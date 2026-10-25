// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {HANDLE_VERSION} from "./Constants.sol";
import {FheType, Operator} from "./FheType.sol";
import {FHEEvents} from "./FHEEvents.sol";
import {IACL, PermissionType} from "./IACL.sol";
import {ICiphertextVerification} from "@primuslabs/spacebridge-contracts/contracts/interfaces/ICiphertextVerification.sol";
import {ISpaceBridgeConfig} from "@primuslabs/spacebridge-contracts/contracts/interfaces/ISpaceBridgeConfig.sol";
import {IDecryption} from "@primuslabs/spacebridge-contracts/contracts/interfaces/IDecryption.sol";
import {IFHEExecutor} from "./IFHEExecutor.sol";
import {IAlphatrionRewardSettlement, IFeeManager, IExecutorAdmin, IExecutorView} from "./IFHEExecutor.sol";

error LengthMismatch();
error ZeroAmount();
error ZeroAddress();
error TransferFailed();

/// @notice ConfigStorage
library ConfigStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.config")) - 1)) & ~bytes32(uint256(0xff));
    struct Layout {
        /// Mapping: block.chainid => protocol chain key
        mapping(uint256 => uint8) chainKeyOf;
        /// Settlement authority contract
        address alphatrionReward;
        /// CiphertextVerification contract
        ICiphertextVerification ciphertextVerification;
        /// SpaceBridgeConfig contract
        ISpaceBridgeConfig spaceBridgeConfig;
        /// IDecryption contract
        IDecryption decryption;
    }
    function l() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}

/// @notice PricingStorage
library PricingStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.pricing")) - 1)) & ~bytes32(uint256(0xff));

    struct Layout {
        /// Base cost per logical operator
        mapping(Operator => uint256) opBasePrice;
    }

    function l() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}

/// @notice FeeManagerStorage
library FeeManagerStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.fee.manager")) - 1)) & ~bytes32(uint256(0xff));
    struct Layout {
        /// User balance
        mapping(address user => uint256 balance) userBalance;
        /// Revenue accrued per user via _charge (available for distribution)
        mapping(address user => uint256 accrued) accruedRevenue;
        /// Handle => fee user for reward distribution validation
        mapping(bytes32 handle => address user) feeUserOf;
        /// Handle => fee actually charged for this handle (anchor for reward distribution amounts)
        mapping(bytes32 handle => uint256 paid) feePaidOf;
        /// Recipient => Native token credited when a push transfer fails (pull via FHEExecutor.claimReward)
        mapping(address recipient => uint256 claimable) claimableRewards;
    }
    // taskId --> revenue
    function l() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}

/// @notice ConfigLib
library ConfigLib {
    error InvalidChainId();
    error InvalidChainKey();
    error AlreadyExistChainKey(uint256 chainId, uint8 key);

    event ChainKeyUpdated(uint256 indexed chainId, uint8 key);
    event AlphatrionRewardUpdated(address oldAddr, address newAddr);
    event CiphertextVerificationUpdated(address oldAddr, address newAddr);
    event DecryptionUpdated(address oldAddr, address newAddr);
    event SpaceBridgeConfigUpdated(address oldAddr, address newAddr);

    /// @notice Initialize chainId => chainKey mapping
    /// @dev Keys are immutable once set
    function setChainKeys(uint256[] calldata chainIds, uint8[] calldata chainKeys) internal {
        ConfigStorage.Layout storage ec = ConfigStorage.l();
        if (chainIds.length != chainKeys.length) revert LengthMismatch();

        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];
            if (chainId == 0) revert InvalidChainId();
            uint8 key = chainKeys[i];
            if (key == 0) revert InvalidChainKey();

            uint8 oldKey = ec.chainKeyOf[chainId];
            if (oldKey != 0) revert AlreadyExistChainKey(chainId, oldKey);
            ec.chainKeyOf[chainId] = key;

            emit ChainKeyUpdated(chainId, key);
        }
    }

    function getChainKeys(uint256[] calldata chainIds) internal view returns (uint8[] memory chainKeys) {
        ConfigStorage.Layout storage ec = ConfigStorage.l();

        chainKeys = new uint8[](chainIds.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];
            chainKeys[i] = ec.chainKeyOf[chainId];
        }
    }

    /// @notice Set settlement bridge
    function setAlphatrionReward(address addr) internal {
        address oldAddr = ConfigStorage.l().alphatrionReward;
        ConfigStorage.l().alphatrionReward = addr;
        emit AlphatrionRewardUpdated(oldAddr, addr);
    }

    function setCiphertextVerification(address addr) internal {
        address oldAddr = address(ConfigStorage.l().ciphertextVerification);
        ConfigStorage.l().ciphertextVerification = ICiphertextVerification(addr);
        emit CiphertextVerificationUpdated(oldAddr, addr);
    }

    function setDecryption(address addr) internal {
        address oldAddr = address(ConfigStorage.l().decryption);
        ConfigStorage.l().decryption = IDecryption(addr);
        emit DecryptionUpdated(oldAddr, addr);
    }

    function setSpaceBridgeConfig(address addr) internal {
        address oldAddr = address(ConfigStorage.l().spaceBridgeConfig);
        ConfigStorage.l().spaceBridgeConfig = ISpaceBridgeConfig(addr);
        emit SpaceBridgeConfigUpdated(oldAddr, addr);
    }
}

