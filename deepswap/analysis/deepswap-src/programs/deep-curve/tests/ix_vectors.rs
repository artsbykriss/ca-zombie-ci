//! Cross-checks @deep/sdk instruction builders against Anchor's generated account
//! structs. fixtures/ix-vectors.json is produced by
//! packages/sdk/scripts/gen-ix-fixtures.ts; this test rebuilds every instruction
//! from `deep_curve::accounts::*` + `deep_curve::instruction::*` and requires
//! byte-for-byte equality (account order, signer/writable flags, data).

use anchor_lang::prelude::Pubkey;
use anchor_lang::{InstructionData, ToAccountMetas};
use anchor_spl::associated_token::get_associated_token_address;
use deep_curve::{raydium, ConfigParams};
use serde_json::Value;
use std::str::FromStr;

const VECTORS: &str = include_str!("../../../fixtures/ix-vectors.json");

fn k(n: u8) -> Pubkey {
    Pubkey::new_from_array([n; 32])
}
fn pk(s: &str) -> Pubkey {
    Pubkey::from_str(s).unwrap()
}
fn pda(seeds: &[&[u8]], program: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(seeds, program).0
}

const ADMIN: u8 = 1;
const MIGRATION: u8 = 2;
const CREATOR: u8 = 3;
const FEE_RECIPIENT: u8 = 4;
const AMM_CONFIG: u8 = 5;
const USER: u8 = 6;
const MINT: u8 = 7;
const LOW_MINT: u8 = 0;
const AMM_FEE_RECEIVER: u8 = 8;
const PAYER: u8 = 9;
/// Stand-in for the build-time DEEP_BUILDER_WALLET (deep_curve::BUILDER_WALLET).
const BUILDER: u8 = 10;
const DEST1: u8 = 11;
const DEST2: u8 = 12;

fn native_mint() -> Pubkey {
    anchor_spl::token::spl_token::native_mint::ID
}
fn metadata_program() -> Pubkey {
    pk("metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s")
}
fn rent() -> Pubkey {
    pk("SysvarRent111111111111111111111111111111111")
}
fn config() -> Pubkey {
    pda(&[deep_curve::CONFIG_SEED], &deep_curve::ID)
}
fn treasury() -> Pubkey {
    pda(&[deep_curve::TREASURY_SEED], &deep_curve::ID)
}
fn fee_vault() -> Pubkey {
    pda(&[deep_curve::FEE_VAULT_SEED], &deep_curve::ID)
}
fn curve(mint: &Pubkey) -> Pubkey {
    pda(&[deep_curve::CURVE_SEED, mint.as_ref()], &deep_curve::ID)
}

fn params() -> ConfigParams {
    ConfigParams {
        fee_recipient: k(FEE_RECIPIENT),
        migration_authority: k(MIGRATION),
        protocol_fee_bps: 70,
        creator_fee_bps: 30,
        migration_fee_bps: 100,
        initial_virtual_sol: 45_000_000_000,
        initial_virtual_token: 1_000_000_000_000_000,
        curve_supply: 800_000_000_000_000,
        token_total_supply: 1_000_000_000_000_000,
        decimals: 6,
        raydium_amm_config: k(AMM_CONFIG),
        timelock_seconds: 172_800,
        launch_fee_usd_cents: 200,
        // distinct values, so a swapped field order cannot pass
        sell_protocol_fee_bps: 80,
        max_reward_bps: 100,
        reserved_bps: 90,
    }
}

/// (pubkey, is_signer, is_writable) in order.
type Metas = Vec<(String, bool, bool)>;

