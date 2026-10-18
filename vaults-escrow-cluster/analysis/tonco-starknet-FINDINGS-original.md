# ZOMBIE-HUNT IV — TONCO V2 (TON) / Extended (Starknet)

**Date:** 2026-10-18 (UTC)
**Mode:** read-only. No transactions, no signing, no writes outside
`vaults-escrow-cluster/analysis/tonco-starknet/`.
**Heights used:**
- TON masterchain seqno **99,765,186**, `gen_utime` **1792306256** (toncenter `masterchainInfo`).
- Starknet mainnet block **16,553,213** for the final class/treasury reads (Cartridge RPC;
  earlier core reads at 16,551,378 and 16,552,967 gave the same class hash).
- USD prices: DefiLlama coins API timestamp **1792305907** (ETH $2,411.44, BTC $81,676.08,
  USDT $0.99912, USDC $0.99977); TONCO tsTON price from tonapi at **1792301451** ($1.572219).

---

## Verdict table

| Target | Headline E-U | Confidence | Other categories | Verdict |
|---|---:|---|---|---|
| **TONCO V2 (TON)** | **$0** | **High** | H-O (low), P (admin/governance) | No unprivileged extraction found. Router `PAY_TO` is sender-authenticated (exit 111); factory `CREATE_POOL` reaches the live pool but `POOLV3_INIT` is rejected (exit 82); fake jetton notifications are accepted but the pool address is derived from `sender_address`, so they cannot target a live pool. |
| **Extended (Starknet)** | **$0** | **Medium** | P (operator/gov/upgrade), S (TVL overlap, class mismatch) | No unprivileged value path in the live 122-entrypoint Core. Withdrawals/transfers need operator nonce + user-signed approval; forced withdraw needs the owner's signature and a governor-enabled escape hatch; treasury withdrawal is Core-only. The task's class hash `0x055ca...` is a Nov-2025 class with no indexed mainnet instance; the live spot-enabled Core is class `0x2009d...` (May 2026). |

---

## 1) TONCO V2 (TON)

### 1.1 Addresses and roles (verified on-chain)

| Role | Address | Raw |
|---|---|---|
| Router | `EQAT0nCO20vC6gzpyUJbWI7ELnRvAAB3VHJ3Z1jXQsw6KGJ4` | `0:13d2708edb4bc2ea0ce9c9425b588ec42e746f0000775472776758d742cc3a28` |
| wGRAM jetton wallet | `EQC7D80WjxMZZmvdCJxWhR-X69p-WesFsRtn-fu-hq_MQY3S` | `0:bb0fcd168f1319666bdd089c56851f97ebda7e59eb05b11b67f9fbbe86afcc41` |
| Pool factory | `EQDfACt0RyDSCwz89WJyF7hgq3vCLVwhRN7YBmVJDj4iAh0o` | `0:df002b744720d20b0cfcf5627217b860ab7bc22d5c2144ded80665490e3e2202` |
| Router admin | `EQB_KING_xJKbdCK4jujREmQm6ePnYSql9VXepHhLxl9aA-R` | `0:7f288346ff124a6dd08ae23ba34449909ba78f9d84aa97d5577a91e12f197d68` |
| Router pool-admin | `EQA_CO_XYJU_vp16Oh6yOmd2nee1TkHaxBUK73D7_L7Y0UH_` | `0:3f08efd760953fbe9d7a3a1eb23a67769de7b54e41dac4150aef70fbfcbed8d1` |
| tsTON/USDT pool | `EQDNwgDBGCTSfWAUnQcoB1BdjZUaZJtlC0WyaImETIqu0r_S` | `0:cdc200c11824d27d60149d072807505d8d951a649b650b45b26889844c8aaed2` |
| wGRAM/USDT pool | `EQBPTSLamspzALssCkevAbqS2J3GtH7E5Z0tm6XI0DaPyWzE` | `0:4f4d22da9aca7300bb2c0a47af01ba92d89dc6b47ec4e59d2d9ba5c8d0368fc9` |
| tsTON minter | `EQC98_qAmNEptUtPc7W6xdHh_ZHrBUFpw5Ft_IzNU20QAJav` | `0:bdf3fa8098d129b54b4f73b5bac5d1e1fd91eb054169c3916dfc8ccd536d1000` |
| USDT minter | `EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs` | `0:b113a994b5024a16719f69139328eb759596c38a25f59028b146fecdc3621dfe` |
| Router tsTON wallet | `EQC-HTMbYjoHOvv5C9rHEFK2lCULjVgEpprN8D-gA31TzSQb` | `0:be1d331b623a073afbf90bdac71052b694250b8d5804a69acdf03fa0037d53cd` |
| Router USDT wallet | `EQDjX82ToswIYIKdhm8kfa8k4UEzaT9F0J0Q5SG-G_jC2gnF` | `0:e35fcd93a2cc0860829d866f247daf24e14133693f45d09d10e521be1bf8c2da` |

