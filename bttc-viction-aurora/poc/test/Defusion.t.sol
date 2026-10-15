// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/// Minimal interfaces (hand-rolled; selectors verified on-chain)
interface IMaster {
    function mintLpToken(address, uint256) external;
    function burnLpToken(address, uint256) external;
    function setImplement(address) external;
    function setProtocolFee(uint256) external;
    function setAdmins(address[] calldata, bool[] calldata) external;
    function unlock(bytes4) external;
    function isPool(address) external view returns (bool);
    function sVic() external view returns (address);
    function validator() external view returns (address);
    function getImplement() external view returns (address);
    function isUnlock(bytes4) external view returns (bool);
    function allPools(uint256) external view returns (address);
}

interface IPool {
    function stake() external payable;
    function unstake(uint256) external;
    function withdrawUnstakedAmount() external;
    function withdrawUnstakedAmount(uint256) external;
    function withdrawReward() external;
    function withdrawAfterResign() external;
    function voteForResign(bool) external;
    function users(address) external view returns (uint256 capacity, uint256 rewardDebt);
    function lpLocked(address) external view returns (uint256);
    function poolStatus() external view returns (uint8);
    function totalCapacity() external view returns (uint256);
    function lastBalance() external view returns (uint256);
    function accRewardPerShare() external view returns (uint256);
    function currentStakerReward(address) external view returns (uint256);
    function getWithdrawBlockNumbers(address) external view returns (uint256[] memory);
    function currentWithdrawIndex() external view returns (uint256);
    function owner() external view returns (address);
    function resignBlock() external view returns (uint256);
}

interface ISVIC {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function setMinter(address, bool) external;
    function issuer() external view returns (address);
}

