// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

/**
 * @title IPriceProvider
 * @notice Minimal interface for price providers used by `Pricer`.
 */
interface IPriceProvider {
    function getPrice() external view returns (uint256);
    function decimals() external view returns (uint8);
}
