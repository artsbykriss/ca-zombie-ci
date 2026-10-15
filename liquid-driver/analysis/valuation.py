#!/usr/bin/env python3
"""Valuation: prices for all underlyings + Beethoven BPT resolution."""
import sys, json, urllib.request, subprocess
sys.path.insert(0, "/home/heisenberg/CA/liquid-driver/analysis")
from fetch_state import rpc_batch, call, addr_result, int_result, enc_addr, enc_uint

F = "fantom"
VAULT = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce"  # Beethoven X vault
out = {}

# collect all underlying tokens from CI live-state
d = json.load(open("/home/heisenberg/CA/liquid-driver/ci-artifacts/result-liquid-driver/ci-out/live-state.json"))
tokens = set()
for lp, m in d["lpmeta"].items():
    for k in ("token0", "token1"):
        if m.get(k): tokens.add(m[k].lower())
tokens.add("0x04068da6c83afcfa0e13ba15a6696662335d5b75")  # USDC
tokens.add("0x049d68029688eabf473097a2fc38ef61633a3c7a")  # fUSDT
tokens = sorted(tokens)
print("tokens:", len(tokens))

# DefiLlama prices in batches of 50
prices = {}
for i in range(0, len(tokens), 40):
    batch = tokens[i:i+40]
    url = "https://coins.llama.fi/prices/current/" + ",".join(f"fantom:{t}" for t in batch)
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=40) as r:
            pd = json.loads(r.read().decode())
        for k, v in (pd.get("coins") or {}).items():
            prices[k] = {"usd": v["price"], "symbol": v.get("symbol")}
    except Exception as e:
        print("llama batch fail:", e)
print("priced:", len(prices), "of", len(tokens))
for t in tokens:
    k = f"fantom:{t}"
    if k in prices:
        print(f"  {t} {prices[k]['symbol']} = {prices[k]['usd']}")
    else:
        print(f"  {t} UNPRICED")
out["prices"] = prices

# Beethoven vault pool tokens for the BPTs held by MiniChef
bp = "0xcdf68a4d525ba2e90fe959c74330430a5a6b8226"
bpt2 = "0xc0064b291bd3d4ba0e44ccfc81bf8e7f7a579cd2"
# try known poolIds from DefiLlama adapter
poolids = {
    bp: "0xcdf68a4d525ba2e90fe959c74330430a5a6b8226000200000000000000000008",
    bpt2: "0xc0064b291bd3d4ba0e44ccfc81bf8e7f7a579cd200000000000000000000042c",
}
# find poolId via PoolRegistered logs (topic0 = keccak(PoolRegistered(bytes32,address,uint8)))
t0 = subprocess.run(["cast", "keccak", "PoolRegistered(bytes32,address,uint8)"], capture_output=True, text=True).stdout.strip()
print("PoolRegistered topic0:", t0)
for bpt in [bp, bpt2, "0x30a92a4eeca857445f41e4bb836e64d66920f1c0", "0x8f6a658056378558ff88265f7c9444a0fb4db4be",
            "0x8b858eaf095a7337de6f9bc212993338773ca34e", "0x4e415957aa4fd703ad701e43ee5335d1d7891d83",
            "0x56ad84b777ff732de69e85813daee1393a9ffe10", "0xeadcfa1f34308b144e96fcd7a07145e027a8467d",
            "0xf6b8d1167aa8e0f070c50ca3552106e7604c6640", "0x95f959994df1d5df422f814641d0d1c93b621f62",
            "0x72bc4be6642355e820318f696340bfd8f2c7aa4e"]:
    r = rpc_batch(F, [("eth_getLogs", [{"address": VAULT, "topics": [t0, None, "0x" + bpt[2:].lower().rjust(64, "0")], "fromBlock": "0x0", "toBlock": "latest"}])])
    logs = r[0] if r else None
    if isinstance(logs, list) and logs:
        pid = logs[-1]["topics"][1]
        out.setdefault("poolids", {})[bpt] = pid
        print(f"  {bpt} poolId {pid} (logs {len(logs)})")
    else:
        print(f"  {bpt} no PoolRegistered log ({str(logs)[:60]})")

# getPoolTokens for each resolved poolId
sel_gpt = subprocess.run(["cast", "sig", "getPoolTokens(bytes32)"], capture_output=True, text=True).stdout.strip()
for bpt, pid in (out.get("poolids") or {}).items():
    r = call(F, VAULT, sel_gpt, pid[2:])
    if isinstance(r, str) and len(r) > 2:
        b = bytes.fromhex(r[2:])
        off_t = int.from_bytes(b[0:32], "big"); off_bal = int.from_bytes(b[32:64], "big")
        n = int.from_bytes(b[off_t:off_t+32], "big")
        toks = []
        for i in range(n):
            toks.append("0x" + b[off_t+32+32*i+12:off_t+64+32*i].hex())
        nb = int.from_bytes(b[off_bal:off_bal+32], "big")
        bals = []
        for i in range(nb):
            bals.append(int.from_bytes(b[off_bal+32+32*i:off_bal+64+32*i], "big"))
        out.setdefault("pooltokens", {})[bpt] = {"tokens": toks, "balances": bals}
        print(f"  {bpt}: {list(zip(toks, bals))}")
    else:
        print(f"  {bpt}: getPoolTokens failed {str(r)[:80]}")

with open("/home/heisenberg/CA/liquid-driver/analysis/valuation.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved valuation.json")
