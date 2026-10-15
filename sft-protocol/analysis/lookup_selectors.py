#!/usr/bin/env python3
"""Look up 4-byte selectors via 4byte.directory (public, keyless). Caches results."""
import json, sys, time, urllib.request, os

def lookup(sel, cache):
    if sel in cache:
        return cache[sel]
    url = f"https://www.4byte.directory/api/v1/signatures/?hex_signature={sel}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=25) as r:
            d = json.load(r)
        names = sorted({x['text_signature'] for x in d.get('results', [])})
    except Exception as e:
        names = [f"<error: {e}>"]
    cache[sel] = names
    time.sleep(0.7)
    return names

def main(infile, outfile):
    sel = json.load(open(infile))
    cache = {}
    if os.path.exists(outfile):
        cache = json.load(open(outfile))
    for item in sel:
        s = item['selector']
        names = lookup(s, cache)
        print(f"{s}  {names[:4]}")
        json.dump(cache, open(outfile, 'w'), indent=1)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
