# Weft V2 (Radix mainnet) — External-Unprivileged Extraction Audit

**Date:** 2026-10-15, ~11:00–12:10 UTC
**Chain state at verification:** state_version 563,382,553 (2026-10-15T11:45:20Z); scan window ~563,370k–563,381k
**XRD price:** $0.0004519744788105959 (DefiLlama, 2026-10-15T11:22:52Z)
**Method:** read-only Gateway queries + `transaction/preview` simulations only (never signed, never submitted). No keys used. Funding accounts inside previews are real unrelated accounts used only as simulated sources (`assume_all_signature_proofs`), per the campaign's approved read-only preview pattern.

## Target

| Entity | Address | Blueprint |
|---|---|---|
| LendingPool | `component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn` | LendingPool 1.0.0 (`package_rdx1p5uwrs3heg37n5zyzate8xtc440l2x3l59ywya4jl2na6em25qjnfj`) |
| LendingMarket | `component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w` | LendingMarket 1.0.0 (`package_rdx1pktdrmwan4mcugates06wwcvspn4y0hsapm9zkyg4clh0sf8qn7c6t`) |
| CDP ("Wefty") NFT | `resource_rdx1nt22yfvhuuhxww7jnnml5ec3yt5pkxh0qlghm6f0hz46z2wfk80s9r` | 1142 minted, 901 live |
| Price feed #1 (all resource_configs) | `component_rdx1czdvvanvdy6495phfgz8uv6n2semp2cpexcg6vvty6uaycc82adgyv` | PriceFeed 1.0.0; admin + updater badge-gated |
| Resource-pools KVS | `internal_keyvaluestore_rdx1kzjr763caq96j0kv883vy8gnf3jvrrp7dfm9zr5n0akryvzsxvyujc` (11 pools) | — |

Market roles `can_borrow`, `can_liquidate`, `can_refinance`, `can_create_cdp`, `can_flash_borrow` = **AllowAll** (any address may call). Admin/fee/oracle roles = badge-gated (P).

## Headline result

