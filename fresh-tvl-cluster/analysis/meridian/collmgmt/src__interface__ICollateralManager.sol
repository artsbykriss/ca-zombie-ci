// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface ICollateralManager {
    // --- Events --- //

    /// @notice Emitted when the first deposit is made with a referral code.
    event AccountReferred(address indexed account, bytes32 referralCode);

    /// @notice Emitted when a deposit is initiated.
    event DepositInitiated(
        address indexed sender, bytes32 indexed subaccount, address token, uint256 amount, uint128 fee
    );

    /// @notice Emitted when the accrued fees are claimed.
    event FeesClaimed(address indexed account, bytes32 indexed subaccount, address token, uint256 amount);

    /// @notice Emitted when the accrued fees are converted.
    event FeesConverted(
        address indexed account, bytes32 indexed subaccount, address fromToken, address toToken, uint256 amount
    );

    /// @notice Emitted when a pending withdraw has been finalized.
    event WithdrawFinalized(
        address indexed account,
        bytes32 indexed withdrawDigest,
        address token,
        uint256 amount,
        uint128 fee,
        uint64 finalizedTimestamp,
        bytes32 destinationAddress,
        uint32 destinationEndpointId
    );

    /// @notice Emitted when funds are rescued due to a withdrawal that could not finalize.
    event FundsRescued(address indexed account, bytes32 withdrawDigest);

    // --- Structs --- //

    struct DepositOnBehalfRequest {
        address account;
        bytes32 subaccount;
        bytes32 tokenName;
        uint256 amount;
    }

    // --- Functions --- //

    /// @notice Claim and transfer accrued fees from exchange's fee collector, without fees or restrictions.
    /// @param feeToken Accrued token fees to claim
    /// @param amount Fee tokens to claim in D9
    function claimFees(address feeToken, uint256 amount) external;

    /// @notice Convert accrued fees from one token to another.
    /// @param fromToken Accrued token fees to convert
    /// @param toToken Token to convert to
    /// @param amount Fee tokens to convert in D9
    function convertFees(address fromToken, address toToken, uint256 amount) external;

    /// @notice Deposit `amount` of token from msg.sender to the `subaccount`.
    /// @param subaccount bytes32 encoded string of the subaccount (unique per EOA)
    /// @param depositToken Address of the token to deposit
    /// @param amount The amount of tokens in native units to deposit (non-D9)
    /// @param referralCode accepted only on the first deposit for an account, reference to credit for referral
    function deposit(bytes32 subaccount, address depositToken, uint256 amount, bytes32 referralCode) external;

    /// @notice Deposit `amount` of the default wrapped USD token from msg.sender to the `subaccount`.
    /// @param subaccount bytes32 encoded string of the subaccount (unique per EOA)
    /// @param amount The amount of default wrapped USD tokens in native units to deposit (non-D9)
    /// @param referralCode accepted only on the first deposit for an account, reference to credit for referral
    function depositUsd(bytes32 subaccount, uint256 amount, bytes32 referralCode) external;

    /// @notice Deposit default wrapped USD from msg.sender on behalf of many accounts.
    /// @param deposits Array of deposit requests. Each amount is in default wrapped USD native units (non-D9).
    /// @param referralCode accepted only on the first deposit for an account, reference to credit for referral
    function depositOnBehalf(ICollateralManager.DepositOnBehalfRequest[] calldata deposits, bytes32 referralCode)
        external;

    /// @notice Actions pending withdraw for a subaccount.
    /// @notice USD withdrawals are unwrapped to the configured default wrapped USD token.
    /// @param account Address of the account to perform on behalf of
    /// @param withdrawDigest EIP712 digest of the withdraw data
    function finalizeWithdraw(address account, bytes32 withdrawDigest) external payable;

    /// @notice Rescues funds from a withdrawal that could not finalzie after a rescue delay period.
    /// @param account Address of the account to perform on behalf of
    /// @param withdrawDigest EIP712 digest of the withdraw data
    function rescueFunds(address account, bytes32 withdrawDigest) external payable;
}
