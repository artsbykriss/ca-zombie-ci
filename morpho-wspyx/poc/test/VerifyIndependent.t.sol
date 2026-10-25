// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IERC4626, IOracle, IPyth, IMorpho} from "../src/Interfaces.sol";

/// @title INDEPENDENT VERIFICATION of the Morpho wSPYx/AUSD "donation-inflation, E-U=$0" claim.
/// @notice This file is deliberately written from scratch (no code copied from
///         MorphoWspyxOracle.t.sol) to try to BREAK the parent's claim that no profitable
///         external-unprivileged path exists. It re-derives the oracle price from raw reads,
///         attacks the flash-buy-existing-shares variant, the deflation->liquidation variant,
///         the Pyth leg, and other inflatable reads of the vault, and re-derives the general
///         no-profit bound. Fork-only, read-only on mainnet.

interface IMorphoPythOracle is IOracle {
    function pyth() external view returns (address);
    function BASE_VAULT() external view returns (address);
    function BASE_VAULT_CONVERSION_SAMPLE() external view returns (uint256);
    function BASE_FEED_1() external view returns (bytes32);
    function BASE_FEED_2() external view returns (bytes32);
    function QUOTE_VAULT() external view returns (address);
    function QUOTE_FEED_1() external view returns (bytes32);
    function PRICE_FEED_MAX_AGE() external view returns (uint256);
    function SCALE_FACTOR() external view returns (uint256);
}

interface IPythExt is IPyth {
    function latestPriceInfoPublishTime(bytes32 id) external view returns (uint64);
    function getValidTimePeriod() external view returns (uint256);
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
}

interface IVaultExt is IERC4626 {
    function maxWithdraw(address owner) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
}

