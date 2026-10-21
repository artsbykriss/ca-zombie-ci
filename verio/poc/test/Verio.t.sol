// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IStakePool,
    IWithdrawalPool,
    IVerioIP,
    IDelegator,
    IComponentSelector,
    IInsurancePool,
    IRewardPool
} from "../src/Interfaces.sol";

/// @notice Read-only fork checks for the Verio vIP / StakePool / WithdrawalPool ledger.
///         No mainnet transaction is ever signed; everything runs on an anvil fork.
contract VerioTest is Test {
    // --- live Story mainnet addresses (chain id 1514) ---
    address constant SP = 0xf6701A6A20639f0E765bA7FF66FD4f49815F1a27; // StakePool proxy
    address constant WP = 0x2a7935E926C65Ef2671D5807760e2421adf992d8; // WithdrawalPool proxy
    address constant VIP = 0x5267F7eE069CEB3D8F1c760c215569b79d0685aD; // vIP proxy
    address constant DEL = 0xB47Aedf533cc3c1651a8Af2312Fe55e317006821; // Delegator proxy
    address constant SEL = 0x20Cb9DCb6FC306c31325bdA6221AA5e067B9Da51; // ComponentSelector proxy
    address constant INS = 0x22dF4eF4Ebe13755Dcb719945596F94A72C8Ebc4; // WithdrawalPool InsurancePool
    address constant RP = 0x3bDcB577C21a36f66816bE3D5d8C311419EC3975; // RewardPool proxy
    address constant OWNER = 0x0f0172E30795958dA86f068F80A1743Df1955e16; // EOA owner of all components

    // StakePoolState is at the ERC-7201 slot; excessUnstake is field #9.
    bytes32 constant SP_STATE = 0xe41b22deefae2f9a6392ef27a1127c46110b60ec2d4f6d998d8b7863795f6700;
    bytes32 constant E_SLOT = 0xe41b22deefae2f9a6392ef27a1127c46110b60ec2d4f6d998d8b7863795f6709;

    // 0x14a6bf0f is the insurance pool's "remaining capacity" getter (selector recovered by trace).
    bytes4 constant INS_CAPACITY = 0x14a6bf0f;

    function setUp() public {
        vm.createSelectFork(vm.envOr("STORY_RPC_URL", string("https://mainnet.storyrpc.io")));
        console2.log("fork block", block.number);
    }

    // ---------------------------------------------------------------- 1
    function test_ledgerIdentity() public {
        uint256 D = IDelegator(DEL).getGlobalDistributionTotal();
        uint256 E = IStakePool(SP).getUnstaked();
        uint256 P = IStakePool(SP).getPendingUnstake();
        uint256 TS = IStakePool(SP).getTotalStake();
        uint256 B = SP.balance;
        uint256 S = IVerioIP(VIP).totalSupply();
        uint256 S2 = IVerioIP(VIP).getTotalSupply();

        console2.log("D (delegator total)", D);
        console2.log("E (excessUnstake)", E);
        console2.log("P (pendingUnstake)", P);
        console2.log("TS (getTotalStake)", TS);
        console2.log("B (stake pool balance)", B);
        console2.log("NAV = TS + B", TS + B);
        console2.log("vIP supply", S);
        console2.log("rate IP/vIP x1e18", (TS + B) * 1e18 / S);
        console2.log("WP pending withdrawals", IWithdrawalPool(WP).getTotalPendingWithdrawals());
        console2.log("WP balance", WP.balance);

        // exact ledger identity from StakePool._getTotalStake()
        assertEq(TS, D + E - P, "TS != D + E - P");
        assertEq(S, S2, "totalSupply != getTotalSupply");
        // the live pool has no excess unstake at this state
        console2.log("E is zero:", E == 0);
    }

    // ---------------------------------------------------------------- 2
    /// @notice handleBalance() sends only the true surplus to the WithdrawalPool
    ///         InsurancePool. It never sends IP to the StakePool.
    function test_handleBalance_goesToInsurancePool_notStakePool() public {
        uint256 Pw = IWithdrawalPool(WP).getTotalPendingWithdrawals();
        uint256 E = IStakePool(SP).getUnstaked();
        uint256 cap = _capacity();
        uint256 surplus = 5_000e18;
        if (cap < surplus) surplus = cap;

        vm.deal(WP, Pw + E + 5_000e18);
        uint256 insBefore = INS.balance;
        uint256 spBefore = SP.balance;

        vm.prank(SP);
        IWithdrawalPool(WP).handleBalance();

        console2.log("surplus sent to insurance", surplus);
        console2.log("insurance delta", INS.balance - insBefore);

        assertEq(INS.balance, insBefore + surplus, "insurance funding mismatch");
        assertEq(WP.balance, Pw + E + (5_000e18 - surplus), "WP retention mismatch");
        assertEq(SP.balance, spBefore, "StakePool balance must not change");
    }

    // ---------------------------------------------------------------- 3
    /// @notice handleBalance() reserves stakePool.getUnstaked() (excessUnstake) in the
    ///         WithdrawalPool before computing the surplus, so E is not double counted.
    function test_handleBalance_reservesExcessUnstake() public {
        uint256 E = 1_000e18;
        vm.store(SP, E_SLOT, bytes32(E));
        assertEq(IStakePool(SP).getUnstaked(), E, "store failed");

        uint256 Pw = IWithdrawalPool(WP).getTotalPendingWithdrawals();
        uint256 cap = _capacity();
        uint256 pot = 2_000e18;
        uint256 surplus = pot;
        if (cap < surplus) surplus = cap;

        vm.deal(WP, Pw + E + pot);
        uint256 insBefore = INS.balance;
        uint256 spBefore = SP.balance;

        vm.prank(SP);
        IWithdrawalPool(WP).handleBalance();

        console2.log("E reserved in WP", E);
        console2.log("surplus sent to insurance", surplus);
        assertEq(INS.balance, insBefore + surplus, "insurance funding mismatch");
        assertEq(WP.balance, Pw + E + (pot - surplus), "WP must retain Pw + E");
        assertEq(SP.balance, spBefore, "StakePool balance must not change");
    }

    // ---------------------------------------------------------------- 4
    /// @notice Full permissionless stake -> unstake -> simulated unbonding arrival.
    ///         The unbonded IP lands in the WithdrawalPool (precompile withdrawal
    ///         address == WP), never in the StakePool, so address(this).balance in
    ///         the StakePool never contains pending-withdrawal IP.
    function test_realUnstake_noStakePoolCredit() public {
        uint256 amount = 3_000e18;
        vm.deal(address(this), amount);
        IStakePool(SP).stake{value: amount}(false);

        uint256 v = IVerioIP(VIP).balanceOf(address(this));
        assertGt(v, 0, "no vIP minted");
        console2.log("vIP minted for 3000 IP", v);

        uint256 wpBefore = WP.balance;
        uint256 pwBefore = IWithdrawalPool(WP).getTotalPendingWithdrawals();
        IStakePool(SP).unstake(v);

        uint256 pwAfter = IWithdrawalPool(WP).getTotalPendingWithdrawals();
        uint256 claim = pwAfter - pwBefore;
        assertGt(claim, 0, "no withdrawal recorded");
        console2.log("withdrawal claim (IP)", claim);
        console2.log("excessUnstake after unstake", IStakePool(SP).getUnstaked());

        // Simulate the 16-day unbonding settlement: the precompile sends exactly the
        // claim amount to the WP (its configured withdrawal address).
        vm.deal(WP, wpBefore + claim);

        uint256 tsBefore = IStakePool(SP).getTotalStake();
        uint256 spBefore = SP.balance;
        uint256 insBefore = INS.balance;

        vm.prank(SP);
        IWithdrawalPool(WP).handleBalance();

        assertEq(SP.balance, spBefore, "StakePool must not receive unbonded IP");
        assertEq(IStakePool(SP).getTotalStake(), tsBefore, "TS must not change");
        // The claim is below the outstanding liability, so the WP keeps it and
        // nothing is forwarded to the insurance pool.
        assertEq(WP.balance, wpBefore + claim, "WP must retain the unbonded claim");
        assertEq(INS.balance, insBefore, "no surplus should be forwarded");
    }

    // ---------------------------------------------------------------- 5
    function test_gating() public {
        vm.expectRevert();
        IWithdrawalPool(WP).addWithdrawal(address(this), 1, 1);

        vm.expectRevert();
        IWithdrawalPool(WP).handleBalance();

        vm.expectRevert();
        IWithdrawalPool(WP).withdraw();

        vm.expectRevert();
        IVerioIP(VIP).mint(address(this), 1e18);

        address holder = 0xc8C554a3f5aDc516d6e0c4eb6b3CAc02c40C7adf;
        vm.expectRevert();
        IVerioIP(VIP).burn(holder, 1e18);

        vm.expectRevert();
        IInsurancePool(INS).claim(1);

        vm.expectRevert();
        IRewardPool(RP).claimRewards();
    }

    // ---------------------------------------------------------------- 6
    function test_roundtripAndFees() public {
        uint256 shares = IStakePool(SP).calculateVIPMint(1e18);
        uint256 back = IStakePool(SP).calculateIPWithdrawal(shares);
        console2.log("1 IP -> vIP", shares);
        console2.log("vIP -> IP", back);
        assertLe(back, 1e18, "roundtrip must not profit");
        assertGe(back, 1e18 - 10, "unexpected rounding loss");

        console2.log("burnFeeBps", IStakePool(SP).getBurnFeeBps());
        console2.log("burnFeeEnabled", IStakePool(SP).getBurnFeeEnabled());
        console2.log("mintFeeBps", IStakePool(SP).getMintFeeBps());
        assertEq(IStakePool(SP).getBurnFeeBps(), 10);
        assertTrue(IStakePool(SP).getBurnFeeEnabled());
        assertEq(IStakePool(SP).getMintFeeBps(), 0);
    }

    // ---------------------------------------------------------------- 7
    function test_donationUnprofitable() public {
        uint256 v = 1_000e18; // fixed vIP amount
        uint256 before = IStakePool(SP).calculateIPWithdrawal(v);
        uint256 donation = 10_000e18;
        vm.deal(address(this), donation);
        IStakePool(SP).fund{value: donation}();
        uint256 afterGain = IStakePool(SP).calculateIPWithdrawal(v) - before;

        console2.log("redemption value gain for 1000 vIP", afterGain);
        // the donor only recovers its pro-rata share of the donation
        assertLt(afterGain, donation, "donation must not be profitable");
    }

    // ---------------------------------------------------------------- 8
    /// @notice P-class check (not E-U): the EOA owner can replace the 300 s timelock
    ///         admin with itself and retarget the ComponentSelector, including the
    ///         withdrawal pool that receives the Delegator's unbonded IP.
    function test_P_ownerCanBypassTimelock() public {
        assertEq(IComponentSelector(SEL).owner(), OWNER);
        assertEq(IComponentSelector(SEL).getAdmin() != OWNER, true);

        vm.prank(OWNER);
        IComponentSelector(SEL).setAdmin(OWNER);
        assertEq(IComponentSelector(SEL).getAdmin(), OWNER);

        MaliciousComponent m = new MaliciousComponent();
        vm.prank(OWNER);
        IComponentSelector(SEL).setWithdrawalPool(address(m));
        assertEq(IComponentSelector(SEL).withdrawalPool(), address(m));

        MaliciousComponent m2 = new MaliciousComponent();
        vm.prank(OWNER);
        IComponentSelector(SEL).setStakePool(address(m2));
        assertEq(IComponentSelector(SEL).stakePool(), address(m2));

        vm.prank(OWNER);
        IDelegator(DEL).setAdmin(OWNER);
        assertEq(IDelegator(DEL).getAdmin(), OWNER);

        // This sets the Story staking precompile's withdrawal address to
        // selector.withdrawalPool() == m (the attacker contract).
        vm.prank(OWNER);
        IDelegator(DEL).setWithdrawalAddress();
    }

    // ---------------------------------------------------------------- helpers
    function _capacity() internal view returns (uint256 cap) {
        (bool ok, bytes memory ret) = INS.staticcall(abi.encodeWithSelector(INS_CAPACITY));
        if (ok && ret.length >= 32) cap = abi.decode(ret, (uint256));
    }
}

contract MaliciousComponent {
    function getVersion() external pure returns (string memory) {
        return "v999.0.0";
    }

    receive() external payable {}
}
