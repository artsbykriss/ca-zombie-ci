// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IPerpEngine} from "../../interface/IPerpEngine.sol";
import {ProductStatus} from "../../share/Enums.sol";
import {PerpPosition} from "./PerpPosition.sol";

library PerpProduct {
    struct Data {
        /// Mapping of account/subaccount to position
        mapping(address account => mapping(bytes32 subaccount => PerpPosition.Data)) positions;
        /// Mapping of digest to filled order quantity
        mapping(bytes32 digest => uint128 amount) filled;
        /// Generated unique identifier
        uint32 id;
        /// The fee schedule for the maker and taker fees
        uint32 feeScheduleId;
        /// Trading restriction status of the product
        ProductStatus status;
        /// Maximum allowed leverage, only whole numbers
        uint16 maxLeverage;
        /// Pyth price feedId.
        uint32 pythFeedId;
        /// Total funding accumulated (USD terms) per unit of size (native)
        int128 cumulativeFundingUsd;
        /// Bytes32 name of the base token name (e.g. ETH in ETHUSD)
        bytes32 baseTokenName;
        /// Bytes32 name of the quote token name (e.g. USD in ETHUSD)
        bytes32 quoteTokenName;
        /// Maximum quantity size per order (multiple of lotSize)
        uint128 maxQuantity;
        /// Smallest quantity size per order (set once on registration)
        uint128 lotSize;
        /// Minimum product tick size (e.g. 0.01)
        uint128 tickSize;
        /// Total product OI in native units (e.g. 5 short, 5 long then 5 OI)
        uint128 openInterest;
        /// Maximum open interest allowed for the product (quote units, D9)
        uint128 maxOpenInterestUsd;
        /// Maximum position notional value allowed per product (quote units, D9)
        uint128 maxPositionNotionalUsd;
        /// Pyth-verified settlement price (gwei, 1e9) recorded at delist finalization
        uint128 delistExpiryPrice;
        /// True once delisting has been initiated (before terminal DELISTED status)
        bool delistInvoked;
        /// Engine expiry message index every force-settlement and the finalize for this delist must share
        uint64 delistMessageIdx;
        /// Total position fee accumulated (USD terms) per unit of size (native)
        uint128 cumulativePositionFeeUsd;
    }

    /// @dev Info is the Data that can be stored in memory
    struct Info {
        uint32 id;
        uint32 feeScheduleId;
        ProductStatus status;
        uint16 maxLeverage;
        uint32 pythFeedId;
        int128 cumulativeFundingUsd;
        bytes32 baseTokenName;
        bytes32 quoteTokenName;
        uint128 maxQuantity;
        uint128 tickSize;
        uint128 lotSize;
        uint128 openInterest;
        uint128 maxOpenInterestUsd;
        uint128 maxPositionNotionalUsd;
        uint128 delistExpiryPrice;
        bool delistInvoked;
        uint64 delistMessageIdx;
        uint128 cumulativePositionFeeUsd;
    }

    function load(uint32 productId) internal pure returns (PerpProduct.Data storage $) {
        bytes32 s = keccak256(abi.encode("xyz.meridian.PerpProduct.Data", productId));
        assembly {
            $.slot := s
        }
    }

    function loadPendingUpdate(uint32 productId) internal pure returns (IPerpEngine.UpdatePerpProductParams storage $) {
        bytes32 s = keccak256(abi.encode("xyz.meridian.PerpProduct.PendingUpdate", productId));
        assembly {
            $.slot := s
        }
    }
}
