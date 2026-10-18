import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import llrpc as rpc

MARKETS = {
    "ethereum": {
        "chain_id": 1,
        "factory": "0x8f6B56ec5DdF1f2691a1059f1D3cd97AC9EAB0Bd",
        "markets": [
            {"id": 0, "collateral": "0xb45ad160634c528cc3d2926d9807104fa3157305", "vault": "0x2b5a321c3cb1f33e1abecd047c2649d0b4c47eba", "controller": "0xc77d97cf01737eb7ace46cab7cd9f60ec51a40c0", "amm": "0x0bf6f64b741164c26023f97faaea8e02453c2744", "oracle": "0x0117ba42d18eac940b469f81ed0a135ca23a1003", "created_block": 25529593},
            {"id": 1, "collateral": "0xcf62f905562626cfcdd2261162a51fd02fc9c5b6", "vault": "0x3da0f110079012387f47c6fc6e878f10262e300a", "controller": "0x3cd4d86a2c65e57ce4b4121b67e2d2224ba41bbe", "amm": "0x63791be4985992580f84dae105bcc0e15c282d1f", "oracle": "0xea1b981203dbccaeb1f2f00081a426b6308c8c2b", "created_block": 25529781},
            {"id": 2, "collateral": "0x80ac24aa929eaf5013f6436cda2a7ba190f5cc0b", "vault": "0xd0d347e14fbf1872affeacb49d0b8b7182680e6c", "controller": "0x2fb54c8eae57767a9a509a395b9c4fa0702e2675", "amm": "0x0b7e89ea00d57454f28198c4bf7575c269e72971", "oracle": "0xb799322c447a53d82629e085182ddfe65eeda840", "created_block": 25603281},
            {"id": 3, "collateral": "0xe5f130253ff137f9917c0107659a4c5262abf6b0", "vault": "0xcb6e2c3d9dba8fe6245b2c969320f2485dfce2fd", "controller": "0xfd85e847cdd2549f213e276e4b57b0690169f043", "amm": "0xc8c469e3964707295302299dbbf88f13eb9c40a3", "oracle": "0xa44b313a8d3fedc6f024ec25cfbf2e15487c1951", "created_block": 25688031},
            {"id": 4, "collateral": "0xed785af60bed688baa8990cd5c4166221599a441", "vault": "0xfe33bb533bb51e8b36a3afd160bdc4f80adcca40", "controller": "0x4922995d8cbf9e1f368b2ee521bd2fa2f49eadb1", "amm": "0xa305ff5fe27b8194447700b34f522d79df4400e5", "oracle": "0xf9f3beac3bd194b86114a76790d7f2d5fe1b6078", "created_block": 26147713},
        ],
    },
    "optimism": {
        "chain_id": 10,
        "factory": "0x5F94073E3f51c1FFf92ffc6b4B06b7Af193B3640",
        "markets": [
            {"id": 0, "collateral": "0x1f32b1c2345538c0c6f582fcb022739c4a194ebb", "vault": "0x638ef78599c404a90545c6cfb460efcff8a019f7", "controller": "0x745422bf49f3f6e4a8e12e4abd19339e7910f8c9", "amm": "0xf621ae3e7cc2bcb4098cd0c2185b4649589626d0", "oracle": "0x0deb4aafab8d171fd211b9dfa2b966ae1dc8e679", "created_block": 152707737},
            {"id": 1, "collateral": "0x68f180fcce6836688e9084f035309e29bf0a2095", "vault": "0xff9a3085ed83da377a94e32dd4745bb57411ea24", "controller": "0x9fc15ac3ef97093832f49b7997a58e29b49c56de", "amm": "0x86372d2844acb9f1fed32b80aebbe3cc50124c72", "oracle": "0x63284d83e542cc774c52394073ef6875c3ce03bd", "created_block": 152739328},
            {"id": 2, "collateral": "0x1f32b1c2345538c0c6f582fcb022739c4a194ebb", "vault": "0xab504518c7b83ed6c67718877c4ffc2b52b29436", "controller": "0xb5ec7a3d591877a66be4f3eafdc4205e98a1bcaa", "amm": "0x1c6056540690bae459a6dc6efadda148fe43c9dc", "oracle": "0x7d81eda6f594dfd82faf39f377366c67abe2b315", "created_block": 152739379},
        ],
    },
}

SEL = {
    "total_debt": "0x31dc3ca8", "admin_fees": "0x1b1800e3", "available_balance": "0x092314da",
    "n_loans": "0x6cce39be", "liquidation_discount": "0x627d2b83", "loan_discount": "0x5449b9cb",
    "borrow_cap": "0x670ff237", "admin_percentage": "0x1059fcbd", "vault": "0xfbfa77cf", "controller": "0xf77c4791",
    "amm": "0x2a943945", "collateral_token": "0x2621db2f", "borrowed_token": "0x765337b6",
    "c_version": "0x54fd4d50",
    "totalAssets": "0x01e1d114", "totalSupply": "0x18160ddd", "maxSupply": "0xd5abeb01",
    "asset": "0x38d52e0f",
    "fee": "0xddca3f43", "rate": "0x2c4e722e", "active_band": "0x8f8654c5",
    "price_oracle": "0x86fc88d3", "get_p": "0xf2388acb", "A": "0xf446c1d0",
    "get_rate_mul": "0x095a0fc6", "get_base_price": "0xa7db79a5", "min_band": "0xca72a821",
    "max_band": "0xaaa615fc", "amm_admin": "0xf851a440", "oracle_contract": "0x5ea0e01b",
    "price": "0xa035b1fe", "decimals": "0x313ce567", "symbol": "0x95d89b41",
    "name": "0x06fdde03", "token": "0xfc0c546a", "pool": "0x16f0115b",
    "bal": "0x70a08231",
}


