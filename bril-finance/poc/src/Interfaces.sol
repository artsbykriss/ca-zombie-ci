// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function symbol() external view returns (string memory);
}

interface IICHIVault {
    function owner() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function pool() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function getTotalAmounts() external view returns (uint256, uint256);
    function baseLower() external view returns (int24);
    function baseUpper() external view returns (int24);
    function limitLower() external view returns (int24);
    function limitUpper() external view returns (int24);
    function currentTick() external view returns (int24);
    function rebalance(int24, int24, int24, int24, int256) external;
}

interface IBrilStrategy {
    function rebalance() external;
    function performUpkeep(bytes calldata) external;
    function checkUpkeep(bytes calldata) external returns (bool, bytes memory);
    function simulate() external view returns (int24, int24, int24, int24);
    function vault() external view returns (address);
    function owner() external view returns (address);
    function gnosis() external view returns (address);
    function paused() external view returns (bool);
    function rebalanceInitiation() external view returns (uint256);
    function executionDelay() external view returns (uint256);
    function lastRebalance() external view returns (uint256);
    function minTimeBetweenRebalances() external view returns (uint256);
    function poolPrices() external view returns (uint256, uint256, uint256);
}

interface IUniV3Pool {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
    function liquidity() external view returns (uint128);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external returns (int256, int256);
}

interface IGnosisSafe {
    function isModuleEnabled(address) external view returns (bool);
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

interface IWBNB {
    function deposit() external payable;
    function withdraw(uint256) external;
}

/// @dev Minimal PancakeSwap-V3 (fork of UniV3) swap helper: performs a swap and pays in the callback.
///      Funded with `deal()` to stand in for flash-loan capital (noted in the report).
contract Swapper {
    address public immutable pool;
    address public immutable t0;
    address public immutable t1;

    constructor(address _pool) {
        pool = _pool;
        t0 = IUniV3Pool(_pool).token0();
        t1 = IUniV3Pool(_pool).token1();
    }

    function doSwap(bool zeroForOne, int256 amountSpecified) external returns (int256 a0, int256 a1) {
        uint160 limit = zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341;
        (a0, a1) = IUniV3Pool(pool).swap(address(this), zeroForOne, amountSpecified, limit, "");
    }

    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == pool, "cb: pool only");
        if (amount0Delta > 0) IERC20(t0).transfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20(t1).transfer(msg.sender, uint256(amount1Delta));
    }

    function sweep(address token, address to) external {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }
}
