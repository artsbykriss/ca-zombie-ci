// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITokenStreamEmitter {
    event Collect(address indexed token, address indexed owner, address indexed recipient, uint128 amount);

    function outputTokens() external view returns (address[] memory);

    function collect(address token, address recipient, uint128 maxAmount) external returns (uint128);

    function collectAll(address recipient) external returns (uint128[] memory);

    function collectableAmount(address token, address account) external view returns (uint128);

    function tokenOutputPerSecondX128(address token, address account) external view returns (uint256);

    function collectableAmountWithUpdate(address token, address account) external returns (uint128);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {TokenStreamConsumer} from "contracts/reward/TokenStreamConsumer.sol";
import {TokenStreamEmitter} from "contracts/reward/TokenStreamEmitter.sol";

abstract contract FixedTokenStreamEmitter is TokenStreamConsumer, TokenStreamEmitter {

    address public immutable rewardRecipient;

    constructor(address rewardRecipient_) {
        rewardRecipient = rewardRecipient_;
    }

    function _outputTokens() internal view override returns (address[] memory) {
        return _inputTokens();
    }

    function _pendingOutputAmount(address token, address account) internal view override returns (uint128) {
        if (account != rewardRecipient) return 0;
        return _pendingInputAmount(token);
    }

    function _pendingOutputAmountWithUpdate(address token, address account) internal override returns (uint128) {
        if (account != rewardRecipient) return 0;
        return _pendingInputAmountWithUpdate(token);
    }

    function _sendOutput(address token, address account, address recipient, uint128 maxAmount) internal override returns (uint128) {
        return _takeInput(token, recipient, maxAmount);
    }

    function _tokenOutputPerSecondX128(address token, address account) internal view override returns (uint256) {
        if (account != rewardRecipient) return 0;
        return _tokenInputPerSecondX128(token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ITokenStreamEmitter} from "contracts/reward/interfaces/ITokenStreamEmitter.sol";
import {Context} from "openzeppelin-v5/utils/Context.sol";

import {ReentrancyGuardTransient} from "openzeppelin-v5/utils/ReentrancyGuardTransient.sol";
import {SlotDerivation} from "openzeppelin-v5/utils/SlotDerivation.sol";
import {TransientSlot} from "openzeppelin-v5/utils/TransientSlot.sol";
import {Math} from "openzeppelin-v5/utils/math/Math.sol";

abstract contract TokenStreamEmitter is ITokenStreamEmitter, ReentrancyGuardTransient {
    using TransientSlot for bytes32;
    using TransientSlot for TransientSlot.Uint256Slot;
    using SlotDerivation for bytes32;

    bytes32 private constant pendingOutputAmountCacheSlot = 0x9f1862abe01993f17760c1aaa1badf16579f4eccc1b84d72c709ceed3276aa00; // erc7201 "TokenStreamEmitter.pendingOutputAmountCached"

    function readCache(address token, address account) private view returns (bool, uint128) {
        TransientSlot.Uint256Slot slot = pendingOutputAmountCacheSlot.deriveMapping(token).deriveMapping(account).asUint256();
        uint256 cached = slot.tload();
        if (cached >> 255 == 1) return (true, uint128(cached));
        return (false, 0);
    }

    function writeCache(address token, address account, uint128 value) private {
        TransientSlot.Uint256Slot slot = pendingOutputAmountCacheSlot.deriveMapping(token).deriveMapping(account).asUint256();

        slot.tstore(uint256(1 << 255) | value);
    }

    // @notice amount of tokens that can be claimed by the account.
    // @dev the return value of this function must not decrease except when _sendOutput was called.
    function _pendingOutputAmount(address token, address account) internal view virtual returns (uint128);

    // @notice _pendingOutputAmount but without staticcall constraint.
    // @dev the return value of this function must not decrease except when _sendOutput was called.
    // @dev this is used instead of the static version, whenever possible.
    function _pendingOutputAmountWithUpdate(address token, address account) internal virtual returns (uint128);

    // @notice actually transfer the token
    // @dev the caller ensures that maxAmount <= _pendingOutputAmount
    function _sendOutput(address token, address account, address recipient, uint128 maxAmount) internal virtual returns (uint128 amount);

    // @notice the list of tokens this contract can emit.
    // @dev the return value of this function must not change at any circumstance.
    function _outputTokens() internal view virtual returns (address[] memory);

    function _tokenOutputPerSecondX128(address token, address account) internal view virtual returns (uint256);

    function outputTokens() external view returns (address[] memory) {
        return _outputTokens();
    }

    function collect(address token, address recipient, uint128 maxAmount) external nonReentrant returns (uint128) {
        address account = msg.sender;

        uint128 amount = _sendOutput(token, account, recipient, uint128(Math.min(_collectableAmountWithUpdate(token, account), maxAmount)));

        (bool cached, uint128 cache) = readCache(token, account);
        if (cached) writeCache(token, account, cache - amount);
        emit Collect(token, account, recipient, amount);
        return amount;
    }

    function collectAll(address recipient) external nonReentrant returns (uint128[] memory) {
        address[] memory tokens = _outputTokens();
        uint128[] memory amounts = new uint128[](tokens.length);
        address account = msg.sender;
        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = _sendOutput(tokens[i], account, recipient, _collectableAmountWithUpdate(tokens[i], account));
            (bool cached, uint128 cache) = readCache(tokens[i], account);
            if (cached) writeCache(tokens[i], account, cache - amounts[i]);
            emit Collect(tokens[i], account, recipient, amounts[i]);
        }
        return amounts;
    }

    function collectableAmount(address token, address account) external view returns (uint128) {
        (bool cached, uint128 cache) = readCache(token, account);
        if (cached) return cache;
        return _pendingOutputAmount(token, account);
    }

    function _collectableAmountWithUpdate(address token, address account) internal returns (uint128) {
        (bool cached, uint128 cache) = readCache(token, account);
        if (cached) return cache;
        uint128 fetched = _pendingOutputAmountWithUpdate(token, account);
        writeCache(token, account, fetched);
        return fetched;
    }

    function collectableAmountWithUpdate(address token, address account) external nonReentrant returns (uint128) {
        return _collectableAmountWithUpdate(token, account);
    }

    function tokenOutputPerSecondX128(address token, address account) external view returns (uint256) {
        return _tokenOutputPerSecondX128(token, account);
    }
}

