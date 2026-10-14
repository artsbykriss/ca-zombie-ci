# Nsure Network (Ethereum) — L2 Phase-2 deep-dive: live extractability

**Date:** 2026-10-14 · **Chain:** Ethereum mainnet (block **26,193,225**) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**

**Mission:** determine rigorously how much an *external, unprivileged* attacker (fresh-attacker standard: no legacy
positions, keys, roles, whitelists) can extract live from Nsure today. An honest "$0, here is the proof" is the
successful outcome if true.

---

## 1. TL;DR

| Target | Live value (unprivileged?) | Why closed / open | Latent risk |
|---|---|---|---|
| **Underwriting** `0x1a66f065…` | **3.3105 WETH ($8,046)** — **P** | `claim()` pays only against an EIP-712 signature from `signer = 0xbb826fb8…` (EOA); `payouts()` needs `operator`, which is **unset (0x0)**; `withdraw()` needs both an internal balance and a signer signature | Owner EOA `0x7023a321…` can `setSigner`/`setOperator` and drain at will; a leaked signer key would make this E-U |
| **Surplus** `0x80e711b2…` | **6.0481 WETH ($14,700)** — **P** | `payouts()` is `onlyOperator` and **`operator == address(0)`** → nobody can call it today; `setOperator` is `onlyOwner` | Single owner EOA can enable payouts with one tx |
| **Treasury** `0xfd0D2853…` | **1.5120 WETH ($3,675)** + 26,000 NSURE — **P** | same signer-gated `claim()`/`withdraw()`; `payouts()` operator unset | same as Underwriting |
| **CapitalStake** `0xB98eD980…` | 16,291,542 NSURE reward pool — **H-O** (stakers only) | `claim(pid)` is permissionless **but** pays only the caller's own accrued rewards; `deposit` needs nETH (mint bricked, see below); `unstake` needs signer sig | pool drips 1.8 NSURE/block; team can rotate signer |
| **CapitalConverter (nETH)** `0xa6b658Ce…` | **$0** (ETH backing already paid out to the team on 2026-10-09) | `convert()` reverts (SafeMath underflow, `smartBalance()==0`); `exit()` pays `value * 0 / totalSupply = 0` | none (drained) |
| **Buy** `0x702aff99…` | ~0 (35 wei WETH) | `buyInsurance()` needs a signer signature (fabricated sig reverts atomically) | signer key |
| **ClaimPurchaseMint** `0x200db99f…` | 145,484 NSURE — **P** | `claim()` needs a signer signature; mint-to-self happens only inside a successful claim | signer key |
| **Nsure token** `0x20945ca1…` | 415,838 NSURE held by the token contract itself — **S** | no sweep/withdraw function exists; `mint` is minter-gated (3 minters) | up to 27.04M NSURE mintable to maxSupply (P) |

**Total live value on-chain (block 26,193,225):** **10.8706 WETH = $26,419.98** (ETH $2,430.41, DefiLlama) plus
**18.748M NSURE** (nominal **$12,436** at the live UniV2 pool price $0.0006633; realizable into that thin pool
≤ ~$6,379 if the entire balance were sold at once).

---

## 2. Total live extractable now

| Category | Amount | USD | Confidence |
|---|---:|---:|---|
| **E-U (external unprivileged)** | **0** | **$0.00** | **high** |
| **H-O (holder-only, self-service)** | 2,218,373 NSURE pending claimable now by the 17 active nETH stakers (plus the 16.29M reward pool streaming at 1.8 NSURE/block) | ~$1,471 nominal / ~$1,322 realizable | high |
| **P (privileged: owner EOA / signer EOA / 3-of-5 Safe)** | 10.8706 WETH + 1.87M NSURE (Underwriting) + 26k NSURE (Treasury) + 145.5k NSURE (ClaimPurchaseMint) + mint rights (27.04M NSURE headroom) | $26,419.98 + ~$1,354 nominal | high |
| **S (stuck, no function moves it)** | 415,838 NSURE inside the Nsure token contract | ~$276 nominal | high |

**Headline: an external unprivileged attacker can extract $0.00 live from Nsure.** Every live WETH path requires a
protocol key (owner EOA `0x7023a321…` or signer EOA `0xbb826fb8…`) or is dead because `operator` was never set
(Surplus/Treasury/Underwriting/CapitalStake). The only permissionless value-moving calls pay the caller's own stake
rewards (`CapitalStake.claim`) or their own (worthless) nETH (`CapitalConverter.exit`).

---

## 3. The protocol and its live state (block 26,193,225)

