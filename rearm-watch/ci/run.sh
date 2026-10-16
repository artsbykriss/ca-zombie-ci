#!/usr/bin/env bash
# rearm-watch heavy job — live-state snapshot + USD pricing for the four re-arm-on-deposit targets.
# Read-only: only eth_call / eth_getBalance / eth_getLogs. No secrets printed (RPC URLs are used from
# env but never written to output files).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

ETH="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
POLY="${POLYGON_RPC_URL:-https://polygon.drpc.org}"

echo "[rearm-watch] start $(date -u +%FT%TZ)"

OUT="ci-out/live_state.txt"
: > "$OUT"

{
  echo "== rearm-watch live state $(date -u +%FT%TZ) =="
  echo "-- Ethereum block: $(cast block-number --rpc-url "$ETH")"
  echo "-- Polygon block:  $(cast block-number --rpc-url "$POLY")"

  echo
  echo "== Z3-H6 BitBay UsdcDaiV4Vault (Polygon 0x048E88311ca84876aeA086125825492e2AF2e5A0) =="
  V=0x048E88311ca84876aeA086125825492e2AF2e5A0
  echo "mintThis        : $(cast call $V 'mintThis()(bool)' --rpc-url "$POLY")"
  echo "liquidity       : $(cast call $V 'liquidity()(uint128)' --rpc-url "$POLY")"
  echo "totalShares     : $(cast call $V 'totalShares()(uint256)' --rpc-url "$POLY")"
  echo "tickLower/Upper : $(cast call $V 'tickLower()(int24)' --rpc-url "$POLY") / $(cast call $V 'tickUpper()(int24)' --rpc-url "$POLY")"
  echo "lastReposition  : $(cast call $V 'lastReposition()(uint256)' --rpc-url "$POLY")"
  echo "minter          : $(cast call $V 'minter()(address)' --rpc-url "$POLY")"
  echo "vault DAI       : $(cast call 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 'balanceOf(address)(uint256)' $V --rpc-url "$POLY")"
  echo "vault USDC      : $(cast call 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359 'balanceOf(address)(uint256)' $V --rpc-url "$POLY")"

  echo
  echo "== Z3-H7 X7 Finance X7Pioneer (Ethereum 0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7) =="
  X=0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7
  echo "balance         : $(cast balance $X --rpc-url "$ETH")"
  echo "lastETHBalance  : $(cast call $X 'lastETHBalance()(uint256)' --rpc-url "$ETH")"
  echo "totalRewards    : $(cast call $X 'totalRewards()(uint256)' --rpc-url "$ETH")"
  echo "totalSupply     : $(cast call $X 'totalSupply()(uint256)' --rpc-url "$ETH")"
  echo "unclaimedRewards(token 0)  : $(cast call $X 'unclaimedRewards(uint256)(uint256)' 0 --rpc-url "$ETH" 2>/dev/null || echo n/a)"
  echo "unclaimedRewards(token 300): $(cast call $X 'unclaimedRewards(uint256)(uint256)' 300 --rpc-url "$ETH" 2>/dev/null || echo n/a)"
  echo "transferUnlocked(0)/ac(0)  : $(cast call $X 'transferUnlocked(uint256)(bool)' 0 --rpc-url "$ETH") / $(cast call $X 'rewardsClaimed(uint256)(uint256)' 0 --rpc-url "$ETH")"

  echo
  echo "== Z3-H9 Unistreet LaunchpadFactoryAuto (Ethereum 0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825) =="
  F=0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825
  POSM=0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e
  echo "factory balance : $(cast balance $F --rpc-url "$ETH")"
  echo "launchesCount   : $(cast call $F 'launchesCount()(uint256)' --rpc-url "$ETH")"
  echo "POSM balanceOf(factory) : $(cast call $POSM 'balanceOf(address)(uint256)' $F --rpc-url "$ETH")"
  echo "operator approvals still live (factory -> operator):"
  for op in 0xc7d8C70F4349aCc55409800c8768E801b7556B77 0xEda1f193e0c211b42ACaA9342CB7150fa3Fd205A 0x3C59433D780411923e808499C4fad9b9809B5f51 0xDE2e60798068B95c7054642aBb428A1229a47A6C; do
    echo "  $op : $(cast call $POSM 'isApprovedForAll(address,address)(bool)' $F $op --rpc-url "$ETH")"
  done

  echo
  echo "== Z3-H10 DAOstack Genesis Alpha (Ethereum avatar 0x7b11dFb29504abc8C0DFa60DC7E0aa2AAe836DB0) =="
  AV=0x7b11dFb29504abc8C0DFa60DC7E0aa2AAe836DB0
  echo "avatar ETH      : $(cast balance $AV --rpc-url "$ETH")"
  echo "Reputation supply: $(cast call 0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9 'totalSupply()(uint256)' --rpc-url "$ETH")"
  echo "GDT balance     : $(cast call 0xe30a71938b743d126E977A2b3F7450484F209a34 'balanceOf(address)(uint256)' $AV --rpc-url "$ETH")"

  echo
  echo "== USD prices (DefiLlama, current) =="
  curl -s "https://coins.llama.fi/prices/current/coingecko:ethereum,coingecko:dai,coingecko:usd-coin" || echo "(price fetch failed)"
  echo
} | tee "$OUT"

