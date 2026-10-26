// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {SturdyLeverage, IBaseLeverage, IERC20, SafeERC20} from "./SturdyLeverage.sol";
import { IERC4626 } from "../interfaces/IERC4626.sol";

contract ERC4626VaultLeverage is SturdyLeverage {
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
      // ERC4626_VAULT_LP -> ASSET
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();

      // Withdraw from ERC4626 Vault and receive asset
      uint256 outAmount = IERC4626(_path.swapFrom).redeem(_amount, address(this), address(this));
      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    }

    // ASSET -> ERC4626_VAULT_LP
    // Deposit asset to ERC4626 Vault and receive LP token
    address asset = _path.swapFrom;
    address vault = _path.swapTo;
    IERC20(asset).safeApprove(vault, 0);
    IERC20(asset).safeApprove(vault, _amount);
    uint256 outAmount = IERC4626(vault).deposit(_amount, address(this));

    if (_checkOutAmount && outAmount < _path.outAmount) {
      revert LV_REQUIRE_MIN_AMOUNT();
    }
  
    return outAmount;
  }
}