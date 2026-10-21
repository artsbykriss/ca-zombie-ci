// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IRISExAdapterConnector } from "risex-adapter/interfaces/IRISExAdapterConnector.sol";

/// @title IRISExAdapter
/// @notice Stable strategy-facing interface for a non-delegatecall RISEx account adapter.
/// @dev The adapter is the canonical RISEx collateral account and perps user/vault identity.
///      It calls PerpsManager (not OrdersManager directly) for order and risk operations.
///      Access control is delegated to an external AccessManager authority.
interface IRISExAdapter {
    /*//////////////////////////////////////////////////////////////////////////
                                    ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum Side {
        Buy,
        Sell
    }

    enum Action {
        DeployCollateral,
        FreeCollateral,
        EmergencyWithdraw,
        PlaceOrder,
        CancelOrder,
        TransferToMM,
        ExecuteCrossTakeover,
        ExecuteIsolatedTakeover,
        GetAccountEquity,
        GetWithdrawableUSD,
        GetCollateralBalance,
        GetPosition,
        HasPosition,
        GetMarkPrice,
        GetActiveMarkets
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Parameters for placing an order on the RISEx order book.
    /// @param marketId The perps market identifier.
    /// @param side The order side (Buy or Sell).
    /// @param size The order size in raw units (will be divided by stepSize).
    /// @param limitPrice The limit price in raw units (will be divided by stepPrice).
    /// @param flags Packed bit field: postOnly(0), reduceOnly(1), orderType(3:2),
    ///              timeInForce(5:4), stpMode(7:6), ttlUnits(23:8), headerVersion(31:24).
    /// @param extraData Optional connector-specific payload (e.g. builderId).
    struct OrderRequest {
        uint16 marketId;
        Side side;
        uint128 size;
        uint128 limitPrice;
        uint32 flags;
        bytes extraData;
    }

    /// @notice Parameters for cancelling a resting order.
    /// @param marketId The perps market identifier.
    /// @param orderId The WideOrderId returned by placeOrder, stored as bytes32.
    /// @param extraData Reserved for future connector-specific payload.
    struct CancelRequest {
        uint16 marketId;
        bytes32 orderId;
        bytes extraData;
    }

    /// @notice Parameters for an OTC vault-to-market-maker transfer.
    /// @param marketId The perps market identifier.
    /// @param mmVault The market maker vault address.
    /// @param side The transfer side (Buy or Sell).
    /// @param size The notional size to transfer.
    /// @param price The agreed OTC price.
    /// @param flags Reserved for future use.
    /// @param extraData Reserved for future connector-specific payload.
    struct OtcRequest {
        uint16 marketId;
        address mmVault;
        Side side;
        uint128 size;
        uint128 price;
        uint32 flags;
        bytes extraData;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the connector contract is updated.
    /// @param oldConnector The previous connector address.
    /// @param newConnector The new connector address.
    event ConnectorUpdated(address indexed oldConnector, address indexed newConnector);

    /// @notice Emitted when the RISEx endpoint addresses are updated.
    /// @param collateralManager The new CollateralManager address.
    /// @param ordersManager The new OrdersManager address.
    /// @param perpsManager The new PerpsManager address.
    /// @param accountRegistry The new AccountRegistry address.
    event EndpointsUpdated(
        address indexed collateralManager,
        address indexed ordersManager,
        address indexed perpsManager,
        address accountRegistry
    );

    /// @notice Emitted when an escape-hatch selector allowance is toggled.
    /// @param selector The function selector being configured.
    /// @param allowed Whether the selector is now allowed.
    event AllowedSelectorUpdated(bytes4 indexed selector, bool allowed);

    /// @notice Emitted when the strategy contract is updated.
    /// @param oldStrategy The previous strategy address.
    /// @param newStrategy The new strategy address.
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a zero address is provided where one is required.
    error ZeroAddress();

    /// @notice Thrown when the caller is not the registered strategy.
    error NotStrategy();

    /// @notice Thrown when calldata is too short (less than 4 bytes).
    error InvalidCalldata();

    /// @notice Thrown when executeCustom is called with a disallowed selector.
    /// @param selector The disallowed selector.
    error SelectorNotAllowed(bytes4 selector);

    /// @notice Thrown when executeCustom targets a blocked address (e.g. the adapter itself or its authority).
    /// @param target The blocked target address.
    error TargetBlocked(address target);

    /*//////////////////////////////////////////////////////////////////////////
                                  ADAPTER INFO
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the adapter implementation version.
    /// @return The version number.
    function adapterVersion() external pure returns (uint64);

    /// @notice Returns a bitmask of actions supported by the current connector.
    /// @return A uint256 bitmask where each set bit represents a supported action.
    function capabilities() external view returns (uint256);

    /// @notice Returns the current strategy address.
    /// @return The strategy contract address.
    function getStrategy() external view returns (address);

    /// @notice Returns the current connector address.
    /// @return The connector contract address.
    function getConnector() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN (RESTRICTED)
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets a new strategy address. Restricted to management role.
    /// @param newStrategy The new strategy contract address.
    function setStrategy(
        address newStrategy
    ) external;

    /// @notice Sets a new connector address. Restricted to management role.
    /// @param newConnector The new connector contract address.
    function setConnector(
        address newConnector
    ) external;

