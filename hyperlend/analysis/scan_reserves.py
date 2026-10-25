#!/usr/bin/env python3
"""Read-only HyperLend core-pool reserve scan (HyperEVM 999).
Decodes Aave-v3 reserve config, reads AaveOracle price + source, and checks
Chainlink-style feed staleness (latestRoundData.updatedAt / latestTimestamp).
NO secrets. Uses public RPC by default."""
import json, sys, urllib.request, time

RPC = sys.argv[1] if len(sys.argv) > 1 else "https://rpc.hyperliquid.xyz/evm"
POOL = "0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b"
ORACLE = "0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e"

_id = 0
def rpc(method, params):
    global _id
    _id += 1
    body = json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.loads(r.read())
            if "result" in d: return d["result"]
            raise RuntimeError(d)
        except Exception as e:
            if attempt == 3: raise
            time.sleep(1.5*(attempt+1))

def call(to, sig):
    sel = __import__("hashlib").sha3_256  # placeholder
    return rpc("eth_call", [{"to":to,"data":sig}, "latest"])

# minimal keccak for selectors
def keccak256(b):
    import binascii
    # use sha3 via eth? implement keccak-f. Too long. Use cast instead for selectors.
    raise NotImplementedError

# Instead: hardcode selectors (computed once)
SEL = {
  "getReservesList()": "0xd1946dbc",
  "getReserveData(address)": "0x35ea6a75",
  "getConfiguration(address)": "0xc44b11f7",
  "getAssetPrice(address)": "0xb3596f07",
  "getSourceOfAsset(address)": "0x92bf2be0",
  "decimals()": "0x313ce567",
  "symbol()": "0x95d89b41",
  "name()": "0x06fdde03",
  "latestAnswer()": "0x50d25bcd",
  "latestTimestamp()": "0x8205bf6a",
  "latestRoundData()": "0xfeaf968c",
  "getReserveNormalizedVariableDebt(address)":"0x386497fd",
}
def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def enc_sig(sig): return SEL[sig]

def call_addr(to, sig, arg=None):
    data = SEL[sig] + (enc_addr(arg) if arg else "")
    return rpc("eth_call", [{"to":to,"data":data}, "latest"])

def as_int(h): return int(h,16) if h and h!="0x" else 0

def dec_str(h):
    if not h or h=="0x": return ""
    b = bytes.fromhex(h[2:])
    if len(b) < 64: return ""
    try:
        off = int.from_bytes(b[:32],"big")
        ln = int.from_bytes(b[off:off+32],"big")
        return b[off+32:off+32+ln].decode("utf-8","replace")
    except Exception:
        return ""

# --- get reserves list ---
raw = call_addr(POOL, "getReservesList()")
b = bytes.fromhex(raw[2:])
off = int.from_bytes(b[:32],"big")
n = int.from_bytes(b[off:off+32],"big")
reserves = []
for i in range(n):
    a = b[off+32+i*32:off+64+i*32]
    reserves.append("0x"+a[12:].hex())

now = as_int(rpc("eth_blockNumber",[]))
blk = rpc("eth_getBlockByNumber", ["latest", False])
ts_now = int(blk["timestamp"],16)
print(f"# HyperEVM block {now}  ts={ts_now}  ({time.strftime('%Y-%m-%d %H:%M UTC', time.gmtime(ts_now))})")
print(f"# reserves: {len(reserves)}")

# reserve config bit layout (Aave v3)
M = {
 "LTV": (0xFFFF, 0),
 "liqThresh": (0xFFFF,16),
 "liqBonus": (0xFFFF,32),
 "decimals": (0xFF,48),
 "active": (1,56),
 "frozen": (1,57),
 "borrowingEnabled": (1,58),
 "stableBorrowing": (1,59),
 "paused": (1,60),
 "borrowableInIsolation": (1,61),
 "siloedBorrowing": (1,62),
 "flashloanEnabled": (1,63),
 "borrowCap": (0xFFFFFFFF,64),
 "supplyCap": (0xFFFFFFFF,80),
}
rows = []
for a in reserves:
    cfg = as_int(call_addr(POOL, "getConfiguration(address)", a))
    d = {}
    for k,(mask,sh) in M.items():
        d[k] = (cfg >> sh) & mask
    # reserve data (liquidityIndex etc) - tuple; pull selected fields by offset is messy; use getReserveData raw
    price = as_int(call_addr(ORACLE, "getAssetPrice(address)", a))
    src = "0x"+call_addr(ORACLE,"getSourceOfAsset(address)",a)[-40:]
    dec = d["decimals"]
    # feed staleness
    upd = None; ans=None; feed_ok=False
    try:
        lr = call_addr(src, "latestRoundData()")
        bb = bytes.fromhex(lr[2:])
        if len(bb) >= 160:
            ans = int.from_bytes(bb[32:64],"big",signed=True)
            upd = int.from_bytes(bb[96:128],"big")
            feed_ok = True
    except Exception as e:
        pass
    if upd is None:
        try:
            upd = as_int(call_addr(src,"latestTimestamp()"))
            ans = int.from_bytes(bytes.fromhex(call_addr(src,"latestAnswer()")[2:]),"big",signed=True)
            feed_ok = True
        except Exception:
            pass
    age_d = (ts_now - upd)/86400.0 if upd else None
    sym = dec_str(call_addr(a,"symbol()")) or "?"
    rows.append(dict(addr=a,sym=sym,dec=dec,cfg=hex(cfg),**d,price=price,src=src,
                     ans=ans,updatedAt=upd,age_days=age_d,feed_ok=feed_ok))

print(f"{'symbol':<12}{'addr':<44}{'dec':>4}{'LTV':>6}{'liqThr':>7}{'bonus':>6}{'act':>4}{'frz':>4}{'borr':>5}{'paus':>5}{'price(1e8)':>14}{'age_d':>9}  source")
for r in rows:
    age = f"{r['age_days']:.2f}" if r['age_days'] is not None else "n/a"
    print(f"{r['sym']:<12}{r['addr']:<44}{r['dec']:>4}{r['LTV']:>6}{r['liqThresh']:>7}{r['liqBonus']:>6}{r['active']:>4}{r['frozen']:>4}{r['borrowingEnabled']:>5}{r['paused']:>5}{r['price']:>14}{age:>9}  {r['src']}")

json.dump(dict(block=now, ts=ts_now, oracle=ORACLE, pool=POOL, reserves=rows),
          open("/home/heisenberg/CA/hyperlend/analysis/reserves_scan.json","w"), indent=1)
print("\n# wrote reserves_scan.json")
