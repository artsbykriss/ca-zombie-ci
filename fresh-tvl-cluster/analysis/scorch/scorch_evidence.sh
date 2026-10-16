#!/usr/bin/env bash
# Z3-H17 · Scorch (Solana) — read-only RPC evidence script.
# Keyless public RPC only (https://api.mainnet-beta.solana.com). No keys, no sends.
# Re-runnable; writes raw JSON dumps next to itself (analysis/scorch/raw/).
#
# Program under test : SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn  (router / vault custodian)
# Core AMM program   : ojh19ojaKduoJZuaJADhcVGp4xt1TcdAvZmpVsCorch  (SCORCH_CORE_PROGRAM_ID)
# Vault PDA          : EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP = PDA(["authority"], SCoRcH..)
#                      (verified independently with @solana/web3.js findProgramAddressSync, bump 255)
# Upgrade authority  : 6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ (read from ProgramData)
set -euo pipefail
RPC="${SOLANA_RPC:-https://api.mainnet-beta.solana.com}"
OUT="$(cd "$(dirname "$0")" && pwd)/raw"
mkdir -p "$OUT"
PROGRAM=SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn
PDA=EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP
TOKEN_PROGRAM=TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
TOKEN_2022=TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb

rpc() { # rpc <method> <params-json> <outfile>
  curl -s -X POST "$RPC" -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}" -o "$OUT/$3"
}

echo "[1/7] program account + slot"
rpc getAccountInfo "[\"$PROGRAM\",{\"encoding\":\"jsonParsed\"}]" scorch_program_getaccountinfo.json

echo "[2/7] ProgramData (upgrade authority + last deploy slot)"
PD=$(python3 -c "import json;print(json.load(open('$OUT/scorch_program_getaccountinfo.json'))['result']['value']['data']['parsed']['info']['programData'])")
rpc getAccountInfo "[\"$PD\",{\"encoding\":\"base64\"}]" programdata_getaccountinfo.json

echo "[3/7] upgrade authority account + recent signatures"
AUTH=$(python3 -c "
import json,base64
raw=base64.b64decode(json.load(open('$OUT/programdata_getaccountinfo.json'))['result']['value']['data'][0])
A='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58(b):
    n=int.from_bytes(b,'big'); o=''
    while n>0: n,r=divmod(n,58); o=A[r]+o
    return '1'*(len(b)-len(b.lstrip(b'\x00')))+o
print(b58(raw[13:45]) if raw[12]==1 else 'NONE')")
rpc getAccountInfo "[\"$AUTH\",{\"encoding\":\"jsonParsed\"}]" solana_auth_getaccountinfo.json
rpc getSignaturesForAddress "[\"$AUTH\",{\"limit\":10}]" auth_signatures.json

echo "[4/7] vault PDA state + ALL token accounts (SPL + Token-2022)"
rpc getAccountInfo "[\"$PDA\",{\"encoding\":\"base64\"}]" pda_correct_getaccountinfo.json
rpc getTokenAccountsByOwner "[\"$PDA\",{\"programId\":\"$TOKEN_PROGRAM\"},{\"encoding\":\"jsonParsed\"}]" pda_correct_spl_accounts.json
rpc getTokenAccountsByOwner "[\"$PDA\",{\"programId\":\"$TOKEN_2022\"},{\"encoding\":\"jsonParsed\"}]" pda_correct_t22_accounts.json

echo "[5/7] Anchor IDL account probes + upgrade history"
rpc getMultipleAccounts "[[\"F6Sw7Vx67xhaghuUgKTwd2wBjcW9AchSpEi7afvpKHXJ\",\"HcRQNK5Z3or2hbJgkL3w54cL6pPMsh1WWRpwc2jowy4G\"],{\"encoding\":\"base64\"}]" idl_accounts_correct.json
rpc getSignaturesForAddress "[\"$PD\",{\"limit\":20}]" programdata_signatures.json

echo "[6/7] recent program activity"
rpc getSignaturesForAddress "[\"$PROGRAM\",{\"limit\":200}]" program_signatures_recent.json

echo "[7/7] TVL reproduction (amounts x DefiLlama prices, USD)"
python3 - "$OUT" <<'PY'
import json, sys, urllib.request
OUT=sys.argv[1]
accs=[]
for f in ['pda_correct_spl_accounts.json','pda_correct_t22_accounts.json']:
    d=json.load(open(f'{OUT}/{f}'))['result']['value']
    for a in d:
        i=a['account']['data']['parsed']['info']
        accs.append((i['mint'], i['tokenAmount']['uiAmountString'], i['tokenAmount']['decimals'], a['pubkey']))
mints=sorted({a[0] for a in accs})
url="https://coins.llama.fi/prices/current/"+",".join(f"solana:{m}" for m in mints)+"?searchWidth=4h"
prices=json.load(urllib.request.urlopen(url,timeout=60))['coins']
total=0.0; unpriced=0; rows=[]
for mint,amt,dec,acct in accs:
    p=prices.get(f"solana:{mint}",{})
    price=p.get('price'); usd=(float(amt)*price) if price else None
    if usd is None: unpriced+=1
    else: total+=usd
    rows.append({"mint":mint,"symbol":p.get('symbol',mint[:8]),"amount":amt,"decimals":dec,"token_account":acct,"price_usd":price,"value_usd":usd})
json.dump({"token_accounts":len(accs),"unpriced":unpriced,"total_priced_usd":round(total,2),"rows":rows},
          open(f'{OUT}/tvl_reproduction.json','w'), indent=1)
print(f'  token accounts: {len(accs)} | unpriced mints: {unpriced} | TOTAL priced USD: {round(total,2)}')
PY
echo "done. NOTE: the Scorch IDL used in the report is analysis/scorch/scorch_idl.json"
