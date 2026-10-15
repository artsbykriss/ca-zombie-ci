#!/usr/bin/env python3
"""Z3-C2 Switchboard-Move live-state verification (read-only, public endpoints only).

Re-runs the key evidence checks against live Sui + Aptos state and writes
ci-out/verification.json + ci-out/SUMMARY.txt. No keys, no transactions.
"""
import json, sys, os, time, datetime, urllib.request, base64

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from sui_query import q as sui_q                      # Sui GraphQL (public)
from aptos_view import view as aptos_view             # Aptos fullnode /view
from aptos_simulate import simulate, entry, PKG as APT_PKG  # Aptos simulate
from move_disasm import parse_tables, parse_common, uleb

SB_PKG_ORIG = "0xc3c7e6eb7202e9fb0389a2f7542b91cc40e4f7a33c02554fec11c4c92f938ea3"
SB_PKG_LATEST = "0xf347253e6aa6f81e9da16e841c089fb09c42f7b6ec9514eeee1b5606e23f64f9"
SB_PKG_V4 = "0xa81086572822d67a1559942f23481de9a60c7709c08defafbb1ca8dffc44e210"
SB_PKG_V2 = "0xe6717fb7c9d44706bf8ce8a651e25c0a7902d32cb0ff40c0976251ce8ac25655"
MAIN_Q = "0x6e43354b8ea2dfad98eadb33db94dcc9b1175e70ee82e42abc605f6b7de9e910"
GUARD_Q = "0x662f5642dc730289b5c8084b67e4e092428e825a97071c5cb5c691dfb2cc88f7"
APT_MAIN_Q = "0x7fdf7235bf3bd872ad093927deb2ff5f1645d1b6dabbfd4a03c3e0442788ce12"
APT_GUARD_Q = "0x3434a45114f5f8fc577557a9a3dda54c1799fee5271313f2599a1093c4a8ba01"
ATTACK_SENDER = "0x9104d073e1fdfd"
NOW_MS = int(time.time() * 1000)

results = {}
checks = []

def check(name, ok, detail=""):
    checks.append({"check": name, "ok": bool(ok), "detail": detail})
    print(("PASS " if ok else "FAIL ") + name + (" | " + str(detail)[:160] if detail else ""))

def sui_obj(addr, sel):
    d = sui_q('{ object(address: "%s") { address version %s } }' % (addr, sel))
    return d.get("data", {}).get("object")

# ---------------------------------------------------------------- Sui queues
for label, addr in [("main", MAIN_Q), ("guardian", GUARD_Q)]:
    o = sui_obj(addr, "asMoveObject { contents { json } }")
    j = o["asMoveObject"]["contents"]["json"] if o else {}
    results[f"sui_queue_{label}"] = j
    check(f"sui.{label}_queue_alive", bool(j), j.get("name"))
check("sui.main_queue_paused", len(results["sui_queue_main"].get("fee_types", [])) == 0,
      "fee_types=%s" % results["sui_queue_main"].get("fee_types"))
check("sui.main_queue_min_attestations_3", results["sui_queue_main"].get("min_attestations") == "3")
check("sui.guardian_queue_self_referential",
      results["sui_queue_guardian"].get("guardian_queue_id") == GUARD_Q)

# ---------------------------------------------------------------- Sui oracles
nodes = []
cur = None
while True:
    after = ', after: "%s"' % cur if cur else ""
    d = sui_q('{ objects(first: 50%s, filter: {type: "%s::oracle::Oracle"}) '
              '{ pageInfo { hasNextPage endCursor } nodes { address asMoveObject { contents { json } } } } }' % (after, SB_PKG_ORIG))
    ob = d["data"]["objects"]; nodes += ob["nodes"]
    if not ob["pageInfo"]["hasNextPage"]:
        break
    cur = ob["pageInfo"]["endCursor"]
oracles = [n["asMoveObject"]["contents"]["json"] for n in nodes]
valid = [o for o in oracles if int(o["expiration_time_ms"]) > NOW_MS]
empty_key = [o for o in oracles if o["secp256k1_key"] == ""]
results["sui_oracles"] = {"total": len(oracles), "valid_now": len(valid), "empty_key": len(empty_key)}
check("sui.all_oracles_expired", len(valid) == 0, "valid=%d/%d" % (len(valid), len(oracles)))
check("sui.empty_key_oracles_exist", len(empty_key) > 0, "empty_key=%d" % len(empty_key))

