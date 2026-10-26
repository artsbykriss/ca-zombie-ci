// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

contract DepositReceiver is Auth {
    using SafeTransferLib for address;

    mapping(address => bool) public isDnCoreWriter;
    address public withdrawalQueue;
    address public pricer;

    error DepositReceiver__OnlyWithdrawalQueue();
    error DepositReceiver__NotDnCoreWriter(address _dnCoreWriter);
    error DepositReceiver__OnlyPricer();

    event WithdrawalQueueSet(address _withdrawalQueue);
    event PricerSet(address _pricer);
    event DnCoreWriterSet(address _dnCoreWriter, bool _isDnCoreWriter);
    event AssetsSentToDnCoreWriter(address _dnCoreWriter, address _token, uint256 _amount);
    event FeesSent(address _feeRecipient, address _token, uint256 _amount);

    modifier onlyWithdrawalQueue() {
        if (msg.sender != withdrawalQueue) {
            revert DepositReceiver__OnlyWithdrawalQueue();
        }
        _;
    }

    modifier onlyPricer() {
        if (msg.sender != pricer) {
            revert DepositReceiver__OnlyPricer();
        }
        _;
    }

    constructor(address _owner, address _withdrawalQueue) Auth(_owner, Authority(address(0))) {
        withdrawalQueue = _withdrawalQueue;
    }

    /**
     * @notice Sends assets for instant withdrawal
     * @dev Only callable by addresses with WITHDRAWAL_QUEUE_ROLE
     * @param _token The address of the token
     * @param _user The address of the user
     * @param _amount The amount of tokens to send
     */
    function sendAssetsForInstantWithdrawal(
        address _token,
        address _user,
        uint256 _amount
    )
        external
        onlyWithdrawalQueue
    {
        _token.safeTransfer(_user, _amount);
    }

    /**
     * @notice Sends fees to the fee recipient
     * @dev Only callable by addresses with PRICER
     * @param _feeRecipient The address of the fee recipient
     * @param _token The address of the token
     * @param _amount The amount of tokens to send
     */
    function sendFees(address _feeRecipient, address _token, uint256 _amount) external onlyPricer {
        _token.safeTransfer(_feeRecipient, _amount);
        emit FeesSent(_feeRecipient, _token, _amount);
    }

    /**
     * @notice Sends assets to the DnCoreWriter
     * @dev Only callable by addresses with ALLOCATOR_ROLE
     * @param _dnCoreWriter The address of the DnCoreWriter
     * @param _token The address of the token
     * @param _amount The amount of tokens to send
     */
    function sendAssetsToDnCoreWriter(address _dnCoreWriter, address _token, uint256 _amount) external requiresAuth {
        if (!isDnCoreWriter[_dnCoreWriter]) {
            revert DepositReceiver__NotDnCoreWriter(_dnCoreWriter);
        }
        _token.safeTransfer(_dnCoreWriter, _amount);
        emit AssetsSentToDnCoreWriter(_dnCoreWriter, _token, _amount);
    }

    /**
     * @notice Sets the DnCoreWriter
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _dnCoreWriter The address of the DnCoreWriter
     * @param _isDnCoreWriter The status of the DnCoreWriter
     */
    function setDnCoreWriter(address _dnCoreWriter, bool _isDnCoreWriter) external requiresAuth {
        isDnCoreWriter[_dnCoreWriter] = _isDnCoreWriter;
        emit DnCoreWriterSet(_dnCoreWriter, _isDnCoreWriter);
    }

    /**
     * @notice Sets the WithdrawalQueue
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _withdrawalQueue The address of the WithdrawalQueue
     */
    function setWithdrawalQueue(address _withdrawalQueue) external requiresAuth {
        withdrawalQueue = _withdrawalQueue;
        emit WithdrawalQueueSet(_withdrawalQueue);
    }

    /**
     * @notice Sets the Pricer
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _pricer The address of the Pricer
     */
    function setPricer(address _pricer) external requiresAuth {
        pricer = _pricer;
        emit PricerSet(_pricer);
    }
}
