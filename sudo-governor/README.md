# P7-LOW-7 — SudoGovernor (sudoswap DAO): no timelock, no guardian, but an unreachable quorum

**Date:** 2026-10-25 · **Chain:** Ethereum (chain id 1) · **Target:** `0x6853f8865BA8e9FBd9C8CCE3155ce5023fB7EEB0` (`SudoGovernor`)
**Status:** read-only; PoC **fork-verified only**; **no mainnet transaction was ever signed or sent.**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| SudoGovernor `0x6853…EEB0` (holds **14,892,500 SUDO** ≈ $540k notional + **0.016735 ETH** ≈ $39) | **$0** | Quorum = **2,400,000 SUDO**; the **entire live SUDO DEX liquidity is 685,256.88 SUDO (28.55%)**. No CEX listing, no lending market, no way to hold a flash loan across the ~5-day snapshot window. | **HIGH if the token ever gains real depth or a whale/CEX lends 2.4M SUDO** — the governor has **no timelock and no guardian**, so a single quorum-reaching vote executes instantly and irreversibly. |

## 2. Total live extractable now: **$0.00** — confidence: **high**

The capture *mechanism* is real and fork-proven (TEST A). The blocker is purely **acquisition**: the 2.4M SUDO needed to reach quorum cannot be obtained from any live venue, and the prize is illiquid. Both facts are proven on a fork (TEST B, TEST D) and the economics are quantified (TEST C).

---

## 3. The mechanism in exact terms

`SudoGovernor` is an unmodified OpenZeppelin **v4.8** governor:

```solidity
contract SudoGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotesComp {
    constructor(ERC20VotesComp _token)
        Governor("SudoGovernor")
        GovernorSettings(14400 /* 2 days */, 21600 /* 3 days */, 300000e18)
        GovernorVotesComp(_token) {}

    function quorum(uint256) public pure override returns (uint256) { return 2400000e18; }
}
```

- **No `TimelockController`.** `timelock()` reverts. A `Succeeded` proposal is executed by calling the targets directly from `Governor.execute()` — **instant, no delay**.
- **No `GovernorGuardian`.** `guardian()` reverts — **no veto / cancel authority** other than the proposer's own `cancel()`.
- **Block-number clock.** `clock()` reverts; snapshots use `block.number`.
- **Counting:** `support=bravo&quorum=for,abstain`. Quorum counts For+Abstain; an attacker who is the only voter needs exactly the quorum in `For` votes and wins (`For > Against`).
- **Threshold:** 300,000 SUDO delegated is enough to *propose*.

