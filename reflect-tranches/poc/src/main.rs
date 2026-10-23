//! READ-ONLY authorisation harness for the Reflect Tranches deployment on Solana mainnet.
//!
//! Loads the *deployed* program ELFs (JrXLmS6… RLP, pRoxYU64… proxy) plus cloned mainnet
//! accounts into an in-process LiteSVM and exercises every value-moving / role-mutating
//! instruction. Signature verification is disabled in the VM so that a **real privileged
//! pubkey** (the on-chain SUPREMO / MANAGER / proxy authority / cooldown authority) can be
//! used as the signer for a *positive control*, while a **fresh random keypair** is used for
//! the unprivileged test. The pair isolates the authorisation check exactly.
//!
//! Nothing is signed against a real network and nothing is broadcast; the VM is local.
//! Cloned price accounts are "refreshed" (timestamp fields only) so oracle staleness cannot
//! mask the authorisation result being measured.

use litesvm::types::TransactionResult;
use litesvm::LiteSVM;
use serde_json::Value;
use sha2::{Digest, Sha256};
use solana_account::Account;
use solana_address::Address;
use solana_clock::Clock;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;

const RLP_S: &str = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av";
const PROXY_S: &str = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C";
const TOKEN_S: &str = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const ATA_S: &str = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";
const SYSTEM_S: &str = "11111111111111111111111111111111";

const SETTINGS: &str = "9q89A973AWTkvWi87tKPj8GSw58b6JJhWALCJ1MGXNFc";
const PERM_SUPREMO: &str = "8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625";
const SUPREMO: &str = "28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA";
const MANAGER: &str = "KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw";
const PERM_MANAGER: &str = "CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY";
const POOL0: &str = "HcSqywSCt1tQ9XPD2ztEmZ3kaWc1ZgB7vs8GxCbbH7pw";
const ASSET0: &str = "27K2omY6vfgx2SH8htus5pb4CXT29tXhvFFXgy5UTwZr";
const MINT0: &str = "AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj";
const POOL0_ATA0: &str = "Dh1sPTGc9YycHKnw5t4S1Ss24TtcoWTiD61azGSmtoS5";
const AUTHORITY_ATA0: &str = "UVw4BJXJqnVpi9Qw98KXcHNYS6ZG836ZcX8rqibTnFq";
// pool AAyszk / asset idx4 — exact accounts of a real on-chain RLP Withdraw tx (slot 460429494)
const POOL_A: &str = "AAyszkQtxXEgFPwq6E19TkcuyJpK9gpxofk9LZzhdE9j";
const LP_A: &str = "JrGsMfJodyVEqLGnyAKa9qHzRqZ9dzFfeSjouV3qEeG";
const ASSET_A: &str = "HqZ7TKBR6DLhFLnCujsTdnQ3WSdVoHiV9BXQWhGx7mbJ";
const MINT_A: &str = "3b8X44fLF9ooXaUm3hhSgjpmVs6rZZ3pPoGnGahc3Uu7";
const POOL_A_ATA: &str = "GYgwMfwfjwtBZhx1ongrGC5cbqAWJfL8qZEFwejMptHv";
const STREAM_A: &str = "z9WRzdCfvHtVjGSLQjfNhynRY6XZHRX9hSJFgWV7j9A";
const PROXY_STATE_A: &str = "By42A3QzVt1KERdnJcPESGWR3YoN2GSbzZroQFGJ6Qjm";
const PROXY_VAULT_A: &str = "J6fkJ53tCcentTPgiExLJmo6iKRnUKBbU9FAaKVxC461";
const COOLDOWN_A: &str = "H9AihFBfAwVuwimeySWM1Xk9w9iUpS5Lj2qXq5S3vDru";
const COOLDOWN_A_ESCROW: &str = "6HqnrLXX7WTMXLkzLpC9EWaYB6T7MKXz9PJwNt4JDs3r";
const COOLDOWN_A_AUTH: &str = "8iSXYPaUoveig2cYUzQYNcgLypbn6BKr5wNVHmEzRbhJ";
// proxy (senior tranche) pool 0
const PROXY_STATE0: &str = "FD4YydhzPpSmXwnHsX1oJBE4er4m9mg4ezaBN9cXgQbz";
const PROXY_VAULT0: &str = "E5ohyMVkBTdn3DekUPcFyLFF2Wi78Rg3Mt9QQDWgN5Mp";
const BRANDED_MINT0: &str = "sro4agJ6nJ89MJgj2DfDdx8zXVqSyZfCZjbhBfQaJU5";
const PROXY_ORACLE0: &str = "GWdwWDhYFUc8ZD6uCTtEAAwx97V1ZCsxPWGL7vhSha6w";
const PROXY_CFG0: &str = "V8eHEsRUBcxpkYZN2jhjYLzJFhbWbFvpNJYBp1YHNar";
const PROXY_AUTH0: &str = "apyaB89kiVoc1xfYiYAMmRDB2M1qSYYdHy7psv5pPwE";
const VICTIM_BRANDED0: &str = "7cfj48Ym6zsu8WfPtDrU3ERw4Y1WxRzrqd9gF7KrWiJv";

