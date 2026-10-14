"""Extract verified sources from Etherscan V2 JSON into analysis/src/<addr>/<file>.sol."""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")


def extract(addr_json_path):
    j = json.load(open(addr_json_path))
    res = (j.get("result") or [{}])[0]
    name = res.get("ContractName") or "Unknown"
    sc = res.get("SourceCode") or ""
    outdir = os.path.join(SRC, os.path.basename(addr_json_path).replace(".json", ""))
    os.makedirs(outdir, exist_ok=True)
    files = {}
    s = sc.strip()
    if s.startswith("{{") and s.endswith("}}"):
        try:
            sj = json.loads(s[1:-1])
            for fn, fv in (sj.get("sources") or {}).items():
                files[fn] = fv.get("content", "")
        except Exception:  # noqa: BLE001
            files["raw.sol"] = sc
    elif s.startswith("{"):
        try:
            sj = json.loads(s)
            for fn, fv in (sj.get("sources") or {}).items():
                files[fn] = fv.get("content", "")
        except Exception:  # noqa: BLE001
            files["raw.sol"] = sc
    else:
        files[name + ".sol"] = sc
    for fn, content in files.items():
        safe = fn.replace("/", "__").replace(" ", "_")
        with open(os.path.join(outdir, safe), "w") as f:
            f.write(content)
    return name, list(files.keys())


if __name__ == "__main__":
    for fn in sorted(os.listdir(SRC)):
        if not fn.endswith(".json") or fn == "summary.json":
            continue
        try:
            name, files = extract(os.path.join(SRC, fn))
            print(f"{fn[:-5]} -> {name}: {len(files)} files")
        except Exception as e:  # noqa: BLE001
            print(f"{fn[:-5]} ERROR {e}")
