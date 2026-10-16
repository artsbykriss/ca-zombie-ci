// Rain collateral-fleet PoC: replay the historical exploit transaction sequence
// against the current on-chain builds (and pre-incident builds) in LiteSVM.
// READ-ONLY: runs entirely in a local VM; no network transactions.
use std::str::FromStr;

use base64::Engine;
use litesvm::LiteSVM;
use serde_json::Value;
use solana_account::Account;
use solana_address::Address;
use solana_hash::Hash;
use solana_message::{compiled_instruction::CompiledInstruction, Message, MessageHeader};
use solana_signature::Signature;
use solana_transaction::Transaction;

fn addr(s: &str) -> Address {
    Address::from_str(s).expect("bad address")
}

/// Replace the compiled-in `declare_id!` bytes so a build can be loaded at the incident
/// program's address (Anchor rejects a mismatch; all constraint derivations then use the
/// runtime program id, which is what we want for replay against the real accounts).
fn patch_declared_id(elf: &[u8], from: &str, to: &str) -> Vec<u8> {
    let from_b = addr(from).to_bytes();
    let to_b = addr(to).to_bytes();
    let mut out = elf.to_vec();
    let mut count = 0usize;
    // 1) full 32-byte const (rodata)
    let mut i = 0usize;
    while i + 32 <= out.len() {
        if out[i..i + 32] == from_b {
            out[i..i + 32].copy_from_slice(&to_b);
            count += 1;
            i += 32;
        } else {
            i += 1;
        }
    }
    // 2) 4-byte chunks embedded inline as SBF immediates (lddw / compares)
    let mut chunk_count = 0usize;
    for c in 0..8 {
        let fc = &from_b[c * 4..c * 4 + 4];
        let tc = &to_b[c * 4..c * 4 + 4];
        if fc == tc {
            continue;
        }
        let mut j = 0usize;
        while j + 4 <= out.len() {
            if &out[j..j + 4] == fc {
                out[j..j + 4].copy_from_slice(tc);
                chunk_count += 1;
                j += 4;
            } else {
                j += 1;
            }
        }
    }
    eprintln!("[patch] {}: {} full const(s), {} inline chunk(s) replaced", from, count, chunk_count);
    out
}

struct Variant {
    name: &'static str,
    program_id: &'static str,
    elf: &'static str,
}

fn build_tx(decoded: &Value) -> Transaction {
    let header = &decoded["header"];
    let nreq = header["numRequiredSignatures"].as_u64().unwrap() as u8;
    let nros = header["numReadonlySignedAccounts"].as_u64().unwrap() as u8;
    let nrou = header["numReadonlyUnsignedAccounts"].as_u64().unwrap() as u8;
    let account_keys: Vec<Address> = decoded["account_keys"]
        .as_array()
        .unwrap()
        .iter()
        .map(|k| addr(k["pubkey"].as_str().unwrap()))
        .collect();
    let instructions: Vec<CompiledInstruction> = decoded["instructions"]
        .as_array()
        .unwrap()
        .iter()
        .map(|ix| CompiledInstruction {
            program_id_index: ix["program_id_index"].as_u64().unwrap() as u8,
            accounts: ix["accounts"].as_array().unwrap().iter().map(|a| a.as_u64().unwrap() as u8).collect(),
            data: base64::engine::general_purpose::STANDARD
                .decode(ix["data_b64"].as_str().unwrap())
                .unwrap(),
        })
        .collect();
    let message = Message {
        header: MessageHeader {
            num_required_signatures: nreq,
            num_readonly_signed_accounts: nros,
            num_readonly_unsigned_accounts: nrou,
        },
        account_keys,
        recent_blockhash: Hash::default(),
        instructions,
    };
    Transaction { signatures: vec![Signature::default(); nreq as usize], message }
}

