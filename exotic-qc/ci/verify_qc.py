#!/usr/bin/env python3
"""ZH4 exotic/legacy cluster — independent QC gate (read-only).
Re-checks the decisive facts the cluster's $0 verdicts depend on.
Writes ci-out/qc.json. No transactions, no secrets.
"""
import json, os, subprocess, urllib.request, time, sys

OUT = "ci-out/qc.json"
os.makedirs("ci-out", exist_ok=True)
CHECKS = []
ETH = os.environ.get("FORK_RPC_URL") or "https://ethereum-rpc.publicnode.com"
BASE = os.environ.get("BASE_RPC_URL") or "https://base-rpc.publicnode.com"
POLY = os.environ.get("POLYGON_RPC_URL") or "https://polygon-bor-rpc.publicnode.com"
TAC = "https://rpc.tac.build"
MEZO = "https://mezo.drpc.org"
ARB = os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc"
ANKR = os.environ.get("ANKR_API_KEY", "")

def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode == 0, (p.stdout + p.stderr).strip()

def call(to, sig, args=(), rpc=ETH, frm=None, retries=2):
    cmd = ["cast", "call", to, sig, *[str(a) for a in args], "--rpc-url", rpc]
    if frm: cmd += ["--from", frm]
    for _ in range(retries + 1):
        ok, out = run(cmd)
        if ok: return True, out
        if "429" in out or "rate" in out.lower() or "timed out" in out.lower():
            time.sleep(2); continue
        break
    return False, out

def word(out, i=0):
    s = out.strip()
    toks0 = s.split()
    if toks0 and toks0[0].startswith("0x") and len(toks0[0]) >= 66:
        h = toks0[0][2:]
        return int(h[i*64:(i+1)*64], 16)
    toks = [t.strip("(),") for t in s.replace("\n", " ").split()]
    toks = [t for t in toks if t and not t.startswith("[")]
    t = toks[i]
    return int(t, 16) if t.startswith("0x") else int(t)

def boolean(out):
    return out.strip().lower() == "true"

def add(name, ok, detail, decisive=True):
    CHECKS.append({"check": name, "ok": bool(ok), "detail": str(detail)[:220], "decisive": decisive})
    print(("PASS " if ok else "FAIL ") + name + " :: " + str(detail)[:160], flush=True)

