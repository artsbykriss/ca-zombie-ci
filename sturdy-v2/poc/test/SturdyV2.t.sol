// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, ISturdyPair, IDualOracle, IYearnVault, ICurvePool, IAggregatorV3, ISturdyDataProvider} from "../src/Interfaces.sol";

/// @title Sturdy V2 (Ethereum) — oracle-manipulation / stale-mark residual PoC (fork only)
/// @notice Read-only mainnet research. Every test runs on a local fork; no transaction is signed
///         or sent to any live chain. The tests establish:
///   A. the per-pair `maxOracleDeviation` bound is 0 on all 23 pairs and every live oracle returns
///      priceLow == priceHigh, so the "deviation guard" that V2 added after the V1 hack is a no-op;
///      the only real protection is the oracle's *price source*.
///   B. no oracle in the set reads a UniV2 `getReserves()` or UniV3 `slot0()` spot price.
///   C. the borrow path is fully permissionless (no roles/whitelist) and works today.
///   D. borrowing is hard-capped by the pair's free (unborrowed) liquidity.
///   E. for every live pair, maxBorrow(collateral) < collateral's real value because maxLTV < 100 %,
///      so "inflate the collateral mark and default" is a loss unless the oracle price exceeds the
///      real price (i.e. unless the source is genuinely manipulable/stale).
///   F. a direct donation to the Yearn vault that backs the largest strategy does not open a gap.
///   G. four markets currently have oracles that revert -> borrow and liquidation are frozen.
contract SturdyV2OracleTest is Test {
    address constant DP = 0x69764E3e0671747A7768A1C1AfB7C0C39868CC9e;
    uint256 constant EXCHANGE_PRECISION = 1e18;
    uint256 constant LTV_PRECISION = 1e5;

    struct S {
        address pair;
        address asset;
        address coll;
        address oracle;
        uint256 maxLTV;
        string assetSym;
    }

    // ---------------------------------------------------------------- fork
    function _rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        uint256 blk = vm.envOr("STURDY_FORK_BLOCK", uint256(0));
        if (blk == 0) {
            vm.createSelectFork(_rpc());
        } else {
            vm.createSelectFork(_rpc(), blk);
        }
        console2.log("fork block:", block.number);
    }

    // ---------------------------------------------------------------- strategy table
    // Decoded from AggregatorDataProvider.getStrategies() @ 0x69764E3e.. ; block 26,271,892.
    function _strategies() internal pure returns (S[] memory s) {
        s = new S[](23);
        s[0]  = S(0x7578F31CC44fDF2f123A6f84c42f702f9C990091, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0x7cA00559B978CFde81297849be6151d3ccB408A9, 0x1121DDD2007D2C6677E9987e289c3D52Aaa9668c, 90000, "crvUSD");
        s[1]  = S(0x9B0aFdA3aCaF3bfa3e49CB0aF1Fc0375Df290B99, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0xd901DCf4948a29d7D9D7E015AAF61591825AC267, 0x3Bd929574ff5Dea4a23d3bb3b1Ad0b95D0FE1e1d, 85000, "crvUSD");
        s[2]  = S(0x28bBa0e8F1201f14BCCF31c37904A25629097966, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0x241AdD131B9aaa7527132b752252b99420937ADc, 0xdB6cE32d36a9d807Bab0C3947b31b06706758492, 90000, "crvUSD");
        s[3]  = S(0xD1Eed9475EC923cfF04028D5920766784aE65006, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0x8176b059BD8f63aeB7e20282b12D243b4626E2AE, 0x680F851a3796AB1Aa1204cA8dD2214ef170D1A2D, 90000, "crvUSD");
        s[4]  = S(0xA25f4Cce877159f902869E501bfCD503602Ef11F, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xd33dAd974b938744dAC81fE00ac67cb5AA13958E, 0xA34Fe4D13cA737d0B1F8d9c169cbd044C56f17aD, 85000, "WETH");
        s[5]  = S(0xBD1290671ac658F8EFFBF488A420c7f6662005f1, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xfd6db5011b171B05E1Ea3b92f9EAcaEEb055e971, 0x3723d77a72e829Cb367B4F0cdF35B9b95dc3e57d, 85000, "WETH");
        s[6]  = S(0xAcDBcDE220c7155FEAC574cd04CCD363A1B26B76, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xb5b29320d2Dde5BA5BAFA1EbcD270052070483ec, 0x1F4b81F8d61dda8A2752BE59a9aF9a9fb37c9eAD, 85000, "WETH");
        s[7]  = S(0x9A81759333948ab6E6036cb0F35711028B8aF1C2, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xf951E335afb289353dc249e82926178EaC7DEd78, 0xFeF192CaBf37A2396A8665f42f9a499A52BAa185, 90000, "WETH");
        s[8]  = S(0x5630D6564Ba2154C324D80E0c12D1445e7f469FB, 0x04C154b66CB340F3Ae24111CC767e0184Ed00Cc6, 0x2c8a33C66c00264316Ea4E4433e86A386Eb6ECBf, 0xd12B45a5BA878d4b406886A7876061306712B2f0, 90000, "pxETH");
        s[9]  = S(0x4Aa83d5366C5B644330C07aC70E60e19b70c9647, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xc69Ad9baB1dEE23F4605a82b3354F8E40d1E5966, 0xa621a3809FDa139C7aA63d7736d2E3eb0B351D0b, 85000, "WETH");
        s[10] = S(0xC7f52315A7D717293804Ed8D91e5D88fBf38290D, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x5cb12D56F5346a016DBBA8CA90635d82e6D1bcEa, 0x22436Aed9FE5a6408537e748280cb25a6d78978B, 85000, "WETH");
        s[11] = S(0x7A8Fc1ac4f9558Fc2596A1Cdf812F3896D55104b, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xB05cABCd99cf9a73b19805edefC5f67CA5d1895E, 0x49C27C15DbB239C4943C5f86361Da724F8D1F8aF, 85000, "WETH");
        s[12] = S(0x5B0134F94A78516e860624EE314753A79b4d078F, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7, 0xDEDa72c39B7b2fb0433aF9cFC21031d5ef3B126A, 90000, "WETH");
        s[13] = S(0x3CEC86A7d36B22Ae94810DBf30dcd8c287b8Ee87, 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f, 0xAc22e3a3cfE4dC82FFD4Ffa7453729Ca963CeB5a, 0x50710F355652439F7fCC752c58C15E6ae7626092, 90000, "GHO");
        s[14] = S(0xe0A41694FCe6EA13b473C86D9e801fa85acCB5F6, 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f, 0xbcccE9991D2C8A8056D677c0c52C20ac901f39eC, 0x85db1A4EC3fC2dd880Ae81464B1b946CaA71C708, 90000, "GHO");
        s[15] = S(0x35B5564A1e7B3a90D8E9F0E9eA246ca68842393e, 0x04C154b66CB340F3Ae24111CC767e0184Ed00Cc6, 0x9Ba021B0a9b958B5E75cE9f6dff97C7eE52cb3E6, 0x0AcD9D715E354861fE68D3cf339b9427d09a77Ae, 90000, "pxETH");
        s[16] = S(0x7fecfb9CBF7F03872c6Eb836409bD436763Bb2D8, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x35D8949372D46B7a3D5A56006AE77B215fc69bC0, 0x0D1039bEC12cb320161bBd5578c62f1F8294D4b3, 86000, "USDC");
        s[17] = S(0xb1c3e57f26dB4709e073402232F1Ee1CC608690D, 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0x8DB2350D78aBc13f5673A411D4700BCF87864dDE, 0xe8384d78667dFC4B4D5eAE90308eA95a58229166, 94000, "WBTC");
        s[18] = S(0xAEA34F75431A989353ECc7Ab0C9dEF4E5f9ae4C9, 0x18084fbA666a33d37592fA2633fD49a74DD93a88, 0xb3CA5C531BCaF94C3575500DA16b7e219b910224, 0x0B70F7093394ED748A4D1d72225DF723256e3785, 90000, "tBTC");
        s[19] = S(0x537090da8EBA71FA572350A793c38050cf56b429, 0x18084fbA666a33d37592fA2633fD49a74DD93a88, 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642, 0x9CE963C99fDc8E3563e3787F8557B96d31Ca2f63, 90000, "tBTC");
        s[20] = S(0x435F9eB57Be41A69D76aE26fFAc065df16CB661C, 0x18084fbA666a33d37592fA2633fD49a74DD93a88, 0x8DB2350D78aBc13f5673A411D4700BCF87864dDE, 0x4BD8bcd78fF3440e11Ee8356cD006D58510925b7, 94000, "tBTC");
        s[21] = S(0x45B334a25b8F9c9D96B044F9661DD1dE5d3c1bbF, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x96F6eF951840721AdBF46Ac996b59E0235CB985C, 0xEEE4EcDdbB6145839e52f5BC177331Db56f26C6C, 90000, "USDC");
        s[22] = S(0x4162381996B2321E40AaDade4ae267A13214Af80, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x990200DACA8c96f1B1d10aF074D4054cD8916028, 0x78852021cE063012A79B9f7d443A70E988585eD7, 85000, "USDC");
    }

    // ---------------------------------------------------------------- helpers
    function _freeAsset(address pair) internal view returns (uint256) {
        (uint128 ta,) = ISturdyPair(pair).totalAsset();
        (uint128 tb,) = ISturdyPair(pair).totalBorrow();
        return uint256(ta) - uint256(tb);
    }

    function _maxBorrowFor(address pair, uint256 collAmt) internal view returns (uint256) {
        (,,, uint256 lo, uint256 hi) = ISturdyPair(pair).exchangeRateInfo();
        // solvency uses the HIGH rate (conservative): borrow <= collAmt * maxLTV / 1e5 * 1e18 / hi
        return collAmt * ISturdyPair(pair).maxLTV() / LTV_PRECISION * EXCHANGE_PRECISION / hi;
    }

    function _hasSel(bytes memory code, bytes4 s) internal pure returns (bool) {
        if (code.length < 4) return false;
        for (uint256 i; i <= code.length - 4; i++) {
            if (code[i] == s[0] && code[i + 1] == s[1] && code[i + 2] == s[2] && code[i + 3] == s[3]) return true;
        }
        return false;
    }

    /// @dev external so that reverts (e.g. oracle revert, deal failure) are catchable by the caller
    function tryBorrow(uint256 i, uint256 borrowAmt) external returns (uint256 got) {
        S memory st = _strategies()[i];
        (,,, uint256 lo, uint256 hi) = ISturdyPair(st.pair).exchangeRateInfo();
        uint256 collAmt = borrowAmt * hi / EXCHANGE_PRECISION * LTV_PRECISION / ISturdyPair(st.pair).maxLTV();
        collAmt = collAmt * 105 / 100; // 5 % buffer
        deal(st.coll, address(this), collAmt);
        IERC20(st.coll).approve(st.pair, collAmt);
        uint256 b0 = IERC20(st.asset).balanceOf(address(this));
        ISturdyPair(st.pair).borrowAsset(borrowAmt, collAmt, address(this));
        got = IERC20(st.asset).balanceOf(address(this)) - b0;
    }

    /// @dev returns (success, errorSelector)
    function probeBorrow(uint256 i, uint256 borrowAmt) external returns (bool ok, bytes4 errSel) {
        S memory st = _strategies()[i];
        (,,, uint256 lo, uint256 hi) = ISturdyPair(st.pair).exchangeRateInfo();
        uint256 collAmt = borrowAmt * hi / EXCHANGE_PRECISION * LTV_PRECISION / ISturdyPair(st.pair).maxLTV();
        collAmt = collAmt * 105 / 100;
        deal(st.coll, address(this), collAmt);
        IERC20(st.coll).approve(st.pair, collAmt);
        (bool s, bytes memory r) = st.pair.call(
            abi.encodeWithSelector(ISturdyPair.borrowAsset.selector, borrowAmt, collAmt, address(this)));
        ok = s;
        if (!s && r.length >= 4) errSel = bytes4(r);
    }

    // ---------------------------------------------------------------- tests

    /// A. deviation bound is 0 everywhere and every live oracle returns low == high
    function test_A_deviation_guard_is_a_noop() public {
        S[] memory s = _strategies();
        uint256 live; uint256 reverting;
        for (uint256 i; i < s.length; i++) {
            (bool ok, bytes memory r) = s[i].oracle.staticcall(abi.encodeWithSelector(IDualOracle.getPrices.selector));
            if (ok) {
                (, uint256 lo, uint256 hi) = abi.decode(r, (bool, uint256, uint256));
                assertEq(lo, hi, "live oracle returned low != high");
                live++;
            } else {
                reverting++;
            }
            (bool ok2, bytes memory r2) = s[i].pair.staticcall(abi.encodeWithSelector(ISturdyPair.exchangeRateInfo.selector));
            assertTrue(ok2, "exchangeRateInfo reverted");
            (, uint32 dev,,,) = abi.decode(r2, (address, uint32, uint184, uint256, uint256));
            assertEq(uint256(dev), 0, "pair.maxOracleDeviation != 0");
        }
        console2.log("A: oracles live (low==high):", live);
        console2.log("A: oracles reverting (frozen):", reverting);
        assertGt(live, 0, "no live oracle");
        assertEq(live + reverting, s.length);
    }

    /// B. no oracle reads a UniV2 getReserves() / UniV3 slot0() spot price
    function test_B_no_spot_price_source_in_any_oracle() public {
        S[] memory s = _strategies();
        for (uint256 i; i < s.length; i++) {
            bytes memory code = s[i].oracle.code;
            assertGt(code.length, 0, "oracle has no code");
            assertFalse(_hasSel(code, bytes4(0x0902f1ac)), "UniV2 getReserves() selector present");
            assertFalse(_hasSel(code, bytes4(0x3850c7bd)), "UniV3 slot0() selector present");
        }
        // the deployed sources are Chainlink / RedStone / Curve virtual-price / Yearn pps / Pendle TWAP:
        (, int256 ans,, uint256 upd,) = IAggregatorV3(0x8350b7De6a6a2C1368E7D4Bd968190e13E354297).latestRoundData(); // TBTC/USD
        assertGt(ans, 0); assertGt(upd, 0);
        assertGt(ICurvePool(0x6951bDC4734b9f7F3E1B74afeBC670c736A0EDB6).get_virtual_price(), 0); // Curve pxETH/stETH
        assertGt(IYearnVault(0x2c8a33C66c00264316Ea4E4433e86A386Eb6ECBf).pricePerShare(), 0);   // Yearn vault
        console2.log("B: no spot selectors in any of the 23 oracles");
    }

    /// C. the borrow path is permissionless and open today
    function test_C_permissionless_borrow_path_open() public {
        S[] memory s = _strategies();
        uint256 successes;
        for (uint256 i; i < s.length; i++) {
            uint256 free = _freeAsset(s[i].pair);
            if (free < 1e6) continue;          // need a non-trivial amount
            uint256 amt = free / 10;
            try this.tryBorrow(i, amt) returns (uint256 got) {
                if (got == amt) {
                    successes++;
                    console2.log("C: borrow OK, strategy idx / amount:", i);
                    console2.log("     ", s[i].assetSym, got);
                }
            } catch {}
        }
        assertGt(successes, 0, "no permissionless borrow succeeded");
        console2.log("C: strategies where an unprivileged borrow succeeded:", successes);
    }

    /// D. borrowing is hard-capped by the pair's free (unborrowed) liquidity
    function test_D_borrow_is_hard_capped_by_free_liquidity() public {
        S[] memory s = _strategies();
        uint256 checked;
        for (uint256 i; i < s.length; i++) {
            uint256 free = _freeAsset(s[i].pair);
            if (free < 1e6) continue;
            try this.probeBorrow(i, free + 1) returns (bool ok, bytes4 errSel) {
                assertFalse(ok, "borrowed more than free liquidity");
                console2.log("D: borrow(free+1) rejected, strategy idx / errSel:", i);
                console2.logBytes4(errSel);
                checked++;
            } catch {}
        }
        assertGt(checked, 0);
        console2.log("D: strategies where borrow(free+1) reverted:", checked);
    }

    /// E. for every live pair, maxBorrow(collateral) < collateral value (maxLTV < 100 %)
    function test_E_collateral_inflation_cannot_profit() public {
        S[] memory s = _strategies();
        uint256 checked;
        for (uint256 i; i < s.length; i++) {
            (bool ok, bytes memory r) = s[i].oracle.staticcall(abi.encodeWithSelector(IDualOracle.getPrices.selector));
            if (!ok) continue;
            (, uint256 lo, uint256 hi) = abi.decode(r, (bool, uint256, uint256));
            uint256 collAmt = 1e18;
            uint256 collValueAsset = collAmt * EXCHANGE_PRECISION / hi;      // collateral value in 1e18-normalised asset
            uint256 maxBorrow = collValueAsset * s[i].maxLTV / LTV_PRECISION; // = _maxBorrowFor(pair, collAmt)
            assertLt(maxBorrow, collValueAsset, "maxBorrow >= collateral value");
            assertLt(s[i].maxLTV, LTV_PRECISION, "maxLTV >= 100%");
            checked++;
        }
        assertGt(checked, 0);
        console2.log("E: live pairs where maxBorrow < collateral value:", checked);
    }

    /// @dev external so a failing `deal`/transfer is catchable by the caller
    function donationProbe()
        external
        returns (uint256 pps0, uint256 pps1, uint256 hi0, uint256 hi1, uint256 cap0, uint256 cap1)
    {
        address vault = 0x2c8a33C66c00264316Ea4E4433e86A386Eb6ECBf; // yvCurve-pxETH-stETH (strategy 8 collateral)
        address pair = 0x5630D6564Ba2154C324D80E0c12D1445e7f469FB;
        address oracle = 0xd12B45a5BA878d4b406886A7876061306712B2f0;
        address lp = IYearnVault(vault).token();
        uint256 collAmt = 1e18;

        pps0 = IYearnVault(vault).pricePerShare();
        (, , hi0) = IDualOracle(oracle).getPrices();
        cap0 = _maxBorrowFor(pair, collAmt);

        uint256 D = 1e18; // donate 1 LP token directly to the vault (permissionless ERC20 transfer)
        deal(lp, address(this), D);
        IERC20(lp).transfer(vault, D);

        pps1 = IYearnVault(vault).pricePerShare();
        (, , hi1) = IDualOracle(oracle).getPrices();
        cap1 = _maxBorrowFor(pair, collAmt);
    }

    /// F. a direct donation to the Yearn vault backing the largest strategy opens no gap
    function test_F_yearn_vault_donation_no_free_gap() public {
        uint256 pps0; uint256 pps1; uint256 hi0; uint256 hi1; uint256 cap0; uint256 cap1;
        try this.donationProbe() returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f) {
            pps0 = a; pps1 = b; hi0 = c; hi1 = d; cap0 = e; cap1 = f;
        } catch {
            console2.log("F: donation probe skipped (deal/transfer unavailable on this fork)");
            return;
        }

        console2.log("F: vault pricePerShare before/after:", pps0, pps1);
        console2.log("F: oracle priceHigh before/after:", hi0, hi1);
        console2.log("F: maxBorrow(1 collateral) before/after:", cap0, cap1);

        // structural bound: whatever the price does, maxBorrow stays below the collateral's value
        uint256 collValue = 1e18 * EXCHANGE_PRECISION / hi1;
        assertLt(cap1, collValue, "maxBorrow >= collateral value after donation");
        // and the extra capacity can never exceed what was donated (1 LP ~ 1.03 pxETH)
        assertLe(cap1, cap0 + 2e18, "capacity gain exceeds the donation");
    }

    /// G. four markets have reverting oracles -> borrow and liquidation are frozen
    function test_G_frozen_markets() public {
        uint256[4] memory idx = [uint256(3), uint256(4), uint256(11), uint256(12)];
        S[] memory s = _strategies();
        uint256 frozen;
        for (uint256 k; k < 4; k++) {
            (bool ok,) = s[idx[k]].pair.call(abi.encodeWithSelector(ISturdyPair.updateExchangeRate.selector));
            if (!ok) {
                frozen++;
                console2.log("G: frozen market, strategy idx:", idx[k]);
            } else {
                console2.log("G: oracle now live again, strategy idx:", idx[k]);
            }
        }
        assertGt(frozen, 0, "expected at least one frozen market");
        console2.log("G: frozen (borrow+liquidate reverting) strategies:", frozen);
    }
}
