// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IStakingCore {
    function stake(string calldata communityCode) external payable;
    function exchangeRatio() external view returns (uint256);
    function getTotalProtocolHype() external view returns (uint256);
    function BeHYPEToHYPE(uint256) external view returns (uint256);
    function HYPEToBeHYPE(uint256) external view returns (uint256);
    function paused() external view returns (bool);
}

interface IWithdrawManager {
    struct WithdrawalEntry {
        address user;
        uint256 beHypeAmount;
        uint256 hypeAmount;
        bool claimed;
    }
    function withdraw(uint256 beHypeAmount, bool instant, uint256 minAmountOut) external returns (uint256);
    function claimWithdrawal(uint256 id) external;
    function finalizeWithdrawals(uint256 index) external;
    function canClaimWithdrawal(uint256 id) external view returns (bool);
    function getWithdrawalQueue(uint256) external view returns (WithdrawalEntry memory);
    function lastFinalizedIndex() external view returns (uint256);
    function instantWithdrawalFeeInBps() external view returns (uint16);
    function lowWatermarkInHYPE() external view returns (uint256);
    function getTotalInstantWithdrawableBeHYPE() external view returns (uint256);
}

contract RevertingReceiver {
    IStakingCore public core;
    IWithdrawManager public wm;
    IERC20 public token;

    constructor(IStakingCore _core, IWithdrawManager _wm, IERC20 _token) {
        core = _core;
        wm = _wm;
        token = _token;
    }

    function queue(uint256 beHypeAmount) external returns (uint256) {
        token.approve(address(wm), type(uint256).max);
        return wm.withdraw(beHypeAmount, false, 0);
    }

    receive() external payable {
        revert("no HYPE accepted");
    }
}

