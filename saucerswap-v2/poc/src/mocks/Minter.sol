// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {MockERC20} from "./MockERC20.sol";

interface IUniswapV3MintCallbackMin {
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external;
}

interface IPoolMin {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
    function burn(int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);
    function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 a0, uint128 a1)
        external
        returns (uint128 amount0, uint128 amount1);
}

/// @notice Stands in for an ordinary LP: owns its pool position (msg.sender-keyed) and pays mint fees.
contract Minter is IUniswapV3MintCallbackMin {
    address public pool;
    address public t0;
    address public t1;

    constructor(address _pool, address _t0, address _t1) {
        pool = _pool;
        t0 = _t0;
        t1 = _t1;
    }

    function doMint(int24 lo, int24 hi, uint128 L) external {
        IPoolMin(pool).mint(address(this), lo, hi, L, abi.encode(t0, t1));
    }

    function doBurn(int24 lo, int24 hi, uint128 L) external {
        IPoolMin(pool).burn(lo, hi, L);
    }

    function doCollect(address recipient, int24 lo, int24 hi)
        external
        returns (uint128 amount0, uint128 amount1)
    {
        return IPoolMin(pool).collect(recipient, lo, hi, type(uint128).max, type(uint128).max);
    }

    function uniswapV3MintCallback(uint256 a0, uint256 a1, bytes calldata) external override {
        if (a0 > 0) MockERC20(t0).transfer(msg.sender, a0);
        if (a1 > 0) MockERC20(t1).transfer(msg.sender, a1);
    }
}
