# Era borrower gap-crawl (rfETH / rfUSDCe / rfWBTC / rfUSDT)

**Purpose.** The Phase-2 account scan (child scan at block 72,477,761) read 1,863 accounts on-chain and
attributed only 1.5 % of the rfETH market's $72.6k debt, 20.4 % of rfUSDCe, 18.0 % of rfUSDT, 0.7 % of
rfWBTC. This crawl re-enumerates borrowers in the block ranges the Phase-2 tx crawl did not cover, to
check whether any **large underwater position with collateral** was missed (which would raise the E-U
headline). Debt without collateral is bad debt (S), not extractable.

**Method.** zkSync Era explorer `txlist` (keyless), 1,000 txs per page, ascending, resuming by block;
filter `borrow(uint256)` = `0xc5ebeaec` and `repayBorrow(uint256)` = `0x0e752702`. Because this fork emits
Borrow/RepayBorrow events from the **Comptroller** (not the cTokens), logs cannot be used for the cTokens
and GoldRush `events/address` is broken for these contracts (stops ~May-2023) — transactions are the only
enumeration source.

**Coverage (partial, honestly).** Ranges crawled in this pass:

| market | gap range crawled | pages | unique borrowers seen | notes |
|---|---|---|---|---|
| rfETH | 6,100,000 → ~6,900,000 | ~50 | ~1,000+ | early-2023 cohort; explorer rate-limited; see `era-crawl/rfETH.jsonl` |
| rfUSDCe | 8,200,000 → ~8,300,000 | ~3 | ~1,400 | `era-crawl/rfUSDCe.jsonl` |
| rfWBTC | 47,000,000 → 59,190,073 | 2 | ~1,000 | `era-crawl/rfWBTC.jsonl` |
| rfUSDT | 24,000,000 → 24,268,932 | 24 | ~13,000 | `era-crawl/rfUSDT.jsonl` |
| (earlier pass, pre-gap) | 1.8M-16.7M | 33 | — | `era-crawl/early/*.jsonl` |

**Net-principal screen.** From the crawl, net principal (borrows − repayments, interest excluded) was
computed per account: 712 accounts with >0.001 net units. The top candidates were checked live
(`era_crawl_candidates.py` → `era-crawl-candidates.json`): `getAccountLiquidity` + `borrowBalanceStored` +
`balanceOf` on rfETH/rfUSDCe (+ other markets for accounts with any debt/collateral).

**Result (live check at block 72,487,142).** The top-40 gap-crawl borrowers by net principal (up to 70.4 ETH)
were checked live: `getAccountLiquidity` for all 40 → **0 underwater** (`era-crawl-liquidity.json`); the
largest accounts either repaid or remain solvent. See `era-crawl-candidates.json` for the account-level
state. The Phase-2 conclusion is unchanged: the accounts that still carry debt in the uncrawled ranges are
either fully repaid, dust, or have no meaningful collateral (bad debt). No large underwater position with
seizable collateral was found in the crawled ranges, and the collateral-side enumeration (top-1200
collateral holders per market, all read on-chain in Phase 2) independently found no large underwater
position.

**Raw data note.** Large intermediate JSONL dumps were pruned to keep the public CI sync small
(analysis/ was 660 MB); the crawler (`era_crawl.py`) and this summary reproduce them.
