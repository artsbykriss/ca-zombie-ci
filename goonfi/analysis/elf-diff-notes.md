# ELF / build-diff notes — GoonFi (Z3-H2)

## What we have (retrievable today, 2026-10-16)

| Artifact | Bytes | sha256 | Last deploy slot / date | Notes |
|---|---|---|---|---|
| `progdata_v2.elf` — GoonFi **v2 current** build | 292,384 | `a24aa13a0a9a4d7d1c8752cc9d9a566a5fae3bc20ba0ca3ba11368abd613e43c` | 453,915,006 / 2026-10-06 13:27 | source paths `programs/goonfi-v2/src/{instructions/whitelisted_key_registry,state/bloom,state/market_v2,state/whitelisted_key_registry,utils/helpers}.rs`; custom framework (`src/extension`, `src/de`, `src/logger`) |
| `progdata_v1.elf` — GoonFi **v1** (separate lineage) | 130,336 | `2ffef035202a3642c36251836cfa19ca15ce38b481ed214aa4f33fbf0ac9003c` | 389,267,056 / 2025-12-26 | source paths `program/src/{instructions/blacklist_trader,state/market,utils/helpers}.rs`; v1 program `goonERTd…` is dead on-chain (0 accounts, 0 activity) |
| `dijkbk.elf` — **oracle-relay** program | 512 | see `dijkbk.elf.sha256` | 404,369,628 / ~2026-02 | 30 SBF instructions; disassembled in `bpf_disasm.py` output below; copies 32 B of instruction data into the target account, gated on the signer |

## The March-28 incident build (NOT retrievable)

- The incident ran against the build deployed **2026-03-25 07:02 UTC (slot 408,715,553)**; the first post-incident upgrade was **2026-03-31 10:26 UTC (slot 410,071,314)**, followed by ~20 more upgrades (list in `upgrade-history-v2.json`).
- Public Solana RPCs expose only the *current* ProgramData bytes; no public service returns historical program bytecode. Upgrade buffers from March are closed. Therefore a byte-level diff **current vs Mar-28** cannot be produced from public data. This is stated honestly in the report.

## Behavioural diff (the evidence we DO have)

Executing the current ELF against cloned live state (LiteSVM, `poc/`) and against the incident's exact call shape:

- The **exact March call** (13-account layout, `tag=1 dir=1 amount_in=4,096,000,000`, 18- and 20-byte data forms) still executes — but pays **38.799742877 WSOL** at the live oracle price ($105.57/SOL) instead of the March 1,539.265798532 WSOL ($2.661/SOL).
- The current build **rejects every non-pool oracle** (`Custom(32)`), including byte-identical copies of the pool's own oracle placed at other addresses — i.e. an oracle-identity binding exists that the March build must not have had (or had mis-configured).
- The current build **rejects stale oracles** (`Custom(21)`), **zero prices** (`Custom(9)`) and **upward price deviations > ~1–5%** (`Custom(36)`), and **clamps trade size/capacity** (`Custom(36)`).
- The oracle accounts' writer is **signer-gated** (real 512-byte `dijkbk` ELF: keeper signer → write; attacker signer → `MissingRequiredSignature`).

## Upgrade timeline (v2 ProgramData `124gUYwjVnJQ4sJsFug9gHPzPLEtwCbAQC5LkbaDgx9s`)

41 deploy/upgrade transactions total (2025-12-11 → 2026-10-06). Around the incident:

```
2026-03-16 12:47  slot 406,796,896
2026-03-25 07:02  slot 408,715,553   ← build live during the Mar-28 incident
2026-03-28        slot 409,430,505   ← INCIDENT (GoonFi + BisonFi drained, tx 5A1YuYHf…MGV2)
2026-03-31 10:26  slot 410,071,314   ← first post-incident upgrade (+72h)
2026-04-10 … 2026-10-06              ← ~20 further upgrades
2026-10-06 13:27  slot 453,915,006   ← current build
```

Full list: `upgrade-history-v2.json` (and `upgrade-history-v1.json` for v1: last upgrade 2025-12-26).

## `dijkbk` oracle program disassembly (all 30 instructions)

```
0040: ldxdw r4, [r1+20744]          ; r4 = ix_data[24..32]
0048: ldxdw r2, [r1+10456]          ; r2 = target_account.data[24..32]
0050: jne32 r4, r2 -> 0x128         ; equal → early exit (no write)
0058: ldxh  r2, [r1+8]              ; account0 flags
0060: jne   r2, 0x1ff -> 0xd8       ; account0 must be signer (dup=0xff, signer=1)
0068: ldxdw r2, [r1+16]
0070: lddw  r3, 0x871ca02361dde1d6
0080: jsgt  r2, 0 -> 0xd8           ; error path
0088: ldxdw r0, [r1+24]
0090: add32 r0, 0xfea415c4
0098: ldxdw r2, [r1+32]
00a0: lddw  r3, 0x6b334f7c22c1165b
00b0: jsgt  r2, 0 -> 0xd8
00b8: ldxdw r2, [r1+40]
00c0: lddw  r3, 0x89d698c3…
00d0: jgt   r2, 0 -> 0xf0           ; write path
00d8: lddw  r0, 0x800000000         ; error return
00e8: exit
00f0: stdw  [r1+10456], r4          ; target.data[24..32] = ix_data[24..32]
00f8: ldxdw r2, [r1+20720]          ; ix_data[0..8]
0100: stdw  [r1+10432], r2          ; target.data[0..8]
0108: ldxdw r2, [r1+20728]
0110: stdw  [r1+10440], r2
0118: ldxdw r2, [r1+20736]
0120: stdw  [r1+10448], r2
0128: exit
```

The signer gate itself is enforced by the runtime for this program's data-writes (`MissingRequiredSignature` for non-keeper signers, reproduced in LiteSVM with the real ELF).
