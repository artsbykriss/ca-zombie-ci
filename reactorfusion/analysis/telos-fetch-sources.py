#!/usr/bin/env python3
"""Fetch verified sources from Teloscan explorer API for ReactorFusion Telos contracts.
Read-only. Saves into analysis/telos-sources/<label>/ ... No secrets written."""
import json, os, sys, time, urllib.request

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-sources")
API = "https://api.teloscan.io/api"

TARGETS = {
    "comptroller_impl": "0xd4b18a93019ba2dd9d1ad0e66302730648be2b40",
    "oracle": "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2",
    "rfTLOS_ctoken": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
    "rfUSDC_ctoken": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfETH_ctoken": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "unitroller": "0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494",
}


def get(url, tries=4):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research-read-only"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    raise last


def safe_name(p):
    return p.replace("/", "__").replace("@", "@")


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {}
    for label, addr in TARGETS.items():
        url = f"{API}?module=contract&action=getsourcecode&address={addr}"
        j = get(url)
        res = j.get("result")
        if not isinstance(res, list) or not res:
            manifest[label] = {"address": addr, "error": str(j)[:300]}
            print("FAIL", label, str(j)[:200])
            continue
        r0 = res[0]
        entry = {"address": addr, "ContractName": r0.get("ContractName"),
                 "CompilerVersion": r0.get("CompilerVersion"), "OptimizationUsed": r0.get("OptimizationUsed"),
                 "Proxy": r0.get("Proxy"), "Implementation": r0.get("Implementation")}
        src = r0.get("SourceCode") or ""
        d = os.path.join(OUT, label)
        os.makedirs(d, exist_ok=True)
        if src.strip().startswith("{"):
            # standard-json bundle
            try:
                bundle = json.loads(src)
                sources = bundle.get("sources", {})
                for path, obj in sources.items():
                    content = obj.get("content", "")
                    with open(os.path.join(d, safe_name(path)), "w") as f:
                        f.write(content)
                entry["n_sources"] = len(sources)
                entry["files"] = sorted(safe_name(p) for p in sources)
            except Exception as e:
                entry["parse_error"] = str(e)[:200]
                with open(os.path.join(d, "_raw_sourcecode.txt"), "w") as f:
                    f.write(src)
        else:
            with open(os.path.join(d, "Main.sol"), "w") as f:
                f.write(src)
            entry["n_sources"] = 1
            entry["files"] = ["Main.sol"]
        # additional sources (flattened multi-file)
        adds = r0.get("AdditionalSources") or []
        for i, a in enumerate(adds):
            p = a.get("Filename") or f"Additional_{i}.sol"
            with open(os.path.join(d, safe_name(p)), "w") as f:
                f.write(a.get("SourceCode", ""))
        entry["n_additional"] = len(adds)
        manifest[label] = entry
        print(f"OK {label} {addr} name={entry['ContractName']} n_sources={entry.get('n_sources')} n_additional={len(adds)}")
    with open(os.path.join(OUT, "_manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)


if __name__ == "__main__":
    main()
