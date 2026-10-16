// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// @see: https://github.com/pyth-network/pyth-crosschain/blob/main/lazer/contracts/evm/src/PythLazerLib.sol
//
// NOTE: Adjusted to use `bytes memory update` from `bytes calldata update`.
library PythLazerLib {
    enum PriceFeedProperty {
        Price,
        BestBidPrice,
        BestAskPrice,
        PublisherCount,
        Exponent,
        Confidence,
        FundingRate,
        FundingTimestamp,
        FundingRateInterval,
        MarketSession,
        EmaPrice,
        EmaConfidence,
        FeedUpdateTimestamp
    }

    enum Channel {
        Invalid,
        RealTime,
        FixedRate50,
        FixedRate200
    }

    function parsePayloadHeader(bytes memory update)
        internal
        pure
        returns (uint64 timestamp, Channel channel, uint8 feedsLen, uint16 pos)
    {
        uint32 FORMAT_MAGIC = 2479346549;

        pos = 0;
        // Manual byte concatenation for uint32/bytes4
        bytes4 magicBytes = bytes4(abi.encodePacked(update[pos], update[pos + 1], update[pos + 2], update[pos + 3]));
        uint32 magic = uint32(magicBytes);
        pos += 4;
        if (magic != FORMAT_MAGIC) {
            revert("invalid magic");
        }

        // Manual byte concatenation for uint64/bytes8
        bytes8 timestampBytes = bytes8(
            abi.encodePacked(
                update[pos],
                update[pos + 1],
                update[pos + 2],
                update[pos + 3],
                update[pos + 4],
                update[pos + 5],
                update[pos + 6],
                update[pos + 7]
            )
        );
        timestamp = uint64(timestampBytes);
        pos += 8;

        channel = Channel(uint8(update[pos]));
        pos += 1;
        feedsLen = uint8(update[pos]);
        pos += 1;
    }

    function parseFeedHeader(bytes memory update, uint16 pos)
        internal
        pure
        returns (uint32 feed_id, uint8 num_properties, uint16 new_pos)
    {
        // Manual byte concatenation for uint32/bytes4
        bytes4 feedIdBytes = bytes4(abi.encodePacked(update[pos], update[pos + 1], update[pos + 2], update[pos + 3]));
        feed_id = uint32(feedIdBytes);
        pos += 4;
        num_properties = uint8(update[pos]);
        pos += 1;
        new_pos = pos;
    }

    function parseFeedProperty(bytes memory update, uint16 pos)
        internal
        pure
        returns (PriceFeedProperty property, uint16 new_pos)
    {
        property = PriceFeedProperty(uint8(update[pos]));
        pos += 1;
        new_pos = pos;
    }

    function parseFeedValueUint64(bytes memory update, uint16 pos)
        internal
        pure
        returns (uint64 value, uint16 new_pos)
    {
        // Manual byte concatenation for uint64/bytes8
        bytes8 valueBytes = bytes8(
            abi.encodePacked(
                update[pos],
                update[pos + 1],
                update[pos + 2],
                update[pos + 3],
                update[pos + 4],
                update[pos + 5],
                update[pos + 6],
                update[pos + 7]
            )
        );
        value = uint64(valueBytes);
        pos += 8;
        new_pos = pos;
    }

    function parseFeedValueInt64(bytes memory update, uint16 pos) internal pure returns (int64 value, uint16 new_pos) {
        // Manual byte concatenation for int64/bytes8
        bytes8 valueBytes = bytes8(
            abi.encodePacked(
                update[pos],
                update[pos + 1],
                update[pos + 2],
                update[pos + 3],
                update[pos + 4],
                update[pos + 5],
                update[pos + 6],
                update[pos + 7]
            )
        );
        value = int64(uint64(valueBytes));
        pos += 8;
        new_pos = pos;
    }

    function parseFeedValueUint16(bytes memory update, uint16 pos)
        internal
        pure
        returns (uint16 value, uint16 new_pos)
    {
        // Manual byte concatenation for uint16/bytes2
        bytes2 valueBytes = bytes2(abi.encodePacked(update[pos], update[pos + 1]));
        value = uint16(valueBytes);
        pos += 2;
        new_pos = pos;
    }

    function parseFeedValueInt16(bytes memory update, uint16 pos) internal pure returns (int16 value, uint16 new_pos) {
        // Manual byte concatenation for int16/bytes2
        bytes2 valueBytes = bytes2(abi.encodePacked(update[pos], update[pos + 1]));
        value = int16(uint16(valueBytes));
        pos += 2;
        new_pos = pos;
    }

    function parseFeedValueUint8(bytes memory update, uint16 pos) internal pure returns (uint8 value, uint16 new_pos) {
        value = uint8(update[pos]);
        pos += 1;
        new_pos = pos;
    }
}
