# MakerDAO legacy auction-keeper family — full Flipper + sibling-keeper sweep

**Target:** `0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273` (EIP-1967 `AdminUpgradeabilityProxy`, ETH-A auction keeper)
**Chain:** Ethereum mainnet (chain id 1)
**Read block:** `26,217,462` → `2026-10-18 05:49:47 UTC`
**Incident block:** `26,131,471` → `2026-10-06 06:13:11 UTC`
**Mode:** read-only (`eth_call`, `eth_getCode`, `eth_getStorageAt`, `eth_getLogs`, Etherscan V2, Blockscout). No transaction signed or sent.

---

## 1. Method

1. Enumerated every ilk ever initialized in `MCD_VAT` by scanning the Vat's anonymous `init(bytes32)` LogNote (`topic0 = 0x3b663195…`) over blocks 8,920,000–26,217,462. Result: **78 unique ilks**.
2. Read `MCD_ILK_REGISTRY.count()` / `list()` (**35 current ilks**) and `MCD_CAT.ilks(ilk)` for every ilk. `Cat.ilks` returned a non-zero legacy Flipper for **33 ilks**.
3. Recovered older/newer Flipper generations from the two FlipperFab creation graphs (`0xbab4fbea…` 13 creates, `0x4acdbe9d…` 35 creates) plus the deployer EOA's direct creates. Filtered by `vat() == MCD_VAT`, `kicks()` succeeding and `bids(1)` decoding to 8 words. Result: **43 bid-capable Flipper contracts**, **27 with `kicks() > 0`**.
4. Scanned every bid id `1..kicks()` for all 27 active Flippers via Multicall3 at the fixed block: **6,737 bids**. Flagged `lot > 0 && guy != 0 && end < now`. Re-ran `deal(id)` as a read-only `eth_call` from `0x3333…3333` for every flagged bid.
5. For every distinct flagged `guy`: read `vat.gem(ilk, guy)` for all 78 ilks, `vat.dai(guy)`, `vat.can(guy, attackerModule)`, code, EIP-1967 slots, and ETH/WETH/DAI/KNC balances at the same block.
6. Reconstructed the keeper deployment graph from the dealer EOA, the operator EOA, both ProxyAdmins, and every `Upgraded(address)` log; fetched bytecode/codehash for each family contract.
7. Tested `drain` reachability with a read-only `eth_call` from an unrelated address, supplying the real attacker module as the worker (the module implements `vat()`, `drip()`, `join(uint256)`).

---

## 2. Address verification / chainlog corrections

| Key | Prompt / expected | Verified on-chain | Note |
|---|---|---|---|
| `MCD_VAT` | `0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B` | same | `getAddress` OK |
| `MCD_CAT` | `0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea` | same | code present; chainlog key retired (`invalid-key`) |
| `MCD_FLIP_ETH_A` | `0xd8a04F5412223F513DC55F839574430f5EC15531` | same | `ilk()`=ETH-A, `vat()`=Vat, `kicks()`=4,990; attack tx dealt ids 1457–1460 |
| `MCD_FLIP_ETH_B` | — | `0xd499d71Be9E9e5D236A07aC562f7B6CEaCCa624C` | `Cat.ilks(ETH-B).flip`, 437 kicks |
| `MCD_FLIP_ETH_C` | — | `0x7a67901a68243241ebF66BeeB0e7b5395582BF17` | 0 kicks |
| `MCD_FLIP_USDC_A` | — | `0xbe359e53038E41a1ffA47DAE39645756C80e557a` (current), `0xe6ed1d09A19Bd335F051d78D5D22DF3bFF2c28B1` (older) | both 0 kicks |
| `MCD_FLIP_WBTC_A` | — | `0x58CD24aC7322890382eE45A3E4F903a5B22Ee930` (current, 110 kicks), `0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603` (older, 3 kicks) | |
| `MCD_ILK_REGISTRY` | `0x5a464C28D19848f44199D003BeF5ecc87cD57CFF` | **no code at that address**; chainlog `ILK_REGISTRY` = `0x5a464C28D19848f44199D003BeF5ecc87d090F87` | registry address in the prompt is truncated/corrupted; the real registry has `count()=35` |
| `MCD_VOW` | — | `0xA950524441892A31ebddF91d3cEEFa04Bf454466` | |
| `MCD_DAI` | — | `0x6B175474E89094C44Da98b954EedeAC495271d0F` | |
| `MCD_FLASH` | — | `0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA` | |

