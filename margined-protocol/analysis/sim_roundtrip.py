#!/usr/bin/env python3
"""Part 5: decisive round-trip: deposit -> redeem in ONE simulated tx; measure net out."""
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
    return r["resp"].get("result", {}).get("events", []) if r.get("ok") else None

def find_minted(ev, share_denom, recipient):
    """find amount of share_denom credited to recipient (transfer or coin_received)."""
    amts = []
    for e in ev or []:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") in ("transfer", "coin_received") and a.get("receiver") == recipient:
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                if coin.endswith(share_denom):
                    amts.append(int(coin[: -len(share_denom)]))
    return max(amts) if amts else None

def print_flows(r, label, denoms):
    print(f"\n### {label}: {'OK' if r.get('ok') else 'FAIL ' + str(r.get('body') or r.get('err'))[:350]}")
    if not r.get("ok"):
        return
    for e in events_of(r):
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") in ("transfer", "coin_received", "coin_spent", "wasm"):
            s = json.dumps(a)
            if any(d in s for d in denoms) or (e.get("type") == "wasm"):
                print(f"  [{e['type']}] {s[:280]}")

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/sim-roundtrip.json", "w"), indent=1)
    addr, pk = SG.SIGNERS["osmosis"]["deployer2"]
    seq = SG.sequence("osmosis", addr)
    taddr, tpk = SG.SIGNERS["osmosis"]["treasury"]
    tpk = tpk or SG.get_pubkey("osmosis", taddr)
    tseq = SG.sequence("osmosis", taddr)

    # --- ampOSMO round trip
    r1 = SG.simulate("osmosis", [{"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                  "funds": [{"denom": AMP, "amount": "1000000"}]}], addr, pk, seq)
    out["dep_amp"] = r1
    minted = find_minted(events_of(r1), AMP_SHARE, addr)
    print(f"dep_amp minted shares: {minted}")
    save()
    if minted:
        r2 = SG.simulate("osmosis", [
            {"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}}, "funds": [{"denom": AMP, "amount": "1000000"}]},
            {"contract": AMPOSMO_VAULT, "msg": {"redeem": {"amount": str(minted), "recipient": None}}, "funds": [{"denom": AMP_SHARE, "amount": str(minted)}]},
        ], addr, pk, seq)
        out["rt_amp"] = r2
        print_flows(r2, "rt_amp (deposit 1 ampOSMO + redeem)", [AMP, AMP_SHARE, "uosmo"])
        save()

    # --- stOSMO round trip
    r3 = SG.simulate("osmosis", [{"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                  "funds": [{"denom": STOSMO, "amount": "1000000"}]}], taddr, tpk, tseq)
    out["dep_stosmo"] = r3
    minted2 = find_minted(events_of(r3), STOSMO_SHARE, taddr)
    print(f"\ndep_stosmo minted shares: {minted2}")
    save()
    if minted2:
        r4 = SG.simulate("osmosis", [
            {"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}}, "funds": [{"denom": STOSMO, "amount": "1000000"}]},
            {"contract": STOSMO_VAULT, "msg": {"redeem": {"amount": str(minted2), "recipient": None}}, "funds": [{"denom": STOSMO_SHARE, "amount": str(minted2)}]},
        ], taddr, tpk, tseq)
        out["rt_stosmo"] = r4
        print_flows(r4, "rt_stosmo (deposit 1 stOSMO + redeem)", [STOSMO, STOSMO_SHARE, "uosmo"])
        save()
    print("done")

if __name__ == "__main__":
    main()
