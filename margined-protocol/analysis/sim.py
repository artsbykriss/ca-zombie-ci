#!/usr/bin/env python3
"""Read-only dry-run (simulate) gate + round-trip prober for Margined vaults.
Uses /cosmos/tx/v1beta1/simulate with dummy signature (no signing, no broadcast; state discarded).
"""
import json, base64, urllib.request, urllib.error, sys, time

UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"}

OSMO_BASE = "https://osmosis-api.polkachu.com"
NEUT_BASE = "https://lcd-neutron.keplr.app"

# signers: address -> pubkey (b64). All public on-chain data.
SIGNERS = {
    "osmosis": {
        "deployer": ("osmo1g8qypve6l95xmhgc0fddaecerffymsl7kn9muw", "AhNCN2tPdwGKgihV53IeuAvTN3O4kdm7qwj2vCwLTXNU"),
        "deployer2": ("osmo13y2js99t6huwdgm5z26k6ugv8l09gvckjyztgz", "A/kuWaSDHiIfd2m2Vm4hBlsU9LhMbBq4C3Lw+0PWZQXV"),
        "lsd_controller": ("osmo1x83dj67d25gjfwhfrp6qa893yjc2nr3dfcyt02", "A5c+tATl10ZUf6Sm6Do7RVjuvIguvJ3hV2abIQS1xOyz"),
    },
    "neutron": {
        "admin": ("neutron1ha2hjlce7sqp59g8xhxz2jds97x8fdw9k9wngp", None),
    },
}

def http_get(url, timeout=20):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def get_pubkey(chain, addr):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    d = http_get(f"{base}/cosmos/auth/v1beta1/accounts/{addr}")
    acc = d.get("account", {})
    pk = acc.get("pub_key")
    if pk and pk.get("@type") == "/cosmos.crypto.secp256k1.PubKey":
        return pk["key"]
    return None

def balances(chain, addr):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    d = http_get(f"{base}/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")
    return d.get("balances", [])

def sequence(chain, addr):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    d = http_get(f"{base}/cosmos/auth/v1beta1/accounts/{addr}")
    return str(d.get("account", {}).get("sequence", "0"))

def simulate(chain, msgs, signer_addr, pubkey, seq, memo=""):
    """msgs: list of dicts {contract, msg, funds}"""
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    cosmos_msgs = [{"@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
                    "sender": signer_addr, "contract": m["contract"],
                    "msg": base64.b64encode(json.dumps(m["msg"]).encode()).decode(),
                    "funds": m.get("funds", [])} for m in msgs]
    body = {"tx": {"body": {"messages": cosmos_msgs, "memo": memo,
                            "timeout_height": "0", "extension_options": [], "non_critical_extension_options": []},
                   "auth_info": {"signer_infos": [{"public_key": {"@type": "/cosmos.crypto.secp256k1.PubKey", "key": pubkey},
                                                   "mode_info": {"single": {"mode": "SIGN_MODE_DIRECT"}}, "sequence": seq}],
                                 "fee": {"amount": [], "gas_limit": "0", "payer": "", "granter": ""}},
                   "signatures": [base64.b64encode(b"\x00" * 64).decode()]}}
    data = json.dumps(body).encode()
    for attempt in range(3):
        req = urllib.request.Request(base + "/cosmos/tx/v1beta1/simulate", data=data, headers=UA)
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return {"ok": True, "resp": json.loads(r.read().decode())}
        except urllib.error.HTTPError as e:
            return {"ok": False, "http": e.code, "body": e.read().decode()[:1200]}
        except Exception as e:
            last = {"ok": False, "err": str(e)}
            time.sleep(1)
    return last

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("chain")
    ap.add_argument("signer")  # key in SIGNERS
    ap.add_argument("--msgs")  # JSON file with list of {contract,msg,funds}
    a = ap.parse_args()
    chain = a.chain
    addr, pk = SIGNERS[chain][a.signer]
    if pk is None:
        pk = get_pubkey(chain, addr)
    seq = sequence(chain, addr)
    msgs = json.load(open(a.msgs))
    r = simulate(chain, msgs, addr, pk, seq)
    print(json.dumps(r, indent=1)[:6000])

if __name__ == "__main__":
    main()
