# O16–O21 — Solana residuals: LOCATION + verdicts

Read-only. No transaction signed/broadcast. Keyless public RPCs only (`solana-rpc.publicnode.com`,
`api.mainnet-beta.solana.com`, `coins.llama.fi`). Slot ~461.32M · 2026-10-25.
Prices: cbBTC $80,478.38 · RUSH $88.09 · USDC $0.99953.

Method: DeFiLlama `/protocols` → `module`/`tvlCodePath` → adapter source → custody addresses;
then on-chain `getAccountInfo` (jsonParsed) for each custody account, `getTransaction` to identify
the program actually invoked, `getAccountInfo` on each program (executable + upgrade authority),
and ELF string extraction (`program_surface.py`) for the instruction surface.

**Bottom line: all six are now LOCATED (program IDs resolved). None has a demonstrated
unprivileged value path. Total custody ≈ $7.5M, all behind program PDAs / admin / user queues.
E-U = $0.**

---

## O16 · Sat Rush — **LOCATED** — verdict **P**, ~$2.25M, confidence medium

- **Programs** (both executable, BPFLoaderUpgradeable):
  - `satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco` — mining/launch (ELF 2,141,536 B)
  - `SaTsTaKpGdTfUEPSSwyYgLKkfnZu8uL3D1DbLXshdb7` — staking (ELF 156,880 B)
  - both upgrade authority **`DDiAZadxEtAhVYJLFLv1yz91VC7z3GmNWJq2RXSYDuas`** (single key, upgradeable)
- **Custody** (adapter `registries/sumTokens/data1.js` → verified on-chain):

| Account | Mint | Amount | USD |
|---|---|---|---|
| `2zpcctvd7sCdtWe4bAYcNmfVFzaiFVtH81tfMAWCtMh9` | cbBTC | 10.56295475 | $850,286 |
| `G9iBFqhbu3rPCtTEnHzZmn8UDqy3t5d7VLqbnU8faYdT` | RUSH | 4,791.08622235 | $422,024 |
| `7c3iepAJkw8MRF6Rm5LyxB1Vbkxgq4EAAkGy7LNQtFfV` | RUSH | 11,065.784566102 | $974,799 |

  Owners: the two RUSH/vault authorities are **PDAs of `satRush…`**; the staking treasury is a
  **PDA of `SaTsTaKp…`**. The funds can only be moved by those programs.
- **Instruction surface** (from ELF): `SettleDeployPublic`, `BuyEpochTickets`, `BuyOneBtcTickets`,
  `BuybackBurnToken`, `ClaimGrubstakeAirdrop`, `ClaimOneBtcReward`, `ClaimSats`, `ClaimUsd`,
  `CreateEpochVault`, `CreateSatsVault`, `DistributeEpochReward`, `ExchangeAffiliatePoints`,
  `ExecutePublicAutomation`, `ReclaimMinerGrubstake`, `SealEpochPage`, `SwapRoundStake`,
  `TriggerOneBtcDraw`, `WithdrawGrubstake`, `WithdrawProtocolFees`, admin `Update*`.
  The `Withdraw*` names are the only exits; they are per-user (grubstake) or admin (protocol fees).
  `ExecutePublicAutomation` / `SettleDeployPublic` are permissionless by design (cranks).
- **Verdict:** funds sit in program PDAs, the two programs share one upgrade key, and the value
  exits are user-claim or admin. No unprivileged path observed ⇒ **P** (privileged/upgrade),
  with the claim paths **H-O** for users. Confidence medium (instruction bodies not decompiled).
- DL TVL: $848,425 (tvl) + $1,281,805 (staking) = $2,130,230 (close to the $2.25M measured).

## O17 · Loyal Earn — **LOCATED (no proprietary program)** — verdict **H-O**, ~$309k, confidence medium-low

- **No Loyal program ID exists.** Adapter `projects/loyal/index.js`: TVL = USDC in **1,987 per-user
  Squads vaults** (addresses from `stats.askloyal.com/api/earn/vaults`) + Kamino vanilla obligations
  (`KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD`, RiskBasket.Safe markets) + idle USDC on vault ATAs.
