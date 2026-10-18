import json
import lib

BN = 26217462
FLIPS = json.load(open("canonical_flippers.json"))
# keep real Flippers: kicks() succeeds and bids(1) decodes to 8 words
flips = []
for f in FLIPS:
    if not f.get("kicks"):
        continue
    try:
        r = lib.eth_call(f["flip"], "0x4423c5f1" + lib.pad_u256(1), hex(BN))
        if r and r != "0x" and len(r) >= 2 + 64 * 8:
            flips.append(f)
    except Exception:
        pass

print("flippers to scan", len(flips), "bids", sum(f["kicks"] for f in flips), flush=True)

calls = []
meta = []
for f in flips:
    for i in range(1, f["kicks"] + 1):
        calls.append((f["flip"], "0x4423c5f1" + lib.pad_u256(i)))
        meta.append((f, i))

res = lib.mc3(calls, block=hex(BN), chunk=200)
now = lib.block_ts(BN)
rows = []
for (f, i), (ok, rb) in zip(meta, res):
    if not ok or len(rb) < 32 * 8:
        continue
    w = [rb[j:j + 32].hex() for j in range(0, 256, 32)]
    row = {
        "ilk": f["ilk"], "flip": f["flip"], "id": i,
        "bid": int(w[0], 16), "lot": int(w[1], 16),
        "guy": lib.word_addr(w[2]), "tic": int(w[3], 16),
        "end": int(w[4], 16), "usr": lib.word_addr(w[5]),
        "gal": lib.word_addr(w[6]), "tab": int(w[7], 16),
    }
    if row["lot"] > 0:
        row["expired"] = row["end"] < now
        row["open_no_bid"] = row["guy"] == "0x" + "0" * 40
        row["age_days"] = round((now - row["end"]) / 86400, 1) if row["end"] else None
        rows.append(row)

print("undealt bids", len(rows), flush=True)
flagged = [r for r in rows if (r["lot"] > 0 and r["guy"] != "0x" + "0" * 40 and r["end"] < now)]
print("expired with guy (dealable)", len(flagged), flush=True)
json.dump({"block": BN, "timestamp": now, "flippers": flips, "undealt": rows,
           "flagged": flagged}, open("bids_scan.json", "w"), indent=1)
for r in sorted(rows, key=lambda x: -x["lot"]):
    print(r["ilk"], r["flip"], r["id"], "lot", r["lot"] / 1e18, "tab", r["tab"] / 1e18,
          "guy", r["guy"], "end", r["end"], "age_d", r["age_days"])
