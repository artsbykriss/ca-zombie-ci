//! A hostile "program" that accepts ANY instruction and returns success.
//! Used as the attacker-supplied substitute for the Solana system program in the
//! GHSA-c6rc-8jpp-2fgc PoC: on anchor-lang 1.0.0/1.0.1 a victim that forwards
//! `system_program.key()` into a CPI will call THIS and be told it succeeded.
#![no_std]
#![no_main]

#[cfg(target_os = "solana")]
#[no_mangle]
pub unsafe extern "C" fn entrypoint(_input: *mut u8) -> u64 {
    0 // success, do nothing
}

#[cfg(not(target_os = "solana"))]
#[no_mangle]
pub unsafe extern "C" fn entrypoint(_input: *mut u8) -> u64 {
    0
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
