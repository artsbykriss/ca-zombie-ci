# CosmWasm chain exposure — wasmer `wasmer-compiler-singlepass` 7.x (GHSA-v2h8-j899-r676)

Date: 2026-11-03. Read-only spot-check; public keyless HTTP GET only. All calls `curl -4 -A "Mozilla/5.0" -m 20-30` (host IPv6 is broken).

Advisory scope used: `>=7.0.0-alpha.1, <=7.4.2`, plus requester's code check that `7.5.0` still contains the vulnerable code. `wasmvm`→`wasmer` mapping taken from `CosmWasm/wasmvm` `libwasmvm/Cargo.lock` (re-verified below): v2.2.9 → 7.4.2; v2.3.5 → 7.4.2; v3.0.8 → 7.4.2 (cosmwasm-vm 3.0.10 `Cargo.toml` pins `wasmer = "=7.4.2"`, features `["singlepass"]`). Boundary re-checked: v2.2.8 / v2.3.4 → 4.3.7; v3.0.7 → 5.0.6 (out of range).

**Key route correction:** wasmd ≥0.54 registers list-codes at `GET /cosmwasm/wasm/v1/code` (singular). `GET /cosmwasm/wasm/v1/codes` is unregistered and returns the gRPC-gateway default **501**; the same 501 is returned for `/foo/bar`. A 501 on `/codes` is **not** evidence that the wasm module is absent. Exact code counts were obtained by paging `/cosmwasm/wasm/v1/code?pagination.limit=100` because `pagination.count_total=true` returns HTTP 400 `{"code":3,"message":"offset and count queries not supported"}` on every wasmd build tested.

## Table

| Chain | chain_id | Working endpoint | App version | Commit (12) | wasmvm | wasmer (mapped) | wasm wired? | upload | instantiate | code count | contract count | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Cosmos Hub | cosmoshub-4 | https://rest.lavenderfive.com/cosmoshub | gaia v29.0.1 | 48c981b31981 | v2.3.5 | 7.4.2 | yes | Everybody | Everybody | 820 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| Neutron | neutron-1 | https://rest.lavenderfive.com/neutron | neutron 11.3.0 | a3d76eb603b7 | v3.0.8-rc.3² (also v3.0.8²) | 7.x (rc)² / 7.4.2 | yes | Everybody | Everybody | 5412 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| Coreum | coreum-mainnet-1 | https://rest-01.mainnet-1.tx.org | tx-chain v8.0.0 | 5575eea6670b | v2.3.5 | 7.4.2 | yes | Everybody | Everybody | 692 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| Chihuahua | chihuahua-1 | https://api.chihuahua.wtf | chihuahua v10.0.1 | 4b69726b2f89 | v3.0.8 | 7.4.2 | yes | Everybody | Everybody | 703 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| Dungeon | dungeon-1 | https://api.dungeongames.io | dungeonchain 13.1.2-rc.1 | 5cc284f5010c | v3.0.8 | 7.4.2 | yes | Everybody³ | Everybody | 228 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| Firmachain | colosseum-1 | https://rest.lavenderfive.com/firmachain | FirmaChain v0.5.2 | be4109c5f4fd / 5659706dbad5 | v2.2.9-rc.3² / v2.2.9 | 7.x (rc)² / 7.4.2 | yes | Everybody | Everybody | 4 | 25⁴ | **AFFECTED-PERMISSIONLESS** |
| Terra 2 | phoenix-1 | https://terra-rest.publicnode.com | terra v2.22.0 | e68dd029990a | v2.2.9 | 7.4.2 | yes | Everybody | Everybody | 4074 | n/a¹ | **AFFECTED-PERMISSIONLESS** |
| THORChain | thorchain-1 | https://api-thorchain.rorcual.xyz | THORChain 3.21.0 | 31bc1ae34ee6 | v2.2.9 | 7.4.2 | yes | Everybody | Everybody | 204 | n/a¹ | **AFFECTED-PERMISSIONLESS** |

