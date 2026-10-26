// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IDexFiFarm {
    enum TimeUnit {
        BLOCK,
        SECOND
    }

    function MIN_AMOUNT_OUT() external pure returns (uint256);

    function vault() external view returns (address);

    function native() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardTokens(uint256 index) external view returns (address);

    function rewardTokensCount() external view returns (uint256);

    function farm() external view returns (address);

    function liquidity(address user) external view returns (uint256);

    function stakingTokenType() external view returns (string memory);

    function rewardTokenType(address token) external view returns (string memory);

    function dexVersion() external view returns (uint256);

    function stakingTokenLiquidity(uint256 amount) external returns (uint256);

    function stakingTokenApproveData(address to, uint256 amount) external view returns (bytes memory data);

    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 amount
    ) external view returns (bytes memory data);

    function timeUnit() external pure returns (TimeUnit);

    function sharePerTimeUnit(address rewardToken) external view returns (uint256);

    function pendingRewards(address token, address user) external view returns (uint256);

    function decodeAndValidateReinitialize(bytes memory params) external view returns (bool);

    function initializationVersion() external view returns (uint8);

    error CallerIsNotVault(address caller, address vault);

    function getAmountOutStakingTokenToNative(uint256 amountIn) external returns (uint256 nativeAmount);

    function getAmountOutRewardTokenToNative(address token, uint256 amountIn) external returns (uint256 nativeAmount);

    function initialize(bytes memory params) external returns (bool);

    function reinitialize(bytes memory params) external returns (bool);

    function deposit(uint256 nativeAmount) external returns (uint256 stakingAmount);

    function depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) external;

    function harvest() external returns (uint256 amount);

    function withdraw(uint256 stakingAmount) external returns (uint256 nativeAmount);

    function withdrawConvertless(uint256 stakingAmount, address recipient) external;

    function emergencyWithdraw(uint256 stakingAmount, address recipient) external;
}
