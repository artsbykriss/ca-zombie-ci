// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Linear Rate Model - epoch version
 * @author Deepr
 */
contract LinearRateModel {
    event SetNewParameters(uint amountOfTokens, uint totalOfEpochs, uint epochSeconds, uint initBlock);
    event SetNewTimelockAddress(address timelockAddress);

    /**
     * @notice Timelock address.
     */
    address public timelockAddress;

    /**
     * @notice Total amount of tokens to be distributed by the model
     */
    uint public amountOfTokens;

    /**
     * @notice The x-value (epoch in our case) which is the x-intersect when the y-value (rate in our case) is 0 - Number of Epochs for practical purposes
     */
    uint public xIntersect;

    /**
     * @notice The y-value (rate in our case) which is the y-intersect when the x-value (epoch in our case) is 0 - Rate of the first Epoch (epoch number 0) for practical purposes
     */
    uint public yIntersect;

    /**
     * @notice The time in seconds that represent one Epoch
     */
    uint public epochSeconds;

    /**
     * @notice The timestamp where epoch 0 starts
     */
    uint public initTimestamp;

    /**
     * @notice Constructor
     * @param amountOfTokens_ Amount of Tokens - Total amount of tokens to be distributed by the model
     * @param totalOfEpochs_ Number of Epochs - Number of epochs in which the entire amount of tokens will be distributed
     * @param epochSeconds_ Number of seconds - The time in seconds that represent one Epoch
     * @param initTimestamp_ Number of timestamp- The timestamp of the block where epoch 0 starts
     * @param timelockAddress_ Timelock address
     */
    constructor(
        uint amountOfTokens_,
        uint totalOfEpochs_,
        uint epochSeconds_,
        uint initTimestamp_,
        address timelockAddress_
    ) {
        require(initTimestamp_ > block.timestamp, "initTimestamp must be greater than current timestamp");
        timelockAddress = timelockAddress_;

        amountOfTokens = amountOfTokens_;
        epochSeconds = epochSeconds_;
        initTimestamp = initTimestamp_;

        // Y-intersection calculation
        yIntersect = (2 * amountOfTokens_) / (totalOfEpochs_ + 1);

        // X-intersection calculation
        xIntersect = totalOfEpochs_;

        emit SetNewParameters(amountOfTokens_, totalOfEpochs_, epochSeconds_, initTimestamp_);
    }

    modifier onlyTimelock() {
        require(msg.sender == timelockAddress, "Only timelock contract can call this function");
        _;
    }

    /**
     * @notice Set New Parameters Function - only the admin can call this function
     * @param amountOfTokens_ Amount of Tokens - Total amount of tokens to be distributed by the model
     * @param totalOfEpochs_ Number of Epochs - Number of epochs in which the entire amount of tokens will be distributed
     * @param epochSeconds_ Number of seconds - The time in seconds that represent one Epoch
     * @param initTimestamp_ Number of timestamp- The timestamp of the block where epoch 0 starts
     */
    function _setNewParameters(
        uint amountOfTokens_,
        uint totalOfEpochs_,
        uint epochSeconds_,
        uint initTimestamp_
    ) external onlyTimelock {
        require(initTimestamp_ > block.timestamp, "initTimestamp must be greater than current timestamp");

        amountOfTokens = amountOfTokens_;
        epochSeconds = epochSeconds_;
        initTimestamp = initTimestamp_;

        // Y-intersection calculation
        yIntersect = (2 * amountOfTokens_) / (totalOfEpochs_ + 1);

        // X-intersection calculation
        xIntersect = totalOfEpochs_;

        emit SetNewParameters(amountOfTokens_, totalOfEpochs_, epochSeconds_, initTimestamp_);
    }

    /**
     * @notice Set new timelock address
     * @param newTimelockAddress The new timelock address
     */
    function _setNewTimelock(address newTimelockAddress) external onlyTimelock {
        require(newTimelockAddress != address(0), "The new timelock address cannot be address 0");
        timelockAddress = newTimelockAddress;

        emit SetNewTimelockAddress(newTimelockAddress);
    }

    /**
     * @notice Calculates the Rate in the Epoch that was passed as a parameter
     *          `rate = yIntersect - ( slope * epochNumberParam )`
     * @param epochNumber The epochNumber (remember: the first epoch is 0)
     * @return The return Rate by epoch in the target epoch
     */
    function getRatePerEpoch(uint epochNumber) public view returns (uint) {
        uint xIntersect_ = xIntersect;

        if (epochNumber > xIntersect_) {
            return 0;
        }

        uint yIntersect_ = yIntersect;
        // Slope calculation
        uint slope = yIntersect_ / xIntersect_;
        return (yIntersect_ - (epochNumber * slope)) / epochSeconds;
    }

    /**
     * @notice Calculates the Actual Rate per second (relative to initTimestamp and the actualBlock)
     * @return The actual Rate per second
     */
    function getActualRate() external view returns (uint) {
        if (initTimestamp > block.timestamp) {
            return 0;
        }

        return getRatePerEpoch(getActualEpoch());
    }

    /**
     * @notice Get the actual epoch (relative to initTimestamp and ActualBlock)
     * @return The Actual epoch number
     */
    function getActualEpoch() public view returns (uint) {
        uint initTimestamp_ = initTimestamp;
        require(
            initTimestamp_ <= block.timestamp,
            "Actual timestamp is lower than initTimestamp, wait till the epoch 0 starts."
        );
        return (block.timestamp - initTimestamp_) / epochSeconds;
    }

    /**
     * @notice Get the next epoch Block (relative to initTimestamp and ActualBlock)
     * @return The next epoch Block
     */
    function getNextEpochTimestamp() public view returns (uint) {
        uint initTimestamp_ = initTimestamp;
        if (block.timestamp < initTimestamp_) {
            return initTimestamp_;
        }
        return initTimestamp_ + ((getActualEpoch() + 1) * epochSeconds);
    }

    /**
     * @notice Get the timestamp where the epoch init (relative to initTimestamp)
     * @return The timestamp where the epoch init
     */
    function getInitEpochTimestamp(uint epochNumber) external view returns (uint) {
        require(epochNumber <= xIntersect, "The epoch number must be minor or equal to the total of epochs (xIntersect)");
        return initTimestamp + (epochNumber * epochSeconds);
    }

    /**
     * @notice Get the epoch and rate from the block timestamp passed as parameter (relative to initTimestamp)
     * @return The epoch and rate number
     */
    function getEpochAndRate(uint timestamp) public view returns (uint, uint) {
        uint initTimestamp_ = initTimestamp;
        require(timestamp >= initTimestamp_, "The timestamp must be greater than the init timestamp");
        uint epoch = (timestamp - initTimestamp_) / epochSeconds;
        return (epoch, getRatePerEpoch(epoch));
    }

    /**
     * @notice This function helps the Comptroller to know if there was an Epoch Jump/Overlapping 
     *          (this scenario occurs if no operation was done in Comptroller during an entire epoch)
     * @return Epoch Overlapping boolean
     */
    function isEpochOverlapping(uint epochTimestamp) public view returns (bool) {
        require(epochTimestamp <= block.timestamp, "The epochTimestamp must be lower or equal than the actual timestamp");
        if (epochTimestamp + epochSeconds < getNextEpochTimestamp()) {
            return true;
        }
        return false;
    }

    /**
     * @notice Return the Epoch Overlapping Rates array when there was an Epoch Jump/Overlapping 
     *          (this scenario occurs if no operation was done in Comptroller during an entire epoch)
     * @return Epoch Overlapping Rates array
     */
    function epochOverlappingRates(uint epochTimestamp) external view returns (uint[] memory) {
        require(isEpochOverlapping(epochTimestamp), "There is not Epoch Overlapping");

        (uint initEpoch,) = getEpochAndRate(epochTimestamp);
        uint arrayCount = getActualEpoch() - initEpoch;
        uint[] memory rateArray = new uint[](arrayCount);

        for (uint i = 0; i < arrayCount; i++) {
            rateArray[i] = getRatePerEpoch(initEpoch + i);
        }
        return rateArray;
    }
}