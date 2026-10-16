// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Constants {
  // TODO_season: fill in the correct address
  uint256 constant PERCENTAGE_BASE = 10000;
  address constant CORE_REGISTRY_INSTANCE = 0x6547b4A12953F70C44DF5bb57E78fce68199c5c8;

  /* Common */
  string constant SYSTEM_SERVICE_NAME = "System";
  // ##
  string constant ACCESS_CONTROL_SERVICE_ID = "AccessControl";
  address constant ACCESS_CONTROL_INSTANCE = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;
  // ##
  string constant SYSTEM_VERIFIER_SERVICE_ID = "SystemVerifier";
  address constant SYSTEM_VERIFIER_INSTANCE = 0x8019775cFF797e2498b7F7f68673668077b1926F;
  // ##
  string constant ZOO_KEEPER_SERVICE_ID = "ZooKeeper";
  // ##
  string constant KERNEL_SERVICE_ID = "Kernel";
  // ##
  string constant ROUTER_SERVICE_ID = "Router";

  /* Champions */
  string constant CHAMPION_SERVICE_NAME = "Champion";
  // ##
  string constant CHAMPION_SUMMONED_SERVICE_ID = "ChampionSummoned";
  // ##
  string constant CHAMPION_ATTRIBUTE_SERVICE_ID = "ChampionAttribute";
  // ##
  string constant CHAMPION_UTILS_SERVICE_ID = "ChampionUtils";

  /* Summoning */
  string constant SUMMONING_SERVICE_NAME = "Summoning";
  // ##
  string constant SUMMONING_STATE_SERVICE_ID = "SummoningState";

  /* Vault */
  string constant VAULT_SERVICE_NAME = "Vault";
  // ##
  string constant VAULT_STATE_SERVICE_ID = "VaultState";

  /* Season */
  string constant SEASON_SERVICE_NAME = "Season";
  // ##
  string constant SEASON_SERVICE_ID = "SeasonService";
  // ##
  string constant SEASON_PASS_SERVICE_ID = "SeasonPass";
}
