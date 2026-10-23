// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

/// Minimal interfaces for the Metropolis DLMM VaultFactory / OracleRewardVault / Strategy (Sonic 146).
interface IVaultFactory {
    enum VaultType { None, Simple, Oracle }
    function owner() external view returns (address);
    function getVaultImplementation(VaultType vType) external view returns (address);
    function getStrategyImplementation(uint8 sType) external view returns (address);
    function getNumberOfVaults(VaultType vType) external view returns (uint256);
    function getVaultAt(VaultType vType, uint256 index) external view returns (address);
    function getCreationFee() external view returns (uint256);
    function getFeeRecipient() external view returns (address);
    function getDefaultOperator() external view returns (address);
    function isPairWhitelisted(address pair) external view returns (bool);
    function getFeeRecipientByVault(address vault) external view returns (address);
    function createMarketMakerOracleVault(address lbPair, uint16 aumFee) external payable returns (address, address);
    function setVaultImplementation(VaultType vType, address impl) external;
    function setFeeRecipient(address feeRecipient) external;
    function initialize4(address owner, uint256 creationFee) external;
}

interface IVault {
    function getStrategy() external view returns (address);
    function getPair() external view returns (address);
    function getTokenX() external view returns (address);
    function getTokenY() external view returns (address);
    function getOracleHelper() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getOperators() external view returns (address defaultOperator, address operator);
    function isDepositsPaused() external view returns (bool);
    function pauseDeposits() external;
    function resumeDeposits() external;
    function submitShutdown() external;
    function setStrategy(address newStrategy) external;
    function recoverERC20(address token, address recipient, uint256 amount) external;
    function setEmergencyMode() external;
    function emergencyWithdraw() external;
    function executeQueuedWithdrawals() external;
    function claim() external;
    function queueWithdrawal(uint256 shares, address recipient) external returns (uint256);
}

