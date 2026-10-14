#!/usr/bin/env python3
"""Read-only snapshot of the CaviarNine LSU Pool component via public Radix Gateway.
Uses /transaction/preview (simulation, no commit) to read all public getters.
No secrets, no transactions. Public endpoint only."""
import json, urllib.request, sys

GW = "https://mainnet.radixdlt.com"
COMP = "component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp"
TOKVAL = "component_rdx1cz7h8j68esue87jmq4mfqpnx5403jujadewlqcn5cqxew80fwd5fgd"

def http(url, body, timeout=120):
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) read-only-research"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"')

def main():
    # resources from component fungible list
    comp_details = http(f"{GW}/state/entity/details", {"addresses": [COMP], "opt_ins": {}})
    led = comp_details["ledger_state"]["state_version"]
    resources = [i["resource_address"] for i in comp_details["items"][0]["fungible_resources"]["items"]]
    print(f"state_version={led} resources={len(resources)}", file=sys.stderr)

    lines = []
    def call(addr, method, *args):
        a = ",".join(args)
        lines.append(f'CALL_METHOD\n    Address("{addr}")\n    "{method}"\n    {a}\n;' if args else
                     f'CALL_METHOD\n    Address("{addr}")\n    "{method}"\n;')

    def run_manifest(manifest_lines, epoch, tag):
        manifest = "\n".join(manifest_lines)
        last = None
        for attempt in range(4):
            try:
                return http(f"{GW}/transaction/preview", {
                    "manifest": manifest,
                    "start_epoch_inclusive": epoch,
                    "end_epoch_exclusive": epoch + 2,
                    "nonce": 12345 + attempt,
                    "signer_public_keys": [],
                    "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                              "skip_epoch_check": True},
                }, timeout=180)
            except Exception as e:
                last = e
                print(f"  retry {tag} attempt {attempt}: {e}", file=sys.stderr)
        raise last

    def parse_vals(receipt):
        vals = []
        for o in receipt.get("output") or []:
            pj = o.get("programmatic_json", {})
            kind = pj.get("kind")
            if kind == "Decimal":
                vals.append(pj.get("value"))
            elif kind == "Enum":
                fields = pj.get("fields", [])
                if pj.get("variant_id") == "1" and fields:
                    vals.append(fields[0].get("value"))
                else:
                    vals.append(None)
            elif kind == "Bool":
                vals.append(pj.get("value"))
            else:
                vals.append(pj)
        return vals

    head_calls = [
        (COMP, "get_dex_valuation_xrd"), (COMP, "get_liquidity_token_total_supply"),
        (COMP, "get_validator_counter"), (COMP, "get_validator_pointer"),
        (COMP, "get_validator_max_before_fee"), (COMP, "get_protocol_fee"),
        (COMP, "get_liquidity_fee"), (COMP, "get_reserve_fee"),
        (COMP, "get_token_validator_address"), (COMP, "get_fee_vaults_address"),
    ]
    epoch = comp_details["ledger_state"]["epoch"]
    for addr, m in head_calls:
        call(addr, m)
    r0 = run_manifest(lines, epoch, "head")
    assert r0["receipt"]["status"] == "Succeeded", r0["receipt"]["status"]
    head = parse_vals(r0["receipt"])
    print("head ok", file=sys.stderr)

    snap_res = []
    CHUNK = 10
    for ci in range(0, len(resources), CHUNK):
        chunk = resources[ci:ci + CHUNK]
        lines = []
        for r in chunk:
            call(COMP, "get_vault_balance", f'Address("{r}")')
            call(COMP, "get_reserve_vault_balance", f'Address("{r}")')
            call(COMP, "get_price_lsu_xrd_cached", f'Address("{r}")')
            call(COMP, "get_validator_price_lsu_xrd", f'Address("{r}")')
            call(TOKVAL, "get_in_active_set", f'Address("{r}")')
        resp = run_manifest(lines, epoch, f"chunk{ci}")
        st = resp["receipt"]["status"]
        vals = parse_vals(resp["receipt"])
        if st != "Succeeded":
            print(f"chunk {ci} status {st}; fields may be partial", file=sys.stderr)
        for i, r in enumerate(chunk):
            base = i * 5
            snap_res.append({
                "resource": r,
                "vault_balance": vals[base] if base < len(vals) else None,
                "reserve_balance": vals[base + 1] if base + 1 < len(vals) else None,
                "cached_price": vals[base + 2] if base + 2 < len(vals) else None,
                "fresh_price": vals[base + 3] if base + 3 < len(vals) else None,
                "in_active_set": vals[base + 4] if base + 4 < len(vals) else None,
            })
        print(f"chunk {ci} ok ({len(chunk)} res)", file=sys.stderr)

    snap = {
        "ledger_state_version": led,
        "epoch": comp_details["ledger_state"]["epoch"],
        "head": head,
        "head_keys": ["dex_valuation_xrd", "lsu_lp_total_supply", "validator_counter",
                      "validator_pointer", "validator_max_before_fee", "protocol_fee",
                      "liquidity_fee", "reserve_fee", "token_validator", "fee_vaults"],
        "resources": snap_res,
    }
    with open("pool_state_snapshot.json", "w") as f:
        json.dump(snap, f, indent=1)
    print("wrote pool_state_snapshot.json", file=sys.stderr)

if __name__ == "__main__":
    main()