fn a(s: &str) -> Address {
    s.parse::<Address>().unwrap()
}
fn disc(name: &str) -> [u8; 8] {
    let mut h = Sha256::new();
    h.update(format!("global:{name}").as_bytes());
    let d = h.finalize();
    let mut o = [0u8; 8];
    o.copy_from_slice(&d[..8]);
    o
}
fn pda(seeds: &[&[u8]], pid: &Address) -> Address {
    Address::find_program_address(seeds, pid).0
}
fn meta(pk: Address, signer: bool, writable: bool) -> AccountMeta {
    AccountMeta { pubkey: pk, is_signer: signer, is_writable: writable }
}
fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}
fn b64(s: &str) -> Vec<u8> {
    const T: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut idx = [255u8; 256];
    for (i, c) in T.iter().enumerate() {
        idx[*c as usize] = i as u8;
    }
    let mut out = Vec::new();
    let (mut buf, mut bits) = (0u32, 0u32);
    for c in s.bytes() {
        if c == b'=' {
            break;
        }
        let v = idx[c as usize];
        if v == 255 {
            continue;
        }
        buf = (buf << 6) | v as u32;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            out.push((buf >> bits) as u8);
        }
    }
    out
}

struct Harness {
    svm: LiteSVM,
    rlp: Address,
    proxy: Address,
    token: Address,
    ata: Address,
}

impl Harness {
    fn new(accounts_path: &str, programs_dir: &str, slot: u64, ts: i64) -> Self {
        // sigverify OFF: a real privileged pubkey can be used as a signer without its key.
        let mut svm = LiteSVM::new().with_sigverify(false);
        svm.set_sysvar(&Clock { slot, epoch_start_timestamp: 0, epoch: 0, leader_schedule_epoch: 0, unix_timestamp: ts });

        let rlp = a(RLP_S);
        let proxy = a(PROXY_S);
        let token = a(TOKEN_S);
        let ata = a(ATA_S);
        for (pid, file) in [(rlp, "rlp.so"), (proxy, "proxy.so"), (token, "spl_token.so"), (ata, "ata.so")] {
            if svm.get_account(&pid).is_none() {
                let bytes = std::fs::read(format!("{programs_dir}/{file}")).unwrap();
                svm.add_program(pid, &bytes).unwrap();
            }
        }

        let raw: Value = serde_json::from_str(&std::fs::read_to_string(accounts_path).unwrap()).unwrap();
        for (_, v) in raw["accounts"].as_object().unwrap() {
            let pk = a(v["pubkey"].as_str().unwrap());
            let mut data = b64(v["data"].as_str().unwrap());
            let owner = v["owner"].as_str().unwrap();
            // refresh cached timestamps so oracle staleness cannot mask the auth result
            if (owner == RLP_S || owner == PROXY_S) && data.len() == 75 {
                // StreamPrice: [62..66] u32 unix_timestamp, [66..70] u32 slot
                data[62..66].copy_from_slice(&(ts as u32).to_le_bytes());
                data[66..70].copy_from_slice(&(slot as u32).to_le_bytes());
            } else if owner.starts_with("rec5EKMGg6") && data.len() >= 134 {
                // Pyth PriceUpdateV2: [93..101] publish_time, [125..129] posted_slot
                data[93..101].copy_from_slice(&ts.to_le_bytes());
                data[125..129].copy_from_slice(&(slot as u32).to_le_bytes());
            }
            svm.set_account(pk, Account {
                lamports: v["lamports"].as_u64().unwrap(),
                data,
                owner: a(owner),
                executable: v["executable"].as_bool().unwrap(),
                rent_epoch: v["rentEpoch"].as_u64().unwrap_or(0),
            }).unwrap();
        }
        Harness { svm, rlp, proxy, token, ata }
    }