- The sampled vault owners are **System-owned accounts** (squads_v4_count = 0, squads_v3_count = 0
  in the child scan) — i.e. per-user self-custody wallets, not a shared pool.
- **Verdict:** value is each user's own USDC in their own vault/obligation ⇒ **H-O** (holder-only).
  There is no pooled contract to drain; the LYL mint `LYLikzBQtpa9ZgVrJsqYGQpR3cC1WMJrBHaXGrQmeta`
  is a token, not a custody program. E-U $0.

## O18 · TRUE DEX — **LOCATED** — verdict **P**, ~$290k, confidence medium

- **Programs:** `ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL` (ELF 561,248 B, upgrade auth
  `7pg5CzPosgA9dhh9gAViJfV8gLzHPZwEJtMeqY6N9XBK`) + a second, **immutable** program
  `L2TExMFKdjpN9kozasaurPirfHy9P8sbXoAN1qA3S95` (reported by the child; the ZK verifier).
- **Custody:** `A5GTSUyjFSfsQWwRESSa1UtxciFY6g6guBvM12Tee1ag` = **289,915.853993 USDC ≈ $289,780**
  (owner `FgAsLXd1S6LY6masqLFPgcPSeGjgMQpFeTh8PmeRG9fD`, a non-existent/PDA account).
- **Instruction surface:** `Initialize`, `RecoverCustody`, `RevokeProgramVkey`, `RotateWithdrawalExecutor`,
  `SetMinDepositAmount`, `SetPaused`, `StageProgramVkey`, `VerifyBlock`, `AcceptAdminTransfer`.
  This is a **zk-verifier custody** design: deposits are proven by `VerifyBlock`, and the only value
  exit is `RecoverCustody`, gated by a staged program vkey + an authorised withdrawal executor.
- **Verdict:** **P** — the custody is behind a verifier/executor role; `SetPaused` and admin-transfer
  are role-gated. No unprivileged path found. Confidence medium (verifier logic not decompiled).

## O19 · Pascal — **LOCATED** — verdict **P**, ~$2.33M, confidence medium

- **Program:** `3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j` (ELF 390,800 B, upgrade auth
  `CD3rB8zunjh7QEiVdd9vHaHYY5KmKBHDjMXfV5ebDMWp`).
- **Custody:** `5vRGRcwN4iYaiQdso1vgWbTDFYbS8GQNUDRMMKE2ycZS` = **2,332,835.390006 USDC ≈ $2,331,738**
  (owner `ASZu2LQiMCdWguteq3v5DkgU6wZ7aRL22MvU9fEJA98B`, a non-existent/PDA account).
- The ELF is stripped of Anchor `global:` names (no `Instruction:` strings recovered) ⇒ the
  instruction set could not be enumerated from strings; the custody PDA is only signable by the
  program.
- **Verdict:** **P** — largest single Solana residual ($2.33M) but custody is a program PDA and the
  program is upgradeable by one key. No unprivileged path found; **instruction surface not
  recovered** is the open item. Confidence medium.

## O20 · N1 Exchange Bridge — **LOCATED** — verdict **P (low confidence)**, ~$1.38M

- **Program:** `n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM` (ELF 566,016 B, upgrade auth
  `7qJuE8Kz8i6CvYHu6WGLKEJw97dyLCjZAzgdnzzgevGj`).
- **Custody (verified on-chain via `api.mainnet-beta`):**
  `DBDThTrUkoGhWRzT8fcE8MKwjEvgwrgPT981QUEyPqGy` = **1,381,289.660406 USDC ≈ $1,380,640**
  (ATA of the adapter owner `2ds4b3zrkgZ9FU8vNBSpT1UzACnmfYtjGsazPRzsbCCz`).
