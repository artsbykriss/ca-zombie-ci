#!/usr/bin/env python3
"""
binfp.py — Phase C: download release binaries for the vulnerable shortlist and
fingerprint them: PIE/non-PIE, stripped/unstripped, static/dynamic, embedded Go
version, SDK/wasmd/wasmvm versions, and (when symbols are present) the
runtime/cgo/mint symbol surface and package-level globals.

READ-ONLY. Public release assets only. No chain interaction, no secrets.
"""
import json, os, re, subprocess, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "ci-out"))
os.makedirs(OUT, exist_ok=True)
DL = "/tmp/cwa006-bin"
os.makedirs(DL, exist_ok=True)
UA = {"User-Agent": "cwa006-crosschain-research/1.0"}
MAX_BYTES = 400 * 1024 * 1024

# chain -> explicit deployed-version asset URL (overrides the stale registry URL).
URLS = {
    "archway": "https://github.com/archway-network/archway/releases/download/v10.1.0/archwayd_linux_amd64",
    "desmos": "https://github.com/desmos-labs/desmos/releases/download/v7.1.0/desmos-v7.1.0-linux-amd64",
    "jackal": "https://github.com/JackalLabs/canine-chain/releases/download/v5.1.2/canined-linux-amd64",
    "shido": "https://github.com/ShidoGlobal/mainnetShidoNodeSync/releases/download/v2.0.0/ubuntu_22.04.tar.gz",
    "axelar": "https://github.com/axelarnetwork/axelar-core/releases/download/v1.0.5/axelard-linux-amd64-v1.0.5",
    "bitcanna": "https://github.com/BitCannaGlobal/bcna/releases/download/v4.0.1/bcnad_linux_amd64.tar.gz",
    "bitsong": "https://github.com/bitsongofficial/go-bitsong/releases/download/v0.23.0/bitsongd-linux-amd64",
    "aura": "https://github.com/aura-nw/aura/releases/download/v0.9.3/aurad",
    "sentinel": "https://github.com/sentinel-official/hub/releases/download/v12.0.1/sentinelhub-amd64",
    "stride": "https://github.com/Stride-Labs/stride/releases/download/v35.0.0/strided",
    "cosmoshub": "https://github.com/cosmos/gaia/releases/download/v28.3.1/gaiad-v28.3.1-linux-amd64",
    "neutron": "https://github.com/neutron-org/neutron/releases/download/v11.1.0/neutrond-linux-amd64",
    "juno": "https://github.com/CosmosContracts/juno/releases/download/v31.0.0/junod",
    "osmosis": "https://github.com/osmosis-labs/osmosis/releases/download/v32.0.0/osmosisd-32.0.0-linux-amd64",
    "nyx": "https://github.com/nymtech/nyx/releases/download/nym-binaries-v2024.13-magus/nyxd",
    "sentinel": "https://github.com/sentinel-official/hub/releases/download/v12.0.1/sentinelhub",
    "stride": "https://github.com/Stride-Labs/stride/releases/download/v35.0.0/strided",
    "aura": "https://github.com/aura-nw/aura/releases/download/v0.9.3/aurad",
    "nolus": "https://github.com/Nolus-Protocol/nolus-core/releases/download/v0.8.6/nolusd",
    "persistence": "https://github.com/persistenceOne/persistenceCore/releases/download/v16.1.0/persistenceCore-v16.1.0-linux-amd64",
}


def run(cmd, timeout=1800):
    try:
        p = subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=True, text=True, timeout=timeout)
        return (p.stdout or "") + (p.stderr or "")
    except Exception as e:
        return f"__err__ {e}"


def download(url, dest):
    if os.path.exists(dest) and os.path.getsize(dest) > 2 * 1024 * 1024:
        return True
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=1800) as r, open(dest, "wb") as f:
            total = 0
            while True:
                chunk = r.read(1 << 20)
                if not chunk:
                    break
                total += len(chunk)
                if total > MAX_BYTES:
                    return False
                f.write(chunk)
        return os.path.getsize(dest) > 1024 * 1024
    except Exception as e:
        print(f"    download failed: {e}")
        return False