Legacy chainlog keys `MCD_CAT`, `MCD_FLIP_*`, `MCD_ILK_REGISTRY` revert `dss-chain-log/invalid-key` at the current head — they were retired. The authoritative live mappings are `Cat.ilks(ilk).flip` and the registry at `…d090F87`.

---

## 3. Flipper enumeration

| Metric | Count |
|---|---:|
| Ilks ever initialized in Vat | 78 |
| IlkRegistry current `count()` | 35 |
| Ilks with non-zero `Cat.ilks(ilk).flip` | 33 |
| Bid-capable Flipper contracts | 43 |
| Flippers with `kicks() > 0` | 27 |
| Bids scanned (`Σ kicks`) | 6,737 |
| Undealt bids (`lot > 0`) | 8 |
| Expired undealt with `guy != 0` | 8 |
| Read-only `deal(id)` simulations that succeed | 8 |

All 43 Flippers have code (they answered `kicks()`/`bids()`). The 16 with `kicks() == 0` are ETH-C, GUSD-A, PAXUSD-A, PSM-USDC-A, SAI, TUSD-A (two generations), UNIV2DAIUSDC-A, UNIV2DAIUSDT-A, UNIV2USDCETH-A, UNIV2WBTCETH-A, USDC-A (two), USDC-B (two), XMPL-A. Ilks that migrated to `Clip` (WBTC-B/C, WSTETH-A/B, etc.) have no legacy Flipper.

The four incident lots (`ETH-A` ids 1457–1460, 50 ETH each) were deleted by the Oct-6 `deal()` calls and read as `lot = 0`; they are not among the 8 flags.

---

## 4. Flagged expired undealt bids (all dealable, all payable to `guy`)

| Ilk | Flipper | id | Lot | Tab (DAI) | `guy` | End (UTC) | Age (d) | Deal sim | USD @ 2026-10-18 |
|---|---|---:|---:|---:|---|---|---:|---:|---|---:|
| ETH-A | `0xd8a04F…5531` | 3190 | 0.240000 ETH | 28.4056 | `0x4d27e99aeacc3bda29a91c9dbc73afc80bc24782` | 2020-03-16 00:04:37 | 2,407.2 | OK | $578.91 |
| ETH-A | `0xd8a04F…5531` | 3563 | 0.350000 ETH | 28.4479 | `0xc2f61a6eeec48d686901d325cde9233b81c793f3` | 2020-03-16 01:08:03 | 2,407.2 | OK | $844.24 |
| ETH-A | `0xd8a04F…5531` | 3753 | 0.400000 ETH | 33.1981 | `0xc2f61a6eeec48d686901d325cde9233b81c793f3` | 2020-03-16 01:15:55 | 2,407.2 | OK | $964.85 |
| ETH-A | `0xd8a04F…5531` | 4459 | 0.499994 ETH | 39.5808 | `0xc2f61a6eeec48d686901d325cde9233b81c793f3` | 2020-03-16 03:16:49 | 2,407.1 | OK | $1,206.05 |
| ETH-A | `0xd8a04F…5531` | 4885 | 0.175927 ETH | 37.2991 | `0x04bb161c4e7583cdaadee93a8b8e6125fd661e57` | 2020-04-30 17:05:41 | 2,361.5 | OK | $424.36 |
| ETH-A | `0xd8a04F…5531` | 4886 | 0.150387 ETH | 30.5143 | `0x04bb161c4e7583cdaadee93a8b8e6125fd661e57` | 2020-04-30 17:05:41 | 2,361.5 | OK | $362.75 |
| KNC-A | `0x57b01F…3F2F` | 23 | 2,120.310064 KNC | 4,764.6254 | `0xfb04641a1ab744254706c5e0680a1dd533170a0b` | 2021-03-25 04:00:18 | 2,033.0 | OK | $255.93 |
| KNC-A | `0x57b01F…3F2F` | 24 | 2,790.166827 KNC | 5,955.2136 | `0xfb04641a1ab744254706c5e0680a1dd533170a0b` | 2021-03-25 07:00:03 | 2,033.0 | OK | $336.79 |
| **Total** | | | **1.816308 ETH + 4,910.477 KNC** | | | | | | **$4,973.88** |

