// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @dev Minimal interface for the deployed Stake DAO MorphoStrategyWrapper
///      (StrategyWrapper v3 / older generation). Only the surface needed for the PoC.
interface IStrategyWrapper {
    // ERC20
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    // Stake DAO wrapper surface
    function version() external pure returns (uint256);
    function lendingMarketId() external view returns (bytes32);
    function LENDING_PROTOCOL() external view returns (address);
    function REWARD_VAULT() external view returns (address);
    function MAIN_REWARD_TOKEN() external view returns (address);
    function owner() external view returns (address);

    function depositShares(uint256 amount, address receiver) external;
    function depositAssets(uint256 amount, address receiver) external;
    function withdraw(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function claim(address receiver) external returns (uint256);
    function claimExtraRewards(address receiver) external returns (uint256[] memory);
    function claimLiquidation(address liquidator, address victim, uint256 liquidatedAmount)
        external
        returns (uint256);
    function checkpointBalanceOf(address account) external view returns (uint256);
    function getPendingRewards(address user) external view returns (uint256);
    function initialize(bytes32 marketId) external;
}

interface IMorpho {
    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm;
        uint256 lltv;
    }

    struct Position {
        uint256 supplyShares;
        uint128 borrowShares;
        uint128 collateral;
    }

    function idToMarketParams(bytes32 id) external view returns (MarketParams memory);
    function position(bytes32 id, address user) external view returns (Position memory);
    function withdrawCollateral(MarketParams memory marketParams, uint256 assets, address onBehalf, address receiver) external;
    function supplyCollateral(MarketParams memory marketParams, uint256 assets, address onBehalf, bytes memory data) external;
}

interface IRewardVault {
    function asset() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getRewardTokens() external view returns (address[] memory);
    function ACCOUNTANT() external view returns (address);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
