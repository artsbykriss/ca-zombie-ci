#!/usr/bin/env python3
"""xALPH (PowFi liquid-staking token, Alephium) -- live-state verifier.

Read-only. Uses only PUBLIC keyless Alephium endpoints (no API keys, no secrets).
Re-derives the contract address from the contract id (mirrors DefiLlama's
projects/helper/chain/alephium.js `addressFromContractId`) and re-reads the
backing vs supply, the unissued reserve, the reward collector and the CLMM pool.

Run: python3 analysis/live_state.py
"""
import json, urllib.request, urllib.error, sys

NODE = "https://node.mainnet.alephium.org"
BACKEND = "https://backend.mainnet.alephium.org"
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
E = 10**18

# --- ids (from DefiLlama adapter + alephium/powfi-sdk staking/deployments/.deployments.mainnet.json)
ALPH_ID = "0" * 64
XALPH_ID = "6dc961b59aae53c768fe6f608e6bea30f6747041af3fd800c8c6533766e54f00"
UNSTAKE_VAULT_TEMPLATE_ID = "b8ff9fd3c568d01c3d99c56326560311d53731c3ee47adf65717567a70173000"
REWARD_FEE_COLLECTOR_ID = "6f81c06710522b6e1d396f475e247ff693586ac4d251e50d0b8ae16d55ecb700"
CLMM_FACTORY_ID = "948d87ddf2d6cd751645892cbb4d32b98b617e8a43b2307448b932f27b340c00"


def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = B58[r] + out
    for byte in b:
        if byte == 0: out = "1" + out
        else: break
    return out


def address_from_contract_id(cid_hex: str) -> str:
    raw = bytes.fromhex(cid_hex)
    assert len(raw) == 32
    return b58encode(b"\x03" + raw)


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "xalph-verify/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def state(addr):
    return get(f"{NODE}/contracts/{addr}/state")


def multicall(calls):
    import urllib.request
    data = json.dumps({"calls": calls}).encode()
    req = urllib.request.Request(f"{NODE}/contracts/multicall-contract", data=data,
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "xalph-verify/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def main():
    out = {}
    xalph_addr = address_from_contract_id(XALPH_ID)
    vault_tpl_addr = address_from_contract_id(UNSTAKE_VAULT_TEMPLATE_ID)
    rfc_addr = address_from_contract_id(REWARD_FEE_COLLECTOR_ID)
    out["addresses"] = {"xAlphToken": xalph_addr, "unstakeVaultTemplate": vault_tpl_addr,
                        "rewardFeeCollector": rfc_addr}

    # chain height (Alephium "version" == block height)
    try:
        out["chain_height"] = get(f"{NODE}/blockflow/chain-info?fromGroup=0&toGroup=0")["currentHeight"]
    except Exception as e:
        out["chain_height_error"] = str(e)

    # xALPH token contract
    st = state(xalph_addr)
    out["xAlph_codeHash"] = st["codeHash"]
    imm = st["immFields"]; mut = st["mutFields"]
    out["xAlph_immFields"] = imm
    out["xAlph_mutFields"] = mut
    totalDeposited = int(mut[0]["value"]); totalSupply = int(mut[1]["value"]); lastIdx = int(mut[2]["value"])
    out["backing_attoAlph"] = str(totalDeposited)
    out["circulating_xAlph"] = str(totalSupply)
    out["lastUnstakeVaultIndex"] = lastIdx
    out["rate_alph_per_xalph"] = totalDeposited / totalSupply
    out["over_collateral_pct"] = (totalDeposited / totalSupply - 1) * 100
    out["contract_alph_balance_atto"] = st["asset"]["attoAlphAmount"]
    held_tokens = {t["id"]: t["amount"] for t in st["asset"]["tokens"]}
    out["contract_xAlph_reserve"] = held_tokens.get(XALPH_ID)
    out["reserve_check_1e9_minus_circulating"] = 10**9 * E - totalSupply
    # confirm backing == getTotalDepositedAlph method index 13 (DefiLlama)
    mc = multicall([{"group": 0, "address": xalph_addr, "methodIndex": 13}])
    out["method13_get_xalph_backing"] = mc["results"][0]["returns"][0]["value"]
    out["method13_matches_state_field0"] = (mc["results"][0]["returns"][0]["value"] == str(totalDeposited))

    # unstake-vault template (AlphUnstakeVault) code hash -- used to verify the deployed template
    try:
        out["unstakeVaultTemplate_codeHash"] = state(vault_tpl_addr)["codeHash"]
    except Exception as e:
        out["unstakeVaultTemplate_error"] = str(e)

    # reward fee collector
    try:
        rst = state(rfc_addr)
        out["rewardFeeCollector_codeHash"] = rst["codeHash"]
        out["rewardFeeCollector_mutFields"] = rst["mutFields"]
        out["rewardFeeCollector_alph_atto"] = rst["asset"]["attoAlphAmount"]
    except Exception as e:
        out["rewardFeeCollector_error"] = str(e)

    # token metadata
    try:
        md = urllib.request.Request(f"{BACKEND}/tokens/fungible-metadata",
                                    data=json.dumps([XALPH_ID]).encode(),
                                    headers={"Content-Type": "application/json",
                                             "User-Agent": "xalph-verify/1.0"})
        with urllib.request.urlopen(md, timeout=30) as r:
            out["xAlph_metadata"] = json.load(r)
    except Exception as e:
        out["xAlph_metadata_error"] = str(e)

    # price
    try:
        out["alph_usd"] = get("https://api.coingecko.com/api/v3/simple/price?ids=alephium&vs_currencies=usd")["alephium"]["usd"]
    except Exception as e:
        out["alph_usd_error"] = str(e)

    p = out.get("alph_usd")
    if p:
        out["backing_usd"] = totalDeposited / E * p
        out["contract_held_usd"] = int(st["asset"]["attoAlphAmount"]) / E * p
        out["rewardFeeCollector_usd"] = int(out.get("rewardFeeCollector_alph_atto", "0")) / E * p

    json.dump(out, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
