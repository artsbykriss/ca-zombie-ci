# Rabby Swap legacy router (19 chains) — live allowance census of a 2022 arbitrary-call router

**Date:** 2026-10-23 · **Chains:** 19 (Ethereum, BNB Chain, Polygon, Avalanche, Fantom, Optimism, Arbitrum, Gnosis, Cronos, Aurora, Harmony, Metis, Moonbeam, Arbitrum Nova, Klaytn/Kaia, Astar, Boba, HECO, Celo)
**Status:** read-only — no transaction was signed or sent on any network. All exploit logic is exercised on local forks only (Foundry, CI). No secrets or keyed RPC URLs are stored in this folder.

**CI (PoC + census):** see §7.

---

## TL;DR

| Item | Value |
|---|---|
| **Target family** | The legacy Rabby Swap router (`RabbyRouter` v1.0), one identical implementation deployed at 19 addresses (registry: `RevokeCash/approval-exploit-list/exploits/rabby.json`) |
| **Bug** | `swap(...)` performs an **unvalidated external call** to a caller-supplied `dexRouter` with caller-supplied `data` (OpenZeppelin `Address.functionCallWithValue`, inlined). A caller can make the router itself call `token.transferFrom(victim, attacker, amount)`, consuming any standing allowance the victim granted to the router |
| **2022 incident** | 2022-10-11, ~$200k (114 ETH + 179 BNB), attacker `0xb687…9d55`, ~27 txs; Rabby reimbursed users |
| **Was it fixed?** | **No.** Ethereum router bytecode at the 2022 exploit block (15,724,451) is **byte-identical** to today (keccak `0xc721ffeb…3895`). All 18 reachable deployments are **unpaused** (`paused() == false`) |
| **Mechanism still live?** | **Yes, fork-proven** — a fresh caller `0x1111…` drains a third party's standing USDC approval through the live deployed contract (gas **123,328**) |
| **Residual live approvals (all chains)** | **≈ $0.13 of dust** (see §5); Ethereum **$0**, Arbitrum **$0**, Avalanche **$0**, Gnosis **$0**, BSC/Aurora/Metis/Boba **$0**, Polygon **$0.13** (AURUM + LUNA dust) |
| **Headline E-U (external unprivileged, now)** | **$0.13** (Polygon dust; no position ≥ $1k — materially **$0**) |
| **Confidence** | **High** on the mechanism and on Ethereum/Arbitrum/Avalanche/Gnosis/BSC (full census); **medium** on the long-tail chains where only a bounded post-deployment window could be scanned (see §5/§9) |
| **Verdict** | **CLOSED / latent** — the vulnerability is permanent and live, but there is no material value left to extract. Keep only as a *latent* risk (future approvals would re-arm it) |

---

## 1. The bug in exact terms

The legacy router exposes one dangerous external entry point:

```solidity
function swap(
    address srcToken, uint256 amount, address dstToken, uint256 minReturn,
    address dexRouter, address dexSpender, bytes memory data, uint256 deadline
) external payable;
```

Selector `0x32854cc2` (`swap(address,uint256,address,uint256,address,address,bytes,uint256)`), confirmed present in the deployed bytecode (pc `0x7c` → handler at `0x00fe`) and in the 4byte database.

Inside `_swap`, after the (optional) `srcToken` pull, the router performs:

```solidity
(bool success, bytes memory ret) = dexRouter.functionCallWithValue(data, value);
```

`dexRouter` **and** `data` are fully caller-controlled and **never validated** (no allow-list, no selector check). Because the call is made *by the router*, `msg.sender` for the inner call is the router itself. So if the caller sets `dexRouter = <token>` and `data = transferFrom(victim, attacker, amount)`, the router spends the victim's **standing approval to the router**.

