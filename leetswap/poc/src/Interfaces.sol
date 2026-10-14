// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256, uint256, uint256);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function sync() external;
    function skim(address) external;
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function _transferFeesSupportingTaxTokens(address token, uint256 amount) external returns (uint256);
    function fees() external view returns (address);
    function factory() external view returns (address);
    function stable() external view returns (bool);
}

interface IFactory {
    function isPaused() external view returns (bool);
    function tradingFees(address pair, address to) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IWETH {
    function deposit() external payable;
}
