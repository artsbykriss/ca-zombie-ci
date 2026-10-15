# Hover (Kava EVM, chain id 2222) — L2-06 deep-dive: extractable-value determination

**Campaign:** zombie-hunt II · **Target:** L2-06 "Hover — ~$2.3k; hUSDT insolvent | zombie, no empty-market path"
**Chain:** Kava EVM (2222) · **Date of work:** 2026-10-15 · **Pinned state block:** 23,034,510 (and re-verified unchanged to 23,035,842)
**Status:** read-only research; no transactions signed or sent to any real chain. The fork suite (`test/HoverFork.t.sol`) was written for CI execution on a Foundry fork; it is not run locally by this subagent.

**VERDICT — external unprivileged extractable: $0 (confidence: high).**
The campaign's L2-06 verdict ("$2.3k TVL, hUSDT insolvent, no empty-market path") survives adversarial testing and is *understated in its closure*: in addition to the empty-market path being closed, **every** other live extraction class was tested and closed:

| # | Path | Net USD for an external attacker | Verdict | Why closed (exact gate) |
|---|---|---|---|---|
| 1 | Liquidation of the two underwater hUSDT borrowers (collateral hKAVA) | **$0** | **P** (privileged only) | `Comptroller.liquidateBorrowAllowed` starts with `IAllowList(liquidatorsWhitelistVerifier).allowed(liquidator)` → allowlist has **exactly 2 addresses** (protocol liquidation bots); outsider gets `Error.UNAUTHORIZED (1)` |
| 2 | Same liquidation routed *through* a whitelisted bot (the public entry a third-party keeper used) | **$0** (and would be a **loss** of gas) | **P** | bot's public entry sends proceeds to a hard-coded `profitWallet()` = `0xbA6f82F7…` (protocol team), not the caller — proven by the historical liquidation trace |
| 3 | Any liquidation at all, even by the whitelisted bots | **$0** | **S/P** (currently frozen) | the oracle (Pyth asset-config) is **stale**: `getUnderlyingPrice()` reverts `StalePrice()` for all 3 markets, so `getAccountLiquidity` and therefore the whole liquidation path reverts for everyone |
| 4 | Mint / supply attack, donation class, empty-market exchange-rate inflation | **$0** | **P/S** | `mintGuardianPaused == true` on **all three** markets → `mintAllowed` **reverts** `"MP"`; the native market's payable fallback also routes into mint and reverts. No cTokens can be created by anyone (including the admin's users) |
| 5 | Over-borrow / oracle-manipulation borrow, recursive leverage | **$0** | **P** | `borrowGuardianPaused == true` on all three markets → `borrowAllowed` **reverts** `"BP"` |
| 6 | `seize()` called directly (the classic Compound caller-check gap) | **$0** | closed | `msg.sender` must be a listed cToken: `seizeAllowed` returns `MARKET_NOT_LISTED (9)` for an outside caller; observed `seize()` → `COMPTROLLER_REJECTION (3)` |
| 7 | Force-feed / selfdestruct donation to inflate the exchange rate and capture it | **negative** | closed | direct sends revert (`MP`); force-fed KAVA raises the exchange rate **for existing holders only** — the attacker owns 0 cTokens → pure loss (fork-proven) |
| 8 | Rescue/sweep/admin functions (reserves, stray tokens, oracle prices, pause flags) | **$0** | **P** | all admin-gated to a **2-of-8 Gnosis Safe v1.3.0** (`_reduceReserves` → `UNAUTHORIZED` for outsiders; `sweepToken` → `"only admin may call"`) |
| 9 | Reward capture (`claimReward`, Comptroller pot) | **$0** | closed | rewards are paid to `holders[i]`, never the caller; emission speeds are **1 wei/sec** (≈0); attacker's `rewardAccrued == 0` |
| 10 | GenesisPool farms (cToken staking) drain | **$0** | **P/H-O** | `emergencyWithdraw(address)` reverts `"admin only"`; `claimRewards()` pays the caller's own accrued (0 for outsiders); `redeem()` reverts for non-stakers |
| 11 | HOV / esHOV / xHOV token-contract value | **$0** | **S** | no market price (DefiLlama + CoinGecko return no price for all three) → nothing realisable; control/admin paths are Safe-gated |
| 12 | Redeem side — draining the markets' cash | **$0** for an attacker | **H-O** | only cToken *holders* can redeem; the attacker holds none, and there is no on-chain market to buy cTokens. hUSDT's cash is 0.00001 USDT anyway |

