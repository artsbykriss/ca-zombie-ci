# X7Pioneer NFT (`0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7`) — Acquisition-Cost Analysis for a Fresh Attacker

**Question:** What would it cost a *fresh, unprivileged* attacker TODAY to obtain a usable X7Pioneer `tokenId` (needed because `claimRewards` requires `ownerOf(tokenIds[i]) == msg.sender`)?

**Verdict (short):** **No market / not acquirable on any public venue as of block 26201566 (2026-10-16).** Zero active listings anywhere (OpenSea, Blur, Forbes/CoinGecko all show floor "—/$0.00", listed 0, 24h volume $0). There is no path to buy a token for <$50, and no path to buy one at *any* price right now. The only observable precedent trade is the 2026-10-08 Blur sale of token #300 for **0.15 ETH ($384.63 at sale time)**; the buyer of that sale is `0xc79352119A7cF6EFbFaBBD7e6b013B79687BaCf2` — the address holding the token the original attacker used. The 223 already-unlocked tokens (including #300) require **no** 0.07 ETH unlock fee; any *locked* token would add $170.79 (0.07 ETH) that only its current owner can pay. Acquisition today is only possible via a private OTC deal/gift from one of the 113 current holders of unlocked tokens, at a price not observable in any market — nothing under ~$50 exists.

No transactions were sent; all work is read-only.

---

## 1. Live reads (pinned block 26201566, 2026-10-16T00:40:35Z, RPC `https://ethereum-rpc.publicnode.com`)

| Read | Result |
|---|---|
| `name()` | "X7 Pioneer" / `X7PIONEER` |
| `transferUnlockFee()` | `70000000000000000` wei = **0.07 ETH** |
| `airdropActive()` | **false** |
| `owner()` | `0x7000a09c425ABf5173FF458dF1370C25d1C58105` — an **EOA with EIP-7702 delegation**: its code is the designator `0xef0100` + `63c0c19a282a1b52b07dd5a65b58948a07dae32b` (delegate contract name: `EIP7702StatelessDeleGator`; owner EOA nonce 1052) |
| `totalSupply()` | **639** |
| `transferUnlocked(i)` sample (i = 0..30, 300) | **true** for 0, 10, 16, 20, 22, 24, 30, 300; false for all other sampled ids |
| `transferUnlockFeeDestination()` | `0x70001BA1BA4d85739E7B6A7C646B8aba5ed6c888` |
| `airdropActive` note | one-way: `disableAirDrop()` sets it false; **there is no setter to re-enable it** |
| ETH/USD (Chainlink `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`, fresh round) | **$2,439.87** |
| Gas price | 0.0634 gwei (transfer ≈ $0.01–0.02 — negligible) |

Evidence: `analysis/x7_live_reads.txt`.

**No public mint.** Verified in the verified source (`analysis/x7_source.json` / `x7_source.sol`): the *only* mint callsite in the X7Pioneer contract is `airdropTokens(recipients)` (line 1381), which is `onlyOwner` and requires `airdropActive` (now false, cannot be re-enabled). All other external functions are either owner-only setters, `unlockTransfer` / `claimRewards` / `selectVariant` (all require `ownerOf == msg.sender`), or standard ERC-721 transfers. There is no `mint`, no sale function, no claim-a-free-token path.

## 2. `TransferUnlocked` universe (all-time)

