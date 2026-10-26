// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {SturdyLeverage, IBaseLeverage, IERC20, SafeERC20} from "./SturdyLeverage.sol";
import {IYearnVault} from "../interfaces/Yearn/IYearnVault.sol";

/// @notice  Leverage contract for yearn vault of curve lp token
contract CrvYearnVaultLeverage is SturdyLeverage {
  using SafeERC20 for IERC20;

  error LV_REQUIRE_MIN_AMOUNT();

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal override returns (uint256) {
    if (_path.swapType > IBaseLeverage.SwapType.WITHDRAW) {
      return _swapByPath(_amount, _path, _checkOutAmount);
    }

    if (_path.swapType == IBaseLeverage.SwapType.WITHDRAW) {
      // Yearn Vault LP -> Curve Pool LP
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();

      // Withdraw from Yearn Vault and receive Curve LP token
      uint256 outAmount = IYearnVault(_path.swapFrom).withdraw(_amount, address(this), 1);
      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    }

    // Curve Pool LP -> Yearn Vault LP
    // Deposit Curve LP token to Yearn Vault and receive Yearn Vault LP token
    address asset = _path.swapFrom;
    address vault = _path.swapTo;
    IERC20(asset).safeApprove(vault, 0);
    IERC20(asset).safeApprove(vault, _amount);
    uint256 outAmount = IYearnVault(vault).deposit(_amount, address(this));

    if (_checkOutAmount && outAmount < _path.outAmount) {
      revert LV_REQUIRE_MIN_AMOUNT();
    }
  
    return outAmount;
  }
}