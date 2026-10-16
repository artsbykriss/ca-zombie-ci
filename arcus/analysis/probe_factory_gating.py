#!/usr/bin/env python3
"""
Arcus factory/pToken gating matrix (read-only). Reproduces the §3/§4 tables in child-ptokens-admin.md.
Runs eth_call from several senders against the local fork (anvil --fork-url <rpc> --port 8547) or any RPC.
Expected results (verified 2026-10-16, block ~89.75M):
  - 0x4e666f20 / 0xc2eabaf3 / 0xd3c5ee0e / 0xfe618ab1  -> OK from roleB members
        (deployer 0x38d0eaba, safe 0x81B80499, 0x001232c6, 0x57D32496); revert 0xe2517d3f(role=0xfb488cd4..)
        from manager/NAV-signer/random.
  - 0x5df8122f / 0xed6d7b26 -> OK from roleA (safe, 0x57D32496); revert 0xe2517d3f(role=0xb91dda2c..) others.
  - 0x8da87eb1 / 0xd42afb56 / 0xebcb0b7a / 0xfb94bd8a / 0x4f1ef286 -> only SAFE (DEFAULT_ADMIN);
        others revert 0xe2517d3f(role=0x0). 0x8da87eb1 accepts only value 1 today.
  - pTEST3 deposit -> revert 0x6565c4ec(amount, quota=0) for every sender (step 1: per-account quota at
        pToken ns 0xd9fd...2a12; step 2: factory allowlist 0x1c0d9bca = map5 || map6).
"""
import json, urllib.request

RPC = "http://127.0.0.1:8547"   # or https://rpc.mainnet.chain.robinhood.com
def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
                                 headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=120) as r: d = json.load(r)
    if "error" in d: raise RuntimeError(json.dumps(d["error"])[:300])
    return d["result"]

F = "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB"
pad_a = lambda a: "0"*24 + a.lower().replace("0x","")
pad_u = lambda x: f"{x:064x}"

pBTC3x = "0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e"
pTEST  = "0x1193BcBfaFeB2F25C516817C46BD3143936d1d5C"
pTEST3 = "0x122408C1399E51C41B096402fea46e20E762A950"
CUR_IMPL = "0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f"
dead = "0x000000000000000000000000000000000000dEaD"

SENDERS = {
 "deployer(roleA? no, roleB yes)": "0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101",
 "safe (DEFAULT_ADMIN+roleA+roleB)": "0x81B80499C396a9931b9e44953425a82C1b2541bd",
 "0x57D32496 (roleA+roleB)": "0x57D32496efA0ebe68C1AEd77c9d46EC99c4f5b78",
 "manager EOA (no roles)": "0xB7410dc44e2715161E9914272e2D55D7c5061FAa",
 "NAV signer (NAV_SIGNER only)": "0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A",
 "random": dead,
}

TESTS = [
 ("class Factory (UUPS) 0x9c3663...", F, [
    ("0x4e666f20(pBTC3x, 2.5e11)", "0x4e666f20" + pad_a(pBTC3x) + pad_u(250000000000)),
    ("0xc2eabaf3(pBTC3x, true)",   "0xc2eabaf3" + pad_a(pBTC3x) + pad_u(1)),
    ("0xd3c5ee0e(pTEST, [dead], true)",
        "0xd3c5ee0e" + pad_a(pTEST) + pad_u(0x60) + pad_u(1) + pad_u(1) + pad_a(dead)),
    ("0xfe618ab1([dead], true)", "0xfe618ab1" + pad_u(0x40) + pad_u(1) + pad_u(1) + pad_a(dead)),
    ("0x5df8122f(pBTC3x, manager)", "0x5df8122f" + pad_a(pBTC3x) + pad_a("0xB7410dc44e2715161E9914272e2D55D7c5061FAa")),
    ("0x8da87eb1(1)", "0x8da87eb1" + pad_u(1)),
    ("0xd42afb56(beacon)", "0xd42afb56" + pad_a("0x33846348210A0Cc0345F354d9DE52b89AD473A76")),
    ("0xebcb0b7a(vault)", "0xebcb0b7a" + pad_a("0xD42c46c7BaD6A54b38395F846b09981CE75fb8e2")),
    ("0xfb94bd8a('x')", "0xfb94bd8a" + pad_u(0x20) + pad_u(1) + ("78" + "00"*31)),
    ("0x4f1ef286(curImpl,'')", "0x4f1ef286" + pad_a(CUR_IMPL) + pad_u(0x40) + pad_u(0)),
    ("0x4d9f30fc(2) [view, expect OK for everyone]", "0x4d9f30fc" + pad_u(2)),
 ]),
 ("pToken pTEST3 (empty) 0x122408C1...", pTEST3, [
    ("convertToShares(1e6)", "0xc6e6f592" + pad_u(10**6)),   # expect 1e16
    ("convertToAssets(1e18)", "0x07a2d13a" + pad_u(10**18)), # expect 1e8
    ("maxDeposit(dead)", "0x402d267d" + pad_a(dead)),        # expect 0
    ("deposit(1e6, dead)", "0x6e553f65" + pad_u(10**6) + pad_a(dead)),  # expect revert 0x6565c4ec(1e6,0)
 ]),
]

for title, to, tests in TESTS:
    print(f"\n=== {title}")
    for label, data in tests:
        print(f"\n-- {label}")
        for sname, s in SENDERS.items():
            try:
                r = rpc("eth_call", [{"to": to, "data": data, "from": s}, "latest"])
                print(f"   [{sname}] OK {r[:50]}")
            except Exception as e:
                s_ = str(e)
                import re
                m = re.search(r"custom error 0x([0-9a-f]+): ([0-9a-f]*)", s_)
                if m:
                    role = m.group(2)[-64:]
                    print(f"   [{sname}] REVERT 0x{m.group(1)} role/args=0x{role}")
                else:
                    print(f"   [{sname}] REVERT {s_[:110]}")
