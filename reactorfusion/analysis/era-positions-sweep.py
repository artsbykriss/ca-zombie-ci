#!/usr/bin/env python3
"""getAssetsIn sweep over the full account universe (finds all market members).

Universe = from_address of every tx (GoldRush + explorer crawls) + event accounts
(RPC scan logs). Reads getAssetsIn(account) at one fixed block for each address.
Saves era-positions-assetsin.json (resume-safe).

Usage: python3 era-positions-sweep.py [--limit N]
"""
import glob, json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
import os as _os
RPC_URLS = []
if _os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + _os.environ["ALCHEMY_API_KEY_2"])
if _os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + _os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")
SEL_GETASSETSIN = "0xabfceffc"
ZERO = "0x" + "00" * 20


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def post(url, payload, timeout=40):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch_calls(items, block_hex, max_batch=30, tries=4):
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
                        "params": [{"to": items[x][0], "data": items[x][1]}, block_hex]} for x in g]
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
                    errs[g[0]] = f"transport {str(e)[:80]}"
            if not ok:
                still.extend(g)
        pending = still
        if pending:
            size = max(5, size // 2)
            time.sleep(0.8 * attempt)
    return out, errs


def dec_addrs(raw):
    if not raw or raw == "0x":
        return []
    b = raw[2:]
    try:
        n = int(b[64:128], 16)
    except Exception:
        return []
    out = []
    for i in range(n):
        w = b[128 + i * 64: 192 + i * 64]
        if len(w) == 64:
            out.append("0x" + w[-40:])
    return out


def load_universe():
    """Tx-from accounts only: membership requires a tx (enterMarkets/borrow/mint),
    and event-only accounts cannot be market members."""
    accts = set()
    for fp in glob.glob(os.path.join(HERE, "era-positions-grtxs-*.jsonl")):
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            x = json.loads(line)
            if x.get("from"):
                accts.add(x["from"])
    for fp in glob.glob(os.path.join(HERE, "era-positions-txs-*.jsonl")):
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            x = json.loads(line)
            if x.get("from"):
                accts.add(x["from"])
    return sorted(accts)


def main():
    limit = None
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])
    part = 0
    nparts = 1
    if "--part" in sys.argv:
        i = sys.argv.index("--part")
        part, nparts = int(sys.argv[i + 1]), int(sys.argv[i + 2])
    universe = load_universe()
    if nparts > 1:
        universe = [a for k, a in enumerate(universe) if k % nparts == part]
    if limit:
        universe = universe[:limit]
    print(f"universe: {len(universe)} accounts (part {part}/{nparts})", flush=True)
    block = None
    for attempt in range(8):
        for url in RPC_URLS:
            try:
                j = post(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, timeout=40)
                block = int(j["result"], 16); break
            except Exception:
                continue
        if block:
            break
        time.sleep(1.5 * (attempt + 1))
    if block is None:
        sys.exit("no block")
    bh = hex(block)
    print(f"block {block}", flush=True)
    prog_path = os.path.join(HERE, f"era-positions-assetsin-part{part}.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {}
    prog.setdefault("block", block)
    prog.setdefault("assets", {})
    todo = [a for a in universe if a not in prog["assets"]]
    print(f"todo {len(todo)} (done {len(prog['assets'])})", flush=True)
    t0 = time.time()
    CH = 120
    for i in range(0, len(todo), CH):
        chunk = todo[i:i + CH]
        items = [(C, SEL_GETASSETSIN + pad(a)) for a in chunk]
        raws, errs = batch_calls(items, bh, max_batch=40)
        for a, raw, e in zip(chunk, raws, errs):
            if raw is None:
                prog["assets"][a] = {"err": e or "no result"}
            else:
                prog["assets"][a] = dec_addrs(raw)
        json.dump(prog, open(prog_path, "w"))
        el = time.time() - t0
        rate = (i + len(chunk)) / el if el else 0
        print(f"progress {len(prog['assets'])}/{len(universe)} ({rate:.1f} acct/s)", flush=True)
    print("SWEEP DONE", flush=True)


if __name__ == "__main__":
    main()