fn main() {
    let base = std::env::args().nth(1).unwrap_or_else(|| "..".to_string());
    let data: Value =
        serde_json::from_str(&std::fs::read_to_string(format!("{base}/poc/data/ci_test_data.json")).unwrap())
            .unwrap();

    let variants = [
        Variant { name: "V2_aug28_26DkA98", program_id: "26DkA98jjctzPkBEteUsN935CR4dsKx3XvjrtE7MeL4a", elf: "V2_aug28.so" },
        Variant { name: "V3_sep03_9Wti", program_id: "9Wti1DaFGLyV74wCKTERFYZohxrLzvMbEmoHRrdkRZaN", elf: "V3_sep03.so" },
        Variant { name: "V4_sep09_67Ry", program_id: "67RyHr9VW9QwZCtXiVW2vBMS3kg1BS4rngrt5LxFYouX", elf: "V4_sep09.so" },
        Variant { name: "V5_oct13_yYC3", program_id: "yYC31xuL2dYbPGZovrE3fqdPB1hckLcn13ud1ewkkeR", elf: "V5_oct13.so" },
        Variant { name: "V1_aug21_C4y8t56f", program_id: "C4y8t56fmNzCsR9kNoZtBUmJ7pNEAKKyTRBvSQZredEi", elf: "V1_aug21.so" },
        Variant { name: "OLD_801160_29NTjs", program_id: "29NTjsSpTvnv25UqsmanXfGmV4iSmcPBmDyzkEwkDcNG", elf: "old_801160.so" },
    ];

    let tx_names = ["submit1", "add", "submit2", "withdraw"];

    // (json_key, pubkey, rewrite_owner_to_variant)
    let account_keys = [
        ("fee_payer", "FVNFzqAny8spWdPmYw6RQ9TkYa29ueFFiqCFD1gQnCEj", false),
        ("collateral_CHEzcULr", "CHEzcULr75DT3Ug5kaympgiETSSJVHg5CCtHXVZj9Nft", true),
        ("coordinator_26Dk", "3bB8jfvCVKsmckvhqEjsztvXFvdvaN2v7MJBPS58VfEH", true),
        ("vault_ata_H7ANUpwV", "H7ANUpwVcRExtB6wdNB6zYJ9Y9Q8EJWtC4QVvE53RzJG", false),
        ("dest_ata_6skUP5dU", "6skUP5dUhyjtStK1hChJ5s2JQmkps8LsmYe7JZ9VeKxF", false),
        ("mint_usdt", "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", false),
    ];

    let mut results: Vec<Value> = Vec::new();

    for v in &variants {
        let mut svm = LiteSVM::new()
            .with_sigverify(false)
            .with_blockhash_check(false)
            .with_sysvars()
            .with_precompiles();

        let elf_path = format!("{base}/poc/data/{}", v.elf);
        let elf_raw = std::fs::read(&elf_path).expect("elf read");
        // Load every build at the INCIDENT program's address: the historical txs invoke that
        // address, and Anchor constraints use the runtime program id (not the compiled id).
        let elf = patch_declared_id(&elf_raw, v.program_id, "26DkA98jjctzPkBEteUsN935CR4dsKx3XvjrtE7MeL4a");
        svm.add_program(addr("26DkA98jjctzPkBEteUsN935CR4dsKx3XvjrtE7MeL4a"), &elf).expect("add_program");

        // fee payer
        svm.set_account(
            addr("FVNFzqAny8spWdPmYw6RQ9TkYa29ueFFiqCFD1gQnCEj"),
            Account { lamports: 10_000_000_000, data: vec![], owner: addr("11111111111111111111111111111111"), executable: false, rent_epoch: 0 },
        ).expect("set fee payer");

        for (json_key, pubkey, rewrite_owner) in account_keys.iter() {
            if *json_key == "fee_payer" {
                continue;
            }
            let obj = match data.get(*json_key) {
                Some(o) if !o.is_null() => o,
                _ => continue,
            };
            let data_b64 = obj["data_b64"].as_str().unwrap_or("");
            let raw = base64::engine::general_purpose::STANDARD.decode(data_b64).unwrap_or_default();
            let owner = if *rewrite_owner { "26DkA98jjctzPkBEteUsN935CR4dsKx3XvjrtE7MeL4a".to_string() } else { obj["owner"].as_str().unwrap_or("11111111111111111111111111111111").to_string() };
            eprintln!("[setup] variant={} set {} owner={} len={}", v.name, pubkey, owner, raw.len());
            svm.set_account(
                addr(pubkey),
                Account { lamports: obj["lamports"].as_u64().unwrap_or(1_000_000), data: raw, owner: addr(&owner), executable: false, rent_epoch: 0 },
            ).expect("set account");
        }

        for tname in tx_names {
            let decoded = match data.get(format!("{tname}_decoded")) {
                Some(d) if !d.is_null() => d,
                _ => continue,
            };
            let tx = build_tx(decoded);
            eprintln!("[run] variant={} tx={} keys={} ixs={}", v.name, tname,
                tx.message.account_keys.len(), tx.message.instructions.len());
            match svm.send_transaction(tx) {
                Ok(meta) => {
                    let logs: Vec<String> = meta.logs.iter().rev().take(12).cloned().collect::<Vec<_>>().into_iter().rev().collect();
                    results.push(serde_json::json!({"variant": v.name, "tx": tname, "status": "OK", "logs": logs}));
                }
                Err(fail) => {
                    let logs: Vec<String> = fail.meta.logs.iter().rev().take(18).cloned().collect::<Vec<_>>().into_iter().rev().collect();
                    results.push(serde_json::json!({
                        "variant": v.name, "tx": tname, "status": "FAIL",
                        "err": format!("{:?}", fail.err), "logs": logs
                    }));
                }
            }
        }

        if let Some(acct) = svm.get_account(&addr("H7ANUpwVcRExtB6wdNB6zYJ9Y9Q8EJWtC4QVvE53RzJG")) {
            let amt = if acct.data.len() >= 72 { u64::from_le_bytes(acct.data[64..72].try_into().unwrap()) } else { 0 };
            results.push(serde_json::json!({"variant": v.name, "vault_ata_amount_raw": amt}));
        }
        if let Some(acct) = svm.get_account(&addr("6skUP5dUhyjtStK1hChJ5s2JQmkps8LsmYe7JZ9VeKxF")) {
            let amt = if acct.data.len() >= 72 { u64::from_le_bytes(acct.data[64..72].try_into().unwrap()) } else { 0 };
            results.push(serde_json::json!({"variant": v.name, "dest_ata_amount_raw": amt}));
        }
    }

    let out = serde_json::json!({"results": results});
    std::fs::write(format!("{base}/ci-out/litesvm_results.json"), serde_json::to_string_pretty(&out).unwrap()).unwrap();
    println!("{}", serde_json::to_string_pretty(&out).unwrap());
}
