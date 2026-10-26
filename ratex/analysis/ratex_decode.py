#!/usr/bin/env python3
"""Generic type-driven decoder for the RateX Anchor IDL (borsh/bytemuck layout)."""
import json, base64, struct
import solrpc as s
try:
    import base58 as b58
except Exception:
    import b58

IDL=json.load(open("idl_b8a8fa.json"))
TYPES={t["name"]:t["type"] for t in IDL["types"]}

def size(tp):
    if isinstance(tp,str):
        return {"pubkey":32,"u8":1,"i8":1,"bool":1,"u16":2,"i16":2,"u32":4,"i32":4,
                "u64":8,"i64":8,"u128":16,"i128":16,"f32":4,"f64":8}.get(tp)
    if "array" in tp: return tp["array"][1]*size(tp["array"][0])
    if "defined" in tp:
        tt=TYPES[tp["defined"]["name"]]
        if tt.get("kind")=="enum": return 1
        return sum(size(f["type"]) for f in tt["fields"])
    if "option" in tp: return 1+size(tp["option"])
    if "vec" in tp: return None
    raise Exception("unknown type "+json.dumps(tp))

def decode(tp, buf, off):
    if isinstance(tp,str):
        if tp=="pubkey": return b58.b58encode(buf[off:off+32]).decode(), off+32
        if tp in ("u8","i8","bool"): return (buf[off]!=0 if tp=="bool" else buf[off]), off+1
        fmts={"u16":"<H","i16":"<h","u32":"<I","i32":"<i","u64":"<Q","i64":"<q",
              "u128":"<QQ","i128":"<qq","f32":"<f","f64":"<d"}
        f=fmts[tp]; sz=size(tp)
        v=struct.unpack_from(f,buf,off)
        if tp in ("u128",): v=(v[0]|(v[1]<<64))
        if tp in ("i128",): v=(v[0]|(v[1]<<64))
        return v, off+sz
    if "array" in tp:
        et,n=tp["array"]; out=[]
        for i in range(n):
            v,off=decode(et,buf,off); out.append(v)
        return out, off
    if "defined" in tp:
        name=tp["defined"]["name"]
        # enums
        if TYPES[name].get("kind")=="enum":
            tag=buf[off]; return {"__variant":tag,"name":TYPES[name]["variants"][tag]["name"]}, off+1
        out={}
        for f in TYPES[name]["fields"]:
            v,off=decode(f["type"],buf,off); out[f["name"]]=v
        return out, off
    if "option" in tp:
        present=buf[off]; off+=1
        if not present: return None, off
        v,off=decode(tp["option"],buf,off); return v, off
    raise Exception("unknown "+json.dumps(tp))

def decode_account(data, type_name, has_disc=True):
    off=8 if has_disc else 0
    return decode({"defined":{"name":type_name}}, data, off)[0]

if __name__=="__main__":
    PROG="RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D"
    accts=json.load(open("ratex_accounts.json"))
    for typ in ["State","YieldMarket","EarnVault","Oracle","MarginMarket"]:
        print("="*20, typ)
        for a in accts[typ]:
            v=s.get_account_info(a["pubkey"], encoding="base64")["result"]["value"]
            d=base64.b64decode(v["data"][0])
            try:
                dec=decode_account(d, typ)
            except Exception as e:
                print("  ",a["pubkey"],"decode err",e); continue
            print("  ",a["pubkey"], "len",len(d))
            if typ=="State":
                print("     admin",dec["admin"],"signer",dec["signer"],"twap_duration",dec["twap_duration"],
                      "keepers",[k for k in dec["keepers"] if k!="11111111111111111111111111111111"],
                      "n_yield",dec["number_of_yield_markets"],"n_margin",dec["number_of_margin_markets"])
            elif typ=="YieldMarket":
                nm=bytes(dec["name"]).split(b"\x00")[0].decode("utf8","replace")
                print("     name",nm,"oracle",dec["oracle"],"status",dec["status"],"mtype",dec["market_type"],
                      "expire_ts",dec["expire_ts"],"mkt_idx",dec["market_index"])
                print("     quote_vault",dec["quote_asset_vault"],"base_vault",dec["base_asset_vault"])
                print("     net_quote",dec["net_quote_amount"],"net_base",dec["net_base_amount"],"implied_rate",dec["implied_rate"],
                      "last_rate",dec["last_rate"],"total_quote_asset",dec["total_quote_asset_amount"])
                print("     pool.liq",dec["pool"]["liquidity"],"pool.sqrt",dec["pool"]["sqrt_price"],
                      "base_mint",dec["pool"]["token_mint_base"],"quote_mint",dec["pool"]["token_mint_quote"])
            elif typ=="EarnVault":
                print("     pt_mint",dec["pt_mint"],"pt_total_supply",dec["pt_total_supply"],
                      "user_ratio",dec["user_ratio"],"net_quote_realized",dec["net_quote_amount_realized"],
                      "mkt_idx",dec["market_index"],"margin_idx",dec["margin_index"])
            elif typ=="Oracle":
                nm=bytes(dec["name"]).split(b"\x00")[0].decode("utf8","replace")
                print("     name",nm,"admin",dec["admin"],"rate",dec["rate"],"market_rate",dec["market_rate"],
                      "last_rate",dec["last_rate"],"ts",dec["ts"],"decimals",dec["decimals"])
            elif typ=="MarginMarket":
                nm=bytes(dec["name"]).split(b"\x00")[0].decode("utf8","replace")
                print("     name",nm,"mint",dec["mint"],"vault",dec["vault"],"deposit_balance",dec["deposit_balance"],
                      "market_index",dec["market_index"],"status",dec["status"])
