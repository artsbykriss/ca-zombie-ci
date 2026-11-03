#!/usr/bin/env bash
# ca2-low-a — reproducible live-state verifier (read-only).
# Re-checks the exact blocking conditions for the three CA2 LOW findings:
#   b14g (CORE)      : Marketplace / CoreVault / FairShare paused(), owner, impl slots
#   Vara Bridge (ETH): challengeRoot freeze, verifier address, ERC20Manager balances
#   Hifi (ETH)       : malicious BalanceSheet impl, harvestIdle revert, empty balances,
#                      Governor proposal 22 state / quorum
# No keys or keyed URLs are printed or written. Results: ci-out/live_state.json
set -uo pipefail

mkdir -p ci-out
ETHRPC="${FORK_RPC_URL:-${RPC_URL:-https://eth.drpc.org}}"
CORERPC="${CORE_RPC_URL:-https://rpc.coredao.org}"

retry() {
  for i in 1 2 3; do
    out=$("$@" 2>/dev/null) && { printf '%s' "$out"; return 0; }
    sleep $((i*2))
  done
  return 1
}
raw() { retry cast call "$3" "$4" --rpc-url "$1" --block "$2"; }
dec() {
  local h; h=$(raw "$1" "$2" "$3" "$4") || { echo null; return; }
  if [ -z "$h" ] || [ "$h" = "0x" ]; then echo 0; return; fi
  cast to-dec "$h" 2>/dev/null || echo null
}
addr() {
  local h; h=$(raw "$1" "$2" "$3" "$4") || { echo null; return; }
  if [ -z "$h" ] || [ "$h" = "0x" ]; then echo null; return; fi
  echo "0x${h: -40}"
}
slot_impl() {
  retry cast storage "$3" 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$1" --block "$2" 2>/dev/null \
    | sed 's/^0x000000000000000000000000/0x/'
}
errcheck() { # errcheck <pattern> <cmd...>
  local pat="$1"; shift
  for i in 1 2 3; do
    out=$("$@" 2>&1)
    case "$out" in *"$pat"*) echo 1; return 0;; esac
    sleep 2
  done
  echo 0
}

EB=$(retry cast block-number --rpc-url "$ETHRPC") || EB=0
CB=$(retry cast block-number --rpc-url "$CORERPC") || CB=0

# ---------------- b14g (CORE, chain id 1116) ----------------
M=0x04EA61C431F7934d51fEd2aCb2c5F942213f8967
V=0xee21ab613d30330823D35Cf91A84cE964808B83F
F=0x13E3eC65EFeB0A4583c852F4FaF6b2Fb31Ff04b1
M_PAUSED=$(dec "$CORERPC" "$CB" "$M" 0x5c975abb)
V_PAUSED=$(dec "$CORERPC" "$CB" "$V" 0x5c975abb)
F_PAUSED=$(dec "$CORERPC" "$CB" "$F" 0x5c975abb)
M_OWNER=$(addr "$CORERPC" "$CB" "$M" 0x8da5cb5b)
M_IMPL=$(slot_impl "$CORERPC" "$CB" "$M")
V_IMPL=$(slot_impl "$CORERPC" "$CB" "$V")
F_IMPL=$(slot_impl "$CORERPC" "$CB" "$F")
M_BAL=$(retry cast balance "$M" --rpc-url "$CORERPC" --block "$CB") || M_BAL=null
V_BAL=$(retry cast balance "$V" --rpc-url "$CORERPC" --block "$CB") || V_BAL=null
WITHDRAW_REVERT=$(errcheck 'Pausable: paused' cast call "$M" \
  0x94923c6000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000 \
  --from 0x000000000000000000000000000000000000dEaD --rpc-url "$CORERPC" --block "$CB")
UNPAUSE_REVERT=$(errcheck 'caller is not the owner' cast call "$M" 0x3f4ba83a \
  --from 0x000000000000000000000000000000000000dEaD --rpc-url "$CORERPC" --block "$CB")

