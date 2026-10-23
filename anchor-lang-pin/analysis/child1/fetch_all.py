#!/usr/bin/env python3
"""Child1: fetch + classify deployed Solana programs across the named repos.

Read-only. Uses getAccountInfo / getSlot / getBlockTime / getSignaturesForAddress.
Never signs anything. Writes only inside analysis/child1/.

Usage: python3 fetch_all.py candidates.json outdir
"""
import base64, json, os, re, subprocess, sys, time, urllib.request

_B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = _B58[r] + out
    for c in b:
        if c == 0: out = "1" + out
        else: break
    return out.encode()

ENDPOINTS = [u for u in [os.environ.get("SOLANA_RPC_URL")] if u] + [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]

def rpc_any(method, params):
    last = None
    for u in ENDPOINTS:
        for attempt in range(2):
            try:
                body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method,
                                   "params": params}).encode()
                req = urllib.request.Request(u, data=body,
                                             headers={"Content-Type": "application/json"})
                with urllib.request.urlopen(req, timeout=90) as r:
                    j = json.loads(r.read())
                if "error" in j:
                    last = j["error"]; break
                return j
            except Exception as e:
                last = e; time.sleep(1)
    raise RuntimeError(f"{method}: {last}")

def elf_true_size(b):
    if b[:4] != b"\x7fELF":
        return len(b)
    e_shoff = int.from_bytes(b[0x28:0x30], "little")
    e_shentsize = int.from_bytes(b[0x3a:0x3c], "little")
    e_shnum = int.from_bytes(b[0x3c:0x3e], "little")
    return min(len(b), e_shoff + e_shentsize * e_shnum)

# --- classification (mirrors analysis/classify_anchor.py) ---
M_1_0_X = [
    "A duplicate mutable account constraint was violated",
    "Account is already migrated",
    "Account must be migrated before exiting",
    "Cannot deref to From: account is already migrated.",
    "Use `UncheckedAccount` instead of `AccountInfo` for safer unchecked accounts.",
]
M_LE_0_32 = [
    "IDL account must be empty in order to resize, try closing first",
    "The program was compiled without idl instructions",
    "interface-instructions",
    "Use `solana-sdk-ids` crate instead",
    "Use `solana-sysvar` crate instead",
]
M_0_31_PLUS = ["Instruction discriminator not provided"]
M_LE_0_30 = ["8 byte instruction identifier not provided"]

def classify(path):
    data = open(path, "rb").read()
    def has(s): return s.encode() in data
    hits10 = [m for m in M_1_0_X if has(m)]
    hits032 = [m for m in M_LE_0_32 if has(m)]
    hits031 = [m for m in M_0_31_PLUS if has(m)]
    hits030 = [m for m in M_LE_0_30 if has(m)]
    if hits10:
        fam = "ANCHOR_1_0_X"
    elif hits032:
        fam = "ANCHOR_0_30_0_32"
    else:
        fam = "INDETERMINATE"
    reg = set(re.findall(rb"index\.crates\.io-[0-9a-f]{16}", data))
    hb = set(re.findall(rb"hashbrown-[0-9.]+", data))
    return {
        "anchor_family": fam,
        "markers_1_0_x": hits10,
        "markers_le_0_32": hits032,
        "marker_0_31_plus": hits031,
        "marker_le_0_30": hits030,
        "registry_hashes": sorted(x.decode() for x in reg),
        "hashbrown": sorted(x.decode() for x in hb),
    }

ANCHOR_HINTS = ["anchor_lang", "anchor-lang", "anchor_spl", "AnchorSerialize",
                "AnchorDeserialize", "anchor_lang::", "Instruction discriminator",
                "discriminator", "Pinocchio", "pinocchio", "entrypoint"]

