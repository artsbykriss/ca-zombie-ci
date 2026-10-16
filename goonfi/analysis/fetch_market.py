#!/usr/bin/env python3
"""Fetch + decode market state accounts and vaults for GoonFi."""
import json, os, sys, base64, struct, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58e(b):
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


def b58d(s):
    n = 0
    for ch in s:
        n = n * 58 + B58.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for ch in s:
        if ch == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b


ACCS = {
    "market_Daop": "Daopjqyt5qZZ111x7MDbWbxtf72cdNEUnCECzZ7hVpbp",
    "vault_J7rc": "J7rc6e6jkQFQ4hWJ9c3rShgmeSFDjJ38HW1fa6jV9JV6",
    "vault_mbbg": "mbbgY8AQttyUZHoJSHrt3Rg4cz81tB6LKqvccPicuFe",
    "mint_6p6x": "6p6xgHyF7AeE6TZkSmFsko444wqoP15icUSqi2jfGiPN",
    "oracle_FggV": "FggV5dLyuFC5SMqxhpF64xkHu1rXiTUP3CwufV5ZSam4",
    "ag3hi": "Ag3hiK9svNixH9Vu5sD2CmK5fyDWrx9a1iVSbZW22bUS",
    "incident_oracle_7yec": "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3",
    "incident_market_GMCJ": "GMCJvYGf5Ex2ARiMquaBDqU6iKM8uiEQkB8jCnoNfHpC",
    "incident_wsol_vault": "8ncU5YW1CQwvr4gs7buH57bW58e86TDau4STrCJBuz8z",
    "incident_usdc_vault": "EunHLeqeJKvxnCPQSytnBP63HJVk2fbHceiKKpngyAo8",
    "oracle_prog_dijkbk": "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu",
    "prog_goonuddt": "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE",
}


def token_acct(raw):
    # SPL Token account (165 bytes): mint(32) owner(32) amount(8) delegate(36) state(1) is_native(12) delegated(12) close(12)
    return {
        "mint": b58e(raw[0:32]),
        "owner": b58e(raw[32:64]),
        "amount": struct.unpack("<Q", raw[64:72])[0],
        "state": raw[108],
        "is_native": struct.unpack("<Q", raw[109:117])[0],
    }


def main():
    out = {}
    for label, addr in ACCS.items():
        r = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
        v = r.get("result", {}).get("value")
        if not v:
            print(label, addr, "MISSING"); out[label] = {"addr": addr, "exists": False}; continue
        raw = base64.b64decode(v["data"][0])
        info = {"addr": addr, "exists": True, "owner": v["owner"], "lamports": v["lamports"], "len": len(raw)}
        if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" and len(raw) == 165:
            info["token"] = token_acct(raw)
        if len(raw) == 2048:
            info["hex0_256"] = raw[:256].hex()
            info["hex256_512"] = raw[256:512].hex()
            # find candidate pubkeys: 32-byte windows that are valid base58 pubkey-ish (non-zero, not all same)
            info["u64s"] = {str(o): struct.unpack("<Q", raw[o:o + 8])[0] for o in range(0, 256, 8)}
        if len(raw) in (32, 36, 40, 48, 64, 72, 80):
            info["hex"] = raw.hex()
        out[label] = info
        print(label, addr, "owner=", v["owner"], "len=", len(raw), "lamports=", v["lamports"])
        if "token" in info:
            print("   token:", json.dumps(info["token"]))
    with open(os.path.join(OUT, "market-accounts.json"), "w") as f:
        json.dump(out, f, indent=1)


if __name__ == "__main__":
    main()