Deployed-code evidence (`analysis/code/eth_router.asm`):
- dispatcher contains `PUSH4 0x32854cc2` (pc `0x7c`), plus `0x19f4ff2f setFeeRatio`, `0x41744dd4 feeRatio`, `0x5c975abb paused`.
- an inlined generic call at pc `0x02f5–0x0302`: `… DUP8 GAS CALL` with the target and calldata taken from memory that was populated from calldata.
- The contract is **unverified** on Etherscan (no source/ABI); the analysis above is from the runtime bytecode + the 2022 post-mortems (SlowMist, Beosin, 零时科技, Neptune Mutual) and the DeFiHackLabs reproduction.

A second defect noted in the audit ("redundant Ether transfer", missing `require(amount == msg.value)` on the ETH route) is not needed for the drain and is not counted here.

### The historical attack path (for reference)

```solidity
router.swap(
    address(USDT),        // srcToken  (amount = 0 -> pull nothing)
    0,                    // amount
    address(fakeDst),     // dstToken  (a contract faking balanceOf/transfer)
    4660,                 // minReturn
    address(USDC),        // dexRouter = the token to drain
    address(USDC),        // dexSpender
    abi.encodeWithSelector(USDC.transferFrom.selector, victim, attacker, victimBal),
    block.timestamp
);
```

---

## 2. Address list and provenance

Source of truth: **`RevokeCash/approval-exploit-list`** → `exploits/rabby.json`
(`https://raw.githubusercontent.com/RevokeCash/approval-exploit-list/main/exploits/rabby.json`), the data behind
<https://revoke.cash/exploits/rabby>. 19 `{chainId, address}` entries.

| # | Chain | chainId | Router address |
|---|---|---|---|
| 1 | Ethereum | 1 | `0x6eb211CAF6d304A76efE37D9AbDFAdDC2d4363d1` |
| 2 | BNB Chain | 56 | `0xf756a77E74954C89351c12da24C84d3c206E5355` |
| 3 | Polygon | 137 | `0xf23B0F5CC2e533283Ea97f7B9245242b8D65b26b` |
| 4 | Avalanche | 43114 | `0x509f49aD29d52bfAacAC73245Ee72c59171346A8` |
| 5 | Fantom | 250 | `0x3422656fB4BB0C6b43b4BF65Ea174D5b5EBc4A39` |
| 6 | Optimism | 10 | `0xD1a57cb694CF4941360a937d5F5633B363204E18` |
| 7 | Arbitrum | 42161 | `0xf401C6373A63c7A2ddF88D704650773232cea391` |
| 8 | Gnosis | 100 | `0x5a0aB5d78C4d40E3a467a8BC52cE16Cce88c999D` |
| 9 | Cronos | 25 | `0xa1B61f32A7C11e64df6b11d420D2BB7656F4b6AB` |
| 10 | Aurora | 1313161554 | `0x67832c40Daf905Ea5dDe3fCa036219E861a6bb8A` |
| 11 | Harmony | 1666600000 | `0x563B6C3646E587cAAd54D57b5C0E98d7E99Aeb4f` |
| 12 | Metis | 1088 | `0xb490F6A28eB43709410737dbdC1Ffb4D3a5c4989` |
| 13 | Moonbeam | 1284 | `0xA166A168463c44c6C973C4F8adF97031D7B25499` |
| 14 | Arbitrum Nova | 42170 | `0xE02504dCBc0721e7a4861c56b842c53E28DEc84d` |
| 15 | Klaytn/Kaia | 8217 | `0xFCDa4bd27E841dEc3D8A49a3187f44757C8B9EAC` |
| 16 | Astar | 592 | `0x563B6C3646E587cAAd54D57b5C0E98d7E99Aeb4f` |
| 17 | Boba | 288 | `0x328fD59A417463AF4b0a465794AD627d5fc90d7B` |
| 18 | HECO | 128 | `0x275aD6133d7662E6feB70365c93d78363286DFcC` |
| 19 | Celo | 42220 | `0xC9F8a7d8Cabb46135a90b9fa0CE58B75E8d15Cc5` |

