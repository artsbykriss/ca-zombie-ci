#!/usr/bin/env python3
"""Full state pull for CaviarNine LSU Pool: vault balances (main), fresh redemption
prices, cached prices. Public Radix Gateway only; read-only previews."""
import json, urllib.request, time, sys, os

GW = "https://mainnet.radixdlt.com"
COMP = "component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) read-only-research"}

def http(url, body, timeout=45, tries=8):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=UA)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read())
        except Exception as e:
            if t == tries - 1:
                raise
            print(f"  retry {url.split('/')[-1]}: {type(e).__name__}", file=sys.stderr)
            time.sleep(2 + t)

def preview(lines, nonce):
    body = {"manifest": "\n".join(lines), "start_epoch_inclusive": EPOCH,
            "end_epoch_exclusive": EPOCH + 2, "nonce": nonce, "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True, "skip_epoch_check": True}}
    resp = http(f"{GW}/transaction/preview", body, timeout=150)
    return resp["receipt"]

def parse_vals(receipt):
    vals = []
    for o in receipt.get("output") or []:
        pj = o.get("programmatic_json", {})
        kind = pj.get("kind")
        if kind == "Decimal":
            vals.append(pj.get("value"))
        elif kind == "Enum":
            f = pj.get("fields", [])
            vals.append(f[0].get("value") if pj.get("variant_id") == "1" and f else None)
        elif kind == "Bool":
            vals.append(pj.get("value"))
        else:
            vals.append(pj)
    return vals

def main():
    global EPOCH
    status = http(f"{GW}/status/gateway-status", {})
    EPOCH = status["ledger_state"]["epoch"]
    sv = status["ledger_state"]["state_version"]
    print(f"epoch={EPOCH} state_version={sv}", file=sys.stderr)

    # 1. component vault-level aggregation
    comp = http(f"{GW}/state/entity/details", {"addresses": [COMP], "aggregation_level": "Vault"})
    item = comp["items"][0]
    resources = []
    for f in item["fungible_resources"]["items"]:
        vaults = (f.get("vaults") or {}).get("items") or []
        resources.append({"resource": f["resource_address"],
                          "vaults": [{"vault": v["vault_address"], "amount": v["amount"],
                                      "last_updated": v.get("last_updated_at_state_version")} for v in vaults]})
    print(f"component resources: {len(resources)}", file=sys.stderr)
    json.dump(resources, open("vault_level.json", "w"), indent=1)

    # 2. main vault balance via preview (authoritative get_vault_balance)
    if os.path.exists("main_vault_balances.json"):
        print("skip stage2 (cached)", file=sys.stderr); main_balances = json.load(open("main_vault_balances.json"))
    else:
      main_balances = {}
      n = 0
      CH = 25
      for i in range(0, len(resources), CH):
        lines = []
        for r in resources[i:i + CH]:
            lines.append(f'CALL_METHOD\n    Address("{COMP}")\n    "get_vault_balance"\n    Address("{r["resource"]}")\n;')
        rc = preview(lines, 5000 + n)
        st = rc["status"]
        vals = parse_vals(rc)
        print(f"main-vault batch {n}: {st} ({len(vals)} vals)", file=sys.stderr)
        for j, r in enumerate(resources[i:i + CH]):
            main_balances[r["resource"]] = vals[j] if j < len(vals) else None
        n += 1
        time.sleep(0.5)
      json.dump(main_balances, open("main_vault_balances.json", "w"), indent=1)

    # 3. LSU resource details: validator + total supply
    lsu_res = [r["resource"] for r in resources]
    if os.path.exists("lsu_info.json"):
        print("skip stage3 (cached)", file=sys.stderr); lsu_info = json.load(open("lsu_info.json"))
    else:
      lsu_info = {}
      for i in range(0, len(lsu_res), 20):
        rd = http(f"{GW}/state/entity/details", {"addresses": lsu_res[i:i + 20],
                  "opt_ins": {"explicit_metadata": ["validator"]}})
        for it in rd["items"]:
            meta = {m["key"]: m for m in (it.get("metadata", {}) or {}).get("items", [])}
            val = (meta.get("validator", {}).get("value", {}).get("typed", {}) or {}).get("value")
            lsu_info[it["address"]] = {"validator": val,
                                       "total_supply": (it.get("details", {}) or {}).get("total_supply")}
        print(f"lsu batch {i // 20}: {len(rd['items'])}", file=sys.stderr)
        time.sleep(0.4)
      json.dump(lsu_info, open("lsu_info.json", "w"), indent=1)

    # 4. validator details: stake_xrd_vault + balances
    validators = sorted(set(v["validator"] for v in lsu_info.values() if v["validator"]))
    if os.path.exists("validator_info.json"):
        print("skip stage4 (cached)", file=sys.stderr); val_info = json.load(open("validator_info.json"))
    else:
      val_info = {}
      for i in range(0, len(validators), 20):
        vd = http(f"{GW}/state/entity/details", {"addresses": validators[i:i + 20], "aggregation_level": "Vault"})
        for v in vd["items"]:
            st = (v.get("details", {}).get("state", {}) or {})
            stake_vault = (st.get("stake_xrd_vault", {}) or {}).get("entity_address")
            su = st.get("stake_unit_resource_address")
            xrd_bal = None
            for x in (v.get("fungible_resources", {}) or {}).get("items", []):
                if x["resource_address"].endswith("radxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"):
                    for vault in (x.get("vaults", {}) or {}).get("items", []):
                        if vault.get("vault_address") == stake_vault:
                            xrd_bal = vault.get("amount")
            val_info[v["address"]] = {"stake_xrd_vault": stake_vault, "stake_xrd": xrd_bal,
                                      "stake_unit": su, "state": st}
        print(f"validator batch {i // 20}: {len(vd['items'])}", file=sys.stderr)
        time.sleep(0.4)
      json.dump(val_info, open("validator_info.json", "w"), indent=1)

    # 5. fresh prices from contract getter (all 82, batches of 28)
    CH = 25
    if os.path.exists("fresh_prices.json"):
        print("skip stage5 (cached)", file=sys.stderr)
    else:
      fresh = {}
      n = 0
      for i in range(0, len(lsu_res), CH):
        lines = []
        for r in lsu_res[i:i + CH]:
            lines.append(f'CALL_METHOD\n    Address("{COMP}")\n    "get_validator_price_lsu_xrd"\n    Address("{r}")\n;')
        rc = preview(lines, 6000 + n)
        vals = parse_vals(rc)
        print(f"fresh-price batch {n}: {rc['status']} ({len(vals)} vals)", file=sys.stderr)
        for j, r in enumerate(lsu_res[i:i + CH]):
            fresh[r] = vals[j] if j < len(vals) else None
        n += 1
        time.sleep(0.5)
      json.dump(fresh, open("fresh_prices.json", "w"), indent=1)

    # 6. cached prices (all 82)
    if os.path.exists("cached_prices.json"):
        print("skip stage6 (cached)", file=sys.stderr)
    else:
      cached = {}
      n = 0
      for i in range(0, len(lsu_res), CH):
        lines = []
        for r in lsu_res[i:i + CH]:
            lines.append(f'CALL_METHOD\n    Address("{COMP}")\n    "get_price_lsu_xrd_cached"\n    Address("{r}")\n;')
        rc = preview(lines, 7000 + n)
        vals = parse_vals(rc)
        print(f"cached-price batch {n}: {rc['status']} ({len(vals)} vals)", file=sys.stderr)
        for j, r in enumerate(lsu_res[i:i + CH]):
            cached[r] = vals[j] if j < len(vals) else None
        n += 1
        time.sleep(0.5)
      json.dump(cached, open("cached_prices.json", "w"), indent=1)

    print("done", file=sys.stderr)

if __name__ == "__main__":
    main()
