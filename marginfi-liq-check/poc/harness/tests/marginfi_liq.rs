//! marginfi v2 (C2-37) liquidation-realisability PoC — LiteSVM against cloned mainnet state.
//!
//! Loads the EXACT deployed marginfi program bytecode (dumped from the upgradeable-loader
//! ProgramData account, last upgrade slot 456,093,551) + the real SPL Token program, plus
//! cloned mainnet accounts for each case (banks, oracles, group, liquidatee, vaults).
//!
//! Tests:
//!   T1  v1 top "underwater" account (off-chain model: -$105k): the deployed program's own
//!       pulse + liquidation verdict -> 6068 HealthyAccount (not liquidatable).
//!   T2  program-confirmed liquidatable bad-debt account: pulse says liquidatable
//!       (liq_err=0) but the liquidation fails because there is no collateral to seize.
//!   T3  program-confirmed liquidatable account WITH collateral: liquidation executes;
//!       the emitted event gives the exact seized/repaid amounts (dust).
//!
//! Read-only: LiteSVM is an in-process sandbox; no mainnet transaction is ever sent.

use base64::{engine::general_purpose::STANDARD as B64, Engine};
use litesvm::types::TransactionResult;
use litesvm::LiteSVM;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use solana_account::Account;
use solana_address::Address;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::{Message, VersionedMessage};
use solana_signer::Signer;
use solana_transaction::versioned::VersionedTransaction;
use std::str::FromStr;

const MFI: &str = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA";
const TOKENKEG: &str = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const SNAPSHOT_TS: i64 = 1_792_080_000;

fn addr(s: &str) -> Address {
    Address::from_str(s).unwrap()
}
fn disc(name: &str) -> [u8; 8] {
    let mut h = Sha256::new();
    h.update(name.as_bytes());
    h.finalize()[..8].try_into().unwrap()
}
fn ro(pk: Address) -> AccountMeta {
    AccountMeta { pubkey: pk, is_signer: false, is_writable: false }
}
fn wr(pk: Address) -> AccountMeta {
    AccountMeta { pubkey: pk, is_signer: false, is_writable: true }
}
fn sgn(pk: Address) -> AccountMeta {
    AccountMeta { pubkey: pk, is_signer: true, is_writable: false }
}

fn i80(raw: &[u8], off: usize) -> f64 {
    let mut b = [0u8; 16];
    b.copy_from_slice(&raw[off..off + 16]);
    i128::from_le_bytes(b) as f64 / (1u64 << 48) as f64
}
fn i80_bytes(x: f64) -> [u8; 16] {
    ((x * (1u64 << 48) as f64) as i128).to_le_bytes()
}

fn f64_at(raw: &[u8], off: usize) -> f64 {
    f64::from_le_bytes(raw[off..off + 8].try_into().unwrap())
}

/// Active balance bank pubkeys of a MarginfiAccount, in raw array order.
fn account_banks(raw: &[u8]) -> Vec<Address> {
    let mut out = Vec::new();
    for i in 0..16 {
        let o = 72 + i * 104;
        if o + 104 > raw.len() {
            break;
        }
        if raw[o] != 0 {
            out.push(Address::new_from_array(raw[o + 1..o + 33].try_into().unwrap()));
        }
    }
    out
}

fn health_cache(raw: &[u8]) -> Value {
    let hc = &raw[1840..2144];
    json!({
        "asset_value_init": i80(hc, 0), "liability_value_init": i80(hc, 16),
        "asset_value_maint": i80(hc, 32), "liability_value_maint": i80(hc, 48),
        "asset_value_equity": i80(hc, 64), "liability_value_equity": i80(hc, 80),
        "timestamp": i64::from_le_bytes(hc[96..104].try_into().unwrap()),
        "flags": u32::from_le_bytes(hc[104..108].try_into().unwrap()),
        "mrgn_err": u32::from_le_bytes(hc[108..112].try_into().unwrap()),
        "internal_err": u32::from_le_bytes(hc[240..244].try_into().unwrap()),
        "internal_liq_err": u32::from_le_bytes(hc[248..252].try_into().unwrap()),
        "internal_bankruptcy_err": u32::from_le_bytes(hc[252..256].try_into().unwrap()),
        "health_maint": i80(hc, 32) - i80(hc, 48),
        "health_init": i80(hc, 0) - i80(hc, 16),
        "health_equity": i80(hc, 64) - i80(hc, 80),
    })
}

