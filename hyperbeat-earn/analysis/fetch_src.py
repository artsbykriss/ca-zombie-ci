#!/usr/bin/env python3
"""Fetch verified source + ABI from Etherscan V2 (chain 999) for Hyperbeat contracts.
Key is read from env ETHERSCANV2_API_KEY; the keyed URL is NEVER written to disk."""
import json, os, urllib.request, time, re, sys

KEY = os.environ.get("ETHERSCANV2_API_KEY")
if not KEY:
    print("NO KEY"); sys.exit(1)
OUT = "/home/heisenberg/CA/hyperbeat-earn/analysis/src"
os.makedirs(OUT, exist_ok=True)

ADDRS = {
 "impl_liquidHYPE": "0x6d684992f8d105b33f9b1bbaa77bdd0e0f71f585",
 "impl_oracle": "0x20a9bb2e08b9cb3c38cb3838311f7e0bd129bff8",
 "impl_rate_lstHYPE": "0x7b5bd5a38677a5355a54adc9b3113c3023709d03",
 "impl_rate_hbUSDT": "0x77b13307d6a36511ee7d887ae7ae9eb28e78e690",
 "impl_rate_hbUSDC": "0x76a20173c5792c04a9cc6754d7e888ac84c54871",
 "impl_wVLP": "0x042e8217be08dac98aaaee834d47ea3a7f77ba34",
 "oracle_lstHYPE": "0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b",
 "oracle_masterUSD": "0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6",
 "morpho_MEVHYPE": "0xd19e3d00f8547f7d108abfd4bbb015486437b487",
 "morpho_GauntletUSDC": "0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3",
 "proxy_liquidHYPE": "0x441794D6a8F9A3739F5D4E98a728937b33489D29",
 "admin_bf25": "0xbf25b58cb8dfad688f7bcb2b87d71c23a6600aac",
 "strategist_eoa": "0x83a80e5b64086197c01cbb123df2aea79a149c1d",
 "erc4626_ultraHYPE_impl": "0xcd27d859bae91fbcac1deda69deae3313f07ef6b",
 "oracle_placeholder": "0x1ceab703956e24b18a0af6b272e0bf3f499aca0f",
}

def fetch(addr):
    url = f"https://api.etherscan.io/v2/api?chainid=999&module=contract&action=getsourcecode&address={addr}&apikey={KEY}"
    for a in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"research/1.0"}), timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(2)

def fetch_abi(addr):
    url = f"https://api.etherscan.io/v2/api?chainid=999&module=contract&action=getabi&address={addr}&apikey={KEY}"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"research/1.0"}), timeout=40) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"__exc__":str(e)}

index={}
for name, addr in ADDRS.items():
    d = fetch(addr)
    res = d.get("result")
    row = {"address": addr}
    if isinstance(res, list) and res:
        x = res[0]
        row["ContractName"] = x.get("ContractName")
        row["Proxy"] = x.get("Proxy")
        row["Implementation"] = x.get("Implementation")
        row["CompilerVersion"] = x.get("CompilerVersion")
        sc = x.get("SourceCode") or ""
        row["src_len"] = len(sc)
        with open(f"{OUT}/{name}.srccode.txt", "w") as f:
            f.write(sc)
        if x.get("ABI"):
            with open(f"{OUT}/{name}.abi.json","w") as f:
                f.write(x["ABI"])
        # extract contract names in multi-file json
        if sc.startswith("{{") or sc.startswith("{"):
            try:
                j = json.loads(sc[1:-1] if sc.startswith("{{") else sc)
                row["files"] = list(j.get("sources",{}).keys())[:40]
            except Exception: pass
    else:
        row["result"] = str(res)[:200]
    index[name]=row
    print(name, addr, row.get("ContractName"), "proxy=",row.get("Proxy"), "impl=",row.get("Implementation"), "len=",row.get("src_len"), flush=True)

json.dump(index, open(f"{OUT}/_index.json","w"), indent=1)
print("done")
