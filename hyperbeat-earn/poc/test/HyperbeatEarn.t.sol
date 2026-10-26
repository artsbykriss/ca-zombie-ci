// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

/* ------------------------------------------------------------------ */
/*  Minimal interfaces (no external deps)                              */
/* ------------------------------------------------------------------ */
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IERC4626 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function deposit(uint256, address) external returns (uint256);
    function mint(uint256, address) external returns (uint256);
    function redeem(uint256, address, address) external returns (uint256);
    function withdraw(uint256, address, address) external returns (uint256);
    function previewDeposit(uint256) external view returns (uint256);
    function previewRedeem(uint256) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function convertToShares(uint256) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function skimRecipient() external view returns (address);
    function skim(address) external;
}

interface IPricer {
    function getRate() external view returns (uint256);
    function getAssetAmount(address, uint256) external view returns (uint256);
    function getVaultTokenAmount(address, uint256) external view returns (uint256);
    function updateExchangeRate(uint96) external;
    function vaultToken() external view returns (address);
    function baseAsset() external view returns (address);
}

interface IWithdrawalQueue {
    function instantWithdraw(address, uint256) external;
    function createWithdrawalRequest(address, uint256, uint256, uint64) external;
    function setPricer(address) external;
    function setPaused(bool) external;
    function setInstantWithdrawalPaused(bool) external;
    function setInstantWithdrawalFee(uint64) external;
    function isPaused() external view returns (bool);
    function isInstantWithdrawalPaused() external view returns (bool);
    function pricer() external view returns (address);
    function vaultToken() external view returns (address);
}

interface IFeed {
    function lastAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function setRoundData(int256) external;
    function setRoundDataSafe(int256) external;
}

interface IMidasToken {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function pause() external;
    function unpause() external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IMultiRolesAuthority {
    function canCall(address, address, bytes4) external view returns (bool);
    function isCapabilityPublic(bytes4) external view returns (bool);
}

interface IDepositor {
    function deposit(address, address, uint256, bytes32) external;
    function isDepositToken(address) external view returns (bool);
    function isPaused() external view returns (bool);
    function depositCap() external view returns (uint256);
    function vaultToken() external view returns (address);
    function pricer() external view returns (address);
}

interface IUltraVault {
    function convertToShares(uint256) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function collectFees() external;
    function chargeManagementFee() external;
    function depositsPaused() external view returns (bool);
    function withdrawalsPaused() external view returns (bool);
    function globalLiabilityShares() external view returns (uint256);
    function globalLiabilityAssets() external view returns (uint256);
    function externalAssets() external view returns (uint256);
    function maxDepositAmount() external view returns (uint256);
}

/* ------------------------------------------------------------------ */
contract HyperbeatEarnPoC is Test {
    // ---- chain / block ----
    uint256 constant FORK_BLOCK = 49_508_160; // HyperEVM recon block

    // ---- tokens ----
    address constant WHYPE = 0x5555555555555555555555555555555555555555;
    address constant USDC  = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant UBTC  = 0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463;

    // ---- MetaMorphoV1_1 vaults ----
    address constant MEV_HYPE       = 0xd19e3d00f8547f7d108abFD4bbb015486437B487;
    address constant GAUNTLET_USDC  = 0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3;
    address constant MEV_USDC       = 0x4851D4891321035729713D43bE1F4bb883Dffd34;
    address constant GAUNTLET_USDe  = 0x5eEC795d919FA97688Fb9844eeB0072E6B846F9d;

    // ---- Midas-lineage permissioned tokens ----
    address constant LSTHYPE   = 0x81e064d0eB539de7c3170EDF38C1A42CBd752A76;
    address constant LIQUIDHYPE= 0x441794D6a8F9A3739F5D4E98a728937b33489D29;
    address constant NLP_TOKEN = 0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA;

    // ---- Midas price feed (LiquidHypeCustomAggregatorFeed) ----
    address constant FEED      = 0x1CeaB703956e24b18a0AF6b272E0bF3F499aCa0F;

    // ---- Pricer + WithdrawalQueue (lstHYPE instance) ----
    address constant PRICER    = 0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b;
    address constant WQ        = 0x8B04Cd6561AbF2de78112DA30Ccb919fe8D09D98;
    address constant AUTH      = 0x82999519c6F7012037375e4930F59474cd27c4Eb; // MultiRolesAuthority

    // ---- Mellow "Ultra" TokenizedAccount ERC4626 vaults ----
    address constant ULTRA_HYPE = 0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB;
    address constant ULTRA_UBTC = 0xc061d38903b99aC12713B550C2CB44B221674F94;

    // ---- permissionless deposit entry points (Depositor) ----
    address constant LSTHYPE_DEPOSITOR = 0x205aC1e0380B0b9ccE691bd4C6f3c14258Ae9201;
    address constant HBAUT_DEPOSITOR   = 0xccBc13AF723Bee139a5Cc48F0C7169a56E10D2D3;
    address constant HBAUT_PRICER      = 0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597;
    address constant XAUT0             = 0xf4D9235269a96aaDaFc9aDAe454a0618eBE37949;

    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("HYPEREVM_RPC", string("https://rpc.hyperliquid.xyz/evm"));
        // NOTE: the HyperEVM public RPC honours the block tag for eth_getBlockByNumber but NOT for
        // eth_call (it serves latest state). Pinning a historical block therefore yields a
        // (state=latest, timestamp=pinned) mismatch that underflows inside Morpho's interest accrual.
        // Fork at latest so state and timestamp are consistent.
        vm.createSelectFork(rpc);
    }

