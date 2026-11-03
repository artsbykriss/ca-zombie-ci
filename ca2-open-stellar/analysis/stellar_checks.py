#!/usr/bin/env python3
"""
Read-only on-chain checks for the Stellar "Evergreen" / Sentora USDC share vault
CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM.

- Fetches the contract instance + wasm from public Soroban RPC (getLedgerEntries).
- Reads live state (total_assets, total_supply, balances, admin/operator, subaccounts).
- Runs read-only simulateTransaction (record mode) against key call paths to record
  exactly which addresses must authorise each operation.
- Writes a machine-readable JSON to stdout (and optionally to a file).

No keys, no signing, no transaction submission. Public RPC only.
"""
import base64
import hashlib
import json
import sys

import requests
from stellar_sdk import SorobanServer, TransactionBuilder, Account, Network, xdr as X, scval
from stellar_sdk.strkey import StrKey

RPC = "https://mainnet.sorobanrpc.com"
PASSPHRASE = Network.PUBLIC_NETWORK_PASSPHRASE

VAULT = "CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM"
WASM_HASH = "3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12"
USDC = "CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75"
ADMIN = "GCE5LGZ6ADXMKHD6FRYLBRNOBUY4LAZFXJACFSBBN6AOSFFTRJPJZWFH"
OPERATOR = "GABFK2HTLWNOZDR7EHA2EB4AGYHRC6SWMAORUE64DWUNIVZVCMYEYFH2"
WALLET_SUB = "GDLVR5MPWXWQNN5TSHIYZ3EVI47YVJ7JOEGODGU54USF24VNBNJ32XJQ"
# Unprivileged, non-admin account that has interacted with the vault (0 shares, 0 USDC).
ATTACKER = "GDIMN2XLD2U6ZKDLRDMZD7E5XYZDSMI52N5WEV7MN6NOMBJAC56MCPUK"

S = SorobanServer(RPC)


def scval_to_py(v):
    t = v.type
    if t == X.SCValType.SCV_VOID:
        return None
    if t == X.SCValType.SCV_BOOL:
        return bool(v.b)
    if t == X.SCValType.SCV_U32:
        return v.u32.uint32
    if t == X.SCValType.SCV_I32:
        return v.i32.int32
    if t == X.SCValType.SCV_U64:
        return v.u64.uint64
    if t == X.SCValType.SCV_I64:
        return v.i64.int64
    if t == X.SCValType.SCV_U128:
        return (v.u128.hi.int64 << 64) + v.u128.lo.uint64
    if t == X.SCValType.SCV_I128:
        return (v.i128.hi.int64 << 64) + v.i128.lo.uint64
    if t == X.SCValType.SCV_BYTES:
        b = v.bytes.sc_bytes
        return b.hex() if isinstance(b, (bytes, bytearray)) else str(b)
    if t == X.SCValType.SCV_STRING:
        return v.str.sc_string.decode(errors="replace")
    if t == X.SCValType.SCV_SYMBOL:
        return v.sym.sc_symbol.decode(errors="replace")
    if t == X.SCValType.SCV_VEC:
        return [scval_to_py(x) for x in v.vec.sc_vec]
    if t == X.SCValType.SCV_MAP:
        return {str(scval_to_py(x.key)): scval_to_py(x.val) for x in v.map.sc_map}
    if t == X.SCValType.SCV_ADDRESS:
        a = v.address
        if a.type == X.SCAddressType.SC_ADDRESS_TYPE_CONTRACT:
            return "C:" + StrKey.encode_contract(bytes(a.contract_id.contract_id.hash))
        if a.type == X.SCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
            return "G:" + StrKey.encode_ed25519_public_key(
                bytes(a.account_id.account_id.ed25519.uint256)
            )
        return f"addr_type_{a.type}"
    return {"scval_type": str(t)}


def ledger_key_instance(cid):
    addr = X.SCAddress(
        type=X.SCAddressType.SC_ADDRESS_TYPE_CONTRACT,
        contract_id=X.ContractID(X.Hash(StrKey.decode_contract(cid))),
    )
    key = X.SCVal(type=X.SCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE)
    lk = X.LedgerKey(
        type=X.LedgerEntryType.CONTRACT_DATA,
        contract_data=X.LedgerKeyContractData(
            contract=addr, key=key, durability=X.ContractDataDurability.PERSISTENT
        ),
    )
    return X.LedgerKey.to_xdr(lk)


