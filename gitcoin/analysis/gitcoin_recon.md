# Gitcoin DAO Governance — Recon (Ethereum mainnet)

**Pinned block:** 26253666 (~2026-10-23) · **chainId:** 1 · read-only (`eth_call`/`eth_getLogs`/APIs)
**RPC:** `https://<rpc>` (redacted)

> Headline: the prior lane looked at the **legacy** governor. The **active** governor is a different
> contract (`0xef41…`, "Gitcoin Governor Charlie", OZ v5 + ProposalGuardian), and the treasury's
> entire GTC stake (~12.5M) is delegated to the **same 4-of-6 Safe that is the proposal guardian** —
> giving that Safe both the power to *cancel* proposals and ~12.5% of voting power.

---

## 1. Contracts

| Role | Address | Contract | Notes |
|---|---|---|---|
| Active governor | `0xef41CbD211076E8b1901e214Bf751d404cf06638` | `GitcoinGovernorWithGuardian` ("Gitcoin Governor Charlie"), solc 0.8.35 | deployed blk **25776742** (2026-08-17) |
| Legacy governor | `0x9D4C63565D5618310271bF3F3c01b2954C1D1639` | `GitcoinGovernor` ("GTC Governor Bravo"), solc 0.8.17 | deployed blk 17813942 (2023-07-31) |
| Timelock | `0x57a8865cfB1eCEf7253c27da6B4BC3dAEE5Be518` | Compound-style Timelock (solc 0.6.12) | deployed 2021-05-24 |
| GTC token | `0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F` | ERC20VotesComp "Gitcoin" | totalSupply **100,000,000 GTC** |
| Proposal Guardian **and** veto multisig | `0x5743E35477363241300FcEdc2F5eB0195F300817` | Gnosis Safe **v1.4.1** | **4-of-6**, created blk 24836964 (2026-04-08) |

---

## 2. Governor parameters (verified at block 26253666)

| Param | **Active** (`0xef41…`) | Legacy (`0x9D4C…`) | Prior claim |
|---|---|---|---|
| `name()` | `Gitcoin Governor Charlie` | `GTC Governor Bravo` | — |
| `quorum(<blk>)` | **1,500,000 GTC** | 2,500,000 GTC | 2,500,000 ❗stale |
| `proposalThreshold()` | **150,000 GTC** | 150,000 GTC | 150,000 ✅ |
| `votingDelay()` | **14,400 blocks** | 13,140 blocks | 13,140 ❗stale |
| `votingPeriod()` | **40,320 blocks** | 40,320 blocks | 40,320 ✅ |
| `timelock()` | `0x57a8…` | `0x57a8…` | ✅ |
| `COUNTING_MODE()` | `support=bravo,fractional&quorum=for,abstain&params=fractional` | `support=bravo&quorum=for,abstain&params=fractional` | — |
| `CLOCK_MODE()` | `mode=blocknumber&from=default` | — | — |
| `proposalGuardian()` | **`0x5743…`** | n/a (no guardian) | "a Proposal Guardian" ✅ (address now known) |
| `lateQuorumVoteExtension()` | 7,200 blocks | n/a | — |
| `proposalNeedsQueuing()` | true | true | — |
| `cancel()` exists | **yes** (`0x452115d6`) | no | — |

Timelock: `admin()` = `0xef41…` (active governor), `pendingAdmin()` = `0x0`, `delay()` = **172,800 s (2 days)**,
`GRACE_PERIOD()` = 1,209,600 s (14 days), `MINIMUM_DELAY` 172,800, `MAXIMUM_DELAY` 2,592,000. ✅ delay matches claim.

---

## 3. Proposal Guardian — who can cancel and under what conditions

- `proposalGuardian()` = **`0x5743E35477363241300FcEdc2F5eB0195F300817`**.
- That address is a **Gnosis Safe v1.4.1, threshold 4, 6 owners**:
  `0xdB2A…D743, 0x0EdE…F8ee, 0x00De…5Fc3, 0x393B…18Cf, 0xc2E2…6099, 0x5a5D…a9C3`.
- Mechanism (`GovernorProposalGuardian._validateCancel` + `Governor.cancel/_cancel`): the guardian
  **can cancel any proposal in any state except Canceled, Expired, or Executed** — i.e. **Active,
  Pending, Defeated, Succeeded and Queued** proposals are all cancelable. Cancellation only *cancels*;
  the guardian can never modify or force execution.
