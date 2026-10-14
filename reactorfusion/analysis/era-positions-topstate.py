#!/usr/bin/env python3
"""Read state for top borrowers (by tx borrow amount) + optionally merged lists.
Writes era-positions-topstate.json. Resume-safe."""
import glob, json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
RPC_URLS = []
if os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + os.environ["ALCHEMY_API_KEY_2"])
if os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def post(url, payload, timeout=20):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch_calls(items, max_batch=10, tries=6):
    out = [None] * len(items); errs = [None] * len(items)
    pending = list(range(len(items)))
    size = max_batch
    attempt = 0
    while pending and attempt < tries:
        attempt += 1
        still = []
        for i in range(0, len(pending), size):
            g = pending[i:i + size]
            payload = [{"jsonrpc": "2.0", "id": x, "method": "eth_call",
                        "params": [{"to": items[x][0], "data": items[x][1]}, "latest"]} for x in g]
            ok = False
            for url in RPC_URLS:
                try:
                    resp = post(url, payload)
                    if isinstance(resp, list):
                        byid = {r.get("id"): r for r in resp}
                        for x in g:
                            r = byid.get(x, {})
                            if "result" in r:
                                out[x] = r["result"]
                            else:
                                errs[x] = str(r.get("error"))[:120]
                        ok = True
                        break
                except Exception as e:
                    errs[g[0]] = f"transport {str(e)[:60]}"
            if not ok:
                still.extend(g)
        pending = still
        if pending:
            size = max(5, size // 2)
            time.sleep(0.8 * attempt)
    return out, errs


def top_borrowers(topn=200):
    per = {}
    for fp in glob.glob(os.path.join(HERE, "era-positions-txs-*.jsonl")):
        base = os.path.basename(fp)
        m = base.replace("era-positions-txs-", "").split("-")[0].replace(".jsonl", "")
        if m not in MARKETS:
            continue
        lst = per.setdefault(m, {})
        for line in open(fp):
            x = json.loads(line)
            if (x.get("mid") or "").lower() != "0xc5ebeaec":
                continue
            inp = x.get("in") or ""
            if len(inp) < 74 or not x.get("from"):
                continue
            try:
                amt = int(inp[10:74], 16)
            except Exception:
                continue
            a = x["from"]
            if amt > lst.get(a, 0):
                lst[a] = amt
    out = set()
    for m, lst in per.items():
        top = sorted(lst.items(), key=lambda kv: -kv[1])[:topn]
        out.update(a for a, _ in top)
        print(f"{m}: {len(lst)} borrowers in crawl, top {len(top)} kept", flush=True)
    return sorted(out)


def main():
    topn = 200
    if "--top" in sys.argv:
        topn = int(sys.argv[sys.argv.index("--top") + 1])
    accounts = set(top_borrowers(topn))
    extra = os.path.join(HERE, "era-positions-priority.json")
    if os.path.exists(extra):
        try:
            accounts.update(json.load(open(extra)).get("priority", []))
        except Exception:
            pass
    accounts = sorted(accounts)
    print(f"accounts to read: {len(accounts)}", flush=True)
    prog_path = os.path.join(HERE, "era-positions-topstate.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {}
    prog.setdefault("accounts", {})
    todo = [a for a in accounts if a not in prog["accounts"]]
    print(f"todo {len(todo)}", flush=True)
    t0 = time.time()
    CH = 20
    for i in range(0, len(todo), CH):
        chunk = todo[i:i + CH]
        items = []
        for a in chunk:
            for m, addr in MARKETS.items():
                items.append((addr, "0xc37f68e2" + pad(a)))
            items.append((C, "0x5ec88c79" + pad(a)))
        raws, errs = batch_calls(items)
        k = 0
        for a in chunk:
            snaps = {}
            for m in MARKETS:
                raw, e = raws[k], errs[k]; k += 1
                if raw and raw != "0x":
                    b = raw[2:]
                    try:
                        snaps[m] = [int(b[0:64], 16), int(b[64:128], 16), int(b[128:192], 16), int(b[192:256], 16)]
                    except Exception:
                        snaps[m] = {"err": "decode"}
                else:
                    snaps[m] = {"err": e or "empty"}
            raw, e = raws[k], errs[k]; k += 1
            if raw and raw != "0x":
                b = raw[2:]
                liq = {"err": int(b[0:64], 16), "liquidity": int(b[64:128], 16), "shortfall": int(b[128:192], 16)}
            else:
                liq = {"err_str": e or "empty"}
            prog["accounts"][a] = {"snapshots": snaps, "liquidity": liq}
        json.dump(prog, open(prog_path, "w"))
        el = time.time() - t0
        print(f"progress {len(prog['accounts'])}/{len(accounts)} ({(i+len(chunk))/el:.1f} acct/s)", flush=True)
    print("TOPSTATE DONE", flush=True)


if __name__ == "__main__":
    main()
