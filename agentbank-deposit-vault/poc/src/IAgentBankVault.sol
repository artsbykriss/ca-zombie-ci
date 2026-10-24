// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Minimal interface for the deployed World Chain "AgentBank Deposit Vault" (abWLD),
/// which is a genuine Morpho `VaultV2` deployed via Morpho's official `VaultV2Factory`.
interface IVaultV2 {
    function asset() external view returns (address);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function virtualShares() external view returns (uint256);

    function owner() external view returns (address);
    function curator() external view returns (address);
    function receiveSharesGate() external view returns (address);
    function sendSharesGate() external view returns (address);
    function receiveAssetsGate() external view returns (address);
    function sendAssetsGate() external view returns (address);
    function adapterRegistry() external view returns (address);
    function isAllocator(address account) external view returns (bool);
    function isSentinel(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function adaptersLength() external view returns (uint256);
    function adapters(uint256 index) external view returns (address);
    function isAdapter(address account) external view returns (bool);
    function liquidityAdapter() external view returns (address);
    function forceDeallocatePenalty(address adapter) external view returns (uint256);

    function maxRate() external view returns (uint64);
    function performanceFee() external view returns (uint96);
    function managementFee() external view returns (uint96);
    function performanceFeeRecipient() external view returns (address);
    function managementFeeRecipient() external view returns (address);

    function timelock(bytes4 selector) external view returns (uint256);
    function abdicated(bytes4 selector) external view returns (bool);

    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);

    function canReceiveShares(address account) external view returns (bool);
    function canSendShares(address account) external view returns (bool);
    function canReceiveAssets(address account) external view returns (bool);
    function canSendAssets(address account) external view returns (bool);

    function deposit(uint256 assets, address onBehalf) external returns (uint256);
    function mint(uint256 shares, address onBehalf) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address onBehalf) external returns (uint256);
    function redeem(uint256 shares, address receiver, address onBehalf) external returns (uint256);
    function forceDeallocate(address adapter, bytes memory data, uint256 assets, address onBehalf)
        external
        returns (uint256);

    // Owner functions (no timelock by design)
    function setOwner(address newOwner) external;
    function setCurator(address newCurator) external;
    function setIsSentinel(address account, bool newIsSentinel) external;

    // Curator functions (timelocked)
    function setIsAllocator(address account, bool newIsAllocator) external;
    function setReceiveSharesGate(address newGate) external;
    function setSendSharesGate(address newGate) external;
    function setReceiveAssetsGate(address newGate) external;
    function setSendAssetsGate(address newGate) external;
    function addAdapter(address account) external;
    function setPerformanceFee(uint256 newFee) external;
    function setManagementFee(uint256 newFee) external;
    function setMaxRate(uint256 newMaxRate) external;
    function setLiquidityAdapterAndData(address newAdapter, bytes memory newData) external;
    function submit(bytes calldata data) external;
}

interface IVaultV2Factory {
    function isVaultV2(address account) external view returns (bool);
    function createVaultV2(address owner, address asset, bytes32 salt) external returns (address);
}

/// @dev ErrorsLib of Morpho VaultV2 (only the ones exercised by the PoC).
interface IVaultErrors {
    error Abdicated();
    error Unauthorized();
    error DataNotTimelocked();
    error NotAdapter();
    error CannotReceiveShares();
    error CannotSendShares();
    error CannotReceiveAssets();
    error CannotSendAssets();
}
