// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IPairLike {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function sync() external;
    function skim(address) external;
}

interface IFactoryLike {
    function getPair(address, address) external view returns (address);
}

interface IRouterLike {
    function factory() external view returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external payable;
}

interface IGDCToken {
    // ERC20
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    // business surface
    function maxSellAmount() external view returns (uint256);
    function currentStage() external view returns (uint8);
    function reserveDistributor() external view returns (address);
    function companyAccount() external view returns (address);
    function rewardAccount() external view returns (address);
    function depositContract() external view returns (address);
    function pair() external view returns (address);
    function referrals() external view returns (address);
    function isLiquidityPool(address) external view returns (bool);
    function transferWhitelist(address) external view returns (bool);
    function LP_MIN_BALANCE() external view returns (uint256);
    function lastTradeBlock(address) external view returns (uint256);
}

interface IGDCMain {
    function pendingReserveDividend() external view returns (uint256);
    function distributionRemaining() external view returns (uint256);
    function originalDeflationReward() external view returns (uint256);
    function deflationCount() external view returns (uint256);
}

interface IGDCReserveDistributor {
    function gdc() external view returns (address);
    function controller() external view returns (address);
    function dividendReceiver() external view returns (address);
    function distribute(uint256 requestedAmount)
        external
        returns (uint256 actualAmount, uint256 companyAmount, uint256 dividendAmount);
}
