# Tooling notes — what worked, what failed (exact)

## Worked
1. **Initia Move REST API exposes compiled bytecode.**
   `GET https://rest.initia.xyz/initia/move/v1/accounts/<addr>/modules/<name>` returns
   `{address, module_name, abi, raw_bytes, upgrade_policy}` where **`raw_bytes` is the full
   compiled Move module (base64)**. This is the key enabler — no source verification service was
   needed. `GET .../accounts/<addr>/modules` lists all modules.
2. **aptos-cli disassembles Initia bytecode.**
   `aptos-cli 9.6.0` → `aptos move disassemble --bytecode-path cabal.mv --output-dir dis` emitted
   a complete `.masm` (111 KB) with function bodies, structs and calls. The Initia Move binary
   format is compatible with the aptos disassembler at this version. Full output:
   `analysis/disasm-cabal.mv.masm`.
3. **Live view oracle.**
   `POST https://rest.initia.xyz/initia/move/v1/view/json` with
   `{"address","module_name","function_name","args","typeArgs"}`. Args are **JSON strings**;
   scalar `u64` args must be quoted (`"1"`), `Object<Metadata>` args double-quoted
   (`"\"0x…\""`) — same convention as the DefiLlama `projects/cabal` adapter.
4. **Deployed package discovery.** `projects/cabal/index.js` in DefiLlama-Adapters names
   `CABAL_MODULE_ADDRESS = 0x53c3f5d8…` (Initia mainnet) and the `strat-1`/`cabal-1` vault
   addresses. Cross-checked by calling `get_pools` / `get_real_total_stakes` on it.

## Failed / not available
1. **No Move source-verification service.** `scan.initia.xyz` returns a Next.js HTML shell (no
   public JSON API for module source); `explorer.initia.xyz` and `api.initia.xyz` do not resolve.
   The only machine-readable artifact is the bytecode (`raw_bytes`) — used here.
2. **No `initiad` / `move` toolchain installed locally**, and Initia's release binary does not
   ship a `move disassemble` subcommand; the aptos CLI was used instead (works).
3. **No `move-binary-format` / `move-disassembler` crates on crates.io** (crates.io returns
   nothing for those names) — avoided a long `move-language/move` cargo build by using the
   prebuilt aptos CLI.
4. **The audited `staking_addr` `0xe472ba1c…` is NOT deployed on mainnet** — `…/accounts/0xe472…/
   modules` returns `{"modules":[],"pagination":{"total":"0"}}`. The audited repo's named
   address is not the live package.
5. **No team response / mitigation review** for H-01 in the C4 report or in the sponsor's
   `0xCabal/cabal-audits` PDF mirror. The only way to settle mitigation was the on-chain
   bytecode, which is what this folder does.
6. **No live interaction was attempted** (read-only mandate): we cannot submit an actual
   `initiate_unstake`/`batch_undelegate_pending_lps` tx. The "deployed vs audited" conclusion is
   from bytecode + a permissionless view-function oracle, not from a signed tx.

## Note on the 41-unit discriminator
`get_estimate_unstake_amount(1, 1_000_000)` is `(unstaking_amount / (supply + pending)) ×
real_total_stakes`. With supply `2,726,911,250,625`, pending `63,778,039`, real
`4,737,924,767,617`, the deployed formula = `1,737,428` exactly and the audited formula
(`supply` only) = `1,737,469`. The live call returned `1,737,428`. The margin is small because
the current pending is only 63.78 LP, but the discriminator is an **exact integer** match/mismatch
(bigdecimal truncation is far below the integer unit here), so it is conclusive.
