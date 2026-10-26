#!/usr/bin/env python3
"""For each version, list entry/public functions and whether they transitively
call protocol::check_version / check_basic / check_is_normal / roles gating.

Heuristic call-graph over the Move disassembly text.
"""
import json, glob, os, re, sys

FUN_RE = re.compile(
    r'^(?P<vis>(public\(friend\)|public\(package\)|public\(script\)|public|entry|native|friend)\s+)*'
    r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<generics><[^>]*>)?\s*\((?P<args>[^)]*)\)\s*(:\s*[^\{]+)?\{\s*$')
CALL_RE = re.compile(r'Call\s+(?:0x[0-9a-fA-F]+::)?(?P<mod>[A-Za-z_][A-Za-z0-9_]*)::(?P<fn>[A-Za-z_][A-Za-z0-9_]*)')

GATE = {("protocol","check_version"), ("protocol","check_basic"), ("protocol","check_is_normal")}

def parse(dis):
    """Return dict fnname -> (header_line, body_text)."""
    fns = {}
    lines = dis.splitlines()
    cur = None; buf = []
    for line in lines:
        if line and line[0] not in " \t":
            m = FUN_RE.match(line.rstrip())
            if m:
                if cur: fns[cur[0]] = (cur[1], "\n".join(buf))
                cur = (m.group("name"), line.rstrip()); buf = []
                continue
        if cur is not None:
            buf.append(line)
    if cur: fns[cur[0]] = (cur[1], "\n".join(buf))
    return fns

def reachable_gate(mod, fn, fns_by_mod, seen):
    key = (mod, fn)
    if key in seen: return False
    seen.add(key)
    if key in GATE: return True
    if mod not in fns_by_mod or fn not in fns_by_mod[mod]: return False
    _, body = fns_by_mod[mod][fn]
    for m in CALL_RE.finditer(body):
        if reachable_gate(m.group("mod"), m.group("fn"), fns_by_mod, seen):
            return True
    return False

def main(folder, want=None):
    for f in sorted(glob.glob(os.path.join(folder, "v*.json"))):
        d = json.load(open(f))
        fns_by_mod = {mod: parse(dis) for mod, dis in d["modules"].items()}
        print(f"\n===== {os.path.basename(f)} v{d['version']} =====")
        for mod, fns in fns_by_mod.items():
            for fn, (hdr, body) in fns.items():
                vis = hdr.split(fn)[0].strip()
                is_callable = ("entry" in vis) or (vis.startswith("public") and "friend" not in vis and "package" not in vis)
                if not is_callable:
                    continue
                if want and want not in hdr:
                    continue
                gated = reachable_gate(mod, fn, fns_by_mod, set())
                # value-moving heuristic: does it call coin::take / transfer:: / balance:: ?
                moves = bool(re.search(r'Call\s+(coin|balance|transfer|sui)::', body))
                print(f"  [{'GATED ' if gated else 'UNGATED'}] {'VALUE ' if moves else '      '} {mod}::{fn}   ({vis})")

if __name__ == "__main__":
    main(sys.argv[1])
