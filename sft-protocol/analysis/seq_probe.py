#!/usr/bin/env python3
"""Run a targets JSON sequentially with fc.py (cache-aware, fast)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fc import rpc, load_cache

def main():
    targets = json.load(open(sys.argv[1]))
    out = []
    cache = load_cache()
    for t in targets:
        try:
            r = rpc('eth_call', [{'to': t['to'], 'data': t['data']}, 'latest'], cache)
        except Exception as e:
            r = f'<transport err {str(e)[:80]}>'
        out.append({'name': t['name'], 'to': t['to'], 'value': r})
        if isinstance(r, str) and r.startswith('0x') and len(r) <= 66:
            disp = f"{int(r,16)} (e18={int(r,16)/1e18:.6f})"
        else:
            disp = str(r)[:110]
        print(f"{t['name']:48s} {disp}", flush=True)
    json.dump(out, open(sys.argv[2] if len(sys.argv) > 2 else 'seq_out.json', 'w'), indent=1)

if __name__ == '__main__':
    main()
