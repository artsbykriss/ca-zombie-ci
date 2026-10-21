// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import {
    AccessManagedUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { IRISExAdapter } from "risex-adapter/interfaces/IRISExAdapter.sol";
import { IRISExAdapterConnector } from "risex-adapter/interfaces/IRISExAdapterConnector.sol";
import { LibBit } from "solady/src/utils/LibBit.sol";

/// @title RISExAdapter
/// @notice Non-delegatecall adapter that holds the canonical RISEx account identity.
/// @dev Deployed behind TransparentUpgradeableProxy (TUP). The adapter is the collateral account
///      and perps user/vault identity on RISEx. It calls PerpsManager and CollateralManager
///      through a swappable connector that encodes/decodes the current RISEx ABI.
///      Access control is delegated to an external AccessManager authority.
contract RISExAdapter is IRISExAdapter, AccessManagedUpgradeable, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;
    using Address for address;
    using BitMaps for BitMaps.BitMap;

    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:risex.storage.adapters.Adapter
    struct AdapterStorage {
        address strategy;
        address connector;
        address collateralManager;
        address ordersManager;
        address perpsManager;
        address accountRegistry;
        BitMaps.BitMap allowedSelectors;
    }

    /// @dev ERC-7201 storage slot for AdapterStorage.
    /// keccak256(abi.encode(uint256(keccak256("risex.storage.adapters.Adapter")) - 1)) & ~bytes32(uint256(0xff))
    /// Verify with `cast index-erc7201 "risex.storage.adapters.Adapter"`
    bytes32 private constant ADAPTER_STORAGE_LOCATION =
        0xf9cbdc52c94633716063c7906d01499a468b28f4e7546df5cc2bd1d0fa663700;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyStrategy() {
        _requireStrategy();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 INITIALIZATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the adapter proxy.
    /// @param authority The AccessManager authority contract.
    /// @param strategy The strategy vault that owns this adapter.
    /// @param connector The initial connector contract.
    /// @param endpoints The initial RISEx endpoint addresses.
    function initialize(
        address authority,
        address strategy,
        address connector,
        IRISExAdapterConnector.EndpointSet calldata endpoints
    ) external initializer {
        __AccessManaged_init(authority);

        _requireNonZeroAddress(strategy);
        _requireNonZeroAddress(connector);

        AdapterStorage storage $ = _storage();
        $.strategy = strategy;
        $.connector = connector;
        _setEndpoints($, endpoints);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  ADAPTER INFO
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function adapterVersion() external pure returns (uint64) {
        return 1;
    }

    /// @inheritdoc IRISExAdapter
    function capabilities() external view returns (uint256) {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        return IRISExAdapterConnector($.connector).capabilities(endpoints);
    }

    /// @inheritdoc IRISExAdapter
    function getStrategy() external view returns (address) {
        return _storage().strategy;
    }

    /// @inheritdoc IRISExAdapter
    function getConnector() external view returns (address) {
        return _storage().connector;
    }

    /// @inheritdoc IRISExAdapter
    function getEndpoints() external view returns (IRISExAdapterConnector.EndpointSet memory) {
        return _endpoints(_storage());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN (RESTRICTED)
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function setStrategy(
        address newStrategy
    ) external restricted {
        _requireNonZeroAddress(newStrategy);
        AdapterStorage storage $ = _storage();
        address old = $.strategy;
        $.strategy = newStrategy;
        emit StrategyUpdated(old, newStrategy);
    }

    /// @inheritdoc IRISExAdapter
    function setConnector(
        address newConnector
    ) external restricted {
        _requireNonZeroAddress(newConnector);
        AdapterStorage storage $ = _storage();
        address old = $.connector;
        $.connector = newConnector;
        emit ConnectorUpdated(old, newConnector);
    }

    /// @notice Updates all RISEx endpoint addresses.
    function setEndpoints(
        IRISExAdapterConnector.EndpointSet calldata endpoints
    ) external restricted {
        _setEndpoints(_storage(), endpoints);
    }

    /// @notice Allows or disallows a selector for `executeCustom`.
    function setAllowedSelector(
        bytes4 selector,
        bool allowed
    ) external restricted {
        _storage().allowedSelectors.setTo(uint32(selector), allowed);
        emit AllowedSelectorUpdated(selector, allowed);
    }

    /// @notice Returns whether a selector is allowed for `executeCustom`.
    function getIsAllowedSelector(
        bytes4 selector
    ) external view returns (bool) {
        return _storage().allowedSelectors.get(uint32(selector));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  COLLATERAL
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function deployCollateral(
        address asset,
        uint256 amount
    ) external nonReentrant onlyStrategy {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call =
            _buildCall($, Action.DeployCollateral, endpoints, abi.encode(asset, amount));

        IERC20(asset).forceApprove(call.target, amount);
        _executeCall(call);
        IERC20(asset).forceApprove(call.target, 0);
    }

    /// @inheritdoc IRISExAdapter
    function freeCollateral(
        address asset,
        uint256 amount
    ) external nonReentrant onlyStrategy returns (uint256) {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call =
            _buildCall($, Action.FreeCollateral, endpoints, abi.encode(asset, amount, msg.sender));

        uint256 balanceBefore = IERC20(asset).balanceOf(msg.sender);
        _executeCall(call);
        return IERC20(asset).balanceOf(msg.sender) - balanceBefore;
    }

    /// @inheritdoc IRISExAdapter
    function emergencyWithdraw(
        address asset,
        uint256 amount,
        address receiver
    ) external nonReentrant restricted returns (uint256) {
        _requireNonZeroAddress(receiver);
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call =
            _buildCall($, Action.EmergencyWithdraw, endpoints, abi.encode(asset, amount, receiver));

        uint256 balanceBefore = IERC20(asset).balanceOf(receiver);
        _executeCall(call);
        return IERC20(asset).balanceOf(receiver) - balanceBefore;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ORDERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function placeOrder(
        OrderRequest calldata request
    ) external nonReentrant onlyStrategy returns (bytes32) {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call = _buildCall($, Action.PlaceOrder, endpoints, abi.encode(request));

        bytes memory ret = _executeCallWithReturn($, Action.PlaceOrder, call);
        return abi.decode(ret, (bytes32));
    }

    /// @inheritdoc IRISExAdapter
    function cancelOrder(
        CancelRequest calldata request
    ) external nonReentrant onlyStrategy {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call = _buildCall($, Action.CancelOrder, endpoints, abi.encode(request));

        _executeCall(call);
    }

    /// @inheritdoc IRISExAdapter
    function transferToMM(
        OtcRequest calldata request
    ) external nonReentrant restricted {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call = _buildCall($, Action.TransferToMM, endpoints, abi.encode(request));

        _executeCall(call);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                RISK / TAKEOVER
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function executeCrossTakeover(
        address account
    ) external nonReentrant onlyStrategy {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call =
            _buildCall($, Action.ExecuteCrossTakeover, endpoints, abi.encode(account));

        _executeCall(call);
    }

    /// @inheritdoc IRISExAdapter
    function executeIsolatedTakeover(
        address account,
        uint16 marketId
    ) external nonReentrant onlyStrategy {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call =
            _buildCall($, Action.ExecuteIsolatedTakeover, endpoints, abi.encode(account, marketId));

        _executeCall(call);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    VIEWS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function getAccountEquity() external view returns (int256) {
        bytes memory ret = _query(Action.GetAccountEquity, "");
        return abi.decode(ret, (int256));
    }

    /// @inheritdoc IRISExAdapter
    function getWithdrawableUSD() external view returns (uint256) {
        bytes memory ret = _query(Action.GetWithdrawableUSD, "");
        return abi.decode(ret, (uint256));
    }

    /// @inheritdoc IRISExAdapter
    function getCollateralBalance(
        address asset
    ) external view returns (int256) {
        bytes memory ret = _query(Action.GetCollateralBalance, abi.encode(asset));
        return abi.decode(ret, (int256));
    }

    /// @inheritdoc IRISExAdapter
    function getPosition(
        uint16 marketId,
        address account
    ) external view returns (bytes memory) {
        return _query(Action.GetPosition, abi.encode(marketId, account));
    }

    /// @inheritdoc IRISExAdapter
    function hasPosition(
        uint16 marketId,
        address account
    ) external view returns (bool) {
        bytes memory ret = _query(Action.HasPosition, abi.encode(marketId, account));
        return abi.decode(ret, (bool));
    }

    /// @inheritdoc IRISExAdapter
    function getMarkPrice(
        uint16 marketId
    ) external view returns (uint256) {
        bytes memory ret = _query(Action.GetMarkPrice, abi.encode(marketId));
        return abi.decode(ret, (uint256));
    }

    /// @inheritdoc IRISExAdapter
    function getActiveMarkets(
        address account
    ) external view returns (uint256[] memory) {
        bytes memory ret = _query(Action.GetActiveMarkets, abi.encode(account));
        return abi.decode(ret, (uint256[]));
    }

    /// @inheritdoc IRISExAdapter
    function getActiveMarketIds(
        address account
    ) external view returns (uint16[] memory marketIds) {
        bytes memory ret = _query(Action.GetActiveMarkets, abi.encode(account));
        uint256[] memory bitmap = abi.decode(ret, (uint256[]));

        uint256 total;
        for (uint256 i; i < bitmap.length; ++i) {
            total += LibBit.popCount(bitmap[i]);
        }

        marketIds = new uint16[](total);
        uint256 idx;
        for (uint256 bucketIndex; bucketIndex < bitmap.length; ++bucketIndex) {
            uint256 word = bitmap[bucketIndex];
            while (word != 0) {
                uint256 bitIndex = LibBit.ffs(word);
                marketIds[idx++] = uint16((bucketIndex << 8) | bitIndex);
                word &= word - 1;
            }
        }
    }

    /// @inheritdoc IRISExAdapter
    function isReduceOnly(
        uint32 flags
    ) external pure returns (bool) {
        return (flags & (1 << 1)) != 0;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 ESCAPE HATCH
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function executeCustom(
        address target,
        bytes calldata data
    ) external nonReentrant restricted returns (bytes memory) {
        require(data.length >= 4, InvalidCalldata());
        require(target != address(this) && target != authority(), TargetBlocked(target));
        AdapterStorage storage $ = _storage();
        bytes4 selector = bytes4(data[:4]);
        require($.allowedSelectors.get(uint32(selector)), SelectorNotAllowed(selector));
        return target.functionCall(data);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  ERC-1271
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExAdapter
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        if (SignatureChecker.isValidSignatureNow(_storage().strategy, hash, signature)) {
            return IERC1271.isValidSignature.selector;
        }
        return bytes4(0xffffffff);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   INTERNALS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if msg.sender is not the registered strategy.
    function _requireStrategy() internal view {
        require(msg.sender == _storage().strategy, NotStrategy());
    }

    /// @dev Reverts if the given address is the zero address.
    function _requireNonZeroAddress(
        address addr
    ) internal pure {
        require(addr != address(0), ZeroAddress());
    }

    /// @dev Returns the ERC-7201 namespaced storage pointer.
    function _storage() internal pure returns (AdapterStorage storage $) {
        assembly ("memory-safe") {
            $.slot := ADAPTER_STORAGE_LOCATION
        }
    }

    /// @dev Reads the endpoint addresses from storage into a memory struct.
    function _endpoints(
        AdapterStorage storage $
    ) internal view returns (IRISExAdapterConnector.EndpointSet memory) {
        return IRISExAdapterConnector.EndpointSet({
            collateralManager: $.collateralManager,
            ordersManager: $.ordersManager,
            perpsManager: $.perpsManager,
            accountRegistry: $.accountRegistry
        });
    }

    /// @dev Validates and writes new endpoint addresses to storage.
    function _setEndpoints(
        AdapterStorage storage $,
        IRISExAdapterConnector.EndpointSet calldata endpoints
    ) internal {
        _requireNonZeroAddress(endpoints.collateralManager);
        _requireNonZeroAddress(endpoints.ordersManager);
        _requireNonZeroAddress(endpoints.perpsManager);
        _requireNonZeroAddress(endpoints.accountRegistry);
        $.collateralManager = endpoints.collateralManager;
        $.ordersManager = endpoints.ordersManager;
        $.perpsManager = endpoints.perpsManager;
        $.accountRegistry = endpoints.accountRegistry;
        emit EndpointsUpdated(
            endpoints.collateralManager, endpoints.ordersManager, endpoints.perpsManager, endpoints.accountRegistry
        );
    }

    /// @dev Delegates call encoding to the connector.
    function _buildCall(
        AdapterStorage storage $,
        Action action,
        IRISExAdapterConnector.EndpointSet memory endpoints,
        bytes memory input
    ) internal view returns (IRISExAdapterConnector.Call memory) {
        return IRISExAdapterConnector($.connector).buildCall(action, address(this), endpoints, input);
    }

    /// @dev Executes a low-level call, reverting on failure.
    function _executeCall(
        IRISExAdapterConnector.Call memory call
    ) internal {
        call.target.functionCallWithValue(call.data, call.value);
    }

    /// @dev Executes a call and decodes the return data through the connector.
    function _executeCallWithReturn(
        AdapterStorage storage $,
        Action action,
        IRISExAdapterConnector.Call memory call
    ) internal returns (bytes memory) {
        bytes memory ret = call.target.functionCallWithValue(call.data, call.value);
        return IRISExAdapterConnector($.connector).decodeResult(action, ret);
    }

    /// @dev Builds and executes a static call, decoding the result through the connector.
    function _query(
        Action action,
        bytes memory input
    ) internal view returns (bytes memory) {
        AdapterStorage storage $ = _storage();
        IRISExAdapterConnector.EndpointSet memory endpoints = _endpoints($);
        IRISExAdapterConnector.Call memory call = _buildCall($, action, endpoints, input);

        bytes memory ret = call.target.functionStaticCall(call.data);
        return IRISExAdapterConnector($.connector).decodeResult(action, ret);
    }
}
