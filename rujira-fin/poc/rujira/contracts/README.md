# Rujira contracts

Rujira's application-layer contracts are written in Rust and compiled to
CosmWasm. This page describes the contracts maintained in this repository and
links to the source of contracts maintained in external repositories that are
deployed on THORChain mainnet.

The external deployment list was last reviewed on 19 August 2026. For current
addresses and versions, see the [deployment explorer][deployment-explorer]; for
release checksums and audits, see [Releases & Contracts][releases].

## Rujira repository contracts

### Current contract directories

| Contract | Description |
| --- | --- |
| [`rujira-account`](./rujira-account/) | Minimal account contract used as an isolated execution container. A controlling contract such as `rujira-ghost-credit` uses its sudo entry point to manage collateral and execute approved actions. |
| [`rujira-brune`](./rujira-brune/) | Bonding and market-making contract for bRUNE. It manages RUNE bonding, bRUNE liquidity, and the distribution of bonding revenue. |
| [`rujira-demo`](./rujira-demo/) | Development contract demonstrating the bindings between the application layer and THORChain's base layer. It is an example integration surface, not a production protocol. |
| [`rujira-fin`](./rujira-fin/) | Crankless, fully on-chain order book powering RUJI Trade. It supports market, fixed-price, oracle-priced, and range orders with deterministic matching. |
| [`rujira-ghost-credit`](./rujira-ghost-credit/) | Overcollateralized credit-account registry for borrowing against multiple assets. It creates isolated `rujira-account` instances, values collateral, tracks debt, and coordinates liquidations. |
| [`rujira-ghost-mint`](./rujira-ghost-mint/) | Capped, interest-bearing credit source for assets minted by authorized borrowers. It is designed to provide the mint-side liquidity used by perpetual markets. |
| [`rujira-ghost-vault`](./rujira-ghost-vault/) | Single-asset lending vault that accepts deposits, issues receipt tokens, and lends to approved markets. Interest is derived from utilization and distributed to lenders after protocol fees. |
| [`rujira-merge`](./rujira-merge/) | Migration contract that exchanges eligible ecosystem tokens for RUJI according to configured ratios and decay. Depositors receive pool shares that can be redeemed for their RUJI allocation. |
| [`rujira-revenue`](./rujira-revenue/) | Scheduled revenue router that can swap collected fees into target denominations and distribute them among weighted recipients. A separate instance can be configured for each revenue token. |
| [`rujira-staking`](./rujira-staking/) | Revenue-distributing staking contract with account-based and liquid-staking modes. It tracks stake shares, routes rewards, and can compound rewards into the bonded asset. |
| [`rujira-template`](./rujira-template/) | Minimal scaffold for developing new Rujira contracts. Its runtime handlers are intentionally empty and it is not a production application. |
| [`rujira-thorchain-swap`](./rujira-thorchain-swap/) | Market-making strategy that exposes THORChain base-layer liquidity to RUJI Trade, also known as Virtualization Strategy. It provides atomic application-layer execution while settling against base-layer pools with liquidity borrowed from Ghost vaults. |

### Deprecated contracts

| Contract | Description |
| --- | --- |
| [`rujira-bow`][rujira-bow] | Deprecated automated market maker for RUJI Pools. It places pooled liquidity into RUJI Trade markets using XYK constant-product logic and was replaced by Custom Concentrated Liquidity (CCL) range strategies built directly into FIN. |

## Contracts maintained in external repositories

### Current contracts

#### [CALC][calc-repository]

| Contract | Description |
| --- | --- |
| [`calc-manager`][calc-manager] | Factory, registry, and primary user entry point for CALC strategies. It validates strategy configuration and coordinates creation and management. |
| [`calc-scheduler`][calc-scheduler] | Permissionless scheduler that tracks strategy triggers and dispatches their configured execution messages when conditions are met. |
| [`calc-strategy`][calc-strategy] | Isolated, programmable strategy instance that holds a user's funds and executes a configured graph of conditions and actions. |

#### [CosmWasm CW Plus][cw-plus-repository]

| Contract | Description |
| --- | --- |
| [`cw3-flex-multisig`][cw3-flex-multisig] | Weighted multisignature contract backed by a CW4 membership group. Members propose and vote on executable Cosmos messages. |
| [`cw4-group`][cw4-group] | Group and membership contract used to maintain weighted voter sets for multisignatures and DAO voting modules. |

#### [DAO DAO][dao-repository]

