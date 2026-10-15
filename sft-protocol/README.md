# SFT Protocol (Filecoin FEVM) — L2 Phase-2 deep dive

**Date:** 2026-10-15 · **Chain:** Filecoin mainnet (FEVM, chain id 314) · **Fork block:** 6,457,969
**Status:** read-only analysis; PoC fork-verified only (local + GitHub Actions forks); **no mainnet transactions**; no secrets.

SFT Protocol is an abandoned Filecoin liquid-staking / lending protocol (DefiLlama "deadUrl", TVL stale 1d).
L2 triage found **$59.31 live** at the lending pool. This deep dive re-verified live state at the latest
block, mapped every value-moving path, and fork-tested all candidate extraction routes.

## TL;DR

| Target (Filecoin FEVM) | Live value | Fresh unprivileged attacker (E-U) | Why closed | Latent risk |
|---|---|---|---|---|
| Lending pool / rSFT `0x1471…b58E` | **53.786 FIL** ≈ $59.00 | **$0** | `deposit()` reverts `paused!`; `withdraw()` reverts `POOL_FIL_BALANCE_NOT_ENOUGH` for **all** holders (frozen); `borrow()` reverts `NOT_PLEDGE_THIS_ORDER`; `pledge()` reverts for arbitrary callers; utilization 99.99% > borrowThreshold 95% | Owner EOA can upgrade proxy / rescue (P). Holder withdrawals frozen since ~block 5.47M (S) |
| Reward pool / farm `0xE86D…54f7` | **1000.075 FIL** ≈ $1,097.08 + 854,354 SFT staked | **$0** | `batchClaim` is per-order credit accounting: fresh stake ⇒ 0 credits; cross-user claim ⇒ Panic(0x32); fresh `unstake` ⇒ `it is not time to unlock` (6-month lock) | Credited stakers can still claim their credits (H-O, observed live) |
| Mint/withdraw pool `0xcdAf…9C445` | 0 FIL + 216,128 SFT | $0 | `deposit()` reverts; pool has no FIL; `swapFil` has nothing to pay | SFT stuck (worthless, no market) |
| SFT token `0xC5eA…58Ba` | 1,388,939 SFT | $0 | `mint` gated (`Only minter can call`); no DEX market (no CoinGecko/DefiLlama price, no Blockscout volume) | Minter can inflate (P) |
| rSPD token `0x97AA…5616` | 236,807 rSPD | $0 | no market, no redemption path | — |
| Newer proxy `0xc28F…2Ea94` | 0.37 FIL + 2,000 SFT | $0 | owner-only (deployer EOA) | — |
| Native FIL at miner actors | **not enumerable** (dashboard API `ww8.sftproject.io` dead) | $0 (not EVM-reachable) | FIL sits at native Filecoin actors, outside FEVM | unknown |

**Total live EVM-visible value: 1,054.23 FIL ≈ $1,156.49** (FIL = $1.097, CoinGecko 2026-10-15).

## Total live extractable by an external unprivileged attacker: **$0.00 (E-U)** — confidence: **high**

No permissionless path pays the caller. All value is behind holder-only positions (credited farm
orders), owner roles (ProxyAdmin / owner EOA), or is frozen. An honest $0 with proofs.

## Mechanism: what each contract does and where the value sits

