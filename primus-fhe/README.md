# Primus Confidential Vault (FHE) — BNB Chain (BSC) — unprivileged-extraction deep dive

**Date:** 2026-10-25 · **Chain:** BNB Smart Chain (chainid 56) · **Status:** **read-only** — every
claim below is an `eth_call` / `eth_getCode` / `eth_getStorageAt` against BSC or verified source
read. **No transaction was signed or sent on any real network.** The only executable PoC is a
Foundry fork test (CI).

**Verdict (one line):** the FHE vault stack is correctly gated — there is **no unprivileged
extraction path**; an external attacker can extract **$0**. The ~**$248,434** of live backing is
recoverable only by its confidential-token holders (H-O), and the whole stack (including the
2-of-3 FHE decryption threshold) is controlled by two Primus EOAs plus one keeper EOA.

---

## 1 · TL;DR table

| Target (role) | Address (BSC 56) | Live value now | Why closed / open | Latent risk |
|---|---|---|---|---|
| esUSDu-u converter (holds sUSDu backing for the "u" route) | `0x06776741b1f8bfF5ea51750E91edcf03ed8C6994` | **96,242.263463 sUSDu ≈ $105,864.76** | Unshield requires FHE-ACL handle access + `from==msg.sender`; burn/clamp on balance; transfers pinned to whitelist (`transferRestrictionEnabled()=true`) | owner-upgradeable (UUPS) → **P** |
| esUSDu-usdt converter | `0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d` | **121,457.549211 sUSDu ≈ $133,601.13** | same as above; transfer restriction currently **off** (`false`) but unshield still FHE-gated | owner-upgradeable → **P** |
| eUSDT converter | `0xc2CC9419DDEb3425876091a1eb79D5C59017838c` | **4,060.886564 USDT ≈ $4,057.21** | same | owner-upgradeable → **P** |
| eU converter ("Confidential U") | `0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800` | **4,915.308965 U ≈ $4,911.45** | same | owner-upgradeable → **P** |
| UnitasMintAggregatorConfidential ("u" route) | `0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24` | **~$0** (dust) | `dispatchAggregate`/`dispatchAggregateCallback` = **keeper-only**; `recoverAggregate`/setters = owner-only; `claim` pays the *depositor* | keeper/owner → **P** |
| UnitasMintAggregatorConfidential (USDT route) | `0xE76F5202EF8eEB462eC784Fe51D69E9a8a0b56c1` | **~$0** (dust) | same | **P** |
| UnitasRedeemAggregatorConfidential ("u") | `0xBef1366512ffFF33cdd6C48d66e48D33c6dbCa22` | **~$0** | same | **P** |
| UnitasRedeemAggregatorConfidential (USDT) | `0x485dBFD90DdF92E009438FF49b1918C6636a8f89` | **~$0** (592 µUSDT) | same | **P** |
| UnitasProxy "vault" (backend mint/redeem proxy) | `0xe9E8573Bb351da16c6EE7dDaC0cBC70b7f9784AE` | **~$0** | `mintAndStake`/`redeemAndWithdraw` = `MINT_CALLER_ROLE`/`REDEEM_CALLER_ROLE` | **P** |
| UnitasRewardPool | `0xCfd2917b0D8b83D7EB3a4BA637e0D8a034B7524F` | **$0 U** (budget is confidential eU) | all value paths = `onlyKeeper` | keeper/owner → **P** |
| FHE ACL / FHEExecutor / Decryption / SpaceBridgeConfig | see §5 | n/a | owner-only config; decryption = 2-of-3 KMS proof | **P** (centralised) |

**Latent:** the *entire* stack is UUPS/Transparent-upgradeable and owned by two EOAs
(`0xEA7Ff995…`, `0x3480B1E2…`) with a single shared settlement keeper (`0x43A28B8d…`); the FHE
decryption and ciphertext-verification oracles are **2-of-3 thresholds whose three signers are all
Primus-operated EOAs**. See §4/§8.

---

## 2 · Total live extractable now

