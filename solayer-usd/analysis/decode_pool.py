#!/usr/bin/env python3
"""Decode Pool + OpenedenInfo + SusdSupplyOffset + SunsetInfo + proof accounts with exact IDL layout."""
import json, base64, sys, os, struct
HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "recon1c.json")))
by = {a["pubkey"]: a for a in D["program_accounts"]}
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

def raw(pk): return base64.b64decode(by[pk]["data_b64"])

POOL = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
r = raw(POOL)
o = 8
def pk_():
    global o
    v = b58enc(r[o:o+32]); o += 32; return v
def u8_():
    global o
    v = r[o]; o += 1; return v
def u64_():
    global o
    v = struct.unpack_from("<Q", r, o)[0]; o += 8; return v
def i64_():
    global o
    v = struct.unpack_from("<q", r, o)[0]; o += 8; return v
def u16_():
    global o
    v = struct.unpack_from("<H", r, o)[0]; o += 2; return v

pool = {}
pool["disc"] = r[:8].hex()
pool["bump"] = u8_()
pool["manager"] = pk_()
pool["operator"] = pk_()
pool["rateAuthority"] = pk_()
pool["fee_numerator"] = u64_()
pool["fee_denominator"] = u64_()
pool["fee_recipient"] = pk_()
pool["poolCreationTs"] = i64_()
pool["lastFeeCollectionTs"] = i64_()
pool["usdcMint"] = pk_()
pool["poolUsdcMainVault"] = pk_()
pool["susdMint"] = pk_()
pool["poolSusdVault"] = pk_()
pool["batchDepositStatus"] = u8_()
pool["currentDepositId"] = u64_()
pool["currentDepositUsdcAmount"] = u64_()
pool["batchDepositRemainingUsdcAmount"] = u64_()
pool["batchWithdrawStatus"] = u8_()
pool["currentWithdrawId"] = u64_()
pool["currentWithdrawSusdAmount"] = u64_()
pool["batchWithdrawRemainingSusdAmount"] = u64_()
pool["openedenInfo"] = pk_()
pool["bytes_consumed"] = o
print("POOL decoded:")
print(json.dumps(pool, indent=1))
print("consumed", o, "of", len(r))

# OpenedenInfo
OI = "9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc"
r = raw(OI); o = 8
oi = {"disc": r[:8].hex(), "bump": r[o]}
o += 1
for f in ["rwaTokenMint","rwaTokenVault","rwaTokenVaultAuthority","usdcVault","usdcVaultAuthority",
          "poolRwaTokenMainVault","poolRwaTokenAccountForDeposit","poolUsdcTokenAccountForWithdraw",
          "transferHookProgram","extraMetasAccount","pauseAccount"]:
    oi[f] = b58enc(r[o:o+32]); o += 32
for f in ["allowedDriftNumerator","allowedDriftDenominator","depositRwaTokenUsdcRatioNumerator",
          "depositRwaTokenUsdcRatioDenominator","withdrawUsdcSusdTokenRatioNumerator",
          "withdrawUsdcSusdTokenRatioDenominator"]:
    oi[f] = struct.unpack_from("<Q", r, o)[0]; o += 8
oi["consumed"] = o
print("\nOPENEDEN INFO:"); print(json.dumps(oi, indent=1))

# SusdSupplyOffset
SO = "5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
r = raw(SO)
print("\nSusdSupplyOffset:", {"disc": r[:8].hex(), "amount": struct.unpack_from("<Q", r, 8)[0]})

# SunsetInfo
SI = "EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"
r = raw(SI)
print("SunsetInfo raw:", r.hex(), "len", len(r))

# a couple proofs
for pk in ["mzESBcvxnoHYHduycb2GJhUjLBAAdxFS5dhN8X7Mt12","pzWrVqajs4UPwoxSgTcAqQFLHimH14a7G2SEuUp8wPW",
           "3U2chkhnisqEoPT8WToTqRSSNKZuNJ45NJJxCNVc6ZHX"]:
    r = raw(pk)
    print("\nproof", pk, "len", len(r), "hex", r.hex())

json.dump({"pool": pool, "openeden": oi, "slot": D["slot"]},
          open(os.path.join(HERE, "pool_decoded.json"), "w"), indent=1)
