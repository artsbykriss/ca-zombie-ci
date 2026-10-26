// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {SturdyLeverage, IBaseLeverage, IERC20, SafeERC20} from "./SturdyLeverage.sol";
import {IPendleMarket} from "../interfaces/Pendle/IPendleMarket.sol";
import {IPendleRouter} from "../interfaces/Pendle/IPendleRouter.sol";
import {ISY} from "../interfaces/Pendle/ISY.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";

/// @notice  Leverage contract for pendle pt token
contract PendlePTLeverage is SturdyLeverage {
  using SafeERC20 for IERC20;

  address private constant PENDLE_ROUTER = 0x00000000005BBB0EF59571E58418F9a4357b68A0;

  address public immutable PENDLE_MARKET;

  IPendleRouter.ApproxParams public routerParams;

  // pendle PT -> pendle Market(LPT)
  mapping (address => address) public ptToMarket;

  error LV_REQUIRE_MIN_AMOUNT();

  constructor() {
    routerParams.guessMin = 0;
    routerParams.guessMax = type(uint256).max;
    routerParams.guessOffchain = 0; // strictly 0
    routerParams.maxIteration = 256;
    routerParams.eps = 1e15; // max 0.1% unused
  }

  /**
   * @dev Set the mapping between PT and Market. 
   * @param _pts - The pendle PT token addresses
   * @param _markets - The pendle Market addresses
   */
  function setPTAndMarket(
    address[] calldata _pts, 
    address[] calldata _markets
  ) external payable onlyOwner {
    uint256 length = _pts.length;
    if (length != _markets.length) revert LV_INVALID_CONFIGURATION();

    for (uint256 i; i < length; ++i) {
      ptToMarket[_pts[i]] = _markets[i];
    }
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

    uint256 outAmount;
    address market;
    address asset;

    if (_path.swapType == IBaseLeverage.SwapType.UNSTAKE) {
      // ERC4626_VAULT_LP -> asset
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();

      // Withdraw from ERC4626 Vault and receive asset
      outAmount = IERC4626(_path.swapFrom).redeem(_amount, address(this), address(this));
      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    } else if (_path.swapType == IBaseLeverage.SwapType.STAKE) {
      // asset -> ERC4626_VAULT_LP
      // Deposit asset to ERC4626 Vault and receive LP token
      address vault = _path.swapTo;
      asset = _path.swapFrom;
      IERC20(asset).safeApprove(vault, 0);
      IERC20(asset).safeApprove(vault, _amount);
      outAmount = IERC4626(vault).deposit(_amount, address(this));
    } else if (_path.swapType == IBaseLeverage.SwapType.WITHDRAW) {
      if (!_checkOutAmount) revert LV_INVALID_CONFIGURATION();
      
      address PT = _path.swapFrom;
      asset = _path.swapTo;
      market = ptToMarket[PT];
      (address SY,,) = IPendleMarket(market).readTokens();
      
      //Pendle PT --> SY
      IERC20(PT).safeApprove(PENDLE_ROUTER, 0);
      IERC20(PT).safeApprove(PENDLE_ROUTER, _amount);

      IPendleRouter.LimitOrderData memory limit; //skip limit order by passing zero address
      (outAmount,) = IPendleRouter(PENDLE_ROUTER).swapExactPtForSy(address(this), market, _amount, 0, limit);

      //SY --> asset
      if (outAmount != 0) {
        outAmount = ISY(SY).redeem(address(this), outAmount, asset, 0, false);
      }

      if (outAmount < _path.outAmount) revert LV_REQUIRE_MIN_AMOUNT();

      return outAmount;
    } else if (_path.swapType == IBaseLeverage.SwapType.DEPOSIT) {
      asset = _path.swapFrom;
      market = ptToMarket[_path.swapTo];
      (address SY,,) = IPendleMarket(market).readTokens();
      
      //asset --> SY
      IERC20(asset).safeApprove(SY, 0);
      IERC20(asset).safeApprove(SY, _amount);
      outAmount = ISY(SY).deposit(address(this), asset, _amount, 0);
      
      //SY --> Pendle PT
      if (outAmount != 0) {
        IERC20(SY).safeApprove(PENDLE_ROUTER, 0);
        IERC20(SY).safeApprove(PENDLE_ROUTER, outAmount);

        IPendleRouter.LimitOrderData memory limit; //skip limit order by passing zero address
        (outAmount,) = IPendleRouter(PENDLE_ROUTER).swapExactSyForPt(address(this), market, outAmount, 0, routerParams, limit);
      }
    }

    if (_checkOutAmount && outAmount < _path.outAmount) {
      revert LV_REQUIRE_MIN_AMOUNT();
    }
  
    return outAmount;
  }
}