// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library FeeSchedule {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.FeeSchedule.Data"));

    struct DataGlobal {
        /// Last used feeSchedule id from prior add invocation.
        uint32 feeScheduleIdCounter;
    }

    struct Data {
        /// Whether the schedule has been previously registered.
        bool isRegistered;
        /// Percentage fee charged to the maker side, in D9 precision.
        uint32 makerFee;
        /// Percentage fee charged to the taker side, in D9 precision.
        uint32 takerFee;
    }

    function load() internal pure returns (FeeSchedule.DataGlobal storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }

    function load(uint32 feeScheduleId) internal pure returns (FeeSchedule.Data storage $) {
        bytes32 s = keccak256(abi.encode(_SLOT_PATH, feeScheduleId));
        assembly {
            $.slot := s
        }
    }

    /// @dev Returns the next feeSchedule then updates id counter.
    function getAndIncrementNextFeeScheduleId(FeeSchedule.DataGlobal storage self) internal returns (uint32) {
        uint32 nextId = self.feeScheduleIdCounter + 1;
        self.feeScheduleIdCounter = nextId;
        return nextId;
    }
}
