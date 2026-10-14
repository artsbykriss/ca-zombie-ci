"""Precise gate reads: pause states, borrow caps, Pyth feed mappings (public RPCs).

Writes analysis/gates_state.json.
"""
import json
import os
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
RPCS = ([os.environ["BLAST_RPC_URL"]] if os.environ.get("BLAST_RPC_URL") else []) + [
    "https://81457.rpc.thirdweb.com", "https://blast-rpc.publicnode.com", "https://blast.drpc.org"]


def call(to, data, tries=5):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    for i in range(tries):
        for url in RPCS:
            try:
                req = urllib.request.Request(url, data=body, headers={
                    "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=12) as r:
                    j = json.loads(r.read())
                if "result" in j:
                    return j["result"]
                if "error" in j:
                    return "__REVERT__"
            except Exception:  # noqa: BLE001
                continue
        time.sleep(0.4)
    return None


def pad(a):
    return a[2:].rjust(64, "0")


def u(h):
    return int(h, 16) if h and h.startswith("0x") and h != "0x" else None


COMPTROLLERS = {
    1: "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    2: "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    3: "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    4: "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
}
MK = {
    1: ["0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec", "0xd847b486fe612c51900f1da1a045741820dd5fa0",
        "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87", "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389",
        "0x0872b71efc37cb8dde22b2118de3d800427fdba0", "0x8c415331761063e5d6b1c8e700f996b13603fc2e"],
    2: ["0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e", "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2",
        "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d"],
    3: ["0xafabd582e82042f4a8574f75c36409abea916ac5", "0x9bbba6322fe5f3968c1f27c8b860727d683194c8",
        "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782", "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b",
        "0xa3135b76c28b3971b703a5e6cd451531b187eb5a", "0x4adf85e2e760c9211894482df74ba535bcae50a4",
        "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408", "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853",
        "0x586abb06179535de9eb6c6d968a355128dd74511"],
    4: ["0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa", "0xe9391d8e1d5c970f7648852ffeda1a9f42833857",
        "0x7878c119f08052789f84cf4fdd3c3642fa291257"],
}
ORACLE = {1: "0x8240881C0731a84F44b69a221871bBD88E8ca711",
          2: "0xF62dd5404d96Bf9628a891c6fd2D62DcD4DB8A56",
          3: "0x5F3f2f65c78Ea522767ae965a1C48cBC852820cE",
          4: "0x5F3f2f65c78Ea522767ae965a1C48cBC852820cE"}
UND = {
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87": "0x4300000000000000000000000000000000000003",
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e": "0xf7bc58b8d8f97adc129cfc4c9f45ce3c0e1d2692",
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2": "0x2416092f143378750bb29b79ed961ab195cceea5",
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d": "0x66714db8f3397c767d0a602458b5b4e3c0fe7dd1",
    "0xafabd582e82042f4a8574f75c36409abea916ac5": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8": "0xe7903b1f75c534dd8159b313d92cdcfbc62cb3cd",
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782": "0x66714db8f3397c767d0a602458b5b4e3c0fe7dd1",
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b": "0x04c0599ae5a44757c0af6f9ec3b93da8976c150a",
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a": "0x1da40c742f32bbee81694051c0ee07485fc630f6",
    "0x4adf85e2e760c9211894482df74ba535bcae50a4": "0x1a3d9b2fa5c6522c8c071dc07125ce55df90b253",
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408": "0x4300000000000000000000000000000000000003",
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853": "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
    "0x586abb06179535de9eb6c6d968a355128dd74511": "0x38e6da25e91fe7fc023bf2689a5bd0154e2f810a",
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    "0xe9391d8e1d5c970f7648852ffeda1a9f42833857": "0x04c0599ae5a44757c0af6f9ec3b93da8976c150a",
    "0x7878c119f08052789f84cf4fdd3c3642fa291257": "0x1da40c742f32bbee81694051c0ee07485fc630f6",
}
ROUTER = "0x8240881C0731a84F44b69a221871bBD88E8ca711"


def main():
    out = {"markets": {}, "pyth_feeds": {}, "router_map": {}, "comptrollers": {}}
    for c, mks in MK.items():
        comp = COMPTROLLERS[c]
        for name, sel in (("transferPaused", "0x1e5f6a04"), ("seizePaused", "0x9a5a5c5e"),
                          ("closeFactor", "0xe8755446"), ("liqIncentive", "0x4ada90af"),
                          ("pauseGuardian", "0x24a3d622"), ("admin", "0xf851a440")):
            out["comptrollers"].setdefault(c, {})[name] = u(call(comp, sel))
        for m in mks:
            e = {"mintPaused": u(call(comp, "0x731f0c2b" + pad(m))),
                 "borrowPaused": u(call(comp, "0x6d154ea5" + pad(m))),
                 "borrowCap": u(call(comp, "0x4a584432" + pad(m)))}
            h = call(comp, "0x8e8f294b" + pad(m))
            if h and h.startswith("0x") and len(h) >= 194:
                e["isListed"] = int(h[2:66], 16) == 1
                e["cf"] = int(h[66:130], 16) / 1e18
            out["markets"][m] = e
            print(f"c{c} {m} mintP={e['mintPaused']} borrowP={e['borrowPaused']} cap={e['borrowCap']} cf={e.get('cf')}", flush=True)
        if c == 1:
            for m in mks:
                h = call(ROUTER, "0x16a833d3" + pad(m))
                out["router_map"][m] = "0x" + h[-40:] if h and h.startswith("0x") and len(h) >= 42 else None
        oracle = ORACLE[c]
        for m in mks:
            asset = UND.get(m)
            if not asset:
                continue
            h = call(oracle, "0xaafe21c5" + pad(asset))
            if h and h.startswith("0x") and len(h) == 66:
                out["pyth_feeds"][f"{oracle}:{asset}"] = h
        print("comptroller", c, "done", flush=True)
    with open(os.path.join(HERE, "gates_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote gates_state.json", flush=True)


if __name__ == "__main__":
    main()
