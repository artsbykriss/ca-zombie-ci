#!/usr/bin/env python3
"""For every Premia V3 UnderwriterVault, ask the vault itself (getQuote, view)
whether it would underwrite a small ATM option today. A reverting oracle feed
means the vault cannot price the pair and is not reachable by the trade() path.

Read-only. RPC URL from ARB_RPC_URL (or public fallback); never printed.
"""
import json
import os
import time
import urllib.request

U = os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vault_reachability.json")
ORACLE = "0x68bda63662b16550e86ad16160625eb293ac3d5f"
USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
WBTC = "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f"
WETH = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
ARB = "0x912ce59144191c1204e64559fe8253a0e49e6548"
LINK = "0xf97f4df75117a78c1a5a0dbb814af92458539fb4"
WSTETH = "0x5979d7b546e38e414f7e9822514be443a4800529"
GMX = "0xfc5a1a6eb076a2c7ad06ed22c90d7e710e35ad0a"
MAGIC = "0x539bde0d7dbd336b79148aa742883198bbf60342"
SOL = "0x2bcc6d6cdbbdc0a4071e48bb3b969b06b3330c07"
FXS = "0x9d2f299715d94d8a7e6f5eaa8e654e8c74a988a7"
FRAX = "0x17fc002b466eec40dae837fc4be5c67993ddbd6f"
PREMIA = "0x51fc0f6660482ea73330e414efd7808811a57fa2"
OP = "0xac800fd6159c2a2cb8fc31ef74621eb430287a5a"

# vault, base, quote, isCall, [candidate strikes in whole units]
VAULTS = [
    ("0xbae43c546dfadc69576ae73c68e0694a54f08e1b", WETH, USDC, True, [2200, 2276, 2300, 2400]),
    ("0xd46993f25d298ebbcd31e941156c66f7e628a52a", WETH, USDC, False, [2200, 2276, 2300, 2400]),
    ("0x45df5ea836a15b561937ae8373ab9ee984aea531", WBTC, USDC, True, [74000, 77000, 78000, 80000]),
    ("0x6a1fc0e1c60ba6564cde4910a425f1f1a1d18c1f", WBTC, USDC, False, [74000, 77000, 78000, 80000]),
    ("0xdc631d88dbb5eb39f5c4bf8b4e5298d098912fff", ARB, USDC, True, [0.15, 0.16, 0.17]),
    ("0xbe3e229319f86f5ee96ee1dc0b6d55e8b68a439e", ARB, USDC, False, [0.15, 0.16, 0.17]),
    ("0x9c9a20b9a27b91592f7ef7622f8c4fea9f4a0c8f", LINK, USDC, True, [10, 11, 11.2, 12]),
    ("0x8cebe7380bbe5e680fa31a5fe0229f638580dbf3", LINK, USDC, False, [10, 11, 11.2, 12]),
    ("0xe0c92f15ee2947c81e8d72864ac62331baf8d77d", WSTETH, USDC, True, [2700, 2848, 2900]),
    ("0xe330c090e2a5ceb4c39d3fb1df82c773efa55dcf", WSTETH, USDC, False, [2700, 2848, 2900]),
    ("0x2e98ed9983747ab93f14503cde4cd0f1eacbd098", GMX, USDC, True, [8, 8.3, 8.5]),
    ("0xb5eca2280dd6a58c9e17f613f292cb35e5260f21", GMX, USDC, False, [8, 8.3, 8.5]),
    ("0xa181f7ce9820b074960c4ee11d5202f159c87afb", MAGIC, USDC, True, [0.07, 0.078, 0.08]),
    ("0xe56bf5a095f98c3ad93ec4c8aa0a5c9ba780b615", MAGIC, USDC, False, [0.07, 0.078, 0.08]),
    ("0x2aebd7ffd70cb191eb72a76662a04aeb6a4ee9e2", SOL, USDC, True, [88, 92, 95]),
    ("0x010aeb3ec7a6a15655c2991eb617c7d9b64baef0", SOL, USDC, False, [88, 92, 95]),
    ("0x767823505c345fa1aa315116dc5f0276f8d5c623", FXS, FRAX, True, [0.22, 0.24, 0.26]),
    ("0x469ea472d168364b2e50abb81fe5c6da142f9a62", FXS, FRAX, False, [0.22, 0.24, 0.26]),
    ("0xa8ff43e1953139a830c3df25c4a922cf985b079a", PREMIA, USDC, True, [0.004, 0.005, 0.006]),
    ("0xf1f6b7e04549976f6274917a86575d55d6e6e3c8", PREMIA, USDC, False, [0.004, 0.005, 0.006]),
    ("0xd4af4096891a45c488bd330bbea7fe5c38890613", OP, USDC, True, [0.10, 0.11, 0.12]),
    ("0xd9a6443fb26259fddd781b4f546ce57f153feee8", OP, USDC, False, [0.10, 0.11, 0.12]),
]

