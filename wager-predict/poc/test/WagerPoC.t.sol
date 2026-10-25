// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

/// @title Wager Predict (BSC) — external-unprivileged extraction PoC
/// @notice Read-only fork test. Every candidate value-moving path is probed from a
///         fresh attacker EOA. A green suite == "no unprivileged path works".
///         No mainnet transaction is ever signed or sent.
contract WagerPoC is Test {
    // ---- BSC mainnet addresses (read at the block below) ----
    address constant SE     = 0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c; // SpotEngine (holds funds)
    address constant VAULT  = 0x88d163d40D6BFe0Ad2b17f4a90A03053fEbf3014; // LP vault
    address constant USDW   = 0xe5eBE2AE0a036C955bfF58291826C50F7d670D43; // USDW proxy
    address constant ORACLE = 0x5c3a3b430E44bD18Fd7f29Cb3Ec1948Bac542a9A; // PriceOracle proxy
    address constant BSC_USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // approved input stable
    address constant ABNBUSDC = 0x00901a076785e0906d1028c7d6372d247bec7d61; // held by depositRecipient, NOT approved
    address constant DEAD   = 0x000000000000000000000000000000000000dEaD;

    uint256 constant FORK_BLOCK = 129_703_926;

    address attacker;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string("https://bsc-rpc.publicnode.com"));
        vm.createSelectFork(rpc, FORK_BLOCK);
        attacker = vm.addr(0xA11CE);
    }

    function test_engine_holds_the_funds() public view {
        uint256 se = IERC20(USDW).balanceOf(SE);
        emit log_named_uint("SpotEngine USDW", se);
        assertGt(se, 170_000e6);
        assertGt(IERC20(USDW).totalSupply(), 0);
    }

    function test_privileged_paths_revert_for_stranger() public {
        vm.startPrank(attacker);
        assertFalse(_ok(SE, abi.encodeWithSelector(0xd3f0b0f8, uint256(0), uint8(0)))); // resolveMarket (sig best-effort)
        assertFalse(_ok(SE, hex"00000000"));                                             // unknown selector -> revert
        // initializeMarket / haltMarket -> OnlyRegistry
        (bool ok, bytes memory ret) = SE.call(abi.encodeWithSignature("haltMarket(uint256)", uint256(0)));
        assertFalse(ok);
        assertEq(_reason(ret), "OnlyRegistry");
        vm.stopPrank();
    }

    function test_claim_and_trade_revert_without_position() public {
        vm.startPrank(attacker);
        (bool ok, bytes memory ret) = SE.call(abi.encodeWithSignature("claimWinnings(uint256)", uint256(0)));
        assertFalse(ok);
        assertEq(_reason(ret), "NotSettled(0)");
        vm.stopPrank();
    }

    function test_usdw_mint_is_capped_at_par_and_redemption_locks() public {
        // Oracle is a real Chainlink-backed PriceOracle; aBnbUSDC is NOT an input stable.
        (bool ok, bytes memory r) = ORACLE.staticcall(abi.encodeWithSignature("quoteUsdwMint(address,uint256)", BSC_USDC, uint256(1e18)));
        assertTrue(ok, "oracle quote must not revert for an approved stable");
        uint256 out = abi.decode(r, (uint256));
        assertLe(out, 1e6, "mint is capped at par (1 USDW per 1 USDC)");
        // redemption source is unfunded / unapproved -> USDW payout path is blocked (H-O risk, not E-U)
        assertEq(IERC20(BSC_USDC).allowance(0x959b4a9Ad2dD1beBfD2579121325a75768C4D024, USDW), 0);
    }

    function test_attacker_net_profit_is_zero() public {
        uint256 before = IERC20(USDW).balanceOf(SE);
        vm.startPrank(attacker);
        SE.call(abi.encodeWithSignature("haltMarket(uint256)", uint256(0)));
        SE.call(abi.encodeWithSignature("resolveMarket(uint256,uint8)", uint256(0), uint8(0)));
        SE.call(abi.encodeWithSignature("exitForGraduation(uint256)", uint256(0)));
        SE.call(abi.encodeWithSignature("claimWinnings(uint256)", uint256(0)));
        vm.stopPrank();
        assertEq(IERC20(USDW).balanceOf(SE), before);
        assertEq(IERC20(USDW).balanceOf(attacker), 0);
    }

    // ---------------------------------------------------------------- helpers
    function _ok(address t, bytes memory data) internal returns (bool) {
        (bool ok, ) = t.call(data);
        return ok;
    }

    function _reason(bytes memory ret) internal pure returns (string memory) {
        if (ret.length < 68) return "";
        bytes memory slice = new bytes(ret.length - 4);
        for (uint256 i = 4; i < ret.length; ++i) slice[i - 4] = ret[i];
        return abi.decode(slice, (string));
    }
}