¹ wasmd exposes no global contract-list RPC: `GET /cosmwasm/wasm/v1/contract?pagination.limit=1&pagination.count_total=true` → 501 on all eight; `/cosmwasm/wasm/v1/contracts` → 405. Contract count not obtained.
² Neutron and Firmachain have heterogeneous public nodes — see per-chain evidence. `v3.0.8-rc.3` / `v2.2.9-rc.3` are pre-releases of the 7.4.2 releases; their exact wasmer pin could not be resolved from public artifacts on this host, so mapped as "7.x (rc), unverified".
³ `code_upload_access = {"permission":"Everybody","addresses":[3 dungeon1... addresses]}`. Not `AnyOfAddresses`: wasmd `AccessConfig.Allowed` returns `true` unconditionally for `AccessTypeEverybody` (wasmd v0.70.4 `x/wasm/types/params.go` L138-148), so the address list is inert.
⁴ Firmachain: sum of `GET /cosmwasm/wasm/v1/code/{1..4}/contracts` = 8+6+6+5 = 25.

All eight chains were reached; no chain is `UNREACHABLE`. No chain is `OUT-OF-RANGE` or `NOT-WASM-WIRED`.

## Per-chain evidence

### Cosmos Hub (cosmoshub-4)
- `GET https://rest.lavenderfive.com/cosmoshub/cosmos/base/tendermint/v1beta1/node_info` → **200**. `default_node_info.network="cosmoshub-4"`; `application_version.name="gaia"`, `.version="v29.0.1"`, `.git_commit="48c981b3198164a3d5ba5632ed631fcc3e9eeb09"`, `.go_version="go version go1.26.10 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.60.9`, `github.com/CosmWasm/wasmvm/v2 v2.3.5`, `github.com/cosmos/ibc-go/modules/light-clients/08-wasm/v10 v10.5.0`.
- Cross-check: `GET https://rest.cosmos.directory/cosmoshub/cosmos/base/tendermint/v1beta1/node_info` → 200, identical fields in **15/15** samples.
- `GET https://rest.lavenderfive.com/cosmoshub/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/cosmoshub/cosmwasm/wasm/v1/code/1` → **200**; `code_info.code_id="1"`, `creator="cosmos1559zgk3mxm00qtr0zu2x5n4rh5vw704qaqj6ap"`, `data` prefix `AGFzbQEAAAAB` (wasm magic `\0asm`). `.../code/820` → 200 (`creator="cosmos1s8qx0zvz8yd6e4x0mqmqf7fr9vvfn6226hkvrq"`).
- Count: paged `GET https://rest.cosmos.directory/cosmoshub/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 9 pages, **820** unique ids, contiguous 1..820.
- Source confirmation: gaia `v29.0.1` `app/app.go` L67-69 imports `github.com/CosmWasm/wasmd/x/wasm` + `wasmkeeper`; `app/keepers/keepers.go` L466 constructs `wasmkeeper.NewKeeper`; `app.go` L326 registers `wasmkeeper.NewWasmSnapshotter(app.CommitMultiStore(), &app.WasmKeeper)`.
- The old-path 501: `GET https://rest.cosmos.directory/cosmoshub/cosmwasm/wasm/v1/codes` → 501 `{"code":12,"message":"Not Implemented","details":[]}`. Control `GET https://rest.cosmos.directory/neutron/foo/bar` → 501 same body.

### Neutron (neutron-1)
- `GET https://rest.lavenderfive.com/neutron/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="neutron-1"`; `application_version.name="neutron"`, `.version="11.3.0"`, `.git_commit="a3d76eb603b71314c57f84eb62da72b3d0892730"`, `.go_version="go version go1.24.10 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.61.0`, `github.com/CosmWasm/wasmvm/v3 v3.0.8-rc.3`.
- Heterogeneous nodes, `GET https://rest.cosmos.directory/neutron/cosmos/base/tendermint/v1beta1/node_info` sampled 15 times (11 valid JSON): **3x** `version="11.3.0"`, commit `b83729aa9887…`, `wasmvm/v3 v3.0.8`; **8x** `version="11.3.0-21-gf1d5578d"`, commit `f1d5578d8b3c…`, `wasmvm/v3 v3.0.8-rc.3`; 4 non-JSON responses.
- `GET https://rest.lavenderfive.com/neutron/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/neutron/cosmwasm/wasm/v1/code/1` → **200**; `code_info.code_id="1"`, `creator="neutron1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqhufaa6"`, `data` prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/neutron/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 55 pages, **5412** unique ids, contiguous 1..5412.
- Mapping: wasmvm `v3.0.8` `libwasmvm/Cargo.lock` → `wasmer-compiler-singlepass 7.4.2`; cosmwasm-vm `3.0.10` `Cargo.toml`: `wasmer = { version = "=7.4.2", default-features = false, features = ["singlepass"] }`. `v3.0.8-rc.3` pin not publicly resolvable here.

