import json, os, sys, html
sys.path.insert(0, os.path.dirname(__file__))
from rows import ROWS

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AN = os.path.join(BASE, 'analysis')
os.makedirs(AN, exist_ok=True)

LANES = ['r1','r2','r3','r4','r5','r6','r7','d2a','d2b','d2c','d2d']
LANE_NAMES = {
 'r1':'r1-evm-fresh', 'r2':'r2-x-radar', 'r3':'r3-disclosure-gap', 'r4':'r4-non-evm',
 'r5':'r5-exotic', 'r6':'r6-new-chains', 'r7':'r7-beyond-llama',
 'd2a':'d2a-fresh14d', 'd2b':'d2b-staleprice', 'd2c':'d2c-dormantdao', 'd2d':'d2d-liqsweep'
}
STATUS_ORDER = ['FINDING','LOW','OPEN','PARKED','CLOSED-README','CLOSED-LANE','COVERED','EXCLUDED']

# ---- OPEN list metadata (manual, ranked by funds x plausibility) ----
OPEN_META = [
 dict(rank=1, lane='r6', target='Katana Vault Bridge / vbASSET stack',
      chain='Katana L2 <-> Ethereum',
      funds='~$27.7M reported L1 vault totalAssets (7.14M USDC + 3.07M USDT + 154.2 WBTC + 2,074.6 WETH; USDC leg staked in yieldVault 0xbeef... whose totalAssets is 9.43M USDC) + 6.67M L2 vbUSDC supply',
      addr='L2 minter 0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0; L1 vbUSDC 0x53E82ABbb12638F09d9e624578ccB666217a765e (impl 0xcc865b03..., yieldVault 0xbeefb9f61cc44895d8aec381373555a64191a9c4); L1 adapter 0xb5bada33542a05395d504a25885e02503a957bb3; L2 vbUSDC 0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36',
      plaus='MED-HIGH', conf='MEDIUM',
      path='Unverified 1,718-byte LZ OApp mints/burns bridged vbASSETs. peers(30101)=0xb5bada... is set; lzReceive origin/peer binding and endpoint auth not decompiled. A forged/replayed message minting unbacked vbASSET has the L2 Yearn vault + DEX exit as immediate liquidity. L1 vault proxies hold dust; stakedAssets sits in yieldVault 0xbeef... (USDC leg verified totalAssets 9.43M), so the reported $27.7M is partly strategy custody and the 154.2 WBTC figure needs reconciliation vs r6\'s 33.68 WBTC.',
      next='Decompile L2 minter and L1 adapter; confirm lzReceive onlyEndpoint + peer(30101)/origin binding; fork-test forged message and replay; reconcile vbWBTC totalAssets vs strategy custody.'),
 dict(rank=2, lane='r7', target='Unnamed zkSync Era settlement vault 0x621425a1',
      chain='zkSync Era',
      funds='~$5.5M+ (1,121.26 ETH + 2,182,482 USDC + 181,232 USDT + 12.52M ZK)',
      addr='0x621425a1Ef6abE91058E9712575dcc4258F8d091 (owner/creator EOA 0x000002c34bae6dd7bec72acba6aaac1e01a359de)',
      plaus='MEDIUM', conf='LOW-MED',
      path='61.9KB unverified contract; public withdraw(address,address,uint256) reverts with Panic 0x11 for a zero-balance caller, so accounting is per-user; 199,874 txs / 118.8M transfers suggests a CEX/payment omnibus. If the accounting mapping is caller-settable or transferAndDeposit credits without custody, the vault drains.',
      next='Decompile withdraw/transferAndDeposit, map the accounting storage and auth, identify the operator (CEX vs protocol); check deposit/withdraw event reconciliation.'),
 dict(rank=3, lane='r4', target='JustLend Energy Rental (MarketG1)',
      chain='TRON',
      funds='1.56M TRX native (~$500k) + 3.46M TRX nominal security deposits (~$1.11M per r4)',
      addr='proxy TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd -> impl TNoHbPuBQrVanVf9qxUsSvHdB2eDkeDAKD',
      plaus='MEDIUM', conf='MED-LOW',
      path='rentResource/returnResource/liquidate/forceLiquidate are permissionless; live fee is 8% of rent, min-deposit orders can be liquidated almost immediately; the badDebt branch (deposit < fee) books a loss while paying the fee. Renter+identifier collusion plus return-after-liquidate double-refund is untested.',
      next='Fork-prove the liquidate -> returnResource sequence and the badDebt branch; measure per-cycle extraction vs 3.46M TRX deposits; check for a non-colluding path.'),
 dict(rank=4, lane='r1', target='Alchemix V3',
      chain='Ethereum, Arbitrum, Optimism, Base',
      funds='$40.6M DL',
      addr='factories 0xdd56b00302e91C4c2b8246156bDEAa1cEDc58984 (ETH), 0x8c7C0C380bA4eE38461eb5a6b82e5d930EC11Ca2 (Arb/OP), 0x2584E8b0616b3E750492c9629a3b27679C410cb9 (Base)',
      plaus='LOW-MED', conf='LOW',
      path='Fresh VaultV2 ERC-4626 (Apr 2026) created via permissionless createVaultV2; share math, first-redeemer/donation, harvest/withdraw roles and migration lens unreviewed.',
      next='Pick largest CreateVaultV2 vault; donation/first-redeemer test; read harvest/withdraw role gates.'),
 dict(rank=5, lane='r1', target='Curve LlamaLend V2',
      chain='Ethereum, Optimism',
      funds='$42.1M DL',
      addr='ETH factory 0x8f6B56ec5DdF1f2691a1059f1D3cd97AC9EAB0Bd; OP 0x5F94073E3f51c1FFf92ffc6b4B06b7Af193B3640',
      plaus='LOW', conf='LOW',
      path='Fresh Jun-Jul 2026 LL v2 markets, new controller/AMM/vault blueprints and per-market oracles; soft-liquidation/partial-repay edge math unreviewed.',
      next='Enumerate markets + oracle params; quick soft-liquidation/partial-repay pass.'),
 dict(rank=6, lane='r1', target='Flex',
      chain='Ethereum',
      funds='$1.9M DL (6 markets)',
      addr='registry 0x9117440a7d03238905d1c8908157bd7a547c77c8; markets incl. 0xd82db989...; oracles 0x6d8d09f1..., 0x38cae071...',
      plaus='LOW-MED', conf='LOW',
      path='Liquity-v1 fork with custom PriceOracle and exotic collateral feeds; redemption/bonus math deviates from canonical Liquity and is unread.',
      next='Read oracle aggregator (spot vs Chainlink, staleness, decimals); fuzz redemption at low TCR.'),
 dict(rank=7, lane='r1', target='JPYdf',
      chain='Ethereum',
      funds='$849k DL',
      addr='wstETH vault 0x6042755ecca71a1be9c7091441ca5beaa6b520e4; USDC vault 0x087ebaf3f1b094b2046912a5e5f0bad78df3eaa7 -> impl 0x878da559d17458d84fd7a42804ccaea53c2f10b5',
      plaus='LOW-MED', conf='LOW',
      path='receiveFromStrategy(declaredAmount) and claim(requestId) are unprivileged accounting entrypoints; backstop release/writeoff and redeem-queue pricing unreviewed.',
      next='Trace receiveFromStrategy shortfall handling + backstop release + writeoff; verify redeem queue pricing.'),
 dict(rank=8, lane='r7', target='zkSwap V2 (legacy zkSync AMM)',
      chain='zkSync Era',
      funds='$533k DL; 48 pairs',
      addr='factory 0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d; pair0 0xa55e595aaeda7f8f8e74b0f765b1c9f7eaa0540d',
      plaus='LOW', conf='LOW',
      path='Unverified UniV2-style factory/pairs; pair0 holds 8,926 USDC + 3.74 WETH. Fork drift in swap/fee/collect or a missing feeTo auth would be directly harvestable.',
      next='Decompile factory/pair, diff vs UniswapV2; check feeTo/setter auth, skim/sync, pair creation.'),
 dict(rank=9, lane='d2a', target='DeepSwap',
      chain='Solana',
      funds='$78.7k DL',
      addr='program HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP',
      plaus='LOW', conf='LOW',
      path='Raydium cp-swap fork tied to DEEP launchpad; missing owner check on withdraw/fee-claim or fork-drift in deposit/withdraw fees would drain pool vaults.',
      next='Recover IDL/diff program vs Raydium cp-swap; verify fee-recipient withdraw instruction auth.'),
 dict(rank=10, lane='d2a', target='Motoswap / VampChef',
      chain='Ethereum',
      funds='$55.6k DL',
      addr='VampChef 0x51e648f08a9a08A724591938d9cbc483C809aCA4; MotoStaking 0xCE88F2C6B49EfBb92555eE5475311f0e250C2528; MOTO 0xBd965230588EAA536dE6aA45E8ebbc01638535e0',
      plaus='LOW', conf='LOW',
      path='Proxied MasterChef + revenue-share staking + new UniV2 registry; legacy accRewardPerShare/lpSupply accounting and emergencyWithdraw unread.',
      next='Read VampChef impl (EIP-1967), verify lpSupply sync + emergencyWithdraw; check MotoStaking lock math.'),
]

