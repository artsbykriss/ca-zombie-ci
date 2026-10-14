// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title ITreasury
 * @notice Interface for managing protocol fee collection and token withdrawals
 * @dev Handles LP fee collection and controlled withdrawals of tokens/native currency
 */
interface ITreasury {

    /**
     * @notice Thrown when an unauthorized address attempts to access treasury functions
     */
    error WrongAccess();

    /**
     * @notice Thrown when a withdrawal of native currency fails
     */
    error FailedWithdrawal();

    /**
     * @notice Thrown when a zero address is provided where a valid address is required
     */
    error ZeroAddress();

    /**
     * @notice Emitted when fees are collected from a liquidity position
     * @param token0 Address of the first token in the pair
     * @param token1 Address of the second token in the pair
     * @param recipient Address receiving the collected fees
     * @param amount0 Amount of token0 collected
     * @param amount1 Amount of token1 collected
     * @param lockId ID of the locked liquidity position
     */
    event CollectedLiquidityFees(
        address indexed token0,
        address indexed token1,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 lockId
    );

    /**
     * @notice Collects accumulated fees from a locked liquidity position by delegating to the liquidity module
     * @dev Only callable by authorized addresses. Delegates to the appropriate liquidity module
     *      which handles locker-specific logic (GoPlus, generic, etc.) and token ordering.
     * @param liquidityModule Address of the liquidity module that manages this position's DEX
     * @param lockId ID of the locked liquidity position
     * @param token Address of the first token in the pair
     * @param basePair Address of the second token in the pair (base currency)
     * @param recipient Address to receive the collected fees
     * @custom:throws WrongAccess if caller is not authorized
     */
    function collectLiquidityFees(
        address liquidityModule,
        uint256 lockId,
        address token,
        address basePair,
        address recipient
    ) external;

    /**
     * @notice Withdraws tokens or native currency from the treasury
     * @dev Only callable by authorized addresses
     * @param token Address of token to withdraw (address(0) for native currency)
     * @param recipient Address to receive the withdrawal
     * @param amount Amount to withdraw
     * @custom:throws WrongAccess if caller is not authorized
     * @custom:throws FailedWithdrawal if native currency transfer fails
     */
    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Handles receipt of ERC721 tokens (LP position NFTs)
     * @dev Required for compatibility with ERC721 token transfers
     * @return bytes4 Function selector to indicate successful receipt
     */
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure returns (bytes4);

}
