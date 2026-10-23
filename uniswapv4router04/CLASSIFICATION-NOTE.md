# Classification note — UniswapV4Router04 (ZH4-PASS5 Tier-3 LOW)

**Live E-U ≈ $2.60 (fork-proven $2.34) — DUST KEEP (non-zero rule).** The hardcoded `calldataload(164)` auth bypass is **confirmed live**, but the nominal $14.40 is mostly unreachable (USDT has no bool-return → `settle` reverts; blacklisting tokens; zero-liquidity pool). **Re-arms with any new approval.** The same code is live on Base/Arbitrum/OP/Polygon/Unichain (0 approvals there).
- **Monitor:** any new approval to the router on any of the six chains.
- Evidence: `uniswapv4router04/` (README, summary, analysis, poc — PoC passes locally; the CI run was still queued behind sibling contention at write time).
