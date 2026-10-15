#!/usr/bin/env python3
"""Valuation + extraction optimizer for ShadeSwap pools (read-only, based on measured reserves)."""
import json

PRICES = {
    "SHD": 0.064581, "SILK": None, "stkd-SCRT": 0.018445, "SSCRT": 0.00731912,
    "sstATOM": 1.76, "sstkATOM": 1.76, "sATOM": 1.678, "sqATOM": 1.678,
    "sINJ": 7.28, "sstINJ": 7.28, "sOSMO": 0.04295394, "sstOSMO": 0.061014,
    "sJUNO": 0.0066922, "sstJUNO": 0.0066922, "sLUNA": 0.0, "sstLUNA": 0.0,
    "sJKL": 0.00053874, "sBLD": 0.00519697, "sCMST": 0.05105, "sIST": 0.954931,
    "sUSK": 0.314985, "saUSDC": 1.0, "saUSDT": 1.0, "saWETH": 2369.61,
    "saWBTC": 81213.0, "SIENNA": 0.01574366, "ALTER": 0.0000221, "spSTAKE": 0.00010833,
}

data = json.load(open("/home/heisenberg/CA/shadeswap/analysis/valuation-inputs.json"))
tokens, pairs = data["tokens"], data["pairs"]
# refresh with all-pairs file
tokens = {}
pairs = []
for line in open("/home/heisenberg/CA/shadeswap/analysis/all-pairs-states.jsonl"):
    r = json.loads(line)
    if "result" not in r:
        continue
    if r["kind"] == "token":
        ti = r["result"].get("token_info") or r["result"]
        tokens[r["address"]] = {"sym": ti.get("symbol"), "dec": ti.get("decimals")}
    if r["kind"] == "pair":
        pi = r["result"].get("get_pair_info") or r["result"]
        pairs.append({"addr": r["address"],
                      "t0": pi["pair"][0]["custom_token"]["contract_addr"],
                      "t1": pi["pair"][1]["custom_token"]["contract_addr"],
                      "a0": int(pi["amount_0"]), "a1": int(pi["amount_1"]),
                      "stable": bool(pi["pair"][2])})


def human(addr, raw):
    t = tokens[addr]
    return raw / 10 ** t["dec"]


# --- TVL table at external prices (SILK excluded -> report separately) ---
rows = []
tot_usd = 0.0
silk_total = 0.0
for p in pairs:
    s0, s1 = tokens[p["t0"]]["sym"], tokens[p["t1"]]["sym"]
    h0, h1 = human(p["t0"], p["a0"]), human(p["t1"], p["a1"])
    v0 = h0 * PRICES.get(s0, 0) if PRICES.get(s0) is not None else None
    v1 = h1 * PRICES.get(s1, 0) if PRICES.get(s1) is not None else None
    usd = (v0 or 0) + (v1 or 0)
    tot_usd += usd
    rows.append((p["addr"], s0, h0, s1, h1, usd, p["stable"]))
    if s0 == "SILK":
        silk_total += h0
    if s1 == "SILK":
        silk_total += h1

print(f"TOTAL pool reserves value (excl SILK) at external prices: ${tot_usd:,.2f}")
print(f"Total SILK in pools: {silk_total:,.2f} (valued separately)")
print()
print(f"{'pair':44s} {'t0':9s} {'amount0':>14s} {'t1':9s} {'amount1':>14s} {'USD':>10s} {'stable'}")
for r in sorted(rows, key=lambda x: -x[5]):
    print(f"{r[0]:44s} {r[1]:9s} {r[2]:14.4f} {r[3]:9s} {r[4]:14.6f} {r[5]:10.2f} {r[6]}")
