# Capital-acquisition routemap — 48,698.35 KITE (quorum) and 122,423.63 KITE (win)

Live reads: Optimism blocks 159,336,206–159,337,291 (2026-11-10). Prices: KITE $0.308646,
OP $0.100293, WETH $2,127.24, HAI $1.19587.

**Correction first.** CA3 uses `quorum = 48,698,350 KITE`. On-chain `totalSupply() = 973,967e18`
(973,967 KITE, not 973,967,000) and `quorum(now-1) = 48,698.35e18`. CA3's `$5,545` is the correct
USD value of 48,698 KITE *at $0.113859*; the 48,698,350 figure is a 1,000× decimal slip. Live quorum
is **$15,030.55 at $0.3086**.

## 1. What must be acquired

| Purpose | KITE | USD at spot | Note |
|---|---|---|---|
| Proposal threshold | 20,000 | $6,172.92 | to submit |
| Quorum only | 48,698.35 | $15,030.55 | passes only if Against < For |
| Beat live defence bloc | **122,423.63** | **$37,785.66** | 5 delegates (test_02/03) |
| Beat every delegated vote | 131,098.14 | $40,462.66 | if all delegates vote |

The treasury's own 328,143.98 KITE has **0 votes and delegate = 0x0** (`getVotes(SAFE)=0`,
`delegates(SAFE)=0x0`). Quorum is measured on `getPastTotalSupply`, not delegated supply, so the
treasury's KITE is loot, not voting power. It does not help the attacker vote.

## 2. Route-by-route availability

### 2.1 Optimism DEX (the only on-chain venue)

| Pool | Address | KITE reserve | Quote reserve |
|---|---|---|---|
| Velodrome v2 volatile KITE/HAI | `0xf2d3941b6E1cbD3616061E556Eb06986147715d1` | 18,606.23 | 4,777.38 HAI |
| Velodrome v2 volatile OP/KITE | `0xf4638dC488F9C826DC40250515592E678E447238` | 3,613.98 | 11,110.19 OP |

**Total KITE in all pools = 22,220.21** — less than half the quorum and 18% of the winning stake.
Constant-product cost to buy (30 bp fee, best split):

| Buy | Cost | Avg price | vs spot |
|---|---|---|---|
| 5,000 | $1,988 | $0.398 | +29% |
| 10,000 | $5,604 | $0.560 | +81% |
| 15,000 | $14,227 | $0.948 | +207% |
| 20,000 | $61,687 | $3.08 | +899% |
| 22,220 (≈everything) | $677,947 | $30.51 | +9,780% |

→ **A DEX purchase cannot fill either stake.** Even 20,000 KITE costs 4× the quorum's spot value and
leaves the pool empty.

### 2.2 CEX

CoinGecko `/coins/kite` tickers return exactly two venues, both Velodrome V2 pools. No CEX listing,
no deposit/withdrawal route, no KYC path. DexScreener's token lookup returns the same two pairs.

### 2.3 Other chains / bridges

`/latest/dex/tokens/0xf467…1404` returns 11 pairs, **all on Optimism** (2 KITE pools, 9 HAI pools).
The KITE token is a native `ProtocolToken` on OP (totalSupply 973,967); there is no bridged
representation with a second float. GeckoTerminal's large "KITE/USDT" pools ($1.5M) are a different
asset (KITE AI), not this contract.

### 2.4 OTC / whales

| Holder | KITE | Notes |
|---|---|---|
| `0xE207f98c…2067` (EOA) | 51,118.88 | only single wallet that can cover quorum |
| `0x0a453F46…c43E` (EOA) | 20,403.51 | |
| `0xd96fa7e7…9762` (EOA) | 12,722.53 | |
| `0xf23F999E…1Ab0` (EOA) | 9,927.47 | |
| `0xeCeA7231…6903` (EOA) | 8,666.04 | |
| `0xcFdB6e13…677C` (EOA) | 8,147.70 | |
| `0xef93AF92…edD9` (EOA) | 7,392.53 | |
| `0x7e551Dc6…00A3` (EOA) | 6,271.32 | called `execute` on the hardening proposal |
| all other EOAs | ~46,100 | 1,595 addresses |

**Total EOA float = 171,750.63 KITE.** The winning stake is **71.3% of every EOA-held token**.
Quorum is reachable from one whale (`0xE207…` holds 1.05× quorum). The winning stake is not
reachable without 6–8 whales selling simultaneously — a negotiated OTC operation, not a market
purchase, and one that is publicly visible for 6.5 days.

## 3. All-in cost vs the treasury

| Scenario | Cost | Treasury realizable | Net |
|---|---|---|---|
| Quorum only, DEX+OTC at spot | $17,547 | $6,576 (KITE exit $6,508 + $68) | **−$10,971** |
| Quorum only, 2× OTC premium | $29,490 | $6,576 | **−$22,914** |
| Quorum only, vs treasury **mark** ($101,348) | $17,547 | $101,348 (unrealizable) | +$83,801 nominal |
| Win (122,423.63), spot OTC | $47,384 | $6,576 | **−$40,808** |
| Win + protocol collateral | $47,384–$80,541 | ~$808k | +$727k…+$761k |

The treasury's KITE is only realizable at **$6,508** because the two pools together hold $6,828 of
quote assets. Dumping 328,143.98 KITE into them returns 4,520.31 HAI + 10,988.80 OP (fork test 05).
The KITE leg is **structurally net-negative at any price** (the treasury/quorum ratio is fixed at
6.738× in token units, but the exit curve is fixed in dollars).

## 4. Verdict

* **Against the treasury alone: net-negative.** The cost of a quorum stake ($17.5k–$29.5k) exceeds
  the realizable treasury ($6.6k).
* **Against the protocol: positive on paper only after winning the vote.** Winning requires
  122,423.63 KITE = 5.5× the entire DEX float and 71% of all EOA holdings. The 48,698.35 quorum stake
  is sourceable from one whale, but that proposal is defeated 122,423.63 → 48,698.35 by the live
  delegate bloc (fork-proven).
* No CEX, no bridge, no second-chain float, no lending market for KITE. There is no market route to
  the winning stake; it would require a coordinated OTC purchase from most large holders.