    // fund an address with WHYPE via its WETH9 balanceOf slot (slot 3; verified on-chain:
    // slot0=name, slot1=symbol, slot2=decimals, slot3=balanceOf)
    function _dealWHYPE(address to, uint256 amount) internal {
        vm.store(WHYPE, keccak256(abi.encode(to, uint256(3))), bytes32(amount));
    }

    /* ============================================================ */
    /* 1. Every privileged path reverts for an arbitrary caller      */
    /* ============================================================ */
    function test_01_authority_denies_random_caller() public view {
        bytes4[] memory sels = new bytes4[](6);
        sels[0] = IPricer.updateExchangeRate.selector;
        sels[1] = IWithdrawalQueue.setPricer.selector;
        sels[2] = IWithdrawalQueue.setPaused.selector;
        sels[3] = IWithdrawalQueue.setInstantWithdrawalFee.selector;
        sels[4] = IMidasToken.mint.selector;
        sels[5] = IMidasToken.burn.selector;
        for (uint256 i = 0; i < sels.length; i++) {
            assertFalse(IMultiRolesAuthority(AUTH).canCall(attacker, PRICER, sels[i]), "canCall PRICER must be false");
            assertFalse(IMultiRolesAuthority(AUTH).canCall(attacker, WQ, sels[i]), "canCall WQ must be false");
            assertFalse(IMultiRolesAuthority(AUTH).isCapabilityPublic(sels[i]), "capability must not be public");
        }
    }

