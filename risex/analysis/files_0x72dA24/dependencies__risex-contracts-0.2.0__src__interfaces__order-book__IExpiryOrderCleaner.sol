// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

interface IExpiryOrderCleaner {
    /// @notice Thrown when epoch config is missing or disabled
    error EpochConfigNotInitialized();

    /// @notice Emitted when the orderbook checksum is computed
    event OrderbookChecksum(address indexed protocol, uint16 indexed marketId, bytes32 checksum);

    /// @notice Emitted when global epoch config is initialized
    event EpochConfigInitialized(uint32 genesisTimestamp, uint32 epochDuration, uint16 maxBucketSize);

    /// @notice Cleans expired orders from the order book by epochs (access restricted via AccessManager)
    /// @param protocol The protocol address whose orderbook to clean
    /// @param marketId The market ID
    /// @param maxEpochs Maximum number of epochs to finalize
    /// @return epochsCleaned Number of epochs fully cleaned in this call
    function cleanExpiredEpochs(
        address protocol,
        uint16 marketId,
        uint32 maxEpochs
    ) external returns (uint32 epochsCleaned);

    /// @notice Returns expiry queue info for a market
    /// @param protocol The protocol address whose orderbook to query
    function getExpiryQueueInfo(
        address protocol,
        uint16 marketId
    )
        external
        view
        returns (
            bool initialized,
            uint32 epochDuration,
            uint16 bucketSize,
            uint32 lastCleanedEpoch,
            uint32 currentEpoch
        );

    /// @notice Returns how many epochs are behind and need cleaning
    /// @param protocol The protocol address whose orderbook to query
    function getEpochsBehind(
        address protocol,
        uint16 marketId
    ) external view returns (uint32);

    /// @notice Returns the number of orders in a specific epoch bucket
    /// @param protocol The protocol address whose orderbook to query
    function getOrdersInEpoch(
        address protocol,
        uint16 marketId,
        uint32 epochId
    ) external view returns (uint256);

    /// @notice Returns the epoch interval configuration
    function getEpochInterval() external view returns (uint32 duration, uint32 genesisTimestamp);

    /// @notice Returns the epoch bucket size for order expiry queue
    function getEpochBucketSize() external view returns (uint16);
}