Corroboration: the 2022 Beosin/零时科技 lists name ETH `0x6eb211…`, BSC `0xf756a7…`, Polygon `0xf23b0f…`,
Avalanche `0x509f49…`, Fantom `0x342265…`, Arbitrum `0xf401c6…` — all matching the registry. The Etherscan
examples in the pass-2 lane (`0x275aD613…`, `0x328fD59A…`, `0x3422656f…`) are the HECO, Boba and Fantom entries.

---

## 3. Deployed reality: one implementation, never patched, never paused

`eth_getCode` + `keccak256` of the runtime code, plus `paused()`/`owner()` reads, were performed on all 19 chains
(see `analysis/live_state.py`, `ci-out/raw/live_state_all.json`).

- **18 of 19** chains have the router deployed (HECO's RPC is dead — no endpoint serves it; the HECO copy is
  assumed present but unverifiable, see §9).
- Every reachable deployment is **10,402 bytes** and **`paused() == false`**.
- There are three runtime-code hashes, and they differ **only in the trailing 43-byte Solidity metadata**:
  the functional code (first 10,359 bytes) is **byte-identical** across all three families.

| Runtime hash | Chains |
|---|---|
| `0xc721ffeb1e240f323bf491ac19ef3a6d5797d3e606fe1df8e7a0ee05453e3895` | Ethereum, BNB Chain, Polygon, Avalanche, Fantom, Optimism, Arbitrum, Gnosis, Cronos |
| `0x4eab96dd05e5dbcc392b65ba3f1ae97fddce7ad2d53fdfe62303121d9517bd2f` | Harmony, Moonbeam, Klaytn/Kaia, Aurora, Metis, Arbitrum Nova |
| `0xcce19a0cb870016c6c4dacdf0949bc8eadbd87d8c8b67918e1d137fb18b5cbf4` | Astar, Boba, Celo |

Proof of "never patched" on Ethereum: the runtime code at the **2022 exploit block 15,724,451** hashes to
`0xc721ffeb…3895` — identical to the code at the latest block. `eth_getTransactionCount(router) = 1` (deployment only).

Owner of the family: `0x2Cc26F59379832fDe97a6c35Abcd80D672846194` (Boba differs: `0x5853ed4f26a3fcea565b3fbc698bb19cdf6deb85`).
`feeRatio() = 875` (8.75%). No chain has been paused.

---

## 4. What an attacker can and cannot do (fork-proven)

**Can (unprivileged, any EOA):** for any victim `V` with `allowance(V, router) > 0` and `balanceOf(V) > 0`,
call `router.swap(USDT, 0, fakeDst, 4660, <token>, <token>, transferFrom(V, attacker, x), now)` and receive
`min(allowance, balance)` of `<token>`. Cost: one tx (~123k gas). No privileges, no capital.

**Cannot:**
- Drain anything from a victim with **no** standing allowance (the inner `transferFrom` reverts).
- Extract from the router's own balance — the router holds **0** tokens/native on every chain.
- Use the router to bypass token-level restrictions (frozen/blacklisted tokens still block `transferFrom`).

**Preconditions are the whole story:** the exploit is fully gated on *existing* approvals. Four years of
Revoke.cash warnings + Rabby's own reimbursement campaign have eliminated them — the census below quantifies this.

---

## 5. Live allowance census

Method (per chain): enumerate `Approval(owner, spender=router, value)` logs, dedupe to the latest approval per
`(token, owner)`, then read the **current** `allowance(owner, router)` and, where non-zero, `balanceOf(owner)`.
Extractable = `min(allowance, balance)`. A separate pass checks ERC-721/1155 `ApprovalForAll(operator=router)`.

Sources: public/CI RPCs (`eth_getLogs`, adaptive chunking; deployment-block detection) as the primary path, with the
**Etherscan V2** topic-only log API as a fallback for Ethereum/Polygon/Arbitrum/Celo. Full data in `ci-out/raw/census_*.json`, `ci-out/census_summary.json`.