def rpc(method, params):
    r = requests.post(
        RPC, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=60
    )
    r.raise_for_status()
    j = r.json()
    if "error" in j:
        raise RuntimeError(j["error"])
    return j["result"]


def get_instance(cid):
    res = rpc("getLedgerEntries", {"keys": [ledger_key_instance(cid)]})
    e = res["entries"][0]
    d = X.LedgerEntryData.from_xdr(e["xdr"])
    ci = d.contract_data.val.instance
    storage = {}
    for item in ci.storage.sc_map:
        k = scval_to_py(item.key)
        storage[str(k)] = scval_to_py(item.val)
    ex = ci.executable
    wasm = bytes(ex.wasm_hash.hash).hex() if ex.type == X.ContractExecutableType.CONTRACT_EXECUTABLE_WASM else None
    return {
        "last_modified_ledger": e["lastModifiedLedgerSeq"],
        "live_until_ledger": e.get("liveUntilLedgerSeq"),
        "wasm_hash": wasm,
        "storage": storage,
        "latest_ledger": res.get("latestLedger"),
    }


def get_wasm(wasm_hash):
    lk = X.LedgerKey(
        type=X.LedgerEntryType.CONTRACT_CODE,
        contract_code=X.LedgerKeyContractCode(hash=X.Hash(bytes.fromhex(wasm_hash))),
    )
    res = rpc("getLedgerEntries", {"keys": [X.LedgerKey.to_xdr(lk)]})
    e = res["entries"][0]
    d = X.LedgerEntryData.from_xdr(e["xdr"])
    code = d.contract_code.code
    return {
        "code": code,
        "sha256": hashlib.sha256(code).hexdigest(),
        "size": len(code),
        "last_modified_ledger": e["lastModifiedLedgerSeq"],
        "live_until_ledger": e.get("liveUntilLedgerSeq"),
    }


def account_seq(g):
    aid = X.AccountID(
        X.PublicKey(
            type=X.PublicKeyType.PUBLIC_KEY_TYPE_ED25519,
            ed25519=X.Uint256(StrKey.decode_ed25519_public_key(g)),
        )
    )
    lk = X.LedgerKey(
        type=X.LedgerEntryType.ACCOUNT, account=X.LedgerKeyAccount(account_id=aid)
    )
    res = rpc("getLedgerEntries", {"keys": [X.LedgerKey.to_xdr(lk)]})
    if not res["entries"]:
        return None
    d = X.LedgerEntryData.from_xdr(res["entries"][0]["xdr"])
    a = d.account
    seq = a.seq_num.sequence_number
    return seq.int64 if hasattr(seq, "int64") else int(seq)


def account_info(g):
    aid = X.AccountID(
        X.PublicKey(
            type=X.PublicKeyType.PUBLIC_KEY_TYPE_ED25519,
            ed25519=X.Uint256(StrKey.decode_ed25519_public_key(g)),
        )
    )
    lk = X.LedgerKey(
        type=X.LedgerEntryType.ACCOUNT, account=X.LedgerKeyAccount(account_id=aid)
    )
    res = rpc("getLedgerEntries", {"keys": [X.LedgerKey.to_xdr(lk)]})
    if not res["entries"]:
        return {"exists": False}
    a = X.LedgerEntryData.from_xdr(res["entries"][0]["xdr"]).account
    bal = a.balance
    return {
        "exists": True,
        "thresholds_low_med_high_master": list(bytes(a.thresholds.thresholds)),
        "signers": [
            {
                "type": str(s.key.type),
                "weight": s.weight.uint32,
            }
            for s in a.signers
        ],
        "num_subentries": a.num_sub_entries.uint32,
        "last_modified_ledger": res["entries"][0]["lastModifiedLedgerSeq"],
    }


def auth_addrs(entries):
    out = []
    for raw in entries:
        try:
            entry = X.SorobanAuthorizationEntry.from_xdr(raw) if isinstance(raw, str) else raw
            creds = entry.credentials
            if creds.type == X.SorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
                addr = creds.address.address
                out.append(scval_to_py(X.SCVal(type=X.SCValType.SCV_ADDRESS, address=addr)))
            elif creds.type == X.SorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
                addr = creds.address_v2.address
                out.append(scval_to_py(X.SCVal(type=X.SCValType.SCV_ADDRESS, address=addr)))
            else:
                out.append(str(creds.type))
        except Exception as exc:  # pragma: no cover - diagnostics only
            out.append("decode_error: " + str(exc)[:80])
    return out


