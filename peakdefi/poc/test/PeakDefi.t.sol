// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IPeakFund, IPeakStaking, IERC20} from "../src/IPeakDefi.sol";

/// @title PEAKDEFI live-state / extraction PoC (Ethereum mainnet fork)
/// @notice Read-only reproduction of the L2 Phase-2 audit of PEAKDEFI.
///         No mainnet transactions: everything runs on a fork.
contract PeakDefiEthTest is Test {
    // --- live mainnet addresses (verified 2026-10-13) ---
    address constant GF = 0x07cDB44fA1E7eCEb638c12A3451A3Dc9CE1400e4; // Global Fund (EIP-1167 -> 0xa1dff47e)
    address constant NF = 0xC120C7dB0804ae3AbEB1d5f9c9C70402347B4685; // NFT Fund
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant GSHARE = 0x4D1f4532fe81d0B28dF0Fe9ef14093F37EEcc339; // PEAKDEFI Fund Shares
    address constant NSHARE = 0x506ed0B68f8750cc07daf51F114Bb7c83A541B3f; // NFT Share
    address constant REF_MID = 0xB4238F7C5B5E117CaB8a2AF7e414c8882316D37A; // entitled referrer (global)
    address constant M1 = 0x26D57f312f25Cc4E087a40916600627CA937F41E;     // REP holder / manager
    address constant WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;  // USDC whale (fork impersonation only)
    address constant ATTACKER = address(0xA11CE);

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://ethereum-rpc.publicnode.com";
        forkBlock = vm.createSelectFork(rpc);
    }

    // ------------------------------------------------------------------
    // A. Live state + accounting identity
    // ------------------------------------------------------------------
    function test_A_live_state_accounting_identity() public {
        uint256 gfBal = IERC20(USDC).balanceOf(GF);
        uint256 gfInvestor = IPeakFund(GF).totalFundsInUSDC();
        uint256 gfMgrPool = IPeakFund(GF).totalCommissionLeft();
        uint256 gfRefPool = IPeakFund(GF).peakReferralTotalCommissionLeft();
        assertEq(gfBal, gfInvestor + gfMgrPool + gfRefPool, "global: balance != investor + mgr + ref pools");

        uint256 nfBal = IERC20(USDC).balanceOf(NF);
        uint256 nfInvestor = IPeakFund(NF).totalFundsInUSDC();
        uint256 nfMgrPool = IPeakFund(NF).totalCommissionLeft();
        uint256 nfRefPool = IPeakFund(NF).peakReferralTotalCommissionLeft();
        // allow 0.01 USDC of accumulated withdrawal rounding dust
        assertApproxEqAbs(nfBal, nfInvestor + nfMgrPool + nfRefPool, 1e4, "nft: balance != investor + mgr + ref pools");

        // share supply matches the accounting
        assertEq(IERC20(GSHARE).totalSupply(), IPeakFund(GF).totalSharesAtLastManagePhaseStart(), "global shares");
        assertEq(IERC20(NSHARE).totalSupply(), IPeakFund(NF).totalSharesAtLastManagePhaseStart(), "nft shares");

        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("global fund USDC (6dp)", gfBal);
        emit log_named_uint("  investor capital", gfInvestor);
        emit log_named_uint("  manager commission pool", gfMgrPool);
        emit log_named_uint("  referral commission pool", gfRefPool);
        emit log_named_uint("nft fund USDC (6dp)", nfBal);
        emit log_named_uint("  investor capital", nfInvestor);
        emit log_named_uint("  manager commission pool", nfMgrPool);
        emit log_named_uint("  referral commission pool", nfRefPool);
        emit log_named_uint("global cycle", IPeakFund(GF).cycleNumber());
        emit log_named_uint("nft cycle", IPeakFund(NF).cycleNumber());
    }

    // ------------------------------------------------------------------
    // B. Admin surface: no-ops / gated for a fresh attacker
    // ------------------------------------------------------------------
    function test_B_admin_surface_noop_and_gated() public {
        address ownerBefore = IPeakFund(GF).owner();
        address adminBefore = IPeakFund(GF).proxyAdmin();
        address implBefore = IPeakFund(GF).proxyImplementation();
        address devBefore = IPeakFund(GF).devFundingAccount();
        uint256 devRateBefore = IPeakFund(GF).devFundingRate();
        address nextVerBefore = IPeakFund(GF).nextVersion();
        uint256 usdcBefore = IERC20(USDC).balanceOf(GF);

        vm.startPrank(ATTACKER);
        IPeakFund(GF).changeProxyAdmin(ATTACKER);
        IPeakFund(GF).developerInitiateUpgrade(ATTACKER);
        IPeakFund(GF).migrateOwnedContractsToNextVersion();
        IPeakFund(GF).transferAssetToNextVersion(USDC);
        IPeakFund(GF).changeDeveloperFeeAccount(ATTACKER);
        IPeakFund(GF).changeDeveloperFeeRate(123);
        IPeakFund(GF).listKyberToken(ATTACKER);
        IPeakFund(GF).listCompoundToken(ATTACKER);
        vm.stopPrank();

        assertEq(IPeakFund(GF).owner(), ownerBefore, "owner changed");
        assertEq(IPeakFund(GF).proxyAdmin(), adminBefore, "proxyAdmin changed");
        assertEq(IPeakFund(GF).proxyImplementation(), implBefore, "impl changed");
        assertEq(IPeakFund(GF).devFundingAccount(), devBefore, "devFeeAccount changed");
        assertEq(IPeakFund(GF).devFundingRate(), devRateBefore, "devFeeRate changed");
        assertEq(IPeakFund(GF).nextVersion(), nextVerBefore, "nextVersion changed");
        assertEq(IERC20(USDC).balanceOf(GF), usdcBefore, "fund USDC moved");
        assertFalse(IPeakFund(GF).isKyberToken(ATTACKER), "attacker became kyber token");
        assertFalse(IPeakFund(GF).isCompoundToken(ATTACKER), "attacker became compound token");

        // ownership transfer and re-init are gated
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        IPeakFund(GF).initOwner();
        vm.expectRevert();
        IPeakFund(GF).transferOwnership(ATTACKER);
        vm.expectRevert();
        IPeakFund(GF).renounceOwnership();
        vm.stopPrank();

        // while the current phase is still running: nextPhase and withdrawals revert
        uint256[2] memory lens = IPeakFund(GF).getPhaseLengths();
        uint256 len = IPeakFund(GF).cyclePhase() ? lens[1] : lens[0];
        uint256 end = IPeakFund(GF).startTimeOfCyclePhase() + len;
        if (block.timestamp < end) {
            vm.startPrank(ATTACKER);
            vm.expectRevert();
            IPeakFund(GF).nextPhase();
            vm.expectRevert();
            IPeakFund(GF).withdrawUSDC(1_000_000);
            vm.stopPrank();
        }
    }

    // ------------------------------------------------------------------
    // C. Fresh attacker cannot claim any pool
    // ------------------------------------------------------------------
    function test_C_fresh_attacker_cannot_claim_pools() public {
        vm.startPrank(ATTACKER);
        assertEq(IPeakFund(GF).peakReferralCommissionBalanceOf(ATTACKER), 0, "fresh attacker has referral balance");
        (uint256 commission, ) = IPeakFund(GF).commissionBalanceOf(ATTACKER);
        assertEq(commission, 0, "fresh attacker has manager commission");
        vm.expectRevert();
        IPeakFund(GF).peakReferralRedeemCommission();
        vm.expectRevert();
        IPeakFund(GF).redeemCommission(false);
        vm.expectRevert();
        IPeakFund(GF).registerWithUSDC();
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // D. nextPhase is permissionless (pays the caller nothing);
    //    an *entitled* referrer can then claim its commission (H-O proof)
    // ------------------------------------------------------------------
    function test_D_nextPhase_permissionless_and_entitled_claim() public {
        IPeakFund gf = IPeakFund(GF);
        bool phase = gf.cyclePhase();
        uint256[2] memory lens = gf.getPhaseLengths();
        uint256 len = phase ? lens[1] : lens[0];
        uint256 target = gf.startTimeOfCyclePhase() + len + 1;
        if (block.timestamp < target) vm.warp(target);

        uint256 attUsdcBefore = IERC20(USDC).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        gf.nextPhase(); // permissionless
        assertTrue(gf.cyclePhase() != phase, "phase did not flip");
        assertEq(IERC20(USDC).balanceOf(ATTACKER), attUsdcBefore, "nextPhase paid the caller a reward");
        assertEq(IERC20(USDC).balanceOf(ATTACKER), 0, "caller reward non-zero");

        // entitled referrer claim (H-O) - only possible in the sell phase
        uint256 raw = gf.peakReferralCommissionBalanceOf(REF_MID);
        emit log_named_uint("REF_MID raw referral commission", raw);
        if (raw > 0) {
            uint256 balBefore = IERC20(USDC).balanceOf(REF_MID);
            vm.prank(REF_MID);
            gf.peakReferralRedeemCommission();
            uint256 balAfter = IERC20(USDC).balanceOf(REF_MID);
            assertGt(balAfter, balBefore, "entitled referrer did not get paid");
            emit log_named_uint("REF_MID USDC received", balAfter - balBefore);
        }
    }

    // ------------------------------------------------------------------
    // E. Manager commission pool has no claimer (stranded)
    // ------------------------------------------------------------------
    function test_E_manager_pool_unclaimable() public {
        IPeakFund gf = IPeakFund(GF);
        (uint256 commission, uint256 penalty) = gf.commissionBalanceOf(M1);
        emit log_named_uint("manager commission", commission);
        emit log_named_uint("manager penalty", penalty);
        assertEq(commission, 0, "manager has claimable commission");

        // move to the sell phase (redemptions are sell-phase only)
        uint256[2] memory lens = gf.getPhaseLengths();
        uint256 len = gf.cyclePhase() ? lens[1] : lens[0];
        uint256 target = gf.startTimeOfCyclePhase() + len + 1;
        if (block.timestamp < target) vm.warp(target);
        vm.prank(ATTACKER);
        gf.nextPhase();

        uint256 poolBefore = gf.totalCommissionLeft();
        uint256 balBefore = IERC20(USDC).balanceOf(M1);
        vm.prank(M1);
        gf.redeemCommission(false);
        assertEq(IERC20(USDC).balanceOf(M1), balBefore, "manager was paid from the pool");
        assertEq(gf.totalCommissionLeft(), poolBefore, "manager pool changed");

        // and the per-cycle path is equally empty (reverts or pays zero)
        uint256 balBefore2 = IERC20(USDC).balanceOf(M1);
        vm.prank(M1);
        try gf.redeemCommissionForCycle(false, gf.cycleNumber() - 1) {} catch {}
        assertEq(IERC20(USDC).balanceOf(M1), balBefore2, "per-cycle redemption paid the manager");
        assertEq(gf.totalCommissionLeft(), poolBefore, "manager pool changed after per-cycle redemption");
    }

    // ------------------------------------------------------------------
    // F. Deposit -> withdraw round trip is not profitable for an attacker
    // ------------------------------------------------------------------
    function test_F_deposit_withdraw_not_profitable() public {
        IPeakFund gf = IPeakFund(GF);
        uint256 start = IERC20(USDC).balanceOf(ATTACKER);

        // fund the attacker on the fork (whale impersonation; fork only)
        vm.prank(WHALE);
        IERC20(USDC).transfer(ATTACKER, 10_000e6);

        vm.startPrank(ATTACKER);
        IERC20(USDC).approve(GF, type(uint256).max);
        gf.depositUSDC(1_000e6, address(0)); // deposits are open to anyone, priced at NAV
        vm.stopPrank();

        uint256 shares = IERC20(GSHARE).balanceOf(ATTACKER);
        assertGt(shares, 0, "no shares minted");

        // advance to the sell phase and withdraw part of the position
        bool phase = gf.cyclePhase();
        uint256[2] memory lens = gf.getPhaseLengths();
        uint256 len = phase ? lens[1] : lens[0];
        uint256 target = gf.startTimeOfCyclePhase() + len + 1;
        if (block.timestamp < target) vm.warp(target);
        vm.prank(ATTACKER);
        gf.nextPhase();

        uint256 balBeforeWd = IERC20(USDC).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        gf.withdrawUSDC(900e6);
        uint256 received = IERC20(USDC).balanceOf(ATTACKER) - balBeforeWd;
        assertEq(received, 900e6, "withdrawal did not pay the requested amount");

        // remaining share value at current NAV
        uint256 sharesLeft = IERC20(GSHARE).balanceOf(ATTACKER);
        uint256 navValue = sharesLeft * gf.totalFundsInUSDC() / IERC20(GSHARE).totalSupply();
        // total value returned to the attacker (cash + remaining NAV) must not exceed the deposit
        assertLe(received + navValue, 1_000e6, "round trip was profitable");
        emit log_named_uint("deposited", 1_000e6);
        emit log_named_uint("withdrawn", received);
        emit log_named_uint("remaining share value", navValue);
        emit log_named_uint("total returned", received + navValue);
        // start balance is only used to sanity-check the whale gift
        assertEq(start, 0, "attacker had USDC before the test");
    }

    // ------------------------------------------------------------------
    // G. NFT fund is deposit-open despite isPermissioned == true
    // ------------------------------------------------------------------
    function test_G_nft_fund_permissionless_deposit() public {
        assertTrue(IPeakFund(NF).isPermissioned(), "nft fund not permissioned");
        vm.prank(WHALE);
        IERC20(USDC).transfer(ATTACKER, 2_000e6);
        vm.startPrank(ATTACKER);
        IERC20(USDC).approve(NF, type(uint256).max);
        IPeakFund(NF).depositUSDC(1_000e6, address(0));
        vm.stopPrank();
        assertGt(IERC20(NSHARE).balanceOf(ATTACKER), 0, "no NFT shares minted");
        emit log_named_uint("nft shares minted", IERC20(NSHARE).balanceOf(ATTACKER));
    }
}
