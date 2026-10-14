#!/usr/bin/env python3
"""CaviarNine LSU Pool (Radix) - live verification job (read-only, public endpoints only).

Runs on GitHub Actions via ci/run.sh. Writes ci-out/results.json.
No secrets. No transactions: /transaction/preview is a simulation that is never submitted.
"""
import json, os, sys, time, urllib.request
from decimal import Decimal as D, getcontext

getcontext().prec = 70
GW = "https://mainnet.radixdlt.com"
POOL = "component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
LSU2 = "resource_rdx1tkwrxs8ak7narzldq4e9e0xds0rfkdn936qe4myn2e83upvfp4gc9g"
VALIDATOR = "validator_rdx1svpqafv4te3qtfhux5yxv2vyv95mp866dp9xpe28v0pvvwzhrk4vyz"
LSULP = "resource_rdx1thksg5ng70g9mmy9ne7wz0sc7auzrrwy7fmgcxzel2gvp8pj0xxfmf"
CREDIT = "resource_rdx1nt3frmqu4v57dy55e90n0k3uy352zyy89vszzamvjld6vqvr98rls9"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 read-only-research"}

def http(url, body, timeout=120, tries=7):
    last = None
    for t in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=UA)
            return json.loads(urllib.request.urlopen(req, timeout=timeout).read())
        except urllib.error.HTTPError as e:
            return json.loads(e.read())
        except Exception as e:
            last = e
            time.sleep(2 + 2 * t)
    raise last

def preview(lines, nonce, epoch):
    body = {"manifest": "\n".join(lines), "start_epoch_inclusive": epoch,
            "end_epoch_exclusive": epoch + 2, "nonce": nonce, "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True, "skip_epoch_check": True}}
    return http(f"{GW}/transaction/preview", body, timeout=180)

def outs(rc):
    vals = []
    for o in rc.get("output") or []:
        pj = o.get("programmatic_json", {})
        k = pj.get("kind")
        if k == "Decimal":
            vals.append(pj.get("value"))
        elif k == "Enum":
            f = pj.get("fields", [])
            vals.append(f[0].get("value") if pj.get("variant_id") == "1" and f else None)
        elif k == "Bool":
            vals.append(pj.get("value"))
        else:
            vals.append(pj)
    return vals

def evname(e):
    t = e.get("type", {})
    return (t.get("type_reference") or {}).get("name") or t.get("name")

def main():
    out = {"job": "caviarnine-lsu-pool live verification", "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    st = http(f"{GW}/status/gateway-status", {})
    epoch = st["ledger_state"]["epoch"]
    out["ledger_state_version"] = st["ledger_state"]["state_version"]
    out["epoch"] = epoch
    out["timestamp_utc"] = st["ledger_state"]["proposer_round_timestamp"]

    # 1. component state
    r = http(f"{GW}/state/entity/details", {"addresses": [POOL]})
    det = r["items"][0]["details"]
    fields = {f["field_name"]: f.get("value") for f in det["state"]["fields"]}
    out["component"] = {
        "address": POOL, "blueprint": det["blueprint_name"], "package": det["package_address"],
        "dex_valuation_xrd": fields.get("dex_valuation_xrd"),
        "protocol_fee": fields.get("protocol_fee"), "liquidity_fee": fields.get("liquidity_fee"),
        "reserve_fee": fields.get("reserve_fee"), "validator_counter": fields.get("validator_counter"),
        "validator_pointer": fields.get("validator_pointer"),
    }
    r2 = http(f"{GW}/state/entity/details", {"addresses": [LSULP, CREDIT]})
    for it in r2["items"]:
        out.setdefault("resources", {})[it["address"]] = it["details"].get("total_supply")

    # 2. stale-gap measurement (permissionless refresh)
    lines = [f'CALL_METHOD\n    Address("{POOL}")\n    "get_dex_valuation_xrd"\n;',
             f'CALL_METHOD\n    Address("{POOL}")\n    "update_multiple_validator_prices"\n    200u32\n;',
             f'CALL_METHOD\n    Address("{POOL}")\n    "get_dex_valuation_xrd"\n;']
    rc = preview(lines, 90001, epoch)["receipt"]
    v = outs(rc)
    if rc.get("status") == "Succeeded" and len(v) >= 2:
        gap = D(v[-1]) - D(v[0])
        out["stale_gap"] = {"before_xrd": v[0], "after_xrd": v[-1], "delta_xrd": str(gap),
                            "refresh_call": "update_multiple_validator_prices(200) - PUBLIC"}
    else:
        out["stale_gap"] = {"error": str(rc.get("error_message"))[:300]}

    # 3. sandwich simulation (stake -> add -> refresh -> remove), atomic preview
    acc = http(f"{GW}/state/entity/details", {"addresses": [ACCT]})["items"][0]
    xrd_bal = D("0")
    for f in acc["fungible_resources"]["items"]:
        if f["resource_address"] == XRD:
            xrd_bal = D(f["amount"])
    dep = min(D("1000000"), xrd_bal * D("0.9"))
    if dep > D("1000"):
        dep_s = str(dep.quantize(D("0.000001")))
        man = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{dep_s}")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{dep_s}")
    Bucket("xrd")
;
CALL_METHOD
    Address("{VALIDATOR}")
    "stake"
    Bucket("xrd")
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSU2}")
    Bucket("dep")
