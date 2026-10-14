#!/usr/bin/env python3
"""Read borrowBalanceStored for a JSON list of [market, account] pairs (concurrent singles).
Usage: python3 era-positions-pairscan.py pairs.json out.json [workers]
"""
import json, os, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
URLS = []
if os.environ.get("ALCHEMY_API_KEY_2"):
    URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + os.environ["ALCHEMY_API_KEY_2"])
if os.environ.get("INFURA_API_KEY"):
    URLS.append("https://zksync-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
URLS.append("https://mainnet.era.zksync.io/")


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def one_call(url, to, data, timeout=20, tries=4):
    for a in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"], None
            return None, str(j.get("error"))[:80]
        except Exception as e:
            err = str(e)[:60]
            time.sleep(0.5 * (a + 1))
    return None, err


def main():
    pairs_path, out_path = sys.argv[1], sys.argv[2]
    workers = int(sys.argv[3]) if len(sys.argv) > 3 else 16
    pairs = [tuple(p) for p in json.load(open(pairs_path))]
    prog = json.load(open(out_path)) if os.path.exists(out_path) else {}
    todo = [p for p in pairs if f"{p[0]}|{p[1]}" not in prog]
    print(f"pairs {len(pairs)}, todo {len(todo)}", flush=True)

    def work(p):
        i = work.counter
        work.counter += 1
        m, a = p
        raw, err = one_call(URLS[i % len(URLS)], MARKETS[m], "0x95dd9193" + pad(a))
        return f"{m}|{a}", raw, err

    work.counter = 0
    t0 = time.time()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(work, p) for p in todo]
        for f in as_completed(futs):
            k, raw, err = f.result()
            prog[k] = int(raw, 16) if (raw and raw != "0x") else ({"err": err} if raw is None else 0)
            done += 1
            if done % 200 == 0:
                json.dump(prog, open(out_path, "w"))
                print(f"  {done}/{len(todo)} ({done/(time.time()-t0):.1f}/s)", flush=True)
    json.dump(prog, open(out_path, "w"))
    pos = {k: v for k, v in prog.items() if isinstance(v, int) and v > 0}
    print(f"debt>0: {len(pos)}", flush=True)
    for k, v in sorted(pos.items(), key=lambda kv: -kv[1])[:25]:
        print(f"  {v} {k}", flush=True)


if __name__ == "__main__":
    main()
