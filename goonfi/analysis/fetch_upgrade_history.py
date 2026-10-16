#!/usr/bin/env python3
"""Full upgrade-history pagination for GoonFi v1/v2 programdata (mainnet-beta index)."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

OUT = os.path.dirname(os.path.abspath(__file__))
RPC = "https://api.mainnet-beta.solana.com"


def call(method, params, retries=8):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for a in range(retries):
        try:
            req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out:
                e = out["error"]
                if e.get("code") in (429, -32005) or "rate" in str(e).lower() or "limit" in str(e).lower():
                    time.sleep(2.0 * (a + 1)); last = e; continue
                return out
            return out
        except Exception as ex:  # noqa
            last = str(ex); time.sleep(1.5 * (a + 1))
    return {"error": {"code": -1, "message": f"failed: {last}"}}


def all_sigs(addr, cap=2000):
    out = []
    before = None
    while True:
        params = [addr, {"limit": 1000}]
        if before:
            params[1]["before"] = before
        r = call("getSignaturesForAddress", params)
        if "result" not in r:
            print("ERR", json.dumps(r)[:200]); break
        batch = r["result"]
        out.extend(batch)
        print("  got", len(batch), "total", len(out), flush=True)
        if len(batch) < 1000 or len(out) >= cap:
            break
        before = batch[-1]["signature"]
        time.sleep(0.5)
    return out


def main():
    targets = {
        "v2": "124gUYwjVnJQ4sJsFug9gHPzPLEtwCbAQC5LkbaDgx9s",
        "v1": "2yhK81gpQoK2jGKrokGYgt7TLt1yT3DM1DSWkpCHpnML",
    }
    for label, addr in targets.items():
        print("== fetching", label, addr, flush=True)
        s = all_sigs(addr)
        with open(os.path.join(OUT, f"upgrade-history-{label}.json"), "w") as f:
            json.dump(s, f, indent=1)
        print(label, "total sigs:", len(s))
        for x in s:
            import datetime
            bt = x.get("blockTime")
            ts = datetime.datetime.utcfromtimestamp(bt).isoformat() if bt else "?"
            print("   slot", x["slot"], ts, x["signature"][:44], "err=", x.get("err") is not None)


if __name__ == "__main__":
    main()
