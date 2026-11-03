#!/usr/bin/env python3
"""Static guard map for the Tron SunSwap V4 PoolManager runtime (read-only).

Produces a machine-checkable summary of opcode primitives and, per selector,
whether its code window references the transient locker slot (onlyWhenUnlocked),
the owner slot-3 check, or the protocol-fee-controller slot-6 check.
"""
import json, sys, bisect
sys.path.insert(0, "/home/heisenberg/CA/ca2-open-sunswap/analysis")
from disasm import disasm, selector_map, OPS
from Crypto.Hash import keccak

ROOT = "/home/heisenberg/CA/ca2-open-sunswap/analysis"
code = bytes.fromhex(open(ROOT + "/poolmanager_runtime_only.hex").read().strip())
LOCKER = 0xedda7c051899c54dd66eaf5e13c031326ab4729812a579bed198ab93fd313d70
DELTA_COUNT = 0xa88ffc6a483ae852b901fb1c3a0df606e2e4461b493434e6643ebdc3ffabd151
CURRENCY = 0x52a1be34b47478d7c75e2b6c3eea1e05dcb8dbb8c6a42c6482d0dca0df53cb27
RESERVES = 0xb0879d96d58bcff08d1fd45590200072d5a8c380da0b5aa1052b48b84e115207

def h(sig):
    k = keccak.new(digest_bits=256); k.update(sig.encode()); return k.hexdigest()[:8]

# selector -> name from ABI
abi = json.load(open(ROOT + "/poolmanager_abi.json"))
names = {}
for e in abi:
    if e.get("type", "").lower() != "function" or not e.get("name"):
        continue
    n = e["name"]
    ins = []
    for i in e.get("inputs", []):
        t = i.get("type", "")
        if t.startswith("tuple"):
            comps = i.get("components") or []
            t = "(" + ",".join(c.get("type", "") for c in comps) + ")" + t[5:]
        ins.append(t)
    sig = n + "(" + ",".join(ins) + ")"
    names[h(sig)] = sig
# tuple layouts recovered from live calldata / events
for name, sig in {
    "2a5f6409": "initialize((address,address,address,uint24,bytes32),uint160)",
    "ea77b364": "swap((address,address,address,uint24,bytes32),(bool,int256,uint160),bytes)",
    "7550efcf": "modifyLiquidity((address,address,address,uint24,bytes32),(int24,int24,int256,bytes32),bytes)",
    "55cea574": "donate((address,address,address,uint24,bytes32),uint256,uint256,bytes)",
    "b62f36b3": "setProtocolFee((address,address,address,uint24,bytes32),uint24)",
    "01a6832f": "updateDynamicLPFee((address,address,address,uint24,bytes32),uint24)",
}.items():
    names[name] = sig

ins = disasm(code)
counts = {}
for pc, n, a, s in ins:
    counts[n] = counts.get(n, 0) + 1

sm = selector_map(code)
entries = sorted({d for ds in sm.values() for d in ds})
selector_by_entry = {}
for sel, ds in sm.items():
    for d in ds:
        selector_by_entry.setdefault(d, []).append(sel)

def window(start):
    i = bisect.bisect_right(entries, start)
    end = entries[i] if i < len(entries) else len(code)
    return [(pc, n, a) for pc, n, a, s in ins if start <= pc < end]

SEL_BY_CONST = {LOCKER: "locker", DELTA_COUNT: "delta_count", CURRENCY: "currency", RESERVES: "reserves"}
rows = []
for d in entries:
    w = window(d)
    consts = set()
    owner_check = controller_check = False
    for j, (pc, n, a) in enumerate(w):
        if n == "PUSH32" and a in SEL_BY_CONST:
            consts.add(SEL_BY_CONST[a])
        # owner/controller checks load slot 3 / slot 6 then compare with CALLER
        if n == "SLOAD":
            prev = w[max(0, j-3):j]
            slot = next((x[2] for x in reversed(prev) if x[1].startswith("PUSH")), None)
            nxt = [x[1] for x in w[j:j+8]]
            if slot == 3 and "CALLER" in nxt: owner_check = True
            if slot == 6 and "CALLER" in nxt: controller_check = True
    rows.append({
        "entry": hex(d),
        "selectors": sorted({names.get(s, s) for s in selector_by_entry.get(d, [])}),
        "locker_slot": "locker" in consts,
        "delta_count_slot": "delta_count" in consts,
        "currency_slot": "currency" in consts,
        "reserves_slot": "reserves" in consts,
        "owner_slot3_caller_check": owner_check,
        "controller_slot6_caller_check": controller_check,
    })

out = {
    "runtime_bytes": len(code),
    "instructions": len(ins),
    "opcode_counts": {k: counts.get(k, 0) for k in
        ["CALLER", "ORIGIN", "SLOAD", "SSTORE", "TLOAD", "TSTORE", "CALL", "STATICCALL",
         "DELEGATECALL", "CREATE", "CREATE2", "SELFDESTRUCT", "CALLVALUE", "SELFBALANCE"]},
    "selector_count": len(sm),
    "locker_slot": hex(LOCKER),
    "functions": rows,
}
json.dump(out, open(ROOT + "/static_guards.json", "w"), indent=1)
print(json.dumps({k: v for k, v in out.items() if k != "functions"}, indent=1))
print("\nfunctions with locker gate:")
for r in rows:
    if r["locker_slot"]:
        print(" ", r["entry"], r["selectors"], "owner" if r["owner_slot3_caller_check"] else "")
print("\nowner-gated:", [(r["entry"], r["selectors"]) for r in rows if r["owner_slot3_caller_check"]])
print("controller-gated:", [(r["entry"], r["selectors"]) for r in rows if r["controller_slot6_caller_check"]])
