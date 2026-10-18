#!/usr/bin/env python3
"""Read-only state snapshot for Katana Vault Bridge. RPCs from env/public defaults.
No secrets are written; only on-chain values and public prices."""
import json, time, urllib.request
from eth_utils import keccak

ETH = "https://eth.drpc.org"
KAT = "https://rpc.katana.network"

def sel(sig): return "0x" + keccak(text=sig)[:4].hex()

def rpc(url, method, params, tries=3):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, data=body, headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"})
            d = json.loads(urllib.request.urlopen(req, timeout=40).read())
            if "result" in d: return d["result"]
            last = d
        except Exception as e:
            last = str(e)
        time.sleep(0.4)
    return last

def call(url, to, sig, args=()):
    data = sel(sig)
    for a in args:
        data += (hex(a)[2:].zfill(64) if isinstance(a, int) else "0"*24 + a[2:].lower())
    return rpc(url, "eth_call", [{"to": to, "data": data}, "latest"])

def u(x):
    if not isinstance(x, str) or x in ("0x", ""): return None
    try: return int(x, 16)
    except Exception: return None

def a(x):
    if not isinstance(x, str) or len(x) < 42: return None
    return "0x" + x[-40:]

def s(x):
    if not isinstance(x, str) or len(x) < 130: return None
    try:
        n = int(x[2:66], 16); return bytes.fromhex(x[130:130+n*2]).decode(errors="replace")
    except Exception: return None

ADDR = {
"L1_vbUSDC":"0x53E82ABbb12638F09d9e624578ccB666217a765e",
"L1_vbUSDT":"0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC",
"L1_vbWBTC":"0x2C24B57e2CCd1f273045Af6A5f632504C432374F",
"L1_vbETH":"0x2DC70fb75b88d2eB4715bc06E1595E6D97c34DFF",
"L1_vbUSDS":"0x3DD459dE96F9C28e3a343b831cbDC2B93c8C4855",
"L1_adapter_vbUSDC":"0xb5bADA33542a05395d504a25885e02503A957Bb3",
"L1_adapter_vbUSDT":"0x839dC0cFF5e263F56C9810560adF8Ea40E95Ab82",
"L1_adapter_vbWBTC":"0x8d09C41229F07AD098ffB5faD239Dd87D2c131D4",
"L1_adapter_vbETH":"0x8F45F7ACD4b9FC0B446902790F304d444dfF949b",
"L1_lxly":"0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe",
"L2_minter_vbUSDC":"0x807275727Dd3E640c5F2b5DE7d1eC72B4Dd293C0",
"L2_vbUSDC":"0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36",
"L2_converter_vbUSDC":"0x97a3500083348A147F419b8a65717909762c389f",
"L2_minter_vbUSDT":"0x4690f346337eD8737BeA462ac71Ff16Ef95B985E",
"L2_vbUSDT":"0x2DCa96907fde857dd3D816880A0df407eeB2D2F2",
"L2_converter_vbUSDT":"0x053FA9b934b83E1E0ffc7e98a41aAdc3640bB462",
"L2_minter_vbWBTC":"0x8169e532Bc781985e155037db1F96c267a520DFC",
"L2_vbWBTC":"0x0913DA6Da4b42f538B445599b46Bb4622342Cf52",
"L2_converter_vbWBTC":"0xb00aa68b87256E2F22058fB2Ba3246EEc54A44fc",
"L2_minter_vbETH":"0x694d1697F6909361775139357d99fb60b5caB683",
"L2_WETH":"0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62",
"L2_converter_vbETH":"0xa6B0DB1293144Ebe9478B6a84F75dd651E45914a",
"L2_yvvbUSDC":"0x80c34BD3A3569E126e7055831036aa7b212cB159",
"L2_endpoint":"0x6F475642a6e85809B1c36Fa62763669b1b48DD5B",
"L2_lxly":"0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe",
"L2_GER":"0xa40D5f56745a118D0906a34E69aeC8C0Db1cB8fA",
}

out = {"block": {}, "l1": {}, "l2": {}, "prices": {}}
out["block"]["ethereum"] = u(rpc(ETH, "eth_blockNumber", []))
out["block"]["katana"] = u(rpc(KAT, "eth_blockNumber", []))

def rec(url, name, addr, fields):
    d = {}
    for key, (sig, args) in fields.items():
        r = call(url, addr, sig, args)
        if key in ("name","symbol","version"): d[key] = s(r)
        elif key in ("asset","owner","token","endpoint","yieldVault","nativeConverter","underlyingToken","customToken","role_manager","bridgeManager","globalExitRootUpdater"):
            d[key] = a(r)
        elif key in ("peer_30101","peer_30375"): d[key] = r
        else: d[key] = u(r)
    out["l1" if url == ETH else "l2"][name] = {"address": addr, **d}

L1_VAULT_FIELDS = {
    "totalSupply": ("totalSupply()", ()), "totalAssets": ("totalAssets()", ()),
    "reservedAssets": ("reservedAssets()", ()), "asset": ("asset()", ()),
    "yieldVault": ("yieldVault()", ()), "paused": ("paused()", ()),
}
for n in ["L1_vbUSDC","L1_vbUSDT","L1_vbWBTC","L1_vbETH","L1_vbUSDS"]:
    rec(ETH, n, ADDR[n], L1_VAULT_FIELDS)
