# Verio vIP — live state (Story mainnet, chainId 1514)

Pinned read block: **23,624,317** (anvil fork block used by `poc/test/Verio.t.sol`;
the public RPC `https://mainnet.storyrpc.io` does not serve archive state, so all
reads below are "latest at fork block" and were taken in one batch by the fork test).
IP price used: **$0.15295** (DefiLlama `api.llama.fi/protocol/verio`, latest point
timestamp 1792592663: TVL $2,369,454.98 / 15,491,283.906 IP).

## Contracts

| Role | Proxy | Implementation | Verified | Notes |
|---|---|---|---|---|
| StakePool | `0xf6701A6A20639f0E765bA7FF66FD4f49815F1a27` | `0x3dbe57a66ab00a6dc28cff9b47d6c09fe8aa2698` | yes (StakePool, 19.4 KB) | ERC1967, admin slot 0, no UUPS selectors → immutable proxy |
| vIP token | `0x5267F7eE069CEB3D8F1c760c215569b79d0685aD` | `0xA322C273D020adCa4BBCa12481c06FfcD3C48288` | no | decompiled; mint/burn gated (see gating) |
| WithdrawalPool | `0x2a7935E926C65Ef2671D5807760e2421adf992d8` | `0x8512eed984234e197f8b32ef8f589e6eeb8bc9e2` | no | `analysis/wp-decompiled.sol`; v2.0.0 |
| Delegator | `0xB47Aedf533cc3c1651a8Af2312Fe55e317006821` | `0x3A938977354A47331E56029664a41F1a2D513252` | yes (Delegator, 41.8 KB) | ERC1967, immutable |
| ComponentSelector | `0x20Cb9DCb6FC306c31325bdA6221AA5e067B9Da51` | `0xe174935bA41f6417a871f4A25610993596f40c8C` | yes (ComponentSelector) | all setters `onlyAdmin` |
| RewardPool | `0x3bDcB577C21a36f66816bE3D5d8C311419EC3975` | `0x6034fb27a4d1F923ACAD4F1F35CB2A8A2d55BB6A` | no | `claimRewards()` onlyStakePool |
| WP InsurancePool | `0x22dF4eF4Ebe13755Dcb719945596F94A72C8Ebc4` | `0xcb5e5a4755f7d67754d123582225cb6d8cb95713` | no | 25,000 IP cap; `claim()` onlyWithdrawalPool |
| Delegator InsurancePool | `0x01075765071baC590168C55B40D46DAFbf8BD1bA` | `0x63bc080a…` | no | 98 IP balance; pays precompile fees |
| Treasury | `0x08721C44915969aeB1f04817C92B0F8EA62d5096` | — | — | EOA, receives 16% RP fee + burn fee vIP |
| Admin (timelock) | `0xc64129116e6906686a39e7a6Be633a5A3EF5B7B8` | — | yes (TimelockController) | `getMinDelay()` = **300 s** |
| Owner | `0x0f0172E30795958dA86f068F80A1743Df1955e16` | — | — | **EOA (codesize 0)**; same owner on SP/WP/vIP/Delegator/Selector/RP |

All proxies: EIP-1967 admin slot = `0x0` and no `upgradeToAndCall`/`proxiableUUID`
selector in any implementation → the implementations are **not upgradeable**. The
owner can still retarget the ComponentSelector components (P-class, see below).

## State (block 23,624,317)

| Field | Value (IP / vIP) |
|---|---|
| `delegator.getGlobalDistributionTotal()` D | 15,475,537.586749393557894500 |
| `stakePool.getUnstaked()` E (`excessUnstake`) | **0** |
| `stakePool.getPendingUnstake()` P | 1,469.357216360810924995 |
| `stakePool.getTotalStake()` TS | 15,474,068.229533032746969505 |
| StakePool native balance B | 1,845.402511830810000000 |
| **NAV = TS + B** | **15,475,913.632044863556969505** |
| vIP `totalSupply` / `getTotalSupply` | 13,675,004.869990373338040218 (equal) |
| Rate NAV/supply | **1.131693464037191087 IP/vIP** |
| WithdrawalPool balance | **0** |
| `withdrawalPool.getTotalPendingWithdrawals()` Pw | **6,665.841927501986166900** |
| WP InsurancePool balance | 263.583953655634299353 |
| WP InsurancePool remaining capacity (0x14a6bf0f) | 24,736.416046344366 (= 25,000 − balance) |
| RewardPool balance | 83,613.991616934000000000 (grows every block) |
| RewardPool fee (`0x2c928098`) | 1,600 bps (16% to treasury) |
| Delegator unstake queue | 2,316.341756343325680771 (validator `0x033923af…ff60`, flexible, overdue: `nextUnstake` 1,757,794,721 < now) |
| Delegator native balance | 0 (fees paid from its 98 IP insurance pool) |
| Treasury native balance | 0 |

## WP outstanding claims — top recipients (event reconstruction)

939 `WithdrawalAdded` − 743 `WithdrawalClaimed` = 6,665.841927501987 IP, matching
`getTotalPendingWithdrawals()`; 114 recipients have a non-zero balance.

| Recipient | Outstanding IP |
|---|---|
| `0xedfc6299b8d9d261a8364b6f7bf88cdeb78cc912` | 1,508.5108315993004 |
| `0x1cbc5c23c073117eca2662f57c4e2b4b50bc6d7d` | 1,470.137751742961 |
| `0xd3aaa5197f4cbdf9969e72feb07cb67f2a89ab1f` | 884.2948917745155 |
| `0xc960517dee7a3fc8b1f28481fd82756023d3470d` | 578.6441254147516 |
| `0x37a054353c6f43b3de9d6d19be2117dc0e5c0f2c` | 438.6828393413363 |

Approximate currently-due (unbondedTimestamp ≤ now) unclaimed: 706.03 IP upper bound;
WP liquid 0 + insurance 263.58 → ~442 IP temporarily unfunded. Backed by D = 15.47M IP;
the Delegator queue (2,316.34 IP) is overdue and permissionlessly processable.

Ledger identity verified exactly by the fork test:
`getTotalStake() == D + E − P` (15,474,068.229533032746969505).

## Parameters

| Param | Value |
|---|---|
| `delegationSize` | 2,048 IP |
| `unbondingPeriod` | 1,382,400 s = **16 days** |
| `minStake` (SP) | 0.001 IP |
| `minStakeAmount()` (precompile) | 1,024 IP |
| precompile `fee()` | 1 IP |
| `mintFeeBps` / enabled | 0 / false |
| `burnFeeBps` / enabled | **10 (0.1%)** / true |
| `paused` (SP/WP/RP/Delegator/Selector) | false |
| `maxStake` / `maxStakeIterations` | 20,480 IP / 20 |
| `singularity` | passed (unstake enabled) |
