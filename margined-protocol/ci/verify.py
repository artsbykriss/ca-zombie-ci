#!/usr/bin/env python3
"""
Margined Protocol (Neutron + Osmosis) — read-only live verification for CI.

What it does (NO transactions, NO signing, NO broadcast):
  1. Reads live chain state (heights, bank balances, vault config/state) from public LCDs.
  2. Runs read-only dry-runs via /cosmos/tx/v1beta1/simulate (dummy signature; state discarded)
     to reproduce the key findings:
       - LSD vault (stOSMO, ampOSMO) deposit -> redeem round trip: measures the pricing
         asymmetry that lets a fresh depositor extract value from the vault.
       - Redemption vault (TIARedemption / OSMORedemption) deposit: reverts on a `feed`
         submessage to the feedr contract -> deposits/redeems are bricked.
       - Neutron escrow: user can claim own redemptions; non-user cannot.
       - Admin gate: pause/update_config from a non-admin -> "Caller is not admin".
  3. Prices via DefiLlama coins API and writes everything to ci-out/verify.json.

The signer addresses/pubkeys used for simulation are public on-chain data; signatures are
64 zero bytes (simulation skips signature verification). Nothing is ever broadcast.
"""
import json, base64, urllib.request, urllib.error, sys, time, os, datetime

UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (zombie-research; read-only)"}
OSMO_BASE = "https://osmosis-api.polkachu.com"
NEUT_BASE = "https://lcd-neutron.keplr.app"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
OUT = os.path.join(OUT_DIR, "verify.json")

CONTRACTS = {
    "osmosis": {
        "stOSMO_vault": "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5",
        "stTIA_vault": "osmo1q3w9kedgtc8sdh7xlcr77ydv3qu7fs2e3q6xznysp2lrdfyz9xyqv26yqv",
        "ampOSMO_vault": "osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq",
        "bOSMO_vault": "osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3",
        "qOSMO_vault": "osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu",
        "OSMORedemption": "osmo15fqmdl8lfl9h0qflljd63ufw9j2m7xmsk3hu5vsn8xpta4hk5chqt7mddc",
        "TIARedemption": "osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl",
        "ATOMRedemption": "osmo1hvl5kj4xzdj4udxjv2dzk2zfqhzkd9afqygwq3t84tn53e0250zqrltj48",
        "DYDXRedemption": "osmo1grs74ux62lukjdlfs9ll4myyulcyjcd4uzwpw3cgnzdygtsspp2se2ense",
    },
    "neutron": {
        "ATOMdATOM": "neutron1f99ujxefjr4jqmskc7hvg09am6pdq2j2c5049xwl0de4cavc4rfsl866y0",
        "escrow": "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8",
        "treasury": "neutron1d9uwvv4w4n8yfnng8enl643vml4xwke63m63gl",
    },
}
SIGNERS = {
    "osmosis": {
        "treasury": "osmo1dw2yh3w85yda8qcfc07kl0pjnywz2wc04wjh5c",
        "deployer2": "osmo13y2js99t6huwdgm5z26k6ugv8l09gvckjyztgz",
    },
    "neutron": {
        "user_r6rv": "neutron1r6rv879netg009eh6ty23v57qrq29afecuehlm",
        "admin": "neutron1ha2hjlce7sqp59g8xhxz2jds97x8fdw9k9wngp",
    },
}
TOKENS = {
    "stOSMO": "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC",
    "stTIA": "ibc/D79E7D83AB399BFFF93433E54FAA480C191248FC556924A2A8351AE2638B3877",
    "ampOSMO": "factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO",
    "uosmo": "uosmo",
}
SHARES = {
    "stOSMO": "factory/osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5/lsd-vault-1252",
    "ampOSMO": "factory/osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq/locust-vault-1923",
}

def http_get(url, timeout=25):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_get(bases, path, tries=4, timeout=25):
    last = None
    for i in range(tries):
        for b in bases:
            try:
                return http_get(b + path, timeout=timeout)
            except urllib.error.HTTPError as e:
                try:
                    body = e.read().decode()
                except Exception:
                    body = ""
                last = {"_http": e.code, "_body": body[:400]}
                if e.code == 404:
                    return last
            except Exception as e:
                last = {"_err": str(e)}
        time.sleep(2)
    return last

def account(chain, addr):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    return try_get([base], f"/cosmos/auth/v1beta1/accounts/{addr}")

def pubkey_and_seq(chain, addr):
    d = account(chain, addr)
    acc = d.get("account", {})
    pk = acc.get("pub_key")
    pk = pk.get("key") if pk and pk.get("@type") == "/cosmos.crypto.secp256k1.PubKey" else None
    return pk, str(acc.get("sequence", "0"))

