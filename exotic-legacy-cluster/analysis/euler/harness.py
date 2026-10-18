import json, time, sys, os
import requests
from eth_abi import encode as abi_encode, decode as abi_decode
from eth_utils import keccak

HERE = os.path.dirname(os.path.abspath(__file__))
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"

CHAINS = {
 "ethereum": dict(cid=1, rpc="https://ethereum-rpc.publicnode.com", llama="ethereum",
   factory="0x29a56a1b8214D9Cf7c5561811750D5cBDb45CC8e"),
 "base": dict(cid=8453, rpc="https://base-rpc.publicnode.com", llama="base",
   factory="0x7F321498A801A191a93C840750ed637149dDf8D0"),
 "arbitrum": dict(cid=42161, rpc="https://arb1.arbitrum.io/rpc", llama="arbitrum",
   factory="0x78Df1CF5bf06a7f27f2ACc580B934238C1b80D50"),
 "monad": dict(cid=143, rpc="https://rpc.monad.xyz", llama="monad",
   factory="0xba4Dd672062dE8FeeDb665DD4410658864483f1E"),
 "sonic": dict(cid=146, rpc="https://rpc.soniclabs.com", llama="sonic",
   factory="0xF075cC8660B51D0b8a4474e3f47eDAC5fA034cFB"),
 "avalanche": dict(cid=43114, rpc="https://api.avax.network/ext/bc/C/rpc", llama="avax",
   factory="0xaf4B4c18B17F6a2B32F6c398a3910bdCD7f26181"),
 "unichain": dict(cid=130, rpc="https://mainnet.unichain.org", llama="unichain",
   factory="0xbAd8b5BDFB2bcbcd78Cc9f1573D3Aad6E865e752"),
 "bob": dict(cid=60808, rpc="https://rpc.gobob.xyz", llama="bob",
   factory="0x046a9837A61d6b6263f54F4E27EE072bA4bdC7e4"),
 "berachain": dict(cid=80094, rpc="https://rpc.berachain.com", llama="berachain",
   factory="0x5C13fb43ae9BAe8470f646ea647784534E9543AF"),
 "linea": dict(cid=59144, rpc="https://rpc.linea.build", llama="linea",
   factory="0x84711986Fd3BF0bFe4a8e6d7f4E22E67f7f27F04"),
 "plasma": dict(cid=9745, rpc="https://rpc.plasma.to", llama="plasma",
   factory="0x42388213C6F56D7E1477632b58Ae6Bba9adeEeA3"),
 "hyperliquid": dict(cid=999, rpc="https://rpc.hyperliquid.xyz/evm", llama="hyperliquid",
   factory="0xcF5552580fD364cdBBFcB5Ae345f75674c59273A"),
 "mantle": dict(cid=5000, rpc="https://rpc.mantle.xyz", llama="mantle",
   factory="0x47Aaf2f062aa1D55AFa602f5C9597588f71E2d76"),
 "bsc": dict(cid=56, rpc="https://bsc-rpc.publicnode.com", llama="bsc",
   factory="0x7F53E2755eB3c43824E162F7F6F087832B9C9Df6"),
}

SEL = {}
def sel(sig):
    if sig not in SEL:
        SEL[sig] = keccak(text=sig)[:4]
    return SEL[sig]

