#!/usr/bin/env python3
"""Scan sBPF text for call instructions and map to syscall hashes; also dump basic opcode stats."""
import struct, os, collections

OUT = os.path.dirname(os.path.abspath(__file__))
elf = open(os.path.join(OUT, "bisonfi-live.elf"), "rb").read()
e_phoff = struct.unpack_from("<Q", elf, 32)[0]
e_phnum = struct.unpack_from("<H", elf, 56)[0]
segs = []
for i in range(e_phnum):
    off = e_phoff + i * 56
    p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from("<IIQQQQQQ", elf, off)
    segs.append(dict(type=p_type, flags=p_flags, offset=p_offset, vaddr=p_vaddr, filesz=p_filesz))
text = [s for s in segs if s["flags"] == 1][0]
T = elf[text["offset"]:text["offset"]+text["filesz"]]

SYSCALLS = {
 0x207559bd: "sol_log_", 0x5c2a3178: "sol_log_64_", 0x7ef088ca: "sol_log_pubkey",
 0xd56b5fe9: "sol_get_clock_sysvar", 0xbf7188f6: "sol_get_rent_sysvar",
 0x23a29a61: "sol_get_epoch_schedule_sysvar", 0x77f9b9d0: "sol_get_last_restart_slot_sysvar",
 0xa22b9c85: "sol_invoke_signed_c", 0xd7449092: "sol_invoke_signed_rust",
 0x717cc4a3: "sol_memcpy_", 0x434371f8: "sol_memmove_", 0x3770fb22: "sol_memset_",
 0x5fdcde31: "sol_memcmp_", 0xadb8efc8: "sol_get_processed_sibling_instruction",
 0x85532d94: "sol_get_stack_height", 0x5d2245e4: "sol_get_return_data", 0xa226d3eb: "sol_set_return_data",
 0x11f49d86: "sol_sha256", 0xd7793abb: "sol_keccak256", 0x17e40350: "sol_secp256k1_recover",
 0x1a72106b: "sol_ed25519_verify", 0xae0c318b: "sol_alt_bn128_group_op", 0x174c5122: "sol_blake3",
 0x13c1b505: "sol_get_sysvar", 0x83f00e8f: "sol_alloc_free_", 0x5be92f4a: "sol_get_epoch_stake",
 0x2be35363: "sol_poseidon", 0x686093bb: "sol_curve_validate_point", 0xca93c2a4: "sol_curve_group_op",
 0xda1fd1c9: "sol_curve_multiscalar_mul", 0x23e92f24: "sol_curve_pairing_map",
 0x18d634ec: "sol_remaining_compute_units", 0xe22b9c85: "sol_invoke_signed_c2",
 0x25de0c4b: "sol_get_processed_sibling_instruction2",
}

calls = collections.Counter()
call_sites = collections.defaultdict(list)
for i in range(0, len(T) - 8, 8):
    op = T[i]
    if op == 0x85:
        imm = struct.unpack_from("<i", T, i+4)[0] & 0xFFFFFFFF
        calls[imm] += 1
        call_sites[imm].append(i)

print("=== call targets (syscalls) ===")
for imm, n in calls.most_common():
    print(f"  {imm:#010x} x{n}  {SYSCALLS.get(imm, '?')}")
    if imm not in SYSCALLS:
        print(f"      sites: {[hex(x) for x in call_sites[imm][:8]]}")

# opcode histogram
ops = collections.Counter()
for i in range(0, len(T) - 8, 8):
    ops[T[i]] += 1
print("\n=== opcode histogram (top 25) ===")
for op, n in ops.most_common(25):
    print(f"  {op:#04x} x{n}")
