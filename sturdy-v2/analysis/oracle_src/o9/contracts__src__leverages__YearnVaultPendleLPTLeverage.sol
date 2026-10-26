// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {SturdyLeverage, IBaseLeverage, IERC20, SafeERC20} from "./SturdyLeverage.sol";
import {IYearnVault} from "../interfaces/Yearn/IYearnVault.sol";
import {IPendleMarket} from "../interfaces/Pendle/IPendleMarket.sol";
import {IPendleRouter} from "../interfaces/Pendle/IPendleRouter.sol";
import {ISY} from "../interfaces/Pendle/ISY.sol";

/// @notice  Leverage contract for yearn vault of pendle lp token
contract YearnVaultPendleLPTLeverage is SturdyLeverage {
  using SafeERC20 for IERC20;

  address private constant PENDLE_ROUTER = 0x00000000005BBB0EF59571E58418F9a4357b68A0;

  address public immutable YEARN_VAULT;
  IPendleRouter.ApproxParams public routerParams;

  error LV_REQUIRE_MIN_AMOUNT();

  constructor(
    address _yearnVault
  ) {
    YEARN_VAULT = _yearnVault;

    routerParams.guessMin = 0;
    routerParams.guessMax = type(uint256).max;
    routerParams.guessOffchain = 0; // strictly 0
    routerParams.maxIteration = 256;
    routerParams.eps = 1e15; // max 0.1% unused
  }

  /**
    * @notice Set the routerParams for the pendleRouter. Pendle's AMM only supports the built-in swapSyForExactPt. To execute a swapExactSyForPt, the router will conduct a binary search to determine the amount of PT to swap.
    * @param _guessMin The minimum value for binary search. Default: 0.
    * @param _guessMax The maximum value for binary search. Default: type(uint256).max.
    * @param _maxIteration The maximum number of times binary search will be performed. Default: 256.
    * @param _eps The precision of binary search - the maximum proportion of the input that can be unused. Default: 1e15 == max 0.1% unused. Alternatively: 1e14 implies that no more than 0.01% unused.     
    */
  function setRouterParams(uint256 _guessMin, uint256 _guessMax, uint256 _maxIteration, uint256 _eps) external onlyOwner {
      routerParams.guessMin = _guessMin; // default: 0
      routerParams.guessMax = _guessMax; // default: type(uint256).max
      routerParams.maxIteration = _maxIteration; // default: 256
      routerParams.eps = _eps; // default: 1e15 == max 0.1% unused. Alternatively: 1e14 implies that no more than 0.01% unused.
  }

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _checkOutAmount
  ) internal override returns (uint256) {
    if (_path.swapType > IBaseLeverage.SwapType.WITHDRAW) {
      return _swapByPath(_amount, _path, _checkOutAmount);
    }

    address asset;
    address vault;
    uint256 outAmount;

    if (_path.swapType == IBaseLeverage.SwapType.WITHDRAW) {
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();
      
      vault = _path.swapFrom;
      if(vault == YEARN_VAULT) {
        // Withdraw from Yearn Vault and receive Pendle LP token
        outAmount = IYearnVault(vault).withdraw(_amount, address(this), 1);
      } else {
        // Withdraw from Pendle Pool and receive asset
        (address SY,,) = IPendleMarket(vault).readTokens();

        //Pendle LP --> SY
        IPendleRouter.LimitOrderData memory limit; //skip limit order by passing zero address
        (outAmount,) = IPendleRouter(PENDLE_ROUTER).removeLiquiditySingleSy(address(this), vault, _amount, 0, limit);

        //SY --> asset
        outAmount = ISY(SY).redeem(address(this), outAmount, asset, 0, true);
      }
      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    }

    asset = _path.swapFrom;
    vault = _path.swapTo;

    if (vault == YEARN_VAULT) {
      // Deposit Pendle LP token to Yearn Vault and receive Yearn Vault LP token
      IERC20(asset).safeApprove(vault, 0);
      IERC20(asset).safeApprove(vault, _amount);
      outAmount = IYearnVault(vault).deposit(_amount, address(this));
    } else {
      // Deposit asset to Pendle pool and receive Pendle LP token.
      (address SY,,) = IPendleMarket(vault).readTokens();
      
      //asset --> SY
      IERC20(asset).safeApprove(SY, 0);
      IERC20(asset).safeApprove(SY, _amount);
      outAmount = ISY(SY).deposit(address(this), asset, _amount, 0);
      
      //SY --> Pendle LP
      if (outAmount > 0) {
        IERC20(SY).safeApprove(PENDLE_ROUTER, 0);
        IERC20(SY).safeApprove(PENDLE_ROUTER, outAmount);
        
        IPendleRouter.LimitOrderData memory limit; //skip limit order by passing zero address
        (outAmount,) = IPendleRouter(PENDLE_ROUTER).addLiquiditySingleSy(address(this), vault, outAmount, 0, routerParams, limit);
      }
    }    

    if (_checkOutAmount && outAmount < _path.outAmount) {
      revert LV_REQUIRE_MIN_AMOUNT();
    }
  
    return outAmount;
  }
}