#!/usr/bin/env python3
"""Full live-state dump for the MinMax Finance finding (read-only, pinned block)."""
import json, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"
PIN_BLOCK = "latest"

def rpc(method, params, retries=3):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.4)
    return {}

def call(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, PIN_BLOCK])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

def decstr(h):
    if not h: return None
    w = words(h); b = h[2:]
    if len(b) >= 128:
        off = w[0]; ln = int(b[off*2:off*2+64], 16)
        raw = bytes.fromhex(b[(off+32)*2:(off+32+ln)*2])
        try: return raw.decode()
        except Exception: return raw.hex()
    return None

POOLS = [
 ("P1_E4", "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547", ["ioBUSD","ioUSDC","ioUSDT","ioDAI"], False),
 ("P2_XIM", "0x2c1B1DE747043f7C7c8e0896EB33b09eD9ED55c5", ["XIM","ioBUSD","ioUSDC","ioUSDT"], False),
 ("P3_E3", "0xC264ED05ed2aF451732EF05C480d9e51b92a07aC", ["ioUSDC","ioUSDT","ioDAI"], False),
 ("P4_META", "0x8360D306Be83f9A992b1657Ad68fe08Ca6f2757A", ["XIM","P3-LP"], True),
 ("P5_B3", "0x09A1B7d922BcfECa097b06498Bc992A83b0BCc42", ["BUSD-bsc","USDC_b","USDT_b"], False),
 ("P6_XIM", "0xe409587F043f74e47eFB0C10aAf40808D4e037cE", ["XIM","BUSD-bsc","USDC_b","USDT_b"], False),
 ("P7_USDT", "0x074ec23e80bd1fd26b822305614fb10b97847a35", ["ioUSDT","USDT_b","USDT-matic"], False),
 ("P8_META", "0x833d89FA7dD693035678AB53Be792F6F4B352C01", ["XIM","P5-LP"], True),
 ("P9_M3", "0xdab7B4D2CA330dde50ce611E2177271fD3Eb3F5F", ["DAI-matic","USDT-matic","USDC-matic"], False),
 ("P10_META", "0x7B24cAA6a497bc79FDfBAeb8A71a38F15eB3d7F7", ["XIM","P9-LP"], True),
 ("P11_XIM", "0x73541e9ffb9F4B8d13C2E5621b1Cede1981aD0d9", ["XIM","DAI-matic","USDT-matic","USDC-matic"], False),
 ("M22_oldXIM_P5LP", "0x22CB23Cb5F5Da3547F51909fEC8b3aE83589CE07", ["XIM-old","P5-LP"], True),
 ("M55_oldXIM_P3LP", "0x55Ce939A353dFED2B898C6EFcD8994ee414df7a8", ["XIM-old","P3-LP"], True),
 ("M70_oldXIM_P9LP", "0x70CDfb660835a80BFADCc2BB0c17ac15245C9890", ["XIM-old","P9-LP"], True),
 ("M5F_ioUSDT_P9LP", "0x5F0273ABD7754EF42a4eC320c97d5Eb1e270e54c", ["ioUSDT","P9-LP"], False),
 ("M88_DAIm_P1LP", "0x886fA6ca90750ddd53E74217Be01eDF9049dAc2f", ["DAI-matic","P1-LP"], True),
 ("MA6_BUSD_P1LP", "0xA63B7e43F4cb7C4E366e5524849a8eAc1086D33e", ["BUSD-bsc","P1-LP"], True),
 ("MEd_ioUSDT_P5LP", "0xEd01d84879D56Eb4e0969007ab8aF0e1996353A2", ["ioUSDT","P5-LP"], False),
 ("A8D_io3", "0xA8D60c3574f2A3f32bA6226939Df15092DD03617", ["ioBUSD","ioUSDC","ioUSDT"], False),
]
MIMO_PAIRS = {
 "ioUSDC/WIOTX": "0x68bf247e1F763cB157b2B5F1B927DFf4522723D5",
 "WIOTX/ioBUSD": "0x2a7775e754ca239c54030d7d804c7cb49cb38567",
 "ioUSDT/WIOTX": "0xe82b7054471d3f5cc825c50350da3bca64f7be4e",
 "BUSD-bsc/WIOTX": "0x6bdefe87c4b18726002d3505b3251c89c8004c6a",
 "USDT_b/WIOTX": "0x9e774a0c1e61c415e2a9f3c020caae8701c6122e",
 "BNB-bsc/WIOTX": "0xa1313c9e020df867d90afb72a19882f5dd81a3f9",
 "DAI-matic/WIOTX": "0xd40bfd9bffc798b5183cbe27d877562fb09c8958",
 "USDT-matic/WIOTX": "0xb30ddcc6df9839669f50ec9202828826ec36ef7c",
 "MAX/WIOTX": "0xd27f9437f800d2cadfc0f687ab208dde4d1fb0a7",
 "MAX/XIM": "0xde7399ec841627bc68243832572086b9d2d41404",
}

