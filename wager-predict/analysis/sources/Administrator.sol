// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {IRole} from "../interfaces/IRole.sol";
import {IBlackList} from "../interfaces/IBlackList.sol";
import {ITimeLock} from "../interfaces/ITimeLock.sol";
import {Roles} from "../libraries/Roles.sol";
import {AddressLib} from "../libraries/AddressLib.sol";
import {MathLib} from "../libraries/MathLib.sol";
import {Errors} from "../libraries/Errors.sol";
import {Constants} from "../libraries/Constants.sol";

/**
 * @title Administrator
 * @notice Central administration contract for role, global pause, blacklist management, timelock, and proxy upgrades
 * @dev Implements IRole, IBlackList, and ITimeLock interfaces
 * @dev Does not replace OpenZeppelin `ProxyAdmin`. After deploy, each per-proxy `ProxyAdmin`
 *      must be owned by this contract so `OP_CONTRACT_UPGRADE` can call `upgradeAndCall`.
 * @dev Production timelock delays apply after `activateProductionTimelocks`; `initialize` starts at zero delay for deployment wiring
 * @dev Global pause, blacklist, and timelock operations require GOVERNOR_ROLE
 * @dev removeFromBlackList includes user existence check to prevent unnecessary state changes
 */
contract Administrator is IRole, IBlackList, ITimeLock, Ownable2StepUpgradeable {
    using AddressLib for address;
    using MathLib for uint256;

    // ═══════════════════════════════════════════════════════════════════
    //                          STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Role assignments: role => account => hasRole
    /// @dev key: role (bytes32 role identifier), nested key: account (address), value: hasRole (bool)
    mapping(bytes32 role => mapping(address account => bool hasRole)) private _roles;

    /// @notice Blacklist status per address
    struct BlacklistEntry {
        bool active;
        uint8 reason; // Constants.BLACKLIST_REASON_* (0–3) when active
    }

    /// @notice Blacklisted addresses and reason codes
    /// @dev key: account (address), value: BlacklistEntry
    mapping(address account => BlacklistEntry entry) private _blacklist;

    /// @notice Global pause flag (pauses all contracts)
    bool private _globalPause;

    // ═══════════════════════════════════════════════════════════════════
    //                       TIMELOCK STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Timelock delay per operation type in seconds
    /// @dev key: operationType (bytes32), value: delay (seconds)
    mapping(bytes32 operationType => uint256 delay) private _timelockDelayByOperationType;

    /// @notice Struct to store operation details
    struct Operation {
        address target; // Target contract address
        bytes32 operationType; // Operation type used when scheduling
        bytes data; // Calldata for the operation
        uint256 readyTime; // Timestamp when operation becomes ready
        uint256 expiryTime; // Timestamp when operation expires
    }

    /// @notice Scheduled operations mapping
    /// @dev key: operationId (bytes32), value: Operation struct
    mapping(bytes32 operationId => Operation) private _operations;

    // ═══════════════════════════════════════════════════════════════════
    //                         STORAGE GAP
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @dev Storage gap for future upgrades
     * CRITICAL: Update gap when adding/removing state variables
     * Current storage:
     * - Ownable2StepUpgradeable: 2 slots (owner, pendingOwner)
     * - _roles: 1 slot (mapping)
     * - _blacklist: 1 slot (mapping)
     * - _globalPause: 1 slot (bool)
     * - _timelockDelayByOperationType: 1 slot (mapping)
     * - _operations: 1 slot (mapping)
     * Total: 7 slots used
     * Gap: 72 - 7 = 65 slots remaining
     * Note: _gap follows OpenZeppelin's standard pattern for upgradeable contracts
     * Note: Constants (MIN/MAX_TIMELOCK_DELAY, TIMELOCK_* delays, OPERATION_EXPIRY_WINDOW) do not use storage slots
     */
    uint256[65] private __gap;

    // ═══════════════════════════════════════════════════════════════════
    //                             EVENTS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Emitted when global pause is activated
    event GlobalPauseActivated(address indexed caller);

    /// @notice Emitted when global pause is deactivated
    event GlobalPauseDeactivated(address indexed caller);

    /// @notice Emitted when deployment zero-delay timelocks are replaced with production delays
    event ProductionTimelocksActivated(address indexed governor);

    // ═══════════════════════════════════════════════════════════════════
    //                             ERRORS
    // ═══════════════════════════════════════════════════════════════════
    // All errors are defined in Errors.sol library

    // ═══════════════════════════════════════════════════════════════════
    //                            MODIFIERS
    // ═══════════════════════════════════════════════════════════════════

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    modifier onlyOperator() {
        _onlyOperator();
        _;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Disable initializer for implementation contract
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the Administrator contract
     * @param owner_ Initial owner address
     */
    function initialize(
        address owner_
    ) external initializer {
        owner_.requireNonZero();

        // Initialize Ownable2Step with owner
        __Ownable_init(owner_);
        __Ownable2Step_init();

        // Bootstrap governance roles for the owner (subsequent grants require timelock)
        _grantRole(Roles.GOVERNOR_ROLE, owner_, address(this));
        _grantRole(Roles.OPERATOR_ROLE, owner_, address(this));

        // Initialize per-operation-type timelock delays
        _timelockDelayByOperationType[Constants.OP_GRANT_ROLE] = Constants.ZERO_TIMELOCK_DELAY;
        _timelockDelayByOperationType[Constants.OP_CONTRACT_UPGRADE] = Constants.ZERO_TIMELOCK_DELAY;
        _timelockDelayByOperationType[Constants.OP_PARAMETER_CHANGE] = Constants.ZERO_TIMELOCK_DELAY;
        _timelockDelayByOperationType[Constants.OP_OWNERSHIP_TRANSFER] = Constants.ZERO_TIMELOCK_DELAY;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      INTERNAL VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    function _onlyGovernor() internal view {
        if (!hasRole(Roles.GOVERNOR_ROLE, msg.sender)) {
            revert Errors.Unauthorized(msg.sender, Roles.GOVERNOR_ROLE);
        }
    }

    function _onlyOperator() internal view {
        if (!hasRole(Roles.OPERATOR_ROLE, msg.sender)) {
            revert Errors.Unauthorized(msg.sender, Roles.OPERATOR_ROLE);
        }
    }

    function _timelockDelayFor(bytes32 operationType) internal view returns (uint256 delay) {
        delay = _timelockDelayByOperationType[operationType];
        if (delay == 0) {
            delay = _timelockDelayByOperationType[Constants.OP_PARAMETER_CHANGE];
        }
    }

    function _isDeploymentTimelockPhase() internal view returns (bool) {
        return _timelockDelayByOperationType[Constants.OP_PARAMETER_CHANGE] == Constants.ZERO_TIMELOCK_DELAY;
    }

    function _grantRole(bytes32 role, address account, address sender) internal {
        account.requireNonZero();

        if (_roles[role][account]) revert Errors.RoleAlreadyGranted();

        _roles[role][account] = true;
        emit RoleGranted(role, account, sender);
    }

    function _validateBlackListReason(uint8 reason) internal pure {
        if (reason > Constants.BLACKLIST_REASON_OTHER) {
            revert Errors.InvalidBlacklistReason(reason);
        }
    }

    function _addToBlackList(address user, uint8 reason) internal {
        _validateBlackListReason(reason);
        _blacklist[user] = BlacklistEntry({active: true, reason: reason});
        emit AddressBlacklisted(user, msg.sender, reason);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      EXTERNAL VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Check if an account has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return hasRole True if account has the role
     */
    function hasRole(
        bytes32 role,
        address account
    ) public view override returns (bool) {
        return _roles[role][account];
    }


    /**
     * @notice Check if global pause is active
     * @return paused True if globally paused
     */
    function isGloballyPaused() external view returns (bool paused) {
        return _globalPause;
    }

    /**
     * @notice Check if an address is blacklisted
     * @param user The address to check
     * @return blacklisted True if the address is blacklisted
     */
    function isBlackListed(
        address user
    ) external view override returns (bool blacklisted) {
        return _blacklist[user].active;
    }

    /**
     * @notice Get the blacklist reason for an address
     * @param user The address to check
     * @return reason Reason code (`Constants.BLACKLIST_REASON_*`)
     */
    function getBlackListReason(address user) external view override returns (uint8 reason) {
        BlacklistEntry storage entry = _blacklist[user];
        if (!entry.active) {
            revert Errors.BlacklistReasonNotSet(user);
        }
        return entry.reason;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      TIMELOCK VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Get the timelock delay for the default operation type
     * @return delay The timelock delay in seconds
     */
    function getTimelockDelay() external view override returns (uint256 delay) {
        return _timelockDelayFor(Constants.OP_PARAMETER_CHANGE);
    }

    /**
     * @notice Get the timelock delay for a specific operation type
     * @param operationType The operation type identifier
     * @return delay The timelock delay in seconds
     */
    function getTimelockDelay(bytes32 operationType) external view returns (uint256 delay) {
        return _timelockDelayFor(operationType);
    }

    /**
     * @notice Check if an operation is currently scheduled and still actionable
     * @dev Returns false for entries past `expiryTime` even if they remain in storage.
     *      Governors may call `cancelOperation` to clear stale entries.
     * @param operationId The operation identifier
     * @return scheduled True if the operation exists AND is not yet expired
     */
    function isOperationScheduled(
        bytes32 operationId
    ) public view override returns (bool scheduled) {
        Operation storage op = _operations[operationId];
        return op.target != address(0) && block.timestamp <= op.expiryTime;
    }

    /**
     * @notice Check if an operation is ready for execution
     * @param operationId The operation identifier
     * @return ready True if the operation is ready
     */
    function isOperationReady(
        bytes32 operationId
    ) public view override returns (bool ready) {
        Operation storage op = _operations[operationId];
        return
            op.target != address(0) &&
            block.timestamp >= op.readyTime &&
            block.timestamp <= op.expiryTime;
    }

    /**
     * @notice Get operation details
     * @param operationId The operation identifier
     * @return target The target contract address
     * @return operationType The operation type used when scheduling
     * @return data The calldata for the operation
     * @return readyTime The timestamp when operation becomes ready
     * @return expiryTime The timestamp when operation expires
     */
    function getOperation(
        bytes32 operationId
    )
        external
        view
        override
        returns (
            address target,
            bytes32 operationType,
            bytes memory data,
            uint256 readyTime,
            uint256 expiryTime
        )
    {
        Operation storage op = _operations[operationId];
        return (op.target, op.operationType, op.data, op.readyTime, op.expiryTime);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      INTERNAL WRITE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    // (No internal write functions currently)

    // ═══════════════════════════════════════════════════════════════════
    //                      EXTERNAL WRITE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Grant a role to an account
     * @param role The role to grant
     * @param account The account to grant role to
     * @dev Callable only via timelock execution (`executeOperation` self-call). Revoke remains instant via `revokeRole`.
     */
    function grantRole(
        bytes32 role,
        address account
    ) external override {
        if (msg.sender != address(this)) {
            revert Errors.UnauthorizedCaller();
        }

        _grantRole(role, account, msg.sender);
    }

    /**
     * @notice Revoke a role from an account
     * @dev Asymmetric authority:
     *      - Revoking `GOVERNOR_ROLE` requires `owner()` (apex circuit-breaker; prevents governor self-coup).
     *      - Revoking any other role requires `GOVERNOR_ROLE` (operational hygiene without cold-key signing).
     * @param role The role to revoke
     * @param account The account to revoke role from
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external override {
        if (role == Roles.GOVERNOR_ROLE) {
            if (msg.sender != owner()) revert Errors.UnauthorizedCaller();
        } else {
            _onlyGovernor();
        }

        if (!_roles[role][account]) revert Errors.RoleNotGranted();

        delete _roles[role][account];
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice Transfer ownership to a new address (callable only via timelock self-call).
     * @dev Overrides `Ownable2StepUpgradeable.transferOwnership`. The owner schedules this call
     *      via `scheduleOperation(address(this), <encoded transferOwnership(newOwner)>, OP_OWNERSHIP_TRANSFER)`,
     *      waits 72h, then any governor executes. Skips the 2-step pendingOwner pattern because the
     *      timelock itself provides the safety window.
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) public override {
        if (msg.sender != address(this)) revert Errors.OwnershipTransferThroughTimelock();
        newOwner.requireNonZero();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Disabled — renouncing ownership would permanently leave the protocol ungoverned.
     * @dev Override of `Ownable2StepUpgradeable.renounceOwnership` that always reverts.
     */
    function renounceOwnership() public pure override {
        revert Errors.RenounceOwnershipDisabled();
    }

    /**
     * @notice Activate global pause (pauses all contracts)
     * @dev Circuit-breaker entry: `OPERATOR_ROLE` only (GV-05 1-of-N off-chain).
     */
    function activateGlobalPause() external onlyOperator {
        _globalPause = true;
        emit GlobalPauseActivated(msg.sender);
    }

    /**
     * @notice Deactivate global pause
     */
    function deactivateGlobalPause() external onlyGovernor {
        _globalPause = false;
        emit GlobalPauseDeactivated(msg.sender);
    }

    /**
     * @notice Add an address to the blacklist
     * @param user The address to blacklist
     * @param reason Blacklist reason code (0–3, see `Constants.BLACKLIST_REASON_*`)
     * @dev Freeze entry: `OPERATOR_ROLE` only (GV-05 1-of-N off-chain).
     */
    function addToBlackList(address user, uint8 reason) external override onlyOperator {
        user.requireNonZero();
        _addToBlackList(user, reason);
    }

    /**
     * @notice Remove an address from the blacklist
     * @param user The address to remove from blacklist
     */
    function removeFromBlackList(address user) external override onlyGovernor {
        if (!_blacklist[user].active) {
            revert Errors.ZeroAddress(); // User not in blacklist
        }
        delete _blacklist[user];
        emit AddressWhitelisted(user, msg.sender);
    }

    /**
     * @notice Batch add addresses to blacklist
     * @param users Array of addresses to blacklist
     * @dev Freeze entry: `OPERATOR_ROLE` only (GV-05 1-of-N off-chain).
     */
    function batchAddToBlackList(
        address[] calldata users,
        uint8 reason
    ) external override onlyOperator {
        AddressLib.requireNonZeroBatch(users);
        _validateBlackListReason(reason);

        for (uint256 i; i < users.length; ++i) {
            _addToBlackList(users[i], reason);
        }
    }

    /**
     * @notice Batch remove addresses from blacklist
     * @param users Array of addresses to remove from blacklist
     */
    function batchRemoveFromBlackList(
        address[] calldata users
    ) external override onlyGovernor {
        for (uint256 i; i < users.length; ++i) {
            delete _blacklist[users[i]];
            emit AddressWhitelisted(users[i], msg.sender);
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                   DEPLOYMENT TIMELOCK ACTIVATION
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Restore production timelock delays after deployment wiring.
     * @dev Requires `GOVERNOR_ROLE`. Callable only while `initialize` zero-delay values are still in effect.
     *      Reverts once production delays are active (one-shot transition).
     */
    function activateProductionTimelocks() external onlyGovernor {
        if (!_isDeploymentTimelockPhase()) revert Errors.ProductionTimelocksAlreadyActive();

        _timelockDelayByOperationType[Constants.OP_GRANT_ROLE] = Constants.TIMELOCK_GRANT_ROLE;
        _timelockDelayByOperationType[Constants.OP_CONTRACT_UPGRADE] = Constants.TIMELOCK_CONTRACT_UPGRADE;
        _timelockDelayByOperationType[Constants.OP_PARAMETER_CHANGE] = Constants.TIMELOCK_PARAMETER_CHANGE;
        _timelockDelayByOperationType[Constants.OP_OWNERSHIP_TRANSFER] = Constants.TIMELOCK_OWNERSHIP_TRANSFER;

        emit ProductionTimelocksActivated(msg.sender);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      TIMELOCK WRITE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @notice Schedule an operation for delayed execution
     * @param target The target contract address
     * @param data The calldata for the operation
     * @param operationType The operation type determining the timelock delay
     * @return operationId The unique identifier for the operation
     */
    function scheduleOperation(
        address target,
        bytes calldata data,
        bytes32 operationType
    ) external override onlyGovernor returns (bytes32 operationId) {
        target.requireNonZeroContract();
        if (data.length == 0) revert Errors.InvalidData();

        // Idempotent ID: same (target, data, operationType) produces the same opId. Block.timestamp
        // is deliberately NOT included so an accidental double-schedule reverts at the dup check
        // below rather than silently creating an independent queued copy with its own timer.
        operationId = keccak256(abi.encode(target, data, operationType));

        // Check if operation is already scheduled (and not yet expired)
        if (isOperationScheduled(operationId)) {
            revert Errors.OperationAlreadyScheduled(operationId);
        }
        // If an expired entry occupies the slot, clear it so the re-schedule below can proceed cleanly.
        if (_operations[operationId].target != address(0)) {
            delete _operations[operationId];
        }

        // C-05: When scheduling `updateTimelockDelay(targetType, _)`, use the LONGER of the
        // parameter-change delay and the existing delay for `targetType`. Prevents using a
        // short-delay op type (e.g. PARAMETER_CHANGE = 24h) to weaken a long-delay op type
        // (e.g. CONTRACT_UPGRADE = 72h).
        uint256 delay = _timelockDelayFor(operationType);
        if (target == address(this) && data.length >= 36) {
            bytes4 selector;
            bytes32 targetType;
            assembly {
                selector := calldataload(data.offset)
                targetType := calldataload(add(data.offset, 4))
            }
            if (selector == this.updateTimelockDelay.selector) {
                uint256 currentTargetDelay = _timelockDelayByOperationType[targetType];
                if (currentTargetDelay > delay) {
                    delay = currentTargetDelay;
                }
            }
        }

        uint256 readyTime = block.timestamp + delay;
        uint256 expiryTime = readyTime + Constants.OPERATION_EXPIRY_WINDOW;

        // Store operation
        _operations[operationId] = Operation({
            target: target,
            operationType: operationType,
            data: data,
            readyTime: readyTime,
            expiryTime: expiryTime
        });

        emit OperationScheduled(operationId, target, operationType, data, readyTime, expiryTime);
    }

    /**
     * @notice Execute a scheduled operation
     * @param operationId The operation identifier
     * @dev Only `GOVERNOR_ROLE` holders can execute operations
     */
    function executeOperation(bytes32 operationId) external override onlyGovernor {
        Operation storage op = _operations[operationId];

        // Check if operation is scheduled
        op.target.requireNonZeroContract();

        // Check if operation is ready
        if (block.timestamp < op.readyTime) {
            revert Errors.OperationNotReady(operationId, op.readyTime);
        }

        // Check if operation has expired
        if (block.timestamp > op.expiryTime) {
            revert Errors.OperationExpired(operationId, op.expiryTime);
        }

        // Save operation data before deleting (storage reference becomes invalid after delete)
        address target = op.target;
        bytes memory data = op.data;

        // Delete operation before execution (reentrancy protection)
        delete _operations[operationId];

        // Execute operation
        (bool success, ) = target.call(data);
        if (!success) {
            revert Errors.OperationExecutionFailed(operationId);
        }

        emit OperationExecuted(operationId, msg.sender);
    }

    /**
     * @notice Cancel a scheduled operation (including expired entries left in storage)
     * @param operationId The operation identifier
     * @dev Only `GOVERNOR_ROLE` holders can cancel operations
     */
    function cancelOperation(bytes32 operationId) external override onlyGovernor {
        // Delete operation
        delete _operations[operationId];

        emit OperationCancelled(operationId, msg.sender);
    }

    /**
     * @notice Update the timelock delay for an operation type
     * @param operationType The operation type identifier
     * @param newDelay The new delay in seconds
     * @dev Callable only via timelock execution (`executeOperation` self-call on this contract).
     */
    function updateTimelockDelay(bytes32 operationType, uint256 newDelay) external override {
        if (msg.sender != address(this)) {
            revert Errors.UnauthorizedCaller();
        }
        if (newDelay < Constants.MIN_TIMELOCK_DELAY || newDelay > Constants.MAX_TIMELOCK_DELAY) {
            revert Errors.InvalidTimelockDelay(
                newDelay,
                Constants.MIN_TIMELOCK_DELAY,
                Constants.MAX_TIMELOCK_DELAY
            );
        }

        uint256 oldDelay = _timelockDelayFor(operationType);
        _timelockDelayByOperationType[operationType] = newDelay;

        emit TimelockDelayUpdated(operationType, oldDelay, newDelay);
    }
}
