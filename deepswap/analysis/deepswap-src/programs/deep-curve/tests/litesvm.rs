//! LiteSVM integration tests: run the compiled SBF program (`deep_curve.so`) together
//! with SPL Token / ATA (bundled with LiteSVM) and the Metaplex token-metadata program.
//!
//! Requires the `litesvm-tests` feature and env vars pointing at SBF binaries/accounts:
//!   DEEP_CURVE_SO           target/deploy/deep_curve.so (from `cargo build-sbf`)
//!   DEEP_CURVE_DEVNET_SO    the same program built with `--features devnet` (600 s price age)
//!   MPL_TOKEN_METADATA_SO   Metaplex token-metadata .so (dumped from devnet)
//!   DEEP_AMM_SO             deep_amm.so built from programs/deep-amm (NOT a devnet dump)
//!   AMM_ADMIN_KEYPAIR / AMM_FEE_OWNER_KEYPAIR / BUILDER_KEYPAIR
//!       throwaway test keys whose pubkeys were compiled into deep_amm.so (and deep_curve.so)
//!       via DEEP_AMM_ADMIN / DEEP_AMM_FEE_OWNER / DEEP_BUILDER_WALLET. DEEP_FEE_VAULT and
//!       DEEP_AMM_CREATE_POOL_FEE_RECEIVER are the real fee vault and its WSOL ATA.
//! `node scripts/programs-test.mjs --sbf` sets all of this up inside Docker.

use anchor_lang::prelude::{AccountDeserialize, Pubkey};
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::{InstructionData, Space, ToAccountMetas};
use anchor_spl::associated_token::get_associated_token_address;
use anchor_spl::token::{Mint, TokenAccount};
use deep_curve::math::{self, Curve, Fees};
use deep_curve::{
    raydium, BondingCurve, Config, ConfigParams, DeepError, DestinationParams, SplitterConfig,
    SplitterParams, CONFIG_SEED, CURVE_SEED, FEE_VAULT_SEED, PENDING_SPLITTER_SEED,
    POOL_CREATOR_SEED, RAYDIUM_POOL_SEED, SPLITTER_SEED, TREASURY_SEED, WSOL_UNWRAP_SEED,
};
use litesvm::types::TransactionMetadata;
use litesvm::LiteSVM;
use solana_instruction_error::InstructionError;
use solana_keypair::Keypair;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_transaction_error::TransactionError;

const SOL: u64 = 1_000_000_000;
const UNIT: u64 = 1_000_000;
const NO_DEADLINE: i64 = i64::MAX;

fn so_path(var: &str) -> String {
    std::env::var(var)
        .unwrap_or_else(|_| panic!("{var} is not set; run `node scripts/programs-test.mjs --sbf`"))
}

fn params(fee_recipient: Pubkey, migration_authority: Pubkey) -> ConfigParams {
    ConfigParams {
        fee_recipient,
        migration_authority,
        protocol_fee_bps: 70,
        creator_fee_bps: 30,
        migration_fee_bps: 100,
        initial_virtual_sol: 45 * SOL,
        initial_virtual_token: 1_000_000_000 * UNIT,
        curve_supply: 800_000_000 * UNIT,
        token_total_supply: 1_000_000_000 * UNIT,
        decimals: 6,
        raydium_amm_config: amm_config_0(),
        timelock_seconds: 0,
        launch_fee_usd_cents: 0,
        // the pre-V1 devnet schedule: the same protocol rate on both sides, no curve reward
        sell_protocol_fee_bps: 70,
        // the current maximum reward rate a creator may choose: the ceiling
        max_reward_bps: 500,
        reserved_bps: 0,
    }
}

fn config_pda() -> Pubkey {
    Pubkey::find_program_address(&[CONFIG_SEED], &deep_curve::ID).0
}

fn curve_pda(mint: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(&[CURVE_SEED, mint.as_ref()], &deep_curve::ID).0
}

fn metadata_pda(mint: &Pubkey) -> Pubkey {
    let mpl = anchor_spl::metadata::ID;
    Pubkey::find_program_address(&[b"metadata", mpl.as_ref(), mint.as_ref()], &mpl).0
}

fn treasury_pda() -> Pubkey {
    Pubkey::find_program_address(&[TREASURY_SEED], &deep_curve::ID).0
}

fn fee_vault_pda() -> Pubkey {
    Pubkey::find_program_address(&[FEE_VAULT_SEED], &deep_curve::ID).0
}

fn fee_vault_wsol() -> Pubkey {
    get_associated_token_address(&fee_vault_pda(), &NATIVE_MINT)
}

fn splitter_pda() -> Pubkey {
    Pubkey::find_program_address(&[SPLITTER_SEED], &deep_curve::ID).0
}

fn pending_splitter_pda() -> Pubkey {
    Pubkey::find_program_address(&[PENDING_SPLITTER_SEED], &deep_curve::ID).0
}

fn program_data_pda() -> Pubkey {
    Pubkey::find_program_address(&[deep_curve::ID.as_ref()], &BPF_LOADER_UPGRADEABLE).0
}

const BPF_LOADER_UPGRADEABLE: Pubkey =
    Pubkey::from_str_const("BPFLoaderUpgradeab1e11111111111111111111111");

/// VM with deep_curve loaded under the upgradeable loader. LiteSVM writes
/// `upgrade_authority_address: None` into ProgramData; we patch the
/// UpgradeableLoaderState::ProgramData header (u32 tag, u64 slot, Option<Pubkey>)
/// so tests can model a real deploy's upgrade authority.
fn vm(upgrade_authority: Option<Pubkey>) -> LiteSVM {
    let mut svm = LiteSVM::new();
    svm.add_program_from_file(deep_curve::ID, so_path("DEEP_CURVE_SO"))
        .expect("load deep_curve.so");
    svm.add_program_from_file(anchor_spl::metadata::ID, so_path("MPL_TOKEN_METADATA_SO"))
        .expect("load mpl_token_metadata.so");
    let pd = program_data_pda();
    let mut acc = svm.get_account(&pd).expect("programdata");
    assert_eq!(&acc.data[0..4], &3u32.to_le_bytes(), "ProgramData tag");
    match upgrade_authority {
        Some(a) => {
            acc.data[12] = 1;
            acc.data[13..45].copy_from_slice(a.as_ref());
        }
        None => acc.data[12] = 0,
    }
    svm.set_account(pd, acc).expect("patch programdata");
    svm.add_program_from_file(deep_amm::ID, so_path("DEEP_AMM_SO"))
        .expect("load deep_amm.so");
    // WSOL native mint (exists on every cluster; LiteSVM does not create it).
    let mut mint = vec![0u8; 82];
    mint[44] = 9; // decimals
    mint[45] = 1; // is_initialized
    let rent = svm.minimum_balance_for_rent_exemption(82);
    svm.set_account(
        NATIVE_MINT,
        solana_account::Account {
            lamports: rent,
            data: mint,
            owner: anchor_spl::token::ID,
            executable: false,
            rent_epoch: 0,
        },
    )
    .expect("native mint");
    setup_deep_amm(&mut svm);
    // The builder wallet holds exactly its 0-byte rent minimum (the rollout funds it once), so
    // every later balance change is the builder share and nothing else.
    let builder = load_keypair("BUILDER_KEYPAIR");
    assert_eq!(
        builder.pubkey(),
        deep_curve::BUILDER_WALLET,
        "deep_curve.so built with another DEEP_BUILDER_WALLET"
    );
    assert_eq!(builder.pubkey(), deep_amm::deep_keys::BUILDER);
    let rent0 = svm.minimum_balance_for_rent_exemption(0);
    svm.airdrop(&builder.pubkey(), rent0).unwrap();
    svm
}

/// The compiled-in builder wallet's balance minus its rent minimum: what it has been paid.
fn builder_paid(env: &Env) -> u64 {
    env.lamports(&deep_curve::BUILDER_WALLET) - env.svm.minimum_balance_for_rent_exemption(0)
}

/// DEEP revenue sitting in the fee vault (balance above its 0-byte rent minimum).
fn vault_revenue(env: &Env) -> u64 {
    env.lamports(&fee_vault_pda()) - env.svm.minimum_balance_for_rent_exemption(0)
}

fn load_keypair(var: &str) -> Keypair {
    let bytes: Vec<u8> =
        serde_json::from_str(&std::fs::read_to_string(so_path(var)).expect("read keypair"))
            .unwrap();
    Keypair::try_from(bytes.as_slice()).expect("keypair")
}

/// AmmConfig we create for DeepSwap (DEEP V1 Phase 1): 0.30% trade fee, 333_333 / 1e6 of it
/// to DEEP (collected only into the fee vault), fund fee 0 (the only rate deep-amm accepts),
/// so LPs keep 666_667 / 1e6; creator fee off. create_amm_config ARGS.
const AMM_TRADE_FEE_RATE: u64 = 3_000;
const AMM_PROTOCOL_FEE_RATE: u64 = 333_333;
const AMM_FUND_FEE_RATE: u64 = deep_amm::deep_keys::BUILDER_FUND_FEE_RATE;
const AMM_CREATE_POOL_FEE: u64 = 150_000_000;
const AMM_CREATOR_FEE_RATE: u64 = 0;

/// deep-amm `Permission` PDA of `authority`.
fn permission_pda(authority: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(
        &[raydium::PERMISSION_SEED, authority.as_ref()],
        &deep_amm::ID,
    )
    .0
}

fn amm_config_0() -> Pubkey {
    Pubkey::find_program_address(&[b"amm_config", &0u16.to_be_bytes()], &deep_amm::ID).0
}

/// Creates AmmConfig #0 (signed by the compiled-in admin). DEEP V1: its protocol owner is the
/// fee vault and the create-pool fee receiver is the vault's WSOL ATA, which
/// `initialize_splitter` creates (Env::new).
fn setup_deep_amm(svm: &mut LiteSVM) {
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let fee_owner = load_keypair("AMM_FEE_OWNER_KEYPAIR");
    assert_eq!(
        admin.pubkey(),
        deep_amm::admin::ID,
        "deep_amm.so built with another DEEP_AMM_ADMIN"
    );
    assert_eq!(
        deep_amm::deep_keys::FEE_VAULT,
        fee_vault_pda(),
        "deep_amm.so built with another DEEP_FEE_VAULT"
    );
    assert_eq!(deep_amm::protocol_fee_owner::ID, fee_vault_pda());
    assert_eq!(
        deep_amm::create_pool_fee_reveiver::ID,
        fee_vault_wsol(),
        "DEEP_AMM_CREATE_POOL_FEE_RECEIVER must be the fee vault's WSOL ATA"
    );
    svm.airdrop(&admin.pubkey(), 10 * SOL).unwrap();
    svm.airdrop(&fee_owner.pubkey(), 10 * SOL).unwrap();
    let create_cfg = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreateAmmConfig {
            owner: admin.pubkey(),
            amm_config: amm_config_0(),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreateAmmConfig {
            index: 0,
            trade_fee_rate: AMM_TRADE_FEE_RATE,
            protocol_fee_rate: AMM_PROTOCOL_FEE_RATE,
            fund_fee_rate: AMM_FUND_FEE_RATE,
            create_pool_fee: AMM_CREATE_POOL_FEE,
            creator_fee_rate: AMM_CREATOR_FEE_RATE,
        }
        .data(),
    };
    // The Permission PDA that lets deep-curve's pool-creator PDA call
    // `initialize_with_permission` (created once by the deep-amm admin).
    let pool_creator = Pubkey::find_program_address(&[POOL_CREATOR_SEED], &deep_curve::ID).0;
    let create_permission = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreatePermissionPda {
            owner: admin.pubkey(),
            permission_authority: pool_creator,
            permission: permission_pda(&pool_creator),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreatePermissionPda {}.data(),
    };
    let tx = Transaction::new_signed_with_payer(
        &[create_cfg, create_permission],
        Some(&admin.pubkey()),
        &[&admin],
        svm.latest_blockhash(),
    );
    svm.send_transaction(tx).expect("deep-amm setup");
    svm.expire_blockhash();
}

const NATIVE_MINT: Pubkey = Pubkey::from_str_const("So11111111111111111111111111111111111111112");
const COMPUTE_BUDGET: Pubkey =
    Pubkey::from_str_const("ComputeBudget111111111111111111111111111111");
const GRADUATE_CU_LIMIT: u32 = 400_000;
/// Position of `reward_recipient` in `deep_curve::accounts::Graduate` (no signer account).
const GRADUATE_REWARD_RECIPIENT: usize = 5;

fn cu_limit_ix(units: u32) -> Instruction {
    let mut data = vec![2u8];
    data.extend_from_slice(&units.to_le_bytes());
    Instruction {
        program_id: COMPUTE_BUDGET,
        accounts: vec![],
        data,
    }
}

/// Every address the Raydium CPMM graduation touches for `mint`.
struct PoolKeys {
    pool_creator: Pubkey,
    permission: Pubkey,
    pool_state: Pubkey,
    authority: Pubkey,
    lp_mint: Pubkey,
    token_vault: Pubkey,
    wsol_vault: Pubkey,
    observation: Pubkey,
    creator_token: Pubkey,
    creator_wsol: Pubkey,
    creator_lp: Pubkey,
}

fn pool_keys(mint: &Pubkey) -> PoolKeys {
    let cp = raydium::CP_SWAP_PROGRAM_ID;
    let pda = |seeds: &[&[u8]], p: &Pubkey| Pubkey::find_program_address(seeds, p).0;
    // one pool-creator PDA for every graduation (its deep-amm Permission is per payer)
    let pool_creator = pda(&[POOL_CREATOR_SEED], &deep_curve::ID);
    let pool_state = pda(&[RAYDIUM_POOL_SEED, mint.as_ref()], &deep_curve::ID);
    let lp_mint = pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()], &cp);
    PoolKeys {
        pool_creator,
        permission: permission_pda(&pool_creator),
        pool_state,
        authority: pda(&[raydium::AUTH_SEED], &cp),
        lp_mint,
        token_vault: pda(
            &[raydium::POOL_VAULT_SEED, pool_state.as_ref(), mint.as_ref()],
            &cp,
        ),
        wsol_vault: pda(
            &[
                raydium::POOL_VAULT_SEED,
                pool_state.as_ref(),
                NATIVE_MINT.as_ref(),
            ],
            &cp,
        ),
        observation: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()], &cp),
        creator_token: get_associated_token_address(&pool_creator, mint),
        creator_wsol: get_associated_token_address(&pool_creator, &NATIVE_MINT),
        creator_lp: get_associated_token_address(&pool_creator, &lp_mint),
    }
}

fn pending_config_pda() -> Pubkey {
    Pubkey::find_program_address(&[deep_curve::PENDING_CONFIG_SEED], &deep_curve::ID).0
}

fn custom(e: DeepError) -> u32 {
    anchor_lang::error::ERROR_CODE_OFFSET + e as u32
}

struct Env {
    svm: LiteSVM,
    admin: Keypair,
    fee_recipient: Keypair,
    migration: Keypair,
    creator: Keypair,
    /// The single 90% splitter destination (Phase 1: the DEEP Treasury wallet).
    treasury_wallet: Keypair,
}

struct Token {
    mint: Pubkey,
    curve: Pubkey,
    vault: Pubkey,
}

impl Env {
    /// Fresh VM with the program loaded and `initialize_config` executed.
    fn new() -> Self {
        let admin = Keypair::new();
        let mut svm = vm(Some(admin.pubkey()));
        // fee_recipient is deliberately left unfunded (0 lamports): fees accrue in the
        // treasury PDA, so trades must not depend on the recipient being rent-exempt.
        let fee_recipient = Keypair::new();
        let migration = Keypair::new();
        let creator = Keypair::new();
        for k in [&admin, &migration, &creator] {
            svm.airdrop(&k.pubkey(), 10 * SOL).unwrap();
        }
        let treasury_wallet = Keypair::new();
        svm.airdrop(&treasury_wallet.pubkey(), SOL).unwrap();
        let mut env = Env {
            svm,
            admin,
            fee_recipient,
            migration,
            creator,
            treasury_wallet,
        };
        let p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
        let ix = env.ix_initialize_config(&env.admin.pubkey(), p);
        let admin = env.admin.insecure_clone();
        env.send(ix, &[&admin]).expect("initialize_config");
        let sp = splitter_params(&[(env.treasury_wallet.pubkey(), 10_000)]);
        let ix = env.ix_initialize_splitter(&admin.pubkey(), sp);
        env.send(ix, &[&admin]).expect("initialize_splitter");
        env
    }

    /// Env::new without `initialize_splitter` (fee vault unfunded, no WSOL ATA).
    fn new_without_splitter() -> Self {
        let admin = Keypair::new();
        let mut svm = vm(Some(admin.pubkey()));
        let fee_recipient = Keypair::new();
        let migration = Keypair::new();
        let creator = Keypair::new();
        let treasury_wallet = Keypair::new();
        for k in [&admin, &migration, &creator, &treasury_wallet] {
            svm.airdrop(&k.pubkey(), 10 * SOL).unwrap();
        }
        let mut env = Env {
            svm,
            admin,
            fee_recipient,
            migration,
            creator,
            treasury_wallet,
        };
        let p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
        let ix = env.ix_initialize_config(&env.admin.pubkey(), p);
        let admin = env.admin.insecure_clone();
        env.send(ix, &[&admin]).expect("initialize_config");
        env
    }

    fn splitter(&self) -> SplitterConfig {
        self.load(&splitter_pda())
    }

    fn ix_initialize_splitter(&self, admin: &Pubkey, p: SplitterParams) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::InitializeSplitter {
                admin: *admin,
                config: config_pda(),
                splitter: splitter_pda(),
                fee_vault: fee_vault_pda(),
                fee_vault_wsol: fee_vault_wsol(),
                wsol_mint: NATIVE_MINT,
                token_program: anchor_spl::token::ID,
                associated_token_program: anchor_spl::associated_token::ID,
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::InitializeSplitter { params: p }.data(),
        }
    }

    fn ix_queue_splitter(&self, admin: &Pubkey, p: SplitterParams) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::QueueSplitterUpdate {
                admin: *admin,
                config: config_pda(),
                splitter: splitter_pda(),
                pending_splitter: pending_splitter_pda(),
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::QueueSplitterUpdate { params: p }.data(),
        }
    }

    fn ix_apply_splitter(&self) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::ApplySplitterUpdate {
                splitter: splitter_pda(),
                pending_splitter: pending_splitter_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::ApplySplitterUpdate {}.data(),
        }
    }

    fn ix_cancel_splitter(&self, admin: &Pubkey) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::CancelSplitterUpdate {
                admin: *admin,
                config: config_pda(),
                pending_splitter: pending_splitter_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::CancelSplitterUpdate {}.data(),
        }
    }

    /// `distribute` with an explicit payer, builder account and destination list.
    fn ix_distribute_with(&self, payer: Pubkey, builder: Pubkey, dests: &[Pubkey]) -> Instruction {
        use anchor_lang::prelude::AccountMeta;
        let mut accounts = deep_curve::accounts::Distribute {
            payer,
            splitter: splitter_pda(),
            fee_vault: fee_vault_pda(),
            fee_vault_wsol: fee_vault_wsol(),
            wsol_unwrap: Pubkey::find_program_address(&[WSOL_UNWRAP_SEED], &deep_curve::ID).0,
            wsol_mint: NATIVE_MINT,
            builder,
            token_program: anchor_spl::token::ID,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None);
        accounts.extend(dests.iter().map(|d| AccountMeta::new(*d, false)));
        Instruction {
            program_id: deep_curve::ID,
            accounts,
            data: deep_curve::instruction::Distribute {}.data(),
        }
    }

    /// `distribute` for the configured destinations, sent by a fresh, unrelated cranker.
    fn distribute(&mut self) -> Result<TransactionMetadata, u32> {
        let dests: Vec<Pubkey> = self.splitter().active().iter().map(|d| d.wallet).collect();
        let cranker = self.user(SOL);
        let ix = self.ix_distribute_with(cranker.pubkey(), deep_curve::BUILDER_WALLET, &dests);
        self.send_ixs(vec![cu_limit_ix(400_000), ix], &[&cranker])
    }

    fn send(&mut self, ix: Instruction, signers: &[&Keypair]) -> Result<TransactionMetadata, u32> {
        self.send_ixs(vec![ix], signers)
    }

    /// Sends a transaction; on failure returns the custom error code (or u32::MAX).
    fn send_ixs(
        &mut self,
        ixs: Vec<Instruction>,
        signers: &[&Keypair],
    ) -> Result<TransactionMetadata, u32> {
        let tx = Transaction::new_signed_with_payer(
            &ixs,
            Some(&signers[0].pubkey()),
            signers,
            self.svm.latest_blockhash(),
        );
        let r = self.svm.send_transaction(tx);
        self.svm.expire_blockhash();
        r.map_err(|f| match f.err {
            TransactionError::InstructionError(_, InstructionError::Custom(c)) => c,
            other => {
                eprintln!("non-custom failure: {other:?}\n{}", f.meta.logs.join("\n"));
                u32::MAX
            }
        })
    }

    fn user(&mut self, lamports: u64) -> Keypair {
        let k = Keypair::new();
        self.svm.airdrop(&k.pubkey(), lamports).unwrap();
        k
    }

    fn lamports(&self, k: &Pubkey) -> u64 {
        self.svm.get_balance(k).unwrap_or(0)
    }

    fn load<T: AccountDeserialize>(&self, k: &Pubkey) -> T {
        let acc = self.svm.get_account(k).expect("account exists");
        T::try_deserialize(&mut acc.data.as_slice()).expect("deserialize")
    }

    fn curve(&self, t: &Token) -> BondingCurve {
        self.load(&t.curve)
    }

    fn token_balance(&self, owner: &Pubkey, mint: &Pubkey) -> u64 {
        let ata = get_associated_token_address(owner, mint);
        match self.svm.get_account(&ata) {
            Some(_) => self.load::<TokenAccount>(&ata).amount,
            None => 0,
        }
    }

    // ── instruction builders ──

    fn ix_initialize_config(&self, admin: &Pubkey, p: ConfigParams) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::InitializeConfig {
                admin: *admin,
                config: config_pda(),
                treasury: treasury_pda(),
                program: deep_curve::ID,
                program_data: program_data_pda(),
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::InitializeConfig { params: p }.data(),
        }
    }

    fn admin_accounts(admin: &Pubkey) -> Vec<anchor_lang::prelude::AccountMeta> {
        deep_curve::accounts::AdminOnly {
            admin: *admin,
            config: config_pda(),
        }
        .to_account_metas(None)
    }

    fn ix_set_paused(&self, admin: &Pubkey, paused: bool) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: Self::admin_accounts(admin),
            data: deep_curve::instruction::SetPaused { paused }.data(),
        }
    }

    fn ix_queue_config(&self, admin: &Pubkey, p: ConfigParams) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::QueueConfigUpdate {
                admin: *admin,
                config: config_pda(),
                pending_config: pending_config_pda(),
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::QueueConfigUpdate { params: p }.data(),
        }
    }

    fn ix_apply_config(&self) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::ApplyConfigUpdate {
                config: config_pda(),
                pending_config: pending_config_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::ApplyConfigUpdate {}.data(),
        }
    }

    fn ix_cancel_config(&self, admin: &Pubkey) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::CancelConfigUpdate {
                admin: *admin,
                config: config_pda(),
                pending_config: pending_config_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::CancelConfigUpdate {}.data(),
        }
    }

    /// queue + apply in one transaction (valid while timelock_seconds == 0).
    fn update_config_now(&mut self, p: ConfigParams) -> Result<TransactionMetadata, u32> {
        let admin = self.admin.insecure_clone();
        let ixs = vec![
            self.ix_queue_config(&admin.pubkey(), p),
            self.ix_apply_config(),
        ];
        self.send_ixs(ixs, &[&admin])
    }

    fn set_unix_time(&mut self, t: i64) {
        let mut clock: anchor_lang::prelude::Clock = self.svm.get_sysvar();
        clock.unix_timestamp = t;
        self.svm.set_sysvar(&clock);
    }

    fn ix_propose_admin(&self, admin: &Pubkey, new_admin: Pubkey) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: Self::admin_accounts(admin),
            data: deep_curve::instruction::ProposeAdmin { new_admin }.data(),
        }
    }

    fn ix_accept_admin(&self, pending: &Pubkey) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::AcceptAdmin {
                pending_admin: *pending,
                config: config_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::AcceptAdmin {}.data(),
        }
    }

    fn ix_create_token(&self, creator: &Pubkey, mint: &Pubkey, name: &str) -> Instruction {
        // What the pre-V1 tests' creator launches: a Creator token at the Config's legacy
        // creator fee (30 bps in `params()`), i.e. the terms those tests were written for; a
        // Standard token when that is 0. (Before the sixth round the Config imposed that fee.)
        // (read raw at Config.creator_fee_bps, offset 138: the same in every layout version,
        // and some tests hold a downgraded Config)
        let cfg = self.svm.get_account(&config_pda()).expect("config").data;
        let legacy_fee = u16::from_le_bytes([cfg[138], cfg[139]]);
        let default_reward = if legacy_fee > 0 {
            (deep_curve::math::REWARD_MODEL_CREATOR, legacy_fee)
        } else {
            (deep_curve::math::REWARD_MODEL_STANDARD, 0)
        };
        let curve = curve_pda(mint);
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::CreateToken {
                creator: *creator,
                config: config_pda(),
                mint: *mint,
                curve,
                vault: get_associated_token_address(&curve, mint),
                metadata: metadata_pda(mint),
                price_update: deep_curve::pyth::SOL_USD_PRICE_UPDATE,
                token_program: anchor_spl::token::ID,
                associated_token_program: anchor_spl::associated_token::ID,
                token_metadata_program: anchor_spl::metadata::ID,
                system_program: anchor_lang::system_program::ID,
                rent: "SysvarRent111111111111111111111111111111111"
                    .parse()
                    .unwrap(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::CreateToken {
                name: name.to_string(),
                symbol: "DEEP".to_string(),
                uri: "https://example.invalid/deep.json".to_string(),
                reward_model: default_reward.0,
                reward_bps: default_reward.1,
                // no limit, unless a test sets one (`with_max_launch_fee`)
                max_launch_fee_lamports: u64::MAX,
            }
            .data(),
        }
    }

    fn trade_accounts(&self, t: &Token, user: &Pubkey) -> Vec<anchor_lang::prelude::AccountMeta> {
        deep_curve::accounts::Trade {
            user: *user,
            config: config_pda(),
            mint: t.mint,
            curve: t.curve,
            vault: t.vault,
            user_token: get_associated_token_address(user, &t.mint),
            token_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None)
    }

    fn ix_buy(
        &self,
        t: &Token,
        user: &Pubkey,
        sol_in: u64,
        min_out: u64,
        deadline: i64,
    ) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: self.trade_accounts(t, user),
            data: deep_curve::instruction::Buy {
                sol_in,
                min_tokens_out: min_out,
                deadline,
            }
            .data(),
        }
    }

    fn ix_sweep(&self, t: &Token) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::SweepProtocolFees {
                curve: t.curve,
                fee_vault: fee_vault_pda(),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::SweepProtocolFees {}.data(),
        }
    }

    fn ix_sell(
        &self,
        t: &Token,
        user: &Pubkey,
        tokens_in: u64,
        min_sol_out: u64,
        deadline: i64,
    ) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: self.trade_accounts(t, user),
            data: deep_curve::instruction::Sell {
                tokens_in,
                min_sol_out,
                deadline,
            }
            .data(),
        }
    }

    fn ix_claim(&self, t: &Token, creator: &Pubkey) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::ClaimCreatorFees {
                creator: *creator,
                curve: t.curve,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::ClaimCreatorFees {}.data(),
        }
    }

    fn ix_graduate(&self, t: &Token, authority: &Pubkey) -> Instruction {
        // the AmmConfig deep-curve is currently pointed at (#0 legacy, or the V1 config)
        let cfg: deep_curve::Config = self.load(&config_pda());
        self.ix_graduate_with(
            t,
            authority,
            cfg.raydium_amm_config,
            raydium::CP_SWAP_PROGRAM_ID,
        )
    }

    fn ix_graduate_with(
        &self,
        t: &Token,
        authority: &Pubkey,
        amm_config: Pubkey,
        cp_swap_program: Pubkey,
    ) -> Instruction {
        // The reward recipient the program expects: the token's holder vault for a Holder
        // token (passed writable, so graduate can sweep the curve's holder fees), otherwise
        // the token's creator (read-only).
        let c = self.curve(t);
        let recipient = deep_curve::reward_recipient_address(&c);
        let mut ix = self.ix_graduate_as(t, authority, amm_config, cp_swap_program, recipient);
        if c.reward_model == math::REWARD_MODEL_HOLDER {
            assert_eq!(ix.accounts[GRADUATE_REWARD_RECIPIENT].pubkey, recipient);
            ix.accounts[GRADUATE_REWARD_RECIPIENT].is_writable = true;
        }
        ix
    }

    /// `graduate` naming `token_creator` as the pool's reward recipient (read-only).
    fn ix_graduate_as(
        &self,
        t: &Token,
        _sender: &Pubkey,
        amm_config: Pubkey,
        cp_swap_program: Pubkey,
        token_creator: Pubkey,
    ) -> Instruction {
        let k = pool_keys(&t.mint);
        let wsol_first = NATIVE_MINT < t.mint;
        let (v0, v1) = if wsol_first {
            (k.wsol_vault, k.token_vault)
        } else {
            (k.token_vault, k.wsol_vault)
        };
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::Graduate {
                config: config_pda(),
                fee_vault: fee_vault_pda(),
                mint: t.mint,
                curve: t.curve,
                vault: t.vault,
                reward_recipient: token_creator,
                pool_creator: k.pool_creator,
                creator_token: k.creator_token,
                wsol_mint: NATIVE_MINT,
                creator_wsol: k.creator_wsol,
                creator_lp_token: k.creator_lp,
                pool_state: k.pool_state,
                amm_config,
                permission: k.permission,
                raydium_authority: k.authority,
                lp_mint: k.lp_mint,
                token_0_vault: v0,
                token_1_vault: v1,
                create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
                observation_state: k.observation,
                cp_swap_program,
                token_program: anchor_spl::token::ID,
                associated_token_program: anchor_spl::associated_token::ID,
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::Graduate {}.data(),
        }
    }

    fn graduate(&mut self, t: &Token, authority: &Keypair) -> Result<TransactionMetadata, u32> {
        let ix = self.ix_graduate(t, &authority.pubkey());
        self.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[authority])
    }

    fn ix_withdraw(&self, admin: &Pubkey, fee_recipient: &Pubkey, amount: u64) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::WithdrawProtocolFees {
                admin: *admin,
                config: config_pda(),
                treasury: treasury_pda(),
                fee_recipient: *fee_recipient,
            }
            .to_account_metas(None),
            data: deep_curve::instruction::WithdrawProtocolFees { amount }.data(),
        }
    }

    // ── flows ──

    fn create_token(&mut self) -> (Token, TransactionMetadata) {
        self.create_token_with(Keypair::new())
    }

    /// Mint keypair chosen so that WSOL sorts before (true) / after (false) it,
    /// exercising both Raydium token_0/token_1 orderings.
    fn create_token_ordered(&mut self, wsol_first: bool) -> Token {
        loop {
            let k = Keypair::new();
            if (NATIVE_MINT < k.pubkey()) == wsol_first {
                return self.create_token_with(k).0;
            }
        }
    }

    fn create_token_with(&mut self, mint: Keypair) -> (Token, TransactionMetadata) {
        let creator = self.creator.insecure_clone();
        let ix = self.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Deep Test");
        let meta = self.send(ix, &[&creator, &mint]).expect("create_token");
        let curve = curve_pda(&mint.pubkey());
        let t = Token {
            mint: mint.pubkey(),
            curve,
            vault: get_associated_token_address(&curve, &mint.pubkey()),
        };
        (t, meta)
    }

    fn buy(&mut self, t: &Token, user: &Keypair, sol_in: u64) -> Result<TransactionMetadata, u32> {
        let ix = self.ix_buy(t, &user.pubkey(), sol_in, 0, NO_DEADLINE);
        self.send(ix, &[user])
    }

    fn complete_curve(&mut self, t: &Token) -> Keypair {
        let whale = self.user(2_000 * SOL);
        self.buy(t, &whale, 1_000 * SOL).expect("whale buy");
        assert!(self.curve(t).complete);
        whale
    }
}

fn splitter_params(dests: &[(Pubkey, u16)]) -> SplitterParams {
    SplitterParams {
        destinations: dests
            .iter()
            .map(|(wallet, bps)| DestinationParams {
                wallet: *wallet,
                bps: *bps,
            })
            .collect(),
        min_distribute_lamports: deep_curve::DEFAULT_MIN_DISTRIBUTE_LAMPORTS,
    }
}

fn to_math(c: &BondingCurve) -> Curve {
    c.to_math()
}

fn fees() -> Fees {
    Fees {
        protocol_fee_bps: 70,
        creator_fee_bps: 30,
    }
}

// ───────────────────────────── tests ─────────────────────────────

#[test]
fn initialize_config_sets_state_and_cannot_rerun() {
    let mut env = Env::new();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.admin, env.admin.pubkey());
    assert_eq!(cfg.fee_recipient, env.fee_recipient.pubkey());
    assert_eq!(cfg.migration_authority, env.migration.pubkey());
    assert_eq!(cfg.protocol_fee_bps, 70);
    assert!(!cfg.paused);

    // Config PDA already exists: a second init (by anyone) fails.
    let other = env.user(SOL);
    let p = params(other.pubkey(), other.pubkey());
    let ix = env.ix_initialize_config(&other.pubkey(), p);
    assert!(env.send(ix, &[&other]).is_err());
}

#[test]
fn queue_config_rejects_invalid_params() {
    let mut svm_env = Env::new();
    let admin = svm_env.admin.insecure_clone();
    let mut p = params(svm_env.fee_recipient.pubkey(), svm_env.migration.pubkey());
    p.timelock_seconds = deep_curve::MAX_TIMELOCK_SECONDS + 1;
    let ix = svm_env.ix_queue_config(&admin.pubkey(), p.clone());
    assert_eq!(
        svm_env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InvalidParams)
    );
    p.timelock_seconds = 0;
    p.protocol_fee_bps = 1_000;
    p.creator_fee_bps = 1;
    let ix = svm_env.ix_queue_config(&admin.pubkey(), p);
    assert_eq!(
        svm_env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InvalidFee)
    );
}

#[test]
fn create_token_revokes_mint_authority_and_vaults_full_supply() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let mint: Mint = env.load(&t.mint);
    assert!(
        mint.mint_authority.is_none(),
        "mint authority must be revoked"
    );
    assert!(mint.freeze_authority.is_none());
    assert_eq!(mint.supply, 1_000_000_000 * UNIT);
    assert_eq!(mint.decimals, 6);
    let vault: TokenAccount = env.load(&t.vault);
    assert_eq!(vault.amount, mint.supply);
    assert_eq!(vault.owner, t.curve);
    let c = env.curve(&t);
    // account sizes the SDK decoders rely on (BONDING_CURVE_SIZE / CONFIG_SIZE)
    // v3: +u16 sell_protocol_fee_bps, u8 reward_model, u64 holder_fees_unclaimed
    assert_eq!(env.svm.get_account(&t.curve).unwrap().data.len(), 196);
    // v3: +3 x u16 (sell protocol fee, current maximum reward rate, reserved)
    assert_eq!(env.svm.get_account(&config_pda()).unwrap().data.len(), 221);
    // this test's creator launched a Creator token at 30 bps (see `ix_create_token`)
    assert_eq!(c.reward_model, deep_curve::math::REWARD_MODEL_CREATOR);
    assert_eq!((c.protocol_fee_bps, c.sell_protocol_fee_bps), (70, 70));
    assert_eq!(c.creator_fee_bps, 30, "the creator's reward rate");
    assert_eq!(c.holder_fees_unclaimed, 0);
    assert_eq!(c.pool, Pubkey::default());
    assert_eq!(c.creator, env.creator.pubkey());
    assert_eq!(c.real_token_reserves, 800_000_000 * UNIT);
    assert!(!c.complete && !c.graduated);
    // Metadata account was created by Metaplex.
    let md = env
        .svm
        .get_account(&metadata_pda(&t.mint))
        .expect("metadata");
    assert_eq!(md.owner, anchor_spl::metadata::ID);
}

#[test]
fn buy_and_sell_match_math_quotes() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    let fee0 = env.lamports(&treasury_pda());
    let curve0 = env.lamports(&t.curve);

    // Buy
    let before = env.curve(&t);
    let q = math::quote_buy(&to_math(&before), 3 * SOL, &fees(), 0).unwrap();
    let user0 = env.lamports(&user.pubkey());
    env.buy(&t, &user, 3 * SOL).unwrap();
    let after = env.curve(&t);
    assert_eq!(to_math(&after), q.next);
    assert_eq!(env.token_balance(&user.pubkey(), &t.mint), q.tokens_out);
    assert_eq!(
        env.lamports(&treasury_pda()),
        fee0,
        "buy does not touch the Treasury"
    );
    assert_eq!(
        env.lamports(&t.curve) - curve0,
        q.sol_to_curve + q.fees.creator + q.fees.protocol
    );
    assert_eq!(after.creator_fees_unclaimed, q.fees.creator);
    assert_eq!(after.protocol_fees_unclaimed, q.fees.protocol);
    let ata_rent = env.svm.minimum_balance_for_rent_exemption(165);
    // user pays: gross + ATA rent + tx fee (5000 lamports, 1 signature)
    assert_eq!(
        user0 - env.lamports(&user.pubkey()),
        q.sol_in + ata_rent + 5_000
    );

    // Sell half
    let tokens = q.tokens_out / 2;
    let s = math::quote_sell(&to_math(&after), tokens, &fees(), 0).unwrap();
    let user1 = env.lamports(&user.pubkey());
    let fee1 = env.lamports(&treasury_pda());
    let ix = env.ix_sell(&t, &user.pubkey(), tokens, s.sol_out, NO_DEADLINE);
    env.send(ix, &[&user]).unwrap();
    let after2 = env.curve(&t);
    assert_eq!(to_math(&after2), s.next);
    assert_eq!(env.lamports(&user.pubkey()) - user1, s.sol_out - 5_000);
    assert_eq!(
        env.lamports(&treasury_pda()),
        fee1,
        "sell does not touch the Treasury"
    );
    assert_eq!(
        after2.protocol_fees_unclaimed,
        q.fees.protocol + s.fees.protocol
    );
    assert_eq!(
        after2.creator_fees_unclaimed,
        q.fees.creator + s.fees.creator
    );
    assert_eq!(
        env.token_balance(&user.pubkey(), &t.mint),
        q.tokens_out - tokens
    );

    // Creator claims accumulated fees.
    let creator = env.creator.insecure_clone();
    let c0 = env.lamports(&creator.pubkey());
    let ix = env.ix_claim(&t, &creator.pubkey());
    env.send(ix, &[&creator]).unwrap();
    assert_eq!(
        env.lamports(&creator.pubkey()) - c0,
        q.fees.creator + s.fees.creator - 5_000
    );
    assert_eq!(env.curve(&t).creator_fees_unclaimed, 0);
    // Nothing left to claim.
    let ix = env.ix_claim(&t, &creator.pubkey());
    assert_eq!(
        env.send(ix, &[&creator]).unwrap_err(),
        custom(DeepError::ZeroAmount)
    );
}

#[test]
fn slippage_rejected_on_buy_and_sell() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    let q = math::quote_buy(&to_math(&env.curve(&t)), SOL, &fees(), 0).unwrap();
    let ix = env.ix_buy(&t, &user.pubkey(), SOL, q.tokens_out + 1, NO_DEADLINE);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::SlippageExceeded)
    );

    env.buy(&t, &user, SOL).unwrap();
    let s = math::quote_sell(&to_math(&env.curve(&t)), q.tokens_out, &fees(), 0).unwrap();
    let ix = env.ix_sell(&t, &user.pubkey(), q.tokens_out, s.sol_out + 1, NO_DEADLINE);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::SlippageExceeded)
    );
}

#[test]
fn deadline_rejected() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let mut clock: anchor_lang::prelude::Clock = env.svm.get_sysvar();
    clock.unix_timestamp = 1_700_000_000;
    env.svm.set_sysvar(&clock);
    let user = env.user(100 * SOL);
    let ix = env.ix_buy(&t, &user.pubkey(), SOL, 0, 1_699_999_999);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::DeadlineExceeded)
    );
    // exactly at the deadline is still valid
    let ix = env.ix_buy(&t, &user.pubkey(), SOL, 0, 1_700_000_000);
    env.send(ix, &[&user]).unwrap();
    let ix = env.ix_sell(&t, &user.pubkey(), UNIT, 0, 1_699_999_999);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::DeadlineExceeded)
    );
}

#[test]
fn paused_blocks_create_buy_sell_but_not_claims() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    env.buy(&t, &user, SOL).unwrap();

    let admin = env.admin.insecure_clone();
    let ix = env.ix_set_paused(&admin.pubkey(), true);
    env.send(ix, &[&admin]).unwrap();

    assert_eq!(
        env.buy(&t, &user, SOL).unwrap_err(),
        custom(DeepError::Paused)
    );
    let ix = env.ix_sell(&t, &user.pubkey(), UNIT, 0, NO_DEADLINE);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::Paused)
    );
    let mint = Keypair::new();
    let creator = env.creator.insecure_clone();
    let ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Paused");
    assert_eq!(
        env.send(ix, &[&creator, &mint]).unwrap_err(),
        custom(DeepError::Paused)
    );
    // creator fee claims still work while paused
    let ix = env.ix_claim(&t, &creator.pubkey());
    env.send(ix, &[&creator]).unwrap();

    let ix = env.ix_set_paused(&admin.pubkey(), false);
    env.send(ix, &[&admin]).unwrap();
    env.buy(&t, &user, SOL).unwrap();
}

#[test]
fn unauthorized_admin_calls_rejected() {
    let mut env = Env::new();
    let mallory = env.user(10 * SOL);
    let m = mallory.pubkey();
    let p = params(m, m);
    let unauthorized = custom(DeepError::Unauthorized);

    let ix = env.ix_set_paused(&m, true);
    assert_eq!(env.send(ix, &[&mallory]).unwrap_err(), unauthorized);
    let ix = env.ix_queue_config(&m, p.clone());
    assert_eq!(env.send(ix, &[&mallory]).unwrap_err(), unauthorized);
    let ix = env.ix_propose_admin(&m, m);
    assert_eq!(env.send(ix, &[&mallory]).unwrap_err(), unauthorized);
    // accept_admin without a pending proposal for this key
    let ix = env.ix_accept_admin(&m);
    assert_eq!(env.send(ix, &[&mallory]).unwrap_err(), unauthorized);

    // Proper two-step transfer works, and only the proposed key can accept.
    let admin = env.admin.insecure_clone();
    let new_admin = env.user(SOL);
    let ix = env.ix_propose_admin(&admin.pubkey(), new_admin.pubkey());
    env.send(ix, &[&admin]).unwrap();
    let ix = env.ix_accept_admin(&m);
    assert_eq!(env.send(ix, &[&mallory]).unwrap_err(), unauthorized);
    let ix = env.ix_accept_admin(&new_admin.pubkey());
    env.send(ix, &[&new_admin]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.admin, new_admin.pubkey());
    assert_eq!(cfg.pending_admin, Pubkey::default());
    // old admin lost its rights
    let ix = env.ix_set_paused(&admin.pubkey(), true);
    assert_eq!(env.send(ix, &[&admin]).unwrap_err(), unauthorized);
}

#[test]
fn sell_more_than_sold_rejected() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let a = env.user(100 * SOL);
    let b = env.user(100 * SOL);
    env.buy(&t, &a, SOL).unwrap();
    env.buy(&t, &b, SOL).unwrap();
    let sold = {
        let c = env.curve(&t);
        c.curve_supply - c.real_token_reserves
    };
    let ix = env.ix_sell(&t, &a.pubkey(), sold + 1, 0, NO_DEADLINE);
    assert_eq!(
        env.send(ix, &[&a]).unwrap_err(),
        custom(DeepError::InsufficientReserves)
    );
    // Selling more than the user holds (but <= sold) fails in the token program.
    let held = env.token_balance(&a.pubkey(), &t.mint);
    let ix = env.ix_sell(&t, &a.pubkey(), held + 1, 0, NO_DEADLINE);
    assert!(env.send(ix, &[&a]).is_err());
}

#[test]
fn buy_after_complete_rejected_and_sell_too() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let whale = env.complete_curve(&t);
    let c = env.curve(&t);
    assert_eq!(c.real_token_reserves, 0);
    assert_eq!(
        env.token_balance(&whale.pubkey(), &t.mint),
        800_000_000 * UNIT
    );
    let user = env.user(10 * SOL);
    assert_eq!(
        env.buy(&t, &user, SOL).unwrap_err(),
        custom(DeepError::CurveComplete)
    );
    let ix = env.ix_sell(&t, &whale.pubkey(), UNIT, 0, NO_DEADLINE);
    assert_eq!(
        env.send(ix, &[&whale]).unwrap_err(),
        custom(DeepError::CurveComplete)
    );
}

#[test]
fn graduate_rules() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let migration = env.migration.insecure_clone();

    // not complete yet
    assert_eq!(
        env.graduate(&t, &migration).unwrap_err(),
        custom(DeepError::CurveNotComplete)
    );

    env.complete_curve(&t);

    // PERMISSIONLESS (security review F2): the configured migration authority is not needed.
    // A stranger graduates the curve; see `graduate_is_permissionless_...` for the accounting.
    let stranger = env.user(10 * SOL);
    assert_ne!(stranger.pubkey(), migration.pubkey());
    env.graduate(&t, &stranger)
        .expect("anyone can graduate a completed curve");
    assert!(env.curve(&t).graduated);
    assert_eq!(
        env.graduate(&t, &migration).unwrap_err(),
        custom(DeepError::AlreadyGraduated)
    );
}

#[test]
fn graduate_creates_raydium_pool_and_burns_lp() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    let k = pool_keys(&t.mint);

    let before = env.curve(&t);
    let alloc = math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
    let m0 = env.lamports(&migration.pubkey());
    let tr0 = env.lamports(&treasury_pda());
    let v0 = vault_revenue(&env);
    assert_eq!(builder_paid(&env), 0);
    assert_eq!(raydium::CREATE_POOL_FEE_RECEIVER, fee_vault_wsol());
    let fee0 = env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER);
    let curve_lamports0 = env.lamports(&t.curve);
    let meta = env.graduate(&t, &migration).expect("graduate");
    println!("graduate CU: {}", meta.compute_units_consumed);

    // pool exists, owned by deep-amm, paid for by our pool_creator PDA and recorded to
    // the TOKEN's creator (who can collect the creator fee)
    let pool = env.svm.get_account(&k.pool_state).expect("pool_state");
    assert_eq!(pool.owner, raydium::CP_SWAP_PROGRAM_ID);
    assert_eq!(
        &pool.data[8..40],
        amm_config_0().as_ref(),
        "pool.amm_config"
    );
    assert_eq!(
        &pool.data[40..72],
        env.creator.pubkey().as_ref(),
        "pool.pool_creator is the token creator"
    );
    assert_eq!(before.creator, env.creator.pubkey());
    // vaults hold exactly the allocation from math.rs
    let tv: TokenAccount = env.load(&k.token_vault);
    let wv: TokenAccount = env.load(&k.wsol_vault);
    assert_eq!(tv.amount, alloc.lp_tokens);
    assert_eq!(wv.amount, alloc.lp_sol);
    assert_eq!(tv.mint, t.mint);
    assert_eq!(wv.mint, NATIVE_MINT);
    // every LP token minted to the creator was burned: supply 0, account closed
    let lp: Mint = env.load(&k.lp_mint);
    assert_eq!(lp.supply, 0, "LP tokens burned");
    assert!(env.svm.get_account(&k.creator_lp).is_none());
    // temporary accounts closed, pool creator drained
    assert!(env.svm.get_account(&k.creator_token).is_none());
    assert!(env.svm.get_account(&k.creator_wsol).is_none());
    assert_eq!(env.lamports(&k.pool_creator), 0);

    // supply: reserve not needed for the pool was burned; vault empty
    let mint: Mint = env.load(&t.mint);
    assert_eq!(mint.supply, 1_000_000_000 * UNIT - alloc.burn_tokens);
    let vault: TokenAccount = env.load(&t.vault);
    assert_eq!(vault.amount, 0);

    // SOL accounting
    let after = env.curve(&t);
    assert!(after.graduated);
    assert_eq!(after.pool, k.pool_state);
    assert_eq!(after.real_sol_reserves, 0);
    assert_eq!(after.creator_fees_unclaimed, before.creator_fees_unclaimed);
    assert_eq!(
        curve_lamports0 - env.lamports(&t.curve),
        alloc.raised_sol + before.protocol_fees_unclaimed,
        "graduate moves the raise and sweeps accrued protocol fees"
    );
    assert_eq!(after.protocol_fees_unclaimed, 0);
    let rent = |key: &Pubkey| {
        let len = env.svm.get_account(key).unwrap().data.len();
        env.svm.minimum_balance_for_rent_exemption(len)
    };
    let create_pool_fee = env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER) - fee0;
    let amm_cfg = env.svm.get_account(&amm_config_0()).unwrap();
    assert_eq!(
        create_pool_fee,
        u64::from_le_bytes(amm_cfg.data[36..44].try_into().unwrap())
    );
    let pool_costs = create_pool_fee
        + rent(&k.pool_state)
        + rent(&k.observation)
        + rent(&k.lp_mint)
        + rent(&k.token_vault)
        + rent(&k.wsol_vault);
    // DEEP V1: the migration fee minus pool costs, plus the swept protocol fees, go to the fee
    // vault; the create-pool fee arrives as WSOL in the vault's ATA. Nothing reaches the
    // Treasury or the builder directly.
    let base = alloc.migration_fee - pool_costs + before.protocol_fees_unclaimed;
    assert_eq!(
        vault_revenue(&env) - v0,
        base,
        "fee vault gets the graduation revenue"
    );
    assert_eq!(
        env.lamports(&treasury_pda()),
        tr0,
        "legacy Treasury untouched"
    );
    assert_eq!(
        builder_paid(&env),
        0,
        "the builder is paid by distribute, not graduate"
    );
    // the sender only paid the network fee (the pool payer PDA funds the temporary accounts)
    assert_eq!(m0 - env.lamports(&migration.pubkey()), 5_000);

    // distribute (anyone): the WSOL create-pool fee is unwrapped and everything is split,
    // builder exactly 10%, the Treasury wallet 90%.
    let w0 = env.lamports(&env.treasury_wallet.pubkey());
    let total = v0 + base + create_pool_fee;
    env.distribute().expect("distribute after graduation");
    assert_eq!(builder_paid(&env), total / 10);
    assert_eq!(
        env.lamports(&env.treasury_wallet.pubkey()) - w0,
        total - total / 10
    );
    assert_eq!(vault_revenue(&env), 0);
    let wsol: TokenAccount = env.load(&fee_vault_wsol());
    assert_eq!(wsol.amount, 0, "vault WSOL unwrapped");
    assert_eq!(
        env.lamports(&fee_vault_wsol()),
        env.svm.minimum_balance_for_rent_exemption(165),
        "the vault's WSOL ATA stays, rent-exempt"
    );

    // second graduation is rejected
    assert_eq!(
        env.graduate(&t, &migration).unwrap_err(),
        custom(DeepError::AlreadyGraduated)
    );
}

#[test]
fn graduate_survives_griefing_of_predictable_addresses() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let whale = env.complete_curve(&t);
    let k = pool_keys(&t.mint);
    // Attacker pre-creates the pool creator's ATAs, sends tokens into them and
    // pre-funds the pool_creator / pool_state PDAs with lamports.
    let create_ata = |owner: &Pubkey, mint: &Pubkey, payer: &Pubkey| Instruction {
        program_id: anchor_spl::associated_token::ID,
        accounts: vec![
            anchor_lang::prelude::AccountMeta::new(*payer, true),
            anchor_lang::prelude::AccountMeta::new(
                get_associated_token_address(owner, mint),
                false,
            ),
            anchor_lang::prelude::AccountMeta::new_readonly(*owner, false),
            anchor_lang::prelude::AccountMeta::new_readonly(*mint, false),
            anchor_lang::prelude::AccountMeta::new_readonly(anchor_lang::system_program::ID, false),
            anchor_lang::prelude::AccountMeta::new_readonly(anchor_spl::token::ID, false),
        ],
        data: vec![1], // CreateIdempotent
    };
    let w = whale.pubkey();
    let send_tokens = anchor_spl::token::spl_token::instruction::transfer(
        &anchor_spl::token::ID,
        &get_associated_token_address(&w, &t.mint),
        &k.creator_token,
        &w,
        &[],
        12_345 * UNIT,
    )
    .unwrap();
    env.send_ixs(
        vec![
            create_ata(&k.pool_creator, &t.mint, &w),
            create_ata(&k.pool_creator, &NATIVE_MINT, &w),
            send_tokens,
        ],
        &[&whale],
    )
    .expect("grief setup");
    env.svm.airdrop(&k.pool_creator, 3 * SOL).unwrap();
    env.svm.airdrop(&k.pool_state, SOL).unwrap();

    let migration = env.migration.insecure_clone();
    let before = env.curve(&t);
    let alloc = math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
    env.graduate(&t, &migration)
        .expect("graduate despite griefing");
    let tv: TokenAccount = env.load(&k.token_vault);
    assert_eq!(tv.amount, alloc.lp_tokens);
    let mint: Mint = env.load(&t.mint);
    // the attacker's 12,345 tokens sent to the creator ATA were burned as well
    assert_eq!(
        mint.supply,
        1_000_000_000 * UNIT - alloc.burn_tokens - 12_345 * UNIT
    );
    assert_eq!(env.lamports(&k.pool_creator), 0);
    assert!(env.curve(&t).graduated);
}

#[test]
fn graduate_rejects_wrong_raydium_accounts() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    let m = migration.pubkey();
    let other_cfg =
        Pubkey::find_program_address(&[b"amm_config", &1u16.to_be_bytes()], &deep_amm::ID).0;
    for ix in [
        env.ix_graduate_with(&t, &m, other_cfg, raydium::CP_SWAP_PROGRAM_ID),
        env.ix_graduate_with(&t, &m, amm_config_0(), anchor_spl::token::ID),
    ] {
        assert_eq!(
            env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&migration])
                .unwrap_err(),
            custom(DeepError::InvalidPool)
        );
    }
    assert!(!env.curve(&t).graduated);
}

#[test]
fn graduate_with_low_migration_fee_recovers_after_top_up() {
    let mut env = Env::new();
    // 10 bps of ~85 SOL ≈ 0.085 SOL: less than Raydium's 0.15 SOL create-pool fee.
    let admin = env.admin.insecure_clone();
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.migration_fee_bps = 10;
    let _ = admin;
    env.update_config_now(p).unwrap();
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    assert!(env.graduate(&t, &migration).is_err());
    assert!(!env.curve(&t).graduated);
    // Documented recovery: anyone tops up the pool_creator PDA, then retry.
    let k = pool_keys(&t.mint);
    env.svm.airdrop(&k.pool_creator, SOL / 5).unwrap();
    env.graduate(&t, &migration).expect("graduate after top-up");
    assert!(env.curve(&t).graduated);
    assert_eq!(env.lamports(&k.pool_creator), 0);
}

#[test]
fn creator_fee_claim_by_non_creator_rejected() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    env.buy(&t, &user, SOL).unwrap();
    let ix = env.ix_claim(&t, &user.pubkey());
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
}

#[test]
fn compute_units_report() {
    let mut env = Env::new();
    let mut rows: Vec<(&str, u64)> = Vec::new();

    // initialize_config on a fresh VM
    {
        let admin = Keypair::new();
        let mut svm = vm(Some(admin.pubkey()));
        svm.airdrop(&admin.pubkey(), SOL).unwrap();
        let ix = env.ix_initialize_config(&admin.pubkey(), params(admin.pubkey(), admin.pubkey()));
        let tx = Transaction::new_signed_with_payer(
            &[ix],
            Some(&admin.pubkey()),
            &[&admin],
            svm.latest_blockhash(),
        );
        rows.push((
            "initialize_config",
            svm.send_transaction(tx).unwrap().compute_units_consumed,
        ));
    }

    let admin = env.admin.insecure_clone();
    let ix = env.ix_queue_config(
        &admin.pubkey(),
        params(env.fee_recipient.pubkey(), env.migration.pubkey()),
    );
    rows.push((
        "queue_config_update",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_apply_config();
    rows.push((
        "apply_config_update",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_queue_config(
        &admin.pubkey(),
        params(env.fee_recipient.pubkey(), env.migration.pubkey()),
    );
    env.send(ix, &[&admin]).unwrap();
    let ix = env.ix_cancel_config(&admin.pubkey());
    rows.push((
        "cancel_config_update",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_set_paused(&admin.pubkey(), false);
    rows.push((
        "set_paused",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_propose_admin(&admin.pubkey(), admin.pubkey());
    rows.push((
        "propose_admin",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_accept_admin(&admin.pubkey());
    rows.push((
        "accept_admin",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));

    let (t, meta) = env.create_token();
    rows.push(("create_token", meta.compute_units_consumed));
    let user = env.user(100 * SOL);
    rows.push((
        "buy (creates user ATA)",
        env.buy(&t, &user, SOL).unwrap().compute_units_consumed,
    ));
    rows.push((
        "buy (ATA exists)",
        env.buy(&t, &user, SOL).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_sell(&t, &user.pubkey(), 1_000 * UNIT, 0, NO_DEADLINE);
    rows.push((
        "sell",
        env.send(ix, &[&user]).unwrap().compute_units_consumed,
    ));
    let ix = env.ix_sweep(&t);
    rows.push((
        "sweep_protocol_fees",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let fr = env.fee_recipient.pubkey();
    env.svm.airdrop(&treasury_pda(), SOL / 100).unwrap(); // a legacy (pre-V1) balance
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, SOL / 100);
    rows.push((
        "withdraw_protocol_fees",
        env.send(ix, &[&admin]).unwrap().compute_units_consumed,
    ));
    let creator = env.creator.insecure_clone();
    let ix = env.ix_claim(&t, &creator.pubkey());
    rows.push((
        "claim_creator_fees",
        env.send(ix, &[&creator]).unwrap().compute_units_consumed,
    ));
    let whale = env.user(2_000 * SOL);
    rows.push((
        "buy (completes curve)",
        env.buy(&t, &whale, 1_000 * SOL)
            .unwrap()
            .compute_units_consumed,
    ));
    let migration = env.migration.insecure_clone();
    rows.push((
        "graduate (Raydium CPMM)",
        env.graduate(&t, &migration).unwrap().compute_units_consumed,
    ));
    // distribute at the maximum of 8 destinations, with WSOL (the create-pool fee) to unwrap
    let dests: Vec<(Pubkey, u16)> = (0..8)
        .map(|i| (env.user(SOL).pubkey(), if i == 0 { 3_000 } else { 1_000 }))
        .collect();
    env.update_splitter_now(splitter_params(&dests)).unwrap();
    rows.push((
        "distribute (8 dest, WSOL)",
        env.distribute().unwrap().compute_units_consumed,
    ));

    println!("\n── deep_curve compute units (LiteSVM) ──");
    for (name, cu) in &rows {
        println!("{name:<26} {cu:>8}");
        let budget = if name.starts_with("graduate") {
            GRADUATE_CU_LIMIT as u64
        } else {
            200_000
        };
        assert!(*cu < budget, "{name} exceeds its CU budget");
    }
}

#[test]
fn initialize_config_requires_upgrade_authority() {
    let admin = Keypair::new();
    let mallory = Keypair::new();
    let mut env = Env {
        svm: vm(Some(admin.pubkey())),
        admin: admin.insecure_clone(),
        fee_recipient: Keypair::new(),
        migration: Keypair::new(),
        creator: Keypair::new(),
        treasury_wallet: Keypair::new(),
    };
    env.svm.airdrop(&mallory.pubkey(), SOL).unwrap();
    env.svm.airdrop(&admin.pubkey(), SOL).unwrap();
    let p = params(mallory.pubkey(), mallory.pubkey());
    let ix = env.ix_initialize_config(&mallory.pubkey(), p.clone());
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    // A spoofed program_data account (not the program's ProgramData) is rejected.
    let mut ix = env.ix_initialize_config(&mallory.pubkey(), p.clone());
    ix.accounts[4].pubkey = config_pda();
    assert!(env.send(ix, &[&mallory]).is_err());
    assert!(env.svm.get_account(&config_pda()).is_none());
    // the real upgrade authority succeeds
    let ix = env.ix_initialize_config(&admin.pubkey(), p);
    env.send(ix, &[&admin]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.admin, admin.pubkey());
}

#[test]
fn initialize_config_rejected_when_program_is_immutable() {
    let admin = Keypair::new();
    let mut env = Env {
        svm: vm(None),
        admin: admin.insecure_clone(),
        fee_recipient: Keypair::new(),
        migration: Keypair::new(),
        creator: Keypair::new(),
        treasury_wallet: Keypair::new(),
    };
    env.svm.airdrop(&admin.pubkey(), SOL).unwrap();
    let ix = env.ix_initialize_config(&admin.pubkey(), params(admin.pubkey(), admin.pubkey()));
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
}

#[test]
fn sweeps_go_to_the_fee_vault_and_the_legacy_treasury_is_drain_only() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    let fr = env.fee_recipient.pubkey();
    assert_eq!(env.lamports(&fr), 0, "fee recipient starts unfunded");
    let t0 = env.lamports(&treasury_pda());
    let rent = env
        .svm
        .minimum_balance_for_rent_exemption(8 + deep_curve::Treasury::INIT_SPACE);
    assert_eq!(t0, rent);
    let q = math::quote_buy(&to_math(&env.curve(&t)), 5 * SOL, &fees(), 0).unwrap();
    env.buy(&t, &user, 5 * SOL).unwrap();
    let ix = env.ix_sweep(&t);
    env.send(ix, &[&user]).unwrap(); // permissionless
                                     // DEEP V1: the whole protocol fee goes to the fee vault; nothing to the Treasury or builder
    assert_eq!(q.fees.protocol, 35_000_000);
    assert_eq!(vault_revenue(&env), 35_000_000);
    assert_eq!(builder_paid(&env), 0);
    assert_eq!(
        env.lamports(&treasury_pda()),
        t0,
        "nothing credits the Treasury any more"
    );

    // The pre-V1 devnet Treasury balance can still be withdrawn by the admin (drain-only).
    let accrued = 7_777_777;
    env.svm.airdrop(&treasury_pda(), accrued).unwrap();

    let admin = env.admin.insecure_clone();
    // non-admin cannot withdraw
    let ix = env.ix_withdraw(&user.pubkey(), &fr, 1);
    assert_eq!(
        env.send(ix, &[&user]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    // destination must be config.fee_recipient
    let ix = env.ix_withdraw(&admin.pubkey(), &admin.pubkey(), 1);
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InvalidFeeRecipient)
    );
    // zero and over-withdraw (would dip below rent) rejected
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, 0);
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::ZeroAmount)
    );
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, accrued + 1);
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InsufficientTreasury)
    );
    // withdrawing everything above rent works and leaves the treasury rent-exempt
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, accrued);
    env.send(ix, &[&admin]).unwrap();
    assert_eq!(env.lamports(&fr), accrued);
    assert_eq!(env.lamports(&treasury_pda()), rent);
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, 1);
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InsufficientTreasury)
    );
}

#[test]
fn tiny_trades_work_with_unfunded_fee_recipient() {
    // Previously a protocol fee below rent-exemption credited to an empty
    // fee_recipient failed the whole trade. Fees now accrue in the treasury PDA.
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(10 * SOL);
    env.buy(&t, &user, 10_000).unwrap(); // protocol fee: a handful of lamports
    let held = env.token_balance(&user.pubkey(), &t.mint);
    let ix = env.ix_sell(&t, &user.pubkey(), held / 2, 0, NO_DEADLINE);
    env.send(ix, &[&user]).unwrap();
    assert_eq!(env.lamports(&env.fee_recipient.pubkey()), 0);
}

#[test]
fn graduate_works_for_both_mint_orderings() {
    for wsol_first in [true, false] {
        let mut env = Env::new();
        let t = env.create_token_ordered(wsol_first);
        env.complete_curve(&t);
        let before = env.curve(&t);
        let alloc =
            math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
        let migration = env.migration.insecure_clone();
        env.graduate(&t, &migration).expect("graduate");
        let k = pool_keys(&t.mint);
        let pool = env.svm.get_account(&k.pool_state).unwrap();
        // PoolState: token_0_vault @ 72, token_1_vault @ 104, token_0_mint @ 168, token_1_mint @ 200
        let (m0, m1) = if wsol_first {
            (NATIVE_MINT, t.mint)
        } else {
            (t.mint, NATIVE_MINT)
        };
        assert_eq!(
            &pool.data[168..200],
            m0.as_ref(),
            "token_0_mint (wsol_first={wsol_first})"
        );
        assert_eq!(&pool.data[200..232], m1.as_ref());
        let tv: TokenAccount = env.load(&k.token_vault);
        let wv: TokenAccount = env.load(&k.wsol_vault);
        assert_eq!((tv.amount, wv.amount), (alloc.lp_tokens, alloc.lp_sol));
    }
}

// ───────────── Raydium CPMM swap against the graduated pool ─────────────

/// sha256("global:swap_base_input")[..8]
const SWAP_BASE_INPUT_DISC: [u8; 8] = [143, 190, 90, 218, 196, 30, 51, 222];
const CPMM_FEE_DENOMINATOR: u128 = 1_000_000;
/// cp-swap ErrorCode (error.rs): NotApproved = 6000, ExceededSlippage = 6005.
const CPMM_ERR_NOT_APPROVED: u32 = 6000;
const CPMM_ERR_EXCEEDED_SLIPPAGE: u32 = 6005;
/// deep-amm ErrorCode::InsufficientVault (DEEP pre-check in swap_base_output).
const CPMM_ERR_INSUFFICIENT_VAULT: u32 = 6012;

fn create_ata_ix(payer: &Pubkey, owner: &Pubkey, mint: &Pubkey) -> Instruction {
    use anchor_lang::prelude::AccountMeta;
    Instruction {
        program_id: anchor_spl::associated_token::ID,
        accounts: vec![
            AccountMeta::new(*payer, true),
            AccountMeta::new(get_associated_token_address(owner, mint), false),
            AccountMeta::new_readonly(*owner, false),
            AccountMeta::new_readonly(*mint, false),
            AccountMeta::new_readonly(anchor_lang::system_program::ID, false),
            AccountMeta::new_readonly(anchor_spl::token::ID, false),
        ],
        data: vec![1], // CreateIdempotent
    }
}

/// Fields of cp-swap PoolState needed for quoting (offsets from states/pool.rs).
struct CpmmPool {
    token_0_vault: Pubkey,
    token_1_vault: Pubkey,
    token_0_mint: Pubkey,
    token_1_mint: Pubkey,
    observation: Pubkey,
    open_time: u64,
    /// protocol + fund + creator fees accrued per side (excluded from reserves)
    fees_0: u64,
    fees_1: u64,
    creator_fee_on: u8,
    enable_creator_fee: bool,
}

fn read_cpmm_pool(data: &[u8]) -> CpmmPool {
    let pk = |o: usize| Pubkey::new_from_array(data[o..o + 32].try_into().unwrap());
    let u64_at = |o: usize| u64::from_le_bytes(data[o..o + 8].try_into().unwrap());
    CpmmPool {
        token_0_vault: pk(72),
        token_1_vault: pk(104),
        token_0_mint: pk(168),
        token_1_mint: pk(200),
        observation: pk(296),
        open_time: u64_at(373),
        fees_0: u64_at(341) + u64_at(357) + u64_at(397),
        fees_1: u64_at(349) + u64_at(365) + u64_at(405),
        creator_fee_on: data[389],
        enable_creator_fee: data[390] == 1,
    }
}

fn ceil_div_u128(a: u128, n: u128, d: u128) -> u128 {
    (a * n).div_ceil(d)
}

/// Independent re-implementation of cp-swap `CurveCalculator::swap_base_input`
/// (curve/calculator.rs + curve/fees.rs + curve/constant_product.rs).
fn cpmm_quote(
    amount_in: u64,
    reserve_in: u64,
    reserve_out: u64,
    trade_fee_rate: u64,
    creator_fee_rate: u64,
    creator_fee_on_input: bool,
) -> u64 {
    let (x, xr, yr) = (amount_in as u128, reserve_in as u128, reserve_out as u128);
    let (tr, cr) = (trade_fee_rate as u128, creator_fee_rate as u128);
    let net_in = if creator_fee_on_input {
        x - ceil_div_u128(x, tr + cr, CPMM_FEE_DENOMINATOR)
    } else {
        x - ceil_div_u128(x, tr, CPMM_FEE_DENOMINATOR)
    };
    let swapped = net_in * yr / (xr + net_in);
    let out = if creator_fee_on_input {
        swapped
    } else {
        swapped - ceil_div_u128(swapped, cr, CPMM_FEE_DENOMINATOR)
    };
    out as u64
}

fn cpmm_swap_ix(
    trader: &Pubkey,
    pool_state: &Pubkey,
    pool: &CpmmPool,
    input_mint: Pubkey,
    amount_in: u64,
    min_out: u64,
) -> Instruction {
    use anchor_lang::prelude::AccountMeta;
    let zero_for_one = input_mint == pool.token_0_mint;
    let (in_mint, out_mint, in_vault, out_vault) = if zero_for_one {
        (
            pool.token_0_mint,
            pool.token_1_mint,
            pool.token_0_vault,
            pool.token_1_vault,
        )
    } else {
        (
            pool.token_1_mint,
            pool.token_0_mint,
            pool.token_1_vault,
            pool.token_0_vault,
        )
    };
    let mut data = SWAP_BASE_INPUT_DISC.to_vec();
    data.extend_from_slice(&amount_in.to_le_bytes());
    data.extend_from_slice(&min_out.to_le_bytes());
    let authority =
        Pubkey::find_program_address(&[raydium::AUTH_SEED], &raydium::CP_SWAP_PROGRAM_ID).0;
    Instruction {
        program_id: raydium::CP_SWAP_PROGRAM_ID,
        accounts: vec![
            AccountMeta::new_readonly(*trader, true),
            AccountMeta::new_readonly(authority, false),
            AccountMeta::new_readonly(amm_config_0(), false),
            AccountMeta::new(*pool_state, false),
            AccountMeta::new(get_associated_token_address(trader, &in_mint), false),
            AccountMeta::new(get_associated_token_address(trader, &out_mint), false),
            AccountMeta::new(in_vault, false),
            AccountMeta::new(out_vault, false),
            AccountMeta::new_readonly(anchor_spl::token::ID, false),
            AccountMeta::new_readonly(anchor_spl::token::ID, false),
            AccountMeta::new_readonly(in_mint, false),
            AccountMeta::new_readonly(out_mint, false),
            AccountMeta::new(pool.observation, false),
        ],
        data,
    }
}

/// Quote from live on-chain state: reserves = vault balance − accrued pool fees.
fn cpmm_quote_live(
    env: &Env,
    pool_state: &Pubkey,
    input_mint: Pubkey,
    amount_in: u64,
) -> (CpmmPool, u64) {
    let pool = read_cpmm_pool(&env.svm.get_account(pool_state).unwrap().data);
    let cfg = env.svm.get_account(&amm_config_0()).unwrap().data;
    let trade_fee_rate = u64::from_le_bytes(cfg[12..20].try_into().unwrap());
    let creator_fee_rate = if pool.enable_creator_fee {
        u64::from_le_bytes(cfg[108..116].try_into().unwrap())
    } else {
        0
    };
    let v0 = env.load::<TokenAccount>(&pool.token_0_vault).amount - pool.fees_0;
    let v1 = env.load::<TokenAccount>(&pool.token_1_vault).amount - pool.fees_1;
    let zero_for_one = input_mint == pool.token_0_mint;
    let on_input = match pool.creator_fee_on {
        0 => true,
        1 => zero_for_one,
        _ => !zero_for_one,
    };
    let (ri, ro) = if zero_for_one { (v0, v1) } else { (v1, v0) };
    let out = cpmm_quote(
        amount_in,
        ri,
        ro,
        trade_fee_rate,
        creator_fee_rate,
        on_input,
    );
    (pool, out)
}

#[test]
fn graduated_pool_is_tradable_on_raydium_and_matches_cpmm_math() {
    let mut env = Env::new();
    let mut clock: anchor_lang::prelude::Clock = env.svm.get_sysvar();
    clock.unix_timestamp = 1_800_000_000;
    env.svm.set_sysvar(&clock);

    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    env.graduate(&t, &migration).expect("graduate");
    let k = pool_keys(&t.mint);
    let pool = read_cpmm_pool(&env.svm.get_account(&k.pool_state).unwrap().data);
    assert_eq!(pool.open_time, 1_800_000_001, "open_time = now + 1");
    assert!(
        pool.enable_creator_fee,
        "graduation creates the pool with the creator fee enabled"
    );

    // trader: wrap 2 SOL into a WSOL ATA, create the token ATA
    let trader = env.user(10 * SOL);
    let tp = trader.pubkey();
    let wsol_ata = get_associated_token_address(&tp, &NATIVE_MINT);
    let tok_ata = get_associated_token_address(&tp, &t.mint);
    let wrap = vec![
        create_ata_ix(&tp, &tp, &NATIVE_MINT),
        create_ata_ix(&tp, &tp, &t.mint),
        anchor_lang::solana_program::system_instruction::transfer(&tp, &wsol_ata, 2 * SOL),
        anchor_spl::token::spl_token::instruction::sync_native(&anchor_spl::token::ID, &wsol_ata)
            .unwrap(),
    ];
    env.send_ixs(wrap, &[&trader]).expect("wrap SOL");

    // before open_time: cp-swap rejects the swap (NotApproved)
    let (p, q_early) = cpmm_quote_live(&env, &k.pool_state, NATIVE_MINT, SOL);
    assert!(q_early > 0);
    let ix = cpmm_swap_ix(&tp, &k.pool_state, &p, NATIVE_MINT, SOL, 0);
    assert_eq!(
        env.send(ix, &[&trader]).unwrap_err(),
        CPMM_ERR_NOT_APPROVED,
        "swap before open_time must fail"
    );

    // warp to open_time
    clock.unix_timestamp = 1_800_000_001;
    env.svm.set_sysvar(&clock);

    // SOL → token
    let (p, q) = cpmm_quote_live(&env, &k.pool_state, NATIVE_MINT, SOL);
    let tok0 = env.load::<TokenAccount>(&tok_ata).amount;
    let ix = cpmm_swap_ix(&tp, &k.pool_state, &p, NATIVE_MINT, SOL, q + 1);
    assert_eq!(
        env.send(ix, &[&trader]).unwrap_err(),
        CPMM_ERR_EXCEEDED_SLIPPAGE,
        "min_out = quote + 1 must fail"
    );
    let ix = cpmm_swap_ix(&tp, &k.pool_state, &p, NATIVE_MINT, SOL, q);
    let m = env.send(ix, &[&trader]).expect("swap SOL→token");
    let got = env.load::<TokenAccount>(&tok_ata).amount - tok0;
    assert_eq!(got, q, "SOL→token output equals the constant-product quote");
    println!(
        "cp-swap SOL→token: {} CU, in {SOL} out {got}",
        m.compute_units_consumed
    );

    // token → SOL (half of what we received); reserves now exclude accrued fees
    let sell = got / 2;
    let (p, q2) = cpmm_quote_live(&env, &k.pool_state, t.mint, sell);
    let w0 = env.load::<TokenAccount>(&wsol_ata).amount;
    let ix = cpmm_swap_ix(&tp, &k.pool_state, &p, t.mint, sell, q2);
    let m = env.send(ix, &[&trader]).expect("swap token→SOL");
    let got2 = env.load::<TokenAccount>(&wsol_ata).amount - w0;
    assert_eq!(
        got2, q2,
        "token→SOL output equals the constant-product quote"
    );
    println!(
        "cp-swap token→SOL: {} CU, in {sell} out {got2}",
        m.compute_units_consumed
    );
    assert!(
        got2 < SOL / 2,
        "round trip loses value to fees and price impact"
    );
}

// ───────────── config timelock ─────────────

fn pending(env: &Env) -> deep_curve::PendingConfig {
    env.load(&pending_config_pda())
}

#[test]
fn config_timelock_queue_apply_cancel() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let fr = env.fee_recipient.pubkey();
    let mig = env.migration.pubkey();
    env.set_unix_time(1_900_000_000);

    // 1. raise the timelock to 48h (applies immediately: current timelock is 0)
    let mut p = params(fr, mig);
    p.timelock_seconds = deep_curve::RECOMMENDED_MAINNET_TIMELOCK_SECONDS;
    env.update_config_now(p.clone()).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.timelock_seconds, 172_800);

    // 2. queue a fee change; apply before eta fails, after eta succeeds
    let mut fee_change = p.clone();
    fee_change.protocol_fee_bps = 90;
    let ix = env.ix_queue_config(&admin.pubkey(), fee_change.clone());
    env.send(ix, &[&admin]).unwrap();
    let pc = pending(&env);
    assert!(pc.active);
    assert_eq!(pc.eta, 1_900_000_000 + 172_800);
    assert_eq!(pc.params.protocol_fee_bps, 90);
    // only one change may be queued at a time
    let ix = env.ix_queue_config(&admin.pubkey(), p.clone());
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::ConfigUpdatePending)
    );
    let anyone = env.user(SOL);
    env.set_unix_time(1_900_000_000 + 172_799);
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::TimelockNotElapsed)
    );
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.protocol_fee_bps, 70, "unchanged before eta");
    env.set_unix_time(1_900_000_000 + 172_800);
    // permissionless: a random fee payer executes it
    let ix = env.ix_apply_config();
    env.send(ix, &[&anyone]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.protocol_fee_bps, 90);
    assert_eq!(
        cfg.admin,
        admin.pubkey(),
        "admin is not part of ConfigParams"
    );
    assert!(!pending(&env).active);
    // applying twice fails
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::NoPendingConfigUpdate)
    );

    // 3. cancel: admin only; afterwards apply fails even after eta
    let ix = env.ix_queue_config(&admin.pubkey(), p.clone());
    env.send(ix, &[&admin]).unwrap();
    let ix = env.ix_cancel_config(&anyone.pubkey());
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    let ix = env.ix_cancel_config(&admin.pubkey());
    env.send(ix, &[&admin]).unwrap();
    env.set_unix_time(1_900_000_000 + 3 * 172_800);
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::NoPendingConfigUpdate)
    );
    let ix = env.ix_cancel_config(&admin.pubkey());
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::NoPendingConfigUpdate)
    );
}

#[test]
fn shortening_the_timelock_is_itself_timelocked() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let (fr, mig) = (env.fee_recipient.pubkey(), env.migration.pubkey());
    env.set_unix_time(2_000_000_000);
    let mut p = params(fr, mig);
    p.timelock_seconds = 86_400;
    env.update_config_now(p.clone()).unwrap();

    // try to drop the timelock to 0 and change fees in the same breath
    let mut evil = p.clone();
    evil.timelock_seconds = 0;
    evil.protocol_fee_bps = 900;
    evil.creator_fee_bps = 100;
    let ixs = vec![
        env.ix_queue_config(&admin.pubkey(), evil),
        env.ix_apply_config(),
    ];
    assert_eq!(
        env.send_ixs(ixs, &[&admin]).unwrap_err(),
        custom(DeepError::TimelockNotElapsed)
    );
    let ix = env.ix_queue_config(&admin.pubkey(), {
        let mut q = p.clone();
        q.timelock_seconds = 0;
        q
    });
    env.send(ix, &[&admin]).unwrap();
    assert_eq!(
        pending(&env).eta,
        2_000_000_000 + 86_400,
        "old delay applies"
    );
    env.set_unix_time(2_000_000_000 + 86_399);
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::TimelockNotElapsed)
    );
    env.set_unix_time(2_000_000_000 + 86_400);
    let ix = env.ix_apply_config();
    env.send(ix, &[&admin]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.timelock_seconds, 0);
}

#[test]
fn stale_config_update_expires() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let (fr, mig) = (env.fee_recipient.pubkey(), env.migration.pubkey());
    env.set_unix_time(2_100_000_000);
    let mut p = params(fr, mig);
    p.timelock_seconds = 3_600;
    env.update_config_now(p.clone()).unwrap();
    let ix = env.ix_queue_config(&admin.pubkey(), p.clone());
    env.send(ix, &[&admin]).unwrap();
    let eta = pending(&env).eta;
    env.set_unix_time(eta + deep_curve::CONFIG_UPDATE_GRACE_SECONDS + 1);
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::ConfigUpdateExpired)
    );
    // recovery: cancel, re-queue, apply after the delay
    let ix = env.ix_cancel_config(&admin.pubkey());
    env.send(ix, &[&admin]).unwrap();
    let ix = env.ix_queue_config(&admin.pubkey(), p);
    env.send(ix, &[&admin]).unwrap();
    let eta = pending(&env).eta;
    env.set_unix_time(eta);
    let ix = env.ix_apply_config();
    env.send(ix, &[&admin]).unwrap();
}

#[test]
fn config_change_does_not_touch_live_curve_fees_and_pause_stays_immediate() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let (t, _) = env.create_token();
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.protocol_fee_bps = 200;
    p.timelock_seconds = 600;
    env.update_config_now(p).unwrap();
    let c = env.curve(&t);
    assert_eq!(c.protocol_fee_bps, 70, "fees are snapshotted at launch");
    // pause is not timelocked: takes effect in the same slot
    let ix = env.ix_set_paused(&admin.pubkey(), true);
    env.send(ix, &[&admin]).unwrap();
    let user = env.user(10 * SOL);
    assert_eq!(
        env.buy(&t, &user, SOL).unwrap_err(),
        custom(DeepError::Paused)
    );
}

#[test]
fn deep_amm_protocol_fees_can_only_go_to_the_fee_vault() {
    let mut env = Env::new();
    // AmmConfig #0 carries the init params, and the compiled-in fee owner
    let cfg = env.svm.get_account(&amm_config_0()).unwrap();
    assert_eq!(cfg.owner, deep_amm::ID);
    let cfg_d = &cfg.data;
    let u64_at = |o: usize| u64::from_le_bytes(cfg_d[o..o + 8].try_into().unwrap());
    assert_eq!(u64_at(12), AMM_TRADE_FEE_RATE);
    assert_eq!(u64_at(20), AMM_PROTOCOL_FEE_RATE);
    assert_eq!(u64_at(28), AMM_FUND_FEE_RATE);
    assert_eq!(u64_at(36), AMM_CREATE_POOL_FEE);
    assert_eq!(
        &cfg_d[44..76],
        deep_amm::protocol_fee_owner::ID.as_ref(),
        "protocol_owner"
    );
    assert_eq!(u64_at(108), AMM_CREATOR_FEE_RATE);
    assert_eq!(
        &cfg_d[44..76],
        fee_vault_pda().as_ref(),
        "protocol_owner = fee vault"
    );
    assert_eq!(AMM_FUND_FEE_RATE, 0, "DEEP V1: the fund fee is retired");
    assert_eq!(
        &cfg_d[76..108],
        deep_curve::BUILDER_WALLET.as_ref(),
        "fund_owner is the compiled-in builder wallet"
    );

    env.set_unix_time(1_800_000_000);
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    let receiver0 = env
        .load::<TokenAccount>(&deep_amm::create_pool_fee_reveiver::ID)
        .amount;
    env.graduate(&t, &migration).expect("graduate");
    // create-pool fee landed (as WSOL) in the fee vault's WSOL ATA
    let receiver = env.load::<TokenAccount>(&deep_amm::create_pool_fee_reveiver::ID);
    assert_eq!(receiver.amount - receiver0, AMM_CREATE_POOL_FEE);
    assert_eq!(receiver.owner, fee_vault_pda());

    // trade both ways
    env.set_unix_time(1_800_000_001);
    let k = pool_keys(&t.mint);
    let trader = env.user(10 * SOL);
    let tp = trader.pubkey();
    let wsol_ata = get_associated_token_address(&tp, &NATIVE_MINT);
    let wrap = vec![
        create_ata_ix(&tp, &tp, &NATIVE_MINT),
        create_ata_ix(&tp, &tp, &t.mint),
        anchor_lang::solana_program::system_instruction::transfer(&tp, &wsol_ata, 3 * SOL),
        anchor_spl::token::spl_token::instruction::sync_native(&anchor_spl::token::ID, &wsol_ata)
            .unwrap(),
    ];
    env.send_ixs(wrap, &[&trader]).unwrap();
    let (p, q) = cpmm_quote_live(&env, &k.pool_state, NATIVE_MINT, 2 * SOL);
    env.send(
        cpmm_swap_ix(&tp, &k.pool_state, &p, NATIVE_MINT, 2 * SOL, q),
        &[&trader],
    )
    .unwrap();
    let (p, q2) = cpmm_quote_live(&env, &k.pool_state, t.mint, q / 3);
    env.send(
        cpmm_swap_ix(&tp, &k.pool_state, &p, t.mint, q / 3, q2),
        &[&trader],
    )
    .unwrap();

    // protocol fee = floor(trade_fee * 333_333 / 1e6) per swap, accrued per side
    let pool = env.svm.get_account(&k.pool_state).unwrap().data;
    let pf0 = u64::from_le_bytes(pool[341..349].try_into().unwrap());
    let pf1 = u64::from_le_bytes(pool[349..357].try_into().unwrap());
    assert!(
        pf0 > 0 && pf1 > 0,
        "protocol fees accrued on both sides ({pf0}, {pf1})"
    );
    let wsol_side_fee = {
        let x = 2 * SOL as u128;
        let trade_fee = (x * AMM_TRADE_FEE_RATE as u128).div_ceil(1_000_000);
        (trade_fee * AMM_PROTOCOL_FEE_RATE as u128 / 1_000_000) as u64
    };
    let pool_s = read_cpmm_pool(&pool);
    let wsol_is_0 = pool_s.token_0_mint == NATIVE_MINT;
    assert_eq!(if wsol_is_0 { pf0 } else { pf1 }, wsol_side_fee);

    // The old collect path: no signer can take DEEP's fees any more. The admin bypass is gone,
    // the protocol owner is the keyless fee vault, so the fee owner, admin and a stranger fail.
    let (m0, m1) = (pool_s.token_0_mint, pool_s.token_1_mint);
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let fee_owner = load_keypair("AMM_FEE_OWNER_KEYPAIR");
    let mallory = env.user(SOL);
    for who in [&admin, &fee_owner, &mallory] {
        let w = who.pubkey();
        env.send_ixs(
            vec![create_ata_ix(&w, &w, &m0), create_ata_ix(&w, &w, &m1)],
            &[who],
        )
        .unwrap();
        assert_eq!(
            env.send(collect_protocol_fee_ix(&w, &k, &pool_s, &w), &[who])
                .unwrap_err(),
            CPMM_ERR_INVALID_OWNER,
            "collect_protocol_fee by {w}"
        );
    }
    // collect_protocol_fee_to_vault: wrong recipients are rejected, even from the admin
    let fv = fee_vault_pda();
    let (r0, r1) = (
        get_associated_token_address(&fv, &m0),
        get_associated_token_address(&fv, &m1),
    );
    let bad = get_associated_token_address(&mallory.pubkey(), &m0);
    for (x, y) in [
        (bad, r1),
        (r0, get_associated_token_address(&mallory.pubkey(), &m1)),
    ] {
        assert_eq!(
            env.send(collect_to_vault_ix(&k, &pool_s, x, y), &[&mallory])
                .unwrap_err(),
            CPMM_ERR_INVALID_PROTOCOL_FEE_RECIPIENT
        );
    }
    // anyone (here: a stranger) moves them into the vault's ATAs; the token-side ATA is created
    // by the caller first (idempotent).
    let token_mint = if wsol_is_0 { m1 } else { m0 };
    let mp = mallory.pubkey();
    let m = env
        .send_ixs(
            vec![
                create_ata_ix(&mp, &fv, &token_mint),
                collect_to_vault_ix(&k, &pool_s, r0, r1),
            ],
            &[&mallory],
        )
        .expect("collect_protocol_fee_to_vault (permissionless)");
    println!(
        "deep-amm CU: collect_protocol_fee_to_vault {}",
        m.compute_units_consumed
    );
    let wsol_ata = fee_vault_wsol();
    let token_ata = get_associated_token_address(&fv, &token_mint);
    let (wsol_fee, token_fee) = if wsol_is_0 { (pf0, pf1) } else { (pf1, pf0) };
    assert_eq!(
        env.load::<TokenAccount>(&wsol_ata).amount,
        AMM_CREATE_POOL_FEE + wsol_fee
    );
    assert_eq!(env.load::<TokenAccount>(&token_ata).amount, token_fee);
    let pool = env.svm.get_account(&k.pool_state).unwrap().data;
    assert_eq!(
        &pool[341..357],
        &[0u8; 16],
        "protocol fees reset after collection"
    );
    // nothing left: a second collect has nothing to do
    assert_eq!(
        env.send(collect_to_vault_ix(&k, &pool_s, r0, r1), &[&mallory])
            .unwrap_err(),
        CPMM_ERR_NO_FEE_COLLECT
    );

    // distribute: the WSOL (DeepSwap protocol fee + create-pool fee) is unwrapped and split;
    // the builder gets exactly 10% of everything that reached the vault.
    let before = vault_revenue(&env);
    let w0 = env.lamports(&env.treasury_wallet.pubkey());
    env.distribute().expect("distribute");
    let total = before + AMM_CREATE_POOL_FEE + wsol_fee;
    assert_eq!(builder_paid(&env), total / 10);
    assert_eq!(
        env.lamports(&env.treasury_wallet.pubkey()) - w0,
        total - total / 10
    );
    // the token-side fees stay in the vault's token ATA (outside the split); only the admin can
    // move them, and only to a token account of config.fee_recipient (withdraw_vault_tokens).
    let fr = env.fee_recipient.pubkey();
    let admin_c = env.admin.insecure_clone();
    let ap = admin_c.pubkey();
    env.send(create_ata_ix(&ap, &fr, &token_mint), &[&admin_c])
        .unwrap();
    let fr_ata = get_associated_token_address(&fr, &token_mint);
    let wd = |who: &Pubkey, mint: Pubkey, to: Pubkey, amount: u64| Instruction {
        program_id: deep_curve::ID,
        accounts: deep_curve::accounts::WithdrawVaultTokens {
            admin: *who,
            config: config_pda(),
            splitter: splitter_pda(),
            fee_vault: fv,
            mint,
            vault_token: get_associated_token_address(&fv, &mint),
            recipient_token: to,
            token_program: anchor_spl::token::ID,
        }
        .to_account_metas(None),
        data: deep_curve::instruction::WithdrawVaultTokens { amount }.data(),
    };
    assert_eq!(
        env.send(wd(&mp, token_mint, fr_ata, 1), &[&mallory])
            .unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    assert_eq!(
        env.send(wd(&ap, NATIVE_MINT, fr_ata, 1), &[&admin_c])
            .unwrap_err(),
        custom(DeepError::InvalidVaultToken),
        "WSOL leaves the vault only through distribute"
    );
    env.send(wd(&ap, token_mint, fr_ata, token_fee), &[&admin_c])
        .expect("withdraw_vault_tokens");
    assert_eq!(env.token_balance(&fr, &token_mint), token_fee);
}

fn collect_to_vault_ix(k: &PoolKeys, pool_s: &CpmmPool, r0: Pubkey, r1: Pubkey) -> Instruction {
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectProtocolFeeToVault {
            authority: k.authority,
            pool_state: k.pool_state,
            amm_config: amm_config_0(),
            token_0_vault: pool_s.token_0_vault,
            token_1_vault: pool_s.token_1_vault,
            vault_0_mint: pool_s.token_0_mint,
            vault_1_mint: pool_s.token_1_mint,
            recipient_token_0_account: r0,
            recipient_token_1_account: r1,
            token_program: anchor_spl::token::ID,
            token_program_2022: anchor_spl::token_2022::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectProtocolFeeToVault {}.data(),
    }
}

const CPMM_ERR_INVALID_PROTOCOL_FEE_RECIPIENT: u32 = 6018;

// ───────────── v2: per-curve protocol fees, sweep, account locks ─────────────

/// Writable / all account keys of a compiled transaction.
fn lock_sets(ixs: &[Instruction], payer: &Pubkey) -> (Vec<Pubkey>, Vec<Pubkey>) {
    let msg = solana_message::Message::new(ixs, Some(payer));
    let keys = msg.account_keys.clone();
    let h = &msg.header;
    let (signed, ro_signed, ro_unsigned) = (
        h.num_required_signatures as usize,
        h.num_readonly_signed_accounts as usize,
        h.num_readonly_unsigned_accounts as usize,
    );
    let writable = keys
        .iter()
        .enumerate()
        .filter(|(i, _)| *i < signed - ro_signed || (*i >= signed && *i < keys.len() - ro_unsigned))
        .map(|(_, k)| *k)
        .collect();
    (writable, keys)
}

#[test]
fn trades_on_different_tokens_share_no_writable_account() {
    let mut env = Env::new();
    let (a, _) = env.create_token();
    let (b, _) = env.create_token();
    let u1 = env.user(10 * SOL);
    let u2 = env.user(10 * SOL);
    for (ix1, ix2) in [
        (
            env.ix_buy(&a, &u1.pubkey(), SOL, 0, NO_DEADLINE),
            env.ix_buy(&b, &u2.pubkey(), SOL, 0, NO_DEADLINE),
        ),
        (
            env.ix_sell(&a, &u1.pubkey(), UNIT, 0, NO_DEADLINE),
            env.ix_sell(&b, &u2.pubkey(), UNIT, 0, NO_DEADLINE),
        ),
        (
            env.ix_buy(&a, &u1.pubkey(), SOL, 0, NO_DEADLINE),
            env.ix_sell(&b, &u2.pubkey(), UNIT, 0, NO_DEADLINE),
        ),
    ] {
        let (w1, _) = lock_sets(std::slice::from_ref(&ix1), &u1.pubkey());
        let (w2, _) = lock_sets(std::slice::from_ref(&ix2), &u2.pubkey());
        let shared: Vec<_> = w1.iter().filter(|k| w2.contains(k)).collect();
        assert!(shared.is_empty(), "shared writable accounts: {shared:?}");
        assert!(!w1.contains(&treasury_pda()) && !w2.contains(&treasury_pda()));
        assert!(!w1.contains(&config_pda()), "config is read-only");
        // exactly: user, curve, vault, user ATA
        assert_eq!(w1.len(), 4, "{w1:?}");
    }
    // and they really execute
    env.buy(&a, &u1, SOL).unwrap();
    env.buy(&b, &u2, SOL).unwrap();
    let ix = env.ix_sell(&a, &u1.pubkey(), UNIT, 0, NO_DEADLINE);
    env.send(ix, &[&u1]).unwrap();
}

#[test]
fn deep_amm_swap_has_no_global_writable_account() {
    let mut env = Env::new();
    env.set_unix_time(1_800_000_000);
    let (a, _) = env.create_token();
    env.complete_curve(&a);
    let migration = env.migration.insecure_clone();
    env.graduate(&a, &migration).unwrap();
    let k = pool_keys(&a.mint);
    let trader = Keypair::new().pubkey();
    let (p, _) = cpmm_quote_live(&env, &k.pool_state, NATIVE_MINT, SOL);
    let ix = cpmm_swap_ix(&trader, &k.pool_state, &p, NATIVE_MINT, SOL, 0);
    let (w, _) = lock_sets(&[ix], &trader);
    // trader (fee payer) + pool_state + 2 trader token accounts + 2 vaults + observation
    assert!(!w.contains(&amm_config_0()), "AmmConfig must be read-only");
    assert!(!w.contains(&k.authority));
    for per_pool in [k.pool_state, k.observation, k.token_vault, k.wsol_vault] {
        assert!(w.contains(&per_pool));
    }
    assert_eq!(w.len(), 7, "{w:?}");
}

#[test]
fn sweep_moves_accrued_fees_and_keeps_curves_solvent() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(100 * SOL);
    // nothing accrued yet
    let anyone = env.user(SOL);
    let ix = env.ix_sweep(&t);
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::ZeroAmount)
    );

    let q1 = math::quote_buy(&to_math(&env.curve(&t)), 7 * SOL, &fees(), 0).unwrap();
    env.buy(&t, &user, 7 * SOL).unwrap();
    let q2 = math::quote_sell(&to_math(&env.curve(&t)), q1.tokens_out / 3, &fees(), 0).unwrap();
    let ix = env.ix_sell(&t, &user.pubkey(), q1.tokens_out / 3, 0, NO_DEADLINE);
    env.send(ix, &[&user]).unwrap();
    let c = env.curve(&t);
    assert_eq!(
        c.protocol_fees_unclaimed,
        q1.fees.protocol + q2.fees.protocol
    );
    let rent = env
        .svm
        .minimum_balance_for_rent_exemption(8 + BondingCurve::INIT_SPACE);
    let owed = rent + c.real_sol_reserves + c.creator_fees_unclaimed + c.protocol_fees_unclaimed;
    assert_eq!(
        env.lamports(&t.curve),
        owed,
        "curve holds exactly what it owes"
    );

    let t0 = env.lamports(&treasury_pda());
    let ix = env.ix_sweep(&t);
    env.send(ix, &[&anyone]).unwrap();
    assert_eq!(vault_revenue(&env), c.protocol_fees_unclaimed);
    assert_eq!(env.lamports(&treasury_pda()), t0);
    assert_eq!(builder_paid(&env), 0);
    let c2 = env.curve(&t);
    assert_eq!(c2.protocol_fees_unclaimed, 0);
    assert_eq!(env.lamports(&t.curve), owed - c.protocol_fees_unclaimed);
    // creator fees untouched and still claimable; sell still works afterwards
    assert_eq!(c2.creator_fees_unclaimed, c.creator_fees_unclaimed);
    let creator = env.creator.insecure_clone();
    let ix = env.ix_claim(&t, &creator.pubkey());
    env.send(ix, &[&creator]).unwrap();
    let ix = env.ix_sell(&t, &user.pubkey(), UNIT, 0, NO_DEADLINE);
    env.send(ix, &[&user]).unwrap();
    // a swept-to account must be the real fee vault (not the Treasury, not another wallet)
    for wrong in [config_pda(), treasury_pda(), anyone.pubkey()] {
        let mut ix = env.ix_sweep(&t);
        ix.accounts[1].pubkey = wrong;
        assert!(env.send(ix, &[&anyone]).is_err());
    }
}

// ───────────── v2: Pyth-priced launch fee ─────────────

/// Synthetic PriceUpdateV2 (layout: pyth_solana_receiver_sdk price_update.rs).
fn price_update_data(
    feed: [u8; 32],
    full: bool,
    price: i64,
    conf: u64,
    expo: i32,
    publish: i64,
) -> Vec<u8> {
    let mut d = deep_curve::pyth::PRICE_UPDATE_V2_DISCRIMINATOR.to_vec();
    d.extend_from_slice(&[9u8; 32]); // write_authority
    if full {
        d.push(1);
    } else {
        d.extend_from_slice(&[0, 5]); // Partial { num_signatures: 5 }
    }
    d.extend_from_slice(&feed);
    d.extend_from_slice(&price.to_le_bytes());
    d.extend_from_slice(&conf.to_le_bytes());
    d.extend_from_slice(&expo.to_le_bytes());
    d.extend_from_slice(&publish.to_le_bytes());
    d.extend_from_slice(&(publish - 1).to_le_bytes()); // prev_publish_time
    d.extend_from_slice(&price.to_le_bytes()); // ema_price
    d.extend_from_slice(&conf.to_le_bytes()); // ema_conf
    d.extend_from_slice(&1234u64.to_le_bytes()); // posted_slot
    if full {
        d.push(0); // accounts are sized for the larger (Partial) variant
    }
    d
}

fn set_price(env: &mut Env, owner: Pubkey, data: Vec<u8>) {
    let lamports = env.svm.minimum_balance_for_rent_exemption(data.len());
    env.svm
        .set_account(
            deep_curve::pyth::SOL_USD_PRICE_UPDATE,
            solana_account::Account {
                lamports,
                data,
                owner,
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();
}

fn env_with_launch_fee(cents: u16) -> Env {
    let mut env = Env::new();
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.launch_fee_usd_cents = cents;
    env.update_config_now(p).unwrap();
    env
}

const NOW: i64 = 1_900_000_000;
const FEED: [u8; 32] = deep_curve::pyth::SOL_USD_FEED_ID;
const RECEIVER: Pubkey = deep_curve::pyth::RECEIVER_PROGRAM_ID;

#[test]
fn launch_fee_charged_exactly_and_accrued_on_the_curve() {
    let mut env = env_with_launch_fee(200);
    env.set_unix_time(NOW);
    // real devnet reading (2026-10-03): $120.30243981 ± 0.01196361, expo -8
    set_price(
        &mut env,
        RECEIVER,
        price_update_data(FEED, true, 12_030_243_981, 1_196_361, -8, NOW - 5),
    );
    let creator0 = env.lamports(&env.creator.pubkey());
    let t0 = env.lamports(&treasury_pda());
    let (t, meta) = env.create_token();
    let fee = deep_curve::pyth::launch_fee_lamports(200, 12_030_243_981, -8).unwrap();
    assert_eq!(fee, 16_624_767); // ceil(200·1e7·1e8 / 12_030_243_981)
    let c = env.curve(&t);
    assert_eq!(c.protocol_fees_unclaimed, fee);
    assert_eq!(
        env.lamports(&treasury_pda()),
        t0,
        "launch does not write the Treasury"
    );
    let rent = env
        .svm
        .minimum_balance_for_rent_exemption(8 + BondingCurve::INIT_SPACE);
    assert_eq!(env.lamports(&t.curve), rent + fee);
    assert!(creator0 - env.lamports(&env.creator.pubkey()) > fee);
    let events = meta
        .logs
        .iter()
        .filter(|l| l.contains("Program data:"))
        .count();
    assert!(
        events >= 2,
        "TokenCreated + LaunchFeeCharged emitted ({events})"
    );
    // sweepable like trade fees into the fee vault, and split by distribute (builder 10%)
    let ix = env.ix_sweep(&t);
    let admin = env.admin.insecure_clone();
    env.send(ix, &[&admin]).unwrap();
    assert_eq!(vault_revenue(&env), fee);
    assert_eq!(env.lamports(&treasury_pda()), t0);
    env.distribute().expect("distribute the launch fee");
    assert_eq!(builder_paid(&env), 1_662_476); // floor(16_624_767 / 10)
    assert_eq!(vault_revenue(&env), 0);
}

#[test]
fn launch_fee_rejects_bad_prices() {
    let mut env = env_with_launch_fee(200);
    env.set_unix_time(NOW);
    let creator = env.creator.insecure_clone();
    let try_create = |env: &mut Env, owner: Pubkey, data: Vec<u8>| {
        set_price(env, owner, data);
        let mint = Keypair::new();
        let ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Priced");
        env.send(ix, &[&creator, &mint]).map(|_| ())
    };
    let good = |publish: i64| price_update_data(FEED, true, 12_000_000_000, 1_000_000, -8, publish);
    // boundary: exactly 120 s old is accepted, 121 s is stale
    assert!(try_create(&mut env, RECEIVER, good(NOW - 120)).is_ok());
    assert_eq!(
        try_create(&mut env, RECEIVER, good(NOW - 121)).unwrap_err(),
        custom(DeepError::PriceStale)
    );
    // wrong owner (anyone can write an account with this layout elsewhere)
    assert_eq!(
        try_create(&mut env, anchor_lang::system_program::ID, good(NOW)).unwrap_err(),
        custom(DeepError::PriceFeedInvalid)
    );
    // wrong feed id
    let mut other = FEED;
    other[0] ^= 1;
    assert_eq!(
        try_create(
            &mut env,
            RECEIVER,
            price_update_data(other, true, 12_000_000_000, 1, -8, NOW)
        )
        .unwrap_err(),
        custom(DeepError::PriceFeedInvalid)
    );
    // partially verified
    assert_eq!(
        try_create(
            &mut env,
            RECEIVER,
            price_update_data(FEED, false, 12_000_000_000, 1, -8, NOW)
        )
        .unwrap_err(),
        custom(DeepError::PriceNotFullyVerified)
    );
    // confidence: exactly 2% ok, above rejected (at a realistic $120 price: a tiny
    // price would make the $2 fee exceed the creator's balance and fail for that instead)
    assert!(try_create(
        &mut env,
        RECEIVER,
        price_update_data(FEED, true, 12_000_000_000, 240_000_000, -8, NOW)
    )
    .is_ok());
    assert_eq!(
        try_create(
            &mut env,
            RECEIVER,
            price_update_data(FEED, true, 12_000_000_000, 240_000_001, -8, NOW)
        )
        .unwrap_err(),
        custom(DeepError::PriceConfidenceTooWide)
    );
    // non-positive price
    assert_eq!(
        try_create(
            &mut env,
            RECEIVER,
            price_update_data(FEED, true, 0, 0, -8, NOW)
        )
        .unwrap_err(),
        custom(DeepError::PriceNonPositive)
    );
    // garbage data / wrong discriminator
    assert_eq!(
        try_create(&mut env, RECEIVER, vec![0u8; 134]).unwrap_err(),
        custom(DeepError::PriceFeedInvalid)
    );
    // a different PriceUpdateV2 account (not the pinned sponsored feed) is refused
    let mint = Keypair::new();
    let mut ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Other");
    let idx = ix
        .accounts
        .iter()
        .position(|m| m.pubkey == deep_curve::pyth::SOL_USD_PRICE_UPDATE)
        .unwrap();
    ix.accounts[idx].pubkey = Keypair::new().pubkey();
    assert_eq!(
        env.send(ix, &[&creator, &mint]).unwrap_err(),
        custom(DeepError::PriceFeedInvalid)
    );
}

/// The Pyth price age is a compile-time choice: 120 s in the default build (`DEEP_CURVE_SO`,
/// what mainnet gets), 600 s in a build with `--features devnet` (`DEEP_CURVE_DEVNET_SO`,
/// what the devnet release build deploys). Same VM, same Config, same price account: only
/// the program binary differs.
#[test]
fn launch_fee_price_age_is_120s_by_default_and_600s_with_the_devnet_feature() {
    let mut env = env_with_launch_fee(200);
    env.set_unix_time(NOW);
    let creator = env.creator.insecure_clone();
    let try_create = |env: &mut Env, age: i64| {
        set_price(
            env,
            RECEIVER,
            price_update_data(FEED, true, 12_000_000_000, 1_000_000, -8, NOW - age),
        );
        let mint = Keypair::new();
        let ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Aged");
        env.send(ix, &[&creator, &mint])
    };
    let marker = deep_curve::pyth::DEVNET_BUILD_MARKER;
    let logged = |meta: &TransactionMetadata| meta.logs.iter().any(|l| l.contains(marker));

    // default build (the test crate is compiled without `devnet`, like the .so)
    assert_eq!(deep_curve::pyth::MAX_PRICE_AGE_SECONDS, 120);
    let meta = try_create(&mut env, 120).expect("120 s is accepted by the default build");
    assert!(
        !logged(&meta),
        "the default build never logs the devnet marker"
    );
    for age in [121, 300, 600] {
        assert_eq!(
            try_create(&mut env, age).unwrap_err(),
            custom(DeepError::PriceStale),
            "default build rejects a {age} s old price"
        );
    }

    // swap in the devnet build of the same program
    env.svm
        .add_program_from_file(deep_curve::ID, so_path("DEEP_CURVE_DEVNET_SO"))
        .expect("load the devnet deep_curve.so");
    for age in [120, 300, 600] {
        let meta = try_create(&mut env, age)
            .unwrap_or_else(|e| panic!("devnet build rejected a {age} s old price: {e}"));
        assert!(logged(&meta), "the devnet build logs its marker");
    }
    assert_eq!(
        try_create(&mut env, 601).unwrap_err(),
        custom(DeepError::PriceStale),
        "devnet build still rejects a price older than 600 s"
    );
}

#[test]
fn launch_fee_cap_and_zero_fee() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.launch_fee_usd_cents = deep_curve::MAX_LAUNCH_FEE_USD_CENTS + 1;
    let ix = env.ix_queue_config(&admin.pubkey(), p.clone());
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::LaunchFeeAboveCap)
    );
    p.launch_fee_usd_cents = deep_curve::MAX_LAUNCH_FEE_USD_CENTS;
    env.update_config_now(p.clone()).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.launch_fee_usd_cents, 2_000);
    // zero fee: no Pyth account needed at all (none exists in this VM) and nothing charged
    p.launch_fee_usd_cents = 0;
    env.update_config_now(p).unwrap();
    assert!(env
        .svm
        .get_account(&deep_curve::pyth::SOL_USD_PRICE_UPDATE)
        .is_none());
    let (t, _) = env.create_token();
    assert_eq!(env.curve(&t).protocol_fees_unclaimed, 0);
}

// ───────────── v2: migration of v1 accounts (devnet) ─────────────

fn truncate(env: &mut Env, key: &Pubkey, len: usize) {
    let mut a = env.svm.get_account(key).unwrap();
    a.data.truncate(len);
    a.lamports = env.svm.minimum_balance_for_rent_exemption(len);
    env.svm.set_account(*key, a).unwrap();
}

#[test]
fn migrate_v1_config_pending_and_curve() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let (t, _) = env.create_token();
    let user = env.user(10 * SOL);
    env.buy(&t, &user, SOL).unwrap();
    // queue a change so a PendingConfig exists, then make every account look v1
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.protocol_fee_bps = 80;
    let ix = env.ix_queue_config(&admin.pubkey(), p);
    env.send(ix, &[&admin]).unwrap();
    let pc_before = env.svm.get_account(&pending_config_pda()).unwrap().data;
    let bump = pc_before[pc_before.len() - 1];
    // v1 PendingConfig = the first 139 bytes of the params, then the bump
    let mut v1 = pc_before[..deep_curve::PENDING_CONFIG_V1_SIZE - 1].to_vec();
    v1.push(bump);
    let mut acct = env.svm.get_account(&pending_config_pda()).unwrap();
    acct.data = v1;
    env.svm.set_account(pending_config_pda(), acct).unwrap();
    truncate(&mut env, &config_pda(), deep_curve::CONFIG_V1_SIZE);
    // a v1 curve must also hold its real reserves + creator fees above rent
    let c = env.curve(&t);
    truncate(&mut env, &t.curve, deep_curve::BONDING_CURVE_V1_SIZE);
    let mut ca = env.svm.get_account(&t.curve).unwrap();
    ca.lamports += c.real_sol_reserves + c.creator_fees_unclaimed;
    env.svm.set_account(t.curve, ca).unwrap();

    // v1 accounts no longer deserialize: trading/admin fail closed until migrated
    assert!(env.buy(&t, &user, SOL).is_err());

    let payer = env.user(SOL);
    let mig_cfg = Instruction {
        program_id: deep_curve::ID,
        accounts: deep_curve::accounts::MigrateConfig {
            payer: payer.pubkey(),
            config: config_pda(),
            pending_config: pending_config_pda(),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_curve::instruction::MigrateConfig {}.data(),
    };
    let mig_curve = Instruction {
        program_id: deep_curve::ID,
        accounts: deep_curve::accounts::MigrateCurve {
            payer: payer.pubkey(),
            mint: t.mint,
            curve: t.curve,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_curve::instruction::MigrateCurve {}.data(),
    };
    let m = env
        .send_ixs(vec![mig_cfg.clone(), mig_curve.clone()], &[&payer])
        .expect("migrate");
    println!(
        "migrate_config + migrate_curve: {} CU",
        m.compute_units_consumed
    );
    // v1 accounts go straight to the current (v3) layout
    assert_eq!(env.svm.get_account(&config_pda()).unwrap().data.len(), 221);
    assert_eq!(
        env.svm
            .get_account(&pending_config_pda())
            .unwrap()
            .data
            .len(),
        173
    );
    assert_eq!(env.svm.get_account(&t.curve).unwrap().data.len(), 196);
    // the payer funds the extra rent: reserves and unclaimed fees stay fully backed
    assert_eq!(
        env.lamports(&t.curve),
        env.svm.minimum_balance_for_rent_exemption(196)
            + c.real_sol_reserves
            + c.creator_fees_unclaimed,
        "migrate_curve keeps the curve solvent"
    );
    let cfg: Config = env.load(&config_pda());
    assert_eq!(
        cfg.launch_fee_usd_cents, 0,
        "migration never turns a fee on"
    );
    assert_eq!(cfg.protocol_fee_bps, 70);
    assert_eq!(
        cfg.sell_protocol_fee_bps, 70,
        "sells keep the rate they paid"
    );
    assert_eq!((cfg.max_reward_bps, cfg.reserved_bps), (500, 0));
    let pc: deep_curve::PendingConfig = env.load(&pending_config_pda());
    assert!(pc.active);
    assert_eq!(pc.params.protocol_fee_bps, 80);
    assert_eq!(pc.params.sell_protocol_fee_bps, 80);
    assert_eq!(pc.params.launch_fee_usd_cents, 0);
    assert_eq!((pc.params.max_reward_bps, pc.params.reserved_bps), (500, 0));
    assert_eq!(pc.bump, bump);
    let migrated = env.curve(&t);
    assert_eq!(migrated.protocol_fees_unclaimed, 0);
    assert_eq!(migrated.sell_protocol_fee_bps, 70);
    assert_eq!(
        migrated.reward_model,
        deep_curve::math::REWARD_MODEL_CREATOR,
        "a curve with a creator fee keeps paying its creator"
    );
    assert_eq!(migrated.holder_fees_unclaimed, 0);
    // idempotent, and everything works again (including applying the migrated queue)
    env.send_ixs(vec![mig_cfg, mig_curve], &[&payer])
        .expect("second migrate is a no-op");
    env.buy(&t, &user, SOL).unwrap();
    let ix = env.ix_apply_config();
    env.send(ix, &[&user]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.protocol_fee_bps, 80);
    assert_eq!(cfg.sell_protocol_fee_bps, 80);
}

// ───────────── DeepSwap pool after graduation: swaps, fee policy, third-party LP ─────────────

/// deep-amm ErrorCode (error.rs, unchanged from upstream): InvalidOwner = 6001.
const CPMM_ERR_INVALID_OWNER: u32 = 6001;
/// PoolState offsets (states/pool.rs, after the 8-byte discriminator).
const POOL_LP_SUPPLY: usize = 333;
/// [protocol_0, protocol_1, fund_0, fund_1, creator_0, creator_1]
const POOL_FEE_OFFSETS: [usize; 6] = [341, 349, 357, 365, 397, 405];

fn pool_u64(env: &Env, pool_state: &Pubkey, off: usize) -> u64 {
    let d = env.svm.get_account(pool_state).unwrap().data;
    u64::from_le_bytes(d[off..off + 8].try_into().unwrap())
}

fn pool_fee_parts(env: &Env, pool_state: &Pubkey) -> [u64; 6] {
    POOL_FEE_OFFSETS.map(|o| pool_u64(env, pool_state, o))
}

fn live_pool(env: &Env, k: &PoolKeys) -> CpmmPool {
    read_cpmm_pool(&env.svm.get_account(&k.pool_state).unwrap().data)
}

/// Pool reserves excluding accrued fees, as (token_0, token_1).
fn pool_reserves(env: &Env, pool: &CpmmPool) -> (u64, u64) {
    (
        env.load::<TokenAccount>(&pool.token_0_vault).amount - pool.fees_0,
        env.load::<TokenAccount>(&pool.token_1_vault).amount - pool.fees_1,
    )
}

/// Live pool + reserves ordered (input side, output side) for `input_mint`.
fn live_reserves(env: &Env, k: &PoolKeys, input_mint: Pubkey) -> (CpmmPool, u64, u64) {
    let pool = live_pool(env, k);
    let (v0, v1) = pool_reserves(env, &pool);
    if input_mint == pool.token_0_mint {
        (pool, v0, v1)
    } else {
        (pool, v1, v0)
    }
}

/// Graduates a fresh token into DeepSwap and warps to the pool's open_time.
fn graduated_deepswap_pool(env: &mut Env) -> (Token, PoolKeys) {
    env.set_unix_time(1_800_000_000);
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    env.graduate(&t, &migration).expect("graduate");
    env.set_unix_time(1_800_000_001);
    let k = pool_keys(&t.mint);
    (t, k)
}

/// A funded user holding `wsol` lamports as WSOL and an empty ATA for `mint`.
fn deepswap_trader(env: &mut Env, mint: &Pubkey, wsol: u64) -> Keypair {
    let trader = env.user(wsol + 10 * SOL);
    let tp = trader.pubkey();
    let wsol_ata = get_associated_token_address(&tp, &NATIVE_MINT);
    let ixs = vec![
        create_ata_ix(&tp, &tp, &NATIVE_MINT),
        create_ata_ix(&tp, &tp, mint),
        anchor_lang::solana_program::system_instruction::transfer(&tp, &wsol_ata, wsol),
        anchor_spl::token::spl_token::instruction::sync_native(&anchor_spl::token::ID, &wsol_ata)
            .unwrap(),
    ];
    env.send_ixs(ixs, &[&trader]).expect("trader setup");
    trader
}

/// swap_base_input(a = amount_in, b = minimum_amount_out) or
/// swap_base_output(a = max_amount_in, b = amount_out), built from deep-amm's own
/// `#[derive(Accounts)]` struct.
fn amm_swap_ix(
    base_output: bool,
    trader: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
    input_mint: Pubkey,
    a: u64,
    b: u64,
) -> Instruction {
    let zero_for_one = input_mint == pool.token_0_mint;
    let (in_mint, out_mint, in_vault, out_vault) = if zero_for_one {
        (
            pool.token_0_mint,
            pool.token_1_mint,
            pool.token_0_vault,
            pool.token_1_vault,
        )
    } else {
        (
            pool.token_1_mint,
            pool.token_0_mint,
            pool.token_1_vault,
            pool.token_0_vault,
        )
    };
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::Swap {
            payer: *trader,
            authority: k.authority,
            amm_config: amm_config_0(),
            pool_state: k.pool_state,
            input_token_account: get_associated_token_address(trader, &in_mint),
            output_token_account: get_associated_token_address(trader, &out_mint),
            input_vault: in_vault,
            output_vault: out_vault,
            input_token_program: anchor_spl::token::ID,
            output_token_program: anchor_spl::token::ID,
            input_token_mint: in_mint,
            output_token_mint: out_mint,
            observation_state: pool.observation,
        }
        .to_account_metas(None),
        data: if base_output {
            deep_amm::instruction::SwapBaseOutput {
                max_amount_in: a,
                amount_out: b,
            }
            .data()
        } else {
            deep_amm::instruction::SwapBaseInput {
                amount_in: a,
                minimum_amount_out: b,
            }
            .data()
        },
    }
}

/// Independent re-implementation of cp-swap `CurveCalculator::swap_base_output` with
/// the creator fee off: input = ceil(ri*out / (ro-out)), grossed up by
/// ceil(x * 1e6 / (1e6 - trade_fee_rate)). Returns (amount_in, trade_fee).
fn cpmm_quote_base_output(out: u64, ri: u64, ro: u64, trade_fee_rate: u64) -> (u64, u64) {
    let swapped = (ri as u128 * out as u128).div_ceil(ro as u128 - out as u128);
    let d = CPMM_FEE_DENOMINATOR;
    let with_fee = (swapped * d).div_ceil(d - trade_fee_rate as u128);
    (with_fee as u64, (with_fee - swapped) as u64)
}

/// DEEP V1 fee policy: protocol share = floor(trade_fee * 333_333 / 1e6) (collected only into
/// the fee vault); the fund share is 0 (retired); the LP keeps the remainder.
fn protocol_cut(trade_fee: u64) -> u64 {
    (trade_fee as u128 * AMM_PROTOCOL_FEE_RATE as u128 / CPMM_FEE_DENOMINATOR) as u64
}

fn fund_cut(trade_fee: u64) -> u64 {
    (trade_fee as u128 * AMM_FUND_FEE_RATE as u128 / CPMM_FEE_DENOMINATOR) as u64
}

/// Executes one swap and checks it against the independent integer re-implementation:
/// a limit one unit too tight is rejected (min out / max in), the exact amounts move,
/// the protocol and builder (fund) fees accrue on the input side, creator fees stay 0, and
/// the reserves (excluding fees) move exactly as constant-product math says.
/// `amount` is amount_in (base input) or amount_out (base output).
/// Returns (amount_in, amount_out, protocol_fee, CU).
fn checked_deepswap_swap(
    env: &mut Env,
    trader: &Keypair,
    k: &PoolKeys,
    input_mint: Pubkey,
    base_output: bool,
    amount: u64,
) -> (u64, u64, u64, u64) {
    let tp = trader.pubkey();
    let (pool, ri, ro) = live_reserves(env, k, input_mint);
    let output_mint = if input_mint == pool.token_0_mint {
        pool.token_1_mint
    } else {
        pool.token_0_mint
    };
    let (exp_in, exp_out, trade_fee) = if base_output {
        let (i, f) = cpmm_quote_base_output(amount, ri, ro, AMM_TRADE_FEE_RATE);
        (i, amount, f)
    } else {
        let out = cpmm_quote(amount, ri, ro, AMM_TRADE_FEE_RATE, 0, true);
        let f = (amount as u128 * AMM_TRADE_FEE_RATE as u128).div_ceil(CPMM_FEE_DENOMINATOR);
        (amount, out, f as u64)
    };
    let exp_protocol = protocol_cut(trade_fee);
    let exp_fund = fund_cut(trade_fee);
    assert!(exp_out > 0 && trade_fee > 0);

    let tight = if base_output {
        amm_swap_ix(true, &tp, k, &pool, input_mint, exp_in - 1, amount)
    } else {
        amm_swap_ix(false, &tp, k, &pool, input_mint, amount, exp_out + 1)
    };
    assert_eq!(
        env.send(tight, &[trader]).unwrap_err(),
        CPMM_ERR_EXCEEDED_SLIPPAGE,
        "a limit one unit tighter than the quote must be rejected"
    );

    let in_ata = get_associated_token_address(&tp, &input_mint);
    let out_ata = get_associated_token_address(&tp, &output_mint);
    let in0 = env.load::<TokenAccount>(&in_ata).amount;
    let out0 = env.load::<TokenAccount>(&out_ata).amount;
    let fees0 = pool_fee_parts(env, &k.pool_state);
    let ix = if base_output {
        amm_swap_ix(true, &tp, k, &pool, input_mint, exp_in, amount)
    } else {
        amm_swap_ix(false, &tp, k, &pool, input_mint, amount, exp_out)
    };
    let m = env.send(ix, &[trader]).expect("swap at the exact quote");
    let spent = in0 - env.load::<TokenAccount>(&in_ata).amount;
    let got = env.load::<TokenAccount>(&out_ata).amount - out0;
    assert_eq!(
        (spent, got),
        (exp_in, exp_out),
        "amounts match constant-product math"
    );

    let mut fees_exp = fees0;
    let in_side = if input_mint == pool.token_0_mint {
        0
    } else {
        1
    };
    fees_exp[in_side] += exp_protocol;
    fees_exp[2 + in_side] += exp_fund;
    let fees1 = pool_fee_parts(env, &k.pool_state);
    assert_eq!(
        fees1, fees_exp,
        "only the input-side protocol and builder fund fees accrue"
    );
    assert_eq!(&fees1[4..], &[0; 2], "no creator fee at this test's rate");

    let (_, ri2, ro2) = live_reserves(env, k, input_mint);
    assert_eq!(
        ri2,
        ri + exp_in - exp_protocol - exp_fund,
        "LP keeps trade fee minus protocol and builder cuts"
    );
    assert_eq!(ro2, ro - exp_out);
    assert!(
        ri2 as u128 * ro2 as u128 >= ri as u128 * ro as u128,
        "k never decreases"
    );
    (spent, got, exp_protocol, m.compute_units_consumed)
}

fn collect_protocol_fee_ix(
    signer: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
    recipient: &Pubkey,
) -> Instruction {
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectProtocolFee {
            owner: *signer,
            authority: k.authority,
            pool_state: k.pool_state,
            amm_config: amm_config_0(),
            token_0_vault: pool.token_0_vault,
            token_1_vault: pool.token_1_vault,
            vault_0_mint: m0,
            vault_1_mint: m1,
            recipient_token_0_account: get_associated_token_address(recipient, &m0),
            recipient_token_1_account: get_associated_token_address(recipient, &m1),
            token_program: anchor_spl::token::ID,
            token_program_2022: anchor_spl::token_2022::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectProtocolFee {
            amount_0_requested: u64::MAX,
            amount_1_requested: u64::MAX,
        }
        .data(),
    }
}

#[test]
fn deepswap_swaps_match_constant_product_math_and_fee_policy() {
    let mut env = Env::new();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let pool = live_pool(&env, &k);
    // The creator fee is enabled on graduation pools; this test's AmmConfig keeps its
    // RATE at 0 (create_amm_config arg), so the amounts below are the plain 0.30% policy.
    // The creator fee itself is covered by the deepswap_creator_fee_* tests.
    assert!(pool.enable_creator_fee);
    let trader = deepswap_trader(&mut env, &t.mint, 5 * SOL);

    // swap_base_input both ways, then swap_base_output both ways
    let (_, bought, pf_a, cu_in_buy) =
        checked_deepswap_swap(&mut env, &trader, &k, NATIVE_MINT, false, SOL);
    let (_, _, pf_b, cu_in_sell) =
        checked_deepswap_swap(&mut env, &trader, &k, t.mint, false, bought / 2);
    let (_, _, pf_c, cu_out_buy) =
        checked_deepswap_swap(&mut env, &trader, &k, NATIVE_MINT, true, bought / 4);
    let (_, _, pf_d, cu_out_sell) =
        checked_deepswap_swap(&mut env, &trader, &k, t.mint, true, SOL / 10);
    println!(
        "deep-amm CU: swap_base_input SOL->token {cu_in_buy}, token->SOL {cu_in_sell}; \
         swap_base_output SOL->token {cu_out_buy}, token->SOL {cu_out_sell}"
    );
    // 0.30% fee: on 1 SOL the trade fee is 3_000_000 lamports; DEEP's protocol cut is
    // floor(3_000_000 * 333_333 / 1e6) = 999_999 (the builder's 10% of it is paid by the
    // splitter), no fund cut, and the LPs keep 2_000_001
    assert_eq!(pf_a, 999_999);
    assert_eq!(fund_cut(3_000_000), 0);
    assert_eq!(3_000_000 - pf_a, 2_000_001);

    // swap_base_output cannot drain the output reserve
    let (p, _, ro) = live_reserves(&env, &k, NATIVE_MINT);
    let ix = amm_swap_ix(true, &trader.pubkey(), &k, &p, NATIVE_MINT, u64::MAX, ro);
    assert_eq!(
        env.send(ix, &[&trader]).unwrap_err(),
        CPMM_ERR_INSUFFICIENT_VAULT,
        "amount_out = whole reserve rejected with a clean error, not a panic"
    );

    let wsol_is_0 = pool.token_0_mint == NATIVE_MINT;
    let (sol_side, tok_side) = (pf_a + pf_c, pf_b + pf_d);
    let fees = pool_fee_parts(&env, &k.pool_state);
    let expect = if wsol_is_0 {
        (sol_side, tok_side)
    } else {
        (tok_side, sol_side)
    };
    assert_eq!((fees[0], fees[1]), expect);

    // collect_protocol_fee: nobody can sign it (owner = keyless fee vault, no admin bypass);
    // collect_protocol_fee_to_vault moves exactly the accrued fees into the vault, by anyone.
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    let mallory = env.user(SOL);
    let mp = mallory.pubkey();
    env.send_ixs(
        vec![create_ata_ix(&mp, &mp, &m0), create_ata_ix(&mp, &mp, &m1)],
        &[&mallory],
    )
    .unwrap();
    let ix = collect_protocol_fee_ix(&mp, &k, &pool, &mp);
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        CPMM_ERR_INVALID_OWNER
    );
    let fv = fee_vault_pda();
    let (r0, r1) = (
        get_associated_token_address(&fv, &m0),
        get_associated_token_address(&fv, &m1),
    );
    let token_mint = if wsol_is_0 { m1 } else { m0 };
    env.send(create_ata_ix(&mp, &fv, &token_mint), &[&mallory])
        .unwrap();
    let (b0, b1) = (env.token_balance(&fv, &m0), env.token_balance(&fv, &m1));
    let reserves_before = pool_reserves(&env, &live_pool(&env, &k));
    env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&mallory])
        .expect("anyone collects into the vault");
    assert_eq!(
        (
            env.token_balance(&fv, &m0) - b0,
            env.token_balance(&fv, &m1) - b1
        ),
        expect,
        "the fee vault receives exactly the accrued protocol fees"
    );
    let left = pool_fee_parts(&env, &k.pool_state);
    assert_eq!(left, [0; 6], "protocol fees collected, no fund fees in V1");
    assert_eq!(
        pool_reserves(&env, &live_pool(&env, &k)),
        reserves_before,
        "LP reserves untouched by collection"
    );
}

/// Upstream `lp_tokens_to_trading_tokens`: floor, or ceil when `ceil` and floor > 0.
fn lp_to_tokens(lp: u64, supply: u64, vault: u64, ceil: bool) -> u64 {
    let n = lp as u128 * vault as u128;
    let q = n / supply as u128;
    (if ceil && q > 0 && !n.is_multiple_of(supply as u128) {
        q + 1
    } else {
        q
    }) as u64
}

/// deposit (a0/a1 = maximum amounts) or withdraw (a0/a1 = minimum amounts).
fn amm_lp_ix(
    deposit: bool,
    owner: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
    lp: u64,
    a0: u64,
    a1: u64,
) -> Instruction {
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    let owner_lp_token = get_associated_token_address(owner, &k.lp_mint);
    let (t0, t1) = (
        get_associated_token_address(owner, &m0),
        get_associated_token_address(owner, &m1),
    );
    if deposit {
        Instruction {
            program_id: deep_amm::ID,
            accounts: deep_amm::accounts::Deposit {
                owner: *owner,
                authority: k.authority,
                pool_state: k.pool_state,
                owner_lp_token,
                token_0_account: t0,
                token_1_account: t1,
                token_0_vault: pool.token_0_vault,
                token_1_vault: pool.token_1_vault,
                token_program: anchor_spl::token::ID,
                token_program_2022: anchor_spl::token_2022::ID,
                vault_0_mint: m0,
                vault_1_mint: m1,
                lp_mint: k.lp_mint,
            }
            .to_account_metas(None),
            data: deep_amm::instruction::Deposit {
                lp_token_amount: lp,
                maximum_token_0_amount: a0,
                maximum_token_1_amount: a1,
            }
            .data(),
        }
    } else {
        Instruction {
            program_id: deep_amm::ID,
            accounts: deep_amm::accounts::Withdraw {
                owner: *owner,
                authority: k.authority,
                pool_state: k.pool_state,
                owner_lp_token,
                token_0_account: t0,
                token_1_account: t1,
                token_0_vault: pool.token_0_vault,
                token_1_vault: pool.token_1_vault,
                token_program: anchor_spl::token::ID,
                token_program_2022: anchor_spl::token_2022::ID,
                vault_0_mint: m0,
                vault_1_mint: m1,
                lp_mint: k.lp_mint,
                memo_program: anchor_spl::memo::ID,
            }
            .to_account_metas(None),
            data: deep_amm::instruction::Withdraw {
                lp_token_amount: lp,
                minimum_token_0_amount: a0,
                minimum_token_1_amount: a1,
            }
            .data(),
        }
    }
}

#[test]
fn deepswap_third_party_lp_deposit_withdraw_and_graduation_lp_stays_burned() {
    let mut env = Env::new();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let pool = live_pool(&env, &k);
    let (g0, g1) = pool_reserves(&env, &pool);
    let l0 = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    // pool accounting still counts the graduation liquidity (incl. upstream's 100 locked
    // LP), but every minted LP token was burned: nobody holds a claim on it.
    assert_eq!(l0 as u128, (g0 as u128 * g1 as u128).isqrt());
    let lp_mint: Mint = env.load(&k.lp_mint);
    assert_eq!(lp_mint.supply, 0);
    assert_eq!(
        lp_mint.mint_authority.unwrap(),
        k.authority,
        "only deep-amm's PDA mints LP"
    );
    assert!(lp_mint.freeze_authority.is_none());

    // third-party LP: buys tokens on the pool, then deposits 1% of the LP supply
    let lp_user = deepswap_trader(&mut env, &t.mint, 30 * SOL);
    let lpk = lp_user.pubkey();
    let ix = amm_swap_ix(false, &lpk, &k, &pool, NATIVE_MINT, 15 * SOL, 1);
    env.send(ix, &[&lp_user]).expect("LP buys tokens");
    env.send(create_ata_ix(&lpk, &lpk, &k.lp_mint), &[&lp_user])
        .unwrap();
    let lp_ata = get_associated_token_address(&lpk, &k.lp_mint);
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    let bal = |env: &Env| (env.token_balance(&lpk, &m0), env.token_balance(&lpk, &m1));

    let pool = live_pool(&env, &k);
    let (v0, v1) = pool_reserves(&env, &pool);
    let l = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    assert_eq!(l, l0, "swaps do not change LP supply");
    let amt = l / 100;
    let (d0, d1) = (
        lp_to_tokens(amt, l, v0, true),
        lp_to_tokens(amt, l, v1, true),
    );
    // max-in slippage on either side
    for (x0, x1) in [(d0 - 1, d1), (d0, d1 - 1)] {
        let ix = amm_lp_ix(true, &lpk, &k, &pool, amt, x0, x1);
        assert_eq!(
            env.send(ix, &[&lp_user]).unwrap_err(),
            CPMM_ERR_EXCEEDED_SLIPPAGE
        );
    }
    let b0 = bal(&env);
    let ix = amm_lp_ix(true, &lpk, &k, &pool, amt, d0, d1);
    let m = env.send(ix, &[&lp_user]).expect("deposit");
    println!("deep-amm CU: deposit {}", m.compute_units_consumed);
    let b1 = bal(&env);
    assert_eq!(
        (b0.0 - b1.0, b0.1 - b1.1),
        (d0, d1),
        "deposit pays ceil(lp * reserve / supply)"
    );
    assert_eq!(env.load::<TokenAccount>(&lp_ata).amount, amt);
    assert_eq!(env.load::<Mint>(&k.lp_mint).supply, amt);
    assert_eq!(pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY), l + amt);

    // a trader pays fees into the pool while the LP is in
    let trader = deepswap_trader(&mut env, &t.mint, 5 * SOL);
    let ix = amm_swap_ix(false, &trader.pubkey(), &k, &pool, NATIVE_MINT, 3 * SOL, 1);
    env.send(ix, &[&trader]).expect("trade");

    let pool = live_pool(&env, &k);
    let (v0, v1) = pool_reserves(&env, &pool);
    let l = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    let (w0, w1) = (
        lp_to_tokens(amt, l, v0, false),
        lp_to_tokens(amt, l, v1, false),
    );
    // min-out slippage on either side; more LP than held
    for (x0, x1) in [(w0 + 1, w1), (w0, w1 + 1)] {
        let ix = amm_lp_ix(false, &lpk, &k, &pool, amt, x0, x1);
        assert_eq!(
            env.send(ix, &[&lp_user]).unwrap_err(),
            CPMM_ERR_EXCEEDED_SLIPPAGE
        );
    }
    let ix = amm_lp_ix(false, &lpk, &k, &pool, amt + 1, 0, 0);
    assert!(
        env.send(ix, &[&lp_user]).is_err(),
        "cannot burn more LP than held"
    );
    let b2 = bal(&env);
    let ix = amm_lp_ix(false, &lpk, &k, &pool, amt, w0, w1);
    let m = env.send(ix, &[&lp_user]).expect("withdraw");
    println!("deep-amm CU: withdraw {}", m.compute_units_consumed);
    let b3 = bal(&env);
    assert_eq!(
        (b3.0 - b2.0, b3.1 - b2.1),
        (w0, w1),
        "withdraw pays floor(lp * reserve / supply)"
    );
    assert!(
        w0 as u128 * w1 as u128 > d0 as u128 * d1 as u128,
        "the LP's share grew with trading fees"
    );
    assert_eq!(env.load::<TokenAccount>(&lp_ata).amount, 0);
    assert_eq!(env.load::<Mint>(&k.lp_mint).supply, 0);
    assert_eq!(pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY), l0);

    // the graduation liquidity stays locked: with LP supply 0 nobody can withdraw any of it
    let mallory = deepswap_trader(&mut env, &t.mint, SOL);
    let mp = mallory.pubkey();
    env.send(create_ata_ix(&mp, &mp, &k.lp_mint), &[&mallory])
        .unwrap();
    for lp in [1, l0 - 100, l0] {
        let ix = amm_lp_ix(false, &mp, &k, &pool, lp, 0, 0);
        assert!(
            env.send(ix, &[&mallory]).is_err(),
            "withdraw {lp} LP with none held"
        );
    }
    let ix = amm_lp_ix(false, &lpk, &k, &pool, 1, 0, 0);
    assert!(
        env.send(ix, &[&lp_user]).is_err(),
        "the exited LP holds nothing either"
    );
    let (e0, e1) = pool_reserves(&env, &live_pool(&env, &k));
    assert!(
        e0 as u128 * e1 as u128 >= g0 as u128 * g1 as u128,
        "the locked graduation liquidity is still in the pool"
    );
}

// ───────────── DeepSwap creator fee on graduation pools ─────────────
//
// Owner decision 2026-10-06: pools created by graduation charge a creator fee ON TOP of
// the 0.30% pool fee; it is split between the token's creator and DEEP. Both numbers are
// AmmConfig values the deep-amm admin changes with update_amm_config (params 7 and 8).

/// update_amm_config param codes (deep-amm instructions/admin/update_config.rs).
const AMM_PARAM_CREATOR_FEE_RATE: u8 = 7;
const AMM_PARAM_CREATOR_FEE_SHARE_RATE: u8 = 8;
/// The target policy: 0.30% creator fee, half of it retained by the protocol.
const TARGET_CREATOR_FEE_RATE: u64 = 3_000;
const TARGET_CREATOR_FEE_SHARE_RATE: u64 = 500_000;
/// deep-amm ErrorCode::NoFeeCollect.
const CPMM_ERR_NO_FEE_COLLECT: u32 = 6014;
/// AmmConfig offsets (states/config.rs, after the 8-byte discriminator).
const CFG_TRADE_FEE_RATE: usize = 12;
const CFG_CREATOR_FEE_RATE: usize = 108;
const CFG_CREATOR_FEE_SHARE_RATE: usize = 116;

fn amm_cfg_u64(env: &Env, off: usize) -> u64 {
    let d = env.svm.get_account(&amm_config_0()).unwrap().data;
    u64::from_le_bytes(d[off..off + 8].try_into().unwrap())
}

/// update_amm_config(param, value) signed by the compiled-in deep-amm admin.
fn set_amm_param(env: &mut Env, param: u8, value: u64) {
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let ix = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::UpdateAmmConfig {
            owner: admin.pubkey(),
            amm_config: amm_config_0(),
        }
        .to_account_metas(None),
        data: deep_amm::instruction::UpdateAmmConfig { param, value }.data(),
    };
    env.send(ix, &[&admin]).expect("update_amm_config");
}

fn set_target_creator_fee(env: &mut Env) {
    set_amm_param(env, AMM_PARAM_CREATOR_FEE_RATE, TARGET_CREATOR_FEE_RATE);
    set_amm_param(
        env,
        AMM_PARAM_CREATOR_FEE_SHARE_RATE,
        TARGET_CREATOR_FEE_SHARE_RATE,
    );
    assert_eq!(
        amm_cfg_u64(env, CFG_CREATOR_FEE_RATE),
        TARGET_CREATOR_FEE_RATE
    );
    assert_eq!(
        amm_cfg_u64(env, CFG_CREATOR_FEE_SHARE_RATE),
        TARGET_CREATOR_FEE_SHARE_RATE
    );
}

/// Independent re-implementation of deep-amm CurveCalculator::swap_base_input with the
/// creator fee: returns (amount_out, trade_fee, creator_fee).
/// Fee on input: total = ceil(x·(tr+cr)/1e6), creator = floor(total·cr/(tr+cr)),
/// trade = total − creator, and the curve prices x − total.
/// Fee on output: trade = ceil(x·tr/1e6), the curve prices x − trade, and
/// creator = ceil(swapped·cr/1e6) comes off what the trader receives.
fn cpmm_quote_with_creator_fee(
    amount_in: u64,
    reserve_in: u64,
    reserve_out: u64,
    trade_fee_rate: u64,
    creator_fee_rate: u64,
    creator_fee_on_input: bool,
) -> (u64, u64, u64) {
    let d = CPMM_FEE_DENOMINATOR;
    let (x, ri, ro) = (amount_in as u128, reserve_in as u128, reserve_out as u128);
    let (tr, cr) = (trade_fee_rate as u128, creator_fee_rate as u128);
    if creator_fee_on_input {
        let total = (x * (tr + cr)).div_ceil(d);
        let creator = total * cr / (tr + cr);
        let net = x - total;
        let out = net * ro / (ri + net);
        (out as u64, (total - creator) as u64, creator as u64)
    } else {
        let trade = (x * tr).div_ceil(d);
        let net = x - trade;
        let swapped = net * ro / (ri + net);
        let creator = (swapped * cr).div_ceil(d);
        ((swapped - creator) as u64, trade as u64, creator as u64)
    }
}

/// swap_base_input at the exact quote on a pool, checked against the re-implementation
/// above with the LIVE AmmConfig rates: one unit more min-out is rejected, the trader's
/// balances move by exactly (amount_in, out), the protocol cut of the trade fee accrues
/// on the input side and the creator fee accrues on the side the pool takes it in.
/// Returns (amount_out, trade_fee, creator_fee).
fn checked_creator_fee_swap(
    env: &mut Env,
    trader: &Keypair,
    k: &PoolKeys,
    input_mint: Pubkey,
    amount_in: u64,
) -> (u64, u64, u64) {
    let tp = trader.pubkey();
    let (pool, ri, ro) = live_reserves(env, k, input_mint);
    let zero_for_one = input_mint == pool.token_0_mint;
    let output_mint = if zero_for_one {
        pool.token_1_mint
    } else {
        pool.token_0_mint
    };
    let on_input = match pool.creator_fee_on {
        0 => true,
        1 => zero_for_one,
        _ => !zero_for_one,
    };
    let creator_rate = if pool.enable_creator_fee {
        amm_cfg_u64(env, CFG_CREATOR_FEE_RATE)
    } else {
        0
    };
    let (exp_out, trade_fee, creator_fee) = cpmm_quote_with_creator_fee(
        amount_in,
        ri,
        ro,
        amm_cfg_u64(env, CFG_TRADE_FEE_RATE),
        creator_rate,
        on_input,
    );
    let tight = amm_swap_ix(false, &tp, k, &pool, input_mint, amount_in, exp_out + 1);
    assert_eq!(
        env.send(tight, &[trader]).unwrap_err(),
        CPMM_ERR_EXCEEDED_SLIPPAGE
    );
    let in_ata = get_associated_token_address(&tp, &input_mint);
    let out_ata = get_associated_token_address(&tp, &output_mint);
    let in0 = env.load::<TokenAccount>(&in_ata).amount;
    let out0 = env.load::<TokenAccount>(&out_ata).amount;
    let fees0 = pool_fee_parts(env, &k.pool_state);
    let ix = amm_swap_ix(false, &tp, k, &pool, input_mint, amount_in, exp_out);
    env.send(ix, &[trader]).expect("swap at the exact quote");
    assert_eq!(in0 - env.load::<TokenAccount>(&in_ata).amount, amount_in);
    assert_eq!(env.load::<TokenAccount>(&out_ata).amount - out0, exp_out);

    let in_side = if zero_for_one { 0 } else { 1 };
    let creator_side = if on_input { in_side } else { 1 - in_side };
    let mut fees_exp = fees0;
    fees_exp[in_side] += protocol_cut(trade_fee);
    fees_exp[2 + in_side] += fund_cut(trade_fee);
    fees_exp[4 + creator_side] += creator_fee;
    assert_eq!(
        pool_fee_parts(env, &k.pool_state),
        fees_exp,
        "protocol and builder cuts on the input side, creator fee on its configured side"
    );
    // The LPs keep the trade fee minus the protocol and builder cuts; the creator fee never
    // reaches them.
    let (_, ri2, ro2) = live_reserves(env, k, input_mint);
    let (creator_in, creator_out) = if on_input {
        (creator_fee, 0)
    } else {
        (0, creator_fee)
    };
    assert_eq!(
        ri2,
        ri + amount_in - protocol_cut(trade_fee) - fund_cut(trade_fee) - creator_in
    );
    assert_eq!(ro2, ro - exp_out - creator_out);
    assert!(ri2 as u128 * ro2 as u128 >= ri as u128 * ro as u128);
    (exp_out, trade_fee, creator_fee)
}

fn creator_fee_share_pda(creator: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(
        &[
            b"creator_fee_share",
            creator.as_ref(),
            amm_config_0().as_ref(),
        ],
        &deep_amm::ID,
    )
    .0
}

/// collect_creator_fee, signed by the pool's recorded creator.
fn collect_creator_fee_ix(creator: &Pubkey, k: &PoolKeys, pool: &CpmmPool) -> Instruction {
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectCreatorFee {
            creator: *creator,
            authority: k.authority,
            pool_state: k.pool_state,
            amm_config: amm_config_0(),
            token_0_vault: pool.token_0_vault,
            token_1_vault: pool.token_1_vault,
            vault_0_mint: m0,
            vault_1_mint: m1,
            creator_token_0: get_associated_token_address(creator, &m0),
            creator_token_1: get_associated_token_address(creator, &m1),
            token_0_program: anchor_spl::token::ID,
            token_1_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            creator_fee_share: creator_fee_share_pda(creator),
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectCreatorFee {}.data(),
    }
}

/// collect_creator_fee_permissionless: any payer, the fee still goes to the creator.
fn collect_creator_fee_permissionless_ix(
    payer: &Pubkey,
    creator: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
) -> Instruction {
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectCreatorFeePermissionless {
            payer: *payer,
            creator: *creator,
            authority: k.authority,
            pool_state: k.pool_state,
            token_0_vault: pool.token_0_vault,
            token_1_vault: pool.token_1_vault,
            vault_0_mint: m0,
            vault_1_mint: m1,
            creator_token_0: get_associated_token_address(creator, &m0),
            creator_token_1: get_associated_token_address(creator, &m1),
            token_0_program: anchor_spl::token::ID,
            token_1_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            amm_config: amm_config_0(),
            creator_fee_share: creator_fee_share_pda(creator),
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectCreatorFeePermissionless {}.data(),
    }
}

#[test]
fn deepswap_creator_fee_is_charged_in_sol_and_split_between_creator_and_protocol() {
    for wsol_first in [true, false] {
        let mut env = Env::new();
        set_target_creator_fee(&mut env);
        env.set_unix_time(1_800_000_000);
        let t = env.create_token_ordered(wsol_first);
        env.complete_curve(&t);
        let migration = env.migration.insecure_clone();
        env.graduate(&t, &migration).expect("graduate");
        // replayed graduation still fails
        assert_eq!(
            env.graduate(&t, &migration).unwrap_err(),
            custom(DeepError::AlreadyGraduated)
        );
        env.set_unix_time(1_800_000_001);
        let k = pool_keys(&t.mint);
        let creator = env.creator.insecure_clone();
        let cp = creator.pubkey();

        // the pool is recorded to the TOKEN's creator, with the creator fee on, in WSOL
        let raw = env.svm.get_account(&k.pool_state).unwrap();
        assert_eq!(raw.owner, deep_amm::ID);
        assert_eq!(&raw.data[40..72], cp.as_ref(), "pool.pool_creator");
        let pool = live_pool(&env, &k);
        assert!(pool.enable_creator_fee);
        let sol_side = if pool.token_0_mint == NATIVE_MINT {
            0
        } else {
            1
        };
        assert_eq!(sol_side == 0, wsol_first);
        assert_eq!(
            pool.creator_fee_on,
            if wsol_first { 1 } else { 2 },
            "CreatorFeeOn::OnlyToken{{0,1}} = the WSOL side"
        );
        // LP is still fully burned
        let lp: Mint = env.load(&k.lp_mint);
        assert_eq!(lp.supply, 0, "LP tokens burned");
        assert!(env.svm.get_account(&k.creator_lp).is_none());
        assert_eq!(env.lamports(&k.pool_creator), 0);

        let trader = deepswap_trader(&mut env, &t.mint, 5 * SOL);

        // BUY 1 SOL (SOL is the input, so the creator fee is taken on the input):
        // total fee = ceil(1e9 · 6000 / 1e6) = 6_000_000 lamports (0.60%),
        // creator fee = floor(6_000_000 · 3000 / 6000) = 3_000_000, trade fee = 3_000_000,
        // protocol cut = floor(3_000_000 · 333_333 / 1e6) = 999_999, no fund cut (V1),
        // curve input 994_000_000.
        let (_, ri, ro) = live_reserves(&env, &k, NATIVE_MINT);
        let (bought, trade_fee, creator_fee) =
            checked_creator_fee_swap(&mut env, &trader, &k, NATIVE_MINT, SOL);
        assert_eq!((trade_fee, creator_fee), (3_000_000, 3_000_000));
        assert_eq!(
            bought as u128,
            994_000_000u128 * ro as u128 / (ri as u128 + 994_000_000)
        );
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!(fees[sol_side], 999_999);
        assert_eq!(fees[2 + sol_side], 0);
        assert_eq!(fees[4 + sol_side], 3_000_000);

        // SELL (the token is the input, so the creator fee comes off the SOL output):
        // trade fee = ceil(tokens · 3000 / 1e6) in the token, the curve prices the rest,
        // creator fee = ceil(sol_swapped · 3000 / 1e6) in SOL.
        let sell = bought / 2;
        let (_, ri, ro) = live_reserves(&env, &k, t.mint);
        let (sol_out, sell_trade_fee, sell_creator_fee) =
            checked_creator_fee_swap(&mut env, &trader, &k, t.mint, sell);
        let exp_trade = (sell as u128 * 3_000).div_ceil(1_000_000);
        let net = sell as u128 - exp_trade;
        let swapped = net * ro as u128 / (ri as u128 + net);
        let exp_creator = (swapped * 3_000).div_ceil(1_000_000);
        assert_eq!(
            (
                sol_out as u128,
                sell_trade_fee as u128,
                sell_creator_fee as u128
            ),
            (swapped - exp_creator, exp_trade, exp_creator)
        );
        let accrued = 3_000_000 + sell_creator_fee;
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!(fees[4 + sol_side], accrued, "creator fee accrues in WSOL");
        assert_eq!(fees[5 - sol_side], 0, "and never in the token");
        let token_protocol = protocol_cut(sell_trade_fee);
        assert_eq!(fees[1 - sol_side], token_protocol);

        // Only the recorded creator can sign collect_creator_fee.
        let mallory = env.user(SOL);
        let mp = mallory.pubkey();
        assert!(env
            .send(collect_creator_fee_ix(&mp, &k, &pool), &[&mallory])
            .is_err());

        // The creator collects: floor(accrued · 500_000 / 1e6) is booked to the protocol,
        // the creator receives the rest (the odd lamport, if any, stays with the creator).
        let reserves_before = pool_reserves(&env, &live_pool(&env, &k));
        assert_eq!(env.token_balance(&cp, &NATIVE_MINT), 0);
        env.send(collect_creator_fee_ix(&cp, &k, &pool), &[&creator])
            .expect("creator collects");
        let shared = accrued / 2;
        let creator_got = env.token_balance(&cp, &NATIVE_MINT);
        assert_eq!(creator_got, accrued - shared, "creator receives half");
        assert_eq!(creator_got + shared, accrued);
        assert!(creator_got - shared <= 1);
        assert_eq!(env.token_balance(&cp, &t.mint), 0, "nothing in the token");
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!((fees[4], fees[5]), (0, 0), "creator fees settled");
        assert_eq!(
            fees[sol_side],
            999_999 + shared,
            "the other half is booked as protocol fee"
        );
        assert_eq!(fees[1 - sol_side], token_protocol);
        assert_eq!(
            pool_reserves(&env, &live_pool(&env, &k)),
            reserves_before,
            "LP reserves untouched by the collection"
        );
        // nothing left: a second collection fails
        assert_eq!(
            env.send(collect_creator_fee_ix(&cp, &k, &pool), &[&creator])
                .unwrap_err(),
            CPMM_ERR_NO_FEE_COLLECT
        );

        // DEEP's side (the fee vault) receives the other half through
        // collect_protocol_fee_to_vault, together with its cut of the trade fees.
        let fv = fee_vault_pda();
        env.send(create_ata_ix(&mp, &fv, &t.mint), &[&mallory])
            .unwrap();
        let (w0, tk0) = (
            env.token_balance(&fv, &NATIVE_MINT),
            env.token_balance(&fv, &t.mint),
        );
        let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
        let ix = collect_to_vault_ix(
            &k,
            &pool,
            get_associated_token_address(&fv, &m0),
            get_associated_token_address(&fv, &m1),
        );
        env.send(ix, &[&mallory]).expect("collect into the vault");
        assert_eq!(
            env.token_balance(&fv, &NATIVE_MINT) - w0,
            999_999 + shared,
            "DEEP receives its trade-fee cut plus half of the creator fee, in WSOL"
        );
        assert_eq!(env.token_balance(&fv, &t.mint) - tk0, token_protocol);
        let left = pool_fee_parts(&env, &k.pool_state);
        assert_eq!(left, [0; 6], "everything collected; no fund fees in V1");

        // Params 7 and 8 take effect on the next swap and the next collection.
        set_amm_param(&mut env, AMM_PARAM_CREATOR_FEE_RATE, 5_000);
        set_amm_param(&mut env, AMM_PARAM_CREATOR_FEE_SHARE_RATE, 250_000);
        // total = ceil(5e8 · 8000 / 1e6) = 4_000_000; creator = floor(4e6 · 5000/8000)
        let (_, trade_fee, creator_fee) =
            checked_creator_fee_swap(&mut env, &trader, &k, NATIVE_MINT, SOL / 2);
        assert_eq!((trade_fee, creator_fee), (1_500_000, 2_500_000));
        // Anyone may trigger the collection; the creator's part still goes to the creator.
        let before = env.token_balance(&cp, &NATIVE_MINT);
        env.send(
            collect_creator_fee_permissionless_ix(&mp, &cp, &k, &pool),
            &[&mallory],
        )
        .expect("permissionless collection");
        assert_eq!(
            env.token_balance(&cp, &NATIVE_MINT) - before,
            2_500_000 - 625_000,
            "creator keeps 75% at share rate 250_000"
        );
        assert_eq!(env.token_balance(&mp, &NATIVE_MINT), 0);
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!(fees[sol_side], protocol_cut(1_500_000) + 625_000);
        assert_eq!((fees[4], fees[5]), (0, 0));
        // ...and it cannot be redirected to another "creator"
        assert!(env
            .send(
                collect_creator_fee_permissionless_ix(&mp, &mp, &k, &pool),
                &[&mallory],
            )
            .is_err());

        // Rate 0 switches the creator fee off again on the next swap.
        set_amm_param(&mut env, AMM_PARAM_CREATOR_FEE_RATE, 0);
        let (_, trade_fee, creator_fee) =
            checked_creator_fee_swap(&mut env, &trader, &k, NATIVE_MINT, SOL / 2);
        assert_eq!((trade_fee, creator_fee), (1_500_000, 0));
    }
}

#[test]
fn deepswap_pool_from_permissionless_initialize_charges_no_creator_fee() {
    let mut env = Env::new();
    set_target_creator_fee(&mut env);
    let (t, k) = graduated_deepswap_pool(&mut env);
    let user = deepswap_trader(&mut env, &t.mint, 20 * SOL);
    let up = user.pubkey();
    let grad_pool = live_pool(&env, &k);
    let ix = amm_swap_ix(false, &up, &k, &grad_pool, NATIVE_MINT, 5 * SOL, 1);
    env.send(ix, &[&user]).expect("user buys tokens");
    let tokens = env.token_balance(&up, &t.mint);

    // A second pool for the same pair, opened by anyone with the permissionless
    // initialize at the canonical cp-swap pool address.
    let (m0, m1) = (grad_pool.token_0_mint, grad_pool.token_1_mint);
    let pda = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let pool_state = pda(&[b"pool", amm_config_0().as_ref(), m0.as_ref(), m1.as_ref()]);
    let lp_mint = pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()]);
    let vault = |m: &Pubkey| pda(&[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()]);
    let k2 = PoolKeys {
        pool_state,
        lp_mint,
        token_vault: vault(&t.mint),
        wsol_vault: vault(&NATIVE_MINT),
        observation: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]),
        ..pool_keys(&t.mint)
    };
    let (a_sol, a_tok) = (2 * SOL, tokens / 2);
    let (init_amount_0, init_amount_1) = if m0 == NATIVE_MINT {
        (a_sol, a_tok)
    } else {
        (a_tok, a_sol)
    };
    let init = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::Initialize {
            creator: up,
            amm_config: amm_config_0(),
            authority: k2.authority,
            pool_state,
            token_0_mint: m0,
            token_1_mint: m1,
            lp_mint,
            creator_token_0: get_associated_token_address(&up, &m0),
            creator_token_1: get_associated_token_address(&up, &m1),
            creator_lp_token: get_associated_token_address(&up, &lp_mint),
            token_0_vault: vault(&m0),
            token_1_vault: vault(&m1),
            create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
            observation_state: k2.observation,
            token_program: anchor_spl::token::ID,
            token_0_program: anchor_spl::token::ID,
            token_1_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            rent: "SysvarRent111111111111111111111111111111111"
                .parse()
                .unwrap(),
        }
        .to_account_metas(None),
        data: deep_amm::instruction::Initialize {
            init_amount_0,
            init_amount_1,
            open_time: 0,
        }
        .data(),
    };
    env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), init], &[&user])
        .expect("permissionless initialize");
    env.set_unix_time(1_800_000_010);

    let raw = env.svm.get_account(&pool_state).unwrap();
    assert_eq!(&raw.data[40..72], up.as_ref(), "pool.pool_creator");
    let pool2 = live_pool(&env, &k2);
    assert!(
        !pool2.enable_creator_fee,
        "initialize() never enables the creator fee"
    );

    // Same AmmConfig (creator_fee_rate 3000), but this pool charges the 0.30% only.
    assert_eq!(
        amm_cfg_u64(&env, CFG_CREATOR_FEE_RATE),
        TARGET_CREATOR_FEE_RATE
    );
    let (_, ri, ro) = live_reserves(&env, &k2, NATIVE_MINT);
    let (out, trade_fee, creator_fee) =
        checked_creator_fee_swap(&mut env, &user, &k2, NATIVE_MINT, SOL);
    assert_eq!((trade_fee, creator_fee), (3_000_000, 0));
    assert_eq!(
        out,
        cpmm_quote(SOL, ri, ro, AMM_TRADE_FEE_RATE, 0, true),
        "priced with the trade fee alone"
    );
    let (_, _, creator_fee) = checked_creator_fee_swap(&mut env, &user, &k2, t.mint, out / 2);
    assert_eq!(creator_fee, 0);
    let fees = pool_fee_parts(&env, &pool_state);
    assert_eq!((fees[4], fees[5]), (0, 0));
    assert_eq!(
        env.send(collect_creator_fee_ix(&up, &k2, &pool2), &[&user])
            .unwrap_err(),
        CPMM_ERR_NO_FEE_COLLECT
    );

    // ...while the graduation pool of the same token does charge it.
    let (_, _, creator_fee) = checked_creator_fee_swap(&mut env, &user, &k, NATIVE_MINT, SOL);
    assert_eq!(creator_fee, 3_000_000);
}

#[test]
fn graduate_needs_the_permission_and_the_real_token_creator() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    let m = migration.pubkey();
    let k = pool_keys(&t.mint);

    // The pool's creator must be the curve's creator: nobody can be substituted.
    let mallory = env.user(SOL);
    for other in [mallory.pubkey(), m] {
        let ix = env.ix_graduate_as(&t, &m, amm_config_0(), raydium::CP_SWAP_PROGRAM_ID, other);
        assert_eq!(
            env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&migration])
                .unwrap_err(),
            custom(DeepError::InvalidPool)
        );
    }

    // Only the deep-amm admin can create a Permission.
    let mp = mallory.pubkey();
    let ix = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreatePermissionPda {
            owner: mp,
            permission_authority: mp,
            permission: permission_pda(&mp),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreatePermissionPda {}.data(),
    };
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        CPMM_ERR_INVALID_OWNER
    );

    // Security review F2: the graduation payer needs NO Permission. Even with the account
    // gone (it can no longer be closed; a deployment where it was never created is the same
    // state), graduation succeeds. A wrong address in its place is still refused by deep-amm.
    let saved = env.svm.get_account(&k.permission).expect("permission");
    assert_eq!(saved.owner, deep_amm::ID);
    assert_eq!(&saved.data[8..40], k.pool_creator.as_ref());
    env.svm
        .set_account(k.permission, solana_account::Account::default())
        .unwrap();
    let mut wrong = env.ix_graduate(&t, &m);
    for a in wrong.accounts.iter_mut() {
        if a.pubkey == k.permission {
            a.pubkey = permission_pda(&mp);
        }
    }
    assert_eq!(
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), wrong], &[&migration])
            .unwrap_err(),
        ANCHOR_CONSTRAINT_SEEDS,
        "deep-amm still pins the permission address"
    );
    assert!(!env.curve(&t).graduated);
    env.graduate(&t, &migration)
        .expect("graduate without any Permission account");
    assert!(env.curve(&t).graduated);
}

// ───────────── DEEP V1 Phase 1: fee vault + splitter (docs/V1_FEES.md) ─────────────
//
// All DEEP revenue lands in the deep-curve fee vault; the permissionless `distribute` pays the
// compiled-in builder wallet exactly 10% of everything over time (cumulative floor, never more)
// and the 90% to the destinations by bps. The checks below re-derive every amount with
// independent integer maths (not the program's `split_round`).

/// deep-amm ErrorCode::BuilderFeeLocked / ProtocolOwnerLocked / FeeRateAboveCap.
const CPMM_ERR_BUILDER_FEE_LOCKED: u32 = 6016;
const CPMM_ERR_PROTOCOL_OWNER_LOCKED: u32 = 6017;
const CPMM_ERR_FEE_RATE_ABOVE_CAP: u32 = 6019;

impl Env {
    /// queue + apply a splitter update in one transaction (valid while timelock_seconds == 0).
    fn update_splitter_now(&mut self, p: SplitterParams) -> Result<TransactionMetadata, u32> {
        let admin = self.admin.insecure_clone();
        let ixs = vec![
            self.ix_queue_splitter(&admin.pubkey(), p),
            self.ix_apply_splitter(),
        ];
        self.send_ixs(ixs, &[&admin])
    }

    /// The configured destinations' balances.
    fn dest_balances(&self) -> Vec<u64> {
        self.splitter()
            .active()
            .iter()
            .map(|d| self.lamports(&d.wallet))
            .collect()
    }
}

#[test]
fn curve_trades_are_unchanged_and_sweeps_route_everything_to_the_fee_vault() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(500 * SOL);
    let anyone = env.user(SOL);
    let mut swept = 0u64;
    let mut odd = 1_000_003u64;
    for i in 0..20 {
        // the trade itself is exactly the shared-fixture math (no splitter term in it)
        let sol_in = SOL / 3 + odd;
        odd = (odd * 7_919 + 13) % 900_000_007;
        let q = math::quote_buy(&to_math(&env.curve(&t)), sol_in, &fees(), 0).unwrap();
        let c0 = env.lamports(&t.curve);
        env.buy(&t, &user, sol_in).unwrap();
        assert_eq!(
            env.lamports(&t.curve) - c0,
            q.sol_in,
            "buy {i}: curve receives the quote"
        );
        assert_eq!(
            to_math(&env.curve(&t)),
            q.next,
            "buy {i}: state = fixture math"
        );
        let mut expect = q.fees.protocol;
        if i % 3 == 2 {
            let q2 =
                math::quote_sell(&to_math(&env.curve(&t)), q.tokens_out / 2, &fees(), 0).unwrap();
            let ix = env.ix_sell(&t, &user.pubkey(), q.tokens_out / 2, 0, NO_DEADLINE);
            env.send(ix, &[&user]).unwrap();
            assert_eq!(
                to_math(&env.curve(&t)),
                q2.next,
                "sell {i}: state = fixture math"
            );
            expect += q2.fees.protocol;
        }
        let base = env.curve(&t).protocol_fees_unclaimed;
        assert_eq!(base, expect);
        let v0 = vault_revenue(&env);
        let ix = env.ix_sweep(&t);
        env.send(ix, &[&anyone]).unwrap();
        assert_eq!(
            vault_revenue(&env) - v0,
            base,
            "sweep {i}: all of it to the vault"
        );
        swept += base;
    }
    assert_eq!(vault_revenue(&env), swept);
    assert_eq!(
        builder_paid(&env),
        0,
        "nothing reaches the builder before distribute"
    );
    let w0 = env.lamports(&env.treasury_wallet.pubkey());
    env.distribute().unwrap();
    assert_eq!(builder_paid(&env), swept / 10);
    assert_eq!(
        env.lamports(&env.treasury_wallet.pubkey()) - w0,
        swept - swept / 10
    );
}

#[test]
fn one_sol_buy_pays_the_builder_exactly_ten_percent_of_the_protocol_fee() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    let user = env.user(10 * SOL);
    let q = math::quote_buy(&to_math(&env.curve(&t)), SOL, &fees(), 0).unwrap();
    assert_eq!(
        q.fees.protocol, 7_000_000,
        "0.70% of 1 SOL (trade maths unchanged)"
    );
    env.buy(&t, &user, SOL).unwrap();
    let ix = env.ix_sweep(&t);
    env.send(ix, &[&user]).unwrap();
    // 7_000_000 is below the 0.01 SOL default minimum
    assert_eq!(
        env.distribute().unwrap_err(),
        custom(DeepError::BelowMinDistribute)
    );
    let mut p = splitter_params(&[(env.treasury_wallet.pubkey(), 10_000)]);
    p.min_distribute_lamports = 1_000_000;
    env.update_splitter_now(p).unwrap();
    let w0 = env.lamports(&env.treasury_wallet.pubkey());
    let m = env.distribute().unwrap();
    println!(
        "deep-curve CU: distribute (1 destination, no WSOL) {}",
        m.compute_units_consumed
    );
    assert_eq!(builder_paid(&env), 700_000);
    assert_eq!(env.lamports(&env.treasury_wallet.pubkey()) - w0, 6_300_000);
    let s = env.splitter();
    assert_eq!(s.base_total, 7_000_000);
    assert_eq!(s.builder_paid_total, 700_000);
    assert_eq!(s.distributions, 1);
    assert_eq!(s.active()[0].paid_total, 6_300_000);
    assert_eq!(vault_revenue(&env), 0);
}

#[test]
fn builder_gets_exactly_ten_percent_over_many_distributions_including_dust() {
    let mut env = Env::new();
    // three destinations, odd bps, and a 1-lamport minimum so dust-sized rounds run
    let wallets: Vec<Keypair> = (0..3).map(|_| env.user(SOL)).collect();
    let bps = [6_001u16, 2_999, 1_000];
    let mut p = splitter_params(&[
        (wallets[0].pubkey(), bps[0]),
        (wallets[1].pubkey(), bps[1]),
        (wallets[2].pubkey(), bps[2]),
    ]);
    p.min_distribute_lamports = 1;
    env.update_splitter_now(p).unwrap();

    let (mut total, mut retained) = (0u128, 0u128);
    let mut dests_total = [0u128; 3];
    let mut seed = 77u64;
    for i in 0..60 {
        seed = seed
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        // dust (1..=19 lamports) every third round, otherwise up to ~0.5 SOL
        let rev = if i % 3 == 0 {
            seed % 19 + 1
        } else {
            seed % 500_000_000 + 1
        };
        env.svm.airdrop(&fee_vault_pda(), rev).unwrap();
        let b0 = builder_paid(&env);
        let d0 = env.dest_balances();
        env.distribute()
            .unwrap_or_else(|e| panic!("round {i}: distribute failed {e}"));
        total += rev as u128;
        // independent re-derivation: builder cumulative floor; 90% pool incl. carried dust
        let builder_now = (total / 10) as u64;
        assert_eq!(
            builder_paid(&env),
            builder_now,
            "round {i}: builder = floor(10% of all)"
        );
        let pool = rev as u128 - (builder_now - b0) as u128 + retained;
        let mut paid = 0u128;
        for (j, b) in bps.iter().enumerate() {
            let share = pool * *b as u128 / 10_000;
            assert_eq!(
                (env.dest_balances()[j] - d0[j]) as u128,
                share,
                "round {i}: destination {j} by bps"
            );
            dests_total[j] += share;
            paid += share;
        }
        retained = pool - paid;
        assert!(retained < 3, "dust is at most one lamport per destination");
        assert_eq!(env.splitter().retained as u128, retained);
        let sp = env.splitter();
        assert_eq!(
            vault_revenue(&env),
            sp.retained + sp.owed_total().unwrap() + sp.builder_owed,
            "vault = rent + carried dust + owed, to the lamport"
        );
        assert_eq!(sp.owed_total().unwrap() + sp.builder_owed, 0);
    }
    // nothing lost, nothing counted twice
    let s = env.splitter();
    assert_eq!(s.base_total, total);
    assert_eq!(s.builder_paid_total as u128, total / 10);
    assert_eq!(
        s.builder_paid_total as u128 + dests_total.iter().sum::<u128>() + retained,
        total
    );
    for (j, d) in s.active().iter().enumerate() {
        assert_eq!(d.paid_total as u128, dests_total[j]);
        assert_eq!(d.owed, 0);
    }
}

#[test]
fn distribute_is_permissionless_and_checks_min_builder_and_destinations() {
    let mut env = Env::new();
    let tw = env.treasury_wallet.pubkey();
    // below the 0.01 SOL default minimum: rejected, by anyone
    env.svm.airdrop(&fee_vault_pda(), 9_999_999).unwrap();
    assert_eq!(
        env.distribute().unwrap_err(),
        custom(DeepError::BelowMinDistribute)
    );
    env.svm.airdrop(&fee_vault_pda(), 1).unwrap();
    let cranker = env.user(SOL);
    // a wrong builder account
    for wrong in [cranker.pubkey(), tw] {
        let ix = env.ix_distribute_with(cranker.pubkey(), wrong, &[tw]);
        assert_eq!(
            env.send(ix, &[&cranker]).unwrap_err(),
            custom(DeepError::InvalidBuilder)
        );
    }
    // destinations missing, extra, wrong, or read-only
    let b = deep_curve::BUILDER_WALLET;
    for dests in [vec![], vec![tw, tw], vec![cranker.pubkey()]] {
        let ix = env.ix_distribute_with(cranker.pubkey(), b, &dests);
        assert_eq!(
            env.send(ix, &[&cranker]).unwrap_err(),
            custom(DeepError::InvalidDestination),
            "{dests:?}"
        );
    }
    let mut ix = env.ix_distribute_with(cranker.pubkey(), b, &[tw]);
    ix.accounts.last_mut().unwrap().is_writable = false;
    assert_eq!(
        env.send(ix, &[&cranker]).unwrap_err(),
        custom(DeepError::InvalidDestination)
    );
    // the admin is not needed: a stranger cranks it
    let ix = env.ix_distribute_with(cranker.pubkey(), b, &[tw]);
    env.send(ix, &[&cranker]).expect("anyone can distribute");
    assert_eq!(builder_paid(&env), 1_000_000);
    // the splitter cannot be paused by the admin: set_paused does not affect distribute
    let admin = env.admin.insecure_clone();
    let ix = env.ix_set_paused(&admin.pubkey(), true);
    env.send(ix, &[&admin]).unwrap();
    env.svm.airdrop(&fee_vault_pda(), 20_000_000).unwrap();
    env.distribute()
        .expect("distribute while curves are paused");
    assert_eq!(builder_paid(&env), 3_000_000);
}

#[test]
fn an_unfunded_builder_is_owed_never_skipped_and_paid_in_full_later() {
    let mut env = Env::new();
    let b = deep_curve::BUILDER_WALLET;
    let rent0 = env.svm.minimum_balance_for_rent_exemption(0);
    let tw = env.treasury_wallet.pubkey();
    // the builder wallet does not exist (0 lamports)
    env.svm
        .set_account(b, solana_account::Account::default())
        .unwrap();
    let mut p = splitter_params(&[(tw, 10_000)]);
    p.min_distribute_lamports = 1;
    env.update_splitter_now(p).unwrap();
    // builder due 500_000 < the 0-byte rent minimum: credited to builder_owed, nothing fails
    env.svm.airdrop(&fee_vault_pda(), 5_000_000).unwrap();
    let w0 = env.lamports(&tw);
    env.distribute()
        .expect("distribute does not fail on the builder");
    assert_eq!(env.lamports(&b), 0);
    let s = env.splitter();
    assert_eq!(s.builder_owed, 500_000);
    assert_eq!(s.builder_paid_total, 500_000, "credited");
    assert_eq!(
        env.lamports(&tw) - w0,
        4_500_000,
        "the 90% is paid regardless"
    );
    assert_eq!(
        vault_revenue(&env),
        500_000,
        "owed builder pay stays in the vault"
    );
    // no new revenue: distribute still runs (owed outstanding) but cannot pay yet
    env.distribute().expect("no-op round");
    assert_eq!(env.splitter().builder_owed, 500_000);
    // more revenue: owed + new due reach rent exemption → paid in full, nothing re-split
    env.svm.airdrop(&fee_vault_pda(), 5_000_000).unwrap();
    env.distribute().unwrap();
    assert_eq!(env.lamports(&b), 1_000_000);
    assert!(env.lamports(&b) >= rent0);
    let s = env.splitter();
    assert_eq!(s.builder_owed, 0);
    assert_eq!(s.builder_paid_total, 1_000_000);
    assert_eq!(env.lamports(&tw) - w0, 9_000_000);
    assert_eq!(vault_revenue(&env), 0, "vault drained to the lamport");
}

#[test]
fn legacy_fund_fees_and_the_legacy_treasury_drain_exactly() {
    // Pre-V1 devnet pools hold builder fund fees accrued at 166_667 / 1e6; V1 accrues none. We
    // write such a balance into the pool (as the old binary would have) and drain it.
    let mut env = Env::new();
    let (_t, k) = graduated_deepswap_pool(&mut env);
    let pool = live_pool(&env, &k);
    let wsol_is_0 = pool.token_0_mint == NATIVE_MINT;
    let legacy = 1_234_567u64;
    let mut acc = env.svm.get_account(&k.pool_state).unwrap();
    let off = if wsol_is_0 { 357 } else { 365 }; // fund_fees_token_{0,1}
    acc.data[off..off + 8].copy_from_slice(&legacy.to_le_bytes());
    env.svm.set_account(k.pool_state, acc).unwrap();
    let builder = load_keypair("BUILDER_KEYPAIR");
    let b = builder.pubkey();
    env.svm.airdrop(&b, SOL).unwrap();
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    env.send_ixs(
        vec![create_ata_ix(&b, &b, &m0), create_ata_ix(&b, &b, &m1)],
        &[&builder],
    )
    .unwrap();
    env.send(collect_fund_fee_ix(&b, &k, &pool, &b), &[&builder])
        .expect("the builder drains legacy fund fees");
    assert_eq!(env.token_balance(&b, &NATIVE_MINT), legacy);
    assert_eq!(pool_fee_parts(&env, &k.pool_state), [0; 6]);

    // the pre-V1 Treasury balance: the admin withdraws all of it above rent
    let rent = env.lamports(&treasury_pda());
    env.svm.airdrop(&treasury_pda(), 3_333_333).unwrap();
    let admin = env.admin.insecure_clone();
    let fr = env.fee_recipient.pubkey();
    let ix = env.ix_withdraw(&admin.pubkey(), &fr, 3_333_333);
    env.send(ix, &[&admin]).unwrap();
    assert_eq!(env.lamports(&fr), 3_333_333);
    assert_eq!(env.lamports(&treasury_pda()), rent);
}

#[test]
fn an_unpayable_destination_is_owed_and_reassigned_on_removal_without_loss() {
    let mut env = Env::new();
    let tw = env.treasury_wallet.pubkey();
    // an executable account cannot take a system transfer: it must not block or strand funds.
    // (The DEEP programs themselves are refused as destinations, security review F10; any
    // other program can still be named, and is handled here.)
    let exe = anchor_spl::metadata::ID;
    let mut p = splitter_params(&[(tw, 5_000), (exe, 5_000)]);
    p.min_distribute_lamports = 1;
    env.update_splitter_now(p).unwrap();
    env.svm.airdrop(&fee_vault_pda(), 20_000_000).unwrap();
    let w0 = env.lamports(&tw);
    let e0 = env.lamports(&exe);
    env.distribute()
        .expect("an executable destination does not fail distribute");
    assert_eq!(env.lamports(&exe), e0);
    assert_eq!(env.splitter().active()[1].owed, 9_000_000);
    assert_eq!(env.lamports(&tw) - w0, 9_000_000);
    assert_eq!(vault_revenue(&env), 9_000_000);
    // removing it moves its owed into `retained`: the remaining destination gets it next round
    let mut only_tw = splitter_params(&[(tw, 10_000)]);
    only_tw.min_distribute_lamports = 1;
    env.update_splitter_now(only_tw).unwrap();
    let s = env.splitter();
    assert_eq!(s.retained, 9_000_000);
    assert_eq!(s.count, 1);
    env.svm.airdrop(&fee_vault_pda(), 10).unwrap();
    env.distribute().unwrap();
    // 10 new lamports: builder 1, pool 9 + 9_000_000 carried
    assert_eq!(env.lamports(&tw) - w0, 9_000_000 + 9_000_009);
    assert_eq!(builder_paid(&env), 2_000_001);
    assert_eq!(vault_revenue(&env), 0, "drained to the lamport");
    assert_eq!(builder_paid(&env) + (env.lamports(&tw) - w0), 20_000_010);
}

#[test]
fn destinations_change_only_through_the_timelock_and_only_by_the_admin() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let mallory = env.user(SOL);
    let new_dest = env.user(SOL);
    // a 1 hour timelock (itself applied through the config timelock, at 0 s now)
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.timelock_seconds = 3_600;
    env.update_config_now(p).unwrap();
    env.set_unix_time(NOW);
    let target = splitter_params(&[(new_dest.pubkey(), 10_000)]);

    // only the admin can queue or cancel
    let ix = env.ix_queue_splitter(&mallory.pubkey(), target.clone());
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    // invalid params are rejected at queue time
    let bad_sets: Vec<SplitterParams> = vec![
        splitter_params(&[]),
        splitter_params(&[(new_dest.pubkey(), 9_999)]),
        splitter_params(&[(new_dest.pubkey(), 5_000), (new_dest.pubkey(), 5_000)]),
        splitter_params(&[(deep_curve::BUILDER_WALLET, 10_000)]),
        splitter_params(&[(fee_vault_pda(), 10_000)]),
        splitter_params(&[(treasury_pda(), 10_000)]),
        splitter_params(&[(Pubkey::default(), 10_000)]),
        splitter_params(&[(new_dest.pubkey(), 10_000), (mallory.pubkey(), 0)]),
        splitter_params(
            &(0..9)
                .map(|i| (Pubkey::new_unique(), if i == 0 { 2_000 } else { 1_000 }))
                .collect::<Vec<_>>(),
        ),
        SplitterParams {
            min_distribute_lamports: 10 * SOL + 1,
            ..target.clone()
        },
        SplitterParams {
            min_distribute_lamports: 0,
            ..target.clone()
        },
    ];
    for bad in bad_sets {
        let ix = env.ix_queue_splitter(&admin.pubkey(), bad.clone());
        assert_eq!(
            env.send(ix, &[&admin]).unwrap_err(),
            custom(DeepError::InvalidSplitterParams),
            "{bad:?}"
        );
    }
    // 8 destinations is fine
    let eight: Vec<(Pubkey, u16)> = (0..8)
        .map(|i| (Pubkey::new_unique(), if i == 0 { 3_000 } else { 1_000 }))
        .collect();
    let ix = env.ix_queue_splitter(&admin.pubkey(), splitter_params(&eight));
    env.send(ix, &[&admin]).expect("8 destinations");
    // only one pending change; a stranger cannot cancel it; the admin can
    let ix = env.ix_queue_splitter(&admin.pubkey(), target.clone());
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::SplitterUpdatePending)
    );
    let ix = env.ix_cancel_splitter(&mallory.pubkey());
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    let ix = env.ix_cancel_splitter(&admin.pubkey());
    env.send(ix, &[&admin]).unwrap();
    let ix = env.ix_apply_splitter();
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::NoPendingSplitterUpdate)
    );

    // queue the real change: not before eta, by anyone after it
    let ix = env.ix_queue_splitter(&admin.pubkey(), target.clone());
    env.send(ix, &[&admin]).unwrap();
    env.set_unix_time(NOW + 3_599);
    let ix = env.ix_apply_splitter();
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::TimelockNotElapsed)
    );
    assert_eq!(
        env.splitter().active()[0].wallet,
        env.treasury_wallet.pubkey()
    );
    env.set_unix_time(NOW + 3_600);
    let ix = env.ix_apply_splitter();
    env.send(ix, &[&mallory])
        .expect("permissionless apply after eta");
    let s = env.splitter();
    assert_eq!(s.count, 1);
    assert_eq!(s.active()[0].wallet, new_dest.pubkey());
    assert_eq!(s.active()[0].bps, 10_000);
    // a stale change (past the 14-day grace) can only be cancelled
    let ix = env.ix_queue_splitter(&admin.pubkey(), target.clone());
    env.send(ix, &[&admin]).unwrap();
    env.set_unix_time(NOW + 3_600 + 3_600 + deep_curve::CONFIG_UPDATE_GRACE_SECONDS + 1);
    let ix = env.ix_apply_splitter();
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::ConfigUpdateExpired)
    );
    // revenue now goes to the new destination
    env.svm.airdrop(&fee_vault_pda(), 50_000_000).unwrap();
    let n0 = env.lamports(&new_dest.pubkey());
    env.distribute().unwrap();
    assert_eq!(env.lamports(&new_dest.pubkey()) - n0, 45_000_000);
    assert_eq!(builder_paid(&env), 5_000_000);
}

#[test]
fn an_unfunded_destination_is_owed_then_paid_in_full() {
    let mut env = Env::new();
    let fresh = Pubkey::new_unique(); // 0 lamports: below rent exemption
    let tw = env.treasury_wallet.pubkey();
    let mut p = splitter_params(&[(tw, 9_900), (fresh, 100)]);
    p.min_distribute_lamports = 1;
    env.update_splitter_now(p).unwrap();
    let rent0 = env.svm.minimum_balance_for_rent_exemption(0);
    // 10_000_000 revenue: 9_000_000 pool, fresh's 1% = 90_000 < rent: owed, others paid
    env.svm.airdrop(&fee_vault_pda(), 10_000_000).unwrap();
    let w0 = env.lamports(&tw);
    env.distribute().unwrap();
    assert_eq!(builder_paid(&env), 1_000_000);
    assert_eq!(env.lamports(&tw) - w0, 8_910_000);
    assert_eq!(env.lamports(&fresh), 0);
    assert_eq!(env.splitter().active()[1].owed, 90_000);
    assert_eq!(
        vault_revenue(&env),
        90_000,
        "owed lamports stay in the vault"
    );
    // owed + new share reach rent exemption: paid in full; owed is not new revenue
    let only_tw = splitter_params(&[(tw, 10_000)]);
    let need = rent0; // 0.9% of 100 x rent, plus the 90_000 owed, clears rent exemption
    env.svm.airdrop(&fee_vault_pda(), need * 100).unwrap();
    env.distribute().unwrap();
    let s = env.splitter();
    assert_eq!(s.active()[1].owed, 0);
    let fresh_share = (need * 100 - need * 10) / 100 + 90_000;
    assert_eq!(env.lamports(&fresh), fresh_share);
    assert_eq!(builder_paid(&env), (10_000_000 + need * 100) / 10);
    assert_eq!(vault_revenue(&env), s.retained, "only dust left");
    env.update_splitter_now(only_tw).expect("removable");
}

#[test]
fn initialize_splitter_is_admin_only_once_and_funds_the_vault() {
    let mut env = Env::new_without_splitter();
    let mallory = env.user(SOL);
    let p = splitter_params(&[(env.treasury_wallet.pubkey(), 10_000)]);
    let ix = env.ix_initialize_splitter(&mallory.pubkey(), p.clone());
    assert_eq!(
        env.send(ix, &[&mallory]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );
    let mut bad = p.clone();
    bad.destinations[0].bps = 1;
    let admin = env.admin.insecure_clone();
    let ix = env.ix_initialize_splitter(&admin.pubkey(), bad);
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::InvalidSplitterParams)
    );
    assert_eq!(env.lamports(&fee_vault_pda()), 0);
    let ix = env.ix_initialize_splitter(&admin.pubkey(), p.clone());
    env.send(ix, &[&admin]).expect("initialize_splitter");
    assert_eq!(
        env.lamports(&fee_vault_pda()),
        env.svm.minimum_balance_for_rent_exemption(0),
        "vault funded to its rent minimum"
    );
    let wsol: TokenAccount = env.load(&fee_vault_wsol());
    assert_eq!(wsol.owner, fee_vault_pda());
    assert_eq!(wsol.mint, NATIVE_MINT);
    let s = env.splitter();
    assert_eq!(s.count, 1);
    assert_eq!(s.min_distribute_lamports, 10_000_000);
    assert_eq!(s.builder_paid_total, 0);
    let ix = env.ix_initialize_splitter(&admin.pubkey(), p);
    assert!(env.send(ix, &[&admin]).is_err(), "second initialize fails");
}

#[test]
fn deepswap_fee_locks_fund_zero_protocol_owner_vault_and_ten_percent_cap() {
    let mut env = Env::new();
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let cfg = |env: &Env| env.svm.get_account(&amm_config_0()).unwrap().data;
    // param 2 (fund_fee_rate): only 0 (the retired builder fund fee) is accepted
    for v in [1, 166_667, 333_333, 1_000_000] {
        assert_eq!(
            env.send(update_amm_ix(2, v, None), &[&admin]).unwrap_err(),
            CPMM_ERR_BUILDER_FEE_LOCKED,
            "fund_fee_rate {v}"
        );
    }
    env.send(update_amm_ix(2, 0, None), &[&admin])
        .expect("fund fee back to 0 (the devnet migration step)");
    // param 4 (fund_owner): still only the builder (legacy fund fees stay the builder's)
    let fee_owner = load_keypair("AMM_FEE_OWNER_KEYPAIR");
    for k in [admin.pubkey(), fee_owner.pubkey(), fee_vault_pda()] {
        assert_eq!(
            env.send(update_amm_ix(4, 0, Some(k)), &[&admin])
                .unwrap_err(),
            CPMM_ERR_BUILDER_FEE_LOCKED,
            "fund_owner {k}"
        );
    }
    // param 3 (protocol_owner): the old instant bypass is closed, only the fee vault
    for k in [admin.pubkey(), fee_owner.pubkey(), Pubkey::new_unique()] {
        assert_eq!(
            env.send(update_amm_ix(3, 0, Some(k)), &[&admin])
                .unwrap_err(),
            CPMM_ERR_PROTOCOL_OWNER_LOCKED,
            "protocol_owner {k}"
        );
    }
    assert!(env.send(update_amm_ix(3, 0, None), &[&admin]).is_err());
    env.send(update_amm_ix(3, 0, Some(fee_vault_pda())), &[&admin])
        .expect("idempotent: the fee vault");
    assert_eq!(&cfg(&env)[44..76], fee_vault_pda().as_ref());
    // DEEP's protocol share stays adjustable (it is still DEEP revenue, split in the vault)
    env.send(update_amm_ix(1, 333_333, None), &[&admin])
        .unwrap();
    // 10% hard cap per side: trade + creator <= 100_000 (per 1e6)
    assert_eq!(
        env.send(update_amm_ix(0, 100_001, None), &[&admin])
            .unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    env.send(update_amm_ix(0, 97_000, None), &[&admin]).unwrap();
    assert_eq!(
        env.send(update_amm_ix(7, 3_001, None), &[&admin])
            .unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    env.send(update_amm_ix(7, 3_000, None), &[&admin]).unwrap();
    env.send(update_amm_ix(0, AMM_TRADE_FEE_RATE, None), &[&admin])
        .unwrap();
    // a new AmmConfig: fund fee must be 0, protocol owner = vault, cap applies
    let cfg1 = Pubkey::find_program_address(&[b"amm_config", &1u16.to_be_bytes()], &deep_amm::ID).0;
    let create = |fund: u64, trade: u64| Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreateAmmConfig {
            owner: admin.pubkey(),
            amm_config: cfg1,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreateAmmConfig {
            index: 1,
            trade_fee_rate: trade,
            protocol_fee_rate: 333_333,
            fund_fee_rate: fund,
            create_pool_fee: 0,
            creator_fee_rate: 0,
        }
        .data(),
    };
    assert_eq!(
        env.send(create(166_667, 3_500), &[&admin]).unwrap_err(),
        CPMM_ERR_BUILDER_FEE_LOCKED
    );
    assert_eq!(
        env.send(create(0, 100_001), &[&admin]).unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    env.send(create(0, 3_500), &[&admin]).unwrap();
    let c1 = env.svm.get_account(&cfg1).unwrap().data;
    assert_eq!(u64::from_le_bytes(c1[28..36].try_into().unwrap()), 0);
    assert_eq!(
        &c1[44..76],
        fee_vault_pda().as_ref(),
        "protocol_owner = vault"
    );
    assert_eq!(
        &c1[76..108],
        deep_curve::BUILDER_WALLET.as_ref(),
        "fund_owner = builder"
    );
}

#[test]
fn legacy_fund_fee_collection_stays_builder_only() {
    let mut env = Env::new();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let pool = live_pool(&env, &k);
    let trader = deepswap_trader(&mut env, &t.mint, 5 * SOL);
    checked_deepswap_swap(&mut env, &trader, &k, NATIVE_MINT, false, SOL);
    let fees = pool_fee_parts(&env, &k.pool_state);
    assert_eq!((fees[2], fees[3]), (0, 0), "V1: no fund fee accrues");
    // the admin, the fee owner and a stranger still cannot call collect_fund_fee
    let fee_owner = load_keypair("AMM_FEE_OWNER_KEYPAIR");
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let stranger = env.user(SOL);
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    for who in [&admin, &fee_owner, &stranger] {
        let w = who.pubkey();
        env.svm.airdrop(&w, SOL).unwrap();
        env.send_ixs(
            vec![create_ata_ix(&w, &w, &m0), create_ata_ix(&w, &w, &m1)],
            &[who],
        )
        .unwrap();
        assert_eq!(
            env.send(collect_fund_fee_ix(&w, &k, &pool, &w), &[who])
                .unwrap_err(),
            CPMM_ERR_INVALID_OWNER,
            "collect_fund_fee by {w}"
        );
    }
}

fn update_amm_ix(param: u8, value: u64, remaining: Option<Pubkey>) -> Instruction {
    let admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let mut accounts = deep_amm::accounts::UpdateAmmConfig {
        owner: admin.pubkey(),
        amm_config: amm_config_0(),
    }
    .to_account_metas(None);
    if let Some(k) = remaining {
        accounts.push(anchor_lang::prelude::AccountMeta::new_readonly(k, false));
    }
    Instruction {
        program_id: deep_amm::ID,
        accounts,
        data: deep_amm::instruction::UpdateAmmConfig { param, value }.data(),
    }
}

fn collect_fund_fee_ix(
    signer: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
    recipient: &Pubkey,
) -> Instruction {
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectFundFee {
            owner: *signer,
            authority: k.authority,
            pool_state: k.pool_state,
            amm_config: amm_config_0(),
            token_0_vault: pool.token_0_vault,
            token_1_vault: pool.token_1_vault,
            vault_0_mint: m0,
            vault_1_mint: m1,
            recipient_token_0_account: get_associated_token_address(recipient, &m0),
            recipient_token_1_account: get_associated_token_address(recipient, &m1),
            token_program: anchor_spl::token::ID,
            token_program_2022: anchor_spl::token_2022::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectFundFee {
            amount_0_requested: u64::MAX,
            amount_1_requested: u64::MAX,
        }
        .data(),
    }
}

// ───────────── DEEP V1 Phase 2: per-side protocol fee + reward model on the curve ─────────────

use deep_curve::math::{FeesV1, REWARD_MODEL_CREATOR, REWARD_MODEL_HOLDER, REWARD_MODEL_STANDARD};

const MODELS: [u8; 3] = [
    REWARD_MODEL_STANDARD,
    REWARD_MODEL_CREATOR,
    REWARD_MODEL_HOLDER,
];
/// Anchor `ConstraintSeeds` / `AccountNotSystemOwned`.
const ANCHOR_CONSTRAINT_SEEDS: u32 = 2006;
const ANCHOR_NOT_SYSTEM_OWNED: u32 = 3011;

fn holder_vault(mint: &Pubkey) -> Pubkey {
    deep_curve::holder_vault_address(mint)
}

/// The curve fee schedule under V1: buy / sell protocol bps, no legacy creator fee, and the
/// curve reward rates (0 by default).
fn v1_params(
    env: &Env,
    buy: u16,
    sell: u16,
    creator_reward: u16,
    holder_reward: u16,
) -> ConfigParams {
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.protocol_fee_bps = buy;
    p.sell_protocol_fee_bps = sell;
    p.creator_fee_bps = 0;
    TEST_REWARD_BPS.with(|c| c.set((creator_reward, holder_reward)));
    p
}

thread_local! {
    /// The reward rates the test's creator chooses for Creator / Holder tokens launched with
    /// `create_token_model` (0 = the default, 100 bps). Set by `v1_params`; each test runs on
    /// its own thread. The rate is the creator's choice at launch, never a Config value.
    static TEST_REWARD_BPS: std::cell::Cell<(u16, u16)> = const { std::cell::Cell::new((0, 0)) };
}

fn trade_events(meta: &TransactionMetadata) -> Vec<deep_curve::TradeEvent> {
    use anchor_lang::{AnchorDeserialize, Discriminator};
    use base64::Engine;
    meta.logs
        .iter()
        .filter_map(|l| l.strip_prefix("Program data: "))
        .filter_map(|b| base64::engine::general_purpose::STANDARD.decode(b).ok())
        .filter(|d| d.len() > 8 && d[..8] == *deep_curve::TradeEvent::DISCRIMINATOR)
        .map(|d| deep_curve::TradeEvent::try_from_slice(&d[8..]).expect("TradeEvent"))
        .collect()
}

impl Env {
    /// A token of `model` with the reward rate these tests' creator picks: 0 for Standard;
    /// for Creator / Holder the rate the test chose through `v1_params`, or 100 bps (1%).
    fn try_create_token_model(&mut self, model: u8) -> Result<Token, u32> {
        let (creator_bps, holder_bps) = TEST_REWARD_BPS.with(|c| c.get());
        let pick = |v: u16| if v == 0 { 100 } else { v };
        let reward_bps = match model {
            REWARD_MODEL_STANDARD => 0,
            REWARD_MODEL_CREATOR => pick(creator_bps),
            _ => pick(holder_bps),
        };
        self.try_create_token_reward(model, reward_bps)
    }

    fn try_create_token_reward(&mut self, model: u8, reward_bps: u16) -> Result<Token, u32> {
        let mint = Keypair::new();
        let creator = self.creator.insecure_clone();
        let mut ix = self.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Deep Test");
        // the argument tail: reward_model (u8), reward_bps (u16 LE),
        // max_launch_fee_lamports (u64 LE)
        let n = ix.data.len();
        ix.data[n - 11] = model;
        ix.data[n - 10..n - 8].copy_from_slice(&reward_bps.to_le_bytes());
        self.send(ix, &[&creator, &mint])?;
        let curve = curve_pda(&mint.pubkey());
        Ok(Token {
            mint: mint.pubkey(),
            curve,
            vault: get_associated_token_address(&curve, &mint.pubkey()),
        })
    }

    fn create_token_model(&mut self, model: u8) -> Token {
        self.try_create_token_model(model).expect("create_token")
    }

    fn create_token_reward(&mut self, model: u8, reward_bps: u16) -> Token {
        self.try_create_token_reward(model, reward_bps)
            .expect("create_token")
    }

    fn ix_sweep_holder(&self, t: &Token) -> Instruction {
        Instruction {
            program_id: deep_curve::ID,
            accounts: deep_curve::accounts::SweepHolderFees {
                curve: t.curve,
                holder_vault: holder_vault(&t.mint),
            }
            .to_account_metas(None),
            data: deep_curve::instruction::SweepHolderFees {}.data(),
        }
    }

    fn sell(&mut self, t: &Token, user: &Keypair, tokens: u64) -> Result<TransactionMetadata, u32> {
        let ix = self.ix_sell(t, &user.pubkey(), tokens, 0, NO_DEADLINE);
        self.send(ix, &[user])
    }

    fn rent0(&self) -> u64 {
        self.svm.minimum_balance_for_rent_exemption(0)
    }

    /// Lamports a curve PDA holds ABOVE everything it owes (rent, reserves and the three fee
    /// accumulators). Must be exactly 0: nothing unaccounted, nothing missing.
    fn curve_surplus(&self, t: &Token) -> i128 {
        let c = self.curve(t);
        let rent = self
            .svm
            .minimum_balance_for_rent_exemption(8 + BondingCurve::INIT_SPACE);
        self.lamports(&t.curve) as i128
            - (rent as i128
                + c.real_sol_reserves as i128
                + c.creator_fees_unclaimed as i128
                + c.holder_fees_unclaimed as i128
                + c.protocol_fees_unclaimed as i128)
    }
}

/// The V1 target (owner decision, V1_FEES.md section 10): 1.25% to DEEP on buy and on sell.
/// A Standard token charges nothing else (tokens with a reward rate: the next tests).
#[test]
fn v1_target_charges_125_bps_to_deep_per_side_and_stores_the_model() {
    let mut env = Env::new();
    let p = v1_params(&env, 125, 125, 0, 0);
    env.update_config_now(p).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(
        (
            cfg.protocol_fee_bps,
            cfg.sell_protocol_fee_bps,
            cfg.creator_fee_bps
        ),
        (125, 125, 0)
    );
    assert_eq!((cfg.max_reward_bps, cfg.reserved_bps), (500, 0));

    {
        let model = REWARD_MODEL_STANDARD;
        let t = env.create_token_model(model);
        let c = env.curve(&t);
        assert_eq!(c.reward_model, model, "the model is stored on the curve");
        assert_eq!(
            c.fees_v1(),
            FeesV1 {
                buy_protocol_fee_bps: 125,
                sell_protocol_fee_bps: 125,
                reward_bps: 0,
                reward_model: model
            }
        );
        // raw byte the SDK / Phase 3 read: BondingCurve.reward_model at offset 187
        assert_eq!(env.svm.get_account(&t.curve).unwrap().data[187], model);

        let user = env.user(50 * SOL);
        let m = env.buy(&t, &user, SOL).unwrap();
        let c = env.curve(&t);
        assert_eq!(c.protocol_fees_unclaimed, 12_500_000, "1.25% of 1 SOL");
        assert_eq!((c.creator_fees_unclaimed, c.holder_fees_unclaimed), (0, 0));
        let ev = trade_events(&m);
        assert_eq!(ev.len(), 1);
        assert_eq!(
            (
                ev[0].protocol_fee,
                ev[0].creator_fee,
                ev[0].holder_fee,
                ev[0].reward_model
            ),
            (12_500_000, 0, 0, model)
        );

        let tokens = env.token_balance(&user.pubkey(), &t.mint) / 2;
        let (q, r) = math::quote_sell_v1(&to_math(&c), tokens, &c.fees_v1(), 0).unwrap();
        assert_eq!(
            q.fees.total,
            (q.sol_from_curve as u128 * 125).div_ceil(10_000) as u64
        );
        assert_eq!((r.creator, r.holder), (0, 0));
        let u0 = env.lamports(&user.pubkey());
        env.sell(&t, &user, tokens).unwrap();
        assert_eq!(env.lamports(&user.pubkey()) - u0, q.sol_out - 5_000);
        let c2 = env.curve(&t);
        assert_eq!(to_math(&c2), q.next);
        assert_eq!(c2.protocol_fees_unclaimed, 12_500_000 + q.fees.total);
        assert_eq!(
            (c2.creator_fees_unclaimed, c2.holder_fees_unclaimed),
            (0, 0)
        );
        assert_eq!(env.curve_surplus(&t), 0);

        // no reward accrued: nothing to claim or sweep to the holders, for any model
        let creator = env.creator.insecure_clone();
        let ix = env.ix_claim(&t, &creator.pubkey());
        assert_eq!(
            env.send(ix, &[&creator]).unwrap_err(),
            custom(DeepError::ZeroAmount)
        );
        let ix = env.ix_sweep_holder(&t);
        assert_eq!(
            env.send(ix, &[&user]).unwrap_err(),
            custom(DeepError::ZeroAmount)
        );
        // all of the fee is DEEP revenue, and the sweep drains it exactly
        let v0 = vault_revenue(&env);
        let ix = env.ix_sweep(&t);
        env.send(ix, &[&user]).unwrap();
        assert_eq!(vault_revenue(&env) - v0, c2.protocol_fees_unclaimed);
        assert_eq!(env.curve_surplus(&t), 0);
        assert_eq!(env.lamports(&holder_vault(&t.mint)), 0);
    }
}

/// With the curve reward parameter switched on (and different buy / sell rates), every trade
/// matches the shared-fixture math, the reward goes to the creator (Creator) or the holders
/// (Holder), the curve holds exactly what it owes after each step, and each way out drains its
/// balance exactly.
#[test]
fn curve_reward_accrues_per_model_and_every_sweep_drains_exactly() {
    let mut env = Env::new();
    let p = v1_params(&env, 125, 150, 100, 80);
    env.update_config_now(p).unwrap();

    for model in MODELS {
        let reward_bps = [0u16, 100, 80][model as usize];
        let t = env.create_token_model(model);
        let f = env.curve(&t).fees_v1();
        assert_eq!(
            f,
            FeesV1 {
                buy_protocol_fee_bps: 125,
                sell_protocol_fee_bps: 150,
                reward_bps,
                reward_model: model
            }
        );
        let user = env.user(400 * SOL);
        let (mut protocol, mut creator, mut holder) = (0u64, 0u64, 0u64);
        let mut odd = 1_000_003u64;
        for i in 0..12 {
            let sol_in = SOL / 2 + odd;
            odd = (odd * 7_919 + 13) % 900_000_007;
            let before = to_math(&env.curve(&t));
            let (q, r) = math::quote_buy_v1(&before, sol_in, &f, 0).unwrap();
            let c0 = env.lamports(&t.curve);
            let m = env.buy(&t, &user, sol_in).unwrap();
            assert_eq!(env.lamports(&t.curve) - c0, q.sol_in, "{model} buy {i}");
            assert_eq!(to_math(&env.curve(&t)), q.next, "{model} buy {i}");
            assert_eq!(
                q.fees.total,
                (sol_in as u128 * (125 + reward_bps as u128)).div_ceil(10_000) as u64
            );
            let ev = &trade_events(&m)[0];
            assert_eq!(
                (
                    ev.protocol_fee,
                    ev.creator_fee,
                    ev.holder_fee,
                    ev.reward_model
                ),
                (r.protocol, r.creator, r.holder, model)
            );
            protocol += r.protocol;
            creator += r.creator;
            holder += r.holder;
            if i % 3 == 1 {
                let tokens = q.tokens_out / 2 + 1;
                let before = to_math(&env.curve(&t));
                let (s, r) = math::quote_sell_v1(&before, tokens, &f, 0).unwrap();
                assert_eq!(
                    s.fees.total,
                    (s.sol_from_curve as u128 * (150 + reward_bps as u128)).div_ceil(10_000) as u64,
                    "the sell rate, not the buy rate"
                );
                let u0 = env.lamports(&user.pubkey());
                let m = env.sell(&t, &user, tokens).unwrap();
                assert_eq!(env.lamports(&user.pubkey()) - u0, s.sol_out - 5_000);
                assert_eq!(to_math(&env.curve(&t)), s.next, "{model} sell {i}");
                let ev = &trade_events(&m)[0];
                assert!(!ev.is_buy);
                assert_eq!(
                    (ev.protocol_fee, ev.creator_fee, ev.holder_fee),
                    (r.protocol, r.creator, r.holder)
                );
                protocol += r.protocol;
                creator += r.creator;
                holder += r.holder;
            }
            let c = env.curve(&t);
            assert_eq!(
                (
                    c.protocol_fees_unclaimed,
                    c.creator_fees_unclaimed,
                    c.holder_fees_unclaimed
                ),
                (protocol, creator, holder),
                "{model} step {i}"
            );
            assert_eq!(
                env.curve_surplus(&t),
                0,
                "{model} step {i}: holds what it owes"
            );
        }
        match model {
            REWARD_MODEL_STANDARD => assert_eq!((creator, holder), (0, 0)),
            REWARD_MODEL_CREATOR => assert!(creator > 0 && holder == 0),
            _ => assert!(holder > 0 && creator == 0),
        }

        // ── ways out, each exact ──
        let anyone = env.user(SOL);
        let reserves = env.curve(&t).real_sol_reserves;
        // creator reward: claim_creator_fees (Creator only)
        let creator_kp = env.creator.insecure_clone();
        let c0 = env.lamports(&creator_kp.pubkey());
        let ix = env.ix_claim(&t, &creator_kp.pubkey());
        if creator > 0 {
            env.send(ix, &[&creator_kp]).unwrap();
            assert_eq!(env.lamports(&creator_kp.pubkey()) - c0, creator - 5_000);
        } else {
            assert_eq!(
                env.send(ix, &[&creator_kp]).unwrap_err(),
                custom(DeepError::ZeroAmount)
            );
        }
        // holder reward: sweep_holder_fees, permissionless, into the deep-rewards holder vault
        let vault = holder_vault(&t.mint);
        assert_eq!(env.lamports(&vault), 0);
        let ix = env.ix_sweep_holder(&t);
        if holder > 0 {
            assert!(holder >= env.rent0(), "enough accrued to open the vault");
            let m = env.send(ix, &[&anyone]).unwrap();
            println!("sweep_holder_fees: {} CU", m.compute_units_consumed);
            assert_eq!(
                env.lamports(&vault),
                holder,
                "every holder lamport, nothing else"
            );
            let acc = env.svm.get_account(&vault).unwrap();
            assert_eq!(acc.owner, anchor_lang::system_program::ID);
            assert!(acc.data.is_empty());
            let ix = env.ix_sweep_holder(&t);
            assert_eq!(
                env.send(ix, &[&anyone]).unwrap_err(),
                custom(DeepError::ZeroAmount),
                "nothing is swept twice"
            );
        } else {
            assert_eq!(
                env.send(ix, &[&anyone]).unwrap_err(),
                custom(DeepError::ZeroAmount)
            );
            assert_eq!(env.lamports(&vault), 0);
        }
        // protocol fee: sweep_protocol_fees into the DEEP fee vault
        let v0 = vault_revenue(&env);
        let ix = env.ix_sweep(&t);
        env.send(ix, &[&anyone]).unwrap();
        assert_eq!(vault_revenue(&env) - v0, protocol);

        let c = env.curve(&t);
        assert_eq!(
            (
                c.protocol_fees_unclaimed,
                c.creator_fees_unclaimed,
                c.holder_fees_unclaimed
            ),
            (0, 0, 0)
        );
        assert_eq!(
            c.real_sol_reserves, reserves,
            "sweeps never touch the reserves"
        );
        assert_eq!(env.curve_surplus(&t), 0);
        let rent = env
            .svm
            .minimum_balance_for_rent_exemption(8 + BondingCurve::INIT_SPACE);
        assert_eq!(env.lamports(&t.curve), rent + reserves);
        // and the curve still trades
        env.buy(&t, &user, SOL).unwrap();
        assert_eq!(env.curve_surplus(&t), 0);
    }
}

/// `sweep_holder_fees` pays the token's own deep-rewards holder vault and nothing else, never
/// leaves the vault below rent, and keeps working after graduation.
#[test]
fn sweep_holder_fees_rejects_wrong_destinations_and_never_strands_fees() {
    let mut env = Env::new();
    let p = v1_params(&env, 125, 125, 100, 100);
    env.update_config_now(p).unwrap();
    let t = env.create_token_model(REWARD_MODEL_HOLDER);
    let other = env.create_token_model(REWARD_MODEL_HOLDER);
    let creator_token = env.create_token_model(REWARD_MODEL_CREATOR);
    let user = env.user(3_000 * SOL);
    let anyone = env.user(SOL);
    let rent0 = env.rent0();

    // a small buy: the accrued holder fee (1% of 0.05 SOL = 500_000) is below the vault's
    // 0-byte rent minimum, so the sweep waits and the fee stays on the curve
    env.buy(&t, &user, SOL / 20).unwrap();
    let small = env.curve(&t).holder_fees_unclaimed;
    assert_eq!(small, 500_000);
    assert!(small < rent0);
    let ix = env.ix_sweep_holder(&t);
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::HolderVaultBelowRent)
    );
    assert_eq!(env.curve(&t).holder_fees_unclaimed, small, "not lost");
    assert_eq!(env.lamports(&holder_vault(&t.mint)), 0);
    assert_eq!(env.curve_surplus(&t), 0);

    // wrong destinations, with an amount that WOULD be payable
    env.buy(&t, &user, 2 * SOL).unwrap();
    let accrued = env.curve(&t).holder_fees_unclaimed;
    assert_eq!(accrued, small + 20_000_000);
    let creator = env.creator.pubkey();
    for wrong in [
        fee_vault_pda(),
        creator,
        anyone.pubkey(),
        holder_vault(&other.mint),
        // the same seeds under deep-curve instead of deep-rewards
        Pubkey::find_program_address(
            &[deep_curve::HOLDER_VAULT_SEED, t.mint.as_ref()],
            &deep_curve::ID,
        )
        .0,
    ] {
        let mut ix = env.ix_sweep_holder(&t);
        ix.accounts[1].pubkey = wrong;
        assert_eq!(
            env.send(ix, &[&anyone]).unwrap_err(),
            ANCHOR_CONSTRAINT_SEEDS,
            "{wrong}"
        );
    }
    // program-owned accounts are refused before the address is even compared
    for wrong in [treasury_pda(), config_pda(), other.curve] {
        let mut ix = env.ix_sweep_holder(&t);
        ix.accounts[1].pubkey = wrong;
        assert_eq!(
            env.send(ix, &[&anyone]).unwrap_err(),
            ANCHOR_NOT_SYSTEM_OWNED,
            "{wrong}"
        );
    }
    // another token's curve with this token's vault
    let mut ix = env.ix_sweep_holder(&other);
    ix.accounts[1].pubkey = holder_vault(&t.mint);
    assert!(env.send(ix, &[&anyone]).is_err());
    // a Creator token never has holder fees, even though its reward accrued
    env.buy(&creator_token, &user, SOL).unwrap();
    assert_eq!(env.curve(&creator_token).creator_fees_unclaimed, 10_000_000);
    let ix = env.ix_sweep_holder(&creator_token);
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::ZeroAmount)
    );
    // a holder vault that is not a plain system account is refused
    let squatted = solana_account::Account {
        lamports: env.svm.minimum_balance_for_rent_exemption(8),
        data: vec![0u8; 8],
        owner: deep_curve::DEEP_REWARDS_PROGRAM_ID,
        executable: false,
        rent_epoch: 0,
    };
    env.svm
        .set_account(holder_vault(&other.mint), squatted)
        .unwrap();
    env.buy(&other, &user, 2 * SOL).unwrap();
    let ix = env.ix_sweep_holder(&other);
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        ANCHOR_NOT_SYSTEM_OWNED
    );
    assert_eq!(env.curve(&other).holder_fees_unclaimed, 20_000_000);
    assert_eq!(env.curve_surplus(&other), 0);
    assert_eq!(
        env.curve(&t).holder_fees_unclaimed,
        accrued,
        "nothing moved so far"
    );

    // the right vault: exact
    let ix = env.ix_sweep_holder(&t);
    env.send(ix, &[&anyone]).unwrap();
    assert_eq!(env.lamports(&holder_vault(&t.mint)), accrued);
    assert_eq!(env.curve(&t).holder_fees_unclaimed, 0);
    assert_eq!(env.curve_surplus(&t), 0);

    // once the vault exists (deep-rewards init_distributor funds its reserve the same way),
    // any amount can be swept, even 1 lamport of reward
    env.buy(&t, &user, 100).unwrap();
    let dust = env.curve(&t).holder_fees_unclaimed;
    assert_eq!(dust, 1);
    let ix = env.ix_sweep_holder(&t);
    env.send(ix, &[&anyone]).unwrap();
    assert_eq!(env.lamports(&holder_vault(&t.mint)), accrued + 1);

    // a token whose vault was funded first (the reserve) sweeps a below-rent amount at once
    let t2 = env.create_token_model(REWARD_MODEL_HOLDER);
    env.svm.airdrop(&holder_vault(&t2.mint), rent0).unwrap();
    env.buy(&t2, &user, SOL / 20).unwrap();
    let ix = env.ix_sweep_holder(&t2);
    env.send(ix, &[&anyone]).unwrap();
    assert_eq!(env.lamports(&holder_vault(&t2.mint)), rent0 + 500_000);

    // holder fees accrued up to completion are swept to the holder vault by graduate itself
    // (Phase 3; the vault was passed writable and can hold them), to the lamport
    let whale = env.user(2_000 * SOL);
    env.buy(&t, &whale, 1_000 * SOL).unwrap();
    assert!(env.curve(&t).complete);
    let pending_holder = env.curve(&t).holder_fees_unclaimed;
    assert!(pending_holder > SOL);
    let migration = env.migration.insecure_clone();
    let v0 = env.lamports(&holder_vault(&t.mint));
    env.graduate(&t, &migration)
        .expect("graduate a Holder token");
    let c = env.curve(&t);
    assert!(c.graduated);
    assert_eq!(
        c.reward_model, REWARD_MODEL_HOLDER,
        "still readable after graduation"
    );
    assert_eq!(c.holder_fees_unclaimed, 0, "graduate swept them");
    assert_eq!(c.protocol_fees_unclaimed, 0);
    assert_eq!(env.curve_surplus(&t), 0);
    assert_eq!(env.lamports(&holder_vault(&t.mint)) - v0, pending_holder);
    let ix = env.ix_sweep_holder(&t);
    assert_eq!(
        env.send(ix, &[&anyone]).unwrap_err(),
        custom(DeepError::ZeroAmount)
    );
    let rent = env
        .svm
        .minimum_balance_for_rent_exemption(8 + BondingCurve::INIT_SPACE);
    assert_eq!(
        env.lamports(&t.curve),
        rent,
        "a graduated, swept curve holds only its rent"
    );
}

/// While the configured AmmConfig is still a LEGACY one (#0), graduation creates a legacy pool
/// for every reward model exactly as before V1 Phase 3 (the old instruction, the old fee
/// semantics). The pool's recorded creator is the token's reward recipient: the creator, or
/// the holder vault for a Holder token.
#[test]
fn graduate_into_a_legacy_config_is_unchanged_for_every_reward_model() {
    let mut env = Env::new();
    let p = v1_params(&env, 125, 125, 0, 0);
    env.update_config_now(p).unwrap();
    for model in MODELS {
        let t = env.create_token_model(model);
        env.complete_curve(&t);
        let before = env.curve(&t);
        let alloc =
            math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
        let migration = env.migration.insecure_clone();
        env.graduate(&t, &migration).expect("graduate");
        let c = env.curve(&t);
        assert!(c.graduated);
        assert_eq!(c.reward_model, model);
        assert_eq!(c.pool, pool_keys(&t.mint).pool_state);
        let raw = read_v1_pool(&env, &pool_keys(&t.mint).pool_state);
        assert_eq!(
            (raw.fee_model, raw.reward_model, raw.reward_rate),
            (0, 0, 0)
        );
        assert_eq!(raw.amm_config, amm_config_0());
        assert!(raw.enable_creator_fee);
        let recipient = if model == REWARD_MODEL_HOLDER {
            holder_vault(&t.mint)
        } else {
            env.creator.pubkey()
        };
        assert_eq!(raw.pool_creator, recipient);
        let pool = live_pool(&env, &pool_keys(&t.mint));
        let (wsol_vault, token_vault) = if NATIVE_MINT < t.mint {
            (pool.token_0_vault, pool.token_1_vault)
        } else {
            (pool.token_1_vault, pool.token_0_vault)
        };
        assert_eq!(env.load::<TokenAccount>(&wsol_vault).amount, alloc.lp_sol);
        assert_eq!(
            env.load::<TokenAccount>(&token_vault).amount,
            alloc.lp_tokens
        );
        assert_eq!(env.curve_surplus(&t), 0);
    }
}

/// The hard cap (10% per side, protocol + the largest reward rate) and the reward-model range.
#[test]
fn fee_cap_per_side_and_reward_model_range_are_enforced() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    // (buy, sell, legacy creator fee, creator reward, holder reward)
    for (buy, sell, cf, cr, hr) in [
        (1_001u16, 0u16, 0u16, 0u16, 0u16),
        (0, 1_001, 0, 0, 0),
        (125, 125, 1_001, 0, 0),
        (901, 0, 100, 0, 0),
        (0, 901, 100, 0, 0),
    ] {
        let mut p = v1_params(&env, buy, sell, cr, hr);
        p.creator_fee_bps = cf;
        let ix = env.ix_queue_config(&admin.pubkey(), p);
        assert_eq!(
            env.send(ix, &[&admin]).unwrap_err(),
            custom(DeepError::InvalidFee),
            "{buy}/{sell}/{cf}/{cr}/{hr}"
        );
    }
    // the current maximum reward rate can never be set above the 500 bps ceiling
    for max in [501u16, 1_000, u16::MAX] {
        let mut p = v1_params(&env, 125, 125, 0, 0);
        p.max_reward_bps = max;
        let ix = env.ix_queue_config(&admin.pubkey(), p);
        assert_eq!(
            env.send(ix, &[&admin]).unwrap_err(),
            custom(DeepError::InvalidRewardRate)
        );
    }
    let cfg: Config = env.load(&config_pda());
    assert_eq!(
        (cfg.protocol_fee_bps, cfg.sell_protocol_fee_bps),
        (70, 70),
        "unchanged"
    );
    // only the admin can queue a fee change
    let stranger = env.user(SOL);
    let p = v1_params(&env, 125, 125, 0, 0);
    let ix = env.ix_queue_config(&stranger.pubkey(), p);
    assert_eq!(
        env.send(ix, &[&stranger]).unwrap_err(),
        custom(DeepError::Unauthorized)
    );

    // exactly at the cap on both sides is allowed, and trades at 10%
    let p = v1_params(&env, 900, 0, 100, 100);
    env.update_config_now(p).unwrap();
    let t = env.create_token_model(REWARD_MODEL_HOLDER);
    let user = env.user(10 * SOL);
    env.buy(&t, &user, SOL).unwrap();
    let c = env.curve(&t);
    assert_eq!(c.protocol_fees_unclaimed, 90_000_000);
    assert_eq!(c.holder_fees_unclaimed, 10_000_000);
    let tokens = env.token_balance(&user.pubkey(), &t.mint);
    let (q, r) = math::quote_sell_v1(&to_math(&c), tokens, &c.fees_v1(), 0).unwrap();
    env.sell(&t, &user, tokens).unwrap();
    assert_eq!(
        r.protocol,
        q.fees.total - r.holder,
        "sell side: 0 bps protocol + 1% reward"
    );
    assert!(
        r.protocol <= 1,
        "only the rounding remainder goes to the protocol"
    );
    assert_eq!(env.curve_surplus(&t), 0);

    // reward model: 0, 1 and 2 only
    for bad in [3u8, 4, 255] {
        assert_eq!(
            env.try_create_token_model(bad).err().unwrap(),
            custom(DeepError::InvalidRewardModel)
        );
    }
}

/// The new fee fields change only through the Config timelock, and never for a live curve.
#[test]
fn new_fee_fields_are_timelocked_and_snapshotted_per_token() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let mut p = v1_params(&env, 125, 125, 0, 0);
    p.timelock_seconds = 600;
    env.update_config_now(p).unwrap();
    let old = env.create_token_model(REWARD_MODEL_HOLDER);

    env.set_unix_time(NOW);
    let mut p = v1_params(&env, 130, 140, 100, 90);
    p.timelock_seconds = 600;
    let ix = env.ix_queue_config(&admin.pubkey(), p);
    env.send(ix, &[&admin]).unwrap();
    let pc = pending(&env);
    assert!(pc.active);
    assert_eq!(pc.eta, NOW + 600);
    assert_eq!(
        (
            pc.params.sell_protocol_fee_bps,
            pc.params.max_reward_bps,
            pc.params.reserved_bps
        ),
        (140, 500, 0)
    );
    // before the eta nothing changes, for anyone
    let ix = env.ix_apply_config();
    assert_eq!(
        env.send(ix, &[&admin]).unwrap_err(),
        custom(DeepError::TimelockNotElapsed)
    );
    let during = env.create_token_reward(REWARD_MODEL_HOLDER, 100);
    assert_eq!(env.curve(&during).fees_v1().reward_bps, 100);
    assert_eq!(env.curve(&during).sell_protocol_fee_bps, 125);

    env.set_unix_time(NOW + 600);
    let anyone = env.user(SOL);
    let ix = env.ix_apply_config();
    env.send(ix, &[&anyone])
        .expect("permissionless after the eta");
    let cfg: Config = env.load(&config_pda());
    assert_eq!(
        (
            cfg.protocol_fee_bps,
            cfg.sell_protocol_fee_bps,
            cfg.max_reward_bps,
            cfg.reserved_bps
        ),
        (130, 140, 500, 0)
    );
    // new tokens snapshot the new protocol rates (the reward rate is each creator's choice)
    for (model, reward) in [
        (REWARD_MODEL_STANDARD, 0u16),
        (REWARD_MODEL_CREATOR, 100),
        (REWARD_MODEL_HOLDER, 90),
    ] {
        let t = env.create_token_model(model);
        assert_eq!(
            env.curve(&t).fees_v1(),
            FeesV1 {
                buy_protocol_fee_bps: 130,
                sell_protocol_fee_bps: 140,
                reward_bps: reward,
                reward_model: model
            }
        );
    }
    // live curves keep the terms they launched with, on both sides
    for t in [&old, &during] {
        assert_eq!(
            env.curve(t).fees_v1(),
            FeesV1 {
                buy_protocol_fee_bps: 125,
                sell_protocol_fee_bps: 125,
                reward_bps: 100,
                reward_model: REWARD_MODEL_HOLDER
            }
        );
    }
    let user = env.user(10 * SOL);
    env.buy(&old, &user, SOL).unwrap();
    assert_eq!(env.curve(&old).protocol_fees_unclaimed, 12_500_000);
    assert_eq!(env.curve(&old).holder_fees_unclaimed, 10_000_000);
}

// ───────────── v2 → v3 migration (devnet has live v2 state) ─────────────

/// Rewrites a v3 account as the v2 program left it: the v3 tail removed (for PendingConfig the
/// bump moved back to the end), and the balance reduced by exactly the rent difference.
fn downgrade_to_v2(env: &mut Env, key: &Pubkey, v2_len: usize, bump_last: bool) {
    let mut a = env.svm.get_account(key).unwrap();
    let v3_len = a.data.len();
    let bump = a.data[v3_len - 1];
    a.data.truncate(v2_len);
    if bump_last {
        a.data[v2_len - 1] = bump;
    }
    a.lamports -= env.svm.minimum_balance_for_rent_exemption(v3_len)
        - env.svm.minimum_balance_for_rent_exemption(v2_len);
    env.svm.set_account(*key, a).unwrap();
}

#[test]
fn migrate_v2_config_pending_and_curves_to_v3_keeps_terms_and_solvency() {
    let mut env = Env::new(); // 70 / 30, the live devnet schedule
    let admin = env.admin.insecure_clone();
    let user = env.user(200 * SOL);

    // curve A: 70/30 with trades, unclaimed creator and protocol fees
    let (a, _) = env.create_token();
    env.buy(&a, &user, 5 * SOL).unwrap();
    let half = env.token_balance(&user.pubkey(), &a.mint) / 2;
    env.sell(&a, &user, half).unwrap();
    // curve B: launched with no creator fee
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.creator_fee_bps = 0;
    env.update_config_now(p).unwrap();
    let (b, _) = env.create_token();
    env.buy(&b, &user, 3 * SOL).unwrap();
    // curve C: 70/30 again, completed and graduated before the upgrade
    let p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    env.update_config_now(p).unwrap();
    let (g, _) = env.create_token();
    env.complete_curve(&g);
    let migration = env.migration.insecure_clone();
    env.graduate(&g, &migration).unwrap();
    // a queued change (protocol 80, launch fee $2) so a PendingConfig exists
    let mut p = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    p.protocol_fee_bps = 80;
    p.sell_protocol_fee_bps = 80;
    p.launch_fee_usd_cents = 200;
    let ix = env.ix_queue_config(&admin.pubkey(), p);
    env.send(ix, &[&admin]).unwrap();
    let pc_bump = pending(&env).bump;

    // what each curve owes above rent, before the downgrade
    let owed = |env: &Env, t: &Token| {
        let c = env.curve(t);
        (
            c.real_sol_reserves,
            c.creator_fees_unclaimed,
            c.protocol_fees_unclaimed,
        )
    };
    let (owed_a, owed_b, owed_g) = (owed(&env, &a), owed(&env, &b), owed(&env, &g));
    assert!(owed_a.1 > 0 && owed_a.2 > 0 && owed_b.1 == 0 && owed_b.2 > 0);
    let math_a = to_math(&env.curve(&a));

    // ── make every account look v2 ──
    use deep_curve::{
        BONDING_CURVE_V2_SIZE, BONDING_CURVE_V3_SIZE, CONFIG_V2_SIZE, CONFIG_V3_SIZE,
        PENDING_CONFIG_V2_SIZE, PENDING_CONFIG_V3_SIZE,
    };
    let rent = |env: &Env, n: usize| env.svm.minimum_balance_for_rent_exemption(n);
    let (rent2, rent3) = (
        rent(&env, BONDING_CURVE_V2_SIZE),
        rent(&env, BONDING_CURVE_V3_SIZE),
    );
    downgrade_to_v2(&mut env, &config_pda(), CONFIG_V2_SIZE, false);
    downgrade_to_v2(
        &mut env,
        &pending_config_pda(),
        PENDING_CONFIG_V2_SIZE,
        true,
    );
    for (t, o) in [(&a, owed_a), (&b, owed_b), (&g, owed_g)] {
        downgrade_to_v2(&mut env, &t.curve, BONDING_CURVE_V2_SIZE, false);
        assert_eq!(
            env.lamports(&t.curve),
            rent2 + o.0 + o.1 + o.2,
            "a solvent v2 curve"
        );
        assert_eq!(env.svm.get_account(&t.curve).unwrap().data.len(), 185);
    }
    assert_eq!(env.svm.get_account(&config_pda()).unwrap().data.len(), 215);
    assert_eq!(
        env.svm
            .get_account(&pending_config_pda())
            .unwrap()
            .data
            .len(),
        167
    );

    // v2 accounts do not deserialize under the v3 program: everything fails closed (no trade
    // at a wrong fee, no payout from a half-read account) until migrated
    let creator = env.creator.insecure_clone();
    assert!(env.buy(&a, &user, SOL).is_err());
    assert!(env.sell(&a, &user, UNIT).is_err());
    let ix = env.ix_sweep(&a);
    assert!(env.send(ix, &[&user]).is_err());
    let ix = env.ix_claim(&a, &creator.pubkey());
    assert!(env.send(ix, &[&creator]).is_err());
    assert!(env.try_create_token_model(REWARD_MODEL_STANDARD).is_err());
    let ix = env.ix_apply_config();
    assert!(env.send(ix, &[&user]).is_err());

    // ── migrate: permissionless, any payer ──
    let payer = env.user(SOL);
    let mig_cfg = Instruction {
        program_id: deep_curve::ID,
        accounts: deep_curve::accounts::MigrateConfig {
            payer: payer.pubkey(),
            config: config_pda(),
            pending_config: pending_config_pda(),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_curve::instruction::MigrateConfig {}.data(),
    };
    let mig_curve = |t: &Token| Instruction {
        program_id: deep_curve::ID,
        accounts: deep_curve::accounts::MigrateCurve {
            payer: payer.pubkey(),
            mint: t.mint,
            curve: t.curve,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_curve::instruction::MigrateCurve {}.data(),
    };
    let all = vec![mig_cfg.clone(), mig_curve(&a), mig_curve(&b), mig_curve(&g)];
    let p0 = env.lamports(&payer.pubkey());
    let m = env
        .send_ixs(all.clone(), &[&payer])
        .expect("migrate v2 -> v3");
    println!(
        "migrate_config + 3 x migrate_curve (v2 -> v3): {} CU",
        m.compute_units_consumed
    );
    assert_eq!(env.svm.get_account(&config_pda()).unwrap().data.len(), 221);
    assert_eq!(
        env.svm
            .get_account(&pending_config_pda())
            .unwrap()
            .data
            .len(),
        173
    );
    // the payer funds exactly the rent difference of every grown account, nothing else moves
    let rent_delta = (rent(&env, CONFIG_V3_SIZE) - rent(&env, CONFIG_V2_SIZE))
        + (rent(&env, PENDING_CONFIG_V3_SIZE) - rent(&env, PENDING_CONFIG_V2_SIZE))
        + 3 * (rent3 - rent2);
    assert_eq!(p0 - env.lamports(&payer.pubkey()), rent_delta + 5_000);

    // Config: every old value kept; sells keep the rate they had; no reward fee switched on
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.admin, admin.pubkey());
    assert_eq!(cfg.migration_authority, env.migration.pubkey());
    assert_eq!(
        (
            cfg.protocol_fee_bps,
            cfg.creator_fee_bps,
            cfg.migration_fee_bps
        ),
        (70, 30, 100)
    );
    assert_eq!(
        cfg.sell_protocol_fee_bps, 70,
        "sell rate = the rate sells paid before"
    );
    assert_eq!((cfg.max_reward_bps, cfg.reserved_bps), (500, 0));
    assert_eq!(cfg.launch_fee_usd_cents, 0);
    assert_eq!(cfg.raydium_amm_config, amm_config_0());
    // PendingConfig: the queued change survives, with the same sell-rate rule and its bump
    let pc = pending(&env);
    assert!(pc.active);
    assert_eq!(pc.bump, pc_bump);
    assert_eq!(
        (pc.params.protocol_fee_bps, pc.params.sell_protocol_fee_bps),
        (80, 80)
    );
    assert_eq!(pc.params.launch_fee_usd_cents, 200);
    assert_eq!((pc.params.max_reward_bps, pc.params.reserved_bps), (500, 0));
    assert_eq!(pc.params.timelock_seconds, 0);

    // curves: same reserves and unclaimed fees, the model that matches their fee, solvent
    for (t, o, model) in [
        (&a, owed_a, REWARD_MODEL_CREATOR),
        (&b, owed_b, REWARD_MODEL_STANDARD),
        (&g, owed_g, REWARD_MODEL_CREATOR),
    ] {
        assert_eq!(env.svm.get_account(&t.curve).unwrap().data.len(), 196);
        let c = env.curve(t);
        assert_eq!(c.reward_model, model);
        assert_eq!((c.protocol_fee_bps, c.sell_protocol_fee_bps), (70, 70));
        assert_eq!(c.holder_fees_unclaimed, 0);
        assert_eq!(
            (
                c.real_sol_reserves,
                c.creator_fees_unclaimed,
                c.protocol_fees_unclaimed
            ),
            o
        );
        assert_eq!(env.lamports(&t.curve), rent3 + o.0 + o.1 + o.2);
        assert_eq!(
            env.curve_surplus(t),
            0,
            "solvent to the lamport after migration"
        );
    }
    assert_eq!(to_math(&env.curve(&a)), math_a);
    assert!(env.curve(&g).graduated && env.curve(&g).pool != Pubkey::default());
    assert_eq!(env.curve(&b).creator_fee_bps, 0);

    // idempotent: a second run changes nothing and costs only the transaction fee
    let p1 = env.lamports(&payer.pubkey());
    let before: Vec<Vec<u8>> = [
        config_pda(),
        pending_config_pda(),
        a.curve,
        b.curve,
        g.curve,
    ]
    .iter()
    .map(|k| env.svm.get_account(k).unwrap().data)
    .collect();
    env.send_ixs(all, &[&payer])
        .expect("second migrate is a no-op");
    assert_eq!(p1 - env.lamports(&payer.pubkey()), 5_000);
    let after: Vec<Vec<u8>> = [
        config_pda(),
        pending_config_pda(),
        a.curve,
        b.curve,
        g.curve,
    ]
    .iter()
    .map(|k| env.svm.get_account(k).unwrap().data)
    .collect();
    assert_eq!(before, after);

    // a migrated curve trades exactly as before the upgrade: 70/30 on both sides, the creator
    // fee to the creator
    let c = env.curve(&a);
    let q = math::quote_buy(&to_math(&c), 2 * SOL, &fees(), 0).unwrap();
    let (q1, r1) = math::quote_buy_v1(&to_math(&c), 2 * SOL, &c.fees_v1(), 0).unwrap();
    assert_eq!(q1, q);
    assert_eq!((r1.creator, r1.holder), (q.fees.creator, 0));
    env.buy(&a, &user, 2 * SOL).unwrap();
    let c = env.curve(&a);
    assert_eq!(to_math(&c), q.next);
    let tokens = q.tokens_out / 3;
    let s = math::quote_sell(&to_math(&c), tokens, &fees(), 0).unwrap();
    let u0 = env.lamports(&user.pubkey());
    env.sell(&a, &user, tokens).unwrap();
    assert_eq!(env.lamports(&user.pubkey()) - u0, s.sol_out - 5_000);
    let c = env.curve(&a);
    assert_eq!(
        c.creator_fees_unclaimed,
        owed_a.1 + q.fees.creator + s.fees.creator
    );
    assert_eq!(
        c.protocol_fees_unclaimed,
        owed_a.2 + q.fees.protocol + s.fees.protocol
    );
    assert_eq!(c.holder_fees_unclaimed, 0);
    assert_eq!(env.curve_surplus(&a), 0);

    // every balance held under the old layout still has its way out, exactly
    for (t, creator_fees) in [(&a, c.creator_fees_unclaimed), (&g, owed_g.1)] {
        assert!(creator_fees > 0);
        let c0 = env.lamports(&creator.pubkey());
        let ix = env.ix_claim(t, &creator.pubkey());
        env.send(ix, &[&creator]).unwrap();
        assert_eq!(env.lamports(&creator.pubkey()) - c0, creator_fees - 5_000);
    }
    let v0 = vault_revenue(&env);
    for t in [&a, &b] {
        let ix = env.ix_sweep(t);
        env.send(ix, &[&user]).unwrap();
    }
    assert_eq!(
        vault_revenue(&env) - v0,
        c.protocol_fees_unclaimed + owed_b.2
    );
    for t in [&a, &b, &g] {
        let c = env.curve(t);
        assert_eq!(env.lamports(&t.curve), rent3 + c.real_sol_reserves);
        assert_eq!(env.curve_surplus(t), 0);
    }
    assert_eq!(env.lamports(&g.curve), rent3);

    // the migrated queued change applies as queued
    let ix = env.ix_apply_config();
    env.send(ix, &[&user]).unwrap();
    let cfg: Config = env.load(&config_pda());
    assert_eq!(
        (
            cfg.protocol_fee_bps,
            cfg.sell_protocol_fee_bps,
            cfg.launch_fee_usd_cents
        ),
        (80, 80, 200)
    );

    // an account of an unknown size is refused, never patched
    let mut acc = env.svm.get_account(&b.curve).unwrap();
    acc.data.truncate(190);
    env.svm.set_account(b.curve, acc).unwrap();
    let ix = mig_curve(&b);
    assert_eq!(
        env.send(ix, &[&payer]).unwrap_err(),
        custom(DeepError::InvalidParams)
    );
    let mut acc = env.svm.get_account(&config_pda()).unwrap();
    acc.data.truncate(217);
    env.svm.set_account(config_pda(), acc).unwrap();
    assert_eq!(
        env.send(mig_cfg, &[&payer]).unwrap_err(),
        custom(DeepError::InvalidParams)
    );
}

// ───────────── DEEP V1 Phase 3: DeepSwap side-dependent fees and reward routing ─────────────

/// The owner's V1 schedule (per 1e6): buy LP / buy DEEP / sell LP / sell DEEP. A pool's
/// reward rate is the token's own (the creator's choice at launch), not a config value.
const V1_RATES: [u64; 4] = [1_000, 2_500, 1_000, 6_500];

const V1_ERR_INVALID_INPUT: u32 = 6003;
const V1_ERR_FEE_MODEL_MISMATCH: u32 = 6020;
const V1_ERR_INVALID_REWARD_MODEL: u32 = 6021;
const V1_ERR_INVALID_QUOTE_SIDE: u32 = 6022;
const V1_ERR_INVALID_REWARD_RATE: u32 = 6023;
const ANCHOR_CONSTRAINT_ADDRESS: u32 = 2012;
const ANCHOR_ACCOUNT_NOT_INITIALIZED: u32 = 3012;

/// AmmConfig update params added by V1 (10..=13); there is no param 9.
const V1_PARAM_BUY_LP: u8 = 10;
const V1_PARAM_BUY_PROTOCOL: u8 = 11;
const V1_PARAM_SELL_PROTOCOL: u8 = 13;

fn amm_config_n(index: u16) -> Pubkey {
    Pubkey::find_program_address(&[b"amm_config", &index.to_be_bytes()], &deep_amm::ID).0
}

fn amm_config_1() -> Pubkey {
    amm_config_n(1)
}

fn create_v1_config_ix(owner: &Pubkey, index: u16, r: [u64; 4]) -> Instruction {
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreateAmmConfig {
            owner: *owner,
            amm_config: amm_config_n(index),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreateAmmConfigV1 {
            index,
            create_pool_fee: AMM_CREATE_POOL_FEE,
            buy_lp_fee_rate: r[0],
            buy_protocol_fee_rate: r[1],
            sell_lp_fee_rate: r[2],
            sell_protocol_fee_rate: r[3],
        }
        .data(),
    }
}

/// Env::new plus the V1 rollout: AmmConfig #1 is created as a V1 config and deep-curve's
/// Config is pointed at it (and at the V1 curve schedule 125 / 125, no legacy creator fee),
/// through the config timelock (0 in tests). #0 stays as it is, a legacy config.
fn env_v1_with(rates: [u64; 4]) -> Env {
    let mut env = Env::new();
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    env.send(
        create_v1_config_ix(&amm_admin.pubkey(), 1, rates),
        &[&amm_admin],
    )
    .expect("create the V1 AmmConfig");
    let mut p = v1_params(&env, 125, 125, 0, 0);
    p.raydium_amm_config = amm_config_1();
    env.update_config_now(p).expect("point deep-curve at #1");
    env
}

fn env_v1() -> Env {
    env_v1_with(V1_RATES)
}

/// Replaces AmmConfig #0 by `cfg` in an instruction built by the pre-V1 helpers.
fn with_amm_config(mut ix: Instruction, cfg: Pubkey) -> Instruction {
    for m in ix.accounts.iter_mut() {
        if m.pubkey == amm_config_0() {
            m.pubkey = cfg;
        }
    }
    ix
}

fn set_v1_param(env: &mut Env, param: u8, value: u64) -> Result<TransactionMetadata, u32> {
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    env.send(
        with_amm_config(update_amm_ix(param, value, None), amm_config_1()),
        &[&amm_admin],
    )
}

fn amm_cfg(env: &Env, key: &Pubkey) -> deep_amm::states::AmmConfig {
    env.load(key)
}

/// The V1 fields of a PoolState, read from the raw account at the published offsets.
struct V1PoolRaw {
    amm_config: Pubkey,
    pool_creator: Pubkey,
    creator_fee_on: u8,
    enable_creator_fee: bool,
    fee_model: u8,
    reward_model: u8,
    reward_rate: u64,
}

fn read_v1_pool(env: &Env, pool_state: &Pubkey) -> V1PoolRaw {
    let d = env.svm.get_account(pool_state).unwrap().data;
    assert_eq!(d.len(), deep_amm::states::PoolState::LEN);
    let pk = |o: usize| Pubkey::new_from_array(d[o..o + 32].try_into().unwrap());
    V1PoolRaw {
        amm_config: pk(8),
        pool_creator: pk(40),
        creator_fee_on: d[389],
        enable_creator_fee: d[390] == 1,
        fee_model: d[deep_amm::states::POOL_STATE_FEE_MODEL_OFFSET],
        reward_model: d[deep_amm::states::POOL_STATE_REWARD_MODEL_OFFSET],
        reward_rate: u64::from_le_bytes(
            d[deep_amm::states::POOL_STATE_REWARD_RATE_SNAPSHOT_OFFSET..][..8]
                .try_into()
                .unwrap(),
        ),
    }
}

fn patch_pool_byte(env: &mut Env, pool_state: &Pubkey, offset: usize, value: u8) {
    let mut acc = env.svm.get_account(pool_state).unwrap();
    acc.data[offset] = value;
    env.svm.set_account(*pool_state, acc).unwrap();
}

fn events_of<T: anchor_lang::AnchorDeserialize + anchor_lang::Discriminator>(
    meta: &TransactionMetadata,
) -> Vec<T> {
    use base64::Engine;
    meta.logs
        .iter()
        .filter_map(|l| l.strip_prefix("Program data: "))
        .filter_map(|b| base64::engine::general_purpose::STANDARD.decode(b).ok())
        .filter(|d| d.len() > 8 && d[..8] == *T::DISCRIMINATOR)
        .map(|d| T::try_from_slice(&d[8..]).expect("event payload"))
        .collect()
}

/// What one V1 swap must do, from an INDEPENDENT re-implementation of the V1 rules (no
/// deep-amm code): the fee is one total at `lp + deep + reward` (per 1e6), rounded up, taken
/// in SOL: off the input of a buy, off the output of a sell; the LP and reward parts are
/// floored, DEEP keeps the remainder.
#[derive(Debug, Clone, Copy, PartialEq)]
struct V1Expect {
    amount_in: u64,
    amount_out: u64,
    lp: u64,
    deep: u64,
    reward: u64,
}

fn v1_expect(
    base_output: bool,
    is_buy: bool,
    amount: u64,
    ri: u64,
    ro: u64,
    (l, d, r): (u64, u64, u64),
) -> V1Expect {
    let den = 1_000_000u128;
    let t = (l + d + r) as u128;
    let (a, ri, ro) = (amount as u128, ri as u128, ro as u128);
    let ceil = |n: u128, m: u128| n.div_ceil(m);
    let (amount_in, amount_out, total) = match (base_output, is_buy) {
        // exact SOL in: fee off the input, the rest is priced
        (false, true) => {
            let total = ceil(a * t, den);
            let net = a - total;
            (a, net * ro / (ri + net), total)
        }
        // exact tokens in: fee off the SOL the curve pays
        (false, false) => {
            let gross = a * ro / (ri + a);
            let total = ceil(gross * t, den);
            (a, gross - total, total)
        }
        // exact tokens out: the curve's SOL input, grossed up by the fee
        (true, true) => {
            let swapped = ceil(ri * a, ro - a);
            let gross_in = ceil(swapped * den, den - t);
            (gross_in, a, gross_in - swapped)
        }
        // exact SOL out: the curve must pay that plus the fee
        (true, false) => {
            let gross = ceil(a * den, den - t);
            (ceil(ri * gross, ro - gross), a, gross - a)
        }
    };
    // no rate, no fee, no parts
    let lp = (total * l as u128).checked_div(t).unwrap_or(0);
    let reward = (total * r as u128).checked_div(t).unwrap_or(0);
    V1Expect {
        amount_in: amount_in as u64,
        amount_out: amount_out as u64,
        lp: lp as u64,
        deep: (total - lp - reward) as u64,
        reward: reward as u64,
    }
}

/// The rates the pool at `k` must charge on this side, from the raw accounts: the config's
/// LP and DEEP rates of the side, and the pool's OWN reward rate (the token's).
fn v1_live_rates(env: &Env, k: &PoolKeys, is_buy: bool) -> (u64, u64, u64) {
    let raw = read_v1_pool(env, &k.pool_state);
    assert_eq!(raw.fee_model, 1);
    let cfg = amm_cfg(env, &raw.amm_config);
    let (l, d) = if is_buy {
        (cfg.buy_lp_fee_rate, cfg.buy_protocol_fee_rate)
    } else {
        (cfg.sell_lp_fee_rate, cfg.sell_protocol_fee_rate)
    };
    let r = if raw.reward_model == REWARD_MODEL_STANDARD {
        0
    } else {
        raw.reward_rate
    };
    (l, d, r)
}

/// Executes one swap on a V1 pool with EXACT slippage bounds and checks, against
/// `v1_expect`: the trader's balances, the pool's fee accumulators (DEEP and reward on the
/// SOL side only, nothing on the token side, no fund fee), the reserves, `k`, and both
/// events. Returns the expectation and the compute units.
fn checked_v1_swap(
    env: &mut Env,
    trader: &Keypair,
    t: &Token,
    k: &PoolKeys,
    base_output: bool,
    is_buy: bool,
    amount: u64,
) -> (V1Expect, u64) {
    let tp = trader.pubkey();
    let input_mint = if is_buy { NATIVE_MINT } else { t.mint };
    let (pool, ri, ro) = live_reserves(env, k, input_mint);
    let raw = read_v1_pool(env, &k.pool_state);
    let rates = v1_live_rates(env, k, is_buy);
    let e = v1_expect(base_output, is_buy, amount, ri, ro, rates);
    let fees_before = pool_fee_parts(env, &k.pool_state);
    let sol_before = env.token_balance(&tp, &NATIVE_MINT);
    let tok_before = env.token_balance(&tp, &t.mint);

    let ix = if base_output {
        amm_swap_ix(true, &tp, k, &pool, input_mint, e.amount_in, amount)
    } else {
        amm_swap_ix(false, &tp, k, &pool, input_mint, amount, e.amount_out)
    };
    let meta = env
        .send(with_amm_config(ix, raw.amm_config), &[trader])
        .expect("V1 swap at the exact quote");

    let sol_after = env.token_balance(&tp, &NATIVE_MINT);
    let tok_after = env.token_balance(&tp, &t.mint);
    if is_buy {
        assert_eq!(sol_before - sol_after, e.amount_in, "SOL paid");
        assert_eq!(tok_after - tok_before, e.amount_out, "tokens received");
    } else {
        assert_eq!(tok_before - tok_after, e.amount_in, "tokens paid");
        assert_eq!(sol_after - sol_before, e.amount_out, "SOL received");
    }

    // [protocol_0, protocol_1, fund_0, fund_1, creator_0, creator_1]
    let fees_after = pool_fee_parts(env, &k.pool_state);
    let (sol_p, sol_c, tok_p, tok_c) = if pool.token_0_mint == NATIVE_MINT {
        (0, 4, 1, 5)
    } else {
        (1, 5, 0, 4)
    };
    assert_eq!(fees_after[sol_p] - fees_before[sol_p], e.deep, "DEEP part");
    assert_eq!(
        fees_after[sol_c] - fees_before[sol_c],
        e.reward,
        "reward part"
    );
    assert_eq!(
        (fees_after[tok_p], fees_after[tok_c]),
        (0, 0),
        "no fee in the token"
    );
    assert_eq!((fees_after[2], fees_after[3]), (0, 0), "no fund fee");

    // reserves: the LP part stays in, the DEEP and reward parts leave the SOL side
    let (_, ri2, ro2) = live_reserves(env, k, input_mint);
    if is_buy {
        assert_eq!(ri2, ri + e.amount_in - e.deep - e.reward);
        assert_eq!(ro2, ro - e.amount_out);
    } else {
        assert_eq!(ri2, ri + e.amount_in);
        assert_eq!(ro2, ro - e.amount_out - e.deep - e.reward);
    }
    assert!(ri2 as u128 * ro2 as u128 >= ri as u128 * ro as u128, "k");

    let swaps: Vec<deep_amm::states::SwapEvent> = events_of(&meta);
    assert_eq!(swaps.len(), 1);
    let s = &swaps[0];
    assert_eq!(s.pool_id, k.pool_state);
    assert_eq!(
        (s.input_amount, s.output_amount),
        (e.amount_in, e.amount_out)
    );
    assert_eq!((s.input_vault_before, s.output_vault_before), (ri, ro));
    assert_eq!(s.base_input, !base_output);
    assert_eq!(s.trade_fee, e.lp + e.deep);
    assert_eq!(s.creator_fee, e.reward);
    assert_eq!(s.creator_fee_on_input, is_buy);
    let fees: Vec<deep_amm::states::SwapFeesV1> = events_of(&meta);
    assert_eq!(fees.len(), 1);
    let f = &fees[0];
    assert_eq!(f.pool_id, k.pool_state);
    assert_eq!(f.is_buy, is_buy);
    assert_eq!(f.quote_mint, NATIVE_MINT);
    assert_eq!(
        (f.lp_fee, f.protocol_fee, f.reward_fee),
        (e.lp, e.deep, e.reward)
    );
    assert_eq!(f.reward_model, raw.reward_model);
    (e, meta.compute_units_consumed)
}

/// `collect_creator_fee_permissionless` for a pool of `cfg`: pays the pool's reward fees to
/// its recorded recipient's token accounts.
fn v1_collect_reward_ix(
    payer: &Pubkey,
    recipient: &Pubkey,
    k: &PoolKeys,
    pool: &CpmmPool,
    cfg: Pubkey,
) -> Instruction {
    let mut ix = with_amm_config(
        collect_creator_fee_permissionless_ix(payer, recipient, k, pool),
        cfg,
    );
    // the (never read for a V1 pool) CreatorFeeShare PDA is derived from the config
    let share = Pubkey::find_program_address(
        &[b"creator_fee_share", recipient.as_ref(), cfg.as_ref()],
        &deep_amm::ID,
    )
    .0;
    ix.accounts.last_mut().unwrap().pubkey = share;
    ix
}

/// Completes and graduates a token of `model` into a V1 pool and warps past its open time.
fn v1_graduated(env: &mut Env, model: u8) -> (Token, PoolKeys, TransactionMetadata) {
    env.set_unix_time(1_800_000_000);
    let t = env.create_token_model(model);
    env.complete_curve(&t);
    let migration = env.migration.insecure_clone();
    let meta = env
        .graduate(&t, &migration)
        .expect("graduate into a V1 pool");
    env.set_unix_time(1_800_000_001);
    let k = pool_keys(&t.mint);
    (t, k, meta)
}

/// End to end for each reward model: launch, trade on the curve, graduate into a V1 pool
/// (model, quote side, reward recipient and reward-rate snapshot recorded), swaps in all four
/// direction/mode combinations at the exact independent quote, DEEP's part collected to the
/// fee vault exactly, the reward part collected to its recipient exactly and in full, the
/// vaults reconciled to the lamport, and the builder paid exactly 10% of what reached the
/// vault.
#[test]
fn v1_pools_charge_side_dependent_fees_for_every_model_and_every_balance_drains_exactly() {
    let mut rows: Vec<(String, u64)> = Vec::new();
    for model in MODELS {
        let mut env = env_v1();
        env.set_unix_time(1_800_000_000);
        let t = env.create_token_model(model);
        env.complete_curve(&t);
        let before = env.curve(&t);
        let alloc =
            math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
        let migration = env.migration.insecure_clone();
        let grad = env
            .graduate(&t, &migration)
            .expect("graduate into a V1 pool");
        env.set_unix_time(1_800_000_001);
        let k = pool_keys(&t.mint);
        rows.push((
            format!("graduate (V1, model {model})"),
            grad.compute_units_consumed,
        ));

        let creator = env.creator.pubkey();
        let recipient = if model == REWARD_MODEL_HOLDER {
            holder_vault(&t.mint)
        } else {
            creator
        };
        let raw = read_v1_pool(&env, &k.pool_state);
        assert_eq!(raw.amm_config, amm_config_1());
        assert_eq!((raw.fee_model, raw.reward_model), (1, model));
        assert_eq!(raw.pool_creator, recipient);
        let standard = model == REWARD_MODEL_STANDARD;
        assert_eq!(raw.reward_rate, if standard { 0 } else { 10_000 });
        assert_eq!(raw.enable_creator_fee, !standard);
        // the quote side is WSOL
        assert_eq!(raw.creator_fee_on, if NATIVE_MINT < t.mint { 1 } else { 2 });
        assert_eq!(env.curve(&t).reward_model, model);
        assert_eq!(env.curve_surplus(&t), 0);

        // The trader pays 0.35% / 0.75% (Standard) or 1.35% / 1.75% (Creator, Holder).
        assert_eq!(
            v1_live_rates(&env, &k, true),
            (1_000, 2_500, if standard { 0 } else { 10_000 })
        );
        assert_eq!(
            v1_live_rates(&env, &k, false),
            (1_000, 6_500, if standard { 0 } else { 10_000 })
        );

        let trader = deepswap_trader(&mut env, &t.mint, 60 * SOL);
        let (mut deep_total, mut reward_total, mut lp_total) = (0u64, 0u64, 0u64);
        let (mut sol_in, mut sol_out) = (0u64, 0u64);
        for (base_output, is_buy, amount) in [
            (false, true, 5 * SOL),           // exact SOL in
            (true, true, 1_000_000 * UNIT),   // exact tokens out
            (false, false, 3_000_000 * UNIT), // exact tokens in
            (true, false, SOL / 2),           // exact SOL out
            (false, true, 1_234_567_891),     // odd sizes, every rounding path again
            (true, true, 7_777_777),
            (false, false, 987_654_321),
            (true, false, 123_456_789),
        ] {
            let (e, cu) = checked_v1_swap(&mut env, &trader, &t, &k, base_output, is_buy, amount);
            deep_total += e.deep;
            reward_total += e.reward;
            lp_total += e.lp;
            if is_buy {
                sol_in += e.amount_in;
            } else {
                sol_out += e.amount_out;
            }
            if amount == 5 * SOL
                || amount == 1_000_000 * UNIT
                || amount == 3_000_000 * UNIT
                || amount == SOL / 2
            {
                rows.push((
                    format!(
                        "swap V1 model {model} {} {}",
                        if is_buy { "buy" } else { "sell" },
                        if base_output { "exact-out" } else { "exact-in" }
                    ),
                    cu,
                ));
            }
        }
        assert!(deep_total > 0 && lp_total > 0);
        assert_eq!(reward_total > 0, !standard);

        let pool = live_pool(&env, &k);
        let wsol_is_0 = pool.token_0_mint == NATIVE_MINT;
        let (sol_p, sol_c) = if wsol_is_0 { (0, 4) } else { (1, 5) };
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!(fees[sol_p], deep_total);
        assert_eq!(fees[sol_c], reward_total);
        assert_eq!(fees.iter().sum::<u64>(), deep_total + reward_total);

        // DEEP's part: anyone moves it to the fee vault's WSOL account, exactly.
        let cranker = env.user(SOL);
        let vault_wsol_before = env.load::<TokenAccount>(&fee_vault_wsol()).amount;
        let r0 = get_associated_token_address(&fee_vault_pda(), &pool.token_0_mint);
        let r1 = get_associated_token_address(&fee_vault_pda(), &pool.token_1_mint);
        let collect = with_amm_config(collect_to_vault_ix(&k, &pool, r0, r1), amm_config_1());
        env.send(collect.clone(), &[&cranker])
            .expect("collect_protocol_fee_to_vault");
        assert_eq!(
            env.load::<TokenAccount>(&fee_vault_wsol()).amount - vault_wsol_before,
            deep_total
        );
        let fees = pool_fee_parts(&env, &k.pool_state);
        assert_eq!((fees[0], fees[1]), (0, 0));
        assert_eq!(
            env.send(collect, &[&cranker]).unwrap_err(),
            CPMM_ERR_NO_FEE_COLLECT
        );

        // The reward part: only to the pool's recorded recipient, in full.
        if model == REWARD_MODEL_CREATOR {
            // A CreatorFeeShare override of 100% for this creator and config is ignored by
            // a V1 pool, and the config-level share cannot even be set on a V1 config.
            let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
            let share = Pubkey::find_program_address(
                &[
                    b"creator_fee_share",
                    creator.as_ref(),
                    amm_config_1().as_ref(),
                ],
                &deep_amm::ID,
            )
            .0;
            let ix = Instruction {
                program_id: deep_amm::ID,
                accounts: deep_amm::accounts::CreateCreatorFeeShare {
                    owner: amm_admin.pubkey(),
                    creator,
                    amm_config: amm_config_1(),
                    creator_fee_share: share,
                    system_program: anchor_lang::system_program::ID,
                }
                .to_account_metas(None),
                data: deep_amm::instruction::CreateCreatorFeeShare {
                    share_rate: 1_000_000,
                }
                .data(),
            };
            env.send(ix, &[&amm_admin]).expect("create a 100% share");
            assert_eq!(
                set_v1_param(&mut env, AMM_PARAM_CREATOR_FEE_SHARE_RATE, 500_000).unwrap_err(),
                V1_ERR_FEE_MODEL_MISMATCH
            );
        }
        let stranger = Keypair::new().pubkey();
        let wrong = v1_collect_reward_ix(&cranker.pubkey(), &stranger, &k, &pool, amm_config_1());
        assert_eq!(
            env.send_ixs(vec![cu_limit_ix(400_000), wrong], &[&cranker])
                .unwrap_err(),
            ANCHOR_CONSTRAINT_ADDRESS,
            "a reward can only go to the pool's recorded recipient"
        );
        let ix = v1_collect_reward_ix(&cranker.pubkey(), &recipient, &k, &pool, amm_config_1());
        if standard {
            assert_eq!(
                env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&cranker])
                    .unwrap_err(),
                CPMM_ERR_NO_FEE_COLLECT
            );
        } else {
            let got_before = env.token_balance(&recipient, &NATIVE_MINT);
            env.send_ixs(vec![cu_limit_ix(400_000), ix.clone()], &[&cranker])
                .expect("collect the reward");
            assert_eq!(
                env.token_balance(&recipient, &NATIVE_MINT) - got_before,
                reward_total,
                "the recipient gets 100% of the reward"
            );
            let ata = get_associated_token_address(&recipient, &NATIVE_MINT);
            assert_eq!(env.load::<TokenAccount>(&ata).owner, recipient);
            assert_eq!(env.token_balance(&recipient, &t.mint), 0);
            assert_eq!(
                env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&cranker])
                    .unwrap_err(),
                CPMM_ERR_NO_FEE_COLLECT
            );
        }

        // Nothing is left accrued, and the SOL vault reconciles to the lamport: what
        // graduation seeded, plus what the trader paid, minus what the trader received,
        // minus DEEP's part, minus the reward. The LP part is still inside.
        assert_eq!(pool_fee_parts(&env, &k.pool_state), [0u64; 6]);
        let wsol_vault = if wsol_is_0 {
            pool.token_0_vault
        } else {
            pool.token_1_vault
        };
        assert_eq!(
            env.load::<TokenAccount>(&wsol_vault).amount,
            alloc.lp_sol + sol_in - sol_out - deep_total - reward_total
        );

        // The splitter: the builder gets exactly 10% of everything that reached the vault
        // (DeepSwap's DEEP part included), never more.
        env.distribute().expect("distribute");
        let s = env.splitter();
        assert_eq!(s.builder_paid_total as u128, s.base_total / 10);
        assert_eq!(builder_paid(&env), s.builder_paid_total);
        assert_eq!(env.load::<TokenAccount>(&fee_vault_wsol()).amount, 0);
    }

    println!("\n── DEEP V1 DeepSwap compute units (LiteSVM) ──");
    for (name, cu) in &rows {
        println!("{name:<40} {cu:>8}");
        let budget = if name.starts_with("graduate") {
            GRADUATE_CU_LIMIT as u64
        } else {
            100_000
        };
        assert!(*cu < budget, "{name} exceeds its CU budget");
    }
}

fn holder_fees_field(env: &Env, t: &Token) -> u64 {
    env.curve(t).holder_fees_unclaimed
}

/// `graduate` sweeps a Holder token's curve reward fees to its holder vault when the vault
/// can hold them, and otherwise SKIPS the sweep without failing the graduation: the fees stay
/// on the curve, counted, and `sweep_holder_fees` drains them exactly later.
#[test]
fn graduate_sweeps_curve_holder_fees_or_skips_without_failing_and_nothing_is_stranded() {
    // Holder tokens launched at a 1% reward rate: the curve phase accrues holder fees
    let mut env = env_v1();
    let migration = env.migration.insecure_clone();
    env.set_unix_time(1_800_000_000);

    // A. the accrued amount alone covers the vault's rent minimum: swept inside graduate
    let t = env.create_token_model(REWARD_MODEL_HOLDER);
    env.complete_curve(&t);
    let held = holder_fees_field(&env, &t);
    assert!(held > env.rent0());
    let vault = holder_vault(&t.mint);
    assert_eq!(env.lamports(&vault), 0);
    let meta = env.graduate(&t, &migration).expect("graduate");
    assert_eq!(holder_fees_field(&env, &t), 0);
    assert_eq!(env.lamports(&vault), held);
    assert_eq!(env.curve_surplus(&t), 0);
    let swept: Vec<deep_curve::HolderFeesSwept> = events_of(&meta);
    assert_eq!(swept.len(), 1);
    assert_eq!(
        (swept[0].mint, swept[0].holder_vault, swept[0].amount),
        (t.mint, vault, held)
    );
    assert_eq!(
        read_v1_pool(&env, &pool_keys(&t.mint).pool_state).pool_creator,
        vault
    );

    // B. the vault passed read-only: the sweep is skipped, graduation succeeds
    let t = env.create_token_model(REWARD_MODEL_HOLDER);
    env.complete_curve(&t);
    let held = holder_fees_field(&env, &t);
    let vault = holder_vault(&t.mint);
    let ix = env.ix_graduate_as(
        &t,
        &migration.pubkey(),
        amm_config_1(),
        raydium::CP_SWAP_PROGRAM_ID,
        vault,
    );
    assert!(!ix.accounts[GRADUATE_REWARD_RECIPIENT].is_writable);
    let meta = env
        .send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&migration])
        .expect("graduate with a read-only holder vault");
    assert!(events_of::<deep_curve::HolderFeesSwept>(&meta).is_empty());
    assert!(env.curve(&t).graduated);
    assert_eq!(holder_fees_field(&env, &t), held);
    assert_eq!(env.lamports(&vault), 0);
    assert_eq!(env.curve_surplus(&t), 0);
    let cranker = env.user(SOL);
    let ix = env.ix_sweep_holder(&t);
    env.send(ix, &[&cranker]).expect("sweep after graduation");
    assert_eq!(holder_fees_field(&env, &t), 0);
    assert_eq!(env.lamports(&vault), held);
    assert_eq!(env.curve_surplus(&t), 0);

    // C. the vault would end below its rent minimum: skipped, never failed. (The accrued
    //    amount is set to 1,000 lamports directly in the account, with the curve's balance
    //    lowered by the same difference, because a real curve's volume always accrues more.)
    let t = env.create_token_model(REWARD_MODEL_HOLDER);
    env.complete_curve(&t);
    let vault = holder_vault(&t.mint);
    let mut acc = env.svm.get_account(&t.curve).unwrap();
    assert_eq!(acc.data.len(), deep_curve::BONDING_CURVE_V3_SIZE);
    let held = u64::from_le_bytes(acc.data[188..196].try_into().unwrap());
    assert_eq!(held, holder_fees_field(&env, &t));
    acc.data[188..196].copy_from_slice(&1_000u64.to_le_bytes());
    acc.lamports -= held - 1_000;
    env.svm.set_account(t.curve, acc).unwrap();
    assert_eq!(env.curve_surplus(&t), 0);
    let meta = env
        .graduate(&t, &migration)
        .expect("graduate, sweep skipped");
    assert!(events_of::<deep_curve::HolderFeesSwept>(&meta).is_empty());
    assert_eq!(holder_fees_field(&env, &t), 1_000);
    assert_eq!(env.lamports(&vault), 0);
    assert_eq!(env.curve_surplus(&t), 0);
    let ix = env.ix_sweep_holder(&t);
    assert_eq!(
        env.send(ix, &[&cranker]).unwrap_err(),
        custom(DeepError::HolderVaultBelowRent)
    );
    // once the vault holds its rent reserve (what init_distributor funds), it drains exactly
    let rent0 = env.rent0();
    env.svm.airdrop(&vault, rent0).unwrap();
    let ix = env.ix_sweep_holder(&t);
    env.send(ix, &[&cranker]).expect("sweep");
    assert_eq!(holder_fees_field(&env, &t), 0);
    assert_eq!(env.lamports(&vault), rent0 + 1_000);
    assert_eq!(env.curve_surplus(&t), 0);

    // The recipient is fixed by the token's model: a Holder token cannot graduate with its
    // creator as the pool's reward recipient, nor a Creator token with a holder vault.
    for (model, wrong_is_vault) in [(REWARD_MODEL_HOLDER, false), (REWARD_MODEL_CREATOR, true)] {
        let t = env.create_token_model(model);
        env.complete_curve(&t);
        let wrong = if wrong_is_vault {
            holder_vault(&t.mint)
        } else {
            env.creator.pubkey()
        };
        let ix = env.ix_graduate_as(
            &t,
            &migration.pubkey(),
            amm_config_1(),
            raydium::CP_SWAP_PROGRAM_ID,
            wrong,
        );
        assert_eq!(
            env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&migration])
                .unwrap_err(),
            custom(DeepError::InvalidPool)
        );
        env.graduate(&t, &migration)
            .expect("graduate with the right recipient");
    }
}

/// Keys of a second pool for (WSOL, `mint`) at deep-amm's canonical address under `cfg`.
fn second_pool_keys(mint: &Pubkey, cfg: &Pubkey) -> (PoolKeys, Pubkey, Pubkey) {
    let (m0, m1) = if NATIVE_MINT < *mint {
        (NATIVE_MINT, *mint)
    } else {
        (*mint, NATIVE_MINT)
    };
    let pda = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let pool_state = pda(&[b"pool", cfg.as_ref(), m0.as_ref(), m1.as_ref()]);
    let lp_mint = pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()]);
    let vault = |m: &Pubkey| pda(&[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()]);
    (
        PoolKeys {
            pool_state,
            lp_mint,
            token_vault: vault(mint),
            wsol_vault: vault(&NATIVE_MINT),
            observation: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]),
            ..pool_keys(mint)
        },
        m0,
        m1,
    )
}

fn vault_of(k: &PoolKeys, mint: &Pubkey) -> Pubkey {
    if *mint == NATIVE_MINT {
        k.wsol_vault
    } else {
        k.token_vault
    }
}

fn init_with_permission_ix(
    payer: &Pubkey,
    creator: &Pubkey,
    cfg: Pubkey,
    k: &PoolKeys,
    (m0, m1): (Pubkey, Pubkey),
    data: Vec<u8>,
) -> Instruction {
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::InitializeWithPermission {
            payer: *payer,
            creator: *creator,
            amm_config: cfg,
            authority: k.authority,
            pool_state: k.pool_state,
            token_0_mint: m0,
            token_1_mint: m1,
            lp_mint: k.lp_mint,
            payer_token_0: get_associated_token_address(payer, &m0),
            payer_token_1: get_associated_token_address(payer, &m1),
            payer_lp_token: get_associated_token_address(payer, &k.lp_mint),
            token_0_vault: vault_of(k, &m0),
            token_1_vault: vault_of(k, &m1),
            create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
            observation_state: k.observation,
            permission: permission_pda(payer),
            token_program: anchor_spl::token::ID,
            token_0_program: anchor_spl::token::ID,
            token_1_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data,
    }
}

fn quote_on(token_0: bool) -> deep_amm::states::CreatorFeeOn {
    if token_0 {
        deep_amm::states::CreatorFeeOn::OnlyToken0
    } else {
        deep_amm::states::CreatorFeeOn::OnlyToken1
    }
}

/// `initialize_with_permission_v1` needs the payer's Permission, a V1 config, the WSOL side
/// as the quote and a valid reward model; the legacy instruction cannot create a pool under
/// a V1 config (it could never be priced). The permissionless `initialize` under a V1 config
/// opens a V1 Standard pool at the V1 Standard rates.
#[test]
fn v1_pool_creation_rules_with_and_without_permission() {
    let mut env = env_v1();
    let (t, k, _) = v1_graduated(&mut env, REWARD_MODEL_STANDARD);
    let user = deepswap_trader(&mut env, &t.mint, 30 * SOL);
    let up = user.pubkey();
    checked_v1_swap(&mut env, &user, &t, &k, false, true, 5 * SOL);
    let tokens = env.token_balance(&up, &t.mint);
    assert!(tokens > 4);

    let (k1, m0, m1) = second_pool_keys(&t.mint, &amm_config_1());
    let (k0, ..) = second_pool_keys(&t.mint, &amm_config_0());
    let wsol_is_0 = m0 == NATIVE_MINT;
    let (a_sol, a_tok) = (2 * SOL, tokens / 4);
    let (init_amount_0, init_amount_1) = if wsol_is_0 {
        (a_sol, a_tok)
    } else {
        (a_tok, a_sol)
    };
    let v1_data_rate = |on: deep_amm::states::CreatorFeeOn, reward_model: u8, reward_rate: u64| {
        deep_amm::instruction::InitializeWithPermissionV1 {
            init_amount_0,
            init_amount_1,
            open_time: 0,
            creator_fee_on: on,
            reward_model,
            reward_rate,
        }
        .data()
    };
    let v1_data = |on: deep_amm::states::CreatorFeeOn, reward_model: u8| {
        let rate = if reward_model == REWARD_MODEL_STANDARD {
            0
        } else {
            10_000
        };
        v1_data_rate(on, reward_model, rate)
    };
    let legacy_data = deep_amm::instruction::InitializeWithPermission {
        init_amount_0,
        init_amount_1,
        open_time: 0,
        creator_fee_on: quote_on(wsol_is_0),
    }
    .data();
    let recipient = Keypair::new().pubkey();
    let try_init = |env: &mut Env, cfg: Pubkey, k: &PoolKeys, data: Vec<u8>| {
        let ix = init_with_permission_ix(&up, &recipient, cfg, k, (m0, m1), data);
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user])
    };

    // no Permission for this payer
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data(quote_on(wsol_is_0), REWARD_MODEL_CREATOR)
        )
        .unwrap_err(),
        ANCHOR_ACCOUNT_NOT_INITIALIZED
    );
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let grant = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreatePermissionPda {
            owner: amm_admin.pubkey(),
            permission_authority: up,
            permission: permission_pda(&up),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreatePermissionPda {}.data(),
    };
    env.send(grant, &[&amm_admin]).expect("grant a Permission");

    // the V1 instruction under a legacy config, and the legacy instruction under a V1 config
    assert_eq!(
        try_init(
            &mut env,
            amm_config_0(),
            &k0,
            v1_data(quote_on(wsol_is_0), REWARD_MODEL_CREATOR)
        )
        .unwrap_err(),
        V1_ERR_FEE_MODEL_MISMATCH
    );
    assert_eq!(
        try_init(&mut env, amm_config_1(), &k1, legacy_data).unwrap_err(),
        V1_ERR_FEE_MODEL_MISMATCH
    );
    // the quote must be one side, and the WSOL side when the pair has WSOL
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data(
                deep_amm::states::CreatorFeeOn::BothToken,
                REWARD_MODEL_CREATOR
            )
        )
        .unwrap_err(),
        V1_ERR_INVALID_QUOTE_SIDE
    );
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data(quote_on(!wsol_is_0), REWARD_MODEL_CREATOR)
        )
        .unwrap_err(),
        V1_ERR_INVALID_QUOTE_SIDE
    );
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data(quote_on(wsol_is_0), 3)
        )
        .unwrap_err(),
        V1_ERR_INVALID_REWARD_MODEL
    );
    // the reward rate: none for Standard, at most 10% otherwise
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data_rate(quote_on(wsol_is_0), REWARD_MODEL_STANDARD, 1)
        )
        .unwrap_err(),
        V1_ERR_INVALID_REWARD_RATE
    );
    assert_eq!(
        try_init(
            &mut env,
            amm_config_1(),
            &k1,
            v1_data_rate(quote_on(wsol_is_0), REWARD_MODEL_CREATOR, 50_001)
        )
        .unwrap_err(),
        V1_ERR_INVALID_REWARD_RATE
    );
    // valid: a Holder-model pool whose reward goes to the named recipient
    try_init(
        &mut env,
        amm_config_1(),
        &k1,
        v1_data(quote_on(wsol_is_0), REWARD_MODEL_HOLDER),
    )
    .expect("initialize_with_permission_v1");
    let raw = read_v1_pool(&env, &k1.pool_state);
    assert_eq!(
        (raw.fee_model, raw.reward_model, raw.reward_rate),
        (1, 2, 10_000)
    );
    assert_eq!(raw.pool_creator, recipient);
    assert_eq!(raw.creator_fee_on, if wsol_is_0 { 1 } else { 2 });
    assert!(raw.enable_creator_fee);
    env.set_unix_time(1_800_000_010);
    let (e, _) = checked_v1_swap(&mut env, &user, &t, &k1, false, true, SOL / 10);
    assert!(e.reward > 0);
    let pool = live_pool(&env, &k1);
    let ix = v1_collect_reward_ix(&up, &recipient, &k1, &pool, amm_config_1());
    env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&user])
        .expect("collect the reward");
    assert_eq!(env.token_balance(&recipient, &NATIVE_MINT), e.reward);
}

#[test]
fn permissionless_initialize_under_a_v1_config_opens_a_v1_standard_pool() {
    let mut env = env_v1();
    // graduate a Creator token, so the pair's graduation pool charges a reward and the
    // permissionless pool of the same pair must not
    let (t, k, _) = v1_graduated(&mut env, REWARD_MODEL_CREATOR);
    let user = deepswap_trader(&mut env, &t.mint, 30 * SOL);
    let up = user.pubkey();
    checked_v1_swap(&mut env, &user, &t, &k, false, true, 5 * SOL);
    let tokens = env.token_balance(&up, &t.mint);

    let (k2, m0, m1) = second_pool_keys(&t.mint, &amm_config_1());
    let wsol_is_0 = m0 == NATIVE_MINT;
    let (a_sol, a_tok) = (2 * SOL, tokens / 2);
    let (init_amount_0, init_amount_1) = if wsol_is_0 {
        (a_sol, a_tok)
    } else {
        (a_tok, a_sol)
    };
    let init = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::Initialize {
            creator: up,
            amm_config: amm_config_1(),
            authority: k2.authority,
            pool_state: k2.pool_state,
            token_0_mint: m0,
            token_1_mint: m1,
            lp_mint: k2.lp_mint,
            creator_token_0: get_associated_token_address(&up, &m0),
            creator_token_1: get_associated_token_address(&up, &m1),
            creator_lp_token: get_associated_token_address(&up, &k2.lp_mint),
            token_0_vault: vault_of(&k2, &m0),
            token_1_vault: vault_of(&k2, &m1),
            create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
            observation_state: k2.observation,
            token_program: anchor_spl::token::ID,
            token_0_program: anchor_spl::token::ID,
            token_1_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            rent: "SysvarRent111111111111111111111111111111111"
                .parse()
                .unwrap(),
        }
        .to_account_metas(None),
        data: deep_amm::instruction::Initialize {
            init_amount_0,
            init_amount_1,
            open_time: 0,
        }
        .data(),
    };
    env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), init], &[&user])
        .expect("permissionless initialize under a V1 config");
    env.set_unix_time(1_800_000_010);

    let raw = read_v1_pool(&env, &k2.pool_state);
    assert_eq!(
        (raw.fee_model, raw.reward_model, raw.reward_rate),
        (1, 0, 0)
    );
    assert_eq!(raw.amm_config, amm_config_1());
    assert_eq!(raw.creator_fee_on, if wsol_is_0 { 1 } else { 2 });
    assert!(!raw.enable_creator_fee);
    assert_eq!(v1_live_rates(&env, &k2, true), (1_000, 2_500, 0));
    assert_eq!(v1_live_rates(&env, &k2, false), (1_000, 6_500, 0));

    let mut deep_total = 0;
    for (base_output, is_buy, amount) in [
        (false, true, SOL / 4),
        (false, false, 1_000 * UNIT),
        (true, true, 500 * UNIT),
        (true, false, SOL / 100),
    ] {
        let (e, _) = checked_v1_swap(&mut env, &user, &t, &k2, base_output, is_buy, amount);
        assert_eq!(e.reward, 0);
        deep_total += e.deep;
    }
    // no reward ever accrues; DEEP's part drains to the fee vault exactly
    let pool = live_pool(&env, &k2);
    let ix = v1_collect_reward_ix(&up, &up, &k2, &pool, amm_config_1());
    assert_eq!(
        env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&user])
            .unwrap_err(),
        CPMM_ERR_NO_FEE_COLLECT
    );
    let before = env.load::<TokenAccount>(&fee_vault_wsol()).amount;
    let r0 = get_associated_token_address(&fee_vault_pda(), &pool.token_0_mint);
    let r1 = get_associated_token_address(&fee_vault_pda(), &pool.token_1_mint);
    let collect = with_amm_config(collect_to_vault_ix(&k2, &pool, r0, r1), amm_config_1());
    env.send(collect, &[&user])
        .expect("collect to the fee vault");
    assert_eq!(
        env.load::<TokenAccount>(&fee_vault_wsol()).amount - before,
        deep_total
    );
    assert_eq!(pool_fee_parts(&env, &k2.pool_state), [0u64; 6]);
}

/// A pool is priced only with the fee model it was created under: a legacy pool never with
/// V1 rates, a V1 pool never with legacy rates, whatever config account is passed.
#[test]
fn a_pool_is_never_priced_with_the_other_fee_model() {
    // a V1 pool
    let mut env = env_v1();
    let (t, k, _) = v1_graduated(&mut env, REWARD_MODEL_CREATOR);
    let trader = deepswap_trader(&mut env, &t.mint, 20 * SOL);
    let tp = trader.pubkey();
    checked_v1_swap(&mut env, &trader, &t, &k, false, true, 2 * SOL);
    let pool = live_pool(&env, &k);
    for base_output in [false, true] {
        let swap = |cfg: Pubkey| {
            let (a, b) = if base_output {
                (SOL, 1_000 * UNIT)
            } else {
                (SOL / 10, 1)
            };
            with_amm_config(
                amm_swap_ix(base_output, &tp, &k, &pool, NATIVE_MINT, a, b),
                cfg,
            )
        };
        // the legacy config cannot be passed for a V1 pool
        assert_eq!(
            env.send(swap(amm_config_0()), &[&trader]).unwrap_err(),
            ANCHOR_CONSTRAINT_ADDRESS
        );
        // a pool whose model byte disagrees with its config (corrupted state) is refused
        patch_pool_byte(&mut env, &k.pool_state, 413, 0);
        assert_eq!(
            env.send(swap(amm_config_1()), &[&trader]).unwrap_err(),
            V1_ERR_FEE_MODEL_MISMATCH
        );
        patch_pool_byte(&mut env, &k.pool_state, 413, 2);
        assert_eq!(
            env.send(swap(amm_config_1()), &[&trader]).unwrap_err(),
            V1_ERR_FEE_MODEL_MISMATCH
        );
        patch_pool_byte(&mut env, &k.pool_state, 413, 1);
        env.send(swap(amm_config_1()), &[&trader])
            .expect("the untouched V1 pool trades");
    }

    // a legacy pool (the pre-V1 world: deep-curve still points at the legacy config #0)
    let mut env = Env::new();
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    env.send(
        create_v1_config_ix(&amm_admin.pubkey(), 1, V1_RATES),
        &[&amm_admin],
    )
    .unwrap();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let raw = read_v1_pool(&env, &k.pool_state);
    assert_eq!((raw.fee_model, raw.amm_config), (0, amm_config_0()));
    let trader = deepswap_trader(&mut env, &t.mint, 20 * SOL);
    let tp = trader.pubkey();
    let pool = live_pool(&env, &k);
    for base_output in [false, true] {
        let swap = |cfg: Pubkey| {
            let (a, b) = if base_output {
                (SOL, 1_000 * UNIT)
            } else {
                (SOL / 10, 1)
            };
            with_amm_config(
                amm_swap_ix(base_output, &tp, &k, &pool, NATIVE_MINT, a, b),
                cfg,
            )
        };
        assert_eq!(
            env.send(swap(amm_config_1()), &[&trader]).unwrap_err(),
            ANCHOR_CONSTRAINT_ADDRESS
        );
        patch_pool_byte(&mut env, &k.pool_state, 413, 1);
        assert_eq!(
            env.send(swap(amm_config_0()), &[&trader]).unwrap_err(),
            V1_ERR_FEE_MODEL_MISMATCH
        );
        patch_pool_byte(&mut env, &k.pool_state, 413, 0);
    }
    // untouched, it trades with the legacy math: 0.30% of the input, nothing off the output
    let (pool, ri, ro) = live_reserves(&env, &k, NATIVE_MINT);
    let amount = SOL / 10;
    let fee = (amount as u128 * 3_000).div_ceil(1_000_000) as u64;
    let net = (amount - fee) as u128;
    let out = (net * ro as u128 / (ri as u128 + net)) as u64;
    let before = env.token_balance(&tp, &t.mint);
    let ix = amm_swap_ix(false, &tp, &k, &pool, NATIVE_MINT, amount, out);
    let meta = env.send(ix, &[&trader]).expect("legacy swap");
    assert_eq!(env.token_balance(&tp, &t.mint) - before, out);
    assert!(events_of::<deep_amm::states::SwapFeesV1>(&meta).is_empty());
    let swaps: Vec<deep_amm::states::SwapEvent> = events_of(&meta);
    assert_eq!(swaps[0].trade_fee, fee);
}

/// The V1 AmmConfig: created by the admin only, capped at 10% per side at creation and on
/// every change, its fee model fixed (no parameter changes it), legacy rate parameters
/// refused on it and V1 parameters refused on a legacy config, its legacy fields kept as a
/// mirror of the buy side.
#[test]
fn v1_amm_config_rates_are_capped_mirrored_and_fixed_to_their_fee_model() {
    let mut env = env_v1();
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let c = amm_cfg(&env, &amm_config_1());
    assert_eq!(c.fee_model, 1);
    assert_eq!(
        [
            c.buy_lp_fee_rate,
            c.buy_protocol_fee_rate,
            c.sell_lp_fee_rate,
            c.sell_protocol_fee_rate
        ],
        V1_RATES
    );
    assert_eq!(c.protocol_owner, fee_vault_pda());
    assert_eq!(c.fund_owner, deep_amm::deep_keys::BUILDER);
    assert_eq!(
        (c.fund_fee_rate, c.create_pool_fee),
        (0, AMM_CREATE_POOL_FEE)
    );
    // the current maximum reward rate for new pools starts at the 5% ceiling
    assert_eq!(c.max_reward_rate, 50_000);
    // the legacy mirror: 0.35% trade fee, DEEP's share of it, no creator fee
    assert_eq!((c.trade_fee_rate, c.protocol_fee_rate), (3_500, 714_285));
    assert_eq!((c.creator_fee_rate, c.creator_fee_share_rate), (0, 0));
    // the legacy config is untouched and stays legacy
    let legacy = amm_cfg(&env, &amm_config_0());
    assert_eq!(legacy.fee_model, 0);
    assert_eq!(legacy.trade_fee_rate, AMM_TRADE_FEE_RATE);
    assert_eq!(legacy.buy_lp_fee_rate + legacy.sell_protocol_fee_rate, 0);

    // creation: admin only, capped
    let stranger = env.user(SOL);
    assert_eq!(
        env.send(
            create_v1_config_ix(&stranger.pubkey(), 2, V1_RATES),
            &[&stranger]
        )
        .unwrap_err(),
        CPMM_ERR_INVALID_OWNER
    );
    for bad in [
        [1_000, 49_001, 1_000, 6_500],
        [1_000, 2_500, 1_000, 49_001],
        [999_999, 0, 0, 0],
        [u64::MAX, 1, 0, 0],
        [0, 0, 1, u64::MAX],
    ] {
        assert_eq!(
            env.send(
                create_v1_config_ix(&amm_admin.pubkey(), 2, bad),
                &[&amm_admin]
            )
            .unwrap_err(),
            CPMM_ERR_FEE_RATE_ABOVE_CAP,
            "{bad:?}"
        );
    }
    // LP + DEEP up to 5% on a side (the other 5% is the reward ceiling) is allowed
    env.send(
        create_v1_config_ix(&amm_admin.pubkey(), 2, [1_000, 49_000, 0, 50_000]),
        &[&amm_admin],
    )
    .expect("a config at the cap");

    // updates: each parameter, the cap on every change, the mirror kept
    assert_eq!(
        set_v1_param(&mut env, V1_PARAM_BUY_PROTOCOL, 49_001).unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    assert_eq!(
        set_v1_param(&mut env, V1_PARAM_SELL_PROTOCOL, 49_001).unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    assert_eq!(
        set_v1_param(&mut env, V1_PARAM_BUY_LP, u64::MAX).unwrap_err(),
        CPMM_ERR_FEE_RATE_ABOVE_CAP
    );
    set_v1_param(&mut env, V1_PARAM_BUY_PROTOCOL, 4_000).unwrap();
    set_v1_param(&mut env, V1_PARAM_BUY_LP, 1_500).unwrap();
    let c = amm_cfg(&env, &amm_config_1());
    assert_eq!((c.buy_lp_fee_rate, c.buy_protocol_fee_rate), (1_500, 4_000));
    assert_eq!((c.trade_fee_rate, c.protocol_fee_rate), (5_500, 727_272));
    assert_eq!(c.fee_model, 1);

    // the fee model has no parameter, a pool's reward rate is not a config value (no
    // parameter either), and each model only takes its own rate parameters
    for no_such_param in [9u8, 15, 16] {
        assert_eq!(
            set_v1_param(&mut env, no_such_param, 0).unwrap_err(),
            V1_ERR_INVALID_INPUT
        );
    }
    for legacy_param in [
        0u8,
        1,
        AMM_PARAM_CREATOR_FEE_RATE,
        AMM_PARAM_CREATOR_FEE_SHARE_RATE,
    ] {
        assert_eq!(
            set_v1_param(&mut env, legacy_param, 1_000).unwrap_err(),
            V1_ERR_FEE_MODEL_MISMATCH
        );
    }
    for v1_param in 10u8..=14 {
        assert_eq!(
            env.send(update_amm_ix(v1_param, 1_000, None), &[&amm_admin])
                .unwrap_err(),
            V1_ERR_FEE_MODEL_MISMATCH
        );
    }
    assert_eq!(amm_cfg(&env, &amm_config_0()).fee_model, 0);
    // not the admin
    let ix = with_amm_config(update_amm_ix(V1_PARAM_BUY_LP, 1, None), amm_config_1());
    let mut ix_stranger = ix.clone();
    ix_stranger.accounts[0].pubkey = stranger.pubkey();
    assert_eq!(
        env.send(ix_stranger, &[&stranger]).unwrap_err(),
        CPMM_ERR_INVALID_OWNER
    );
    // the fund fee and the protocol owner stay locked on a V1 config too
    assert_eq!(
        set_v1_param(&mut env, 2, 1).unwrap_err(),
        CPMM_ERR_BUILDER_FEE_LOCKED
    );
    let other = Keypair::new().pubkey();
    assert_eq!(
        env.send(
            with_amm_config(update_amm_ix(3, 0, Some(other)), amm_config_1()),
            &[&amm_admin]
        )
        .unwrap_err(),
        CPMM_ERR_PROTOCOL_OWNER_LOCKED
    );
}

const V1_ERR_HOLDER_NEEDS_SOL_QUOTE: u32 = 6024;
const V1_ERR_REWARD_ABOVE_MAX: u32 = 6025;
const V1_PARAM_MAX_REWARD: u8 = 14;

/// The creator chooses the reward rate at launch (0 for Standard, 1..=500 bps for Creator
/// and Holder, under the admin's current maximum and the 10% total per side), it is
/// immutable, and the curve charges it on buys and sells on top of DEEP's protocol fee, to
/// the creator or to the holders. Every balance drains exactly.
#[test]
fn the_creator_chooses_the_reward_rate_at_launch_and_the_curve_charges_it_on_both_sides() {
    let mut env = env_v1();
    // Standard has no rate; Creator and Holder need one; nobody goes above 500 bps
    for (model, bps) in [
        (REWARD_MODEL_STANDARD, 1u16),
        (REWARD_MODEL_STANDARD, 500),
        (REWARD_MODEL_CREATOR, 0),
        (REWARD_MODEL_HOLDER, 0),
        (REWARD_MODEL_CREATOR, 501),
        (REWARD_MODEL_HOLDER, 1_000),
        (REWARD_MODEL_HOLDER, u16::MAX),
    ] {
        assert_eq!(
            env.try_create_token_reward(model, bps).err().unwrap(),
            custom(DeepError::InvalidRewardRate),
            "{model}/{bps}"
        );
    }
    assert_eq!(
        env.try_create_token_reward(3, 100).err().unwrap(),
        custom(DeepError::InvalidRewardModel)
    );

    for (model, bps) in [
        (REWARD_MODEL_CREATOR, 1u16),
        (REWARD_MODEL_CREATOR, 100),
        (REWARD_MODEL_CREATOR, 500),
        (REWARD_MODEL_HOLDER, 1),
        (REWARD_MODEL_HOLDER, 500),
        (REWARD_MODEL_HOLDER, 333),
    ] {
        let t = env.create_token_reward(model, bps);
        let c = env.curve(&t);
        assert_eq!(
            c.fees_v1(),
            FeesV1 {
                buy_protocol_fee_bps: 125,
                sell_protocol_fee_bps: 125,
                reward_bps: bps,
                reward_model: model
            }
        );
        // raw bytes other programs and the SDK read: creator_fee_bps (the reward rate) at
        // 122, reward_model at 187
        let raw = env.svm.get_account(&t.curve).unwrap().data;
        assert_eq!(u16::from_le_bytes([raw[122], raw[123]]), bps);
        assert_eq!(raw[187], model);

        // buy 1 SOL: 1.25% to DEEP plus the creator's rate, e.g. 6.25% at 500 bps
        let user = env.user(50 * SOL);
        let m = env.buy(&t, &user, SOL).unwrap();
        let reward = SOL / 10_000 * bps as u64;
        let total = (SOL as u128 * (125 + bps as u128)).div_ceil(10_000) as u64;
        assert_eq!(total, 12_500_000 + reward);
        let c = env.curve(&t);
        let (to_creator, to_holders) = if model == REWARD_MODEL_HOLDER {
            (0, reward)
        } else {
            (reward, 0)
        };
        assert_eq!(c.protocol_fees_unclaimed, 12_500_000);
        assert_eq!(
            (c.creator_fees_unclaimed, c.holder_fees_unclaimed),
            (to_creator, to_holders)
        );
        let ev = trade_events(&m);
        assert_eq!(
            (ev[0].protocol_fee, ev[0].creator_fee, ev[0].holder_fee),
            (12_500_000, to_creator, to_holders)
        );

        // sell half: the same rate on the SOL the curve pays out
        let tokens = env.token_balance(&user.pubkey(), &t.mint) / 2;
        let (q, r) = math::quote_sell_v1(&to_math(&c), tokens, &c.fees_v1(), 0).unwrap();
        assert_eq!(
            q.fees.total,
            (q.sol_from_curve as u128 * (125 + bps as u128)).div_ceil(10_000) as u64
        );
        assert_eq!(r.protocol + r.creator + r.holder, q.fees.total);
        let u0 = env.lamports(&user.pubkey());
        env.sell(&t, &user, tokens).unwrap();
        assert_eq!(env.lamports(&user.pubkey()) - u0, q.sol_out - 5_000);
        let c = env.curve(&t);
        assert_eq!(c.protocol_fees_unclaimed, 12_500_000 + r.protocol);
        assert_eq!(c.creator_fees_unclaimed, to_creator + r.creator);
        assert_eq!(c.holder_fees_unclaimed, to_holders + r.holder);
        assert_eq!(env.curve_surplus(&t), 0);

        // every balance has its way out, to the lamport
        let v0 = vault_revenue(&env);
        let ix = env.ix_sweep(&t);
        env.send(ix, &[&user]).unwrap();
        assert_eq!(vault_revenue(&env) - v0, c.protocol_fees_unclaimed);
        if model == REWARD_MODEL_HOLDER {
            let vault = holder_vault(&t.mint);
            let rent0 = env.rent0();
            env.svm.airdrop(&vault, rent0).unwrap(); // the reserve init_distributor funds
            let ix = env.ix_sweep_holder(&t);
            env.send(ix, &[&user]).unwrap();
            assert_eq!(env.lamports(&vault) - rent0, c.holder_fees_unclaimed);
        } else {
            let creator = env.creator.insecure_clone();
            let c0 = env.lamports(&creator.pubkey());
            let ix = env.ix_claim(&t, &creator.pubkey());
            env.send(ix, &[&creator]).unwrap();
            assert_eq!(
                env.lamports(&creator.pubkey()) - c0,
                c.creator_fees_unclaimed - 5_000
            );
        }
        let c = env.curve(&t);
        assert_eq!(
            (
                c.protocol_fees_unclaimed,
                c.creator_fees_unclaimed,
                c.holder_fees_unclaimed
            ),
            (0, 0, 0)
        );
        assert_eq!(env.curve_surplus(&t), 0);
    }
}

/// `graduate` carries the token's own reward rate (the one its curve charged) into its V1
/// pool, where it is charged on both sides on top of the config's LP + DEEP rates. It is the
/// pool's for good: no AmmConfig change touches it, and a side never costs more than 10%
/// (LP + DEEP at most 5%, the reward at most 5%).
#[test]
fn graduate_carries_the_tokens_own_reward_rate_into_its_pool_and_no_config_change_touches_it() {
    let mut env = env_v1();
    let mut pools = Vec::new();
    for (model, bps) in [
        (REWARD_MODEL_CREATOR, 1u16),
        (REWARD_MODEL_HOLDER, 500),
        (REWARD_MODEL_CREATOR, 250),
    ] {
        env.set_unix_time(1_800_000_000);
        let t = env.create_token_reward(model, bps);
        env.complete_curve(&t);
        let migration = env.migration.insecure_clone();
        env.graduate(&t, &migration).expect("graduate");
        env.set_unix_time(1_800_000_001);
        let k = pool_keys(&t.mint);
        let raw = read_v1_pool(&env, &k.pool_state);
        assert_eq!((raw.fee_model, raw.reward_model), (1, model));
        assert_eq!(raw.reward_rate, bps as u64 * 100, "bps -> per 1e6");
        assert_eq!(
            v1_live_rates(&env, &k, true),
            (1_000, 2_500, bps as u64 * 100)
        );
        assert_eq!(
            v1_live_rates(&env, &k, false),
            (1_000, 6_500, bps as u64 * 100)
        );
        let trader = deepswap_trader(&mut env, &t.mint, 30 * SOL);
        let mut reward_total = 0;
        for (base_output, is_buy, amount) in [
            (false, true, 4 * SOL),
            (true, true, 500_000 * UNIT),
            (false, false, 2_000_000 * UNIT),
            (true, false, SOL / 3),
        ] {
            let (e, _) = checked_v1_swap(&mut env, &trader, &t, &k, base_output, is_buy, amount);
            reward_total += e.reward;
            if !base_output && is_buy {
                // 4 SOL in: 0.35% plus the token's rate, split to the lamport
                assert_eq!(
                    e.lp + e.deep + e.reward,
                    4 * SOL / 1_000_000 * (3_500 + bps as u64 * 100)
                );
                assert_eq!(e.reward, 4 * SOL / 10_000 * bps as u64);
            }
        }
        pools.push((t, k, trader, model, bps, reward_total));
    }

    // The admin moves DEEP's sell rate to its limit (LP + DEEP = 5%) and lowers the current
    // maximum reward rate for new pools to 0.01%. Every pool keeps its own reward rate; the
    // 500 bps pool now charges exactly the 10% cap on a sell, and still trades exactly.
    set_v1_param(&mut env, V1_PARAM_SELL_PROTOCOL, 49_000).unwrap();
    set_v1_param(&mut env, V1_PARAM_MAX_REWARD, 100).unwrap();
    for (t, k, trader, model, bps, reward_total) in pools.iter_mut() {
        assert_eq!(
            read_v1_pool(&env, &k.pool_state).reward_rate,
            *bps as u64 * 100
        );
        assert_eq!(
            v1_live_rates(&env, k, false),
            (1_000, 49_000, *bps as u64 * 100)
        );
        let (_, ri, ro) = live_reserves(&env, k, t.mint);
        let amount = 1_000_000 * UNIT;
        let gross = amount as u128 * ro as u128 / (ri as u128 + amount as u128);
        let (e, _) = checked_v1_swap(&mut env, trader, t, k, false, false, amount);
        let rate = 50_000 + *bps as u128 * 100;
        assert!(rate <= 100_000);
        assert_eq!(
            (e.lp + e.deep + e.reward) as u128,
            (gross * rate).div_ceil(1_000_000)
        );
        *reward_total += e.reward;
        let (e, _) = checked_v1_swap(&mut env, trader, t, k, true, false, SOL / 10);
        *reward_total += e.reward;

        // the reward drains to its recipient exactly
        let recipient = if *model == REWARD_MODEL_HOLDER {
            holder_vault(&t.mint)
        } else {
            env.creator.pubkey()
        };
        let pool = live_pool(&env, k);
        let before = env.token_balance(&recipient, &NATIVE_MINT);
        let ix = v1_collect_reward_ix(&trader.pubkey(), &recipient, k, &pool, amm_config_1());
        env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&*trader])
            .expect("collect the reward");
        assert_eq!(
            env.token_balance(&recipient, &NATIVE_MINT) - before,
            *reward_total
        );
    }
}

/// Keys of a pool of (WSOL, `mint`) stored at `pool_state`.
fn keys_at(pool_state: Pubkey, mint: &Pubkey) -> PoolKeys {
    let pda = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let vault = |m: &Pubkey| pda(&[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()]);
    PoolKeys {
        pool_state,
        lp_mint: pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()]),
        token_vault: vault(mint),
        wsol_vault: vault(&NATIVE_MINT),
        observation: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]),
        ..pool_keys(mint)
    }
}

/// The permissionless `Initialize` accounts for a pool at `pool_state` with vaults `v0`/`v1`.
#[allow(clippy::too_many_arguments)]
fn initialize_ix(
    creator: &Pubkey,
    cfg: Pubkey,
    pool_state: Pubkey,
    (m0, p0, v0): (Pubkey, Pubkey, Pubkey),
    (m1, p1, v1): (Pubkey, Pubkey, Pubkey),
    data: Vec<u8>,
) -> Instruction {
    let pda = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let lp_mint = pda(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()]);
    let ata = anchor_spl::associated_token::get_associated_token_address_with_program_id;
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::Initialize {
            creator: *creator,
            amm_config: cfg,
            authority: pda(&[raydium::AUTH_SEED]),
            pool_state,
            token_0_mint: m0,
            token_1_mint: m1,
            lp_mint,
            creator_token_0: ata(creator, &m0, &p0),
            creator_token_1: ata(creator, &m1, &p1),
            creator_lp_token: get_associated_token_address(creator, &lp_mint),
            token_0_vault: v0,
            token_1_vault: v1,
            create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
            observation_state: pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]),
            token_program: anchor_spl::token::ID,
            token_0_program: p0,
            token_1_program: p1,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            rent: "SysvarRent111111111111111111111111111111111"
                .parse()
                .unwrap(),
        }
        .to_account_metas(None),
        data,
    }
}

fn initialize_v1_data(
    (init_amount_0, init_amount_1): (u64, u64),
    on: deep_amm::states::CreatorFeeOn,
    reward_model: u8,
    reward_rate: u64,
) -> Vec<u8> {
    deep_amm::instruction::InitializeV1 {
        init_amount_0,
        init_amount_1,
        open_time: 0,
        creator_fee_on: on,
        reward_model,
        reward_rate,
    }
    .data()
}

/// Seventh round: whoever opens a pool chooses its reward model and rate, immutable. The
/// reward recipient is derived by the program: the pool's creator (Creator) or the non-quote
/// token's holder vault (Holder), never an account the caller names.
#[test]
fn initialize_v1_lets_any_pool_creator_choose_the_reward_model_and_rate() {
    let mut env = env_v1();
    let (t, k, _) = v1_graduated(&mut env, REWARD_MODEL_STANDARD);
    let user = deepswap_trader(&mut env, &t.mint, 40 * SOL);
    let up = user.pubkey();
    checked_v1_swap(&mut env, &user, &t, &k, false, true, 8 * SOL);
    let tokens = env.token_balance(&up, &t.mint);
    let (m0, m1) = if NATIVE_MINT < t.mint {
        (NATIVE_MINT, t.mint)
    } else {
        (t.mint, NATIVE_MINT)
    };
    let wsol_is_0 = m0 == NATIVE_MINT;
    let amounts = if wsol_is_0 {
        (2 * SOL, tokens / 8)
    } else {
        (tokens / 8, 2 * SOL)
    };
    let spl = anchor_spl::token::ID;
    let build = |cfg: Pubkey, pool_state: Pubkey, data: Vec<u8>| {
        let kk = keys_at(pool_state, &t.mint);
        initialize_ix(
            &up,
            cfg,
            pool_state,
            (m0, spl, vault_of(&kk, &m0)),
            (m1, spl, vault_of(&kk, &m1)),
            data,
        )
    };
    let (k1, ..) = second_pool_keys(&t.mint, &amm_config_1());
    let (k0, ..) = second_pool_keys(&t.mint, &amm_config_0());
    let try_at_pda = |env: &mut Env, data: Vec<u8>| {
        let ix = build(amm_config_1(), k1.pool_state, data);
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user])
    };

    // refused: a rate on Standard, no rate on Creator / Holder, a rate above 10%, no quote
    // side, the token side as quote of a WSOL pair, an unknown model, a legacy config
    for (on, model, rate, err) in [
        (
            quote_on(wsol_is_0),
            REWARD_MODEL_STANDARD,
            1u64,
            V1_ERR_INVALID_REWARD_RATE,
        ),
        (
            quote_on(wsol_is_0),
            REWARD_MODEL_CREATOR,
            0,
            V1_ERR_INVALID_REWARD_RATE,
        ),
        (
            quote_on(wsol_is_0),
            REWARD_MODEL_HOLDER,
            0,
            V1_ERR_INVALID_REWARD_RATE,
        ),
        (
            quote_on(wsol_is_0),
            REWARD_MODEL_CREATOR,
            50_001,
            V1_ERR_INVALID_REWARD_RATE,
        ),
        (
            deep_amm::states::CreatorFeeOn::BothToken,
            REWARD_MODEL_CREATOR,
            10_000,
            V1_ERR_INVALID_QUOTE_SIDE,
        ),
        (
            quote_on(!wsol_is_0),
            REWARD_MODEL_CREATOR,
            10_000,
            V1_ERR_INVALID_QUOTE_SIDE,
        ),
        (quote_on(wsol_is_0), 3, 10_000, V1_ERR_INVALID_REWARD_MODEL),
    ] {
        assert_eq!(
            try_at_pda(&mut env, initialize_v1_data(amounts, on, model, rate)).unwrap_err(),
            err
        );
    }
    let ix = build(
        amm_config_0(),
        k0.pool_state,
        initialize_v1_data(amounts, quote_on(wsol_is_0), REWARD_MODEL_CREATOR, 10_000),
    );
    assert_eq!(
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user])
            .unwrap_err(),
        V1_ERR_FEE_MODEL_MISMATCH
    );

    // a Holder pool at 0.5%: the recipient is the token's holder vault, derived on chain.
    // Security review F3: anyone can open this pool, so it is refused until DEEP serves the
    // token, i.e. until the (token, SOL) distributor of deep-rewards exists and is passed as
    // a remaining account. Otherwise its reward fees could wait in the holder vault for good.
    let holder_data =
        || initialize_v1_data(amounts, quote_on(wsol_is_0), REWARD_MODEL_HOLDER, 5_000);
    assert_eq!(
        try_at_pda(&mut env, holder_data()).unwrap_err(),
        V1_ERR_HOLDER_NEEDS_DISTRIBUTOR
    );
    let rewards_admin = setup_deep_rewards(&mut env);
    let dist = init_distributor(&mut env, &rewards_admin, &t.mint, &NATIVE_MINT);
    assert_eq!(
        try_at_pda(&mut env, holder_data()).unwrap_err(),
        V1_ERR_HOLDER_NEEDS_DISTRIBUTOR,
        "the distributor exists but was not passed"
    );
    let mut ix = build(amm_config_1(), k1.pool_state, holder_data());
    ix.accounts
        .push(anchor_lang::prelude::AccountMeta::new_readonly(dist, false));
    env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user])
        .expect("initialize_v1, Holder");
    // a Creator pool at the 5% ceiling, at an address of the creator's choosing (it signs)
    let pool_kp = Keypair::new();
    let k_creator = keys_at(pool_kp.pubkey(), &t.mint);
    let mut ix = build(
        amm_config_1(),
        pool_kp.pubkey(),
        initialize_v1_data(amounts, quote_on(wsol_is_0), REWARD_MODEL_CREATOR, 50_000),
    );
    for m in ix.accounts.iter_mut() {
        if m.pubkey == pool_kp.pubkey() {
            m.is_signer = true;
        }
    }
    env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user, &pool_kp])
        .expect("initialize_v1, Creator");
    env.set_unix_time(1_800_000_010);

    for (kk, model, rate, recipient) in [
        (&k1, REWARD_MODEL_HOLDER, 5_000u64, holder_vault(&t.mint)),
        (&k_creator, REWARD_MODEL_CREATOR, 50_000, up),
    ] {
        let raw = read_v1_pool(&env, &kk.pool_state);
        assert_eq!(
            (raw.fee_model, raw.reward_model, raw.reward_rate),
            (1, model, rate)
        );
        assert_eq!(raw.pool_creator, recipient);
        assert_eq!(raw.creator_fee_on, if wsol_is_0 { 1 } else { 2 });
        assert!(raw.enable_creator_fee);
        assert_eq!(v1_live_rates(&env, kk, true), (1_000, 2_500, rate));
        assert_eq!(v1_live_rates(&env, kk, false), (1_000, 6_500, rate));
        let mut reward_total = 0;
        for (base_output, is_buy, amount) in [
            (false, true, SOL / 4),
            (false, false, 1_000 * UNIT),
            (true, true, 500 * UNIT),
            (true, false, SOL / 100),
        ] {
            let (e, _) = checked_v1_swap(&mut env, &user, &t, kk, base_output, is_buy, amount);
            reward_total += e.reward;
        }
        assert!(reward_total > 0);
        let pool = live_pool(&env, kk);
        let before = env.token_balance(&recipient, &NATIVE_MINT);
        let ix = v1_collect_reward_ix(&up, &recipient, kk, &pool, amm_config_1());
        env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&user])
            .expect("collect the reward");
        assert_eq!(
            env.token_balance(&recipient, &NATIVE_MINT) - before,
            reward_total
        );
    }

    // The admin's current maximum for NEW pools: lowered to 1%, a pool at 1.0001% is refused,
    // one at 1% opens, and the pools that exist keep their 5% and 0.5%. It can never be set
    // above the 5% ceiling.
    assert_eq!(amm_cfg(&env, &amm_config_1()).max_reward_rate, 50_000);
    assert_eq!(
        set_v1_param(&mut env, V1_PARAM_MAX_REWARD, 50_001).unwrap_err(),
        V1_ERR_INVALID_REWARD_RATE
    );
    set_v1_param(&mut env, V1_PARAM_MAX_REWARD, 10_000).unwrap();
    let third = Keypair::new();
    let open = |env: &mut Env, rate: u64| {
        let mut ix = build(
            amm_config_1(),
            third.pubkey(),
            initialize_v1_data(amounts, quote_on(wsol_is_0), REWARD_MODEL_CREATOR, rate),
        );
        for m in ix.accounts.iter_mut() {
            if m.pubkey == third.pubkey() {
                m.is_signer = true;
            }
        }
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&user, &third])
    };
    assert_eq!(open(&mut env, 10_001).unwrap_err(), V1_ERR_REWARD_ABOVE_MAX);
    assert_eq!(open(&mut env, 50_000).unwrap_err(), V1_ERR_REWARD_ABOVE_MAX);
    open(&mut env, 10_000).expect("a pool at the current maximum");
    assert_eq!(read_v1_pool(&env, &third.pubkey()).reward_rate, 10_000);
    assert_eq!(
        read_v1_pool(&env, &k_creator.pool_state).reward_rate,
        50_000
    );
    assert_eq!(read_v1_pool(&env, &k1.pool_state).reward_rate, 5_000);
    env.set_unix_time(1_800_000_020);
    checked_v1_swap(&mut env, &user, &t, &k_creator, false, true, SOL / 10);
}

const TOKEN_2022: Pubkey = anchor_spl::token_2022::ID;

fn raw_mint(env: &mut Env, mint: Pubkey, program: Pubkey, decimals: u8, supply: u64) {
    let mut d = vec![0u8; 82];
    d[36..44].copy_from_slice(&supply.to_le_bytes());
    d[44] = decimals;
    d[45] = 1; // is_initialized; no mint authority, no freeze authority
    let lamports = env.svm.minimum_balance_for_rent_exemption(82);
    env.svm
        .set_account(
            mint,
            solana_account::Account {
                lamports,
                data: d,
                owner: program,
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();
}

/// Writes `owner`'s associated token account for `mint` with `amount`; returns its address.
fn raw_token_account(
    env: &mut Env,
    owner: &Pubkey,
    mint: &Pubkey,
    program: &Pubkey,
    amount: u64,
) -> Pubkey {
    let addr = anchor_spl::associated_token::get_associated_token_address_with_program_id(
        owner, mint, program,
    );
    let mut d = vec![0u8; 165];
    d[..32].copy_from_slice(mint.as_ref());
    d[32..64].copy_from_slice(owner.as_ref());
    d[64..72].copy_from_slice(&amount.to_le_bytes());
    d[108] = 1; // AccountState::Initialized
    let lamports = env.svm.minimum_balance_for_rent_exemption(165);
    env.svm
        .set_account(
            addr,
            solana_account::Account {
                lamports,
                data: d,
                owner: *program,
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();
    addr
}

fn token_amount_at(env: &Env, account: &Pubkey) -> u64 {
    let d = env.svm.get_account(account).unwrap().data;
    u64::from_le_bytes(d[64..72].try_into().unwrap())
}

/// A stock-style pair with no SOL in it: a Token-2022 token quoted in an SPL stablecoin
/// (6 decimals each; synthetic mints written into the VM). The pool's creator names the
/// stablecoin as the quote and takes Creator Rewards: DEEP's part and the reward accrue in the
/// stablecoin on both directions and drain exactly. Holder Rewards are refused on such a pair
/// by the permissionless instruction.
#[test]
fn a_token_2022_pair_quoted_in_a_stablecoin_takes_creator_rewards_in_the_quote_token() {
    let mut env = env_v1();
    env.set_unix_time(1_800_000_000);
    let (a, b) = (Keypair::new().pubkey(), Keypair::new().pubkey());
    let (m0, m1) = if a < b { (a, b) } else { (b, a) };
    // token 0 is the stock, token 1 the stablecoin; the creator names the quote explicitly
    let (stock, usdc) = (m0, m1);
    let spl = anchor_spl::token::ID;
    raw_mint(&mut env, stock, TOKEN_2022, 6, 2_000_000 * UNIT);
    raw_mint(&mut env, usdc, spl, 6, 2_000_000 * UNIT);
    let lp = env.user(10 * SOL);
    let trader = env.user(10 * SOL);
    for who in [lp.pubkey(), trader.pubkey()] {
        raw_token_account(&mut env, &who, &stock, &TOKEN_2022, 1_000_000 * UNIT);
        raw_token_account(&mut env, &who, &usdc, &spl, 1_000_000 * UNIT);
    }
    let pda = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let pool_state = pda(&[b"pool", amm_config_1().as_ref(), m0.as_ref(), m1.as_ref()]);
    let vault = |m: &Pubkey| pda(&[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()]);
    let (stock_vault, usdc_vault) = (vault(&stock), vault(&usdc));
    let amounts = (100_000 * UNIT, 500_000 * UNIT); // 100k stock, 500k usdc
    let init = |model: u8, rate: u64| {
        vec![
            cu_limit_ix(GRADUATE_CU_LIMIT),
            initialize_ix(
                &lp.pubkey(),
                amm_config_1(),
                pool_state,
                (stock, TOKEN_2022, stock_vault),
                (usdc, spl, usdc_vault),
                initialize_v1_data(amounts, quote_on(false), model, rate),
            ),
        ]
    };
    // Holder Rewards need a SOL quote on the permissionless path
    assert_eq!(
        env.send_ixs(init(REWARD_MODEL_HOLDER, 30_000), &[&lp])
            .unwrap_err(),
        V1_ERR_HOLDER_NEEDS_SOL_QUOTE
    );
    env.send_ixs(init(REWARD_MODEL_CREATOR, 30_000), &[&lp])
        .expect("initialize_v1 on a Token-2022 / stablecoin pair");
    env.set_unix_time(1_800_000_010);
    let raw = read_v1_pool(&env, &pool_state);
    assert_eq!(
        (raw.fee_model, raw.reward_model, raw.reward_rate),
        (1, 1, 30_000)
    );
    assert_eq!(raw.pool_creator, lp.pubkey());
    assert_eq!(
        raw.creator_fee_on, 2,
        "the quote is token 1, the stablecoin"
    );

    let tp = trader.pubkey();
    let ata = anchor_spl::associated_token::get_associated_token_address_with_program_id;
    let (t_stock, t_usdc) = (ata(&tp, &stock, &TOKEN_2022), ata(&tp, &usdc, &spl));
    let observation = pda(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]);
    let swap = |is_buy: bool, amount_in: u64, min_out: u64| {
        let (in_acc, out_acc, in_vault, out_vault, in_prog, out_prog, in_mint, out_mint) = if is_buy
        {
            (
                t_usdc,
                t_stock,
                usdc_vault,
                stock_vault,
                spl,
                TOKEN_2022,
                usdc,
                stock,
            )
        } else {
            (
                t_stock,
                t_usdc,
                stock_vault,
                usdc_vault,
                TOKEN_2022,
                spl,
                stock,
                usdc,
            )
        };
        Instruction {
            program_id: deep_amm::ID,
            accounts: deep_amm::accounts::Swap {
                payer: tp,
                authority: pda(&[raydium::AUTH_SEED]),
                amm_config: amm_config_1(),
                pool_state,
                input_token_account: in_acc,
                output_token_account: out_acc,
                input_vault: in_vault,
                output_vault: out_vault,
                input_token_program: in_prog,
                output_token_program: out_prog,
                input_token_mint: in_mint,
                output_token_mint: out_mint,
                observation_state: observation,
            }
            .to_account_metas(None),
            data: deep_amm::instruction::SwapBaseInput {
                amount_in,
                minimum_amount_out: min_out,
            }
            .data(),
        }
    };
    // [protocol_0, protocol_1, fund_0, fund_1, creator_0, creator_1]; the quote is token 1
    let (mut deep_total, mut reward_total) = (0u64, 0u64);
    let (mut r_stock, mut r_usdc) = amounts;
    for (is_buy, amount) in [
        (true, 12_345 * UNIT + 67),
        (false, 2_000 * UNIT + 1),
        (true, 999_999),
        (false, 31),
    ] {
        let (rates_l, rates_d) = if is_buy {
            (1_000, 2_500)
        } else {
            (1_000, 6_500)
        };
        let (ri, ro) = if is_buy {
            (r_usdc, r_stock)
        } else {
            (r_stock, r_usdc)
        };
        let e = v1_expect(false, is_buy, amount, ri, ro, (rates_l, rates_d, 30_000));
        let (s0, u0) = (
            token_amount_at(&env, &t_stock),
            token_amount_at(&env, &t_usdc),
        );
        let meta = env
            .send(swap(is_buy, amount, e.amount_out), &[&trader])
            .expect("swap at the exact quote");
        let (s1, u1) = (
            token_amount_at(&env, &t_stock),
            token_amount_at(&env, &t_usdc),
        );
        if is_buy {
            assert_eq!((u0 - u1, s1 - s0), (e.amount_in, e.amount_out));
            r_usdc += e.amount_in - e.deep - e.reward;
            r_stock -= e.amount_out;
        } else {
            assert_eq!((s0 - s1, u1 - u0), (e.amount_in, e.amount_out));
            r_stock += e.amount_in;
            r_usdc -= e.amount_out + e.deep + e.reward;
        }
        deep_total += e.deep;
        reward_total += e.reward;
        let fees = pool_fee_parts(&env, &pool_state);
        assert_eq!(
            fees,
            [0, deep_total, 0, 0, 0, reward_total],
            "all in the quote"
        );
        assert_eq!(token_amount_at(&env, &stock_vault), r_stock);
        assert_eq!(
            token_amount_at(&env, &usdc_vault),
            r_usdc + deep_total + reward_total
        );
        let f: Vec<deep_amm::states::SwapFeesV1> = events_of(&meta);
        assert_eq!((f[0].is_buy, f[0].quote_mint), (is_buy, usdc));
        assert_eq!(
            (f[0].lp_fee, f[0].protocol_fee, f[0].reward_fee),
            (e.lp, e.deep, e.reward)
        );
    }
    assert!(deep_total > 0 && reward_total > 0);

    // the reward: to the pool creator's stablecoin account, in full
    let lp_usdc = ata(&lp.pubkey(), &usdc, &spl);
    let before = token_amount_at(&env, &lp_usdc);
    let share = Pubkey::find_program_address(
        &[
            b"creator_fee_share",
            lp.pubkey().as_ref(),
            amm_config_1().as_ref(),
        ],
        &deep_amm::ID,
    )
    .0;
    let collect_reward = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectCreatorFeePermissionless {
            payer: tp,
            creator: lp.pubkey(),
            authority: pda(&[raydium::AUTH_SEED]),
            pool_state,
            token_0_vault: stock_vault,
            token_1_vault: usdc_vault,
            vault_0_mint: stock,
            vault_1_mint: usdc,
            creator_token_0: ata(&lp.pubkey(), &stock, &TOKEN_2022),
            creator_token_1: lp_usdc,
            token_0_program: TOKEN_2022,
            token_1_program: spl,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
            amm_config: amm_config_1(),
            creator_fee_share: share,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectCreatorFeePermissionless {}.data(),
    };
    env.send_ixs(vec![cu_limit_ix(400_000), collect_reward], &[&trader])
        .expect("collect the reward");
    assert_eq!(token_amount_at(&env, &lp_usdc) - before, reward_total);

    // DEEP's part: to the fee vault's stablecoin account, exactly
    let vault_usdc = raw_token_account(&mut env, &fee_vault_pda(), &usdc, &spl, 0);
    let collect = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CollectProtocolFeeToVault {
            authority: pda(&[raydium::AUTH_SEED]),
            pool_state,
            amm_config: amm_config_1(),
            token_0_vault: stock_vault,
            token_1_vault: usdc_vault,
            vault_0_mint: stock,
            vault_1_mint: usdc,
            recipient_token_0_account: ata(&fee_vault_pda(), &stock, &TOKEN_2022),
            recipient_token_1_account: vault_usdc,
            token_program: spl,
            token_program_2022: TOKEN_2022,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CollectProtocolFeeToVault {}.data(),
    };
    env.send(collect, &[&trader])
        .expect("collect to the fee vault");
    assert_eq!(token_amount_at(&env, &vault_usdc), deep_total);
    assert_eq!(pool_fee_parts(&env, &pool_state), [0u64; 6]);
    assert_eq!(token_amount_at(&env, &usdc_vault), r_usdc);
    assert_eq!(token_amount_at(&env, &stock_vault), r_stock);
}

/// Eighth round. The admin's current maximum reward rate applies to NEW launches and NEW
/// pools only: a creator cannot launch above it, a live curve keeps the rate it launched
/// with, and `graduate` carries that rate into the pool without looking at any current
/// maximum, so lowering the maximum can never block a graduation.
#[test]
fn lowering_the_maximum_reward_rate_never_touches_live_tokens_nor_blocks_their_graduation() {
    let mut env = env_v1();
    env.set_unix_time(1_800_000_000);
    // launched at the 500 bps ceiling while the maximum is 500
    let t = env.create_token_reward(REWARD_MODEL_HOLDER, 500);
    let t_creator = env.create_token_reward(REWARD_MODEL_CREATOR, 500);

    // the admin lowers the maximum for launches to 100 bps (through the config timelock)
    // and the maximum for new DeepSwap pools to 100 bps as well
    let mut p = v1_params(&env, 125, 125, 0, 0);
    p.raydium_amm_config = amm_config_1();
    p.max_reward_bps = 100;
    env.update_config_now(p).unwrap();
    set_v1_param(&mut env, V1_PARAM_MAX_REWARD, 100 * 100).unwrap();
    assert_eq!(env.load::<Config>(&config_pda()).max_reward_bps, 100);

    // new launches: at most 100 now (maximum + 1 is refused, the ceiling too)
    for bps in [101u16, 250, 500] {
        assert_eq!(
            env.try_create_token_reward(REWARD_MODEL_CREATOR, bps)
                .err()
                .unwrap(),
            custom(DeepError::RewardRateAboveMax)
        );
    }
    assert_eq!(
        env.try_create_token_reward(REWARD_MODEL_CREATOR, 501)
            .err()
            .unwrap(),
        custom(DeepError::InvalidRewardRate)
    );
    let t_new = env.create_token_reward(REWARD_MODEL_CREATOR, 100);
    assert_eq!(env.curve(&t_new).fees_v1().reward_bps, 100);
    env.create_token_reward(REWARD_MODEL_HOLDER, 1);
    env.create_token_reward(REWARD_MODEL_STANDARD, 0);

    // the live 500 bps tokens are untouched: they trade at 1.25% + 5%, complete, and
    // graduate into pools that charge 5%
    for (tok, model) in [
        (&t, REWARD_MODEL_HOLDER),
        (&t_creator, REWARD_MODEL_CREATOR),
    ] {
        assert_eq!(env.curve(tok).fees_v1().reward_bps, 500);
        let user = env.user(5 * SOL);
        env.buy(tok, &user, SOL).unwrap();
        let c = env.curve(tok);
        assert_eq!(c.protocol_fees_unclaimed, 12_500_000);
        assert_eq!(
            c.creator_fees_unclaimed + c.holder_fees_unclaimed,
            50_000_000,
            "5% of 1 SOL"
        );
        env.complete_curve(tok);
        let migration = env.migration.insecure_clone();
        env.graduate(tok, &migration)
            .expect("graduation is not subject to the current maximum");
        let k = pool_keys(&tok.mint);
        let raw = read_v1_pool(&env, &k.pool_state);
        assert_eq!((raw.fee_model, raw.reward_model), (1, model));
        assert_eq!(raw.reward_rate, 50_000, "the pool has the curve's 500 bps");
        assert_eq!(v1_live_rates(&env, &k, true), (1_000, 2_500, 50_000));
        assert_eq!(v1_live_rates(&env, &k, false), (1_000, 6_500, 50_000));
        assert_eq!(env.curve_surplus(tok), 0);
    }
    env.set_unix_time(1_800_000_001);
    let k = pool_keys(&t.mint);
    let trader = deepswap_trader(&mut env, &t.mint, 10 * SOL);
    let (e, _) = checked_v1_swap(&mut env, &trader, &t, &k, false, true, 2 * SOL);
    assert_eq!(e.reward, 2 * SOL / 20, "5% of 2 SOL to the holders");
    checked_v1_swap(&mut env, &trader, &t, &k, false, false, 100_000 * UNIT);

    // the total cap per side at launch: DEEP's fee + the reward rate <= 10%
    let mut p = v1_params(&env, 600, 125, 0, 0);
    p.raydium_amm_config = amm_config_1();
    env.update_config_now(p).unwrap(); // the maximum is back at 500
    assert_eq!(
        env.try_create_token_reward(REWARD_MODEL_CREATOR, 401)
            .err()
            .unwrap(),
        custom(DeepError::InvalidFee),
        "6% + 4.01% on the buy side"
    );
    let t_cap = env.create_token_reward(REWARD_MODEL_CREATOR, 400);
    let user = env.user(5 * SOL);
    env.buy(&t_cap, &user, SOL).unwrap();
    let c = env.curve(&t_cap);
    assert_eq!(
        (c.protocol_fees_unclaimed, c.creator_fees_unclaimed),
        (60_000_000, 40_000_000),
        "exactly 10% of 1 SOL"
    );
}

// ───────────── Security review before mainnet (2026-10-07) ─────────────
//
// "No funds can ever be stuck, no backdoors": one test (or more) per finding, each showing that
// the old failure is gone and that the changed exit drains exactly.

/// deep-amm ErrorCode::CreatePoolFeeAboveCap / GraduationPermissionLocked / InvalidPoolStatus /
/// HolderRewardsNeedDistributor.
const CPMM_ERR_CREATE_POOL_FEE_ABOVE_CAP: u32 = 6026;
const CPMM_ERR_GRADUATION_PERMISSION_LOCKED: u32 = 6027;
const CPMM_ERR_INVALID_POOL_STATUS: u32 = 6028;
const V1_ERR_HOLDER_NEEDS_DISTRIBUTOR: u32 = 6029;
/// PoolState.status (states/pool.rs: 8 + 10 pubkeys + auth_bump).
const POOL_STATUS_OFFSET: usize = 329;
/// AmmConfig.create_pool_fee and .disable_create_pool.
const CFG_CREATE_POOL_FEE: usize = 36;
const CFG_DISABLE_CREATE_POOL: usize = 9;

fn rewards_distributor(mint: &Pubkey, reward_mint: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(
        &[
            deep_rewards::DISTRIBUTOR_SEED,
            mint.as_ref(),
            reward_mint.as_ref(),
        ],
        &deep_rewards::ID,
    )
    .0
}

fn rewards_config_pda() -> Pubkey {
    Pubkey::find_program_address(&[deep_rewards::REWARDS_CONFIG_SEED], &deep_rewards::ID).0
}

/// Loads deep_rewards.so into the VM and initializes its RewardsConfig; returns its admin.
fn setup_deep_rewards(env: &mut Env) -> Keypair {
    let admin = env.user(10 * SOL);
    env.svm
        .add_program_from_file(deep_rewards::ID, so_path("DEEP_REWARDS_SO"))
        .expect("load deep_rewards.so");
    let pd = Pubkey::find_program_address(&[deep_rewards::ID.as_ref()], &BPF_LOADER_UPGRADEABLE).0;
    let mut acc = env.svm.get_account(&pd).expect("deep-rewards programdata");
    acc.data[12] = 1;
    acc.data[13..45].copy_from_slice(admin.pubkey().as_ref());
    env.svm.set_account(pd, acc).unwrap();
    let ix = Instruction {
        program_id: deep_rewards::ID,
        accounts: deep_rewards::accounts::Initialize {
            admin: admin.pubkey(),
            config: rewards_config_pda(),
            pending_config: Pubkey::find_program_address(
                &[deep_rewards::PENDING_CONFIG_SEED],
                &deep_rewards::ID,
            )
            .0,
            program: deep_rewards::ID,
            program_data: pd,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_rewards::instruction::Initialize {
            params: deep_rewards::RewardsConfigParams {
                root_authority: Keypair::new().pubkey(),
                payout_mode: deep_rewards::PAYOUT_MODE_CLAIM,
                root_delay_seconds: deep_rewards::MIN_ROOT_DELAY_SECONDS,
                max_proof_len: 24,
                push_min_usd_micros: deep_rewards::DEFAULT_PUSH_MIN_USD_MICROS,
                min_holding_usd_micros: deep_rewards::DEFAULT_MIN_HOLDING_USD_MICROS,
                max_price_age_seconds: 120,
                sol_usd_price_update: deep_curve::pyth::SOL_USD_PRICE_UPDATE,
                stable_mints: vec![],
                stray_recipient: fee_vault_pda(),
                guardian: admin.pubkey(),
            },
        }
        .data(),
    };
    env.send(ix, &[&admin]).expect("deep-rewards initialize");
    admin
}

/// deep-rewards `init_distributor(mint, reward_mint)` by `authority`; returns the distributor.
fn init_distributor(
    env: &mut Env,
    authority: &Keypair,
    mint: &Pubkey,
    reward_mint: &Pubkey,
) -> Pubkey {
    let hv = holder_vault(mint);
    let dist = rewards_distributor(mint, reward_mint);
    let ix = Instruction {
        program_id: deep_rewards::ID,
        accounts: deep_rewards::accounts::InitDistributor {
            authority: authority.pubkey(),
            config: rewards_config_pda(),
            mint: *mint,
            reward_mint: *reward_mint,
            holder_vault: hv,
            distributor: dist,
            vault_token_account: get_associated_token_address(&hv, reward_mint),
            reward_token_program: anchor_spl::token::ID,
            associated_token_program: anchor_spl::associated_token::ID,
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_rewards::instruction::InitDistributor {}.data(),
    };
    env.send_ixs(vec![cu_limit_ix(400_000), ix], &[authority])
        .expect("init_distributor");
    dist
}

fn pool_status_ix(pool_state: Pubkey, status: u8) -> Instruction {
    Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::UpdatePoolStatus {
            authority: deep_amm::admin::ID,
            pool_state,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::UpdatePoolStatus { status }.data(),
    }
}

/// Wraps `lamports` into the WSOL account `to` (it must exist), paid by `from`.
fn wrap_into(env: &mut Env, from: &Keypair, to: &Pubkey, lamports: u64) {
    let ixs = vec![
        anchor_lang::solana_program::system_instruction::transfer(&from.pubkey(), to, lamports),
        anchor_spl::token::spl_token::instruction::sync_native(&anchor_spl::token::ID, to).unwrap(),
    ];
    env.send_ixs(ixs, &[from]).expect("wrap");
}

/// The constants deep-amm compiles in for the graduation path are deep-curve's own.
#[test]
fn deep_amm_knows_the_graduation_payer() {
    assert_eq!(
        deep_amm::deep_keys::GRADUATION_PAYER,
        Pubkey::find_program_address(&[POOL_CREATOR_SEED], &deep_curve::ID).0
    );
    assert_eq!(
        deep_amm::deep_keys::GRADUATION_PAYER,
        pool_keys(&NATIVE_MINT).pool_creator
    );
    assert_eq!(
        deep_amm::deep_keys::MAX_CREATE_POOL_FEE,
        AMM_CREATE_POOL_FEE
    );
    assert_eq!(
        deep_amm::deep_keys::DISTRIBUTOR_SEED,
        deep_rewards::DISTRIBUTOR_SEED
    );
    assert_eq!(
        deep_amm::deep_keys::DEEP_REWARDS_PROGRAM_ID,
        deep_rewards::ID
    );
    let (a, b) = (Keypair::new().pubkey(), Keypair::new().pubkey());
    assert_eq!(
        deep_amm::deep_keys::distributor_address(&a, &b),
        rewards_distributor(&a, &b)
    );
}

/// F2 (a): anyone graduates a completed curve. The sender pays the network fee and nothing
/// else, receives nothing, and everything that is not the pool's goes to the fee vault: the
/// migration fee minus the pool costs, the rent of temporary accounts somebody else created,
/// WSOL donated to the temporary WSOL account and SOL sent to the pool payer. Reconciled to
/// the lamport.
#[test]
fn graduate_is_permissionless_and_every_leftover_goes_to_the_fee_vault() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let k = pool_keys(&t.mint);

    // A donor creates both temporary accounts, wraps 0.7 SOL into the WSOL one and sends
    // 0.3 SOL to the pool payer PDA.
    let donor = env.user(10 * SOL);
    let d = donor.pubkey();
    let (donated_wsol, donated_sol) = (700_000_000u64, 300_000_000u64);
    env.send_ixs(
        vec![
            create_ata_ix(&d, &k.pool_creator, &NATIVE_MINT),
            create_ata_ix(&d, &k.pool_creator, &t.mint),
            anchor_lang::solana_program::system_instruction::transfer(
                &d,
                &k.pool_creator,
                donated_sol,
            ),
        ],
        &[&donor],
    )
    .expect("donor setup");
    wrap_into(&mut env, &donor, &k.creator_wsol, donated_wsol);
    let ata_rent = env.svm.minimum_balance_for_rent_exemption(165);

    let before = env.curve(&t);
    let alloc = math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
    let v0 = vault_revenue(&env);
    let fee0 = env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER);
    let migration0 = env.lamports(&env.migration.pubkey());
    let creator0 = env.lamports(&env.creator.pubkey());
    let stranger = env.user(SOL);
    let s0 = env.lamports(&stranger.pubkey());
    let ix = env.ix_graduate(&t, &stranger.pubkey());
    assert!(
        ix.accounts.iter().all(|a| !a.is_signer),
        "graduate has no signer account"
    );
    assert_eq!(ix.accounts.len(), 24);
    env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix], &[&stranger])
        .expect("anyone can graduate");

    assert_eq!(
        s0 - env.lamports(&stranger.pubkey()),
        5_000,
        "the sender pays the network fee and nothing else, and receives nothing"
    );
    assert_eq!(env.lamports(&env.migration.pubkey()), migration0);
    assert_eq!(env.lamports(&env.creator.pubkey()), creator0);

    // the pool got exactly the allocation; the temporary accounts are gone, the payer is empty
    let tv: TokenAccount = env.load(&k.token_vault);
    let wv: TokenAccount = env.load(&k.wsol_vault);
    assert_eq!((tv.amount, wv.amount), (alloc.lp_tokens, alloc.lp_sol));
    assert!(env.svm.get_account(&k.creator_token).is_none());
    assert!(env.svm.get_account(&k.creator_wsol).is_none());
    assert!(env.svm.get_account(&k.creator_lp).is_none());
    assert_eq!(env.lamports(&k.pool_creator), 0);
    assert_eq!(env.load::<Mint>(&k.lp_mint).supply, 0, "LP burned");

    let rent = |key: &Pubkey| {
        let len = env.svm.get_account(key).unwrap().data.len();
        env.svm.minimum_balance_for_rent_exemption(len)
    };
    let create_pool_fee = env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER) - fee0;
    assert_eq!(create_pool_fee, AMM_CREATE_POOL_FEE);
    let pool_costs = create_pool_fee
        + rent(&k.pool_state)
        + rent(&k.observation)
        + rent(&k.lp_mint)
        + rent(&k.token_vault)
        + rent(&k.wsol_vault);
    assert_eq!(
        vault_revenue(&env) - v0,
        alloc.migration_fee - pool_costs
            + before.protocol_fees_unclaimed
            + donated_wsol
            + donated_sol
            + 2 * ata_rent,
        "every leftover reached the fee vault, to the lamport"
    );
    assert_eq!(env.curve_surplus(&t), 0);
}

/// F2 (b), (c), (d): nothing the deep-amm admin can do stops a graduation. The graduation
/// payer's Permission cannot be closed (and is not needed), `disable_create_pool` stops other
/// pool creations only, and the create-pool fee is capped both where it is set and where it is
/// charged.
#[test]
fn graduation_cannot_be_blocked_by_the_deep_amm_admin() {
    let mut env = Env::new();
    let (t, _) = env.create_token();
    // a holder with tokens, to try a pool of its own later
    let holder = deepswap_trader(&mut env, &t.mint, 5 * SOL);
    env.buy(&t, &holder, 2 * SOL).unwrap();
    env.complete_curve(&t);
    let k = pool_keys(&t.mint);
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let ap = amm_admin.pubkey();

    // (b) close_permission_pda on the graduation payer: refused, the account stays
    let close = |authority: Pubkey| Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::ClosePermissionPda {
            owner: ap,
            permission_authority: authority,
            permission: permission_pda(&authority),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::ClosePermissionPda {}.data(),
    };
    assert_eq!(
        env.send(close(k.pool_creator), &[&amm_admin]).unwrap_err(),
        CPMM_ERR_GRADUATION_PERMISSION_LOCKED
    );
    assert_eq!(
        env.svm.get_account(&k.permission).unwrap().owner,
        deep_amm::ID
    );
    // any other permission can still be created and closed by the admin
    let other = Keypair::new().pubkey();
    let create = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreatePermissionPda {
            owner: ap,
            permission_authority: other,
            permission: permission_pda(&other),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreatePermissionPda {}.data(),
    };
    env.send(create, &[&amm_admin]).unwrap();
    env.send(close(other), &[&amm_admin])
        .expect("other permissions stay closable");
    assert!(env
        .svm
        .get_account(&permission_pda(&other))
        .is_none_or(|a| a.lamports == 0));

    // (d) the create-pool fee: capped in update_amm_config and in both create instructions
    assert_eq!(
        env.send(
            update_amm_ix(5, AMM_CREATE_POOL_FEE + 1, None),
            &[&amm_admin]
        )
        .unwrap_err(),
        CPMM_ERR_CREATE_POOL_FEE_ABOVE_CAP
    );
    assert_eq!(
        env.send(update_amm_ix(5, u64::MAX, None), &[&amm_admin])
            .unwrap_err(),
        CPMM_ERR_CREATE_POOL_FEE_ABOVE_CAP
    );
    let create_cfg = |index: u16, v1: bool, create_pool_fee: u64| Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreateAmmConfig {
            owner: ap,
            amm_config: amm_config_n(index),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: if v1 {
            deep_amm::instruction::CreateAmmConfigV1 {
                index,
                create_pool_fee,
                buy_lp_fee_rate: V1_RATES[0],
                buy_protocol_fee_rate: V1_RATES[1],
                sell_lp_fee_rate: V1_RATES[2],
                sell_protocol_fee_rate: V1_RATES[3],
            }
            .data()
        } else {
            deep_amm::instruction::CreateAmmConfig {
                index,
                trade_fee_rate: AMM_TRADE_FEE_RATE,
                protocol_fee_rate: AMM_PROTOCOL_FEE_RATE,
                fund_fee_rate: AMM_FUND_FEE_RATE,
                create_pool_fee,
                creator_fee_rate: AMM_CREATOR_FEE_RATE,
            }
            .data()
        },
    };
    for (index, v1) in [(7u16, false), (8, true)] {
        assert_eq!(
            env.send(
                create_cfg(index, v1, AMM_CREATE_POOL_FEE + 1),
                &[&amm_admin]
            )
            .unwrap_err(),
            CPMM_ERR_CREATE_POOL_FEE_ABOVE_CAP,
            "config {index}"
        );
        env.send(create_cfg(index, v1, AMM_CREATE_POOL_FEE), &[&amm_admin])
            .expect("at the cap");
    }
    // A config written BEFORE the cap existed may hold more: the charge is capped all the
    // same. (Patched directly; no instruction can write this value any more.)
    let mut cfg = env.svm.get_account(&amm_config_0()).unwrap();
    cfg.data[CFG_CREATE_POOL_FEE..CFG_CREATE_POOL_FEE + 8]
        .copy_from_slice(&(100 * SOL).to_le_bytes());
    env.svm.set_account(amm_config_0(), cfg).unwrap();
    assert_eq!(amm_cfg_u64(&env, CFG_CREATE_POOL_FEE), 100 * SOL);

    // (c) disable_create_pool: on. It stops a pool anyone opens ...
    set_amm_param(&mut env, 6, 1);
    assert_eq!(
        env.svm.get_account(&amm_config_0()).unwrap().data[CFG_DISABLE_CREATE_POOL],
        1
    );
    let hp = holder.pubkey();
    let (k0, m0, m1) = second_pool_keys(&t.mint, &amm_config_0());
    let tokens = env.token_balance(&hp, &t.mint);
    let amounts = if m0 == NATIVE_MINT {
        (SOL, tokens / 2)
    } else {
        (tokens / 2, SOL)
    };
    let spl = anchor_spl::token::ID;
    let open = initialize_ix(
        &hp,
        amm_config_0(),
        k0.pool_state,
        (m0, spl, vault_of(&k0, &m0)),
        (m1, spl, vault_of(&k0, &m1)),
        deep_amm::instruction::Initialize {
            init_amount_0: amounts.0,
            init_amount_1: amounts.1,
            open_time: 0,
        }
        .data(),
    );
    assert_eq!(
        env.send_ixs(vec![cu_limit_ix(GRADUATE_CU_LIMIT), open], &[&holder])
            .unwrap_err(),
        CPMM_ERR_NOT_APPROVED,
        "disable_create_pool still stops everyone else"
    );

    // ... but not the graduation: no Permission account at all, pool creation disabled, a
    // stored fee of 100 SOL, sent by a stranger. It succeeds and pays exactly the capped fee.
    env.svm
        .set_account(k.permission, solana_account::Account::default())
        .unwrap();
    let before = env.curve(&t);
    let alloc = math::graduation_allocation(&to_math(&before), before.migration_fee_bps).unwrap();
    let fee0 = env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER);
    let stranger = env.user(SOL);
    env.graduate(&t, &stranger)
        .expect("graduation is immune to the deep-amm admin's switches");
    assert!(env.curve(&t).graduated);
    assert_eq!(
        env.lamports(&raydium::CREATE_POOL_FEE_RECEIVER) - fee0,
        deep_amm::deep_keys::MAX_CREATE_POOL_FEE,
        "charged the cap, not the stored 100 SOL"
    );
    let wv: TokenAccount = env.load(&k.wsol_vault);
    assert_eq!(wv.amount, alloc.lp_sol);
    assert_eq!(env.lamports(&k.pool_creator), 0);
}

/// F4 (ii): the admin can stop deposits and swaps, never withdrawals; a pool whose stored
/// status has the withdraw bit set (written before this rule) lets LPs out too; and fee
/// collection works in every status.
#[test]
fn withdrawals_cannot_be_disabled_and_fees_stay_collectable_in_every_pool_status() {
    let mut env = Env::new();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let pool = live_pool(&env, &k);
    let lp_user = deepswap_trader(&mut env, &t.mint, 30 * SOL);
    let lpk = lp_user.pubkey();
    let ix = amm_swap_ix(false, &lpk, &k, &pool, NATIVE_MINT, 15 * SOL, 1);
    env.send(ix, &[&lp_user]).expect("LP buys tokens");
    env.send(create_ata_ix(&lpk, &lpk, &k.lp_mint), &[&lp_user])
        .unwrap();
    let (m0, m1) = (pool.token_0_mint, pool.token_1_mint);
    let pool = live_pool(&env, &k);
    let (v0, v1) = pool_reserves(&env, &pool);
    let l = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    let amt = l / 100;
    let ix = amm_lp_ix(
        true,
        &lpk,
        &k,
        &pool,
        amt,
        lp_to_tokens(amt, l, v0, true),
        lp_to_tokens(amt, l, v1, true),
    );
    env.send(ix, &[&lp_user]).expect("deposit");
    assert_eq!(
        env.load::<TokenAccount>(&get_associated_token_address(&lpk, &k.lp_mint))
            .amount,
        amt
    );

    // the withdraw bit, alone or combined, and unknown bits: refused, status unchanged
    for bad in [2u8, 3, 6, 7, 8, 16, 128, 255] {
        assert_eq!(
            env.send(pool_status_ix(k.pool_state, bad), &[&amm_admin])
                .unwrap_err(),
            CPMM_ERR_INVALID_POOL_STATUS,
            "status {bad}"
        );
    }
    assert_eq!(
        env.svm.get_account(&k.pool_state).unwrap().data[POOL_STATUS_OFFSET],
        0
    );
    // only the admin
    let ix = Instruction {
        accounts: deep_amm::accounts::UpdatePoolStatus {
            authority: lpk,
            pool_state: k.pool_state,
        }
        .to_account_metas(None),
        ..pool_status_ix(k.pool_state, 1)
    };
    assert!(env.send(ix, &[&lp_user]).is_err());

    // deposits and swaps off (1 | 4): both stop
    env.send(pool_status_ix(k.pool_state, 5), &[&amm_admin])
        .expect("disable deposits and swaps");
    let pool = live_pool(&env, &k);
    let ix = amm_swap_ix(false, &lpk, &k, &pool, NATIVE_MINT, SOL, 1);
    assert_eq!(
        env.send(ix, &[&lp_user]).unwrap_err(),
        CPMM_ERR_NOT_APPROVED
    );
    let ix = amm_lp_ix(true, &lpk, &k, &pool, 1_000, u64::MAX, u64::MAX);
    assert_eq!(
        env.send(ix, &[&lp_user]).unwrap_err(),
        CPMM_ERR_NOT_APPROVED
    );

    // ... the LP still gets out, at the exact pro-rata amounts
    let bal = |env: &Env| (env.token_balance(&lpk, &m0), env.token_balance(&lpk, &m1));
    let half = amt / 2;
    let (v0, v1) = pool_reserves(&env, &pool);
    let supply = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    assert_eq!(supply, l + amt);
    let (w0, w1) = (
        lp_to_tokens(half, supply, v0, false),
        lp_to_tokens(half, supply, v1, false),
    );
    let b0 = bal(&env);
    let ix = amm_lp_ix(false, &lpk, &k, &pool, half, w0, w1);
    env.send(ix, &[&lp_user])
        .expect("withdraw while deposits and swaps are disabled");
    let b1 = bal(&env);
    assert_eq!((b1.0 - b0.0, b1.1 - b0.1), (w0, w1));

    // a pool whose stored status carries the withdraw bit (set before the rule): still out
    patch_pool_byte(&mut env, &k.pool_state, POOL_STATUS_OFFSET, 7);
    let pool = live_pool(&env, &k);
    let (v0, v1) = pool_reserves(&env, &pool);
    let supply = pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY);
    let rest = amt - half;
    let (w0, w1) = (
        lp_to_tokens(rest, supply, v0, false),
        lp_to_tokens(rest, supply, v1, false),
    );
    let ix = amm_lp_ix(false, &lpk, &k, &pool, rest, w0, w1);
    env.send(ix, &[&lp_user])
        .expect("withdraw with the legacy withdraw bit set");
    let b2 = bal(&env);
    assert_eq!((b2.0 - b1.0, b2.1 - b1.1), (w0, w1));
    assert_eq!(
        env.load::<TokenAccount>(&get_associated_token_address(&lpk, &k.lp_mint))
            .amount,
        0,
        "the LP is fully out"
    );
    assert_eq!(pool_u64(&env, &k.pool_state, POOL_LP_SUPPLY), l);

    // DEEP's protocol fee is collectable in this status (the token side has no recipient
    // account and is skipped, see the F8 test)
    let parts = pool_fee_parts(&env, &k.pool_state);
    let wsol_is_0 = m0 == NATIVE_MINT;
    let wsol_fee = if wsol_is_0 { parts[0] } else { parts[1] };
    assert!(wsol_fee > 0);
    let token_ata = get_associated_token_address(&fee_vault_pda(), &t.mint);
    let (r0, r1) = if wsol_is_0 {
        (fee_vault_wsol(), token_ata)
    } else {
        (token_ata, fee_vault_wsol())
    };
    let w_before = env.load::<TokenAccount>(&fee_vault_wsol()).amount;
    env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&lp_user])
        .expect("collect protocol fees while the pool is disabled");
    assert_eq!(
        env.load::<TokenAccount>(&fee_vault_wsol()).amount - w_before,
        wsol_fee
    );

    // the admin re-enables everything; a stored withdraw bit can only be cleared, never set
    env.send(pool_status_ix(k.pool_state, 0), &[&amm_admin])
        .expect("status 0");
    let pool = live_pool(&env, &k);
    let ix = amm_swap_ix(false, &lpk, &k, &pool, NATIVE_MINT, SOL, 1);
    env.send(ix, &[&lp_user]).expect("swaps are back");
}

/// F8: `collect_protocol_fee_to_vault` moves each side on its own. A side whose recipient
/// does not exist or is frozen is skipped and stays accrued; it never blocks the other side.
#[test]
fn collect_to_vault_takes_each_side_on_its_own() {
    let mut env = Env::new();
    let (t, k) = graduated_deepswap_pool(&mut env);
    let trader = deepswap_trader(&mut env, &t.mint, 8 * SOL);
    let tp = trader.pubkey();
    let pool = live_pool(&env, &k);
    // a legacy pool takes its fee on the input: buy then sell accrues both sides
    let ix = amm_swap_ix(false, &tp, &k, &pool, NATIVE_MINT, 3 * SOL, 1);
    env.send(ix, &[&trader]).expect("buy");
    let tokens = env.token_balance(&tp, &t.mint);
    let ix = amm_swap_ix(false, &tp, &k, &pool, t.mint, tokens / 2, 1);
    env.send(ix, &[&trader]).expect("sell");

    let wsol_is_0 = pool.token_0_mint == NATIVE_MINT;
    let fees = |env: &Env| {
        let p = pool_fee_parts(env, &k.pool_state);
        if wsol_is_0 {
            (p[0], p[1])
        } else {
            (p[1], p[0])
        }
    }; // (wsol side, token side)
    let (wsol_fee, token_fee) = fees(&env);
    assert!(wsol_fee > 0 && token_fee > 0);
    let token_ata = get_associated_token_address(&fee_vault_pda(), &t.mint);
    let (r0, r1) = if wsol_is_0 {
        (fee_vault_wsol(), token_ata)
    } else {
        (token_ata, fee_vault_wsol())
    };
    let vault_wsol = |env: &Env| env.load::<TokenAccount>(&fee_vault_wsol()).amount;
    let w0 = vault_wsol(&env);

    // 1. the token recipient does not exist: the WSOL side is collected, the token side waits
    assert!(env.svm.get_account(&token_ata).is_none());
    env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&trader])
        .expect("the WSOL side is not blocked by the missing token account");
    assert_eq!(vault_wsol(&env) - w0, wsol_fee);
    assert_eq!(fees(&env), (0, token_fee), "the token side stays accrued");
    // nothing can move now: NoFeeCollect, and nothing changed
    assert_eq!(
        env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&trader])
            .unwrap_err(),
        CPMM_ERR_NO_FEE_COLLECT
    );

    // 2. the token recipient exists but is frozen: still skipped; new WSOL fees still move
    env.send(create_ata_ix(&tp, &fee_vault_pda(), &t.mint), &[&trader])
        .unwrap();
    let mut acc = env.svm.get_account(&token_ata).unwrap();
    assert_eq!(acc.data[108], 1);
    acc.data[108] = 2; // AccountState::Frozen
    env.svm.set_account(token_ata, acc).unwrap();
    let ix = amm_swap_ix(false, &tp, &k, &pool, NATIVE_MINT, SOL, 1);
    env.send(ix, &[&trader]).expect("another buy");
    let (wsol_fee_2, token_fee_2) = fees(&env);
    assert!(wsol_fee_2 > 0);
    assert_eq!(token_fee_2, token_fee);
    let w1 = vault_wsol(&env);
    env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&trader])
        .expect("the WSOL side is not blocked by the frozen token account");
    assert_eq!(vault_wsol(&env) - w1, wsol_fee_2);
    assert_eq!(fees(&env), (0, token_fee));
    assert_eq!(env.load::<TokenAccount>(&token_ata).amount, 0);

    // 3. usable again: the token side drains exactly, nothing is left in the pool
    let mut acc = env.svm.get_account(&token_ata).unwrap();
    acc.data[108] = 1;
    env.svm.set_account(token_ata, acc).unwrap();
    env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&trader])
        .expect("collect the token side");
    assert_eq!(env.load::<TokenAccount>(&token_ata).amount, token_fee);
    assert_eq!(fees(&env), (0, 0));
    assert_eq!(
        env.send(collect_to_vault_ix(&k, &pool, r0, r1), &[&trader])
            .unwrap_err(),
        CPMM_ERR_NO_FEE_COLLECT
    );
    // a wrong recipient address is still an error, never a silent skip
    let ix = amm_swap_ix(false, &tp, &k, &pool, NATIVE_MINT, SOL / 2, 1);
    env.send(ix, &[&trader]).unwrap();
    let wrong = get_associated_token_address(&tp, &NATIVE_MINT);
    let (x0, x1) = if wsol_is_0 {
        (wrong, token_ata)
    } else {
        (token_ata, wrong)
    };
    assert_eq!(
        env.send(collect_to_vault_ix(&k, &pool, x0, x1), &[&trader])
            .unwrap_err(),
        CPMM_ERR_INVALID_PROTOCOL_FEE_RECIPIENT
    );
}

/// F6: `distribute` with the fee vault at exactly its rent minimum and revenue waiting only
/// as WSOL. The sender fronts the temporary account's rent and gets exactly it back.
#[test]
fn distribute_works_with_the_vault_at_its_rent_minimum_and_only_wsol_waiting() {
    let mut env = Env::new();
    let unwrap_pda = Pubkey::find_program_address(&[WSOL_UNWRAP_SEED], &deep_curve::ID).0;
    let tw = env.treasury_wallet.pubkey();
    assert_eq!(
        vault_revenue(&env),
        0,
        "the vault holds its rent minimum only"
    );
    let funder = env.user(10 * SOL);
    wrap_into(&mut env, &funder, &fee_vault_wsol(), 500_000_000);
    assert_eq!(vault_revenue(&env), 0);

    // a sender with 0.01 SOL: enough to front the 0.00203928 SOL rent, which comes back
    let cranker = env.user(10_000_000);
    let c0 = env.lamports(&cranker.pubkey());
    let t0 = env.lamports(&tw);
    let ix = env.ix_distribute_with(cranker.pubkey(), deep_curve::BUILDER_WALLET, &[tw]);
    assert!(ix.accounts[0].is_signer && ix.accounts[0].is_writable);
    let meta = env
        .send_ixs(vec![cu_limit_ix(400_000), ix], &[&cranker])
        .expect("distribute with the vault at its rent minimum");
    println!(
        "distribute CU (vault at rent minimum, WSOL unwrap, 1 destination): {}",
        meta.compute_units_consumed
    );
    assert_eq!(
        c0 - env.lamports(&cranker.pubkey()),
        5_000,
        "the sender paid the network fee only: the fronted rent came back"
    );
    assert_eq!(builder_paid(&env), 50_000_000);
    assert_eq!(env.lamports(&tw) - t0, 450_000_000);
    assert_eq!(
        vault_revenue(&env),
        0,
        "drained exactly, back at the rent minimum"
    );
    assert_eq!(env.load::<TokenAccount>(&fee_vault_wsol()).amount, 0);
    assert_eq!(
        env.lamports(&unwrap_pda),
        0,
        "the temporary account is closed"
    );

    // griefing: someone pre-funds the temporary address. The sender fronts only the shortfall
    // and gets it back; the pre-funded lamports become revenue.
    env.svm
        .set_account(
            unwrap_pda,
            solana_account::Account {
                lamports: 1_000,
                ..Default::default()
            },
        )
        .unwrap();
    wrap_into(&mut env, &funder, &fee_vault_wsol(), 200_000_000);
    let cranker = env.user(10_000_000);
    let c0 = env.lamports(&cranker.pubkey());
    let ix = env.ix_distribute_with(cranker.pubkey(), deep_curve::BUILDER_WALLET, &[tw]);
    env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&cranker])
        .expect("distribute with a pre-funded unwrap address");
    assert_eq!(c0 - env.lamports(&cranker.pubkey()), 5_000);
    let total: u64 = 500_000_000 + 200_000_000 + 1_000;
    assert_eq!(builder_paid(&env), total / 10);
    assert_eq!(env.lamports(&tw) - t0, total - total / 10);
    assert_eq!(vault_revenue(&env), 0);
    assert_eq!(env.lamports(&unwrap_pda), 0);
    let s = env.splitter();
    assert_eq!(s.base_total, total as u128);
    assert_eq!((s.retained, s.builder_owed), (0, 0));
}

/// F7: a builder address owned by another program no longer fails account validation (and
/// with it every distribution). Its share accrues to `builder_owed`, the destinations are paid,
/// and the builder is paid in full once the address is a system account again.
#[test]
fn a_builder_address_owned_by_another_program_is_owed_and_never_blocks_the_others() {
    let mut env = Env::new();
    let b = deep_curve::BUILDER_WALLET;
    let tw = env.treasury_wallet.pubkey();
    let saved = env.svm.get_account(&b).unwrap();
    let mut foreign = saved.clone();
    foreign.owner = anchor_spl::token::ID;
    env.svm.set_account(b, foreign).unwrap();

    env.svm.airdrop(&fee_vault_pda(), 50_000_000).unwrap();
    let t0 = env.lamports(&tw);
    env.distribute()
        .expect("the destinations are paid although the builder cannot be");
    assert_eq!(
        env.lamports(&b),
        saved.lamports,
        "not paid while program-owned"
    );
    assert_eq!(env.lamports(&tw) - t0, 45_000_000);
    let s = env.splitter();
    assert_eq!(s.builder_owed, 5_000_000);
    assert_eq!(
        s.builder_paid_total, 5_000_000,
        "counted once, never re-split"
    );
    assert_eq!(
        vault_revenue(&env),
        5_000_000,
        "the owed share waits in the vault"
    );

    // more revenue while it is still unpayable: the owed amount grows, nobody else loses
    env.svm.airdrop(&fee_vault_pda(), 30_000_000).unwrap();
    env.distribute().expect("second round");
    assert_eq!(env.splitter().builder_owed, 8_000_000);
    assert_eq!(env.lamports(&tw) - t0, 72_000_000);

    // a system account again: paid in full without any new revenue
    env.svm.set_account(b, saved).unwrap();
    env.distribute().expect("pay what is owed");
    assert_eq!(builder_paid(&env), 8_000_000);
    assert_eq!(env.splitter().builder_owed, 0);
    assert_eq!(vault_revenue(&env), 0, "drained exactly");
}

/// F9: the launch fee is charged only up to the creator's limit in lamports.
#[test]
fn create_token_respects_the_creators_launch_fee_limit() {
    let mut env = env_with_launch_fee(200);
    env.set_unix_time(NOW);
    set_price(
        &mut env,
        RECEIVER,
        price_update_data(FEED, true, 12_030_243_981, 1_196_361, -8, NOW - 5),
    );
    let fee = deep_curve::pyth::launch_fee_lamports(200, 12_030_243_981, -8).unwrap();
    assert_eq!(fee, 16_624_767);
    let creator = env.creator.insecure_clone();
    let try_launch = |env: &mut Env, max: u64| {
        let mint = Keypair::new();
        let mut ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Limit");
        let n = ix.data.len();
        ix.data[n - 8..].copy_from_slice(&max.to_le_bytes());
        env.send(ix, &[&creator, &mint]).map(|_| mint.pubkey())
    };
    let c0 = env.lamports(&creator.pubkey());
    for max in [0, 1, fee - 1] {
        assert_eq!(
            try_launch(&mut env, max).unwrap_err(),
            custom(DeepError::LaunchFeeAboveMax),
            "limit {max}"
        );
    }
    assert!(
        c0 - env.lamports(&creator.pubkey()) <= 3 * 2 * 5_000,
        "a refused launch charges nothing but the network fee (two signatures)"
    );
    // the price moves against the creator between quote and landing: refused at the old limit
    set_price(
        &mut env,
        RECEIVER,
        price_update_data(FEED, true, 6_000_000_000, 600_000, -8, NOW - 5),
    );
    let dearer = deep_curve::pyth::launch_fee_lamports(200, 6_000_000_000, -8).unwrap();
    assert!(dearer > 2 * fee - 1_000);
    assert_eq!(
        try_launch(&mut env, fee).unwrap_err(),
        custom(DeepError::LaunchFeeAboveMax)
    );
    set_price(
        &mut env,
        RECEIVER,
        price_update_data(FEED, true, 12_030_243_981, 1_196_361, -8, NOW - 5),
    );
    // exactly at the limit: charged exactly the fee
    let mint = try_launch(&mut env, fee).expect("launch at the limit");
    let curve: BondingCurve = env.load(&curve_pda(&mint));
    assert_eq!(curve.protocol_fees_unclaimed, fee);

    // no launch fee configured: the limit is not read, 0 is fine
    let mut env = Env::new();
    let creator = env.creator.insecure_clone();
    let mint = Keypair::new();
    let mut ix = env.ix_create_token(&creator.pubkey(), &mint.pubkey(), "Free");
    let n = ix.data.len();
    ix.data[n - 8..].copy_from_slice(&0u64.to_le_bytes());
    env.send(ix, &[&creator, &mint])
        .expect("no launch fee, limit 0");
}

/// F5: a Config under which a completed curve could not graduate is refused when it is
/// queued (and at `initialize_config`, same validation), so no curve is ever launched under one.
#[test]
fn a_config_under_which_no_curve_could_graduate_is_refused() {
    let mut env = Env::new();
    let base = params(env.fee_recipient.pubkey(), env.migration.pubkey());
    // the whole supply on the curve: nothing left for the pool (was accepted before)
    let mut p = base.clone();
    p.curve_supply = p.token_total_supply;
    assert_eq!(
        env.update_config_now(p).unwrap_err(),
        custom(DeepError::InvalidParams)
    );
    // one base unit raised for the whole curve: the migration fee takes all of it
    let mut p = base.clone();
    p.initial_virtual_sol = 1;
    p.curve_supply = UNIT;
    assert_eq!(
        math::validate_graduation_params(
            p.initial_virtual_sol,
            p.initial_virtual_token,
            p.curve_supply,
            p.token_total_supply,
            p.migration_fee_bps
        ),
        Err(math::MathError::InvalidParams)
    );
    assert_eq!(
        env.update_config_now(p).unwrap_err(),
        custom(DeepError::GraduationImpossible)
    );
    // a pool below deep-amm's minimum liquidity
    let mut p = base.clone();
    p.initial_virtual_sol = 1_000;
    p.initial_virtual_token = 1_000 * UNIT;
    p.curve_supply = 500 * UNIT;
    p.token_total_supply = 500 * UNIT + 3;
    assert_eq!(
        env.update_config_now(p).unwrap_err(),
        custom(DeepError::GraduationImpossible)
    );
    // the config in force is unchanged, and the default parameters still validate
    let cfg: Config = env.load(&config_pda());
    assert_eq!(cfg.curve_supply, base.curve_supply);
    env.update_config_now(base).expect("the default parameters");
    // ... and a curve launched under them does graduate
    let (t, _) = env.create_token();
    env.complete_curve(&t);
    let c = env.curve(&t);
    let alloc = math::graduation_allocation(&to_math(&c), c.migration_fee_bps).unwrap();
    assert!(alloc.lp_sol > 0 && alloc.lp_tokens > 0);
    let stranger = env.user(SOL);
    env.graduate(&t, &stranger).expect("graduate");
}

/// F10: an address nobody can ever sign for cannot be made a splitter destination.
#[test]
fn splitter_destinations_that_can_never_sign_are_refused() {
    let mut env = Env::new();
    let admin = env.admin.insecure_clone();
    let good = env.user(SOL).pubkey();
    let never = deep_curve::never_a_destination(&deep_curve::ID);
    let pda = |seed: &[u8]| Pubkey::find_program_address(&[seed], &deep_curve::ID).0;
    for must in [
        Pubkey::default(),
        fee_vault_pda(),
        fee_vault_wsol(),
        splitter_pda(),
        pending_splitter_pda(),
        config_pda(),
        pending_config_pda(),
        pda(WSOL_UNWRAP_SEED),
        treasury_pda(),
        pda(POOL_CREATOR_SEED),
        deep_curve::ID,
        deep_amm::ID,
        deep_rewards::ID,
        anchor_spl::token::ID,
        anchor_spl::token_2022::ID,
        anchor_spl::associated_token::ID,
        NATIVE_MINT,
        anchor_lang::system_program::ID,
    ] {
        assert!(never.contains(&must), "{must} must be refused");
    }
    for bad in never.iter().copied().chain([deep_curve::BUILDER_WALLET]) {
        for dests in [vec![(bad, 10_000)], vec![(good, 4_000), (bad, 6_000)]] {
            let ix = env.ix_queue_splitter(&admin.pubkey(), splitter_params(&dests));
            assert_eq!(
                env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&admin])
                    .unwrap_err(),
                custom(DeepError::InvalidSplitterParams),
                "{bad}"
            );
        }
    }
    // an ordinary wallet is accepted
    let ix = env.ix_queue_splitter(&admin.pubkey(), splitter_params(&[(good, 10_000)]));
    env.send_ixs(vec![cu_limit_ix(400_000), ix], &[&admin])
        .expect("a wallet destination");
}

/// F3: a Holder pool can be opened only when DEEP serves that (token, quote) pair, i.e. when
/// the deep-rewards distributor exists, so its reward fees always have a way out and can never
/// be swept as stray. The one exemption is a graduation (SOL quote, permissioned): it must
/// not depend on a distributor, and does not.
#[test]
fn a_holder_pool_needs_its_distributor_except_when_a_token_graduates() {
    use anchor_lang::prelude::AccountMeta;
    // 1. a Holder token graduates with no distributor and no deep-rewards program in the VM
    let mut env = env_v1();
    let (t, k, _) = v1_graduated(&mut env, REWARD_MODEL_HOLDER);
    assert!(env.svm.get_account(&deep_rewards::ID).is_none());
    assert!(env
        .svm
        .get_account(&rewards_distributor(&t.mint, &NATIVE_MINT))
        .is_none());
    let raw = read_v1_pool(&env, &k.pool_state);
    assert_eq!(raw.reward_model, REWARD_MODEL_HOLDER);
    assert_eq!(raw.pool_creator, holder_vault(&t.mint));

    // 2. the permissioned path with a quote that is not SOL: refused without the distributor
    let amm_admin = load_keypair("AMM_ADMIN_KEYPAIR");
    let lp = env.user(10 * SOL);
    let lpk = lp.pubkey();
    let create_permission = Instruction {
        program_id: deep_amm::ID,
        accounts: deep_amm::accounts::CreatePermissionPda {
            owner: amm_admin.pubkey(),
            permission_authority: lpk,
            permission: permission_pda(&lpk),
            system_program: anchor_lang::system_program::ID,
        }
        .to_account_metas(None),
        data: deep_amm::instruction::CreatePermissionPda {}.data(),
    };
    env.send(create_permission, &[&amm_admin]).unwrap();
    let (a, b) = (Keypair::new().pubkey(), Keypair::new().pubkey());
    let (m0, m1) = if a < b { (a, b) } else { (b, a) };
    let (stock, usdc) = (m0, m1); // the quote is token 1
    let spl = anchor_spl::token::ID;
    raw_mint(&mut env, stock, spl, 6, 2_000_000 * UNIT);
    raw_mint(&mut env, usdc, spl, 6, 2_000_000 * UNIT);
    raw_token_account(&mut env, &lpk, &stock, &spl, 1_000_000 * UNIT);
    raw_token_account(&mut env, &lpk, &usdc, &spl, 1_000_000 * UNIT);
    let amm = |seeds: &[&[u8]]| Pubkey::find_program_address(seeds, &deep_amm::ID).0;
    let pool_state = amm(&[b"pool", amm_config_1().as_ref(), m0.as_ref(), m1.as_ref()]);
    let lp_mint = amm(&[raydium::POOL_LP_MINT_SEED, pool_state.as_ref()]);
    let vault = |m: &Pubkey| amm(&[raydium::POOL_VAULT_SEED, pool_state.as_ref(), m.as_ref()]);
    let build = |model: u8, extra: Option<Pubkey>| {
        let mut ix = Instruction {
            program_id: deep_amm::ID,
            accounts: deep_amm::accounts::InitializeWithPermission {
                payer: lpk,
                creator: holder_vault(&stock),
                amm_config: amm_config_1(),
                authority: amm(&[raydium::AUTH_SEED]),
                pool_state,
                token_0_mint: m0,
                token_1_mint: m1,
                lp_mint,
                payer_token_0: get_associated_token_address(&lpk, &m0),
                payer_token_1: get_associated_token_address(&lpk, &m1),
                payer_lp_token: get_associated_token_address(&lpk, &lp_mint),
                token_0_vault: vault(&m0),
                token_1_vault: vault(&m1),
                create_pool_fee: raydium::CREATE_POOL_FEE_RECEIVER,
                observation_state: amm(&[raydium::OBSERVATION_SEED, pool_state.as_ref()]),
                permission: permission_pda(&lpk),
                token_program: spl,
                token_0_program: spl,
                token_1_program: spl,
                associated_token_program: anchor_spl::associated_token::ID,
                system_program: anchor_lang::system_program::ID,
            }
            .to_account_metas(None),
            data: deep_amm::instruction::InitializeWithPermissionV1 {
                init_amount_0: 100_000 * UNIT,
                init_amount_1: 500_000 * UNIT,
                open_time: 0,
                creator_fee_on: quote_on(false),
                reward_model: model,
                reward_rate: 10_000,
            }
            .data(),
        };
        if let Some(k) = extra {
            ix.accounts.push(AccountMeta::new_readonly(k, false));
        }
        vec![cu_limit_ix(GRADUATE_CU_LIMIT), ix]
    };
    let dist = rewards_distributor(&stock, &usdc);
    for extra in [
        None,
        Some(dist),
        Some(rewards_distributor(&stock, &NATIVE_MINT)),
    ] {
        assert_eq!(
            env.send_ixs(build(REWARD_MODEL_HOLDER, extra), &[&lp])
                .unwrap_err(),
            V1_ERR_HOLDER_NEEDS_DISTRIBUTOR,
            "no distributor yet ({extra:?})"
        );
    }
    // an account at the right address that deep-rewards does not own is not a distributor
    env.svm.airdrop(&dist, SOL).unwrap();
    assert_eq!(
        env.send_ixs(build(REWARD_MODEL_HOLDER, Some(dist)), &[&lp])
            .unwrap_err(),
        V1_ERR_HOLDER_NEEDS_DISTRIBUTOR
    );
    env.svm
        .set_account(dist, solana_account::Account::default())
        .unwrap();

    // DEEP opts in: the distributor exists, the pool can be opened
    let rewards_admin = setup_deep_rewards(&mut env);
    let created = init_distributor(&mut env, &rewards_admin, &stock, &usdc);
    assert_eq!(created, dist);
    assert_eq!(env.svm.get_account(&dist).unwrap().owner, deep_rewards::ID);
    assert_eq!(
        env.send_ixs(build(REWARD_MODEL_HOLDER, None), &[&lp])
            .unwrap_err(),
        V1_ERR_HOLDER_NEEDS_DISTRIBUTOR,
        "it must be passed"
    );
    env.send_ixs(build(REWARD_MODEL_HOLDER, Some(dist)), &[&lp])
        .expect("a Holder pool of a pair DEEP serves");
    let raw = read_v1_pool(&env, &pool_state);
    assert_eq!(raw.reward_model, REWARD_MODEL_HOLDER);
    assert_eq!(raw.pool_creator, holder_vault(&stock));
}
