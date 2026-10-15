#!/usr/bin/env python3
"""
EtherVista bytecode-vs-verified-source diff — Z3-C5 deep-dive (read-only).

For the pair 0xfdd05552..., the router 0x9bD63C5D... and the factory 0x9a27cb5b...:
  1. fetch live runtime code (eth_getCode) at one pinned block
  2. compile the exact Etherscan-verified standard-JSON with the matching solc
  3. compare: executable code (everything except the trailing CBOR metadata) and
     the metadata tail separately (bzzr1 source hash may differ if Etherscan
     normalised the source text; it is not executable)
  4. for the pair: extract the deployed creation code from the factory runtime
     (the factory embeds type(EtherVistaPair).creationCode), validate it against
     the factory's on-chain INIT_CODE_HASH, and re-derive the pair address with
     CREATE2 from that creation code.

Outputs analysis/bytecode_diff.json + ci-out/bytecode_diff.json + *.hex dumps.
No secrets. Read-only.
"""
import json
import os
import subprocess
import sys
import urllib.request
import hashlib

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.abspath(os.environ.get("OUTDIR", os.path.join(HERE, "..", "ci-out")))

PAIR = "0xfdd05552F1377aA488AFed744c8024358AF02041"
FACTORY = "0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4"
ROUTER = "0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
VISTA = "0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf"
INIT_CODE_HASH = "0xe260b72768e8ec6814aa811c576f346d208ba00840f835949d65c6424ac80a8d"

SOLC_URLS = {
    "0.5.16": "https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.5.16+commit.9c3226ce",
    "0.6.6": "https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.6.6+commit.6c089d02",
}

RPC_CANDIDATES = [os.environ.get("FORK_RPC_URL", ""), os.environ.get("RPC_URL", ""),
                  "https://ethereum-rpc.publicnode.com", "https://eth.drpc.org"]
RPC_CANDIDATES = [u for u in RPC_CANDIDATES if u]
UA = {"User-Agent": "zombie-research/1.0"}

# ---------------- pure-python keccak256 (validated against known vectors) ----------------
RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
      0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
      0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
      0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
      0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
      0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
ROT = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
MASK = (1 << 64) - 1


def _rotl(v, n):
    if n == 0:
        return v
    return ((v << n) | (v >> (64 - n))) & MASK


