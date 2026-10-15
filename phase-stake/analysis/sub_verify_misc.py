#!/usr/bin/env python3
"""Verify vlist entry layout, pdSOL pool account type/size, retry tla on mainnet-beta."""
import json, sys, time, struct, base64, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, get_data, b58encode

OUT = {}
# 1) validator list, fresh, full data
own, d = get_data("phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821")
OUT["vlist_owner"], OUT["vlist_len"] = own, len(d)
LEN_ENTRY = 73
hdr_type = d[0]
maxv = struct.unpack_from("<I", d, 1)[0]
n = struct.unpack_from("<I", d, 5)[0]
OUT["vlist_header"] = {"account_type": hdr_type, "max_validators": maxv, "vec_len": n}
entries = []
for i in range(n):
    off = 9 + i * LEN_ENTRY
    e = d[off:off + LEN_ENTRY]
    entries.append({
        "idx": i,
        "active_lamports": struct.unpack_from("<Q", e, 0)[0],
        "transient_lamports": struct.unpack_from("<Q", e, 8)[0],
        "last_update_epoch": struct.unpack_from("<Q", e, 16)[0],
        "transient_seed": struct.unpack_from("<Q", e, 24)[0],
        "unused": struct.unpack_from("<I", e, 32)[0],
        "validator_seed": struct.unpack_from("<I", e, 36)[0],
        "status": e[40],
        "vote": b58encode(e[41:73]),
    })
OUT["vlist_entries"] = entries
json.dump(OUT, open("/home/heisenberg/CA/phase-stake/analysis/vlist_recheck.json", "w"), indent=2)
print("vlist len:", len(d), "header:", OUT["vlist_header"])
for e in entries:
    print(e)

# 2) pdSOL pool account type / size
own2, d2 = get_data("aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6")
print("\npdSOL owner:", own2, "len:", len(d2), "account_type:", d2[0] if d2 else None)

# 3) tla retry on mainnet-beta only, few attempts
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
def post(url, method, params, timeout=45):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

got = False
for i in range(6):
    time.sleep(8)
    try:
        d3 = post("https://api.mainnet-beta.solana.com", "getTokenLargestAccounts", [MINT])
        if "result" in d3:
            json.dump(d3, open("/home/heisenberg/CA/phase-stake/analysis/tla_raw.json", "w"), indent=2)
            print("\nTLA OK, n =", len(d3["result"]["value"]))
            for h in d3["result"]["value"][:20]:
                print(h)
            got = True
            break
        print("tla try", i, str(d3.get("error"))[:90])
    except Exception as ex:
        print("tla try", i, "exc", str(ex)[:90])
if not got:
    print("\nTLA not obtained yet (will rely on background retry loop)")
