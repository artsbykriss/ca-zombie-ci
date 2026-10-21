// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IPerpsAccount } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsAccount.sol";
import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";
import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

/// @title IPerpsRiskManagement
/// @notice Interface for liquidation, takeover, and ADL functions
interface IPerpsRiskManagement {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Request parameters to liquidate a position
    struct LiquidateParams {
        uint16 marketId;
        address account;
        uint128 expectedPrice;
        uint128 expectedSize;
        IOrdersManager.OrderSide positionSide;
    }

    /// @notice Counterparty for ADL
    // forge-lint: disable-next-line(pascal-case-struct)
    struct ADLCounterparty {
        address account;
        uint128 size;
    }

    /// @notice Request parameters for auto-deleveraging
    // forge-lint: disable-next-line(pascal-case-struct)
    struct ADLParams {
        uint16 marketId;
        address account;
        ADLCounterparty[] counterparties;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when liquidating a healthy account
    error HealthyAccount(address account);

    /// @notice Thrown when liquidating an account that must be taken over by RLP
    error AccountMustBeTakenOverByRLP(address account);

    /// @notice Thrown when liquidating a healthy position
    error HealthyPosition(address account, uint16 marketId);

    /// @notice Thrown when liquidating a position that must be taken over by RLP
    error PositionMustBeTakenOverByRLP(address account, uint16 marketId);

    /// @notice Thrown when position does not need RLP takeover
    error PositionNotEligibleForRLPTakeover(address account, uint16 marketId);

    /// @notice Thrown when account does not need RLP takeover
    error AccountNotEligibleForRLPTakeover(address account);

    /// @notice Thrown when total margin accountable order unfilled size is not cleared
    error TotalMarginAccountableOrderUnfilledSizeNotCleared(uint256 totalOrderUnfilledSize);

    /// @notice Thrown when total margin accountable order notional is not cleared
    error TotalMarginAccountableOrderNotionalNotCleared(uint256 isolatedOrderNotional);

    /// @notice Thrown when the margin mode is not as expected
    error InvalidMarginMode(IPerpsAccount.MarginMode expected, IPerpsAccount.MarginMode actual);

    /// @notice Thrown when the position size is zero
    error ZeroPositionSize();

    /// @notice Thrown when the cross margin balance is zero or negative (already bankrupted)
    error AlreadyBankrupted(int256 balance);

    /// @notice Thrown when the ADL size is zero
    error ADLZeroSize();

    /// @notice Thrown when there are open orders
    error OpenOrdersExist(uint256 numOpenOrders);

    /// @notice Thrown when a liquidation order could not be placed due to insufficient book depth
    error LiquidationFailed();

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a position is liquidated
    event Liquidate(address indexed account, address indexed liquidator, uint16 marketId, WideOrderId orderId);

    /// @notice Emitted when liquidated positions are taken over by RLP
    event Takeover(address indexed account, address indexed rlp, uint16[] marketIds);

    /// @notice Emitted when auto-deleveraging is executed
    event ADL(
        address indexed account, uint16 indexed marketId, address[] counterparties, uint256[] sizes, uint256 price
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Liquidates a position
    /// @param params The liquidation parameters
    function liquidate(
        LiquidateParams calldata params
    ) external;

    /// @notice Takes over all cross margin positions from an account by RLP
    /// @param account The account to take over
    function crossTakeover(
        address account
    ) external;

    /// @notice Takes over an isolated position from an account by RLP
    /// @param account The account to take over
    /// @param marketId The market ID
    function isolatedTakeover(
        address account,
        uint16 marketId
    ) external;

    /// @notice Executes auto-deleveraging
    /// @param params The ADL parameters
    function executeADL(
        ADLParams calldata params
    ) external;
}
