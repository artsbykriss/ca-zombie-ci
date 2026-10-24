#!/usr/bin/env python3
"""
Exhaustive read-only live-state probe of the Kolan launchpad + all LaunchHooks + the
main KolanHook (Ethereum mainnet).  Public keyless RPC only.

Reads at ONE pinned block:
  launchpad.launchCount(), launchpad.hooksBetween(0, n)
  per hook: windowCount(), held(), launched(), TOKEN(), DEV(), TREASURY(), KLN(),
            eth_getBalance, eth_getCode size
  per hook window id in 1..windowCount: windows(id) + cutsOf(id)
  main KolanHook: same core reads.

Writes analysis/live_state.json
"""
import json, urllib.request, urllib.error, time, sys

RPC = "https://ethereum-rpc.publicnode.com"
LAUNCHPAD = "0x8F89905624E3613b3A578Ff1EC690463A33e940e"
MAIN = "0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC"

SEL = {
    "launchCount": "0x27cca59f",
    "hooksBetween": "0x4bdaf8b2",
    "windowCount": "0x2d07ae11",
    "held": "0xa285aed7",
    "launched": "0x8091f3bf",
    "TOKEN": "0x82bfefc8",
    "DEV": "0xc1eb5ddd",
    "TREASURY": "0x2d2c5565",
    "KLN": "0x437c923e",
    "windows": "0x637e7006",
    "cutsOf": "0xbd23e627",
    "accept": "0x19b05f49",
}

def rpc(method, params, url=RPC):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body,
                                 headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
    last = None
    for a in range(6):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                d = json.load(r)
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = repr(e)
        time.sleep(0.8 + a)
    raise RuntimeError(f"{method} {params[:1]} failed: {last}")

def call(to, data, block):
    return rpc("eth_call", [{"to": to, "data": data}, hex(block)])

def word(hexstr, i):
    return hexstr[2 + i * 64: 2 + (i + 1) * 64]

def as_uint(hexstr, i):
    w = word(hexstr, i)
    return int(w, 16) if w else None

def as_addr(hexstr, i):
    w = word(hexstr, i)
    return "0x" + w[-40:] if w else None

def as_int24(hexstr, i):
    v = as_uint(hexstr, i)
    if v is None:
        return None
    return v - 2**24 if v >= 2**23 else v

def decode_dynamic_addr_array(res):
    words = res[2:]
    off = int(words[0:64], 16) // 32
    ln = int(words[off * 64: (off + 1) * 64], 16)
    out = []
    for i in range(ln):
        w = words[(off + 1 + i) * 64: (off + 2 + i) * 64]
        out.append("0x" + w[-40:])
    return out

def decode_cuts(res):
    """Cut[]: (int24 lower, int24 upper, uint104 liquidity, uint104 partialTaken)"""
    if not res or len(res) < 130:
        return []
    words = res[2:]
    off = int(words[0:64], 16) // 32
    ln = int(words[off * 64: (off + 1) * 64], 16)
    cuts = []
    base = (off + 1) * 64
    for i in range(ln):
        seg = words[base + i * 256: base + (i + 1) * 256]
        lo = int(seg[0:64], 16); lo = lo - 2**24 if lo >= 2**23 else lo
        hi = int(seg[64:128], 16); hi = hi - 2**24 if hi >= 2**23 else hi
        cuts.append({"lower": lo, "upper": hi,
                     "liquidity": int(seg[128:192], 16),
                     "partialTaken": int(seg[192:256], 16)})
    return cuts

def read_window(hook, wid, block):
    w = call(hook, SEL["windows"] + hex(wid)[2:].rjust(64, "0"), block)
    if not isinstance(w, str) or len(w) < 2 + 64 * 6:
        return {"id": wid, "raw": w}
    rec = {
        "id": wid,
        "owner": as_addr(w, 0),
        "expiry": as_uint(w, 1),
        "cuts": as_uint(w, 2),
        "eth": as_uint(w, 3),
        "tokens": as_uint(w, 4),
        "premium": as_uint(w, 5),
    }
    try:
        rec["cutsOf"] = decode_cuts(call(hook, SEL["cutsOf"] + hex(wid)[2:].rjust(64, "0"), block))
    except Exception as e:
        rec["cutsOf_err"] = repr(e)
    return rec

def probe_hook(h, block, has_treasury_kln=True):
    rec = {"hook": h}
    rec["windowCount"] = as_uint(call(h, SEL["windowCount"], block), 0)
    held = call(h, SEL["held"], block)
    if isinstance(held, str) and len(held) >= 2 + 128:
        rec["held_eth"] = as_uint(held, 0)
        rec["held_tokens"] = as_uint(held, 1)
    rec["launched"] = as_uint(call(h, SEL["launched"], block), 0)
    rec["TOKEN"] = as_addr(call(h, SEL["TOKEN"], block), 0)
    rec["DEV"] = as_addr(call(h, SEL["DEV"], block), 0)
    if has_treasury_kln:
        rec["TREASURY"] = as_addr(call(h, SEL["TREASURY"], block), 0)
        rec["KLN"] = as_addr(call(h, SEL["KLN"], block), 0)
    rec["balance_wei"] = int(rpc("eth_getBalance", [h, hex(block)]), 16)
    code = rpc("eth_getCode", [h, hex(block)])
    rec["code_size"] = (len(code) - 2) // 2
    rec["accept_selector_present"] = SEL["accept"][2:] in code[2:]
    # enumerate windows
    wins = []
    wc = rec["windowCount"] or 0
    for wid in range(1, wc + 1):
        wins.append(read_window(h, wid, block))
    rec["windows"] = wins
    rec["open_or_funded_windows"] = [
        x for x in wins if x.get("owner") not in (None, "0x" + "0" * 40) and (x.get("eth") or 0) > 0
    ]
    rec["any_window_open"] = len(rec["open_or_funded_windows"]) > 0
    return rec

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    out = {"rpc": RPC, "block": block, "launchpad": LAUNCHPAD, "main_KolanHook": MAIN}
    lc = as_uint(call(LAUNCHPAD, SEL["launchCount"], block), 0)
    out["launchCount"] = lc
    arg = hex(0)[2:].rjust(64, "0") + hex(lc)[2:].rjust(64, "0")
    hooks = decode_dynamic_addr_array(call(LAUNCHPAD, SEL["hooksBetween"] + arg, block))
    out["hooks_count"] = len(hooks)
    out["hooks"] = [probe_hook(h, block, True) for h in hooks]
    out["main"] = probe_hook(MAIN, block, False)
    # totals
    tot = 0
    for h in out["hooks"]:
        tot += h.get("held_eth") or 0
    out["total_held_eth_launchhooks_wei"] = tot
    out["total_held_eth_main_wei"] = out["main"].get("held_eth") or 0
    openpath = "/home/heisenberg/CA/kolan-hooks/analysis/live_state.json"
    with open(openpath, "w") as f:
        json.dump(out, f, indent=1)
    # compact summary
    print(f"block={block} launchCount={lc} hooks={len(hooks)}")
    for h in out["hooks"]:
        print(f"  {h['hook']} wc={h['windowCount']} held.eth={h['held_eth']} bal={h['balance_wei']} "
              f"code={h['code_size']} open={h['any_window_open']}")
    m = out["main"]
    print(f"  MAIN {m['hook']} wc={m['windowCount']} held.eth={m['held_eth']} bal={m['balance_wei']} "
          f"code={m['code_size']} open={m['any_window_open']}")
    print("wrote", openpath)

if __name__ == "__main__":
    main()
