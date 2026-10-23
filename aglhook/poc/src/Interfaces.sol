// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Minimal v4 / AGL interfaces for the AGLHook fork PoC. No secrets.

type Currency is address;
type BalanceDelta is int256;
type BeforeSwapDelta is int256;

struct PoolKey {
    Currency currency0;
    Currency currency1;
    uint24 fee;
    int24 tickSpacing;
    IHooks hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

interface IHooks {}

interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta);
    function sync(Currency currency) external;
    function settle() external payable returns (uint256);
    function take(Currency currency, address to, uint256 amount) external;
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function extsload(bytes32 slot) external view returns (bytes32);
    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24);
}

interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IAGLHook {
    function poolManager() external view returns (address);
    function agl() external view returns (address);
    function xautFundWallet() external view returns (address);
    function bound() external view returns (bool);
    function boundPool() external view returns (bytes32);
    function owed() external view returns (uint256);
    function feeBps(bool isBuy) external view returns (uint24);
    function feeExempt(address) external view returns (bool);
    function REQUIRED_FLAGS() external view returns (uint160);
    function claim() external;

    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (bytes4, BeforeSwapDelta, uint24);

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta swapDelta,
        bytes calldata hookData
    ) external returns (bytes4, int128);

    function unlockCallback(bytes calldata data) external returns (bytes memory);
}

library DeltaLib {
    function amount0(BalanceDelta d) internal pure returns (int128) {
        return int128(int256(BalanceDelta.unwrap(d)) >> 128);
    }

    function amount1(BalanceDelta d) internal pure returns (int128) {
        return int128(int256(BalanceDelta.unwrap(d)));
    }
}
