// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IGauge {
    function balanceOf(address) external view returns (uint256);
    function getTotalDelegateStaked(address) external view returns (uint256);
    function delegateStake(address account, uint256 amount) external;
    function delegateWithdraw(address account, uint256 amount) external;
    function stakeOnBehalf(address account, uint256 amount) external;
    function stake(uint256) external;
    function withdraw(uint256) external;
    function paused() external view returns (bool);
}

interface IStrategy {
    function getTokenBalance() external view returns (uint256);
    function getUnderlyingBalance() external view returns (uint256);
    function hubVault() external view returns (address);
}

interface IIsland {
    function getMintAmounts(uint256, uint256) external view returns (uint256, uint256, uint256);
    function getUnderlyingBalances() external view returns (uint256, uint256);
    function totalSupply() external view returns (uint256);
    function burn(uint256, address) external returns (uint256, uint256, uint128);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address) external view returns (uint256);
}

interface IIslandRouter {
    function addLiquidity(
        address island,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 mintAmountMin,
        address receiver
    ) external returns (uint256, uint256, uint256);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256);
}

interface IVault {
    function deposit(uint256 _tid, uint256 _amount) external payable;
    function withdraw(uint256 _tid, uint256 _amount) external;
    function seniorToken() external view returns (address);
    function juniorToken() external view returns (address);
    function currentTrancheInformation() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}

library Addrs {
    address internal constant HONEY = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address internal constant ISLAND = 0xE5A2ab5D2fb268E5fF43A5564e44c3309609aFF9;
    address internal constant ISLAND_ROUTER = 0x679a7C63FC83b6A4D9C1F931891d705483d4791F;
    address internal constant SWAP_ROUTER = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
    address internal constant GAUGE = 0x75Da1D58A8d97f7b626224E7E71fa44DB13689f2;
    address internal constant STRATEGY = 0x1Ce23321A72F2dae96809cC6192f053A7aD5D8e4;
    address internal constant VAULT = 0x4a3c8Fdd55017773fEe33dE4aa7e12dD60B0A054;
}
