#!/usr/bin/env bash
# hle-circle — combined heavy job for the ZH4-PASS7 TIER-2 HIGH deep-dive.
# Dumps live state for BOTH targets into ci-out/ using keyless public endpoints only. No secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[hle-circle] start $(date -u +%FT%TZ)"

echo "=== circle-gateway live state ==="
python3 - > ci-out/circle_gateway_state.json <<'PY'
import json, urllib.request, datetime
RPCS = ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"]
UA = "Mozilla/5.0 (zombie-hunt research)"
MINTER = "0x2222222d7164433c4C09B0b0D809a9b52C04C205"
WALLET = "0x77777777Dcc4d5A8B6E418Fd04D8997ef11000eE"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
INIT_SLOT = "0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00"
def rpc(method, params):
    last = None
    for url in RPCS:
        try:
            req = urllib.request.Request(url, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                         headers={"Content-Type":"application/json","User-Agent":UA})
            return json.load(urllib.request.urlopen(req, timeout=25))
        except Exception as e:
            last = e
    raise last
def call(to, data):
    try: return rpc("eth_call", [{"to": to, "data": data}, "latest"]).get("result")
    except Exception as e: return "ERR:" + str(e)
def slot(a, s): return rpc("eth_getStorageAt", [a, s, "latest"])["result"]
def codesize(a): return (len(rpc("eth_getCode", [a, "latest"])["result"]) - 2) // 2
def addr_of(w): return "0x" + w[-40:]
block = int(rpc("eth_blockNumber", [])["result"], 16)
out = {"chain":"ethereum","block":block,"read_at_utc":datetime.datetime.utcnow().isoformat()+"Z","minter":MINTER,"wallet":WALLET}
for label, a in [("minter", MINTER), ("wallet", WALLET)]:
    out[label] = {"owner":call(a,"0x8da5cb5b"),"pendingOwner":call(a,"0xe30c3978"),"pauser":call(a,"0x9fd0506d"),
                  "domain":call(a,"0xc2fb26a6"),"impl_slot":slot(a,IMPL_SLOT),"admin_slot":slot(a,ADMIN_SLOT),
                  "init_slot":slot(a,INIT_SLOT),"paused":call(a,"0x5c975abb")}
out["wallet"]["withdrawalDelay"] = call(WALLET,"0xa7ab6961")
out["wallet"]["feeRecipient"] = call(WALLET,"0x46904840")
out["wallet"]["usdc_balance"] = int(call(USDC,"0x70a08231000000000000000000000000"+WALLET[2:]),16)/1e6
out["wallet"]["usdc_supported"] = call(WALLET,"0x75151b63"+"0"*24+USDC[2:])
out["owner_codesize"] = {"minter_owner":codesize(addr_of(out["minter"]["owner"])),"wallet_owner":codesize(addr_of(out["wallet"]["owner"]))}
print(json.dumps(out, indent=2))
PY
echo "[hle-circle] circle snapshot done"

echo "=== hyperliquid-earn live state ==="
python3 - > ci-out/hyperliquid_earn_state.json <<'PY'
import json, urllib.request, datetime
API = "https://api.hyperliquid.xyz/info"
RPC = "https://rpc.hyperliquid.xyz/evm"
def api(payload):
    req = urllib.request.Request(API, data=json.dumps(payload).encode(), headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(req, timeout=25))
def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(req, timeout=25))
def widx(i): return "0x%064x" % i
def call_pre(pre, data): return rpc("eth_call",[{"to":"0x000000000000000000000000000000000000"+pre,"data":data},"latest"])
block = int(rpc("eth_blockNumber", [])["result"], 16)
reserves = api({"type":"allBorrowLendReserveStates"})
spot = api({"type":"spotMeta"}); names = {t["index"]:t["name"] for t in spot["tokens"]}
fields = ["borrowYearlyRateBps","supplyYearlyRateBps","balance1e8","utilizationBps","oraclePx1e6","ltvBps","totalSupplied1e8","totalBorrowed1e8"]
out = {"chain":"hyperliquid-hyperevm","chainId":999,"hyperevm_block":block,"read_at_utc":datetime.datetime.utcnow().isoformat()+"Z",
       "precompiles":{"tokenInfo":"0x000000000000000000000000000000000000080c","reserveState":"0x0000000000000000000000000000000000000812","coreWriter":"0x3333333333333333333333333333333333333333"},"reserves":[]}
for tok, state in reserves:
    e = {"tokenIndex":tok,"name":names.get(tok,"?"),"api":state}
    try:
        r = call_pre("0812", widx(tok))
        if "result" in r:
            h = r["result"][2:]; ws = [int(h[i:i+64],16) for i in range(0,len(h),64)]
            e["precompile_0x0812"] = dict(zip(fields, ws))
    except Exception as ex: e["precompile_0x0812_error"] = str(ex)
    out["reserves"].append(e)
out["tvl_supplied_usd_oraclePx"] = round(sum(float(e["api"]["totalSupplied"])*float(e["api"]["oraclePx"]) for e in out["reserves"]),2)
out["corewriter_code_bytes"] = (len(rpc("eth_getCode",["0x3333333333333333333333333333333333333333","latest"])["result"])-2)//2
print(json.dumps(out, indent=2))
PY
echo "[hle-circle] hl snapshot done"
echo "[hle-circle] done $(date -u +%FT%TZ)"
