#!/usr/bin/env python3
"""Build program_table.json / program_table.md from all_programs.json."""
import json, re, subprocess, os

allp = {r["program"]: r for r in json.load(open("all_programs.json"))}

# (repo_group, program_name, program_id, scope)
ROWS = [
 # ---------------- chainlink-solana ----------------
 ("chainlink-solana","ocr_2 (mainnet data-feeds OCR2)","HEvSKofvBgfaexv23kMabbYqxasxU3mQ4ibBMEmJWHny","repo"),
 ("chainlink-solana","ocr_2 (historic id, scripts/lib.sh)","cjg3oHmg9uuPsP8D6g29NWvhySJkdYdAo9D25PRbKXJ","repo"),
 ("chainlink-solana","access-controller (historic id)","9xi644bRR8birboDGdTiwBq3C7VEeR7VuamRYYXCubUW","repo"),
 ("chainlink-solana","mock-forwarder","7kuEAA3mSC1Tz8gQjnvH7bKFda9xSPRRin9SZbH49cNK","repo"),
 ("chainlink-solana","access-controller (old deploy, 0.20.1)","CaH12fwNTKJAG8PxEvo9R96Zc2j8qNHZaFj8ZW49yZNT","repo"),
 ("chainlink-solana","ocr2+store (old deploy, 0.20.1)","HW3ipKzeeduJq6f1NqRCw4doknMeWkfrM4WxobtG3o5v","repo"),
 ("chainlink-solana","access-controller (old deploy, 0.20.1)","DzzjdPWNfwHZmzPVxnmqkkMJraYQQRCpgFZajqkqmU6G","repo"),
 ("chainlink-solana","store/other (old deploy, 0.18.2)","7zr352snXaLm2uwgP8kJcckh5nBij2m2oLiGjuXGVKWg","repo"),
 ("chainlink-solana","cre-simulate-receiver","EJwYCKxQ826qEUoFeGVyQLmBDGw6DY1hdg1QP5QcwhXa","repo-shared-authority"),
 ("chainlink-solana","store (repo declare_id)","9kRNTZmoZSiTBuXC62dzK9E7gC7huYgcmRRhYv3i4osC","repo-absent"),
 ("chainlink-solana","ocr_2 (repo declare_id)","E3j24rx12SyVsG6quKuZPbQqZPkhAUCh8Uek4XrKYD2x","repo-absent"),
 ("chainlink-solana","access-controller (repo declare_id)","2ckhep7Mvy1dExenBqpcdevhRu7CLuuctMcx7G9mWEvo","repo-absent"),
 ("chainlink-solana","keystone-forwarder (repo declare_id)","whV7Q5pi17hPPyaPksToDw1nMx6Lh8qmNWKFaLRQ4wz","repo-absent"),
 ("chainlink-solana","data-feeds-cache (repo declare_id)","3kX63udXtYcsdj2737Wi2KGd2PhqiKPgAFAxstrjtRUa","repo-absent"),
 # ---------------- light-protocol ----------------
 ("light-protocol","system","SySTEM1eSU2p4BGQfQpimFEWWSC1XDFeun3Nqzz3rT7","repo"),
 ("light-protocol","registry","Lighton6oQpVkeewmo2mcPTQQp7kYHr4fWpAgJyEmDX","repo"),
 ("light-protocol","account-compression","compr6CUsB5m2jS4Y3831ztGSTnDpnKJTKS95d64XVq","repo"),
 ("light-protocol","compressed-token","cTokenmWW8bLPjZEBAUgYy3zKxQZW6VKi7bqNFEVv3m","repo"),
 ("light-protocol","create-nullifier","NFLx5WGPrTHHvdRNsidcrNcLxRruMC92E4yv7zhZBoT","repo-shared-authority"),
 ("light-protocol","test-batch-transactions","Dcc5vv836DzrDrvY8rB7TZD2bhtfXLMCWCHdoJCtQnxy","repo-shared-authority"),
 # ---------------- helium-program-library ----------------
 ("helium-program-library","helium-sub-daos","hdaoVTCqhfHHo75XdAMxBKdUqvq1i5bF23sisBqVgGR","repo"),
 ("helium-program-library","data-credits","credMBJhYFzfn7NxBMdU4aUqFggAjgztaCcv2Fo6fPT","repo"),
 ("helium-program-library","lazy-distributor","1azyuavdMyvsivtNxPoz6SucD18eDHeXzFCUPq5XU7w","repo"),
 ("helium-program-library","treasury-management","treaf4wWBBty3fHdyBpo35Mz84M8k3heKXmjmi9vFt5","repo"),
 ("helium-program-library","mobile-entity-manager","memMa1HG4odAFmUbGWfPwS1WWfK95k99F2YTkGvyxZr","repo"),
 ("helium-program-library","fanout","fanqeMu3fw8R4LwKNbahPtYXJsyLL6NXyfe2BqzhfB6","repo"),
 ("helium-program-library","mini-fanout","mfanLprNnaiP4RX9Zz1BMcDosYHCqnG24H1fMEbi9Gn","repo"),
 ("helium-program-library","price-oracle","porcSnvH9pvcYPmQ65Y8qcZSRxQBiBBQX7UV5nmBegy","repo"),
 ("helium-program-library","rewards-oracle","rorcfdX4h9m9swCKgcypaHJ8NGYVANBpmV9EHn3cYrF","repo"),
 ("helium-program-library","hexboosting","hexbnKYoA2GercNNhHUCCfrTRWrHjT6ujKPXTa5NPqJ","repo"),
 ("helium-program-library","circuit-breaker","circAbx64bbsscPbQzZAUvuXpHqrCe6fLMzc2uKXz9g","repo"),
 ("helium-program-library","dc-auto-top","topqqzQZroCyRrgyM5zVq6xkFDVnfF13iixSjajydgU","repo"),
 ("helium-program-library","helium-entity-manager","hemjuPXBpNvggtaUnN1MwT3wrdhttKEfosTcc2P9Pg8","repo"),
 ("helium-program-library","voter-stake-registry","hvsrNC3NKbcryqDs2DocYHZ9yPKEVzdSjQG6RVtK1s8","repo"),
 ("helium-program-library","welcome-pack","we1cGnTxTkDP9Sk49dw1d3T7ik7V2NfnY4qDGCDHXfC","repo"),
 ("helium-program-library","lazy-transactions","1atrmQs3eq1N2FEYWu6tyTXbCjP4uQwExpjtnhXtS8h","repo"),
 ("helium-program-library","no-emit","noEmmgLmQdk6DLiPV8CSwQv3qQDyGEhz9m5A4zhtByv","repo"),
 ("helium-program-library","tuktuk-dca","tdcam4m5U74pEZQrsQ7fVAav4AUXXc6z8fkhvExfRVN","repo"),
 ("helium-program-library","hpl-crons","hcrLPFgFUY6sCUKzqLWxXx5bntDiDCrAZVcrXfx9AHu","repo"),
 ("helium-program-library","tuktuk-dca (repo declare_id)","tdcaoktKw6bDQ5ukLq5fLtje2kCkmHX7Sj9G77jY5dh","repo-absent"),
 ("helium/helium-proposals","proposal","propFYxqmVcufMhk5esNMrexq2ogHbbC2kP9PU1qxKs","repo-shared-authority"),
 ("helium-program-library","nft_proxy","nprx42sXf5rpVnwBWEdRg1d8tuCWsTuVLys1pRWwE6p","repo-shared-authority"),
 ("helium/tuktuk","tuktuk","tuktukUrfhXT6ZT77QTU8RQtvgL967uRuVagWF57zVA","repo-shared-authority"),
 ("helium/helium-cron","cron","cronAjRZnJn3MTP3B9kE62NWDrjSuAPVXf9c4hu4grM","repo-shared-authority"),
 ("helium/helium-staking","stc (staking/rewards)","stcfiqW3fwD9QCd8Bqr1NBLrs7dftZHBQe7RiMMA4aM","repo-shared-authority"),
 # ---------------- openbook ----------------
 ("openbook-v2","openbook-v2","opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb","repo"),
 ("openbook-v1","openbook-v1 (Serum fork)","srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX","repo"),
 # ---------------- raydium-clmm ----------------
 ("raydium-clmm","raydium-clmm (main)","CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK","repo"),
 ("raydium-clmm","wrapper/devnet declare_id (not deployed)","DRayAUgENGQBKVaX8owNhgzkEDyoHTGVEGHVJT1E9pfH","repo-absent"),
 # ---------------- marginfi-v2 ----------------
 ("marginfi-v2","marginfi (main)","MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA","repo"),
 ("marginfi-v2","mocks (test program)","HfCg2Re4BnZmQ7SzUcw3fhBtf1fqWmtMY1wov59VFrYs","repo-shared-authority"),
 # ---------------- mpl-bubblegum ----------------
 ("mpl-bubblegum","bubblegum","BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY","repo"),
 # ---------------- manifest ----------------
 ("manifest","manifest (main)","MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms","repo"),
 ("manifest","wrapper","wMNFSTkir3HgyZTsB7uqu3i7FA73grFCptPXgrZjksL","repo"),
 ("manifest","ui-wrapper","UMnFStVeG1ecZFc2gc5K3vFy3sMpotq8C91mXBQDGwh","repo"),
 ("manifest","destiny/fortune","FoRTUqpCaR3MYs2VFYuQNkzfJruzDWxxiJEGk9bFhib7","repo-shared-authority"),
 ("manifest","dawn (perps?)","DSTNyVLdoKxTYSjzCQ5191wozVChdVD8qCcFWZwMMX37","repo-shared-authority"),
 ("manifest","fate (tiny program)","FATEX7qHcbWRip7scfUMFa1VbLWZzscy8Bfj68LexYtP","repo-shared-authority"),
 # ---------------- same-authority extras (other Raydium / Metaplex repos) ----------------
 ("raydium-ecosystem (shared authority)","raydium-launchpad","LanMV9sAd7wArD4vJFi2qDdfnVhFxYSUg6eADduJ3uj","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-cp-swap (CPMM)","CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-amm-v4","675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-farm/stake","FarmqiPv5eAj3j1GMdMCMUGXqPUvmquZtMy86QH6rzhG","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-lock","LockrWmn6K5twhz3y9w1dQERbmgSaRkfnTeTKbpofwE","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-route","routeUGWgWzqBWFcrCfv8tritsqukccJPu3q5GPP3xS","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-vote","VoteWPk9yyGmkX4U77nEWRJWpcc8kUfrPoghxENpstL","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-claim","CLaimxFqjHzgTJtAGHU47NPhg6qrc5sCnpC4tBLyABQS","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-unknown EhhTKcz","EhhTKczWMGQt46ynNeRX1WfeagwwJd7ufHvCDjRxjo5Q","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-unknown 5quBtoi","5quBtoiQqxF9Jv6KYKctB59NT3gtJD2Y65kdnB1Uev3h","shared-authority-extra"),
 ("raydium-ecosystem (shared authority)","raydium-unknown 9KEPoZ","9KEPoZmtHUrBbhWN1v1KWLMkkvwY6WLtAVUCPRtRjP4z","shared-authority-extra"),
 ("metaplex-ecosystem (shared authority)","mpl-core","CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d","shared-authority-extra"),
 ("metaplex-ecosystem (shared authority)","mpl-genesis","GNS1S5J5AspKXgpjz6SvKL66kPaKWAhaGRhCqPRxii2B","shared-authority-extra"),
 ("metaplex-ecosystem (shared authority)","auth9Sig (token-auth-rules?)","auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg","shared-authority-extra"),
]

