# USDT0 LayerZero OFT adapter — deep read (finding P7-04)

- **Date:** 2026-10-25
- **Chain:** Ethereum mainnet (chain id 1)
- **Status:** read-only; **no mainnet tx signed or sent** (only `eth_call` / `eth_getCode` / `eth_getStorageAt` / `eth_getLogs`).
- **Snapshot block:** `26271799`
- **Target:** TransparentUpgradeableProxy `0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee` → impl `0xcd979b10a55fcdac23ec785ce3066c6ef8a479a4` (`OAdapterUpgradeable`, USDT0 lock/unlock OFT adapter).

## TL;DR

**Total live extractable now (E-U): $0.00.** All **21** live inbound LayerZero routes are **3-of-3 required DVN**. The four weak **1-of-1** configs (`0x747C7414…` on eids 30165/30214/30375, and the `0x…dEaD` DVN on 30243) have **no peer set** and are therefore inert. A forged `lzReceive` reverts `OnlyEndpoint`; even the real endpoint reverts `NoPeer(30165)` for the dormant routes. **Trigger to watch:** a `PeerSet` event on eid 30165 / 30214 / 30375 / 30243 → that route becomes a 1-of-1-DVN inbound unlock path against the **~$3.20B** escrow.

## Live state

| Item | Value |
|---|---|
| Proxy | `0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee` |
| EIP-1967 impl slot | `0x…cd979b10a55fcdac23ec785ce3066c6ef8a479a4` ✔ matches |
| Admin slot | `0x4de7096b2131e84fd6b2042ad8cd9b4e43f728fc` |
| `owner()` | `0x4DFF9b5b0143E642a3F63a5bcf2d1C328e600bf8` |
| endpoint delegate (`endpoint.delegates(oapp)`) | `0x4DFF9b5b0143E642a3F63a5bcf2d1C328e600bf8` (same as owner) |
| `endpoint()` | `0x1a44076050125825900e736c501f859c50fE728c` |
| Initializable slot (`0xf0c57e16…c6a00`) | `1` → **initialize locked** |
| Native USDT `0xdAC17F958D2ee523a2206206994597C13D831ec7` `balanceOf(proxy)` | `3196899493942590` = **3,196,899,493.94 USDT** ≈ **$3.197B** |
| Token | native USDT (6 decimals) |

> Pass7 claimed 3,197,754,613 USDT; the live figure is now 3,196,899,494 (≈$0.86M lower, normal net outflow). Same address, same impl.

## Per-route peer + DVN table (block 26271799)

All live routes use receive library `0xc02Ab410f0734EFa3F14628780e6e695156024C2` (Ethereum ULN302) with the **same 3 required DVNs**: `0x3b0531eb02ab4ad72e7a531180beef9493a00dd2`, `0x589dedbd617e0cbcb916a9223f4d1300c294236b`, `0xf9d2c0915cac4c75b7ae359089333c8ac258e12c` — **0 optional DVNs**.

| eid | chain | peer set | required DVN | config |
|---|---|---|---|---|
| 30109 | Polygon | ✅ | **3-of-3** | 0 optional |
| 30110 | Arbitrum One | ✅ | **3-of-3** | 0 optional |
| 30111 | Optimism | ✅ | **3-of-3** | 0 optional |
| 30181 | Mantle | ✅ | **3-of-3** | 0 optional |
| 30212 | eid 30212 | ✅ | **3-of-3** | 0 optional |
| 30274 | eid 30274 | ✅ | **3-of-3** | 0 optional |
| 30280 | eid 30280 | ✅ | **3-of-3** | 0 optional |
| 30295 | eid 30295 | ✅ | **3-of-3** | 0 optional |
| 30316 | Zircuit | ✅ | **3-of-3** | 0 optional |
| 30320 | eid 30320 | ✅ | **3-of-3** | 0 optional |
| 30322 | eid 30322 | ✅ | **3-of-3** | 0 optional |
| 30333 | eid 30333 | ✅ | **3-of-3** | 0 optional |
| 30339 | eid 30339 | ✅ | **3-of-3** | 0 optional |
| 30362 | eid 30362 | ✅ | **3-of-3** | 0 optional |
| 30367 | eid 30367 | ✅ | **3-of-3** | 0 optional |
| 30383 | eid 30383 | ✅ | **3-of-3** | 0 optional |
| 30390 | eid 30390 | ✅ | **3-of-3** | 0 optional |
| 30396 | eid 30396 | ✅ | **3-of-3** | 0 optional |
| 30398 | eid 30398 | ✅ | **3-of-3** | 0 optional |
| 30410 | eid 30410 | ✅ | **3-of-3** | 0 optional |
| 30600 | eid 30600 | ✅ | **3-of-3** | 0 optional |
| **30165** | zkSync Era | ❌ no peer | **1-of-1** | `0x747c741496a507e4b404b50463e691a8d692f6ac` |
| **30214** | Scroll | ❌ no peer | **1-of-1** | `0x747c741496a507e4b404b50463e691a8d692f6ac` |
| **30375** | Katana | ❌ no peer | **1-of-1** | `0x747c741496a507e4b404b50463e691a8d692f6ac` |
| **30243** | eid 30243 | ❌ no peer | **1-of-1** | `0x000000000000000000000000000000000000dEaD` |

