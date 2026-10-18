#!/usr/bin/env python3
"""Read-only CI verifier for the exotic/legacy cluster.
Re-checks the decisive live fact for every target. No transactions are sent.
Writes ci-out/verify.json and exits non-zero if a decisive check fails.
"""
import json, subprocess, urllib.request, os, sys, time

OUT = "ci-out/verify.json"
os.makedirs("ci-out", exist_ok=True)
CHECKS = []

# CI's RPC_URL secret is method-restricted; use the fork RPC chosen by the
# workflow (public endpoint) and fall back to a public node locally.
ETH = os.environ.get("FORK_RPC_URL") or "https://ethereum-rpc.publicnode.com"
ETH2 = "https://eth.drpc.org"
BASE = os.environ.get("BASE_RPC_URL") or "https://base-rpc.publicnode.com"
MEZO = "https://mezo.drpc.org"
ARB = os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc"

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

def word(out, i):
    h = out[2:] if out.startswith("0x") else out
    return int(h[i*64:(i+1)*64], 16)

def add(name, ok, detail, decisive=True):
    CHECKS.append({"check": name, "ok": bool(ok), "detail": detail, "decisive": decisive})
    print(("PASS " if ok else "FAIL ") + name + " :: " + str(detail)[:160], flush=True)

# ---------- Ethereum ----------
ok, blk = run(["cast", "block-number", "--rpc-url", ETH])
add("eth.rpc", ok, blk)
blk = int(blk) if ok else 0

# Aragon: DAP token supply is 0 (100 ETH vault stuck)
ok, out = call("0xff3ad52375e4dbdf5b52d4ad08a890b286f95710", "totalSupply()")
add("aragon.dap.totalSupply==0", ok and int(out, 16) == 0, out)

