// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {SturdyLeverage, IBaseLeverage, IERC20, SafeERC20} from "./SturdyLeverage.sol";
import {IYearnVault} from "../interfaces/Yearn/IYearnVault.sol";
import {ICurvePool} from "../interfaces/Curve/ICurvePool.sol";

/// @notice  Leverage contract for yearn vault of curve lp token
contract CrvYearnVaultLeverage2 is SturdyLeverage {
  using SafeERC20 for IERC20;

  address public immutable YEARN_VAULT;

  error LV_REQUIRE_MIN_AMOUNT();

  constructor(
      address _yearnVault
  ) {
    YEARN_VAULT = _yearnVault;
  }

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal override returns (uint256) {
    if (_path.swapType > IBaseLeverage.SwapType.WITHDRAW) {
      return _swapByPath(_amount, _path, _checkOutAmount);
    }

    if (_path.swapType == IBaseLeverage.SwapType.WITHDRAW) {
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();
      
      // Withdraw from Yearn Vault and receive Curve LP token
      uint256 outAmount = IYearnVault(_path.swapFrom).withdraw(_amount, address(this), 1);
      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    }

    address asset = _path.swapFrom;
    address vault = _path.swapTo;
    uint256 outAmount;

    IERC20(asset).safeApprove(vault, 0);
    IERC20(asset).safeApprove(vault, _amount);

    if (vault == YEARN_VAULT) {
      // Deposit Curve LP token to Yearn Vault and receive Yearn Vault LP token
      outAmount = IYearnVault(vault).deposit(_amount, address(this));
    } else {
      // Deposit asset to Curve pool and receive LP token.
      uint256[] memory amounts = new uint256[](2);
      for (uint256 i; i < 2; ++i) {
        if (ICurvePool(vault).coins(i) == asset) {
          amounts[i] = _amount;
          break;
        }
      }

      outAmount = ICurvePool(vault).add_liquidity(amounts, 0);
    }    

    if (_checkOutAmount && outAmount < _path.outAmount) {
      revert LV_REQUIRE_MIN_AMOUNT();
    }
  
    return outAmount;
  }
}