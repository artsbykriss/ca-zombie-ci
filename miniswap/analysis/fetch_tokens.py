#!/usr/bin/env python3
"""Fetch Etherscan verification/source metadata for a list of token addresses (chainid 1).
Usage: ETHERSCANV2_API_KEY=... python3 fetch_tokens.py <addr1> <addr2> ...
Writes analysis/token_srcs/<addr>.json (source omitted from printed output; full source saved for reading)."""
import json, os, subprocess, sys, time

KEY = os.environ["ETHERSCANV2_API_KEY"]
OUT = "analysis/token_srcs"
os.makedirs(OUT, exist_ok=True)
for a in sys.argv[1:]:
    a = a.lower()
    url = (f"https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode"
           f"&address={a}&apikey={KEY}")
    raw = subprocess.run(["curl","-s","--max-time","40",url], capture_output=True).stdout
    try:
        d = json.loads(raw)
        r = (d.get("result") or [{}])[0]
    except Exception:
        print(a, "FETCH-ERR", raw[:120]); continue
    rec = {
        "address": a, "name": r.get("ContractName"), "compiler": r.get("CompilerVersion"),
        "proxy": r.get("Proxy"), "impl": r.get("Implementation"),
        "abi": r.get("ABI"), "source": r.get("SourceCode"),
        "verified": bool(r.get("SourceCode")),
    }
    json.dump(rec, open(f"{OUT}/{a}.json","w"), indent=1)
    abi = r.get("ABI") or ""
    fns = []
    if abi and abi != "Contract source code not verified":
        try:
            for f in json.loads(abi):
                if f.get("type") == "function":
                    ins = ",".join(i["type"] for i in f.get("inputs", []))
                    fns.append(f"{f['name']}({ins})")
        except Exception: pass
    print(f"{a} | {r.get('ContractName') or 'UNVERIFIED'} | comp={r.get('CompilerVersion') or '-'} | src={'yes' if r.get('SourceCode') else 'no'} | fns={len(fns)}")
    if fns:
        interesting = [f for f in fns if any(k in f.lower() for k in ("mint","owner","admin","pause","burn","blacklist","fee","set"))]
        print("   notable:", interesting[:25])
    time.sleep(0.4)