def anchor_strings(path):
    """strings -n 6 | grep -iE anchor|discriminator|Pinocchio|entrypoint ; return matched lines"""
    try:
        p1 = subprocess.run(["strings", "-n", "6", path], capture_output=True)
        lines = p1.stdout.decode("latin-1", "replace").splitlines()
    except Exception as e:
        return {"error": str(e)}
    pat = re.compile(r"anchor|discriminator|pinocchio|entrypoint", re.I)
    matched = [l for l in lines if pat.search(l)]
    # interesting flags
    has_pinocchio = any("pinocchio" in l.lower() for l in lines)
    has_anchor_lang = any(re.search(r"anchor[-_]lang", l, re.I) for l in lines)
    has_anchor_disc = any("anchor" in l.lower() and "discriminator" in l.lower() for l in lines) \
        or any("Instruction discriminator" in l for l in lines)
    return {
        "pinocchio": has_pinocchio,
        "anchor_lang": has_anchor_lang,
        "anchor_discriminator": has_anchor_disc,
        "sample": matched[:40],
        "n_matched": len(matched),
    }

def fetch_program(pid, elfdir):
    info = rpc_any("getAccountInfo", [pid, {"encoding": "base64"}])["result"]["value"]
    if info is None:
        return {"program": pid, "exists": False, "error": "no account"}
    out = {"program": pid, "exists": True, "owner": info["owner"],
           "executable": info["executable"], "lamports": info["lamports"]}
    if not info["executable"]:
        out["error"] = "not executable"; return out
    d = base64.b64decode(info["data"][0])
    state = int.from_bytes(d[:4], "little")
    out["loader_state"] = state
    if state != 2:
        out["error"] = "not upgradeable (loader_state=%d)" % state
        return out
    pd = b58encode(d[4:36]).decode()
    out["programdata"] = pd
    v2 = rpc_any("getAccountInfo", [pd, {"encoding": "base64"}])["result"]["value"]
    d2 = base64.b64decode(v2["data"][0])
    out["programdata_len"] = len(d2)
    out["programdata_lamports"] = v2["lamports"]
    last_slot = int.from_bytes(d2[4:12], "little")
    has_auth = d2[12]
    out["last_deploy_slot"] = last_slot
    out["upgrade_authority"] = b58encode(d2[13:45]).decode() if has_auth else None
    elf = d2[13 + (32 if has_auth else 0):]
    tsize = elf_true_size(elf)
    out["elf_len_account"] = len(elf)
    out["elf_len_true"] = tsize
    os.makedirs(elfdir, exist_ok=True)
    epath = os.path.join(elfdir, pid + ".so")
    with open(epath, "wb") as f:
        f.write(elf[:tsize])
    try:
        bt = rpc_any("getBlockTime", [last_slot]).get("result")
        out["last_deploy_unix"] = bt
        if bt:
            out["last_deploy_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(bt))
    except Exception as e:
        out["last_deploy_unix_error"] = str(e)
    try:
        sigs = rpc_any("getSignaturesForAddress", [pd, {"limit": 25}])["result"]
        out["upgrade_history"] = [
            {"sig": s["signature"], "slot": s["slot"], "blockTime": s.get("blockTime"),
             "err": s.get("err") is not None} for s in sigs]
    except Exception as e:
        out["upgrade_history_error"] = str(e)
    # classify
    try:
        out.update(classify(epath))
    except Exception as e:
        out["classify_error"] = str(e)
    try:
        out["strings"] = anchor_strings(epath)
    except Exception as e:
        out["strings_error"] = str(e)
    return out

if __name__ == "__main__":
    cand_path = sys.argv[1]
    elfdir = sys.argv[2] if len(sys.argv) > 2 else "elf"
    cands = json.load(open(cand_path))
    res = []
    for c in cands:
        name, pid, repo = c["name"], c["id"], c.get("repo", "")
        try:
            r = fetch_program(pid, elfdir)
        except Exception as e:
            r = {"program": pid, "exists": None, "error": str(e)}
        r["name"] = name
        r["repo"] = repo
        res.append(r)
        print(f"{name:38s} {pid:44s} exists={r.get('exists')} "
              f"fam={r.get('anchor_family')} err={r.get('error')}", flush=True)
    json.dump(res, open(os.path.join(os.path.dirname(cand_path), "fetched_raw.json"), "w"), indent=2)
    print("WROTE", os.path.join(os.path.dirname(cand_path), "fetched_raw.json"))
