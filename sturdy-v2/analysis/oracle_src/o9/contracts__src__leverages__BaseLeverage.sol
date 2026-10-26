// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBaseLeverage} from "../interfaces/IBaseLeverage.sol";
import {IFlashLoanReceiver} from "../interfaces/Aave/V3/IFlashLoanReceiver.sol";
import {IFlashLoanRecipient} from "../interfaces/Balancer/IFlashLoanRecipient.sol";
import {IPool} from "../interfaces/Aave/V3/IPool.sol";
import {IBalancerVault} from "../interfaces/Balancer/IBalancerVault.sol";
import {BalancerswapAdapter} from "../swappers/BalancerswapAdapter.sol";
import {UniswapAdapter} from "../swappers/UniswapAdapter.sol";
import {CurveswapAdapter} from "../swappers/CurveswapAdapter.sol";

abstract contract BaseLeverage is IFlashLoanReceiver, IFlashLoanRecipient, ReentrancyGuard {
  using SafeERC20 for IERC20;

  error LV_INVALID_CONFIGURATION();
  error LV_AMOUNT_NOT_GT_0();
  error LV_SUPPLY_NOT_ALLOWED();
  error LV_SUPPLY_FAILED();

  address private constant AAVE_LENDING_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

  address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  uint256 private constant PERCENTAGE_FACTOR = 100_00;

  //1 == not inExec
  //2 == inExec;
  //setting default to 1 to save some gas.
  uint256 private _balancerFlashLoanLock = 1;

  /**
   * This function is called after your contract has received the flash loaned amount
   * overriding executeOperation() in IFlashLoanReceiver
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    if (initiator != address(this)) revert LV_INVALID_CONFIGURATION();
    if (msg.sender != AAVE_LENDING_POOL_ADDRESS) revert LV_INVALID_CONFIGURATION();
    if (assets.length != amounts.length) revert LV_INVALID_CONFIGURATION();
    if (assets.length != premiums.length) revert LV_INVALID_CONFIGURATION();
    if (amounts[0] == 0) revert LV_INVALID_CONFIGURATION();
    if (assets[0] == address(0)) revert LV_INVALID_CONFIGURATION();

    _executeOperation(assets[0], amounts[0], premiums[0], params);

    // approve the Aave LendingPool contract allowance to *pull* the owed amount
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, 0);
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, amounts[0] + premiums[0]);

    return true;
  }

  /**
   * This function is called after your contract has received the flash loaned amount
   * overriding receiveFlashLoan() in IFlashLoanRecipient
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override {
    if (msg.sender != BALANCER_VAULT) revert LV_INVALID_CONFIGURATION();
    if (_balancerFlashLoanLock != 2) revert LV_INVALID_CONFIGURATION();
    if (tokens.length != amounts.length) revert LV_INVALID_CONFIGURATION();
    if (tokens.length != feeAmounts.length) revert LV_INVALID_CONFIGURATION();
    if (amounts[0] == 0) revert LV_INVALID_CONFIGURATION();
    if (address(tokens[0]) == address(0)) revert LV_INVALID_CONFIGURATION();

    _balancerFlashLoanLock = 1;

    _executeOperation(address(tokens[0]), amounts[0], feeAmounts[0], userData);

    // send tokens to Balancer vault contract
    IERC20(tokens[0]).safeTransfer(msg.sender, amounts[0] + feeAmounts[0]);
  }

  function _executeOperation(
    address asset,
    uint256 borrowAmount,
    uint256 fee,
    bytes memory params
  ) internal {
    // parse params
    IBaseLeverage.FlashLoanParams memory opsParams = abi.decode(
      params,
      (IBaseLeverage.FlashLoanParams)
    );
    if (opsParams.minRequiredAmount == 0) revert LV_INVALID_CONFIGURATION();
    if (opsParams.user == address(0)) revert LV_INVALID_CONFIGURATION();

    if (opsParams.isEnterPosition) {
      _enterPositionWithFlashloan(asset, borrowAmount, fee, opsParams);
    } else {
      _withdrawWithFlashloan(asset, borrowAmount, opsParams);
    }
  }

  /**
   * @param _principal - The amount of collateral
   * @param _leverage - Extra leverage value and must be greater than 0, ex. 300% = 300_00
   *                    _principal + _principal * _leverage should be used as collateral
   * @param _borrowAsset - The flashloan borrowing asset address when leverage works
   * @param _collateralAsset - The collateral asset address when leverage works
   * @param _silo - The silo address
   * @param _flashLoanType - 0 is Aave, 1 is Balancer
   * @param _borrowAssetAndCollateral - The uniswap/balancer/curve swap paths between borrowAsset and collateral
   * @param _borrowAssetAndSiloAsset - The uniswap/balancer/curve swap paths between borrowAsset and silo asset
   */
  function enterPositionWithFlashloan(
    uint256 _principal,
    uint256 _leverage,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    IBaseLeverage.FlashLoanType _flashLoanType,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndCollateral,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndSiloAsset
  ) external nonReentrant {
    if (_principal == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_leverage == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_leverage >= 900_00) revert LV_INVALID_CONFIGURATION();
    if (_borrowAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_collateralAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_silo == address(0)) revert LV_INVALID_CONFIGURATION();
    if (IERC20(_collateralAsset).balanceOf(msg.sender) < _principal) revert LV_SUPPLY_NOT_ALLOWED();

    IERC20(_collateralAsset).safeTransferFrom(msg.sender, address(this), _principal);

    _leverageWithFlashloan(
      IBaseLeverage.LeverageParams(
        msg.sender,
        _principal,
        _leverage,
        _borrowAsset,
        _collateralAsset,
        _silo,
        _flashLoanType,
        _borrowAssetAndCollateral,
        _borrowAssetAndSiloAsset
      )
    );
  }

  /**
   * @param _repayAmount - The amount of repay
   * @param _requiredAmount - The amount of collateral
   * @param _borrowAsset - The flashloan borrowing asset address when leverage works
   * @param _collateralAsset - The collateral asset address when leverage works
   * @param _silo - The silo address
   * @param _flashLoanType - 0 is Aave, 1 is Balancer
   * @param _borrowAssetAndCollateral - The uniswap/balancer/curve swap paths between borrowAsset and collateral asset
   * @param _borrowAssetAndSiloAsset - The uniswap/balancer/curve swap paths between borrowAsset and silo asset
   */
  function withdrawWithFlashloan(
    uint256 _repayAmount,
    uint256 _requiredAmount,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    IBaseLeverage.FlashLoanType _flashLoanType,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndCollateral,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndSiloAsset
  ) external nonReentrant {
    if (_repayAmount == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_requiredAmount == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_borrowAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_collateralAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_silo == address(0)) revert LV_INVALID_CONFIGURATION();

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _borrowAssetAndSiloAsset.paths[0].inAmount;
    if (amounts[0] == 0) {
      amounts[0] = _repayAmount;
    }

    bytes memory params = abi.encode(
      false /*leavePosition*/,
      _repayAmount,
      msg.sender,
      _collateralAsset,
      _silo,
      _borrowAssetAndCollateral,
      _borrowAssetAndSiloAsset
    );

    if (_flashLoanType == IBaseLeverage.FlashLoanType.AAVE) {
      // 0 means revert the transaction if not validated
      uint256[] memory modes = new uint256[](1);
      modes[0] = 0;

      address[] memory assets = new address[](1);
      assets[0] = _borrowAsset;
      IPool(AAVE_LENDING_POOL_ADDRESS).flashLoan(
        address(this),
        assets,
        amounts,
        modes,
        address(this),
        params,
        0
      );
    } else {
      if (_balancerFlashLoanLock != 1) revert LV_INVALID_CONFIGURATION();
      IERC20[] memory assets = new IERC20[](1);
      assets[0] = IERC20(_borrowAsset);
      _balancerFlashLoanLock = 2;
      IBalancerVault(BALANCER_VAULT).flashLoan(address(this), assets, amounts, params);
    }

    // remained borrow asset -> collateral
    _swapAsset(
      _borrowAsset,
      _collateralAsset,
      IERC20(_borrowAsset).balanceOf(address(this)),
      _borrowAssetAndCollateral.paths,
      _borrowAssetAndCollateral.pathLength,
      false
    );

    uint256 collateralAmount = IERC20(_collateralAsset).balanceOf(address(this));
    if (collateralAmount > _requiredAmount) {
      _supply(_collateralAsset, _silo, collateralAmount - _requiredAmount, msg.sender);
      collateralAmount = _requiredAmount;
    }

    // finally deliver the collateral to user
    IERC20(_collateralAsset).safeTransfer(msg.sender, collateralAmount);
  }

  /**
   * @param _principal - The amount of zapping asset
   * @param _borrowAmount - The amount of borrowing asset
   * @param _zappingAsset - The address which will zap into collateral asset
   * @param _collateralAsset - The collateral asset address
   * @param _silo - The silo address
   * @param _zapAssetToCollateral - The uniswap/balancer/curve swap paths from zappingAsset to collateral asset
   */
  function zapDeposit(
    uint256 _principal,
    uint256 _borrowAmount,
    address _zappingAsset,
    address _collateralAsset,
    address _silo,
    IBaseLeverage.UniDirectSwapInfo calldata _zapAssetToCollateral
  ) external nonReentrant {
    if (_principal == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_zappingAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_collateralAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_silo == address(0)) revert LV_INVALID_CONFIGURATION();
    if (IERC20(_zappingAsset).balanceOf(msg.sender) < _principal) revert LV_SUPPLY_FAILED();

    IERC20(_zappingAsset).safeTransferFrom(msg.sender, address(this), _principal);

    uint256 collateralAmount = _swapAsset(
      _zappingAsset, 
      _collateralAsset, 
      _principal, 
      _zapAssetToCollateral.paths, 
      _zapAssetToCollateral.pathLength, 
      true
    );
    
    // deposit collateral
    _supply(_collateralAsset, _silo, collateralAmount, msg.sender);

    //borrow
    if (_borrowAmount != 0) {
      _borrow(_silo, _borrowAmount, msg.sender, msg.sender);
    }
  }

  /**
   * @param _principal - The amount of the zapping asset
   * @param _leverage - Extra leverage value and must be greater than 0, ex. 300% = 300_00
   *                    principal + principal * leverage should be used as collateral
   * @param _zappingAsset - The address which will zap into collateral asset
   * @param _collateralAsset - The collateral asset address when leverage works
   * @param _borrowAsset - The flashloan borrowing asset address when leverage works
   * @param _silo - The silo address
   * @param _flashLoanType - 0 is Aave, 1 is Balancer
   * @param _zapAssetToCollateral - The uniswap/balancer/curve swap paths from zappingAsset to collateral asset
   * @param _borrowAssetAndCollateral - The uniswap/balancer/curve swap path length between borrowAsset and collateral asset
   * @param _borrowAssetAndSiloAsset - The uniswap/balancer/curve swap between borrowAsset and collateralAsset
   */
  function zapLeverageWithFlashloan(
    uint256 _principal,
    uint256 _leverage,
    address _zappingAsset,
    address _collateralAsset,
    address _borrowAsset,
    address _silo,
    IBaseLeverage.FlashLoanType _flashLoanType,
    IBaseLeverage.UniDirectSwapInfo calldata _zapAssetToCollateral,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndCollateral,
    IBaseLeverage.BiDirectSwapInfo calldata _borrowAssetAndSiloAsset
  ) external nonReentrant {
    if (_principal == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_leverage == 0) revert LV_AMOUNT_NOT_GT_0();
    if (_leverage >= 900_00) revert LV_INVALID_CONFIGURATION();
    if (_zappingAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_collateralAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_borrowAsset == address(0)) revert LV_INVALID_CONFIGURATION();
    if (_silo == address(0)) revert LV_INVALID_CONFIGURATION();
    if (IERC20(_zappingAsset).balanceOf(msg.sender) < _principal) revert LV_SUPPLY_FAILED();

    IERC20(_zappingAsset).safeTransferFrom(msg.sender, address(this), _principal);

    uint256 collateralAmount = _swapAsset(
      _zappingAsset, 
      _collateralAsset, 
      _principal, 
      _zapAssetToCollateral.paths, 
      _zapAssetToCollateral.pathLength, 
      true
    );

    _leverageWithFlashloan(
      IBaseLeverage.LeverageParams(
        msg.sender,
        collateralAmount,
        _leverage,
        _borrowAsset,
        _collateralAsset,
        _silo,
        _flashLoanType,
        _borrowAssetAndCollateral,
        _borrowAssetAndSiloAsset
      )
    );
  }

  function _leverageWithFlashloan(IBaseLeverage.LeverageParams memory _params) internal {
    uint256 minCollateralAmount = _params.principal * (PERCENTAGE_FACTOR + _params.leverage) / PERCENTAGE_FACTOR;

    bytes memory params = abi.encode(
      true /*enterPosition*/,
      minCollateralAmount,
      _params.user,
      _params.collateralAsset,
      _params.silo,
      _params.borrowAssetAndCollateral,
      _params.borrowAssetAndSiloAsset
    );

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _params.borrowAssetAndCollateral.paths[0].inAmount;
    if (_params.flashLoanType == IBaseLeverage.FlashLoanType.AAVE) {
      // 0 means revert the transaction if not validated
      uint256[] memory modes = new uint256[](1);
      address[] memory assets = new address[](1);
      assets[0] = _params.borrowAsset;
      IPool(AAVE_LENDING_POOL_ADDRESS).flashLoan(
        address(this),
        assets,
        amounts,
        modes,
        address(this),
        params,
        0
      );
    } else {
      if (_balancerFlashLoanLock != 1) revert LV_INVALID_CONFIGURATION();

      IERC20[] memory assets = new IERC20[](1);
      assets[0] = IERC20(_params.borrowAsset);
      _balancerFlashLoanLock = 2;
      IBalancerVault(BALANCER_VAULT).flashLoan(address(this), assets, amounts, params);
      _balancerFlashLoanLock = 1;
    }

    _afterLeverageWithFlashloan(
      _params.borrowAsset,
      _params
    );
  }

  function _swapAsset(
    address _fromAsset,
    address _toAsset,
    uint256 _amount,
    IBaseLeverage.MultipSwapPath[4] memory _paths,
    uint256 _pathLength,
    bool _checkOutAmount
  ) internal returns (uint256) {
    if (_pathLength == 0) revert LV_INVALID_CONFIGURATION();
    if (_paths[0].swapFrom != _fromAsset) revert LV_INVALID_CONFIGURATION();
    if (_paths[_pathLength - 1].swapTo != _toAsset) revert LV_INVALID_CONFIGURATION();

    uint256 amount = _amount;
    if (amount == 0) return 0;

    for (uint256 i; i < _pathLength; ++i) {
      if (_paths[i].swapType == IBaseLeverage.SwapType.NONE) continue;

      amount = _processSwap(amount, _paths[i], _checkOutAmount);
    }

    return amount;
  }

  function _swapByPath(
    uint256 _fromAmount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal returns (uint256) {
    uint256 poolCount = _path.poolCount;
    uint256 outAmount = _checkOutAmount ? _path.outAmount : 0;
    if (poolCount == 0) revert LV_INVALID_CONFIGURATION();

    if (_path.swapType == IBaseLeverage.SwapType.BALANCER) {
      // Balancer Swap
      BalancerswapAdapter.Path memory path;
      path.tokens = new address[](poolCount + 1);
      path.poolIds = new bytes32[](poolCount);

      for (uint256 i; i < poolCount; ++i) {
        path.tokens[i] = _path.routes[i * 2];
        path.poolIds[i] = bytes32(_path.routeParams[i][0]);
      }
      path.tokens[poolCount] = _path.routes[poolCount * 2];

      return
        BalancerswapAdapter.swapExactTokensForTokens(
          _path.swapFrom,
          _path.swapTo,
          _fromAmount,
          path,
          outAmount
        );
    }

    if (_path.swapType == IBaseLeverage.SwapType.UNISWAP) {
      // UniSwap
      UniswapAdapter.Path memory path;
      path.tokens = new address[](poolCount + 1);
      path.fees = new uint256[](poolCount);

      for (uint256 i; i < poolCount; ++i) {
        path.tokens[i] = _path.routes[i * 2];
        path.fees[i] = _path.routeParams[i][0];
      }
      path.tokens[poolCount] = _path.routes[poolCount * 2];

      return
        UniswapAdapter.swapExactTokensForTokens(
          _path.swapFrom,
          _path.swapTo,
          _fromAmount,
          path,
          outAmount
        );
    }

    // Curve Swap
    return
      CurveswapAdapter.swapExactTokensForTokens(
        _path.swapFrom,
        _path.swapTo,
        _fromAmount,
        CurveswapAdapter.Path(_path.routes, _path.routeParams),
        outAmount
      );
  }

  function _enterPositionWithFlashloan(
    address _borrowAsset,
    uint256 _borrowedAmount,
    uint256 _fee,
    IBaseLeverage.FlashLoanParams memory _params
  ) internal virtual;

  function _afterLeverageWithFlashloan(
    address _borrowAsset,
    IBaseLeverage.LeverageParams memory _params
  ) internal virtual;

  function _withdrawWithFlashloan(
    address _borrowAsset,
    uint256 _borrowedAmount,
    IBaseLeverage.FlashLoanParams memory _params
  ) internal virtual;

  function _supply(
    address _collateralAsset, 
    address _silo, 
    uint256 _amount, 
    address _user
  ) internal virtual;

  function _remove(
    uint256 _amount, 
    address _silo, 
    uint256 _slippage, 
    address _user
  ) internal virtual;

  function _borrow(
    address _silo, 
    uint256 _amount, 
    address _borrower,
    address _receiver
  ) internal virtual;

  function _repay(
    address _silo, 
    uint256 _amount, 
    address _borrower
  ) internal virtual;

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal virtual returns (uint256);
}