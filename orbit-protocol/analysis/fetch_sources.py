"""Fetch verified contract sources from Etherscan V2 (chainid 81457 = Blast).

Reads ETHERSCANV2_API_KEY from environment; never writes the key to disk.
Saves per-address JSON under analysis/src/.
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
if not KEY:
    print("ETHERSCANV2_API_KEY missing", file=sys.stderr)
    sys.exit(1)

ADDRS = [
    # comptroller implementations
    "0x27A389b4cb1FbcC6bE301076bFD5096E0B1eD679",
    "0x43aA593813CC96eC81A54dd4fcB86E8A6E05b1D1",
    "0x4e41E9Bde2b68a6aF0eE96172cF325a2AF4EbAA3",
    "0x9d9CEf84006048e7e5501777a34aCC1B952164b2",
    # oracles
    "0x8240881C0731a84F44b69a221871bBD88E8ca711",
    "0xF62dd5404d96Bf9628a891c6fd2D62DcD4DB8A56",
    "0x5F3f2f65c78Ea522767ae965a1C48cBC852820cE",
    # c1 markets
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec",
    "0xd847b486fe612c51900f1da1a045741820dd5fa0",
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87",
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389",
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0",
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e",
    # c2 markets
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e",
    "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2",
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d",
    # c3 markets
    "0xafabd582e82042f4a8574f75c36409abea916ac5",
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8",
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782",
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b",
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a",
    "0x4adf85e2e760c9211894482df74ba535bcae50a4",
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408",
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853",
    "0x586abb06179535de9eb6c6d968a355128dd74511",
    # c4 markets
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa",
    "0xe9391d8e1d5c970f7648852ffeda1a9f42833857",
    "0x7878c119f08052789f84cf4fdd3c3642fa291257",
]


def fetch(addr):
    q = urllib.parse.urlencode({"chainid": 81457, "module": "contract", "action": "getsourcecode",
                                "address": addr, "apikey": KEY})
    url = f"https://api.etherscan.io/v2/api?{q}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read())


def main():
    os.makedirs(os.path.join(HERE, "src"), exist_ok=True)
    summary = {}
    for a in ADDRS:
        try:
            j = fetch(a)
            res = (j.get("result") or [{}])[0]
            name = res.get("ContractName")
            src = res.get("SourceCode") or ""
            with open(os.path.join(HERE, "src", a.lower() + ".json"), "w") as f:
                json.dump(j, f)
            summary[a] = {"name": name, "verified": bool(src), "len": len(src),
                          "compiler": res.get("CompilerVersion"), "proxy": res.get("Proxy")}
            print(f"{a} {name} verified={bool(src)} len={len(src)} proxy={res.get('Proxy')}", flush=True)
        except Exception as e:  # noqa: BLE001
            summary[a] = {"error": str(e)}
            print(f"{a} ERROR {e}", flush=True)
        time.sleep(0.25)
    with open(os.path.join(HERE, "src", "summary.json"), "w") as f:
        json.dump(summary, f, indent=1)


if __name__ == "__main__":
    main()
