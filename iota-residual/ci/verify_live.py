#!/usr/bin/env python3
"""Live-state verification for iota-residual (TokenLabs vIOTA on IOTA L1 + Deepr Finance on IOTA EVM).

Read-only, keyless public RPCs. No secrets. Outputs ci-out/live_state.json.
Checks (TokenLabs):
  * pool object fields (v2), paused=false, version=2, dynamic field validator_cap_base
  * cert::Metadata<CERT>.total_supply  -> vIOTA supply
  * ratio = (pending + total_staked + total_rewards - collected_rewards) / supply
  * solvency guard: supply <= total  (math::ratio aborts otherwise)
  * invariants: total_staked == sum of vault.total_staked (validator_set dynamic fields)
  * daily reward credit estimate from FeeCollectedEvent values (fee = 0.99% of increment)
Checks (Deepr):
  * comptroller getAllMarkets() -> per-market cash/totalBorrows/exchangeRate/underlying
  * comptroller admin/closeFactor/liquidationIncentive/oracle
"""
import json, urllib.request, datetime, sys, os

L1 = "https://api.mainnet.iota.cafe"
EVM_RPCS = ["https://rpc.ankr.com/iota_evm", "https://8822.rpc.thirdweb.com"]
PKG_V2 = "0x6ab984dfae09bbef27551765622a85f461e0b46629eee60807b6e5399c0f7f0f"
POOL = "0xb435fa61ee8d5473ab36de02c88756f8c74fcc031b4e3a2fe2a6647bb06b2872"
META = "0xb45b32d8d58c6499795036faa92b0561c6df089cdd4fc6ae8a0543981a698bf1"
VSET = "0x8a49f19ed89c2d24c7748a65bffc5f97ad9ef187f08660102e620140a8ceb472"
COMPTROLLER = "0xee07121d97FDEA35675e02017837a7a43aeDa48F"

