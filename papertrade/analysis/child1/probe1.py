#!/usr/bin/env python3
"""Child1 live probe (READ-ONLY). Public keyless RPC only. No secrets."""
import json, sys, urllib.request, time

RPC = "https://rpc.hyperliquid.xyz/evm"
EXCHANGE = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE   = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
BATCH    = "0x233Ff29b239abc1D7748605dA9b205C3e008626E"
EIP1967_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

def rpc(method, params, retries=4):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                j = json.loads(r.read())
            if "result" in j: return j["result"]
            raise RuntimeError(j.get("error"))
        except Exception as e:
            if i == retries-1: raise
            time.sleep(1.5)

def call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])

def sget(addr, slot, block="latest"):
    return rpc("eth_getStorageAt", [addr, slot, block])

def keccak(b: bytes) -> str:
    from Crypto.Hash import keccak as _k
    k = _k.new(digest_bits=256); k.update(b); return k.hexdigest()

def addr_word(a):  # left-pad address into 32 bytes
    return format(int(a,16),'064x')

bn = int(rpc("eth_blockNumber", []), 16)
print(f"# block {bn}")

print("== EIP-1967 impl slots @ latest ==")
for name, a in [("exchange",EXCHANGE),("batch",BATCH),("oracle",ORACLE)]:
    s = sget(a, EIP1967_IMPL, hex(bn))
    print(f"{name} proxy {a} impl 0x{s[-40:]}")

print("== BatchExecutor getters ==")
for name, sel in [("owner()","0x8da5cb5b"),("sessionKeyManager() 0x0b826190","0x0b826190"),
                  ("SLOAD0>>16 (0xd2f7265a)","0xd2f7265a"),("SLOAD2 (0xd5c539ce)","0xd5c539ce"),
                  ("SLOAD5&ff (0x6090cf16)","0x6090cf16")]:
    try: print(f"BATCH {name}: {call(BATCH, sel, hex(bn))}")
    except Exception as e: print(f"BATCH {name}: ERR {e}")

print("== BatchExecutor raw storage slots 0..5, 0x1d, 0x58 ==")
for slot in ["0x0","0x1","0x2","0x3","0x4","0x5","0x1d","0x58"]:
    print(f"  batch[{slot}] = {sget(BATCH, slot, hex(bn))}")

print("== relayer mapping getter 0x29e295c5 for candidate relayers ==")
cands = ["0xc916e55b1909be6582bf1b2f017aaf82ad8eb0b4",
         "0xe726b15cfa8808b2b033dd324a61e754dc6c1686"]
for c in cands + ["0x0000000000000000000000000000000000000000"]:
    try: print(f"relayers({c}) = {call(BATCH, '0x29e295c5'+addr_word(c), hex(bn))}")
    except Exception as e: print(f"relayers({c}) ERR {e}")

print("== mapping slot4 raw for candidates (keccak(addr||4)) ==")
for c in cands:
    key = bytes.fromhex(addr_word(c) + format(4,'064x'))
    h = "0x" + keccak(key)
    print(f"  {c}: key={h} val={sget(BATCH, h, hex(bn))}")

print("== Exchange getters ==")
for name, sel in [("owner()","0x8da5cb5b"),("tradingPaused(0x53e23e2e)","0x53e23e2e"),
                  ("oracle(0x7dc0d1d0)","0x7dc0d1d0"),("nextPositionId(0x899346c7)","0x899346c7"),
                  ("pauseGuardian(0x24a3d622)","0x24a3d622"),("marketKeeper(0x21f55a6c)","0x21f55a6c")]:
    try: print(f"EXCH {name}: {call(EXCHANGE, sel, hex(bn))}")
    except Exception as e: print(f"EXCH {name}: ERR {e}")
print(f"EXCH storage[0x58] = {sget(EXCHANGE, '0x58', hex(bn))}")

print("== Oracle getBBO(0),(1),(2) ==")
for arg in (0,1,2):
    try:
        r = call(ORACLE, "0xfb466481"+format(arg,'064x'), hex(bn))
        print(f"oracle getBBO({arg}) = {r}")
        if r and len(r) >= 2+64*2:
            w = r[2:]
            bid = int(w[0:64],16); ask = int(w[64:128],16)
            print(f"   decoded bid={bid} ask={ask}")
    except Exception as e:
        print(f"oracle getBBO({arg}) ERR {e}")

print("== Exchange getBBO passthrough ==")
for arg in (0,1):
    try: print(f"EXCH getBBO({arg}) = {call(EXCHANGE,'0xfb466481'+format(arg,'064x'),hex(bn))}")
    except Exception as e: print(f"EXCH getBBO({arg}) ERR {str(e)[:100]}")

print("== positions(0) and (10) ==")
for pid in (0,10):
    try: print(f"positions({pid}) = {call(EXCHANGE,'0x99fbab88'+format(pid,'064x'),hex(bn))}")
    except Exception as e: print(f"positions({pid}) ERR {e}")
