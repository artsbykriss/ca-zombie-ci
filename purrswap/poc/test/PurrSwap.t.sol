// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

// ---------------------------------------------------------------------------
// PurrSwap (Abracadabra) — HyperEVM (chainid 999) live-state + mechanism PoC
//
// READ-ONLY FORK ONLY. No broadcasts. Nothing is signed against a real chain.
//
// Proves:
//   (a) C-06  — Factory.create() accepts an ARBITRARY oracle with no validation
//               (permissionless pool creation; attacker fully controls `i`).
//   (b) H-02/M-06 — the two live pools have _ORACLE_ == address(0), so
//               getEffectiveI() returns the frozen _I_. No malicious oracle is
//               needed for the stale-price condition; it is permanent.
//               Demonstrated by pricing a swap at the frozen i vs the market i.
//   (c) both live pools hold dust only => external-unprivileged extractable = $0.
// ---------------------------------------------------------------------------

interface IFactory {
    function implementation() external view returns (address);
    function owner() external view returns (address);
    function create(
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_,
        address oracle_
    ) external returns (address clone);
    function getPoolCount(address, address) external view returns (uint256);
}

interface IPurrLP {
    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 Q;
        uint256 B0;
        uint256 Q0;
        uint8 R;
    }

    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
    function _ORACLE_() external view returns (address);
    function _I_() external view returns (uint256);
    function _K_() external view returns (uint256);
    function getEffectiveI() external view returns (uint256);
    function getReserves() external view returns (uint256, uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function version() external view returns (string memory);
    function owner() external view returns (address);

    function getPMMStateForCall()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function querySellBase(PMMState memory state, address trader, uint256 payBaseAmount)
        external
        view
        returns (uint256, uint256, uint8, uint256);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint256 deadline
    ) external returns (uint256, uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

/// @dev A trivially malicious oracle: returns any `i` the attacker sets.
contract MockOracle {
    uint256 public p;

    constructor(uint256 p_) {
        p = p_;
    }

    function setPrice(uint256 p_) external {
        p = p_;
    }

    function price(address) external view returns (uint256) {
        return p;
    }
}

contract PurrSwapTest is Test {
    // ---- HyperEVM mainnet (chainid 999) -----------------------------------
    uint256 constant FORK_BLOCK = 49_292_001; // recorded 2026-10-23

    address constant FACTORY = 0x802762e604CE08a79DA2BA809281D727A690Fa0d;
    address constant IMPL = 0x76DA31D7C9CbEAE102aff34D3398bC450c8374c1;
    address constant SAFE = 0xfB3485c2e209A5cfBDC1447674256578f1A80eE3;

    // The only two pools that exist (global LogCreated scan == 2).
    address constant POOL1 = 0x4E90767E92E58170F6732a7Fa652e03B82e5bb44; // WHYPE/KEI
    address constant POOL2 = 0x7B3959da5d74648Af48B8D69e19ea6a9812cdFDB; // wstHYPE/WHYPE

    address constant WHYPE = 0x5555555555555555555555555555555555555555;
    address constant WSTHYPE = 0x94e8396e0869c9F2200760aF0621aFd240E1CF38;
    address constant KEI = 0xB5fE77d323d69eB352A02006eA8ecC38D882620C;

    // The only real LP of pool 2 (holds 495147544162277 LP shares).
    address constant LP2 = 0x1453Acb73B4c13BCE00496Ae00DdC7E4cF484C6c;

    // DefiLlama USD prices, 2026-10-23 (coins.llama.fi/prices/current), 1e18 fp.
    uint256 constant P_WHYPE = 78_516_523_672_358_570_000; // $78.5165
    uint256 constant P_WSTHYPE = 80_585_687_615_321_770_000; // $80.5857
    // market i for wstHYPE/WHYPE = p_wstHYPE / p_WHYPE
    uint256 constant MARKET_I = 1_026_353_229_182_657_408; // ~1.02635e18

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("HYPER_RPC_URL", string("https://rpc.hyperliquid.xyz/evm")), FORK_BLOCK
        );
    }

    // ------------------------------------------------------------------
    // (a) C-06 — no oracle validation in Factory.create()
    // ------------------------------------------------------------------
    function test_C06_factoryCreate_noOracleValidation() public {
        IFactory f = IFactory(FACTORY);

        // Deployed reality.
        assertEq(f.implementation(), IMPL, "implementation");
        assertEq(f.owner(), SAFE, "factory owner is the Abracadabra safe");
        assertEq(block.chainid, 999, "chain id");

        // Permissionless: any EOA can create a pool with ANY oracle address.
        MockOracle mock = new MockOracle(1e18);
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        address clone = f.create(WHYPE, WSTHYPE, 1e14, 1e18, 1e14, address(mock));

        assertTrue(clone.code.length > 0, "clone deployed");
        assertEq(IPurrLP(clone)._ORACLE_(), address(mock), "attacker oracle accepted");
        assertEq(IPurrLP(clone).getEffectiveI(), 1e18, "oracle drives i");

        // The attacker now fully controls the pool price, mid-transaction:
        mock.setPrice(5e18);
        assertEq(IPurrLP(clone).getEffectiveI(), 5e18, "attacker sets i to 5e18");
        mock.setPrice(0.01e18);
        assertEq(IPurrLP(clone).getEffectiveI(), 0.01e18, "attacker sets i to 0.01e18");

        // No whitelist: a second, unrelated caller with a different arbitrary
        // oracle (here a bare EOA with no code) is also accepted.
        vm.prank(makeAddr("attacker2"));
        address clone2 = f.create(WHYPE, WSTHYPE, 1e14, 1e18, 1e14, address(0xdead));
        assertTrue(clone2.code.length > 0, "second clone deployed");
        assertEq(IPurrLP(clone2)._ORACLE_(), address(0xdead), "arbitrary EOA oracle accepted");

        // Factory tracks both pools for the same token pair.
        assertEq(f.getPoolCount(WHYPE, WSTHYPE), 2, "both pools registered");

        console2.log("C-06: create() with arbitrary oracle SUCCEEDED, clone", clone);
        console2.log("C-06: clone2 (oracle = 0xdead) ", clone2);
    }

    // ------------------------------------------------------------------
    // (b) H-02 / M-06 — live pools are permanently stale (oracle == 0)
    // ------------------------------------------------------------------
    function test_H02_M06_livePools_haveFrozenI() public {
        IPurrLP p1 = IPurrLP(POOL1);
        IPurrLP p2 = IPurrLP(POOL2);

        // Version / identity.
        assertEq(p1.version(), "PurrLp 1.0.0", "pool1 version");
        assertEq(p2.version(), "PurrLp 1.0.0", "pool2 version");

        // No oracle on either live pool -> getEffectiveI() returns frozen _I_.
        assertEq(p1._ORACLE_(), address(0), "pool1 oracle == 0");
        assertEq(p2._ORACLE_(), address(0), "pool2 oracle == 0");
        assertEq(p1.getEffectiveI(), p1._I_(), "pool1 frozen i");
        assertEq(p2.getEffectiveI(), p2._I_(), "pool2 frozen i");
        assertEq(p1._I_(), 15e18, "pool1 _I_ = 15");
        assertEq(p2._I_(), 1e18, "pool2 _I_ = 1");

        // PurrLP has no setParameters()/_I_ setter and no oracle setter:
        // _I_ and _ORACLE_ are written only in init() (immutable thereafter).
        (bool ok,) = POOL2.call(abi.encodeWithSignature("setParameters(uint256,uint256,uint256,uint256,uint256)"));
        assertFalse(ok, "no setParameters on live pool");
        (bool ok2,) = POOL2.call(abi.encodeWithSignature("setOracle(address)", address(0xdead)));
        assertFalse(ok2, "no oracle setter on live pool");

        console2.log("H-02/M-06: pool1 frozen i =", p1.getEffectiveI());
        console2.log("H-02/M-06: pool2 frozen i =", p2.getEffectiveI());
    }

    // ------------------------------------------------------------------
    // (b cont.) frozen i vs market i -> stale price is real & quantified
    // ------------------------------------------------------------------
    function test_stalePrice_frozenIVsMarketI() public {
        IPurrLP p2 = IPurrLP(POOL2);

        (uint256 i, uint256 K, uint256 B, uint256 Q, uint256 B0, uint256 Q0, uint256 R) =
            p2.getPMMStateForCall();
        assertEq(i, 1e18, "pool uses frozen i");

        // Market ratio wstHYPE/WHYPE is ~1.02635, i.e. ~2.6% above the frozen 1.0.
        assertEq(MARKET_I, 1_026_353_229_182_657_408, "market i constant");
        assertGt(MARKET_I, i, "market i above frozen i");

        uint256 amt = 1e12; // tiny sell, well below reserves, to read marginal price
        IPurrLP.PMMState memory sFrozen = IPurrLP.PMMState(i, K, B, Q, B0, Q0, uint8(R));
        IPurrLP.PMMState memory sMarket = IPurrLP.PMMState(MARKET_I, K, B, Q, B0, Q0, uint8(R));

        (uint256 outFrozen,,,) = p2.querySellBase(sFrozen, address(0), amt);
        (uint256 outMarket,,,) = p2.querySellBase(sMarket, address(0), amt);

        console2.log("querySellBase(1e12) @ frozen i :", outFrozen);
        console2.log("querySellBase(1e12) @ market i :", outMarket);

        assertGt(outMarket, outFrozen, "market price pays more quote");
        // >1% mispricing on the marginal quote.
        assertGt((outMarket - outFrozen) * 1e18 / outFrozen, 1e16, ">1% stale mispricing");
    }

    // ------------------------------------------------------------------
    // (c) both live pools hold dust only -> E-U extractable = $0
    // ------------------------------------------------------------------
    function test_livePools_holdDustOnly() public {
        uint256 b1 = IERC20(WHYPE).balanceOf(POOL1);
        uint256 q1 = IERC20(KEI).balanceOf(POOL1);
        uint256 b2 = IERC20(WSTHYPE).balanceOf(POOL2);
        uint256 q2 = IERC20(WHYPE).balanceOf(POOL2);

        // USD value (KEI is unpriced; assume a deliberately generous $1/KEI).
        uint256 usd1 = (b1 * P_WHYPE) / 1e18 + (q1 * 1e18) / 1e18;
        uint256 usd2 = (b2 * P_WSTHYPE) / 1e18 + (q2 * P_WHYPE) / 1e18;

        console2.log("pool1 WHYPE wei", b1);
        console2.log("pool1 KEI wei  ", q1);
        console2.log("pool1 USD (1e18) [KEI@$1 upper bound]", usd1);
        console2.log("pool2 wstHYPE wei", b2);
        console2.log("pool2 WHYPE wei  ", q2);
        console2.log("pool2 USD (1e18)", usd2);

        // Both pools below $1 (in fact pool1 < $1e-12, pool2 ~ $0.078).
        assertLt(usd1, 1e18, "pool1 < $1");
        assertLt(usd2, 1e18, "pool2 < $1");

        // Pool 1 never got a real LP: totalSupply is exactly the 1001 dead shares.
        assertEq(IPurrLP(POOL1).totalSupply(), 1001, "pool1 only dead shares");
        assertEq(IPurrLP(POOL1).balanceOf(address(0)), 1001, "pool1 shares burned to 0x0");
        assertEq(IPurrLP(POOL1).balanceOf(LP2), 0, "pool1: no real LP");
    }

    // ------------------------------------------------------------------
    // (c cont.) the dust that does exist is H-O (LP can self-withdraw)
    // ------------------------------------------------------------------
    function test_HO_lpCanSelfWithdrawDust() public {
        IPurrLP p2 = IPurrLP(POOL2);
        uint256 shares = p2.balanceOf(LP2);
        assertGt(shares, 0, "LP2 holds shares");

        uint256 beforeB = IERC20(WSTHYPE).balanceOf(LP2);
        uint256 beforeQ = IERC20(WHYPE).balanceOf(LP2);

        vm.prank(LP2);
        (uint256 baseAmt, uint256 quoteAmt) =
            p2.sellShares(shares, LP2, 0, 0, block.timestamp + 1);

        assertEq(IERC20(WSTHYPE).balanceOf(LP2), beforeB + baseAmt, "wstHYPE withdrawn");
        assertEq(IERC20(WHYPE).balanceOf(LP2), beforeQ + quoteAmt, "WHYPE withdrawn");

        console2.log("H-O: LP2 withdrew wstHYPE", baseAmt);
        console2.log("H-O: LP2 withdrew WHYPE  ", quoteAmt);
    }
}
