// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IERC20, IUniswapV2Pair, IUniswapV3Factory, IUniswapV3Pool, IWETH} from "../src/Interfaces.sol";

/// @title BOT Chain (BDEX V3/V2) fork verification
/// @notice Read-only fork checks: the V3 core is canonical Uniswap V3, the pool prices
///         WBOT consistently across venues, and the USDT/USDT0 mint paths are gated.
contract BdexTest is Test {
    string constant RPC = "https://rpc.botchain.ai"; // keyless public endpoint

    address constant WBOT = 0xD5452816194a3784dBa983426cCe7c122F4abd30; // canonical WETH (0.7.6)
    address constant USDT = 0xaBabc7Ddc03e501d190C676BF3d92ef0e6e87a3C; // OZ ERC20 + AccessControl
    address constant USDT0 = 0x9841194c1F6f8359d0ff1a98fB2C3A6A17357cE0; // fixed-supply, 4 holders
    address constant V3_FACTORY = 0x1C51c173323ec11BB4e3C4fD2314c225Dc4b5419;
    address constant V2_FACTORY = 0x117115f3B72C8d1989178089A67D0C26f8EE0AA3;
    address constant V3_POOL = 0x64F418471a1A7932a190E10da5A8551dB5AbeC05; // USDT/WBOT 0.3%
    address constant V2_PAIR = 0xdc7547f3cEa82C6Af7fd420656cE532C6da9b98d; // USDT/WBOT
    address constant V3_OWNER = 0x4a1aAD72622Ede44B4ffCba4c86E2eCbD2dD930e;
    address constant ATTACKER = 0x00000000000000000000000000000000BADadd57;

    uint160 constant MIN_SQRT_RATIO = 4295128739;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    uint256 forkBlock;

    function setUp() public {
        forkBlock = vm.createSelectFork(RPC);
        emit log_named_uint("fork block", forkBlock);
    }

    // ------------------------------------------------------------------
    // 1. Factory / pool wiring is canonical Uniswap V3
    // ------------------------------------------------------------------
    function test_v3_factory_and_pool_state() public {
        assertEq(IUniswapV3Factory(V3_FACTORY).owner(), V3_OWNER, "factory owner");
        assertEq(IUniswapV3Factory(V3_FACTORY).feeAmountTickSpacing(3000), 60, "0.3% tick spacing");
        assertEq(IUniswapV3Factory(V3_FACTORY).getPool(USDT, WBOT, 3000), V3_POOL, "pool address");

        assertEq(IUniswapV3Pool(V3_POOL).token0(), USDT, "token0 = USDT");
        assertEq(IUniswapV3Pool(V3_POOL).token1(), WBOT, "token1 = WBOT");
        assertEq(IUniswapV3Pool(V3_POOL).fee(), 3000, "fee = 0.3%");
        assertGt(IUniswapV3Pool(V3_POOL).liquidity(), 0, "pool has liquidity");

        uint256 usdtBal = IERC20(USDT).balanceOf(V3_POOL);
        uint256 wbotBal = IERC20(WBOT).balanceOf(V3_POOL);
        emit log_named_uint("pool USDT (1e6)", usdtBal / 1e6);
        emit log_named_uint("pool WBOT (1e18)", wbotBal / 1e18);
        assertGt(usdtBal, 10_000_000e6, "pool holds >10M USDT");
        assertGt(wbotBal, 1_000_000e18, "pool holds >1M WBOT");

        uint256 priceE6 = (usdtBal * 1e18) / wbotBal; // USDT per WBOT, scaled 1e6
        emit log_named_uint("implied WBOT price (USDT, 1e6)", priceE6);
        assertGt(priceE6, 10e6, "price > 10 USDT");
        assertLt(priceE6, 15e6, "price < 15 USDT");
    }

    function test_v3_factory_setOwner_is_owner_gated() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = V3_FACTORY.call(abi.encodeWithSignature("setOwner(address)", ATTACKER));
        assertFalse(ok, "setOwner must revert for external caller");
        emit log_named_bytes("setOwner revert", ret);
    }

    // ------------------------------------------------------------------
    // 2. USDT / USDT0 mint paths are gated
    // ------------------------------------------------------------------
    function test_usdt_mint_is_role_gated() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = USDT.call(abi.encodeWithSignature("mint(address,uint256)", ATTACKER, 1_000_000e6));
        assertFalse(ok, "USDT.mint must revert for external caller");
        emit log_named_bytes("USDT.mint revert", ret);

        // MINTER_ROLE holders are EOAs (no bridge contract holds the role)
        bytes32 minterRole = keccak256("MINTER_ROLE");
        (bool ok2, bytes memory ret2) = USDT.staticcall(abi.encodeWithSignature("hasRole(bytes32,address)", minterRole, ATTACKER));
        assertTrue(ok2);
        assertEq(abi.decode(ret2, (bool)), false, "attacker has no MINTER_ROLE");
    }

    function test_usdt0_has_no_mint_function() public {
        vm.prank(ATTACKER);
        (bool ok, ) = USDT0.call(abi.encodeWithSignature("mint(address,uint256)", ATTACKER, 1e24));
        assertFalse(ok, "USDT0 has no mint");
    }

    // ------------------------------------------------------------------
    // 3. V3 swap is canonical: round-trip loses money (fees), no free money
    // ------------------------------------------------------------------
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == V3_POOL, "callback: bad caller");
        if (amount0Delta > 0) IERC20(USDT).transfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20(WBOT).transfer(msg.sender, uint256(amount1Delta));
    }

    function test_v3_swap_roundtrip_no_free_money() public {
        // fund the test contract with 1 BOT -> 1 WBOT
        vm.deal(address(this), 1 ether);
        IWETH(WBOT).deposit{value: 1 ether}();
        assertEq(IERC20(WBOT).balanceOf(address(this)), 1 ether, "wrapped 1 BOT");

        // WBOT -> USDT (token1 in, token0 out)
        (int256 a0, int256 a1) = IUniswapV3Pool(V3_POOL).swap(address(this), false, int256(1 ether), MAX_SQRT_RATIO - 1, "");
        uint256 usdtOut = uint256(-a0);
        emit log_named_uint("WBOT in (1e18)", uint256(a1));
        emit log_named_uint("USDT out (1e6)", usdtOut / 1e6);
        assertGt(usdtOut, 0, "swap produced USDT");

        // USDT -> WBOT (round trip)
        IUniswapV3Pool(V3_POOL).swap(address(this), true, int256(usdtOut), MIN_SQRT_RATIO + 1, "");
        uint256 wbotFinal = IERC20(WBOT).balanceOf(address(this));
        uint256 usdtFinal = IERC20(USDT).balanceOf(address(this));
        emit log_named_uint("WBOT after round trip (1e18)", wbotFinal);
        emit log_named_uint("USDT after round trip (1e6)", usdtFinal / 1e6);
        assertLt(wbotFinal, 1 ether, "round trip cannot profit (fees paid)");
        assertEq(usdtFinal, 0, "no USDT left over");
    }

    // ------------------------------------------------------------------
    // 4. WBOT price is consistent between V2 and V3 venues (no arb)
    // ------------------------------------------------------------------
    function test_wbot_price_consistent_v2_vs_v3() public {
        (uint112 r0, uint112 r1, ) = IUniswapV2Pair(V2_PAIR).getReserves(); // token0=USDT, token1=WBOT
        uint256 v2PriceE6 = (uint256(r0) * 1e18) / uint256(r1);

        uint256 usdtBal = IERC20(USDT).balanceOf(V3_POOL);
        uint256 wbotBal = IERC20(WBOT).balanceOf(V3_POOL);
        uint256 v3PriceE6 = (usdtBal * 1e18) / wbotBal;

        emit log_named_uint("V2 implied price (1e6)", v2PriceE6);
        emit log_named_uint("V3 implied price (1e6)", v3PriceE6);

        uint256 diff = v2PriceE6 > v3PriceE6 ? v2PriceE6 - v3PriceE6 : v3PriceE6 - v2PriceE6;
        assertLt((diff * 100) / v3PriceE6, 15, "V2/V3 prices within 15% (no exploitable dislocation)");
    }
}