def rpc(url, method, params):
    req = urllib.request.Request(url, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def evm(url, method, params):
    return rpc(url, method, params).get("result")

out = {"generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "tokenlabs": {}, "deepr": {}}

# ---------------- TokenLabs (IOTA L1) ----------------
try:
    ckpt = rpc(L1, "iota_getLatestCheckpointSequenceNumber", []).get("result")
    out["tokenlabs"]["latest_checkpoint"] = ckpt
    pool = rpc(L1, "iota_getObject", [POOL, {"showType": True, "showContent": True, "showOwner": True}])["result"]["data"]
    f = pool["content"]["fields"]
    mf = rpc(L1, "iota_getObject", [META, {"showType": True, "showContent": True}])["result"]["data"]["content"]["fields"]
    ts_field = mf["total_supply"]
    supply = int(ts_field["fields"]["value"] if isinstance(ts_field, dict) and "fields" in ts_field else ts_field["value"])
    pending = int(f["pending"]); ts = int(f["total_staked"]); tr = int(f["total_rewards"]); cr = int(f["collected_rewards"])
    total = pending + ts + (tr - cr)
    out["tokenlabs"].update({
        "pool_object_version": pool["version"], "pool_type": pool["type"],
        "paused": f["paused"], "version_field": f["version"], "pending": pending,
        "total_staked": ts, "total_rewards": tr, "collected_rewards": cr,
        "min_stake": int(f["min_stake"]), "base_reward_fee": int(f["base_reward_fee"]),
        "rewards_threshold": int(f["rewards_threshold"]),
        "max_validator_stake_per_epoch": int(f["max_validator_stake_per_epoch"]),
        "rewards_update_ts": int(f["rewards_update_ts"]),
        "supply_vIOTA": supply,
        "pooled_iota": total,
        "ratio_shares_per_iota_x1e18": (supply * 10**18) // total,
        "iota_per_vIOTA": total / supply,
        "solvent_supply_le_total": supply <= total,
        "jIT_daily_reward_iota": None,
    })
    # validator set is a child object: read it from the pool's field
    vs = f["validator_set"]["fields"]
    prio = {}
    for e in vs["validators"]["fields"]["contents"]:
        prio[e["fields"]["key"]] = int(e["fields"]["value"])
    out["tokenlabs"]["validators"] = {k: prio.get(k) for k in vs["sorted_validators"]}
    out["tokenlabs"]["validators_priorities"] = prio
    out["tokenlabs"]["bad_validators_priority0"] = [v for v, p in prio.items() if p == 0]
    # vault sum: dynamic fields of the vaults Table -> multiGetObjects -> sum total_staked
    try:
        tid = vs["vaults"]["fields"]["id"]["id"]
        dfs = rpc(L1, "iotax_getDynamicFields", [tid, None, 100])["result"]["data"]
        ids = [d["objectId"] for d in dfs]
        objs = rpc(L1, "iota_multiGetObjects", [ids, {"showContent": True}])["result"]
        vsum = 0; nonempty = 0
        for o in objs:
            val = o["data"]["content"]["fields"]["value"]["fields"]
            vsum += int(val["total_staked"])
            if int(val["total_staked"]) > 0:
                nonempty += 1
        out["tokenlabs"]["vaults_found"] = len(dfs)
        out["tokenlabs"]["vaults_nonempty"] = nonempty
        out["tokenlabs"]["vault_total_staked_sum"] = vsum
        out["tokenlabs"]["vault_sum_equals_total_staked"] = (vsum == ts)
    except Exception as e:
        out["tokenlabs"]["vault_scan_note"] = f"vault scan failed: {e}"
    # pool dynamic field: validator_cap_base
    try:
        pds = rpc(L1, "iotax_getDynamicFields", [POOL, None, 10])["result"]["data"]
        for d in pds:
            nm = d.get("name", {})
            if nm.get("value") == "validator_cap_base" or (isinstance(nm.get("value"), list)):
                o = rpc(L1, "iota_getObject", [d["objectId"], {"showContent": True}])["result"]["data"]
                out["tokenlabs"]["validator_cap_base"] = int(o["content"]["fields"]["value"])
        out["tokenlabs"]["pool_dynamic_field_names"] = [d.get("name", {}).get("value") for d in pds]
    except Exception as e:
        out["tokenlabs"]["dyn_field_note"] = str(e)
    # fee events (daily reward estimate): last 50, fee = 0.99% of daily increment
    try:
        T = "0xe4abf8b6183c106282addbfb8483a043e1a60f1fd3dd91fb727fa284306a27fd::native_pool::FeeCollectedEvent"
        ev = rpc(L1, "iotax_queryEvents", [{"MoveEventType": T}, None, 50, True])["result"]["data"]
        uniq = {}
        for e in ev:
            uniq[(e["id"]["txDigest"], e["parsedJson"]["value"])] = int(e["timestampMs"])
        rows = sorted(uniq.items(), key=lambda x: x[1])
        fees = [int(k[1]) for k, _ in rows]
        last7 = fees[-7:] if len(fees) >= 7 else fees
        mean_fee = sum(last7) / len(last7)
        R = mean_fee / 0.0099
        out["tokenlabs"]["last_fee_events"] = len(rows)
        out["tokenlabs"]["mean_daily_fee_iota"] = mean_fee / 1e9
        out["tokenlabs"]["daily_reward_credit_iota_est"] = R / 1e9
        out["tokenlabs"]["jIT_daily_reward_iota"] = R / 1e9
        # JIT attacker profit at X = TVL (value transfer from incumbent holders)
        X = ts
        out["tokenlabs"]["jit_profit_at_X_eq_TVL_iota_per_day"] = (X / (total + X)) * (R * (1 - 0.0099)) / 1e9
    except Exception as e:
        out["tokenlabs"]["fee_event_note"] = str(e)
except Exception as e:
    out["tokenlabs"]["error"] = repr(e)

# ---------------- Deepr (IOTA EVM) ----------------
url = None
for u in EVM_RPCS:
    try:
        if evm(u, "eth_chainId", []):
            url = u
            break
    except Exception:
        continue
out["deepr"]["rpc"] = url
if url:
    try:
        bn = int(evm(url, "eth_blockNumber", []), 16)
        out["deepr"]["block"] = bn
        sel = lambda s: "0x" + s
        def call(to, sig):
            return evm(url, "eth_call", [{"to": to, "data": sig}, hex(bn)])
        # getAllMarkets()
        data = call(COMPTROLLER, "0xb0772d0b")
        # decode address[]
        raw = data[2:]
        off = int(raw[0:64], 16) * 2
        n = int(raw[off:off + 64], 16)
        addrs = ["0x" + raw[off + 64 + i * 64 + 24: off + 64 + (i + 1) * 64] for i in range(n)]
        out["deepr"]["markets"] = addrs
        # comptroller config
        cfgs = {
            "closeFactorMantissa": "0xe8755446",   # closeFactorMantissa()
            "liquidationIncentiveMantissa": "0x4ada90af",  # liquidationIncentiveMantissa()
            "admin": "0xf851a440",
            "oracle": "0x7dc0d1d0",
        }
        c = {}
        for k, sig in cfgs.items():
            try:
                r = call(COMPTROLLER, sig)
                c[k] = r if len(r) <= 66 else r[:66] + "..."
            except Exception as e:
                c[k] = f"err:{e}"
        out["deepr"]["comptroller"] = c
        mk = {}
        for m in addrs:
            d = {}
            for k, sig in [("underlying", "0x6f307dc3"), ("cash", "0x3b1d21a2"),
                           ("totalBorrows", "0x47bd3718"), ("totalReserves", "0x8f840ddd"),
                           ("totalSupply", "0x18160ddd"), ("exchangeRateStored", "0x182df0f5"),
                           ("accrualBlockNumber", "0x6c540baf")]:
                try:
                    r = call(m, sig)
                    d[k] = r
                except Exception as e:
                    d[k] = f"err:{e}"
            mk[m] = d
        out["deepr"]["market_state"] = mk
    except Exception as e:
        out["deepr"]["error"] = repr(e)

os.makedirs("ci-out", exist_ok=True)
with open("ci-out/live_state.json", "w") as fh:
    json.dump(out, fh, indent=1)
print(json.dumps(out, indent=1)[:6000])
print("\nWROTE ci-out/live_state.json")
