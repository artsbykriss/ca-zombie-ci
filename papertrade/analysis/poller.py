#!/usr/bin/env python3
"""Background poller: OI + caps storage for BTC(0)/ETH(1) on Papertrade Exchange.
Read-only, public keyless RPC. Writes JSONL to analysis/oi_poll.jsonl."""
import json, time, urllib.request, sys, os
from Crypto.Hash import keccak

U = "https://rpc.hyperliquid.xyz/evm"
EX = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "oi_poll.jsonl")

def rpc(m, p, timeout=15):
    b = json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
    r = urllib.request.Request(U, data=b, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.loads(urllib.request.urlopen(r, timeout=timeout).read())

def slot_hash(mid):
    key = bytes.fromhex(format(mid,'064x') + format(0x24,'064x'))
    k = keccak.new(digest_bits=256); k.update(key)
    return "0x" + k.hexdigest()

def main():
    hashes = {mid: slot_hash(mid) for mid in (0,1)}
    end = time.time() + int(sys.argv[1]) if len(sys.argv) > 1 else time.time() + 2700
    n = 0
    with open(OUT, "a") as f:
        while time.time() < end:
            try:
                bn = int(rpc("eth_blockNumber", [])["result"], 16)
                rec = {"t": int(time.time()), "block": bn}
                for mid, name in ((0,"BTC"),(1,"ETH")):
                    s0 = rpc("eth_getStorageAt", [EX, hashes[mid], hex(bn)])["result"]
                    s1 = rpc("eth_getStorageAt", [EX, "0x"+format(int(hashes[mid],16)+1,'064x'), hex(bn)])["result"]
                    rec[name] = {"s0": s0, "s1": s1}
                f.write(json.dumps(rec)+"\n"); f.flush()
                n += 1
            except Exception as e:
                f.write(json.dumps({"t":int(time.time()),"err":str(e)[:120]})+"\n"); f.flush()
            time.sleep(15)
    print("polled", n, "samples")

if __name__ == "__main__":
    main()
