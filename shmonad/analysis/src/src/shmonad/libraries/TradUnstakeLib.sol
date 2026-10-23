//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { UserUnstakeRequest, UserUnstakesState } from "../Types.sol";
import {
    TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT,
    TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT,
    TRADITIONAL_UNSTAKE_MATURED_SLOT
} from "../Constants.sol";
import { ShMonadErrors } from "../Errors.sol";

/// @title TradUnstakeLib
/// @notice Storage-manipulation helpers for the bounded traditional unstake request set.
/// @dev This library intentionally operates on the existing v1.2 storage mappings by reference so the queue logic can
/// move out of `ShMonad.sol` without introducing a new storage layout abstraction.
library TradUnstakeLib {
    /// @dev Returns the compatibility summary used by `getUnstakeRequest(address)`.
    /// Legacy integrations expected 1 request, so the summary view preserves that ABI as total amount + max epoch.
    function summary(
        mapping(address => UserUnstakeRequest) storage legacyRequests,
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account
    )
        internal
        view
        returns (uint128 amountMon, uint64 completionEpoch)
    {
        UserUnstakeRequest memory legacyRequest = legacyRequests[account];
        if (legacyRequest.amountMon != 0) {
            amountMon = legacyRequest.amountMon;
            completionEpoch = legacyRequest.completionEpoch;
        }

        UserUnstakesState storage state = statesByAccount[account];
        uint8 occupiedBitmap = state.occupiedBitmap;
        for (uint8 slot; slot < TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT; ++slot) {
            if (!_isSlotOccupied(occupiedBitmap, slot)) continue;

            UserUnstakeRequest memory request = state.requests[slot];
            amountMon += request.amountMon;
            if (request.completionEpoch > completionEpoch) completionEpoch = request.completionEpoch;
        }
    }

    /// @dev Returns every active request as a compact array sorted by ascending completion epoch.
    /// The legacy request is included until the next stateful touch migrates it into the fixed-slot set.
    function activeRequests(
        mapping(address => UserUnstakeRequest) storage legacyRequests,
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account
    )
        internal
        view
        returns (UserUnstakeRequest[] memory requests)
    {
        UserUnstakesState storage state = statesByAccount[account];
        UserUnstakeRequest memory legacyRequest = legacyRequests[account];
        uint8 occupiedBitmap = state.occupiedBitmap;
        uint256 requestCount = _activeRequestCount(occupiedBitmap);
        if (legacyRequest.amountMon != 0) ++requestCount;

        requests = new UserUnstakeRequest[](requestCount);
        uint256 writeIndex;

        if (legacyRequest.amountMon != 0) {
            requests[writeIndex++] = legacyRequest;
        }

        for (uint8 slot; slot < TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT; ++slot) {
            if (!_isSlotOccupied(occupiedBitmap, slot)) continue;
            requests[writeIndex++] = state.requests[slot];
        }

        for (uint256 i = 1; i < requestCount; ++i) {
            UserUnstakeRequest memory candidate = requests[i];
            uint256 j = i;
            while (j > 0 && requests[j - 1].completionEpoch > candidate.completionEpoch) {
                requests[j] = requests[j - 1];
                unchecked {
                    --j;
                }
            }
            requests[j] = candidate;
        }
    }

    /// @dev Compacts already-matured requests and lazily migrates the legacy single-slot request before any
    /// state-changing traditional-unstake operation touches the v1.2 request set.
    /// Compaction runs first so matured legacy state can merge into the same dedicated matured slot.
    function prepare(
        mapping(address => UserUnstakeRequest) storage legacyRequests,
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account,
        uint64 currentInternalEpoch
    )
        internal
        returns (uint64 oldestPendingCompletionEpoch)
    {
        oldestPendingCompletionEpoch = _compactMaturedRequests(statesByAccount, account, currentInternalEpoch);
        uint64 legacyPendingCompletionEpoch =
            _migrateLegacyRequest(legacyRequests, statesByAccount, account, currentInternalEpoch);
        if (legacyPendingCompletionEpoch < oldestPendingCompletionEpoch) {
            oldestPendingCompletionEpoch = legacyPendingCompletionEpoch;
        }
    }

    /// @dev Inserts a pending traditional-unstake request into the bounded request set.
    /// Matching completion epochs merge so repeated requests in the same quoted epoch keep the legacy behavior.
    function enqueuePendingRequest(
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account,
        uint128 amountMon,
        uint64 completionEpoch
    )
        internal
    {
        UserUnstakesState storage state = statesByAccount[account];
        uint8 occupiedBitmap = state.occupiedBitmap;
        uint8 firstFreeSlot = TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT;

        for (uint8 slot; slot < TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT; ++slot) {
            if (!_isSlotOccupied(occupiedBitmap, slot)) {
                if (firstFreeSlot == TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT) firstFreeSlot = slot;
                continue;
            }

            if (state.requests[slot].completionEpoch != completionEpoch) continue;

            state.requests[slot].amountMon += amountMon;
            return;
        }

        // Defensive guard for an expected-unreachable state. Normal request history can only fill the seven future
        // pending epochs `current + 1` through `current + 7`, so a fresh `current + 5` or `current + 7` quote should
        // merge above when the pending set is full.
        if (firstFreeSlot >= TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT) {
            // Avoid counting active requests on the normal successful enqueue path.
            uint256 activeRequestCount = _activeRequestCount(occupiedBitmap);
            require(
                firstFreeSlot < TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT,
                ShMonadErrors.NoUnstakeRequestSlotsAvailable(account, activeRequestCount)
            );
        }

        state.requests[firstFreeSlot] = UserUnstakeRequest({ amountMon: amountMon, completionEpoch: completionEpoch });
        state.occupiedBitmap = _setSlotBit(occupiedBitmap, firstFreeSlot);
    }

    /// @dev Drains the prepared matured slot for `account`, leaving later requests untouched.
    /// `prepare()` must run first so pending-slot maturity has already been normalized into this slot.
    function consumeMaturedRequests(
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account
    )
        internal
        returns (uint128 amountMon)
    {
        UserUnstakesState storage state = statesByAccount[account];
        uint8 occupiedBitmap = state.occupiedBitmap;
        if (!_isSlotOccupied(occupiedBitmap, TRADITIONAL_UNSTAKE_MATURED_SLOT)) return 0;

        amountMon = state.requests[TRADITIONAL_UNSTAKE_MATURED_SLOT].amountMon;
        delete state.requests[TRADITIONAL_UNSTAKE_MATURED_SLOT];
        state.occupiedBitmap = _clearSlotBit(occupiedBitmap, TRADITIONAL_UNSTAKE_MATURED_SLOT);
    }

    function _migrateLegacyRequest(
        mapping(address => UserUnstakeRequest) storage legacyRequests,
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account,
        uint64 currentInternalEpoch
    )
        private
        returns (uint64 pendingCompletionEpoch)
    {
        pendingCompletionEpoch = type(uint64).max;
        UserUnstakeRequest memory legacyRequest = legacyRequests[account];
        if (legacyRequest.amountMon == 0) return pendingCompletionEpoch;

        delete legacyRequests[account];

        // Matured legacy requests become immediately withdrawable via the dedicated matured slot.
        if (legacyRequest.completionEpoch <= currentInternalEpoch) {
            UserUnstakesState storage state = statesByAccount[account];
            state.occupiedBitmap = _mergeIntoMaturedSlot(
                state, state.occupiedBitmap, legacyRequest.amountMon, legacyRequest.completionEpoch
            );
            return pendingCompletionEpoch;
        }

        enqueuePendingRequest(statesByAccount, account, legacyRequest.amountMon, legacyRequest.completionEpoch);
        pendingCompletionEpoch = legacyRequest.completionEpoch;
    }

    function _compactMaturedRequests(
        mapping(address => UserUnstakesState) storage statesByAccount,
        address account,
        uint64 currentInternalEpoch
    )
        private
        returns (uint64 oldestPendingCompletionEpoch)
    {
        UserUnstakesState storage state = statesByAccount[account];
        uint8 occupiedBitmap = state.occupiedBitmap;
        oldestPendingCompletionEpoch = type(uint64).max;

        // Only pending slots are scanned here. The matured slot already represents withdrawable state.
        for (uint8 slot; slot < TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT; ++slot) {
            if (!_isSlotOccupied(occupiedBitmap, slot)) continue;

            UserUnstakeRequest memory request = state.requests[slot];
            if (request.completionEpoch > currentInternalEpoch) {
                if (request.completionEpoch < oldestPendingCompletionEpoch) {
                    oldestPendingCompletionEpoch = request.completionEpoch;
                }
                continue;
            }

            occupiedBitmap = _mergeIntoMaturedSlot(state, occupiedBitmap, request.amountMon, request.completionEpoch);
            delete state.requests[slot];
            occupiedBitmap = _clearSlotBit(occupiedBitmap, slot);
        }

        state.occupiedBitmap = occupiedBitmap;
    }

    function _mergeIntoMaturedSlot(
        UserUnstakesState storage state,
        uint8 occupiedBitmap,
        uint128 amountMon,
        uint64 completionEpoch
    )
        private
        returns (uint8 updatedOccupiedBitmap)
    {
        // The caller owns bitmap writeback so compaction and migration can batch it into 1 final SSTORE.
        updatedOccupiedBitmap = occupiedBitmap;
        UserUnstakeRequest storage maturedRequest = state.requests[TRADITIONAL_UNSTAKE_MATURED_SLOT];
        // The matured slot keeps the latest merged completion epoch so the compatibility summary still reports max
        // epoch.
        if (_isSlotOccupied(occupiedBitmap, TRADITIONAL_UNSTAKE_MATURED_SLOT)) {
            maturedRequest.amountMon += amountMon;
            if (completionEpoch > maturedRequest.completionEpoch) maturedRequest.completionEpoch = completionEpoch;
        } else {
            maturedRequest.amountMon = amountMon;
            maturedRequest.completionEpoch = completionEpoch;
            updatedOccupiedBitmap = _setSlotBit(occupiedBitmap, TRADITIONAL_UNSTAKE_MATURED_SLOT);
        }
    }

    function _activeRequestCount(uint8 occupiedBitmap) private pure returns (uint256 count) {
        for (uint8 slot; slot < TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT; ++slot) {
            if (_isSlotOccupied(occupiedBitmap, slot)) ++count;
        }
    }

    function _isSlotOccupied(uint8 occupiedBitmap, uint8 slot) private pure returns (bool) {
        return (occupiedBitmap & (uint8(1) << slot)) != 0;
    }

    function _setSlotBit(uint8 occupiedBitmap, uint8 slot) private pure returns (uint8) {
        return occupiedBitmap | (uint8(1) << slot);
    }

    function _clearSlotBit(uint8 occupiedBitmap, uint8 slot) private pure returns (uint8) {
        return occupiedBitmap & ~(uint8(1) << slot);
    }
}
