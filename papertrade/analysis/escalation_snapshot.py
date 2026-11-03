#!/usr/bin/env python3
"""2026-11 escalation: atomic live snapshot of Papertrade (HyperEVM 999) at one block.
Read-only. Writes escalation_snapshot.json. No secrets, public keyless RPC.
Everything is pinned to a single eth_blockNumber result; the public RPC's
historical-state reads are load-balancer-inconsistent, so only latest-block
reads are treated as decisive (documented in the report)."""
import json, os, urllib.request, time

# ---- pure-python keccak256 (stdlib only; CI has no pycryptodome) ----
_KECCAK_RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
_KECCAK_R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
_MASK64 = (1 << 64) - 1
def _rotl(x, n): return ((x << n) | (x >> (64 - n))) & _MASK64
def _keccak_f(a):
    for rnd in range(24):
        c = [a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4] for x in range(5)]
        d = [c[(x - 1) % 5] ^ _rotl(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(5): a[x][y] ^= d[x]
        b = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5): b[y][(2 * x + 3 * y) % 5] = _rotl(a[x][y], _KECCAK_R[x][y])
        for x in range(5):
            for y in range(5):
                a[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y])
        a[0][0] ^= _KECCAK_RC[rnd]
    return a
def keccak256(data: bytes) -> bytes:
    rate = 136; p = bytearray(data); p.append(0x01)
    while len(p) % rate != 0: p.append(0)
    p[-1] ^= 0x80
    a = [[0] * 5 for _ in range(5)]
    for off in range(0, len(p), rate):
        blk = p[off:off + rate]
        for i in range(rate // 8):
            a[i % 5][i // 5] ^= int.from_bytes(blk[i * 8:(i + 1) * 8], 'little')
        _keccak_f(a)
    out = b''
    for i in range(4): out += a[i % 5][i // 5].to_bytes(8, 'little')
    return out

U = "https://rpc.hyperliquid.xyz/evm"
EX = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
BATCH = "0x233Ff29b239abc1D7748605dA9b205C3e008626E"
SKM = "0x8326Eb8896e358717f10502Ec73CE8D28E37B108"
EIP1967 = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
M96 = 2**96 - 1
M128 = 2**128 - 1

URL = U


def rpc(m, p, retries=4):
    import time
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    for i in range(retries):
        try:
            r = urllib.request.Request(U, data=b, headers={"Content-Type": "application/json",
                                                           "User-Agent": "Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(r, timeout=30).read())
        except Exception:
            if i == retries - 1:
                raise
            time.sleep(1.5)


def call(to, data, block):
    j = rpc("eth_call", [{"to": to, "data": data}, block])
    return j.get("result")


def slot_hash(mid, base):
    return "0x" + keccak256(bytes.fromhex(format(mid, '064x') + format(base, '064x'))).hex()


def main():
    bn = int(rpc("eth_blockNumber", [])["result"], 16)
    blk = hex(bn)
    out = {"block": bn, "rpc": "public https://rpc.hyperliquid.xyz/evm"}
    out["impls"] = {}
    for name, addr in (("exchange", EX), ("oracle", ORACLE), ("batchExecutor", BATCH),
                       ("sessionKeyManager", SKM)):
        s = rpc("eth_getStorageAt", [addr, EIP1967, blk])["result"]
        out["impls"][name] = "0x" + s[-40:]

    views = {"tradingPaused": "0x53e23e2e", "lpBankrollAvailable": "0x0cdd5fc4",
             "totalLockedMargin": "0x01ad056f", "totalQueued": "0x53ac4b66",
             "totalBalances": "0xa69a2ad1", "treasury": "0x61d027b3",
             "winFeeRate": "0x48ee5e08", "lossFeeRate": "0xf1a8786c",
             "liquidationFeeRate": "0x5fb3b1b5", "nextPositionId": "0x899346c7",
             "queueHead": "0x96523644", "collateralScale": "0xec0bdcfc",
             "oracle": "0x7dc0d1d0", "authorizedExecutor": "0x13dd495b",
             "owner": "0x8da5cb5b", "pauseGuardian": "0x24a3d622",
             "marketKeeper": "0x21f55a6c", "authorizedKeeper": "0x9d47d4d3",
             "instrumentCount": "0xf28bbdb2"}
    raw, val = {}, {}
    for k, sel in views.items():
        raw[k] = call(EX, sel, blk)
    def u(k):
        return int(raw[k], 16) if raw.get(k) and raw[k] != "0x" else None
    val["tradingPaused"] = bool(u("tradingPaused"))
    for k in ("lpBankrollAvailable", "totalLockedMargin", "totalQueued", "totalBalances"):
        val[k + "_usd"] = (u(k) or 0) / 1e18
    val["winFeeRate"] = (u("winFeeRate") or 0) / 1e18
    val["lossFeeRate"] = (u("lossFeeRate") or 0) / 1e18
    val["liquidationFeeRate"] = (u("liquidationFeeRate") or 0) / 1e18
    val["nextPositionId"] = u("nextPositionId")
    val["queueHead"] = u("queueHead")
    val["collateralScale"] = u("collateralScale")
    val["instrumentCount"] = u("instrumentCount")
    for k in ("treasury", "oracle", "authorizedExecutor", "owner", "pauseGuardian",
              "marketKeeper", "authorizedKeeper"):
        val[k] = ("0x" + raw[k][-40:]) if raw.get(k) and len(raw[k]) >= 42 else raw.get(k)
    out["views"] = val

    out["bbo"] = {}
    for asset in (0, 1):
        b = call(ORACLE, "0xfb466481" + format(asset, '064x'), blk)
        m = call(ORACLE, "0xc0182669" + format(asset, '064x'), blk)
        bid = int(b[2:66], 16) if b and len(b) >= 130 else None
        ask = int(b[66:130], 16) if b and len(b) >= 130 else None
        out["bbo"][str(asset)] = {"bid_raw": bid, "ask_raw": ask,
                                  "mid_raw": int(m, 16) if m else None,
                                  "mid_equals_floor_half_sum": (int(m, 16) == (bid + ask) // 2)
                                  if (m and bid is not None) else None,
                                  "no_deviation_delta_bp": 0.0 if (m and bid is not None) else None}
        if bid:
            out["bbo"][str(asset)]["mid_calc"] = (bid + ask) / 2

    out["markets"] = {}
    for mid, name in ((0, "BTC"), (1, "ETH")):
        h = slot_hash(mid, 0x24)
        s0 = int(rpc("eth_getStorageAt", [EX, h, blk])["result"], 16)
        s1 = int(rpc("eth_getStorageAt", [EX, hex(int(h, 16) + 1), blk])["result"], 16)
        scale = s0 >> 192
        rec = {"priceScale": scale,
               "longOI": (s0 & M96) / 1e18, "shortOI": ((s0 >> 96) & M96) / 1e18,
               "longCap": (s1 & M128) / 1e18, "shortCap": ((s1 >> 128) & M128) / 1e18,
               "mid": out["bbo"][str(mid)]["mid_calc"] / scale}
        rec["longHeadroom"] = rec["longCap"] - rec["longOI"]
        rec["shortHeadroom"] = rec["shortCap"] - rec["shortOI"]
        rec["longHeadroom_usd"] = rec["longHeadroom"] * rec["mid"]
        rec["shortHeadroom_usd"] = rec["shortHeadroom"] * rec["mid"]
        out["markets"][name] = rec

    out["instruments"] = {}
    for mid, name in ((0, "BTC"), (1, "ETH")):
        r = call(EX, "0xdc8a47ef" + format(mid, '064x'), blk)
        if r and len(r) >= 2 + 8 * 64:
            w = [int(r[2 + i * 64:2 + (i + 1) * 64], 16) for i in range(8)]
            out["instruments"][name] = {
                "rateMultiplier": w[0] / 1e18, "positionMultiplier": w[1] / 1e18,
                "assetIndex": w[2], "maxLeverage": w[3],
                "maxPositionNotional_usd": w[4] / 1e18, "bustBuffer": w[5] / 1e18,
                "baseRate": w[6] / 1e18, "referenceNotional_usd": w[7] / 1e18,
            }
    out["instruments_note"] = ("instruments(uint32) has no OI-cap field (8 words: rateMultiplier, "
                               "positionMultiplier, assetIndex, maxLeverage, maxPositionNotional, "
                               "bustBuffer, baseRate, referenceNotional). Caps live in packed storage "
                               "mapping base 0x24 (slot+1) and are set by keeper setOiCaps(0x628a9fd6); "
                               "the relayer's public GET /state/trading mirrors them.")

    impl = out["impls"]["exchange"]
    code = rpc("eth_getCode", [impl, blk])["result"]
    out["exchange_code"] = {"bytes": (len(code) - 2) // 2,
                            "keccak256": "0x" + keccak256(bytes.fromhex(code[2:])).hex()}
    scan = {}
    for s in ("c0182669", "a066fae9", "2af78bd1", "610806", "610807", "61080e",
              "fb466481", "ec6783f0", "2792e706"):
        scan[s] = code.lower().count(s)
    out["selector_scan"] = scan
    out["selector_scan_note"] = ("610806/610807/61080e are PUSH2 operands for the mark/oracle/BBO "
                                 "precompile addresses; absent means the Exchange never calls them directly")
    OUTDIR = os.environ.get("ESCALATION_OUT", "/home/heisenberg/CA/papertrade/analysis")
    json.dump(out, open(os.path.join(OUTDIR, "escalation_snapshot.json"), "w"), indent=1)
    print(json.dumps({k: out[k] for k in ("block", "impls", "views", "markets")}, indent=1))


if __name__ == "__main__":
    main()
