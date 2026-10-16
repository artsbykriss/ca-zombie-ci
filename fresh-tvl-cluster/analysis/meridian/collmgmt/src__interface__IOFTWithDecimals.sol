// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IOFT} from "@layerzerolabs/lz-evm-oapp-v2/oft/interfaces/IOFT.sol";

/**
 * @title IOFTWithDecimals
 * @dev Extended interface for OFT that includes decimal conversion rate access
 * @dev This extends the standard IOFT interface to include decimalConversionRate()
 * which is available as a public variable in OFTCore implementations
 */
interface IOFTWithDecimals is IOFT {
    /**
     * @notice Retrieves the decimal conversion rate of the OFT.
     * @return decimalConversionRate The decimal conversion rate (10^(localDecimals - sharedDecimals)).
     * @dev This rate is used to convert between local decimals and shared decimals for cross-chain transfers.
     */
    function decimalConversionRate() external view returns (uint256);
}
