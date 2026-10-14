// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import { ILiquidityModule } from "../interfaces/liquidity/ILiquidityModule.sol";
import { IPrintrTrading } from "../interfaces/printr/IPrintrTrading.sol";
import { IPrintrTeleportingTelecoin } from "../interfaces/telecoin/IPrintrTeleportingTelecoin.sol";
import { IWETH } from "../interfaces/telecoin/IWETH.sol";

import { SqrtPriceMath } from "../libs/SqrtPriceMath.sol";

import { PrintrStorage } from "./PrintrStorage.sol";

/**
 * @title Printr Trading
 * @notice Implements trading functionality for tokens with linear bonding curves
 * @dev Implements:
 *      - Bonding curve calculations for token pricing
 *      - Token buying and selling mechanics
 *      - Cross-chain trading operations
 *      - Liquidity pool interactions
 *      - Fee collection and distribution
 */
abstract contract PrintrTrading is IPrintrTrading, PrintrStorage {

    using SafeERC20 for IERC20;
    using Math for uint256;
    using SqrtPriceMath for uint256;

    /// @notice Gas reserved for graceful exit operations during token graduation
    /// @dev Worst-case breakdown: event emission (~2,100 gas), ERC20 balanceOf (~2,600 gas),
    ///      WETH withdraw (~8,000 gas), ERC20 safeTransfer cold SSTORE (~20,100 gas), safety buffer (~25,200 gas)
    /// @dev Applied to liquidity deployment and post-graduation swaps to allow token refunds on failure
    uint256 private constant GRACEFUL_EXIT_GAS_RESERVE = 63_000;

    /**
     * @notice Buys tokens according to the bonding curve or from liquidity pool
     * @dev Handles both curve-based purchases (pre-graduation) and pool-based purchases (post-graduation)
     *      Includes slippage protection via maxPrice parameter
     * @param token Address of the token to purchase
     * @param recipient Address that will receive the purchased tokens
     * @param amount Amount of tokens to buy (exact amount)
     * @param maxPrice Maximum acceptable price per token (0 = no limit)
     * @return TradeParams struct containing executed trade details
     * @custom:throws TokenNotFound if token curve doesn't exist
     * @custom:throws InsufficientPayment if ETH sent is insufficient
     */
    function buy(
        address token,
        address recipient,
        uint256 amount,
        uint256 maxPrice
    ) external payable whenNotPaused returns (TradeParams memory) {
        Storage storage $ = _storage();
        Curve memory curve = $.curves[token];

        require(amount != 0, ZeroAmount());
        require(curve.basePair != address(0), TokenNotFound());

        TradeParams memory params = TradeParams(msg.sender, recipient, token, amount, maxPrice, tradingFee);

        // Route to liquidity pool if already deployed (threshold = 0)
        if (curve.completionThreshold == 0) {
            // Quote the actual cost to buy the desired amount of tokens
            (, uint256 actualCost,,,) = _quoteLiquidityExactOutput(params, curve);
            // Get the maximum amount user can spend
            uint256 maxAvailable = _getMaxAmount(curve.basePair, msg.sender);
            // Use the smaller of actualCost and maxAvailable
            params.amount = actualCost < maxAvailable ? actualCost : maxAvailable;

            _spendInLiquidityPool(curve, params, false);
            _refundNativeValue(recipient);
            return params;
        }

        _buy(curve, params);
        // Refund excess ETH payment if any
        _refundNativeValue(recipient);

        return params;
    }

    /**
     * @notice Buys tokens with a specified amount of base currency
     * @dev Calculates optimal token amount for given base currency input
     *      Handles both ETH and ERC20 base currencies
     * @param token Address of the token to buy
     * @param recipient Address to receive the tokens
     * @param baseAmount Amount of base currency to spend. Pass type(uint256).max to use
     *                   the maximum available amount (all approved tokens or all sent ETH)
     * @param maxPrice Maximum acceptable price per token
     */
    function spend(
        address token,
        address recipient,
        uint256 baseAmount,
        uint256 maxPrice
    ) public payable whenNotPaused returns (TradeParams memory) {
        Storage storage $ = _storage();
        Curve memory curve = $.curves[token];

        require(baseAmount != 0, ZeroAmount());
        require(curve.basePair != address(0), TokenNotFound());

        if (baseAmount == type(uint256).max) {
            baseAmount = _getMaxAmount(curve.basePair, msg.sender);
        }

        TradeParams memory params = TradeParams(msg.sender, recipient, token, baseAmount, maxPrice, tradingFee);

        // Route to liquidity pool if already deployed (threshold = 0)
        if (curve.completionThreshold == 0) {
            params.amount = _spendInLiquidityPool(curve, params, false);
            _refundNativeValue(recipient);
            return params;
        }

        params.amount = _quoteTokenAmount($.curves[token], baseAmount, tradingFee);

        _buy(curve, params);
        // Refund excess ETH payment if any
        _refundNativeValue(recipient);

        return params;
    }

    /**
     * @notice Sells tokens and returns base currency according to the bonding curve
     * @dev Includes slippage protection via minPrice parameter
     *      Handles both curve-based and pool-based sales
     * @param token Address of the token to sell
     * @param recipient Address to receive the refund
     * @param amount Amount of tokens to sell. Pass type(uint256).max to sell all tokens
     * @param minPrice Minimum acceptable price per token
     */
    function sell(
        address token,
        address recipient,
        uint256 amount,
        uint256 minPrice
    ) public whenNotPaused returns (TradeParams memory) {
        Storage storage $ = _storage();
        Curve memory curve = $.curves[token];

        require(amount != 0, ZeroAmount());
        require(curve.basePair != address(0), TokenNotFound());

        if (amount == type(uint256).max) {
            amount = _getMaxAmount(token, msg.sender);
        }

        TradeParams memory params = TradeParams(msg.sender, recipient, token, amount, minPrice, tradingFee);

        _sell(curve, params);
        // Refund ETH value for the token sold
        _refundNativeValue(recipient);

        return params;
    }

    /**
     * @notice Sells tokens and returns base currency according to the bonding curve
     * @dev Includes slippage protection via minPrice parameter
     *      Handles both curve-based and pool-based sales
     * @param token Address of the token to sell
     * @param recipient Address to receive the refund
     * @param amount Amount of tokens to sell. Pass type(uint256).max to sell all tokens
     * @param minPrice Minimum acceptable price per token
     */
    function witnessSell(
        address signer,
        address token,
        address recipient,
        uint256 amount,
        uint256 minPrice
    ) public whenNotPaused returns (TradeParams memory) {
        require(msg.sender == token, UnauthorizedCaller());

        Storage storage $ = _storage();
        Curve memory curve = $.curves[token];

        require(curve.basePair != address(0), TokenNotFound());
        if (amount == type(uint256).max) {
            amount = _getMaxAmount(token, signer);
        }
        require(amount != 0, ZeroAmount());

        TradeParams memory params = TradeParams(signer, recipient, token, amount, minPrice, tradingFee);

        _sell(curve, params);
        // Refund ETH value for the token sold
        _refundNativeValue(recipient);

        return params;
    }

    /**
     * @notice Internal function to calculate token purchase costs using linear bonding curve
     * @dev Implements the main bonding curve calculation:
     *      - Uses constant product formula: (v+r)*t = k where v=virtual_reserve, r=reserve, t=token_reserve
     *      - Calculates cost including trading fees
     *      - Rounds up costs to prevent precision attacks
     * @param curve The bonding curve parameters
     * @param tokenAmount Amount of tokens to purchase
     * @param tradingFee Fee percentage (basis points)
     * @return availableAmount Amount of tokens available for purchase
     * @return cost Total cost in base currency including fees
     * @return fee Trading fee amount in base currency
     * @return priceAfter Price per token after the trade
     * @return issuedSupply Total tokens issued from curve after the trade
     */
    function _estimateTokenCost(
        Curve memory curve,
        uint256 tokenAmount,
        uint16 tradingFee,
        uint256 priceLimit
    )
        internal
        pure
        returns (uint256 availableAmount, uint256 cost, uint256 fee, uint256 priceAfter, uint256 issuedSupply)
    {
        // Calculate available token reserve based on max supply and current reserve
        uint256 initialTokenReserve;
        {
            uint256 maxTokenSupply = 10 ** curve.maxTokenSupplyE * PRECISION;
            initialTokenReserve = maxTokenSupply / curve.totalCurves;
        }
        uint256 virtualReserve = uint256(curve.virtualReserve) * 10 ** curve.virtualReserveE;
        uint256 curveConstant = virtualReserve * initialTokenReserve;
        uint256 tokenReserve = curveConstant / (virtualReserve + curve.reserve);
        issuedSupply = initialTokenReserve - tokenReserve;

        {
            // Calculate maximum amount based on price limit if specified
            if (priceLimit != 0) {
                // Calculate the maximum tokenReserve that would result in priceAfter <= priceLimit
                // priceLimit = PRECISION * curveConstant / (tokenReserve - tokenAmount)^2
                // tokenAmount = tokenReserve - sqrt(PRECISION * curveConstant / priceLimit)
                // Early division prevents overflow: sqrt((PRECISION * virtualReserve / priceLimit) *
                // initialTokenReserve)

                uint256 sqrtValue = Math.sqrt((PRECISION * virtualReserve / priceLimit) * initialTokenReserve);
                if (sqrtValue < tokenReserve) {
                    uint256 maxAmountFromPriceLimit = tokenReserve - sqrtValue;
                    // Take the minimum between requested amount and price limit amount
                    if (maxAmountFromPriceLimit < tokenAmount) {
                        tokenAmount = maxAmountFromPriceLimit;
                    }
                } else {
                    // Current price already exceeds the price limit - zero fill
                    tokenAmount = 0;
                }
            }

            uint256 completionAmount = (10 ** curve.maxTokenSupplyE) * curve.completionThreshold;
            if (issuedSupply + tokenAmount > completionAmount) {
                // Adjust amount if it would exceed completion threshold
                availableAmount = completionAmount > issuedSupply ? completionAmount - issuedSupply : 0;
                tokenAmount = availableAmount;
            } else {
                availableAmount = tokenAmount;
            }
        }

        // Apply constant product formula: (virtual_reserve + reserve) * token_reserve = k
        uint256 curveCost = curveConstant / (tokenReserve - tokenAmount) - virtualReserve - curve.reserve;

        // Round up the cost if there's any remainder to prevent precision attacks
        if ((curveConstant / (tokenReserve - tokenAmount)) * (tokenReserve - tokenAmount) < curveConstant) {
            curveCost += 1;
        }

        // Calculate projected issuedSupply based on new curve reserve
        issuedSupply = initialTokenReserve - (tokenReserve - availableAmount);

        // Calculate and round up minimum fee (1 wei) if percentage would round to 0
        fee = (curveCost * tradingFee) / BIPS_SCALAR;
        if (fee == 0 && tradingFee > 0) {
            fee = 1;
        }

        cost = curveCost + fee;

        // Calculate final token price: base_reserve / token_reserve^2
        // Early division prevents overflow with large reserve values
        uint256 newTokenReserve = tokenReserve - tokenAmount;
        priceAfter = (PRECISION * virtualReserve / newTokenReserve) * initialTokenReserve / newTokenReserve;
    }

    /**
     * @notice Internal function to calculate token amount for given base currency input
     * @dev Implements reverse bonding curve calculation to determine token output
     *      Includes fee calculations and smart rounding protection
     *      Returns tokenAmount - 1 when it would prevent rounding discrepancies
     * @param curve Bonding curve configuration
     * @param baseSpend Amount of base currency to spend
     * @param tradingFee Fee percentage to apply
     * @return tokenAmount Amount of tokens to be received
     */
    function _quoteTokenAmount(
        Curve memory curve,
        uint256 baseSpend,
        uint16 tradingFee
    ) internal pure override returns (uint256 tokenAmount) {
        // Calculate available token reserve based on max supply and current reserve
        uint256 maxTokenSupply = 10 ** curve.maxTokenSupplyE * PRECISION;
        uint256 initialTokenReserve = maxTokenSupply / curve.totalCurves;
        uint256 virtualReserve = uint256(curve.virtualReserve) * 10 ** curve.virtualReserveE;
        uint256 curveConstant = virtualReserve * initialTokenReserve;
        uint256 tokenReserve = curveConstant / (virtualReserve + curve.reserve);

        // curveBudget = 100 % / 101 %, excluding trading fee
        uint256 curveBudget = (BIPS_SCALAR * baseSpend) / (BIPS_SCALAR + tradingFee);
        tokenAmount = tokenReserve - curveConstant / (virtualReserve + curve.reserve + curveBudget);

        if (
            (curveConstant / (tokenReserve - tokenAmount)) * (tokenReserve - tokenAmount) < curveConstant
                && tokenAmount != 0
        ) {
            // Prevent precision attacks by rounding down
            tokenAmount -= 1;
        }
    }

    /**
     * @notice Calculates refund amount for selling tokens using the bonding curve
     * @dev Uses constant product formula k = (v+r)*t for price calculation
     *      Where: v = virtual reserve, r = actual reserve, t = token reserve
     * @param curve Token's bonding curve configuration
     * @param tokenAmount Amount of tokens to sell
     * @param tradingFee Fee percentage in basis points (1 = 0.01%)
     * @param priceLimit Minimum acceptable price per token (0 = no limit)
     * @return tokenAmountIn Amount of tokens that can be sold (adjusted for price limit)
     * @return refund Amount of base currency to return to user
     * @return fee Trading fee to be deducted
     * @return priceAfter Price per token after the sell operation
     * @return issuedSupply New total tokens issued from curve after the trade
     */
    function _estimateTokenRefund(
        Curve memory curve,
        uint256 tokenAmount,
        uint16 tradingFee,
        uint256 priceLimit
    )
        internal
        pure
        returns (uint256 tokenAmountIn, uint256 refund, uint256 fee, uint256 priceAfter, uint256 issuedSupply)
    {
        // Calculate available token reserve based on max supply and current reserve
        uint256 initialTokenReserve;
        {
            uint256 maxTokenSupply = 10 ** curve.maxTokenSupplyE * PRECISION;
            initialTokenReserve = maxTokenSupply / curve.totalCurves;
        }
        uint256 virtualReserve = uint256(curve.virtualReserve) * 10 ** curve.virtualReserveE;
        uint256 curveConstant = virtualReserve * initialTokenReserve;
        uint256 tokenReserve = curveConstant / (virtualReserve + curve.reserve);
        uint256 currentIssuedSupply = initialTokenReserve - tokenReserve;

        {
            // Calculate minimum amount based on price limit if specified
            if (priceLimit != 0) {
                // For selling, we need to find the maximum tokenAmount that results in priceAfter >= priceLimit
                // priceLimit = PRECISION * curveConstant / (tokenReserve + tokenAmount)^2
                // tokenAmount = sqrt(PRECISION * curveConstant / priceLimit) - tokenReserve
                // Early division prevents overflow: sqrt((PRECISION * virtualReserve / priceLimit) *
                // initialTokenReserve)

                uint256 sqrtValue = Math.sqrt((PRECISION * virtualReserve / priceLimit) * initialTokenReserve);
                if (sqrtValue > tokenReserve) {
                    uint256 maxAmountFromPriceLimit = sqrtValue - tokenReserve;
                    // Take the minimum between requested amount and price limit amount
                    if (maxAmountFromPriceLimit < tokenAmount) {
                        tokenAmount = maxAmountFromPriceLimit;
                    }
                } else {
                    // Current price already below the minimum price limit - zero fill
                    tokenAmount = 0;
                }
            }

            if (tokenAmount > currentIssuedSupply) {
                tokenAmount = currentIssuedSupply;
            }
        }

        tokenAmountIn = tokenAmount;
        issuedSupply = currentIssuedSupply - tokenAmount;

        // Calculate refund using bonding curve formula
        uint256 curveRefund = virtualReserve + curve.reserve - curveConstant / (tokenReserve + tokenAmount);

        if (
            (curveConstant / (tokenReserve + tokenAmount)) * (tokenReserve + tokenAmount) < curveConstant
                && curveRefund != 0
        ) {
            // Round down the refund to prevent precision attacks
            curveRefund -= 1;
        }

        // Calculate and ensure minimum fee if applicable
        fee = (curveRefund * tradingFee) / BIPS_SCALAR;

        if (fee == 0 && tradingFee != 0 && curveRefund != 0) {
            fee = 1;
        }

        // Calculate final refund after deducting fee
        refund = curveRefund - fee;

        // Calculate price after sell operation using constant product formula
        // Early division prevents overflow with large reserve values
        uint256 newTokenReserve = tokenReserve + tokenAmount;
        priceAfter = (PRECISION * virtualReserve / newTokenReserve) * initialTokenReserve / newTokenReserve;
    }

    struct BuyContext {
        uint256 completionAmount;
        uint256 buyAmount;
        uint256 cost;
        uint256 issuedSupply;
        uint256 priceAfter;
    }

    /**
     * @dev Internal buy implementation handling both curve and pool-based purchases
     * @param curve Token's bonding curve configuration
     * @param params Trading parameters including amounts and limits
     * @notice This function handles two different trading mechanisms:
     *         1. Bonding curve trades before completion threshold
     *         2. Liquidity pool trades after deployment
     * @notice Also manages:
     *         - Fee collection
     *         - Token transfers from treasury
     *         - ETH refunds
     *         - Liquidity deployment when threshold reached
     */
    function _buy(
        Curve memory curve,
        TradeParams memory params
    ) internal override {
        Storage storage $ = _storage();
        BuyContext memory ctx;

        // Calculate and enforce completion threshold
        ctx.completionAmount = (10 ** curve.maxTokenSupplyE) * curve.completionThreshold;

        // Calculate costs and fees
        {
            uint256 fee;
            (ctx.buyAmount, ctx.cost, fee, ctx.priceAfter, ctx.issuedSupply) =
                _estimateTokenCost(curve, params.amount, params.tradingFee, params.priceLimit);

            // Revert if slippage resulted in zero tokens while not graduating
            if (ctx.buyAmount == 0 && ctx.issuedSupply < ctx.completionAmount) {
                revert ZeroAmount();
            }

            // Update reserve balance and collect fees
            curve.reserve += uint192(ctx.cost - fee);
            $.curves[params.token].reserve = curve.reserve;
            $.collectedFees[params.token] += fee;

            emit TokenTrade(
                params.token,
                params.recipient,
                true,
                ctx.buyAmount,
                ctx.cost,
                ctx.priceAfter,
                ctx.issuedSupply,
                curve.reserve
            );
        }

        address treasuryAddr = address(treasury);
        // Handle payment collection
        if (curve.basePair == wrappedNativeToken && msg.value > 0) {
            if (address(this).balance < ctx.cost) {
                revert InsufficientPayment();
            }
            // Wrap ETH
            IWETH(wrappedNativeToken).deposit{ value: ctx.cost }();
            // Transfer ERC20 tokens to treasury
            IERC20(curve.basePair).safeTransfer(treasuryAddr, ctx.cost);
        } else {
            // Transfer ERC20 tokens to treasury
            IERC20(curve.basePair).safeTransferFrom(params.account, treasuryAddr, ctx.cost);
        }

        // Migrate token from legacy treasury if needed
        _migrateTreasury(params.token);

        // Transfer tokens from treasury to recipient
        treasury.withdraw(params.token, params.recipient, ctx.buyAmount);

        // Check if liquidity deployment threshold is reached
        if (ctx.issuedSupply >= ctx.completionAmount) {
            // Reset completion threshold to zero to indicate deployed liquidity
            $.curves[params.token].completionThreshold = 0;

            // Migrate token from legacy treasury if needed
            _migrateTreasury(curve.basePair);

            uint256 gasLeft = gasleft();

            if (gasLeft < GRACEFUL_EXIT_GAS_RESERVE) {
                // Revert token graduation by restoring completion threshold
                $.curves[params.token].completionThreshold = curve.completionThreshold;
                params.amount = ctx.buyAmount;
                // Graceful failure: liquidity deployment failed, skip post-swap
                emit TokenGraduationPartialFailure(params.token, 0, gasleft());
                return;
            }

            // Deploy liquidity via module with gas limit for graceful failure
            (bool success, bytes memory data) = liquidityModule.delegatecall{
                gas: gasLeft - GRACEFUL_EXIT_GAS_RESERVE
            }(
                abi.encodeCall(
                    ILiquidityModule.deployLiquidity,
                    (ILiquidityModule.LiquidityDeployParams({
                            curve: curve, token: params.token, issuedSupply: ctx.completionAmount, treasury: treasury
                        }))
                )
            );

            if (!success) {
                // Revert token graduation by restoring completion threshold
                $.curves[params.token].completionThreshold = curve.completionThreshold;
                params.amount = ctx.buyAmount;
                // Graceful failure: liquidity deployment failed, skip post-swap
                emit TokenGraduationPartialFailure(params.token, 0, gasleft());
                return;
            }

            // Store liquidity lock IDs and handle collected fees
            (uint256 lockId0, uint256 lockId1, uint256 collectedFees) = abi.decode(data, (uint256, uint256, uint256));
            $.liquidityLocks[params.token] = [lockId0, lockId1];

            if (collectedFees > 0) {
                $.collectedFees[params.token] += collectedFees;
                IERC20(curve.basePair).safeTransfer(address(treasury), collectedFees);
            }

            // NOTE: remaining spend should not be affected by liquidity deployment
            //       as native value was not wrapped and ERC20 not transferred from user

            // Route the rest of the trade to deployed liquidity
            uint256 remainingTokens = params.amount - ctx.buyAmount;

            if (remainingTokens > 0) {
                params.amount = remainingTokens;
                // Set completion threshold to 100% to bypass graduation logic
                curve.completionThreshold = uint64(PRECISION / curve.totalCurves);
                (, uint256 originalCost,,,) =
                    _estimateTokenCost(curve, remainingTokens, params.tradingFee, params.priceLimit);

                // Get max available funds from user
                uint256 maxAvailable = _getMaxAmount(curve.basePair, params.account);

                // Use minimum of actualCost and maxAvailable
                uint256 remainingSpend = originalCost < maxAvailable ? originalCost : maxAvailable;

                if (remainingSpend > 0) {
                    params.amount = remainingSpend;
                    params.amount = ctx.buyAmount + _spendInLiquidityPool(curve, params, true);
                } else {
                    params.amount = ctx.buyAmount;
                }
            } else {
                params.amount = ctx.buyAmount;
            }

            emit TokenGraduated(params.token, ctx.completionAmount);
        }
    }

    /**
     * @notice Internal implementation of token selling logic
     * @dev Handles both curve-based and pool-based token sales
     *      Includes slippage protection and fee collection
     * @param curve Curve configuration for the token
     * @param params Parameters for the token sale
     */
    function _sell(
        Curve memory curve,
        TradeParams memory params
    ) internal {
        Storage storage $ = _storage();

        // Route to liquidity pool if available
        if (curve.completionThreshold == 0) {
            _sellToLiquidityPool(curve, params);
            return;
        }

        // Calculate refund amount and fees
        (uint256 availableAmount, uint256 refund, uint256 fee, uint256 priceAfter, uint256 issuedSupply) =
            _estimateTokenRefund(curve, params.amount, params.tradingFee, params.priceLimit);
        params.amount = availableAmount;

        // Revert if slippage resulted in zero refund
        require(refund != 0, ZeroAmount());

        // Transfer tokens from seller to treasury
        IERC20(params.token).safeTransferFrom(params.account, address(treasury), params.amount);

        // Update reserve balance and collect fees
        curve.reserve -= uint192(refund + fee);
        $.curves[params.token].reserve = curve.reserve;
        $.collectedFees[params.token] += fee;

        emit TokenTrade(
            params.token, params.recipient, false, params.amount, refund, priceAfter, issuedSupply, curve.reserve
        );

        // Process refund payment
        if (refund > 0) {
            // Migrate token from legacy treasury if needed
            _migrateTreasury(curve.basePair);

            if (curve.basePair == wrappedNativeToken) {
                treasury.withdraw(curve.basePair, address(this), refund);
                // Unwrap WETH into ETH
                IWETH(wrappedNativeToken).withdraw(refund);
                // ETH is refunded later in sell function
            } else {
                treasury.withdraw(curve.basePair, params.recipient, refund);
            }
        }
    }

    /**
     * @notice Converts price limit to sqrtPriceLimitX96 format for AMM swaps
     * @dev Uses token ordering to determine if price inversion is needed
     * @param basePair Quote token address
     * @param token Telecoin address
     * @param priceLimit Price limit in PRECISION units (basePair per token)
     * @return sqrtPriceLimitX96 Price limit in X96 sqrt format, 0 if no limit
     */
    function _convertPriceLimitToSqrtX96(
        address basePair,
        address token,
        uint256 priceLimit
    ) internal pure returns (uint160 sqrtPriceLimitX96) {
        if (priceLimit == 0) {
            return 0;
        }

        uint256 adjustedPriceLimit;
        if (token > basePair) {
            // Token ordering reversed, invert price
            adjustedPriceLimit = (PRECISION * PRECISION) / priceLimit;
        } else {
            // Token ordering matches, use price as-is
            adjustedPriceLimit = priceLimit;
        }

        // Calculate square root price in X96 format
        sqrtPriceLimitX96 = adjustedPriceLimit.toSqrtPriceX96();
    }

    /**
     * @notice Executes a buy order through the liquidity pool
     * @dev Handles token swaps via the liquidity module
     *      Uses sqrtPriceLimitX96 for partial fills instead of amountOutMinimum
     * @param curve Curve configuration containing pool details
     * @param params Trading parameters and limits
     * @param gracefulFailure If true, return 0 on failure instead of reverting (for graduation flow)
     */
    function _spendInLiquidityPool(
        Curve memory curve,
        TradeParams memory params,
        bool gracefulFailure
    ) internal returns (uint256 amountOut) {
        // Calculate sqrtPriceLimitX96 from price limit for partial fills
        uint160 sqrtPriceLimitX96 = _convertPriceLimitToSqrtX96(curve.basePair, params.token, params.priceLimit);

        // Setup swap parameters for liquidity module
        ILiquidityModule.SwapParams memory swapParams = ILiquidityModule.SwapParams({
            tokenIn: curve.basePair,
            tokenOut: params.token,
            amountIn: params.amount,
            amountOutMinimum: 0, // Set to 0 to allow partial fills
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            recipient: params.recipient
        });

        // If input token is WETH and we received ETH, wrap it first
        if (curve.basePair == wrappedNativeToken && msg.value > 0) {
            // value should be sufficient for the amount or be equal to 0
            if (msg.value < params.amount) {
                revert InsufficientPayment();
            }
            IWETH(wrappedNativeToken).deposit{ value: params.amount }();
        } else {
            IERC20(curve.basePair).safeTransferFrom(params.account, address(this), params.amount);
        }

        {
            // Execute swap via delegatecall with gas limiting for graceful failures
            uint256 gasLeft = gasleft();
            bool success;
            bytes memory data;
            if (gasLeft > GRACEFUL_EXIT_GAS_RESERVE) {
                uint256 gasLimit = gracefulFailure ? gasLeft - GRACEFUL_EXIT_GAS_RESERVE : gasLeft;
                (success, data) = liquidityModule.delegatecall{ gas: gasLimit }(
                    abi.encodeWithSelector(ILiquidityModule.executeSwap.selector, swapParams)
                );
            }

            if (success) {
                (amountOut) = abi.decode(data, (uint256));
            } else {
                if (gracefulFailure) {
                    emit TokenGraduationPartialFailure(params.token, 1, gasleft());
                } else {
                    // Bubble up the actual AMM error
                    if (data.length == 0) {
                        revert SwapFailed();
                    }
                    assembly {
                        revert(add(data, 0x20), mload(data))
                    }
                }
            }
        }

        // Handle leftover refund if needed
        uint256 balance = IERC20(curve.basePair).balanceOf(address(this));

        if (balance > 0) {
            if (curve.basePair == wrappedNativeToken) {
                // Unwrap WETH into ETH
                IWETH(wrappedNativeToken).withdraw(balance);
                // ETH is refunded later in buy function
            } else {
                IERC20(curve.basePair).safeTransfer(params.recipient, balance);
            }
        }
    }

    /**
     * @notice Executes a sell order through the liquidity pool
     * @dev Transfers tokens from seller and executes swap
     *      Uses sqrtPriceLimitX96 for partial fills instead of amountOutMinimum
     * @param curve Curve configuration containing pool details
     * @param params Trading parameters and limits
     */
    function _sellToLiquidityPool(
        Curve memory curve,
        TradeParams memory params
    ) internal {
        // Transfer tokens from seller to contract
        IERC20(params.token).safeTransferFrom(params.account, address(this), params.amount);

        // Calculate sqrtPriceLimitX96 from price limit for partial fills
        uint160 sqrtPriceLimitX96 = _convertPriceLimitToSqrtX96(curve.basePair, params.token, params.priceLimit);

        // Setup swap parameters
        ILiquidityModule.SwapParams memory swapParams = ILiquidityModule.SwapParams({
            tokenIn: params.token,
            tokenOut: curve.basePair,
            amountIn: params.amount,
            amountOutMinimum: 0, // Set to 0 to allow partial fills
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            recipient: curve.basePair == wrappedNativeToken ? address(this) : params.recipient
        });

        // Execute swap via delegatecall
        (bool success, bytes memory data) =
            liquidityModule.delegatecall(abi.encodeWithSelector(ILiquidityModule.executeSwap.selector, swapParams));

        if (!success) {
            // Bubble up the actual AMM error
            if (data.length == 0) {
                revert SwapFailed();
            }
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }

        if (curve.basePair == wrappedNativeToken) {
            uint256 amountOut = abi.decode(data, (uint256));
            // Unwrap WETH into ETH
            IWETH(wrappedNativeToken).withdraw(amountOut);
            // ETH is refunded later in sell function
        }

        // Handle token leftover if needed
        uint256 balance = IERC20(params.token).balanceOf(address(this));

        if (balance > 0) {
            IERC20(params.token).safeTransfer(params.recipient, balance);
        }
    }

    /**
     * @notice Internal function to get liquidity quote for exact output amount
     * @dev Queries liquidity module for swap pricing with exact output
     * @param params Trade parameters including token, amount, and price limit
     * @param curve Bonding curve configuration for issued supply calculation
     * @return availableAmount Amount of tokens available for purchase
     * @return cost Total cost in base currency
     * @return fee Trading fee (0 for liquidity trades)
     * @return priceAfter Final price per token
     * @return issuedSupply Approximated issued supply
     */
    function _quoteLiquidityExactOutput(
        TradeParams memory params,
        Curve memory curve
    ) internal returns (uint256 availableAmount, uint256 cost, uint256 fee, uint256 priceAfter, uint256 issuedSupply) {
        // Build swap parameters for quoting (include price limit to simulate user's constraints)
        ILiquidityModule.SwapParams memory swapParams = ILiquidityModule.SwapParams({
            tokenIn: curve.basePair,
            tokenOut: params.token,
            amountIn: 0,
            amountOutMinimum: params.amount,
            sqrtPriceLimitX96: _convertPriceLimitToSqrtX96(curve.basePair, params.token, params.priceLimit),
            recipient: address(0)
        });

        // Get quote from liquidity module
        (bool success, bytes memory data) =
            liquidityModule.delegatecall(abi.encodeWithSelector(ILiquidityModule.quoteExactOutput.selector, swapParams));

        if (success && data.length > 0) {
            uint256 ammFeeBips;
            (cost, priceAfter, ammFeeBips) = abi.decode(data, (uint256, uint256, uint256));

            // Validate quote result
            if (cost == 0 || cost == type(uint256).max) {
                revert InvalidQuoteResult();
            }

            // The liquidity module returns price in token0/token1 terms
            // We want the price as "basePair per Telecoin"
            if (params.token > curve.basePair) {
                // basePair is token1, Telecoin is token0: need to invert
                priceAfter = (PRECISION * PRECISION) / priceAfter;
            }

            // Calculate the fee based on the AMM's fee tier in basePair terms.
            // ammFeeBips is the Uniswap V3 fee tier in 1/UNISWAP_FEE_SCALAR units
            // (3000 = 0.30%, 10000 = 1.00%); divide by that scalar, not Printr's
            // BIPS_SCALAR (which is 1/10_000).
            if (swapParams.tokenIn == curve.basePair) {
                // Buying with basePair: fee is a percentage of the cost
                fee = (cost * ammFeeBips) / UNISWAP_FEE_SCALAR;
            } else {
                // Selling for exact output: cost is in Telecoin, convert fee to basePair
                uint256 feeInTokenIn = (cost * ammFeeBips) / UNISWAP_FEE_SCALAR;
                fee = (feeInTokenIn * priceAfter) / PRECISION;
            }
            availableAmount = swapParams.amountOutMinimum;

            // For graduated tokens, ALL supply for this chain has been issued
            uint256 maxTokenSupply = 10 ** curve.maxTokenSupplyE * PRECISION;
            issuedSupply = maxTokenSupply / curve.totalCurves;

            return (availableAmount, cost, fee, priceAfter, issuedSupply);
        } else {
            revert InvalidQuoteResult();
        }
    }

}