- `setProposalGuardian(address)` is `onlyGovernance` → the DAO can replace/remove the guardian only via
  a full governance proposal. The legacy governor has no cancel function at all.

**Conclusion:** the guardian (4-of-6 Safe) can cancel a **Queued or Active** proposal. It is both the
safety council *and* the holder of the treasury's delegated votes (see §5).

---

## 4. Timelock balances & USD

Native: **138.763666637965409775 ETH**. Priced tokens (DefiLlama, latest):

| Token | Qty | Price | USD |
|---|---:|---:|---:|
| GTC | 12,508,498.095757 | $0.316952 | $3,964,589.72 |
| RAD | 680,272.108 | $0.279666 | $190,248.69 |
| USDC | 112,326.376588 | $0.999515 | $112,271.94 |
| DAI | 2,500 | $1.00003 | $2,500.07 |
| SYND | 200,000 | $0.006185 | $1,236.99 |
| CYBER | 300 | $0.313996 | $94.20 |
| MTV / GRG / WETH | dust | — | <$1 |
| **ETH** | 138.763667 | $2,399.76 | $332,998.81 |
| **TOTAL (priced)** | | | **≈ $4,603,941** |

- The **~$4.95M** prior figure is in the right ballpark; at current prices it is **≈$4.60M** (driven by GTC price).
- **LP / NFTs held by timelock:** a **Uniswap V3 LP position NFT** (`UNI-V3-POS`, `0xC364…FE88`, tokenId **25670**)
  = SACKS/WETH 0.05% pool (liquidity 86,081,853,130,684,128,716; tokensOwed 0). Value not priced (SACKS is illiquid).
  Plus 3 ERC-1155s (Access Liquideth, NativePunks, Maverick Reward).
- **Unpriced notable:** **24,000,000 WNDR** (DeFi Wonderland, `0xB3A6…2605`) — no DefiLlama price; plus ALA, FNF, HAM, ELIMU and dust.
- **Admin/owner of other contracts:** the timelock is the *executor/admin* of governance (it is the
  `timelock()` target of the governor and the governor is its `admin()`), and it is the owner of the LP NFT.
  No exhaustive ownership enumeration was performed (see `notes.md`).

---

## 5. GTC delegation landscape

- `GTC.totalSupply()` = **100,000,000 GTC** (18 decimals).
- **Treasury GTC IS delegated:** `GTC.delegates(timelock 0x57a8…)` = **`0x5743…`** (the veto multisig).
  `getCurrentVotes(timelock)` = **0** (delegated away); the timelock delegated once, at block **24928212** (2026-04-21).
- **Largest delegate = `0x5743…` (veto multisig / proposal guardian) with `getCurrentVotes` =
  12,508,498.263341596282817320 GTC.**

Top delegates (exact `getCurrentVotes`):

| Delegate | Votes (GTC) | Label |
|---|---:|---|
| `0x5743E35477363241300FcEdc2F5eB0195F300817` | 12,508,498.26 | veto multisig / guardian (treasury GTC) |
| `0x00De4B13153673BCAE2616b67bf822500d325Fc3` | 2,487,835.87 | guardian Safe owner |
| `0x93f80a67fdfdf9daf1aee5276db95c8761cc8561` | 500,000.00 | |
| `0xc2E2B715d9e302947Ec7e312fd2384b5a1296099` | 409,520.48 | guardian Safe owner |
| `0xb35659cbac913d5e4119f2af47fd490a45e2c826` | 152,245.14 | |
| `0x393BC37ea5493233D2bDC68FD59Dd97Ee01B18Cf` | 3,971.82 | guardian Safe owner |

- Sum over the candidate delegate set ≈ **16,066,524 GTC delegated (~16%)**, leaving **~84% undelegated**.
  The single largest *holder* `0x14D7Cee42D4643f0C767A1D504d9cA24C890f86c` holds **21,509,235.53 GTC** and
  **delegates to `0x0`** (undelegated). (Delegated total is a lower bound — candidate set built from top-50
  holders + DelegateChanged events since block 23,000,000.)

---

