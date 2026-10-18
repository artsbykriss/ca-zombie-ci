// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IPool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external returns (uint256 amount0, uint256 amount1);
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external returns (int256 amount0, int256 amount1);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external returns (uint128 amount0, uint128 amount1);
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

interface INPM {
    struct CollectParams { uint256 tokenId; address recipient; uint128 amount0Max; uint128 amount1Max; }
    function ownerOf(uint256 tokenId) external view returns (address);
    function collect(CollectParams calldata params) external payable returns (uint256, uint256);
    function burn(uint256 tokenId) external payable returns (uint256, uint256);
}

interface IFactory {
    function owner() external view returns (address);
    function governor() external view returns (address);
    function protocolFeeReceiver() external view returns (address);
    function poolsCount() external view returns (uint256);
    function setPoolImplementation(address) external;
    function transferOwnership(address) external;
    function setGovernor(address) external;
    function collectProtocolFees(uint256 startPoolIndex, uint256 count) external;
}

interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

interface IERC20 { function balanceOf(address) external view returns (uint256); }

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
    address constant FACTORY = 0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de;
    address constant NPM = 0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657;
    address constant POOL = 0x3C2a7B76795E58829FAAa034486D417dd0155162;
    address constant WFLR = 0x1D80c49BbBCd1C0911346656B529DF9E5c2F783d;
    address constant SAFE = 0xDEddA08961216adB9Ca09B88986d110127b24270;
    address constant ATTACKER_EOA = address(0xBEEF);
    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address constant EXPECTED_POOL_IMPL = 0x23F02a41dEa4fE6180b8e4AA56A745EA1ba4A88E;

    NonPayingAttacker attacker;

    function setUp() public {
        string memory rpc = vm.envOr("FLARE_RPC", string("https://flare-api.flare.network/ext/C/rpc"));
        uint256 forkBlock = vm.envOr("FLARE_BLOCK", uint256(0));
        // Default 0 = latest (public RPCs are not full archive). Set FLARE_BLOCK=72386500
        // to replay the pinned 2026-10-18 state where the RPC retains it.
        if (forkBlock == 0) vm.createSelectFork(rpc); else vm.createSelectFork(rpc, forkBlock);
        attacker = new NonPayingAttacker();
    }

    function test_mint_without_payment_reverts() public {
        (, int24 tick,,,,,) = IPool(POOL).slot0();
        int24 lower = ((tick - 600) / 60) * 60;
        int24 upper = ((tick + 600) / 60) * 60;
        vm.expectRevert();
        attacker.mintNoPay(POOL, lower, upper, 1e18);
    }

    function test_swap_without_payment_reverts() public {
        vm.expectRevert();
        attacker.swapNoPay(POOL, true, -int256(1e6), 4295128740);
    }

    function test_flash_without_repayment_reverts() public {
        vm.expectRevert();
        attacker.flashNoRepay(POOL, 1e6, 0);
    }

    function test_npm_collect_not_owner_reverts() public {
        address owner = INPM(NPM).ownerOf(1);
        assertTrue(owner != ATTACKER_EOA);
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("Not approved"));
        INPM(NPM).collect(INPM.CollectParams(1, ATTACKER_EOA, type(uint128).max, type(uint128).max));
    }

    function test_npm_burn_not_owner_reverts() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("Not approved"));
        INPM(NPM).burn(1);
    }

    function test_pool_collectProtocol_not_authorized() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("NA"));
        IPool(POOL).collectProtocol(ATTACKER_EOA, type(uint128).max, type(uint128).max);
    }

    function test_pool_setFeeProtocol_not_authorized() public {
        vm.prank(ATTACKER_EOA);
        vm.expectRevert(bytes("NA"));
        IPool(POOL).setFeeProtocol(10, 10);
    }

    function test_factory_admin_not_authorized() public {
        vm.startPrank(ATTACKER_EOA);
        vm.expectRevert(bytes("EnosysDexV3Factory: Caller is not the factory owner"));
        IFactory(FACTORY).setPoolImplementation(ATTACKER_EOA);
        vm.expectRevert(bytes("EnosysDexV3Factory: Caller is not the factory owner"));
        IFactory(FACTORY).transferOwnership(ATTACKER_EOA);
        vm.expectRevert(bytes("EnosysDexFactory: Forbidden"));
        IFactory(FACTORY).setGovernor(ATTACKER_EOA);
        vm.stopPrank();
    }

    function test_collectProtocolFees_is_permissionless_but_fixed_recipient() public {
        address receiver = IFactory(FACTORY).protocolFeeReceiver();
        assertTrue(receiver != address(0));
        assertTrue(receiver != ATTACKER_EOA);
        vm.prank(ATTACKER_EOA);
        IFactory(FACTORY).collectProtocolFees(0, 1);
    }

    function test_flare_pool_count_and_impl() public {
        assertEq(IFactory(FACTORY).poolsCount(), 106);
        assertEq(address(uint160(uint256(vm.load(POOL, IMPL_SLOT)))), EXPECTED_POOL_IMPL);
        assertEq(IPool(POOL).factory(), FACTORY);
        assertEq(IPool(POOL).fee(), 3000);
    }

    function test_safe_is_2_of_6() public {
        assertEq(ISafe(SAFE).getThreshold(), 2);
        assertEq(ISafe(SAFE).getOwners().length, 6);
        assertEq(IFactory(FACTORY).owner(), SAFE);
        assertEq(IFactory(FACTORY).governor(), SAFE);
    }

    function test_songbird_pool_count_and_owner() public {
        vm.createSelectFork(vm.envOr("SONGBIRD_RPC", string("https://songbird-api.flare.network/ext/C/rpc")));
        address sf = 0x416F1CcBc55033Ae0133DA96F9096Fe8c2c17E7d;
        assertEq(IFactory(sf).poolsCount(), 62);
        assertEq(IFactory(sf).owner(), 0x68d0818bb30B340aD99994592a88a3095e47522f);
        assertEq(IFactory(sf).governor(), 0x68d0818bb30B340aD99994592a88a3095e47522f);
    }

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