def simulate(contract, fn, args, source, auth_mode="record"):
    seq = account_seq(source)
    if seq is None:
        return {"error": "source account does not exist", "source": source}
    tx = (
        TransactionBuilder(Account(source, seq), PASSPHRASE, 1_000_000)
        .append_invoke_contract_function_op(contract, fn, args, auth=[])
        .set_timeout(60)
        .build()
    )
    r = S.simulate_transaction(tx, auth_mode=auth_mode)
    return {
        "function": fn,
        "source": source,
        "error": (r.error or "").split("\n")[0] if r.error else None,
        "return": scval_to_py(X.SCVal.from_xdr(r.results[0].xdr)) if (r.results and not r.error) else None,
        "required_auth": auth_addrs(r.results[0].auth) if (r.results and r.results[0].auth) else [],
        "latest_ledger": r.latest_ledger,
    }


def read(fn, args=None, source=ADMIN):
    return simulate(VAULT, fn, args or [], source)["return"]


def main(out_path=None):
    report = {"rpc": RPC, "vault": VAULT, "network": "stellar-mainnet"}
    inst = get_instance(VAULT)
    report["instance"] = inst

    wasm = get_wasm(inst["wasm_hash"] or WASM_HASH)
    report["wasm"] = {k: v for k, v in wasm.items() if k != "code"}
    report["wasm"]["matches_target"] = wasm["sha256"] == WASM_HASH

    # Also fetch the hash pinned by the recon brief, in case the instance was upgraded.
    if inst["wasm_hash"] != WASM_HASH:
        alt = get_wasm(WASM_HASH)
        report["wasm_brief_hash"] = {k: v for k, v in alt.items() if k != "code"}

    report["accounts"] = {name: account_info(a) for name, a in [
        ("admin", ADMIN), ("operator", OPERATOR), ("wallet_subaccount", WALLET_SUB),
        ("attack_source", ATTACKER),
    ]}

    report["live_state"] = {
        "total_assets_raw": read("total_assets"),
        "total_supply_raw": read("total_supply"),
        "decimals": read("decimals"),
        "get_admin": read("get_admin"),
        "get_operator": read("get_operator"),
        "is_paused": read("is_paused"),
        "get_deployed_assets": read("get_deployed_assets"),
        "get_strategy_balances": read("get_strategy_balances"),
        "get_wallet_deployed_assets": read("get_wallet_deployed_assets"),
        "get_subaccounts": read("get_subaccounts"),
        "query_asset": read("query_asset"),
        "aum_increase_limit_bps": read("get_aum_increase_limit"),
        "aum_decrease_limit_bps": read("get_aum_decrease_limit"),
        "aum_window_duration": read("get_aum_window_duration"),
        "vault_usdc_balance_raw": simulate(USDC, "balance", [scval.to_address(VAULT)], ADMIN)["return"],
        "wallet_usdc_balance_raw": simulate(USDC, "balance", [scval.to_address(WALLET_SUB)], ADMIN)["return"],
        "share_balance_wallet_raw": read("balance", [scval.to_address(WALLET_SUB)]),
        "share_balance_admin_raw": read("balance", [scval.to_address(ADMIN)]),
        "share_balance_operator_raw": read("balance", [scval.to_address(OPERATOR)]),
        "share_balance_attacker_raw": read("balance", [scval.to_address(ATTACKER)]),
    }
    st = report["live_state"]
    if st["total_assets_raw"] is not None:
        st["vault_tvl_usd_at_1usdc"] = round(st["total_assets_raw"] / 1e7, 2)
    if st["total_supply_raw"]:
        st["share_price_usdc"] = round(
            (st["total_assets_raw"] / 1e7) / (st["total_supply_raw"] / 1e13), 6
        )
        st["wallet_share_pct"] = round(
            100.0 * st["share_balance_wallet_raw"] / st["total_supply_raw"], 4
        )

    # Read-only simulation battery. Record mode returns the exact auth tree a call
    # would need; it does not sign or submit anything.
    A = scval.to_address(ATTACKER)
    W = scval.to_address(WALLET_SUB)
    AD = scval.to_address(ADMIN)
    hash_arg = scval.to_bytes(bytes.fromhex(WASM_HASH))
    report["simulations"] = [
        simulate(VAULT, "deposit", [scval.to_int128(10_000_000), A, A, A], ATTACKER),
        simulate(VAULT, "mint", [scval.to_int128(1_000_000), A, A, A], ATTACKER),
        simulate(VAULT, "withdraw", [scval.to_int128(10_000_000), A, A, A], ATTACKER),
        simulate(VAULT, "redeem", [scval.to_int128(1_000_000_000_000), A, A, A], ATTACKER),
        simulate(VAULT, "withdraw", [scval.to_int128(10_000_000), A, W, A], ATTACKER),
        simulate(VAULT, "redeem", [scval.to_int128(1_000_000_000_000), A, W, A], ATTACKER),
        simulate(VAULT, "deposit", [scval.to_int128(1_000_000), A, W, A], ATTACKER),
        simulate(VAULT, "transfer", [W, A, scval.to_int128(1_000_000)], ATTACKER),
        simulate(VAULT, "transfer_from", [A, W, A, scval.to_int128(1_000_000)], ATTACKER),
        simulate(VAULT, "approve", [W, A, scval.to_int128(1_000_000), scval.to_uint32((report["instance"].get("latest_ledger") or 0) + 100)], ATTACKER),
        simulate(VAULT, "upgrade", [hash_arg, A], ATTACKER),
        simulate(VAULT, "upgrade", [hash_arg, AD], ADMIN),
        simulate(VAULT, "propose_admin", [A, A, scval.to_uint64(2_000_000_000)], ATTACKER),
        simulate(VAULT, "accept_admin", [], ATTACKER),
        simulate(VAULT, "pause", [A], ATTACKER),
        simulate(VAULT, "set_operator", [A, A], ATTACKER),
        simulate(VAULT, "update_deployed_assets", [A, scval.to_int128(1_000_000_000_000)], ATTACKER),
        simulate(VAULT, "deposit_to_subaccount", [A, W, scval.to_int128(1)], ATTACKER),
        simulate(VAULT, "withdraw_from_subaccount", [A, W, scval.to_int128(1)], ATTACKER),
        simulate(VAULT, "add_subaccount", [A, A, scval.to_enum("Wallet", None)], ATTACKER),
        simulate(VAULT, "remove_subaccount", [A, W], ATTACKER),
        simulate(VAULT, "set_aum_limits", [A, scval.to_uint32(10_000), scval.to_uint32(10_000)], ATTACKER),
        simulate(VAULT, "seed_wallet_net_deployed", [A, W, scval.to_int128(1)], ATTACKER),
        simulate(VAULT, "remove_wallet_and_reconcile", [A, A, W, scval.to_int128(0)], ATTACKER),
    ]
    # Operator-only path (P): the AUM rate limit is skipped when the previous
    # `deployed_assets` is zero, so the first accounting write is unbounded.
    report["operator_path"] = [
        simulate(VAULT, "update_deployed_assets", [scval.to_address(OPERATOR), scval.to_int128(1)], OPERATOR),
        simulate(VAULT, "update_deployed_assets", [scval.to_address(OPERATOR), scval.to_int128(10**17)], OPERATOR),
        simulate(VAULT, "update_deployed_assets", [scval.to_address(OPERATOR), scval.to_int128(11392468804947658614539)], OPERATOR),
    ]

    # Holder liquidity: the wallet subaccount holds ~99.94% of shares.
    wb = st.get("share_balance_wallet_raw") or 0
    report["holder_liquidity"] = {
        "wallet_shares_raw": wb,
        "max_withdraw_raw": read("max_withdraw", [scval.to_address(WALLET_SUB)]),
        "max_redeem_raw": read("max_redeem", [scval.to_address(WALLET_SUB)]),
        "preview_redeem_all_raw": read("preview_redeem", [scval.to_int128(wb)]),
        "redeem_all_via_wallet_source": simulate(
            VAULT, "redeem", [scval.to_int128(wb), W, W, W], WALLET_SUB
        ),
    }

    report["simulation_verdicts"] = {
        s["function"] + "@" + ("self" if s["source"] == ATTACKER else "admin"): {
            "error": s["error"],
            "required_auth": s["required_auth"],
        }
        for s in report["simulations"]
    }

    text = json.dumps(report, indent=1, default=str)
    if out_path:
        with open(out_path, "w") as fh:
            fh.write(text)
    print(text)
    return report


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