### Coreum (coreum-mainnet-1)
- `GET https://rest-01.mainnet-1.tx.org/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="coreum-mainnet-1"`; `application_version.name="tx-chain"`, `.version="v8.0.0"`, `.git_commit="5575eea6670b80261ab9168dc7ea0339bba0da34"`, `.go_version="go version go1.24.6 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.60.9`, `github.com/CosmWasm/wasmvm/v2 v2.3.5`, `.../08-wasm/v10 v10.1.1`.
- `GET https://rest-01.mainnet-1.tx.org/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/coreum/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="core195ply22yw08edsk5342ajhz6gn6rn5s5667yu6"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/coreum/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 7 pages, **692** unique ids, contiguous 1..692.
- Note: `https://coreum-rest.publicnode.com` serves node_info/params but returns publicnode JSON-RPC 501 for the legacy `/codes` path; not used.

### Chihuahua (chihuahua-1)
- `GET https://api.chihuahua.wtf/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="chihuahua-1"`; `application_version.name="chihuahua"`, `.version="v10.0.1"`, `.git_commit="4b69726b2f8929aed434d37bf3e641e7b4865e28"`, `.go_version="go version go1.26.5 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.70.4`, `github.com/CosmWasm/wasmvm/v3 v3.0.8`.
- `GET https://api.chihuahua.wtf/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/chihuahua/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="chihuahua1m65lc0svtjpgkyxpmmqacrphjv06clrjaeedfu"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/chihuahua/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 8 pages, **703** unique ids, contiguous 1..703.

### Dungeon (dungeon-1)
- `GET https://api.dungeongames.io/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="dungeon-1"`; `application_version.name="dungeonchain"`, `.version="13.1.2-rc.1"`, `.git_commit="5cc284f5010c75e3c2cd0a5b3bbcfd788505d2c8"`, `.go_version="go version go1.26.5 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.70.4`, `github.com/CosmWasm/wasmvm/v3 v3.0.8`.
- `GET https://api.dungeongames.io/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":["dungeon1wxn8sqnv4kea7mglqa9jmae50d7zdx7vujhllt","dungeon1f6s4550dzyu0yzp7q2acn47mp5u25k0xhfv9sc","dungeon13x4pynlp86prhcmtns742kgsgu7pjtzj72eycc"]},"instantiate_default_permission":"Everybody"}}`. Effective upload = `Everybody` (see footnote 3).
- Wired: `GET https://rest.cosmos.directory/dungeon/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="dungeon1wxn8sqnv4kea7mglqa9jmae50d7zdx7vujhllt"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/dungeon/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 3 pages, **228** unique ids, contiguous 1..228.

### Firmachain (colosseum-1)
- `GET https://rest.lavenderfive.com/firmachain/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="colosseum-1"`; `application_version.name="FirmaChain"`, `.version="v0.5.2"`, `.git_commit="be4109c5f4fd0b62b75a4d2e7806e739ed34ac99"`, `.go_version="go version go1.23.4 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.54.3`, `github.com/CosmWasm/wasmvm/v2 v2.2.9-rc.3`.
- Official tag build: `GET https://rest.cosmos.directory/firmachain/cosmos/base/tendermint/v1beta1/node_info` → 200 in 4/15 samples: `version="v0.5.2"`, commit `5659706dbad5…`, `wasmd v0.54.10`, `wasmvm/v2 v2.2.9`. `FirmaChain/firmachain` tag `v0.5.2` = commit `5659706dbad5644bb2e7de45a0afa5437667dff6`; its `go.mod` has `wasmd v0.54.10`, `wasmvm/v2 v2.2.9`. Second public LCD `GET https://api.firmachain.chaintools.tech/cosmos/base/tendermint/v1beta1/node_info` → 200, commit `be4109c5f4fd…`, `v2.2.9-rc.3`.
- `GET https://rest.lavenderfive.com/firmachain/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/firmachain/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="firma10q7mj8wpefqfmtjqsevg2m5sc93fyhcn528z45"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/firmachain/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 1 page, **4** ids (1..4).
- Contracts: `GET https://rest.lavenderfive.com/firmachain/cosmwasm/wasm/v1/code/{1,2,3,4}/contracts` → 200 each; 8+6+6+5 = **25**.