# machine-readable snapshot
python3 - <<'PY' > ci-out/live_state.json 2>/dev/null || echo '{"error":"snapshot parse failed"}' > ci-out/live_state.json
import json, subprocess, os, time

ETH = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
POLY = os.environ.get("POLYGON_RPC_URL") or "https://polygon.drpc.org"

def cast(*args):
    try:
        return subprocess.run(["cast", *args], capture_output=True, text=True, timeout=60).stdout.strip()
    except Exception as e:
        return f"error: {e}"

def call(rpc, addr, sig, *args):
    return cast("call", addr, sig, *args, "--rpc-url", rpc)

def price(ids):
    try:
        r = subprocess.run(["curl", "-s", f"https://coins.llama.fi/prices/current/{ids}"], capture_output=True, text=True, timeout=30).stdout
        return json.loads(r).get("coins", {})
    except Exception:
        return {}

p = price("coingecko:ethereum,coingecko:dai,coingecko:usd-coin")
eth_usd = p.get("coingecko:ethereum", {}).get("price", 0)

vault = "0x048E88311ca84876aeA086125825492e2AF2e5A0"
x7 = "0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7"
fac = "0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825"
posm = "0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e"
av = "0x7b11dFb29504abc8C0DFA60DC7E0aa2AAe836DB0"

x7_bal = cast("balance", x7, "--rpc-url", ETH)
try:
    x7_bal_eth = int(x7_bal) / 1e18
except Exception:
    x7_bal_eth = None

snap = {
    "ts": int(time.time()),
    "eth_usd": eth_usd,
    "ethereum_block": cast("block-number", "--rpc-url", ETH),
    "polygon_block": cast("block-number", "--rpc-url", POLY),
    "bitbay": {
        "vault": vault,
        "mintThis": call(POLY, vault, "mintThis()(bool)"),
        "liquidity": call(POLY, vault, "liquidity()(uint128)"),
        "totalShares": call(POLY, vault, "totalShares()(uint256)"),
        "dai": call(POLY, "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063", "balanceOf(address)(uint256)", vault),
        "usdc": call(POLY, "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359", "balanceOf(address)(uint256)", vault),
    },
    "x7": {
        "pioneer": x7,
        "balance_wei": x7_bal,
        "balance_eth": x7_bal_eth,
        "balance_usd": (x7_bal_eth or 0) * eth_usd,
        "lastETHBalance": call(ETH, x7, "lastETHBalance()(uint256)"),
        "totalRewards": call(ETH, x7, "totalRewards()(uint256)"),
        "totalSupply": call(ETH, x7, "totalSupply()(uint256)"),
    },
    "unistreet": {
        "factory": fac,
        "posm_balanceOf_factory": call(ETH, posm, "balanceOf(address)(uint256)", fac),
        "launchesCount": call(ETH, fac, "launchesCount()(uint256)"),
    },
    "daostack": {
        "avatar": av,
        "avatar_eth": cast("balance", av, "--rpc-url", ETH),
    },
}
print(json.dumps(snap, indent=2))
PY

echo "[rearm-watch] done; wrote ci-out/live_state.txt and ci-out/live_state.json"
