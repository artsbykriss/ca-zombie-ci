#!/usr/bin/env python3
"""Light read-only sanity checks for the CA2-recon OPEN list.
Public RPCs only. No keys, no transactions. Safe to run in the public CI."""
import json, subprocess, sys, urllib.request, time

def sh(*args, timeout=25):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout.strip()
    except Exception as e:
        return "ERR:" + str(e)

def cast_call(rpc, addr, sig, *params):
    return sh("cast","call",addr,sig,*params,"--rpc-url",rpc)

def cast_int(rpc, addr, sig, *params):
    for _ in range(2):
        out = cast_call(rpc, addr, sig, *params)
        try: return int(out.split()[0])
        except Exception: time.sleep(1)
    return None

def tron_api(path, body):
    last=None
    for _ in range(3):
        try:
            req = urllib.request.Request("https://api.trongrid.io"+path, data=json.dumps(body).encode(),
                                         headers={"Content-Type":"application/json"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except Exception as e:
            last=e; time.sleep(2)
    raise last

PHAROS = "https://infra.originstake.com/pharos/evm"
MONAD  = "https://rpc.monad.xyz"
BSC    = "https://1rpc.io/bnb"

res = {"generated_utc": sh("date","-u","+%FT%TZ"), "read_only": True, "checks": {}}

# --- R25 (Pharos): totalAssets + decimals only (10 calls) ---
vaults = ["0x94f7ebc6ae0819a4b4e231ae6ddaaf9bfd2a1a86",
          "0x1c2bc8b553d9a7e61f7531a3a4bf2162f4569268",
          "0xee26bb0989691735c997dfdc49a4a607f75e190b",
          "0xd0428799fbc35557834d33121ba4472692c8908a",
          "0x6Ce4bc043398Ac40392d1E063328048072b2075d"]
r25 = {"chain_id": sh("cast","chain-id","--rpc-url",PHAROS),
       "block": sh("cast","block-number","--rpc-url",PHAROS), "vaults": []}
for v in vaults:
    d = cast_int(PHAROS, v, "decimals()(uint8)")
    inferred = False
    if d is None and v.lower()=="0xd0428799fbc35557834d33121ba4472692c8908a":
        d, inferred = 6, True   # prior successful read; keep flagged
    r25["vaults"].append({"address": v,
                          "totalAssets_raw": cast_int(PHAROS, v, "totalAssets()(uint256)"),
                          "decimals": d, "decimals_inferred": inferred})
r25["asset"] = "0xC879C018dB60520F4355C26eD1a6D572cdAC1815"
r25["asset_decimals"] = cast_int(PHAROS, "0xC879C018dB60520F4355C26eD1a6D572cdAC1815", "decimals()(uint8)")
res["checks"]["r25_pharos"] = r25

# --- Neverland isolated markets (Monad): reserve lists only ---
never = {"block": sh("cast","block-number","--rpc-url",MONAD), "pools": []}
for p in ["0x690ad251a0d9c8a47cf1bc5e4c0dbd3131ee09d3",
          "0x99cbb76041fb8206e2459085afb98bbc683db527",
          "0xf1a9323d97572a6d673e193d7fe0ecc8b7dcd4b8"]:
    never["pools"].append({"pool": p, "reserves": cast_call(MONAD, p, "getReservesList()(address[])")})
res["checks"]["neverland_monad"] = never

# --- Gambit (BSC) ---
g = {"block": sh("cast","block-number","--rpc-url",BSC),
     "vault": "0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B",
     "usdt": cast_int(BSC,"0x55d398326f99059fF775485246999027B3197955","balanceOf(address)(uint256)","0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B"),
     "wbnb": cast_int(BSC,"0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c","balanceOf(address)(uint256)","0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B"),
     "redeem_1000_usdt": cast_call(BSC,"0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B","getRedemptionAmount(address,uint256)(uint256)","0x55d398326f99059fF775485246999027B3197955","1000000000000000000000")}
res["checks"]["gambit_bsc"] = g

# --- ApolloX (BSC) ---
res["checks"]["apollox_bsc"] = {"block": sh("cast","block-number","--rpc-url",BSC),
    "diamond": "0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0",
    "bnb": sh("cast","balance","0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0","--rpc-url",BSC),
    "code_size": sh("cast","codesize","0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0","--rpc-url",BSC)}

# --- TRON trio ---
trio = {"block": None, "contracts": []}
try:
    trio["block"] = tron_api("/wallet/getnowblock", {})["block_header"]["raw_data"]["number"]
except Exception as e:
    trio["error"] = str(e)
for addr, fn in [("TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR","withdrawTronAll()"),
                 ("TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn","withdraw()"),
                 ("TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW","withdraw()")]:
    item={"address":addr,"fn":fn}
    try:
        acct=tron_api("/wallet/getaccount", {"address":addr,"visible":True})
        item["balance_sun"]=acct.get("balance")
        item["account_name"]=acct.get("account_name")
        cc=tron_api("/wallet/triggerconstantcontract", {"owner_address":"TJRabPrwbZy45sbavfcjinPJC18kjpRTv8",
              "contract_address":addr,"function_selector":fn,"parameter":"","visible":True})
        item["constant_result"]=cc.get("constant_result")
        item["energy_used"]=cc.get("energy_used")
        item["result"]=cc.get("result")
    except Exception as e:
        item["error"]=str(e)
    trio["contracts"].append(item)
res["checks"]["tron_trio"] = trio

json.dump(res, open(sys.argv[1] if len(sys.argv)>1 else "ci-out/live-checks.json","w"), indent=1)
print(json.dumps(res, indent=1))