- **This is a zk/STARK-consensus bridge, not a simple lockbox.** ELF strings: `fina_state_facts`,
  `challenge_nullifier`, `effect_nullifier`, `merkle.rs`, `validator`, `acl`,
  `challenge_consensus_threshold`, `challenge_period_slots`, and errors
  `WithdrawalRateLimitExceeded`, `NotAValidator`, `MerkleRootMismatch`, `EffectAlreadyExecuted`.
  Instructions: `InitializeGlobal`, `EmitCrumb`, `AppCreatePropose/Approve/Cancel`, `Freeze`,
  `AllowAppVersion`, `SetPermission`, `SetOperator`, `SetChallengeConsensusThreshold`,
  `SetChallengePeriodSlots`, `SetBlockLifetime`, `SetTargetFinaStateFacts`, `DepositCreate`,
  `EventQueue`, **`Withdraw`**, `PruneEffectNullifier`, `WhitelistAsset`, `SetMinDeposit`,
  `SetWithdrawalRateLimit`, `ProposeBlock`, `FinalizeBlock`, `ChallengeBlock`, `PruneBlock`.
- **Verdict:** **P (low confidence)**. `Withdraw` is a user-facing instruction but the program
  carries a full consensus/challenge machine (validator ACL, challenge window, effect nullifiers,
  Merkle roots) ⇒ a withdrawal is only payable against a *finalized, unchallenged* state fact.
  No unprivileged path demonstrated, but the `Withdraw` account/proof binding was **not**
  decompiled — this is the one target worth a deeper pass. E-U not proven.

## O21 · Byzanlink RWA Markets — **LOCATED** — verdict **P**, ~$898k (Solana leg), confidence medium

- **Programs:** vault `HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se` (ELF 987,072 B, upgrade auth
  `CEhSZ93vgAretDxdDq7UopXCYhHf7ejnp1RTKJsFfdmh`); PayFi pool
  `B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U` (ELF 552,304 B, upgrade auth
  `5rmV2qBzHoJma5Xh75zbW32N9ePpj7ovRKdCRy9HJ6zG`). Vault state `96k5AKfdHMW6URrn3Qwn4wp3gN4S2GupK27dPxtt3vfw`.
- **The vault program is a fork of Kamino's `kvault`** — ELF source paths `programs/kvault/src/handlers/*`
  and `programs/payfi-vault/src/*`. Instructions: `InitVault`, `MintInitialShares`,
  `InitializeWithdrawalQueue`, `OpenUserPosition`, `Deposit(WithMinSharesOut)`, `RequestWithdrawal`,
  `InitiateWithdrawal`, `ProcessWithdrawals`, `CancelWithdrawals`, `UpdateVaultConfig`, `UpdateAdmin`,
  `GiveUpPendingFees`, `UpdatePoolAllocation`, `Invest`, `Deallocate`, `BuyWithMinSharesOut`;
  PayFi: `InitPool`, `Deposit`, `Allocate`, `Redeem`, `UpdateNav`, `Repay`, `SetPoolConfig`.
- Other legs: Ethereum ERC-4626 `bSyrupUSDC 0xA5cDEE01aA7A5E0620df5f27F26E552fdf7f5F20`;
  Hedera Credible PayFi Vault `0x6b8dfA6aa5f803a886Beb2492eF3307EC0Ee16FB` (DL total $2,093,356).
- **Verdict:** **P** — value moves through a queued withdrawal (`RequestWithdrawal` →
  `ProcessWithdrawals`) and admin config; deposits/invest are whitelist-gated
  (`PoolNotWhitelistedForInvest`). Users' exits are queue-based (**H-O**). No unprivileged path found.
  Confidence medium.

---

## Negative results (do not re-check)
- O16: no plain-wallet custody; all custody is program-PDA. No permissionless `Withdraw*`.
- O17: no Loyal program exists — adapter is per-user Squads/Kamino self-custody.
- O20: the adapter's owner is a *program-controlled* PDA; the ATA was resolved and the balance
  matches DL (the "0 balance" I first saw was a publicnode `getTokenAccountsByOwner` **block**, not
  an empty account — corrected by re-reading via `api.mainnet-beta`).
