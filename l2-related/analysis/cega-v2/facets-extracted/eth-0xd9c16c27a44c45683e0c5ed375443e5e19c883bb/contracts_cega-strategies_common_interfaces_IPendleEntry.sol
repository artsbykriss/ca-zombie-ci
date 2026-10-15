// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface IPendleEntry {
    // Events

    /**
     * @dev Emitted when a user claims yields.
     * @param user The address of the user claiming the yield.
     * @param ytAddress The address of the YT for which SY claim is done
     * @param amount The total yield amount the user has claimed.
     */
    event PendleRewardClaimed(
        address indexed user,
        address indexed ytAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when a user claims yields. (LEGACY)
     * @param user The address of the user claiming the yield.
     * @param amount The total yield amount the user has claimed.
     */
    event RewardClaimed(
        address indexed user,
        uint256 amount
    );

    /**
     * @dev Emitted when the account signing yield claims is updated
     * @param signer The address of the new signer
     */
    event YieldClaimSignerUpdated(address indexed signer);

    // Functions

    /**
     * @dev Allows a user to claim rewards based on an off-chain signature
     * @param user The address of the user claiming the yield.
     * @param ytAddresses The addresses of the YT for which SY is claimed
     * @param amounts The total yield amounts the user is entitled to.
     * @param signatures The signature for the user's claims.
     */
    function claimPendleYield(
        address user,
        address[] calldata ytAddresses,
        uint256[] calldata amounts,
        bytes[] calldata signatures
    ) external;

    /**
     * @dev Updates the account signing yield claims
     * @param signer The address of the signer
     */
    function updateYieldClaimSigner(address signer) external;

    /**
     * @dev returns the claimed amount for a token/user pair.
     * @param token The address of the token associated with the yield.
     * @param user The address of the user claiming the yield.
     * @return The claimed amount
     */
    function getUserClaimedYieldAmount(
        address token,
        address user
    ) external view returns (uint256);

    /**
     * @dev get the account signing yield claims
     * @return The address of the signer
     */
    function getYieldClaimSigner() external view returns (address);
}