**Total live extractable by an external unprivileged attacker right now: $0.00.**
The campaign's "~$2.3k" is **holder-claimable cash** (H-O), not attacker-extractable: hKAVA 28,572.17 KAVA ($1,957.48) + hATOM 179.03 ATOM ($301.88) + hUSDT 0.00001 USDT.

**Tripwires found (one state-flip from value):**
1. **Pyth refresh** (permissionless contract call, fee = 0 wei) → the oracle comes alive for up to 1,260 s → the two whitelisted bots can liquidate the two underwater positions (**≈$136.77 gross liquidation bonus**, see §4) and members' redemptions unfreeze. Fresh VAA data now requires a (free) Pyth/Hermes API key — the endpoint `/v2/updates/price/latest` returns 401 without one (as of 2026-10-15).
2. **Unpause mint/borrow** (admin/Safe) → classic Compound-fork donation/borrow surface returns. The oracle would still have to be refreshed first.
3. **Add any address to the allowlist** (admin/Safe) → that address becomes a liquidator (but still needs a fresh oracle).

---

## 1. Contracts and live state (block 23,034,510; prices at chain ts 1792058644 = 2026-10-15 ~10:00 UTC)

Prices used (DefiLlama `coins.llama.fi/prices/current`, coingecko:kava / kava:0x1593…A(ATOM) / kava:0x919C…(USDT)):
**KAVA $0.0685086 · ATOM $1.6864362 · USDT $0.9991027**. HOV/esHOV/xHOV: **no price** (not listed on DefiLlama or CoinGecko).

| Contract | Address | Evidence / role |
|---|---|---|
| Comptroller | `0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC` | **Unitroller proxy** (runtime 1,508 B); storage slot 2 → impl `0xb618fb7c9921fb35a75fddf5ee1bbdf19080020c` (49 KB custom Comptroller, verified). `admin()=Safe`, `pendingAdmin()=0` |
| Oracle | `0xE8Ae943de7f036Cfa505127641Eee7c5b6606878` | unverified 6,771 B Pyth **asset-config oracle**; `owner()=Safe`; `tokenConfigs("KAVA"/"ATOM"/"USDt")` → (native/uATOM/uUSDT, Pyth feed id, maxStalePeriod 1260 s) |
| Pyth | `0xa2aa501b19aff244d90cc15a4cf739d2725b5729` | ERC-1967 proxy → UUPS impl `0x36825bf3…`; `version()="1.3.0"`; `singleUpdateFeeInWei()=0` |
| Admin | `0xcecC934494adED6c0c82C52656a845862176ceeE` | **Gnosis Safe v1.3.0, threshold 2-of-8** (owners listed in `state.json`); admin of comptroller/markets/oracle/allowlist |
| Liquidator allowlist | `0x49AE3cc17eD67c9Bc9cd11E4d799c329bC90203F` | owner = Safe; `allowedAddressesLength()=2`: `0x9b9FB7e3291C43F3146A9F590a421aC3C0377709`, `0x608cB0F61c1e574025D3e8168078d13e2320781D`; `allow()` owner-only |
| Whitelisted liquidator bots | `0x9b9FB7e3…`, `0x608cB0F6…` | both `owner() = profitWallet() = 0xbA6f82F77fCf03d33150fceC7384644AC12F4DD5`; both hold **0** of every asset |
| hKAVA (native market) | `0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636` | **CNativeDelegator** (7,410 B) → impl `0x39c18a98d1d5e432a9f7469009f65f1da0c706b4` (CNativeDelegate, verified); no `underlying()`, fallback **mints** (hence `"MP"` on unknown calls) |
| hATOM / hUSDT | `0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd`, `0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961` | **CErc20Delegator** (8,085 B) → impl `0x5c59874128dc86e386973dd0b877f796d152b9ea`; contain the admin-only `sweepToken` |
| uATOM / uUSDT | `0x15932E26f5BD4923d46a2b205191C4b5d5f43FE3` (6 dec), `0x919C1c267BC06a7039e03fcc2eF738525769109c` (6 dec) | underlyings |
| GenesisPools | hKAVA `0x5450c389…`, hATOM `0x4d06a0d5…`, hUSDT `0xb399cdcc…` | 1,189 B proxies → per-market GenesisPool impls (identical 6,799 B code); hold cTokens + esHOV |
| HOV / esHOV / xHOV | `0xCe82db637A2D750380ef27063518eAa263fbe10E`, `0xD3452d932A81C1221C1Ba331852554cBBEF8c652`, `0xD6aDF6284b657c3c5b0d0Fa69BDB03afb8a98c76` | ERC-1967 proxies (impls `0xA52BCcBd…`, `0xE469fDda…`, `0x80B4fa5C…`), proxy-admin `0xAEfca816…`; no market price |

