// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {RISExStrategy} from "src/extensions/RISExStrategy.sol";

import {IRISExAdapter} from "risex-adapter/interfaces/IRISExAdapter.sol";
import {IRISExMarketMakingStrategy} from "src/interfaces/IRISExMarketMakingStrategy.sol";

/// @title RISExMarketMakingStrategy
/// @author RiseX Team
/// @notice Yearn V3 TokenizedStrategy for RISEx perpetual trading
/// @dev Deposits USDC as collateral to RISEx via an adapter and tracks account equity
///      including unrealized PnL from open positions.
contract RISExMarketMakingStrategy is
    RISExStrategy,
    IRISExMarketMakingStrategy
{
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint16 public constant DEFAULT_BUFFER_BPS = 5_000;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maximum total assets allowed (0 = unlimited, 6 decimals)
    uint128 private s_depositCap;

    /// @dev Withdrawal buffer in basis points
    uint16 private s_withdrawalBufferBps;

    /// @dev Position limit threshold in basis points
    uint16 private s_positionLimitBps;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address asset_,
        string memory name_,
        address adapter_
    ) RISExStrategy(asset_, name_, adapter_) {
        s_withdrawalBufferBps = DEFAULT_BUFFER_BPS;
        s_positionLimitBps = DEFAULT_BUFFER_BPS;
    }

    /*//////////////////////////////////////////////////////////////
                    REQUIRED STRATEGY OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Free funds from RISEx collateral.
    ///      Reverts during stale-loss windows to prevent first-exiter advantage.
    function _freeFunds(uint256 amount) internal override {
        (uint256 idle, int256 equity) = _requireNoStaleLoss();

        // Clamp to buffer and epoch limits
        uint256 availableFromBuffer = _applyWithdrawalBuffer(
            getWithdrawableAmount(),
            equity
        );
        uint256 epochLimit = _getEpochWithdrawalLimit(idle);
        uint256 available = availableFromBuffer < epochLimit
            ? availableFromBuffer
            : epochLimit;
        uint256 actualWithdraw = amount > available ? available : amount;

        if (actualWithdraw > 0) {
            _recordWithdrawal(actualWithdraw.toUint128());
            uint256 freed = i_adapter.freeCollateral(
                address(asset),
                actualWithdraw
            );
            if (freed < actualWithdraw) {
                _correctWithdrawalOvercount(
                    (actualWithdraw - freed).toUint128()
                );
            }
            emit WithdrawnFromRISEx(freed);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         OPTIONAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum withdrawable considering buffer and epoch limit
    /// @dev Returns 0 during stale-loss windows (live < recorded) — report() must run first.
    function availableWithdrawLimit(
        address /*owner*/
    ) public view override returns (uint256) {
        (
            uint256 liveAssets,
            uint256 idle,
            int256 equity
        ) = _getLiveTotalAssets();

        if (liveAssets < TokenizedStrategy.totalAssets()) return 0;

        uint256 withdrawable = getWithdrawableAmount();
        uint256 totalAvailable = idle +
            _applyWithdrawalBuffer(withdrawable, equity);
        uint256 epochLimit = _getEpochWithdrawalLimit(idle);

        return totalAvailable < epochLimit ? totalAvailable : epochLimit;
    }

    /// @notice Maximum depositable considering whitelist and cap
    function availableDepositLimit(
        address owner
    ) public view override returns (uint256) {
        if (!whitelistedDepositor(owner)) return 0;
        if (s_depositCap == 0) return type(uint256).max;

        (uint256 totalAssets, , ) = _getLiveTotalAssets();
        if (totalAssets >= s_depositCap) return 0;

        return s_depositCap - totalAssets;
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExMarketMakingStrategy
    function getMarginRatio() public view returns (uint256) {
        int256 equity = getAccountEquity();
        if (equity <= 0) return 0;
        return (getWithdrawableAmount() * BPS_DENOMINATOR) / uint256(equity);
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function hasOpenPositions() public view returns (bool) {
        int256 equity = getAccountEquity();
        if (equity < 0) return true;
        return uint256(equity) != getWithdrawableAmount();
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function getDepositCap() external view returns (uint128) {
        return s_depositCap;
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function getWithdrawalBufferBps() external view returns (uint16) {
        return s_withdrawalBufferBps;
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function getPositionLimitBps() external view returns (uint16) {
        return s_positionLimitBps;
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExMarketMakingStrategy
    function setWithdrawalBufferBps(
        uint16 newBufferBps
    ) external onlyManagement {
        require(newBufferBps <= BPS_DENOMINATOR, InvalidBuffer());
        uint16 oldBuffer = s_withdrawalBufferBps;
        s_withdrawalBufferBps = newBufferBps;
        emit WithdrawalBufferUpdated(oldBuffer, newBufferBps);
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function setPositionLimitBps(uint16 newLimitBps) external onlyManagement {
        require(newLimitBps <= BPS_DENOMINATOR, InvalidBuffer());
        uint16 oldLimit = s_positionLimitBps;
        s_positionLimitBps = newLimitBps;
        emit PositionLimitUpdated(oldLimit, newLimitBps);
    }

    /// @inheritdoc IRISExMarketMakingStrategy
    function setDepositCap(uint128 newCap) external onlyManagement {
        uint128 oldCap = s_depositCap;
        s_depositCap = newCap;
        emit DepositCapUpdated(oldCap, newCap);
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Apply withdrawal buffer based on margin ratio
    function _applyWithdrawalBuffer(
        uint256 withdrawable,
        int256 equity
    ) internal view returns (uint256) {
        if (equity <= 0) return withdrawable;
        if (!hasOpenPositions()) return withdrawable;

        uint256 marginRatio = (withdrawable * BPS_DENOMINATOR) /
            uint256(equity);
        if (marginRatio < s_withdrawalBufferBps) return 0;

        return withdrawable;
    }
}