Nsure Network launched 2020–2021 as a decentralized insurance marketplace ("underwriting pools"). Contracts
(all verified, **non-upgradeable**, compiler 0.6.12):

| Role | Address | Notes |
|---|---|---|
| `CapitalStake` | `0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6` | MasterChef-style staking of **nETH** (pid 0); NSURE reward pool |
| `Underwriting` | `0x1a66f065303299d78693f122c800Ab3dEbE9c966` | receives 50% of premiums; signer-gated claims |
| `Buy` | `0x702aff99b08e8891fc70811174701fb7407b4477` | policy purchases (signer-signed); splits 50/40/10 |
| `Surplus` | `0x80e711b29e46d430ff1553eb2ada670e2a25593c` | 40% of premiums for claims; `payouts` onlyOperator |
| `Treasury` | `0xfd0D28539aeD12477dcba1575eB40fca53969440` | 10% of premiums; signer-gated claims |
| `Nsure` token | `0x20945ca1df56d237fd40036d47e866c7dccd2114` | ERC20 + votes; `mint` onlyMinter; maxSupply 100M |
| `CapitalConverter` (nETH) | `0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84` | ETH ⇄ nETH shares; `payouts` onlyOperator |
| `Product` | `0x06e76c5c53775681f0626600d6266901a03141a8` | product registry (20 active products) |
| `ClaimPurchaseMint` | `0x200db99fe5c0f39688853d4c4d8651648d995b26` | ICO-purchase reward claims (signer-gated) |
| second `Underwriting` | `0x454fd408abb7c3b36b4cf098fe86c9ed388fc477` | orphan, holds $0 |

**Roles (live reads):**

- `owner()` of **all five pools** = **`0x7023a32108539a024ca17afab0f5b90f8770bccd` — a single EOA** (not a multisig).
  It was active on **2026-09-21** (`CapitalStake.setSigner`, tx `0xa05c76d9…`, block 26,025,678) and funded gas
  to the signer EOA.
- `signer()` of Underwriting/Treasury/Buy/ClaimPurchaseMint = **`0xbb826fb86fae53be90f0b711c6a506860b7bdbe3` (EOA)** —
  this address **has never sent a transaction** (0 txs): it is a pure off-chain EIP-712 signing key.
- `signer()` of CapitalStake = **`0x04ae9200c02d598edf2801c3e3850431d57cd707` (EOA)** — **active**: executed the
  Gnosis-Safe wind-down tx on 2026-10-09, received the 41.181 ETH payout, reimbursed a staker 8.2 ETH, moved 33 ETH
  onward on 2026-10-12.
- `operator()` of Underwriting, Treasury, Surplus, CapitalStake = **`address(0)`** (never set) → their `payouts`/
  `burnOuts` paths are **unreachable by anyone**, including the team, until the owner sets one.
- `owner()` of the Nsure token + `owner`/`operator` of the converter = **Gnosis Safe `0x1995dc62…`** (3-of-5;
  owners `0x04ae9200…`, `0x109ba0a2…`, `0x5ba55c92…`, `0x9af49f88…`, `0x74d039de…`; nonce 11).
- Minters of NSURE (3): `CapitalStake`, `ClaimPurchaseMint`, the Safe. Max-supply headroom: **27.04M NSURE**.

**Balances (block 26,193,225):**

| Contract | WETH | NSURE | other |
|---|---:|---:|---|
| Underwriting | 3.310472452994177977 | 1,869,535.488480029562381732 | 50.0M "SPARK" spam token |
| Surplus | 6.048082593315581676 | 0 | 50.0M "SPARK" spam token |
| Treasury | 1.512020648328895409 | 26,000 | — |
| CapitalStake | 0 | 16,291,541.687157376292487166 | 38.702 nETH staked (lpToken) |
| ClaimPurchaseMint | 0 | 145,484.073385803029360000 | — |
| Nsure token contract | 0 | 415,838.180384726188914343 | — |
| CapitalConverter | 1e-7 (dust) | 0 | **native ETH = 0**, nETH totalSupply 41.182 |
| Buy | 35 wei | 0 | — |

No token approvals exist from any pool/converter to any spender (verified: zero `Approval` events on WETH/NSURE with
owner ∈ {Underwriting, Surplus, Treasury, CapitalStake, Buy, Converter}).

**Liquidity:** the only NSURE market is the Uniswap-V2 pair `0xed196f5f01e8c99eF4c6d77B83CCaF629032A8f2`
(NSURE/WETH): reserves **19,745,162.45 NSURE / 5.38903 WETH** → NSURE ≈ $0.0006633.

---

## 4. The nETH story (why the "insurance backer" funds are gone)

