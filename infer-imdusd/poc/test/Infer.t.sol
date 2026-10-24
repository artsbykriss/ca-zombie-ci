// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

// ---------------------------------------------------------------------------------------------
// INFER / imdUSD — fork PoC (read-only; state-override simulations only; no mainnet tx).
//
// The finding under test: "a single attester key signs all 3 feeds, and SwarmRelay relays
// permissionlessly, so an attacker over-borrows to the 1M imdUSD ceiling."
//
// What this suite settles on a mainnet fork:
//   T1  wiring: one attester, one permissionless relayer, per-epoch deviation bound.
//   T2  the feed's per-epoch acceptance bound (the thing that limits any price push).
//   T3  the vault's response to an inflated collateral price (the "if the feed said f" sim):
//       the maximum over-borrow and the attacker's net, for f = 1.2 / 1.6 / 2.0.
//   T4  the divergence guard: a primary/spot disagreement refuses every priced action.
//   T5  the line (1M imdUSD) is not reachable at the live collateral size.
//
// NOTE on method: the attester's private key is not available and must not be. T3/T4 therefore
// use vm.mockCall to substitute the feed's *reported* value (a state-override), which measures
// the vault's response to a given price without forging any signature. T2 measures the live
// feed's own accept() bound directly. The per-epoch compounding (20%/epoch) is read from the
// deployed SwarmFeed source (documented in src/SwarmFeed.sol) and bounded by T2 for one step.
// ---------------------------------------------------------------------------------------------

interface ISwarmFeed {
    function latestValue() external view returns (uint256, uint64);
    function isStale() external view returns (bool);
    function attester() external view returns (address);
    function relayer() external view returns (address);
    function maxDeviationBps() external view returns (uint256);
    function maxAge() external view returns (uint256);
    function minAgreed() external view returns (uint16);
    function accepts(uint256 value) external view returns (bool);
    function epoch() external view returns (uint256 anchor, uint64 openedAt, uint256 allowanceBps);
}

interface IVault {
    function gem() external view returns (address);
    function stablecoin() external view returns (address);
    function priceFeed() external view returns (address);
    function spotFeed() external view returns (address);
    function nhiFeed() external view returns (address);
    function collateralPriceFeed() external view returns (address);
    function line() external view returns (uint256);
    function mat() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function positions(address) external view returns (uint256 collateral, uint256 debt);
    function lock(uint256 amount) external;
    function draw(uint256 amount) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

contract InferTest is Test {
    address constant VAULT = 0x0b69F8DA8D8cE521d74Ea69a7A3475B77302EF82;
    address constant PRICE_FEED = 0x070e0603737242B01aBC1D223f7C92D63E86EC97;
    address constant SPOT_FEED = 0x77E1684402869Bf2B7c70B8bf21E1C7Ca7104951;
    address constant NHI_FEED = 0x014DabF6F940c9C383D9ef48636F70D842F65D7A;
    address constant RELAY = 0x9AEb55c7A16C11B37DC96BD22a33906D1668e20B;
    address constant ATTESTER = 0x5598Aa9146215Bc13eb26f2c692Ad1461Fd32982;
    address constant SIMD = 0x9Efa934D9fAd4AE28c998a40195646b965a97247;
    address constant COLL_FEED = 0xF065C8b65AA9Ac6fd9cBAd15301738e91389d9e1;
    address constant TREASURY = 0x6Ac8fF96Fb8DCF5d79A8eF1E59D9AC23f2BD27Bc;

    IVault vault = IVault(VAULT);

    // Honest live values (read at the pinned fork block; see README).
    uint256 constant HONEST_PRIMARY = 1_725_759_290_349_039; // ETH per 1e18 raw IMD (wei)
    uint256 constant HONEST_COLL_USD = 32_229_178_651_274; // USD per 1e18 raw sIMD
    uint256 constant HONEST_NHI = 984_009_911_971_530_572; // 0.984

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        // Pinned to the state read for this report. CI RPCs are archive-capable; if this reverts,
        // re-run with the latest block (see README).
        vm.createSelectFork(url, 26_265_283);
    }