def _parse_modinfo(text):
    deps = {}
    for line in re.split(r"[\n\x00]+", text):
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0] in ("dep", "mod", "go", "build"):
            if parts[0] == "go":
                deps["__go__"] = parts[1]
            elif parts[0] == "dep":
                deps[parts[1]] = parts[2]
    return deps


def _uvarint(b, off):
    x = 0
    s = 0
    i = off
    while i < len(b):
        c = b[i]
        x |= (c & 0x7F) << s
        i += 1
        if c < 0x80:
            return x, i
        s += 7
    return None, i


def read_buildinfo(path):
    """Dependency-free Go buildinfo reader (inline, varint-prefixed layout)."""
    MAGIC = b"\xff Go buildinf:"
    try:
        with open(path, "rb") as f:
            data = f.read()
    except Exception:
        return None
    i = data.find(MAGIC)
    if i < 0:
        return None
    flags = data[i + 15]
    if flags & 2 == 0:
        return None  # pointer layout; rely on `go version -m`
    d = data[i + 32:]
    vl, o = _uvarint(d, 0)
    if not vl:
        return None
    version = d[o:o + vl].decode("utf-8", "replace")
    rest = d[o + vl:]
    ml, o2 = _uvarint(rest, 0)
    blob = rest[o2:o2 + (ml or 0)] if ml else rest[:262144]
    text = None
    try:
        import zlib
        text = zlib.decompress(blob).decode("utf-8", "replace")
    except Exception:
        text = blob.decode("utf-8", "replace")
    deps = _parse_modinfo(text)
    deps["__go__"] = version
    return deps


def fingerprint(path):
    res = {}
    res["sha256"] = run(f"sha256sum '{path}'").split()[0]
    res["size"] = os.path.getsize(path)
    res["file"] = run(f"file -b '{path}'").strip()
    eh = run(f"readelf -h '{path}'")
    m = re.search(r"Type:\s+(\S+)", eh)
    res["elf_type"] = m.group(1) if m else None
    res["pie"] = (res["elf_type"] == "DYN")
    m = re.search(r"Entry point address:\s+(\S+)", eh)
    res["entry"] = m.group(1) if m else None
    res["statically_linked"] = ("statically linked" in res["file"])
    res["stripped"] = ("stripped" in res["file"] and "not stripped" not in res["file"])
    # embedded Go buildinfo (authoritative)
    gv = run(["go", "version", "-m", path])
    m = re.search(r"^\s*go(1\.\d+(?:\.\d+)?)", gv, re.M)
    res["go_version"] = ("go" + m.group(1)) if m else None
    deps = {}
    for mm in re.finditer(r"^\s*dep\s+(\S+)\s+(\S+)", gv, re.M):
        deps[mm.group(1)] = mm.group(2)
    if not deps:
        d2 = read_buildinfo(path)
        if d2:
            res["go_version"] = res["go_version"] or d2.pop("__go__", None)
            deps = d2
    res["wasmd"] = next((v for k, v in deps.items() if k.startswith("github.com/CosmWasm/wasmd")), None)
    res["wasmvm"] = next((v for k, v in deps.items() if k.startswith("github.com/CosmWasm/wasmvm")), None)
    res["cosmos_sdk"] = deps.get("github.com/cosmos/cosmos-sdk")
    res["all_deps_n"] = len(deps)
    # symbol surface (works if not stripped)
    nm = run(f"go tool nm '{path}' 2>&1 | head -400000")
    res["nm_ok"] = ("no symbol section" not in nm) and ("__err__" not in nm) and (len(nm.strip()) > 1000)
    if res["nm_ok"]:
        for label, pat in [
            ("has_cgocallback", r"runtime\.cgocallback\b"),
            ("has_cgocallback_abi0", r"runtime\.cgocallback\.abi0"),
            ("has_crosscall2", r"\bcrosscall2\b"),
            ("has_cSet", r"_cgoexp_\w+_cSet|api\.cSet"),
            ("has_cQueryExternal", r"_cgoexp_\w+_cQueryExternal|api\.cQueryExternal"),
            ("has_mintcoins", r"BaseKeeper\)\.MintCoins|mintbankkeeper.*MintCoins"),
            ("has_sendcoins_mod", r"SendCoinsFromModuleToAccount"),
            ("has_itab_context", r"go:itab\..*Context"),
        ]:
            res[label] = bool(re.search(pat, nm))
        # package-level globals holding app/keeper/ctx (BSS/Data symbols)
        globals_ = re.findall(r"^\s*[0-9a-f]+\s+[BbDd]\s+(\S+)$", nm, re.M)
        res["n_globals"] = len(globals_)
        interesting = [g for g in globals_ if re.search(r"(?i)(app\b|app\.|\bkeepers?\b|bankkeeper|wasm.*keeper|mintkeeper|sdk\.Context|\bctx\b)", g)]
        res["globals_interesting"] = interesting[:80]
    # wasmvm / wasmer strings
    res["wasm_strings"] = run(f"strings -a '{path}' | grep -iE 'libwasmvm|wasmvm v|cosmwasm-vm|wasmer[-_ /]|singlepass' | sort -u | head -30").strip()
    return res


