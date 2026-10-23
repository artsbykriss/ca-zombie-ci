# PurrSwap — analysis notes

## What this is
Deep-dive on the Abracadabra **PurrSwap** (DODO-PMM fork) deployment on **HyperEVM (chainid 999)**,
covering Guardian findings **C-06** (no oracle validation in `Factory.create`), **C-07** (wrong
initial target updates), **H-02** / **M-06** (stale `_I_` when no oracle), all ACKNOWLEDGED by the team.

## Method (read-only)
1. Source: Etherscan V2 API `chainid=999` `getsourcecode` for the Factory and PurrLP implementation.
   Flattened standard-json saved under `analysis/src/factory/` and `analysis/src/purrlp/`.
2. Enumeration by event, not by docs: global `eth_getLogs` for the factory's `LogCreated`
   (topic0 `0x2a0061…`) from deploy block to latest → exactly **2** pools. All factory events → 6 logs
   total (2 `LogCreated`, 2 `LogPoolAdded`, 2 `OwnershipTransferred`) → no pool added by any other path.
3. Live state at pinned block **49,292,001** (`cast call --block`), keyless RPC.
4. LP holders via ERC-20 `Transfer` logs on each pool.
5. Pricing via DefiLlama `coins.llama.fi/prices/current/hyperevm:<token>`.
6. Mechanism PoC: Foundry fork test `poc/test/PurrSwap.t.sol` (no broadcasts).

## Key results
- Factory `implementation()=0x76DA…74c1`, `owner()=0xfB34…0eE3` (Abracadabra safe). `create()` has
  **no oracle validation** — proven on fork: an attacker EOA created a pool with a mock oracle and set
  `i` freely (1e18 → 5e18 → 0.01e18), plus a second pool with a bare EOA oracle (`0xdead`).
- Both live pools have `_ORACLE_ == address(0)`, so `getEffectiveI()` returns the frozen `_I_`
  (pool1 `15e18`, pool2 `1e18`). There is **no setter** for `_I_`/`_ORACLE_` on PurrLP → permanent.
- Pool2 (wstHYPE/WHYPE) frozen `i = 1.0` vs market `i ≈ 1.02635` (DefiLlama prices) → ~2.64% stale
  mispricing, demonstrated via `querySellBase` (frozen 1,000,375,559,624 vs market 1,026,738,686,015
  for a 1e12 base sell).
- **Live value:** pool1 ≈ $0 (only 1001 dead shares; 639 wei WHYPE + 20535 wei KEI stuck); pool2
  ≈ **$0.078** (2.0589e-4 wstHYPE + 7.8447e-4 WHYPE), all of it held by one EOA LP
  `0x1453Acb73B4c13BCE00496Ae00DdC7E4cF484C6c` who can `sellShares` it (verified on fork).

## Why E-U = $0 (not inflated)
- C-06 / C-07 harm is **opt-in**: a pool's liquidity and its (mis)pricing only affect whoever
  voluntarily LPs into / trades that pool. `Factory.create` is permissionless by design and was
  **acknowledged** (M-03). An attacker can create a malicious pool, but cannot force any external
  victim to supply liquidity or trade against it — there is no protocol-owned liquidity, no router
  that routes users into attacker pools, and no shared vault.
- The two existing pools hold dust and are effectively abandoned. There is nothing to extract.
- So the external-unprivileged extractable value today is **$0**; the dust that does exist is
  holder-only recoverable (**H-O ≈ $0.078**).

## Negative results / dead ends (so they are not re-investigated)
- `setParameters(...)` and `setOracle(...)` calls on the live pool **revert** (no such functions) —
  `_I_`/`_ORACLE_` cannot be changed post-`init`.
- Pool1 has `totalSupply == 1001` = exactly the dead shares minted to `0x0`; no LP can redeem its
  639 wei WHYPE / 20535 wei KEI reserves (H-O not applicable there; effectively $0 stuck).
- A **separate** Abracadabra **MIMSwap / MagicLP** factory exists on HyperEVM
  (`0xc8f5eb8a632f9600d1c7bc91e97dad5f8b1e3748`, impl `0xD6b8bd85…`, same owner safe). It is a
  different product (MagicLP 1.0.0 pools, empty). **Not counted / not conflated** with PurrSwap.

## Caveats
- `KEI` has no DefiLlama price; for pool1 we used a deliberately generous $1/KEI upper bound — the
  result is still < $1e-12.
- Fork tests were run against the keyless public HyperEVM RPC
  (`https://rpc.hyperliquid.xyz/evm`); state is a snapshot of block 49,292,001.
- Values are dust-level; USD figures move only with HYPE price and are rounded.