`getRouterState` returned admin, pool_admin, factory, and the wGRAM wallet as the fourth address,
with flags `0x500000003`, seqno `39`, timelock `16000`.
The tsTON/USDT pool's stored router is the router above, admin/controller is `EQA_CO...`
(the router's `pool_admin`), and it is active (`getIsActive = -1`).

### 1.2 TVL (real, on-chain)

Router jetton balances at the read (tonapi, USD prices at 1792301451):

| Asset | Amount | USD |
|---|---:|---:|
| tsTON | 1,477,119.0325 | $2,322,354.74 |
| USDT | 70,930.7950 | $70,852.86 |
| wGRAM | 86,188.4342 | n/a (proxy token; price 0 on tonapi) |
| other/dust | — | ~$1.3k |
| **Router total (excl. fake OPENAI price)** | | **~$2.39M** |

The router's `OPENAI` jetton shows a fake $5.24M tonapi price and is excluded from TVL.

Pool reserves (`getPoolStateAndConfiguration`, raw units):

| Pool | Reserve0 | Reserve1 | USD |
|---|---:|---:|---:|
| tsTON/USDT `EQDNwgD...` | 1,476,986.507077531 tsTON | 59,919.913412 USDT | **$2,382,000.46** |
| wGRAM/USDT `EQBPTS...` | 85,413.798439258 wGRAM | 11,625.432561 USDT | **$23,238.09** (implied wGRAM $0.136107) |

**Two-pool total: $2,405,238.55.** DefiLlama TONCO V2 at 1792304207: **$2,503,881.97** (Δ $98,643, 3.9%;
other pools/fees). The values are consistent; the on-chain number is the defensible one.

### 1.3 What blocks/allows extraction — tests

All tests were **local TON sandbox emulation** (`@ton/sandbox`) with the live router code/data and
live pool code/data loaded as accounts. No network transactions were sent. Scripts and raw console
outputs are in `tonco/sandbox/`.

**(a) `ROUTERV3_PAY_TO` from an arbitrary sender — blocked (exit 111).**
The exact real `PAY_TO` body from trace
`fc934a68eab6b09d4e77104169f87cd364b20cc7bbf1a375f892428b4818b723` (pool → router, op `0xa1daa96d`)
was replayed to the router from a sandbox treasury. Result: router compute phase **exit 111**
(`ROUTERV3_INVALID_CALLER`), transaction aborted and bounced.
`payto2.js` / `payto_output.txt`.

This is the main custody path: the router holds the jettons; the pool tells it to pay. A random caller
cannot trigger a payout.

**(b) `POOLV3_INIT` on a live pool via permissionless factory — blocked (exit 82).**
A real `ROUTERV3_CREATE_POOL` body (from toncenter tx with `decoded_opcode=tonco_router_create_pool`,
factory `0xdf002b...`) was modified to the live tsTON/USDT wallets, spacing 60, current price, fees
2000/20/20, and sent to the router from the factory address. The router accepted (exit 0) and sent
`POOLV3_INIT` (`0x441c39ed`) to the live pool `EQDNwgD...`. The pool rejected it with **exit 82**
(`POOLV3_INVALID_CALLER`) and stayed active (`getIsActive = -1`).
`reinit.js` / `reinit_output.txt`.

The docs say the factory is callable by anyone and that `POOLV3_INIT` is used by the pool admin to
change parameters. The on-chain result shows the live pool rejects the router-forwarded factory init
(exit 82); the only remaining re-init path is the pool admin (`EQA_CO...`). Re-init is privileged,
not unprivileged.

**(c) Fake `JETTON_TRANSFER_NOTIFICATION` — sender is not checked, but the pool is sender-derived.**
The exact real notify body from the same trace (from router tsTON wallet `0:be1d...`, amount
65.3525876 tsTON, forward payload `POOLV3_SWAP` `0xa7fb58f8`) was replayed to the router from a
sandbox treasury. The router **accepted** it (exit 0) and forwarded `POOLV3_SWAP` to
`EQAdlH-dLZ839GZG33cbgsZQ6yHEEhOGuq4pHmCxZHRGqFDY` (`0:1d947f9d...`), which tonapi reports as
`status: nonexist`. The swap bounced and the router refunded.
`notify.js` / `notify_output.txt`.

This proves the router does not authenticate the notification sender. The forwarded pool address is
derived from `sender_address` and the payload's router jetton wallet (the replay changed only the sender
and the computed pool changed from the live `EQDNwgD...` to a nonexistent address). To reach a live pool,
the sender would have to be that pool's input jetton wallet (the router's own wallet), which an attacker
cannot control. An attacker can create
a pool whose input wallet is theirs and whose output is a real jetton, but that pool has only the
liquidity the attacker (or later LPs) put in it; faking the input amount yields no net gain against
current TVL. This is a **hardening gap**, not a current extraction path.

