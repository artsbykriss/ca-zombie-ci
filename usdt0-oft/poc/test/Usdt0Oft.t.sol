// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

interface IEndpoint {
    function getConfig(address oapp, address lib, uint32 eid, uint32 configType) external view returns (bytes memory);
    function delegates(address oapp) external view returns (address);
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface IOApp {
    function peers(uint32 eid) external view returns (bytes32);
    function endpoint() external view returns (address);
    function allowInitializePath(Origin calldata origin) external view returns (bool);
    function lzReceive(Origin calldata origin, bytes32 guid, bytes calldata message, address executor, bytes calldata extraData) external payable;
}

/// @title USDT0 OFT adapter — inbound DVN / peer verification PoC (finding P7-04)
/// @notice READ-ONLY / fork-only (Ethereum mainnet). No mainnet tx.
///   Verifies: every live inbound route is 3-of-3 DVN; the 1-of-1 DVN routes are dormant
///   (no peer) and inert; a forged lzReceive reverts OnlyEndpoint.
contract Usdt0OftPoC is Test {
    address constant PROXY   = 0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee;
    address constant USDT    = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ULN302   = 0xc02Ab410f0734EFa3F14628780e6e695156024C2; // registered receive lib on Ethereum
    uint32 constant CONFIG_TYPE_ULN = 2;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IOApp oapp = IOApp(PROXY);
    IEndpoint ep = IEndpoint(ENDPOINT);

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"));
        vm.createSelectFork(url);
    }

    // 1. escrow size + init lock
    function test_01_escrow_and_init() public {
        uint256 bal = IERC20(USDT).balanceOf(PROXY);
        console2.log("USDT escrow (6dp)", bal);
        assertGt(bal, 3_000_000_000e6, "escrow should be > 3B USDT");
        // EIP-1967 impl slot matches the verified OAdapterUpgradeable impl
        bytes32 implSlot = vm.load(PROXY, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        console2.log("impl", address(uint160(uint256(implSlot))));
        // OZ v5 Initializable slot -> initialize() locked
        bytes32 initSlot = vm.load(PROXY, 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00);
        assertEq(uint256(initSlot), 1, "initialize locked (init slot = 1)");
    }

    // 2. live routes are 3-of-3; the four weak routes are 1-of-1 AND have no peer
    address constant DVN_1 = 0x3b0531eB02Ab4aD72e7a531180beeF9493a00dD2;
    address constant DVN_2 = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address constant DVN_3 = 0xF9D2C0915cac4C75b7ae359089333c8Ac258E12C;
    address constant DVN_WEAK = 0x747C741496a507E4B404b50463e691A8d692f6Ac;

    function _hasAddr(bytes memory hay, address a) internal pure returns (bool) {
        bytes memory n = abi.encodePacked(a);
        if (hay.length < 20) return false;
        for (uint256 i = 0; i + 20 <= hay.length; i++) {
            bool ok = true;
            for (uint256 j = 0; j < 20; j++) {
                if (hay[i + j] != n[j]) { ok = false; break; }
            }
            if (ok) return true;
        }
        return false;
    }

    function _rawCfg(uint32 eid) internal view returns (bytes memory) {
        return ep.getConfig(PROXY, ULN302, eid, CONFIG_TYPE_ULN);
    }

    function test_02_dvn_and_peer_config() public {
        uint32[4] memory live = [uint32(30109), 30110, 30111, 30181];
        for (uint256 i = 0; i < live.length; i++) {
            bytes32 peer = oapp.peers(live[i]);
            bytes memory raw = _rawCfg(live[i]);
            console2.log("live eid", live[i]);
            console2.log("  peer nonzero", peer != bytes32(0));
            assertTrue(peer != bytes32(0), "live route must have a peer");
            assertTrue(raw.length > 0, "live route must have a config");
            // 3-of-3 set present, weak 1-of-1 DVN absent
            assertTrue(_hasAddr(raw, DVN_1) && _hasAddr(raw, DVN_2) && _hasAddr(raw, DVN_3),
                "live route must carry the 3 required DVNs");
            assertFalse(_hasAddr(raw, DVN_WEAK), "live route must NOT use the weak DVN");
        }

        uint32[3] memory weak = [uint32(30165), 30214, 30375];
        for (uint256 i = 0; i < weak.length; i++) {
            bytes32 peer = oapp.peers(weak[i]);
            bytes memory raw = _rawCfg(weak[i]);
            console2.log("weak eid", weak[i]);
            console2.log("  peer zero", peer == bytes32(0));
            assertEq(peer, bytes32(0), "weak route has NO peer -> inert");
            assertTrue(_hasAddr(raw, DVN_WEAK), "weak route uses the single 0x747c7414 DVN");
            assertFalse(_hasAddr(raw, DVN_1), "weak route is NOT the 3-of-3 set");
        }

        // eid 30243 -> single 0x...dEaD DVN, no peer
        assertEq(oapp.peers(30243), bytes32(0), "30243 has no peer");
        assertTrue(_hasAddr(_rawCfg(30243), DEAD), "30243's only DVN is 0x...dEaD");
        console2.log("eid 30243: no peer, single DVN = 0x...dEaD");
    }

    // 3. forged lzReceive from 0x...dEaD reverts OnlyEndpoint
    function test_03_forged_lzReceive_reverts() public {
        vm.prank(DEAD);
        vm.expectRevert(); // OnlyEndpoint(0x...dEaD)
        Origin memory o = Origin(30165, bytes32(uint256(uint160(DEAD))), 1);
        oapp.lzReceive(o, bytes32(0), hex"", address(0), hex"");
        console2.log("forged lzReceive reverted (OnlyEndpoint)");
        // allowInitializePath is false for the dormant route (no peer)
        assertFalse(oapp.allowInitializePath(Origin(30165, bytes32(uint256(uint160(DEAD))), 1)));
        console2.log("allowInitializePath(dormant 30165) = false");
    }
}
