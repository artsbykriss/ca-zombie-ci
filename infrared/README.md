# Infrared iBERA (Berachain) — unprivileged-extraction assessment

**Finding:** P4-04 · **Chain:** Berachain (80094) · **Date:** 2026-10-22
**Status:** read-only research; PoC fork-verified only; **no mainnet transaction was signed or sent.**
**Target:** `0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5` → implementation
`0xC0654903c7d76F7FE63f9AD2F01618c3B55D9DcF`
**Primary snapshot block:** 27 827 865 (`0x1a89e99`); secondary reads at 27 828 198.

---

## 1. TL;DR

| # | Target | Live extractable by an unprivileged attacker | Why closed | Latent risk |
|---|---|---|---|---|
| 1 | iBERA LST proxy `0x9b6761bf…` (impl `0xC0654903…`) — **$14.20 M** of BERA backing (84 122 523.8 BERA) | **$0** | Every value-moving path is either **governance-gated** (`AccessControlUnauthorizedAccount(_, GOVERNANCE_ROLE)`), **keeper-gated**, **fixed-caller-gated**, or **self-scoped** (`mint` requires `msg.value`; `burn` burns the caller's own iBERA). The implementation is Etherscan-**verified** and proven byte-identical to the public source (see §6). | 3-of-6 Safe upgrade key; ungated (benign) `Receivor.sweep()`; `mint()` not `whenNotPaused` |
| 2 | Infrared core `0xb71b3DaE…` (impl `InfraredV2` `0xd9ce49e4…`) | **$0** (holds 0.0099 BERA) | `redeemIbgtForBera` = `onlyKeeper`; `claimExternalVaultRewards` = `Unauthorized`; setters/`upgradeToAndCall` = `onlyGovernor` | governance |

## 2. Total live extractable now: **$0.00** (confidence **high**)

| Category | USD | Note |
|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | no reachable path; gate proven on-chain + fork-verified |
| **H-O** (holder-only recoverable) | **$0.00** | nothing stuck; normal LST redemption is operational (queue → keeper `process` → `claim`) |
| **P** (privileged/governance) | **$11.34** | 63.5098 iBERA of accrued exit fees sitting in the proxy, claimable only by `claimExitFees()` (`onlyGovernor`) |
| **S** (stuck/bricked) | **$0.00** | — |

> **TVL for context, not a finding:** `totalAssets()` = 84 122 523.818 BERA = **$14 200 709.25**
> at BERA **$0.16880983** (DefiLlama `coins.llama.fi`, ts 1792670220). DefiLlama's
> `infrared-finance` figure of ≈$19.0 M is the same BERA amount priced at ≈$0.226. This is a
> **functioning** liquid-staking token: the backing is staked on the Berachain consensus layer and
> is only reachable pro-rata by iBERA holders through the documented withdrawal queue. It is *not*
> extractable, and it is *not* stuck.

---

## 3. The mechanism, in exact terms

`0x9b6761bf…` is **not** a deposit vault (as the pass-4 lead suggested) — it is the
**iBERA liquid-staking token** (`name() = "Infrared BERA"`, `symbol() = "iBERA"`, 18 decimals),
an OZ **ERC1967Proxy** (163 B, OZ v5.1.0) whose implementation is a **UUPS** contract
(`UPGRADE_INTERFACE_VERSION() == "5.0.0"`). EIP-1967 admin slot is **zero** ⇒ no `ProxyAdmin`.

The $14.2 M of BERA backing is **not held in the token contract** (its native balance is `0`):

```
mint{value: V}(receiver)          user BERA  ─►  InfraredBERADepositorV2.queue{value:V}()   ─► CL deposit
burn(receiver, shares)            iBERA      ─►  InfraredBERAWithdrawor.queue(receiver, amt) ─► EIP-7002
                                             ─► keeper process() ─► receiver claim()
compound()/sweep()                EL rewards ─►  deposits += amount (pro-rata to all holders)
```

`totalAssets()` simply returns `deposits`, the protocol's internal ledger of BERA escrowed/staked.
Addresses: Depositor `0x04CddC538ea65908106416986aDaeCeFD4CAB7D7` (impl
`0xe18e88631e0b497180f440ff895981d99bc3e24b`), Withdrawor `0x8c0E122960dc2E97dc0059c07d6901Dce72818E1`
(impl `0x367cbfd767de1452415d24fae29c0fde206bac8d`), Receivor
`0xf6a4A6aCECd5311327AE3866624486b6179fEF97` (impl `0xab2dadd15af962b036d361849c024a3f70b18254`).

---

## 4. Live-state assessment (block 27 827 865 unless stated)

| Item | Value / evidence |
|---|---|
| `name()` / `symbol()` / `decimals()` | `Infrared BERA` / `iBERA` / `18` |
| `totalSupply()` | 79 515 424.296432355153529597 iBERA |
| `totalAssets()` == `deposits()` | 84 122 523.818056978854247603 BERA |
| share price | 1.057939696 BERA/iBERA |
| `asset()` | `0x000…0` (native BERA) |
| `withdrawalsEnabled()` / `paused()` | `true` / `false` |
| `burnFee()` | 0.01 iBERA |
| `feeDivisorShareholders()` | `4` (25 % of EL yield to the protocol) |
| `proofTimestampBuffer()` | 600 s |
| impl code size / codehash | 14 082 B / `0xf1c00f0e9ba3431a2d3c4634d775eecf2b16e7359b88f9e217632da415bd766f` |
| EIP-1967 impl / **admin** / beacon slot | `0x…c0654903…` / `0x00…00` / `0x00…00` |
| native balance of token contract | **0 wei** |
| proxy's own iBERA (accrued exit fees) | 63.50983597134332 iBERA (= $11.34) |
| Depositor / Withdrawor / Receivor / core native | 5 203.5107 / 0.9868 / 0.0668866 / 0.0099 BERA |
| Withdrawor `requestLength` / `requestsFinalisedUntil` / `totalClaimable` | 5140 / 5138 / 0 |
| **`DEFAULT_ADMIN_ROLE` + `GOVERNANCE_ROLE`** | `0x182a31A27A0D39d735b31e80534CFE1fCd92c38f` — **Gnosis Safe v1.3.0, 3-of-6** |
| `KEEPER_ROLE` | `0x242D55c9404E0Ed1fD37dB1f00D60437820fe4f0` (Safe-style contract), `0x0C224f0F468675aD6299f7A93D23a829964a2369` (EOA) |
| `PAUSER_ROLE` | **nobody** ⇒ `pause()` requires `GOVERNANCE_ROLE` |
| revoked keeper | `0x3e08c3728a69ab3804af74f55f500ceedb342ac7` (revoked at block 20 186 293) |
| Safe owners / threshold | `0x438bffBD…`, `0xe5A0Fab1…`, `0xa0AFda6b…`, `0xF3E3f0Dd…`, `0xb56D8669…`, `0xd35E2E0A…` / **3** |

Role holders were enumerated from `RoleGranted`/`RoleRevoked` logs (`getLogs` via Etherscan V2,
chain 80094) and re-confirmed with live `hasRole()` calls.

---

## 5. What an attacker can / cannot do

**Can (all harmless, all cost-only):**
* `mint{value: V}(receiver)` — buy iBERA at the fair, floored, post-`compound()` rate. `mint` with
  `V = 0` reverts `InvalidShares()`; shares ≤ `totalSupply·V/deposits`. Round-trip `mint`→`burn` is
  loss-making (flooring on both legs + 0.01 iBERA burn fee).
* `burn(receiver, shares)` — burn **your own** iBERA and queue a withdrawal to a `receiver` of your
  choice (never the Depositor). With no balance it reverts `ERC20InsufficientBalance`.
* `compound()` / `Receivor.sweep()` — push the Receivor's EL rewards into `deposits` (pro-rata to
  **all** holders). Pays the caller nothing.