**Market accounting (block 23,034,510):**

| Market | totalSupply (cTokens) | exchangeRateStored | cash | borrows | reserves | claims (value) | CF | mint/borrow paused |
|---|---|---|---|---|---|---|---|---|
| hKAVA | 2,224,575.2330 | 2.0075707062e26 | 28,572.1724 KAVA **($1,957.48)** | 18,113.0 KAVA ($1,240.94) | 2,025.244 KAVA ($138.75) | 44,659.4 KAVA ($3,059.73) | 0.60 | **yes / yes** |
| hATOM | 8,601.0235 | 2.1451412131e14 | 179.0266 ATOM **($301.88)** | 5.48 ATOM ($9.24) | 0.002913 ATOM | 184.50 ATOM ($311.12) | 0.35 | **yes / yes** |
| hUSDT | 333,655.7787 | 3.0934965701e14 | **0.00001 USDT** | 12,103.44 USDT ($12,092.58) | 1,781.81 USDT ($1,780.21) | 10,321.6 USDT ($10,312.35) | 0.85 | **yes / yes** |

`closeFactor=0.5`, `liquidationIncentive=1.05`, `pauseGuardian=0x0`, `transferGuardianPaused=false`, `seizeGuardianPaused=false`, `maxAssets=0`, `allMarkets.length=3`, `protocolTokenAddress=esHOV`, `rewardNativeToken=1`, reward tokens `[esHOV, native, HOV]`, reward speeds `=1 wei/s` (emissions off), comptroller reward pot = **673.99 KAVA + 15.97 HOV + 9.71 esHOV**.

## 2. The mechanism, in exact terms

Hover is a Compound V2 fork (solc 0.5.17, Compound 2021-lineage) deployed on Kava in Nov-2023 (hKAVA deployed at block 7,402,257, 2023-11-20, creator `0xF4efDf1E…152BC909`). Its distinguishing features:

1. **Time-based interest accrual** (`accrualBlockTimestamp`, `borrowRatePerTimestamp`) instead of block-based.
2. **A liquidator allowlist**: `liquidateBorrowAllowed()` returns `UNAUTHORIZED` unless `IAllowList(liquidatorsWhitelistVerifier).allowed(msg.sender)`. `seizeAllowed()` additionally requires the caller to be a *listed market* (`markets[msg.sender].isListed`), which closes the generic "call `seize()` directly" class.
3. **A Pyth asset-config oracle**: `getUnderlyingPrice(cToken)` resolves `tokenConfigs[underlying symbol?]` (KAVA-native → key `"hKAVA"`, ATOM → `"ATOM"`, USDT → `"USDt"`) → `Pyth.getPriceNoOlderThan(feedId, 1260)`. Feeds: KAVA/USD `0xa6e905d4…`, ATOM/USD `0xb00b60f8…`, USDT/USD `0x2b89b9dc…`.
4. **A Hover-native reward system** (esHOV/HOV/native) with `claimReward`, plus three **GenesisPool** staking contracts (stake cTokens → esHOV).
5. **mint + borrow are paused per-market** (`mintGuardianPaused`, `borrowGuardianPaused`) — the Comptroller *reverts* (`"MP"`/`"BP"`) rather than returning an error code.

## 3. Exact call-path evidence (all reads; eth_call simulations only)

