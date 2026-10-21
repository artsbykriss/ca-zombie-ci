// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IPerpsAccount } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsAccount.sol";
import { IPerpsCrossMargin } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsCrossMargin.sol";
import { IPerpsIsolatedMargin } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsIsolatedMargin.sol";
import { IPerpsMarketConfig } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsMarketConfig.sol";
import { IPerpsRiskManagement } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsRiskManagement.sol";
import { IPerpsVaultManagement } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsVaultManagement.sol";
import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";
import { RestingOrderId } from "src/libraries/types/RestingOrderId.sol";
import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

interface IPerpsManager is
    IPerpsAccount,
    IPerpsCrossMargin,
    IPerpsIsolatedMargin,
    IPerpsMarketConfig,
    IPerpsVaultManagement,
    IPerpsRiskManagement
{
    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the token is not a collateral token
    error NotCollateral(address token);

    /// @notice Thrown when the token is already added as a collateral token
    error CollateralAlreadyAdded(address token);

    /// @notice Thrown when the withdrawal fails
    error FailedToWithdraw(address account, address token, uint256 amount);

    /// @notice Thrown when reduce-only order has invalid time-in-force
    error InvalidTimeInForceForReduceOnlyOrder(IOrdersManager.TimeInForce timeInForce);

    /// @notice Thrown when the migration target account is invalid (zero, same as source, or has existing state)
    error InvalidMigrationTarget(address newAccount);

    /// @notice Thrown when the source account is unhealthy and cannot be migrated
    error UnhealthySourceAccount(address account);

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a collateral token is added
    event AddCollateral(address indexed token);

    /// @notice Emitted when an account is migrated to a new address
    event AccountMigrated(address indexed oldAccount, address indexed newAccount);

    /// @notice Emitted when the protocol is paused
    event Pause();

    /// @notice Emitted when the protocol is unpaused
    event Unpause();

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Places a new order
    function placeOrder(
        IOrdersManager.PlaceOrderParams calldata params
    ) external returns (WideOrderId orderId);

    /// @notice Cancels a single order
    /// @param params The cancel order parameters
    function cancelOrder(
        IOrdersManager.CancelOrderParams calldata params
    ) external;

    /// @notice Cancels orders by their IDs
    /// @param marketId The market ID
    /// @param orderIds The order IDs to cancel
    function cancelOrders(
        uint16 marketId,
        RestingOrderId[] calldata orderIds
    ) external;

    /// @notice Migrates all positions, collateral, and open orders from the caller to a new account
    /// @param newAccount The target account to migrate to
    function migrateAccount(
        address newAccount
    ) external;
}
