// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Minimal interfaces for the Infrared iBERA liquid-staking token (Berachain 80094).
/// Mirrors the Etherscan-verified ABI of the implementation
/// 0xc0654903c7d76f7fe63f9ad2f01618c3b55d9dcf (contract name InfraredBERAV2_1).

interface IERC20Like {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IAccessControlLike {
    function hasRole(bytes32, address) external view returns (bool);
    function getRoleAdmin(bytes32) external view returns (bytes32);
    function grantRole(bytes32, address) external;
    function revokeRole(bytes32, address) external;
    function renounceRole(bytes32, address) external;
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function GOVERNANCE_ROLE() external view returns (bytes32);
    function KEEPER_ROLE() external view returns (bytes32);
    function PAUSER_ROLE() external view returns (bytes32);
}

interface IInfraredBERA is IERC20Like, IAccessControlLike {
    // ---- live views ----
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function deposits() external view returns (uint256);
    function withdrawalsEnabled() external view returns (bool);
    function paused() external view returns (bool);
    function burnFee() external view returns (uint256);
    function feeDivisorShareholders() external view returns (uint16);
    function proofTimestampBuffer() external view returns (uint256);
    function rateProvider() external view returns (address);
    function infrared() external view returns (address);
    function depositor() external view returns (address);
    function withdrawor() external view returns (address);
    function receivor() external view returns (address);
    function pending() external view returns (uint256);
    function confirmed() external view returns (uint256);
    function currentImplementation() external view returns (address);
    function implementation() external view returns (address);
    function convertToShares(uint256) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function previewMint(uint256) external view returns (uint256);
    function previewBurn(uint256) external view returns (uint256, uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address) external view returns (uint256);
    function maxRedeem(address) external view returns (uint256);
    function governor(address) external view returns (bool);
    function keeper(address) external view returns (bool);

    // ---- state changing ----
    function mint(address receiver) external payable returns (uint256);
    function burn(address receiver, uint256 shares) external returns (uint256, uint256);
    function compound() external;
    function sweep() external payable;
    function collect() external returns (uint256);
    function register(bytes calldata pubkey, int256 delta) external;
    function claimExitFees(address to) external;
    function pause() external;
    function unpause() external;
    function setWithdrawalsEnabled(bool) external;
    function updateBurnFee(uint256) external;
    function updateRateProvider(address) external;
    function setFeeDivisorShareholders(uint16) external;
    function updateProofTimestampBuffer(uint256) external;
    function setDepositSignature(bytes calldata, bytes calldata) external;
    function upgradeToAndCall(address, bytes calldata) external payable;
    function proxiableUUID() external view returns (bytes32);
}

interface IWithdrawor {
    function reserves() external view returns (uint256);
    function requestLength() external view returns (uint256);
    function requestsFinalisedUntil() external view returns (uint256);
    function totalClaimable() external view returns (uint256);
    function pendingWithdrawalsLength() external view returns (uint256);
    function minActivationBalance() external view returns (uint256);
    function InfraredBERA() external view returns (address);
    function paused() external view returns (bool);
    function queue(address receiver, uint256 amount) external returns (uint256);
    function process(uint256) external;
    function claim(uint256 requestId) external;
    function claimBatch(uint256[] calldata, address receiver) external;
}

interface IReceivor {
    function distribution() external view returns (uint256, uint256);
    function shareholderFees() external view returns (uint256);
    function InfraredBERA() external view returns (address);
    function sweep() external returns (uint256, uint256);
    function collect() external returns (uint256);
}
