#!/usr/bin/env python3
"""ZH4-02 Startale Earn (Soneium) — recent-epoch scan + JIT deposit census.

Read-only. Public keyless RPC only (no secrets). Usage:
    python3 scan_epochs.py [LOOKBACK_BLOCKS] [OUT_JSON]

Fetches RR Distributed / VaultTVLsSnapshotCaptured events and EarnVault
Deposit / Withdraw / InterestClaimed / YieldIndexed events over the lookback
window, and classifies every deposit relative to its epoch window:
  - PRE_SNAPSHOT   : deposit in [snapshotBlock-10, snapshotBlock)   (Play P signature)
  - IN_WINDOW      : deposit in (snapshotBlock, distributeBlock]    (Play W signature)
  - OTHER          : anywhere else
Also reports per-epoch minted/toEarn stats.
"""
import json, sys, urllib.request, time

RPC = "https://rpc.soneium.org"
BS = "https://soneium.blockscout.com/api"          # keyless public explorer API (log paging)
RR = "0xda798684ffD5eb509c2Ab7b8352EC55B31F18201"
VAULT = "0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0"
USDSC = "0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a"

TOPIC_DISTRIBUTED = "0x"  # filled below
TOPIC_SNAPSHOT = "0x"
TOPIC_DEPOSIT = "0x"
TOPIC_WITHDRAW = "0x"
TOPIC_YIELDINDEXED = "0x"


def keccak_topic(sig: str) -> str:
    # tiny keccak256 via eth RPC? -> use web3-free implementation below (pure python keccak)
    import hashlib
    return _keccak_256(sig.encode()).hex()


