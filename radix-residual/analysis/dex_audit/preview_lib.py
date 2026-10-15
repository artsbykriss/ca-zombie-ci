#!/usr/bin/env python3
"""Generic Radix Gateway PREVIEW harness (simulation only; nothing is ever submitted).

Usage: python3 preview_lib.py
Nothing is signed or submitted. Flags: use_free_credit + assume_all_signature_proofs.
"""
import json
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import ledger_state  # noqa: E402

GATEWAY = "https://mainnet.radixdlt.com"


def preview_raw(body, timeout=300, retries=3):
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(
                GATEWAY + "/transaction/preview",
                data=json.dumps(body).encode(),
                headers={"Content-Type": "application/json",
                         "User-Agent": "radix-residual-research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:  # noqa: PERF203
            try:
                msg = e.read().decode()[:800]
            except Exception:  # noqa: BLE001
                msg = ""
            last = f"HTTP {e.code}: {msg}"
            print("   preview http error:", last, file=sys.stderr)
            if e.code in (400, 500) and "Invalid" in msg:
                raise RuntimeError(last) from e
            time.sleep(2 + 2 * i)
        except Exception as e:  # noqa: BLE001
            last = e
            print(f"   preview retry {type(e).__name__}", file=sys.stderr)
            time.sleep(2 + 2 * i)
    raise RuntimeError(f"preview failed: {last}")

ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"  # sim funding source
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"


def run(manifest, tag="test", save=True):
    ls = ledger_state()
    body = {"manifest": manifest,
            "start_epoch_inclusive": ls["epoch"],
            "end_epoch_exclusive": ls["epoch"] + 2,
            "nonce": 1234567,
            "signer_public_keys": [{"key_type": "EddsaEd25519", "key_hex": "00" * 32}],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                      "skip_epoch_check": True},
            "tip_percentage": 0}
    resp = preview_raw(body)
    rc = resp.get("receipt", {})
    status = rc.get("status")
    print(f"\n===== [{tag}] status={status}")
    if status != "Succeeded":
        err = rc.get("error_message")
        print("  error:", json.dumps(err)[:600] if err else None)
    out = {"tag": tag, "status": status}
    fs = rc.get("fee_summary") or {}
    print("  cost_units:", fs.get("execution_cost_units_consumed"),
          "xrd_cost:", fs.get("xrd_total_execution_cost"),
          "storage:", fs.get("xrd_total_storage_cost"))
    out["fee_summary"] = {k: fs.get(k) for k in
                          ("execution_cost_units_consumed", "xrd_total_execution_cost",
                           "xrd_total_storage_cost", "xrd_total_royalty_cost",
                           "xrd_total_tipping_cost")}
    out["error"] = rc.get("error_message")
    # account deltas: resource_changes is a list of batches, each with resource_changes[]
    deltas = {}
    for batch in resp.get("resource_changes", []):
        for e in batch.get("resource_changes", []):
            if e.get("component_entity", {}).get("entity_address") == ACCT:
                res = e["resource_address"]
                deltas[res] = deltas.get(res, 0.0) + float(e.get("amount") or 0)
    deltas = {k: v for k, v in deltas.items() if v != 0}
    print("  ACCT net deltas:", json.dumps(deltas)[:500])
    out["acct_deltas"] = deltas
    # pool-level deltas (any component/vault)
    pdeltas = {}
    for batch in resp.get("resource_changes", []):
        for e in batch.get("resource_changes", []):
            ent = e.get("component_entity", {}).get("entity_address")
            if ent and ent != ACCT:
                key = f"{ent[:40]}|{e['resource_address'][:26]}"
                pdeltas[key] = pdeltas.get(key, 0.0) + float(e.get("amount") or 0)
    out["entity_deltas"] = pdeltas
    # resource totals (whole tx resource delta, useful for pool-level view)
    tot = {}
    for r in resp.get("resource_changes", []):
        tot[r.get("resource_address")] = r.get("total_amount") if "total_amount" in r else None
    out["totals"] = tot
    # events of interest
    names = {}
    for e in rc.get("events", []):
        n = (e.get("type") or {}).get("name")
        names[n] = names.get(n, 0) + 1
    out["event_counts"] = names
    print("  events:", names)
    for e in rc.get("events", []):
        n = (e.get("type") or {}).get("name")
        if n in ("SwapEvent", "FlashLoanEvent", "AddLiquidityEvent", "RemoveLiquidityEvent",
                 "ClaimFeesEvent", "ContributeEvent", "RedeemEvent", "DepositEvent"):
            pj = ((e.get("data") or {}).get("programmatic_json") or {})
            print(f"   {n}: {json.dumps(pj.get('fields', pj))[:300]}")
    json.dump(resp, open(f"receipts/{tag}.json", "w"), indent=1)
    return out


def swap_roundtrip(pool, res_in, res_out, amount, tag):
    """withdraw res_in -> swap -> swap back -> deposit all."""
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{res_in}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res_in}")
    Bucket("in1")
;
CALL_METHOD
    Address("{pool}")
    "swap"
    Bucket("in1")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res_out}")
    Bucket("mid")
;
CALL_METHOD
    Address("{pool}")
    "swap"
    Bucket("mid")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res_out}")
    Bucket("unused")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res_in}")
    Bucket("fin")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("fin"), Bucket("unused"))
;
'''.strip()
    return run(m, tag)


def swap_chain(pool, res_in, res_out, amount, hops, tag):
    """withdraw -> swap -> swap -> ... (hops times) -> deposit all."""
    steps = []
    cur = "in0"
    steps.append(f'CALL_METHOD\n    Address("{ACCT}")\n    "withdraw"\n    Address("{res_in}")\n    Decimal("{amount}")\n;\nTAKE_ALL_FROM_WORKTOP\n    Address("{res_in}")\n    Bucket("{cur}")\n;')
    for i in range(hops):
        steps.append(f'CALL_METHOD\n    Address("{pool}")\n    "swap"\n    Bucket("{cur}")\n;')
        steps.append(f'TAKE_ALL_FROM_WORKTOP\n    Address("{res_in}" if {i} % 2 else "{res_out}")\n    Bucket("x{i}")\n;')
        cur = f"x{i}"
    steps.append(f'CALL_METHOD\n    Address("{ACCT}")\n    "deposit"\n    Bucket("{cur}")\n;')
    return run("\n".join(steps), tag)


def getters(pool, tag):
    m = f'''
CALL_METHOD
    Address("{pool}")
    "input_fee_rate"
;
CALL_METHOD
    Address("{pool}")
    "price_sqrt"
;
CALL_METHOD
    Address("{pool}")
    "liquidity_pool"
;
'''.strip()
    return run(m, tag)


if __name__ == "__main__":
    import os
    os.makedirs("receipts", exist_ok=True)
    print("harness ok; ledger:", ledger_state())