# ---------------- Vara Bridge (Ethereum) ----------------
Q=0x8E01Fbf136cA97627ca241dB9EFf1DFE3f2195F6
E=0x16fCff97822fcf3345Fa76D29c229b11C49EaE12
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
WVARA=0xB67010F2246814e5c39593ac23A925D9e9d7E5aD
PAD_E=$(python3 -c "print('0'*24+'$E'[2:])")
Q_PAUSED=$(dec "$ETHRPC" "$EB" "$Q" 0x5c975abb)
Q_ESTOP=$(dec "$ETHRPC" "$EB" "$Q" 0xfddd4837)
Q_CHAL=$(dec "$ETHRPC" "$EB" "$Q" 0x52d190f3)
Q_MAXBLK=$(dec "$ETHRPC" "$EB" "$Q" 0xa912fd25)
Q_VERIFIER=$(addr "$ETHRPC" "$EB" "$Q" 0x2b7ac3f3)
Q_IMPL=$(slot_impl "$ETHRPC" "$EB" "$Q")
E_PAUSED=$(dec "$ETHRPC" "$EB" "$E" 0x5c975abb)
USDC_BAL=$(dec "$ETHRPC" "$EB" "$USDC" "0x70a08231$PAD_E")
USDT_BAL=$(dec "$ETHRPC" "$EB" "$USDT" "0x70a08231$PAD_E")
WVARA_SUPPLY=$(dec "$ETHRPC" "$EB" "$WVARA" 0x18160ddd)
SUBMIT_ERR=$(errcheck '0x4df7989c' cast call "$Q" "submitMerkleRoot(uint256,bytes32,bytes)" \
  37072001 0x0000000000000000000000000000000000000000000000000000000000000000 0x \
  --from 0x000000000000000000000000000000000000dEaD --rpc-url "$ETHRPC" --block "$EB")

# ---------------- Hifi (Ethereum) ----------------
BS=0x452467a37f7a0c1ea8432a52b8bbe3cc31e9513b
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
GOV=0xef0A0421Ea43b602E5Be35e9018Dd3E34Bcee007
HIFI=0x4b9278b94a1112cAD404048903b8d343a810B07e
PAD_BS=$(python3 -c "print('0'*24+'$BS'[2:])")
BS_IMPL=$(slot_impl "$ETHRPC" "$EB" "$BS")
BS_ETH=$(retry cast balance "$BS" --rpc-url "$ETHRPC" --block "$EB") || BS_ETH=null
BS_WETH=$(dec "$ETHRPC" "$EB" "$WETH" "0x70a08231$PAD_BS")
HARVEST_ERR=$(errcheck '0x40eaba5a' cast call "$BS" "harvestIdle(address)" "$WETH" \
  --from 0x000000000000000000000000000000000000dEaD --rpc-url "$ETHRPC" --block "$EB")
P22=$(retry cast call "$GOV" "proposals(uint256)(uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool)" 22 \
  --rpc-url "$ETHRPC" --block "$EB" 2>/dev/null | tr '\n' ' ')
P22_STATE=$(dec "$ETHRPC" "$EB" "$GOV" "0x3e4f49e6$(python3 -c "print(format(22,'064x'))")")
QUORUM=$(dec "$ETHRPC" "$EB" "$GOV" 0x24bc1a64)
HIFI_SUPPLY=$(dec "$ETHRPC" "$EB" "$HIFI" 0x18160ddd)

cat > ci-out/live_state.json <<EOF
{
  "generated_utc": "$(date -u +%FT%TZ)",
  "blocks": {"ethereum": $EB, "core": $CB},
  "b14g": {
    "marketplace": "$M", "paused": $M_PAUSED, "owner": "$M_OWNER", "impl": "$M_IMPL",
    "corevault": "$V", "corevault_paused": $V_PAUSED, "corevault_impl": "$V_IMPL",
    "fairshare": "$F", "fairshare_paused": $F_PAUSED, "fairshare_impl": "$F_IMPL",
    "marketplace_core_balance_wei": "$M_BAL", "corevault_core_balance_wei": "$V_BAL",
    "batch_withdraw_reverts_paused": $WITHDRAW_REVERT,
    "unpause_owner_only": $UNPAUSE_REVERT
  },
  "vara_bridge": {
    "messagequeue": "$Q", "impl": "$Q_IMPL", "verifier": "$Q_VERIFIER",
    "paused": $Q_PAUSED, "isEmergencyStopped": $Q_ESTOP, "isChallengingRoot": $Q_CHAL,
    "maxBlockNumber": $Q_MAXBLK,
    "erc20manager": "$E", "erc20manager_paused": $E_PAUSED,
    "usdc_balance": "$USDC_BAL", "usdt_balance": "$USDT_BAL",
    "wvara_totalSupply": "$WVARA_SUPPLY",
    "submit_merkle_root_blocked_by_challenge": $SUBMIT_ERR
  },
  "hifi": {
    "balancesheet": "$BS", "impl": "$BS_IMPL",
    "eth_balance_wei": "$BS_ETH", "weth_balance": "$BS_WETH",
    "harvest_idle_reverts_zero": $HARVEST_ERR,
    "proposal22": "$P22", "proposal22_state": $P22_STATE,
    "quorum_votes": "$QUORUM", "hifi_totalSupply": "$HIFI_SUPPLY"
  }
}
EOF
echo "wrote ci-out/live_state.json"
python3 -m json.tool ci-out/live_state.json | head -60
if [ "$EB" = "0" ] || [ "$CB" = "0" ]; then echo "ERROR: RPC block read failed" >&2; exit 1; fi