def simulate(chain, msgs, signer_addr, pubkey, seq):
    base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
    cosmos_msgs = [{"@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
                    "sender": signer_addr, "contract": m["contract"],
                    "msg": m["msg"], "funds": m.get("funds", [])} for m in msgs]
    body = {"tx": {"body": {"messages": cosmos_msgs, "memo": "zombie-readonly-dryrun",
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
            with urllib.request.urlopen(req, timeout=45) as r:
                return {"ok": True, "resp": json.loads(r.read().decode())}
        except urllib.error.HTTPError as e:
            return {"ok": False, "http": e.code, "body": e.read().decode()[:800]}
        except Exception as e:
            last = {"ok": False, "err": str(e)}
            time.sleep(2)
    return last

def events_of(r):
    return r["resp"].get("result", {}).get("events", []) if r.get("ok") else []

def find_minted(ev, share_denom, recipient):
    amts = []
    for e in ev:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") in ("transfer", "coin_received") and a.get("receiver") == recipient:
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                if coin.endswith(share_denom):
                    amts.append(int(coin[: -len(share_denom)]))
    return max(amts) if amts else None

def payout(ev, recipient, denoms):
    res = {}
    for e in ev:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") == "transfer" and a.get("recipient") == recipient and a.get("msg_index") == "1":
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                for d in denoms:
                    if coin.endswith(d):
                        res[d] = res.get(d, 0) + int(coin[: -len(d)])
    return res

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    out = {"generated_at_utc": datetime.datetime.utcnow().isoformat() + "Z", "readonly": True}
    def save():
        json.dump(out, open(OUT, "w"), indent=1)

    # heights
    out["heights"] = {}
    for chain, base in (("osmosis", OSMO_BASE), ("neutron", NEUT_BASE)):
        r = try_get([base], "/cosmos/base/tendermint/v1beta1/blocks/latest")
        h = r.get("block", {}).get("header", {})
        out["heights"][chain] = {"height": h.get("height"), "time": h.get("time")}
    save()

    # live balances
    out["balances"] = {}
    for chain, addrs in CONTRACTS.items():
        base = OSMO_BASE if chain == "osmosis" else NEUT_BASE
        for name, addr in addrs.items():
            r = try_get([base], f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")
            out["balances"].setdefault(chain, {})[name] = r.get("balances", r)
    save()

    # prices
    denoms = "coingecko:celestia,coingecko:cosmos,coingecko:osmosis,coingecko:stride-staked-osmo,coingecko:neutron-3"
    try:
        out["prices"] = try_get(["https://coins.llama.fi"], f"/prices/current/{denoms}")
    except Exception as e:
        out["prices"] = {"err": str(e)}
    save()

    # --- LSD vault round trips (stOSMO + ampOSMO)
    out["roundtrips"] = {}
    for token, vault_key, signer_key, amount in (("stOSMO", "stOSMO_vault", "treasury", 1000000),
                                                 ("ampOSMO", "ampOSMO_vault", "deployer2", 1000000)):
        vault = CONTRACTS["osmosis"][vault_key]
        addr = SIGNERS["osmosis"][signer_key]
        pk, seq = pubkey_and_seq("osmosis", addr)
        if not pk:
            out["roundtrips"][token] = {"skip": "no pubkey"}
            save(); continue
        base_denom, share = TOKENS[token], SHARES[token]
        dep = simulate("osmosis", [{"contract": vault, "msg": {"deposit": {"amount": str(amount), "recipient": None}},
                                    "funds": [{"denom": base_denom, "amount": str(amount)}]}], addr, pk, seq)
        minted = find_minted(events_of(dep), share, addr)
        entry = {"deposit_ok": dep.get("ok"), "minted_shares": minted,
                 "deposit_err": None if dep.get("ok") else str(dep.get("body") or dep.get("err"))[:400]}
        if dep.get("ok") and minted:
            rt = simulate("osmosis", [
                {"contract": vault, "msg": {"deposit": {"amount": str(amount), "recipient": None}}, "funds": [{"denom": base_denom, "amount": str(amount)}]},
                {"contract": vault, "msg": {"redeem": {"amount": str(minted), "recipient": None}}, "funds": [{"denom": share, "amount": str(minted)}]},
            ], addr, pk, seq)
            entry["roundtrip_ok"] = rt.get("ok")
            entry["roundtrip_err"] = None if rt.get("ok") else str(rt.get("body") or rt.get("err"))[:400]
            if rt.get("ok"):
                entry["paid"] = {base_denom: amount}
                entry["received"] = payout(events_of(rt), addr, [base_denom, "uosmo"])
        out["roundtrips"][token] = entry
        save()

    # --- Redemption vault deposits (expect feed-submessage revert)
    out["redemption_vault_deposits"] = {}
    addr = SIGNERS["osmosis"]["treasury"]
    pk, seq = pubkey_and_seq("osmosis", addr)
    for name, vault in (("OSMORedemption", CONTRACTS["osmosis"]["OSMORedemption"]),
                        ("TIARedemption", CONTRACTS["osmosis"]["TIARedemption"])):
        dep = simulate("osmosis", [{"contract": vault, "msg": {"deposit": {"amount": "1000", "recipient": None}},
                                    "funds": [{"denom": TOKENS["uosmo"] if name.startswith("OSMO") else TOKENS["stTIA"], "amount": "1000"}]}],
                       addr, pk, seq)
        out["redemption_vault_deposits"][name] = {"ok": dep.get("ok"), "err": None if dep.get("ok") else str(dep.get("body") or dep.get("err"))[:400]}
        save()

    # --- on-chain price via simulated swap (stOSMO -> OSMO), to value the round trip
    out["onchain_price"] = {}
    a = SIGNERS["osmosis"]["treasury"]
    pk4, seq4 = pubkey_and_seq("osmosis", a)
    if pk4:
        swap_msg = {"@type": "/osmosis.poolmanager.v1beta1.MsgSwapExactAmountIn",
                    "sender": a,
                    "routes": [{"pool_id": "1252", "token_in_denom": TOKENS["stOSMO"], "token_out_denom": "uosmo"}],
                    "token_in": {"denom": TOKENS["stOSMO"], "amount": "1000000"},
                    "token_out_min_amount": "1"}
        body = {"tx": {"body": {"messages": [swap_msg], "memo": "price-check",
                                "timeout_height": "0", "extension_options": [], "non_critical_extension_options": []},
                       "auth_info": {"signer_infos": [{"public_key": {"@type": "/cosmos.crypto.secp256k1.PubKey", "key": pk4},
                                                       "mode_info": {"single": {"mode": "SIGN_MODE_DIRECT"}}, "sequence": seq4}],
                                     "fee": {"amount": [], "gas_limit": "0", "payer": "", "granter": ""}},
                       "signatures": [base64.b64encode(b"\x00" * 64).decode()]}}
        try:
            req = urllib.request.Request(OSMO_BASE + "/cosmos/tx/v1beta1/simulate", data=json.dumps(body).encode(), headers=UA)
            with urllib.request.urlopen(req, timeout=45) as r:
                d = json.loads(r.read().decode())
            got = None
            for e in d.get("result", {}).get("events", []):
                at = {x["key"]: x["value"] for x in e.get("attributes", [])}
                if e.get("type") == "transfer" and at.get("recipient") == a:
                    for coin in at.get("amount", "").split(","):
                        coin = coin.strip()
                        if coin.endswith("uosmo"):
                            got = int(coin[:-5])
            out["onchain_price"]["stOSMO_to_OSMO_1"] = got
            rt = out["roundtrips"].get("stOSMO", {})
            if got and rt.get("received"):
                received_osmo_equiv = rt["received"].get(TOKENS["stOSMO"], 0) * got / 1_000_000 + rt["received"].get("uosmo", 0)
                out["roundtrips"]["stOSMO"]["received_value_in_OSMO"] = received_osmo_equiv
                out["roundtrips"]["stOSMO"]["net_OSMO"] = received_osmo_equiv - got
                out["roundtrips"]["stOSMO"]["net_pct"] = round((received_osmo_equiv - got) / got * 100, 3)
        except Exception as e:
            out["onchain_price"]["err"] = str(e)[:200]
    save()

    # --- escrow claim gating (user vs non-user)
    out["escrow"] = {}
    for who in ("user_r6rv", "admin"):
        a = SIGNERS["neutron"][who]
        pk2, seq2 = pubkey_and_seq("neutron", a)
        if not pk2:
            out["escrow"][who] = {"skip": "no pubkey"}
            save(); continue
        r = simulate("neutron", [{"contract": CONTRACTS["neutron"]["escrow"], "msg": {"claim_redemption": {"limit": 10}}}], a, pk2, seq2)
        out["escrow"][who] = {"ok": r.get("ok"), "err": None if r.get("ok") else str(r.get("body") or r.get("err"))[:300]}
        save()

    # --- admin gate on stOSMO vault (pause from treasury = non-admin)
    a = SIGNERS["osmosis"]["treasury"]
    pk3, seq3 = pubkey_and_seq("osmosis", a)
    r = simulate("osmosis", [{"contract": CONTRACTS["osmosis"]["stOSMO_vault"],
                              "msg": {"vault_extension": {"vaultenator": {"pause": {}}}}}], a, pk3, seq3)
    out["admin_gate_pause_stOSMO"] = {"ok": r.get("ok"), "err": None if r.get("ok") else str(r.get("body") or r.get("err"))[:300]}
    save()
    print(json.dumps(out, indent=1)[:4000])
    print("wrote", OUT)

if __name__ == "__main__":
    main()
