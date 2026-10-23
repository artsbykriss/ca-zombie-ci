#!/usr/bin/env python3
"""Rabby Swap legacy router — allowance census (robust).

For each chain: enumerate ERC-20 Approval logs where spender == legacy router,
dedupe to the latest approval per (token, owner), then read the *current*
allowance and (only where allowance > 0) the owner balance. A position is
live-extractable iff allowance > 0 AND balance > 0.

Robustness: browser User-Agent, retry/backoff on 429/403/413/5xx, adaptive
eth_getLogs chunking, allowance-first to minimise call volume.

Read-only. RPC URLs come from env vars only; never written to disk.
"""
import json, os, sys, time, urllib.request, urllib.error

APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
SEL_ALLOWANCE = "dd62ed3e"
SEL_BALANCE = "70a08231"
SEL_SYMBOL = "95d89b41"
SEL_DECIMALS = "313ce567"
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
HEADERS = {"Content-Type": "application/json", "User-Agent": UA}


def _post(url, body, timeout=180):
    req = urllib.request.Request(url, data=body, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def rpc(url, method, params, retries=6, timeout=180):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for a in range(retries):
        try:
            return _post(url, body, timeout=timeout)
        except urllib.error.HTTPError as e:
            last = e
            if e.code in (429, 413, 500, 502, 503, 504):
                time.sleep(min(2 ** a, 20))
                continue
            raise
        except Exception as e:
            last = e
            time.sleep(min(1.5 * (a + 1), 10))
    raise last


def rpc_batch(url, calls, retries=6):
    """Batch eth_calls; on any failure (incl. 413 / no batch support) fall back to
    sequential single calls so we never silently lose reads."""
    body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
                       for i, (m, p) in enumerate(calls)]).encode()
    last = None
    for a in range(retries):
        try:
            data = _post(url, body)
            if not isinstance(data, list):
                raise ValueError("no batch support")
            out = [None] * len(calls)
            for item in data:
                if isinstance(item, dict) and "result" in item:
                    out[item["id"]] = item["result"]
            return out
        except urllib.error.HTTPError as e:
            last = e
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(min(2 ** a, 20))
                continue
            break  # 413 / 403 / 400 etc -> go sequential
        except Exception as e:
            last = e
            if a < 2:
                time.sleep(1.0)
            else:
                break
    # sequential fallback
    out = []
    for (m, p) in calls:
        try:
            r = rpc(url, m, p, retries=3)
            out.append(r.get("result"))
        except Exception:
            out.append(None)
    return out


def pad(addr):
    return "0x" + addr.lower().replace("0x", "").rjust(64, "0")


# Etherscan V2 free tier covers these chains for log queries (topic-only, no address param)
ETHERSCAN_V2 = {1, 137, 42161, 42220}


def _es_get(url, retries=6):
    last = None
    for a in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            last = e
            time.sleep(min(2 ** a, 15))
        except Exception as e:
            last = e
            time.sleep(1.5 * (a + 1))
    raise last


def get_logs_etherscan(chain_id, router):
    key = os.environ.get("ETHERSCANV2_API_KEY", "")
    if not key or chain_id not in ETHERSCAN_V2:
        raise RuntimeError("etherscan v2 not available")
    base = "https://api.etherscan.io/v2/api"
    t2 = pad(router)
    logs = []
    page = 1
    while True:
        url = (f"{base}?chainid={chain_id}&module=logs&action=getLogs&topic0={APPROVAL}"
               f"&topic2={t2}&topic0_2_opr=and&fromBlock=0&toBlock=latest&offset=1000&page={page}&apikey={key}")
        d = _es_get(url)
        if d.get("status") != "1" or not isinstance(d.get("result"), list):
            if page == 1:
                raise RuntimeError("etherscan v2: " + str(d.get("result"))[:120])
            break
        logs.extend(d["result"])
        if len(d["result"]) < 1000:
            break
        page += 1
        if page > 60:
            break
        time.sleep(0.25)
    # latest block
    d = _es_get(f"{base}?chainid={chain_id}&module=proxy&action=eth_blockNumber&apikey={key}")
    latest = int(d.get("result", "0x0"), 16)
    return logs, latest, 0, latest, False


def find_deploy_block(url, router, latest):
    """Binary search for the first block at which the router has code.

    Returns None if the node is not archival (returns code for block 0, which is
    impossible for a 2022 contract) or if historical eth_getCode errors out.
    """
    # archival check: a real archive node has no code at block 0 for this address
    try:
        r0 = rpc(url, "eth_getCode", [router, "0x0"], retries=1)
    except Exception:
        return None
    if "result" not in r0:
        return None
    if r0["result"] not in ("0x", None):
        return None  # non-archival node: answers every block with latest code

    lo, hi = 0, latest
    while lo < hi:
        mid = (lo + hi) // 2
        try:
            r = rpc(url, "eth_getCode", [router, hex(mid)], retries=2)
        except Exception:
            return None
        if "result" not in r:
            return None
        if r["result"] not in ("0x", None):
            hi = mid
        else:
            lo = mid + 1
    return lo