Architecture (all on Filecoin FEVM; verified from on-chain calls, docs at `docs.sftproject.io`, and DefiLlama's adapter):

1. **Lending pool + rSFT share token** — `0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E`
   (EIP-1967 `TransparentUpgradeableProxy`; impl `0x0b5929e454a9593a7CD78889377EcdbF3ec90f7B`; admin `0x98002559DC58B1c1ba01f6c5F309a9e92af589DD`).
   Docs: FIL depositors get rSFT 1:1; borrowers pledge SFT (staked 6 months in the farm) and borrow up to 60% LTV.
   - `totalPooledFIL()` = `totalSupply()` = **234,477.718487329089234903** (exchange rate exactly 1.0).
   - Actual FIL balance: **53.7862261354336 FIL**; utilization `getUtilizationRate()` = **9999** (99.99%), `borrowThreshold` = 9500, `ltv` = 6000.
   - **Deposits paused** (`deposit()` ⇒ `Error(paused!)`).
   - **Withdrawals frozen**: every holder call tested (`0.00001 FIL` up to `53 FIL`; holders with 355 and 100,081 rSFT) reverts `POOL_FIL_BALANCE_NOT_ENOUGH`. Last successful withdrawal on-chain: block **5,472,905** (~Nov 2025). Cause: an internal accounting variable (storage slot 2 = 185,868.916202 FIL, i.e. FIL "out" / deployed) must be 0 for the check to pass; the contract's own FIL balance is irrelevant (topping the pool to 500,000,000 FIL on the fork does not unfreeze it).
   - `borrow(orderId, amount)` ⇒ `NOT_PLEDGE_THIS_ORDER`; only **one** borrow ever succeeded (block 4,512,413, 0.11 FIL). `pledge(...)` reverts for arbitrary callers.
   - `distributeReward(uint256)` is distributor-gated (`0xb894CDd932A610e7096b06Ef5177Ca601D0e3a36`); the distributor has sent **41,609 FIL** into the pool in the fetched tx window alone (206 calls) — mining income recycling, not attacker-reachable.
2. **Reward pool / farm** — `0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7`
   (proxy; impl `0xd8089632eae9258371262a7b0ece371f3b607f1a`; same admin).
   - Holds **1000.0751373305601 FIL** and **854,354.36103 SFT** (staked by users).
   - `stake(4, amount)` works (creates a locked order; SFT moves in). `unstake` ⇒ `it is not time to unlock` for fresh orders.
   - `batchClaim(types[], indexes[], amounts[])` is per-user, per-order credit accounting: a fresh staker's claim pays **0**; a non-staker's claim reverts `Panic(0x32)` (array OOB). The distributor credits specific orders with specific amounts in `distributeReward` (335 calls, 39,060 FIL in in the fetched window); the remaining **1000 FIL is the unclaimed credit reserve**.
   - Live claims still work for credited stakers (observed on the fork: 1e-5 FIL, 9.96e-12 FIL, 3.79e-12 FIL to three different stakers).
3. **Mint/withdraw (swap) pool** — `0xcdAfc875eed0f346D5D2584fc6C37B539459C445` (impl `0xa341c4d7b1ab5526f11f1a57dc9b9f7c460e9c41`): 0 FIL, 216,128.27 SFT; `paused()` = false; `deposit()` reverts; `oracle()` = the deployer EOA `0x3BBFa3fe…`.
4. **SFT token** — `0xC5eA96Dd365983cfEc90E72b6A2daC9562f458Ba`: supply 1,388,939.198; `mint` ⇒ `Error(Only minter can call)`. Top holders: reward pool 854,354 / mint pool 216,128 / lending pool 167,837 / EOAs.
5. **rSPD** — `0x97AAe66a1D2a41eAC573397B7a5656a9cF3E5616`: supply 236,807.94, owner EOA, no market.
6. **Newer proxy** — `0xc28Fb2061df04c3AFFEAd841863e97C4ad12Ea94` (impl `0x89B9Dbff…`): 0.37 FIL + 2,000.13 SFT; `owner()` = deployer EOA.
7. **Ownership**: all three pools share ProxyAdmin `0x98002559…` whose `owner()` = EOA `0x0E294a09Ab6d03597A79e52c951410955097c32C`; pool/reward/mint `owner()` = same EOA; reward pool `pendingOwner()` = deployer EOA `0x3BBFa3feDbb53323CD2beb754f20bDbb87D04bc1`.

## What an attacker can / cannot do (fresh, no positions, no roles)

| Call | Live result | Fork evidence |
|---|---|---|
| `pool.deposit()` | revert `paused!` | test_C |
| `pool.withdraw(1e18 / 53e18)` | no-op returning 0 (no shares) | test_B |
| `pool.withdraw(...)` as rSFT holder | revert `POOL_FIL_BALANCE_NOT_ENOUGH` (frozen) | test_N, WithdrawGate |
| `pool.borrow(0, 1e18)` | revert `NOT_PLEDGE_THIS_ORDER` | test_D |
| `pool.pledge(...)` | revert (empty reason) | test_G |
| `pool.rescueTokens(SFT,…)` | revert `Ownable: caller is not the owner` | test_J |
| `reward.stake(4,100e18)` (after obtaining SFT) | **succeeds** — but creates a 6-month locked order | test_H |
| `reward.batchClaim` after fresh stake | succeeds, pays **0** | test_H |
| `reward.batchClaim` as non-staker | revert `Panic(0x32)` | test_K |
| `reward.unstake` fresh | revert `it is not time to unlock` | test_H |
| `reward.deposit{1 FIL}()` / `reward.withdraw(1e18)` | revert | test_L, MiscProbe |
| `mint.deposit{1 FIL}()` | revert | test_I |
| `mint.pause()` | revert `Ownable: caller is not the owner` | test_J |

The only acquisition route for SFT is an OTC transfer from an existing holder (modelled in test_H by a
transfer from an EOA holder) — SFT has no DEX market (no CoinGecko listing, no DefiLlama price, no
Blockscout volume/exchange-rate), and the protocol's own mint path reverts. Even with SFT in hand, the
stake→claim→borrow→unstake loop yields **0** (claim pays 0; borrow reverts; unstake locked).

## PoC / fork verification

Foundry project: `poc/` (solc 0.8.24). Fork pinned at block **6,457,969**, RPC `https://filecoin.drpc.org` (keyless;
override with `FIL_RPC_URL`). All tests are read-only fork simulations; no mainnet transactions.

- `poc/test/SFTLive.t.sol` — 15 tests: live state, fresh-attacker probes, stake/claim/borrow/unstake loop, admin gates.
- `poc/test/WithdrawGate.t.sol` + `WithdrawGateBisect.t.sol` + `SlotGate.t.sol` + `SlotThreshold.t.sol` — proves the withdrawal freeze and isolates the gate (internal accounting slot 2; contract FIL balance irrelevant).
- `poc/test/WithdrawDebug.t.sol`, `WithdrawTrace.t.sol`, `WithdrawHistory.t.sol` — withdrawal semantics and history.
- `poc/test/StorageDump.t.sol` — storage layout dump (accounting variables).
- `poc/test/StakerClaim.t.sol` — H-O liveness: credited stakers still claim FIL.
- `poc/test/MiscProbe.t.sol` — newer proxy + reward pool deposit/withdraw probes.

Results: see `ci-log.txt` / `ci-artifacts/` (CI run URLs below) and `analysis/local_full_suite.log`.

**CI runs:**
- _(filled after CI run)_

## Verdict and classification

- **E-U: $0.00 (high confidence)** — no permissionless extraction path exists at block 6,457,969.
- **H-O: $1,097.08** — reward-pool FIL is claimable only by stakers whose orders were credited (self-service `batchClaim`); observed live payouts are small (1e-5 FIL scale) and the remainder is unclaimed credits. Medium confidence that the full remainder is claimable (it is credit accounting, not a pooled rate).
- **P: $59.00** — lending-pool FIL (53.786 FIL) plus all token reserves are reachable by the owner EOA via proxy upgrade / `rescueTokens`; the same EOA controls all three pools' ProxyAdmin.
- **S: $0.00 additionally** — the lending pool's FIL is frozen for non-privileged parties (withdraw reverts for everyone; deposits paused). Note the 53.786 FIL is counted once, under P.

Residual/latent risk: (a) if the internal accounting variable that gates `withdraw()` returns to 0 (e.g., protocol-side "undeploy" of FIL), rSFT holders could withdraw at 1:1 — that is holder-only (H-O), not attacker-profitable; (b) the ProxyAdmin owner EOA is a single point of failure for ~$1.16K; (c) native FIL held at miner actors is unknown and not EVM-reachable.

## Methodology & sources

- Live reads at block 6,457,969 via keyless public Filecoin RPCs (`filecoin.drpc.org`, `api.node.glif.io`); Blockscout Filecoin (`filecoin.blockscout.com`) for ABIs, decoded txs, logs, holders; CoinGecko for FIL price.
- Contract surface reconstructed by selector extraction from runtime bytecode + 4byte lookup + Blockscout method decoding (`analysis/`).
- Docs: `docs.sftproject.io` (architecture, contract addresses, lending/redemption mechanics); DefiLlama adapter `projects/sft-protocol/index.js`.
- Fork PoCs executed locally and on GitHub Actions (fork-only; no mainnet writes).

## Caveats & limitations

- The lending-pool implementation is not verified; the exact formula behind `POOL_FIL_BALANCE_NOT_ENOUGH` was isolated empirically (storage-slot bisection), not from source. The operational conclusion (all withdrawals revert) is source-independent.
- Miner-actor FIL (the protocol's staked FIL at storage providers) cannot be enumerated (dashboard API dead) and is not EVM-reachable; excluded from all totals.
- SFT/rSFT/rSPD have no observable market; "value" figures are FIL-denominated balances only.
- USD uses FIL = $1.097 (CoinGecko, 2026-10-15).

## Files index

```
sft-protocol/
├── README.md                  (this file)
├── summary.json               (machine-readable summary)
├── analysis/                  (RPC helpers, selector maps, storage dumps, tx/log fetches, local suite log)
├── poc/                       (Foundry project: interfaces + fork tests)
├── ci-out/                    (CI artifacts)
├── ci-log.txt                 (CI log; after run)
└── ci-artifacts/              (CI artifacts; after run)
```
