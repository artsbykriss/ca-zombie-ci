#!/usr/bin/env python3
"""
Bytecode-level identity proof for the Kolan LaunchHook vs the main KolanHook.

CI-only heavy job. Downloads solc 0.8.26, recompiles the two Sourcify source bundles
each with its OWN exact recorded settings (incl. viaIR and the exact remapping list),
then compares the recompiled runtime bytecode to the live on-chain bytecode with the
immutable slots masked (via compiler `immutableReferences`).

Result: proves the deployed runtime code IS the verified source (byte-for-byte, up to
the non-executable IPFS metadata hash).

No secrets; keyless public RPCs + Sourcify only.
"""
import json, os, sys, subprocess, urllib.request, hashlib, shutil

SOLC_VER = "0.8.26+commit.8a97fa7a"
SOLC_URL = f"https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v{SOLC_VER}"
MAIN = "0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC"        # main KolanHook
LAUNCHPAD = "0x8F89905624E3613b3A578Ff1EC690463A33e940e"  # launchpad (its build embeds LaunchHook)
LAUNCHHOOK_LIVE = "0xc75059b9e101483ca3261ca3fdd65bf85a1528ec"  # an actually-deployed LaunchHook
RPC_URLS = ["https://eth.drpc.org", "https://eth-mainnet.public.blastapi.io",
            "https://rpc.mevblocker.io", "https://ethereum-rpc.publicnode.com"]

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out"))