/// @notice PricingLib
library PricingLib {
    error ZeroBasePrice();

    event OpBasePriceUpdated(Operator indexed op, uint256 oldPrice, uint256 newPrice);
    event AssetRateUpdated(address indexed token, uint256 oldRate, uint256 newRate);

    struct OpPrice {
        Operator op;
        uint256 price;
    }

    function setOpBasePrices(Operator[] calldata ops, uint256[] calldata prices) internal {
        PricingStorage.Layout storage ps = PricingStorage.l();
        if (ops.length != prices.length) revert LengthMismatch();

        for (uint256 i = 0; i < ops.length; i++) {
            if (prices[i] == 0) revert ZeroBasePrice();

            uint256 old = ps.opBasePrice[ops[i]];
            ps.opBasePrice[ops[i]] = prices[i];

            emit OpBasePriceUpdated(ops[i], old, prices[i]);
        }
    }

    function getAllOpPrices() internal view returns (PricingLib.OpPrice[] memory list) {
        uint256 len = uint256(type(Operator).max) + 1;

        PricingStorage.Layout storage ps = PricingStorage.l();

        list = new OpPrice[](len);
        for (uint256 i = 0; i < len; i++) {
            list[i] = OpPrice({op: Operator(i), price: ps.opBasePrice[Operator(i)]});
        }
    }
}