- Topic0 = `keccak("TransferUnlocked(uint256)")` = `0xf03c5e9a7bca700fe035c5bedbbb637e54cf3f7710958ce3b269ae2da7405bba` (tokenId is **indexed**; contract emits it only in `unlockTransfer`).
- **223 unlock events, all-time, 223 unique tokenIds** (no duplicates possible: `unlockTransfer` reverts on already-unlocked). The mapping is one-way — no function anywhere writes `transferUnlocked[tokenId] = false`, so all 223 remain unlocked today.
- Window: first unlock block 15,946,843 (2022-11-11T12:42:23Z) → last unlock block 18,215,254 (2023-09-25T20:42:23Z). **No new unlocks in ~3 years.**
- Each of the 223 unlock txs came from a **different sender** (each owner unlocked their own token, paying 0.07 ETH): 223 × 0.07 ETH = **15.61 ETH (~$38,086 at today's rate)** paid to `transferUnlockFeeDestination` over time.
- Current state of all 223 (batch `ownerOf` at block 26201566): **all 223 still exist**, spread across **113 unique owners**; 31 still held by the address that originally unlocked them.
- Top current holders of unlocked tokens:
  | Owner | Unlocked tokens held |
  |---|---|
  | `0xa9f0e54466d4ac72b6b64bb09b2136c17fa0290e` | 25 |
  | `0xe632a03be4e6268eef850d5646644f5ded73bf23` | 14 |
  | `0x644271b9e727bcbda5d005690c098ae39add9d40` | 10 |
  | `0xe91da8a8bbe3c3921c2d5c820585e0d462afb44f` | 7 |
  | `0x0fb7c06de0b41c0c2efe39aaafa8733900594f5d` | 7 |
  | `0x1e3fb0a275a2114d2cc79a15fcfd06d105bc09bd` | 6 |
  | `0x107a14ec62bacf30620b7f92bf5201c9299decc0` | 6 |
  | `0x803a268a1c22612088a5660ec03b25d488d3271e` | 5 |
  | (105 more owners with 1–4 each, holding the remaining 143 tokens) | — |

- Full per-token owner list: `analysis/x7_unlocked_tokens.csv` (columns: tokenId, current_owner, unlock_tx_sender, unlock_tx_hash). Full id list (223):
  `0,10,16,20,22,24,30,36,38,42,44,50,54,56,62,66,70,78,84,86,90,92,107,110,117,122,124,125,129,131,134,137,139,147,148,149,150,151,153,156,157,161,165,167,170,171,177,178,179,182,183,185,187,191,192,195,196,197,201,202,204,206,210,219,227,228,230,238,239,241,242,243,249,252,253,254,258,259,262,266,268,270,271,272,273,276,277,278,280,281,284,293,298,299,300,303,306,308,310,311,315,318,320,324,326,329,330,331,336,341,347,350,352,355,358,359,361,367,368,371,372,376,378,379,387,389,391,395,396,398,399,408,414,415,418,429,432,433,435,436,443,446,448,449,451,454,455,456,457,459,463,466,471,473,474,491,492,493,495,498,503,505,511,512,513,515,516,518,523,524,531,532,536,540,541,542,543,544,545,550,558,561,563,566,568,574,575,576,577,579,584,585,586,587,588,589,591,592,595,598,600,605,609,611,615,617,618,621,625,635,636,647,649,653,657,673,675,679,687,693,699,701,719`
  (12 ids are > 639 — `totalSupply` is 639 because of gaps left by the `airdropTokens` index logic; there is no burn function.)

### Token #300 (the original attacker's token)
- Current owner: `0xc79352119A7cF6EFbFaBBD7e6b013B79687BaCf2` (`balanceOf` = 1).
- **Unlocked: yes** (`transferUnlocked(300) = true`).
- Unlocked 2023-04-29T15:58:11Z (block 17,152,784) by `0xf800eb77defe86d6e99946ff88ab2110c82457bf` for 0.07 ETH — tx `0x21fa9122f083ee1457240a3244b297486e210f539b3e02f2745859bf67d63c35`.
- **Not listed for sale** (OpenSea: "Best Offer —", collection-wide listings = 0).

## 3. Marketplace status (checked 2026-10-16)

| Venue | Result |
|---|---|
| **OpenSea** (slug `x7-pioneer`) | Floor **—** (none); **Listed 0 (0%)**; 24h volume **$0.00**; lifetime volume $347.3K; 639 items; 509 unique owners (79.7%). Token #300 page: Last Sale **$384.63**, Best Offer —, floor — |
| **Blur** (`blur.io/collection/0x70000299…`) | Floor **0.00**; sales volume 0.00; owners 509 (80%) of 639; **"No activity"** |
| **Forbes NFT / CoinGecko data** | Floor **0.00 ETH ($0.00)**; 24h volume 0.00 ETH; market cap $0.00; **508 owners** |
| **LooksRare** | Collection page returns HTTP 500 (no data) |
| **Magic Eden** | Collection not found (404) — not indexed |

Notes: the `OPENSEA_API_KEY` in `/home/heisenberg/CA/.env` is **invalid** (HTTP 401 on both the target and a control request), so OpenSea data was taken from the public collection/activity pages. `api.reservoir.tools` did not resolve (DNS); Reservoir could not be used.

### The only recent sale — decoded on-chain (this is the price precedent)
- **2026-10-08T09:11:59Z**, block 26,146,702, tx `0xda55fd68dce40896726207c74cf9618d8cd727d00d7f822af04d68470b3baeec`.
- Market: **Blur** — tx `to` = proxy `0xb2ecfe4e4d61f8790bbb9de2d1259b9e2410cea5`, implementation `BlurExchangeV2` (`0x5fa60726e62c50af45ff2f6280c468da438a7837`).
- Buyer (tx sender): `0xc79352119A7cF6EFbFaBBD7e6b013B79687BaCf2` (the current token-#300 holder). Seller: `0x2e00cd8be75a41941205b55876615b341c41c9ec` (OpenSea handle "pioneer-maxi").
- **Price decoded from the marketplace event: exactly 0.15 ETH** (`0x0214E8348C4F0000` packed in the match event). OpenSea displays it as **$384.63** (implies ETH ≈ $2,564 at sale time). Buyer gas: 0.000365 ETH (~$0.89).
- The transfer succeeded with no `TransferUnlocked` event → the token was already unlocked at sale time; the buyer paid **no unlock fee**.

### Corroborating on-chain activity (2024–2026)
Only 6 non-trivial transfers since 2024, all **direct user-to-user moves**, not marketplace sales: blocks 20,884,291 (2024-10-03), 22,753,450 (2025-06-21), 23,063,175 (2025-08-03), 24,597,632 (2026-03-06), 25,878,637 (2026-08-31, part of a 228-log multi-collection Multicall3 batch), plus the Blur sale above. There is effectively **no live secondary market**.

### What the buyer did 44 min after buying (context; matches the parent task's exploit)
- 2026-10-08T09:55:59Z, block 26,146,922, tx `0xc98056d6ab55ef898189da5fa1fb08b968cb84ca99528d171f8240836b21766d` (attacker as sender, ~$6.66 gas):
  - Deployed a one-shot helper contract `0xaa0cad88ac3f76beb9a0f1ba661916d7716d5f4a` in that same tx, transferred #300 to it, and back to the attacker in the same tx.
  - The helper took an **Aave V3 flash loan** (≈26.963 WETH borrowed, 26.97665 WETH repaid) and the tx contains a **`RewardsClaimed` event: tokenId 300, recipient = helper, amount = 33.756919822234785 ETH** (`RewardsClaimed(uint256,address,uint256)` topic0 = `0x3300bdb359cfb956935bca32e9db727413eab1ca84341f2e36caea85bb796968`).
  - I.e., the token was purchased and used within the hour to extract ~33.76 ETH of claim payout via a flash-funded claim — strong evidence the token's only utility is this claim path.

## 4. Cost model for a fresh attacker (today)

Because transfers are gated by `_beforeTokenTransfer` (`require(transferUnlocked[tokenId] || msg.sender == owner())`), a token can only change hands if (a) it is unlocked and its owner agrees to sell/gift, or (b) the contract owner executes the transfer (privileged).

| Path | Cost today |
|---|---|
| Buy on a marketplace | **Impossible — 0 listings on OpenSea/Blur, floor undefined, 24h volume $0.** Not available at any price, let alone <$50 |
| Buy an already-unlocked token OTC (223 exist, 113 owners) | Negotiated price only. Precedent: last sale 0.15 ETH = **$365.98** at today's ETH ($384.63 at sale time). No unlock fee needed. + gas pennies |
| Buy a locked token | Same as above **+ 0.07 ETH = $170.79**, payable by its owner before transfer (only the owner can call `unlockTransfer`; `require(ownerOf(tokenId) == msg.sender)`) |
| Mint | **None** — no public mint; airdrop disabled and cannot be re-enabled |
| Owner-privileged transfer | Possible for `owner()` (`msg.sender == owner()` bypasses the lock), but unavailable to a fresh/unprivileged attacker |

**Minimum realistic acquisition cost: "no market / not acquirable" via any public venue.** The cheapest *observed* transaction price for a single token is 0.15 ETH (~$366–$385); there is no listing or offer at any lower price, and nothing at all is for sale. A sub-$50 acquisition would require a holder to voluntarily part with an unlocked token for <$50 OTC — no evidence any holder is willing at any price (0% of supply listed, $0 volume). If a locked token were chosen instead, add the fixed 0.07 ETH unlock fee ($170.79).

### Owner privileges (noted, not an unprivileged path)
- `owner()` = `0x7000a09c425ABf5173FF458dF1370C25d1C58105` — an **EOA with EIP-7702 delegation** (MetaMask-style `EIP7702StatelessDeleGator` at `0x63c0c19a282a1b52b07dd5a65b58948a07dae32b`). It can bypass the transfer lock for any token (`msg.sender == owner()` in `_beforeTokenTransfer`) and controls fee/URI settings, but this is the X7 team's key — a fresh attacker cannot use it, and no token transfers *from* the owner are required for the claim exploit (only ownership by the attacker's own address).
- `renounceOwnership()`/`transferOwnership()` exist (standard Ownable) but likewise are irrelevant to an unprivileged attacker.

## 5. Commands used (key material redacted)

```bash
# live reads, pinned block
RPC=https://ethereum-rpc.publicnode.com
C=0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7
BLOCK=$(cast block-number --rpc-url $RPC)
cast call $C 'transferUnlockFee()(uint256)' --rpc-url $RPC --block $BLOCK
cast call $C 'airdropActive()(bool)' --rpc-url $RPC --block $BLOCK
cast call $C 'owner()(address)' --rpc-url $RPC --block $BLOCK
cast call $C 'totalSupply()(uint256)' --rpc-url $RPC --block $BLOCK
for i in $(seq 0 30) 300; do cast call $C 'transferUnlocked(uint256)(bool)' $i --rpc-url $RPC --block $BLOCK; done
cast keccak 'TransferUnlocked(uint256)'

# all TransferUnlocked logs (Etherscan V2; key read from env, never written to files)
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs&address=$C&topic0=0xf03c5e9a7bca700fe035c5bedbbb637e54cf3f7710958ce3b269ae2da7405bba&fromBlock=0&toBlock=latest&page=1&offset=1000&apikey=${ETHERSCANV2_API_KEY}"

# batch ownerOf for the 223 unlocked ids at the pinned block (JSON-RPC batch via curl)

# source verification
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address=$C&apikey=${ETHERSCANV2_API_KEY}"

# ETH/USD
cast call 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url $RPC
```

## 6. Evidence files (all in `analysis/`)

- `x7_live_reads.txt` — pinned-block reads
- `x7_source.json`, `x7_source.sol` — verified source (53,574 chars)
- `x7_unlock_logs.json` — all 223 TransferUnlocked logs
- `x7_unlocked_ids.json`, `x7_unlocked_owners.json`, `x7_unlocked_tokens.csv` — unlocked ids, current owners, unlock tx per token
- `x7_transfer_logs.json` (first 1,000 Transfer logs), `x7_recent_transfers.json` (transfers since block 17M)
- `receipt_sale.json`, `receipt_roundtrip.json` — Blur sale and helper/claim txs
- `marketplace_src.json`, `marketplace_impl_src.json`, `marketplace_abi.json` — Blur proxy/impl identity
- `delegate_src.json` — `EIP7702StatelessDeleGator` source record

Caveats: USD conversions use the Chainlink ETH/USD spot ($2,439.87) except where a sale-time USD figure is quoted from OpenSea; the 0.07 ETH parameter is owner-changeable (`setTransferUnlockFee`) and was not modified as of the pinned block. Marketplace pages were captured 2026-10-16 (collection pages are dynamic; "Listed 0 (0%)" and "$0.00 24h volume" are the relevant snapshot values).
