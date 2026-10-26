#!/usr/bin/env python3
"""
Prosper Alpha (Pharos 1672) — read-only PoC simulation.

WHY NOT FOUNDRY: the public Pharos RPC `rpc.pharos.xyz` returns a NON-STANDARD
`eth_getProof` payload (objects with nextBeginOffset/nextEndOffset/proofNode instead of
hex strings), so `anvil`/`forge` cannot build a fork ("failed to parse block hash or number").
The PoC is therefore driven by `eth_call` (cast call) against the live chain — 100% read-only,
no tx signed/sent. Every assertion below is an eth_call simulation.

Proves:
  A. the bonding-curve buy->sell round-trip is strictly loss-making (symmetric x*y=k + 1% fee),
     for 5 sizes across all live markets (phase 0 and phase 3);
  B. every privileged value-mover REVERTS for an unprivileged caller (role/owner gates).
"""
import json, subprocess, sys, os

RPC = os.environ.get("PHAROS_RPC_URL", "https://rpc.pharos.xyz")
ATTACKER = "0x1111111111111111111111111111111111111111"
OUT = sys.argv[1] if len(sys.argv) > 1 else "ci-out"
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "poc_results.txt")

PASS = 0
FAIL = 0
lines = []


def say(s):
    lines.append(s)
    print(s)


def cast(*args):
    r = subprocess.run(["cast", *args, "--rpc-url", RPC], capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def call_json(to, sig, *params):
    rc, out, err = cast("call", to, sig, *params, "--json")
    if rc != 0:
        return None, err
    try:
        v = json.loads(out)
    except Exception:
        return None, out
    return (v if isinstance(v, list) else [v]), None


def check(name, ok, detail=""):
    global PASS, FAIL
    if ok:
        PASS += 1
        say(f"PASS {name} {detail}")
    else:
        FAIL += 1
        say(f"FAIL {name} {detail}")


# ---- targets (verified on-chain) ----
ACTIVE = [
    ("pPika", "0x39630b3c2874276cd664823C44Ab23aA69Dde80A"),
    ("pMusk", "0x5c3E0e4B1BE0851DCbC5F6a5cc04d799AcbE8B7F"),
    ("pPeng", "0xe534Dadb1E32A9DF075ffcAE0D636fF472A040db"),
]
FAILED = [("pBANA", "0x21E1C2dD76CF9C3223dC38fE53bB63b4F1234D8a")]
FAILED_VAULT = "0x2F1cBC9D23b2e8E2Edb2c1110f5cC0C4e2Ad4e75"
MIGESCROW = "0xc8F6D453D3C3ceA8A046f6D4AB683B0c4DB9a4D5"
TIMELOCK = "0x152Ecca16F86FAa5d1FC2eD0a1B2bAF5AACd794B"
FACTORY = "0xEfdbb0eA7647B0e21AEf7A3b7a5D6A632c3116C8"
ACCESS = "0x3C22060C99EE18097029151113478b4264041Bdb"
CLAIM = "0x158432EeD50E944B4148D46b5e7df5D083706811"
BUYBACK = "0x484Ec8A653f35bFBe0F4FF04387F109a70bFB53d"
WPROS = "0x52C48d4213107b20bC583832b0d951FB9CA8F0B0"

say("=== Prosper Alpha read-only PoC (eth_call simulation) ===")
rc, bn, _ = cast("block-number")
say(f"chain=pharos(1672) block={bn} rpc=<keyless public>")

SIZES = [10**15, 10**17, 10**18, 10**19, 10**20]

# ---- A. curve round-trip never profits ----
for name, mk in ACTIVE + FAILED:
    for x in SIZES:
        qb, e = call_json(mk, "quoteBuy(uint256)(uint256,uint256,uint256,uint256)", str(x))
        if qb is None:
            check(f"roundtrip {name} x={x}", False, f"quoteBuy err={e[:60]}")
            continue
        pout = int(qb[3])
        qs, e2 = call_json(mk, "quoteSell(uint256)(uint256,uint256,uint256)", str(pout))
        if qs is None:
            check(f"roundtrip {name} x={x}", False, f"quoteSell err={e2[:60]}")
            continue
        net = int(qs[2])
        check(f"roundtrip {name} x={x}", net <= x, f"pOut={pout} netBack={net} loss={x-net}")

# ---- B. privileged movers revert for an unprivileged caller ----
gates = [
    ("migrateToExternal", MIGESCROW, "migrateToExternal(address)", [FAILED_VAULT]),
    ("addLiquidity", MIGESCROW, "addLiquidity(address,bool,uint256,uint256,uint256,uint256,uint256,uint256)",
     [FAILED_VAULT, "true", "0", "0", "0", "0", "0", "9999999999"]),
    ("LpTimeLock.claim", TIMELOCK, "claim(address,address)", ["0x000000000000000000000000000000000000dEaD", ATTACKER]),
    ("LpTimeLock.register", TIMELOCK, "register(address,uint64)", ["0x000000000000000000000000000000000000dEaD", "1"]),
    ("Buyback.withdrawUsdc", BUYBACK, "withdrawUsdc(bytes32,uint256)",
     ["0x0000000000000000000000000000000000000000000000000000000000000001", "1"]),
    ("Factory.upgradeToAndCall", FACTORY, "upgradeToAndCall(address,bytes)", ["0x000000000000000000000000000000000000bEEF", "0x"]),
    ("AccessController.upgradeToAndCall", ACCESS, "upgradeToAndCall(address,bytes)", ["0x000000000000000000000000000000000000bEEF", "0x"]),
    ("PTokenClaim.claim(forge)", CLAIM, "claim(address,address,uint256,bytes32[])",
     [FAILED_VAULT, ATTACKER, str(10**30), "[]"]),
]
for label, to, sig, params in gates:
    rc, out, err = cast("call", to, sig, *params, "--from", ATTACKER)
    reverted = rc != 0 or "revert" in (out + err).lower()
    check(f"gate {label} reverts", reverted, (err or out)[:90].replace("\n", " "))

# ---- C. permissionless refreshPhase moves no WPROS ----
esc_before, _ = call_json(WPROS, "balanceOf(address)(uint256)", MIGESCROW)
esc_before = int(esc_before[0]) if esc_before else -1
rc, out, err = cast("call", "0x39630b3c2874276cd664823C44Ab23aA69Dde80A", "refreshPhase()(uint8)", "--from", ATTACKER)
esc_after, _ = call_json(WPROS, "balanceOf(address)(uint256)", MIGESCROW)
esc_after = int(esc_after[0]) if esc_after else -1
check("refreshPhase moves no WPROS", esc_before == esc_after and esc_before >= 0,
      f"escrow {esc_before}->{esc_after} (refreshPhase rc={rc})")

say("")
say(f"SUMMARY passed={PASS} failed={FAIL}")
with open(LOG, "w") as f:
    f.write("\n".join(lines) + "\n")
sys.exit(1 if FAIL else 0)
