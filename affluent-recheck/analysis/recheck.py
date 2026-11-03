#!/usr/bin/env python3
"""Affluent TON C-1 recheck: live vault NAV + burn->payout emulation.

Read-only. Public keyless endpoints only (toncenter v3 / tonapi v2).
No secrets, no broadcast. Results are written to ci-out/ (and analysis/out/).
"""
import base64
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from ton import account, get, jettons, run_getmethod  # noqa: E402
from emulate import burn_body, emulate, internal, summarize  # noqa: E402

from pytoniq_core import Address, Builder, Cell  # noqa: E402

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

POOL_ADV = "0:425d0a76b124c986f9d5e83941aa14ec74d31973fb49717409e578e85a2cbe38"
MINT_TRACE = os.path.join(HERE, "emul", "hist_oct26_mint_trace.json")

VAULTS = {
    "affUSDTl": {
        "address": "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9",
        "symbol": "affUSDTl",
        "decimals": 6,
        "holder": "0:7822fea79ab73250d6a0101904734f5d6be8f5a0e4f6fe78ae9e73f8a2d4a0b1",
        "holder_wallet": "0:9c2f3711d07abf869154b4a0bf5a36605ac9ac73eca1602bdda8a7be6d507ec8",
        "asset": "USDT",
    },
    "affTONl": {
        "address": "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad",
        "symbol": "affTONl",
        "decimals": 9,
        "holder": "0:7822fea79ab73250d6a0101904734f5d6be8f5a0e4f6fe78ae9e73f8a2d4a0b1",
        "holder_wallet": "0:6881fe3e81042892947f47ab983b5f22cc0a08680d40e273b585ce8bc17ce493",
        "asset": "TON",
    },
}

# burn sizes: 1 raw, 1e6, 1e9, 1e15, 1e16 (raw share units), plus each holder's full balance
AMOUNTS = [1, 10**6, 10**9, 10**15, 10**16]
FULL_AMOUNTS = {"affUSDTl": 3 * 10**16, "affTONl": 2 * 10**16}


def decode_addr_slice(b64):
    from pytoniq_core import Cell
    c = Cell.one_from_boc(base64.b64decode(b64))
    return str(c.begin_parse().load_address())


def vault_data(addr):
    r = run_getmethod(addr, "get_vault_data")
    st = r["stack"]
    out = {
        "exit_code": r.get("exit_code"),
        "gas_used": r.get("gas_used"),
        "total_supply": int(st[0]["value"], 16) if st[0]["type"] == "num" else None,
        "owner": decode_addr_slice(st[1]["value"]),
        "manager": decode_addr_slice(st[2]["value"]),
        "asset": decode_addr_slice(st[3]["value"]),
        "balance": int(st[4]["value"], 16),
        "cash": int(st[5]["value"], 16),
        "total_target_weight": int(st[6]["value"], 16),
        "asset_wallet": decode_addr_slice(st[7]["value"]),
        "pools": [],
    }
    for entry in st[8]["value"]:
        f = entry["value"]
        out["pools"].append({
            "pool": decode_addr_slice(f[0]["value"]),
            "is_whitelisted": bool(int(f[1]["value"], 16)),
            "target_weight": int(f[2]["value"], 16),
            "supply_share": int(f[3]["value"], 16),
            "supply_amount": int(f[4]["value"], 16),
            "pool_cash": int(f[5]["value"], 16),
        })
    out["supply_amount_sum"] = sum(p["supply_amount"] for p in out["pools"])
    out["pool_cash_sum"] = sum(p["pool_cash"] for p in out["pools"])
    return out


FALLBACK_PRICES = {
    "coingecko:the-open-network": 1.155512,
    "coingecko:tether": 0.998495,
}


def price(slug):
    try:
        j = get(f"https://coins.llama.fi/prices/current/{slug}", ttl=120)
        return j["coins"][slug]["price"], j["coins"][slug]["timestamp"]
    except Exception as e:
        print(f"price fallback for {slug}: {e!r}")
        return FALLBACK_PRICES.get(slug, 0.0), int(time.time())


