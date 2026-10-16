#!/usr/bin/env python3
"""Replay a REAL dijkbk keeper tx verbatim via simulateTransaction (read-only) and
inspect post-state account data to learn the write mechanism."""
import json, os, sys, base64, urllib.request, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

OUT = os.path.dirname(os.path.abspath(__file__))
RPC = os.environ.get("SOLANA_RPC_URL", "https://solana-rpc.publicnode.com")
ORACLE = "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3"


def call(method, params, retries=4):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for a in range(retries):
        try:
            req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out:
                print("rpc err:", json.dumps(out["error"])[:150]); time.sleep(1.5 * (a + 1)); continue
            return out
        except Exception as e:
            time.sleep(1.5 * (a + 1))
    return {}


def main():
    sig = sys.argv[1] if len(sys.argv) > 1 else None
    if not sig:
        # find a fresh real update tx of 7yec from a couple minutes ago
        s = call("getSignaturesForAddress", [ORACLE, {"limit": 25}])
        sig = [x["signature"] for x in s.get("result", []) if not x.get("err")][0]
    print("replaying", sig)
    r = call("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 1}])
    tx = r.get("result")
    if not tx:
        print("could not fetch tx"); return
    t = tx["transaction"]
    b64 = t[0] if isinstance(t, list) else t
    print("slot", tx["slot"])
    # simulate verbatim
    sim = call("simulateTransaction", [b64, {
        "encoding": "base64",
        "sigVerify": False,
        "replaceRecentBlockhash": True,
        "commitment": "processed",
        "accounts": {"encoding": "base64", "addresses": [ORACLE, "GHjEJbxWcT55xWCucjSRUJAxxVXD8wXsLUAToBWTUPBa"]},
    }])
    v = sim.get("result", {}).get("value", {})
    print("err:", json.dumps(v.get("err")))
    print("logs:", v.get("logs"))
    print("unitsConsumed:", v.get("unitsConsumed"))
    for i, a in enumerate(v.get("accounts", []) or []):
        if a:
            raw = base64.b64decode(a["data"][0])
            print(f"post-sim acct[{i}] data:", raw.hex())
    # also decode the instruction data of the real tx (jsonParsed)
    r2 = call("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 1}])
    jtx = r2.get("result")
    if jtx:
        for ix in jtx["transaction"]["message"]["instructions"]:
            print("real ix:", ix.get("programId"), "data:", ix.get("data"), "accs:", ix.get("accounts"))
    with open(os.path.join(OUT, "sim-replay-real-tx.json"), "w") as f:
        json.dump({"sig": sig, "slot": tx["slot"], "sim": sim}, f, indent=1)


if __name__ == "__main__":
    main()
