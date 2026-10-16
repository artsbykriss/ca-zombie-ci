// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVestingCalculator.sol";

/**
 * @title VestingCalculator
 * @dev Contract for calculating vesting schedules with different vesting types (linear, exponential, interval)
 * @notice This contract handles the logic for computing vested token amounts based on various vesting schedules
 */
contract VestingCalculator is IVestingCalculator {
    using Math for uint256;

   

    constructor() {
       
    }

     


    /**
     * @dev Validates the time-amount pairs for a vesting schedule
     * @param tranches Array of time-amount pairs to validate
     */
    function _validateTranches(TimeAmount[] calldata tranches) internal pure {
        // First check if we have at least 2 tranches
        if (tranches.length < 2) revert InvalidTranches();


        // Then validate the sequence
        for (uint256 i = 1; i < tranches.length; i++) {
            if (tranches[i].time <= tranches[i-1].time) {
                revert TimesMustBeInAscendingOrder();
            }
            if (tranches[i].amount < tranches[i-1].amount) {
                revert AmountsMustBeIncreasing();
            }
        }
    }


    /**
     * @dev Calculates the vested amount at a specific time
     * @param tranches Array of time-amount pairs defining the vesting schedule
     * @param currentTime The timestamp to calculate vested amount for
     * @return The amount vested at the specified time
     */
    function calculateVestedAmount(
        TimeAmount[] calldata tranches,
        uint256 currentTime
    ) public view returns (uint256) {
        // Then validate other tranche properties
        _validateTranches(tranches);

        // Before first tranche
        if (currentTime <= tranches[0].time) {
            return 0;
        }

        // After last tranche
        if (currentTime >= tranches[tranches.length - 1].time) {
            return tranches[tranches.length - 1].amount;
        }

        return _calculateVestingForPeriod(tranches, currentTime);
    }

    /**
     * @dev Internal function to calculate vesting amount for a specific period
     * @param tranches Array of time-amount pairs
     * @param currentTime The timestamp to calculate vested amount for
     * @return The vested amount for the period
     */
    function _calculateVestingForPeriod(
        TimeAmount[] calldata tranches,
        uint256 currentTime
    ) internal view returns (uint256) {
        // Find the relevant tranche
        uint256 i;
        for (i = 1; i < tranches.length; i++) {
            if (currentTime <= tranches[i].time) {
                break;
            }
        }

        uint256 startTime = tranches[i - 1].time;
        uint256 endTime = tranches[i].time;
        uint256 startAmount = tranches[i - 1].amount;
        uint256 endAmount = tranches[i].amount;
        EquationType eqType = tranches[i - 1].eqType;

        if (eqType == EquationType.LINEAR) {
            return _calculateLinearVesting(
                startTime,
                endTime,
                startAmount,
                endAmount,
                currentTime
            );
        } else if (eqType == EquationType.EXPONENTIAL) {
            return _calculateExponentialVesting(
                startTime,
                endTime,
                startAmount,
                endAmount,
                currentTime,
                2e18
            );
        } else if (eqType == EquationType.INTERVAL) {
            return endAmount;
        } else if (eqType == EquationType.QUADRATIC) {
            return _calculateQuadraticVesting(
                startTime,
                endTime,
                startAmount,
                endAmount,
                currentTime
            );
        } else {
            revert InvalidEquationType();
        }
    }

    /**
     * @dev Calculates vested amount using linear vesting formula
     * @param startTime Start time of the vesting period
     * @param endTime End time of the vesting period
     * @param startAmount Amount at start of period
     * @param endAmount Amount at end of period
     * @param currentTime Current timestamp
     * @return The linearly vested amount
     */
    function _calculateLinearVesting(
        uint256 startTime,
        uint256 endTime,
        uint256 startAmount,
        uint256 endAmount,
        uint256 currentTime
    ) internal pure returns (uint256) {
        uint256 timeElapsed = currentTime - startTime;
        uint256 totalDuration = endTime - startTime;
        uint256 amountDiff = endAmount - startAmount;

        // Calculate progress with 1e18 precision
        uint256 progress = (timeElapsed * 1e18) / totalDuration;
        
        // Calculate vested amount using the high precision progress
        uint256 vestedDiff = (amountDiff * progress) / 1e18;
        
        return startAmount + vestedDiff;
    }

    /**
     * @dev Calculates vested amount using exponential vesting formula
     * @param startTime Start time of the vesting period
     * @param endTime End time of the vesting period
     * @param startAmount Amount at start of period
     * @param endAmount Amount at end of period
     * @param currentTime Current timestamp
     * @param exponent Exponent for the vesting curve
     * @return The exponentially vested amount
     */
    function _calculateExponentialVesting(
        uint256 startTime,
        uint256 endTime,
        uint256 startAmount,
        uint256 endAmount,
        uint256 currentTime,
        uint256 exponent
    ) internal pure returns (uint256) {
        uint256 timeElapsed = currentTime - startTime;
        uint256 totalDuration = endTime - startTime;
        uint256 amountDiff = endAmount - startAmount;

        uint256 timeProgress = (timeElapsed * 1e18) / totalDuration;
        
        // Calculate timeProgress^exponent with better precision
        uint256 expProgress = timeProgress;
        uint256 scaledExponent = exponent / 1e18;
        
        // Handle exponent = 1 case separately
        if (scaledExponent == 1) {
            return startAmount + (amountDiff * timeProgress) / 1e18;
        }
        
        // For exponents > 1, calculate power iteratively
        for (uint256 i = 1; i < scaledExponent; i++) {
            expProgress = (expProgress * timeProgress) / 1e18;
        }

        return startAmount + (amountDiff * expProgress) / 1e18;
    }

    /**
     * @dev Calculates vested amount using quadratic vesting formula
     * @param startTime Start time of the vesting period
     * @param endTime End time of the vesting period
     * @param startAmount Amount at start of period
     * @param endAmount Amount at end of period
     * @param currentTime Current timestamp
     * @return The quadratically vested amount
     */
    function _calculateQuadraticVesting(
        uint256 startTime,
        uint256 endTime,
        uint256 startAmount,
        uint256 endAmount,
        uint256 currentTime
    ) internal pure returns (uint256) {
        // Redirect to exponential with n=2
        return _calculateExponentialVesting(
            startTime,
            endTime,
            startAmount,
            endAmount,
            currentTime,
            2e18  // Quadratic is just exponential with n=2
        );
    }

    /**
     * @dev Gets the total amount to be vested
     * @param tranches Array of time-amount pairs defining the vesting schedule
     * @return The total amount to be vested
     */
    function getTotalAmount(TimeAmount[] calldata tranches) public pure returns (uint256) {
        _validateTranches(tranches);
        return tranches[tranches.length - 1].amount;
    }
} 