### 1.4 TONCO verdict

- **E-U: $0**, confidence **High** for current live pools. The value-bearing paths (`PAY_TO`, pool init,
  pool swap/mint via router) are gated by sender/pool identity; the fake-notify gap is bounded by
  sender-derived pool addresses.
- **H-O (low):** missing explicit `sender_address == router jetton wallet` check in the notify handler.
  It is defense-in-depth; a future pool design or a jetton-wallet compromise would turn it into a drain.
- **P:** pool admin `EQA_CO...` can re-init/change fees/lock; router admin can upgrade/change params;
  factory can create new pools permissionlessly (by design).
- **S:** tonapi shows a fake $5.24M `OPENAI` price on the router; ignore it. DL $2.50M vs on-chain
  $2.41M is within 3.9%.

---

## 2) Extended (Starknet)

### 2.1 Class hash verification — the task's class hash is not the live deployment

| Item | Published in docs | Live on Starknet |
|---|---|---|
| Class hash | `0x055ca2019a8677a996e7b583c5c9d0147d2854d0c477716af685e926ee4a5463` | `0x2009d10834de7d068e1339f4984b85fd8ee625e5b29dc67a55dcc46433add59` |
| Declared | 2025-11-03 08:34:39 UTC | 2026-05-08 03:08:11 UTC |
| Compiler | 2.12.2 | 2.15.0 |
| External entrypoints | 83 (33 read / 50 write) | 122 (41 read / 81 write) |
| Source | verified (Voyager) | verified (Voyager) |
| Deployed instances | **0** (Voyager: "No contracts found"; Starkscan: "No indexed instances") | Core `0x062da...` |
| Spot/forced functions | absent | present (`add_spot_asset`, `liquidate_spot_asset`, `forced_withdraw*`, `enable_escape_hatch`, `get_treasury_address`) |

