// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { Pricer } from "./Pricer.sol";
import { VaultToken } from "./VaultToken.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { EnumerableSetLib } from "solady/utils/EnumerableSetLib.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";
import { DepositReceiver } from "./DepositReceiver.sol";
import { IPriceProvider } from "./interfaces/IPriceProvider.sol";


contract WithdrawalQueueMultiAsset is Auth {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;
    using EnumerableSetLib for EnumerableSetLib.Bytes32Set;
    using SafeCastLib for uint256;
    

    address public pricer;
    address public vaultToken;
    address public baseAsset;
    address public depositReceiver;

    uint256 public withdrawalNonce = 1;
    uint64 public minimumDeadline = 2 hours;
    uint64 public instantWithdrawalFee;

    EnumerableSetLib.Bytes32Set private _withdrawalRequests;
    mapping(bytes32 => WithdrawalRequest) public withdrawalRequestData;
    mapping(address => bool) public isAcceptableToken;
    bool public isPaused;
    bool public isInstantWithdrawalPaused;
    uint256 private constant BASIS_POINTS_DENOMINATOR = 10_000;

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
    error WithdrawalQueue__TokenNotAcceptable(address token);
    error WithdrawalQueue__TokenNotInPricer(address token);
    error WithdrawalQueue__FeeTooLarge();

    event WithdrawalRequestCreated(
        bytes32 withdrawalRequestId,
        uint256 nonce,
        address initiator,
        address user,
        address assetOut,
        uint256 amount,
        uint256 createdAt,
        uint256 exchangeRate,
        uint256 assetOutAmount,
        uint256 minAssetOut,
        uint64 deadline
    );
    event WithdrawalRequestProcessed(
        bytes32 withdrawalRequestId, 
        address user, 
        address assetOut,
        uint256 amount, 
        uint256 assetOutAmount, 
        uint256 exchangeRate
    );
    event InstantWithdrawal(address user, address assetOut, uint256 amount, uint256 assetOutAmount, uint256 fee);
    event WithdrawalRequestRejected(
        bytes32 withdrawalRequestId, address initiator, address user, address assetOut, uint256 amount, uint256 assetOutAmount
    );
    event WithdrawalRequestClaimed(bytes32 withdrawalRequestId, address initiator, uint256 amount);
    event WithdrawalRequestCancelled(bytes32 withdrawalRequestId, address initiator, uint256 amount);
    event InstantWithdrawalFeeSet(uint64 instantWithdrawalFee);
    event PausedSet(bool isPaused);
    event InstantWithdrawalPausedSet(bool isInstantWithdrawalPaused);
    event PricerSet(address pricer);
    event MinimumDeadlineSet(uint64 minimumDeadline);
    event AcceptableTokenSet(address token, bool isAcceptable);
    event AssetReturnedToDepositReceiver(address indexed token, uint256 amount);

    struct WithdrawalRequest {
        uint256 nonce;
        address initiator;
        address user;
        address assetOut;
        uint256 amount;
        uint256 createdAt;
        uint128 exchangeRate;
        uint256 assetOutAmount;
        uint256 minAssetOut;
        uint64 deadline;
    }

    constructor(address _owner, address _pricer, address _depositReceiver) Auth(_owner, Authority(address(0))) {
        if (_pricer == address(0) || _owner == address(0) || _depositReceiver == address(0)) {
            revert WithdrawalQueue__ZeroAddress();
        }
        pricer = _pricer;
        vaultToken = Pricer(pricer).vaultToken();
        baseAsset = Pricer(pricer).baseAsset();
        if (vaultToken == address(0) || baseAsset == address(0)) {
            revert WithdrawalQueue__ZeroAddress();
        }
        depositReceiver = _depositReceiver;
        instantWithdrawalFee = 30; //0.3%
        isAcceptableToken[baseAsset] = true;
        emit AcceptableTokenSet(baseAsset, true);
    }

    /**
     * @notice Creates a withdrawal request
     * @param _user The address of the user
     * @param _assetOut The address of the asset the user wants to receive
     * @param _amount The amount of vault tokens to withdraw
     * @param _minAssetOut The minimum amount of asset out the user expects
     * @param _deadline The deadline for the withdrawal request
     */
    function createWithdrawalRequest(
        address _user,
        address _assetOut,
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
        if (_user == address(0)) {
            revert WithdrawalQueue__ZeroAddress();
        }
        if (!isAcceptableToken[_assetOut]) {
            revert WithdrawalQueue__TokenNotAcceptable(_assetOut);
        }
        if (_amount == 0) {
            revert WithdrawalQueue__InvalidAmount();
        }
        if (_deadline < block.timestamp + minimumDeadline) {
            revert WithdrawalQueue__InvalidDeadline();
        }

        vaultToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentExchangeRate = Pricer(pricer).getRate();
        // Use getAssetAmount with the specified assetOut
        uint256 assetOutAmount = Pricer(pricer).getAssetAmount(_assetOut, _amount);
        if (assetOutAmount < _minAssetOut) {
            revert WithdrawalQueue__InvalidMinAssetOut();
        }
        WithdrawalRequest memory withdrawalRequest = WithdrawalRequest({
            nonce: withdrawalNonce,
            initiator: msg.sender,
            user: _user,
            assetOut: _assetOut,
            amount: _amount,
            createdAt: uint64(block.timestamp),
            exchangeRate: currentExchangeRate.toUint128(),
            assetOutAmount: assetOutAmount,
            minAssetOut: _minAssetOut,
            deadline: _deadline
        });
        bytes32 withdrawalRequestId = keccak256(abi.encode(withdrawalRequest));
        bool success = _withdrawalRequests.add(withdrawalRequestId);
        if (!success) {
            revert WithdrawalQueue__WithdrawalRequestIdAlreadyExists(withdrawalRequestId);
        }
        withdrawalRequestData[withdrawalRequestId] = withdrawalRequest;

        emit WithdrawalRequestCreated(
            withdrawalRequestId,
            withdrawalRequest.nonce,
            msg.sender,
            withdrawalRequest.user,
            withdrawalRequest.assetOut,
            withdrawalRequest.amount,
            withdrawalRequest.createdAt,
            withdrawalRequest.exchangeRate,
            withdrawalRequest.assetOutAmount,
            withdrawalRequest.minAssetOut,
            withdrawalRequest.deadline
        );
        withdrawalNonce++;
        return withdrawalRequest;
    }

    /**
     * @notice Instantly withdraws tokens with a fee
     * @param _user The address of the user who will receive the withdrawn assets
     * @param _assetOut The address of the asset the user wants to receive
     * @param _amount The amount of vault tokens to withdraw (before fee)
     * @param _minAssetOut The minimum amount of assetOut to receive (slippage protection)
     */
    function instantWithdraw(address _user, address _assetOut, uint256 _amount, uint256 _minAssetOut) external {
        if (isPaused || isInstantWithdrawalPaused) {
            revert WithdrawalQueue__Paused();
        }
        if (_user == address(0)) {
            revert WithdrawalQueue__ZeroAddress();
        }
        if (!isAcceptableToken[_assetOut]) {
            revert WithdrawalQueue__TokenNotAcceptable(_assetOut);
        }
        if (_amount == 0) {
            revert WithdrawalQueue__InvalidAmount();
        }
        VaultToken(vaultToken).burn(msg.sender, _amount);
        uint256 fee = _amount.mulDivUp(instantWithdrawalFee, BASIS_POINTS_DENOMINATOR);
        uint256 amountToWithdraw = _amount - fee;
        uint256 assetOutAmount = Pricer(pricer).getAssetAmount(_assetOut, amountToWithdraw);
        if (assetOutAmount < _minAssetOut) {
            revert WithdrawalQueue__InvalidMinAssetOut();
        }
        DepositReceiver(depositReceiver).sendAssetsForInstantWithdrawal(_assetOut, _user, assetOutAmount);
        emit InstantWithdrawal(_user, _assetOut, _amount, assetOutAmount, fee);
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
            bytes32 withdrawalRequestId = keccak256(abi.encode(withdrawalRequest));

            // Validate request exists in storage
            if (withdrawalRequestData[withdrawalRequestId].nonce == 0) {
                revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
            }

            if (withdrawalRequest.deadline < block.timestamp) {
                revert WithdrawalQueue__WithdrawalRequestExpired();
            }
            uint256 amountToSend = withdrawalRequest.assetOutAmount;
            uint256 exchangeRateApplied = withdrawalRequest.exchangeRate;

            // Calculate current asset amount based on current prices
            uint256 currentAssetAmount = Pricer(pricer).getAssetAmount(withdrawalRequest.assetOut, withdrawalRequest.amount);

            // If the reserved amount is greater than current value, recalculate
            if (amountToSend > currentAssetAmount) {
                amountToSend = currentAssetAmount;
                exchangeRateApplied = currentExchangeRate.toUint128();
                if (amountToSend < withdrawalRequest.minAssetOut) {
                    success = _withdrawalRequests.remove(withdrawalRequestId);
                    if (!success) {
                        revert WithdrawalQueue__WithdrawalRequestIdNotFound(withdrawalRequestId);
                    }
                    delete withdrawalRequestData[withdrawalRequestId];
                    vaultToken.safeTransfer(withdrawalRequest.initiator, withdrawalRequest.amount);
                    // Return the reserved asset to depositReceiver
                    withdrawalRequest.assetOut.safeTransfer(depositReceiver, withdrawalRequest.assetOutAmount);
                    emit AssetReturnedToDepositReceiver(withdrawalRequest.assetOut, withdrawalRequest.assetOutAmount);
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
            delete withdrawalRequestData[withdrawalRequestId];

            // Send the user's chosen asset
            withdrawalRequest.assetOut.safeTransfer(withdrawalRequest.user, amountToSend);
            VaultToken(vaultToken).burn(address(this), withdrawalRequest.amount);

            emit WithdrawalRequestProcessed(
                withdrawalRequestId, 
                withdrawalRequest.user, 
                withdrawalRequest.assetOut,
                withdrawalRequest.amount, 
                amountToSend, 
                exchangeRateApplied
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
        delete withdrawalRequestData[withdrawalRequestId];

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
        delete withdrawalRequestData[withdrawalRequestId];

        vaultToken.safeTransfer(_withdrawalRequest.initiator, _withdrawalRequest.amount);
        emit WithdrawalRequestRejected(
            withdrawalRequestId,
            _withdrawalRequest.initiator,
            _withdrawalRequest.user,
            _withdrawalRequest.assetOut,
            _withdrawalRequest.amount,
            _withdrawalRequest.assetOutAmount
        );
    }

    /**
     * @notice Recovers ERC20 tokens from the contract
     * @dev Only callable by admin. For acceptable tokens that may be part of pending withdrawals,
     *      calculates reserved amounts and only recovers excess tokens. Non-acceptable tokens are fully recovered.
     * @param _token The address of the token to recover
     * @param _activeWithdrawals The active withdrawal requests (must match stored requests to ensure accurate accounting)
     */
    function recoverERC20(address _token, WithdrawalRequest[] memory _activeWithdrawals) external requiresAuth {
        if (isAcceptableToken[_token]) {
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
                if (withdrawalRequest.assetOut == _token) {
                    totalAssets += withdrawalRequest.assetOutAmount;
                }
            }
            uint256 balance = _token.balanceOf(address(this));
            if (balance > totalAssets) {
                _token.safeTransfer(depositReceiver, balance - totalAssets);
            }
        } else {
            _token.safeTransfer(depositReceiver, _token.balanceOf(address(this)));
        }
    }

    /**
     * @notice Gets all active withdrawal request IDs
     * @return Array of bytes32 withdrawal request IDs currently in the queue
     */
    function getActiveWithdrawals() public view returns (bytes32[] memory) {
        return _withdrawalRequests.values();
    }
    /**
     * @notice Sets the instant withdrawal fee
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _instantWithdrawalFee The instant withdrawal fee
     */

    function setInstantWithdrawalFee(uint64 _instantWithdrawalFee) external requiresAuth {
        if (_instantWithdrawalFee > 1000) revert WithdrawalQueue__FeeTooLarge(); // Max 10%
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
        if (_pricer == address(0)) revert WithdrawalQueue__ZeroAddress();
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


    /**
     * @notice Sets whether a token is acceptable for withdrawals
     * @dev Only callable by addresses with ADMIN_ROLE. Token must be configured in Pricer.
     * @param _token The address of the token
     * @param _isAcceptable Whether the token is acceptable
     */
    function setAcceptableToken(address _token, bool _isAcceptable) external requiresAuth {
        if (_isAcceptable && _token != baseAsset) {
            (IPriceProvider priceProvider,,) = Pricer(pricer).assetConfigs(_token);
            if (address(priceProvider) == address(0)) {
                revert WithdrawalQueue__TokenNotInPricer(_token);
            }
        }
        isAcceptableToken[_token] = _isAcceptable;
        emit AcceptableTokenSet(_token, _isAcceptable);
    }

    /**
     * @notice Gets all active withdrawal requests with full data
     * @return requests Array of active WithdrawalRequest structs
     */
    function getActiveWithdrawalRequests() external view returns (WithdrawalRequest[] memory requests) {
        bytes32[] memory ids = _withdrawalRequests.values();
        requests = new WithdrawalRequest[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            requests[i] = withdrawalRequestData[ids[i]];
        }
    }

    /**
     * @notice Computes the required amount for a specific token from active withdrawals
     * @param _token The token address to query
     * @return amount The total amount needed for the specified token
     */
    function getRequiredTokenAmounts(address _token) external view returns (uint256 amount) {
        bytes32[] memory ids = _withdrawalRequests.values();

        for (uint256 i = 0; i < ids.length; i++) {
            WithdrawalRequest memory req = withdrawalRequestData[ids[i]];
            if (req.assetOut == _token) {
                amount += req.assetOutAmount;
            }
        }
    }

    /**
     * @notice Gets the count of active withdrawal requests
     * @return count Number of active withdrawal requests
     */
    function getActiveWithdrawalsCount() external view returns (uint256 count) {
        return _withdrawalRequests.length();
    }

    /**
     * @notice Gets a single withdrawal request by its ID hash
     * @param _withdrawalRequestId The keccak256 hash of the withdrawal request
     * @return request The withdrawal request data
     */
    function getWithdrawalRequest(bytes32 _withdrawalRequestId) external view returns (WithdrawalRequest memory request) {
        return withdrawalRequestData[_withdrawalRequestId];
    }

}