;
CALL_METHOD
    Address("{POOL}")
    "add_liquidity"
    Bucket("dep")
    None
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSULP}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{CREDIT}")
    Bucket("credit")
;
CALL_METHOD
    Address("{POOL}")
    "update_multiple_validator_prices"
    200u32
;
CREATE_PROOF_FROM_BUCKET_OF_ALL
    Bucket("credit")
    Proof("cp")
;
CALL_METHOD
    Address("{POOL}")
    "remove_liquidity"
    Bucket("lp")
    Address("{LSU2}")
    Some(Proof("cp"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSU2}")
    Bucket("out")
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSULP}")
    Bucket("lp2")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("out"), Bucket("lp2"), Bucket("credit"))
;
'''.strip()
        rr = preview(man.split("\n"), 90002, epoch)
        rc2 = rr.get("receipt", {})
        sim = {"capital_xrd": dep_s, "status": rc2.get("status"),
               "error": str(rc2.get("error_message") or rr.get("details") or rr.get("message"))[:400]}
        if rc2.get("status") == "Succeeded":
            fs = rc2.get("fee_summary", {})
            sim["execution_cost_units"] = fs.get("execution_cost_units_consumed")
            sim["xrd_fee_total"] = str(D(fs.get("xrd_total_execution_cost", "0")) + D(fs.get("xrd_total_finalization_cost", "0")) + D(fs.get("xrd_total_storage_cost", "0")))
            add_amt = None; recv = None; price = None
            for e in rc2.get("events", []):
                n = evname(e)
                pj = e.get("data", {}).get("programmatic_json", {})
                f = pj.get("fields", [])
                if n == "AddLiquidityEvent" and len(f) >= 2:
                    add_amt = D(f[1].get("value"))
                if n == "ValuationChangeEvent" and len(f) >= 1:
                    price = None  # updated below with removal change
                if n == "RemoveLiquidityEvent" and len(f) >= 2:
                    payout = -D(f[1].get("value"))
                    # find the valuation change emitted by the removal (last one)
                    sim["payout_lsu"] = str(payout)
                if n == "DepositEvent":
                    pjf = pj.get("fields", [])
                    if pj.get("variant_id") == "0" and len(pjf) >= 2 and pjf[0].get("value") == LSU2 and e.get("type", {}).get("emitter", {}).get("entity", {}).get("entity_address") == ACCT:
                        recv = D(pjf[1].get("value"))
            # price from the last ValuationChangeEvent: change = -amount*price
            vcevs = [e for e in rc2.get("events", []) if evname(e) == "ValuationChangeEvent"]
            if vcevs and sim.get("payout_lsu"):
                ch = D(vcevs[-1]["data"]["programmatic_json"]["fields"][0]["value"])
                if ch != 0:
                    price = -ch / D(sim["payout_lsu"])
            if add_amt is not None and recv is not None and price:
                delta = recv - add_amt
                gross = delta * price
                sim["deposited_lsu"] = str(add_amt)
                sim["received_lsu"] = str(recv)
                sim["profit_lsu"] = str(delta)
                sim["price_lsu_xrd"] = str(price)
                sim["profit_xrd_gross_fee"] = str(gross)
                sim["profit_xrd_net"] = str(gross - D(sim["xrd_fee_total"]))
            out["sandwich_simulation"] = sim
        else:
            out["sandwich_simulation"] = sim
    else:
        out["sandwich_simulation"] = {"error": "funding account balance too low"}

    out["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/results.json", "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(out, indent=1))
    return 0

if __name__ == "__main__":
    sys.exit(main())