def kind_of(r):
    fam = r.get("anchor_family")
    s = r.get("strings") or {}
    pid = r.get("program")
    if not r.get("exists"):
        return "ABSENT on mainnet"
    if fam == "ANCHOR_1_0_X":
        return "anchor (1.0.x family)"
    if fam == "ANCHOR_0_30_0_32":
        # refine the <=0.32 bucket using the pre-0.31 / 0.31+ markers
        if r.get("marker_0_31_plus"):
            return "anchor (0.31-0.32)"
        if r.get("marker_le_0_30"):
            return "anchor (<=0.30, pre-0.31)"
        return "anchor (0.30-0.32 undetermined)"
    # INDETERMINATE: disambiguate
    out = ""
    try:
        out = subprocess.run(["strings","-n","5","elf/"+pid+".so"],
                             capture_output=True).stdout.decode("latin-1","replace")
    except Exception:
        pass
    av = sorted(set(re.findall(r"anchor-lang-([0-9.]+)", out)))
    if s.get("pinocchio"):
        return "Pinocchio entrypoint (non-anchor)"
    if av:
        return f"anchor (old pre-0.30; embedded anchor-lang {','.join(av)})"
    if s.get("anchor_lang") or s.get("anchor_discriminator"):
        return "anchor (markers DCE'd)"
    return "custom/native entrypoint (non-anchor)"

