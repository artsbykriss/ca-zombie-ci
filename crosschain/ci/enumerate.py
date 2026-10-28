#!/usr/bin/env python3
"""
enumerate.py — CWA-2026-006 cross-chain feasibility: Phase A (chain-registry metadata)
+ Phase B (source go.mod verification).

READ-ONLY: only public HTTPS GETs to raw.githubusercontent.com / api.github.com.
No chain interaction, no secrets, no writes outside ci-out/.
"""
import json, os, re, sys, time, urllib.request, urllib.error

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)

REG_RAW = "https://raw.githubusercontent.com/cosmos/chain-registry/master"
UA = {"User-Agent": "cwa006-crosschain-research/1.0"}

# Candidate CosmWasm-capable / wasmvm-embedding Cosmos chains (chain-registry folder names).
CANDIDATES = [
    # --- known set (mission ground truth) ---
    "archway", "jackal", "shido", "nyx", "pundix", "sommelier", "desmos",
    # --- broader CosmWasm ecosystem ---
    "osmosis", "kujira", "neutron", "juno", "stargaze", "terra", "terra2",
    "secretnetwork", "sei", "injective", "persistence", "cheqd", "coreum",
    "comdex", "chihuahua", "migaloo", "nois", "ojo", "assetmantle",
    "quicksilver", "provenance", "aura", "ki", "kava", "nolus", "nibiru",
    "bitsong", "cerberus", "omniflixhub", "regen", "umee", "shentu",
    "sentinel", "bitcanna", "emoney", "finschia", "lum-network", "irisnet",
    "cosmoshub", "akash", "stride", "noble", "dydx", "celestia", "babylon",
    "axelar", "saga", "xion", "canto", "cryptoorgchain", "passage",
    # --- further wasmd-based appchains ---
    "tgrade", "okp4", "gitopia", "xpla", "pryzm", "elys", "arkh", "furya",
    "mantra", "dungeon", "bitbadges", "aioz", "lava", "empower", "fury",
    "kyve", "nomic", "nois", "seilor", "rizon", "sifchain",
]


def get(url, timeout=30):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def get_json(url, timeout=30):
    try:
        return json.loads(get(url, timeout))
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code}
    except Exception as e:
        return {"_error": str(e)}


def fetch_registry(name):
    for sub in ("", "testnets/"):
        url = f"{REG_RAW}/{sub}{name}/chain.json"
        d = get_json(url)
        if "_http_error" not in d and "_error" not in d:
            d["_registry_path"] = f"{sub}{name}"
            return d
    return None


def parse_gomod(text):
    """Return (module_deps, go_directive) for the deps we care about."""
    deps = {}
    gv = None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("go ") and gv is None:
            gv = s.split()[1]
        # dep lines look like:  github.com/CosmWasm/wasmd v0.51.0
        m = re.match(r"^(github\.com/CosmWasm/(?:wasmd|wasmvm)|github\.com/cosmos/cosmos-sdk|github\.com/wasmerio/\S+|cosmossdk\.io/\S+)\s+(\S+)", s)
        if m:
            deps[m.group(1)] = m.group(2)
    # replaces
    repl = {}
    for m in re.finditer(r"replace\s+(\S+)\s+=>\s+(\S+)\s+(\S+)", text):
        repl[m.group(1)] = f"{m.group(2)} {m.group(3)}"
    for m in re.finditer(r"replace\s*\(\s*(.*?)\s*\)", text, re.S):
        for line in m.group(1).splitlines():
            mm = re.match(r"^\s*(\S+)\s+=>\s+(\S+)\s+(\S+)", line)
            if mm:
                repl[mm.group(1)] = f"{mm.group(2)} {mm.group(3)}"
    return deps, gv, repl


def norm_repo(url):
    if not url:
        return None
    m = re.search(r"github\.com[/:]([^/]+/[^/\s#?]+)", url)
    if not m:
        return None
    r = m.group(1)
    if r.endswith(".git"):
        r = r[:-4]
    return r


def main():
    reg = {}
    gomod = {}
    for name in CANDIDATES:
        d = fetch_registry(name)
        if not d:
            reg[name] = {"_not_found": True}
            print(f"[A] {name}: not in registry")
            continue
        cb = d.get("codebase", {}) or {}
        rec = {
            "chain_name": d.get("chain_name"),
            "chain_id": d.get("chain_id"),
            "status": d.get("status"),
            "network_type": d.get("network_type"),
            "pretty_name": d.get("pretty_name"),
            "git_repo": cb.get("git_repo"),
            "recommended_version": cb.get("recommended_version"),
            "tag": cb.get("tag"),
            "sdk_version": (cb.get("sdk") or {}).get("version"),
            "cosmwasm_version": (cb.get("cosmwasm") or {}).get("version"),
            "cosmwasm_enabled": (cb.get("cosmwasm") or {}).get("enabled"),
            "ibc_version": (cb.get("ibc") or {}).get("version"),
            "consensus": (cb.get("consensus") or {}).get("version"),
            "binaries": cb.get("binaries") or {},
        }
        apis = d.get("apis", {}) or {}
        rest = [a.get("address") for a in (apis.get("rest") or []) if a.get("address")]
        rpc = [a.get("address") for a in (apis.get("rpc") or []) if a.get("address")]
        rec["rest"] = rest[:4]
        rec["rpc"] = rpc[:2]
        reg[name] = rec
        print(f"[A] {name}: status={rec['status']} id={rec['chain_id']} sdk={rec['sdk_version']} cosmwasm={rec['cosmwasm_version']} enabled={rec['cosmwasm_enabled']}")

        # Phase B: source go.mod at the recommended tag
        repo = norm_repo(rec["git_repo"])
        tag = rec["recommended_version"] or rec["tag"]
        if repo and tag:
            for ref in (tag, tag.lstrip("v"), "main", "master"):
                url = f"https://raw.githubusercontent.com/{repo}/{ref}/go.mod"
                try:
                    txt = get(url, 25)
                except Exception:
                    continue
                if "module " in txt:
                    deps, gv, repl = parse_gomod(txt)
                    gomod[name] = {"repo": repo, "ref": ref, "go": gv, "deps": deps, "replace": repl}
                    print(f"[B] {name}: go.mod@{ref} go={gv} wasmd={deps.get('github.com/CosmWasm/wasmd')} wasmvm={deps.get('github.com/CosmWasm/wasmvm')} sdk={deps.get('github.com/cosmos/cosmos-sdk')} repl={repl}")
                    break
        time.sleep(0.15)

    json.dump(reg, open(os.path.join(OUT, "registry.json"), "w"), indent=1)
    json.dump(gomod, open(os.path.join(OUT, "gomod.json"), "w"), indent=1)
    print(f"\nwrote registry.json ({len(reg)}) and gomod.json ({len(gomod)})")


if __name__ == "__main__":
    main()