## 6. Recent governance activity

- **Legacy governor (Bravo, `0x9D4C…`): 49 proposals total**, first 2023-08-23, last **2026-09-23** (block 26041897).
  Recent proposers: `0x393BC37e…` (a steward), `0xdfBecC0b…`, `0x00De4B13…` (guardian owner).
- **Active governor (`0xef41…`): ZERO `ProposalCreated` events** since deployment. **No Active/Pending proposal
  exists anywhere. No hostile proposal currently exists.**
- **Apr-2026 security proposals** (on the legacy governor):
  - blk 24844817 (2026-04-09) "Temporary Transition to Multisig Execution" — `USDC.transfer(0x5743…, 5,000,000 USDC)`.
  - blk 24845002 (2026-04-09) "Delegate GTC to Veto Multisig" — `GTC.delegate(0x5743…)`, delegating the
    treasury's ~12,508,498.0957571 GTC to the veto multisig.
- **Veto multisig currently holds** ~4,321,564 USDC + 70 ETH (separate from the timelock's 112,326 USDC).
  So the 4-of-6 Safe custodies the bulk of liquid USDC *and* holds the 12.5M delegated GTC *and* the guardian cancel power.
- No `ProposalCanceled` events on either governor. No `CancelTransaction` on the timelock.
- Timelock: 6 `QueueTransaction` since blk 24,000,000, **all 6 matched by `ExecuteTransaction`** → no pending tx.

---

## 7. The upgrade to OZ v5 (exact blocks)

- New governor `0xef41…` **deployed at block 25776742** (2026-08-17T18:57:35Z) by `0xba41c0…28f6`.
- **Timelock admin switched at block 26127931** (2026-10-05T18:22:35Z), tx `0x50364b5286205edc8025…`.
  This tx is the execution of the final legacy proposal #49 "Upgrade the Gitcoin Governor"
  (two actions: `timelock.setPendingAdmin(newGov)` + `newGov.acceptAdmin()`).
- **Old governor can no longer execute:** the Compound timelock only lets its `admin()` queue/execute, and
  `admin()` is now `0xef41…`. All 49 legacy proposals are Executed/Defeated and there are no pending
  timelock transactions, so nothing legacy is stranded.
- New governor uses OZ `GovernorProposalGuardian` (marked "last updated v5.5.0"), `GovernorPreventLateQuorum`,
  `GovernorSettableFixedQuorum`, `GovernorCountingFractional`, `GovernorVotesComp`, `GovernorTimelockCompound`,
  `GovernorSettings`. Migration rationale (on-chain description): Tally shutdown / ScopeLift takeover; add
  Proposal Guardian, late-quorum protection, DAO-adjustable quorum.

---

## 8. Corrections to the prior claims

1. **Governor identity/upgrade** — `0x9D4C…` is the **legacy** governor. Active governor is **`0xef41…`**.
   New contract deployed **2026-08-17**; the **2026-10-05** event is the timelock admin hand-over (activation).
2. **quorum** — legacy 2,500,000 GTC; **active = 1,500,000 GTC**.
3. **votingDelay** — legacy 13,140; **active = 14,400**.
4. **proposalThreshold 150,000 / votingPeriod 40,320 / timelock delay 172,800s** — confirmed.
5. **Timelock holdings** — confirmed (12,508,498 GTC, 138.7637 ETH, 112,326.38 USDC). Treasury ≈ **$4.60M** now.
6. **Proposal Guardian** — confirmed; address is `0x5743…` (4-of-6 Safe); can cancel Active **and** Queued.
7. **Veto multisig delegation** — **the "~4.06M GTC" figure is wrong.** The veto multisig `0x5743…` currently
   holds **12,508,498.263 GTC** delegated (the whole treasury GTC), continuously since ~block 25,000,000.

---

## 9. Exact commands used (RPC redacted as `https://<rpc>`)

```bash
# env (never echoed)
set -a; . /home/heisenberg/CA/.env; set +a
BLK=26253666
GOV=0xef41CbD211076E8b1901e214Bf751d404cf06638        # active
OLD=0x9D4C63565D5618310271bF3F3c01b2954C1D1639        # legacy
TL=0x57a8865cfB1eCEf7253c27da6B4BC3dAEE5Be518
GTC=0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F
G=0x5743E35477363241300FcEdc2F5eB0195F300817         # guardian / veto multisig

# governor params
cast call $GOV 'name()(string)'            --rpc-url https://<rpc> --block $BLK
cast call $GOV 'quorum(uint256)(uint256)'  $BLK --rpc-url https://<rpc> --block $BLK
cast call $GOV 'proposalThreshold()(uint256)' --rpc-url https://<rpc> --block $BLK
cast call $GOV 'votingDelay()(uint256)'    --rpc-url https://<rpc> --block $BLK
cast call $GOV 'votingPeriod()(uint256)'   --rpc-url https://<rpc> --block $BLK
cast call $GOV 'timelock()(address)'       --rpc-url https://<rpc> --block $BLK
cast call $GOV 'COUNTING_MODE()(string)'   --rpc-url https://<rpc> --block $BLK
cast call $GOV 'CLOCK_MODE()(string)'      --rpc-url https://<rpc> --block $BLK
cast call $GOV 'proposalGuardian()(address)' --rpc-url https://<rpc> --block $BLK
cast call $GOV 'lateQuorumVoteExtension()(uint48)' --rpc-url https://<rpc> --block $BLK
cast call $GOV 'proposalNeedsQueuing(uint256)(bool)' 0 --rpc-url https://<rpc> --block $BLK
# legacy
cast call $OLD 'quorum(uint256)(uint256)' 26253665 --rpc-url https://<rpc> --block $BLK
cast call $OLD 'votingDelay()(uint256)'    --rpc-url https://<rpc> --block $BLK

# timelock
cast call $TL 'admin()(address)'           --rpc-url https://<rpc> --block $BLK
cast call $TL 'pendingAdmin()(address)'    --rpc-url https://<rpc> --block $BLK
cast call $TL 'delay()(uint256)'           --rpc-url https://<rpc> --block $BLK
cast call $TL 'GRACE_PERIOD()(uint256)'    --rpc-url https://<rpc> --block $BLK
cast balance $TL --rpc-url https://<rpc> --block $BLK

# guardian Safe
cast call $G 'getThreshold()(uint256)'     --rpc-url https://<rpc> --block $BLK
cast call $G 'getOwners()(address[])'      --rpc-url https://<rpc> --block $BLK
cast call $G 'VERSION()(string)'           --rpc-url https://<rpc> --block $BLK

# GTC delegation
cast call $GTC 'totalSupply()(uint256)'    --rpc-url https://<rpc> --block $BLK
cast call $GTC 'delegates(address)(address)' $TL --rpc-url https://<rpc> --block $BLK
cast call $GTC 'getCurrentVotes(address)(uint256)' $G --rpc-url https://<rpc> --block $BLK
cast call $GTC 'getPriorVotes(address,uint256)(uint256)' $G 25000000 --rpc-url https://<rpc>

# events (Etherscan V2 getLogs; topic0 via cast keccak)
cast keccak "ProposalCreated(uint256,address,address[],uint256[],string[],bytes[],uint256,uint256,string)"
cast keccak "VoteCast(address,uint256,uint8,uint256,string)"
cast keccak "ProposalQueued(uint256,uint256)"
cast keccak "ProposalExecuted(uint256)"
cast keccak "DelegateChanged(address,address,address)"
cast keccak "NewAdmin(address)"
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs&fromBlock=25776742&toBlock=$BLK&address=$GOV&topic0=<topic0>&apikey=$ETHERSCANV2_API_KEY"
# decode a ProposalCreated log:
cast decode-abi "f(uint256,address,address[],uint256[],string[],bytes[],uint256,uint256,string)(uint256,address,address[],uint256[],string[],bytes[],uint256,uint256,string)" <data>

# creation / verification
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address=$GOV&apikey=$ETHERSCANV2_API_KEY"
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getcontractcreation&contractaddresses=$GOV&apikey=$ETHERSCANV2_API_KEY"

# balances & prices
curl -s "https://eth.blockscout.com/api/v2/addresses/$TL/token-balances"
curl -s "https://eth.blockscout.com/api/v2/tokens/$GTC/holders?items_count=50"
curl -s "https://coins.llama.fi/prices/current/ethereum:$GTC,coingecko:ethereum"
```