⇒ Anyone holding ≥ 2,400,000 SUDO delegated at the snapshot can propose `SUDO.transfer(attacker, 14_892_500e18)`, wait out `votingDelay` (14,400 blocks ≈ 2 d) + `votingPeriod` (21,600 blocks ≈ 3 d), and execute. **TEST A proves this end-to-end** (a funded attacker sweeps the governor's whole SUDO balance; anyone may even be the executor).

## 4. Live-state assessment (block **26271639**, RPC `https://ethereum-rpc.publicnode.com`)

### Governor `0x6853f8865BA8e9FBd9C8CCE3155ce5023fB7EEB0`
| Call | Value |
|---|---|
| `name()` | `SudoGovernor` |
| `token()` | `0x3446Dd70B2D52A6Bf4a5a192D9b0A161295aB7F9` (SUDO) |
| `votingDelay()` / `votingPeriod()` | `14400` / `21600` (blocks) |
| `proposalThreshold()` | `300000000000000000000000` (300k SUDO) |
| `quorum(0)` | `2400000000000000000000000` (2.4M SUDO, hardcoded) |
| `COUNTING_MODE()` | `support=bravo&quorum=for,abstain` |
| `timelock()` | **revert** (no timelock) |
| `guardian()` | **revert** (no guardian) |
| `clock()` | **revert** (block-number clock) |
| `balanceOf(SUDO)` | `14892500000000000000000000` (**14,892,500 SUDO**) |
| ETH balance | `16735161959695215` wei (0.016735 ETH ≈ $39) |

### SUDO token `0x3446Dd70B2D52A6Bf4a5a192D9b0A161295aB7F9` (`SudoToken`, solc 0.8.14)
| Call | Value | Note |
|---|---|---|
| `totalSupply()` | `58056418773617226618580000` (58,056,418.77 SUDO) | quorum = 4.13% of supply |
| `owner()` | `0x0000…0000` | **`mint()` is `onlyOwner` → permanently uncallable** (no inflation route) |
| `transferEnabled()` | `true` | transfers open (mechanism not blocked by the transfer gate) |
| `delegates(governor)` | `0x0000…0000` | governor's own 14.89M SUDO is **undelegated → 0 votes** |
| `getPriorVotes(governor, 26271638)` | `0` | confirms the governor cannot self-vote its own holdings |

### Live SUDO liquidity (all venues, block 26271639)
| Venue | Address | SUDO | WETH |
|---|---|---|---|
| UniV2 SUDO/WETH | `0x1533F61FAcb7cc3A632B12ea9f55D3FBb57309E0` | 214,675.018 | 3.33765 |
| UniV3 1% SUDO/WETH | `0x68d01EfdFbe5C0eeBE3b19B571B18Ae6D6EE16FC` | 470,521.123 | 1.17797 |
| UniV3 0.3% SUDO/WETH | `0x1aB172cb7eC893Eb990BfeE8f83B49d69Aa6A6CC` | 308.31 | ~0 |
| UniV3 1% SUDO/USDC | `0xDF709525C5880322422A10E045C1E0fA82cDa1B2` | 59,403.66 | — |
| UniV3 1% SUDO/XMON | `0x9E4908114C5e8b23F828C8De965932EC10f2E9D3` | 1.03 | — |
| **Total** | | **685,256.88 SUDO** | ≈ 4.52 WETH |

- Sushi V2 `getPair(SUDO, WETH)` = `0x0` (no pair). UniV3 fee tiers 0.05%/0.5% have no SUDO/WETH pool.
- CoinGecko tickers: **only** Uniswap V2 and V3, 24 h volume ≈ $150 + $30 — **no CEX**.
- Prices (DefiLlama, 2026-10-25): SUDO `$0.036293`, WETH `$2349.99`.

## 5. What an attacker can / cannot do

**Can (mechanism):** if they already hold ≥ 2.4M SUDO delegated at the snapshot, they propose → vote → execute and receive the governor's 14,892,500 SUDO. Cost: ~5 days of holding + gas. No delay, no veto. **Proven in TEST A.**

**Cannot (acquisition) — the decisive negative:**
1. **Buy it.** Every SUDO pool on-chain holds 685,256.88 SUDO total = **28.55% of quorum**. Buying *all* of it (paying an unbounded WETH price) still falls ~1.71M SUDO short. **Proven in TEST B.**
2. **Borrow it.** No lending market lists SUDO; no CEX to borrow from.
3. **Flash-loan it.** Votes are checkpointed at `block.number + votingDelay` and voting opens only after 14,400 blocks; the position must survive ~5 days. A single-block flash loan cannot vote.
4. **Use the governor's own tokens.** They are undelegated (`delegates(governor) = 0x0`) and the governor exposes no path to delegate them without first passing a proposal (circular).
5. **Inflate supply.** `SUDO.mint()` is `onlyOwner` and `owner() = 0x0`.

**End-to-end negative (TEST D):** an attacker seeded with **100% of all on-chain SUDO liquidity** (685,256.88 SUDO) *can* propose (clears the 300k threshold) but the proposal is **Defeated** — quorum never reached, `execute()` reverts.

## 6. Economics — even the prize is tiny (TEST C)

Selling the governor's 14,892,500 SUDO into the UniV2 pool (constant product, X = 214,675 SUDO, Y = 3.33765 WETH):

```
WETH out = Y·Q/(X+Q) = 3.33765 · 14,892,500 / (214,675 + 14,892,500) = 3.2902 WETH ≈ $7,744
```

Adding the UniV3 pool's WETH (1.17797 WETH), the **hard ceiling of the whole prize is the WETH sitting in both pools ≈ $10,628** (plus 0.0167 ETH ≈ $39 of native). To actually capture it you would have to *own* 2.4M SUDO — which costs far more than $10.6k and is, in any case, impossible to acquire.

## 7. PoC / fork-verification

Project: `poc/` (Foundry, solc 0.8.24, vendored `lib/forge-std`). Fork via
`vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))))`.
**No `forge install`, no secrets, no keyed RPC URLs in the repo.**

| Test | What it proves | Result |
|---|---|---|
| `test_A_mechanism_noTimelock_instantDrain` | No timelock/guardian; a quorum-holding attacker proposes, votes, and **sweeps the governor's 14,892,500 SUDO** in one permissionless execute | **PASS** (gas 801,005) |
| `test_B_maxAcquirable_farBelowQuorum` | Max SUDO acquirable from **all** live pools = **685,256.88 SUDO** < 2,400,000 quorum (28.55%) | **PASS** (gas 71,932) |
| `test_C_prize_isIlliquid` | Dumping 14.89M SUDO into UniV2 = 3.2902 WETH (~$7,744); all-pool WETH ceiling ~$10,628 | **PASS** (gas 48,537) |
| `test_D_attackerWithAllLiquidity_isDefeated` | Attacker holding 100% of on-chain SUDO liquidity still reaches no quorum → proposal **Defeated**, `execute()` reverts | **PASS** (gas 671,336) |

**4 passed / 4 total.** CI (GitHub Actions, public repo `artsbykriss/ca-zombie-ci`, fork block 26271850):
**https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40228023680** (also [40227226605](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40227226605)).

## 8. Verdict & residual / latent risk

**Verdict:** E-U = **$0** (high confidence). The instant-execute governance mechanism is genuine and would be critical in a liquid token, but SudoGovernor is **un-capturable today**: the quorum is 3.5× larger than every SUDO pool combined, there is no CEX/lending depth, and the extractable prize is illiquid (~$10.6k of WETH).

**Residual/latent risk — HIGH:**
- The governor has **no timelock and no guardian**. If SUDO ever gains meaningful DEX depth, gets a CEX listing, or a whale/team wallet is willing to lend/delegate 2.4M SUDO, the whole 14.89M SUDO becomes sweepable in a single vote.
- Quorum/threshold are **absolute constants** — they do not scale with supply, so a falling price/supply does not help; but a *rising* price makes the attack cheaper in USD.
- Not in scope of this finding: the governor's execution authority over any external protocol SUDO governance controls (none observed as a target of value here).

**Blockers (why closed):** acquisition ceiling (685,256.88 SUDO), no CEX/lending market, snapshot/flash-loan incompatibility, undelegated governor holdings, disabled mint.

## 9. Methodology, sources, caveats, files

**Method:** verified source (Etherscan V2) + full flatten review of the deployed `SudoGovernor`; on-chain reads of every param/role/balance at explicit block **26271639**; enumeration of all SUDO venues via UniV2/UniV3 factories + GeckoTerminal + CoinGecko; fork PoC on GitHub Actions (4 tests); DefiLlama prices.

**Caveats / limitations:**
- PoC is **fork-only**; no mainnet state was touched. TEST A grants the attacker 2.4M SUDO via `vm.deal` to isolate the *mechanism* (the acquisition impossibility is separately proven in B/D).
- Pool reserves drift; verified at block 26271639 and reproduced at CI fork block 26271850 (identical to the wei). Even a 3× change in liquidity leaves it below quorum.
- Illiquidity is assessed via CoinGecko (only Uni V2/V3) and absence of any lending market; a private OTC block trade is out of scope but would be the only conceivable acquisition route.
- TEST C uses ETH = $2353.68; DefiLlama spot at the time was $2349.99 (immaterial).

**Files index:**
```
sudo-governor/
├── README.md                     # this report
├── summary.json                  # machine-readable summary (§7 schema)
├── analysis/
│   ├── gov.sol                   # verified flattened source of SudoGovernor
│   ├── gov.manifest              # compiler / proxy metadata
│   └── evidence.json             # raw on-chain reads + pool reserves + economics
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/            # vendored
│   ├── src/Interfaces.sol
│   └── test/SudoGovernor.t.sol   # TEST A/B/C/D
├── ci-log.txt                    # CI run log (run 40227226605)
└── ci-artifacts/                 # CI artifacts
```