# ---- compute counts ----
from collections import Counter, defaultdict
cnt = Counter(); lane_cnt = defaultdict(Counter); n_total = 0
for lane, target, funds, status, ref, note, *rest in ROWS:
    n = rest[0] if rest else 1
    n_total += n
    cnt[status] += n
    lane_cnt[lane][status] += n
closed = cnt['CLOSED-README'] + cnt['CLOSED-LANE'] + cnt['EXCLUDED'] + cnt['COVERED']
open_n = cnt['OPEN']
parked = cnt['PARKED']
findings = cnt['FINDING']
low = cnt['LOW']
assert open_n == len(OPEN_META), (open_n, len(OPEN_META))

# ---- markdown helpers ----
def esc(s): return str(s).replace('|','\\|').replace('\n',' ')
def status_badge(s):
    return {'FINDING':'**FINDING**','LOW':'LOW','OPEN':'**OPEN**','PARKED':'PARKED',
            'CLOSED-README':'closed (README)','CLOSED-LANE':'closed (in-lane)',
            'COVERED':'covered (ZH4-03)','EXCLUDED':'excluded'}[s]

def table(rows, title):
    out = [f'## {title}', '', '| # | Target | Live funds | Disposition | Why / citation |', '|---|---|---|---|---|']
    for i,(lane,target,funds,status,ref,note,*rest) in enumerate(rows,1):
        n = rest[0] if rest else 1
        nm = f' ({n} names)' if n>1 else ''
        out.append(f'| {i} | {esc(target)}{nm} | {esc(funds)} | {status_badge(status)} | {esc(note)} — `{esc(ref)}` |')
    out.append('')
    return out

