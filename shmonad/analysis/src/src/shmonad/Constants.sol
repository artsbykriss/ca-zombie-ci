//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { IMonadStaking } from "./interfaces/IMonadStaking.sol";

IMonadStaking constant STAKING = IMonadStaking(0x0000000000000000000000000000000000001000);

// NOTE: These constants exist internally in the precompile but are NOT exposed as view functions.
// Only constants used in production code are defined here. Test-only constants remain in MockMonadStakingPrecompile.
uint256 constant DUST_THRESHOLD = 1e9; // Minimum stake amount (1 gwei)
uint256 constant WITHDRAWAL_DELAY = 1; // Epochs
uint256 constant MAX_EXTERNAL_REWARD = 1_000_000 * 1e18; // Precompile upper bound for externalReward()
uint256 constant VALIDATOR_CRANK_LIMIT = 1_500_000; // Stop loops when gasleft() drops below this

address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
// System-only accounting address for owner commission. No private key is assumed to exist for this address;
// balances are realized via `claimOwnerCommissionAsShares()`, not by direct token transfers.
address constant OWNER_COMMISSION_ACCOUNT = address(0x1111111111111111111111111111111111111111);

// Deterministic deployment salt namespace for Coinbase contracts
uint256 constant COINBASE_PROCESS_GAS_LIMIT = 250_000;
uint256 constant COINBASE_HANDLE_MEV_GAS_LIMIT = 75_000;
bytes32 constant COINBASE_SALT = keccak256("SHMONAD_COINBASE");
uint8 constant COINBASE_IMMUTABLE_ARGS_VERSION = 1; // Version byte packed into CWIA coinbase proxy args
uint256 constant TRANSFER_GAS_LIMIT = 50_000; // gas headroom for multisig recipient support

// Keep base gas values in sync with Monad's staking precompile docs. Calls add STAKING_GAS_BUFFER.
uint256 constant STAKING_GAS_BUFFER = 10_000;
uint256 constant STAKING_GAS_CLAIM_REWARDS = 155_375;
uint256 constant STAKING_GAS_EXTERNAL_REWARD = 66_575;
uint256 constant STAKING_GAS_DELEGATE = 260_850;
uint256 constant STAKING_GAS_UNDELEGATE = 147_750;
uint256 constant STAKING_GAS_WITHDRAW = 68_675;
uint256 constant STAKING_GAS_GET_WITHDRAWAL_REQUEST = 24_300;
uint256 constant STAKING_GAS_GET_VALIDATOR = 97_200;
uint256 constant STAKING_GAS_PROPOSER_VAL_ID = 100;

// EIP-1967 admin slot: bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
bytes32 constant EIP1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
// NOTE: Top-up period duration is compared against `block.number` in policy logic and is measured in blocks.
// Set to ~1 day on Monad (0.4s blocks): 24*60*60 / 0.4 = 216_000 blocks.
uint32 constant MIN_TOP_UP_PERIOD_BLOCKS = 216_000;
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

uint256 constant ZERO = 0;
uint16 constant BPS_SCALE = 10_000; // Still used for percentage weights/targets outside fee curve math
uint256 constant MIN_VALIDATOR_DEPOSIT = 1e18; // Min amount to do a validator deposit
uint256 constant ATOMIC_MIN_FEE_WEI = 1e9; // 1 gwei floor for atomic paths

uint256 constant EPOCHS_TRACKED = 8; // Must be a power of 2
uint256 constant MONAD_EPOCH_LENGTH = 50_000; // Measured in blocks
uint256 constant SHMONAD_VALIDATOR_DEACTIVATION_PERIOD = 7; // Minimum epochs before inactive removal is eligible
uint256 constant MAX_ACTIVE_VALIDATORS_FOR_ALLOCATION = 300; // Keeps the global two-pass allocation prepass gas-bounded
uint8 constant POOLED_WITHDRAW_ID_MIN = 1;
uint8 constant POOLED_WITHDRAW_ID_MAX = 128;
uint8 constant ISOLATED_WITHDRAW_ID_MIN = 129;
uint8 constant ISOLATED_WITHDRAW_ID_MAX = type(uint8).max;
// Traditional unstake requests can only quote at `internalEpoch + 5` or `internalEpoch + 7`, so at most 7
// distinct pending completion epochs can be live at once when a user requests once per epoch. The extra slot is
// reserved for compacting already-matured requests so new requests do not consume a pending bucket.
uint8 constant TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT = 8;
uint8 constant TRADITIONAL_UNSTAKE_PENDING_SLOT_COUNT = TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT - 1;
uint8 constant TRADITIONAL_UNSTAKE_MATURED_SLOT = TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT - 1;

uint256 constant SCALE = 1e18; // 100%
uint256 constant TARGET_FLOAT = 2e16; // 2%
uint256 constant FLOAT_REBALANCE_SENSITIVITY = 1e14; // 1bp
uint256 constant FLOAT_PLACEHOLDER = 1;

uint64 constant UNKNOWN_VAL_ID = type(uint64).max - 1;
address constant UNKNOWN_VAL_ADDRESS = address(uint160(type(uint160).max - 1));
// ID-based sentinels for validator crank linked list
uint64 constant FIRST_VAL_ID = 1_111_111_111_111_111_111; // 1.111e18 sentinel (fits in uint64)
uint64 constant LAST_VAL_ID = 9_999_999_999_999_999_999; // 9.999e18 sentinel (fits in uint64)

uint256 constant UINT120_MASK = type(uint120).max;

// feeLib constant
uint256 constant RAY = 1e27;
uint256 constant DEFAULT_NON_STAKING_REVENUE_MULTIPLIER_RAY = 2 * RAY;
uint256 constant MAX_NON_STAKING_REVENUE_MULTIPLIER_RAY = 20 * RAY;
uint16 constant DEFAULT_STAKING_YIELD_DEADBAND_BPS = 8000;

// Default affine fee curve parameters (Ray precision)
// Fee curve: r(u) = m*u + c with
// - c = 8% / 1600 = 1/20000 = 0.005%
// - m chosen so r(1) = 1% + c  => m = 1%
// Therefore: at u = 0 => 0.005%; at u = 1 => 1.005%
uint128 constant DEFAULT_SLOPE_RATE_RAY = uint128(RAY / 100); // m = 1.00%
uint128 constant DEFAULT_Y_INTERCEPT_RAY = uint128(RAY / 20_000); // c = 0.005%
