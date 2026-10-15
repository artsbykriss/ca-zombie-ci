#!/usr/bin/env python3
"""Simulate-based gate prober for Margined contracts (read-only dry runs).
Tests: message schemas, permissionless access, and deposit->redeem round trips.
NEVER broadcasts: /cosmos/tx/v1beta1/simulate discards state; dummy signature.
"""
import json, base64, urllib.request, urllib.error, sys, time

UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"}
OSMO_BASE = "https://osmosis-api.polkachu.com"
NEUT_BASE = "https://lcd-neutron.keplr.app"

SIGNERS = {
    "osmosis": {
        "deployer": ("osmo1g8qypve6l95xmhgc0fddaecerffymsl7kn9muw", "AhNCN2tPdwGKgihV53IeuAvTN3O4kdm7qwj2vCwLTXNU"),
        "deployer2": ("osmo13y2js99t6huwdgm5z26k6ugv8l09gvckjyztgz", "A/kuWaSDHiIfd2m2Vm4hBlsU9LhMbBq4C3Lw+0PWZQXV"),
        "lsd_controller": ("osmo1x83dj67d25gjfwhfrp6qa893yjc2nr3dfcyt02", "A5c+tATl10ZUf6Sm6Do7RVjuvIguvJ3hV2abIQS1xOyz"),
        "treasury": ("osmo1dw2yh3w85yda8qcfc07kl0pjnywz2wc04wjh5c", None),
        "redemption_controller": ("osmo1pzpe5v33udccmv64w57tv6pk8cjy06rtxfmsjq", None),
    },
    "neutron": {
        "admin": ("neutron1ha2hjlce7sqp59g8xhxz2jds97x8fdw9k9wngp", None),
        "user_r6rv": ("neutron1r6rv879netg009eh6ty23v57qrq29afecuehlm", None),
        "user_fmxw": ("neutron14fmxw54lgvheyn7m0p9efpr82fac68ysph96ch", None),
    },
}
PUBKEYS = {  # cache of known pubkeys (b64), filled by lookup if None
    "osmosis": {"deployer": "AhNCN2tPdwGKgihV53IeuAvTN3O4kdm7qwj2vCwLTXNU",
                "deployer2": "A/kuWaSDHiIfd2m2Vm4hBlsU9LhMbBq4C3Lw+0PWZQXV",
                "lsd_controller": "A5c+tATl10ZUf6Sm6Do7RVjuvIguvJ3hV2abIQS1xOyz"},
}

def http_get(url, timeout=20):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def get_pubkey(chain, addr):
    if PUBKEYS.get(chain, {}).get(addr):
        return PUBKEYS[chain][addr]
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    try:
        d = http_get(f"{base}/cosmos/auth/v1beta1/accounts/{addr}")
        pk = d.get("account", {}).get("pub_key")
        if pk and pk.get("@type") == "/cosmos.crypto.secp256k1.PubKey":
            PUBKEYS.setdefault(chain, {})[addr] = pk["key"]
            return pk["key"]
    except Exception:
        pass
    return None

def sequence(chain, addr):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    for _ in range(3):
        try:
            d = http_get(f"{base}/cosmos/auth/v1beta1/accounts/{addr}")
            return str(d.get("account", {}).get("sequence", "0"))
        except Exception:
            time.sleep(1)
    return "0"

def simulate(chain, msgs, signer_addr, pubkey, seq):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    cosmos_msgs = [{"@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
                    "sender": signer_addr, "contract": m["contract"],
                    "msg": m["msg"],
                    "funds": m.get("funds", [])} for m in msgs]
    body = {"tx": {"body": {"messages": cosmos_msgs, "memo": "",
                            "timeout_height": "0", "extension_options": [], "non_critical_extension_options": []},
                   "auth_info": {"signer_infos": [{"public_key": {"@type": "/cosmos.crypto.secp256k1.PubKey", "key": pubkey},
                                                   "mode_info": {"single": {"mode": "SIGN_MODE_DIRECT"}}, "sequence": seq}],
                                 "fee": {"amount": [], "gas_limit": "0", "payer": "", "granter": ""}},
                   "signatures": [base64.b64encode(b"\x00" * 64).decode()]}}
    data = json.dumps(body).encode()
    last = None
    for attempt in range(4):
        req = urllib.request.Request(base + "/cosmos/tx/v1beta1/simulate", data=data, headers=UA)
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                return {"ok": True, "resp": json.loads(r.read().decode())}
        except urllib.error.HTTPError as e:
            return {"ok": False, "http": e.code, "body": e.read().decode()[:1500]}
        except Exception as e:
            last = {"ok": False, "err": str(e)}
            time.sleep(2)
    return last

