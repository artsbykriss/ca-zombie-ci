// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";

library Swap {
    using SafeERC20 for IERC20;

    struct SwapPair {
        address tokenIn;
        address tokenOut;
    }

    struct SwapData {
        uint256 minSwapAmountNative;
        uint256 minSwapAmountToken0;
        uint256 minSwapAmountToken1;
        Swap.SwapPair[] swapsToken0ToNative;
        Swap.SwapPair[] swapsToken1ToNative;
        Swap.SwapPair[] swapsNativeToToken0;
        Swap.SwapPair[] swapsNativeToToken1;
        Swap.SwapPair[] swapsToken0ToToken1;
        Swap.SwapPair[] swapsToken1ToToken0;
    }

    error ValidateSwapPathPathDisjoined(SwapPair[]);
    error ValidateSwapPathPathTokenInNotEqRequiredTokenIn(address pathTokenIn, address tokenIn);
    error ValidateSwapPathPathTokenOutNotEqRequiredTokenOut(address pathTokenOut, address tokenOut);

    function swap(
        SwapPair[] memory path,
        IDexFiUniversalRouterBytes router,
        uint256 amountIn,
        address recipient,
        uint256 minSwapAmount
    ) external returns (uint256 amountOut) {
        uint256 swapsLength = path.length;
        amountOut = amountIn;
        if (path[0].tokenIn == path[swapsLength - 1].tokenOut && amountIn > 0) {
            if (recipient != address(this)) IERC20(path[0].tokenIn).safeTransfer(recipient, amountOut);
        } else if (amountIn >= minSwapAmount) {
            for (uint256 i = 0; i < swapsLength; i++) {
                address middleRecipient = i == swapsLength - 1 ? recipient : address(this);
                SwapPair memory pair = path[i];
                IERC20 tokenOut = IERC20(pair.tokenOut);
                uint256 tokenOutBalanceBefore = tokenOut.balanceOf(middleRecipient);
                IERC20(pair.tokenIn).forceApprove(address(router), amountOut);
                router.swap(pair.tokenIn, pair.tokenOut, amountOut, 0, middleRecipient);
                amountOut = tokenOut.balanceOf(middleRecipient) - tokenOutBalanceBefore;
            }
        } else amountOut = 0;
    }

    function getAmountOut(
        SwapPair[] memory path,
        IDexFiUniversalRouterBytes router,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        uint256 swapsLength = path.length;
        amountOut = amountIn;
        if (path[0].tokenIn != path[swapsLength - 1].tokenOut && amountIn > 0) {
            for (uint256 i = 0; i < swapsLength; i++) {
                SwapPair memory pair = path[i];
                if (amountOut == 0) break;
                amountOut = router.getAmountOut(amountOut, pair.tokenIn, pair.tokenOut);
            }
        }
    }

    function validateSwapPath(SwapPair[] memory path, address tokenIn, address tokenOut) external pure {
        uint256 swapsCount = path.length - 1;
        if (path[0].tokenIn != tokenIn)
            revert ValidateSwapPathPathTokenInNotEqRequiredTokenIn(path[0].tokenIn, tokenIn);
        if (path[swapsCount].tokenOut != tokenOut)
            revert ValidateSwapPathPathTokenOutNotEqRequiredTokenOut(path[swapsCount].tokenOut, tokenOut);
        for (uint256 i = 0; i < swapsCount; i++) {
            if (path[i].tokenOut != path[i + 1].tokenIn) revert ValidateSwapPathPathDisjoined(path);
        }
    }

    function reverseSwapPath(SwapPair[] memory path) external pure returns (SwapPair[] memory output) {
        uint256 swapsLength = path.length;
        output = new SwapPair[](swapsLength);
        for (uint256 i = 0; i < swapsLength; i++) {
            SwapPair memory pair = path[swapsLength - 1 - i];
            output[i] = SwapPair({tokenIn: pair.tokenOut, tokenOut: pair.tokenIn});
        }
    }
}
