// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, IEarnVault, IRewardRedistributor, IPoolManager, IUnlockCallback} from "../src/IStartale.sol";

/// @title ZH4-02 follow-up — can the JIT cycle be atomicized with a flash loan?
/// @notice Soneium mainnet fork. The only $1M+ same-tx USDSC source is the
///         Uniswap v4 PoolManager singleton ($2.25M USDSC, flash accounting,
///         no protocol fee). This suite proves the loan itself works and that
///         the full atomic cycle nevertheless reverts at the keeper gate.
contract StartaleFlashloanTest is Test {
    address constant VAULT = 0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0;
    address constant RR = 0xda798684ffD5eb509c2Ab7b8352EC55B31F18201;
    address constant USDSC = 0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a;
    address constant KEEPER = 0x86bE13a26d548FA5407Ee3E5a8321B4E1019333C;
    address constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;
    bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 constant PIN = 29_573_086; // same live fork as the main PoC

    V4FlashBorrower borrower;

    function setUp() public {
        vm.createSelectFork(vm.envOr("SONEIUM_RPC_URL", string("https://rpc.soneium.org")), PIN);
        borrower = new V4FlashBorrower();
    }

    function test_P5a_snapshot_is_keeper_gated() public {
        address rand = makeAddr("rand");
        vm.startPrank(rand);
        vm.expectRevert(abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)", rand, OPERATOR_ROLE));
        IRewardRedistributor(RR).snapshotVaultTVLs();
        vm.stopPrank();
        console.log("snapshotVaultTVLs: OPERATOR_ROLE required");
    }

    function test_P5b_distribute_is_keeper_gated() public {
        address rand = makeAddr("rand");
        vm.startPrank(rand);
        vm.expectRevert(abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)", rand, OPERATOR_ROLE));
        IRewardRedistributor(RR).distribute();
        vm.stopPrank();
        console.log("distribute: OPERATOR_ROLE required");
    }

    function test_P5c_onYield_is_rr_only() public {
        address rand = makeAddr("rand");
        vm.startPrank(rand);
        vm.expectRevert(abi.encodeWithSignature("NotYieldRedistributor()"));
        IEarnVault(VAULT).onYield(1_000_000);
        vm.stopPrank();
        console.log("onYield: NotYieldRedistributor for non-RR caller");
    }

    function test_P5_same_block_snapshot_then_distribute_reverts() public {
        vm.prank(KEEPER);
        IRewardRedistributor(RR).snapshotVaultTVLs();

        vm.prank(KEEPER);
        vm.expectRevert(abi.encodeWithSignature(
            "MustSnapshotInPreviousBlocks(uint256,uint256)", block.number, block.number));
        IRewardRedistributor(RR).distribute();

        // Next block: the keeper's distribute succeeds (proves the guard is precisely one block).
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 2);
        vm.prank(KEEPER);
        IRewardRedistributor(RR).distribute();
        console.log("same-block snapshot+distribute reverts; next-block distribute succeeds");
    }

    /// @dev The v4 singleton really can lend $1M USDSC in one tx at zero protocol fee.
    function test_P6_v4_flashloan_1M_works() public {
        uint256 amount = 1_000_000e6;
        uint256 pmBefore = IERC20(USDSC).balanceOf(POOL_MANAGER);
        assertGe(pmBefore, amount, "PoolManager USDSC depth < $1M");

        uint256 gasBefore = gasleft();
        borrower.flash(amount);
        uint256 gasUsed = gasBefore - gasleft();

        assertEq(IERC20(USDSC).balanceOf(POOL_MANAGER), pmBefore, "PoolManager not repaid");
        assertEq(IERC20(USDSC).balanceOf(address(borrower)), 0, "borrower kept funds");
        console.log("v4 flashloan 1M USDSC OK; PM depth", pmBefore);
        console.log("flashloan round-trip gas", gasUsed);
    }

    function test_P6_v4_flashloan_2M_works() public {
        uint256 amount = 2_000_000e6;
        uint256 pmBefore = IERC20(USDSC).balanceOf(POOL_MANAGER);
        assertGe(pmBefore, amount, "PoolManager USDSC depth < $2M");

        borrower.flash(amount);

        assertEq(IERC20(USDSC).balanceOf(POOL_MANAGER), pmBefore, "PoolManager not repaid");
        assertEq(IERC20(USDSC).balanceOf(address(borrower)), 0, "borrower kept funds");
        console.log("v4 flashloan 2M USDSC OK; PM depth", pmBefore);
    }

    /// @dev Full atomic cycle: flashloan -> deposit -> snapshot -> distribute -> withdraw -> repay.
    ///      Reverts at snapshotVaultTVLs() with AccessControlUnauthorizedAccount; the entire
    ///      transaction (including the flashloan and the deposit) is rolled back.
    function test_P5_atomic_flashloan_cycle_reverts_at_keeper_gate() public {
        uint256 amount = 1_000_000e6;
        uint256 pmBefore = IERC20(USDSC).balanceOf(POOL_MANAGER);
        uint256 vpBefore = IEarnVault(VAULT).totalPrincipal();

        vm.expectRevert(abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)", address(borrower), OPERATOR_ROLE));
        borrower.flashAndAttack(amount);

        assertEq(IERC20(USDSC).balanceOf(POOL_MANAGER), pmBefore, "PM balance changed after revert");
        assertEq(IEarnVault(VAULT).totalPrincipal(), vpBefore, "vault state changed after revert");
        console.log("atomic flashloan JIT cycle reverts at snapshotVaultTVLs (keeper gate)");
    }
}

contract V4FlashBorrower is IUnlockCallback {
    IPoolManager constant PM = IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
    address constant VAULT = 0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0;
    address constant RR = 0xda798684ffD5eb509c2Ab7b8352EC55B31F18201;
    address constant USDSC = 0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a;

    function flash(uint256 amount) external {
        PM.unlock(abi.encode(amount, false));
    }

    function flashAndAttack(uint256 amount) external {
        PM.unlock(abi.encode(amount, true));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(PM), "not PoolManager");
        (uint256 amount, bool attack) = abi.decode(data, (uint256, bool));

        PM.take(USDSC, address(this), amount);

        if (attack) {
            IERC20(USDSC).approve(VAULT, amount);
            IEarnVault(VAULT).deposit(amount);            // succeeds
            IRewardRedistributor(RR).snapshotVaultTVLs(); // reverts: OPERATOR_ROLE
            IRewardRedistributor(RR).distribute();        // unreachable
            IEarnVault(VAULT).withdraw(amount);            // unreachable
        }

        PM.sync(USDSC);
        IERC20(USDSC).transfer(address(PM), amount);
        PM.settle();
        return "";
    }
}