contract VerifyIndependent is Test {
    // ------------------------------------------------------------------ constants (Ethereum mainnet)
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WSPYX = 0xc88FcD8B874fDb3256E8B55b3decB8c24EAb4c02; // ERC-4626 wrapper
    address constant SPYX = 0x90A2a4c76b5D8c0bc892A69EA28Aa775a8f2dD48;  // vault asset
    address constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;  // loan token (6 dp)
    address constant ORACLE = 0x01Fd716a703eD6A54922b1F2C8cc2Ed5a018bAC5; // MorphoPythOracle
    address constant PYTH = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    bytes32 constant FEED_SPY = 0x2817b78438c769357182c04346fddaad1178c82f4048828fe0997c3c64624e14;
    uint256 constant LLTV = 0.86e18;
    bytes32 constant MID = 0xbf0432567b44ef5ce013ffcd7dd756c522252503f7986a406e780715b32c74fc;
    uint256 constant CONVERSION_SAMPLE = 1e6;

    // large SPYx holder (~3,842 SPYx) used to fund the attacker on the fork
    address constant WHALE = 0xf3C20F98Db6De1DBe023bBa94C9525620A0B37e8;

    // real free (non-Morpho) wSPYx holders, read live from Blockscout holders list
    address constant POOL_MGR = 0x000000000004444c5dc75cB358380D2e3dE08A90; // Uniswap V4 PoolManager
    address constant H1 = 0x6fe89E702bdA744D009B8F12995cAF8A0f068Aa3;
    address constant H2 = 0x57926b7C1A0E3B97d1E238F5C6e8C8964d443D8c;
    address constant H3 = 0xC6877a65349B0fA45cC61a267eE682c7AbF2B369;
    address constant ANGLE = 0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae;
    address constant H4 = 0x993122c48Dc1003C78de0e828231E7af5a62A42E;
    address constant H5 = 0x6AB536bC3D486cFb0B4b59F4054C1071009720Ef;
    address constant H6 = 0x2669512B00025A7C052E96877d3dda2002fa16e0;

    // the largest borrower (Morpho Blue API) and the lowest-HF borrower, for the deflation test
    address constant BIG_BORROWER = 0x2Eb5162Af8E14393AD9e277d2234152437F45577;
    address constant LOW_HF_BORROWER = 0x03951709bA7d2FAB9e5a587069f5a347555bbfB2;

    // ------------------------------------------------------------------ helpers
    function _rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
        // Safety: if the Pyth SPY feed is stale relative to the fork head, warp to its publishTime
        // so the oracle's `getPriceNoOlderThan(...,3600)` leg is fresh and deterministic.
        IPyth.Price memory p = IPyth(PYTH).getPriceUnsafe(FEED_SPY);
        if (block.timestamp >= uint256(p.publishTime) + 3600) {
            vm.warp(uint256(p.publishTime) + 1);
        }
    }

    function _fund(address to, uint256 amount) internal {
        vm.prank(WHALE);
        IERC20(SPYX).transfer(to, amount);
    }

    function _mp() internal view returns (IMorpho.MarketParams memory) {
        return IMorpho(MORPHO).idToMarketParams(MID);
    }

    function _pyth() internal view returns (uint256) {
        return uint256(uint64(IPyth(PYTH).getPriceUnsafe(FEED_SPY).price));
    }

    /// @dev AUSD (6 dp) value of a user's collateral at the current oracle price. price has 36 + 6 - 18 dp.
    function _collateralValueAUSD(address user) internal view returns (uint256) {
        IMorpho.Position memory p = IMorpho(MORPHO).position(MID, user);
        return uint256(p.collateral) * IOracle(ORACLE).price() / 1e36;
    }

    function _borrowAssetsAUSD(address user) internal view returns (uint256) {
        IMorpho.Market memory m = IMorpho(MORPHO).market(MID);
        IMorpho.Position memory p = IMorpho(MORPHO).position(MID, user);
        if (m.totalBorrowShares == 0) return 0;
        return uint256(p.borrowShares) * uint256(m.totalBorrowAssets) / uint256(m.totalBorrowShares);
    }

    function _freeLiquidity() internal view returns (uint256) {
        IMorpho.Market memory m = IMorpho(MORPHO).market(MID);
        return uint256(m.totalSupplyAssets) - uint256(m.totalBorrowAssets);
    }

    // ============================================================================================
    // 1. PRICE FORMULA RE-DERIVATION FROM RAW READS (independent of the parent's test)
    // ============================================================================================
    function test_1_priceFormulaReDerivedFromRawReads() public {
        IMorphoPythOracle o = IMorphoPythOracle(ORACLE);

        // --- independently re-derive SCALE_FACTOR from the constructor formula + live decimals ---
        // SCALE_FACTOR = 10**(36 + quoteDec + qFeed1Dec + qFeed2Dec - baseDec - bFeed1Dec - bFeed2Dec)
        //                * quoteVaultConversionSample / baseVaultConversionSample
        uint256 loanDec = IERC20(AUSD).decimals();          // 6
        uint256 collDec = IERC4626(WSPYX).decimals();       // 18
        int32 expo = IPyth(PYTH).getPriceUnsafe(FEED_SPY).expo;
        uint256 baseFeedDec = uint256(-int256(expo));        // 8
        uint256 quoteDec = loanDec;                          // quoteTokenDecimals == loan token decimals (6)
        uint256 qFeedDecs = 0;                               // QUOTE_FEED_1/2 == 0
        uint256 bFeed2Dec = 0;                               // BASE_FEED_2 == 0
        uint256 expectedScale =
            (10 ** (36 + quoteDec + qFeedDecs - collDec - baseFeedDec - bFeed2Dec)) * 1 / CONVERSION_SAMPLE;

        emit log_named_uint("loanDec(AUSD)", loanDec);
        emit log_named_uint("collDec(wSPYx)", collDec);
        emit log_named_uint("baseFeedDec(SPY)", baseFeedDec);
        emit log_named_uint("expected SCALE_FACTOR (re-derived)", expectedScale);
        emit log_named_uint("on-chain SCALE_FACTOR", o.SCALE_FACTOR());
        assertEq(o.SCALE_FACTOR(), expectedScale, "SCALE_FACTOR not reproduced from constructor formula");
        assertEq(o.SCALE_FACTOR(), 1e10, "unexpected SCALE_FACTOR");

        // --- confirm the "other" legs are neutral (so the formula reduces to SCALE*cv*Pyth) ---
        assertEq(o.QUOTE_VAULT(), address(0), "quote vault must be 0");
        assertEq(o.BASE_FEED_2(), bytes32(0), "base feed 2 must be 0");
        assertEq(o.QUOTE_FEED_1(), bytes32(0), "quote feed 1 must be 0");
        assertEq(o.BASE_VAULT(), WSPYX, "base vault must be wSPYx");
        assertEq(o.BASE_VAULT_CONVERSION_SAMPLE(), CONVERSION_SAMPLE, "conversion sample");
        assertEq(o.PRICE_FEED_MAX_AGE(), 3600, "max age");
        assertEq(o.pyth(), PYTH, "pyth address");

        // --- the exact quantity the oracle reads, straight from the vault ---
        uint256 cv = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 pyth = _pyth();
        uint256 expectedPrice = o.SCALE_FACTOR() * cv * pyth; // denom == 1
        uint256 actual = IOracle(ORACLE).price();

        emit log_named_uint("convertToAssets(1e6)", cv);
        emit log_named_uint("Pyth SPY (exp -8)", pyth);
        emit log_named_uint("expected price", expectedPrice);
        emit log_named_uint("oracle.price()", actual);
        assertEq(actual, expectedPrice, "price != SCALE_FACTOR * convertToAssets(1e6) * Pyth(SPY)");

        // --- the staleness path used by the oracle is live and returns the same value ---
        IPyth.Price memory pFresh = IPyth(PYTH).getPriceNoOlderThan(FEED_SPY, 3600);
        assertEq(uint256(uint64(pFresh.price)), pyth, "getPriceNoOlderThan != getPriceUnsafe");
    }

    // ============================================================================================
    // 2. FLASH-BUY-EXISTING-SHARES + DONATE VARIANT (the parent only tested mint-then-donate)
    // ============================================================================================
    function _buyExisting(address atk, uint256 want) internal returns (uint256 got) {
        address[4] memory sellers = [H1, H2, H3, POOL_MGR];
        for (uint256 i = 0; i < sellers.length && got < want; i++) {
            uint256 bal = IERC20(WSPYX).balanceOf(sellers[i]);
            uint256 take = bal;
            if (got + take > want) take = want - got;
            if (take == 0) continue;
            vm.prank(sellers[i]);
            IERC20(WSPYX).transfer(atk, take);
            got += take;
        }
    }

    function test_2_flashBuyExistingSharesDonateCannotRepay() public {
        IMorpho.MarketParams memory mp = _mp();
        IMorpho(MORPHO).accrueInterest(mp);

        uint256 A0 = IERC4626(WSPYX).totalAssets();
        uint256 S0 = IERC4626(WSPYX).totalSupply();
        uint256 free = _freeLiquidity();
        uint256 usd = _pyth();
        uint256 morphoColl = IERC20(WSPYX).balanceOf(MORPHO);
        uint256 freeFloat = S0 - morphoColl;

        address atk = address(0xA77AC);
        // buy 2 existing shares from real holders (no minting -> totalSupply unchanged)
        uint256 x = _buyExisting(atk, 2e18);
        uint256 costSpyx = IERC4626(WSPYX).convertToAssets(x); // fair value paid, pre-donation

        // flash-borrow D SPYx (simulated by a whale transfer) and donate it to the vault
        uint256 D = 100e18;
        _fund(atk, D);
        vm.prank(atk);
        IERC20(SPYX).transfer(WSPYX, D); // <-- donation inflates convertToAssets / oracle

        // supply the bought shares and borrow the maximum the market allows
        vm.startPrank(atk);
        IERC4626(WSPYX).approve(MORPHO, type(uint256).max);
        IMorpho(MORPHO).supplyCollateral(mp, x, atk, "");
        uint256 tryB = free;
        uint256 borrowed;
        while (tryB > 0) {
            try IMorpho(MORPHO).borrow(mp, tryB, 0, atk, atk) returns (uint256 a, uint256) {
                borrowed = a;
                break;
            } catch {
                tryB = tryB * 99 / 100;
            }
        }
        vm.stopPrank();

        int256 netUsd1e18 = int256(borrowed) * 1e12 - int256(costSpyx + D) * int256(usd) / 1e8;

        emit log_named_uint("bought existing shares x (1e18)", x);
        emit log_named_uint("fair cost of shares (SPYx 1e18)", costSpyx);
        emit log_named_uint("donation D (SPYx 1e18)", D);
        emit log_named_uint("borrowed AUSD (1e6)", borrowed);
        emit log_named_int("net USD (1e18)", netUsd1e18);
        emit log_named_uint("free float (non-Morpho shares)", freeFloat);
        emit log_named_uint("attacker fraction x/S0 (1e18)", x * 1e18 / S0);

        assertGt(x, 0, "must have bought shares");
        assertLt(netUsd1e18, 0, "flash-buy + donate path must be net-negative");
        assertLe(borrowed, free, "cannot borrow more than free liquidity");
        assertGt(borrowed, free * 99 / 100, "borrow should hit the free-liquidity cap");

        // The attacker cannot repay the flash loan by redeeming the bought shares:
        // redeemable = x*(A0+D+1)/(S0+1), which is < D whenever x < S0 (always).
        uint256 redeemable = IERC4626(WSPYX).convertToAssets(x);
        emit log_named_uint("redeemable SPYx after donation", redeemable);
        assertLt(redeemable, D, "redeeming bought shares returns LESS than the flash-borrowed donation");

        // share-fraction bound: without minting, attacker can hold at most the free float
        assertLt(freeFloat * 1e18 / S0, 1e18, "free fraction must be < 100%");
        assertLt(freeFloat * 1e18 / S0, uint256(1e18) * 1e18 / LLTV, "free fraction must be < 1/LLTV");
    }

    // ============================================================================================
    // 3. DEFLATION -> LIQUIDATION VARIANT (can an attacker push the borrower HF below 1?)
    // ============================================================================================
    function test_3_deflationCannotLiquidateBorrower() public {
        uint256 price0 = IOracle(ORACLE).price();
        uint256 cv0 = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 A0 = IERC4626(WSPYX).totalAssets();
        uint256 S0 = IERC4626(WSPYX).totalSupply();

        uint256 bigHF0 = _collateralValueAUSD(BIG_BORROWER) * 1e18 / _borrowAssetsAUSD(BIG_BORROWER);
        uint256 lowHF0 = _collateralValueAUSD(LOW_HF_BORROWER) * 1e18 / _borrowAssetsAUSD(LOW_HF_BORROWER);

        // Maximum deflation an external actor can cause: every free holder exits the vault.
        address[8] memory holders = [POOL_MGR, H1, H2, H3, ANGLE, H4, H5, H6];
        uint256 redeemed;
        for (uint256 i = 0; i < holders.length; i++) {
            uint256 bal = IERC20(WSPYX).balanceOf(holders[i]);
            if (bal == 0) continue;
            vm.prank(holders[i]);
            redeemed += IERC4626(WSPYX).redeem(bal, holders[i], holders[i]);
        }

        uint256 price1 = IOracle(ORACLE).price();
        uint256 cv1 = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 A1 = IERC4626(WSPYX).totalAssets();
        uint256 S1 = IERC4626(WSPYX).totalSupply();
        uint256 bigHF1 = _collateralValueAUSD(BIG_BORROWER) * 1e18 / _borrowAssetsAUSD(BIG_BORROWER);
        uint256 lowHF1 = _collateralValueAUSD(LOW_HF_BORROWER) * 1e18 / _borrowAssetsAUSD(LOW_HF_BORROWER);

        emit log_named_uint("SPYx redeemed by free holders", redeemed);
        emit log_named_uint("totalAssets before/after", A0);
        emit log_named_uint("totalAssets after", A1);
        emit log_named_uint("convertToAssets(1e6) before", cv0);
        emit log_named_uint("convertToAssets(1e6) after", cv1);
        emit log_named_uint("oracle price before", price0);
        emit log_named_uint("oracle price after", price1);
        emit log_named_uint("BIG borrower HF before (1e18)", bigHF0);
        emit log_named_uint("BIG borrower HF after  (1e18)", bigHF1);
        emit log_named_uint("LOW-HF borrower HF before (1e18)", lowHF0);
        emit log_named_uint("LOW-HF borrower HF after  (1e18)", lowHF1);

        assertGt(redeemed, 0, "should have redeemed free shares");
        // Fair-value redemption is NAV-neutral (rounding slightly favours remaining holders),
        // so the oracle price cannot be pushed DOWN this way.
        assertGe(price1 + 1e15, price0, "redeeming free shares must not deflate the oracle");
        assertApproxEqRel(price1, price0, 1e14, "oracle price ~unchanged by redemption");
        // health factors stay far above 1
        assertGt(bigHF1, 1e18, "big borrower must stay solvent");
        assertGt(lowHF1, 1e18, "low-HF borrower must stay solvent");
        assertGt(bigHF1, 100e18, "big borrower HF stays > 100x");
    }

    // ============================================================================================
    // 4. PYTH MANIPULATION FEASIBILITY (staleness + non-monotonic / forged updates)
    // ============================================================================================
    function test_4_pythManipulationInfeasible() public {
        IPyth.Price memory p = IPyth(PYTH).getPriceUnsafe(FEED_SPY);
        uint64 storedPt = IPythExt(PYTH).latestPriceInfoPublishTime(FEED_SPY);
        emit log_named_uint("block.timestamp", block.timestamp);
        emit log_named_uint("pyth publishTime", p.publishTime);
        emit log_named_uint("pyth age (s)", block.timestamp - uint256(p.publishTime));
        emit log_named_uint("getValidTimePeriod (deprecated)", IPythExt(PYTH).getValidTimePeriod());

        // oracle's own staleness window is 3600, and the feed is inside it at fork time
        assertLe(block.timestamp - uint256(p.publishTime), 3600, "feed stale vs oracle max age");
        // stored price IS the unsafe price
        assertEq(uint256(storedPt), uint256(p.publishTime), "stored publishTime mismatch");

        // a signed update cannot regress the stored price: PythSetters.updateLatestPriceIfNecessary
        // only writes when info.publishTime > stored publishTime. We cannot craft a signed VAA here,
        // but we CAN show the update entrypoint rejects arbitrary payloads (forgery requires the
        // Pyth accumulator + Wormhole Merkle proof, which needs publisher signatures).
        bytes[] memory bogus = new bytes[](1);
        bogus[0] = hex"0102030405060708090a";
        vm.expectRevert();
        IPythExt(PYTH).updatePriceFeeds(bogus);

        // the oracle would revert (StalePrice) if fed an age below the true age -> the guard is active
        uint256 age = block.timestamp - uint256(p.publishTime);
        if (age >= 1) {
            vm.expectRevert();
            IPyth(PYTH).getPriceNoOlderThan(FEED_SPY, age - 1);
        }
    }

    // ============================================================================================
    // 5. OTHER INFLATABLE READS OF THE VAULT (rounding / maxWithdraw / totalAssets source)
    // ============================================================================================
    function test_5_otherInflatableReadsAreValueNeutral() public {
        // totalAssets() is literally the asset balance -> donation-inflatable (confirms mechanism)
        assertEq(IERC4626(WSPYX).totalAssets(), IERC20(SPYX).balanceOf(WSPYX), "totalAssets != asset.balanceOf");

        uint256 cvBefore = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 csBefore = IERC4626(WSPYX).convertToShares(CONVERSION_SAMPLE);

        // donate to inflate
        address atk = address(0xD0A0);
        uint256 D = 100e18;
        _fund(atk, D);
        vm.prank(atk);
        IERC20(SPYX).transfer(WSPYX, D);

        uint256 cvAfter = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 csAfter = IERC4626(WSPYX).convertToShares(CONVERSION_SAMPLE);
        emit log_named_uint("convertToAssets(1e6) before/after", cvBefore);
        emit log_named_uint("convertToAssets(1e6) after", cvAfter);
        emit log_named_uint("convertToShares(1e6) before", csBefore);
        emit log_named_uint("convertToShares(1e6) after", csAfter);

        // inflation raises convertToAssets (oracle input) but LOWERS convertToShares (depositors get
        // fewer shares) -> the asymmetry is value-destructive for the attacker, not extractive.
        assertGt(cvAfter, cvBefore, "donation must inflate convertToAssets");
        assertLt(csAfter, csBefore, "donation must shrink convertToShares (hurts depositors)");

        // maxWithdraw(attacker) after donating is still fair value of *their* shares only; the
        // attacker cannot withdraw the donation back (it belongs to all holders pro-rata).
        uint256 atkShares = IERC4626(WSPYX).balanceOf(atk); // 0: pure donation mints nothing
        assertEq(atkShares, 0, "donation must not mint shares");
        assertEq(IVaultExt(WSPYX).maxWithdraw(atk), 0, "donor cannot withdraw the donation");
    }

    // ============================================================================================
    // 6. INDEPENDENT GENERAL NO-PROFIT BOUND (analytic sweep, no fork state needed beyond reads)
    // ============================================================================================
    /// @dev net (USD 1e18) for an attacker who holds fraction f of post-state shares and donates D,
    ///      borrowing at most min(free, LLTV * collateral value).
    function _netBound(
        uint256 fWad,
        uint256 D,
        uint256 A0,
        uint256 S0,
        uint256 usd,
        uint256 free
    ) internal pure returns (int256) {
        uint256 x = fWad * S0 / 1e18;                 // shares held
        uint256 valSpyx = x * (A0 + D + 1) / (S0 + 1); // oracle-valued collateral (SPYx wei)
        uint256 valUsd6 = valSpyx * usd / 1e20;        // AUSD 6dp  (valSpyx/1e18 * usd/1e8 * 1e6)
        uint256 borrow = valUsd6 * LLTV / 1e18;
        if (borrow > free) borrow = free;
        uint256 costSpyx = x * (A0 + 1) / (S0 + 1) + D; // fair share cost + donation
        return int256(borrow) * 1e12 - int256(costSpyx) * int256(usd) / 1e8;
    }

    function test_6_generalNoProfitBound() public {
        uint256 A0 = IERC4626(WSPYX).totalAssets();
        uint256 S0 = IERC4626(WSPYX).totalSupply();
        uint256 usd = _pyth();
        uint256 free = _freeLiquidity();

        uint256[7] memory fs = [uint256(1e15), 1e16, 3e16, 5e16, 1e17, 5e17, 1e18];
        uint256[5] memory ds = [uint256(0), 1e18, 10e18, 100e18, 668e18];
        int256 best = type(int256).min;
        for (uint256 i = 0; i < fs.length; i++) {
            for (uint256 j = 0; j < ds.length; j++) {
                int256 net = _netBound(fs[i], ds[j], A0, S0, usd, free);
                if (net > best) best = net;
                emit log_named_uint("f (1e18)", fs[i]);
                emit log_named_uint("D (1e18)", ds[j]);
                emit log_named_int("net USD (1e18)", net);
            }
        }
        emit log_named_int("BEST (max) net USD (1e18)", best);

        // The donation term is D*(LLTV*f - 1) <= 0 for every f <= 1 (LLTV=0.86<1), and the
        // capital term is -(1-LLTV)*f*A0 <= 0. Hence net < 0 for every attack with any capital
        // or any donation: no profitable external-unprivileged path. E-U = $0.
        assertLt(best, 0, "general bound: every attack is net-negative");

        // The theoretically least-negative attack is the no-donation, minimal-collateral one
        // (borrow capped by collateral): its loss approaches 0 but is never positive.
        int256 noDon = _netBound(1e15, 0, A0, S0, usd, free);
        assertLt(noDon, 0, "even the least-negative attack loses money");
    }
}
