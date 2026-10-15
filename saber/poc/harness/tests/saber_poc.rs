//! Saber (C2-40) — chain-native PoC against the REAL deployed program bytecode.
//!
//! Harness: LiteSVM (in-process SVM, same runtime rules as a validator).
//! Loads:
//!   * the exact mainnet Saber stable-swap program (dumped ProgramData bytecode, deploy slot 119,721,738)
//!   * the exact mainnet SPL Token program bytecode
//!   * the real USDC/USDT pool state (slot 457,257,871): swap account, vaults, LP mint, mints, fee accounts
//!
//! Tests:
//!   T0 control: legitimate swap with the real Tokenkeg program succeeds.
//!   T1 fake-LP: withdraw with an attacker-owned "LP mint" is rejected (deployed binary checks pool_mint).
//!   T2 fake token program: Saber invokes the attacker program with the swap-authority PDA signer, but the
//!      runtime blocks any CPI back into Tokenkeg (callee not in the caller's account list) -> no drain.
//!   T3 fake swap account: a crafted SwapInfo pointing reserves at the real vaults cannot move them
//!      (vault owner must equal the PDA derived from *that* swap account).
//!   T4 rounding probe: synthetic pool reproduces the pre-Feb-2022 swap rounding; quantifies the leak.

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

const SABER: &str = "SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ";
const TOKENKEG: &str = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const ACCOUNTS_JSON: &str = include_str!("../../accounts.json");

// Synthetic pool (T3/T4): fixed key, nonce 253, off-curve authority (precomputed).
const SYNTH_SWAP: &str = "4BTrNCW2BQ4L9syxcwhMMwt4BqDRvBNWm1hUEzQnkQ4s";
const SYNTH_NONCE: u8 = 253;
const SYNTH_AUTHORITY: &str = "72veoxzcdjX2qRjNhaPo5txfPS9ggtkfn8B3p89ybAfg";

fn addr(s: &str) -> Address {
    Address::from_str(s).unwrap()
}
fn saber() -> Address {
    addr(SABER)
}
fn tokenkeg() -> Address {
    addr(TOKENKEG)
}
fn ro(pk: Address) -> AccountMeta {
    AccountMeta {
        pubkey: pk,
        is_signer: false,
        is_writable: false,
    }
}
fn wr(pk: Address) -> AccountMeta {
    AccountMeta {
        pubkey: pk,
        is_signer: false,
        is_writable: true,
    }
}
fn sgn(pk: Address) -> AccountMeta {
    AccountMeta {
        pubkey: pk,
        is_signer: true,
        is_writable: false,
    }
}

fn token_data(mint: &Address, owner: &Address, amount: u64) -> Vec<u8> {
    let mut d = vec![0u8; 165];
    d[0..32].copy_from_slice(mint.as_ref());
    d[32..64].copy_from_slice(owner.as_ref());
    d[64..72].copy_from_slice(&amount.to_le_bytes());
    d[108] = 1; // AccountState::Initialized
    d
}

fn mint_data(authority: &Address, supply: u64, decimals: u8) -> Vec<u8> {
    let mut d = vec![0u8; 82];
    d[0..4].copy_from_slice(&1u32.to_le_bytes()); // COption::Some
    d[4..36].copy_from_slice(authority.as_ref());
    d[36..44].copy_from_slice(&supply.to_le_bytes());
    d[44] = decimals;
    d[45] = 1; // initialized
    d
}

fn mk_account(svm: &mut LiteSVM, owner: &Address, data: Vec<u8>) -> Address {
    let key = Address::new_unique();
    svm.set_account(
        key,
        Account {
            lamports: 3_000_000,
            data,
            owner: *owner,
            executable: false,
            rent_epoch: 0,
        },
    )
    .unwrap();
    key
}

fn read_amount(svm: &LiteSVM, key: &Address) -> u64 {
    let a = svm.get_account(key).unwrap();
    u64::from_le_bytes(a.data[64..72].try_into().unwrap())
}