| Contract | Description |
| --- | --- |
| [`cw-admin-factory`][cw-admin-factory] | Factory that instantiates a contract and transfers that contract's admin role to itself, allowing it to control its own migrations. |
| [`dao-dao-core`][dao-dao-core] | Core DAO module that holds the treasury, connects voting and proposal modules, and executes messages approved through governance. |
| [`dao-pre-propose-multiple`][dao-pre-propose-multiple] | Submission and deposit layer for multiple-choice proposals before they enter the proposal module. |
| [`dao-pre-propose-single`][dao-pre-propose-single] | Submission and deposit layer for single-choice proposals before they enter the proposal module. |
| [`dao-proposal-multiple`][dao-proposal-multiple] | Governance module for proposals with multiple voting options and configurable voting and execution rules. |
| [`dao-proposal-single`][dao-proposal-single] | Governance module for standard single-choice proposals, including voting, status transitions, and execution. |
| [`dao-rewards-distributor`][dao-rewards-distributor] | Distributes native or CW20 rewards to members according to voting power snapshots supplied by a DAO voting module. |
| [`dao-vote-delegation`][dao-vote-delegation] | Lets DAO members delegate voting power while preserving the ability to override a delegate with their own vote. |
| [`dao-voting-cw4`][dao-voting-cw4] | Voting-power module backed by the weighted membership stored in a CW4 group contract. |
| [`dao-voting-token-staked`][dao-voting-token-staked] | Voting-power module based on staked native or Token Factory tokens. It tracks stake and exposes historical voting power to governance modules. |

#### [Liquidy][liquidy-repository]

| Contract | Description |
| --- | --- |
| [`liquidy-swap-router`][liquidy-swap] | Multi-stage swap router that chains trades across RUJI Trade markets, enforces a minimum return, and sends the result to an application-layer or base-layer recipient. It also collects configured platform and affiliate fees. |

#### [NAMI Index][nami-repository]

| Contract | Description |
| --- | --- |
| [`nami-affiliate`][nami-affiliate] | Wrapper that deducts an optional affiliate fee before forwarding funds and a message to another contract, then returns residual balances. |
| [`nami-index-entry-adapter`][nami-index-entry-adapter] | Entry and exit adapter that swaps assets into or out of the denominations required by a NAMI index and chains the required operations through callbacks. |
| [`nami-index-fixed`][nami-index-fixed] | Fixed-unit index in which each receipt token represents a deterministic basket of assets. It supports ratio-matched deposits, proportional withdrawals, and controlled reallocation. |
| [`nami-index-nav`][nami-index-nav] | Net-asset-value index in which receipt tokens represent proportional ownership of the fund. It uses external prices for deposits and withdrawals and supports permissionless rebalancing. |

#### [Public Awesome CW NFTs][cw-nfts-repository]

| Contract | Description |
| --- | --- |
| [`cw721-base`][cw721-base] | Base implementation of the CW721 non-fungible token standard, providing token ownership, transfers, approvals, and metadata extensions. |

#### [Redacted][redacted-repository]

| Contract | Description |
| --- | --- |
| [`redacted-proxy`][redacted-proxy] | Privacy-pool contract that registers stealth addresses, routes deposits and withdrawals, tracks balances, and verifies zero-knowledge proofs. It also controls the isolated sub-wallets used for private execution. |
| [`redacted-sub-wallet`][redacted-sub-wallet] | Isolated execution account controlled by the Redacted proxy. It executes approved DeFi interactions and transfers while applying the protocol's configured fees. |

### Deprecated contracts

#### [AUTO V2][auto-repository]

| Contract | Description |
| --- | --- |
| [`auto-workflow-manager`][auto-workflow-manager] | Core automation contract that publishes workflows, creates instances, and orchestrates their actions through completion. It also controls which publishers and executors may participate. |
| [`auto-fee-manager`][auto-fee-manager] | Manages workflow balances, execution and creator fees, debt, and revenue distribution for the AUTO automation system. |

#### [Levana Perps][levana-repository]