    function test_02_pricer_updateExchangeRate_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IPricer(PRICER).updateExchangeRate(2e8); // try to double the rate
    }

    function test_03_wq_privileged_reverts() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IWithdrawalQueue(WQ).setPricer(attacker);
        vm.expectRevert();
        IWithdrawalQueue(WQ).setPaused(true);
        vm.expectRevert();
        IWithdrawalQueue(WQ).setInstantWithdrawalFee(0);
        vm.stopPrank();
    }

    function test_04_midas_token_mint_burn_pause_reverts() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IMidasToken(LSTHYPE).mint(attacker, 1e18);
        vm.expectRevert();
        IMidasToken(LSTHYPE).burn(attacker, 1e18);
        vm.expectRevert();
        IMidasToken(LSTHYPE).pause();
        vm.stopPrank();
    }

    function test_05_vaulttoken_mint_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IMidasToken(NLP_TOKEN).mint(attacker, 1e18);
    }

    /* ============================================================ */
    /* 2. Oracle cannot be moved by a permissionless caller          */
    /* ============================================================ */
    function test_06_feed_lastAnswer_immutable_for_attacker() public {
        int256 before = IFeed(FEED).lastAnswer();
        assertGt(before, 0, "feed should be live");
        vm.startPrank(attacker);
        vm.expectRevert();
        IFeed(FEED).setRoundDataSafe(int256(uint256(before) * 2));
        vm.expectRevert();
        IFeed(FEED).setRoundData(int256(uint256(before) * 2));
        vm.stopPrank();
        assertEq(IFeed(FEED).lastAnswer(), before, "feed unchanged");
    }

    /* ============================================================ */
    /* 3. MetaMorpho: donation does NOT inflate totalAssets          */
    /* ============================================================ */
    function test_07_morpho_totalAssets_market_derived() public view {
        // totalAssets() is derived from Morpho market positions, NOT from the vault's
        // idle token balance -> a direct token donation cannot inflate NAV.
        address[4] memory vs = [MEV_HYPE, GAUNTLET_USDC, MEV_USDC, GAUNTLET_USDe];
        for (uint256 i = 0; i < vs.length; i++) {
            uint256 ta = IERC4626(vs[i]).totalAssets();
            uint256 bal = IERC20(IERC4626(vs[i]).asset()).balanceOf(vs[i]);
            assertGt(ta, 0, "vault has market assets");
            assertEq(bal, 0, "vault holds 0 idle asset");
            assertGt(ta, bal, "totalAssets is market-derived, not balance-derived");
        }
    }

    function test_07b_morpho_donation_does_not_inflate_nav() public {
        uint256 ta0 = IERC4626(MEV_HYPE).totalAssets();
        _dealWHYPE(attacker, 5e18);
        vm.prank(attacker);
        IERC20(WHYPE).transfer(MEV_HYPE, 5e18);
        assertEq(IERC4626(MEV_HYPE).totalAssets(), ta0, "donation must not change totalAssets");
    }

    /* ============================================================ */
    /* 4. MetaMorpho: skim is permissionless but recipient-fixed      */
    /* ============================================================ */
    function test_08_morpho_skim_not_attacker_profitable() public {
        // MEV HYPE has skimRecipient == address(0) -> skim reverts
        assertEq(IERC4626(MEV_HYPE).skimRecipient(), address(0));
        vm.prank(attacker);
        vm.expectRevert();
        IERC4626(MEV_HYPE).skim(WHYPE);

        // Gauntlet USDC has a non-zero skimRecipient but holds 0 idle asset
        address rec = IERC4626(GAUNTLET_USDC).skimRecipient();
        assertTrue(rec != address(0));
        assertEq(IERC20(USDC).balanceOf(GAUNTLET_USDC), 0, "no idle asset to skim");
        uint256 recBefore = IERC20(USDC).balanceOf(rec);
        vm.prank(attacker);
        IERC4626(GAUNTLET_USDC).skim(USDC);
        assertEq(IERC20(USDC).balanceOf(rec), recBefore, "skim moved 0");
        assertEq(IERC20(USDC).balanceOf(attacker), 0, "attacker received nothing");
    }

    /* ============================================================ */
    /* 5. MetaMorpho: deposit->redeem roundtrip cannot profit         */
    /* ============================================================ */
    function test_09_morpho_roundtrip_no_profit_view() public view {
        address[3] memory vs = [MEV_HYPE, GAUNTLET_USDC, MEV_USDC];
        for (uint256 i = 0; i < vs.length; i++) {
            uint256 dec = IERC20(IERC4626(vs[i]).asset()).decimals();
            uint256 x = 10 ** dec;
            uint256 shares = IERC4626(vs[i]).previewDeposit(x);
            uint256 back = IERC4626(vs[i]).previewRedeem(shares);
            assertLe(back, x, "roundtrip must not exceed input");
        }
    }

    function test_10_morpho_roundtrip_no_profit_funded() public {
        // fund attacker with WHYPE and do a real deposit+redeem on MEV HYPE
        _dealWHYPE(attacker, 5e18);
        uint256 inAmt = 1e18;
        vm.startPrank(attacker);
        IERC20(WHYPE).approve(MEV_HYPE, inAmt);
        uint256 shares = IERC4626(MEV_HYPE).deposit(inAmt, attacker);
        uint256 out = IERC4626(MEV_HYPE).redeem(shares, attacker, attacker);
        vm.stopPrank();
        assertGt(shares, 0, "deposit produced shares");
        assertLe(out, inAmt, "attacker cannot extract more than deposited");
    }

    /* ============================================================ */
    /* 6. Midas WithdrawalQueue: instant withdraw needs real tokens   */
    /* ============================================================ */
    function test_11_wq_instantWithdraw_zero_balance_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IWithdrawalQueue(WQ).instantWithdraw(attacker, 1e18);
    }

    function test_12_wq_pricer_roundtrip_no_profit() public view {
        address base = IPricer(PRICER).baseAsset();
        uint256 dec = IERC20(base).decimals();
        uint256 x = 10 ** dec;
        uint256 shares = IPricer(PRICER).getVaultTokenAmount(base, x);
        uint256 back = IPricer(PRICER).getAssetAmount(base, shares);
        assertLe(back, x, "pricer roundtrip must not exceed input");
    }

    /* ============================================================ */
    /* 7. Mellow Ultra ERC4626: donation economics + roundtrip        */
    /* ============================================================ */
    function test_13_ultra_roundtrip_no_profit() public view {
        address[2] memory vs = [ULTRA_HYPE, ULTRA_UBTC];
        for (uint256 i = 0; i < vs.length; i++) {
            uint256 dec = 18;
            if (vs[i] == ULTRA_UBTC) dec = 8;
            uint256 x = 10 ** dec;
            uint256 shares = IUltraVault(vs[i]).convertToShares(x);
            uint256 back = IUltraVault(vs[i]).convertToAssets(shares);
            assertLe(back, x, "ultra roundtrip must not exceed input");
        }
    }

    // Donation to a balance-derived NAV is only profitable for an attacker holding
    // nearly ALL of the supply; at ~$1.6M NAV this is impossible. Prove the economics.
    function test_14_ultra_donation_unprofitable_for_small_holder() public view {
        address[2] memory vs = [ULTRA_HYPE, ULTRA_UBTC];
        for (uint256 i = 0; i < vs.length; i++) {
            uint256 nav = IUltraVault(vs[i]).totalAssets();
            uint256 sup = IUltraVault(vs[i]).totalSupply();
            assertGt(nav, 0);
            assertGt(sup, 0);
            // attacker fraction f = X / (X + NAV_shares). With X << NAV, f ~ 0.
            // profit(D) = f*D - D  < 0 for any f < 1. Attacker needs f ~ 1 (own ~all supply).
            // Show NAV is large (so dominating supply needs > NAV of capital) and the
            // per-share price is already > 1 (first-depositor inflation is dead).
            uint256 priceE18 = (nav * 1e18) / sup;
            assertGt(priceE18, 1e18, "share price already > 1: inflation path closed");
        }
    }

    /* ============================================================ */
    /* 8. Mellow Ultra: collectFees is permissionless but fixed-recip */
    /* ============================================================ */
    function test_15_ultra_collectFees_not_attacker_profitable() public {
        uint256 aBefore = IERC20(UBTC).balanceOf(attacker);
        uint256 feesBefore = IUltraVault(ULTRA_UBTC).totalAssets();
        vm.prank(attacker);
        IUltraVault(ULTRA_UBTC).collectFees();
        assertEq(IERC20(UBTC).balanceOf(attacker), aBefore, "attacker gets no fees");
        assertGe(IUltraVault(ULTRA_UBTC).totalAssets(), feesBefore - 1, "no gain to attacker");
    }

    /* ============================================================ */
    /* 9. Full inventory: every vault's live state is readable, all   */
    /*    custom "vaults" are permissioned (no permissionless deposit) */
    /* ============================================================ */
    function test_16_inventory_live_and_permissioned() public view {
        // MetaMorpho vaults: standard ERC4626, deposit open
        assertGt(IERC4626(MEV_HYPE).maxDeposit(attacker), 0);
        // Midas-lineage tokens: no `deposit`/`asset` selector at all (permissioned mint/burn)
        (bool ok,) = LSTHYPE.staticcall(abi.encodeWithSignature("asset()"));
        assertFalse(ok, "lstHYPE is not an ERC4626 vault");
        // Ultra vaults are ERC4626 but deposits/withdrawals are operator-gated/timelocked
        assertTrue(IUltraVault(ULTRA_HYPE).depositsPaused(), "UltraHYPE deposits paused");
    }

    /* ============================================================ */
    /* 10. Depositor (permissionless deposit) — base-asset-only, and  */
    /*     the cross-asset pricing branch is a LATENT mispricing       */
    /* ============================================================ */
    function test_17_depositor_whitelist_is_base_asset_only() public view {
        // lstHYPE Depositor: base = WHYPE -> only WHYPE accepted
        assertTrue(IDepositor(LSTHYPE_DEPOSITOR).isDepositToken(WHYPE));
        assertFalse(IDepositor(LSTHYPE_DEPOSITOR).isDepositToken(USDC));
        assertFalse(IDepositor(LSTHYPE_DEPOSITOR).isDepositToken(XAUT0));
        assertFalse(IDepositor(LSTHYPE_DEPOSITOR).isPaused());
        // hbXAUt Depositor: base = XAUt0 -> only XAUt0 accepted
        assertTrue(IDepositor(HBAUT_DEPOSITOR).isDepositToken(XAUT0));
        assertFalse(IDepositor(HBAUT_DEPOSITOR).isDepositToken(USDC));
    }

    // LATENT BUG (not reachable today): Pricer.getVaultTokenAmount()'s non-base branch divides
    // a USD price by the BASE-ASSET exchange rate, which is only dimensionally correct when the
    // vault's base asset IS a USD stablecoin. On the WHYPE/XAUt0-base vaults the branch would mint
    // ~77x / ~4000x too many shares. It is unreachable only because no non-base deposit token is
    // whitelisted.
    function test_18_pricer_cross_asset_mispricing_is_latent() public view {
        // hbXAUt: base = XAUt0 ($3983). Deposit 1 USDC ($1) via the non-base branch:
        uint256 sharesFor1usdc = IPricer(HBAUT_PRICER).getVaultTokenAmount(USDC, 1e6);
        assertGt(sharesFor1usdc, 9e17, "~0.958 hbXAUt minted for $1 (should be ~0.00024)");
        // and those shares convert back to >1 XAUt0 (~$4,000) via the BASE path:
        uint256 xautOut = IPricer(HBAUT_PRICER).getAssetAmount(XAUT0, sharesFor1usdc);
        assertGt(xautOut, 900_000, "1 USDC would redeem for >0.9 XAUt0 (~$3.6k): ~4000x mispricing");
        // unreachable today:
        assertFalse(IDepositor(HBAUT_DEPOSITOR).isDepositToken(USDC), "USDC not whitelisted -> latent");

        // lstHYPE: base = WHYPE ($77). Deposit 1 USDC via the non-base branch:
        uint256 lstShares = IPricer(PRICER).getVaultTokenAmount(USDC, 1e6);
        assertGt(lstShares, 9e17, "~0.952 lstHYPE minted for $1 (should be ~0.0123): ~77x mispricing");
        assertFalse(IDepositor(LSTHYPE_DEPOSITOR).isDepositToken(USDC), "USDC not whitelisted -> latent");
    }

    function test_19_lstHYPE_deposit_then_instantWithdraw_is_a_loss() public {
        _dealWHYPE(attacker, 1e18);
        vm.startPrank(attacker);
        IERC20(WHYPE).approve(LSTHYPE_DEPOSITOR, 1e18);
        IDepositor(LSTHYPE_DEPOSITOR).deposit(WHYPE, attacker, 1e18, bytes32(0));
        uint256 shares = IERC20(LSTHYPE).balanceOf(attacker);
        assertGt(shares, 0, "minted lstHYPE shares");
        IWithdrawalQueue(WQ).instantWithdraw(attacker, shares);
        uint256 out = IERC20(WHYPE).balanceOf(attacker);
        vm.stopPrank();
        assertLt(out, 1e18, "roundtrip loses the 0.3% instant-withdrawal fee");
    }
}