> ### **E-U (external, unprivileged attacker): $0** — confidence **high**
>
> ### H-O (holder self-service only): **$248,434.55** (the FHE-vault backing) — confidence **high**
>
> ### P (privileged: owner/keeper/2-of-3 KMS): the full backing + upgrade control — confidence **high**
>
> ### S (stuck/bricked): ~$109 (FHEExecutor prepaid BNB, see §8) — confidence **medium**

No unprivileged call path was found that moves, mints, burns or redirects another party's value.
Every entry point that touches value is gated by one of: FHE-ACL handle access, `msg.sender`
ownership, a keeper role, an owner role, or a threshold KMS/alphatrion signature proof.

---

## 3 · The mechanism, in exact terms (with deployed code references)

### 3.1 Address resolution (how the FHE contracts were found)

The dapp `https://dapp.primuslabs.xyz/` is a Next.js app; its `_next/static/chunks/4781-*.js`
bundle contains a hard-coded chain config (`module 83401`). The BSC-mainnet branch is:

```
mainnet: {
  acl: "0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE",
  usduAddress: "0xeA953eA6634d55dAC6697C436B1e81A679Db5882",
  tokenPairs: { u:    { standard: "0xcE24439F…B666666", confidential: "0x3EcB7d91…1F06800" },
                usdt: { standard: "0x55d39832…3197955", confidential: "0xc2CC9419…17838c" } },
  standaloneTokens: { "esUSDu-u":    "0x06776741b1f8bfF5ea51750E91edcf03ed8C6994",
                      "esUSDu-usdt": "0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d" },
  earnVaults: {
    "united-stables-confidential-vault": { vault: "0xe9E8573B…9784AE",
        depositAggregator: "0xedcDd426…5dd24", redeemAggregator: "0xBef13665…bCa22",
        inputToken: "0x3EcB7d91…1F06800", shareToken: "0x06776741…8C6994" },
    "encrypted-usdt-confidential-vault": { vault: "0xe9E8573B…9784AE",
        depositAggregator: "0xE76F5202…56c1", redeemAggregator: "0x485dBFD9…6a8f89",
        inputToken: "0xc2CC9419…17838c", shareToken: "0x75787E2a…42354d" } },
  alphaTrionRpcUrl: "https://fhetransform.alphatrion.bnbmainnet.primuslabs.xyz/test",
  decryptionRpcUrl: "https://fhetransform.alphatrion.bnbmainnet.primuslabs.xyz:38084" }
```

The FHE-system addresses are not in the JS config (only the ACL is); they come from the on-chain
config baked into the contracts — `PrimusConfigBase._setupFHEConfig()`
(`analysis/src/flat/ConfidentialConverter__0x15c0ac63__PrimusConfigBase.sol`):

```solidity
if (block.chainid == 56) {            // BSC mainnet
  cfg = FHEConfig({ ACLAddress: 0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE,
                    FHEExecutorAddress: 0x12964221F412e3e52F5f0C9592781904266dd9B4 });
}
```

and confirmed live at block 129,593,000:
`FHEExecutor.getDecryptionAddress() = 0x29873f805e66B39c28D394B213f712B7b2B52ba1`,
`getSpaceBridgeConfigAddress() = 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396`,
`getCiphertextVerificationAddress() = 0x9313191E3Eadc4C365d2043E8b7c03d73193D99A`,
`getAlphatrionRewardAddress() = 0xa536Ba1D17268e3821a17A591D7d6530cb593845`.