/// @notice FeeManagerLib
library FeeManagerLib {
    /* ---------------- Constants ---------------- */
    /// Transient storage key for per-tx asset lock
    bytes32 private constant TS_ACTIVE_USER = keccak256("TS_ACTIVE_USER");

    /* ---------------- Errors ---------------- */
    error UserLockedInTx();
    error UserNotInitializedInTx();
    error UserAlreadyInitializedInTx();
    error InvalidBasePrice();
    error InsufficientBalance();
    error UnauthorizedFeeUser();

    /* ---------------- Events ---------------- */
    /// @notice Emitted when a user charge ETH to the contract
    event FeeCharged(address indexed user, uint256 amount);
    /// @notice Emitted when ETH is refunded to a user
    event FeeRefunded(address indexed user, uint256 amount);
    /// @notice Emitted when revenue is accrued for an operation
    event RevenueAccrued(address indexed user, address indexed token, uint256 amount, bytes32 handle);

    /// @notice Charge ETH to the user's fee balance
    /// @dev Ensures user is not locked in current tx
    function chargeFee(address user) internal {
        uint256 amount = msg.value;
        if (amount == 0) revert ZeroAmount();
        if (user == address(0)) revert ZeroAddress();
        // Only the user themself (directly or via a dApp contract in the same tx) may be
        // locked as the fee payer. Prevents locking an arbitrary victim's prepaid balance.
        if (user != msg.sender && user != tx.origin) revert UnauthorizedFeeUser();

        _assertUserNotLockedInTx();
        _storeUserInTx(user);

        FeeManagerStorage.l().userBalance[user] += amount;

        emit FeeCharged(user, amount);
    }

    /// @notice Refund ETH to the user
    /// @dev Ensures user is not locked and has sufficient balance
    function refundFee(address user, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        if (user == address(0)) revert ZeroAddress();

        _assertUserNotLockedInTx();

        FeeManagerStorage.Layout storage fm = FeeManagerStorage.l();
        uint256 bal = fm.userBalance[user];
        if (amount > bal) revert InsufficientBalance();

        fm.userBalance[user] = bal - amount;

        (bool ok, ) = user.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit FeeRefunded(user, amount);
    }

    /// @notice Returns the current fee balance of a user
    function balanceOfFee(address user) internal view returns (uint256) {
        return FeeManagerStorage.l().userBalance[user];
    }

    /// @notice Charge user for an operator execution
    function charge(Operator op, bytes32 handle) internal {
        address user = _loadUserInTx();

        FeeManagerStorage.Layout storage fm = FeeManagerStorage.l();
        PricingStorage.Layout storage ps = PricingStorage.l();

        uint256 basePrice = ps.opBasePrice[op];
        if (basePrice == 0) revert InvalidBasePrice();

        uint256 bal = fm.userBalance[user];
        if (bal < basePrice) revert InsufficientBalance();

        fm.userBalance[user] = bal - basePrice;
        fm.accruedRevenue[user] += basePrice;
        fm.feeUserOf[handle] = user;
        fm.feePaidOf[handle] += basePrice;

        emit RevenueAccrued(user, address(0), basePrice, handle);
    }

    /// -------------------------------------------------------
    /// Internal Transaction Helpers
    /// -------------------------------------------------------
    /// @dev Ensures no user is locked in current transaction
    function _assertUserNotLockedInTx() internal view {
        bytes32 key = TS_ACTIVE_USER;
        bytes32 locked;
        assembly {
            locked := tload(key)
        }
        if (locked != bytes32(0)) revert UserLockedInTx();
    }
    /// @dev Stores the active user in transient storage for the current transaction
    function _storeUserInTx(address user) internal {
        bytes32 key = TS_ACTIVE_USER;
        bytes32 locked;
        assembly {
            locked := tload(key)
        }
        if (locked != 0) revert UserAlreadyInitializedInTx();

        bytes32 current = bytes32(uint256(uint160(user)));
        assembly {
            tstore(key, current)
        }
    }
    /// @dev Loads the active user stored in transient storage
    function _loadUserInTx() internal view returns (address user) {
        bytes32 key = TS_ACTIVE_USER;
        bytes32 locked;
        assembly {
            locked := tload(key)
        }
        if (locked == bytes32(0)) revert UserNotInitializedInTx();

        user = address(uint160(uint256(locked)));
    }
}

/// @notice AlphatrionRewardSettlementLib
library AlphatrionRewardSettlementLib {
    error InvalidToken(address token);
    error InsufficientAccruedRevenue();
    event RevenueDistributed(address indexed user, address indexed token, address recipient, uint256 amount);
    /// @notice Emitted when a push transfer fails and the amount is credited as claimable instead (audit N3).
    event RevenuePushFailed(address indexed user, address indexed recipient, uint256 amount);

    /// @notice Distribute accrued revenue
    function distributeRevenue(address user, address token, address[] calldata recipients, uint256[] calldata amounts) internal {
        if (user == address(0)) revert ZeroAddress();
        if (token != address(0)) revert InvalidToken(token);
        if (recipients.length != amounts.length) revert LengthMismatch();

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        if (total == 0) revert ZeroAmount();

        FeeManagerStorage.Layout storage fm = FeeManagerStorage.l();
        uint256 accrued = fm.accruedRevenue[user];
        if (total > accrued) revert InsufficientAccruedRevenue();
        fm.accruedRevenue[user] = accrued - total;

        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            uint256 amt = amounts[i];

            if (amt == 0) continue;
            // if (amt == 0) revert ZeroAmount();
            if (to == address(0)) revert ZeroAddress();

            (bool ok, ) = to.call{value: amt}("");
            if (!ok) {
                // Isolate the failed transfer: credit it as a claimable balance
                // (pull via FHEExecutor.claimReward) instead of reverting the
                // whole batch, so one reverting recipient cannot block every
                // other participant's settlement (audit N3).
                fm.claimableRewards[to] += amt;
                emit RevenuePushFailed(user, to, amt);
                continue;
            }

            emit RevenueDistributed(user, token, to, amt);
        }
    }
}

