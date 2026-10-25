// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9Like {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title MockSlipstreamRouter
 * @notice Test stand-in for Aerodrome Slipstream's SwapRouter, with the entry points
 *         NullmaskSwapSlipstream calls and the same payment rules as the Uniswap V3
 *         periphery it is built on: ETH sent with `exactInputSingle` is wrapped only for
 *         what the swap consumes, and the call ends by refunding the caller every wei the
 *         router holds (`refundETH`); `unwrapWETH9` unwraps the router's whole WETH balance;
 *         `multicall` delegatecalls itself. So ETH or WETH parked in the router reaches the
 *         caller, as with the real one. It swaps at a fixed price and
 *         pays the output out of `vault` (standing in for the pool), never out of its own
 *         balance - like the real router, which holds nothing between calls. A test funds
 *         the vault with the output token first.
 *
 *         Knobs for the failure cases: `shortfallBps` leaves part of the input unconsumed (a
 *         pool that hit its price limit) and `skipMinimum` skips the router's own slippage
 *         check, so the library's check is what stops the swap. Every knob's zero value is
 *         the honest default, so the mock also works when its code is copied elsewhere with
 *         hardhat_setCode (storage is not copied).
 */
contract MockSlipstreamRouter {
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

    address public immutable WETH9;
    address public immutable factory;
    MockSlipstreamVault public immutable vault;

    /// amountOut = consumed * rateNum / rateDen; 1:1 while rateDen is zero.
    uint256 public rateNum;
    uint256 public rateDen;
    /// Part of the input, in basis points, the swap leaves unconsumed.
    uint256 public shortfallBps;
    bool public skipMinimum;

    int24 public lastTickSpacing;
    address public lastRecipient;
    uint256 public lastAmountIn;
    uint256 public swaps;

    constructor(address weth9, address factory_) {
        WETH9 = weth9;
        factory = factory_;
        vault = new MockSlipstreamVault();
    }

    receive() external payable {
        require(msg.sender == WETH9, "Not WETH9");
    }

    function setRate(uint256 num, uint256 den) external {
        rateNum = num;
        rateDen = den;
    }

    function setShortfallBps(uint256 bps) external {
        shortfallBps = bps;
    }

    function setSkipMinimum(bool skip) external {
        skipMinimum = skip;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        require(block.timestamp <= params.deadline, "Transaction too old");
        lastTickSpacing = params.tickSpacing;
        lastRecipient = params.recipient;
        lastAmountIn = params.amountIn;
        swaps += 1;

        uint256 consumed = params.amountIn - (params.amountIn * shortfallBps) / 10_000;
        _pay(params.tokenIn, msg.sender, consumed);

        amountOut = rateDen == 0 ? consumed : (consumed * rateNum) / rateDen;
        vault.pay(params.tokenOut, params.recipient, amountOut);
        if (!skipMinimum) require(amountOut >= params.amountOutMinimum, "Too little received");
        _refundETH();
    }

    /// PeripheryPayments.refundETH: every wei the router holds, to the caller.
    function _refundETH() private {
        if (address(this).balance > 0) {
            (bool ok,) = msg.sender.call{value: address(this).balance}("");
            require(ok, "STE");
        }
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable {
        uint256 balance = IWETH9Like(WETH9).balanceOf(address(this));
        require(balance >= amountMinimum, "Insufficient WETH9");
        if (balance > 0) {
            IWETH9Like(WETH9).withdraw(balance);
            (bool ok,) = recipient.call{value: balance}("");
            require(ok, "STE");
        }
    }

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
            results[i] = result;
        }
    }

    /// Uniswap V3 PeripheryPayments.pay, the input side of a swap.
    function _pay(address token, address payer, uint256 value) private {
        if (token == WETH9 && address(this).balance >= value) {
            IWETH9Like(WETH9).deposit{value: value}();
            require(IWETH9Like(WETH9).transfer(address(vault), value), "transfer in");
        } else {
            require(IERC20(token).transferFrom(payer, address(vault), value), "transfer in");
        }
    }
}

/// The liquidity behind MockSlipstreamRouter: receives the input, pays the output.
contract MockSlipstreamVault {
    address public immutable router;

    constructor() {
        router = msg.sender;
    }

    function pay(address token, address to, uint256 amount) external {
        require(msg.sender == router, "only router");
        require(IERC20(token).transfer(to, amount), "transfer out");
    }
}
