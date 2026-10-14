// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title Printr Trading Interface
 * @notice Interface for trading operations on tokens with linear bonding curves
 * @dev All price calculations use PRECISION_SCALAR (1e18) for accurate floating point math
 *      Handles buying, selling, and cross-chain trading operations
 */
interface IPrintrTrading is IPrintrStorage {

    /**
     * @notice Parameters for token trading operations
     * @param account Account performing the trade
     * @param token Address of the token being traded
     * @param amount Amount of tokens in the trade
     * @param priceLimit Maximum/minimum price limit for slippage protection
     * @param tokenSupply Current token supply before the trade
     * @param tradingFee Fee percentage applied to the trade
     */
    struct TradeParams {
        address account;
        address recipient;
        address token;
        uint256 amount;
        uint256 priceLimit;
        uint16 tradingFee;
    }

    /**
     * @notice Emitted when tokens are traded through the bonding curve
     * @param token Address of the token contract
     * @param trader Address that performed the trade
     * @param isBuy True if tokens were bought, false if sold
     * @param amount Number of tokens traded
     * @param cost Amount of base currency involved in the trade
     * @param priceAfter Price per token achieved in the trade
     * @param issuedSupply New total supply after the trade
     * @param reserve New reserve balance after the trade
     */
    event TokenTrade(
        address indexed token,
        address indexed trader,
        bool isBuy,
        uint256 amount,
        uint256 cost,
        uint256 priceAfter,
        uint256 issuedSupply,
        uint256 reserve
    );

    /**
     * @notice Emitted when a token graduates from bonding curve to liquidity pool
     * @param token Address of the token that graduated
     * @param totalSupply Total supply at graduation
     */
    event TokenGraduated(address indexed token, uint256 totalSupply);

    /**
     * @notice Emitted when a token graduation process encounters a partial failure
     * @dev Used for graceful degradation when liquidity deployment or post-graduation swap fails
     * @param token Address of the token that experienced partial graduation failure
     * @param stage Stage at which failure occurred (0=liquidity deployment, 1=post-graduation swap)
     */
    event TokenGraduationPartialFailure(address indexed token, uint8 stage, uint256 gasLeft);

    /**
     * @notice Issues tokens according to the bonding curve
     * @param token Address of the token to issue
     * @param recipient Address to receive the issued tokens
     * @param amount Amount of tokens to issue
     * @param maxPrice Maximum acceptable price per token for slippage protection
     */
    function buy(
        address token,
        address recipient,
        uint256 amount,
        uint256 maxPrice
    ) external payable returns (TradeParams memory params);

    /**
     * @notice Buys tokens with a specified amount of base currency
     * @param token Address of the token to buy
     * @param recipient Address to receive the tokens
     * @param baseAmount Amount of base currency to spend. Pass type(uint256).max to use
     *                   the maximum available amount (all approved tokens or all sent ETH)
     * @param maxPrice Maximum acceptable price per token for slippage protection
     */
    function spend(
        address token,
        address recipient,
        uint256 baseAmount,
        uint256 maxPrice
    ) external payable returns (TradeParams memory params);

    /**
     * @notice Redeems tokens and returns base currency according to the bonding curve
     * @param token Address of the token to redeem
     * @param recipient Address to receive the refunded base currency
     * @param amount Amount of tokens to redeem. Pass type(uint256).max to sell all tokens
     * @param minPrice Minimum acceptable refund per token for slippage protection
     */
    function sell(
        address token,
        address recipient,
        uint256 amount,
        uint256 minPrice
    ) external returns (TradeParams memory params);

    /**
     * @notice Sells tokens and returns base currency according to the bonding curve
     * @dev Called by the Telecoin contract via permitWitnessCall
     * @param account Address of the account selling tokens
     * @param token Address of the token to sell
     * @param recipient Address to receive the refund
     * @param amount Amount of tokens to sell. Pass type(uint256).max to sell all tokens
     * @param minPrice Minimum acceptable price per token
     */
    function witnessSell(
        address account,
        address token,
        address recipient,
        uint256 amount,
        uint256 minPrice
    ) external returns (TradeParams memory params);

}