/// @title deFusion LSD (Viction) — adversarial fork tests
/// @notice Read-only mainnet; forks only. Proves gates + 1:1 round trip.
contract DefusionTest is Test {
    // ---- live addresses (verified 2026-10-15) ----
    address constant MASTER = 0x56a04beEE463CbaBEB6d3B67F634B6A4F5f52eB0;
    address constant SVIC = 0xCdde1f5D971A369eB952192F9a5C367f33a0A891;
    address constant POOL_S1 = 0x5045401be9d9c9fFA7De5c32028605B094168F02; // "Kuang Si Falls Pool", status 1, cap 219,687.98
    address constant RESIGNED = 0x5a52e2a9027a95C96a0212c496Ab11E15d55FC79; // status 2, 6,738 VIC
    address constant VALIDATOR = 0x0000000000000000000000000000000000000088;
    address constant STAKER = 0xd66E7E27CAdc258c1830F681D6ddC014281aE847; // capacity 33,333 on S1
    address constant ATTACKER = address(0xA77ACCE7);

    bool forked;

    function setUp() public {
        string[3] memory urls = [
            vm.envOr("VICTION_RPC_URL", string("https://viction.drpc.org")),
            "https://rpc.viction.xyz",
            "https://viction.drpc.org"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) {
                forked = true;
                break;
            } catch {}
        }
    }

    modifier onlyFork() {
        if (!forked) {
            console2.log("SKIP: viction fork unavailable");
            return;
        }
        _;
    }

    // ---------------------------------------------------------------- gates
    function test_01_mint_burn_pool_gated() public onlyFork {
        // attacker cannot mint/burn SVIC via the Master (pool-gated)
        vm.startPrank(ATTACKER);
        vm.expectRevert(bytes("Factory: sender is not a pool"));
        IMaster(MASTER).mintLpToken(ATTACKER, 1e18);
        vm.expectRevert(bytes("Factory: sender is not a pool"));
        IMaster(MASTER).burnLpToken(ATTACKER, 1e18);
        vm.stopPrank();
        // attacker cannot mint on the token either
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Only from minter"));
        ISVIC(SVIC).mint(ATTACKER, 1e18);
        // the OWNER (issuer EOA) CAN mint unbacked SVIC -> privileged (P) risk, not E-U
        uint256 before = ISVIC(SVIC).balanceOf(ATTACKER);
        vm.prank(0x433bAf6C9DAb45201D53fB99b88392c0bb20DB3f);
        ISVIC(SVIC).mint(ATTACKER, 1e18);
        assertEq(ISVIC(SVIC).balanceOf(ATTACKER) - before, 1e18, "owner is a minter (P risk)");
    }

    function test_02_master_admin_gated() public onlyFork {
        vm.startPrank(ATTACKER);
        vm.expectRevert(bytes("VRC25: caller is not the owner"));
        IMaster(MASTER).setImplement(ATTACKER);
        vm.expectRevert(bytes("VRC25: caller is not the owner"));
        IMaster(MASTER).setProtocolFee(1);
        vm.expectRevert(bytes("VRC25: caller is not the owner"));
        IMaster(MASTER).unlock(bytes4(0xfb43eb3e));
        address[] memory a = new address[](1);
        bool[] memory b = new bool[](1);
        a[0] = ATTACKER;
        b[0] = true;
        vm.expectRevert(bytes("VRC25: caller is not the owner"));
        IMaster(MASTER).setAdmins(a, b);
        vm.stopPrank();
        assertFalse(IMaster(MASTER).isUnlock(bytes4(0xfb43eb3e)), "mintLpToken must not be unlocked");
        assertEq(IMaster(MASTER).getImplement(), 0x90f78350838229a40478Cc0d4164bB58905d943b, "impl");
    }

    function test_03_pool_payouts_require_staker() public onlyFork {
        vm.startPrank(ATTACKER);
        vm.expectRevert(bytes("deFusionPool: Caller is not a staker"));
        IPool(POOL_S1).unstake(1e18);
        vm.expectRevert(bytes("deFusionPool: Caller is not a staker"));
        IPool(POOL_S1).withdrawReward();
        vm.expectRevert(bytes("deFusionPool: No unstaked data"));
        IPool(POOL_S1).withdrawUnstakedAmount();
        vm.expectRevert(bytes("deFusionPool: No withdraw cap"));
        IPool(POOL_S1).withdrawUnstakedAmount(block.number - 1);
        vm.expectRevert(bytes("deFusionPool: Caller is not a staker"));
        IPool(POOL_S1).voteForResign(true);
        // resigned pool: same gates
        vm.expectRevert(bytes("deFusionPool: Caller is not a staker"));
        IPool(RESIGNED).withdrawAfterResign();
        vm.expectRevert(bytes("deFusionPool: No unstaked data"));
        IPool(RESIGNED).withdrawUnstakedAmount();
        vm.stopPrank();
        assertGt(POOL_S1.balance, 0, "pool holds liquid VIC (state readable)");
        assertEq(IPool(POOL_S1).poolStatus(), 1, "S1 active");
        assertEq(IPool(RESIGNED).poolStatus(), 2, "resigned");
    }

    /// @dev unstake checks BOTH capacity (per-pool) and SVIC allowance/balance
    function test_04_unstake_needs_capacity_and_allowance() public onlyFork {
        // real staker, no allowance -> capacity ok, allowance fails
        vm.prank(STAKER);
        vm.expectRevert(bytes("VRC25: amount exeeds allowance"));
        IPool(POOL_S1).unstake(1e18);
        // amount above capacity -> capacity check fires first
        vm.prank(STAKER);
        vm.expectRevert(bytes("deFusionPool: Insufficient amount to withdraw"));
        IPool(POOL_S1).unstake(1e24);
        // attacker with SVIC but no capacity anywhere cannot unstake
        deal(SVIC, ATTACKER, 1000e18);
        vm.startPrank(ATTACKER);
        ISVIC(SVIC).approve(MASTER, type(uint256).max);
        vm.expectRevert(bytes("deFusionPool: Caller is not a staker"));
        IPool(POOL_S1).unstake(1000e18);
        vm.stopPrank();
    }

    /// @dev 1:1 round trip: stake -> SVIC 1:1 -> unstake -> withdraw after delay
    function test_05_roundtrip_is_one_to_one() public onlyFork {
        uint256 capBefore = IPool(POOL_S1).totalCapacity();
        uint256 sBefore = ISVIC(SVIC).totalSupply();
        uint256 balBefore = ATTACKER.balance;

        // stake 100 VIC
        vm.deal(ATTACKER, 100 ether);
        vm.prank(ATTACKER);
        IPool(POOL_S1).stake{value: 100 ether}();

        uint256 svicMinted = ISVIC(SVIC).balanceOf(ATTACKER);
        assertEq(svicMinted, 100e18, "SVIC minted must equal VIC deposited (1:1)");
        assertEq(ISVIC(SVIC).totalSupply() - sBefore, 100e18, "supply delta 1:1");
        assertEq(IPool(POOL_S1).totalCapacity() - capBefore, 100e18, "capacity delta");
        assertEq(ATTACKER.balance, 0, "all VIC forwarded to validator");

        // unstake 100 (approve first)
        vm.startPrank(ATTACKER);
        ISVIC(SVIC).approve(MASTER, 100e18);
        ISVIC(SVIC).approve(POOL_S1, 100e18);
        IPool(POOL_S1).unstake(100e18);
        vm.stopPrank();
        assertEq(ISVIC(SVIC).balanceOf(ATTACKER), 0, "SVIC burned on unstake");

        uint256[] memory blocks = IPool(POOL_S1).getWithdrawBlockNumbers(ATTACKER);
        assertGt(blocks.length, 0, "queue entry recorded");
        console2.log("queued withdraw block:", blocks[0]);

        // validator voter withdraw delay = 86,400 blocks (~2 days)
        vm.roll(blocks[0] + 86_401);

        uint256 before = ATTACKER.balance;
        vm.prank(ATTACKER);
        IPool(POOL_S1).withdrawUnstakedAmount();
        uint256 got = ATTACKER.balance - before;
        console2.log("withdrawn (wei):", got);
        // principal returned 1:1 (no protocol fee on principal)
        assertEq(got, 100e18, "round trip must return exactly the deposited VIC");
        // pool's own SPOOL balance (unused ERC20) remains zero
        assertEq(ISVIC(SVIC).balanceOf(ATTACKER), 0, "no extra SVIC claim");
    }

    /// @dev reward accounting is MasterChef-style: pending = cap*acc/1e18 - debt
    function test_06_reward_math_is_debt_based() public onlyFork {
        (uint256 cap, uint256 debt) = IPool(POOL_S1).users(STAKER);
        uint256 acc = IPool(POOL_S1).accRewardPerShare();
        uint256 pending = IPool(POOL_S1).currentStakerReward(STAKER);
        assertGt(cap, 0, "staker has capacity");
        assertEq(cap * acc / 1e18 - debt, pending, "pending == cap*acc/PRECISION - debt");
        // pool's liquid balance covers at most small pending rewards; principal sits in validator
        uint256 poolBal = POOL_S1.balance;
        uint256 capTotal = IPool(POOL_S1).totalCapacity();
        assertLt(poolBal, capTotal, "principal is NOT in the pool (staked in validator)");
    }

    /// @dev totals: SVIC supply is backed ~1:1 by pool capacities
    function test_07_backing_ratio() public onlyFork {
        uint256 supply = ISVIC(SVIC).totalSupply();
        uint256 capSum = 0;
        // sample 20 pools (full 111-pool enumeration is in analysis/defusion_pool_states.json)
        for (uint256 i = 0; i < 20; i++) {
            address p = IMaster(MASTER).allPools(i);
            if (p == address(0)) break;
            capSum += IPool(p).totalCapacity();
        }
        console2.log("SVIC supply:", supply);
        console2.log("sum capacity (20 pools):", capSum);
        assertGt(capSum, 0, "capacities readable");
        // 20 sampled pools carry a large share of the supply; ratio must be same order of magnitude
        assertLt(capSum, supply, "capacities cannot exceed supply materially");
        assertGt(capSum, supply / 10, "sampled capacities must back a large share");
    }
}
