#!/usr/bin/env python3
"""decode_proofs.py - decode WithdrawProof/DepositProof and inspect a real resolve_batch_withdraw."""
import json, sys, os, base64, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as rpc, pda
from solsim import b58enc, b58dec

def raw(pk):
    return base64.b64decode(rpc.get_account_info(pk)["result"]["value"]["data"][0])

def dec_wp(pk):
    r = raw(pk); o=8
    bump=r[o]; o+=1
    nonce=struct.unpack_from("<Q",r,o)[0]; o+=8
    frm=b58enc(r[o:o+32]); o+=32
    amount=struct.unpack_from("<Q",r,o)[0]; o+=8
    mint=b58enc(r[o:o+32]); o+=32
    batch=struct.unpack_from("<Q",r,o)[0]; o+=8
    uv=b58enc(r[o:o+32]); o+=32
    return {"pk":pk,"bump":bump,"nonce":nonce,"from":frm,"amount":amount,"mint":mint,"batchId":batch,"userUsdcVault":uv}

for pk in ["pzWrVqajs4UPwoxSgTcAqQFLHimH14a7G2SEuUp8wPW"]:
    try:
        print(json.dumps(dec_wp(pk)))
    except Exception as e:
        print(pk, "decode err", e)

# check whether userUsdcVault == ATA(from, USDC)
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
d = dec_wp("pzWrVqajs4UPwoxSgTcAqQFLHimH14a7G2SEuUp8wPW")
print("expected ATA(from,USDC):", pda.ata(d["from"], USDC))
print("proof userUsdcVault     :", d["userUsdcVault"])

# inspect a real resolve_batch_withdraw
tx = rpc.get_transaction("5LtGCfGs2qcYyvyXTvdZwEvxU965xgZLKayApjfN54tznxFog4eQvsTeXK1fWcLKuknpNmdmUBjPh2wuH1AzDeu2", encoding="json").get("result")
if tx:
    keys = list(tx["transaction"]["message"]["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    keys += list(la.get("writable") or []) + list(la.get("readonly") or [])
    print("\nresolve sig slot", tx["slot"], "err", tx["meta"]["err"])
    print("keys:", json.dumps(keys, indent=1)[:2500])
    print("logs:")
    for l in tx["meta"]["logMessages"]:
        if "log:" in l or "invoke" in l: print("  ", l)
    pre = {b["accountIndex"]: (keys[b["accountIndex"]], b["mint"], int(b["uiTokenAmount"]["amount"])) for b in (tx["meta"].get("preTokenBalances") or [])}
    post = {b["accountIndex"]: (keys[b["accountIndex"]], b["mint"], int(b["uiTokenAmount"]["amount"])) for b in (tx["meta"].get("postTokenBalances") or [])}
    print("token deltas:")
    for i in sorted(set(pre)|set(post)):
        if pre.get(i)!=post.get(i):
            print("   idx",i, (post.get(i) or pre.get(i))[0], (post.get(i) or pre.get(i))[1], pre.get(i,[None,None,0])[2], "->", post.get(i,[None,None,0])[2])
