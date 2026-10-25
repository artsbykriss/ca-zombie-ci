#!/usr/bin/env python3
"""Probe value-moving selectors of Prodigy.Fi V2 (Base) from a fresh EOA (0x..dEaD).

READ-ONLY: eth_call only, at latest block. KEYLESS endpoint.
Writes analysis/probe_results.json
"""
import json, os, sys, urllib.request, time

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
FRESH = "0x000000000000000000000000000000000000dEaD"
PM = "0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7"
POOL = "0xe1303B2514755A72da4AcA9B917d96F16c842c80"
POOL2 = "0x864cd49392a4348b5da5337623d994151610D0a3"
VAULT = "0xD6EE85424b29C8055b9cC71FAC0660CB5BaF35FB"
VAULT_LAST = "0xd1A1513B3E672eEBD42E7AB2A0a99bE372B77B90"
WETH = "0x4200000000000000000000000000000000000006"
USDC = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for _ in range(4):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json"})
            return json.load(urllib.request.urlopen(req, timeout=30))
        except Exception as e:
            time.sleep(0.3)
    return {"error":{"message":"rpc fail"}}

def pad32(x):
    if x.startswith("0x"): x = x[2:]
    return x.rjust(64,"0")

def enc_sel(sel, args):
    return sel + "".join(pad32(a) for a in args)

def probe(to, sel, args, label, from_=FRESH):
    data = enc_sel(sel, args)
    r = rpc("eth_call", [{"from": from_, "to": to, "data": data}, "latest"])
    res = {"target": to, "label": label, "selector": sel, "data": data, "from": from_}
    if "error" in r:
        res["ok"] = False
        res["error"] = r["error"].get("message") if isinstance(r["error"], dict) else str(r["error"])
        # try to decode revert string from data
        d = r["error"].get("data") if isinstance(r["error"], dict) else None
        res["revert_data"] = d
        if isinstance(d, str) and d.startswith("0x08c379a0"):
            try:
                raw = bytes.fromhex(d[10:])
                ln = int.from_bytes(raw[32:64], "big")
                res["revert_string"] = raw[64:64+ln].decode()
            except Exception: pass
    else:
        res["ok"] = True
        res["result"] = r["result"]
    return res