contract HyperbeatTest is Test {
    // HyperEVM mainnet (chain 999), pinned at block 49,145,310 (2026-10-21).
    uint256 constant FORK_BLOCK = 49_145_310;
    IStakingCore constant CORE = IStakingCore(0xCeaD893b162D38e714D82d06a7fe0b0dc3c38E0b);
    IWithdrawManager constant WM = IWithdrawManager(0x9d0B0877b9f2204CF414Ca7862E4f03506822538);
    IERC20 constant BEHYPE = IERC20(0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9);
    address constant L1READ = 0xb7467E0524Afba7006957701d1F06A59000d15A2;

    address constant ADMIN = 0xb700d555DDcB806634617f861f01fE8F47aA33Ef; // PROTOCOL_ADMIN holder
    address constant TREASURY = 0xc4bdD45Ff1229146c2c1dc585E66aEb6677cbbf3;
    uint256 constant TREASURY_UNCLAIMED_ID = 2707;
    uint256 constant TREASURY_UNCLAIMED_HYPE = 1156690616997664083801;
    uint256 constant MANAGER_BALANCE = 1621_905798325016362542;

    address attacker = address(0xA77AC4E5);

    function setUp() public {
        vm.createSelectFork(vm.envOr("HYPEREVM_RPC", string("https://rpc.hyperliquid.xyz/evm")), FORK_BLOCK);
        vm.deal(attacker, 10_000 ether);
        // HyperEVM read precompiles are native and absent from the forked EVM state; substitute
        // the *exact* values read from HyperCore at the same block so NAV math is unchanged.
        vm.mockCall(
            L1READ,
            abi.encodeWithSignature("delegatorSummary(address)", address(CORE)),
            abi.encode(uint64(14775998986656), uint64(9329457606), uint64(99668380321), uint64(5))
        );
        vm.mockCall(
            L1READ,
            abi.encodeWithSignature("spotBalance(address,uint64)", address(CORE), uint64(150)),
            abi.encode(uint64(18502354439), uint64(0), uint64(1434455320935))
        );
    }

    /// 1. Stored exchange ratio is BELOW live NAV per share by one un-poked accrual
    ///    period. Quantify the gap and the maximum value it exposes.
    function test_staleRatioGap() public {
        uint256 nav = CORE.getTotalProtocolHype();
        uint256 supply = BEHYPE.totalSupply();
        uint256 ratio = CORE.exchangeRatio();
        uint256 implied = (nav * 1e18) / supply;
        assertLe(ratio, implied, "ratio above NAV (should not happen)");
        uint256 gapBps100 = ((implied - ratio) * 1_000_000) / ratio; // bps x100
        emit log_named_uint("nav wei", nav);
        emit log_named_uint("ratio", ratio);
        emit log_named_uint("nav/supply", implied);
        emit log_named_uint("gap (bps x100)", gapBps100);
        // gap must be small: <= 10 bps (1 day of ~0.58bp accrual)
        assertLe(gapBps100, 1000, "stale gap > 10bps");
        assertEq(CORE.BeHYPEToHYPE(1 ether), ratio, "BeHYPEToHYPE must use stored ratio");
    }

    /// 2. Manager holds exactly the finalized-but-unclaimed liability; largest claim is live.
    function test_queueFullyBacked() public view {
        assertEq(address(WM).balance, MANAGER_BALANCE, "manager balance changed");
        assertEq(WM.lastFinalizedIndex(), 5590, "lastFinalizedIndex changed");
        assertTrue(WM.canClaimWithdrawal(TREASURY_UNCLAIMED_ID), "treasury entry should be claimable");
        IWithdrawManager.WithdrawalEntry memory e = WM.getWithdrawalQueue(TREASURY_UNCLAIMED_ID);
        assertEq(e.user, TREASURY);
        assertEq(e.hypeAmount, TREASURY_UNCLAIMED_HYPE);
        assertLe(e.hypeAmount, address(WM).balance, "liability exceeds balance");
    }

    /// 3. Unprivileged caller cannot run the admin-only finalization step.
    function test_attackerCannotFinalize() public {
        vm.prank(attacker);
        (bool ok, bytes memory ret) =
            address(WM).call(abi.encodeWithSignature("finalizeWithdrawals(uint256)", WM.lastFinalizedIndex() + 1));
        assertFalse(ok, "attacker finalized the queue");
        emit log_named_bytes("revert", ret);
    }

    /// 4. Claiming someone else's entry pays *them*, not the caller.
    function test_claimOtherUserPaysThem() public {
        IWithdrawManager.WithdrawalEntry memory e = WM.getWithdrawalQueue(TREASURY_UNCLAIMED_ID);
        uint256 before = TREASURY.balance;
        uint256 attackerBefore = attacker.balance;
        vm.prank(attacker);
        WM.claimWithdrawal(TREASURY_UNCLAIMED_ID);
        assertEq(TREASURY.balance, before + e.hypeAmount, "victim did not receive funds");
        assertEq(attacker.balance, attackerBefore, "attacker profited");
        assertTrue(WM.getWithdrawalQueue(TREASURY_UNCLAIMED_ID).claimed);
    }

    /// 5. No double claim.
    function test_doubleClaimReverts() public {
        vm.startPrank(attacker);
        WM.claimWithdrawal(TREASURY_UNCLAIMED_ID);
        (bool ok, bytes memory ret) =
            address(WM).call(abi.encodeWithSignature("claimWithdrawal(uint256)", TREASURY_UNCLAIMED_ID));
        vm.stopPrank();
        assertFalse(ok, "double claim succeeded");
        emit log_named_bytes("revert", ret);
    }

    /// 6. The old CRITICAL (reverting receiver bricks finalization) is fixed by the pull pattern.
    function test_revertingReceiverCannotBlockQueue() public {
        RevertingReceiver bad = new RevertingReceiver(CORE, WM, BEHYPE);
        vm.startPrank(attacker);
        CORE.stake{value: 1 ether}("");
        BEHYPE.transfer(address(bad), 0.1 ether);
        vm.stopPrank();

        uint256 id = bad.queue(0.1 ether);
        WM.getWithdrawalQueue(id);
        uint256 wmBefore = address(WM).balance;

        vm.prank(ADMIN);
        WM.finalizeWithdrawals(id); // must NOT revert

        assertEq(WM.lastFinalizedIndex(), id, "queue did not advance");
        assertGt(address(WM).balance, wmBefore, "finalize did not prefund the manager");
        assertTrue(WM.canClaimWithdrawal(id));

        // only the attacker's own claim reverts -> their 0.1 HYPE is self-stuck, queue is unaffected
        vm.prank(address(bad));
        (bool ok,) = address(WM).call(abi.encodeWithSignature("claimWithdrawal(uint256)", id));
        assertFalse(ok, "reverting receiver unexpectedly claimed");
    }

    /// 7. Instant withdrawal roundtrip loses exactly the 30 bps fee - no free value.
    function test_instantWithdrawalRoundtrip() public {
        uint256 amount = 100 ether;
        uint256 before = attacker.balance;
        vm.startPrank(attacker);
        CORE.stake{value: amount}("");
        uint256 shares = BEHYPE.balanceOf(attacker);
        BEHYPE.approve(address(WM), type(uint256).max);
        WM.withdraw(shares, true, 0);
        vm.stopPrank();
        uint256 afterBal = attacker.balance;
        assertLt(afterBal, before, "instant roundtrip profitable?!");
        assertEq(WM.instantWithdrawalFeeInBps(), 30);
        uint256 loss = before - afterBal;
        assertApproxEqRel(loss, (amount * 30) / 10_000, 1e15, "unexpected fee");
        emit log_named_uint("HYPE in", amount);
        emit log_named_uint("HYPE back", afterBal + amount - before);
    }

    /// 8. JIT yield sandwich: break-even needs far more accrued yield than the live cadence.
    function test_jitBreakEvenFarAboveLiveAccrual() public {
        // successive ExchangeRatioUpdated values ~86,600s apart
        uint256 r0 = 0xe31ca7e18c987ea;
        uint256 r1 = 0xe3200ef2c755be7;
        uint256 perDayBps100 = ((r1 - r0) * 10_000 * 100) / r0; // bps x100
        uint256 feeBps100 = 30 * 100;
        uint256 breakEvenDays = perDayBps100 == 0 ? type(uint256).max : feeBps100 / perDayBps100;
        emit log_named_uint("per-day accrual (bps x100)", perDayBps100);
        emit log_named_uint("break-even days", breakEvenDays);
        assertGt(breakEvenDays, 45, "JIT could break even inside 45 days");
    }
}