| Chain | block | Approval logs | (token,owner) pairs | live | unread | coverage |
|---|---:|---:|---:|---:|---:|---|
| ethereum | 26,255,821 | 1,122 | 498 | 0 | 0 | full |
| bsc | 129,335,237 | 1,823 | 499 | **1** | 0 | full |
| polygon | 96,039,431 | 6,272 | 1,460 | **2** | 0 | full |
| avalanche | 98,339,890 | 369 | 123 | 0 | 0 | full |
| fantom | 123,796,877 | 183 | 59 | 0 | 0 | full (from deployment) |
| optimism | 158,582,916 | 1,965 | 573 | 0 | 1 | full |
| arbitrum | 517,557,238 | 2,182 | 627 | 0 | 0 | full |
| gnosis | 48,902,530 | 178 | 72 | 0 | 0 | full |
| cronos | 101,707,761 | 13 | 9 | 0 | 0 | partial (from deployment) |
| aurora | 221,249,394 | 0 | 0 | 0 | 0 | full |
| harmony | 93,624,315 | 8 | 4 | 0 | 0 | partial (from deployment) |
| metis | 23,312,828 | 3 | 1 | 0 | 0 | full |
| moonbeam | 16,796,699 | 0 | 0 | 0 | 0 | partial (from deployment) |
| arbitrum-nova | 85,287,094 | 29 | 11 | 0 | 0 | partial (from genesis) |
| klaytn/Kaia | 230,566,697 | 0 | 0 | 0 | 0 | partial (2022 window) |
| astar | 15,194,709 | 6 | 3 | 0 | 0 | partial (from deployment) |
| boba | 40,880,824 | 3 | 1 | 0 | 0 | full (from deployment) |
| heco | — | — | — | — | — | RPC unavailable (chain dead) |
| celo | 80,865,926 | 0 | 0 | 0 | 0 | partial (from genesis) |
| **TOTAL** | | **14,156** | **3,940** | **3** | **1** | |

`full` = every block from the router's deployment (or genesis) to latest was scanned. `partial` = the RPC caps
`eth_getLogs` ranges, so a bounded window was scanned — always starting at the deployment block, i.e. covering the
Sept–Oct 2022 approval window first. The single `unread` pair (Optimism) is an RPC read error, not a live approval.

**ERC-721/1155 `ApprovalForAll(operator=router)`:** **0 events on every chain** (the arbitrary call could have
exploited an NFT operator approval too). See `ci-out/raw/nft_approvals_all.json`.

Only **3 live positions** exist across all 19 chains, all dust:

| Chain | Token | Owner | Amount | USD | last approval |
|---|---|---|---:|---:|---:|
| BNB Chain | `0x9d39ef3b…ee75` (WEAR / "Metawear") | `0x5c64c14f…f266` | 10 WEAR | **$0** (no DEX pair, no price) | block 21,367,776 |
| Polygon | `0x34d4ab47…ee23` (AURUM) | `0x741df195…f001` | 0.2701 AURUM | ~$0.00002 | block 35,640,325 |
| Polygon | `0x9cd67466…3439` (LUNA) | `0xc2a4d83a…a30b` | 2,839.66 LUNA | **~$0.13** | block 33,162,221 |

Every other `(token, owner)` pair from the historical approval logs has **either a revoked allowance or a
zero balance** (e.g. Ethereum: 64 pairs still carry a non-zero allowance but hold **0** tokens; Arbitrum: 137
such pairs; all with zero balance). The router itself holds **0** tokens/native on every chain.

**Total live extractable (E-U) = $0.13**, all Polygon dust. No position anywhere reaches $1k.

Categories: **E-U $0.13 (dust)** · **E-U-conditional $0** (no live material allowance) · **H-O** n/a (revocation is
self-service, recovers nothing) · **P** $0 (owner can `pause()`/`setFeeRatio` but holds no value) · **S** $0
(router holds no tokens).

---

## 6. PoC / fork verification

Project: `poc/` (Foundry 1.8.5, solc 0.8.24, vendored `lib/forge-std`). Tests in `poc/test/RabbySwapLegacy.t.sol`.

