# Contract sources (verbatim)

`*.cdc` in this directory are **byte-identical copies of the code deployed on Flow mainnet**
(dumped from chain by the parent analysis, see `../../analysis/*.cdc`).

`deps/*.cdc` are **byte-identical copies of the code actually deployed on Flow mainnet** at
the standard addresses, fetched read-only from the public Flow REST API
(`https://rest-mainnet.onflow.org/v1/accounts/...?expand=contracts`):

| file | mainnet address |
|---|---|
| `deps/ViewResolver.cdc` | `0x1d7e57aa55817448` |
| `deps/NonFungibleToken.cdc` | `0x1d7e57aa55817448` |
| `deps/MetadataViews.cdc` | `0x1d7e57aa55817448` |
| `deps/Burner.cdc` | `0xf233dcee88fe0abe` |
| `deps/FungibleToken.cdc` | `0xf233dcee88fe0abe` |
| `deps/FungibleTokenMetadataViews.cdc` | `0xf233dcee88fe0abe` |

Because the emulator rejects mainnet addresses (its address space is chain-scoped), the
sources are *not* modified on disk. Instead `run.sh` copies them to `.runtime/` and rewrites
**only the import address literals**:

| mainnet address | local (emulator) address |
|---|---|
| `0xf233dcee88fe0abe` (FungibleToken, FungibleTokenMetadataViews, Burner) | address of runtime account `dep-ft` |
| `0x1d7e57aa55817448` (NonFungibleToken, MetadataViews, ViewResolver) | address of runtime account `dep-nft` |
| `0x0f9df91c9121c460` (BloctoToken, BloctoTokenStaking, BloctoPass, BloctoPassStamp) | address of runtime account `blocto` |
| `0x5555555555555555` (placeholder, transactions/scripts only) | address of runtime account `user` |

No other character of any contract is changed. Addresses are non-load-bearing for the three
gates under test (they are all about *which account* holds a resource/capability vs *which
account* invokes it, and that structure is preserved: BloctoTokenStaking + BloctoPass share
one account, exactly like mainnet).

`BloctoTokenSale.cdc` is deliberately **excluded**: it is pre-1.0 Cadence syntax that no
longer compiles and is not needed for these gates.
