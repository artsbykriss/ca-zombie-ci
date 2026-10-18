// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IMotoStaking {
    function stake(uint256 amount, uint8 durationOption) external;
    function appendStake(uint256 amount) external;
    function requestUnstake(uint256 amount) external;
    function claimUnstaked() external returns (uint256);
    function claim(address token) external returns (uint256);
    function claimReward(address account, address token) external returns (uint256);
    function claimTokenSelf(address account, address token) external;
    function pendingReward(address account, address token) external view returns (uint256);
    function effectiveStakeOf(address account) external view returns (uint256);
    function positions(address account) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function available(address account) external view returns (uint256);
    function ticketCount(address account) external view returns (uint256);
    function rewardOwed(address token) external view returns (uint256);
    function claimableStored(address account, address token) external view returns (uint256);
    function totalEffectiveStake() external view returns (uint256);
    function upgradesRenounced() external view returns (bool);
    function owner() external view returns (address);
    function upgradeAuthority() external view returns (address);
}

interface IVampChef {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardTime, uint256 accRewardPerShare, uint256 lpSupply);
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function pendingReward(uint256 pid, address user) external view returns (uint256);
    function depositFor(uint256 pid, uint256 amount, address user) external;
    function harvest(uint256 pid) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function emergencyWithdraw(uint256 pid) external;
    function recoverUndistributedRewards(address to, uint256 amount) external;
    function availableReward() external view returns (uint256);
    function totalCredited() external view returns (uint256);
    function totalHarvested() external view returns (uint256);
    function totalStakedRewardToken() external view returns (uint256);
    function emissionEnd() external view returns (uint64);
}

