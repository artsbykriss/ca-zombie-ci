// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Minimal surface the MasterChef needs from the RewardVestingEscrow.
interface IRewardVestingEscrow {
    /// @notice Pull `amount` of the vested token from the caller and fold it into `user`'s
    ///         180-day linear vesting schedule.
    function depositFor(address user, uint256 amount) external;

    /// @notice The vested token the escrow streams (must equal the chef's reward token).
    function token() external view returns (address);
}
