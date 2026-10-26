#!/usr/bin/env python3
"""Compute Hyperbeat Earn TVL in USD from live state + DefiLlama prices."""
import json, urllib.request

st=json.load(open("/home/heisenberg/CA/hyperbeat-earn/analysis/state_dump.json"))
pr=json.load(open("/home/heisenberg/CA/hyperbeat-earn/analysis/proxies.json"))

# prices (DefiLlama, hyperliquid:<addr>) — fetched separately; USR/rUSDC treated as $1 stablecoins (flagged)
PRICE={
 "0x5555555555555555555555555555555555555555":77.14440548524593,  # WHYPE
 "0xb88339cb7199b77e23db6e890353e22632ba630f":0.9995957166745453, # USDC
 "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb":0.9988544579867125, # USDT0
 "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34":0.9996428012866799, # USDe
 "0xbe6727b535545c67d5caa73dea54865b92cf7907":2348.798940447733,  # UETH
 "0x9ab96a4668456896d45c301bc3a15cee76aa7b8d":1.0,               # rUSDC (stable, DL no price)
 "0x0ad339d66bf4aed5ce31c64bc37b3244b6394a77":0.07087248103822731, # USR (DL) -- flagged
 "0x9fdbda0a5e284c32744d2f17ee5c74b284993463":80489.37478490862,  # uBTC
 "0xf4d9235269a96aadafc9adae454a0618ebe37949":3983.5605395860257, # XAUt0
}
# underlying decimals per adapter config
UNDERLYING_DEC={
 "0x5eEC795d919FA97688Fb9844eeB0072E6B846F9d":( "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",18),
 "0x53A333e51E96FE288bC9aDd7cdC4B1EAD2CD2FfA":( "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6),
 "0x0571362ba5EA9784a97605f57483f865A37dBEAA":( "0xbe6727b535545c67d5caa73dea54865b92cf7907",18),
 "0xd19e3d00f8547f7d108abfd4bbb015486437b487":( "0x5555555555555555555555555555555555555555",18),
 "0x4346C98E690c17eFbB999aE8e1dA96B089bE320b":( "0x9ab96a4668456896d45c301bc3a15cee76aa7b8d",6),
 "0xe5ADd96840F0B908ddeB3Bd144C0283Ac5ca7cA0":( "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6),
 "0xD3A9Cb7312B9c29113290758f5ADFe12304cd16A":( "0x0ad339d66bf4aed5ce31c64bc37b3244b6394a77",18),
 "0x3Bcc0a5a66bB5BdCEEf5dd8a659a4eC75F3834d8":( "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6),
 "0x51F64488d03D8B210294dA2BF70D5db0Bc621B0c":( "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6),
 "0x182b318A8F1c7C92a7884e469442a610B0e69ed2":( "0x5555555555555555555555555555555555555555",18),
 "0x92B518e1cD76dD70D3E20624AEdd7D107F332Cff":( "0x5555555555555555555555555555555555555555",18),
 "0x264a06Fd7A7C9E0Bfe75163b475E2A3cc1856578":( "0x5555555555555555555555555555555555555555",18),
 "0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3":( "0xb88339cb7199b77e23db6e890353e22632ba630f",6),
 "0x4851D4891321035729713D43bE1F4bb883Dffd34":( "0xb88339cb7199b77e23db6e890353e22632ba630f",6),
 "0x441794D6a8F9A3739F5D4E98a728937b33489D29":( "0x5555555555555555555555555555555555555555",18), # liquidHYPE ~1:1 HYPE
 "0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42":( "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6),
}
RATE_META={  # vault -> (underlying, underlyingDec, shareDec)
 "0x81e064d0eB539de7c3170EDF38C1A42CBd752A76":("0x5555555555555555555555555555555555555555",18,18),
 "0x5e105266db42f78FA814322Bce7f388B4C2e61eb":("0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6,18),
 "0x057ced81348D57Aad579A672d521d7b4396E8a61":("0xb88339cb7199b77e23db6e890353e22632ba630f",6,18),
 "0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA":("0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb",6,6),
 "0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03":("0xb88339cb7199b77e23db6e890353e22632ba630f",6,6),
 "0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29":("0xb88339cb7199b77e23db6e890353e22632ba630f",6,18),
 "0x8858A307a85982c2B3CB2AcE1720237f2f09c39B":("0xb88339cb7199b77e23db6e890353e22632ba630f",6,18),
 "0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8":("0xf4d9235269a96aadafc9adae454a0618ebe37949",6,18),
}
rates=pr["rates"]
total=0.0
rows=[]
for v in st["vaults"]:
    a=v["address"]; k=v["kind"]; ts=v["totalSupply"]; ta=v["totalAssets"]
    usd=None; note=""
    if k=="morpho":
        u,dec=UNDERLYING_DEC[a]; amt=ta/10**dec; usd=amt*PRICE[u]
    elif k=="rate":
        u,udec,sdec=RATE_META[a]; rate=rates[v["label"]]["getRate"]
        amt=ts*rate/1e8/10**sdec; usd=amt*PRICE[u]
    elif k=="erc4626":
        u=v["asset"]; dec=18 if a.lower()=="0x96c6cbb6251ee1c257b2162ca0f39aa5fa44b1fb" else 8
        usd=(ta/10**dec)*PRICE.get(u.lower(),0)
    elif k=="standalone":
        u,dec=UNDERLYING_DEC[a]; usd=(ts/10**18)*PRICE[u]; note="1:1 share"
    if usd is not None:
        total+=usd; rows.append((v["label"],k,round(usd,2)))
rows.sort(key=lambda x:-x[2])
for r in rows: print(f"{r[0]:22s} {r[1]:11s} ${r[2]:,.2f}")
print(f"{'TOTAL':22s} {'':11s} ${total:,.2f}")
json.dump({"total_usd":round(total,2),"rows":rows},open("/home/heisenberg/CA/hyperbeat-earn/analysis/tvl.json","w"),indent=1)
