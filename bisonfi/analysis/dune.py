#!/usr/bin/env python3
"""Run a Dune SQL query via API (reads DUNE_API_KEY from env file at runtime; never prints it)."""
import json, os, sys, time, urllib.request

ENV_FILE = "/home/heisenberg/CA/.env"
def _env(name):
    try:
        with open(ENV_FILE) as f:
            for line in f:
                if line.startswith(name + "="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return os.environ.get(name)

KEY = _env("DUNE_API_KEY")
H = {"x-dune-api-key": KEY, "Content-Type": "application/json"}

def api(method, path, body=None):
    url = "https://api.dune.com/api/v1" + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=H, method=method)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())

def run_sql(sql, timeout_s=900):
    r = api("POST", "/query/execute", {"sql": sql, "performance": "medium"})
    eid = r.get("execution_id")
    if not eid:
        print("submit failed:", json.dumps(r)[:500]); return None
    print("execution_id:", eid, file=sys.stderr)
    t0=time.time()
    while time.time()-t0 < timeout_s:
        st = api("GET", f"/execution/{eid}/status")
        state = st.get("state")
        if state == "QUERY_STATE_COMPLETED":
            res = api("GET", f"/execution/{eid}/results?limit=2000")
            return res
        if state in ("QUERY_STATE_FAILED","QUERY_STATE_CANCELLED","QUERY_STATE_EXPIRED"):
            print("state:", state, json.dumps(st)[:800]); return None
        time.sleep(3)
    print("timeout"); return None

if __name__ == "__main__":
    sql = sys.argv[1] if len(sys.argv) > 1 else "SELECT 1"
    res = run_sql(sql)
    if res:
        json.dump(res, sys.stdout, indent=1)
