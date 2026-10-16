import json, urllib.request, urllib.parse, sys, time
UA = {"User-Agent": "Blockscout-SkillGuidedScript/0.6.0"}
BASE = "https://mcp.blockscout.com/v1/direct_api_call"

def get(path, params=None):
    q = {"chain_id": "4663", "endpoint_path": path}
    if params:
        for k,v in params.items():
            q[f"query_params[{k}]"] = v
    url = BASE + "?" + urllib.parse.urlencode(q)
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.load(r)
        except Exception as e:
            if i==3: raise
            time.sleep(2*(i+1))

def fetch_all_logs(address, max_pages=200):
    out = []
    params = {}
    pages = 0
    while pages < max_pages:
        d = get(f"/api/v2/addresses/{address}/logs", params)
        items = d.get("data") if isinstance(d, dict) else None
        if items is None:
            print("shape:", json.dumps(d)[:400]); break
        out.extend(items)
        nxt = d.get("pagination", {}).get("next_page_params") if isinstance(d, dict) else None
        if not nxt: break
        params = nxt
        pages += 1
        if pages % 10 == 0: print("pages", pages, "logs", len(out), file=sys.stderr)
    return out

if __name__ == "__main__":
    addr = sys.argv[1]
    outfile = sys.argv[2]
    logs = fetch_all_logs(addr)
    json.dump(logs, open(outfile,"w"), indent=1)
    print("total logs:", len(logs))
