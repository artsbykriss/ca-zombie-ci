#!/usr/bin/env python3
"""Scan candidate addresses for on-chain contract existence + labels (read-only, resumable)."""
import json
import os
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/shadeswap/analysis")
from secret_abci import contract_info  # noqa

addrs = [l.strip() for l in open("/tmp/opencode/all_addrs.txt") if l.strip()]
OUT = "/home/heisenberg/CA/shadeswap/analysis/contract-scan.jsonl"
done = set()
if os.path.exists(OUT):
    for line in open(OUT):
        try:
            done.add(json.loads(line)["address"])
        except Exception:
            pass

with open(OUT, "a") as f:
    for i, a in enumerate(addrs):
        if a in done:
            continue
        try:
            info, h = contract_info(a)
            rec = {"address": a, "height": h, **info}
        except Exception as e:
            rec = {"address": a, "error": str(e)[:120]}
        f.write(json.dumps(rec) + "\n")
        f.flush()
        print(f"{i:3d} {a} code={rec.get('code_id')} label={rec.get('label')!r} admin={rec.get('admin')} err={rec.get('error','')}", flush=True)
        time.sleep(0.4)
