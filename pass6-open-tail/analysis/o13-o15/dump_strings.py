#!/usr/bin/env python3
"""Fetch program ELF (via programdata account) and dump printable strings.
Saves a FILTERED strings dump (not the whole ELF)."""
import json, base64, re, sys
from sol_rpc import get_account_info

PROGRAMS = {
    "O13": ("DiversiFi", "3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk", "BonoESSTLj2dnopx9ZjAVszqTnKB5zEAHb8EySLBtUqj"),
    "O14": ("Overpass",  "WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum", "FyMXrZUg5pkZACoxZXFFQ2kB5twTdKbk1eAyXzLh6YM7"),
    "O15": ("Zodial",    "zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ", "2JEHikpqMTTcyiZbXNHGjyaQg4pr67VqbgTBybFCvors"),
}

def fetch_programdata(pd_addr, total_len):
    """Fetch full programdata via dataSlice chunks."""
    chunk = 9000
    parts = []
    off = 0
    while off < total_len:
        end = min(off + chunk - 1, total_len - 1)
        r = get_account_info(pd_addr)
        # dataSlice not supported by getAccountInfo; use raw chunk via getMultipleAccounts? 
        break
    # fallback: single full fetch
    r = get_account_info(pd_addr)
    v = r.get("result", {}).get("value")
    if not v:
        raise RuntimeError(f"no account {pd_addr}: {json.dumps(r)[:200]}")
    return base64.b64decode(v["data"][0])

def strings(data, minlen=6):
    return re.findall(rb"[ -~]{%d,}" % minlen, data)

def main():
    for k,(name,pid,pd) in PROGRAMS.items():
        try:
            raw = fetch_programdata(pd, 0)
        except Exception as e:
            print(k, name, "FETCH FAIL", e); continue
        print(f"{k} {name}: programdata bytes = {len(raw)}")
        # ProgramData header is 45 bytes
        elf = raw[45:]
        print(f"   elf bytes = {len(elf)} magic={elf[:4]!r}")
        ss = strings(elf, 6)
        ss = [s.decode("latin1") for s in ss]
        with open(f"strings_{k}_{name}.txt", "w") as f:
            f.write("\n".join(ss))
        print(f"   strings = {len(ss)}")

if __name__ == "__main__":
    main()
