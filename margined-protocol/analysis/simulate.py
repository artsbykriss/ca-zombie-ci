#!/usr/bin/env python3
"""Read-only dry-run probe v2: uses a locally generated (throwaway) keypair to build an
UNSIGNED/simulated tx against /cosmos/tx/v1beta1/simulate. No broadcast, no state change.
The key is generated locally and never used to sign or send anything on-chain.
"""
import json, base64, urllib.request, urllib.error, sys, hashlib, subprocess, os

UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"}

# ---- bech32 (reference impl) ----
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def bech32_polymod(values):
    gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    chk = 1
    for v in values:
        b = chk >> 25
        chk = (chk & 0x1ffffff) << 5 ^ v
        for i in range(5):
            chk ^= gen[i] if ((b >> i) & 1) else 0
    return chk
def bech32_hrp_expand(hrp):
    return [ord(x) >> 5 for x in hrp] + [0] + [ord(x) & 31 for x in hrp]
def bech32_create_checksum(hrp, data):
    values = bech32_hrp_expand(hrp) + data
    polymod = bech32_polymod(values + [0,0,0,0,0,0]) ^ 1
    return [(polymod >> 5 * (5 - i)) & 31 for i in range(6)]
def convertbits(data, frombits, tobits, pad=True):
    acc = 0; bits = 0; ret = []
    maxv = (1 << tobits) - 1
    for value in data:
        acc = (acc << frombits) | value
        bits += frombits
        while bits >= tobits:
            bits -= tobits
            ret.append((acc >> bits) & maxv)
    if pad and bits:
        ret.append((acc << (tobits - bits)) & maxv)
    return ret
def bech32_encode(hrp, data):
    combined = data + bech32_create_checksum(hrp, data)
    return hrp + '1' + ''.join([CHARSET[d] for d in combined])

def ripemd160(data: bytes) -> bytes:
    import subprocess
    p = subprocess.run(["openssl", "dgst", "-provider", "legacy", "-ripemd160", "-binary"],
                       input=data, capture_output=True)
    if p.returncode == 0 and len(p.stdout) == 20:
        return p.stdout
    raise RuntimeError("ripemd160 failed: " + p.stderr.decode()[:200])

def cosmos_address(pubkey_compressed_hex, prefix):
    pk = bytes.fromhex(pubkey_compressed_hex)
    h = hashlib.sha256(pk).digest()
    r = ripemd160(h)
    return bech32_encode(prefix, convertbits(list(r), 8, 5))

KEY_FILE = "/tmp/opencode/simprobe_key.json"

def ensure_key():
    if os.path.exists(KEY_FILE):
        return json.load(open(KEY_FILE))
    r = subprocess.run(["cast", "wallet", "new"], capture_output=True, text=True)
    out = (r.stdout or "") + (r.stderr or "")
    pk = None
    for line in out.splitlines():
        if "Private key" in line or "private key" in line.lower():
            pk = line.split(":")[-1].strip()
    r2 = subprocess.run(["cast", "wallet", "public-key", "--private-key", pk], capture_output=True, text=True)
    pub = ((r2.stdout or "") + (r2.stderr or "")).strip().splitlines()[0].strip()
    d = {"pk": pk, "pub_raw": pub}
    if pub.startswith("0x"):
        pub = pub[2:]
    if len(pub) == 130 and pub.startswith("04"):
        x = bytes.fromhex(pub[2:66]); y = bytes.fromhex(pub[66:])
        prefix = "02" if y[-1] % 2 == 0 else "03"
        d["pub_compressed"] = prefix + x.hex()
    elif len(pub) == 128:
        x = bytes.fromhex(pub[:64]); y = bytes.fromhex(pub[64:])
        prefix = "02" if y[-1] % 2 == 0 else "03"
        d["pub_compressed"] = prefix + x.hex()
    elif len(pub) == 66:
        d["pub_compressed"] = pub
    else:
        raise RuntimeError("unexpected pubkey: " + pub)
    json.dump(d, open(KEY_FILE, "w"))
    return d

CHAINS = {
    "osmosis": {"bases": ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com"], "prefix": "osmo"},
    "neutron": {"bases": ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"], "prefix": "neutron"},
}

def simulate(chain, contract, msg, funds=None, sender=None, memo=""):
    ch = CHAINS[chain]
    key = ensure_key()
    addr = sender or cosmos_address(key["pub_compressed"], ch["prefix"])
    body = {"tx": {"body": {"messages": [{
        "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
        "sender": addr, "contract": contract,
        "msg": base64.b64encode(json.dumps(msg).encode()).decode(),
        "funds": funds or []}], "memo": memo,
        "timeout_height": "0", "extension_options": [], "non_critical_extension_options": []},
        "auth_info": {"signer_infos": [{"public_key": {"@type": "/cosmos.crypto.secp256k1.PubKey",
                                                      "key": base64.b64encode(bytes.fromhex(key["pub_compressed"])).decode()},
                                        "mode_info": {"single": {"mode": "SIGN_MODE_DIRECT"}}, "sequence": "0"}],
                      "fee": {"amount": [], "gas_limit": "0", "payer": "", "granter": ""}},
        "signatures": [base64.b64encode(b"\x00" * 64).decode()]}}
    data = json.dumps(body).encode()
    errs = []
    for base in ch["bases"]:
        req = urllib.request.Request(base + "/cosmos/tx/v1beta1/simulate", data=data, headers=UA)
        try:
            with urllib.request.urlopen(req, timeout=25) as r:
                return {"ok": True, "resp": json.loads(r.read().decode()), "base": base, "sender": addr}
        except urllib.error.HTTPError as e:
            return {"ok": False, "http": e.code, "body": e.read().decode()[:800], "base": base, "sender": addr}
        except Exception as e:
            errs.append(f"{base}: {e}")
    return {"ok": False, "errs": errs, "sender": addr}

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("chain"); ap.add_argument("contract"); ap.add_argument("msg_json")
    ap.add_argument("--sender"); ap.add_argument("--funds")
    a = ap.parse_args()
    funds = json.loads(a.funds) if a.funds else None
    r = simulate(a.chain, a.contract, json.loads(a.msg_json), funds=funds, sender=a.sender)
    print(json.dumps(r, indent=1)[:4000])

if __name__ == "__main__":
    main()
