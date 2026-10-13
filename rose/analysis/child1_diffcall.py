#!/usr/bin/env python3
"""Child1: behavioral differential test of live VASE vs canonical BentoBox (Ethereum).

Both contracts are eth_called with identical crafted calldata; outputs are compared
(normalizing the Vase:/BentoBox: revert-string rename). Read-only.
"""
import json, urllib.request, time
from Crypto.Hash import keccak

AURORA = "https://mainnet.aurora.dev"
ETH = "https://ethereum-rpc.publicnode.com"
VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"
BENTO = "0xF5BCE5077908a1b7370B9ae04AdC565EBd643966"
ATTACKER = "0x5eed000000000000000000000000000000005eed"
DEAD = "0x000000000000000000000000000000000000dEaD"

SEL = {"batch": "0xd2423b51", "deploy": "0x1f54245b", "nonces": "0x7ecebe00",
       "owner": "0x8da5cb5b", "transferOwnership": "0x078dfbe7"}

def w(x):
    if isinstance(x, int):
        return format(x, "064x")
    return x.lower()[2:].rjust(64, "0")

def rpc(url, method, params, retries=4):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for _ in range(retries):
        try:
            req = urllib.request.Request(url, data=payload,
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=60))
            if "error" in r:
                return {"error": r["error"]}
            return {"result": r["result"]}
        except Exception as e:
            last = str(e)
            time.sleep(1.5)
    return {"error": {"message": f"unreachable: {last}"}}

def eth_call(url, to, data, frm=ATTACKER):
    return rpc(url, "eth_call", [{"to": to, "data": data, "from": frm}, "latest"])

def batch_calldata(calls_elems, revert_on_fail):
    """calls_elems: list of bytes; encode batch(bytes[] calldata, bool) canonically."""
    # build bytes-array encoding
    n = len(calls_elems)
    offs = []
    payload = b""
    base = 32 * n
    for c in calls_elems:
        offs.append(base + len(payload))
        payload += len(c).to_bytes(32, "big") + c
    enc = len(calls_elems).to_bytes(32, "big")
    for o in offs:
        enc += o.to_bytes(32, "big")
    enc += payload
    # args: offset to array, bool
    return bytes.fromhex(SEL["batch"][2:]) + (0x40).to_bytes(32, "big") + int(revert_on_fail).to_bytes(32, "big") + enc

def raw_batch(offset_word, bool_word, tail_hex=""):
    return SEL["batch"] + w(offset_word) + w(bool_word) + tail_hex

def raw_deploy(master, use_create2, data_hex):
    # deploy(address,bytes,bool): head = [master, offset=0x60, useCreate2], then bytes {len,data padded}
    d = bytes.fromhex(data_hex[2:]) if data_hex.startswith("0x") else b""
    enc = w(master) + w(0x60) + w(1 if use_create2 else 0) + w(len(d)) + d.hex().ljust(((len(d) + 31) // 32) * 64, "0")
    return SEL["deploy"] + enc

def norm(x):
    s = json.dumps(x)
    s = s.replace("Vase: ", "BentoBox: ").replace("Vase:", "BentoBox:")
    # node-specific empty revert data field
    s = s.replace(', "data": "0x"', "")
    # mask owner addresses in results (state difference, not code)
    for a in ("0x0e2a05ca5d1e218034f2b7deb6e9419159839f8b", "0x6b0e07d19daf0e6e6b06c3d7dd39d1e1fd1d0f6f"):
        s = s.replace(a.lower(), "0xOWNER")
        s = s.replace(a, "0xOWNER")
    return s

def is_revert(x):
    return "error" in x

def main():
    cases = []
    # case name -> calldata
    cases.append(("batch_empty_false", batch_calldata([], False)))
    cases.append(("batch_empty_true", batch_calldata([], True)))
    cases.append(("batch_one_empty_bytes", batch_calldata([b""], False)))
    # one element = call to nonces(0xdead)
    cases.append(("batch_call_nonces_dead", batch_calldata([bytes.fromhex(SEL["nonces"][2:]) + bytes.fromhex(w(DEAD))], False)))
    # one element = call to owner()
    cases.append(("batch_call_owner", batch_calldata([bytes.fromhex(SEL["owner"][2:])], False)))
    # one element = nested batch([])
    cases.append(("batch_call_nested", batch_calldata([batch_calldata([], False)], False)))
    # 4-byte non-multiple payload with proper padding present
    cases.append(("batch_call_bytes4_padded", batch_calldata([b"\xde\xad\xbe\xef"], False)))
    # malformed: declared len=1 but no element data
    cases.append(("batch_malformed_len1_nodata", raw_batch(0x40, 0, w(1))))
    # malformed: element offset out of range
    cases.append(("batch_malformed_offset_oob", raw_batch(0x40, 0, w(1) + w(0xffff))))
    # malformed: bytes length huge
    tail = w(1) + w(0x20) + w(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) + "00" * 16
    cases.append(("batch_malformed_len_huge", raw_batch(0x40, 0, tail)))
    # call to unknown selector inside batch (dispatcher revert)
    cases.append(("batch_call_unknown_selector", batch_calldata([b"\x11\x22\x33\x44"], False)))
    # deploy: master 0 -> revert with reason
    cases.append(("deploy_master_zero", raw_deploy("0x" + "0" * 40, False, "0x")))
    # deploy: codeless master dead -> init call succeeds empty
    cases.append(("deploy_master_dead_noinit", raw_deploy(DEAD, False, "0x")))
    # transferMultiple with empty tos (canonical tos[0] revert): head=[tok, from, off_tos=0x80, off_shares=0xa0]
    cases.append(("transferMultiple_emptytos", "0x0fca8843" + w(VASE) + w(VASE) + w(0x80) + w(0xA0) + w(0) + w(0)))

    out = {"attacker": ATTACKER, "cases": {}}
    for name, data in cases:
        if isinstance(data, (bytes, bytearray)):
            data = "0x" + bytes(data).hex()
        a = eth_call(AURORA, VASE, data)
        b = eth_call(ETH, BENTO, data)
        same = norm(a) == norm(b)
        both_revert = is_revert(a) and is_revert(b)
        out["cases"][name] = {
            "calldata_len": (len(data) - 2) // 2,
            "aurora_vase": a, "eth_bentobox": b,
            "both_revert": both_revert,
            "equal_after_rename_norm": same,
        }
        print(f"--- {name} (calldata {len(data)//2 - 1}B) equal={same} both_revert={both_revert}")
        print(f"    VASE : {json.dumps(a)[:200]}")
        print(f"    BENTO: {json.dumps(b)[:200]}")
    json.dump(out, open("child1_diffcall.json", "w"), indent=1)
    neq = [k for k, v in out["cases"].items() if not v["equal_after_rename_norm"]]
    print("\nunequal cases:", neq)

if __name__ == "__main__":
    main()