def run_case(chain, signer, msgs, label, results):
    addr, pk = SIGNERS[chain][signer]
    pk = pk or get_pubkey(chain, addr)
    if not pk:
        results[label] = {"skip": "no pubkey for " + addr}
        return
    seq = sequence(chain, addr)
    r = simulate(chain, msgs, addr, pk, seq)
    results[label] = {"signer": addr, "msgs": msgs, "result": r}
    # summarize
    if r.get("ok"):
        ev = r["resp"].get("events", [])
        wasm_ev = [e for e in ev if e.get("type") == "wasm"]
        attrs = []
        for e in wasm_ev:
            for a in e.get("attributes", []):
                if a["key"] in ("action", "amount", "shares", "minted", "burned", "sent", "withdrawn", "penalty", "token0", "token1", "user", "redeem_amount"):
                    attrs.append(f"{a['key']}={a['value']}")
        print(f"[OK] {label}: gas={r['resp'].get('gas_info',{}).get('gas_used')} attrs={attrs[:14]}", file=sys.stderr)
    else:
        print(f"[FAIL] {label}: {str(r.get('body') or r.get('err'))[:300]}", file=sys.stderr)

def main():
    results = {}
    def save():
        json.dump(results, open("/home/heisenberg/CA/margined-protocol/analysis/sim-gates.json", "w"), indent=1)

    # ---------------- Osmosis redemption vault (TIARedemption / ATOMRedemption / OSMORedemption)
    TIAR = "osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl"
    ATOMR = "osmo1hvl5kj4xzdj4udxjv2dzk2zfqhzkd9afqygwq3t84tn53e0250zqrltj48"
    OSMR = "osmo15fqmdl8lfl9h0qflljd63ufw9j2m7xmsk3hu5vsn8xpta4hk5chqt7mddc"
    D79E = "ibc/D79E7D83AB399BFFF93433E54FAA480C191248FC556924A2A8351AE2638B3877"
    ATOM = "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2"
    UOSMO = "uosmo"

    # 1. schema discovery: bogus extension
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"__bogus__": {}}}}], "schema_TIAR_ext_bogus", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"deposit": {}}}], "schema_TIAR_deposit_empty", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"crank": {}}}}], "gate_TIAR_crank_nonadmin", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"pause": {}}}}], "gate_TIAR_pause_nonadmin", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"set_open": {}}}}], "gate_TIAR_set_open_nonadmin", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"update_config": {"new_config": {}}}}}], "gate_TIAR_update_config_nonadmin", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"withdraw_and_swap": {"withdraw_amount": "1", "min_amount_out": "0"}}}}], "gate_TIAR_withdraw_and_swap_nonctrl", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"repay": {}}}}], "gate_TIAR_repay_nonctrl", results); save()
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"vault_extension": {"set_route": {"pool_route": {}}}}}], "gate_TIAR_set_route_nonadmin", results); save()

    # 2. deposit into OSMORedemption from lsd_controller (has 7510 OSMO) -> read mint
    run_case("osmosis", "lsd_controller", [{"contract": OSMR, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                            "funds": [{"denom": UOSMO, "amount": "1000000"}]}], "dep_OSMR_1osmo", results); save()
    # 3. deposit into ATOMRedemption from deployer2 (has ~1.567 ATOM)
    run_case("osmosis", "deployer2", [{"contract": ATOMR, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                       "funds": [{"denom": ATOM, "amount": "1000000"}]}], "dep_ATOMR_1atom", results); save()
    # 4. deposit into TIARedemption from deployer2 (no stTIA; expect bank failure -> shows gate)
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                       "funds": [{"denom": D79E, "amount": "1000000"}]}], "dep_TIAR_1sttia_nofunds", results); save()
    # 5. redeem from non-holder (expect error showing redeem semantics)
    run_case("osmosis", "deployer2", [{"contract": TIAR, "msg": {"redeem": {"amount": "1000000", "recipient": None}},
                                       "funds": [{"denom": "factory/osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl/redemption-vault", "amount": "1000000"}]}], "red_TIAR_nonholder", results); save()
    print("part1 saved")
    return results

if __name__ == "__main__":
    main()
