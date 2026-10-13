#!/usr/bin/env python3
"""Check pool tokens for open/public mint functions (E-U drain path). Read-only.
Fetches verified source from Etherscan V2 (Blast) and greps mint/ownership patterns.
"""
import json, os, re, urllib.request, time

API = "https://api.etherscan.io/v2/api"
CHAIN = 81457
key = None
for line in open("/home/heisenberg/CA/.env"):
    if line.startswith("ETHERSCANV2_API_KEY="):
        key = line.split("=", 1)[1].strip().strip('"')

toks = json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/tokens.json"))
meta = toks["meta"]
os.makedirs("/home/heisenberg/CA/monoswap-v3/analysis/token_src", exist_ok=True)

def fetch(addr):
    url = f"{API}?chainid={CHAIN}&module=contract&action=getsourcecode&address={addr}&apikey={key}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

# tokens that are paired against real assets (USDB/WETH/ezETH/USDe/BLAST) - check all pool tokens anyway
order = [
 "0x082e53a6519c5e0ec846d3dc6ee499011601990a",  # KID
 "0x5f49349fb82454d4ca935f3e2e736bd5be556578",  # BLSTE
 "0x837fe561e9c5dfa73f607fda679295dbc2be5e40",  # MUSD
 "0x5fe8534a6f96cb01261bd96e98c17c2c1cab3204",  # BAJA
 "0x5ffd9ebd27f2fcab044c0f0a26a45cb62fa29c06",  # PAC
 "0x73c369f61c90f03eb0dd172e95c90208a28dc5bc",  # OLE
 "0xd43d8adac6a4c7d9aeece7c3151fca8f23752cf8",  # ANDY
 "0x66889602f76e8f7efdc968771f1d2f75bdbb3fde",  # MONO
 "0x818a92bc81aad0053d72ba753fb5bc3d0c5c0923",  # JUICE
 "0x42e12d42b3d6c4a74a88a61063856756ea2db357",  # ORBIT
 "0x2954baf1fc870687cf01bf51aeb48f45fbc89cbc",  # PEWPEW
 "0x67fa2887914fa3729e9eed7630294fe124f417a0",  # YIELD
 "0x667b3b6670c04661b50c28fe74ef6b19d761b146",  # CAPY
 "0xae8172a7597b3bf4d3816c76dd8d9b2535262955",  # TOISE
 "0xbe27241fbd6b24bc1d6acb52cc9b0a1875117133",  # fake USDB
 "0xdc81cceef38691f1f4e35c0b7e487b75dac20aa3",  # bETH
 "0x5fc9befed86ef0f68b2531fcf54c820f0a3ee415",  # MTK
 "0xdc49b835928c1afe8643af9f56686e85818962b1",  # TLAB
 "0x8f2c7415b88d9572fc4d4ae6eb580f9a39296887",  # BANG
 "0x48d9e2f8ed1490dc0337c533d0295d625ae6639f",  # BlastInu
 "0x910d008021f08524cb6c5da8416dc3e80857ab8e",  # SNUS
 "0x84f9d2b2355c4a8e9a7d84106c8f19410dc9e9a3",  # TT
 "0xc5e864da505cc8b60309c817e2447c9e1da14ff5",  # USDX
 "0x4fee793d435c6d2c10c135983bb9d6d4fc7b9bbd",  # USD+
 "0xc56b547e9619aa948a611f2ccfc7d151e3acdd81",  # DWB
 "0xc7d7cdbefa1ec8b70cd78da14b03c0ac0da9ab73",  # BEDO
 "0x006cb3bcb58c1233ddec945250cb231406d655b2",  # Kalax
 "0x0d56cbc480a45ad452d541bebe3a7be51e28f73e",  # LCT
 "0x9fe9991daf6b9a5d79280f48cbb6827d46de2ea4",  # HYPE
 "0xdfdcdbc789b56f99b0d0692d14dbc61906d9deed",  # SSS
 "0x09a14d9c514a8ff7518040ef407a495ba33d7c7d",  # B T C
 "0x3092612bb2340146708f3e79940795fe4e37c398",  # MONO-V2
 "0x2ef6ee4884892b15dfcf53b33ed139fef6141a49",  # WIF
 "0x0369aadf19bc99ccf5b4738df2d3e7d8a93f1990",  # Thruster
 "0xc1c3df952c7e3b4073840254c6b1795573b896f4",  # YIELD2
 "0x08e0948e952063a6396a24fc59554ac476bea66e",  # UPT
 "0x000000daa580e54635a043d2773f2c698593836a",  # OHNO
 "0x0a6e7055c16ee7965031611c2d9cfadb7835479f",
]

out = {}
for addr in order:
    try:
        d = fetch(addr)
        r = d["result"][0]
        name = r.get("ContractName")
        proxy = r.get("Proxy")
        impl = r.get("Implementation") or ""
        src = r.get("SourceCode") or ""
        rec = {"name": name, "proxy": proxy, "impl": impl}
        # find mint functions
        mints = re.findall(r"function\s+(mint\w*)\s*\(([^)]*)\)([^{;]*)", src)
        rec["mint_funcs"] = [{"fn": m[0], "args": m[1].strip()[:120], "mods": m[2].strip()[:120]} for m in mints]
        # owner/admin patterns
        rec["has_onlyOwner"] = "onlyOwner" in src
        rec["has_Ownable"] = "Ownable" in src
        rec["has_roles"] = "AccessControl" in src or "MINTER_ROLE" in src
        out[addr] = rec
        print(f"{addr} {meta.get(addr,{}).get('symbol')}: {name} proxy={proxy} impl={impl[:14]} mints={[(m[0],m[2].strip()[:40]) for m in mints][:4]}")
    except Exception as e:
        out[addr] = {"error": str(e)[:120]}
        print(addr, "ERR", str(e)[:100])
    time.sleep(0.25)

json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/token_mint_check.json", "w"), indent=1)