The live Core contract `0x062da0780fae50d68cecaa5a051606dc21217ba290969b302db4dd99d2e9b470`
was created 2025-07-17; its **current** class `0x2009d` was declared 2026-05-08, consistent with an
in-place upgrade of the existing Core. The June-2026 "spot deployment" is consistent with that upgrade
plus activation of spot markets (the exact June activation date was not independently established;
the class declaration is 2026-05-08). The task's `0x055ca` class is an older class with no indexed
mainnet deployed instance.
`starknet_getClassHashAt(core, block 16,553,213)` returns `0x2009d...`.

The closest public source is the `x10xchange/starknet-perpetual` branch `clean_multi_spot_diff`
(last commit 2026-03-02), which contains the forced/spot code; the `dev` branch (2026-04-21) does not
contain `forced_withdraw`/`enable_escape_hatch`. The `audited_version` branch also lacks those functions.
Exact commit/bytecode match was not proven; the Voyager-verified class is the authoritative source.
See `extended/entrypoints.md`.

**Audit-coverage gap:** the public Code4rena 2025-03 report predates the live May-2026 class. The live
class adds spot assets, forced-withdraw/escape-hatch, vault-protection and interest functions that are
not in the audited snapshot. No public audit covering those additions was found in the docs (the docs
link only ChainSecurity and the 2025-03 Code4rena report). This is a verification/coverage risk (S),
not evidence of an exploitable path.

### 2.2 TVL (real, on-chain)

The exchange's funds sit in the **Protocol Treasury**
`0x60c0f8cdfa28e8a3f719d1e2def2599785d7557a5650794c150d9b557603e48`
(class `0x202f7d8d...`; `get_perps_contract` = `0x062da...`), not in the Core contract
(the Core itself held only dust at block 16,553,213: 103.83 USDC.e, 0.01 ETH, and 0 USDC/USDT/WBTC).

Treasury balances at Starknet block **16,553,213**:

| Asset | Amount | USD (DefiLlama, ts 1792305907) |
|---|---:|---:|
| USDC.e (`0x33068f...`, 6 dp) | 110,190,871.756776 | $110,165,150.61 |
| USDT (`0x068f5c...`, 6 dp) | 918,615.799668 | $917,807.85 |
| ETH (`0x049d36...`, 18 dp) | 692.230614 | $1,669,269.49 |
| WBTC (`0x03fe2b...`, 8 dp) | 33.09262248 | $2,702,875.72 |
| **Total** | | **$115,455,103.66** |

Comparison:
- DefiLlama **Extended Perps**: $115,579,672 total at 1792302143; Starknet portion **$115,424,672.84**
  (Δ $30,431, 0.026%). This matches the treasury total.
- DefiLlama **Extended Spot**: **$2,743,189.19** at 1792304075.
- The treasury's spot-eligible assets (USDT+ETH+WBTC) total **$5,289,953.06**.
- Conclusion: DL Spot strongly indicates an **orderbook-locked subset/overlap** of the same treasury,
  not additive to DL Perps. Adding $115.42M + $2.74M would double-count the same collateral. This is a
  data-quality (S) issue, not a security bug.

### 2.3 Unprivileged value paths — code review

Live ABI: 122 external entrypoints. The value-bearing ones:

- **`withdraw_request`** — user-signed; registers an approval keyed by the position owner's public key.
- **`withdraw`** — operator-only (`operator_nonce.use_checked_nonce`), consumes the user's approved
  request, checks health, decrements the position, calls `treasury.withdraw_from` (Core-only) and
  transfers to the recipient.
- **`transfer_request` / `transfer`** — same signed-request + operator-nonce model.
- **`forced_withdraw_request`** — requires `_is_escape_hatch_enabled()` (only the app governor can enable
  it), the position owner's signature, and the caller pays a premium; **`forced_withdraw`** runs after a
  timelock and consumes the approval. A third party cannot force another user's position.
