#!/usr/bin/env python3
"""C2-36 Phase Delegation — end-to-end on-chain verification (read-only).

Re-proves, from public RPCs only, every headline claim of the report:
  1. Pool account owner == canonical SPL Stake Pool program SPoo1...
  2. Deployed program ELF == official solana-program/stake-pool program@v2.1.0 release asset
     (sha256 of programdata[45:] vs the downloaded release .so)
  3. Pool state decode: manager/staker/deposit-auth/mint/fee-account/total/supply/fees
  4. Withdraw authority == PDA([pool, "withdraw"], SPoo1) == pool mint authority
  5. All 110 validator stake accounts are PDAs([vote, pool]) with staker == withdrawer == PDA
     (zero orphaned/foreign-controlled stake accounts; also a getProgramAccounts memcmp sweep)
  6. Reserve stake account controlled by the PDA; no lockup; totals add up
  7. No pending FutureEpoch fee changes; no extra Option fields set
  8. SOL price + USD valuation of total pool lamports

Writes ci-out/verification.json. Public keyless endpoints only — safe for the public CI repo.
"""
import base64, hashlib, json, itertools, os, sys, time, urllib.request

ENDPOINTS = ["https://solana-rpc.publicnode.com", "https://api.mainnet-beta.solana.com"]
POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
VLIST = "aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ"
MINT = "aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF"
PROGRAM = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"
PROGRAMDATA = "EmiU8AQkB2sswTxVB6aCmsAJftoowZGGDXuytm6X65R3"
RELEASE_SHA256 = "ec2dfefaa70d560754a0000f39bd2cabc192b895d36205b3c428f601b6e1d7e1"
RELEASE_URL = "https://github.com/solana-program/stake-pool/releases/download/program%40v2.1.0/spl-stake-pool.so"
EXPECT = {
    "manager": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
    "staker": "QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk",
    "withdraw_pda": "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn",
    "deposit_pda": "4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8",
    "manager_fee_account": "HC77HUgE6XpEVnS6RtNwe1yf7a1BoBdQzdxyWrAsxVac",
    "reserve": "aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC",
    "num_validators": 110,
}

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n: n, r = divmod(n, 58); out = B58[r] + out
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + (out or "")
def b58dec(s):
    n = 0
    for ch in s: n = n * 58 + B58.index(ch)
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + n.to_bytes((n.bit_length() + 7) // 8, "big")

_state = {"i": 0}
def rpc(method, params, tries=8, timeout=60):
    last = None
    for attempt in range(tries):
        url = ENDPOINTS[(_state["i"] + attempt) % len(ENDPOINTS)]
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "zombie-ci/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]; time.sleep(1.0 + attempt); continue
            _state["i"] += attempt + 1
            return out["result"]
        except Exception as e:
            last = str(e); time.sleep(1.0 + attempt)
    raise RuntimeError(f"rpc {method} failed: {last}")

# ---------- ed25519 PDA derivation ----------
P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
def _on_curve(b):
    y = int.from_bytes(b, "little") & ((1 << 255) - 1)
    if y >= P: return False
    yy = y * y % P; u = (yy - 1) % P; v = (D * yy + 1) % P
    w = u * pow(v, P - 2, P) % P
    return w == 0 or pow(w, (P - 1) // 2, P) == 1
def find_pda(seeds, program):
    for bump in range(255, -1, -1):
        a = hashlib.sha256(b"".join(list(seeds) + [bytes([bump])]) + program + b"ProgramDerivedAddress").digest()
        if not _on_curve(a): return a, bump
    raise RuntimeError("no bump")

def get_account(addr):
    res = rpc("getAccountInfo", [addr, {"encoding": "base64", "commitment": "finalized"}])
    return res["value"]

def decode_pool(raw):
    u64 = lambda o: int.from_bytes(raw[o:o+8], "little")
    d = {"account_type": raw[0]}
    o = 1
    for f in ["manager", "staker", "stake_deposit_authority"]: d[f] = b58enc(raw[o:o+32]); o += 32
    d["stake_withdraw_bump_seed"] = raw[o]; o += 1
    for f in ["validator_list", "reserve_stake", "pool_mint", "manager_fee_account", "token_program_id"]:
        d[f] = b58enc(raw[o:o+32]); o += 32
    d["total_lamports"] = u64(o); o += 8
    d["pool_token_supply"] = u64(o); o += 8
    d["last_update_epoch"] = u64(o); o += 8
    d["lockup"] = {"ts": int.from_bytes(raw[o:o+8], "little", signed=True), "epoch": u64(o+8), "custodian": b58enc(raw[o+16:o+48])}; o += 48
    def fee(o): return (u64(o), u64(o+8))
    d["epoch_fee"] = fee(o); o += 16
    # interleaved dynamic fields, exactly as the borsh layout
    def tag(name):
        d[f"_tag_{name}"] = raw[o]
        return raw[o]
    if tag("next_epoch_fee"): o += 1; d["next_epoch_fee"] = fee(o); o += 16
    else: o += 1
    if tag("pref_dep"): d["pref_dep"] = b58enc(raw[o+1:o+33]); o += 33
    else: o += 1
    if tag("pref_wd"): d["pref_wd"] = b58enc(raw[o+1:o+33]); o += 33
    else: o += 1
    d["stake_deposit_fee"] = fee(o); o += 16
    d["stake_withdrawal_fee"] = fee(o); o += 16
    if tag("next_stake_wd"): o += 1; d["next_stake_wd"] = fee(o); o += 16
    else: o += 1
    d["stake_referral_fee"] = raw[o]; o += 1
    if tag("sol_dep_auth"): d["sol_dep_auth"] = b58enc(raw[o+1:o+33]); o += 33
    else: o += 1
    d["sol_deposit_fee"] = fee(o); o += 16
    d["sol_referral_fee"] = raw[o]; o += 1
    if tag("sol_wd_auth"): d["sol_wd_auth"] = b58enc(raw[o+1:o+33]); o += 33
    else: o += 1
    d["sol_withdrawal_fee"] = fee(o); o += 16
    if tag("next_sol_wd"): o += 1; d["next_sol_wd"] = fee(o); o += 16
    else: o += 1
    d["last_epoch_pool_token_supply"] = u64(o); o += 8
    d["last_epoch_total_lamports"] = u64(o); o += 8
    d["_decoded_bytes"] = o
    return d

def decode_vlist(raw):
    u64 = lambda o: int.from_bytes(raw[o:o+8], "little")
    u32 = lambda o: int.from_bytes(raw[o:o+4], "little")
    assert raw[0] == 2
    maxv = u32(1); n = u32(5)
    vals = []; o = 9
    for i in range(n):
        vals.append({
            "active": u64(o), "transient": u64(o+8), "last_update_epoch": u64(o+16),
            "transient_seed_suffix": u64(o+24), "unused": u32(o+32),
            "validator_seed_suffix": u32(o+36), "status": raw[o+40],
            "vote": b58enc(raw[o+41:o+73])})
        o += 73
    return {"max_validators": maxv, "num": n, "validators": vals}

def main():
    result = {"generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "checks": {}, "failures": []}
    def check(name, ok, detail=None):
        result["checks"][name] = {"ok": bool(ok), "detail": detail}
        print(("PASS " if ok else "FAIL ") + name + (f"  {detail}" if detail is not None else ""))
        if not ok: result["failures"].append(name)

    slot = rpc("getSlot", [{"commitment": "finalized"}])
    epoch = rpc("getEpochInfo", [{"commitment": "finalized"}])["epoch"]
    result["slot"] = slot; result["epoch"] = epoch

    # 1. pool account
    pv = get_account(POOL)
    check("pool_owner_is_SPoo1", pv and pv["owner"] == PROGRAM, pv and pv["owner"])
    raw = base64.b64decode(pv["data"][0])
    pool = decode_pool(raw)
    result["pool"] = pool
    check("pool_account_type", pool["account_type"] == 1, pool["account_type"])
    check("manager", pool["manager"] == EXPECT["manager"], pool["manager"])
    check("staker", pool["staker"] == EXPECT["staker"], pool["staker"])
    check("stake_deposit_authority", pool["stake_deposit_authority"] == EXPECT["deposit_pda"], pool["stake_deposit_authority"])
    check("pool_mint", pool["pool_mint"] == MINT)
    check("manager_fee_account", pool["manager_fee_account"] == EXPECT["manager_fee_account"])
    check("reserve_stake", pool["reserve_stake"] == EXPECT["reserve"])
    check("all_options_none", all(pool[f"_tag_{k}"] == 0 for k in
          ["next_epoch_fee", "pref_dep", "pref_wd", "next_stake_wd", "sol_dep_auth", "next_sol_wd", "sol_wd_auth"]))
    check("epoch_fee_5pct", pool["epoch_fee"] == (100, 5), pool["epoch_fee"])
    check("deposit_fee_5bp", pool["stake_deposit_fee"] == (10000, 5), pool["stake_deposit_fee"])
    check("withdrawal_fee_5bp", pool["stake_withdrawal_fee"] == (10000, 5), pool["stake_withdrawal_fee"])
    check("no_lockup", pool["lockup"]["custodian"] == "11111111111111111111111111111111")
    check("pool_updated_this_epoch", pool["last_update_epoch"] == epoch, f"{pool['last_update_epoch']} vs {epoch}")

    # 2. PDAs
    prog = b58dec(PROGRAM); pool_b = b58dec(POOL)
    wd, wd_bump = find_pda([pool_b, b"withdraw"], prog)
    dep, dep_bump = find_pda([pool_b, b"deposit"], prog)
    check("withdraw_authority_pda", b58enc(wd) == EXPECT["withdraw_pda"], f"{b58enc(wd)} bump={wd_bump}")
    check("deposit_authority_pda", b58enc(dep) == EXPECT["deposit_pda"], f"{b58enc(dep)} bump={dep_bump}")
    check("stored_withdraw_bump_matches", pool["stake_withdraw_bump_seed"] == wd_bump, pool["stake_withdraw_bump_seed"])

    # 3. mint
    mv = get_account(MINT)
    mraw = base64.b64decode(mv["data"][0])
    mint_authority = b58enc(mraw[4:36]) if int.from_bytes(mraw[:4], "little") == 1 else None
    freeze = b58enc(mraw[50:82]) if int.from_bytes(mraw[46:50], "little") == 1 else None
    supply = int.from_bytes(mraw[36:44], "little")
    result["mint"] = {"authority": mint_authority, "freeze": freeze, "supply": supply, "decimals": mraw[44]}
    check("mint_authority_is_withdraw_pda", mint_authority == EXPECT["withdraw_pda"], mint_authority)
    check("mint_freeze_authority_none", freeze is None, freeze)
    check("mint_supply_matches_pool", supply == pool["pool_token_supply"])

    # 4. validator list
    vv = get_account(VLIST)
    vl = decode_vlist(base64.b64decode(vv["data"][0]))
    result["vlist"] = {"max": vl["max_validators"], "num": vl["num"]}
    check("num_validators", vl["num"] == EXPECT["num_validators"], vl["num"])
    check("all_validators_active", all(v["status"] == 0 for v in vl["validators"]))
    check("vlist_updated_this_epoch", all(v["last_update_epoch"] == epoch for v in vl["validators"]))
    sum_active = sum(v["active"] for v in vl["validators"])
    result["vlist"]["sum_active_lamports"] = sum_active

    # 5. stake account PDAs + authority verification
    derived = []
    for v in vl["validators"]:
        vote = b58dec(v["vote"])
        seeds = [vote, pool_b]
        if v["validator_seed_suffix"]: seeds.append(v["validator_seed_suffix"].to_bytes(4, "little"))
        sa, sb = find_pda(seeds, prog)
        derived.append({"vote": v["vote"], "stake_account": b58enc(sa), "bump": sb, "listed": v["active"]})
    addrs = [d["stake_account"] for d in derived] + [EXPECT["reserve"]]
    accs = {}
    for i in range(0, len(addrs), 100):
        batch = addrs[i:i+100]
        res = rpc("getMultipleAccounts", [batch, {"encoding": "base64"}])
        for a, val in zip(batch, res["value"]): accs[a] = val
    wd_str = EXPECT["withdraw_pda"]
    n_missing = n_bad = 0
    total = 0
    for d in derived:
        a = accs.get(d["stake_account"])
        if a is None: n_missing += 1; continue
        b = base64.b64decode(a["data"][0])
        staker = b58enc(b[12:44]); withdrawer = b58enc(b[44:76])
        if withdrawer != wd_str or staker != wd_str: n_bad += 1
        total += a["lamports"]
    resv = accs.get(EXPECT["reserve"])
    reserve_lamports = resv["lamports"] if resv else None
    total_all = total + (reserve_lamports or 0)
    result["stake_accounts"] = {"count": len(derived), "missing": n_missing, "bad_authority": n_bad,
                                "sum_stake_lamports": total, "reserve_lamports": reserve_lamports,
                                "sum_all_lamports": total_all}
    check("all_110_stake_accounts_exist", n_missing == 0, n_missing)
    check("all_stake_accounts_owned_by_pool_pda", n_bad == 0, n_bad)
    check("reserve_owned_by_pool_pda", resv is not None and b58enc(base64.b64decode(resv["data"][0])[44:76]) == wd_str)
    check("totals_reconcile", abs(total_all - pool["total_lamports"]) < 50 * 10**9,
          f"on-chain {total_all} vs pool state {pool['total_lamports']}")

    # 6. orphan sweep (getProgramAccounts memcmp withdrawer == PDA)
    try:
        res = rpc("getProgramAccounts", ["Stake11111111111111111111111111111111111111", {
            "encoding": "base64", "filters": [{"memcmp": {"offset": 44, "bytes": wd_str}}]}], tries=4, timeout=120)
        addrs_found = set(a["pubkey"] for a in res)
        expected_set = set(d["stake_account"] for d in derived) | {EXPECT["reserve"]}
        orphans = sorted(addrs_found - expected_set)
        result["orphan_sweep"] = {"found": len(addrs_found), "expected": len(expected_set), "orphans": orphans}
        check("no_orphan_stake_accounts", not orphans and addrs_found == expected_set,
              f"found={len(addrs_found)} expected={len(expected_set)}")
    except Exception as e:
        result["orphan_sweep"] = {"error": str(e)[:200]}
        check("no_orphan_stake_accounts", False, "scan failed")

    # 7. deployed program == official v2.1.0 release asset
    try:
        pd = get_account(PROGRAMDATA)
        elf = base64.b64decode(pd["data"][0])[45:]
        onchain_hash = hashlib.sha256(elf).hexdigest()
        rel_path = "ci-out/spl-stake-pool-v2.1.0.so"
        if not os.path.exists(rel_path):
            with urllib.request.urlopen(urllib.request.Request(RELEASE_URL, headers={"User-Agent": "zombie-ci/1.0"}), timeout=120) as r:
                open(rel_path, "wb").write(r.read())
        rel_hash = hashlib.sha256(open(rel_path, "rb").read()).hexdigest()
        result["program_hash"] = {"onchain_elf_sha256": onchain_hash, "release_sha256": rel_hash,
                                  "release": RELEASE_URL, "elf_bytes": len(elf)}
        check("program_matches_v2.1.0_release", onchain_hash == rel_hash == RELEASE_SHA256, onchain_hash)
    except Exception as e:
        result["program_hash"] = {"error": str(e)[:200]}
        check("program_matches_v2.1.0_release", False, "fetch failed")

    # 7b. pending v2.2.0 upgrade buffer (authority = Squads vault; content == official v2.2.0 asset)
    try:
        BUF = "EmR4UhwTPoEwKe9JNnVaHqSgmup3ebeBMyogY5fR9bgf"
        bv = get_account(BUF)
        braw = base64.b64decode(bv["data"][0])
        buf_elf = braw[37:]
        buf_hash = hashlib.sha256(buf_elf).hexdigest()
        buf_auth = b58enc(braw[5:37]) if braw[4] else None
        v220_url = "https://github.com/solana-program/stake-pool/releases/download/program%40v2.2.0/spl_stake_pool.so"
        v220_path = "ci-out/spl_stake_pool-v2.2.0.so"
        if not os.path.exists(v220_path):
            with urllib.request.urlopen(urllib.request.Request(v220_url, headers={"User-Agent": "zombie-ci/1.0"}), timeout=120) as r:
                open(v220_path, "wb").write(r.read())
        v220_hash = hashlib.sha256(open(v220_path, "rb").read()).hexdigest()
        result["pending_upgrade_buffer"] = {"buffer": BUF, "tag": int.from_bytes(braw[:4], "little"),
                                            "authority": buf_auth, "elf_sha256": buf_hash,
                                            "v2.2.0_asset_sha256": v220_hash, "bytes": len(buf_elf)}
        check("pending_upgrade_is_official_v2.2.0", buf_hash == v220_hash and buf_auth == "dPpFfahSWhm5M2RB3nVaHsXfnh9ooz5bWtR3WeUguDH", buf_hash[:16])
    except Exception as e:
        result["pending_upgrade_buffer"] = {"error": str(e)[:200]}
        check("pending_upgrade_is_official_v2.2.0", False, "fetch failed")

    # 8. price + valuation
    try:
        with urllib.request.urlopen("https://coins.llama.fi/prices/current/solana:So11111111111111111111111111111111111111112", timeout=30) as r:
            price = json.loads(r.read().decode())["coins"]["solana:So11111111111111111111111111111111111111112"]["price"]
        result["sol_price_usd"] = price
        result["total_lamports_usd"] = pool["total_lamports"] / 1e9 * price
        print(f"SOL price ${price:.2f}; pool {pool['total_lamports']/1e9:.2f} SOL = ${result['total_lamports_usd']:,.0f}")
    except Exception as e:
        result["sol_price_error"] = str(e)[:120]

    os.makedirs("ci-out", exist_ok=True)
    json.dump(result, open("ci-out/verification.json", "w"), indent=1)
    print(f"\n=== {len(result['failures'])} failures of {len(result['checks'])} checks ===")
    if result["failures"]: print("FAILED:", result["failures"]); sys.exit(1)

if __name__ == "__main__":
    main()
