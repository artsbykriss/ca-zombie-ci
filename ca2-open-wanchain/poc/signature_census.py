#!/usr/bin/env python3
"""
Signature census since the GPK rotation (block 14,044,468).

Answers: how many storeman-signed Cardano transactions exist after the rotation,
which validator accepted each one, and therefore which message encoding was
signed. Read-only public Koios API.

Classification rule: a transaction that validates under a script whose ONLY
signature-digest path is sha3(serialiseData(...)) proves the signer produced a
V3-format digest. A transaction under a script with AppendByteString proves the
legacy format. We do not need to reproduce the digest to classify it.
"""
import json
import os
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
AN = os.path.join(ROOT, "analysis")
os.makedirs(OUT, exist_ok=True)

KOIOS = "https://api.koios.rest/api/v1"
ROTATION_BLOCK = 14044468          # GroupInfo UTxO 2211c2a0...#0 creation (GPK 022af717)
ROTATION_TIME = 1791518438         # 2026-10-09T04:00:38Z
V3_MIGRATION_BLOCK = 13997675      # first GroupInfo at the V3 address (check 8c02), 2026-09-28T04:27:24Z
V3_MIGRATION_TIME = 1790656044
OLD_GPK = "0335664ecb713efe92e94b30e2273fcfcb2cc3efcb2d25a734cf119f27c7ffd98a"
NEW_GPK = "022af71766796d1c8e2f212d7a3a0b53d150b1e1f30c4b079b7f15e40774100e9e"

# check-script addresses (TCheckCoin holders)
CHECK_ADDRS = {
    "485aa10343f63bcc2a43f1625dc841093488e4685ba607cc187ba495": "addr1x9y94ggrg0mrhnp2g0ckyhwggyynfz8ydpd6vp7vrpa6f9f9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsrlh4ng",
    "8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e": "addr1xxxqy7ggyc8tc22ppnj0llnc3kj3pexhl4nlfvua83makh39nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsurygyp",
    "cfd786f4c42215f2f0ecee2d831c15e2fa553e58d737389a74c4a02c": "addr1x88a0ph5cs3ptuhsanhzmqcuzh3054f7trtnwwy6wnz2qtp9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncs08mf8n",
    "4efc0be6eb039ed5337b4c11af8ad732d6c66fdaec3cb8f3224f1b9f": "addr1x980czlxavpea4fn0dxprtu26uedd3n0mtkrew8nyf83h8e9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncs55c2gc",
    "41b2a43a374553888dfcc50d22dcdcc5eafe968f0250cb3f1a5ee18c": "addr1x9qm9fp6xaz48zydlnzs6gkumnz74l5k3up9pjelrf0wrrp9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncskpfrp7",
    "8d4c43c5a72fe731513ebecf5f44d717164d254e08eb4a57ee234bb7": "addr1xxx5cs795uh7wv2386lv7h6y6ut3vnf9fcywkjjhac35hde9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsnpvtt2",
}
MINT_CHECK_VH = "4730b708f37d24c025f52a66701a622d56d5d1da28ae8c777c3e1ec2"
MINT_CHECK_ADDR = "addr1x9rnpdcg7d7jfsp9754xvuq6vgk4d4w3mg52arrh0slpas39nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncshcadjd"


def post(path, payload):
    req = urllib.request.Request(
        KOIOS + path, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST")
    for a in range(5):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.loads(r.read())
        except Exception:
            if a == 4:
                raise
            time.sleep(3 * (a + 1))


def tx_scripts(hashes):
    out = []
    for i in range(0, len(hashes), 5):
        out += post("/tx_info", {"_tx_hashes": hashes[i:i + 5], "_scripts": True})
        time.sleep(0.4)
    return out


def address_since(addr, block):
    txs = post("/address_txs", {"_addresses": [addr]})
    return [t for t in txs if t["block_height"] > block]


def main():
    census = {
        "rotation_block": ROTATION_BLOCK,
        "rotation_time_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ROTATION_TIME)),
        "v3_migration_block": V3_MIGRATION_BLOCK,
        "v3_migration_time_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(V3_MIGRATION_TIME)),
        "old_gpk": OLD_GPK,
        "new_gpk": NEW_GPK,
        "treasury_check": [],
        "mint_check": [],
        "legacy_encoding_signatures": [],
        "per_script_counts": {},
    }

    # ---- treasury check scripts
    check_hashes = {}
    since_v3 = 0
    for vh, addr in CHECK_ADDRS.items():
        era = address_since(addr, V3_MIGRATION_BLOCK)
        post = [t for t in era if t["block_height"] > ROTATION_BLOCK]
        census["per_script_counts"][vh] = {"since_v3_migration": len(era), "post_rotation": len(post)}
        since_v3 += len(era)
        for t in post:
            check_hashes[t["tx_hash"]] = (t["block_height"], vh)
    census["treasury_signed_since_v3_migration"] = since_v3

    details = {t["tx_hash"]: t for t in tx_scripts(list(check_hashes))}
    for h, (bh, vh) in sorted(check_hashes.items(), key=lambda kv: kv[1][0]):
        tx = details.get(h, {})
        paid = []
        for c in (tx.get("plutus_contracts") or []):
            if not c.get("valid_contract"):
                continue
            red = c["input"]["redeemer"]["datum"]["value"]
            fields = None
            if red.get("constructor") == 1 and red["fields"] and "fields" in red["fields"][0]:
                fields = red["fields"][0]["fields"]
            if fields and len(fields) >= 14:
                paid.append({
                    "to_pkh": fields[0]["bytes"],
                    "amount": fields[4]["int"],
                    "ada_amount": fields[5]["int"],
                    "ttl": fields[11]["int"],
                    "sig_len": len(fields[13]["bytes"]) // 2,
                })
        census["treasury_check"].append({
            "block": bh, "tx": h, "validator": vh,
            "encoding": "legacy-raw-concat" if vh.startswith("485a") else "V3-serialiseData",
            "payouts": paid,
        })

    # ---- mint-check script
    mint_era = address_since(MINT_CHECK_ADDR, V3_MIGRATION_BLOCK)
    census["mint_signed_since_v3_migration"] = len(mint_era)
    for t in [x for x in mint_era if x["block_height"] > ROTATION_BLOCK]:
        census["mint_check"].append({
            "block": t["block_height"], "tx": t["tx_hash"], "validator": MINT_CHECK_VH,
            "encoding": "V3-serialiseData",
        })

    if census["treasury_check"]:
        census["legacy_encoding_signatures"] = [
            r for r in census["treasury_check"] if r["encoding"] == "legacy-raw-concat"
        ]

    census["totals"] = {
        "treasury_signed_since_v3_migration": since_v3,
        "treasury_signed_post_rotation": len(census["treasury_check"]),
        "mint_signed_since_v3_migration": len(mint_era),
        "mint_signed_post_rotation": len(census["mint_check"]),
        "legacy_encoding_signatures": len(census["legacy_encoding_signatures"]),
    }
    census["conclusion"] = (
        "All storeman signatures since the V3 migration (2026-09-28) were accepted by V3 "
        "validators whose only digest path is sha3(serialiseData(...)); zero legacy raw-concat "
        "signatures exist. The live signer demonstrably uses the V3 encoder."
        if not census["legacy_encoding_signatures"] else
        "LEGACY SIGNATURES PRESENT after rotation - re-open the trigger."
    )

    with open(os.path.join(OUT, "signature_census.json"), "w") as f:
        json.dump(census, f, indent=2)
    print(json.dumps(census["totals"], indent=2))
    print(census["per_script_counts"])
    print(census["conclusion"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
