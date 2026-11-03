#!/usr/bin/env python3
"""Enumerate the ApolloX EIP-2535 diamond facets and fetch verified sources/ABIs.

Read-only. Uses BSC public RPC for facets() and Etherscan V2 (chainid 56) for source.
API key is read from ETHERSCANV2_API_KEY; never written to disk.
Output: analysis/apollox_facets.json + analysis/facets/<addr>_{abi.json,src.json}
"""
import json, os, sys, time, urllib.parse, urllib.request

RPC = os.environ.get("BSC_RPC_URL", "https://bsc-rpc.publicnode.com")
BLOCK = int(os.environ.get("PIN_BLOCK", "131443197"))
DIAMOND = "0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0"
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "facets")
os.makedirs(OUT, exist_ok=True)


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type": "application/json", "User-Agent": "ca-research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.load(r)
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]


def call(to, data, block=BLOCK):
    return rpc("eth_call", [{"to": to, "data": data}, hex(block)])


def eth_get_code(addr, block=BLOCK):
    return rpc("eth_getCode", [addr, hex(block)])


# facets() selector 0x7a0ed627
raw = call(DIAMOND, "0x7a0ed627")
# decode dynamic array of (address, bytes4[])
def words(hexstr):
    b = bytes.fromhex(hexstr[2:])
    return [b[i:i + 32] for i in range(0, len(b), 32)]


def u256(w):
    return int.from_bytes(w, "big")


def addr(w):
    return "0x" + w[12:].hex()


w = words(raw)
base = u256(w[0]) // 32            # word index of the array length
n = u256(w[base])
facets = []
for i in range(n):
    # tuple pointers are byte offsets relative to the array data area (after the length word)
    t = base + 1 + u256(w[base + 1 + i]) // 32
    facet = addr(w[t])
    soff = t + u256(w[t + 1]) // 32
    cnt = u256(w[soff])
    sels = ["0x" + w[soff + 1 + j][:4].hex() for j in range(cnt)]
    facets.append({"facet": facet, "selectors": sels})

print(f"facets: {len(facets)} total selectors {sum(len(f['selectors']) for f in facets)}")

def es(action, **kw):
    q = {"chainid": "56", "module": "contract", "action": action, "apikey": KEY}
    q.update(kw)
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(q)
    req = urllib.request.Request(url, headers={"User-Agent": "ca-research/1.0"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception as e:
            print("retry", e, file=sys.stderr)
            time.sleep(3)
    return {}

for f in facets:
    a = f["facet"]
    path = os.path.join(OUT, a + ".json")
    if os.path.exists(path):
        d = json.load(open(path))
    else:
        d = es("getsourcecode", address=a)
        time.sleep(0.25)
        if not d.get("result"):
            d = {}
        json.dump(d, open(path, "w"), indent=1)
    res = (d.get("result") or [{}])[0] if d else {}
    f["name"] = res.get("ContractName", "")
    f["verified"] = bool(res.get("SourceCode"))
    f["proxy"] = res.get("Proxy", "0")
    f["implementation"] = res.get("Implementation", "")
    f["compiler"] = res.get("CompilerVersion", "")
    try:
        f["abi"] = json.loads(res.get("ABI", "[]"))
    except Exception:
        f["abi"] = []
    f["code_size"] = len(eth_get_code(a)) // 2 - 1
    print(f"{a} {f['name']:55s} sels={len(f['selectors']):2d} verified={f['verified']} size={f['code_size']}")

json.dump({"diamond": DIAMOND, "block": BLOCK, "facets": facets},
          open(os.path.join(HERE, "apollox_facets.json"), "w"), indent=1)

# selector -> facet map
selmap = {}
for f in facets:
    for s in f["selectors"]:
        selmap[s] = f["facet"]
json.dump(selmap, open(os.path.join(HERE, "selector_map.json"), "w"), indent=1)
print("wrote apollox_facets.json, selector_map.json")
