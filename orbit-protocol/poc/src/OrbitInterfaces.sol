// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Minimal interfaces for Orbit Protocol (Compound-v2 fork on Blast).

interface ICErc20 {
    function underlying() external view returns (address);
    function getCash() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function mint(uint256) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
    function _reduceReserves(uint256) external returns (uint256);
    function _blastClaimYield(address target) external;
    function admin() external view returns (address);
    function comptroller() external view returns (address);
    function sweepToken(address token) external;
}

interface ICEther {
    function getCash() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function mint() external payable;
    function redeem(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow() external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function _blastClaimYield(address target) external;
    function admin() external view returns (address);
    function comptroller() external view returns (address);
}

interface IComptroller {
    function admin() external view returns (address);
    function oracle() external view returns (address);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function comptrollerImplementation() external view returns (address);
    function pauseGuardian() external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    function markets(address) external view returns (bool, uint256, bool);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function getHypotheticalAccountLiquidity(address, address, uint256, uint256)
        external view returns (uint256, uint256, uint256);
    function liquidateCalculateSeizeTokens(address, address, uint256)
        external view returns (uint256, uint256);
    function _setPriceOracle(address) external returns (uint256);
    function _setCloseFactor(uint256) external returns (uint256);
    function _setLiquidationIncentive(uint256) external returns (uint256);
    function _setMintPaused(address, bool) external returns (bool);
    function _become(address) external;
    function enterMarkets(address[] calldata) external returns (uint256[] memory);
}

interface IOracle {
    function getUnderlyingPrice(address oToken) external view returns (uint256);
}

interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }
    function getPriceUnsafe(bytes32 id) external view returns (Price memory);
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (Price memory);
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256);
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
    function getValidTimePeriod() external view returns (uint256);
}

interface IBlast {
    function readClaimableYield(address) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}