`Flipper.deal(id)` is permissionless after `end`; it `vat.flux`es the lot to `bids[id].guy` and deletes the bid. The caller gets nothing. All 8 `deal` simulations succeeded.

---

## 5. Bidder (`guy`) analysis

| `guy` | Type | Vat gem | Vat dai | Flagged claim | Claim USD | Family match? |
|---|---|---|---:|---|---:|---|
| `0x4d27e99aeacc3bda29a91c9dbc73afc80bc24782` | EOA (0 code) | ETH-A 11.230357630 | ~0 | ETH-A 3190 (0.24 ETH) | $578.91 | No |
| `0xc2f61a6eeec48d686901d325cde9233b81c793f3` | EOA (0 code) | ETH-A 1.340000000; USDC-A 1e-14 | 3.954116 | ETH-A 3563/3753/4459 (1.25 ETH) | $3,015.14 | No |
| `0x04bb161c4e7583cdaadee93a8b8e6125fd661e57` | EOA (0 code) | — | 0.671257 | ETH-A 4885/4886 (0.3263 ETH) | $787.11 | No |
| `0xfb04641a1ab744254706c5e0680a1dd533170a0b` | contract, 12,955 B | WBTC-A 8.8e-9 | 1.000000 | KNC-A 23/24 (4,910.48 KNC) | $592.72 | No |

`vat.can(guy, attackerModule) = 0` for all four. `vat.can(guy, familyContract) = 0` for all four × all six family keeper contracts (victim, v2 impl/clone, v1 impl/copy, v0).

The three ETH-A bidders are EOAs with **no code**; there is no keeper contract to drain. The KNC-A bidder is a contract, but it does **not** contain selector `0x8804d1de`; it is a different Maker keeper (`cat()`, `vow()`, `jug()`, `flap()`, `flop()`, `flips(bytes32)`, `gemJoins(bytes32)`, `managers(address)`; `managers(creator) = 1`). Its only Vat value is dust; its 4,910 KNC claim is payable to itself by `deal()`, and no unprivileged path to move that gem was found.

The 11.230 ETH and 1.340 ETH Vat gem held by `0x4d27…` and `0xc2f6…` are from **other, already-settled positions** (they are free gem, not the flagged undealt lots). They are real third-party value (`~$30.3k`), but they sit in EOA accounts with no hope grant to any family contract, so the `0x8804d1de` bug cannot touch them.

---

## 6. Sibling-keeper sweep

The dealer EOA `0x52ce67ba2cd112ed7b34ae935407c215ac7b32d3` is **not a contract**; it created 6 contracts. The operator EOA `0xaDC374E77b89Af0B8B39F7c47E8e0A37B6DaF073` created 2. Both ProxyAdmins and all `Upgraded` logs were enumerated.

