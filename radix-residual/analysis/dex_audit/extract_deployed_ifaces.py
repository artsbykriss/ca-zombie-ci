#!/usr/bin/env python3
"""Extract the AUTHORITATIVE deployed blueprint interfaces (state fields + fn signatures) per package."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details  # noqa: E402

PKGS = {
    "BasicPool": "package_rdx1p5l6dp3slnh9ycd7gk700czwlck9tujn0zpdnd0efw09n2zdnn0lzx",
    "Pool": "package_rdx1phyk2tszvfhz2ukht6pkg3f3q3ww3fsuwku4uyyzctslpfp6dqksqq",
    "PrecisionPool": "package_rdx1pkl8tdw43xqx64etxwdf8rjtvptqurq4c3fky0kaj6vwa0zrkfmcmc",
    "FlexPool": "package_rdx1pkzxm6nw55wvz0e2fn79hd8t07834cxa8kpdlhq8s5lp5ldqpcglwe",
}


def main():
    out = {}
    d = entity_details(list(PKGS.values()))
    for it in d["items"]:
        det = it["details"]
        print("=" * 100)
        print("PACKAGE", it["address"], "code_hash", det.get("code_hash_hex"))
        for b in det["blueprints"]["items"]:
            name = b["name"]
            iface = (b.get("definition") or {}).get("interface") or {}
            fields = (((iface.get("state") or {}).get("fields") or {}).get("fields") or [])
            fnames = [f.get("field_name") for f in fields]
            print(f"\nBLUEPRINT {name} v{b.get('version')}  state_fields({len(fnames)}): {fnames}")
            fns = iface.get("functions") or []
            sigs = []
            for f in fns:
                if not isinstance(f, dict):
                    continue
                nm = f.get("name")
                inp = f.get("input") or {}
                outt = f.get("output") or {}
                sigs.append({"name": nm,
                             "input": inp.get("type_ref", inp),
                             "output": outt.get("type_ref", outt)})
            out[name] = {"package": it["address"], "code_hash": det.get("code_hash_hex"),
                         "state_fields": fnames, "functions": sigs}
            for s in sigs:
                print(f"   fn {s['name']}: in={json.dumps(s['input'])[:120]} out={json.dumps(s['output'])[:120]}")
    json.dump(out, open("ociswap_deployed_ifaces.json", "w"), indent=1)


if __name__ == "__main__":
    main()