    /*//////////////////////////////////////////////////////////////////////////
                                   COLLATERAL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Pulls tokens from the strategy and deposits them as collateral on RISEx.
    /// @param asset The ERC-20 token address.
    /// @param amount The amount to deposit.
    function deployCollateral(
        address asset,
        uint256 amount
    ) external;

    /// @notice Withdraws collateral from RISEx back to the strategy.
    /// @param asset The ERC-20 token address.
    /// @param amount The amount to withdraw.
    /// @return freed The actual amount received by the strategy.
    function freeCollateral(
        address asset,
        uint256 amount
    ) external returns (uint256 freed);

    /// @notice Emergency withdrawal to an arbitrary receiver. Restricted to management role.
    /// @param asset The ERC-20 token address.
    /// @param amount The amount to withdraw.
    /// @param receiver The address that will receive the tokens.
    /// @return freed The actual amount received by the receiver.
    function emergencyWithdraw(
        address asset,
        uint256 amount,
        address receiver
    ) external returns (uint256 freed);

    /*//////////////////////////////////////////////////////////////////////////
                                     ORDERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Places an order on the RISEx order book via the PerpsManager.
    /// @param request The order parameters.
    /// @return orderRef The WideOrderId returned by the exchange, stored as bytes32.
    function placeOrder(
        OrderRequest calldata request
    ) external returns (bytes32 orderRef);

    /// @notice Cancels a resting order on the RISEx order book.
    /// @param request The cancel parameters including the orderId from placeOrder.
    function cancelOrder(
        CancelRequest calldata request
    ) external;

    /// @notice Transfers a position to a market maker vault via OTC. Restricted to operator role.
    /// @param request The OTC transfer parameters.
    function transferToMM(
        OtcRequest calldata request
    ) external;

    /*//////////////////////////////////////////////////////////////////////////
                                  RISK / TAKEOVER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Executes a cross-margin takeover (liquidation) on an underwater account.
    /// @param account The account to take over.
    function executeCrossTakeover(
        address account
    ) external;

    /// @notice Executes an isolated-margin takeover (liquidation) on an underwater position.
    /// @param account The account to take over.
    /// @param marketId The isolated market identifier.
    function executeIsolatedTakeover(
        address account,
        uint16 marketId
    ) external;

    /*//////////////////////////////////////////////////////////////////////////
                                     VIEWS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the adapter's total account equity in USD (WAD).
    /// @return The equity as a signed integer (negative means underwater).
    function getAccountEquity() external view returns (int256);

    /// @notice Returns the adapter's withdrawable USD balance (WAD).
    /// @return The withdrawable amount.
    function getWithdrawableUSD() external view returns (uint256);

    /// @notice Returns the adapter's collateral balance for a specific asset.
    /// @param asset The ERC-20 token address.
    /// @return The balance as a signed integer.
    function getCollateralBalance(
        address asset
    ) external view returns (int256);

    /// @notice Returns the raw position data for a market and account.
    /// @param marketId The perps market identifier.
    /// @param account The account address.
    /// @return The ABI-encoded position struct.
    function getPosition(
        uint16 marketId,
        address account
    ) external view returns (bytes memory);

    /// @notice Returns whether the account has an open position in a market.
    /// @param marketId The perps market identifier.
    /// @param account The account address.
    /// @return True if position size is non-zero.
    function hasPosition(
        uint16 marketId,
        address account
    ) external view returns (bool);

    /// @notice Returns the current RISEx endpoint addresses.
    /// @return The endpoint set containing all protocol addresses.
    function getEndpoints() external view returns (IRISExAdapterConnector.EndpointSet memory);

    /// @notice Returns the mark price for a market from the RISEx oracle (WAD).
    /// @param marketId The perps market identifier.
    /// @return The mark price in WAD (18 decimals).
    function getMarkPrice(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Returns the active markets bitmap for an account.
    /// @param account The account address.
    /// @return The bitmap array where each set bit represents an active market.
    function getActiveMarkets(
        address account
    ) external view returns (uint256[] memory);

    /// @notice Returns decoded active market IDs for an account.
    /// @param account The account address.
    /// @return marketIds Array of active market IDs extracted from the bitmap.
    function getActiveMarketIds(
        address account
    ) external view returns (uint16[] memory marketIds);

    /// @notice Returns whether the given OrderRequest flags indicate a reduce-only order.
    /// @param flags The packed flags field from OrderRequest.
    /// @return True if the reduceOnly bit is set.
    function isReduceOnly(
        uint32 flags
    ) external pure returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                  ESCAPE HATCH
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calls an arbitrary target with pre-approved selector. Restricted to management role.
    /// @dev Selector must be allowlisted via setAllowedSelector before use.
    /// @param target The contract to call.
    /// @param data The calldata (must be at least 4 bytes).
    /// @return result The raw return data from the call.
    function executeCustom(
        address target,
        bytes calldata data
    ) external returns (bytes memory result);

    /*//////////////////////////////////////////////////////////////////////////
                                    ERC-1271
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice ERC-1271 signature validation. Delegates to the strategy via SignatureChecker.
    /// @param hash The hash that was signed.
    /// @param signature The signature bytes.
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise.
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4 magicValue);
}
