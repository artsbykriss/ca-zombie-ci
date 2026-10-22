// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ---------------------------------------------------------------------------
// ZH4-PASS4 Tier-3 deep-dive : BTCX (BTCΞ) burn-from-pair + sync()
// Read-only. Fork simulation only. No mainnet transaction is signed/sent.
//
// BTCΞ token : 0xb1939843fB9220719d13076dCeEfb0aeaeF06666
// BTCΞ "main" pair (hardcoded `pancakePair`) : 0x3cC292bB0011951F3151eB998816c31680a2Ce87 (BT/BTCB, $2.46M)
// Other BT pairs (NOT hardcoded, so NOT covered by the "T0" gate):
//   BT/WBNB 0x422A5F1Dce067133Ad3941e9A7E2a7cDeB6EC918  (dust)
//   BT/USDT 0x22bCdB167992cB52A6fB7943d7b35738346a81AB  (dust)
// ---------------------------------------------------------------------------

interface IERC20m {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

interface IRouter {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory);
}

interface INStoken {
    function pairBurnOperator() external view returns (address);
    function burnNsFromPair(uint256 burnBps) external;
}

interface IDMDtoken {
    function admin() external view returns (address);
    function burnFromMainPair() external;
}

contract BtcxPoC is Test {
    address constant BT = 0xb1939843fB9220719d13076dCeEfb0aeaeF06666;
    address constant BT_PAIR = 0x3cC292bB0011951F3151eB998816c31680a2Ce87; // hardcoded pancakePair
    address constant BT_WBNB_PAIR = 0x422A5F1Dce067133Ad3941e9A7E2a7cDeB6EC918;
    address constant BT_USDT_PAIR = 0x22bCdB167992cB52A6fB7943d7b35738346a81AB;
    address constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address constant NS = 0x33F1c4Fbb7e4E040F4F4E6Bc492e4Fedf750FD41;
    address constant DMD = 0x939Df4A5A5022037BB33102C6489e774E063b160;

    address constant ATT = address(0xdEADbeEF00000000000000000000000000000001);

    uint256 forkBlock;

    function setUp() public {
        string[3] memory urls = [
            "https://bsc-rpc.publicnode.com",
            "https://bsc.drpc.org",
            "https://bsc.blockrazor.xyz"
        ];
        bool ok = false;
        string memory env = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(env).length > 0) {
            try vm.createSelectFork(env) {
                ok = true;
            } catch {}
        }
        if (!ok) {
            for (uint256 i = 0; i < urls.length; i++) {
                try vm.createSelectFork(urls[i]) {
                    ok = true;
                    break;
                } catch {}
            }
        }
        require(ok, "no working BSC fork rpc");
        forkBlock = block.number;
    }

    // ---- 0. live state ------------------------------------------------------
    function test_btcx_live_state() public {
        (uint112 r0, uint112 r1,) = IPair(BT_PAIR).getReserves();
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("main pair reserve BTCB (1e18)", r0);
        emit log_named_uint("main pair reserve BT   (1e18)", r1);
        emit log_named_uint("BT.balanceOf(main pair)", IERC20m(BT).balanceOf(BT_PAIR));
        assertEq(uint256(r1), IERC20m(BT).balanceOf(BT_PAIR), "reserve1 == real balance (no desync)");
        assertEq(IPair(BT_PAIR).token0(), BTCB);
        assertEq(IPair(BT_PAIR).token1(), BT);
    }

    // ---- 0b. the OTHER BT pairs exist and are dust -------------------------
    function test_btcx_other_pairs_are_dust() public {
        (uint112 a0, uint112 a1,) = IPair(BT_WBNB_PAIR).getReserves();
        (uint112 b0, uint112 b1,) = IPair(BT_USDT_PAIR).getReserves();
        emit log_named_uint("BT/WBNB pair r0 (BT)", a0);
        emit log_named_uint("BT/WBNB pair r1 (WBNB wei)", a1);
        emit log_named_uint("BT/USDT pair r0 (USDT wei)", b0);
        emit log_named_uint("BT/USDT pair r1 (BT wei)", b1);
        // both are worth < $10 -> no meaningful way to acquire BTCX there
        assertLt(uint256(a1), 0.01 ether, "BT/WBNB holds < 0.01 WBNB");
        assertLt(uint256(a0), 10 ether, "BT/WBNB holds < 10 BTCX");
        assertLt(uint256(b0), 1 ether, "BT/USDT holds < 1 USDT");
    }

    // ---- 1. entry via the MAIN pair is blocked: pair -> user reverts "T0" --
    function test_btcx_buy_from_main_pair_is_blocked_T0() public {
        // what a swap output does: the pair calls BT.transfer(buyer)
        vm.prank(BT_PAIR);
        vm.expectRevert(bytes("T0"));
        IERC20m(BT).transfer(ATT, 1 ether);

        // and via the real router on the main route WBNB -> BTCB -> BTCX
        vm.deal(ATT, 1 ether);
        address[] memory path = new address[](3);
        path[0] = WBNB;
        path[1] = BTCB;
        path[2] = BT;
        vm.prank(ATT);
        vm.expectRevert(); // pair's _safeTransfer masks the inner "T0" as Pancake: TRANSFER_FAILED
        IRouter(ROUTER).swapExactETHForTokens{value: 0.1 ether}(0, path, ATT, block.timestamp + 300);

        assertEq(IERC20m(BT).balanceOf(ATT), 0, "attacker acquired no BTCX from the main pool");
    }

    // ---- 2. the burn-from-pair + sync IS permissionless, but self-limited ---
    function test_btcx_burn_permissionless_one_hour() public {
        (uint112 a0, uint112 a1,) = IPair(BT_PAIR).getReserves();
        emit log_named_uint("reserve BT before", a1);

        vm.warp(block.timestamp + 1 hours + 1); // cross one hourly cycle
        vm.prank(ATT);
        IERC20m(BT).transfer(ATT, 1); // permissionless trigger of _updateCycle()

        (uint112 b0, uint112 b1,) = IPair(BT_PAIR).getReserves();
        emit log_named_uint("reserve BT after", b1);
        assertLt(uint256(b1), uint256(a1), "pair BT reserve reduced by the burn");
        assertEq(uint256(b1), IERC20m(BT).balanceOf(BT_PAIR), "sync() ran: reserve == balance");

        uint256 dropBps = (uint256(a1) - uint256(b1)) * 10_000 / uint256(a1);
        emit log_named_uint("single-hour burn (bps of pair BT)", dropBps);
        assertApproxEqAbs(dropBps, 10, 3, "~0.104% per hourly cycle (10 bps)");

        assertEq(IERC20m(BT).balanceOf(ATT), 0, "attacker still holds no BTCX -> nothing to sell");
    }

    // ---- 3. worst-case dormant catch-up (LATENT, not current state) ---------
    function test_btcx_dormant_catchup_is_capped_100() public {
        (uint112 a0, uint112 a1,) = IPair(BT_PAIR).getReserves();
        vm.warp(block.timestamp + 200 hours);
        vm.prank(ATT);
        IERC20m(BT).transfer(ATT, 1);
        (uint112 b0, uint112 b1,) = IPair(BT_PAIR).getReserves();
        uint256 dropBps = (uint256(a1) - uint256(b1)) * 10_000 / uint256(a1);
        emit log_named_uint("200h-dormant catch-up burn (bps of pair BT)", dropBps);
        assertGt(dropBps, 900, "~9.9% removed when 100 cycles are replayed");
        assertLt(dropBps, 1100, "catch-up capped at 100 cycles");
        assertEq(IERC20m(BT).balanceOf(ATT), 0, "attacker still holds no BTCX");
    }

    // ---- 4. NS / DMD cross-check ------------------------------------------
    function test_ns_gate_is_not_unprivileged() public {
        vm.prank(ATT);
        (bool ok, bytes memory ret) = NS.call(abi.encodeWithSelector(INStoken.burnNsFromPair.selector, uint256(500)));
        assertFalse(ok, "burnNsFromPair must revert for an outsider");
        assertEq(bytes4(ret), bytes4(0x82b42900), "Unauthorized()");
        emit log_named_address("NS pairBurnOperator", INStoken(NS).pairBurnOperator());
    }

    function test_dmd_gate_is_not_unprivileged() public {
        vm.prank(ATT);
        (bool ok, bytes memory ret) = DMD.call(abi.encodeWithSelector(IDMDtoken.burnFromMainPair.selector));
        assertFalse(ok, "burnFromMainPair must revert for an outsider");
        assertEq(bytes4(ret), bytes4(0x7bfa4b9f), "NotAdmin()");
        emit log_named_address("DMD admin", IDMDtoken(DMD).admin());
    }
}
