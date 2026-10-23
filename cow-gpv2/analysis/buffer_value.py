#!/usr/bin/env python3
"""Value the GPv2Settlement buffer at a pinned block using DefiLlama prices. Read-only."""
import json, os, urllib.request, time

R = os.environ["NODEREAL_ETH_RPC_URL"]
S = "0x9008d19f58aabd9ed0d60971565aa8510560ab41"
BLOCK = 26_253_971

TOK = {
 "WETH":"0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","DAI":"0x6B175474E89094C44Da98b954EedeAC495271d0F",
 "USDC":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","USDT":"0xdAC17F958D2ee523a2206206994597C13D831ec7",
 "USDe":"0x4c9EDD5852cd905f086C759E8383e09bff1E68B3","USDS":"0xdC035D45d973E3EC169d2276DDab16f1e407384F",
 "sDAI":"0x83F20F44975D03b1b09e64809B757c47f942BEeA","COW":"0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB",
 "GNO":"0x6810e776880C02933D47DB1b9fc05908e5386b96","WBTC":"0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
 "EURS":"0xdB25f211AB05b1c97D595516F45794528a807ad8","XAUt":"0x68749665FF8D2d112Fa859AA293F07A622782F38",
 "SLP":"0xCC8Fa225D80b9c7D42F96e9570156c65D6cAA25","imBTC":"0x3212b29E33587A00FB1C83346f5dBFA69A458923",
 "wstETH":"0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0","stETH":"0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84",
 "LINK":"0x514910771AF9Ca656af840dff83E8264EcF986CA","UNI":"0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
 "AAVE":"0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9","CRV":"0xD533a949740bb3306d119CC777fa900bA034cd52",
 "BAL":"0xba100000625a3754423978a60c9317c58a424e3D","MKR":"0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
 "LDO":"0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32","SHIB":"0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
 "PEPE":"0x6982508145454Ce325dDbE47a25d4ec3d2311933","cbETH":"0xBe9895146f7AF43049ca1c1AE358B0541Ea49704",
 "rETH":"0xae78736Cd615f374D3085123A210448E74Fc6393","FRAX":"0x853d955aCEf822Db058eb8505911ED77F175b99e",
 "LUSD":"0x5f98805A4E8be255a32880FDeC7F6728C6568bA0","TUSD":"0x0000000000085d4780B73119b644AE5ecd22b376",
 "PYUSD":"0x6c3ea9036406852006290770BEdFcAbA0e23A0e8","CVX":"0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B",
 "COMP":"0xc00e94Cb662C3520282E6f5717214004A7f26888",
}
def pad(a): return a[2:].rjust(64,"0")
def batch(calls):
    out=[]
    for i in range(0,len(calls),40):
        req=urllib.request.Request(R,data=json.dumps(calls[i:i+40]).encode(),headers={"Content-Type":"application/json"})
        for a in range(4):
            try: out+=json.load(urllib.request.urlopen(req,timeout=90)); break
            except Exception:
                if a==3: raise
                time.sleep(2)
        time.sleep(0.05)
    return out

res={c["id"]:c.get("result") for c in batch(
    [{"jsonrpc":"2.0","id":k,"method":"eth_call","params":[{"to":t,"data":"0x70a08231"+pad(S)},hex(BLOCK)]} for k,t in TOK.items()])}
dec={c["id"]:c.get("result") for c in batch(
    [{"jsonrpc":"2.0","id":k,"method":"eth_call","params":[{"to":t,"data":"0x313ce567"},hex(BLOCK)]} for k,t in TOK.items()])}

keys=",".join("ethereum:"+t for t in TOK.values())
prices=json.load(urllib.request.urlopen("https://coins.llama.fi/prices/current/"+keys,timeout=60))["coins"]

total=0.0; rowsout=[]
for k,t in TOK.items():
    raw=res.get(k); d=dec.get(k)
    if not raw or raw=="0x": continue
    bal=int(raw,16)
    if bal==0: continue
    dd=int(d,16) if d and d!="0x" else 18
    pr=prices.get("ethereum:"+t,{}).get("price")
    amt=bal/10**dd
    usd=amt*(pr or 0)
    total+=usd
    rowsout.append({"sym":k,"token":t,"raw":bal,"decimals":dd,"amount":amt,"price":pr,"usd":round(usd,2)})
    print(f"{k:7} raw={bal:<28} amt={amt:<20.8f} px={pr} usd={usd:.2f}")
print(f"TOTAL priced = ${total:,.2f}")
json.dump({"block":BLOCK,"settlement":S,"total_usd":round(total,2),"tokens":rowsout},
          open("/home/heisenberg/CA/cow-gpv2/analysis/buffer_valuation.json","w"),indent=1)
print("wrote analysis/buffer_valuation.json")