* ERC-20 `transfer`/`approve`/`transferFrom` on your own balances/allowances only.
* `renounceRole(role, self)` — a no-op for roles you don't hold.

**Cannot:**
* mint shares without paying `msg.value`; mint at a stale pre-yield price (`compound()` runs first);
* burn or withdraw anyone else's iBERA or BERA (`ERC20InsufficientBalance` /
  `ERC20InsufficientAllowance` / `Unauthorized`);
* call any setter, `pause`/`unpause`, `claimExitFees`, `grantRole`/`revokeRole`,
  `upgradeToAndCall`, `collect`, `sweep`, `register`, `registerViaProofs` — all revert
  `AccessControlUnauthorizedAccount(caller, GOVERNANCE_ROLE|KEEPER_ROLE)`, `NotPauser()` or
  `Unauthorized(caller)`;
* `initialize()` the proxy or the implementation — the deployed revision has **no** `initialize`
  function at all (both proxy and impl revert with empty data), and the impl's constructor ran
  `_disableInitializers()`;
* reach the withdrawal queue directly (`Withdrawor.queue` requires `msg.sender ∈ {iBERA, keeper}`),
  finalise tickets (`process` = `onlyKeeper`) or claim someone else's ticket (`claim` requires
  `ticket.receiver == msg.sender`).