/// Synthetic SwapInfo (395 bytes, exact `SwapInfo::pack` layout).
#[allow(clippy::too_many_arguments)]
fn synth_swap_data(
    nonce: u8,
    amp: u64,
    reserves_a: &Address,
    reserves_b: &Address,
    pool_mint: &Address,
    mint_a: &Address,
    mint_b: &Address,
    admin_a: &Address,
    admin_b: &Address,
) -> Vec<u8> {
    let mut d = vec![0u8; 395];
    d[0] = 1; // is_initialized
    d[1] = 0; // is_paused
    d[2] = nonce;
    d[3..11].copy_from_slice(&amp.to_le_bytes()); // initial_amp
    d[11..19].copy_from_slice(&amp.to_le_bytes()); // target_amp
    // ramp ts (0), future_admin_deadline (0), future_admin_key (0)
    d[75..107].copy_from_slice(&[7u8; 32]); // admin_key (unused)
    d[107..139].copy_from_slice(reserves_a.as_ref());
    d[139..171].copy_from_slice(reserves_b.as_ref());
    d[171..203].copy_from_slice(pool_mint.as_ref());
    d[203..235].copy_from_slice(mint_a.as_ref());
    d[235..267].copy_from_slice(mint_b.as_ref());
    d[267..299].copy_from_slice(admin_a.as_ref());
    d[299..331].copy_from_slice(admin_b.as_ref());
    // fees: all zero numerators (denominators 1000 to avoid div-by-zero)
    let zero_fee = |d: &mut Vec<u8>, off: usize| {
        d[off..off + 8].copy_from_slice(&0u64.to_le_bytes());
        d[off + 8..off + 16].copy_from_slice(&1000u64.to_le_bytes());
    };
    zero_fee(&mut d, 331); // admin_trade
    zero_fee(&mut d, 347); // admin_withdraw
    zero_fee(&mut d, 363); // trade
    zero_fee(&mut d, 379); // withdraw
    d
}

fn pda(seeds: &[&[u8]], program: &Address) -> Address {
    let mut h = Sha256::new();
    for s in seeds {
        h.update(s);
    }
    h.update(program.as_ref());
    h.update(b"ProgramDerivedAddress");
    let out: [u8; 32] = h.finalize().into();
    Address::from(out)
}

struct Env {
    svm: LiteSVM,
    payer: Keypair,
    j: Value,
}

impl Env {
    fn acc(&self, name: &str) -> Address {
        addr(self.j["accounts"][name]["pubkey"].as_str().unwrap())
    }
    fn send(&mut self, ixs: &[Instruction]) -> TransactionResult {
        let msg = Message::new_with_blockhash(
            ixs,
            Some(&self.payer.pubkey()),
            &self.svm.latest_blockhash(),
        );
        let tx = VersionedTransaction::try_new(VersionedMessage::Legacy(msg), &[&self.payer]).unwrap();
        self.svm.send_transaction(tx)
    }
}

