// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BaseLeverageWihtoutFlashloan} from "./BaseLeverageWihtoutFlashloan.sol";
import {IBaseLeverageWihtoutFlashloan} from "../../interfaces/Mode/IBaseLeverageWihtoutFlashloan.sol";
import {ISturdyPair} from "../../interfaces/ISturdyPair.sol";
import {ISiloGateway} from "../../interfaces/ISiloGateway.sol";

contract SturdyLeverageWihtoutFlashloan is Ownable, BaseLeverageWihtoutFlashloan {
  using SafeERC20 for IERC20;

  uint256 private constant SAFE_BUFFER = 5000;

  // silo -> silo gateway
  mapping (address => address) private _siloToGateway;

  error LV_REPAY_FAILED();
  error LV_SWAP_FAILED();

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

  function _calcBorrowableAmount(
    address _silo,
    uint256 _collateralAmount
  ) internal override returns (uint256) {
    ISturdyPair pair = ISturdyPair(_silo);

    (,, uint256 exchangeRate) = pair.updateExchangeRate();
    ( uint256 LTV_PRECISION,,,, uint256 EXCHANGE_PRECISION,,,) = pair.getConstants();
    uint256 availableBorrowAmount = _collateralAmount * EXCHANGE_PRECISION * pair.maxLTV() / exchangeRate / LTV_PRECISION;
    
    return availableBorrowAmount > SAFE_BUFFER ? availableBorrowAmount - SAFE_BUFFER : 0;
  }

  function _calcWithdrawalAmount(
    address _silo,
    uint256 _healthFactor
  ) internal override returns (uint256) {
    ISturdyPair pair = ISturdyPair(_silo);

    (,, uint256 exchangeRate) = pair.updateExchangeRate();
    ( uint256 LTV_PRECISION,,,, uint256 EXCHANGE_PRECISION,,,) = pair.getConstants();
    uint256 debtShares = pair.userBorrowShares(msg.sender);
    uint256 debtAmount =  pair.toBorrowAmount(debtShares, true, true);
    uint256 collateralAmount = pair.userCollateralBalance(msg.sender);
    uint256 withdrawalAmount = collateralAmount - debtAmount * _healthFactor * exchangeRate * LTV_PRECISION / pair.maxLTV() / EXCHANGE_PRECISION / 1e18;

    return withdrawalAmount;
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
    IBaseLeverageWihtoutFlashloan.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal virtual override returns (uint256) {
    return _swapByPath(_amount, _path, _checkOutAmount);
  }
}