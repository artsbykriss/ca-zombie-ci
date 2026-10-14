#!/usr/bin/env python3
"""Concurrent single-call state reader (batches get throttled; singles don't).

Usage: python3 era-positions-fastread.py <input_accounts.json> <output.json> [workers]
input json: {"accounts": [addr, ...]}  or {"priority": [...]} or a plain list
Reads 6 getAccountSnapshot + getAccountLiquidity per account.
"""
import json, os, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

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
URLS = []
if os.environ.get("ALCHEMY_API_KEY_2"):
    URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + os.environ["ALCHEMY_API_KEY_2"])
if os.environ.get("INFURA_API_KEY"):
    URLS.append("https://zksync-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
URLS.append("https://mainnet.era.zksync.io/")


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def one_call(url, to, data, timeout=15, tries=3):
    for a in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"], None
            return None, str(j.get("error"))[:100]
        except Exception as e:
            err = str(e)[:80]
            time.sleep(0.4 * (a + 1))
    return None, err


def main():
    inp, outp = sys.argv[1], sys.argv[2]
    workers = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    d = json.load(open(inp))
    if isinstance(d, dict):
        accounts = d.get("accounts") or d.get("priority") or d.get("candidates") or []
    else:
        accounts = d
    prog = json.load(open(outp)) if os.path.exists(outp) else {"accounts": {}}
    prog.setdefault("accounts", {})
    todo = [a for a in accounts if a not in prog["accounts"]]
    print(f"todo {len(todo)} of {len(accounts)} (workers {workers})", flush=True)

    tasks = []
    for a in todo:
        for m, addr in MARKETS.items():
            tasks.append((a, m, addr, "0xc37f68e2" + pad(a)))
        tasks.append((a, "LIQ", C, "0x5ec88c79" + pad(a)))

    def work(t):
        i = work.counter
        work.counter += 1
        url = URLS[i % len(URLS)]
        a, m, addr, data = t
        raw, err = one_call(url, addr, data)
        return (a, m, raw, err)

    work.counter = 0
    t0 = time.time()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(work, t) for t in tasks]
        for f in as_completed(futs):
            a, m, raw, err = f.result()
            st = prog["accounts"].setdefault(a, {"snapshots": {}, "liquidity": None})
            if m == "LIQ":
                if raw and raw != "0x":
                    b = raw[2:]
                    st["liquidity"] = {"err": int(b[0:64], 16), "liquidity": int(b[64:128], 16), "shortfall": int(b[128:192], 16)}
                else:
                    st["liquidity"] = {"err_str": err}
            else:
                if raw and raw != "0x":
                    b = raw[2:]
                    try:
                        st["snapshots"][m] = [int(b[0:64], 16), int(b[64:128], 16), int(b[128:192], 16), int(b[192:256], 16)]
                    except Exception:
                        st["snapshots"][m] = {"err": "decode"}
                else:
                    st["snapshots"][m] = {"err": err}
            done += 1
            if done % 140 == 0:
                json.dump(prog, open(outp, "w"))
                print(f"  {done}/{len(tasks)} calls ({done/(time.time()-t0):.1f} calls/s)", flush=True)
    json.dump(prog, open(outp, "w"))
    print(f"DONE {len(prog['accounts'])} accounts in {time.time()-t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
