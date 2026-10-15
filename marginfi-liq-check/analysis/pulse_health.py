#!/usr/bin/env python3
"""Program-side health oracle: simulate permissionless `lending_account_pulse_health` for any
MarginfiAccount and decode the program's OWN health cache (init + maintenance values, error
codes, was_liquidatable flag) from the emitted HealthPulseEvent.

Usage:
  python3 pulse_health.py --accounts pk1,pk2,... [--out file.json] [--workers 4]
"""
import argparse, base64, concurrent.futures as cf, hashlib, json, os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import b58decode, b58encode, rpc, get_accounts, decode_balances
from simulate_liquidate import accounts_for_bank, build_tx, COMPUTE_BUDGET
from decode_bank import decode_bank

PROGRAM = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
# System-owned funded account used purely as the simulated fee payer (sigVerify=false).
FEE_PAYER = "HYYdpVq3SDferJDUnDpL7exGwxWFtJ5AuzvwbkvLUsrU"
PULSE_DISC = hashlib.sha256(b"global:lending_account_pulse_health").digest()[:8]
PULSE_EVENT_DISC = hashlib.sha256(b"event:HealthPulseEvent").digest()[:8]
I80F48 = float(1 << 48)
HEALTHCACHE_LEN = 304


def decode_health_cache(b):
    f = lambda o: int.from_bytes(b[o:o + 16], "little", signed=True) / I80F48
    hc = {
        "asset_value_init": f(0), "liability_value_init": f(16),
        "asset_value_maint": f(32), "liability_value_maint": f(48),
        "asset_value_equity": f(64), "liability_value_equity": f(80),
        "timestamp": struct.unpack_from("<q", b, 96)[0],
        "flags": struct.unpack_from("<I", b, 104)[0],
        "mrgn_err": struct.unpack_from("<I", b, 108)[0],
        "internal_err": struct.unpack_from("<I", b, 240)[0],
        "err_index": b[244], "program_version": b[245],
        "internal_liq_err": struct.unpack_from("<I", b, 248)[0],
        "internal_bankruptcy_err": struct.unpack_from("<I", b, 252)[0],
    }
    hc["health_init"] = hc["asset_value_init"] - hc["liability_value_init"]
    hc["health_maint"] = hc["asset_value_maint"] - hc["liability_value_maint"]
    hc["health_equity"] = hc["asset_value_equity"] - hc["liability_value_equity"]
    return hc


_BANK_CACHE = {}


def get_bank(pk):
    b = _BANK_CACHE.get(pk)
    if b is None:
        b = decode_bank(get_accounts([pk])[0][3])
        _BANK_CACHE[pk] = b
    return b


def pulse(account_pk):
    ares = get_accounts([account_pk])[0]
    raw = ares[3]
    group = b58encode(raw[8:40])
    bals = decode_balances(raw)
    ais = []
    for b in bals:
        ais += accounts_for_bank(b["bank"], get_bank(b["bank"])["config"])
    metas = [(account_pk, False, True), (group, False, False)] + [(p, False, False) for p in ais]
    cb = bytes([2]) + struct.pack("<I", 1_400_000)
    tx = build_tx(FEE_PAYER, [(COMPUTE_BUDGET, [], cb), (PROGRAM, metas, PULSE_DISC)])
    try:
        res = rpc("simulateTransaction", [base64.b64encode(tx).decode(),
                  {"encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True,
                   "commitment": "processed"}], timeout=120)
    except Exception as e:
        return {"account": account_pk, "err": "SIMFAIL:" + str(e)[:120], "health": None,
                "n_balances": len(bals), "banks": [b["bank"] for b in bals], "units": None}
    val = res["value"]
    err = val.get("err")
    errcode = None
    if isinstance(err, dict) and "InstructionError" in err:
        e = err["InstructionError"][1]
        errcode = e.get("Custom") if isinstance(e, dict) else str(e)
    hc = None
    for l in val.get("logs", []):
        if l.startswith("Program data: "):
            raw_ev = base64.b64decode(l.split("Program data: ", 1)[1])
            if raw_ev[:8] == PULSE_EVENT_DISC and len(raw_ev) >= 8 + 32 + HEALTHCACHE_LEN:
                hc = decode_health_cache(raw_ev[8 + 32: 8 + 32 + HEALTHCACHE_LEN])
                break
    return {"account": account_pk, "err": errcode, "health": hc,
            "n_balances": len(bals), "banks": [b["bank"] for b in bals],
            "units": val.get("unitsConsumed")}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--accounts", required=True)
    ap.add_argument("--out", default=None)
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--resume", action="store_true")
    args = ap.parse_args()
    accts = [a for a in args.accounts.split(",") if a]
    done = {}
    if args.resume and args.out and os.path.exists(args.out):
        try:
            for r in json.load(open(args.out)):
                done[r["account"]] = r
            print(f"resuming with {len(done)} already-pulsed accounts", flush=True)
        except Exception:
            done = {}
    todo = [a for a in accts if a not in done]
    out = list(done.values())
    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        for r in ex.map(pulse, todo):
            out.append(r)
            h = r["health"]
            print(f"{r['account'][:44]:46} err={r['err']} "
                  f"maint_health={h['health_maint'] if h else None} "
                  f"init_health={h['health_init'] if h else None} "
                  f"liq_err={h['internal_liq_err'] if h else None} "
                  f"mrgn_err={h['mrgn_err'] if h else None}", flush=True)
            if args.out:
                json.dump(out, open(args.out, "w"), indent=1)
    if args.out:
        json.dump(out, open(args.out, "w"), indent=1)


if __name__ == "__main__":
    main()