### Terra 2 (phoenix-1)
- `GET https://terra-rest.publicnode.com/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="phoenix-1"`; `application_version.name="terra"`, `.version="v2.22.0"`, `.git_commit="e68dd029990a4cf347157f2426cabba4d9eb5c30"`, `.go_version="go version go1.23.12 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.54.10`, `github.com/CosmWasm/wasmvm/v2 v2.2.9`.
- Cross-check: `GET https://rest.cosmos.directory/terra2/cosmos/base/tendermint/v1beta1/node_info` → 200, same commit `e68dd029990a`, `wasmvm v2.2.9`, `go1.23.6` (some proxy backends report `version="20210603"`, same commit/build_deps).
- `GET https://terra-rest.publicnode.com/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/terra2/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="terra1hzt9ywljcdg7urcud5nlcsh8trk72mqyj4g8e4"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/terra2/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 41 pages, **4074** unique ids, contiguous 1..4074.

### THORChain (thorchain-1)
- `GET https://api-thorchain.rorcual.xyz/cosmos/base/tendermint/v1beta1/node_info` → **200**. `network="thorchain-1"`; `application_version.name="THORChain"`, `.version="3.21.0"`, `.git_commit="31bc1ae34ee6486e8ae7a2aca4e2db5a0a6ca5a5"`, `.go_version="go version go1.26.9 linux/amd64"`; `build_deps`: `github.com/CosmWasm/wasmd v0.54.10`, `github.com/CosmWasm/wasmvm/v2 v2.2.9`.
- `GET https://api-thorchain.rorcual.xyz/cosmwasm/wasm/v1/codes/params` → **200**. Raw: `{"params":{"code_upload_access":{"permission":"Everybody","addresses":[]},"instantiate_default_permission":"Everybody"}}`.
- Wired: `GET https://rest.cosmos.directory/thorchain/cosmwasm/wasm/v1/code/1` → **200**; `code_id="1"`, `creator="thor1e0lmk5juawc46jwjwd0xfz587njej7ay5fh6cd"`, data prefix `AGFzbQEAAAAB`.
- Count: paged `GET https://rest.cosmos.directory/thorchain/cosmwasm/wasm/v1/code?pagination.limit=100` → 200, 3 pages, **204** unique ids, contiguous 1..204.
- Requested as `thorchain-mainnet-v1`; actual `node_info.network` is `thorchain-1`.

## Falsified / corrected

1. **Prior verified work — "Cosmos Hub's gaia has NO wasm keeper wiring; 501 on `/cosmwasm/wasm/v1/codes`" — FALSIFIED.** cosmoshub-4 runs gaia v29.0.1 with `wasmd v0.60.9` + `wasmvm v2.3.5`; the source imports/constructs the wasmd keeper (`app/app.go` L67-69, `app/keepers/keepers.go` L466); the chain serves `/cosmwasm/wasm/v1/codes/params` 200 with `Everybody`, `/cosmwasm/wasm/v1/code/1` 200 with a real wasm blob, and holds **820** contiguous codes. The 501 was the **wrong path**: wasmd (all versions tested: v0.54.10, v0.60.9, v0.61.0, v0.70.4) registers the code list at `/cosmwasm/wasm/v1/code`, not `/codes`; unknown paths also return 501. CA2's "Cosmos Hub is permissionless" is therefore **CONFIRMED**; the prior "no wiring" inference is wrong.
2. **CA2 — neutron v11.3.0 / wasmvm v3.0.8 permissionless:** partly confirmed. One public build is `11.3.0` (`b83729aa9887`) / `v3.0.8`; another is `11.3.0-21-gf1d5578d` (`f1d5578d8b3c`) / `v3.0.8-rc.3`. Both serve `Everybody/Everybody`. The `v3.0.8` build maps to wasmer 7.4.2.
3. **CA2 — firmachain v2.2.9 permissionless:** confirmed for the official `v0.5.2` tag build (`5659706dbad5`, wasmd v0.54.10, wasmvm v2.2.9, wasmer 7.4.2). Two public LCDs run a different build (`be4109c5f4fd`, wasmvm v2.2.9-rc.3, wasmd v0.54.3); same permission/wiring.
4. **CA2 — coreum v8.0.0 v2.3.5, dungeon v13.1.2-rc.1 v3.0.8, chihuahua v10.0.1 v3.0.8, terra2 v2.2.9, thorchain v2.2.9 permissionless:** all confirmed exactly (build_deps and `Everybody/Everybody`).
5. **Dungeon is not `AnyOfAddresses`:** params literally are `"permission":"Everybody"` with a 3-address array. wasmd's `Allowed()` returns true for `Everybody` before consulting addresses, so upload is permissionless.
6. **Chain ids:** Firmachain is `colosseum-1` (not `firmachain-mainnet-1`); THORChain is `thorchain-1` (not `thorchain-mainnet-v1`).

