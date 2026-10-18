// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SlotDerivation} from "openzeppelin-v5/utils/SlotDerivation.sol";
import {TransientSlot} from "openzeppelin-v5/utils/TransientSlot.sol";

abstract contract TokenStreamConsumer {
    using TransientSlot for bytes32;
    using TransientSlot for TransientSlot.Uint256Slot;
    using SlotDerivation for bytes32;

    bytes32 private constant pendingInputAmountCacheSlot = 0x9bff43e48456609f6db56d12441696de4ee3adb372cd3bab07a15d4d26c65400; // erc7201 "TokenStreamConsumer.pendingInputAmountCached"

    function readCache(address token) private view returns (bool, uint128) {
        TransientSlot.Uint256Slot slot = pendingInputAmountCacheSlot.deriveMapping(token).asUint256();
        uint256 cached = slot.tload();
        if (cached >> 255 == 1) return (true, uint128(cached));
        return (false, 0);
    }

    function writeCache(address token, uint128 value) private {
        pendingInputAmountCacheSlot.deriveMapping(token).asUint256().tstore(uint256(1 << 255) | value);
    }

    function _inputTokens() internal view virtual returns (address[] memory);

    function _takeInput(address token, address recipient, uint128 amountMax) internal returns (uint128) {
        if (amountMax == 0) return 0;
        uint128 amount = _takeInputRaw(token, recipient, amountMax);

        (bool cached, uint128 cache) = readCache(token);
        if (cached) writeCache(token, cache - amount);
        return amount;
    }

    function _pendingInputAmount(address token) internal view returns (uint128) {
        (bool cached, uint128 cache) = readCache(token);
        if (cached) return cache;

        return _pendingInputAmountUncached(token);
    }

    function _pendingInputAmountWithUpdate(address token) internal returns (uint128) {
        (bool cached, uint128 cache) = readCache(token);
        if (cached) return cache;

        uint128 fetched = _pendingInputAmountWithUpdateUncached(token);
        writeCache(token, fetched);
        return fetched;
    }

    function _takeInputRaw(address token, address recipient, uint128 amountMax) internal virtual returns (uint128);

    function _pendingInputAmountWithUpdateUncached(address token) internal virtual returns (uint128);

    function _pendingInputAmountUncached(address token) internal view virtual returns (uint128);

    function _tokenInputPerSecondX128(address token) internal view virtual returns (uint256);

    function tokenInputPerSecondX128(address token) external view returns (uint256) {
        return _tokenInputPerSecondX128(token);
    }
}