for n in ["L1_vbUSDC","L1_vbUSDT","L1_vbWBTC","L1_vbETH"]:
    out["l1"][n]["lxlyEscrow"] = u(call(ETH, ADDR[n], "balanceOf(address)", (ADDR["L1_lxly"],)))
for n, adp in [("L1_vbUSDC","L1_adapter_vbUSDC"),("L1_vbUSDT","L1_adapter_vbUSDT"),("L1_vbWBTC","L1_adapter_vbWBTC"),("L1_vbETH","L1_adapter_vbETH")]:
    out["l1"][n]["lzAdapterBalance"] = u(call(ETH, ADDR[n], "balanceOf(address)", (ADDR[adp],)))

for n in ["L1_adapter_vbUSDC","L1_adapter_vbUSDT","L1_adapter_vbWBTC","L1_adapter_vbETH"]:
    rec(ETH, n, ADDR[n], {"owner":("owner()",()), "token":("token()",()), "endpoint":("endpoint()",()), "peer_30375":("peers(uint32)",(30375,)), "initCounter":("globalInitializationCounter()",())})

for n in ["L2_vbUSDC","L2_vbUSDT","L2_vbWBTC"]:
    rec(KAT, n, ADDR[n], {"totalSupply":("totalSupply()",()), "decimals":("decimals()",()), "nativeConverter":("nativeConverter()",()), "paused":("paused()",()), "version":("version()",()), "totalNetMinted":("totalNetMintedByAdditionalMintersBurners()",())})
rec(KAT, "L2_WETH", ADDR["L2_WETH"], {"totalSupply":("totalSupply()",()), "nativeConverter":("nativeConverter()",()), "paused":("paused()",()), "version":("version()",())})
out["l2"]["L2_WETH"]["ethBalance"] = u(rpc(KAT, "eth_getBalance", [ADDR["L2_WETH"], "latest"]))

for n in ["L2_minter_vbUSDC","L2_minter_vbUSDT","L2_minter_vbWBTC","L2_minter_vbETH"]:
    rec(KAT, n, ADDR[n], {"owner":("owner()",()), "token":("token()",()), "endpoint":("endpoint()",()), "peer_30101":("peers(uint32)",(30101,)), "initCounter":("globalInitializationCounter()",()), "secondaryChainBalance":("secondaryChainBalance()",()), "approvalRequired":("approvalRequired()",())})

for n in ["L2_converter_vbUSDC","L2_converter_vbUSDT","L2_converter_vbWBTC","L2_converter_vbETH"]:
    rec(KAT, n, ADDR[n], {"customToken":("customToken()",()), "underlyingToken":("underlyingToken()",()), "backingOnLayerY":("backingOnLayerY()",()), "paused":("paused()",())})
    d = out["l2"][n]
    if d.get("underlyingToken"):
        d["underlyingBalance"] = u(call(KAT, d["underlyingToken"], "balanceOf(address)", (ADDR[n],)))

rec(KAT, "L2_yvvbUSDC", ADDR["L2_yvvbUSDC"], {"totalAssets":("totalAssets()",()), "totalSupply":("totalSupply()",()), "pricePerShare":("pricePerShare()",()), "totalIdle":("totalIdle()",()), "totalDebt":("totalDebt()",()), "role_manager":("role_manager()",()), "isShutdown":("isShutdown()",())})

rec(KAT, "L2_lxly", ADDR["L2_lxly"], {"networkID":("networkID()",()), "depositCount":("depositCount()",())})
rec(KAT, "L2_GER", ADDR["L2_GER"], {"globalExitRootUpdater":("globalExitRootUpdater()",()), "bridgeManager":("bridgeManager()",())})
# bridgeManager is on the bridge, not GER
out["l2"]["L2_lxly"]["bridgeManager"] = a(call(KAT, ADDR["L2_lxly"], "bridgeManager()", ()))

# proxy admin owners (key)
for chain, url, pairs in [
    ("l1", ETH, {"L1_vbUSDC":("0x8970650cf3f1e57ca804c65b4dbcff698789fe30",), "L1_adapter_vbUSDC":("0xff3a591400dd2a68e6df6bb6974089feff75b13b",)}),
    ("l2", KAT, {"L2_minter_vbUSDC":("0x2124704b63e09f246343f5878ee94e97a8e99fc6",), "L2_vbUSDC":("0xf5f3a9687f45217df2e5fff191fbd1b1aaf57e7e",)}),
]:
    for n,(adm,) in pairs.items():
        out[chain][n]["proxyAdmin"] = adm
        out[chain][n]["proxyAdminOwner"] = a(call(url, adm, "owner()", ()))

# prices
try:
    ids = "coingecko:ethereum,coingecko:wrapped-bitcoin,coingecko:usd-coin,coingecko:tether,coingecko:usds"
    p = json.loads(urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/" + ids + "?searchWidth=4h", headers={"user-agent":"Mozilla/5.0"}), timeout=30).read())
    out["prices"] = {k: v["price"] for k, v in p["coins"].items()}
except Exception as e:
    out["prices"] = {"error": str(e)[:100]}

json.dump(out, open("/home/heisenberg/CA/katana-bridge/analysis/state_map.json", "w"), indent=1)
print(json.dumps(out, indent=1)[:6000])