# maturities: 2026-11-10, 2026-11-13, 2026-11-20 (8AM UTC); try in order
MATURITIES = [1794292800, 1794556800, 1795161600]


def rpc(method, params):
    req = urllib.request.Request(
        U,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read())


def sel():
    # getQuote((address,address,address,uint256,uint256,bool),uint256,bool,address)
    return "0xfff87bbf"


def word(x):
    if isinstance(x, int):
        return hex(x)[2:].rjust(64, "0")
    return x[2:].lower().rjust(64, "0")


def calldata(base, quote, strike_e18, maturity, is_call, size_e18, taker):
    return (
        "0xfff87bbf"
        + word(base)
        + word(quote)
        + word(ORACLE)
        + word(strike_e18)
        + word(maturity)
        + word(1 if is_call else 0)
        + word(size_e18)
        + word(1)  # isBuy
        + word(taker)
    )


def main():
    out = []
    for vault, base, quote, is_call, strikes in VAULTS:
        # tiny size: for calls 1e-6 base units in 18-dec; for puts tiny contracts
        size = 10**12
        rec = {"vault": vault, "base": base, "quote": quote, "isCall": is_call, "attempts": []}
        for strike in strikes:
            ok = False
            for mat in MATURITIES:
                data = calldata(base, quote, int(strike * 1e18), mat, is_call, size, "0x" + "1" * 40)
                try:
                    d = rpc("eth_call", [{"to": vault, "data": data}, "latest"])
                    if "result" in d:
                        rec["attempts"].append(
                            {"strike": strike, "maturity": mat, "result": "QUOTE", "premium": int(d["result"], 16)}
                        )
                        ok = True
                        break
                    err = d.get("error", {})
                    rec["attempts"].append(
                        {"strike": strike, "maturity": mat, "result": "REVERT", "error": str(err.get("message"))[:120], "data": str(err.get("data"))[:80]}
                    )
                except Exception as e:  # noqa: BLE001
                    rec["attempts"].append(
                        {"strike": strike, "maturity": mat, "result": "ERR", "error": str(e)[:120]}
                    )
                time.sleep(0.05)
            if ok:
                break
        rec["writable"] = any(a["result"] == "QUOTE" for a in rec["attempts"])
        # classify the first revert
        if not rec["writable"]:
            errs = [a.get("data", "") + a.get("error", "") for a in rec["attempts"]]
            if any("7317e7c6" in e for e in errs):
                rec["reason"] = "delta/DTE bounds or insufficient funds"
            elif any("LatestRoundData" in e or "0x" == e[-2:] and "Chainlink" in e for e in errs):
                rec["reason"] = "oracle feed unavailable"
            else:
                rec["reason"] = "no quote"
        out.append(rec)
        print(vault, "writable" if rec["writable"] else "NO", rec.get("reason", ""), flush=True)
    json.dump(out, open(OUT, "w"), indent=1)


if __name__ == "__main__":
    main()
