// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal interfaces for the deployed zkLink (ZkLink + ZkLinkPeriphery) contracts that
/// custody ApeX Omni deposits on Ethereum / BSC / Arbitrum / Base / Mantle.
/// Read-only research: these interfaces are used only in fork simulations.

struct StoredBlockInfo {
    uint32 blockNumber;
    uint32 blockSequence;
    uint64 priorityOperations;
    bytes32 pendingOnchainOperationsHash;
    bytes32 syncHash;
}

struct CommitBlockInfo {
    bytes32 newStateHash;
    bytes publicData;
    OnchainOperationData[] onchainOperations;
    uint32 blockNumber;
}

struct OnchainOperationData {
    bytes ethWitness;
    uint32 publicDataOffset;
}

struct ExecuteBlockInfo {
    StoredBlockInfo storedBlock;
    bytes[] pendingOnchainOpsPubdata;
}

interface IZkLink {
    // permissionless user interface
    function depositETH(bytes32 zkLinkAddress, uint8 subAccountId) external payable;
    function depositERC20(address token, uint104 amount, bytes32 zkLinkAddress, uint8 subAccountId, bool isMapping) external;
    function acceptETH(address payable receiver, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external payable;
    function acceptERC20(address receiver, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external;
    function withdrawPendingBalance(address payable owner, uint16 tokenId, uint128 amount) external;
    function activateExodusMode() external;
    function setAuthPubkeyHash(bytes calldata pubkeyHash, uint32 nonce) external;

    // validator-gated
    function commitCompressedBlocks(StoredBlockInfo memory lastCommittedBlockData, CommitBlockInfo[] memory newBlocksData) external;
    function executeCompressedBlocks(ExecuteBlockInfo[] memory blocksData) external;

    // governor-gated (delegatecalled into ZkLinkPeriphery)
    function changeGovernor(address newGovernor) external;
    function addToken(uint16 tokenId, address tokenAddress, uint8 decimals) external;
    function setTokenPaused(uint16 tokenId, bool tokenPaused) external;
    function setValidator(address validator, bool active) external;
    function setGateway(address gateway) external;

    // views
    function exodusMode() external view returns (bool);
    function networkGovernor() external view returns (address);
    function verifier() external view returns (address);
    function getNoticePeriod() external view returns (uint256);
    function totalBlocksExecuted() external view returns (uint32);
    function totalBlocksProven() external view returns (uint32);
    function totalBlocksSynchronized() external view returns (uint32);
    function CHAIN_ID() external view returns (uint8);
    function MASTER_CHAIN_ID() external view returns (uint8);
    function periphery() external view returns (address);
    function gateway() external view returns (address);
    function validators(address) external view returns (bool);
    function tokenIds(address) external view returns (uint16);
    function tokens(uint16) external view returns (bool registered, bool paused, address tokenAddress, uint8 decimals);
    function getPendingBalance(bytes32 owner, uint16 tokenId) external view returns (uint128);
}

interface IZkLinkProxy {
    function getMaster() external view returns (address);
    function getTarget() external view returns (address);
    function upgradeTarget(address newTarget) external;
    function transferMastership(address newMaster) external;
    function initialize(bytes calldata params) external;
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}
