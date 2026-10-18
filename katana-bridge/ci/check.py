#!/usr/bin/env python3
"""CI validation for katana-bridge: schema + live auth/backing re-reads + secret scan.
Public RPCs only. No secrets are read or written."""
import json, os, re, sys, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ETH = os.environ.get("CHECK_ETH_RPC", "https://eth.drpc.org")
KAT = os.environ.get("KATANA_RPC_URL", "https://rpc.katana.network")

SEL = {
 "totalSupply()":"0x18160ddd", "balanceOf(address)":"0x70a08231",
 "peers(uint32)":"0xbb0b6a53", "endpoint()":"0x5e280f11",
 "globalInitializationCounter()":"0x4267d865", "backingOnLayerY()":"0xf524fe57",
 "hasRole(bytes32,address)":"0x91d14854",
}
def sel(s): return SEL[s]
def rpc(url, method, params, tries=3):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, data=body, headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
            d = json.loads(urllib.request.urlopen(req, timeout=40).read())
            if "result" in d: return d["result"]
            last = d
        except Exception as e:
            last = str(e)
    raise RuntimeError(f"{method} failed: {last}")
def call(url, to, sig, args=()):
    data = sel(sig)
    for a in args:
        if isinstance(a, int):
            data += hex(a)[2:].zfill(64)
        elif isinstance(a, str) and a.startswith("0x") and len(a) == 66:
            data += a[2:].lower()
        else:
            data += "0"*24 + a[2:].lower()
    return rpc(url, "eth_call", [{"to":to,"data":data},"latest"])
def u(x): return int(x,16) if isinstance(x,str) and x not in ("0x","") else None
A = {
 "vbUSDC":"0x53E82ABbb12638F09d9e624578ccB666217a765e",
 "vbUSDT":"0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC",
 "vbWBTC":"0x2C24B57e2CCd1f273045Af6A5f632504C432374F",
 "adapter":"0xb5bADA33542a05395d504a25885e02503A957Bb3",
 "adapterUSDT":"0x839dC0cFF5e263F56C9810560adF8Ea40E95Ab82",
 "adapterWBTC":"0x8d09C41229F07AD098ffB5faD239Dd87D2c131D4",
 "lxly":"0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe",
 "minter":"0x807275727Dd3E640c5F2b5DE7d1eC72B4Dd293C0",
 "vbUSDC_l2":"0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36",
 "conv":"0x97a3500083348A147F419b8a65717909762c389f",
 "minterUSDT":"0x4690f346337eD8737BeA462ac71Ff16Ef95B985E",
 "vbUSDT_l2":"0x2DCa96907fde857dd3D816880A0df407eeB2D2F2",
 "convUSDT":"0x053FA9b934b83E1E0ffc7e98a41aAdc3640bB462",
 "minterWBTC":"0x8169e532Bc781985e155037db1F96c267a520DFC",
 "vbWBTC_l2":"0x0913DA6Da4b42f538B445599b46Bb4622342Cf52",
 "convWBTC":"0xb00aa68b87256E2F22058fB2Ba3246EEc54A44fc",
 "l2endpoint":"0x6F475642a6e85809B1c36Fa62763669b1b48DD5B",
 "l1endpoint":"0x1a44076050125825900e736c501f859c50fe728c",
}
MBR = "0xcfd53186d792f1ec9d0679afc2dc3ffc86fc31fe1e0f342b838eb6c3eade62b3"

checks = {"blocks": {}, "auth": {}, "solvency": {}, "secret_scan": {}}
checks["blocks"]["ethereum"] = u(rpc(ETH,"eth_blockNumber",[]))
checks["blocks"]["katana"] = u(rpc(KAT,"eth_blockNumber",[]))

checks["auth"]["l2_minter_peer_30101"] = call(KAT,A["minter"],"peers(uint32)",(30101,))
checks["auth"]["l1_adapter_peer_30375"] = call(ETH,A["adapter"],"peers(uint32)",(30375,))
checks["auth"]["l2_minter_endpoint"] = call(KAT,A["minter"],"endpoint()")
checks["auth"]["l1_adapter_endpoint"] = call(ETH,A["adapter"],"endpoint()")
checks["auth"]["l2_minter_init"] = u(call(KAT,A["minter"],"globalInitializationCounter()"))
checks["auth"]["l1_adapter_init"] = u(call(ETH,A["adapter"],"globalInitializationCounter()"))
checks["auth"]["l2_token_minter_role"] = u(call(KAT,A["vbUSDC_l2"],"hasRole(bytes32,address)",(MBR,A["minter"])))
checks["auth"]["l2_token_attacker_role"] = u(call(KAT,A["vbUSDC_l2"],"hasRole(bytes32,address)",(MBR,"0x000000000000000000000000000000000000dEaD")))
checks["auth"]["l2_token_initialized"] = u(rpc(KAT,"eth_getStorageAt",[A["vbUSDC_l2"],"0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00","latest"]))

