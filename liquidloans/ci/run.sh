#!/usr/bin/env bash
# LiquidLoans — read-only live-state capture for the public CI artifact.
# No transactions are signed or sent. Public RPC only (no keyed URL is ever written).
set -uo pipefail
mkdir -p ci-out
R="${PULSE_RPC_URL:-https://rpc.pulsechain.com}"

VM=0xD79bfb86fA06e8782b401bC0197d92563602D2Ab
BO=0xa09bB56B39D652988C7E7d3665aA7EC7308BbF09
PF=0xc65Abc8B9B4B3cEE03430f6fc3d8A4760221A113
SP=0x7bFD406632483ad00c6EdF655E04De91A96f84bc
USDL=0x0dEEd1486bc52aA0d3E6f8849cEC5adD6598A162
LOAN=0x9159f1D2a9f51998Fc9Ab03fbd8f265ab14A1b3B
CSP=0x88742a6Fd16A00Fc671fff371E4CC8ff58378596
AP=0x3983f040916681085D7949F7ee78BfA12c5CB119

{
  echo "{"
  echo "  \"chain\": \"pulsechain\","
  echo "  \"rpc\": \"https://<rpc>/...\","
  echo "  \"block\": $(cast block-number --rpc-url "$R"),"
  echo "  \"activePool_pls_wei\": \"$(cast balance $AP --rpc-url "$R")\","
  echo "  \"systemColl_wei\": \"$(cast call $VM 'getEntireSystemColl()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"systemDebt_usdl_wei\": \"$(cast call $VM 'getEntireSystemDebt()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"oracle_lastGoodPrice\": \"$(cast call $PF 'lastGoodPrice()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"pricefeed_status\": \"$(cast call $PF 'status()(uint8)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"pricefeed_owner\": \"$(cast call $PF 'owner()(address)' --rpc-url "$R")\","
  echo "  \"vaultManager_owner\": \"$(cast call $VM 'owner()(address)' --rpc-url "$R")\","
  echo "  \"borrowerOps_owner\": \"$(cast call $BO 'owner()(address)' --rpc-url "$R")\","
  echo "  \"vault_count\": $(cast call $VM 'getVaultOwnersCount()(uint256)' --rpc-url "$R" | awk '{print $1}'),"
  echo "  \"MCR\": \"$(cast call $VM 'MCR()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"baseRate\": \"$(cast call $VM 'baseRate()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"stabilityPool_pls_wei\": \"$(cast balance $SP --rpc-url "$R")\","
  echo "  \"stabilityPool_usdl_wei\": \"$(cast call $USDL 'balanceOf(address)(uint256)' $SP --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"collSurplusPool_pls_wei\": \"$(cast balance $CSP --rpc-url "$R")\","
  echo "  \"loanStaking_loan_wei\": \"$(cast call $LOAN 'balanceOf(address)(uint256)' 0x853F0CD4B0083eDf7cFf5Ad9A296f02Ffb71C995 --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"usdl_totalSupply_wei\": \"$(cast call $USDL 'totalSupply()(uint256)' --rpc-url "$R" | awk '{print $1}')\","
  echo "  \"loan_totalSupply_wei\": \"$(cast call $LOAN 'totalSupply()(uint256)' --rpc-url "$R" | awk '{print $1}')\""
  echo "}"
} > ci-out/liquidloans-state.json

echo "wrote ci-out/liquidloans-state.json"
cat ci-out/liquidloans-state.json
