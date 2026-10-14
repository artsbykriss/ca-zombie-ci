// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICErc20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function underlying() external view returns (address);
    function comptroller() external view returns (address);
    function admin() external view returns (address);
    function getCash() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function borrowBalanceCurrent(address) external returns (uint256);
    function accrueInterest() external returns (uint256);
    function takeReserves() external returns (uint256);
    function _reduceReserves(uint256) external returns (uint256);
    function _setReserveFactor(uint256) external returns (uint256);
    function _setInterestRateModel(address) external returns (uint256);
    function mint() external payable;
    function borrow(uint256) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable returns (uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function reserveFactorMantissa() external view returns (uint256);
    function dist() external view returns (address);
}

interface IComptroller {
    function admin() external view returns (address);
    function oracle() external view returns (address);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function getAllMarkets() external view returns (address[] memory);
    function markets(address) external view returns (bool, uint256, bool);
    function borrowCaps(address) external view returns (uint256);
    function borrowGuardianPaused(address) external view returns (bool);
    function mintGuardianPaused(address) external view returns (bool);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function liquidateBorrowAllowed(
        address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 repayAmount
    ) external returns (uint256);
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint256 actualRepayAmount)
        external
        view
        returns (uint256, uint256);
    function _setPriceOracle(address newOracle) external returns (uint256);
    function _setCloseFactor(uint256) external returns (uint256);
    function _setLiquidationIncentive(uint256) external returns (uint256);
    function _setMintPaused(address cToken, bool state) external returns (bool);
    function _setBorrowPaused(address cToken, bool state) external returns (bool);
}

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
    function owner() external view returns (address);
    function setPriceFeed(address ct, address pf) external;
}

interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

interface IRewardDistributor {
    function underlying() external view returns (address);
    function owner() external view returns (address);
    function harvest(bytes32[] memory ledgerIds) external returns (uint256);
    function updateRewards(bytes32[] memory ledgerIds) external;
    function onAssetIncrease(bytes32 kind, address account, uint256 delta) external;
    function onAssetDecrease(bytes32 kind, address account, uint256 delta) external;
}