## Chains / endpoints not reached

No chain was unreachable: all eight returned `node_info` 200 from at least one public LCD. Endpoint-level failures (never treated as chain facts):

- **Cosmos Hub:** `https://cosmos-lcd.quickapi.com` → 403 (administrative rules); `https://cosmoshub.lava.build` → 404; `https://cosmoshub-rest.publicnode.com` → 000 (and 404 for `/code/820`).
- **Neutron:** `https://rest-lb.neutron.org` → 302 to `https://x.com/neutron_org/status/2072037746424603130` (domain no longer serves LCD); `https://neutron-rest.publicnode.com` → 404; `rest.neutron.solva.solutions`, `rest-solara/rest-voidara/rest-pulsarix.neutron-1.neutron.org`, `neutron-api.polkachu.com`, `api.novel.remedy.tm.p2p.org`, `lcd.neutron.bronbro.io`, `api.neutron.quokkastake.io`, `rest.neutron.org` → 000 (DNS/connect/timeout).
- **Chihuahua:** `https://chihuahua-rest.publicnode.com` → 404; `chihuahua-api.polkachu.com`, `api.chihuahua.validatus.com`, `chihuahua-api.kleomedes.network` → 000.
- **Dungeon:** `https://dungeon-rest.publicnode.com` → 000; `https://api.dungeon.chaintools.tech` → 000.
- **Firmachain:** `https://lcd-mainnet.firmachain.dev:1317` (https and http), `firma.api.m.stavr.tech`, `firmachain-api.polkachu.com`, `firmachain-api.ramuchi.tech`, `firmachain.api.nodeshub.online`, `firmachain_mainnet_api.chain.whenmoonwhenlambo.money` → 000.
- **Terra 2:** `https://phoenix-lcd.terra.dev` → 000 (timeout).
- **THORChain:** `https://thorchain-rest.publicnode.com` → 000; `https://gateway.liquify.com/chain/thorchain_api` → 200 for node_info/params but intermittent 000 for `/code/1`.
- **Coreum:** `https://coreum-rest.publicnode.com` is reachable but returns JSON-RPC `{"code":-32701,"message":"not implemented"}` for the legacy `/codes` path; `https://rest-01.mainnet-1.tx.org` used instead.

## Caveats

- Verdicts are based on the on-chain `code_upload_access` / `instantiate_default_permission` params plus the presence of a 7.x `wasmer-compiler-singlepass` in the node build. No transaction, signing, upload, or exploit attempt was made.
- `v3.0.8-rc.3` and `v2.2.9-rc.3` could not be mapped to an exact wasmer version from public artifacts here; they are pre-releases of the vulnerable v3.0.8 / v2.2.9 releases. The Neutron/Firmachain verdicts also rest on the co-existing release builds (v3.0.8 / v2.2.9), which are 7.4.2.
- Exact code counts are from full paging (ids contiguous 1..N); `pagination.count_total` is unsupported by these wasmd builds.
- Contract totals are unavailable except Firmachain (25) because wasmd has no global contract-list endpoint (`/contract` 501, `/contracts` 405).
- Build versions are read from `application_version.build_deps`; we cannot detect an operator that rebuilds/patch-backs `libwasmvm` from a fork while reporting the stock Go module version. No such patch evidence was observed.
- Liveness spot-check: latest-block calls returned cosmoshub height 33708334 (2026-11-03T13:07:38Z), neutron 62117764 (13:07:34Z), chihuahua 26035083 (13:07:38Z), firmachain 25903342 (13:07:41Z); other endpoints were intermittently rate-limited (HTTP 000) on the block call after the evidence queries above.