/**
 * @notice This contract implements symbolic execution on the blockchain.
 */
contract FHEExecutor is OwnableUpgradeable, ReentrancyGuardTransient, IFHEExecutor, FHEEvents, IAlphatrionRewardSettlement, IFeeManager, IExecutorAdmin, IExecutorView {
    /// @notice Returned when the handle is not allowed in the ACL for the account.
    error ACLNotAllowed(bytes32 handle, address account);
    /// @notice Returned when the FHE operator attempts to divide by zero.
    error DivisionByZero();
    /// @notice Returned if two types are not compatible for this operation.
    error IncompatibleTypes();
    /// @notice Returned if the type is not the expected one.
    error InvalidType();
    /// @notice Returned if operation is supported only for a scalar (functions fheDiv/fheRem).
    error IsNotScalar();
    /// @notice Returned if the type is not supported for this operation.
    error UnsupportedType();
    /// @notice Returned when the input handle with invalid signature
    error InvalidHandleSignature(bytes32 handle, address user);

    event ACLUpdated(address oldAddr, address newAddr);

    string private constant CONTRACT_NAME = "FHEExecutor";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 2;

    IACL private acl;
    /// @dev Deprecated storage slot. Kept for storage compatibility. (DO NOT USE)
    address private __deprecated_primusZKTLS;
    uint256 private counter;
    uint256[10] internal __gap;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    error NotAlphatrionReward();
    modifier onlyAlphatrionReward() {
        require(ConfigStorage.l().alphatrionReward != address(0), "AlphatrionReward cannot be zero.");
        if (msg.sender != ConfigStorage.l().alphatrionReward) revert NotAlphatrionReward();
        _;
    }

    /**
     * @notice Initializes the contract.
     */
    function initialize(address owner) public initializer {
        require(owner != address(0), "Owner cannot be zero");

        __Ownable_init(owner);
    }

    /**
     * @param addr The ACL address
     */
    function setACL(address addr) external onlyOwner {
        require(addr != address(0), "ACL cannot be zero");
        address oldAddr = address(acl);
        acl = IACL(addr);
        emit ACLUpdated(oldAddr, addr);
    }
    function getACLAddress() public view virtual returns (address) {
        return address(acl);
    }

    function setChainKeys(uint256[] calldata chainIds, uint8[] calldata chainKeys) external onlyOwner {
        ConfigLib.setChainKeys(chainIds, chainKeys);
    }
    function getChainKeys(uint256[] calldata chainIds) public view returns (uint8[] memory chainKeys) {
        chainKeys = ConfigLib.getChainKeys(chainIds);
    }

    function setAlphatrionReward(address _alphatrionReward) external onlyOwner {
        require(_alphatrionReward != address(0), "AlphatrionReward address cannot be zero");
        ConfigLib.setAlphatrionReward(_alphatrionReward);
    }
    function getAlphatrionRewardAddress() public view returns (address) {
        return ConfigStorage.l().alphatrionReward;
    }

    function setCiphertextVerification(address _ciphertextVerification) external onlyOwner {
        require(_ciphertextVerification != address(0), "CiphertextVerification address cannot be zero");
        ConfigLib.setCiphertextVerification(_ciphertextVerification);
    }
    function getCiphertextVerificationAddress() public view returns (address) {
        return address(ConfigStorage.l().ciphertextVerification);
    }

    function setDecryption(address _decryption) external onlyOwner {
        require(_decryption != address(0), "Decryption address cannot be zero");
        ConfigLib.setDecryption(_decryption);
    }
    function getDecryptionAddress() public view returns (address) {
        return address(ConfigStorage.l().decryption);
    }

    function setSpaceBridgeConfig(address _spaceBridgeConfig) external onlyOwner {
        require(_spaceBridgeConfig != address(0), "SpaceBridgeConfig address cannot be zero");
        ConfigLib.setSpaceBridgeConfig(_spaceBridgeConfig);
    }
    function getSpaceBridgeConfigAddress() public view returns (address) {
        return address(ConfigStorage.l().spaceBridgeConfig);
    }

    function setOpBasePrices(Operator[] calldata ops, uint256[] calldata prices) external onlyOwner {
        PricingLib.setOpBasePrices(ops, prices);
    }
    function getAllOpPrices() external view returns (PricingLib.OpPrice[] memory list) {
        list = PricingLib.getAllOpPrices();
    }

    function next() internal returns (uint256) {
        counter += 1;
        return counter;
    }

    function fheAdd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheAdd, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheAdd, result);
        emit FheAdd(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheSub(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheSub, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheSub, result);
        emit FheSub(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheMul(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheMul, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheMul, result);
        emit FheMul(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheDiv(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        /// @dev rhs must be scalar
        if (scalarByte & 0x01 != 0x01) revert IsNotScalar();
        if (rhs == 0) revert DivisionByZero();

        uint256 supportedTypes = _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheDiv, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheDiv, result);
        emit FheDiv(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheBitAnd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheBitAnd, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheBitAnd, result);
        emit FheBitAnd(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheBitOr(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheBitOr, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheBitOr, result);
        emit FheBitOr(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheBitXor(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        FheType lhsType = _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheBitXor, lhs, rhs, scalar, lhsType);
        _charge(Operator.fheBitXor, result);
        emit FheBitXor(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheBitNot(bytes32 lhs) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        result = _unaryOp(Operator.fheBitNot, lhs);
        _charge(Operator.fheBitNot, result);
        emit FheBitNot(msg.sender, lhs, result);
    }

    function fheEq(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheEq, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheEq, result);
        emit FheEq(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheNe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheNe, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheNe, result);
        emit FheNe(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheGe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheGe, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheGe, result);
        emit FheGe(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheGt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheGt, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheGt, result);
        emit FheGt(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheLe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheLe, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheLe, result);
        emit FheLe(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheLt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) public virtual returns (bytes32 result) {
        uint256 supportedTypes = _supportedU8toU256();
        _verifyAndReturnType(lhs, supportedTypes);
        bytes1 scalar = scalarByte & 0x01;
        result = _binaryOp(Operator.fheLt, lhs, rhs, scalar, FheType.Bool);
        _charge(Operator.fheLt, result);
        emit FheLt(msg.sender, lhs, rhs, scalarByte, result);
    }

    function fheIfThenElse(bytes32 control, bytes32 ifTrue, bytes32 ifFalse) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        _verifyAndReturnType(ifTrue, supportedTypes);
        result = _ternaryOp(Operator.fheIfThenElse, control, ifTrue, ifFalse);
        _charge(Operator.fheIfThenElse, result);
        emit FheIfThenElse(msg.sender, control, ifTrue, ifFalse, result);
    }

    function trivialEncrypt(uint256 pt, FheType toType) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        if ((1 << uint8(toType)) & supportedTypes == 0) revert UnsupportedType();
        result = keccak256(abi.encodePacked(Operator.trivialEncrypt, pt, toType, acl, block.chainid, next()));
        result = _appendMetadataToPrehandle(result, toType, Operator.trivialEncrypt);
        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
        emit TrivialEncrypt(msg.sender, pt, toType, result);
    }

    function verifyAttestation(
        bytes32 inputHandle,
        address userAddress,
        bytes memory inputData,
        FheType inputType
    ) public virtual returns (bytes32 result) {
        _validateInputHandle(inputHandle, inputType);

        require(address(ConfigStorage.l().ciphertextVerification) != address(0), "CiphertextVerification cannot be zero.");
        ConfigStorage.l().ciphertextVerification.verifyInput(userAddress, msg.sender, inputHandle, inputData);
        result = inputHandle;

        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
        emit VerifyAttestation(msg.sender, userAddress, inputHandle, inputType, inputData, result);
    }

    /**
     * @notice Casts an encrypted integer `ct` to the target type `toType`, producing a new handle.
     * @dev Type-width conversion between encrypted integer types (e.g. Uint64 -> Uint128).  
     */
    function fheCast(bytes32 ct, FheType toType) public virtual returns (bytes32 result) {
        uint256 supportedTypes = (1 << uint8(FheType.Bool)) + _supportedU8toU256();
        // Source must be a supported encrypted type.
        _verifyAndReturnType(ct, supportedTypes);
        // Target must be a supported encrypted type.
        if ((1 << uint8(toType)) & supportedTypes == 0) revert UnsupportedType();
        result = _castOp(ct, toType);
        _charge(Operator.fheCast, result);
        emit FheCast(msg.sender, ct, toType, result);
    }

    /**
     * @notice Getter for the handle version.
     */
    function getHandleVersion() external pure virtual returns (uint8) {
        return HANDLE_VERSION;
    }

    /**
     * @notice Getter for the name and version of the contract.
     */
    function getVersion() external pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    CONTRACT_NAME,
                    " v",
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }

    function _supportedU8toU256() internal pure returns (uint256) {
        return
            (1 << uint8(FheType.Uint8)) +
            (1 << uint8(FheType.Uint16)) +
            (1 << uint8(FheType.Uint32)) +
            (1 << uint8(FheType.Uint64)) +
            (1 << uint8(FheType.Uint128)) +
            (1 << uint8(FheType.Uint256));
    }

    /**
     * @notice handle[30]
     */
    function _typeOf(bytes32 handle) internal pure virtual returns (FheType typeCt) {
        typeCt = FheType(uint8(handle[30]));
    }

    function _verifyAndReturnType(bytes32 handle, uint256 supportedTypes) internal pure virtual returns (FheType typeCt) {
        typeCt = _typeOf(handle);
        if ((1 << uint8(typeCt)) & supportedTypes == 0) revert UnsupportedType();
    }

    function _appendMetadataToPrehandle(bytes32 prehandle, FheType handleType, Operator op) internal view virtual returns (bytes32 result) {
        uint8 chainKey = ConfigStorage.l().chainKeyOf[block.chainid];
        require(chainKey != 0, "Unsupported chain key");

        /// @dev Clear bytes 20-31.
        result = prehandle & 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;
        /// @dev Set byte 20-27 to block number (cast to uint64 first before shifting).
        result = result | (bytes32(uint256(uint64(block.number))) << 32);
        /// @dev Set byte 28 to chain key which mapping to chain id.
        result = result | (bytes32(uint256(chainKey)) << 24);
        /// @dev Insert opType into byte 29.
        result = result | (bytes32(uint256(uint8(op))) << 16);
        /// @dev Insert handleType into byte 30.
        result = result | (bytes32(uint256(uint8(handleType))) << 8);
        /// @dev Set byte 31 to the packed of source(3bits) and HANDLE_VERSION(5bits).
        ///   source:
        ///     000b: the new handle comes from off-chain.
        ///     001b: the new handle comes from computation.
        uint8 packed = (0x1 << 5) | (HANDLE_VERSION & 0x1f);
        result = result | bytes32(uint256(packed));
    }

    function _validateInputHandle(bytes32 inputHandle, FheType inputType) internal view {
        FheType typeCt = _typeOf(inputHandle);
        if (inputType != typeCt) revert InvalidType();

        uint8 chainKey = ConfigStorage.l().chainKeyOf[block.chainid];
        require(uint8(inputHandle[28]) == chainKey, "inputHandle with invalid chain key");
    }

    function _unaryOp(Operator op, bytes32 lhs) internal virtual returns (bytes32 result) {
        if (!acl.isAllowed(lhs, msg.sender)) revert ACLNotAllowed(lhs, msg.sender);
        result = keccak256(abi.encodePacked(op, lhs, acl, block.chainid, next()));
        FheType lhsType = _typeOf(lhs);
        result = _appendMetadataToPrehandle(result, lhsType, op);
        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
    }

    function _castOp(bytes32 ct, FheType toType) internal virtual returns (bytes32 result) {
        if (!acl.isAllowed(ct, msg.sender)) revert ACLNotAllowed(ct, msg.sender);
        result = keccak256(abi.encodePacked(Operator.fheCast, ct, toType, acl, block.chainid, next()));
        result = _appendMetadataToPrehandle(result, toType, Operator.fheCast);
        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
    }

    function _binaryOp(Operator op, bytes32 lhs, bytes32 rhs, bytes1 scalar, FheType resultType) internal virtual returns (bytes32 result) {
        if (!acl.isAllowed(lhs, msg.sender)) revert ACLNotAllowed(lhs, msg.sender);
        if (scalar == 0x00) {
            if (!acl.isAllowed(rhs, msg.sender)) revert ACLNotAllowed(rhs, msg.sender);

            FheType rhsType = _typeOf(rhs);
            FheType lhsType = _typeOf(lhs);
            if (lhsType != rhsType) revert IncompatibleTypes();
        }
        result = keccak256(abi.encodePacked(op, lhs, rhs, scalar, acl, block.chainid, next()));
        result = _appendMetadataToPrehandle(result, resultType, op);
        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
    }

    function _ternaryOp(Operator op, bytes32 lhs, bytes32 middle, bytes32 rhs) internal virtual returns (bytes32 result) {
        if (!acl.isAllowed(lhs, msg.sender)) revert ACLNotAllowed(lhs, msg.sender);
        if (!acl.isAllowed(middle, msg.sender)) revert ACLNotAllowed(middle, msg.sender);
        if (!acl.isAllowed(rhs, msg.sender)) revert ACLNotAllowed(rhs, msg.sender);

        FheType lhsType = _typeOf(lhs);
        FheType middleType = _typeOf(middle);
        FheType rhsType = _typeOf(rhs);

        /// @dev lhs must be ve_bool
        if (lhsType != FheType.Bool) revert UnsupportedType();
        if (middleType != rhsType) revert IncompatibleTypes();

        result = keccak256(abi.encodePacked(op, lhs, middle, rhs, acl, block.chainid, next()));
        result = _appendMetadataToPrehandle(result, middleType, op);
        acl.accessPolicy(result, msg.sender, PermissionType.Transient);
    }

    /*//////////////////////////////////////////////////////////////
                             FEE
    //////////////////////////////////////////////////////////////*/
    function chargeFee(address user) external payable {
        FeeManagerLib.chargeFee(user);
    }
    // DISABLED
    // function refundFee(address user, uint256 amount) external {
    //     FeeManagerLib.refundFee(user, amount);
    // }
    // function balanceOfFee(address user) external view returns (uint256) {
    //     return FeeManagerLib.balanceOfFee(user);
    // }
    /*//////////////////////////////////////////////////////////////
                            CHARGE
    //////////////////////////////////////////////////////////////*/
    function _charge(Operator op, bytes32 handle) internal {
        FeeManagerLib.charge(op, handle);
    }

    /*//////////////////////////////////////////////////////////////
                        DISTRIBUTE REVENUE
    //////////////////////////////////////////////////////////////*/
    function distributeRevenue(address user, address token, address[] calldata recipients, uint256[] calldata amounts) external onlyAlphatrionReward {
        AlphatrionRewardSettlementLib.distributeRevenue(user, token, recipients, amounts);
    }

    /// @notice Emitted when a recipient pulls rewards that a previous push transfer failed to deliver.
    event RewardClaimed(address indexed recipient, uint256 amount);

    /// @notice Claim rewards that were credited after a failed push transfer (audit N3).
    /// @dev The balance is zeroed before the external call (CEI). If the call still
    ///      fails (e.g. the caller is a contract that keeps reverting), the balance
    ///      is restored so it can be retried later.
    function claimReward() external nonReentrant {
        FeeManagerStorage.Layout storage fm = FeeManagerStorage.l();
        uint256 amt = fm.claimableRewards[msg.sender];
        if (amt == 0) revert ZeroAmount();
        fm.claimableRewards[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amt}("");
        if (!ok) {
            fm.claimableRewards[msg.sender] = amt;
            revert TransferFailed();
        }
        emit RewardClaimed(msg.sender, amt);
    }

    /// @notice Returns the claimable reward balance of an account.
    function getClaimableReward(address account) external view returns (uint256) {
        return FeeManagerStorage.l().claimableRewards[account];
    }

    /// @notice Returns the fee user for a given ciphertext handle.
    function getFeeUserOf(bytes32 handle) external view returns (address) {
        return FeeManagerStorage.l().feeUserOf[handle];
    }

    /// @notice Returns the total fee actually charged for a given ciphertext handle.
    function getFeePaidOf(bytes32 handle) external view returns (uint256) {
        return FeeManagerStorage.l().feePaidOf[handle];
    }

    // function cleanTransientStorage() external virtual {
    //     acl.cleanTransientStorage();
    // }
}
