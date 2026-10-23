# Notes — dead ends, uncertainties, method caveats

Pinned block **26253666**. All reads read-only. No secrets written.

## Method / tooling caveats

- **Primary `$RPC_URL` (a public Flashbots endpoint) blocks `eth_call`** ("rpc method is not whitelisted").
  Used `$BLOCKPI_RPC_URL` / `$NODEREAL_ETH_RPC_URL` for `eth_call`. Redacted as `https://<rpc>`.
- **`cast logs` treats multiple topic0 values positionally**, not as an OR. Each event must be queried
  with a single topic. (First attempt silently returned wrong/empty data.)
- **BlockPi caps `eth_getLogs` at a 5,000-block range** → used **Etherscan V2 `getLogs`** instead
  (returns up to 1000 records per call; larger result sets get truncated — see below).
- **`cast abi-decode` needs `cast decode-abi "name(in)(out)"`** (with output types) — plain
  `cast abi-decode "f(...)"` returned "no data was decoded".
- **`eth_abi` (installed version) fails** decoding the 9-arg `ProposalCreated` with
  `OverflowError: Python int too large to convert to C ssize_t` — worked around with `cast decode-abi`.
- **BlockPi rejected batched JSON-RPC (HTTP 403)**; NodeReal accepted it. Batched `eth_call` via NodeReal
  was used for the ~450 delegate `getCurrentVotes` lookups.
- **Blockscout token balances are "latest" (~block 26253784)**, not pinned to 26253666. Quantities are
  near-identical but not exact-at-block. Native ETH and all `eth_call` values are pinned to 26253666.
- **`getCurrentVotes` is the Comp-style call**; historical is **`getPriorVotes(address,uint256)`** —
  `getPastVotes` reverts on GTC (ERC20VotesComp does not expose it). Used `getPriorVotes` for history.

## Uncertainties / lower-confidence items

- **"~4.06M GTC delegated to the veto multisig" (prior claim)** could not be reproduced at any block.
  `getPriorVotes(0x5743, blk)` = 0 at blocks 24845001 / 24898462, then **12,508,498.26 GTC** at block
  25,000,000 and every sampled block after. The timelock delegated to `0x5743` exactly once
  (DelegateChanged at block 24928212). So the current and historical figure is ~12.51M, not 4.06M.
  Possible sources of the prior 4.06M: a different snapshot source, a stale cache, or confusion with
  another address. **Flagged as WRONG (amount)**, not silently corrected.
- **Delegated-total (~16.07%) is a lower bound.** The candidate delegate set was built from the top-50
  holders plus `DelegateChanged` events since block 23,000,000, and the Etherscan `getLogs` for that
  window was **truncated at 1000 records** (there are more). Some delegates with small balances may be
  missed, and the top-50 holders are only part of the holder base. Exact per-address figures
  (`getCurrentVotes`) are authoritative; the aggregate is approximate.
- **`0x5743` is described as "4/5" in the April-2026 proposal text but is now a 4-of-6 Safe.**
  Confirmed on-chain at block 26253666: threshold 4, 6 owners, VERSION 1.4.1. The owner set changed at
  some point after April 2026; the exact owner-change tx was not traced.
- **Timelock "admin/owner of other contracts" was NOT exhaustively enumerated.** Established: it is the
  governor's `timelock()` executor, the governor is its `admin()`, and it owns a Uniswap V3 LP NFT
  (tokenId 25670) + 3 ERC-1155s. A full ownership graph across all Gitcoin contracts was out of scope;
  treat "owner of other contracts" as **unverified beyond the above**.
- **LP position value not computed.** TokenId 25670 is a SACKS/WETH 0.05% Uniswap V3 position
  (liquidity 86,081,853,130,684,128,716, tokensOwed 0). SACKS has no DefiLlama price; likely dust.
- **WNDR (24,000,000, DeFi Wonderland) unpriced** — no DefiLlama feed. If it has any value it is not in
  the $4.60M total. Same for ALA, FNF, HAM, ELIMU and the remaining dust tokens.
- **USD total uses DefiLlama spot prices at query time** (GTC $0.316952, ETH $2,399.76). The prior
  ~$4.95M vs current ~$4.60M difference is dominated by GTC price, not quantity changes.
- **Proposal "turnout per proposal"** was derived from `VoteCast` events; for the legacy governor the
  recent window (blocks 25,776,742–26,253,666) had only 8 `VoteCast` events, all for the final proposals.
  A full per-proposal turnout table for all 49 proposals was not built (event volume + truncation).
  The 49 `ProposalCreated` events were fully decoded and saved to `raw/logs/proposals_old.json`.
- **New governor has no `proposalCount()`** (OZ v5); proposal count was established by counting
  `ProposalCreated` events (= 0).
- **Timelock admin-change events**: correct topics required `NewAdmin(address)` (single indexed arg) and
  `QueueTransaction(bytes32,address,uint256,string,bytes,uint256)` — note `string signature` (not `bytes`).
  Initial attempts with `(address,address)` / `bytes` variants returned 0.

## Dead ends

- `guardian()`, `token()` on the **legacy** governor: `token()` works; there is **no** `guardian()` /
  `proposalGuardian()` / `proposalCount()` on the legacy Bravo governor (reverts).
- Timelock has no `guardian()` / `DEFAULT_ADMIN_ROLE()` (reverts) — it is the plain Compound Timelock.
- Searching for a *second* "veto multisig" holding ~4.06M votes: none found in the candidate set
  (only `0x5743` at 12.5M, `0x00De4B13` at 2.49M, `0x93f80a67` at 0.5M, `0xc2E2B715` at 0.41M, others small).
- The exact OZ v5 patch version of the new governor is inferred from the source header
  ("last updated v5.5.0" in `GovernorProposalGuardian.sol`); the compiler is pinned at
  `v0.8.35+commit.47b9dedd` and `version()` returns "1".

## Raw artifacts (under /home/heisenberg/CA/gitcoin/raw/)

- `src_<addr>.json`, `abi_<addr>.json`, `files_<addr>/` — Etherscan V2 source + ABI for governor(s),
  timelock, guardian Safe.
- `cc_<addr>.json` — contract creation (block/tx/creator) for the three contracts.
- `logs/` — raw Etherscan `getLogs` JSON for governor + timelock + GTC `DelegateChanged`.
- `logs/proposals_old.json` — all 49 legacy `ProposalCreated` decoded (block, ts, id, proposer, voteStart/End, description).
- `holders_votes.json`, `top_delegates.json`, `prices.json`, `tl_token_balances.json` — delegation + pricing raw data.
