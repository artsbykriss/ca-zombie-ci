# Circle Wrapped Bitcoin (cirBTC) — custodial, permissioned-mint token (E-U $0)

**Date:** 2026-10-25 · **Chain:** Ethereum (1) (natively issued on Ethereum + Arc) · **Status:** read-only
research; PoC fork-verified only; **no mainnet transaction was ever sent/signed**.

**Scope (pass-7 `fresh-deep` fast-growing axis):** cirBTC was flagged as a fast-growing fresh deployment
(DefiLlama TVL ≈ **$37.59M**, `+432 %/7 d`). Mandate: *confirm the mint is permissioned (no permissionless
release) and close it as custodial if so.*

**Answer: confirmed.** cirBTC is Circle's **FiatTokenV2_2** token (the exact USDC/EURC architecture) behind a
`FiatTokenProxy`. **Minting is permissioned** to a Circle `MasterMinter`/minter-allowance system, the BTC
backing is held in **Circle custody**, and every privileged path is role-gated. An external unprivileged
attacker can extract **$0**. The residual is **P** (Circle keys / upgradeable proxy, no timelock) and the
**custodial/H-O** nature of redemption (KYC'd Circle Mint customers only).

---

## 1. TL;DR

| Target | Live extractable (external, unprivileged) | Why closed | Latent / non-E-U risk |
|---|---|---|---|
| cirBTC token `0x72DFB2E4…` (FiatTokenProxy → FiatTokenV2_2) | **$0** | `mint` is `onlyMinters` + `minterAllowance`; `configureMinter` is `masterMinter`; role changes are `owner`; `pause`/`blacklist` are `pauser`/`blacklister`; `rescueERC20` is `owner`; `upgradeTo` is proxy-admin. No permissionless mint/release. | **P:** proxy admin + owner are **EOAs** (no multisig, **no upgrade timelock**); a compromised minter/attester key could mint unbacked cirBTC. **H-O/custodial:** redemption requires a KYC'd Circle Mint account, so retail holders cannot arbitrage a depeg. |

**Total live extractable now: $0.00. Confidence: HIGH** (verified deployed source + 9 fork tests).

---

## 2. What cirBTC is, in exact terms

* **Token:** `0x72DFB2E44f59C5AD2bAFE84314E5b99a7cd5075E` — `FiatTokenProxy` (proxy-admin slot
  `keccak256("org.zeppelinos.proxy.admin")`) delegating to implementation
  `0x43506849D7C04F9138D1A2050bbF3A0c054402dd` = **`FiatTokenV2_2`** (verified; 23,464 B). `name =
  "Circle Wrapped Bitcoin"`, `symbol = "cirBTC"`, `decimals = 8`, `version() = "2"`, `paused = false`.
* **Mint authority:** `mint(to, amount)` requires `msg.sender` to be a minter **and**
  `minterAllowance[msg.sender] >= amount`. Minters and allowances are configured by the
  **`MasterMinter`** contract `0xC0Cc159c07a99EeCC35C36f25fE7C1Aeeb3587A2` (verified `MasterMinter`,
  owner `0x51834D9b4B25c470aeA8D54F800a18Db2dA42256`). 13 unique minters have been configured (29
  `MinterConfigured` events); the sample minter `0xF2E21385…` currently holds a 0.00028217 cirBTC allowance.
* **Roles:** `owner 0xd5015499…`, `masterMinter 0xC0Cc159c…`, `pauser 0xabde92e0…`,
  `blacklister 0xb5BE9AfA…`; proxy admin `0xC9cEe9ef…`. Owner, pauser, blacklister and proxy admin are
  **EOAs** (codesize 0).
* **Backing / redemption:** 1:1 native BTC held in custody by Circle International Bermuda Limited (CIBL);
  mint/redeem run through **Circle Mint** for KYC'd institutions. Chainlink Proof-of-Reserve and CCTP
  support are planned, not live.

**On-chain supply at the snapshot block:** `totalSupply = 848.7027121 cirBTC` (≈ **$68.3M** at
$80,445/BTC; ≈849.00 by 2026-10-26 — supply is growing). Note: DefiLlama's `$37.59M` implies a ~$44.2k
BTC price at the same supply, i.e. a DefiLlama chain-level price lag; it does not change the verdict.

---

## 3. What an attacker can / cannot do (live `eth_call` probes at block 26,272,008)

| Call (as an unprivileged attacker) | Result |
|---|---|
| `mint(attacker, 1e8)` | **revert** `FiatToken: caller is not a minter` |
| `configureMinter(attacker, max)` / `incrementMinterAllowance(max)` | **revert** (`caller is not the masterMinter` / minter gate) |
| `removeMinter(...)` | revert (masterMinter) |
| `updateMasterMinter` / `updateOwner` / `updatePauser` / `updateBlacklister` | **revert** `Ownable: caller is not the owner` |
| `pause()` / `unpause()` | **revert** `Pausable: caller is not the pauser` |
| `blacklist()` / `unblacklist()` | **revert** `Blacklistable: caller is not the blacklister` |
| `rescueERC20(token, amt)` | **revert** (owner-gated) |
| `upgradeTo(...)` on the proxy | **revert** (proxy admin only) |
| `burn(amt)` with 0 balance | **revert** (own balance only; reduces supply, never extracts) |
| `transfer` / `transferFrom` / `approve` / `permit` / `transferWithAuthorization` | only the caller's own funds (standard ERC-20 / EIP-2612 / EIP-3009) |

**No permissionless call increases an attacker's cirBTC balance.** The mint is the only issuance path and it
is minter-gated; there is no "release" function at all (cirBTC is natively issued, not bridged from an
escrow, so there is no lock/release contract to attack).

---

## 4. PoC / fork-verification

Foundry project `poc/` (vendored `forge-std`; Ethereum fork at block 26,272,008). **9/9 tests pass:**
`test_token_is_circle_fiat_token_v2_2_proxy`, `test_roles_are_nonzero`, `test_attacker_cannot_mint`,
`test_attacker_cannot_configure_a_minter`, `test_attacker_cannot_change_roles`,
`test_attacker_cannot_pause_or_blacklist_or_rescue`, `test_attacker_cannot_upgrade_the_proxy`,
`test_attacker_with_zero_balance_cannot_burn`, `test_mint_requires_a_funded_minter_allowance`.

CI: `bash /home/heisenberg/CA/ci/ci-run.sh cirbtc` → `forge test -vvv` (run URL in `summary.json`).

---

## 5. Verdict, residual risk, caveats

* **E-U: $0.00 (high confidence).** Custodial, permissioned-mint; not an unprivileged attack surface.
* **P:** Circle holds every privileged role. The **proxy admin and owner are EOAs with no upgrade timelock**
  (noted by LlamaRisk in the Aave onboarding assessment), so a key compromise or an unauthorised upgrade is
  the real risk — a centralisation risk, not an E-U bug.
* **H-O / custodial:** redemption is restricted to verified Circle Mint customers; if cirBTC trades below its
  BTC backing, non-eligible holders cannot redeem directly.
* **Caveats:** point-in-time 2026-10-25; supply/roles can change; source is the explorer-verified deployed
  bundle; the DefiLlama TVL figure differs from on-chain supply as noted. All work read-only; the PoC runs
  only on an in-memory fork.

**Files.** `README.md` · `summary.json` · `analysis/live-state.json` · `poc/` (Foundry, 9 tests) · `ci/` ·
`ci-out/`, `ci-log.txt`, `ci-artifacts/`.