- **`enable_escape_hatch`** — `roles.only_app_governor()`.
- **Treasury `withdraw_from`** — `assert(get_caller_address() == perps_contract, 'ONLY_PERPS_CAN_WITHDRAW')`.
- **`deposit` / `deposit_asset`** — user-initiated; asset config validated; `process_deposit` is
  operator-only; `cancel_deposit` is depositor-only after a delay.
- **Upgrades** — `add_new_implementation` / `replace_to` are role-gated and timelocked.
- **Vault share price** — the ERC4626 vault's `before_deposit`/`before_withdraw` require the perps contract
  as caller/receiver/owner, and `get_total_assets` is the Core position's TVTR (not the token balance), so
  the vault is not publicly depositabled and a donation/share-inflation attack is not available.
- **`liquidate_spot_asset`**, **`apply_interests`**, **`update_exchange_time`**, **`price_tick`**,
  **`funding_tick`** — operator/governance gated.

No unprivileged entrypoint was found that moves another user's collateral, mints shares without
funding, or withdraws from the treasury. The operator/sequencer remains a liveness trust anchor;
the escape hatch is the user-protection path.

### 2.4 Extended verdict

- **E-U: $0**, confidence **Medium**. The live Core is source-verified (with post-audit spot/forced
  additions) and the value paths are operator/signature gated; the treasury is Core-only. Confidence is
  medium rather than high because (i) the exact public source commit matching class `0x2009d` was not
  proven, (ii) the contract is upgradeable by governance, and (iii) the operator/sequencer can
  pause/liveness-block withdrawals (escape hatch mitigates but is governor-enabled).
- **P:** operator nonces, governance upgrades, app-governor escape hatch, sequencer liveness.
- **S:** (1) DL Spot and DL Perps share the same treasury — do not add them; (2) the docs' class hash
  `0x055ca` is an undeployed older class; (3) migration to Arc is scheduled for **2026-10-22 12:00 UTC**
  (docs published 2026-10-08): deposits/withdrawals paused up to 2 hours, USDT/wBTC conversion or
  withdrawal deadline **2026-10-21 12:00 UTC**, accounts then migrate to Arc. This changes the trust
  surface after the analysis date.

---

## 3) Negative results / what was ruled out

- TONCO router `PAY_TO` unauthenticated drain — **ruled out** (exit 111).
- TONCO factory re-init of a live pool — **ruled out** (pool exit 82; state unchanged).
- TONCO fake jetton notification against a live pool — **not reachable** (pool address derived from
  sender; real notify replay from a different sender produced a nonexistent pool).
- Extended `withdraw` without a user approval — **ruled out** (approval consumption).
- Extended `forced_withdraw` by a third party — **ruled out** (owner signature + governor escape hatch).
- Extended treasury `withdraw_from` by a non-Core caller — **ruled out** (ONLY_PERPS_CAN_WITHDRAW).
- Extended fake-token deposit credit — no path found; deposits validate the registered asset and
  transfer the token; the operator processes them.
- Extended vault share-price/donation attack — **ruled out**: only the perps Core can deposit/withdraw
  from the ERC4626 vault, and `total_assets` is the Core position TVTR, not the token balance.
- TONCO verified source — not available on `verifier.ton.org` registry for the router code hash; the
  docs + on-chain getters + sandbox emulation were used instead.
- TON code disassembly (`tvm-disassembler`, `@scaleton/tvm-disassembler`) — **failed** to decode the
  router code cell (Fift-like dump, "Prefix not found"); not used as evidence.

## 4) Search trail / blockers

**TONCO**
1. tonapi `/v2/accounts/{router}` and `/jettons` → balances, wallet addresses.
2. toncenter v3 `accountStates`, `runGetMethod` (`getRouterState`, `getPoolAddress`,
   `getPoolStateAndConfiguration`) → roles, pools, reserves.
