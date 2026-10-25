#!/usr/bin/env python3
"""final_state.py - freeze live state at a slot for the report."""
import json, sys, os, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as rpc, pda
from solsim import b58enc

POOL="FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
SUSD="susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
CUSDO="BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
POOL_USDC_MAIN="DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ"
POOL_SUSD_VAULT="FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds"
POOL_SUSD_RESERVE="93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK"
PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"

out = {}
slot = rpc.get_slot()["result"]
out["slot"] = slot

def tb(a):
    return rpc.rpc("getTokenAccountBalance", [a, {"commitment":"confirmed"}]).get("result",{}).get("value")

out["pool_usdc_main_vault"] = {"addr": POOL_USDC_MAIN, "bal": tb(POOL_USDC_MAIN)}
out["pool_susd_vault"] = {"addr": POOL_SUSD_VAULT, "bal": tb(POOL_SUSD_VAULT)}
out["pool_susd_reserve"] = {"addr": POOL_SUSD_RESERVE, "bal": tb(POOL_SUSD_RESERVE)}
out["susd_supply"] = rpc.get_token_supply(SUSD).get("result",{}).get("value")
out["cusdo_supply"] = rpc.get_token_supply(CUSDO).get("result",{}).get("value")
out["usdc_supply"] = rpc.get_token_supply(USDC).get("result",{}).get("value")
pv = rpc.get_balance(POOL).get("result",{}).get("value")
out["pool_lamports"] = pv

# DefiLlama prices
try:
    url = "https://coins.llama.fi/prices/current/solana:%s,solana:%s,solana:%s" % (USDC, SUSD, CUSDO)
    req = urllib.request.Request(url, headers={"User-Agent":"audit/1.0"})
    out["prices"] = json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
except Exception as e:
    out["prices"] = {"error": str(e)}

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "final_state.json"),"w"), indent=1)
print(json.dumps(out, indent=1))