| Name | Address | Role | Codehash | `0x8804d1de` | Drain reachable? | Vat value |
|---|---|---|---|---|---|---|
| victim | `0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273` | EIP-1967 proxy, impl v2 | `0x0edc21cf…` (proxy runtime) | via impl | **Yes — proven by real tx** | $0 |
| impl v2 | `0x68399ed8aa33C5b43F863EE6782de492006A5546` | v2 implementation | `0x8449fde7e5cfb4412396ffcf81f266acb465dff1b705dd5cc27dcaacd62172f1` | Yes | **Yes** (read-only probe) | $0 |
| clone v2 | `0xa7a6d04dfa4e2646489a361b74e2b317c2a53608` | byte-identical v2 copy | `0x8449fde7…f1` (same) | Yes | **Yes** | $0 |
| impl v1 | `0x721dc69893cf62c532ef566e7ff2c0532343148b` | v1 implementation (initial victim impl) | `0xd9b1d1c95cf2c965fa582f37d1675d1ad27d09c9e01ba098172451fb1b0c5418` | Yes | **Yes** | $0 |
| v1 copy | `0xcf7e34f9ac4d91d3430f7c34251bda02fac13440` | byte-identical v1 copy | `0xd9b1d1c9…18` (same) | Yes | **Yes** | $0 |
| v0 keeper | `0xdaa93d669a5b06b607a675a418ce2c804e21bb7b` | older 14,962-byte keeper | `0x8fea9c6a5a1426112e88bc5884a31c615a056438ea430854c62e61ae43ecd559` | Yes | **Yes** | $0 |
| ProxyAdmin | `0x5b492f7483da1778c450b9b18f5df9d95cab8efe` | admin of victim; owner = dealer EOA | `0xc908d463…9e` | No | n/a | $0 |
| ProxyAdmin | `0x777e07b5549eb830fcbd118431d948c2f6b584fe` | second admin copy; unused | `0xc908d463…9e` | No | n/a | $0 |

**Sibling proxies: 0.** The only `Upgraded(0x68399…)` log in history is the victim at block 9,566,071. The `0x721dc698` and `0xa7a6d04` implementations have no `Upgraded` logs. Both ProxyAdmins' complete transaction histories contain no other proxy.

**Sibling implementations: 5** (v0, v1 ×2, v2 ×2), all bytecode-matched and all holding $0. The victim's proxy is the only proxy in the family.

### Drain callability evidence

- `eth_call` from `0x2222222222222222222222222222222222222222` to **each** of the six keeper contracts (`victim`, `impl v2`, `clone v2`, `impl v1`, `v1 copy`, `v0`) with `0x8804d1de` + `worker = 0xf09a…c170` + `x = 0` reverts with **`Flipper/not-finished`** — the error comes from the worker's `join(0)`, after `vat.hope(worker)` and after `worker.drip()`. There is no auth revert. This proves the selector is ungated on all six.
- The victim's real attack tx (`0xbb6940…a88c`, status 1) contains a Vat `Hope` log with `topic1 = 0xf09a…c170`, four Flipper `deal` logs for ids `0x5b1`–`0x5b4` (1457–1460), and a 200 WETH transfer/withdraw.
- Implementation dispatcher: `0x8804d1de` appears at byte offsets 21 and 114; the handler at `0x02e3` does only the Solidity `CALLVALUE` check and jumps to the body at `0x1223`. The body begins with `worker.drip()` (selector `0x9f678cca`) and never reads owner/authority. `owner()` (`0x8da5cb5b`) and `authority()` (`0xbf7e214f`) exist elsewhere but are not on the drain path.

---

## 7. Post-state and standing hope

At block 26,217,462:

- Victim proxy: ETH 0, WETH 0, DAI 0, Vat gem **0 across all 78 ilks**, Vat dai 0.
- Attacker module `0xf09a13072Ed939B79Bc25B66AA3a836ea6DCC170`: ETH 0, WETH 0, DAI 0, Vat gem 0, Vat dai 0.
- `vat.can(victim, attackerModule) = 1` — **the hope persists**.
- `vat.can(victim, attackerEOA) = 0`, `vat.can(victim, helper) = 0`.
- No GemJoin-attributable collateral for the victim: its Vat gem is 0 for every ilk; the GemJoin contracts hold pooled WETH, not a per-user claim.
- Attacker EOA `0x01EB957E5C7DcDDD60F3C875956cCc6fb9BdA5FA` still holds 0.07009 ETH dust; helper and worker hold 0.

**Implication:** the proxy's `drain` remains ungated, so any caller can grant hope to a fresh worker and take any future Vat gem/dai credited to the victim; the old attacker module also still holds `vat.can(victim, module)=1`. Either way, there is no balance today.

---

## 8. Oct-10 on-chain message lead

Cheap checks performed:

- Resolved `defimon.eth` → `0xeCb7B4FA6B3d592e42FE5E46b46276Db694984e6` and `defimon-alerts.eth` → `0x5d7152f599eFF38A7f89CA0fECE641DFc4d6e055`. Both are EOAs with **no transactions** in blocks 26,100,000–26,217,462.
- Blockscout `/api/v2/search?q=MakerDAO` and `?q=Defimon` return token/address records only, not transaction messages.
- Etherscan V2 has no full-text search over transaction input.

