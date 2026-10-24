#!/usr/bin/env python3
"""Read-only: enumerate ALL Fluid vaults on BSC (T1..T4) with configs + live totals.
Retries across keyless public BSC RPCs. No transactions signed/sent."""
import json, sys, time
from web3 import Web3

RPCS = ["https://bsc-rpc.publicnode.com", "https://bsc-dataseed.binance.org", "https://1rpc.io/bnb",
        "https://bsc-dataseed1.defibit.io", "https://binance.llamarpc.com"]
RESOLVER = "0xA5C3E16523eeeDDcC34706b0E6bE88b4c6EA95cC"

CV = "(address,address,address,address,address,address,address,address,(address,address),(address,address),uint256,uint256,bytes32,bytes32,bytes32,bytes32)"
CFG = "(uint16,uint16,uint16,uint16,uint16,uint16,uint16,uint16,address,uint256,uint256,address,uint256)"
EXR = "(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,int256,int256,int256,int256)"
TOT = "(uint256,uint256,uint256,uint256,uint256,uint256)"
LIM = "(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
VST = "(uint256,int256,uint256,uint256,uint256,uint256,(uint256,int256,uint256,uint256,uint256,uint256,int256))"
USD = "(bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
OUT = "(" + ",".join(["address", "bool", "bool", CV, CFG, EXR, TOT, LIM, VST, USD, USD]) + ")"
ABI = [{"name": "getVaultEntireData", "type": "function", "stateMutability": "view",
        "inputs": [{"name": "vault_", "type": "address"}], "outputs": [{"name": "vaultData_", "type": OUT}]},
       {"name": "getAllVaultsAddresses", "type": "function", "stateMutability": "view",
        "inputs": [], "outputs": [{"name": "", "type": "address[]"}]}]

def connect():
    for r in RPCS:
        try:
            w = Web3(Web3.HTTPProvider(r, request_kwargs={"timeout": 45}))
            if w.is_connected():
                w.eth.block_number
                return w, r
        except Exception:
            continue
    raise SystemExit("no rpc")

w3, RPC = connect()
print("using", RPC)
block = w3.eth.block_number
c = w3.eth.contract(address=Web3.to_checksum_address(RESOLVER), abi=ABI)
vaults = c.functions.getAllVaultsAddresses().call(block_identifier=block)

erc = [{"name": "symbol", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "string"}]},
       {"name": "decimals", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint8"}]}]
meta = {}
def get_meta(tok):
    tok = Web3.to_checksum_address(tok)
    if tok in meta: return meta[tok]
    if tok.lower() == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee":
        meta[tok] = {"sym": "BNB", "dec": 18}; return meta[tok]
    try:
        cc = w3.eth.contract(address=tok, abi=erc)
        meta[tok] = {"sym": cc.functions.symbol().call(), "dec": cc.functions.decimals().call()}
    except Exception as e:
        meta[tok] = {"sym": "?", "dec": 0, "err": str(e)[:60]}
    return meta[tok]

WS = [w3]
for _r in RPCS:
    try:
        _w = Web3(Web3.HTTPProvider(_r, request_kwargs={"timeout": 45}))
        _w.eth.block_number
        WS.append(_w)
    except Exception:
        pass

def call_retry(vault):
    last = None
    for attempt in range(15):
        w = WS[attempt % len(WS)]
        try:
            c = w.eth.contract(address=Web3.to_checksum_address(RESOLVER), abi=ABI)
            return c.functions.getVaultEntireData(Web3.to_checksum_address(vault)).call(block_identifier=block)
        except Exception as e:
            last = e; time.sleep(0.5)
    raise last

rows = []
for v in vaults:
    try:
        d = call_retry(v)
    except Exception as e:
        rows.append({"vault": v, "error": str(e)[:150]}); continue
    cv, cfg, exr, tot, lim, vst, usd, ubd = d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10]
    sup = cv[8][0]; bor = cv[9][0]
    sm = get_meta(sup); bm = get_meta(bor)
    rows.append({
        "vault": v, "vaultId": cv[11], "vaultType": cv[12],
        "supplyToken": sup, "supplySym": sm["sym"], "supplyDec": sm["dec"], "supplyToken1": cv[8][1],
        "borrowToken": bor, "borrowSym": bm["sym"], "borrowDec": bm["dec"], "borrowToken1": cv[9][1],
        "collateralFactor": cfg[2], "liquidationThreshold": cfg[3], "liquidationMaxLimit": cfg[4],
        "withdrawalGap": cfg[5], "liquidationPenalty": cfg[6], "borrowFee": cfg[7],
        "oracle": cfg[8], "oraclePriceOperate": str(cfg[9]), "oraclePriceLiquidate": str(cfg[10]),
        "rebalancer": cfg[11],
        "totalSupplyVault": str(tot[0]), "totalBorrowVault": str(tot[1]),
        "totalSupplyLiquidityOrDex": str(tot[2]), "totalBorrowLiquidityOrDex": str(tot[3]),
        "absorbedSupply": str(tot[4]), "absorbedBorrow": str(tot[5]),
        "withdrawLimit": str(lim[0]), "withdrawableUntilLimit": str(lim[1]), "withdrawable": str(lim[2]),
        "borrowLimit": str(lim[3]), "borrowableUntilLimit": str(lim[4]), "borrowable": str(lim[5]),
        "borrowLimitUtilization": str(lim[6]), "minimumBorrowing": str(lim[7]),
        "totalPositions": vst[0],
        "liquidityUserSupplyData": {"supply": str(usd[1]), "baseWithdrawalLimit": str(usd[6]), "withdrawable": str(usd[8])},
        "liquidityUserBorrowData": {"borrow": str(ubd[1]), "borrowLimit": str(ubd[2]), "maxBorrowLimit": str(ubd[7]), "borrowable": str(ubd[9])},
    })
    time.sleep(0.1)

def clean(o):
    if isinstance(o, bytes): return "0x" + o.hex()
    if isinstance(o, dict): return {k: clean(v) for k, v in o.items()}
    if isinstance(o, list): return [clean(v) for v in o]
    return o

out = {"block": block, "rpc": RPC, "resolver": RESOLVER, "totalVaults": len(vaults), "vaults": clean(rows)}
json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else "vaults.json", "w"), indent=1)
print("block", block, "vaults", len(vaults), "errors", sum(1 for r in rows if "error" in r))
