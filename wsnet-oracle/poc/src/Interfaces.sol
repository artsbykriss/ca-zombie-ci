// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Minimal interfaces for the Robinhood Chain (4663) Loopback / Morpho-Blue stack.
// Only the members used by the PoC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function sync() external;
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}

interface IPairOracle {
    function checkpoint() external;
    function twapNetUsdg() external view returns (uint256);
    function lastCheckpointAt() external view returns (uint64);
    function pair() external view returns (address);
}

interface ITreasury {
    function backingPerToken() external view returns (uint256);
}

interface ILoopbackOracle {
    function price() external view returns (uint256);
    function pairOracle() external view returns (address);
    function treasury() external view returns (address);
    function sNet() external view returns (address);
    function pair() external view returns (address);
    function netIsToken0() external view returns (bool);
}

interface IsNET {
    function index() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IwsNET {
    function wrap(uint256) external returns (uint256);
    function unwrap(uint256) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface IStaking {
    function stake(address to, uint256 amount) external returns (uint256);
    function enabled() external view returns (bool);
    function warmupEpochs() external view returns (uint256);
    function epoch() external view returns (uint64, uint64, uint64, uint256);
}

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

interface IMorpho {
    function market(bytes32 id)
        external
        view
        returns (uint128 totalSupplyAssets, uint128 totalSupplyShares, uint128 totalBorrowAssets, uint128 totalBorrowShares, uint128 lastUpdate, uint128 fee);
    function idToMarketParams(bytes32 id) external view returns (MarketParams memory);
    function supplyCollateral(MarketParams calldata p, uint256 assets, address onBehalf, bytes calldata data) external;
    function borrow(MarketParams calldata p, uint256 assets, uint256 shares, address onBehalf, address receiver)
        external
        returns (uint256, uint256);
    function position(bytes32 id, address user) external view returns (uint256 supplyShares, uint128 borrowShares, uint128 collateral);
}
