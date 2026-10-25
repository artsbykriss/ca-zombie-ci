#!/usr/bin/env python3
"""Live-state snapshot for the ZH4 pass-7 Sui targets (READ-ONLY).

Reads the known value-bearing shared objects for:
  - Bucket Protocol V2 (CDP vaults + PSM pools)
  - DipCoin (vault, perps bank)
  - Bluefin Pro (data store, USDC vault)
  - Suigar (SweetHouse casino houses)
  - AlphaFi Lend (lending protocol object)
Writes ci-out/live_state.json. Public GraphQL only; no keys, no signing.
"""
import json, os, sys, urllib.request, datetime

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
OUT = os.environ.get("OUTDIR", os.path.join(os.path.dirname(__file__), "..", "ci-out"))

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def obj(addr):
    q = """query($a:SuiAddress!){ object(address:$a){ address version
      asMoveObject{ contents{ type{repr} json } } } }"""
    return ((gql(q, {"a": addr}).get("data") or {}).get("object"))

def objs_of_type(t, n=50):
    q = """query($t:String!,$n:Int){ objects(first:$n, filter:{type:$t}){ nodes{
      address version asMoveObject{ contents{ type{repr} json } } } } }"""
    return (((gql(q, {"t": t, "n": n}).get("data") or {}).get("objects") or {}).get("nodes") or [])

def df(addr, n=50):
    q = """query($a:SuiAddress!,$n:Int){ object(address:$a){ dynamicFields(first:$n){
      nodes{ name{ type{repr} json } value{ ... on MoveValue{ type{repr} json } } } } } }"""
    return (((gql(q, {"a": addr, "n": n}).get("data") or {}).get("object") or {}).get("dynamicFields") or {}).get("nodes") or []

def price(coins):
    url = "https://coins.llama.fi/prices/current/" + ",".join(coins)
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.loads(r.read().decode()).get("coins", {})
    except Exception as e:
        return {"error": str(e)}

SNAPSHOT = {
    "bucket_vaults": ("0x9f835c21d21f8ce519fec17d679cd38243ef2643ad879e7048ba77374be4036e::vault::Vault", "type"),
    "bucket_pools":  ("0xc2ae6693383e4a81285136effc8190c7baaf0e75aafa36d1c69cd2170cfc3803::pool::Pool", "type"),
    "bucket_cdp_protocol": ("0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df", "obj"),
    "dipcoin_vault_config": ("0x69bae0c198f83acf12656a247dfe85467819139560968669f14b4df0abe8efd7", "obj"),
    "dipcoin_perps_bank": ("0x3cc2bfbe6b9dc346f3f27a47b4b0c9eaaf0143c0c704726a1513a1e8c5d9a4c1", "obj"),
    "bluefin_data_store": ("0x740d972ea066fe3302ee655163373cda2e9529bfa93d2266e1355cf56899da57", "obj"),
    "bluefin_usdc_vault": ("0x10d48e112b92c8af207c1850225284a7ca46bac1d935c4af4cf87ce29b121694", "obj"),
    "suigar_sweethouse": ("0xa1549d73230118716bc08865b8d62454f360ddaf40eee2158e458e52125d4ef1", "obj+df"),
    "alphalend_protocol": ("0x01d9cf05d65fa3a9bb7163095139120e3c4e414dfbab153a49779a7d14010b93", "obj"),
}

def main():
    os.makedirs(OUT, exist_ok=True)
    res = {"generated": datetime.datetime.utcnow().isoformat() + "Z", "endpoint": ENDPOINT, "targets": {}}
    for name, (addr, kind) in SNAPSHOT.items():
        try:
            if kind == "type":
                nodes = objs_of_type(addr, 50)
                res["targets"][name] = {"type": addr, "count": len(nodes),
                    "objects": [{"address": n["address"], "version": n["version"],
                                 "type": n["asMoveObject"]["contents"]["type"]["repr"],
                                 "json": n["asMoveObject"]["contents"]["json"]} for n in nodes]}
            else:
                o = obj(addr)
                rec = {"address": addr, "version": o["version"] if o else None,
                       "type": o["asMoveObject"]["contents"]["type"]["repr"] if o else None,
                       "json": o["asMoveObject"]["contents"]["json"] if o else None}
                if "df" in kind:
                    rec["dynamic_fields"] = df(addr, 50)
                res["targets"][name] = rec
            print(f"[ok] {name}")
        except Exception as e:
            res["targets"][name] = {"error": str(e)}
            print(f"[err] {name}: {e}")
    # prices
    res["prices"] = price(["sui:0x2::sui::SUI",
                           "sui:0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC"])
    json.dump(res, open(os.path.join(OUT, "live_state.json"), "w"), indent=1)
    print("wrote", os.path.join(OUT, "live_state.json"))

if __name__ == "__main__":
    main()
