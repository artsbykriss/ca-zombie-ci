#!/usr/bin/env python3
"""Function-BODY diff across package versions (READ-ONLY) — the real version/import signal.

Function *names* can be identical across versions while their *bodies* (gating, math) changed.
This fetches the disassembly of the FIRST and LATEST version of each family, splits each module
into functions, and reports which function bodies changed / were added / removed. Bodies are
normalised (whitespace) before comparison.

Public GraphQL only. Output -> ci-out/body_diff.json (+ per-module body dumps on request).
"""
import json, os, re, urllib.request, datetime

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
OUT = os.environ.get("OUTDIR", os.path.join(os.path.dirname(__file__), "..", "ci-out"))
FAMILIES = {
    "dipcoin":      "0x978fed071cca22dd26bec3cf4a5d5a00ab10f39cb8c659bbfdfbec4397241001",
    "bluefin-pro":  "0xe74481697f432ddee8dd6f9bd13b9d0297a5b63d55f3db25c4d3b5d34dad85b7",
    "suigar":       "0xcbb0929f21450013ebe5e86e7139f2409da2e3ed212c51126a7e6448b795a43f",
    "bucket-vault": "0x9f835c21d21f8ce519fec17d679cd38243ef2643ad879e7048ba77374be4036e",
    "bucket-pool":  "0xc2ae6693383e4a81285136effc8190c7baaf0e75aafa36d1c69cd2170cfc3803",
    "alphalend":    "0xd631cd66138909636fc3f73ed75820d0c5b76332d1644608ed1c85ea2b8219b4",
    "kai-leverage": "0x51e0ccce48f0763f98f1cb4856847c2e1531adacada99cdd7626ab999db57523",
}
FUNC_RE = re.compile(r'^(entry|public|public\(friend\)|fun)\s+([\w<>]+)')

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def chain(orig):
    q = """query($a:SuiAddress!){ package(address:$a){ address version
      packageVersionsBefore(last:50){ nodes{ address version } } } }"""
    p = ((gql(q, {"a": orig}).get("data") or {}).get("package"))
    if not p: return []
    h = sorted(p["packageVersionsBefore"]["nodes"], key=lambda x: x["version"])
    h.append({"address": p["address"], "version": p["version"]})
    seen, out = set(), []
    for x in h:
        if x["version"] in seen: continue
        seen.add(x["version"]); out.append(x)
    return out

def disasm(veraddr):
    q = """query($a:SuiAddress!,$c:String){ object(address:$a){ asMovePackage{
      modules(first:50, after:$c){ pageInfo{hasNextPage endCursor} nodes{ name disassembly } } } } }"""
    mods, cur = [], None
    while True:
        r = gql(q, {"a": veraddr, "c": cur})
        p = ((r.get("data") or {}).get("object") or {}).get("asMovePackage")
        if not p: return {}
        mods += p["modules"]["nodes"]
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]: cur = pi["endCursor"]
        else: break
    return {m["name"]: (m.get("disassembly") or "") for m in mods}

def funcs(dis):
    """module disassembly -> {funcName: normalized body}"""
    out, cur, buf = {}, None, []
    for line in dis.splitlines():
        m = FUNC_RE.match(line)
        if m:
            if cur: out[cur] = "\n".join(buf)
            cur = m.group(2); buf = [line]
        elif cur is not None:
            buf.append(line)
    if cur: out[cur] = "\n".join(buf)
    return out

def norm(s):
    return re.sub(r'\s+', ' ', s).strip()

def main():
    os.makedirs(OUT, exist_ok=True)
    res = {"generated": datetime.datetime.utcnow().isoformat() + "Z", "families": {}}
    for fam, orig in FAMILIES.items():
        vs = chain(orig)
        if not vs: res["families"][fam] = {"error": "no package"}; continue
        first, last = vs[0], vs[-1]
        d0, d1 = disasm(first["address"]), disasm(last["address"])
        famres = {"first": first, "latest": last, "modules": {}}
        for mod in sorted(set(d0) & set(d1)):
            f0, f1 = funcs(d0[mod]), funcs(d1[mod])
            changed, removed, added = [], [], []
            for fn in set(f0) & set(f1):
                if norm(f0[fn]) != norm(f1[fn]): changed.append(fn)
            removed = sorted(set(f0) - set(f1))
            added = sorted(set(f1) - set(f0))
            if changed or removed or added:
                famres["modules"][mod] = {"changed": sorted(changed), "removed": removed,
                                          "added": added}
        res["families"][fam] = famres
        print(f"[{fam}] v{first['version']}->v{last['version']}")
        for mod, d in famres["modules"].items():
            if mod in ("error", "errors", "constants", "events"): continue
            if d["changed"] or d["removed"]:
                print(f"   {mod}: changed={len(d['changed'])} removed={len(d['removed'])}")
                if d["removed"]: print(f"       removed: {d['removed']}")
    json.dump(res, open(os.path.join(OUT, "body_diff.json"), "w"), indent=1)
    print("wrote", os.path.join(OUT, "body_diff.json"))

if __name__ == "__main__":
    main()
