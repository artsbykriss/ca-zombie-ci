#!/usr/bin/env python3
"""Final reconciliation: friendly addresses, prices, USD totals."""
import os, json, time, requests, base64, hashlib

OUT = os.path.dirname(os.path.abspath(__file__))
S = requests.Session()
S.headers.update({"Accept": "application/json", "User-Agent": "affluent-readonly/1.0"})


def get(url, params=None, tries=4):
    for i in range(tries):
        try:
            r = S.get(url, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            time.sleep(2)
        except Exception:
            time.sleep(2)
    return None


# --- TON friendly address (bounceable EQ / non-bounceable UQ) ---
def crc16(data: bytes) -> int:
    poly, reg = 0x1021, 0
    for b in data:
        reg ^= b << 8
        for _ in range(8):
            reg = ((reg << 1) ^ poly) & 0xFFFF if reg & 0x8000 else (reg << 1) & 0xFFFF
    return reg


def friendly(raw: str, bounceable=True):
    wc, h = raw.split(":")
    payload = bytes([0x11 if bounceable else 0x51, int(wc) & 0xFF]) + bytes.fromhex(h)
    chk = crc16(payload)
    return base64.urlsafe_b64encode(payload + chk.to_bytes(2, "big")).decode().rstrip("=")


RAWS = {
    "attacker_10_16_wallet": "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2",
    "drainer_09_30_10_12_wallet": "0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1",
    "FactorialTON_affTONl_vault": "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad",
    "FactorialUSDT_affUSDTl_vault": "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9",
    "BasicPool": "0:ab1071c6e057fc4c3dcfcee1f9b454b01c10f7cf17976a8b33e3c8c62de6f08a",
    "AdvancedPool": "0:425d0a76b124c986f9d5e83941aa14ec74d31973fb49717409e578e85a2cbe38",
    "LendingVaultPool": "0:503038d654b797d2f0143434d12fe680ebae4422d2f34af38dcb02831d72510a",
    "StormUsdtPool": "0:1825d53d24545c280c0c66fdcca83d105630443063bfe26830389b5304e1d1db",
    "EthenaPool": "0:3d893760b0fc6f934f227425d0a1e7c6a8918b4c3405cb85b7e00b448fb67fdb",
    "StormAdvancedPool": "0:8e03780ddc393e9a5ebaceec7fbee89aee64c805310d2b1b68983e930e09c565",
    "forward_target_2830bdd3": "0:2830bdd386afd8f449",
}
print("=== friendly addresses ===")
friendly_map = {}
for n, a in RAWS.items():
    if a.count(":") == 1 and len(a.split(":")[1]) == 64:
        f = friendly(a)
        friendly_map[n] = {"raw": a, "friendly": f}
        print(f"{n:30s} {a}\n{'':30s} -> {f}")
    else:
        print(f"{n:30s} {a}  (short/unknown)")

# --- prices ---
print("\n=== TON price ===")
prices = {}
for label, t in [("2026-09-30", 1790726400), ("2026-10-12", 1791849600), ("2026-10-16", 1792183560)]:
    j = get(f"https://coins.llama.fi/prices/historical/{t}/coingecko:the-open-network")
    p = (j or {}).get("coins", {}).get("coingecko:the-open-network", {}).get("price")
    prices[label] = p
    print(f"  {label}: ${p}")

# --- reconciliation ---
print("\n=== RECONCILIATION ===")
TON_0930 = 505056.73
TON_1012 = 126808.75
TON_1016 = 150041.27
USDT_1016 = 13824.94
tot_ton = TON_0930 + TON_1012 + TON_1016
print(f"  09-30 TON drained : {TON_0930:>14,.2f}  x ${prices['2026-09-30']:.4f} = ${TON_0930*prices['2026-09-30']:>12,.0f}")
print(f"  10-12 TON drained : {TON_1012:>14,.2f}  x ${prices['2026-10-12']:.4f} = ${TON_1012*prices['2026-10-12']:>12,.0f}")
print(f"  10-16 TON drained : {TON_1016:>14,.2f}  x ${prices['2026-10-16']:.4f} = ${TON_1016*prices['2026-10-16']:>12,.0f}")
print(f"  10-16 USDT drained: {USDT_1016:>14,.2f}  = ${USDT_1016:,.0f}")
print(f"  TOTAL TON         : {tot_ton:>14,.2f}")
print(f"  TOTAL USD (blended): ${TON_0930*prices['2026-09-30'] + TON_1012*prices['2026-10-12'] + TON_1016*prices['2026-10-16'] + USDT_1016:,.0f}")
print(f"  reported incident : $1,053,000")

with open(os.path.join(OUT, "reconciliation.json"), "w") as f:
    json.dump({"friendly": friendly_map, "prices": prices,
               "ton_drained": {"2026-09-30": TON_0930, "2026-10-12": TON_1012, "2026-10-16": TON_1016},
               "usdt_drained_2026_10_16": USDT_1016}, f, indent=1)