fn setup() -> Env {
    let j: Value = serde_json::from_str(ACCOUNTS_JSON).unwrap();
    let mut svm = LiteSVM::new();
    let saber_so = std::fs::read(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../programs/saber_program.so"
    ))
    .expect("saber_program.so missing");
    let tok_so = std::fs::read(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../programs/tokenkeg.so"
    ))
    .expect("tokenkeg.so missing");
    svm.add_program(saber(), &saber_so).unwrap();
    svm.add_program(tokenkeg(), &tok_so).unwrap();

    for (_name, v) in j["accounts"].as_object().unwrap() {
        let pk = addr(v["pubkey"].as_str().unwrap());
        let b64 = v["data_b64"].as_str().unwrap();
        let data = if b64.is_empty() {
            vec![]
        } else {
            B64.decode(b64).unwrap()
        };
        let owner = match v["owner"].as_str() {
            Some(o) => addr(o),
            None => saber(), // the authority PDA account does not exist on-chain; create it locally
        };
        let lamports = v["lamports"].as_u64().unwrap_or(1).max(1);
        svm.set_account(
            pk,
            Account {
                lamports,
                data,
                owner,
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();
    }
    let payer = Keypair::new();
    svm.airdrop(&payer.pubkey(), 100_000_000_000).unwrap();
    // Realistic clock: pools have amp ramps with real 2025 timestamps; the default
    // LiteSVM clock (unix_timestamp = 0) underflows in compute_amp_factor.
    let mut clock: solana_clock::Clock = svm.get_sysvar();
    clock.unix_timestamp = 1_790_000_000; // 2026-09-XX
    svm.set_sysvar(&clock);
    Env { svm, payer, j }
}

fn out_dir() -> std::path::PathBuf {
    let p = std::path::PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/../../ci-out"));
    std::fs::create_dir_all(&p).unwrap();
    p
}

fn dump(name: &str, v: &Value) {
    let p = out_dir().join(format!("{name}.json"));
    std::fs::write(p, serde_json::to_string_pretty(v).unwrap()).unwrap();
}

fn malicious_path() -> String {
    std::env::var("MALICIOUS_SO").unwrap_or_else(|_| {
        format!(
            "{}/../target/deploy/malicious_token_program.so",
            env!("CARGO_MANIFEST_DIR")
        )
    })
}

/// T0 — control: a legitimate swap through the real Tokenkeg program works.
#[test]
fn t0_control_legit_swap() {
    let mut env = setup();
    let attacker = env.payer.pubkey();
    let (mint_a, mint_b) = (env.acc("mint_a"), env.acc("mint_b"));
    let src = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_a, &attacker, 1_000_000));
    let dst = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_b, &attacker, 0));
    let (swap, auth) = (env.acc("swap"), env.acc("authority"));
    let (va, vb, afb) = (env.acc("vault_a"), env.acc("vault_b"), env.acc("admin_fee_b"));
    let before_a = read_amount(&env.svm, &va);
    let before_b = read_amount(&env.svm, &vb);

    let mut data = vec![1u8]; // Swap
    data.extend_from_slice(&1000u64.to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    let ix = Instruction {
        program_id: saber(),
        accounts: vec![
            ro(swap),
            ro(auth),
            sgn(attacker),
            wr(src),
            wr(va),
            wr(vb),
            wr(dst),
            wr(afb),
            ro(tokenkeg()),
        ],
        data,
    };
    let res = env.send(&[ix]);
    match &res {
        Ok(m) => println!("T0 PASS logs:\n{}", m.logs.join("\n")),
        Err(e) => panic!("T0 control swap failed: {:?} logs={:?}", e.err, e.meta.logs),
    }
    let after_a = read_amount(&env.svm, &va);
    let after_b = read_amount(&env.svm, &vb);
    let got_b = read_amount(&env.svm, &dst);
    assert_eq!(after_a, before_a + 1000, "vault A must receive input");
    assert!(after_b < before_b, "vault B must pay out");
    assert!(got_b > 0, "user must receive output");
    dump(
        "t0_control",
        &json!({
            "status": "PASS",
            "vault_a_before": before_a, "vault_a_after": after_a,
            "vault_b_before": before_b, "vault_b_after": after_b,
            "user_received_b": got_b,
        }),
    );
}

/// T1 — fake LP mint: withdraw must fail with IncorrectMint (custom 13).
#[test]
fn t1_fake_lp_mint_cannot_withdraw() {
    let mut env = setup();
    let attacker = env.payer.pubkey();
    // attacker-controlled "LP mint" (they own the mint authority) + funded LP account
    let fake_mint = mk_account(&mut env.svm, &tokenkeg(), mint_data(&attacker, 10u64.pow(15), 6));
    let fake_lp = mk_account(
        &mut env.svm,
        &tokenkeg(),
        token_data(&fake_mint, &attacker, 10u64.pow(15)),
    );
    let (mint_a, mint_b) = (env.acc("mint_a"), env.acc("mint_b"));
    let da = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_a, &attacker, 0));
    let db = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_b, &attacker, 0));
    let (swap, auth) = (env.acc("swap"), env.acc("authority"));
    let (va, vb) = (env.acc("vault_a"), env.acc("vault_b"));
    let (afa, afb) = (env.acc("admin_fee_a"), env.acc("admin_fee_b"));
    let before_a = read_amount(&env.svm, &va);
    let before_b = read_amount(&env.svm, &vb);

    let mut data = vec![3u8]; // Withdraw
    data.extend_from_slice(&10u64.pow(15).to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    let ix = Instruction {
        program_id: saber(),
        accounts: vec![
            ro(swap),
            ro(auth),
            sgn(attacker),
            ro(fake_mint), // <-- attacker's mint, not the pool LP mint
            wr(fake_lp),
            wr(va),
            wr(vb),
            wr(da),
            wr(db),
            wr(afa),
            wr(afb),
            ro(tokenkeg()),
        ],
        data,
    };
    let res = env.send(&[ix]);
    let err_str = match &res {
        Ok(_) => panic!("T1 FAILED: fake-LP withdraw unexpectedly succeeded"),
        Err(e) => {
            println!("T1 error: {:?}", e.err);
            format!("{:?}", e.err)
        }
    };
    assert_eq!(read_amount(&env.svm, &va), before_a, "vault A must be untouched");
    assert_eq!(read_amount(&env.svm, &vb), before_b, "vault B must be untouched");
    let code_ok = err_str.contains("Custom(13)"); // SwapError::IncorrectMint
    println!("T1 IncorrectMint(13) match: {code_ok}");
    dump(
        "t1_fake_lp",
        &json!({
            "status": "CLOSED",
            "error": err_str,
            "incorrect_mint_13": code_ok,
            "vault_a_before": before_a, "vault_a_after": read_amount(&env.svm, &va),
            "vault_b_before": before_b, "vault_b_after": read_amount(&env.svm, &vb),
        }),
    );
    assert!(code_ok, "expected Saber IncorrectMint (custom 13), got {err_str}");
}

