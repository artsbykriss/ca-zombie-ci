// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

/// MiniSwap V1 pair (mining-enabled), per MiniswapOrg/Miniswap-contract interfaces/V1
interface IMiniswapV1Pair {
    function factory() external view returns (address);
    function miner() external view returns (address);
    function MINI() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function feeTemp() external view returns (address);
    function totalFeeAmount() external returns (uint256);
    function userInFeeAmount(address) external returns (uint256);
    function getMineFeeAmount(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256);
    function burn(address to) external returns (uint256, uint256, uint256);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, address originSender, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

/// MiniSwap V2 pair (plain, factory1)
interface IMiniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function burn(address to) external returns (uint256, uint256);
    function mint(address to) external returns (uint256);
}

interface IMini {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function issueTo(address, uint256) external;
    function paused() external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IMiniswapMiner {
    function feeder() external view returns (address);
    function minFee() external view returns (uint256);
    function mineInfo(uint256) external view returns (uint256);
    function whitelistMap(address) external view returns (bool);
}
