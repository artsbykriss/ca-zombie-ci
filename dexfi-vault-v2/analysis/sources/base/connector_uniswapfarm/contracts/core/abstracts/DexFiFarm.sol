// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./utils/DexFiInitializable.sol";
import "./../interfaces/IDexFiFarm.sol";

/**
 * @title DexFiFarm
 * @dev Abstract contract for DexFi farms.
 */
abstract contract DexFiFarm is DexFiInitializable, IDexFiFarm {
    uint256 public constant MIN_AMOUNT_OUT = 0;

    address public vault;

    /**
     * @dev Get the native token address.
     * @return The native token address.
     */
    function native() external view virtual returns (address);

    /**
     * @dev Get the staking token address.
     * @return The staking token address.
     */
    function stakingToken() external view virtual returns (address);

    /**
     * @dev Get the reward token address at a specific index.
     * @param index The index of the reward token.
     * @return The reward token address.
     */
    function rewardTokens(uint256 index) external view virtual returns (address);

    /**
     * @dev Get the count of reward tokens.
     * @return The count of reward tokens.
     */
    function rewardTokensCount() external view virtual returns (uint256);

    /**
     * @dev Get the farm contract address.
     * @return The farm contract address.
     */
    function farm() external view virtual returns (address);

    /**
     * @dev Get the liquidity of a user.
     * @param user The user address.
     * @return The liquidity of the user.
     */
    function liquidity(address user) external view virtual returns (uint256);

    /**
     * @dev Get the type of staking token.
     * @return The type of staking token.
     */
    function stakingTokenType() external view virtual returns (string memory);

    /**
     * @dev Get the type of reward token.
     * @param token The reward token address.
     * @return The type of reward token.
     */
    function rewardTokenType(address token) external view virtual returns (string memory);

    /**
     * @dev Get the version of the DEX.
     * @return The version of the DEX.
     */
    function dexVersion() external view virtual returns (uint256);

    /**
     * @dev Get the staking token liquidity for a given amount.
     * @param amount The amount of staking tokens.
     * @return The staking token liquidity.
     */
    function stakingTokenLiquidity(uint256 amount) external virtual returns (uint256);

    /**
     * @dev Get the approval data for staking token transfer.
     * @param to The recipient address.
     * @param amount The amount of staking tokens to be transferred.
     * @return data The approval data.
     */
    function stakingTokenApproveData(address to, uint256 amount) external view virtual returns (bytes memory data);

    /**
     * @dev Get the transfer data for staking token.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The amount of staking tokens to be transferred.
     * @return data The transfer data.
     */
    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 amount
    ) external view virtual returns (bytes memory data);

    /**
     * @dev Get the time unit for reward calculations.
     * @return The time unit.
     */
    function timeUnit() external pure virtual returns (TimeUnit);

    /**
     * @dev Get the reward tokens distributed per time unit.
     * @param rewardToken The reward token address.
     * @return The amount of reward tokens per time unit.
     */
    function sharePerTimeUnit(address rewardToken) external view virtual returns (uint256);

    /**
     * @dev Get the pending rewards for a user and token.
     * @param token The reward token address.
     * @param user The user address.
     * @return The pending rewards.
     */
    function pendingRewards(address token, address user) external view virtual returns (uint256);

    /**
     * @dev Decode and validate reinitialization parameters.
     * @param params The initialization parameters.
     * @return Whether the decoding and validation was successful.
     */
    function decodeAndValidateReinitialize(bytes memory params) external view virtual returns (bool);

    /**
     * @dev Get the initialization version of the farm.
     * @return The initialization version.
     */
    function initializationVersion() public view returns (uint8) {
        return _getInitializedVersion();
    }

    /**
     * @dev Get the amount of native tokens required to obtain a specific amount of staking tokens.
     * @param amountIn The amount of staking tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function getAmountOutStakingTokenToNative(
        uint256 amountIn
    ) external onlyInitialized returns (uint256 nativeAmount) {
        nativeAmount = _getAmountOutStakingTokenToNative(amountIn);
    }

    /**
     * @dev Get the amount of native tokens obtained from a specific amount of reward tokens.
     * @param token The reward token address.
     * @param amountIn The amount of reward tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function getAmountOutRewardTokenToNative(
        address token,
        uint256 amountIn
    ) external onlyInitialized returns (uint256 nativeAmount) {
        nativeAmount = _getAmountOutRewardTokenToNative(token, amountIn);
    }

    /**
     * @dev Initialize the farm contract.
     * @param params The initialization parameters.
     * @return Whether the initialization was successful.
     */
    function initialize(bytes memory params) external initializer returns (bool) {
        vault = msg.sender;
        _reinitialize(params);
        return true;
    }

    /**
     * @dev Reinitialize the farm contract.
     * @param params The reinitialization parameters.
     * @return Whether the reinitialization was successful.
     */
    function reinitialize(
        bytes memory params
    ) public onlyVault reinitializer(initializationVersion() + 1) returns (bool) {
        _reinitialize(params);
        return true;
    }

    /**
     * @dev Deposit native tokens and receive staking tokens.
     * @param nativeAmount The amount of native tokens to deposit.
     * @return stakingAmount The amount of staking tokens received.
     */
    function deposit(uint256 nativeAmount) external onlyInitialized onlyVault returns (uint256 stakingAmount) {
        stakingAmount = _deposit(nativeAmount);
    }

    /**
     * @dev Deposit staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to deposit.
     * @param depositLiquidityAmount The amount of liquidity tokens to receive.
     * @param feeLiquidityAmount The amount of liquidity tokens for fees.
     * @param feeRecipient The recipient of fees.
     * @param residualsRecipient The recipient of residuals.
     */
    function depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) external onlyInitialized onlyVault {
        _depositConvertless(
            stakingAmount,
            depositLiquidityAmount,
            feeLiquidityAmount,
            feeRecipient,
            residualsRecipient
        );
    }

    /**
     * @dev Harvest rewards.
     * @return nativeAmount The amount of native tokens harvested.
     */
    function harvest() external onlyInitialized onlyVault returns (uint256 nativeAmount) {
        nativeAmount = _harvest();
    }

    /**
     * @dev Withdraw staking tokens and receive native tokens.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @return nativeAmount The amount of native tokens received.
     */
    function withdraw(uint256 stakingAmount) external onlyInitialized onlyVault returns (uint256 nativeAmount) {
        nativeAmount = _withdraw(stakingAmount);
    }

    /**
     * @dev Withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function withdrawConvertless(uint256 stakingAmount, address recipient) external onlyInitialized onlyVault {
        _withdrawConvertless(stakingAmount, recipient);
    }

    /**
     * @dev Emergency withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to emergency withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function emergencyWithdraw(uint256 stakingAmount, address recipient) external onlyInitialized onlyVault {
        _emergencyWithdraw(stakingAmount, recipient);
    }

    /**
     * @dev Get the amount of native tokens required to obtain a specific amount of staking tokens.
     * @param amountIn The amount of staking tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function _getAmountOutStakingTokenToNative(uint256 amountIn) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Get the amount of native tokens obtained from a specific amount of reward tokens.
     * @param token The reward token address.
     * @param amountIn The amount of reward tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function _getAmountOutRewardTokenToNative(
        address token,
        uint256 amountIn
    ) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Reinitialize the farm contract.
     * @param params The reinitialization parameters.
     */
    function _reinitialize(bytes memory params) internal virtual;

    /**
     * @dev Deposit native tokens and receive staking tokens.
     * @param nativeAmount The amount of native tokens to deposit.
     * @return stakingAmount The amount of staking tokens received.
     */
    function _deposit(uint256 nativeAmount) internal virtual returns (uint256 stakingAmount);

    /**
     * @dev Deposit staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to deposit.
     * @param depositLiquidityAmount The amount of liquidity tokens to receive.
     * @param feeLiquidityAmount The amount of liquidity tokens for fees.
     * @param feeRecipient The recipient of fees.
     * @param residualsRecipient The recipient of residuals.
     */
    function _depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) internal virtual;

    /**
     * @dev Harvest rewards.
     * @return nativeAmount The amount of native tokens harvested.
     */
    function _harvest() internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Withdraw staking tokens and receive native tokens.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @return nativeAmount The amount of native tokens received.
     */
    function _withdraw(uint256 stakingAmount) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function _withdrawConvertless(uint256 stakingAmount, address recipient) internal virtual;

    /**
     * @dev Emergency withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to emergency withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function _emergencyWithdraw(uint256 stakingAmount, address recipient) internal virtual;

    /**
     * @dev Ensure that the caller is the vault.
     */
    modifier onlyVault() {
        if (msg.sender != vault) revert CallerIsNotVault(msg.sender, vault);
        _;
    }
}
