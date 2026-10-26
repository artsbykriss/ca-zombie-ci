#!/usr/bin/env python3
"""Enumerate + decode Omnipair live state (read-only, keyless RPC)."""
import base64
import json
import os
import sys
import time

import solrpc as s
import omni as O

HERE = os.path.dirname(os.path.abspath(__file__))


def get_all():
    r = s.get_program_accounts(O.PID)
    slot = r["result"][0] if False else None
    accts = r["result"]
    return accts


def main():
    out = {}
    accts = get_all()
    pairs, positions, authorities, rates = [], [], [], []
    for a in accts:
        raw = O.acct_data(a)
        d = raw[:8]
        if d == O.DISC_PAIR:
            p = O.decode_pair(raw)
            p["pubkey"] = a["pubkey"]
            pairs.append(p)
        elif d == O.DISC_POSITION:
            p = O.decode_position(raw)
            p["pubkey"] = a["pubkey"]
            positions.append(p)
        elif d == O.DISC_AUTHORITY:
            au = O.decode_authority(raw)
            au["pubkey"] = a["pubkey"]
            authorities.append(au)
        elif d == O.DISC_RATE_MODEL:
            rm = O.decode_rate_model(raw)
            rm["pubkey"] = a["pubkey"]
            rates.append(rm)
    slot = s.get_slot()["result"]
    out["slot"] = slot
    out["n_pairs"] = len(pairs)
    out["n_positions"] = len(positions)
    out["n_authorities"] = len(authorities)
    out["n_rate_models"] = len(rates)
    out["pairs"] = pairs
    out["positions"] = positions
    out["authorities"] = authorities
    out["rate_models"] = rates

    # derive vaults and read token balances
    token_accts = {}
    vault_map = {}
    for p in pairs:
        pk = p["pubkey"]
        vb = p["vault_bumps"]
        for side, mint, bump in (
            ("reserve0", p["token0"], vb["reserve0"]),
            ("reserve1", p["token1"], vb["reserve1"]),
            ("collateral0", p["token0"], vb["collateral0"]),
            ("collateral1", p["token1"], vb["collateral1"]),
        ):
            seed = O.RESERVE_VAULT_SEED if side.startswith("reserve") else O.COLLATERAL_VAULT_SEED
            addr = O.b58enc(O.create_pda([seed, O.b58dec(pk), O.b58dec(mint), bytes([bump])]))
            vault_map[f"{pk}:{side}"] = addr
            token_accts[addr] = None
    keys = list(token_accts)
    balances = {}
    for i in range(0, len(keys), 100):
        chunk = keys[i:i + 100]
        vals = s.get_multiple_accounts(chunk, encoding="jsonParsed")
        for k, v in zip(chunk, vals["result"]["value"]):
            if v is None:
                balances[k] = None
                continue
            try:
                pi = v["data"]["parsed"]["info"]
                balances[k] = {
                    "mint": pi.get("mint"),
                    "owner": pi.get("owner"),
                    "amount": pi["tokenAmount"]["amount"],
                    "decimals": pi["tokenAmount"]["decimals"],
                    "tokenProgram": v["owner"],
                }
            except Exception as e:  # noqa: BLE001
                balances[k] = {"raw_owner": v["owner"], "err": str(e)}
    out["vault_map"] = vault_map
    out["vault_balances"] = balances
    json.dump(out, open(os.path.join(HERE, "live_state.json"), "w"), indent=1)
    print("slot", slot, "pairs", len(pairs), "positions", len(positions),
          "authorities", len(authorities))
    for au in authorities:
        print("AUTHORITY", json.dumps(au))
    return out


if __name__ == "__main__":
    main()
