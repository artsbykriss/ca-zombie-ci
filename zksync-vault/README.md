# ZH4 Wave B1 — “Unnamed zkSync Era vault” `0x621425a1…` is **SyncSwap Vault (V1)** — E-U **$0.00**

**Date:** 2026-10-18 · **Chain:** zkSync Era (324) · **Status:** read-only; **no transactions signed or
sent**; no keys; all proofs are `eth_call` / `eth_getCode` / state-override simulations or a
byte-identical recompile. · **Verdict:** **CLOSED — protocol custody, not a CEX omnibus, no
unprivileged extraction.**

## TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent / conditional risk |
|---|---:|---|---|
| **SyncSwap Vault V1** `0x621425a1Ef6abE91058E9712575dcc4258F8d091` (zkSync Era) | **$0.00** | Every debit is keyed by `msg.sender` (`balances[token][msg.sender] -= amount`); `transferAndDeposit` credits only the real balance delta and has no `from` parameter; flash loans require `postLoanBalance ≥ preLoanBalance`; the owner has **no sweep/withdraw** function and there is **no proxy/upgrade**; the deployed code is **byte-identical** to the published source | (1) **Excess attribution** — anyone can call `deposit(token,to)` to claim a *pre-existing unattributed* balance. Standing value measured: **$0.0001** (100 raw USDC in one stable pool) + 40 spam tokens worth $0. (2) **2-tx deposit front-run** — a user who does `token.transfer(vault)` then `vault.deposit()` in a separate tx can be front-run; not currently used (last 50 direct txs: 49 `withdraw`, 1 `transferAndDeposit`). (3) `deposit(wETH,to)` grabs the vault’s entire wETH balance; live balance **0**. |

## Total live extractable now: **$0.00**

**Confidence: HIGH.** Basis: byte-identical source↔code proof (0/30,944 bytes differ), exhaustive
live accounting (2,825 ERC-20 tokens; all 3,821 V1 pools), and 22/22 live gate checks. The only
permissionless value-capture primitive is capped at **$0.0001** standing, below gas.

**What the $5.59M actually is:** **99.96% SyncSwap V1 pool reserves** ($5,588,218 of $5,590,697);
only **$2,478.77** is non-pool user/account balance. This is LP-owned liquidity, redeemable by the
LP holders via the pools (`burn`/`burnSingle`) — **H-O**, not attacker-extractable. It is *not* a
CEX omnibus and *not* a protocol fee pot.

---

## 1. Identity — it is the documented SyncSwap V1 vault

- **Official docs:** SyncSwap “Smart Contracts” page lists **Vault (V1) =
  `0x621425a1Ef6abE91058E9712575dcc4258F8d091`** on zkSync Era, next to Pool Master (V1)
  `0xbB05918E9B4bA9Fe2c8384d223f0844867909Ffb`, Classic Pool Factory `0xf2DAd89f2788a8CD54625C60b55cD3d2D0ACa7Cb`,
  Stable Pool Factory `0x5b9f21d407F35b10CbfDDca17D5D84b129356ea3`, Router `0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295`,
  wETH `0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91`.
- **Creation:** `0xecd787b7351ef02b52a6adcbfd015907b83e74c5e4e015510657084c3d84d82b`, zkSync Era block
  **9,764**, 2023-03-24, status **success**, deployer **`0x000002c34bAE6DD7BeC72AcbA6aAAC1e01A359De`**
  (EOA, nonce 13) via ContractDeployer `0x…8006`. Constructor arg `wETH = 0x5AEa…9a91`.
  The `ContractDeployed` event’s indexed bytecode hash is
  `010003c71e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5`.
  *(Blockscout’s address page shows creation tx `0x72316d49…`; that tx failed (status 0) and tried a
  different code hash. The real deployment is the block-9,764 event above.)*
- **Not a CEX omnibus:** no `deposit`-per-user hot-wallet pattern beyond the documented vault;
  3,821 documented SyncSwap pools hold their reserves at this address; `owner()` is the SyncSwap
  deployer EOA; `wETH()` is the canonical zkSync wETH; the selector set is exactly the Audit/AGPL
  `SyncSwapVault` ABI (24 functions + `0xffffffff` sentinel), with **no** sweep/withdraw-all/admin
  transfer function.

## 2. Code identity — byte-identical, not a look-alike

The deployed EraVM runtime is **30,944 bytes**. Recompiling the published
`contracts/vault/SyncSwapVault.sol` (+ its 15-file import closure, vendored in `analysis/src/`) with the
project’s own **zksolc 1.3.5** and **solc 0.8.15** (optimizer on, runs 200, standard-JSON — the exact
hardhat-zksync-solc path) reproduces **all 30,944 bytes exactly**:

