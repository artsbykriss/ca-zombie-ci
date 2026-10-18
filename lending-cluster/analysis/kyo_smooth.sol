// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {TokenStreamConsumer} from "contracts/reward/TokenStreamConsumer.sol";
import "openzeppelin-v5/utils/math/Math.sol";
import "solmate/utils/SignedWadMath.sol";

abstract contract SmoothTokenStreamConsumer is TokenStreamConsumer {
    event CurveUpdate(address, uint128, uint128, uint256);
    event DecayRate(int256);

    error InvalidDecayRate(int256);

    mapping(address => uint256) private lastUpdateTime;
    mapping(address => uint128) private lastPendingInputs;
    mapping(address => uint128) private lastLockedAmounts;

    int256 public immutable decayRate;
    int256 private immutable logDecayRate;

    function() view returns (address[] memory)
        private immutable _sourceInputTokens;
    function(address) view returns (uint128)
        private immutable _sourcePendingInputAmount;
    function(address) returns (uint128)
        private immutable _sourcePendingInputAmountWithUpdate;
    function(address, address, uint128) returns (uint128)
        private immutable _sourceTakeInput;

    constructor(
        int256 decayRate_,
        function() view returns (address[] memory) __sourceInputTokens,
        function(address) view returns (uint128) __sourcePendingInputAmount,
        function(address)
            returns (uint128) __sourcePendingInputAmountWithUpdate,
        function(address, address, uint128) returns (uint128) __sourceTakeInput
    ) {
        require(decayRate_ > 0 && decayRate_ < 1e18, InvalidDecayRate(decayRate_));
        decayRate = decayRate_;
        logDecayRate = wadLn(decayRate);
        _sourcePendingInputAmount = __sourcePendingInputAmount;
        _sourcePendingInputAmountWithUpdate = __sourcePendingInputAmountWithUpdate;
        _sourceInputTokens = __sourceInputTokens;
        _sourceTakeInput = __sourceTakeInput;
        emit DecayRate(decayRate);
        address[] memory tokens = _inputTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            lastUpdateTime[tokens[i]] = block.timestamp;
            emit CurveUpdate(tokens[i], 0, 0, block.timestamp);
        }
    }

    function _inputTokens() internal view virtual override returns (address[] memory) {
        return _sourceInputTokens();
    }

    function _pendingInputAmountUncached(address token) internal view virtual override returns (uint128) {
        (, uint128 amount,) = _computeCurve(token, _sourcePendingInputAmount(token));
        return amount;
    }

    function _computeCurve(address token, uint128 sourcePendingInput) internal view returns (uint128 lockedAmount, uint128 pendingAmount, uint128 currentPendingInput) {
        uint256 lut = lastUpdateTime[token];
        int256 timeElapsed = lut == 0 ? int256(0) : int256(block.timestamp - lut);
        int256 r = wadExp(logDecayRate * timeElapsed);
        currentPendingInput = sourcePendingInput;
        uint128 lastPendingInput = lastPendingInputs[token];

        lockedAmount = uint128(uint256(lastLockedAmounts[token]) * uint256(r)) / 1e18;

        if (currentPendingInput > lastPendingInput) {
            lockedAmount += (currentPendingInput - lastPendingInput);
            if (timeElapsed > 0) {
                int256 r2 = ((r - 1e18) * 1e18) / (logDecayRate * timeElapsed);
                lockedAmount -= uint128((uint256(currentPendingInput - lastPendingInput) * uint256(1e18 - r2)) / 1e18);
            }
        }

        if (lockedAmount <= currentPendingInput) pendingAmount = currentPendingInput - lockedAmount;
    }

    function _pendingInputAmountWithUpdateUncached(address token) internal virtual override returns (uint128) {
        (, uint128 pendingAmount,) = _updateCurve(token);
        return pendingAmount;
    }

    function _updateCurve(address token) internal returns (uint128 lockedAmount, uint128 pendingAmount, uint128 currentPendingInput) {
        (lockedAmount, pendingAmount, currentPendingInput) = _computeCurve(token, _sourcePendingInputAmountWithUpdate(token));
        lastLockedAmounts[token] = lockedAmount;
        lastPendingInputs[token] = currentPendingInput;
        lastUpdateTime[token] = block.timestamp;
        emit CurveUpdate(token, lockedAmount, currentPendingInput, block.timestamp);
    }

    function _takeInputRaw(address token, address recipient, uint128 amountMax) internal virtual override returns (uint128) {
        uint128 amount = _sourceTakeInput(token, recipient, amountMax);
        lastPendingInputs[token] -= amount;
        return amount;
    }

    function _tokenInputPerSecondX128(address token) internal view override returns (uint256 rate) {
        uint256 lut = lastUpdateTime[token];
        int256 timeElapsed = lut == 0 ? int256(0) : int256(block.timestamp - lut);
        int256 r = wadExp(logDecayRate * timeElapsed);
        uint128 currentPendingInput = _sourcePendingInputAmount(token);
        uint128 lastPendingInput = lastPendingInputs[token];

        rate += Math.mulDiv(uint256(r * -logDecayRate), uint256(lastPendingInput) << 128, 1e36);

        if (currentPendingInput > lastPendingInput) {
            uint128 newPendingInputs = currentPendingInput - lastPendingInput;
            if (timeElapsed <= 0) {
                rate += Math.mulDiv(newPendingInputs, uint256(-logDecayRate) << 128, 2e18);
            } else {
                uint256 numerator = uint256(r * (logDecayRate * timeElapsed - 1e18) + 1e36);
                uint256 denominator = uint256(timeElapsed * timeElapsed * -logDecayRate) * 1e18;
                rate += Math.mulDiv(newPendingInputs * numerator, 1 << 128, denominator);
            }
        }
    }
}

