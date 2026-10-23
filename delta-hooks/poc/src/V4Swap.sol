// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal Uniswap v4 interfaces (hand-rolled so the PoC does not depend on v4-core in CI).

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (int256 balanceDelta);
    function sync(address currency) external;
    function settle() external payable returns (uint256 paid);
    function settleFor(address recipient) external payable returns (uint256 paid);
    function take(address currency, address to, uint256 amount) external;
    function extsload(bytes32 slot) external view returns (bytes32);
    function balanceOf(address owner, uint256 id) external view returns (uint256);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

library CurrencyDelta {
    // v4 packs a BalanceDelta into int256: high 128 bits = amount0, low 128 bits = amount1.
    function amount0(int256 d) internal pure returns (int128) {
        return int128(d >> 128);
    }

    function amount1(int256 d) internal pure returns (int128) {
        return int128(d);
    }
}

/// A minimal single-pool swapper. Calls PoolManager.unlock and performs one swap,
/// settling the input currency and taking the output currency.
contract V4Swapper {
    IPoolManager public constant PM_ETH = IPoolManager(0x000000000004444c5dc75cB358380D2e3dE08A90);
    IPoolManager public constant PM_BASE = IPoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);

    struct SwapCall {
        PoolKey key;
        bool zeroForOne;
        int256 amountSpecified;
        address recipient;
        bytes hookData;
    }

    event Dbg(int256 delta, int128 d0, int128 d1);

    /// Execute a swap paying with `payToken` (address(0) = native ETH) held by this contract.
    function swapExactIn(
        IPoolManager pm,
        PoolKey memory key,
        bool zeroForOne,
        uint256 amountIn,
        address recipient,
        bytes memory hookData
    ) public returns (int256 delta) {
        bytes memory data = abi.encode(SwapCall(key, zeroForOne, -int256(amountIn), recipient, hookData));
        return abi.decode(pm.unlock(data), (int256));
    }

    function unlockCallback(bytes calldata raw) external returns (bytes memory) {
        require(msg.sender == address(PM_ETH) || msg.sender == address(PM_BASE), "only pm");
        IPoolManager pm = IPoolManager(msg.sender);
        SwapCall memory c = abi.decode(raw, (SwapCall));

        int256 delta = pm.swap(c.key, SwapParams(c.zeroForOne, c.amountSpecified, _priceLimit(c.zeroForOne)), c.hookData);

        int128 d0 = CurrencyDelta.amount0(delta);
        int128 d1 = CurrencyDelta.amount1(delta);
        emit Dbg(delta, d0, d1);

        // settle the negative (owed by caller) side, take the positive (credit) side
        if (d0 < 0) _settle(pm, c.key.currency0, uint256(uint128(-d0)));
        if (d1 < 0) _settle(pm, c.key.currency1, uint256(uint128(-d1)));
        if (d0 > 0) pm.take(c.key.currency0, c.recipient, uint256(uint128(d0)));
        if (d1 > 0) pm.take(c.key.currency1, c.recipient, uint256(uint128(d1)));

        return abi.encode(delta);
    }

    function _priceLimit(bool zeroForOne) internal pure returns (uint160) {
        return zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341;
    }

    function _settle(IPoolManager pm, address currency, uint256 amount) internal {        if (currency == address(0)) {
            pm.settle{value: amount}();
        } else {
            pm.sync(currency);
            require(IERC20Min(currency).transfer(address(pm), amount), "pay");
            pm.settle();
        }
    }

    receive() external payable {}
}
