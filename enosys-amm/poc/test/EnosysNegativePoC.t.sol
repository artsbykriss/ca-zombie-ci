// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IPool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1);
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external
        returns (int256 amount0, int256 amount1);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external
        returns (uint128 amount0, uint128 amount1);
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface INPM {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function ownerOf(uint256 tokenId) external view returns (address);
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

interface IFactory {
    function owner() external view returns (address);
    function protocolFeeReceiver() external view returns (address);
    function setPoolImplementation(address) external;
    function collectProtocolFees(uint256 startPoolIndex, uint256 count) external;
    function collectProtocolFeesAll() external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

/// @notice Attacker contract that implements the three pool callbacks but never pays.
contract NonPayingAttacker {
    function mintNoPay(address pool, int24 lower, int24 upper, uint128 liq) external {
        IPool(pool).mint(address(this), lower, upper, liq, "");
    }

    function swapNoPay(address pool, bool zeroForOne, int256 amountSpecified, uint160 limit) external {
        IPool(pool).swap(address(this), zeroForOne, amountSpecified, limit, "");
    }

    function flashNoRepay(address pool, uint256 amount0, uint256 amount1) external {
        IPool(pool).flash(address(this), amount0, amount1, "");
    }

    function enosysdexV3MintCallback(uint256, uint256, bytes calldata) external {}
    function enosysdexV3SwapCallback(int256, int256, bytes calldata) external {}
    function enosysdexV3FlashCallback(uint256, uint256, bytes calldata) external {}

    receive() external payable {}
}

contract EnosysNegativePoC is Test {
    // Flare mainnet, block 72,382,727 (2026-10-18), read-only fork.
    address constant FACTORY = 0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de;
    address constant NPM = 0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657;
    // WFLR / USDT0 0.30% pool; the deepest active pool at the snapshot block.
    address constant POOL = 0x3C2a7B76795E58829FAAa034486D417dd0155162;
    address constant WFLR = 0x1D80c49BbBCd1C0911346656B529DF9E5c2F783d;
    address constant ATTACKER_EOA = address(0xBEEF);

    NonPayingAttacker attacker;

    function setUp() public {
        string memory rpc = vm.envOr("FLARE_RPC", string("https://flare-api.flare.network/ext/C/rpc"));
        uint256 forkBlock = vm.envOr("FLARE_BLOCK", uint256(72_382_727));
        vm.createSelectFork(rpc, forkBlock);
        attacker = new NonPayingAttacker();
    }

    /// @dev mint() calls the callback before checking the balance delta. A callback that does
    ///      not pay must make the pool revert on its post-callback balance check.
    function test_mint_without_payment_reverts() public {
        (, int24 tick,,,,,) = IPool(POOL).slot0();
        int24 lower = ((tick - 600) / 60) * 60;
        int24 upper = ((tick + 600) / 60) * 60;
        vm.expectRevert();
        attacker.mintNoPay(POOL, lower, upper, 1e18);
    }

    /// @dev swap() transfers the output before the callback; a no-pay callback must revert
    ///      on the input balance check (IIA), so the transfer is rolled back.
    function test_swap_without_payment_reverts() public {
        vm.expectRevert();
        attacker.swapNoPay(POOL, true, -int256(1e6), 4295128740);
    }

    /// @dev flash() transfers the borrowed amount before the callback; no repayment must
    ///      revert on F0/F1 and roll the transfer back.
    function test_flash_without_repayment_reverts() public {
        vm.expectRevert();
        attacker.flashNoRepay(POOL, 1e6, 0);
    }

    /// @dev collect() is owner-gated. Token 1 is owned by 0x2417c9a1... at the fork block.
    function test_npm_collect_not_owner_reverts() public {
        address owner = INPM(NPM).ownerOf(1);
        assertTrue(owner != ATTACKER_EOA);
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("Not approved"));
        INPM(NPM).collect(INPM.CollectParams(1, ATTACKER_EOA, type(uint128).max, type(uint128).max));
    }

    /// @dev collectProtocol() is onlyFactoryOrFactoryOwner.
    function test_pool_collectProtocol_not_authorized() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("NA"));
        IPool(POOL).collectProtocol(ATTACKER_EOA, type(uint128).max, type(uint128).max);
    }

    /// @dev setFeeProtocol() is onlyFactoryOrFactoryOwner.
    function test_pool_setFeeProtocol_not_authorized() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("NA"));
        IPool(POOL).setFeeProtocol(10, 10);
    }

    /// @dev The factory owner is the 2/6 Safe; a random EOA cannot change the implementation.
    function test_factory_admin_not_authorized() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("EnosysDexV3Factory: Caller is not the factory owner"));
        IFactory(FACTORY).setPoolImplementation(ATTACKER_EOA);
    }

    /// @dev collectProtocolFees is permissionless, but the recipient is the fixed
    ///      protocolFeeReceiver (ProfitDistribution), not the caller.
    function test_collectProtocolFees_is_permissionless_but_fixed_recipient() public {
        address receiver = IFactory(FACTORY).protocolFeeReceiver();
        assertTrue(receiver != address(0));
        assertTrue(receiver != ATTACKER_EOA);
        vm.prank(ATTACKER_EOA);
        IFactory(FACTORY).collectProtocolFees(0, 1);
    }

    /// @dev Structural checks on the live pool.
    function test_live_pool_state() public {
        assertEq(IPool(POOL).factory(), FACTORY);
        assertEq(IPool(POOL).fee(), 3000);
        (uint160 sqrtPriceX96, int24 tick,,,,, bool unlocked) = IPool(POOL).slot0();
        assertGt(sqrtPriceX96, 0);
        assertTrue(unlocked);
        assertGt(tick, -887272);
        assertLt(tick, 887272);
        assertGt(IPool(POOL).liquidity(), 0);
        assertGt(IERC20(WFLR).balanceOf(POOL), 0);
    }
}