_tm = {}
class RPC:
    def __init__(self, url):
        self.url = url
        self.s = requests.Session()
        self.id = 0
        self.block = None
    def _post(self, payload, tries=4):
        for i in range(tries):
            try:
                r = self.s.post(self.url, json=payload, timeout=25)
                if r.status_code == 200:
                    j = r.json()
                    return j
                time.sleep(0.4 * (i + 1))
            except Exception:
                time.sleep(0.4 * (i + 1))
        raise RuntimeError(f"rpc failed {self.url}")
    def call(self, method, params):
        self.id += 1
        j = self._post({"jsonrpc": "2.0", "id": self.id, "method": method, "params": params})
        if "error" in j:
            raise RuntimeError(str(j["error"])[:200])
        return j["result"]
    def blocknum(self):
        if self.block is None:
            self.block = int(self.call("eth_blockNumber", []), 16)
        return self.block
    def eth_call(self, to, data, block=None):
        b = block or self.blocknum()
        return self.call("eth_call", [{"to": to, "data": "0x" + data.hex()}, hex(b)])
    def batch(self, method, params_list, chunk=80):
        out = []
        for i in range(0, len(params_list), chunk):
            part = params_list[i:i+chunk]
            payload = [{"jsonrpc": "2.0", "id": j, "method": method, "params": p} for j, p in enumerate(part)]
            try:
                j = self._post(payload, tries=2)
            except Exception:
                j = None
            if isinstance(j, dict):
                j = [j]
            if not isinstance(j, list):
                for p in part:
                    try:
                        out.append(self.call(method, p))
                    except Exception:
                        out.append(None)
                continue
            byid = {x.get("id"): x for x in j if isinstance(x, dict)}
            for k in range(len(part)):
                x = byid.get(k, {})
                out.append(x.get("result") if "result" in x else None)
        return out
    def mc(self, calls, allow=True, chunksz=120, block=None):
        """calls: list of (target, calldata bytes). returns list of (ok, hexstr|None)"""
        out = []
        b = block or self.blocknum()
        for i in range(0, len(calls), chunksz):
            part = calls[i:i+chunksz]
            arr = [(t, allow, d) for (t, d) in part]
            data = sel("aggregate3((address,bool,bytes)[])") + abi_encode(["(address,bool,bytes)[]"], [arr])
            for attempt in range(4):
                try:
                    ret = self.eth_call(MC3, data, b)
                    dec = abi_decode(["(bool,bytes)[]"], bytes.fromhex(ret[2:]))[0]
                    if len(dec) != len(part):
                        raise RuntimeError("mc len")
                    out.extend([(bool(ok), "0x" + r.hex()) for (ok, r) in dec])
                    break
                except Exception as e:
                    if attempt == 3:
                        # fallback individual calls
                        for (t, d) in part:
                            try:
                                out.append((True, self.eth_call(t, d, b)))
                            except Exception:
                                out.append((False, None))
                    else:
                        time.sleep(0.5 * (attempt + 1))
        return out

def dec_addr(hexs):
    if not hexs or len(hexs) < 42: return None
    return "0x" + hexs[-40:]

def dec_uint(hexs):
    if not hexs or hexs == "0x": return None
    return int(hexs, 16)

def dec_str(hexs):
    if not hexs or hexs == "0x": return None
    try:
        b = bytes.fromhex(hexs[2:])
        if len(b) >= 64:
            ln = int.from_bytes(b[32:64], "big")
            return b[64:64+ln].decode("utf-8", "replace")
        return b.decode("utf-8", "replace")
    except Exception:
        return None

def dec_addrs(hexs):
    if not hexs or hexs == "0x": return []
    try:
        b = bytes.fromhex(hexs[2:])
        n = int.from_bytes(b[32:64], "big")
        return ["0x" + b[64+32*i+12:64+32*i+32].hex() for i in range(n)]
    except Exception:
        return []

def enc_addr(a):
    return bytes.fromhex("0"*24 + a[2:].lower())

def enumerate_chain(name, maxv=2000):
    c = CHAINS[name]
    r = RPC(c["rpc"])
    cid = int(r.call("eth_chainId", []), 16)
    assert cid == c["cid"], (name, cid)
    blk = r.blocknum()
    print(f"[{name}] block {blk} chainId {cid}", flush=True)
    ln_hex = r.eth_call(c["factory"], sel("getProxyListLength()"))
    n = int(ln_hex, 16)
    n_eff = min(n, maxv)
    print(f"[{name}] proxies {n} (cap {maxv})", flush=True)
    calls = [(c["factory"], sel("proxyList(uint256)") + abi_encode(["uint256"], [i])) for i in range(n_eff)]
    res = r.mc(calls, chunksz=150)
    proxies = [dec_addr(h) for (ok, h) in res if ok]
    proxies = [p for p in proxies if p]
    return dict(name=name, chainId=cid, block=blk, factory=c["factory"], reported=n,
                enumerated=len(proxies), proxies=proxies)

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "enum":
        names = sys.argv[2:] or list(CHAINS)
        allout = {}
        fn = os.path.join(HERE, "raw_proxies.json")
        if os.path.exists(fn):
            allout = json.load(open(fn))
        for nm in names:
            try:
                allout[nm] = enumerate_chain(nm)
                json.dump(allout, open(fn, "w"), indent=1)
            except Exception as e:
                print(f"[{nm}] FAIL {e}", flush=True)
        print(json.dumps({k: (v["reported"], v["block"]) for k,v in allout.items()}, indent=1))
