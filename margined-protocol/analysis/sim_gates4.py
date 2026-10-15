#!/usr/bin/env python3
"""Part 4: mint event extraction + deposit->redeem round-trip in one simulated tx."""
import json, base64, urllib.request, urllib.error, sys, time
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

AMPOSMO_VAULT = "osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq"
STOSMO_VAULT = "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5"
AMP = "factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO"
AMP_SHARE = "factory/osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq/locust-vault-1923"
STOSMO = "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC"
STOSMO_SHARE = "factory/osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5/lsd-vault-1252"

def events_of(r):
    if not r.get("ok"):
        return None
    return r["resp"].get("result", {}).get("events", [])

def summarize_events(ev):
    out = []
    for e in ev or []:
        t = e.get("type")
        attrs = {a["key"]: a["value"] for a in e.get("attributes", [])}
        if t in ("wasm", "transfer", "coin_received", "coin_spent", "mint", "burn", "message", "reply"):
            out.append((t, attrs))
    return out

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/sim-gates4.json", "w"), indent=1)
    addr, pk = SG.SIGNERS["osmosis"]["deployer2"]
    seq = SG.sequence("osmosis", addr)
    taddr, tpk = SG.SIGNERS["osmosis"]["treasury"]
    tpk = tpk or SG.get_pubkey("osmosis", taddr)
    tseq = SG.sequence("osmosis", taddr)

    # 1. deposit 1 ampOSMO from deployer2 -> mint amount
    r = SG.simulate("osmosis", [{"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": AMP, "amount": "1000000"}]}], addr, pk, seq)
    out["dep_amp_1"] = r
    ev = events_of(r)
    print("=== dep_amp_1 events:")
    for t, a in summarize_events(ev):
        print(f"  [{t}] {json.dumps(a)[:300]}")
    # find minted share amount
    minted = None
    for t, a in summarize_events(ev):
        if t == "wasm" and a.get("action") == "mint":
            minted = a.get("amount")
        if t == "transfer":
            print("   transfer:", json.dumps(a)[:250])
    print("   minted shares:", minted)
    save()

    # 2. round trip: deposit 1 ampOSMO + redeem that many shares (in one tx)
    if minted:
        r2 = SG.simulate("osmosis", [
            {"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}}, "funds": [{"denom": AMP, "amount": "1000000"}]},
            {"contract": AMPOSMO_VAULT, "msg": {"redeem": {"amount": minted, "recipient": None}}, "funds": [{"denom": AMP_SHARE, "amount": minted}]},
        ], addr, pk, seq)
        out["roundtrip_amp"] = r2
        print("\n=== roundtrip_amp:", "OK" if r2.get("ok") else str(r2.get("body") or r2.get("err"))[:400])
        for t, a in summarize_events(events_of(r2)):
            if t in ("wasm", "transfer", "coin_received", "coin_spent", "mint", "burn"):
                print(f"  [{t}] {json.dumps(a)[:300]}")
        save()

    # 3. deposit 1 stOSMO from treasury -> mint amount
    r3 = SG.simulate("osmosis", [{"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                  "funds": [{"denom": STOSMO, "amount": "1000000"}]}], taddr, tpk, tseq)
    out["dep_stosmo_1"] = r3
    print("\n=== dep_stosmo_1 events:")
    minted2 = None
    for t, a in summarize_events(events_of(r3)):
        print(f"  [{t}] {json.dumps(a)[:300]}")
        if t == "wasm" and a.get("action") == "mint":
            minted2 = a.get("amount")
    print("   minted shares:", minted2)
    save()
    if minted2:
        r4 = SG.simulate("osmosis", [
            {"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}}, "funds": [{"denom": STOSMO, "amount": "1000000"}]},
            {"contract": STOSMO_VAULT, "msg": {"redeem": {"amount": minted2, "recipient": None}}, "funds": [{"denom": STOSMO_SHARE, "amount": minted2}]},
        ], taddr, tpk, tseq)
        out["roundtrip_stosmo"] = r4
        print("\n=== roundtrip_stosmo:", "OK" if r4.get("ok") else str(r4.get("body") or r4.get("err"))[:400])
        for t, a in summarize_events(events_of(r4)):
            if t in ("wasm", "transfer", "coin_received", "coin_spent", "mint", "burn"):
                print(f"  [{t}] {json.dumps(a)[:300]}")
        save()
    print("part4 saved")

if __name__ == "__main__":
    main()
