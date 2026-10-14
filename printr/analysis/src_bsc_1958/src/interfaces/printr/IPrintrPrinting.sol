// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title Printr Printing Interface
 * @notice Interface for managing token printing and liquidity curve operations
 * @dev Extends IPrintrStorage to handle token deployment and curve management across chains
 */
interface IPrintrPrinting is IPrintrStorage {

    /**
     * @notice Event emitted when a new token is printed
     * @param token Address of the new token contract
     * @param telecoinId Unique identifier for cross-chain deployment
     */
    event TelecoinPrinted(address indexed token, bytes32 indexed telecoinId);

    /**
     * @notice Emitted when a new token is created
     * @param creator Address that created the token
     * @param token Address of the new token contract
     * @param telecoinId Unique identifier for cross-chain deployment
     */
    event CurveCreated(address indexed creator, address indexed token, bytes32 indexed telecoinId);

    /**
     * @notice Emitted when token liquidity is deployed to Uniswap
     * @param token Address of the token contract
     * @param tokenAmount Amount of tokens added to the liquidity pool
     * @param baseAmount Amount of base currency added to the liquidity pool
     */
    event LiquidityDeployed(address indexed token, uint256 tokenAmount, uint256 baseAmount);

    /**
     * @notice Emitted when liquidity position is locked
     * @param token Address of the token contract
     * @param positionManager Address of the liquidity position manager
     * @param positionId Unique identifier for the liquidity position
     * @param lockId Unique identifier for the lock
     */
    event LiquidityLocked(address indexed token, address indexed positionManager, uint256 positionId, uint256 lockId);

    /**
     * @notice Emitted when a new Uniswap V3-compatible AMM pool is created
     * @param telecoin Address of the telecoin contract
     * @param baseToken Address of the base/quote token
     * @param factory Address of the DEX factory that created the pool
     * @param pool Address of the newly created pool
     * @param feePips AMM fee tier in parts-per-million
     */
    event UniswapPoolCreated(
        address indexed telecoin, address indexed baseToken, address indexed factory, address pool, uint24 feePips
    );

    /**
     * @notice Prints a new token with a bonding curve across multiple chains
     * @dev Deploys token with bonding curve on the current chain and initiates remote deployments
     * @param initialSpending Initial amount of base currency to commit. Pass type(uint256).max to use
     *                        the maximum available amount (all approved tokens or all sent ETH)
     * @param telecoinParams Parameters for the token curve deployment including across-chain configuration
     * @return tokenAddress The address of the newly created token
     * @return telecoinId Unique identifier for cross-chain deployment
     */
    function print(
        uint256 initialSpending,
        TelecoinParams calldata telecoinParams
    ) external payable returns (address tokenAddress, bytes32 telecoinId);

}
