# NOXA Fun — LaunchLocker fee-auth & principal-lock review

**Date:** 2026-10-19/20 · **Chains:** Robinhood Chain (4663) primary; Monad (143), MegaETH, Arc, Stable, Intuition, Merlin
**Status:** read-only; fork-verified only; **no mainnet transactions signed or sent**; public RPCs only.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Live external-unprivileged extraction (E-U) | **$0.00** |
| Confidence | **High** (verified source + 6/6 fork tests + live `eth_call` reverts) |
| Is the $3.9M LP principal at risk? | **No** — the locker has no function that transfers the NFTs, decreases liquidity, or sweeps principal. Principal is **locked forever by design** (not a bug). |
| Is there a fee-theft path? | **No** for a fresh caller. `collectFees` is gated to `owner`, the token's `deployer`, or a registered `feeCollector`; `setFeeRedirect` is gated to the token's `deployer`; `setFeeCollector` is `onlyOwner`. |
| What is actually at risk? | **P (owner-key):** all unclaimed LP fees, ~**12.6 WETH ≈ $30.4k** (sample estimate), plus the protocol manager's 29.79 ETH (~$71.7k) treasury. **No E-U.** |
| Worst case if the owner EOA is compromised | Protocol fees can be redirected to an attacker (`setProtocolFeeRecipient` + `setFeeCollector` + `collectFees`). This is a key-custody/governance risk, not an unprivileged path. |
| Principal (locked by design) | **$3,934,698** total DefiLlama TVL across 7 chains; **$3,903,181** on Robinhood Chain. 60,142 UniV3 position NFTs held by the locker. |

**Headline:** the pass-2 lead's "auth ambiguity" is resolved by the verified source — the `collectFees` gate is exactly `owner || deployer || feeCollectors[msg.sender]`, and the only registered fee collector is the protocol's own manager. **E-U = $0.** The locker is a one-way fee harvester with permanently locked principal.

---

## 2. Mechanism (deployed code)