def _keccak_f(state):
    for rnd in range(24):
        c = [state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20] for x in range(5)]
        d = [c[(x + 4) % 5] ^ _rotl(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(0, 25, 5):
                state[x + y] ^= d[x]
        b = [0] * 25
        for x in range(5):
            for y in range(5):
                b[y + 5 * ((2 * x + 3 * y) % 5)] = _rotl(state[x + 5 * y], ROT[x][y])
        for x in range(5):
            for y in range(0, 25, 5):
                state[x + y] = (b[x + y] ^ ((~b[(x + 1) % 5 + y]) & b[(x + 2) % 5 + y])) & MASK
        state[0] ^= RC[rnd]
    return state


def keccak256(data: bytes) -> bytes:
    rate = 136
    padded = bytearray(data)
    padded.append(0x01)
    while len(padded) % rate != 0:
        padded.append(0x00)
    padded[-1] |= 0x80
    state = [0] * 25
    for off in range(0, len(padded), rate):
        block = padded[off:off + rate]
        for i in range(rate // 8):
            state[i] ^= int.from_bytes(block[i * 8:(i + 1) * 8], "little")
        _keccak_f(state)
    return b"".join(s.to_bytes(8, "little") for s in state)[:32]


assert keccak256(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470", "keccak self-test failed"
assert keccak256(b"transfer(address,uint256)").hex()[:8] == "a9059cbb", "keccak selector self-test failed"


def rpc(method, params, url):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=payload, headers={**UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        j = json.loads(r.read().decode())
    if "result" not in j:
        raise RuntimeError(str(j.get("error"))[:200])
    return j["result"]


def pick_rpc():
    for u in RPC_CANDIDATES:
        try:
            b = rpc("eth_blockNumber", [], u)
            print(f"[rpc] ok, block={int(b, 16)}", flush=True)
            return u, int(b, 16)
        except Exception as e:
            print(f"[rpc] fail {type(e).__name__}", flush=True)
    raise RuntimeError("no rpc")


def ensure_solc(version):
    env = os.environ.get("SOLC_" + version.replace(".", "_"))
    if env and os.path.exists(env):
        return env
    # look in PATH and ~/.svm
    for c in [f"solc-{version}", f"solc{version}", "solc"]:
        p = subprocess.run(["bash", "-lc", f"command -v {c} || true"], capture_output=True, text=True).stdout.strip()
        if p:
            v = subprocess.run([p, "--version"], capture_output=True, text=True).stdout
            if version in v:
                return p
    for root in [os.path.expanduser("~/.svm"), "/tmp/opencode", "/root", os.path.expanduser("~/.foundry")]:
        for dirpath, _, files in os.walk(root) if os.path.isdir(root) else []:
            for fn in files:
                if version in fn and "solc" in fn:
                    p = os.path.join(dirpath, fn)
                    if os.access(p, os.X_OK):
                        v = subprocess.run([p, "--version"], capture_output=True, text=True).stdout
                        if version in v:
                            return p
    # download
    dst = f"/tmp/solc-{version}"
    if not os.path.exists(dst):
        print(f"[solc] downloading {version}", flush=True)
        req = urllib.request.Request(SOLC_URLS[version], headers=UA)
        with urllib.request.urlopen(req, timeout=180) as r, open(dst, "wb") as f:
            f.write(r.read())
        os.chmod(dst, 0o755)
    return dst


def compile_stdjson(stdjson, solc, contract_name):
    out = subprocess.run([solc, "--standard-json"], input=json.dumps(stdjson), capture_output=True, text=True)
    res = json.loads(out.stdout)
    errs = [e for e in res.get("errors", []) if e.get("severity") == "error"]
    if errs:
        raise RuntimeError("compile errors: " + str(errs[:1])[:400])
    for fname, contracts in res["contracts"].items():
        if contract_name in contracts:
            c = contracts[contract_name]
            return (bytes.fromhex(c["evm"]["bytecode"]["object"]),
                    bytes.fromhex(c["evm"]["deployedBytecode"]["object"]),
                    fname)
    raise RuntimeError("contract not found: " + contract_name)


def meta_region(code):
    """returns (start_offset_of_metadata_incl_length, mlen) for solc >=0.5 CBOR tail"""
    mlen = int.from_bytes(code[-2:], "big")
    if mlen <= 0 or mlen > 200 or code[-2 - mlen] != 0xA2:
        return None, 0
    return len(code) - 2 - mlen, mlen


def compare(name, onchain_code, compiled_runtime, results, immutables=(), extra_meta_ranges=()):
    """immutables: list of 20-byte values that may fill immutable slots.
    extra_meta_ranges: absolute (start,end) ranges in the onchain code that are
    known non-executable (e.g. metadata of embedded creation code)."""
    r = {"onchain_len": len(onchain_code), "compiled_len": len(compiled_runtime)}
    if onchain_code == compiled_runtime:
        r.update({"full_match": True, "executable_match": True, "metadata_match": True, "diff_bytes": 0})
    else:
        n = min(len(onchain_code), len(compiled_runtime))
        diffs = [i for i in range(n) if onchain_code[i] != compiled_runtime[i]]
        mstart, mlen = meta_region(onchain_code)
        mstart_c, mlen_c = meta_region(compiled_runtime)
        own_meta = set()
        if mstart is not None:
            own_meta = set(range(mstart, len(onchain_code)))
        emb_meta = set()
        for (a, b) in extra_meta_ranges:
            emb_meta.update(range(a, b))
        imm_fill = set()
        for i in diffs:
            for v in immutables:
                for s in range(max(0, i - 19), i + 1):
                    if onchain_code[s:s + 20] == v and all(j in diffs for j in range(s, s + 20)):
                        imm_fill.update(range(s, s + 20))
        ex_match = None
        if mstart is not None:
            ex_match = onchain_code[:mstart] == compiled_runtime[:mstart_c]
        unclassified = [i for i in diffs if i not in own_meta and i not in emb_meta and i not in imm_fill]
        r.update({
            "full_match": False,
            "executable_match": ex_match,
            "metadata_match": (mstart is not None and mstart_c is not None
                               and onchain_code[mstart:] == compiled_runtime[mstart_c:]),
            "diff_bytes": len(diffs),
            "diff_range": [diffs[0], diffs[-1]] if diffs else None,
            "diff_classification": {
                "own_metadata_bytes": len([i for i in diffs if i in own_meta]),
                "embedded_metadata_bytes": len([i for i in diffs if i in emb_meta]),
                "immutable_slot_bytes": len([i for i in diffs if i in imm_fill]),
                "unclassified_bytes": len(unclassified),
                "unclassified_sample": unclassified[:20],
            },
            "metadata_start": mstart, "metadata_len": mlen,
            "onchain_meta_tail": onchain_code[mstart:].hex() if mstart is not None else None,
            "compiled_meta_tail": compiled_runtime[mstart_c:].hex() if mstart_c is not None else None,
        })
    results[name] = r
    print(f"[diff] {name}: full={r['full_match']} exec={r.get('executable_match')} "
          f"diff_bytes={r.get('diff_bytes')} class={r.get('diff_classification')}", flush=True)
    return r


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    url, block = pick_rpc()

    onchain = {
        "pair": bytes.fromhex(rpc("eth_getCode", [PAIR, "latest"], url).removeprefix("0x")),
        "router": bytes.fromhex(rpc("eth_getCode", [ROUTER, "latest"], url).removeprefix("0x")),
        "factory": bytes.fromhex(rpc("eth_getCode", [FACTORY, "latest"], url).removeprefix("0x")),
    }
    init_code_hash = rpc("eth_call", [{"to": FACTORY, "data": "0x257671f5"}, "latest"], url)
    print(f"[chain] init_code_hash={init_code_hash}", flush=True)

    results = {"block": block, "pair": PAIR, "router": ROUTER, "factory": FACTORY,
               "init_code_hash_onchain": init_code_hash, "checks": {}}

    # ---------- pair ----------
    std = json.load(open(os.path.join(HERE, "verified_pair.json")))
    std.pop("_etherscan", None)
    solc = ensure_solc("0.5.16")
    creation, runtime, fname = compile_stdjson(std, solc, "EtherVistaPair")
    r = compare("pair", onchain["pair"], runtime, results["checks"])
    results["checks"]["pair"]["compiled_file"] = fname

    # extract deployed creation code from the factory runtime
    probe = creation[:32]
    idx = onchain["factory"].find(probe)
    dep = None
    rt_off = -1
    if idx >= 0:
        cand = onchain["factory"][idx:idx + len(creation)]
        if keccak256(cand).hex() == init_code_hash.removeprefix("0x").lower():
            dep = cand
    results["checks"]["pair"]["creation_extracted_from_factory"] = dep is not None
    if dep is not None:
        open(os.path.join(HERE, "pair_creation_deployed.hex"), "w").write("0x" + dep.hex())
        # embedded runtime == on-chain runtime?
        rt_off = dep.find(runtime[:32])
        emb = dep[rt_off:rt_off + len(onchain["pair"])] if rt_off >= 0 else None
        # diff deployed creation vs compiled creation
        d = [i for i in range(len(dep)) if dep[i] != creation[i]] if len(dep) == len(creation) else None
        mstart, mlen = meta_region(dep[rt_off:rt_off + len(runtime)]) if rt_off >= 0 else (None, 0)
        results["checks"]["pair"]["creation_vs_compiled"] = {
            "deployed_len": len(dep), "compiled_len": len(creation),
            "diff_bytes": len(d) if d is not None else None,
            "diff_range": [d[0], d[-1]] if d else None,
            "all_diffs_in_runtime_metadata": (d is not None and bool(d) and mstart is not None
                                              and d[0] >= rt_off + mstart and d[-1] < rt_off + len(runtime) - 2),
        }
        results["checks"]["pair"]["embedded_runtime_offset"] = rt_off
        results["checks"]["pair"]["embedded_runtime_equals_onchain"] = (emb == onchain["pair"])
        # CREATE2 derivation
        t0 = bytes.fromhex(WETH[2:].lower())
        t1 = bytes.fromhex(VISTA[2:].lower())
        salt = keccak256(t0 + t1)
        derived = keccak256(b"\xff" + bytes.fromhex(FACTORY[2:].lower()) + salt + keccak256(dep))[12:]
        results["checks"]["pair"]["create2_derived"] = "0x" + derived.hex()
        results["checks"]["pair"]["create2_matches"] = ("0x" + derived.hex()).lower() == PAIR.lower()
    open(os.path.join(HERE, "pair_runtime.hex"), "w").write("0x" + onchain["pair"].hex())
    open(os.path.join(HERE, "factory_runtime.hex"), "w").write("0x" + onchain["factory"].hex())

    # ---------- router ----------
    std = json.load(open(os.path.join(HERE, "verified_router.json")))
    std.pop("_etherscan", None)
    solc = ensure_solc("0.6.6")
    creation_r, runtime_r, fname_r = compile_stdjson(std, solc, "EtherVistaRouter")
    compare("router", onchain["router"], runtime_r, results["checks"],
            immutables=[bytes.fromhex(FACTORY[2:].lower()), bytes.fromhex(WETH[2:].lower())])

    # ---------- factory ----------
    std = json.load(open(os.path.join(HERE, "verified_factory.json")))
    std.pop("_etherscan", None)
    solc = ensure_solc("0.5.16")
    creation_f, runtime_f, fname_f = compile_stdjson(std, solc, "EtherVistaFactory")
    extra = []
    if dep is not None and rt_off >= 0:
        mstart_pair, _ = meta_region(dep[rt_off:rt_off + len(onchain["pair"])])
        if mstart_pair is not None:
            a = idx + rt_off + mstart_pair
            b = idx + rt_off + len(onchain["pair"]) - 2
            extra.append((a, b))
    compare("factory", onchain["factory"], runtime_f, results["checks"], extra_meta_ranges=extra)

    with open(os.path.join(HERE, "bytecode_diff.json"), "w") as f:
        json.dump(results, f, indent=2)
    with open(os.path.join(OUTDIR, "bytecode_diff.json"), "w") as f:
        json.dump(results, f, indent=2)
    print(json.dumps({k: {kk: vv for kk, vv in v.items() if kk in ("full_match", "executable_match", "diff_bytes")}
                      for k, v in results["checks"].items()}, indent=2), flush=True)


if __name__ == "__main__":
    main()