fn metas<T: ToAccountMetas>(a: T) -> Metas {
    a.to_account_metas(None)
        .into_iter()
        .map(|m| (m.pubkey.to_string(), m.is_signer, m.is_writable))
        .collect()
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn check(name: &str, expected_metas: Metas, expected_data: Vec<u8>) {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let ix = &v["instructions"][name];
    assert!(!ix.is_null(), "{name}: missing from fixtures");
    assert_eq!(
        ix["programId"],
        deep_curve::ID.to_string(),
        "{name}: program id"
    );
    let got: Metas = ix["keys"]
        .as_array()
        .unwrap()
        .iter()
        .map(|m| {
            (
                m["pubkey"].as_str().unwrap().to_string(),
                m["isSigner"].as_bool().unwrap(),
                m["isWritable"].as_bool().unwrap(),
            )
        })
        .collect();
    assert_eq!(got.len(), expected_metas.len(), "{name}: account count");
    for (i, (g, e)) in got.iter().zip(expected_metas.iter()).enumerate() {
        assert_eq!(g, e, "{name}: account #{i} (pubkey, signer, writable)");
    }
    assert_eq!(
        ix["data"].as_str().unwrap(),
        hex(&expected_data),
        "{name}: data"
    );
}

#[test]
fn fixture_keys_match() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    for (name, n) in [
        ("admin", ADMIN),
        ("migration", MIGRATION),
        ("creator", CREATOR),
        ("feeRecipient", FEE_RECIPIENT),
        ("ammConfig", AMM_CONFIG),
        ("user", USER),
        ("mint", MINT),
        ("lowMint", LOW_MINT),
        ("ammFeeReceiver", AMM_FEE_RECEIVER),
        ("payer", PAYER),
    ] {
        assert_eq!(v["keys"][name], k(n).to_string(), "{name}");
    }
}

