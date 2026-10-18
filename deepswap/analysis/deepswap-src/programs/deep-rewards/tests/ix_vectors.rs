//! fixtures/rewards-ix-vectors.json (from packages/sdk/scripts/gen-rewards-fixtures.ts) against
//! Anchor's generated `accounts::*` / `instruction::*`: every SDK deep-rewards builder has the
//! exact account order, signer/writable flags and data the program expects.

use anchor_lang::prelude::Pubkey;
use anchor_lang::solana_program::instruction::{AccountMeta, Instruction};
use anchor_lang::{InstructionData, ToAccountMetas};
use anchor_spl::associated_token::get_associated_token_address_with_program_id;
use deep_rewards::{
    accounts, instruction, RewardsConfigParams, CLAIM_SEED, DISTRIBUTOR_SEED, HOLDER_VAULT_SEED,
    NATIVE_MINT, REWARDS_CONFIG_SEED, WSOL_UNWRAP_SEED, PENDING_CONFIG_SEED,
};
use serde_json::Value;
use std::str::FromStr;

const BPF_LOADER_UPGRADEABLE: Pubkey =
    Pubkey::from_str_const("BPFLoaderUpgradeab1e11111111111111111111111");
const TOKEN: Pubkey = anchor_spl::token::ID;
const TOKEN_2022: Pubkey = anchor_spl::token_2022::ID;
const ATA: Pubkey = anchor_spl::associated_token::ID;
const SYSTEM: Pubkey = anchor_lang::system_program::ID;
const PYTH: Pubkey = deep_rewards::pyth::SOL_USD_PRICE_UPDATE;

fn fixtures() -> Value {
    let path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../fixtures/rewards-ix-vectors.json");
    serde_json::from_str(&std::fs::read_to_string(path).expect("read rewards-ix-vectors.json"))
        .expect("json")
}

fn key(f: &Value, name: &str) -> Pubkey {
    Pubkey::from_str(f["keys"][name].as_str().unwrap()).unwrap()
}

fn pda(seeds: &[&[u8]]) -> Pubkey {
    Pubkey::find_program_address(seeds, &deep_rewards::ID).0
}

fn check(f: &Value, name: &str, accounts: Vec<AccountMeta>, data: Vec<u8>) {
    let v = &f["instructions"][name];
    assert!(!v.is_null(), "missing vector {name}");
    let ix = Instruction {
        program_id: deep_rewards::ID,
        accounts,
        data,
    };
    assert_eq!(
        Pubkey::from_str(v["programId"].as_str().unwrap()).unwrap(),
        ix.program_id
    );
    let want: Vec<(Pubkey, bool, bool)> = v["accounts"]
        .as_array()
        .unwrap()
        .iter()
        .map(|a| {
            (
                Pubkey::from_str(a["pubkey"].as_str().unwrap()).unwrap(),
                a["isSigner"].as_bool().unwrap(),
                a["isWritable"].as_bool().unwrap(),
            )
        })
        .collect();
    let got: Vec<(Pubkey, bool, bool)> = ix
        .accounts
        .iter()
        .map(|a| (a.pubkey, a.is_signer, a.is_writable))
        .collect();
    assert_eq!(got, want, "{name}: accounts");
    let hex: String = ix.data.iter().map(|b| format!("{b:02x}")).collect();
    assert_eq!(hex, v["data"].as_str().unwrap(), "{name}: data");
}

