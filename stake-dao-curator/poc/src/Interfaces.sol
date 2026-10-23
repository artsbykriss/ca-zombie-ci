// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

/// @dev Morpho Blue (0xBBBB...) — only the subset we touch.
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
    function supplyCollateral(MarketParams calldata marketParams, uint256 assets, address onBehalf, bytes calldata data)
        external;
    function withdrawCollateral(MarketParams calldata marketParams, uint256 assets, address onBehalf, address receiver)
        external;
}

/// @dev Live (old) StrategyWrapper surface.
interface IWrapperOld {
    function depositShares(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function claimLiquidation(address liquidator, address victim, uint256 liquidatedAmount) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function lendingMarketId() external view returns (bytes32);
    function REWARD_VAULT() external view returns (address);
    function LENDING_PROTOCOL() external view returns (address);
    function MAIN_REWARD_TOKEN() external view returns (address);
}

/// @dev Patched StrategyWrapper surface (receiver-based deposit).
interface IWrapperFixed {
    function depositShares(uint256 amount, address receiver) external;
    function withdrawCollateral(uint256 amount) external;
    function claimLiquidation(address liquidator, address victim, uint256 liquidatedAmount)
        external
        returns (uint256 claimed);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function REWARD_VAULT() external view returns (address);
}

interface IRewardVault {
    function asset() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getRewardTokens() external view returns (address[] memory);
}
