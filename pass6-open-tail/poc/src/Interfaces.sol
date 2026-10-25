// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/// @dev Ronin BondingCurveManager (verified source read; only the surface we test).
interface IBondingCurveManager {
    struct MarketState {
        uint256 virtualToken;
        uint256 virtualRonke;
        uint256 tokensSold;
        uint256 ronkeCollected;
        address creator;
        bool exists;
        bool graduated;
    }

    function buy(address token, uint256 ronkeIn, uint256 minTokensOut)
        external
        returns (uint256 tokensOut, uint256 ronkeSpent);

    function sell(address token, uint256 tokensIn, uint256 minRonkeOut) external returns (uint256 ronkeOut);

    function buyFor(address token, address buyer, uint256 ronkeIn, uint256 minTokensOut)
        external
        returns (uint256, uint256);

    function quoteBuy(address token, uint256 ronkeIn) external view returns (uint256, uint256, uint256);

    function quoteSell(address token, uint256 tokensIn) external view returns (uint256, uint256);

    function markets(address token) external view returns (MarketState memory);

    function boughtFromCurve(address token, address wallet) external view returns (uint256);

    function creatorBought(address token) external view returns (uint256);

    function ronke() external view returns (address);

    function feeVault() external view returns (address);

    function graduationManager() external view returns (address);

    function factory() external view returns (address);

    function liveTarget(address token) external view returns (uint256);

    function readyToGraduate(address token) external view returns (bool);

    function owner() external view returns (address);

    function setWiring(address, address) external;

    function setAutoGraduate(bool) external;
}

/// @dev Ink ChimeraQuoteHook404 / Router404 (verified source read; surface only).
interface IChimeraQuoteHook404 {
    function poolManager() external view returns (address);
    function router() external view returns (address);
    function factory() external view returns (address);
    function launchLiquidity() external view returns (address);
    function platform() external view returns (address);
    function ecosystem() external view returns (address);
    function quoteOf(bytes32 id) external view returns (address);
    function distributeQuotrons(bytes32 id) external;
    function setQuote(address asset, bool allowed) external;
    function setEcosystem(address recipient) external;
    function configureInfrastructure(address f, address r) external;
    function updateFees(bytes32 id, uint256 nft, uint256 lp, uint256[] calldata custom) external;
    function setEligibility(bytes32 id, address[] calldata assets, uint256[] calldata minima) external;
}

interface IChimeraQuoteRouter404 {
    struct Hop {
        PoolKey key;
        bool zeroForOne;
    }
    function actor() external view returns (address);
    function weth() external view returns (address);
    function hook() external view returns (address);
    function swapPath(Hop[] calldata path, uint128 amountIn, uint128 minOut, address rule, uint256 deadline)
        external
        payable
        returns (uint128);
}

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}
