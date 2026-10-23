// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {
    IERC20, IUniswapV3Factory, IUniswapV3Pool, INonfungiblePositionManager
} from "../src/Interfaces.sol";

interface IPointsRedemption {
    function claim(uint16 eventId, uint16 userRedemptionId, address tokenAddress, uint256 amount, bytes calldata signature) external;
    function withdrawRemainingToken(uint16 eventId, address tokenAddress) external;
    function owner() external view returns (address);
    function globalSigner() external view returns (address);
}

/// @title BulbaSwap V3 (Morph L2) — unprivileged-extraction recon PoC/// @notice READ-ONLY research. Fork-only; no mainnet transaction is ever sent.
///         Everything below runs against a pinned Morph block via vm.createSelectFork.
contract BulbaV3Test is Test {
    // ---- pinned target state (Morph L2, chainId 2818) ----
    uint256 constant FORK_BLOCK = 28_699_967;

    address constant FACTORY = 0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD;
    address constant NPM = 0xC6B60EE77854b7c11c39b6E3f5BCfe1866cbC20A;
    address constant SWAP_ROUTER02 = 0xa7304d322219553d4A85c9cE8eB7462Dcaf6453C;
    address constant V3_MIGRATOR = 0xe87c01ca304d69a94c4E079275B276BE659EE5eF;
    address constant STAKER = 0x192122E28E45923cAbdcC40232a278867a432C2b;
    address constant POINTS_REDEMPTION = 0xdbd064f9E41dB9F08cb9F481C72a2EEb29AFC9A4;
    address constant FACTORY_OWNER_SAFE = 0x9876097201662D70A63C935c2f7576B35D6f45e7;

    address constant WETH = 0x5300000000000000000000000000000000000011;
    address constant USDT = 0xc7D67A9cBB121b3b0b9c053DD9f469523243379A;

    // top pool by TVL: WETH/USDT 0.05% (~$2.53M at the pinned block)
    address constant POOL_WETH_USDT_500 = 0x5191035D329f481eFf0143e690e0a4e366Dd1e0c;

    // canonical Uniswap v3-core v1.0.0 POOL_INIT_CODE_HASH
    bytes32 constant CANONICAL_POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    // a foreign position with liquidity > 0, owned by a third party (WETH/MOOD 0.3%)
    uint256 constant FOREIGN_TOKEN_ID = 1500;

    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork("https://rpc.morphl2.io", FORK_BLOCK);
    }

    // ------------------------------------------------------------------
    // 1. deployed code is byte-for-byte canonical Uniswap V3
    // ------------------------------------------------------------------

    /// The pool's CREATE2 address is derived from the *canonical* init-code hash.
    /// If it matches the factory's getPool(), the deployed pool bytecode IS canonical.
    function test_poolInitCode_isCanonicalUniswapV3() public view {
        address derived = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            FACTORY,
                            keccak256(abi.encode(WETH, USDT, uint24(500))),
                            CANONICAL_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
        assertEq(
            derived,
            IUniswapV3Factory(FACTORY).getPool(WETH, USDT, 500),
            "pool address does not derive from canonical init code hash"
        );
        console.log("canonical POOL_INIT_CODE_HASH reproduces pool", derived);
    }

    /// skim() does not exist in Uniswap v3-core v1.0.0 -> selector 0xbc25cf77 absent.
    function test_skimSelector_absentFromDeployedPool() public view {
        bytes memory code = POOL_WETH_USDT_500.code;
        bool found;
        for (uint256 i = 0; i + 4 <= code.length; i++) {
            if (
                code[i] == 0xbc && code[i + 1] == 0x25 && code[i + 2] == 0xcf && code[i + 3] == 0x77
            ) {
                found = true;
                break;
            }
        }
        assertFalse(found, "skim selector present (unexpected for v1.0.0)");
        console.log("skim() selector 0xbc25cf77 absent -> no skim path exists");
    }

    function test_factoryState_isCanonical() public view {
        assertEq(IUniswapV3Factory(FACTORY).owner(), FACTORY_OWNER_SAFE);
        assertEq(IUniswapV3Factory(FACTORY).feeAmountTickSpacing(100), 1);
        assertEq(IUniswapV3Factory(FACTORY).feeAmountTickSpacing(500), 10);
        assertEq(IUniswapV3Factory(FACTORY).feeAmountTickSpacing(3000), 60);
        assertEq(IUniswapV3Factory(FACTORY).feeAmountTickSpacing(10000), 200);
    }

    function test_topPool_holdsTVL_butIsLockedCanonical() public view {
        IUniswapV3Pool p = IUniswapV3Pool(POOL_WETH_USDT_500);
        assertEq(p.token0(), WETH);
        assertEq(p.token1(), USDT);
        assertEq(p.fee(), 500);
        (,, , , , , bool unlocked) = p.slot0();
        assertTrue(unlocked);
        uint256 b0 = IERC20(WETH).balanceOf(POOL_WETH_USDT_500);
        uint256 b1 = IERC20(USDT).balanceOf(POOL_WETH_USDT_500);
        console.log("pool WETH wei:", b0);
        console.log("pool USDT units:", b1);
        assertGt(b0, 0);
        assertGt(b1, 0);
    }

    // ------------------------------------------------------------------
    // 2. NPM position auth — foreign positions are not collectable
    // ------------------------------------------------------------------

    function test_foreignPosition_ownerIsThirdParty() public view {
        assertEq(INonfungiblePositionManager(NPM).ownerOf(FOREIGN_TOKEN_ID), 0x8557acFc9BE0183a21f02372AbCf0c1541f6b5fB);
        (,, , , , , , uint128 liq,,, ,) =
            INonfungiblePositionManager(NPM).positions(FOREIGN_TOKEN_ID);
        assertGt(liq, 0);
    }

    function test_collectForeignPosition_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not approved"));
        INonfungiblePositionManager(NPM).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: FOREIGN_TOKEN_ID,
                recipient: attacker,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function test_decreaseLiquidityForeign_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not approved"));
        INonfungiblePositionManager(NPM).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: FOREIGN_TOKEN_ID,
                liquidity: 1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
    }

    function test_burnForeign_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not approved"));
        INonfungiblePositionManager(NPM).burn(FOREIGN_TOKEN_ID);
    }

    function test_increaseLiquidity_isPermissionless_butAddsOnly() public {
        // v1.0.0 NonfungiblePositionManager.increaseLiquidity has NO owner check:
        // anyone may add liquidity to any position, but the tokens added come FROM the
        // caller, so it can never move value out of the position.
        uint256 before0 = IERC20(WETH).balanceOf(NPM);
        uint256 before1 = IERC20(USDT).balanceOf(NPM);
        vm.prank(attacker);
        (bool ok,) = NPM.call(
            abi.encodeWithSelector(
                INonfungiblePositionManager.increaseLiquidity.selector,
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: FOREIGN_TOKEN_ID,
                    amount0Desired: 1 ether,
                    amount1Desired: 1_000_000,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            )
        );
        // reverts only because the caller must implement uniswapV3MintCallback to pay
        assertFalse(ok);
        assertEq(IERC20(WETH).balanceOf(NPM), before0);
        assertEq(IERC20(USDT).balanceOf(NPM), before1);
    }

    // ------------------------------------------------------------------
    // 3. flash loan: callback + repayment + reentrancy lock
    // ------------------------------------------------------------------

    bool internal reentrancyBlocked;
    bool internal repayFlash = true;
    uint256 internal flashAmount0;

    function uniswapV3FlashCallback(uint256 fee0, uint256, bytes calldata) external {
        // attempt to reenter the pool while it is locked
        (bool ok,) = msg.sender.call(
            abi.encodeWithSelector(
                IUniswapV3Pool.swap.selector,
                address(this),
                true,
                int256(1),
                uint160(0),
                bytes("")
            )
        );
        reentrancyBlocked = !ok;
        if (repayFlash) {
            IERC20(WETH).transfer(msg.sender, flashAmount0 + fee0);
        }
        // if repayFlash == false the outer call must revert with F0
    }

    function test_flash_reentrancyBlockedByLock() public {
        deal(WETH, address(this), 10 ether);
        flashAmount0 = 1 ether;
        repayFlash = true;
        IUniswapV3Pool(POOL_WETH_USDT_500).flash(address(this), flashAmount0, 0, bytes(""));
        assertTrue(reentrancyBlocked, "reentrancy into locked pool was NOT blocked");
    }

    function test_flash_repaymentRequired() public {
        deal(WETH, address(this), 10 ether);
        flashAmount0 = 1 ether;
        repayFlash = false;
        vm.expectRevert(bytes("F0"));
        IUniswapV3Pool(POOL_WETH_USDT_500).flash(address(this), flashAmount0, 0, bytes(""));
    }

    // ------------------------------------------------------------------
    // 4. privileged paths are owner-only (P, not E-U)
    // ------------------------------------------------------------------

    function test_collectProtocol_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUniswapV3Pool(POOL_WETH_USDT_500).collectProtocol(attacker, 1, 1);
    }

    function test_setFeeProtocol_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUniswapV3Pool(POOL_WETH_USDT_500).setFeeProtocol(0, 0);
    }

    function test_factory_setOwner_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUniswapV3Factory(FACTORY).setOwner(attacker);
    }

    function test_factory_enableFeeAmount_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUniswapV3Factory(FACTORY).enableFeeAmount(1234, 5);
    }

    // ------------------------------------------------------------------
    // 5. public sweep primitives exist but hold nothing
    // ------------------------------------------------------------------

    function test_npm_sweepToken_isPublicButEmpty() public {
        assertEq(IERC20(WETH).balanceOf(NPM), 0);
        assertEq(IERC20(USDT).balanceOf(NPM), 0);
        uint256 before = IERC20(USDT).balanceOf(attacker);
        vm.prank(attacker);
        INonfungiblePositionManager(NPM).sweepToken(USDT, 0, attacker); // permissionless
        assertEq(IERC20(USDT).balanceOf(attacker), before);
        console.log("NPM.sweepToken callable by anyone but NPM balance is 0 -> $0");
    }

    function test_swapRouter_sweepToken_isPublicButEmpty() public {
        // SwapRouter02 inherits PeripheryPayments: sweepToken/unwrapWETH9/refundETH are public
        assertEq(IERC20(WETH).balanceOf(SWAP_ROUTER02), 0);
        assertEq(IERC20(USDT).balanceOf(SWAP_ROUTER02), 0);
    }

    // ------------------------------------------------------------------
    // 6. oracle: cardinality 1 (no TWAP), permissionless griefing only
    // ------------------------------------------------------------------

    function test_observe_reverts_beyondLastObservation() public {
        // observationCardinality == 1 on ALL 212 pools: only the most recent
        // observation is retained, so any historical window reverts 'OLD'.
        uint32[] memory ago = new uint32[](2);
        ago[0] = 0;
        ago[1] = 3600;
        vm.expectRevert(bytes("OLD"));
        IUniswapV3Pool(POOL_WETH_USDT_500).observe(ago);
    }

    function test_increaseObservationCardinalityNext_isPermissionless_griefOnly() public {
        (,,,, uint16 cardNext,,) = IUniswapV3Pool(POOL_WETH_USDT_500).slot0();
        vm.prank(attacker);
        IUniswapV3Pool(POOL_WETH_USDT_500).increaseObservationCardinalityNext(cardNext + 10);
        (,,,, uint16 afterNext,,) = IUniswapV3Pool(POOL_WETH_USDT_500).slot0();
        assertEq(afterNext, cardNext + 10); // anyone can raise it; no value accrues to caller
        console.log("cardinalityNext griefed from", cardNext, "to", afterNext);
    }

    // ------------------------------------------------------------------
    // 7. peripheral live contracts hold no extractable value
    // ------------------------------------------------------------------

    function test_staker_isEmpty_andUnused() public view {
        assertEq(IERC20(WETH).balanceOf(STAKER), 0);
        assertEq(IERC20(USDT).balanceOf(STAKER), 0);
        assertEq(V3_MIGRATOR.balance, 0);
    }

    function test_pointsRedemption_claimRequiresSignature() public {
        vm.prank(attacker);
        vm.expectRevert(); // ECDSA: invalid signature / Invalid signature
        IPointsRedemption(POINTS_REDEMPTION).claim(5, 1, USDT, 1, bytes(""));
    }

    function test_pointsRedemption_withdraw_nonOwner_reverts() public {
        vm.prank(attacker);
        (bool ok,) = POINTS_REDEMPTION.call(
            abi.encodeWithSignature("withdrawRemainingToken(uint16,address)", uint16(5), USDT)
        );
        assertFalse(ok, "non-owner withdraw succeeded");
    }
}