#[test]
fn config_instructions() {
    let program_data = pda(
        &[deep_curve::ID.as_ref()],
        &pk("BPFLoaderUpgradeab1e11111111111111111111111"),
    );
    check(
        "initialize_config",
        metas(deep_curve::accounts::InitializeConfig {
            admin: k(ADMIN),
            config: config(),
            treasury: treasury(),
            program: deep_curve::ID,
            program_data,
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::InitializeConfig { params: params() }.data(),
    );
    let pending = pda(&[deep_curve::PENDING_CONFIG_SEED], &deep_curve::ID);
    check(
        "queue_config_update",
        metas(deep_curve::accounts::QueueConfigUpdate {
            admin: k(ADMIN),
            config: config(),
            pending_config: pending,
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::QueueConfigUpdate { params: params() }.data(),
    );
    check(
        "apply_config_update",
        metas(deep_curve::accounts::ApplyConfigUpdate {
            config: config(),
            pending_config: pending,
        }),
        deep_curve::instruction::ApplyConfigUpdate {}.data(),
    );
    check(
        "cancel_config_update",
        metas(deep_curve::accounts::CancelConfigUpdate {
            admin: k(ADMIN),
            config: config(),
            pending_config: pending,
        }),
        deep_curve::instruction::CancelConfigUpdate {}.data(),
    );
    check(
        "set_paused",
        metas(deep_curve::accounts::AdminOnly {
            admin: k(ADMIN),
            config: config(),
        }),
        deep_curve::instruction::SetPaused { paused: true }.data(),
    );
    check(
        "propose_admin",
        metas(deep_curve::accounts::AdminOnly {
            admin: k(ADMIN),
            config: config(),
        }),
        deep_curve::instruction::ProposeAdmin {
            new_admin: k(MIGRATION),
        }
        .data(),
    );
    check(
        "accept_admin",
        metas(deep_curve::accounts::AcceptAdmin {
            pending_admin: k(MIGRATION),
            config: config(),
        }),
        deep_curve::instruction::AcceptAdmin {}.data(),
    );
}

#[test]
fn fee_instructions() {
    check(
        "withdraw_protocol_fees",
        metas(deep_curve::accounts::WithdrawProtocolFees {
            admin: k(ADMIN),
            config: config(),
            treasury: treasury(),
            fee_recipient: k(FEE_RECIPIENT),
        }),
        deep_curve::instruction::WithdrawProtocolFees { amount: 5_000 }.data(),
    );
    check(
        "claim_creator_fees",
        metas(deep_curve::accounts::ClaimCreatorFees {
            creator: k(CREATOR),
            curve: curve(&k(MINT)),
        }),
        deep_curve::instruction::ClaimCreatorFees {}.data(),
    );
}

#[test]
fn sweep_and_migration_instructions() {
    let mint = k(MINT);
    check(
        "sweep_protocol_fees",
        metas(deep_curve::accounts::SweepProtocolFees {
            curve: curve(&mint),
            fee_vault: fee_vault(),
        }),
        deep_curve::instruction::SweepProtocolFees {}.data(),
    );
    // The holder vault is a PDA of deep-rewards. The SDK derives it from ITS deep-rewards
    // program id (pinned to programs/deep-rewards by fixtures/rewards-ix-vectors.json), so
    // this equality pins deep-curve's DEEP_REWARDS_PROGRAM_ID and seed to the same program.
    check(
        "sweep_holder_fees",
        metas(deep_curve::accounts::SweepHolderFees {
            curve: curve(&mint),
            holder_vault: deep_curve::holder_vault_address(&mint),
        }),
        deep_curve::instruction::SweepHolderFees {}.data(),
    );
    check(
        "migrate_config",
        metas(deep_curve::accounts::MigrateConfig {
            payer: k(PAYER),
            config: config(),
            pending_config: pda(&[deep_curve::PENDING_CONFIG_SEED], &deep_curve::ID),
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::MigrateConfig {}.data(),
    );
    check(
        "migrate_curve",
        metas(deep_curve::accounts::MigrateCurve {
            payer: k(PAYER),
            mint,
            curve: curve(&mint),
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::MigrateCurve {}.data(),
    );
}

#[test]
fn create_and_trade_instructions() {
    let mint = k(MINT);
    let c = curve(&mint);
    let metadata = pda(
        &[b"metadata", metadata_program().as_ref(), mint.as_ref()],
        &metadata_program(),
    );
    // Standard (no reward rate) and Holder at 250 bps: the argument tail is
    // reward_model (u8), reward_bps (u16 LE), max_launch_fee_lamports (u64 LE)
    for (name, reward_model, reward_bps, max_launch_fee_lamports) in [
        (
            "create_token",
            deep_curve::math::REWARD_MODEL_STANDARD,
            0u16,
            25_000_000u64,
        ),
        (
            "create_token_holder",
            deep_curve::math::REWARD_MODEL_HOLDER,
            250,
            u64::MAX,
        ),
        // (the vectors pin the encoding only; 250 is under the 500 bps ceiling)
    ] {
        check(
            name,
            metas(deep_curve::accounts::CreateToken {
                creator: k(CREATOR),
                config: config(),
                mint,
                curve: c,
                vault: get_associated_token_address(&c, &mint),
                metadata,
                price_update: deep_curve::pyth::SOL_USD_PRICE_UPDATE,
                token_program: anchor_spl::token::ID,
                associated_token_program: anchor_spl::associated_token::ID,
                token_metadata_program: metadata_program(),
                system_program: anchor_lang::system_program::ID,
                rent: rent(),
            }),
            deep_curve::instruction::CreateToken {
                name: "Hadal".into(),
                symbol: "HADAL".into(),
                uri: "https://x/m.json".into(),
                reward_model,
                reward_bps,
                max_launch_fee_lamports,
            }
            .data(),
        );
    }
    let trade = || deep_curve::accounts::Trade {
        user: k(USER),
        config: config(),
        mint,
        curve: c,
        vault: get_associated_token_address(&c, &mint),
        user_token: get_associated_token_address(&k(USER), &mint),
        token_program: anchor_spl::token::ID,
        associated_token_program: anchor_spl::associated_token::ID,
        system_program: anchor_lang::system_program::ID,
    };
    check(
        "buy",
        metas(trade()),
        deep_curve::instruction::Buy {
            sol_in: 1_000_000_000,
            min_tokens_out: 123,
            deadline: 1_700_000_000,
        }
        .data(),
    );
    check(
        "sell",
        metas(trade()),
        deep_curve::instruction::Sell {
            tokens_in: 1_000_000_000,
            min_sol_out: 123,
            deadline: 1_700_000_000,
        }
        .data(),
    );
}

fn graduate_metas(mint: Pubkey) -> Metas {
    let cp = raydium::CP_SWAP_PROGRAM_ID;
    let c = curve(&mint);
    let pool_creator = pda(&[deep_curve::POOL_CREATOR_SEED], &deep_curve::ID);
    let pool_state = pda(
        &[deep_curve::RAYDIUM_POOL_SEED, mint.as_ref()],
        &deep_curve::ID,
    );
    let lp_mint = pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()], &cp);
    let vault_of = |m: &Pubkey| {
        pda(
            &[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()],
            &cp,
        )
    };
    let wsol = native_mint();
    let (v0, v1) = if wsol < mint {
        (vault_of(&wsol), vault_of(&mint))
    } else {
        (vault_of(&mint), vault_of(&wsol))
    };
    metas(deep_curve::accounts::Graduate {
        config: config(),
        fee_vault: fee_vault(),
        mint,
        curve: c,
        vault: get_associated_token_address(&c, &mint),
        reward_recipient: k(CREATOR),
        pool_creator,
        creator_token: get_associated_token_address(&pool_creator, &mint),
        wsol_mint: wsol,
        creator_wsol: get_associated_token_address(&pool_creator, &wsol),
        creator_lp_token: get_associated_token_address(&pool_creator, &lp_mint),
        pool_state,
        amm_config: k(AMM_CONFIG),
        permission: pda(&[raydium::PERMISSION_SEED, pool_creator.as_ref()], &cp),
        raydium_authority: pda(&[raydium::AUTH_SEED], &cp),
        lp_mint,
        token_0_vault: v0,
        token_1_vault: v1,
        // deep-amm's fee account is a build-time value; the vectors use a stand-in key
        create_pool_fee: k(AMM_FEE_RECEIVER),
        observation_state: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()], &cp),
        cp_swap_program: cp,
        token_program: anchor_spl::token::ID,
        associated_token_program: anchor_spl::associated_token::ID,
        system_program: anchor_lang::system_program::ID,
    })
}

/// `graduate` hand-encodes its CPI into deep-amm, so the constants it uses are pinned to
/// the deep-amm crate here: the instruction discriminator, the `CreatorFeeOn` tags, the
/// `Permission` seed and the account count/order of `InitializeWithPermission`.
#[test]
fn graduation_cpi_constants_match_deep_amm() {
    use anchor_lang::Discriminator;
    use deep_amm::states::CreatorFeeOn;
    assert_eq!(
        raydium::INITIALIZE_WITH_PERMISSION_DISCRIMINATOR,
        deep_amm::instruction::InitializeWithPermission::DISCRIMINATOR
    );
    assert_eq!(
        raydium::CREATOR_FEE_ON_ONLY_TOKEN_0,
        CreatorFeeOn::OnlyToken0.to_u8()
    );
    assert_eq!(
        raydium::CREATOR_FEE_ON_ONLY_TOKEN_1,
        CreatorFeeOn::OnlyToken1.to_u8()
    );
    assert_eq!(
        raydium::PERMISSION_SEED,
        deep_amm::states::PERMISSION_SEED.as_bytes()
    );
    // the encoded argument tail: the Borsh enum tag is the same single byte
    let data = deep_amm::instruction::InitializeWithPermission {
        init_amount_0: 1,
        init_amount_1: 2,
        open_time: 0,
        creator_fee_on: CreatorFeeOn::OnlyToken1,
    }
    .data();
    assert_eq!(data.len(), 8 + 8 + 8 + 8 + 1);
    assert_eq!(data[32], raydium::CREATOR_FEE_ON_ONLY_TOKEN_1);

    // DEEP V1: the same accounts, a new discriminator and two more arguments: the reward
    // model (u8) and the token's reward rate (u64 LE, per 1e6 = bps * RATE_PER_BPS)
    assert_eq!(
        raydium::INITIALIZE_WITH_PERMISSION_V1_DISCRIMINATOR,
        deep_amm::instruction::InitializeWithPermissionV1::DISCRIMINATOR
    );
    let v1 = deep_amm::instruction::InitializeWithPermissionV1 {
        init_amount_0: 1,
        init_amount_1: 2,
        open_time: 0,
        creator_fee_on: CreatorFeeOn::OnlyToken1,
        reward_model: deep_curve::math::REWARD_MODEL_HOLDER,
        reward_rate: 250 * raydium::RATE_PER_BPS,
    }
    .data();
    assert_eq!(v1.len(), data.len() + 1 + 8);
    assert_eq!(v1[8..33], data[8..33]);
    assert_eq!(v1[33], deep_curve::math::REWARD_MODEL_HOLDER);
    assert_eq!(v1[34..42], 25_000u64.to_le_bytes());
    // bps -> per 1e6, and the two reward caps are the same rate
    assert_eq!(
        raydium::RATE_PER_BPS * 10_000,
        deep_amm::curve::FEE_RATE_DENOMINATOR_VALUE
    );
    assert_eq!(
        u64::from(deep_curve::math::MAX_REWARD_BPS) * raydium::RATE_PER_BPS,
        deep_amm::deep_keys::MAX_REWARD_RATE
    );
    assert_eq!(
        u64::from(deep_curve::math::MAX_TOTAL_FEE_BPS) * raydium::RATE_PER_BPS,
        deep_amm::deep_keys::MAX_TOTAL_FEE_RATE
    );
    // the reward-model numbers and the AmmConfig fee-model byte graduate reads
    assert_eq!(
        (
            deep_amm::states::REWARD_MODEL_STANDARD,
            deep_amm::states::REWARD_MODEL_CREATOR,
            deep_amm::states::REWARD_MODEL_HOLDER
        ),
        (
            deep_curve::math::REWARD_MODEL_STANDARD,
            deep_curve::math::REWARD_MODEL_CREATOR,
            deep_curve::math::REWARD_MODEL_HOLDER
        )
    );
    assert_eq!(raydium::AMM_CONFIG_FEE_MODEL_OFFSET, 124);
    assert_eq!((raydium::FEE_MODEL_LEGACY, raydium::FEE_MODEL_V1), (0, 1));
    // deep-amm derives a permissionless Holder pool's recipient from the same program id
    assert_eq!(
        deep_amm::deep_keys::DEEP_REWARDS_PROGRAM_ID,
        deep_curve::DEEP_REWARDS_PROGRAM_ID
    );
    assert_eq!(
        deep_amm::deep_keys::HOLDER_VAULT_SEED,
        deep_curve::HOLDER_VAULT_SEED
    );
    assert_eq!(
        deep_amm::deep_keys::holder_vault_address(&k(7)),
        deep_curve::holder_vault_address(&k(7))
    );

    // account order graduate's CPI relies on: (signer, writable) per position
    let metas = deep_amm::accounts::InitializeWithPermission {
        payer: k(1),
        creator: k(2),
        amm_config: k(3),
        authority: k(4),
        pool_state: k(5),
        token_0_mint: k(6),
        token_1_mint: k(7),
        lp_mint: k(8),
        payer_token_0: k(9),
        payer_token_1: k(10),
        payer_lp_token: k(11),
        token_0_vault: k(12),
        token_1_vault: k(13),
        create_pool_fee: k(14),
        observation_state: k(15),
        permission: k(16),
        token_program: k(17),
        token_0_program: k(18),
        token_1_program: k(19),
        associated_token_program: k(20),
        system_program: k(21),
    }
    .to_account_metas(None);
    assert_eq!(metas.len(), 21);
    for (i, m) in metas.iter().take(16).enumerate() {
        assert_eq!(m.pubkey, k(i as u8 + 1), "account {i} order");
    }
    // payer signs and pays; the recorded creator and the permission are read-only
    assert!(metas[0].is_signer && metas[0].is_writable);
    assert!(!metas[1].is_signer && !metas[1].is_writable);
    assert!(!metas[15].is_signer && !metas[15].is_writable);
}

/// Security review F2 / F4 / F10: what deep-amm and deep-curve compile in is what the SDK
/// derives: the graduation payer (deep-curve's `["pool_creator"]` PDA, held by deep-amm as a
/// constant), the create-pool fee cap, and the addresses that can never be a splitter
/// destination, in the same order.
#[test]
fn compiled_in_constants_match_the_sdk() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let c = &v["constants"];
    let payer = pda(&[deep_curve::POOL_CREATOR_SEED], &deep_curve::ID);
    assert_eq!(deep_amm::deep_keys::GRADUATION_PAYER, payer);
    assert_eq!(c["graduationPayer"], payer.to_string());
    assert_eq!(c["graduationPayerPda"], payer.to_string());
    assert_eq!(
        c["maxCreatePoolFee"],
        deep_amm::deep_keys::MAX_CREATE_POOL_FEE.to_string()
    );
    assert_eq!(deep_amm::deep_keys::MAX_CREATE_POOL_FEE, 150_000_000);
    assert_eq!(deep_amm::deep_keys::create_pool_fee_to_charge(0), 0);
    assert_eq!(
        deep_amm::deep_keys::create_pool_fee_to_charge(149_999_999),
        149_999_999
    );
    assert_eq!(
        deep_amm::deep_keys::create_pool_fee_to_charge(u64::MAX),
        150_000_000
    );
    let never: Vec<String> = deep_curve::never_a_destination(&deep_curve::ID)
        .iter()
        .map(|k| k.to_string())
        .collect();
    let sdk: Vec<String> = c["neverADestination"]
        .as_array()
        .unwrap()
        .iter()
        .map(|k| k.as_str().unwrap().to_string())
        .collect();
    assert_eq!(never, sdk);
    // the distributor a Holder pool requires is deep-rewards' own PDA
    assert_eq!(
        deep_amm::deep_keys::DISTRIBUTOR_SEED,
        deep_rewards::DISTRIBUTOR_SEED
    );
    assert_eq!(
        deep_amm::deep_keys::distributor_address(&k(MINT), &native_mint()),
        pda(
            &[
                deep_rewards::DISTRIBUTOR_SEED,
                k(MINT).as_ref(),
                native_mint().as_ref()
            ],
            &deep_rewards::ID
        )
    );
}

/// The default curve's 1% migration fee covers the capped create-pool fee with room for the
/// pool's rent: a graduation of a default curve never needs a top-up because of the fee.
#[test]
fn the_default_migration_fee_covers_the_create_pool_fee_cap() {
    use deep_curve::math;
    let raised =
        math::sol_in_for_tokens(45_000_000_000, 1_000_000_000_000_000, 800_000_000_000_000)
            .unwrap();
    assert_eq!(raised, 180_000_000_000);
    let migration_fee = raised / 100;
    assert!(migration_fee >= 10 * deep_amm::deep_keys::MAX_CREATE_POOL_FEE);
}

#[test]
fn graduate_instruction_both_mint_orders() {
    assert!(
        native_mint() < k(MINT),
        "fixture assumes WSOL sorts first for MINT"
    );
    assert!(
        k(LOW_MINT) < native_mint(),
        "fixture assumes LOW_MINT sorts before WSOL"
    );
    check(
        "graduate",
        graduate_metas(k(MINT)),
        deep_curve::instruction::Graduate {}.data(),
    );
    check(
        "graduate_low_mint",
        graduate_metas(k(LOW_MINT)),
        deep_curve::instruction::Graduate {}.data(),
    );
}

fn splitter_params() -> deep_curve::SplitterParams {
    deep_curve::SplitterParams {
        destinations: vec![
            deep_curve::DestinationParams {
                wallet: k(DEST1),
                bps: 7_000,
            },
            deep_curve::DestinationParams {
                wallet: k(DEST2),
                bps: 3_000,
            },
        ],
        min_distribute_lamports: 10_000_000,
    }
}

#[test]
fn splitter_instructions() {
    let splitter = pda(&[deep_curve::SPLITTER_SEED], &deep_curve::ID);
    let pending = pda(&[deep_curve::PENDING_SPLITTER_SEED], &deep_curve::ID);
    let vault = fee_vault();
    let vault_wsol = get_associated_token_address(&vault, &native_mint());
    check(
        "initialize_splitter",
        metas(deep_curve::accounts::InitializeSplitter {
            admin: k(ADMIN),
            config: config(),
            splitter,
            fee_vault: vault,
            fee_vault_wsol: vault_wsol,
            wsol_mint: native_mint(),
            token_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::InitializeSplitter {
            params: splitter_params(),
        }
        .data(),
    );
    check(
        "queue_splitter_update",
        metas(deep_curve::accounts::QueueSplitterUpdate {
            admin: k(ADMIN),
            config: config(),
            splitter,
            pending_splitter: pending,
            system_program: anchor_lang::system_program::ID,
        }),
        deep_curve::instruction::QueueSplitterUpdate {
            params: splitter_params(),
        }
        .data(),
    );
    check(
        "apply_splitter_update",
        metas(deep_curve::accounts::ApplySplitterUpdate {
            splitter,
            pending_splitter: pending,
        }),
        deep_curve::instruction::ApplySplitterUpdate {}.data(),
    );
    check(
        "cancel_splitter_update",
        metas(deep_curve::accounts::CancelSplitterUpdate {
            admin: k(ADMIN),
            config: config(),
            pending_splitter: pending,
        }),
        deep_curve::instruction::CancelSplitterUpdate {}.data(),
    );
    // distribute: the struct's accounts, then the destinations (writable, config order)
    let mut d = metas(deep_curve::accounts::Distribute {
        payer: k(PAYER),
        splitter,
        fee_vault: vault,
        fee_vault_wsol: vault_wsol,
        wsol_unwrap: pda(&[deep_curve::WSOL_UNWRAP_SEED], &deep_curve::ID),
        wsol_mint: native_mint(),
        // a build-time value (DEEP_BUILDER_WALLET); the vectors use a stand-in key
        builder: k(BUILDER),
        token_program: anchor_spl::token::ID,
        system_program: anchor_lang::system_program::ID,
    });
    d.push((k(DEST1).to_string(), false, true));
    d.push((k(DEST2).to_string(), false, true));
    check(
        "distribute",
        d,
        deep_curve::instruction::Distribute {}.data(),
    );
    check(
        "withdraw_vault_tokens",
        metas(deep_curve::accounts::WithdrawVaultTokens {
            admin: k(ADMIN),
            config: config(),
            splitter,
            fee_vault: vault,
            mint: k(MINT),
            vault_token: get_associated_token_address(&vault, &k(MINT)),
            recipient_token: k(PAYER),
            token_program: anchor_spl::token::ID,
        }),
        deep_curve::instruction::WithdrawVaultTokens { amount: 42 }.data(),
    );
}

/// deep-rewards is a separate program; deep-curve only compiles in its id and the vault seed.
#[test]
fn holder_vault_is_a_deep_rewards_pda() {
    assert_eq!(
        deep_curve::DEEP_REWARDS_PROGRAM_ID.to_string(),
        "4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2"
    );
    assert_eq!(deep_curve::HOLDER_VAULT_SEED, b"holder_vault");
    let mint = k(MINT);
    let vault = deep_curve::holder_vault_address(&mint);
    assert_eq!(
        vault,
        pda(
            &[b"holder_vault", mint.as_ref()],
            &deep_curve::DEEP_REWARDS_PROGRAM_ID
        )
    );
    // never a deep-curve address: deep-curve cannot sign for it, only deep-rewards can
    assert_ne!(
        vault,
        pda(&[b"holder_vault", mint.as_ref()], &deep_curve::ID)
    );
    assert_ne!(vault, fee_vault());
    assert_ne!(vault, deep_curve::holder_vault_address(&k(LOW_MINT)));
    assert_eq!(deep_curve::math::REWARD_MODEL_STANDARD, 0);
    assert_eq!(deep_curve::math::REWARD_MODEL_CREATOR, 1);
    assert_eq!(deep_curve::math::REWARD_MODEL_HOLDER, 2);
}

/// The fee vault is the same address on every cluster (one deep-curve program id). The SDK,
/// docs and release configs hard-code it; deep-amm compiles it in (DEEP_FEE_VAULT), and its
/// WSOL ATA as the create-pool fee receiver (DEEP_AMM_CREATE_POOL_FEE_RECEIVER).
#[test]
fn fee_vault_address_is_pinned_and_matches_deep_amm_build_keys() {
    assert_eq!(
        fee_vault().to_string(),
        "8a2XakVBzdMRJ6gMY6u8mvebzJGgbmG6nVBVPB8uwBVZ"
    );
    let wsol = get_associated_token_address(&fee_vault(), &native_mint());
    assert_eq!(
        wsol.to_string(),
        "EcnANJ5kYr7a8LpiH4ETkSGD3r7SDdicUn9ttf5MWCir"
    );
    let unset = anchor_lang::system_program::ID;
    // A configured build must name exactly this vault (an unconfigured build fails closed).
    let fv = deep_amm::deep_keys::FEE_VAULT;
    assert!(
        fv == unset || fv == fee_vault(),
        "DEEP_FEE_VAULT != fee_vault PDA"
    );
    let recv = deep_curve::raydium::CREATE_POOL_FEE_RECEIVER;
    if fv != unset {
        assert_eq!(
            recv, wsol,
            "DEEP_AMM_CREATE_POOL_FEE_RECEIVER != ATA(WSOL, fee vault)"
        );
    }
    assert_eq!(deep_curve::BUILDER_SPLIT_BPS, 1_000);
    assert_eq!(deep_amm::deep_keys::BUILDER_FUND_FEE_RATE, 0);
}
