// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function allowance(address, address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IPair is IERC20 {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function kLast() external view returns (uint256);
    function sync() external;
    function skim(address) external;
    function swap(uint256, uint256, address, bytes calldata) external;
    function burn(address) external returns (uint256, uint256);
    function mint(address) external returns (uint256);
}

interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory);
    function getAmountsIn(uint256, address[] calldata) external view returns (uint256[] memory);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256, uint256, address[] calldata, address, uint256) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256, address[] calldata, address, uint256) external payable;
    function addLiquidity(address, address, uint256, uint256, uint256, uint256, address, uint256)
        external returns (uint256, uint256, uint256);
    function removeLiquidity(address, address, uint256, uint256, uint256, address, uint256)
        external returns (uint256, uint256);
}

interface IToken is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function owner() external view returns (address);
    function tradeController() external view returns (address);
    function mainPair() external view returns (address);
    function usdt() external view returns (address);
    function miner() external view returns (address);
    function node() external view returns (address);
    function liquidityRemover() external view returns (address);
    function liquidityProvider() external view returns (address);
    function blockConfig() external view returns (bool buyEnabled, bool sellEnabled);
    function priceTracker() external view returns (uint128 currentPrice, uint128 historicalHighPrice, uint32 lastDay, uint32 offset, uint64 lastUpdateBlock);
    function getPriceInfo() external view returns (uint128, uint128, uint32, uint32, uint64, uint256);
    function getDownFee() external view returns (uint256);
    function feeWhiteList(address) external view returns (bool);
    function swapPairList(address) external view returns (bool);
    function swapRouters(address) external view returns (bool);
    function strictCheck() external view returns (bool);
    function releaseRate() external view returns (uint256);
    function feeConfig() external view returns (uint16, uint16, uint16, uint16, uint16, uint16);
    function lpDistributor() external view returns (address);
    function tokenDistributor() external view returns (address);
    function silverDistributor() external view returns (address);
    function goldDistributor() external view returns (address);
    function diamondDistributor() external view returns (address);
    function marketDistributor() external view returns (address);
    function diaBurnDistributor() external view returns (address);
    function levelDistributor() external view returns (address);
    function mainDistributor() external view returns (address);
}