def main():
    out = []
    # ---- collateral pool (funded) ----
    out.append(probe(POOL, "0xf3fef3a3", [USDC, "0x1"], "pool.withdraw(USDC,1)"))
    out.append(probe(POOL, "0xf3fef3a3", [WETH, "0x1"], "pool.withdraw(WETH,1)"))
    out.append(probe(POOL, "0x47e7ef24", [USDC, "0x1"], "pool.deposit(USDC,1)"))
    out.append(probe(POOL, "0x1ea734b6", [USDC, "0x1"], "pool.processUserDeposit(USDC,1)"))
    out.append(probe(POOL, "0x1749aa26", [USDC, "0x1"], "pool.0x1749aa26(USDC,1)"))
    out.append(probe(POOL, "0xd5735e7d", [VAULT], "pool.0xd5735e7d(vault)"))
    out.append(probe(POOL, "0x05c4fdf9", [FRESH, FRESH], "pool.registerVault(x,x)"))
    out.append(probe(POOL, "0x3e99414e", [VAULT, "0x1"], "pool.approveVault(vault,true)"))
    out.append(probe(POOL, "0x4f1ef286", [FRESH, "0x40", "0x0"], "pool.upgradeToAndCall"))
    out.append(probe(POOL, "0xc4d66de8", [FRESH], "pool.initialize(dead)"))
    out.append(probe(POOL, "0x5bb47808", [FRESH], "pool.setFactory"))
    out.append(probe(POOL, "0x76ce28f1", [USDC, "0x1"], "pool.setWhitelistedToken"))
    out.append(probe(POOL, "0x9d73d725", [USDC, "0x1"], "pool.setWhitelistedLP"))
    out.append(probe(POOL, "0xa4bc9c2d", ["0x1"], "pool.0xa4bc9c2d(true)"))
    out.append(probe(POOL, "0xf2fde38b", [FRESH], "pool.transferOwnership"))
    out.append(probe(POOL, "0x715018a6", [], "pool.renounceOwnership"))
    # v1 pool too (unfunded but check)
    out.append(probe(POOL2, "0xf3fef3a3", [USDC, "0x1"], "pool2.withdraw(USDC,1)"))
    out.append(probe(POOL2, "0xe7f02017", [VAULT, "0x1"], "pool2.useCollateral(vault,1)"))

    # ---- vault ----
    for V,name in [(VAULT,"v0"),(VAULT_LAST,"v1713")]:
        out.append(probe(V, "0xeaa46ccf", [], f"{name}.eaa46ccf()"))
        out.append(probe(V, "0x08031eba", [], f"{name}.08031eba()"))
        out.append(probe(V, "0x8caad7b5", [], f"{name}.8caad7b5()"))
        out.append(probe(V, "0x8caad7b5", ["0x1"], f"{name}.8caad7b5(1)"))
        out.append(probe(V, "0xb392c530", ["0x1"], f"{name}.b392c530(1)"))
        out.append(probe(V, "0x65de4b2a", ["0x1"], f"{name}.65de4b2a(1)"))
        out.append(probe(V, "0x173458bc", [USDC, "0x1", "0x1", "0x1", "0x1", "0x1"], f"{name}.173458bc"))
        out.append(probe(V, "0x781229fc", [USDC, "0x1", "0x1", "0x20", "0x0"], f"{name}.deposit"))
        out.append(probe(V, "0x4f1ef286", [FRESH, "0x40", "0x0"], f"{name}.upgradeToAndCall"))
        out.append(probe(V, "0xf2fde38b", [FRESH], f"{name}.transferOwnership"))
        out.append(probe(V, "0xc4d66de8", [FRESH], f"{name}.initialize"))

    # ---- position manager ----
    for sel,args,label in [
        ("0x4f1ef286", [FRESH, "0x40", "0x0"], "pm.upgradeToAndCall"),
        ("0x32c3c1b6", [USDC], "pm.32c3c1b6(USDC)"),
        ("0x1c2a75b9", [USDC, WETH, "0x1"], "pm.1c2a75b9"),
        ("0x9d509f38", [USDC, WETH], "pm.9d509f38"),
        ("0x7159c42e", [USDC, WETH, WETH, "0x1"], "pm.7159c42e"),
        ("0x4ce92445", [USDC, "0x1"], "pm.4ce92445"),
        ("0xd17e970d", [USDC, WETH, "0x1"], "pm.d17e970d"),
        ("0xda4f0f30", [USDC, "0x1"], "pm.da4f0f30"),
        ("0xbb3696dc", [USDC, "0x1"], "pm.bb3696dc"),
        ("0x43470ad5", ["0x1"], "pm.43470ad5(1)"),
        ("0x8d58b216", [FRESH], "pm.setCollateralPoolV2"),
        ("0xc8d60b42", [FRESH, "0x1"], "pm.setVaultImplementation"),
        ("0x7c08b964", [FRESH], "pm.changeFeeReceiver"),
        ("0xdfe15bac", [USDC, "0x1"], "pm.setMinDepositAmount"),
        ("0x3242edfc", ["0x1"], "pm.changeDepositDeadlineOffset"),
        ("0x5b769f3c", [FRESH], "pm.setWETH"),
        ("0x1ba28878", [FRESH], "pm.setCollateralPool"),
        ("0xe12799b1", [], "pm.initializeUpgrade"),
        ("0xc4d66de8", [FRESH], "pm.initialize(dead)"),
        ("0x8456cb59", [], "pm.pause"),
        ("0x3f4ba83a", [], "pm.unpause"),
        ("0xf2fde38b", [FRESH], "pm.transferOwnership"),
        ("0x715018a6", [], "pm.renounceOwnership"),
    ]:
        out.append(probe(PM, sel, args, label))

    json.dump(out, open("probe_results.json","w"), indent=1)
    for r in out:
        if r.get("ok"):
            print("SUCCESS ", r["label"], "->", str(r.get("result"))[:80])
        else:
            print("revert  ", r["label"], "|", (r.get("revert_string") or r.get("error") or "")[:90])

if __name__ == "__main__":
    main()