/// T2 — fake token program: Saber's token helpers pass the attacker-supplied `token_program.key`
/// into the SPL-Token instruction constructors, which reject any id != Tokenkeg with
/// `IncorrectProgramId` before any CPI. The attacker program is never invoked and no funds move.
/// (Defense in depth: even without that check, the runtime forbids the follow-up CPI into Tokenkeg
/// because the callee program account is not in the attacker program's account list.)
#[test]
fn t2_fake_token_program_rejected_before_any_cpi() {
    let mut env = setup();
    let mal_so = std::fs::read(malicious_path()).expect("malicious .so missing (build with cargo build-sbf)");
    let mal_id = Address::new_unique();
    env.svm.add_program(mal_id, &mal_so).unwrap();

    let attacker = env.payer.pubkey();
    let (mint_a, mint_b) = (env.acc("mint_a"), env.acc("mint_b"));
    let src = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_a, &attacker, 1_000_000));
    let dst = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_b, &attacker, 0));
    let (swap, auth) = (env.acc("swap"), env.acc("authority"));
    let (va, vb, afb) = (env.acc("vault_a"), env.acc("vault_b"), env.acc("admin_fee_b"));
    let before_a = read_amount(&env.svm, &va);
    let before_b = read_amount(&env.svm, &vb);
    let before_src = read_amount(&env.svm, &src);

    let mut data = vec![1u8]; // Swap
    data.extend_from_slice(&1000u64.to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    let ix = Instruction {
        program_id: saber(),
        accounts: vec![
            ro(swap),
            ro(auth),
            sgn(attacker),
            wr(src),
            wr(va),
            wr(vb),
            wr(dst),
            wr(afb),
            ro(mal_id), // <-- attacker program passed as "token program"
            ro(tokenkeg()), // extra trailing account: real Tokenkeg IS in the transaction
        ],
        data,
    };
    let res = env.send(&[ix]);
    let (err_str, logs) = match &res {
        Ok(m) => panic!("T2 FAILED: fake token program tx succeeded; logs={:?}", m.logs),
        Err(e) => (format!("{:?}", e.err), e.meta.logs.clone()),
    };
    let joined = logs.join("\n");
    println!("T2 error: {err_str}");
    println!("T2 logs:\n{joined}");

    let attacker_invoked = joined.contains("MAL: invoked");
    let incorrect_program_id = joined.contains("IncorrectProgramId") || err_str.contains("IncorrectProgramId");
    let cpi_succeeded = joined.contains("MAL: TOKENKEG CPI SUCCEEDED");
    println!(
        "T2 incorrect_program_id={incorrect_program_id} attacker_invoked={attacker_invoked} cpi_succeeded={cpi_succeeded}"
    );

    assert!(incorrect_program_id, "expected Saber to reject the fake token program with IncorrectProgramId");
    assert!(!attacker_invoked, "attacker program must never be invoked");
    assert!(!cpi_succeeded, "CRITICAL: attacker CPI into Tokenkeg SUCCEEDED");
    assert_eq!(read_amount(&env.svm, &va), before_a, "vault A must be untouched");
    assert_eq!(read_amount(&env.svm, &vb), before_b, "vault B must be untouched");
    assert_eq!(read_amount(&env.svm, &src), before_src, "attacker funds untouched");

    dump(
        "t2_fake_token_program",
        &json!({
            "status": "CLOSED",
            "error": err_str,
            "incorrect_program_id": incorrect_program_id,
            "attacker_program_invoked": attacker_invoked,
            "tokenkeg_cpi_succeeded": cpi_succeeded,
            "vault_a_before": before_a, "vault_a_after": read_amount(&env.svm, &va),
            "vault_b_before": before_b, "vault_b_after": read_amount(&env.svm, &vb),
        }),
    );
}

