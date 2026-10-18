import json, os
from harness import *

USD = "0x0000000000000000000000000000000000000348"

def main():
    v = json.load(open(os.path.join(HERE, "vaults_flags.json")))
    prices = json.load(open(os.path.join(HERE, "prices.json")))
    bychain = {}
    for x in v:
        bychain.setdefault(x["chain"], []).append(x)
    out = {}
    for chain, xs in bychain.items():
        r = RPC(CHAINS[chain]["rpc"]); r.block = None
        blk = r.blocknum()
        # collateral decimals
        cols = sorted({c for x in xs for c in (x.get("ltv") or {})})
        cdec = {}
        if cols:
            res = r.mc([(c, sel("decimals()")) for c in cols], chunksz=180)
            for c, (ok, h) in zip(cols, res):
                cdec[c] = dec_uint(h) if ok else None
        # selection
        sel_v = [x for x in xs if (x.get("tvlUsd") or 0) >= 1000]
        sel_v += [x for x in xs if x["flags"] and (x.get("tvlUsd") or 0) > 0]
        sel_v = list({x["address"]: x for x in sel_v}.values())
        # call set
        calls = []   # (kind, vault, token, uoa, key)
        for x in sel_v:
            orc = x.get("oracle"); uoa = x.get("unitOfAccount"); asset = x.get("asset")
            if not orc or orc == "0x"+"0"*40 or not asset or not uoa: continue
            ad = x.get("assetDecimals")
            if ad is None: continue
            calls.append(("asset", x["address"], asset, uoa, (orc, asset, uoa, ad)))
            for c in (x.get("ltv") or {}):
                cd = cdec.get(c)
                if cd is None: continue
                calls.append(("coll", x["address"], c, uoa, (orc, c, uoa, cd)))
        uniq = {}
        for kind, vault, tok, uoa, key in calls:
            uniq[key] = 1
        keys = list(uniq)
        # name calls
        oracles = sorted({k[0] for k in keys})
        res = r.mc([(o, sel("name()")) for o in oracles], chunksz=180)
        names = {o: (dec_str(h) if ok else None) for o, (ok, h) in zip(oracles, res)}
        # quote calls
        qc = []
        for (orc, tok, uoa, dec) in keys:
            amt = 10 ** dec
            data = sel("getQuote(uint256,address,address)") + abi_encode(["uint256", "address", "address"], [amt, tok, uoa])
            qc.append((orc, data))
        res = r.mc(qc, chunksz=180)
        qres = {}
        for k, (ok, h) in zip(keys, res):
            qres[k] = (dec_uint(h) if ok else None)
        # assemble per vault
        vmap = {x["address"]: x for x in sel_v}
        for kind, vault, tok, uoa, key in calls:
            x = vmap[vault]
            q = qres.get(key)
            o = key[0]
            item = {"oracle": o, "oracleName": names.get(o), "token": tok,
                    "uoa": uoa, "decimals": key[3], "quote": q, "kind": kind}
            # expected quote in uoa units
            ll = prices.get(f"{CHAINS[chain]['llama']}:{tok.lower()}")
            lu = prices.get(f"{CHAINS[chain]['llama']}:{uoa.lower()}")
            if q is not None and ll and ll.get("price"):
                if uoa == USD:
                    exp = ll["price"] * 10 ** 18
                elif lu and lu.get("price"):
                    exp = ll["price"] / lu["price"] * 10 ** (lu.get("decimals") or 18)
                else:
                    exp = None
                item["expected"] = exp
                if exp:
                    item["ratio"] = q / exp
            x.setdefault("oracleChecks", []).append(item)
        out[chain] = {"block": blk, "checkedVaults": len(sel_v), "oracleCalls": len(keys), "names": names}
        print(f"[{chain}] blk {blk} vaults {len(sel_v)} calls {len(keys)} oracles {len(oracles)}", flush=True)
    json.dump(v, open(os.path.join(HERE, "vaults_quotes.json"), "w"))
    json.dump(out, open(os.path.join(HERE, "quote_meta.json"), "w"))

if __name__ == "__main__":
    main()
