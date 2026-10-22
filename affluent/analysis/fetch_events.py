#!/usr/bin/env python3
"""Fetch tonapi.io events for every Affluent/Factorial TON contract in the loss window.

READ-ONLY. Public anonymous tonapi.io v2 only.
"""
import json
import time
import sys
import os
import requests

OUT = os.path.dirname(os.path.abspath(__file__))
BASE = "https://tonapi.io/v2"

W_START = 1791763200  # 2026-10-12T00:00:00Z
W_END = 1792368000    # 2026-10-19T00:00:00Z

CONTRACTS = {
    # Pools (affluent_pool)
    "BasicPool": ("EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx", "pool"),
    "AdvancedPool": ("EQBCXQp2sSTJhvnV6DlBqhTsdNMZc_tJcXQJ5XjoWiy-OAge", "pool"),
    "StormUsdtPool": ("EQAYJdU9JFRcKAwMZv3MqD0QVjBEMGO_4mgwOJtTBOHR22ec", "pool"),
    "StormAdvancedPool": ("EQCOA3gN3Dk-ml66zux_vuia7mTIBTENKxtomD6TDgnFZXoH", "pool"),
    "StormTonPool": ("EQA3m4H3vTUOeXGW-o6AEyZxv6i79tR-i1f4XiW588HJoqND", "pool"),
    "LendingVaultPool": ("EQBQMDjWVLeX0vAUNDTRL-aA665EItLzSvONywKDHXJRCuxB", "pool"),
    "TradoorAdvancedPool": ("EQCNgBmHVBRWpMeZE7E92RM-Gecnv88LJaXAlmqn4WAfJIA9", "pool"),
    "EthenaPool": ("EQA9iTdgsPxvk08idCXQoefGqJGLTDQFy4W34AtEj7Z_25iT", "pool"),
    # MultiplyVault V1
    "GoldMultiply": ("EQBowXTtxDTSMEJbrIIcYzIvSXZ9V5HW2Oo2iSW0chUzod3d", "multiply_vault_v1"),
    "EthenaVault": ("EQD3F7Ex_uxBjxEub8FgeDoYYUSIbAUVyehCb_JSiCVL369T", "multiply_vault_v1"),
    # MultiplyVaultV2
    "TON-Multiply-1": ("EQDtxQqkgIRQQR5hWlrQxiJMtLwjR3rEYNUBbEcvPDwCs1Ng", "multiply_vault_v2"),
    "USDT-Multiply-1": ("EQBzSItiC1vpDUEftDeWDyjgMutf6CIzme16gzn9iNlolpcY", "multiply_vault_v2"),
    "Ethena-Multiply-1": ("EQDXmtbt1-WSP00tSh6N6FH-4lX7LbnrjORClmtmuZqg4Ymm", "multiply_vault_v2"),
    "Sentora-Affluent": ("EQBjpfG5fzFESWJb6K5EdjvY_yhFa6fxhcwkVff0jlK1za82", "multiply_vault_v2"),
    "Sentora-Wallet": ("EQD5O4qzJmVwuKDIfDcuM6HI7fUf1AOolgF2oiPGyqr_WZsp", "multiply_vault_v2"),
    # LendingVault
    "Factorial-USDT": ("EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW", "lending_vault"),
    "Factorial-TON": ("EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN", "lending_vault"),
    "Affluent-USDT": ("EQAc65JgiTwcoC3M1VYnQcM2Ivq4DTWOtyY2k2EaBuXsKRAZ", "lending_vault"),
    # Jetton master
    "AffluentTON-master": ("EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_", "jetton_master"),
    # Batch router
    "AffluentBatch": ("EQA2zgb-gK0JBknK5aN63dora40GmO2wRpQDhkL2cz1H2ZKq", "batch"),
}

S = requests.Session()
S.headers.update({"Accept": "application/json", "User-Agent": "affluent-readonly/1.0"})


def get(url, params=None, tries=5):
    for i in range(tries):
        try:
            r = S.get(url, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            if r.status_code == 429:
                time.sleep(3 + i * 3)
                continue
            return {"__error__": r.status_code, "__body__": r.text[:500]}
        except Exception as e:
            time.sleep(2 + i * 2)
            last = str(e)
    return {"__error__": "exception", "__body__": last}


def fetch_events(addr):
    """Paginate all events newest-first using before_lt, return (list, pages, err).

    NOTE: tonapi's `next_from` cursor is broken for this endpoint (returns the
    same page). `before_lt` (exclusive lt) paginates correctly.
    """
    evs = []
    seen = set()
    params = {"limit": 100}
    pages = 0
    err = None
    while True:
        j = get(f"{BASE}/accounts/{addr}/events", params)
        if "__error__" in j:
            err = j
            break
        batch = j.get("events", [])
        new = 0
        for e in batch:
            eid = e.get("event_id")
            if eid in seen:
                continue
            seen.add(eid)
            evs.append(e)
            new += 1
        pages += 1
        oldest_ts = min((e.get("timestamp", 0) for e in batch), default=0)
        oldest_lt = min((e.get("lt", 0) for e in batch), default=0)
        if not batch or new == 0:
            break
        if oldest_ts < W_START - 2 * 86400:
            break
        if pages > 200:
            break
        params = {"limit": 100, "before_lt": oldest_lt}
        time.sleep(0.2)
    return evs, pages, err


def main():
    all_data = {}
    summary = []
    for name, (addr, ctype) in CONTRACTS.items():
        print(f"[*] {name} {addr[:20]}...", flush=True)
        evs, pages, err = fetch_events(addr)
        inwin = [e for e in evs if W_START <= e.get("timestamp", 0) < W_END]
        all_data[name] = {
            "address": addr,
            "type": ctype,
            "pages": pages,
            "total_events": len(evs),
            "events_in_window": len(inwin),
            "err": err,
            "events": inwin,
        }
        summary.append((name, addr, len(evs), len(inwin)))
        print(f"    total={len(evs)} in_window={len(inwin)} pages={pages} err={err}", flush=True)
        with open(os.path.join(OUT, "raw_events_all.json"), "w") as f:
            json.dump(all_data, f, indent=1)

    print("\n=== SUMMARY ===")
    for name, addr, tot, iw in sorted(summary, key=lambda x: -x[3]):
        print(f"{iw:5d}  {name:22s} {addr}")


if __name__ == "__main__":
    main()
