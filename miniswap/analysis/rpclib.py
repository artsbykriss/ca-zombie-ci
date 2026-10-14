#!/usr/bin/env python3
"""Minimal batched Ethereum JSON-RPC helper for MiniSwap recon.
URLs are assembled at runtime from /home/heisenberg/CA/.env (keys never stored in this folder)."""
import json, os, sys, time, subprocess

ENVF = "/home/heisenberg/CA/.env"
def getk(name):
    try:
        with open(ENVF) as f:
            for line in f:
                if line.startswith(name+"="):
                    return line.split("=",1)[1].strip().strip('"')
    except Exception:
        pass
    return None

def candidates():
    u=[]
    inf=getk("INFURA_API_KEY"); u.append(("infura", f"https://mainnet.infura.io/v3/{inf}")) if inf else None
    u.append(("publicnode","https://ethereum-rpc.publicnode.com"))
    dr=getk("DRPC_API_KEY"); u.append(("drpc", f"https://lb.drpc.org/ogrpc?network=ethereum&dkey={dr}")) if dr else None
    nr=getk("NODEREAL_ETH_RPC_URL"); u.append(("nodereal", nr)) if nr else None
    bp=getk("BLOCKPI_RPC_URL"); u.append(("blockpi", bp)) if bp else None
    return u

_urls = None
def urls():
    global _urls
    if _urls is None: _urls = candidates()
    return _urls

def _promote(name):
    """Move a working URL to the front so subsequent calls hit it first."""
    global _urls
    _urls = sorted(_urls, key=lambda x: 0 if x[0]==name else 1)

def _post(url, body, timeout=20):
    """POST JSON via curl (robust IPv4/happy-eyeballs); returns parsed JSON or raises."""
    p = subprocess.run(["curl","-s","--max-time",str(timeout),"-X","POST",
                        "-H","Content-Type: application/json","--data-binary","@-",url],
                       input=body, capture_output=True, timeout=timeout+5)
    if p.returncode != 0 or not p.stdout:
        raise RuntimeError(f"curl rc={p.returncode} err={p.stderr[:100].decode(errors='replace')}")
    return json.loads(p.stdout)

def rpc_batch(calls, timeout=20, retries=3):
    """Try each candidate URL until all results arrive; then retry stragglers individually.
    Returns list where each entry is the hex result or None (None = no answer / revert)."""
    out = [None]*len(calls)
    n = len(calls)
    payload = [{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]
    for attempt in range(retries):
        missing = [i for i,x in enumerate(out) if x is None]
        if not missing: break
        body = json.dumps([payload[i] for i in missing]).encode()
        for name,url in urls():
            try:
                resp = _post(url, body, timeout=timeout)
                for item in resp:
                    if isinstance(item, dict):
                        idx = item.get("id")
                        if idx is not None and "result" in item and item["result"] is not None:
                            out[missing[idx]] = item["result"]
                _promote(name)
                break  # this URL answered; move on
            except Exception as e:
                sys.stderr.write(f"[rpc] {name} err: {str(e)[:80]}\n")
        # retry stragglers individually (still-missing)
        for i in [i for i,x in enumerate(out) if x is None]:
            if n > 1:
                r = rpc_batch([calls[i]], timeout=timeout, retries=1)
                if r[0] is not None: out[i] = r[0]
        time.sleep(0.3)
    return out

def eth_call(to, data, block="latest"):
    return rpc_batch([("eth_call", [{"to":to,"data":data}, block])])[0]

def calls_batched(items, chunk=10, block="latest"):
    res=[]
    for i in range(0,len(items),chunk):
        part=items[i:i+chunk]
        rs=rpc_batch([("eth_call",[{"to":t,"data":d},block]) for t,d in part])
        res.extend(rs); time.sleep(0.15)
    return res

SEL = {
 "allPairsLength":"0x574f2ba3","allPairs":"0x1e3dd18b","feeTo":"0x017e7e58",
 "feeToSetter":"0x094b7415","setFeeToSetter":"0xa2e74af6","setFeeTo":"0xf46901ed","token0":"0x0dfe1681","token1":"0xd21220a7",
 "getReserves":"0x0902f1ac","totalSupply":"0x18160ddd","balanceOf":"0x70a08231",
 "symbol":"0x95d89b41","name":"0x06fdde03","decimals":"0x313ce567","owner":"0x8da5cb5b",
 "skim":"0xbc25cf77","sync":"0xfff6cae9","swap":"0x022c0d9f","mint":"0x6a627842",
 "burn":"0x89afcb44","kLast":"0x7464fc3d","factory":"0xc45a0155","getPair":"0xe6a43905",
 "token0_addr":"0x0dfe1681","implementation":"0x5c60da1b","admin":"0xf851a440",
}
def pad(addr): return "0"*24 + addr.lower().replace("0x","")

if __name__ == "__main__":
    bn = rpc_batch([("eth_blockNumber",[])])[0]
    print("block:", int(bn,16) if bn else None)
    f="0x1e2c2102cf8efcaaaf20ffe926469ec7cd0d0f6e"
    n=eth_call(f,SEL["allPairsLength"])
    print("pairs:", int(n,16) if n else None)
