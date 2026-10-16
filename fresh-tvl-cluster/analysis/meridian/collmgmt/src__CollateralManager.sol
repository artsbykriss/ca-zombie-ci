// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ICollateralManager} from "./interface/ICollateralManager.sol";
import {IOFTWithDecimals} from "./interface/IOFTWithDecimals.sol";
import {IMeridianUSD} from "./interface/token/IMeridianUSD.sol";
import {VerifierLib} from "./lib/VerifierLib.sol";
import {Account} from "./lib/storage/Account.sol";
import {Deposit} from "./lib/storage/Deposit.sol";
import {Exchange} from "./lib/storage/Exchange.sol";
import {FeeCollector} from "./lib/storage/FeeCollector.sol";
import {Token} from "./lib/storage/Token.sol";
import {Withdraw} from "./lib/storage/Withdraw.sol";
import {USD_TOKEN_NAME} from "./share/Constants.sol";
import {DecimalMath} from "./share/DecimalMath.sol";
import {
    DepositCapacityExceeded,
    DepositInsufficient,
    DepositOnBehalfBatchSizeExceeded,
    ExcludedAccount,
    InsufficientBalance,
    InvalidDepositOnBehalf,
    InvalidDepositToken,
    InvalidFeeConversionPair,
    InvalidFeeToken,
    P_ERR_AMT_GT_MAX,
    P_ERR_BAD_VAL,
    P_ERR_NOT_FOUND,
    PendingDepositFound,
    RescueTooEarly,
    SignerDepositUnauthorized,
    TokenDepositPaused,
    WithdrawNotFound,
    WithdrawOftFailed,
    WithdrawOftInsufficientFees,
    ZeroAddress,
    ZeroAmount,
    ZeroLength
} from "./share/Errors.sol";
import {ActionId} from "./share/UserDefinedTypes.sol";
import {ERC20Helpers} from "./share/tokens/ERC20Helpers.sol";
import {IERC20Extend} from "./share/tokens/IERC20Extend.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/oapp/OAppSender.sol";
import {OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/oft/interfaces/IOFT.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

struct FinalizeWithdraw_Runtime {
    address usdToken;
    uint256 normalizedAmount;
    uint256 denormalizedAmount;
    address withdrawToken;
    bytes32 destinationAddress;
    uint32 destinationEndpointId;
}

contract CollateralManager is ICollateralManager {
    using Account for Account.DataGlobal;
    using ERC20Helpers for IERC20Extend;
    using Exchange for Exchange.Data;
    using FeeCollector for FeeCollector.Data;
    using SafeTransferLib for address;
    using VerifierLib for address;
    using Token for Token.Data;

    /// @inheritdoc ICollateralManager
    function claimFees(address feeToken, uint256 amount) external {
        // Cannot withdraw zero amounts.
        if (amount == 0) {
            revert ZeroAmount();
        }

        // Reject virtual/synthetic tokens — claiming requires a real ERC20 to transfer.
        bytes32 feeTokenName = Exchange.load().tokensByAddress[feeToken];
        Token.Data storage feeTokenData = Token.load(feeTokenName);
        if (feeTokenData.tokenAddress == address(0) || feeTokenData.backingToken != address(0)) {
            revert InvalidFeeToken(feeToken);
        }

        FeeCollector.Data storage feeCollector = FeeCollector.load();
        address feeCollectorAccount = feeCollector.account;
        bytes32 feeCollectorSubaccount = feeCollector.subaccount;

        Account.Data storage account = Account.load(feeCollectorAccount);
        uint256 balance = account.balance[feeCollectorSubaccount][feeToken];

        // The current fee collector must have accrued sufficient balance of the token
        if (amount > balance) {
            revert InsufficientBalance(
                ActionId.wrap(0), feeCollectorAccount, feeCollectorSubaccount, feeToken, amount, balance
            );
        }

        account.balance[feeCollectorSubaccount][feeToken] = balance - amount;
        Account.load().totalBalance[feeToken] -= amount;
        Account.load().totalBackedBalance[feeToken] -= amount;

        uint256 denormalizedAmount = IERC20Extend(feeToken).denormalize(amount);
        address usdToken = Account.load().usdToken;
        if (feeToken == usdToken) {
            _unwrapUsdTo(usdToken, feeCollectorAccount, denormalizedAmount);
        } else {
            feeToken.safeTransfer(feeCollectorAccount, denormalizedAmount);
        }

        emit FeesClaimed(feeCollectorAccount, feeCollectorSubaccount, feeToken, amount);
    }

    /// @inheritdoc ICollateralManager
    function convertFees(address fromToken, address toToken, uint256 amount) external {
        // Cannot convert zero amounts.
        if (amount == 0) {
            revert ZeroAmount();
        }

        if (fromToken == toToken) {
            revert InvalidFeeConversionPair(fromToken, toToken);
        }

        Exchange.Data storage exchange = Exchange.load();
        bytes32 fromTokenName = exchange.tokensByAddress[fromToken];
        bytes32 toTokenName = exchange.tokensByAddress[toToken];
        if (fromTokenName == bytes32(0)) {
            revert InvalidFeeToken(fromToken);
        }
        if (toTokenName == bytes32(0)) {
            revert InvalidFeeToken(toToken);
        }

        {
            address fromBackingToken = Token.load(fromTokenName).backingToken;
            address toBackingToken = Token.load(toTokenName).backingToken;

            bool isValidConversion =
            // shared backing token (sibling <-> sibling)
             (fromBackingToken != address(0) && fromBackingToken == toBackingToken)
                // child -> parent: from is backed by to
                || (fromBackingToken != address(0) && fromBackingToken == toToken)
                // parent -> child: to is backed by from
                || (toBackingToken != address(0) && toBackingToken == fromToken);

            if (!isValidConversion) {
                revert InvalidFeeConversionPair(fromToken, toToken);
            }
        }

        FeeCollector.Data storage feeCollector = FeeCollector.load();
        address feeCollectorAccount = feeCollector.account;
        bytes32 feeCollectorSubaccount = feeCollector.subaccount;

        Account.Data storage account = Account.load(feeCollectorAccount);
        uint256 fromBalance = account.balance[feeCollectorSubaccount][fromToken];

        if (amount > fromBalance) {
            revert InsufficientBalance(
                ActionId.wrap(0), feeCollectorAccount, feeCollectorSubaccount, fromToken, amount, fromBalance
            );
        }

        account.balance[feeCollectorSubaccount][fromToken] = fromBalance - amount;
        account.balance[feeCollectorSubaccount][toToken] += amount;
        Account.load().totalBalance[fromToken] -= amount;
        Account.load().totalBalance[toToken] += amount;

        emit FeesConverted(feeCollectorAccount, feeCollectorSubaccount, fromToken, toToken, amount);
    }

    /// @inheritdoc ICollateralManager
    function deposit(bytes32 subaccount, address depositToken, uint256 amount, bytes32 referralCode) external {
        address usdToken = Account.load().usdToken;
        if (depositToken != usdToken && depositToken == _getDefaultWrappedUsdToken(usdToken)) {
            uint256 usdDepositAmount = _verifyAndDeposit(msg.sender, subaccount, usdToken, amount, referralCode);
            _wrapUsdFrom(msg.sender, usdToken, depositToken, usdDepositAmount);
            return;
        }

        uint256 depositAmount = _verifyAndDeposit(msg.sender, subaccount, depositToken, amount, referralCode);
        depositToken.safeTransferFrom(msg.sender, address(this), depositAmount);
    }

    /// @inheritdoc ICollateralManager
    function depositUsd(bytes32 subaccount, uint256 amount, bytes32 referralCode) external {
        address usdToken = Account.load().usdToken;
        address wrappedToken = _getDefaultWrappedUsdToken(usdToken);
        if (wrappedToken == address(0)) {
            revert InvalidDepositToken(usdToken);
        }

        uint256 depositAmount = _verifyAndDeposit(msg.sender, subaccount, usdToken, amount, referralCode);
        _wrapUsdFrom(msg.sender, usdToken, wrappedToken, depositAmount);
    }

    /// @inheritdoc ICollateralManager
    function depositOnBehalf(ICollateralManager.DepositOnBehalfRequest[] calldata deposits, bytes32 referralCode)
        external
    {
        uint256 depositsLength = deposits.length;
        if (depositsLength == 0) {
            revert ZeroLength();
        }

        uint16 maxBatchSize = Exchange.load().delegateDepositMaxBatchSize;
        if (depositsLength > maxBatchSize) {
            revert DepositOnBehalfBatchSizeExceeded(maxBatchSize);
        }

        address usdToken = Account.load().usdToken;
        address wrappedToken = _getDefaultWrappedUsdToken(usdToken);
        uint256 denormalizedTotalUsdAmount;
        for (uint256 i = 0; i < depositsLength; i++) {
            ICollateralManager.DepositOnBehalfRequest calldata d = deposits[i];
            if (d.tokenName != USD_TOKEN_NAME) {
                revert InvalidDepositOnBehalf(msg.sender, d.account, d.subaccount, "INVALID_TOKEN");
            }
            if (d.account == address(0)) {
                revert ZeroAddress();
            }

            // Prevent the depositor from depositing into another user's subaccount unless (i) it is the first deposit
            // or (ii) it's a subsequent deposit to same subaccount, avoiding unnecessary subaccounts from being created
            // not owned by the depositor.
            Account.Data storage account = Account.load(d.account);
            if (!account.hasRegistered[d.subaccount] && account.sender != address(0)) {
                revert InvalidDepositOnBehalf(msg.sender, d.account, d.subaccount, "SUBACCOUNT_REGISTERED");
            }

            // NOTE: Zero amount deposit check is performed in `_verifyAndDeposit`.
            denormalizedTotalUsdAmount += _verifyAndDeposit(d.account, d.subaccount, usdToken, d.amount, referralCode);
        }

        if (denormalizedTotalUsdAmount > 0) {
            if (wrappedToken == address(0)) {
                revert InvalidDepositToken(usdToken);
            }

            _wrapUsdFrom(msg.sender, usdToken, wrappedToken, denormalizedTotalUsdAmount);
        }
    }

    /// @inheritdoc ICollateralManager
    function finalizeWithdraw(address account, bytes32 withdrawDigest) external payable {
        Account.Data storage accountData = Account.load(account);
        Withdraw.Data memory pendingWithdraw = accountData.pendingWithdraw[withdrawDigest];

        // No pending withdraw was found with the account and digest combination
        if (pendingWithdraw.token == address(0)) {
            revert WithdrawNotFound();
        }

        // Delete the pending withdraw early, prevent re-entrancy.
        delete accountData.pendingWithdraw[withdrawDigest];
        account.verifySignature(withdrawDigest, pendingWithdraw.signature, ActionId.wrap(0));
        _completeWithdrawal(account, withdrawDigest, pendingWithdraw);
    }

    /// @inheritdoc ICollateralManager
    function rescueFunds(address account, bytes32 withdrawDigest) external payable {
        Account.Data storage accountData = Account.load(account);
        Withdraw.Data memory pendingWithdraw = accountData.pendingWithdraw[withdrawDigest];

        // No pending withdraw was found with the account and digest combination.
        if (pendingWithdraw.token == address(0)) {
            revert WithdrawNotFound();
        }

        // Check if withdrawal has been pending for long enough.
        uint256 rescueTimestamp = pendingWithdraw.initiatedAt + Exchange.load().rescueDelay;
        if (block.timestamp < rescueTimestamp) {
            revert RescueTooEarly(rescueTimestamp);
        }

        // Delete the pending withdraw early, prevent re-entrancy.
        delete accountData.pendingWithdraw[withdrawDigest];
        _completeWithdrawal(account, withdrawDigest, pendingWithdraw);
        emit FundsRescued(account, withdrawDigest);
    }

    // --- Helpers --- //

    /// @dev Completes the withdrawal, fee accrual, and transferring funds
    function _completeWithdrawal(address account, bytes32 withdrawDigest, Withdraw.Data memory withdraw) private {
        FinalizeWithdraw_Runtime memory rt;
        rt.normalizedAmount = withdraw.amount;
        rt.withdrawToken = withdraw.token;
        rt.destinationAddress = withdraw.destinationAddress;
        rt.destinationEndpointId = withdraw.destinationEndpointId;

        uint128 normalizedFee = withdraw.fee;
        if (normalizedFee > 0) {
            // Withdraw fee is an accounting transfer between the user and feeCollector (credit without token transfer)
            FeeCollector.load().accrueFees(rt.withdrawToken, normalizedFee, withdraw.messageIdx);
        }

        rt.usdToken = Account.load().usdToken;
        rt.denormalizedAmount = IERC20Extend(rt.withdrawToken).denormalize(rt.normalizedAmount);

        uint256 refundAmount;

        // If the destination is the same chain, or the destination is not set, withdraw the funds directly
        if (rt.destinationEndpointId == Exchange.load().lzEndpointId || rt.destinationEndpointId == 0) {
            // NOTE: `account` should always be `address(uint160(uint256(withdraw.destinationAddress)))`.
            // @see: OFTComposeMsgCodec.sol:addressToBytes32
            address destinationAddress = address(uint160(uint256(withdraw.destinationAddress)));
            if (rt.withdrawToken == rt.usdToken) {
                _unwrapUsdTo(rt.usdToken, destinationAddress, rt.denormalizedAmount);
            } else {
                rt.withdrawToken.safeTransfer(destinationAddress, rt.denormalizedAmount);
            }

            if (msg.value > 0) {
                refundAmount = msg.value;
            }
        } else {
            // Otherwise, prepare the OFT, and send funds to destination chain via LZ.
            if (rt.withdrawToken != rt.usdToken) {
                // NOTE: No support for withdrawing non-USD tokens via OFT. A future upgrade is necessary.
                revert InvalidDepositToken(rt.withdrawToken);
            }

            address wrappedUsdToken = _unwrapUsd(rt.usdToken, rt.denormalizedAmount);
            bytes32 tokenName = Exchange.load().tokensByAddress[rt.withdrawToken];
            IOFTWithDecimals oft = IOFTWithDecimals(Token.load(tokenName).oftAddress);

            // `oft.send` will implicitly floor by the decimal conversion rate to remove any dust from a lower
            // precision shared decimal on the OFT. Our `amountLD` and `minAmountLD` must be exactly the same otherwise
            // the send will revert.
            //
            // Example: 10.123456789 USD (18 decimals) with a default LZ shared decimals of 6:
            // - `decimalConversionRate` 10^(18-6) = 10^12 = 1,000,000,000,000
            // - Input (denormalized)    10,123,456,789,000,000,000 (10.123456789 * 10^18)
            // - After `floorToMultiple` 10,123,456,000,000,000,000 (exactly 10.123456 USD)
            // - Lost precision          0.000000789 USD           (unavoidable dust from shared decimal conversion)
            //
            // @see: ArbNativeOFTAdapter.sol:send, OFTCore.sol:_removeDust
            uint256 amountLD = DecimalMath.floorToMultiple(rt.denormalizedAmount, oft.decimalConversionRate());
            wrappedUsdToken.safeApprove(address(oft), amountLD);

            SendParam memory params = SendParam({
                to: rt.destinationAddress,
                dstEid: rt.destinationEndpointId,
                amountLD: amountLD,
                minAmountLD: amountLD,
                extraOptions: "",
                composeMsg: "",
                oftCmd: ""
            });

            MessagingFee memory messagingFee = oft.quoteSend(params, false);
            if (messagingFee.nativeFee > msg.value) {
                revert WithdrawOftInsufficientFees(account, withdrawDigest, messagingFee.nativeFee);
            }

            (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
                oft.send{value: messagingFee.nativeFee}(params, messagingFee, msg.sender);

            if (msgReceipt.guid == bytes32(0) || oftReceipt.amountSentLD == 0) {
                revert WithdrawOftFailed(account, withdrawDigest);
            }

            if (msg.value > messagingFee.nativeFee) {
                refundAmount = msg.value - messagingFee.nativeFee;
            }
        }

        if (refundAmount > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, refundAmount);
        }

        emit WithdrawFinalized(
            account,
            withdrawDigest,
            rt.withdrawToken,
            rt.normalizedAmount,
            normalizedFee,
            uint64(block.timestamp),
            rt.destinationAddress,
            rt.destinationEndpointId
        );
    }

    function _wrapUsdFrom(address from, address usdToken, address wrappedToken, uint256 amount) private {
        wrappedToken.safeTransferFrom(from, address(this), amount);
        wrappedToken.safeApprove(usdToken, amount);
        IMeridianUSD(usdToken).wrap(wrappedToken, amount);
    }

    function _unwrapUsdTo(address usdToken, address recipient, uint256 amount) private {
        address wrappedToken = _unwrapUsd(usdToken, amount);
        wrappedToken.safeTransfer(recipient, amount);
    }

    function _unwrapUsd(address usdToken, uint256 amount) private returns (address wrappedToken) {
        wrappedToken = _getDefaultWrappedUsdToken(usdToken);
        if (wrappedToken == address(0)) {
            revert InvalidDepositToken(usdToken);
        }
        IMeridianUSD(usdToken).unwrap(wrappedToken, amount);
    }

    function _getDefaultWrappedUsdToken(address usdToken) private view returns (address token) {
        (bool success, bytes memory data) =
            usdToken.staticcall(abi.encodeWithSelector(IMeridianUSD.defaultWrappedToken.selector));
        if (success && data.length >= 32) {
            token = abi.decode(data, (address));
        }
    }

    /// @dev Deposit `amount` tokens to `sender` and `subaccount` pair.
    /// @dev returns the denormalized amount to transfer from the depositor (interaction step)
    function _verifyAndDeposit(
        address sender,
        bytes32 subaccount,
        address depositToken,
        uint256 amount,
        bytes32 referralCode
    ) private returns (uint256) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (subaccount == bytes32(0)) {
            revert ZeroLength();
        }
        if (depositToken == address(0)) {
            revert InvalidDepositToken(depositToken);
        }

        Token.Data storage token = Token.load(Exchange.load().tokensByAddress[depositToken]);

        // Token deposit address does not match tracked.
        if (token.tokenAddress != depositToken) {
            revert InvalidDepositToken(depositToken);
        }

        // Virtual/Synthetic tokens cannot be deposited to
        if (token.tokenAddress == address(0) || token.backingToken != address(0)) {
            revert InvalidDepositToken(depositToken);
        }

        // Accepting of deposits must not be paused.
        if (!token.depositEnabled) {
            revert TokenDepositPaused(depositToken);
        }

        // Deposit amounts must be at least minimum required.
        //
        // Tokens are configured to have a minimum deposit. The minimum deposit must be larger than
        // the depositFee such that amount - fee is always > 0.
        uint256 normalizedAmount = IERC20Extend(depositToken).normalize(amount);
        if (normalizedAmount < token.minDeposit) {
            revert DepositInsufficient(normalizedAmount);
        }

        // Ensures deposit amount (normalized) does not exceed exchange deposit caps.
        Account.DataGlobal storage accountGlobal = Account.load();

        Account.Data storage account = Account.load(sender);
        Deposit.Data storage pendingDeposit = account.pendingDeposit[subaccount];
        if (pendingDeposit.token != address(0)) {
            revert PendingDepositFound(sender, subaccount, pendingDeposit.token, pendingDeposit.amount);
        }

        uint256 totalPendingBalance = accountGlobal.totalPendingBalance[depositToken];
        {
            // NOTE: `totalBackedBalance` is the total backed balance of the token including balance converted to virtual tokens
            uint256 totalBackedBalance = accountGlobal.totalBackedBalance[depositToken];
            uint256 capacity = token.depositCapacity;

            uint256 totalUsedCapacity = totalBackedBalance + totalPendingBalance;
            if (totalUsedCapacity + normalizedAmount > capacity) {
                revert DepositCapacityExceeded(capacity, totalUsedCapacity + normalizedAmount);
            }
        }

        if (accountGlobal.excludedAccounts[sender]) {
            revert ExcludedAccount(ActionId.wrap(0), sender);
        }

        // Register subaccount/associate deposits when `subaccount` for `msg.sender` is new (i.e. no prior deposits).
        // On the first deposit by the sender
        if (account.sender == address(0)) {
            // Prevent currently linked signers from depositing
            if (accountGlobal.linkedSignersToAccount[sender] != address(0)) {
                revert SignerDepositUnauthorized(sender);
            }

            // Accounts are not allowed to also be linked signers.
            accountGlobal.excludedSigners[sender] = true;
            account.sender = sender;

            if (referralCode != bytes32(0)) {
                emit AccountReferred(sender, referralCode);
            }
        }

        // Update deposit balances (depositor & exchange global).
        uint128 depositFee = token.depositFee;
        uint256 normalizedNetAmount = normalizedAmount - depositFee;

        // Update the total pending deposit balance for the token + fees.
        accountGlobal.totalPendingBalance[depositToken] = totalPendingBalance + normalizedAmount;
        account.pendingDeposit[subaccount] =
            Deposit.Data({token: depositToken, amount: normalizedNetAmount, fee: token.depositFee});

        emit DepositInitiated(sender, subaccount, depositToken, normalizedNetAmount, depositFee);

        // During the `normalize` step, we may lose tiny amounts of precision if decimals > 9 -> 9.
        // When this happens, we do not transfer the precision lost amounts from `msg.sender` to `exchange`,
        // achieved by denormalizing the normalized value.
        return IERC20Extend(depositToken).denormalize(normalizedAmount);
    }
}