The Unitas backend (`staked`/`minting`) is derived at runtime from the vault proxy:
`UnitasProxy.usdu() = USDu`, `staked() = 0x385C279445581a186a4182a5503094eBb652EC71` (**StakedUSDuV2**,
the recon's `0x385C2794…`), `minting() = 0xbB984CE670100AA855f6152f88b26EE57f4EA82A`
(**UnitasMintingV2**, the recon's `0xbB984CE6…`).

### 3.2 How value moves (and why it is gated)

**Deposit (mint route).** A user calls `confidentialTransferAndCall` on the input converter
(`eU`/`eUSDT`) with the aggregator as `to`. The converter runs the receiver hook
`AggregatorConfidentialUpgradeable.onConfidentialTransferReceived` →
`require(msg.sender == address(fromToken()))` then `_join(from, amount)` credits the encrypted
deposit. Keeper-gated `dispatchAggregate()` unshields `totalDeposits` to the aggregator (burning the
confidential tokens, releasing the plaintext underlying) and the keeper drives the off-chain Unitas
API; `_executeRoute` at `MintInit` does `forceApprove(underlying, UnitasProxy, rawUSDT)`; when sUSDu
arrives the keeper re-enters `dispatchAggregateCallback`, which shields the output and writes a
plaintext `exchangeRate`. Users then `claim(aggregateId, account)`.

**Why an attacker can't extract:**
1. `dispatchAggregate` / `dispatchAggregateCallback` are **overridden to be keeper-only** in
   `UnitasAggregatorConfidentialUpgradeable` (base `AggregatorConfidentialUpgradeable` makes them
   permissionless, but the Unitas leaf re-gates them; verified live: `keeper() = 0x43A28B8d…` and a
   funded non-keeper call reverts `NotKeeper`).
2. `claim(aggregateId, account)` is permissionless **but always pays `account`** — the depositor —
   after zeroing that account's own deposit; an attacker with no deposit reverts
   (`ZeroDeposits` / `UnexpectedAggregateState`).
3. `quit(aggregateId)` is self-only (`deposits[id][msg.sender]`).
4. `recoverAggregate` and every policy setter are `onlyOwner`.
5. **FHE gating:** `finalizeUnshield(requestId, cleartext, proof)` is permissionless but (a) reverts
   `InvalidUnshieldRequest` for any id that was not opened by a real `unshield`, (b) always pays the
   *recorded* recipient, and (c) requires
   `FHE.checkSignatures(handles, cleartext, proof)` → `Decryption.verifyPublicDecryptionEIP712KMSSignature`
   → a **threshold** of registered KMS signers (2 of 3 live). A forged cleartext cannot be settled.
6. `unshield(from,to,amount)` requires `FHE.isAllowed(amount, msg.sender)` **and**
   `from == msg.sender || isOperator(from, msg.sender)`; `_update` clamps with `tryDecrease`
   (`transferred = select(success, amount, 0)`), so no underflow / no stealing another balance.
7. `RestrictedConfidentialConverter` (esUSDu) can pin transfers to whitelisted rails; live
   `esUSDu-u.transferRestrictionEnabled() = true`.

### 3.3 The share math (Unitas StakedUSDuV2) — no unprivileged edge

`StakedUSDuV2` (`0x385C279445581a186a4182a5503094eBb652EC71`, a StakedUSDe/Ethena-lineage ERC-4626)
prices shares as `totalAssets()/totalSupply()` where `totalAssets() = USDu.balanceOf(this) −
getUnvestedAmount()` (8-hour linear vesting of the last `transferInRewards`). Live
(block 129,593,000):

* `totalSupply() = 35,223,612.958059121610622516` sUSDu
* `totalAssets() = 38,787,873.685204223163221473` USDu
* `getUnvestedAmount() = 1,232.666647388888888888` USDu
* **rate = 1.101189526792412782586448363 USDu / sUSDu**; with USDu @ $0.998903 → **sUSDu ≈ $1.099982**
* `cooldownDuration() = 604800` (7 days) → `withdraw`/`redeem` disabled (`ensureCooldownOff`); exits
  go through `cooldownShares` → `unstake` after 7 d. Deposit/withdraw are also blacklist-gated
  (`SOFT_/FULL_RESTRICTED_STAKER_ROLE`) and `MIN_SHARES = 1 ether` blocks the first-depositor
  donation attack. `redistributeLockedAmount`/`rescueTokens` are admin-only (cannot touch USDu).
  No rounding path lets an outsider extract value.

### 3.4 The 8-hour batch settlement (confirmed)

`mint_u` / `mint_usdt`: `minAggregateAge() = 28800 s` (8 h), `callbackDeadline() = 86400 s` (24 h);
`redeem_u` / `redeem_usdt`: `minAggregateAge() = 604800 s` (7 d, matching the sUSDu cooldown),
`callbackDeadline() = 1296000 s` (15 d). `UnitasRewardPool.periodDuration() = 28800 s` (8 h).
Batch counters at the pinned block: `mint_u` id **180**, `mint_usdt` id **101**, `redeem_u` id **9**,
`redeem_usdt` id **5**. Only one aggregate is in flight (`redeem_u` #8, `aggregateStep = 4`
= `RedeemCooldown`, cooldown ends ~1.5 d later — healthy, not stuck). No aggregate is stranded in
`Dispatched` past its deadline.

---

## 4 · FHE-specific caveat (stated explicitly)

**The FHE confidentiality and decryption authorisation are centralised, not trustless.** Live
`SpaceBridgeConfig` (`0x8914af6Bb24Cbff797Be208aBE388927C0FC0396`):

* `getPublicDecryptionThreshold() = 2`, `getUserDecryptionThreshold() = 2`,
  `getAlphatrionThreshold() = 2` (the contract enforces `t ≥ ⌊n/2⌋+1`, so 2 is the minimum for n=3);
* `getKmsSigners()` = **3 EOAs, all under Primus's `owner() = 0xEA7Ff995…`**:
  `0x7b0D311DE29c8AC04948a30BecB268F97d23B8ee`,
  `0x91D3D15FE8f3b5fd4b26584FA3912dF3a432848b`,
  `0x708f25bEc3a52748C44727909a6916439d9a08cc`;
* `getAlphatrionSigners()` = 3 EOAs (`0x76b1bAa5…`, `0x4E7509a8…`, `0x72E772Fc…`) with threshold 2.

`Decryption.verifyPublicDecryptionEIP712KMSSignature` is a **stateless** oracle: it recovers each
signature, requires it to be a registered KMS signer, and requires ≥ threshold unique valid
signatures over the EIP-712 digest of `(ctHandles, decryptedResult, extraData)`. Consequently:

* anyone holding **≥2 of the 3 KMS keys** (i.e. Primus, or an attacker who compromises two of those
  EOAs) can (a) **decrypt any user's balance/amount**, breaking confidentiality, and (b) **mint a
  valid decryption proof for an arbitrary cleartext**. Combined with a real `unshield` request this
  would let them settle an inflated `finalizeUnshield` and drain the converter backing.
* Because the same entity is also the **UUPS owner** (can upgrade the converter/aggregator to
  arbitrary code), this is a **privileged (P) capability, not an E-U path** — a 2-of-3 key
  compromise is out of scope for "external unprivileged". It is nevertheless the single most
  important trust assumption of the system and is recorded here as the headline caveat.

Similarly, `CiphertextVerification.verifyInput` (used by `FHE.fromUnverified` on every encrypted
input) verifies **2-of-3 Alphatrion** EIP-712 signatures — so even input ciphertext well-formedness
is a centralised threshold. (Note: even a forged *input* proof cannot steal funds, because the
token logic clamps every arithmetic result to the caller's own balance; only the *decryption* proof
is value-bearing, and only in conjunction with a pre-existing unshield request.)

---

## 5 · Live-state assessment (all at BSC block **129,593,000**, 2026-10-24)

Full raw dump: `analysis/live_state.json`. Prices: DefiLlama `coins.llama.fi/prices/current`
(timestamp 1792881602) — USDu **$0.998903** (conf 0.99), U **$0.999214**, USDT **$0.999095**,
BNB **$741.82**; sUSDu derived = rate × USDu = **$1.099982**.

### 5.1 FHE system contracts

| Contract | Proxy | Implementation | Owner / admin | State |
|---|---|---|---|---|
| ACL | `0x3fE3B494…742AE` | `0xe9627450…016d3` (verified `ACL`) | `0xEA7Ff995…0d87` (ProxyAdmin `0xdc2bd2b2…` owner) | `paused()=false` |
| FHEExecutor | `0x12964221…dd9B4` | `0x349e8cf8…38d38` (verified `FHEExecutor`) | `0xEA7Ff995…0d87` (ProxyAdmin `0xdac165bf…` owner) | 0.146737176 BNB prepaid |
| Decryption | `0x29873f805e66B39c28D394B213f712B7b2B52ba1` | `0x8cacbebe…076e4e` | SpaceBridge owner `0xEA7Ff995…0d87` | pub/user threshold 2 |
| SpaceBridgeConfig | `0x8914af6B…C0396` | `0x120d2112…0a778` | `0xEA7Ff995…0d87` | KMS 3 / α 3, thresholds 2 |
| CiphertextVerification | `0x9313191E…3D99A` | `0xb1164e7b…13feb` | SpaceBridge owner | α threshold 2 |
| AlphatrionReward | `0xa536Ba1D…93845` | `0xf6c179f2…ffaaa` | SpaceBridge owner | fee settlement |

### 5.2 Confidential converters (the FHE-vault value)

| Token | Proxy | Impl | Owner | Underlying | rate | Backing (live) | USD |
|---|---|---|---|---|---|---|---|
| eU "Confidential U" | `0x3EcB7d91…06800` | `0x15c0ac63…72a7` (`ConfidentialConverter`) | `0xEA7Ff995…0d87` | U `0xcE24439F…666666` | 1e12 | 4,915.308965 U | **$4,911.45** |
| eUSDT | `0xc2CC9419…17838c` | `0x15c0ac63…72a7` | `0x3480B1E2…4893` | USDT `0x55d39832…3197955` | 1e12 | 4,060.886564 USDT | **$4,057.21** |
| esUSDu ("u") | `0x06776741…8C6994` | `0x18d3f55b…827353` (`RestrictedConfidentialConverter`) | `0xEA7Ff995…0d87` | sUSDu `0x385C2794…2EC71` | 1e12 | 96,242.263463 sUSDu | **$105,864.76** |
| esUSDu ("usdt") | `0x75787E2a…42354d` | `0x18d3f55b…827353` | `0x3480B1E2…4893` | sUSDu `0x385C2794…2EC71` | 1e12 | 121,457.549211 sUSDu | **$133,601.13** |

`transferRestrictionEnabled()`: esUSDu-u = **true**, esUSDu-usdt = **false**.
**Total FHE-converter backing = $248,434.55.**

### 5.3 Aggregators + reward pool

| Contract | Proxy | Impl | Owner | Keeper | minAge / deadline | currentAggregateId | rewardPool |
|---|---|---|---|---|---|---|---|
| UnitasMintAggregatorConfidential "u" | `0xedcDd426…5dd24` | `0x8b621304…c29d` | `0xEA7Ff995…0d87` | `0x43A28B8d…8FB6` | 28800 / 86400 | 180 | `0xCfd2917b…524F` |
| UnitasMintAggregatorConfidential "usdt" | `0xE76F5202…56c1` | `0x8b621304…c29d` | `0x3480B1E2…4893` | `0x43A28B8d…8FB6` | 28800 / 86400 | 101 | 0 |
| UnitasRedeemAggregatorConfidential "u" | `0xBef13665…bCa22` | `0xa2652e6c…ad46` | `0xEA7Ff995…0d87` | `0x43A28B8d…8FB6` | 604800 / 1296000 | 9 | `0xCfd2917b…524F` |
| UnitasRedeemAggregatorConfidential "usdt" | `0x485dBFD9…6a8f89` | `0xa2652e6c…ad46` | `0x3480B1E2…4893` | `0x43A28B8d…8FB6` | 604800 / 1296000 | 5 | 0 |
| UnitasRewardPool | `0xCfd2917b…524F` | `0xe14cfce2…1436` | `0xEA7Ff995…0d87` | `0x70520046…d3DC` | period 28800 | — | rewardToken = **eU** |

`unitasProxy()` on all four = `0xe9E8573Bb351da16c6EE7dDaC0cBC70b7f9784AE`; all `paused() = false`.
Aggregator token balances ≈ dust (mint_u holds 0; redeem_usdt holds 592,314,983 wei USDT ≈
$0.00059; vault UnitasProxy holds 106,708,030,759,568 wei USDT ≈ $0.000107).

### 5.4 Unitas backend (context; not FHE-vault value)

| Contract | Address | Owner | Live |
|---|---|---|---|
| StakedUSDuV2 (sUSDu) | `0x385C279445581a186a4182a5503094eBb652EC71` | `0x179650b38B20773393c3a10B3b55ba57780BDBD9` | 38,789,106.62 USDu ≈ **$38,746,574**; silo `0x6F8A06A8…EAFD` holds 1,013,216.78 USDu ≈ **$1,012,106** (cooldown) |
| UnitasMintingV2 | `0xbB984CE670100AA855f6152f88b26EE57f4EA82A` | `0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8` | holds 843,213.54 USDT ≈ **$842,450** |
| UnitasProxy "vault" | `0xe9E8573Bb351da16c6EE7dDaC0cBC70b7f9784AE` | ProxyAdmin `0x5d00747c…` owner `0xa53DD0a0…` | `paused()=false`; holds ~$0 |
| USDu | `0xeA953eA6634d55dAC6697C436B1e81A679Db5882` | `0x8E3811B4Dc5022AB9C8Afbb54Be4Aa23780C62b3` | totalSupply 40,791,002.136 USDu |
| U ("United Stables") | `0xcE24439F2D9C6a2289F741120FE202248B666666` | `0x59F94AdE4F881f21ea608AD4448bf70B78e37187` | 18 dec, totalSupply 1,077,493,134.7 U |

### 5.5 Roles / privileged actors

* **Primus FHE side:** owner `0xEA7Ff99584C1996Bd9E94033b5C7A1Fe37B00d87` (EOA) — ACL, FHEExecutor,
  Decryption, SpaceBridgeConfig, eU, esUSDu-u, mint_u, redeem_u, UnitasRewardPool, and the two
  ProxyAdmins for ACL/FHEExecutor.
* **Primus FHE side #2:** owner `0x3480B1E2f19D95cdfb8dA3ae40E9C7C500Fe4893` (EOA) — eUSDT,
  esUSDu-usdt, mint_usdt, redeem_usdt.
* **Keeper (all 4 aggregators):** `0x43A28B8dD1ebc3752ECcfd610d70D5c2BCc18FB6` (EOA).
  **Reward-pool keeper:** `0x70520046798043970955AbF5189c63b11C3Dd3DC`.
* **KMS signers (2-of-3):** `0x7b0D311D…B8ee`, `0x91D3D15F…848b`, `0x708f25bE…08cc`.
* **Alphatrion signers (2-of-3):** `0x76b1bAa5…db13`, `0x4E7509a8…c608`, `0x72E772Fc…FB5E`.
* **Unitas side:** StakedUSDuV2 owner `0x179650b3…DBD9`; UnitasMintingV2 owner `0x0a6Db8e8…B1c8`;
  USDu owner `0x8E3811B4…2b3`; U owner `0x59F94AdE…7187`.

---

## 6 · What an attacker can / cannot do (exact call paths)

Every probe below was run as `eth_call` **from a fresh funded EOA** (`0x000…DeaDBeef` or the funded
non-keeper `0x8894E0a0…D4E3`) against BSC; the Foundry test reproduces them on a fork
(`poc/test/PrimusFheGating.t.sol`). Observed revert reasons are the live, on-chain ones.

**Cannot (all revert):**
| Attempt | Call | Live revert |
|---|---|---|
| Force a batch (grief/drain) | `mint_u.dispatchAggregate{value}()` | `NotKeeper(attacker)` |
| Advance/settle a batch | `mint_u.dispatchAggregateCallback(180,1,""){value}` | `NotKeeper(attacker)` |
| Force-settle a stuck batch | `mint_u.recoverAggregate(180,1,true){value}` | `OwnableUnauthorizedAccount(attacker)` |
| Hijack settlement | `mint_u.setKeeper/setRewardPool/pause` | `OwnableUnauthorizedAccount(attacker)` |
| Claim someone else's / open batch | `mint_u.claim(180,attacker){value}` | `UnexpectedAggregateState(180, Open, 0x…04)` |
| Refund a stranger | `mint_u.quit(180){value}` | `ZeroDeposits(180, attacker)` |
| Forge an unshield settlement | `eU.finalizeUnshield(fakeId, 1e18, "")` | `InvalidUnshieldRequest(fakeId)` (`0x9112ea14`) |
| Unshield a handle you don't own | `eU.unshield(attacker,attacker,1){value}` | revert (FHE ACL) |
| Self-grant ACL access | `ACL.allow(h, attacker)` | `SenderNotAllowed(attacker)` |
| Force-decrypt a handle | `ACL.allowForDecryption([h])` | `SenderNotAllowed(attacker)` |
| Pause/retarget the oracle | `ACL.pause()`, `ACL.setFheExecutorAddress(a)` | `OwnableUnauthorizedAccount(attacker)` |
| Forge a KMS proof | `Decryption.verifyPublicDecryptionEIP712KMSSignature([h],1e18,"0x00")` | `DeserializingDecryptionProofFail()` |
| Denylist / rewire converter | `eU.denyUser/setFeeSkipCaller` | `OwnableUnauthorizedAccount(attacker)` |

**Can (harmless / no gain):**
* `shield(to, amount)` on any converter — a *deposit*: pulls the caller's own underlying in and
  mints confidential tokens to `to`. Costs the attacker money; gives nothing extra.
* `claim(aggregateId, account)` on a **Finalized** aggregate for any `account` — pays `account`
  (the depositor) their own pro-rata output. Third-party "relaying" is intentional and moves no
  value to the caller.
* `claimBusinessFee(recipient)` / `FHEExecutor.claimReward()` — pay the recipient/caller only.
* `requestReveal(handle)` for a handle the caller already holds — makes the caller's own handle
  publicly decryptable (self-disclosure).

**Cost/preconditions to attempt the gated paths:** all require either (a) the keeper key, (b) an
owner key, or (c) ≥2 of the 3 KMS signer keys — i.e. privileged/insider access, not attacker
capital. Flash loans do not help: nothing is price- or liquidity-dependent.

---

## 7 · PoC / fork-verification

* **Files:** `poc/foundry.toml`, `poc/test/PrimusFheGating.t.sol` (7 tests). Forks BSC via
  `BSC_RPC_URL` (env) and asserts every gating revert above, plus that the live backing is present
  and holder-only. `ci/run.sh` writes a live-state snapshot to `ci-out/evidence.txt`.
* **How it ran:** on GitHub Actions (Ubuntu, public repo `artsbykriss/ca-zombie-ci`) via
  `bash /home/heisenberg/CA/ci/ci-run.sh primus-fhe` — see `ci-log.txt` and the run URL(s) recorded
  in `summary.json`. No local anvil/fuzz/build was run.
* **Key numbers asserted on the fork:** converter backing floors
  (esUSDu-u ≥ 90,000 sUSDu; esUSDu-usdt ≥ 115,000 sUSDu; eUSDT ≥ 3,900 USDT; eU ≥ 4,700 U);
  thresholds == 2; keeper/owner addresses as in §5.5.
* **Result:** see `ci-log.txt` (`x/7 PASS`). *(The run URL + pass count are mirrored into
  `summary.json` → `poc`.)*

---

## 8 · Verdict, residual / latent risk, blockers

**Verdict.** **E-U = $0 (high confidence).** The FHE vault (Primus Confidential Finance) and its
Unitas backend are a *well-gated* custody stack: batch settlement is keeper-gated, owner escape
hatches are owner-gated, and the FHE layer requires either a real pre-existing unshield request plus
a threshold KMS proof, or ACL handle access, to move value. No unprivileged path was found.

**Residual / latent risk (all privileged, listed so they are not re-hunted as E-U):**
1. **Centralised FHE oracle (headline caveat).** 2-of-3 KMS + 2-of-3 Alphatrion, all signers
   Primus EOAs; the KMS proof is value-bearing. A 2-key compromise ⇒ forged `finalizeUnshield` ⇒
   converter drain, and full confidentiality loss. Classified **P**, not E-U.
2. **Two EOAs + one keeper EOA** control the whole stack and every proxy is UUPS/Transparent
   upgradeable ⇒ unconditional owner drain of the ~$248k (and the ability to pause/deny). **P**.
3. **Unitas backend concentration:** StakedUSDuV2 `FULL_RESTRICTED_STAKER_ROLE` +
   `redistributeLockedAmount` let its owner move/void a restricted staker's $38.7M; `BLACKLIST_MANAGER`
   can freeze exits. **P**.
4. **H-O (holder self-service):** the ~$248,434.55 of backing is redeemable by holders via
   `unshield → dispatchAggregate → claim` — subject to the keeper being online (otherwise the owner
   must `recoverAggregate`) and to the 7-day sUSDu cooldown on the redeem route.
5. **S (stuck):** `FHEExecutor` holds 0.146737176 BNB (≈ **$109**) of prepaid fees; `refundFee` is
   disabled and only the owner/AlphatrionReward can distribute it ⇒ effectively unrecoverable by
   users. Aggregator rounding dust (~µ$) also accumulates. Confidence **medium** (low value).

**Blockers / what would change the verdict:**
* A leaked KMS signer key (2 of 3) or the keeper/owner keys would turn the "P" paths into live
  drains — monitor those 3 KMS + 3 Alphatrion + 2 owner + 1 keeper addresses.
* The system depends on the off-chain Alphatrion service (`fhetransform.alphatrion.bnbmainnet…`) and
  the Unitas off-chain mint/redeem API; if either halts, batches stall in `Dispatched` (owner
  `recoverAggregate` is the escape hatch) — a liveness, not an E-U, risk.
* `esUSDu-usdt.transferRestrictionEnabled()` is currently **false** (the "u" route's is `true`): if
  the reward ledger depends on the whitelist, the usdt route is the weaker of the two rails. No fund
  impact observed.

---

## 9 · Methodology, sources, caveats, files index

**Methodology.** (1) Scraped the dapp's Next.js JS chunks (`_next/static/chunks/4781-*.js`) to
extract the BSC-mainnet address config; (2) read the on-chain FHE config from the verified
`PrimusConfigBase`; (3) pulled verified sources for every contract + its EIP-1967/Transparent
implementation from Etherscan V2 (`chainid=56`, `getsourcecode`); (4) read every value-moving entry
point; (5) pinned a block (129,593,000) and read all state via batched `eth_call`
(`analysis/live_state.json`); (6) ran unprivileged probes as `eth_call` from fresh EOAs; (7)
reproduced the gating on a BSC fork in Foundry (CI).

**Sources.** dapp.primuslabs.xyz JS bundles; docs.primuslabs.xyz (`fhe/use-cases/confidential-transfer`);
Etherscan V2 verified source (all contracts above are verified); BSC archive `eth_call`;
DefiLlama prices; forge-std (vendored).

**Caveats.**
* The recon's ">$1M user deposits" is **not** what is on-chain today: the FHE converters back
  **$248,434.55** (the rest of the reported figure is likely cumulative / the Unitas backend, which
  is $38.7M TVL). I report only what the contracts hold.
* "Extractable" is net of real costs; here there is no path, so cost analysis is moot.
* The KMS/owner centralisation means the *system's* security is not trustless — an honest statement
  of the trust model, not an E-U finding.
* Some `view` getters revert on these contracts (`penaltyRate` is private; converters have no
  `paused()`); noted, not material.

**Files index.**
```
primus-fhe/
├── README.md                      # this report
├── summary.json                   # machine-readable summary (§7 schema)
├── ci-log.txt                     # GitHub Actions log (written by ci-run.sh)
├── analysis/
│   ├── live_state.json            # 115 pinned-block reads (block 129,593,000)
│   ├── config_dump.txt            # raw dapp JS config extract
│   └── src/                       # Etherscan V2 getsourcecode responses + flat/ extracted sources
│       ├── src_<addr>.json        # raw API responses (all 15+ contracts)
│       └── flat/                  # 272 extracted .sol files, keyed by Contract__addr__file.sol
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/             # vendored
│   ├── src/Stub.sol
│   └── test/PrimusFheGating.t.sol # 7 fork tests (gating + live backing)
├── ci/run.sh                      # heavy job: live-state evidence -> ci-out/
├── ci-out/                        # CI result files (artifacts)
└── ci-artifacts/                  # downloaded CI artifacts (if any)
```

*Read-only. No mainnet transaction was signed or sent. All executable checks are fork-only (CI).*