/// T3 — crafted SwapInfo cannot redirect real vaults: the authority is bound to the swap account.
#[test]
fn t3_fake_swap_account_cannot_redirect_real_vaults() {
    let mut env = setup();
    let attacker = env.payer.pubkey();
    let (swap_real, auth_real) = (env.acc("swap"), env.acc("authority"));
    let (va, vb) = (env.acc("vault_a"), env.acc("vault_b"));
    let (afa, afb) = (env.acc("admin_fee_a"), env.acc("admin_fee_b"));
    let (mint_a, mint_b) = (env.acc("mint_a"), env.acc("mint_b"));
    let lp_mint = env.acc("pool_mint");

    // fake swap account (fixed key) whose stored reserves are the REAL vaults
    let fake_swap = addr(SYNTH_SWAP);
    let synth_auth = addr(SYNTH_AUTHORITY);
    assert_eq!(
        pda(&[fake_swap.as_ref(), &[SYNTH_NONCE]], &saber()),
        synth_auth,
        "synth authority derivation mismatch"
    );
    let data = synth_swap_data(SYNTH_NONCE, 100, &va, &vb, &lp_mint, &mint_a, &mint_b, &afa, &afb);
    env.svm
        .set_account(
            fake_swap,
            Account {
                lamports: 3_000_000,
                data,
                owner: saber(),
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();

    // attacker LP account of the REAL LP mint, funded out of thin air (1e9 LP < supply 8.15e11,
    // so the computed withdrawal is well within the vault balances)
    let fake_lp = mk_account(&mut env.svm, &tokenkeg(), token_data(&lp_mint, &attacker, 1_000_000_000));
    let da = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_a, &attacker, 0));
    let db = mk_account(&mut env.svm, &tokenkeg(), token_data(&mint_b, &attacker, 0));
    let before_a = read_amount(&env.svm, &va);
    let before_b = read_amount(&env.svm, &vb);

    let mut data = vec![3u8]; // Withdraw
    data.extend_from_slice(&1_000_000_000u64.to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    data.extend_from_slice(&0u64.to_le_bytes());
    let ix = Instruction {
        program_id: saber(),
        accounts: vec![
            ro(fake_swap),
            ro(synth_auth),
            sgn(attacker),
            ro(lp_mint),
            wr(fake_lp),
            wr(va),
            wr(vb),
            wr(da),
            wr(db),
            wr(afa),
            wr(afb),
            ro(tokenkeg()),
        ],
        data,
    };
    let res = env.send(&[ix]);
    let (err_str, logs) = match &res {
        Ok(_) => panic!("T3 FAILED: crafted swap account moved real vault funds"),
        Err(e) => (format!("{:?}", e.err), e.meta.logs.clone()),
    };
    println!("T3 error: {err_str}");
    println!("T3 logs:\n{}", logs.join("\n"));
    assert_eq!(read_amount(&env.svm, &va), before_a);
    assert_eq!(read_amount(&env.svm, &vb), before_b);
    let tokenkeg_rejected = logs.iter().any(|l| l.contains("Tokenkeg") && l.contains("failed"));
    assert!(tokenkeg_rejected, "expected Tokenkeg to reject the transfer (owner binding)");
    let _ = (swap_real, auth_real);
    dump(
        "t3_fake_swap",
        &json!({
            "status": "CLOSED",
            "error": err_str,
            "tokenkeg_rejected_transfer": tokenkeg_rejected,
            "vault_a_before": before_a, "vault_a_after": read_amount(&env.svm, &va),
            "vault_b_before": before_b, "vault_b_after": read_amount(&env.svm, &vb),
        }),
    );
}

/// T4 — rounding probe on a synthetic pool (amp 324449, zero fees, 100e9/100e9 reserves):
/// reproduce the exact sequence from the Feb-2022 regression tests and measure any leak.
#[test]
fn t4_rounding_probe() {
    let mut env = setup();
    let attacker = env.payer.pubkey();
    let synth_auth = addr(SYNTH_AUTHORITY);
    let fake_swap = addr(SYNTH_SWAP);

    // attacker-owned mints (attacker is mint authority) and accounts
    let my_a = mk_account(&mut env.svm, &tokenkeg(), mint_data(&attacker, u64::MAX, 9));
    let my_b = mk_account(&mut env.svm, &tokenkeg(), mint_data(&attacker, u64::MAX, 9));
    let my_lp = mk_account(&mut env.svm, &tokenkeg(), mint_data(&attacker, 0, 9));
    let my_fee_a = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_a, &attacker, 0));
    let my_fee_b = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_b, &attacker, 0));
    // vaults owned by the synthetic PDA
    let va = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_a, &synth_auth, 100_000_000_000));
    let vb = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_b, &synth_auth, 100_000_000_000));
    // user balances
    let ua = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_a, &attacker, 10_000_000_000));
    let ub = mk_account(&mut env.svm, &tokenkeg(), token_data(&my_b, &attacker, 10_000_000_000));

    let data = synth_swap_data(SYNTH_NONCE, 324449, &va, &vb, &my_lp, &my_a, &my_b, &my_fee_a, &my_fee_b);
    env.svm
        .set_account(
            fake_swap,
            Account {
                lamports: 3_000_000,
                data,
                owner: saber(),
                executable: false,
                rent_epoch: 0,
            },
        )
        .unwrap();

    let initial_total: u64 = 20_000_000_000;
    let mut totals = vec![initial_total];
    let mut per_swap = vec![];
    let seq: [u64; 3] = [2_097_152, 8_053_063_680, 48];
    for amt in seq {
        let mut data = vec![1u8];
        data.extend_from_slice(&amt.to_le_bytes());
        data.extend_from_slice(&0u64.to_le_bytes());
        let ix = Instruction {
            program_id: saber(),
            accounts: vec![
                ro(fake_swap),
                ro(synth_auth),
                sgn(attacker),
                wr(ua),
                wr(va),
                wr(vb),
                wr(ub),
                wr(my_fee_b),
                ro(tokenkeg()),
            ],
            data,
        };
        let res = env.send(&[ix]);
        if let Err(e) = &res {
            panic!("T4 swap failed: {:?} logs={:?}", e.err, e.meta.logs);
        }
        let a_after = read_amount(&env.svm, &ua);
        let b_after = read_amount(&env.svm, &ub);
        totals.push(a_after + b_after);
        per_swap.push(json!({
            "amount_in": amt,
            "user_a_after": a_after, "user_b_after": b_after,
            "user_b_delta": b_after as i128 - 10_000_000_000i128,
            "vault_a_after": read_amount(&env.svm, &va), "vault_b_after": read_amount(&env.svm, &vb),
        }));
    }

    // extended probe: 200 tiny swaps (amounts < fee-free threshold irrelevant here, fees are 0)
    let mut extra_gain: i128 = 0;
    for i in 0..200u64 {
        let amt = 1_000 + i * 7;
        let before = read_amount(&env.svm, &ua) + read_amount(&env.svm, &ub);
        let mut data = vec![1u8];
        data.extend_from_slice(&amt.to_le_bytes());
        data.extend_from_slice(&0u64.to_le_bytes());
        let ix = Instruction {
            program_id: saber(),
            accounts: vec![
                ro(fake_swap),
                ro(synth_auth),
                sgn(attacker),
                wr(ua),
                wr(va),
                wr(vb),
                wr(ub),
                wr(my_fee_b),
                ro(tokenkeg()),
            ],
            data,
        };
        let res = env.send(&[ix]);
        if let Err(e) = &res {
            panic!("T4 extra swap failed: {:?}", e.err);
        }
        let after = read_amount(&env.svm, &ua) + read_amount(&env.svm, &ub);
        extra_gain += after as i128 - before as i128;
    }

    let final_total = read_amount(&env.svm, &ua) + read_amount(&env.svm, &ub);
    println!("T4 totals after regression sequence: {totals:?}");
    println!("T4 final total: {final_total} (initial {initial_total})");
    println!("T4 net gain over 200 extra swaps: {extra_gain} raw units");

    dump(
        "t4_rounding",
        &json!({
            "status": "MEASURED",
            "sequence": seq,
            "totals_after_each_swap": totals,
            "per_swap": per_swap,
            "initial_total": initial_total,
            "final_total": final_total,
            "regression_gain_units": final_total as i128 - initial_total as i128,
            "extra_swaps": 200,
            "extra_gain_units": extra_gain,
            "note": "deployed program was last upgraded 2022-02-07 (slot 119721738); compare per-swap outputs against pre/post-2022-02-25 math to determine which build is live",
        }),
    );
}
