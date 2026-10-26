#!/usr/bin/env python3
"""Read-only state dump for Hyperbeat Earn vault set (HyperEVM chain 999).
Uses raw JSON-RPC over the keyless public RPC. No secrets. No tx sent."""
import json, urllib.request, sys, time

RPC = "https://rpc.hyperliquid.xyz/evm"
BLK = int(sys.argv[1]) if len(sys.argv) > 1 else None

# selectors
SEL = {
    "name": "0x06fdde03",
    "symbol": "0x95d89b41",
    "asset": "0x38d52e0f",
    "owner": "0x8da5cb5b",
    "curator": "0xead542f6",
    "totalSupply": "0x18160ddd",
    "totalAssets": "0x01e1d114",
    "getRate": "0x679aefce",
    "decimals": "0x313ce567",
    "lastAnswer": "0xba2e56b2",  # ? verify
    "skim": "0xbc25cf77",
    "deposit1": "0x6e553f65",  # deposit(uint256,address)
    "maxDeposit": "0x402d267d",
    "paused": "0x5c975abb",
    "fee": "0xddca3f43",
}

_id = 0
def rpc(method, params):
    global _id
    _id += 1
    body = json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                d = json.loads(r.read())
            if "error" in d:
                return {"__err__": d["error"]}
            return d.get("result")
        except Exception as e:
            if attempt == 3:
                return {"__exc__": str(e)}
            time.sleep(1.5)

def bn(): return hex(BLK) if BLK else "latest"

def call(addr, sel, extra=""):
    data = sel + extra
    return rpc("eth_call", [{"to": addr, "data": data}, bn()])

def code(addr):
    return rpc("eth_getCode", [addr, bn()])

def dec_str(hexres):
    if not isinstance(hexres, str) or hexres == "0x": return None
    b = bytes.fromhex(hexres[2:])
    if len(b) < 64: return None
    try:
        off = int.from_bytes(b[0:32], "big")
        ln = int.from_bytes(b[off:off+32], "big")
        return b[off+32:off+32+ln].decode("utf-8", "replace")
    except Exception:
        return None

def dec_uint(hexres):
    if not isinstance(hexres, str) or hexres == "0x": return None
    try: return int(hexres, 16)
    except Exception: return None

def dec_addr(hexres):
    if not isinstance(hexres, str) or len(hexres) < 42: return None
    return "0x" + hexres[-40:]

VAULTS = [
    # (address, label, kind)
    ("0x5eEC795d919FA97688Fb9844eeB0072E6B846F9d","Gauntlet USDe Core","morpho"),
    ("0x53A333e51E96FE288bC9aDd7cdC4B1EAD2CD2FfA","Gauntlet USDT0","morpho"),
    ("0x0571362ba5EA9784a97605f57483f865A37dBEAA","Gauntlet uETH","morpho"),
    ("0xd19e3d00f8547f7d108abfd4bbb015486437b487","MEV Capital HYPE","morpho"),
    ("0x4346C98E690c17eFbB999aE8e1dA96B089bE320b","vault5","morpho"),
    ("0xe5ADd96840F0B908ddeB3Bd144C0283Ac5ca7cA0","vault6","morpho"),
    ("0xD3A9Cb7312B9c29113290758f5ADFe12304cd16A","vault7","morpho"),
    ("0x3Bcc0a5a66bB5BdCEEf5dd8a659a4eC75F3834d8","vault8","morpho"),
    ("0x51F64488d03D8B210294dA2BF70D5db0Bc621B0c","Re7 USDT0","morpho"),
    ("0x182b318A8F1c7C92a7884e469442a610B0e69ed2","Re7 HYPE","morpho"),
    ("0x92B518e1cD76dD70D3E20624AEdd7D107F332Cff","Hyperithm HYPE","morpho"),
    ("0x264a06Fd7A7C9E0Bfe75163b475E2A3cc1856578","Gauntlet HYPE","morpho"),
    ("0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3","Gauntlet USDC","morpho"),
    ("0x4851D4891321035729713D43bE1F4bb883Dffd34","MEV USDC","morpho"),
    ("0x441794D6a8F9A3739F5D4E98a728937b33489D29","liquidHYPE","standalone"),
    ("0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42","wVLP","standalone"),
    ("0x81e064d0eB539de7c3170EDF38C1A42CBd752A76","lstHYPE","rate"),
    ("0x5e105266db42f78FA814322Bce7f388B4C2e61eb","hbUSDT","rate"),
    ("0x057ced81348D57Aad579A672d521d7b4396E8a61","hbUSDC","rate"),
    ("0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA","nLP","rate"),
    ("0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03","masterUSD","rate"),
    ("0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29","dnHYPE","rate"),
    ("0x8858A307a85982c2B3CB2AcE1720237f2f09c39B","dnPUMP","rate"),
    ("0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8","hbXAUt","rate"),
    ("0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB","erc4626_a","erc4626"),
    ("0xc061d38903b99aC12713B550C2CB44B221674F94","erc4626_b","erc4626"),
]

out = {"rpc": "<keyless public RPC>", "block": BLK, "vaults": []}
for addr, label, kind in VAULTS:
    v = {"address": addr, "label": label, "kind": kind}
    c = code(addr)
    v["codesize"] = (len(c)-2)//2 if isinstance(c, str) and c.startswith("0x") else None
    v["name"] = dec_str(call(addr, SEL["name"]))
    v["symbol"] = dec_str(call(addr, SEL["symbol"]))
    v["asset"] = dec_addr(call(addr, SEL["asset"]))
    v["owner"] = dec_addr(call(addr, SEL["owner"]))
    v["curator"] = dec_addr(call(addr, SEL["curator"]))
    v["totalSupply"] = dec_uint(call(addr, SEL["totalSupply"]))
    v["totalAssets"] = dec_uint(call(addr, SEL["totalAssets"]))
    v["decimals"] = dec_uint(call(addr, SEL["decimals"]))
    out["vaults"].append(v)
    print(f"{label:20s} {addr} cs={v['codesize']} name={v['name']!r} asset={v['asset']} owner={v['owner']} sup={v['totalSupply']} assets={v['totalAssets']}", flush=True)

json.dump(out, open("/home/heisenberg/CA/hyperbeat-earn/analysis/state_dump.json","w"), indent=1)
print("WROTE state_dump.json")
