#!/usr/bin/env python3
"""Live state dump for key LeetSwap pairs/factories (read-only)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc as R

OUT = os.path.dirname(os.path.abspath(__file__))

# factory -> list of focus pairs
JOBS = {
    "op_bnb": {
        "factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
        "pairs": ["0x3e5b8c9e1c98a457b68a4337897a8f6020725e18",
                  "0xf9e34e8dae9767df2a7f99713ea3c5c20b149adb",
                  "0x18d4b3a71bda8758c56b5dcc1874915b16b9df20",
                  "0x7efb0e7fb43051e879659136bcbdf8676c4d0271"],
        "tokens": {"WBNB": "0x4200000000000000000000000000000000000006",
                   "T_f2f4": "0xf2f41fe10d53e15ba34e410987eb0f986ec7509f",
                   "T_d9db": "0xd9dbb44682be930002e4fcfcb48869c89822a8f7",
                   "T_7ad7": "0x7ad7d1466208ce3c55f8aa6c5e810c24e4e91b4e",
                   "T_3a55": "0x3a5573ed3c2af1fe3f91befb2d2f3d3b11193c2e"},
    },
    "manta": {
        "factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
        "pairs": ["0xf5f8a569483663e9f7227d16e4ec21de9e729f93",
                  "0xfedd2f73e128fc52ee717ed666bef9bedbf57d22",
                  "0xead80cbf96cff47f8f12672885a9b901b5623b5e"],
        "tokens": {"WETH": "0x0dc808adce2099a9f62aa87d9670745aba741746",
                   "T_e650": "0xe650686a3b474c01fbb5ad3b07ecc44093356090",
                   "T_a23d": "0xa23da6b48e11ad98b0f5bcdddca026fb15692201",
                   "T_3652": "0x3652da207868e2e4d3a2814d063d270c9d076ce7"},
    },
}


def main():
    out = {}
    for chain, j in JOBS.items():
        blk = R.block_number(chain)
        res = {"block": blk, "factory": j["factory"]}
        f = j["factory"]
        for label, sel in [("allPairsLength", "0x574f2ba3"), ("feeTo", "0x017e7e58"),
                           ("owner", "0x8da5cb5b"), ("paused", "0x5c975abb")]:
            try:
                r = R.call(chain, f, sel)
                if sel == "0x574f2ba3":
                    res[label] = R.dec_uint(R.words(r)[0])
                elif sel == "0x5c975abb":
                    res[label] = bool(R.dec_uint(R.words(r)[0]))
                else:
                    res[label] = R.dec_addr(R.words(r)[0])
            except Exception as e:
                res[label] = f"ERR:{str(e)[:60]}"
        # token info
        toks = {}
        for tk, addr in j["tokens"].items():
            info = {"addr": addr}
            try:
                info["symbol"] = R.symbol(chain, addr)
                info["name"] = R.name(chain, addr)
                info["decimals"] = R.decimals(chain, addr)
                info["totalSupply"] = R.total_supply(chain, addr)
            except Exception as e:
                info["err"] = str(e)[:80]
            toks[tk] = info
        res["tokens"] = toks
        pairs = []
        for p in j["pairs"]:
            row = {"pair": p}
            try:
                t0 = R.dec_addr(R.words(R.call(chain, p, "0x0dfe1681"))[0])
                t1 = R.dec_addr(R.words(R.call(chain, p, "0xd21220a7"))[0])
                r0, r1, ts = R.reserves(chain, p)
                b0 = R.balance_of(chain, t0, p)
                b1 = R.balance_of(chain, t1, p)
                sup = R.total_supply(chain, p)
                row.update({"t0": t0, "t1": t1, "reserve0": r0, "reserve1": r1,
                            "balance0": b0, "balance1": b1, "lp_totalSupply": sup,
                            "excess0": b0 - r0, "excess1": b1 - r1,
                            "excess0_usd_hint": (b0 - r0) > 0, "excess1_usd_hint": (b1 - r1) > 0})
                try:
                    row["factory"] = R.dec_addr(R.words(R.call(chain, p, "0xc45a0155"))[0])
                except Exception:
                    row["factory"] = None
            except Exception as e:
                row["err"] = str(e)[:100]
            pairs.append(row)
            print(chain, p, json.dumps({k: v for k, v in row.items() if k in
                  ("reserve0", "reserve1", "balance0", "balance1", "excess0", "excess1", "lp_totalSupply")}), flush=True)
        res["pairs"] = pairs
        out[chain] = res
    json.dump(out, open(os.path.join(OUT, "live-state-keypairs.json"), "w"), indent=1)
    print("saved live-state-keypairs.json")


if __name__ == "__main__":
    main()
