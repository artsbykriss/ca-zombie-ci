// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IOpinionResolver {
    struct Resolution {
        bytes32 questionId;
        uint256[2] originalPayouts;
        uint256[2] finalPayouts;
        uint8 status;
        uint8 disputeReason;
        uint256 receivedAt;
        uint256 disputeDeadline;
        uint256 reVoteDeadline;
        address disputor;
        address stakeToken;
        uint256 rewardAmount;
        uint256 stakedAmount;
        bool claimed;
        bool disputeSucceeded;
    }
    function getActiveQuestionIds() external view returns (bytes32[] memory);
    function getResolution(bytes32) external view returns (Resolution memory);
    function dispute(bytes32, uint8) external;
    function claim(bytes32) external;
    function timeoutDispute(bytes32) external;
    function finalize(bytes32) external;
    function resolve(bytes32, uint256[] calldata) external;
    function isDisputeTimedOut(bytes32) external view returns (bool);
    function hasRole(bytes32, address) external view returns (bool);
    function OPERATOR_ROLE() external view returns (bytes32);
    function paused() external view returns (bool);
}

interface ITenbinRevenueModule {
    function collect(address, uint256) external;
    function manager() external view returns (address);
    function multisig() external view returns (address);
    function hasRole(bytes32, address) external view returns (bool);
}

interface ITenbinCollateralManager {
    function getRevenue(address) external view returns (uint256);
    function withdrawRevenue(address, uint256) external;
    function pendingRevenue(address) external view returns (uint256);
    function getVaultAssets(address) external view returns (uint256);
    function lastTotalAssets(address) external view returns (uint256);
    function vaults(address) external view returns (address);
    function pauseStatus() external view returns (uint8);
}

interface IERC4626 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function previewDeposit(uint256) external view returns (uint256);
    function previewRedeem(uint256) external view returns (uint256);
    function deposit(uint256, address) external returns (uint256);
    function redeem(uint256, address, address) external returns (uint256);
}

interface IGenericMorphoAdapter {
    function parentVault() external view returns (address);
    function vault() external view returns (address);
    function realAssets() external view returns (uint256);
    function allocate(bytes calldata, uint256, bytes4, address) external returns (bytes32[] memory, int256);
}