# Aragon: SHARE agent holds the DAI/USDC stack
ok1, dai = call("0x6B175474E89094C44Da98b954EedeAC495271d0F", "balanceOf(address)", ["0xe0d11d5a1982f64ff1d36cd8c2bd315dea127d66"])
ok2, usdc = call("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "balanceOf(address)", ["0xe0d11d5a1982f64ff1d36cd8c2bd315dea127d66"])
add("aragon.share.agent.dai>=14000", ok1 and int(dai, 16) >= 14000 * 10**18, dai)
add("aragon.share.agent.usdc>=3700", ok2 and int(usdc, 16) >= 3700 * 10**6, usdc)

# Aragon: SHARE holder can forward (governance path live, holder-only)
ok, out = call("0x1ccb0c6b932bc453babe7210992cdd4b4bcd3014", "canForward(address,bytes)", ["0xc89000e12c600b12d6e61a535cd3fedd4ac1eec4", "0x"])
add("aragon.share.canForward(holder)==true", ok and int(out, 16) == 1, out)

# Aragon: ANT create-vote is gated
ok, out = call("0x277bfcf7c2e162cb1ac3e9ae228a3132a75f83d4", "newVote(bytes,string)", ["0x00000001", ""], frm="0x000000000000000000000000000000000000dEaD")
add("aragon.ant.newVote.gated", (not ok) and "APP_AUTH_FAILED" in out, out)

# Maker: victim has no Vat gem; standing hope; expired lot still readable and dealable
VAT = "0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B"
VICTIM = "0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273"
MOD = "0xf09a13072Ed939B79Bc25B66AA3a836ea6DCC170"
ILK = "0x4554482d41000000000000000000000000000000000000000000000000000000"
ok, out = call(VAT, "gem(bytes32,address)", [ILK, VICTIM])
add("maker.victim.vat.gem==0", ok and int(out, 16) == 0, out)
ok, out = call(VAT, "can(address,address)", [VICTIM, MOD])
add("maker.vat.can(victim,module)==1", ok and int(out, 16) == 1, out)
FLIP = "0xd8a04F5412223F513DC55F839574430f5EC15531"
ok, out = call(FLIP, "bids(uint256)", [3190])
add("maker.flip3190.lot==0.24e18", ok and word(out, 1) == 24 * 10**16, out)
ok, out = call(FLIP, "deal(uint256)", [3190], frm="0x3333333333333333333333333333333333333333")
add("maker.flip3190.deal.sim", ok, out[:120])

# 3F: wrapper balances add up to ~$39.7M
ok, jaaa = call("0x5a0f93d040de44e78f251b03c43be9cf317dcf64", "balanceOf(address)", ["0x86b495e4cb00ab18ad94bfd7920479cc79e8ebfe"])
add("3f.jaaa.balance>=2.3M", ok and int(jaaa, 16) >= 2_300_000 * 10**6, jaaa)
ok, aa = call("0xc26a6fa2c37b38e549a4a1807543801db684f99c", "balanceOf(address)", ["0x4614f7a56a3eb83b2ff9fa4b4b9575b28fb68644"])
add("3f.aa_falconx.balance>=26M", ok and int(aa, 16) >= 26_000_000 * 10**18, aa)

# Zama: registry has 26 pairs; USDC wrapper balance
ok, out = call("0xeb5015fF021DB115aCe010f23F55C2591059bBA0", "getTokenConfidentialTokenPairs()")
add("zama.pairs==26", ok and word(out, 1) == 26, out[:90] if out else out)
ok, out = call("0xa0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "balanceOf(address)", ["0xe978f22157048e5db8e5d07971376e86671672b2"])
add("zama.usdc.wrapper>=2.8M", ok and int(out, 16) >= 2_800_000 * 10**6, out)

# Kamui: three vaults total ~2.87M
tot = 0
for v in ["0xcDA323c2DF692d989B24BA51D0aCCa924cf9a344", "0xA5AE405242f42C47996a0C6857ff10a77F9bdeE6", "0x9E0DB8F43bb91e2148B0Db920E21370525CF3Aab"]:
    ok, out = call(v, "totalAssets()")
    if ok: tot += int(out, 16)
add("kamui.totalAssets>=2.8M", tot >= 2_800_000 * 10**6, tot / 1e6)

# ---------- Base / THEO ----------
ok, out = call("0x9AE3C0204F76cE8580Ef88CEF76EC6C7150ccb87", "trustedRelayer()", rpc=BASE)
add("theo.ism.relayer==0xeF30", ok and out.lower().endswith("ef305ec5df4054b15295a0389787bf671ab930ce"), out)
ok, out = call("0xeF305Ec5DF4054B15295A0389787bf671Ab930CE", "nonce()", rpc=BASE) if False else run(["cast", "nonce", "0xeF305Ec5DF4054B15295A0389787bf671Ab930CE", "--rpc-url", BASE])
add("theo.relayer.nonce>=378", ok and out.isdigit() and int(out) >= 378, out)
ok, out = call("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", "balanceOf(address)", ["0x182BE47742B81777055d69c50E5C9d2fE803e938"], rpc=BASE)
add("theo.pool.usdc~$1.8k", ok and 1_700_000_000 <= int(out, 16) <= 2_000_000_000, out)

# ---------- Mezo ----------
ok, out = run(["cast", "code", "0xa62060d57e04d6c799b58188dc654b85addd1465", "--rpc-url", MEZO])
if ok:
    ok2, h = run(["cast", "keccak", out])
    add("mezo.voter.impl.codehash", ok2 and h == "0xb6269ea69262be9a59e31a0fd1daddb1725fcc10288fa5658a46dcfc3cc065b1", h)
else:
    add("mezo.voter.impl.codehash", False, out)
ok, out = call("0x48233ccc97b87ba93bca212cbee48e3210211f03", "governor()", rpc=MEZO)
add("mezo.voter.governor==Safe", ok and out.lower().endswith("98d8899c3030741925be630c710a98b57f397c7a"), out)
ok, out = call("0x48233ccc97b87ba93bca212cbee48e3210211f03", "claimBribes(address[],address[][],uint256)", ["[0x6d446e27505c71ee39D632488cE849feF6AFfc57]", "[[]]", 0], rpc=MEZO, frm="0x000000000000000000000000000000000000dEaD")
add("mezo.voter.claimBribes.gated", (not ok) and "NotApprovedOrOwner" in out, out)

# ---------- Arbitrum / TxFlow ----------
ok, out = call("0xaf88d065e77c8cC2239327C5EDb3A432268e5831", "balanceOf(address)", ["0xcDE3F99bCB4c91e19124e41730489EAeFEc24565"], rpc=ARB)
add("txflow.bridge.usdc>=31M", ok and int(out, 16) >= 31_000_000 * 10**6, out)
ok, out = call("0xcDE3F99bCB4c91e19124e41730489EAeFEc24565", "paused()", rpc=ARB)
add("txflow.bridge.paused==false", ok and int(out, 16) == 0, out)

# ---------- TRON / USDD ----------
def tron_const(contract, selector, parameter=""):
    body = {"owner_address": "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb",
            "contract_address": contract, "function_selector": selector,
            "parameter": parameter, "visible": True}
    req = urllib.request.Request("https://api.trongrid.io/wallet/triggerconstantcontract",
                                 data=json.dumps(body).encode(),
                                 headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))

try:
    r = tron_const("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz", "tin()")
    tin = int(r.get("constant_result", ["0"])[0] or "0", 16)
    r2 = tron_const("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz", "tout()")
    tout = int(r2.get("constant_result", ["0"])[0] or "0", 16)
    r3 = tron_const("TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz", "sellEnabled()")
    sell = int(r3.get("constant_result", ["0"])[0] or "0", 16)
    add("usdd.psm.tin==0,tout==0,sell==1", tin == 0 and tout == 0 and sell == 1, {"tin": tin, "tout": tout, "sell": sell})
    r4 = tron_const("TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz", "totalSupply()")
    sup = int(r4.get("constant_result", ["0"])[0] or "0", 16)
    add("usdd.supply>1.3B", sup > 1_300_000_000 * 10**18, sup / 1e18)
except Exception as e:
    add("usdd.psm.state", False, repr(e))

summary = {"eth_block": blk, "checks_total": len(CHECKS),
           "checks_passed": sum(1 for c in CHECKS if c["ok"]),
           "checks_failed": [c["check"] for c in CHECKS if not c["ok"] and c["decisive"]],
           "checks": CHECKS, "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
json.dump(summary, open(OUT, "w"), indent=1)
print(json.dumps({k: summary[k] for k in ("eth_block", "checks_total", "checks_passed", "checks_failed")}, indent=1))
sys.exit(0 if not summary["checks_failed"] else 1)