`CapitalConverter` minted nETH 1:1 against ETH (215 mints, 2021–2022). Total nETH outstanding: **41.182**; of that,
**38.702 is staked in CapitalStake** (17 active stakers) and 2.48 sits in 4 wallets.

Wind-down sequence (all read-only citations):

1. **2026-09-18/24:** holder `0x3906e62f…` withdrew 2.0 nETH; the big holder `0x4322aa46…` withdrew **50.0 nETH**
   from CapitalStake (block 26,048,212, after its 14-day pending period) and then called
   `CapitalConverter.exit(50e18)` → **50 ETH** (tx `0x3002b102…`, block 26,048,215).
2. **2026-10-09:** the Gnosis Safe, executed by signer EOA `0x04ae9200…`, called
   `CapitalConverter.payouts(0x04ae9200…, 41.181 ETH)` (tx `0x14ee088c…`, block 26,152,934, event `ePayouts`).
   **nETH totalSupply stayed at 41.182 after this payout** → the ETH left via the privileged `payouts` path, not via
   holder exits. nETH's redemption value is now exactly **0**.
3. The signer EOA then paid **8.2 ETH** to staker `0x6f9bb7e4…` (their exact nETH stake) off-chain and moved 33 ETH
   onward — i.e., the team is settling selected stakers off-chain while the on-chain nETH is worthless.

The team is **alive and winding down** (owner tx 2026-09-21; Safe tx 2026-10-09; signer EOA tx 2026-10-12).

---

## 5. What an attacker can / cannot do (exact call paths)

**E-U — closed (all proven by fork PoC `test_eu_paths_closed`, 12 attempts):**

| Attempt | Live result |
|---|---|
| `Underwriting.claim(3.31 WETH, 0, …)` with fabricated sig | revert (`invalid signature`/`unauthorized`) — needs `signer` key |
| `Treasury.claim(1.51 WETH, 1, …)` with fabricated sig | revert — needs `signer` key |
| `Surplus.payouts(attacker, 6.05 WETH, WETH)` | revert `not operator` — `operator == 0x0` |
| `Treasury.payouts(…)` | revert `not operator` |
| `Underwriting.withdraw(1, …)` | revert `insufficient` (no internal balance) |
| `CapitalStake.unstake(0, 1, …)` | revert — needs `signer` key |
| `CapitalStake.claim(0)` / `withdraw(0)` by a fresh address | succeed but transfer **0 NSURE** (`user.amount == 0`) |
| `CapitalConverter.exit(1e18)` | revert `CapitalConverter: insufficient assets` |
| `CapitalConverter.convert{1 ETH}(1e18)` | **revert** (SafeMath underflow: `smartBalance()==0`, totalSupply>0) |
| `Buy.buyInsurance{0.001 ETH}(…)` with fabricated sig | revert — needs `signer` key; premium transfers roll back atomically |
| `Nsure.mint(attacker, 1e18)` | revert — minter-gated |
| legacy nETH holder `exit(2e18)` | **succeeds and pays 0 ETH** (`value*0/totalSupply`) |

Net attacker gain in all cases: **0 wei**.

**P — open with keys (demonstrated, `test_privileged_owner_signer_drain`, gas 462,209):**
owner EOA rotates `signer` on Underwriting/Treasury → a signed `claim` drains **3.3105 + 1.5120 WETH**; owner sets
`Surplus.operator` → `payouts` drains **6.0481 WETH**; total **10.870575694638655562 WETH ($26,419.98)**. The same
owner can drain the NSURE depositor balances (withdraw with signer sig) and the Safe can mint up to 27.04M NSURE and
sell into the 5.39 WETH pool.

**H-O — open to legacy stakers only (`test_ho_staker_claims_nsure_rewards`):** each of the 17 active nETH stakers can
call the permissionless `CapitalStake.claim(0)` and receive their accrued NSURE. At the pinned block the pool-wide
pending was **2,218,372.86 NSURE** (largest single: 777,411 NSURE); the 16.29M reward pool then streams at
1.8 NSURE/block. Realizable ≈ $1,322 into the live pool (nominal $1,471).

**S:** the 415,838 NSURE sitting inside the Nsure token contract has no withdrawal function; nETH itself is worthless.

---

## 6. PoC / fork verification

