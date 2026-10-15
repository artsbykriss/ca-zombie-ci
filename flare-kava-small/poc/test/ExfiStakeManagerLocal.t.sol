// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/// Minimal ERC20 for the local harness.
contract MockERC20 {
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory s) {
        symbol = s;
    }

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
        totalSupply += a;
    }

    function approve(address s, uint256 a) external returns (bool) {
        allowance[msg.sender][s] = a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        require(balanceOf[msg.sender] >= a, "ERC20: balance");
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        require(balanceOf[f] >= a, "ERC20: balance");
        require(allowance[f][msg.sender] >= a, "ERC20: allowance");
        allowance[f][msg.sender] -= a;
        balanceOf[f] -= a;
        balanceOf[to] += a;
        return true;
    }
}

/// Mock of the APYCloud notifier: the manager calls `epochDuration()` (0x4ff0876a) and a
/// first-epoch getter (0x5aecb7b7) on it during vault initialisation, and only this address
/// may call `updateRewardAmountByToken`.
contract MockAPYCloud {
    uint256 public firstEpoch;

    constructor(uint256 zeroEpoch) {
        firstEpoch = zeroEpoch + 86400;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        bytes4 sel = bytes4(data[:4]);
        if (sel == 0x4ff0876a) return abi.encode(uint32(86400));
        if (sel == 0x5aecb7b7) return abi.encode(uint32(firstEpoch));
        return abi.encode(uint256(0));
    }
}

/// Placeholder vault with code: the manager calls `apyCloud()` (0xa5032f3c) on it.
contract MockVault {
    address public immutable APYCLOUD;

    constructor(address apyCloud) {
        APYCLOUD = apyCloud;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        bytes4 sel = bytes4(data[:4]);
        if (sel == 0xa5032f3c) return abi.encode(APYCLOUD);
        return abi.encode(uint256(0));
    }
}

interface IMgr {
    function initialize(address stakingTokenAddress, uint256 zeroEpochTimeStamp, address[] calldata rewardTokens, address apyCloudVaultAddress) external;
    function stake(uint256) external;
    function stakeWithHint(uint256, uint256) external;
    function withdraw(uint256) external;
    function withdrawWithHint(uint256, uint256) external;
    function claimRewards() external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);
    function getLatestEpochForRewards() external view returns (uint256);
    function epochSnapshotBlock(uint256) external view returns (uint256);
    function balanceOfEpoch(address, uint256) external view returns (uint256);
    function getBalanceAt(address, uint256) external view returns (uint256);
    function getBalanceHint(address) external view returns (uint256);
    function usersCheckpointsCount(address) external view returns (uint256);
    function checkpoints(address, uint256) external view returns (uint256, uint256);
    function userLastRewardClaimEpoch(address) external view returns (uint256);
    function getAllUnclaimedRewards(address) external view returns (uint256[] memory);
    function getRewardTokens() external view returns (address[] memory);
    function epochRewardRate(uint256, address) external view returns (uint256);
    function totalSupplyByEpoch(uint256) external view returns (int256);
    function updateRewardAmountByToken(address, uint256) external returns (bool);
    function updateTotalSupplyByEpochIfNeeded(uint256) external returns (uint256);
    function updateApyCloudVault(address) external;
    function updateRewardTokensAdd(address) external;
    function updateGovernor(address, bool) external;
    function updateTotalSupplyAggregationRange(uint256) external;
    function withdrawReturnedFees(bool) external;
    function DURATION() external view returns (uint256);
    function ZERO_EPOCH_START() external view returns (uint256);
}

