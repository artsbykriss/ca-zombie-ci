# Cardboard Trade — oracle price path / exchange settle auth (subagent deep-dive)

Read-only. All evidence from `sbpf disassemble` of the dumped ELFs plus
`simulateTransaction` (`sigVerify=false`, `replaceRecentBlockhash=true`) against live mainnet
state. No transaction was signed or sent. Public RPC only.

## Question
Can an unprivileged attacker make the exchange settle a position at an attacker-chosen price
(→ drain the ~1.04M USDC vault `DSnqZ6ctTToaCMoCwULqdfkXGTTXfQ9oiv3qH98NR4hv`)?

## Verdict: **no E-U path** (confidence: high)

### How the price flows
The oracle push is top-level oracle tag **0x07** (instruction data `07 1f` = base58 `YS`).
For each market the oracle emits two inner CPIs to the exchange:

1. **exchange tag `0x1f`** — 35-byte payload
   `1f | u16 market_idx | u64 price | u64 price | u64 ts | u64 seq`.
   The settlement price is carried **directly in this instruction data**.
2. **exchange event `CTEVNT`** (discriminator `0x544e56455443`, 140 bytes).

So the security of the whole system reduces to two questions.

### (a) Can an unprivileged caller invoke exchange tag `0x1f`? — **No.**
`exchange.asm:18108` is the entrypoint; `exchange.asm:20572` is the 1-byte tag dispatch;
tag `0x1f` → `jmp_208d8` → `jmp_21290` (requires data_len `0x23`) → `jmp_21f90` (handler id `r6=4`)
→ `jmp_22dc8` → `fn_05d0`.

* `fn_05d0` (`exchange.asm:230`) compares a 32-byte program id against the **hardcoded oracle id**
  (lines 236-243) and exchange id (273-280), derives the PDA and requires return `0x1a`.
* A **direct top-level** call with the **exact** oracle-CPI account list `[20,41,3,8,42]` and the
  **exact** 35-byte payload returns `err=None` but logs
  `ORCLSKIP (0x50494b534c43524f), 0x1, 0x1f, 0x0, 0x3` and consumes only **1361 CU** (no settle).
  The oracle's own CPI of the identical instruction succeeds (exchange inner ≈ 4200 CU).
* Bypass probes all bail (`sim_gate_probe.py`): append the oracle program account / oracle PDAs /
  weights; prepend the oracle program account; **prepend a real oracle `0x071f` push as instruction 0
  then call exchange `0x1f` directly**; put the Instructions sysvar first. All `ORCLSKIP`, 470-1361 CU.

⇒ exchange `0x1f` is gated on the immediate caller being the **oracle program**. Unprivileged callers
cannot satisfy it. (The exact gate instruction was not fully isolated — the exchange imports
`sol_get_sysvar` and contains the Instructions-sysvar id at `exchange.asm:11218`, consistent with a
sysvar-based caller read; behaviour is decisive regardless.)

### (b) Can an unprivileged caller make the oracle compute a chosen price? — **No.**
* Oracle instruction data is only **2 bytes** — no price can be supplied.
* `fn_8480` (`oracle.asm:4733`, called per source group from `oracle.asm:5579`) validates each source:
  * group owner program id ∈ hardcoded table `data_03c8..data_0458` (`oracle.asm:13424-13429`), decoded to
    **BiSoNHVp…, TessVdML…, goonuddt…, ojh19oja…, AQU1FRd7…, ALPHAQmeA…** (`oracle.asm:4768-4797`), plus
    **dijkbkCA…, ojh19oja…, fastC7gqs…** (`oracle.asm:4950-5010`);
  * specific source **account keys** are hardcoded: `DmocjvFXp75…` (owner ojh, lines 4840-4866) and
    `8mZVRgrr…` (owner fast, lines 5032-5055).
  * any non-matching source is **skipped** with `ORCLSKIP` and the push continues.
* Swap matrix (`source_swap_summary.txt`): baseline = 0 ORCLSKIP; **every** source substitution
  (same-owner or wrong-owner) ⇒ ≥1 ORCLSKIP. ⇒ validated by **exact key + owner**.
* Source price accounts are written by **authorised updater signers**, not permissionlessly
  (dijk ← `FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f`, fast ← `AK9U2FvVU12TjCoaGAnuvzNfZkuny4NiQZEkUBVK1Swz`,
  BiSo ← `7RrqWam5ri2Yu6fUtiCp2dwqaydjJYMXz6HtCnQPGbDY`). A fake price cannot be injected into a source.

## Residual / caveats
* A permissionless push with **all** sources invalid still writes the feed (`CTFEED01`, 1338 B) and the
  weights (`CTWGHT02`, 191 B) and still settles, using the registry's **last-known** prices
  (`all_sources_invalid.txt`). This is a "stale-price refresh", bounded by the last valid price and the
  keeper's constant pushes — **not** an arbitrary-price primitive. Impact not quantified.
* The `oracle_learning.rs` deviation/TWAP logic and the exact 5-group aggregation were not fully reversed.
* No top-level (user) exchange instructions appear in 200 recent exchange signatures (all 571 invocations
  were inner `0x1f`/`CTEVNT` from the oracle), so deposit `0x05` / withdraw / margin auth was not exercised.

## Instruction tags
* oracle top-level: `0x07` (push, permissionless).
* exchange inner (from oracle): `0x1f` (settle), `0x43`/`CTEVNT` (event).
* exchange dispatch: 1-byte tags `0x00..0x2d` plus the `CTEVNT` event instruction (table in
  `../ci-out/oracle-re.json`).
