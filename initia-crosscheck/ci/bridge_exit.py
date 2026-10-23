#!/usr/bin/env python3
"""initia-crosscheck — bridge-lockbox exit re-assessment + Initia on-chain verification.

Read-only. Public endpoints only (no keys required except optional Alchemy for the EVM part).
Runs on GitHub Actions; writes JSON + markdown into ci-out/.

Core question (from the Initia 2026-10-23 exploit): an OFT/CCTP/IBC lockbox pays at par for
any source-side mint. For our unpatched wasmvm chains (Archway / Jackal / Shido / Nyx / PundiX),
what is the *par-drainable* value that a CWA-2026-006 unbacked mint could release through
bridge escrows, versus the ~$18k DEX-pool bound already measured?

Method: for each chain, the amount of real value that can be released at par by minting a
foreign IBC voucher denom and sending it back is bounded by the *circulating supply of that
voucher on the chain* (the two sides of an ICS-20 channel are equal: voucher supply on the
destination == escrow on the source). So: enumerate supply, resolve every ibc/<hash> denom to
its base denom, classify foreign vouchers, and value the hard assets.

Also enumerates module accounts (IBC escrow / community pool / fee pool / mint) for the
direct-state-theft variant, and (optionally) verifies the Initia incident on Ethereum.
"""
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)
UA = {"User-Agent": "initia-crosscheck-ci/1.0"}

# ---------------------------------------------------------------- chains
CHAINS = {
    "archway": {
        "rest": ["https://api.mainnet.archway.io"],
        "hrp": "archway",
        "native": ["aarch"],
        "wasm": True,
    },
    "jackal": {
        "rest": [
            "https://api.jackal.nodestake.org",
            "https://jackal.api.pocket.network",
            "https://rest.cosmos.directory/jackal",
        ],
        "hrp": "jkl",
        "native": ["ujkl"],
        "wasm": True,
    },
    "shido": {
        "rest": ["https://api-shido.onenov.xyz", "https://rest.mavnode.io"],
        "hrp": "shido",
        "native": ["shido"],
        "wasm": True,
    },
    "nyx": {
        "rest": ["https://api.nyx.nodes.guru", "https://api.nymtech.net"],
        "hrp": "n",
        "native": ["unym", "unyx"],
        "wasm": True,
    },
    "pundix": {
        "rest": ["https://px-rest.pundix.com"],
        "hrp": "px",
        "native": ["bscpundix", "pundix", "ibc"],
        "wasm": False,
    },
    "sommelier": {
        "rest": ["https://sommelier-api.polkachu.com"],
        "hrp": "somm",
        "native": ["usomm"],
        "wasm": False,
    },
}

# Counterparty chains whose escrow we verify directly (chain_id -> rest, hrp).
COUNTERPARTY = {
    "noble-1": (["https://noble-api.polkachu.com", "https://rest.cosmos.directory/noble"], "noble"),
    "osmosis-1": (["https://lcd.osmosis.zone", "https://osmosis-api.polkachu.com",
                   "https://rest.cosmos.directory/osmosis"], "osmo"),
    "axelar-dojo-1": (["https://axelar-api.polkachu.com", "https://rest.cosmos.directory/axelar"], "axelar"),
    "gravity-bridge-3": (["https://gravity-bridge-api.polkachu.com"], "gravity"),
    "injective-1": (["https://injective-api.polkachu.com", "https://rest.cosmos.directory/injective"], "inj"),
    "celestia": (["https://celestia-api.polkachu.com", "https://rest.cosmos.directory/celestia"], "celestia"),
    "akashnet-2": (["https://akash-api.polkachu.com", "https://rest.cosmos.directory/akash"], "akash"),
    "kujira-1": (["https://kujira-api.polkachu.com"], "kujira"),
    "juno-1": (["https://juno-api.polkachu.com", "https://rest.cosmos.directory/juno"], "juno"),
    "stride-1": (["https://stride-api.polkachu.com", "https://rest.cosmos.directory/stride"], "stride"),
    "stargaze-1": (["https://stargaze-api.polkachu.com"], "stars"),
    "pacific-1": (["https://sei-api.polkachu.com", "https://rest.cosmos.directory/sei"], "sei"),
    "evmos_9001-2": (["https://evmos-api.polkachu.com"], "evmos"),
    "phoenix-1": (["https://terra-api.polkachu.com", "https://rest.cosmos.directory/terra"], "terra"),
    "dydx-mainnet-1": (["https://dydx-api.polkachu.com"], "dydx"),
    "interwoven-1": (["https://initia-api.polkachu.com"], "init"),
}