# ---- per-lane files ----
for lane in LANES:
    rows = [r for r in ROWS if r[0]==lane]
    lines = [f'# Residual enumeration — {LANE_NAMES[lane]}', '',
             f'Source: `zombie-hunt-iv/wave1/{LANE_NAMES[lane]}.md`' if lane.startswith('r') else f'Source: `zombie-hunt-iv/wave2/{LANE_NAMES[lane]}.md`', '',
             f'Rows/leads enumerated: **{sum((r[6] if len(r)>6 else 1) for r in rows)}**.', '']
    lines += table(rows, 'Rows and prose/negative leads')
    with open(os.path.join(AN, f'{lane}.md'),'w') as f: f.write('\n'.join(lines))

# ---- ALL ROWS ----
all_lines = ['# ZH4 Wave-B0 — full residual disposition table', '',
             f'Every candidate row and named prose/negative lead from the 7 wave-1 lanes and d2a–d2d. '
             f'**{n_total} named candidates** in {len(ROWS)} rows/groups. Status vocabulary: FINDING (README Tier 1/2), LOW (README Tier 3), '
             f'OPEN (actionable residual), PARKED (below-bar/unlocated/watch/trigger/P-class), closed (README or in-lane verdict), excluded (prior corpus).', '']
for lane in LANES:
    rows=[r for r in ROWS if r[0]==lane]
    all_lines += table(rows, f'{lane} — {LANE_NAMES[lane]}')
with open(os.path.join(AN,'ALL-ROWS.md'),'w') as f: f.write('\n'.join(all_lines))

