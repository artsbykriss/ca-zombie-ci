// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ---------------------------------------------------------------------------
// ZH4-PASS4 Tier-3 deep-dive : DMD (DMDToken) burn-from-pair + sync()
// Read-only. Fork simulation only. No mainnet tx signed/sent.
//
// DMD token : 0x939Df4A5A5022037BB33102C6489e774E063b160
// DMD pair  : 0x29f9148a8518e327e8677Ba21C3fa3A55DD1e6Bc (PancakeV2 DMD/USDC)
// gate      : burnFromMainPair() -> `onlyAdmin` (if msg.sender != admin revert
//             NotAdmin()) ; PAIR_BURN_BPS = 50 (0.5% of pair per call, no cooldown)
// ---------------------------------------------------------------------------

interface IERC20m {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function sync() external;
}

interface IRouter {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory);
}

interface IDMDtoken {
    function admin() external view returns (address);
    function owner() external view returns (address);
    function buyEnabled() external view returns (bool);
    function mainPair() external view returns (address);
    function burnFromMainPair() external;
    function setBuyEnabled(bool) external;
}

contract DmdPoC is Test {
    address constant DMD = 0x939Df4A5A5022037BB33102C6489e774E063b160;
    address constant DMD_PAIR = 0x29f9148a8518e327e8677Ba21C3fa3A55DD1e6Bc;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

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

    function test_dmd_live_state() public {
        (uint112 r0, uint112 r1,) = IPair(DMD_PAIR).getReserves();
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("DMD pair reserve USDC (1e18)", r0);
        emit log_named_uint("DMD pair reserve DMD  (1e18)", r1);
        emit log_named_uint("DMD pair balanceOf(DMD)", IERC20m(DMD).balanceOf(DMD_PAIR));
        assertEq(uint256(r1), IERC20m(DMD).balanceOf(DMD_PAIR), "reserve1 == real DMD balance (no desync)");
        assertEq(IPair(DMD_PAIR).token0(), USDC);
        assertEq(IPair(DMD_PAIR).token1(), DMD);
        assertEq(IDMDtoken(DMD).mainPair(), DMD_PAIR);
    }

    // gate : onlyAdmin -> NotAdmin()
    function test_dmd_gate_reverts_not_admin() public {
        vm.prank(ATT);
        (bool ok, bytes memory ret) = DMD.call(abi.encodeWithSelector(IDMDtoken.burnFromMainPair.selector));
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(0x7bfa4b9f), "NotAdmin()");
        emit log_named_address("DMD admin", IDMDtoken(DMD).admin());
        emit log_named_address("DMD owner", IDMDtoken(DMD).owner());
        emit log_named_uint("DMD buyEnabled (1=true)", IDMDtoken(DMD).buyEnabled() ? 1 : 0);
    }

    // buying is disabled on the token level -> a fresh attacker cannot acquire DMD
    function test_dmd_buy_is_disabled() public {
        assertFalse(IDMDtoken(DMD).buyEnabled(), "buyEnabled == false");

        // direct: the pair cannot move DMD out while buying is disabled
        vm.prank(DMD_PAIR);
        vm.expectRevert(bytes4(0x44c1679c)); // BuyingDisabled()
        IERC20m(DMD).transfer(ATT, 1 ether);

        vm.deal(ATT, 1 ether);
        address[] memory path = new address[](3);
        path[0] = WBNB;
        path[1] = USDC;
        path[2] = DMD;
        vm.prank(ATT);
        vm.expectRevert(); // router masks the inner BuyingDisabled() as Pancake: TRANSFER_FAILED
        IRouter(ROUTER).swapExactETHForTokens{value: 0.1 ether}(0, path, ATT, block.timestamp + 300);
        assertEq(IERC20m(DMD).balanceOf(ATT), 0);
    }

    // LATENT (privileged) : a compromised admin key can loop the burn
    // (no cooldown) and collapse the DMD reserve, then sell DMD back.
    function test_dmd_latent_admin_loop_burn() public {
        address admin = IDMDtoken(DMD).admin();
        (uint112 a0, uint112 a1,) = IPair(DMD_PAIR).getReserves();

        vm.startPrank(admin);
        for (uint256 i = 0; i < 100; i++) {
            IDMDtoken(DMD).burnFromMainPair(); // 0.5% of pair DMD each call + sync()
        }
        vm.stopPrank();

        (uint112 b0, uint112 b1,) = IPair(DMD_PAIR).getReserves();
        emit log_named_uint("DMD reserve before", a1);
        emit log_named_uint("DMD reserve after", b1);
        uint256 dropBps = (uint256(a1) - uint256(b1)) * 10_000 / uint256(a1);
        emit log_named_uint("100x admin burn drop (bps of pair DMD)", dropBps);
        assertGt(dropBps, 3000, "~39% of pair DMD removed in 100 calls");
        assertEq(uint256(b1), IERC20m(DMD).balanceOf(DMD_PAIR), "sync() ran");
        assertEq(uint256(b0), uint256(a0), "USDC reserve unchanged");
    }
}
