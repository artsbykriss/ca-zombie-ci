#!/usr/bin/env python3
"""child2_fetch.py - enumerate holders of Rose (Aurora) LP tokens, stROSE, ROSE and VASE shares.
Read-only. Public keyless RPC https://mainnet.aurora.dev (chain id 1313161554).
"""
import json, time, sys
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import requests

RPC = "https://mainnet.aurora.dev"
EXP = "https://explorer.aurora.dev"
S = requests.Session()
S.headers.update({"User-Agent": "rose-holder-map/1.0"})

TRANSFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
LOGTRANSFER = "0x6eabe333476233fd382224f233210cb808a7bc4c4de64f9d76628bf63c677b1a"

class TooBig(Exception):
    pass

def rpc(method, params, tries=7, timeout=180):
    last = None
    for i in range(tries):
        try:
            r = S.post(RPC, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=timeout)
            if r.status_code == 429:
                last = "429"; time.sleep(2 + 2 * i); continue
            j = r.json()
            if "error" in j:
                e = j["error"]; msg = json.dumps(e)
                if e.get("code") == -32005 or "response size exceeded" in msg.lower() or "exceeds" in msg.lower() or "limit" in msg.lower():
                    raise TooBig(msg)
                last = msg
            else:
                return j.get("result")
        except TooBig:
            raise
        except Exception as ex:
            last = repr(ex)
        time.sleep(1.0 + 1.5 * i)
    raise RuntimeError(f"{method} failed: {last}")

def rpc_batch(calls, chunk=40):
    """calls: list of (method, params). returns list of results (or {'error':...})."""
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        payload = [{"jsonrpc": "2.0", "id": k, "method": m, "params": p} for k, (m, p) in enumerate(part)]
        for attempt in range(6):
            try:
                r = S.post(RPC, json=payload, timeout=180)
                if r.status_code == 429:
                    time.sleep(2 + attempt * 2); continue
                j = r.json()
                by_id = {x["id"]: x for x in j}
                for k in range(len(part)):
                    x = by_id.get(k, {})
                    out.append(x.get("result", {"error": x.get("error")}))
                break
            except Exception as ex:
                if attempt == 5:
                    raise
                time.sleep(1 + attempt)
    return out

def get_logs(addr, topics, lo, hi, depth=0):
    try:
        return rpc("eth_getLogs", [{"fromBlock": hex(lo), "toBlock": hex(hi), "address": addr, "topics": topics}])
    except TooBig:
        if hi - lo < 1:
            raise
        mid = (lo + hi) // 2
        a = get_logs(addr, topics, lo, mid, depth + 1)
        b = get_logs(addr, topics, mid + 1, hi, depth + 1)
        return a + b

def net_transfers(logs, kind="erc20"):
    """Return {addr: int balance} netted from Transfer/LogTransfer logs."""
    bal = defaultdict(int)
    for lg in logs:
        t = lg["topics"]
        if kind == "erc20":
            frm = "0x" + t[1][-40:]; to = "0x" + t[2][-40:]
        else:  # bentobox LogTransfer(token,from,to,share) - topics[2]=from, topics[3]=to
            frm = "0x" + t[2][-40:]; to = "0x" + t[3][-40:]
        amt = int(lg["data"], 16) if lg["data"] not in ("0x", "") else 0
        bal[frm] -= amt
        bal[to] += amt
    return {k: v for k, v in bal.items() if v > 0}

def call(addr, data):
    return rpc("eth_call", [{"to": addr, "data": data}, "latest"])

def bal_of(token, addr):
    d = "0x70a08231" + addr[2:].lower().rjust(64, "0")
    return int(call(token, d), 16)

def u256(x):
    return int(x, 16) if isinstance(x, str) else int(x)

# ---------------- targets ----------------
LP_TOKENS = {
    "3pool-LP":  "0xff79d5bff48e1c01b722560d6ffdfce9fc883587",
    "metaUST-LP":"0x94a7644e4d9ca0e685226254f88eadc957d3c263",
    "metaFRAX-LP":"0x4463a118a2fb34640ff8ef7fe1b3abacd4ac9fb7",
    "metaMAI-LP":"0xa7ae42224bf48ecefc5f838c230ee339e5fd8e62",
    "RUSD-LP":   "0x56f87a0cb4713eb513baf57d5e81750433f5fcb9",
}
STROSE = "0xe23d2289fbca7de725dc21a13fc096787a85e16f"
ROSE = "0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970"
VASE = "0xee793001ce9fa988712b15a59ccf5dc7d54b22ff"
VASE_TOKENS = {
    "RUSD":  "0x19cc40283b057d6608c22f1d20f17e16c245642e",
    "WBTC":  "0xf4eb217ba2454613b15dbdea6e5f22276410e89e",
    "UST":   "0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc",
    "USDC":  "0xb12bfca5a55806aaf64e99521918a4bf0fc40802",
    "USDT":  "0x4988a896b1227218e4a686fde5eabdcabd91571f",
    "WNEAR": "0xc42c30ac6cc15fac9bd938618bcaa1a1f49a694f",
    "WETH":  "0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb",
}
DAO_EOA = "0x3820feddeaba00564166e68a73babdae5740394f"