def main():
    reg = json.load(open(os.path.join(OUT, "registry.json")))
    targets = json.load(open(os.path.join(HERE, "..", "targets.json")))
    results = {}
    for name in targets:
        url = URLS.get(name)
        if not url:
            b = (reg.get(name) or {}).get("binaries") or {}
            url = b.get("linux/amd64") if isinstance(b, dict) else None
        if not url:
            results[name] = {"error": "no_url"}
            continue
        print(f"[C] {name}: {url}")
        ext = ".tar.gz" if url.endswith(".tar.gz") else ".bin"
        dest = os.path.join(DL, name + ext)
        if not download(url, dest):
            results[name] = {"error": "download_failed", "url": url}
            continue
        binpath = dest
        if ext == ".tar.gz":
            run(f"mkdir -p {DL}/{name} && tar -xzf '{dest}' -C {DL}/{name} 2>/dev/null || true")
            cand = None
            for root, _dirs, files in os.walk(f"{DL}/{name}"):
                for fn in files:
                    fp = os.path.join(root, fn)
                    try:
                        with open(fp, "rb") as fh:
                            if fh.read(4) == b"\x7fELF" and os.path.getsize(fp) > 5 * 1024 * 1024:
                                cand = fp
                                break
                    except Exception:
                        pass
                if cand:
                    break
            if cand:
                binpath = cand
        r = fingerprint(binpath)
        r["binary_url"] = url
        r["binary_path"] = binpath
        results[name] = r
        print(f"    type={r.get('elf_type')} pie={r.get('pie')} stripped={r.get('stripped')} static={r.get('statically_linked')} go={r.get('go_version')} wasmd={r.get('wasmd')} wasmvm={r.get('wasmvm')} sdk={r.get('cosmos_sdk')} nm={r.get('nm_ok')}")
        if r.get("nm_ok"):
            print(f"    cgocallback={r.get('has_cgocallback')} crosscall2={r.get('has_crosscall2')} cSet={r.get('has_cSet')} mint={r.get('has_mintcoins')} globals={r.get('n_globals')} interesting={len(r.get('globals_interesting') or [])}")
    json.dump(results, open(os.path.join(OUT, "binfp.json"), "w"), indent=1)
    print(f"\nwrote binfp.json ({len(results)})")


if __name__ == "__main__":
    main()
