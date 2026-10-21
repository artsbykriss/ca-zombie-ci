// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title PricingLibrary
/// @notice Provides pricing calculations for AMM swaps using constant product formula with dynamic fees.

library PricingLibrary {
    error INSUFFICIENT_INPUT_AMOUNT();
    error EMPTY_RESERVE();
    error INSUFFICIENT_TOKENS();
    error INSUFFICIENT_LIQUIDITY();
    // Fee equal to (or above) the denominator makes the fee gross-up divide by zero.
    error FEE_TOO_HIGH();

    struct PriceBreakdown {
        uint256 totalAmount; // Total price/tokens including fees
        uint256 feeAmount; // Fee amount (totalPrice - priceWithoutFee)
    }

    /**
     * @notice Ceiling division - rounds up to protect protocol from precision loss
     * @param a Numerator
     * @param b Denominator
     * @return result Ceiling of a/b
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256 result) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice How much currency will I get if a sell this number of shares.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for currency amount.
     * @param _playerTokenAmountTosell Amount of player token in
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _currencyReserve Amount of currency in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return currencyAmountOut Amount of currency out
     */
    function sellNumShares(
        //quoteUSDCOutForExactTokenIn
        uint256 _playerTokenAmountTosell,
        uint256 _playerTokenReserve,
        uint256 _currencyReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (uint256 currencyAmountOut) {
        if (_playerTokenAmountTosell == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (_playerTokenReserve == 0 || _currencyReserve == 0) revert EMPTY_RESERVE();

        // First calculate raw currency output without fee
        uint256 numerator = _playerTokenAmountTosell * _currencyReserve;
        uint256 denominator = _playerTokenReserve + _playerTokenAmountTosell;
        uint256 rawCurrencyOutput = numerator / denominator;
        
        // Then apply fee by reducing the currency output
        currencyAmountOut = (rawCurrencyOutput * (_feeBasisPointsDenominator - _lpFeeBasisPoints)) / _feeBasisPointsDenominator;
    }

    /**
     * @notice How much currency will I get if a sell this number of shares. Without fee.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for currency amount.
     * @param _playerTokenAmountTosell Amount of player token in
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _currencyReserve Amount of currency in reserve
     * @return currencyAmountOut Amount of currency out
     */
    function sellNumSharesWithoutFee(
        //quoteUSDCOutForExactTokenIn
        uint256 _playerTokenAmountTosell,
        uint256 _playerTokenReserve,
        uint256 _currencyReserve
    ) internal pure returns (uint256 currencyAmountOut) {
        if (_playerTokenAmountTosell == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (_playerTokenReserve == 0 || _currencyReserve == 0) revert EMPTY_RESERVE();

        // First calculate raw currency output without fee
        uint256 numerator = _playerTokenAmountTosell * _currencyReserve;
        uint256 denominator = _playerTokenReserve + _playerTokenAmountTosell;
        return numerator / denominator;
    }

    /**
     * @notice How much currency will I get if I sell this number of shares. With breakdown.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for currency amount.
     * @param _playerTokenAmountTosell Amount of player token in
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _currencyReserve Amount of currency in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return breakdown PriceBreakdown struct containing total price and fee amount.
     */
    function sellNumSharesWithBreakdown(
        uint256 _playerTokenAmountTosell,
        uint256 _playerTokenReserve,
        uint256 _currencyReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (PriceBreakdown memory breakdown) {
        if (_playerTokenAmountTosell == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (_playerTokenReserve == 0 || _currencyReserve == 0) revert EMPTY_RESERVE();

        // First calculate raw currency output without fee
        uint256 numerator = _playerTokenAmountTosell * _currencyReserve;
        uint256 denominator = _playerTokenReserve + _playerTokenAmountTosell;
        uint256 rawCurrencyOutput = numerator / denominator;
        
        // Then apply fee by reducing the currency output
        uint256 currencyAmountOut = (rawCurrencyOutput * (_feeBasisPointsDenominator - _lpFeeBasisPoints)) / _feeBasisPointsDenominator;

        breakdown = PriceBreakdown({
            totalAmount: currencyAmountOut,
            feeAmount: rawCurrencyOutput - currencyAmountOut
        });
    }

    /**
     * @notice How many shares will I receive if I spend this much currency. With breakdown.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for token amount.
     * @param currencyIn Amount of currency in
     * @param currencyReserve Amount of currency in reserve
     * @param playerTokenReserve Amount of player token in reserve
     * @param feeMultiplier Fee multiplier
     * @param feeDenominator Fee denominator
     * @return breakdown PriceBreakdown struct containing total price and fee amount.
     */
    //quoteTokensOutForExactUSDCIN
    function spendCurrencyForSharesWithBreakdown(
        uint256 currencyIn,
        uint256 currencyReserve,
        uint256 playerTokenReserve,
        uint256 feeMultiplier,
        uint256 feeDenominator
    ) internal pure returns (PriceBreakdown memory breakdown) {
        if (currencyIn == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (currencyReserve == 0 || playerTokenReserve == 0) revert EMPTY_RESERVE();

        uint256 currencyInWithFee = (currencyIn * (feeDenominator - feeMultiplier)) / feeDenominator;
        uint256 numerator = currencyInWithFee * playerTokenReserve;
        uint256 denominator = currencyReserve + currencyInWithFee;
        uint256 playerTokenAmountOut = numerator / denominator;

        breakdown = PriceBreakdown({
            totalAmount: playerTokenAmountOut,
            feeAmount: currencyIn - currencyInWithFee
        });
    }

    /**
     * @notice How many player tokens can be bought for a given currency amount, without fee.
     * @param currencyIn Amount of currency to spend
     * @param currencyReserve Amount of currency in reserve
     * @param playerTokenReserve Amount of player token in reserve
     * @return playerTokenAmountOut Amount of player tokens that can be bought
     */
    function spendCurrencyForSharesWithoutFee(
        uint256 currencyIn,
        uint256 currencyReserve,
        uint256 playerTokenReserve
    ) internal pure returns (uint256 playerTokenAmountOut) {
        if (currencyIn == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (currencyReserve == 0 || playerTokenReserve == 0) revert EMPTY_RESERVE();

        uint256 numerator = currencyIn * playerTokenReserve;
        uint256 denominator = currencyReserve + currencyIn;
        playerTokenAmountOut = numerator / denominator;
    }

    /**
     * @notice How much currency will it cost to buy a specific number of shares.
     * @param _playerTokenAmountToBuy Amount of player tokens to buy
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return price Amount of currency in
     */
    function buyNumShares(
        uint256 _playerTokenAmountToBuy,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (uint256 price) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_playerTokenAmountToBuy >= _playerTokenReserve) revert INSUFFICIENT_TOKENS();
        if (_lpFeeBasisPoints >= _feeBasisPointsDenominator) revert FEE_TOO_HIGH();

        // Calculate exactly how much currency the AMM needs to maintain constant product
        // Round UP to ensure K invariant is maintained
        uint256 numerator = _currencyReserve * _playerTokenAmountToBuy;
        uint256 denominator = _playerTokenReserve - _playerTokenAmountToBuy;
        uint256 ammNeedsAmount = ceilDiv(numerator, denominator);

        // Calculate what user must pay total so that after fees, AMM gets exactly ammNeedsAmount
        // Round UP to ensure protocol receives enough currency
        // If ammNeedsAmount = userPays * (1 - feeRate), then userPays = ammNeedsAmount / (1 - feeRate)
        price = ceilDiv(ammNeedsAmount * _feeBasisPointsDenominator, _feeBasisPointsDenominator - _lpFeeBasisPoints);
    }

    /**
     * @notice How much currency will it cost to buy a specific number of shares. Without fee.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for currency amount.
     * @param _playerTokenAmountToBuy Amount of player tokens to buy
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @return price Amount of currency in
     */
    function buyNumSharesWithoutFee(
        uint256 _playerTokenAmountToBuy,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve
    ) internal pure returns (uint256 price) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_playerTokenAmountToBuy >= _playerTokenReserve) revert INSUFFICIENT_TOKENS();

        // Round UP to ensure K invariant is maintained
        uint256 numerator = _currencyReserve * _playerTokenAmountToBuy;
        uint256 denominator = _playerTokenReserve - _playerTokenAmountToBuy;
        price = ceilDiv(numerator, denominator);
    }

    /**
     * @notice How much currency will it cost to buy a specific number of shares. With breakdown.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for currency amount.
     * @param _playerTokenAmountToBuy Amount of player tokens to buy
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return breakdown PriceBreakdown struct containing total price and fee amount.
     */
    function buyNumSharesWithBreakdown(
        uint256 _playerTokenAmountToBuy,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (PriceBreakdown memory breakdown) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_playerTokenAmountToBuy >= _playerTokenReserve) revert INSUFFICIENT_TOKENS();
        if (_lpFeeBasisPoints >= _feeBasisPointsDenominator) revert FEE_TOO_HIGH();

        // Calculate exactly how much currency the AMM needs to maintain constant product
        // Round UP to ensure K invariant is maintained
        uint256 numerator = _currencyReserve * _playerTokenAmountToBuy;
        uint256 denominator = _playerTokenReserve - _playerTokenAmountToBuy;
        uint256 ammNeedsAmount = ceilDiv(numerator, denominator);

        // Calculate what user must pay total so that after fees, AMM gets exactly ammNeedsAmount
        // Round UP to ensure protocol receives enough currency
        // If ammNeedsAmount = userPays * (1 - feeRate), then userPays = ammNeedsAmount / (1 - feeRate)
        uint256 totalPrice = ceilDiv(ammNeedsAmount * _feeBasisPointsDenominator, _feeBasisPointsDenominator - _lpFeeBasisPoints);

        breakdown = PriceBreakdown({
            totalAmount: totalPrice,
            feeAmount: totalPrice - ammNeedsAmount
        });
    }
 
    /**
     * @notice How many shares would I need to sell to get a target amount of currency.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for token amount.
     * @param _currencyWantedAmount Amount of currency wanted to receive
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return tokenAmountIn Amount of tokens in
     */
    function sellSharesForTargetCurrencyAmount(
        uint256 _currencyWantedAmount,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (uint256 tokenAmountIn) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_currencyWantedAmount >= _currencyReserve) revert INSUFFICIENT_LIQUIDITY();
        if (_lpFeeBasisPoints >= _feeBasisPointsDenominator) revert FEE_TOO_HIGH();

        // Calculate how much currency AMM needs to provide before fees are applied
        // If user gets _currencyWantedAmount after fees, AMM needs to provide more before fees
        uint256 currencyBeforeFees = (_currencyWantedAmount * _feeBasisPointsDenominator) / (_feeBasisPointsDenominator - _lpFeeBasisPoints);

        // Now calculate tokens needed for AMM to provide currencyBeforeFees
        uint256 numerator = _playerTokenReserve * currencyBeforeFees;
        uint256 denominator = _currencyReserve - currencyBeforeFees;
        tokenAmountIn = numerator / denominator;
    }

    /**
     * @notice How many shares would I need to sell to get a target amount of currency. With breakdown.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for token amount.
     * @param _currencyWantedAmount Amount of currency wanted to receive
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @param _lpFeeBasisPoints LP fee basis points
     * @param _feeBasisPointsDenominator Fee basis points denominator
     * @return breakdown PriceBreakdown struct containing total price and fee amount.
     */
    function sellSharesForTargetCurrencyAmountWithBreakdown(
        uint256 _currencyWantedAmount,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve,
        uint256 _lpFeeBasisPoints,
        uint256 _feeBasisPointsDenominator
    ) internal pure returns (PriceBreakdown memory breakdown) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_currencyWantedAmount >= _currencyReserve) revert INSUFFICIENT_LIQUIDITY();
        if (_lpFeeBasisPoints >= _feeBasisPointsDenominator) revert FEE_TOO_HIGH();

        // Calculate how much currency AMM needs to provide before fees are applied
        // If user gets _currencyWantedAmount after fees, AMM needs to provide more before fees
        uint256 currencyBeforeFees = (_currencyWantedAmount * _feeBasisPointsDenominator) / (_feeBasisPointsDenominator - _lpFeeBasisPoints);

        // Calculate tokens needed for AMM to provide currencyBeforeFees
        uint256 numerator = _playerTokenReserve * currencyBeforeFees;
        uint256 denominator = _currencyReserve - currencyBeforeFees;
        uint256 tokensNeeded = numerator / denominator;

        // Fee is the difference between what AMM provides and what user receives
        uint256 feeAmountInCurrency = currencyBeforeFees - _currencyWantedAmount;

        breakdown = PriceBreakdown({
            totalAmount: tokensNeeded,
            feeAmount: feeAmountInCurrency
        });
    }

    /**
     * @notice How many shares would I need to sell to get a target amount of currency. Without fee.
     * @dev Uses the same constant product formula as Uniswap V2 but solves for token amount.
     * @param _currencyWantedAmount Amount of currency wanted to receive
     * @param _currencyReserve Amount of currency in reserve
     * @param _playerTokenReserve Amount of player token in reserve
     * @return tokenAmountIn Amount of tokens in
     */
    function sellSharesForTargetCurrencyAmountWithoutFee(
        uint256 _currencyWantedAmount,
        uint256 _currencyReserve,
        uint256 _playerTokenReserve
    ) internal pure returns (uint256 tokenAmountIn) {
        if (_currencyReserve == 0 || _playerTokenReserve == 0) revert EMPTY_RESERVE();
        if (_currencyWantedAmount >= _currencyReserve) revert INSUFFICIENT_LIQUIDITY();

        uint256 numerator = _playerTokenReserve * _currencyWantedAmount;
        uint256 denominator = _currencyReserve - _currencyWantedAmount;
        tokenAmountIn = numerator / denominator;
    }
}