| Claim | Call (block) | Result |
|---|---|---|
| Market admin = Safe; no pending admin | `hUSDT.admin()` etc. (23,034,510) | `0xcecC934494adED6c0c82C52656a845862176ceeE`; `pendingAdmin=0` |
| Mint blocked | `hUSDT.mint(1e6)` (23,035,4xx) | revert `Error("MP")` |
| Borrow blocked | `hUSDT.borrow(1e6)` | revert `Error("BP")` |
| Attacker cannot liquidate | `Comptroller.liquidateBorrowAllowed(hUSDT,hKAVA,0x1111…,borrower,1e6)` (23,035,488) | returns **1** (`UNAUTHORIZED`) |
| Attacker cannot liquidate (market-level) | `hUSDT.liquidateBorrow(borrower,1e6,hKAVA)` from `0x1111…` | returns **3** (`COMPTROLLER_REJECTION`); inner code 1 |
| Whitelisted bot passes allowlist, then hits the oracle | `liquidateBorrowAllowed(hUSDT,hKAVA,BOT2,borrower,1e6)` | **reverts `0x19abf40e` = `StalePrice()`** |
| `hUSDT.liquidateBorrow` from BOT2 | same as above, market-level | reverts `StalePrice` |
| Oracle dead | `oracle.getUnderlyingPrice(hKAVA/hATOM/hUSDT)` | all revert `0x19abf40e` |
| Pyth feeds frozen | `Pyth.getPriceUnsafe(feed)` | publishTime **1774775979** (2026-03-29) for all three; chain time 1792064506 → **~200 days stale**; last KAVA $0.05403 / ATOM $1.65717 / USDT $0.99920 |
| Refresh is free | `Pyth.singleUpdateFeeInWei()` | **0**; version 1.3.0 (UUPS) |
| Allowlist contents | `allowedAddressesLength()=2`, `allowed(BOT2)=true`, `allowed(attacker)=false`, `allowed(Safe)=false` | `allow()` from outsider → `Ownable: caller is not the owner` |
| Direct seize blocked | `hKAVA.seize(attacker,victim,1)` / `Comptroller.seizeAllowed(hKAVA,attacker,attacker,victim,1)` | `3` / `9` (`MARKET_NOT_LISTED`) |
| Reserves are admin-only | `hUSDT._reduceReserves(0)` from `0x1111…` / from Safe | `1` (`UNAUTHORIZED`) / `0` |
| Stray-token sweep is admin-only | `hUSDT.sweepToken(uUSDT)` from `0x1111…` | revert `"CErc20Delegator::sweepToken: only admin may call"` |
| GenesisPool drain blocked | `GenesisPool.emergencyWithdraw(token)` from `0x1111…` | revert `"admin only"` for every token |
| GenesisPool rewards are user-scoped | `getClaimableRewards()`/`supplyAmount(0x1111…)` = 0; `claimRewards()` from outsider transfers nothing; `redeem(1e18)` from outsider reverts | no outsider value |
| Reward pot is holder-only | `claimReward(1,attacker)` | attacker KAVA/HOV/USDT unchanged; `rewardAccrued(1,attacker)=0` |
| Bot proceeds are the team's | historical tx `0x002f6c9b…` (block 17,563,567) | caller `0x960ee067…` (unprivileged keeper EOA) ended with **+0**; profit (5.1743 WKAVA) was sent to `profitWallet 0xbA6f82F7…`; `profitWallet()` is a storage var, not `msg.sender` |
| Impl contracts are empty | `balanceOf(impl)`/native for impl `0xA52BCcBd…`,`0xE469fDda…`,`0x80B4fa5C…` | 0 |
| HOV/esHOV/xHOV have no market | DefiLlama `kava:0xCe82…/0xD345…/0xD6aD…` → `{}`; CoinGecko contract lookup → "coin not found" | $0 realisable |

## 4. Borrower / position census (full-history event enumeration, not sampling)