def get_logs(url, router, max_requests=None):
    """Return (logs, latest, deploy_block, covered_to, partial).

    Order: (A) full-range eth_getLogs; (B) deployment-based forward scan (covers
    the 2022 approval window first); (C) chunked scan from genesis. Bounded by
    RABBY_MAX_REQS / RABBY_MAX_SECS.
    """
    if max_requests is None:
        max_requests = int(os.environ.get("RABBY_MAX_REQS", "1500"))
    max_secs = int(os.environ.get("RABBY_MAX_SECS", "420"))
    deadline = time.time() + max_secs
    topic2 = pad(router)
    latest = int(rpc(url, "eth_blockNumber", [])["result"], 16)
    full = {"fromBlock": "0x0", "toBlock": "latest", "topics": [APPROVAL, None, topic2]}
    try:
        r = rpc(url, "eth_getLogs", [full], retries=1, timeout=25)
    except Exception:
        r = {}
    if "result" in r:
        return r["result"], latest, 0, latest, False

    def _chunked(start, chunk):
        r0 = rpc(url, "eth_getLogs", [{"fromBlock": hex(start), "toBlock": hex(min(start + chunk - 1, latest)),
                                       "topics": [APPROVAL, None, topic2]}])
        if "result" not in r0:
            raise RuntimeError("first chunk failed")
        logs = list(r0["result"])
        cur = start + chunk
        reqs = 1
        while cur <= latest and reqs < max_requests and time.time() < deadline:
            end = min(cur + chunk - 1, latest)
            rr = rpc(url, "eth_getLogs", [{"fromBlock": hex(cur), "toBlock": hex(end),
                                           "topics": [APPROVAL, None, topic2]}])
            if "result" not in rr:
                raise RuntimeError("mid-chunk failed")
            logs.extend(rr["result"])
            cur = end + 1
            reqs += 1
        covered_to = min(cur - 1, latest)
        return logs, covered_to

    chunks = (2_000_000, 500_000, 100_000, 50_000, 10_000, 2_000, 1_000, 500, 100, 10)

    # (B) deployment-based forward scan
    deploy = find_deploy_block(url, router, latest)
    if deploy is not None:
        for chunk in chunks:
            try:
                logs, covered_to = _chunked(deploy, chunk)
                return logs, latest, deploy, covered_to, covered_to < latest
            except Exception:
                continue

    # (C) chunked from genesis (logs indexed but state not archival)
    for chunk in chunks:
        try:
            logs, covered_to = _chunked(0, chunk)
            return logs, latest, 0, covered_to, covered_to < latest
        except Exception:
            continue
    raise RuntimeError("no chunk size works for eth_getLogs")


def decode_meta(sym, dec):
    try:
        d = int(dec, 16) if dec else 18
    except Exception:
        d = 18
    s = None
    if sym and len(sym) > 130:
        try:
            off = int(sym[2:66], 16)
            ln = int(sym[66 + off * 2:66 + off * 2 + 64], 16)
            s = bytes.fromhex(sym[66 + off * 2 + 64:66 + off * 2 + 64 + ln * 2]).decode("utf-8", "replace")
        except Exception:
            s = None
    elif sym and len(sym) == 66:
        try:
            s = bytes.fromhex(sym[2:]).rstrip(b"\x00").decode("utf-8", "replace")
        except Exception:
            s = None
    return s, d


def pick_call_rpc(rpcs, router):
    """First RPC that answers eth_call AND supports JSON-RPC batching."""
    for url in rpcs:
        if not url:
            continue
        try:
            r = rpc(url, "eth_call", [{"to": router, "data": "0x5c975abb"}, "latest"], retries=1)
            if not ("result" in r or "error" in r):
                continue
            b = rpc_batch(url, [("eth_call", [{"to": router, "data": "0x5c975abb"}, "latest"])], retries=1)
            if b and b[0] is not None:
                return url
        except Exception:
            continue
    # fall back: any RPC that answers eth_call (rpc_batch will do sequential calls)
    for url in rpcs:
        if not url:
            continue
        try:
            r = rpc(url, "eth_call", [{"to": router, "data": "0x5c975abb"}, "latest"], retries=1)
            if "result" in r or "error" in r:
                return url
        except Exception:
            continue
    raise RuntimeError("no rpc answers eth_call")