| Contract | Description |
| --- | --- |
| [`levana-perpswap-cosmos-copy-trading`][levana-copy-trading] | Copy-trading vault in which depositors allocate funds to a leader whose trades are replicated for the vault. |
| [`levana-perpswap-cosmos-countertrade`][levana-countertrade] | Permissionless strategy that takes the less popular side of perpetual markets to collect funding payments, while retaining directional market risk. |
| [`levana-perpswap-cosmos-factory`][levana-factory] | Factory and administration contract responsible for creating and configuring a set of perpetual markets. |
| [`levana-perpswap-cosmos-liquidity-token`][levana-liquidity-token] | CW20-compatible proxy representing liquidity-provider positions in a Levana perpetual market. |
| [`levana-perpswap-cosmos-market`][levana-market] | Primary perpetual-market contract implementing positions, liquidity, funding, fees, profit and loss, and market configuration. |
| [`levana-perpswap-cosmos-position-token`][levana-position-token] | CW721-compatible proxy representing individual perpetual positions as transferable NFTs. |


[deployment-explorer]: https://rujira.network/developer/deployment
[releases]: https://docs.rujira.network/resources/releases-and-contracts
[rujira-bow]: https://gitlab.com/thorchain/rujira/-/tree/29b1573d19614ba256764f1c3be933f5e80d4a68/contracts/rujira-bow
[auto-repository]: https://github.com/we-build-it/auto-v2-contracts
[auto-workflow-manager]: https://github.com/we-build-it/auto-v2-contracts/tree/main/contracts/auto-workflow-manager
[auto-fee-manager]: https://github.com/we-build-it/auto-v2-contracts/tree/main/contracts/auto-fee-manager
[calc-repository]: https://github.com/calculated-finance/calc-rs
[calc-manager]: https://github.com/calculated-finance/calc-rs/tree/main/contracts/manager
[calc-scheduler]: https://github.com/calculated-finance/calc-rs/tree/main/contracts/scheduler
[calc-strategy]: https://github.com/calculated-finance/calc-rs/tree/main/contracts/strategy
[cw-plus-repository]: https://github.com/CosmWasm/cw-plus
[cw3-flex-multisig]: https://github.com/CosmWasm/cw-plus/tree/main/contracts/cw3-flex-multisig
[cw4-group]: https://github.com/CosmWasm/cw-plus/tree/main/contracts/cw4-group
[dao-repository]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1
[cw-admin-factory]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/external/cw-admin-factory
[dao-dao-core]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/dao-dao-core
[dao-pre-propose-multiple]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/pre-propose/dao-pre-propose-multiple
[dao-pre-propose-single]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/pre-propose/dao-pre-propose-single
[dao-proposal-multiple]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/proposal/dao-proposal-multiple
[dao-proposal-single]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/proposal/dao-proposal-single
[dao-rewards-distributor]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/distribution/dao-rewards-distributor
[dao-vote-delegation]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/delegation/dao-vote-delegation
[dao-voting-cw4]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/voting/dao-voting-cw4
[dao-voting-token-staked]: https://github.com/DA0-DA0/dao-contracts/tree/v2.7.1/contracts/voting/dao-voting-token-staked
[levana-repository]: https://github.com/Levana-Protocol/levana-perps
[levana-copy-trading]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/copy_trading
[levana-countertrade]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/countertrade
[levana-factory]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/factory
[levana-liquidity-token]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/liquidity_token
[levana-market]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/market
[levana-position-token]: https://github.com/Levana-Protocol/levana-perps/tree/main/contracts/position_token
[liquidy-repository]: https://github.com/Liquidy-Finance/liquidy-contracts
[liquidy-swap]: https://github.com/Liquidy-Finance/liquidy-contracts/tree/main/contracts/liquidy-swap
[nami-repository]: https://github.com/NAMIProtocol/nami-contracts
[nami-affiliate]: https://github.com/NAMIProtocol/nami-contracts/tree/audit/contracts/nami-affiliate
[nami-index-entry-adapter]: https://github.com/NAMIProtocol/nami-contracts/tree/audit/contracts/nami-index-entry-adapter
[nami-index-fixed]: https://github.com/NAMIProtocol/nami-contracts/tree/audit/contracts/nami-index-fixed
[nami-index-nav]: https://github.com/NAMIProtocol/nami-contracts/tree/audit/contracts/nami-index-nav
[cw-nfts-repository]: https://github.com/public-awesome/cw-nfts
[cw721-base]: https://github.com/public-awesome/cw-nfts/tree/177a993dfb5a1a3164be1baf274f43b1ca53da53/contracts/cw721-base
[redacted-repository]: https://github.com/redactedLabs/redacted-contract-main
[redacted-proxy]: https://github.com/redactedLabs/redacted-contract-main/tree/main/contracts/proxy
[redacted-sub-wallet]: https://github.com/redactedLabs/redacted-contract-main/tree/main/contracts/sub-wallet
