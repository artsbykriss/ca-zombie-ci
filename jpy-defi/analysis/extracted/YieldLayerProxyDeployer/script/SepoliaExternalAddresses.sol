// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @dev External Sepolia addresses consumed by the production-parity dUSDC rehearsal.
library SepoliaExternalAddresses {
    /// Source: https://github.com/aave-dao/aave-address-book/blob/main/src/AaveV3Sepolia.sol
    address internal constant AAVE_V3_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address internal constant AAVE_USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address internal constant AAVE_USDC_ATOKEN = 0x16dA4541aD1807f4443d92D26044C1147406EB80;
    address internal constant AAVE_FAUCET = 0xC959483DBa39aa9E78757139af0e9a2EDEb3f42D;

    /// Official Morpho Vaults V2 source deployed for the Sepolia verification environment.
    /// Deployment/provenance evidence:
    /// documents/jp/engineering/historical-reviews/verification-evidence/sepolia/
    /// 2026-08-12-Sepolia-Fresh-Verification-Evidence/json/fresh-morpho-v2-venue-freeze-evidence-20260815.json
    address internal constant MORPHO_V2_USDC_VAULT = 0xa3836bb3CB271C8950A4a373362CE9117231dfB9;
}