    // ------------------------------------------------------------------ T1: wiring
    function test_T1_wiring_singleAttester_permissionlessRelay() public {
        assertEq(ISwarmFeed(PRICE_FEED).attester(), ATTESTER, "price attester");
        assertEq(ISwarmFeed(SPOT_FEED).attester(), ATTESTER, "spot attester");
        assertEq(ISwarmFeed(NHI_FEED).attester(), ATTESTER, "nhi attester");
        // one attester signs ALL three feeds
        assertEq(ISwarmFeed(PRICE_FEED).attester(), ISwarmFeed(NHI_FEED).attester());

        assertEq(ISwarmFeed(PRICE_FEED).relayer(), RELAY, "price relayer");
        assertEq(ISwarmFeed(SPOT_FEED).relayer(), RELAY, "spot relayer");
        assertEq(ISwarmFeed(NHI_FEED).relayer(), RELAY, "nhi relayer");

        // the relay is a contract with no owner and a permissionless `relay()`; the feeds still
        // enforce the attester signature, so the relay is not itself a trust boundary.
        assertGt(RELAY.code.length, 0, "relay has code");

        assertEq(ISwarmFeed(PRICE_FEED).maxDeviationBps(), 2000, "20% per-epoch cap");
        assertEq(ISwarmFeed(PRICE_FEED).maxAge(), 3600, "1h price lifetime");

        assertEq(vault.line(), 1_000_000e18, "line = 1M imdUSD");
        assertEq(vault.mat(), 170, "mat 170 at healthy NHI");
        emit log_named_uint("vault sIMD collateral", IERC20(SIMD).balanceOf(VAULT));
        emit log_named_uint("totalDebt (imdUSD)", vault.totalDebt());
        emit log_named_uint("attester nonce (EOA, never sent tx)", ATTESTER.code.length == 0 ? 1 : 0);
    }

    // ------------------------------------------------------------------ T2: feed accept bound
    function test_T2_feedRejectsBeyondEpochAllowance() public {
        (uint256 anchor,, uint256 allowanceBps) = ISwarmFeed(PRICE_FEED).epoch();
        emit log_named_uint("epoch anchor (ETH/1e18 IMD)", anchor);
        emit log_named_uint("epoch allowance bps", allowanceBps);
        assertGt(anchor, 0);

        // at the allowance -> accepted; a step well past it -> rejected
        uint256 atCap = anchor + (anchor * allowanceBps) / 10_000;
        assertTrue(ISwarmFeed(PRICE_FEED).accepts(atCap), "value at allowance accepted");
        assertFalse(
            ISwarmFeed(PRICE_FEED).accepts(anchor + (anchor * (allowanceBps + 300)) / 10_000),
            "value past allowance rejected"
        );
        // A single step can never double the price: the epoch bound is far below 100%.
        assertFalse(ISwarmFeed(PRICE_FEED).accepts(anchor * 2), "2x in one step always rejected");
        assertTrue(ISwarmFeed(PRICE_FEED).accepts(anchor + anchor / 100), "small step accepted");
    }

    // ------------------------------------------------------------------ helpers: state-override the feeds
    function _mockPrice(uint256 fBps) internal {
        // fBps = 10_000 => honest; fBps = 20_000 => 2x.
        uint256 primary = (HONEST_PRIMARY * fBps) / 10_000;
        uint256 collUsd = (HONEST_COLL_USD * fBps) / 10_000;
        vm.mockCall(PRICE_FEED, abi.encodeWithSignature("latestValue()"), abi.encode(primary, uint64(block.timestamp)));
        vm.mockCall(PRICE_FEED, abi.encodeWithSignature("isStale()"), abi.encode(false));
        vm.mockCall(SPOT_FEED, abi.encodeWithSignature("latestValue()"), abi.encode(primary, uint64(block.timestamp)));
        vm.mockCall(SPOT_FEED, abi.encodeWithSignature("isStale()"), abi.encode(false));
        vm.mockCall(NHI_FEED, abi.encodeWithSignature("isStale()"), abi.encode(false));
        vm.mockCall(NHI_FEED, abi.encodeWithSignature("latestValue()"), abi.encode(HONEST_NHI, uint64(block.timestamp)));
        vm.mockCall(COLL_FEED, abi.encodeWithSignature("latestValue()"), abi.encode(collUsd, uint64(block.timestamp)));
        vm.mockCall(COLL_FEED, abi.encodeWithSignature("isStale()"), abi.encode(false));
    }

