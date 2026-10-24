// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import {
    IUsdnProtocol,
    ILiquidationRewardsManager,
    IOracleMiddleware,
    IPyth,
    IWstETH,
    IERC20,
    PositionId,
    Position,
    LiqTickInfo,
    PreviousActionsData,
    RewardsParameters,
    PythPrice,
    PythPriceFeed,
    PriceInfo
} from "../src/Interfaces.sol";

/// @title SMARDEX USDN — permissionless-liquidation / oracle / vault round-trip PoC
/// @notice READ-ONLY: forks Ethereum mainnet, never signs or sends to a real chain.
contract UsdnLiquidationPoC is Test {
    // live mainnet addresses (verified via eth_getCode + EIP-1967 slot)
    address constant PROXY = 0x656cB8C6d154Aad29d8771384089be5B5141f01a;
    address constant LIQ_REWARDS = 0x9514D3496F46572e8461da381B200812D5Db202C;
    address constant MIDDLEWARE = 0xC1459fcFe23d5db9Ddb04935ab7a426Bd398EAb0;
    address constant PYTH = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant USDN = 0xde17a000BA631c5d7c2Bd9FB692EFeA52D90DEE2;
    address constant SDEX = 0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF;

    // storage layout (main storage base + offsets) derived from the verified Storage struct
    uint256 constant STORAGE_MAIN = 0xd143a936a6a372725e12535db83a2cfabcb3715dfd88bc350da3399604dc9700;
    uint256 constant SLOT_LASTPRICE = STORAGE_MAIN + 26;
    uint256 constant SLOT_HIGHEST = STORAGE_MAIN + 41;
    uint256 constant SLOT_TOTALPOS = STORAGE_MAIN + 42;
    uint256 constant SLOT_BITMAP = STORAGE_MAIN + 43;
    int24 constant MIN_TICK = -322_378;
    int24 constant TICK_SPACING = 100;

    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")))
        );
    }

    /* ------------------------------------------------------------------ */
    /*                             helpers                                */
    /* ------------------------------------------------------------------ */

    function _lastPrice() internal view returns (uint128) {
        return uint128(uint256(vm.load(PROXY, bytes32(SLOT_LASTPRICE))));
    }

    function _highestPopulatedTick() internal view returns (int24 tick) {
        int24 raw = int24(uint24(uint256(vm.load(PROXY, bytes32(SLOT_HIGHEST)))));
        // scan the bitmap downward for the highest set bit
        uint256 maxIndex = _indexFromTick(raw);
        for (uint256 w = maxIndex >> 8;; --w) {
            uint256 word = uint256(vm.load(PROXY, keccak256(abi.encode(w, SLOT_BITMAP))));
            if (word != 0) {
                uint256 bit = 255;
                while ((word >> bit) & 1 == 0) {
                    --bit;
                }
                return _tickFromIndex((w << 8) + bit);
            }
            if (w == 0) break;
        }
        return MIN_TICK;
    }

    function _indexFromTick(int24 tick) internal pure returns (uint256) {
        return uint256(int256(tick - MIN_TICK)) / uint256(int256(TICK_SPACING));
    }

    function _tickFromIndex(uint256 index) internal pure returns (int24) {
        return int24((int256(index) + int256(MIN_TICK) / int256(TICK_SPACING)) * int256(TICK_SPACING));
    }

    function _pythData() internal pure returns (bytes memory) {
        // 0x504e4155 = PNAU magic so the middleware treats it as a Pyth message
        return abi.encodePacked(bytes4(0x504e4155), bytes32(uint256(1)));
    }

    /// @dev mock the Pyth contract to report a chosen wstETH price (bypasses VAA verification
    ///      to *measure* protocol behaviour; not a claim that Pyth can be forged on-chain).
    function _mockPyth(uint256 wstethPriceE18) internal {
        uint256 stEthPerToken = IWstETH(WSTETH).stEthPerToken();
        uint256 ethPriceE18 = wstethPriceE18 * 1e18 / stEthPerToken;
        int64 p = int64(int256(ethPriceE18 / 1e10)); // expo -8
        PythPriceFeed[] memory feeds = new PythPriceFeed[](1);
        PythPrice memory pp = PythPrice({ price: p, conf: 0, expo: -8, publishTime: uint64(block.timestamp) });
        feeds[0] = PythPriceFeed({ id: bytes32(0), price: pp, emaPrice: pp });
        bytes memory ret = abi.encode(feeds);
        vm.mockCall(PYTH, abi.encodeWithSelector(IPyth.parsePriceFeedUpdates.selector), ret);
        vm.mockCall(PYTH, abi.encodeWithSelector(IPyth.parsePriceFeedUpdatesUnique.selector), ret);
        vm.mockCall(PYTH, abi.encodeWithSelector(IPyth.getUpdateFee.selector), abi.encode(uint256(1)));
    }

    function _empty() internal pure returns (PreviousActionsData memory) {
        return PreviousActionsData({ priceData: new bytes[](0), rawIndices: new uint128[](0) });
    }

    /* ------------------------------------------------------------------ */
    /* 1. book health: no tick is liquidatable at the current price        */
    /* ------------------------------------------------------------------ */
    function test_bookHealthy_noLiquidatableTick() public {
        uint128 lastPrice = _lastPrice();
        int24 topTick = _highestPopulatedTick();
        uint128 topLiq = IUsdnProtocol(PROXY).getEffectivePriceForTick(topTick);
        uint256 bufferBps = uint256(lastPrice - topLiq) * 10_000 / lastPrice;

        emit log_named_uint("lastPrice (wstETH USD, 1e18)", lastPrice);
        emit log_named_int("highest populated tick", topTick);
        emit log_named_uint("weakest position liq price", topLiq);
        emit log_named_uint("buffer of weakest position (bps)", bufferBps);
        emit log_named_uint("open long positions", IUsdnProtocol(PROXY).getTotalLongPositions());
        emit log_named_uint("balanceVault (wstETH, 1e18)", IUsdnProtocol(PROXY).getBalanceVault());
        emit log_named_uint("balanceLong (wstETH, 1e18)", IUsdnProtocol(PROXY).getBalanceLong());

        assertGt(topLiq, 0, "liq price must be positive");
        assertLt(topLiq, lastPrice, "no tick should be liquidatable at the current price");
        // Live-state-dependent floor. The weakest buffer was 814 bps on 2026-10-23 and 687 bps on
        // 2026-10-24; assert a conservative >3% headroom so the test proves the book is healthy
        // (no near-liquidation) while tolerating normal price drift.
        assertGt(bufferBps, 300, "weakest position must be >3% from liquidation");
    }

    /* ------------------------------------------------------------------ */
    /* 2. liquidate requires low-latency (Pyth) data                       */
    /* ------------------------------------------------------------------ */
    function test_liquidate_requiresPythData() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUsdnProtocol(PROXY).liquidate("");
    }

    function test_liquidate_atCurrentPrice_liquidatesNothing() public {
        uint128 lastPrice = _lastPrice();
        _mockPyth(lastPrice); // no price move
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        LiqTickInfo[] memory liq = IUsdnProtocol(PROXY).liquidate{ value: 1 }(_pythData());
        emit log_named_uint("ticks liquidated at current price", liq.length);
        assertEq(liq.length, 0, "nothing should be liquidatable at the current price");
    }

    /* ------------------------------------------------------------------ */
    /* 3. the liquidation reward is hard-capped at maxReward (0.5 ETH)     */
    /* ------------------------------------------------------------------ */
    function test_liquidationReward_isCapped() public {
        RewardsParameters memory rp = ILiquidationRewardsManager(LIQ_REWARDS).getRewardsParameters();
        assertEq(rp.maxReward, 0.5 ether, "cap is 0.5 ETH");

        uint128 lastPrice = _lastPrice();
        // worst case: a huge tick, liquidated far below its price
        LiqTickInfo[] memory ticks = new LiqTickInfo[](1);
        ticks[0] = LiqTickInfo({
            totalPositions: 1000,
            totalExpo: 10_000 ether,
            remainingCollateral: 0,
            tickPrice: uint128(lastPrice * 2),
            priceWithoutPenalty: uint128(lastPrice)
        });
        uint256 rewardWst = ILiquidationRewardsManager(LIQ_REWARDS).getLiquidationRewards(
            ticks, lastPrice, true, 6 /*ClosedOpened*/, 10 /*Liquidation*/, "", ""
        );
        uint256 rewardEth = IWstETH(WSTETH).getStETHByWstETH(rewardWst);
        emit log_named_uint("max-case liquidation reward (wstETH)", rewardWst);
        emit log_named_uint("max-case liquidation reward (stETH/ETH)", rewardEth);
        assertLe(rewardEth, 0.5 ether, "reward cannot exceed maxReward");
    }

    /* ------------------------------------------------------------------ */
    /* 4. forced crash: measure the attacker's reward for liquidating      */
    /* ------------------------------------------------------------------ */
    function test_forcedCrash_liquidatorReward() public {
        int24 topTick = _highestPopulatedTick();
        uint128 topLiq = IUsdnProtocol(PROXY).getEffectivePriceForTick(topTick);
        uint256 crashPrice = uint256(topLiq) * 995 / 1000; // 0.5% below the weakest liq price

        _mockPyth(crashPrice);
        vm.deal(attacker, 1 ether);
        uint256 balBefore = IERC20(WSTETH).balanceOf(attacker);
        vm.prank(attacker);
        LiqTickInfo[] memory liq = IUsdnProtocol(PROXY).liquidate{ value: 1 }(_pythData());
        uint256 balAfter = IERC20(WSTETH).balanceOf(attacker);

        emit log_named_uint("crash price used", crashPrice);
        emit log_named_uint("ticks liquidated", liq.length);
        emit log_named_uint("attacker wstETH reward (1e18)", balAfter - balBefore);
        emit log_named_uint(
            "attacker reward in ETH terms", IWstETH(WSTETH).getStETHByWstETH(balAfter - balBefore)
        );
        // the liquidator only ever receives the (capped) reward, never the collateral
        assertLe(IWstETH(WSTETH).getStETHByWstETH(balAfter - balBefore), 0.5 ether, "reward capped");
    }

    /* ------------------------------------------------------------------ */
    /* 6. oracle: liquidation has no on-chain fallback; parameters live    */
    /* ------------------------------------------------------------------ */
    function test_oracle_liquidationRequiresLowLatency() public {
        IOracleMiddleware mw = IOracleMiddleware(MIDDLEWARE);
        emit log_named_uint("middleware validationDelay (s)", mw.getValidationDelay());
        emit log_named_uint("middleware lowLatencyDelay (s)", mw.getLowLatencyDelay());
        emit log_named_uint("middleware pythRecentPriceDelay (s)", mw.getPythRecentPriceDelay());
        emit log_named_uint("middleware confRatioBps", mw.getConfRatioBps());

        // a Liquidation (action=10) with empty data must revert (Pyth is mandatory, no Chainlink fallback)
        vm.expectRevert();
        mw.parseAndValidatePrice{ value: 0 }(bytes32(0), 0, 10, "");

        // an InitiateDeposit (action=2) with empty data falls back to Chainlink and succeeds
        PriceInfo memory p =
            mw.parseAndValidatePrice{ value: 0 }(bytes32(0), uint128(block.timestamp), 2, "");
        emit log_named_uint("Chainlink fallback ETH price (1e18)", p.price);
        assertGt(p.price, 0, "chainlink fallback must return a price");
    }

    /* ------------------------------------------------------------------ */
    /* 7. full-book crash: total reward an attacker could ever collect      */
    /* ------------------------------------------------------------------ */
    function test_fullBookCrash_totalLiquidatorReward() public {
        _mockPyth(600 ether); // far below every position's liquidation price
        vm.deal(attacker, 1 ether);
        uint256 balBefore = IERC20(WSTETH).balanceOf(attacker);
        uint256 totalTicks;
        for (uint256 i = 0; i < 5; ++i) {
            vm.prank(attacker);
            LiqTickInfo[] memory liq = IUsdnProtocol(PROXY).liquidate{ value: 1 }(_pythData());
            totalTicks += liq.length;
            if (liq.length == 0) break;
        }
        uint256 gained = IERC20(WSTETH).balanceOf(attacker) - balBefore;
        emit log_named_uint("ticks liquidated in full crash", totalTicks);
        emit log_named_uint("total attacker wstETH reward (1e18)", gained);
        emit log_named_uint("total attacker reward in ETH terms", IWstETH(WSTETH).getStETHByWstETH(gained));
        emit log_named_uint("open long positions remaining", IUsdnProtocol(PROXY).getTotalLongPositions());
        // the liquidator never receives collateral; the whole-book ceiling is the reward formula
        assertLe(IWstETH(WSTETH).getStETHByWstETH(gained), 1.5 ether, "full-book reward bounded");
    }

    /* ------------------------------------------------------------------ */
    /* 5. deposit -> withdraw round trip is a loss (no free value)         */
    /* ------------------------------------------------------------------ */
    function test_depositWithdraw_roundTrip_notProfitable() public {
        uint128 lastPrice = _lastPrice();
        _mockPyth(lastPrice);

        vm.deal(attacker, 5 ether);
        deal(WSTETH, attacker, 5 ether);
        deal(SDEX, attacker, 1_000_000 ether);

        vm.startPrank(attacker);
        IERC20(WSTETH).approve(PROXY, type(uint256).max);
        IERC20(SDEX).approve(PROXY, type(uint256).max);
        IERC20(USDN).approve(PROXY, type(uint256).max);

        uint256 wstBefore = IERC20(WSTETH).balanceOf(attacker);
        uint64 dep = IUsdnProtocol(PROXY).getSecurityDepositValue();

        IUsdnProtocol(PROXY).initiateDeposit{ value: dep + 1 }(
            1 ether, 0, attacker, payable(attacker), block.timestamp + 1 days, _pythData(), _empty()
        );
        vm.warp(block.timestamp + 30);
        IUsdnProtocol(PROXY).validateDeposit{ value: 1 }(payable(attacker), _pythData(), _empty());

        uint256 shares = IERC20(USDN).sharesOf(attacker);
        emit log_named_uint("USDN shares minted", shares);
        assertGt(shares, 0, "deposit should mint USDN");

        IUsdnProtocol(PROXY).initiateWithdrawal{ value: dep + 1 }(
            uint152(shares), 0, attacker, payable(attacker), block.timestamp + 1 days, _pythData(), _empty()
        );
        vm.warp(block.timestamp + 30);
        IUsdnProtocol(PROXY).validateWithdrawal{ value: 1 }(payable(attacker), _pythData(), _empty());
        vm.stopPrank();

        uint256 wstAfter = IERC20(WSTETH).balanceOf(attacker);
        emit log_named_uint("wstETH before round trip", wstBefore);
        emit log_named_uint("wstETH after round trip", wstAfter);
        assertLe(wstAfter, wstBefore, "round trip must not be profitable");
    }

    /* ------------------------------------------------------------------ */
    /* 9. open-position path: collateral recorded exactly, position value   */
    /*    never exceeds the collateral (no free leverage)                   */
    /* ------------------------------------------------------------------ */
    function test_openPosition_noFreeValue() public {
        uint128 lastPrice = _lastPrice();
        _mockPyth(lastPrice);
        vm.deal(attacker, 5 ether);
        deal(WSTETH, attacker, 5 ether);

        vm.startPrank(attacker);
        IERC20(WSTETH).approve(PROXY, type(uint256).max);
        uint64 dep = IUsdnProtocol(PROXY).getSecurityDepositValue();
        uint256 wstBefore = IERC20(WSTETH).balanceOf(attacker);

        (, PositionId memory posId) = IUsdnProtocol(PROXY).initiateOpenPosition{ value: dep + 1 }(
            1 ether,
            uint128(uint256(lastPrice) * 90 / 100), // liq price 10% below current
            uint128(uint256(lastPrice) * 101 / 100), // 1% slippage cap
            25e21, // max leverage
            attacker,
            payable(attacker),
            block.timestamp + 1 days,
            _pythData(),
            _empty()
        );
        vm.warp(block.timestamp + 30);
        IUsdnProtocol(PROXY).validateOpenPosition{ value: 1 }(payable(attacker), _pythData(), _empty());
        vm.stopPrank();

        (Position memory pos,) = IUsdnProtocol(PROXY).getLongPosition(posId);
        int256 pv = IUsdnProtocol(PROXY).getPositionValue(posId, _lastPrice(), uint128(block.timestamp));
        emit log_named_uint("collateral recorded (wstETH)", pos.amount);
        emit log_named_int("position value at current price (wstETH)", pv);
        emit log_named_uint("attacker wstETH spent", wstBefore - IERC20(WSTETH).balanceOf(attacker));

        assertEq(pos.amount, 1 ether, "collateral recorded exactly");
        assertEq(wstBefore - IERC20(WSTETH).balanceOf(attacker), 1 ether, "spent exactly the collateral");
        assertLe(uint256(pv), uint256(pos.amount), "position value must not exceed collateral");
    }
}
