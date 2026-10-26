// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseLeverage, IBaseLeverage, IERC20, SafeERC20} from "./BaseLeverage.sol";
import {ISturdyPair} from "../interfaces/ISturdyPair.sol";
import {ISiloGateway} from "../interfaces/ISiloGateway.sol";

contract SturdyLeverage is Ownable, BaseLeverage {
  using SafeERC20 for IERC20;

  // silo -> silo gateway
  mapping (address => address) private _siloToGateway;

  error LV_REPAY_FAILED();

  /**
   * @dev Set the mapping between silos and gateways. 
   *      Gateways will be used to borrow asset for the Just-In-Time liquidity features.
   * @param _silos - The silo addresses
   * @param _gateways - The gateway addresses
   */
  function setGateways(
    address[] calldata _silos, 
    address[] calldata _gateways
  ) external payable onlyOwner {
    uint256 length = _silos.length;
    if (length != _gateways.length) revert LV_INVALID_CONFIGURATION();

    for (uint256 i; i < length; ++i) {
      _siloToGateway[_silos[i]] = _gateways[i];
    }
  }

  /**
   * @dev Get the gateway address for the silo
   * @param _silo - The silo address
   * @return The gateway address
   */
  function getGateway(
    address _silo
  ) external view returns (address) {
    return _siloToGateway[_silo];
  }

  function _enterPositionWithFlashloan(
    address _borrowAsset,
    uint256 _borrowedAmount,
    uint256 _fee,
    IBaseLeverage.FlashLoanParams memory _params
  ) internal override {
    //swap borrow asset -> collateral
    _swapAsset(
      _borrowAsset,
      _params.collateralAsset,
      _borrowedAmount,
      _params.borrowAssetAndCollateral.paths,
      _params.borrowAssetAndCollateral.pathLength,
      true
    );

    uint256 collateralAmount = IERC20(_params.collateralAsset).balanceOf(address(this));
    if (collateralAmount < _params.minRequiredAmount) revert LV_SUPPLY_FAILED();

    //deposit collateral
    _supply(_params.collateralAsset, _params.silo, collateralAmount, _params.user);

    ISturdyPair pair = ISturdyPair(_params.silo);
    if (pair.asset() == _borrowAsset) {
      //borrow
      _borrow(_params.silo, _borrowedAmount + _fee, _params.user, address(this));
    } else {
      ( uint256 LTV_PRECISION,,,, uint256 EXCHANGE_PRECISION,,,) = pair.getConstants();
      pair.addInterest(false);

      (,, uint256 exchangeRate) = pair.updateExchangeRate();
      uint256 borrowShares = pair.userBorrowShares(_params.user);
      uint256 borrowAmount =  pair.toBorrowAmount(borrowShares, true, false);
      uint256 collateralAmount = pair.userCollateralBalance(_params.user);
      borrowAmount = collateralAmount * EXCHANGE_PRECISION * pair.maxLTV() / exchangeRate / LTV_PRECISION - borrowAmount;

      //borrow
      _borrow(_params.silo, borrowAmount, _params.user, address(this));

      //swap asset -> borrow asset
      _swapAsset(
        pair.asset(),
        _borrowAsset,
        borrowAmount,
        _params.borrowAssetAndSiloAsset.reversePaths,
        _params.borrowAssetAndSiloAsset.pathLength,
        true
      );
    }
  }

  function _afterLeverageWithFlashloan(
    address _borrowAsset,
    IBaseLeverage.LeverageParams memory _params
  ) internal override {
    address asset = ISturdyPair(_params.silo).asset();

    if (asset == _borrowAsset) return;

    // remained borrow asset -> asset
    _swapAsset(
      _borrowAsset,
      asset,
      IERC20(_borrowAsset).balanceOf(address(this)),
      _params.borrowAssetAndSiloAsset.paths,
      _params.borrowAssetAndSiloAsset.pathLength,
      false
    );

    // repay
    _repay(_params.silo, IERC20(asset).balanceOf(address(this)), _params.user);
  }

  function _withdrawWithFlashloan(
    address _borrowAsset,
    uint256 _borrowedAmount,
    IBaseLeverage.FlashLoanParams memory _params
  ) internal override {
    ISturdyPair pair = ISturdyPair(_params.silo);
    address asset = pair.asset();

    if (asset == _borrowAsset) {
      // repay
      _repay(_params.silo, _borrowedAmount, _params.user);
    } else {
      //swap borrow asset -> asset
      _swapAsset(
        _borrowAsset,
        asset,
        _borrowedAmount,
        _params.borrowAssetAndSiloAsset.paths,
        _params.borrowAssetAndSiloAsset.pathLength,
        true
      );

      uint256 assetAmount = IERC20(asset).balanceOf(address(this));
      if (assetAmount < _params.minRequiredAmount) revert LV_REPAY_FAILED();

      // repay
      _repay(_params.silo, _params.minRequiredAmount, _params.user);

      //swap asset -> borrow asset
      _swapAsset(
        asset,
        _borrowAsset,
        assetAmount - _params.minRequiredAmount,
        _params.borrowAssetAndSiloAsset.reversePaths,
        _params.borrowAssetAndSiloAsset.pathLength,
        false
      );
    }

    // withdraw collateral    
    if (_params.collateralAsset != pair.collateralContract()) revert LV_INVALID_CONFIGURATION();

    ( uint256 LTV_PRECISION,,,, uint256 EXCHANGE_PRECISION,,,) = pair.getConstants();
    pair.addInterest(false);

    (,, uint256 exchangeRate) = pair.updateExchangeRate();
    uint256 borrowShares = pair.userBorrowShares(_params.user);
    uint256 borrowAmount =  pair.toBorrowAmount(borrowShares, true, false);
    uint256 collateralAmount = pair.userCollateralBalance(_params.user);
    uint256 withdrawalAmount = collateralAmount - (borrowAmount * exchangeRate * LTV_PRECISION / EXCHANGE_PRECISION / pair.maxLTV());

    _remove(withdrawalAmount, _params.silo, 0, _params.user);

    // collateral -> borrow asset
    _swapAsset(
      _params.collateralAsset, 
      _borrowAsset, 
      IERC20(_params.collateralAsset).balanceOf(address(this)),
      _params.borrowAssetAndCollateral.reversePaths, 
      _params.borrowAssetAndCollateral.pathLength,
      true
    );
  }

  function _supply(
    address _collateralAsset, 
    address _silo, 
    uint256 _amount, 
    address _user
  ) internal override {
    IERC20(_collateralAsset).safeApprove(_silo, 0);
    IERC20(_collateralAsset).safeApprove(_silo, _amount);
    ISturdyPair(_silo).addCollateral(_amount, _user);
  }

  function _remove(
    uint256 _amount, 
    address _silo, 
    uint256 _slippage, 
    address _user
  ) internal override {
    ISturdyPair(_silo).removeCollateralFrom(_amount, address(this), _user);
  }

  function _borrow(
    address _silo, 
    uint256 _amount, 
    address _borrower,
    address _receiver
  ) internal override {
    if (_siloToGateway[_silo] == address(0)) {
      ISturdyPair(_silo).borrowAssetOnBehalfOf(_amount, _borrower);
      
      if (_receiver != address(this)) {
        IERC20(ISturdyPair(_silo).asset()).safeTransfer(_receiver, _amount);
      }
    } else {
      ISiloGateway(_siloToGateway[_silo]).borrowAsset(
        _silo,
        _amount,
        0,
        ISturdyPair(_silo).collateralContract(),
        _borrower,
        _receiver
      );
    }

    
  }

  function _repay(
    address _silo, 
    uint256 _amount, 
    address _borrower
  ) internal override {
    IERC20 borrowAsset = IERC20(ISturdyPair(_silo).asset());

    ISturdyPair(_silo).addInterest(false);

    uint256 borrowShares =  ISturdyPair(_silo).toBorrowShares(_amount, false, false);

    borrowAsset.safeApprove(_silo, 0);
    borrowAsset.safeApprove(_silo, _amount);

    uint256 paybackAmount = ISturdyPair(_silo).repayAsset(borrowShares, _borrower);
    if (paybackAmount == 0) revert LV_REPAY_FAILED();
  }

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal virtual override returns (uint256) {
    return _swapByPath(_amount, _path, _checkOutAmount);
  }
}