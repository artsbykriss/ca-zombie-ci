#!/usr/bin/env python3
"""Tiny Dune API helper. Reads DUNE_API_KEY from /home/heisenberg/CA/.env; never prints it."""
import json, os, sys, time, urllib.request

ENV = "/home/heisenberg/CA/.env"

def key():
    for line in open(ENV):
        if line.startswith("DUNE_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"')
    raise SystemExit("no dune key")

K = key()
BASE = "https://api.dune.com/api/v1"

def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"x-dune-api-key": K, "content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())

def run_sql(sql, name="adhoc"):
    q = call("POST", "/query", {"name": name, "query_sql": sql, "is_private": True})
    qid = q["query_id"]
    ex = call("POST", f"/query/{qid}/execute", {})
    eid = ex["execution_id"]
    for _ in range(120):
        st = call("GET", f"/execution/{eid}/status")
        if st.get("state") in ("QUERY_STATE_COMPLETED", "QUERY_STATE_FAILED", "QUERY_STATE_CANCELLED"):
            break
        time.sleep(2)
    res = call("GET", f"/execution/{eid}/results?limit=1000")
    return qid, res

if __name__ == "__main__":
    sql = sys.stdin.read()
    name = sys.argv[1] if len(sys.argv) > 1 else "adhoc"
    qid, res = run_sql(sql, name)
    out = {"query_id": qid,
           "state": res.get("state"),
           "rows": (res.get("result") or {}).get("rows", []),
           "metadata": (res.get("result") or {}).get("metadata", {})}
    print(json.dumps(out, indent=1)[:20000])
