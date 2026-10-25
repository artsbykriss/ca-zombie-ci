#!/usr/bin/env python3
"""Step 1b recon: pool token accounts, metadata, program header. Read-only."""
import json, base64, sys, os, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

MINT   = "LAYER4xPpTCb3QL8S9u41EAhAX7mhBn8Q6xMTwY2Yzc"
PROG   = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
POOL   = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
TOK22  = "BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
USDC   = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

out = {}
out["slot"] = s.get_slot()["result"]

# pool token accounts (both programs)
for pid, label in [("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", "spl"),
                   ("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb", "t22")]:
    r = s.get_token_accounts_by_owner(POOL, program_id=pid)
    val = (r.get("result") or {}).get("value", [])
    out["pool_tokaccts_" + label] = val
    print("pool", label, "n=", len(val))
    for it in val:
        pi = it["account"]["data"]["parsed"]["info"]
        print("   ", it["pubkey"], pi.get("mint"), pi.get("tokenAmount"), "delegated", pi.get("delegate"))

# program header
pv = s.get_account_info(PROG)["result"]["value"]
raw = base64.b64decode(pv["data"][0])
pd_addr = b58enc(raw[4:36])
out["programdata_addr"] = pd_addr
pd = s.get_account_info(pd_addr, encoding="base64")["result"]["value"]
pdraw = base64.b64decode(pd["data"][0])
last_deploy = struct.unpack_from("<Q", pdraw, 4)[0]
auth = b58enc(pdraw[13:45]) if pdraw[12] == 1 else None
out["programdata"] = {"addr": pd_addr, "space": pd["space"], "last_deploy_slot": last_deploy,
                      "upgrade_authority": auth}
print("programdata", pd_addr, "last_deploy", last_deploy, "upgrade_auth", auth)

# metadata for LAYER4x and cUSDO
def metadata(mint):
    # metaplex metadata PDA
    from hashlib import sha256
    seeds = [b"metadata", b58dec(b"metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"), b58dec(mint)]
    return None

def b58dec(sv):
    n = 0
    for c in sv: n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00" * pad + b

META_PROG = "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
def find_pda(seeds, program):
    for bump in range(255, -1, -1):
        h = sha256(bytes(seeds) + bytes([bump]) + b58dec(program) + b"ProgramDerivedAddress").digest()
        # check off-curve
        try:
            from nacl.signing import VerifyKey
        except Exception:
            pass
        # crude on-curve check via ed25519 decompress not available; just return first
        return h, bump
    return None

# Instead, use getProgramAccounts on metaplex filtered by mint
for name, mint in [("LAYER4x", MINT), ("cUSDO", TOK22)]:
    try:
        r = s.get_program_accounts(META_PROG, filters=[{"memcmp": {"offset": 33, "bytes": mint}}],
                                   encoding="base64")
        accts = r.get("result") or []
        out["meta_" + name] = accts
        for a in accts:
            d = base64.b64decode(a["account"]["data"][0])
            # borsh: key(1)+update_auth(32)+mint(32)+name(4+..)+symbol(4+..)+uri(4+..)
            o = 65
            def rdstr(o):
                ln = struct.unpack_from("<I", d, o)[0]; o += 4
                return d[o:o+ln].decode("utf8", "replace").rstrip("\x00"), o + ln
            nm, o = rdstr(o); sy, o = rdstr(o); ur, o = rdstr(o)
            print(name, "metadata name=", nm, "symbol=", sy, "uri=", ur)
    except Exception as e:
        print("meta err", name, e)

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon1b.json"), "w"), indent=1)
print("slot", out["slot"])