#[test]
fn sdk_builders_match_anchor() {
    let f = fixtures();
    assert_eq!(
        Pubkey::from_str(f["programId"].as_str().unwrap()).unwrap(),
        deep_rewards::ID
    );
    let admin = key(&f, "admin");
    let root_authority = key(&f, "rootAuthority");
    let mint = key(&f, "mint");
    let usdc = key(&f, "usdc");
    let claimant = key(&f, "claimant");
    let cranker = key(&f, "cranker");
    let guardian = key(&f, "guardian");
    let new_admin = key(&f, "newAdmin");
    let depositor_token = key(&f, "depositorToken");
    let config = pda(&[REWARDS_CONFIG_SEED]);
    let holder_vault = pda(&[HOLDER_VAULT_SEED, mint.as_ref()]);
    let dist_sol = pda(&[DISTRIBUTOR_SEED, mint.as_ref(), NATIVE_MINT.as_ref()]);
    let dist_tok = pda(&[DISTRIBUTOR_SEED, mint.as_ref(), usdc.as_ref()]);
    let wsol_vault = get_associated_token_address_with_program_id(&holder_vault, &NATIVE_MINT, &TOKEN);
    let tok_vault = get_associated_token_address_with_program_id(&holder_vault, &usdc, &TOKEN_2022);
    let program_data = Pubkey::find_program_address(&[deep_rewards::ID.as_ref()], &BPF_LOADER_UPGRADEABLE).0;
    let proof = vec![[7u8; 32], [8u8; 32]];
    let params = RewardsConfigParams {
        root_authority,
        payout_mode: 1,
        root_delay_seconds: deep_rewards::MIN_ROOT_DELAY_SECONDS,
        max_proof_len: 24,
        push_min_usd_micros: 20_000_000,
        min_holding_usd_micros: 10_000_000,
        max_price_age_seconds: 600,
        sol_usd_price_update: PYTH,
        stable_mints: vec![usdc],
        stray_recipient: admin,
        guardian,
    };
    let pending_config = pda(&[PENDING_CONFIG_SEED]);

    check(
        &f,
        "initialize",
        accounts::Initialize {
            admin,
            config,
            pending_config,
            program: deep_rewards::ID,
            program_data,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::Initialize { params: params.clone() }.data(),
    );
    let admin_only = || accounts::AdminOnly { admin, config }.to_account_metas(None);
    check(
        &f,
        "queue_config_update",
        accounts::QueueConfigUpdate { admin, config, pending_config }.to_account_metas(None),
        instruction::QueueConfigUpdate { params }.data(),
    );
    check(
        &f,
        "apply_config_update",
        accounts::ApplyConfigUpdate { config, pending_config }.to_account_metas(None),
        instruction::ApplyConfigUpdate {}.data(),
    );
    check(
        &f,
        "cancel_config_update",
        accounts::CancelConfigUpdate { admin, config, pending_config }.to_account_metas(None),
        instruction::CancelConfigUpdate {}.data(),
    );
    check(
        &f,
        "recover_stray",
        accounts::RecoverStray {
            cranker,
            config,
            mint,
            holder_vault,
            reward_distributor: pda(&[DISTRIBUTOR_SEED, mint.as_ref(), mint.as_ref()]),
            stray_mint: mint,
            vault_token: get_associated_token_address_with_program_id(&holder_vault, &mint, &TOKEN_2022),
            stray_recipient: admin,
            recipient_token: get_associated_token_address_with_program_id(&admin, &mint, &TOKEN_2022),
            token_program: TOKEN_2022,
            associated_token_program: ATA,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::RecoverStray {}.data(),
    );
    // set_paused: the admin or the guardian, same account shape
    for (name, authority) in [("set_paused", admin), ("set_paused_guardian", guardian)] {
        check(
            &f,
            name,
            accounts::AdminOrGuardian { authority, config }.to_account_metas(None),
            instruction::SetPaused { paused: true }.data(),
        );
    }
    check(
        &f,
        "migrate_config",
        accounts::MigrateConfig {
            payer: cranker,
            config,
            pending_config,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::MigrateConfig {}.data(),
    );
    check(&f, "propose_admin", admin_only(), instruction::ProposeAdmin { new_admin }.data());
    check(
        &f,
        "accept_admin",
        accounts::AcceptAdmin { new_admin, config }.to_account_metas(None),
        instruction::AcceptAdmin {}.data(),
    );
    check(
        &f,
        "init_distributor_sol",
        accounts::InitDistributor {
            authority: root_authority,
            config,
            mint,
            reward_mint: NATIVE_MINT,
            holder_vault,
            distributor: dist_sol,
            vault_token_account: wsol_vault,
            reward_token_program: TOKEN,
            associated_token_program: ATA,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::InitDistributor {}.data(),
    );
    check(
        &f,
        "init_distributor_token",
        accounts::InitDistributor {
            authority: admin,
            config,
            mint,
            reward_mint: usdc,
            holder_vault,
            distributor: dist_tok,
            vault_token_account: tok_vault,
            reward_token_program: TOKEN_2022,
            associated_token_program: ATA,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::InitDistributor {}.data(),
    );
    check(
        &f,
        "deposit_sol",
        accounts::DepositSol {
            depositor: cranker,
            distributor: dist_sol,
            holder_vault,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::DepositSol { amount: 123 }.data(),
    );
    check(
        &f,
        "deposit_token",
        accounts::DepositToken {
            depositor: cranker,
            distributor: dist_tok,
            reward_mint: usdc,
            depositor_token,
            token_vault: tok_vault,
            token_program: TOKEN_2022,
        }
        .to_account_metas(None),
        instruction::DepositToken { amount: 456 }.data(),
    );
    check(
        &f,
        "unwrap_wsol",
        accounts::UnwrapWsol {
            payer: cranker,
            distributor: dist_sol,
            holder_vault,
            wsol_vault,
            wsol_unwrap: pda(&[WSOL_UNWRAP_SEED, dist_sol.as_ref()]),
            wsol_mint: NATIVE_MINT,
            token_program: TOKEN,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::UnwrapWsol {}.data(),
    );
    check(
        &f,
        "propose_root",
        accounts::ProposeRoot {
            root_authority,
            config,
            distributor: dist_sol,
            holder_vault,
            token_vault: wsol_vault,
        }
        .to_account_metas(None),
        instruction::ProposeRoot {
            root: [5; 32],
            max_total_claim: 789,
            snapshot_slot: 1_000,
            data_hash: [6; 32],
        }
        .data(),
    );
    check(
        &f,
        "activate_root",
        accounts::ActivateRoot {
            distributor: dist_tok,
            holder_vault,
            token_vault: tok_vault,
        }
        .to_account_metas(None),
        instruction::ActivateRoot {}.data(),
    );
    for (name, authority) in [("veto_root", admin), ("veto_root_guardian", guardian)] {
        check(
            &f,
            name,
            accounts::VetoRoot {
                authority,
                config,
                distributor: dist_sol,
            }
            .to_account_metas(None),
            instruction::VetoRoot {}.data(),
        );
    }
    check(
        &f,
        "claim_sol",
        accounts::ClaimSol {
            claimant,
            config,
            distributor: dist_sol,
            holder_vault,
            claim_status: pda(&[CLAIM_SEED, dist_sol.as_ref(), claimant.as_ref()]),
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::ClaimSol {
            cumulative_amount: 1_000,
            proof: proof.clone(),
        }
        .data(),
    );
    check(
        &f,
        "claim_token",
        accounts::ClaimToken {
            claimant,
            config,
            distributor: dist_tok,
            holder_vault,
            reward_mint: usdc,
            token_vault: tok_vault,
            claimant_token: get_associated_token_address_with_program_id(&claimant, &usdc, &TOKEN_2022),
            claim_status: pda(&[CLAIM_SEED, dist_tok.as_ref(), claimant.as_ref()]),
            token_program: TOKEN_2022,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::ClaimToken {
            cumulative_amount: 2_000,
            proof: proof.clone(),
        }
        .data(),
    );
    check(
        &f,
        "push_sol",
        accounts::PushSol {
            cranker,
            config,
            distributor: dist_sol,
            holder_vault,
            claimant,
            claim_status: pda(&[CLAIM_SEED, dist_sol.as_ref(), claimant.as_ref()]),
            price_update: PYTH,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::PushSol {
            cumulative_amount: 3_000,
            proof: proof.clone(),
        }
        .data(),
    );
    check(
        &f,
        "push_token",
        accounts::PushToken {
            cranker,
            config,
            distributor: dist_tok,
            holder_vault,
            reward_mint: usdc,
            token_vault: tok_vault,
            claimant,
            claimant_token: get_associated_token_address_with_program_id(&claimant, &usdc, &TOKEN_2022),
            claim_status: pda(&[CLAIM_SEED, dist_tok.as_ref(), claimant.as_ref()]),
            token_program: TOKEN_2022,
            associated_token_program: ATA,
            system_program: SYSTEM,
        }
        .to_account_metas(None),
        instruction::PushToken {
            cumulative_amount: 4_000,
            proof,
        }
        .data(),
    );
    assert_eq!(f["instructions"].as_object().unwrap().len(), 23, "every vector checked");
}