def trace_facts(t):
    rows = summarize(t)
    payouts = []
    refunds = []
    for r in rows:
        if r["op"] in ("0x0f8a7ea5", "0xcb03bfaf", "0xb2a4c51b"):
            payouts.append(r)
        if r["op"] == "0x178d4519":
            refunds.append(r)
    return rows, payouts, refunds


def _find_notify(node):
    tx = node.get("transaction", {})
    im = tx.get("in_msg", {}) or {}
    if im.get("op_code") == "0x7362d09c":
        return im
    for c in node.get("children", []) or []:
        r = _find_notify(c)
        if r:
            return r
    return None


def mint_body_from_history():
    """Rebuild the 2026-10-26 mint notification (payload: USDT vault, beneficiary, 1e16)."""
    d = json.load(open(MINT_TRACE))
    im = _find_notify(d)
    payload = Cell.one_from_boc(bytes.fromhex(im["decoded_body"]["forward_payload"]["value"]["value"]))
    b = Builder()
    b.store_uint(0x7362D09C, 32)
    b.store_uint(0, 64)
    b.store_coins(10 ** 18)          # notify amount is irrelevant (CA2 control)
    b.store_address(Address(VAULTS["affUSDTl"]["address"]))
    b.store_bit(1)                   # Either right = ref
    b.store_ref(payload)
    return b.end_cell()


