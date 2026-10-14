// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title Printr Quoting Interface
 * @notice Interface for read-only price quoting operations on bonding curves and liquidity pools
 * @dev Separated from IPrintrTrading to allow quoting logic to live in Module instead of PrintrCore,
 *      reducing PrintrCore's contract size while keeping the same proxy-level API
 */
interface IPrintrQuoting is IPrintrStorage {

    /**
     * @notice Estimates the cost of issuing a specific amount of tokens
     * @dev Uses linear bonding curve. All calculations are scaled by PRECISION_SCALAR
     * @param token Address of the token
     * @param tokenAmount Number of tokens to issue
     * @return availableAmount Amount of tokens available for issuing
     * @return cost Cost in base currency to issue the specified amount of tokens
     * @return fee Trading fee amount in base currency
     * @return priceAfter Effective price per token in base currency
     * @return issuedSupply New total supply after the issue
     */
    function estimateTokenCost(
        address token,
        uint256 tokenAmount
    ) external returns (uint256 availableAmount, uint256 cost, uint256 fee, uint256 priceAfter, uint256 issuedSupply);

    /**
     * @notice Quote the amount of tokens receivable for a specific amount of base currency
     * @dev Calculates tokens received including trading fees
     * @param token The token address
     * @param baseAmount The amount of base currency to spend
     * @return tokenAmount The amount of tokens receivable
     * @return cost The actual amount in base currency required for the purchase
     * @return fee The trading fee amount in base currency
     * @return priceAfter The effective price per token
     * @return issuedSupply The new total supply after the purchase
     */
    function quoteTokenAmount(
        address token,
        uint256 baseAmount
    ) external returns (uint256 tokenAmount, uint256 cost, uint256 fee, uint256 priceAfter, uint256 issuedSupply);

    /**
     * @notice Estimates the refund amount for redeeming a specific amount of tokens
     * @dev Uses the same linear bonding curve as issue, but in reverse
     * @param token Address of the token
     * @param tokenAmount Number of tokens to redeem
     * @return tokenAmountIn Amount of tokens that can actually be sold (capped by supply)
     * @return refund Refund amount in base currency for redeeming the specified tokens
     * @return fee Trading fee amount in base currency
     * @return priceAfter Effective price per token in base currency
     * @return issuedSupply New total supply after the redemption
     */
    function estimateTokenRefund(
        address token,
        uint256 tokenAmount
    ) external returns (uint256 tokenAmountIn, uint256 refund, uint256 fee, uint256 priceAfter, uint256 issuedSupply);

}
