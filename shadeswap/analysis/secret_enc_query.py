#!/usr/bin/env python3
"""Encrypted smart-query client for Secret Network (secretd >= 1.2x, 2026 protocol).

Replicates secretd's WASMContext.Encrypt/Decrypt:
  - IO pubkey via ABCI /secret.registration.v1beta1.Query/TxKey
  - ephemeral X25519 keypair; HKDF-SHA256(ikm||nonce, salt) -> AES-CMAC-SIV key
  - plaintext = codeHash || queryJSON  (SecretMsg.Serialize())
  - blob = nonce(32) || senderPub(32) || siv_ct
Read-only; no secrets stored.
"""
import base64
import hashlib
import hmac
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from secret_abci import abci_query, parse_proto, ld  # noqa

from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESSIV

HKDF_SALT = bytes.fromhex("000000000000000000024bead8df69990852c202db0e0097c1a12ea637d7e96d")

_rpc = {"url": "https://rpc.secret.mainnet.secret3.dev"}


def hkdf_sha256(ikm: bytes, salt: bytes, info: bytes, length: int) -> bytes:
    prk = hmac.new(salt, ikm, hashlib.sha256).digest()
    okm, t, i = b"", b"", 1
    while len(okm) < length:
        t = hmac.new(prk, t + info + bytes([i]), hashlib.sha256).digest()
        okm += t
        i += 1
    return okm[:length]


def get_io_key(retries=4):
    last = None
    for a in range(retries):
        try:
            raw, h = abci_query("/secret.registration.v1beta1.Query/TxKey", b"", rpc=_rpc["url"])
            for f, wt, v in parse_proto(raw):
                if f == 1:
                    return v, h
            raise RuntimeError("no key field in TxKey response")
        except Exception as e:
            last = e
            time.sleep(1.5 * (a + 1))
    raise RuntimeError(f"TxKey failed: {last}")


def get_code_hash(addr: str):
    raw, h = abci_query("/secret.compute.v1beta1.Query/CodeHashByContractAddress", ld(1, addr.encode()), rpc=_rpc["url"])
    for f, wt, v in parse_proto(raw):
        if f == 1 and wt == 2:
            return v.decode(), h
    raise RuntimeError("no code_hash")


def encrypt_query(code_hash: str, query: dict):
    io_key, io_h = get_io_key()
    priv = X25519PrivateKey.generate()
    pub = priv.public_key().public_bytes_raw()
    ikm = priv.exchange(X25519PublicKey.from_public_bytes(io_key))
    nonce = os.urandom(32)
    key = hkdf_sha256(ikm + nonce, HKDF_SALT, b"", 32)
    plaintext = code_hash.encode() + json.dumps(query).encode()  # code hash = HEX STRING bytes
    siv = AESSIV(key)
    ct = siv.encrypt(plaintext, [b""])
    blob = nonce + pub + ct
    return blob, key, nonce


def decrypt_response(key: bytes, blob: bytes):
    siv = AESSIV(key)
    try:
        return siv.decrypt(blob, [b""])
    except Exception:
        return None


def decrypt_error(key: bytes, err: str):
    import re
    m = re.search(r"encrypted: (.+?):", err)
    if not m:
        return None
    try:
        ct = base64.b64decode(m.group(1))
        return decrypt_response(key, ct)
    except Exception:
        return None


def smart_query(addr: str, query: dict, rpc: str = None, retries: int = 3):
    if rpc:
        _rpc["url"] = rpc
    code_hash, ch = get_code_hash(addr)
    blob, key, nonce = encrypt_query(code_hash, query)
    data = ld(1, addr.encode()) + ld(2, blob)
    last = None
    for a in range(retries):
        try:
            raw, h = abci_query("/secret.compute.v1beta1.Query/QuerySecretContract", data, rpc=_rpc["url"])
            plain = None
            for f, wt, v in parse_proto(raw):
                if f == 1 and wt == 2:
                    plain = decrypt_response(key, v)
            if plain is None:
                raise RuntimeError("response decrypt failed")
            txt = plain.decode(errors="replace")
            # official CLI base64-decodes the decrypted payload
            try:
                txt2 = base64.b64decode(txt).decode()
                if txt2.strip().startswith(("{", "[")):
                    txt = txt2
            except Exception:
                pass
            return json.loads(txt), h
        except Exception as e:
            msg = str(e)
            de = decrypt_error(key, msg)
            if de is not None:
                raise RuntimeError(f"contract error: {de.decode(errors='replace')[:300]}")
            last = e
            time.sleep(1.5 * (a + 1))
    raise RuntimeError(f"smart_query failed: {last}")


if __name__ == "__main__":
    addr = sys.argv[1]
    q = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {"token_info": {}}
    res, h = smart_query(addr, q)
    print(json.dumps({"height": h, "result": res}, indent=1))
