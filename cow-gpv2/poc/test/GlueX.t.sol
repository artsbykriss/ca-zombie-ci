// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// @notice Implements the Uniswap V3 pool surface a solver helper may read from msg.sender.
contract EvilPool {
    address public immutable t0;
    address public immutable t1;
    uint24 public constant fee_ = 3000;

    constructor(address _t0, address _t1) {
        t0 = _t0;
        t1 = _t1;
    }

    function token0() external view returns (address) { return t0; }
    function token1() external view returns (address) { return t1; }
    function fee() external view returns (uint24) { return fee_; }

    /// @dev Call the helper's V3 callback directly, impersonating a pool (msg.sender = this).
    function attack(address helper, address payer, int256 a0, int256 a1)
        external
        returns (bool ok, bytes memory ret)
    {
        (ok, ret) = helper.call(
            abi.encodeWithSignature("uniswapV3SwapCallback(int256,int256,bytes)", a0, a1, abi.encode(payer))
        );
    }

    function attackRaw(address helper, bytes calldata payload) external returns (bool ok, bytes memory ret) {
        (ok, ret) = helper.call(payload);
    }
}

/// @title CoW GPv2Settlement — GlueX/CIP-55 solver-allowance drain (fork PoC)
/// @notice The settlement holds LIVE max allowances to many solver helper contracts (a strictly
///         larger surface than pass5 reported). This suite tests whether any is drainable by an
///         unprivileged caller via a direct (unrestricted) swap callback - i.e. the GlueX vector.
///         Result: NONE drainable. All tested callbacks are guarded / payer is msg.sender-bound.
contract GlueXTest is Test {
    address constant SETTLEMENT = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;

    // Solver helper contracts with LIVE max allowances from the settlement (see analysis/):
    address constant HELPER_1d94 = 0x1d94BedCb3641ba060091eD090D28BbdcCDb7f1D; // generic V3/V2 swap router
    address constant HELPER_0500 = 0x0500001fDe3800757d9fc800003d10B8004A11aC; // generic swap router
    address constant HELPER_COWEXEC = 0x2FbB05d206c2E8A50B2959EEE7d8C5f0F64e40e9; // CowExecutor

    bytes4 constant UNAUTHORIZED = 0x82b42900;

    function forkUrl() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(forkUrl(), 26_253_971);
    }

    /// @dev The live approval surface to solver helpers is real and max-sized.
    function test_helper_allowances_are_live() public view {
        assertGt(IERC20(USDC).allowance(SETTLEMENT, HELPER_1d94), 0, "no USDC allow 1d94");
        assertGt(IERC20(WBTC).allowance(SETTLEMENT, HELPER_1d94), 0, "no WBTC allow 1d94");
        assertGt(IERC20(DAI).allowance(SETTLEMENT, HELPER_1d94), 0, "no DAI allow 1d94");
        assertGt(IERC20(USDC).allowance(SETTLEMENT, HELPER_0500), 0, "no USDC allow 0500");
        assertGt(IERC20(DAI).allowance(SETTLEMENT, HELPER_0500), 0, "no DAI allow 0500");
        console2.log("USDC allow 1d94", IERC20(USDC).allowance(SETTLEMENT, HELPER_1d94));
        console2.log("DAI  allow 0500", IERC20(DAI).allowance(SETTLEMENT, HELPER_0500));
        console2.log("settlement USDC", IERC20(USDC).balanceOf(SETTLEMENT));
    }

    /// @dev NEGATIVE: helper 0x1d94bedc validates msg.sender is a real V3 pool.
    function test_helper_1d94_callback_is_guarded() public {
        uint256 before = IERC20(USDC).balanceOf(SETTLEMENT);
        EvilPool evil = new EvilPool(USDC, USDC); // fake pool, not a real V3 pool
        (bool ok, bytes memory ret) = evil.attack(HELPER_1d94, SETTLEMENT, int256(before), int256(0));
        assertFalse(ok, "fake-pool callback unexpectedly succeeded");
        console2.log("1d94 revert data:");
        console2.logBytes(ret);
        // revert reason observed on-chain: "UNIV3R: bad pool" (Error(string))
        assertEq(ret.length, 84, "unexpected revert payload");
        bytes memory reason = new bytes(16);
        for (uint256 i; i < 16; ++i) reason[i] = ret[68 + i];
        assertEq(keccak256(reason), keccak256(bytes("UNIV3R: bad pool")), "unexpected revert reason");
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), before, "settlement USDC moved");
        assertEq(IERC20(USDC).balanceOf(address(evil)), 0, "attacker received USDC");
    }

    /// @dev NEGATIVE: helper 0x0500001f's V3 callback does not drain when called directly.
    function test_helper_0500_callback_does_not_drain() public {
        uint256 beforeU = IERC20(USDC).balanceOf(SETTLEMENT);
        uint256 beforeD = IERC20(DAI).balanceOf(SETTLEMENT);
        EvilPool evil = new EvilPool(USDC, USDC);
        (bool ok, bytes memory ret) = evil.attackRaw(
            HELPER_0500,
            abi.encodeWithSignature(
                "uniswapV3SwapCallback(int256,int256,bytes)",
                int256(beforeU),
                int256(0),
                abi.encodePacked(uint8(1), USDC) // 21-byte token descriptor, matches on-chain trace
            )
        );
        console2.log("0500 direct-callback ok", ok);
        console2.logBytes(ret);
        assertFalse(ok, "direct callback unexpectedly succeeded");
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), beforeU, "settlement USDC moved");
        assertEq(IERC20(DAI).balanceOf(SETTLEMENT), beforeD, "settlement DAI moved");
        assertEq(IERC20(USDC).balanceOf(address(evil)), 0, "attacker received USDC");
    }

    /// @dev NEGATIVE: CowExecutor's value-moving entries are onlyCowSettlementContract().
    function test_cowexecutor_entrypoints_guarded() public {
        uint256 before = IERC20(USDC).balanceOf(SETTLEMENT);
        (bool ok,) = HELPER_COWEXEC.call(
            abi.encodeWithSignature("guardedUncheckedCall(address,bytes)", USDC, bytes(""))
        );
        assertFalse(ok, "CowExecutor.guardedUncheckedCall callable by attacker");
        (bool ok2,) = HELPER_COWEXEC.call(
            abi.encodeWithSignature(
                "guardedUnlimitedApprovedInteractionCall(uint256,address,address,address,address,bytes)",
                uint256(0), USDC, USDC, USDC, USDC, bytes("")
            )
        );
        assertFalse(ok2, "CowExecutor.guardedUnlimitedApprovedInteractionCall callable by attacker");
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), before, "settlement USDC moved");
    }

    /// @dev NEGATIVE: a direct transferFrom by the attacker is rejected.
    function test_attacker_direct_transferFrom_reverts() public {
        uint256 before = IERC20(USDC).balanceOf(SETTLEMENT);
        vm.prank(address(0xBAD));
        vm.expectRevert();
        IERC20(USDC).transferFrom(SETTLEMENT, address(0xBAD), before);
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), before, "settlement USDC moved");
    }
}
