// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {State} from "./State.sol";

/// @dev The part of Aerodrome Slipstream's SwapRouter this library calls.
interface ISlipstreamSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        int24 tickSpacing;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

/// @dev The pool's relayer allowlist, read through the pool.
interface INullmaskRelayers {
    function allowedRelayers(address relayer) external view returns (bool);
}

/// @title NullmaskSwapSlipstream
/// @notice The Aerodrome Slipstream leg of `Nullmask.shieldedSwap` on Base, linked in place of NullmaskSwap.
library NullmaskSwapSlipstream {
    using SafeERC20 for IERC20;

    error TokenNotWhitelisted(address token);
    error InvalidSwapSelector();
    error NotRelayer(address caller);
    error UnsupportedPathLength(uint256 length);
    error UnsupportedPair(address tokenIn, address tokenOut);
    error NotWrappedNative(address token);
    error WrappedNativeAsToken();
    error UnsupportedToken(address token);
    error SwapInputNotFullySpent();
    error SwapOutputNotReceived(uint256 received, uint256 swapped);
    error InsufficientOutputAmount(uint256 amountOut, uint256 amountOutMin);

    bytes4 private constant SWAP_TOKENS_FOR_TOKENS = 0x38ed1739;
    bytes4 private constant SWAP_ETH_FOR_TOKENS = 0x7ff36ab5;
    bytes4 private constant SWAP_TOKENS_FOR_ETH = 0x18cbafe5;

    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    int24 internal constant TICK_SPACING = 100;

    /// @notice Runs one Slipstream swap and returns the amount credited to the output note.
    function swap(
        mapping(address => State.TokenType) storage whitelist,
        address router,
        bytes4 selector,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        if (!INullmaskRelayers(address(this)).allowedRelayers(msg.sender)) revert NotRelayer(msg.sender);

        bool ethIn = selector == SWAP_ETH_FOR_TOKENS;
        bool ethOut = selector == SWAP_TOKENS_FOR_ETH;
        if (!ethIn && !ethOut && selector != SWAP_TOKENS_FOR_TOKENS) revert InvalidSwapSelector();
        _checkPath(whitelist, ethIn, ethOut, path);

        address outputToken = ethOut ? address(0) : path[1];
        if (whitelist[outputToken] == State.TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(outputToken);

        uint256 balanceBefore = _balance(outputToken);
        ISlipstreamSwapRouter.ExactInputSingleParams memory params = ISlipstreamSwapRouter.ExactInputSingleParams({
            tokenIn: path[0],
            tokenOut: path[1],
            tickSpacing: TICK_SPACING,
            recipient: ethOut ? router : address(this),
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        uint256 swapped = ethIn ? _swapEthIn(router, params) : _swapToEth(router, params);

        uint256 received = _balance(outputToken) - balanceBefore;
        if (ethOut) {
            if (received < swapped) revert SwapOutputNotReceived(received, swapped);
            amountOut = swapped;
        } else {
            amountOut = received < swapped ? received : swapped;
        }
        if (amountOut < amountOutMin) revert InsufficientOutputAmount(amountOut, amountOutMin);
    }

    /// @dev ETH -> token swap.
    function _swapEthIn(address router, ISlipstreamSwapRouter.ExactInputSingleParams memory params)
        private
        returns (uint256 swapped)
    {
        uint256 routerEthBefore = router.balance;
        uint256 ethBefore = address(this).balance;
        swapped = ISlipstreamSwapRouter(router).exactInputSingle{value: params.amountIn}(params);
        if (address(this).balance + params.amountIn != ethBefore + routerEthBefore) revert SwapInputNotFullySpent();
    }

    /// @dev Token -> ETH swap through the router's multicall.
    function _swapToEth(address router, ISlipstreamSwapRouter.ExactInputSingleParams memory params)
        private
        returns (uint256 swapped)
    {
        IERC20 tokenIn = IERC20(params.tokenIn);
        uint256 inputBefore = tokenIn.balanceOf(address(this));
        tokenIn.forceApprove(router, params.amountIn);
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(ISlipstreamSwapRouter.exactInputSingle, (params));
        calls[1] = abi.encodeCall(ISlipstreamSwapRouter.unwrapWETH9, (params.amountOutMinimum, address(this)));
        bytes[] memory results = ISlipstreamSwapRouter(router).multicall(calls);
        swapped = abi.decode(results[0], (uint256));
        if (tokenIn.balanceOf(address(this)) + params.amountIn != inputBefore) revert SwapInputNotFullySpent();
    }

    /// @dev Checks the path against the pinned pair and the whitelist.
    function _checkPath(
        mapping(address => State.TokenType) storage whitelist,
        bool ethIn,
        bool ethOut,
        address[] memory path
    ) private view {
        if (path.length != 2) revert UnsupportedPathLength(path.length);
        if (!((path[0] == WETH && path[1] == USDC) || (path[0] == USDC && path[1] == WETH))) {
            revert UnsupportedPair(path[0], path[1]);
        }
        for (uint256 i = 0; i < 2; i++) {
            address token = path[i];
            if ((i == 0 && ethIn) || (i == 1 && ethOut)) {
                if (token != WETH) revert NotWrappedNative(token);
                continue;
            }
            if (token == WETH) revert WrappedNativeAsToken();
            State.TokenType tt = whitelist[token];
            if (tt == State.TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(token);
            if (tt != State.TokenType.ERC20) revert UnsupportedToken(token);
        }
    }

    function _balance(address token) private view returns (uint256) {
        return token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));
    }
}