# ---- minimal pure-python keccak-256 (public-domain style, compact) ----
def _keccak_256(data: bytes) -> bytes:
    RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
          0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
          0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
          0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
          0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
          0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
    R = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61],
         [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
    def rol(x, n): return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF
    def f(A):
        for rnd in range(24):
            C = [A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4] for x in range(5)]
            D = [C[(x - 1) % 5] ^ rol(C[(x + 1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    A[x][y] ^= D[x]
            B = [[0] * 5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2 * x + 3 * y) % 5] = rol(A[x][y], R[x][y])
            for x in range(5):
                for y in range(5):
                    A[x][y] = B[x][y] ^ ((~B[(x + 1) % 5][y]) & B[(x + 2) % 5][y])
            A[0][0] ^= RC[rnd]
        return A
    rate = 136
    st = [[0] * 5 for _ in range(5)]
    data = bytearray(data)
    data.append(0x01)
    while len(data) % rate != 0:
        data.append(0x00)
    data[-1] ^= 0x80
    for off in range(0, len(data), rate):
        blk = data[off:off + rate]
        for i in range(rate // 8):
            lane = int.from_bytes(blk[i * 8:(i + 1) * 8], "little")
            st[i % 5][i // 5] ^= lane
        st = f(st)
    out = b""
    for i in range(4):
        out += st[i % 5][i // 5].to_bytes(8, "little")
    return out


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research; read-only)"})
    for attempt in range(10):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"]
            raise RuntimeError(j.get("error"))
        except urllib.error.HTTPError as e:
            if attempt == 9:
                raise
            # public Soneium RPC rate-limits bursts; 429 needs a long cool-down
            time.sleep(60 if e.code == 429 else 3 * (attempt + 1))
        except Exception:
            if attempt == 9:
                raise
            time.sleep(3 * (attempt + 1))


def _http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (research; read-only)"})
    for attempt in range(8):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                j = json.loads(r.read())
            time.sleep(1.2)  # be polite: Blockscout rate-limits bursts
            return j
        except urllib.error.HTTPError as e:
            if attempt == 7:
                raise
            time.sleep(6 * (attempt + 1) if e.code == 429 else 2 * (attempt + 1))
        except Exception:
            if attempt == 7:
                raise
            time.sleep(2 * (attempt + 1))


def get_logs(addr, topics, frm, to):
    """eth_getLogs over the public Soneium RPC (1000-block max range), topic-filtered.

    Blockscout's public /api logs endpoint returns HTTP 429 under this load, and the
    node caps block ranges at 1000, so chunk accordingly.
    """
    topic = topics[0]
    out, chunk = [], 1000
    b = frm
    while b <= to:
        e = min(b + chunk - 1, to)
        res = rpc("eth_getLogs", [{
            "address": addr, "fromBlock": hex(b), "toBlock": hex(e), "topics": [topic],
        }])
        time.sleep(0.15)  # stay under the public RPC's burst limit
        for r in res:
            out.append({"address": r["address"], "blockNumber": r["blockNumber"],
                        "transactionHash": r["transactionHash"], "data": r["data"],
                        "topics": r["topics"], "timeStamp": None})
        b = e + 1
    return out


def get_block_timestamps(blocks):
    """Batch eth_getBlockByNumber (JSON-RPC batch of 40) for unique block numbers."""
    uniq = sorted(set(blocks))
    out = {}
    for i in range(0, len(uniq), 40):
        part = uniq[i:i + 40]
        reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_getBlockByNumber",
                 "params": [hex(b), False]} for j, b in enumerate(part)]
        body = json.dumps(reqs).encode()
        req = urllib.request.Request(RPC, data=body, headers={
            "Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research; read-only)"})
        for attempt in range(6):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    js = json.loads(r.read())
                break
            except Exception:
                if attempt == 5:
                    raise
                time.sleep(2 * (attempt + 1))
        for item in js:
            res = item.get("result")
            if res:
                out[int(res["number"], 16)] = int(res["timestamp"], 16)
        time.sleep(0.2)
    return out


def main():
    lookback = int(sys.argv[1]) if len(sys.argv) > 1 else 200000
    out_path = sys.argv[2] if len(sys.argv) > 2 else "recent_epochs.json"

    latest = int(rpc("eth_blockNumber", []), 16)
    frm = latest - lookback

    t_dist = "0x" + keccak_topic("Distributed(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)")
    t_snap = "0x" + keccak_topic("VaultTVLsSnapshotCaptured(uint256,uint256,uint256,uint256)")
    t_dep = "0x" + keccak_topic("Deposit(address,uint256)")
    t_wd = "0x" + keccak_topic("Withdraw(address,uint256)")
    t_yi = "0x" + keccak_topic("YieldIndexed(uint256,uint256,uint256)")

    dist = get_logs(RR, [t_dist], frm, latest)
    snap = get_logs(RR, [t_snap], frm, latest)
    deps = get_logs(VAULT, [t_dep], frm, latest)
    wds = get_logs(VAULT, [t_wd], frm, latest)
    yis = get_logs(VAULT, [t_yi], frm, latest)

    def u(h): return int(h, 16)
    def w(i, h): return u(h) / 1e6
    def words(data):
        h = data[2:] if data.startswith("0x") else data
        return [int(h[i:i + 64], 16) for i in range(0, len(h), 64)]

    block_ts = get_block_timestamps(
        [u(d["blockNumber"]) for d in dist]
        + [u(s["blockNumber"]) for s in snap]
        + [u(d["blockNumber"]) for d in deps]
        + [u(x["blockNumber"]) for x in wds]
        + [u(x["blockNumber"]) for x in yis]
    )

    def ts(bn):
        return block_ts.get(bn, 0)

    epochs = []
    for i, d in enumerate(dist):
        blk = u(d["blockNumber"])
        wd = words(d["data"])
        if len(wd) < 8:
            raise RuntimeError(f"Distributed data has {len(wd)} words: {d['data'][:80]}")
        minted, fee, to_earn, to_on, extra, s_base, t_earn, t_y = wd[:8]
        # pair with the most recent snapshot before this block
        snap_for = None
        for s in reversed(snap):
            if u(s["blockNumber"]) <= blk:
                snap_for = s
                break
        epochs.append({
            "dist_block": blk, "dist_ts": None, "minted": minted / 1e6,
            "fee": fee / 1e6, "toEarn": to_earn / 1e6, "toOn": to_on / 1e6,
            "toStartaleExtra": extra / 1e6, "S_base": s_base / 1e6, "T_earn": t_earn / 1e6,
            "T_yield": t_y / 1e6,
            "snap_block": u(snap_for["blockNumber"]) if snap_for else None,
            "snap_ts": None,
            "tx": d["transactionHash"],
        })
    for e in epochs:
        e["dist_ts"] = ts(e["dist_block"])
        if e["snap_block"]:
            e["snap_ts"] = ts(e["snap_block"])

    # classify deposits
    deps_out = []
    for d in deps:
        blk = u(d["blockNumber"])
        user = "0x" + d["topics"][1][-40:]
        amt = w(0, d["data"])
        cls = "OTHER"
        ep = None
        for e in epochs:
            if e["snap_block"] and e["snap_block"] - 10 <= blk < e["snap_block"]:
                cls, ep = "PRE_SNAPSHOT", e
                break
            if e["snap_block"] and e["snap_block"] < blk <= e["dist_block"]:
                cls, ep = "IN_WINDOW", e
                break
        deps_out.append({"block": blk, "ts": ts(blk), "user": user, "amount": amt,
                         "class": cls, "epoch_dist_block": ep["dist_block"] if ep else None,
                         "tx": d["transactionHash"]})

    wds_out = [{"block": u(x["blockNumber"]), "ts": ts(u(x["blockNumber"])),
                "user": "0x" + x["topics"][1][-40:], "amount": w(0, x["data"]),
                "tx": x["transactionHash"]} for x in wds]

    yis_out = [{"block": u(x["blockNumber"]), "amount": w(0, x["data"][:66]),
                "tx": x["transactionHash"]} for x in yis]

    res = {
        "rpc_latest_block": latest, "from_block": frm, "lookback": lookback,
        "epochs": epochs, "deposits": deps_out, "withdraws": wds_out, "yield_indexed": yis_out,
        "counts": {"epochs": len(epochs), "deposits": len(deps_out), "withdraws": len(wds_out),
                   "PRE_SNAPSHOT": sum(1 for d in deps_out if d["class"] == "PRE_SNAPSHOT"),
                   "IN_WINDOW": sum(1 for d in deps_out if d["class"] == "IN_WINDOW")},
    }
    with open(out_path, "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res["counts"], indent=1))
    print("epochs (last 12):")
    for e in epochs[-12:]:
        print(f"  dist_blk={e['dist_block']} snap_blk={e['snap_block']} minted=${e['minted']:.4f} "
              f"toEarn=${e['toEarn']:.4f} S_base=${e['S_base']:.0f} T_earn=${e['T_earn']:.0f}")


if __name__ == "__main__":
    main()
