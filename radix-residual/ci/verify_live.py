#!/usr/bin/env python3
"""radix-residual — independent live re-verification on a fresh runner.

Read-only: public Radix Gateway (https://mainnet.radixdlt.com) queries + transaction
PREVIEW simulations only. Nothing is ever signed or submitted. No secrets needed.

Checks (one per headline claim):
  W1  Weft: hUSDC total supply (~1,092.79)
  W2  Weft: top underwater CDPs still liquidatable (liq_ltv > 1)
  W3  Weft: zero-capital flash-loan liquidation SUCCEEDS (net XRD > 0)
  W4  Weft: 45-hUSDC liquidation of #1015 SUCCEEDS (net XRD > 0)
  L1  JustLock: locker live; no `withdraw` entry point (E-U $0 gate)
  L2  RadLock: fee vault = 10,500 XRD; admin withdrawal rejected for fresh caller
  L3  RlyFun: pump fee vault balance; fresh-dev `claim_fee` rejected (P gate)
  D1  Ociswap: 10-XRD round trip loses ~2x fee (no extraction)
  D2  DefiPlaza: 10-XRD round trip loses ~2x fee (no extraction)
  D3  Ociswap: flash-loan take-without-repay rejected by the engine
"""
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "analysis"))
from rdx import post, entity_details, preview, ledger_state  # noqa: E402

XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
HUSDC = "resource_rdx1thxj9m87sn5cc9ehgp9qxp6vzeqxtce90xm5cp33373tclyp4et4gv"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"
HUSDC_HOLDER = "account_rdx129v8sg52dex7ct6gf7ne0rqvyxck4rn5mp0uyp30f898qfy3hxqrmj"

WEFT_POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
WEFT_MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
WEFT_TRANSIENT = "resource_rdx1nfeyk5cmjep98zae9vhg067elm2necwsvdnngp3je62ahqstsa8x2x"

JL_LOCKER = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"
RL_SVC = "component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs"
RL_ADMIN_BADGE = "resource_rdx1th5shllnhx33m5jkcqxsrgztp72yuxpg54cyxj2vcj3lpdup7f33ff"
RLY_PUMP = "component_rdx1cz78ld4409v7l8nawmeqr6wj4f5nvmpzdaulwpdqg3hps56mmgzzmy"
RLY_DEV_BADGE = "resource_rdx1ng362xkr6ptkrpgww99qzhqzvwytg92ad8vxvvjzeqxa8hrt0g4ryw"
RLY_EARLY = "resource_rdx1t5xv44c0u99z096q00mv74emwmxwjw26m98lwlzq6ddlpe9f5cuc7s"

OCI_BASIC = "component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt"
OCI_PRECISION_OCI = "component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp"
DFP2 = "resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq"
DP_DEX = "component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68"

RESULTS = []
STATE = {}


def record(check, ok, detail, **extra):
    RESULTS.append({"check": check, "ok": bool(ok), "detail": detail, **extra})
    print(f"[{'PASS' if ok else 'FAIL'}] {check}: {detail}")


def xrd_delta_acct(resp, acct=ACCT):
    """Sum the XRD delta of `acct` from a preview response."""
    total = 0.0
    for batch in resp.get("resource_changes", []) or []:
        for e in batch.get("resource_changes", []) or []:
            if e.get("resource_address") != XRD:
                continue
            ce = e.get("component_entity") or {}
            if ce.get("entity_address") == acct:
                total += float(e.get("amount") or 0)
    return total


def preview_status(manifest, nonce):
    resp = preview(manifest, nonce=nonce)
    rc = resp.get("receipt", {})
    return rc.get("status"), str(rc.get("error_message") or ""), resp