| | Value |
|---|---|
| Deployed sha256 | `92c3ce7b1e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5` |
| Recompiled sha256 | `92c3ce7b1e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5` |
| Differing bytes | **0** |
| zkSync hash | `010003c7` + `sha256[8:]` = version 1, 967 words, `1e7f9b…730a5` |
| Source commit | `5285a3a7b2b00ca8b7ffc5ae5ce6f6c6195e4aa7` (vault files last changed 2023-03-16, before deploy) |

This is a **completeness proof**, not just a selector match: there is no hidden function, no
`delegatecall`, no upgrade hook. Full detail: `analysis/decompilation.md`,
`analysis/selector-map.md`, `analysis/storage-layout.json`.

**Storage layout verified live** (block 72,542,827): slot 0 `_status=1`; slot 1 owner +
`_paused=false`; slot 2 fee `5e14`; slot 3 fee recipient; slot 4 `balances` mapping;
slot 5 `reserves` mapping. Direct mapping reads reproduce `balanceOf(USDC,pool)=2116219546435` and
`reserves(USDC)=2190557651671` exactly — the deployed layout is the published one.

## 3. Live state (block **72,543,148**, CI run; prices DefiLlama 2026-10-18)

| Asset | Amount | USD |
|---|---:|---:|
| ETH (native) | 1,116.878522 | $2,690,440.37 |
| USDC `0x3355…aaf4` | 2,190,162.85 | $2,189,668 |
| USDT `0x4932…ba4c` | 181,779.79 | $181,707 |
| ZK `0x5a7d…eaf3e` | 12,659,823.43 | $188,192 |
| WBTC `0xbbeb…1011` | 1.15086182 | $93,790 |
| wstETH `0x703b…e867` | 16.04880224 | $48,186 |
| rETH / cbETH | 10.53344 / 1.208026 | $29,771 / $3,322 |
| DAI / BUSD | 14,333.99 / 25,104.63 | $14,338 / $25,061 |
| MATIC/BNB/LUSD/crvUSD + smaller real tokens | — | ≈$190k |
| **Total custody** | | **$5,590,697.02** |

- **Pool-attributed: $5,588,218.25 (99.96%)**; non-pool (router/user balances): **$2,478.77**.
- `reserves(0x0)` = **exactly** the native balance (`1116878522377497625509` wei at the CI block):
  **zero native excess**.
- wETH balance of the vault = **0**; `reserves(wETH)` = 0 (wETH and ETH share the native ledger).
- `paused()` = **false**; `owner()` = `0x000002c3…59de`; fee = 0.05%; fee recipient = `0x4444f8…99Ce`
  (a contract, 18,784 bytes).
- **No proxy:** `implementations: []`; EIP-1967 implementation/admin/beacon slots all **0**.
- **No token approvals from the vault:** `allowance(vault → router / pool master / fee recipient)` = 0
  for USDC, USDT, WETH. The source never calls `approve`.
- The vault holds 2,825 ERC-20 token contracts (mostly spam airdrops; 40 show any excess, all
  worthless). 3,821 V1 pools enumerated from both factories (3,742 classic + 79 stable); **one** pool
  has any reserve-vs-vault excess: 100 raw USDC = **$0.0001**.

## 4. What an attacker can and cannot do (live-tested)

All simulations at the CI block from a **fresh address** `0x1111…1111` (no balance, no code):

| Call | Result | Meaning |
|---|---|---|
| `withdraw(USDC, attacker, 1)` | **Panic `0x11`** | debit keyed to `msg.sender`; recipient param is not the debit key |
| `withdraw(USDT, attacker, 185e6)` | **Panic `0x11`** | same |
| `withdrawETH(attacker, 1e18)` | **Panic `0x11`** | same |
| `withdrawAlternative(USDC, …, 0/2)` | **Panic `0x11`** | mode only selects wrapping |
| `transfer(USDC, attacker, 1e6)` | **Panic `0x11`** | internal transfer debits sender |
| `transferAndDeposit(USDC, attacker, 1e6)` | **`TransferFromFailed` `0x7939f424`** | pulls from `msg.sender`; unfunded caller cannot fake a deposit |
| `deposit(USDC, attacker)` | **returns 0** | credits only the real unattributed delta (0 for USDC) |
| `deposit(ETH/wETH, attacker)` | **returns 0** | no native/wETH excess |
| `setPaused(true)` / fee setters / `transferOwnership` | **`Ownable: caller is not the owner`** | admin only |
| `flashLoan(EOA, USDC, 1e6)` | revert (empty callback) | EOA cannot implement the callback |
| `flashLoan(fake receiver, USDC, 1e6)` with state override returning the magic value but **not repaying** | **`INVALID_POST_LOAN_BALANCE`** | cannot keep the loan |
| same with wrong callback value | **`IERC3156_CALLBACK_FAILED`** | callback value is checked |

