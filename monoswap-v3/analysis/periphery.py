#!/usr/bin/env python3
"""Identify MonoSwap V3 periphery contracts and check for stray value. Read-only."""
import json, urllib.request, concurrent.futures as cf

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io"]

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for rpc_url in RPCS:
        for a in range(3):
            try:
                req = urllib.request.Request(rpc_url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=25) as r:
                    d = json.loads(r.read())
                if "result" in d:
                    return d["result"]
                last = d.get("error")
            except Exception as e:
                last = e
    return None

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def dec_str(h):
    if not h or h == "0x": return None
    b = bytes.fromhex(h[2:])
    if len(b) < 64: return None
    off = int.from_bytes(b[0:32], "big"); ln = int.from_bytes(b[off:off+32], "big")
    return b[off+32:off+32+ln].decode("utf-8", "replace")

SIG = {
    "name()": "0x06fdde03", "symbol()": "0x95d89b41", "factory()": "0xc45a0155",
    "WETH9()": "0x4aa4a4fc", "owner()": "0x8da5cb5b", "token0()": "0x0dfe1681",
    "token1()": "0xd21220a7", "balanceOf(address)": "0x70a08231",
    "totalSupply()": "0x18160ddd", "positions(uint256)": "0x99fbab88",
    "deployer()": "0xd5f39488", "slot0()": "0x3850c7bd",
}

CANDS = [
    "0xeb7adbef26f615ebffadfadff39dbe52e4613f41",
    "0x816381bb69a22c5fdddb09af8eeedf7b340318f2",
    "0x98d0d17df4ad2a039550a6bd33e5945c6eebd2b6",
    "0xea3e40cec4cefc1b032f58fd1be71bc7225dfc6c",
    "0xd2b4af0e1150e0a7b22bf89400c2b3f6332f9645",
    "0x29021fa50fbb64d7c1bf96be56b2f164e2becea8",
    "0x3989788f404a7db408537a052e5150546961fc65",
    "0x0f0c3de3cd5185454ede5ef184bc9c7f4133fb90",
    "0x29eb40f0a3522c2baf4346803da3a4d617ba7c96",
    "0x4a3930837f6e721a6da5de4e400a7e90f907fb54",
    "0xf9f134e6652a5ede4666b9a75d8cfdd972c12912",
    "0x2add22a4b213bb0b26c0231be61f931ec0666120",
    "0x19781cb84ca75a1d81787ae88c72f63764a3037f",
    "0x334641e7de5e0de838d050b9fc05093fc7063b4c",
    "0x948e2930360d55b5cad4a269c85d5de6a688a38a",
    "0xe359d8afd40cc5f3ced469156bf69b2047c42d46",
    "0x288e11432fc397725ea1814228f7834f28925fe1",
    "0xacd9095df09b9d9f8ed91ae08907534b431a3f5f",
    "0x3c8ef655ddb1d98a7c2e0f0ed58d6812df090be6",
    "0x52001052c14ce790ebd71fcdd5081faceeb14eb9",
    "0x859374ea6df8289d883fed4e688a83381276521d",
    "0x1fdf0dba0c1cda76ee7cf57a69ca08cb1ae7b4bc",
    "0xe4dd30f7a2808580c9185e975bd7770a842923c6",
    "0x01b5343e63b3f3a67043ffb5d046961d4bd8766e",
    "0xddb8d0215b659747543d7057c2229b27db3680c8",
    "0xca3f794e8818c41b61fcd1ff6e5765d0df299ca6",
    "0xcfa4a30899764c57f3d153b1e433058e9a26e062",
    "0x28a922ad2d2a02250473b30f3444e20b138354d1",
    "0x19e88b665368be0525a9dc7ddc633c8a07a72e7e",
    "0xaea9f94202987ce3f65af85e14d8e291a41d3f8e",
    "0xf10cab7e3df03185a03e9829b0b38b1edc961e37",
    "0xe27cb06a15230a7480d02956a3521e78c5bfd2d0",
]

out = {}
def probe(a):
    rec = {}
    code = rpc("eth_getCode", [a, "latest"])
    rec["code_size"] = (len(code) - 2) // 2 if code else 0
    if rec["code_size"] == 0:
        return a, rec
    for k, sel in SIG.items():
        if k == "balanceOf(address)" or k == "positions(uint256)":
            continue
        h = call(a, sel)
        if h and h != "0x":
            if k in ("name()", "symbol()"):
                rec[k] = dec_str(h)
            elif k in ("factory()", "WETH9()", "owner()", "token0()", "token1()", "deployer()"):
                rec[k] = "0x" + h[-40:]
            else:
                rec[k] = int(h, 16) if len(h) <= 66 else h[:20]
    bal = rpc("eth_getBalance", [a, "latest"])
    rec["eth"] = int(bal, 16) if bal else None
    return a, rec

with cf.ThreadPoolExecutor(max_workers=6) as ex:
    for a, rec in ex.map(probe, CANDS):
        out[a] = rec

json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/periphery.json", "w"), indent=1)
for a, rec in out.items():
    print(a, json.dumps(rec)[:220])
