#!/usr/bin/env python3
"""Part 6: scaling verification of LSD vault round-trip profit (stOSMO 2x, ampOSMO, qOSMO, bOSMO)."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

V = {
    "stOSMO": dict(vault="osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5",
                   base="ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC",
                   share="factory/osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5/lsd-vault-1252",
                   signer="treasury", decimals=6),
    "ampOSMO": dict(vault="osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq",
                   base="factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO",
                   share="factory/osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq/locust-vault-1923",
                   signer="deployer2", decimals=6),
    "qOSMO": dict(vault="osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu",
                  base="ibc/42D24879D4569CE6477B7E88206ADBFE47C222C6CAD51A54083E4A72594269FC",
                  share="factory/osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu/locust-vault-1590",
                  signer="deployer2", decimals=6),
    "bOSMO": dict(vault="osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3",
                  base="factory/osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv/boneOsmo",
                  share="factory/osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3/locust-vault-1922",
                  signer="treasury", decimals=6),
}

def events_of(r):
    return r["resp"].get("result", {}).get("events", []) if r.get("ok") else None

def find_minted(ev, share_denom, recipient):
    amts = []
    for e in ev or []:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") in ("transfer", "coin_received") and a.get("receiver") == recipient:
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                if coin.endswith(share_denom):
                    amts.append(int(coin[: -len(share_denom)]))
    return max(amts) if amts else None

def payout_for(r, recipient, denoms):
    """sum transfers to recipient in msg_index 1 (redeem)."""
    res = {}
    for e in events_of(r) or []:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") == "transfer" and a.get("recipient") == recipient and a.get("msg_index") == "1":
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                for d in denoms:
                    if coin.endswith(d):
                        res[d] = res.get(d, 0) + int(coin[: -len(d)])
    return res

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/sim-scale.json", "w"), indent=1)
    for name, cfg in V.items():
        addr, pk = SG.SIGNERS["osmosis"][cfg["signer"]]
        pk = pk or SG.get_pubkey("osmosis", addr)
        seq = SG.sequence("osmosis", addr)
        for amt in cfg.get("amounts", [1000000, 2000000]):
            dep = SG.simulate("osmosis", [{"contract": cfg["vault"], "msg": {"deposit": {"amount": str(amt), "recipient": None}},
                                           "funds": [{"denom": cfg["base"], "amount": str(amt)}]}], addr, pk, seq)
            minted = find_minted(events_of(dep), cfg["share"], addr)
            label = f"{name}_dep{amt}"
            out[label] = {"deposit_ok": dep.get("ok"), "minted": minted, "raw": dep}
            if not dep.get("ok"):
                print(f"[{name} dep {amt}] FAIL {str(dep.get('body') or dep.get('err'))[:200]}", file=sys.stderr)
                save(); continue
            print(f"[{name} dep {amt}] minted={minted}", file=sys.stderr)
            if minted:
                rt = SG.simulate("osmosis", [
                    {"contract": cfg["vault"], "msg": {"deposit": {"amount": str(amt), "recipient": None}}, "funds": [{"denom": cfg["base"], "amount": str(amt)}]},
                    {"contract": cfg["vault"], "msg": {"redeem": {"amount": str(minted), "recipient": None}}, "funds": [{"denom": cfg["share"], "amount": str(minted)}]},
                ], addr, pk, seq)
                label2 = f"{name}_rt{amt}"
                out[label2] = {"ok": rt.get("ok"), "raw": rt}
                if rt.get("ok"):
                    pay = payout_for(rt, addr, [cfg["base"], "uosmo"])
                    out[label2]["payout"] = pay
                    print(f"[{name} rt {amt}] payout={pay}", file=sys.stderr)
                else:
                    print(f"[{name} rt {amt}] FAIL {str(rt.get('body') or rt.get('err'))[:250]}", file=sys.stderr)
            save()
    print("done")

if __name__ == "__main__":
    main()