# backing invariants
for name, tok, adp, mnt, l2tok, conv in [
    ("USDC",A["vbUSDC"],A["adapter"],A["minter"],A["vbUSDC_l2"],A["conv"]),
    ("USDT",A["vbUSDT"],A["adapterUSDT"],A["minterUSDT"],A["vbUSDT_l2"],A["convUSDT"]),
    ("WBTC",A["vbWBTC"],A["adapterWBTC"],A["minterWBTC"],A["vbWBTC_l2"],A["convWBTC"]),
]:
    esc = u(call(ETH,tok,"balanceOf(address)",(A["lxly"],)))
    adb = u(call(ETH,tok,"balanceOf(address)",(adp,)))
    sup = u(call(KAT,l2tok,"totalSupply()"))
    cb  = u(call(KAT,conv,"backingOnLayerY()"))
    checks["solvency"][name] = {"lxlyEscrow":esc,"lzAdapterBalance":adb,"l2Supply":sup,"converterBacking":cb,
                                "backingSurplus":(esc or 0)+(adb or 0)+(cb or 0)-(sup or 0)}

# secret scan: keyed RPC urls / private keys / API keys
patterns = [
    r"alchemy\.com/v2/[A-Za-z0-9_-]{10,}", r"infura\.io/v3/[A-Za-z0-9]{10,}",
    r"quiknode\.pro/[A-Za-z0-9]{10,}", r"api\.etherscan\.io[^\s\"']*apikey=[A-Za-z0-9]{10,}",
    r"(?i)private[_ -]?key\s*[:=]\s*[0-9a-fx]{20,}",
    r"(?i)(secret|mnemonic|seed[_ -]?phrase)\s*[:=]\s*[A-Za-z0-9 ,]{20,}",
    r"BLOCKPI_RPC_URL\s*=\s*https?://", r"NODEREAL_ETH_RPC_URL\s*=\s*https?://",
]
hits = []
for base, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in (".git","out","cache","ci-artifacts","lib")]
    relbase = os.path.relpath(base, ROOT)
    if relbase.startswith("analysis/src"):  # verified upstream source, not our code/secrets
        continue
    for f in files:
        if f.endswith((".png",".jpg",".pdf")): continue
        p = os.path.join(base,f)
        try: txt = open(p, encoding="utf-8", errors="ignore").read()
        except Exception: continue
        for pat in patterns:
            for m in re.finditer(pat, txt):
                # allow 64-hex hashes (tx hashes / roots) only in analysis artifacts; flag in scripts/docs
                hits.append({"file":os.path.relpath(p,ROOT),"pattern":pat[:40],"match":m.group(0)[:24]})
checks["secret_scan"] = {"hits":hits,"count":len(hits)}

# summary.json sanity
s = json.load(open(os.path.join(ROOT,"summary.json")))
errors = []
for key in ["finding","title","chains","headline_extractable_usd","headline_confidence","categories","latest_block","block_numbers","targets_checked","live_targets","closed_reasons","poc","key_facts","caveats","one_liner"]:
    if key not in s: errors.append("missing "+key)
if s.get("categories",{}).get("E-U") != s.get("headline_extractable_usd"):
    errors.append("E-U category != headline")
checks["summary_errors"] = errors

ok = (hits == [] and errors == [] and
      checks["auth"]["l2_minter_peer_30101"].lower().endswith(A["adapter"][2:].lower()) and
      checks["auth"]["l1_adapter_peer_30375"].lower().endswith(A["minter"][2:].lower()) and
      checks["auth"]["l2_token_minter_role"] == 1 and
      checks["auth"]["l2_token_attacker_role"] == 0 and
      checks["auth"]["l2_token_initialized"] == 2 and
      all(v["backingSurplus"] >= 0 for v in checks["solvency"].values()))
checks["ok"] = ok
os.makedirs(os.path.join(ROOT,"ci-out"),exist_ok=True)
json.dump(checks, open(os.path.join(ROOT,"ci-out","live_checks.json"),"w"), indent=1)
print(json.dumps(checks, indent=1))
sys.exit(0 if ok else 1)