- **Project:** `nsure/poc/` (Foundry, solc 0.8.24, vendored forge-std), fork pinned to block **26,193,225**.
- **Tests:** `nsure/poc/test/Nsure.t.sol` — **5/5 PASS** (CI run
  [38637806719](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38637806719), workflow `poc.yml`, branch
  `nsure`, 2026-10-14; fork RPC = keyless publicnode):
  - `test_live_state` (gas 206,966) — asserts every live balance/role cited above
  - `test_eu_paths_closed` (gas 764,228) — 12 attack attempts, net gain 0
  - `test_eu_neth_exit_pays_zero` (gas 63,045) — real nETH holder exits, receives 0 ETH
  - `test_privileged_owner_signer_drain` (gas 462,209) — P-path drains exactly 10.870575694638655562 WETH
  - `test_ho_staker_claims_nsure_rewards` (gas 169,693) — staker receives 91,537.27 NSURE pending
- **CI-side independent state check:** `ci-out/nsure_state.txt` (artifact `result-nsure`), re-verified at block
  26,193,330: identical roles/balances; converter native = 0; nETH totalSupply 41.182.
- **Local run:** same 5/5 PASS (drpc fork).

**Cost note:** since E-U is empty, there is no gas/flash-loan math to report for an attacker. The P-path claim costs
~460k gas (a few $) and needs no capital.

---

## 7. Verdict and residual risk

- **E-U = $0.00 (high confidence).** No permissionless call pays an outsider any live value; the two permissionless
  value-moving calls (`CapitalStake.claim`, `CapitalConverter.exit`) pay only the caller's own position, and the only
  remaining position (nETH) redeems to 0.
- **P ≈ $26,420 WETH + ~$1.35k nominal NSURE** is one key away: a single **owner EOA** (`0x7023a321…`) and a single
  **signer EOA** (`0xbb826fb8…`, zero on-chain history). If either key is leaked/compromised, the WETH becomes E-U.
  This is the main latent risk and the thing to monitor (`setSigner`/`setOperator` events).
- **H-O ≈ 2.22M NSURE claimable now** by legacy stakers; the reward pool keeps dripping 1.8 NSURE/block.
- **S:** 415,838 NSURE locked in the token contract; nETH worthless.

**Blockers/caveats:** the signer key `0xbb826fb8…` has never transacted — key possession cannot be assessed
on-chain (a public leak would change the verdict to E-U for the WETH; no evidence found). The owner is a single EOA,
not a multisig. NSURE USD pricing relies on one thin UniV2 pool. State is moving (wind-down active Sept–Oct 2026).

---

## 8. Methodology & sources

- Live reads: `eth_call`/`eth_getBalance`/`eth_getStorageAt`/`eth_getCode` at pinned block 26,193,225
  (`analysis/snapshot.py` → `analysis/live_state.json`), cross-checked in CI at block 26,193,330.
- Sources: Etherscan V2 verified sources + ABIs for all 10 family contracts (`analysis/sources/`).
- History: Etherscan V2 `txlist`, `txlistinternal`, `tokentx`, `getLogs` (`analysis/event_logs.json`,
  `analysis/evidence_txs.json`, `analysis/neth_holders.json`, `analysis/capitalConverter_*.json`).
- Enumeration: all contracts created by the two deployer EOAs (`analysis/nsure_family_contracts.json`).
- Prices: DefiLlama `coins.llama.fi` (WETH $2,430.41, 2026-10-14); NSURE from live UniV2 reserves.
- Prior context: `l2-triage-a` row "Nsure" ($27,300 LIVE-FUNDED); `zombie_hunt/github_stuck_funds.md` §Signal C
  (the 41.18 ETH then still in the converter — since paid out; see §4). MarketingMining `0x0feccb11…` (23.42 ETH)
  is **not** Nsure — it is an NFTX/Shard-era pool (SAND/ENJ), out of scope.

## 9. Files index

```
nsure/
├── README.md                     ← this report
├── summary.json                  ← machine-readable summary
├── analysis/
│   ├── rpc.py, snapshot.py       ← read-only tooling (no secrets; RPC from env)
│   ├── live_state.json           ← pinned state dump (block 26,193,225)
│   ├── sources/                  ← verified sources + ABIs + extracted core contracts
│   ├── event_logs.json           ← Claim/Deposit/Withdraw/Unstake/ePayouts/eMint/eBurn history
│   ├── evidence_txs.json         ← wind-down tx citations
│   ├── neth_holders.json         ← nETH holder set
│   ├── pending_rewards.json      ← per-staker pending NSURE
│   ├── capitalConverter_txs.json / _internal.json
│   ├── nsure_family_contracts.json, tokenmap.json, all_balances_nz.json
├── poc/                          ← Foundry PoC (5 tests)
├── ci/run.sh                     ← CI state re-verification
├── ci-out/nsure_state.txt        ← CI-side artifact
├── ci-log.txt                    ← CI run log (run 38637806719)
└── ci-artifacts/                 ← downloaded artifact
```
