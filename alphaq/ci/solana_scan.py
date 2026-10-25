#!/usr/bin/env python3
"""AlphaQ (Solana) read-only enumeration + simulation battery.

Runs entirely against keyless public Solana JSON-RPC endpoints. No signing, no
broadcast: only getSignaturesForAddress / getTransaction / getProgramAccounts /
getMultipleAccounts / simulateTransaction(sigVerify=false, replaceRecentBlockhash=true).

Outputs JSON into ../ci-out/.
"""
import base64
import collections
import json
import os
import sys
import time
import urllib.request

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]
PID = "ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58dec(s):
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for c in s:
        if c == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b


def b58enc(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = A[r] + s
    pad = 0
    for c in b:
        if c == 0:
            pad += 1
        else:
            break
    return "1" * pad + (s or "")


def cu(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)


def _post(url, body, timeout=120):
    req = urllib.request.Request(
        url, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    return urllib.request.urlopen(req, timeout=timeout)


def call(method, params, retries=8):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        url = ENDPOINTS[i % len(ENDPOINTS)]
        try:
            r = json.load(_post(url, body))
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(min(30, 1.5 * (2 ** i)))
    raise last


def fullkeys(tx):
    m = tx["transaction"]["message"]
    k = list(m["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or [])
    k += list(la.get("readonly") or [])
    return k


def aq_ixs(tx):
    keys = fullkeys(tx)
    out = []
    for i, ix in enumerate(tx["transaction"]["message"]["instructions"]):
        if keys[ix["programIdIndex"]] == PID:
            out.append(("top", i, ix, keys))
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            if ix["programIdIndex"] < len(keys) and keys[ix["programIdIndex"]] == PID:
                out.append(("inner%d" % g["index"], None, ix, keys))
    return out


def scan_instructions(n=1000):
    sigs = call("getSignaturesForAddress", [PID, {"limit": min(1000, n)}])
    hist = collections.Counter()
    samples = {}
    txs_ok = 0
    for i, s in enumerate(sigs):
        try:
            tx = call("getTransaction", [s["signature"], {"encoding": "json", "maxSupportedTransactionVersion": 1}], retries=4)
        except Exception:  # noqa: BLE001
            continue
        if not tx:
            continue
        txs_ok += 1
        for kind, idx, ix, keys in aq_ixs(tx):
            raw = b58dec(ix["data"])
            key = "%d:%d" % (raw[0] if raw else -1, len(raw))
            hist[key] += 1
            if key not in samples:
                samples[key] = {
                    "sig": s["signature"], "slot": tx["slot"], "kind": kind,
                    "data": raw.hex(),
                    "accounts": [keys[a] for a in ix["accounts"]],
                    "err": tx["meta"]["err"],
                }
        if i % 100 == 99:
            print("scan ...", i + 1, dict(hist), flush=True)
    return {"program": PID, "n_sigs": len(sigs), "n_txs": txs_ok, "hist": dict(hist), "samples": samples}


def enumerate_state():
    accts = call("getProgramAccounts", [PID, {"encoding": "base64"}])
    markets = [a for a in accts if a["account"]["space"] == 672]
    stats = [a for a in accts if a["account"]["space"] == 336]
    glob = [a for a in accts if a["account"]["space"] == 504]
    # candidate vault/authority pubkeys live at fixed 32-byte slots of the 672B market account
    cand = {}
    for a in markets:
        raw = base64.b64decode(a["account"]["data"][0])
        for off in range(0, len(raw) - 31):
            w = raw[off:off + 32]
            if w == b"\x00" * 32:
                continue
            cand.setdefault(b58enc(w), set()).add(off)
    # keep candidates that appear at >=2 distinct aligned-ish offsets or look like token accts later
    keys = sorted(cand)
    info = {}
    for i in range(0, len(keys), 100):
        chunk = keys[i:i + 100]
        vals = call("getMultipleAccounts", [chunk, {"encoding": "jsonParsed"}])
        for k, v in zip(chunk, vals["value"]):
            if v and v["owner"] in ("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                                    "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"):
                try:
                    pi = v["data"]["parsed"]["info"]
                    info[k] = {"mint": pi.get("mint"), "authority": pi.get("owner"),
                               "amount": pi.get("tokenAmount", {}).get("amount"),
                               "decimals": pi.get("tokenAmount", {}).get("decimals"),
                               "tokenProgram": v["owner"], "offsets": sorted(cand[k])}
                except Exception:  # noqa: BLE001
                    pass
    return {
        "program": PID,
        "n_markets_672": len(markets),
        "n_stats_336": len(stats),
        "n_global_504": len(glob),
        "market_names": sorted(base64.b64decode(a["account"]["data"][0])[:8].decode("ascii", "replace") for a in markets),
        "global_account": glob[0]["pubkey"] if glob else None,
        "token_accounts": info,
    }


def build_legacy(signer, writable, readonly, blockhash, instructions):
    keys = [signer] + writable + readonly
    idx = {k: i for i, k in enumerate(keys)}
    msg = bytearray()
    msg += bytes([1, 0, len(readonly)])
    msg += cu(len(keys))
    for k in keys:
        msg += b58dec(k)
    msg += b58dec(blockhash)
    msg += cu(len(instructions))
    for pid, accts, data in instructions:
        msg += bytes([idx[pid]])
        msg += cu(len(accts))
        for a in accts:
            msg += bytes([idx[a]])
        msg += cu(len(data))
        msg += data
    return base64.b64encode(cu(1) + b"\x00" * 64 + bytes(msg)).decode()


def simulate(tx_b64):
    return call("simulateTransaction", [tx_b64, {
        "encoding": "base64", "sigVerify": False,
        "replaceRecentBlockhash": True, "commitment": "processed",
    }])


def sim_battery():
    USER = "ARu4n5mFdZogZAravu7CcizaojWnS6oqka37gdLT5SZn"
    MARKET = "9xPhpwq6GLUkrDBNfXCbnSP9ARAMMyUQqgkrqaDW6NLV"
    STATS = "H18xqLYd5uEenmiFKoXkgrTvyhnLgJMPT8sSvdZPpi3p"
    UA = "C1qMskwQhQ4cn1M6RG8uWfUuMrq6ysRPEHccGxk4tjw8"   # user USD1
    UB = "8XrtGP8RG33AnrN2yJ6H3gnXPNQ3dYXKqM72bpzhcsd6"   # user USDC
    VA = "CQUfYBxF2KFVjYyCPyGa7JCFX9zw2PwmNnECzY3merGA"   # USD1 vault
    VB = "F2KCaXcp7AoQtxTDvNEDCyMyWjSCAMWNzcyN9dsPfPs5"   # USDC vault
    TK = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    SI = "Sysvar1nstructions1111111111111111111111111"
    USD1 = "USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB"
    USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    ATT = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1"
    AUTH = "ALPHAQuu7dmdpSQfg2oPvSvACSCkAYgGENVpEwjCWNJf"
    BH = "11111111111111111111111111111111"

    def base():
        return [USER, MARKET, STATS, UA, UB, VA, VB, VA, VB, VB, TK, SI]

    def run(label, accts, data, signer=None, signer_set=None):
        signer = signer or USER
        writable, readonly = [], []
        for a in accts:
            if a in (TK, SI, PID, MARKET):
                if a not in readonly:
                    readonly.append(a)
            elif a != signer and a not in writable:
                writable.append(a)
        if PID not in readonly:
            readonly.append(PID)
        tx = build_legacy(signer, writable, readonly, BH, [(PID, accts, data)])
        try:
            r = simulate(tx)
        except Exception as e:  # noqa: BLE001
            return {"label": label, "rpc_error": str(e)}
        v = r["value"]
        pre = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (v.get("preTokenBalances") or [])}
        post = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (v.get("postTokenBalances") or [])}
        deltas = {}
        for i in sorted(set(pre) | set(post)):
            if pre.get(i) != post.get(i):
                deltas[str(i)] = {"account": accts[i] if i < len(accts) else None,
                                  "pre": pre.get(i), "post": post.get(i),
                                  "delta": (post.get(i) or 0) - (pre.get(i) or 0)}
        return {"label": label, "err": v["err"], "cu": v.get("unitsConsumed"),
                "deltas": deltas, "logs": [l for l in (v.get("logs") or []) if "failed" in l or "ALPHAQ" in l]}

    A18 = "0c00e04de000000000000000000000000000"
    res = []
    res.append(run("control_swap", base(), bytes.fromhex(A18)))
    for lbl, mutate in [
        ("D1_input_vault:=user_usdc", lambda a: a.__setitem__(6, UB)),
        ("D1b_input_vault:=other_usdc_vault", lambda a: a.__setitem__(6, "6EcioYG5g5svhRS3dL28JKp7VytCf86WPe9dNWVY95oJ")),
        ("D1c_input_vault:=usdc_mint", lambda a: a.__setitem__(6, USDC)),
        ("D2_output_vault:=cash_vault_wrongmint", lambda a: a.__setitem__(5, "2foKAwvuvKfHjuVK6NjFG94cCTPCYWxbKRDjva9CtiJj")),
        ("D2b_output_vault:=input_vault", lambda a: a.__setitem__(5, VB)),
        ("D3_stats:=other_market_stats", lambda a: a.__setitem__(2, "aXQtJ9cGr1zgLyrppKJ5BR5jv1RMjyYL5Wetd2KZNtB")),
        ("D4_stats:=non_program_acct", lambda a: a.__setitem__(2, UB)),
        ("D5_market:=other_market", lambda a: a.__setitem__(1, "2YR8bXXn4tTnq8nVjvpYnBiQ7ZKjN3G16wxE8ShL3KaB")),
        ("D9_input_source:=usdc_vault", lambda a: a.__setitem__(4, VB)),
        ("D10_output_dest:=usd1_vault", lambda a: a.__setitem__(3, VA)),
    ]:
        a = base()
        mutate(a)
        res.append(run(lbl, a, bytes.fromhex(A18)))
    res.append(run("D6_amount=1", base(), bytes.fromhex("0c0001000000000000000000000000000000")))
    res.append(run("D6b_amount=0", base(), bytes.fromhex("0c0000000000000000000000000000000000")))
    res.append(run("D7b_amount=u64max", base(), bytes.fromhex("0c00ffffffffffffffff0000000000000000")))
    res.append(run("D8_direction=1", base(), bytes.fromhex("0c01e04de000000000000000000000000000")))
    # update_price gating re-verification (tag 0x0b)
    UPD = bytes.fromhex("0b018c1a6f5d8296e118a6837a1b0000000070802fd3765c4a806c130ec5020000003fbe4bd4e8000000d9af20d5e8000000")
    MKT2 = "61LMyNZudQFDNMRFKwkBmf5HtRf1vU8B8FgNYdrha3fq"
    res.append(run("upd_control_authority_signs", [AUTH, MKT2], UPD, signer=AUTH))
    res.append(run("upd_attacker_as_acct0", [ATT, MKT2], UPD, signer=ATT))
    res.append(run("upd_attacker_signs_real_auth_nonsigner", [AUTH, MKT2], UPD, signer=ATT))
    # tag probes: look for any unprivileged admin path
    extra = [MARKET, STATS, UA, UB, VA, VB, TK, SI, USD1, USDC,
             "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
             "11111111111111111111111111111111",
             "SysvarRent111111111111111111111111111111111",
             "SysvarC1ock11111111111111111111111111111111",
             "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
             "2WdXaRBZhPTUJRgHqJ4KJWEZ95EjccnnSiKhUuDMCSbg"]
    for tag, ac, dl in [(2, 6, 2), (4, 7, 10), (6, 7, 10), (8, 5, 10), (10, 2, 272),
                        (14, 3, 11), (1, 6, 10), (3, 16, 10), (5, 16, 10), (7, 6, 10),
                        (9, 16, 10), (13, 16, 10), (15, 16, 10), (16, 16, 10), (17, 12, 91)]:
        accts = [ATT] + extra[:ac - 1]
        res.append(run("tag%d_ac%d_dl%d" % (tag, ac, dl), accts, bytes([tag]) + bytes(dl - 1), signer=ATT))
    return res


def main():
    print("== program account ==", flush=True)
    pa = call("getAccountInfo", [PID, {"encoding": "base64"}])
    raw = base64.b64decode(pa["value"]["data"][0])
    pd_addr = b58enc(raw[4:36])
    pd = call("getAccountInfo", [pd_addr, {"encoding": "base64", "dataSlice": {"offset": 0, "length": 45}}])
    praw = base64.b64decode(pd["value"]["data"][0])
    import struct
    last_deploy = struct.unpack_from("<Q", praw, 4)[0]
    auth = b58enc(praw[13:45]) if praw[12] == 1 else None
    header = {"slot": pa["result"]["context"]["slot"] if "result" in pa else None,
              "programdata": pd_addr, "last_deploy_slot": last_deploy,
              "upgrade_authority": auth, "programdata_space": pd["value"]["space"],
              "elf_sha256_hint": None}
    json.dump(header, open(os.path.join(OUT, "program_header.json"), "w"), indent=1)
    print("header", header, flush=True)

    print("== scan instructions ==", flush=True)
    sc = scan_instructions(1000)
    json.dump(sc, open(os.path.join(OUT, "instruction_scan.json"), "w"), indent=1)
    print("hist", sc["hist"], flush=True)

    print("== enumerate state ==", flush=True)
    st = enumerate_state()
    json.dump(st, open(os.path.join(OUT, "state_enum.json"), "w"), indent=1)
    print("markets", st["n_markets_672"], "stats", st["n_stats_336"], "token_accounts", len(st["token_accounts"]), flush=True)

    print("== sim battery ==", flush=True)
    sb = sim_battery()
    json.dump(sb, open(os.path.join(OUT, "sim_battery.json"), "w"), indent=1)
    for r in sb:
        print(r.get("label"), r.get("err"), r.get("cu"), flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
