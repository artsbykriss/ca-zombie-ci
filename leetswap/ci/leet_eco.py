#!/usr/bin/env python3
"""LEET token ecosystem checks (read-only): owner contracts, farms, other DEX markets, holders.

Uses public RPCs + GoldRush REST (key from env, never written to disk).
"""
import json, os, sys, time, urllib.request, socket

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "analysis"))
import rpcb as B

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)

LEET_OP = "0xf2f41fe10d53e15ba34e410987eb0f986ec7509f"
LEET_MANTA = "0xe650686a3b474c01fbb5ad3b07ecc44093356090"
LEET_LINEA = "0xff98dcf88d1ae42c7ebb835133ab57481d16076e"
WBNB = "0x4200000000000000000000000000000000000006"
WETH_MANTA = "0x0dc808adce2099a9f62aa87d9670745aba741746"
OWNER_OP = "0x8d326e13db0f63351a694e6cd2e309170827494c"
OWNER_MANTA = "0x151df330a47f272cdaa5c2acf57e308d5931f110"

FARM_SELS = {
    "poolLength()": "0x081e3eda",
    "totalAllocPoint()": "0x17caf6f1",
    "leetPerBlock()": "0x8ae39cac",
    "rewardPerBlock()": "0x8ae39cac",
    "owner()": "0x8da5cb5b",
    "stakingToken()": "0x72f702f3",
    "rewardToken()": "0x0a2c9d9c",
    "startBlock()": "0x48cd4cb1",
    "endBlock()": "0x083c6323",
    "bonusEndBlock()": "0x6c0a24d9",
    "totalStaked()": "0x817b1cd2",
    "pendingLeet(address)": "0xac1e50a8",
}
FARM_SELS2 = {
    "pendingReward(address)": "0xf40f0f52",
    "pending(address)": "0x44e7b4a1",
    "userInfo(uint256,address)": "0x93f1a40b",
    "poolInfo(uint256)": "0x1526fe27",
    "rewardToken()": "0x0a2c9d9c",
}

# candidate DEX factories on opBNB / Manta
OPBNB_FACTORIES = {
    "pancake_v2": "0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E",
    "thena_v2": "0x9f3E6B0e0a0e0a0e0a0e0a0e0a0e0a0e0a0e0a0e",
    "leetswap_univ2": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
    "uniswap_v2_style_1": "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
}
MANTA_FACTORIES = {
    "leetswap_univ2": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
}
SEL_GETPAIR = "0xe6a43905"


def goldrush_holders(chain, token):
    key = os.environ.get("GOLD_RUSH_API_KEY", "")
    if not key:
        return {"error": "no key"}
    url = f"https://api.covalenthq.com/v1/{chain}/tokens/{token}/token_holders_v2/?page-size=25"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0",
                                               "Authorization": f"Bearer {key}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            d = json.loads(r.read().decode())
        items = ((d.get("data") or {}).get("items") or [])
        return {"items": [{"address": x.get("address"), "balance": x.get("balance"),
                           "share": x.get("share")} for x in items]}
    except Exception as e:
        return {"error": str(e)[:150]}


def probe_contract(chain, addr, sels):
    out = {}
    try:
        r = B.batch(chain, [("eth_call", [{"to": addr, "data": s}, "latest"]) for s in sels.values()])
        for (name, _), v in zip(sels.items(), r):
            if v and v != "0x":
                ws = B.words(v)
                out[name] = B.dec_uint(ws[0]) if len(v) == 66 else v[:80]
            else:
                out[name] = None
    except Exception as e:
        out["err"] = str(e)[:120]
    return out


def main():
    out = {}
    # ---- opBNB
    res = {}
    try:
        res["leet_owner_contract_code_size"] = len(B.code("op_bnb", OWNER_OP) or "0x") // 2 - 1
        res["owner_probes"] = probe_contract("op_bnb", OWNER_OP, FARM_SELS)
        res["owner_probes2"] = probe_contract("op_bnb", OWNER_OP, FARM_SELS2)
        gp = {}
        for name, f in OPBNB_FACTORIES.items():
            try:
                v = B.batch("op_bnb", [("eth_call", [{"to": f, "data": SEL_GETPAIR + B.pad_addr(LEET_OP) + B.pad_addr(WBNB)}, "latest"])])[0]
                gp[name] = B.dec_addr(B.words(v)[0]) if v and v != "0x" else v
            except Exception as e:
                gp[name] = f"ERR:{str(e)[:60]}"
        res["getPair_LEET_WBNB"] = gp
        res["holders"] = goldrush_holders("bnb-opbnb-mainnet", LEET_OP)
    except Exception as e:
        res["err"] = str(e)[:200]
    out["op_bnb"] = res
    print("opBNB:", json.dumps(res)[:800], flush=True)

    # ---- manta
    res = {}
    try:
        res["leet_owner_contract_code_size"] = len(B.code("manta", OWNER_MANTA) or "0x") // 2 - 1
        res["owner_probes"] = probe_contract("manta", OWNER_MANTA, FARM_SELS)
        res["owner_probes2"] = probe_contract("manta", OWNER_MANTA, FARM_SELS2)
        gp = {}
        for name, f in MANTA_FACTORIES.items():
            try:
                v = B.batch("manta", [("eth_call", [{"to": f, "data": SEL_GETPAIR + B.pad_addr(LEET_MANTA) + B.pad_addr(WETH_MANTA)}, "latest"])])[0]
                gp[name] = B.dec_addr(B.words(v)[0]) if v and v != "0x" else v
            except Exception as e:
                gp[name] = f"ERR:{str(e)[:60]}"
        res["getPair_LEET_WETH"] = gp
        res["holders"] = goldrush_holders("manta-mainnet", LEET_MANTA)
    except Exception as e:
        res["err"] = str(e)[:200]
    out["manta"] = res
    print("manta:", json.dumps(res)[:800], flush=True)

    json.dump(out, open(os.path.join(OUT, "leet-eco.json"), "w"), indent=1)
    print("wrote ci-out/leet-eco.json", flush=True)


if __name__ == "__main__":
    main()
