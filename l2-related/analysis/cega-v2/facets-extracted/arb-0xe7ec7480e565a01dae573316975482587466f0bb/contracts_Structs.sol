// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { DCSProduct, DCSVault } from "./cega-strategies/dcs/DCSStructs.sol";
import { FCNProduct, FCNVault } from "./cega-strategies/fcn/FCNStructs.sol";
import { SFNProduct, SFNVault } from "./cega-strategies/sfn/SFNStructs.sol";
import { IOracleEntry } from "./oracle-entry/interfaces/IOracleEntry.sol";

uint32 constant DCS_STRATEGY_ID = 1;
uint32 constant FCN_STRATEGY_ID = 2;
uint32 constant SFN_STRATEGY_ID = 3;

struct DepositQueue {
    uint128 queuedDepositsTotalAmount;
    uint128 processedIndex;
    mapping(address => uint128) amounts;
    address[] depositors;
    mapping(address => bool) depositorExists;
}

struct Withdrawer {
    address account;
    uint32 nextProductId;
}

struct ProductMetadata {
    string name;
    string tradeWinnerNftImage;
}

struct WithdrawalQueue {
    uint128 queuedWithdrawalSharesAmount;
    uint128 processedIndex;
    mapping(address => mapping(uint32 => uint256)) amounts;
    Withdrawer[] withdrawers;
    mapping(address => bool) withdrawingWithProxy;
}

struct Vault {
    uint128 totalAssets;
    uint64 auctionWinnerTokenId;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
    uint32 productId;
    address auctionWinner;
    uint40 tradeStartDate;
    VaultStatus vaultStatus;
    IOracleEntry.DataSource dataSource;
    bool isInDispute;
    bool isDefaulted;
}

enum OldVaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    PreAuction,
    Auctioned,
    Traded,
    AwaitingSettlement,
    Settled,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct MMNFTMetadata {
    address vaultAddress;
    uint40 tradeStartDate;
    uint40 tradeEndDate;
    uint16 aprBps;
    uint128 notional;
    uint128 initialSpotPrice;
    uint128 strikePrice;
    bytes extraData;
}

struct VaultCreationParams {
    string tokenName;
    string tokenSymbol;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
}

struct AddToDepositQueueParams {
    uint32 productId;
    uint128 amount;
    address receiver;
    address depositAsset;
    bool isDepositQueueOpen;
    uint128 minDepositAmount;
    uint128 sumVaultUnderlyingAmounts;
    uint128 maxUnderlyingAmountLimit;
    RotationStrategyParams[] rotationStrategyParams;
}

struct RemoveFromDepositQueueParams {
    uint32 productId;
    uint128 amount;
    address depositor;
    address depositAsset;
    uint128 minDepositAmount;
}

struct ProcessQueueParams {
    uint32 productId;
    address vaultAddress;
    address depositAsset;
    uint128 sumVaultUnderlyingAmounts;
    uint256 maxProcessCount;
}

struct RotationStrategy {
    uint32 nextProductId;
}

struct RotationStrategyParams {
    uint32 productId;
    RotationStrategy rotationStrategy;
}

struct VaultRotationData {
    address[] usersWithRotations;
    mapping(address => bool) userHasRotation;
    uint64 maxRotationListLength;
}

struct CegaGlobalStorage {
    // Global information
    uint32 strategyIdCounter;
    uint32 productIdCounter;
    uint32[] strategyIds;
    mapping(uint32 => uint32) strategyOfProduct;
    mapping(uint32 => ProductMetadata) productMetadata;
    mapping(address => Vault) vaults;
    // DCS information
    mapping(uint32 => DCSProduct) dcsProducts;
    // Shared
    mapping(uint32 => DepositQueue) depositQueues;
    // DCS information
    mapping(address => DCSVault) dcsVaults;
    // Shared
    mapping(address => WithdrawalQueue) withdrawalQueues;
    // vaultAddress => (asset/s hash => timestamp => price)
    mapping(address => mapping(bytes32 => mapping(uint40 => uint128))) oraclePriceOverride;
    // this will be a bitmap that has all the configs for pausing
    uint256 protocolPauseConfig;
    // FCN information
    mapping(uint32 => FCNProduct) fcnProducts;
    mapping(address => FCNVault) fcnVaults;
    // Shared
    mapping(address => bool) bondAllowList;
    // SFN information
    mapping(uint32 => SFNProduct) sfnProducts;
    mapping(address => SFNVault) sfnVaults;
    // Rotations
    // [user][productId] => rotation strategy
    mapping(address => mapping(uint32 => RotationStrategy)) rotationStrategies;
    // [vault] => vault rotation data
    mapping(address => VaultRotationData) vaultRotationData;
}

struct CegaAdhocStorage {
    // Global information
    address yieldClaimSigner;
    mapping(address token => mapping(address user => uint256 claimedAmount)) claimedAmounts;
}
