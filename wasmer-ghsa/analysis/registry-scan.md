# Registry scan — GHSA-v2h8-j899-r676 (wasmer-compiler-singlepass 7.x)

Read 2026-11-03 UTC. All calls `curl -4 -A "Mozilla/5.0" -m 15` with
`--doh-url https://cloudflare-dns.com/dns-query` (the host resolver returned NXDOMAIN
intermittently; DoH results were used to distinguish "no such host" from "host down").
No keys, no transactions.

Source of truth: `GET /cosmos/base/tendermint/v1beta1/node_info` on the endpoint shown.
`wasmvm` = `build_deps` entry whose path contains `wasmvm`; `wasmer` from the parent's
verified `libwasmvm/Cargo.lock` mapping unless stated otherwise.

| chain | chain_id | endpoint | app | commit | wasmvm | wasmer | upload | instantiate | verdict |
|---|---|---|---|---|---|---|---|---|---|
| kujira | kaiyo-1 | — | — | — | — | — | — | — | UNREACHABLE |
| migaloo | migaloo-1 | — | — | — | — | — | — | — | UNREACHABLE |
| stargaze | stargaze-1 | — | — | — | — | — | — | — | UNREACHABLE |
| comdex | comdex-1 | — | — | — | — | — | — | — | UNREACHABLE |
| archway | archway-1 | https://rest.cosmos.directory/archway | v10.1.1-tachyon-security-patch | bdeda3102ea7 | v1.5.5 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| desmos | desmos-mainnet | https://rest.cosmos.directory/desmos | 7.1.0 | 00b333c1e4fe | v1.5.2 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| jackal | jackal-1 | https://rest.cosmos.directory/jackal | 5.1.0-3-g76c55bd6 | 76c55bd6f1aa | v1.2.6 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| shido | shido_9008-1 | https://rest.cosmos.directory/shido | 3.3.1 | c4f715eb5591 | v2.1.4 | not 7.x (4.x/5.x) | — | — | OUT-OF-RANGE |
| bitsong | bitsong-2b | https://rest.cosmos.directory/bitsong | 0.24.0 | 7207c486e4ff | v2.1.6 | not 7.x (4.x/5.x) | — | — | OUT-OF-RANGE |
| bitcanna | bitcanna-1 | https://rest.cosmos.directory/bitcanna | v4.0.4 | bc886c0a50c8 | v2.1.4 | not 7.x (4.x/5.x) | — | — | OUT-OF-RANGE |
| aura | aura_6322-2 | https://rest.cosmos.directory/aura | v0.9.3 | ae45a4ef71da | v1.4.0 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| axelar | axelar-dojo-1 | https://rest.cosmos.directory/axelar | 1.5.5 | 034c47b29415 | v2.3.4 | 4.3.7 (tag-verified) | — | — | OUT-OF-RANGE |
| sentinel | sentinelhub-2 | https://rest.cosmos.directory/sentinel | 12.0.2 | 8bf61c4bead2 | v1.5.8 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| akash | akashnet-2 | https://rest.cosmos.directory/akash | 2.1.0 | 151b989a58f5 | v3.0.2 | 4.3.x/5.0.6 | — | — | OUT-OF-RANGE |
| stride | stride-1 | https://rest.cosmos.directory/stride | v35.0.0 | 5b7fbe92b687 | v3.0.6 | 4.3.x/5.0.6 | — | — | OUT-OF-RANGE |
| fetchhub | fetchhub-4 | https://rest.cosmos.directory/fetchhub | v0.15.1-0-gae12a4f | ae12a4fc8886 | v3.0.8-rc.3 | **UNVERIFIED** | Everybody | Everybody | **AFFECTED-PERMISSIONLESS** |
| kiichain | kiichain_1783-1 | https://rest.cosmos.directory/kiichain | v8.0.2 | f7a20a4ced58 | v3.0.8 | 7.4.2 | Nobody | Nobody | **AFFECTED-RESTRICTED** |
| qorechain | qorechain-vladi | https://rest.cosmos.directory/qorechain | `""` | `""` | v2.3.5 | 7.4.2 | Nobody | Nobody | **AFFECTED-RESTRICTED** |
| zigchain | zigchain-1 | https://rest.cosmos.directory/zigchain | v6.0.0 | 81af3b281338 | v2.3.5 | 7.4.2 | AnyOfAddresses (15) | Everybody | **AFFECTED-RESTRICTED** |
| andromeda | andromeda-1 | https://andromeda.api.liveraven.net | 2.0.0 | d4a545873e26 | v2.1.3 | not 7.x (4.x/5.x) | — | — | OUT-OF-RANGE |
| emoney | emoney-3 | — | — | — | — | — | — | — | UNREACHABLE |
| assetmantle | mantle-1 | https://mantle-lcd.dungeon.games | 1.0.1 | 6d3824b | none | n/a | — | — | NOT-WASM |
| crescent | crescent-1 | — | — | — | — | — | — | — | UNREACHABLE |
| omniflix | omniflixhub-1 | — | — | — | — | — | — | — | UNREACHABLE |
| passage | passage-2 | https://rest.cosmos.directory/passage | 4.0.3 | eea1f3e416c7 | v1.5.0 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| nois | nois-1 | — | — | — | — | — | — | — | UNREACHABLE |
| empower | empowerchain-1 | https://rest.cosmos.directory/empowerchain | v2.0.0-pebbledb | 70ad47fc878d | v1.5.0 | not 7.x (2.x/4.x) | — | — | OUT-OF-RANGE |
| lava | lava-mainnet-1 | https://rest.cosmos.directory/lava | 6.2.4 | e293c30dbd5f | none | n/a | — | — | NOT-WASM |
| nibiru | cataclysm-1 | https://rest.cosmos.directory/nibiru | 2.21.0 | 18d74f6ea2e8 | none in build_deps (local replace) | **7.4.2** | Everybody | Everybody | **AFFECTED-PERMISSIONLESS** |
| sei | pacific-1 | https://rest.cosmos.directory/sei | v6.7.2 | 02df238d64de | none | n/a | — | — | NOT-WASM |
| mantra | mantra-1 | https://rest.cosmos.directory/mantrachain | v8.7.0-pre.1 | d5dfc27c | v3.0.8-rc.3 | **UNVERIFIED** | AnyOfAddresses (4) | Everybody | **AFFECTED-RESTRICTED** |
| quicksilver | quicksilver-2 | — | — | — | — | — | — | — | UNREACHABLE |

