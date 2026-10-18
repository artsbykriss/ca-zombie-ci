# DEEP on-chain programs

Source code of the three Solana programs behind [DEEP](https://deepliquidity.fun), a Solana
launchpad and DEX: **Launch → Bond → Graduate → DeepSwap**.

| Program | Mainnet program ID | What it does |
| --- | --- | --- |
| `deep-curve` | `7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA` | Bonding-curve launches: token creation, curve buys and sells, graduation into a DeepSwap pool with the LP burned, DEEP's fee vault and its splitter. |
| `deep-amm` (DeepSwap) | `HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP` | DeepSwap, DEEP's constant-product AMM: a fork of [raydium-cp-swap](https://github.com/raydium-io/raydium-cp-swap) with DEEP's fee model and keys. |
| `deep-rewards` | `4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2` | Holder Rewards: per-token distributors paid out by Merkle roots (a cumulative amount per wallet, with an on-chain review delay before a root is used), claimed by holders. |

The same IDs are used on devnet. The IDLs are in [`idl/`](idl/). The TypeScript client is
[`@deepliquidity/sdk`](https://www.npmjs.com/package/@deepliquidity/sdk)
([source](https://github.com/Deep-Liquidity/deep-sdk)).

## What is in this repository

This tree is the exact source the mainnet binaries were built from (release commit `03a5c75`
of DEEP's development repository), limited to what the build needs:

- `programs/`: the three programs, with their Rust tests;
- `Cargo.toml`, `Cargo.lock`, `Anchor.toml`: the Cargo workspace (Anchor 1.2.0);
- `.cargo/config.toml`: the **public** build-time keys of the mainnet release (below);
- `idl/`: the Anchor IDLs;
- `fixtures/`: the cross-language test vectors the Rust tests read (shared with the SDK).

### Build-time keys

`deep-amm` and `deep-curve` compile a few public keys in from the environment, so no instruction
can change them later. `.cargo/config.toml` sets them through Cargo's `[env]` table for every
build of this tree (the full list is in that file):

| Variable | Mainnet value | Role |
| --- | --- | --- |
| `DEEP_AMM_ADMIN` | `4vEQmhpGxVJNiLaYz16NVaYQqcp7GbZMwd5TR3cZtQqu` | DeepSwap admin: DEEP's Squads multisig vault |
| `DEEP_AMM_FEE_OWNER` | `4vEQmhpGxVJNiLaYz16NVaYQqcp7GbZMwd5TR3cZtQqu` | the same vault |
| `DEEP_FEE_VAULT` | `8a2XakVBzdMRJ6gMY6u8mvebzJGgbmG6nVBVPB8uwBVZ` | deep-curve PDA `["fee_vault"]`: receives all DEEP revenue |
| `DEEP_AMM_CREATE_POOL_FEE_RECEIVER` | `EcnANJ5kYr7a8LpiH4ETkSGD3r7SDdicUn9ttf5MWCir` | the fee vault's WSOL account |

Without that file every key resolves to the system program (no admin). The mainnet build is
compiled **without** the `devnet` Cargo feature (that feature only relaxes the Pyth price age
for devnet).

## Verifying the mainnet binaries

The mainnet binaries were built with
[`solana-verify`](https://github.com/Ellipsis-Labs/solana-verifiable-build) **0.5.2** from the
repository root. `Cargo.toml`'s `[workspace.metadata.cli] solana = "3.1.10"` selects its build
image (Agave 3.1.10, Rust 1.86.0).

```bash
git clone https://github.com/Deep-Liquidity/contracts && cd contracts
solana-verify build --library-name deep_curve
solana-verify build --library-name deep_amm
solana-verify build --library-name deep_rewards

# hash of what you built
solana-verify get-executable-hash target/deploy/deep_curve.so
# hash of what is deployed
solana-verify get-program-hash -u mainnet-beta 7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA
```

Or in one step per program:

```bash
solana-verify verify-from-repo -u mainnet-beta \
  --program-id 7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA \
  --library-name deep_curve \
  https://github.com/Deep-Liquidity/contracts
```

Expected hashes (sha256 of the program bytes without trailing zeros, as `solana-verify` prints):

| Program | Hash |
| --- | --- |
| `deep_curve` | `3a63be6b995cd9e2e3bdc9175cb8ebf4283110cf1daa07a70256c555d15c4213` |
| `deep_amm` | `17e8f45289d6ffda8e1b7b6e948d5c4b97fb1f8a2c748d6431177184300b6052` |
| `deep_rewards` | `c06ca350c8051815dc4cbe9ac1826fbaaedd0910d17155f6508699265cf5c32d` |

All three programs' upgrade authority is DEEP's Squads multisig vault
`4vEQmhpGxVJNiLaYz16NVaYQqcp7GbZMwd5TR3cZtQqu`. An upgrade goes through the multisig and its
time lock, and this repository is updated with the source of every upgrade.

## Tests

```bash
cargo test --workspace            # unit tests and the cross-language vectors
```

The LiteSVM integration tests (`--features litesvm-tests`) load SBF binaries and test keypairs
from paths given in environment variables (`DEEP_CURVE_SO`, `DEEP_AMM_SO`, `DEEP_REWARDS_SO`,
`MPL_TOKEN_METADATA_SO`, …); DEEP's own harness runs them.

## Security

Report vulnerabilities privately through GitHub's security advisories on this repository.

## Licence

`deep-curve`, `deep-rewards`, the IDLs and fixtures: MIT (see [LICENSE](LICENSE)).
`deep-amm`: Apache-2.0 (see [programs/deep-amm/LICENSE](programs/deep-amm/LICENSE)); its
[NOTICE](programs/deep-amm/NOTICE) names the upstream commit and lists every modification.
See [NOTICE](NOTICE).
