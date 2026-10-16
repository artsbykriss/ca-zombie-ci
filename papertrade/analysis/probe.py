#!/usr/bin/env python3
"""Papertrade live probe (read-only). Public keyless RPC only; no secrets written."""
import json, sys, time, urllib.request

RPCS = [
    "https://rpc.hyperliquid.xyz/evm",
    "https://hyperliquid.drpc.org",
    "https://hyperevm-rpc.dwellir.com",
]

EXCHANGE = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE   = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
BATCH    = "0x233Ff29b239abc1D7748605dA9b205C3e008626E"
EIP1967_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

def rpc(url, method, params, retries=3):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                j = json.loads(r.read())
                if "result" in j: return j["result"]
                return j
        except Exception as e:
            if i == retries-1: raise
            time.sleep(1)

def pick_rpc():
    for u in RPCS:
        try:
            n = rpc(u, "eth_blockNumber", [])
            print(f"# RPC {u} block {int(n,16)}", file=sys.stderr)
            return u
        except Exception as e:
            print(f"# RPC {u} FAILED: {e}", file=sys.stderr)
    raise SystemExit("no rpc")

def call(url, to, data, block="latest"):
    return rpc(url, "eth_call", [{"to":to,"data":data}, block])

def get_storage(url, addr, slot, block="latest"):
    return rpc(url, "eth_getStorageAt", [addr, slot, block])

def main():
    u = pick_rpc()
    bn = int(rpc(u,"eth_blockNumber",[]),16)
    print("block", bn)

    print("== impl slots ==")
    for name,a in [("exchange",EXCHANGE),("oracle",ORACLE),("batch",BATCH)]:
        s = get_storage(u,a,EIP1967_IMPL,hex(bn))
        print(name, "impl", "0x"+s[-40:])

    print("== exchange views ==")
    views = {
        "tradingPaused": "0x53e23e2e",
        "lpBankrollAvailable": "0x0cdd5fc4",
        "totalLockedMargin": "0x01ad056f",
        "totalQueued": "0x53ac4b66",
        "totalBalances": "0xa69a2ad1",
        "oracle": "0x7dc0d1d0",
        "pauseGuardian": "0x24a3d622",
        "marketKeeper": "0x21f55a6c",
        "owner": "0x8da5cb5b",
        "nextPositionId": "0x899346c7",
        "liquidationFeeRate": "0x5fb3b1b5",
        "feeRate2": "0x48ee5e08",
        "queueHead": "0x96523644",
        "devFeeAccumulator": "0x7d004aeb",
        "stakerFeeAccumulator": "0xafdf6702",
        "batchExecutor_slot58": None,
    }
    for name,sel in views.items():
        try:
            if sel:
                r = call(u,EXCHANGE,sel,hex(bn))
            else:
                r = get_storage(u,EXCHANGE,hex(0x58),hex(bn))
            print(name, r)
        except Exception as e:
            print(name, "ERR", e)

    print("== storage slot 0x24 mapping ==")
    for mid in (0,1):
        key = "0x" + format(mid,'064x') + format(0x24,'064x')
        h = rpc(u,"web3_sha3",[key]) if False else None
        # keccak of abi.encode(mid, 0x24)
        import hashlib
        # use eth_call-free keccak via cast? do keccak in python via pysha3 fallback
        try:
            from Crypto.Hash import keccak as _k  # pycryptodome
            k=_k.new(digest_bits=256); k.update(bytes.fromhex(key[2:])); hh="0x"+k.hexdigest()
        except Exception:
            hh=None
        print("mid",mid,"keyhash",hh)
        if hh:
            for off,label in ((0,"slot"),(1,"slot+1")):
                slot = "0x" + format(int(hh,16)+off, '064x')
                r = get_storage(u,EXCHANGE,slot,hex(bn))
                print(" ",label,r)

    print("== oracle probe ==")
    oracle_sels = ["0x23615171","0x30361013","0x3036101b","0x38190036","0x43000818","0x7bfa4b9f","0xb6e8ee11","0xe6c4247b","0xfb466481"]
    for sel in oracle_sels:
        for arg in (0,1):
            data = sel + format(arg,'064x')
            try:
                r = call(u,ORACLE,data,hex(bn))
                if r and r!="0x" and len(r)>2:
                    print("oracle",sel,"arg",arg,r)
            except Exception as e:
                pass
    print("== exchange getBBO probe ==")
    for arg in (0,1,2):
        data = "0xfb466481" + format(arg,'064x')
        try:
            r = call(u,EXCHANGE,data,hex(bn))
            if r and r!="0x":
                print("exchange getBBO arg",arg,r)
        except Exception as e:
            print("exchange getBBO arg",arg,"ERR",str(e)[:80])

if __name__ == "__main__":
    main()
