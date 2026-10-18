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