The Robinhood Chain locker [`0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85`](https://robinhoodchain.blockscout.com/address/0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85) is **source-verified on Sourcify** (`runtimeMatch: match`, `solc 0.8.30`, `viaIR`, optimizer 200). The same runtime code hash (`sha256: 5124fdbb984a6eb3…`, 4,823 bytes) is deployed at all seven DefiLlama locker addresses, so the logic below applies to every chain.

Key functions (`contracts/LaunchLocker.sol`):

```solidity
function collectFees(address token) external nonReentrant {
    LaunchedToken memory launched = ILaunchFactory(factory).getLaunchedToken(token);
    if (!launched.exists) revert TokenNotFound();
    if (msg.sender != owner() && msg.sender != launched.deployer && !feeCollectors[msg.sender])
        revert NotAuthorized();
    ...
    address recipient = feeRedirects[token] != address(0) ? feeRedirects[token] : launched.deployer;
    // protocolFeeShare% -> protocolFeeRecipient; remainder -> recipient
}

function setFeeRedirect(address token, address recipient) external {
    ...
    if (msg.sender != launched.deployer) revert NotDeployer();
    feeRedirects[token] = recipient;
}

function setFeeCollector(address collector, bool status) external onlyOwner { ... }
```

- `collectFees` **never pays the caller**. It pays `protocolFeeRecipient` and the token's `deployer`/`feeRedirects[token]`.
- `setFeeRedirect` cannot be called by a third party for someone else's token.
- `lockPosition` is `NotFactory`-gated; `onERC721Received` only accepts NFTs from the factory.
- **There is no `withdraw`, `redeem`, `decreaseLiquidity`, `transferFrom`, `safeTransferFrom`, `approve`, or `sweep` function.** The locker is not a proxy; it cannot be upgraded.

The factory [`0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB`](https://robinhoodchain.blockscout.com/address/0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB) is unverified, but its public launch path (`0x686399cb`) creates the token/position and calls the locker; the locker's `getLaunchedToken` record always points at the canonical NPM `0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3` (all **526** sampled `PositionLocked` events, 61,687–2,976,546). A fresh caller cannot inject an arbitrary `positionManager`/`positionId` into the locker.

---

## 3. Live state (read on-chain)

Primary read block: **Robinhood Chain 93,005,273** (CI, 2026-10-19 23:34 UTC). Local analysis block 92,977,747; both give the same state.

| Item | Value |
|---|---|
| Locker | `0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85` (code 4,823 B, verified) |
| Factory | `0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB` |
| Owner | `0x7E035Fb048a31e0481b88074557415b1C187242B` — **EOA** (code size 0; 0.0488 ETH) |
| `protocolFeeShare` | **100** (all fees to the protocol recipient) |
| `protocolFeeRecipient` | `0x9eFdC1A8e6E94f16A228e44f3025E1f346EE0417` — `NoxaManagerV116` Yul contract (verified, 7,726 B; 29.79 ETH) |
| `feeCollectors(0x9eFd…)` | **true** — the only registered collector |
| `feeCollectors(0x1111…)` | false |
| Locked NFTs | **60,142** UNI-V3-POS NFTs (`NPM.balanceOf(locker)`) |
| Sample position 212 (token `0x77Bd…Dcc2`) | `ownerOf(212) = locker`; `getApproved(212) = 0x0` |
| Position manager in 526 sampled locks | `0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3` (100%) |
| Paired token in 526 sampled locks | WETH `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` (100%) |

### Auth probes at the same block (all `eth_call`, no tx)

| Call from `0x1111…` | Result | Meaning |
|---|---|---|
| `collectFees(0x77Bd…)` | **`NotAuthorized`** | closed |
| `setFeeRedirect(0x77Bd…, 0x1111…)` | **`NotDeployer`** | closed |
| `lockPosition(0x77Bd…)` | **`NotFactory`** | closed |
| `setFeeCollector(0x1111…, true)` | **`OwnableUnauthorizedAccount(0x1111…)`** | closed |
| `NPM.transferFrom(locker, 0x1111…, 212)` | **`ERC721: transfer caller is not owner nor approved`** | principal closed |

The owner calling `collectFees(0x77Bd…)` at the same block returned `NoFeesToCollect` — the protocol keeper (`0x9eFd…`) had just harvested that token. This is not a stale state: `FeesClaimed` has **90,429** events from block 70,236 to 92,960,011, with **88,854** calls by `0x9eFd…` (the protocol manager) and 644 unique callers (mostly token deployers). Fees are actively collected, so the live unclaimed pot is only the accrual since the last per-token harvest.

### Multichain footprint (same code hash)

| Chain | Locker | Owner | `protocolFeeShare` | TVL (DefiLlama) |
|---|---|---|---|---|
| Robinhood | `0x7F03…cD85` | `0x7E03…242B` (EOA) | 100 | **$3,903,181** |
| Monad | `0x2e98…68c0` | `0x7E03…242B` | 100 | $3,438 |
| MegaETH | `0x93e7…4733` | `0xC312…bE03` | 0 | $2,176 |
| Arc | `0x6309…E0A4` | (RPC unavailable) | — | $21,168 |
| Stable | `0xc28E…0022` | `0x1Db1…8E3E` | 0 | $2,044 |
| Intuition | `0x120C…8dAD` | `0x7E03…242B` | 0 | $108 |
| Merlin | `0x7c6a…52c3` | `0x1Db1…8E3E` | 0 | $2,584 |

`pfs = 0` on four chains means the token deployer gets 100% of that token's fees; a fresh caller still cannot collect them. TVL there is $2k–$2.6k, so the economics do not change.

---

## 4. Fee-pot quantification (the only live value)

With `protocolFeeShare = 100`, **all** LP fees go to `0x9eFd…` (the protocol manager), not to the caller. To quantify what an owner-key compromise could capture (P), a 120-position random sample of the 46,198 fee-bearing tokens was collected in simulation (`NPM.collect` from the locker, `eth_call`):

- 11/120 positions had nonzero WETH-side fees; total **0.0251736548 WETH** in the sample.
- Scaled to 60,142 positions: **≈12.62 WETH ≈ $30.4k** at ETH $2,407 (Blockscout rate 2026-10-19).
- The remaining fees are meme tokens with near-zero USD value; the WETH side is the economically meaningful part.
- The protocol manager `0x9eFd…` additionally holds **29.79 ETH (~$71.7k)** plus harvested tokens. Its `routeFees` (`0x06ec16f8`) reverts for a fresh caller while `protocolFeeShare == 100 && protocolFeeRecipient == manager`; its native sweep (`0xab803a76`) reverts `OwnableUnauthorizedAccount` for `0x1111…`; `setTreasury`/`setProtocolShare` are owner-gated. This is protocol treasury, not an unprivileged pot.

**E-U = $0.00.** The fee pot is **P** (owner key / protocol manager), not E-U.

---

## 5. What an attacker can / cannot do

**Cannot:**
1. Call `collectFees` — reverts `NotAuthorized` (fork test 1).
2. Redirect a token's fees — `setFeeRedirect` reverts `NotDeployer` (fork test 2).
3. Register as a fee collector — `setFeeCollector` reverts `OwnableUnauthorizedAccount` (fork test 3).
4. Lock/claim an arbitrary position — `lockPosition` reverts `NotFactory`; the factory record always points at the canonical NPM (fork test 4).
5. Move the NFTs — no transfer/approve function exists on the locker; the position manager rejects a third-party `transferFrom` (fork test 5).
6. Withdraw principal — no `decreaseLiquidity`, `collect` only harvests fees, and the locker never approves the NPM for NFT transfers (`getApproved = 0`).

**Can:**
- Launch their own token through the factory and collect **their own** token's fees (legitimate deployer path; with `pfs=100` on RH, the protocol takes all, so even this yields $0 on RH).
- Buy/sell the launched tokens; nothing in the locker is affected.

**The only privileged paths (P):**
- Owner EOA `0x7E03…` can `setProtocolFeeRecipient(attacker)` + `setFeeCollector(attacker)` and call `collectFees` for every token → captures the ~$30.4k fee pot (and could sweep the manager's 29.79 ETH to its treasury). This is a single EOA key, 0.0488 ETH balance, no multisig/timelock.
- Owner can `setProtocolFeeShare(0)` to divert future fees to token deployers (not to itself).
- The factory owner is the same EOA; a factory upgrade/redeploy could change the launch flow, but the current locker's `factory` is immutable and the code is not a proxy.

---

## 6. PoC / fork verification

**Project:** `noxa-fun/poc/` (Foundry, vendored forge-std). **6/6 tests PASS** on GitHub Actions.

| Test | Result | What it proves |
|---|---|---|
| `test_locker_state` | PASS | factory, pfs=100, pfr, only fee collector, 60,142 NFTs, position 212 owned by locker, no approval |
| `test_collectFees_random_reverts` | PASS | `NotAuthorized` |
| `test_setFeeRedirect_random_reverts` | PASS | `NotDeployer` |
| `test_lockPosition_random_reverts` | PASS | `NotFactory` |
| `test_setFeeCollector_random_reverts` | PASS | `OwnableUnauthorizedAccount` |
| `test_nft_cannot_be_transferred_by_attacker` | PASS | ERC721 transfer rejected |

- CI run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39342348361** (`conclusion: success`; artifact `result-noxa-fun`).
- Live state capture: `ci-out/state.json` (artifact), block **93,005,273**.
- Gas for the gated calls: 30k–74k (a failed call is cheap; there is no profitable call to make).

---

## 7. Verdict, residual/latent risk, blockers

**Verdict:** **E-U $0.00 (high confidence).** The pass-2 "auth ambiguity" is closed: the verified `collectFees` gate is `owner || deployer || feeCollectors[msg.sender]`; the only collector is the protocol manager; fees are paid to the protocol/deployer, never to the caller. The $3.9M is LP principal, and the locker has no exit function for it.

**Residual/latent:**
- **P — owner key:** one EOA controls the fee recipient, fee collector, protocol share and the factory. A key compromise could capture the ~$30.4k unclaimed fee pot and the protocol manager's 29.79 ETH. No multisig/timelock observed.
- **P — protocol manager:** `0x9eFd…` is a 7,726-byte Yul contract with the same EOA owner; its `sweep` is `onlyOwner`. This is protocol treasury risk, not user funds.
- **S — principal:** $3,903,181 on RH (60,142 NFTs) is **permanently locked by design**. Nobody — including the team — can withdraw it. Do not count it as "at risk"; count it as "locked".
- **Fees:** the live fee pot is small and continuously harvested; the worst case for a fee-only bug is ~$30k, not $3.9M.

**Re-arm triggers (when this verdict could change):**
1. `feeCollectors` gains an address that is a public contract or a compromised EOA (monitor `FeeCollectorUpdated`; currently exactly one event, collector `0x9eFd…`).
2. The owner EOA `0x7E03…` is compromised or transfers ownership (monitor `OwnershipTransferred` on the locker/factory/manager).
3. A new locker version/factory appears with a `withdraw`/`decreaseLiquidity`/NFT-transfer function, or the factory starts accepting a caller-supplied `positionManager`/`positionId`.
4. `protocolFeeShare` changes away from 100 **and** a fee collector is added that pays `msg.sender`.
5. A token deployer is a public contract exposing a callable `setFeeRedirect`/`collectFees` (would let anyone redirect that token's fees, but still only that token's fees).

---

## 8. Methodology, sources, caveats, files

**Method:** DefiLlama adapter → 7 locker addresses; Sourcify verified source (`runtimeMatch: match`); live `eth_call`/`eth_getLogs` at named blocks; full event history for admin events; 90,429 `FeesClaimed` and 4,150 `PositionLocked` logs; 120-position `collect` simulation; multichain code-hash/owner/pfs comparison; Foundry fork PoC on RH.

**Sources:** Sourcify contract `4663/0x7F03…cD85`; Robinhood Blockscout; DefiLlama `noxa-fun` adapter and protocol JSON; public RPC `https://rpc.mainnet.chain.robinhood.com`; GitHub Actions run above.

**Caveats:**
- DefiLlama TVL is its adapter's estimate (base-token side of single-sided UniV3 positions, doubled); it is not a realized liquidation value. The principal is illiquid and permanently locked regardless.
- The 12.6 WETH fee estimate is a 120-position sample (11 nonzero), scaled to 60,142; the true pot varies with the keeper's harvest schedule. It is an order-of-magnitude figure, not an exact claim.
- Arc RPC was unavailable; its $21k TVL is not verified. Other chains' TVLs are small.
- The factory is unverified; its launch path was inferred from the verified locker interface + 526 decoded `PositionLocked` events, all using the canonical NPM.
- No mainnet transaction was sent; all "attacker" calls are `eth_call`/fork simulations.

**Files:**
- `README.md` (this file), `summary.json`
- `analysis/src/contracts_LaunchLocker.sol` — verified locker source
- `analysis/src/rh_locker_sourcify.json`, `rh_factory_dec/` — verified metadata + factory decompilation
- `analysis/logs_rh_locker_summary.json` — counts, admin events, fee/position samples
- `analysis/fee_sample_rh.json` — 120-position collect simulation
- `analysis/lockers_multichain.json` — 7-chain code hash/owner/pfs
- `poc/test/NoxaAuth.t.sol` — 6 fork tests
- `ci/run.sh`, `ci-out/state.json` — live state capture
- `ci-log.txt`, `ci-artifacts/` — CI log and artifact