def verdict_of(r, kind):
    fam = r.get("anchor_family")
    if not r.get("exists"):
        return "n/a (not deployed)"
    if fam == "ANCHOR_0_30_0_32":
        return "No - proven <=0.32 (not the 1.0.x family)"
    if fam == "ANCHOR_1_0_X":
        return "POSSIBLE by family (1.0.x); last deploy after 1.0.2 fix (2026-05-02) -> likely >=1.0.2 (fixed), but not provable from ELF"
    # indeterminate
    if "non-anchor" in kind:
        return "No - not an anchor-lang program"
    if "pre-0.30" in kind:
        return "No - proven old anchor (<0.30)"
    return "No - no 1.0.x markers (inconclusive family, but not a 1.0.x build)"

rows = []
for repo, name, pid, scope in ROWS:
    r = allp.get(pid)
    if r is None:
        rows.append({"repo":repo,"program_name":name,"program_id":pid,"scope":scope,
                     "exists":None,"elf_size":None,"anchor_family":None,
                     "markers_1_0_x":[],"last_deploy_utc":None,"upgrade_authority":None,
                     "kind":"NOT FETCHED","notes":"","verdict":"unknown"})
        continue
    kind = kind_of(r)
    verdict = verdict_of(r, kind)
    notes = kind
    if r.get("exists"):
        notes += f"; markers_le_0_32={r.get('markers_le_0_32')}"
        if r.get("marker_le_0_30"):
            notes += "; pre-0.31 marker present"
    rows.append({
        "repo": repo, "program_name": name, "program_id": pid, "scope": scope,
        "exists": r.get("exists"),
        "elf_size": r.get("elf_len_true"),
        "anchor_family": r.get("anchor_family"),
        "markers_1_0_x": r.get("markers_1_0_x") or [],
        "markers_le_0_32": r.get("markers_le_0_32") or [],
        "marker_0_31_plus": r.get("marker_0_31_plus") or [],
        "marker_le_0_30": r.get("marker_le_0_30") or [],
        "last_deploy_utc": r.get("last_deploy_utc"),
        "upgrade_authority": r.get("upgrade_authority"),
        "kind": kind, "notes": notes, "verdict": verdict,
    })