# base_denom -> (coingecko id, decimals). Used for USD valuation of hard assets.
ASSET_MAP = {
    "uusdc": ("usd-coin", 6),
    "usdc": ("usd-coin", 6),
    "uusdt": ("tether", 6),
    "usdt": ("tether", 6),
    "udai": ("dai", 18),
    "dai": ("dai", 18),
    "uatom": ("cosmos", 6),
    "atom": ("cosmos", 6),
    "stuatom": ("stride-staked-atom", 6),
    "uosmo": ("osmosis", 6),
    "osmo": ("osmosis", 6),
    "utia": ("celestia", 6),
    "uakt": ("akash-network", 6),
    "inj": ("injective-protocol", 18),
    "aarch": ("archway", 18),
    "ujkl": ("jackal", 6),
    "wei": ("ethereum", 18),
    "weth-wei": ("ethereum", 18),
    "wbtc-satoshi": ("bitcoin", 8),
    "wbtc": ("bitcoin", 8),
    "ustrd": ("stride", 6),
    "uluna": ("terra-luna", 6),
    "usei": ("sei-network", 6),
    "ujuno": ("juno-network", 6),
    "aevmos": ("evmos", 18),
    "aplanq": ("planq", 18),
    "acudos": ("cudos", 18),
    "shido": ("shido", 18),
    "unym": ("nym", 6),
    "usomm": ("sommelier", 6),
    "bscpundix": ("pundi-x", 8),
    "pundix": ("pundi-x", 8),
    "factory/osmo1q77cw0mmlluxu0wr29fcdd0tdnh78gzhkvhe4n6ulal9qvrtu43qtd0nh8/pbb": ("pbb", 6),
}

HARD_KEYS = [
    "usdc", "usdt", "dai", "weth", "wei", "wbtc", "btc", "eth", "atom", "osmo",
    "tia", "akt", "inj", "steth", "wsteth", "usd",
]


# ---------------------------------------------------------------- http
def jget(rests, path, timeout=25, tries=3):
    last = None
    for _ in range(tries):
        for base in rests:
            try:
                req = urllib.request.Request(base + path, headers=UA)
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    return json.loads(r.read().decode())
            except Exception as e:  # noqa
                last = f"{base}{path}: {e}"
        time.sleep(1.0)
    return {"__err__": str(last)}


def paginate(rests, path, key, limit=1000, maxpages=40):
    items, nk = [], None
    sep = "&" if "?" in path else "?"
    for _ in range(maxpages):
        u = f"{path}{sep}pagination.limit={limit}"
        if nk:
            u += "&pagination.key=" + urllib.parse.quote(nk)
        d = jget(rests, u)
        if "__err__" in d:
            return items, d["__err__"]
        items += d.get(key, [])
        nk = d.get("pagination", {}).get("next_key")
        if not nk:
            break
    return items, None


# ---------------------------------------------------------------- bech32
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"


def _polymod(values):
    gen = [0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3]
    chk = 1
    for v in values:
        b = chk >> 25
        chk = (chk & 0x1FFFFFF) << 5 ^ v
        for i in range(5):
            chk ^= gen[i] if ((b >> i) & 1) else 0
    return chk


def _hrp_expand(hrp):
    return [ord(x) >> 5 for x in hrp] + [0] + [ord(x) & 31 for x in hrp]


