#!/usr/bin/env python3
"""Part 3: full event dumps for LSD vault deposit/redeem + round-trip economics."""
import json, base64, urllib.request, urllib.error, sys, time
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

AMPOSMO_VAULT = "osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq"
BOSMO_VAULT = "osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3"
STOSMO_VAULT = "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5"
AMP = "factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO"
AMP_SHARE = "factory/osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq/locust-vault-1923"
BONE = "factory/osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv/boneOsmo"
BONE_SHARE = "factory/osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3/locust-vault-1922"
STOSMO = "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC"

def dump(label, r, out):
    out[label] = r
    if r.get("ok"):
        ev = r["resp"].get("events", [])
        print(f"\n=== {label} OK gas={r['resp'].get('gas_info',{}).get('gas_used')}")
        for e in ev:
            if e.get("type") in ("wasm", "transfer", "coin_received", "coin_spent", "mint", "burn", "message"):
                attrs = {a["key"]: a["value"] for a in e.get("attributes", [])}
                if e["type"] == "message":
                    print(f"  [message] {json.dumps(attrs)[:200]}")
                elif e["type"] == "wasm":
                    print(f"  [wasm] {json.dumps(attrs)[:400]}")
                elif e["type"] in ("transfer", "coin_received", "coin_spent", "mint", "burn"):
                    print(f"  [{e['type']}] {json.dumps(attrs)[:200]}")
    else:
        print(f"\n=== {label} FAIL: {str(r.get('body') or r.get('err'))[:400]}")

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/sim-gates3.json", "w"), indent=1)
    # 1. deposit 1 ampOSMO -> minted shares?
    addr, pk = SG.SIGNERS["osmosis"]["deployer2"]
    seq = SG.sequence("osmosis", addr)
    r = SG.simulate("osmosis", [{"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": AMP, "amount": "1000000"}]}], addr, pk, seq)
    dump("dep_amp_1", r, out); save()
    # 2. redeem 1e6 ampOSMO shares (deployer2 holds them)
    r = SG.simulate("osmosis", [{"contract": AMPOSMO_VAULT, "msg": {"redeem": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": AMP_SHARE, "amount": "1000000"}]}], addr, pk, seq)
    dump("red_amp_1share", r, out); save()
    # 3. deposit 1 boneOsmo (treasury)
    taddr, tpk = SG.SIGNERS["osmosis"]["treasury"]
    tpk = tpk or SG.get_pubkey("osmosis", taddr)
    tseq = SG.sequence("osmosis", taddr)
    r = SG.simulate("osmosis", [{"contract": BOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": BONE, "amount": "1000000"}]}], taddr, tpk, tseq)
    dump("dep_bone_1", r, out); save()
    # 4. deposit 1 stOSMO (treasury) + dump
    r = SG.simulate("osmosis", [{"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": STOSMO, "amount": "1000000"}]}], taddr, tpk, tseq)
    dump("dep_stosmo_1", r, out); save()
    # 5. LSD gate tests from treasury (non-owner, non-controller)
    for label, m in [
        ("gate3_bone_update_config", {"vault_extension": {"vaultenator": {"update_config": {"new_config": {}}}}}),
        ("gate3_bone_pause", {"vault_extension": {"vaultenator": {"pause": {}}}}),
        ("gate3_bone_set_open", {"vault_extension": {"vaultenator": {"set_open": {}}}}),
        ("gate3_bone_set_route", {"vault_extension": {"vaultenator": {"set_route": {"pool_route": {}}}}}),
        ("gate3_bone_rebalance", {"vault_extension": {"vaultenator": {"rebalance": {"amount": "1"}}}}),
        ("gate3_bone_crank", {"vault_extension": {"vaultenator": {"crank": {}}}}),
        ("gate3_bone_process_withdrawal", {"vault_extension": {"vaultenator": {"process_withdrawal": {}}}}),
    ]:
        r = SG.simulate("osmosis", [{"contract": BOSMO_VAULT, "msg": m}], taddr, tpk, tseq)
        out[label] = r
        ok = r.get("ok")
        msg = "OK gas=%s" % r["resp"].get("gas_info", {}).get("gas_used") if ok else str(r.get("body") or r.get("err"))[:220]
        print(f"[{'OK' if ok else 'FAIL'}] {label}: {msg}", file=sys.stderr)
        save()
    print("part3 saved")

if __name__ == "__main__":
    main()
