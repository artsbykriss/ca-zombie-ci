import json, os, sys, urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import llrpc as rpc

OUT = os.path.dirname(os.path.abspath(__file__))


def get_etherscan(chain, addr):
    d = rpc.etherscan({"chainid": chain, "module": "contract", "action": "getsourcecode", "address": addr})
    return d["result"][0]


def get_blockscout(base, addr):
    url = f"{base}/api/v2/smart-contracts/{addr}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))


def dump_etherscan(chain, addr, label):
    d = get_etherscan(chain, addr)
    name = d["ContractName"]
    src = d["SourceCode"]
    out = os.path.join(OUT, f"src_{label}_{name}")
    os.makedirs(out, exist_ok=True)
    try:
        s = src
        if s.startswith("{{"):
            s = s[1:]
        if s.endswith("}}"):
            s = s[:-1]
        j = json.loads(s)
        for p, c in j["sources"].items():
            fp = os.path.join(out, p.replace("..", "__"))
            os.makedirs(os.path.dirname(fp), exist_ok=True)
            open(fp, "w").write(c["content"])
        meta = {"name": name, "addr": addr, "chain": chain, "verified": True,
                "proxy": d["Proxy"], "impl": d["Implementation"],
                "compiler": d["CompilerVersion"], "settings": d.get("EVMVersion")}
    except Exception as e:  # noqa: BLE001
        open(os.path.join(out, "RAW.sol"), "w").write(src)
        meta = {"name": name, "addr": addr, "chain": chain, "raw": True, "err": str(e),
                "proxy": d["Proxy"], "impl": d["Implementation"], "compiler": d["CompilerVersion"]}
    json.dump(meta, open(os.path.join(out, "meta.json"), "w"), indent=1)
    print(out, name, len(src), meta.get("proxy"), meta.get("impl"))


def dump_blockscout(base, addr, label):
    d = get_blockscout(base, addr)
    name = d.get("name") or "unknown"
    out = os.path.join(OUT, f"src_{label}_{name}")
    os.makedirs(out, exist_ok=True)
    files = d.get("additional_sources") or []
    if d.get("source_code"):
        open(os.path.join(out, "main.vy"), "w").write(d["source_code"])
    for f in files:
        fp = os.path.join(out, f.get("file_path", "aux").replace("..", "__"))
        os.makedirs(os.path.dirname(fp), exist_ok=True)
        open(fp, "w").write(f.get("source_code", ""))
    meta = {"name": name, "addr": addr, "verified": d.get("is_verified"),
            "compiler": d.get("compiler_version"), "language": d.get("language"),
            "proxy": d.get("is_proxy"), "impl": (d.get("implementations") or [{}])[0].get("address")}
    json.dump(meta, open(os.path.join(out, "meta.json"), "w"), indent=1)
    print(out, name, "verified", d.get("is_verified"), "files", 1 + len(files))


if __name__ == "__main__":
    mode, label = sys.argv[1], sys.argv[2]
    addrs = sys.argv[3:]
    if mode == "eth":
        for a in addrs:
            dump_etherscan(1, a, label)
    elif mode == "op":
        for a in addrs:
            dump_blockscout("https://optimism.blockscout.com", a, label)