def verify(token, baldict, n=15, kind="erc20"):
    top = sorted(baldict.items(), key=lambda kv: -kv[1])[:n]
    calls = []
    for a, _ in top:
        if kind == "erc20":
            d = "0x70a08231" + a[2:].lower().rjust(64, "0")
        else:
            d = "0xf7888aec" + token[2:].lower().rjust(64, "0") + a[2:].lower().rjust(64, "0")
        calls.append(("eth_call", [{"to": token if kind == "erc20" else VASE, "data": d}, "latest"]))
    res = rpc_batch(calls)
    out = []
    for (a, net), r in zip(top, res):
        onchain = int(r, 16) if isinstance(r, str) else None
        out.append({"addr": a, "netted": net, "onchain": onchain, "match": (onchain == net) if onchain is not None else None})
    return out

def strip_logs(logs):
    return [{"b": lg["blockNumber"], "t": lg["topics"], "d": lg["data"], "tx": lg["transactionHash"]} for lg in logs]

def main():  # trimmed: LP, stROSE, ROSE only
    blk = u256(rpc("eth_blockNumber", []))
    print("latest block", blk)
    result = {"block": blk, "rpc": "https://mainnet.aurora.dev", "chainId": 1313161554}

    # ---- 1) LP tokens via logs ----
    lp_out = {}
    for sym, addr in LP_TOKENS.items():
        logs = get_logs(addr, [TRANSFER], 0, blk)
        bal = net_transfers(logs)
        ts = int(call(addr, "0x18160ddd"), 16)
        dec = int(call(addr, "0x313ce567"), 16)
        s = sum(bal.values())
        ver = verify(addr, bal, 15)
        lp_out[sym] = {"address": addr, "decimals": dec, "totalSupply": str(ts),
                       "logCount": len(logs), "holders": len(bal), "sumNetted": str(s),
                       "complete": s == ts, "top": ver,
                       "allBalances": {k: str(v) for k, v in sorted(bal.items(), key=lambda kv: -kv[1])}}
        print(sym, addr, "logs", len(logs), "holders", len(bal), "sum==supply", s == ts, "supply", ts)
        json.dump(strip_logs(logs), open(f"/tmp/opencode/child2_raw_{sym}.json", "w"), indent=0)
        if len(logs) <= 60000:
            json.dump(strip_logs(logs), open(f"/home/heisenberg/CA/rose/analysis/child2_raw_{sym}.json", "w"), indent=0)
    result["lp"] = lp_out

    # ---- stROSE ----
    logs = get_logs(STROSE, [TRANSFER], 0, blk)
    bal = net_transfers(logs)
    ts = int(call(STROSE, "0x18160ddd"), 16)
    dec = int(call(STROSE, "0x313ce567"), 16)
    result["stRose"] = {"address": STROSE, "decimals": dec, "totalSupply": str(ts), "logCount": len(logs),
                        "sumNetted": str(sum(bal.values())), "complete": sum(bal.values()) == ts,
                        "top": verify(STROSE, bal, 15), "allBalances": {k: str(v) for k, v in sorted(bal.items(), key=lambda kv: -kv[1])}}
    print("stROSE logs", len(logs), "holders", len(bal), "supply", ts, "sum", sum(bal.values()))

    # ---- ROSE via explorer API (logs too heavy) ----
    rose_holders = {}
    for page in range(1, 6):
        try:
            r = S.get(f"{EXP}/api?module=token&action=getTokenHolders&contractaddress={ROSE}&page={page}&offset=100", timeout=60)
            res = r.json().get("result") or []
            if not res:
                break
            for it in res:
                rose_holders[it["address"].lower()] = int(it["value"])
            if len(res) < 100:
                break
        except Exception as e:
            print("rose holder page err", page, e)
            break
    ts = int(call(ROSE, "0x18160ddd"), 16)
    dec = int(call(ROSE, "0x313ce567"), 16)
    top = sorted(rose_holders.items(), key=lambda kv: -kv[1])[:60]
    calls = [("eth_call", [{"to": ROSE, "data": "0x70a08231" + a[2:].lower().rjust(64, "0")}, "latest"]) for a, _ in top]
    res = rpc_batch(calls)
    ver = []
    for (a, net), rr in zip(top, res):
        oc = int(rr, 16) if isinstance(rr, str) else None
        ver.append({"addr": a, "explorer": str(net), "onchain": str(oc) if oc is not None else None,
                    "match": (oc == net) if oc is not None else None})
    result["rose"] = {"address": ROSE, "decimals": dec, "totalSupply": str(ts), "holders": len(rose_holders),
                      "top": ver, "explorerPages": page}
    print("ROSE explorer holders", len(rose_holders), "supply", ts)


    json.dump(result, open("/home/heisenberg/CA/rose/analysis/child2_holders_raw.json", "w"), indent=1)
    print("saved child2_holders_raw.json")
    return result

if __name__ == "__main__":
    main()
