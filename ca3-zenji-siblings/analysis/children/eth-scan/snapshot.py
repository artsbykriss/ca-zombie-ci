#!/usr/bin/env python3
"""Final consistent-state snapshot for the ETH sibling scan. Read-only eth_calls at one block."""
import json, subprocess, os

RPC = os.environ.get("PUB_RPC", "https://ethereum-rpc.publicnode.com")
BLK = int(subprocess.check_output(["cast", "block-number", "--rpc-url", RPC]).decode().strip())
STATE = {"block": BLK, "rpc": "publicnode (keyless)", "reads": {}}

def call(to, sig, *args):
    cmd = ["cast", "call", to, sig, *[str(a) for a in args], "--rpc-url", RPC, "--block", str(BLK)]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, timeout=60).decode().strip()
        return out
    except subprocess.CalledProcessError as e:
        return "REVERT: " + e.output.decode().strip().splitlines()[-1][:200]

def i(x):
    try:
        return int(x.split()[0])
    except Exception:
        return None

def rec(key, to, sig, *args):
    v = call(to, sig, *args)
    STATE["reads"][key] = {"to": to, "sig": sig, "raw": v, "int": i(v)}
    return v

# ---------- YieldBasis ----------
F = "0x370a449FeBb9411c95bf897021377fe0B7D100c0"
rec("yb.market_count", F, "market_count()(uint256)")
rec("yb.LEVERAGE", F, "LEVERAGE()(uint256)")
rec("yb.min_admin_fee", F, "min_admin_fee()(uint256)")
rec("yb.admin", F, "admin()(address)")
rec("yb.STABLECOIN", F, "STABLECOIN()(address)")
rec("yb.amm_impl", F, "amm_impl()(address)")
YB = []
for m in range(11):
    row = {}
    row["idx"] = m
    s = call(F, "markets(uint256)(address,address,address,address,address,address,address)", m).split("\n")
    row["asset"], row["pool"], row["amm"], row["lt"] = s[0], s[1], s[2], s[3]
    row["lt_symbol"] = call(row["lt"], "symbol()(string)")
    row["lt_supply"] = i(call(row["lt"], "totalSupply()(uint256)"))
    row["lt_pps"] = i(call(row["lt"], "pricePerShare()(uint256)"))
    vo = call(row["amm"], "value_oracle()(uint256,uint256)").split("\n")
    row["p_o"] = int(vo[0].split()[0]); row["equity_usd18"] = int(vo[1].split()[0])
    row["rate"] = i(call(row["amm"], "rate()(uint256)"))
    row["accrued_interest"] = i(call(row["amm"], "accumulated_interest()(uint256)"))
    row["amm_crvusd_cash"] = i(call("0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E", "balanceOf(address)(uint256)", row["amm"]))
    row["lt_crvusd_cash"] = i(call("0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E", "balanceOf(address)(uint256)", row["lt"]))
    row["pool_lp_price"] = i(call(row["pool"], "lp_price()(uint256)"))
    row["pool_lp_supply"] = i(call(row["pool"], "totalSupply()(uint256)"))
    row["pool_bal0"] = i(call(row["pool"], "balances(uint256)(uint256)", 0))
    row["pool_bal1"] = i(call(row["pool"], "balances(uint256)(uint256)", 1))
    YB.append(row)
STATE["yieldbasis_markets"] = YB

# ---------- Fluid Lite / Instadapp ----------
FL = {
 "eth_v2": "0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78",
 "usd_v2": "0x273DA948ACa9261043fbdb2a857BC255ECC29012",
 "v1_eth": "0xc383a3833A87009fD9597F8184979AF5eDFad019",
 "v1_usdc": "0xc8871267e07408b89aA5aEcc58AdCA5E574557F8",
}
for k, a in FL.items():
    rec(f"fluid.{k}.name", a, "name()(string)")
    rec(f"fluid.{k}.symbol", a, "symbol()(string)")
    rec(f"fluid.{k}.asset", a, "asset()(address)")
    rec(f"fluid.{k}.totalAssets", a, "totalAssets()(uint256)")
    rec(f"fluid.{k}.totalSupply", a, "totalSupply()(uint256)")
    rec(f"fluid.{k}.exchangePrice", a, "exchangePrice()(uint256)")
for s in ["updateExchangePrice()", "rebalanceFromWstETHToWeETH(uint256,uint256,uint256)"]:
    STATE["reads"][f"fluid.eth_v2.probe.{s}"] = {"to": FL["eth_v2"], "sig": s, "raw": call(FL["eth_v2"], s, *([1,1,0] if "rebalance" in s else []))}
STATE["reads"]["fluid.eth_v2.isRebalancer(dead)"] = {"to": FL["eth_v2"], "sig": "isRebalancer(address)(bool)", "raw": call(FL["eth_v2"], "isRebalancer(address)(bool)", "0x000000000000000000000000000000000000dEaD")}
rec("fluid.eth_v2.getAdmin", FL["eth_v2"], "getAdmin()(address)")
rec("fluid.eth_v2.vaultDSA", FL["eth_v2"], "vaultDSA()(address)")
rec("fluid.usd_v2.getStrategyHandler", FL["usd_v2"], "getStrategyHandler()(address)")
rec("fluid.usd_v2.getFUSDC", FL["usd_v2"], "getFUSDC()(address)")
rec("fluid.v1_eth.netAssets", FL["v1_eth"], "netAssets()(uint256)")
rec("fluid.v1_usdc.getCurrentExchangePrice", FL["v1_usdc"], "getCurrentExchangePrice()(uint256,uint256)")