`nibiru` detail: `go.mod` replaces `github.com/CosmWasm/wasmvm => ./lib/wasmvm`; that tree has
`libwasmvm/Cargo.lock` with `cosmwasm-vm 1.6.1` + `wasmer-compiler-singlepass 7.4.2`, and
`lib/wasmer/lib/compiler-singlepass/src/codegen.rs` is byte-identical to vulnerable v7.4.2
(md5 `d0b168fd67bcb0e2f651ea08e259981b`, no `emit_if_block_end`). `wasm_backend/engine.rs` uses
`Singlepass` when the `cranelift` feature is off (default). Not visible in `build_deps` because
of the local replace.

## Affected / permissionless (new)

- **fetchhub-4** — Everybody/Everybody. Caveat: `v3.0.8-rc.3` is not a public wasmvm tag; fetchd
  `v0.15.1` replaces it with `github.com/fetchai/priv_wasmvm_sec/v3 v3.0.8-rc.3` (private), so the
  wasmer pin cannot be read. In scope by lineage (3.0.8 line), wasmer unverified.
- **cataclysm-1 (Nibiru)** — Everybody/Everybody, wasmer 7.4.2 verified as above. New: was not in
  the parent's baseline and was invisible to `build_deps`.

## Affected / restricted

- **kiichain_1783-1** — Nobody/Nobody (upload closed).
- **qorechain-vladi** — Nobody/Nobody (upload closed).
- **zigchain-1** — AnyOfAddresses (15) / Everybody.
- **mantra-1** — AnyOfAddresses (4) / Everybody. Same `v3.0.8-rc.3` unverified-wasmer caveat.

`codes/params` returned HTTP 200 for all five; `/cosmwasm/wasm/v1/codes` returned 501 on this
public proxy for every chain, so code counts were not obtainable (not interpreted as "not wired").

## Changes vs prior 2026-10-28 enumeration

Baseline was 16 parent-verified chains plus 4 under parallel check; none of those were re-tested
here, so no baseline row changed. This scan adds **6 affected chains**: fetchhub, kiichain,
qorechain, zigchain, mantra (restricted/permissionless as above) and **nibiru (permissionless)**.
Everything else newly scanned is OUT-OF-RANGE (`wasmvm` ≤ v3.0.7 / ≤ v2.3.4 / v1.x) or NOT-WASM.

## UNREACHABLE (no node_info obtainable)

| chain | chain_id | why |
|---|---|---|
| kujira | kaiyo-1 | 15/15 chain-registry REST hosts dead/NXDOMAIN (setten.io parked, polkachu NXDOMAIN, kjnodes/ibs TLS "unrecognized name"); `rest.cosmos.directory/kujira` 502 ×3; `kujira-rest.publicnode.com` 404 |
| migaloo | migaloo-1 | 3/3 registry hosts dead (polkachu NXDOMAIN, kleomedes 525); proxy 502 ×3; publicnode 404 |
| stargaze | stargaze-1 | 19/19 registry hosts dead (rest.stargaze-apis.com no A, d-stake.xyz parked domain, others NXDOMAIN/timeout); proxy 404 ×3; publicnode 404 |
| comdex | comdex-1 | 13/13 registry hosts dead (all NXDOMAIN or 502/503); proxy 404 ×3; publicnode 404 |
| emoney | emoney-3 | only 2 registry hosts, both NXDOMAIN; proxy 404 ×3 |
| crescent | crescent-1 | 8/8 registry hosts dead (NXDOMAIN/503); proxy 502 ×3 |
| omniflix | omniflixhub-1 | 13/13 registry hosts dead; official `api.omniflix.*` NXDOMAIN; proxy 404 ×3; publicnode 404 |
| quicksilver | quicksilver-2 | 14/14 registry hosts dead; `api.quicksilver.zone` NXDOMAIN; proxy 502 ×3; publicnode 404 |
| nois | nois-1 | 12/12 registry hosts dead (d-stake.xyz parked domain); proxy 404 ×3 |

These are endpoint-level failures, not proof the chains are halted; no public LCD/REST answered
from this vantage point, so no version claim is made.
