// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IActionHandler} from "./interface/IActionHandler.sol";
import {ICollateralManager} from "./interface/ICollateralManager.sol";
import {IExchangeConfig} from "./interface/IExchangeConfig.sol";
import {IExchangeGateway} from "./interface/IExchangeGateway.sol";
import {IPerpEngine} from "./interface/IPerpEngine.sol";
import {IPerpEngineAdmin} from "./interface/IPerpEngineAdmin.sol";
import {Account} from "./lib/storage/Account.sol";
import {AddressRegistry} from "./lib/storage/AddressRegistry.sol";
import {Deposit} from "./lib/storage/Deposit.sol";
import {Exchange} from "./lib/storage/Exchange.sol";
import {FeeCollector} from "./lib/storage/FeeCollector.sol";
import {FeeSchedule} from "./lib/storage/FeeSchedule.sol";
import {Liquidator} from "./lib/storage/Liquidator.sol";
import {PerpPosition} from "./lib/storage/PerpPosition.sol";
import {PerpProduct} from "./lib/storage/PerpProduct.sol";
import {ProductRegistry} from "./lib/storage/ProductRegistry.sol";
import {Token} from "./lib/storage/Token.sol";
import {Withdraw} from "./lib/storage/Withdraw.sol";
import {EXCHANGE_NAME, EXCHANGE_VERSION} from "./share/Constants.sol";
import {ActionType, ProductStatus} from "./share/Enums.sol";
import {
    DelegationFailed,
    ExchangeNotPaused,
    ExchangePaused,
    InvalidRegistryRecord,
    PingTooSoon,
    UnauthorizedAccount
} from "./share/Errors.sol";
import {
    ACTION_HANDLER_RECORD,
    COLLATERAL_MANAGER_RECORD,
    DELEVERAGE_RECORD,
    DELEVERAGE_WITH_COMPENSATION_RECORD,
    EXCHANGE_CONFIG_RECORD,
    LIQUIDATION_RECORD,
    PERP_ENGINE_ADMIN_RECORD,
    PERP_ENGINE_RECORD
} from "./share/RegistryRecords.sol";
import {Signatures} from "./share/Signatures.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {EIP712} from "solady/utils/EIP712.sol";
import {Initializable} from "solady/utils/Initializable.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";