**Cost of any attempt:** one `eth_call` — every candidate path reverts. There is no path requiring
capital, so no flash-loan/rounding cost analysis applies.

---

## 6. PoC / fork verification

Foundry project in `poc/` (vendored `lib/forge-std`; solc 0.8.26; runs via GitHub Actions).

* Fork: anvil fork of Berachain at the **pinned block 27 827 865**, keyless RPC
  `https://rpc.berachain.com` (`vm.createSelectFork`, no secret used).
* `poc/test/InfraredIBERA.t.sol` — **16 tests, 16 PASS** (`forge test -vvv`).
  * `test_A` live state + code identity (asserts `keccak256(impl.code) == 0xf1c00f0e…`, impl/admin slots);
  * `test_B` role holders are the 3-of-6 Safe + 2 keepers, and the attacker holds nothing;
  * `test_C/D` `mint` with 0 value reverts `InvalidShares`; `mint{1 ether}` mints **≤ pro-rata**
    shares, `deposits` and the Depositor balance increase by exactly `sweepAmt + 1 ether`;
  * `test_E/F/G` `burn` reverts `ERC20InsufficientBalance` / `InvalidShares`, cannot redirect anyone's shares;
  * `test_H/I/J/K` every governor setter, `pause`/`unpause`, `grantRole`/`revokeRole`,
    `upgradeToAndCall` revert with the exact OZ/`NotPauser` errors; `initialize()` absent on proxy **and** impl;
  * `test_L` `collect`/`sweep`/`register` revert `Unauthorized(attacker)`; `registerViaProofs` reverts;
  * `test_M` `transferFrom` from the proxy / a keeper reverts `ERC20InsufficientAllowance`;
  * `test_N` `Withdrawor.queue`/`process`/`claim`/`claimBatch` all gated;
  * `test_O/P` the two permissionless entry points (`compound()`, `Receivor.sweep()`) pay the caller **nothing**.

* `ci/run.sh` additionally performs the **byte-exact source-identity proof** and a fresh live-state +
  selector probe, writing `ci-out/`. Result: `byte_exact_match = true` — recompiling the
  Etherscan-verified standard-JSON with solc `v0.8.26+commit.8a97fa7a` (optimizer runs 50,
  evmVersion cancun), linking `BeaconRootsVerify` at `0x49b696528cf0979ed8b13c1e32a9e54f09285416`
  and filling the 3 constructor-set UUPS `immutable __self` slots with `0xC0654903…`, reproduces the
  deployed runtime code **byte-for-byte** (14 082 bytes, metadata hash
  `c031d2f45be36020e3cec9d2d8e46dc215d787607908dfd0c0b0dd211fe8d2bc` on both sides).

**CI runs (public, read-only):**
* `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/PLACEHOLDER_RUN1` — first full run

---

## 7. Verdict and residual / latent risk

**Verdict: E-U $0.00 (closed), confidence high.** The pass-4 lead's residual ("unverified
implementation") is removed: the implementation is verified *and* independently proven
byte-identical to its public source, and every value-moving entry point on it is gated or
self-scoped, proven both by `eth_call` against live state and by fork tests.

Residual / latent risk (none currently extractable by an outsider):

