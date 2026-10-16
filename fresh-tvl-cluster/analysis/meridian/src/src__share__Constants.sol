// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

bytes32 constant USD_TOKEN_NAME = "USD";
string constant EXCHANGE_NAME = "Meridian";
string constant EXCHANGE_VERSION = "1";

/// @dev Realized PnL tolerance for a worst-case 10_000_000_000_000 USD match notional:
/// 10_000_000_000_000 USD * 1_000_000_000 raw units/USD = 10_000_000_000_000_000_000_000 raw units,
/// ceil(notional / 2^52) = 2_220_447 raw units, plus 1 raw unit for integer rounding.
uint128 constant WORST_CASE_REALIZED_PNL_ERROR = 2_220_448;
