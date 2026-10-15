# 1Hive Aragon DAO (Gnosis) — capture/extraction analysis

**Date:** 2026-10-15 · **Chain:** Gnosis (id 100) · **Status:** read-only; all state read at pinned block **48,767,111** unless noted; no transactions sent; economics modelled, not fork-executed.

**Scope:** can an external, unprivileged attacker (no keys, no roles, no insider access) extract HNY from the classic 1Hive Aragon DAO, and what does it net out at? All raw dumps in `1hive-*.json` (same folder).

---

## 0. TL;DR

| Path | Who | Net to a fresh attacker | Confidence |
|---|---|---|---|
| **ConvictionVoting proposal** → `Agent.transfer` (no vote needed; ANY can create proposals) | anyone | **single round +$0.8k…+$2.3k** (best modelled: **+$2,115** for R=3,000 HNY, S≈3,710 HNY, ~7 days, $5.4k capital) | medium |
| **DisputableVoting vote** → `Agent.execute` (drain whole vault; ANY can create votes) | anyone with 7,543+ HNY at one block | **+$6,442** (needs ~$22.3k capital for 1 block + 6 days waiting; challengeable) | medium |
| Cumulative (patient attacker, ~$10k capital, several CV rounds) | anyone | **≈ +$5.2k…+$6.5k** until the DEX quote inventory is exhausted | medium |
| Conservative (only hard-currency exit pools: WXDAI/WETH/WBTC/EURe/USDT/USDC) | anyone | single CV round **+$1.6k**; whole-vault dump ceiling **+$3.9k**; vote path infeasible to acquire | medium |

**E-U ≈ $2.1k (single best ConvictionVoting round) to $6.4k (full-drain vote with ~$22k capital); hard-currency-only floor ~$1.6k; cumulative pool-limited ceiling ~$6.5k.** The vault holds **21,398.66 HNY (~$20.9k at spot)** but only ~**$6.5k–$9.8k** of HNY is realistically convertible to cash anywhere on Gnosis — the thin DEX depth, not the DAO's permissions, is the binding constraint.

**H-O (holder-only):** Agreement staking pool 243.08 HNY (~$238 paper; withdrawable user stakes). · **P:** full governance control (roles below) over the 21,398.66 HNY vault + HNY minting capability via TM upgrade — paper $20,947 but cash-realizable only ~$6.5k. · **S:** none.

No privileged key is required for either live path. Both paths ultimately **pay out in HNY**, not xDAI.

---

## 1. The DAO, exhaustively enumerated

