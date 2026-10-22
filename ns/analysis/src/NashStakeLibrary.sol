// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library NashStakeLibrary {
    address internal constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant BSC_USDT = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bytes32 internal constant CONTRACT_KEY_NS_TOKEN = keccak256("NSToken");
    bytes32 internal constant CONTRACT_KEY_DISTRIBUTION_VAULT = keccak256("DistributionVault");
    bytes32 internal constant CONTRACT_KEY_PROTOCOL_TREASURY = keccak256("ProtocolTreasury");
    bytes32 internal constant CONTRACT_KEY_NS_ORACLE_ADAPTER = keccak256("NsOracleAdapter");
    bytes32 internal constant CONTRACT_KEY_STAKING = keccak256("Staking");
    bytes32 internal constant CONTRACT_KEY_NASH_LEDGER = keccak256("NashLedger");
    bytes32 internal constant CONTRACT_KEY_NASH_CLAIM_SETTLEMENT = keccak256("NashClaimSettlement");
    bytes32 internal constant CONTRACT_KEY_LIQUIDITY_MANAGER = keccak256("LiquidityManager");
    bytes32 internal constant CONTRACT_KEY_NB_EQUILIBRIUM = keccak256("NbEquilibrium");
    bytes32 internal constant ECOSYSTEM_ADDRESS = keccak256("ECOSYSTEM_ADDRESS");
}