**E-U (external-unprivileged, extractable now): 264,328 XRD ≈ $119.5** in liquidation bonuses (already net of the protocol's 20% bonus cut) across 126 underwater CDPs. **Practical cap ≈ $101.5** because the three dominant targets must be repaid in hUSDC and only 1,092.79 hUSDC exist (total supply). Mechanics verified with live previews (two successful liquidation simulations, incl. a zero-capital flash-loan demo).

The big three (all verified liquidatable at 11:45Z):

| CDP | liq_ltv | Debt (must repay) | Seizable fungible collateral | Net bonus (after protocol fee) |
|---|---|---|---|---|
| #1015 | 1.1373 | 1,352.92 hUSDC (cap 676.46 per call) | 4,385,093.63 XRD (b=12%) | **139,319 XRD ≈ $63.0** |
| #517 | 1.0695 | 771.41 hUSDC (cap 385.71) | 2,658,668.87 w2-XRD (b=12%) | **79,437 XRD ≈ $35.9** |
| #100 | 1.0590 | 423.33 hUSDC (cap 211.67) | 1,473,485.96 w2-XRD (b=12%) | **43,593 XRD ≈ $19.7** |
| #1029 | 1.1703 | hUSDC+hSOL+hUSDT (~42,170 XRD val, cap 21,085) | w2-LSULP/w2-hETH/w2-hUSDT | 1,963 XRD ≈ $0.89 |
| 122 others | ~1.0–1.14 | mostly hUSDC dust | small | ≈ 15 XRD ≈ $0.01 |
| **Total** | | | | **264,328 XRD ≈ $119.46** |

**hUSDC scarcity cap:** max repayable = 1,092.79 hUSDC (85.8% of the 1,273.84 hUSDC theoretical max for the top-3 alone — note only 1,092.79 hUSDC exist in total; the top-3 debts alone exceed the entire supply), each hUSDC repaid yields 205.95 XRD net → cap ≈ 225,060 XRD ≈ **$101.5** (before acquisition costs; −$2.8 at 0.5% DEX cost if bought at oracle).

## Verified attack paths (E-U)

### Path 1 — Self-contained flash-loan liquidation (ZERO capital, verified SUCCEEDED)

Preview: `preview_flashliq.json` (Succeeded; 50,369,798 cost units; 2.52 XRD exec + 0.22 XRD storage ≈ $0.0012)

Manifest (read-only preview; `account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk` used only as simulated destination):
```
CALL_METHOD pool "take_flash_loan" Map<Address,Decimal>(XRD => 10);
TAKE_ALL_FROM_WORKTOP TRANSIENT_RES Bucket("terms");
TAKE_FROM_WORKTOP XRD 5 Bucket("pay");
CALL_METHOD market "liquidate" NonFungibleLocalId("#447#") Array<Bucket>(Bucket("pay")) Enum<1u8>(Array<Address>(XRD));
TAKE_ALL_FROM_WORKTOP XRD Bucket("all_xrd");
CALL_METHOD pool "repay_flash_loan" Array<Bucket>(Bucket("all_xrd")) Bucket("terms");
CALL_METHOD ACCT "deposit_batch" Expression("ENTIRE_WORKTOP");
```
Receipt facts: flash 10 XRD, flash fee 0.002 XRD (0.02%, pool override for XRD); liquidation repaid **2.550022 XRD** (exactly 50% close factor), seized **2.626523 XRD** (config-5 3% bonus), protocol fee 0.015759 XRD; **net account delta +0.058742 XRD with zero starting capital**. Liquidate mechanic formula confirmed: `net = repay × (1+b) × (1−0.2b) − repay`, b = bonus rate.

### Path 2 — Large liquidation, external funding (#1015, verified SUCCEEDED)

Preview: `preview_liq1015.json` (Succeeded; 45,343,189 cost units; 2.27 XRD exec + 0.17 XRD storage)

Manifest: withdraw 45 hUSDC from simulated holder → `market.liquidate(NonFungibleLocalId("#1015#"), [bucket], Some([XRD]))` → deposit_batch.
Receipt facts: repaid **45.0 hUSDC**, seized **111,471.124 XRD** (= 45 × 2211.7 × 1.12), protocol fee **2,675.307 XRD** (=20% of bonus), **net received 108,795.817 XRD → profit +9,269.23 XRD (~$4.19) on a $45 outlay (9.31% ROI)**. Post-state check in the same preview: debt 1352.919647 → 1307.919647 (−45.0 exactly); `liq_ltv` still 1.128 (repeatable). Scaling to the 676.46-hUSDC close-factor cap → +139,319 XRD ($63).

### Path 3 — full scan evidence

- `get_cdp` view (Array<NonFungibleLocalId>) run 57× over all 901 live Wefty NFTs (`weft_cdp_health_raw.json`): **126 CDPs with liquidation_ltv > 1** and non-trivial debt; 298 CDPs carry debt.
- 38 of the 126 have seizable **fungible** collateral (24 yield >0.01 XRD; 4 yield >1,000 XRD); the rest hold only NFT collateral (blocked path) or near-zero collateral.
- Aggregate bad debt visible: total adjusted loans in liquidatable set ≈ 111.87M XRD, but seizable fungible collateral only ≈ 5.15M XRD → the pools are deeply undercollateralized; only the bonuses above are recoverable by an outsider.
- Two CommittedFailure clusters observed on-chain (08:02Z, 09:30Z, dozens of txs) — third-party bot attempts; no debt was repaid (CDP debts unchanged across the audit window), consistent with the gates below.

## Gates / negatives (with evidence)

| # | Path | Result | Evidence (preview error) |
|---|---|---|---|
| N1 | **Borrow / create-with-borrow** | BLOCKED — market `Borrow` service not active | `[weft2-market] Error in batch CDP operation: The service is not active: (Borrow)` on `create_cdp(... borrow map hUSDC 32)`. Market service-status map only holds CreateCDP/UpdateCDP/BurnCDP (all enabled). |
| N2 | **NFT-collateral liquidation** (`liquidate_nft(cdp_id, payments, nft_res, nft_id, compensation)`) | BLOCKED — protocol NFT-fee vault empty | `Insufficient NFT liquidation protocol fees\| missing: -17.517497386440870937` for #523 (claim NFT 3007.17 XRD). `nft_liquidation_fees` vault `internal_vault_rdx1trtv...` balance = **0 XRD**. Even full payment (3,037.1 ≥ 2,919.6 discounted value + fee) fails. Affects ~52 NFT positions incl. #523/#530/#529 (XRD debts vs CaviarNine LSU claim NFTs). |
| N3 | Fungible `liquidate` targeting NFT collateral | BLOCKED | `Error liquidating collateral: \|\| Collateral Pool not found` when requesting the claim-NFT resource. |
| N4 | **Oracle manipulation** | BLOCKED — permissioned push oracle | Feed component roles: `admin` → `resource_rdx1nfvglpg...`, `updater` → `resource_rdx1ngrrjr2...` (both Protected). Weft backend (`price-updater` service: Pyth ⇢ Coingecko ⇢ CaviarNine/Astrolescent fallbacks) pushes every ~10 min; prices fresh & accurate (hUSDC 2211.78 XRD ≈ $0.9996; hETH 5.23M XRD; xETH 5.23M; hWBTC 179.2M; LSULP 1.2276 XRD). |
| N5 | Stale price cache exploitation | NEGATIVE — ops use live feed values | Market's persistent `price_cache` holds stale values (e.g., xUSDC 3319.7 vs live 2211.7), but `market.get_price([...])` returns live values (preview output: XRD=1, xUSDC=2211.7198) and liquidations/health checks demonstrably used live prices. `PriceCacheMode=Hash` (per-tx). Floor-priced dead tokens (WEFT/CAVIAR/FLOOP...=1e-10) give no borrow power; Borrow is off anyway. |
| N6 | Flash-loan principal/fee bug | NEGATIVE — accounting correct | take 10 XRD → repay requirement 10.002 (0.02% fee), enforced (`InsufficientBalance` when under-paying); flash-loan-funded cross-asset liquidation cannot be self-contained (fee top-up in debt asset required). |
| N7 | Borrow anyone's CDP / seize via repay | NEGATIVE — CDP ops require the Wefty NFT proof (`cdp_batch_operation(proof,...)`); liquidate accepts only a `NonFungibleLocalId` + payment bucket. | Signature probes. |
| N8 | Deposit/withdraw accounting (rounding/donation) | No exploit found; ratios tracked exactly (`asset = units/ratio`; verified against unit supplies). Deposits **frozen (enabled=false, locked=true)** for xUSDC/xwBTC/xETH pools (`pool_lending_service_manager_entries`); withdraw/borrow/flash still enabled there. Not exhaustively fuzzed (caveat). |
| N9 | Self-liquidation | No net gain by construction; not further pursued. | — |
| N10 | Price-feed pool-unit (HLP/sASTRL) manipulation | Not pursued to a definitive conclusion (no borrow path open, so no leverage; LP redemption values are fee-bounded). Caveat. | — |

## Classification

| Class | USD | Notes |
|---|---|---|
| **E-U** | **≈ $119.5 theoretical / ≈ $101.5 practical cap** (264,328 XRD) | Liquidation bonuses; mechanics verified by live previews; residual uncertainty = acquiring hUSDC at ≤ 4.2% premium (breakeven at ~9.31% premium); gas ≈ 1.2–2.5 XRD/tx. |
| H-O | $0 | None found. |
| P | — | Badge-gated admin (config, fees, oracle updates, service status). Not accessible externally. |
| S (stuck) | ≈ 111.87M XRD-valued loans vs 5.15M XRD seizable collateral | Bad debt: #1138 71.5M XRD-value debt with ~0 collateral, #717 5.29M, #112 1.70M, #708 0.67M; NFT-collateral liquidations bricked (N2); xUSDC/xwBTC/xETH deposits frozen; hUSDC/xUSDC pools nearly fully lent out. Lenders' loss, not outsider-extractable. |

## Caveats

- All "attacks" are PREVIEW simulations only; nothing was signed or submitted; funding accounts were simulated sources inside previews.
- USD conversion uses the protocol's own oracle pricing (self-consistent) and Llama XRD spot; hUSDC is not tracked by Llama — valued at oracle ≈ $1.00.
- hUSDC scarcity (1,092.79 total) is the binding constraint for the big three; an attacker must buy hUSDC from the ~30 top holders/DEX at ≤ 4.2% over oracle for the full $100+; even a partial repayment is profitable proportionally (any amount ≤ 50% of debt per call; verified with 45 of 676.46).
- `get_cdp` previews occasionally returned empty maps when a price-updater tx committed concurrently (:05/:15/... minutes); retries succeed. Not a state condition.
- Paths N8/N10 not exhaustively fuzzed (documented as residual unknowns).

## Artifacts

- Raw state: `weft_entities_live.json`, `weft_all_kvs_live.json`, `weft_feeds_kvs.json`, `weft_entities_now.json`, `weft_service_status_now.json`, `weft_feeds_live.json`
- CDPs: `weft_cdp_nft_ids.json`, `weft_cdp_nft_data.json`, `weft_cdp_health_raw.json` (all 901), `weft_cdp_health_summary.json`, `weft_liquidatable_cdps.json`, `weft_extract_quant.json`
- Previews: `preview_flashliq.json` (zero-capital liquidation, Succeeded), `preview_liq1015.json` (45 hUSDC liquidation, Succeeded), `preview_liquidate.json` (#447, Succeeded), `preview_create_cdp.json` (Succeeded), failures: `preview_liqnft_failed.json`, `preview_attack_failed.json`, `preview_flash_take_failed.json`
- Scripts: `01_reverify.py` … `31_quantify.py` (see folder)