| Test | Result | Proves |
|---|---|---|
| `test_live_router_state` | PASS | code present (10,402 B), selector `0x32854cc2` in bytecode, `paused()==false`, owner/feeRatio read |
| `test_fresh_caller_drains_standing_allowance` | PASS | fresh caller `0x1111…` drains a third party's 1,000,000 USDC through the **live** router; gas **123,328** |
| `test_no_allowance_cannot_drain` | PASS | without a standing allowance the same call reverts (negative control) |
| `test_historical_replay_2022` | PASS | fork at block 15,724,451: 6 known victims drain **5,204.918440 USDC** via the deployed bytecode |
| `test_router_holds_no_tokens` | PASS | router holds 0 USDC/USDT/ETH (no "stuck" bucket) |

Reproduce:

```bash
cd poc
FORK_RPC_URL=<archive-rpc> BLOCKPI_RPC_URL=<archive-rpc> forge test -vv
```

CI runs (`artsbykriss/ca-zombie-ci`, `poc.yml`):

- **Final:** [run 39966961644](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39966961644) — **5/5 tests PASS**, 19-chain census + NFT scan. Artifact `result-rabby-swap-legacy`.
- [run 39957404961](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957404961) — 5/5 PASS, census v2.
- [run 39921749857](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39921749857) — 5/5 PASS, first census.

---

## 7. Verdict, residual and latent risk

**Verdict: CLOSED / latent — headline E-U ≈ $0.00 (confidence high for the major chains).**

The vulnerability is *structurally permanent* (immutable, unpaused, unpatched on 18 chains) and the call path
*works today* (fork-proven), but the economic precondition — a live, material allowance — is gone. The only
residual value found is sub-cent dust on Polygon and a marketless BNB-Chain token.

**Latent risk (the real takeaway):** the router is still a live approval-spender. Any user who *re-approves*
it (or a wallet that auto-approves it) re-arms the exploit for anyone. Revoke.cash keeps it on the exploit list
precisely for this reason. This is a *monitor/awareness* item, not a funded target.

**Blockers / caveats:** HECO has no reachable RPC (its copy is unverified); a few long-tail chains
(Harmony/Astar/Moonbeam/Klaytn/Cronos/Nova) could only be scanned over a bounded post-deployment window because
their public RPCs cap `eth_getLogs` ranges. Those chains are documented in `ci-out/census_summary.json` with
`partial: true` where applicable.

---

## 8. Methodology & sources

- Registry: `RevokeCash/approval-exploit-list/exploits/rabby.json`; Revoke.cash exploit page.
- Post-mortems: SlowMist, Beosin, 零时科技 (learnblockchain.cn/article/4881), Neptune Mutual; DeFiHackLabs
  `RabbyWallet_SwapRouter_exp.sol` (attacker `0xb687…9d55`, attack contract `0x9682f3…6475`, tx
  `0x914c1ae4…bfc26` @ block 15,724,452).
- On-chain: `eth_getCode`, `eth_call` (`paused`, `owner`, `feeRatio`, `allowance`, `balanceOf`, `symbol`,
  `decimals`), `eth_getLogs` (`Approval`/`ApprovalForAll` by topic), Etherscan V2 topic-only log API.
- Decompilation: `cast disassemble` of the runtime bytecode (`analysis/code/eth_router.asm`).
- Pricing: DefiLlama `coins.llama.fi`, DexScreener.
- All heavy compute (Foundry fork tests, 19-chain census) ran on GitHub Actions (`artsbykriss/ca-zombie-ci`).

**Caveats:** point-in-time (2026-10-23); balances/allowances are read at the blocks in `ci-out/census_summary.json`;
dust positions are valued at DefiLlama spot and are not worth liquidation. No mainnet transactions; no secrets stored.

**Files:** `README.md` · `summary.json` · `analysis/` (`addresses.json`, `census.py`, `live_state.py`,
`nft_approvals.py`, `valuation.py`, `chains.json`, `code/eth_router.{hex,asm}`, `evidence.md`, `raw/`) ·
`poc/` (Foundry) · `ci/run.sh` · `ci-out/` · `ci-log.txt` · `ci-artifacts/`.
