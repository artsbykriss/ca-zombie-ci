# Live chain exposure — GHSA-v2h8-j899-r676 (wasmer 7.x Singlepass)

Read-only public LCD/chain-registry GETs, 2026-11-03. No keys, no transactions. Version mapping is from
`CosmWasm/wasmvm/<tag>/libwasmvm/Cargo.lock` (see `advisory-verification.md` §3).

## Method note that changes previous conclusions

wasmd **≥ 0.54** registers the *list-codes* route at `/cosmwasm/wasm/v1/code` (**singular**). The plural
`/cosmwasm/wasm/v1/codes` is **not registered** and returns the gRPC-gateway default `501 Not Implemented`
— exactly like any unknown path. Public REST proxies (publicnode in particular) return a JSON-RPC
`-32701 not implemented` for paths they do not whitelist.

**Consequence:** the 501 we recorded in `ci/CROSS-CHAIN-FEASIBILITY.md` on `/codes` was **not** evidence
that the wasm module was absent, on Cosmos Hub or anywhere else. Using `/code` (and `/code/1`) confirms the
module is live everywhere below. This invalidates the earlier "Cosmos Hub is not a wasm target" conclusion.

## Affected and permissionless

`code_upload_access.permission = Everybody` **and** `instantiate_default_permission = Everybody`.
(`AnyOfAddresses` + a non-empty address list is allowlisted; `Everybody` ignores the list.)

| chain | chain_id | app | wasmvm | wasmer | codes | endpoint used |
|---|---|---|---|---|---|---|
| **Juno** | juno-1 | v31.0.0 | v3.0.8 | 7.4.2 | — | `rest.cosmos.directory/juno` (params), `juno-rest.publicnode.com` |
| **Cosmos Hub** | cosmoshub-4 | v29.0.1 | v2.3.5 | 7.4.2 | 820 | `rest.lavenderfive.com/cosmoshub` |
| **Neutron** | neutron-1 | 11.3.0 | v3.0.8 / v3.0.8-rc.3 | 7.4.2 | 5,412 | `rest.lavenderfive.com/neutron` |
| **Coreum** | coreum-mainnet-1 | v8.0.0 | v2.3.5 | 7.4.2 | 692 | `rest-01.mainnet-1.tx.org` |
| **Chihuahua** | chihuahua-1 | v10.0.1 | v3.0.8 | 7.4.2 | 703 | `api.chihuahua.wtf` |
| **Dungeon** | dungeon-1 | 13.1.2-rc.1 | v3.0.8 | 7.4.2 | 228 | `api.dungeongames.io` |
| **Firmachain** | colosseum-1 | v0.5.2 | v2.2.9 / v2.2.9-rc.3 | 7.4.2 | 4 | `rest.lavenderfive.com/firmachain` |
| **Terra 2** | phoenix-1 | v2.22.0 | v2.2.9 | 7.4.2 | 4,074 | `terra-rest.publicnode.com` |
| **THORChain** | thorchain-1 | 3.21.0 | v2.2.9 | 7.4.2 | 204 | `api-thorchain.rorcual.xyz` |

Neutron and Firmachain are **heterogeneous**: some public nodes report the released build (`v3.0.8`,
`v2.2.9` → wasmer 7.4.2), others a `-rc.3` build whose public `Cargo.lock` does not exist. The released
build is confirmed affected; the rc build is presumed 7.x (same release line) but not proven.

## Affected but not permissionless

| chain | chain_id | app | wasmvm | wasmer | upload | addresses |
|---|---|---|---|---|---|---|
| Osmosis | osmosis-1 | 32.0.0 | v2.2.9 | 7.4.2 | AnyOfAddresses | 53 |
| Provenance | pio-mainnet-1 | v1.31.0 | v3.0.8 | 7.4.2 | AnyOfAddresses | 4 |
| Nolus | pirin-1 | 0.8.6-patch | v3.0.8 | 7.4.2 | AnyOfAddresses | 2 |
| XPLA | dimension_37-1 | v1.14.1 | v2.3.5 | 7.4.2 | AnyOfAddresses | 1 |
| Babylon | bbn-1 | v4.6.0 | v2.3.5 | 7.4.2 | AnyOfAddresses | 1 |
| Nyx | nyx | 0.61.16 | v3.0.9 | 7.5.0 | AnyOfAddresses | 1 |
| Persistence | core-1 | v16.1.0 | v2.3.5 | 7.4.2 | AnyOfAddresses | — |
| Regen | regen-1 | v7.3.0 | v2.3.5-rc.3 | 7.x presumed | AnyOfAddresses | 1 |
| Injective | injective-1 | v1.20.4-bl.2 | v2.2.9-rc.2 | 7.x presumed | AnyOfAddresses | 1 |
| Xion | xion-mainnet-1 | v32.0.0 | v3.0.9 | 7.5.0 | Nobody | 0 |
| Terra Classic | columbus-5 | v4.1.1 | v3.0.8 | 7.4.2 | Nobody | 0 |

## Value proxies (DefiLlama `v2/chains`, 2026-11-03)

These are **exit-liquidity proxies**, not extractable amounts. A native mint is bounded by what can be
sold, not by chain state; for large assets (ATOM) the real depth is off-chain and far larger than chain TVL.

| chain | DeFi TVL | note |
|---|---|---|
| Cosmos Hub | $112,693 | ATOM market depth is off-chain/on Osmosis — this figure badly understates a mint's reach |
| Terra 2 | $2,922,281 | largest permissionless affected chain by TVL |
| Juno | $40,849 | matches the order of magnitude of the measured contract-held JUNO (~$90 k) |
| Dungeon | $75,682 | |
| Coreum / Neutron / Chihuahua / Firmachain / THORChain | unlisted / 0 / $15,572 / — / $30,571,183 | THORChain TVL is mostly its own protocol, not CosmWasm |

## What this means

The permissionless affected set is **nine chains** confirmed here (plus the registry scan's additions),
including **Cosmos Hub** and **Terra 2** — not the five listed in CA2 and not the "Juno only" reading of
the first advisory pass. Every one of them runs a build with the vulnerable lowering and exposes upload +
instantiate to any funded account.

It does **not** follow that value is extractable: the missing piece is still the controlled escape (§6 of
the README). But the exposure surface is much wider than previously reported, and there is **no released
fix** for any of these chains.