# ---------- Euler: omitted-chain enumeration ----------
for chain, rpc, factory, expected in [
        ("polygon", POLY, "0xB1771a13e2a13fCafA89B00335915E732B9466b7", 543),
        ("tac", TAC, "0x2b21621b8Ef1406699a99071ce04ec14cCd50677", 36)]:
    ok, out = call(factory, "getProxyListLength()(uint256)", rpc=rpc)
    add(f"euler.{chain}.factory_count>={expected}", ok and word(out) >= expected, out)
    # sample five vaults, check oracle/borrows/code
    bad = []
    for i in [0, expected//4, expected//2, (3*expected)//4, expected-1]:
        ok1, p = call(factory, "proxyList(uint256)(address)", [i], rpc=rpc)
        if not ok1: bad.append(f"proxyList({i}) failed"); continue
        v = p.strip().splitlines()[-1]
        ok2, o = call(v, "oracle()(address)", rpc=rpc)
        ok3, b = call(v, "totalBorrows()(uint256)", rpc=rpc)
        if not (ok2 and ok3): bad.append(f"{v} read fail"); continue
        oz = o.strip().lower().endswith("0"*40)
        borrows = word(b)
        code = "0x"
        if not oz:
            okc, cs = run(["cast", "codesize", o.strip(), "--rpc-url", rpc])
            code = cs
        if (oz or code in ("0", "0x", "")) and borrows > 0:
            bad.append(f"HIT {v} borrows={borrows} oracle={o.strip()} code={code}")
    add(f"euler.{chain}.sample.no_broken_oracle_borrow", not bad, bad or "0 hits in 5-vault sample")

# ---------- Aragon ----------
ok, out = call("0xff3ad52375e4dbdf5b52d4ad08a890b286f95710", "totalSupply()(uint256)")
add("aragon.dap.supply==0", ok and word(out) == 0, out)
ok, out = run(["cast", "balance", "0xf527f6ffb0fed308178292a830a64ebb15c02c47", "--rpc-url", ETH])
add("aragon.dap.vault==100ETH", ok and int(out) == 100 * 10**18, out)
ok, out = call("0x2e59a20f205bb85a89c53f1936454680651e618e", "newVote(bytes,string)", ["0x00000001", ""], frm="0x000000000000000000000000000000000000dEaD")
add("aragon.lido.newVote.gated", (not ok) and "APP_AUTH_FAILED" in out, out)
ok, out = call("0x1c8058e72e4902b3431ef057e8d9a58a73f26372", "newVote(bytes,string)", ["0x00000001", ""], frm="0x000000000000000000000000000000000000dEaD")
add("aragon.api3.newVote.gated", (not ok) and "API3_HIT_PROPOSAL_THRESHOLD" in out, out)

# ---------- THEO ----------
ISM = "0x9AE3C0204F76cE8580Ef88CEF76EC6C7150ccb87"
MB = "0x14b8591b00671835A2d5bb7A3B6822319e853EA7"
ok, out = call("0xebe516a20238f79dc20b07ead6768e08891ed309", "interchainSecurityModule()(address)", rpc=BASE)
add("theo.token.ism==default", ok and out.strip().lower().endswith("9ae3c0204f76ce8580ef88cef76ec6c7150ccb87"), out)
ok, out = call(MB, "defaultIsm()(address)", rpc=BASE)
add("theo.mailbox.defaultIsm==ism", ok and out.strip().lower().endswith("9ae3c0204f76ce8580ef88cef76ec6c7150ccb87"), out)
ok, out = call(ISM, "trustedRelayer()(address)", rpc=BASE)
add("theo.ism.relayer==0xeF30", ok and out.strip().lower().endswith("ef305ec5df4054b15295a0389787bf671ab930ce"), out)
ok, out = call("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", "balanceOf(address)", ["0x182BE47742B81777055d69c50E5C9d2fE803e938"], rpc=BASE)
add("theo.pool.usdc<2k", ok and 1_700_000_000 <= word(out) <= 2_000_000_000, out)
# mailbox process census via Ankr archive
try:
    body = {"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{
        "address": MB, "fromBlock":"0x2ec0000", "toBlock":"latest",
        "topics":["0x0d381c2a574ae8f04e213db7cfb4df8df712cdbd427d9868ffef380660ca6574"]}]}
    req = urllib.request.Request(f"https://rpc.ankr.com/base/{ANKR}", data=json.dumps(body).encode(),
                                 headers={"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    logs = json.load(urllib.request.urlopen(req, timeout=90))["result"]
    recips = sorted(set("0x"+l["topics"][3][-40:] for l in logs))
    add("theo.mailbox.process_census", len(logs) >= 370 and len(recips) == 2,
        {"process": len(logs), "recipients": recips}, decisive=False)
except Exception as e:
    add("theo.mailbox.process_census", False, repr(e), decisive=False)

# ---------- Zama ----------
for w in ["0xe978f22157048e5db8e5d07971376e86671672b2",
          "0xda9396b82634ea99243ce51258b6a5ae512d4893",
          "0x85de671c3bec1aded752c3cea943521181c826bc"]:
    ok, out = run(["cast", "storage", w, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "--rpc-url", ETH])
    add(f"zama.{w[:8]}.impl_shared", ok and out.strip().lower().endswith("2abad2203eba104b52cf040cccfa100df15687f8"), out)
ok, out = call("0xe978f22157048e5db8e5d07971376e86671672b2", "finalizeUnwrap(bytes32,uint64,bytes)", ["0x"+"11"*32, 1, "0x"], frm="0x000000000000000000000000000000000000dEaD")
add("zama.finalizeUnwrap.fake_request_reverts", (not ok) and "InvalidUnwrapRequest" in out, out)
ok, out = call("0xe978f22157048e5db8e5d07971376e86671672b2", "inferredTotalSupply()(uint256)")
add("zama.usdc.backing>2.8M", ok and word(out) > 2_800_000*10**6, out)

# ---------- USDD (TRON) ----------
def tron(contract, sig, param=""):
    body = {"owner_address":"T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb","contract_address":contract,
            "function_selector":sig,"parameter":param,"visible":True}
    for attempt in range(4):
        try:
            req = urllib.request.Request("https://api.trongrid.io/wallet/triggerconstantcontract",
                                         data=json.dumps(body).encode(),
                                         headers={"content-type":"application/json","User-Agent":"Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=30))
            c = r.get("constant_result",[""])[0]
            return int(c,16) if c else None
        except Exception:
            if attempt == 3: raise
            time.sleep(2*(attempt+1))
try:
    tin = tron("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz","tin()")
    tout = tron("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz","tout()")
    sell = tron("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz","sellEnabled()")
    add("usdd.psm.tin/tout/sell", tin == 0 and tout == 0 and sell == 1, {"tin":tin,"tout":tout,"sell":sell})
    # TSUY... USDT balanceOf param (base58-decoded, padded)
    p = "000000000000000000000000b50eb419ebeba06c80df5e9aaec494cef4297879"
    bal = tron("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t","balanceOf(address)",p)
    add("usdd.psm.usdt>35M", bal and bal > 35_000_000*10**6, bal/1e6 if bal else bal, decisive=False)
except Exception as e:
    add("usdd.psm.state", False, repr(e))

# ---------- Mezo ----------
ok, out = run(["cast", "code", "0xa62060d57e04d6c799b58188dc654b85addd1465", "--rpc-url", MEZO])
if ok:
    ok2, h = run(["cast", "keccak", out])
    add("mezo.voter.codehash", ok2 and h.strip() == "0xb6269ea69262be9a59e31a0fd1daddb1725fcc10288fa5658a46dcfc3cc065b1", h)
else:
    add("mezo.voter.codehash", False, out)
ok, out = call("0x48233ccc97b87ba93bca212cbee48e3210211f03","claimBribes(address[],address[][],uint256)",["[0x6d446e27505c71ee39D632488cE849feF6AFfc57]","[[]]",0],rpc=MEZO,frm="0x000000000000000000000000000000000000dEaD")
add("mezo.voter.claimBribes.gated", (not ok) and "NotApprovedOrOwner" in out, out)

# ---------- TxFlow ----------
ok, out = call("0xcDE3F99bCB4c91e19124e41730489EAeFEc24565","disputePeriodSeconds()(uint64)",rpc=ARB)
add("txflow.dispute==200", ok and word(out) == 200, out)
ok, out = call("0xcDE3F99bCB4c91e19124e41730489EAeFEc24565","totalValidatorPower()(uint64)",rpc=ARB)
add("txflow.power==4000", ok and word(out) == 4000, out)
ok, out = call("0xcDE3F99bCB4c91e19124e41730489EAeFEc24565","paused()(bool)",rpc=ARB)
add("txflow.unpaused", ok and not boolean(out), out)
ok, out = call("0xaf88d065e77c8cC2239327C5EDb3A432268e5831","balanceOf(address)",["0xcDE3F99bCB4c91e19124e41730489EAeFEc24565"],rpc=ARB)
add("txflow.usdc>31M", ok and word(out) > 31_000_000*10**6, out)

# ---------- 3F ----------
W = "0x86b495e4cb00ab18ad94bfd7920479cc79e8ebfe"; U = "0x5a0f93d040de44e78f251b03c43be9cf317dcf64"
ok1, ts = call(W,"totalSupply()(uint256)")
ok2, bal = call(U,"balanceOf(address)",[W])
add("3f.jaaa.1to1", ok1 and ok2 and word(ts) == word(bal), {"supply":word(ts),"balance":word(bal)})
ok, out = call("0xa0f6cbc8dba8b106473e5f70fe04a3ea6c3bfd26","getThreshold()(uint256)")
add("3f.safe.threshold==2", ok and word(out) == 2, out)

# ---------- Kamui ----------
tot = 0
for v in ["0xcDA323c2DF692d989B24BA51D0aCCa924cf9a344","0xA5AE405242f42C47996a0C6857ff10a77F9bdeE6","0x9E0DB8F43bb91e2148B0Db920E21370525CF3Aab"]:
    ok, out = call(v,"totalAssets()(uint256)")
    if ok: tot += word(out)
add("kamui.totalAssets>2.8M", tot > 2_800_000*10**6, tot/1e6)

# ---------- Maker ----------
FLIP = "0xd8a04F5412223F513DC55F839574430f5EC15531"
for i in [3190,3563,3753,4459,4885,4886]:
    ok, out = call(FLIP,"bids(uint256)",[i])
    lot = word(out,1) if ok else 0
    add(f"maker.lot.{i}.nonzero", ok and lot > 0, lot)
ok, out = call(FLIP,"deal(uint256)",[3190],frm="0x3333333333333333333333333333333333333333")
add("maker.deal3190.sim", ok, out)

summary = {"checks_total": len(CHECKS), "checks_passed": sum(1 for c in CHECKS if c["ok"]),
           "checks_failed": [c["check"] for c in CHECKS if not c["ok"] and c["decisive"]],
           "checks": CHECKS, "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
json.dump(summary, open(OUT,"w"), indent=1)
print(json.dumps({k:summary[k] for k in ("checks_total","checks_passed","checks_failed")}, indent=1))
sys.exit(0 if not summary["checks_failed"] else 1)
