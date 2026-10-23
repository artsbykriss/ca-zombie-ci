// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager, IUnlockCallback, IERC20, PoolKey, SwapParams, BalanceDelta, Currency, DeltaLib} from "./Interfaces.sol";

/// @notice Minimal unprivileged v4 swapper: calls PoolManager.unlock + swap, settles
///         what it owes and takes what it is owed. Mirrors what a real router does.
contract Swapper is IUnlockCallback {
    using DeltaLib for BalanceDelta;

    IPoolManager public immutable pm;

    constructor(IPoolManager pm_) {
        pm = pm_;
    }

    function doSwap(PoolKey memory key, SwapParams memory p) external payable returns (BalanceDelta) {
        return abi.decode(pm.unlock(abi.encode(key, p)), (BalanceDelta));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(pm), "not poolManager");
        (PoolKey memory key, SwapParams memory p) = abi.decode(data, (PoolKey, SwapParams));
        BalanceDelta d = pm.swap(key, p, "");

        int128 a0 = d.amount0();
        int128 a1 = d.amount1();

        if (a0 < 0) {
            pm.settle{value: uint256(uint128(-a0))}();
        } else if (a0 > 0) {
            pm.take(key.currency0, address(this), uint256(uint128(a0)));
        }

        if (a1 < 0) {
            uint256 need = uint256(uint128(-a1));
            pm.sync(key.currency1);
            IERC20(Currency.unwrap(key.currency1)).transfer(address(pm), need);
            pm.settle();
        } else if (a1 > 0) {
            pm.take(key.currency1, address(this), uint256(uint128(a1)));
        }
        return abi.encode(d);
    }

    receive() external payable {}
}
