"""Position/liquidation analysis for Orbit Protocol (Blast).

Reads logs/*_Borrow.json (from fetch_logs.py) to find borrower candidates, then
reads live borrow balances + account liquidity for each candidate. Writes
ci-out/positions.json (or analysis/positions.json when run locally).

Read-only, keyless RPCs (BLAST_RPC_URL honored when set).
"""
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from enumerate_live2 import words, a20, u  # noqa: E402

OUTDIR = os.environ.get("CI_OUT", HERE)

# --- RPC helpers (independent of enumerate_live2 to keep this robust) ---
import urllib.request  # noqa: E402

RPCS = []
if os.environ.get("BLAST_RPC_URL"):
    RPCS.append(os.environ["BLAST_RPC_URL"])
RPCS += ["https://81457.rpc.thirdweb.com", "https://blast-rpc.publicnode.com",
         "https://blast.drpc.org", "https://rpc.blast.io"]


def call(to, data, tries=4, timeout=20):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    for i in range(tries):
        for url in RPCS:
            try:
                req = urllib.request.Request(url, data=body, headers={
                    "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    out = json.loads(r.read())
                if "result" in out:
                    return out["result"]
                err = out.get("error") or {}
                msg = (err.get("message") or "") + str(err.get("data") or "")
                if err.get("code") == 3 or "revert" in msg.lower():
                    return "__REVERT__"
            except Exception:  # noqa: BLE001
                continue
        time.sleep(0.5 * (i + 1))
    return None


def w(a):
    return a[2:].rjust(64, "0") if isinstance(a, str) and a.startswith("0x") and len(a) == 42 else None


COMPTROLLER_OF = {}  # filled from core_state if present


def load_market_map():
    m = {}
    for f in ("core_state.json", os.path.join(OUTDIR, "core_state.json")):
        if os.path.exists(f):
            d = json.load(open(f))
            for lab, c in d.get("comptrollers", {}).items():
                for mk in c.get("markets", []):
                    m[mk.lower()] = {"comptroller": c["address"], "label": lab}
            return m
    return m


def main():
    mm = load_market_map()
    logs_dir = os.environ.get("LOG_DIR", os.path.join(HERE, "logs"))
    borrowers = {}  # market -> set
    for fn in os.listdir(logs_dir):
        if not fn.endswith("_Borrow.json"):
            continue
        market = fn.split("_")[0].lower()
        try:
            logs = json.load(open(os.path.join(logs_dir, fn)))
        except Exception:  # noqa: BLE001
            continue
        s = set()
        for lg in logs:
            try:
                d = lg["data"][2:]
                borrower = "0x" + d[24:64]
                s.add(borrower.lower())
            except Exception:  # noqa: BLE001
                continue
        borrowers[market] = s
        print(f"{market}: {len(s)} unique borrowers (from {len(logs)} Borrow events)", flush=True)

    jobs = []
    for market, bs in borrowers.items():
        comp = (mm.get(market) or {}).get("comptroller")
        for b in bs:
            jobs.append((market, b, comp))
    print(f"total borrower-market pairs: {len(jobs)}", flush=True)

    res = {}

    def work(job):
        market, b, comp = job
        bb = call(market, "0x95dd9193" + w(b))  # borrowBalanceStored(address)
        liq = call(comp, "0x5ec88c79" + w(b)) if comp else None  # getAccountLiquidity(address)
        return job, bb, liq

    with ThreadPoolExecutor(max_workers=4) as ex:
        for i, (job, bb, liq) in enumerate(ex.map(work, jobs)):
            market, b, comp = job
            key = f"{market}:{b}"
            entry = {"market": market, "borrower": b, "comptroller": comp,
                     "borrowBalanceStored": u(bb) if bb and bb != "__REVERT__" else bb}
            if liq and liq != "__REVERT__" and words(liq):
                ws = words(liq)
                entry["liq_err"] = int(ws[0], 16)
                entry["liquidity"] = int(ws[1], 16)
                entry["shortfall"] = int(ws[2], 16)
            else:
                entry["liq_raw"] = liq
            res[key] = entry
            if (i + 1) % 25 == 0:
                print(f"  {i+1}/{len(jobs)}", flush=True)

    out = {"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "borrowers_by_market": {k: sorted(v) for k, v in borrowers.items()},
           "positions": res}
    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "positions.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote positions.json", flush=True)


if __name__ == "__main__":
    main()
