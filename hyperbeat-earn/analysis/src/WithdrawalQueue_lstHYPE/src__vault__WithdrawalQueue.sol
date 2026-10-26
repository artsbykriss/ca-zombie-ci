// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { Pricer } from "./Pricer.sol";
import { VaultToken } from "./VaultToken.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { EnumerableSetLib } from "solady/utils/EnumerableSetLib.sol";
import { DepositReceiver } from "./DepositReceiver.sol";

contract WithdrawalQueue is Auth {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;
    using EnumerableSetLib for EnumerableSetLib.Bytes32Set;

    address public pricer;
    address public vaultToken;
    address public baseAsset;
    address public depositReceiver;

    uint256 public withdrawalNonce = 1;
    uint64 public minimumDeadline = 2 hours;
    uint64 public instantWithdrawalFee;

    EnumerableSetLib.Bytes32Set private _withdrawalRequests;
    bool public isPaused;
    bool public isInstantWithdrawalPaused;

    error WithdrawalQueue__ZeroAddress();
    error WithdrawalQueue__InvalidLastWithdrawalIdToProcess();
    error WithdrawalQueue__Paused();
    error WithdrawalQueue__WithdrawalRequestIdAlreadyExists(bytes32 withdrawalRequestId);
    error WithdrawalQueue__WithdrawalRequestIdNotFound(bytes32 withdrawalRequestId);
    error WithdrawalQueue__ExchangeRateLowerThanLastWithdrawalRequest(
        uint128 withdrawalRequestExchangeRate, uint256 currentExchangeRate
    );
    error WithdrawalQueue__InvalidActiveWithdrawals();
    error WithdrawalQueue__InvalidActiveWithdrawalRequest();
    error WithdrawalQueue__WithdrawalRequestDeadlineNotMet();
    error WithdrawalQueue__InvalidDeadline();
    error WithdrawalQueue__InvalidAmount();
    error WithdrawalQueue__InvalidMinAssetOut();
    error WithdrawalQueue__WithdrawalRequestExpired();

    event WithdrawalRequestCreated(
        bytes32 withdrawalRequestId,
        uint256 nonce,
        address initiator,
        address user,
        uint256 amount,
        uint256 createdAt,
        uint256 exchangeRate,
        uint256 baseAssetAmount,
        uint256 minAssetOut,
        uint64 deadline
    );
    event WithdrawalRequestProcessed(
        bytes32 withdrawalRequestId, address user, uint256 amount, uint256 baseAssetAmount, uint256 exchangeRate
    );
    event InstantWithdrawal(address user, uint256 amount, uint256 baseAssetAmount, uint256 fee);
    event WithdrawalRequestRejected(
        bytes32 withdrawalRequestId, address initiator, address user, uint256 amount, uint256 baseAssetAmount
    );
    event WithdrawalRequestClaimed(bytes32 withdrawalRequestId, address initiator, uint256 amount);
    event WithdrawalRequestCancelled(bytes32 withdrawalRequestId, address initiator, uint256 amount);
    event InstantWithdrawalFeeSet(uint64 instantWithdrawalFee);
    event PausedSet(bool isPaused);
    event InstantWithdrawalPausedSet(bool isInstantWithdrawalPaused);
    event PricerSet(address pricer);
    event MinimumDeadlineSet(uint64 minimumDeadline);

    struct WithdrawalRequest {
        uint256 nonce;
        address initiator;
        address user;
        uint256 amount;
        uint256 createdAt;
        uint128 exchangeRate;
        uint256 baseAssetAmount;
        uint256 minAssetOut;
        uint64 deadline;
    }

    constructor(address _owner, address _pricer, address _depositReceiver) Auth(_owner, Authority(address(0))) {
        if (_pricer == address(0) || _owner == address(0)) {
            revert WithdrawalQueue__ZeroAddress();
        }
        pricer = _pricer;
        vaultToken = Pricer(pricer).vaultToken();
        baseAsset = Pricer(pricer).baseAsset();
        depositReceiver = _depositReceiver;
        instantWithdrawalFee = 30; //0.3%
    }

    /**
     * @notice Creates a withdrawal request
     * @param _user The address of the user
     * @param _amount The amount of tokens to withdraw
     */
    function createWithdrawalRequest(
        address _user,
        uint256 _amount,
        uint256 _minAssetOut,
        uint64 _deadline
    )
        external
        returns (WithdrawalRequest memory)
    {
        if (isPaused) {
            revert WithdrawalQueue__Paused();
        }
        if (_amount == 0) {
            revert WithdrawalQueue__InvalidAmount();
        }
        if (_deadline < block.timestamp + minimumDeadline) {
            revert WithdrawalQueue__InvalidDeadline();
        }

        vaultToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentExchangeRate = Pricer(pricer).getRate();
        uint256 baseAssetAmount = Pricer(pricer).getAssetAmount(baseAsset, _amount);
        if (baseAssetAmount < _minAssetOut) {
            revert WithdrawalQueue__InvalidMinAssetOut();
        }
        WithdrawalRequest memory withdrawalRequest = WithdrawalRequest({
            nonce: withdrawalNonce,
            initiator: msg.sender,
            user: _user,
            amount: _amount,
            createdAt: uint64(block.timestamp),
            exchangeRate: uint128(currentExchangeRate),
            baseAssetAmount: baseAssetAmount,
            minAssetOut: _minAssetOut,
            deadline: _deadline
        });
        bytes32 withdrawalRequestId = keccak256(abi.encode(withdrawalRequest));
        bool success = _withdrawalRequests.add(withdrawalRequestId);
        if (!success) {
            revert WithdrawalQueue__WithdrawalRequestIdAlreadyExists(withdrawalRequestId);
        }

        emit WithdrawalRequestCreated(
            withdrawalRequestId,
            withdrawalRequest.nonce,
            msg.sender,
            withdrawalRequest.user,
            withdrawalRequest.amount,
            withdrawalRequest.createdAt,
            withdrawalRequest.exchangeRate,
            withdrawalRequest.baseAssetAmount,
            withdrawalRequest.minAssetOut,
            withdrawalRequest.deadline
        );
        withdrawalNonce++;
        return withdrawalRequest;
    }

    /**
     * @notice Instantly withdraws tokens
     * @param _user The address of the user
     * @param _amount The amount of tokens to withdraw
     */
    function instantWithdraw(address _user, uint256 _amount) external {
        if (isPaused || isInstantWithdrawalPaused) {
            revert WithdrawalQueue__Paused();
        }
        VaultToken(vaultToken).burn(msg.sender, _amount);
        uint256 fee = _amount.mulDivUp(instantWithdrawalFee, 10_000);
        uint256 amountToWithdraw = _amount - fee;
        uint256 baseAssetAmount = Pricer(pricer).getAssetAmount(baseAsset, amountToWithdraw);
        DepositReceiver(depositReceiver).sendAssetsForInstantWithdrawal(baseAsset, _user, baseAssetAmount);
        emit InstantWithdrawal(_user, _amount, baseAssetAmount, fee);
    }

    /**
     * @notice Processes withdrawal requests
     * @dev Only callable by addresses with SOLVER_ROLE
     * @param _withdrawalRequestsToProcess The withdrawal requests to process
     */
    function processWithdrawalRequests(WithdrawalRequest[] memory _withdrawalRequestsToProcess) external requiresAuth {
        uint256 requestsLength = _withdrawalRequestsToProcess.length;
        uint256 currentExchangeRate = Pricer(pricer).getRate();
        bool success;
        for (uint256 i = 0; i < requestsLength; i++) {
            WithdrawalRequest memory withdrawalRequest = _withdrawalRequestsToProcess[i];
            if (withdrawalRequest.deadline < block.timestamp) {
                revert WithdrawalQueue__WithdrawalRequestExpired();
            }
            bytes32 withdrawalRequestId = keccak256(abi.encode(withdrawalRequest));
            uint256 amountToSend = withdrawalRequest.baseAssetAmount;
            uint256 exchangeRateApplied = withdrawalRequest.exchangeRate;
            if (withdrawalRequest.exchangeRate > currentExchangeRate) {
                amountToSend = Pricer(pricer).getAssetAmount(baseAsset, withdrawalRequest.amount);
                exchangeRateApplied = uint128(currentExchangeRate);
                if (amountToSend < withdrawalRequest.minAssetOut) {
                    success = _withdrawalRequests.remove(withdrawalRequestId);
                    if (!success) {
                        revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
                    }
                    vaultToken.safeTransfer(withdrawalRequest.initiator, withdrawalRequest.amount);
                    baseAsset.safeTransfer(depositReceiver, withdrawalRequest.baseAssetAmount);
                    emit WithdrawalRequestCancelled(
                        withdrawalRequestId, withdrawalRequest.initiator, withdrawalRequest.amount
                    );
                    continue;
                }
            }
            success = _withdrawalRequests.remove(withdrawalRequestId);
            if (!success) {
                revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
            }

            baseAsset.safeTransfer(withdrawalRequest.user, amountToSend);
            VaultToken(vaultToken).burn(address(this), withdrawalRequest.amount);

            emit WithdrawalRequestProcessed(
                withdrawalRequestId, withdrawalRequest.user, withdrawalRequest.amount, amountToSend, exchangeRateApplied
            );
        }
    }

    /**
     * @notice Cancels a withdrawal request and claims shares
     * @param _withdrawalRequest The withdrawal request to cancel and claim shares
     */
    function cancelWithdrawalRequestAndClaimShares(WithdrawalRequest memory _withdrawalRequest) external {
        if (_withdrawalRequest.deadline > block.timestamp) {
            revert WithdrawalQueue__WithdrawalRequestDeadlineNotMet();
        }
        bytes32 withdrawalRequestId = keccak256(abi.encode(_withdrawalRequest));
        bool success = _withdrawalRequests.remove(withdrawalRequestId);
        if (!success) {
            revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
        }

        vaultToken.safeTransfer(_withdrawalRequest.initiator, _withdrawalRequest.amount);
        emit WithdrawalRequestClaimed(withdrawalRequestId, _withdrawalRequest.initiator, _withdrawalRequest.amount);
    }

    /**
     * @notice Rejects a withdrawal request
     * @dev Only callable by addresses with SOLVER_ROLE
     * @param _withdrawalRequest The withdrawal request to reject
     */
    function rejectWithdrawalRequest(WithdrawalRequest memory _withdrawalRequest) external requiresAuth {
        bytes32 withdrawalRequestId = keccak256(abi.encode(_withdrawalRequest));
        bool success = _withdrawalRequests.remove(withdrawalRequestId);
        if (!success) {
            revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
        }

        vaultToken.safeTransfer(_withdrawalRequest.initiator, _withdrawalRequest.amount);
        emit WithdrawalRequestRejected(
            withdrawalRequestId,
            _withdrawalRequest.initiator,
            _withdrawalRequest.user,
            _withdrawalRequest.amount,
            _withdrawalRequest.baseAssetAmount
        );
    }

    function recoverERC20(address _token, WithdrawalRequest[] memory _activeWithdrawals) external requiresAuth {
        if (_token == baseAsset) {
            bytes32[] memory activeWithdrawalRequestIds = getActiveWithdrawals();
            uint256 activeWithdrawalsLength = _activeWithdrawals.length;
            if (activeWithdrawalsLength != activeWithdrawalRequestIds.length) {
                revert WithdrawalQueue__InvalidActiveWithdrawals();
            }
            uint256 totalAssets = 0;
            for (uint256 i = 0; i < activeWithdrawalsLength; i++) {
                if (activeWithdrawalRequestIds[i] != keccak256(abi.encode(_activeWithdrawals[i]))) {
                    revert WithdrawalQueue__InvalidActiveWithdrawalRequest();
                }
                WithdrawalRequest memory withdrawalRequest = _activeWithdrawals[i];
                totalAssets += withdrawalRequest.baseAssetAmount;
            }
            baseAsset.safeTransfer(depositReceiver, baseAsset.balanceOf(address(this)) - totalAssets);
        } else {
            _token.safeTransfer(depositReceiver, _token.balanceOf(address(this)));
        }
    }

    function getActiveWithdrawals() public view returns (bytes32[] memory) {
        return _withdrawalRequests.values();
    }
    /**
     * @notice Sets the instant withdrawal fee
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _instantWithdrawalFee The instant withdrawal fee
     */

    function setInstantWithdrawalFee(uint64 _instantWithdrawalFee) external requiresAuth {
        instantWithdrawalFee = _instantWithdrawalFee;
        emit InstantWithdrawalFeeSet(_instantWithdrawalFee);
    }

    /**
     * @notice Sets the paused state
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _isPaused The paused state
     */
    function setPaused(bool _isPaused) external requiresAuth {
        isPaused = _isPaused;
        emit PausedSet(_isPaused);
    }

    /**
     * @notice Sets the instant withdrawal paused state
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _isInstantWithdrawalPaused The instant withdrawal paused state
     */
    function setInstantWithdrawalPaused(bool _isInstantWithdrawalPaused) external requiresAuth {
        isInstantWithdrawalPaused = _isInstantWithdrawalPaused;
        emit InstantWithdrawalPausedSet(_isInstantWithdrawalPaused);
    }

    /**
     * @notice Sets the pricer
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _pricer The address of the pricer
     */
    function setPricer(address _pricer) external requiresAuth {
        pricer = _pricer;
        emit PricerSet(_pricer);
    }

    /**
     * @notice Sets the minimum deadline
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _minimumDeadline The minimum deadline
     */
    function setMinimumDeadline(uint64 _minimumDeadline) external requiresAuth {
        minimumDeadline = _minimumDeadline;
        emit MinimumDeadlineSet(_minimumDeadline);
    }
}