The relay/message was **not located**. Our independent full Flipper scan found exactly 8 unfinalised lots (6 ETH-A, 2 KNC-A), which likely covers the subject matter; no other keeper with material value surfaced. Treat the Oct-10 message as unverified.

---

## 9. Verdict

| Category | USD | Confidence | Meaning |
|---|---:|---:|---|
| **E-U (current)** | **$0** | 0.95 | No unprivileged extraction from any of the six family keeper contracts; all hold $0. |
| **E-U-conditional** | **$0** | 0.90 | The victim's `drain` remains ungated and `vat.can(victim, attackerModule)=1`; any future Vat credit to the victim is drainable by anyone, but there is no balance today. |
| **H-O (other parties)** | **$35,300.75 observed; $0 at risk** | 0.85 | 12.570 ETH-A gem + 5.625 DAI Vat balances of the four bidders, plus 8 undealt lots (1.816 ETH + 4,910 KNC). Owners are three EOAs and one non-family keeper; no hope grants to any family contract. Not attacker-extractable via this bug. |
| **P (privileged)** | **$0 current** | 0.90 | Dealer EOA owns ProxyAdmin `0x5b492f…` and can upgrade the victim, but the victim is $0. |
| **S (stranded)** | **$0** | 0.90 | No value stranded in the family contracts or attacker module. |
| **Realized loss (historical)** | **$538,000** (200 ETH; CertiK $542,982 at incident price) | 1.00 | Oct-6 tx `0xbb6940…a88c`, block 26,131,471. Not a current balance. |

**Headline: E-U $0, high confidence.** The family sweep is complete for every Flipper (all 6,737 bids) and every deployment/upgrade path of the keeper family. Five sibling implementations/copies share the ungated `0x8804d1de` drain, but all are empty. The only non-empty legacy-keeper value is held by EOAs or by a non-family KNC keeper, and none of it is reachable through this bug.

---

## 10. Caveats

- Prices: ETH $2,412.122829 and KNC $0.120705953 at 2026-10-18 06:23–06:35 UTC (DefiLlama). KNC is thin; the $592.72 KNC figure is nominal.
- A chain-wide `eth_getStorageAt` scan for the EIP-1967 impl slot is not available over public RPC. The conclusion of "no sibling proxy" rests on the complete deployer/operator/ProxyAdmin/`Upgraded` graph (dealer EOA created only the victim; operator created no proxies; the only upgrade log is the victim). An unrelated EOA deploying a proxy with this unverified impl and no event cannot be excluded by construction.
- The 12.57 ETH-A gem held by the two EOA bidders is **not** exposed to the `0x8804d1de` bug. If those keys are lost, the balances may be stranded, but key loss is not proven and is not counted in S.
- The KNC keeper contract's 4,910 KNC claim is payable to itself by permissionless `deal()`. No unprivileged exit path was identified, but its 12,955-byte unverified code was not fully audited; the $592.72 is therefore not counted as E-U.
- `MCD_FLIP_ETH_A` was verified by `ilk()`/`vat()`/`kicks()` and by the incident tx's four `deal` logs; the legacy chainlog key itself is retired, so a chainlog-only check would falsely fail.

---

## 11. Evidence files

- `flippers.json` — 78 ilks, 43 Flippers, 6,737 bids, 8 flagged rows.
- `keepers.json` — bidder state, 8 family contracts, drain probes, sibling graph, post-state.
- `summary.json` — headline numbers.
- `bids_scan.json` — raw scan output (flagged + undealt).
- `vat_state.json`, `guys_vat_state.json`, `owner_vat_state.json` — Vat balances.
- `attack_receipt.json` — Oct-6 receipt/logs.
- `flippers_clean.json`, `canonical_flippers.json`, `cat_flips.json`, `vat_inits.json` — enumeration intermediates.
- `lib.py`, `scan_bids.py`, `build_outputs.py` — read-only scripts (no embedded keys; Etherscan key read from env at runtime).
