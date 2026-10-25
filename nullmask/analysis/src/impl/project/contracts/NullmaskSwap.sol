// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {State} from "./State.sol";

interface IUniswapV2Router {
    function WETH() external view returns (address);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/// @dev The pool's relayer allowlist, read through the pool.
interface INullmaskSwapRelayers {
    function allowedRelayers(address relayer) external view returns (bool);
}

/// @title NullmaskSwap
/// @notice The Uniswap V2 leg of `Nullmask.shieldedSwap`, linked into the pool and run by DELEGATECALL.
library NullmaskSwap {
    using SafeERC20 for IERC20;

    error TokenNotWhitelisted(address token);
    error InvalidSwapSelector();
    error NotRelayer(address caller);
    error InsufficientOutputAmount(uint256 amountOut, uint256 amountOutMin);

    bytes4 private constant SWAP_TOKENS_FOR_TOKENS = 0x38ed1739;
    bytes4 private constant SWAP_ETH_FOR_TOKENS = 0x7ff36ab5;
    bytes4 private constant SWAP_TOKENS_FOR_ETH = 0x18cbafe5;

    /// @notice Runs one router swap and returns the amount credited to the output note.
    function swap(
        mapping(address => State.TokenType) storage whitelist,
        address router,
        bytes4 selector,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) external returns (uint256) {
        if (!INullmaskSwapRelayers(address(this)).allowedRelayers(msg.sender)) revert NotRelayer(msg.sender);
        bool feeOnTransfer = _checkPath(whitelist, selector, path);

        bool outputIsETH = selector == SWAP_TOKENS_FOR_ETH;
        address outputToken = outputIsETH ? address(0) : path[path.length - 1];
        if (whitelist[outputToken] == State.TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(outputToken);

        uint256 balanceBefore = outputIsETH ? address(this).balance : IERC20(outputToken).balanceOf(address(this));
        uint256 swapped = type(uint256).max;
        uint256 parked;

        if (selector == SWAP_TOKENS_FOR_TOKENS) {
            IERC20(path[0]).forceApprove(router, amountIn);
            if (feeOnTransfer) {
                IUniswapV2Router(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn, amountOutMin, path, address(this), deadline
                );
            } else {
                swapped = IUniswapV2Router(router).swapExactTokensForTokens(
                    amountIn, amountOutMin, path, address(this), deadline
                )[path.length - 1];
            }
        } else if (selector == SWAP_ETH_FOR_TOKENS) {
            if (feeOnTransfer) {
                IUniswapV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                );
            } else {
                swapped = IUniswapV2Router(router).swapExactETHForTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                )[path.length - 1];
            }
        } else if (selector == SWAP_TOKENS_FOR_ETH) {
            IERC20(path[0]).forceApprove(router, amountIn);
            if (feeOnTransfer) {
                parked = IERC20(IUniswapV2Router(router).WETH()).balanceOf(router);
                IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn, amountOutMin, path, address(this), deadline
                );
            } else {
                swapped = IUniswapV2Router(router).swapExactTokensForETH(
                    amountIn, amountOutMin, path, address(this), deadline
                )[path.length - 1];
            }
        } else {
            revert InvalidSwapSelector();
        }

        uint256 balanceAfter = outputIsETH ? address(this).balance : IERC20(outputToken).balanceOf(address(this));
        uint256 amountOut = balanceAfter - balanceBefore - parked;
        if (amountOut > swapped) amountOut = swapped;
        if (amountOut < amountOutMin) revert InsufficientOutputAmount(amountOut, amountOutMin);
        return amountOut;
    }

    /// @dev Checks every token on the path against the whitelist; true if any may take a fee on transfer.
    function _checkPath(mapping(address => State.TokenType) storage whitelist, bytes4 selector, address[] memory path)
        private
        view
        returns (bool feeOnTransfer)
    {
        uint256 last = path.length - 1;
        for (uint256 i = 0; i < path.length; i++) {
            State.TokenType tt = whitelist[path[i]];
            bool wethEnd = (i == 0 && selector == SWAP_ETH_FOR_TOKENS) || (i == last && selector == SWAP_TOKENS_FOR_ETH);
            if (tt != State.TokenType.ERC20 && tt != State.TokenType.NATIVE_TOKEN && !wethEnd) feeOnTransfer = true;
            if (tt == State.TokenType.NOT_ALLOWED && !wethEnd) revert TokenNotWhitelisted(path[i]);
        }
    }
}
