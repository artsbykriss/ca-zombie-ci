#!/usr/bin/env python3
"""Find txs that WRITE the oracle-relay accounts. Uses jsonParsed (v1-capable)."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

OUT = os.path.dirname(os.path.abspath(__file__))
RPC = os.environ.get("SOLANA_RPC_URL", "https://solana-rpc.publicnode.com")


def call(method, params, retries=4):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for a in range(retries):
        try:
            req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out:
                time.sleep(1.2 * (a + 1)); continue
            return out
        except Exception:  # noqa
            time.sleep(1.2 * (a + 1))
    return {}


def main():
    targets = sys.argv[1:] or ["7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3"]
    for target in targets:
        print(f"== scanning txs touching {target}")
        s = call("getSignaturesForAddress", [target, {"limit": 40}])
        sigs = s.get("result", [])
        for cand in sigs:
            sig = cand["signature"]
            r = call("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 1}])
            tx = r.get("result")
            if not tx:
                continue
            ka = tx["transaction"]["message"]["accountKeys"]
            entry = next((k for k in ka if k["pubkey"] == target), None)
            if entry and entry.get("writable"):
                print(f"WRITE candidate: slot {tx['slot']} sig {sig} err={tx['meta'].get('err')}")
                print("  signers:", [k["pubkey"] for k in ka if k.get("signer")])
                for ix in tx["transaction"]["message"]["instructions"]:
                    print("  top ix:", ix.get("programId"), str(ix.get("data"))[:80])
                for grp in tx["meta"].get("innerInstructions", []) or []:
                    for ix in grp["instructions"]:
                        print("  inner ix:", ix.get("programId"), str(ix.get("data"))[:80], "accs:", str(ix.get("accounts"))[:200])
                for l in tx["meta"].get("logMessages", [])[:25]:
                    print("   LOG:", l)
                with open(os.path.join(OUT, f"oracle-write-tx-{target[:6]}.json"), "w") as f:
                    json.dump(tx, f, indent=1)
                return
        print("  no writable tx found in window")


if __name__ == "__main__":
    main()