# ---------- Gearbox ----------
CM = "0x006895396432a631b73EAA6CAd90911eAe0d3EE5"
FAC = "0xae72924d7Dc51E4f566b490637419beB0bFb6Ea2"
ORC = "0x6C10935f56Ec2dcDd36b633d4cFeB1af02083380"
POOL = "0xA9d17f6D3285208280a1Fd9B94479c62e0AABa64"
rec("gb.cm.version", CM, "version()(uint256)")
rec("gb.cm.underlying", CM, "underlying()(address)")
rec("gb.cm.creditFacade", CM, "creditFacade()(address)")
rec("gb.cm.priceOracle", CM, "priceOracle()(address)")
rec("gb.facade.paused", FAC, "paused()(bool)")
rec("gb.oracle.wstETH.feed", ORC, "priceFeedParams(address)((address,uint32,bool))", "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0")
rec("gb.oracle.WETH.feed", ORC, "priceFeedParams(address)((address,uint32,bool))", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
rec("gb.pool.totalBorrowed", POOL, "totalBorrowed()(uint256)")
rec("gb.pool.availableLiquidity", POOL, "availableLiquidity()(uint256)")
STATE["reads"]["gb.facade.probe.liquidate"] = {"to": FAC, "sig": "liquidateCreditAccount(address,address,(address,bytes,bytes)[])", "raw": call(FAC, "liquidateCreditAccount(address,address,(address,bytes,bytes)[])", "0x000000000000000000000000000000000000dEaD", "0x000000000000000000000000000000000000dEaD", "[]")}

# ---------- Zenji pmUSD (not the two incident vaults) ----------
Z = {"wbtc": "0xB415bce7d24ef95405006e8A1a9381119F7fc31F", "wsteth": "0x45bBa5E1A014f9944fC077F5A0a3D4106fA31595"}
for k, a in Z.items():
    rec(f"zenji_pmusd.{k}.symbol", a, "symbol()(string)")
    rec(f"zenji_pmusd.{k}.totalSupply", a, "totalSupply()(uint256)")
    rec(f"zenji_pmusd.{k}.totalAssets", a, "totalAssets()(uint256)")
    rec(f"zenji_pmusd.{k}.loanManager", a, "loanManager()(address)")
    rec(f"zenji_pmusd.{k}.yieldStrategy", a, "yieldStrategy()(address)")
    rec(f"zenji_pmusd.{k}.gov", a, "gov()(address)")
    rec(f"zenji_pmusd.{k}.emergencyMode", a, "emergencyMode()(bool)")
    rec(f"zenji_pmusd.{k}.targetLtv", a, "targetLtv()(uint256)")
    rec(f"zenji_pmusd.{k}.rebalance_bounty", a, "rebalanceBountyRate()(uint256)")
    STATE["reads"][f"zenji_pmusd.{k}.probe.rebalance(dead)"] = {"to": a, "sig": "rebalance()", "raw": call(a, "rebalance()")}
    STATE["reads"][f"zenji_pmusd.{k}.probe.harvestYield(dead)"] = {"to": a, "sig": "harvestYield()", "raw": call(a, "harvestYield()")}

# ---------- LlamaLend zaps / wrappers ----------
ZAPS = {
 "Curve_LlamaLendLeverageZap": "0xE1834AF57923059B4306B468013262D73F344D4E",
 "LlamaLend_1inch_zap": "0xe61d72cb6d30Bc21A623875f160682E6C17B005E",
 "LlamaLendLevCreate_DFS": "0x534b704a62385cfe5EEB8d9605419743d4fe105E",
 "LlamaLendBoost_DFS": "0xA21c1cE7318C6d38a10DE44c2cd5D80514437D85",
 "Zunami_LlamalendCrvUsdStrat": "0x8dfcD34b074517C446a7885c271AFD365981Ed47",
 "Zunami_LlamalendCrvStrat": "0xF3558b523235fE9bb78A02CA6F18292F4796ab73",
}
for k, a in ZAPS.items():
    STATE["reads"][f"llama.{k}.eth_balance"] = {"to": a, "sig": "eth_getBalance", "raw": call(a, "eth_balance") if False else subprocess.check_output(["cast","balance",a,"--rpc-url",RPC,"--block",str(BLK)]).decode().strip()}
    rec(f"llama.{k}.crvusd_balance", "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E", "balanceOf(address)(uint256)", a)

rec("stakedao.recovery_vault.totalAssets", "0xF221D8359F3eE259adf2015F57E9fA863b952998", "totalAssets()(uint256)")
rec("stakedao.recovery_vault.asset", "0xF221D8359F3eE259adf2015F57E9fA863b952998", "asset()(address)")
rec("stakedao.recovery_pool.totalSupply", "0x516C3eCfe45F0820653E08DD7c93633d71B93Cb5", "totalSupply()(uint256)")
STATE["reads"]["curvance.dao_bonding.eth_getCode"] = {
    "to": "0xFf5c76Abb78cba501aA2c7A1bFfBaBf2b9DeB989",
    "sig": "eth_getCode",
    "raw": "0x" + subprocess.check_output(["cast", "code", "0xFf5c76Abb78cba501aA2c7A1bFfBaBf2b9DeB989", "--rpc-url", RPC, "--block", str(BLK)]).decode().strip().removeprefix("0x"),
}
STATE["reads"]["curvance.dao_bonding.code_len"] = {"to": "0xFf5c76Abb78cba501aA2c7A1bFfBaBf2b9DeB989", "sig": "code_len", "int": (len(STATE["reads"]["curvance.dao_bonding.eth_getCode"]["raw"]) - 2)//2}

print("block", BLK)
json.dump(STATE, open("evidence/live_state.json", "w"), indent=1)
print("wrote evidence/live_state.json")