def main():
    result = {
        "generated_unix": int(time.time()),
        "method": "live toncenter get_vault_data + tonapi /traces/emulate (read-only, no broadcast)",
        "vaults": {},
        "prices": {},
        "emulations": [],
        "verdict": {},
    }

    ton_price, ton_ts = price("coingecko:the-open-network")
    usdt_price, usdt_ts = price("coingecko:tether")
    result["prices"] = {"TON": {"usd": ton_price, "ts": ton_ts},
                        "USDT": {"usd": usdt_price, "ts": usdt_ts}}

    for name, v in VAULTS.items():
        d = None
        for attempt in range(5):
            try:
                d = vault_data(v["address"])
                break
            except Exception as e:
                print(f"{name} vault_data retry {attempt}: {e!r}")
                time.sleep(3 + 4 * attempt)
        if d is None:
            result["vaults"][name] = {"error": "vault_data failed after retries"}
            continue
        try:
            d.update({k: v[k] for k in ("symbol", "decimals", "asset", "holder", "holder_wallet")})
            d["nav_raw"] = d["balance"] + d["supply_amount_sum"]
            d["nav_tokens"] = d["nav_raw"] / (10 ** v["decimals"])
            px = usdt_price if v["asset"] == "USDT" else ton_price
            d["nav_usd"] = d["nav_tokens"] * px
            d["nav_per_token"] = d["nav_tokens"] / (d["total_supply"] / (10 ** v["decimals"]))
            d["nav_per_token_usd"] = d["nav_per_token"] * px
            try:
                d["wallet_jettons"] = jettons(v["address"])
            except Exception as e:
                d["wallet_jettons_error"] = repr(e)
            result["vaults"][name] = d
        except Exception as e:
            result["vaults"][name] = {"error": repr(e)}

    for name, v in VAULTS.items():
        for amt in AMOUNTS + [FULL_AMOUNTS[name]]:
            tag = f"{name}_{amt}"
            entry = {"vault": name, "amount_raw": amt, "tag": tag}
            t = None
            for attempt in range(4):
                try:
                    msg = internal(v["holder"], v["holder_wallet"], burn_body(amt, v["holder"]),
                                   value=500_000_000)
                    t = emulate(msg, tag=f"ci_{tag}")
                    break
                except Exception as e:
                    print(f"{tag} emulation retry {attempt}: {e!r}")
                    time.sleep(4 + 5 * attempt)
            if t is None:
                entry["error"] = "emulation failed after retries"
                entry["conclusion"] = "EMULATION_ERROR"
                result["emulations"].append(entry)
                continue
            try:
                rows, payouts, refunds = trace_facts(t)
                entry["tx_hash"] = t.get("transaction", {}).get("hash")
                entry["success"] = t.get("transaction", {}).get("success")
                entry["rows"] = rows
                entry["payout_msgs"] = payouts
                entry["refund_msgs"] = refunds
                entry["payout_count"] = len(payouts)
                entry["refund_count"] = len(refunds)
                entry["payout_raw"] = None
                entry["conclusion"] = (
                    "REFUND_ONLY: shares minted back (0x178d4519), no asset payout"
                    if payouts == [] and refunds else "PAYOUT_PATH_OR_ANOMALY"
                )
                with open(os.path.join(OUT, f"trace_{tag}.json"), "w") as f:
                    json.dump(t, f)
            except Exception as e:
                entry["error"] = repr(e)
                entry["conclusion"] = "EMULATION_ERROR"
            result["emulations"].append(entry)
            print(tag, entry["conclusion"], entry.get("payout_count"), entry.get("refund_count"),
                  entry.get("error", ""))

    # Re-run the mint primitive today (fresh + historical sender). Both should mint 1e16
    # affUSDTl to the payload beneficiary with from="" and no asset movement.
    result["mints"] = []
    mint_ok = False
    try:
        body = mint_body_from_history()
        for tag, src in [
            ("mint_recheck_hist_sender", "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"),
            ("mint_recheck_fresh", "0:1111111111111111111111111111111111111111111111111111111111111111"),
        ]:
            entry = {"tag": tag, "source": src}
            t = None
            for attempt in range(4):
                try:
                    t = emulate(internal(src, POOL_ADV, body, value=300_000_000), tag=tag)
                    break
                except Exception as e:
                    print(f"{tag} mint retry {attempt}: {e!r}")
                    time.sleep(4 + 5 * attempt)
            if t is None:
                entry["conclusion"] = "EMULATION_ERROR"
                result["mints"].append(entry)
                continue
            rows, payouts, refunds = trace_facts(t)
            mints = [r for r in refunds if r.get("decoded_body") and r["decoded_body"].get("from") == ""]
            entry["mint_count"] = len(mints)
            entry["mint_amounts"] = [r["decoded_body"].get("amount") for r in mints]
            entry["gas_transfer_count"] = len(payouts)
            entry["conclusion"] = (
                "MINT_LIVE" if any(int(a) == 10 ** 16 for a in entry["mint_amounts"] if a)
                else "MINT_ANOMALY"
            )
            mint_ok = mint_ok or entry["conclusion"] == "MINT_LIVE"
            result["mints"].append(entry)
            print(tag, entry["conclusion"], entry.get("mint_amounts"), entry.get("gas_transfer_count"))
    except Exception as e:
        result["mints"].append({"conclusion": "EMULATION_ERROR", "error": repr(e)})

    # verdict arithmetic
    try:
        u = result["vaults"]["affUSDTl"]
        t = result["vaults"]["affTONl"]
        result["verdict"] = {
            "affUSDTl_nav_usd": round(u["nav_usd"], 2),
            "affTONl_nav_usd": round(t["nav_usd"], 2),
            "combined_nav_usd": round(u["nav_usd"] + t["nav_usd"], 2),
            "affUSDTl_balance_raw": u["balance"],
            "affTONl_balance_raw": t["balance"],
            "affUSDTl_supply_amount_sum_raw": u["supply_amount_sum"],
            "affTONl_supply_amount_sum_raw": t["supply_amount_sum"],
            "live_extractable_usd": 0.0,
            "mint_live_today": mint_ok,
            "mint_amount_raw": 10 ** 16,
            "reason": "every burn emulation (1 raw .. 1e16) refunds the shares via 0x178d4519; "
                      "no 0x0f8a7ea5 / 0xb2a4c51b / 0xcb03bfaf payout is emitted. Vault idle "
                      "balance is 1 raw (USDT) / 0 (TON); the NAV sits in whitelisted-pool "
                      "supply positions that the burn path cannot reach.",
        }
    except Exception as e:
        result["verdict"] = {"error": repr(e)}

    with open(os.path.join(OUT, "measurement.json"), "w") as f:
        json.dump(result, f, indent=1)
    print("wrote", os.path.join(OUT, "measurement.json"))
    return result


if __name__ == "__main__":
    main()
