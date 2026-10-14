"""Minimal JSON-RPC helper (read-only, keyless-or-env). Never stores secret URLs."""
import json, os, time, urllib.request

try:
    import sha3  # pysha3
    def _keccak(b: bytes) -> bytes:
        k = sha3.keccak_256(); k.update(b); return k.digest()
except Exception:  # pragma: no cover
    from eth_hash.auto import keccak as _keccak  # type: ignore

from eth_abi import encode as _abi_encode, decode as _abi_decode


def selector(sig: str) -> str:
    return "0x" + _keccak(sig.encode()).hex()[:8]


def calldata(sig: str, types, vals) -> str:
    return selector(sig) + _abi_encode(types, vals).hex()


def dec(types, hexres: str):
    if hexres is None or hexres in ("0x", ""):
        return tuple()
    return _abi_decode(types, bytes.fromhex(hexres[2:]))


def default_urls(chain: str):
    """Keyed endpoints come from env (never persisted); public keyless fallbacks always included."""
    if chain == "era":
        urls = []
        if os.environ.get("ERA_RPC"):
            urls.append(("env:ERA_RPC", os.environ["ERA_RPC"]))
        if os.environ.get("DRPC_API_KEY"):
            urls.append(("env:DRPC", f"https://lb.drpc.org/ogrpc?network=zksync-era&dkey={os.environ['DRPC_API_KEY']}"))
        urls += [("public:era.zksync.io", "https://mainnet.era.zksync.io"),
                 ("public:zksync.drpc.org", "https://zksync.drpc.org")]
        return urls
    if chain == "telos":
        urls = []
        if os.environ.get("TELOS_RPC"):
            urls.append(("env:TELOS_RPC", os.environ["TELOS_RPC"]))
        urls += [("public:rpc.telos.net", "https://rpc.telos.net")]
        return urls
    raise ValueError(chain)


class RPC:
    def __init__(self, urls, name="rpc", batch=3):
        self.urls = urls
        self.name = name
        self.batch = batch
        self._good = None

    def _ordered_urls(self):
        if self._good:
            return [self._good] + [u for u in self.urls if u[0] != self._good[0]]
        return self.urls

    # ---------- low level ----------
    def _post(self, url, payload, timeout=25):
        req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) research-read-only",
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read())

    def call(self, method, params, retries=4, timeout=25):
        last = None
        for a in range(retries):
            for label, url in self.urls:
                try:
                    j = self._post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout)
                    if "result" in j:
                        return j["result"]
                    last = RuntimeError(f"{self.name}[{label}] rpc error: {str(j.get('error'))[:160]}")
                except Exception as e:
                    last = e
            time.sleep(0.6 * (a + 1))
        raise last

    def call_ret(self, method, params, retries=3):
        try:
            return self.call(method, params, retries=retries), None
        except Exception as e:
            return None, str(e)[:220]

    def eth_call(self, to, data, block="latest"):
        return self.call("eth_call", [{"to": to, "data": data}, block])

    def eth_calls(self, items, block="latest"):
        """items: list of (to, data). Returns list of raw hex results.
        Deterministic per-item errors (reverts) raise a RuntimeError at the end."""
        out = [None] * len(items)
        errs = [None] * len(items)
        pending = list(range(len(items)))
        attempt = 0
        while pending and attempt < 3:
            attempt += 1
            groups = [pending[i:i + self.batch] for i in range(0, len(pending), self.batch)]
            still = []
            for g in groups:
                payload = [{"jsonrpc": "2.0", "id": i, "method": "eth_call",
                            "params": [{"to": items[i][0], "data": items[i][1]}, block]} for i in g]
                transport_fail = True
                for label, url in self._ordered_urls():
                    try:
                        resp = self._post(url, payload, timeout=20)
                    except Exception:
                        continue
                    if not isinstance(resp, list):
                        continue
                    self._good = (label, url)
                    transport_fail = False
                    byid = {r.get("id"): r for r in resp}
                    for i in g:
                        r = byid.get(i, {})
                        if "result" in r:
                            out[i] = r["result"]
                        else:
                            errs[i] = str(r.get("error", "no result"))[:200]
                    break
                if transport_fail:
                    still.extend(g)
            pending = still
            if pending:
                time.sleep(0.5 * attempt)
        if pending:
            for i in pending:
                errs[i] = errs[i] or "transport failure"
        return out, errs

    def try_calls(self, items, block="latest"):
        """Batch version returning [(raw_or_None, err)] without raising."""
        try:
            raws, errs = self.eth_calls(items, block=block)
        except Exception as e:
            return [(None, str(e)[:200])] * len(items)
        return list(zip(raws, errs))

    def try_call(self, to, sig, types=(), vals=(), out_types=None, block="latest"):
        try:
            r = self.eth_call(to, calldata(sig, types, vals), block)
        except Exception as e:
            return None, str(e)[:200]
        if out_types is None:
            return r, None
        try:
            return dec(out_types, r), None
        except Exception as e:
            return r, f"decode: {e}"

    def block_number(self):
        return int(self.call("eth_blockNumber", []), 16)
