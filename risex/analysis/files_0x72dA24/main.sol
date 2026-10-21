// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IRISExAdapter } from "risex-adapter/interfaces/IRISExAdapter.sol";
import { IRISExAdapterConnector } from "risex-adapter/interfaces/IRISExAdapterConnector.sol";
import { ICollateralManager } from "risex-contracts/src/interfaces/exchanges/perps/collateral/ICollateralManager.sol";
import { IPerpsManager } from "risex-contracts/src/interfaces/exchanges/perps/engine/IPerpsManager.sol";
import { IPerpsAccount } from "risex-contracts/src/interfaces/exchanges/perps/engine/extensions/IPerpsAccount.sol";
import {
    IPerpsRiskManagement
} from "risex-contracts/src/interfaces/exchanges/perps/engine/extensions/IPerpsRiskManagement.sol";
import {
    IPerpsVaultManagement
} from "risex-contracts/src/interfaces/exchanges/perps/engine/extensions/IPerpsVaultManagement.sol";
import { IRISExOracle } from "risex-contracts/src/interfaces/oracles/IRISExOracle.sol";
import { IOrdersManager } from "risex-contracts/src/interfaces/order-book/IOrdersManager.sol";

/// @title RISExAdapterConnectorV1
/// @notice Version 1 connector: encodes/decodes calls for the current RISEx ABI.
/// @dev Stateless. The adapter remains the caller for all external interactions.
///      Uses abi.encodeWithSelector for cross-boundary calls to avoid UDVT type conflicts
///      between the adapter project and the risex-contracts dependency.
contract RISExAdapterConnectorV1 is IRISExAdapterConnector {
    /*//////////////////////////////////////////////////////////////////////////
                                 FLAGS LAYOUT
    //////////////////////////////////////////////////////////////////////////*/

    // OrderRequest.flags bit layout:
    //   [0]      postOnly
    //   [1]      reduceOnly
    //   [3:2]    orderType   (0=Market, 1=Limit)
    //   [5:4]    timeInForce (0=GTC, 1=GTT, 2=FOK, 3=IOC)
    //   [7:6]    stpMode     (0=ExpireMaker, 1=ExpireTaker, 2=ExpireBoth)
    //   [23:8]   ttlUnits    (16 bits)
    //   [31:24]  headerVersion (8 bits)

    uint32 private constant FLAG_POST_ONLY = 1 << 0;
    uint32 private constant FLAG_REDUCE_ONLY = 1 << 1;
    uint32 private constant MASK_ORDER_TYPE = 0x03;
    uint32 private constant SHIFT_ORDER_TYPE = 2;
    uint32 private constant MASK_TIME_IN_FORCE = 0x03;
    uint32 private constant SHIFT_TIME_IN_FORCE = 4;
    uint32 private constant MASK_STP_MODE = 0x03;
    uint32 private constant SHIFT_STP_MODE = 6;
    uint32 private constant MASK_TTL_UNITS = 0xFFFF;
    uint32 private constant SHIFT_TTL_UNITS = 8;
    uint32 private constant SHIFT_HEADER_VERSION = 24;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONNECTOR INFO
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapterConnector
    function connectorVersion() external pure returns (uint64) {
        return 1;
    }

    /// @inheritdoc IRISExAdapterConnector
    function capabilities(
        EndpointSet calldata
    ) external pure returns (uint256) {
        // All actions supported in V1
        return type(uint256).max;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  BUILD CALL
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapterConnector
    function buildCall(
        IRISExAdapter.Action action,
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) external view returns (Call memory call) {
        if (action == IRISExAdapter.Action.DeployCollateral) {
            return _buildDeployCollateral(adapterAccount, endpoints, input);
        } else if (action == IRISExAdapter.Action.FreeCollateral) {
            return _buildFreeCollateral(adapterAccount, endpoints, input);
        } else if (action == IRISExAdapter.Action.EmergencyWithdraw) {
            return _buildEmergencyWithdraw(adapterAccount, endpoints, input);
        } else if (action == IRISExAdapter.Action.PlaceOrder) {
            return _buildPlaceOrder(endpoints, input);
        } else if (action == IRISExAdapter.Action.CancelOrder) {
            return _buildCancelOrder(endpoints, input);
        } else if (action == IRISExAdapter.Action.TransferToMM) {
            return _buildTransferToMM(adapterAccount, endpoints, input);
        } else if (action == IRISExAdapter.Action.ExecuteCrossTakeover) {
            return _buildCrossTakeover(endpoints, input);
        } else if (action == IRISExAdapter.Action.ExecuteIsolatedTakeover) {
            return _buildIsolatedTakeover(endpoints, input);
        } else if (action == IRISExAdapter.Action.GetAccountEquity) {
            return _buildGetAccountEquity(adapterAccount, endpoints);
        } else if (action == IRISExAdapter.Action.GetWithdrawableUSD) {
            return _buildGetWithdrawableUSDC(adapterAccount, endpoints);
        } else if (action == IRISExAdapter.Action.GetCollateralBalance) {
            return _buildGetCollateralBalance(adapterAccount, endpoints, input);
        } else if (action == IRISExAdapter.Action.GetPosition) {
            return _buildGetPosition(endpoints, input);
        } else if (action == IRISExAdapter.Action.HasPosition) {
            return _buildGetPosition(endpoints, input);
        } else if (action == IRISExAdapter.Action.GetMarkPrice) {
            return _buildGetMarkPrice(endpoints, input);
        } else if (action == IRISExAdapter.Action.GetActiveMarkets) {
            return _buildGetActiveMarkets(endpoints, input);
        }
        revert UnsupportedAction(action);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 DECODE RESULT
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapterConnector
    function decodeResult(
        IRISExAdapter.Action action,
        bytes calldata returnData
    ) external pure returns (bytes memory) {
        if (action == IRISExAdapter.Action.PlaceOrder) {
            // WideOrderId is type WideOrderId is uint56 — decode as uint56 to avoid UDVT conflict
            uint56 orderId = abi.decode(returnData, (uint56));
            return abi.encode(bytes32(uint256(orderId)));
        } else if (action == IRISExAdapter.Action.GetAccountEquity) {
            return returnData;
        } else if (action == IRISExAdapter.Action.GetWithdrawableUSD) {
            return returnData;
        } else if (action == IRISExAdapter.Action.GetCollateralBalance) {
            return returnData;
        } else if (action == IRISExAdapter.Action.GetPosition) {
            return returnData;
        } else if (action == IRISExAdapter.Action.HasPosition) {
            // Position struct: (int128 size, int128 quoteAmount, int128 lastFundingPayment,
            //                   uint16 leverage, uint8 marginMode, int128 isolatedUsdcBalance)
            (int128 size,,,,,) = abi.decode(returnData, (int128, int128, int128, uint16, uint8, int128));
            return abi.encode(size != 0);
        } else if (action == IRISExAdapter.Action.GetMarkPrice) {
            return returnData;
        } else if (action == IRISExAdapter.Action.GetActiveMarkets) {
            return returnData;
        }
        // Actions that return void: DeployCollateral, FreeCollateral, EmergencyWithdraw,
        // CancelOrder, TransferToMM, ExecuteCrossTakeover, ExecuteIsolatedTakeover
        return returnData;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL: COLLATERAL
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Encodes a CollateralManager.deposit call.
    function _buildDeployCollateral(
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        (address asset, uint256 amount) = abi.decode(input, (address, uint256));
        // deposit(address account, Currency token, uint256 amount)
        // Currency is type Currency is address — pass asset directly
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.deposit.selector, adapterAccount, asset, amount)
        });
    }

    /// @dev Encodes a CollateralManager.withdraw call to the strategy.
    function _buildFreeCollateral(
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        // withdraw(address receiver, Currency token, uint256 amount)
        (address asset, uint256 amount, address receiver) = abi.decode(input, (address, uint256, address));
        address to = receiver == address(0) ? adapterAccount : receiver;
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.withdraw.selector, to, asset, amount)
        });
    }

    /// @dev Encodes a CollateralManager.withdraw call to an arbitrary receiver.
    function _buildEmergencyWithdraw(
        address,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        (address asset, uint256 amount, address receiver) = abi.decode(input, (address, uint256, address));
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.withdraw.selector, receiver, asset, amount)
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                               INTERNAL: ORDERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Encodes a PerpsManager.placeOrder call with step/tick conversion.
    function _buildPlaceOrder(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal view returns (Call memory) {
        IRISExAdapter.OrderRequest memory req = abi.decode(input, (IRISExAdapter.OrderRequest));

        // Query book config for step/tick conversion
        IOrdersManager.Config memory config =
            IOrdersManager(endpoints.ordersManager).getBookConfig(endpoints.perpsManager, req.marketId);
        uint64 stepSize = config.stepSize;
        uint64 stepPrice = config.stepPrice;
        require(stepSize > 0 && stepPrice > 0, BookConfigQueryFailed());

        require(uint256(req.size) % uint256(stepSize) == 0, SizeNotAligned(req.size, stepSize));
        uint256 sizeSteps = uint256(req.size) / uint256(stepSize);
        require(sizeSteps <= type(uint32).max, SizeOverflow(req.size, stepSize));

        require(uint256(req.limitPrice) % uint256(stepPrice) == 0, PriceNotAligned(req.limitPrice, stepPrice));
        uint256 priceTicks = uint256(req.limitPrice) / uint256(stepPrice);
        require(priceTicks <= type(uint24).max, PriceOverflow(req.limitPrice, stepPrice));

        uint32 flags = req.flags;
        uint16 builderId;
        if (req.extraData.length >= 32) {
            builderId = abi.decode(req.extraData, (uint16));
        }

        // PlaceOrderParams struct encoded field-by-field to avoid cross-dependency struct conflict
        // Fields: (uint16 marketId, uint32 sizeSteps, uint24 priceTicks, uint16 ttlUnits,
        //          OrderSide side, STPMode stpMode, OrderType orderType, bool postOnly,
        //          bool reduceOnly, TimeInForce timeInForce, uint8 headerVersion, uint16 builderId)
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(
                IPerpsManager.placeOrder.selector,
                req.marketId,
                uint32(sizeSteps),
                uint24(priceTicks),
                uint16((flags >> SHIFT_TTL_UNITS) & MASK_TTL_UNITS),
                uint8(req.side), // OrderSide enum
                uint8((flags >> SHIFT_STP_MODE) & MASK_STP_MODE), // STPMode enum
                uint8((flags >> SHIFT_ORDER_TYPE) & MASK_ORDER_TYPE), // OrderType enum
                (flags & FLAG_POST_ONLY) != 0,
                (flags & FLAG_REDUCE_ONLY) != 0,
                uint8((flags >> SHIFT_TIME_IN_FORCE) & MASK_TIME_IN_FORCE), // TimeInForce enum
                uint8(flags >> SHIFT_HEADER_VERSION),
                builderId
            )
        });
    }

    /// @dev Encodes a PerpsManager.cancelOrder call, converting WideOrderId to RestingOrderId.
    function _buildCancelOrder(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        IRISExAdapter.CancelRequest memory req = abi.decode(input, (IRISExAdapter.CancelRequest));

        // CancelOrderParams { uint16 marketId, RestingOrderId orderId }
        // orderId is a WideOrderId (uint56) stored as bytes32. WideOrderId has a rest bit at
        // bit 0 that must be stripped to get the RestingOrderId (uint40): RestingOrderId = WideOrderId >> 1
        uint256 restingId = uint256(req.orderId) >> 1;
        require(restingId <= type(uint40).max, OrderIdOverflow(req.orderId));
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(IPerpsManager.cancelOrder.selector, req.marketId, uint40(restingId))
        });
    }

    /// @dev Encodes a PerpsVaultManagement.executeVaultOtc call.
    function _buildTransferToMM(
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        IRISExAdapter.OtcRequest memory req = abi.decode(input, (IRISExAdapter.OtcRequest));

        // executeVaultOtc(uint16 marketId, address makerAccount, address takerAccount,
        //                 OrderSide side, uint128 size, uint128 price)
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(
                IPerpsVaultManagement.executeVaultOtc.selector,
                req.marketId,
                adapterAccount,
                req.mmVault,
                uint8(req.side), // OrderSide enum
                req.size,
                req.price
            )
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL: RISK / TAKEOVER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Encodes a PerpsRiskManagement.crossTakeover call.
    function _buildCrossTakeover(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        address account = abi.decode(input, (address));
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(IPerpsRiskManagement.crossTakeover.selector, account)
        });
    }

    /// @dev Encodes a PerpsRiskManagement.isolatedTakeover call.
    function _buildIsolatedTakeover(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        (address account, uint16 marketId) = abi.decode(input, (address, uint16));
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(IPerpsRiskManagement.isolatedTakeover.selector, account, marketId)
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                               INTERNAL: VIEWS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Encodes a CollateralManager.getAccountEquity static call.
    function _buildGetAccountEquity(
        address adapterAccount,
        EndpointSet calldata endpoints
    ) internal pure returns (Call memory) {
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.getAccountEquity.selector, adapterAccount)
        });
    }

    /// @dev Encodes a CollateralManager.getWithdrawableUSDC static call.
    function _buildGetWithdrawableUSDC(
        address adapterAccount,
        EndpointSet calldata endpoints
    ) internal pure returns (Call memory) {
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.getWithdrawableUSDC.selector, adapterAccount)
        });
    }

    /// @dev Encodes a CollateralManager.getTokenBalance static call.
    function _buildGetCollateralBalance(
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        address asset = abi.decode(input, (address));
        // getTokenBalance(address account, Currency token)
        return Call({
            target: endpoints.collateralManager,
            value: 0,
            data: abi.encodeWithSelector(ICollateralManager.getTokenBalance.selector, adapterAccount, asset)
        });
    }

    /// @dev Encodes a PerpsAccount.getPosition static call.
    function _buildGetPosition(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        (uint16 marketId, address account) = abi.decode(input, (uint16, address));
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(IPerpsAccount.getPosition.selector, marketId, account)
        });
    }

    /// @dev Encodes a two-hop static call: CollateralManager.getRisexOracle() → IRISExOracle.getMarkPrice().
    function _buildGetMarkPrice(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal view returns (Call memory) {
        uint16 marketId = abi.decode(input, (uint16));
        // Resolve oracle address from CollateralManager
        address oracle = address(ICollateralManager(endpoints.collateralManager).getRisexOracle());
        return
            Call({
                target: oracle, value: 0, data: abi.encodeWithSelector(IRISExOracle.getMarkPrice.selector, marketId)
            });
    }

    /// @dev Encodes a PerpsAccount.getActiveMarkets static call.
    function _buildGetActiveMarkets(
        EndpointSet calldata endpoints,
        bytes calldata input
    ) internal pure returns (Call memory) {
        address account = abi.decode(input, (address));
        return Call({
            target: endpoints.perpsManager,
            value: 0,
            data: abi.encodeWithSelector(IPerpsAccount.getActiveMarkets.selector, account)
        });
    }
}