All `Borrow` events were scanned from each market's launch to the tip using `eth_getLogs` over 1.5M-block ranges on `evm.kava-rpc.com` (which retains full history; `evm.kava.io`/publicnode cap ranges at 10k):
**hKAVA 13,453 events / 111 unique borrowers · hATOM 1,303 / 74 · hUSDT 17,205 / 66 → 160 unique addresses** (the same 2023-2024 launch wave; hKAVA's first borrow is block 8,679,145, 2024-02-21).

Current positions were read with `getAccountSnapshot` on all three markets for all 160 addresses (`analysis/borrowers.py`): **19 addresses still carry debt**; 4 are underwater:

| Borrower | Collateral | Debt | Shortfall | Max repay | Gross bonus |
|---|---|---|---|---|---|
| `0x5b484cf225cc252918034653d5ff92cf979e6cb2` | 30,341.41 KAVA in hKAVA ($2,078.65) | 7,743.51 USDT (hUSDT) | $6,489.37 | $1,979.67 | **$98.98** |
| `0xf9c3ffa841a7618ea1c09499b4b3153bed2ee626` | 11,581.41 KAVA in hKAVA ($793.43) | 4,115.92 USDT (hUSDT) | $3,636.17 | $755.65 | **$37.78** |
| `0xb622a77180563067908549717fe5eb696c44a9df` | — | 234.84 USDT | $234.63 | $0 | $0 |
| `0xb9b6c87943f8c18e1268e481ebcd7ecf411b7e5b` | dust hUSDT | 68.50 KAVA | $4.69 | ~$0 | ~$0 |
| 2 dust positions | | | $0.95 | | ~$0 |

Total shortfall $10,365.81; total collateral of the underwater positions **$2,872.08**; **maximum gross liquidation bonus ≈ $136.77** (5% of the seizeable collateral). Costs a real liquidator would bear: gas ≈ 1.15M (measured on the historical liquidation) at 1 gwei ≈ **1.15 KAVA ≈ $0.08**, and the flash-loan fee observed on Hover's own historical liquidation (tx `0x002f6c9b…`: 100.000000 USDT borrowed → 100.150001 repaid = **0.15%**, ≈ $4.10 on the full $2,735 repay) → the bot's realistic net ≈ **$132**. It is only reachable by the 2 allowlisted bots, and only after a Pyth refresh.

**Holder census** (complete, from Transfer events — balances sum exactly to totalSupply):
- hKAVA: the two underwater borrowers hold **93.8%** (1,511,349.70 + 576,886.70 of 2,224,575.23); the hKAVA GenesisPool holds 104,978.09 (4.72%).
- hUSDT: `0x319bf294…` (the hKAVA debtor, **healthy**: 17,637.88 KAVA debt vs 9,259.25 USDT collateral) holds **89.7%**; hUSDT GenesisPool 7.8%.
- hATOM: fragmented (top: 3,729.91).
- Both underwater borrowers and most large holders **entered** the markets (`getAssetsIn`), so their `redeem`/`transfer` is oracle-gated too. Only non-members can redeem today (the bypass in `redeemAllowedInternal`: "if the redeemer is not 'in' the market, bypass the liquidity check").

## 5. What an attacker can/cannot do today

**Cannot (all evidence above):** mint, borrow, redeem value (no cTokens), liquidate (allowlist + oracle), seize (caller gate), claim rewards (nothing accrued), sweep/reduce reserves (admin), drain the bots/pools (nothing there to take, plus admin gates), inflate the exchange rate profitably (force-feed is a loss), and there is no DEX market for cTokens or HOV to buy into.

**Can (net $0 or negative):** call bot2's public `liquidateBorrow(...)` (0x1f147b2d) as an unprivileged keeper — it reverts today (oracle), and if it ever succeeds the profit is the team's, not the caller's; send KAVA to the markets (reverts) or force-feed via selfdestruct (pure donation); trigger `claimReward`/`claimRewards` for any holder (pays the holder); permissionlessly refresh the Pyth feeds (fee 0) — which re-arms the *bots'* liquidation path, not the attacker's.

## 6. Fork-verification (CI)

`test/HoverFork.t.sol` — 9 tests in 4 groups; designed for `poc/test/HoverFork.t.sol` with
`vm.createSelectFork(vm.envOr("KAVA_RPC_URL", string("https://evm.kava.io")))` (no pin; all assertions are state-robust or deliberately tripwire-flavoured):

| Test | Proves |
|---|---|
| `test_T1_state_invariants` | live state reproduced: admin = Safe, closeFactor/liqIncentive, per-market supply/cash/borrows/reserves/exchange rate; `getCash()==address(hKAVA).balance`; hUSDT cash dust vs >10k USDT borrows |
| `test_T2a_mint_and_borrow_globally_paused` | `mint`→`"MP"`, `borrow`→`"BP"` on all markets (all flags true) |
| `test_T2b_liquidation_allowlist_blocks_outsiders` | allowlist = exactly [BOT1, BOT2]; attacker not in it and cannot self-add; `liquidateBorrowAllowed(attacker)==1`; `seize()`→3; `seizeAllowed`→9 |
| `test_T2c_oracle_is_stale_all_liquidity_checks_revert` | all three oracle calls revert `0x19abf40e`; Pyth publishTime > 1 day stale; `singleUpdateFeeInWei()==0` |
| `test_T3a_attacker_cannot_route_liquidation_through_whitelisted_bot` | attacker-caller to bot2 nets 0 KAVA / 0 USDT; `profitWallet()` is the team EOA |
| `test_T3b_attacker_without_ctokens_cannot_redeem_value` | redeem with no cTokens → no gain |
| `test_T3c_attacker_cannot_claim_rewards_it_did_not_earn` | `claimReward(1,attacker)` moves nothing; accrued = 0 |
| `test_T3d_donation_and_forcefeed_are_attacker_losses` | direct send reverts (`MP`); selfdestruct force-feed raises the exchange rate but costs the attacker exactly 2 KAVA and yields 0 cTokens |
| `test_T4_tripwire_oracle_refresh_opens_liquidations_for_bot_only` | with the oracle mocked fresh: `liquidateBorrowAllowed(BOT2)==0` (bot can liquidate) while the attacker still gets `1`; proceeds still go to `profitWallet` |

## 7. Residual / latent risk and monitors

- **Pyth staleness is the master switch**: one permissionless `Pyth.updatePriceFeeds(bytes[])` (fee 0, ~1M gas) re-enables the whole oracle for 1,260 s. Monitor the three feed publish times. (Fresh VAA acquisition now needs a Pyth API key — `/v2/updates/price/latest` → 401 — which is an operational, not a contractual, barrier.)
- **Liquidation window**: after a refresh, ≈$137 gross bonus is available to the 2 bots (and the hKAVA/hATOM cash becomes a member-redeem race). If the team never refreshes, the underwater borrowers remain un-liquidatable indefinitely (their positions also can't be moved: members cannot transfer/redeem while the oracle is stale).
- **Safe is 2-of-8** with `pendingAdmin=0`/`pendingComptrollerImplementation=0`: compromise of 2 keys ⇒ full protocol control (pause flags, oracle prices, allowlist, reserves ≈ $139 KAVA + $1,780 USDT admin-sweepable). Not an E-U path.
- **GenesisPools are upgradeable** (impl settable via `becomeImplementation`/pending-implementation flow, admin = Safe): staker funds (104,978 hKAVA cTokens + esHOV) are only as safe as the Safe.
- **Both liquidation bots expose an unguarded `withdraw(address token)`** (a random caller's `withdraw(uUSDT)` does not revert) — today it yields nothing (both bots hold 0 of every asset and the historical flow forwards proceeds to `profitWallet` inside the same tx), but any future token residue in a bot is free for anyone to take. Latent, $0 today.
- **Rewards**: all emission speeds are 1 wei/s; the residual pots (comptroller 674 KAVA + 15.97 HOV + 9.71 esHOV; pools ≈215,387 esHOV) are claimable only by the users they accrued to.

## 8. Methodology, caveats, files

**Method.** (1) Contract identity/state: `eth_call`/`eth_getStorageAt`/`eth_getCode` at pinned blocks; Sourcify v2 verified sources (Unitroller, CErc20Delegator/Delegate, CNativeDelegator/Delegate — runtime bytecode equality checked); unverified contracts (oracle, Pyth proxy/impl, both liquidation bots, GenesisPools) analysed via bytecode strings/selector tables + `4byte.directory`. (2) Full-history log enumeration via `evm.kava-rpc.com` (1.5M-block `eth_getLogs` ranges). (3) Position/health math from `getAccountSnapshot` × exchange rates × DefiLlama prices in `analysis/borrowers.py` (160/160 addresses). (4) Every gate was probed with `eth_call` simulations from arbitrary addresses (never with a signed transaction).

**Caveats.** Prices are DefiLlama at chain ts 1792058644; the *on-chain* oracle's last (stale) prices were KAVA $0.05403 / ATOM $1.65717 / USDT $0.99920 (publishTime 1774775979, ≈2026-03-29) — a refresh with the same magnitude keeps the two underwater positions underwater (debt/collateral ≈ 3.7× and 5.2×), so the liquidation conclusion is not price-sensitive. The fork suite asserts current pause/allowlist state: if the team changes it, those tests *should* fail loudly (by design). `kavascan.com` was unavailable for most of the survey (502), so explorer cross-checks were replaced by direct RPC + logs.

**Files.**
- `analysis/` — `rpc.py` (keyless batch JSON-RPC), `dump_state.py`/`dump2.py` (state dumps), `fetch_sources.py` + `sources/`, `sources_sol/` (verified sources/ABIs), `scan_full.py`/`scan_logs.py` (log enumeration), `borrowers.py`, `build_final.py`, `logs_*.json` (raw events), `holders_*.json`, `holders_membership.json`, `borrowers.json`, `state_v2.json`, `state_raw.json`, `hermes.json`, `stale.log`, `genesis.log`, `code/` (runtime bytecode)
- `state.json` (machine-readable live state), `state.md` (human-readable), `oracle.md` (oracle deep-dive), `borrowers.csv` (all 160 borrowers with per-market positions/shortfalls/bonus), `summary.json` (campaign schema)
- `test/HoverFork.t.sol` (CI suite)