    /// Send with `payer` paying (a real keypair) and any `is_signer` metas treated as signers.
    /// sigverify is off, so privileged pubkeys need no key material.
    fn send(&mut self, ixs: &[Instruction], payer: &Keypair, label: &str) -> (bool, String) {
        let msg = Message::new_with_blockhash(ixs, Some(&payer.pubkey()), &self.svm.latest_blockhash());
        let tx = Transaction::new_unsigned(msg);
        match self.svm.send_transaction(tx) {
            TransactionResult::Ok(_) => {
                println!("  [OK ] {label}");
                (true, String::new())
            }
            TransactionResult::Err(e) => {
                let err = format!("{:?}", e.err);
                let why = e.meta.logs.iter().rev().find(|l| l.contains("AnchorError") || l.contains("failed")).cloned().unwrap_or_default();
                println!("  [ERR] {label} -> {err}   | {}", why.replace("Program log: ", ""));
                (false, err)
            }
        }
    }

    fn ata_of(&self, owner: &Address, mint: &Address) -> Address {
        pda(&[owner.as_ref(), self.token.as_ref(), mint.as_ref()], &self.ata)
    }
    fn bal(&self, acct: &Address) -> u64 {
        match self.svm.get_account(acct) {
            Some(x) if x.data.len() >= 72 => u64::from_le_bytes(x.data[64..72].try_into().unwrap()),
            _ => 0,
        }
    }
    #[allow(dead_code)]
    fn create_ata_ix(&self, payer: &Address, owner: &Address, mint: &Address) -> Instruction {
        Instruction {
            program_id: self.ata,
            accounts: vec![
                meta(*payer, true, true), meta(self.ata_of(owner, mint), false, true),
                meta(*owner, false, false), meta(*mint, false, false),
                meta(a(SYSTEM_S), false, false), meta(self.token, false, false),
            ],
            data: vec![0u8],
        }
    }
    fn patch(&mut self, addr: &Address, f: impl Fn(&mut Vec<u8>)) {
        let mut acc = self.svm.get_account(addr).expect("account exists");
        f(&mut acc.data);
        self.svm.set_account(*addr, acc).unwrap();
    }
    /// Fabricate an initialised SPL Token account directly (no ATA-program dependency).
    fn set_token_account(&mut self, mint: &Address, owner: &Address, amount: u64) -> Address {
        let addr = self.ata_of(owner, mint);
        let mut d = vec![0u8; 165];
        d[0..32].copy_from_slice(mint.as_ref());
        d[32..64].copy_from_slice(owner.as_ref());
        d[64..72].copy_from_slice(&amount.to_le_bytes());
        d[108] = 1; // AccountState::Initialized
        self.svm
            .set_account(addr, Account { lamports: 3_000_000, data: d, owner: self.token, executable: false, rent_epoch: 0 })
            .unwrap();
        addr
    }
}