fn err_code(err: &solana_transaction::TransactionError) -> Value {
    match err {
        solana_transaction::TransactionError::InstructionError(_i, ie) => match ie {
            solana_instruction::error::InstructionError::Custom(c) => json!({"custom": c}),
            other => json!({"instruction_error": format!("{other:?}")}),
        },
        other => json!({"tx_error": format!("{other:?}")}),
    }
}

struct Env {
    svm: LiteSVM,
    payer: Keypair,
    j: Value,
    liquidator: Address,
}

impl Env {
    fn load(name: &str) -> Value {
        let path = format!("{}/../accounts/{name}.json", env!("CARGO_MANIFEST_DIR"));
        serde_json::from_str(&std::fs::read_to_string(&path).expect("case json missing")).unwrap()
    }

    fn setup(name: &str) -> Env {
        let j = Self::load(name);
        let mut svm = LiteSVM::new();
        let mfi_so = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../programs/marginfi_program.so"))
            .expect("marginfi_program.so missing");
        let tok_so = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../programs/tokenkeg.so"))
            .expect("tokenkeg.so missing");
        svm.add_program(addr(MFI), &mfi_so).unwrap();
        svm.add_program(addr(TOKENKEG), &tok_so).unwrap();
        for (pk, v) in j["accounts"].as_object().unwrap() {
            let data = B64.decode(v["data"].as_str().unwrap()).unwrap();
            svm.set_account(
                addr(pk),
                Account {
                    lamports: v["lamports"].as_u64().unwrap_or(1).max(1),
                    data,
                    owner: addr(v["owner"].as_str().unwrap()),
                    executable: false,
                    rent_epoch: 0,
                },
            )
            .unwrap();
        }
        let payer = Keypair::new();
        svm.airdrop(&payer.pubkey(), 100_000_000_000).unwrap();
        // Clock must sit just after the cloned oracles' publish_time, otherwise the program's
        // staleness gate (oracle_max_age, typically 70s) rejects them.
        let mut max_pt: i64 = 0;
        for (_pk, v) in j["accounts"].as_object().unwrap() {
            if v["owner"].as_str() == Some("rec2HHDDnjLfj4kE7VyEtFA1HPGQLK33259532cRyHp") {
                let d = B64.decode(v["data"].as_str().unwrap()).unwrap();
                if d.len() >= 101 {
                    let pt = i64::from_le_bytes(d[93..101].try_into().unwrap());
                    max_pt = max_pt.max(pt);
                }
            }
        }
        let mut clock: solana_clock::Clock = svm.get_sysvar();
        clock.unix_timestamp = if max_pt > 0 { max_pt + 2 } else { SNAPSHOT_TS };
        svm.set_sysvar(&clock);
        let ts = clock.unix_timestamp as u64;

        // Fabricate the liquidator marginfi account from an empty mainnet account in the same
        // group: patch authority to our payer and seed a SOL deposit so the post-liquidation
        // init-health check can pass (this is the attacker's capital).
        let template = j["liquidator_template"].as_str().unwrap();
        let mut d = B64
            .decode(j["accounts"][template]["data"].as_str().unwrap())
            .unwrap();
        d[40..72].copy_from_slice(payer.pubkey().as_ref());
        for i in 0..16 * 104 {
            d[72 + i] = 0;
        }
        let sol_bank = addr(j["sol_bank"].as_str().unwrap());
        let sol_bank_data = svm.get_account(&sol_bank).unwrap().data;
        let sol_asv = i80(&sol_bank_data, 80);
        let deposit_sol = 8.0_f64;
        let shares = deposit_sol / sol_asv;
        let b = 72;
        d[b] = 1;
        d[b + 1..b + 33].copy_from_slice(sol_bank.as_ref());
        d[b + 33] = 1; // ASSET_TAG_SOL
        d[b + 40..b + 56].copy_from_slice(&i80_bytes(shares));
        d[b + 88..b + 96].copy_from_slice(&ts.to_le_bytes());
        d[2208..2216].copy_from_slice(&ts.to_le_bytes());
        let liquidator = addr(template);
        svm.set_account(
            liquidator,
            Account {
                lamports: 16_982_400,
                data: d,
                owner: addr(MFI),
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();
        Env { svm, payer, j, liquidator }
    }

    fn send(&mut self, ixs: &[Instruction]) -> TransactionResult {
        let msg = Message::new_with_blockhash(ixs, Some(&self.payer.pubkey()), &self.svm.latest_blockhash());
        let tx = VersionedTransaction::try_new(VersionedMessage::Legacy(msg), &[&self.payer]).unwrap();
        self.svm.send_transaction(tx)
    }

    /// prepend a 1.4M CU budget instruction (real liquidations set this too)
    fn with_budget(&self, ix: Instruction) -> Vec<Instruction> {
        let mut data = vec![2u8];
        data.extend_from_slice(&1_400_000u32.to_le_bytes());
        vec![
            Instruction {
                program_id: addr("ComputeBudget111111111111111111111111111111"),
                accounts: vec![],
                data,
            },
            ix,
        ]
    }

    /// remaining accounts for one bank: [bank, aux...]
    fn bank_ais(&self, bank: Address) -> Vec<AccountMeta> {
        let key = bank.to_string();
        let list = self.j["remaining_for_bank"][&key].as_array().unwrap();
        list.iter().map(|v| ro(addr(v.as_str().unwrap()))).collect()
    }

    /// all balances' remaining accounts, sorted desc by bank pk (program sorts before health calc)
    fn balances_ais(&self, account: Address, extra: &[Address]) -> Vec<AccountMeta> {
        let data = self.svm.get_account(&account).unwrap().data;
        let mut banks = account_banks(&data);
        for e in extra {
            if !banks.contains(e) {
                banks.push(*e);
            }
        }
        banks.sort_by(|a, b| b.as_ref().cmp(a.as_ref()));
        let mut out = Vec::new();
        for b in banks {
            out.extend(self.bank_ais(b));
        }
        out
    }

    fn pulse(&mut self, account: Address) -> (Value, Vec<String>) {
        let group = addr(self.j["group"].as_str().unwrap());
        let mut metas = vec![wr(account), ro(group)];
        metas.extend(self.balances_ais(account, &[]));
        let ix = Instruction {
            program_id: addr(MFI),
            accounts: metas,
            data: disc("global:lending_account_pulse_health").to_vec(),
        };
        let ixs = self.with_budget(ix);
        let res = self.send(&ixs);
        let logs = match &res {
            Ok(meta) => meta.logs.clone(),
            Err(e) => e.meta.logs.clone(),
        };
        let hc = health_cache(&self.svm.get_account(&account).unwrap().data);
        (hc, logs)
    }

    fn liquidate(&mut self, amount: u64) -> Value {
        let j = &self.j;
        let liqee = addr(j["liquidatee"].as_str().unwrap());
        let asset_bank = addr(j["asset_bank"].as_str().unwrap());
        let liab_bank = addr(j["liab_bank"].as_str().unwrap());
        let group = addr(j["group"].as_str().unwrap());
        let vault_auth = addr(j["vault_authority"].as_str().unwrap());
        let liq_vault = addr(j["liab_liquidity_vault"].as_str().unwrap());
        let ins_vault = addr(j["liab_insurance_vault"].as_str().unwrap());
        let mut metas = vec![
            ro(group),
            wr(asset_bank),
            wr(liab_bank),
            wr(self.liquidator),
            sgn(self.payer.pubkey()),
            wr(liqee),
            ro(vault_auth),
            wr(liq_vault),
            wr(ins_vault),
            ro(addr(TOKENKEG)),
        ];
        // remaining: asset oracles, liab oracles, liquidator balances, liquidatee balances
        let asset_aux = self.bank_ais(asset_bank);
        let liab_aux = self.bank_ais(liab_bank);
        let asset_oracles = &asset_aux[1..];
        let liab_oracles = &liab_aux[1..];
        let liqor_ais = self.balances_ais(self.liquidator, &[asset_bank, liab_bank]);
        let liqee_ais = self.balances_ais(liqee, &[]);
        for m in asset_oracles.iter().chain(liab_oracles.iter()) {
            metas.push(m.clone());
        }
        metas.extend(liqor_ais.iter().cloned());
        metas.extend(liqee_ais.iter().cloned());
        let mut data = disc("global:lending_account_liquidate").to_vec();
        data.extend_from_slice(&amount.to_le_bytes());
        data.push(liqee_ais.len() as u8);
        data.push(liqor_ais.len() as u8);
        let ix = Instruction { program_id: addr(MFI), accounts: metas, data };
        let ixs = self.with_budget(ix);
        let res = self.send(&ixs);
        let (err, logs, ok) = match &res {
            Ok(meta) => (Value::Null, meta.logs.clone(), true),
            Err(e) => (err_code(&e.err), e.meta.logs.clone(), false),
        };
        // decode LendingAccountLiquidateEvent from logs if present
        let ev_disc = disc("event:LendingAccountLiquidateEvent");
        let mut event = Value::Null;
        for l in &logs {
            if let Some(b64) = l.strip_prefix("Program data: ") {
                if let Ok(raw) = B64.decode(b64) {
                    if raw.len() > 8 && raw[..8] == ev_disc {
                        // header: Option<Pubkey>(33) + 3 pubkeys (96) = 129
                        let o = 8 + 129;
                        let pre_o = o + 32 * 6 + 8 + 8;
                        let post_o = pre_o + 40;
                        event = json!({
                            "liquidatee_pre_health": f64_at(&raw, o + 32 * 6),
                            "liquidatee_post_health": f64_at(&raw, o + 32 * 6 + 8),
                            "pre": {
                                "liquidatee_asset_balance": f64_at(&raw, pre_o),
                                "liquidatee_liability_balance": f64_at(&raw, pre_o + 8),
                                "liquidator_asset_balance": f64_at(&raw, pre_o + 16),
                                "liquidator_liability_balance": f64_at(&raw, pre_o + 24),
                                "liquidator_liab_bank_asset_balance": f64_at(&raw, pre_o + 32),
                            },
                            "post": {
                                "liquidatee_asset_balance": f64_at(&raw, post_o),
                                "liquidatee_liability_balance": f64_at(&raw, post_o + 8),
                                "liquidator_asset_balance": f64_at(&raw, post_o + 16),
                                "liquidator_liability_balance": f64_at(&raw, post_o + 24),
                                "liquidator_liab_bank_asset_balance": f64_at(&raw, post_o + 32),
                            },
                        });
                    }
                }
            }
        }
        json!({"ok": ok, "err": err, "event": event, "logs_tail": logs.iter().rev().take(8).rev().collect::<Vec<_>>()})
    }
}

fn out_dir() -> std::path::PathBuf {
    let p = std::path::PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/../../ci-out"));
    std::fs::create_dir_all(&p).unwrap();
    p
}
fn dump(name: &str, v: &Value) {
    std::fs::write(out_dir().join(format!("{name}.json")), serde_json::to_string_pretty(v).unwrap()).unwrap();
}

/// T1 — v1 top "underwater" account: the deployed program disagrees (6068 HealthyAccount).
#[test]
fn t1_v1_top_is_healthy() {
    let mut env = Env::setup("t1_v1top_healthy");
    let liqee = addr(env.j["liquidatee"].as_str().unwrap());
    let (hc, _) = env.pulse(liqee);
    println!("T1 pulse health cache: {hc}");
    assert_eq!(hc["internal_liq_err"].as_u64().unwrap(), 6068, "expected HealthyAccount");
    assert!(hc["health_maint"].as_f64().unwrap() > 0.0, "expected positive maintenance health");
    let liq = env.liquidate(1_000_000_000); // seize 1 phaseLST
    println!("T1 liquidate: {liq}");
    assert_eq!(liq["ok"], false);
    assert_eq!(liq["err"]["custom"], 6068, "liquidation must be rejected as healthy");
    dump("t1_v1top_healthy", &json!({"pulse": hc, "liquidate": liq}));
}

/// T2 — program-confirmed liquidatable bad debt: no collateral, so nothing can be seized.
#[test]
fn t2_bad_debt_cannot_be_liquidated() {
    let mut env = Env::setup("t2_baddebt_liquidatable");
    let liqee = addr(env.j["liquidatee"].as_str().unwrap());
    let (hc, _) = env.pulse(liqee);
    println!("T2 pulse health cache: {hc}");
    assert_eq!(hc["internal_liq_err"].as_u64().unwrap(), 0, "expected liquidatable flag");
    assert!(hc["health_maint"].as_f64().unwrap() < 0.0, "expected negative maintenance health");
    let liq = env.liquidate(1_000);
    println!("T2 liquidate: {liq}");
    assert_eq!(liq["ok"], false, "no collateral -> liquidation must fail");
    dump("t2_baddebt_liquidatable", &json!({"pulse": hc, "liquidate": liq}));
}

/// T3 — program-confirmed liquidatable WITH collateral: executes, but seizes dust.
#[test]
fn t3_dust_collateral_liquidation() {
    let mut env = Env::setup("t3_dust_collateral");
    let liqee = addr(env.j["liquidatee"].as_str().unwrap());
    let (hc, _) = env.pulse(liqee);
    println!("T3 pulse health cache: {hc}");
    assert_eq!(hc["internal_liq_err"].as_u64().unwrap(), 0, "expected liquidatable flag");
    let amount = env.j["asset_amount"].as_u64().unwrap_or(1000);
    let liq = env.liquidate(amount);
    println!("T3 liquidate: {liq}");
    dump("t3_dust_collateral", &json!({"pulse": hc, "liquidate": liq, "asset_amount": amount}));
}

/// Batch: top-N program-verified liquidatable accounts (N >= 10) — pulse + real liquidation
/// attempt each, recording the exact per-account outcome (health, error, seized/repaid).
#[test]
fn t4_batch_top_n() {
    let dir = std::path::PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/../accounts"));
    let mut cases: Vec<String> = std::fs::read_dir(&dir)
        .unwrap()
        .filter_map(|e| {
            let p = e.ok()?.path();
            let name = p.file_stem()?.to_str()?.to_string();
            name.starts_with("batch_").then_some(name)
        })
        .collect();
    cases.sort();
    println!("batch cases: {cases:?}");
    assert!(cases.len() >= 10, "need at least 10 batch cases");
    let mut results = Vec::new();
    let mut n_liq_ok = 0usize;
    let mut n_liq_fail = 0usize;
    for name in &cases {
        let mut env = Env::setup(name);
        let liqee = addr(env.j["liquidatee"].as_str().unwrap());
        let (hc, _) = env.pulse(liqee);
        let amount = env.j["asset_amount"].as_u64().unwrap_or(1);
        let liq = env.liquidate(amount);
        if liq["ok"].as_bool().unwrap_or(false) {
            n_liq_ok += 1;
        } else {
            n_liq_fail += 1;
        }
        println!("{name}: pulse liq_err={} health={} | liq ok={} err={}",
                 hc["internal_liq_err"], hc["health_maint"], liq["ok"], liq["err"]);
        results.push(json!({
            "case": name,
            "liquidatee": env.j["liquidatee"],
            "asset_bank": env.j["asset_bank"],
            "liab_bank": env.j["liab_bank"],
            "asset_amount": amount,
            "pulse": hc,
            "liquidate": liq,
        }));
    }
    dump("batch_results", &json!({
        "n_cases": cases.len(), "liquidations_ok": n_liq_ok, "liquidations_failed": n_liq_fail,
        "results": results,
    }));
    // every batch case is program-liquidatable; the interesting split is ok vs error reason
    assert_eq!(n_liq_ok + n_liq_fail, cases.len());
}