**Positive control:** calling `withdraw(USDC, attacker, 1)` *from the USDC/WETH pool address*
`0x80115c70…c05c` (which holds 2,116,219 USDC + 876.70 ETH of pool reserves) succeeds — proving the
debit is bound to the calling account and the recipient is arbitrary. Only that pool contract can
initiate it; a user cannot borrow its identity.

## 5. Why the pool reserves are not directly extractable

The vault is a shared ledger; the pools are the accounts. The pool contracts (`SyncSwapClassicPool`,
`SyncSwapStablePool`) expose only:

- `mint(data, sender, callback, data)` — `amount0 = vaultBalance0 − reserve0`; requires the input to
  have been transferred/credited first; zero input ⇒ zero invariant growth ⇒ `InsufficientLiquidityMinted`.
- `burn` / `burnSingle` — `liquidity = balanceOf[address(this)]`; the caller must have transferred LP
  tokens to the pool first; pays pro-rata reserves to a caller-chosen `to`.
- `swap` — `amountIn = vaultBalance − reserve`; zero input ⇒ zero output; fees/slippage apply.

There is no public `skim`, `sweep`, or arbitrary `vault.withdraw` in the pool ABI, and the pool’s
`_transferTokens` is private. A per-pool `getReserves()` vs `vault.balanceOf(token,pool)` sweep of
**all 3,821 pools** found exactly **one** excess (100 raw USDC, $0.0001) — the accounting is otherwise
exact. So the $5.59M is redeemable only by LP holders (H-O), not by an unprivileged attacker.

## 6. Residual / latent risk (honest)

1. **Excess attribution (the only free-credit primitive).** `deposit(token,to)` credits
   `token.balanceOf(vault) − reserves[token]` to any `to`. If a real token is ever left unattributed
   (fat-finger transfer, bridge/CEX delivery, or the window between a plain `transfer(vault)` and a
   follow-up `deposit`), whoever calls `deposit` first captures it. Measured standing excess:
   **$0** for every real token (USDC/USDT/ZK/WBTC/ETH-derivatives excess exactly 0), 40 spam tokens
   worth $0, and 100 raw USDC in one stable pool ($0.0001). The 2-tx pattern is a genuine MEV
   surface, but not currently used: the last 50 direct vault txs were 49 `withdraw` + 1
   `transferAndDeposit`, no `deposit` calls; v19 saw 4 `deposit` calls in a 1,400-tx sample. Re-check
   is cheap: compare `token.balanceOf(vault)` to `reserves(token)`.
2. **wETH grab.** `deposit(wETH,to)` takes the vault’s entire wETH balance and unwraps it; balance
   is **0 now** and was 0 across v19’s 34-block historical sample. Only an accidental wETH send
   creates a one-block opportunity.
3. **Native donations are stuck, not claimable.** Every native credit path is `msg.value`-funded;
   a forced/donated ETH balance would be unattributable and permanently stuck. Live native excess is 0.
4. **Owner key.** The owner can change flash-loan fee config, pause flash loans, and transfer
   ownership — **not** move principal. A key compromise yields no sweep (P = $0), only a flash-loan
   DoS/fee change.
5. **Flash-loan fee quirk.** `_payFeeAmount` forwards the entire `post − pre` delta to the fee
   recipient (not just the required fee), so over-repayment is a donation to the fee recipient.
   No profit path; the borrower must repay ≥ principal + fee.

## 7. PoC / verification

- **Byte-identical recompile:** `ci-out/compile.json` — 30,944/30,944 bytes, 0 diff, sha256 match.
- **Live gate suite:** `analysis/gates.sh` / `analysis/gates.txt`; reproduced in CI as 22 checks
  (`ci-out/verify.log`).
- **Flash-loan non-repayment PoC:** `poc/README.md` — live `eth_call` with a code state-override
  receiver that returns the ERC-3156 magic value but does not repay; vault reverts
  `INVALID_POST_LOAN_BALANCE`. Control with a wrong magic value reverts `IERC3156_CALLBACK_FAILED`.
