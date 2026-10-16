#!/usr/bin/env python3
"""Trace factory functions with different senders via anvil debug_traceCall (local, read-only)."""
import json, urllib.request

RPC = "http://127.0.0.1:8547"
F = "0x9c3663fa9ab976e67b42939486ec4966cb41a0bb".lower()

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.load(r)
    if "error" in d: raise RuntimeError(json.dumps(d["error"])[:300])
    return d["result"]

def ethcall(data, sender, to=F, trace=False, gas="0x5f5e100"):
    tx = {"to": to, "data": data, "from": sender, "gas": gas}
    if not trace:
        try:
            return {"ok": True, "ret": rpc("eth_call", [tx, "latest"])}
        except Exception as e:
            return {"ok": False, "err": str(e)[:220]}
    try:
        tr = rpc("debug_traceCall", [tx, "latest", {"tracer": "prestateTracer", "tracerConfig": {"diffMode": True}}])
        return {"ok": True, "trace": tr}
    except Exception as e:
        return {"ok": False, "err": str(e)[:220]}

def pad_addr(a): return "0"*24 + a.lower().replace("0x","")
def pad_u(x): return f"{x:064x}"

def summarize(trace):
    """prestateTracer diffMode: trace = {pre:{addr:{storage,balance,...}}, post:{addr:{storage}}}"""
    out = []
    if not trace: return out
    pre, post = trace.get("pre", {}), trace.get("post", {})
    for addr, poststate in post.items():
        prestore = pre.get(addr, {}).get("storage", {})
        poststore = poststate.get("storage", {})
        for slot, val in poststore.items():
            old = prestore.get(slot, "0x"+"00"*32)
            if old != val:
                out.append(f"    STORE {addr} slot {slot} : {old} -> {val}")
        # balance changes
        if "balance" in poststate and "balance" in pre.get(addr, {}):
            if poststate["balance"] != pre[addr]["balance"]:
                out.append(f"    BAL {addr}: {int(pre[addr]['balance'],16)} -> {int(poststate['balance'],16)}")
        # new contracts
        if "code" in poststate and "code" not in pre.get(addr, {}):
            out.append(f"    CREATED {addr}")
    return out

SENDERS = {
 "NAVsig": "0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A",
 "deployer": "0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101",
 "safe": "0x81B80499C396a9931b9e44953425a82C1b2541bd",
 "manager": "0xB7410dc44e2715161E9914272e2D55D7c5061FAa",
 "team001232": "0x001232c60a01d7b54cb011b0075bab75791aa03b",
 "random": "0x000000000000000000000000000000000000dEaD",
}
PT = {
 "pTEST": "0x1193BcBfaFeB2F25C516817C46BD3143936d1d5C",
 "pBTC3x": "0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e",
 "pHOOD3x": "0xe24CABDf76DD1c2576049167eB1755C84b985C36",
 "pTEST3": "0x122408C1399E51C41B096402fea46e20E762A950",
}

TESTS = [
 ("0x4e666f20(pBTC3x, 2.5e11)", "0x4e666f20" + pad_addr(PT["pBTC3x"]) + pad_u(250000000000)),
 ("0x4e666f20(pTEST3, 1)", "0x4e666f20" + pad_addr(PT["pTEST3"]) + pad_u(1)),
 ("0xd3c5ee0e(pTEST,[deployer],true)", "0xd3c5ee0e" + pad_addr(PT["pTEST"]) + pad_u(0x60) + pad_u(1) + pad_u(1) + pad_addr(SENDERS["deployer"])),
 ("0xd3c5ee0e(pTEST,[dead],true)", "0xd3c5ee0e" + pad_addr(PT["pTEST"]) + pad_u(0x60) + pad_u(1) + pad_u(1) + pad_addr(SENDERS["random"])),
 ("0xfe618ab1([dead],true)", "0xfe618ab1" + pad_u(0x40) + pad_u(1) + pad_u(1) + pad_addr(SENDERS["random"])),
 ("0xfe618ab1([dead],false)", "0xfe618ab1" + pad_u(0x40) + pad_u(0) + pad_u(1) + pad_addr(SENDERS["random"])),
 ("0x8da87eb1(7776000)", "0x8da87eb1" + pad_u(7776000)),
 ("0xc2eabaf3(pBTC3x,true)", "0xc2eabaf3" + pad_addr(PT["pBTC3x"]) + pad_u(1)),
 ("0xc2eabaf3(pBTC3x,false)", "0xc2eabaf3" + pad_addr(PT["pBTC3x"]) + pad_u(0)),
]

for name, data in TESTS:
    print(f"\n########## {name}")
    for sname, sender in SENDERS.items():
        res = ethcall(data, sender, trace=False)
        if res["ok"]:
            print(f"  [{sname}] OK ret={res['ret'][:80]}")
        else:
            print(f"  [{sname}] REVERT {res['err'][:170]}")