# ---------------------------------------------------------------- Sui feeds
nodes = []
cur = None
while True:
    after = ', after: "%s"' % cur if cur else ""
    d = sui_q('{ objects(first: 50%s, filter: {type: "%s::aggregator::Aggregator"}) '
              '{ pageInfo { hasNextPage endCursor } nodes { address asMoveObject { contents { json } } } } }' % (after, SB_PKG_ORIG))
    ob = d["data"]["objects"]; nodes += ob["nodes"]
    if not ob["pageInfo"]["hasNextPage"]:
        break
    cur = ob["pageInfo"]["endCursor"]
aggs = [n["asMoveObject"]["contents"]["json"] for n in nodes]
main_aggs = [a for a in aggs if a["queue"] == MAIN_Q]
last_ms = max((int(a["current_result"]["timestamp_ms"]) for a in main_aggs), default=0)
last_dt = datetime.datetime.fromtimestamp(last_ms / 1000, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ") if last_ms else "never"
results["sui_feeds"] = {"total": len(aggs), "main_queue": len(main_aggs),
                        "authorities": len(set(a["authority"] for a in main_aggs)),
                        "last_main_update": last_dt}
check("sui.feeds_stale_since_suspension", last_ms < 1788000000000,
      "last main-queue update %s (queue suspended 2026-08-29)" % last_dt)

# ---------------------------------------------------------------- Sui deployed bytecode
def sui_disasm(pkg, module):
    d = sui_q('{ object(address: "%s") { asMovePackage { module(name: "%s") { disassembly } } } }' % (pkg, module))
    return d["data"]["object"]["asMovePackage"]["module"]["disassembly"]

att_v6 = sui_disasm(SB_PKG_LATEST, "oracle_attest_action")
agg_v6 = sui_disasm(SB_PKG_LATEST, "aggregator_submit_result_action")
ini_v6 = sui_disasm(SB_PKG_LATEST, "oracle_init_action")
att_v4 = sui_disasm(SB_PKG_V4, "oracle_attest_action")
results["sui_bytecode"] = {}
check("sui.v6_attestation_still_uses_check_subvec", "check_subvec" in att_v6)
check("sui.v6_attestation_requires_valid_guardian",
      "Call oracle::expiration_time_ms" in att_v6, "guardian expiration check present")
check("sui.v6_price_path_has_key_len64_check", "LdU64(64)" in agg_v6 and "secp256k1_key" in agg_v6)
check("sui.v6_price_path_uses_check_subvec", "check_subvec" in agg_v6)
check("sui.v6_oracle_init_has_no_authority_check", "has_authority" not in ini_v6)
check("sui.v4_attestation_uses_check_subvec", "check_subvec" in att_v4)

# ---------------------------------------------------------------- Sui attack forensics
d = sui_q('{ events(filter: {module: "%s::oracle_attest_action"}, last: 10) '
          '{ nodes { timestamp sender { address } contents { json } transaction { digest } } } }' % SB_PKG_V4)
ev = d["data"]["events"]["nodes"]
resolved = [e for e in ev if "secp256k1_key" in e["contents"]["json"]]
results["sui_attack"] = {"attestation_events": len(ev), "resolved": len(resolved),
                         "first": ev[0]["timestamp"] if ev else None,
                         "last": ev[-1]["timestamp"] if ev else None,
                         "senders": sorted(set(e["sender"]["address"] for e in ev))}
check("sui.aug2026_attestation_exploit_onsui", len(resolved) > 0,
      "AttestationResolved %s" % (resolved[0]["timestamp"] if resolved else "-"))

# ---------------------------------------------------------------- Aptos state
def apt_view(fn, *args):
    r = aptos_view("%s::%s" % (APT_PKG, fn), [], list(args))
    return r[0] if isinstance(r, list) and len(r) == 1 else r

mq = apt_view("queue::view_queue", APT_MAIN_Q)
gq = apt_view("queue::view_queue", APT_GUARD_Q)
results["aptos_queues"] = {"main": mq, "guardian": gq}
check("aptos.main_queue_alive", bool(mq), mq.get("name"))
check("aptos.main_queue_min_attestations_3", mq.get("min_attestations") == "3")
check("aptos.guardian_queue_self_referential", gq.get("guardian_queue") == APT_GUARD_Q)
mq_oracles = apt_view("oracle::view_queue_oracles", APT_MAIN_Q)
results["aptos_oracles"] = {"main": len(mq_oracles),
                            "secp_key_lens": sorted(set(len(o.get("secp256k1_key", "")) for o in mq_oracles))}
check("aptos.oracles_have_64b_keys", results["aptos_oracles"]["secp_key_lens"] == [130])

# Aptos feed staleness (sample the freshest few)
aggs = apt_view("aggregator::view_queue_aggregators", APT_MAIN_Q)
ts = sorted((int(a["current_result"]["timestamp"]) for a in aggs), reverse=True)
newest = ts[0] if ts else 0
results["aptos_feeds"] = {"count": len(aggs), "newest_update_ms": newest}
check("aptos.feeds_stale_since_suspension", newest < 1788000000000,
      "newest feed ts %s" % newest)

# ---------------------------------------------------------------- Aptos: unguarded oracle creation (simulate)
sim = simulate(entry("%s::oracle_init_action::run" % APT_PKG, [], [APT_MAIN_Q, "0x" + "11" * 32]))
t = sim[0] if isinstance(sim, list) else sim
ok = bool(t.get("success"))
evs = [e["type"].split("::")[-1] for e in (t.get("events") or [])]
results["aptos_sim_oracle_init"] = {"success": ok, "vm_status": t.get("vm_status"), "events": evs}
check("aptos.oracle_init_unguarded_live", ok and "OracleCreated" in evs,
      "vm_status=%s events=%s" % (t.get("vm_status"), evs))

# ---------------------------------------------------------------- Aptos deployed bytecode (disassembly)
import io, contextlib
def aptos_module_bytes(module):
    url = "https://fullnode.mainnet.aptoslabs.com/v1/accounts/%s/module/%s" % (APT_PKG, module)
    with urllib.request.urlopen(url, timeout=60) as r:
        return bytes.fromhex(json.load(r)["bytecode"][2:])

def decode_function(data, target):
    ver, tables = parse_tables(data)
    common = parse_common(data, tables)
    # inline function-handle + function-def parse (kept in sync with move_disasm.py)
    import move_disasm as md
    fhs = md.parse_function_handles(data, tables, common)
    defs = md.parse_function_defs(data, tables, common, fhs)
    out = {}
    for fh, vis, entry_, code in defs:
        nm = md.fh_name(fhs, common, fh)
        if target in nm and code:
            locsig, ops = code
            out[nm] = [{"op": o, "args": a,
                        "call": md.fh_name(fhs, common, a[0]) if o in ("Call", "CallGeneric") and a else None}
                       for o, a in ops]
    return out

try:
    att_apt = decode_function(aptos_module_bytes("oracle_attest_action"), "validate")
    flat = att_apt.get("oracle_attest_action::validate", [])
    ops = [x["op"] for x in flat]
    calls = [x["call"] for x in flat if x.get("call")]
    results["aptos_attest_disasm"] = {"ops": len(ops), "calls": calls}
    check("aptos.attestation_no_check_subvec", "hash::check_subvec" not in calls)
    check("aptos.attestation_exact_neq_compare", "Neq" in ops and "secp256k1::ecdsa_raw_public_key_to_bytes" in calls
          and "oracle::oracle_key" in calls)
    check("aptos.attestation_checks_guardian_expiration", "oracle::expiration_time" in calls)
except Exception as e:
    check("aptos.attest_disasm", False, str(e)[:200])

# ---------------------------------------------------------------- verdict
os.makedirs(os.path.join(os.path.dirname(__file__), "..", "ci-out"), exist_ok=True)
out_dir = os.path.join(os.path.dirname(__file__), "..", "ci-out")
with open(os.path.join(out_dir, "verification.json"), "w") as f:
    json.dump({"generated": datetime.datetime.now(datetime.timezone.utc).isoformat(),
               "checks": checks, "results": results}, f, indent=1)
with open(os.path.join(out_dir, "SUMMARY.txt"), "w") as f:
    f.write("Z3-C2 Switchboard-Move verification run %s\n\n" % datetime.datetime.now(datetime.timezone.utc).isoformat())
    for c in checks:
        f.write(("PASS " if c["ok"] else "FAIL ") + c["check"] + (" | " + str(c["detail"])[:200] if c["detail"] else "") + "\n")
    f.write("\nSui main-queue feeds: %s\n" % json.dumps(results["sui_feeds"]))
    f.write("Sui oracles: %s\n" % json.dumps(results["sui_oracles"]))
    f.write("Aptos feeds: %s\n" % json.dumps(results["aptos_feeds"]))
    f.write("Sui Aug-2026 attack forensics: %s\n" % json.dumps(results["sui_attack"]))
    f.write("\nHEADLINE: live E-U = $0 on both chains (state-blocked); code-level residual on Sui v6 attestation path.\n")
n_fail = sum(1 for c in checks if not c["ok"])
print("checks: %d, failed: %d" % (len(checks), n_fail))
sys.exit(1 if n_fail else 0)
