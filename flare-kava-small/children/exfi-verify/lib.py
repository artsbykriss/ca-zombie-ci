"""Verification helpers for the Enosys EXFI/SFIN stake-manager audit (independent re-verification).

Read-only. Keyless public RPC only. No secrets, no transactions.
"""
import json, urllib.request, time
from Crypto.Hash import keccak

RPC = "https://songbird-api.flare.network/ext/C/rpc"

def sel(sig: str) -> str:
    h = keccak.new(digest_bits=256); h.update(sig.encode()); return "0x" + h.hexdigest()[:8]

def topic(sig: str) -> str:
    h = keccak.new(digest_bits=256); h.update(sig.encode()); return "0x" + h.hexdigest()

def w(x: int) -> str:
    return format(x % (1 << 256), "064x")

def waddr(a: str) -> str:
    return a.lower().replace("0x", "").rjust(64, "0")

def uint(v: int) -> str:
    return w(v)

def addr(a: str) -> str:
    return waddr(a)

def rpc(method, params, retries=4, timeout=45):
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"content-type": "application/json"},
            )
            r = json.loads(urllib.request.urlopen(req, timeout=timeout).read())
            if isinstance(r, dict) and "error" in r:
                err = r["error"]
                msg = err.get("message", str(err)) if isinstance(err, dict) else str(err)
                if "revert" in msg.lower():
                    if ":" in msg:
                        raise RuntimeError("execution reverted: " + msg.split(":", 1)[-1].strip())
                    raise RuntimeError(msg)
                raise RuntimeError(msg)
            return r.get("result")
        except RuntimeError:
            raise
        except Exception as e:  # noqa
            last = e
            time.sleep(0.5 * (i + 1))
    raise RuntimeError(f"rpc failed {method}: {last}")

def batch_eth_call(calls, chunk=25):
    """calls: list of dicts {to, data, from(optional), block='latest'} -> list of results or {'error':...}."""
    out = {}
    for i in range(0, len(calls), chunk):
        sub = calls[i:i + chunk]
        req = []
        for j, c in enumerate(sub):
            tx = {"to": c["to"], "data": c["data"]}
            if c.get("from"):
                tx["from"] = c["from"]
            req.append({"jsonrpc": "2.0", "id": i + j, "method": "eth_call", "params": [tx, c.get("block", "latest")]})
        for attempt in range(4):
            try:
                r = urllib.request.Request(RPC, data=json.dumps(req).encode(), headers={"content-type": "application/json"})
                resp = json.loads(urllib.request.urlopen(r, timeout=90).read())
                if isinstance(resp, dict):
                    resp = [resp]
                for x in resp:
                    if "id" in x:
                        out[x["id"]] = {"error": x["error"]} if "error" in x else x.get("result")
            except Exception as e:  # noqa
                print("warn batch retry:", e)
                time.sleep(0.8 * (attempt + 1))
            if all((i + j) in out for j in range(len(sub))):
                break
    return [out.get(k) for k in range(len(calls))]

def one_call(to, data, frm=None, block="latest"):
    r = batch_eth_call([{"to": to, "data": data, "from": frm, "block": block}])[0]
    if isinstance(r, dict):
        raise RuntimeError(f"revert/err: {r}")
    return r

def dec_uint(res: str) -> int:
    return int(res, 16)

def dec_int(res: str) -> int:
    v = int(res, 16)
    return v - (1 << 256) if v >= (1 << 255) else v

def dec_addr(res: str) -> str:
    return "0x" + res[-40:]

def dec_uarr(res: str):
    b = res[2:]; off = int(b[:64], 16) * 2
    ln = int(b[off:off + 64], 16); off += 64
    return [int(b[off + 64 * i:off + 64 * (i + 1)], 16) for i in range(ln)]

def dec_aarr(res: str):
    b = res[2:]; off = int(b[:64], 16) * 2
    ln = int(b[off:off + 64], 16); off += 64
    return ["0x" + b[off + 64 * i + 24:off + 64 * (i + 1)] for i in range(ln)]

def revert_str(err):
    if not isinstance(err, dict):
        return str(err)
    e = err.get("error")
    if isinstance(e, dict):
        return e.get("message", str(e))
    return str(err)

def reason(ret_hex):
    """decode standard revert data: Error(string) or Panic(uint)."""
    if not ret_hex or ret_hex == "0x":
        return "(empty)"
    b = ret_hex[2:]
    try:
        if b.startswith("08c379a0"):
            ln = int(b[8 + 64:8 + 128], 16)
            return "Error: " + bytes.fromhex(b[8 + 128:8 + 128 + 2 * ln]).decode("utf8", "replace")
        if b.startswith("4e487b71"):
            return "Panic(0x%x)" % int(b[8:8 + 64], 16)
    except Exception:
        pass
    return "raw:" + ret_hex[:80]

# ---- Multicall3 helpers (state-override technique) ----
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
AGG3 = sel("aggregate3((address,bool,bytes)[])")

def _enc_bytes(b) -> str:
    if isinstance(b, str):
        b = bytes.fromhex(b.replace("0x", ""))
    ln = len(b)
    padded = b.hex() + "00" * ((32 - ln % 32) % 32)
    return w(ln) + padded

def enc_aggregate3(calls):
    n = len(calls)
    elems = ""
    offsets = []
    acc = 32 * n
    for (t, af, cd) in calls:
        body = waddr(t) + w(1 if af else 0) + w(0x60) + _enc_bytes(cd)
        offsets.append(acc)
        elems += body
        acc += len(body) // 2
    out = AGG3[2:] + w(0x20) + w(n)
    out += "".join(w(o) for o in offsets)
    out += elems
    return "0x" + out

def dec_agg3_results(res_hex):
    b = res_hex[2:]
    off = int(b[:64], 16) * 2
    n = int(b[off:off + 64], 16)
    off += 64
    base = off
    out = []
    for i in range(n):
        eoff = int(b[base + 64 * i:base + 64 * (i + 1)], 16) * 2
        e = base + eoff
        succ = int(b[e:e + 64], 16) == 1
        boff = int(b[e + 64:e + 128], 16) * 2
        p = e + boff
        ln = int(b[p:p + 64], 16)
        out.append((succ, "0x" + b[p + 64:p + 64 + 2 * ln]))
    return out

def mc3_override_call(target_staker, calls, extra=None, block="latest"):
    """Run Multicall3.aggregate3 *as* target_staker (its code is overridden with MC3 runtime in eth_call),
    so inner calls have msg.sender = target_staker and state writes persist within the call."""
    code = rpc("eth_getCode", [MC3, block])
    ov = {target_staker: {"code": code}}
    if extra:
        ov.update(extra)
    tx = {"from": target_staker, "to": target_staker, "data": enc_aggregate3(calls)}
    res = rpc("eth_call", [tx, block, ov])
    return dec_agg3_results(res)