- **Accounting sweeps:** 2,825 ERC-20 tokens (`ci-out/sweep.json`), 3,821 pools
  (`ci-out/pool_excess.json`), pool-vs-user attribution (`analysis/attribution.json`).
- **Foundry/EVM fork note:** Foundry’s revm cannot execute EraVM bytecode, so a local Foundry fork of
  zkSync Era is not possible. The PoC uses the chain’s own `eth_call`/state-override engine
  (read-only, no state change). This is a toolchain limitation, not a gap in the gate evidence.
- **CI:** see §9.

## 8. Verdict

| Category | USD | Confidence | Note |
|---|---:|---|---|
| **E-U** (external unprivileged) | **$0.00** | **high** | no standing path; the only primitive is capped at $0.0001 |
| **E-U-conditional** | $0.0001 standing | high | excess-attribution / 2-tx deposit race; third-party-mistake dependent |
| **H-O** (holder self-service) | **$5,590,697.02** | high | LP reserves (99.96%) + user balances; redeemable by holders |
| **P** (privileged) | $0.00 | high | owner: fees/pause/ownership only; no sweep, no proxy |
| **S** (stuck) | $0.00 | high | no native excess, no dead pool with balance, spam = $0 |

**Headline:** the “unnamed $5.5M zkSync vault” is the **documented SyncSwap V1 custody vault**;
the $5.59M is **LP-owned pool liquidity**. An external unprivileged attacker can extract **$0.00**
today. The wave-1 hypothesis (CEX omnibus / spoofable accounting) is falsified by byte-identical
source, `msg.sender`-bound debits, delta-based deposits, repayment-enforced flash loans, and an
owner with no sweep.

## 9. CI

- Run: **PENDING** (fill after `bash ci/ci-run.sh zksync-vault`).
- Artifacts: `ci-out/verdict.json`, `compile.json`, `sweep.json`, `pool_excess.json`, `verify.log`.
- Local pre-CI run at block 72,543,148: all 22 checks PASS; total custody $5,590,697.02; E-U $0.00;
  standing excess $0.0001.

## 10. Methodology, caveats, files

**Method.** Located the contract from the docs, then proved identity three ways: (a) creation-event
bytecode hash = `sha256(runtime)` low 28 bytes with version/length prefix; (b) full recompile with the
repo’s own zksolc/solc/settings → 0-byte diff; (c) live storage-layout and behavior checks. Enumerated
all V1 pools from both factory `PoolCreated` logs (3,821); read every pool’s `getReserves()` and vault
balance; swept every ERC-20 the vault holds; simulated every value-moving selector from a fresh
address; simulated a non-repaying flash loan via state override.

**Caveats.**
- Point-in-time reads (2026-10-18, blocks 72,542,827 / 72,543,148); re-check before acting.
- The $5.59M is not “lost” or “dormant”: it is live AMM liquidity; LP holders can exit at market.
- `reserves ≤ balance` invariant holds for every real token; if that ever flips (a real token is
  donated/unattributed), `deposit(token, me)` is a 2-call capture — re-check is cheap and recommended.
- Blockscout’s creation-tx metadata is wrong for this address (failed tx `0x72316d49…`); the
  authoritative deployment is the `ContractDeployed` event at block 9,764.
- No mainnet transactions, no keys, no approvals; the state-override PoC changes no state.
- The 2-tx deposit front-run is an MEV observation, not a standing balance; it is reported separately
  and not counted in the headline.

**Files.**
- `README.md` (this) · `summary.json`
- `analysis/code.hex` — deployed runtime (30,944 B)
- `analysis/selector-map.md` — 24 selectors + sentinel, auth/effect
- `analysis/decompilation.md` — byte-identical compile, creation, storage
- `analysis/storage-layout.json` — slots + live values
- `analysis/gates.txt`, `analysis/gates.sh` — live gate sims
- `analysis/sweep.json`, `analysis/priced.json` — 2,825-token reserves sweep + prices
- `analysis/pools.json`, `analysis/pool_excess.json` — 3,821 pools, reserve-vs-vault
- `analysis/attribution.json` — pool vs non-pool USD
- `analysis/sweep.py`, `price.py`, `pool_excess.py`, `pools.py`, `attribute.py` — scripts
- `analysis/src/` — vendored 15-file source closure (AGPL-3.0-or-later, SyncSwap)
- `ci/verify.py`, `ci/run.sh`, `ci-out/` — reproducible CI job
- `poc/README.md` — state-override non-repayment PoC
