// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev Minimal v4-core type/interface surface used by the PoC. Byte-identical ABI to
///      Uniswap v4-core (PoolKey, SwapParams, BalanceDelta as int256, IPoolManager selectors).
type Currency is address;

struct PoolKey {
    Currency currency0;
    Currency currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

interface IPoolManagerMin {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData) external returns (int256);
    function sync(Currency currency) external;
    function settle() external payable returns (uint256);
    function take(Currency currency, address to, uint256 amount) external;
    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// @dev Minimal surface of the StablePairHook/VolatilePairHook proxy (as verified on Etherscan).
interface IDynamicFeeHookMin {
    function poolManager() external view returns (address);
    function getHookPermissions()
        external
        pure
        returns (
            bool beforeInitialize,
            bool afterInitialize,
            bool beforeAddLiquidity,
            bool afterAddLiquidity,
            bool beforeRemoveLiquidity,
            bool afterRemoveLiquidity,
            bool beforeSwap,
            bool afterSwap,
            bool beforeDonate,
            bool afterDonate,
            bool beforeSwapReturnDelta,
            bool afterSwapReturnDelta,
            bool afterAddLiquidityReturnDelta,
            bool afterRemoveLiquidityReturnDelta
        );
    function getFee(PoolKey calldata key) external view returns (uint24 feeE6ZeroForOne, uint24 feeE6OneForZero);
    function initializePool(PoolKey calldata poolKey, uint160 sqrtPriceX96, bytes calldata feeConfig)
        external
        returns (int24);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function POOL_INITIALIZER_ROLE() external view returns (bytes32);
    function CONFIG_MANAGER_ROLE() external view returns (bytes32);
    function updateFeeConfig(bytes32 poolId, bytes calldata feeConfig) external;
}