def census(chain, outdir="analysis/raw"):
    name = chain["name"]
    router = chain["router"]
    rpcs = [os.environ.get(e, "") for e in chain.get("rpc_env", [])] + chain.get("rpc_default", [])
    last_err = None
    source = None
    try:
        logs, latest, deploy, covered_to, partial = get_logs_etherscan(chain["chainId"], router)
        source = "etherscan_v2"
        url = pick_call_rpc(rpcs, router)
    except Exception as es_err:
        for url in rpcs:
            if not url:
                continue
            try:
                logs, latest, deploy, covered_to, partial = get_logs(url, router)
                source = "rpc"
                break
            except Exception as e:
                last_err = e
        else:
            raise RuntimeError(f"all sources failed: etherscan={es_err} rpc={last_err}")

    pairs = {}
    for l in logs:
        owner = "0x" + l["topics"][1][-40:]
        token = l["address"].lower()
        blk = int(l["blockNumber"], 16)
        key = (token, owner)
        if key not in pairs or blk >= pairs[key]:
            pairs[key] = blk
    print(f"[{name}] block={latest} deploy={deploy} covered_to={covered_to} partial={partial} logs={len(logs)} pairs={len(pairs)}", flush=True)

    keys = sorted(pairs)
    nonzero = []      # (token, owner, allowance)
    unread = []
    for i in range(0, len(keys), 20):
        chunk = keys[i:i + 20]
        calls = [("eth_call", [{"to": t, "data": "0x" + SEL_ALLOWANCE + pad(o)[2:] + pad(router)[2:]}, "latest"])
                 for (t, o) in chunk]
        try:
            res = rpc_batch(url, calls)
        except Exception:
            res = [None] * len(chunk)
        for j, (t, o) in enumerate(chunk):
            if res[j] is None:
                unread.append({"token": t, "owner": o, "what": "allowance"})
                continue
            try:
                a = int(res[j], 16)
            except Exception:
                a = 0
            if a > 0:
                nonzero.append((t, o, a))
        time.sleep(0.15)
    print(f"[{name}] nonzero allowances: {len(nonzero)}", flush=True)

    # balances only for nonzero allowances
    live = []
    for i in range(0, len(nonzero), 20):
        chunk = nonzero[i:i + 20]
        calls = [("eth_call", [{"to": t, "data": "0x" + SEL_BALANCE + pad(o)[2:]}, "latest"]) for (t, o, a) in chunk]
        try:
            res = rpc_batch(url, calls)
        except Exception:
            res = [None] * len(chunk)
        for j, (t, o, a) in enumerate(chunk):
            if res[j] is None:
                unread.append({"token": t, "owner": o, "what": "balance"})
                continue
            try:
                b = int(res[j], 16)
            except Exception:
                b = 0
            if b > 0:
                live.append({"chain": name, "chainId": chain["chainId"], "router": router,
                             "token": t, "owner": o, "allowance": str(a), "balance": str(b),
                             "lastApprovalBlock": pairs[(t, o)], "extractable_raw": str(min(a, b))})
        time.sleep(0.15)

    # metadata only for live tokens
    meta = {}
    tokens = sorted({p["token"] for p in live})
    for i in range(0, len(tokens), 20):
        chunk = tokens[i:i + 20]
        calls = []
        for t in chunk:
            calls.append(("eth_call", [{"to": t, "data": "0x" + SEL_DECIMALS}, "latest"]))
            calls.append(("eth_call", [{"to": t, "data": "0x" + SEL_SYMBOL}, "latest"]))
        try:
            res = rpc_batch(url, calls)
        except Exception:
            res = [None] * (2 * len(chunk))
        for j, t in enumerate(chunk):
            s, d = decode_meta(res[2 * j + 1], res[2 * j])
            meta[t] = {"symbol": s, "decimals": d}
    for p in live:
        m = meta.get(p["token"], {"symbol": None, "decimals": 18})
        p["symbol"] = m["symbol"]
        p["decimals"] = m["decimals"]

    os.makedirs(outdir, exist_ok=True)
    out = {"chain": name, "chainId": chain["chainId"], "router": router, "source": source, "latest_block": latest,
           "deploy_block": deploy, "covered_to_block": covered_to, "partial_coverage": partial,
           "approval_logs": len(logs), "unique_pairs": len(pairs), "live_positions": live,
           "unread_pairs": unread}
    with open(os.path.join(outdir, f"census_{name}.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(f"[{name}] LIVE positions: {len(live)} unread: {len(unread)}", flush=True)
    for p in live:
        print(f"    {p['symbol']} {p['token']} owner={p['owner']} allow={p['allowance']} bal={p['balance']}", flush=True)
    return out


if __name__ == "__main__":
    cfg = json.load(open(sys.argv[1]))
    outdir = sys.argv[2] if len(sys.argv) > 2 else "analysis/raw"
    only = sys.argv[3].split(",") if len(sys.argv) > 3 else None
    for c in cfg:
        if only and c["name"] not in only:
            continue
        try:
            census(c, outdir=outdir)
        except Exception as e:
            print(f"[{c['name']}] ERROR {e}", flush=True)
            os.makedirs(outdir, exist_ok=True)
            with open(os.path.join(outdir, f"census_{c['name']}.json"), "w") as f:
                json.dump({"chain": c["name"], "chainId": c["chainId"], "router": c["router"],
                           "error": str(e), "live_positions": []}, f, indent=1)
