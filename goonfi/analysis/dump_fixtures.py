#!/usr/bin/env python3
"""Dump GoonFi fixtures (live mainnet accounts) into poc/fixtures/accounts.json.
Read-only RPC reads. Keyless endpoints only in the file."""
import json, os, sys, base64, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
FIX = os.path.join(OUT, "..", "poc", "fixtures")

ACCS = {
    # GoonFi program + state
    "prog_goonfi": "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE",
    "goonfi_pool": "GMCJvYGf5Ex2ARiMquaBDqU6iKM8uiEQkB8jCnoNfHpC",           # WSOL/USDC (incident market)
    "goonfi_vault_wsol": "8ncU5YW1CQwvr4gs7buH57bW58e86TDau4STrCJBuz8z",
    "goonfi_vault_usdc": "EunHLeqeJKvxnCPQSytnBP63HJVk2fbHceiKKpngyAo8",
    "goonfi_oracle": "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3",
    "goonfi_global": "BNrK9LpEn65QA4TyBLVSMdngW3XHj3xLfFPwGdCBv8wV",           # 719000B global state
    "goonfi_const13": "J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv",
    # second market (USDC/JupUSD-ish) for binding tests
    "goonfi_pool2": "Daopjqyt5qZZ111x7MDbWbxtf72cdNEUnCECzZ7hVpbp",
    "goonfi_vault2_a": "J7rc6e6jkQFQ4hWJ9c3rShgmeSFDjJ38HW1fa6jV9JV6",
    "goonfi_vault2_b": "mbbgY8AQttyUZHoJSHrt3Rg4cz81tB6LKqvccPicuFe",
    "goonfi_oracle2": "FggV5dLyuFC5SMqxhpF64xkHu1rXiTUP3CwufV5ZSam4",
    # extra oracle (different price) for the unbound-oracle test
    "oracle_alt": "GHjEJbxWcT55xWCucjSRUJAxxVXD8wXsLUAToBWTUPBa",       # HYPE oracle ($82.07)
    "oracle_pengu": "Hy5crMonHfzjdUUVtMo8YsWVES3mACNRQuMLDo8gWyxb",     # PENGU oracle ($0.0076)
    "oracle_cbbtc": "12jcZpK8ggSk2ppnKsbqno6zqbqTMS2rq2jAxNj3moKs",     # cbBTC oracle ($82,288)
    "oracle_stale_wsol": "9BKWr8SXzLkFRv1A3izFmf1cPGyJmPqzrmzzPyuq7Jdf", # stale WSOL/USDC oracle ($83.6, 7mo old)
    # mints
    "mint_wsol": "So11111111111111111111111111111111111111112",
    "mint_usdc": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "mint_6p6x": "6p6xgHyF7AeE6TZkSmFsko444wqoP15icUSqi2jfGiPN",
    # programs / sysvars
    "oracle_prog": "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu",
    "token_prog": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
    "ata_prog": "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
    "vote_account": "J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv",
}


def main():
    os.makedirs(FIX, exist_ok=True)
    fx = {}
    for name, addr in ACCS.items():
        r = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
        v = r.get("result", {}).get("value")
        if not v:
            print("MISSING", name, addr); continue
        fx[name] = {
            "address": addr, "owner": v["owner"], "lamports": v["lamports"],
            "executable": v["executable"], "data_b64": v["data"][0],
        }
        print(f"{name:22s} {addr[:12]}.. owner={v['owner'][:12]}.. lamports={v['lamports']} len={len(base64.b64decode(v['data'][0]))}")
        time.sleep(0.15)
    with open(os.path.join(FIX, "accounts.json"), "w") as f:
        json.dump(fx, f, indent=1)
    # program ELFs
    for name, elf_src in [("goonfi.elf", os.path.join(OUT, "progdata_v2.elf")),
                          ("dijkbk.elf", os.path.join(OUT, "dijkbk.elf"))]:
        with open(os.path.join(FIX, name), "wb") as f:
            f.write(open(elf_src, "rb").read())
        print("wrote", name)


if __name__ == "__main__":
    main()