# ---- summary.json ----
summary = {
 'finding':'ZH4-Wave-B0-residual-recon',
 'title':'Residual reconciliation of ZH4 wave1 + d2a-d2d; nothing left without a disposition',
 'date':'2026-10-18',
 'mode':'read-only; no transactions; no keyed RPC URLs in folder files',
 'chains':['ethereum','arbitrum','bsc','mantle','zksync-era','iotex','ronin','flare','katana','optimism','base','tron','solana','rsk','0g'],
 'counts':{
   'named_candidates_enumerated':n_total,
   'table_rows_and_groups':len(ROWS),
   'findings_tier1_tier2':findings,
   'low_tier3':low,
   'closed_total':closed,
   'closed_readme':cnt['CLOSED-README'],
   'closed_in_lane':cnt['CLOSED-LANE'],
   'excluded':cnt['EXCLUDED'],
   'covered_zh4_03':cnt['COVERED'],
   'parked':parked,
   'open':open_n,
 },
 'open_list':[{
   'rank':o['rank'],'target':o['target'],'chain':o['chain'],'live_funds':o['funds'],
   'addresses':o['addr'],'plausibility':o['plaus'],'confidence':o['conf'],
   'path':o['path'],'next_check':o['next']} for o in OPEN_META],
 'specific_rows':{
   'derive_v3':'CLOSED-in-lane: zk-proven Outbox + permissioned batchSubmitter + $2M throttle; no E-U path at recon depth (r1:11, top5#3); watch zk layer.',
   'flex':'OPEN (low): $1.9M Liquity-v1 fork with custom oracle; oracle/redemption unread.',
   'alchemix_v3':'OPEN (low-med): $40.6M fresh VaultV2; donation/first-redeemer/harvest unread.',
   'curve_llamalend_v2':'OPEN (low): $42.1M fresh markets/new oracles; soft-liquidation edge unread.',
   'morpho_midnight':'PARKED: $8.6M, immutable, audited; no concrete path.',
   'jpy_df':'OPEN (low-med): $849k; receiveFromStrategy/backstop accounting unread.',
   'qualia':'PARKED: $89k, contracts not located.',
   'baibai':'PARKED: $120k, contracts not located.',
   'deepswap':'OPEN (low): $78.7k Raydium cp-swap fork; program diff unread.',
   'motoswap_vampchef':'OPEN (low): $55.6k proxied MasterChef; lpSupply/emergencyWithdraw unread.',
   'nullmask_tacit':'PARKED: $71k/$69k, contracts not located.',
   'shibbex_dogswap':'COVERED by ZH4-03 deep-dive in flight; not deep-dived here.',
   'metronome_msusd':'CLOSED-in-lane: swap active but 10% fee vs ~10% discount => -9% round trip; no liquidatable positions; watch 9-11% collateral drop.',
   'fedz_fusd':'PARKED: redemption restricted to Fedz-NFT holders.',
   'usdb':'PARKED: ~1% bridge-exit edge, below bar.',
   'satusd':'PARKED: 0.62% discount, below bar / conversion unscanned.',
   'bend':'CLOSED-in-lane: 0 accounts HF<1 with collateral; keepers active.',
   'colend':'CLOSED-in-lane: $0 borrowed.',
   'klend':'CLOSED-in-lane: dead/parked domain; no live Kaia venue.',
   'hyperevm_morpho_khype':'PARKED watch: HF 1.0042, not liquidatable today; $356k conditional.',
   'gimo_st0g':'PARKED: ~$3.5M plausible, mint gated, exit liquidity ~$1.1k.',
   'cl8y':'CLOSED-in-lane: identified as CeramicLiberty.com memecoin; both addresses are EOAs holding 126.7 ETH + 0.03 ETH; no contract surface.',
 },
 'unlocated_targets_resolved':{
   'MoreMarkets.xyz':'PARKED: located; Ethereum RLUSD vault totalAssets 30.68 RLUSD; the $432k Ethereum TVL is hyperETH/BTC/USD token market cap, not protocol custody; Flare fXRP ~$16.6k supply; no protocol pot.',
   'zkSwap V2':'OPEN (low): factory 0xeeE1...; 48 pairs; pair0 8,926 USDC + 3.74 WETH; unverified UniV2 fork.',
   'MUFEX':'PARKED: 3 vault contracts; live USDT ~$6.5k across Arb/Polygon/Mantle/BSC (DL $276k stale).',
   'Lendle':'PARKED: 11 reserves, ~$174k aToken cash, ~$13k borrows, no empty market; Aave-v2 fork, no concrete path.',
   'xDollar':'CLOSED-in-lane: 28 IoTeX troves, 143.9k XUSD debt vs ~$11.7k WIOTX collateral (~8% TCR); insolvent, no extraction.',
   'Ronin deprecated staking manager':'CLOSED-in-lane: 755,974.8 RON + 101,474.7 AXS (~$157k); impl has only admin withdrawEther/withdrawToken (revert for random caller); no user unstake/exit; P/S class.',
 },
 'latest_block':{'ethereum':26215684,'arbitrum':515815045,'bsc':128261569,'mantle':102075427,'zksync-era':72540257,'iotex':53495038,'ronin':62406190,'flare':72362372,'katana':45538361,'rsk':9334070},
 'key_facts':[
   'Every one of the 7 wave-1 files and all four d2* files was enumerated (table rows + prose/negative leads).',
   'The three Tier-1 findings and four Tier-2 findings are unchanged; no new Tier-1/2 was created.',
   'The largest residual omission from README is Katana Vault Bridge (~$27.7M L1 vault assets + 6.67M L2 vbUSDC).',
   'The second-largest is the unnamed zkSync Era settlement vault (1,121 ETH + 2.18M USDC + 181k USDT + 12.5M ZK).',
   'JustLend Energy Rental has 1.56M TRX native (~$500k) plus 3.46M TRX nominal security deposits; the badDebt/double-refund branch is untested.',
   'MoreMarkets.xyz, MUFEX, Lendle and xDollar were located and do not hold an extractable protocol pot; Ronin is admin-only/P-S.',
 ],
 'caveats':[
   'Read-only; no transactions signed or sent. All figures are point-in-time 2026-10-18 reads or the cited ZH4 file date.',
   'OPEN is a triage label, not a proven vulnerability. Plausibility/confidence are explicit per row.',
   'Public RPCs were used; keyed URLs are not stored in this folder.',
   'Zappy has a contradiction: r7 on-chain reads show ~$90k; d2d L7 found the domain dead. README Tier3 #8 follows r7 on-chain evidence; verify before action.',
   'The zkSync vault may be a CEX/omnibus rather than a protocol; this is the main blocker.',
 ],
 'one_liner':f'{n_total} named residual candidates enumerated: {findings} Tier1/2, {low} Tier3, {closed} closed/excluded/covered, {parked} parked, {open_n} OPEN. Largest OPEN: Katana Vault Bridge (~$27.7M reported L1 backing + $6.67M L2 supply) and the unnamed zkSync Era settlement vault (~$5.5M).',
 'ci':{
   'run_urls':['https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081911266',
               'https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081800492'],
   'validation':'pass — counts match summary.json; 0 secret hits; live reads on Ethereum/Katana/zkSync Era/Ronin/Mantle/TRON returned',
 }
}
with open(os.path.join(BASE,'summary.json'),'w') as f: json.dump(summary,f,indent=2)

