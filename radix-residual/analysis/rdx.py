#!/usr/bin/env python3
"""Shared Radix Gateway helper (read-only, public endpoint, no secrets).

All calls go to the public Radix mainnet Gateway API. Never submits transactions.
"""
import json
import time
import urllib.request

GATEWAY = "https://mainnet.radixdlt.com"


def post(path, body, retries=4, timeout=60):
    url = GATEWAY + path
    data = json.dumps(body).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(
                url,
                data=data,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "radix-residual-research/1.0",
                },
            )
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:  # noqa: PERF203
            try:
                body = e.read().decode()[:300]
            except Exception:  # noqa: BLE001
                body = ""
            last = f"HTTP {e.code}: {body}"
            time.sleep(1.5 * (i + 1))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"POST {path} failed after {retries} retries: {last}")


def gateway_status():
    return post("/status/gateway-status", {})


def ledger_state():
    st = gateway_status()
    ls = st["ledger_state"]
    return {
        "state_version": ls["state_version"],
        "epoch": ls["epoch"],
        "timestamp": ls["proposer_round_timestamp"],
    }


def entity_details(addresses, aggregation_level="Global", opt_ins=None):
    body = {"addresses": addresses, "aggregation_level": aggregation_level}
    if opt_ins:
        body["opt_ins"] = opt_ins
    return post("/state/entity/details", body)


def entity_metadata(addresses, keys=None):
    return post(
        "/state/entity/page/metadata",
        {"address": addresses, "limit_per_page": 100},
    )


def fungibles(address, at_state_version=None, page_limit=100):
    first = post(
        "/state/entity/details",
        {"addresses": [address], "aggregation_level": "Global"},
    )
    items = []
    it = first["items"][0]
    items.extend(it.get("fungible_resources", {}).get("items", []))
    cursor = it.get("fungible_resources", {}).get("next_cursor")
    if cursor and not at_state_version:
        at_state_version = first["ledger_state"]["state_version"]
    while cursor:
        page = post(
            "/state/entity/page/fungibles/",
            {
                "address": address,
                "cursor": cursor,
                "aggregation_level": "Global",
                "at_ledger_state": {"state_version": at_state_version}
                if at_state_version
                else None,
            },
        )
        items.extend(page.get("items", []))
        cursor = page.get("next_cursor")
    return items


def kvs_keys(kvs, limit=100):
    keys = []
    cursor = None
    sv = None
    while True:
        body = {"key_value_store_address": kvs, "limit_per_page": limit}
        if cursor:
            body["cursor"] = cursor
            body["at_ledger_state"] = {"state_version": sv}
        page = post("/state/key-value-store/keys", body)
        if sv is None:
            sv = page["ledger_state"]["state_version"]
        keys.extend(page["items"])
        cursor = page.get("next_cursor")
        if not cursor:
            break
    return keys


def kvs_data(kvs, keys, at_state_version=None):
    """keys: list of items from kvs_keys() (or dicts with key_hex/key_json)."""
    norm = []
    for k in keys:
        if isinstance(k, dict) and "key_hex" in k:
            norm.append(k)
        elif isinstance(k, dict) and "key" in k and "raw_hex" in k["key"]:
            norm.append({"key_hex": k["key"]["raw_hex"]})
        else:
            raise ValueError(f"unrecognized key shape: {str(k)[:120]}")
    body = {"key_value_store_address": kvs, "keys": norm}
    if at_state_version:
        body["at_ledger_state"] = {"state_version": at_state_version}
    return post("/state/key-value-store/data", body)


def preview(manifest, start_epoch_inclusive=None, end_epoch_exclusive=None,
            tip_percentage=0, nonce=0, signer_public_keys=None,
            flags=None):
    """Preview a transaction manifest string (simulation; never submitted)."""
    ls = ledger_state()
    body = {
        "manifest": manifest,
        "start_epoch_inclusive": start_epoch_inclusive
        or max(1, ls["epoch"] - 2),
        "end_epoch_exclusive": end_epoch_exclusive or (ls["epoch"] + 2),
        "nonce": nonce,
        "signer_public_keys": signer_public_keys
        or [
            {
                "key_type": "EddsaEd25519",
                "key_hex": "00" * 32,
            }
        ],
        "flags": flags or {"use_free_credit": True, "assume_all_signature_proofs": True},
        "tip_percentage": tip_percentage,
    }
    return post("/transaction/preview", body)
