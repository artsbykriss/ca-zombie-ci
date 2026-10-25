// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import {
    IERC20,
    IERC4626,
    IAggregatorV3,
    IMorphoChainlinkOracleV2,
    IParallelizer,
    Facet
} from "../src/Interfaces.sol";

/// @title Parallel Protocol V3 (Diamond / EIP-2535, Angle-Transmuter fork) — oracle + collateral-accounting PoC
/// @notice READ-ONLY against mainnet; everything runs on a local fork. No tx is signed or sent to a live chain.
contract ParallelV3Test is Test {
    // --- mainnet addresses (Ethereum, chainid 1) ---
    address constant DIAMOND = 0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2;
    address constant TOKEN_P = 0x9B3a8f7CEC208e247d97dEE13313690977e24459; // USDp
    address constant FRXUSD = 0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29;
    address constant SFRXUSD = 0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6;
    address constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

    address constant FRXUSD_FEED = 0x9B4a96210bc8D9D55b1908B465D8B0de68B7fF83;
    address constant USDE_FEED = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961;
    address constant SUSDE_FEED = 0xFF3BC18cCBd5999CE63E788A1c250a88626aD099;
    address constant SFRXUSD_MORPHO_ORACLE = 0x0Cb7dEE76aA916a3666f50b044f16051C325b3e2;

    uint256 constant FORK_BLOCK = 26271789;
    uint256 constant STALE_PERIOD = 90000; // 25h, as configured in the transmuter oracleConfig
    address constant ATTACKER = address(0xBEEF);

    IParallelizer par;

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(url, FORK_BLOCK);
        par = IParallelizer(DIAMOND);
    }

    /*//////////////////////////////////////////////////////////////
        A. DIAMOND RESOLUTION
    //////////////////////////////////////////////////////////////*/

    function test_A_diamond_facets_resolve() public {
        address[] memory facets = par.facetAddresses();
        assertEq(facets.length, 9, "9 facets");
        uint256 total;
        for (uint256 i; i < facets.length; i++) {
            bytes4[] memory sels = par.facetFunctionSelectors(facets[i]);
            total += sels.length;
            for (uint256 j; j < sels.length; j++) {
                assertEq(par.facetAddress(sels[j]), facets[i], "selector routes to facet");
            }
        }
        assertEq(total, 74, "74 selectors total");
        emit log_named_uint("total selectors", total);

        address[] memory cols = par.getCollateralList();
        assertEq(cols.length, 4, "4 collaterals");
        assertEq(cols[0], FRXUSD);
        assertEq(cols[1], SFRXUSD);
        assertEq(cols[2], USDE);
        assertEq(cols[3], SUSDE);
        assertEq(par.tokenP(), TOKEN_P, "USDp");
    }

    /*//////////////////////////////////////////////////////////////
        B. ORACLE TYPE + FRESHNESS
    //////////////////////////////////////////////////////////////*/

    function test_B_oracle_types_and_freshness() public {
        // USDe + frxUSD: CHAINLINK_FEEDS(0) + STABLE(3)
        (uint8 ot, uint8 tt,,,) = par.getOracle(USDE);
        assertEq(ot, 0, "USDe oracle = CHAINLINK_FEEDS");
        assertEq(tt, 3, "USDe target = STABLE");
        (ot, tt,,,) = par.getOracle(FRXUSD);
        assertEq(ot, 0);
        assertEq(tt, 3);

        // sUSDe: CHAINLINK_FEEDS + MAX(8)
        (ot, tt,,,) = par.getOracle(SUSDE);
        assertEq(ot, 0, "sUSDe oracle = CHAINLINK_FEEDS");
        assertEq(tt, 8, "sUSDe target = MAX");

        // sfrxUSD: MORPHO_ORACLE(9) + MAX(8)
        (ot, tt,,,) = par.getOracle(SFRXUSD);
        assertEq(ot, 9, "sfrxUSD oracle = MORPHO_ORACLE");
        assertEq(tt, 8, "sfrxUSD target = MAX");

        // all Chainlink feeds fresh (< stalePeriod) and positive
        _assertFresh(USDE_FEED);
        _assertFresh(FRXUSD_FEED);
        _assertFresh(SUSDE_FEED);

        // sfrxUSD morpho oracle = MorphoChainlinkOracleV2(BASE_VAULT=sfrxUSD, BASE_FEED_1=frxUSD/USD)
        IMorphoChainlinkOracleV2 mo = IMorphoChainlinkOracleV2(SFRXUSD_MORPHO_ORACLE);
        assertEq(mo.BASE_VAULT(), SFRXUSD);
        assertEq(mo.BASE_FEED_1(), FRXUSD_FEED);
        assertEq(mo.QUOTE_VAULT(), address(0));
        assertEq(mo.QUOTE_FEED_1(), address(0));
        assertEq(mo.SCALE_FACTOR(), 1);
    }

    /*//////////////////////////////////////////////////////////////
        C. MINT PRICE IS CAPPED BY THE TARGET (never above the oracle)
    //////////////////////////////////////////////////////////////*/

    function test_C_mint_price_capped_by_target() public {
        // USDe / frxUSD : targetType = STABLE -> targetPrice = $1 ; mint = min(oracle, $1) <= $1.
        //                 (the 0.05% deviation band snaps the mark to $1.00 while the oracle is near $1)
        _assertMintCappedStable(USDE);
        _assertMintCappedStable(FRXUSD);

        // sUSDe / sfrxUSD : targetType = MAX (stored, ratcheted, always <= oracle) -> mint <= oracle
        _assertMintCappedMax(SUSDE);
        _assertMintCappedMax(SFRXUSD);

        // explicit: sUSDe/sfrxUSD mint price equals the stored MAX target, strictly below the raw oracle
        (, uint256 rawSusde) = _morphoOrChainlinkValue(SUSDE);
        (uint256 mintSusde,,,,) = par.getOracleValues(SUSDE);
        assertLe(mintSusde, rawSusde, "sUSDe mint <= raw oracle");

        // and the stable mint price is $1 (deviation-snapped), never above the $1 target
        (uint256 mintUsde,,,,) = par.getOracleValues(USDE);
        assertLe(mintUsde, 1e18, "USDe mint <= $1 target");
    }

    /*//////////////////////////////////////////////////////////////
        D. sfrxUSD VAULT IS NOT DONATION-INFLATABLE
    //////////////////////////////////////////////////////////////*/

    function test_D_sfrxusd_not_donation_inflatable() public {
        IERC4626 v = IERC4626(SFRXUSD);
        uint256 taBefore = v.totalAssets();
        uint256 ctaBefore = v.convertToAssets(1e16);
        uint256 pps = v.pricePerShare();

        // totalAssets is synthetic (rewards-based), NOT asset.balanceOf(vault):
        assertEq(IERC20(FRXUSD).balanceOf(SFRXUSD), 0, "vault holds 0 underlying");
        assertGt(taBefore, 0, "yet totalAssets > 0 -> synthetic");
        assertEq(taBefore, (pps * v.totalSupply()) / 1e18, "totalAssets == pps*totalSupply/1e18 (time-based)");
        assertEq(ctaBefore, (1e16 * pps) / 1e18, "convertToAssets == shares*pps/1e18");

        // real donation: the protocol itself holds frxUSD; move some into the vault
        uint256 donorBal = IERC20(FRXUSD).balanceOf(DIAMOND);
        assertGt(donorBal, 100e18, "protocol holds frxUSD");
        vm.prank(DIAMOND);
        IERC20(FRXUSD).transfer(SFRXUSD, 100e18);
        assertEq(IERC20(FRXUSD).balanceOf(SFRXUSD), 100e18, "donation landed");

        uint256 taAfter = v.totalAssets();
        uint256 ctaAfter = v.convertToAssets(1e16);
        assertEq(taAfter, taBefore, "donation does not change totalAssets");
        assertEq(ctaAfter, ctaBefore, "donation does not change convertToAssets");
        emit log_named_uint("convertToAssets(1e16) unchanged", ctaAfter);

        // and the transmuter mint price for sfrxUSD is unchanged
        uint256 qBefore = par.quoteIn(1000e18, SFRXUSD, TOKEN_P);
        assertEq(par.quoteIn(1000e18, SFRXUSD, TOKEN_P), qBefore, "mint price unchanged after donation");
    }

    /*//////////////////////////////////////////////////////////////
        E. STALENESS IS ENFORCED (Chainlink leg)
    //////////////////////////////////////////////////////////////*/

    function test_E_staleness_enforced() public {
        // fresh: getOracleValues returns
        par.getOracleValues(USDE);

        // warp past the configured stalePeriod (25h) -> the USDe chainlink leg reverts
        vm.warp(block.timestamp + STALE_PERIOD + 1 hours);
        vm.expectRevert();
        par.getOracleValues(USDE);
        emit log_string("stale Chainlink leg -> oracle read reverts (InvalidChainlinkRate)");
    }

    /*//////////////////////////////////////////////////////////////
        F. PERMISSIONLESS MINT AT THE LIVE ORACLE PRICE
    //////////////////////////////////////////////////////////////*/

    function test_F_permissionless_mint_at_oracle_price() public {
        uint256 amountIn = 1000e18;
        uint256 quoted = par.quoteIn(amountIn, USDE, TOKEN_P);
        (uint256 oracleValue,,,,) = par.getOracleValues(USDE);
        // mint price = min(oracle, $1) = oracle (0.9998...) ; fee = 0
        uint256 expected = (oracleValue * amountIn) / 1e18;
        assertEq(quoted, expected, "quoteIn == oracleValue * amountIn");

        // no role needed: a fresh address with USDe can mint
        deal(USDE, ATTACKER, amountIn);
        vm.startPrank(ATTACKER);
        IERC20(USDE).approve(DIAMOND, type(uint256).max);
        uint256 out = par.swapExactInput(amountIn, 0, USDE, TOKEN_P, ATTACKER, block.timestamp);
        vm.stopPrank();

        assertEq(out, expected, "minted USDp == oracle-priced amount");
        assertEq(IERC20(TOKEN_P).balanceOf(ATTACKER), expected, "USDp received");
        emit log_named_uint("USDp minted for 1000 USDe (18dp)", out);
    }

    /*//////////////////////////////////////////////////////////////
        G. REDEMPTION RETURNS <= 0.995x (no free lunch)
    //////////////////////////////////////////////////////////////*/

    function test_G_redemption_never_above_995() public {
        uint256 amount = 1000e18;
        (address[] memory tokens, uint256[] memory amounts) = par.quoteRedemptionCurve(amount);

        // value the quoted basket at the protocol's own (raw) redemption oracle prices
        uint256 value;
        for (uint256 i; i < tokens.length; i++) {
            uint256 p;
            if (tokens[i] == USDE) (, , , , p) = par.getOracleValues(USDE);
            else if (tokens[i] == FRXUSD) (, , , , p) = par.getOracleValues(FRXUSD);
            else if (tokens[i] == SUSDE) (, , , , p) = par.getOracleValues(SUSDE);
            else if (tokens[i] == SFRXUSD) (, , , , p) = par.getOracleValues(SFRXUSD);
            value += (p * amounts[i]) / 1e18;
        }
        emit log_named_uint("basket value (18dp) for 1000 USDp", value);
        assertLe(value, (amount * 995) / 1000 + 1e15, "redemption <= 0.995x + dust");

        // and it actually executes for an unprivileged holder
        deal(TOKEN_P, ATTACKER, amount);
        uint256[] memory minOuts = new uint256[](amounts.length);
        bytes32 h = keccak256(abi.encodePacked(tokens));
        vm.prank(ATTACKER);
        par.redeem(amount, ATTACKER, block.timestamp, minOuts, h);
        assertEq(IERC20(TOKEN_P).balanceOf(ATTACKER), 0, "USDp burned");
    }

    /*//////////////////////////////////////////////////////////////
        H. QUANTIFY THE (CONDITIONAL) STALE-HIGH CEILING
    //////////////////////////////////////////////////////////////*/

    function test_H_conditional_stale_high_ceiling() public {
        // The only profitable direction is: collateral's mark HIGH while its real market price is LOW.
        // mintPrice = min(oracle±dev, target). For USDe/frxUSD target = $1 (so the mark can never exceed
        // $1.00); for sUSDe/sfrxUSD target = stored MAX <= oracle. Redemption fee = 0.5% (yRedemptionCurve
        // last = 0.995). Net per unit = mark*0.995 - real  =>  profit requires real < mark*0.995 <= 0.995,
        // i.e. a >0.5% depeg not yet reflected in the feed.
        (uint256 mintUsde,,,,) = par.getOracleValues(USDE);
        (uint256 mintFrx,,,,) = par.getOracleValues(FRXUSD);
        (uint256 mintSusde,,,,) = par.getOracleValues(SUSDE);
        (uint256 mintSfrx,,,,) = par.getOracleValues(SFRXUSD);

        // stables are deviation-snapped to exactly $1.00 (<= target), never above
        assertEq(mintUsde, 1e18, "USDe mint = $1 (deviation-snapped)");
        assertEq(mintFrx, 1e18, "frxUSD mint = $1 (deviation-snapped)");
        // MAX collaterals mint strictly below the raw oracle (the target lags the oracle)
        (, uint256 rawSusde) = _morphoOrChainlinkValue(SUSDE);
        (, uint256 rawSfrx) = _morphoOrChainlinkValue(SFRXUSD);
        assertLt(mintSusde, rawSusde, "sUSDe mint < raw oracle");
        assertLt(mintSfrx, rawSfrx, "sfrxUSD mint < raw oracle");

        emit log_named_uint("mint USDp per 1 USDe (18dp)", mintUsde);
        emit log_named_uint("mint USDp per 1 frxUSD (18dp)", mintFrx);
        emit log_named_uint("mint USDp per 1 sUSDe (18dp)", mintSusde);
        emit log_named_uint("mint USDp per 1 sfrxUSD (18dp)", mintSfrx);
        emit log_string("E-U today = $0 (fresh feeds; no stale-high gap; stables capped at $1)");
    }

    /*//////////////////////////////////////////////////////////////
        HELPERS
    //////////////////////////////////////////////////////////////*/

    function _assertFresh(address feed) internal view {
        (, int256 ans,, uint256 updatedAt,) = IAggregatorV3(feed).latestRoundData();
        assertGt(ans, 0, "positive answer");
        assertLt(block.timestamp - updatedAt, STALE_PERIOD, "feed within stalePeriod");
    }

    /// @dev asserts that the mint price for a STABLE-target collateral never exceeds the $1 target
    function _assertMintCappedStable(address collateral) internal view {
        (uint256 mint,,,,) = par.getOracleValues(collateral);
        assertLe(mint, 1e18, "stable mint <= $1 target");
    }

    /// @dev asserts that the mint price for a MAX-target collateral never exceeds the raw oracle value
    function _assertMintCappedMax(address collateral) internal view {
        (uint256 mint,,,,) = par.getOracleValues(collateral);
        (, uint256 raw) = _morphoOrChainlinkValue(collateral);
        assertLe(mint, raw, "MAX-collateral mint <= raw oracle value");
    }

    /// @dev raw oracle value ignoring the target cap: for CHAINLINK collaterals read the feed directly;
    ///      for sfrxUSD recompute MorphoChainlinkOracleV2 price.
    function _morphoOrChainlinkValue(address collateral) internal view returns (uint256 kind, uint256 value) {
        if (collateral == USDE) {
            (, int256 a,,,) = IAggregatorV3(USDE_FEED).latestRoundData();
            return (0, uint256(a) * 1e10);
        } else if (collateral == FRXUSD) {
            (, int256 a,,,) = IAggregatorV3(FRXUSD_FEED).latestRoundData();
            return (0, uint256(a) * 1e10);
        } else if (collateral == SUSDE) {
            (, int256 a,,,) = IAggregatorV3(SUSDE_FEED).latestRoundData();
            return (0, uint256(a) * 1e10);
        } else if (collateral == SFRXUSD) {
            uint256 p = IMorphoChainlinkOracleV2(SFRXUSD_MORPHO_ORACLE).price();
            return (1, p / 1e6);
        }
        revert("unknown collateral");
    }
}
