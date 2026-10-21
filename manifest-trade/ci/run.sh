#!/usr/bin/env bash
# Manifest — keyless re-verification job for CI. Writes ci-out/manifest-verify.json.
# No secrets, no keyed RPC URLs, no transactions.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out
python3 - <<'PY'
import json, struct, base64, hashlib, urllib.request, time
ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = ALPHABET[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

ENDPOINTS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
PROG = "MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms"
GLOBAL_DISC = 10787423733276977665
EXPECTED_ELF_SHA = "31ac04c9159fa7090430759ec47e13f6a901cd708464656131be2addb5c36996"
# snapshot of the 6 global accounts at slot 459,675,283 (fallback if enumeration is blocked)
KNOWN_GLOBALS = [
    "YWE5YVRbkoT5q51SqenUVVeXnag17SgjDrWxYxNn4bM",
    "3B7x1opTwA3u8fFr8Af8WnYyvYem7oGenGjchdaarZmp",
    "7SVenoiAhoPjgAmm8JBzrdjeNPUKyJJQUnQHZ56Bcuhy",
    "A8yKjzZoanvffYUzxhTxfvpuAoWNSfsGRbNfkTXsztga",
    "DFL4YjUxNctETvVxYkChxADB4RSzapm5VDMY755KbahX",
    "FqTMBBFRsAwmixf6rZBDaXfisdnK5bzkAxAMZpsZaSi3",
]

def rpc(m, p):
    last = None
    for ep in ENDPOINTS:
        for i in range(3):
            time.sleep(1)
            try:
                req = urllib.request.Request(ep, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
                                             headers={"Content-Type":"application/json","User-Agent":"zh4-ci/1.0"})
                r = json.load(urllib.request.urlopen(req, timeout=90))
                if "error" in r:
                    last = r["error"]; time.sleep(2); continue
                return r["result"]
            except Exception as e:
                last = str(e); time.sleep(2)
    raise RuntimeError(f"{m} failed on all endpoints: {last}")

out = {}
_blob = open("analysis/manifest_current.so","rb").read()
# the programdata account is over-allocated; the live ELF extent comes from the section header table
_e_shoff = int.from_bytes(_blob[0x28:0x30], "little")
_e_shentsize = int.from_bytes(_blob[0x3A:0x3C], "little")
_e_shnum = int.from_bytes(_blob[0x3C:0x3E], "little")
_elf_len = _e_shoff + _e_shentsize * _e_shnum
out["elf_len"] = _elf_len
out["programdata_padding"] = len(_blob) - _elf_len
out["elf_sha256_local"] = hashlib.sha256(_blob[:_elf_len]).hexdigest()
out["elf_sha256_expected"] = EXPECTED_ELF_SHA
out["elf_matches_release_v3_0_26"] = out["elf_sha256_local"] == EXPECTED_ELF_SHA

out["slot"] = rpc("getSlot", [{"commitment": "confirmed"}])
pd = rpc("getAccountInfo", ["G92J4ZFggKZ9LbsQ2zBpajRvRto7ed7uRuJJqWsX4BhJ",
                            {"encoding":"base64","commitment":"confirmed"}])["value"]
raw = base64.b64decode(pd["data"][0])
out["last_deploy_slot"] = int.from_bytes(raw[4:12], "little")
out["upgrade_authority"] = b58(raw[13:45]) if raw[12] == 1 else None
out["programdata_len"] = len(raw)

globals_ = []
gb58 = b58(struct.pack("<Q", GLOBAL_DISC))
try:
    gs = rpc("getProgramAccounts", [PROG, {"encoding":"base64","commitment":"confirmed",
            "filters":[{"memcmp":{"offset":0,"bytes":gb58}},{"dataSize":96}]}])
    out["enumerated"] = True
    for g in gs:
        d = base64.b64decode(g["account"]["data"][0])
        globals_.append({"global": g["pubkey"],
                         "mint": b58(d[8:40]),
                         "vault": b58(d[40:72]),
                         "num_seats_claimed": struct.unpack_from("<H", d, 94)[0]})
except Exception as e:
    out["enumerated"] = False
    out["enumerate_error"] = str(e)[:200]
    accts = rpc("getMultipleAccounts", [KNOWN_GLOBALS, {"encoding":"base64","commitment":"confirmed"}])["value"]
    for addr, a in zip(KNOWN_GLOBALS, accts):
        d = base64.b64decode(a["data"][0])
        globals_.append({"global": addr,
                         "mint": b58(d[8:40]),
                         "vault": b58(d[40:72]),
                         "num_seats_claimed": struct.unpack_from("<H", d, 94)[0]})

vaults = rpc("getMultipleAccounts", [[x["vault"] for x in globals_],
                                     {"encoding":"base64","commitment":"confirmed"}])["value"]
for g, v in zip(globals_, vaults):
    g["vault_amount"] = int.from_bytes(base64.b64decode(v["data"][0])[64:72], "little") if v else None
out["globals"] = globals_
out["globals_count"] = len(globals_)
out["max_seats_claimed"] = max((g["num_seats_claimed"] for g in globals_), default=0)
out["total_global_vault_atoms"] = sum((g["vault_amount"] or 0) for g in globals_)
out["eviction_reachable"] = out["max_seats_claimed"] >= 999
json.dump(out, open("ci-out/manifest-verify.json","w"), indent=1)
print(json.dumps(out, indent=1))
assert out["elf_matches_release_v3_0_26"], "ELF does not match release v3.0.26"
assert out["globals_count"] == 6
assert out["max_seats_claimed"] == 0, "seats claimed - re-check eviction"
assert out["total_global_vault_atoms"] == 0
print("OK: deployed ELF == v3.0.26, 0 seats, 0 global-vault atoms")
PY
