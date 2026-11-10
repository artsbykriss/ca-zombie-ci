#!/usr/bin/env python3
"""Keyless live-state dump for the Neufund FeeDisbursal finding.

Reads both chains at their latest block and writes ci-out/live-state.json.
No secrets, no keyed URLs: only the public endpoints (or the CI-provided
FORK_RPC_URL / PULSECHAIN_RPC_URL env vars, which are never written out).
"""
import json
import os
import urllib.request

FD = "0x26B7DedAb33c58bC9Edc26D9CD81b8eEE43c24Dd"
CONTROLLER = "0xa10e0AB575016F91Df28C20306f359123BE5ac7D"
IDENTITY_REGISTRY = "0x98B2d718D96F956d1CdEDA013CFd67a797928B13"
RBAC = "0xaE38c27E646959735ec70d77ED4eCc03A3EFf490"
ETHT = "0x0B7dc5A43Ce121b4EaaA41b0F4f43BBA47Bb8951"
EURT = "0x61646f3BEdE9E1A24D387Feb661888B4cc1587d8"
NEU = "0xA823E6722006afe99E91c30FF5295052fe6b8E32"
ATTACKER = "0x5247E060a978D2a7b39029cc39C9c7cba15dea16"

ROLE_DISBURSER = "0xd7ea6093d11d866c9e8449f8bffd9da1387c530ee40ad54f0641425bb0ca33b7"
ROLE_IDM = "0x32964e6bc50f2aaab2094a1d311be8bda920fc4fb32b2fb054917bdb153a9e9e"
ROLE_ACCESS = "0xac42f8beb17975ed062dcb80c63e6d203ef1c2c335ced149dc5664cc671cb7da"
ROLE_DISBURSAL_MANAGER = "0x677f87f7b7ef7c97e42a7e6c85c295cf020c9f11eea1e49f6bf847d7aeae1475"
ROLE_RECLAIMER = "0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5"

DEFAULT_ETH = "https://ethereum-rpc.publicnode.com"
DEFAULT_PLS = "https://pulsechain-rpc.publicnode.com"


def rpc(url, method, params):
    req = urllib.request.Request(
        url,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"content-type": "application/json", "user-agent": "Mozilla/5.0 (research)"},
    )
    with urllib.request.urlopen(req, timeout=40) as r:
        out = json.loads(r.read())
    if "result" not in out:
        raise RuntimeError(str(out)[:300])
    return out["result"]


def w(a):
    return a[2:].lower().rjust(64, "0")


def call(url, to, data, block="latest"):
    return rpc(url, "eth_call", [{"to": to, "data": data}, block])


def u(url, to, data):
    return int(call(url, to, data), 16)


def snapshot(name, url, code_hash_expected):
    out = {"chain": name, "block": int(rpc(url, "eth_blockNumber", []), 16)}
    code = rpc(url, "eth_getCode", [FD, "latest"])
    out["fd_code_bytes"] = (len(code) - 2) // 2
    out["fd_code_sha3"] = None  # filled by caller via cast if desired
    out["fd_native_balance_wei"] = int(rpc(url, "eth_getBalance", [FD, "latest"]), 16)
    for label, token, slot in (("ETHT", ETHT, 0), ("EURT", EURT, 4), ("NEU", NEU, None)):
        if slot is None:
            out[f"{label}_balance"] = u(url, token, "0x70a08231" + w(FD))
        else:
            out[f"{label}_balance"] = u(url, token, "0x70a08231" + w(FD))
    out["disbursal_count_ETHT_NEU"] = u(url, FD, "0xa01b67e9" + w(ETHT) + w(NEU))
    out["disbursal_count_EURT_NEU"] = u(url, FD, "0xa01b67e9" + w(EURT) + w(NEU))
    out["onAccept_attacker"] = u(url, CONTROLLER, "0xd2efcd94" + w(ETHT) + w(NEU) + w(ATTACKER))
    out["onAccept_zero"] = u(url, CONTROLLER, "0xd2efcd94" + w(ETHT) + w(NEU) + w("0x" + "0" * 40))
    out["claims_attacker"] = call(url, IDENTITY_REGISTRY, "0xd0d46a0b" + w(ATTACKER))
    out["rbac_everyone_disburser_on_fd"] = u(
        url, RBAC, "0x0beeb0af" + w("0x" + "0" * 40) + w(ROLE_DISBURSER) + w(FD)
    )
    for label, role in (("IDM", ROLE_IDM), ("ACCESS", ROLE_ACCESS), ("DISBURSAL_MANAGER", ROLE_DISBURSAL_MANAGER), ("RECLAIMER", ROLE_RECLAIMER)):
        raw = call(url, RBAC, "0x11d817f2" + w("0x" + "0" * 40) + w(role))
        b = bytes.fromhex(raw[2:])
        off = int.from_bytes(b[0:32], "big")
        n = int.from_bytes(b[off : off + 32], "big")
        users = ["0x" + b[off + 32 + 32 * i : off + 64 + 32 * i].hex() for i in range(n)]
        out[f"global_role_users_{label}"] = users
    out["gas_price_wei"] = int(rpc(url, "eth_gasPrice", []), 16)
    return out


def main():
    eth_url = os.environ.get("FORK_RPC_URL") or DEFAULT_ETH
    pls_url = os.environ.get("PULSECHAIN_RPC_URL") or DEFAULT_PLS
    res = {}
    try:
        res["ethereum"] = snapshot("ethereum", eth_url, None)
    except Exception as e:  # noqa: BLE001
        res["ethereum"] = {"error": str(e)[:300]}
    try:
        res["pulsechain"] = snapshot("pulsechain", pls_url, None)
    except Exception as e:  # noqa: BLE001
        res["pulsechain"] = {"error": str(e)[:300]}

    # priceable exit: 1 ETH-T withdraws 1 native PLS (not ETH).  Price from DefiLlama.
    try:
        req = urllib.request.Request(
            "https://coins.llama.fi/prices/current/coingecko:pulsechain",
            headers={"user-agent": "research"},
        )
        price = json.loads(urllib.request.urlopen(req, timeout=30).read())
        res["pls_usd"] = price["coins"]["coingecko:pulsechain"]["price"]
    except Exception as e:  # noqa: BLE001
        res["pls_usd"] = None
        res["pls_price_error"] = str(e)[:200]

    if res.get("pls_usd") and res.get("pulsechain", {}).get("ETHT_balance"):
        res["pulsechain"]["ETHT_exit_usd"] = res["pulsechain"]["ETHT_balance"] * res["pls_usd"] / 1e18
        res["pulsechain"]["claim_gas_pls"] = res["pulsechain"]["gas_price_wei"] * 290000 / 1e18
        res["pulsechain"]["claim_gas_usd"] = res["pulsechain"]["claim_gas_pls"] * res["pls_usd"]
        res["pulsechain"]["net_usd"] = (
            res["pulsechain"]["ETHT_exit_usd"] - res["pulsechain"]["claim_gas_usd"]
        )

    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/live-state.json", "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    main()