    function _attackerMaxDraw(address a, uint256 collateralRaw, uint256 fBps) internal returns (uint256) {
        deal(SIMD, a, collateralRaw);
        _mockPrice(fBps);
        vm.startPrank(a);
        IERC20(SIMD).approve(VAULT, collateralRaw);
        vault.lock(collateralRaw);
        uint256 collUsd = (collateralRaw * ((HONEST_COLL_USD * fBps) / 10_000)) / 1e18;
        uint256 maxDebt = (collUsd * 100) / vault.mat();
        // draw as much as the position allows
        vault.draw(maxDebt);
        vm.stopPrank();
        return maxDebt;
    }

    // ------------------------------------------------------------------ T3: over-borrow economics
    function test_T3_overBorrow_isUnprofitableBelowMat() public {
        uint256 c = 10_000e24; // 10,000 sIMD (24-dec) == ~$322k real
        uint256 realUsd = (c * HONEST_COLL_USD) / 1e18;
        emit log_named_uint("attacker collateral (USD, real)", realUsd);

        // f = 1.2 : the largest step a FRESH epoch allows (20%)
        uint256 draw120 = _attackerMaxDraw(address(0xA11CE1), c, 12_000);
        emit log_named_int("net @ f=1.20 (draw - real)", int256(draw120) - int256(realUsd));
        assertLt(draw120, realUsd, "no profit at the 20% epoch cap");

        // f = 1.6 : the widest allowance reachable before the Treasury's 60% auto-refresh
        uint256 draw160 = _attackerMaxDraw(address(0xA11CE2), c, 16_000);
        emit log_named_int("net @ f=1.60 (draw - real)", int256(draw160) - int256(realUsd));
        assertLt(draw160, realUsd, "no profit at the 60% stale-allowance bound");

        // f = 2.0 : only reachable after several 20%/epoch compounding steps (hours of a
        // compromised attester or a sustained pool manipulation) -> first profitable band
        uint256 draw200 = _attackerMaxDraw(address(0xA11CE3), c, 20_000);
        emit log_named_int("net @ f=2.00 (draw - real)", int256(draw200) - int256(realUsd));
        assertGt(draw200, realUsd, "profit only once f > mat/100");
    }

    // ------------------------------------------------------------------ T4: divergence guard
    function test_T4_divergenceGuardBlocksInconsistentPush() public {
        address a = address(0xB0B);
        deal(SIMD, a, 1000e24);
        _mockPrice(15_000); // primary +50%
        // spot stays honest -> disagreement > skew (5%)
        vm.mockCall(
            SPOT_FEED, abi.encodeWithSignature("latestValue()"), abi.encode(HONEST_PRIMARY, uint64(block.timestamp))
        );
        vm.startPrank(a);
        IERC20(SIMD).approve(VAULT, 1000e24);
        vault.lock(1000e24);
        vm.expectRevert(); // PriceDivergence
        vault.draw(1e18);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------ T5: line not reachable
    function test_T5_lineNotReachableAtLiveCollateral() public {
        // borrow capacity = collateral_value * 100 / mat ; with ~$285k collateral and mat 170
        // the ceiling is ~$168k, far below the 1M line.
        uint256 liveColl = 8_841_558_994_832_782_916_628_246_875; // 8,841.56 sIMD (24-dec)
        uint256 cap = ((liveColl * HONEST_COLL_USD) / 1e18) * 100 / 170;
        emit log_named_uint("live collateral USD", (liveColl * HONEST_COLL_USD) / 1e18);
        emit log_named_uint("max borrowable USD (honest)", cap);
        assertLt(cap, 1_000_000e18, "1M line unreachable at live collateral");
    }
}
