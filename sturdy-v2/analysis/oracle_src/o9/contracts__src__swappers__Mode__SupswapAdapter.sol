// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IV3SwapRouter} from "../../interfaces/Mode/Supswap/IV3SwapRouter.sol";

library SupswapAdapter {
  using SafeERC20 for IERC20;

  error SW_PATH_LENGTH_INVALID();
  error SW_PATH_TOKEN_INVALID();
  error SW_MISMATCH_RETURNED_AMOUNT();

  address private constant SUPSWAP_ROUTER = 0x016e131C05fb007b5ab286A6D614A5dab99BD415;

  struct Path {
    address[] tokens;
    uint256[] fees;
  }

  function swapExactTokensForTokens(
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    Path calldata path,
    uint256 minAmountOut
  ) external returns (uint256) {
    // Check path is valid
    uint256 length = path.tokens.length;
    if (length <= 1 || length - 1 != path.fees.length) revert SW_PATH_LENGTH_INVALID();
    if (path.tokens[0] != assetToSwapFrom || path.tokens[length - 1] != assetToSwapTo) revert SW_PATH_TOKEN_INVALID();

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(assetToSwapFrom).safeApprove(address(SUPSWAP_ROUTER), 0);
    IERC20(assetToSwapFrom).safeApprove(address(SUPSWAP_ROUTER), amountToSwap);

    uint256 receivedAmount;
    if (length > 2) {
      bytes memory _path;

      for (uint256 i; i < length - 1; ++i) {
        _path = abi.encodePacked(_path, path.tokens[i], uint24(path.fees[i]));
      }
      _path = abi.encodePacked(_path, assetToSwapTo);

      IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
        path: _path,
        recipient: address(this),
        amountIn: amountToSwap,
        amountOutMinimum: minAmountOut
      });

      // Executes the swap.
      receivedAmount = IV3SwapRouter(SUPSWAP_ROUTER).exactInput(params);
    } else {
      IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
        tokenIn: assetToSwapFrom,
        tokenOut: assetToSwapTo,
        fee: uint24(path.fees[0]),
        recipient: address(this),
        amountIn: amountToSwap,
        amountOutMinimum: minAmountOut,
        sqrtPriceLimitX96: 0
      });

      // Executes the swap.
      receivedAmount = IV3SwapRouter(SUPSWAP_ROUTER).exactInputSingle(params);
    }

    if (receivedAmount == 0) revert SW_MISMATCH_RETURNED_AMOUNT();
    if (IERC20(assetToSwapTo).balanceOf(address(this)) < receivedAmount) revert SW_MISMATCH_RETURNED_AMOUNT();

    return receivedAmount;
  }
}
