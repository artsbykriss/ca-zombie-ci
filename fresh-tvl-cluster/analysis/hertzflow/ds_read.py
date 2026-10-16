#!/usr/bin/env python3
"""HertzFlow DataStore reader — read-only, keyless public RPC. Computes GMX-v2-style keys
per the protocol's own SDK (configs/dataStore.ts) and eth_calls the DataStore."""
import json, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
from Crypto.Hash import keccak
from eth_abi import encode

RPC = "https://bsc-rpc.publicnode.com"
DS_B = "0xc244A37A17CE7aa14E1BDD73f6a047Ed6B56f6B8"
DS_A = "0x92A898D6c26fB69B532c0b78aAd0cD196972dcF0"

def k(b: bytes) -> str:
    h = keccak.new(digest_bits=256); h.update(b); return "0x" + h.hexdigest()

def hashString(s: str) -> str:
    return k(encode(["string"], [s]))

def hashData(types, values) -> str:
    vals = []
    for t, v in zip(types, values):
        if t == "bytes32" and isinstance(v, str):
            vals.append(bytes.fromhex(v[2:]))
        else:
            vals.append(v)
    return k(encode(types, vals))

S = lambda s: hashString(s)

# single keys
K = {n: S(n) for n in [
 "MAX_CALLBACK_GAS_LIMIT","MIN_COLLATERAL_USD","MIN_COLLATERAL_FACTOR","MIN_POSITION_SIZE_USD","MAX_LEVERAGE",
 "FUNDING_INCREASE_FACTOR_PER_SECOND","FUNDING_DECREASE_FACTOR_PER_SECOND","MIN_FUNDING_FACTOR_PER_SECOND",
 "MAX_FUNDING_FACTOR_PER_SECOND","THRESHOLD_FOR_STABLE_FUNDING","THRESHOLD_FOR_DECREASE_FUNDING",
 "IS_MARKET_DISABLED","PRICE_FEED","MAX_POSITION_IMPACT_FACTOR","MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS",
 "POSITION_IMPACT_FACTOR","POSITION_IMPACT_EXPONENT_FACTOR","POSITION_IMPACT_POOL_AMOUNT","MIN_POSITION_IMPACT_POOL_AMOUNT",
 "POSITION_IMPACT_POOL_DISTRIBUTION_RATE","SWAP_IMPACT_FACTOR","SWAP_IMPACT_EXPONENT_FACTOR","SWAP_IMPACT_POOL_AMOUNT",
 "FUNDING_FACTOR","FUNDING_EXPONENT_FACTOR","POSITION_FEE_FACTOR","SWAP_FEE_FACTOR","ATOMIC_SWAP_FEE_FACTOR",
 "DEPOSIT_FEE_FACTOR","WITHDRAWAL_FEE_FACTOR","MAX_PNL_FACTOR","MAX_PNL_FACTOR_FOR_WITHDRAWALS","MAX_PNL_FACTOR_FOR_DEPOSITS",
 "MAX_PNL_FACTOR_FOR_TRADERS","MAX_OPEN_INTEREST","OPEN_INTEREST","OPEN_INTEREST_IN_TOKENS","POOL_AMOUNT","MAX_POOL_AMOUNT",
 "MAX_POOL_USD_FOR_DEPOSIT","RESERVE_FACTOR","OPEN_INTEREST_RESERVE_FACTOR","BORROWING_FACTOR","BORROWING_EXPONENT_FACTOR",
 "VIRTUAL_INVENTORY_FOR_POSITIONS","VIRTUAL_INVENTORY_FOR_SWAPS","VIRTUAL_TOKEN_ID","VIRTUAL_MARKET_ID","MAX_PROFIT_FACTOR",
 "MAX_LENDABLE_IMPACT_FACTOR","MAX_LENDABLE_IMPACT_USD","LOSS_REBATE_FACTOR","CLAIMABLE_COLLATERAL_DELAY",
]}

def call(to, data):
    req = {"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
    r = subprocess.run(["curl","-s","-m","25","-X","POST",RPC,"-H","Content-Type: application/json","-d",json.dumps(req)],capture_output=True,text=True)
    try:
        return json.loads(r.stdout).get("result")
    except Exception:
        return None

SEL_UINT = "0xbd02d0f5"   # getUint(bytes32)
SEL_INT  = "0xdc97d962"   # getInt(bytes32)
SEL_ADDR = "0x21f8a721"   # getAddress(bytes32)
SEL_BOOL = "0x7ae1cfca"   # getBool(bytes32)

def enc_key(sel, key):
    return sel + key[2:]

def get_uint(ds, key):  return call(ds, enc_key(SEL_UINT, key))
def get_addr(ds, key):  return call(ds, enc_key(SEL_ADDR, key))
def get_bool(ds, key):  return call(ds, enc_key(SEL_BOOL, key))
def get_int(ds, key):   return call(ds, enc_key(SEL_INT, key))

if __name__ == "__main__":
    print("sel check via cast:")
    for sig in ["getUint(bytes32)","getInt(bytes32)","getAddress(bytes32)","getBool(bytes32)"]:
        out = subprocess.run(["cast","sig",sig],capture_output=True,text=True).stdout.strip()
        print(" ", sig, "=", out)
