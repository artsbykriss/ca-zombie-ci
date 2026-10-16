import json, urllib.request, sys, time

RPCS = ["https://rpc.mainnet.chain.robinhood.com", "https://robinhood-rpc.publicnode.com", "https://robinhood.drpc.org"]
RPC = RPCS[0]
_rpc_i = 0
_UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, retries=8):
    global _rpc_i
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last = None
    for i in range(retries):
        url = RPCS[_rpc_i % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers=_UA)
            with urllib.request.urlopen(req, timeout=25) as r:
                d = json.load(r)
                if "error" in d: raise RuntimeError(d["error"])
                return d["result"]
        except Exception as e:
            last = e
            _rpc_i += 1
            time.sleep(min(1.0*(i+1), 5))
    raise last

def batch(calls, chunk=8):
    """calls: list of (method, params). Returns results list."""
    global _rpc_i
    out = []
    for s in range(0, len(calls), chunk):
        part = calls[s:s+chunk]
        payload = [{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(part)]
        got = None
        for attempt in range(8):
            url = RPCS[_rpc_i % len(RPCS)]
            try:
                req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=_UA)
                with urllib.request.urlopen(req, timeout=40) as r:
                    d = json.load(r)
                res = [None]*len(part)
                for item in d:
                    res[item["id"]] = item.get("result") if "error" not in item else {"error": item["error"]}
                got = res
                break
            except Exception as e:
                _rpc_i += 1
                time.sleep(min(1.0*(attempt+1), 6))
        if got is None: raise RuntimeError("batch failed")
        out.extend(got)
    return out

def call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])

# minimal keccak256 (pure python) for selectors
import struct
def keccak(data):
    # Keccak-f[1600]
    RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
          0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
          0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
          0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
          0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
          0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
    R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
    def rol(x,n): return ((x<<n)|(x>>(64-n)))&0xFFFFFFFFFFFFFFFF
    rate = 136
    # pad
    data = bytearray(data)
    data.append(0x01)
    while len(data)%rate != 0: data.append(0)
    data[-1] |= 0x80
    S = [[0]*5 for _ in range(5)]
    for off in range(0,len(data),rate):
        blk = data[off:off+rate]
        for i in range(rate//8):
            x,y = i%5, i//5
            S[x][y] ^= int.from_bytes(blk[i*8:(i+1)*8],"little")
        for rnd in range(24):
            C = [S[x][0]^S[x][1]^S[x][2]^S[x][3]^S[x][4] for x in range(5)]
            D = [C[(x-1)%5]^rol(C[(x+1)%5],1) for x in range(5)]
            for x in range(5):
                for y in range(5): S[x][y]^=D[x]
            B = [[0]*5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2*x+3*y)%5] = rol(S[x][y], R[x][y])
            for x in range(5):
                for y in range(5):
                    S[x][y] = B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])
            S[0][0]^=RC[rnd]
    out = b"".join(S[x][y].to_bytes(8,"little") for y in range(5) for x in range(5))
    return out[:32]

def enc_sel(sig):
    return "0x" + keccak(sig.encode()).hex()[:8]

def addr_of(word): return "0x"+word[-40:]
def dec(word): return int(word,16)

if __name__ == "__main__":
    print("block:", dec(rpc("eth_blockNumber", [])))
