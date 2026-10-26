# P7-LOW-5 — ApeChain instant-governance / drain-name / public-init cluster (target #5)

**Date:** 2026-10-26 · **Chain:** ApeChain (chain id 33139) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions sent**

> Verdict: **the pass7 flags (instant governance, unguarded drain, public init) are FALSE POSITIVES.**
> An external, unprivileged attacker can extract **$0.00** live. Every value-moving path on all four
> targets is either `onlyOwner` (a Safe / EOA), a self-service claim of the caller's *own* deposit, or a
> server-signature-gated player action. No public initializer is reachable.

---

## 1. TL;DR

| # | Target (ApeChain) | Live native balance | Extractable by unprivileged attacker | Why closed | Latent risk |
|---|---|---|---|---|---|
| 1 | APEPredicts `0xF609…9f75` | 30,921.24 APE (~$3,895) | **$0** | OZ `Ownable`; `withdraw/resolveGame/cancelGame/updateFeePercentage/pause` are `onlyOwner` (EOA). `deposit()` is public but only *adds* to pools; `claim()/refund()` pay the caller's **own** deposit only (deposit mapping zeroed before transfer). | Low — owner EOA key compromise |
| 2 | House (old, migrating) `0x2054…8469` | 15,103.49 APE (~$1,903) | **$0** | `migrator != 0` ⇒ `deposit()`/`withdraw()` revert `"Migration In Progress"`. `migrate()` burns **only the caller's own** `userInfo[msg.sender].balance` and forwards it to the new House via the migrator. Zero-balance attacker reverts `"Zero Balance"`. | None |
| 3 | CashOrCrash `0x8c63…8517` | 17,349.90 APE (~$2,186) | **$0** | `initialize()` guarded by immutable `_initOwner` **and** already initialized (reverts `InvalidInitialization`). `withdrawFunds`/`addAdmin`/`setMessagePrefix` `onlyOwner` (EOA). `cashOut`/`markGameAsLost` require `isAdmin[msg.sender]` or the game's player + a valid server ECDSA signature. | Low — owner EOA / server key compromise |
| 4 | GovernanceManager `0x8632…6b8a` | 0 APE | **$0** | No voting contract. All setters (`changeOwner`, `setHouse`, `setPaused`, `setRNG`, `setIsAdmin`, …) are `onlyOwner`. Owner is a **2-of-4 Gnosis Safe 1.3.0** `0xb5C3…0c52`. | None (multisig) |

