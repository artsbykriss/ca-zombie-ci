#!/usr/bin/env python3
"""
Liquid Driver (Fantom + BSC) live-state enumeration — READ ONLY.
Uses only keyless public RPC endpoints. No transactions.
Outputs: analysis/live-state.json, analysis/prices.json
"""
import json, time, sys, urllib.request, subprocess, socket

# force IPv4 (this host has no IPv6 route; urllib otherwise stalls on AAAA)
_orig_gai = socket.getaddrinfo
def _gai4(host, port, family=0, type=0, proto=0, flags=0):
    return _orig_gai(host, port, socket.AF_INET, type, proto, flags)
socket.getaddrinfo = _gai4

FANTOM = "https://fantom.drpc.org"
BSC = "https://bsc-rpc.publicnode.com"
RPC = {"fantom": FANTOM, "bsc": BSC}
RPC_FALLBACK = {"fantom": ["https://fantom.rpc.thirdweb.com", "https://rpc2.fantom.network"],
                "bsc": ["https://bsc.publicnode.com"]}
CHUNK = 3
OUT = "/home/heisenberg/CA/liquid-driver/analysis/live-state.json"

def _post_urllib(url, payload, timeout=25):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        url, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def _post_curl(url, payload, timeout=25):
    p = subprocess.run(["curl", "-s", "-m", str(timeout), "-X", "POST",
                        "-H", "Content-Type: application/json", "-A", "Mozilla/5.0",
                        "--data-binary", "@-", url],
                       input=json.dumps(payload).encode(), capture_output=True)
    return json.loads(p.stdout.decode())

def _post(url, payload, timeout=25):
    try:
        return _post_urllib(url, payload, timeout)
    except Exception:
        return _post_curl(url, payload, timeout)

def rpc_batch(chain, calls, retries=3):
    results = []
    for i in range(0, len(calls), CHUNK):
        results.extend(_rpc_batch_chunk(chain, calls[i:i+CHUNK], retries))
    return results

def _rpc_batch_chunk(chain, calls, retries=3):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
               for i, (m, p) in enumerate(calls)]
    urls = [RPC[chain]] + RPC_FALLBACK[chain]
    for attempt in range(retries):
        for url in urls:
            try:
                out = _post(url, payload)
                if not isinstance(out, list):
                    continue
                res = [None] * len(calls)
                for item in out:
                    i = item["id"]
                    res[i] = item.get("result", item.get("error"))
                return res
            except Exception:
                time.sleep(0.5 * (attempt + 1))
    # singles fallback
    res = []
    for m, p in calls:
        val = None
        for url in urls:
            try:
                out = _post(url, {"jsonrpc": "2.0", "id": 1, "method": m, "params": p})
                val = out.get("result", out.get("error"))
                break
            except Exception:
                pass
        res.append(val)
    return res

def call(chain, to, sig, args=None):
    return rpc_batch(chain, [("eth_call", [{"to": to, "data": sig + (args or "")}, "latest"])])[0]

def call_many(chain, items):
    calls = [("eth_call", [{"to": t, "data": s + (a or "")}, "latest"]) for (t, s, a) in items]
    return rpc_batch(chain, calls)

def addr_result(h):
    if not isinstance(h, str) or len(h) < 42:
        return None
    return "0x" + h[-40:]

def int_result(h, default=None):
    if not isinstance(h, str):
        return default
    if h == "0x":
        return default
    try:
        return int(h, 16)
    except Exception:
        return default

def pad32(h):
    return h[2:].rjust(64, "0") if h and h.startswith("0x") else h

def enc_addr(a):
    return a[2:].lower().rjust(64, "0")

def enc_uint(n):
    return hex(n)[2:].rjust(64, "0")

SEL = {
    "poolLength": "0x081e3eda",
    "poolInfo(uint256)": "0x1526fe27",
    "lpToken(uint256)": "0x78ed5d1f",
    "strategies(uint256)": "0xd574ea3d",
    "balanceOf(address)": "0x70a08231",
    "totalSupply": "0x18160ddd",
    "token0": "0x0dfe1681",
    "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac",
    "decimals": "0x313ce567",
    "symbol": "0x95d89b41",
    "exchangeRateStored": "0x182df0f5",
    "lpToken()": "0x5fcbd285",
    "strategy()": "0xa8c62e76",
    "owner": "0x8da5cb5b",
    "lqdr": "0x2b0d9c85",   # lqdr() selector? verify in source; harmless if wrong
}

MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
MINI_FTM = "0x6e2ad6527901c9664f016466b8da1357a004db0f"
MINI_BSC = "0xd46db083de31c64af3f680f139a31ff37bac004f"
XL = "0x3ae658656d1c526144db371faef2fff7170654ee"
LQDR = "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9"
SHADOW = [
    "0x59ab3c33e75C91B2B632d51144e57293EF64E556", "0xDC5bDd3966884a2b1cfFd4213DaE925778786f97",
    "0xFfa8B88160Bd847a3bF032B78c8967DCa877981C", "0x767e4Dc3EA4FF70D97BDEEF086e4B021923E4BdD",
    "0xA7cB4E3Ea2d6B44F4109970d7E9E7B7aBa372Eb5", "0x9CD5ab5b2c00560E93Bb89174078a05b03Eb469e",
    "0x477A71A9154050DFbC497B9F782CC5169f7BDDf5", "0xc43a1555554FF87f957c0DD5B80ab54951265c2E",
    "0xf4987eE98881ded997D1F3389B82ADF99e6592ed", "0x3F576a5a3eb52e658bc88c23d8478Ac67eC90aeE",
    "0x3Ce75C35AF2DD29D76C7C8521c218c5A0f2826A8", "0x71943a80a81c64235fC45DE4BD06638556fC773E",
    "0x3beFeA69e89931b70B80231389F97A9bF6827B2E", "0x62A8bB540e52eDfFa5F71B9Ad6BEF52600A1e247",
    "0xDcBd61032cF40C16f6d7B124676C89a0e2e874c4", "0xBb07eBA448e404B56Ba1273B762d690A57F7f84f",
    "0x5bC0F62BfBAc6C5f977BaC73EdC8FbCED89Ba8EC", "0x4423Ca3dB49914c13068C484F9D341D636A515dd",
    "0x22214b00318300e0D046feD2D9CB166cBb48Ba60", "0xA8E6F303092F0c345eEc9f780d72A8Bf56C54DF0",
    "0x04C4244F6b497343e2CcD6f3fE992910c8557dCE", "0x46F8546E33900CcdB5D5FBE80af2449ecAe42128",
    "0xD75d45215a5E8E484F1f094f15b2f626A953456e", "0x9757fd7d3B6281218E11Bab3b550eab8C4eF5eA9",
    "0xa0AC54644dfCE40F83F3B1BC941c234532B4B8e1", "0x763caa35565d457AD4231E089C3E8fb3d0fa3d56",
    "0xf2c00E3ee1c67aAD4169bD041aFd3B7ff98b2775", "0x57B57A9a34de8547EC4a26b4bded6e78c92C9A76",
    "0x948dbcf4595366297E5F2c1baD1593dBBDe875C6", "0x1c9c9d2A73A07F2cbAaa7C086a2DA70f155667d6",
    "0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a", "0x0BF91d2e547A07A41d48817bDD28cb331227d945",
    "0x762C8112207820d60FbB9894D429A60c570Ab574", "0xD354908d297ce9a348b417d2e0F561EE7D11de5E",
]
HUNDRED = ["0x79364E45648Db09eE9314E47b2fD31c199Eb03B9", "0x9A07fB107b9d8eA8B82ECF453Efb7cFb85A66Ce9",
           "0xeD566B089Fc80Df0e8D3E0AD3aD06116433Bf4a7", "0x669F5f289A5833744E830AD6AB767Ea47A3d6409"]

