// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IUniswapV3PoolMinimal {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external returns (int256 amount0, int256 amount1);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

/// @notice Minimal driver that exercises a Uniswap V3 pool's swap + flash paths and
///         acts as its own callback receiver. Used only to measure pool accounting.
contract BulbaProbe {
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;

    uint256 private flash0;
    uint256 private flash1;

    constructor(address _pool) {
        pool = _pool;
        token0 = IUniswapV3PoolMinimal(_pool).token0();
        token1 = IUniswapV3PoolMinimal(_pool).token1();
    }

    function doSwap(bool zeroForOne, int256 amountSpecified) external returns (int256, int256) {
        uint160 limit = zeroForOne
            ? uint160(4295128739 + 1)
            : uint160(1461446703485210103287273052203988822378723970342 - 1);
        return IUniswapV3PoolMinimal(pool).swap(address(this), zeroForOne, amountSpecified, limit, "");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == pool, "cb:only pool");
        if (amount0Delta > 0) IERC20(token0).transfer(pool, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20(token1).transfer(pool, uint256(amount1Delta));
    }

    function doFlash(uint256 a0, uint256 a1) external {
        flash0 = a0;
        flash1 = a1;
        IUniswapV3PoolMinimal(pool).flash(address(this), a0, a1, "");
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata) external {
        require(msg.sender == pool, "cb:only pool");
        if (flash0 + fee0 > 0) IERC20(token0).transfer(pool, flash0 + fee0);
        if (flash1 + fee1 > 0) IERC20(token1).transfer(pool, flash1 + fee1);
    }
}