Kernel (DAO) `0x8ccbeab14b5ac4a431fffc39f4bec4089020a155`, impl `0x336ebb4def4da4fad6936874b8c952e800024653` (Kernel). Full `SetApp` history retrieved with `eth_getLogs` (full range, `rpc.gnosischain.com`), namespaces `base=0xf1f3eb40…` / `app=0xd6f028ca0e…`. Apps (verified by `kernel()`/`appId()` on each proxy and by the ACL's `SetPermission` history):

| appId | App | Proxy (instance) | Impl (base) |
|---|---|---|---|
| 0x3b4bf6bf… | Kernel | 0x8ccbeab1… (self) | 0x336ebb4d… |
| 0xe3262375… | ACL | 0xbc4fb635636b81e60a4e356c4dceb53cac507d03 | 0x4499948D… |
| 0xddbcfd56… | EVMScriptRegistry | 0x0d33a5ca7149d24628efd43564f577ced33dd34b | 0xD4013804… |
| 0x9ac98dc5… | **Agent (vault)** | **0x4ba7362F9189572CbB1216819a45aba0d0B2D1CB** | 0xA6aD366b… |
| 0x705b5084… | **DisputableVoting** (1Hive fork) | **0xfbd0b2726070a9d6aff6d7216c9e9340eae68b2a** | 0x4fdC6f06… |
| 0xbe6744fc… | BrightIdRegister | 0x7714eb44754cb9db6d65b61f3352df12600dc593 | 0x47427E94… |
| 0xa2a1b99c… | **HookedTokenManager** (HNY controller) | **0xed062e26c8f41a9088d060156edc7fc6c17d5825** | 0xbbA6F561… (upgraded ×2) |
| 0xb4534ca1… | Issuance | 0x783da66eea5a93f46f386806fce49ce18937f861 | 0xb0200960… |
| 0xca60629a… | **ConvictionVoting** | **0x0b21081c6f8b1990f53fc76279cc41ba22d7afe2** | 0x4E189151… |
| 0x34c62f3a… | Agreement | 0x59a15718992a42082ab2306bc6cbd662958a178c | 0xE2B44F20… |
| 0xa9018c6b… | Superfluid | 0x602a48a53a425521c9923708d277dc7430e3c749 | 0xb1c83cDe… |

Deploy block **14,861,344** (all core apps; Agent/vault proxy at logIndex 0x1e); all app impls are Blockscout-verified and match the deployed proxies. `1hive-kernel-apps.json` has the raw SetApp list; `1hive-acl.json` the raw SetPermission list.

**Note:** none of the standard Aragon appIds (voting 0x9fa3927f…, token-manager 0x6b20a301…, vault 0x7e852e0f…, finance 0xbf849115…) are registered on this kernel — the DAO uses the 1Hive suite (DisputableVoting, ConvictionVoting, HookedTokenManager, Issuance, Agreement, BrightId, Superfluid).

### 1.1 Who can move the vault (`hasPermission`, live @48,767,111)

| Permission | Holder(s) | Live |
|---|---|---|
| `Agent.TRANSFER_ROLE` | **ConvictionVoting** (0x0b21081c…) [granted b14,861,447], **Superfluid** (0x602a48a5…) [b31,213,417] | **true / true** |
| `Agent.EXECUTE_ROLE` | **DisputableVoting** [b14,861,344] | **true** |
| `Agent.RUN_SCRIPT_ROLE` | DisputableVoting | **true** |
| `Agent.SAFE_EXECUTE_ROLE` | Superfluid | true |
| ANY-entity grants on Agent | none | false |
| `kernel.APP_MANAGER_ROLE` | DisputableVoting only (old factory 0xf60cd4f8 revoked) | true |
| `ACL.CREATE_PERMISSIONS_ROLE` | DisputableVoting only | true |
| `ConvictionVoting.CREATE_PROPOSALS_ROLE` | **ANY entity** | **true** |
| `DisputableVoting.CREATE_VOTES_ROLE` | **ANY entity** | **true** |
| `CHALLENGE_ROLE` (both Voting & CV) | **ANY entity** | true |
| `HookedTokenManager.MINT_ROLE` | Issuance app only | true |
| `Issuance.MINT_ROLE` / `ISSUE_ROLE` / `ASSIGN_ROLE` | **nobody** (ANY false, Voting false) | **mint path dead** |
| `CV.PAUSE_CONTRACT_ROLE` | external DAO's Voting app 0x878759bd… (kernel 0x31167fc6…) | true (circuit-breaker) |

**Practical consequence:** the only unprivileged actors that can make the Agent move HNY are (a) the **ConvictionVoting app** (via its `executeProposal`, which is callable by anyone and transfers to a proposal beneficiary) and (b) the **DisputableVoting app** (via a passed vote executing an EVM script on the Agent). The Superfluid app's TRANSFER_ROLE is unusable for HNY: `withdraw()` requires `isValidSuperToken()` (`getHost()` static probe), whose call on HNY hits the MiniMe fallback → `HookedTokenManager.proxyPayment()` returns **false** → require fails (deployed source verified).

### 1.2 DAO state
- Vault HNY balance @48,767,111: **21,398.659784944634936554 HNY**; xDAI: 0. No other meaningful tokens (WXDAI/WETH/WBTC/COW/GNO/HNYx = 0; Blockscout shows only dust/spam: RXDAI 100, ESR 33). All 223 `VaultTransfer` events ever emitted were HNY (53,147.58 HNY out over the DAO's life). Historical note: Dec 2023–Nov 2024 the DAO converted ~10,500 HNY into **HNYx** ("Super Honey" SuperToken `0xc0712524B39323eb2437E69226b261d928629dC8`, underlying = HNY, supply 680.58) through the Superfluid app/`syncSupertoken` proxy for contributor streams; the vault's HNYx balance is now 0, so there is no residual wrapped-HNY pool in the vault.
- HNY (`0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9`, MiniMe, 18 dec): totalSupply **75,429.939563086058534633**, controller = HookedTokenManager. Price **$0.978918** (DefiLlama, 2026-10-15); DEX spot 0.9782 (WXDAI pool reserves).
- No global pause: `CV.contractPaused()=false`. No DAO-wide pause exists.
- Last governance activity: DisputableVoting — 21 votes ever; last StartVote = **vote 20, block 32,931,139 (2024-03-14)**; last executed vote = **vote 19 (2023-11-22)**. ConvictionVoting — 214 proposals; last extraction = **proposal 213 executed 2026-06-26** (1,000 HNY to 0x625236038836CecC532664915BD0399647E7826b, block 46,889,544).

---

## 2. Path A — ConvictionVoting (no vote needed, extract up to 20 % of vault per proposal)

### 2.1 Mechanics (deployed source verified, block 14,861,447 init)
- `addProposal(string,bytes,uint256,bool,address)` — `auth(CREATE_PROPOSALS_ROLE)` = **ANY**. Amount must satisfy `requestedAmount < 0.2 × vaultBalance` (`CV_AMOUNT_OVER_MAX_RATIO`).
- `stakeToProposal(pid, amount)` — permissionless. **Staking does not transfer tokens**: `_stake()` only requires `balanceOf(staker) ≥ totalVoterStake[staker] + amount`; the HNY stays in the attacker's wallet. The TokenManager hook force-withdraws the stake only if the holder moves HNY out.
- `executeProposal(pid)` — **callable by anyone**. Requires accrued conviction > threshold; then calls `vault.transfer(requestToken=HNY, beneficiary, requestedAmount)` (Agent TRANSFER_ROLE → CV app).
- Threshold (from source): `threshold = 49.75124 × T / (0.2 − R/F)²` in conviction units, with `T = max(totalStaked, 20 %×HNY supply)` (`minThresholdStakePercentage = 2e17`), `F` = live vault HNY. Verified against the on-chain threshold of proposal 213 (block 46,889,544): predicted 3.195e25 vs observed 3.1950241e25 ✓.
- Conviction accrues as `C(t) = S×49,751.24×(1−a^t)`, `a = 0.9999799/block`; so the minimum stake to *ever* pass is **S_min(R) = 10⁻³·T/(0.2−R/F)²**, and the hold time to reach it with `S=ρ·S_min` is `t = ln(ρ/(ρ−1))/2.01e-5` blocks (ρ=1.1 → ~6.9 days; ρ=2 → ~2.0 days at 5 s blocks). **Flash loans cannot work** (multi-day hold; selling the stake auto-withdraws it).
- Before creating any action, the attacker must `Agreement.sign(1)` (permissionless, `AGR_SIGNER_MUST_SIGN` otherwise — verified by live `eth_call`) and have ≥0.1 HNY lockable in the HNY staking pool `0x0e25b918c9fb2fea5d42011d1f4b9f8c61b453e7` (`stake()`/`allowManager()` are permissionless; only 0.1 HNY is locked by the Agreement per action).

### 2.2 Permissionless refill first
`Issuance.executeAdjustment()` (`0x783da66e…`) has **no access control** in the deployed source and is used in practice by an unprivileged EOA (`0x60C1a749C390d2E18Ff84EBc17c74a28fac0c6C9`, block 46,503,506, tx 0x5a09bcd8…). Simulated now: it mints **+1,230.32 HNY to the vault** (targetRatio=30 % of supply; last adjustment 2026-06-03), raising `F` to **22,628.98** and `T` to `0.2×76,660.26 = 15,332.05`. Max request per proposal = **4,525.80 HNY**.

### 2.3 Economics (constant-product model over all HNY pools, 0.3 % fee, 2026-10-15)
`S=1.1×S_min` (~6.9 day hold; the S round trip — buy then sell back — costs only ~0.4 % because the pools are restored):

| R requested (HNY) | S_min | S used | capital ≈ | loot sale (realistic) | **net** |
|---|---|---|---|---|---|
| 1,000 | 631.6 | 694.7 | $724 | $844 | **+$840** |
| 1,500 | 857.5 | 943.3 | $1,006 | $1,209 | **+$1,204** |
| 2,000 | 1,230.6 | 1,353.7 | $1,503 | $1,545 | **+$1,536** |
| 2,500 | 1,913.1 | 2,104.4 | $2,526 | $1,854 | **+$1,841** |
| 3,000 | 3,372.4 | 3,709.6 | $5,382 | $2,141 | **+$2,115** |
| 3,500 | 7,461.2 | 8,207.3 | $28,687 | $2,407 | +$2,322 |
| 4,000 | 28,398.5 | — | — | — | infeasible (S > DEX inventory) |

("realistic" = quote tokens converted at realisation weights: WXDAI/WETH/WBTC/EURe/USDT ≈1.0, LINK 0.95, FOX 0.90, BREAD 0.88, AGVE 0.85, BRIGHT/GIV 0.40, UNI 0.35, dead 0.02–0.30; WATER has no market at all. Restricting the exit to hard-currency pools only: net +$806/+$1,116/+$1,381/+$1,608 for R=1,000–2,500.)

The **S capital is reusable** across rounds (it never leaves the wallet) — a patient attacker needs one ~$10k position and can repeat proposals until the DEX quote inventory is exhausted: cumulative recovery converges to ~**$5.2k–$6.5k** for dumping 9k–21k HNY.

**Precedent:** this channel was actively used — **53,147.58 HNY left the vault across 223 `VaultTransfer` events (all HNY)**, top recipients 0xc6c2E9EF… (14,801.89), 0x14d92832… (8,488), 0x1b8c7f06… (2,560.22), 0x6036DBd7… (2,132); latest 2026-06-26 (1,000 HNY). Those operators presumably already held HNY (zero acquisition cost); a fresh attacker pays the market round trip.

---

## 3. Path B — DisputableVoting vote (drain the entire vault in one action)

DisputableVoting `0xfbd0b272…`, setting 0 (live, `getSetting(0)`): **voteTime 432,000 s (5 d), support 50 %, quorum 10 %, delegatedVotingPeriod 2 d, quietEnding 1 d/12 h, executionDelay 1 d**. `newVote(bytes executionScript, bytes context)` is `auth(CREATE_VOTES_ROLE)` = **ANY**. Snapshot = creation block − 1; voting power = `HNY.balanceOfAt(voter, snapshotBlock)`; `totalPower` = `HNY.totalSupplyAt(snapshot)` (verified: vote 20's totalPower 51,571 = totalSupplyAt(32,931,138)).

**Capture condition:** with no opposition, yea must be **> 10 % of totalSupply = 7,543.0 HNY** at one block. Because the snapshot is taken at block N−1, the attacker need only **hold 7,543 HNY across one block** — then create the vote (block N) and sell immediately (the HNY can even be sold in the same block as `newVote`; a same-block borrow/repay *at* block N−1 would not register, because balance checkpoints record the end-of-block balance, and no HNY lender exists to borrow from anyway — flash loans are not usable here). Conversion is 5 days + 1 day delay (no quiet-ending extension with a single voter), then `executeVote` runs the script → `Agent.execute(HNY, 0, transfer(attacker, 22,628.98e18))` (Voting holds EXECUTE_ROLE ✓).

**Feasibility/economics (modelled):** buy 7,600 HNY from the 16 pools with acquirable quotes (11,408 HNY inventory): **$22,320**; sell back: $22,246 (−$74); dump the 21,398 HNY payout: **$6,515** → **net ≈ +$6,442**. In hard-currency-only terms the buy is impossible (only 4,993 HNY sits in WXDAI/WETH/WBTC/EURe/USDT pools), and the whole-vault dump ceiling is $3,938.

**Gates / killers:** (1) anyone can `challenge` (both apps grant CHALLENGE_ROLE to ANY) — 0.3198 HNY + Celeste arbitration fees — which pauses the vote; a live challenger with a functioning court stops the attack (a 5-day public "send me the treasury" vote is conspicuous). (2) The community can out-vote with ≥7,600 NO (yea/(yea+nay) must be strictly >50%; they hold ~67.8k HNY outside the attacker; the last 2 votes drew only 4.8k–6.8k HNY of votes cast, so turnout is uncertain). (3) If Celeste is dead, a challenge still freezes execution indefinitely.

---

## 4. Market reality — the real bound

Every extraction pays out in HNY. Gnosis HNY liquidity (all 40 GeckoTerminal pools; reserves read on-chain, block 48,767,111):

- ~**13,200 HNY total** in DEX pools (~11,889 in the 20 pools ≥$15 + ~1,310 in BREAD/HNY).
- Quote-side USD: **$4,863** in the 6 hard-currency pools (WXDAI $3,147 + WETH $1,438 split over 2 WXDAI pools + WBTC $134 + EURe $54 + USDT/USDC ~$18); **$12,873** across all 20 pools (paper, incl. illiquid community tokens). Value-weighted after second-hop conversion the quote inventory totals ≈$9.8k, but inventory is not recoverable in full: the pools hold only ~13.2k HNY, so actually dumping 21,398 HNY recovers **$6,515** (realisation-weighted) / $3,938 (hard-currency only).
- **No lending market for HNY:** Aave v3 Gnosis reserves (checked): WETH, wstETH, GNO, USDC, WXDAI, EURe, sDAI, USDC.e, GHO — **HNY absent**. No other Gnosis money market lists HNY. Borrowing/hedging is impossible; leverage cannot span the multi-day CV hold.
- Second-hop depth for junk quotes (WXDAI pairs): FOX $13.2k, BREAD $5.9k, AGVE $4.0k, MIVA $1.6k, xMOON $0.7k, BRIGHT $0.24k, GIV $0.21k, UNI $0.21k, **WATER $0**, MKR $0. This is why the "paper $14k" shrinks to ≈$6.5k realized cash (≈$9.8k value-weighted inventory).

---

## 5. Verdict

| Category | USD (net, fresh unprivileged attacker) | Confidence | Basis |
|---|---|---|---|
| **E-U** | **$2,115 single best CV round** (R=3,000, $5.4k capital, ~7 d) · **$6,442 full-drain vote** ($22.3k capital + 6 d) · cumulative **$5.2k–$6.5k** · hard-currency-only floor **$1.6k** (CV) / $3.9k (vote ceiling) | medium | modelled (constant-product pools + on-chain threshold, verified against historical proposal 213) |
| **H-O** | $238 paper (243.08 HNY user stakes in the Agreement staking pool; withdrawable by their owners) | high | `balanceOf(staking 0x0e25b918…)` @48,767,111 |
| **P** | $20,947 paper (the 21,398.66 HNY vault + unlimited-mint capability via a captured vote + kernel APP_MANAGER → TM upgrade). Cash-realizable still ≤ E-U ceiling. | high (paper) | live ACL matrix |
| **S** | $0 — nothing bricked | high | all apps `hasInitialized`, CV unpaused |

**Exact gates (all open today):** no privileged key is needed. Only: (1) `Agreement.sign(1)` (free), (2) lock 0.1 HNY in staking pool `0x0e25b918…` via `allowManager`+`stake` (permissionless, ~$0.10), (3) capital: `S` ≈ $0.7k–$5.4k (CV path) or $22.3k (vote path), (4) survive the challenge window, (5) accept the exit haircut. There is **no** mint shortcut: `Issuance.mint/issue/assign` have no role holders, TM MINT_ROLE is held only by Issuance.

**What would change the verdict**
- **More exit liquidity** (any real HNY/xDAI market >$50k depth): the full vault (~$20.9k spot) becomes cleanly extractable; E-U → $20k+.
- **An awake community:** a 0.32 HNY challenge pauses any CV proposal or vote (both CHALLENGE_ROLEs are ANY) for 3 days + arbitration; a NO coalition of ≥7,600 HNY kills Path B; one vote can also cancel CV proposals (CANCEL_PROPOSALS_ROLE → DisputableVoting). Community passivity is currently the main reason these paths work.
- **Celeste liveness:** a working court makes challenges decisive (attack EV ≈ −round-trip costs); a dead court makes challenges free denial.
- **HNY price/volatility:** the attacker's profit is HNY-denominated; a >10 % adverse move during the 7-day hold wipes out the single-round net.
- **Race risk:** both paths are public and permissionless — a copycat can front-run the same faucet, and repeated extraction self-destructs the exit liquidity.

**Honest bottom line:** an unprivileged attacker can today convert ~$1–5k of capital into ~$0.8–2.1k of net cash per ConvictionVoting round (or up to ~$6.4k by draining the whole vault with a $22k one-block stake + 6 days), but **cannot realize anything close to the vault's $20.9k spot value** — the entire HNY market's realistically-convertible depth is ~$6.5–9.8k, and the paths are trivially challengeable by any alert community member.

---

## 6. Methodology, caveats, files

- All state via public RPC `https://rpc.gnosischain.com` (full-range `eth_getLogs`), Blockscout `gnosis.blockscout.com/api/v2` for verified sources; DefiLlama + GeckoTerminal for prices/pool list; Aave address-book for the v3 Gnosis Pool.
- Economics: exact reserves for 20 pools (≥$15 USD) from `getReserves()`; constant-product integration with 0.3 % fee, greedy marginal-price routing both ways; S round trip modelled as buy→sellback (pools restored; cost = fees + curve ≈ 0.4 %); payout sold with per-quote realisation weights. This is a model — not fork-executed (parent may fork-verify if desired).
- Caveats: thin pools are racily arbed; quote-token USD values (FOX/AGVE/BREAD) are Honeyswap-implied and can move; challenge/arbitration outcomes not modelled; maximum numbers assume no other extractor races first.
- **Files:** `1hive-aragon.md` (this report) · `1hive-kernel-apps.json` (apps + SetApp history) · `1hive-acl.json` (all 58 SetPermission events + live matrix) · `1hive-state.json` (pinned state, thresholds, Issuance sim) · `1hive-logs.json` (mint history, vault outflows, votes) · `1hive-pools.json` (pool reserves) · `1hive-econ.json` + `1hive-econ-final.json` (economics grids). Raw intermediates: `kernel_setapp_raw.json`, `acl_setperm_raw.json`, `hny_mints_transfer.json`, `agent_vaulttransfers.json`, `voting_startvote.json`, `hny_pools_reserves.json`, `bs_*.json` (verified sources).
- No secrets/keyed URLs written anywhere; all dumps use the public endpoints above.