# ---- README ----
readme = []
readme += ['# ZH4 Wave-B0 — residual reconciliation', '',
 '**Date:** 2026-10-18 · **Mode:** read-only; no transactions signed or sent; no keyed RPC URLs or secrets in this folder · **Scope:** every candidate row and named prose/negative lead in `zombie-hunt-iv/wave1/r1–r7` and `zombie-hunt-iv/wave2/d2a–d2d`, plus residual leads inside `wave2/v*.md`.', '',
 '**Purpose.** The ZH4 README is the campaign’s verdict layer. This pass checks that nothing in the working files was left without a disposition, locates the “contracts not located” rows, and surfaces candidates that still have **live funds + a plausible unprivileged extraction path today** for dedicated deep-dives. It does not deep-dive them.', '',
 '## Headline counts', '',
 '| Metric | Count |', '|---|---|',
 f'| Named candidates enumerated | **{n_total}** |',
 f'| Rows/groups in the disposition table | {len(ROWS)} |',
 f'| Tier 1/2 findings (README) | {findings} |',
 f'| Tier 3 LOW (README) | {low} |',
 f'| Closed / excluded / covered | **{closed}** (README {cnt["CLOSED-README"]} · in-lane {cnt["CLOSED-LANE"]} · excluded {cnt["EXCLUDED"]} · ZH4-03 covered {cnt["COVERED"]}) |',
 f'| Parked (below-bar / unlocated / watch / trigger / P-class) | **{parked}** |',
 f'| **OPEN** (actionable residual) | **{open_n}** |', '',
 'No new Tier 1/2 finding was created; the existing three CRITICAL and four HIGH findings stand. The residual value is in the OPEN list below.',
 '',
 f'*Counting note: the {n_total} named entries are represented by {len(ROWS)} rows/groups (ranked rows + named prose/negative leads, including prior-corpus exclusion lists and dead-end classes). The full per-name table is `analysis/ALL-ROWS.md`; grouped rows carry the number of names they represent.*', '',
 '## OPEN list — ranked by live funds × plausibility', '',
 '| # | Target | Chain | Live funds (est) | Plausibility / confidence | Path | Next check |', '|---|---|---|---|---|---|---|']