def main():
    ls = ledger_state()
    STATE.update(ls)
    print("ledger:", json.dumps(ls))

    try:
        with urllib.request.urlopen(
            "https://coins.llama.fi/prices/current/coingecko:radix", timeout=30
        ) as r:
            px = json.loads(r.read().decode())["coins"]["coingecko:radix"]["price"]
        STATE["xrd_usd"] = px
        print("XRD price:", px)
    except Exception as e:  # noqa: BLE001
        STATE["xrd_usd"] = None
        print("XRD price fetch failed:", e)

    # ---------- Weft ----------
    r = entity_details([HUSDC])
    sup = float(r["items"][0]["details"]["total_supply"])
    record("W1_hUSDC_supply", 900 < sup < 1400, f"hUSDC total supply = {sup}")

    ids = ["#1015#", "#517#", "#100#", "#1029#"]
    idlist = ", ".join(f'NonFungibleLocalId("{i}")' for i in ids)
    st, err, resp = preview_status(
        f'CALL_METHOD Address("{WEFT_MARKET}") "get_cdp" Array<NonFungibleLocalId>({idlist});', 4001
    )
    lltvs = {}
    if st == "Succeeded" and resp.get("receipt", {}).get("output"):
        pj = resp["receipt"]["output"][0].get("programmatic_json") or {}
        for e in pj.get("entries", []):
            fs = e["value"]["fields"]
            lltvs[e["key"]["value"]] = float((fs[8] or {}).get("value") or 0)
    ok = len(lltvs) == 4 and all(v > 1.0 for v in lltvs.values())
    record("W2_underwater_cdps", ok, f"liq_ltv = {json.dumps(lltvs)}", liq_ltv=lltvs)

    m_flash = f"""
CALL_METHOD Address("{WEFT_POOL}") "take_flash_loan" Map<Address, Decimal>(Address("{XRD}") => Decimal("10"));
TAKE_ALL_FROM_WORKTOP Address("{WEFT_TRANSIENT}") Bucket("terms");
TAKE_FROM_WORKTOP Address("{XRD}") Decimal("5") Bucket("pay");
CALL_METHOD Address("{WEFT_MARKET}") "liquidate" NonFungibleLocalId("#447#") Array<Bucket>(Bucket("pay")) Enum<1u8>(Array<Address>(Address("{XRD}")));
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("all_xrd");
CALL_METHOD Address("{WEFT_POOL}") "repay_flash_loan" Array<Bucket>(Bucket("all_xrd")) Bucket("terms");
CALL_METHOD Address("{ACCT}") "deposit_batch" Expression("ENTIRE_WORKTOP");
"""
    st, err, resp = preview_status(m_flash, 4002)
    net = xrd_delta_acct(resp) if st == "Succeeded" else None
    record(
        "W3_zero_capital_flash_liq",
        st == "Succeeded" and net is not None and net > 0,
        f"status={st} net_xrd={net} err={err[:140]}",
        net_xrd=net,
    )

    # W4: liquidate #1015 with hUSDC from its largest holder (simulated funding source)
    r = entity_details([HUSDC_HOLDER], aggregation_level="Global")
    bal = 0.0
    for x in r["items"][0].get("fungible_resources", {}).get("items", []):
        if x["resource_address"] == HUSDC:
            bal = float(x["amount"])
    pay_husdc = round(min(45.0, max(0.0, bal - 0.01)), 6)
    m_liq = f"""
CALL_METHOD Address("{HUSDC_HOLDER}") "withdraw" Address("{HUSDC}") Decimal("{pay_husdc}");
TAKE_ALL_FROM_WORKTOP Address("{HUSDC}") Bucket("pay");
CALL_METHOD Address("{WEFT_MARKET}") "liquidate" NonFungibleLocalId("#1015#") Array<Bucket>(Bucket("pay")) Enum<1u8>(Array<Address>(Address("{XRD}")));
CALL_METHOD Address("{HUSDC_HOLDER}") "deposit_batch" Expression("ENTIRE_WORKTOP");
"""
    st, err, resp = preview_status(m_liq, 4003)
    net = xrd_delta_acct(resp, HUSDC_HOLDER) if st == "Succeeded" else None
    record(
        "W4_liq_1015_husdc",
        st == "Succeeded" and net is not None and net > 30000,
        f"status={st} repaid={pay_husdc} net_xrd={net} err={err[:140]}",
        net_xrd=net,
        repaid_husdc=pay_husdc,
    )

    # ---------- Lockers ----------
    r = entity_details([JL_LOCKER], aggregation_level="Global")
    nf = len(r["items"][0].get("fungible_resources", {}).get("items", []))
    record("L1a_justlock_live", nf > 50, f"locker fungible resources = {nf}")
    st, err, _ = preview_status(f'CALL_METHOD Address("{JL_LOCKER}") "withdraw";', 4004)
    record(
        "L1b_justlock_no_withdraw",
        st == "Failed" and "BlueprintPayloadDoesNotExist" in err,
        f"status={st} err={err[:160]}",
    )

    st, err, resp = preview_status(f'CALL_METHOD Address("{RL_SVC}") "get_xrd_fee_vault";', 4005)
    fee = None
    if st == "Succeeded" and resp.get("receipt", {}).get("output"):
        fee = resp["receipt"]["output"][0]["programmatic_json"].get("value")
    record("L2a_radlock_fee_vault", st == "Succeeded" and fee is not None, f"get_xrd_fee_vault = {fee} XRD", xrd_fee_vault=fee)
    st, err, _ = preview_status(f'CALL_METHOD Address("{RL_SVC}") "withdraw_flat_xrd_fees";', 4006)
    record(
        "L2b_radlock_admin_gate",
        st == "Failed" and "Unauthorized" in err and RL_ADMIN_BADGE in err,
        f"status={st} err={err[:180]}",
    )

    st, err, resp = preview_status(f'CALL_METHOD Address("{RLY_PUMP}") "check_fee_vault";', 4007)
    rly_fee = None
    if st == "Succeeded" and resp.get("receipt", {}).get("output"):
        rly_fee = resp["receipt"]["output"][0]["programmatic_json"].get("value")
    record("L3a_rlyfun_fee_vault", st == "Succeeded", f"check_fee_vault = {rly_fee} XRD", pump_fee_vault=rly_fee)

    m_launch = f"""
CALL_METHOD Address("{ACCT}") "withdraw" Address("{XRD}") Decimal("69");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("fee");
CALL_METHOD Address("{RLY_PUMP}") "launch" "PROBE" "simulation probe" "PRB" "https://example.com/icon.png" "https://example.com" None Bucket("fee") Decimal("0.00069") false;
TAKE_ALL_FROM_WORKTOP Address("{RLY_DEV_BADGE}") Bucket("dev");
CREATE_PROOF_FROM_BUCKET_OF_ALL Bucket("dev") Proof("devproof");
CALL_METHOD Address("{RLY_PUMP}") "claim_fee" Proof("devproof");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("claimed");
TAKE_ALL_FROM_WORKTOP Address("{RLY_EARLY}") Bucket("early");
CALL_METHOD Address("{ACCT}") "deposit_batch" Array<Bucket>(Bucket("dev"), Bucket("claimed"), Bucket("early"));
"""
    st, err, _ = preview_status(m_launch, 4008)
    record(
        "L3b_rlyfun_fresh_dev_claim_rejected",
        st == "Failed" and "Invalid proof" in err,
        f"status={st} err={err[:200]}",
    )

    # ---------- DEX ----------
    m_oci = f"""
CALL_METHOD Address("{ACCT}") "withdraw" Address("{XRD}") Decimal("10");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("in1");
CALL_METHOD Address("{OCI_BASIC}") "swap" Bucket("in1");
TAKE_ALL_FROM_WORKTOP Address("{DFP2}") Bucket("mid");
CALL_METHOD Address("{OCI_BASIC}") "swap" Bucket("mid");
TAKE_ALL_FROM_WORKTOP Address("{DFP2}") Bucket("leftover");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("back");
CALL_METHOD Address("{ACCT}") "deposit_batch" Array<Bucket>(Bucket("back"), Bucket("leftover"));
"""
    st, err, resp = preview_status(m_oci, 4009)
    net = xrd_delta_acct(resp) if st == "Succeeded" else None
    record(
        "D1_ociswap_roundtrip_negative",
        st == "Succeeded" and net is not None and -1.0 < net < 0,
        f"status={st} net_xrd={net}",
        net_xrd=net,
    )

    m_dp = f"""
CALL_METHOD Address("{ACCT}") "withdraw" Address("{XRD}") Decimal("10");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("in1");
CALL_METHOD Address("{DP_DEX}") "swap" Bucket("in1") Address("{DFP2}");
TAKE_ALL_FROM_WORKTOP Address("{DFP2}") Bucket("mid");
CALL_METHOD Address("{DP_DEX}") "swap" Bucket("mid") Address("{XRD}");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("back");
TAKE_ALL_FROM_WORKTOP Address("{DFP2}") Bucket("leftover");
CALL_METHOD Address("{ACCT}") "deposit_batch" Array<Bucket>(Bucket("back"), Bucket("leftover"));
"""
    st, err, resp = preview_status(m_dp, 4010)
    net = xrd_delta_acct(resp) if st == "Succeeded" else None
    record(
        "D2_defiplaza_roundtrip_negative",
        st == "Succeeded" and net is not None and -1.0 < net < 0,
        f"status={st} net_xrd={net}",
        net_xrd=net,
    )

    # flash-loan take-only must fail (engine forces repayment)
    m_fl = f"""
CALL_METHOD Address("{OCI_PRECISION_OCI}") "flash_loan" Address("{XRD}") Decimal("5");
TAKE_ALL_FROM_WORKTOP Address("{XRD}") Bucket("loan");
CALL_METHOD Address("{ACCT}") "deposit" Bucket("loan");
"""
    st, err, _ = preview_status(m_fl, 4011)
    record(
        "D3_ociswap_flash_takeonly_fails",
        st == "Failed" and ("DropNonEmptyBucket" in err or "drop" in err.lower()),
        f"status={st} err={err[:180]}",
    )

    out = {
        "finding": "radix-residual (L2-16 + L2-17)",
        "run_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "ledger_state": STATE,
        "checks": RESULTS,
        "passed": sum(1 for r in RESULTS if r["ok"]),
        "total": len(RESULTS),
    }
    Path("ci-out").mkdir(exist_ok=True)
    with open("ci-out/results.json", "w") as f:
        json.dump(out, f, indent=2)
    print(f"\n{out['passed']}/{out['total']} checks passed -> ci-out/results.json")
    if out["passed"] != out["total"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
