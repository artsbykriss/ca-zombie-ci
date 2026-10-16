// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {InsufficientShares, InvalidRange, OutOfBounds, NoQueueRequest} from "../../constants/Errors.sol";

import {
    IAccountableWithdrawalQueue,
    WithdrawalRequest,
    WithdrawalQueue
} from "../../interfaces/IAccountableWithdrawalQueue.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title AccountableWithdrawalQueue
/// @notice A contract that manages the withdrawal queue
/// @custom:security-contact security@accountable.capital
abstract contract AccountableWithdrawalQueue is IAccountableWithdrawalQueue {
    using Math for uint256;

    /// @notice Price precision
    uint256 internal _precision;

    /// @notice Withdrawal queue
    WithdrawalQueue internal _queue;

    /// @notice Mapping of controller to request ID
    mapping(address controller => uint128 requestId) internal _requestIds;

    /// @inheritdoc IAccountableWithdrawalQueue
    uint256 public totalQueuedShares;

    /// @inheritdoc IAccountableWithdrawalQueue
    /// @dev The reserved liquidity is the amount of assets that are reserved for withdrawals
    /// @dev Has to be excluded from total liquidity calculations to avoid double counting
    uint256 public reservedLiquidity;

    constructor(uint256 precision_) {
        _precision = precision_;

        _queue.nextRequestId = 1;
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function queue() external view returns (uint128 nextRequestId, uint128 lastRequestId) {
        (nextRequestId, lastRequestId) = (_queue.nextRequestId, _queue.lastRequestId);
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function withdrawalRequest(address controller) external view returns (WithdrawalRequest memory request) {
        request = _queue.requests[_requestIds[controller]];
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function withdrawalRequests(uint128 start, uint128 end)
        external
        view
        returns (WithdrawalRequest[] memory requests)
    {
        if (start == 0 || start > end) revert InvalidRange();
        if (end > _queue.lastRequestId) revert OutOfBounds();

        uint128 len = end - start + 1;
        requests = new WithdrawalRequest[](len);

        for (uint128 i = 0; i < len;) {
            requests[i] = _queue.requests[start + i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Pushes a new withdrawal request to the queue
    function _push(address controller, uint256 shares) internal returns (uint128 requestId) {
        uint128 requestId_ = _requestIds[controller];
        if (requestId_ == 0) {
            requestId = ++_queue.lastRequestId;

            _requestIds[controller] = requestId;
            _queue.requests[requestId] = WithdrawalRequest(shares, controller);
        } else {
            requestId = requestId_;
            _queue.requests[requestId_].shares += shares;
        }

        totalQueuedShares += shares;
    }

    /// @dev Reduces or removes the shares of a withdrawal request
    function _reduce(address controller, uint256 shares) internal returns (uint256 remainingShares) {
        uint128 requestId = _requestIds[controller];
        if (requestId == 0) revert NoQueueRequest();

        uint256 currentShares = _queue.requests[requestId].shares;
        if (shares > currentShares || currentShares == 0) revert InsufficientShares();

        remainingShares = currentShares - shares;
        totalQueuedShares -= shares;

        if (remainingShares == 0) {
            _delete(controller, requestId);
        } else {
            _queue.requests[requestId].shares = remainingShares;
        }
    }

    /// @dev Deletes a withdrawal request and its controller from the queue
    function _delete(address controller, uint128 requestId) private {
        delete _queue.requests[requestId];
        delete _requestIds[controller];
    }

    /// @dev Processes up to the given number of shares
    function _processUpToShares(uint256 maxShares, uint256 liquidity, uint256 currentPrice)
        internal
        returns (uint256 assetsUsed)
    {
        if (maxShares == 0 || totalQueuedShares == 0) return 0;

        uint256 precision_ = _precision;
        uint128 nextRequestId = _queue.nextRequestId;
        uint128 lastRequestId = _queue.lastRequestId;

        while (maxShares > 0 && nextRequestId <= lastRequestId) {
            WithdrawalRequest memory request_ = _queue.requests[nextRequestId];

            (uint256 shares_, uint256 assets_, bool processed_) =
                _processRequest(request_, liquidity, maxShares, currentPrice, precision_);

            if (shares_ == 0) {
                if (processed_) {
                    ++nextRequestId;
                    continue;
                }
                break;
            }

            _fulfillRedeemRequest(nextRequestId, request_.controller, shares_, currentPrice);

            assetsUsed += assets_;
            liquidity -= assets_;
            maxShares -= shares_;

            if (!processed_) break;

            ++nextRequestId;
        }

        _queue.nextRequestId = nextRequestId;
    }

    /// @dev Processes requests up to the given request ID
    function _processUpToRequestId(uint256 maxRequestId, uint256 liquidity, uint256 currentPrice)
        internal
        returns (uint256 processedShares, uint256 assetsUsed)
    {
        uint256 maxShares_ = totalQueuedShares;
        if (maxRequestId == 0 || maxShares_ == 0) return (0, 0);

        uint256 precision_ = _precision;
        uint128 nextRequestId = _queue.nextRequestId;
        uint128 lastRequestId = _queue.lastRequestId;

        uint256 cappedMaxRequestId = maxRequestId > lastRequestId ? lastRequestId : maxRequestId;

        while (nextRequestId <= cappedMaxRequestId) {
            WithdrawalRequest memory request_ = _queue.requests[nextRequestId];
            (uint256 shares_, uint256 assets_, bool processed_) =
                _processRequest(request_, liquidity, maxShares_, currentPrice, precision_);

            if (shares_ == 0) {
                if (processed_) {
                    ++nextRequestId;
                    continue;
                }
                break;
            }

            _fulfillRedeemRequest(nextRequestId, request_.controller, shares_, currentPrice);

            processedShares += shares_;
            assetsUsed += assets_;
            liquidity -= assets_;

            if (!processed_) break;

            ++nextRequestId;
        }

        _queue.nextRequestId = nextRequestId;
    }

    /// @dev Processes a withdrawal request updating all relevant state
    function _processRequest(
        WithdrawalRequest memory request,
        uint256 liquidity,
        uint256 maxShares,
        uint256 currentPrice,
        uint256 precision
    ) internal returns (uint256 processedShares, uint256 assetsUsed, bool processed) {
        if (request.controller == address(0)) return (0, 0, true);

        uint256 liquidShares = liquidity.mulDiv(precision, currentPrice);
        uint256 sharesToProcess = _min3(request.shares, liquidShares, maxShares);

        if (sharesToProcess == 0) return (0, 0, false);

        processedShares = sharesToProcess;
        assetsUsed = sharesToProcess.mulDiv(currentPrice, precision);

        processed = (sharesToProcess == request.shares);

        _reduce(request.controller, processedShares);
    }

    /// @dev Returns the number of shares that can be processed with the given assets
    function _previewRequiredShares(uint256 maxAssets, uint256 currentPrice)
        internal
        view
        returns (uint256 processedShares, uint256 assetsUsed)
    {
        uint256 precision_ = _precision;
        uint128 nextRequestId = _queue.nextRequestId;
        uint128 lastRequestId = _queue.lastRequestId;

        uint256 remainingShares = totalQueuedShares;

        while (maxAssets > 0 && remainingShares > 0 && nextRequestId <= lastRequestId) {
            WithdrawalRequest memory request_ = _queue.requests[nextRequestId];
            uint256 requestAssets = request_.shares.mulDiv(currentPrice, precision_);

            if (requestAssets > maxAssets) {
                uint256 maxAvailable = Math.min(maxAssets, requestAssets);
                uint256 maxShares = maxAvailable.mulDiv(precision_, currentPrice);

                if (maxShares > 0) {
                    processedShares += maxShares;
                    assetsUsed += maxShares.mulDiv(currentPrice, precision_);
                }
                break;
            }

            processedShares += request_.shares;
            remainingShares -= request_.shares;

            assetsUsed += requestAssets;
            maxAssets -= requestAssets;

            ++nextRequestId;
        }
    }

    /// @dev Returns the maximum request ID that can be processed with the given assets
    function _previewMaxRequestId(uint256 maxAssets, uint256 currentPrice)
        internal
        view
        returns (uint256 maxRequestId, uint256 assetsUsed)
    {
        uint256 precision_ = _precision;
        uint128 nextRequestId_ = _queue.nextRequestId;
        uint128 lastRequestId_ = _queue.lastRequestId;

        uint256 remainingShares = totalQueuedShares;

        while (maxAssets > 0 && remainingShares > 0 && nextRequestId_ <= lastRequestId_) {
            WithdrawalRequest memory request_ = _queue.requests[nextRequestId_];
            uint256 requestAssets = request_.shares.mulDiv(currentPrice, precision_);

            if (requestAssets > maxAssets) {
                uint256 maxAvailable = Math.min(maxAssets, requestAssets);
                uint256 maxShares = maxAvailable.mulDiv(precision_, currentPrice);

                if (maxShares > 0) {
                    maxRequestId = nextRequestId_;
                    assetsUsed += maxShares.mulDiv(currentPrice, precision_);
                }
                break;
            }

            assetsUsed += requestAssets;
            maxAssets -= requestAssets;

            remainingShares -= request_.shares;

            maxRequestId = nextRequestId_++;
        }
    }

    /// @dev Updates the reserved liquidity, to be triggered on withdraw/redeem
    function _updateReservedLiquidity(uint256 assets) internal {
        reservedLiquidity = assets < reservedLiquidity ? reservedLiquidity - assets : 0;
    }

    /// @dev Returns the minimum of three values
    function _min3(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 result) {
        assembly {
            result := a
            if lt(b, result) { result := b }
            if lt(c, result) { result := c }
        }
    }

    /// @dev Hook function to trigger state updates when a request is processed
    function _fulfillRedeemRequest(uint128 requestId, address controller, uint256 shares, uint256 price)
        internal
        virtual;
}