json.dump(rows, open("program_table.json","w"), indent=2)

# markdown
def esc(x): return ("" if x is None else str(x))
lines = []
lines.append("# Deployed anchor-lang family pin - child1 (remaining programs)\n")
lines.append("Advisory: GHSA-c6rc-8jpp-2fgc / CVE-2026-45137 / RUSTSEC-2026-0144. "
             "Bug exists ONLY in anchor-lang **1.0.0 / 1.0.1** (fixed 1.0.2, released 2026-05-02; 1.0.0 released 2026-04-02).\n")
lines.append("`anchor_family` values: `ANCHOR_1_0_X` (1.0.0-1.0.3, vulnerable family is a subset), "
             "`ANCHOR_0_30_0_32` (0.30-0.32, NOT affected), `INDETERMINATE` (no discriminating markers).\n")
hdr = ("| repo | program | program id | exists | elf size | anchor_family | 1.0.x markers | "
       "last deploy (UTC) | upgrade authority | kind / notes | 1.0.0/1.0.1 verdict |")
sep = "|---|---|---|---|---|---|---|---|---|---|---|"
lines.append(hdr); lines.append(sep)
for r in rows:
    m = ", ".join(r["markers_1_0_x"]) if r["markers_1_0_x"] else "-"
    lines.append("| " + " | ".join([
        esc(r["repo"]), esc(r["program_name"]), "`"+esc(r["program_id"])+"`",
        esc(r["exists"]), esc(r["elf_size"]), esc(r["anchor_family"]), m,
        esc(r["last_deploy_utc"]), ("`"+r["upgrade_authority"]+"`") if r["upgrade_authority"] else "-",
        esc(r["kind"]), esc(r["verdict"]),
    ]) + " |")
open("program_table.md","w").write("\n".join(lines) + "\n")
print("wrote program_table.json (%d rows) and program_table.md" % len(rows))
