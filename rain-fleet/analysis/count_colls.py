import json, sol_rpc as S, time
rows = [json.loads(l) for l in open("fleet_map_main.jsonl")]
b58disc = S.b58encode(bytes.fromhex("132d631dc432e475"))
out = []
for r in rows:
    pid = r["program"]
    try:
        res = S.rpc("getProgramAccounts", [pid, {"encoding":"base64","dataSlice":{"offset":0,"length":0},
            "filters":[{"memcmp":{"offset":0,"bytes":b58disc}}],"commitment":"finalized"}])
        n = len(res)
    except Exception as e:
        n = f"ERR {str(e)[:60]}"
    out.append({"program": pid, "collaterals": n, "code_size": r["code_size"], "deployed": r["last_deploy_utc"]})
    print(json.dumps(out[-1]), flush=True)
json.dump(out, open("collateral_counts.json","w"), indent=1)
