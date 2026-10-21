// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

/// @title IIPTokenStaking
/// @notice Interface for the IPTokenStaking contract
interface IIPTokenStaking {
    /// @notice Enum representing the different staking periods
    /// @dev FLEXIBLE is used for flexible staking, where the staking period is not fixed and can be changed by the user
    /// SHORT, MEDIUM, and LONG are used for staking with specific periods
    enum StakingPeriod {
        FLEXIBLE,
        SHORT,
        MEDIUM,
        LONG
    }

    /// @notice Returns the rounded stake amount and the remainder.
    /// @param rawAmount The raw stake amount.
    /// @return amount The rounded stake amount.
    /// @return remainder The remainder of the stake amount.
    function roundedStakeAmount(uint256 rawAmount) external view returns (uint256 amount, uint256 remainder);

    /// @notice Sets an operator for a delegator.
    /// Calling this method will override any existing operator.
    /// @param operator The operator address to add.
    function setOperator(address operator) external payable;

    /// @notice Removes current operator for a delegator.
    function unsetOperator() external payable;

    /// @notice Set/Update the withdrawal address that receives the withdrawals.
    /// Charges fee (CL spam prevention). Must be exact amount.
    /// @param newWithdrawalAddress EVM address to receive the  withdrawals.
    function setWithdrawalAddress(address newWithdrawalAddress) external payable;

    /// @notice Set/Update the withdrawal address that receives the stake and reward withdrawals.
    /// Charges fee (CL spam prevention). Must be exact amount.
    /// @param newRewardsAddress EVM address to receive the stake and reward withdrawals.
    function setRewardsAddress(address newRewardsAddress) external payable;

    /// @notice Entry point to stake (delegate) to the given validator. The consensus client (CL) is notified of
    /// the deposit and manages the stake accounting and validator onboarding. Payer must be the delegator.
    /// @dev Staking burns tokens in Execution Layer (EL). Unstaking (withdrawal) will trigger minting through
    /// withdrawal queue.
    /// @param validatorCmpPubkey 33 bytes compressed secp256k1 public key.
    /// @param stakingPeriod The staking period.
    /// @param data Additional data for the stake.
    /// @return delegationId The delegation ID, always 0 for flexible staking.
    function stake(bytes calldata validatorCmpPubkey, StakingPeriod stakingPeriod, bytes calldata data)
        external
        payable
        returns (uint256 delegationId);

    /// @notice Entry point for redelegating the stake to another validator.
    /// Charges fee (CL spam prevention). Must be exact amount.
    /// @dev For non flexible staking, your staking period will continue as is.
    /// @dev For locked tokens, this will fail in CL if the validator doesn't support unlocked staking.
    /// @param validatorSrcCmpPubkey 33 bytes compressed secp256k1 public key.
    /// @param validatorDstCmpPubkey 33 bytes compressed secp256k1 public key.
    /// @param delegationId The delegation ID, 0 for flexible staking.
    /// @param amount The amount of stake to redelegate.
    function redelegate(
        bytes calldata validatorSrcCmpPubkey,
        bytes calldata validatorDstCmpPubkey,
        uint256 delegationId,
        uint256 amount
    ) external payable;

    /// @notice Entry point for unstaking the previously staked token.
    /// @dev Unstake (withdrawal) will trigger native minting, so token in this contract is considered as burned.
    /// Charges fee (CL spam prevention). Must be exact amount.
    /// @param validatorCmpPubkey 33 bytes compressed secp256k1 public key.
    /// @param delegationId The delegation ID, 0 for flexible staking.
    /// @param amount Token amount to unstake.
    /// @param data Additional data for the unstake.
    function unstake(bytes calldata validatorCmpPubkey, uint256 delegationId, uint256 amount, bytes calldata data)
        external
        payable;

    /// @notice Returns the minimum stake amount.
    /// @return The minimum stake amount.
    function minStakeAmount() external view returns (uint256);

    /// @notice Returns the fee charged for payable functions such as unstake, redelegate, etc.
    /// @return The fee amount.
    function fee() external view returns (uint256);
}