def pool_state(t):
    name, pool, syms, paused_expected = t
    ss = words(call(pool, "0x5fd65f0f"))
    lp = addr(ss[6]) if len(ss) >= 7 else None
    toks = []
    for i in range(4):
        r = call(pool, "0x82b86600" + f"{i:064x}")
        if not r: break
        toks.append(addr(words(r)[0]))
    bals = []
    for i in range(len(toks)):
        r = call(pool, "0x91ceb3eb" + f"{i:064x}")
        bals.append(words(r)[0] if r else None)
    adm = []
    for i in range(len(toks)):
        r = call(pool, "0xef0a712f" + f"{i:064x}")
        adm.append(words(r)[0] if r else None)
    o = words(call(pool, "0x8da5cb5b"))
    pz = words(call(pool, "0x5c975abb"))
    lpsup = words(call(lp, "0x18160ddd")) if lp else []
    return {"name": name, "pool": pool, "symbols": syms[:len(toks)], "tokens": toks, "balances": bals,
            "adminFees": adm, "paused": (pz[0] if pz else None), "owner": addr(o[0]) if o else None,
            "lpToken": lp, "lpSupply": lpsup[0] if lpsup else None,
            "swapFee": ss[4] if len(ss) > 4 else None, "adminFee": ss[5] if len(ss) > 5 else None}

def pair_state(kv):
    label, p = kv
    r = words(call(p, "0x0902f1ac"))
    t0 = words(call(p, "0x0dfe1681")); t1 = words(call(p, "0xd21220a7"))
    s0 = decstr(call(addr(t0[0]), "0x95d89b41")) if t0 else None
    s1 = decstr(call(addr(t1[0]), "0x95d89b41")) if t1 else None
    return {"label": label, "pair": p, "token0": addr(t0[0]) if t0 else None, "token1": addr(t1[0]) if t1 else None,
            "symbol0": s0, "symbol1": s1, "reserve0": r[0] if r else None, "reserve1": r[1] if len(r) > 1 else None}

if __name__ == "__main__":
    bn = rpc("eth_blockNumber", {})
    PIN_BLOCK = bn.get("result", "latest")
    with ThreadPoolExecutor(max_workers=10) as ex:
        pools = list(ex.map(pool_state, POOLS))
    with ThreadPoolExecutor(max_workers=10) as ex:
        pairs = list(ex.map(pair_state, MIMO_PAIRS.items()))
    try:
        req = urllib.request.Request("https://coins.llama.fi/prices/current/coingecko:iotex",
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            iotx_usd = json.loads(r.read())["coins"]["coingecko:iotex"]["price"]
    except Exception:
        iotx_usd = None
    out = {"block": PIN_BLOCK, "iotx_usd": iotx_usd, "pools": pools, "mimo_pairs": pairs}
    dst = sys.argv[1] if len(sys.argv) > 1 else "state_dump.json"
    json.dump(out, open(dst, "w"), indent=1)
    print("block", PIN_BLOCK, "| pools", len(pools), "| pairs", len(pairs), "| iotx_usd", iotx_usd)
    for p in pools:
        print(f"  {p['name']:16s} paused={p['paused']} owner={p['owner']} bals={p['balances']} admin={p['adminFees']}")