for o in OPEN_META:
    readme.append(f"| {o['rank']} | **{esc(o['target'])}** | {esc(o['chain'])} | {esc(o['funds'])} | {o['plaus']} / {o['conf']} | {esc(o['path'])} | {esc(o['next'])} |")
readme += ['',
 '### OPEN detail — addresses and blockers', '']
for o in OPEN_META:
    readme += [f"**{o['rank']}. {o['target']}** — {o['chain']}", '',
               f"- Live funds: {o['funds']}",
               f"- Addresses: `{o['addr']}`",
               f"- Path: {o['path']}",
               f"- Confidence: {o['conf']} · plausibility: {o['plaus']}",
               f"- Next check: {o['next']}", '']

readme += ['## Specific rows requested', '',
 '| Row | Disposition |', '|---|---|',
 '| **Derive V3** ($185M) | **CLOSED-in-lane** — zk-proven withdrawal Outbox, permissioned `batchSubmitter`, owner can rotate roots/vkey, global bucket cap ~$2M @ ~$1M/hr. No E-U path at recon depth; risk lives in the zk/verification layer (r1:11, top-5 #3). Watch, not actionable. |',
 '| **Flex** ($1.9M) | **OPEN (low)** — Liquity-v1 fork with custom PriceOracle and exotic collateral feeds; oracle/redemption math unread. |',
 '| **Alchemix V3** ($40.6M) | **OPEN (low-med)** — fresh VaultV2 ERC-4626; donation/first-redeemer/harvest share math unread. |',
 '| **Curve LlamaLend V2** ($42.1M) | **OPEN (low)** — fresh markets/new oracles; soft-liquidation/partial-repay edge unread. |',
 '| **Morpho Midnight** ($8.6M) | **PARKED** — immutable, Morpho-audited, no concrete path; watch market config. |',
 '| **JPYdf** ($849k) | **OPEN (low-med)** — public `receiveFromStrategy`/`claim`; shortfall/backstop/redeem-queue accounting unread. |',
 '| **Qualia / BaiBai / Nullmask / Tacit** | **PARKED** — contracts not located (DL-only leads). |',
 '| **DeepSwap** ($78.7k) | **OPEN (low)** — Raydium cp-swap fork; program diff/fee-recipient auth unread. |',
 '| **Motoswap / VampChef** ($55.6k) | **OPEN (low)** — proxied MasterChef; `lpSupply`/`emergencyWithdraw` unread. |',
 '| **shibbex / dogswap Shibarium pools** | **COVERED** by ZH4-03 deep-dive in flight; not deep-dived here. |',
 '| **Metronome msUSD** | **CLOSED-in-lane** — swap active but 10% fee vs ~10% market discount ⇒ −9.0% round trip; no liquidatable positions; watch 9–11% collateral drop. |',
 '| **Fedz FUSD** | **PARKED** — redemption restricted to Fedz-NFT holders. |',
 '| **USDB** | **PARKED** — ~1% bridge-exit edge, below bar. |',
 '| **satUSD** | **PARKED** — 0.62% discount, below bar / conversion path unscanned. |',
 '| **BEND** | **CLOSED-in-lane** — 0 accounts HF<1 with collateral; 285 positions scanned; keepers active. |',
 '| **Colend** | **CLOSED-in-lane** — $0 borrowed. |',
 '| **Klend** | **CLOSED-in-lane** — dead/parked domain; DL entry BSC/OKExChain $0; no live Kaia venue. |',
 '| **HyperEVM Morpho kHYPE** | **PARKED watch** — HF 1.0042; $356k conditional; not liquidatable today. |',
 '| **Gimo st0G** | **PARKED** — ~$3.5M plausible, mint/updateMinter gated, exit liquidity ~$1.1k. |',
 '| **CL8Y** | **CLOSED-in-lane** — identified as CeramicLiberty.com memecoin; both 0x addresses are EOAs (126.7 ETH + 0.03 ETH), no contract surface; Oct-15 BSC incident/recovery notice. |', '',
 '## “Contracts not located” — resolved', '',
 '| Target | Result |', '|---|---|',
 '| **MoreMarkets.xyz** ($467k DL) | **PARKED.** Located the RLUSD vault `0xb962fd1aBd9A365140493Bd499AcF1eC0AcfF040`; `totalAssets()` = **30.68 RLUSD**. The $432k Ethereum TVL is the market value of Midas hyperETH/BTC/USD tokens (data-feed × supply), not protocol custody. Flare fXRP supply 16,579 (6dp). No protocol pot. |',
 '| **zkSwap V2** ($533k) | **OPEN (low).** Factory `0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d` (zkSync Era), 48 pairs; pair0 `0xa55e...` holds 8,926 USDC + 3.74 WETH. Pools are unverified; UniV2 fork. |',
 '| **MUFEX** ($276k DL) | **PARKED.** Three vault contracts (`0x763ecd...`, `0x16BEDB...`, `0x60b4B5...`) across Arb/Polygon/Mantle/BSC; live USDT ≈ **$6.5k** (1,766 Arb + 3,234 Poly + 1,486 Mantle + ~0.3 BSC). DL TVL is stale. |',
 '| **Lendle** ($176k) | **PARKED.** 11 reserves; aToken cash ≈ **$174.2k**; variable-debt ≈ **$13k**; all markets populated (no empty-market donation); Aave-v2 fork, no concrete path. |',
 '| **xDollar** ($161k) | **CLOSED-in-lane.** IoTeX trove managers: 28 troves, 143,885 XUSD debt, 3.05M WIOTX collateral ≈ **$11.7k** ⇒ ~8% TCR. Insolvent; no extraction. |',
 '| **Ronin deprecated staking manager** `0x8Bd81a19420bAd681B7bfc20E703EBd8e253782D` ($158.8k) | **CLOSED-in-lane.** 755,974.8 RON + 101,474.7 AXS (~$157k); impl `0x9b532621...` exposes only admin `withdrawEther`/`withdrawToken` (revert for a random caller) and reward-accounting functions; no user unstake/exit. P/S class. |', '',
 '## Disposition method', '',
 '- Enumerated every ranked table row in `wave1/r1–r7` and `wave2/d2a–d2d`; then named prose leads, “dead ends / notable negatives”, “also-ran”, watchlists, and “honest gaps”.',
 '- Mapped each to: FINDING (README Tier 1/2), LOW (README Tier 3), CLOSED-README, CLOSED-LANE (negative verdict in the working file, cited), EXCLUDED (prior corpus/not a target), PARKED (below-bar/unlocated/watch/trigger/P-class), OPEN.',
 '- For the six “contracts not located” targets: pulled DefiLlama adapters/registries, located contracts, and performed live `eth_call`/`balanceOf`/storage reads at the block numbers in `summary.json` (public RPCs only).',
 '- Residual leads inside `wave2/v*.md` were checked: the only material one is the Beacon-proxy module, which v15 closes at $0 E-U ($423.9k tripwire); SparkDEX old-plugin residual is closed by v32; Rujira off-hash pair is $4.1k; Exponent/Tessera residuals are LOW with $0 demonstrated.', '',
 '## Files', '',
 '- `analysis/ALL-ROWS.md` — full disposition table (all lanes, all named leads).',
 '- `analysis/r1.md` … `analysis/d2d.md` — per-lane enumeration with citations.',
 '- `analysis/v-residuals.md` — residual leads inside the verification files.',
 '- `analysis/rows.py` — machine-readable enumeration.',
 '- `summary.json` — counts, OPEN list, specific-row verdicts, live block numbers.',
 '- `ci/check.py`, `ci/run.sh`, `ci-out/` — CI validation + live-funds re-reads.', '',
 '## CI', '',
 '- Runs: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081911266** (final, success) and https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081800492 (first pass, success).',
 '- The job re-computes the counts from `analysis/rows.py`, compares them to `summary.json`, scans the folder for keyed-URL/secret patterns (0 hits), and re-reads the OPEN-list funds at public RPCs. Results: `ci-out/validation.json`, `ci-out/live_checks.json`; copied artifacts in `ci-artifacts/result-residual-recon/`.', '',
 '## Caveats', '',
 '- OPEN is a triage label, not a proven bug. Confidence/plausibility are explicit.',
 '- Point-in-time reads (2026-10-18); re-check before acting.',
 '- Zappy contradiction: r7 on-chain reads show ~$90k; d2d L7 found the domain dead. README Tier 3 #8 follows the on-chain evidence; verify troves before any action.',
 '- The zkSync vault may be a CEX/omnibus, not a protocol; that is the main blocker for OPEN #2.',
 '- Nothing here is an instruction to transact; interacting with any listed contract may be illegal in the reader’s jurisdiction.']
