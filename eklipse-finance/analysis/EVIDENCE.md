# Evidence index — Eklipse Finance (Kaia) L2 Phase-2

All reads are `eth_call` / `eth_getCode` / `eth_getLogs` against keyless public Kaia RPCs
(`public-en.node.kaia.io`, `rpc.ankr.com/kaia`, `kaia.drpc.org`, `klaytn.drpc.org`) or the
keyed dRPC endpoint constructed at runtime from `$DRPC_API_KEY` (never written to disk).
No transaction was ever signed or sent to a real network.

## Key blocks

| Purpose | Block |
|---|---|
| Triage (Triage-B row 22) | 229,512,567 |
| First deep re-verification | 229,747,709 |
| Fork PoC (local, 5/5 PASS) | 229,753,258 |
| Final state snapshot | 229,754,867 |
| 7-day history check | 229,151,231 → 229,756,031 |

## Core addresses

| Contract | Address |
|---|---|
| Base pool (KDAI/oUSDT/oUSDC) | `0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4` |
| Meta pool (baseLP/pUSD) | `0xe59234EeDC854b3b37D48EFd8a529069C3990F83` |
| Base LP (EKLP) | `0xd83b9dFa49D6C6d2A69554576e712E45A8A13E49` |
| Meta LP | `0x63C7d72963ED6e0C255835B606BEF55EBEB1b5f8` |
| pUSD | `0x168439b5eebe8c83db9eef44a0d76c6f54767ae4` |
| KDAI / oUSDT / oUSDC | `0x5c74070fdea071359b86082bd9f9b3deaafbe32b` / `0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167` / `0x754288077d0ff82af7a5317c7cb8c444d421d103` |
| EKL / staking / pool2 | `0x807C4E063eb0aC21E8EeF7623A6ed50A8EDe58cA` / `0xD067C3b871ee9E07BA4205A8F96c182baBBA6c58` / `0x625Ae9043E8730c4A1E30B36838502fb90e1D3C2` |
| Pool owner (base/meta/p6–p9) | EOA `0x024dfd23bf033d3ae3e9a1e41244ffcb6f6671ea` (0 bytes code) |
| Pool owner (p3–p5) | EOA `0xfd914b8463a2d22dd654da360c56913f31b3936e` (0 bytes code) |

## Key numeric evidence

* Meta pool reserves (all blocks sampled 7 days apart→now): **baseLP 9.131925 / pUSD 10,403.963278**.
* `meta.getTokenPrecisionMultipliers()` = `[base_pool.getVirtualPrice() = 1.041312951e18, 1e18]` → LP priced at par.
* Base LP real value = base pool $29,604.79 ÷ 285,741.485 LP = **$0.10361**.
* `meta.calculateSwap(0,1,1e18)` = **222.4316 pUSD** for 1 LP (block 229,754,543).
* Exact Saddle invariant (A=200, D = meta_vp × metaLP_supply) reproduces on-chain quotes with **fee = 0.06 %** (implied fee = 0.0006000 constant).
* Base pool: A=2000, vp=1.041312954, tokens [KDAI 268,996.599, oUSDT 30,401.011, oUSDC 1,661.047].
* Base-pool swap quotes (market-efficient): 1,000 KDAI → 908.94 oUSDT ($96.35 in / $95.52 out).
* Base-pool LP round trip (loss): 1,000 KDAI → 928.58 LP → 999.74 KDAI / 904.30 oUSDT / 284.67 oUSDC.
* Admin balances: base pool 828.213 KDAI + 1,043.829 oUSDT + 78.317 oUSDC = $212.70; meta = 0.
* pUSD: `paused()==false`, no blacklist/freeze functions (all revert), supply 1,663,773, DL price $1.00025.

## Files

| File | Content |
|---|---|
| `analysis/final_state.json` | Full pool/token/balance snapshot at block 229,754,867 with USD |
| `analysis/pool_state.json` | Per-pool A, vp, tokens, balances, precision multipliers, admin balances |
| `analysis/lp_state.json` | LP token supplies and pool holdings |
| `analysis/llama_protocol.json` | DefiLlama protocol payload (tokens in USD, history) |
| `analysis/*_bytecode.hex` | Runtime bytecode of base pool, meta pool, base LP, pUSD, Klayswap factory |
| `analysis/sel_vyper.py`, `analysis/sel_extract.py` | Dispatcher-selector extractors used for ABI identification |
| `analysis/saddle_math.py`, `analysis/econ.py`, `analysis/pnl.py`, `analysis/quantify.py` | Invariant model + P&L quantification |
| `analysis/final_snapshot.py`, `analysis/dump_pools2.py`, `analysis/dump_lps.py` | State dump scripts |
| `analysis/kaia_rpc.py`, `analysis/rpc2.py` | Keyless Kaia RPC helpers |
| `poc/src/Eklipse.sol` | Interfaces + `EklipseAttacker` |
| `poc/test/Eklipse.t.sol` | 5 fork tests (exploit ×3, snapshot, negative control) |
| `ci/run.sh` | Heavy job: RPC probe (by-hash), test run, results to `ci-out/` |
| `ci/gitlab-eklipse-finance.yml` | GitLab fallback pipeline (Debian + foundryup) |
