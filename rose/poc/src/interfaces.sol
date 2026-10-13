// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// Curve-style Vyper pool (Rose fork): 3-coin base + 2-coin metapools share most of this ABI.
interface ICurvePool {
    function coins(uint256) external view returns (address);
    function balances(uint256) external view returns (uint256);
    function A() external view returns (uint256);
    function fee() external view returns (uint256);
    function owner() external view returns (address);
    function fee_receiver() external view returns (address);
    function lp_token() external view returns (address);
    function token() external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint) external returns (uint256);
    function add_liquidity3(uint256[3] calldata amounts, uint256 min_mint) external returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn) external returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
    function base_pool() external view returns (address);
    function base_coins(uint256) external view returns (address);
    function base_virtual_price() external view returns (uint256);
    function donate_admin_fees() external;
}

/// Minimal UniswapV2 pair (Trisolaris) for market-price checks.
interface IUniV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IUniV2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory);
}

/// Rose "Garden" (Kashi fork) clone.
interface IGarden {
    function cloneInfo() external view returns (address collateral, bool isBorrowWhitelisted, address oracle, bytes memory oracleData, uint256 collateralizationRate, uint256 liquidationMultiplier, uint256 borrowOpeningFee, uint64 interestPerSecond);
    function exchangeRate() external view returns (uint256);
    function totalCollateralShare() external view returns (uint256);
    function totalBorrow() external view returns (uint128 elastic, uint128 base);
    function userCollateralShare(address) external view returns (uint256);
    function userBorrowPart(address) external view returns (uint256);
    function roseUsd() external view returns (address);
    function vase() external view returns (address);
    function liquidate(address[] calldata users, uint256[] calldata maxBorrowParts, address to, address swapper) external;
    function borrow(address to, uint256 amount) external returns (uint256, uint256);
    function addCollateral(address to, bool skim, uint256 share) external;
    function withdrawFees() external;
    function reduceSupply(uint256 amount) external;
    function feeTo() external view returns (address);
}

/// BentoBox-style "Vase".
interface IBentoBox {
    function balanceOf(IERC20 token, address user) external view returns (uint256);
    function totals(IERC20 token) external view returns (uint128 elastic, uint128 base);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256);
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function owner() external view returns (address);
    function masterContractOf(address) external view returns (address);
}

interface IFarm {
    function stakingToken() external view returns (address);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function totalSupply() external view returns (uint256);
    function recoverERC20(address token, uint256 amount) external;
    function rewardTokens(uint256) external view returns (address);
}