with open(os.path.join(BASE,'README.md'),'w') as f: f.write('\n'.join(readme))

# ---- v-residuals ----
vlines = ['# Residual leads inside wave2/v*.md (beyond each file’s main target)', '',
 '| File | Residual lead | Disposition |', '|---|---|---|',
 '| v15-7702module | Beacon-proxy module `0x535023ed` — 481 live delegators, 173.70 ETH (~$423.9k) + tokens | **CLOSED-LANE (not E-U)** — all real fund movers gate `msg.sender == address(this)`; wave-1 eth_call success was the empty fallback. Tripwire on beacon upgrade. |',
 '| v26/v32 SparkDEX | ~150 older V4 pools with unverified plugin impl `0x893388ba` | **CLOSED-LANE** — v32 byte-diff/fork: legacy set ≈$48.8k, $0 E-U; no residual ≥$1k. |',
 '| v27 Rujira | Off-hash FIN pair (code 194, $4.1k) | **CLOSED-LANE** — below bar; pre-v2.2.2 ancestry but no exploit recipe. |',
 '| v19 SyncSwap | Excess-attribution primitive (`deposit(token,to)` can claim unattributed balance) | **CLOSED-LANE** — live excess only in worthless spam tokens; native excess not claimable; 2.2M+ USDC flow swept block-by-block. |',
 '| v29 Exponent/Tessera | Vault `initialize_vault` permissionless + ADV-31 default-mint TokenEntry; Tessera swap rounding/pool↔quote binding | **LOW / not fully closed** — demonstrated theft from existing vaults $0; scam-vector only (victim must deposit into attacker-made vault). |',
 '| v12 Decibel | Stale DPV-share price (600s) as collateral | **LOW / watch** — live exposure 38.2k shares (~$41.1k); max realistic $10–12k on >10% NAV crash inside refresh window; not E-U today. |',
 '| v9 Crystal | `slot0` router scratchpad | **CLOSED-LANE** — slot0=0 for all 31 assets; function never used; no 2-tx deposit pattern. |',
 '| v36 Haedal | vault_incentive forwarding; cetus_clmm loss path; keeper ratchet | **CLOSED-LANE** — P/keeper-gated; no live funds at direct risk; residual edges for a future pass. |',
 '| v34 SundaeSwap | 3 of 14 validators lack public source (governance/treasury/fee_constraint) | **CLOSED-LANE / LOW residual** — cannot violate pool-level invariants; no observed flaw. |',
 '| v4/v4b RealT | Yam offer exit / incumbent relationship | **CLOSED-README (ZH4-07)** — whitelist + ~$0 exit; true unprivileged net $0. |',
 '| v2 BeraFarm | post-incident unverified impls | **FINDING (ZH4-06)** — monitor only. |',
 '| v13 Faiyah | pool deficits / 2027 pot | **FINDING (ZH4-05)** — H-O first-mover; not E-U. |', '',
 'All other v*.md residual notes are P-class, H-O, or below-bar; the main target verdicts are already in the README Tier/CLOSED lists.']
with open(os.path.join(AN,'v-residuals.md'),'w') as f: f.write('\n'.join(vlines))

print('counts', json.dumps(summary['counts'], indent=2))
print('lanes', {k:dict(v) for k,v in lane_cnt.items()})
