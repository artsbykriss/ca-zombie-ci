// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title IPrintrFeeDistribution
 * @notice Interface for fee distribution functionality in the Printr protocol
 */
interface IPrintrFeeDistribution is IPrintrStorage {

    /**
     * @notice Structure containing fee distribution information
     * @param totalAmount Total amount being distributed
     * @param growthAmount Amount allocated to growth fund
     * @param buybackAmount Amount allocated to buyback fund
     * @param teamAmount Amount allocated to team treasury
     * @param creatorAmount Amount allocated to creator NFT holder
     * @param creatorAddress Address of the creator NFT holder (or zero if none)
     */
    struct FeeDistribution {
        uint256 totalAmount;
        uint256 growthAmount;
        uint256 buybackAmount;
        uint256 teamAmount;
        uint256 creatorAmount;
        address creatorAddress;
    }

    /**
     * @notice Emitted when base pair fees are distributed
     * @param token The PRINTR token address for which fees were collected
     * @param feeToken The base pair token being distributed
     * @param totalAmount Total amount of fees distributed
     * @param isLiquidityFee Whether these are LP fees (true) or protocol fees (false)
     */
    event FeesDistributed(address indexed token, address indexed feeToken, uint256 totalAmount, bool isLiquidityFee);

    /**
     * @notice Emitted when telecoin LP fees are distributed
     * @param token The telecoin token address
     * @param stakerAmount Amount sent to stakers (V2 staking contract, or `stakingFund` EOA on V1)
     * @param protocolAmount Amount sent to the team treasury fund (V2 only; 0 for V1)
     */
    event TokenFeesDistributed(address indexed token, uint256 stakerAmount, uint256 protocolAmount);

    /**
     * @notice Returns accumulated protocol fees and their distribution
     * @param token The PRINTR token address to query
     * @return distribution The fee distribution breakdown for the accumulated fees
     */
    function getAccumulatedProtocolFees(
        address token
    ) external returns (FeeDistribution memory distribution);

    /**
     * @notice Collects and distributes accumulated protocol fees for a token
     * @dev Permissionless function that distributes fees to platform wallets and Creator NFT holder
     * @param token Address of the PRINTR token to collect fees from
     */
    function collectProtocolFees(
        address token
    ) external returns (FeeDistribution memory distribution);

    /**
     * @notice Collects and distributes accumulated liquidity fees for a token
     * @dev Permissionless function that distributes LP fees to platform wallets and Creator NFT holder
     * @param token Address of the PRINTR token to collect fees from
     */
    function collectLiquidityFees(
        address token
    ) external returns (FeeDistribution memory basePairDistribution, uint256 tokenStakingAmount);

}
