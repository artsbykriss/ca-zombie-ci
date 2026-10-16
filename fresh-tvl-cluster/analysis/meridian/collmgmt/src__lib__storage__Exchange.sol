// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ActionType} from "../../share/Enums.sol";
import {ActionExpired, NotSequencer, SequencerPaused} from "../../share/Errors.sol";
import {ActionId} from "../../share/UserDefinedTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library Exchange {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.Exchange.Data"));

    struct Data {
        /// Mapping of approved sequencers.
        mapping(address sequencer => bool approved) isSequencerApproved;
        /// Mapping of sequencers and their paused/unpaused status.
        mapping(address sequencer => bool paused) isSequencerPaused;
        /// Set of token names (virtual and concrete).
        EnumerableSet.Bytes32Set tokens;
        /// Mapping of token names by their concrete address.
        mapping(address token => bytes32 name) tokensByAddress;
        /// Time in seconds after the message signed at time, where the action is valid.
        mapping(ActionType action => uint64 buffer) actionExpiryBuffers;
        // Mapping of whether an address is approved to act as a delegate depositor.
        mapping(address delegateDepositor => bool approved) isDelegateDepositor;
        /// Whitelist of addresses that can control the pause state.
        mapping(address sender => bool hasPausePermission) isEmergencyPauser;
        /// Mapping of whether an address has been granted the claimer role.
        mapping(address claimer => bool approved) isClaimer;
        /// Address of the PythLazer contract for price verification.
        address pythLazer;
        /// Max Pyth price age tolerance (delta in seconds from `price.timestamp`).
        uint64 pythMaxAge;
        /// Last processed action identifier.
        ActionId lastActionId;
        /// The maximum number of deposits a delegate depositor may make in a batch.
        uint16 delegateDepositMaxBatchSize;
        /// Whether the exchange is currently paused.
        bool isPaused;
        /// Host chain LayerZero endpoint ID.
        uint32 lzEndpointId;
        /// Delay before a withdrawal can be rescued in seconds.
        uint64 rescueDelay;
        /// Last emitted ping timestamp.
        uint64 lastPingTimestamp;
    }

    function load() internal pure returns (Data storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }

    /// @dev Returns true if `account` is sequencer and not paused.
    function isSequencer(Data storage self, address account) internal view returns (bool) {
        return self.isSequencerApproved[account] && !self.isSequencerPaused[account];
    }

    /// @dev Reverts if the `account` is not in the list of allowed sequencers, or if the sequencer is paused.
    function onlySequencer(Data storage self, address account) internal view {
        if (!self.isSequencerApproved[account]) {
            revert NotSequencer(account);
        }
        if (self.isSequencerPaused[account]) {
            revert SequencerPaused(account);
        }
    }

    /// @dev Reverts if the action is no longer valid for execution.
    function verifyBeforeActionExpiry(Data storage self, ActionId id, ActionType action, uint64 signedAt)
        internal
        view
    {
        if (block.timestamp > signedAt + self.actionExpiryBuffers[action]) {
            revert ActionExpired(id, block.timestamp, signedAt, self.actionExpiryBuffers[action]);
        }
    }
}
