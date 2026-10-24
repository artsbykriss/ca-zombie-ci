#!/usr/bin/env python3
"""Read-only: compute per-vault USD supply/borrow + the DEX pool exposure for the
Fluid (Venus Flux) deployment on BSC. Keyless RPC, no tx."""
import json, sys
from web3 import Web3

RPC = "https://bsc-rpc.publicnode.com"
RESOLVER = "0xA5C3E16523eeeDDcC34706b0E6bE88b4c6EA95cC"
DEX_RES = "0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0"
LIQ_RES = "0xca13A15de31235A37134B4717021C35A3CF25C60"

# prices USD (DefiLlama, fetched separately); stablecoins = 1
P = {"BNB": 744.71, "WBNB": 744.71, "ETH": 2660.0, "wBETH": 2659.83, "BTCB": None,
     "USDC": 1.0, "USDT": 1.0, "syrupUSDT": 1.1457, "wstUSR": 0.0813, "U": 0.999, "asBNB": 791.45}

v = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "vaults.json"))
tot_sup = tot_bor = 0.0
print("=== per-vault USD (collateral @ ORACLE price, debt @ market) ===")
for r in v["vaults"]:
    sup = int(r["totalSupplyVault"]) / 10**r["supplyDec"]
    bor = int(r["totalBorrowVault"]) / 10**r["borrowDec"]
    # oracle price in debt-token units per supply token
    op = int(r["oraclePriceOperate"]) / 10 ** (27 + r["borrowDec"] - r["supplyDec"])
    sup_usd = sup * op * (P.get(r["borrowSym"], 1) or 1)
    bor_usd = bor * (P.get(r["borrowSym"], 1) or 1)
    tot_sup += sup_usd; tot_bor += bor_usd
    print(f"{r['supplySym']+'/'+r['borrowSym']:>18s} sup={sup:>20.6f} (${sup_usd:>12,.2f} @oracle)  bor={bor:>20.6f} (${bor_usd:>12,.2f})  CF={r['collateralFactor']}  oracle={r['oracle'][:10]}")
print(f"TOTAL supply(USD@oracle) = ${tot_sup:,.2f}   TOTAL borrow(USD) = ${tot_bor:,.2f}")

print("\n=== global Liquidity-layer token data ===")
abi = [{"name": "listedTokens", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address[]"}]},
       {"name": "getOverallTokensData", "type": "function", "stateMutability": "view",
        "inputs": [{"type": "address[]"}], "outputs": [{"type": "(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,(address,uint256,uint256,uint256,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256)))[]"}]}]
w3 = Web3(Web3.HTTPProvider(RPC, request_kwargs={"timeout": 60}))
blk = v["block"]
c = w3.eth.contract(address=Web3.to_checksum_address(LIQ_RES), abi=abi)
toks = c.functions.listedTokens().call(block_identifier=blk)
data = c.functions.getOverallTokensData(toks).call(block_identifier=blk)
erc = [{"name": "symbol", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "string"}]},
       {"name": "decimals", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint8"}]}]
for t, d in zip(toks, data):
    if t.lower() == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee":
        sym, dec = "BNB", 18
    else:
        cc = w3.eth.contract(address=Web3.to_checksum_address(t), abi=erc)
        try: sym, dec = cc.functions.symbol().call(block_identifier=blk), cc.functions.decimals().call(block_identifier=blk)
        except Exception: sym, dec = "?", 18
    ts = int(d[12]) / 10**dec; tb = int(d[13]) / 10**dec
    px = P.get(sym, 1) or 1
    print(f"{sym:>12s} supply={ts:>18.4f} (${ts*px:>14,.2f})  borrow={tb:>18.4f} (${tb*px:>14,.2f})  maxUtil={d[15]}")
