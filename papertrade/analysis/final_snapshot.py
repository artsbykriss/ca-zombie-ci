#!/usr/bin/env python3
"""Final atomic snapshot of Papertrade live state (read-only).
Writes analysis/final_snapshot.json. Public keyless RPC + optional Etherscan (env key, never written)."""
import json, time, urllib.request, os, sys
from Crypto.Hash import keccak

U = os.environ.get("HYPEREVM_RPC", "https://rpc.hyperliquid.xyz/evm")
EX = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
BATCH = "0x233Ff29b239abc1D7748605dA9b205C3e008626E"
EIP1967 = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
MASK96 = 2**96 - 1
MASK128 = 2**128 - 1

def rpc(m, p, retries=3):
    b = json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
    for i in range(retries):
        try:
            r = urllib.request.Request(U, data=b, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(r, timeout=25).read())
        except Exception as e:
            if i == retries-1: raise
            time.sleep(1)

def call(to, data, block="latest"):
    j = rpc("eth_call", [{"to":to,"data":data}, block])
    return j.get("result") or j

def storage(addr, slot, block):
    return rpc("eth_getStorageAt", [addr, slot, block])["result"]

def slot_hash(mid, base):
    key = bytes.fromhex(format(mid,'064x') + format(base,'064x'))
    k = keccak.new(digest_bits=256); k.update(key)
    return "0x" + k.hexdigest()

def main():
    bn = int(rpc("eth_blockNumber", [])["result"], 16)
    blk = hex(bn)
    out = {"block": bn, "rpc": U.replace("https://","https://<rpc>/") if False else "public"}

    # impl slots
    out["impls"] = {}
    for name, addr in (("exchange",EX),("oracle",ORACLE),("batchExecutor",BATCH)):
        out["impls"][name] = "0x" + storage(addr, EIP1967, blk)[-40:]

    # views
    views = {
        "tradingPaused":"0x53e23e2e","lpBankrollAvailable":"0x0cdd5fc4","totalLockedMargin":"0x01ad056f",
        "totalQueued":"0x53ac4b66","totalBalances":"0xa69a2ad1","oracle":"0x7dc0d1d0",
        "pauseGuardian":"0x24a3d622","marketKeeper":"0x21f55a6c","owner":"0x8da5cb5b",
        "nextPositionId":"0x899346c7","liquidationFeeRate":"0x5fb3b1b5","winFeeRate":"0x48ee5e08",
        "devFeeAccumulator":"0x7d004aeb","stakerFeeAccumulator":"0xafdf6702",
    }
    out["views_raw"] = {}
    for k, sel in views.items():
        out["views_raw"][k] = call(EX, sel, blk)
    out["views"] = {
        "tradingPaused": int(out["views_raw"]["tradingPaused"],16),
        "lpBankrollAvailable_usd": int(out["views_raw"]["lpBankrollAvailable"],16)/1e18,
        "totalLockedMargin_usd": int(out["views_raw"]["totalLockedMargin"],16)/1e18,
        "totalQueued_usd": int(out["views_raw"]["totalQueued"],16)/1e18,
        "totalBalances_usd": int(out["views_raw"]["totalBalances"],16)/1e18,
        "oracle": "0x"+out["views_raw"]["oracle"][-40:],
        "pauseGuardian": "0x"+out["views_raw"]["pauseGuardian"][-40:],
        "marketKeeper": "0x"+out["views_raw"]["marketKeeper"][-40:],
        "owner": "0x"+out["views_raw"]["owner"][-40:],
        "nextPositionId": int(out["views_raw"]["nextPositionId"],16),
        "liquidationFeeRate": int(out["views_raw"]["liquidationFeeRate"],16)/1e18,
        "winFeeRate": int(out["views_raw"]["winFeeRate"],16)/1e18,
        "devFeeAccumulator_usd": int(out["views_raw"]["devFeeAccumulator"],16)/1e18,
        "stakerFeeAccumulator_usd": int(out["views_raw"]["stakerFeeAccumulator"],16)/1e18,
    }
    out["exchange_slot_0x58"] = "0x" + storage(EX, hex(0x58), blk)[-40:]

    # oracle BBO (getBBO 0xfb466481) for assets 0,1,2
    out["bbo"] = {}
    for asset in (0,1,2):
        r = call(ORACLE, "0xfb466481"+format(asset,'064x'), blk)
        if isinstance(r,str) and len(r) >= 130:
            bid = int(r[2:66],16); ask = int(r[66:130],16)
            scale = {0:10.0,1:100.0}.get(asset, 1.0)
            out["bbo"][str(asset)] = {"bid_raw":bid,"ask_raw":ask,"bid":bid/scale,"ask":ask/scale,
                                      "mid":(bid+ask)/2/scale,"spread_bp":(ask-bid)/((bid+ask)/2)*10000}
    out["oracle_mid"] = {str(a): call(ORACLE, "0xc0182669"+format(a,'064x'), blk) for a in (0,1)}

    # OI / caps storage
    out["markets"] = {}
    for mid, name in ((0,"BTC"),(1,"ETH")):
        h = slot_hash(mid, 0x24)
        s0 = int(storage(EX, h, blk),16)
        s1 = int(storage(EX, "0x"+format(int(h,16)+1,'064x'), blk),16)
        rec = {
            "priceScale": s0 >> 192,
            "longOI": (s0 & MASK96)/1e18,
            "shortOI": ((s0>>96) & MASK96)/1e18,
            "longCap": (s1 & MASK128)/1e18,
            "shortCap": ((s1>>128) & MASK128)/1e18,
        }
        rec["longHeadroom"] = rec["longCap"]-rec["longOI"]
        rec["shortHeadroom"] = rec["shortCap"]-rec["shortOI"]
        px = out["bbo"].get(str(mid),{}).get("mid",0)
        rec["px"] = px
        rec["longHeadroom_usd"] = rec["longHeadroom"]*px
        rec["shortHeadroom_usd"] = rec["shortHeadroom"]*px
        out["markets"][name] = rec

    # instruments config (instruments(uint32)) — selector found via brute-force history: 0x314155f6? use known selector file value
    # prior work decoded instruments via selector; we record raw for 0/1 using selector 0x314155f6 (unverified) -> skip if revert
    out["instruments_raw"] = {}
    for sel in ("0x314155f6","0x31415612","0x31415806","0x31415908","0x31415918"):
        r = call(EX, sel+format(0,'064x'), blk)
        if isinstance(r,str) and len(r)>2:
            out["instruments_raw"][sel] = r

    # HyperCore spot state for the Exchange (public API)
    try:
        body = json.dumps({"type":"spotClearinghouseState","user":EX}).encode()
        req = urllib.request.Request("https://api.hyperliquid.xyz/info", data=body,
                                     headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        hc = json.loads(urllib.request.urlopen(req, timeout=25).read())
        out["hypercore_spot"] = hc
    except Exception as e:
        out["hypercore_spot_err"] = str(e)[:120]

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "final_snapshot.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps({k: out[k] for k in ("block","impls","views","bbo","markets")}, indent=1))

if __name__ == "__main__":
    main()
