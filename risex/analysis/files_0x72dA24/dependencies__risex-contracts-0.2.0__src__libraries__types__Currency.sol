// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

/// @notice A user-defined value type wrapping an `address` to represent a token currency
/// @dev Provides type-safe token address handling with operator overloads for comparison.
///      Wrap with `Currency.wrap(addr)` and unwrap with `Currency.unwrap(c)`.
type Currency is address;

using { greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=, equals as == } for Currency global;

/// @notice Checks equality of two Currency values by comparing their underlying addresses
/// @param currency The first currency to compare
/// @param other The second currency to compare
/// @return True if both currencies wrap the same address
function equals(
    Currency currency,
    Currency other
) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

/// @notice Checks if one Currency is strictly greater than another by address ordering
/// @param currency The left-hand side currency
/// @param other The right-hand side currency
/// @return True if `currency` wraps a numerically greater address than `other`
function greaterThan(
    Currency currency,
    Currency other
) pure returns (bool) {
    return Currency.unwrap(currency) > Currency.unwrap(other);
}

/// @notice Checks if one Currency is strictly less than another by address ordering
/// @param currency The left-hand side currency
/// @param other The right-hand side currency
/// @return True if `currency` wraps a numerically smaller address than `other`
function lessThan(
    Currency currency,
    Currency other
) pure returns (bool) {
    return Currency.unwrap(currency) < Currency.unwrap(other);
}

/// @notice Checks if one Currency is greater than or equal to another by address ordering
/// @param currency The left-hand side currency
/// @param other The right-hand side currency
/// @return True if `currency` wraps a numerically greater or equal address compared to `other`
function greaterThanOrEqualTo(
    Currency currency,
    Currency other
) pure returns (bool) {
    return Currency.unwrap(currency) >= Currency.unwrap(other);
}