def bech32_encode(hrp, data):
    values = _hrp_expand(hrp) + data
    polymod = _polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1
    checksum = [(polymod >> 5 * (5 - i)) & 31 for i in range(6)]
    combined = data + checksum
    return hrp + "1" + "".join(CHARSET[d] for d in combined)


def convertbits(data, frombits, tobits, pad=True):
    acc = bits = 0
    ret = []
    maxv = (1 << tobits) - 1
    for value in data:
        acc = (acc << frombits) | value
        bits += frombits
        while bits >= tobits:
            bits -= tobits
            ret.append((acc >> bits) & maxv)
    if pad and bits:
        ret.append((acc << (tobits - bits)) & maxv)
    return ret


def escrow_addr(hrp, channel, version="ics20-1"):
    """ibc-go GetEscrowAddress (ADR-028): sha256(version ++ 0x00 ++ 'transfer/channel-N')[:20].

    Verified: noble escrow for channel-12 holds 33,621 uusdc == Archway voucher supply.
    """
    pre = version.encode() + b"\x00" + f"transfer/{channel}".encode()
    h = hashlib.sha256(pre).digest()[:20]
    return bech32_encode(hrp, convertbits(list(h), 8, 5))


# ---------------------------------------------------------------- pricing
def load_prices():
    ids = sorted({v[0] for v in ASSET_MAP.values()})
    prices = {}
    # DefiLlama batch (chunked)
    for i in range(0, len(ids), 40):
        chunk = ids[i:i + 40]
        url = "https://coins.llama.fi/prices/current/" + ",".join("coingecko:" + c for c in chunk)
        try:
            req = urllib.request.Request(url, headers=UA)
            d = json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
            for k, v in d.get("coins", {}).items():
                prices[k.split(":", 1)[1]] = v.get("price")
        except Exception:
            pass
    return prices


# ---------------------------------------------------------------- chain collection
def denom_base(denom, trace_map):
    if denom.startswith("ibc/"):
        return trace_map.get(denom, {}).get("base", None), trace_map.get(denom, {}).get("path", None)
    return denom, None


