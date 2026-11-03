#!/usr/bin/env python3
"""BlueMove (Sui) pool/escrow census at a pinned checkpoint.

Read-only. Enumerates every `swap::Pool` object, reads the dynamic-object-field
escrow for every pool that can possibly be desynced, and reports reserve vs
escrow deltas. Writes ci-out/bluemove_scan.json and prints a human summary.

The economic claim being tested: v12 `mint` computes
    delta_x = escrow_x - reserve_x  (u128 Sub -> underflow aborts)
    LP      = min(delta_x*supply/reserve_x, delta_y*supply/reserve_y)
so an LP-inflation profit needs escrow > reserve on BOTH sides (a "two-sided
desync"). v12 re-syncs reserve := escrow on every mint/burn; only legacy v1/v7
writes can leave escrow > reserve.
"""
import json, base64, time, urllib.request, sys, os

GRAPHQL = "https://graphql.mainnet.sui.io/graphql"
POOL_TYPE = ("0xb24b6789e088b876afabca733bed2299fbc9e2d6369be4d1acfa17d8145454d9"
             "::swap::Pool")
OUT = os.path.join("ci-out", "bluemove_scan.json")
HDRS = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}


def gql(query, tries=6):
    body = json.dumps({"query": query}).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(GRAPHQL, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.load(r)
            if d.get("errors"):
                last = d["errors"]
                # GraphQL validation errors are not retryable
                if any(e.get("extensions", {}).get("code") == "GRAPHQL_VALIDATION_FAILED"
                       for e in d["errors"]):
                    raise RuntimeError(d["errors"])
                time.sleep(2 + 2 * i)
                continue
            return d["data"]
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 + 2 * i)
    raise RuntimeError(f"graphql failed: {last}")


def escrow_of(pool):
    """Return (escrow_id, escrow_type, tx, ty) or None."""
    bcs = base64.b64encode(bytes.fromhex(pool.replace("0x", ""))).decode()
    q = ('{ object(address: "%s") { dynamicObjectField(name: {type: "0x2::object::ID", '
         'bcs: "%s"}) { contents { json type { repr } } } } }' % (pool, bcs))
    d = gql(q)
    o = (d.get("object") or {}).get("dynamicObjectField")
    if not o or not o.get("contents"):
        return None
    j = o["contents"]["json"]
    eid = j.get("value")
    if not eid:
        return None
    ej, etyp = object_json(eid)
    if ej is None:
        return None
    return eid, etyp, ej


def object_json(addr):
    q = '{ object(address: "%s") { asMoveObject { contents { json type { repr } } } } }' % addr
    d = gql(q)
    o = d.get("object")
    if not o or not o.get("asMoveObject") or not o["asMoveObject"].get("contents"):
        return None, None
    return o["asMoveObject"]["contents"]["json"], o["asMoveObject"]["contents"]["type"]["repr"]