3. `docs.tonco.io` — the old `contracts-v1/*.html` paths 302 to `/en/`; the live pages are under
   `/en/technical-reference/contracts-v1/{scenarios-v1,router,pool,pool_factory}.html`.
4. `cryptoalgebra/tonco-sdk` and `tonco-demo` — message formats, getter order, opcodes.
5. `ton-blockchain/verifier` SourcesRegistry (`EQD-BJS...`) — no deployed source item for the router
   code hash under `verifier.ton.org`/orbs/tonkeeper.
6. Local `@ton/sandbox` emulation with live code/data — the three auth tests above.
7. Blocker: no public FunC/Tolk source for the deployed router/pool; conclusions rest on docs,
   on-chain getters, and sandbox behavior.

**Extended**
1. Blast and Lava Starknet RPC are dead; used `https://api.cartridge.gg/x/starknet/mainnet`
   (OnFinality also worked).
2. `starknet_getClassHashAt`/`starknet_getClass` for `0x062da...`, `0x055ca...`, treasury.
3. Voyager/Starkscan rendered via Firecrawl (their APIs return 403) — class declaration dates,
   compiler versions, source status, instance counts.
4. `x10xchange/starknet-perpetual` — `dev`, `audited_version`, `activate_spot_assets`,
   `allow_transfer_of_spot`, `change-escape-hatch-governor`, `clean_multi_spot_diff`.
5. `workspace/treasury/src/protocol_treasury.cairo`, `deposit_manager.cairo`,
   `withdrawal_manager.cairo`, `core.cairo` — auth review.
6. Extended API `/info/markets` and `/info/assets` — spot markets and synthetic IDs.
7. Blocker: exact source/commit for class `0x2009d` not proven; local Sierra hash recomputation with
   `starknet.js` did not reproduce the on-chain hash (RPC serialization), so it was not used.
8. Blocker: spot orderbook TVL is off-chain/orderbook data; on-chain treasury cannot separate spot from
   perps collateral. The $115.46M treasury total is the defensible on-chain number.
9. Blocker: if Extended Spot is settled on the separate STARKX appchain rather than Starknet mainnet,
   that appchain's contract set/class hash was not reachable via the public mainnet RPC. The mainnet
   Core/treasury analysis covers the collateral custody we could verify; the appchain deployment (and
   the `0x055ca` class if it lives there) remains unverified.

## 5) Evidence files

```
analysis/tonco-starknet/
  FINDINGS.md
  tonco/
    onchain_state.json          # masterchain height, router state, both pool states, reserves
    pool_tvl.json               # USD math for both pools
    docs_excerpts.md            # exact quotes from the live TONCO docs
    sandbox/
      payto.js, payto_output.txt        # arbitrary PAY_TO -> exit 111
      notify.js, notify_output.txt      # fake notify -> sender-derived pool
      reinit.js, reinit_output.txt      # factory CREATE_POOL -> pool exit 82
  extended/
    heights.json                # block 16,553,213, core/treasury class hashes
    class_info.json             # live vs published class metadata
    live_abi_functions.json     # 122 live entrypoints
    published_abi_functions.json# 83 published-class entrypoints
    treasury_balances.json      # raw balances at the block
    treasury_usd.json           # USD at DefiLlama prices
    spot_markets.json           # USDTSPOT/ETHSPOT/BTCSPOT config
    auth_notes.md               # withdrawal/forced/treasury/deposit auth
    entrypoints.md              # class hash + entrypoint diff + repo comparison
```

**Bottom line:** both targets return **$0 externally-unprivileged extractable value today**.
TONCO's custody path is sender-authenticated and the live pool rejects factory re-init; the fake-notify
gap is real but bounded by sender-derived pool addresses. Extended's live spot-enabled Core and treasury
are operator/signature gated; the published class hash is stale and not deployed, and DL's spot TVL
overlaps the perps treasury rather than adding to it.
