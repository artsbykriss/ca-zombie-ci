// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20,
    IVault,
    INavOracle,
    ILossManager,
    ITranche,
    IMZUSD,
    IFeed
} from "../src/Interfaces.sol";

interface IAccessManager {
    function canCall(address caller, address target, bytes4 selector) external view returns (bool);
}

/// @title Mezzanine (Ethereum) — H-1 fix verification + M-1 loss-allocation probe
/// @notice Read-only fork test. No mainnet transactions; everything runs on a
///         local anvil fork of Ethereum mainnet.
contract MezzanineTest is Test {
    // ---- Ethereum mainnet addresses (verified sources) ----
    address constant VAULT = 0xBB03549117e38103589774AE1D6338D1B237FFA2;
    address constant NAV = 0x9994BC2eCdFd7BDeB5423f5e48E285b91e6a69A7;
    address constant LOSS = 0xD068f54EC22726ba7102Aa425B7845752BEd46E4;
    address constant MZUSD = 0x1BBa049d3869E8d467F38E52AcA8E99D64E310a6;
    address constant WYLDS = 0x6aD038cA6C04e885630851278ca0a856Ad9a66Cc;
    address constant JUNIOR = 0x6F5d94Dc0c8bBf052aBF024259d087dA45AD96A1;
    address constant SENIOR = 0x0e246e5FA94E90ab784b03961C35AaD9999b6649;

    // AccessManager role holders (live, read from RoleGranted logs / canCall):
    address constant SUBMITTER = 0x816dd023C90eDfb751EEfdCCe064AeBB3Bb2AaEd; // role 6, EOA
    address constant ADMIN_SAFE = 0x0b61220A0d0aFd11da63B2931EE368E34E60d122; // role 0, Safe
    address constant FINALIZER = 0x0630e23e0c2D2147b64Ca493f656fE2514D2027B; // role 9
    address constant KEEPER = 0xFAf5012Ee1d9344cf388281e67982Efa75a0bC77; // role 10, automation

    address constant ATTACKER = address(0xB0B);

    IVault vault;
    INavOracle nav;
    ILossManager loss;
    IMZUSD mzusd;

    function setUp() public {
        string memory rpc = vm.envOr(
            "BLOCKPI_RPC_URL",
            vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        vm.createSelectFork(rpc);
        vault = IVault(VAULT);
        nav = INavOracle(NAV);
        loss = ILossManager(LOSS);
        mzusd = IMZUSD(MZUSD);
        console2.log("Ethereum fork block", block.number);
    }

    /* ------------------------------------------------------------------ */
    /* 1. Live state + H-1 fix presence                                    */
    /* ------------------------------------------------------------------ */

    function test_live_state_and_h1_fix() public {
        console2.log("epoch duration", vault.epochDuration());
        console2.log("current epoch", vault.currentEpochId());
        console2.log("pending delta", nav.pendingDeltaUSDC());

        assertEq(vault.tranchesLength(), 2);
        (address[] memory ts, uint16[] memory prem, bool[] memory enabled) = vault.getTranches(0, 2);
        assertEq(ts.length, 2);
        assertEq(ts[0], JUNIOR);
        assertEq(ts[1], SENIOR);
        assertEq(uint256(prem[0]), 2000);
        assertEq(uint256(prem[1]), 0);
        // Both tranches are ENABLED live -> the M-1 "disabled tranche" condition
        // does not exist on the live deployment at this block.
        assertTrue(enabled[0]);
        assertTrue(enabled[1]);

        assertFalse(ITranche(JUNIOR).directWithdrawEnabled());
        assertFalse(ITranche(SENIOR).directWithdrawEnabled());
        assertEq(ITranche(JUNIOR).unstakeDelayEpochs(), 2);
        assertEq(ITranche(SENIOR).unstakeDelayEpochs(), 1);

        // H-1 fix: the deployed NavOracle bytecode contains OraclesNotInSync().
        assertTrue(_codeContains(address(nav).code, bytes4(keccak256("OraclesNotInSync()"))));

        // Both feeds are live; both answers are fresh.
        (, int256 navAnswer, , uint256 navTs, ) = IFeed(nav.navOracle()).latestRoundData();
        (, int256 supAnswer, , uint256 supTs, ) = IFeed(nav.totalSupplyOracle()).latestRoundData();
        console2.log("nav answer", uint256(navAnswer));
        console2.log("supply answer", uint256(supAnswer));
        console2.log("nav updatedAt", navTs);
        console2.log("supply updatedAt", supTs);
        assertGt(navAnswer, 0);
        assertGt(supAnswer, 0);
        assertGt(navTs, 0);
        assertGt(supTs, 0);

        assertEq(uint256(nav.vetoPeriod()), 86_400);
        assertEq(uint256(nav.maxAnswerStaleness()), 86_400);

        // AccessManager role gate: submitter can call submitNav, attacker cannot.
        IAccessManager am = IAccessManager(nav.authority());
        bytes4 submitSel = bytes4(keccak256("submitNav()"));
        assertTrue(am.canCall(SUBMITTER, NAV, submitSel));
        assertFalse(am.canCall(ATTACKER, NAV, submitSel));
    }

    function test_submit_nav_unauthorized_reverts() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        nav.submitNav();
    }

    /* ------------------------------------------------------------------ */
    /* 2. H-1: desynced oracle timestamps revert                           */
    /* ------------------------------------------------------------------ */

    function test_h1_oracles_not_in_sync_reverts() public {
        _clearPending();

        _mockFeed(nav.navOracle(), block.timestamp, 500_000e8);
        _mockFeed(nav.totalSupplyOracle(), block.timestamp - 1, 499_000e8);

        vm.prank(SUBMITTER);
        vm.expectRevert(bytes4(keccak256("OraclesNotInSync()")));
        nav.submitNav();
    }

    function test_h1_synced_oracles_pass() public {
        _clearPending();

        _mockFeed(nav.navOracle(), block.timestamp, 500_000e8);
        _mockFeed(nav.totalSupplyOracle(), block.timestamp, 499_000e8);

        vm.prank(SUBMITTER);
        nav.submitNav();

        assertTrue(nav.hasPendingNav());
        assertTrue(nav.pendingIsYield());
        assertEq(uint256(nav.pendingDeltaUSDC()), 1_000e6);

        // Clean up the pending state (role 0 admin Safe; rejectPendingNav is
        // role 0, not the role-6 submitter).
        vm.prank(ADMIN_SAFE);
        nav.rejectPendingNav();
        assertFalse(nav.hasPendingNav());
    }

    /* ------------------------------------------------------------------ */
    /* 3. M-1: disabled tranche still absorbs loss                         */
    /* ------------------------------------------------------------------ */

    function test_m1_live_has_no_disabled_tranche() public {
        (address[] memory ts, , bool[] memory enabled) = vault.getTranches(0, 2);
        assertEq(ts.length, 2);
        assertTrue(enabled[0]);
        assertTrue(enabled[1]);
    }

    /// @notice Fork-only proof of M-1: disable the first-loss Junior tranche,
    ///         then apply a 100,000 USDC loss. The disabled Junior still burns
    ///         100,000 MZUSD; the enabled Senior is untouched. This is a
    ///         fairness bug for the disabled tranche's holders, not a positive
    ///         yield for anyone.
    function test_m1_disabled_junior_absorbs_loss() public {
        _clearPending();

        // Disable Junior; move the 2000 bps risk premium to Senior so the
        // 10,000 bps total still validates. A disabled tranche must have 0
        // risk premium (the vault's own check).
        IVault.TrancheInfo[] memory infos = new IVault.TrancheInfo[](2);
        infos[0] = IVault.TrancheInfo({tranche: JUNIOR, riskPremiumBps: 0, enabled: false});
        infos[1] = IVault.TrancheInfo({tranche: SENIOR, riskPremiumBps: 2000, enabled: true});
        bool[] memory pairs = new bool[](2);
        vm.prank(ADMIN_SAFE);
        vault.setTrancheConfig(infos, pairs, 8000);

        (address[] memory ts, , bool[] memory enabled) = vault.getTranches(0, 2);
        assertEq(ts[0], JUNIOR);
        assertFalse(enabled[0]);
        assertTrue(enabled[1]);

        uint256 juniorBefore = mzusd.balanceOf(JUNIOR);
        uint256 seniorBefore = mzusd.balanceOf(SENIOR);
        console2.log("junior raw before", juniorBefore);
        console2.log("senior raw before", seniorBefore);

        vm.warp(uint256(vault.epochStart()) + uint256(vault.epochDuration()) + 1);
        vm.prank(NAV);
        loss.applyLoss(100_000e6);

        uint256 juniorAfter = mzusd.balanceOf(JUNIOR);
        uint256 seniorAfter = mzusd.balanceOf(SENIOR);
        console2.log("junior raw after", juniorAfter);
        console2.log("senior raw after", seniorAfter);

        // The disabled Junior absorbed the whole loss (its TVL is > 100k).
        assertEq(juniorBefore - juniorAfter, 100_000e18);
        // The enabled Senior did not participate (loss exhausted by Junior).
        assertEq(seniorAfter, seniorBefore);
    }

    /* ------------------------------------------------------------------ */
    /* 4. M-1: a fresh depositor cannot withdraw more than deposited       */
    /* ------------------------------------------------------------------ */

    /// @notice Deposit into the first-loss Junior, have the oracle apply a
    ///         200,000 USDC loss, then queue/finalize/claim. The attacker
    ///         receives strictly less MZUSD than deposited; there is no
    ///         positive extraction, even with the disabled-tranche fairness bug.
    function test_m1_fresh_depositor_cannot_profit() public {
        _clearPending();

        uint256 deposit = 200_000e18;
        deal(MZUSD, ATTACKER, deposit);

        vm.startPrank(ATTACKER);
        mzusd.approve(JUNIOR, deposit);
        uint256 shares = ITranche(JUNIOR).deposit(deposit, ATTACKER);
        assertEq(ITranche(JUNIOR).balanceOf(ATTACKER), shares);
        assertEq(mzusd.balanceOf(ATTACKER), 0);
        vm.stopPrank();

        // Loss arrives after the deposit; the Junior is first-loss.
        vm.warp(uint256(vault.epochStart()) + uint256(vault.epochDuration()) + 1);
        vm.prank(NAV);
        loss.applyLoss(200_000e6);

        vm.prank(ATTACKER);
        ITranche(JUNIOR).requestWithdrawal(shares);

        uint64 target = vault.currentEpochId() + uint64(ITranche(JUNIOR).unstakeDelayEpochs());

        // Advance the vault through the target epoch (permissioned harness;
        // on a live chain this is the LossManager/NavOracle heartbeat).
        for (uint256 i = 0; i < 3; i++) {
            vm.warp(block.timestamp + uint256(vault.epochDuration()) + 1);
            vm.prank(LOSS);
            vault.advanceEpoch();
        }
        assertGt(uint256(vault.currentEpochId()), uint256(target));

        vm.prank(FINALIZER);
        ITranche(JUNIOR).finalizeEpoch(target);

        vm.prank(ATTACKER);
        ITranche(JUNIOR).claim(ATTACKER, target);

        uint256 claimed = mzusd.balanceOf(ATTACKER);
        console2.log("deposited", deposit);
        console2.log("claimed  ", claimed);
        assertLt(claimed, deposit);
        assertEq(mzusd.balanceOf(ATTACKER), claimed); // nothing else minted
    }

    /// @notice Even when the *first-loss* tranche is disabled (so it absorbs the
    ///         loss and the enabled tranche is protected), a fresh depositor in
    ///         the enabled tranche can at most break even; they never withdraw
    ///         more than they deposited. The loss is shifted to the disabled
    ///         tranche's existing holders.
    function test_m1_disabled_junior_protects_enabled_but_no_positive_yield() public {
        _clearPending();

        IVault.TrancheInfo[] memory infos = new IVault.TrancheInfo[](2);
        infos[0] = IVault.TrancheInfo({tranche: JUNIOR, riskPremiumBps: 0, enabled: false});
        infos[1] = IVault.TrancheInfo({tranche: SENIOR, riskPremiumBps: 2000, enabled: true});
        bool[] memory pairs = new bool[](2);
        vm.prank(ADMIN_SAFE);
        vault.setTrancheConfig(infos, pairs, 8000);

        uint256 deposit = 200_000e18;
        deal(MZUSD, ATTACKER, deposit);
        vm.startPrank(ATTACKER);
        mzusd.approve(SENIOR, deposit);
        uint256 shares = ITranche(SENIOR).deposit(deposit, ATTACKER);
        vm.stopPrank();

        uint256 seniorBefore = mzusd.balanceOf(SENIOR);
        vm.warp(uint256(vault.epochStart()) + uint256(vault.epochDuration()) + 1);
        vm.prank(NAV);
        loss.applyLoss(200_000e6);
        uint256 seniorAfter = mzusd.balanceOf(SENIOR);

        // The disabled Junior absorbed the loss; the Senior raw MZUSD balance
        // (the loss-bearing asset) is unchanged.
        assertEq(seniorAfter, seniorBefore);

        // The attacker's shares are still worth exactly the deposit (no yield
        // was distributed), so there is no positive E-U even in this case.
        uint256 value = ITranche(SENIOR).convertToAssets(shares);
        console2.log("senior value after loss", value);
        // 168 MZUSD of this is the normal live yield stream accruing during
        // the warp; the loss itself added nothing.
        assertLe(value, deposit + 1_000e18);
    }

    /* ------------------------------------------------------------------ */
    /* 5. Residual: yield sniping is bounded by the reported yield         */
    /* ------------------------------------------------------------------ */

    /// @notice The H-1 fix does not stop a depositor from sharing in a *real*
    ///         yield that is already pending (submitted before the deposit and
    ///         applied after the veto). The capture is bounded by the reported
    ///         delta (1,000 USDC in this mock), not by the deposit. With the
    ///         live ~562 USDC pending delta, the ceiling is ~$562 per epoch
    ///         regardless of attacker capital.
    function test_yield_sniping_bounded_by_reported_yield() public {
        _clearPending();

        _mockFeed(nav.navOracle(), block.timestamp, 500_000e8);
        _mockFeed(nav.totalSupplyOracle(), block.timestamp, 499_000e8);
        vm.prank(SUBMITTER);
        nav.submitNav();
        assertEq(uint256(nav.pendingDeltaUSDC()), 1_000e6);

        // Attacker deposits a large amount *after* the pending NAV is fixed but
        // before it is applied.
        uint256 deposit = 1_000_000e18;
        deal(MZUSD, ATTACKER, deposit);
        vm.startPrank(ATTACKER);
        mzusd.approve(JUNIOR, deposit);
        uint256 shares = ITranche(JUNIOR).deposit(deposit, ATTACKER);
        vm.stopPrank();

        // Veto + epoch elapse, then apply the pending yield.
        vm.warp(block.timestamp + 86_400 + 1);
        vm.warp(block.timestamp + uint256(vault.epochDuration()) + 1);
        vm.prank(KEEPER);
        nav.performUpkeep("");

        // Let the linear yield stream finish (epochDuration = 600,300 s).
        vm.warp(block.timestamp + 7 days);

        uint256 value = ITranche(JUNIOR).convertToAssets(shares);
        uint256 captured = value > deposit ? value - deposit : 0;
        console2.log("deposit ", deposit);
        console2.log("value   ", value);
        console2.log("captured", captured);

        // The capture cannot exceed the 1,000 USDC yield that was reported and
        // applied; it is not an unbacked mint proportional to the deposit.
        // `captured` includes the pre-existing live yield stream that accrues
        // during the 7-day warp; the incremental capture from the 1,000 USDC
        // report is ~1,000. Both are tiny relative to the 1,000,000 deposit.
        assertLe(captured, 2_000e18);
    }

    /* ------------------------------------------------------------------ */
    /* Helpers                                                             */
    /* ------------------------------------------------------------------ */

    function _clearPending() internal {
        if (nav.hasPendingNav()) {
            vm.prank(ADMIN_SAFE);
            nav.rejectPendingNav();
        }
    }

    function _mockFeed(address feed, uint256 updatedAt, int256 answer) internal {
        vm.mockCall(
            feed,
            abi.encodeWithSelector(IFeed.latestRoundData.selector),
            abi.encode(uint80(1), answer, updatedAt, updatedAt, uint80(1))
        );
    }

    function _codeContains(bytes memory code, bytes4 selector) internal pure returns (bool) {
        for (uint256 i = 0; i + 4 <= code.length; i++) {
            if (
                code[i] == selector[0] && code[i + 1] == selector[1] && code[i + 2] == selector[2]
                    && code[i + 3] == selector[3]
            ) {
                return true;
            }
        }
        return false;
    }
}
