#!/usr/bin/env python3
"""Batched eth_call state reader for Segment opBNB (keyless public RPC).
Selectors computed with `cast sig` at first use and cached in selectors.json.
Decodes: uint*|int*, address, bool, string, bytes, and arrays of those.
Usage: python3 reader.py <calls.json> > out.json
calls.json: [{"label": "...", "to": "0x..", "sig": "markets(address)", "args": ["0x.."]}]
"""
import json, os, sys, subprocess, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number

HERE = os.path.dirname(os.path.abspath(__file__))
SELFILE = os.path.join(HERE, "selectors.json")
_sels = json.load(open(SELFILE)) if os.path.exists(SELFILE) else {}

def sig_selector(sig):
    if sig in _sels:
        return _sels[sig]
    # strip return part for selector: cut at the last ")("
    idx = sig.rfind(")(")
    inp = sig[:idx + 1] if idx != -1 else sig
    out = subprocess.run(["cast", "sig", inp], capture_output=True, text=True, check=True).stdout.strip()
    _sels[sig] = out
    json.dump(_sels, open(SELFILE, "w"), indent=1)
    return out

def enc_arg(t, v):
    if t.startswith("uint") or t.startswith("int"):
        return f"{int(v):064x}"
    if t == "address":
        return v.lower().replace("0x", "").rjust(64, "0")
    if t == "bool":
        return "1" * 64 if v else "0" * 64
    if t == "bytes32":
        return v.replace("0x", "").rjust(64, "0")
    if t == "bytes":
        hexs = v[2:] if v.startswith("0x") else v
        bs = bytes.fromhex(hexs) if hexs else b""
        return f"{len(bs):064x}" + bs.hex().ljust(64, "0")
    raise ValueError("unsupported arg " + t)

def enc_string(v):
    bs = v.encode()
    return f"{32:064x}{len(bs):064x}" + bs.hex().ljust(64, "0")

def enc_dynamic_array(t, vals):
    base = t[:-2]  # strip []
    body = f"{len(vals):064x}" + "".join(enc_arg(base, v) for v in vals)
    return body

def build_data(sig, sel, types, args):
    """Head/tail encoding supporting string and array args."""
    needs_tail = any(t in ("string", "bytes") or t.endswith("[]") for t in types)
    if not needs_tail:
        return sel + "".join(enc_arg(t, v) for t, v in zip(types, args))
    head, tail, off = "", "", 32 * len(types)
    for t, v in zip(types, args):
        if t == "string":
            enc = enc_string(v)
            head += f"{off:064x}"
            tail += enc
            off += len(enc) // 2
        elif t == "bytes":
            enc = enc_arg(t, v)
            head += f"{off:064x}"
            tail += enc
            off += len(enc) // 2
        elif t.endswith("[]"):
            enc = enc_dynamic_array(t, v)
            head += f"{off:064x}"
            tail += enc
            off += len(enc) // 2
        else:
            head += enc_arg(t, v)
    return sel + head + tail

def parse_types(typestr):
    # typestr like "bool,uint256" or ""
    if not typestr.strip():
        return []
    return [t.strip() for t in typestr.split(",")]

def decode_word(w):
    return int(w, 16)

def decode(typestr, data):
    types = parse_types(typestr)
    if not types:
        return []
    raw = data[2:] if data.startswith("0x") else data
    words = [raw[i:i+64] for i in range(0, len(raw), 64)]
    out = []
    idx = 0
    for t in types:
        w = words[idx]
        base = t.replace("[]", "")
        if t.endswith("[]"):
            off = int(w, 16) // 32
            n = int(words[off], 16)
            items = []
            for j in range(n):
                items.append(dec_single(base, words[off + 1 + j]))
            out.append(items)
            idx += 1
        elif t == "string":
            off = int(w, 16) // 32
            ln = int(words[off], 16)
            bs = bytes.fromhex("".join(words[off + 1:]))
            out.append(bs[:ln].decode("utf-8", "replace"))
            idx += 1
        else:
            out.append(dec_single(base, w))
            idx += 1
    return out

def dec_single(base, word):
    if base.startswith("uint") or base.startswith("int"):
        v = int(word, 16)
        return v
    if base == "address":
        return "0x" + word[24:]
    if base in ("bool",):
        return int(word, 16) != 0
    if base == "bytes32":
        return "0x" + word
    if base == "bytes":
        return "0x" + word
    return int(word, 16)

def run_calls(calls, block="latest"):
    batch = []
    for c in calls:
        sig = c["sig"]
        sel = sig_selector(sig)
        types = parse_types(sig.split("(")[1].split(")")[0]) if "(" in sig else []
        data = build_data(sig, sel, types, c.get("args", []))
        call = {"to": c["to"], "data": data}
        if c.get("from"):
            call["from"] = c["from"]
        if c.get("value") is not None:
            call["value"] = c["value"]
        batch.append(("eth_call", [call, block]))
    res = rpc_batch(batch)
    out = []
    for c, r in zip(calls, res):
        typestr = c["sig"].split(")(")[-1].rstrip(")") if ")(" in c["sig"] else ""
        if isinstance(r, dict) and "__error__" in r:
            out.append({"label": c.get("label", c["sig"]), "error": r["__error__"]})
        else:
            try:
                dec = decode(typestr, r)
            except Exception as e:
                dec = ["decode_error: " + str(e) + " raw=" + str(r)[:80]]
            out.append({"label": c.get("label", c["sig"]), "result": dec, "raw": r})
    return out

if __name__ == "__main__":
    calls = json.load(open(sys.argv[1]))
    block = sys.argv[2] if len(sys.argv) > 2 else "latest"
    print(json.dumps(run_calls(calls, block), indent=1))
