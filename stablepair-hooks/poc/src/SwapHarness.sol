// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManagerMin, PoolKey, SwapParams, Currency, IERC20Min} from "./V4Minimal.sol";

/// @notice Minimal, self-contained v4 swap harness. Calls PoolManager.unlock -> swap and settles
///         the input / takes the output inside unlockCallback. Used to measure the LP fee the
///         StablePairHook actually applies (read from the PoolManager `Swap` event) and the
///         attacker's net token PnL. Read-only fork use only; never broadcast.
contract SwapHarness {
    IPoolManagerMin public immutable pm;

    constructor(IPoolManagerMin _pm) {
        pm = _pm;
    }

    /// @notice Execute one exact-in swap; returns the caller-perspective BalanceDelta (int256 packed).
    function doSwap(PoolKey calldata key, SwapParams calldata params) external returns (int256) {
        return abi.decode(pm.unlock(abi.encode(key, params)), (int256));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(pm), "only PoolManager");
        (PoolKey memory key, SwapParams memory params) = abi.decode(data, (PoolKey, SwapParams));

        int256 delta = pm.swap(key, params, "");
        int128 a0 = int128(delta >> 128);
        int128 a1 = int128(delta);

        // negative amount => caller owes PoolManager (pay in); positive => PoolManager owes caller (take out)
        if (a0 < 0) {
            pm.sync(key.currency0);
            _safeTransfer(Currency.unwrap(key.currency0), address(pm), uint256(uint128(-a0)));
            pm.settle();
        }
        if (a1 < 0) {
            pm.sync(key.currency1);
            _safeTransfer(Currency.unwrap(key.currency1), address(pm), uint256(uint128(-a1)));
            pm.settle();
        }
        if (a0 > 0) pm.take(key.currency0, address(this), uint256(uint128(a0)));
        if (a1 > 0) pm.take(key.currency1, address(this), uint256(uint128(a1)));

        return abi.encode(delta);
    }

    receive() external payable {}

    /// @dev ERC-20 transfer via low-level call so tokens that return no data (e.g. some USDT
    ///      deployments) do not break the strict `bool` ABI decode.
    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "transfer failed");
    }
}