interface IStrategy {
    function getOperator() external view returns (address);
    function getAumAnnualFee() external view returns (uint256);
    function getBalances() external view returns (uint256, uint256);
    function withdrawAll() external;
    function setOperator(address operator) external;
    function rebalance(uint24, uint24, uint24, uint24, uint256, uint256, bytes calldata) external;
    function emergencyWidthdrawRange(uint24 lower, uint24 upper) external;
    function harvestRewards() external;
    function setPendingAumAnnualFee(uint16 fee) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract MetropolisAuthTest is Test {
    // --- live Sonic addresses (verified 2026-10-23, block 81,494,388) ---
    address constant FACTORY   = 0x197d40B36677248E82939f96930bf4E7Fe8aD1c2;
    address constant IMPL_ORACLE = 0xe19B636A6ABEe9C14eABB3F64e30c3304859BDB7; // OracleRewardVault
    address constant IMPL_STRAT  = 0x1817134Ad98B72a42AB68cc485fb123AFaC85e80; // Strategy
    address constant OWNER_SAFE  = 0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF; // Gnosis Safe (factory owner)
    address constant VAULT    = 0x6bE5a84D4A92269eC0Eb228B6c4dAdecED4C7D54; // WETH/wS, ~$62.6k
    address constant STRATEGY = 0x3CD06627E5DAf698F81fdaaD24b6d16DAF209450;
    address constant WETH     = 0x50c42dEAcD8Fc9773493ED674b675bE577f2634b;
    address constant WS       = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address constant PAIR     = 0x9eDE606c7168bb09fF73EbdE7bFD6FcfaBDA9Bc3;
    address constant OP_EOA   = 0xA63C0A7007FFFD9eeDd28f4379b7113d916cD329; // 7702-delegated operator EOA

    address constant ATK = address(0xA11CE);

    IVaultFactory factory = IVaultFactory(FACTORY);
    IVault vault = IVault(VAULT);
    IStrategy strategy = IStrategy(STRATEGY);

    function setUp() public {
        // CI may export SONIC_RPC_URL as an empty string; fall back to the public Sonic RPC.
        string memory url = vm.envOr("SONIC_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://rpc.soniclabs.com";
        vm.createSelectFork(url);
    }

    // 1) Factory holds no custody: no native, oracle impl set, no Simple impl.
    function test_factory_has_no_custody() public view {
        assertGt(FACTORY.code.length, 0, "factory has code");
        assertEq(FACTORY.balance, 0, "factory native balance is 0");
        assertEq(factory.getVaultImplementation(IVaultFactory.VaultType.Oracle), IMPL_ORACLE);
        assertEq(factory.getVaultImplementation(IVaultFactory.VaultType.Simple), address(0));
        assertEq(factory.getNumberOfVaults(IVaultFactory.VaultType.Oracle), 124);
        assertEq(factory.getCreationFee(), 50 ether);
        assertEq(factory.owner(), OWNER_SAFE);
        assertEq(factory.getDefaultOperator(), OWNER_SAFE);
        assertEq(factory.getStrategyImplementation(1), IMPL_STRAT);
    }

    // 2) The created vault is an OracleRewardVault clone (has the reward-vault-only surface).
    function test_vault_is_oracle_reward_vault_clone() public view {
        assertGt(VAULT.code.length, 0);
        assertEq(vault.getStrategy(), STRATEGY);
        assertEq(vault.getPair(), PAIR);
        assertEq(vault.getTokenX(), WETH);
        assertEq(vault.getTokenY(), WS);
        assertTrue(vault.getOracleHelper() != address(0), "oracle helper set");
        assertGt(vault.totalSupply(), 0, "shares outstanding");
        // getUserInfo(address) exists only on OracleRewardVault
        (bool ok,) = VAULT.staticcall(abi.encodeWithSignature("getUserInfo(address)", ATK));
        assertTrue(ok, "OracleRewardVault.getUserInfo present");
        (address defOp, address op) = vault.getOperators();
        assertEq(defOp, OWNER_SAFE);
        assertEq(op, OP_EOA);
        assertEq(strategy.getOperator(), OP_EOA);
    }

    // 3) Every value-moving vault entry point reverts for an unprivileged EOA.
    function test_vault_value_movers_revert_for_unprivileged() public {
        vm.startPrank(ATK);
        vm.expectRevert(); vault.pauseDeposits();
        vm.expectRevert(); vault.resumeDeposits();
        vm.expectRevert(); vault.submitShutdown();
        vm.expectRevert(); vault.setStrategy(address(0xdead));
        vm.expectRevert(); vault.recoverERC20(WETH, ATK, 1);
        vm.expectRevert(); vault.setEmergencyMode();
        vm.expectRevert(); vault.emergencyWithdraw();
        vm.expectRevert(); vault.executeQueuedWithdrawals();
        vm.expectRevert(); vault.queueWithdrawal(0, ATK);
        vm.stopPrank();
    }

    // 4) Every value-moving strategy entry point reverts for an unprivileged EOA.
    function test_strategy_value_movers_revert_for_unprivileged() public {
        vm.startPrank(ATK);
        vm.expectRevert(); strategy.withdrawAll();
        vm.expectRevert(); strategy.setOperator(ATK);
        vm.expectRevert(); strategy.rebalance(1, 2, 0, 0, 0, 0, "");
        vm.expectRevert(); strategy.emergencyWidthdrawRange(0, 1);
        vm.expectRevert(); strategy.harvestRewards();
        vm.expectRevert(); strategy.setPendingAumAnnualFee(100);
        vm.stopPrank();
    }

    // 5) Factory admin entry points revert for an unprivileged EOA; create is whitelist+eth gated.
    function test_factory_admin_gated_and_create_gated() public {
        vm.startPrank(ATK);
        vm.expectRevert(); factory.setVaultImplementation(IVaultFactory.VaultType.Oracle, ATK);
        vm.expectRevert(); factory.setFeeRecipient(ATK);
        vm.expectRevert(); factory.initialize4(ATK, 0); // already initialized at version 6
        vm.expectRevert(); factory.createMarketMakerOracleVault(address(0xdead), 0); // not whitelisted
        vm.stopPrank();
    }

    // 6) claim() is permissionless but self-scoped: caller gets only their own rewards.
    function test_claim_is_self_scoped() public {
        assertEq(vault.getStrategy(), STRATEGY);
        uint256 beforeWeth = IERC20(WETH).balanceOf(ATK);
        uint256 beforeWs = IERC20(WS).balanceOf(ATK);
        vm.prank(ATK);
        vault.claim(); // succeeds, but ATK holds no shares/rewards
        assertEq(IERC20(WETH).balanceOf(ATK), beforeWeth, "no WETH paid to random caller");
        assertEq(IERC20(WS).balanceOf(ATK), beforeWs, "no wS paid to random caller");
    }

    // 7) Even the legitimate operator cannot move principal to itself: its strongest lever
    //    (rebalance with no re-deposit) leaves the tokens in the strategy contract.
    function test_operator_rebalance_cannot_extract_principal() public {
        (uint256 balX, uint256 balY) = strategy.getBalances();
        uint256 principalWeth = IERC20(WETH).balanceOf(STRATEGY);
        uint256 opBefore = IERC20(WETH).balanceOf(OP_EOA);
        uint256 supplyBefore = vault.totalSupply();

        vm.prank(OP_EOA);
        try strategy.rebalance(0, 0, 0, 0, 0, 0, "") {
            // funds were withdrawn from LB into the strategy contract; not sent to the operator
            uint256 stratAfter = IERC20(WETH).balanceOf(STRATEGY);
            assertGe(stratAfter, principalWeth, "principal stays in strategy");
            uint256 opAfter = IERC20(WETH).balanceOf(OP_EOA);
            // operator may only collect the bounded AUM fee (<= 1% of the vault's principal here)
            uint256 opGain = opAfter > opBefore ? opAfter - opBefore : 0;
            assertLe(opGain, balX / 100 + 1e15, "operator gain bounded to a small AUM fee");
            assertEq(vault.totalSupply(), supplyBefore, "no shares minted to operator");
        } catch {
            // if the live rebalance path reverts, principal cannot have moved at all
            assertEq(IERC20(WETH).balanceOf(STRATEGY), principalWeth, "principal unchanged");
        }
        // balX/balY used to keep the live values in the trace
        assertTrue(balX + balY >= 0);
    }
}