contract MotoTest is Test {
    address constant MOTO    = 0xBd965230588EAA536dE6aA45E8ebbc01638535e0;
    address constant STAKING = 0xCE88F2C6B49EfBb92555eE5475311f0e250C2528;
    address constant CHEF    = 0x51e648f08a9a08A724591938d9cbc483C809aCA4;
    address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC    = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT    = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant STAKER  = 0x1F6Bc65Eb0668ab152e289c74a4369BC1DF29732;
    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://eth.drpc.org")), 26217377);
        vm.deal(attacker, 100 ether);
        deal(MOTO, attacker, 2_000_001 ether);
        vm.prank(attacker);
        IERC20(MOTO).approve(STAKING, type(uint256).max);
    }

    function _pend(address t) internal view returns (uint256) {
        return IMotoStaking(STAKING).pendingReward(attacker, t);
    }

    function test_stakeDebt_init() public {
        uint256 p0w = _pend(WETH);
        uint256 p0m = _pend(MOTO);
        emit log_named_uint("pending WETH before stake", p0w);
        emit log_named_uint("pending MOTO before stake", p0m);

        vm.prank(attacker);
        IMotoStaking(STAKING).stake(1_000 ether, 0);
        uint256 p1w = _pend(WETH);
        uint256 p1m = _pend(MOTO);
        emit log_named_uint("pending WETH after 1k stake", p1w);
        emit log_named_uint("pending MOTO after 1k stake", p1m);

        vm.prank(attacker);
        IMotoStaking(STAKING).appendStake(1_000_000 ether);
        uint256 p2w = _pend(WETH);
        uint256 p2m = _pend(MOTO);
        emit log_named_uint("pending WETH after 1M append", p2w);
        emit log_named_uint("pending MOTO after 1M append", p2m);

        (uint256 amt,,,,,,) = IMotoStaking(STAKING).positions(attacker);
        emit log_named_uint("position amount", amt);
        emit log_named_uint("effective", IMotoStaking(STAKING).effectiveStakeOf(attacker));

        uint256 balBefore = IERC20(WETH).balanceOf(attacker);
        vm.prank(attacker);
        uint256 claimed = IMotoStaking(STAKING).claim(WETH);
        uint256 got = IERC20(WETH).balanceOf(attacker) - balBefore;
        emit log_named_uint("WETH claimed return", claimed);
        emit log_named_uint("WETH actually received", got);

        // A new staker must never be able to claim rewards accrued before it staked.
        assertEq(p1w, 0, "retroactive WETH on stake");
        assertEq(p1m, 0, "retroactive MOTO on stake");
    }

    function test_appendStake_noRetroactive() public {
        vm.startPrank(attacker);
        IMotoStaking(STAKING).stake(1_000 ether, 0);
        uint256 beforeW = _pend(WETH);
        IMotoStaking(STAKING).appendStake(1_000_000 ether);
        uint256 afterW = _pend(WETH);
        vm.stopPrank();
        emit log_named_uint("pending WETH before append", beforeW);
        emit log_named_uint("pending WETH after append", afterW);
        assertEq(afterW, beforeW, "appendStake granted retroactive WETH");
    }

    function test_claimPaths_selfOnly() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IMotoStaking(STAKING).claimReward(STAKER, WETH);
        vm.expectRevert();
        IMotoStaking(STAKING).claimTokenSelf(STAKER, WETH);
        vm.stopPrank();
    }

    function test_requestUnstake_drip() public {
        vm.startPrank(attacker);
        IMotoStaking(STAKING).stake(1_000 ether, 0);
        uint256 avail = IMotoStaking(STAKING).available(attacker);
        emit log_named_uint("available after stake", avail);
        if (avail > 0) {
            IMotoStaking(STAKING).requestUnstake(avail);
            uint256 got = IMotoStaking(STAKING).claimUnstaked();
            emit log_named_uint("claimUnstaked immediately", got);
            emit log_named_uint("ticketCount", IMotoStaking(STAKING).ticketCount(attacker));
        }
        vm.stopPrank();
    }

    function test_vampChef_publicPaths() public {
        uint256 n = IVampChef(CHEF).poolLength();
        emit log_named_uint("vamp poolLength", n);
        uint256 motoPid = type(uint256).max;
        for (uint256 i = 0; i < n; i++) {
            (address lp,,,,) = IVampChef(CHEF).poolInfo(i);
            if (lp == MOTO) motoPid = i;
        }
        emit log_named_uint("MOTO pool pid", motoPid);
        require(motoPid != type(uint256).max, "no MOTO pool");

        vm.startPrank(attacker);
        // zero-amount harvest by a non-staker must not pay anything
        IVampChef(CHEF).harvest(motoPid);
        uint256 bal0 = IERC20(MOTO).balanceOf(attacker);
        emit log_named_uint("attacker MOTO after harvest", bal0);
        // emergencyWithdraw with no position must not move tokens
        IVampChef(CHEF).emergencyWithdraw(motoPid);
        emit log_named_uint("attacker MOTO after emergency", IERC20(MOTO).balanceOf(attacker));
        // withdraw more than staked must revert
        vm.expectRevert();
        IVampChef(CHEF).withdraw(motoPid, 1);
        // onlyOwner sweep must revert
        vm.expectRevert();
        IVampChef(CHEF).recoverUndistributedRewards(attacker, 1);
        vm.stopPrank();

        (uint256 staked, uint256 debt) = IVampChef(CHEF).userInfo(motoPid, STAKER);
        emit log_named_uint("staker amount in MOTO pool", staked);
        emit log_named_uint("staker rewardDebt", debt);
        emit log_named_uint("staker pending", IVampChef(CHEF).pendingReward(motoPid, STAKER));
        emit log_named_uint("chef availableReward", IVampChef(CHEF).availableReward());
        emit log_named_uint("chef totalCredited", IVampChef(CHEF).totalCredited());
        emit log_named_uint("chef totalHarvested", IVampChef(CHEF).totalHarvested());
        emit log_named_uint("chef totalStakedRewardToken", IVampChef(CHEF).totalStakedRewardToken());
    }

    function test_rewardTokenSupplySurplus() public {
        emit log_named_uint("staking MOTO balance", IERC20(MOTO).balanceOf(STAKING));
        emit log_named_uint("totalEffectiveStake", IMotoStaking(STAKING).totalEffectiveStake());
        emit log_named_uint("rewardOwed MOTO", IMotoStaking(STAKING).rewardOwed(MOTO));
        emit log_named_uint("rewardOwed WETH", IMotoStaking(STAKING).rewardOwed(WETH));
        emit log_named_uint("upgradeAuthority", uint160(IMotoStaking(STAKING).upgradeAuthority()));
        emit log_named_uint("owner", uint160(IMotoStaking(STAKING).owner()));
        emit log_named_uint("upgradesRenounced", IMotoStaking(STAKING).upgradesRenounced() ? 1 : 0);
    }
}
