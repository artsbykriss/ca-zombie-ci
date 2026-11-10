// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

interface IStPROS {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function oracle() external view returns (address);
    function slp() external view returns (address);
    function bridgeVault() external view returns (address);
    function queuedWithdrawal() external view returns (uint256);
    function completedWithdrawal() external view returns (uint256);
    function getTotalBalance() external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function depositWithPROS() external payable returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function withdrawComplete(address receiver) external returns (uint256);
    function withdrawComplete() external returns (uint256);
    function previewRedeem(uint256) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function maxWithdrawCount() external view returns (uint256);
    function unbondingPeriod() external view returns (uint256);
}

interface IOracle {
    function poolInfo(address) external view returns (uint256, uint256);
    function slp() external view returns (address);
    function update(address, uint256) external;
    function onMint(address, uint256, uint256) external;
    function setTokenAmount(address, uint256, uint256) external;
    function paused() external view returns (bool);
}

interface IBridge {
    function weth() external view returns (address);
    function vTokenAddresses(address) external view returns (bool);
    function vTokenByAsset(address) external view returns (address);
    function vTokenAddressCount() external view returns (uint256);
    function getBalance(address) external view returns (uint256);
    function withdrawToken(address, address, uint256) external;
    function withdrawTokenWrapped(address, uint256) external;
    function emergencyWithdraw(address, address, uint256) external;
    function unwrapWrapped() external;
    function paused() external view returns (bool);
}

interface IDistributor {
    struct Distribution {
        address slp;
        uint256 amount;
    }
    function keeper() external view returns (address);
    function distribute(Distribution[] calldata) external;
    function paused() external view returns (bool);
}

interface IRewardsVault {
    function notifyOracle() external;
}

interface ISlp {
    function bond(bytes32, uint256) external;
    function claim(bytes32) external;
    function transferBack(uint256) external;
}

interface IStaking {
    function claimReward(bytes32) external returns (uint256);
    function claimStake(bytes32) external returns (uint256);
}