def u(res):
    if res is None or res == "0x":
        return None
    try:
        return int(res, 16)
    except Exception:
        return None


def s(res):
    if not res or res == "0x":
        return None
    b = bytes.fromhex(res[2:])
    if len(b) >= 64:
        ln = int.from_bytes(b[32:64], "big")
        return b[64:64 + ln].decode("utf-8", "replace")
    return b.rstrip(b"\x00").decode("utf-8", "replace")


def pad(addr):
    return addr.lower()[2:].rjust(64, "0")


def fetch_market(url, m, blk):
    calls = []  # (label, to, data, kind)
    def add(label, to, data, kind="u"):
        calls.append((label, to, data, kind))

    for k in ["total_debt", "admin_fees", "available_balance", "n_loans",
              "liquidation_discount", "loan_discount", "borrow_cap",
              "admin_percentage", "vault", "amm", "collateral_token",
              "borrowed_token", "c_version"]:
        add("controller." + k, m["controller"], SEL[k], "s" if k == "c_version" else ("addr" if k in ("vault", "amm", "collateral_token", "borrowed_token") else "u"))
    for k in ["totalAssets", "totalSupply", "maxSupply", "asset"]:
        add("vault." + k, m["vault"], SEL[k], "addr" if k == "asset" else "u")
    for k in ["fee", "rate", "active_band", "price_oracle", "get_p", "A",
              "get_rate_mul", "get_base_price", "min_band", "max_band",
              "amm_admin", "oracle_contract"]:
        add("amm." + k, m["amm"], SEL[k], "addr" if k in ("amm_admin", "oracle_contract") else "u")
    add("oracle.price", m["oracle"], SEL["price"])
    add("collateral.symbol", m["collateral"], SEL["symbol"], "s")
    add("collateral.decimals", m["collateral"], SEL["decimals"])
    add("collateral.totalSupply", m["collateral"], SEL["totalSupply"])
    add("borrowed.symbol", m["borrowed"], SEL["symbol"], "s")
    add("borrowed.decimals", m["borrowed"], SEL["decimals"])
    add("borrowed.totalSupply", m["borrowed"], SEL["totalSupply"])
    for k in ["pool", "token"]:
        add("oracle." + k, m["oracle"], SEL[k], "addr")
    res = rpc.batch_chunked(url, [(to, data, hex(blk)) for _, to, data, _ in calls], 8)
    e = dict(m)
    for (label, to, data, kind), r in zip(calls, res):
        if kind == "s":
            e[label] = s(r)
        elif kind == "addr":
            e[label] = ("0x" + r[-40:]) if r and len(r) >= 42 else None
        else:
            e[label] = u(r)
    return e


def main():
    out = {}
    only = os.environ.get("ONLY_CHAIN")
    for chain, cfg in MARKETS.items():
        if only and chain != only:
            continue
        url = rpc.eth_url() if chain == "ethereum" else rpc.op_url()
        blk = rpc.block_number(url)
        rec = {"chain": chain, "chain_id": cfg["chain_id"], "block": blk, "factory": cfg["factory"], "markets": []}
        rec["factory_market_count"] = u(rpc.call(url, cfg["factory"], "0xfd775c78", hex(blk)))
        for m0 in cfg["markets"]:
            m = dict(m0)
            if chain == "ethereum":
                m["borrowed"] = "0xf939e0a03fb07f59a73314e73794be0e57ac1b4e"
            else:
                m["borrowed"] = "0x4200000000000000000000000000000000000006" if m["id"] == 0 else "0x0b2c639c533813f4aa9d7837caf62653d097ff85"
            # derive addresses authoritatively from the vault, not the event words
            derived = rpc.batch_chunked(url, [
                (m["vault"], SEL["amm"], hex(blk)),
                (m["vault"], SEL["controller"], hex(blk)),
                (m["vault"], SEL["collateral_token"], hex(blk)),
                (m["vault"], SEL["borrowed_token"], hex(blk)),
            ], 4)
            m["amm"] = "0x" + (derived[0] or "")[-40:]
            m["controller"] = "0x" + (derived[1] or "")[-40:]
            m["collateral"] = "0x" + (derived[2] or "")[-40:]
            m["borrowed"] = "0x" + (derived[3] or "")[-40:]
            try:
                oc = rpc.call(url, m["amm"], SEL["oracle_contract"], hex(blk))
                m["oracle"] = "0x" + oc[-40:]
            except Exception:
                pass
            e = fetch_market(url, m, blk)
            # controller balances of borrowed token and vault shares
            extra = [
                ("controller.borrowed_balance", m["borrowed"], SEL["bal"] + pad(m["controller"])),
                ("amm.borrowed_balance", m["borrowed"], SEL["bal"] + pad(m["amm"])),
                ("amm.collateral_balance", m["collateral"], SEL["bal"] + pad(m["amm"])),
                ("vault.total_supply_check", m["vault"], SEL["totalSupply"]),
            ]
            res = rpc.batch_chunked(url, [(t, d, hex(blk)) for _, t, d in extra], 8)
            for (lab, _, _), r in zip(extra, res):
                e[lab] = u(r)
            rec["markets"].append(e)
            print(chain, m["id"], e.get("collateral.symbol"), "->", e.get("borrowed.symbol"),
                  "| debt", e.get("controller.total_debt"), "avail", e.get("controller.available_balance"),
                  "| tv", e.get("vault.totalAssets"), "nloans", e.get("controller.n_loans"),
                  "| fee", e.get("amm.fee"), "price", e.get("oracle.price"), "A", e.get("amm.A"))
        out[chain] = rec
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "markets_live.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
