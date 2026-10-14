#!/usr/bin/env python3
"""Identify Eddy-deployed contracts via zetascan API (read-only, no secrets)."""
import json, urllib.request, time

UA = {"User-Agent": "Mozilla/5.0"}

def get(url, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            return json.load(urllib.request.urlopen(req, timeout=30))
        except Exception as e:
            if i == tries - 1:
                return {"__err__": str(e)}
            time.sleep(1.5)

def addr_info(a):
    d = get(f"https://zetascan.com/api/v2/addresses/{a}")
    return {
        "addr": a,
        "name": d.get("name"),
        "is_contract": d.get("is_contract"),
        "verified": d.get("is_verified"),
        "coin_balance": d.get("coin_balance"),
        "creator": d.get("creator_address_hash"),
        "impl": d.get("implementations"),
        "proxy": d.get("proxy_type"),
    }

def token_balances(a):
    d = get(f"https://zetascan.com/api/v2/addresses/{a}/token-balances")
    out = []
    if isinstance(d, list):
        for it in d:
            tok = it.get("token", {}) or {}
            out.append({"token": tok.get("address_hash") or tok.get("address"),
                        "symbol": tok.get("symbol"), "name": tok.get("name"),
                        "value": it.get("value"), "decimals": tok.get("decimals"),
                        "exchange_rate": tok.get("exchange_rate")})
    return out

if __name__ == "__main__":
    contracts = [
        "0x23ce409ea60c3d75827d04d9db3d52f3af62e44d",
        "0x36cfb6dcd6926dfb749dc8e4b28efc73f3e6fae3",
        "0xb9dc665610cf5109ce23abbdaac315b41fa094c1",
        "0xa8168dc495ed61e70f5c1941e2860050ab902cef",
        "0x358e2cfc0e16444ba7d3164bbeeb6bea7472c559",
        "0x2d4672ffb292221b06d6e706518dea5e0512782b",
        "0x3c85e0ca1001f085a3e58d55a0d76e2e8b0a33f9",
        "0x910966e1c0bc9fd74f499723c19ff9799fe258a5",
        "0x9a04f26bebfcfd0e8b9a07bfdc1b3df6a7edc20d",
        "0x934d9d70768b4d601d701d1f51f090e10ef13633",
        "0x42beca156ded89762773b99cc77a685394ef4036",
        "0x3649c03c472b698213926543456e9c21081e529d",
        "0xd9c6f8a9538fd8361de01984edd69b80425d1b5e",
        "0x113d1e0fa690746b6bd86cadcea712f22cfeac05",
        "0x1553f87907fe13b8756feaea99b361825fd74a56",
        "0x399bbd10176f75aa238d2439daf0b8f22203f217",
        "0xc459ab4ac46ce53a30d4c4b6f49176989483b2cf",
        "0xf0a3f93ed1b126142e61423f9546bf1323ff82df",
        "0x19cacb4c0a7fc25598cc44564ed0eca01249fc31",
        # stableswap pools from DefiLlama adapter comment
        "0x448028804461e8e5a8877c228F3adFd58c3Da6B6",
        "0x01a9cd602c6c3f05ea9a3a55184c2181bd43e4b8",
        "0xee1629de70afaf3ae3592a9d6d859949750aa697",
        "0x89cb3fA2A7910A268e9f7F619108aFADBD7587c4",
        # AMM factory
        "0x9fd96203f7b22bCF72d9DCb40ff98302376cE09c",
        # farm factory owner EOA
        "0xfca0392567d5eb77681843b2608de9c625f57948",
    ]
    out = []
    for c in contracts:
        info = addr_info(c)
        tb = token_balances(c)
        info["token_balances"] = tb
        out.append(info)
        print(f"{c} | {info['name']} | contract={info['is_contract']} verified={info['verified']} | native={info['coin_balance']}")
        for t in tb:
            print("    ", t["symbol"], t["value"], t.get("decimals"))
    json.dump(out, open("contracts_map.json", "w"), indent=1)
    print("saved contracts_map.json")