/// @title Faroo stPROS live-gate PoC
/// @notice Read-only verification on a Pharos mainnet fork. No transaction is signed or broadcast.
contract FarooGateTest is Test {
    address constant STPROS = 0x6b0A44c64190279f7034b77c13a566E914FE5Ec4;
    address constant ORACLE = 0x051713fD66845a13BF23BACa008C5C22C27Ccb58;
    address constant BRIDGE = 0xF1dF1CB080256f48e8702c24149136E4A6dec25E;
    address constant DISTRIBUTOR = 0xf772B375f93650F798Bf724cE7A9a45c9e7a579F;
    address constant REWARDS_VAULT = 0xd0C44d3079e97fF285dd7A3e4E0246320a9487e5;
    address constant SLP1 = 0xEC1d6163e05B3F5D0FB8F354881F6c8B793ad612;
    address constant WPROS = 0x52C48d4213107b20bC583832b0d951FB9CA8F0B0;
    address constant STAKING = 0x4100000000000000000000000000000000000000;
    address constant STPROS_IMPL = address(uint160(0x00fD59860894E01773e9780B0d1DFAE4cA2B56708D));
    address constant BRIDGE_IMPL = 0xa7d36cB9dA47bA5123F9070FbA4bb5239C58387e;
    address constant DISTRIBUTOR_IMPL = 0x05A224A9cdD84CfCa21866aE50Fa0cD663e3752f;

    address attacker = address(0x1111111111111111111111111111111111111111);

    IStPROS stpros = IStPROS(STPROS);
    IOracle oracle = IOracle(ORACLE);
    IBridge bridge = IBridge(BRIDGE);
    IDistributor distributor = IDistributor(DISTRIBUTOR);

    uint256 forkBlock;

    function setUp() public {
        // Foundry 1.8 speaks eth_getAccountInfo + block-object params, which the Pharos
        // public RPC rejects; the executable proof is ci/run.sh (eth_call at a pinned block).
        // Set PHAROS_FORK=1 on a standard-EVM Pharos RPC to run this harness.
        if (vm.envOr("PHAROS_FORK", uint256(0)) == 0) {
            vm.skip(true);
            return;
        }
        string memory rpc = vm.envOr("PHAROS_RPC_URL", string("https://rpc.pharos.xyz"));
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        vm.label(STPROS, "stPROS");
        vm.label(ORACLE, "Oracle");
        vm.label(BRIDGE, "BridgeVault");
        vm.label(DISTRIBUTOR, "SlpDistributor");
        vm.label(REWARDS_VAULT, "RewardsVault");
        vm.label(SLP1, "SLP1");
    }

    // ---------------------------------------------------------------- integrity
    function test_code_hashes_match_recorded_runtime() public view {
        // runtimeKeccak values recorded in faroo-xyz/stpros-contracts deployments/mainnet/v4
        assertEq(keccak256(STPROS_IMPL.code), 0xca97539e8a29b612d5a8dedece1b2c2bcec88905e28ce7f79bfa7fff4647e218, "stPROS impl");
        assertEq(keccak256(BRIDGE_IMPL.code), 0x1d9038d2fc9717b44647638e40ee889b4f955f25677cfd260c15257c7cc5a043, "BridgeVault impl");
        assertEq(keccak256(DISTRIBUTOR_IMPL.code), 0xfa824dff1ca8b0ddf019240f571d425034c95f04739ead2e8327907ee5cf577a, "SlpDistributor impl");
    }

    function test_live_topology() public view {
        assertEq(stpros.asset(), WPROS);
        assertEq(stpros.oracle(), ORACLE);
        assertEq(stpros.slp(), DISTRIBUTOR);
        assertEq(stpros.bridgeVault(), BRIDGE);
        assertEq(oracle.slp(), REWARDS_VAULT);
        assertEq(bridge.weth(), WPROS);
        assertEq(bridge.vTokenByAsset(WPROS), STPROS);
        assertEq(bridge.vTokenAddressCount(), 1);
        assertTrue(bridge.vTokenAddresses(STPROS));
        assertFalse(stpros.paused());
        assertFalse(bridge.paused());
        assertFalse(distributor.paused());
        assertFalse(oracle.paused());
        assertEq(distributor.keeper(), 0x8736e68f37C1156e09445ac2D395A139e58fCAb4);
        (uint256 t, uint256 v) = oracle.poolInfo(WPROS);
        assertEq(t, stpros.totalAssets(), "oracle T == totalAssets");
        assertEq(v, stpros.totalSupply(), "oracle V == totalSupply");
        assertGt(t, 0);
        console2.log("block", forkBlock);
        console2.log("totalAssets (PROS)", t);
        console2.log("totalSupply (stPROS)", v);
        console2.log("bridge native (PROS)", BRIDGE.balance);
        console2.log("queuedWithdrawal", stpros.queuedWithdrawal());
        console2.log("getTotalBalance", stpros.getTotalBalance());
    }

    // ---------------------------------------------------------------- gates
    function test_bridge_withdraw_is_vtoken_only() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotVTokenContract(address)")), attacker));
        vm.prank(attacker);
        bridge.withdrawToken(WPROS, attacker, 1);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotVTokenContract(address)")), attacker));
        vm.prank(attacker);
        bridge.withdrawTokenWrapped(attacker, 1);
    }

    function test_bridge_emergency_withdraw_is_owner_only() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("OwnableUnauthorizedAccount(address)")), attacker));
        vm.prank(attacker);
        bridge.emergencyWithdraw(address(0), attacker, 1);
    }

    function test_oracle_writes_are_gated() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotSlp(address)")), attacker));
        vm.prank(attacker);
        oracle.update(WPROS, 1);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotVToken(address)")), attacker));
        vm.prank(attacker);
        oracle.onMint(WPROS, 1, 1);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("OwnableUnauthorizedAccount(address)")), attacker));
        vm.prank(attacker);
        oracle.setTokenAmount(WPROS, 0, 1);
    }

    function test_distributor_and_rewards_vault_gated() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotKeeper(address)")), attacker));
        vm.prank(attacker);
        IDistributor.Distribution[] memory ds = new IDistributor.Distribution[](1);
        ds[0] = IDistributor.Distribution(SLP1, 1);
        distributor.distribute(ds);

        bytes32 whitelistRole = keccak256("WHITELIST_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), attacker, whitelistRole)
        );
        vm.prank(attacker);
        IRewardsVault(REWARDS_VAULT).notifyOracle();
    }

    function test_slp_value_functions_gated() public {
        bytes32 whitelistRole = keccak256("WHITELIST_ROLE");
        bytes memory expected =
            abi.encodeWithSelector(bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), attacker, whitelistRole);
        bytes32 pool = 0xaecb1e6d44e8921b5b9b8e04f95d5a78776ee76d2eb7404fb002ab7fed86bedc;

        vm.expectRevert(expected);
        vm.prank(attacker);
        ISlp(SLP1).bond(pool, 1);

        vm.expectRevert(expected);
        vm.prank(attacker);
        ISlp(SLP1).claim(pool);

        vm.expectRevert(expected);
        vm.prank(attacker);
        ISlp(SLP1).transferBack(1);
    }

    function test_staking_claims_self_scoped() public {
        bytes32 pool = 0xaecb1e6d44e8921b5b9b8e04f95d5a78776ee76d2eb7404fb002ab7fed86bedc;
        vm.prank(attacker);
        vm.expectRevert(bytes("No rewards to claim"));
        IStaking(STAKING).claimReward(pool);

        vm.prank(attacker);
        vm.expectRevert(bytes("No withdrawable stake"));
        IStaking(STAKING).claimStake(pool);
    }

    // ---------------------------------------------------------------- permissionless no-ops
    function test_unwrap_is_permissionless_but_pays_nobody() public {
        uint256 before = attacker.balance;
        uint256 bridgeBefore = BRIDGE.balance;
        uint256 wrappedBefore = IERC20(WPROS).balanceOf(BRIDGE);
        vm.prank(attacker);
        bridge.unwrapWrapped();
        assertEq(attacker.balance, before, "attacker gained");
        assertEq(IERC20(WPROS).balanceOf(BRIDGE), 0, "wrapped left");
        assertEq(BRIDGE.balance, bridgeBefore + wrappedBefore, "vault native delta");
    }

    function test_withdrawComplete_fresh_returns_zero() public {
        vm.prank(attacker);
        assertEq(stpros.withdrawComplete(attacker), 0);
        vm.prank(attacker);
        assertEq(stpros.withdrawComplete(), 0);
    }

    function test_queue_is_fully_funded_no_surplus() public view {
        // getTotalBalance = bridge liquidity + completedWithdrawal; queuedWithdrawal is the
        // cumulative queue offset. The gap is the only amount a fresh withdrawal can claim.
        uint256 avail = stpros.getTotalBalance();
        uint256 queued = stpros.queuedWithdrawal();
        console2.log("available", avail);
        console2.log("queued", queued);
        assertLe(avail, queued + 1e15, "unexpected surplus > 0.001 PROS");
    }

    function test_deposit_redeem_roundtrip_extracts_nothing() public {
        uint256 amount = 10_000 ether;
        vm.deal(attacker, amount);
        uint256 start = attacker.balance;

        vm.prank(attacker);
        uint256 shares = stpros.depositWithPROS{value: amount}();
        assertGt(shares, 0);

        vm.prank(attacker);
        uint256 assetsOut = stpros.redeem(shares, attacker, attacker);
        assertApproxEqAbs(assetsOut, amount, 1e12, "redeem quote");

        vm.prank(attacker);
        uint256 claimed = stpros.withdrawComplete(attacker);
        console2.log("deposited", amount);
        console2.log("shares", shares);
        console2.log("queued assets", assetsOut);
        console2.log("immediately claimed", claimed);

        // No immediate payout beyond the pre-existing queue surplus (which is zero here).
        assertEq(claimed, 0, "unexpected immediate payout");
        assertEq(attacker.balance, start - amount, "attacker should only have the queued claim");
        assertEq(stpros.balanceOf(attacker), 0, "shares burned");
    }

    function test_max_extractable_by_permissionless_calls_is_zero() public {
        uint256 before = attacker.balance;
        vm.startPrank(attacker);
        // every externally callable, non-privileged value-touching entry
        (bool ok1,) = BRIDGE.call(abi.encodeWithSignature("unwrapWrapped()"));
        (bool ok2,) = STPROS.call(abi.encodeWithSignature("withdrawComplete(address)", attacker));
        (bool ok3,) = STPROS.call(abi.encodeWithSignature("withdrawComplete()"));
        (bool ok4,) = STAKING.call(
            abi.encodeWithSignature("claimReward(bytes32)", 0xaecb1e6d44e8921b5b9b8e04f95d5a78776ee76d2eb7404fb002ab7fed86bedc)
        );
        (bool ok5,) = STAKING.call(
            abi.encodeWithSignature("claimStake(bytes32)", 0xaecb1e6d44e8921b5b9b8e04f95d5a78776ee76d2eb7404fb002ab7fed86bedc)
        );
        vm.stopPrank();
        console2.log("unwrap", ok1);
        console2.log("withdrawComplete(receiver)", ok2);
        console2.log("withdrawComplete", ok3);
        console2.log("staking.claimReward", ok4);
        console2.log("staking.claimStake", ok5);
        assertEq(attacker.balance, before, "net extraction must be zero");
    }
}
