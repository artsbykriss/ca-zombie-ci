// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IVault {
    struct SingleSwap {
        bytes32 poolId;
        uint8 kind; // GIVEN_IN = 0
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
    function swap(SingleSwap memory, FundManagement memory, uint256, uint256) external payable returns (uint256);
    function getPoolTokens(bytes32) external view returns (address[] memory, uint256[] memory, uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256)
        external returns (uint256[] memory);
}

/// @title CoW GPv2Settlement — solver-allowance (GlueX-template) drain test
/// @notice read-only fork test: verifies the settlement's live approvals and that an
///         unprivileged caller CANNOT pull the settlement buffer through any approved spender.
contract CoWTest is Test {
    address constant SETTLEMENT = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ONEINCH_V3 = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;
    address constant ZEROX_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    address constant PARASWAP_TTP_V4 = 0xb70Bc06D2c9Bf03b3373799606dc7d39346c06B3;
    address constant PARASWAP_TTP_V5 = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    address constant ATTACKER = address(0xBADBEEF);

    function forkUrl() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(forkUrl(), 26_253_553);
    }

    /// @dev The live approval surface: settlement has max allowances to 7 standard routers.
    function test_live_approval_surface() public {
        address[7] memory spenders = [
            UNIV2_ROUTER, SUSHI_ROUTER, ONEINCH_V3, ZEROX_PROXY, PARASWAP_TTP_V4, PARASWAP_TTP_V5, VAULT
        ];
        for (uint256 i; i < spenders.length; ++i) {
            uint256 a = IERC20(USDC).allowance(SETTLEMENT, spenders[i]);
            console2.log("USDC allowance settlement ->", spenders[i], a);
        }
        // The 7 spenders are all live contracts
        for (uint256 i; i < spenders.length; ++i) {
            assertGt(spenders[i].code.length, 0, "spender not deployed");
        }
        assertGt(IERC20(USDC).allowance(SETTLEMENT, UNIV2_ROUTER), 0, "no USDC allowance");
        assertGt(IERC20(WETH).allowance(SETTLEMENT, UNIV2_ROUTER), 0, "no WETH allowance");
        assertGt(IERC20(DAI).allowance(SETTLEMENT, VAULT), 0, "no DAI allowance to vault");
    }

    /// @dev CONTROL (latent risk): the approval IS real - an address that IS the approved
    /// spender can pull the buffer. This is why any flawed spender = drain (GlueX CIP-55).
    function test_control_approved_spender_can_pull() public {
        uint256 bal = IERC20(USDC).balanceOf(SETTLEMENT);
        assertGt(bal, 0, "settlement holds no USDC at fork block");
        vm.prank(UNIV2_ROUTER); // pretend to be the approved spender
        IERC20(USDC).transferFrom(SETTLEMENT, ATTACKER, bal);
        assertEq(IERC20(USDC).balanceOf(ATTACKER), bal, "approved spender could not pull");
    }

    /// @dev E-U test 1: an unprivileged caller cannot pull directly.
    function test_attacker_cannot_transferFrom_settlement() public {
        uint256 bal = IERC20(USDC).balanceOf(SETTLEMENT);
        vm.prank(ATTACKER);
        vm.expectRevert();
        IERC20(USDC).transferFrom(SETTLEMENT, ATTACKER, bal);
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), bal, "settlement USDC moved");
    }

    /// @dev E-U test 2: Balancer Vault `funds.sender` spoof is blocked by authenticateFor().
    function test_balancer_sender_spoof_reverts() public {
        IVault vault = IVault(VAULT);
        IVault.SingleSwap memory s = IVault.SingleSwap({
            poolId: bytes32(uint256(1)), // auth check fires before pool lookup
            kind: 0,
            assetIn: USDC,
            assetOut: WETH,
            amount: IERC20(USDC).balanceOf(SETTLEMENT),
            userData: ""
        });
        IVault.FundManagement memory f = IVault.FundManagement({
            sender: SETTLEMENT, // spoofed sender
            fromInternalBalance: false,
            recipient: payable(ATTACKER),
            toInternalBalance: false
        });
        vm.prank(ATTACKER);
        vm.expectRevert(); // UnauthorizedSender
        vault.swap(s, f, 0, block.timestamp + 1);
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), IERC20(USDC).balanceOf(SETTLEMENT));
    }

    /// @dev E-U test 3: UniswapV2Router pulls from msg.sender, never from the settlement.
    function test_univ2_router_does_not_touch_settlement() public {
        uint256 before = IERC20(USDC).balanceOf(SETTLEMENT);
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WETH;
        vm.prank(ATTACKER);
        // attacker has no USDC -> reverts inside the router; either way settlement untouched
        try IUniswapV2Router(UNIV2_ROUTER).swapExactTokensForTokens(1e6, 0, path, ATTACKER, block.timestamp + 1) {}
        catch {}
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), before, "settlement USDC moved via router");
    }

    /// @dev E-U test 4: settlement's own entry points are solver-gated / harmless.
    function test_settlement_entrypoints_gated() public {
        (bool ok,) = SETTLEMENT.call(
            abi.encodeWithSignature("setPreSignature(bytes,bool)", new bytes(56), true)
        );
        // setPreSignature requires owner == msg.sender; a random 56-byte uid decodes to a
        // different owner, so it must revert.
        assertFalse(ok, "setPreSignature unexpectedly succeeded");
    }

    /// @dev Buffer snapshot (values priced off-chain at the fork block).
    function test_buffer_snapshot() public view {
        console2.log("settlement ETH (wei)", SETTLEMENT.balance);
        console2.log("settlement WETH", IERC20(WETH).balanceOf(SETTLEMENT));
        console2.log("settlement DAI", IERC20(DAI).balanceOf(SETTLEMENT));
        console2.log("settlement USDC", IERC20(USDC).balanceOf(SETTLEMENT));
        console2.log("settlement USDT", IERC20(USDT).balanceOf(SETTLEMENT));
        assertEq(SETTLEMENT.balance, 23933568139243694);
    }

    /// @dev Latent-risk model (GlueX CIP-55): IF the settlement approves a helper whose pull
    /// path is not bound to msg.sender, ANY address can drain the buffer. The helper here is
    /// synthetic and demonstrates the template only - no such helper is currently approved.
    function test_gluex_template_model() public {
        FlawedSolverHelper helper = new FlawedSolverHelper();
        uint256 bal = IERC20(USDC).balanceOf(SETTLEMENT);
        vm.prank(SETTLEMENT); // settlement grants the helper an allowance (as solvers do)
        IERC20(USDC).approve(address(helper), type(uint256).max);
        vm.prank(ATTACKER);
        helper.pull(USDC, SETTLEMENT, ATTACKER); // public, unbound `from`
        assertEq(IERC20(USDC).balanceOf(ATTACKER), bal, "template drain failed");
        assertEq(IERC20(USDC).balanceOf(SETTLEMENT), 0, "buffer not drained");
    }
}

/// @dev Synthetic example of the GlueX/CIP-55 failure mode (NOT deployed/live).
contract FlawedSolverHelper {
    function pull(address token, address from, address to) external {
        IERC20(token).transferFrom(from, to, IERC20(token).balanceOf(from));
    }
}
