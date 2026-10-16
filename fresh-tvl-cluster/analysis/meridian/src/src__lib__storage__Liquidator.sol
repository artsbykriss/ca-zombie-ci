// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library Liquidator {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.Liquidator.Data"));

    struct Data {
        /// Full position liquidated takeovers are transferred in the liquidatorAccount
        address account;
        /// The subaccount identifier for the address holding the liquidated positions
        bytes32 subaccount;
        /// Accumulated balance delta across multiple deleverage actions for the current deleverage sequence.
        int256 deleverageBalanceDelta;
        /// The message index that initiated the current deleverage sequence.
        /// Non-zero while a deleverage sequence is in progress. All subsequent
        /// deleverage actions in the same sequence must share this index.
        uint64 deleverageMessageIdx;
        /// Current quote token being deleveraged.
        address deleverageQuoteToken;
    }

    function load() internal pure returns (Data storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }
}