def main():
    out = {"blocks": {}, "prices": {}, "masterchef": {}, "minichef": {}, "shadow": {},
           "hundred": {}, "xlqdr": {}, "bpt": {}, "roles": {}, "notes": []}

    def save():
        with open(OUT, "w") as f:
            json.dump(out, f, indent=1)

    def log(*a):
        print(*a, flush=True)

    for chain in ("fantom", "bsc"):
        blk = rpc_batch(chain, [("eth_blockNumber", [])])[0]
        out["blocks"][chain] = int(blk, 16)
    log("blocks:", out["blocks"]); save()

    # ---------------- prices (DefiLlama) ----------------
    coins = {
        "LQDR": "fantom:0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9",
        "WFTM": "fantom:0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83",
        "sFTMX": "fantom:0xd7028092c830b5c8fce061af2e593413ebbc1fc1",
        "USDC_FTM": "fantom:0x04068da6c83afcfa0e13ba15a6696662335d5b75",
        "USDC_BSC": "bsc:0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
        "BUSD": "bsc:0xe9e7cea3dedca5984780bafc599bd69add087d56",
        "WBNB": "bsc:0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
        "LQDR_BSC": "bsc:0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9",
    }
    try:
        url = "https://coins.llama.fi/prices/current/" + ",".join(coins.values())
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=25) as r:
            pdata = json.loads(r.read().decode())
        for name, key in coins.items():
            c = pdata.get("coins", {}).get(key)
            if c:
                out["prices"][name] = {"usd": c["price"], "symbol": c.get("symbol"), "conf": c.get("confidence")}
            else:
                out["prices"][name] = None
    except Exception as e:
        out["notes"].append(f"llama prices failed: {e}")
    log("prices:", out["prices"]); save()

    # DexScreener fallback for LQDR
    for chainid, name, tok in (("fantom", "LQDR", LQDR),):
        try:
            u = f"https://api.dexscreener.com/latest/dex/tokens/{tok}"
            with urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"}), timeout=25) as r:
                dd = json.loads(r.read().decode())
            pairs = dd.get("pairs") or []
            best = sorted(pairs, key=lambda p: float(p.get("liquidity", {}).get("usd") or 0), reverse=True)[:3]
            out.setdefault("dexscreener", {})[name] = [
                {"dex": p.get("dexId"), "pair": p.get("pairAddress"), "priceUsd": p.get("priceUsd"),
                 "liqUsd": p.get("liquidity", {}).get("usd"), "vol24h": p.get("volume", {}).get("h24")}
                for p in best]
        except Exception as e:
            out.setdefault("dexscreener", {})[name] = f"failed: {e}"
    log("dexscreener:", json.dumps(out.get("dexscreener", {}))[:400]); save()

    # ---------------- MasterChef ----------------
    pl = int_result(call("fantom", MC, SEL["poolLength"]), 0)
    out["masterchef"]["poolLength"] = pl
    log("MasterChef poolLength:", pl); save()

    pools = []
    if pl:
        items = [(MC, SEL["poolInfo(uint256)"], enc_uint(i)) for i in range(pl)]
        res = call_many("fantom", items)
        for i, r in enumerate(res):
            if not isinstance(r, str) or len(r) < 2 + 64*5:
                pools.append({"pid": i, "error": str(r)[:80]})
                continue
            b = bytes.fromhex(r[2:])
            pools.append({"pid": i,
                          "lpToken": "0x" + b[12:32].hex(),
                          "allocPoint": int.from_bytes(b[32:64], "big"),
                          "lastRewardBlock": int.from_bytes(b[64:96], "big"),
                          "accLqdrPerShare": int.from_bytes(b[96:128], "big"),
                          "depositFeeBP": int.from_bytes(b[128:160], "big") if len(b) >= 160 else None})
    out["masterchef"]["pools"] = pools
    lps = [p["lpToken"] for p in pools if p.get("lpToken")]
    if lps:
        bals = call_many("fantom", [(lp, SEL["balanceOf(address)"], enc_addr(MC)) for lp in lps])
        tss = call_many("fantom", [(lp, SEL["totalSupply"], None) for lp in lps])
        meta_items = []
        for lp in lps:
            meta_items += [(lp, SEL["token0"], None), (lp, SEL["token1"], None), (lp, SEL["getReserves"], None)]
        meta = call_many("fantom", meta_items)
        for j, p in enumerate(pools):
            if "lpToken" not in p:
                continue
            p["chefBalance"] = int_result(bals[j])
            p["lpTotalSupply"] = int_result(tss[j])
            p["token0"] = addr_result(meta[3*j])
            p["token1"] = addr_result(meta[3*j+1])
            res = meta[3*j+2]
            if isinstance(res, str) and len(res) >= 2+64*3:
                bb = bytes.fromhex(res[2:])
                p["reserve0"] = int.from_bytes(bb[0:32], "big")
                p["reserve1"] = int.from_bytes(bb[32:64], "big")
    out["masterchef"]["lqdrBalance"] = int_result(call("fantom", LQDR, SEL["balanceOf(address)"], enc_addr(MC)))
    save()
    log("masterchef pools fetched")

    # ---------------- MiniChef both chains ----------------
    for name, chain, chef in (("fantom", "fantom", MINI_FTM), ("bsc", "bsc", MINI_BSC)):
        d = {"address": chef}
        pl = int_result(call(chain, chef, SEL["poolLength"]), 0)
        d["poolLength"] = pl
        rows = []
        for i in range(pl or 0):
            r = call(chain, chef, SEL["lpToken(uint256)"], enc_uint(i))
            s = call(chain, chef, SEL["strategies(uint256)"], enc_uint(i))
            rows.append({"pid": i, "lpToken": addr_result(r), "strategy": addr_result(s)})
        d["pools"] = rows
        out["minichef"][name] = d
        save()
        for row in rows:
            if row.get("strategy") and row.get("lpToken"):
                row["strategyBalance"] = int_result(call(chain, row["lpToken"], SEL["balanceOf(address)"], enc_addr(row["strategy"])))
            if row.get("lpToken"):
                row["chefBalance"] = int_result(call(chain, row["lpToken"], SEL["balanceOf(address)"], enc_addr(chef)))
        save()
    log("minichef done")

    # ---------------- shadow farms ----------------
    shadow_rows = []
    for a in SHADOW:
        lp = call("fantom", a, SEL["lpToken()"])
        st = call("fantom", a, SEL["strategy()"])
        shadow_rows.append({"addr": a, "lpToken": addr_result(lp), "strategy": addr_result(st)})
    out["shadow"] = shadow_rows; save()
    for row in shadow_rows:
        if row.get("strategy") and row.get("lpToken"):
            row["strategyBalance"] = int_result(call("fantom", row["lpToken"], SEL["balanceOf(address)"], enc_addr(row["strategy"])))
        if row.get("lpToken"):
            row["farmBalance"] = int_result(call("fantom", row["lpToken"], SEL["balanceOf(address)"], enc_addr(row["addr"])))
        row["owner"] = addr_result(call("fantom", row["addr"], SEL["owner"]))
    save()
    log("shadow done")

    # ---------------- hundredchef ----------------
    hrows = []
    for a in HUNDRED:
        lp = call("fantom", a, SEL["lpToken(uint256)"], enc_uint(0))
        st = call("fantom", a, SEL["strategies(uint256)"], enc_uint(0))
        row = {"addr": a, "hToken": addr_result(lp), "strategy": addr_result(st)}
        if row["strategy"] and row["hToken"]:
            row["stratBalance"] = int_result(call("fantom", row["hToken"], SEL["balanceOf(address)"], enc_addr(row["strategy"])))
            row["farmBalance"] = int_result(call("fantom", row["hToken"], SEL["balanceOf(address)"], enc_addr(a)))
            row["exchangeRate"] = int_result(call("fantom", row["hToken"], SEL["exchangeRateStored"]))
        hrows.append(row)
        save()
    out["hundred"] = hrows
    log("hundred done")

    # ---------------- xLQDR ----------------
    out["xlqdr"]["totalSupply"] = int_result(call("fantom", XL, SEL["totalSupply"]))
    out["xlqdr"]["lqdrInXlqdr"] = int_result(call("fantom", LQDR, SEL["balanceOf(address)"], enc_addr(XL)))
    out["xlqdr"]["lqdrTotalSupply"] = int_result(call("fantom", LQDR, SEL["totalSupply"]))
    out["xlqdr"]["lqdrBalanceOfMasterChef"] = out["masterchef"]["lqdrBalance"]
    save()

    # ---------------- BPTs ----------------
    for nm, bpt in (("BPT-sFTMx", "0xc0064b291bd3d4ba0e44ccfc81bf8e7f7a579cd2"),
                    ("FTM-OPERA-BPT", "0xcdf68a4d525ba2e90fe959c74330430a5a6b8226")):
        d = {"addr": bpt}
        d["totalSupply"] = int_result(call("fantom", bpt, SEL["totalSupply"]))
        d["balanceOfMasterChef"] = int_result(call("fantom", bpt, SEL["balanceOf(address)"], enc_addr(MC)))
        out["bpt"][nm] = d
    save()

    # ---------------- roles ----------------
    for nm, chain, a in (("masterchef", "fantom", MC), ("minichef_ftm", "fantom", MINI_FTM),
                         ("minichef_bsc", "bsc", MINI_BSC), ("xlqdr", "fantom", XL), ("lqdr", "fantom", LQDR)):
        out["roles"][nm] = addr_result(call(chain, a, SEL["owner"]))
    save()
    log("roles:", out["roles"])
    save()
    log("written", OUT)

if __name__ == "__main__":
    main()
