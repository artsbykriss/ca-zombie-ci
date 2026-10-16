// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// AZverse AssetVault — Arbitrum mainnet fork tests against LIVE state.
// Read-only: fork-only; no transactions are ever sent to a real chain.
// Run in CI: ARB_RPC_URL is provided by the workflow (public fallback otherwise).

import {Test} from "forge-std/Test.sol";
import {AssetVault, ValidatorInfo, WithdrawAction} from "../src/AssetVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetVaultForkTest is Test {
    // ---- live addresses (Arbitrum One, chainid 42161) ----
    address constant V1 = 0x91Ba525861c16AA8Cd4D6974E4058cc846f42eBE; // active secondary vault (DL-counted)
    address constant V1_IMPL = 0x94a99081475d0b5B887c5a03FcD9B81e52C264DE;
    bytes32 constant V1_IMPL_CODEHASH = 0x751730582414fb5ec4d158dfc9d12cfbd9820ce1cdccc1ec30fa9ef98983f184;
    address constant V2 = 0x949556cb8634F9a4a8504665C3d0D9d326c600b2; // busier production vault (120s challenge)
    address constant V2_IMPL = 0xB5D7cFae3d89036B0Ca026b46420AB44933323B6;

    bytes32 constant VALIDATOR_HASH = 0x8141d873ff9759ed4e5a2eeb4aadd259f6110c82b662e5f0ed52886b16e3355a;
    address constant VAL1 = 0x6CC538784e6050A3e842104D7a50A1FaEF1dB3aa;
    address constant VAL2 = 0xDa1bB36dE3197A9171b2FF7e45bc27809715323b;
    address constant VAL3 = 0xF29Cc2E03DA7AEA7036f44ddc423644028D8cE6F;

    address constant OP1 = 0x32fCFf5C9BbCF45F4EfE50219CE9F24DF2889aF3;
    address constant OP2 = 0x9276609d5bCe373938AE20F7c1eab7f0c1220701;
    address constant OP3 = 0x9BBc8a82e24Fd4434103302Edf0f0758D51c575f;
    address constant ADMIN_TL = 0x7A1b6891269Ed1699F93e25296a6e23d6f4F7386;
    address constant UPGRADE_TL = 0x92996eA56590b0e659d695d9736Db62Cae843b51;
    address constant VALIDATOR_TL = 0x383A6439f966D67eDC6140d12024334616dDC276;
    address constant SAFE = 0x4a335BB7f44fc27bf4fbB5705e71014bACe924Ec;

    address constant CUSTODY1 = 0x03A7e58745874D49b3AcC770C40261A3ce206608;
    address constant CUSTODY3 = 0xdC379823A9a3A2ca9d77C33299551ecDBaBf7A41;
    address constant USDT0 = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant SPENDER_A = 0x27117f7E48E07f9E23042931aB39fE02a62Ec587;
    address constant SPENDER_B = 0x8786f9b8833D2DeF80F90aD75562f9f5783090a0;

    uint256[8] STALE_IDS = [
        664069738506862848,
        664074101526741248,
        664074311472903296,
        664075284429796480,
        664078265124516992,
        664078799168192768,
        664078868991046784,
        664342947185947776
    ];

    AssetVault v1;
    AssetVault v2;

    function setUp() public {
        string memory rpc = vm.envOr("ARB_RPC_URL", string(""));
        string[3] memory candidates;
        candidates[0] = bytes(rpc).length > 0 ? rpc : "https://arbitrum-one-rpc.publicnode.com";
        candidates[1] = "https://arbitrum-one-rpc.publicnode.com";
        candidates[2] = "https://arb1.arbitrum.io/rpc";
        bool ok;
        for (uint256 i = 0; i < 3 && !ok; i++) {
            try vm.createSelectFork(candidates[i]) {
                ok = true;
            } catch {}
        }
        require(ok, "no working arbitrum rpc");
        v1 = AssetVault(payable(V1));
        v2 = AssetVault(payable(V2));
        assertEq(block.chainid, 42161, "fork must be Arbitrum One");
        // NOTE: on Arbitrum forks Foundry reports the L1 block number here; chainid + code presence prove the fork.
        emit log_named_uint("fork chainid", block.chainid);
        emit log_named_uint("fork block (L1 number on Arbitrum fork)", block.number);
        assertTrue(V1.code.length > 0, "vault code present on fork");
    }

    function test_fork_impl_slot_and_codehash() public view {
        assertEq(
            uint256(vm.load(V1, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)),
            uint256(uint160(V1_IMPL)),
            "impl slot"
        );
        assertEq(
            uint256(vm.load(V1, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)),
            0,
            "no ERC1967 admin (UUPS)"
        );
        assertEq(V1_IMPL.codehash, V1_IMPL_CODEHASH, "impl codehash unchanged");
        assertEq(V2_IMPL.codehash, 0x58a543d406c97870edabd74948034d405b9a49a53a19884b5085138fc2279d20, "v2 impl codehash");
    }

    function test_fork_live_config_v1() public view {
        assertEq(v1.pendingWithdrawChallengePeriod(), 86400, "1-day challenge");
        assertTrue(!v1.paused(), "not paused");
        assertEq(v1.rebalanceReceiver(), address(0), "rebalance disabled on v1");
        assertEq(v1.availableValidators(VALIDATOR_HASH), 60, "total power 60");
        assertEq(v1.validatorRequiredPowers(VALIDATOR_HASH), 40, "required power 40 (2-of-3)");
    }

    function test_fork_validator_set_hash_matches_powers_20_20_20() public pure {
        ValidatorInfo[] memory set = new ValidatorInfo[](3);
        set[0] = ValidatorInfo(VAL1, 20);
        set[1] = ValidatorInfo(VAL2, 20);
        set[2] = ValidatorInfo(VAL3, 20);
        assertEq(keccak256(abi.encode(set)), VALIDATOR_HASH, "live set is exactly [20,20,20]");
    }

    function test_fork_role_holders() public view {
        assertTrue(v1.hasRole(v1.OPERATOR_ROLE(), OP1));
        assertTrue(v1.hasRole(v1.OPERATOR_ROLE(), OP2));
        assertTrue(v1.hasRole(v1.OPERATOR_ROLE(), OP3));
        assertTrue(v1.hasRole(v1.ADMIN_ROLE(), ADMIN_TL));
        assertTrue(v1.hasRole(v1.UPGRADE_ROLE(), UPGRADE_TL));
        assertTrue(v1.hasRole(v1.VALIDATOR_ROLE(), VALIDATOR_TL));
        assertTrue(v1.hasRole(0x00, SAFE));
        assertTrue(v1.hasRole(v1.TOKEN_ROLE(), SAFE));
        assertTrue(v1.hasRole(v1.DEPOSIT_ROLE(), SAFE));
        assertTrue(v1.hasRole(v1.PAUSE_ROLE(), SAFE));
    }

    function test_fork_fresh_attacker_has_no_roles() public view {
        address fresh = address(0xF00D5EED);
        assertTrue(!v1.hasRole(0x00, fresh));
        assertTrue(!v1.hasRole(v1.OPERATOR_ROLE(), fresh));
        assertTrue(!v1.hasRole(v1.VALIDATOR_ROLE(), fresh));
        assertTrue(!v1.hasRole(v1.UPGRADE_ROLE(), fresh));
        assertTrue(!v1.hasRole(v1.ADMIN_ROLE(), fresh));
    }

    function test_fork_stale_withdrawals_all_paused() public {
        for (uint256 i = 0; i < STALE_IDS.length; i++) {
            (bool paused, bool pending, bool executed, uint256 amount, address token, uint256 fee, address receiver, uint256 ts) =
                v1.withdrawals(STALE_IDS[i]);
            assertTrue(pending && !executed, "still pending, unexecuted");
            assertTrue(paused, "paused (cannot be cranked)");
            assertTrue(ts > 0 && amount > 0 && receiver != address(0));
            emit log_named_uint("stale id", STALE_IDS[i]);
            emit log_named_uint("  amount", amount);
            emit log_named_uint("  fee", fee);
            emit log_named_address("  token", token);
        }
    }

    function test_fork_fresh_caller_crank_paused_reverts() public {
        vm.expectRevert(AssetVault.WithdrawalPaused.selector);
        vm.prank(address(0xF00D5EED));
        v1.executeExpiredPendingWithdrawal(STALE_IDS[0]);
    }

    function test_fork_fresh_caller_crank_nonexistent_reverts() public {
        vm.expectRevert(AssetVault.WithdrawalExistenceCheckFailed.selector);
        vm.prank(address(0xF00D5EED));
        v1.executeExpiredPendingWithdrawal(123456789);
    }

    function test_fork_fresh_attacker_cannot_requestWithdraw() public {
        WithdrawAction memory action = WithdrawAction(USDT0, 1e6, 0, address(0xF00D5EED));
        bytes[] memory sigs = new bytes[](0);
        ValidatorInfo[] memory set = new ValidatorInfo[](0);
        vm.expectRevert();
        vm.prank(address(0xF00D5EED)); // AccessControlUnauthorizedAccount
        v1.requestWithdraw(1, false, set, action, sigs, 1);
    }

    function test_fork_no_live_allowances_from_custody_wallets() public view {
        assertEq(IERC20(USDT0).allowance(CUSTODY1, SPENDER_A), 0);
        assertEq(IERC20(USDT0).allowance(CUSTODY1, SPENDER_B), 0);
        assertEq(IERC20(USDT0).allowance(CUSTODY3, SPENDER_A), 0);
        assertEq(IERC20(USDT0).allowance(CUSTODY3, SPENDER_B), 0);
        assertEq(IERC20(USDC).allowance(CUSTODY1, SPENDER_A), 0);
        assertEq(IERC20(USDC).allowance(CUSTODY3, SPENDER_A), 0);
    }

    function test_fork_live_balances_recorded() public {
        uint256 v1Usdt = IERC20(USDT0).balanceOf(V1);
        uint256 v1Usdc = IERC20(USDC).balanceOf(V1);
        uint256 c3Usdt = IERC20(USDT0).balanceOf(CUSTODY3);
        emit log_named_uint("v1 USDT0 (6dp)", v1Usdt);
        emit log_named_uint("v1 USDC (6dp)", v1Usdc);
        emit log_named_uint("custody3 USDT0 (6dp)", c3Usdt);
        assertTrue(v1Usdt > 0 && v1Usdc > 0, "vault holds live funds");
        assertTrue(c3Usdt > 40_000_000e6, "custody3 holds ~$50M USDT0 (plain EOA)");
    }

    function test_fork_v2_vault_same_code_live() public view {
        assertEq(
            uint256(vm.load(V2, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)),
            uint256(uint160(V2_IMPL)),
            "v2 impl slot"
        );
        assertEq(v2.pendingWithdrawChallengePeriod(), 120, "120s challenge");
        assertTrue(!v2.paused(), "not paused");
        assertTrue(v2.rebalanceReceiver() != address(0), "rebalance enabled on v2");
        assertTrue(v2.hasRole(v2.OPERATOR_ROLE(), 0xA9E61f9a176B9D211909F8D24cAFCc22683cF97C));
    }
}