1. **`InfraredBERAFeeReceivor.sweep()` has no auth check.** Anyone may push the Receivor's BERA into
   `deposits`; it pays the caller nothing (the corresponding iBERA is minted to `infrared` by the
   *gated* `collect()`), so this is at most a gas-griefing / ordering nuisance.
2. **`mint()` is not `whenNotPaused`.** Deposits keep working while the system is paused. No value
   loss — the BERA is escrowed in the Depositor and forwarded by keepers — but worth hardening.
3. **`previewBurn()` waives the fee for `msg.sender == rateProvider` while `burn()` does not.** A
   cosmetic preview/execute inconsistency (a BEX pool integrator could under-quote the fee), not a
   fund loss.
4. **Governance is the whole trust assumption.** A 3-of-6 Gnosis Safe holds both `DEFAULT_ADMIN_ROLE`
   and `GOVERNANCE_ROLE` and can `upgradeToAndCall` to arbitrary code. The $14.2 M is **P**-class by
   construction, not attacker-reachable.

**Blockers / caveats:** nothing is frozen, blacklisted or paused today; `withdrawalsEnabled == true`
and `paused == false`.

---

## 8. Methodology & sources

* Live reads: keyless `eth_call` / `eth_getCode` / `eth_getBalance` / `eth_getStorageAt` /
  `eth_getLogs` against `https://rpc.berachain.com` (also cross-checked on
  `berachain-rpc.publicnode.com` and `berachain.drpc.org` — identical revert data).
* Source: Etherscan V2 (`chainid=80094`, `module=contract&action=getsourcecode`) for the proxy, its
  implementation, the Depositor, Withdrawor, Receivor and the `InfraredV2` core; plus the public repo
  `github.com/infrared-dao/contracts@38140b72` (`src/staking/InfraredBERAV2_1.sol`, `diff` empty).
* Selector decoding: `openchain.xyz` + locally recomputed `keccak` of candidate signatures, and the
  verified ABI.
* Role holders: `getLogs` for `RoleGranted`/`RoleRevoked` + live `hasRole`, plus Safe
  `getOwners()`/`getThreshold()`/`VERSION()`.
* Prices: DefiLlama `coins.llama.fi/prices/current`.
* Fork verification: Foundry 1.8.5, anvil fork at a pinned block, on GitHub Actions (public repo
  `artsbykriss/ca-zombie-ci`).

### Caveats & limitations

* Point-in-time: 2026-10-22, block 27 827 865 / 27 828 198. Re-read state before acting.
* USD uses BERA $0.16880983; the headline is $0 so the price only affects the context figure.
* The **implementation** bytecode identity is proven byte-exact. The Depositor/Withdrawor/Receivor
  implementations are Etherscan-verified and their source matches the same public repo modulo a
  `src/interfaces` vs `src/depreciated/interfaces` import-path/licence-header change (different
  revision); they were read in full but not independently recompiled.
* The bytecode proof requires the exact solc build `0.8.26+commit.8a97fa7a` (fetched from
  `binaries.soliditylang.org`); a different 0.8.26 build would change the metadata fingerprint.
* Not attempted: full CL-side validator accounting reconciliation (out of scope — the CL stake is
  not attacker-reachable), and decompilation of the *other* pass-4 unverified impls (Kuru).

---

## 9. Files index

```
infrared/
├── README.md                     this report
├── summary.json                  machine-readable summary
├── analysis/
│   ├── notes.md                  full raw analysis
│   ├── probe.py                  live-state snapshot (views/storage/balances)
│   ├── probe_selectors.py        per-selector unprivileged probe + revert data
│   ├── bytecode_identity.py      byte-exact source↔bytecode proof
│   ├── find_metadata_variant.py  metadata-fingerprint reproduction
│   ├── materialize_verified.py   Etherscan standard-JSON → Foundry project
│   ├── live_state_raw.json, selector_probe_raw.json
│   ├── rolegranted.json, rolerevoked.json
│   └── verified/*.json + verified/src/**   raw getsourcecode records & sources
├── poc/                          Foundry project (foundry.toml, src/, test/, lib/forge-std)
├── ci/run.sh                     live probe + bytecode-identity job
├── ci-out/                       CI job outputs
├── ci-log.txt                    CI log (downloaded by ci/ci-run.sh)
└── ci-artifacts/                 CI artifacts
```