def main():
    # checkpoint snapshot
    cp = gql("{ checkpoint { sequenceNumber timestamp } }")["checkpoint"]
    print(f"checkpoint={cp['sequenceNumber']} time={cp['timestamp']}")

    pools, cursor, pages = [], None, 0
    while True:
        after = f', after: "{cursor}"' if cursor else ""
        q = ('{ objects(filter: {type: "%s"}, first: 50%s) { nodes { address asMoveObject '
             '{ contents { json } } } pageInfo { hasNextPage endCursor } } }' % (POOL_TYPE, after))
        d = gql(q)["objects"]
        for n in d["nodes"]:
            j = n["asMoveObject"]["contents"]["json"]
            j["_addr"] = n["address"]
            pools.append(j)
        pages += 1
        if pages % 40 == 0:
            print(f"  enumerated {len(pools)} pools ({pages} pages)", flush=True)
        if not d["pageInfo"]["hasNextPage"]:
            break
        max_pages = int(os.environ.get("BM_MAX_PAGES", "0"))
        if max_pages and pages >= max_pages:
            print(f"  [test mode] stopping after {pages} pages")
            break
        cursor = d["pageInfo"]["endCursor"]

    print(f"enumerated {len(pools)} Pool objects in {pages} pages")

    def u(x):
        try:
            return int(x)
        except Exception:  # noqa: BLE001
            return 0

    legacy = [p for p in pools if u(p.get("token_x")) or u(p.get("token_y"))]
    top = sorted(pools, key=lambda p: max(u(p.get("reserve_x")), u(p.get("reserve_y"))),
                 reverse=True)[:int(os.environ.get("BM_TOP", "100"))]
    seen, candidates = set(), []
    for p in legacy + top:
        if p["_addr"] not in seen:
            seen.add(p["_addr"])
            candidates.append(p)
    for p in candidates:
        p["_legacy"] = bool(u(p.get("token_x")) or u(p.get("token_y")))
    print(f"legacy-balance pools: {len(legacy)}; top-by-reserve: {len(top)}; "
          f"union candidates: {len(candidates)}")

    stats = {"checked": 0, "with_escrow": 0, "v12": 0, "v7": 0, "other": 0,
             "both_nonneg": 0, "two_sided_desync": 0, "one_sided": 0,
             "underflow_any": 0, "underflow_both": 0, "no_escrow": 0}
    desynced, underflowed, one_sided = [], [], []

    for i, p in enumerate(candidates):
        if i % 100 == 0 and i:
            print(f"  escrow {i}/{len(candidates)}", flush=True)
        a = p["_addr"]
        rx, ry = u(p.get("reserve_x")), u(p.get("reserve_y"))
        tx, ty = u(p.get("token_x")), u(p.get("token_y"))
        stats["checked"] += 1
        try:
            e = escrow_of(a)
        except Exception as exc:  # noqa: BLE001
            print(f"  WARN escrow {a}: {exc}", flush=True)
            continue
        if not e:
            stats["no_escrow"] += 1
            continue
        eid, etyp, ej = e
        ex, ey = u(ej.get("token_x")), u(ej.get("token_y"))
        stats["with_escrow"] += 1
        if "EscrowCoinsV2" in etyp:
            stats["v12"] += 1
        elif "EscownCoins" in etyp:
            stats["v7"] += 1
        else:
            stats["other"] += 1
        dx, dy = ex - rx, ey - ry
        rec = {"pool": a, "escrow": eid, "legacy": bool(p.get("_legacy")),
               "escrow_type": etyp.split("<")[0],
               "reserve": [rx, ry], "escrow_amounts": [ex, ey],
               "token_legacy": [tx, ty], "dx": dx, "dy": dy,
               "dtype": "v12" if "EscrowCoinsV2" in etyp else ("v7" if "EscownCoins" in etyp else "other")}
        if dx < 0 or dy < 0:
            stats["underflow_any"] += 1
            if dx < 0 and dy < 0:
                stats["underflow_both"] += 1
                underflowed.append(rec)
            elif len(one_sided) < 20:
                one_sided.append(rec)
        elif dx > 0 or dy > 0:
            stats["both_nonneg"] += 1
            if dx > 0 and dy > 0:
                stats["two_sided_desync"] += 1
                desynced.append(rec)
            else:
                stats["one_sided"] += 1
                if len(one_sided) < 20:
                    one_sided.append(rec)
        max_esc = int(os.environ.get("BM_MAX_ESCROW", "0"))
        if max_esc and i + 1 >= max_esc:
            print(f"  [test mode] stopping after {max_esc} escrows")
            break

    out = {"checkpoint": cp, "pool_type": POOL_TYPE, "pools_enumerated": len(pools),
           "legacy_pools": len(legacy), "top_by_reserve": len(top),
           "candidates": len(candidates), "stats": stats,
           "two_sided_desync": desynced, "underflow_both": underflowed[:20],
           "one_sided_sample": one_sided}
    os.makedirs("ci-out", exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(stats, indent=1))
    print(f"two-sided desync pools: {len(desynced)}")
    for r in desynced[:10]:
        print(" ", r["pool"], r["dtype"], "reserve", r["reserve"], "escrow", r["escrow_amounts"],
              "delta", r["dx"], r["dy"])
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