**Context (not a target):** the current House `0xB7Ec…C2f1` holds 10,120,640.39 APE (~$1.27M); it is an
open, holder-owned bankroll (deposit open, `withdraw` burns the caller's own shares) — not extractable by
an attacker.

## 2. Total live extractable now: **$0.00** (confidence: **high**)

No unprivileged call path moves value to an attacker on any of the four targets at block 53,009,900.
The only public value-transfer functions are self-scoped (`APEPredicts.claim/refund`, `House.migrate`,
`House.withdraw`) and can only ever return what the caller already owns.

## 3. The claimed bug(s), in exact terms

Pass-7 flagged this cluster for (a) "instant governance", (b) a drain-name function, and (c) a public
initializer. Each is refuted against the deployed, verified source:

* **Instant governance (refuted).** `GovernanceManager` has **no** proposal/vote/execute machinery. It is a
  constructor-ownable registry: `constructor(address owner_) { _owner = owner_; }` and every setter is
  `modifier onlyOwner { require(msg.sender == _owner, 'Only Owner'); }`. `owner()` is the Gnosis Safe
  `0xb5C3…0c52` (threshold **2 of 4**). Nothing is instant or attacker-reachable.
* **Drain-name (refuted).** `APEPredicts.withdraw(uint256)` is `onlyOwner`; `CashOrCrash.withdrawFunds(...)`
  is `onlyOwner`; `House.withdraw(uint256)` is gated by `migrator == 0` and by the caller's own shares.
  There is no public "withdraw/sweep/drain" entrypoint.
* **Public init (refuted).** `CashOrCrash.initialize(string)` is declared `public initializer`, but it is
  unreachable: the OZ 5 `initializer` modifier short-circuits an already-initialized contract with
  `InvalidInitialization()` (verified on-fork), and even on a never-initialized instance the body's
  `if (msg.sender != _initOwner) revert NotInitOwner();` blocks any non-deployer (`_initOwner` is an
  **immutable** set in the constructor).

## 4. Live-state assessment (block 53,009,900; keyless public RPC)

| Read | Value |
|---|---|
| `APEPredicts.owner()` | `0xd5d013cef20373839635Fbce206A1cf0054EC565` (EOA, code 0 bytes) |
| `APEPredicts.paused()` / `gameCount()` | `false` / `292` |
| `GovernanceManager.owner()` | `0xb5C3a66741E21CD80eBdDa25479B10A98Ea80c52` (Safe 1.3.0) |
| Safe `getOwners()` / `getThreshold()` | 4 owners (`0x6927…26fC`, `0x0d69…FE40`, `0x9Ae1…a98a`, `0x7B05…903E`) / `2` |
| `GovernanceManager.house()` / `paused()` | `0xB7EcD1F3fA462d2c6c65F55357E8c16c614CC2f1` / `false` |
| `House(old).migrator()` / `totalShares()` / `calculatePrice()` | `0xaB9b…69DC` / 7,631.5369053564e18 / 1.979089e18 |
| `House(new).migrator()` / `totalShares()` | `0x0` / 4,617.0330763356e24 |
| `CashOrCrash.owner()` / `gameCounter()` / `messagePrefix()` | `0x1fFc20b99E1f4D0319c08d3bbb6B1ca92Db316f8` (EOA) / 1,090,674 / `"cash-or-crash-apechain"` |
| `Migrator.v1House()` / `houseV2()` | `0x2054…8469` / `0xB7Ec…C2f1` |

Balances (native APE, block 53,009,900): APEPredicts `30921240820561351899689`; House(old)
`15103490884967885395647`; CashOrCrash `17349900118694330300000`; GovernanceManager `0`;
House(new) `10120640389818373981453097`. Price: **APE = $0.12596879** (DefiLlama `coingecko:apecoin`,
confidence 0.99). Raw evidence: `analysis/evidence.json`, `analysis/state_dump.json`,
`analysis/apepredicts_games.json`.

## 5. What an attacker can / cannot do

* **APEPredicts.** Can `deposit(gameId, option)` (spends the attacker's own APE, needs an approved,
  unexpired, unlocked game). Cannot `claim`/`refund` without an own deposit; cannot `withdraw`,
  `resolveGame`, `cancelGame`, `updateFeePercentage`, `pause` (all revert `OwnableUnauthorizedAccount`).
* **CashOrCrash.** Cannot `initialize` (reverts `InvalidInitialization`); cannot `withdrawFunds`,
  `addAdmin`, `setMessagePrefix` (revert). `cashOut`/`markGameAsLost` need an admin signature or a server
  signature bound to `(prefix, gameId, amount/state, gameSeed, deadline)` and to the game's player.
* **GovernanceManager.** Every setter reverts `"Only Owner"`. Owner unchanged after attack.
* **House (old).** `deposit()`/`withdraw()` revert `"Migration In Progress"`; `migrate()` with 0 balance
  reverts `"Zero Balance"`; `transfer()` is a no-op unless `recipient == msg.sender` (then it calls the
  blocked `withdraw`). An attacker cannot acquire shares.

Costs: no flash loan, capital, or gas-bearing exploit exists — there is no profitable path, so net
profit is undefined at $0.

## 6. PoC / fork verification

* Project: `poc/` (Foundry, solc 0.8.24, cancun). Forks ApeChain via
  `vm.createSelectFork(vm.envOr("APE_RPC_URL", "https://rpc.apechain.com/http"))` — the CI workflow does
  not inject an ApeChain RPC, so the keyless public fallback is used.
* Tests: **17 / 17 PASS** — `test/ApeChainGov.t.sol`.
  Negatives asserted: `APEPredicts.withdraw/resolveGame/cancelGame/updateGameStatus/pause/updateFeePercentage`
  from a non-owner revert; `claim/refund` without own deposit revert; `CashOrCrash.initialize` from a
  non-deployer reverts `InvalidInitialization` (owner/isAdmin/counter unchanged); `GovernanceManager`
  `changeOwner/setHouse/setPaused/setRNG/setIsAdmin/setFeeReceiver` revert `"Only Owner"`;
  `House.deposit`/`withdraw` revert `"Migration In Progress"`; `House.migrate` from 0 balance reverts
  `"Zero Balance"`; donation to the House raises price for holders only and gives the attacker nothing;
  final `test_attacker_cannot_gain` asserts attacker net balance delta == 0.
* **CI run (GitHub Actions, `artsbykriss/ca-zombie-ci`, branch `apechain-gov`):**
  https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40232585629 — conclusion **success**,
  `Suite result: ok. 17 passed; 0 failed`, artifact `result-apechain-gov` (CI-side state dump at block
  53,012,629).

## 7. Verdict & residual risk

External unprivileged extraction is **$0** (high confidence). Residual/latent risk is purely
privileged: the APEPredicts and CashOrCrash owner EOAs and the CashOrCrash server signer key, and the
2-of-4 Safe controlling the House/GovernanceManager. No frozen/blacklisted assets; no paused path blocks
recovery.

## 8. Categories (USD @ APE $0.12596879)

* **E-U (attacker): $0.00**
* **H-O (holders, self-service): $1,902.57** — House(old) 15,103.49 APE, migratable by its share holders.
* **P (privileged/operator): $6,080.66** — APEPredicts 30,921.24 APE (owner `withdraw`/`resolveGame`) +
  CashOrCrash 17,349.90 APE (owner `withdrawFunds`, or server-signed player cash-out).
* **S (stuck): $0.00**

Caveat: `APEPredicts` users can self-`claim` winnings for already-resolved games, so part of the "P"
bucket is effectively H-O; an exact split is not derivable on-chain because `game.totalPoolA/B` are not
decremented on claim (the contract balance, not the struct pools, is the truth).

## 9. Methodology, caveats, files

Read-only `eth_call` at a pinned block; deployed verified sources in `analysis/*.sol`; foundry fork PoC.
Caveats: block-pinned state (53,009,900); APE price is a point-in-time DefiLlama quote; the House(old)
holder set was read via Blockscout (EOA holders exist, so migration is live). Files:
`analysis/evidence.json`, `analysis/state_dump.json`, `analysis/apepredicts_games.json`,
`analysis/enumerate_games.py`, `analysis/build_evidence.py`, `poc/`, `ci/run.sh`, `ci-artifacts/`,
`summary.json`.
