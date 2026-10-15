#!/usr/bin/env python3
"""Get executable on-chain prices via simulated swaps (read-only dry runs)."""
import json, base64, urllib.request, urllib.error, sys, time
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

OSMO_BASE = "https://osmosis-api.polkachu.com"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"}
UOSMO = "uosmo"
STOSMO = "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC"
AMP = "factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO"
QOSMO = "ibc/42D24879D4569CE6477B7E88206ADBFE47C222C6CAD51A54083E4A72594269FC"
BONE = "factory/osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv/boneOsmo"

def simulate_swap(signer, pk, seq, pool_id, denom_in, denom_out, amount):
    msg = {"@type": "/osmosis.poolmanager.v1beta1.MsgSwapExactAmountIn",
           "sender": signer,
           "routes": [{"pool_id": str(pool_id), "token_in_denom": denom_in, "token_out_denom": denom_out}],
           "token_in": {"denom": denom_in, "amount": str(amount)},
           "token_out_min_amount": "1"}
    body = {"tx": {"body": {"messages": [msg], "memo": "", "timeout_height": "0",
                            "extension_options": [], "non_critical_extension_options": []},
                   "auth_info": {"signer_infos": [{"public_key": {"@type": "/cosmos.crypto.secp256k1.PubKey", "key": pk},
                                                   "mode_info": {"single": {"mode": "SIGN_MODE_DIRECT"}}, "sequence": seq}],
                                 "fee": {"amount": [], "gas_limit": "0", "payer": "", "granter": ""}},
                   "signatures": [base64.b64encode(b"\x00" * 64).decode()]}}
    req = urllib.request.Request(OSMO_BASE + "/cosmos/tx/v1beta1/simulate", data=json.dumps(body).encode(), headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            d = json.loads(r.read().decode())
            # find token_out amount in events
            got = None
            for e in d.get("result", {}).get("events", []):
                a = {x["key"]: x["value"] for x in e.get("attributes", [])}
                if e.get("type") == "transfer" and a.get("recipient") == signer and a.get("sender", "").startswith("osmo1"):
                    for coin in a.get("amount", "").split(","):
                        coin = coin.strip()
                        if coin.endswith(denom_out):
                            got = int(coin[: -len(denom_out)])
            return {"ok": True, "out": got}
    except urllib.error.HTTPError as e:
        return {"ok": False, "body": e.read().decode()[:300]}
    except Exception as e:
        return {"ok": False, "err": str(e)}

def main():
    out = {}
    # use lsd_controller (7510 OSMO) as swapper
    addr, pk = SG.SIGNERS["osmosis"]["lsd_controller"]
    seq = SG.sequence("osmosis", addr)
    tests = [
        ("osmo_to_stOSMO", 1252, UOSMO, STOSMO),
        ("stOSMO_to_osmo", 1252, STOSMO, UOSMO),
        ("osmo_to_ampOSMO", 1923, UOSMO, AMP),
        ("osmo_to_qOSMO", 1590, UOSMO, QOSMO),
        ("osmo_to_boneOsmo", 1922, UOSMO, BONE),
    ]
    for name, pool, din, dout in tests:
        r = simulate_swap(addr, pk, seq, pool, din, dout, 1000000)
        out[name] = r
        print(f"{name}: {json.dumps(r)[:200]}")
        time.sleep(1)
    # CL pool state for 1252 (sqrt price)
    try:
        req = urllib.request.Request(f"{OSMO_BASE}/osmosis/concentratedliquidity/v1beta1/pools/1252", headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=25) as r:
            out["cl_pool_1252"] = json.loads(r.read().decode())
            print("cl_pool_1252:", json.dumps(out["cl_pool_1252"])[:400])
    except Exception as e:
        out["cl_pool_1252"] = {"err": str(e)}
        print("cl_pool_1252 err:", e)
    json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/prices-onchain.json", "w"), indent=1)

if __name__ == "__main__":
    main()