fn main() {
    let base = std::env::args().nth(1).unwrap_or_else(|| ".".to_string());
    let slot = 460_456_908u64;
    let ts = 1_792_741_085i64;
    println!("== Reflect Tranches — LiteSVM authorisation harness (paired privileged/unprivileged) ==");
    let mut h = Harness::new(&format!("{base}/accounts.json"), &format!("{base}/programs"), slot, ts);
    let mut results: Vec<Value> = Vec::new();
    macro_rules! rec {
        ($name:expr, $ok:expr, $err:expr) => {
            results.push(serde_json::json!({"test": $name, "succeeded": $ok, "err": $err}));
        };
    }

    let settings = a(SETTINGS);
    let system = a(SYSTEM_S);
    let rlp = h.rlp;
    let tok = h.token;
    let proxy = h.proxy;
    let event_auth = pda(&[b"__event_authority".as_ref()], &rlp);
    let sup_perm = a(PERM_SUPREMO);
    let mgr_perm = a(PERM_MANAGER);
    let supremo = a(SUPREMO);
    let manager = a(MANAGER);

    // payer keypair: only used to pay fees; sigverify is off so it need not be a signer
    let payer = Keypair::new();
    h.svm.airdrop(&payer.pubkey(), 50_000_000_000).unwrap();

    // attacker: a fresh, role-less third party that signs for real
    let attacker = Keypair::new();
    h.svm.airdrop(&attacker.pubkey(), 50_000_000_000).unwrap();
    let attacker_pk = attacker.pubkey();
    let attacker_perm = pda(&[b"permissions".as_ref(), attacker_pk.as_ref()], &rlp);

    // ======================================================= 1. permissionless registration
    println!("\n-- 1. RLP: permissionless registration grants no role --");
    let ix = Instruction {
        program_id: rlp,
        accounts: vec![meta(settings, false, false), meta(attacker_perm, false, true),
                       meta(attacker_pk, true, true), meta(system, false, false),
                       meta(event_auth, false, false), meta(rlp, false, false)],
        data: { let mut d = disc("create_permission_account").to_vec(); d.extend_from_slice(attacker_pk.as_ref()); d },
    };
    let (ok, err) = h.send(&[ix], &payer, "create_permission_account(attacker)");
    rec!("rlp_create_permission_account", ok, &err);
    let roles = h.svm.get_account(&attacker_perm).map(|x| x.data[41..].to_vec()).unwrap_or_default();
    println!("  attacker UserPermissions roles tail = {}", hex(&roles));
    rec!("rlp_attacker_roles_after_registration", false, &hex(&roles));

    // ======================================================= 2. update_action_role: paired test
    println!("\n-- 2. RLP update_action_role(action=Slash, role=PUBLIC) — attacker vs real MANAGER vs real SUPREMO --");
    let mk_uar = |signer: Address, perm: Address| Instruction {
        program_id: rlp,
        accounts: vec![meta(signer, true, true), meta(settings, false, true),
                       meta(system, false, false), meta(perm, false, true),
                       meta(event_auth, false, false), meta(rlp, false, false)],
        data: { let mut d = disc("update_action_role").to_vec(); d.extend_from_slice(&[2u8, 1u8, 0u8]); d },
    };
    let (ok, err) = h.send(&[mk_uar(attacker_pk, attacker_perm)], &attacker, "attacker (registered, EMPTY roles)");
    rec!("rlp_update_action_role_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_uar(manager, mgr_perm)], &payer, "real MANAGER");
    rec!("rlp_update_action_role_manager", ok, &err);
    let (ok, err) = h.send(&[mk_uar(supremo, sup_perm)], &payer, "real SUPREMO");
    rec!("rlp_update_action_role_supremo", ok, &err);

    // ======================================================= 3. slash: paired test
    println!("\n-- 3. RLP slash(pool0, 1 unit) — attacker vs real SUPREMO --");
    let ata_mint0 = h.set_token_account(&a(MINT0), &attacker_pk, 0);
    let ata_dest = h.set_token_account(&a(MINT0), &supremo, 0);
    let mk_slash = |signer: Address, perm: Address, dest: Address| Instruction {
        program_id: rlp,
        accounts: vec![meta(signer, true, true), meta(perm, false, true), meta(settings, false, true),
                       meta(a(POOL0), false, false), meta(a(MINT0), false, true), meta(a(ASSET0), false, true),
                       meta(a(POOL0_ATA0), false, true), meta(dest, false, true), meta(tok, false, false)],
        data: { let mut d = disc("slash").to_vec(); d.push(0u8); d.extend_from_slice(&1u64.to_le_bytes()); d },
    };
    let (ok, err) = h.send(&[mk_slash(attacker_pk, attacker_perm, ata_mint0)], &attacker, "attacker");
    rec!("rlp_slash_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_slash(supremo, sup_perm, ata_dest)], &payer, "real SUPREMO");
    rec!("rlp_slash_supremo", ok, &err);

    // ======================================================= 4. freeze_functionality: paired
    println!("\n-- 4. RLP freeze_functionality(action=Slash, freeze=true) — attacker vs real SUPREMO --");
    let mk_ff = |signer: Address, perm: Address| Instruction {
        program_id: rlp,
        accounts: vec![meta(signer, true, true), meta(settings, false, true),
                       meta(system, false, false), meta(perm, false, true),
                       meta(event_auth, false, false), meta(rlp, false, false)],
        data: { let mut d = disc("freeze_functionality").to_vec(); d.extend_from_slice(&[2u8, 1u8]); d },
    };
    let (ok, err) = h.send(&[mk_ff(attacker_pk, attacker_perm)], &attacker, "attacker");
    rec!("rlp_freeze_functionality_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_ff(supremo, sup_perm)], &payer, "real SUPREMO");
    rec!("rlp_freeze_functionality_supremo", ok, &err);

    // ======================================================= 5. withdraw: paired test
    println!("\n-- 5. RLP withdraw(cooldown H9Ai, pool6) — attacker vs the cooldown's real authority --");
    let auth_addr = a(COOLDOWN_A_AUTH);
    let mk_withdraw = |signer: Address, signer_lp: Address, signer_asset: Address| Instruction {
        program_id: rlp,
        accounts: vec![
            meta(signer, true, true), meta(settings, false, true), meta(rlp, false, false),
            meta(a(POOL_A), false, true), meta(a(LP_A), false, true), meta(signer_lp, false, true),
            meta(a(COOLDOWN_A_ESCROW), false, true), meta(a(COOLDOWN_A), false, true),
            meta(tok, false, false), meta(system, false, false),
            meta(rlp, false, false), meta(rlp, false, false),
            meta(a(PROXY_STATE_A), false, false), meta(a(PROXY_VAULT_A), false, false),
            meta(rlp, false, false), meta(rlp, false, false),
            meta(a(ASSET_A), false, false), meta(a(POOL_A_ATA), false, true),
            meta(signer_asset, false, true), meta(a(STREAM_A), false, false),
        ],
        data: { let mut d = disc("withdraw").to_vec(); d.push(6u8); d.extend_from_slice(&6u64.to_le_bytes()); d },
    };
    let atk_lp = h.set_token_account(&a(LP_A), &attacker_pk, 0);
    let atk_asset = h.set_token_account(&a(MINT_A), &attacker_pk, 0);
    let auth_lp = h.set_token_account(&a(LP_A), &auth_addr, 0);
    let auth_asset = h.set_token_account(&a(MINT_A), &auth_addr, 0);
    let (ok, err) = h.send(&[mk_withdraw(attacker_pk, atk_lp, atk_asset)], &attacker,
        "attacker on a cooldown it does not own");
    rec!("rlp_withdraw_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_withdraw(auth_addr, auth_lp, auth_asset)], &payer,
        "cooldown's real authority (positive control)");
    rec!("rlp_withdraw_real_authority", ok, &err);

    // ======================================================= 6. proxy claim_fees: paired test
    println!("\n-- 6. proxy claim_fees(ProxyState FD4Yydhz) — attacker vs the real proxy authority --");
    let mk_cf = |signer: Address, dest: Address| Instruction {
        program_id: proxy,
        accounts: vec![meta(signer, true, false), meta(dest, false, true),
                       meta(a(PROXY_STATE0), false, true), meta(a(PROXY_VAULT0), false, true),
                       meta(a(PROXY_ORACLE0), false, false), meta(a(PROXY_CFG0), false, false),
                       meta(tok, false, false), meta(a(MINT0), false, false)],
        data: vec![3u8],
    };
    let atk_usdc0 = h.set_token_account(&a(MINT0), &attacker_pk, 0);
    let auth_usdc0 = h.set_token_account(&a(MINT0), &a(PROXY_AUTH0), 0);
    let (ok, err) = h.send(&[mk_cf(attacker_pk, atk_usdc0)], &attacker, "attacker");
    rec!("proxy_claim_fees_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_cf(a(PROXY_AUTH0), auth_usdc0)], &payer, "real proxy authority (positive control)");
    rec!("proxy_claim_fees_real_authority", ok, &err);

    // ======================================================= 7. proxy unwrap layout matrix
    println!("\n-- 7. proxy unwrap: can a fresh signer burn a VICTIM's branded balance? --");
    let usdc = h.set_token_account(&a(MINT0), &attacker_pk, 0);
    let _attacker_branded = h.set_token_account(&a(BRANDED_MINT0), &attacker_pk, 0);
    let branded_victim = a(VICTIM_BRANDED0);
    let ps = a(PROXY_STATE0);
    let vault = a(PROXY_VAULT0);
    let bm = a(BRANDED_MINT0);
    let orc = a(PROXY_ORACLE0);
    let cfg = a(PROXY_CFG0);
    let tok = h.token;
    let umint = a(MINT0);
    let layouts: Vec<(&str, Vec<Address>)> = vec![
        ("L1 user,usdc,branded,ps,vault,oracle,cfg,token,mint", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, umint]),
        ("L2 +system", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, umint, system]),
        ("L3 +branded_mint", vec![attacker_pk, usdc, branded_victim, ps, vault, bm, orc, cfg, tok, umint]),
        ("L4 user,branded,usdc", vec![attacker_pk, branded_victim, usdc, ps, vault, orc, cfg, tok, umint]),
        ("L5 user,branded,usdc,system", vec![attacker_pk, branded_victim, usdc, ps, vault, orc, cfg, tok, umint, system]),
        ("L6 ...bm,oracle,cfg,token", vec![attacker_pk, usdc, branded_victim, ps, vault, bm, orc, cfg, tok]),
        ("L7 ...token,system,mint", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, system, umint]),
        ("L8 ...token,ata,mint", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, a(ATA_S), umint]),
        ("L9 ...token,mint,ata", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, umint, a(ATA_S)]),
        ("L10 ...cfg,system,token,mint", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, system, tok, umint]),
        ("L11 ...bm,oracle,cfg,token,system,mint", vec![attacker_pk, usdc, branded_victim, ps, vault, bm, orc, cfg, tok, system, umint]),
        ("L12 ...bm,oracle,cfg,token,mint,system", vec![attacker_pk, usdc, branded_victim, ps, vault, bm, orc, cfg, tok, umint, system]),
        ("L13 ...token,mint,system,ata", vec![attacker_pk, usdc, branded_victim, ps, vault, orc, cfg, tok, umint, system, a(ATA_S)]),
    ];
    let vbefore = h.bal(&branded_victim);
    for (name, order) in &layouts {
        let ix = Instruction {
            program_id: proxy,
            accounts: order.iter().enumerate().map(|(i, k)| meta(*k, i == 0, i != 0)).collect(),
            data: { let mut d = vec![2u8]; d.extend_from_slice(&1_000_000u64.to_le_bytes()); d.extend_from_slice(&0u64.to_le_bytes()); d },
        };
        let (ok, err) = h.send(&[ix], &attacker, name);
        let vafter = h.bal(&branded_victim);
        let ausdc = h.bal(&usdc);
        if ok || vafter != vbefore {
            println!("  !! victim branded {vbefore} -> {vafter}; attacker USDC+ = {ausdc}");
        }
        rec!(&format!("proxy_unwrap:{name}"), ok, &err);
        results.last_mut().unwrap()["victim_branded_before"] = serde_json::json!(vbefore);
        results.last_mut().unwrap()["victim_branded_after"] = serde_json::json!(vafter);
        results.last_mut().unwrap()["attacker_usdc_plus"] = serde_json::json!(ausdc);
    }

    // ======================================================= 8. proxy update_authority (hijack test)
    println!("\n-- 8. proxy update_authority: can a fresh signer seize a ProxyState? --");
    let new_auth = Address::new_unique();
    let mk_ua = |signer: Address| Instruction {
        program_id: proxy,
        accounts: vec![meta(signer, true, false), meta(a(PROXY_STATE0), false, true)],
        data: { let mut d = vec![5u8]; d.extend_from_slice(new_auth.as_ref()); d },
    };
    let (ok, err) = h.send(&[mk_ua(attacker_pk)], &attacker, "attacker");
    rec!("proxy_update_authority_attacker", ok, &err);
    let (ok, err) = h.send(&[mk_ua(a(PROXY_AUTH0))], &payer, "real authority (positive control)");
    rec!("proxy_update_authority_real", ok, &err);

    println!("\n{}", serde_json::to_string_pretty(&results).unwrap());
}