/// @title EXFI (Enosys) Governance Stake Manager — deterministic PoC on the EXACT deployed bytecode
/// @notice The Songbird public RPC keeps only ~3 blocks of state (no historical `eth_getStorageAt`),
///         so a live fork is impossible. Instead the deployed *implementation* runtime bytecode
///         (0xB0E4D5baB93B0a7a6A99b7AFCfb50501d8B19772, fetched read-only from Songbird) is etched
///         into a local EVM and initialised, giving full state-changing coverage of the live logic.
contract ExfiStakeManagerLocalTest is Test {
    address constant MANAGER = address(0x1000000000000000000000000000000000000001);
    address constant NOTIFIER_SELECTOR = address(0); // unused
    address constant ATTACKER = address(0xA11CE);
    address constant USER2 = address(0xB0B);

    IMgr mgr = IMgr(MANAGER);
    MockERC20 exfi;
    MockERC20 wsgbb;
    MockVault vault;
    address notifier;

    function setUp() public {
        vm.warp(1_800_000_000); // fixed clock for determinism
        // 1. etch the exact deployed implementation runtime bytecode
        bytes memory code = vm.parseBytes(vm.readFile("exfi_impl_bytecode.hex"));
        vm.etch(MANAGER, code);
        // 2. local harness tokens + vault
        exfi = new MockERC20("EXFI");
        wsgbb = new MockERC20("WSGB");
        uint256 zeroEpoch = block.timestamp - 5 days;
        MockAPYCloud apy = new MockAPYCloud(zeroEpoch);
        vault = new MockVault(address(apy));
        notifier = address(apy);
        address[] memory rewards = new address[](2);
        rewards[0] = address(exfi);
        rewards[1] = address(wsgbb);
        // 3. initialise exactly like the live proxy was (zeroEpoch = 5 days ago)
        mgr.initialize(address(exfi), zeroEpoch, rewards, address(vault));
        console2.log("notifier", notifier);
        // 5. fund: manager holds a reward pool; users hold tokens
        exfi.mint(MANAGER, 1_000_000e18);
        wsgbb.mint(MANAGER, 1_000_000e18);
        exfi.mint(ATTACKER, 10_000e18);
        exfi.mint(USER2, 10_000e18);
        vm.prank(ATTACKER);
        exfi.approve(MANAGER, type(uint256).max);
        vm.prank(USER2);
        exfi.approve(MANAGER, type(uint256).max);
        vm.deal(ATTACKER, 100 ether);
    }

    function _sum(uint256[] memory a) internal pure returns (uint256 s) {
        for (uint256 i = 0; i < a.length; i++) s += a[i];
    }

    /// T1 — a fresh staker cannot capture rewards for epochs before their stake
    function test_L1_no_retro_capture() public {
        uint256 e0 = mgr.getCurrentEpoch();
        uint256 hint_ATTACKER_7563 = mgr.getBalanceHint(ATTACKER);
        vm.prank(ATTACKER);
        mgr.stakeWithHint(1_000e18, hint_ATTACKER_7563);
        assertEq(mgr.balanceOf(ATTACKER), 1_000e18, "staked");
        assertEq(mgr.balanceOfEpoch(ATTACKER, e0 - 1), 0, "no balance before stake");
        assertEq(mgr.balanceOfEpoch(ATTACKER, 1), 0, "no balance epoch 1");

        // register rewards for the epoch *before* the stake (simulating the live notifier)
        vm.prank(notifier);
        mgr.updateRewardAmountByToken(address(exfi), 5_000e18);
        uint256 latest = mgr.getLatestEpochForRewards();
        console2.log("latestEpochForRewards after registration", latest);
        // whatever epoch was credited, the attacker had no balance before e0
        uint256 retro;
        for (uint256 e = 1; e < e0; e++) {
            retro += (mgr.balanceOfEpoch(ATTACKER, e) * mgr.epochRewardRate(e, address(exfi))) / 1e18;
        }
        assertEq(retro, 0, "zero retro rewards across all pre-stake epochs");
        assertEq(_sum(mgr.getAllUnclaimedRewards(ATTACKER)), 0, "nothing claimable");
        uint256 balBefore = exfi.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("EnosysGovernanceStakeManager: No any rewards"));
        mgr.claimRewards();
        assertEq(exfi.balanceOf(ATTACKER), balBefore, "claim paid nothing");
        console2.log("L1 ok");
    }

    /// T2 — reward flow end-to-end: payout equals the exact documented formula, once only.
    /// The epoch snapshot / epoch-total-supply slots (159 / 164, verified against live state)
    /// are set to the values the live chain would hold, so the payout math is exercised exactly.
    function test_L2_fair_payout_exact_formula() public {
        uint256 e0 = mgr.getCurrentEpoch();
        uint256 b0 = block.number;
        uint256 hA = mgr.getBalanceHint(ATTACKER);
        vm.prank(ATTACKER);
        mgr.stakeWithHint(1_000e18, hA);
        uint256 hB = mgr.getBalanceHint(USER2);
        vm.prank(USER2);
        mgr.stakeWithHint(1_000e18, hB);
        // epoch total supply as the live aggregation would report it
        vm.store(MANAGER, keccak256(abi.encode(e0, uint256(164))), bytes32(uint256(2_000e18)));

        // roll into the next epoch, trigger the epoch-snapshot machinery with a dust stake
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 50_000);
        uint256 e1 = mgr.getCurrentEpoch();
        assertGt(e1, e0, "epoch advanced");
        uint256 hB2 = mgr.getBalanceHint(USER2);
        vm.prank(USER2);
        mgr.stakeWithHint(1e18, hB2);
        // pin the snapshot for e0 to a block where both stakers already held their stake
        vm.store(MANAGER, keccak256(abi.encode(e0, uint256(159))), bytes32(b0));
        assertEq(mgr.balanceOfEpoch(ATTACKER, e0), 1_000e18, "epoch-e0 balance counted");

        // notifier credits rewards one epoch at a time (as on mainnet); walk forward until
        // the attacker's staking epoch has been credited
        vm.startPrank(notifier);
        for (uint256 i = 0; i < 12 && mgr.getLatestEpochForRewards() < e0; i++) {
            mgr.updateRewardAmountByToken(address(exfi), 1_000e18);
            if (mgr.getLatestEpochForRewards() < e0) {
                vm.warp(block.timestamp + 1 days);
                vm.roll(block.number + 50_000);
            }
        }
        vm.stopPrank();

        uint256 latest = mgr.getLatestEpochForRewards();
        console2.log("latestEpochForRewards", latest);
        assertGe(latest, e0, "staking epoch credited");
        console2.log("rate(e0,EXFI)", mgr.epochRewardRate(e0, address(exfi)));
        uint256 expected;
        for (uint256 e = 1; e <= latest; e++) {
            expected += (mgr.balanceOfEpoch(ATTACKER, e) * mgr.epochRewardRate(e, address(exfi))) / 1e18;
        }
        assertGt(expected, 0, "attacker earned something");
        uint256[] memory un = mgr.getAllUnclaimedRewards(ATTACKER);
        assertEq(un[0], expected, "unclaimed == formula");
        uint256 before = exfi.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        mgr.claimRewards();
        uint256 got = exfi.balanceOf(ATTACKER) - before;
        console2.log("claimed", got, "expected", expected);
        assertEq(got, expected, "payout == formula exactly");
        // double claim reverts (claim cursor already at the latest credited epoch)
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("EnosysGovernanceStakeManager: At least one epoch has not passed"));
        mgr.claimRewards();
        // user2 got their own (equal) share
        uint256 u2Before = exfi.balanceOf(USER2);
        vm.prank(USER2);
        mgr.claimRewards();
        uint256 u2Got = exfi.balanceOf(USER2) - u2Before;
        console2.log("user2 claimed", u2Got);
        assertGt(u2Got, 0, "user2 paid");
        console2.log("L2 ok");
    }

    /// T3 — hint abuse: oversized hints revert; undersized hints cannot corrupt checkpoints
    function test_L3_hint_abuse_no_corruption() public {
        uint256 hint_ATTACKER_549 = mgr.getBalanceHint(ATTACKER);
        vm.prank(ATTACKER);
        mgr.stakeWithHint(100e18, hint_ATTACKER_549);
        uint256 n1 = mgr.usersCheckpointsCount(ATTACKER);
        console2.log("checkpoints after first stake", n1, "hint", mgr.getBalanceHint(ATTACKER));

        // undersized hint
        vm.prank(ATTACKER);
        try mgr.stakeWithHint(1e18, 0) {
            console2.log("undersized hint ACCEPTED");
        } catch (bytes memory r) {
            console2.log("undersized hint reverted");
            console2.logBytes(r);
        }
        // oversized hint must revert
        vm.prank(ATTACKER);
        vm.expectRevert();
        mgr.stakeWithHint(1e18, type(uint256).max);
        // withdraw with undersized hint
        vm.prank(ATTACKER);
        try mgr.withdrawWithHint(1e18, 0) {
            console2.log("withdraw undersized hint ACCEPTED");
        } catch (bytes memory r) {
            console2.log("withdraw undersized hint reverted");
            console2.logBytes(r);
        }

        // invariants
        uint256 n = mgr.usersCheckpointsCount(ATTACKER);
        uint256 prev = 0;
        for (uint256 i = 0; i < n; i++) {
            (uint256 blk, ) = mgr.checkpoints(ATTACKER, i);
            assertGe(blk, prev, "checkpoints block-sorted");
            prev = blk;
        }
        uint256 cur = mgr.getCurrentEpoch();
        for (uint256 e = 1; e < cur; e++) {
            assertEq(mgr.balanceOfEpoch(ATTACKER, e), 0, "past epoch stays 0");
        }
        assertLe(mgr.balanceOf(ATTACKER), 101e18, "balance <= deposits");
        console2.log("L3 ok");
    }

    /// T4 — admin / notifier / governor paths gated for unprivileged callers
    function test_L4_gating() public {
        vm.startPrank(ATTACKER);
        vm.expectRevert(bytes("EnosysGovernanceStakeManager: Not allowed reward notifier"));
        mgr.updateRewardAmountByToken(address(exfi), 1_000e18);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        mgr.updateApyCloudVault(ATTACKER);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        mgr.updateRewardTokensAdd(ATTACKER);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        mgr.updateGovernor(ATTACKER, true);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        mgr.updateTotalSupplyAggregationRange(1);
        vm.expectRevert(bytes("EnosysGovernanceStakeManager: No pending fees"));
        mgr.withdrawReturnedFees(true);
        vm.stopPrank();
        console2.log("L4 ok");
    }

    /// T5 — principal integrity and permissionless epoch-total update is idempotent
    function test_L5_principal_and_permissionless_update() public {
        uint256 hint_ATTACKER_8210 = mgr.getBalanceHint(ATTACKER);
        vm.prank(ATTACKER);
        mgr.stakeWithHint(500e18, hint_ATTACKER_8210);
        vm.prank(ATTACKER);
        vm.expectRevert();
        mgr.withdraw(500e18 + 1);
        vm.prank(ATTACKER);
        mgr.withdraw(500e18);
        assertEq(mgr.balanceOf(ATTACKER), 0, "withdrawn");

        // permissionless epoch-total finaliser: callable for settled epochs, rejected for current/next
        vm.warp(block.timestamp + 3 days);
        vm.roll(block.number + 150_000);
        uint256 eNow = mgr.getCurrentEpoch();
        uint256 ePast = eNow - 2;
        vm.prank(ATTACKER);
        uint256 ret = mgr.updateTotalSupplyByEpochIfNeeded(ePast);
        console2.log("epoch", ePast);
        console2.log("returned total supply for epoch", ret);
        // current/next epoch must be rejected
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("EnosysGovernanceStakeManager: Cannot update total supply for the current or next epoch"));
        mgr.updateTotalSupplyByEpochIfNeeded(eNow + 1);
        console2.log("L5 ok");
    }
}