contract ExchangeGateway is
    EIP712,
    IActionHandler,
    ICollateralManager,
    IExchangeConfig,
    IExchangeGateway,
    UUPSUpgradeable,
    Ownable,
    Initializable
{
    using Exchange for Exchange.Data;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint64 private constant _PING_MIN_DELTA = 10 seconds;
    // --- Constructor --- //

    constructor() {
        _disableInitializers();
    }

    // --- Initializer --- //

    function initialize() external initializer {
        _initializeOwner(msg.sender);
    }

    // --- Overrides --- //

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = EXCHANGE_NAME;
        version = EXCHANGE_VERSION;
    }

    function _domainNameAndVersionMayChange() internal pure override returns (bool) {
        return false;
    }

    // --- Native token support --- //

    receive() external payable {
        if (msg.sender != Account.load().usdToken && msg.sender != owner()) {
            revert UnauthorizedAccount(msg.sender);
        }
    }

    // --- Delegation --- //

    /// @dev Borrowed from openzeppelin-contracts/utils/Address.sol
    /// @custom:see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/Address.sol#L146
    function _revert(bytes memory returnData) private pure {
        if (returnData.length > 0) {
            assembly ("memory-safe") {
                let returndata_size := mload(returnData)
                revert(add(32, returnData), returndata_size)
            }
        } else {
            revert DelegationFailed();
        }
    }

    /// @dev Wraps `delegatecall` with a code-existence check and error propagation.
    function _delegatecall(address target, bytes memory data) private returns (bytes memory) {
        if (target.code.length == 0) {
            revert DelegationFailed();
        }
        (bool success, bytes memory returnData) = target.delegatecall(data);
        if (!success) {
            _revert(returnData);
        } else {
            return returnData;
        }
    }

    /// @dev Performs a delegate call to the ActionHandler with the data argument.
    function _delegateCallActionHandler(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[ACTION_HANDLER_RECORD], data);
    }

    /// @dev Performs a delegate call to the CollateralManagement with the data argument.
    function _delegateCallCollateralManager(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[COLLATERAL_MANAGER_RECORD], data);
    }

    /// @dev Performs a delegate call to the ExchangeConfig with the data argument.
    function _delegateCallExchangeConfig(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[EXCHANGE_CONFIG_RECORD], data);
    }

    /// @dev Performs a delegate call to the PerpEngine with the data argument.
    function _delegateCallPerpEngine(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[PERP_ENGINE_RECORD], data);
    }

    /// @dev Performs a delegate call to the PerpEngineAdmin with the data argument.
    function _delegateCallPerpEngineAdmin(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[PERP_ENGINE_ADMIN_RECORD], data);
    }

    // --- Signatures --- //

    function LINK_SIGNER_ABI_PARAM() external pure returns (bytes memory) {
        return Signatures.LINK_SIGNER_ABI_PARAM;
    }

    function INITIATE_WITHDRAW_ABI_PARAM() external pure returns (bytes memory) {
        return Signatures.INITIATE_WITHDRAW_ABI_PARAM;
    }

    function REVOKE_LINKED_SIGNER_ABI_PARAM() external pure returns (bytes memory) {
        return Signatures.REVOKE_LINKED_SIGNER_ABI_PARAM;
    }

    function TRADE_ORDER_ABI_PARAM() external pure returns (bytes memory) {
        return Signatures.TRADE_ORDER_ABI_PARAM;
    }

    function CONVERT_TOKEN_ABI_PARAM() external pure returns (bytes memory) {
        return Signatures.CONVERT_TOKEN_ABI_PARAM;
    }

    // --- Ping --- //

    /// @inheritdoc IExchangeGateway
    function ping() public {
        Exchange.Data storage exchange = Exchange.load();
        uint64 timestamp = uint64(block.timestamp);
        uint64 lastPingTimestamp = exchange.lastPingTimestamp;

        if (timestamp - lastPingTimestamp < _PING_MIN_DELTA) {
            revert PingTooSoon(lastPingTimestamp, timestamp, _PING_MIN_DELTA);
        }

        // Public by design. This gives offchain indexers a reliable gateway log to observe,
        // and should not be interpreted as authenticated exchange or sequencer liveness.
        exchange.lastPingTimestamp = timestamp;
        emit Ping(msg.sender, timestamp);
    }

    // --- EmergencyPause --- //

    /// @inheritdoc IExchangeGateway
    function emergencyPause() external {
        Exchange.Data storage exchange = Exchange.load();
        if (exchange.isPaused) {
            revert ExchangePaused();
        }
        if (!exchange.isEmergencyPauser[msg.sender] && msg.sender != owner()) {
            revert Unauthorized();
        }

        emit ExchangePauseUpdated(msg.sender, true);
        exchange.isPaused = true;
    }

    /// @inheritdoc IExchangeGateway
    function emergencyUnpause() external onlyOwner {
        Exchange.Data storage exchange = Exchange.load();
        if (!exchange.isPaused) {
            revert ExchangeNotPaused();
        }

        emit ExchangePauseUpdated(msg.sender, false);
        exchange.isPaused = false;
    }

    // --- CollateralManager --- //

    /// @inheritdoc ICollateralManager
    function deposit(bytes32 subaccount, address depositToken, uint256 amount, bytes32 referralCode) external {
        _verifyNotPaused();
        bytes memory data =
            abi.encodeWithSelector(ICollateralManager.deposit.selector, subaccount, depositToken, amount, referralCode);
        _delegateCallCollateralManager(data);
    }

    /// @inheritdoc ICollateralManager
    function depositUsd(bytes32 subaccount, uint256 amount, bytes32 referralCode) external {
        _verifyNotPaused();
        bytes memory data =
            abi.encodeWithSelector(ICollateralManager.depositUsd.selector, subaccount, amount, referralCode);
        _delegateCallCollateralManager(data);
    }

    /// @inheritdoc ICollateralManager
    function depositOnBehalf(ICollateralManager.DepositOnBehalfRequest[] calldata params, bytes32 referralCode)
        external
    {
        _verifyNotPaused();
        _verifyOwnerOrDelegateDepositor();

        bytes memory data = abi.encodeWithSelector(ICollateralManager.depositOnBehalf.selector, params, referralCode);
        _delegateCallCollateralManager(data);
    }

    /// @inheritdoc ICollateralManager
    function finalizeWithdraw(address account, bytes32 digest) external payable {
        _verifyNotPaused();

        // Only allow the owner of the account, the claimer role or owner role to finalize the withdraw
        if (msg.sender != account && !Exchange.load().isClaimer[msg.sender] && msg.sender != owner()) {
            revert Unauthorized();
        }

        bytes memory data = abi.encodeWithSelector(ICollateralManager.finalizeWithdraw.selector, account, digest);
        _delegateCallCollateralManager(data);
    }

    /// @inheritdoc ICollateralManager
    function rescueFunds(address account, bytes32 digest) external payable onlyOwner {
        _verifyNotPaused();
        bytes memory data = abi.encodeWithSelector(ICollateralManager.rescueFunds.selector, account, digest);
        _delegateCallCollateralManager(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateRescueDelay(uint64 rescueDelay) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateRescueDelay.selector, rescueDelay);
        _delegateCallExchangeConfig(data);
    }

    /// @dev Callable by either `feeCollector` or the `owner` (on behalf of the feeCollector)
    function claimFees(address feeToken, uint256 amount) external {
        _verifyNotPaused();

        // Access only available only to the feeCollector and Owner
        if (msg.sender != FeeCollector.load().account && msg.sender != owner()) {
            revert Unauthorized();
        }

        bytes memory data = abi.encodeWithSelector(ICollateralManager.claimFees.selector, feeToken, amount);
        _delegateCallCollateralManager(data);
    }

    /// @dev Callable by either `feeCollector` or the `owner` (on behalf of the feeCollector)
    function convertFees(address fromToken, address toToken, uint256 amount) external {
        _verifyNotPaused();

        // Access only available only to the feeCollector and Owner
        if (msg.sender != FeeCollector.load().account && msg.sender != owner()) {
            revert Unauthorized();
        }

        bytes memory data = abi.encodeWithSelector(ICollateralManager.convertFees.selector, fromToken, toToken, amount);
        _delegateCallCollateralManager(data);
    }

    // --- Multicall --- //

    /// @inheritdoc IExchangeGateway
    function multicall(bytes[] calldata data) external onlyOwner returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                _revert(result);
            }
            results[i] = result;
        }
    }

    // --- AddressRegistry --- //

    /// @inheritdoc IExchangeGateway
    function updateRegistryRecord(bytes32 name, address record) external onlyOwner {
        if (
            name != ACTION_HANDLER_RECORD && name != COLLATERAL_MANAGER_RECORD && name != EXCHANGE_CONFIG_RECORD
                && name != LIQUIDATION_RECORD && name != DELEVERAGE_RECORD
                && name != DELEVERAGE_WITH_COMPENSATION_RECORD && name != PERP_ENGINE_RECORD
                && name != PERP_ENGINE_ADMIN_RECORD
        ) {
            revert InvalidRegistryRecord();
        }
        if (record.code.length == 0) {
            revert InvalidRegistryRecord();
        }

        AddressRegistry.Data storage registry = AddressRegistry.load();
        registry.records[name] = record;

        emit RegistryRecordUpdated(name, record);
    }

    // --- IActionHandler --- //

    /// @inheritdoc IActionHandler
    function processActions(bytes[] calldata actions) external payable {
        _verifyNotPaused();
        Exchange.load().onlySequencer(msg.sender);

        bytes memory data = abi.encodeWithSelector(IActionHandler.processActions.selector, actions);
        _delegateCallActionHandler(data);
    }

    /// @inheritdoc IActionHandler
    function processActionsDryRun(bytes[] calldata actions, uint256 minGasLeft) external payable {
        _verifyNotPaused();
        Exchange.load().onlySequencer(msg.sender);

        bytes memory data = abi.encodeWithSelector(IActionHandler.processActionsDryRun.selector, actions, minGasLeft);
        _delegateCallActionHandler(data);
    }

    /// @inheritdoc IActionHandler
    function finalizeRevokeLinkedSigner(IActionHandler.RevokeLinkedSignerMessage calldata message) external onlyOwner {
        _verifyNotPaused();
        bytes memory data = abi.encodeWithSelector(IActionHandler.finalizeRevokeLinkedSigner.selector, message);
        _delegateCallActionHandler(data);
    }

    // --- IExchangeConfig --- //

    /// @inheritdoc IExchangeConfig
    function addToken(bytes32 tokenName, address tokenAddress, address oftAddress, address backingToken)
        external
        onlyOwner
    {
        bytes memory data = abi.encodeWithSelector(
            IExchangeConfig.addToken.selector, tokenName, tokenAddress, oftAddress, backingToken
        );
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateActionExpiryBuffer(ActionType action, uint64 buffer) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateActionExpiryBuffer.selector, action, buffer);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateToken(IExchangeConfig.UpdateTokenParams calldata params) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateToken.selector, params);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function promoteToken(bytes32 tokenName, address tokenAddress, address oftAddress) external onlyOwner {
        bytes memory data =
            abi.encodeWithSelector(IExchangeConfig.promoteToken.selector, tokenName, tokenAddress, oftAddress);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function removeToken(bytes32 tokenName) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.removeToken.selector, tokenName);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function addSequencer(address sequencer) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.addSequencer.selector, sequencer);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function removeSequencer(address sequencer) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.removeSequencer.selector, sequencer);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateSequencerPaused(address sequencer, bool paused) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateSequencerPaused.selector, sequencer, paused);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateFeeCollector(address account, bytes32 subaccount) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateFeeCollector.selector, account, subaccount);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateLiquidator(address account, bytes32 subaccount) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateLiquidator.selector, account, subaccount);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateFeeSchedule(IExchangeConfig.UpdateFeeScheduleParams calldata params) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateFeeSchedule.selector, params);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function addFeeSchedule(IExchangeConfig.AddFeeScheduleParams calldata params) external onlyOwner returns (uint32) {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.addFeeSchedule.selector, params);
        return abi.decode(_delegateCallExchangeConfig(data), (uint32));
    }

    /// @inheritdoc IExchangeConfig
    function updatePythLazer(address updatedContract, uint64 updatedMaxAge) external onlyOwner {
        bytes memory data =
            abi.encodeWithSelector(IExchangeConfig.updatePythLazer.selector, updatedContract, updatedMaxAge);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateLzEndpointId(uint32 updatedEndpointId) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.updateLzEndpointId.selector, updatedEndpointId);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function addEmergencyPauser(address pauser) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.addEmergencyPauser.selector, pauser);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function removeEmergencyPauser(address pauser) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.removeEmergencyPauser.selector, pauser);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function addDelegateDepositor(address delegateDepositor) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.addDelegateDepositor.selector, delegateDepositor);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function removeDelegateDepositor(address delegateDepositor) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.removeDelegateDepositor.selector, delegateDepositor);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function updateDelegateDepositMaxBatchSize(uint16 maxDepositsPerBatch) external onlyOwner {
        bytes memory data =
            abi.encodeWithSelector(IExchangeConfig.updateDelegateDepositMaxBatchSize.selector, maxDepositsPerBatch);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function addClaimer(address claimer) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.addClaimer.selector, claimer);
        _delegateCallExchangeConfig(data);
    }

    /// @inheritdoc IExchangeConfig
    function removeClaimer(address claimer) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IExchangeConfig.removeClaimer.selector, claimer);
        _delegateCallExchangeConfig(data);
    }

    // --- PerpEngine --- //

    /// @inheritdoc IExchangeGateway
    function registerPerpProduct(IPerpEngine.RegisterPerpProductParams calldata params)
        external
        onlyOwner
        returns (uint32)
    {
        bytes memory data = abi.encodeWithSelector(IPerpEngineAdmin.register.selector, params);
        return abi.decode(_delegateCallPerpEngineAdmin(data), (uint32));
    }

    /// @inheritdoc IExchangeGateway
    function updatePerpProduct(IPerpEngine.UpdatePerpProductParams calldata params) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IPerpEngineAdmin.update.selector, params);
        _delegateCallPerpEngineAdmin(data);
    }

    /// @inheritdoc IExchangeGateway
    function updatePerpProductPythFeedId(uint32 productId, uint32 pythFeedId) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IPerpEngineAdmin.updatePythFeedId.selector, productId, pythFeedId);
        _delegateCallPerpEngineAdmin(data);
    }

    /// @inheritdoc IExchangeGateway
    function activatePerpProduct(uint32 productId) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IPerpEngineAdmin.activate.selector, productId);
        _delegateCallPerpEngineAdmin(data);
    }

    /// @inheritdoc IExchangeGateway
    function delistPerpProduct(uint32 productId) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(IPerpEngineAdmin.delist.selector, productId);
        _delegateCallPerpEngineAdmin(data);
    }

    // --- PerpsEngineViews --- //

    /// @inheritdoc IExchangeGateway
    function getPerpProduct(uint32 productId) external view returns (PerpProduct.Info memory) {
        PerpProduct.Data storage product = PerpProduct.load(productId);
        return PerpProduct.Info({
            id: product.id,
            feeScheduleId: product.feeScheduleId,
            status: product.status,
            maxLeverage: product.maxLeverage,
            pythFeedId: product.pythFeedId,
            cumulativeFundingUsd: product.cumulativeFundingUsd,
            baseTokenName: product.baseTokenName,
            quoteTokenName: product.quoteTokenName,
            maxQuantity: product.maxQuantity,
            tickSize: product.tickSize,
            lotSize: product.lotSize,
            openInterest: product.openInterest,
            maxOpenInterestUsd: product.maxOpenInterestUsd,
            maxPositionNotionalUsd: product.maxPositionNotionalUsd,
            delistExpiryPrice: product.delistExpiryPrice,
            delistInvoked: product.delistInvoked,
            delistMessageIdx: product.delistMessageIdx,
            cumulativePositionFeeUsd: product.cumulativePositionFeeUsd
        });
    }

    /// @inheritdoc IExchangeGateway
    function getPendingPerpProductUpdate(uint32 productId)
        external
        view
        returns (IPerpEngine.UpdatePerpProductParams memory)
    {
        return PerpProduct.loadPendingUpdate(productId);
    }

    /// @inheritdoc IExchangeGateway
    function getNextPerpProductId() external view returns (uint32) {
        return ProductRegistry.load().productIdCounter + 1;
    }

    /// @inheritdoc IExchangeGateway
    function getPerpPosition(address sender, bytes32 subaccount, uint32 productId)
        external
        view
        returns (PerpPosition.Data memory)
    {
        return PerpProduct.load(productId).positions[sender][subaccount];
    }

    // --- GatewayViews --- //

    /// @dev Naming convention for Data or Info struct of Storage: getStorage()
    /// @dev Naming convention for fieldName from Data struct of Storage: getStorageFieldName()
    /// @dev Naming convention for mappingName from Data struct of Storage: getStorageMappingName()

    /// @inheritdoc IExchangeGateway
    function getAccountBalance(address account, bytes32 subaccount, address token) external view returns (uint256) {
        return Account.load(account).balance[subaccount][token];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountHasRegistered(address account, bytes32 subaccount) external view returns (bool) {
        return Account.load(account).hasRegistered[subaccount];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountOpenPositions(address account, bytes32 subaccount) external view returns (uint128) {
        return Account.load(account).openPositions[subaccount];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountLinkedSigners(address account, bytes32 subaccount) external view returns (address[] memory) {
        return Account.load(account).linkedSigners[subaccount].values();
    }

    /// @inheritdoc IExchangeGateway
    function getAccountPendingDeposit(address account, bytes32 subaccount) external view returns (Deposit.Data memory) {
        return Account.load(account).pendingDeposit[subaccount];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountPendingWithdraw(address account, bytes32 withdrawDigest)
        external
        view
        returns (Withdraw.Data memory)
    {
        return Account.load(account).pendingWithdraw[withdrawDigest];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountRegisteredSubaccounts(address account) external view returns (uint32) {
        return Account.load(account).registeredSubaccounts;
    }

    /// @inheritdoc IExchangeGateway
    function getAccountGlobalLinkedSignersToAccount(address linkedSigner) external view returns (address) {
        return Account.load().linkedSignersToAccount[linkedSigner];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountGlobalUsdToken() external view returns (address) {
        return Account.load().usdToken;
    }

    /// @inheritdoc IExchangeGateway
    function getAccountGlobalTotalBalance(address token) external view returns (uint256) {
        return Account.load().totalBalance[token];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountGlobalTotalBackedBalance(address token) external view returns (uint256) {
        return Account.load().totalBackedBalance[token];
    }

    /// @inheritdoc IExchangeGateway
    function getAccountGlobalTotalPendingBalance(address token) external view returns (uint256) {
        return Account.load().totalPendingBalance[token];
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeActionExpiryBuffer(ActionType action) external view returns (uint64) {
        return Exchange.load().actionExpiryBuffers[action];
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeRescueDelay() external view returns (uint64) {
        return Exchange.load().rescueDelay;
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeLastPingTimestamp() external view returns (uint64) {
        return Exchange.load().lastPingTimestamp;
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeDelegateDepositMaxBatchSize() external view returns (uint16) {
        return Exchange.load().delegateDepositMaxBatchSize;
    }

    /// @inheritdoc IExchangeGateway
    function getExchangePythLazer() external view returns (address pythLazer, uint64 pythMaxAge) {
        Exchange.Data storage exchange = Exchange.load();
        pythLazer = exchange.pythLazer;
        pythMaxAge = exchange.pythMaxAge;
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeSequencer(address account) external view returns (bool isApproved, bool isPaused) {
        Exchange.Data storage exchange = Exchange.load();
        isApproved = exchange.isSequencerApproved[account];
        isPaused = exchange.isSequencerPaused[account];
    }

    /// @inheritdoc IExchangeGateway
    function getExchangeTokens() external view returns (bytes32[] memory) {
        return Exchange.load().tokens.values();
    }

    /// @inheritdoc IExchangeGateway
    function getFeeCollector() external view returns (address feeCollectorAccount, bytes32 feeCollectorSubaccount) {
        FeeCollector.Data storage feeCollector = FeeCollector.load();
        return (feeCollector.account, feeCollector.subaccount);
    }

    /// @inheritdoc IExchangeGateway
    function getFeeSchedule(uint32 feeScheduleId) external pure returns (FeeSchedule.Data memory) {
        return FeeSchedule.load(feeScheduleId);
    }

    /// @inheritdoc IExchangeGateway
    function getLiquidator() external view returns (address liquidatorAccount, bytes32 liquidatorSubaccount) {
        Liquidator.Data storage liquidator = Liquidator.load();
        return (liquidator.account, liquidator.subaccount);
    }

    /// @inheritdoc IExchangeGateway
    function getToken(bytes32 tokenName) external pure returns (Token.Data memory) {
        return Token.load(tokenName);
    }

    /// @inheritdoc IExchangeGateway
    function isDelegateDepositor(address delegateDepositor) external view returns (bool) {
        return Exchange.load().isDelegateDepositor[delegateDepositor];
    }

    /// @inheritdoc IExchangeGateway
    function isEmergencyPaused() external view returns (bool) {
        return Exchange.load().isPaused;
    }

    /// @inheritdoc IExchangeGateway
    function isEmergencyPauser(address account) external view returns (bool) {
        return Exchange.load().isEmergencyPauser[account];
    }

    /// @inheritdoc IExchangeGateway
    function isSequencerApproved(address sequencer) external view returns (bool) {
        return Exchange.load().isSequencerApproved[sequencer];
    }

    /// @inheritdoc IExchangeGateway
    function isClaimer(address claimer) external view returns (bool) {
        return Exchange.load().isClaimer[claimer];
    }

    // --- Helpers --- //

    function _verifyNotPaused() private view {
        if (Exchange.load().isPaused) {
            revert ExchangePaused();
        }
    }

    function _verifyOwnerOrDelegateDepositor() private view {
        if (owner() != msg.sender && !Exchange.load().isDelegateDepositor[msg.sender]) {
            revert Unauthorized();
        }
    }
}