### Correction to pass7
Pass7 listed **8** live inbound routes. The on-chain `peers()` + full `PeerSet` log history show **21** live peers (eids 30212, 30274, 30280, 30295, 30320, 30333, 30362, 30367, 30383, 30396, 30398, 30410, 30600 were missed). The **verdict is unchanged** — every one of the 21 is 3-of-3. eid 30331 was set then cleared (peer = 0 at blocks 25200978 and 25489688) and is currently **no-peer**.

## Mechanism

`OAdapterUpgradeable` is the stock `@layerzerolabs/oft-evm-upgradeable` `OFTAdapterUpgradeable` (thin wrapper; verified source). `_debit` locks native USDT into the adapter (`safeTransferFrom`), `_credit` unlocks it (`safeTransfer`). Inbound messages reach `_credit` only through the public `lzReceive`, which is double-gated:

```solidity
if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);              // gate 1
if (_getPeerOrRevert(_origin.srcEid) != _origin.sender) revert OnlyPeer(...);      // gate 2
```

`allowInitializePath(origin)` returns `peers[origin.srcEid] == origin.sender`. `initialize()` is locked (init slot = 1; impl calls `_disableInitializers()` in its constructor).

## What an attacker can / cannot do

- **Cannot** call `lzReceive` directly — `eth_call` from `0x…dEaD` reverts `OnlyEndpoint(0x…dEaD)`.
- **Cannot** forge through the endpoint for a dormant eid — `eth_call` from the real endpoint with `srcEid=30165` reverts `NoPeer(30165)` (no peer). Same for 30214/30375/30243.
- **Cannot** forge on a live eid — gate 2 requires `origin.sender == peer`, and gate 1 requires the real endpoint, so a message must be delivered by the endpoint, which requires the route's DVN quorum. Every live route is **3-of-3** (three independent DVNs must attest), so a single compromised DVN key is insufficient.
- **Would** be able to drain the escrow if a `PeerSet` were executed for eid 30165/30214/30375/30243 (or the eid-30243 config were re-pointed): that route is configured **1-of-1**, so one DVN attestation would satisfy the quorum, and the peer is attacker-settable only by the owner/delegate `0x4DFF9b5b…` (privileged). This is a **latent H-O** surface, not a live E-U.

## Verdict + trigger

- **E-U: $0.00 — HIGH confidence.** No unprivileged path to the ~$3.2B escrow; all live routes are 3-of-3.
- **Trigger (MONITOR):** `PeerSet(uint32,bytes32)` on the proxy with `eid ∈ {30165, 30214, 30375, 30243}` — emits topic `0x238399d427b947898edb290f5ff0f9109849b1c3ba196a42e35f00c50a54b98b`. Also monitor `setDelegate` / `setConfig` and admin-slot changes (`0x4de7096b…`).
- Last observed `PeerSet`: eid 30600 at block 25687266. Dormant eids 30165/30214/30375/30243 appear **nowhere** in the 25-event `PeerSet` history since deploy → they never had a peer.

## Methodology / caveats / files

- Endpoint: `0x1a44076050125825900e736c501f859c50fE728c`; ULN302 receive lib `0xc02Ab410f0734EFa3F14628780e6e695156024C2`; `getConfig` needs the **registered** lib address (passing the `0x…0002` placeholder reverts `LZ_OnlyRegisteredLib`).
- `getConfig(...)(bytes)` raw return carries a leading `0x20` word before the ULN tuple; `analysis/decode.py` drops it and ABI-decodes `(uint64,uint8,uint8,uint8,address[],address[])`.
- Reads via `ethereum-rpc.publicnode.com` (latest/state) and `eth.drpc.org`; log history via Etherscan V2 `eth_getLogs`.
- Chain names for eids 30212/30274/30280/30295/30320/30322/30333/30339/30362/30367/30383/30390/30396/30398/30410/30600 were not resolved (LayerZero metadata API returned 403); eids are shown verbatim.
- No secrets in this folder (public CI repo); RPCs are keyless public endpoints.
- **Foundry PoC** (`poc/`, forge-std vendored): 3/3 PASS on a live Ethereum fork — https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40232463980 · `test_01` escrow + init lock, `test_02` live routes carry the 3-DVN set & no weak DVN while the dormant routes carry only `0x747c7414…` (and 30243 only `0x…dEaD`) with `peers()==0`, `test_03` forged `lzReceive` from `0x…dEaD` reverts. Log `ci-log.txt`, artifact `ci-out/live_state.txt`.
- Files: `analysis/usdt0_reads.txt` (raw outputs + block numbers), `analysis/dvn_configs.json` (per-eid decoded config + peer), `analysis/decode.py`, `analysis/build_json.py`, `analysis/peers.sh`, `analysis/getcfg.sh`, `analysis/peerset_history.txt`, `analysis/snapshot.txt`, `analysis/src/` (verified impl source), `poc/test/Usdt0Oft.t.sol`, `ci/run.sh`, `summary.json`.
