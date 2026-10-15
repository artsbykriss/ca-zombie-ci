#!/usr/bin/env python3
"""Batch JSON-RPC probe for Filecoin FEVM. Sends many eth_calls in one HTTP request.
Usage: python3 batch_probe.py <targets.json>
targets.json: [{"name": ..., "to": ..., "data": ...}, ...]
Prints results as JSON lines. Caches nothing (fresh probes).
"""
import json, sys, time, urllib.request

ENDPOINTS = [
    "https://filecoin.drpc.org",
    "https://api.node.glif.io/rpc/v1",
    "https://rpc.ankr.com/filecoin",
]

def batch_call(reqs, ep):
    body = json.dumps(reqs).encode()
    r = urllib.request.Request(ep, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(r, timeout=60) as resp:
        return json.load(resp)

def main():
    targets = json.load(open(sys.argv[1]))
    reqs = [{"jsonrpc": "2.0", "id": i, "method": "eth_call", "params": [{"to": t["to"], "data": t["data"]}, "latest"]} for i, t in enumerate(targets)]
    last_err = None
    for ep in ENDPOINTS:
        try:
            res = batch_call(reqs, ep)
            if not isinstance(res, list):
                res = [res]
            by_id = {r.get('id'): r for r in res}
            out = []
            for i, t in enumerate(targets):
                r = by_id.get(i, {})
                if 'result' in r:
                    v = r['result']
                else:
                    msg = str((r.get('error') or {}).get('message', r))[:120]
                    v = '__REVERT__:' + msg
                out.append({"name": t["name"], "to": t["to"], "value": v})
            json.dump(out, open(sys.argv[2] if len(sys.argv) > 2 else 'batch_out.json', 'w'), indent=1)
            for o in out:
                v = o['value']
                if isinstance(v, str) and v.startswith('0x') and len(v) <= 66:
                    disp = f"{int(v,16)} (e18={int(v,16)/1e18:.6f})"
                else:
                    disp = str(v)[:110]
                print(f"{o['name']:48s} {disp}")
            print(f"# endpoint used: {ep}", file=sys.stderr)
            return
        except Exception as e:
            last_err = f"{ep}: {e}"
            time.sleep(2)
    print('ALL ENDPOINTS FAILED', last_err, file=sys.stderr)
    sys.exit(1)

if __name__ == '__main__':
    main()
