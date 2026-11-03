# CA2 LOW-tail C — verify-and-classify (Aperture / Coffer / zkLink)

**Date:** 2026-11-03 · **Status:** read-only; no transaction signed or broadcast · **CI:** `bash /home/heisenberg/CA/ci/ci-run.sh ca2-low-c`

Three CA2 LOW findings were re-verified independently: a named block, the relevant deployed code, and
the exact blocking condition for each. Headline: **live external-unprivileged extraction is $0.00 for
all three**; two carry latent/conditional value below (or, for Aperture, nominally above) the $10k bar.

| # | Target | CA2 | This pass | Live E-U | Confidence |
|---|---|---|---|---|---|
| 1 | Aperture Finance router `0xD83d960d…8913` (ETH/ARB/OP/POLY) | ~$0, path proven, fully swept | **LOW confirmed, with correction**: the NFT path is live but all approved positions are empty; the only materially funded ERC-20 approval (3.48M TRU) is on a **paused token**. Not “fully swept”, but still $0 live. | **$0.00** | high |
| 2 | Coffer rounding M-08 (Solana) | fix deployed 2026-10-19; bound one raw unit (<$1) | **LOW confirmed**: fix still deployed (slot 458,810,142, hash unchanged); per-leg bound is $0.000773, 9-leg call $0.00695 — ~1,300× below $1 | **$0.00** | high |
| 3 | zkLink Nova Arbitrator spoofing (Ethereum) | paused since 9h after drain; payout reverts | **LOW confirmed**: root cause unchanged, public relayer + gateway still live, but `paused()==true`; prove/deposit revert `Pausable: paused`; only $1,419 ETH remains | **$0.00** | high |

**Total live extractable now: $0.00 (high confidence).**

---

## 1. Aperture — path live, value gone, one frozen funded approval

- Router `0xD83d960deBEC397fB149b51F8F37DD3B5CFA8913`, non-proxy, 38,888-hex-char runtime on all four
  chains. Selector `0x67b34120` still present.
- Proven live: tx `0x7d2c160d…6314` (block 25,803,114, status 1); callTracer shows the router calling
  `NFPM.transferFrom(0xc846d321…, attacker 0xfcbe6aa9…, tokenId 0xd188b)`.
- Re-enumerated every `Approval` to the router: **1,483 logs / 392 pairs**. Only **8** pairs have both
  allowance and balance:
  - **Ethereum TRU**: 3,477,020.105893728270632095 TRU, ~2^256 allowance, **token paused since block
    24,192,375** → `transferFrom` reverts `ERC20Pausable: token transfer while paused`. Nominal
    $17,629.92 at the single MEXC quote, but no on-chain depth and only $55.8k/24h venue volume.
  - **Polygon dust**: WBTC 76+147 sat, USDC 0.0002, SUSHI 0.4544, SHIB 69,323.9, FANS 2.861e9
    (unpriced) → **$0.5794** priced total.
- **78** still-approved LP NFTs across the four chains: all `liquidity == 0`, `tokensOwed0/1 == 0`.
  One non-approved OP position has liquidity but `getApproved == 0` and `isApprovedForAll == false`.
- **E-U: $0.00.** Latent: ≤$17.63k nominal if TRU is unpaused (token admin `0x39e6918d…`) **and** the
  ERC-20-target variant (public-analysis claim, not re-proven here) is reachable; realizable at size is
  likely lower. **P/S:** unpause admin-only; TRU frozen while paused.

## 2. Coffer — fix still deployed; bound quantified

- `cubic_pool` `8iQtGj9m…hwu`; ProgramData `7Lh9eKmD…Zw4`, 652,605 bytes, SHA-256
  `14e0965a…5bd3`; **last deploy slot 458,810,142 = 2026-10-19T11:04:29Z**; upgrade authority
  `B4gyhrqL…3Bg` (Treasury PDA).
- 43 pools (27 v5 + 16 legacy), 29 mints, decimals **5–9**. One raw unit ≤ **$0.0007726891** (1 sat of
  an 8-dp BTC token); 9-leg max **$0.0069542** per call. Prior behavioural simulation at slot
  464,630,474 (same bytecode, since last deploy is earlier) showed full credit + `div_up`/`mul_up`
  virtual fix; no redeploy since.
- DefiLlama TVL $58,417.31. **E-U $0.00**; counterfactual ≤$0.007/call, realised incident $0.7.

## 3. zkLink — root cause unpatched, payout paused

- `Arbitrator` impl `0x7a0bb480…` unchanged; stale `finalizeMessageHash` transient-storage flaw still in
  source. Relayer `0x0fdc28e6…` whitelisted; `EthereumGateway 0x83bc7394…` secondary gateway.
- **`ZkLink.paused() == true`** since block **26,297,792** (2026-10-29T10:26:59Z, tx
  `0xb68b67b9…f013c`); no `Unpaused`. `proveL2MessageInclusion` and `requestL2Transaction` revert
  `Pausable: paused`; bridge `finalizeWithdrawal`/`claimFailedDeposit` route through those proofs.
- ZkLink 0.622821572451440221 ETH = **$1,419.23**; bridge 0 ETH / 0 major ERC-20.
- Split: **P** 0.336731588888613576 ETH ($767.31, owner `withdrawForwardFee` works while paused);
  **S/H-O** 0.286089983562826645 ETH ($651.91, user escrow).
- **E-U $0.00**; if unpaused without an Arbitrator upgrade, conditional ceiling ≤$1,419.23 — below $10k.
- **Prior coverage:** ZH4-P2 covered the 2026-10-17 legitimate 15-call `finalizeWithdrawal` batch
  (3,000 uniETH 2024 depositor exit), **not** the Oct 27–29 Arbitrator spoofing drain ($783,100). Different
  event, different mechanism.

---

## 4. Layout

```
ca2-low-c/
├── aperture/   README.md, summary.json, analysis/ (enumeration script, live_approvals.json, decompiler)
├── coffer/     README.md, summary.json, analysis/ (verify.py, pool_tokens.json)
├── zklink/     README.md, summary.json, analysis/ (verify.sh, ABIs)
├── ci/run.sh   re-runs all three verifications; writes ci-out/
└── ci-out/     CI result files
```

## 5. CI

`bash /home/heisenberg/CA/ci/ci-run.sh ca2-low-c` syncs this folder to the public `artsbykriss/ca-zombie-ci`
repo, runs `ci/run.sh`, and downloads `ci-out/`. The job only performs public RPC reads; `ETHERSCANV2_API_KEY`
is injected by the workflow and never written to disk. No keys or keyed URLs are in this folder.

## 6. Caveats

- Aperture is closed source; the NFT path is trace-proven, the ERC-20-target variant is from public
  analyses. The TRU nominal is a single-venue quote, not realizable size.
- Coffer’s fix is verified behaviourally (prior run) + by deployment identity (this pass), not by source
  diff (private source).
- zkLink’s pause is an admin mitigation; the code flaw remains. Per-chain escrows (Linea et al.) are not
  counted because reachability through the Ethereum Arbitrator is unproven.

**CI (read-only re-verification):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41647220393