def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "zh4/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r)

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for u in RPC_URLS:
        try:
            req = urllib.request.Request(u, data=body,
                                         headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.load(r)
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = repr(e)
    raise RuntimeError(f"{method}: {last}")

def ensure_solc():
    path = f"/tmp/solc-{SOLC_VER}"
    if os.path.exists(path):
        return path
    for u in [SOLC_URL, "https://github.com/ethereum/solidity/releases/download/v0.8.26/solc-static-linux"]:
        try:
            print(f"[solc] downloading {u}")
            req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 zh4/1.0"})
            with urllib.request.urlopen(req, timeout=240) as r, open(path, "wb") as f:
                shutil.copyfileobj(r, f)
            os.chmod(path, 0o755)
            return path
        except Exception as e:
            print(f"[solc] failed {u}: {e!r}")
    raise RuntimeError("could not download solc")

def fetch_bundle(addr):
    return http_json(f"https://sourcify.dev/server/v2/contract/1/{addr}?fields=sources,compilation")

def compile_bundle(solc, bundle, cache_path):
    """Compile one Sourcify bundle with its exact recorded settings/remappings."""
    if os.path.exists(cache_path):
        with open(cache_path) as f:
            return json.load(f)
    settings = bundle["compilation"]["compilerSettings"]
    inp = {
        "language": "Solidity",
        "sources": {k: {"content": v["content"]} for k, v in bundle["sources"].items()},
        "settings": {
            "viaIR": settings.get("viaIR", True),
            "optimizer": settings.get("optimizer", {"enabled": True, "runs": 200}),
            "evmVersion": settings.get("evmVersion", "cancun"),
            "metadata": settings.get("metadata", {"bytecodeHash": "ipfs"}),
            "remappings": settings.get("remappings", []),
            "outputSelection": {"*": {"*": [
                "evm.deployedBytecode.object",
                "evm.deployedBytecode.sourceMap",
                "evm.deployedBytecode.immutableReferences",
            ]}},
        },
    }
    p = subprocess.run([solc, "--standard-json"], input=json.dumps(inp).encode(),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = json.loads(p.stdout.decode())
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        print("[solc] ERRORS:", json.dumps(errs)[:3000])
        raise RuntimeError("solc compile failed")
    with open(cache_path, "w") as f:
        json.dump(out, f)
    return out

def mask(code: bytes, refs) -> bytes:
    b = bytearray(code)
    for _, arr in (refs or {}).items():
        for r in arr:
            for i in range(r["start"], r["start"] + r["length"]):
                b[i] = 0
    return bytes(b)

def hexb(s):
    return bytes.fromhex(s[2:])

def keccak256(b: bytes) -> str:
    try:
        from Crypto.Hash import keccak
        h = keccak.new(digest_bits=256); h.update(b); return "0x" + h.hexdigest()
    except Exception:
        return "0x" + hashlib.sha256(b).hexdigest() + "!sha256"

def disasm_offsets(code: bytes):
    out, p, n = [], 0, len(code)
    while p < n:
        op = code[p]
        ln = 32 if op == 0x7f else (op - 0x5f if 0x60 <= op <= 0x7f else 0)
        out.append((p, op, ln)); p += 1 + ln
    return out

def parse_sourcemap(sm):
    entries, src, ln, f, j = [], 0, 0, 0, ""
    for part in sm.split(";"):
        if part:
            fs = part.split(":")
            if fs[0] != "": src = int(fs[0])
            if len(fs) > 1 and fs[1] != "": ln = int(fs[1])
            if len(fs) > 2 and fs[2] != "": f = int(fs[2])
            if len(fs) > 3 and fs[3] != "": j = fs[3]
        entries.append({"s": src, "l": ln, "f": f, "j": j})
    return entries

def find_function_range(text, header):
    i = text.find(header)
    if i < 0:
        return None
    depth, started = 0, False
    for k in range(i, len(text)):
        c = text[k]
        if c == "{": depth += 1; started = True
        elif c == "}":
            depth -= 1
            if started and depth == 0:
                return (i, k + 1)
    return None

def accept_region(deployed_hex, source_map, src_id, src_text):
    rng = find_function_range(src_text, "function accept(uint256 id) external nonReentrant")
    if rng is None:
        return None
    fstart, fend = rng
    code = hexb(deployed_hex)
    offs = disasm_offsets(code)
    sm = parse_sourcemap(source_map)
    n = min(len(offs), len(sm))
    sel = []
    for i in range(n):
        e = sm[i]
        if e["f"] == src_id and fstart <= e["s"] < fend:
            pc, op, ln = offs[i]
            sel.append({"pc": pc, "bytes": code[pc:pc + 1 + ln]})
    return sel

def instr_digest(sel, refs):
    ranges = [(r["start"], r["start"] + r["length"]) for arr in (refs or {}).values() for r in arr]
    blob = bytearray()
    for s in sel:
        b = bytearray(s["bytes"])
        for a, z in ranges:
            for i in range(max(a, s["pc"]), min(z, s["pc"] + len(b))):
                b[i - s["pc"]] = 0
        blob += bytes(b)
    return bytes(blob)

def compare_contract(label, bundle, out, contract_file, contract_name, onchain_addr, result):
    art = out["contracts"].get(contract_file, {}).get(contract_name)
    if not art:
        result[label] = {"error": f"{contract_name} not in output"}
        return None
    obj = art["evm"]["deployedBytecode"]["object"]
    refs = art["evm"]["deployedBytecode"].get("immutableReferences", {})
    sm = art["evm"]["deployedBytecode"]["sourceMap"]
    compiled = hexb("0x" + obj)
    oc = hexb(rpc("eth_getCode", [onchain_addr, "latest"]))
    masked = mask(oc, refs)
    diffs = [i for i in range(min(len(masked), len(compiled))) if masked[i] != compiled[i]]
    if len(masked) != len(compiled):
        diffs += list(range(min(len(masked), len(compiled)), max(len(masked), len(compiled))))
    # metadata CBOR tail = the last occurrence of the 'a2 64 "ipfs"' marker to EOF
    marker = bytes.fromhex("a26469706673")
    ti = compiled.rfind(marker)
    tail_start = ti if ti >= 0 else len(compiled) - 53
    diffs_code = [i for i in diffs if i < tail_start]
    result[label] = {
        "onchain_size": len(oc),
        "compiled_size": len(compiled),
        "n_immutable_ref_slots": sum(len(v) for v in refs.values()),
        "masked_onchain_keccak": keccak256(masked),
        "compiled_keccak": keccak256(compiled),
        "diff_count_total": len(diffs),
        "diff_count_in_code_body": len(diffs_code),
        "diff_offsets_sample": diffs[:12],
        "metadata_tail_start": tail_start,
        "code_body_exact_match": (len(masked) == len(compiled) and len(diffs_code) == 0),
        "diffs_only_in_metadata_tail": all(i >= tail_start for i in diffs),
        "exact_match_after_masking": (len(masked) == len(compiled) and len(diffs) == 0),
    }
    with open(os.path.join(OUT_DIR, f"{label}_onchain.hex"), "w") as f:
        f.write(oc.hex())
    with open(os.path.join(OUT_DIR, f"{label}_compiled.hex"), "w") as f:
        f.write(compiled.hex())
    # accept region
    src_id = out.get("sources", {}).get(contract_file, {}).get("id")
    src_text = bundle["sources"][contract_file]["content"]
    sel = accept_region(obj, sm, src_id, src_text)
    if sel is not None:
        d = instr_digest(sel, refs)
        result[label]["accept_instr_count"] = len(sel)
        result[label]["accept_seq_len"] = len(d)
        result[label]["accept_seq_keccak"] = keccak256(d)
        return d
    return None

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    result = {"solc": SOLC_VER, "rpc": RPC_URLS[0]}
    solc = ensure_solc()
    kh = fetch_bundle(MAIN)
    lp = fetch_bundle(LAUNCHPAD)
    result["sourcify_match"] = {"KolanHook": kh.get("match"), "KolanHook_runtime": kh.get("runtimeMatch"),
                                "Launchpad": lp.get("match"), "Launchpad_runtime": lp.get("runtimeMatch")}
    out_kh = compile_bundle(solc, kh, "/tmp/out_kh.json")
    out_lp = compile_bundle(solc, lp, "/tmp/out_lp.json")
    a = compare_contract("KolanHook", kh, out_kh, "src/KolanHook.sol", "KolanHook", MAIN, result)
    b = compare_contract("LaunchHook", lp, out_lp, "src/LaunchHook.sol", "LaunchHook", LAUNCHHOOK_LIVE, result)
    if a is not None and b is not None:
        n = min(len(a), len(b))
        result["accept_region_compare"] = {
            "kolanhook_len": len(a), "launchhook_len": len(b),
            "equal_bytes_in_overlap": sum(1 for i in range(n) if a[i] == b[i]),
            "overlap": n, "identical": a == b,
        }
    with open(os.path.join(OUT_DIR, "bytecode_identity.json"), "w") as f:
        json.dump(result, f, indent=1)
    print(json.dumps(result, indent=1))

if __name__ == "__main__":
    main()