def chain_report(name, cfg, prices):
    rests, hrp = cfg["rest"], cfg["hrp"]
    rep = {"chain": name, "hrp": hrp, "errors": []}

    # versions
    ni = jget(rests, "/cosmos/base/tendermint/v1beta1/node_info")
    if "__err__" in ni:
        rep["errors"].append("node_info: " + ni["__err__"])
        return rep
    try:
        av = ni["application_version"]
        rep["app"] = av.get("name")
        rep["app_version"] = av.get("version")
        rep["build_deps"] = av.get("build_deps", [])
        rep["cosmos_sdk"] = av.get("cosmos_sdk_version")
    except Exception as e:
        rep["errors"].append("node_info parse: " + str(e))
    try:
        rep["chain_id"] = ni["default_node_info"]["network"]
        rep["latest_height"] = ni["default_node_info"]["other"]["height"] if "other" in ni["default_node_info"] else None
    except Exception:
        pass

    # wasm params
    if cfg.get("wasm"):
        wp = jget(rests, "/cosmwasm/wasm/v1/codes/params")
        if "__err__" not in wp:
            rep["wasm_params"] = wp.get("params", wp)

    # supply
    supply, serr = paginate(rests, "/cosmos/bank/v1beta1/supply", "supply")
    if serr:
        rep["errors"].append("supply: " + serr)

    # denom traces
    traces, terr = paginate(rests, "/ibc/apps/transfer/v1/denom_traces", "denom_traces", limit=500)
    if terr:
        rep["errors"].append("denom_traces: " + terr)
    trace_map = {}
    for t in traces:
        full = t["path"] + "/" + t["base_denom"]
        H = hashlib.sha256(full.encode()).hexdigest().upper()
        trace_map["ibc/" + H] = {"path": t["path"], "base": t["base_denom"], "full": full}
    rep["n_denom_traces"] = len(traces)

    # channels + client resolution
    chans, cerr = paginate(rests, "/ibc/core/channel/v1/channels", "channels", limit=200)
    if cerr:
        rep["errors"].append("channels: " + cerr)
    conns, _ = paginate(rests, "/ibc/core/connection/v1/connections", "connections", limit=200)
    conn_client = {c.get("id"): (c.get("client_id") or (c.get("counterparty", {}) or {}).get("client_id"))
                   for c in conns}
    clients = {}
    cs, _ = paginate(rests, "/ibc/core/client/v1/client_states", "client_states", limit=200)
    for c in cs:
        cid = c.get("client_id")
        try:
            clients[cid] = c.get("client_state", {}).get("chain_id")
        except Exception:
            pass
    # fallback: client state endpoint per client
    chan_info = []
    for ch in chans:
        hops = ch.get("connection_hops") or []
        conn = hops[0] if hops else None
        cl = conn_client.get(conn)
        if cl and not clients.get(cl):
            one = jget(rests, f"/ibc/core/client/v1/client_states/{cl}")
            if "__err__" not in one:
                clients[cl] = one.get("client_state", {}).get("chain_id")
        cp = ch.get("counterparty", {}) or {}
        chan_info.append({
            "channel": ch.get("channel_id"),
            "port": ch.get("port_id"),
            "state": ch.get("state"),
            "conn": conn,
            "client": cl,
            "counterparty_chain": clients.get(cl),
            "cp_port": cp.get("port_id"),
            "cp_channel": cp.get("channel_id"),
        })
    rep["n_channels"] = len(chan_info)
    rep["channels"] = chan_info

    # supply valuation
    native_set = set(cfg["native"])
    foreign = []
    native_supply = []
    unpriced_foreign = []
    for c in supply:
        denom = c["denom"]
        amt = int(c["amount"])
        if denom in native_set:
            native_supply.append({"denom": denom, "amount": amt})
            continue
        if denom.startswith("ibc/") or denom.startswith("gravity0x") or denom.startswith("erc20/") \
           or denom.startswith("factory/") or denom.startswith("cw20:") or "wei" in denom:
            base, path = denom_base(denom, trace_map)
            info = ASSET_MAP.get(base) if base else None
            usd = None
            dec = None
            if info:
                dec = info[1]
                p = prices.get(info[0])
                if p is not None:
                    usd = amt / (10 ** dec) * p
            rec = {"denom": denom, "base": base, "path": path, "amount": amt, "dec": dec, "usd": usd}
            if usd is None:
                unpriced_foreign.append(rec)
            else:
                foreign.append(rec)
        else:
            native_supply.append({"denom": denom, "amount": amt})

    # hard-asset subset of foreign vouchers
    hard = [r for r in foreign if r["base"] and any(k in r["base"].lower() for k in HARD_KEYS)]
    rep["native_supply"] = sorted(native_supply, key=lambda x: -x["amount"])
    rep["foreign_vouchers_priced"] = sorted(foreign, key=lambda x: -(x["usd"] or 0))
    rep["foreign_vouchers_hard"] = sorted(hard, key=lambda x: -(x["usd"] or 0))
    rep["foreign_unpriced_count"] = len(unpriced_foreign)
    rep["foreign_unpriced_top"] = sorted(unpriced_foreign, key=lambda x: -x["amount"])[:30]
    rep["foreign_voucher_usd_total"] = round(sum(r["usd"] for r in foreign), 2)
    rep["foreign_hard_usd_total"] = round(sum(r["usd"] for r in hard), 2)

    # module accounts (direct-theft variant)
    ma = jget(rests, "/cosmos/auth/v1beta1/module_accounts?pagination.limit=300")
    mods = {}
    if "__err__" not in ma:
        for acc in ma.get("accounts", []):
            try:
                nm = acc.get("name") or (acc.get("base_account", {}) or {}).get("name")
                addr = acc.get("address") or (acc.get("base_account", {}) or {}).get("address")
                if nm:
                    mods[nm] = addr
            except Exception:
                pass
    want = ["transfer", "distribution", "gov", "mint", "fee_collector", "bonded_tokens_pool",
            "not_bonded_tokens_pool", "community", "rewards", "wasm", "ibc", "stake"]
    mod_balances = {}
    def one_mod(nm_addr):
        nm, addr = nm_addr
        d = jget(rests, f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")
        if "__err__" in d:
            return nm, None
        return nm, d.get("balances", [])
    sel = [(nm, addr) for nm, addr in mods.items() if any(w in nm for w in want)]
    with ThreadPoolExecutor(max_workers=6) as ex:
        for nm, bals in ex.map(one_mod, sel):
            mod_balances[nm] = bals
    rep["module_balances"] = mod_balances

    # per-channel IBC escrow (outbound) balances
    escrows = {}
    def one_esc(ch):
        cid = ch["channel"]
        try:
            a = escrow_addr(hrp, cid)
        except Exception:
            return cid, None
        d = jget(rests, f"/cosmos/bank/v1beta1/balances/{a}?pagination.limit=100")
        if "__err__" in d:
            return cid, None
        b = d.get("balances", [])
        return cid, ({"addr": a, "balances": b} if b else None)
    with ThreadPoolExecutor(max_workers=8) as ex:
        for cid, val in ex.map(one_esc, chan_info):
            if val:
                escrows[cid] = val
    rep["ibc_escrows"] = escrows

    # counterparty escrow verification: the REAL assets backing our foreign vouchers.
    # For channel C on our chain with counterparty (chain X, channel D), X's escrow for D
    # holds the real tokens our minted voucher would release at par.
    cp_escrows = {}
    def one_cp(ch):
        xid = ch.get("counterparty_chain")
        dch = ch.get("cp_channel")
        if not xid or not dch or xid not in COUNTERPARTY:
            return None
        rests_x, hrp_x = COUNTERPARTY[xid]
        try:
            a = escrow_addr(hrp_x, dch)
        except Exception:
            return None
        d = jget(rests_x, f"/cosmos/bank/v1beta1/balances/{a}?pagination.limit=200")
        if "__err__" in d:
            return None
        bals = d.get("balances", [])
        # value the escrow
        tot = 0.0
        priced = []
        for b in bals:
            base = b["denom"]
            info = ASSET_MAP.get(base)
            if info and prices.get(info[0]) is not None:
                usd = int(b["amount"]) / (10 ** info[1]) * prices[info[0]]
                tot += usd
                priced.append({"denom": base, "amount": int(b["amount"]), "usd": round(usd, 2)})
            else:
                priced.append({"denom": base, "amount": int(b["amount"]), "usd": None})
        return {"our_channel": ch["channel"], "cp_chain": xid, "cp_channel": dch,
                "cp_escrow_addr": a, "balances": bals, "priced": priced, "usd": round(tot, 2)}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for val in ex.map(one_cp, chan_info):
            if val:
                cp_escrows[val["our_channel"]] = val
    rep["counterparty_escrows"] = cp_escrows
    rep["counterparty_escrow_usd_total"] = round(
        sum(v["usd"] for v in cp_escrows.values() if v.get("usd")), 2)
    return rep


# ---------------------------------------------------------------- initia EVM verify
def initia_eth_verify():
    key = os.environ.get("ALCHEMY_API_KEY")
    if not key:
        return {"skipped": "no ALCHEMY_API_KEY"}
    url = f"https://eth-mainnet.g.alchemy.com/v2/{key}"
    attacker = "0xDD922c841d85E12dac2dc2eef5a5E29cFFf6edFA"

    def rpc(method, params):
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
        try:
            return json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
        except Exception as e:
            return {"error": str(e)}

    res = {"attacker": attacker}
    b = rpc("eth_getBalance", [attacker, "latest"])
    if "result" in b:
        res["attacker_balance_eth"] = int(b["result"], 16) / 1e18
    t = rpc("alchemy_getAssetTransfers", [{
        "fromAddress": attacker, "category": ["external", "erc20"],
        "maxCount": "0x32", "order": "desc",
    }])
    try:
        trs = t["result"]["transfers"]
        res["recent_out_transfers"] = [
            {"asset": x.get("asset"), "value": x.get("value"), "to": x.get("to"),
             "hash": x.get("hash"), "block": x.get("blockNum")} for x in trs[:30]
        ]
        eth_total = sum((x.get("value") or 0) for x in trs if x.get("asset") in ("ETH", None))
        res["recent_eth_out_sum"] = eth_total
    except Exception as e:
        res["transfers_err"] = str(e)
    return res


# ---------------------------------------------------------------- main
def main():
    prices = load_prices()
    print("prices loaded:", len(prices))
    reports = {}
    for name, cfg in CHAINS.items():
        print("== collecting", name)
        try:
            reports[name] = chain_report(name, cfg, prices)
        except Exception as e:
            reports[name] = {"chain": name, "errors": [f"fatal: {e}"]}
    with open(os.path.join(OUT, "bridge_exit.json"), "w") as f:
        json.dump({"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                   "prices": prices, "chains": reports}, f, indent=2)

    # markdown summary
    lines = ["# Bridge-lockbox exit re-assessment (par-drain bound)", "",
             f"Generated: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}", "",
             "Bound = circulating supply of foreign IBC vouchers held on the chain "
             "(= counterparty escrow that a minted voucher round-trip would release at par).", ""]
    for name, r in reports.items():
        lines.append(f"## {name}")
        lines.append(f"- app: `{r.get('app')}` {r.get('app_version')}  sdk {r.get('cosmos_sdk')}  "
                     f"height {r.get('latest_height')}")
        wp = r.get("wasm_params", {})
        if wp:
            lines.append(f"- wasm params: `{json.dumps(wp)[:200]}`")
        lines.append(f"- foreign voucher USD total: **${r.get('foreign_voucher_usd_total')}** "
                     f"(hard assets: **${r.get('foreign_hard_usd_total')}**)")
        lines.append(f"- counterparty escrow (real assets behind those vouchers): "
                     f"**${r.get('counterparty_escrow_usd_total')}**")
        lines.append(f"- channels: {r.get('n_channels')}  denom traces: {r.get('n_denom_traces')}")
        lines.append("")
        hard = r.get("foreign_vouchers_hard", [])[:15]
        if hard:
            lines.append("| asset | denom | path | amount | USD |")
            lines.append("|---|---|---|---|---|")
            for h in hard:
                amt = h["amount"] / (10 ** h["dec"]) if h.get("dec") else h["amount"]
                lines.append(f"| {h['base']} | `{h['denom'][:18]}…` | {h.get('path')} | "
                             f"{amt:,.4f} | ${h['usd']:,.0f} |")
        lines.append("")
        if r.get("errors"):
            lines.append(f"- errors: {r['errors']}")
        lines.append("")
    with open(os.path.join(OUT, "bridge_exit.md"), "w") as f:
        f.write("\n".join(lines))

    # versions-only quick file
    with open(os.path.join(OUT, "versions.json"), "w") as f:
        json.dump({n: {"app": r.get("app"), "version": r.get("app_version"),
                       "sdk": r.get("cosmos_sdk"), "height": r.get("latest_height"),
                       "wasm_params": r.get("wasm_params"),
                       "build_deps": [d for d in r.get("build_deps", [])
                                      if any(k in d.get("path", "") for k in ("wasmvm", "wasmd"))]}
                   for n, r in reports.items()}, f, indent=2)

    eth = initia_eth_verify()
    with open(os.path.join(OUT, "initia_eth.json"), "w") as f:
        json.dump(eth, f, indent=2)

    print("DONE. wrote bridge_exit.json / bridge_exit.md / versions.json / initia_eth.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
