# Generated with sbpf v0.3.2
# Generated on: 2026-10-23 07:34:37 UTC

.globl entrypoint

fn_0000:
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r3+0x50]
  jne r4, 0x52, jmp_00c8
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_00a0
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_00a0
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_00a0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_00a8

jmp_00a0:
  mov64 r4, 0x1

jmp_00a8:
  jeq r4, 0x0, jmp_00e0
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x16
  ja jmp_00d8

jmp_00c8:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x3

jmp_00d8:
  exit

jmp_00e0:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_0140
  ldxdw r2, [r10-0x10]
  ldxb r3, [r10-0x8]
  stxb [r6+0x10], r3
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_00d8

jmp_0140:
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0
  ja jmp_00d8

fn_0160:
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r3+0x50]
  jne r4, 0xa5, jmp_0210
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_0200
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_0200
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_0200
  mov64 r4, 0x0
  ldxdw r3, [r3+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_0208

jmp_0200:
  mov64 r4, 0x1

jmp_0208:
  jeq r4, 0x0, jmp_0228

jmp_0210:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x3

jmp_0220:
  exit

jmp_0228:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_0288
  ldxdw r2, [r10-0x10]
  ldxb r3, [r10-0x8]
  stxb [r6+0x10], r3
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_0220

jmp_0288:
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0
  ja jmp_0220

fn_02a8:
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_0308
  mov64 r1, r7
  mov64 r3, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_0320
  mov64 r2, 0x1
  ja jmp_0348

jmp_0308:
  stdw [r6+0x10], 0x0
  stdw [r6+0x8], 0x1
  ja jmp_0718

jmp_0320:
  mov64 r2, 0xa
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1, jmp_0708

jmp_0348:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_03c0
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  lddw r1, 0xfffffffe
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x8]
  ldxdw r2, [r10-0x10]
  jeq r4, 0x2, jmp_0708

jmp_03c0:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_0438
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  lddw r1, 0xfffffffc
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x18]
  ldxdw r2, [r10-0x20]
  jeq r4, 0x4, jmp_0708

jmp_0438:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_04b0
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  lddw r1, 0xfffffff8
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x28]
  ldxdw r2, [r10-0x30]
  jeq r4, 0x8, jmp_0708

jmp_04b0:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_0530
  mov64 r1, r10
  add64 r1, -0x40
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  lddw r1, 0xfffffff0
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x38]
  ldxdw r2, [r10-0x40]
  jeq r4, 0x10, jmp_0708

jmp_0530:
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_0728
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r8, r2
  mov64 r9, r3
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x78], r9
  mov64 r2, r9
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r3, [r10-0x68]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_0640
  mov64 r2, 0x0

jmp_0640:
  ldxdw r3, [r10-0x70]
  ldxdw r5, [r10-0x60]
  mov64 r4, 0x1
  ldxdw r0, [r10-0x78]
  jne r0, 0x0, jmp_0738
  mov64 r4, 0x0
  add64 r5, r3
  ldxdw r3, [r10-0x58]
  mov64 r0, 0x1
  jeq r3, 0x0, jmp_0758

jmp_0690:
  ldxdw r8, [r10-0x48]
  mov64 r3, r8
  add64 r3, r5
  jlt r3, r8, jmp_06b8

jmp_06b0:
  mov64 r1, 0x0

jmp_06b8:
  or64 r4, r0
  or64 r4, r2
  or64 r4, r1
  and64 r4, 0x1
  jne r4, 0x0, jmp_0728
  lddw r1, 0xffffffe0
  and64 r7, r1
  jne r7, 0x20, jmp_0728
  ldxdw r2, [r10-0x50]

jmp_0708:
  stxdw [r6+0x8], r2
  stxdw [r6+0x10], r3

jmp_0718:
  stdw [r6+0x0], 0x1

jmp_0720:
  exit

jmp_0728:
  stdw [r6+0x0], 0x0
  ja jmp_0720

jmp_0738:
  add64 r5, r3
  ldxdw r3, [r10-0x58]
  mov64 r0, 0x1
  jne r3, 0x0, jmp_0690

jmp_0758:
  mov64 r0, 0x0
  ldxdw r8, [r10-0x48]
  mov64 r3, r8
  add64 r3, r5
  jge r3, r8, jmp_06b0
  ja jmp_06b8

fn_0788:
  and64 r2, 0xff
  jgt r2, 0x7, jmp_07e0
  mov64 r3, 0x1
  lsh64 r3, r2
  mov64 r4, r3
  and64 r4, 0xff
  ldxb r2, [r1+0x0]
  jlt r2, r4, jmp_07f8
  sub64 r2, r3
  stxb [r1+0x0], r2
  exit

jmp_07e0:
  lddw r1, data_0810
  call fn_29a40

jmp_07f8:
  lddw r1, data_0828
  call fn_29938

fn_0810:
  mov64 r6, r1
  mov64 r1, 0x0
  jsge r3, 0x0, jmp_0848

jmp_0828:
  mov64 r2, r3
  lddw r3, data_0840
  call fn_28b00

jmp_0848:
  jeq r3, 0x0, jmp_0908
  mov64 r8, r2
  mov64 r7, r3
  call fn_25f40
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_08a0
  mov64 r2, r1

jmp_08a0:
  mov64 r4, r2
  mov64 r3, r7
  sub64 r4, r3
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r5, 0x1
  jle r4, r2, jmp_0918
  mov64 r2, r8
  jeq r5, 0x0, jmp_0930

jmp_08e8:
  lddw r4, 0x300000008
  jge r7, r4, jmp_0950
  ja jmp_0828

jmp_0908:
  mov64 r7, 0x1
  ja jmp_0968

jmp_0918:
  mov64 r5, 0x0
  mov64 r2, r8
  jne r5, 0x0, jmp_08e8

jmp_0930:
  mov64 r7, r4
  lddw r4, 0x300000008
  jlt r7, r4, jmp_0828

jmp_0950:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7

jmp_0968:
  mov64 r1, r7
  mov64 r8, r3
  call fn_2a090
  stxdw [r6+0x8], r7
  stxdw [r6+0x10], r8
  stxdw [r6+0x0], r8
  exit

fn_09a0:
  mov64 r6, r1
  mov64 r4, r10
  add64 r4, -0x20
  mov64 r1, r2
  mov64 r2, r3
  lddw r3, data_0160
  call sol_create_program_address
  jeq r0, 0x0, jmp_0a68
  lddw r2, -0x100000000
  mov64 r1, r0
  add64 r1, r2
  mov64 r2, r1
  rsh64 r2, 0x20
  lsh64 r1, 0x20
  or64 r1, r2
  jge r1, 0x1a, jmp_0ab8
  mov64 r2, r1
  lsh64 r2, 0x2
  lddw r3, data_0488
  add64 r3, r2
  ldxw r0, [r3+0x0]
  ja jmp_0ac0

jmp_0a68:
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x19], r1
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x11], r1
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x9], r1
  ldxdw r1, [r10-0x20]
  stxdw [r6+0x1], r1
  mov64 r1, 0x0
  ja jmp_0ad8

jmp_0ab8:
  mov64 r1, 0x0

jmp_0ac0:
  stxw [r6+0x8], r0
  stxw [r6+0x4], r1
  mov64 r1, 0x1

jmp_0ad8:
  stxb [r6+0x0], r1
  exit

fn_0ae8:
  mov64 r6, r2
  mov64 r4, r1
  add64 r3, 0x80
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r3
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x8]
  jne r2, 0x0, jmp_0b50
  mov64 r1, 0x0

jmp_0b50:
  ldxdw r0, [r10-0x10]
  and64 r1, 0x1
  lddw r2, 0x4000000000000000
  jne r6, r2, jmp_0b98
  jne r1, 0x0, jmp_0c60
  jslt r0, 0x0, jmp_0c60
  lsh64 r0, 0x1
  ja jmp_0c58

jmp_0b98:
  jne r1, 0x0, jmp_0c78
  mov64 r1, r0
  call fn_2bf50
  mov64 r1, r6
  mov64 r2, r0
  call fn_2b7a0
  mov64 r6, r0
  mov64 r8, 0x0
  mov64 r1, r6
  mov64 r2, 0x0
  call fn_2c2f8
  mov64 r7, r0
  mov64 r1, r6
  call fn_2b6e8
  jslt r7, 0x0, jmp_0c18
  mov64 r8, r0

jmp_0c18:
  mov64 r1, r6
  lddw r2, 0x43efffffffffffff
  call fn_2b5e8
  mov64 r1, r0
  mov64 r0, -0x1
  jsgt r1, 0x0, jmp_0c58
  mov64 r0, r8

jmp_0c58:
  exit

jmp_0c60:
  lddw r1, data_09e8
  call fn_29990

jmp_0c78:
  lddw r1, data_09d0
  call fn_29990

fn_0c90:
  jne r3, 0x7, jmp_0da8
  ldxdw r7, [r2+0x10]
  ldxb r3, [r7+0x2]
  jeq r3, 0x0, jmp_0dc0
  ldxdw r3, [r2+0x0]
  ldxb r3, [r3+0x1]
  jeq r3, 0x0, jmp_0dd0
  mov64 r8, r2
  add64 r8, 0x18
  mov64 r4, 0x3
  ldxdw r3, [r8+0x0]
  ldxdw r5, [r3+0x50]
  jne r5, 0x52, jmp_0d98
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_0d80
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_0d80
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_0d80
  mov64 r5, 0x0
  ldxdw r3, [r3+0x40]
  lddw r4, -0x56ff00817a0a73c6
  jeq r3, r4, jmp_0d88

jmp_0d80:
  mov64 r5, 0x1

jmp_0d88:
  mov64 r4, 0x16
  jeq r5, 0x0, jmp_0df8

jmp_0d98:
  stxdw [r1+0x8], r4
  ja jmp_0de8

jmp_0da8:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_0df0

jmp_0dc0:
  stdw [r1+0x8], 0x0
  ja jmp_0de8

jmp_0dd0:
  lddw r2, 0x800000000
  stxdw [r1+0x8], r2

jmp_0de8:
  stdw [r1+0x0], 0x0

jmp_0df0:
  exit

jmp_0df8:
  stxdw [r10-0x28], r2
  mov64 r9, r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r8
  call fn_28528
  ldxdw r6, [r10-0x20]
  jeq r6, 0x0, jmp_0f68
  ldxb r4, [r10-0x8]
  ldxdw r0, [r10-0x10]
  ldxb r3, [r6+0x0]
  mov64 r1, r9
  ldxdw r2, [r10-0x28]
  jne r3, 0x1, jmp_0ef0
  stxdw [r10-0x30], r4
  ldxdw r3, [r7+0x8]
  ldxdw r4, [r6+0x4]
  jne r4, r3, jmp_0ed8
  ldxdw r3, [r7+0x10]
  ldxdw r4, [r6+0xc]
  jne r4, r3, jmp_0ed8
  ldxdw r3, [r7+0x18]
  ldxdw r4, [r6+0x14]
  jne r4, r3, jmp_0ed8
  mov64 r3, 0x0
  ldxdw r4, [r7+0x20]
  ldxdw r5, [r6+0x1c]
  jeq r5, r4, jmp_0ee0

jmp_0ed8:
  mov64 r3, 0x1

jmp_0ee0:
  ldxdw r4, [r10-0x30]
  jeq r3, 0x0, jmp_0f80

jmp_0ef0:
  lddw r2, 0x100000000
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  mov64 r2, r4
  jgt r2, 0x7, jmp_1040

jmp_0f20:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r0+0x0]
  jlt r2, r3, jmp_1520
  sub64 r2, r1
  stxb [r0+0x0], r2
  ja jmp_0df0

jmp_0f68:
  ldxdw r4, [r10-0x18]
  mov64 r1, r9
  ja jmp_0d98

jmp_0f80:
  ldxb r3, [r6+0x2e]
  jne r3, 0x1, jmp_1010
  ldxdw r3, [r7+0x8]
  ldxdw r4, [r6+0x32]
  jne r4, r3, jmp_0ff8
  ldxdw r3, [r7+0x10]
  ldxdw r4, [r6+0x3a]
  jne r4, r3, jmp_0ff8
  ldxdw r3, [r7+0x18]
  ldxdw r4, [r6+0x42]
  jne r4, r3, jmp_0ff8
  mov64 r3, 0x0
  ldxdw r4, [r7+0x20]
  ldxdw r5, [r6+0x4a]
  jeq r5, r4, jmp_1000

jmp_0ff8:
  mov64 r3, 0x1

jmp_1000:
  ldxdw r4, [r10-0x30]
  jeq r3, 0x0, jmp_1058

jmp_1010:
  lddw r2, 0x200000000
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  mov64 r2, r4
  jle r2, 0x7, jmp_0f20

jmp_1040:
  lddw r1, data_0810
  call fn_29a40

jmp_1058:
  add64 r2, 0x28
  stxdw [r10-0x38], r2
  ldxdw r3, [r2+0x0]
  ldxdw r2, [r3+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r2, r4, jmp_10f8
  ldxdw r2, [r3+0x30]
  lddw r4, 0x626c582b5813378e
  jne r2, r4, jmp_10f8
  ldxdw r2, [r3+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r2, r4, jmp_10f8
  mov64 r4, 0x0
  ldxdw r2, [r3+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r2, r5, jmp_1100

jmp_10f8:
  mov64 r4, 0x1

jmp_1100:
  lddw r2, 0x900000000
  jne r4, 0x0, jmp_1318
  lddw r2, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_1318
  stxdw [r10-0x40], r0
  mov64 r1, r10
  add64 r1, -0x20
  ldxdw r2, [r10-0x38]
  call fn_28528
  ldxw r2, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxdw r3, [r10-0x20]
  jeq r3, 0x0, jmp_12e8
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_1538
  ldxb r2, [r10-0x8]
  ldxdw r1, [r10-0x10]
  ldxb r7, [r3+0x23]
  call fn_0788
  lddw r2, 0x2600000000
  mov64 r1, r9
  ldxdw r0, [r10-0x40]
  jne r7, 0x2, jmp_1318
  mov64 r1, r10
  add64 r1, -0x20
  ldxdw r2, [r10-0x38]
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_1300
  ldxb r7, [r10-0x8]
  ldxdw r2, [r10-0x10]
  stxdw [r10-0x48], r2
  ldxb r2, [r1+0x20]
  jne r2, 0x1, jmp_1348
  ldxdw r2, [r10-0x28]
  add64 r2, 0x20
  ldxdw r3, [r1+0x0]
  stxdw [r10-0x50], r2
  ldxdw r2, [r2+0x0]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_12c0
  ldxdw r3, [r1+0x8]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_12c0
  ldxdw r3, [r1+0x10]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_12c0
  mov64 r3, 0x0
  ldxdw r1, [r1+0x18]
  ldxdw r2, [r2+0x20]
  jeq r2, r1, jmp_12c8

jmp_12c0:
  mov64 r3, 0x1

jmp_12c8:
  jeq r3, 0x0, jmp_13a8
  lddw r1, 0x500000000
  ja jmp_1358

jmp_12e8:
  lsh64 r2, 0x20
  or64 r2, r1
  ja jmp_1308

jmp_1300:
  ldxdw r2, [r10-0x18]

jmp_1308:
  mov64 r1, r9
  ldxdw r0, [r10-0x40]

jmp_1318:
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  ldxdw r4, [r10-0x30]
  mov64 r2, r4
  jle r2, 0x7, jmp_0f20
  ja jmp_1040

jmp_1348:
  lddw r1, 0x1200000000

jmp_1358:
  stxdw [r9+0x8], r1

jmp_1360:
  stdw [r9+0x0], 0x0

jmp_1368:
  ldxdw r1, [r10-0x48]
  mov64 r2, r7
  call fn_0788
  ldxdw r0, [r10-0x40]
  ldxdw r4, [r10-0x30]
  mov64 r2, r4
  jle r2, 0x7, jmp_0f20
  ja jmp_1040

jmp_13a8:
  mov64 r1, r10
  add64 r1, -0x20
  ldxdw r2, [r10-0x50]
  call fn_0000
  ldxw r1, [r10-0x14]
  ldxw r2, [r10-0x18]
  ldxdw r4, [r10-0x20]
  jeq r4, 0x0, jmp_1460
  lsh64 r1, 0x20
  or64 r1, r2
  mov64 r3, 0x3
  ldxdw r2, [r10-0x10]
  ldxb r4, [r4+0x2c]
  ldxb r5, [r6+0x2c]
  jne r5, r4, jmp_1438
  mov64 r3, 0x17
  ldxdw r4, [r6+0x24]
  jeq r4, 0x0, jmp_1478

jmp_1438:
  stxw [r9+0xc], r3
  stw [r9+0x8], 0x0
  stdw [r9+0x0], 0x0
  call fn_0788
  ja jmp_1368

jmp_1460:
  stxw [r9+0xc], r1
  stxw [r9+0x8], r2
  ja jmp_1360

jmp_1478:
  ldxdw r3, [r10-0x28]
  mov64 r4, r3
  add64 r4, 0x10
  mov64 r5, r3
  add64 r5, 0x8
  ldxdw r0, [r10-0x38]
  stxdw [r9+0x28], r0
  ldxdw r0, [r10-0x50]
  stxdw [r9+0x20], r0
  stxdw [r9+0x18], r8
  stxdw [r9+0x10], r4
  stxdw [r9+0x8], r5
  stxdw [r9+0x0], r3
  call fn_0788
  ldxdw r1, [r10-0x48]
  mov64 r2, r7
  call fn_0788
  ldxdw r1, [r10-0x40]
  ldxdw r2, [r10-0x30]
  call fn_0788
  ja jmp_0df0

jmp_1520:
  lddw r1, data_0828
  call fn_29938

jmp_1538:
  mov64 r1, 0x23
  lddw r3, data_0e38
  call fn_28b70

fn_1558:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r9, [r7+0x30]
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  lddw r2, str_036a
  stxdw [r10-0xc8], r2
  add64 r1, 0x8
  stxdw [r10-0xb8], r1
  stxdw [r10-0xa8], r9
  stdw [r10-0xa0], 0x1
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x5
  mov64 r1, r10
  add64 r1, -0x78
  call fn_28928
  ldxw r1, [r10-0x78]
  jne r1, 0x1, jmp_1608
  ldxw r1, [r10-0x70]
  ldxw r2, [r10-0x74]
  ja jmp_1dd8

jmp_1608:
  stxdw [r10-0x110], r9
  stxdw [r10-0x108], r8
  mov64 r1, r10
  add64 r1, -0xd8
  ldxdw r2, [r10-0x70]
  mov64 r3, 0x0
  mov64 r4, 0x11c
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0xd0]
  jne r2, 0x0, jmp_1670
  mov64 r1, 0x0

jmp_1670:
  ldxdw r8, [r10-0xd8]
  ldxdw r9, [r10-0x68]
  lddw r2, 0x4000000000000000
  jne r9, r2, jmp_1798
  and64 r1, 0x1
  jne r1, 0x0, jmp_2100
  jslt r8, 0x0, jmp_2100
  lsh64 r8, 0x1
  ldxdw r9, [r7+0x10]
  ldxdw r1, [r9+0x0]
  ldxdw r1, [r1+0x48]
  jne r1, 0x0, jmp_1888

jmp_16d8:
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x60], r8
  stxdw [r10-0x70], r9
  stxdw [r10-0x78], r1
  lddw r1, data_0160
  stxdw [r10-0x68], r1
  stdw [r10-0x58], 0x9c
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r4, 0x1
  call fn_28250
  ldxw r2, [r10-0xf8]
  jeq r2, 0x1a, jmp_1a20
  ldxw r1, [r10-0xf4]
  ja jmp_1dd8

jmp_1798:
  stxdw [r10-0x100], r6
  and64 r1, 0x1
  jne r1, 0x0, jmp_2118
  mov64 r1, r8
  call fn_2bf50
  mov64 r1, r9
  mov64 r2, r0
  call fn_2b7a0
  mov64 r8, r0
  mov64 r6, 0x0
  mov64 r1, r8
  mov64 r2, 0x0
  call fn_2c2f8
  mov64 r9, r0
  mov64 r1, r8
  call fn_2b6e8
  jslt r9, 0x0, jmp_1828
  mov64 r6, r0

jmp_1828:
  mov64 r1, r8
  lddw r2, 0x43efffffffffffff
  call fn_2b5e8
  mov64 r8, -0x1
  jsgt r0, 0x0, jmp_1860
  mov64 r8, r6

jmp_1860:
  ldxdw r6, [r10-0x100]
  ldxdw r9, [r7+0x10]
  ldxdw r1, [r9+0x0]
  ldxdw r1, [r1+0x48]
  jeq r1, 0x0, jmp_16d8

jmp_1888:
  stxdw [r10-0x10], r9
  stdw [r10-0x8], 0x9c
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x78], r1
  stdw [r10-0x70], 0x3
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x78
  mov64 r4, 0x1
  call fn_27da8
  ldxw r2, [r10-0xe0]
  jne r2, 0x1a, jmp_1d70
  lddw r1, data_0160
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r9
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x78], r1
  stdw [r10-0x70], 0x3
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x78
  mov64 r4, 0x1
  call fn_27fe0
  ldxw r2, [r10-0xe8]
  jne r2, 0x1a, jmp_1d80
  ldxdw r1, [r9+0x0]
  ldxdw r1, [r1+0x48]
  jle r8, r1, jmp_1a20
  sub64 r8, r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x68], r8
  stxdw [r10-0x70], r9
  stxdw [r10-0x78], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_283e0
  ldxw r2, [r10-0xf0]
  jne r2, 0x1a, jmp_1d90

jmp_1a20:
  stxdw [r10-0x100], r6
  ldxdw r8, [r7+0x28]
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r1+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r2, r3, jmp_1ac0
  ldxdw r2, [r1+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_1ac0
  ldxdw r2, [r1+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_1ac0
  mov64 r3, 0x0
  ldxdw r2, [r1+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r2, r4, jmp_1ac8

jmp_1ac0:
  mov64 r3, 0x1

jmp_1ac8:
  lddw r2, 0x900000000
  jne r3, 0x0, jmp_1dc0
  lddw r2, 0xa00000000
  ldxdw r1, [r1+0x50]
  jne r1, 0x103, jmp_1dc0
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r8
  call fn_28528
  ldxw r2, [r10-0x6c]
  ldxw r1, [r10-0x70]
  ldxdw r3, [r10-0x78]
  jeq r3, 0x0, jmp_1da0
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_2130
  ldxb r2, [r10-0x60]
  ldxdw r1, [r10-0x68]
  ldxb r6, [r3+0x23]
  call fn_0788
  lddw r2, 0x2600000000
  jne r6, 0x2, jmp_1dc0
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r8
  call fn_28528
  ldxdw r3, [r10-0x78]
  jeq r3, 0x0, jmp_1db8
  ldxb r2, [r10-0x60]
  ldxdw r1, [r10-0x68]
  ldxdw r4, [r3+0x0]
  stxdw [r10-0x98], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x90], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x88], r4
  ldxdw r3, [r3+0x18]
  stxdw [r10-0x80], r3
  jgt r2, 0x7, jmp_2150
  mov64 r3, 0x1
  lsh64 r3, r2
  mov64 r4, r3
  and64 r4, 0xff
  ldxb r2, [r1+0x0]
  jlt r2, r4, jmp_2168
  sub64 r2, r3
  stxb [r1+0x0], r2
  ldxdw r1, [r9+0x0]
  ldxdw r2, [r1+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  ldxdw r6, [r10-0x100]
  jne r2, r3, jmp_1cf0
  ldxdw r2, [r1+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_1cf0
  ldxdw r2, [r1+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_1cf0
  mov64 r3, 0x0
  ldxdw r2, [r1+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r2, r4, jmp_1cf8

jmp_1cf0:
  mov64 r3, 0x1

jmp_1cf8:
  lddw r2, 0x900000000
  jne r3, 0x0, jmp_1d58
  lddw r2, 0xa00000000
  ldxdw r3, [r1+0x50]
  jne r3, 0x9c, jmp_1d58
  mov64 r2, 0xb
  ldxb r3, [r1+0x0]
  mov64 r4, r3
  and64 r4, 0xf
  jeq r4, 0x0, jmp_1df0

jmp_1d58:
  mov64 r1, r2
  rsh64 r1, 0x20
  ja jmp_1dd8

jmp_1d70:
  ldxw r1, [r10-0xdc]
  ja jmp_1dd8

jmp_1d80:
  ldxw r1, [r10-0xe4]
  ja jmp_1dd8

jmp_1d90:
  ldxw r1, [r10-0xec]
  ja jmp_1dd8

jmp_1da0:
  lsh64 r2, 0x20
  or64 r2, r1
  ja jmp_1dc0

jmp_1db8:
  ldxdw r2, [r10-0x70]

jmp_1dc0:
  mov64 r1, r2
  rsh64 r1, 0x20

jmp_1dd0:
  ldxdw r6, [r10-0x100]

jmp_1dd8:
  stxw [r6+0x4], r1
  stxw [r6+0x0], r2
  exit

jmp_1df0:
  mov64 r2, r3
  or64 r2, 0x8
  stxb [r1+0x0], r2
  ldxdw r2, [r10-0x108]
  ldxdw r0, [r2+0x0]
  ldxh r2, [r7+0x38]
  ldxdw r4, [r7+0x0]
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r5+0x20]
  stxdw [r10-0x60], r6
  ldxdw r6, [r5+0x18]
  stxdw [r10-0x68], r6
  ldxdw r6, [r5+0x10]
  stxdw [r10-0x70], r6
  ldxdw r5, [r5+0x8]
  stxdw [r10-0x78], r5
  ldxdw r5, [r10-0x110]
  ldxb r5, [r5+0x0]
  ldxdw r6, [r0+0x8]
  ldxdw r7, [r0+0x10]
  ldxdw r8, [r0+0x18]
  ldxdw r0, [r0+0x20]
  stxdw [r1+0x70], r0
  stxdw [r1+0x68], r8
  stxdw [r1+0x60], r7
  stxdw [r1+0x58], r6
  ldxdw r0, [r10-0x98]
  stxdw [r1+0x78], r0
  ldxdw r0, [r10-0x90]
  stxdw [r1+0x80], r0
  ldxdw r0, [r10-0x88]
  stxdw [r1+0x88], r0
  ldxdw r0, [r10-0x80]
  stxdw [r1+0x90], r0
  jge r2, 0x2711, jmp_20e0
  stxh [r1+0x98], r2
  stdw [r1+0x9a], 0x0
  stdw [r1+0xa2], 0x0
  ldxdw r0, [r10-0x78]
  stxdw [r1+0xaa], r0
  ldxdw r0, [r10-0x70]
  stxdw [r1+0xb2], r0
  ldxdw r0, [r10-0x68]
  stxdw [r1+0xba], r0
  ldxdw r0, [r10-0x60]
  stxdw [r1+0xc2], r0
  stxb [r1+0xca], r5
  stdw [r1+0xd4], 0x0
  stdw [r1+0xcc], 0x0
  stb [r1+0xcb], 0x0
  stdw [r1+0xdc], 0x0
  stdw [r1+0xe4], 0x0
  stdw [r1+0xec], 0x0
  stxb [r1+0x0], r3
  ldxdw r1, [r10-0x108]
  ldxdw r1, [r1+0x0]
  ldxdw r3, [r4+0x0]
  ldxdw r4, [r9+0x0]
  stb [r10-0x78], 0x0
  ldxdw r5, [r4+0x20]
  stxdw [r10-0x5f], r5
  ldxdw r5, [r4+0x18]
  stxdw [r10-0x67], r5
  ldxdw r5, [r4+0x10]
  stxdw [r10-0x6f], r5
  ldxdw r4, [r4+0x8]
  stxdw [r10-0x77], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x57], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x4f], r4
  ldxdw r4, [r3+0x18]
  stxdw [r10-0x47], r4
  ldxdw r3, [r3+0x20]
  stxdw [r10-0x3f], r3
  ldxdw r3, [r1+0x20]
  ldxdw r4, [r1+0x18]
  ldxdw r5, [r1+0x10]
  ldxdw r1, [r1+0x8]
  stxh [r10-0x17], r2
  stxdw [r10-0x37], r1
  stxdw [r10-0x2f], r5
  stxdw [r10-0x27], r4
  stxdw [r10-0x1f], r3
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x63
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r2, 0x1a
  ja jmp_1dd0

jmp_20e0:
  stxb [r1+0x0], r3
  mov64 r2, 0x0
  mov64 r1, 0xb
  ja jmp_1dd0

jmp_2100:
  lddw r1, data_09e8
  call fn_29990

jmp_2118:
  lddw r1, data_09d0
  call fn_29990

jmp_2130:
  mov64 r1, 0x23
  lddw r3, data_0e38
  call fn_28b70

jmp_2150:
  lddw r1, data_0810
  call fn_29a40

jmp_2168:
  lddw r1, data_0828
  call fn_29938

fn_2180:
  jne r3, 0x2, jmp_2380
  ldxdw r3, [r2+0x8]
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2398
  ldxdw r7, [r2+0x0]
  ldxb r4, [r7+0x1]
  jeq r4, 0x0, jmp_23a8
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_2240
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_2240
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_2240
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_2248

jmp_2240:
  mov64 r4, 0x1

jmp_2248:
  lddw r5, 0x900000000
  jne r4, 0x0, jmp_23d8
  lddw r5, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_23d8
  mov64 r8, r1
  mov64 r9, r2
  mov64 r6, r2
  add64 r6, 0x8
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_23c8
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r1+0x52]
  jne r3, r2, jmp_2338
  ldxdw r2, [r7+0x10]
  ldxdw r3, [r1+0x5a]
  jne r3, r2, jmp_2338
  ldxdw r2, [r7+0x18]
  ldxdw r3, [r1+0x62]
  jne r3, r2, jmp_2338
  mov64 r2, 0x0
  ldxdw r3, [r7+0x20]
  ldxdw r1, [r1+0x6a]
  jeq r1, r3, jmp_2340

jmp_2338:
  mov64 r2, 0x1

jmp_2340:
  ldxb r3, [r10-0x8]
  ldxdw r1, [r10-0x10]
  jeq r2, 0x0, jmp_23f0
  lddw r2, 0x1000000000
  stxdw [r8+0x8], r2
  stdw [r8+0x0], 0x0
  ja jmp_2400

jmp_2380:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_23e8

jmp_2398:
  stdw [r1+0x8], 0x0
  ja jmp_23e0

jmp_23a8:
  lddw r2, 0x800000000
  stxdw [r1+0x8], r2
  ja jmp_23e0

jmp_23c8:
  ldxdw r5, [r10-0x18]
  mov64 r1, r8

jmp_23d8:
  stxdw [r1+0x8], r5

jmp_23e0:
  stdw [r1+0x0], 0x0

jmp_23e8:
  exit

jmp_23f0:
  stxdw [r8+0x8], r6
  stxdw [r8+0x0], r9

jmp_2400:
  jgt r3, 0x7, jmp_2450
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_2468
  sub64 r3, r2
  stxb [r1+0x0], r3
  ja jmp_23e8

jmp_2450:
  lddw r1, data_0810
  call fn_29a40

jmp_2468:
  lddw r1, data_0828
  call fn_29938

fn_2480:
  jle r3, 0x5, jmp_2558
  ldxdw r8, [r2+0x28]
  ldxdw r4, [r8+0x8]
  add64 r8, 0x8
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_2520
  ldxdw r4, [r8+0x8]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_2520
  ldxdw r4, [r8+0x10]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_2520
  mov64 r4, 0x0
  ldxdw r5, [r8+0x18]
  lddw r0, -0x56ff00817a0a73c6
  jeq r5, r0, jmp_2528

jmp_2520:
  mov64 r4, 0x1

jmp_2528:
  jeq r4, 0x0, jmp_2570
  lddw r2, 0x1800000000

jmp_2540:
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  ja jmp_2568

jmp_2558:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa

jmp_2568:
  exit

jmp_2570:
  mov64 r6, r2
  add64 r6, 0x8
  ldxdw r9, [r6+0x0]
  ldxb r4, [r9+0x2]
  jeq r4, 0x0, jmp_2778
  ldxdw r7, [r2+0x0]
  ldxb r4, [r7+0x1]
  jeq r4, 0x0, jmp_2790
  ldxdw r4, [r9+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_2638
  ldxdw r4, [r9+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_2638
  ldxdw r4, [r9+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_2638
  mov64 r4, 0x0
  ldxdw r5, [r9+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_2640

jmp_2638:
  mov64 r4, 0x1

jmp_2640:
  lddw r5, 0x900000000
  jne r4, 0x0, jmp_27b8
  lddw r5, 0xa00000000
  ldxdw r4, [r9+0x50]
  jne r4, 0x9c, jmp_27b8
  stxdw [r10-0xc0], r3
  stxdw [r10-0xb8], r2
  stxdw [r10-0xb0], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  call fn_28528
  ldxdw r4, [r10-0x30]
  jeq r4, 0x0, jmp_27a8
  ldxdw r1, [r7+0x8]
  ldxdw r2, [r4+0x52]
  jne r2, r1, jmp_2728
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r4+0x5a]
  jne r2, r1, jmp_2728
  ldxdw r1, [r7+0x18]
  ldxdw r2, [r4+0x62]
  jne r2, r1, jmp_2728
  mov64 r1, 0x0
  ldxdw r2, [r7+0x20]
  ldxdw r3, [r4+0x6a]
  jeq r3, r2, jmp_2730

jmp_2728:
  mov64 r1, 0x1

jmp_2730:
  ldxb r3, [r10-0x18]
  ldxdw r7, [r10-0x20]
  ldxdw r2, [r10-0xb0]
  jeq r1, 0x0, jmp_27d0
  lddw r1, 0x1000000000
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_2b10

jmp_2778:
  stdw [r1+0x8], 0x0
  stdw [r1+0x0], 0x0
  ja jmp_2568

jmp_2790:
  lddw r2, 0x800000000
  ja jmp_2540

jmp_27a8:
  ldxdw r5, [r10-0x28]
  ldxdw r1, [r10-0xb0]

jmp_27b8:
  stxdw [r1+0x8], r5
  stdw [r1+0x0], 0x0
  ja jmp_2568

jmp_27d0:
  stxdw [r10-0xc8], r3
  stxdw [r10-0x78], r8
  add64 r9, 0x8
  stxdw [r10-0x88], r9
  add64 r4, 0x20
  mov64 r9, r4
  stxdw [r10-0x68], r4
  stdw [r10-0x60], 0x20
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x20
  stb [r10-0x58], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r2, 0x3
  lddw r3, data_00a0
  call sol_try_find_program_address
  jne r0, 0x0, jmp_2be8
  ldxdw r8, [r10-0xb8]
  add64 r8, 0x10
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa0], r1
  ldxdw r2, [r10-0x30]
  stxdw [r10-0xa8], r2
  ldxdw r1, [r8+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_2938
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0xa0]
  jne r2, r3, jmp_2938
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x98]
  jne r2, r3, jmp_2938
  mov64 r2, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r10-0x90]
  jeq r1, r3, jmp_2940

jmp_2938:
  mov64 r2, 0x1

jmp_2940:
  ldxdw r1, [r10-0xb0]
  jeq r2, 0x0, jmp_2978
  lddw r2, 0x600000000
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  ja jmp_2b08

jmp_2978:
  stxdw [r10-0x78], r9
  lddw r1, str_036f
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x5
  stb [r10-0x31], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x31
  mov64 r2, 0x2
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_2be8
  ldxdw r1, [r10-0xb8]
  mov64 r2, r1
  add64 r2, 0x20
  ldxdw r3, [r10-0x18]
  stxdw [r10-0x40], r3
  ldxdw r3, [r10-0x20]
  stxdw [r10-0x48], r3
  ldxdw r3, [r10-0x28]
  stxdw [r10-0x50], r3
  ldxdw r5, [r10-0x30]
  stxdw [r10-0x58], r5
  ldxdw r4, [r2+0x0]
  ldxdw r0, [r4+0x8]
  ldxdw r3, [r10-0xc0]
  jne r0, r5, jmp_2ad0
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r10-0x50]
  jne r5, r0, jmp_2ad0
  ldxdw r5, [r4+0x18]
  ldxdw r0, [r10-0x48]
  jne r5, r0, jmp_2ad0
  mov64 r5, 0x0
  ldxdw r4, [r4+0x20]
  ldxdw r0, [r10-0x40]
  jeq r4, r0, jmp_2ad8

jmp_2ad0:
  mov64 r5, 0x1

jmp_2ad8:
  ldxdw r4, [r10-0xb0]
  jeq r5, 0x0, jmp_2b68
  lddw r1, 0x1300000000
  stxdw [r4+0x8], r1
  stdw [r4+0x0], 0x0

jmp_2b08:
  ldxdw r3, [r10-0xc8]

jmp_2b10:
  mov64 r2, r3
  jgt r2, 0x7, jmp_2c48
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r7+0x0]
  jlt r2, r3, jmp_2c60
  sub64 r2, r1
  stxb [r7+0x0], r2
  ja jmp_2568

jmp_2b68:
  add64 r3, -0x6
  mov64 r5, r1
  add64 r5, 0x30
  mov64 r0, r1
  add64 r0, 0x18
  stxdw [r4+0x30], r3
  stxdw [r4+0x28], r5
  stxdw [r4+0x20], r2
  stxdw [r4+0x18], r0
  stxdw [r4+0x10], r8
  stxdw [r4+0x8], r6
  stxdw [r4+0x0], r1
  mov64 r1, r7
  ldxdw r2, [r10-0xc8]
  call fn_0788
  ja jmp_2568

jmp_2be8:
  lddw r1, data_09a8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_09b8
  call fn_28b40

jmp_2c48:
  lddw r1, data_0810
  call fn_29a40

jmp_2c60:
  lddw r1, data_0828
  call fn_29938

fn_2c78:
  ldxdw r7, [r2+0x20]
  ldxdw r3, [r7+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_2d10
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_2d10
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_2d10
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_2d18

jmp_2d10:
  mov64 r4, 0x1

jmp_2d18:
  lddw r6, 0x900000000
  jne r4, 0x0, jmp_2ee0
  lddw r6, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_2ee0
  mov64 r9, r2
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r7
  call fn_28528
  ldxw r6, [r10-0x2c]
  ldxw r1, [r10-0x30]
  ldxdw r2, [r10-0x38]
  jeq r2, 0x0, jmp_2eb8
  lsh64 r6, 0x20
  or64 r6, r1
  jlt r6, 0x24, jmp_3238
  ldxb r1, [r10-0x20]
  mov64 r5, r1
  mov64 r1, r8
  jgt r5, 0x7, jmp_3208
  ldxdw r3, [r10-0x28]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r3+0x0]
  jlt r5, r0, jmp_3220
  ldxb r2, [r2+0x23]
  sub64 r5, r4
  stxb [r3+0x0], r5
  lddw r6, 0x2600000000
  jne r2, 0x2, jmp_2ee0
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r7
  call fn_28528
  ldxdw r2, [r10-0x38]
  jeq r2, 0x0, jmp_2ed0
  ldxb r3, [r10-0x20]
  ldxdw r7, [r10-0x28]
  ldxb r1, [r2+0x26]
  and64 r1, 0x1
  jne r1, 0x0, jmp_2f08
  mov64 r2, 0x2c
  mov64 r6, 0x0
  mov64 r1, r8
  ja jmp_2f78

jmp_2eb8:
  lsh64 r6, 0x20
  or64 r6, r1
  ja jmp_2ed8

jmp_2ed0:
  ldxdw r6, [r10-0x30]

jmp_2ed8:
  mov64 r1, r8

jmp_2ee0:
  mov64 r2, r6
  rsh64 r2, 0x20

jmp_2ef0:
  stxw [r1+0x4], r2
  stxw [r1+0x0], r6
  exit

jmp_2f08:
  stxdw [r10-0x60], r3
  mov64 r1, r9
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x28]
  ldxdw r5, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0x38
  call fn_196a8
  ldxw r2, [r10-0x34]
  ldxw r6, [r10-0x38]
  ldxh r1, [r10-0x24]
  jne r1, 0x2, jmp_2fd0
  mov64 r1, r8
  ldxdw r3, [r10-0x60]

jmp_2f78:
  mov64 r4, r3
  jgt r4, 0x7, jmp_3208
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r7+0x0]
  jlt r4, r5, jmp_3220
  sub64 r4, r3
  stxb [r7+0x0], r4
  ja jmp_2ef0

jmp_2fd0:
  ldxw r3, [r10-0x28]
  stxw [r10-0x40], r3
  ldxdw r3, [r10-0x30]
  stxdw [r10-0x48], r3
  ldxh r3, [r10-0x22]
  stxh [r10-0x3a], r3
  stxh [r10-0x3c], r1
  stxw [r10-0x4c], r2
  stxw [r10-0x50], r6
  ldxdw r1, [r10-0x60]
  mov64 r3, r1
  mov64 r1, r8
  jgt r3, 0x7, jmp_3208
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r5, r2
  and64 r5, 0xff
  ldxb r4, [r7+0x0]
  mov64 r3, r9
  jlt r4, r5, jmp_3220
  sub64 r4, r2
  stxb [r7+0x0], r4
  mov64 r6, 0x0
  mov64 r2, 0x11
  ldxdw r5, [r3+0x8]
  ldxdw r7, [r5+0x0]
  ldxb r4, [r7+0xcb]
  jeq r4, 0x1, jmp_2ef0
  stxdw [r10-0x60], r5
  ldxdw r4, [r3+0x10]
  mov64 r2, r7
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r3, r10
  add64 r3, -0x50
  call fn_1a570
  ldxw r1, [r10-0x58]
  jne r1, 0x1a, jmp_31e8
  mov64 r2, 0xb
  ldxh r3, [r9+0x38]
  mov64 r1, r8
  jgt r3, 0x2710, jmp_2ef0
  stxh [r7+0x98], r3
  ldxdw r1, [r10-0x60]
  ldxdw r1, [r1+0x0]
  stb [r10-0x38], 0x4
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x37], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x27], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x1f], r1
  stxh [r10-0x17], r3
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x23
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r1, r8
  mov64 r6, 0x1a
  ja jmp_2ef0

jmp_31e8:
  ldxw r2, [r10-0x54]
  mov64 r6, r1
  mov64 r1, r8
  ja jmp_2ef0

jmp_3208:
  lddw r1, data_0810
  call fn_29a40

jmp_3220:
  lddw r1, data_0828
  call fn_29938

jmp_3238:
  mov64 r1, 0x23
  mov64 r2, r6
  lddw r3, data_0e38
  call fn_28b70

fn_3260:
  jne r3, 0x2, jmp_34c0
  ldxdw r3, [r2+0x8]
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_34d8
  ldxdw r7, [r2+0x0]
  ldxb r4, [r7+0x1]
  jeq r4, 0x0, jmp_34e8
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_3320
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_3320
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_3320
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_3328

jmp_3320:
  mov64 r4, 0x1

jmp_3328:
  lddw r5, 0x900000000
  jne r4, 0x0, jmp_3518
  lddw r5, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_3518
  mov64 r8, r1
  mov64 r9, r2
  mov64 r6, r2
  add64 r6, 0x8
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r2, [r10-0x20]
  jeq r2, 0x0, jmp_3508
  ldxdw r1, [r2+0x7c]
  jne r1, 0x0, jmp_33f0
  ldxdw r1, [r2+0x84]
  jne r1, 0x0, jmp_33f0
  ldxdw r1, [r2+0x8c]
  jne r1, 0x0, jmp_33f0
  ldxdw r1, [r2+0x94]
  jeq r1, 0x0, jmp_3598

jmp_33f0:
  mov64 r0, 0x1

jmp_33f8:
  mov64 r3, r8
  mov64 r5, r9
  ldxb r4, [r10-0x8]
  ldxdw r1, [r10-0x10]
  jeq r0, 0x0, jmp_3498
  ldxdw r0, [r7+0x8]
  ldxdw r8, [r2+0x7c]
  jne r8, r0, jmp_3488
  ldxdw r0, [r7+0x10]
  ldxdw r8, [r2+0x84]
  jne r8, r0, jmp_3488
  ldxdw r0, [r7+0x18]
  ldxdw r8, [r2+0x8c]
  jne r8, r0, jmp_3488
  mov64 r0, 0x0
  ldxdw r7, [r7+0x20]
  ldxdw r2, [r2+0x94]
  jeq r2, r7, jmp_3490

jmp_3488:
  mov64 r0, 0x1

jmp_3490:
  jeq r0, 0x0, jmp_3530

jmp_3498:
  lddw r2, 0x1000000000
  stxdw [r3+0x8], r2
  stdw [r3+0x0], 0x0
  ja jmp_3540

jmp_34c0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_3528

jmp_34d8:
  stdw [r1+0x8], 0x0
  ja jmp_3520

jmp_34e8:
  lddw r2, 0x800000000
  stxdw [r1+0x8], r2
  ja jmp_3520

jmp_3508:
  ldxdw r5, [r10-0x18]
  mov64 r1, r8

jmp_3518:
  stxdw [r1+0x8], r5

jmp_3520:
  stdw [r1+0x0], 0x0

jmp_3528:
  exit

jmp_3530:
  stxdw [r3+0x8], r6
  stxdw [r3+0x0], r5

jmp_3540:
  mov64 r3, r4
  jgt r3, 0x7, jmp_35a8
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_35c0
  sub64 r3, r2
  stxb [r1+0x0], r3
  ja jmp_3528

jmp_3598:
  mov64 r0, 0x0
  ja jmp_33f8

jmp_35a8:
  lddw r1, data_0810
  call fn_29a40

jmp_35c0:
  lddw r1, data_0828
  call fn_29938

fn_35d8:
  jle r3, 0x9, jmp_36c0
  ldxdw r7, [r2+0x18]
  ldxb r4, [r7+0x2]
  jeq r4, 0x0, jmp_36d8
  ldxdw r6, [r2+0x40]
  ldxdw r4, [r6+0x8]
  add64 r6, 0x8
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_3690
  ldxdw r4, [r6+0x8]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_3690
  ldxdw r4, [r6+0x10]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_3690
  mov64 r4, 0x0
  ldxdw r5, [r6+0x18]
  lddw r0, -0x56ff00817a0a73c6
  jeq r5, r0, jmp_3698

jmp_3690:
  mov64 r4, 0x1

jmp_3698:
  jeq r4, 0x0, jmp_36e8
  lddw r2, 0x1800000000
  stxdw [r1+0x8], r2
  ja jmp_3a30

jmp_36c0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_3a38

jmp_36d8:
  stdw [r1+0x8], 0x0
  ja jmp_3a30

jmp_36e8:
  ldxdw r4, [r7+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_3770
  ldxdw r4, [r7+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_3770
  ldxdw r4, [r7+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_3770
  mov64 r5, 0x0
  ldxdw r4, [r7+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r4, r0, jmp_3778

jmp_3770:
  mov64 r5, 0x1

jmp_3778:
  lddw r4, 0x900000000
  jne r5, 0x0, jmp_3a28
  lddw r4, 0xa00000000
  ldxdw r5, [r7+0x50]
  jne r5, 0x9c, jmp_3a28
  stxdw [r10-0xc0], r3
  stxdw [r10-0xb0], r1
  stxdw [r10-0xb8], r2
  mov64 r8, r2
  add64 r8, 0x18
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r8
  call fn_28528
  ldxdw r4, [r10-0x30]
  jeq r4, 0x0, jmp_3a18
  ldxdw r9, [r10-0xb8]
  add64 r9, 0x10
  mov64 r1, 0x3
  ldxb r5, [r10-0x18]
  ldxdw r0, [r10-0x20]
  ldxdw r3, [r9+0x0]
  ldxdw r2, [r3+0x50]
  jne r2, 0xa5, jmp_3a40
  stxdw [r10-0xd0], r4
  stxdw [r10-0xc8], r5
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  ldxdw r2, [r10-0xb0]
  jne r4, r5, jmp_38e8
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_38e8
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_38e8
  mov64 r4, 0x0
  ldxdw r3, [r3+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_38f0

jmp_38e8:
  mov64 r4, 0x1

jmp_38f0:
  ldxdw r5, [r10-0xc8]
  jne r4, 0x0, jmp_3a48
  stxdw [r10-0xd8], r0
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r9
  call fn_28528
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_3ab0
  ldxdw r3, [r1+0x20]
  ldxdw r2, [r10-0xb8]
  ldxdw r2, [r2+0x0]
  ldxdw r4, [r2+0x8]
  jne r3, r4, jmp_39b0
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r1+0x28]
  jne r4, r3, jmp_39b0
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r1+0x30]
  jne r4, r3, jmp_39b0
  mov64 r3, 0x0
  ldxdw r2, [r2+0x20]
  ldxdw r4, [r1+0x38]
  jeq r4, r2, jmp_39b8

jmp_39b0:
  mov64 r3, 0x1

jmp_39b8:
  ldxb r2, [r10-0x18]
  stxdw [r10-0xe0], r2
  ldxdw r4, [r10-0x20]
  ldxdw r2, [r10-0xb0]
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]
  jeq r3, 0x0, jmp_3af8
  lddw r1, 0x400000000
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_3f98

jmp_3a18:
  ldxdw r4, [r10-0x28]
  ldxdw r1, [r10-0xb0]

jmp_3a28:
  stxdw [r1+0x8], r4

jmp_3a30:
  stdw [r1+0x0], 0x0

jmp_3a38:
  exit

jmp_3a40:
  ldxdw r2, [r10-0xb0]

jmp_3a48:
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  mov64 r2, r5
  jgt r2, 0x7, jmp_4000

jmp_3a68:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r0+0x0]
  jlt r2, r3, jmp_4188
  sub64 r2, r1
  stxb [r0+0x0], r2
  ja jmp_3a38

jmp_3ab0:
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0xb0]
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  mov64 r2, r5
  jle r2, 0x7, jmp_3a68
  ja jmp_4000

jmp_3af8:
  stxdw [r10-0xe8], r4
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r1+0x0]
  jne r4, r3, jmp_3b88
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x8]
  ldxdw r4, [r1+0x8]
  jne r4, r3, jmp_3b88
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x10]
  ldxdw r4, [r1+0x10]
  jne r4, r3, jmp_3b88
  mov64 r3, 0x0
  ldxdw r4, [r10-0xd0]
  ldxdw r4, [r4+0x18]
  ldxdw r1, [r1+0x18]
  jeq r1, r4, jmp_3b90

jmp_3b88:
  mov64 r3, 0x1

jmp_3b90:
  jeq r3, 0x0, jmp_3bc0
  lddw r1, 0x500000000
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_3f90

jmp_3bc0:
  stxdw [r10-0x78], r6
  add64 r7, 0x8
  stxdw [r10-0x88], r7
  ldxdw r1, [r10-0xd0]
  add64 r1, 0x20
  mov64 r7, r1
  stxdw [r10-0x68], r1
  stdw [r10-0x60], 0x20
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x20
  stb [r10-0x58], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r2, 0x3
  lddw r3, data_00a0
  call sol_try_find_program_address
  jne r0, 0x0, jmp_4128
  ldxdw r6, [r10-0xb8]
  add64 r6, 0x20
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa0], r1
  ldxdw r2, [r10-0x30]
  stxdw [r10-0xa8], r2
  ldxdw r1, [r6+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_3d28
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0xa0]
  jne r2, r3, jmp_3d28
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x98]
  jne r2, r3, jmp_3d28
  mov64 r2, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r10-0x90]
  jeq r1, r3, jmp_3d30

jmp_3d28:
  mov64 r2, 0x1

jmp_3d30:
  jeq r2, 0x0, jmp_3d68
  lddw r1, 0x600000000
  ldxdw r2, [r10-0xb0]
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_3f80

jmp_3d68:
  stxdw [r10-0x78], r7
  lddw r1, str_036f
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x5
  stb [r10-0x31], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x31
  mov64 r2, 0x2
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_4128
  ldxdw r1, [r10-0xb8]
  add64 r1, 0x38
  ldxdw r2, [r10-0x18]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x20]
  stxdw [r10-0x48], r2
  ldxdw r2, [r10-0x28]
  stxdw [r10-0x50], r2
  ldxdw r3, [r10-0x30]
  stxdw [r10-0x58], r3
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_3eb0
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r10-0x50]
  jne r3, r4, jmp_3eb0
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r10-0x48]
  jne r3, r4, jmp_3eb0
  mov64 r3, 0x0
  ldxdw r2, [r2+0x20]
  ldxdw r4, [r10-0x40]
  jeq r2, r4, jmp_3eb8

jmp_3eb0:
  mov64 r3, 0x1

jmp_3eb8:
  mov64 r5, 0x13
  jne r3, 0x0, jmp_3f60
  ldxdw r0, [r10-0xb8]
  add64 r0, 0x48
  ldxdw r4, [r7+0x0]
  ldxdw r3, [r0+0x0]
  ldxdw r5, [r3+0x8]
  jne r5, r4, jmp_3f48
  ldxdw r4, [r7+0x8]
  ldxdw r5, [r3+0x10]
  jne r5, r4, jmp_3f48
  ldxdw r4, [r7+0x10]
  ldxdw r5, [r3+0x18]
  jne r5, r4, jmp_3f48
  mov64 r4, 0x0
  ldxdw r5, [r7+0x18]
  ldxdw r3, [r3+0x20]
  jeq r3, r5, jmp_3f50

jmp_3f48:
  mov64 r4, 0x1

jmp_3f50:
  mov64 r5, 0x5
  jeq r4, 0x0, jmp_4018

jmp_3f60:
  ldxdw r1, [r10-0xb0]
  stxw [r1+0xc], r5
  stw [r1+0x8], 0x0
  stdw [r1+0x0], 0x0

jmp_3f80:
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]

jmp_3f90:
  ldxdw r4, [r10-0xe8]

jmp_3f98:
  ldxdw r1, [r10-0xe0]
  mov64 r2, r1
  jgt r2, 0x7, jmp_4000
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_4188
  sub64 r2, r1
  stxb [r4+0x0], r2
  mov64 r2, r5
  jle r2, 0x7, jmp_3a68

jmp_4000:
  lddw r1, data_0810
  call fn_29a40

jmp_4018:
  ldxdw r3, [r10-0xc0]
  add64 r3, -0xa
  ldxdw r4, [r10-0xb8]
  mov64 r5, r4
  add64 r5, 0x50
  mov64 r2, r4
  add64 r2, 0x30
  stxdw [r10-0xd0], r2
  mov64 r7, r4
  add64 r7, 0x28
  mov64 r2, r4
  add64 r2, 0x8
  stxdw [r10-0xc0], r2
  ldxdw r2, [r10-0xb0]
  stxdw [r2+0x50], r3
  stxdw [r2+0x48], r5
  stxdw [r2+0x40], r0
  stxdw [r2+0x38], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r2+0x30], r1
  stxdw [r2+0x28], r7
  stxdw [r2+0x20], r6
  stxdw [r2+0x18], r8
  stxdw [r2+0x10], r9
  ldxdw r1, [r10-0xc0]
  stxdw [r2+0x8], r1
  stxdw [r2+0x0], r4
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xe0]
  call fn_0788
  ldxdw r1, [r10-0xd8]
  ldxdw r2, [r10-0xc8]
  call fn_0788
  ja jmp_3a38

jmp_4128:
  lddw r1, data_09a8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_09b8
  call fn_28b40

jmp_4188:
  lddw r1, data_0828
  call fn_29938

fn_41a0:
  mov64 r3, r2
  ldxdw r6, [r3+0x38]
  ldxdw r4, [r6+0x0]
  ldxdw r2, [r4+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r2, r5, jmp_4240
  ldxdw r2, [r4+0x30]
  lddw r5, 0x626c582b5813378e
  jne r2, r5, jmp_4240
  ldxdw r2, [r4+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r2, r5, jmp_4240
  mov64 r5, 0x0
  ldxdw r2, [r4+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r2, r0, jmp_4248

jmp_4240:
  mov64 r5, 0x1

jmp_4248:
  lddw r2, 0x900000000
  jne r5, 0x0, jmp_4820
  lddw r2, 0xa00000000
  ldxdw r4, [r4+0x50]
  jne r4, 0x103, jmp_4820
  mov64 r9, r3
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  call fn_28528
  ldxw r2, [r10-0x24]
  ldxw r1, [r10-0x28]
  ldxdw r3, [r10-0x30]
  jeq r3, 0x0, jmp_43e0
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_48a0
  ldxb r1, [r10-0x18]
  mov64 r5, r1
  mov64 r1, r8
  jgt r5, 0x7, jmp_4870
  ldxdw r2, [r10-0x20]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r2+0x0]
  jlt r5, r0, jmp_4888
  ldxb r3, [r3+0x23]
  sub64 r5, r4
  stxb [r2+0x0], r5
  lddw r2, 0x2600000000
  jne r3, 0x2, jmp_4820
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  call fn_28528
  ldxdw r2, [r10-0x30]
  jeq r2, 0x0, jmp_4810
  ldxb r7, [r10-0x18]
  ldxdw r6, [r10-0x20]
  ldxb r1, [r2+0x26]
  and64 r1, 0x1
  jne r1, 0x0, jmp_43f8
  mov64 r3, 0x2c
  mov64 r2, 0x0
  ja jmp_4450

jmp_43e0:
  lsh64 r2, 0x20
  or64 r2, r1
  ja jmp_4818

jmp_43f8:
  mov64 r1, r9
  ldxdw r3, [r1+0x30]
  ldxdw r4, [r1+0x48]
  ldxdw r5, [r1+0x50]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_196a8
  ldxw r3, [r10-0x2c]
  ldxw r2, [r10-0x30]
  ldxh r1, [r10-0x1c]
  jne r1, 0x2, jmp_44b0

jmp_4450:
  mov64 r1, r8
  mov64 r5, r7
  jgt r5, 0x7, jmp_4870
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r6+0x0]
  jlt r5, r0, jmp_4888
  sub64 r5, r4
  stxb [r6+0x0], r5
  ja jmp_4830

jmp_44b0:
  ldxw r4, [r10-0x20]
  stxw [r10-0x38], r4
  ldxdw r4, [r10-0x28]
  stxdw [r10-0x40], r4
  ldxh r4, [r10-0x1a]
  stxh [r10-0x32], r4
  stxh [r10-0x34], r1
  stxw [r10-0x44], r3
  stxw [r10-0x48], r2
  mov64 r1, r7
  jgt r1, 0x7, jmp_4870
  mov64 r2, 0x1
  lsh64 r2, r1
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r6+0x0]
  mov64 r1, r9
  jlt r3, r4, jmp_4888
  sub64 r3, r2
  stxb [r6+0x0], r3
  ldxdw r6, [r1+0x20]
  ldxdw r7, [r1+0x58]
  ldxdw r3, [r1+0x28]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x60]
  ldxdw r1, [r1+0x18]
  ldxdw r2, [r1+0x0]
  stxdw [r10-0xfe0], r5
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r4
  stxdw [r10-0x1000], r3
  stxdw [r10-0xfe8], r7
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r3, r10
  add64 r3, -0x48
  mov64 r5, r10
  mov64 r4, r6
  call fn_1b670
  ldxw r2, [r10-0x50]
  jne r2, 0x1a, jmp_4848
  mov64 r2, 0x3
  mov64 r1, r9
  ldxdw r5, [r1+0x40]
  ldxdw r3, [r5+0x0]
  ldxdw r4, [r3+0x50]
  mov64 r1, r8
  jne r4, 0x52, jmp_4820
  ldxdw r2, [r3+0x28]
  lddw r4, -0x6c5e9a281e0922fa
  jne r2, r4, jmp_46c0
  ldxdw r2, [r3+0x30]
  lddw r4, -0x53861431b91e3427
  jne r2, r4, jmp_46c0
  ldxdw r2, [r3+0x38]
  lddw r4, -0x6ec8a4a0127a4be4
  jne r2, r4, jmp_46c0
  mov64 r4, 0x0
  ldxdw r2, [r3+0x40]
  lddw r3, -0x56ff00817a0a73c6
  jeq r2, r3, jmp_46c8

jmp_46c0:
  mov64 r4, 0x1

jmp_46c8:
  mov64 r2, 0x16
  jne r4, 0x0, jmp_4820
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x60], r5
  mov64 r2, r5
  call fn_28528
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_4810
  ldxb r4, [r10-0x18]
  jgt r4, 0x7, jmp_4870
  ldxdw r2, [r10-0x20]
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jlt r4, r5, jmp_4888
  ldxb r1, [r1+0x2c]
  sub64 r4, r3
  stxb [r2+0x0], r4
  ldxdw r2, [r9+0x8]
  ldxdw r3, [r9+0x0]
  stxb [r10-0x8], r1
  stxdw [r10-0x10], r7
  stxdw [r10-0x18], r3
  stxdw [r10-0x20], r6
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x28], r1
  stxdw [r10-0x30], r2
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r2, r10
  add64 r2, -0x30
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_276f0
  ldxw r2, [r10-0x58]
  jne r2, 0x1a, jmp_4860
  mov64 r2, 0x1a
  ja jmp_4850

jmp_4810:
  ldxdw r2, [r10-0x28]

jmp_4818:
  mov64 r1, r8

jmp_4820:
  mov64 r3, r2
  rsh64 r3, 0x20

jmp_4830:
  stxw [r1+0x4], r3
  stxw [r1+0x0], r2
  exit

jmp_4848:
  ldxw r3, [r10-0x4c]

jmp_4850:
  mov64 r1, r8
  ja jmp_4830

jmp_4860:
  ldxw r3, [r10-0x54]
  ja jmp_4850

jmp_4870:
  lddw r1, data_0810
  call fn_29a40

jmp_4888:
  lddw r1, data_0828
  call fn_29938

jmp_48a0:
  mov64 r1, 0x23
  lddw r3, data_0e38
  call fn_28b70

fn_48c0:
  jle r3, 0x9, jmp_49a8
  ldxdw r7, [r2+0x18]
  ldxb r4, [r7+0x2]
  jeq r4, 0x0, jmp_49c0
  ldxdw r6, [r2+0x40]
  ldxdw r4, [r6+0x8]
  add64 r6, 0x8
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_4978
  ldxdw r4, [r6+0x8]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_4978
  ldxdw r4, [r6+0x10]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_4978
  mov64 r4, 0x0
  ldxdw r5, [r6+0x18]
  lddw r0, -0x56ff00817a0a73c6
  jeq r5, r0, jmp_4980

jmp_4978:
  mov64 r4, 0x1

jmp_4980:
  jeq r4, 0x0, jmp_49d0
  lddw r2, 0x1800000000
  stxdw [r1+0x8], r2
  ja jmp_4e40

jmp_49a8:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_4e48

jmp_49c0:
  stdw [r1+0x8], 0x0
  ja jmp_4e40

jmp_49d0:
  ldxdw r4, [r7+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_4a58
  ldxdw r4, [r7+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_4a58
  ldxdw r4, [r7+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_4a58
  mov64 r5, 0x0
  ldxdw r4, [r7+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r4, r0, jmp_4a60

jmp_4a58:
  mov64 r5, 0x1

jmp_4a60:
  lddw r4, 0x900000000
  jne r5, 0x0, jmp_4e38
  lddw r4, 0xa00000000
  ldxdw r5, [r7+0x50]
  jne r5, 0x9c, jmp_4e38
  stxdw [r10-0xc0], r3
  stxdw [r10-0xb0], r1
  stxdw [r10-0xb8], r2
  mov64 r9, r2
  add64 r9, 0x18
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r9
  call fn_28528
  ldxdw r4, [r10-0x30]
  jeq r4, 0x0, jmp_4e28
  ldxdw r8, [r10-0xb8]
  add64 r8, 0x10
  mov64 r1, 0x3
  ldxb r5, [r10-0x18]
  ldxdw r0, [r10-0x20]
  ldxdw r3, [r8+0x0]
  ldxdw r2, [r3+0x50]
  jne r2, 0xa5, jmp_4e50
  stxdw [r10-0xd0], r4
  stxdw [r10-0xc8], r5
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  ldxdw r2, [r10-0xb0]
  jne r4, r5, jmp_4bd0
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_4bd0
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_4bd0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_4bd8

jmp_4bd0:
  mov64 r4, 0x1

jmp_4bd8:
  ldxdw r5, [r10-0xc8]
  jne r4, 0x0, jmp_4e58
  stxdw [r10-0xd8], r0
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r8
  call fn_28528
  ldxdw r5, [r10-0x30]
  jeq r5, 0x0, jmp_4ec0
  ldxdw r4, [r10-0xb8]
  add64 r4, 0x8
  mov64 r1, 0x3
  ldxb r2, [r10-0x18]
  stxdw [r10-0xe8], r2
  ldxdw r2, [r10-0x20]
  stxdw [r10-0xe0], r2
  ldxdw r3, [r4+0x0]
  ldxdw r2, [r3+0x50]
  jne r2, 0xa5, jmp_4f10
  stxdw [r10-0xf8], r5
  stxdw [r10-0xf0], r4
  ldxdw r4, [r3+0x28]
  lddw r5, -0x6c5e9a281e0922fa
  ldxdw r2, [r10-0xb0]
  ldxdw r0, [r10-0xd8]
  jne r4, r5, jmp_4d18
  ldxdw r4, [r3+0x30]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_4d18
  ldxdw r4, [r3+0x38]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_4d18
  mov64 r4, 0x0
  ldxdw r3, [r3+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_4d20

jmp_4d18:
  mov64 r4, 0x1

jmp_4d20:
  ldxdw r5, [r10-0xc8]
  jne r4, 0x0, jmp_4f28
  mov64 r1, r10
  add64 r1, -0x30
  ldxdw r2, [r10-0xf0]
  call fn_28528
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_4f08
  ldxdw r0, [r10-0xf8]
  ldxdw r3, [r0+0x20]
  ldxdw r2, [r10-0xb8]
  ldxdw r2, [r2+0x0]
  ldxdw r4, [r2+0x8]
  jne r3, r4, jmp_4de0
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r0+0x28]
  jne r4, r3, jmp_4de0
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r0+0x30]
  jne r4, r3, jmp_4de0
  mov64 r3, 0x0
  ldxdw r4, [r2+0x20]
  ldxdw r5, [r0+0x38]
  jeq r5, r4, jmp_4de8

jmp_4de0:
  mov64 r3, 0x1

jmp_4de8:
  ldxb r4, [r10-0x18]
  stxdw [r10-0x108], r4
  ldxdw r4, [r10-0x20]
  stxdw [r10-0x100], r4
  jeq r3, 0x0, jmp_4fc0

jmp_4e10:
  lddw r1, 0x400000000
  ja jmp_5068

jmp_4e28:
  ldxdw r4, [r10-0x28]
  ldxdw r1, [r10-0xb0]

jmp_4e38:
  stxdw [r1+0x8], r4

jmp_4e40:
  stdw [r1+0x0], 0x0

jmp_4e48:
  exit

jmp_4e50:
  ldxdw r2, [r10-0xb0]

jmp_4e58:
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  mov64 r2, r5
  jgt r2, 0x7, jmp_4fa8

jmp_4e78:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r0+0x0]
  jlt r2, r3, jmp_5640
  sub64 r2, r1
  stxb [r0+0x0], r2
  ja jmp_4e48

jmp_4ec0:
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0xb0]
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  mov64 r2, r5
  jle r2, 0x7, jmp_4e78
  ja jmp_4fa8

jmp_4f08:
  ldxdw r1, [r10-0x28]

jmp_4f10:
  ldxdw r2, [r10-0xb0]
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]

jmp_4f28:
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ldxdw r4, [r10-0xe0]
  ldxdw r1, [r10-0xe8]
  mov64 r2, r1
  jgt r2, 0x7, jmp_4fa8

jmp_4f58:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_5640
  sub64 r2, r1
  stxb [r4+0x0], r2
  mov64 r2, r5
  jle r2, 0x7, jmp_4e78

jmp_4fa8:
  lddw r1, data_0810
  call fn_29a40

jmp_4fc0:
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r0+0x0]
  jne r4, r3, jmp_5048
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x8]
  ldxdw r4, [r0+0x8]
  jne r4, r3, jmp_5048
  ldxdw r3, [r10-0xd0]
  ldxdw r3, [r3+0x10]
  ldxdw r4, [r0+0x10]
  jne r4, r3, jmp_5048
  mov64 r3, 0x0
  ldxdw r4, [r10-0xd0]
  ldxdw r4, [r4+0x18]
  ldxdw r5, [r0+0x18]
  jeq r5, r4, jmp_5050

jmp_5048:
  mov64 r3, 0x1

jmp_5050:
  jeq r3, 0x0, jmp_5118
  lddw r1, 0x500000000

jmp_5068:
  ldxdw r2, [r10-0xb0]
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0

jmp_5080:
  ldxdw r0, [r10-0xd8]
  ldxdw r5, [r10-0xc8]
  ldxdw r4, [r10-0xe0]
  ldxdw r1, [r10-0x108]
  mov64 r2, r1
  ldxdw r6, [r10-0x100]
  jgt r2, 0x7, jmp_4fa8
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r6+0x0]
  jlt r2, r3, jmp_5640
  sub64 r2, r1
  stxb [r6+0x0], r2
  ldxdw r1, [r10-0xe8]
  mov64 r2, r1
  jle r2, 0x7, jmp_4f58
  ja jmp_4fa8

jmp_5118:
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r1+0x20]
  jne r4, r3, jmp_5180
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r1+0x28]
  jne r4, r3, jmp_5180
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r1+0x30]
  jne r4, r3, jmp_5180
  mov64 r3, 0x0
  ldxdw r2, [r2+0x20]
  ldxdw r1, [r1+0x38]
  jeq r1, r2, jmp_5188

jmp_5180:
  mov64 r3, 0x1

jmp_5188:
  jne r3, 0x0, jmp_4e10
  stxdw [r10-0x78], r6
  add64 r7, 0x8
  stxdw [r10-0x88], r7
  ldxdw r1, [r10-0xd0]
  add64 r1, 0x20
  mov64 r7, r1
  stxdw [r10-0x68], r1
  stdw [r10-0x60], 0x20
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x20
  stb [r10-0x58], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r2, 0x3
  lddw r3, data_00a0
  call sol_try_find_program_address
  jne r0, 0x0, jmp_5658
  ldxdw r6, [r10-0xb8]
  add64 r6, 0x20
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa0], r1
  ldxdw r2, [r10-0x30]
  stxdw [r10-0xa8], r2
  ldxdw r1, [r6+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_52f8
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0xa0]
  jne r2, r3, jmp_52f8
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x98]
  jne r2, r3, jmp_52f8
  mov64 r2, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r10-0x90]
  jeq r1, r3, jmp_5300

jmp_52f8:
  mov64 r2, 0x1

jmp_5300:
  jeq r2, 0x0, jmp_5320
  lddw r1, 0x600000000
  ja jmp_5068

jmp_5320:
  stxdw [r10-0x78], r7
  lddw r1, str_036f
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x5
  stb [r10-0x31], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x31
  mov64 r2, 0x2
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_5658
  ldxdw r1, [r10-0xb8]
  add64 r1, 0x38
  ldxdw r2, [r10-0x18]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x20]
  stxdw [r10-0x48], r2
  ldxdw r2, [r10-0x28]
  stxdw [r10-0x50], r2
  ldxdw r3, [r10-0x30]
  stxdw [r10-0x58], r3
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_5468
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r10-0x50]
  jne r3, r4, jmp_5468
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r10-0x48]
  jne r3, r4, jmp_5468
  mov64 r3, 0x0
  ldxdw r2, [r2+0x20]
  ldxdw r4, [r10-0x40]
  jeq r2, r4, jmp_5470

jmp_5468:
  mov64 r3, 0x1

jmp_5470:
  mov64 r5, 0x13
  jne r3, 0x0, jmp_5518
  ldxdw r0, [r10-0xb8]
  add64 r0, 0x48
  ldxdw r4, [r7+0x0]
  ldxdw r3, [r0+0x0]
  ldxdw r5, [r3+0x8]
  jne r5, r4, jmp_5500
  ldxdw r4, [r7+0x8]
  ldxdw r5, [r3+0x10]
  jne r5, r4, jmp_5500
  ldxdw r4, [r7+0x10]
  ldxdw r5, [r3+0x18]
  jne r5, r4, jmp_5500
  mov64 r4, 0x0
  ldxdw r5, [r7+0x18]
  ldxdw r3, [r3+0x20]
  jeq r3, r5, jmp_5508

jmp_5500:
  mov64 r4, 0x1

jmp_5508:
  mov64 r5, 0x5
  jeq r4, 0x0, jmp_5540

jmp_5518:
  ldxdw r1, [r10-0xb0]
  stxw [r1+0xc], r5
  stw [r1+0x8], 0x0
  stdw [r1+0x0], 0x0
  ja jmp_5080

jmp_5540:
  ldxdw r3, [r10-0xc0]
  add64 r3, -0xa
  ldxdw r7, [r10-0xb8]
  mov64 r5, r7
  add64 r5, 0x50
  mov64 r4, r7
  add64 r4, 0x30
  add64 r7, 0x28
  ldxdw r2, [r10-0xb0]
  stxdw [r2+0x50], r3
  stxdw [r2+0x48], r5
  stxdw [r2+0x40], r0
  stxdw [r2+0x38], r1
  stxdw [r2+0x30], r4
  stxdw [r2+0x28], r7
  stxdw [r2+0x20], r6
  stxdw [r2+0x18], r9
  stxdw [r2+0x10], r8
  ldxdw r1, [r10-0xf0]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0xb8]
  stxdw [r2+0x0], r1
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0x108]
  call fn_0788
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xe8]
  call fn_0788
  ldxdw r1, [r10-0xd8]
  ldxdw r2, [r10-0xc8]
  call fn_0788
  ja jmp_4e48

jmp_5640:
  lddw r1, data_0828
  call fn_29938

jmp_5658:
  lddw r1, data_09a8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_09b8
  call fn_28b40

fn_56b8:
  ldxdw r6, [r2+0x38]
  ldxdw r3, [r6+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_5750
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_5750
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_5750
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_5758

jmp_5750:
  mov64 r4, 0x1

jmp_5758:
  lddw r0, 0x900000000
  jne r4, 0x0, jmp_5918
  lddw r0, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_5918
  mov64 r8, r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r6
  call fn_28528
  ldxw r0, [r10-0x1c]
  ldxw r1, [r10-0x20]
  ldxdw r2, [r10-0x28]
  jeq r2, 0x0, jmp_58f0
  lsh64 r0, 0x20
  or64 r0, r1
  jlt r0, 0x24, jmp_5c30
  ldxb r1, [r10-0x10]
  mov64 r5, r1
  mov64 r1, r7
  jgt r5, 0x7, jmp_5c00
  ldxdw r3, [r10-0x18]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r3+0x0]
  jlt r5, r0, jmp_5c18
  ldxb r2, [r2+0x23]
  sub64 r5, r4
  stxb [r3+0x0], r5
  lddw r0, 0x2600000000
  jne r2, 0x2, jmp_5918
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r6
  call fn_28528
  ldxdw r2, [r10-0x28]
  jeq r2, 0x0, jmp_5908
  ldxb r9, [r10-0x10]
  ldxdw r6, [r10-0x18]
  ldxb r1, [r2+0x26]
  and64 r1, 0x1
  jne r1, 0x0, jmp_5940
  mov64 r2, 0x2c
  mov64 r0, 0x0
  ja jmp_5998

jmp_58f0:
  lsh64 r0, 0x20
  or64 r0, r1
  ja jmp_5910

jmp_5908:
  ldxdw r0, [r10-0x20]

jmp_5910:
  mov64 r1, r7

jmp_5918:
  mov64 r2, r0
  rsh64 r2, 0x20

jmp_5928:
  stxw [r1+0x4], r2
  stxw [r1+0x0], r0
  exit

jmp_5940:
  mov64 r1, r8
  ldxdw r3, [r1+0x30]
  ldxdw r4, [r1+0x48]
  ldxdw r5, [r1+0x50]
  mov64 r1, r10
  add64 r1, -0x28
  call fn_196a8
  ldxw r2, [r10-0x24]
  ldxw r0, [r10-0x28]
  ldxh r1, [r10-0x14]
  jne r1, 0x2, jmp_59f8

jmp_5998:
  mov64 r1, r7
  mov64 r4, r9
  jgt r4, 0x7, jmp_5c00
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r6+0x0]
  jlt r4, r5, jmp_5c18
  sub64 r4, r3
  stxb [r6+0x0], r4
  ja jmp_5928

jmp_59f8:
  ldxw r3, [r10-0x18]
  stxw [r10-0x30], r3
  ldxdw r3, [r10-0x20]
  stxdw [r10-0x38], r3
  ldxh r3, [r10-0x12]
  stxh [r10-0x2a], r3
  stxh [r10-0x2c], r1
  stxw [r10-0x3c], r2
  stxw [r10-0x40], r0
  mov64 r1, r9
  jgt r1, 0x7, jmp_5c00
  mov64 r2, 0x1
  lsh64 r2, r1
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r6+0x0]
  mov64 r1, r8
  jlt r3, r4, jmp_5c18
  sub64 r3, r2
  stxb [r6+0x0], r3
  ldxdw r4, [r1+0x8]
  ldxdw r3, [r1+0x20]
  ldxdw r6, [r1+0x28]
  ldxdw r9, [r1+0x58]
  ldxdw r2, [r1+0x40]
  ldxdw r5, [r1+0x60]
  ldxdw r0, [r1+0x18]
  ldxdw r1, [r0+0x0]
  stxdw [r10-0xfe0], r5
  stxdw [r10-0xff0], r0
  stxdw [r10-0x1000], r2
  stxdw [r10-0xfe8], r9
  stxdw [r10-0xff8], r6
  add64 r1, 0x58
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r5, r10
  call fn_1d440
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_5bf0
  ldxdw r1, [r8+0x10]
  ldxdw r3, [r8+0x0]
  stxb [r10-0x8], r2
  stxdw [r10-0x10], r9
  stxdw [r10-0x18], r3
  stxdw [r10-0x20], r6
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r2, r10
  add64 r2, -0x28
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_26ff8
  ldxw r0, [r10-0x48]
  jne r0, 0x1a, jmp_5be8
  mov64 r0, 0x1a
  ja jmp_5bf0

jmp_5be8:
  ldxw r2, [r10-0x44]

jmp_5bf0:
  mov64 r1, r7
  ja jmp_5928

jmp_5c00:
  lddw r1, data_0810
  call fn_29a40

jmp_5c18:
  lddw r1, data_0828
  call fn_29938

jmp_5c30:
  mov64 r1, 0x23
  mov64 r2, r0
  lddw r3, data_0e38
  call fn_28b70

fn_5c58:
  jle r3, 0x7, jmp_5d50
  ldxdw r6, [r2+0x10]
  ldxb r4, [r6+0x2]
  jeq r4, 0x0, jmp_5d68
  ldxdw r8, [r2+0x0]
  ldxb r4, [r8+0x1]
  jeq r4, 0x0, jmp_5d78
  ldxdw r7, [r2+0x30]
  ldxdw r4, [r7+0x8]
  add64 r7, 0x8
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_5d28
  ldxdw r4, [r7+0x8]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_5d28
  ldxdw r4, [r7+0x10]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_5d28
  mov64 r4, 0x0
  ldxdw r5, [r7+0x18]
  lddw r0, -0x56ff00817a0a73c6
  jeq r5, r0, jmp_5d30

jmp_5d28:
  mov64 r4, 0x1

jmp_5d30:
  jeq r4, 0x0, jmp_5d98
  lddw r2, 0x1800000000
  ja jmp_5d88

jmp_5d50:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_5f90

jmp_5d68:
  stdw [r1+0x8], 0x0
  ja jmp_5f88

jmp_5d78:
  lddw r2, 0x800000000

jmp_5d88:
  stxdw [r1+0x8], r2
  ja jmp_5f88

jmp_5d98:
  ldxdw r4, [r6+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_5e20
  ldxdw r4, [r6+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_5e20
  ldxdw r4, [r6+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_5e20
  mov64 r5, 0x0
  ldxdw r4, [r6+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r4, r0, jmp_5e28

jmp_5e20:
  mov64 r5, 0x1

jmp_5e28:
  lddw r4, 0x900000000
  jne r5, 0x0, jmp_5f80
  lddw r4, 0xa00000000
  ldxdw r5, [r6+0x50]
  jne r5, 0x9c, jmp_5f80
  stxdw [r10-0xc0], r3
  stxdw [r10-0xb0], r1
  stxdw [r10-0xb8], r2
  add64 r2, 0x10
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0xc8], r2
  call fn_28528
  ldxdw r9, [r10-0x30]
  jeq r9, 0x0, jmp_5f70
  ldxdw r1, [r8+0x8]
  ldxdw r2, [r9+0x52]
  jne r2, r1, jmp_5f18
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r9+0x5a]
  jne r2, r1, jmp_5f18
  ldxdw r1, [r8+0x18]
  ldxdw r2, [r9+0x62]
  jne r2, r1, jmp_5f18
  mov64 r1, 0x0
  ldxdw r2, [r8+0x20]
  ldxdw r3, [r9+0x6a]
  jeq r3, r2, jmp_5f20

jmp_5f18:
  mov64 r1, 0x1

jmp_5f20:
  ldxb r4, [r10-0x18]
  ldxdw r8, [r10-0x20]
  ldxdw r2, [r10-0xb0]
  ldxdw r3, [r10-0xb8]
  jeq r1, 0x0, jmp_5f98
  lddw r1, 0x1000000000
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_64d0

jmp_5f70:
  ldxdw r4, [r10-0x28]
  ldxdw r1, [r10-0xb0]

jmp_5f80:
  stxdw [r1+0x8], r4

jmp_5f88:
  stdw [r1+0x0], 0x0

jmp_5f90:
  exit

jmp_5f98:
  stxdw [r10-0xd0], r4
  mov64 r2, r3
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0xd8], r2
  call fn_0160
  ldxw r1, [r10-0x24]
  ldxw r0, [r10-0x28]
  ldxdw r3, [r10-0x30]
  jeq r3, 0x0, jmp_60b0
  lsh64 r1, 0x20
  ldxdw r4, [r9+0x52]
  ldxdw r5, [r3+0x20]
  jne r5, r4, jmp_6060
  ldxdw r4, [r9+0x5a]
  ldxdw r5, [r3+0x28]
  jne r5, r4, jmp_6060
  ldxdw r4, [r9+0x62]
  ldxdw r5, [r3+0x30]
  jne r5, r4, jmp_6060
  mov64 r4, 0x0
  ldxdw r5, [r9+0x6a]
  ldxdw r3, [r3+0x38]
  jeq r3, r5, jmp_6068

jmp_6060:
  mov64 r4, 0x1

jmp_6068:
  or64 r1, r0
  ldxdw r2, [r10-0x20]
  jeq r4, 0x0, jmp_60d8
  lddw r3, 0x400000000
  ldxdw r4, [r10-0xb0]
  stxdw [r4+0x8], r3
  stdw [r4+0x0], 0x0
  ja jmp_64c0

jmp_60b0:
  ldxdw r2, [r10-0xb0]
  stxw [r2+0xc], r1
  stxw [r2+0x8], r0
  stdw [r2+0x0], 0x0
  ja jmp_64c8

jmp_60d8:
  stxdw [r10-0xe8], r2
  stxdw [r10-0xe0], r1
  stxdw [r10-0x78], r7
  add64 r6, 0x8
  stxdw [r10-0x88], r6
  add64 r9, 0x20
  stxdw [r10-0x68], r9
  stdw [r10-0x60], 0x20
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x20
  stb [r10-0x58], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r2, 0x3
  lddw r3, data_00a0
  call sol_try_find_program_address
  jne r0, 0x0, jmp_65e8
  ldxdw r6, [r10-0xb8]
  add64 r6, 0x18
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa0], r1
  ldxdw r2, [r10-0x30]
  stxdw [r10-0xa8], r2
  ldxdw r1, [r6+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_6240
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0xa0]
  jne r2, r3, jmp_6240
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x98]
  jne r2, r3, jmp_6240
  mov64 r4, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r10-0x90]
  jeq r1, r3, jmp_6248

jmp_6240:
  mov64 r4, 0x1

jmp_6248:
  ldxdw r3, [r10-0xb0]
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xe8]
  jeq r4, 0x0, jmp_6290
  lddw r4, 0x600000000
  stxdw [r3+0x8], r4
  stdw [r3+0x0], 0x0
  ja jmp_64c0

jmp_6290:
  stxdw [r10-0x78], r9
  lddw r1, str_036f
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x5
  stb [r10-0x31], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x31
  mov64 r2, 0x2
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_65e8
  ldxdw r1, [r10-0xb8]
  mov64 r2, r1
  add64 r2, 0x28
  ldxdw r3, [r10-0x18]
  stxdw [r10-0x40], r3
  ldxdw r3, [r10-0x20]
  stxdw [r10-0x48], r3
  ldxdw r3, [r10-0x28]
  stxdw [r10-0x50], r3
  ldxdw r4, [r10-0x30]
  stxdw [r10-0x58], r4
  ldxdw r3, [r2+0x0]
  ldxdw r5, [r3+0x8]
  jne r5, r4, jmp_63e0
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r10-0x50]
  jne r4, r5, jmp_63e0
  ldxdw r4, [r3+0x18]
  ldxdw r5, [r10-0x48]
  jne r4, r5, jmp_63e0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  ldxdw r5, [r10-0x40]
  jeq r3, r5, jmp_63e8

jmp_63e0:
  mov64 r4, 0x1

jmp_63e8:
  mov64 r5, 0x13
  ldxdw r3, [r10-0xb0]
  jne r4, 0x0, jmp_6498
  mov64 r4, r1
  add64 r4, 0x38
  ldxdw r0, [r9+0x0]
  ldxdw r5, [r4+0x0]
  ldxdw r7, [r5+0x8]
  jne r7, r0, jmp_6480
  ldxdw r0, [r9+0x8]
  ldxdw r7, [r5+0x10]
  jne r7, r0, jmp_6480
  ldxdw r0, [r9+0x10]
  ldxdw r7, [r5+0x18]
  jne r7, r0, jmp_6480
  mov64 r0, 0x0
  ldxdw r7, [r9+0x18]
  ldxdw r5, [r5+0x20]
  jeq r5, r7, jmp_6488

jmp_6480:
  mov64 r0, 0x1

jmp_6488:
  mov64 r5, 0x5
  jeq r0, 0x0, jmp_6528

jmp_6498:
  stxw [r3+0xc], r5
  stw [r3+0x8], 0x0
  stdw [r3+0x0], 0x0
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xe8]

jmp_64c0:
  call fn_0788

jmp_64c8:
  ldxdw r4, [r10-0xd0]

jmp_64d0:
  mov64 r2, r4
  jgt r2, 0x7, jmp_6648
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r8+0x0]
  jlt r2, r3, jmp_6660
  sub64 r2, r1
  stxb [r8+0x0], r2
  ja jmp_5f90

jmp_6528:
  ldxdw r5, [r10-0xc0]
  add64 r5, -0x8
  mov64 r0, r1
  add64 r0, 0x40
  mov64 r7, r1
  add64 r7, 0x20
  stxdw [r3+0x40], r5
  stxdw [r3+0x38], r0
  stxdw [r3+0x30], r4
  stxdw [r3+0x28], r2
  stxdw [r3+0x20], r7
  stxdw [r3+0x18], r6
  ldxdw r2, [r10-0xc8]
  stxdw [r3+0x10], r2
  ldxdw r2, [r10-0xd8]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xe8]
  call fn_0788
  mov64 r1, r8
  ldxdw r2, [r10-0xd0]
  call fn_0788
  ja jmp_5f90

jmp_65e8:
  lddw r1, data_09a8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_09b8
  call fn_28b40

jmp_6648:
  lddw r1, data_0810
  call fn_29a40

jmp_6660:
  lddw r1, data_0828
  call fn_29938

fn_6678:
  mov64 r3, r2
  ldxdw r6, [r3+0x28]
  ldxdw r4, [r6+0x0]
  ldxdw r2, [r4+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r2, r5, jmp_6718
  ldxdw r2, [r4+0x30]
  lddw r5, 0x626c582b5813378e
  jne r2, r5, jmp_6718
  ldxdw r2, [r4+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r2, r5, jmp_6718
  mov64 r5, 0x0
  ldxdw r2, [r4+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r2, r0, jmp_6720

jmp_6718:
  mov64 r5, 0x1

jmp_6720:
  lddw r2, 0x900000000
  jne r5, 0x0, jmp_68e0
  lddw r2, 0xa00000000
  ldxdw r4, [r4+0x50]
  jne r4, 0x103, jmp_68e0
  mov64 r8, r3
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxw r2, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxdw r3, [r10-0x20]
  jeq r3, 0x0, jmp_68b8
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_6b38
  ldxb r1, [r10-0x8]
  mov64 r5, r1
  mov64 r1, r7
  jgt r5, 0x7, jmp_6b08
  ldxdw r2, [r10-0x10]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r2+0x0]
  jlt r5, r0, jmp_6b20
  ldxb r3, [r3+0x23]
  sub64 r5, r4
  stxb [r2+0x0], r5
  lddw r2, 0x2600000000
  jne r3, 0x2, jmp_68e0
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r2, [r10-0x20]
  jeq r2, 0x0, jmp_68d0
  ldxb r9, [r10-0x8]
  ldxdw r6, [r10-0x10]
  ldxb r1, [r2+0x26]
  and64 r1, 0x1
  jne r1, 0x0, jmp_6908
  mov64 r3, 0x2c
  mov64 r2, 0x0
  ja jmp_6960

jmp_68b8:
  lsh64 r2, 0x20
  or64 r2, r1
  ja jmp_68d8

jmp_68d0:
  ldxdw r2, [r10-0x18]

jmp_68d8:
  mov64 r1, r7

jmp_68e0:
  mov64 r3, r2
  rsh64 r3, 0x20

jmp_68f0:
  stxw [r1+0x4], r3
  stxw [r1+0x0], r2
  exit

jmp_6908:
  mov64 r1, r8
  ldxdw r3, [r1+0x20]
  ldxdw r4, [r1+0x38]
  ldxdw r5, [r1+0x40]
  mov64 r1, r10
  add64 r1, -0x20
  call fn_196a8
  ldxw r3, [r10-0x1c]
  ldxw r2, [r10-0x20]
  ldxh r1, [r10-0xc]
  jne r1, 0x2, jmp_69c0

jmp_6960:
  mov64 r1, r7
  mov64 r5, r9
  jgt r5, 0x7, jmp_6b08
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r6+0x0]
  jlt r5, r0, jmp_6b20
  sub64 r5, r4
  stxb [r6+0x0], r5
  ja jmp_68f0

jmp_69c0:
  ldxw r4, [r10-0x10]
  stxw [r10-0x28], r4
  ldxdw r4, [r10-0x18]
  stxdw [r10-0x30], r4
  ldxh r4, [r10-0xa]
  stxh [r10-0x22], r4
  stxh [r10-0x24], r1
  stxw [r10-0x34], r3
  stxw [r10-0x38], r2
  mov64 r2, r9
  jgt r2, 0x7, jmp_6b08
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r6+0x0]
  jlt r2, r3, jmp_6b20
  sub64 r2, r1
  stxb [r6+0x0], r2
  ldxdw r4, [r8+0x18]
  ldxdw r1, [r8+0x8]
  ldxdw r3, [r8+0x30]
  ldxdw r5, [r8+0x10]
  ldxdw r2, [r5+0x0]
  stxdw [r10-0xff0], r5
  stxdw [r10-0xff8], r3
  stxdw [r10-0x1000], r1
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r3, r10
  add64 r3, -0x38
  mov64 r5, r10
  call fn_1f500
  ldxw r2, [r10-0x40]
  jne r2, 0x1a, jmp_6af0
  mov64 r2, 0x1a
  ja jmp_6af8

jmp_6af0:
  ldxw r3, [r10-0x3c]

jmp_6af8:
  mov64 r1, r7
  ja jmp_68f0

jmp_6b08:
  lddw r1, data_0810
  call fn_29a40

jmp_6b20:
  lddw r1, data_0828
  call fn_29938

jmp_6b38:
  mov64 r1, 0x23
  lddw r3, data_0e38
  call fn_28b70

fn_6b58:
  jne r3, 0x6, jmp_6c28
  ldxdw r3, [r2+0x0]
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_6c40
  ldxdw r4, [r3+0x8]
  lddw r5, -0x60f4508de13d20f0
  jne r4, r5, jmp_6c00
  ldxdw r4, [r3+0x10]
  lddw r5, -0x1a9939e80f5e6338
  jne r4, r5, jmp_6c00
  ldxdw r4, [r3+0x18]
  lddw r5, 0x456c527702a976f0
  jne r4, r5, jmp_6c00
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  lddw r5, -0x3c173f54b221ad4c
  jeq r3, r5, jmp_6c08

jmp_6c00:
  mov64 r4, 0x1

jmp_6c08:
  jeq r4, 0x0, jmp_6c68
  lddw r2, 0x700000000
  ja jmp_6c50

jmp_6c28:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_6c60

jmp_6c40:
  lddw r2, 0x800000000

jmp_6c50:
  stxdw [r1+0x8], r2

jmp_6c58:
  stdw [r1+0x0], 0x0

jmp_6c60:
  exit

jmp_6c68:
  mov64 r7, r2
  add64 r7, 0x10
  ldxdw r8, [r7+0x0]
  ldxb r3, [r8+0x2]
  jeq r3, 0x0, jmp_6e28
  stxdw [r10-0x80], r1
  stxdw [r10-0x88], r2
  mov64 r6, r2
  add64 r6, 0x18
  ldxdw r9, [r6+0x0]
  lddw r1, str_036f
  stxdw [r10-0x58], r1
  mov64 r1, r9
  add64 r1, 0x8
  stxdw [r10-0x48], r1
  stdw [r10-0x40], 0x20
  stdw [r10-0x50], 0x5
  stb [r10-0x31], 0xff
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x31
  mov64 r2, 0x2
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_6fd8
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x78], r1
  ldxdw r2, [r8+0x8]
  jne r2, r1, jmp_6df8
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r10-0x70]
  jne r1, r2, jmp_6df8
  ldxdw r1, [r8+0x18]
  ldxdw r2, [r10-0x68]
  jne r1, r2, jmp_6df8
  mov64 r2, 0x0
  ldxdw r1, [r8+0x20]
  ldxdw r3, [r10-0x60]
  jeq r1, r3, jmp_6e00

jmp_6df8:
  mov64 r2, 0x1

jmp_6e00:
  ldxdw r1, [r10-0x80]
  jeq r2, 0x0, jmp_6e38
  lddw r2, 0x1300000000
  ja jmp_6c50

jmp_6e28:
  stdw [r1+0x8], 0x0
  ja jmp_6c58

jmp_6e38:
  mov64 r2, 0x3
  ldxdw r3, [r9+0x50]
  jne r3, 0x52, jmp_6c50
  ldxdw r2, [r9+0x28]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_6ed8
  ldxdw r2, [r9+0x30]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_6ed8
  ldxdw r2, [r9+0x38]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_6ed8
  mov64 r3, 0x0
  ldxdw r2, [r9+0x40]
  lddw r4, -0x56ff00817a0a73c6
  jeq r2, r4, jmp_6ee0

jmp_6ed8:
  mov64 r3, 0x1

jmp_6ee0:
  mov64 r2, 0x16
  jne r3, 0x0, jmp_6c50
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  call fn_28528
  ldxdw r3, [r10-0x30]
  jeq r3, 0x0, jmp_6fa8
  ldxb r2, [r10-0x18]
  ldxdw r1, [r10-0x20]
  ldxb r8, [r3+0x2d]
  call fn_0788
  jne r8, 0x1, jmp_6fc0
  ldxdw r1, [r10-0x88]
  mov64 r2, r1
  add64 r2, 0x28
  mov64 r3, r1
  add64 r3, 0x8
  ldxdw r4, [r10-0x80]
  stxdw [r4+0x20], r6
  stxdw [r4+0x18], r7
  stxdw [r4+0x10], r3
  stxdw [r4+0x8], r1
  stxdw [r4+0x0], r2
  ja jmp_6c60

jmp_6fa8:
  ldxdw r2, [r10-0x28]
  ldxdw r1, [r10-0x80]
  ja jmp_6c50

jmp_6fc0:
  ldxdw r1, [r10-0x80]
  stw [r1+0x8], 0x9
  ja jmp_6c58

jmp_6fd8:
  lddw r1, data_09a8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_09b8
  call fn_28b40

fn_7038:
  mov64 r9, r2
  mov64 r7, r1
  ldxdw r2, [r9+0x0]
  stdw [r10-0xfe8], 0x0
  stdw [r10-0xff0], 0x0
  stdw [r10-0xff8], 0x0
  stdw [r10-0x1000], 0x0
  mov64 r6, r9
  add64 r6, 0x40
  mov64 r8, r9
  add64 r8, 0x60
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r5, r10
  mov64 r3, r6
  mov64 r4, r8
  call fn_14de0
  ldxh r1, [r10-0x64]
  jne r1, 0x2, jmp_70e8
  ldxw r0, [r10-0x74]
  ldxw r6, [r10-0x78]
  ja jmp_78b8

jmp_70e8:
  stxdw [r10-0x1f8], r6
  stxdw [r10-0x1f0], r7
  mov64 r6, 0x0
  mov64 r0, 0x23
  ldxw r1, [r10-0x68]
  lsh64 r1, 0x20
  arsh64 r1, 0x20
  add64 r1, 0x6
  mov64 r7, r1
  lsh64 r7, 0x20
  arsh64 r7, 0x20
  jeq r7, r1, jmp_7158

jmp_7148:
  ldxdw r7, [r10-0x1f0]
  ja jmp_78b8

jmp_7158:
  ldxdw r6, [r10-0x70]
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x200], r1
  jsle r7, -0x1, jmp_7840
  stxdw [r10-0x208], r6
  mov64 r1, 0x1
  stxdw [r10-0x210], r1
  mov64 r6, 0x1
  mov64 r5, 0x0
  stxdw [r10-0x218], r8
  jeq r7, 0x0, jmp_75b0
  mov64 r1, r7
  and64 r1, 0x1
  jeq r1, 0x0, jmp_71d8
  mov64 r6, 0xa
  jeq r7, 0x1, jmp_75b0

jmp_71d8:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_7250
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x64
  call fn_2c150
  mov64 r0, 0x23
  ldxdw r5, [r10-0x130]
  ldxdw r6, [r10-0x138]
  mov64 r1, r7
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_75b0

jmp_7250:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_72d0
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  mov64 r0, 0x23
  ldxdw r5, [r10-0x140]
  ldxdw r6, [r10-0x148]
  mov64 r1, r7
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_75b0

jmp_72d0:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_7350
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  mov64 r0, 0x23
  ldxdw r5, [r10-0x150]
  ldxdw r6, [r10-0x158]
  mov64 r1, r7
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_75b0

jmp_7350:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_73d8
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r6
  mov64 r3, r5
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r0, 0x23
  ldxdw r5, [r10-0x160]
  ldxdw r6, [r10-0x168]
  mov64 r1, r7
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_75b0

jmp_73d8:
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_80a0
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r5
  mov64 r3, 0x0
  mov64 r8, r6
  lddw r4, -0x7a53107f00000000
  mov64 r6, r5
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  jne r6, 0x0, jmp_74e0
  mov64 r1, 0x0

jmp_74e0:
  ldxdw r4, [r10-0x180]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_7500
  mov64 r3, 0x0

jmp_7500:
  or64 r1, r3
  ldxdw r4, [r10-0x190]
  mov64 r3, 0x1
  mov64 r0, 0x23
  ldxdw r8, [r10-0x218]
  jne r4, 0x0, jmp_7538
  mov64 r3, 0x0

jmp_7538:
  or64 r1, r3
  ldxdw r3, [r10-0x198]
  ldxdw r4, [r10-0x188]
  add64 r4, r3
  ldxdw r3, [r10-0x170]
  mov64 r5, r3
  add64 r5, r4
  jlt r5, r3, jmp_7580
  mov64 r2, 0x0

jmp_7580:
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_80a0
  and64 r7, 0x7fffffe0
  jne r7, 0x20, jmp_80a0
  ldxdw r6, [r10-0x178]

jmp_75b0:
  mov64 r1, r10
  add64 r1, -0x1c8
  ldxdw r2, [r10-0x208]
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r8, r5
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r8
  mov64 r3, 0x0
  ldxdw r7, [r10-0x200]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  jne r8, 0x0, jmp_7680
  mov64 r1, 0x0

jmp_7680:
  mov64 r2, 0x1
  ldxdw r7, [r10-0x1f0]
  ldxdw r3, [r10-0x208]
  jne r3, 0x0, jmp_76a8
  mov64 r2, 0x0

jmp_76a8:
  and64 r2, r1
  ldxdw r3, [r10-0x1c0]
  mov64 r1, 0x1
  mov64 r0, 0x23
  ldxdw r8, [r10-0x218]
  mov64 r6, 0x0
  jne r3, 0x0, jmp_76e8
  mov64 r1, 0x0

jmp_76e8:
  or64 r2, r1
  ldxdw r3, [r10-0x1b0]
  mov64 r1, 0x1
  jne r3, 0x0, jmp_7710
  mov64 r1, 0x0

jmp_7710:
  or64 r2, r1
  ldxdw r1, [r10-0x1b8]
  ldxdw r3, [r10-0x1c8]
  add64 r3, r1
  ldxdw r4, [r10-0x1a0]
  mov64 r1, r4
  add64 r1, r3
  jlt r1, r4, jmp_7760
  mov64 r3, 0x0
  stxdw [r10-0x210], r3

jmp_7760:
  ldxdw r3, [r10-0x210]
  or64 r2, r3
  and64 r2, 0x1
  jne r2, 0x0, jmp_78b8
  ldxdw r2, [r10-0x1a8]
  ldxdw r4, [r9+0x30]
  mov64 r6, 0x0
  mov64 r3, 0x1
  jlt r2, r4, jmp_77b0

jmp_77a8:
  mov64 r3, 0x0

jmp_77b0:
  jne r1, 0x0, jmp_77d8
  mov64 r0, 0x21
  and64 r3, 0x1
  jeq r3, 0x0, jmp_77f8
  ja jmp_78b8

jmp_77d8:
  mov64 r3, 0x0
  mov64 r0, 0x21
  and64 r3, 0x1
  jne r3, 0x0, jmp_78b8

jmp_77f8:
  ldxdw r5, [r9+0x38]
  mov64 r4, 0x1
  mov64 r3, 0x1
  jle r2, r5, jmp_7880
  jeq r1, 0x0, jmp_7890

jmp_7820:
  jne r1, 0x0, jmp_78a0

jmp_7828:
  and64 r3, 0x1
  jne r3, 0x0, jmp_78b8
  ja jmp_78d0

jmp_7840:
  mov64 r3, r7
  neg64 r3
  mov64 r1, r3
  mov64 r5, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_7970
  mov64 r4, 0x1
  ja jmp_7980

jmp_7880:
  mov64 r3, 0x0
  jne r1, 0x0, jmp_7820

jmp_7890:
  mov64 r4, 0x0
  jeq r1, 0x0, jmp_7828

jmp_78a0:
  mov64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_78d0

jmp_78b8:
  stxw [r7+0x4], r0
  stxw [r7+0x0], r6
  exit

jmp_78d0:
  ldxdw r7, [r9+0x28]
  ldxdw r6, [r9+0x20]
  ldxdw r1, [r6+0x0]
  lddw r2, str_036f
  stxdw [r10-0xa8], r2
  add64 r1, 0x8
  stxdw [r10-0x98], r1
  stxdw [r10-0x88], r7
  stdw [r10-0x80], 0x1
  stdw [r10-0x90], 0x20
  stdw [r10-0xa0], 0x5
  mov64 r1, r10
  add64 r1, -0x78
  call fn_28928
  ldxw r1, [r10-0x78]
  jne r1, 0x1, jmp_7e70
  ldxw r0, [r10-0x70]
  ldxw r6, [r10-0x74]
  ja jmp_7148

jmp_7970:
  mov64 r4, 0xa
  jeq r7, -0x1, jmp_7e08

jmp_7980:
  mov64 r1, r3
  and64 r1, 0x2
  stxdw [r10-0x210], r3
  jeq r1, 0x0, jmp_7a18
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x64
  call fn_2c150
  ldxdw r3, [r10-0x210]
  mov64 r0, 0x23
  lddw r1, 0xfffffffe
  mov64 r2, r3
  and64 r2, r1
  ldxdw r5, [r10-0xb0]
  ldxdw r4, [r10-0xb8]
  jeq r2, 0x2, jmp_7e08

jmp_7a18:
  mov64 r1, r3
  and64 r1, 0x4
  jeq r1, 0x0, jmp_7ab0
  mov64 r1, r10
  add64 r1, -0xc8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x210]
  mov64 r0, 0x23
  lddw r1, 0xfffffffc
  mov64 r2, r3
  and64 r2, r1
  ldxdw r5, [r10-0xc0]
  ldxdw r4, [r10-0xc8]
  jeq r2, 0x4, jmp_7e08

jmp_7ab0:
  mov64 r1, r3
  and64 r1, 0x8
  jeq r1, 0x0, jmp_7b48
  mov64 r1, r10
  add64 r1, -0xd8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x210]
  mov64 r0, 0x23
  lddw r1, 0xfffffff8
  mov64 r2, r3
  and64 r2, r1
  ldxdw r5, [r10-0xd0]
  ldxdw r4, [r10-0xd8]
  jeq r2, 0x8, jmp_7e08

jmp_7b48:
  mov64 r1, r3
  and64 r1, 0x10
  jeq r1, 0x0, jmp_7be8
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r4
  mov64 r3, r5
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x210]
  mov64 r0, 0x23
  lddw r1, 0xfffffff0
  mov64 r2, r3
  and64 r2, r1
  ldxdw r5, [r10-0xe0]
  ldxdw r4, [r10-0xe8]
  jeq r2, 0x10, jmp_7e08

jmp_7be8:
  stxdw [r10-0x208], r6
  mov64 r6, 0x0
  mov64 r1, r3
  and64 r1, 0x20
  jeq r1, 0x0, jmp_7148
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r5
  mov64 r3, 0x0
  mov64 r7, r4
  lddw r4, -0x7a53107f00000000
  stxdw [r10-0x220], r5
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  stxdw [r10-0x228], r1
  ldxdw r7, [r10-0x1f0]
  ldxdw r2, [r10-0x220]
  jeq r2, 0x0, jmp_8290
  ldxdw r4, [r10-0x100]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_82b0

jmp_7d20:
  ldxdw r5, [r10-0x110]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_7d40

jmp_7d38:
  mov64 r4, 0x0

jmp_7d40:
  ldxdw r5, [r10-0x118]
  ldxdw r0, [r10-0x108]
  add64 r0, r5
  ldxdw r5, [r10-0xf0]
  mov64 r2, r5
  add64 r2, r0
  stxdw [r10-0x220], r2
  jlt r2, r5, jmp_7d90
  mov64 r2, 0x0
  stxdw [r10-0x228], r2

jmp_7d90:
  lddw r5, 0xffffffe0
  ldxdw r2, [r10-0x210]
  and64 r2, r5
  mov64 r0, 0x23
  jne r2, 0x20, jmp_78b8
  or64 r1, r3
  or64 r1, r4
  ldxdw r2, [r10-0x228]
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_78b8
  ldxdw r4, [r10-0xf8]
  ldxdw r6, [r10-0x208]
  ldxdw r5, [r10-0x220]

jmp_7e08:
  mov64 r1, r10
  add64 r1, -0x128
  ldxdw r2, [r10-0x200]
  mov64 r3, r6
  call fn_2c2b0
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x128]
  ldxdw r7, [r10-0x1f0]
  ldxdw r4, [r9+0x30]
  mov64 r6, 0x0
  mov64 r3, 0x1
  jge r2, r4, jmp_77a8
  ja jmp_77b0

jmp_7e70:
  stxdw [r10-0x200], r6
  ldxdw r2, [r10-0x68]
  ldxdw r1, [r10-0x70]
  mov64 r3, 0x103
  call fn_0ae8
  ldxdw r4, [r9+0x18]
  ldxdw r1, [r4+0x0]
  ldxdw r1, [r1+0x48]
  jeq r1, 0x0, jmp_80b0
  stxdw [r10-0x210], r0
  stxdw [r10-0x208], r7
  stxdw [r10-0x10], r4
  stdw [r10-0x8], 0x103
  mov64 r1, r10
  add64 r1, -0xa8
  stxdw [r10-0x78], r1
  stdw [r10-0x70], 0x3
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x78
  mov64 r7, r4
  mov64 r4, 0x1
  call fn_27da8
  ldxw r6, [r10-0x1d0]
  jne r6, 0x1a, jmp_8280
  lddw r1, data_0160
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r7
  mov64 r1, r10
  add64 r1, -0xa8
  stxdw [r10-0x78], r1
  stdw [r10-0x70], 0x3
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x78
  mov64 r4, 0x1
  call fn_27fe0
  ldxw r6, [r10-0x1d8]
  jne r6, 0x1a, jmp_82e8
  ldxdw r1, [r7+0x0]
  ldxdw r1, [r1+0x48]
  mov64 r4, r7
  ldxdw r7, [r10-0x208]
  ldxdw r2, [r10-0x210]
  jle r2, r1, jmp_8170
  sub64 r2, r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0x68], r2
  stxdw [r10-0x70], r4
  stxdw [r10-0x78], r1
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x8
  mov64 r6, r4
  mov64 r4, 0x0
  call fn_283e0
  mov64 r4, r6
  ldxw r6, [r10-0x1e0]
  jeq r6, 0x1a, jmp_8170
  ldxw r0, [r10-0x1dc]
  ja jmp_7148

jmp_80a0:
  mov64 r6, 0x0
  ja jmp_7148

jmp_80b0:
  ldxdw r1, [r9+0x10]
  stxdw [r10-0x60], r0
  stxdw [r10-0x70], r4
  stxdw [r10-0x78], r1
  lddw r1, data_0160
  stxdw [r10-0x68], r1
  stdw [r10-0x58], 0x103
  mov64 r1, r10
  add64 r1, -0xa8
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r6, r4
  mov64 r4, 0x1
  call fn_28250
  mov64 r4, r6
  ldxw r6, [r10-0x1e8]
  jne r6, 0x1a, jmp_82d8

jmp_8170:
  ldxdw r9, [r4+0x0]
  ldxdw r1, [r9+0x28]
  lddw r2, -0x2ef915ab4fa6d9f4
  jne r1, r2, jmp_8200
  ldxdw r1, [r9+0x30]
  lddw r2, 0x626c582b5813378e
  jne r1, r2, jmp_8200
  ldxdw r1, [r9+0x38]
  lddw r2, -0x164c5fdb9d1c7931
  jne r1, r2, jmp_8200
  mov64 r1, 0x0
  ldxdw r2, [r9+0x40]
  lddw r3, -0xe007a018e0ac636
  jeq r2, r3, jmp_8208

jmp_8200:
  mov64 r1, 0x1

jmp_8208:
  lddw r6, 0x900000000
  jne r1, 0x0, jmp_8268
  lddw r6, 0xa00000000
  ldxdw r1, [r9+0x50]
  jne r1, 0x103, jmp_8268
  mov64 r6, 0xb
  ldxb r2, [r9+0x0]
  mov64 r1, r2
  and64 r1, 0xf
  jeq r1, 0x0, jmp_82f8

jmp_8268:
  mov64 r0, r6
  rsh64 r0, 0x20
  ja jmp_7148

jmp_8280:
  ldxw r0, [r10-0x1cc]
  ja jmp_7148

jmp_8290:
  mov64 r1, 0x0
  ldxdw r4, [r10-0x100]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_7d20

jmp_82b0:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x110]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_7d38
  ja jmp_7d40

jmp_82d8:
  ldxw r0, [r10-0x1e4]
  ja jmp_7148

jmp_82e8:
  ldxw r0, [r10-0x1d4]
  ja jmp_7148

jmp_82f8:
  mov64 r1, r2
  or64 r1, 0x8
  stxb [r9+0x0], r1
  ldxdw r1, [r10-0x200]
  ldxdw r1, [r1+0x0]
  ldxdw r6, [r10-0x1f8]
  stxdw [r10-0x208], r2
  ldxdw r2, [r6+0x18]
  stxdw [r10-0x60], r2
  ldxdw r2, [r6+0x10]
  stxdw [r10-0x68], r2
  ldxdw r2, [r6+0x8]
  stxdw [r10-0x70], r2
  ldxdw r2, [r6+0x0]
  stxdw [r10-0x78], r2
  ldxdw r2, [r8+0x0]
  stxdw [r10-0x58], r2
  ldxdw r2, [r8+0x8]
  stxdw [r10-0x50], r2
  ldxdw r2, [r8+0x10]
  stxdw [r10-0x48], r2
  ldxdw r2, [r8+0x18]
  stxdw [r10-0x40], r2
  ldxb r2, [r7+0x0]
  ldxdw r3, [r1+0x8]
  mov64 r7, r4
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r9+0x70], r1
  stxdw [r9+0x68], r5
  stxdw [r9+0x60], r4
  stxdw [r9+0x58], r3
  stxb [r9+0x79], r2
  stb [r9+0x78], 0x1
  stw [r9+0x7c], 0x10000
  stb [r9+0x7b], 0x2
  mov64 r1, r9
  add64 r1, 0xc9
  mov64 r2, 0x0
  mov64 r3, 0x92
  call fn_2a0b0
  mov64 r1, r9
  add64 r1, 0x80
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x40
  call fn_2a090
  stdw [r9+0xc0], 0x0
  stb [r9+0xc8], 0x0
  ldxdw r1, [r10-0x208]
  stxb [r9+0x0], r1
  stb [r9+0x7a], 0x1
  ldxdw r1, [r10-0x200]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r7+0x0]
  stb [r10-0x78], 0x7
  ldxdw r3, [r2+0x20]
  stxdw [r10-0x5f], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x67], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x6f], r3
  ldxdw r2, [r2+0x8]
  stxdw [r10-0x77], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x57], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x4f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x47], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x3f], r1
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x37], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x2f], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x27], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0x1f], r1
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x61
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r6, 0x1a
  ja jmp_7148

fn_85d0:
  jne r3, 0x2, jmp_86a0
  ldxdw r3, [r2+0x0]
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_86b8
  ldxdw r4, [r3+0x8]
  lddw r5, -0x60f4508de13d20f0
  jne r4, r5, jmp_8678
  ldxdw r4, [r3+0x10]
  lddw r5, -0x1a9939e80f5e6338
  jne r4, r5, jmp_8678
  ldxdw r4, [r3+0x18]
  lddw r5, 0x456c527702a976f0
  jne r4, r5, jmp_8678
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  lddw r5, -0x3c173f54b221ad4c
  jeq r3, r5, jmp_8680

jmp_8678:
  mov64 r4, 0x1

jmp_8680:
  jeq r4, 0x0, jmp_86e0
  lddw r2, 0x700000000
  ja jmp_86c8

jmp_86a0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_86d8

jmp_86b8:
  lddw r2, 0x800000000

jmp_86c8:
  stxdw [r1+0x8], r2

jmp_86d0:
  stdw [r1+0x0], 0x0

jmp_86d8:
  exit

jmp_86e0:
  mov64 r6, r2
  add64 r6, 0x8
  ldxdw r4, [r6+0x0]
  ldxb r3, [r4+0x2]
  jeq r3, 0x0, jmp_8918
  ldxdw r3, [r4+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r3, r5, jmp_8790
  ldxdw r3, [r4+0x30]
  lddw r5, 0x626c582b5813378e
  jne r3, r5, jmp_8790
  ldxdw r3, [r4+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r3, r5, jmp_8790
  mov64 r5, 0x0
  ldxdw r3, [r4+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r3, r0, jmp_8798

jmp_8790:
  mov64 r5, 0x1

jmp_8798:
  lddw r3, 0x900000000
  jne r5, 0x0, jmp_8950
  lddw r3, 0xa00000000
  ldxdw r4, [r4+0x50]
  jne r4, 0x103, jmp_8950
  mov64 r8, r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxw r3, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxdw r4, [r10-0x20]
  jeq r4, 0x0, jmp_8928
  lsh64 r3, 0x20
  or64 r3, r1
  jlt r3, 0x24, jmp_8960
  ldxb r2, [r10-0x8]
  ldxdw r1, [r10-0x10]
  ldxb r9, [r4+0x23]
  call fn_0788
  lddw r3, 0x2600000000
  mov64 r1, r7
  jne r9, 0x2, jmp_8950
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_8940
  ldxb r3, [r10-0x8]
  jgt r3, 0x7, jmp_8988
  ldxdw r1, [r10-0x10]
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_89a0
  sub64 r3, r2
  stxb [r1+0x0], r3
  stxdw [r7+0x8], r6
  stxdw [r7+0x0], r8
  ja jmp_86d8

jmp_8918:
  stdw [r1+0x8], 0x0
  ja jmp_86d0

jmp_8928:
  lsh64 r3, 0x20
  or64 r3, r1
  ja jmp_8948

jmp_8940:
  ldxdw r3, [r10-0x18]

jmp_8948:
  mov64 r1, r7

jmp_8950:
  stxdw [r1+0x8], r3
  ja jmp_86d0

jmp_8960:
  mov64 r1, 0x23
  mov64 r2, r3
  lddw r3, data_0e38
  call fn_28b70

jmp_8988:
  lddw r1, data_0810
  call fn_29a40

jmp_89a0:
  lddw r1, data_0828
  call fn_29938

fn_89b8:
  ldxdw r6, [r2+0x8]
  ldxdw r3, [r6+0x0]
  ldxdw r2, [r3+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r2, r4, jmp_8a50
  ldxdw r2, [r3+0x30]
  lddw r4, 0x626c582b5813378e
  jne r2, r4, jmp_8a50
  ldxdw r2, [r3+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r2, r4, jmp_8a50
  mov64 r4, 0x0
  ldxdw r2, [r3+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r2, r5, jmp_8a58

jmp_8a50:
  mov64 r4, 0x1

jmp_8a58:
  lddw r2, 0x900000000
  jne r4, 0x0, jmp_8c68
  lddw r2, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_8c68
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r6
  call fn_28528
  ldxw r2, [r10-0x2c]
  ldxw r1, [r10-0x30]
  ldxdw r3, [r10-0x38]
  jeq r3, 0x0, jmp_8c50
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_8c90
  ldxb r1, [r10-0x20]
  mov64 r5, r1
  mov64 r1, r7
  jgt r5, 0x7, jmp_8cb0
  ldxdw r2, [r10-0x28]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r2+0x0]
  jlt r5, r0, jmp_8cc8
  ldxb r3, [r3+0x23]
  sub64 r5, r4
  stxb [r2+0x0], r5
  lddw r2, 0x2600000000
  jne r3, 0x2, jmp_8c68
  mov64 r2, 0xb
  ldxdw r3, [r6+0x0]
  ldxb r4, [r3+0x0]
  and64 r4, 0xf
  jne r4, 0x0, jmp_8c68
  stb [r3+0x78], 0x0
  ldxdw r1, [r6+0x0]
  stb [r10-0x38], 0x8
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x37], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x27], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x1f], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x21
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r1, r7
  mov64 r2, 0x1a
  ja jmp_8c78

jmp_8c50:
  lsh64 r2, 0x20
  or64 r2, r1
  mov64 r1, r7

jmp_8c68:
  mov64 r3, r2
  rsh64 r3, 0x20

jmp_8c78:
  stxw [r1+0x4], r3
  stxw [r1+0x0], r2
  exit

jmp_8c90:
  mov64 r1, 0x23
  lddw r3, data_0e50
  call fn_28b70

jmp_8cb0:
  lddw r1, data_0810
  call fn_29a40

jmp_8cc8:
  lddw r1, data_0828
  call fn_29938

fn_8ce0:
  jne r3, 0x2, jmp_8ee0
  ldxdw r7, [r2+0x0]
  ldxb r3, [r7+0x1]
  jeq r3, 0x0, jmp_8ef8
  mov64 r6, r2
  add64 r6, 0x8
  ldxdw r3, [r6+0x0]
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_8f18
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_8db0
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_8db0
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_8db0
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_8db8

jmp_8db0:
  mov64 r4, 0x1

jmp_8db8:
  lddw r5, 0x900000000
  jne r4, 0x0, jmp_8f38
  lddw r5, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_8f38
  mov64 r9, r2
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_8f28
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r1+0x52]
  jne r3, r2, jmp_8e98
  ldxdw r2, [r7+0x10]
  ldxdw r3, [r1+0x5a]
  jne r3, r2, jmp_8e98
  ldxdw r2, [r7+0x18]
  ldxdw r3, [r1+0x62]
  jne r3, r2, jmp_8e98
  mov64 r2, 0x0
  ldxdw r3, [r7+0x20]
  ldxdw r1, [r1+0x6a]
  jeq r1, r3, jmp_8ea0

jmp_8e98:
  mov64 r2, 0x1

jmp_8ea0:
  ldxb r3, [r10-0x8]
  ldxdw r1, [r10-0x10]
  jeq r2, 0x0, jmp_8f50
  lddw r2, 0x1000000000
  stxdw [r8+0x8], r2
  stdw [r8+0x0], 0x0
  ja jmp_8f60

jmp_8ee0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_8f48

jmp_8ef8:
  lddw r2, 0x800000000
  stxdw [r1+0x8], r2
  ja jmp_8f40

jmp_8f18:
  stdw [r1+0x8], 0x0
  ja jmp_8f40

jmp_8f28:
  ldxdw r5, [r10-0x18]
  mov64 r1, r8

jmp_8f38:
  stxdw [r1+0x8], r5

jmp_8f40:
  stdw [r1+0x0], 0x0

jmp_8f48:
  exit

jmp_8f50:
  stxdw [r8+0x8], r6
  stxdw [r8+0x0], r9

jmp_8f60:
  jgt r3, 0x7, jmp_8fb0
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_8fc8
  sub64 r3, r2
  stxb [r1+0x0], r3
  ja jmp_8f48

jmp_8fb0:
  lddw r1, data_0810
  call fn_29a40

jmp_8fc8:
  lddw r1, data_0828
  call fn_29938

fn_8fe0:
  jne r3, 0x5, jmp_9210
  ldxdw r9, [r2+0x0]
  ldxb r3, [r9+0x1]
  jeq r3, 0x0, jmp_9228
  mov64 r6, r2
  add64 r6, 0x10
  ldxdw r8, [r6+0x0]
  ldxb r3, [r8+0x2]
  jeq r3, 0x0, jmp_9248
  mov64 r7, r2
  add64 r7, 0x8
  ldxdw r3, [r7+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_90c8
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_90c8
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_90c8
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_90d0

jmp_90c8:
  mov64 r4, 0x1

jmp_90d0:
  lddw r5, 0x900000000
  jne r4, 0x0, jmp_9268
  lddw r5, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_9268
  stxdw [r10-0x30], r2
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r7
  call fn_28528
  ldxdw r4, [r10-0x20]
  jeq r4, 0x0, jmp_9258
  ldxdw r1, [r9+0x8]
  ldxdw r2, [r4+0x52]
  jne r2, r1, jmp_91b0
  ldxdw r1, [r9+0x10]
  ldxdw r2, [r4+0x5a]
  jne r2, r1, jmp_91b0
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r4+0x62]
  jne r2, r1, jmp_91b0
  mov64 r2, 0x0
  ldxdw r1, [r9+0x20]
  ldxdw r3, [r4+0x6a]
  jeq r3, r1, jmp_91b8

jmp_91b0:
  mov64 r2, 0x1

jmp_91b8:
  ldxb r0, [r10-0x8]
  ldxdw r9, [r10-0x10]
  ldxdw r1, [r10-0x28]
  jeq r2, 0x0, jmp_9280
  lddw r2, 0x1000000000
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  mov64 r2, r0
  jle r2, 0x7, jmp_9358
  ja jmp_94b8

jmp_9210:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_9278

jmp_9228:
  lddw r2, 0x800000000
  stxdw [r1+0x8], r2
  ja jmp_9270

jmp_9248:
  stdw [r1+0x8], 0x0
  ja jmp_9270

jmp_9258:
  ldxdw r5, [r10-0x18]
  ldxdw r1, [r10-0x28]

jmp_9268:
  stxdw [r1+0x8], r5

jmp_9270:
  stdw [r1+0x0], 0x0

jmp_9278:
  exit

jmp_9280:
  mov64 r2, 0x3
  ldxdw r3, [r8+0x50]
  jne r3, 0xa5, jmp_9338
  stxdw [r10-0x38], r4
  ldxdw r3, [r8+0x28]
  lddw r4, -0x6c5e9a281e0922fa
  jne r3, r4, jmp_9328
  ldxdw r3, [r8+0x30]
  lddw r4, -0x53861431b91e3427
  jne r3, r4, jmp_9328
  ldxdw r3, [r8+0x38]
  lddw r4, -0x6ec8a4a0127a4be4
  jne r3, r4, jmp_9328
  mov64 r3, 0x0
  ldxdw r4, [r8+0x40]
  lddw r5, -0x56ff00817a0a73c6
  jeq r4, r5, jmp_9330

jmp_9328:
  mov64 r3, 0x1

jmp_9330:
  jeq r3, 0x0, jmp_93a0

jmp_9338:
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  mov64 r2, r0
  jgt r2, 0x7, jmp_94b8

jmp_9358:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r9+0x0]
  jlt r2, r3, jmp_9568
  sub64 r2, r1
  stxb [r9+0x0], r2
  ja jmp_9278

jmp_93a0:
  mov64 r8, r0
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_94d0
  ldxdw r4, [r10-0x38]
  ldxdw r2, [r4+0x0]
  ldxdw r3, [r1+0x0]
  jne r3, r2, jmp_9448
  ldxdw r2, [r4+0x8]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_9448
  ldxdw r2, [r4+0x10]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_9448
  mov64 r3, 0x0
  ldxdw r2, [r4+0x18]
  ldxdw r1, [r1+0x18]
  jeq r1, r2, jmp_9450

jmp_9448:
  mov64 r3, 0x1

jmp_9450:
  ldxb r2, [r10-0x8]
  ldxdw r1, [r10-0x10]
  ldxdw r4, [r10-0x28]
  ldxdw r5, [r10-0x30]
  jeq r3, 0x0, jmp_9510
  lddw r3, 0x500000000
  stxdw [r4+0x8], r3
  stdw [r4+0x0], 0x0
  call fn_0788
  mov64 r0, r8
  mov64 r2, r0
  jle r2, 0x7, jmp_9358

jmp_94b8:
  lddw r1, data_0810
  call fn_29a40

jmp_94d0:
  ldxdw r2, [r10-0x18]
  ldxdw r1, [r10-0x28]
  mov64 r0, r8
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  mov64 r2, r0
  jle r2, 0x7, jmp_9358
  ja jmp_94b8

jmp_9510:
  mov64 r3, r5
  add64 r3, 0x18
  stxdw [r4+0x18], r3
  stxdw [r4+0x10], r6
  stxdw [r4+0x8], r7
  stxdw [r4+0x0], r5
  call fn_0788
  mov64 r1, r9
  mov64 r2, r8
  call fn_0788
  ja jmp_9278

jmp_9568:
  lddw r1, data_0828
  call fn_29938

fn_9580:
  ldxdw r6, [r2+0x8]
  ldxdw r3, [r6+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_9618
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_9618
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_9618
  mov64 r5, 0x0
  ldxdw r4, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r4, r0, jmp_9620

jmp_9618:
  mov64 r5, 0x1

jmp_9620:
  lddw r4, 0x900000000
  jne r5, 0x0, jmp_97f8
  lddw r4, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_97f8
  mov64 r7, r2
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x58]
  jeq r1, 0x0, jmp_97e8
  ldxb r9, [r10-0x40]
  ldxdw r8, [r10-0x48]
  mov64 r2, r1
  add64 r2, 0x72
  stxdw [r10-0x38], r2
  stxdw [r10-0x48], r1
  lddw r1, str_036a
  stxdw [r10-0x58], r1
  stdw [r10-0x30], 0x1
  stdw [r10-0x40], 0x20
  stdw [r10-0x50], 0x5
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r7+0x18]
  stxdw [r10-0x18], r6
  stxdw [r10-0x20], r2
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x28
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r6, 0x1
  mov64 r4, 0x1
  call fn_27170
  jgt r9, 0x7, jmp_9820
  lsh64 r6, r9
  mov64 r2, r6
  and64 r2, 0xff
  ldxb r3, [r8+0x0]
  ldxdw r1, [r10-0x68]
  jlt r3, r2, jmp_9838
  ldxw r2, [r10-0x5c]
  ldxw r4, [r10-0x60]
  sub64 r3, r6
  stxb [r8+0x0], r3
  ja jmp_9808

jmp_97e8:
  ldxdw r4, [r10-0x50]
  ldxdw r1, [r10-0x68]

jmp_97f8:
  mov64 r2, r4
  rsh64 r2, 0x20

jmp_9808:
  stxw [r1+0x0], r4
  stxw [r1+0x4], r2
  exit

jmp_9820:
  lddw r1, data_0810
  call fn_29a40

jmp_9838:
  lddw r1, data_0828
  call fn_29938

fn_9850:
  ldxdw r6, [r2+0x8]
  ldxdw r3, [r6+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_98e8
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_98e8
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_98e8
  mov64 r5, 0x0
  ldxdw r4, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r4, r0, jmp_98f0

jmp_98e8:
  mov64 r5, 0x1

jmp_98f0:
  lddw r4, 0x900000000
  jne r5, 0x0, jmp_9ac8
  lddw r4, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x9c, jmp_9ac8
  mov64 r7, r2
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r2, r6
  call fn_28528
  ldxdw r1, [r10-0x58]
  jeq r1, 0x0, jmp_9ab8
  ldxb r9, [r10-0x40]
  ldxdw r8, [r10-0x48]
  mov64 r2, r1
  add64 r2, 0x72
  stxdw [r10-0x38], r2
  stxdw [r10-0x48], r1
  lddw r1, str_036a
  stxdw [r10-0x58], r1
  stdw [r10-0x30], 0x1
  stdw [r10-0x40], 0x20
  stdw [r10-0x50], 0x5
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r7+0x18]
  stxdw [r10-0x18], r6
  stxdw [r10-0x20], r2
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x28
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r6, 0x1
  mov64 r4, 0x1
  call fn_27438
  jgt r9, 0x7, jmp_9af0
  lsh64 r6, r9
  mov64 r2, r6
  and64 r2, 0xff
  ldxb r3, [r8+0x0]
  ldxdw r1, [r10-0x68]
  jlt r3, r2, jmp_9b08
  ldxw r2, [r10-0x5c]
  ldxw r4, [r10-0x60]
  sub64 r3, r6
  stxb [r8+0x0], r3
  ja jmp_9ad8

jmp_9ab8:
  ldxdw r4, [r10-0x50]
  ldxdw r1, [r10-0x68]

jmp_9ac8:
  mov64 r2, r4
  rsh64 r2, 0x20

jmp_9ad8:
  stxw [r1+0x0], r4
  stxw [r1+0x4], r2
  exit

jmp_9af0:
  lddw r1, data_0810
  call fn_29a40

jmp_9b08:
  lddw r1, data_0828
  call fn_29938

fn_9b20:
  jlt r3, 0x5b, jmp_9b78
  mov64 r4, r3
  add64 r4, -0x12
  mov64 r9, r4
  div64 r9, 0x49
  mov64 r5, r9
  mul64 r5, 0x49
  mov64 r0, r4
  sub64 r0, r5
  jne r0, 0x0, jmp_9b78
  jle r4, 0x123, jmp_9b90

jmp_9b78:
  stb [r1+0x60], 0x2
  stw [r1+0x0], 0x2

jmp_9b88:
  exit

jmp_9b90:
  mov64 r5, r3
  add64 r5, -0xa
  jlt r5, r4, jmp_a418
  mov64 r0, r3
  add64 r0, -0x2
  jlt r0, r5, jmp_a440
  mov64 r6, r2
  add64 r6, r0
  ldxh r6, [r6+0x0]
  jle r6, 0x3e8, jmp_9c08
  lddw r2, 0x2000000000
  stxdw [r1+0x0], r2
  stb [r1+0x60], 0x2
  ja jmp_9b88

jmp_9c08:
  mov64 r0, r2
  add64 r0, r4
  ldxdw r7, [r0+0x0]
  mov64 r4, r2
  add64 r4, r5
  ldxdw r8, [r4+0x0]
  mov64 r4, r7
  add64 r4, -0x1
  jge r4, r8, jmp_9b78
  stxdw [r10-0x178], r2
  stxdw [r10-0x170], r3
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, 0xa
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x130]
  jne r2, 0x0, jmp_a190
  mov64 r1, 0x0
  mov64 r5, -0x1
  ldxdw r2, [r10-0x170]
  jeq r1, 0x0, jmp_a1a8

jmp_9cd8:
  ldxdw r3, [r10-0x168]
  ldxdw r4, [r10-0x178]
  jge r8, r5, jmp_a1c8

jmp_9cf0:
  stxdw [r10-0x190], r8
  stxdw [r10-0x198], r7
  stxdw [r10-0x188], r6
  mov64 r8, 0x0
  mov64 r1, r10
  add64 r1, -0xe0
  stxdw [r10-0x140], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x180], r1
  stb [r10-0xe0], 0x0
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x0
  stdw [r10-0x100], 0x0
  stdw [r10-0x108], 0x0
  stdw [r10-0x110], 0x0
  stdw [r10-0x118], 0x0
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x0
  stdw [r10-0xdc], 0x0
  stdw [r10-0xd4], 0x0
  stdw [r10-0xcc], 0x0
  stdw [r10-0xc4], 0x0
  stdw [r10-0xbc], 0x0
  stdw [r10-0xb4], 0x0
  stdw [r10-0xac], 0x0
  stdw [r10-0xa4], 0x0
  stdw [r10-0x9c], 0x0
  stb [r10-0x94], 0x0
  stb [r10-0x48], 0x0
  stdw [r10-0x50], 0x0
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x0
  stdw [r10-0x68], 0x0
  stdw [r10-0x70], 0x0
  stdw [r10-0x78], 0x0
  stdw [r10-0x80], 0x0
  stdw [r10-0x88], 0x0
  stdw [r10-0x90], 0x0
  mov64 r0, r9
  mov64 r6, r3
  ja jmp_9ed8

jmp_9e48:
  add64 r7, -0x1
  ldxdw r2, [r10-0x140]
  stxb [r2+0x0], r1
  ldxdw r1, [r10-0x160]
  stxb [r2-0x1], r1
  stxb [r2-0x2], r6
  ldxdw r1, [r10-0x158]
  stxh [r2-0x4], r1
  ldxdw r1, [r10-0x148]
  stxw [r2-0x8], r1
  add64 r8, 0x49
  add64 r2, 0x4c
  stxdw [r10-0x140], r2
  ldxdw r6, [r10-0x168]
  ldxdw r2, [r10-0x170]
  ldxdw r4, [r10-0x178]
  mov64 r0, r7
  jeq r0, 0x0, jmp_a208

jmp_9ed8:
  mov64 r1, r8
  add64 r1, 0x44
  jgt r1, r2, jmp_a468
  jge r1, r2, jmp_a4b8
  mov64 r5, r4
  add64 r5, r8
  ldxb r7, [r5+0x44]
  jgt r7, 0x1, jmp_a378
  mov64 r1, r8
  add64 r1, 0x45
  jge r1, r2, jmp_a4e0
  mov64 r1, r4
  add64 r1, r8
  ldxb r6, [r1+0x45]
  jge r6, 0x6, jmp_a1f0
  ldxw r3, [r5+0x40]
  mov64 r1, r6
  lsh64 r1, 0x2
  lddw r5, data_04f0
  add64 r5, r1
  ldxw r1, [r5+0x0]
  stxdw [r10-0x148], r3
  mov64 r5, r3
  jgt r5, r1, jmp_a1f0
  mov64 r1, r8
  add64 r1, 0x48
  jgt r1, r2, jmp_a480
  mov64 r5, r4
  add64 r5, r8
  ldxh r3, [r5+0x46]
  jeq r3, 0x0, jmp_9ff0
  jeq r6, 0x2, jmp_9fe8
  jne r6, 0x4, jmp_a400

jmp_9fe8:
  jgt r3, 0x3e8, jmp_a1f0

jmp_9ff0:
  jge r1, r2, jmp_a4f8
  mov64 r1, r4
  add64 r1, r8
  ldxb r5, [r1+0x48]
  jeq r6, 0x4, jmp_a048
  jne r6, 0x5, jmp_a060
  mov64 r1, r5
  add64 r1, -0x13
  and64 r1, 0xff
  jge r1, 0xee, jmp_a068
  ja jmp_a1f0

jmp_a048:
  jeq r5, 0x12, jmp_a068
  jeq r5, 0x8, jmp_a068
  ja jmp_a1f0

jmp_a060:
  jne r5, 0x0, jmp_a1f0

jmp_a068:
  stxdw [r10-0x160], r5
  stxdw [r10-0x158], r3
  stxdw [r10-0x150], r7
  mov64 r7, r0
  mov64 r1, r8
  add64 r1, 0x20
  jgt r1, r2, jmp_a498
  ldxdw r1, [r10-0x140]
  add64 r1, -0x48
  mov64 r2, r4
  add64 r2, r8
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x28], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x30], r3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x38], r3
  ldxdw r3, [r2+0x0]
  stxdw [r10-0x40], r3
  ldxdw r3, [r2+0x38]
  ldxdw r4, [r10-0x180]
  stxdw [r4+0x18], r3
  ldxdw r3, [r2+0x30]
  stxdw [r4+0x10], r3
  ldxdw r3, [r2+0x28]
  stxdw [r4+0x8], r3
  ldxdw r2, [r2+0x20]
  stxdw [r4+0x0], r2
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, 0x40
  call fn_2a090
  mov64 r1, 0x1
  ldxdw r2, [r10-0x150]
  jeq r2, 0x1, jmp_9e48
  mov64 r1, 0x0
  ja jmp_9e48

jmp_a190:
  mov64 r5, -0x1
  ldxdw r2, [r10-0x170]
  jne r1, 0x0, jmp_9cd8

jmp_a1a8:
  ldxdw r5, [r10-0x138]
  ldxdw r3, [r10-0x168]
  ldxdw r4, [r10-0x178]
  jlt r8, r5, jmp_9cf0

jmp_a1c8:
  lddw r1, 0x2000000000
  stxdw [r3+0x0], r1
  stb [r3+0x60], 0x2
  ja jmp_9b88

jmp_a1f0:
  mov64 r1, 0x20
  ldxdw r6, [r10-0x168]
  ja jmp_a380

jmp_a208:
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r9
  mul64 r2, 0x4c
  ldxdw r7, [r10-0x188]
  ldxdw r8, [r10-0x190]

jmp_a238:
  jeq r2, 0x0, jmp_a2a0
  ldxb r4, [r1+0x46]
  add64 r2, -0x4c
  add64 r1, 0x4c
  jgt r4, 0x5, jmp_a238
  and64 r4, 0x3f
  mov64 r5, 0x14
  rsh64 r5, r4
  and64 r5, 0x1
  jeq r5, 0x0, jmp_a238
  jeq r7, 0x0, jmp_a2b0
  mov64 r1, r7
  ja jmp_a2b8

jmp_a2a0:
  mov64 r1, 0x27
  jne r7, 0x0, jmp_a380

jmp_a2b0:
  mov64 r1, 0xc8

jmp_a2b8:
  mov64 r2, 0x0
  mov64 r4, r9
  mul64 r4, 0x4c
  ja jmp_a2f0

jmp_a2d8:
  jgt r5, r1, jmp_a378

jmp_a2e0:
  add64 r2, 0x4c
  jeq r4, r2, jmp_a3a0

jmp_a2f0:
  mov64 r5, r10
  add64 r5, -0x128
  add64 r5, r2
  ldxb r5, [r5+0x46]
  jgt r5, 0x5, jmp_a378
  mov64 r0, 0x1
  lsh64 r0, r5
  and64 r0, 0x2b
  jne r0, 0x0, jmp_a2e0
  mov64 r5, r10
  add64 r5, -0x128
  add64 r5, r2
  ldxh r0, [r5+0x44]
  mov64 r5, 0xc8
  jeq r0, 0x0, jmp_a2d8
  mov64 r5, r0
  ja jmp_a2d8

jmp_a378:
  mov64 r1, 0x20

jmp_a380:
  stxw [r6+0x4], r1
  stb [r6+0x60], 0x2
  stw [r6+0x0], 0x0
  ja jmp_9b88

jmp_a3a0:
  mov64 r1, r6
  add64 r1, 0x18
  mov64 r2, r10
  add64 r2, -0x128
  mov64 r3, 0xe4
  call fn_2a090
  stxh [r6+0xfc], r7
  stxdw [r6+0x10], r8
  ldxdw r1, [r10-0x198]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r9
  ja jmp_9b88

jmp_a400:
  mov64 r1, 0x27
  ldxdw r6, [r10-0x168]
  ja jmp_a380

jmp_a418:
  mov64 r1, r4
  mov64 r2, r5
  lddw r3, data_0a00
  call fn_292f0

jmp_a440:
  mov64 r1, r5
  mov64 r2, r0
  lddw r3, data_0a18
  call fn_292f0

jmp_a468:
  lddw r3, data_0a30
  call fn_292e8

jmp_a480:
  lddw r3, data_0a78
  call fn_292e8

jmp_a498:
  ldxdw r2, [r10-0x170]
  lddw r3, data_0aa8
  call fn_292e8

jmp_a4b8:
  add64 r8, 0x44
  mov64 r1, r8
  lddw r3, data_0a48
  call fn_28b70

jmp_a4e0:
  lddw r3, data_0a60
  call fn_28b70

jmp_a4f8:
  add64 r8, 0x48
  mov64 r1, r8
  lddw r3, data_0a90
  call fn_28b70

fn_a520:
  mov64 r6, r1
  ldxdw r7, [r2+0x18]
  ldxdw r9, [r2+0x10]
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x108], r1
  ldxdw r8, [r2+0x0]
  lddw r1, str_042e
  mov64 r2, 0xd
  call sol_log_
  mov64 r2, 0xa
  jlt r7, 0x4, jmp_a7a8
  ldxdw r1, [r9+0x0]
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_a798
  ldxdw r2, [r1+0x8]
  lddw r3, -0x60f4508de13d20f0
  jne r2, r3, jmp_a620
  ldxdw r2, [r1+0x10]
  lddw r3, -0x1a9939e80f5e6338
  jne r2, r3, jmp_a620
  ldxdw r2, [r1+0x18]
  lddw r3, 0x456c527702a976f0
  jne r2, r3, jmp_a620
  mov64 r3, 0x0
  ldxdw r1, [r1+0x20]
  lddw r2, -0x3c173f54b221ad4c
  jeq r1, r2, jmp_a628

jmp_a620:
  mov64 r3, 0x1

jmp_a628:
  lddw r2, 0x700000000
  jne r3, 0x0, jmp_a7a8
  mov64 r5, r9
  add64 r5, 0x8
  ldxdw r1, [r5+0x0]
  ldxb r2, [r1+0x2]
  jeq r2, 0x0, jmp_a7d0
  ldxdw r2, [r1+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r2, r3, jmp_a6f0
  ldxdw r2, [r1+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_a6f0
  ldxdw r2, [r1+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_a6f0
  mov64 r3, 0x0
  ldxdw r2, [r1+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r2, r4, jmp_a6f8

jmp_a6f0:
  mov64 r3, 0x1

jmp_a6f8:
  lddw r2, 0x900000000
  jne r3, 0x0, jmp_a7a8
  lddw r2, 0xa00000000
  ldxdw r1, [r1+0x50]
  jne r1, 0x103, jmp_a7a8
  stxdw [r10-0x110], r5
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r8
  ldxdw r3, [r10-0x108]
  call fn_9b20
  ldxw r2, [r10-0xfc]
  ldxw r1, [r10-0x100]
  ldxb r3, [r10-0xa0]
  jne r3, 0x2, jmp_a7e0
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  ja jmp_a7c0

jmp_a798:
  lddw r2, 0x800000000

jmp_a7a8:
  stxw [r6+0x0], r2
  rsh64 r2, 0x20
  stxw [r6+0x4], r2

jmp_a7c0:
  stb [r6+0x60], 0x2

jmp_a7c8:
  exit

jmp_a7d0:
  mov64 r2, 0x0
  ja jmp_a7a8

jmp_a7e0:
  add64 r7, -0x4
  mov64 r4, r9
  add64 r4, 0x20
  stxdw [r10-0x120], r4
  mov64 r8, r9
  add64 r8, 0x10
  stxdw [r10-0x108], r1
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x118], r2
  mov64 r2, r10
  add64 r2, -0xf8
  stxdw [r10-0x128], r3
  mov64 r3, 0x58
  call fn_2a090
  mov64 r1, r6
  add64 r1, 0x61
  mov64 r2, r10
  add64 r2, -0x9f
  mov64 r3, 0x9f
  call fn_2a090
  stxdw [r6+0x120], r7
  ldxdw r1, [r10-0x120]
  stxdw [r6+0x118], r1
  stxdw [r6+0x110], r8
  ldxdw r2, [r10-0x110]
  mov64 r1, r2
  rsh64 r1, 0x20
  stxw [r6+0x10c], r1
  stxw [r6+0x108], r2
  stxdw [r6+0x100], r9
  ldxdw r1, [r10-0x128]
  stxb [r6+0x60], r1
  ldxdw r1, [r10-0x118]
  stxw [r6+0x4], r1
  ldxdw r1, [r10-0x108]
  stxw [r6+0x0], r1
  ja jmp_a7c8

fn_a910:
  ldxdw r6, [r2+0x0]
  jge r6, 0x4, jmp_ae88
  jeq r6, 0x0, jmp_bc40
  mov64 r7, 0x1f
  mov64 r3, r6
  add64 r3, -0x1
  ldxdw r4, [r2+0x120]
  jge r4, r3, jmp_a960

jmp_a950:
  mov64 r9, 0x0
  ja jmp_b988

jmp_a960:
  ldxdw r7, [r2+0x108]
  ldxdw r3, [r7+0x0]
  ldxdw r4, [r3+0x28]
  lddw r5, -0x2ef915ab4fa6d9f4
  jne r4, r5, jmp_a9f8
  ldxdw r4, [r3+0x30]
  lddw r5, 0x626c582b5813378e
  jne r4, r5, jmp_a9f8
  ldxdw r4, [r3+0x38]
  lddw r5, -0x164c5fdb9d1c7931
  jne r4, r5, jmp_a9f8
  mov64 r4, 0x0
  ldxdw r5, [r3+0x40]
  lddw r0, -0xe007a018e0ac636
  jeq r5, r0, jmp_aa00

jmp_a9f8:
  mov64 r4, 0x1

jmp_aa00:
  lddw r9, 0x900000000
  jne r4, 0x0, jmp_b978
  lddw r9, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_b978
  stxdw [r10-0xc0], r2
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r7
  call fn_28528
  ldxw r9, [r10-0x5c]
  ldxw r1, [r10-0x60]
  ldxdw r3, [r10-0x68]
  jeq r3, 0x0, jmp_b960
  lsh64 r9, 0x20
  or64 r9, r1
  jlt r9, 0x24, jmp_c530
  ldxb r1, [r10-0x50]
  mov64 r0, r1
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  jgt r0, 0x7, jmp_c500
  ldxdw r4, [r10-0x58]
  mov64 r5, 0x1
  lsh64 r5, r0
  mov64 r8, r5
  and64 r8, 0xff
  ldxb r0, [r4+0x0]
  jlt r0, r8, jmp_c518
  ldxb r3, [r3+0x23]
  sub64 r0, r5
  stxb [r4+0x0], r0
  lddw r9, 0x2600000000
  jne r3, 0x2, jmp_b978
  mov64 r9, 0xb
  ldxdw r8, [r7+0x0]
  ldxb r3, [r8+0x0]
  mov64 r4, r3
  and64 r4, 0xf
  jne r4, 0x0, jmp_b978
  mov64 r7, r2
  add64 r7, 0x18
  or64 r3, 0x8
  stxb [r8+0x0], r3
  ldxh r5, [r2+0xfc]
  mov64 r2, r8
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r3, r7
  mov64 r4, r6
  call fn_18eb0
  ldxw r9, [r10-0x70]
  jne r9, 0x1a, jmp_ae58
  stxdw [r10-0xc8], r7
  ldxb r1, [r8+0x0]
  and64 r1, 0xf7
  stxb [r8+0x0], r1
  ldxdw r1, [r10-0xc0]
  ldxdw r8, [r1+0x108]
  ldxdw r2, [r8+0x0]
  ldxdw r1, [r2+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r1, r3, jmp_ac90
  ldxdw r1, [r2+0x30]
  lddw r3, 0x626c582b5813378e
  jne r1, r3, jmp_ac90
  ldxdw r1, [r2+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r1, r3, jmp_ac90
  mov64 r3, 0x0
  ldxdw r1, [r2+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r1, r4, jmp_ac98

jmp_ac90:
  mov64 r3, 0x1

jmp_ac98:
  mov64 r7, 0x9
  ldxdw r1, [r10-0xb8]
  jne r3, 0x0, jmp_a950
  mov64 r7, 0xa
  ldxdw r2, [r2+0x50]
  jne r2, 0x103, jmp_a950
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r8
  call fn_28528
  ldxw r9, [r10-0x5c]
  ldxw r1, [r10-0x60]
  ldxdw r2, [r10-0x68]
  jeq r2, 0x0, jmp_aeb0
  lsh64 r9, 0x20
  or64 r9, r1
  jlt r9, 0x24, jmp_ce60
  ldxb r1, [r10-0x50]
  mov64 r5, r1
  ldxdw r1, [r10-0xb8]
  jgt r5, 0x7, jmp_c500
  ldxdw r3, [r10-0x58]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r3+0x0]
  jlt r5, r0, jmp_c518
  ldxb r2, [r2+0x23]
  sub64 r5, r4
  stxb [r3+0x0], r5
  mov64 r7, 0x26
  mov64 r9, 0x0
  jne r2, 0x2, jmp_b988
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r8
  call fn_28528
  ldxdw r8, [r10-0x68]
  jeq r8, 0x0, jmp_aec8
  mov64 r3, 0x0
  ldxb r1, [r10-0x50]
  stxdw [r10-0xd8], r1
  ldxdw r2, [r10-0x58]
  ldxb r1, [r8+0x27]
  stxdw [r10-0xd0], r2
  jne r1, 0x0, jmp_ae48
  ldxb r1, [r8+0x26]
  jgt r1, 0x1, jmp_ae48
  ldxb r2, [r8+0x22]
  mov64 r1, r2
  add64 r1, -0x4
  and64 r1, 0xff
  jge r1, 0xfd, jmp_b048

jmp_ae48:
  mov64 r7, 0x20
  ja jmp_b2e8

jmp_ae58:
  ldxw r7, [r10-0x6c]
  ldxb r1, [r8+0x0]
  and64 r1, 0xf7
  stxb [r8+0x0], r1

jmp_ae78:
  ldxdw r1, [r10-0xb8]
  ja jmp_b988

jmp_ae88:
  mov64 r1, r6
  mov64 r2, 0x3
  lddw r3, data_0ac0
  call fn_292e8

jmp_aeb0:
  lsh64 r9, 0x20
  or64 r9, r1
  ja jmp_aed0

jmp_aec8:
  ldxdw r9, [r10-0x60]

jmp_aed0:
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  mov64 r7, r9
  rsh64 r7, 0x20
  mov64 r3, r9
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_b988
  ldxdw r8, [r2+0x108]
  and64 r7, 0x1
  jeq r7, 0x0, jmp_b720

jmp_af28:
  mov64 r0, 0x0
  mov64 r5, 0x0
  mov64 r7, 0x0

jmp_af40:
  ldxdw r1, [r8+0x0]
  stb [r10-0x68], 0xe
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x67], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x5f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x57], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x4f], r1
  ldxdw r4, [r10-0xc8]
  ldxdw r1, [r4+0x18]
  ldxdw r2, [r4+0x10]
  ldxdw r3, [r4+0x8]
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x1f], r7
  stxdw [r10-0x27], r5
  stxdw [r10-0x47], r4
  stxdw [r10-0x3f], r3
  stxdw [r10-0x37], r2
  stxdw [r10-0x2f], r1
  stxb [r10-0x13], r6
  stxw [r10-0x17], r0
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x56
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r9, 0x1a
  ja jmp_ae78

jmp_b048:
  stxdw [r10-0xe0], r2
  mov64 r1, r2
  mul64 r1, 0x49
  and64 r1, 0xff
  jne r1, 0xdb, jmp_b0f8

jmp_b070:
  ldxb r1, [r8+0x6c]
  jgt r1, 0x1, jmp_b2d8
  ldxb r2, [r8+0x6d]
  jgt r2, 0x5, jmp_b2d8
  ldxdw r1, [r10-0xc0]
  ldxdw r0, [r1+0x110]
  ldxdw r4, [r1+0x118]
  stxdw [r10-0xf0], r4
  ldxdw r1, [r1+0x120]
  stxdw [r10-0xe8], r1
  ldxb r7, [r8+0x70]
  jeq r2, 0x5, jmp_b2b8
  jne r2, 0x4, jmp_b3a8
  mov64 r4, 0x3
  jeq r7, 0x8, jmp_b360
  jeq r7, 0x12, jmp_b360
  ja jmp_b2d8

jmp_b0f8:
  mov64 r2, 0xdb
  mov64 r4, r8

jmp_b108:
  mov64 r5, r4
  add64 r5, r1
  ldxdw r0, [r5+0x28]
  jne r0, 0x0, jmp_b158
  ldxdw r0, [r5+0x30]
  jne r0, 0x0, jmp_b158
  ldxdw r0, [r5+0x38]
  jne r0, 0x0, jmp_b158
  ldxdw r5, [r5+0x40]
  jeq r5, 0x0, jmp_b258

jmp_b158:
  mov64 r5, 0x1
  jne r5, 0x0, jmp_b2d8

jmp_b168:
  mov64 r5, r4
  add64 r5, r1
  ldxdw r0, [r5+0x48]
  jne r0, 0x0, jmp_b1b8
  ldxdw r0, [r5+0x50]
  jne r0, 0x0, jmp_b1b8
  ldxdw r0, [r5+0x58]
  jne r0, 0x0, jmp_b1b8
  ldxdw r5, [r5+0x60]
  jeq r5, 0x0, jmp_b270

jmp_b1b8:
  mov64 r5, 0x1
  jne r5, 0x0, jmp_b2d8

jmp_b1c8:
  mov64 r5, r4
  add64 r5, r1
  ldxw r0, [r5+0x68]
  jne r0, 0x0, jmp_b2d8
  ldxb r0, [r5+0x6c]
  jne r0, 0x0, jmp_b2d8
  ldxb r0, [r5+0x6d]
  jne r0, 0x0, jmp_b2d8
  ldxh r5, [r5+0x6e]
  jne r5, 0x0, jmp_b2d8
  mov64 r5, r4
  add64 r5, r1
  ldxb r5, [r5+0x70]
  jne r5, 0x0, jmp_b2d8
  add64 r4, 0x49
  add64 r2, -0x49
  jne r1, r2, jmp_b108
  ja jmp_b288

jmp_b258:
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_b168
  ja jmp_b2d8

jmp_b270:
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_b1c8
  ja jmp_b2d8

jmp_b288:
  ldxdw r1, [r10-0xe0]
  jne r1, 0x0, jmp_b070
  mov64 r5, 0x0
  mov64 r1, 0x0
  stxdw [r10-0xf8], r1
  ja jmp_b510

jmp_b2b8:
  mov64 r4, 0x7
  add64 r7, -0x13
  and64 r7, 0xff
  jge r7, 0xee, jmp_b360

jmp_b2d8:
  mov64 r7, 0x20

jmp_b2e0:
  mov64 r9, 0x0

jmp_b2e8:
  ldxdw r1, [r10-0xb8]

jmp_b2f0:
  ldxdw r2, [r10-0xd8]
  mov64 r4, r2
  jgt r4, 0x7, jmp_c500
  mov64 r2, 0x1
  lsh64 r2, r4
  mov64 r5, r2
  and64 r5, 0xff
  ldxdw r0, [r10-0xd0]
  ldxb r4, [r0+0x0]
  jlt r4, r5, jmp_c518
  sub64 r4, r2
  stxb [r0+0x0], r4
  or64 r7, r3
  ja jmp_b988

jmp_b360:
  mov64 r7, 0x1b
  ldxb r1, [r8+0x48]
  jne r1, 0x0, jmp_b2e0
  ldxb r1, [r8+0x49]
  mov64 r5, r1
  mov64 r9, 0x0
  ldxdw r1, [r10-0xb8]
  jeq r5, r4, jmp_b3d0
  ja jmp_b2f0

jmp_b3a8:
  ldxdw r1, [r10-0xb8]
  jeq r7, 0x0, jmp_b3d0

jmp_b3b8:
  mov64 r7, 0x20
  mov64 r9, 0x0
  ja jmp_b2f0

jmp_b3d0:
  mov64 r5, 0x0
  mov64 r1, 0x1
  lsh64 r1, r2
  and64 r1, 0xb
  jne r1, 0x0, jmp_b4e8
  ldxdw r2, [r8+0x28]
  ldxdw r1, [r0+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_b468
  ldxdw r2, [r8+0x30]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_b468
  ldxdw r2, [r8+0x38]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_b468
  mov64 r2, 0x0
  ldxdw r3, [r8+0x40]
  ldxdw r4, [r1+0x20]
  jeq r4, r3, jmp_b470

jmp_b468:
  mov64 r2, 0x1

jmp_b470:
  jne r2, 0x0, jmp_b4e8
  ldxdw r2, [r1+0x50]
  jne r2, 0x0, jmp_b4e8
  ldxdw r2, [r1+0x28]
  jne r2, 0x0, jmp_b4c8
  ldxdw r2, [r1+0x30]
  jne r2, 0x0, jmp_b4c8
  ldxdw r2, [r1+0x38]
  jne r2, 0x0, jmp_b4c8
  ldxdw r1, [r1+0x40]
  jeq r1, 0x0, jmp_cac0

jmp_b4c8:
  mov64 r1, 0x1
  mov64 r5, 0x1
  jeq r1, 0x0, jmp_b4e8

jmp_b4e0:
  mov64 r5, 0x0

jmp_b4e8:
  mov64 r1, 0x0
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0xe0]
  jne r1, 0x1, jmp_bbd8

jmp_b508:
  mov64 r1, 0x0

jmp_b510:
  stxdw [r10-0x100], r1

jmp_b518:
  mov64 r1, r5
  and64 r1, 0x1
  jne r1, 0x0, jmp_b568
  ldxdw r1, [r10-0xf8]
  and64 r1, 0x1
  jne r1, 0x0, jmp_b568
  mov64 r7, 0x0
  ldxdw r1, [r10-0x100]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_b690

jmp_b568:
  mov64 r7, 0x1
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x0, jmp_b690
  ldxdw r1, [r10-0xc0]
  ldxdw r2, [r1+0x120]
  stxdw [r10-0xe8], r2
  ldxdw r1, [r1+0x118]
  stxdw [r10-0xf0], r1
  and64 r5, 0x1
  jeq r5, 0x0, jmp_bc58

jmp_b5b8:
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x1, jmp_b690
  ldxdw r1, [r10-0xe8]
  jeq r1, 0x0, jmp_b690
  ldxdw r1, [r10-0xf8]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_c388

jmp_b5f0:
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x2, jmp_b690
  ldxdw r2, [r10-0xe8]
  lsh64 r2, 0x3
  ldxdw r1, [r10-0xf0]
  mov64 r3, r1
  add64 r3, r2
  add64 r1, 0x8
  stxdw [r10-0xf0], r1
  stxdw [r10-0xe8], r3
  jeq r1, r3, jmp_b690
  ldxdw r1, [r10-0x100]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_c558

jmp_b660:
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x3, jmp_b690
  ldxdw r1, [r10-0xf0]
  add64 r1, 0x8
  ldxdw r2, [r10-0xe8]
  jne r1, r2, jmp_ced8

jmp_b690:
  ldxdw r1, [r10-0xd8]
  mov64 r2, r1
  jgt r2, 0x7, jmp_c500
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxdw r2, [r10-0xd0]
  ldxb r2, [r2+0x0]
  jlt r2, r3, jmp_c518
  sub64 r2, r1
  ldxdw r1, [r10-0xd0]
  stxb [r1+0x0], r2
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  ldxdw r8, [r2+0x108]
  and64 r7, 0x1
  jne r7, 0x0, jmp_af28

jmp_b720:
  ldxdw r2, [r8+0x0]
  ldxdw r3, [r2+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r3, r4, jmp_b7b0
  ldxdw r3, [r2+0x30]
  lddw r4, 0x626c582b5813378e
  jne r3, r4, jmp_b7b0
  ldxdw r3, [r2+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r3, r4, jmp_b7b0
  mov64 r3, 0x0
  ldxdw r4, [r2+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r4, r5, jmp_b7b8

jmp_b7b0:
  mov64 r3, 0x1

jmp_b7b8:
  lddw r9, 0x900000000
  jne r3, 0x0, jmp_b978
  lddw r9, 0xa00000000
  ldxdw r2, [r2+0x50]
  jne r2, 0x103, jmp_b978
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r8
  call fn_28528
  ldxw r9, [r10-0x5c]
  ldxw r1, [r10-0x60]
  ldxdw r3, [r10-0x68]
  jeq r3, 0x0, jmp_b960
  lsh64 r9, 0x20
  or64 r9, r1
  jlt r9, 0x24, jmp_ce60
  ldxb r2, [r10-0x50]
  ldxdw r1, [r10-0x58]
  ldxb r7, [r3+0x23]
  call fn_0788
  lddw r9, 0x2600000000
  ldxdw r1, [r10-0xb8]
  jne r7, 0x2, jmp_b978
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r8
  call fn_28528
  ldxdw r2, [r10-0x68]
  jeq r2, 0x0, jmp_b9a0
  ldxb r7, [r10-0x50]
  ldxdw r9, [r10-0x58]
  ldxdw r1, [r10-0xc0]
  ldxdw r5, [r1+0x120]
  ldxdw r4, [r1+0x118]
  ldxdw r3, [r1+0x110]
  mov64 r1, r10
  add64 r1, -0x68
  call fn_196a8
  ldxw r1, [r10-0x68]
  stxdw [r10-0xd8], r1
  ldxw r1, [r10-0x64]
  stxdw [r10-0xd0], r1
  ldxh r1, [r10-0x54]
  jne r1, 0x2, jmp_b9b0
  mov64 r1, r9
  mov64 r2, r7
  call fn_0788
  ldxdw r7, [r10-0xd0]
  ldxdw r9, [r10-0xd8]
  ja jmp_ae78

jmp_b960:
  lsh64 r9, 0x20
  or64 r9, r1

jmp_b970:
  ldxdw r1, [r10-0xb8]

jmp_b978:
  mov64 r7, r9
  rsh64 r7, 0x20

jmp_b988:
  stxw [r1+0x4], r7
  stxw [r1+0x0], r9
  exit

jmp_b9a0:
  ldxdw r9, [r10-0x60]
  ja jmp_b970

jmp_b9b0:
  ldxw r8, [r10-0x58]
  ldxdw r1, [r10-0x60]
  stxdw [r10-0xe0], r1
  mov64 r1, r9
  mov64 r2, r7
  call fn_0788
  mov64 r9, 0x0
  mov64 r7, 0x23
  stxdw [r10-0xe8], r8
  lsh64 r8, 0x20
  arsh64 r8, 0x20
  add64 r8, 0x6
  mov64 r2, r8
  lsh64 r2, 0x20
  arsh64 r2, 0x20
  jne r2, r8, jmp_ae78
  ldxdw r3, [r10-0xd0]
  lsh64 r3, 0x20
  ldxdw r1, [r10-0xd8]
  or64 r3, r1
  stxdw [r10-0xd0], r3
  jsle r2, -0x1, jmp_bcd0
  mov64 r1, r10
  add64 r1, -0x68
  call fn_02a8
  ldxdw r1, [r10-0x68]
  jeq r1, 0x0, jmp_ae78
  mov64 r1, r10
  add64 r1, -0xb0
  ldxdw r4, [r10-0x60]
  stxdw [r10-0xd8], r4
  ldxdw r2, [r10-0xe0]
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xa0
  ldxdw r2, [r10-0x58]
  stxdw [r10-0xf0], r2
  mov64 r3, 0x0
  ldxdw r8, [r10-0xd0]
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r8
  mov64 r3, 0x0
  ldxdw r4, [r10-0xd8]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  mov64 r2, 0x1
  ldxdw r3, [r10-0xf0]
  jne r3, 0x0, jmp_bfb8
  mov64 r2, 0x0
  mov64 r3, 0x1
  ldxdw r4, [r10-0xe0]
  jeq r4, 0x0, jmp_bfd0

jmp_bb88:
  and64 r3, r2
  ldxdw r4, [r10-0xa8]
  mov64 r2, 0x1
  jne r4, 0x0, jmp_bff8

jmp_bba8:
  mov64 r2, 0x0
  or64 r3, r2
  ldxdw r4, [r10-0x98]
  mov64 r2, 0x1
  jeq r4, 0x0, jmp_c018
  ja jmp_c020

jmp_bbd8:
  mov64 r3, 0x0
  ldxb r1, [r8+0xb5]
  jgt r1, 0x1, jmp_b2d8
  ldxb r2, [r8+0xb6]
  jgt r2, 0x5, jmp_b2d8
  ldxb r0, [r8+0xb9]
  jeq r2, 0x4, jmp_bd70
  jne r2, 0x5, jmp_bdd0
  mov64 r4, 0x7
  add64 r0, -0x13
  and64 r0, 0xff
  jlt r0, 0xee, jmp_b2d8
  ja jmp_bd88

jmp_bc40:
  lddw r1, data_0ad8
  call fn_29938

jmp_bc58:
  mov64 r9, 0x0
  mov64 r3, 0x20
  ldxb r1, [r8+0x6c]
  jgt r1, 0x1, jmp_ce40
  ldxb r1, [r8+0x6d]
  jgt r1, 0x5, jmp_ce40
  ldxdw r2, [r10-0xc0]
  ldxdw r2, [r2+0x110]
  ldxb r5, [r8+0x70]
  jeq r1, 0x5, jmp_c400
  jne r1, 0x4, jmp_c458
  mov64 r4, 0x3
  jeq r5, 0x8, jmp_c428
  jeq r5, 0x12, jmp_c428
  ja jmp_ce40

jmp_bcd0:
  neg64 r2
  mov64 r1, r10
  add64 r1, -0x68
  call fn_02a8
  ldxdw r1, [r10-0x68]
  jeq r1, 0x0, jmp_ae78
  ldxdw r5, [r10-0x58]
  ldxdw r4, [r10-0x60]
  mov64 r2, r4
  or64 r2, r5
  ldxdw r1, [r10-0xb8]
  jeq r2, 0x0, jmp_b988
  mov64 r1, r10
  add64 r1, -0x80
  ldxdw r2, [r10-0xd0]
  ldxdw r3, [r10-0xe0]
  call fn_2c2b0
  ldxdw r2, [r10-0x78]
  ldxdw r1, [r10-0x80]
  ja jmp_c090

jmp_bd70:
  mov64 r4, 0x3
  jeq r0, 0x12, jmp_bd88
  jne r0, 0x8, jmp_b2d8

jmp_bd88:
  mov64 r7, 0x1b
  ldxb r1, [r8+0x91]
  jne r1, 0x0, jmp_b2e0
  ldxb r1, [r8+0x92]
  mov64 r0, r1
  mov64 r9, 0x0
  ldxdw r1, [r10-0xb8]
  jeq r0, r4, jmp_bde0
  ja jmp_b2f0

jmp_bdd0:
  ldxdw r1, [r10-0xb8]
  jne r0, 0x0, jmp_b3b8

jmp_bde0:
  mov64 r1, 0x0
  stxdw [r10-0xf8], r1
  mov64 r1, 0x1
  lsh64 r1, r2
  and64 r1, 0xb
  jne r1, 0x0, jmp_bf38
  ldxdw r1, [r10-0xe8]
  jeq r1, 0x0, jmp_c4c0
  ldxdw r2, [r8+0x71]
  ldxdw r1, [r10-0xf0]
  ldxdw r1, [r1+0x0]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_be98
  ldxdw r2, [r8+0x79]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_be98
  ldxdw r2, [r8+0x81]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_be98
  mov64 r2, 0x0
  ldxdw r3, [r8+0x89]
  ldxdw r4, [r1+0x20]
  jeq r4, r3, jmp_bea0

jmp_be98:
  mov64 r2, 0x1

jmp_bea0:
  mov64 r3, 0x0
  stxdw [r10-0xf8], r3
  jne r2, 0x0, jmp_bf38
  ldxdw r2, [r1+0x50]
  jne r2, 0x0, jmp_bf38
  ldxdw r2, [r1+0x28]
  jne r2, 0x0, jmp_bf08
  ldxdw r2, [r1+0x30]
  jne r2, 0x0, jmp_bf08
  ldxdw r2, [r1+0x38]
  jne r2, 0x0, jmp_bf08
  ldxdw r1, [r1+0x40]
  jeq r1, 0x0, jmp_ce88

jmp_bf08:
  mov64 r1, 0x1
  mov64 r2, 0x1
  stxdw [r10-0xf8], r2
  jeq r1, 0x0, jmp_bf38

jmp_bf28:
  mov64 r1, 0x0
  stxdw [r10-0xf8], r1

jmp_bf38:
  mov64 r1, 0x0
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x2, jmp_b518
  ldxb r1, [r8+0xfe]
  jgt r1, 0x1, jmp_b2d8
  ldxb r0, [r8+0xff]
  jgt r0, 0x5, jmp_b2d8
  ldxb r4, [r8+0x102]
  jeq r0, 0x4, jmp_c678
  jne r0, 0x5, jmp_c6d8
  mov64 r2, 0x7
  add64 r4, -0x13
  and64 r4, 0xff
  jlt r4, 0xee, jmp_b2d8
  ja jmp_c690

jmp_bfb8:
  mov64 r3, 0x1
  ldxdw r4, [r10-0xe0]
  jne r4, 0x0, jmp_bb88

jmp_bfd0:
  mov64 r3, 0x0
  and64 r3, r2
  ldxdw r4, [r10-0xa8]
  mov64 r2, 0x1
  jeq r4, 0x0, jmp_bba8

jmp_bff8:
  or64 r3, r2
  ldxdw r4, [r10-0x98]
  mov64 r2, 0x1
  jne r4, 0x0, jmp_c020

jmp_c018:
  mov64 r2, 0x0

jmp_c020:
  or64 r3, r2
  ldxdw r2, [r10-0xa0]
  ldxdw r4, [r10-0xb0]
  add64 r4, r2
  ldxdw r5, [r10-0x88]
  mov64 r2, r5
  add64 r2, r4
  jlt r2, r5, jmp_c068
  mov64 r1, 0x0

jmp_c068:
  or64 r3, r1
  and64 r3, 0x1
  ldxdw r1, [r10-0xb8]
  jne r3, 0x0, jmp_b988
  ldxdw r1, [r10-0x90]

jmp_c090:
  ldxdw r3, [r10-0xc0]
  ldxdw r4, [r3+0x8]
  mov64 r3, 0x1
  jlt r1, r4, jmp_c0e0
  mov64 r3, 0x0
  jne r2, 0x0, jmp_c0e8

jmp_c0c0:
  mov64 r7, 0x21
  and64 r3, 0x1
  jne r3, 0x0, jmp_ae78
  ja jmp_c108

jmp_c0e0:
  jeq r2, 0x0, jmp_c0c0

jmp_c0e8:
  mov64 r3, 0x0
  mov64 r7, 0x21
  and64 r3, 0x1
  jne r3, 0x0, jmp_ae78

jmp_c108:
  ldxdw r3, [r10-0xc0]
  ldxdw r5, [r3+0x10]
  mov64 r4, 0x1
  mov64 r3, 0x1
  jgt r1, r5, jmp_c178
  mov64 r3, 0x0
  jeq r2, 0x0, jmp_c180

jmp_c140:
  jeq r2, 0x0, jmp_c190

jmp_c148:
  mov64 r3, r4
  and64 r3, 0x1
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  jne r3, 0x0, jmp_b988
  ja jmp_c1b0

jmp_c178:
  jne r2, 0x0, jmp_c140

jmp_c180:
  mov64 r4, 0x0
  jne r2, 0x0, jmp_c148

jmp_c190:
  and64 r3, 0x1
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  jne r3, 0x0, jmp_b988

jmp_c1b0:
  ldxdw r8, [r2+0x108]
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r1+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r2, r3, jmp_c248
  ldxdw r2, [r1+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_c248
  ldxdw r2, [r1+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_c248
  mov64 r2, 0x0
  ldxdw r3, [r1+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r3, r4, jmp_c250

jmp_c248:
  mov64 r2, 0x1

jmp_c250:
  lddw r9, 0x900000000
  jne r2, 0x0, jmp_ca00
  lddw r9, 0xa00000000
  ldxdw r1, [r1+0x50]
  jne r1, 0x103, jmp_ca00
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r8
  call fn_28528
  ldxw r9, [r10-0x5c]
  ldxw r1, [r10-0x60]
  ldxdw r3, [r10-0x68]
  jeq r3, 0x0, jmp_c9f0
  lsh64 r9, 0x20
  or64 r9, r1
  jlt r9, 0x24, jmp_c530
  ldxb r2, [r10-0x50]
  ldxdw r1, [r10-0x58]
  ldxb r7, [r3+0x23]
  call fn_0788
  lddw r9, 0x2600000000
  jne r7, 0x2, jmp_ca00
  mov64 r9, 0xb
  ldxdw r1, [r8+0x0]
  ldxb r2, [r1+0x0]
  and64 r2, 0xf
  jne r2, 0x0, jmp_ca00
  ldxb r2, [r1+0x7e]
  or64 r2, 0x1
  stxb [r1+0x7e], r2
  ldxdw r1, [r10-0xc0]
  ldxdw r8, [r1+0x108]
  ldxdw r5, [r10-0xd0]
  ldxdw r0, [r10-0xe8]
  ldxdw r7, [r10-0xe0]
  ja jmp_af40

jmp_c388:
  mov64 r9, 0x0
  mov64 r3, 0x20
  ldxb r1, [r8+0xb5]
  jgt r1, 0x1, jmp_ce40
  ldxb r1, [r8+0xb6]
  jgt r1, 0x5, jmp_ce40
  ldxb r2, [r8+0xb9]
  jeq r1, 0x4, jmp_c5d0
  jne r1, 0x5, jmp_c618
  mov64 r4, 0x7
  mov64 r5, r2
  add64 r5, -0x13
  and64 r5, 0xff
  jge r5, 0xee, jmp_c5e8
  ja jmp_ce40

jmp_c400:
  mov64 r4, 0x7
  mov64 r0, r5
  add64 r0, -0x13
  and64 r0, 0xff
  jlt r0, 0xee, jmp_ce40

jmp_c428:
  mov64 r3, 0x1b
  ldxb r0, [r8+0x48]
  jne r0, 0x0, jmp_ce40
  ldxb r0, [r8+0x49]
  jeq r0, r4, jmp_c460
  ja jmp_ce40

jmp_c458:
  jne r5, 0x0, jmp_ce40

jmp_c460:
  ldxh r3, [r8+0x6e]
  stxdw [r10-0x110], r3
  ldxw r3, [r8+0x68]
  stxdw [r10-0x108], r3
  jsgt r1, 0x2, jmp_c4d0
  jeq r1, 0x0, jmp_c848
  lddw r3, data_0120
  jeq r1, 0x1, jmp_c868
  lddw r3, data_0140
  ja jmp_c868

jmp_c4c0:
  mov64 r7, 0x1f
  ja jmp_b2e0

jmp_c4d0:
  mov64 r3, r1
  add64 r3, -0x4
  jge r3, 0x2, jmp_c858
  lddw r3, data_0160
  ja jmp_c868

jmp_c500:
  lddw r1, data_0810
  call fn_29a40

jmp_c518:
  lddw r1, data_0828
  call fn_29938

jmp_c530:
  mov64 r1, 0x23
  mov64 r2, r9
  lddw r3, data_0e50
  call fn_28b70

jmp_c558:
  mov64 r9, 0x0
  mov64 r3, 0x20
  ldxb r1, [r8+0xfe]
  jgt r1, 0x1, jmp_ce40
  ldxb r1, [r8+0xff]
  jgt r1, 0x5, jmp_ce40
  ldxb r2, [r8+0x102]
  jeq r1, 0x4, jmp_ca18
  jne r1, 0x5, jmp_ca60
  mov64 r4, 0x7
  mov64 r5, r2
  add64 r5, -0x13
  and64 r5, 0xff
  jge r5, 0xee, jmp_ca30
  ja jmp_ce40

jmp_c5d0:
  mov64 r4, 0x3
  jeq r2, 0x12, jmp_c5e8
  jne r2, 0x8, jmp_ce40

jmp_c5e8:
  mov64 r3, 0x1b
  ldxb r5, [r8+0x91]
  jne r5, 0x0, jmp_ce40
  ldxb r5, [r8+0x92]
  jeq r5, r4, jmp_c620
  ja jmp_ce40

jmp_c618:
  jne r2, 0x0, jmp_ce40

jmp_c620:
  ldxh r0, [r8+0xb7]
  ldxw r3, [r8+0xb1]
  stxdw [r10-0xf8], r3
  jsgt r1, 0x2, jmp_c9c0
  jeq r1, 0x0, jmp_caf0
  lddw r3, data_0120
  jeq r1, 0x1, jmp_cb10
  lddw r3, data_0140
  ja jmp_cb10

jmp_c678:
  mov64 r2, 0x3
  jeq r4, 0x12, jmp_c690
  jne r4, 0x8, jmp_b2d8

jmp_c690:
  mov64 r7, 0x1b
  ldxb r1, [r8+0xda]
  jne r1, 0x0, jmp_b2e0
  ldxb r1, [r8+0xdb]
  mov64 r4, r1
  mov64 r9, 0x0
  ldxdw r1, [r10-0xb8]
  jeq r4, r2, jmp_c6f8
  ja jmp_b2f0

jmp_c6d8:
  mov64 r7, 0x20
  mov64 r9, 0x0
  ldxdw r1, [r10-0xb8]
  jne r4, 0x0, jmp_b2f0

jmp_c6f8:
  mov64 r1, 0x0
  stxdw [r10-0x100], r1
  mov64 r1, 0x1
  lsh64 r1, r0
  and64 r1, 0xb
  jne r1, 0x0, jmp_b518
  ldxdw r1, [r10-0xe8]
  jlt r1, 0x2, jmp_cae0
  ldxdw r2, [r8+0xba]
  ldxdw r1, [r10-0xf0]
  ldxdw r1, [r1+0x8]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_c7b0
  ldxdw r2, [r8+0xc2]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_c7b0
  ldxdw r2, [r8+0xca]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_c7b0
  mov64 r2, 0x0
  ldxdw r3, [r8+0xd2]
  ldxdw r4, [r1+0x20]
  jeq r4, r3, jmp_c7b8

jmp_c7b0:
  mov64 r2, 0x1

jmp_c7b8:
  mov64 r3, 0x0
  stxdw [r10-0x100], r3
  jne r2, 0x0, jmp_b518
  ldxdw r2, [r1+0x50]
  jne r2, 0x0, jmp_b518
  ldxdw r2, [r1+0x28]
  jne r2, 0x0, jmp_c820
  ldxdw r2, [r1+0x30]
  jne r2, 0x0, jmp_c820
  ldxdw r2, [r1+0x38]
  jne r2, 0x0, jmp_c820
  ldxdw r1, [r1+0x40]
  jeq r1, 0x0, jmp_ceb0

jmp_c820:
  mov64 r1, 0x1
  mov64 r2, 0x1
  stxdw [r10-0x100], r2
  jne r1, 0x0, jmp_b508
  ja jmp_b518

jmp_c848:
  mov64 r0, 0x258
  ja jmp_c918

jmp_c858:
  lddw r3, data_0080

jmp_c868:
  ldxdw r0, [r3+0x0]
  ldxdw r4, [r2+0x0]
  ldxdw r9, [r4+0x28]
  jne r9, r0, jmp_c8d8
  ldxdw r0, [r3+0x8]
  ldxdw r9, [r4+0x30]
  jne r9, r0, jmp_c8d8
  ldxdw r0, [r3+0x10]
  ldxdw r9, [r4+0x38]
  jne r9, r0, jmp_c8d8
  mov64 r0, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r4+0x40]
  jeq r4, r3, jmp_c8e0

jmp_c8d8:
  mov64 r0, 0x1

jmp_c8e0:
  jne r0, 0x0, jmp_cd48
  mov64 r3, r1
  lsh64 r3, 0x2
  lddw r4, data_04f0
  add64 r4, r3
  ldxw r0, [r4+0x0]

jmp_c918:
  mov64 r3, r8
  add64 r3, 0x28
  mov64 r4, r8
  add64 r4, 0x48
  ldxdw r9, [r10-0x110]
  stxdw [r10-0xfe8], r9
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  ldxdw r1, [r10-0x108]
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jlt r0, r1, jmp_c980
  mov64 r0, r1

jmp_c980:
  stxdw [r10-0xff0], r0
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r5, r10
  call fn_14de0
  ldxh r1, [r10-0x54]
  jne r1, 0x2, jmp_b5b8
  ja jmp_ce30

jmp_c9c0:
  mov64 r3, r1
  add64 r3, -0x4
  jge r3, 0x2, jmp_cb00
  lddw r3, data_0160
  ja jmp_cb10

jmp_c9f0:
  lsh64 r9, 0x20
  or64 r9, r1

jmp_ca00:
  mov64 r7, r9
  rsh64 r7, 0x20
  ja jmp_ae78

jmp_ca18:
  mov64 r4, 0x3
  jeq r2, 0x12, jmp_ca30
  jne r2, 0x8, jmp_ce40

jmp_ca30:
  mov64 r3, 0x1b
  ldxb r5, [r8+0xda]
  jne r5, 0x0, jmp_ce40
  ldxb r5, [r8+0xdb]
  jeq r5, r4, jmp_ca68
  ja jmp_ce40

jmp_ca60:
  jne r2, 0x0, jmp_ce40

jmp_ca68:
  ldxh r5, [r8+0x100]
  ldxw r3, [r8+0xfa]
  stxdw [r10-0xf8], r3
  jsgt r1, 0x2, jmp_cc70
  jeq r1, 0x0, jmp_cca0
  lddw r3, data_0120
  jeq r1, 0x1, jmp_ccc0
  lddw r3, data_0140
  ja jmp_ccc0

jmp_cac0:
  mov64 r1, 0x0
  mov64 r5, 0x1
  jne r1, 0x0, jmp_b4e0
  ja jmp_b4e8

jmp_cae0:
  mov64 r7, 0x1f
  ja jmp_b2e8

jmp_caf0:
  mov64 r9, 0x258
  ja jmp_cbc8

jmp_cb00:
  lddw r3, data_0080

jmp_cb10:
  ldxdw r9, [r3+0x0]
  ldxdw r4, [r10-0xf0]
  ldxdw r4, [r4+0x0]
  ldxdw r5, [r4+0x28]
  jne r5, r9, jmp_cb88
  ldxdw r5, [r3+0x8]
  ldxdw r9, [r4+0x30]
  jne r9, r5, jmp_cb88
  ldxdw r5, [r3+0x10]
  ldxdw r9, [r4+0x38]
  jne r9, r5, jmp_cb88
  mov64 r9, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r4+0x40]
  jeq r4, r3, jmp_cb90

jmp_cb88:
  mov64 r9, 0x1

jmp_cb90:
  jne r9, 0x0, jmp_cd48
  mov64 r3, r1
  lsh64 r3, 0x2
  lddw r4, data_04f0
  add64 r4, r3
  ldxw r9, [r4+0x0]

jmp_cbc8:
  mov64 r3, r8
  add64 r3, 0x71
  mov64 r4, r8
  add64 r4, 0x91
  stxdw [r10-0xfe8], r0
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  ldxdw r1, [r10-0xf8]
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  jlt r9, r1, jmp_cc28
  mov64 r9, r1

jmp_cc28:
  stxdw [r10-0xff0], r9
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r5, r10
  ldxdw r2, [r10-0xf0]
  call fn_14de0
  ldxh r1, [r10-0x54]
  jne r1, 0x2, jmp_b5f0
  ja jmp_ce30

jmp_cc70:
  mov64 r3, r1
  add64 r3, -0x4
  jge r3, 0x2, jmp_ccb0
  lddw r3, data_0160
  ja jmp_ccc0

jmp_cca0:
  mov64 r0, 0x258
  ja jmp_cd90

jmp_ccb0:
  lddw r3, data_0080

jmp_ccc0:
  ldxdw r9, [r3+0x0]
  ldxdw r4, [r10-0xf0]
  ldxdw r0, [r4+0x0]
  ldxdw r4, [r0+0x28]
  jne r4, r9, jmp_cd38
  ldxdw r4, [r3+0x8]
  ldxdw r9, [r0+0x30]
  jne r9, r4, jmp_cd38
  ldxdw r4, [r3+0x10]
  ldxdw r9, [r0+0x38]
  jne r9, r4, jmp_cd38
  mov64 r9, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r0+0x40]
  jeq r4, r3, jmp_cd40

jmp_cd38:
  mov64 r9, 0x1

jmp_cd40:
  jeq r9, 0x0, jmp_cd60

jmp_cd48:
  mov64 r9, 0x0
  mov64 r3, 0x22
  ja jmp_ce40

jmp_cd60:
  mov64 r3, r1
  lsh64 r3, 0x2
  lddw r4, data_04f0
  add64 r4, r3
  ldxw r0, [r4+0x0]

jmp_cd90:
  mov64 r3, r8
  add64 r3, 0xba
  add64 r8, 0xda
  stxdw [r10-0xfe8], r5
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  ldxdw r1, [r10-0xf8]
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jlt r0, r1, jmp_cde8
  mov64 r0, r1

jmp_cde8:
  stxdw [r10-0xff0], r0
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r5, r10
  ldxdw r2, [r10-0xf0]
  mov64 r4, r8
  call fn_14de0
  ldxh r1, [r10-0x54]
  jne r1, 0x2, jmp_b660

jmp_ce30:
  ldxw r3, [r10-0x64]
  ldxw r9, [r10-0x68]

jmp_ce40:
  mov64 r7, r3
  and64 r7, 0xff
  and64 r3, -0x100
  ja jmp_b2e8

jmp_ce60:
  mov64 r1, 0x23
  mov64 r2, r9
  lddw r3, data_0e38
  call fn_28b70

jmp_ce88:
  mov64 r1, 0x0
  mov64 r2, 0x1
  stxdw [r10-0xf8], r2
  jne r1, 0x0, jmp_bf28
  ja jmp_bf38

jmp_ceb0:
  mov64 r1, 0x0
  mov64 r2, 0x1
  stxdw [r10-0x100], r2
  jne r1, 0x0, jmp_b508
  ja jmp_b518

jmp_ced8:
  mov64 r1, 0x3
  mov64 r2, 0x3
  lddw r3, data_0af0
  call fn_28b70

fn_cf00:
  jne r3, 0x3, jmp_cff8
  ldxdw r3, [r2+0x0]
  ldxb r3, [r3+0x1]
  jeq r3, 0x0, jmp_d010
  mov64 r6, r2
  add64 r6, 0x8
  ldxdw r9, [r6+0x0]
  ldxb r3, [r9+0x2]
  jeq r3, 0x0, jmp_d030
  ldxdw r3, [r9+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r3, r4, jmp_cfd0
  ldxdw r3, [r9+0x30]
  lddw r4, 0x626c582b5813378e
  jne r3, r4, jmp_cfd0
  ldxdw r3, [r9+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r3, r4, jmp_cfd0
  mov64 r3, 0x0
  ldxdw r4, [r9+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r4, r5, jmp_cfd8

jmp_cfd0:
  mov64 r3, 0x1

jmp_cfd8:
  jeq r3, 0x0, jmp_d048
  lddw r2, 0x900000000
  ja jmp_d020

jmp_cff8:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa
  ja jmp_d040

jmp_d010:
  lddw r2, 0x800000000

jmp_d020:
  stxdw [r1+0x8], r2
  ja jmp_d038

jmp_d030:
  stdw [r1+0x8], 0x0

jmp_d038:
  stdw [r1+0x0], 0x0

jmp_d040:
  exit

jmp_d048:
  ldxdw r3, [r9+0x50]
  jne r3, 0x103, jmp_d070
  lddw r2, 0x2500000000
  ja jmp_d020

jmp_d070:
  add64 r3, -0x42
  and64 r3, -0x21
  jeq r3, 0x0, jmp_d0a0
  lddw r2, 0xa00000000
  ja jmp_d020

jmp_d0a0:
  stxdw [r10-0x90], r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r6
  call fn_28528
  ldxw r2, [r10-0x2c]
  ldxw r3, [r10-0x30]
  ldxdw r1, [r10-0x38]
  jeq r1, 0x0, jmp_d2e0
  lsh64 r2, 0x20
  or64 r2, r3
  jle r2, 0x1f, jmp_d338
  jlt r2, 0x42, jmp_d358
  ldxb r2, [r10-0x20]
  stxdw [r10-0x88], r2
  ldxdw r8, [r10-0x28]
  ldxb r2, [r1+0x41]
  mov64 r3, r10
  add64 r3, -0x1
  stxdw [r10-0x18], r3
  stxdw [r10-0x28], r1
  lddw r1, str_036f
  stxdw [r10-0x38], r1
  stxb [r10-0x1], r2
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x20
  stdw [r10-0x30], 0x5
  mov64 r1, r10
  add64 r1, -0x5c
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x3
  call fn_09a0
  ldxb r1, [r10-0x5c]
  jne r1, 0x0, jmp_d2a0
  ldxb r1, [r10-0x59]
  stxb [r10-0x7a], r1
  ldxh r1, [r10-0x5b]
  stxh [r10-0x7c], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0x71], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0x69], r1
  ldxdw r1, [r10-0x43]
  stxdw [r10-0x64], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x79], r1
  ldxdw r1, [r9+0x8]
  ldxdw r2, [r10-0x7c]
  jne r1, r2, jmp_d290
  ldxdw r1, [r9+0x10]
  ldxdw r2, [r10-0x74]
  jne r1, r2, jmp_d290
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r10-0x6c]
  jne r1, r2, jmp_d290
  mov64 r1, 0x0
  ldxdw r2, [r9+0x20]
  ldxdw r3, [r10-0x64]
  jeq r2, r3, jmp_d298

jmp_d290:
  mov64 r1, 0x1

jmp_d298:
  jeq r1, 0x0, jmp_d300

jmp_d2a0:
  lddw r1, 0x1300000000
  stxdw [r7+0x8], r1
  stdw [r7+0x0], 0x0
  ldxdw r2, [r10-0x88]
  mov64 r1, r8
  call fn_0788
  ja jmp_d040

jmp_d2e0:
  stxw [r7+0xc], r2
  stxw [r7+0x8], r3
  stdw [r7+0x0], 0x0
  ja jmp_d040

jmp_d300:
  mov64 r1, r8
  ldxdw r2, [r10-0x88]
  call fn_0788
  stxdw [r7+0x8], r6
  ldxdw r1, [r10-0x90]
  stxdw [r7+0x0], r1
  ja jmp_d040

jmp_d338:
  mov64 r1, 0x20
  lddw r3, data_0b08
  call fn_292e8

jmp_d358:
  mov64 r1, 0x41
  lddw r3, data_0b20
  call fn_28b70

fn_d378:
  mov64 r6, r1
  stxdw [r10-0xc0], r2
  ldxdw r7, [r2+0x8]
  ldxdw r1, [r7+0x0]
  ldxdw r9, [r1+0x50]
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r7
  call fn_28528
  ldxw r2, [r10-0x2c]
  ldxw r1, [r10-0x30]
  ldxdw r4, [r10-0x38]
  jeq r4, 0x0, jmp_da10
  lsh64 r2, 0x20
  or64 r2, r1
  jle r2, 0x1f, jmp_dcb0
  ldxb r3, [r10-0x20]
  ldxdw r1, [r10-0x28]
  ldxb r5, [r4+0x2]
  stxb [r10-0x7a], r5
  ldxh r5, [r4+0x0]
  stxh [r10-0x7c], r5
  ldxw r5, [r4+0x3]
  stxdw [r10-0xc8], r5
  ldxw r5, [r4+0x7]
  stxdw [r10-0xd0], r5
  ldxdw r5, [r4+0x18]
  stxdw [r10-0x8b], r5
  ldxdw r5, [r4+0x13]
  stxdw [r10-0x90], r5
  ldxdw r5, [r4+0xb]
  stxdw [r10-0x98], r5
  jle r2, 0x3f, jmp_dcd0
  ldxb r5, [r4+0x22]
  stxb [r10-0x5a], r5
  ldxh r5, [r4+0x20]
  stxh [r10-0x5c], r5
  ldxw r0, [r4+0x23]
  ldxw r5, [r4+0x27]
  stxdw [r10-0xd8], r5
  ldxdw r5, [r4+0x38]
  stxdw [r10-0x6b], r5
  ldxdw r5, [r4+0x33]
  stxdw [r10-0x70], r5
  ldxdw r5, [r4+0x2b]
  stxdw [r10-0x78], r5
  jeq r2, 0x40, jmp_dd10
  jeq r2, 0x41, jmp_dd38
  ldxb r5, [r4+0x40]
  ldxb r8, [r4+0x41]
  stxdw [r10-0xe8], r8
  stxdw [r10-0xe0], r5
  jle r9, 0x61, jmp_d598
  jle r2, 0x61, jmp_dcf0
  ldxb r2, [r4+0x44]
  stxb [r10-0x3a], r2
  ldxh r2, [r4+0x42]
  stxh [r10-0x3c], r2
  ldxw r5, [r4+0x45]
  ldxw r2, [r4+0x49]
  stxdw [r10-0xf0], r2
  ldxdw r2, [r4+0x5a]
  stxdw [r10-0x4b], r2
  ldxdw r2, [r4+0x55]
  stxdw [r10-0x50], r2
  ldxdw r2, [r4+0x4d]
  stxdw [r10-0x58], r2
  ja jmp_d5d8

jmp_d598:
  mov64 r5, 0x0
  stb [r10-0x3a], 0x0
  sth [r10-0x3c], 0x0
  stdw [r10-0x58], 0x0
  stdw [r10-0x50], 0x0
  stdw [r10-0x4b], 0x0
  mov64 r2, 0x0
  stxdw [r10-0xf0], r2

jmp_d5d8:
  jgt r3, 0x7, jmp_dd60
  stxdw [r10-0x100], r5
  stxdw [r10-0xf8], r0
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_dd78
  sub64 r3, r2
  stxb [r1+0x0], r3
  mov64 r1, r10
  add64 r1, -0x38
  call fn_28928
  ldxw r1, [r10-0x38]
  jeq r1, 0x0, jmp_d670
  ldxw r2, [r10-0x30]
  ldxw r1, [r10-0x34]
  ja jmp_da10

jmp_d670:
  stxdw [r10-0x108], r9
  mov64 r1, r10
  add64 r1, -0xa8
  ldxdw r2, [r10-0x30]
  mov64 r3, 0x0
  mov64 r4, 0x183
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  ldxdw r1, [r10-0xa0]
  jne r1, 0x0, jmp_d6d0
  mov64 r2, 0x0

jmp_d6d0:
  ldxdw r1, [r10-0xa8]
  ldxdw r9, [r10-0x28]
  lddw r3, 0x4000000000000000
  jne r9, r3, jmp_d740
  and64 r2, 0x1
  jne r2, 0x0, jmp_dd90
  ldxdw r9, [r10-0x108]
  jslt r1, 0x0, jmp_dd90
  lsh64 r1, 0x1
  ldxdw r2, [r7+0x0]
  ldxdw r2, [r2+0x48]
  jgt r1, r2, jmp_d828
  ja jmp_d8a0

jmp_d740:
  stxdw [r10-0x110], r6
  and64 r2, 0x1
  jne r2, 0x0, jmp_dda8
  call fn_2bf50
  mov64 r1, r9
  mov64 r2, r0
  call fn_2b7a0
  mov64 r9, r0
  mov64 r8, 0x0
  mov64 r1, r9
  mov64 r2, 0x0
  call fn_2c2f8
  mov64 r6, r0
  mov64 r1, r9
  call fn_2b6e8
  jslt r6, 0x0, jmp_d7c8
  mov64 r8, r0

jmp_d7c8:
  mov64 r1, r9
  lddw r2, 0x43efffffffffffff
  call fn_2b5e8
  mov64 r1, -0x1
  jsgt r0, 0x0, jmp_d800
  mov64 r1, r8

jmp_d800:
  ldxdw r6, [r10-0x110]
  ldxdw r9, [r10-0x108]
  ldxdw r2, [r7+0x0]
  ldxdw r2, [r2+0x48]
  jle r1, r2, jmp_d8a0

jmp_d828:
  sub64 r1, r2
  ldxdw r2, [r10-0xc0]
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x28], r1
  stxdw [r10-0x30], r7
  stxdw [r10-0x38], r2
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_283e0
  ldxw r1, [r10-0xb0]
  jne r1, 0x1a, jmp_da08

jmp_d8a0:
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r7
  mov64 r3, 0x103
  mov64 r4, 0x1
  call fn_285c8
  ldxw r1, [r10-0xb8]
  jne r1, 0x1a, jmp_d9f8
  mov64 r8, r6
  ldxdw r6, [r7+0x0]
  ldxdw r1, [r6+0x28]
  lddw r2, -0x2ef915ab4fa6d9f4
  jne r1, r2, jmp_d978
  ldxdw r1, [r6+0x30]
  lddw r2, 0x626c582b5813378e
  jne r1, r2, jmp_d978
  ldxdw r1, [r6+0x38]
  lddw r2, -0x164c5fdb9d1c7931
  jne r1, r2, jmp_d978
  mov64 r2, 0x0
  ldxdw r1, [r6+0x40]
  lddw r3, -0xe007a018e0ac636
  jeq r1, r3, jmp_d980

jmp_d978:
  mov64 r2, 0x1

jmp_d980:
  lddw r1, 0x900000000
  jne r2, 0x0, jmp_d9d8
  lddw r1, 0xa00000000
  ldxdw r2, [r6+0x50]
  jne r2, 0x103, jmp_d9d8
  mov64 r1, 0xb
  ldxb r2, [r6+0x0]
  and64 r2, 0xf
  jeq r2, 0x0, jmp_da28

jmp_d9d8:
  mov64 r2, r1
  rsh64 r2, 0x20

jmp_d9e8:
  mov64 r6, r8
  ja jmp_da10

jmp_d9f8:
  ldxw r2, [r10-0xb4]
  ja jmp_da10

jmp_da08:
  ldxw r2, [r10-0xac]

jmp_da10:
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  exit

jmp_da28:
  ldxb r1, [r10-0x7a]
  stxb [r6+0x5a], r1
  ldxh r1, [r10-0x7c]
  stxh [r6+0x58], r1
  ldxdw r1, [r10-0xd0]
  stxw [r6+0x5f], r1
  ldxdw r1, [r10-0xc8]
  stxw [r6+0x5b], r1
  ldxdw r1, [r10-0x98]
  stxdw [r6+0x63], r1
  ldxdw r1, [r10-0x90]
  stxdw [r6+0x6b], r1
  ldxdw r1, [r10-0x8b]
  stxdw [r6+0x70], r1
  ldxdw r1, [r10-0xe8]
  stxb [r6+0x79], r1
  stw [r6+0x7c], 0x10000
  stb [r6+0x7b], 0x2
  mov64 r1, r6
  add64 r1, 0xc9
  mov64 r2, 0x0
  mov64 r3, 0x92
  call fn_2a0b0
  ldxh r1, [r10-0x5c]
  ldxb r2, [r10-0x5a]
  ldxdw r3, [r10-0xd8]
  stxw [r6+0x87], r3
  ldxdw r3, [r10-0xf8]
  stxw [r6+0x83], r3
  stxb [r6+0x82], r2
  stxh [r6+0x80], r1
  ldxdw r1, [r10-0xe0]
  mov64 r2, r1
  mov64 r1, 0x1
  jeq r2, 0x1, jmp_db48
  mov64 r1, 0x0

jmp_db48:
  ldxdw r2, [r10-0x78]
  stxdw [r6+0x8b], r2
  ldxdw r2, [r10-0x70]
  stxdw [r6+0x93], r2
  ldxdw r2, [r10-0x6b]
  stxdw [r6+0x98], r2
  ldxb r2, [r10-0x3a]
  stxb [r6+0xa2], r2
  ldxh r2, [r10-0x3c]
  stxh [r6+0xa0], r2
  ldxdw r2, [r10-0xf0]
  stxw [r6+0xa7], r2
  ldxdw r2, [r10-0x100]
  stxw [r6+0xa3], r2
  ldxdw r2, [r10-0x58]
  stxdw [r6+0xab], r2
  ldxdw r2, [r10-0x50]
  stxdw [r6+0xb3], r2
  ldxdw r2, [r10-0x4b]
  stxb [r6+0x78], r1
  stxdw [r6+0xb8], r2
  stb [r6+0xc8], 0x0
  stb [r6+0x7a], 0x1
  stdw [r6+0xc0], 0x0
  ldxdw r1, [r7+0x0]
  stb [r10-0x38], 0x10
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x37], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x27], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x1f], r1
  stxh [r10-0x17], r9
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x23
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r1, 0x1a
  ja jmp_d9e8

jmp_dcb0:
  mov64 r1, 0x20
  lddw r3, data_0b38
  call fn_292e8

jmp_dcd0:
  mov64 r1, 0x40
  lddw r3, data_0b50
  call fn_292e8

jmp_dcf0:
  mov64 r1, 0x62
  lddw r3, data_0b98
  call fn_292e8

jmp_dd10:
  mov64 r1, 0x40
  mov64 r2, 0x40
  lddw r3, data_0b68
  call fn_28b70

jmp_dd38:
  mov64 r1, 0x41
  mov64 r2, 0x41
  lddw r3, data_0b80
  call fn_28b70

jmp_dd60:
  lddw r1, data_0810
  call fn_29a40

jmp_dd78:
  lddw r1, data_0828
  call fn_29938

jmp_dd90:
  lddw r1, data_09e8
  call fn_29990

jmp_dda8:
  lddw r1, data_09d0
  call fn_29990

fn_ddc0:
  mov64 r6, r2
  ldxdw r9, [r6+0x8]
  ldxdw r3, [r9+0x0]
  ldxdw r2, [r3+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r2, r4, jmp_de60
  ldxdw r2, [r3+0x30]
  lddw r4, 0x626c582b5813378e
  jne r2, r4, jmp_de60
  ldxdw r2, [r3+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r2, r4, jmp_de60
  mov64 r4, 0x0
  ldxdw r2, [r3+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r2, r5, jmp_de68

jmp_de60:
  mov64 r4, 0x1

jmp_de68:
  lddw r2, 0x900000000
  jne r4, 0x0, jmp_e120
  lddw r2, 0xa00000000
  ldxdw r3, [r3+0x50]
  jne r3, 0x103, jmp_e120
  stxdw [r10-0x138], r6
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r9
  call fn_28528
  ldxw r2, [r10-0xc4]
  ldxw r1, [r10-0xc8]
  ldxdw r3, [r10-0xd0]
  jeq r3, 0x0, jmp_e0f8
  lsh64 r2, 0x20
  or64 r2, r1
  jlt r2, 0x24, jmp_efb8
  ldxb r1, [r10-0xb8]
  mov64 r5, r1
  mov64 r1, r8
  jgt r5, 0x7, jmp_ef88
  ldxdw r2, [r10-0xc0]
  mov64 r4, 0x1
  lsh64 r4, r5
  mov64 r0, r4
  and64 r0, 0xff
  ldxb r5, [r2+0x0]
  jlt r5, r0, jmp_efa0
  ldxb r3, [r3+0x23]
  sub64 r5, r4
  stxb [r2+0x0], r5
  lddw r2, 0x2600000000
  jne r3, 0x2, jmp_e120
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r9
  call fn_28528
  ldxdw r7, [r10-0xd0]
  jeq r7, 0x0, jmp_e110
  ldxb r1, [r10-0xb8]
  stxdw [r10-0x140], r1
  ldxdw r6, [r10-0xc0]
  mov64 r1, r7
  add64 r1, 0x21
  stxdw [r10-0xb0], r1
  stxdw [r10-0xc0], r7
  lddw r1, str_036f
  stxdw [r10-0xd0], r1
  stdw [r10-0xa8], 0x1
  stdw [r10-0xb8], 0x20
  stdw [r10-0xc8], 0x5
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r4, r10
  add64 r4, -0x90
  mov64 r2, 0x3
  lddw r3, data_0160
  call sol_create_program_address
  jeq r0, 0x0, jmp_e148
  lddw r1, -0x100000000
  mov64 r2, r0
  add64 r2, r1
  mov64 r1, r2
  rsh64 r1, 0x20
  lsh64 r2, 0x20
  or64 r2, r1
  mov64 r1, r8
  jge r2, 0x1a, jmp_e370
  mov64 r3, r2
  lsh64 r3, 0x2
  lddw r4, data_0488
  add64 r4, r3
  ldxw r0, [r4+0x0]
  ja jmp_e378

jmp_e0f8:
  lsh64 r2, 0x20
  or64 r2, r1
  ja jmp_e118

jmp_e110:
  ldxdw r2, [r10-0xc8]

jmp_e118:
  mov64 r1, r8

jmp_e120:
  mov64 r0, r2
  rsh64 r0, 0x20

jmp_e130:
  stxw [r1+0x4], r0
  stxw [r1+0x0], r2
  exit

jmp_e148:
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x53], r1
  ldxdw r1, [r10-0x7d]
  stxdw [r10-0x58], r1
  ldxb r1, [r10-0x8e]
  stxb [r10-0x22], r1
  ldxh r1, [r10-0x90]
  stxh [r10-0x24], r1
  ldxdw r1, [r10-0x85]
  stxdw [r10-0x60], r1
  stxdw [r10-0x19], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x11], r1
  ldxdw r1, [r10-0x53]
  stxdw [r10-0xc], r1
  ldxdw r1, [r10-0x8d]
  stxdw [r10-0x21], r1
  ldxdw r2, [r9+0x0]
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x24]
  mov64 r1, r8
  jne r3, r4, jmp_e248
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r10-0x1c]
  jne r3, r4, jmp_e248
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r10-0x14]
  jne r3, r4, jmp_e248
  mov64 r3, 0x0
  ldxdw r2, [r2+0x20]
  ldxdw r4, [r10-0xc]
  jeq r2, r4, jmp_e250

jmp_e248:
  mov64 r3, 0x1

jmp_e250:
  mov64 r2, 0x0
  mov64 r0, 0x13
  ldxdw r4, [r10-0x138]
  jne r3, 0x0, jmp_e378
  mov64 r0, 0x20
  ldxb r3, [r7+0x27]
  jne r3, 0x0, jmp_e378
  ldxb r3, [r7+0x26]
  jgt r3, 0x1, jmp_e378
  ldxb r9, [r7+0x22]
  mov64 r5, r9
  add64 r5, -0x4
  and64 r5, 0xff
  jlt r5, 0xfd, jmp_e378
  stxdw [r10-0x148], r7
  mov64 r5, r9
  mul64 r5, 0x49
  and64 r5, 0xff
  jne r5, 0xdb, jmp_e3d8

jmp_e2e8:
  ldxdw r7, [r10-0x148]
  ldxb r3, [r7+0x6c]
  jgt r3, 0x1, jmp_e378
  ldxb r5, [r7+0x6d]
  jgt r5, 0x5, jmp_e378
  stxdw [r10-0x158], r9
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x160], r3
  ldxb r3, [r4+0x49]
  stxdw [r10-0x150], r3
  ldxb r9, [r7+0x70]
  jeq r5, 0x5, jmp_e5a8
  jne r5, 0x4, jmp_e600
  mov64 r4, 0x3
  jeq r9, 0x8, jmp_e5d0
  jeq r9, 0x12, jmp_e5d0
  ja jmp_e378

jmp_e370:
  mov64 r2, 0x0

jmp_e378:
  ldxdw r3, [r10-0x140]
  mov64 r4, r3
  jgt r4, 0x7, jmp_ef88
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r6+0x0]
  jlt r4, r5, jmp_efa0
  sub64 r4, r3
  stxb [r6+0x0], r4
  ja jmp_e130

jmp_e3d8:
  stxdw [r10-0x158], r9
  stxdw [r10-0x150], r6
  mov64 r9, 0xdb
  ldxdw r6, [r10-0x148]

jmp_e3f8:
  mov64 r7, r6
  add64 r7, r5
  ldxdw r3, [r7+0x28]
  jne r3, 0x0, jmp_e448
  ldxdw r3, [r7+0x30]
  jne r3, 0x0, jmp_e448
  ldxdw r3, [r7+0x38]
  jne r3, 0x0, jmp_e448
  ldxdw r3, [r7+0x40]
  jeq r3, 0x0, jmp_e548

jmp_e448:
  mov64 r7, 0x1
  jne r7, 0x0, jmp_e570

jmp_e458:
  mov64 r7, r6
  add64 r7, r5
  ldxdw r3, [r7+0x48]
  jne r3, 0x0, jmp_e4a8
  ldxdw r3, [r7+0x50]
  jne r3, 0x0, jmp_e4a8
  ldxdw r3, [r7+0x58]
  jne r3, 0x0, jmp_e4a8
  ldxdw r3, [r7+0x60]
  jeq r3, 0x0, jmp_e560

jmp_e4a8:
  mov64 r7, 0x1
  jne r7, 0x0, jmp_e570

jmp_e4b8:
  mov64 r7, r6
  add64 r7, r5
  ldxw r3, [r7+0x68]
  jne r3, 0x0, jmp_e570
  ldxb r3, [r7+0x6c]
  jne r3, 0x0, jmp_e570
  ldxb r3, [r7+0x6d]
  jne r3, 0x0, jmp_e570
  ldxh r3, [r7+0x6e]
  jne r3, 0x0, jmp_e570
  mov64 r3, r6
  add64 r3, r5
  ldxb r3, [r3+0x70]
  jne r3, 0x0, jmp_e570
  add64 r6, 0x49
  add64 r9, -0x49
  jne r5, r9, jmp_e3f8
  ja jmp_e580

jmp_e548:
  mov64 r7, 0x0
  jeq r7, 0x0, jmp_e458
  ja jmp_e570

jmp_e560:
  mov64 r7, 0x0
  jeq r7, 0x0, jmp_e4b8

jmp_e570:
  ldxdw r6, [r10-0x150]
  ja jmp_e378

jmp_e580:
  ldxdw r9, [r10-0x158]
  mov64 r3, r9
  ldxdw r6, [r10-0x150]
  jne r3, 0x0, jmp_e2e8
  ja jmp_e6d8

jmp_e5a8:
  mov64 r4, 0x7
  mov64 r3, r9
  add64 r3, -0x13
  and64 r3, 0xff
  jlt r3, 0xee, jmp_e378

jmp_e5d0:
  ldxb r3, [r7+0x48]
  jne r3, 0x0, jmp_e5f0
  ldxb r3, [r7+0x49]
  jeq r3, r4, jmp_e608

jmp_e5f0:
  mov64 r0, 0x1b
  ja jmp_e378

jmp_e600:
  jne r9, 0x0, jmp_e378

jmp_e608:
  mov64 r7, r6
  ldxdw r1, [r10-0x150]
  jne r5, r1, jmp_e6c0
  ldxdw r4, [r10-0x148]
  add64 r4, 0x28
  ldxdw r3, [r4+0x0]
  ldxdw r1, [r10-0x160]
  ldxdw r1, [r1+0x0]
  ldxdw r5, [r1+0x8]
  jne r3, r5, jmp_e6a8
  ldxdw r3, [r1+0x10]
  ldxdw r5, [r4+0x8]
  jne r5, r3, jmp_e6a8
  ldxdw r3, [r1+0x18]
  ldxdw r5, [r4+0x10]
  jne r5, r3, jmp_e6a8
  mov64 r6, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_e6b0

jmp_e6a8:
  mov64 r6, 0x1

jmp_e6b0:
  ldxdw r5, [r10-0x138]
  jeq r6, 0x0, jmp_ea88

jmp_e6c0:
  ldxdw r1, [r10-0x158]
  mov64 r6, r7
  jne r1, 0x1, jmp_e710

jmp_e6d8:
  mov64 r1, r6
  ldxdw r2, [r10-0x140]
  call fn_0788
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r0, 0x1f
  ja jmp_e130

jmp_e710:
  ldxdw r1, [r10-0x148]
  ldxb r1, [r1+0xb5]
  jgt r1, 0x1, jmp_e7f0
  ldxdw r1, [r10-0x148]
  ldxb r1, [r1+0xb6]
  jgt r1, 0x5, jmp_e7f0
  ldxdw r3, [r10-0x148]
  ldxb r9, [r3+0xb9]
  jeq r1, 0x4, jmp_e790
  jne r1, 0x5, jmp_e7e8
  mov64 r4, 0x7
  mov64 r3, r9
  add64 r3, -0x13
  and64 r3, 0xff
  jge r3, 0xee, jmp_e7a8
  ja jmp_e7f0

jmp_e790:
  mov64 r4, 0x3
  jeq r9, 0x12, jmp_e7a8
  jne r9, 0x8, jmp_e7f0

jmp_e7a8:
  ldxdw r3, [r10-0x148]
  ldxb r3, [r3+0x91]
  jne r3, 0x0, jmp_e7d8
  ldxdw r3, [r10-0x148]
  ldxb r3, [r3+0x92]
  jeq r3, r4, jmp_e808

jmp_e7d8:
  mov64 r0, 0x1b
  ja jmp_e7f0

jmp_e7e8:
  jeq r9, 0x0, jmp_e808

jmp_e7f0:
  mov64 r1, r8
  mov64 r6, r7
  ja jmp_e378

jmp_e808:
  ldxdw r3, [r10-0x150]
  jne r1, r3, jmp_e8b8
  ldxdw r4, [r10-0x148]
  add64 r4, 0x71
  ldxdw r3, [r4+0x0]
  ldxdw r1, [r10-0x160]
  ldxdw r1, [r1+0x0]
  ldxdw r5, [r1+0x8]
  jne r3, r5, jmp_e8a0
  ldxdw r3, [r1+0x10]
  ldxdw r5, [r4+0x8]
  jne r5, r3, jmp_e8a0
  ldxdw r3, [r1+0x18]
  ldxdw r5, [r4+0x10]
  jne r5, r3, jmp_e8a0
  mov64 r6, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_e8a8

jmp_e8a0:
  mov64 r6, 0x1

jmp_e8a8:
  ldxdw r5, [r10-0x138]
  jeq r6, 0x0, jmp_ea88

jmp_e8b8:
  ldxdw r1, [r10-0x158]
  mov64 r6, r7
  jlt r1, 0x3, jmp_e6d8
  ldxdw r1, [r10-0x148]
  ldxb r1, [r1+0xfe]
  jgt r1, 0x1, jmp_e7f0
  ldxdw r1, [r10-0x148]
  ldxb r4, [r1+0xff]
  jgt r4, 0x5, jmp_e7f0
  ldxdw r1, [r10-0x148]
  ldxb r9, [r1+0x102]
  jeq r4, 0x4, jmp_e950
  jne r4, 0x5, jmp_e9a0
  mov64 r1, 0x7
  mov64 r3, r9
  add64 r3, -0x13
  and64 r3, 0xff
  jlt r3, 0xee, jmp_e7f0
  ja jmp_e968

jmp_e950:
  mov64 r1, 0x3
  jeq r9, 0x12, jmp_e968
  jne r9, 0x8, jmp_e7f0

jmp_e968:
  ldxdw r3, [r10-0x148]
  ldxb r3, [r3+0xda]
  jne r3, 0x0, jmp_e7d8
  ldxdw r3, [r10-0x148]
  ldxb r3, [r3+0xdb]
  jeq r3, r1, jmp_e9a8
  ja jmp_e7d8

jmp_e9a0:
  jne r9, 0x0, jmp_e7f0

jmp_e9a8:
  mov64 r1, r8
  ldxdw r3, [r10-0x150]
  jne r4, r3, jmp_ea68
  ldxdw r4, [r10-0x148]
  add64 r4, 0xba
  ldxdw r3, [r4+0x0]
  ldxdw r1, [r10-0x160]
  ldxdw r1, [r1+0x0]
  ldxdw r5, [r1+0x8]
  jne r3, r5, jmp_ea48
  ldxdw r3, [r1+0x10]
  ldxdw r5, [r4+0x8]
  jne r5, r3, jmp_ea48
  ldxdw r3, [r1+0x18]
  ldxdw r5, [r4+0x10]
  jne r5, r3, jmp_ea48
  mov64 r6, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_ea50

jmp_ea48:
  mov64 r6, 0x1

jmp_ea50:
  mov64 r1, r8
  ldxdw r5, [r10-0x138]
  jeq r6, 0x0, jmp_ea88

jmp_ea68:
  ldxdw r3, [r10-0x158]
  mov64 r6, r7
  jne r3, 0x3, jmp_e378
  ja jmp_e6d8

jmp_ea88:
  ldxh r1, [r4+0x46]
  stxdw [r10-0x168], r1
  ldxw r1, [r4+0x40]
  stxdw [r10-0x158], r1
  ldxdw r2, [r10-0x148]
  ldxdw r1, [r2+0x18]
  stxdw [r10-0x100], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x108], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x110], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x118], r1
  ldxdw r1, [r4+0x38]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r4+0x30]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r4+0x28]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r4+0x20]
  stxdw [r10-0xf8], r1
  mov64 r1, r7
  mov64 r6, r5
  ldxdw r2, [r10-0x140]
  call fn_0788
  ldxb r1, [r6+0x48]
  stxb [r10-0xd1], r1
  mov64 r1, r10
  add64 r1, -0x118
  stxdw [r10-0xc0], r1
  lddw r1, str_0459
  stxdw [r10-0xd0], r1
  mov64 r1, r10
  add64 r1, -0xd1
  stxdw [r10-0xa0], r1
  mov64 r2, r10
  add64 r2, -0xf8
  stxdw [r10-0xb0], r2
  stdw [r10-0x98], 0x1
  stdw [r10-0xa8], 0x20
  stdw [r10-0xb8], 0x20
  stdw [r10-0xc8], 0x6
  stxdw [r10-0x70], r1
  stxdw [r10-0x80], r2
  lddw r1, str_03d2
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x150]
  and64 r1, 0x6
  stdw [r10-0x68], 0x1
  stdw [r10-0x78], 0x20
  stdw [r10-0x88], 0x4
  jne r1, 0x4, jmp_ec90
  mov64 r1, r10
  add64 r1, -0x24
  mov64 r2, r10
  add64 r2, -0xd0
  mov64 r3, 0x4
  call fn_09a0
  ldxb r1, [r10-0x24]
  jne r1, 0x1, jmp_ecd0

jmp_ec78:
  ldxw r0, [r10-0x1c]
  ldxw r2, [r10-0x20]
  ja jmp_edf0

jmp_ec90:
  mov64 r1, r10
  add64 r1, -0x24
  mov64 r2, r10
  add64 r2, -0x90
  mov64 r3, 0x3
  call fn_09a0
  ldxb r1, [r10-0x24]
  jne r1, 0x0, jmp_ec78

jmp_ecd0:
  ldxdw r1, [r10-0xb]
  stxdw [r10-0x33], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x38], r1
  ldxb r1, [r10-0x21]
  stxb [r10-0x5e], r1
  ldxh r1, [r10-0x23]
  stxh [r10-0x60], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x40], r1
  stxdw [r10-0x55], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0x4d], r1
  ldxdw r1, [r10-0x33]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x5d], r1
  ldxdw r1, [r10-0x160]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x60]
  jne r2, r3, jmp_edd0
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0x58]
  jne r2, r3, jmp_edd0
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x50]
  jne r2, r3, jmp_edd0
  mov64 r2, 0x0
  ldxdw r1, [r1+0x20]
  ldxdw r3, [r10-0x48]
  jeq r1, r3, jmp_edd8

jmp_edd0:
  mov64 r2, 0x1

jmp_edd8:
  jeq r2, 0x0, jmp_ee00
  mov64 r2, 0x0
  mov64 r0, 0xe

jmp_edf0:
  mov64 r1, r8
  ja jmp_e130

jmp_ee00:
  ldxdw r1, [r10-0x150]
  jeq r1, 0x4, jmp_eea0
  ldxdw r1, [r10-0x150]
  jne r1, 0x5, jmp_ef30
  mov64 r1, r10
  add64 r1, -0xd0
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r3, r10
  add64 r3, -0xf8
  mov64 r5, r10
  ldxdw r2, [r10-0x138]
  mov64 r4, r9
  call fn_10538
  ldxw r0, [r10-0x11c]
  ldxw r2, [r10-0x120]
  ja jmp_edf0

jmp_eea0:
  mov64 r1, r10
  add64 r1, -0xd0
  stxdw [r10-0xff0], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r3, r10
  add64 r3, -0xf8
  mov64 r5, r10
  ldxdw r2, [r10-0x138]
  mov64 r4, r9
  call fn_efd8
  ldxw r0, [r10-0x124]
  ldxw r2, [r10-0x128]
  ja jmp_edf0

jmp_ef30:
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r3, r10
  add64 r3, -0xf8
  mov64 r4, r10
  add64 r4, -0x90
  ldxdw r2, [r10-0x138]
  call fn_113a8
  ldxw r0, [r10-0x12c]
  ldxw r2, [r10-0x130]
  ja jmp_edf0

jmp_ef88:
  lddw r1, data_0810
  call fn_29a40

jmp_efa0:
  lddw r1, data_0828
  call fn_29938

jmp_efb8:
  mov64 r1, 0x23
  lddw r3, data_0e38
  call fn_28b70

fn_efd8:
  mov64 r6, r1
  ldxdw r1, [r2+0x20]
  ldxdw r1, [r1+0x0]
  ldxdw r0, [r1+0x8]
  lddw r7, -0x72a173d8738a0615
  jne r0, r7, jmp_f078
  ldxdw r0, [r1+0x10]
  lddw r7, 0x7b30da4272c284e
  jne r0, r7, jmp_f078
  ldxdw r0, [r1+0x18]
  lddw r7, -0x5f38133c9c58fa1d
  jne r0, r7, jmp_f078
  mov64 r0, 0x0
  ldxdw r1, [r1+0x20]
  lddw r7, 0x1bea5fd23a69683e
  jeq r1, r7, jmp_f080

jmp_f078:
  mov64 r0, 0x1

jmp_f080:
  jeq r0, 0x0, jmp_f0a0
  mov64 r1, 0x0
  mov64 r2, 0x29
  ja jmp_f3d8

jmp_f0a0:
  stxdw [r10-0x378], r3
  stxdw [r10-0x370], r4
  ldxdw r8, [r5-0xff0]
  ldxdw r9, [r5-0xff8]
  ldxdw r7, [r5-0x1000]
  stxdw [r10-0x380], r2
  mov64 r1, r2
  call fn_f998
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_f3b8
  mov64 r1, r10
  add64 r1, -0x128
  call fn_10118
  ldxb r1, [r10-0x128]
  and64 r1, 0x1
  jne r1, 0x0, jmp_f3c8
  stxdw [r10-0x388], r9
  stxdw [r10-0x390], r8
  ldxb r1, [r10-0x125]
  stxb [r10-0x35e], r1
  ldxh r1, [r10-0x127]
  stxh [r10-0x360], r1
  ldxdw r9, [r10-0x124]
  mov64 r8, r10
  add64 r8, -0x240
  mov64 r2, r10
  add64 r2, -0x11c
  mov64 r1, r8
  mov64 r3, 0x115
  call fn_2a090
  mov64 r1, r10
  add64 r1, -0x355
  mov64 r2, r8
  mov64 r3, 0x115
  call fn_2a090
  stxdw [r10-0x35d], r9
  mov64 r1, r10
  add64 r1, -0x128
  call fn_287f0
  ldxw r1, [r10-0x128]
  jeq r1, 0x1, jmp_f3c8
  ldxdw r9, [r10-0x100]
  ldxdw r8, [r10-0x120]
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0x360
  mov64 r3, 0x120
  call fn_218e8
  ldxw r1, [r10-0x128]
  jeq r1, 0x1, jmp_f3c8
  stxdw [r10-0x398], r8
  ldxw r8, [r10-0x120]
  mov64 r1, r10
  add64 r1, -0x23c
  mov64 r2, r10
  add64 r2, -0x11c
  mov64 r3, 0x70
  call fn_2a090
  mov64 r3, r7
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r3, 0x258, jmp_f2b0
  mov64 r3, 0x258

jmp_f2b0:
  stxw [r10-0x240], r8
  mov64 r1, 0x0
  ldxdw r4, [r10-0xa8]
  stxdw [r10-0x1c8], r4
  ldxw r8, [r10-0xac]
  stxw [r10-0x1cc], r8
  ldxdw r0, [r10-0x370]
  and64 r0, 0xff
  ldxdw r5, [r10-0x378]
  jeq r0, 0x12, jmp_f310
  mov64 r2, 0x20
  jne r0, 0x8, jmp_f3d8

jmp_f310:
  ldxdw r2, [r5+0x0]
  ldxdw r0, [r10-0x240]
  jne r0, r2, jmp_f378
  ldxdw r2, [r5+0x8]
  ldxdw r0, [r10-0x238]
  jne r0, r2, jmp_f378
  ldxdw r2, [r5+0x10]
  ldxdw r0, [r10-0x230]
  jne r0, r2, jmp_f378
  mov64 r0, 0x0
  ldxdw r2, [r5+0x18]
  ldxdw r5, [r10-0x228]
  jeq r5, r2, jmp_f380

jmp_f378:
  mov64 r0, 0x1

jmp_f380:
  mov64 r2, 0x1b
  jne r0, 0x0, jmp_f3d8
  ldxw r2, [r10-0x1d0]
  mov64 r5, r9
  jsge r5, r2, jmp_f3f0

jmp_f3a8:
  mov64 r2, 0x28
  ja jmp_f3d8

jmp_f3b8:
  stxw [r10-0x124], r0
  stw [r10-0x120], 0x0

jmp_f3c8:
  ldxw r2, [r10-0x120]
  ldxw r1, [r10-0x124]

jmp_f3d8:
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  exit

jmp_f3f0:
  mov64 r2, 0xd
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jgt r5, r4, jmp_f3d8
  jlt r5, r8, jmp_f3a8
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  mov64 r4, 0x50
  jeq r7, 0x0, jmp_f440
  mov64 r4, r3

jmp_f440:
  sub64 r9, r8
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jgt r9, r4, jmp_f3d8
  mov64 r3, 0x1
  ldxdw r7, [r10-0x1f8]
  mov64 r2, 0x1
  jslt r7, 0x0, jmp_f4d0
  mov64 r2, 0x0
  ldxdw r4, [r10-0x200]
  stxdw [r10-0x3a0], r4
  jne r4, 0x0, jmp_f4e8

jmp_f4a0:
  jeq r7, 0x0, jmp_f4f8

jmp_f4a8:
  mov64 r3, r2
  mov64 r2, 0x24
  and64 r3, 0x1
  jeq r3, 0x0, jmp_f510
  ja jmp_f3d8

jmp_f4d0:
  ldxdw r4, [r10-0x200]
  stxdw [r10-0x3a0], r4
  jeq r4, 0x0, jmp_f4a0

jmp_f4e8:
  mov64 r3, 0x0
  jne r7, 0x0, jmp_f4a8

jmp_f4f8:
  mov64 r2, 0x24
  and64 r3, 0x1
  jne r3, 0x0, jmp_f3d8

jmp_f510:
  ldxdw r3, [r10-0x1e8]
  jslt r3, 0x0, jmp_f3d8
  ldxdw r0, [r10-0x1f0]
  mov64 r9, 0x1
  mov64 r4, 0x1
  ldxdw r5, [r10-0x3a0]
  jgt r0, r5, jmp_f580
  mov64 r4, 0x0
  jle r3, r7, jmp_f588

jmp_f558:
  jeq r3, r7, jmp_f598

jmp_f560:
  mov64 r4, r9
  and64 r4, 0x1
  jeq r4, 0x0, jmp_f5a8
  ja jmp_f3d8

jmp_f580:
  jgt r3, r7, jmp_f558

jmp_f588:
  mov64 r9, 0x0
  jne r3, r7, jmp_f560

jmp_f598:
  and64 r4, 0x1
  jne r4, 0x0, jmp_f3d8

jmp_f5a8:
  ldxdw r4, [r10-0x1d8]
  ldxdw r0, [r10-0x1e0]
  mov64 r9, 0x1
  mov64 r3, 0x1
  ldxdw r5, [r10-0x3a0]
  jgt r5, r0, jmp_f618
  mov64 r3, 0x0
  jsle r7, r4, jmp_f620

jmp_f5e8:
  stxdw [r10-0x3a8], r7
  jeq r7, r4, jmp_f638

jmp_f5f8:
  mov64 r3, r9
  and64 r3, 0x1
  jeq r3, 0x0, jmp_f648
  ja jmp_f3d8

jmp_f618:
  jsgt r7, r4, jmp_f5e8

jmp_f620:
  mov64 r9, 0x0
  stxdw [r10-0x3a8], r7
  jne r7, r4, jmp_f5f8

jmp_f638:
  and64 r3, 0x1
  jne r3, 0x0, jmp_f3d8

jmp_f648:
  ldxdw r2, [r10-0x388]
  and64 r2, 0xffff
  mov64 r1, r2
  mov64 r3, r2
  jlt r2, 0x3e8, jmp_f678
  mov64 r1, 0x3e8

jmp_f678:
  mov64 r7, 0xc8
  jeq r3, 0x0, jmp_f690
  mov64 r7, r1

jmp_f690:
  mov64 r1, r10
  add64 r1, -0x240
  call fn_22638
  mov64 r9, r0
  mov64 r2, 0x15
  mov64 r1, r9
  and64 r1, 0xffff
  jle r1, r7, jmp_f6e0

jmp_f6d0:
  mov64 r1, 0x0
  ja jmp_f3d8

jmp_f6e0:
  ldxdw r1, [r10-0x380]
  ldxdw r7, [r1+0x10]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x368
  mov64 r3, r7
  ldxdw r4, [r10-0x390]
  call fn_10d10
  ldxw r1, [r10-0x368]
  jne r1, 0x1a, jmp_f838
  ldxdw r3, [r7+0x0]
  ldxdw r1, [r3+0x28]
  lddw r2, -0x2ef915ab4fa6d9f4
  jne r1, r2, jmp_f7c0
  ldxdw r1, [r3+0x30]
  lddw r2, 0x626c582b5813378e
  jne r1, r2, jmp_f7c0
  ldxdw r1, [r3+0x38]
  lddw r2, -0x164c5fdb9d1c7931
  jne r1, r2, jmp_f7c0
  mov64 r2, 0x0
  ldxdw r1, [r3+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r1, r4, jmp_f7c8

jmp_f7c0:
  mov64 r2, 0x1

jmp_f7c8:
  lddw r1, 0x900000000
  jne r2, 0x0, jmp_f820
  lddw r1, 0xa00000000
  ldxdw r2, [r3+0x50]
  jne r2, 0x4b, jmp_f820
  mov64 r1, 0xb
  ldxb r2, [r3+0x0]
  and64 r2, 0xf
  jeq r2, 0x0, jmp_f848

jmp_f820:
  mov64 r2, r1
  rsh64 r2, 0x20
  ja jmp_f3d8

jmp_f838:
  ldxw r2, [r10-0x364]
  ja jmp_f3d8

jmp_f848:
  ldxdw r4, [r10-0x370]
  and64 r4, 0xff
  neg64 r4
  ldxw r5, [r3+0x96]
  jeq r5, 0x0, jmp_f8a0
  mov64 r2, 0x2a
  ldxw r1, [r3+0x90]
  mov64 r0, r4
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r1, r0, jmp_f6d0

jmp_f8a0:
  mov64 r2, 0x2b
  mov64 r1, 0x0
  ldxdw r0, [r10-0x378]
  jle r8, r5, jmp_f3d8
  ldxdw r1, [r10-0x380]
  ldxb r1, [r1+0x48]
  stxdw [r10-0x370], r1
  lddw r2, 0x5d7bf9fb56bbbd19
  stxdw [r3+0x58], r2
  ldxdw r2, [r0+0x18]
  ldxdw r5, [r0+0x10]
  ldxdw r7, [r0+0x8]
  ldxdw r0, [r0+0x0]
  ldxdw r1, [r10-0x3a8]
  stxdw [r3+0x88], r1
  ldxdw r1, [r10-0x3a0]
  stxdw [r3+0x80], r1
  stxdw [r3+0x60], r0
  stxdw [r3+0x68], r7
  stxdw [r3+0x70], r5
  stxdw [r3+0x78], r2
  ldxdw r1, [r10-0x370]
  stxb [r3+0xa2], r1
  ldxdw r1, [r10-0x398]
  stxdw [r3+0x9a], r1
  stxw [r3+0x96], r8
  stxh [r3+0x94], r9
  stxw [r3+0x90], r4
  mov64 r1, 0x1a
  ja jmp_f3d8

fn_f998:
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x60c
  mov64 r8, 0x0
  mov64 r2, 0x0
  mov64 r3, 0x4c4
  call fn_2a0b0
  ldxdw r3, [r7+0x40]
  jgt r3, -0xd, jmp_10088
  mov64 r8, 0x1
  jlt r3, 0x4c5, jmp_f9f8
  mov64 r8, 0x0

jmp_f9f8:
  mov64 r6, r3
  add64 r6, 0xc
  mov64 r0, 0x2
  and64 r8, 0x1
  jeq r8, 0x0, jmp_10000

jmp_fa20:
  ldxdw r2, [r7+0x38]
  stxw [r10-0x610], r3
  lddw r1, -0x69a73987cf725e7b
  stxdw [r10-0x618], r1
  jlt r6, 0xc, jmp_100a8
  jgt r6, 0x4d0, jmp_100d0
  mov64 r1, r6
  add64 r1, -0xc
  jne r1, r3, jmp_100f8
  mov64 r1, r10
  add64 r1, -0x60c
  call fn_2a090
  mov64 r0, 0xa
  ldxdw r1, [r7+0x30]
  jne r1, 0x3, jmp_10000
  mov64 r0, 0xb
  ldxdw r1, [r7+0x28]
  ldxdw r2, [r7+0x0]
  ldxdw r4, [r2+0x0]
  ldxdw r9, [r1+0x0]
  ldxdw r8, [r1+0x8]
  ldxdw r5, [r1+0x10]
  mov64 r3, r5
  add64 r3, 0x8
  stxdw [r10-0x118], r3
  mov64 r7, r8
  add64 r7, 0x8
  stxdw [r10-0x138], r7
  mov64 r2, r9
  add64 r2, 0x8
  stxdw [r10-0x148], r2
  stxdw [r10-0x620], r4
  add64 r4, 0x8
  stxdw [r10-0x128], r4
  sth [r10-0x110], 0x0
  sth [r10-0x120], 0x100
  sth [r10-0x130], 0x0
  sth [r10-0x140], 0x0
  ldxb r1, [r9+0x0]
  and64 r1, 0x88
  jne r1, 0x0, jmp_10000
  stxdw [r10-0x628], r5
  stxdw [r10-0x630], r7
  mov64 r7, r8
  stxdw [r10-0x638], r4
  stxdw [r10-0x640], r3
  ldxb r1, [r9+0x1]
  mov64 r8, 0x1
  mov64 r4, 0x1
  jne r1, 0x0, jmp_fbc0
  mov64 r4, 0x0

jmp_fbc0:
  ldxb r3, [r9+0x2]
  mov64 r1, 0x1
  mov64 r5, r7
  ldxdw r7, [r10-0x628]
  jne r3, 0x0, jmp_fbf0
  mov64 r1, 0x0

jmp_fbf0:
  ldxb r3, [r9+0x3]
  jne r3, 0x0, jmp_fc08
  mov64 r8, 0x0

jmp_fc08:
  ldxdw r3, [r9+0x50]
  mov64 r7, r8
  mov64 r8, r9
  add64 r8, 0x28
  stxdw [r10-0xe8], r8
  mov64 r8, r9
  add64 r8, 0x58
  stxdw [r10-0xf0], r8
  stxdw [r10-0xf8], r3
  add64 r9, 0x48
  stxdw [r10-0x100], r9
  stxdw [r10-0x108], r2
  stxb [r10-0xd6], r7
  stxb [r10-0xd7], r1
  stxb [r10-0xd8], r4
  stdw [r10-0xe0], 0x0
  ldxb r1, [r5+0x0]
  and64 r1, 0x88
  jne r1, 0x0, jmp_10000
  ldxb r2, [r5+0x1]
  mov64 r3, 0x1
  mov64 r1, 0x1
  jeq r2, 0x0, jmp_10008
  ldxb r2, [r5+0x2]
  mov64 r8, 0x1
  jeq r2, 0x0, jmp_10028

jmp_fcd8:
  ldxb r2, [r5+0x3]
  jne r2, 0x0, jmp_fcf0

jmp_fce8:
  mov64 r3, 0x0

jmp_fcf0:
  ldxdw r2, [r5+0x50]
  mov64 r9, r5
  add64 r9, 0x28
  stxdw [r10-0xb0], r9
  mov64 r9, r5
  add64 r9, 0x58
  stxdw [r10-0xb8], r9
  stxdw [r10-0xc0], r2
  add64 r5, 0x48
  stxdw [r10-0xc8], r5
  ldxdw r2, [r10-0x630]
  stxdw [r10-0xd0], r2
  stxb [r10-0x9e], r3
  stxb [r10-0x9f], r8
  stxb [r10-0xa0], r1
  stdw [r10-0xa8], 0x0
  ldxdw r4, [r10-0x620]
  ldxb r1, [r4+0x0]
  and64 r1, 0x88
  jne r1, 0x0, jmp_10000
  ldxb r2, [r4+0x1]
  mov64 r3, 0x1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_fdb8
  mov64 r1, 0x0

jmp_fdb8:
  ldxb r2, [r4+0x2]
  mov64 r5, 0x1
  ldxdw r8, [r10-0x628]
  ldxdw r9, [r10-0x638]
  jne r2, 0x0, jmp_fde8
  mov64 r5, 0x0

jmp_fde8:
  ldxb r2, [r4+0x3]
  jne r2, 0x0, jmp_fe00
  mov64 r3, 0x0

jmp_fe00:
  ldxdw r2, [r4+0x50]
  mov64 r7, r4
  add64 r7, 0x28
  stxdw [r10-0x78], r7
  mov64 r7, r4
  add64 r7, 0x58
  stxdw [r10-0x80], r7
  stxdw [r10-0x88], r2
  add64 r4, 0x48
  stxdw [r10-0x90], r4
  stxdw [r10-0x98], r9
  stxb [r10-0x66], r3
  stxb [r10-0x67], r5
  stxb [r10-0x68], r1
  stdw [r10-0x70], 0x0
  ldxb r1, [r8+0x0]
  and64 r1, 0x88
  jne r1, 0x0, jmp_10000
  ldxb r1, [r8+0x1]
  ldxb r3, [r8+0x2]
  ldxb r5, [r8+0x3]
  ldxdw r2, [r8+0x50]
  mov64 r4, r8
  add64 r4, 0x28
  stxdw [r10-0x40], r4
  mov64 r4, r8
  add64 r4, 0x58
  stxdw [r10-0x48], r4
  stxdw [r10-0x50], r2
  add64 r8, 0x48
  stxdw [r10-0x58], r8
  ldxdw r2, [r10-0x640]
  stxdw [r10-0x60], r2
  mov64 r2, 0x1
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_10048
  stxb [r10-0x2e], r4
  mov64 r4, 0x1
  jeq r3, 0x0, jmp_10068

jmp_ff38:
  stxb [r10-0x2f], r4
  jne r1, 0x0, jmp_ff50

jmp_ff48:
  mov64 r2, 0x0

jmp_ff50:
  stxb [r10-0x30], r2
  stdw [r10-0x38], 0x0
  stxdw [r10-0x8], r6
  mov64 r1, r10
  add64 r1, -0x618
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x148
  stxdw [r10-0x20], r1
  lddw r1, data_0040
  stxdw [r10-0x28], r1
  stdw [r10-0x18], 0x4
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x108
  mov64 r3, 0x4
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  mov64 r0, 0x1a

jmp_10000:
  exit

jmp_10008:
  mov64 r1, 0x0
  ldxb r2, [r5+0x2]
  mov64 r8, 0x1
  jne r2, 0x0, jmp_fcd8

jmp_10028:
  mov64 r8, 0x0
  ldxb r2, [r5+0x3]
  jeq r2, 0x0, jmp_fce8
  ja jmp_fcf0

jmp_10048:
  mov64 r4, 0x0
  stxb [r10-0x2e], r4
  mov64 r4, 0x1
  jne r3, 0x0, jmp_ff38

jmp_10068:
  mov64 r4, 0x0
  stxb [r10-0x2f], r4
  jeq r1, 0x0, jmp_ff48
  ja jmp_ff50

jmp_10088:
  mov64 r0, 0x2
  and64 r8, 0x1
  jne r8, 0x0, jmp_fa20
  ja jmp_10000

jmp_100a8:
  mov64 r1, 0xc
  mov64 r2, r6
  lddw r3, data_0bb0
  call fn_292f0

jmp_100d0:
  mov64 r1, r6
  mov64 r2, 0x4d0
  lddw r3, data_0bb0
  call fn_292e8

jmp_100f8:
  mov64 r2, r3
  lddw r3, data_0bc8
  call fn_292f8

fn_10118:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x868
  mov64 r3, r10
  add64 r3, -0x440
  mov64 r2, 0x400
  call sol_get_return_data
  mov64 r7, r0
  jeq r7, 0x0, jmp_10298
  ldxdw r1, [r10-0x428]
  stxdw [r10-0x8], r1
  ldxdw r1, [r10-0x430]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0x438]
  stxdw [r10-0x18], r1
  ldxdw r1, [r10-0x440]
  stxdw [r10-0x20], r1
  mov64 r8, r10
  add64 r8, -0x420
  mov64 r2, r10
  add64 r2, -0x868
  mov64 r1, r8
  mov64 r3, 0x400
  call fn_2a090
  mov64 r1, r10
  add64 r1, -0x868
  mov64 r2, r8
  mov64 r3, 0x420
  call fn_2a090
  lddw r1, -0x72a173d8738a0615
  ldxdw r2, [r10-0x468]
  jne r2, r1, jmp_10288
  lddw r1, 0x7b30da4272c284e
  ldxdw r2, [r10-0x460]
  jne r2, r1, jmp_10288
  lddw r1, -0x5f38133c9c58fa1d
  ldxdw r2, [r10-0x458]
  jne r2, r1, jmp_10288
  mov64 r1, 0x0
  lddw r2, 0x1bea5fd23a69683e
  ldxdw r3, [r10-0x450]
  jeq r3, r2, jmp_10290

jmp_10288:
  mov64 r1, 0x1

jmp_10290:
  jeq r1, 0x0, jmp_102c8

jmp_10298:
  lddw r1, 0x2900000000

jmp_102a8:
  stxdw [r6+0x4], r1
  mov64 r1, 0x1

jmp_102b8:
  stxb [r6+0x0], r1
  exit

jmp_102c8:
  jne r7, 0x120, jmp_10310
  mov64 r1, r6
  add64 r1, 0x1
  mov64 r2, r10
  add64 r2, -0x420
  mov64 r3, 0x120
  call fn_2a090
  mov64 r1, 0x0
  ja jmp_102b8

jmp_10310:
  lddw r1, 0xa00000000
  ja jmp_102a8

fn_10328:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x868
  mov64 r3, r10
  add64 r3, -0x440
  mov64 r2, 0x400
  call sol_get_return_data
  mov64 r7, r0
  jeq r7, 0x0, jmp_104a8
  ldxdw r1, [r10-0x428]
  stxdw [r10-0x8], r1
  ldxdw r1, [r10-0x430]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0x438]
  stxdw [r10-0x18], r1
  ldxdw r1, [r10-0x440]
  stxdw [r10-0x20], r1
  mov64 r8, r10
  add64 r8, -0x420
  mov64 r2, r10
  add64 r2, -0x868
  mov64 r1, r8
  mov64 r3, 0x400
  call fn_2a090
  mov64 r1, r10
  add64 r1, -0x868
  mov64 r2, r8
  mov64 r3, 0x420
  call fn_2a090
  lddw r1, -0x72a173d8738a0615
  ldxdw r2, [r10-0x468]
  jne r2, r1, jmp_10498
  lddw r1, 0x7b30da4272c284e
  ldxdw r2, [r10-0x460]
  jne r2, r1, jmp_10498
  lddw r1, -0x5f38133c9c58fa1d
  ldxdw r2, [r10-0x458]
  jne r2, r1, jmp_10498
  mov64 r1, 0x0
  lddw r2, 0x1bea5fd23a69683e
  ldxdw r3, [r10-0x450]
  jeq r3, r2, jmp_104a0

jmp_10498:
  mov64 r1, 0x1

jmp_104a0:
  jeq r1, 0x0, jmp_104d8

jmp_104a8:
  lddw r1, 0x2900000000

jmp_104b8:
  stxdw [r6+0x4], r1
  mov64 r1, 0x1

jmp_104c8:
  stxb [r6+0x0], r1
  exit

jmp_104d8:
  jne r7, 0xe0, jmp_10520
  mov64 r1, r6
  add64 r1, 0x1
  mov64 r2, r10
  add64 r2, -0x420
  mov64 r3, 0xe0
  call fn_2a090
  mov64 r1, 0x0
  ja jmp_104c8

jmp_10520:
  lddw r1, 0xa00000000
  ja jmp_104b8

fn_10538:
  mov64 r6, r1
  ldxdw r1, [r2+0x20]
  ldxdw r1, [r1+0x0]
  ldxdw r0, [r1+0x8]
  lddw r7, -0x72a173d8738a0615
  jne r0, r7, jmp_105d8
  ldxdw r0, [r1+0x10]
  lddw r7, 0x7b30da4272c284e
  jne r0, r7, jmp_105d8
  ldxdw r0, [r1+0x18]
  lddw r7, -0x5f38133c9c58fa1d
  jne r0, r7, jmp_105d8
  mov64 r0, 0x0
  ldxdw r1, [r1+0x20]
  lddw r7, 0x1bea5fd23a69683e
  jeq r1, r7, jmp_105e0

jmp_105d8:
  mov64 r0, 0x1

jmp_105e0:
  jeq r0, 0x0, jmp_10600
  mov64 r1, 0x0
  mov64 r2, 0x29
  ja jmp_10908

jmp_10600:
  stxdw [r10-0x2b8], r3
  stxdw [r10-0x2b0], r4
  ldxdw r7, [r5-0xff8]
  ldxdw r9, [r5-0x1000]
  stxdw [r10-0x2c0], r2
  mov64 r1, r2
  call fn_f998
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_108e8
  mov64 r1, r10
  add64 r1, -0xe8
  call fn_10328
  ldxb r1, [r10-0xe8]
  and64 r1, 0x1
  jne r1, 0x0, jmp_108f8
  stxdw [r10-0x2c8], r7
  ldxb r1, [r10-0xe5]
  stxb [r10-0x29e], r1
  ldxh r1, [r10-0xe7]
  stxh [r10-0x2a0], r1
  ldxdw r7, [r10-0xe4]
  mov64 r8, r10
  add64 r8, -0x1c0
  mov64 r2, r10
  add64 r2, -0xdc
  mov64 r1, r8
  mov64 r3, 0xd5
  call fn_2a090
  mov64 r1, r10
  add64 r1, -0x295
  mov64 r2, r8
  mov64 r3, 0xd5
  call fn_2a090
  stxdw [r10-0x29d], r7
  mov64 r1, r10
  add64 r1, -0xe8
  call fn_287f0
  ldxw r1, [r10-0xe8]
  jeq r1, 0x1, jmp_108f8
  ldxdw r7, [r10-0xc0]
  ldxdw r8, [r10-0xe0]
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r10
  add64 r2, -0x2a0
  mov64 r3, 0xe0
  call fn_22a90
  ldxw r1, [r10-0xe8]
  jeq r1, 0x1, jmp_108f8
  stxdw [r10-0x2d0], r8
  ldxw r8, [r10-0xe0]
  mov64 r1, r10
  add64 r1, -0x1bc
  mov64 r2, r10
  add64 r2, -0xdc
  mov64 r3, 0x50
  call fn_2a090
  mov64 r4, r9
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jlt r4, 0x258, jmp_10800
  mov64 r4, 0x258

jmp_10800:
  stxw [r10-0x1c0], r8
  mov64 r1, 0x0
  mov64 r2, 0x20
  ldxdw r0, [r10-0x2b0]
  add64 r0, -0x13
  and64 r0, 0xff
  ldxdw r5, [r10-0x2b8]
  ldxdw r3, [r10-0x2c0]
  jlt r0, 0xee, jmp_10908
  ldxdw r2, [r5+0x0]
  ldxdw r0, [r10-0x1c0]
  jne r0, r2, jmp_108b0
  ldxdw r2, [r5+0x8]
  ldxdw r0, [r10-0x1b8]
  jne r0, r2, jmp_108b0
  ldxdw r2, [r5+0x10]
  ldxdw r0, [r10-0x1b0]
  jne r0, r2, jmp_108b0
  mov64 r0, 0x0
  ldxdw r2, [r5+0x18]
  ldxdw r5, [r10-0x1a8]
  jeq r5, r2, jmp_108b8

jmp_108b0:
  mov64 r0, 0x1

jmp_108b8:
  mov64 r2, 0x1b
  jne r0, 0x0, jmp_10908
  ldxw r2, [r10-0x170]
  jsge r7, r2, jmp_10920

jmp_108d8:
  mov64 r2, 0x28
  ja jmp_10908

jmp_108e8:
  stxw [r10-0xe4], r0
  stw [r10-0xe0], 0x0

jmp_108f8:
  ldxw r2, [r10-0xe0]
  ldxw r1, [r10-0xe4]

jmp_10908:
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  exit

jmp_10920:
  ldxdw r5, [r10-0x88]
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  mov64 r2, 0xd
  jgt r7, r5, jmp_10908
  ldxw r0, [r10-0x8c]
  jlt r7, r0, jmp_108d8
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  mov64 r5, 0x50
  jeq r9, 0x0, jmp_10980
  mov64 r5, r4

jmp_10980:
  stxdw [r10-0x2d8], r0
  sub64 r7, r0
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jgt r7, r5, jmp_10908
  mov64 r1, 0x1
  ldxdw r9, [r10-0x178]
  mov64 r2, 0x1
  jslt r9, 0x0, jmp_10a18
  mov64 r2, 0x0
  ldxdw r8, [r10-0x180]
  jne r8, 0x0, jmp_10a28

jmp_109e0:
  jeq r9, 0x0, jmp_10a38

jmp_109e8:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_10a48

jmp_10a00:
  mov64 r2, 0x24
  mov64 r1, 0x0
  ja jmp_10908

jmp_10a18:
  ldxdw r8, [r10-0x180]
  jeq r8, 0x0, jmp_109e0

jmp_10a28:
  mov64 r1, 0x0
  jne r9, 0x0, jmp_109e8

jmp_10a38:
  and64 r1, 0x1
  jne r1, 0x0, jmp_10a00

jmp_10a48:
  mov64 r1, r3
  ldxdw r3, [r1+0x10]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x2a8
  mov64 r7, r3
  ldxdw r4, [r10-0x2c8]
  call fn_10d10
  ldxw r1, [r10-0x2a8]
  jne r1, 0x1a, jmp_10ba0
  ldxdw r3, [r7+0x0]
  ldxdw r1, [r3+0x28]
  lddw r2, -0x2ef915ab4fa6d9f4
  jne r1, r2, jmp_10b28
  ldxdw r1, [r3+0x30]
  lddw r2, 0x626c582b5813378e
  jne r1, r2, jmp_10b28
  ldxdw r1, [r3+0x38]
  lddw r2, -0x164c5fdb9d1c7931
  jne r1, r2, jmp_10b28
  mov64 r2, 0x0
  ldxdw r1, [r3+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r1, r4, jmp_10b30

jmp_10b28:
  mov64 r2, 0x1

jmp_10b30:
  lddw r1, 0x900000000
  jne r2, 0x0, jmp_10b88
  lddw r1, 0xa00000000
  ldxdw r2, [r3+0x50]
  jne r2, 0x4b, jmp_10b88
  mov64 r1, 0xb
  ldxb r2, [r3+0x0]
  and64 r2, 0xf
  jeq r2, 0x0, jmp_10bb0

jmp_10b88:
  mov64 r2, r1
  rsh64 r2, 0x20
  ja jmp_10908

jmp_10ba0:
  ldxw r2, [r10-0x2a4]
  ja jmp_10908

jmp_10bb0:
  ldxdw r4, [r10-0x2b0]
  and64 r4, 0xff
  neg64 r4
  ldxw r5, [r3+0x96]
  jeq r5, 0x0, jmp_10c08
  mov64 r2, 0x2a
  ldxw r1, [r3+0x90]
  mov64 r0, r4
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r1, r0, jmp_10d00

jmp_10c08:
  mov64 r2, 0x2b
  mov64 r1, 0x0
  stxdw [r10-0x2b0], r4
  ldxdw r0, [r10-0x2b8]
  ldxdw r4, [r10-0x2c0]
  ldxdw r7, [r10-0x2d8]
  jle r7, r5, jmp_10908
  ldxb r1, [r4+0x48]
  lddw r2, 0x5d7bf9fb56bbbd19
  stxdw [r3+0x58], r2
  ldxdw r2, [r0+0x18]
  ldxdw r5, [r0+0x10]
  ldxdw r4, [r0+0x8]
  ldxdw r0, [r0+0x0]
  stxdw [r3+0x88], r9
  stxdw [r3+0x80], r8
  stxdw [r3+0x60], r0
  stxdw [r3+0x68], r4
  stxdw [r3+0x70], r5
  stxdw [r3+0x78], r2
  stxb [r3+0xa2], r1
  ldxdw r1, [r10-0x2d0]
  stxdw [r3+0x9a], r1
  ldxdw r1, [r10-0x2d8]
  stxw [r3+0x96], r1
  ldxdw r1, [r10-0x2b0]
  stxw [r3+0x90], r1
  sth [r3+0x94], 0x0
  mov64 r1, 0x1a
  ja jmp_10908

jmp_10d00:
  mov64 r1, 0x0
  ja jmp_10908

fn_10d10:
  mov64 r5, 0x0
  mov64 r0, 0x9
  ldxdw r6, [r3+0x0]
  ldxdw r7, [r6+0x50]
  jeq r7, 0x0, jmp_10de8
  jne r7, 0x4b, jmp_11338
  ldxdw r2, [r6+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r2, r3, jmp_10dc8
  ldxdw r2, [r6+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_10dc8
  ldxdw r2, [r6+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_10dc8
  mov64 r2, 0x0
  ldxdw r3, [r6+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r3, r4, jmp_10dd0

jmp_10dc8:
  mov64 r2, 0x1

jmp_10dd0:
  jne r2, 0x0, jmp_11338
  mov64 r5, 0x1a
  ja jmp_11338

jmp_10de8:
  ldxdw r7, [r6+0x28]
  jne r7, 0x0, jmp_10e28
  ldxdw r7, [r6+0x30]
  jne r7, 0x0, jmp_10e28
  ldxdw r7, [r6+0x38]
  jne r7, 0x0, jmp_10e28
  ldxdw r6, [r6+0x40]
  jeq r6, 0x0, jmp_11350

jmp_10e28:
  mov64 r6, 0x1
  jne r6, 0x0, jmp_11338

jmp_10e38:
  mov64 r8, r3
  stxdw [r10-0xb8], r2
  stxdw [r10-0xb0], r1
  ldxdw r1, [r4+0x0]
  ldxdw r2, [r4+0x8]
  ldxdw r3, [r4+0x10]
  ldxdw r5, [r4+0x18]
  ldxdw r0, [r4+0x20]
  ldxdw r6, [r4+0x28]
  ldxdw r7, [r4+0x30]
  ldxdw r4, [r4+0x38]
  stxdw [r10-0x40], r4
  stxdw [r10-0x48], r7
  stxdw [r10-0x50], r6
  stxdw [r10-0x58], r0
  stxdw [r10-0x60], r5
  stxdw [r10-0x68], r3
  stxdw [r10-0x70], r2
  stxdw [r10-0x78], r1
  mov64 r1, r10
  add64 r1, -0x38
  call fn_28928
  ldxw r1, [r10-0x38]
  jne r1, 0x1, jmp_10f10
  ldxw r0, [r10-0x30]
  ldxw r5, [r10-0x34]
  ja jmp_11330

jmp_10f10:
  mov64 r1, r10
  add64 r1, -0x88
  ldxdw r2, [r10-0x30]
  mov64 r3, 0x0
  mov64 r4, 0xcb
  mov64 r5, 0x0
  call fn_2c150
  mov64 r3, 0x1
  ldxdw r1, [r10-0x80]
  jne r1, 0x0, jmp_10f68
  mov64 r3, 0x0

jmp_10f68:
  ldxdw r6, [r10-0x88]
  ldxdw r7, [r10-0x28]
  lddw r4, 0x4000000000000000
  ldxdw r1, [r10-0xb8]
  mov64 r2, r8
  and64 r3, 0x1
  jne r7, r4, jmp_11090
  jne r3, 0x0, jmp_11378
  jslt r6, 0x0, jmp_11378
  lsh64 r6, 0x1
  ldxdw r3, [r2+0x0]
  ldxdw r3, [r3+0x48]
  jne r3, 0x0, jmp_11170

jmp_10fd8:
  stxdw [r10-0x20], r6
  stxdw [r10-0x30], r2
  stxdw [r10-0x38], r1
  lddw r1, data_0160
  stxdw [r10-0x28], r1
  stdw [r10-0x18], 0x4b
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x4
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r4, 0x1
  call fn_28250
  ldxw r5, [r10-0xa8]
  jeq r5, 0x1a, jmp_11308
  ldxw r0, [r10-0xa4]
  ja jmp_11330

jmp_11090:
  jne r3, 0x0, jmp_11390
  mov64 r1, r6
  call fn_2bf50
  mov64 r1, r7
  mov64 r2, r0
  call fn_2b7a0
  mov64 r6, r0
  mov64 r9, 0x0
  mov64 r1, r6
  mov64 r2, 0x0
  call fn_2c2f8
  mov64 r7, r0
  mov64 r1, r6
  call fn_2b6e8
  jslt r7, 0x0, jmp_11110
  mov64 r9, r0

jmp_11110:
  mov64 r1, r6
  lddw r2, 0x43efffffffffffff
  call fn_2b5e8
  mov64 r6, -0x1
  jsgt r0, 0x0, jmp_11148
  mov64 r6, r9

jmp_11148:
  ldxdw r1, [r10-0xb8]
  mov64 r2, r8
  ldxdw r3, [r2+0x0]
  ldxdw r3, [r3+0x48]
  jeq r3, 0x0, jmp_10fd8

jmp_11170:
  stxdw [r10-0x10], r2
  stdw [r10-0x8], 0x4b
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x38], r1
  stdw [r10-0x30], 0x4
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x38
  mov64 r4, 0x1
  call fn_27da8
  ldxw r5, [r10-0x90]
  jne r5, 0x1a, jmp_11318
  lddw r1, data_0160
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r8
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x38], r1
  stdw [r10-0x30], 0x4
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r3, r10
  add64 r3, -0x38
  mov64 r4, 0x1
  call fn_27fe0
  ldxw r5, [r10-0x98]
  jne r5, 0x1a, jmp_11328
  ldxdw r1, [r8+0x0]
  ldxdw r1, [r1+0x48]
  jle r6, r1, jmp_11308
  stxdw [r10-0x30], r8
  ldxdw r2, [r10-0xb8]
  stxdw [r10-0x38], r2
  sub64 r6, r1
  stxdw [r10-0x28], r6
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_283e0
  ldxw r5, [r10-0xa0]
  jne r5, 0x1a, jmp_11368

jmp_11308:
  mov64 r5, 0x1a
  ja jmp_11330

jmp_11318:
  ldxw r0, [r10-0x8c]
  ja jmp_11330

jmp_11328:
  ldxw r0, [r10-0x94]

jmp_11330:
  ldxdw r1, [r10-0xb0]

jmp_11338:
  stxw [r1+0x4], r0
  stxw [r1+0x0], r5
  exit

jmp_11350:
  mov64 r6, 0x0
  jne r6, 0x0, jmp_11338
  ja jmp_10e38

jmp_11368:
  ldxw r0, [r10-0x9c]
  ja jmp_11330

jmp_11378:
  lddw r1, data_09e8
  call fn_29990

jmp_11390:
  lddw r1, data_09d0
  call fn_29990

fn_113a8:
  ldxdw r5, [r2+0x20]
  ldxdw r5, [r5+0x0]
  ldxdw r0, [r5+0x8]
  lddw r6, 0x48a6f752bbfab70c
  jne r0, r6, jmp_11440
  ldxdw r0, [r5+0x10]
  lddw r6, -0x6f74fe6582cea445
  jne r0, r6, jmp_11440
  ldxdw r0, [r5+0x18]
  lddw r6, 0x1fefa744702cb57
  jne r0, r6, jmp_11440
  mov64 r0, 0x0
  ldxdw r5, [r5+0x20]
  lddw r6, -0x7ea7c73367203b1a
  jeq r5, r6, jmp_11448

jmp_11440:
  mov64 r0, 0x1

jmp_11448:
  mov64 r9, 0x0
  mov64 r8, 0xe
  jne r0, 0x0, jmp_115b8
  ldxdw r5, [r2+0x30]
  jne r5, 0x4, jmp_115b0
  ldxdw r7, [r2+0x28]
  ldxdw r5, [r7+0x18]
  ldxdw r0, [r5+0x8]
  lddw r6, -0x58cc237c9f9e3249
  jne r0, r6, jmp_11508
  ldxdw r0, [r5+0x10]
  lddw r6, -0x26f1f020f64622e4
  jne r0, r6, jmp_11508
  ldxdw r0, [r5+0x18]
  lddw r6, 0x3d1f6770b437dc4e
  jne r0, r6, jmp_11508
  mov64 r0, 0x0
  ldxdw r5, [r5+0x20]
  lddw r6, 0x65a22ff8508fdeb
  jeq r5, r6, jmp_11510

jmp_11508:
  mov64 r0, 0x1

jmp_11510:
  mov64 r8, 0x10
  jne r0, 0x0, jmp_115b8
  stxdw [r10-0x778], r4
  stxdw [r10-0x770], r1
  mov64 r6, r2
  ldxdw r9, [r2+0x10]
  ldxdw r1, [r9+0x0]
  ldxdw r8, [r1+0x50]
  stxdw [r10-0x788], r3
  jeq r8, 0x0, jmp_115d0
  mov64 r1, r10
  add64 r1, -0x768
  mov64 r2, r9
  call fn_12868
  ldxw r1, [r10-0x768]
  jeq r1, 0x0, jmp_115e0
  ldxw r8, [r10-0x760]
  ldxw r9, [r10-0x764]
  ldxdw r1, [r10-0x770]
  ja jmp_115b8

jmp_115b0:
  mov64 r9, 0xa

jmp_115b8:
  stxw [r1+0x4], r8
  stxw [r1+0x0], r9
  exit

jmp_115d0:
  stxdw [r10-0x790], r8
  ja jmp_115f8

jmp_115e0:
  stxdw [r10-0x790], r8
  ldxdw r1, [r10-0x760]
  stxdw [r10-0x7c0], r1

jmp_115f8:
  mov64 r1, r10
  add64 r1, -0x760
  mov64 r8, 0x0
  mov64 r2, 0x0
  mov64 r3, 0x4c8
  call fn_2a0b0
  mov64 r2, r6
  ldxdw r3, [r2+0x40]
  stxdw [r10-0x780], r9
  jgt r3, -0x9, jmp_11f80
  mov64 r4, 0x1
  jlt r3, 0x4c9, jmp_11660
  mov64 r4, 0x0

jmp_11660:
  mov64 r5, r3
  add64 r5, 0x8
  ldxdw r1, [r10-0x770]
  mov64 r9, 0x2
  and64 r4, 0x1
  jeq r4, 0x0, jmp_115b8

jmp_11690:
  ldxdw r2, [r2+0x38]
  lddw r1, 0x2c764f0bafcf5f85
  stxdw [r10-0x768], r1
  jlt r5, 0x8, jmp_11fb0
  ldxdw r8, [r10-0x780]
  jgt r5, 0x4d0, jmp_11fd8
  stxdw [r10-0x7a0], r5
  add64 r5, -0x8
  jne r5, r3, jmp_12000
  mov64 r1, r10
  add64 r1, -0x760
  call fn_2a090
  ldxdw r8, [r8+0x0]
  ldxdw r3, [r7+0x18]
  ldxdw r0, [r7+0x10]
  ldxdw r4, [r7+0x8]
  ldxdw r2, [r7+0x0]
  add64 r2, 0x8
  ldxdw r1, [r6+0x0]
  ldxdw r5, [r6+0x18]
  stxdw [r10-0x7b0], r5
  ldxdw r5, [r5+0x0]
  ldxdw r6, [r1+0x0]
  stxdw [r10-0x288], r2
  add64 r6, 0x8
  stxdw [r10-0x298], r6
  add64 r5, 0x8
  add64 r4, 0x8
  add64 r0, 0x8
  add64 r8, 0x8
  add64 r3, 0x8
  stxdw [r10-0x7b8], r3
  stxdw [r10-0x238], r3
  stxdw [r10-0x798], r8
  stxdw [r10-0x258], r8
  stxdw [r10-0x268], r0
  stxdw [r10-0x278], r4
  stxdw [r10-0x7a8], r5
  stxdw [r10-0x248], r5
  sth [r10-0x230], 0x100
  sth [r10-0x240], 0x0
  sth [r10-0x250], 0x101
  sth [r10-0x260], 0x1
  sth [r10-0x270], 0x0
  sth [r10-0x280], 0x0
  sth [r10-0x290], 0x101
  ldxdw r2, [r10-0x778]
  ldxdw r6, [r2+0x0]
  ldxdw r8, [r2+0x8]
  ldxdw r9, [r2+0x10]
  ldxdw r3, [r2+0x18]
  ldxdw r5, [r2+0x20]
  ldxdw r2, [r2+0x28]
  stxdw [r10-0x200], r2
  stxdw [r10-0x208], r5
  stxdw [r10-0x210], r3
  stxdw [r10-0x218], r9
  stxdw [r10-0x220], r8
  stxdw [r10-0x228], r6
  stb [r10-0x1f1], 0xff
  mov64 r2, r10
  add64 r2, -0x1f1
  stxdw [r10-0x1e0], r2
  lddw r2, str_03de
  stxdw [r10-0x1f0], r2
  stdw [r10-0x1d8], 0x1
  stdw [r10-0x1e8], 0x4
  mov64 r2, r10
  add64 r2, -0x1f0
  stxdw [r10-0x1c0], r2
  mov64 r2, r10
  add64 r2, -0x228
  stxdw [r10-0x1d0], r2
  stdw [r10-0x1b8], 0x2
  stdw [r10-0x1c8], 0x3
  ldxdw r8, [r1+0x0]
  mov64 r6, r8
  add64 r6, 0x8
  ldxdw r1, [r10-0x298]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r8+0x8]
  jne r3, r2, jmp_11980
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r6+0x8]
  jne r3, r2, jmp_11980
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r6+0x10]
  jne r3, r2, jmp_11980
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  ldxdw r3, [r6+0x18]
  jeq r3, r1, jmp_11988

jmp_11980:
  mov64 r2, 0x1

jmp_11988:
  mov64 r9, 0x1
  ldxdw r1, [r10-0x770]
  jne r2, 0x0, jmp_115b8
  mov64 r9, -0x1
  ldxb r2, [r10-0x290]
  jne r2, 0x0, jmp_119c0
  mov64 r9, -0x78

jmp_119c0:
  ldxb r2, [r8+0x0]
  and64 r9, r2
  and64 r9, 0xff
  jeq r9, 0x0, jmp_119f0

jmp_119e0:
  mov64 r9, 0xb
  ja jmp_115b8

jmp_119f0:
  ldxb r2, [r8+0x1]
  mov64 r3, 0x1
  mov64 r5, 0x1
  jne r2, 0x0, jmp_11ed8
  mov64 r5, 0x0
  ldxb r2, [r8+0x2]
  mov64 r9, 0x1
  jeq r2, 0x0, jmp_11ef0

jmp_11a30:
  stxdw [r10-0x778], r5
  ldxb r2, [r8+0x3]
  jne r2, 0x0, jmp_11a50

jmp_11a48:
  mov64 r3, 0x0

jmp_11a50:
  ldxdw r2, [r8+0x50]
  mov64 r5, r3
  mov64 r3, r8
  add64 r3, 0x28
  stxdw [r10-0x190], r3
  mov64 r3, r8
  add64 r3, 0x58
  stxdw [r10-0x198], r3
  stxdw [r10-0x1a0], r2
  add64 r8, 0x48
  stxdw [r10-0x1a8], r8
  stxdw [r10-0x1b0], r6
  stxb [r10-0x17e], r5
  stxb [r10-0x17f], r9
  ldxdw r2, [r10-0x778]
  stxb [r10-0x180], r2
  stdw [r10-0x188], 0x0
  ldxdw r8, [r7+0x0]
  mov64 r6, r8
  add64 r6, 0x8
  ldxdw r9, [r10-0x288]
  ldxdw r2, [r9+0x0]
  ldxdw r3, [r8+0x8]
  jne r3, r2, jmp_11b60
  ldxdw r2, [r9+0x8]
  ldxdw r3, [r6+0x8]
  jne r3, r2, jmp_11b60
  ldxdw r2, [r9+0x10]
  ldxdw r3, [r6+0x10]
  jne r3, r2, jmp_11b60
  mov64 r2, 0x0
  ldxdw r3, [r9+0x18]
  ldxdw r5, [r6+0x18]
  jeq r5, r3, jmp_11b68

jmp_11b60:
  mov64 r2, 0x1

jmp_11b68:
  mov64 r9, 0x1
  jne r2, 0x0, jmp_115b8
  mov64 r2, -0x1
  ldxb r3, [r10-0x280]
  jne r3, 0x0, jmp_11b98
  mov64 r2, -0x78

jmp_11b98:
  ldxb r3, [r8+0x0]
  and64 r2, r3
  and64 r2, 0xff
  jne r2, 0x0, jmp_119e0
  ldxb r2, [r8+0x1]
  mov64 r3, 0x1
  mov64 r5, 0x1
  jne r2, 0x0, jmp_11f18
  mov64 r5, 0x0
  ldxb r2, [r8+0x2]
  jeq r2, 0x0, jmp_11f28

jmp_11bf0:
  stxdw [r10-0x778], r5
  ldxb r2, [r8+0x3]
  jne r2, 0x0, jmp_11c10

jmp_11c08:
  mov64 r3, 0x0

jmp_11c10:
  ldxdw r2, [r8+0x50]
  mov64 r5, r3
  mov64 r3, r8
  add64 r3, 0x28
  stxdw [r10-0x158], r3
  mov64 r3, r8
  add64 r3, 0x58
  stxdw [r10-0x160], r3
  stxdw [r10-0x168], r2
  add64 r8, 0x48
  stxdw [r10-0x170], r8
  stxdw [r10-0x178], r6
  stxb [r10-0x146], r5
  stxb [r10-0x147], r9
  ldxdw r2, [r10-0x778]
  stxb [r10-0x148], r2
  stdw [r10-0x150], 0x0
  ldxdw r8, [r7+0x8]
  mov64 r6, r8
  add64 r6, 0x8
  ldxdw r2, [r4+0x0]
  ldxdw r3, [r8+0x8]
  jne r3, r2, jmp_11d18
  ldxdw r2, [r4+0x8]
  ldxdw r3, [r6+0x8]
  jne r3, r2, jmp_11d18
  ldxdw r2, [r4+0x10]
  ldxdw r3, [r6+0x10]
  jne r3, r2, jmp_11d18
  mov64 r2, 0x0
  ldxdw r3, [r4+0x18]
  ldxdw r4, [r6+0x18]
  jeq r4, r3, jmp_11d20

jmp_11d18:
  mov64 r2, 0x1

jmp_11d20:
  mov64 r9, 0x1
  jne r2, 0x0, jmp_115b8
  ldxb r2, [r8+0x0]
  and64 r2, 0x88
  jne r2, 0x0, jmp_119e0
  ldxb r2, [r8+0x1]
  mov64 r4, 0x1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_11f50
  mov64 r1, 0x0
  ldxb r2, [r8+0x2]
  jeq r2, 0x0, jmp_11f60

jmp_11d80:
  ldxb r2, [r8+0x3]
  jne r2, 0x0, jmp_11d98

jmp_11d90:
  mov64 r4, 0x0

jmp_11d98:
  ldxdw r2, [r8+0x50]
  mov64 r3, r8
  add64 r3, 0x28
  stxdw [r10-0x120], r3
  mov64 r3, r8
  add64 r3, 0x58
  stxdw [r10-0x128], r3
  stxdw [r10-0x130], r2
  add64 r8, 0x48
  stxdw [r10-0x138], r8
  stxdw [r10-0x140], r6
  stxb [r10-0x10e], r4
  stxb [r10-0x10f], r9
  stxb [r10-0x110], r1
  stdw [r10-0x118], 0x0
  ldxdw r6, [r7+0x10]
  mov64 r4, r6
  add64 r4, 0x8
  ldxdw r1, [r0+0x0]
  ldxdw r2, [r6+0x8]
  jne r2, r1, jmp_11e90
  ldxdw r1, [r0+0x8]
  ldxdw r2, [r4+0x8]
  jne r2, r1, jmp_11e90
  ldxdw r1, [r0+0x10]
  ldxdw r2, [r4+0x10]
  jne r2, r1, jmp_11e90
  mov64 r2, 0x0
  ldxdw r1, [r0+0x18]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_11e98

jmp_11e90:
  mov64 r2, 0x1

jmp_11e98:
  mov64 r9, 0x1
  ldxdw r1, [r10-0x770]
  jne r2, 0x0, jmp_115b8
  ldxb r1, [r6+0x0]
  jeq r1, 0x0, jmp_12028

jmp_11ec0:
  mov64 r9, 0xb
  ldxdw r1, [r10-0x770]
  ja jmp_115b8

jmp_11ed8:
  ldxb r2, [r8+0x2]
  mov64 r9, 0x1
  jne r2, 0x0, jmp_11a30

jmp_11ef0:
  mov64 r9, 0x0
  stxdw [r10-0x778], r5
  ldxb r2, [r8+0x3]
  jeq r2, 0x0, jmp_11a48
  ja jmp_11a50

jmp_11f18:
  ldxb r2, [r8+0x2]
  jne r2, 0x0, jmp_11bf0

jmp_11f28:
  mov64 r9, 0x0
  stxdw [r10-0x778], r5
  ldxb r2, [r8+0x3]
  jeq r2, 0x0, jmp_11c08
  ja jmp_11c10

jmp_11f50:
  ldxb r2, [r8+0x2]
  jne r2, 0x0, jmp_11d80

jmp_11f60:
  mov64 r9, 0x0
  ldxb r2, [r8+0x3]
  jeq r2, 0x0, jmp_11d90
  ja jmp_11d98

jmp_11f80:
  mov64 r4, 0x0
  ldxdw r1, [r10-0x770]
  mov64 r9, 0x2
  and64 r4, 0x1
  jeq r4, 0x0, jmp_115b8
  ja jmp_11690

jmp_11fb0:
  mov64 r1, 0x8
  mov64 r2, r5
  lddw r3, data_0be0
  call fn_292f0

jmp_11fd8:
  mov64 r1, r5
  mov64 r2, 0x4d0
  lddw r3, data_0be0
  call fn_292e8

jmp_12000:
  mov64 r1, r5
  mov64 r2, r3
  lddw r3, data_0bf8
  call fn_292f8

jmp_12028:
  ldxb r2, [r6+0x1]
  mov64 r0, 0x1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_12718
  mov64 r1, 0x0
  ldxb r2, [r6+0x2]
  mov64 r8, 0x1
  jeq r2, 0x0, jmp_12730

jmp_12068:
  ldxb r2, [r6+0x3]
  jne r2, 0x0, jmp_12080

jmp_12078:
  mov64 r0, 0x0

jmp_12080:
  ldxdw r2, [r6+0x50]
  mov64 r3, r6
  add64 r3, 0x28
  stxdw [r10-0xe8], r3
  mov64 r3, r6
  add64 r3, 0x58
  stxdw [r10-0xf0], r3
  stxdw [r10-0xf8], r2
  add64 r6, 0x48
  stxdw [r10-0x100], r6
  stxdw [r10-0x108], r4
  stxb [r10-0xd6], r0
  stxb [r10-0xd7], r8
  stxb [r10-0xd8], r1
  stdw [r10-0xe0], 0x0
  ldxdw r1, [r10-0x780]
  ldxdw r0, [r1+0x0]
  mov64 r4, r0
  add64 r4, 0x8
  ldxdw r1, [r10-0x798]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r0+0x8]
  jne r2, r1, jmp_121a0
  ldxdw r1, [r10-0x798]
  ldxdw r1, [r1+0x8]
  ldxdw r2, [r4+0x8]
  jne r2, r1, jmp_121a0
  ldxdw r1, [r10-0x798]
  ldxdw r1, [r1+0x10]
  ldxdw r2, [r4+0x10]
  jne r2, r1, jmp_121a0
  mov64 r2, 0x0
  ldxdw r1, [r10-0x798]
  ldxdw r1, [r1+0x18]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_121a8

jmp_121a0:
  mov64 r2, 0x1

jmp_121a8:
  ldxdw r1, [r10-0x770]
  jne r2, 0x0, jmp_115b8
  ldxb r1, [r0+0x0]
  jne r1, 0x0, jmp_11ec0
  ldxb r2, [r0+0x1]
  mov64 r5, 0x1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_12750
  mov64 r1, 0x0
  ldxb r2, [r0+0x2]
  mov64 r6, 0x1
  jeq r2, 0x0, jmp_12768

jmp_12208:
  ldxb r2, [r0+0x3]
  jne r2, 0x0, jmp_12220

jmp_12218:
  mov64 r5, 0x0

jmp_12220:
  ldxdw r2, [r0+0x50]
  mov64 r3, r0
  add64 r3, 0x28
  stxdw [r10-0xb0], r3
  mov64 r3, r0
  add64 r3, 0x58
  stxdw [r10-0xb8], r3
  stxdw [r10-0xc0], r2
  add64 r0, 0x48
  stxdw [r10-0xc8], r0
  stxdw [r10-0xd0], r4
  stxb [r10-0x9e], r5
  stxb [r10-0x9f], r6
  stxb [r10-0xa0], r1
  stdw [r10-0xa8], 0x0
  ldxdw r1, [r10-0x7b0]
  ldxdw r5, [r1+0x0]
  mov64 r4, r5
  add64 r4, 0x8
  ldxdw r1, [r10-0x7a8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r5+0x8]
  jne r2, r1, jmp_12340
  ldxdw r1, [r10-0x7a8]
  ldxdw r1, [r1+0x8]
  ldxdw r2, [r4+0x8]
  jne r2, r1, jmp_12340
  ldxdw r1, [r10-0x7a8]
  ldxdw r1, [r1+0x10]
  ldxdw r2, [r4+0x10]
  jne r2, r1, jmp_12340
  mov64 r2, 0x0
  ldxdw r1, [r10-0x7a8]
  ldxdw r1, [r1+0x18]
  ldxdw r3, [r4+0x18]
  jeq r3, r1, jmp_12348

jmp_12340:
  mov64 r2, 0x1

jmp_12348:
  ldxdw r1, [r10-0x770]
  jne r2, 0x0, jmp_115b8
  ldxb r1, [r5+0x0]
  and64 r1, 0x88
  jne r1, 0x0, jmp_11ec0
  ldxb r2, [r5+0x1]
  mov64 r3, 0x1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_12788
  mov64 r1, 0x0
  ldxb r2, [r5+0x2]
  mov64 r0, 0x1
  jeq r2, 0x0, jmp_127a0

jmp_123b0:
  ldxb r2, [r5+0x3]
  jne r2, 0x0, jmp_123c8

jmp_123c0:
  mov64 r3, 0x0

jmp_123c8:
  ldxdw r2, [r5+0x50]
  mov64 r6, r5
  add64 r6, 0x28
  stxdw [r10-0x78], r6
  mov64 r6, r5
  add64 r6, 0x58
  stxdw [r10-0x80], r6
  stxdw [r10-0x88], r2
  add64 r5, 0x48
  stxdw [r10-0x90], r5
  stxdw [r10-0x98], r4
  stxb [r10-0x66], r3
  stxb [r10-0x67], r0
  stxb [r10-0x68], r1
  stdw [r10-0x70], 0x0
  ldxdw r4, [r7+0x18]
  mov64 r3, r4
  add64 r3, 0x8
  ldxdw r1, [r10-0x7b8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r4+0x8]
  jne r2, r1, jmp_124e0
  ldxdw r1, [r10-0x7b8]
  ldxdw r1, [r1+0x8]
  ldxdw r2, [r3+0x8]
  jne r2, r1, jmp_124e0
  ldxdw r1, [r10-0x7b8]
  ldxdw r1, [r1+0x10]
  ldxdw r2, [r3+0x10]
  jne r2, r1, jmp_124e0
  mov64 r2, 0x0
  ldxdw r1, [r10-0x7b8]
  ldxdw r1, [r1+0x18]
  ldxdw r5, [r3+0x18]
  jeq r5, r1, jmp_124e8

jmp_124e0:
  mov64 r2, 0x1

jmp_124e8:
  ldxdw r1, [r10-0x770]
  jne r2, 0x0, jmp_115b8
  ldxb r2, [r4+0x0]
  and64 r2, 0x88
  mov64 r9, 0xb
  jne r2, 0x0, jmp_115b8
  ldxb r5, [r4+0x1]
  mov64 r2, 0x1
  mov64 r1, 0x1
  jne r5, 0x0, jmp_127c0
  mov64 r1, 0x0
  ldxb r0, [r4+0x2]
  mov64 r5, 0x1
  jeq r0, 0x0, jmp_127d8

jmp_12558:
  ldxb r0, [r4+0x3]
  jne r0, 0x0, jmp_12570

jmp_12568:
  mov64 r2, 0x0

jmp_12570:
  ldxdw r0, [r4+0x50]
  mov64 r6, r4
  add64 r6, 0x28
  stxdw [r10-0x40], r6
  mov64 r6, r4
  add64 r6, 0x58
  stxdw [r10-0x48], r6
  stxdw [r10-0x50], r0
  add64 r4, 0x48
  stxdw [r10-0x58], r4
  stxdw [r10-0x60], r3
  stxb [r10-0x2e], r2
  stxb [r10-0x2f], r5
  stxb [r10-0x30], r1
  stdw [r10-0x38], 0x0
  ldxdw r1, [r10-0x7a0]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x768
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x298
  stxdw [r10-0x20], r1
  lddw r1, data_0140
  stxdw [r10-0x28], r1
  stdw [r10-0x18], 0x7
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x1b0
  mov64 r4, r10
  add64 r4, -0x1d0
  mov64 r3, 0x7
  mov64 r5, 0x2
  call sol_invoke_signed_c
  mov64 r1, r10
  add64 r1, -0x1b0
  ldxdw r2, [r10-0x780]
  ldxdw r3, [r10-0x788]
  call fn_12868
  ldxw r1, [r10-0x1b0]
  jne r1, 0x0, jmp_126f8
  ldxdw r6, [r10-0x1a8]
  mov64 r1, r10
  add64 r1, -0x1b0
  call fn_287f0
  ldxw r1, [r10-0x1b0]
  jeq r1, 0x0, jmp_127f8

jmp_126f8:
  ldxw r8, [r10-0x1a8]
  ldxw r9, [r10-0x1ac]
  ldxdw r1, [r10-0x770]
  ja jmp_115b8

jmp_12718:
  ldxb r2, [r6+0x2]
  mov64 r8, 0x1
  jne r2, 0x0, jmp_12068

jmp_12730:
  mov64 r8, 0x0
  ldxb r2, [r6+0x3]
  jeq r2, 0x0, jmp_12078
  ja jmp_12080

jmp_12750:
  ldxb r2, [r0+0x2]
  mov64 r6, 0x1
  jne r2, 0x0, jmp_12208

jmp_12768:
  mov64 r6, 0x0
  ldxb r2, [r0+0x3]
  jeq r2, 0x0, jmp_12218
  ja jmp_12220

jmp_12788:
  ldxb r2, [r5+0x2]
  mov64 r0, 0x1
  jne r2, 0x0, jmp_123b0

jmp_127a0:
  mov64 r0, 0x0
  ldxb r2, [r5+0x3]
  jeq r2, 0x0, jmp_123c0
  ja jmp_123c8

jmp_127c0:
  ldxb r0, [r4+0x2]
  mov64 r5, 0x1
  jne r0, 0x0, jmp_12558

jmp_127d8:
  mov64 r5, 0x0
  ldxb r0, [r4+0x3]
  jeq r0, 0x0, jmp_12568
  ja jmp_12570

jmp_127f8:
  ldxdw r1, [r10-0x188]
  mov64 r9, 0x0
  mov64 r8, 0x28
  jsle r6, r1, jmp_12828
  ldxdw r1, [r10-0x770]
  ja jmp_115b8

jmp_12828:
  ldxdw r1, [r10-0x770]
  ldxdw r2, [r10-0x790]
  jeq r2, 0x0, jmp_12858
  mov64 r8, 0x2b
  ldxdw r2, [r10-0x7c0]
  jsle r6, r2, jmp_115b8

jmp_12858:
  mov64 r9, 0x1a
  ja jmp_115b8

fn_12868:
  ldxdw r4, [r2+0x0]
  ldxdw r5, [r4+0x28]
  lddw r0, 0x48a6f752bbfab70c
  jne r5, r0, jmp_128f8
  ldxdw r5, [r4+0x30]
  lddw r0, -0x6f74fe6582cea445
  jne r5, r0, jmp_128f8
  ldxdw r5, [r4+0x38]
  lddw r0, 0x1fefa744702cb57
  jne r5, r0, jmp_128f8
  mov64 r5, 0x0
  ldxdw r0, [r4+0x40]
  lddw r6, -0x7ea7c73367203b1a
  jeq r0, r6, jmp_12900

jmp_128f8:
  mov64 r5, 0x1

jmp_12900:
  jeq r5, 0x0, jmp_12918
  stw [r1+0x8], 0x14
  ja jmp_12930

jmp_12918:
  ldxdw r4, [r4+0x50]
  jge r4, 0x85, jmp_12940
  stw [r1+0x8], 0xa

jmp_12930:
  stdw [r1+0x0], 0x1

jmp_12938:
  exit

jmp_12940:
  mov64 r7, r3
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_28528
  ldxw r2, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxdw r4, [r10-0x20]
  jeq r4, 0x0, jmp_12b98
  lsh64 r2, 0x20
  or64 r2, r1
  mov64 r5, r6
  mov64 r0, r7
  jle r2, 0x7, jmp_12bf0
  ldxb r3, [r10-0x8]
  ldxdw r1, [r10-0x10]
  mov64 r6, 0x1d
  ldxdw r7, [r4+0x0]
  lddw r8, -0x320b81629cdc0ede
  jne r7, r8, jmp_12b38
  jle r2, 0x27, jmp_12c10
  ldxdw r6, [r4+0x8]
  lddw r7, -0x58cc237c9f9e3249
  jne r6, r7, jmp_12a78
  ldxdw r6, [r4+0x10]
  lddw r7, -0x26f1f020f64622e4
  jne r6, r7, jmp_12a78
  ldxdw r6, [r4+0x18]
  lddw r7, 0x3d1f6770b437dc4e
  jne r6, r7, jmp_12a78
  mov64 r7, 0x0
  ldxdw r6, [r4+0x20]
  lddw r8, 0x65a22ff8508fdeb
  jeq r6, r8, jmp_12a80

jmp_12a78:
  mov64 r7, 0x1

jmp_12a80:
  mov64 r6, 0x10
  jne r7, 0x0, jmp_12b38
  jeq r2, 0x28, jmp_12ca0
  mov64 r6, 0x1c
  ldxb r7, [r4+0x28]
  jne r7, 0x1, jmp_12b38
  jle r2, 0x48, jmp_12c30
  ldxdw r6, [r0+0x0]
  ldxdw r7, [r4+0x29]
  jne r7, r6, jmp_12b20
  ldxdw r6, [r0+0x8]
  ldxdw r7, [r4+0x31]
  jne r7, r6, jmp_12b20
  ldxdw r6, [r0+0x10]
  ldxdw r7, [r4+0x39]
  jne r7, r6, jmp_12b20
  mov64 r7, 0x0
  ldxdw r0, [r0+0x18]
  ldxdw r6, [r4+0x41]
  jeq r6, r0, jmp_12b28

jmp_12b20:
  mov64 r7, 0x1

jmp_12b28:
  mov64 r6, 0x1b
  jeq r7, 0x0, jmp_12bb8

jmp_12b38:
  stxw [r5+0x8], r6
  stdw [r5+0x0], 0x1
  jgt r3, 0x7, jmp_12c70
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jlt r3, r4, jmp_12c88
  sub64 r3, r2
  stxb [r1+0x0], r3
  ja jmp_12938

jmp_12b98:
  stxw [r6+0x8], r2
  stxw [r6+0x4], r1
  stw [r6+0x0], 0x1
  ja jmp_12938

jmp_12bb8:
  jle r2, 0x64, jmp_12c50
  ldxdw r2, [r4+0x5d]
  stxdw [r5+0x8], r2
  stw [r5+0x0], 0x0
  mov64 r2, r3
  call fn_0788
  ja jmp_12938

jmp_12bf0:
  mov64 r1, 0x8
  lddw r3, data_0c10
  call fn_292e8

jmp_12c10:
  mov64 r1, 0x28
  lddw r3, data_0c28
  call fn_292e8

jmp_12c30:
  mov64 r1, 0x49
  lddw r3, data_0c58
  call fn_292e8

jmp_12c50:
  mov64 r1, 0x65
  lddw r3, data_0c70
  call fn_292e8

jmp_12c70:
  lddw r1, data_0810
  call fn_29a40

jmp_12c88:
  lddw r1, data_0828
  call fn_29938

jmp_12ca0:
  mov64 r1, 0x28
  mov64 r2, 0x28
  lddw r3, data_0c40
  call fn_28b70

fn_12cc8:
  mov64 r6, r1
  ldxdw r8, [r2+0x18]
  ldxdw r7, [r2+0x10]
  ldxdw r9, [r2+0x8]
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x8], r1
  lddw r1, str_045f
  mov64 r2, 0x8
  call sol_log_
  mov64 r3, 0xa
  jne r8, 0x5, jmp_12dd8
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r1+0x8]
  lddw r3, -0x60f4508de13d20f0
  jne r2, r3, jmp_12db8
  ldxdw r2, [r1+0x10]
  lddw r3, -0x1a9939e80f5e6338
  jne r2, r3, jmp_12db8
  ldxdw r2, [r1+0x18]
  lddw r3, 0x456c527702a976f0
  jne r2, r3, jmp_12db8
  mov64 r2, 0x0
  ldxdw r3, [r1+0x20]
  lddw r4, -0x3c173f54b221ad4c
  jeq r3, r4, jmp_12dc0

jmp_12db8:
  mov64 r2, 0x1

jmp_12dc0:
  lddw r3, 0x700000000
  jeq r2, 0x0, jmp_12df0

jmp_12dd8:
  stxdw [r6+0x8], r3
  stdw [r6+0x0], 0x0

jmp_12de8:
  exit

jmp_12df0:
  ldxb r1, [r1+0x1]
  jeq r1, 0x0, jmp_13068
  mov64 r1, r7
  add64 r1, 0x10
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r2+0x8]
  lddw r5, -0x58cc237c9f9e3249
  jne r4, r5, jmp_12ea0
  ldxdw r4, [r2+0x10]
  lddw r5, -0x26f1f020f64622e4
  jne r4, r5, jmp_12ea0
  ldxdw r4, [r2+0x18]
  lddw r5, 0x3d1f6770b437dc4e
  jne r4, r5, jmp_12ea0
  mov64 r4, 0x0
  ldxdw r2, [r2+0x20]
  lddw r5, 0x65a22ff8508fdeb
  jeq r2, r5, jmp_12ea8

jmp_12ea0:
  mov64 r4, 0x1

jmp_12ea8:
  jne r4, 0x0, jmp_12dd8
  mov64 r2, r7
  add64 r2, 0x18
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r3+0x8]
  lddw r5, 0x159c60ddbb666655
  jne r4, r5, jmp_12f50
  ldxdw r4, [r3+0x10]
  lddw r5, 0x13ceabfc31d4fea5
  jne r4, r5, jmp_12f50
  ldxdw r4, [r3+0x18]
  lddw r5, -0xc61440f28fcbdf8
  jne r4, r5, jmp_12f50
  mov64 r4, 0x0
  ldxdw r5, [r3+0x20]
  lddw r0, 0x1fa9f063dd575e01
  jeq r5, r0, jmp_12f58

jmp_12f50:
  mov64 r4, 0x1

jmp_12f58:
  jeq r4, 0x0, jmp_13008
  ldxdw r4, [r3+0x8]
  lddw r5, 0x8f89b063bc68294
  jne r4, r5, jmp_12fe8
  ldxdw r4, [r3+0x10]
  lddw r5, 0x6e1fc181b0fbb2f5
  jne r4, r5, jmp_12fe8
  ldxdw r4, [r3+0x18]
  lddw r5, 0x579a638a98b7be
  jne r4, r5, jmp_12fe8
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  lddw r5, 0x12718c3f29438447
  jeq r3, r5, jmp_12ff0

jmp_12fe8:
  mov64 r4, 0x1

jmp_12ff0:
  lddw r3, 0x600000000
  jne r4, 0x0, jmp_12dd8

jmp_13008:
  jne r9, 0x8, jmp_13080
  add64 r7, 0x8
  ldxdw r3, [r10-0x8]
  ldxdw r3, [r3+0x0]
  stxdw [r6+0x18], r3
  stxdw [r6+0x10], r2
  mov64 r2, r1
  rsh64 r2, 0x20
  stxw [r6+0xc], r2
  stxw [r6+0x8], r1
  stxdw [r6+0x0], r7
  ja jmp_12de8

jmp_13068:
  lddw r3, 0x800000000
  ja jmp_12dd8

jmp_13080:
  stdw [r6+0x0], 0x0
  stw [r6+0x8], 0x2
  ja jmp_12de8

fn_13098:
  jne r3, 0x8, jmp_13218
  ldxdw r3, [r2+0x20]
  ldxdw r4, [r3+0x8]
  lddw r5, 0x159c60ddbb666655
  jne r4, r5, jmp_13130
  ldxdw r4, [r3+0x10]
  lddw r5, 0x13ceabfc31d4fea5
  jne r4, r5, jmp_13130
  ldxdw r4, [r3+0x18]
  lddw r5, -0xc61440f28fcbdf8
  jne r4, r5, jmp_13130
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  lddw r5, 0x1fa9f063dd575e01
  jeq r3, r5, jmp_13138

jmp_13130:
  mov64 r4, 0x1

jmp_13138:
  jne r4, 0x0, jmp_131f0
  mov64 r8, r2
  add64 r8, 0x28
  ldxdw r3, [r8+0x0]
  ldxdw r4, [r3+0x8]
  lddw r5, 0x8f89b063bc68294
  jne r4, r5, jmp_131e0
  ldxdw r4, [r3+0x10]
  lddw r5, 0x6e1fc181b0fbb2f5
  jne r4, r5, jmp_131e0
  ldxdw r4, [r3+0x18]
  lddw r5, 0x579a638a98b7be
  jne r4, r5, jmp_131e0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x20]
  lddw r5, 0x12718c3f29438447
  jeq r3, r5, jmp_131e8

jmp_131e0:
  mov64 r4, 0x1

jmp_131e8:
  jeq r4, 0x0, jmp_13230

jmp_131f0:
  lddw r2, 0x600000000
  stxdw [r1+0x8], r2
  stdw [r1+0x0], 0x0
  ja jmp_13228

jmp_13218:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0xa

jmp_13228:
  exit

jmp_13230:
  mov64 r6, r2
  add64 r6, 0x8
  mov64 r3, 0x3
  ldxdw r4, [r6+0x0]
  ldxdw r5, [r4+0x50]
  jne r5, 0xa5, jmp_132f8
  ldxdw r5, [r4+0x28]
  lddw r0, -0x6c5e9a281e0922fa
  jne r5, r0, jmp_132e8
  ldxdw r5, [r4+0x30]
  lddw r0, -0x53861431b91e3427
  jne r5, r0, jmp_132e8
  ldxdw r5, [r4+0x38]
  lddw r0, -0x6ec8a4a0127a4be4
  jne r5, r0, jmp_132e8
  mov64 r5, 0x0
  ldxdw r4, [r4+0x40]
  lddw r0, -0x56ff00817a0a73c6
  jeq r4, r0, jmp_132f0

jmp_132e8:
  mov64 r5, 0x1

jmp_132f0:
  jeq r5, 0x0, jmp_13310

jmp_132f8:
  stxdw [r1+0x8], r3
  stdw [r1+0x0], 0x0
  ja jmp_13228

jmp_13310:
  stxdw [r10-0x28], r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  call fn_28528
  ldxdw r2, [r10-0x20]
  jeq r2, 0x0, jmp_13418
  ldxdw r3, [r2+0x20]
  ldxdw r1, [r10-0x28]
  ldxdw r9, [r1+0x0]
  ldxdw r4, [r9+0x8]
  jne r3, r4, jmp_133c8
  ldxdw r3, [r9+0x10]
  ldxdw r4, [r2+0x28]
  jne r4, r3, jmp_133c8
  ldxdw r3, [r9+0x18]
  ldxdw r4, [r2+0x30]
  jne r4, r3, jmp_133c8
  mov64 r3, 0x0
  ldxdw r4, [r9+0x20]
  ldxdw r2, [r2+0x38]
  jeq r2, r4, jmp_133d0

jmp_133c8:
  mov64 r3, 0x1

jmp_133d0:
  ldxb r5, [r10-0x8]
  ldxdw r4, [r10-0x10]
  mov64 r2, r7
  jeq r3, 0x0, jmp_13430
  lddw r1, 0x400000000
  stxdw [r2+0x8], r1
  stdw [r2+0x0], 0x0
  ja jmp_13580

jmp_13418:
  ldxdw r3, [r10-0x18]
  mov64 r1, r7
  ja jmp_132f8

jmp_13430:
  stxdw [r10-0x38], r5
  stxdw [r10-0x30], r4
  mov64 r2, r1
  add64 r2, 0x10
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x40], r2
  call fn_0160
  ldxw r1, [r10-0x14]
  ldxw r2, [r10-0x18]
  ldxdw r3, [r10-0x20]
  jeq r3, 0x0, jmp_13558
  lsh64 r1, 0x20
  ldxdw r4, [r9+0x8]
  ldxdw r5, [r3+0x20]
  jne r5, r4, jmp_13500
  ldxdw r4, [r9+0x10]
  ldxdw r5, [r3+0x28]
  jne r5, r4, jmp_13500
  ldxdw r4, [r9+0x18]
  ldxdw r5, [r3+0x30]
  jne r5, r4, jmp_13500
  mov64 r4, 0x0
  ldxdw r5, [r9+0x20]
  ldxdw r3, [r3+0x38]
  jeq r3, r5, jmp_13508

jmp_13500:
  mov64 r4, 0x1

jmp_13508:
  or64 r1, r2
  ldxdw r2, [r10-0x10]
  ldxdw r3, [r10-0x28]
  jeq r4, 0x0, jmp_135d8
  lddw r3, 0x400000000
  stxdw [r7+0x8], r3
  stdw [r7+0x0], 0x0
  call fn_0788
  ja jmp_13570

jmp_13558:
  stxw [r7+0xc], r1
  stxw [r7+0x8], r2
  stdw [r7+0x0], 0x0

jmp_13570:
  ldxdw r4, [r10-0x30]
  ldxdw r5, [r10-0x38]

jmp_13580:
  mov64 r2, r5
  jgt r2, 0x7, jmp_13670
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_13688
  sub64 r2, r1
  stxb [r4+0x0], r2
  ja jmp_13228

jmp_135d8:
  mov64 r4, r3
  add64 r4, 0x30
  mov64 r5, r3
  add64 r5, 0x20
  mov64 r0, r3
  add64 r0, 0x18
  stxdw [r7+0x30], r4
  stxdw [r7+0x28], r8
  stxdw [r7+0x20], r5
  stxdw [r7+0x18], r0
  ldxdw r4, [r10-0x40]
  stxdw [r7+0x10], r4
  stxdw [r7+0x8], r6
  stxdw [r7+0x0], r3
  call fn_0788
  ldxdw r1, [r10-0x30]
  ldxdw r2, [r10-0x38]
  call fn_0788
  ja jmp_13228

jmp_13670:
  lddw r1, data_0810
  call fn_29a40

jmp_13688:
  lddw r1, data_0828
  call fn_29938

fn_136a0:
  mov64 r6, r1
  ldxb r1, [r2+0x48]
  jeq r1, 0x0, jmp_136e8
  mov64 r1, r10
  add64 r1, -0x10
  call fn_13728
  ldxw r1, [r10-0xc]
  ldxw r2, [r10-0x10]
  ja jmp_13710

jmp_136e8:
  mov64 r1, r10
  add64 r1, -0x8
  call fn_142b0
  ldxw r1, [r10-0x4]
  ldxw r2, [r10-0x8]

jmp_13710:
  stxw [r6+0x0], r2
  stxw [r6+0x4], r1
  exit

fn_13728:
  mov64 r7, r2
  stxdw [r10-0x148], r1
  ldxdw r9, [r7+0x38]
  ldxdw r1, [r7+0x8]
  ldxdw r2, [r7+0x20]
  ldxdw r3, [r7+0x0]
  stxdw [r10-0x20], r3
  stxdw [r10-0x28], r2
  stxdw [r10-0x30], r1
  stxdw [r10-0x18], r9
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r10
  add64 r2, -0x30
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_27588
  ldxw r8, [r10-0x68]
  jne r8, 0x1a, jmp_13920
  ldxdw r2, [r7+0x30]
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r1+0x8]
  lddw r4, -0x593934c5a60125fb
  jne r3, r4, jmp_13858
  ldxdw r3, [r1+0x10]
  lddw r4, 0x6b23daa64f1fad8d
  jne r3, r4, jmp_13858
  ldxdw r3, [r1+0x18]
  lddw r4, -0x4e54e0c1a36e87b4
  jne r3, r4, jmp_13858
  mov64 r3, 0x0
  ldxdw r4, [r1+0x20]
  lddw r5, -0x5e5d0abbcad8efe0
  jeq r4, r5, jmp_13860

jmp_13858:
  mov64 r3, 0x1

jmp_13860:
  mov64 r8, 0x3
  jne r3, 0x0, jmp_13938
  lddw r8, 0xa00000000
  ldxdw r1, [r1+0x50]
  jne r1, 0x11, jmp_13938
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxdw r8, [r10-0x30]
  jeq r8, 0x0, jmp_13930
  ldxb r1, [r10-0x18]
  stxdw [r10-0x150], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x158], r1
  ldxdw r6, [r8+0x0]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_13968
  ldxw r6, [r10-0x28]
  ldxw r8, [r10-0x2c]
  ja jmp_140a0

jmp_13920:
  ldxw r6, [r10-0x64]
  ja jmp_13948

jmp_13930:
  ldxdw r8, [r10-0x28]

jmp_13938:
  mov64 r6, r8
  rsh64 r6, 0x20

jmp_13948:
  ldxdw r1, [r10-0x148]
  stxw [r1+0x0], r8
  stxw [r1+0x4], r6
  exit

jmp_13968:
  mov64 r4, r8
  ldxdw r2, [r10-0x28]
  mov64 r1, r2
  sub64 r1, r6
  mov64 r8, 0x0
  mov64 r3, 0x1
  jle r1, r2, jmp_139c8
  mov64 r2, 0x0
  jeq r3, 0x0, jmp_139e0

jmp_139b0:
  mov64 r6, 0xd
  jle r2, 0xc8, jmp_139f8
  ja jmp_140a0

jmp_139c8:
  mov64 r3, 0x0
  mov64 r2, 0x0
  jne r3, 0x0, jmp_139b0

jmp_139e0:
  mov64 r2, r1
  mov64 r6, 0xd
  jgt r2, 0xc8, jmp_140a0

jmp_139f8:
  mov64 r6, 0x0
  ldxdw r1, [r4+0x8]
  stxdw [r10-0x160], r1
  ldxb r2, [r4+0x10]
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_13e28
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_13a50
  mov64 r3, 0xa
  jeq r2, 0x1, jmp_13e28

jmp_13a50:
  mov64 r1, r2
  and64 r1, 0x2
  stxdw [r10-0x168], r2
  jeq r1, 0x0, jmp_13ad8
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r3
  mov64 r3, r8
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x168]
  ldxdw r8, [r10-0x70]
  ldxdw r3, [r10-0x78]
  mov64 r1, r2
  and64 r1, 0xfe
  jeq r1, 0x2, jmp_13e28

jmp_13ad8:
  mov64 r1, r2
  and64 r1, 0x4
  jeq r1, 0x0, jmp_13b58
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, r3
  mov64 r3, r8
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x168]
  ldxdw r8, [r10-0x80]
  ldxdw r3, [r10-0x88]
  mov64 r1, r2
  and64 r1, 0xfc
  jeq r1, 0x4, jmp_13e28

jmp_13b58:
  mov64 r1, r2
  and64 r1, 0x8
  jeq r1, 0x0, jmp_13bd8
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r3
  mov64 r3, r8
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x168]
  ldxdw r8, [r10-0x90]
  ldxdw r3, [r10-0x98]
  mov64 r1, r2
  and64 r1, 0xf8
  jeq r1, 0x8, jmp_13e28

jmp_13bd8:
  mov64 r1, r2
  and64 r1, 0x10
  jeq r1, 0x0, jmp_13c60
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r3
  mov64 r3, r8
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x168]
  ldxdw r8, [r10-0xa0]
  ldxdw r3, [r10-0xa8]
  mov64 r1, r2
  and64 r1, 0xf0
  jeq r1, 0x10, jmp_13e28

jmp_13c60:
  mov64 r1, r2
  and64 r1, 0x20
  jeq r1, 0x0, jmp_14298
  mov64 r1, r10
  add64 r1, -0xd8
  mov64 r2, r3
  stxdw [r10-0x178], r3
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x170], r8
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xb8
  ldxdw r2, [r10-0x178]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r3, [r10-0xd0]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_13d70
  mov64 r2, 0x0

jmp_13d70:
  ldxdw r5, [r10-0xd8]
  ldxdw r4, [r10-0xc8]
  mov64 r3, 0x1
  ldxdw r0, [r10-0x170]
  jeq r0, 0x0, jmp_14210
  add64 r4, r5
  ldxdw r0, [r10-0xc0]
  mov64 r5, 0x1
  jeq r0, 0x0, jmp_14238

jmp_13db8:
  ldxdw r0, [r10-0xb0]
  mov64 r8, r0
  add64 r8, r4
  jlt r8, r0, jmp_13de0

jmp_13dd8:
  mov64 r1, 0x0

jmp_13de0:
  or64 r3, r5
  or64 r3, r2
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_14298
  ldxdw r1, [r10-0x168]
  and64 r1, 0xe0
  jne r1, 0x20, jmp_14298
  ldxdw r3, [r10-0xb8]

jmp_13e28:
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r8
  mov64 r8, r3
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0xf0]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_13ec0
  mov64 r1, 0x0

jmp_13ec0:
  ldxdw r3, [r10-0xe0]
  ldxdw r4, [r10-0xf8]
  mov64 r2, r3
  add64 r2, r4
  mov64 r4, 0x1
  jlt r2, r3, jmp_13ef8
  mov64 r4, 0x0

jmp_13ef8:
  or64 r1, r4
  mov64 r8, 0x2
  and64 r1, 0x1
  jne r1, 0x0, jmp_140a0
  ldxdw r9, [r10-0xe8]
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r3, 0x0
  mov64 r4, 0x270f
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, 0x270f
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  ldxdw r3, [r10-0x110]
  mov64 r1, 0x1
  jne r3, 0x0, jmp_13fb0
  mov64 r1, 0x0

jmp_13fb0:
  ldxdw r0, [r10-0x100]
  ldxdw r5, [r10-0x118]
  mov64 r3, r0
  add64 r3, r5
  ldxdw r4, [r10-0x160]
  jlt r3, r0, jmp_13fe8
  mov64 r2, 0x0

jmp_13fe8:
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_140a0
  jeq r4, 0x0, jmp_140a0
  ldxdw r2, [r10-0x108]
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r5, 0x0
  call fn_2c2b0
  mov64 r1, r10
  add64 r1, -0x138
  ldxdw r2, [r10-0x128]
  ldxdw r9, [r10-0x120]
  mov64 r3, r9
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  jgt r9, 0x270f, jmp_140a0
  ldxdw r1, [r10-0x138]
  ldxdw r2, [r7+0x40]
  jle r2, r1, jmp_14108
  mov64 r8, 0x0
  mov64 r6, 0xf

jmp_140a0:
  ldxdw r1, [r10-0x150]
  mov64 r2, r1
  jgt r2, 0x7, jmp_14268
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxdw r4, [r10-0x158]
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_14280
  sub64 r2, r1
  stxb [r4+0x0], r2
  ja jmp_13948

jmp_14108:
  lddw r2, data_0467
  stxdw [r10-0x50], r2
  lddw r2, str_03de
  stxdw [r10-0x60], r2
  stdw [r10-0x48], 0x1
  stdw [r10-0x58], 0x4
  ldxdw r2, [r7+0x28]
  ldxdw r3, [r7+0x10]
  ldxdw r4, [r7+0x18]
  stxdw [r10-0x18], r1
  stxdw [r10-0x20], r4
  stxdw [r10-0x28], r3
  stxdw [r10-0x30], r2
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x40], r1
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0x30
  mov64 r3, r10
  add64 r3, -0x40
  mov64 r4, 0x1
  call fn_27588
  ldxw r6, [r10-0x13c]
  ldxw r8, [r10-0x140]
  ldxdw r1, [r10-0x158]
  ldxdw r2, [r10-0x150]
  call fn_0788
  ja jmp_13948

jmp_14210:
  mov64 r3, 0x0
  add64 r4, r5
  ldxdw r0, [r10-0xc0]
  mov64 r5, 0x1
  jne r0, 0x0, jmp_13db8

jmp_14238:
  mov64 r5, 0x0
  ldxdw r0, [r10-0xb0]
  mov64 r8, r0
  add64 r8, r4
  jge r8, r0, jmp_13dd8
  ja jmp_13de0

jmp_14268:
  lddw r1, data_0810
  call fn_29a40

jmp_14280:
  lddw r1, data_0828
  call fn_29938

jmp_14298:
  lddw r1, data_07f8
  call fn_29990

fn_142b0:
  mov64 r7, r2
  stxdw [r10-0x138], r1
  ldxdw r9, [r7+0x38]
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r7+0x28]
  ldxdw r3, [r7+0x0]
  stxdw [r10-0x20], r3
  stxdw [r10-0x28], r2
  stxdw [r10-0x30], r1
  stxdw [r10-0x18], r9
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r10
  add64 r2, -0x30
  mov64 r3, 0x8
  mov64 r4, 0x0
  call fn_27588
  ldxw r8, [r10-0x68]
  jne r8, 0x1a, jmp_144a8
  ldxdw r2, [r7+0x30]
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r1+0x8]
  lddw r4, -0x593934c5a60125fb
  jne r3, r4, jmp_143e0
  ldxdw r3, [r1+0x10]
  lddw r4, 0x6b23daa64f1fad8d
  jne r3, r4, jmp_143e0
  ldxdw r3, [r1+0x18]
  lddw r4, -0x4e54e0c1a36e87b4
  jne r3, r4, jmp_143e0
  mov64 r3, 0x0
  ldxdw r4, [r1+0x20]
  lddw r5, -0x5e5d0abbcad8efe0
  jeq r4, r5, jmp_143e8

jmp_143e0:
  mov64 r3, 0x1

jmp_143e8:
  mov64 r8, 0x3
  jne r3, 0x0, jmp_144c0
  lddw r8, 0xa00000000
  ldxdw r1, [r1+0x50]
  jne r1, 0x11, jmp_144c0
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxdw r8, [r10-0x30]
  jeq r8, 0x0, jmp_144b8
  ldxb r1, [r10-0x18]
  stxdw [r10-0x140], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x148], r1
  ldxdw r6, [r8+0x0]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_144f0
  ldxw r6, [r10-0x28]
  ldxw r8, [r10-0x2c]
  ja jmp_14c28

jmp_144a8:
  ldxw r6, [r10-0x64]
  ja jmp_144d0

jmp_144b8:
  ldxdw r8, [r10-0x28]

jmp_144c0:
  mov64 r6, r8
  rsh64 r6, 0x20

jmp_144d0:
  ldxdw r1, [r10-0x138]
  stxw [r1+0x0], r8
  stxw [r1+0x4], r6
  exit

jmp_144f0:
  stxdw [r10-0x150], r8
  ldxdw r2, [r10-0x28]
  mov64 r1, r2
  sub64 r1, r6
  mov64 r8, 0x0
  mov64 r3, 0x1
  jle r1, r2, jmp_14550
  mov64 r2, 0x0
  jeq r3, 0x0, jmp_14568

jmp_14538:
  mov64 r6, 0xd
  jle r2, 0xc8, jmp_14580
  ja jmp_14c28

jmp_14550:
  mov64 r3, 0x0
  mov64 r2, 0x0
  jne r3, 0x0, jmp_14538

jmp_14568:
  mov64 r2, r1
  mov64 r6, 0xd
  jgt r2, 0xc8, jmp_14c28

jmp_14580:
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r1+0x8]
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r6, 0x0
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xa8
  ldxdw r2, [r10-0x70]
  mov64 r3, 0x0
  mov64 r4, 0x270f
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x98
  ldxdw r2, [r10-0x78]
  mov64 r3, 0x0
  mov64 r4, 0x270f
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r1, [r10-0xa8]
  ldxdw r8, [r10-0x90]
  mov64 r9, r8
  add64 r9, r1
  mov64 r1, r10
  add64 r1, -0x88
  ldxdw r2, [r10-0x98]
  mov64 r3, r9
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  mov64 r1, 0x1
  mov64 r2, 0x1
  jge r9, r8, jmp_146e0
  ldxdw r3, [r10-0xa0]
  jeq r3, 0x0, jmp_146f8

jmp_146b8:
  or64 r1, r2
  mov64 r8, 0x2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_14720
  ja jmp_14c28

jmp_146e0:
  mov64 r2, 0x0
  ldxdw r3, [r10-0xa0]
  jne r3, 0x0, jmp_146b8

jmp_146f8:
  mov64 r1, 0x0
  or64 r1, r2
  mov64 r8, 0x2
  and64 r1, 0x1
  jne r1, 0x0, jmp_14c28

jmp_14720:
  ldxdw r3, [r10-0x80]
  ldxdw r2, [r10-0x88]
  ldxdw r1, [r10-0x150]
  ldxb r9, [r1+0x10]
  jeq r9, 0x0, jmp_14778
  mov64 r1, r9
  mov64 r5, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_14790
  mov64 r4, 0x1
  ja jmp_147a0

jmp_14778:
  mov64 r4, 0x1
  mov64 r5, 0x0
  ja jmp_14bd8

jmp_14790:
  mov64 r4, 0xa
  jeq r9, 0x1, jmp_14bd8

jmp_147a0:
  mov64 r1, r9
  and64 r1, 0x2
  stxdw [r10-0x150], r3
  stxdw [r10-0x158], r2
  jeq r1, 0x0, jmp_14830
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x64
  call fn_2c150
  ldxdw r2, [r10-0x158]
  ldxdw r3, [r10-0x150]
  ldxdw r5, [r10-0xb0]
  ldxdw r4, [r10-0xb8]
  mov64 r1, r9
  and64 r1, 0xfe
  jeq r1, 0x2, jmp_14bd8

jmp_14830:
  mov64 r1, r9
  and64 r1, 0x4
  jeq r1, 0x0, jmp_148b8
  mov64 r1, r10
  add64 r1, -0xc8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x158]
  ldxdw r3, [r10-0x150]
  ldxdw r5, [r10-0xc0]
  ldxdw r4, [r10-0xc8]
  mov64 r1, r9
  and64 r1, 0xfc
  jeq r1, 0x4, jmp_14bd8

jmp_148b8:
  mov64 r1, r9
  and64 r1, 0x8
  jeq r1, 0x0, jmp_14940
  mov64 r1, r10
  add64 r1, -0xd8
  mov64 r2, r4
  mov64 r3, r5
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x158]
  ldxdw r3, [r10-0x150]
  ldxdw r5, [r10-0xd0]
  ldxdw r4, [r10-0xd8]
  mov64 r1, r9
  and64 r1, 0xf8
  jeq r1, 0x8, jmp_14bd8

jmp_14940:
  mov64 r1, r9
  and64 r1, 0x10
  jeq r1, 0x0, jmp_149d0
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r4
  mov64 r3, r5
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x158]
  ldxdw r3, [r10-0x150]
  ldxdw r5, [r10-0xe0]
  ldxdw r4, [r10-0xe8]
  mov64 r1, r9
  and64 r1, 0xf0
  jeq r1, 0x10, jmp_14bd8

jmp_149d0:
  mov64 r1, r9
  and64 r1, 0x20
  jeq r1, 0x0, jmp_14dc8
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r4
  mov64 r3, 0x0
  stxdw [r10-0x168], r4
  lddw r4, 0x4ee2d6d415b
  stxdw [r10-0x160], r5
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x108
  ldxdw r2, [r10-0x160]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xf8
  ldxdw r2, [r10-0x168]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  stxdw [r10-0x168], r1
  ldxdw r3, [r10-0x110]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_14ae8
  mov64 r2, 0x0

jmp_14ae8:
  ldxdw r5, [r10-0x118]
  ldxdw r4, [r10-0x108]
  mov64 r3, 0x1
  ldxdw r0, [r10-0x160]
  jne r0, 0x0, jmp_14b18
  mov64 r3, 0x0

jmp_14b18:
  add64 r4, r5
  ldxdw r0, [r10-0x100]
  mov64 r5, 0x1
  jne r0, 0x0, jmp_14b40
  mov64 r5, 0x0

jmp_14b40:
  ldxdw r1, [r10-0xf0]
  mov64 r0, r1
  add64 r0, r4
  mov64 r4, r0
  jlt r0, r1, jmp_14b78
  mov64 r1, 0x0
  stxdw [r10-0x168], r1

jmp_14b78:
  or64 r3, r5
  or64 r3, r2
  ldxdw r1, [r10-0x168]
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_14dc8
  and64 r9, 0xe0
  ldxdw r3, [r10-0x150]
  ldxdw r2, [r10-0x158]
  mov64 r5, r4
  jne r9, 0x20, jmp_14dc8
  ldxdw r4, [r10-0xf8]

jmp_14bd8:
  mov64 r1, r10
  add64 r1, -0x128
  call fn_2c2b0
  ldxdw r1, [r10-0x120]
  jne r1, 0x0, jmp_14c28
  ldxdw r1, [r10-0x128]
  ldxdw r2, [r7+0x40]
  jle r2, r1, jmp_14c90
  mov64 r8, 0x0
  mov64 r6, 0xf

jmp_14c28:
  ldxdw r1, [r10-0x140]
  mov64 r2, r1
  jgt r2, 0x7, jmp_14d98
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxdw r4, [r10-0x148]
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_14db0
  sub64 r2, r1
  stxb [r4+0x0], r2
  ja jmp_144d0

jmp_14c90:
  lddw r2, data_0467
  stxdw [r10-0x50], r2
  lddw r2, str_03de
  stxdw [r10-0x60], r2
  stdw [r10-0x48], 0x1
  stdw [r10-0x58], 0x4
  ldxdw r2, [r7+0x20]
  ldxdw r3, [r7+0x8]
  ldxdw r4, [r7+0x18]
  stxdw [r10-0x18], r1
  stxdw [r10-0x20], r4
  stxdw [r10-0x28], r3
  stxdw [r10-0x30], r2
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x40], r1
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0x30
  mov64 r3, r10
  add64 r3, -0x40
  mov64 r4, 0x1
  call fn_27588
  ldxw r6, [r10-0x12c]
  ldxw r8, [r10-0x130]
  ldxdw r1, [r10-0x148]
  ldxdw r2, [r10-0x140]
  call fn_0788
  ja jmp_144d0

jmp_14d98:
  lddw r1, data_0810
  call fn_29a40

jmp_14db0:
  lddw r1, data_0828
  call fn_29938

jmp_14dc8:
  lddw r1, data_07f8
  call fn_29990

fn_14de0:
  ldxdw r6, [r3+0x0]
  ldxdw r0, [r2+0x0]
  ldxdw r7, [r0+0x8]
  jne r7, r6, jmp_14e50
  ldxdw r6, [r3+0x8]
  ldxdw r7, [r0+0x10]
  jne r7, r6, jmp_14e50
  ldxdw r6, [r3+0x10]
  ldxdw r7, [r0+0x18]
  jne r7, r6, jmp_14e50
  mov64 r6, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r7, [r0+0x20]
  jeq r7, r3, jmp_14e58

jmp_14e50:
  mov64 r6, 0x1

jmp_14e58:
  jeq r6, 0x0, jmp_14e88
  lddw r2, 0xe00000000

jmp_14e70:
  stxdw [r1+0x0], r2
  sth [r1+0x14], 0x2

jmp_14e80:
  exit

jmp_14e88:
  ldxdw r3, [r0+0x28]
  lddw r6, -0x5d3e4a73274641fb
  jne r3, r6, jmp_14f10
  ldxdw r3, [r0+0x30]
  lddw r6, -0x297bdac46b16b7e2
  jne r3, r6, jmp_14f10
  ldxdw r3, [r0+0x38]
  lddw r6, 0x7299832a665230e9
  jne r3, r6, jmp_14f10
  mov64 r3, 0x0
  ldxdw r6, [r0+0x40]
  lddw r7, -0x6cc41ec9d65332c1
  jeq r6, r7, jmp_14f18

jmp_14f10:
  mov64 r3, 0x1

jmp_14f18:
  ldxdw r6, [r5-0xff0]
  jeq r3, 0x0, jmp_15120
  stxdw [r10-0x68], r1
  ldxdw r1, [r0+0x28]
  lddw r3, 0x48a6f752bbfab70c
  jne r1, r3, jmp_14fb8
  ldxdw r1, [r0+0x30]
  lddw r3, -0x6f74fe6582cea445
  jne r1, r3, jmp_14fb8
  ldxdw r1, [r0+0x38]
  lddw r3, 0x1fefa744702cb57
  jne r1, r3, jmp_14fb8
  mov64 r1, 0x0
  ldxdw r3, [r0+0x40]
  lddw r7, -0x7ea7c73367203b1a
  jeq r3, r7, jmp_14fc0

jmp_14fb8:
  mov64 r1, 0x1

jmp_14fc0:
  ldxdw r8, [r5-0xfe8]
  jeq r1, 0x0, jmp_15240
  ldxdw r1, [r0+0x28]
  lddw r3, -0x452d942aa509b40f
  jne r1, r3, jmp_15058
  ldxdw r1, [r0+0x30]
  lddw r3, 0x271f232c74455e71
  jne r1, r3, jmp_15058
  ldxdw r1, [r0+0x38]
  lddw r3, 0x378f775bcf2136d6
  jne r1, r3, jmp_15058
  mov64 r3, 0x0
  ldxdw r1, [r0+0x40]
  lddw r7, 0x256171d9548a2c1
  jeq r1, r7, jmp_15060

jmp_15058:
  mov64 r3, 0x1

jmp_15060:
  ldxdw r1, [r10-0x68]
  jeq r3, 0x0, jmp_152c8
  ldxdw r3, [r0+0x28]
  lddw r7, -0x2ef915ab4fa6d9f4
  jne r3, r7, jmp_150f8
  ldxdw r3, [r0+0x30]
  lddw r7, 0x626c582b5813378e
  jne r3, r7, jmp_150f8
  ldxdw r3, [r0+0x38]
  lddw r7, -0x164c5fdb9d1c7931
  jne r3, r7, jmp_150f8
  mov64 r3, 0x0
  ldxdw r0, [r0+0x40]
  lddw r7, -0xe007a018e0ac636
  jeq r0, r7, jmp_15100

jmp_150f8:
  mov64 r3, 0x1

jmp_15100:
  jeq r3, 0x0, jmp_15358
  lddw r2, 0x1400000000
  ja jmp_14e70

jmp_15120:
  ldxdw r3, [r0+0x8]
  ldxdw r5, [r4+0x0]
  jne r5, r3, jmp_15188
  ldxdw r3, [r0+0x10]
  ldxdw r5, [r4+0x8]
  jne r5, r3, jmp_15188
  ldxdw r3, [r0+0x18]
  ldxdw r5, [r4+0x10]
  jne r5, r3, jmp_15188
  mov64 r3, 0x0
  ldxdw r5, [r0+0x20]
  ldxdw r4, [r4+0x18]
  jeq r4, r5, jmp_15190

jmp_15188:
  mov64 r3, 0x1

jmp_15190:
  jne r3, 0x0, jmp_15340
  ldxdw r3, [r0+0x50]
  jne r3, 0x11, jmp_15498
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxw r2, [r10-0x24]
  ldxw r3, [r10-0x28]
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_15668
  lsh64 r2, 0x20
  or64 r2, r3
  jle r2, 0x7, jmp_16268
  jle r2, 0xf, jmp_16288
  jeq r2, 0x10, jmp_162d8
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  jeq r6, 0x0, jmp_156b0
  mul64 r6, 0x3e8
  div64 r6, 0x190
  ja jmp_156b8

jmp_15240:
  mov64 r9, r4
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxw r2, [r10-0x24]
  ldxw r1, [r10-0x28]
  ldxdw r7, [r10-0x30]
  jeq r7, 0x0, jmp_153a0
  lsh64 r2, 0x20
  or64 r2, r1
  ldxb r0, [r10-0x18]
  ldxdw r5, [r10-0x20]
  ldxdw r1, [r10-0x68]
  jgt r2, 0x28, jmp_153c8

jmp_152b0:
  lddw r2, 0xa00000000
  ja jmp_15818

jmp_152c8:
  ldxdw r3, [r0+0x8]
  ldxdw r5, [r4+0x0]
  jne r5, r3, jmp_15330
  ldxdw r3, [r0+0x10]
  ldxdw r5, [r4+0x8]
  jne r5, r3, jmp_15330
  ldxdw r3, [r0+0x18]
  ldxdw r5, [r4+0x10]
  jne r5, r3, jmp_15330
  mov64 r3, 0x0
  ldxdw r5, [r0+0x20]
  ldxdw r4, [r4+0x18]
  jeq r4, r5, jmp_15338

jmp_15330:
  mov64 r3, 0x1

jmp_15338:
  jeq r3, 0x0, jmp_154b0

jmp_15340:
  lddw r2, 0x1b00000000
  ja jmp_14e70

jmp_15358:
  ldxdw r0, [r5-0xff8]
  ldxdw r3, [r5-0x1000]
  and64 r3, 0xff
  jne r3, 0x5, jmp_15618
  mov64 r3, r4
  mov64 r4, r0
  mov64 r5, r6
  call fn_187f0
  ja jmp_14e80

jmp_153a0:
  ldxdw r3, [r10-0x68]
  stxw [r3+0x4], r2
  stxw [r3+0x0], r1
  sth [r3+0x14], 0x2
  ja jmp_14e80

jmp_153c8:
  ldxdw r3, [r7+0x0]
  lddw r4, -0x320b81629cdc0ede
  jne r3, r4, jmp_15650
  ldxb r3, [r7+0x28]
  jeq r3, 0x0, jmp_15808
  jne r3, 0x1, jmp_152b0
  jlt r2, 0x85, jmp_152b0
  ldxdw r2, [r9+0x0]
  ldxdw r3, [r7+0x29]
  jne r3, r2, jmp_15470
  ldxdw r2, [r9+0x8]
  ldxdw r3, [r7+0x31]
  jne r3, r2, jmp_15470
  ldxdw r2, [r9+0x10]
  ldxdw r3, [r7+0x39]
  jne r3, r2, jmp_15470
  mov64 r2, 0x0
  ldxdw r3, [r9+0x18]
  ldxdw r4, [r7+0x41]
  jeq r4, r3, jmp_15478

jmp_15470:
  mov64 r2, 0x1

jmp_15478:
  jeq r2, 0x0, jmp_15900
  lddw r2, 0x1b00000000
  ja jmp_15818

jmp_15498:
  lddw r2, 0xa00000000
  ja jmp_14e70

jmp_154b0:
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxw r4, [r10-0x24]
  ldxw r1, [r10-0x28]
  ldxdw r3, [r10-0x30]
  jeq r3, 0x0, jmp_15688
  lsh64 r4, 0x20
  or64 r4, r1
  mov64 r8, 0xa
  mov64 r1, 0x0
  ldxb r9, [r10-0x18]
  ldxdw r7, [r10-0x20]
  ldxdw r2, [r10-0x68]
  jlt r4, 0xf8, jmp_15b70
  mov64 r8, 0x1d
  ldxdw r4, [r3+0x0]
  lddw r5, 0x754981804245b360
  jne r4, r5, jmp_15b70
  mov64 r8, 0x1e
  ldxb r4, [r3+0x8]
  jne r4, 0x2, jmp_15b70
  ldxw r4, [r3+0x94]
  jne r4, 0x1, jmp_15b70
  mov64 r8, 0x24
  ldxw r4, [r3+0x8f]
  jeq r4, 0x0, jmp_15b70
  ldxdw r1, [r3+0xe0]
  stxdw [r10-0x70], r1
  ldxdw r1, [r3+0xd8]
  stxdw [r10-0x80], r1
  ldxw r1, [r3+0xd0]
  stxdw [r10-0x78], r1
  ldxdw r8, [r3+0xc8]
  ldxb r1, [r3+0x8a]
  stxdw [r10-0x88], r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_15ad8

jmp_15600:
  ldxw r8, [r10-0x28]
  ldxw r1, [r10-0x2c]
  ja jmp_15b68

jmp_15618:
  stxdw [r10-0xff8], r8
  stxdw [r10-0x1000], r6
  mov64 r5, r10
  mov64 r3, r4
  mov64 r4, r0
  call fn_18040
  ja jmp_14e80

jmp_15650:
  lddw r2, 0x1d00000000
  ja jmp_15818

jmp_15668:
  stxw [r8+0x4], r2
  stxw [r8+0x0], r3
  sth [r8+0x14], 0x2
  ja jmp_14e80

jmp_15688:
  ldxdw r2, [r10-0x68]
  stxw [r2+0x4], r4
  stxw [r2+0x0], r1
  sth [r2+0x14], 0x2
  ja jmp_14e80

jmp_156b0:
  mov64 r6, 0xc8

jmp_156b8:
  ldxb r7, [r10-0x18]
  ldxdw r2, [r10-0x20]
  stxdw [r10-0x68], r2
  ldxdw r9, [r1+0x0]
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x70], r2
  ldxb r1, [r1+0x10]
  stxdw [r10-0x78], r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_15738
  ldxw r2, [r10-0x28]
  ldxw r1, [r10-0x2c]
  ja jmp_15888

jmp_15738:
  ldxdw r4, [r10-0x28]
  mov64 r2, r4
  sub64 r2, r9
  mov64 r1, 0x0
  mov64 r3, 0x1
  jgt r2, r4, jmp_15798
  mov64 r3, 0x0
  mov64 r4, 0x0
  jeq r3, 0x0, jmp_157a8

jmp_15780:
  mov64 r2, 0xd
  jle r4, r6, jmp_157c0
  ja jmp_15888

jmp_15798:
  mov64 r4, 0x0
  jne r3, 0x0, jmp_15780

jmp_157a8:
  mov64 r4, r2
  mov64 r2, 0xd
  jgt r4, r6, jmp_15888

jmp_157c0:
  ldxdw r2, [r10-0x70]
  jeq r2, 0x0, jmp_15880
  stxdw [r8+0x0], r2
  ldxdw r1, [r10-0x78]
  neg64 r1
  stxw [r8+0x10], r1
  stdw [r8+0x8], 0x0
  sth [r8+0x14], 0x0
  ja jmp_158a0

jmp_15808:
  lddw r2, 0x1c00000000

jmp_15818:
  stxdw [r1+0x0], r2

jmp_15820:
  sth [r1+0x14], 0x2
  mov64 r2, r0
  jgt r2, 0x7, jmp_162a8
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r5+0x0]
  jlt r2, r3, jmp_162c0
  sub64 r2, r1
  stxb [r5+0x0], r2
  ja jmp_14e80

jmp_15880:
  mov64 r2, 0x24

jmp_15888:
  stxw [r8+0x4], r2
  stxw [r8+0x0], r1
  sth [r8+0x14], 0x2

jmp_158a0:
  mov64 r2, r7
  jgt r2, 0x7, jmp_162a8
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxdw r4, [r10-0x68]
  ldxb r2, [r4+0x0]
  jlt r2, r3, jmp_162c0
  sub64 r2, r1
  stxb [r4+0x0], r2
  ja jmp_14e80

jmp_15900:
  stxdw [r10-0x70], r0
  stxdw [r10-0x78], r5
  ldxdw r9, [r7+0x7d]
  ldxw r1, [r7+0x59]
  stxdw [r10-0x90], r1
  ldxdw r1, [r7+0x51]
  stxdw [r10-0x88], r1
  ldxdw r1, [r7+0x49]
  stxdw [r10-0x80], r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_15990
  ldxw r4, [r10-0x28]
  ldxw r3, [r10-0x2c]
  ldxdw r1, [r10-0x68]
  ja jmp_15a30

jmp_15990:
  mov64 r1, r6
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r2, 0x190
  jeq r1, 0x0, jmp_159c8
  mov64 r2, r1
  mul64 r2, 0x5

jmp_159c8:
  stxdw [r10-0x98], r1
  ldxdw r5, [r10-0x28]
  mov64 r4, r5
  sub64 r4, r9
  mov64 r3, 0x0
  mov64 r0, 0x1
  ldxdw r1, [r10-0x68]
  jgt r4, r5, jmp_15a58
  mov64 r0, 0x0
  mov64 r5, 0x0
  jeq r0, 0x0, jmp_15a68

jmp_15a20:
  mov64 r4, 0xd
  jle r5, r2, jmp_15a80

jmp_15a30:
  stxw [r1+0x4], r4
  stxw [r1+0x0], r3

jmp_15a40:
  ldxdw r5, [r10-0x78]
  ldxdw r0, [r10-0x70]
  ja jmp_15820

jmp_15a58:
  mov64 r5, 0x0
  jne r0, 0x0, jmp_15a20

jmp_15a68:
  mov64 r5, r4
  mov64 r4, 0xd
  jgt r5, r2, jmp_15a30

jmp_15a80:
  ldxdw r7, [r7+0x5d]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_15cf0
  ldxw r5, [r10-0x28]
  ldxw r2, [r10-0x2c]
  ldxdw r1, [r10-0x68]
  ldxdw r0, [r10-0x70]
  ja jmp_16058

jmp_15ad8:
  mov64 r0, r6
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r2, 0x190
  jeq r0, 0x0, jmp_15b10
  mov64 r2, r0
  mul64 r2, 0x5

jmp_15b10:
  ldxdw r5, [r10-0x28]
  mov64 r3, r5
  sub64 r3, r8
  mov64 r1, 0x0
  mov64 r4, 0x1
  jgt r3, r5, jmp_15be0
  mov64 r4, 0x0
  mov64 r5, 0x0
  jeq r4, 0x0, jmp_15bf0

jmp_15b58:
  mov64 r8, 0xd
  jle r5, r2, jmp_15c08

jmp_15b68:
  ldxdw r2, [r10-0x68]

jmp_15b70:
  stxw [r2+0x4], r8
  stxw [r2+0x0], r1
  sth [r2+0x14], 0x2
  mov64 r2, r9
  jgt r2, 0x7, jmp_162a8
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r7+0x0]
  jlt r2, r3, jmp_162c0
  sub64 r2, r1
  stxb [r7+0x0], r2
  ja jmp_14e80

jmp_15be0:
  mov64 r5, 0x0
  jne r4, 0x0, jmp_15b58

jmp_15bf0:
  mov64 r5, r3
  mov64 r8, 0xd
  jgt r5, r2, jmp_15b68

jmp_15c08:
  stxdw [r10-0x90], r0
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jeq r1, 0x1, jmp_15600
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  mov64 r3, 0x50
  jeq r6, 0x0, jmp_15c60
  ldxdw r3, [r10-0x90]

jmp_15c60:
  mov64 r1, 0x0
  mov64 r4, 0x1
  mov64 r2, 0x1
  ldxdw r6, [r10-0x78]
  jsgt r6, 0x0, jmp_16078
  mov64 r2, 0x0
  ldxdw r0, [r10-0x8]
  mov64 r5, r0
  sub64 r5, r6
  jsge r5, r0, jmp_16098

jmp_15cb0:
  xor64 r2, r4
  lddw r4, -0x8000000000000000
  jne r2, 0x0, jmp_160c0

jmp_15cd0:
  mov64 r4, r5
  ldxdw r2, [r10-0x68]
  jsgt r4, r3, jmp_15b70
  ja jmp_160d0

jmp_15cf0:
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  mov64 r3, 0x50
  jeq r6, 0x0, jmp_15fe0
  ldxdw r3, [r10-0x98]
  mov64 r2, 0x0
  mov64 r5, 0x1
  mov64 r1, 0x1
  jsle r7, 0x0, jmp_16000

jmp_15d38:
  ldxdw r0, [r10-0x8]
  mov64 r4, r0
  sub64 r4, r7
  jslt r4, r0, jmp_16028

jmp_15d58:
  mov64 r5, 0x0
  xor64 r1, r5
  jeq r1, 0x0, jmp_16038

jmp_15d70:
  arsh64 r4, 0x3f
  lddw r1, -0x8000000000000000
  xor64 r4, r1
  mov64 r5, 0xd
  ldxdw r1, [r10-0x68]
  ldxdw r0, [r10-0x70]
  jsgt r4, r3, jmp_16058

jmp_15db0:
  ldxdw r1, [r10-0x80]
  jslt r1, 0x1, jmp_16250
  mov64 r1, r10
  add64 r1, -0x40
  ldxdw r2, [r10-0x88]
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  and64 r8, 0xffff
  mov64 r1, r8
  jlt r8, 0x3e8, jmp_15e18
  mov64 r1, 0x3e8

jmp_15e18:
  mov64 r4, 0xc8
  jeq r8, 0x0, jmp_15e30
  mov64 r4, r1

jmp_15e30:
  mov64 r1, r10
  add64 r1, -0x50
  ldxdw r2, [r10-0x80]
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r4, 0x1
  ldxdw r1, [r10-0x40]
  ldxdw r3, [r10-0x50]
  mov64 r2, 0x1
  jgt r1, r3, jmp_16148
  mov64 r2, 0x0
  ldxdw r3, [r10-0x38]
  ldxdw r5, [r10-0x48]
  jle r3, r5, jmp_16160

jmp_15ea8:
  jeq r3, r5, jmp_16170

jmp_15eb0:
  mov64 r2, r4
  and64 r2, 0x1
  jne r2, 0x0, jmp_16180

jmp_15ec8:
  ldxdw r5, [r10-0x80]
  mov64 r2, r5
  add64 r2, r1
  mov64 r1, 0x1
  mov64 r4, 0x1
  jlt r2, r5, jmp_15f00
  mov64 r4, 0x0

jmp_15f00:
  add64 r3, r4
  jeq r2, 0x0, jmp_15f18
  mov64 r1, 0x0

jmp_15f18:
  sub64 r3, r1
  add64 r2, -0x1
  mov64 r1, r10
  add64 r1, -0x60
  ldxdw r4, [r10-0x80]
  mov64 r5, 0x0
  call fn_2c2b0
  ldxdw r1, [r10-0x60]
  jlt r1, 0xffff, jmp_15f68
  mov64 r1, 0xffff

jmp_15f68:
  ldxdw r2, [r10-0x58]
  jeq r2, 0x0, jmp_15f80
  mov64 r1, 0xffff

jmp_15f80:
  ldxdw r2, [r10-0x68]
  ldxdw r3, [r10-0x80]
  stxdw [r2+0x0], r3
  ldxdw r3, [r10-0x90]
  stxw [r2+0x10], r3
  stxh [r2+0x16], r1
  stdw [r2+0x8], 0x0
  sth [r2+0x14], 0x1
  ldxdw r1, [r10-0x78]
  ldxdw r2, [r10-0x70]
  call fn_0788
  ja jmp_14e80

jmp_15fe0:
  mov64 r2, 0x0
  mov64 r5, 0x1
  mov64 r1, 0x1
  jsgt r7, 0x0, jmp_15d38

jmp_16000:
  mov64 r1, 0x0
  ldxdw r0, [r10-0x8]
  mov64 r4, r0
  sub64 r4, r7
  jsge r4, r0, jmp_15d58

jmp_16028:
  xor64 r1, r5
  jne r1, 0x0, jmp_15d70

jmp_16038:
  mov64 r5, 0xd
  ldxdw r1, [r10-0x68]
  ldxdw r0, [r10-0x70]
  jsle r4, r3, jmp_15db0

jmp_16058:
  stxw [r1+0x4], r5
  stxw [r1+0x0], r2
  ldxdw r5, [r10-0x78]
  ja jmp_15820

jmp_16078:
  ldxdw r0, [r10-0x8]
  mov64 r5, r0
  sub64 r5, r6
  jslt r5, r0, jmp_15cb0

jmp_16098:
  mov64 r4, 0x0
  xor64 r2, r4
  lddw r4, -0x8000000000000000
  jeq r2, 0x0, jmp_15cd0

jmp_160c0:
  ldxdw r2, [r10-0x68]
  jsgt r4, r3, jmp_15b70

jmp_160d0:
  mov64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x80]
  jeq r4, 0x0, jmp_161a8
  mov64 r3, 0x0
  ldxdw r4, [r10-0x70]
  jsge r4, 0x0, jmp_161b8

jmp_16108:
  ldxdw r4, [r10-0x70]
  jeq r4, 0x0, jmp_161d0

jmp_16118:
  mov64 r3, r2
  and64 r3, 0x1
  mov64 r8, 0x24
  ldxdw r2, [r10-0x68]
  jeq r3, 0x0, jmp_161f0
  ja jmp_15b70

jmp_16148:
  ldxdw r3, [r10-0x38]
  ldxdw r5, [r10-0x48]
  jgt r3, r5, jmp_15ea8

jmp_16160:
  mov64 r4, 0x0
  jne r3, r5, jmp_15eb0

jmp_16170:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_15ec8

jmp_16180:
  lddw r2, 0x1500000000
  ldxdw r1, [r10-0x68]
  stxdw [r1+0x0], r2
  ja jmp_15a40

jmp_161a8:
  ldxdw r4, [r10-0x70]
  jslt r4, 0x0, jmp_16108

jmp_161b8:
  mov64 r2, 0x0
  ldxdw r4, [r10-0x70]
  jne r4, 0x0, jmp_16118

jmp_161d0:
  and64 r3, 0x1
  mov64 r8, 0x24
  ldxdw r2, [r10-0x68]
  jne r3, 0x0, jmp_15b70

jmp_161f0:
  ldxdw r1, [r10-0x80]
  stxdw [r2+0x0], r1
  ldxdw r1, [r10-0x70]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x88]
  neg64 r1
  stxw [r2+0x10], r1
  sth [r2+0x14], 0x0
  mov64 r1, r7
  mov64 r2, r9
  call fn_0788
  ja jmp_14e80

jmp_16250:
  ldxdw r1, [r10-0x68]
  stw [r1+0x0], 0x3
  ja jmp_15a40

jmp_16268:
  mov64 r1, 0x8
  lddw r3, data_0ca0
  call fn_292e8

jmp_16288:
  mov64 r1, 0x10
  lddw r3, data_0cb8
  call fn_292e8

jmp_162a8:
  lddw r1, data_0810
  call fn_29a40

jmp_162c0:
  lddw r1, data_0828
  call fn_29938

jmp_162d8:
  mov64 r1, 0x10
  mov64 r2, 0x10
  lddw r3, data_0cd0
  call fn_28b70

fn_16300:
  ldxdw r6, [r5-0xfe8]
  ldxdw r0, [r5-0xff0]
  ldxdw r7, [r5-0xff8]
  ldxdw r5, [r5-0x1000]
  mov64 r9, r5
  and64 r9, 0xff
  jsgt r9, 0x2, jmp_163a8
  jeq r9, 0x0, jmp_16480
  stxdw [r10-0x10], r6
  stxdw [r10-0x8], r3
  mov64 r3, r4
  lddw r8, data_0120
  jeq r9, 0x1, jmp_163e0
  lddw r8, data_0140
  ldxdw r6, [r8+0x0]
  ldxdw r9, [r2+0x0]
  ldxdw r4, [r9+0x28]
  jeq r4, r6, jmp_16400
  ja jmp_164c0

jmp_163a8:
  stxdw [r10-0x8], r3
  add64 r9, -0x4
  stxdw [r10-0x10], r6
  mov64 r3, r4
  jge r9, 0x2, jmp_16490
  lddw r8, data_0160

jmp_163e0:
  ldxdw r6, [r8+0x0]
  ldxdw r9, [r2+0x0]
  ldxdw r4, [r9+0x28]
  jne r4, r6, jmp_164c0

jmp_16400:
  ldxdw r4, [r8+0x8]
  ldxdw r6, [r9+0x30]
  jne r6, r4, jmp_164c0
  ldxdw r4, [r8+0x10]
  ldxdw r6, [r9+0x38]
  jne r6, r4, jmp_164c0
  mov64 r6, 0x0
  ldxdw r4, [r8+0x18]
  ldxdw r8, [r9+0x40]
  jne r8, r4, jmp_164c0
  jeq r6, 0x0, jmp_164d0

jmp_16458:
  lddw r2, 0x2200000000
  stxdw [r1+0x0], r2
  sth [r1+0x14], 0x2
  ja jmp_16580

jmp_16480:
  mov64 r8, 0x258
  ja jmp_16520

jmp_16490:
  lddw r8, data_0080
  ldxdw r6, [r8+0x0]
  ldxdw r9, [r2+0x0]
  ldxdw r4, [r9+0x28]
  jeq r4, r6, jmp_16400

jmp_164c0:
  mov64 r6, 0x1
  jne r6, 0x0, jmp_16458

jmp_164d0:
  mov64 r4, r5
  and64 r4, 0xff
  lsh64 r4, 0x2
  lddw r6, data_04f0
  add64 r6, r4
  ldxw r8, [r6+0x0]
  mov64 r4, r3
  ldxdw r3, [r10-0x8]
  ldxdw r6, [r10-0x10]

jmp_16520:
  stxdw [r10-0xfe8], r6
  stxdw [r10-0xff8], r7
  stxdw [r10-0x1000], r5
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  jlt r8, r0, jmp_16568
  mov64 r8, r0

jmp_16568:
  stxdw [r10-0xff0], r8
  mov64 r5, r10
  call fn_14de0

jmp_16580:
  exit

fn_16588:
  stxdw [r10-0x2c0], r1
  jeq r3, 0x1, jmp_165b8
  jne r3, 0x0, jmp_165c8
  lddw r1, 0x2000000000
  ja jmp_18008

jmp_165b8:
  ldxb r1, [r2+0x18]
  jeq r1, 0x0, jmp_17f20

jmp_165c8:
  lsh64 r3, 0x5
  mov64 r1, r2
  add64 r1, r3
  stxdw [r10-0x2b0], r1
  lddw r9, 0xde0b6b3a7640000
  mov64 r7, 0x0
  mov64 r1, 0x0
  stxdw [r10-0x2a8], r1
  ja jmp_16648

jmp_16618:
  stxdw [r10-0x2b8], r3
  mov64 r1, 0x1
  stxdw [r10-0x2a8], r1

jmp_16630:
  add64 r2, 0x20
  ldxdw r1, [r10-0x2b0]
  jeq r2, r1, jmp_17f98

jmp_16648:
  ldxw r1, [r2+0x10]
  lsh64 r1, 0x20
  arsh64 r1, 0x20
  add64 r1, 0x12
  mov64 r8, r1
  lsh64 r8, 0x20
  arsh64 r8, 0x20
  jne r8, r1, jmp_17f08
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x268], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x270], r1
  stxdw [r10-0x2a0], r2
  stxdw [r10-0x278], r7
  jsle r8, -0x1, jmp_16c60
  mov64 r6, 0x1
  mov64 r7, 0x0
  jeq r8, 0x0, jmp_16a90
  mov64 r1, r8
  and64 r1, 0x1
  jeq r1, 0x0, jmp_16700
  mov64 r6, 0xa
  jeq r8, 0x1, jmp_16a90

jmp_16700:
  mov64 r1, r8
  and64 r1, 0x2
  jeq r1, 0x0, jmp_16778
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r6
  mov64 r3, r7
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r7, [r10-0x88]
  ldxdw r6, [r10-0x90]
  mov64 r1, r8
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_16a90

jmp_16778:
  mov64 r1, r8
  and64 r1, 0x4
  jeq r1, 0x0, jmp_167f0
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r6
  mov64 r3, r7
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r7, [r10-0x98]
  ldxdw r6, [r10-0xa0]
  mov64 r1, r8
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_16a90

jmp_167f0:
  mov64 r1, r8
  and64 r1, 0x8
  jeq r1, 0x0, jmp_16868
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r6
  mov64 r3, r7
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r7, [r10-0xa8]
  ldxdw r6, [r10-0xb0]
  mov64 r1, r8
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_16a90

jmp_16868:
  mov64 r1, r8
  and64 r1, 0x10
  jeq r1, 0x0, jmp_168e8
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, r6
  mov64 r3, r7
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r7, [r10-0xb8]
  ldxdw r6, [r10-0xc0]
  mov64 r1, r8
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_16a90

jmp_168e8:
  mov64 r1, r8
  and64 r1, 0x20
  jeq r1, 0x0, jmp_17f08
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r6
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r6
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r3, [r10-0xe8]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_17eb8
  ldxdw r0, [r10-0xf0]
  ldxdw r5, [r10-0xe0]
  mov64 r3, 0x1
  jeq r7, 0x0, jmp_17ee0

jmp_16a00:
  ldxdw r6, [r10-0xd8]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_16a20

jmp_16a18:
  mov64 r4, 0x0

jmp_16a20:
  add64 r5, r0
  ldxdw r0, [r10-0xc8]
  mov64 r7, r0
  add64 r7, r5
  jlt r7, r0, jmp_16a50
  mov64 r1, 0x0

jmp_16a50:
  and64 r8, 0x7fffffe0
  jne r8, 0x20, jmp_17f08
  or64 r3, r4
  or64 r3, r2
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_17f08
  ldxdw r6, [r10-0xd0]

jmp_16a90:
  mov64 r1, r10
  add64 r1, -0x110
  stxdw [r10-0x280], r7
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r7, [r10-0x270]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x120
  ldxdw r8, [r10-0x268]
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x108]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_16b70
  mov64 r1, 0x0

jmp_16b70:
  ldxdw r0, [r10-0x110]
  ldxdw r4, [r10-0x120]
  ldxdw r3, [r10-0x118]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_16ca0
  mov64 r5, 0x1
  mov64 r7, 0x1
  ldxdw r3, [r10-0x280]
  jeq r3, 0x0, jmp_16cc8

jmp_16bb8:
  mov64 r3, 0x1
  jne r8, 0x0, jmp_16bd0

jmp_16bc8:
  mov64 r3, 0x0

jmp_16bd0:
  add64 r4, r0
  ldxdw r0, [r10-0xf8]
  mov64 r6, r0
  add64 r6, r4
  jlt r6, r0, jmp_16c00
  mov64 r7, 0x0

jmp_16c00:
  and64 r3, r5
  or64 r3, r2
  or64 r3, r1
  or64 r3, r7
  and64 r3, 0x1
  jne r3, 0x0, jmp_17f08
  ldxdw r7, [r10-0x100]
  mov64 r1, r7
  or64 r1, r6
  ldxdw r2, [r10-0x2a0]
  jne r1, 0x0, jmp_17148
  ja jmp_17ff8

jmp_16c60:
  mov64 r7, r8
  neg64 r7
  mov64 r1, r7
  mov64 r5, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_16ce8
  mov64 r6, 0x1
  ja jmp_16cf8

jmp_16ca0:
  mov64 r2, 0x0
  mov64 r5, 0x1
  mov64 r7, 0x1
  ldxdw r3, [r10-0x280]
  jne r3, 0x0, jmp_16bb8

jmp_16cc8:
  mov64 r5, 0x0
  mov64 r3, 0x1
  jeq r8, 0x0, jmp_16bc8
  ja jmp_16bd0

jmp_16ce8:
  mov64 r6, 0xa
  jeq r8, -0x1, jmp_170e8

jmp_16cf8:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_16d78
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x64
  call fn_2c150
  mov64 r1, r7
  lddw r2, 0xfffffffe
  and64 r1, r2
  ldxdw r5, [r10-0x8]
  ldxdw r6, [r10-0x10]
  jeq r1, 0x2, jmp_170e8

jmp_16d78:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_16e00
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r7
  lddw r2, 0xfffffffc
  and64 r1, r2
  ldxdw r5, [r10-0x18]
  ldxdw r6, [r10-0x20]
  jeq r1, 0x4, jmp_170e8

jmp_16e00:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_16e88
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  mov64 r3, r5
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r7
  lddw r2, 0xfffffff8
  and64 r1, r2
  ldxdw r5, [r10-0x28]
  ldxdw r6, [r10-0x30]
  jeq r1, 0x8, jmp_170e8

jmp_16e88:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_16f18
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, r6
  mov64 r3, r5
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r7
  lddw r2, 0xfffffff0
  and64 r1, r2
  ldxdw r5, [r10-0x38]
  ldxdw r6, [r10-0x40]
  jeq r1, 0x10, jmp_170e8

jmp_16f18:
  mov64 r8, r5
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_17f08
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, r6
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r6
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r3, [r10-0x68]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_17e68
  ldxdw r0, [r10-0x70]
  ldxdw r5, [r10-0x60]
  mov64 r3, 0x1
  jeq r8, 0x0, jmp_17e90

jmp_17038:
  ldxdw r6, [r10-0x58]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_17058

jmp_17050:
  mov64 r4, 0x0

jmp_17058:
  add64 r5, r0
  ldxdw r0, [r10-0x48]
  mov64 r6, r0
  add64 r6, r5
  mov64 r8, r6
  jlt r6, r0, jmp_17090
  mov64 r1, 0x0

jmp_17090:
  lddw r5, 0xffffffe0
  and64 r7, r5
  jne r7, 0x20, jmp_17f08
  or64 r3, r4
  or64 r3, r2
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_17f08
  ldxdw r6, [r10-0x50]
  mov64 r5, r8

jmp_170e8:
  mov64 r1, r10
  add64 r1, -0x80
  ldxdw r2, [r10-0x270]
  ldxdw r3, [r10-0x268]
  mov64 r4, r6
  call fn_2c2b0
  ldxdw r6, [r10-0x78]
  ldxdw r7, [r10-0x80]
  mov64 r1, r7
  or64 r1, r6
  ldxdw r2, [r10-0x2a0]
  jeq r1, 0x0, jmp_17ff8

jmp_17148:
  stxdw [r10-0x280], r6
  ldxb r1, [r2+0x18]
  jeq r1, 0x0, jmp_17260
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r9
  mov64 r3, 0x0
  lddw r4, 0xde0b6b3a7640000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1d0
  ldxdw r2, [r10-0x278]
  mov64 r3, 0x0
  lddw r4, 0xde0b6b3a7640000
  mov64 r5, 0x0
  call fn_2c150
  jne r7, 0x0, jmp_176a8
  ldxdw r3, [r10-0x280]
  mov64 r1, r3
  neg64 r1
  mov64 r2, r3
  and64 r2, r1
  lddw r1, 0x218a392cd3d5dbf
  mul64 r2, r1
  rsh64 r2, 0x3a
  lddw r1, data_0000
  add64 r1, r2
  ldxb r9, [r1+0x0]
  add64 r9, 0x40
  ja jmp_17710

jmp_17260:
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r6, r7
  ldxdw r7, [r10-0x280]
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r6
  mov64 r3, 0x0
  ldxdw r6, [r10-0x278]
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r4, [r10-0x128]
  ldxdw r1, [r10-0x140]
  mov64 r5, r4
  add64 r5, r1
  ldxdw r1, [r10-0x150]
  mov64 r6, r5
  add64 r6, r1
  mov64 r1, 0x1
  mov64 r2, 0x1
  jlt r6, r5, jmp_173b0
  mov64 r2, 0x0

jmp_173b0:
  mov64 r3, 0x1
  jlt r5, r4, jmp_173c8
  mov64 r3, 0x0

jmp_173c8:
  ldxdw r4, [r10-0x160]
  ldxdw r5, [r10-0x138]
  mov64 r7, r5
  add64 r7, r4
  mov64 r4, 0x1
  jlt r7, r5, jmp_17400
  mov64 r4, 0x0

jmp_17400:
  ldxdw r5, [r10-0x148]
  mov64 r0, r7
  add64 r0, r5
  mov64 r5, 0x1
  jlt r0, r7, jmp_17430
  mov64 r5, 0x0

jmp_17430:
  add64 r3, r2
  mov64 r7, r0
  add64 r7, r3
  jlt r7, r0, jmp_17458
  mov64 r1, 0x0

jmp_17458:
  ldxdw r9, [r10-0x158]
  add64 r9, r4
  add64 r9, r5
  add64 r9, r1
  mov64 r1, r9
  lsh64 r1, 0x2e
  mov64 r8, r7
  rsh64 r8, 0x12
  or64 r8, r1
  mov64 r3, r9
  rsh64 r3, 0x12
  lddw r1, 0x3782dace9d9
  mod64 r3, r1
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r8
  lddw r4, 0x3782dace9d9
  mov64 r5, 0x0
  call fn_2c2b0
  lddw r1, 0xde0b6b3a763ffff
  jgt r9, r1, jmp_17f08
  ldxdw r2, [r10-0x170]
  jne r2, 0x0, jmp_17f08
  ldxdw r9, [r10-0x130]
  mov64 r1, r10
  add64 r1, -0x180
  lddw r4, 0x3782dace9d9
  mov64 r5, 0x0
  call fn_2c150
  lsh64 r7, 0x2e
  mov64 r1, r6
  rsh64 r1, 0x12
  or64 r7, r1
  ldxdw r1, [r10-0x180]
  sub64 r8, r1
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r7
  mov64 r3, r8
  lddw r4, 0x3782dace9d9
  mov64 r5, 0x0
  call fn_2c2b0
  mov64 r1, r10
  add64 r1, -0x1a0
  ldxdw r8, [r10-0x190]
  ldxdw r3, [r10-0x188]
  mov64 r2, r8
  lddw r4, 0x3782dace9d9
  mov64 r5, 0x0
  call fn_2c150
  rsh64 r9, 0x12
  lsh64 r6, 0x2e
  or64 r6, r9
  ldxdw r1, [r10-0x1a0]
  sub64 r7, r1
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r6
  mov64 r3, r7
  lddw r4, 0x3782dace9d9
  mov64 r5, 0x0
  call fn_2c2b0
  mov64 r7, r8
  ldxdw r1, [r10-0x1a8]
  or64 r7, r1
  ldxdw r9, [r10-0x1b0]
  ja jmp_17df8

jmp_176a8:
  mov64 r1, r7
  neg64 r1
  mov64 r2, r7
  and64 r2, r1
  lddw r1, 0x218a392cd3d5dbf
  mul64 r2, r1
  rsh64 r2, 0x3a
  lddw r1, data_0000
  add64 r1, r2
  ldxb r9, [r1+0x0]
  ldxdw r3, [r10-0x280]

jmp_17710:
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x290], r7
  mov64 r2, r7
  mov64 r4, r9
  call fn_2c4a0
  ldxdw r1, [r10-0x1d0]
  and64 r1, -0x40000
  ldxdw r2, [r10-0x1b8]
  mov64 r3, r2
  add64 r3, r1
  mov64 r8, 0x1
  mov64 r1, 0x1
  stxdw [r10-0x288], r3
  jlt r3, r2, jmp_17790
  mov64 r1, 0x0

jmp_17790:
  ldxdw r2, [r10-0x1c8]
  mov64 r0, r1
  add64 r0, r2
  jlt r0, r1, jmp_177b8
  mov64 r8, 0x0

jmp_177b8:
  ldxdw r4, [r10-0x1c0]
  mov64 r1, r4
  and64 r1, -0x40000
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x1d8]
  ldxdw r3, [r10-0x280]
  jeq r1, 0x0, jmp_17838
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r4, [r10-0x290]
  jlt r0, r4, jmp_179d0
  jlt r8, r3, jmp_179e0

jmp_17818:
  jne r8, r3, jmp_179f0

jmp_17820:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_17a08
  ja jmp_17f08

jmp_17838:
  stxdw [r10-0x268], r1
  ldxdw r6, [r10-0x1e0]
  mov64 r7, r9
  lsh64 r9, 0x20
  mov64 r1, r9
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_17970
  arsh64 r9, 0x20
  mov64 r1, r10
  add64 r1, -0x1f0
  ldxdw r2, [r10-0x298]
  ldxdw r3, [r10-0x288]
  mov64 r4, r9
  stxdw [r10-0x270], r6
  mov64 r6, r0
  call fn_2c4a0
  neg64 r7
  and64 r7, 0x7f
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r2, r6
  mov64 r3, r8
  mov64 r4, r7
  call fn_2c3f8
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r6
  ldxdw r6, [r10-0x270]
  mov64 r3, r8
  mov64 r4, r9
  call fn_2c4a0
  ldxdw r1, [r10-0x1e8]
  ldxdw r2, [r10-0x1f8]
  or64 r2, r1
  stxdw [r10-0x288], r2
  ldxdw r1, [r10-0x1f0]
  ldxdw r4, [r10-0x200]
  or64 r4, r1
  ldxdw r0, [r10-0x210]

jmp_17970:
  mov64 r1, r6
  ldxdw r9, [r10-0x268]
  or64 r1, r9
  jeq r1, 0x0, jmp_18028
  mov64 r2, 0x1
  mov64 r1, 0x1
  jle r6, r0, jmp_17ce0
  jeq r9, 0x0, jmp_17cf0

jmp_179b0:
  jne r9, 0x0, jmp_17d00

jmp_179b8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_17d18
  ja jmp_17f08

jmp_179d0:
  mov64 r1, 0x0
  jge r8, r3, jmp_17818

jmp_179e0:
  mov64 r2, 0x0
  jeq r8, r3, jmp_17820

jmp_179f0:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_17f08

jmp_17a08:
  mov64 r3, 0x0
  mov64 r6, 0x7f
  mov64 r4, 0x0
  stxdw [r10-0x268], r8
  ja jmp_17ac0

jmp_17a30:
  sub64 r8, r4
  sub64 r8, r2
  ldxdw r2, [r10-0x278]
  or64 r7, r2
  ldxdw r2, [r10-0x270]
  or64 r9, r2
  sub64 r1, r3
  add64 r6, -0x1
  mov64 r2, r6
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  mov64 r3, r9
  mov64 r4, r7
  mov64 r0, r1
  stxdw [r10-0x268], r8
  lddw r1, 0xffffffff
  jeq r2, r1, jmp_17df8

jmp_17ac0:
  stxdw [r10-0x278], r4
  stxdw [r10-0x270], r3
  mov64 r9, r6
  lsh64 r9, 0x20
  arsh64 r9, 0x20
  mov64 r1, r10
  add64 r1, -0x260
  ldxdw r2, [r10-0x298]
  ldxdw r3, [r10-0x288]
  mov64 r4, r9
  mov64 r7, r0
  call fn_2c4a0
  mov64 r1, r10
  add64 r1, -0x250
  mov64 r2, 0x1
  mov64 r3, 0x0
  mov64 r4, r9
  call fn_2c3f8
  mov64 r1, r7
  rsh64 r1, 0x3f
  lsh64 r8, 0x1
  or64 r8, r1
  mov64 r2, 0x1
  ldxdw r4, [r10-0x280]
  jge r8, r4, jmp_17b90
  mov64 r2, 0x0

jmp_17b90:
  ldxdw r1, [r10-0x260]
  and64 r1, 0x1
  lsh64 r7, 0x1
  or64 r1, r7
  mov64 r3, 0x1
  ldxdw r0, [r10-0x290]
  jlt r1, r0, jmp_17c20
  jne r8, r4, jmp_17c30

jmp_17bd0:
  mov64 r2, 0x1
  ldxdw r5, [r10-0x268]
  jsge r5, 0x0, jmp_17c50

jmp_17be8:
  or64 r2, r3
  jne r2, 0x0, jmp_17c68

jmp_17bf8:
  mov64 r9, 0x0
  jeq r2, 0x0, jmp_17c78

jmp_17c08:
  ldxdw r7, [r10-0x248]
  jeq r2, 0x0, jmp_17c88
  ja jmp_17c90

jmp_17c20:
  mov64 r3, 0x0
  jeq r8, r4, jmp_17bd0

jmp_17c30:
  mov64 r3, r2
  mov64 r2, 0x1
  ldxdw r5, [r10-0x268]
  jslt r5, 0x0, jmp_17be8

jmp_17c50:
  mov64 r2, 0x0
  or64 r2, r3
  jeq r2, 0x0, jmp_17bf8

jmp_17c68:
  ldxdw r9, [r10-0x250]
  jne r2, 0x0, jmp_17c08

jmp_17c78:
  mov64 r7, 0x0
  jne r2, 0x0, jmp_17c90

jmp_17c88:
  mov64 r4, 0x0

jmp_17c90:
  mov64 r3, r0
  jeq r2, 0x0, jmp_17cb8
  mov64 r2, 0x1
  jlt r1, r3, jmp_17a30
  ja jmp_17cd0

jmp_17cb8:
  mov64 r3, 0x0
  mov64 r2, 0x1
  jlt r1, r3, jmp_17a30

jmp_17cd0:
  mov64 r2, 0x0
  ja jmp_17a30

jmp_17ce0:
  mov64 r1, 0x0
  jne r9, 0x0, jmp_179b0

jmp_17cf0:
  mov64 r2, 0x0
  jeq r9, 0x0, jmp_179b8

jmp_17d00:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_17f08

jmp_17d18:
  mod64 r0, r6
  mov64 r1, r10
  add64 r1, -0x220
  ldxdw r8, [r10-0x288]
  mov64 r2, r8
  mov64 r3, r0
  stxdw [r10-0x270], r4
  mov64 r4, r6
  mov64 r5, r9
  call fn_2c2b0
  mov64 r1, r10
  add64 r1, -0x230
  ldxdw r7, [r10-0x220]
  ldxdw r3, [r10-0x218]
  mov64 r2, r7
  mov64 r4, r6
  mov64 r5, r9
  call fn_2c150
  ldxdw r1, [r10-0x230]
  sub64 r8, r1
  mov64 r1, r10
  add64 r1, -0x240
  ldxdw r2, [r10-0x270]
  mov64 r3, r8
  mov64 r4, r6
  mov64 r5, r9
  call fn_2c2b0
  ldxdw r9, [r10-0x240]

jmp_17df8:
  ldxdw r2, [r10-0x2a0]
  ldxh r1, [r2+0x14]
  jeq r1, 0x0, jmp_16630
  ldxh r1, [r2+0x16]
  ldxdw r3, [r10-0x2b8]
  and64 r3, 0xffff
  add64 r3, r1
  jlt r3, 0xffff, jmp_17e40
  mov64 r3, 0xffff

jmp_17e40:
  ldxdw r4, [r10-0x2a8]
  and64 r4, 0x1
  jne r4, 0x0, jmp_16618
  mov64 r3, r1
  ja jmp_16618

jmp_17e68:
  mov64 r2, 0x0
  ldxdw r0, [r10-0x70]
  ldxdw r5, [r10-0x60]
  mov64 r3, 0x1
  jne r8, 0x0, jmp_17038

jmp_17e90:
  mov64 r3, 0x0
  ldxdw r6, [r10-0x58]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_17050
  ja jmp_17058

jmp_17eb8:
  mov64 r2, 0x0
  ldxdw r0, [r10-0xf0]
  ldxdw r5, [r10-0xe0]
  mov64 r3, 0x1
  jne r7, 0x0, jmp_16a00

jmp_17ee0:
  mov64 r3, 0x0
  ldxdw r6, [r10-0xd8]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_16a18
  ja jmp_16a20

jmp_17f08:
  lddw r1, 0x2300000000
  ja jmp_18008

jmp_17f20:
  ldxdw r6, [r2+0x8]
  ldxdw r1, [r2+0x0]
  mov64 r3, r1
  or64 r3, r6
  jeq r3, 0x0, jmp_17ff8
  ldxw r3, [r2+0x10]
  ldxh r4, [r2+0x14]
  ldxh r5, [r2+0x16]
  ldxdw r0, [r10-0x2c0]
  stxdw [r0+0x8], r6
  stxdw [r0+0x0], r1
  stxh [r0+0x16], r5
  stxh [r0+0x14], r4
  stxw [r0+0x10], r3
  ja jmp_18020

jmp_17f98:
  mov64 r1, r9
  or64 r1, r7
  jeq r1, 0x0, jmp_17ff8
  ldxdw r1, [r10-0x2c0]
  stxdw [r1+0x0], r9
  ldxdw r2, [r10-0x2b8]
  stxh [r1+0x16], r2
  ldxdw r2, [r10-0x2a8]
  stxh [r1+0x14], r2
  stxdw [r1+0x8], r7
  stw [r1+0x10], -0x12
  ja jmp_18020

jmp_17ff8:
  lddw r1, 0x2400000000

jmp_18008:
  ldxdw r2, [r10-0x2c0]
  stxdw [r2+0x0], r1
  sth [r2+0x14], 0x2

jmp_18020:
  exit

jmp_18028:
  lddw r1, data_0c88
  call fn_29a98

fn_18040:
  mov64 r6, r1
  ldxdw r1, [r2+0x0]
  ldxdw r1, [r1+0x50]
  jne r1, 0x4b, jmp_181b8
  mov64 r9, r3
  mov64 r8, r4
  ldxdw r7, [r5-0xff8]
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0x38], r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxw r2, [r10-0x24]
  ldxw r3, [r10-0x28]
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_181d8
  lsh64 r2, 0x20
  or64 r2, r3
  jle r2, 0x7, jmp_186f8
  stxdw [r10-0x48], r7
  ldxb r5, [r10-0x18]
  ldxdw r7, [r10-0x20]
  ldxdw r3, [r1+0x0]
  lddw r4, 0x5d7bf9fb56bbbd19
  jne r3, r4, jmp_181f8
  stxdw [r10-0x40], r5
  jle r2, 0x27, jmp_18718
  ldxdw r4, [r9+0x0]
  ldxdw r5, [r1+0x8]
  jne r5, r4, jmp_18188
  ldxdw r4, [r9+0x8]
  ldxdw r5, [r1+0x10]
  jne r5, r4, jmp_18188
  ldxdw r4, [r9+0x10]
  ldxdw r5, [r1+0x18]
  jne r5, r4, jmp_18188
  mov64 r4, 0x0
  ldxdw r5, [r9+0x18]
  ldxdw r0, [r1+0x20]
  jeq r0, r5, jmp_18190

jmp_18188:
  mov64 r4, 0x1

jmp_18190:
  ldxdw r5, [r10-0x40]
  jeq r4, 0x0, jmp_18270
  lddw r1, 0x1b00000000
  ja jmp_18208

jmp_181b8:
  lddw r1, 0xa00000000
  stxdw [r6+0x0], r1
  ja jmp_181e8

jmp_181d8:
  stxw [r6+0x4], r2
  stxw [r6+0x0], r3

jmp_181e8:
  sth [r6+0x14], 0x2
  ja jmp_18268

jmp_181f8:
  lddw r1, 0x1d00000000

jmp_18208:
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  mov64 r2, r5
  jgt r2, 0x7, jmp_18428

jmp_18228:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r7+0x0]
  jlt r2, r3, jmp_187d8
  sub64 r2, r1
  stxb [r7+0x0], r2

jmp_18268:
  exit

jmp_18270:
  jle r2, 0x37, jmp_18738
  jle r2, 0x3b, jmp_18758
  jle r2, 0x3d, jmp_18778
  jle r2, 0x41, jmp_18798
  jle r2, 0x49, jmp_187b8
  ldxw r9, [r1+0x38]
  mov64 r2, r9
  and64 r8, 0xff
  neg64 r8
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  jne r2, r8, jmp_18358
  ldxdw r2, [r1+0x30]
  stxdw [r10-0x60], r2
  ldxdw r2, [r1+0x28]
  stxdw [r10-0x58], r2
  ldxh r2, [r1+0x3c]
  stxdw [r10-0x68], r2
  ldxw r2, [r1+0x3e]
  stxdw [r10-0x50], r2
  ldxdw r8, [r1+0x42]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_18370
  ldxw r3, [r10-0x28]
  ldxw r2, [r10-0x2c]
  ja jmp_183f8

jmp_18358:
  lddw r1, 0x2a00000000
  ja jmp_18208

jmp_18370:
  ldxdw r0, [r10-0x38]
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r1, 0x190
  jeq r0, 0x0, jmp_183a8
  mov64 r1, r0
  mul64 r1, 0x5

jmp_183a8:
  ldxdw r4, [r10-0x28]
  mov64 r3, r4
  sub64 r3, r8
  mov64 r2, 0x0
  mov64 r5, 0x1
  jle r3, r4, jmp_18440
  mov64 r4, 0x0
  jeq r5, 0x0, jmp_18458

jmp_183e8:
  mov64 r3, 0xd
  jle r4, r1, jmp_18470

jmp_183f8:
  stxw [r6+0x4], r3
  stxw [r6+0x0], r2

jmp_18408:
  sth [r6+0x14], 0x2
  ldxdw r5, [r10-0x40]
  mov64 r2, r5
  jle r2, 0x7, jmp_18228

jmp_18428:
  lddw r1, data_0810
  call fn_29a40

jmp_18440:
  mov64 r5, 0x0
  mov64 r4, 0x0
  jne r5, 0x0, jmp_183e8

jmp_18458:
  mov64 r4, r3
  mov64 r3, 0xd
  jgt r4, r1, jmp_183f8

jmp_18470:
  mov64 r8, r0
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_184b8
  ldxw r3, [r10-0x28]
  ldxw r1, [r10-0x2c]
  ja jmp_18570

jmp_184b8:
  ldxdw r1, [r10-0x38]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r2, 0x50
  jeq r1, 0x0, jmp_184e8
  mov64 r2, r8

jmp_184e8:
  mov64 r1, 0x0
  mov64 r4, 0x1
  mov64 r3, 0x1
  ldxdw r5, [r10-0x50]
  jsgt r5, 0x0, jmp_18518
  mov64 r3, 0x0

jmp_18518:
  ldxdw r0, [r10-0x8]
  mov64 r5, r0
  ldxdw r8, [r10-0x50]
  sub64 r5, r8
  jsge r5, r0, jmp_18588
  xor64 r3, r4
  lddw r4, -0x8000000000000000
  jeq r3, 0x0, jmp_185b0

jmp_18560:
  mov64 r3, 0xd
  jsle r4, r2, jmp_185c8

jmp_18570:
  stxw [r6+0x4], r3
  stxw [r6+0x0], r1
  ja jmp_18408

jmp_18588:
  mov64 r4, 0x0
  xor64 r3, r4
  lddw r4, -0x8000000000000000
  jne r3, 0x0, jmp_18560

jmp_185b0:
  mov64 r4, r5
  mov64 r3, 0xd
  jsgt r4, r2, jmp_18570

jmp_185c8:
  ldxdw r1, [r10-0x58]
  ldxdw r4, [r10-0x60]
  or64 r1, r4
  ldxdw r5, [r10-0x40]
  jeq r1, 0x0, jmp_18658
  ldxdw r2, [r10-0x48]
  and64 r2, 0xffff
  mov64 r1, r2
  mov64 r3, r2
  jge r2, 0x3e8, jmp_18670
  mov64 r2, 0xc8
  jne r3, 0x0, jmp_18688

jmp_18628:
  ldxdw r3, [r10-0x68]
  mov64 r1, r3
  jle r1, r2, jmp_186a8

jmp_18640:
  lddw r1, 0x1500000000
  ja jmp_18208

jmp_18658:
  lddw r1, 0x2400000000
  ja jmp_18208

jmp_18670:
  mov64 r1, 0x3e8
  mov64 r2, 0xc8
  jeq r3, 0x0, jmp_18628

jmp_18688:
  mov64 r2, r1
  ldxdw r3, [r10-0x68]
  mov64 r1, r3
  jgt r1, r2, jmp_18640

jmp_186a8:
  ldxdw r1, [r10-0x58]
  stxdw [r6+0x0], r1
  stxh [r6+0x16], r3
  stxw [r6+0x10], r9
  stxdw [r6+0x8], r4
  sth [r6+0x14], 0x1
  mov64 r1, r7
  mov64 r2, r5
  call fn_0788
  ja jmp_18268

jmp_186f8:
  mov64 r1, 0x8
  lddw r3, data_0ce8
  call fn_292e8

jmp_18718:
  mov64 r1, 0x28
  lddw r3, data_0d00
  call fn_292e8

jmp_18738:
  mov64 r1, 0x38
  lddw r3, data_0d18
  call fn_292e8

jmp_18758:
  mov64 r1, 0x3c
  lddw r3, data_0d30
  call fn_292e8

jmp_18778:
  mov64 r1, 0x3e
  lddw r3, data_0d48
  call fn_292e8

jmp_18798:
  mov64 r1, 0x42
  lddw r3, data_0d60
  call fn_292e8

jmp_187b8:
  mov64 r1, 0x4a
  lddw r3, data_0d78
  call fn_292e8

jmp_187d8:
  lddw r1, data_0828
  call fn_29938

fn_187f0:
  mov64 r6, r1
  ldxdw r1, [r2+0x0]
  ldxdw r1, [r1+0x50]
  jne r1, 0x4b, jmp_18950
  mov64 r9, r3
  mov64 r8, r4
  stxdw [r10-0x38], r5
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28528
  ldxw r2, [r10-0x24]
  ldxw r3, [r10-0x28]
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_18978
  lsh64 r2, 0x20
  or64 r2, r3
  jle r2, 0x7, jmp_18dd8
  ldxb r5, [r10-0x18]
  ldxdw r7, [r10-0x20]
  ldxdw r3, [r1+0x0]
  lddw r4, 0x5d7bf9fb56bbbd19
  jne r3, r4, jmp_18998
  stxdw [r10-0x40], r5
  jle r2, 0x27, jmp_18df8
  ldxdw r4, [r9+0x0]
  ldxdw r5, [r1+0x8]
  jne r5, r4, jmp_18920
  ldxdw r4, [r9+0x8]
  ldxdw r5, [r1+0x10]
  jne r5, r4, jmp_18920
  ldxdw r4, [r9+0x10]
  ldxdw r5, [r1+0x18]
  jne r5, r4, jmp_18920
  mov64 r4, 0x0
  ldxdw r5, [r9+0x18]
  ldxdw r0, [r1+0x20]
  jeq r0, r5, jmp_18928

jmp_18920:
  mov64 r4, 0x1

jmp_18928:
  ldxdw r5, [r10-0x40]
  jeq r4, 0x0, jmp_18a10
  lddw r1, 0x1b00000000
  ja jmp_189a8

jmp_18950:
  lddw r1, 0xa00000000
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_18a08

jmp_18978:
  stxw [r6+0x4], r2
  stxw [r6+0x0], r3
  sth [r6+0x14], 0x2
  ja jmp_18a08

jmp_18998:
  lddw r1, 0x1d00000000

jmp_189a8:
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  mov64 r2, r5
  jgt r2, 0x7, jmp_18bb0

jmp_189c8:
  mov64 r1, 0x1
  lsh64 r1, r2
  mov64 r3, r1
  and64 r3, 0xff
  ldxb r2, [r7+0x0]
  jlt r2, r3, jmp_18e98
  sub64 r2, r1
  stxb [r7+0x0], r2

jmp_18a08:
  exit

jmp_18a10:
  jle r2, 0x37, jmp_18e18
  jle r2, 0x3b, jmp_18e38
  jle r2, 0x41, jmp_18e58
  jle r2, 0x49, jmp_18e78
  ldxw r9, [r1+0x38]
  mov64 r2, r9
  and64 r8, 0xff
  neg64 r8
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  jne r2, r8, jmp_18ae0
  ldxdw r2, [r1+0x30]
  stxdw [r10-0x50], r2
  ldxdw r2, [r1+0x28]
  stxdw [r10-0x58], r2
  ldxw r2, [r1+0x3e]
  stxdw [r10-0x48], r2
  ldxdw r8, [r1+0x42]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_18af8
  ldxw r3, [r10-0x28]
  ldxw r2, [r10-0x2c]
  ja jmp_18b80

jmp_18ae0:
  lddw r1, 0x2a00000000
  ja jmp_189a8

jmp_18af8:
  ldxdw r0, [r10-0x38]
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r1, 0x190
  jeq r0, 0x0, jmp_18b30
  mov64 r1, r0
  mul64 r1, 0x5

jmp_18b30:
  ldxdw r4, [r10-0x28]
  mov64 r3, r4
  sub64 r3, r8
  mov64 r2, 0x0
  mov64 r5, 0x1
  jle r3, r4, jmp_18bc8
  mov64 r4, 0x0
  jeq r5, 0x0, jmp_18be0

jmp_18b70:
  mov64 r3, 0xd
  jle r4, r1, jmp_18bf8

jmp_18b80:
  stxw [r6+0x4], r3
  stxw [r6+0x0], r2

jmp_18b90:
  sth [r6+0x14], 0x2
  ldxdw r5, [r10-0x40]
  mov64 r2, r5
  jle r2, 0x7, jmp_189c8

jmp_18bb0:
  lddw r1, data_0810
  call fn_29a40

jmp_18bc8:
  mov64 r5, 0x0
  mov64 r4, 0x0
  jne r5, 0x0, jmp_18b70

jmp_18be0:
  mov64 r4, r3
  mov64 r3, 0xd
  jgt r4, r1, jmp_18b80

jmp_18bf8:
  mov64 r8, r0
  mov64 r1, r10
  add64 r1, -0x30
  call fn_287f0
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_18c40
  ldxw r3, [r10-0x28]
  ldxw r1, [r10-0x2c]
  ja jmp_18cf8

jmp_18c40:
  ldxdw r1, [r10-0x38]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r2, 0x50
  jeq r1, 0x0, jmp_18c70
  mov64 r2, r8

jmp_18c70:
  mov64 r1, 0x0
  mov64 r4, 0x1
  mov64 r3, 0x1
  ldxdw r5, [r10-0x48]
  jsgt r5, 0x0, jmp_18ca0
  mov64 r3, 0x0

jmp_18ca0:
  ldxdw r0, [r10-0x8]
  mov64 r5, r0
  ldxdw r8, [r10-0x48]
  sub64 r5, r8
  jsge r5, r0, jmp_18d10
  xor64 r3, r4
  lddw r4, -0x8000000000000000
  jeq r3, 0x0, jmp_18d38

jmp_18ce8:
  mov64 r3, 0xd
  jsle r4, r2, jmp_18d50

jmp_18cf8:
  stxw [r6+0x4], r3
  stxw [r6+0x0], r1
  ja jmp_18b90

jmp_18d10:
  mov64 r4, 0x0
  xor64 r3, r4
  lddw r4, -0x8000000000000000
  jne r3, 0x0, jmp_18ce8

jmp_18d38:
  mov64 r4, r5
  mov64 r3, 0xd
  jsgt r4, r2, jmp_18cf8

jmp_18d50:
  ldxdw r3, [r10-0x58]
  mov64 r1, r3
  ldxdw r2, [r10-0x50]
  or64 r1, r2
  ldxdw r5, [r10-0x40]
  jeq r1, 0x0, jmp_18dc0
  stxdw [r6+0x0], r3
  stxw [r6+0x10], r9
  stxdw [r6+0x8], r2
  sth [r6+0x14], 0x0
  mov64 r1, r7
  mov64 r2, r5
  call fn_0788
  ja jmp_18a08

jmp_18dc0:
  lddw r1, 0x2400000000
  ja jmp_189a8

jmp_18dd8:
  mov64 r1, 0x8
  lddw r3, data_0d90
  call fn_292e8

jmp_18df8:
  mov64 r1, 0x28
  lddw r3, data_0da8
  call fn_292e8

jmp_18e18:
  mov64 r1, 0x38
  lddw r3, data_0dc0
  call fn_292e8

jmp_18e38:
  mov64 r1, 0x3c
  lddw r3, data_0dd8
  call fn_292e8

jmp_18e58:
  mov64 r1, 0x42
  lddw r3, data_0df0
  call fn_292e8

jmp_18e78:
  mov64 r1, 0x4a
  lddw r3, data_0e08
  call fn_292e8

jmp_18e98:
  lddw r1, data_0828
  call fn_29938

fn_18eb0:
  mov64 r6, r4
  mov64 r9, r3
  mov64 r7, r2
  mov64 r3, 0x20
  mov64 r2, r6
  add64 r2, -0x4
  jlt r2, -0x3, jmp_19638
  stxdw [r10-0xe0], r1
  stxdw [r10-0xf0], r5
  mov64 r1, r7
  add64 r1, 0x26
  mov64 r2, 0x0
  mov64 r3, 0xdd
  call fn_2a0b0
  mov64 r1, r10
  add64 r1, -0x40
  stxdw [r10-0xd0], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0xc8], r1
  add64 r9, 0x48
  stxdw [r10-0xf8], r6
  mov64 r2, r6
  mul64 r2, 0x4c
  mov64 r1, r7
  add64 r1, 0x28
  stxdw [r10-0xe8], r1
  mov64 r3, 0x0
  mov64 r6, r7
  stxdw [r10-0xc0], r6
  ja jmp_19000

jmp_18fc0:
  ldxdw r6, [r10-0xc0]
  ldxdw r2, [r10-0xb0]
  ldxdw r3, [r10-0x90]
  jne r7, 0x0, jmp_19610

jmp_18fe0:
  add64 r3, 0x49
  add64 r9, 0x4c
  add64 r2, -0x4c
  jeq r2, 0x0, jmp_193b8

jmp_19000:
  ldxb r8, [r9-0x2]
  jgt r8, 0x5, jmp_19610
  stxdw [r10-0xb0], r2
  mov64 r1, r9
  add64 r1, -0x48
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x70], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x78], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x80], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x88], r1
  ldxdw r1, [r9-0x10]
  ldxdw r2, [r10-0xc8]
  stxdw [r2+0x18], r1
  ldxdw r1, [r9-0x18]
  stxdw [r2+0x10], r1
  ldxdw r1, [r9-0x20]
  stxdw [r2+0x8], r1
  ldxdw r1, [r9-0x28]
  stxdw [r2+0x0], r1
  stxdw [r10-0x90], r3
  add64 r6, r3
  ldxb r7, [r9-0x1]
  ldxw r1, [r9-0x8]
  stxdw [r10-0x98], r1
  ldxb r1, [r9+0x0]
  stxdw [r10-0xa0], r1
  ldxh r1, [r9-0x4]
  stxdw [r10-0xa8], r1
  mov64 r1, r6
  add64 r1, 0x28
  mov64 r2, r10
  add64 r2, -0x88
  stxdw [r10-0xb8], r1
  mov64 r3, 0x40
  call fn_2a090
  ldxdw r1, [r10-0xa8]
  stxh [r6+0x6e], r1
  stxb [r6+0x6d], r8
  ldxdw r1, [r10-0xa0]
  stxb [r6+0x6c], r1
  ldxdw r1, [r10-0x98]
  stxw [r6+0x68], r1
  stxb [r6+0x70], r7
  jeq r8, 0x5, jmp_191b0
  jne r8, 0x4, jmp_18fc0
  mov64 r1, 0x3
  ldxdw r6, [r10-0xc0]
  ldxdw r3, [r10-0x90]
  jeq r7, 0x8, jmp_191e0
  jeq r7, 0x12, jmp_191e0
  ja jmp_19610

jmp_191b0:
  mov64 r1, 0x7
  add64 r7, -0x13
  and64 r7, 0xff
  ldxdw r6, [r10-0xc0]
  ldxdw r3, [r10-0x90]
  jlt r7, 0xee, jmp_19610

jmp_191e0:
  mov64 r2, r6
  add64 r2, r3
  ldxb r3, [r2+0x48]
  jne r3, 0x0, jmp_19628
  ldxb r3, [r2+0x49]
  jne r3, r1, jmp_19628
  add64 r2, 0x48
  stxdw [r10-0x68], r2
  stxdw [r10-0x78], r6
  lddw r1, str_0459
  stxdw [r10-0x88], r1
  stdw [r10-0x60], 0x20
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x6
  stb [r10-0x1], 0xff
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x21
  mov64 r5, r10
  add64 r5, -0x1
  mov64 r2, 0x3
  lddw r3, data_0160
  call sol_try_find_program_address
  jne r0, 0x0, jmp_193a8
  ldxb r1, [r10-0x21]
  ldxdw r4, [r10-0xd8]
  ldxdw r2, [r4+0x17]
  ldxdw r3, [r10-0xd0]
  stxdw [r3+0x17], r2
  ldxdw r2, [r4+0x10]
  stxdw [r3+0x10], r2
  ldxdw r2, [r4+0x8]
  stxdw [r3+0x8], r2
  ldxdw r2, [r4+0x0]
  stxdw [r3+0x0], r2
  stxb [r10-0x41], r1
  ldxdw r3, [r10-0xb8]
  ldxdw r1, [r3+0x0]
  ldxdw r2, [r10-0x41]
  jne r1, r2, jmp_19388
  ldxdw r1, [r3+0x8]
  ldxdw r2, [r10-0x39]
  jne r1, r2, jmp_19388
  ldxdw r1, [r3+0x10]
  ldxdw r2, [r10-0x31]
  jne r1, r2, jmp_19388
  mov64 r1, 0x0
  ldxdw r2, [r3+0x18]
  ldxdw r3, [r10-0x29]
  jeq r2, r3, jmp_19390

jmp_19388:
  mov64 r1, 0x1

jmp_19390:
  ldxdw r2, [r10-0xb0]
  ldxdw r3, [r10-0x90]
  jeq r1, 0x0, jmp_18fe0

jmp_193a8:
  mov64 r3, 0xe
  ja jmp_19630

jmp_193b8:
  ldxdw r2, [r10-0xf0]
  ldxdw r9, [r10-0xf8]
  jeq r9, 0x0, jmp_19658
  mov64 r3, 0x0
  mov64 r5, 0x1
  ldxdw r4, [r10-0xc0]
  add64 r4, 0x71
  ja jmp_19418

jmp_193f8:
  add64 r4, 0x49
  mov64 r5, r3
  add64 r5, r1
  jge r3, r9, jmp_19658

jmp_19418:
  mov64 r1, r3
  mov64 r3, r5
  mov64 r5, r1
  add64 r5, 0x1
  jge r5, r9, jmp_195f0
  jgt r1, 0x2, jmp_19688
  mul64 r1, 0x49
  ldxdw r0, [r10-0xe8]
  add64 r0, r1
  mov64 r1, r4
  ja jmp_194a0

jmp_19470:
  xor64 r6, r7
  and64 r6, 0x1
  jne r6, 0x0, jmp_19610

jmp_19488:
  add64 r1, 0x49
  add64 r5, 0x1
  jge r5, r9, jmp_195f0

jmp_194a0:
  ldxdw r6, [r1+0x0]
  ldxdw r7, [r0+0x0]
  jne r7, r6, jmp_19508
  ldxdw r6, [r1+0x8]
  ldxdw r7, [r0+0x8]
  jne r7, r6, jmp_19508
  ldxdw r6, [r1+0x10]
  ldxdw r7, [r0+0x10]
  jne r7, r6, jmp_19508
  mov64 r6, 0x0
  ldxdw r7, [r1+0x18]
  ldxdw r8, [r0+0x18]
  jeq r8, r7, jmp_19510

jmp_19508:
  mov64 r6, 0x1

jmp_19510:
  jeq r6, 0x0, jmp_19590
  ldxdw r6, [r1+0x20]
  ldxdw r7, [r0+0x20]
  jne r7, r6, jmp_19580
  ldxdw r6, [r1+0x28]
  ldxdw r7, [r0+0x28]
  jne r7, r6, jmp_19580
  ldxdw r6, [r1+0x30]
  ldxdw r7, [r0+0x30]
  jne r7, r6, jmp_19580
  mov64 r6, 0x0
  ldxdw r7, [r1+0x38]
  ldxdw r8, [r0+0x38]
  jeq r8, r7, jmp_19588

jmp_19580:
  mov64 r6, 0x1

jmp_19588:
  jne r6, 0x0, jmp_19488

jmp_19590:
  ldxb r8, [r1+0x44]
  mov64 r6, 0x1
  mov64 r7, 0x1
  jeq r8, 0x1, jmp_195d0
  mov64 r7, 0x0
  ldxb r8, [r0+0x44]
  jeq r8, 0x1, jmp_19470
  ja jmp_195e0

jmp_195d0:
  ldxb r8, [r0+0x44]
  jeq r8, 0x1, jmp_19470

jmp_195e0:
  mov64 r6, 0x0
  ja jmp_19470

jmp_195f0:
  mov64 r1, 0x1
  jlt r3, r9, jmp_193f8
  mov64 r1, 0x0
  ja jmp_193f8

jmp_19610:
  ldxdw r1, [r10-0xe0]
  mov64 r3, 0x20
  ja jmp_19638

jmp_19628:
  mov64 r3, 0x1b

jmp_19630:
  ldxdw r1, [r10-0xe0]

jmp_19638:
  mov64 r2, 0x0

jmp_19640:
  stxw [r1+0x4], r3
  stxw [r1+0x0], r2
  exit

jmp_19658:
  ldxdw r1, [r10-0xc0]
  stxh [r1+0x24], r2
  stxb [r1+0x22], r9
  mov64 r2, 0x1a
  ldxdw r1, [r10-0xe0]
  ja jmp_19640

jmp_19688:
  mov64 r2, 0x3
  lddw r3, data_0e68
  call fn_28b70

fn_196a8:
  ldxb r0, [r2+0x27]
  jne r0, 0x0, jmp_196f0
  ldxb r0, [r2+0x26]
  jgt r0, 0x1, jmp_196f0
  ldxb r0, [r2+0x22]
  stxdw [r10-0xb0], r0
  add64 r0, -0x4
  and64 r0, 0xff
  jge r0, 0xfd, jmp_19718

jmp_196f0:
  lddw r2, 0x2000000000

jmp_19700:
  stxdw [r1+0x0], r2

jmp_19708:
  sth [r1+0x14], 0x2

jmp_19710:
  exit

jmp_19718:
  ldxdw r0, [r10-0xb0]
  mul64 r0, 0x49
  and64 r0, 0xff
  jne r0, 0xdb, jmp_197b8

jmp_19738:
  mov64 r9, 0x0
  ldxb r6, [r2+0x6c]
  jgt r6, 0x1, jmp_19948
  ldxb r0, [r2+0x6d]
  jgt r0, 0x5, jmp_19948
  stxdw [r10-0xc0], r6
  mov64 r8, 0x20
  ldxb r7, [r2+0x70]
  stxdw [r10-0xb8], r7
  jeq r0, 0x5, jmp_19968
  jne r0, 0x4, jmp_199c8
  mov64 r6, 0x3
  stxdw [r10-0xc8], r6
  jeq r7, 0x8, jmp_19990
  jeq r7, 0x12, jmp_19990
  ja jmp_19950

jmp_197b8:
  mov64 r6, 0xdb
  mov64 r8, r2

jmp_197c8:
  mov64 r9, r8
  add64 r9, r0
  ldxdw r7, [r9+0x28]
  jne r7, 0x0, jmp_19818
  ldxdw r7, [r9+0x30]
  jne r7, 0x0, jmp_19818
  ldxdw r7, [r9+0x38]
  jne r7, 0x0, jmp_19818
  ldxdw r7, [r9+0x40]
  jeq r7, 0x0, jmp_19918

jmp_19818:
  mov64 r9, 0x1
  jne r9, 0x0, jmp_196f0

jmp_19828:
  mov64 r9, r8
  add64 r9, r0
  ldxdw r7, [r9+0x48]
  jne r7, 0x0, jmp_19878
  ldxdw r7, [r9+0x50]
  jne r7, 0x0, jmp_19878
  ldxdw r7, [r9+0x58]
  jne r7, 0x0, jmp_19878
  ldxdw r7, [r9+0x60]
  jeq r7, 0x0, jmp_19930

jmp_19878:
  mov64 r9, 0x1
  jne r9, 0x0, jmp_196f0

jmp_19888:
  mov64 r9, r8
  add64 r9, r0
  ldxw r7, [r9+0x68]
  jne r7, 0x0, jmp_196f0
  ldxb r7, [r9+0x6c]
  jne r7, 0x0, jmp_196f0
  ldxb r7, [r9+0x6d]
  jne r7, 0x0, jmp_196f0
  ldxh r7, [r9+0x6e]
  jne r7, 0x0, jmp_196f0
  mov64 r7, r8
  add64 r7, r0
  ldxb r7, [r7+0x70]
  jne r7, 0x0, jmp_196f0
  add64 r8, 0x49
  add64 r6, -0x49
  jne r0, r6, jmp_197c8
  ja jmp_19738

jmp_19918:
  mov64 r9, 0x0
  jeq r9, 0x0, jmp_19828
  ja jmp_196f0

jmp_19930:
  mov64 r9, 0x0
  jeq r9, 0x0, jmp_19888
  ja jmp_196f0

jmp_19948:
  mov64 r8, 0x20

jmp_19950:
  stxw [r1+0x4], r8
  stxw [r1+0x0], r9
  ja jmp_19708

jmp_19968:
  mov64 r6, 0x7
  stxdw [r10-0xc8], r6
  add64 r7, -0x13
  and64 r7, 0xff
  jlt r7, 0xee, jmp_19950

jmp_19990:
  mov64 r8, 0x1b
  ldxb r7, [r2+0x48]
  jne r7, 0x0, jmp_19950
  ldxb r7, [r2+0x49]
  ldxdw r6, [r10-0xc8]
  jeq r7, r6, jmp_199d0
  ja jmp_19950

jmp_199c8:
  jne r7, 0x0, jmp_19950

jmp_199d0:
  ldxh r7, [r2+0x6e]
  ldxw r9, [r2+0x68]
  stxdw [r10-0xd0], r7
  jsgt r0, 0x2, jmp_19a30
  jeq r0, 0x0, jmp_19a68
  stxdw [r10-0xd8], r9
  lddw r7, data_0120
  jeq r0, 0x1, jmp_19a90
  lddw r7, data_0140
  ja jmp_19a90

jmp_19a30:
  mov64 r7, r0
  add64 r7, -0x4
  stxdw [r10-0xd8], r9
  jge r7, 0x2, jmp_19a80
  lddw r7, data_0160
  ja jmp_19a90

jmp_19a68:
  mov64 r8, 0x258
  ldxdw r7, [r10-0xb8]
  ja jmp_19b88

jmp_19a80:
  lddw r7, data_0080

jmp_19a90:
  stxdw [r10-0xc8], r7
  ldxdw r7, [r7+0x0]
  ldxdw r8, [r3+0x0]
  ldxdw r9, [r8+0x28]
  jne r9, r7, jmp_19b20
  ldxdw r7, [r10-0xc8]
  ldxdw r7, [r7+0x8]
  ldxdw r9, [r8+0x30]
  jne r9, r7, jmp_19b20
  ldxdw r7, [r10-0xc8]
  ldxdw r7, [r7+0x10]
  ldxdw r9, [r8+0x38]
  jne r9, r7, jmp_19b20
  mov64 r6, 0x0
  ldxdw r7, [r10-0xc8]
  ldxdw r7, [r7+0x18]
  ldxdw r8, [r8+0x40]
  jeq r8, r7, jmp_19b28

jmp_19b20:
  mov64 r6, 0x1

jmp_19b28:
  jeq r6, 0x0, jmp_19b48
  mov64 r8, 0x22
  mov64 r9, 0x0
  ja jmp_19950

jmp_19b48:
  mov64 r7, r0
  lsh64 r7, 0x2
  lddw r8, data_04f0
  add64 r8, r7
  ldxw r8, [r8+0x0]
  ldxdw r7, [r10-0xb8]
  ldxdw r9, [r10-0xd8]

jmp_19b88:
  stxdw [r10-0xe0], r5
  stxdw [r10-0xe8], r4
  stxdw [r10-0xc8], r1
  mov64 r6, r2
  add64 r6, 0x28
  stxdw [r10-0xf0], r2
  mov64 r4, r2
  add64 r4, 0x48
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0xfe8], r1
  stxdw [r10-0xff8], r7
  stxdw [r10-0x1000], r0
  mov64 r1, r9
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  jlt r8, r1, jmp_19c10
  mov64 r8, r1

jmp_19c10:
  stxdw [r10-0xff0], r8
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r5, r10
  mov64 r2, r3
  mov64 r3, r6
  call fn_14de0
  ldxw r7, [r10-0x74]
  ldxw r9, [r10-0x78]
  ldxh r0, [r10-0x64]
  jne r0, 0x2, jmp_19c80
  mov64 r8, r7
  ldxdw r1, [r10-0xc8]
  ja jmp_19950

jmp_19c80:
  mov64 r5, 0x1
  ldxdw r1, [r10-0xc0]
  jeq r1, 0x1, jmp_19ca0
  mov64 r5, 0x0

jmp_19ca0:
  ldxw r1, [r10-0x68]
  stxw [r10-0xa0], r1
  ldxdw r1, [r10-0x70]
  stxdw [r10-0xa8], r1
  ldxh r6, [r10-0x62]
  ldxdw r1, [r10-0xb0]
  ldxdw r2, [r10-0xe8]
  ldxdw r3, [r10-0xe0]
  jne r1, 0x1, jmp_19da8
  stxw [r10-0x74], r7
  stxw [r10-0x78], r9
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x70], r1
  ldxw r1, [r10-0xa0]
  stxw [r10-0x68], r1
  stxb [r10-0x60], r5
  stxh [r10-0x62], r6
  stxh [r10-0x64], r0
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x1

jmp_19d58:
  call fn_16588
  ldxw r2, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxh r3, [r10-0x4]
  jne r3, 0x2, jmp_19e60

jmp_19d80:
  ldxdw r3, [r10-0xc8]
  stxw [r3+0x4], r2
  stxw [r3+0x0], r1
  sth [r3+0x14], 0x2
  ja jmp_19710

jmp_19da8:
  ldxdw r1, [r10-0xc8]
  ldxdw r4, [r10-0xf0]
  jeq r3, 0x0, jmp_19f18
  stxdw [r10-0xb8], r9
  ldxb r9, [r4+0xb5]
  jgt r9, 0x1, jmp_19f30
  stxdw [r10-0xd0], r5
  ldxb r5, [r4+0xb6]
  jgt r5, 0x5, jmp_19f30
  mov64 r3, 0x20
  mov64 r8, 0x0
  stxdw [r10-0xd8], r0
  ldxb r0, [r4+0xb9]
  stxdw [r10-0xc0], r0
  stxdw [r10-0xf8], r6
  jeq r5, 0x5, jmp_19fc8
  jne r5, 0x4, jmp_1a030
  mov64 r0, 0x3
  stxdw [r10-0x100], r0
  ldxdw r0, [r10-0xc0]
  jeq r0, 0x8, jmp_19ff8
  jeq r0, 0x12, jmp_19ff8
  ja jmp_19f40

jmp_19e60:
  ldxw r4, [r10-0x8]
  stxw [r10-0x90], r4
  ldxdw r4, [r10-0x10]
  stxdw [r10-0x98], r4
  ldxh r4, [r10-0x2]
  ldxdw r5, [r10-0xc8]
  ldxdw r0, [r10-0xf0]
  mov64 r6, r3
  and64 r6, 0x1
  jeq r6, 0x0, jmp_19f80
  ldxh r0, [r0+0x24]
  mov64 r6, r0
  jlt r0, 0x3e8, jmp_19f58
  mov64 r6, 0x3e8
  mov64 r7, 0xc8
  jne r0, 0x0, jmp_19f68

jmp_19ee0:
  mov64 r0, r4
  jle r0, r7, jmp_19f80

jmp_19ef0:
  lddw r1, 0x1500000000
  stxdw [r5+0x0], r1
  sth [r5+0x14], 0x2
  ja jmp_19710

jmp_19f18:
  lddw r2, 0x1f00000000
  ja jmp_19700

jmp_19f30:
  mov64 r3, 0x20
  mov64 r8, 0x0

jmp_19f40:
  stxw [r1+0x4], r3
  stxw [r1+0x0], r8
  ja jmp_19708

jmp_19f58:
  mov64 r7, 0xc8
  jeq r0, 0x0, jmp_19ee0

jmp_19f68:
  mov64 r7, r6
  mov64 r0, r4
  jgt r0, r7, jmp_19ef0

jmp_19f80:
  ldxw r0, [r10-0x90]
  stxw [r5+0x10], r0
  ldxdw r0, [r10-0x98]
  stxdw [r5+0x8], r0
  stxh [r5+0x16], r4
  stxh [r5+0x14], r3
  stxw [r5+0x4], r2
  stxw [r5+0x0], r1
  ja jmp_19710

jmp_19fc8:
  mov64 r0, 0x7
  stxdw [r10-0x100], r0
  ldxdw r6, [r10-0xc0]
  add64 r6, -0x13
  and64 r6, 0xff
  jlt r6, 0xee, jmp_19f40

jmp_19ff8:
  mov64 r3, 0x1b
  ldxb r6, [r4+0x91]
  jne r6, 0x0, jmp_19f40
  ldxb r6, [r4+0x92]
  ldxdw r0, [r10-0x100]
  jeq r6, r0, jmp_1a038
  ja jmp_19f40

jmp_1a030:
  jne r0, 0x0, jmp_19f40

jmp_1a038:
  mov64 r3, r4
  add64 r3, 0x71
  ldxw r1, [r4+0xb1]
  ldxh r6, [r4+0xb7]
  stxdw [r10-0xfe8], r6
  stxdw [r10-0xff0], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r5
  add64 r4, 0x91
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r5, r10
  call fn_16300
  ldxw r3, [r10-0x74]
  ldxw r8, [r10-0x78]
  ldxh r6, [r10-0x64]
  jne r6, 0x2, jmp_1a0d8
  ldxdw r1, [r10-0xc8]
  ja jmp_19f40

jmp_1a0d8:
  mov64 r2, 0x1
  jeq r9, 0x1, jmp_1a0f0
  mov64 r2, 0x0

jmp_1a0f0:
  ldxw r1, [r10-0x68]
  stxw [r10-0x80], r1
  ldxdw r1, [r10-0x70]
  stxdw [r10-0x88], r1
  ldxh r4, [r10-0x62]
  ldxdw r1, [r10-0xb0]
  jne r1, 0x2, jmp_1a208
  stxw [r10-0x74], r7
  ldxdw r1, [r10-0xb8]
  stxw [r10-0x78], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x70], r1
  ldxw r1, [r10-0xa0]
  stxw [r10-0x68], r1
  stxw [r10-0x54], r3
  stxw [r10-0x58], r8
  ldxdw r1, [r10-0xd0]
  stxb [r10-0x60], r1
  ldxdw r1, [r10-0xf8]
  stxh [r10-0x62], r1
  ldxdw r1, [r10-0xd8]
  stxh [r10-0x64], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x50], r1
  ldxw r1, [r10-0x80]
  stxw [r10-0x48], r1
  stxb [r10-0x40], r2
  stxh [r10-0x42], r4
  stxh [r10-0x44], r6
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x2
  ja jmp_19d58

jmp_1a208:
  stxdw [r10-0x108], r4
  stxdw [r10-0x100], r2
  stxdw [r10-0xc0], r3
  stxdw [r10-0xb0], r8
  mov64 r9, r7
  ldxdw r1, [r10-0xe0]
  jne r1, 0x1, jmp_1a270
  lddw r1, 0x1f00000000
  ldxdw r2, [r10-0xc8]
  stxdw [r2+0x0], r1
  sth [r2+0x14], 0x2
  ja jmp_19710

jmp_1a270:
  mov64 r1, 0x0
  mov64 r2, 0x20
  ldxdw r3, [r10-0xf0]
  ldxb r7, [r3+0xfe]
  jgt r7, 0x1, jmp_19d80
  ldxdw r3, [r10-0xf0]
  ldxb r4, [r3+0xff]
  jgt r4, 0x5, jmp_19d80
  ldxdw r3, [r10-0xf0]
  ldxb r5, [r3+0x102]
  jeq r4, 0x5, jmp_1a2f0
  jne r4, 0x4, jmp_1a358
  mov64 r3, 0x3
  jeq r5, 0x8, jmp_1a318
  jeq r5, 0x12, jmp_1a318
  ja jmp_19d80

jmp_1a2f0:
  mov64 r3, 0x7
  mov64 r0, r5
  add64 r0, -0x13
  and64 r0, 0xff
  jlt r0, 0xee, jmp_19d80

jmp_1a318:
  mov64 r2, 0x1b
  ldxdw r0, [r10-0xf0]
  ldxb r0, [r0+0xda]
  jne r0, 0x0, jmp_19d80
  ldxdw r0, [r10-0xf0]
  ldxb r0, [r0+0xdb]
  jeq r0, r3, jmp_1a360
  ja jmp_19d80

jmp_1a358:
  jne r5, 0x0, jmp_19d80

jmp_1a360:
  ldxdw r2, [r10-0xe8]
  add64 r2, 0x8
  ldxdw r1, [r10-0xf0]
  mov64 r3, r1
  add64 r3, 0xba
  ldxw r8, [r1+0xfa]
  ldxh r0, [r1+0x100]
  stxdw [r10-0xfe8], r0
  stxdw [r10-0xff0], r8
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r4
  mov64 r4, r1
  add64 r4, 0xda
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r5, r10
  call fn_16300
  ldxw r2, [r10-0x14]
  ldxw r1, [r10-0x18]
  ldxh r3, [r10-0x4]
  jeq r3, 0x2, jmp_19d80
  mov64 r4, 0x1
  jeq r7, 0x1, jmp_1a420
  mov64 r4, 0x0

jmp_1a420:
  ldxw r5, [r10-0x8]
  stxw [r10-0x28], r5
  ldxdw r5, [r10-0x10]
  stxdw [r10-0x30], r5
  stxw [r10-0x74], r9
  ldxdw r5, [r10-0xb8]
  stxw [r10-0x78], r5
  ldxdw r5, [r10-0xa8]
  stxdw [r10-0x70], r5
  ldxw r5, [r10-0xa0]
  stxw [r10-0x68], r5
  ldxdw r5, [r10-0xc0]
  stxw [r10-0x54], r5
  ldxdw r5, [r10-0xb0]
  stxw [r10-0x58], r5
  ldxdw r5, [r10-0xd0]
  stxb [r10-0x60], r5
  ldxdw r5, [r10-0xf8]
  stxh [r10-0x62], r5
  ldxdw r5, [r10-0xd8]
  stxh [r10-0x64], r5
  ldxh r5, [r10-0x2]
  ldxw r0, [r10-0x80]
  stxw [r10-0x48], r0
  ldxdw r0, [r10-0x88]
  stxdw [r10-0x50], r0
  stxb [r10-0x20], r4
  stxh [r10-0x22], r5
  stxh [r10-0x24], r3
  stxw [r10-0x34], r2
  stxw [r10-0x38], r1
  ldxdw r1, [r10-0x100]
  stxb [r10-0x40], r1
  ldxdw r1, [r10-0x108]
  stxh [r10-0x42], r1
  stxh [r10-0x44], r6
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x3
  ja jmp_19d58

fn_1a570:
  mov64 r9, 0x3
  ldxdw r6, [r4+0x0]
  ldxdw r5, [r6+0x50]
  jne r5, 0xa5, jmp_1a628
  ldxdw r5, [r6+0x28]
  lddw r0, -0x6c5e9a281e0922fa
  jne r5, r0, jmp_1a618
  ldxdw r5, [r6+0x30]
  lddw r0, -0x53861431b91e3427
  jne r5, r0, jmp_1a618
  ldxdw r5, [r6+0x38]
  lddw r0, -0x6ec8a4a0127a4be4
  jne r5, r0, jmp_1a618
  mov64 r5, 0x0
  ldxdw r6, [r6+0x40]
  lddw r0, -0x56ff00817a0a73c6
  jeq r6, r0, jmp_1a620

jmp_1a618:
  mov64 r5, 0x1

jmp_1a620:
  jeq r5, 0x0, jmp_1a650

jmp_1a628:
  mov64 r7, r9
  rsh64 r7, 0x20

jmp_1a638:
  stxw [r1+0x4], r7
  stxw [r1+0x0], r9
  exit

jmp_1a650:
  stxdw [r10-0x188], r1
  stxdw [r10-0x198], r2
  ldxw r1, [r3+0x10]
  stxdw [r10-0x190], r1
  ldxdw r8, [r3+0x8]
  ldxdw r6, [r3+0x0]
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r4
  call fn_28528
  ldxdw r1, [r10-0x20]
  jeq r1, 0x0, jmp_1ae38
  ldxb r4, [r10-0x8]
  jgt r4, 0x7, jmp_1b628
  ldxdw r2, [r10-0x10]
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jlt r4, r5, jmp_1b640
  ldxdw r9, [r1+0x40]
  sub64 r4, r3
  stxb [r2+0x0], r4
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r7, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x38]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_1a7a8
  mov64 r1, 0x0

jmp_1a7a8:
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x40]
  mov64 r4, r2
  add64 r4, r3
  stxdw [r10-0x1a0], r4
  mov64 r3, 0x1
  jlt r4, r2, jmp_1a7e8
  mov64 r3, 0x0

jmp_1a7e8:
  or64 r1, r3
  mov64 r9, 0x17
  and64 r1, 0x1
  jne r1, 0x0, jmp_1b438
  ldxdw r2, [r10-0x190]
  lsh64 r2, 0x20
  arsh64 r2, 0x20
  ldxdw r6, [r10-0x30]
  jsle r2, -0x1, jmp_1aea0
  mov64 r8, 0x1
  mov64 r0, 0x0
  jeq r2, 0x0, jmp_1ac70
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1a870
  mov64 r8, 0xa
  jeq r2, 0x1, jmp_1ac70

jmp_1a870:
  mov64 r1, r2
  and64 r1, 0x2
  stxdw [r10-0x190], r2
  jeq r1, 0x0, jmp_1a8f8
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x190]
  ldxdw r0, [r10-0xc8]
  ldxdw r8, [r10-0xd0]
  mov64 r1, r2
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1ac70

jmp_1a8f8:
  mov64 r1, r2
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1a978
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x190]
  ldxdw r0, [r10-0xd8]
  ldxdw r8, [r10-0xe0]
  mov64 r1, r2
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1ac70

jmp_1a978:
  mov64 r1, r2
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1a9f8
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x190]
  ldxdw r0, [r10-0xe8]
  ldxdw r8, [r10-0xf0]
  mov64 r1, r2
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1ac70

jmp_1a9f8:
  mov64 r1, r2
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1aa80
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r8
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x190]
  ldxdw r0, [r10-0xf8]
  ldxdw r8, [r10-0x100]
  mov64 r1, r2
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1ac70

jmp_1aa80:
  mov64 r1, r2
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1b438
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r0
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x1b0], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  stxdw [r10-0x1a8], r1
  mov64 r8, 0x1
  ldxdw r1, [r10-0x1b0]
  jne r1, 0x0, jmp_1b5d0
  mov64 r8, 0x0
  ldxdw r4, [r10-0x118]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1b5e8

jmp_1aba8:
  ldxdw r5, [r10-0x128]
  mov64 r4, 0x1
  ldxdw r1, [r10-0x188]
  jne r5, 0x0, jmp_1abd0

jmp_1abc8:
  mov64 r4, 0x0

jmp_1abd0:
  ldxdw r5, [r10-0x130]
  ldxdw r0, [r10-0x120]
  add64 r0, r5
  ldxdw r2, [r10-0x108]
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, r5
  jlt r0, r2, jmp_1ac20
  mov64 r2, 0x0
  stxdw [r10-0x1a8], r2

jmp_1ac20:
  ldxdw r5, [r10-0x190]
  and64 r5, 0x7fffffe0
  jne r5, 0x20, jmp_1a638
  or64 r8, r3
  or64 r8, r4
  ldxdw r2, [r10-0x1a8]
  or64 r8, r2
  and64 r8, 0x1
  jne r8, 0x0, jmp_1a638
  ldxdw r8, [r10-0x110]

jmp_1ac70:
  stxdw [r10-0x190], r8
  mov64 r1, r10
  add64 r1, -0x160
  ldxdw r2, [r10-0x1a0]
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  mov64 r8, r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r6
  mov64 r3, 0x0
  ldxdw r4, [r10-0x190]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r3, 0x1
  jne r8, 0x0, jmp_1ad40
  mov64 r3, 0x0

jmp_1ad40:
  mov64 r2, 0x1
  ldxdw r0, [r10-0x198]
  ldxdw r1, [r10-0x188]
  ldxdw r4, [r10-0x1a0]
  mov64 r6, 0x1
  jne r4, 0x0, jmp_1ae50
  mov64 r2, 0x0
  and64 r2, r3
  ldxdw r4, [r10-0x158]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1ae70

jmp_1ad98:
  or64 r2, r3
  ldxdw r4, [r10-0x148]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1adc0

jmp_1adb8:
  mov64 r3, 0x0

jmp_1adc0:
  or64 r2, r3
  ldxdw r3, [r10-0x150]
  ldxdw r4, [r10-0x160]
  add64 r4, r3
  ldxdw r5, [r10-0x138]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_1ae08
  mov64 r6, 0x0

jmp_1ae08:
  or64 r2, r6
  and64 r2, 0x1
  jne r2, 0x0, jmp_1a638
  ldxdw r2, [r10-0x140]
  jne r3, 0x0, jmp_1a638
  ja jmp_1b318

jmp_1ae38:
  ldxdw r9, [r10-0x18]
  ldxdw r1, [r10-0x188]
  ja jmp_1a628

jmp_1ae50:
  and64 r2, r3
  ldxdw r4, [r10-0x158]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1ad98

jmp_1ae70:
  mov64 r3, 0x0
  or64 r2, r3
  ldxdw r4, [r10-0x148]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1adb8
  ja jmp_1adc0

jmp_1aea0:
  jeq r2, -0x80000000, jmp_1b658
  stxdw [r10-0x190], r6
  mov64 r6, r2
  neg64 r6
  mov64 r1, r6
  mov64 r0, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_1aef0
  mov64 r8, 0x1
  ja jmp_1af00

jmp_1aef0:
  mov64 r8, 0xa
  jeq r2, -0x1, jmp_1b2b8

jmp_1af00:
  mov64 r1, r6
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1af78
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x48]
  ldxdw r8, [r10-0x50]
  mov64 r1, r6
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1b2b8

jmp_1af78:
  mov64 r1, r6
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1aff0
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x58]
  ldxdw r8, [r10-0x60]
  mov64 r1, r6
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1b2b8

jmp_1aff0:
  mov64 r1, r6
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1b068
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x68]
  ldxdw r8, [r10-0x70]
  mov64 r1, r6
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1b2b8

jmp_1b068:
  mov64 r1, r6
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1b0e8
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, r8
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x78]
  ldxdw r8, [r10-0x80]
  mov64 r1, r6
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1b2b8

jmp_1b0e8:
  mov64 r1, r6
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1b438
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r0
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x1a8], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r8, 0x1
  ldxdw r1, [r10-0x1a8]
  jne r1, 0x0, jmp_1b588
  mov64 r8, 0x0
  ldxdw r4, [r10-0x98]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1b5a0

jmp_1b200:
  ldxdw r5, [r10-0xa8]
  mov64 r4, 0x1
  ldxdw r1, [r10-0x188]
  jne r5, 0x0, jmp_1b228

jmp_1b220:
  mov64 r4, 0x0

jmp_1b228:
  ldxdw r5, [r10-0xb0]
  ldxdw r0, [r10-0xa0]
  add64 r0, r5
  ldxdw r2, [r10-0x88]
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, r5
  mov64 r5, 0x1
  jlt r0, r2, jmp_1b278
  mov64 r5, 0x0

jmp_1b278:
  and64 r6, 0x7fffffe0
  jne r6, 0x20, jmp_1a638
  or64 r8, r3
  or64 r8, r4
  or64 r8, r5
  and64 r8, 0x1
  jne r8, 0x0, jmp_1a638
  ldxdw r8, [r10-0x90]

jmp_1b2b8:
  mov64 r1, r10
  add64 r1, -0xc0
  ldxdw r2, [r10-0x190]
  ldxdw r3, [r10-0x1a0]
  mov64 r4, r8
  mov64 r5, r0
  call fn_2c2b0
  ldxdw r3, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  ldxdw r0, [r10-0x198]
  ldxdw r1, [r10-0x188]
  jne r3, 0x0, jmp_1a638

jmp_1b318:
  ldxdw r5, [r0+0x4a]
  ldxdw r6, [r0+0x42]
  mov64 r4, r6
  add64 r4, r5
  mov64 r3, 0x1
  jlt r4, r6, jmp_1b350
  mov64 r3, 0x0

jmp_1b350:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1a638
  mov64 r4, r5
  add64 r4, r6
  mov64 r3, r2
  sub64 r3, r4
  mov64 r1, 0x1
  jgt r3, r2, jmp_1b398
  mov64 r1, 0x0

jmp_1b398:
  stxdw [r10-0x190], r5
  mov64 r4, 0x0
  jne r1, 0x0, jmp_1b3b8
  mov64 r4, r3

jmp_1b3b8:
  stxdw [r10-0x1a0], r4
  ldxh r2, [r0+0x40]
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x180
  ldxdw r2, [r10-0x170]
  ldxdw r8, [r10-0x168]
  mov64 r3, r8
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  jle r8, 0x270f, jmp_1b448

jmp_1b438:
  ldxdw r1, [r10-0x188]
  ja jmp_1a638

jmp_1b448:
  ldxdw r5, [r10-0x180]
  ldxdw r8, [r10-0x1a0]
  mov64 r3, r8
  sub64 r3, r5
  mov64 r4, 0x1
  jgt r3, r8, jmp_1b4b0
  mov64 r4, 0x0
  ldxdw r2, [r10-0x198]
  ldxdw r0, [r10-0x190]
  jeq r4, 0x0, jmp_1b4c8

jmp_1b498:
  ldxdw r1, [r10-0x188]
  jlt r8, r5, jmp_1a638
  ja jmp_1b4e0

jmp_1b4b0:
  ldxdw r2, [r10-0x198]
  ldxdw r0, [r10-0x190]
  jne r4, 0x0, jmp_1b498

jmp_1b4c8:
  mov64 r7, r3
  ldxdw r1, [r10-0x188]
  jlt r8, r5, jmp_1a638

jmp_1b4e0:
  mov64 r4, r6
  add64 r4, r7
  mov64 r3, 0x1
  jlt r4, r6, jmp_1b508
  mov64 r3, 0x0

jmp_1b508:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1b618
  add64 r7, r6
  stxdw [r2+0x42], r7
  mov64 r4, r0
  add64 r4, r5
  mov64 r7, 0x0
  mov64 r3, 0x1
  jlt r4, r0, jmp_1b558
  mov64 r3, 0x0

jmp_1b558:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1a638
  add64 r0, r5
  stxdw [r2+0x4a], r0
  mov64 r9, 0x1a
  ja jmp_1a638

jmp_1b588:
  ldxdw r4, [r10-0x98]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1b200

jmp_1b5a0:
  mov64 r3, 0x0
  ldxdw r5, [r10-0xa8]
  mov64 r4, 0x1
  ldxdw r1, [r10-0x188]
  jeq r5, 0x0, jmp_1b220
  ja jmp_1b228

jmp_1b5d0:
  ldxdw r4, [r10-0x118]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1aba8

jmp_1b5e8:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x128]
  mov64 r4, 0x1
  ldxdw r1, [r10-0x188]
  jeq r5, 0x0, jmp_1abc8
  ja jmp_1abd0

jmp_1b618:
  mov64 r7, 0x0
  ja jmp_1a638

jmp_1b628:
  lddw r1, data_0810
  call fn_29a40

jmp_1b640:
  lddw r1, data_0828
  call fn_29938

jmp_1b658:
  lddw r1, data_0e20
  call fn_299e8

fn_1b670:
  mov64 r6, r1
  mov64 r1, 0x3
  ldxdw r0, [r4+0x0]
  ldxdw r7, [r0+0x50]
  jne r7, 0xa5, jmp_1b730
  ldxdw r7, [r0+0x28]
  lddw r8, -0x6c5e9a281e0922fa
  jne r7, r8, jmp_1b720
  ldxdw r7, [r0+0x30]
  lddw r8, -0x53861431b91e3427
  jne r7, r8, jmp_1b720
  ldxdw r7, [r0+0x38]
  lddw r8, -0x6ec8a4a0127a4be4
  jne r7, r8, jmp_1b720
  mov64 r7, 0x0
  ldxdw r0, [r0+0x40]
  lddw r8, -0x56ff00817a0a73c6
  jeq r0, r8, jmp_1b728

jmp_1b720:
  mov64 r7, 0x1

jmp_1b728:
  jeq r7, 0x0, jmp_1b758

jmp_1b730:
  mov64 r9, r1
  rsh64 r9, 0x20

jmp_1b740:
  stxw [r6+0x4], r9
  stxw [r6+0x0], r1
  exit

jmp_1b758:
  stxdw [r10-0x298], r6
  stxdw [r10-0x2b0], r2
  ldxw r6, [r3+0x10]
  ldxdw r1, [r5-0xfe0]
  stxdw [r10-0x2c8], r1
  ldxdw r7, [r5-0xfe8]
  ldxdw r8, [r5-0xff0]
  ldxdw r9, [r5-0xff8]
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0x2c0], r1
  ldxdw r1, [r3+0x8]
  stxdw [r10-0x2a8], r1
  ldxdw r1, [r3+0x0]
  stxdw [r10-0x2a0], r1
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r4
  call fn_28528
  ldxdw r1, [r10-0x68]
  jeq r1, 0x0, jmp_1bf78
  ldxb r4, [r10-0x50]
  jgt r4, 0x7, jmp_1d3d0
  stxdw [r10-0x2e8], r9
  stxdw [r10-0x2e0], r8
  stxdw [r10-0x2d8], r7
  ldxdw r2, [r10-0x58]
  mov64 r8, 0x1
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jlt r4, r5, jmp_1d3e8
  ldxdw r7, [r1+0x40]
  sub64 r4, r3
  stxb [r2+0x0], r4
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r9, 0x0
  ldxdw r2, [r10-0x2a8]
  mov64 r3, 0x0
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r4, [r10-0x2a0]
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0xb0]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_1b910
  mov64 r1, 0x0

jmp_1b910:
  ldxdw r2, [r10-0xa0]
  ldxdw r3, [r10-0xb8]
  mov64 r4, r2
  add64 r4, r3
  mov64 r3, r6
  stxdw [r10-0x2b8], r4
  jlt r4, r2, jmp_1b950
  mov64 r8, 0x0

jmp_1b950:
  or64 r1, r8
  and64 r1, 0x1
  ldxdw r6, [r10-0x298]
  jne r1, 0x0, jmp_1c520
  lsh64 r3, 0x20
  arsh64 r3, 0x20
  ldxdw r8, [r10-0xa8]
  stxdw [r10-0x2d0], r3
  jsle r3, -0x1, jmp_1bf90
  mov64 r9, 0x1
  mov64 r0, 0x0
  jeq r3, 0x0, jmp_1bdb0
  mov64 r1, r3
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1b9d8
  mov64 r9, 0xa
  jeq r3, 0x1, jmp_1bdb0

jmp_1b9d8:
  mov64 r1, r3
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1ba58
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r9
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x2d0]
  ldxdw r0, [r10-0x140]
  ldxdw r9, [r10-0x148]
  mov64 r1, r3
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1bdb0

jmp_1ba58:
  mov64 r1, r3
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1bad8
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r2, r9
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x2d0]
  ldxdw r0, [r10-0x150]
  ldxdw r9, [r10-0x158]
  mov64 r1, r3
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1bdb0

jmp_1bad8:
  mov64 r1, r3
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1bb58
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r9
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x2d0]
  ldxdw r0, [r10-0x160]
  ldxdw r9, [r10-0x168]
  mov64 r1, r3
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1bdb0

jmp_1bb58:
  mov64 r1, r3
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1bbe0
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r9
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x2d0]
  ldxdw r0, [r10-0x170]
  ldxdw r9, [r10-0x178]
  mov64 r1, r3
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1bdb0

jmp_1bbe0:
  mov64 r1, r3
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1cd30
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r0
  mov64 r3, 0x0
  mov64 r7, r9
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  mov64 r9, r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  jne r9, 0x0, jmp_1cc48
  mov64 r1, 0x0
  ldxdw r4, [r10-0x190]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1cc60

jmp_1bd00:
  ldxdw r5, [r10-0x1a0]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_1bd20

jmp_1bd18:
  mov64 r4, 0x0

jmp_1bd20:
  ldxdw r5, [r10-0x1a8]
  ldxdw r0, [r10-0x198]
  add64 r0, r5
  ldxdw r5, [r10-0x180]
  mov64 r7, r5
  add64 r7, r0
  mov64 r0, r7
  jlt r0, r5, jmp_1bd68
  mov64 r2, 0x0

jmp_1bd68:
  ldxdw r5, [r10-0x2d0]
  and64 r5, 0x7fffffe0
  jne r5, 0x20, jmp_1cd30
  or64 r1, r3
  or64 r1, r4
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_1cd30
  ldxdw r9, [r10-0x188]

jmp_1bdb0:
  mov64 r1, r10
  add64 r1, -0x1d8
  ldxdw r2, [r10-0x2b8]
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  mov64 r7, r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r3, 0x1
  jne r7, 0x0, jmp_1be78
  mov64 r3, 0x0

jmp_1be78:
  mov64 r2, 0x1
  ldxdw r1, [r10-0x2b0]
  ldxdw r4, [r10-0x2b8]
  mov64 r0, 0x1
  jne r4, 0x0, jmp_1bea8
  mov64 r2, 0x0

jmp_1bea8:
  and64 r2, r3
  ldxdw r4, [r10-0x1d0]
  mov64 r3, 0x1
  mov64 r9, 0x0
  jne r4, 0x0, jmp_1bed8
  mov64 r3, 0x0

jmp_1bed8:
  or64 r2, r3
  ldxdw r4, [r10-0x1c0]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1bf00
  mov64 r3, 0x0

jmp_1bf00:
  or64 r2, r3
  ldxdw r3, [r10-0x1c8]
  ldxdw r4, [r10-0x1d8]
  add64 r4, r3
  ldxdw r5, [r10-0x1b0]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_1bf48
  mov64 r0, 0x0

jmp_1bf48:
  or64 r2, r0
  and64 r2, 0x1
  jne r2, 0x0, jmp_1c520
  ldxdw r4, [r10-0x1b8]
  jeq r3, 0x0, jmp_1c3f8
  ja jmp_1c520

jmp_1bf78:
  ldxdw r1, [r10-0x60]
  ldxdw r6, [r10-0x298]
  ja jmp_1b730

jmp_1bf90:
  jeq r3, -0x80000000, jmp_1d400
  stxdw [r10-0x2f0], r8
  mov64 r8, r3
  neg64 r8
  mov64 r1, r8
  mov64 r0, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_1bfe0
  mov64 r7, 0x1
  ja jmp_1bff0

jmp_1bfe0:
  mov64 r7, 0xa
  jeq r3, -0x1, jmp_1c3a0

jmp_1bff0:
  mov64 r1, r8
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1c068
  mov64 r1, r10
  add64 r1, -0xc8
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xc0]
  ldxdw r7, [r10-0xc8]
  mov64 r1, r8
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1c3a0

jmp_1c068:
  mov64 r1, r8
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1c0e0
  mov64 r1, r10
  add64 r1, -0xd8
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xd0]
  ldxdw r7, [r10-0xd8]
  mov64 r1, r8
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1c3a0

jmp_1c0e0:
  mov64 r1, r8
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1c158
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xe0]
  ldxdw r7, [r10-0xe8]
  mov64 r1, r8
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1c3a0

jmp_1c158:
  mov64 r1, r8
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1c1d8
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r7
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xf0]
  ldxdw r7, [r10-0xf8]
  mov64 r1, r8
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1c3a0

jmp_1c1d8:
  mov64 r1, r8
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1c520
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r0
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x2f8], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r3, [r10-0x2f8]
  jne r3, 0x0, jmp_1cc08
  mov64 r1, 0x0
  ldxdw r4, [r10-0x110]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1cc20

jmp_1c2f8:
  ldxdw r5, [r10-0x120]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_1c318

jmp_1c310:
  mov64 r4, 0x0

jmp_1c318:
  ldxdw r5, [r10-0x128]
  ldxdw r0, [r10-0x118]
  add64 r0, r5
  ldxdw r5, [r10-0x100]
  mov64 r7, r5
  add64 r7, r0
  mov64 r0, r7
  jlt r0, r5, jmp_1c360
  mov64 r2, 0x0

jmp_1c360:
  and64 r8, 0x7fffffe0
  jne r8, 0x20, jmp_1c520
  or64 r1, r3
  or64 r1, r4
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_1c520
  ldxdw r7, [r10-0x108]

jmp_1c3a0:
  mov64 r1, r10
  add64 r1, -0x138
  ldxdw r2, [r10-0x2f0]
  ldxdw r3, [r10-0x2b8]
  mov64 r4, r7
  mov64 r5, r0
  call fn_2c2b0
  ldxdw r3, [r10-0x130]
  ldxdw r4, [r10-0x138]
  ldxdw r1, [r10-0x2b0]
  jne r3, 0x0, jmp_1c520

jmp_1c3f8:
  ldxdw r5, [r1+0x4a]
  ldxdw r7, [r1+0x42]
  mov64 r3, r7
  add64 r3, r5
  mov64 r2, 0x1
  jlt r3, r7, jmp_1c430
  mov64 r2, 0x0

jmp_1c430:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1c520
  mov64 r3, r5
  add64 r3, r7
  mov64 r2, r4
  sub64 r2, r3
  mov64 r3, 0x1
  jgt r2, r4, jmp_1c478
  mov64 r3, 0x0

jmp_1c478:
  stxdw [r10-0x2b8], r5
  stxdw [r10-0x2f8], r4
  mov64 r4, 0x0
  jne r3, 0x0, jmp_1c4a0
  mov64 r4, r2

jmp_1c4a0:
  stxdw [r10-0x2f0], r4
  ldxh r2, [r1+0x40]
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1f8
  ldxdw r2, [r10-0x1e8]
  ldxdw r8, [r10-0x1e0]
  mov64 r3, r8
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  jle r8, 0x270f, jmp_1c530

jmp_1c520:
  mov64 r1, 0x17
  ja jmp_1b740

jmp_1c530:
  ldxdw r1, [r10-0x1f8]
  ldxdw r0, [r10-0x2f0]
  mov64 r3, r0
  sub64 r3, r1
  mov64 r8, 0x0
  mov64 r4, 0x1
  jgt r3, r0, jmp_1c5a8
  mov64 r4, 0x0
  ldxdw r2, [r10-0x2b0]
  ldxdw r5, [r10-0x2b8]
  jeq r4, 0x0, jmp_1c5c0

jmp_1c588:
  jge r0, r1, jmp_1c5d0

jmp_1c590:
  mov64 r9, r8
  mov64 r1, 0x17
  ja jmp_1b740

jmp_1c5a8:
  ldxdw r2, [r10-0x2b0]
  ldxdw r5, [r10-0x2b8]
  jne r4, 0x0, jmp_1c588

jmp_1c5c0:
  mov64 r8, r3
  jlt r0, r1, jmp_1c590

jmp_1c5d0:
  mov64 r4, r7
  add64 r4, r8
  mov64 r3, 0x1
  jlt r4, r7, jmp_1c5f8
  mov64 r3, 0x0

jmp_1c5f8:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1c520
  mov64 r4, r5
  add64 r4, r1
  mov64 r3, 0x1
  jlt r4, r5, jmp_1c630
  mov64 r3, 0x0

jmp_1c630:
  add64 r8, r7
  stxdw [r2+0x42], r8
  and64 r3, 0x1
  jne r3, 0x0, jmp_1c520
  add64 r5, r1
  stxdw [r2+0x4a], r5
  mov64 r1, 0x0
  mov64 r9, 0x19
  ldxdw r2, [r10-0x2f8]
  jgt r8, r2, jmp_1b740
  mov64 r1, 0x3
  ldxdw r2, [r10-0x2c0]
  ldxdw r7, [r2+0x0]
  ldxdw r2, [r7+0x50]
  jne r2, 0x52, jmp_1b730
  ldxdw r1, [r7+0x28]
  lddw r2, -0x6c5e9a281e0922fa
  jne r1, r2, jmp_1c730
  ldxdw r1, [r7+0x30]
  lddw r2, -0x53861431b91e3427
  jne r1, r2, jmp_1c730
  ldxdw r1, [r7+0x38]
  lddw r2, -0x6ec8a4a0127a4be4
  jne r1, r2, jmp_1c730
  mov64 r2, 0x0
  ldxdw r1, [r7+0x40]
  lddw r3, -0x56ff00817a0a73c6
  jeq r1, r3, jmp_1c738

jmp_1c730:
  mov64 r2, 0x1

jmp_1c738:
  mov64 r1, 0x16
  jne r2, 0x0, jmp_1b730
  stxdw [r10-0x2b8], r5
  mov64 r1, r10
  add64 r1, -0x68
  ldxdw r2, [r10-0x2c0]
  call fn_28528
  ldxdw r1, [r10-0x68]
  jeq r1, 0x0, jmp_1cc88
  ldxb r4, [r10-0x50]
  jgt r4, 0x7, jmp_1d3d0
  ldxdw r0, [r10-0x58]
  mov64 r2, 0x1
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r0+0x0]
  jlt r4, r5, jmp_1d3e8
  ldxb r5, [r1+0x2c]
  ldxdw r1, [r1+0x24]
  stxdw [r10-0x2f0], r1
  sub64 r4, r3
  stxb [r0+0x0], r4
  jeq r5, 0x0, jmp_1c988
  mov64 r1, r5
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1c828
  mov64 r2, 0xa
  jeq r5, 0x1, jmp_1c988

jmp_1c828:
  mov64 r1, r5
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1c860
  mul64 r2, 0x64
  mov64 r1, r5
  and64 r1, 0xfe
  jeq r1, 0x2, jmp_1c988

jmp_1c860:
  mov64 r1, r5
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1c898
  mul64 r2, 0x2710
  mov64 r1, r5
  and64 r1, 0xfc
  jeq r1, 0x4, jmp_1c988

jmp_1c898:
  mov64 r1, r5
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1c8d0
  mul64 r2, 0x5f5e100
  mov64 r1, r5
  and64 r1, 0xf8
  jeq r1, 0x8, jmp_1c988

jmp_1c8d0:
  mov64 r1, r5
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1d428
  mov64 r6, r5
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r3, 0x0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x200]
  jne r2, 0x0, jmp_1c948
  mov64 r1, 0x0

jmp_1c948:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d428
  mov64 r5, r6
  mov64 r1, r5
  and64 r1, 0xf0
  ldxdw r6, [r10-0x298]
  jne r1, 0x10, jmp_1d428
  ldxdw r2, [r10-0x208]

jmp_1c988:
  stxdw [r10-0x300], r2
  stxdw [r10-0x310], r5
  stxdw [r10-0x308], r7
  mov64 r1, r10
  add64 r1, -0x228
  ldxdw r2, [r10-0x2a8]
  mov64 r3, 0x0
  ldxdw r7, [r10-0x2d8]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r4, [r10-0x2a0]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r5, 0x1
  ldxdw r3, [r10-0x220]
  mov64 r1, 0x1
  jne r3, 0x0, jmp_1ca40
  mov64 r1, 0x0

jmp_1ca40:
  ldxdw r3, [r10-0x210]
  ldxdw r4, [r10-0x228]
  mov64 r7, r3
  add64 r7, r4
  ldxdw r2, [r10-0x2d0]
  jlt r7, r3, jmp_1ca78
  mov64 r5, 0x0

jmp_1ca78:
  or64 r1, r5
  and64 r1, 0x1
  jne r1, 0x0, jmp_1cd30
  ldxdw r9, [r10-0x218]
  jslt r2, 0x0, jmp_1cc98
  mov64 r1, r10
  add64 r1, -0x68
  call fn_02a8
  ldxdw r1, [r10-0x68]
  jeq r1, 0x0, jmp_1cd30
  mov64 r1, r10
  add64 r1, -0x268
  ldxdw r6, [r10-0x60]
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x258
  ldxdw r2, [r10-0x58]
  stxdw [r10-0x2a0], r2
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  mov64 r3, 0x1
  ldxdw r2, [r10-0x2a0]
  jne r2, 0x0, jmp_1cd48
  mov64 r3, 0x0
  mov64 r2, 0x1
  jeq r7, 0x0, jmp_1cd58

jmp_1cbb8:
  and64 r2, r3
  ldxdw r4, [r10-0x260]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1cd80

jmp_1cbd8:
  mov64 r3, 0x0
  or64 r2, r3
  ldxdw r4, [r10-0x250]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1cda0
  ja jmp_1cda8

jmp_1cc08:
  ldxdw r4, [r10-0x110]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1c2f8

jmp_1cc20:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x120]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_1c310
  ja jmp_1c318

jmp_1cc48:
  ldxdw r4, [r10-0x190]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1bd00

jmp_1cc60:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x1a0]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_1bd18
  ja jmp_1bd20

jmp_1cc88:
  ldxdw r1, [r10-0x60]
  ja jmp_1b730

jmp_1cc98:
  neg64 r2
  mov64 r1, r10
  add64 r1, -0x68
  call fn_02a8
  ldxdw r1, [r10-0x68]
  jne r1, 0x1, jmp_1cd30
  ldxdw r5, [r10-0x58]
  ldxdw r4, [r10-0x60]
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_1ce18
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, r9
  mov64 r3, r7
  call fn_2c2b0
  ldxdw r3, [r10-0x230]
  ldxdw r7, [r10-0x238]
  ja jmp_1ce10

jmp_1cd30:
  mov64 r9, 0x0
  mov64 r1, 0x17
  ja jmp_1b740

jmp_1cd48:
  mov64 r2, 0x1
  jne r7, 0x0, jmp_1cbb8

jmp_1cd58:
  mov64 r2, 0x0
  and64 r2, r3
  ldxdw r4, [r10-0x260]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1cbd8

jmp_1cd80:
  or64 r2, r3
  ldxdw r4, [r10-0x250]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1cda8

jmp_1cda0:
  mov64 r3, 0x0

jmp_1cda8:
  or64 r2, r3
  ldxdw r3, [r10-0x258]
  ldxdw r4, [r10-0x268]
  add64 r4, r3
  ldxdw r5, [r10-0x240]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_1cdf0
  mov64 r1, 0x0

jmp_1cdf0:
  or64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_1ce18
  ldxdw r7, [r10-0x248]

jmp_1ce10:
  jeq r3, 0x0, jmp_1ce38

jmp_1ce18:
  mov64 r9, 0x0
  mov64 r1, 0x17

jmp_1ce28:
  ldxdw r6, [r10-0x298]
  ja jmp_1b740

jmp_1ce38:
  ldxdw r2, [r10-0x2f8]
  mov64 r4, r2
  ldxdw r1, [r10-0x2b8]
  sub64 r4, r1
  mov64 r1, 0x0
  mov64 r5, 0x1
  jgt r4, r2, jmp_1ceb8
  mov64 r5, 0x0
  mov64 r2, 0x0
  jeq r5, 0x0, jmp_1cec8

jmp_1ce88:
  jlt r2, r8, jmp_1ced8

jmp_1ce90:
  mov64 r2, r8
  ldxdw r6, [r10-0x298]
  mov64 r9, 0x19
  jeq r2, 0x0, jmp_1cef0
  ja jmp_1cf00

jmp_1ceb8:
  mov64 r2, 0x0
  jne r5, 0x0, jmp_1ce88

jmp_1cec8:
  mov64 r2, r4
  jge r2, r8, jmp_1ce90

jmp_1ced8:
  ldxdw r6, [r10-0x298]
  mov64 r9, 0x19
  jne r2, 0x0, jmp_1cf00

jmp_1cef0:
  ldxdw r4, [r10-0x2f0]
  jne r4, 0x0, jmp_1b740

jmp_1cf00:
  mov64 r6, r2
  ldxdw r1, [r10-0x300]
  add64 r6, r1
  mov64 r1, 0x1
  jlt r6, r2, jmp_1cf30
  mov64 r1, 0x0

jmp_1cf30:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d018
  ldxdw r4, [r10-0x2f0]
  mov64 r2, r4
  ldxdw r1, [r10-0x300]
  add64 r2, r1
  mov64 r1, 0x1
  jlt r2, r4, jmp_1cf78
  mov64 r1, 0x0

jmp_1cf78:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d018
  jeq r6, 0x0, jmp_1d018
  ldxdw r1, [r10-0x2f0]
  ldxdw r4, [r10-0x300]
  add64 r4, r1
  mov64 r1, r10
  add64 r1, -0x278
  mov64 r2, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x288
  ldxdw r2, [r10-0x278]
  ldxdw r3, [r10-0x270]
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c2b0
  ldxdw r1, [r10-0x280]
  jeq r1, 0x0, jmp_1d038

jmp_1d018:
  mov64 r1, 0x17
  ldxdw r6, [r10-0x298]
  mov64 r9, 0x0
  ja jmp_1b740

jmp_1d038:
  ldxdw r2, [r10-0x288]
  mov64 r1, 0x0
  stxdw [r10-0x2a0], r2
  jeq r2, 0x0, jmp_1d110
  mov64 r9, 0xf
  ldxdw r2, [r10-0x2c8]
  ldxdw r6, [r10-0x298]
  ldxdw r3, [r10-0x2a0]
  jgt r2, r3, jmp_1b740
  ldxdw r1, [r10-0x2b0]
  ldxdw r2, [r1+0x74]
  jeq r2, 0x0, jmp_1d120
  mov64 r1, r8
  add64 r1, r7
  mov64 r3, 0x1
  jlt r1, r8, jmp_1d0c0
  mov64 r3, 0x0

jmp_1d0c0:
  and64 r3, 0x1
  mov64 r1, 0x17
  ldxdw r6, [r10-0x298]
  mov64 r9, 0x0
  jne r3, 0x0, jmp_1b740
  add64 r8, r7
  jle r8, r2, jmp_1d120
  mov64 r1, 0x0
  mov64 r9, 0x16
  ja jmp_1ce28

jmp_1d110:
  mov64 r9, 0xc
  ja jmp_1ce28

jmp_1d120:
  lddw r1, str_036a
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x2b0]
  add64 r1, 0x72
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x308]
  add64 r1, 0x8
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x1
  stdw [r10-0x80], 0x20
  stdw [r10-0x90], 0x5
  ldxdw r1, [r10-0x310]
  stxb [r10-0x48], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x2e0]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x2e8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x2c0]
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x98
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, r10
  add64 r2, -0x68
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r6, 0x1
  mov64 r4, 0x1
  call fn_272c0
  ldxw r1, [r10-0x290]
  jne r1, 0x1a, jmp_1d3c0
  ldxdw r1, [r10-0x2e8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r10-0x2e0]
  ldxdw r2, [r2+0x0]
  stb [r10-0x68], 0x1
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x67], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x5f], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x57], r3
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x4f], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x47], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x3f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x37], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x2f], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x1f], r1
  ldxdw r1, [r10-0x2d8]
  stxdw [r10-0x27], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x51
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  ldxdw r1, [r10-0x2b0]
  ldxdw r1, [r1+0x42]
  mov64 r2, r1
  add64 r2, r7
  jlt r2, r1, jmp_1d380
  mov64 r6, 0x0

jmp_1d380:
  and64 r6, 0x1
  jne r6, 0x0, jmp_1d418
  add64 r1, r7
  ldxdw r2, [r10-0x2b0]
  stxdw [r2+0x42], r1
  mov64 r1, 0x1a

jmp_1d3b0:
  mov64 r9, 0x0
  ja jmp_1ce28

jmp_1d3c0:
  ldxw r9, [r10-0x28c]
  ja jmp_1ce28

jmp_1d3d0:
  lddw r1, data_0810
  call fn_29a40

jmp_1d3e8:
  lddw r1, data_0828
  call fn_29938

jmp_1d400:
  lddw r1, data_0e20
  call fn_299e8

jmp_1d418:
  mov64 r1, 0x17
  ja jmp_1d3b0

jmp_1d428:
  lddw r1, data_07e0
  call fn_29990

fn_1d440:
  mov64 r9, 0x3
  ldxdw r0, [r3+0x0]
  ldxdw r6, [r0+0x50]
  jne r6, 0xa5, jmp_1d4f8
  ldxdw r6, [r0+0x28]
  lddw r7, -0x6c5e9a281e0922fa
  jne r6, r7, jmp_1d4e8
  ldxdw r6, [r0+0x30]
  lddw r7, -0x53861431b91e3427
  jne r6, r7, jmp_1d4e8
  ldxdw r6, [r0+0x38]
  lddw r7, -0x6ec8a4a0127a4be4
  jne r6, r7, jmp_1d4e8
  mov64 r6, 0x0
  ldxdw r0, [r0+0x40]
  lddw r7, -0x56ff00817a0a73c6
  jeq r0, r7, jmp_1d4f0

jmp_1d4e8:
  mov64 r6, 0x1

jmp_1d4f0:
  jeq r6, 0x0, jmp_1d568

jmp_1d4f8:
  mov64 r8, r9
  rsh64 r8, 0x20

jmp_1d508:
  lddw r1, 0xffffff00
  mov64 r6, r8
  and64 r6, r1

jmp_1d528:
  and64 r8, 0xff
  or64 r6, r8
  lsh64 r6, 0x20
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  or64 r6, r9
  mov64 r0, r6
  exit

jmp_1d568:
  stxdw [r10-0x330], r4
  stxdw [r10-0x308], r1
  ldxw r1, [r2+0x10]
  stxdw [r10-0x300], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x310], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x318], r1
  ldxdw r7, [r5-0xfe0]
  ldxdw r9, [r5-0xfe8]
  ldxdw r6, [r5-0xff0]
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0x328], r1
  ldxdw r8, [r5-0x1000]
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x338], r3
  mov64 r2, r3
  call fn_28528
  ldxdw r1, [r10-0x58]
  jeq r1, 0x0, jmp_1e958
  stxdw [r10-0x360], r8
  ldxb r4, [r10-0x40]
  jgt r4, 0x7, jmp_1f4a0
  stxdw [r10-0x358], r7
  stxdw [r10-0x368], r6
  ldxdw r2, [r10-0x48]
  mov64 r8, 0x1
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jlt r4, r5, jmp_1f4b8
  ldxdw r7, [r1+0x40]
  sub64 r4, r3
  stxb [r2+0x0], r4
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r6, 0x0
  ldxdw r2, [r10-0x310]
  mov64 r3, 0x0
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r4, [r10-0x318]
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0xb8]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_1d728
  mov64 r1, 0x0

jmp_1d728:
  stxdw [r10-0x350], r9
  ldxdw r2, [r10-0xa8]
  ldxdw r3, [r10-0xc0]
  mov64 r4, r2
  add64 r4, r3
  stxdw [r10-0x320], r4
  jlt r4, r2, jmp_1d768
  mov64 r8, 0x0

jmp_1d768:
  or64 r1, r8
  mov64 r9, 0x17
  and64 r1, 0x1
  jne r1, 0x0, jmp_1e260
  ldxdw r8, [r10-0x300]
  lsh64 r8, 0x20
  arsh64 r8, 0x20
  ldxdw r6, [r10-0xb0]
  stxdw [r10-0x300], r8
  jsle r8, -0x1, jmp_1ddd0
  stxdw [r10-0x340], r6
  mov64 r6, 0x0
  mov64 r7, 0x1
  mov64 r0, 0x0
  jeq r8, 0x0, jmp_1dbe0
  mov64 r1, r8
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1d808
  mov64 r7, 0xa
  jeq r8, 0x1, jmp_1dbe0

jmp_1d808:
  mov64 r1, r8
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1d880
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x148]
  ldxdw r7, [r10-0x150]
  mov64 r1, r8
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1dbe0

jmp_1d880:
  mov64 r1, r8
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1d8f8
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x158]
  ldxdw r7, [r10-0x160]
  mov64 r1, r8
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1dbe0

jmp_1d8f8:
  mov64 r1, r8
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1d970
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r7
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x168]
  ldxdw r7, [r10-0x170]
  mov64 r1, r8
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1dbe0

jmp_1d970:
  mov64 r1, r8
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1d9f0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r7
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0x178]
  ldxdw r7, [r10-0x180]
  mov64 r1, r8
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1dbe0

jmp_1d9f0:
  mov64 r1, r8
  mov64 r8, 0x0
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1d528
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r0
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x348], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  stxdw [r10-0x370], r1
  ldxdw r2, [r10-0x348]
  jne r2, 0x0, jmp_1e538
  mov64 r1, 0x0
  ldxdw r4, [r10-0x198]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1e550

jmp_1db18:
  ldxdw r5, [r10-0x1a8]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_1db38

jmp_1db30:
  mov64 r4, 0x0

jmp_1db38:
  ldxdw r5, [r10-0x1b0]
  ldxdw r0, [r10-0x1a0]
  add64 r0, r5
  ldxdw r2, [r10-0x188]
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, r5
  jlt r0, r2, jmp_1db88
  mov64 r2, 0x0
  stxdw [r10-0x370], r2

jmp_1db88:
  ldxdw r5, [r10-0x300]
  and64 r5, 0x7fffffe0
  jne r5, 0x20, jmp_1d528
  or64 r1, r3
  or64 r1, r4
  ldxdw r2, [r10-0x370]
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d528
  ldxdw r7, [r10-0x190]
  ldxdw r8, [r10-0x300]

jmp_1dbe0:
  mov64 r1, r10
  add64 r1, -0x1e0
  ldxdw r2, [r10-0x320]
  mov64 r3, 0x0
  mov64 r8, r7
  mov64 r4, r8
  mov64 r5, 0x0
  mov64 r7, r0
  stxdw [r10-0x348], r7
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r7, [r10-0x340]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r3, 0x1
  ldxdw r1, [r10-0x348]
  jne r1, 0x0, jmp_1dcc8
  mov64 r3, 0x0

jmp_1dcc8:
  mov64 r2, 0x1
  ldxdw r1, [r10-0x308]
  ldxdw r4, [r10-0x320]
  mov64 r0, 0x1
  jne r4, 0x0, jmp_1dcf8
  mov64 r2, 0x0

jmp_1dcf8:
  and64 r2, r3
  ldxdw r4, [r10-0x1d8]
  mov64 r3, 0x1
  ldxdw r7, [r10-0x300]
  jne r4, 0x0, jmp_1dd28
  mov64 r3, 0x0

jmp_1dd28:
  or64 r2, r3
  ldxdw r4, [r10-0x1c8]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1dd50
  mov64 r3, 0x0

jmp_1dd50:
  or64 r2, r3
  ldxdw r3, [r10-0x1d0]
  ldxdw r4, [r10-0x1e0]
  add64 r4, r3
  ldxdw r5, [r10-0x1b8]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_1dd98
  mov64 r0, 0x0

jmp_1dd98:
  or64 r2, r0
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e260
  ldxdw r4, [r10-0x1c0]
  mov64 r6, 0x0
  jeq r3, 0x0, jmp_1e270
  ja jmp_1e260

jmp_1ddd0:
  jeq r8, -0x80000000, jmp_1f4d0
  mov64 r7, r8
  neg64 r7
  mov64 r1, r7
  and64 r1, 0x1
  mov64 r2, r8
  mov64 r0, 0x0
  jne r1, 0x0, jmp_1de20
  mov64 r8, 0x1
  ja jmp_1de30

jmp_1de20:
  mov64 r8, 0xa
  jeq r2, -0x1, jmp_1e1f8

jmp_1de30:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1dea8
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xc8]
  ldxdw r8, [r10-0xd0]
  mov64 r1, r7
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1e1f8

jmp_1dea8:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1df20
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xd8]
  ldxdw r8, [r10-0xe0]
  mov64 r1, r7
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1e1f8

jmp_1df20:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1df98
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r8
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xe8]
  ldxdw r8, [r10-0xf0]
  mov64 r1, r7
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1e1f8

jmp_1df98:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1e018
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r8
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xf8]
  ldxdw r8, [r10-0x100]
  mov64 r1, r7
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1e1f8

jmp_1e018:
  stxdw [r10-0x340], r6
  mov64 r6, 0x0
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1e260
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r0
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x348], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r3, [r10-0x348]
  jne r3, 0x0, jmp_1e4f8
  mov64 r1, 0x0
  ldxdw r4, [r10-0x118]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1e510

jmp_1e148:
  ldxdw r5, [r10-0x128]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_1e168

jmp_1e160:
  mov64 r4, 0x0

jmp_1e168:
  ldxdw r5, [r10-0x130]
  ldxdw r0, [r10-0x120]
  add64 r0, r5
  ldxdw r5, [r10-0x108]
  mov64 r8, r5
  add64 r8, r0
  mov64 r0, r8
  jlt r0, r5, jmp_1e1b0
  mov64 r2, 0x0

jmp_1e1b0:
  and64 r7, 0x7fffffe0
  jne r7, 0x20, jmp_1e260
  or64 r1, r3
  or64 r1, r4
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_1e260
  ldxdw r8, [r10-0x110]
  ldxdw r6, [r10-0x340]

jmp_1e1f8:
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r6
  ldxdw r3, [r10-0x320]
  mov64 r4, r8
  mov64 r5, r0
  call fn_2c2b0
  ldxdw r3, [r10-0x138]
  ldxdw r4, [r10-0x140]
  ldxdw r1, [r10-0x308]
  ldxdw r7, [r10-0x300]
  mov64 r6, 0x0
  jeq r3, 0x0, jmp_1e270

jmp_1e260:
  mov64 r8, 0x0
  ja jmp_1d528

jmp_1e270:
  ldxdw r5, [r1+0x4a]
  ldxdw r6, [r1+0x42]
  mov64 r3, r6
  add64 r3, r5
  mov64 r8, 0x0
  mov64 r2, 0x1
  jlt r3, r6, jmp_1e2b0
  mov64 r2, 0x0

jmp_1e2b0:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e408
  mov64 r3, r5
  add64 r3, r6
  mov64 r2, r4
  sub64 r2, r3
  mov64 r3, 0x1
  jgt r2, r4, jmp_1e2f8
  mov64 r3, 0x0

jmp_1e2f8:
  stxdw [r10-0x348], r5
  stxdw [r10-0x320], r4
  mov64 r4, 0x0
  jne r3, 0x0, jmp_1e320
  mov64 r4, r2

jmp_1e320:
  stxdw [r10-0x340], r4
  ldxh r2, [r1+0x40]
  mov64 r1, r10
  add64 r1, -0x1f0
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x200
  ldxdw r2, [r10-0x1f0]
  ldxdw r7, [r10-0x1e8]
  mov64 r3, r7
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  ldxdw r1, [r10-0x308]
  ldxdw r0, [r10-0x320]
  jgt r7, 0x270f, jmp_1e408
  ldxdw r2, [r10-0x200]
  ldxdw r7, [r10-0x340]
  mov64 r4, r7
  sub64 r4, r2
  mov64 r3, 0x0
  mov64 r5, 0x1
  jgt r4, r7, jmp_1e420
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_1e428

jmp_1e3f8:
  jge r7, r2, jmp_1e438

jmp_1e400:
  mov64 r8, r3

jmp_1e408:
  mov64 r6, r8
  and64 r6, -0x100
  ja jmp_1d528

jmp_1e420:
  jne r5, 0x0, jmp_1e3f8

jmp_1e428:
  mov64 r3, r4
  jlt r7, r2, jmp_1e400

jmp_1e438:
  mov64 r5, r6
  add64 r5, r3
  mov64 r4, 0x1
  jlt r5, r6, jmp_1e460
  mov64 r4, 0x0

jmp_1e460:
  and64 r4, 0x1
  ldxdw r7, [r10-0x348]
  jne r4, 0x0, jmp_1e408
  mov64 r5, r7
  add64 r5, r2
  mov64 r4, 0x1
  jlt r5, r7, jmp_1e4a0
  mov64 r4, 0x0

jmp_1e4a0:
  add64 r3, r6
  stxdw [r1+0x42], r3
  ldxdw r5, [r10-0x348]
  jeq r4, 0x1, jmp_1e408
  add64 r5, r2
  stxdw [r1+0x4a], r5
  jle r3, r0, jmp_1e578
  mov64 r8, 0x19

jmp_1e4e0:
  mov64 r6, 0x0
  mov64 r9, 0x0
  ja jmp_1d528

jmp_1e4f8:
  ldxdw r4, [r10-0x118]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1e148

jmp_1e510:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x128]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_1e160
  ja jmp_1e168

jmp_1e538:
  ldxdw r4, [r10-0x198]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1db18

jmp_1e550:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x1a8]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_1db30
  ja jmp_1db38

jmp_1e578:
  ldxdw r2, [r10-0x328]
  ldxdw r4, [r2+0x0]
  add64 r1, 0x72
  stxdw [r10-0x80], r1
  lddw r1, str_036a
  stxdw [r10-0xa0], r1
  mov64 r1, r4
  add64 r1, 0x8
  stxdw [r10-0x90], r1
  mov64 r9, 0x3
  stdw [r10-0x78], 0x1
  stdw [r10-0x88], 0x20
  stdw [r10-0x98], 0x5
  ldxdw r1, [r4+0x50]
  jne r1, 0x52, jmp_1d4f8
  ldxdw r1, [r4+0x28]
  lddw r3, -0x6c5e9a281e0922fa
  jne r1, r3, jmp_1e680
  ldxdw r1, [r4+0x30]
  lddw r3, -0x53861431b91e3427
  jne r1, r3, jmp_1e680
  ldxdw r1, [r4+0x38]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r1, r3, jmp_1e680
  mov64 r1, 0x0
  ldxdw r4, [r4+0x40]
  lddw r3, -0x56ff00817a0a73c6
  jeq r4, r3, jmp_1e688

jmp_1e680:
  mov64 r1, 0x1

jmp_1e688:
  mov64 r9, 0x16
  jne r1, 0x0, jmp_1d4f8
  mov64 r1, r10
  add64 r1, -0x58
  call fn_28528
  ldxdw r3, [r10-0x58]
  jeq r3, 0x0, jmp_1e958
  ldxb r1, [r10-0x40]
  jgt r1, 0x7, jmp_1f4a0
  ldxdw r4, [r10-0x48]
  mov64 r2, 0x1
  mov64 r5, 0x1
  lsh64 r5, r1
  mov64 r6, r5
  and64 r6, 0xff
  ldxb r0, [r4+0x0]
  ldxdw r1, [r10-0x308]
  jlt r0, r6, jmp_1f4b8
  ldxb r8, [r3+0x2c]
  ldxdw r9, [r3+0x24]
  sub64 r0, r5
  stxb [r4+0x0], r0
  jeq r8, 0x0, jmp_1e8b8
  mov64 r3, r8
  and64 r3, 0x1
  jeq r3, 0x0, jmp_1e768
  mov64 r2, 0xa
  jeq r8, 0x1, jmp_1e8b8

jmp_1e768:
  mov64 r3, r8
  and64 r3, 0x2
  jeq r3, 0x0, jmp_1e7a0
  mul64 r2, 0x64
  mov64 r3, r8
  and64 r3, 0xfe
  jeq r3, 0x2, jmp_1e8b8

jmp_1e7a0:
  mov64 r3, r8
  and64 r3, 0x4
  jeq r3, 0x0, jmp_1e7d8
  mul64 r2, 0x2710
  mov64 r3, r8
  and64 r3, 0xfc
  jeq r3, 0x4, jmp_1e8b8

jmp_1e7d8:
  mov64 r3, r8
  and64 r3, 0x8
  jeq r3, 0x0, jmp_1e810
  mul64 r2, 0x5f5e100
  mov64 r3, r8
  and64 r3, 0xf8
  jeq r3, 0x8, jmp_1e8b8

jmp_1e810:
  mov64 r1, r8
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1f4e8
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r3, 0x0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x208]
  jne r2, 0x0, jmp_1e880
  mov64 r1, 0x0

jmp_1e880:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1f4e8
  mov64 r1, r8
  and64 r1, 0xf0
  jne r1, 0x10, jmp_1f4e8
  ldxdw r2, [r10-0x210]
  ldxdw r1, [r10-0x308]

jmp_1e8b8:
  mov64 r7, r2
  add64 r7, r9
  mov64 r6, 0x0
  mov64 r3, 0x1
  jlt r7, r9, jmp_1e8e8
  mov64 r3, 0x0

jmp_1e8e8:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1e940
  ldxdw r3, [r1+0x42]
  mov64 r5, r3
  add64 r5, r2
  mov64 r4, 0x1
  stxdw [r10-0x328], r5
  jlt r5, r3, jmp_1e930
  mov64 r4, 0x0

jmp_1e930:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_1e968

jmp_1e940:
  mov64 r8, 0x0
  mov64 r9, 0x17
  ja jmp_1d528

jmp_1e958:
  ldxdw r9, [r10-0x50]
  ja jmp_1d4f8

jmp_1e968:
  stxdw [r10-0x340], r9
  stxdw [r10-0x348], r8
  ldxdw r1, [r1+0x4a]
  ldxdw r0, [r10-0x320]
  mov64 r4, r0
  sub64 r4, r1
  mov64 r5, 0x1
  jgt r4, r0, jmp_1e9e0
  mov64 r5, 0x0
  mov64 r1, 0x0
  jeq r5, 0x0, jmp_1e9f0

jmp_1e9c0:
  jlt r1, r3, jmp_1ea00

jmp_1e9c8:
  mov64 r1, r3
  jeq r1, 0x0, jmp_1ea08
  ja jmp_1ea28

jmp_1e9e0:
  mov64 r1, 0x0
  jne r5, 0x0, jmp_1e9c0

jmp_1e9f0:
  mov64 r1, r4
  jge r1, r3, jmp_1e9c8

jmp_1ea00:
  jne r1, 0x0, jmp_1ea28

jmp_1ea08:
  mov64 r8, 0x19
  mov64 r9, 0x0
  ldxdw r3, [r10-0x340]
  jne r3, 0x0, jmp_1d528

jmp_1ea28:
  mov64 r3, r1
  add64 r3, r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_1ea50
  mov64 r2, 0x0

jmp_1ea50:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e940
  jeq r7, 0x0, jmp_1e940
  mov64 r1, r10
  add64 r1, -0x220
  mov64 r2, r3
  mov64 r3, 0x0
  ldxdw r4, [r10-0x350]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x230
  ldxdw r2, [r10-0x220]
  ldxdw r3, [r10-0x218]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c2b0
  ldxdw r8, [r10-0x228]
  jne r8, 0x0, jmp_1e940
  ldxdw r1, [r10-0x230]
  stxdw [r10-0x320], r1
  mov64 r1, r10
  add64 r1, -0x240
  ldxdw r2, [r10-0x328]
  mov64 r3, 0x0
  ldxdw r4, [r10-0x350]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x250
  ldxdw r2, [r10-0x240]
  ldxdw r3, [r10-0x238]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c2b0
  ldxdw r1, [r10-0x248]
  jne r1, 0x0, jmp_1e940
  ldxdw r1, [r10-0x250]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x300]
  jslt r1, 0x0, jmp_1ed10
  mov64 r1, r10
  add64 r1, -0x58
  ldxdw r2, [r10-0x300]
  call fn_02a8
  ldxdw r1, [r10-0x58]
  jeq r1, 0x0, jmp_1e940
  mov64 r1, r10
  add64 r1, -0x2c0
  ldxdw r4, [r10-0x50]
  stxdw [r10-0x300], r4
  ldxdw r2, [r10-0x310]
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2b0
  ldxdw r9, [r10-0x48]
  mov64 r2, r9
  mov64 r3, 0x0
  ldxdw r7, [r10-0x318]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2a0
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r4, [r10-0x300]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  mov64 r3, 0x1
  jne r9, 0x0, jmp_1ee78
  mov64 r3, 0x0
  mov64 r2, 0x1
  ldxdw r4, [r10-0x310]
  jeq r4, 0x0, jmp_1ee90

jmp_1ecc0:
  and64 r2, r3
  ldxdw r4, [r10-0x2b8]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1eeb8

jmp_1ece0:
  mov64 r3, 0x0
  or64 r2, r3
  ldxdw r4, [r10-0x2a8]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1eed8
  ja jmp_1eee0

jmp_1ed10:
  ldxdw r2, [r10-0x300]
  neg64 r2
  mov64 r1, r10
  add64 r1, -0x58
  call fn_02a8
  ldxdw r1, [r10-0x58]
  jne r1, 0x1, jmp_1e940
  mov64 r1, r10
  add64 r1, -0x280
  ldxdw r4, [r10-0x50]
  stxdw [r10-0x300], r4
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x270
  ldxdw r9, [r10-0x48]
  mov64 r2, r9
  mov64 r3, 0x0
  ldxdw r7, [r10-0x320]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x260
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r4, [r10-0x300]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  mov64 r4, 0x1
  jne r9, 0x0, jmp_1ef98
  mov64 r4, 0x0
  mov64 r2, 0x1
  jeq r8, 0x0, jmp_1efa8

jmp_1ee38:
  ldxdw r3, [r10-0x278]
  mov64 r5, 0x1
  jne r3, 0x0, jmp_1efc8

jmp_1ee50:
  mov64 r5, 0x0
  ldxdw r3, [r10-0x268]
  mov64 r0, 0x1
  jeq r3, 0x0, jmp_1efe0
  ja jmp_1efe8

jmp_1ee78:
  mov64 r2, 0x1
  ldxdw r4, [r10-0x310]
  jne r4, 0x0, jmp_1ecc0

jmp_1ee90:
  mov64 r2, 0x0
  and64 r2, r3
  ldxdw r4, [r10-0x2b8]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_1ece0

jmp_1eeb8:
  or64 r2, r3
  ldxdw r4, [r10-0x2a8]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1eee0

jmp_1eed8:
  mov64 r3, 0x0

jmp_1eee0:
  or64 r2, r3
  ldxdw r3, [r10-0x2b0]
  ldxdw r4, [r10-0x2c0]
  add64 r4, r3
  ldxdw r3, [r10-0x298]
  mov64 r5, r3
  add64 r5, r4
  jlt r5, r3, jmp_1ef28
  mov64 r1, 0x0

jmp_1ef28:
  or64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e940
  ldxdw r4, [r10-0x2a0]
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_1e940
  mov64 r1, r10
  add64 r1, -0x2d0
  ldxdw r2, [r10-0x320]
  mov64 r3, r8
  call fn_2c2b0
  ldxdw r6, [r10-0x2d0]
  ja jmp_1f0c0

jmp_1ef98:
  mov64 r2, 0x1
  jne r8, 0x0, jmp_1ee38

jmp_1efa8:
  mov64 r2, 0x0
  ldxdw r3, [r10-0x278]
  mov64 r5, 0x1
  jeq r3, 0x0, jmp_1ee50

jmp_1efc8:
  ldxdw r3, [r10-0x268]
  mov64 r0, 0x1
  jne r3, 0x0, jmp_1efe8

jmp_1efe0:
  mov64 r0, 0x0

jmp_1efe8:
  ldxdw r3, [r10-0x270]
  ldxdw r7, [r10-0x280]
  add64 r7, r3
  ldxdw r8, [r10-0x258]
  mov64 r3, r8
  add64 r3, r7
  jlt r3, r8, jmp_1f028
  mov64 r1, 0x0

jmp_1f028:
  ldxdw r7, [r10-0x318]
  ldxdw r8, [r10-0x310]
  or64 r7, r8
  jeq r7, 0x0, jmp_1e940
  and64 r2, r4
  or64 r2, r5
  or64 r2, r0
  or64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e940
  ldxdw r2, [r10-0x260]
  mov64 r1, r10
  add64 r1, -0x290
  ldxdw r4, [r10-0x318]
  ldxdw r5, [r10-0x310]
  call fn_2c2b0
  ldxdw r1, [r10-0x288]
  jne r1, 0x0, jmp_1e940
  ldxdw r6, [r10-0x290]

jmp_1f0c0:
  ldxdw r1, [r10-0x358]
  jge r6, r1, jmp_1f1f0
  lddw r1, str_0468
  mov64 r2, 0x11
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x2e8
  mov64 r3, r10
  add64 r3, -0x70
  mov64 r2, r6
  mov64 r4, 0x14
  call fn_29b88
  ldxdw r3, [r10-0x2e0]
  ldxdw r2, [r10-0x2e8]
  mov64 r1, r10
  add64 r1, -0x58
  call fn_0810
  ldxdw r2, [r10-0x48]
  ldxdw r1, [r10-0x50]
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x2f8
  mov64 r3, r10
  add64 r3, -0x70
  ldxdw r2, [r10-0x358]
  mov64 r4, 0x14
  call fn_29b88
  ldxdw r3, [r10-0x2f0]
  ldxdw r2, [r10-0x2f8]
  mov64 r1, r10
  add64 r1, -0x58
  call fn_0810
  ldxdw r2, [r10-0x48]
  ldxdw r1, [r10-0x50]
  call sol_log_
  mov64 r8, 0xf
  ja jmp_1e4e0

jmp_1f1f0:
  mov64 r1, r10
  add64 r1, -0x58
  ldxdw r2, [r10-0x360]
  call fn_0000
  ldxw r8, [r10-0x4c]
  ldxw r9, [r10-0x50]
  ldxdw r1, [r10-0x58]
  jeq r1, 0x0, jmp_1d508
  lsh64 r8, 0x20
  or64 r8, r9
  ldxdw r2, [r10-0x48]
  ldxb r7, [r1+0x2c]
  mov64 r1, r8
  call fn_0788
  stxb [r10-0x30], r7
  stxdw [r10-0x38], r6
  ldxdw r1, [r10-0x368]
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0x360]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x58], r1
  mov64 r1, r10
  add64 r1, -0xa0
  stxdw [r10-0x70], r1
  stdw [r10-0x68], 0x3
  mov64 r1, r10
  add64 r1, -0x2d8
  mov64 r2, r10
  add64 r2, -0x58
  mov64 r3, r10
  add64 r3, -0x70
  mov64 r4, 0x1
  call fn_276f0
  ldxw r9, [r10-0x2d8]
  jne r9, 0x1a, jmp_1f490
  ldxdw r1, [r10-0x330]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r10-0x368]
  ldxdw r2, [r2+0x0]
  stb [r10-0x58], 0x2
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x57], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x4f], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x47], r3
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x3f], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x37], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2f], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x27], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x1f], r1
  stxdw [r10-0xf], r6
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x17], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x70], r1
  stdw [r10-0x68], 0x51
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0x1
  call fn_287e0
  mov64 r6, 0x0
  ldxdw r1, [r10-0x308]
  ldxdw r1, [r1+0x42]
  mov64 r8, 0x0
  mov64 r9, 0x17
  ldxdw r2, [r10-0x328]
  jlt r1, r2, jmp_1d528
  ldxdw r2, [r10-0x328]
  sub64 r1, r2
  ldxdw r2, [r10-0x308]
  stxdw [r2+0x42], r1
  mov64 r9, 0x1a
  ldxdw r8, [r10-0x348]
  ja jmp_1d528

jmp_1f490:
  ldxw r8, [r10-0x2d4]
  ja jmp_1e408

jmp_1f4a0:
  lddw r1, data_0810
  call fn_29a40

jmp_1f4b8:
  lddw r1, data_0828
  call fn_29938

jmp_1f4d0:
  lddw r1, data_0e20
  call fn_299e8

jmp_1f4e8:
  lddw r1, data_07e0
  call fn_29990

fn_1f500:
  mov64 r7, r4
  mov64 r6, r1
  mov64 r8, 0x3
  ldxdw r1, [r7+0x0]
  ldxdw r4, [r1+0x50]
  jne r4, 0xa5, jmp_1f5c8
  ldxdw r4, [r1+0x28]
  lddw r0, -0x6c5e9a281e0922fa
  jne r4, r0, jmp_1f5b8
  ldxdw r4, [r1+0x30]
  lddw r0, -0x53861431b91e3427
  jne r4, r0, jmp_1f5b8
  ldxdw r4, [r1+0x38]
  lddw r0, -0x6ec8a4a0127a4be4
  jne r4, r0, jmp_1f5b8
  mov64 r4, 0x0
  ldxdw r1, [r1+0x40]
  lddw r0, -0x56ff00817a0a73c6
  jeq r1, r0, jmp_1f5c0

jmp_1f5b8:
  mov64 r4, 0x1

jmp_1f5c0:
  jeq r4, 0x0, jmp_1f5f0

jmp_1f5c8:
  mov64 r7, r8
  rsh64 r7, 0x20

jmp_1f5d8:
  stxw [r6+0x4], r7
  stxw [r6+0x0], r8
  exit

jmp_1f5f0:
  stxdw [r10-0x360], r2
  ldxw r9, [r3+0x10]
  ldxdw r8, [r5-0xff0]
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0x378], r1
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0x380], r1
  ldxdw r1, [r3+0x8]
  stxdw [r10-0x350], r1
  ldxdw r1, [r3+0x0]
  stxdw [r10-0x358], r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r7
  call fn_28528
  ldxdw r1, [r10-0x60]
  jeq r1, 0x0, jmp_1fe20
  stxdw [r10-0x398], r8
  ldxb r4, [r10-0x48]
  jgt r4, 0x7, jmp_218a0
  stxdw [r10-0x368], r6
  stxdw [r10-0x3a0], r7
  ldxdw r2, [r10-0x50]
  mov64 r8, 0x1
  mov64 r3, 0x1
  lsh64 r3, r4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jlt r4, r5, jmp_218b8
  ldxdw r6, [r1+0x40]
  sub64 r4, r3
  stxb [r2+0x0], r4
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r7, 0x0
  ldxdw r2, [r10-0x350]
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xa0
  stxdw [r10-0x390], r6
  mov64 r2, r6
  mov64 r3, 0x0
  ldxdw r4, [r10-0x358]
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0xa8]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_1f798
  mov64 r1, 0x0

jmp_1f798:
  ldxdw r2, [r10-0x98]
  ldxdw r3, [r10-0xb0]
  mov64 r4, r2
  add64 r4, r3
  stxdw [r10-0x370], r4
  jlt r4, r2, jmp_1f7d0
  mov64 r8, 0x0

jmp_1f7d0:
  or64 r1, r8
  mov64 r8, 0x17
  and64 r1, 0x1
  ldxdw r6, [r10-0x368]
  jne r1, 0x0, jmp_1f5d8
  mov64 r2, r9
  lsh64 r2, 0x20
  arsh64 r2, 0x20
  ldxdw r9, [r10-0xa0]
  stxdw [r10-0x388], r2
  jsle r2, -0x1, jmp_1fe30
  mov64 r4, 0x1
  mov64 r0, 0x0
  jeq r2, 0x0, jmp_1fc50
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1f868
  mov64 r4, 0xa
  jeq r2, 0x1, jmp_1fc50

jmp_1f868:
  mov64 r1, r2
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1f8e8
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r0, [r10-0x138]
  ldxdw r4, [r10-0x140]
  mov64 r1, r2
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_1fc50

jmp_1f8e8:
  mov64 r1, r2
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1f968
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r0, [r10-0x148]
  ldxdw r4, [r10-0x150]
  mov64 r1, r2
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_1fc50

jmp_1f968:
  mov64 r1, r2
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1f9e8
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r0, [r10-0x158]
  ldxdw r4, [r10-0x160]
  mov64 r1, r2
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_1fc50

jmp_1f9e8:
  mov64 r1, r2
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1fa70
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r4
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r0, [r10-0x168]
  ldxdw r4, [r10-0x170]
  mov64 r1, r2
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_1fc50

jmp_1fa70:
  mov64 r1, r2
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1f5d8
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r0
  mov64 r3, 0x0
  mov64 r8, r4
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x3a8], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r3, [r10-0x3a8]
  jne r3, 0x0, jmp_20558
  mov64 r1, 0x0
  ldxdw r4, [r10-0x188]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_20570

jmp_1fb98:
  ldxdw r5, [r10-0x198]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_1fbb8

jmp_1fbb0:
  mov64 r4, 0x0

jmp_1fbb8:
  ldxdw r5, [r10-0x1a0]
  ldxdw r0, [r10-0x190]
  add64 r0, r5
  ldxdw r5, [r10-0x178]
  mov64 r8, r5
  add64 r8, r0
  mov64 r0, r8
  jlt r0, r5, jmp_1fc00
  mov64 r2, 0x0

jmp_1fc00:
  ldxdw r5, [r10-0x388]
  and64 r5, 0x7fffffe0
  mov64 r8, 0x17
  jne r5, 0x20, jmp_1f5d8
  or64 r1, r3
  or64 r1, r4
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_1f5d8
  ldxdw r4, [r10-0x180]

jmp_1fc50:
  mov64 r1, r10
  add64 r1, -0x1d0
  ldxdw r2, [r10-0x370]
  mov64 r3, 0x0
  mov64 r6, r4
  mov64 r5, 0x0
  mov64 r8, r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r3, 0x1
  jne r8, 0x0, jmp_1fd18
  mov64 r3, 0x0

jmp_1fd18:
  mov64 r2, 0x1
  ldxdw r1, [r10-0x360]
  ldxdw r4, [r10-0x370]
  mov64 r0, 0x1
  jne r4, 0x0, jmp_1fd48
  mov64 r2, 0x0

jmp_1fd48:
  and64 r2, r3
  ldxdw r4, [r10-0x1c8]
  mov64 r3, 0x1
  mov64 r8, 0x17
  ldxdw r6, [r10-0x368]
  jne r4, 0x0, jmp_1fd80
  mov64 r3, 0x0

jmp_1fd80:
  or64 r2, r3
  ldxdw r4, [r10-0x1b8]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1fda8
  mov64 r3, 0x0

jmp_1fda8:
  or64 r2, r3
  ldxdw r3, [r10-0x1c0]
  ldxdw r4, [r10-0x1d0]
  add64 r4, r3
  ldxdw r5, [r10-0x1a8]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_1fdf0
  mov64 r0, 0x0

jmp_1fdf0:
  or64 r2, r0
  and64 r2, 0x1
  jne r2, 0x0, jmp_1f5d8
  ldxdw r4, [r10-0x1b0]
  jne r3, 0x0, jmp_1f5d8
  ja jmp_20298

jmp_1fe20:
  ldxdw r8, [r10-0x58]
  ja jmp_1f5c8

jmp_1fe30:
  stxdw [r10-0x3a8], r9
  jeq r2, -0x80000000, jmp_218d0
  mov64 r9, r2
  neg64 r9
  mov64 r1, r9
  mov64 r0, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_1fe80
  mov64 r4, 0x1
  ja jmp_1fe90

jmp_1fe80:
  mov64 r4, 0xa
  jeq r2, -0x1, jmp_20248

jmp_1fe90:
  mov64 r1, r9
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1ff08
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xb8]
  ldxdw r4, [r10-0xc0]
  mov64 r1, r9
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_20248

jmp_1ff08:
  mov64 r1, r9
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1ff80
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xc8]
  ldxdw r4, [r10-0xd0]
  mov64 r1, r9
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_20248

jmp_1ff80:
  mov64 r1, r9
  and64 r1, 0x8
  jeq r1, 0x0, jmp_1fff8
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r4
  mov64 r3, r0
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xd8]
  ldxdw r4, [r10-0xe0]
  mov64 r1, r9
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_20248

jmp_1fff8:
  mov64 r1, r9
  and64 r1, 0x10
  jeq r1, 0x0, jmp_20078
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r4
  mov64 r3, r0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r0, [r10-0xe8]
  ldxdw r4, [r10-0xf0]
  mov64 r1, r9
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_20248

jmp_20078:
  mov64 r1, r9
  and64 r1, 0x20
  jeq r1, 0x0, jmp_1f5d8
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r0
  mov64 r3, 0x0
  stxdw [r10-0x3b0], r4
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  stxdw [r10-0x3b8], r0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x120
  ldxdw r2, [r10-0x3b0]
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x100
  ldxdw r2, [r10-0x3b0]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x3b8]
  jne r2, 0x0, jmp_20518
  mov64 r1, 0x0
  ldxdw r4, [r10-0x108]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_20530

jmp_20198:
  ldxdw r5, [r10-0x118]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_201b8

jmp_201b0:
  mov64 r4, 0x0

jmp_201b8:
  ldxdw r5, [r10-0x120]
  ldxdw r0, [r10-0x110]
  add64 r0, r5
  ldxdw r2, [r10-0xf8]
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, r5
  mov64 r5, 0x1
  jlt r0, r2, jmp_20208
  mov64 r5, 0x0

jmp_20208:
  and64 r9, 0x7fffffe0
  jne r9, 0x20, jmp_1f5d8
  or64 r1, r3
  or64 r1, r4
  or64 r1, r5
  and64 r1, 0x1
  jne r1, 0x0, jmp_1f5d8
  ldxdw r4, [r10-0x100]

jmp_20248:
  mov64 r1, r10
  add64 r1, -0x130
  ldxdw r2, [r10-0x3a8]
  ldxdw r3, [r10-0x370]
  mov64 r5, r0
  call fn_2c2b0
  ldxdw r3, [r10-0x128]
  ldxdw r4, [r10-0x130]
  ldxdw r1, [r10-0x360]
  jne r3, 0x0, jmp_1f5d8

jmp_20298:
  ldxdw r5, [r1+0x4a]
  ldxdw r0, [r1+0x42]
  mov64 r3, r0
  add64 r3, r5
  mov64 r2, 0x1
  jlt r3, r0, jmp_202d0
  mov64 r2, 0x0

jmp_202d0:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1f5d8
  mov64 r3, r5
  add64 r3, r0
  mov64 r2, r4
  sub64 r2, r3
  mov64 r3, 0x1
  jgt r2, r4, jmp_20318
  mov64 r3, 0x0

jmp_20318:
  stxdw [r10-0x3a8], r0
  stxdw [r10-0x370], r5
  stxdw [r10-0x3b8], r4
  mov64 r4, 0x0
  jne r3, 0x0, jmp_20348
  mov64 r4, r2

jmp_20348:
  stxdw [r10-0x3b0], r4
  ldxh r2, [r1+0x40]
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x1f0
  ldxdw r2, [r10-0x1e0]
  ldxdw r9, [r10-0x1d8]
  mov64 r3, r9
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c2b0
  jgt r9, 0x270f, jmp_1f5d8
  ldxdw r1, [r10-0x1f0]
  ldxdw r9, [r10-0x3b0]
  mov64 r3, r9
  sub64 r3, r1
  mov64 r4, 0x1
  jgt r3, r9, jmp_20430
  mov64 r4, 0x0
  ldxdw r2, [r10-0x360]
  ldxdw r5, [r10-0x370]
  ldxdw r0, [r10-0x3a8]
  jeq r4, 0x0, jmp_20450

jmp_20420:
  jlt r9, r1, jmp_1f5d8
  ja jmp_20460

jmp_20430:
  ldxdw r2, [r10-0x360]
  ldxdw r5, [r10-0x370]
  ldxdw r0, [r10-0x3a8]
  jne r4, 0x0, jmp_20420

jmp_20450:
  mov64 r7, r3
  jlt r9, r1, jmp_1f5d8

jmp_20460:
  mov64 r4, r0
  add64 r4, r7
  mov64 r3, 0x1
  jlt r4, r0, jmp_20488
  mov64 r3, 0x0

jmp_20488:
  and64 r3, 0x1
  jne r3, 0x0, jmp_20eb8
  mov64 r4, r5
  add64 r4, r1
  mov64 r3, 0x1
  jlt r4, r5, jmp_204c0
  mov64 r3, 0x0

jmp_204c0:
  add64 r7, r0
  stxdw [r2+0x42], r7
  and64 r3, 0x1
  jne r3, 0x0, jmp_20eb8
  add64 r5, r1
  stxdw [r2+0x4a], r5
  ldxdw r1, [r10-0x3b8]
  jle r7, r1, jmp_20598
  mov64 r8, 0x0
  mov64 r7, 0x19
  ja jmp_1f5d8

jmp_20518:
  ldxdw r4, [r10-0x108]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_20198

jmp_20530:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x118]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_201b0
  ja jmp_201b8

jmp_20558:
  ldxdw r4, [r10-0x188]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_1fb98

jmp_20570:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x198]
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_1fbb0
  ja jmp_1fbb8

jmp_20598:
  ldxdw r2, [r10-0x388]
  jslt r2, 0x0, jmp_20cc0
  mov64 r4, 0x1
  mov64 r9, 0x0
  jeq r2, 0x0, jmp_20998
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_205e8
  mov64 r4, 0xa
  jeq r2, 0x1, jmp_20998

jmp_205e8:
  mov64 r1, r2
  and64 r1, 0x2
  jeq r1, 0x0, jmp_20668
  mov64 r1, r10
  add64 r1, -0x230
  mov64 r2, r4
  mov64 r3, r9
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r9, [r10-0x228]
  ldxdw r4, [r10-0x230]
  mov64 r1, r2
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_20998

jmp_20668:
  mov64 r1, r2
  and64 r1, 0x4
  jeq r1, 0x0, jmp_206e8
  mov64 r1, r10
  add64 r1, -0x240
  mov64 r2, r4
  mov64 r3, r9
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r9, [r10-0x238]
  ldxdw r4, [r10-0x240]
  mov64 r1, r2
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_20998

jmp_206e8:
  mov64 r1, r2
  and64 r1, 0x8
  jeq r1, 0x0, jmp_20768
  mov64 r1, r10
  add64 r1, -0x250
  mov64 r2, r4
  mov64 r3, r9
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r9, [r10-0x248]
  ldxdw r4, [r10-0x250]
  mov64 r1, r2
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_20998

jmp_20768:
  mov64 r1, r2
  and64 r1, 0x10
  jeq r1, 0x0, jmp_207f0
  mov64 r1, r10
  add64 r1, -0x260
  mov64 r2, r4
  mov64 r3, r9
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x388]
  ldxdw r9, [r10-0x258]
  ldxdw r4, [r10-0x260]
  mov64 r1, r2
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_20998

jmp_207f0:
  mov64 r1, r2
  and64 r1, 0x20
  jeq r1, 0x0, jmp_20eb8
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r9
  mov64 r3, 0x0
  stxdw [r10-0x370], r4
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x290
  ldxdw r2, [r10-0x370]
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x270
  ldxdw r2, [r10-0x370]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  mov64 r1, 0x1
  jne r9, 0x0, jmp_21360
  mov64 r1, 0x0
  ldxdw r4, [r10-0x278]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_21378

jmp_20908:
  or64 r1, r3
  ldxdw r4, [r10-0x288]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_20930

jmp_20928:
  mov64 r3, 0x0

jmp_20930:
  or64 r1, r3
  ldxdw r3, [r10-0x290]
  ldxdw r4, [r10-0x280]
  add64 r4, r3
  ldxdw r3, [r10-0x268]
  mov64 r9, r3
  add64 r9, r4
  jlt r9, r3, jmp_20978
  mov64 r2, 0x0

jmp_20978:
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_20eb8
  ldxdw r4, [r10-0x270]

jmp_20998:
  stxdw [r10-0x3a8], r9
  mov64 r1, r10
  add64 r1, -0x2c0
  ldxdw r2, [r10-0x350]
  mov64 r3, 0x0
  stxdw [r10-0x370], r4
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2b0
  mov64 r2, r9
  mov64 r3, 0x0
  ldxdw r9, [r10-0x358]
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2a0
  mov64 r2, r9
  mov64 r3, 0x0
  ldxdw r4, [r10-0x370]
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  ldxdw r1, [r10-0x3a8]
  jne r1, 0x0, jmp_20a70
  mov64 r2, 0x0

jmp_20a70:
  mov64 r1, 0x1
  ldxdw r3, [r10-0x350]
  jne r3, 0x0, jmp_20a90
  mov64 r1, 0x0

jmp_20a90:
  and64 r1, r2
  ldxdw r3, [r10-0x2b8]
  mov64 r2, 0x1
  mov64 r4, 0x1
  jne r3, 0x0, jmp_20ac0
  mov64 r2, 0x0

jmp_20ac0:
  or64 r1, r2
  ldxdw r3, [r10-0x2a8]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_20ae8
  mov64 r2, 0x0

jmp_20ae8:
  or64 r1, r2
  ldxdw r2, [r10-0x2b0]
  ldxdw r3, [r10-0x2c0]
  add64 r3, r2
  ldxdw r2, [r10-0x298]
  mov64 r5, r2
  add64 r5, r3
  jlt r5, r2, jmp_20b30
  mov64 r4, 0x0

jmp_20b30:
  or64 r1, r4
  and64 r1, 0x1
  jne r1, 0x0, jmp_20eb8
  ldxdw r4, [r10-0x2a0]
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_20eb8
  mov64 r1, r4
  add64 r1, -0x1
  mov64 r3, r7
  add64 r3, r1
  mov64 r0, 0x1
  mov64 r2, 0x1
  jlt r3, r7, jmp_20ba8
  mov64 r2, 0x0

jmp_20ba8:
  jeq r4, 0x0, jmp_20bb8
  mov64 r0, 0x0

jmp_20bb8:
  mov64 r3, r5
  sub64 r3, r0
  mov64 r0, r3
  add64 r0, r2
  jeq r0, 0x0, jmp_20be8
  mov64 r2, 0x0

jmp_20be8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_20eb8
  mov64 r2, r1
  add64 r2, r7
  mov64 r0, 0x1
  jlt r2, r1, jmp_20c20
  mov64 r0, 0x0

jmp_20c20:
  add64 r3, r0
  mov64 r1, r10
  add64 r1, -0x2d0
  call fn_2c2b0
  ldxdw r0, [r10-0x2c8]
  ldxdw r9, [r10-0x2d0]
  mov64 r7, 0x0
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r10-0x378]
  jne r0, 0x0, jmp_1f5d8

jmp_20c70:
  ldxdw r5, [r10-0x390]
  mov64 r4, r5
  sub64 r4, r9
  mov64 r3, 0x1
  jgt r4, r5, jmp_20ec8
  mov64 r3, 0x0
  jeq r3, 0x0, jmp_20ed0

jmp_20ca8:
  ldxdw r3, [r10-0x390]
  jlt r3, r9, jmp_1f5d8
  ja jmp_20ee8

jmp_20cc0:
  neg64 r2
  mov64 r1, r10
  add64 r1, -0x60
  call fn_02a8
  ldxdw r1, [r10-0x60]
  jne r1, 0x1, jmp_20eb8
  mov64 r1, r10
  add64 r1, -0x210
  ldxdw r2, [r10-0x50]
  mov64 r3, 0x0
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x200
  ldxdw r4, [r10-0x58]
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  ldxdw r3, [r10-0x208]
  mov64 r1, 0x1
  jne r3, 0x0, jmp_20d88
  mov64 r1, 0x0

jmp_20d88:
  ldxdw r4, [r10-0x210]
  ldxdw r5, [r10-0x1f8]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_20db8
  mov64 r2, 0x0

jmp_20db8:
  ldxdw r4, [r10-0x358]
  ldxdw r5, [r10-0x350]
  or64 r4, r5
  jeq r4, 0x0, jmp_20eb8
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_20eb8
  ldxdw r1, [r10-0x200]
  mov64 r7, 0x0
  mov64 r2, 0x1
  mov64 r5, 0x1
  ldxdw r4, [r10-0x358]
  jeq r4, 0x0, jmp_20e28
  mov64 r5, 0x0

jmp_20e28:
  ldxdw r4, [r10-0x350]
  sub64 r4, r5
  ldxdw r5, [r10-0x358]
  add64 r5, -0x1
  mov64 r9, r1
  add64 r9, r5
  mov64 r0, 0x1
  jlt r9, r1, jmp_21288
  mov64 r0, 0x0
  mov64 r9, r3
  add64 r9, r4
  add64 r9, r0
  jge r9, r3, jmp_212a8

jmp_20e90:
  jeq r9, r3, jmp_212b8

jmp_20e98:
  mov64 r0, r2
  and64 r0, 0x1
  jne r0, 0x0, jmp_1f5d8
  ja jmp_212c8

jmp_20eb8:
  mov64 r7, 0x0
  ja jmp_1f5d8

jmp_20ec8:
  jne r3, 0x0, jmp_20ca8

jmp_20ed0:
  mov64 r7, r4
  ldxdw r3, [r10-0x390]
  jlt r3, r9, jmp_1f5d8

jmp_20ee8:
  stxdw [r10-0x370], r0
  lddw r3, str_036a
  stxdw [r10-0x90], r3
  stxdw [r10-0x80], r1
  add64 r1, 0x72
  stxdw [r10-0x70], r1
  stdw [r10-0x68], 0x1
  stdw [r10-0x78], 0x20
  stdw [r10-0x88], 0x5
  mov64 r1, r10
  add64 r1, -0x60
  call fn_0000
  ldxw r1, [r10-0x54]
  ldxw r8, [r10-0x58]
  ldxdw r3, [r10-0x60]
  jeq r3, 0x0, jmp_213a8
  lsh64 r1, 0x20
  or64 r1, r8
  ldxdw r2, [r10-0x50]
  ldxb r8, [r3+0x2c]
  call fn_0788
  stxb [r10-0x38], r8
  stxdw [r10-0x40], r7
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x378]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x3a0]
  stxdw [r10-0x60], r1
  mov64 r1, r10
  add64 r1, -0x90
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x2d8
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r3, r10
  add64 r3, -0x10
  mov64 r4, 0x1
  call fn_276f0
  ldxw r8, [r10-0x2d8]
  jne r8, 0x1a, jmp_213b8
  ldxdw r1, [r10-0x380]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r10-0x398]
  ldxdw r2, [r2+0x0]
  stb [r10-0x60], 0x3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x5f], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x57], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x4f], r3
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x47], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x3f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x37], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x2f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x27], r1
  stxdw [r10-0x1f], r7
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x49
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0x1
  call fn_287e0
  mov64 r1, r10
  add64 r1, -0x308
  mov64 r7, 0x0
  ldxdw r2, [r10-0x370]
  mov64 r3, 0x0
  ldxdw r6, [r10-0x358]
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2f8
  ldxdw r8, [r10-0x350]
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x2e8
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r2, 0x1
  jne r8, 0x0, jmp_213c8
  mov64 r2, 0x0
  mov64 r1, 0x1
  ldxdw r3, [r10-0x370]
  jeq r3, 0x0, jmp_213e0

jmp_21238:
  and64 r1, r2
  ldxdw r3, [r10-0x300]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_21408

jmp_21258:
  mov64 r2, 0x0
  or64 r1, r2
  ldxdw r3, [r10-0x2f0]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_21428
  ja jmp_21430

jmp_21288:
  mov64 r9, r3
  add64 r9, r4
  add64 r9, r0
  jlt r9, r3, jmp_20e90

jmp_212a8:
  mov64 r2, 0x0
  jne r9, r3, jmp_20e98

jmp_212b8:
  and64 r0, 0x1
  jne r0, 0x0, jmp_1f5d8

jmp_212c8:
  mov64 r2, r1
  add64 r2, r5
  mov64 r5, 0x1
  jlt r2, r1, jmp_212f0
  mov64 r5, 0x0

jmp_212f0:
  add64 r3, r4
  add64 r3, r5
  mov64 r1, r10
  add64 r1, -0x220
  ldxdw r4, [r10-0x358]
  ldxdw r5, [r10-0x350]
  call fn_2c2b0
  ldxdw r0, [r10-0x218]
  ldxdw r9, [r10-0x220]
  mov64 r7, 0x0
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r10-0x378]
  jne r0, 0x0, jmp_1f5d8
  ja jmp_20c70

jmp_21360:
  ldxdw r4, [r10-0x278]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_20908

jmp_21378:
  mov64 r3, 0x0
  or64 r1, r3
  ldxdw r4, [r10-0x288]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_20928
  ja jmp_20930

jmp_213a8:
  mov64 r7, r1
  ja jmp_1f5d8

jmp_213b8:
  ldxw r7, [r10-0x2d4]
  ja jmp_1f5d8

jmp_213c8:
  mov64 r1, 0x1
  ldxdw r3, [r10-0x370]
  jne r3, 0x0, jmp_21238

jmp_213e0:
  mov64 r1, 0x0
  and64 r1, r2
  ldxdw r3, [r10-0x300]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_21258

jmp_21408:
  or64 r1, r2
  ldxdw r3, [r10-0x2f0]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_21430

jmp_21428:
  mov64 r2, 0x0

jmp_21430:
  or64 r1, r2
  ldxdw r2, [r10-0x2f8]
  ldxdw r3, [r10-0x308]
  add64 r3, r2
  ldxdw r2, [r10-0x2e0]
  mov64 r9, r2
  add64 r9, r3
  mov64 r3, 0x1
  jlt r9, r2, jmp_21480
  mov64 r3, 0x0

jmp_21480:
  or64 r1, r3
  and64 r1, 0x1
  jne r1, 0x0, jmp_21848
  ldxdw r6, [r10-0x2e8]
  ldxdw r2, [r10-0x388]
  jslt r2, 0x0, jmp_21618
  mov64 r1, r10
  add64 r1, -0x60
  call fn_02a8
  ldxdw r1, [r10-0x60]
  jeq r1, 0x0, jmp_21848
  mov64 r1, r10
  add64 r1, -0x348
  ldxdw r8, [r10-0x58]
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x338
  ldxdw r2, [r10-0x50]
  stxdw [r10-0x350], r2
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x328
  mov64 r2, r6
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  mov64 r3, 0x1
  ldxdw r2, [r10-0x350]
  jne r2, 0x0, jmp_216b0
  mov64 r3, 0x0
  mov64 r2, 0x1
  jeq r9, 0x0, jmp_216c0

jmp_215c8:
  and64 r2, r3
  ldxdw r4, [r10-0x340]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_216e8

jmp_215e8:
  mov64 r3, 0x0
  or64 r2, r3
  ldxdw r4, [r10-0x330]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_21708
  ja jmp_21710

jmp_21618:
  neg64 r2
  mov64 r1, r10
  add64 r1, -0x60
  call fn_02a8
  ldxdw r1, [r10-0x60]
  jne r1, 0x1, jmp_21848
  ldxdw r5, [r10-0x50]
  ldxdw r4, [r10-0x58]
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_21848
  mov64 r1, r10
  add64 r1, -0x318
  mov64 r2, r6
  mov64 r3, r9
  call fn_2c2b0
  ldxdw r3, [r10-0x310]
  ldxdw r1, [r10-0x318]
  ja jmp_21778

jmp_216b0:
  mov64 r2, 0x1
  jne r9, 0x0, jmp_215c8

jmp_216c0:
  mov64 r2, 0x0
  and64 r2, r3
  ldxdw r4, [r10-0x340]
  mov64 r3, 0x1
  jeq r4, 0x0, jmp_215e8

jmp_216e8:
  or64 r2, r3
  ldxdw r4, [r10-0x330]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_21710

jmp_21708:
  mov64 r3, 0x0

jmp_21710:
  or64 r2, r3
  ldxdw r3, [r10-0x338]
  ldxdw r4, [r10-0x348]
  add64 r4, r3
  ldxdw r5, [r10-0x320]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_21758
  mov64 r1, 0x0

jmp_21758:
  or64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_21848
  ldxdw r1, [r10-0x328]

jmp_21778:
  jne r3, 0x0, jmp_21848
  ldxdw r4, [r10-0x3b8]
  mov64 r2, r4
  sub64 r2, r1
  mov64 r3, 0x1
  jgt r2, r4, jmp_217d0
  mov64 r3, 0x0
  jeq r3, 0x0, jmp_217d8

jmp_217b8:
  ldxdw r2, [r10-0x3b8]
  jge r2, r1, jmp_217f0
  ja jmp_21848

jmp_217d0:
  jne r3, 0x0, jmp_217b8

jmp_217d8:
  mov64 r7, r2
  ldxdw r2, [r10-0x3b8]
  jlt r2, r1, jmp_21848

jmp_217f0:
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r1+0x4a]
  mov64 r3, r2
  sub64 r3, r7
  mov64 r1, 0x0
  mov64 r4, 0x1
  jgt r3, r2, jmp_21860
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_21868

jmp_21838:
  jge r2, r7, jmp_21878

jmp_21840:
  mov64 r7, r1

jmp_21848:
  ldxdw r6, [r10-0x368]
  mov64 r8, 0x17
  ja jmp_1f5d8

jmp_21860:
  jne r4, 0x0, jmp_21838

jmp_21868:
  mov64 r1, r3
  jlt r2, r7, jmp_21840

jmp_21878:
  ldxdw r2, [r10-0x360]
  stxdw [r2+0x4a], r1
  mov64 r8, 0x1a
  ldxdw r6, [r10-0x368]
  ja jmp_1f5d8

jmp_218a0:
  lddw r1, data_0810
  call fn_29a40

jmp_218b8:
  lddw r1, data_0828
  call fn_29938

jmp_218d0:
  lddw r1, data_0e20
  call fn_299e8

fn_218e8:
  mov64 r0, 0x1
  mov64 r5, 0xa
  mov64 r6, 0x8
  mov64 r4, 0x0
  mov64 r7, 0x4
  jne r3, 0x120, jmp_225f8
  mov64 r5, 0x1e
  ldxb r3, [r2+0x0]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x1]
  jne r3, 0x3, jmp_225f8
  ldxb r3, [r2+0x20]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x21]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x22]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x23]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x24]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x25]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x26]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x27]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x28]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x29]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2c]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2d]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2e]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x2f]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x30]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x31]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x32]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x33]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x34]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x35]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x36]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x37]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x38]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x39]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x3a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x3b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x40]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x41]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x42]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x43]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x44]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x45]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x46]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x47]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x48]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x49]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4c]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4d]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4e]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x4f]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x50]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x51]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x52]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x53]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x54]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x55]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x56]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x57]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x58]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x59]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x5a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x5b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x60]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x61]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x62]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x63]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x64]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x65]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x66]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x67]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x68]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x69]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6c]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6d]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6e]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x6f]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x80]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x81]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x82]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x83]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x84]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x85]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x86]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x87]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x88]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x89]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8c]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8d]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8e]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x8f]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa0]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa1]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa2]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa3]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa4]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa5]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa6]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa7]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa8]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xa9]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xaa]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xab]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xac]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xad]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xae]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xaf]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb0]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb1]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb2]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb3]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb4]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb5]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb6]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb7]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb8]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xb9]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xba]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xbb]
  jne r3, 0x0, jmp_225f8
  mov64 r5, 0x24
  ldxb r3, [r2+0xc0]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc1]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc2]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc3]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc4]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc5]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc6]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc7]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc8]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xc9]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xca]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xcb]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xcc]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xcd]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xce]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xcf]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xd0]
  lsh64 r3, 0x38
  arsh64 r3, 0x38
  jslt r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe0]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe1]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe2]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe3]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe4]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe5]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe6]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe7]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe8]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xe9]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xea]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xeb]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xec]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xed]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xee]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xef]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0xf0]
  lsh64 r3, 0x38
  arsh64 r3, 0x38
  jslt r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x100]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x101]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x102]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x103]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x104]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x105]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x106]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x107]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x108]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x109]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10a]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10b]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10c]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10d]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10e]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x10f]
  jne r3, 0x0, jmp_225f8
  ldxb r3, [r2+0x110]
  lsh64 r3, 0x38
  arsh64 r3, 0x38
  jslt r3, 0x0, jmp_225f8
  ldxw r3, [r2+0x3c]
  be32 r3
  stxdw [r10-0x10], r3
  ldxw r4, [r2+0x5c]
  be32 r4
  ldxdw r3, [r2+0x70]
  be64 r3
  stxdw [r10-0x8], r3
  ldxdw r3, [r2+0x78]
  be64 r3
  stxdw [r10-0x18], r3
  ldxdw r3, [r2+0x90]
  be64 r3
  stxdw [r10-0x20], r3
  ldxdw r3, [r2+0x98]
  be64 r3
  stxdw [r10-0x28], r3
  ldxw r5, [r2+0xbc]
  be32 r5
  ldxdw r8, [r2+0xd0]
  be64 r8
  ldxdw r6, [r2+0xd8]
  be64 r6
  ldxdw r0, [r2+0xf0]
  be64 r0
  ldxdw r3, [r2+0xf8]
  be64 r3
  ldxdw r7, [r2+0x110]
  stxdw [r10-0x38], r7
  ldxdw r7, [r2+0x118]
  ldxdw r9, [r2+0x0]
  stxdw [r10-0x30], r9
  ldxdw r9, [r2+0x8]
  stxdw [r10-0x48], r9
  ldxdw r9, [r2+0x10]
  stxdw [r10-0x40], r9
  ldxdw r9, [r2+0x18]
  ldxdw r2, [r10-0x10]
  stxw [r1+0x78], r2
  stxdw [r1+0x58], r3
  stxdw [r1+0x60], r0
  stxdw [r1+0x48], r6
  stxdw [r1+0x50], r8
  ldxdw r2, [r10-0x28]
  stxdw [r1+0x38], r2
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x40], r2
  ldxdw r2, [r10-0x18]
  stxdw [r1+0x28], r2
  ldxdw r3, [r10-0x8]
  stxdw [r1+0x30], r3
  stxdw [r1+0x20], r9
  ldxdw r2, [r10-0x40]
  stxdw [r1+0x18], r2
  ldxdw r2, [r10-0x48]
  stxdw [r1+0x10], r2
  ldxdw r2, [r10-0x30]
  stxdw [r1+0x8], r2
  be64 r7
  stxdw [r1+0x68], r7
  ldxdw r2, [r10-0x38]
  be64 r2
  stxdw [r1+0x70], r2
  mov64 r0, 0x0
  mov64 r6, 0x80
  mov64 r7, 0x7c

jmp_225f8:
  mov64 r2, r1
  add64 r2, r7
  stxw [r2+0x0], r4
  mov64 r2, r1
  add64 r2, r6
  stxw [r2+0x0], r5
  stxw [r1+0x0], r0
  exit

fn_22638:
  ldxdw r3, [r1+0x50]
  ldxdw r0, [r1+0x40]
  mov64 r4, 0x1
  jlt r0, r3, jmp_22660
  mov64 r4, 0x0

jmp_22660:
  ldxdw r5, [r1+0x58]
  ldxdw r7, [r1+0x48]
  mov64 r2, r7
  sub64 r2, r5
  sub64 r2, r4
  mov64 r4, r7
  xor64 r4, r5
  mov64 r5, r7
  xor64 r5, r2
  and64 r4, r5
  jslt r4, 0x0, jmp_22a48
  ldxdw r4, [r1+0x68]
  ldxdw r6, [r1+0x60]
  mov64 r5, 0x1
  jlt r6, r0, jmp_226e0
  mov64 r5, 0x0

jmp_226e0:
  mov64 r1, r4
  sub64 r1, r7
  sub64 r1, r5
  mov64 r5, r4
  xor64 r5, r7
  xor64 r4, r1
  and64 r5, r4
  stxdw [r10-0x48], r7
  jslt r5, 0x0, jmp_22a60
  mov64 r8, r0
  sub64 r8, r3
  stxdw [r10-0x50], r0
  sub64 r6, r0
  mov64 r7, 0x1
  mov64 r9, 0x1
  jle r8, r6, jmp_229b8
  mov64 r3, 0x1
  jle r2, r1, jmp_229d0

jmp_22770:
  jne r2, r1, jmp_229e0

jmp_22778:
  jne r9, 0x0, jmp_22788

jmp_22780:
  mov64 r2, r1

jmp_22788:
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  jne r9, 0x0, jmp_227c8
  mov64 r8, r6

jmp_227c8:
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r2, [r10-0x18]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_22820
  mov64 r1, 0x0

jmp_22820:
  ldxdw r2, [r10-0x20]
  ldxdw r3, [r10-0x8]
  mov64 r8, r3
  add64 r8, r2
  ldxdw r9, [r10-0x48]
  jlt r8, r3, jmp_22858
  mov64 r7, 0x0

jmp_22858:
  or64 r1, r7
  and64 r1, 0x1
  jne r1, 0x0, jmp_229a8
  ldxdw r7, [r10-0x50]
  mov64 r1, r7
  or64 r1, r9
  jeq r1, 0x0, jmp_22a78
  ldxdw r6, [r10-0x10]
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  mov64 r3, r8
  mov64 r4, r7
  mov64 r5, r9
  call fn_2c2b0
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r4, r7
  ldxdw r7, [r10-0x30]
  mov64 r5, r9
  ldxdw r9, [r10-0x28]
  mov64 r2, r7
  mov64 r3, r9
  call fn_2c150
  ldxdw r1, [r10-0x38]
  sub64 r8, r1
  mov64 r1, 0x1
  ldxdw r2, [r10-0x40]
  mov64 r3, 0x1
  jlt r6, r2, jmp_22950
  mov64 r3, 0x0

jmp_22950:
  sub64 r8, r3
  sub64 r6, r2
  or64 r6, r8
  mov64 r2, 0x1
  jeq r6, 0x0, jmp_229f8
  mov64 r0, r7
  add64 r0, r2
  jge r0, r7, jmp_22a18

jmp_22990:
  add64 r9, r1
  jge r0, 0xffff, jmp_22a30

jmp_229a0:
  jeq r9, 0x0, jmp_229b0

jmp_229a8:
  mov64 r0, 0xffff

jmp_229b0:
  exit

jmp_229b8:
  mov64 r9, 0x0
  mov64 r3, 0x1
  jgt r2, r1, jmp_22770

jmp_229d0:
  mov64 r3, 0x0
  jeq r2, r1, jmp_22778

jmp_229e0:
  mov64 r9, r3
  jeq r9, 0x0, jmp_22780
  ja jmp_22788

jmp_229f8:
  mov64 r2, 0x0
  mov64 r0, r7
  add64 r0, r2
  jlt r0, r7, jmp_22990

jmp_22a18:
  mov64 r1, 0x0
  add64 r9, r1
  jlt r0, 0xffff, jmp_229a0

jmp_22a30:
  mov64 r0, 0xffff
  jne r9, 0x0, jmp_229a8
  ja jmp_229b0

jmp_22a48:
  lddw r1, data_0e80
  call fn_29938

jmp_22a60:
  lddw r1, data_0e98
  call fn_29938

jmp_22a78:
  lddw r1, data_0eb0
  call fn_29a98

fn_22a90:
  mov64 r0, 0x1
  mov64 r5, 0xa
  mov64 r6, 0x8
  mov64 r4, 0x0
  mov64 r7, 0x4
  jne r3, 0xe0, jmp_234c0
  mov64 r5, 0x1e
  ldxb r3, [r2+0x0]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x1]
  jne r3, 0x7, jmp_234c0
  ldxb r3, [r2+0x20]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x21]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x22]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x23]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x24]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x25]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x26]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x27]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x28]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x29]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2c]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2d]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2e]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x2f]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x30]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x31]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x32]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x33]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x34]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x35]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x36]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x37]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x38]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x39]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x3a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x3b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x40]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x41]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x42]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x43]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x44]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x45]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x46]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x47]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x48]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x49]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4c]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4d]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4e]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x4f]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x50]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x51]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x52]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x53]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x54]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x55]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x56]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x57]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x58]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x59]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x5a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x5b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x60]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x61]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x62]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x63]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x64]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x65]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x66]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x67]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x68]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x69]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6c]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6d]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6e]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x6f]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x80]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x81]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x82]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x83]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x84]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x85]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x86]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x87]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x88]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x89]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8a]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8b]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8c]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8d]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8e]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0x8f]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa0]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa1]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa2]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa3]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa4]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa5]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa6]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa7]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa8]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xa9]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xaa]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xab]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xac]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xad]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xae]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xaf]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb0]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb1]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb2]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb3]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb4]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb5]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb6]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb7]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb8]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xb9]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xba]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xbb]
  jne r3, 0x0, jmp_234c0
  mov64 r5, 0x24
  ldxb r3, [r2+0xc0]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc1]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc2]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc3]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc4]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc5]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc6]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc7]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc8]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xc9]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xca]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xcb]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xcc]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xcd]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xce]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xcf]
  jne r3, 0x0, jmp_234c0
  ldxb r3, [r2+0xd0]
  lsh64 r3, 0x38
  arsh64 r3, 0x38
  jslt r3, 0x0, jmp_234c0
  ldxw r3, [r2+0x3c]
  be32 r3
  stxdw [r10-0x8], r3
  ldxw r4, [r2+0x5c]
  be32 r4
  ldxdw r3, [r2+0x70]
  be64 r3
  stxdw [r10-0x18], r3
  ldxdw r6, [r2+0x78]
  be64 r6
  ldxdw r7, [r2+0x90]
  be64 r7
  ldxdw r8, [r2+0x98]
  be64 r8
  ldxw r5, [r2+0xbc]
  be32 r5
  ldxdw r9, [r2+0xd0]
  ldxdw r3, [r2+0xd8]
  ldxdw r0, [r2+0x0]
  stxdw [r10-0x10], r0
  ldxdw r0, [r2+0x8]
  stxdw [r10-0x28], r0
  ldxdw r0, [r2+0x10]
  stxdw [r10-0x20], r0
  ldxdw r0, [r2+0x18]
  ldxdw r2, [r10-0x8]
  stxw [r1+0x58], r2
  stxdw [r1+0x38], r8
  stxdw [r1+0x40], r7
  stxdw [r1+0x28], r6
  ldxdw r2, [r10-0x18]
  stxdw [r1+0x30], r2
  stxdw [r1+0x20], r0
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x18], r2
  ldxdw r2, [r10-0x28]
  stxdw [r1+0x10], r2
  ldxdw r2, [r10-0x10]
  stxdw [r1+0x8], r2
  be64 r3
  stxdw [r1+0x48], r3
  be64 r9
  stxdw [r1+0x50], r9
  mov64 r0, 0x0
  mov64 r6, 0x60
  mov64 r7, 0x5c

jmp_234c0:
  mov64 r2, r1
  add64 r2, r7
  stxw [r2+0x0], r4
  mov64 r2, r1
  add64 r2, r6
  stxw [r2+0x0], r5
  stxw [r1+0x0], r0
  exit

entrypoint:
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_23918
  mov64 r6, r2
  jlt r2, 0x80, jmp_23528
  mov64 r6, 0x80

jmp_23528:
  mov64 r3, 0x0
  mov64 r5, 0x8
  mov64 r4, r10
  add64 r4, -0x698

jmp_23548:
  mov64 r0, r1
  add64 r0, r5
  ldxb r7, [r0+0x0]
  jeq r7, 0xff, jmp_235f8
  mov64 r0, r5
  add64 r0, 0x8
  mov64 r8, 0x1
  jlt r0, r5, jmp_23590
  mov64 r8, 0x0

jmp_23590:
  and64 r8, 0x1
  jne r8, 0x0, jmp_25da8
  lsh64 r7, 0x3
  mov64 r5, r10
  add64 r5, -0x698
  add64 r5, r7
  ldxdw r5, [r5+0x0]
  stxdw [r4+0x0], r5
  mov64 r5, r0
  add64 r3, 0x1
  add64 r4, 0x8
  jlt r3, r6, jmp_23548
  ja jmp_23748

jmp_235f8:
  mov64 r7, r5
  add64 r7, 0x58
  mov64 r8, 0x1
  jlt r7, r5, jmp_23620
  mov64 r8, 0x0

jmp_23620:
  stb [r0+0x0], 0x0
  and64 r8, 0x1
  jne r8, 0x0, jmp_25e08
  ldxdw r5, [r0+0x50]
  mov64 r8, r7
  add64 r8, r5
  mov64 r5, 0x1
  jlt r8, r7, jmp_23668
  mov64 r5, 0x0

jmp_23668:
  and64 r5, 0x1
  jne r5, 0x0, jmp_25e20
  mov64 r5, r8
  add64 r5, 0x2800
  mov64 r7, 0x1
  jlt r5, r8, jmp_236a0
  mov64 r7, 0x0

jmp_236a0:
  and64 r7, 0x1
  jne r7, 0x0, jmp_25dd8
  mov64 r7, r5
  add64 r7, 0x7
  and64 r7, -0x8
  mov64 r8, 0x1
  jlt r7, r5, jmp_236e0
  mov64 r8, 0x0

jmp_236e0:
  and64 r8, 0x1
  jne r8, 0x0, jmp_25df0
  mov64 r5, r7
  add64 r5, 0x8
  mov64 r8, 0x1
  jlt r5, r7, jmp_23718
  mov64 r8, 0x0

jmp_23718:
  and64 r8, 0x1
  jne r8, 0x0, jmp_25dc0
  stxdw [r4+0x0], r0
  add64 r3, 0x1
  add64 r4, 0x8
  jlt r3, r6, jmp_23548

jmp_23748:
  jlt r2, 0x81, jmp_23928
  mov64 r3, r6
  ja jmp_23788

jmp_23760:
  and64 r0, 0x1
  jne r0, 0x0, jmp_25e38

jmp_23770:
  add64 r3, 0x1
  mov64 r5, r4
  jge r3, r2, jmp_23d88

jmp_23788:
  mov64 r4, r1
  add64 r4, r5
  ldxb r0, [r4+0x0]
  jeq r0, 0xff, jmp_237d8
  mov64 r4, r5
  add64 r4, 0x8
  mov64 r0, 0x1
  jlt r4, r5, jmp_23760
  mov64 r0, 0x0
  ja jmp_23760

jmp_237d8:
  mov64 r0, r5
  add64 r0, 0x58
  mov64 r7, 0x1
  jlt r0, r5, jmp_23800
  mov64 r7, 0x0

jmp_23800:
  and64 r7, 0x1
  jne r7, 0x0, jmp_25e80
  ldxdw r4, [r4+0x50]
  mov64 r5, r0
  add64 r5, r4
  mov64 r4, 0x1
  jlt r5, r0, jmp_23840
  mov64 r4, 0x0

jmp_23840:
  and64 r4, 0x1
  jne r4, 0x0, jmp_25e98
  mov64 r4, r5
  add64 r4, 0x2800
  mov64 r0, 0x1
  jlt r4, r5, jmp_23878
  mov64 r0, 0x0

jmp_23878:
  and64 r0, 0x1
  jne r0, 0x0, jmp_25e50
  mov64 r5, r4
  add64 r5, 0x7
  and64 r5, -0x8
  mov64 r0, 0x1
  jlt r5, r4, jmp_238b8
  mov64 r0, 0x0

jmp_238b8:
  and64 r0, 0x1
  jne r0, 0x0, jmp_25e68
  mov64 r4, r5
  add64 r4, 0x8
  mov64 r0, 0x1
  jlt r4, r5, jmp_238f0
  mov64 r0, 0x0

jmp_238f0:
  and64 r0, 0x1
  jeq r0, 0x0, jmp_23770
  lddw r1, data_0900
  call fn_298e0

jmp_23918:
  mov64 r5, 0x8
  mov64 r6, 0x0

jmp_23928:
  mov64 r2, r5
  add64 r2, 0x8
  mov64 r3, 0x1
  jlt r2, r5, jmp_23950

jmp_23948:
  mov64 r3, 0x0

jmp_23950:
  and64 r3, 0x1
  jne r3, 0x0, jmp_25eb0
  mov64 r3, r1
  add64 r3, r5
  ldxdw r8, [r3+0x0]
  mov64 r4, r2
  add64 r4, r8
  mov64 r3, 0x1
  jlt r4, r2, jmp_239a0
  mov64 r3, 0x0

jmp_239a0:
  and64 r3, 0x1
  jne r3, 0x0, jmp_25ec8
  jeq r8, 0x0, jmp_25788
  add64 r1, r2
  mov64 r9, r8
  add64 r9, -0x1
  mov64 r7, r1
  add64 r7, 0x1
  ldxb r2, [r1+0x0]
  jsgt r2, 0xa, jmp_23bf0
  jsle r2, 0x3, jmp_23db8
  jsle r2, 0x6, jmp_242c8
  jeq r2, 0x7, jmp_24e70
  jeq r2, 0x8, jmp_24cb0
  jne r2, 0x9, jmp_25788
  lddw r1, str_03fe
  mov64 r2, 0xa
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_8ce0
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_25680
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r2+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r3, r4, jmp_23b10
  ldxdw r3, [r2+0x30]
  lddw r4, 0x626c582b5813378e
  jne r3, r4, jmp_23b10
  ldxdw r3, [r2+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r3, r4, jmp_23b10
  mov64 r3, 0x0
  ldxdw r4, [r2+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r4, r5, jmp_23b18

jmp_23b10:
  mov64 r3, 0x1

jmp_23b18:
  lddw r7, 0x900000000
  jne r3, 0x0, jmp_25ad8
  lddw r7, 0xa00000000
  ldxdw r3, [r2+0x50]
  jne r3, 0x9c, jmp_25ad8
  mov64 r7, 0xb
  ldxb r3, [r2+0x0]
  and64 r3, 0xf
  jne r3, 0x0, jmp_25ad8
  stb [r2+0xcb], 0x1
  ldxdw r1, [r1+0x0]
  stb [r10-0x170], 0x9
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x16f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x167], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x15f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x157], r1
  mov64 r1, r10
  add64 r1, -0x170
  stxdw [r10-0x298], r1
  stdw [r10-0x290], 0x21
  ja jmp_249e8

jmp_23bf0:
  jsle r2, 0xe, jmp_23f80
  jsle r2, 0x10, jmp_245b0
  jeq r2, 0x11, jmp_25010
  jeq r2, 0x64, jmp_24d68
  jne r2, 0x65, jmp_25788
  stxdw [r10-0x158], r6
  mov64 r1, r10
  add64 r1, -0x698
  stxdw [r10-0x160], r1
  stxdw [r10-0x168], r9
  stxdw [r10-0x170], r7
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x170
  call fn_12cc8
  ldxw r6, [r10-0x28c]
  ldxw r7, [r10-0x290]
  ldxdw r1, [r10-0x298]
  jeq r1, 0x0, jmp_256e8
  ldxdw r2, [r10-0x288]
  ldxdw r3, [r10-0x280]
  lddw r4, data_0467
  stxdw [r10-0x288], r4
  lddw r4, str_03de
  stxdw [r10-0x298], r4
  stdw [r10-0x280], 0x1
  stdw [r10-0x290], 0x4
  stxdw [r10-0x158], r3
  lsh64 r6, 0x20
  or64 r6, r7
  stxdw [r10-0x160], r6
  stxdw [r10-0x168], r1
  stxdw [r10-0x170], r2
  mov64 r1, r10
  add64 r1, -0x298
  stxdw [r10-0x48], r1
  stdw [r10-0x40], 0x2
  mov64 r1, r10
  add64 r1, -0x6a0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, r10
  add64 r3, -0x48
  mov64 r4, 0x1
  call fn_27588
  ldxw r6, [r10-0x69c]
  ldxw r7, [r10-0x6a0]
  ja jmp_256e8

jmp_23d88:
  mov64 r5, r4
  mov64 r2, r5
  add64 r2, 0x8
  mov64 r3, 0x1
  jge r2, r5, jmp_23948
  ja jmp_23950

jmp_23db8:
  jsgt r2, 0x1, jmp_24080
  jeq r2, 0x0, jmp_24678
  jne r2, 0x1, jmp_25788
  stxdw [r10-0x720], r1
  lddw r1, str_03d6
  mov64 r2, 0x4
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_35d8
  ldxw r6, [r10-0x28c]
  ldxw r7, [r10-0x290]
  ldxdw r8, [r10-0x298]
  jeq r8, 0x0, jmp_256e8
  stxdw [r10-0x730], r6
  stxdw [r10-0x728], r7
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r2, r10
  add64 r2, -0x288
  mov64 r3, 0x48
  call fn_2a090
  mov64 r7, 0x2
  mov64 r6, 0xc
  jne r9, 0x10, jmp_256e8
  mov64 r7, 0x0
  ldxdw r1, [r10-0x720]
  ldxdw r9, [r1+0x1]
  jeq r9, 0x0, jmp_256e8
  ldxdw r1, [r1+0x9]
  jeq r1, 0x0, jmp_256e8
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0x48
  mov64 r3, 0x48
  call fn_2a090
  stxdw [r10-0x110], r6
  stxdw [r10-0x118], r9
  ldxdw r1, [r10-0x730]
  stxw [r10-0x164], r1
  ldxdw r1, [r10-0x728]
  stxw [r10-0x168], r1
  stxdw [r10-0x170], r8
  mov64 r1, r10
  add64 r1, -0x710
  mov64 r2, r10
  add64 r2, -0x170
  call fn_41a0
  ldxw r6, [r10-0x70c]
  ldxw r7, [r10-0x710]
  ja jmp_256e8

jmp_23f80:
  jsgt r2, 0xc, jmp_24188
  jeq r2, 0xb, jmp_247f0
  jne r2, 0xc, jmp_25788
  lddw r1, str_0408
  mov64 r2, 0x14
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_8fe0
  ldxw r6, [r10-0x164]
  ldxw r7, [r10-0x168]
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_256e8
  ldxdw r2, [r10-0x158]
  stxdw [r10-0x280], r2
  ldxdw r2, [r10-0x160]
  stxdw [r10-0x288], r2
  stxw [r10-0x28c], r6
  stxw [r10-0x290], r7
  stxdw [r10-0x298], r1
  mov64 r1, r10
  add64 r1, -0x6d0
  mov64 r2, r10
  add64 r2, -0x298
  call fn_9580
  ldxw r6, [r10-0x6cc]
  ldxw r7, [r10-0x6d0]
  ja jmp_256e8

jmp_24080:
  jeq r2, 0x2, jmp_24a18
  jne r2, 0x3, jmp_25788
  lddw r1, str_03e8
  mov64 r2, 0xa
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_5c58
  ldxw r6, [r10-0x164]
  ldxw r7, [r10-0x168]
  ldxdw r8, [r10-0x170]
  jeq r8, 0x0, jmp_256e8
  mov64 r1, r10
  add64 r1, -0x288
  mov64 r2, r10
  add64 r2, -0x160
  mov64 r3, 0x38
  call fn_2a090
  stxw [r10-0x28c], r6
  stxw [r10-0x290], r7
  stxdw [r10-0x298], r8
  mov64 r1, r10
  add64 r1, -0x700
  mov64 r2, r10
  add64 r2, -0x298
  call fn_6678
  ldxw r6, [r10-0x6fc]
  ldxw r7, [r10-0x700]
  ja jmp_256e8

jmp_24188:
  jeq r2, 0xd, jmp_24bc8
  jne r2, 0xe, jmp_25788
  stxdw [r10-0x30], r6
  mov64 r1, r10
  add64 r1, -0x698
  stxdw [r10-0x38], r1
  stxdw [r10-0x40], r9
  stxdw [r10-0x48], r7
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x48
  call fn_a520
  ldxw r6, [r10-0x16c]
  ldxw r7, [r10-0x170]
  ldxb r8, [r10-0x110]
  jeq r8, 0x2, jmp_256e8
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, r10
  add64 r2, -0x168
  mov64 r3, 0x58
  call fn_2a090
  mov64 r1, r10
  add64 r1, -0x237
  mov64 r2, r10
  add64 r2, -0x10f
  mov64 r3, 0xc7
  call fn_2a090
  stxb [r10-0x238], r8
  stxw [r10-0x294], r6
  stxw [r10-0x298], r7
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, r10
  add64 r2, -0x298
  call fn_a910
  ldxw r6, [r10-0x6bc]
  ldxw r7, [r10-0x6c0]
  ja jmp_256e8

jmp_242c8:
  jeq r2, 0x4, jmp_25230
  jne r2, 0x5, jmp_25788
  mov64 r8, r1
  lddw r1, str_03a0
  mov64 r2, 0x10
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_2180
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_256b0
  mov64 r0, r7
  mov64 r7, 0x2
  jne r9, 0x20, jmp_256d8
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r2+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r3, r4, jmp_243f0
  ldxdw r3, [r2+0x30]
  lddw r4, 0x626c582b5813378e
  jne r3, r4, jmp_243f0
  ldxdw r3, [r2+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r3, r4, jmp_243f0
  mov64 r3, 0x0
  ldxdw r4, [r2+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r4, r5, jmp_243f8

jmp_243f0:
  mov64 r3, 0x1

jmp_243f8:
  lddw r7, 0x900000000
  jne r3, 0x0, jmp_25ad8
  lddw r7, 0xa00000000
  ldxdw r3, [r2+0x50]
  jne r3, 0x9c, jmp_25ad8
  mov64 r7, 0xb
  ldxb r3, [r2+0x0]
  and64 r3, 0xf
  jne r3, 0x0, jmp_25ad8
  mov64 r3, r8
  add64 r3, 0xc
  ldxw r5, [r8+0x8]
  ldxw r4, [r8+0x4]
  mov64 r6, r0
  ldxb r0, [r6+0x2]
  stxb [r2+0xd6], r0
  ldxh r0, [r6+0x0]
  stxh [r2+0xd4], r0
  stxw [r2+0xdb], r5
  stxw [r2+0xd7], r4
  ldxdw r0, [r3+0x0]
  stxdw [r2+0xdf], r0
  ldxdw r0, [r3+0x8]
  stxdw [r2+0xe7], r0
  ldxdw r0, [r3+0xd]
  stxdw [r2+0xec], r0
  ldxdw r1, [r1+0x0]
  stb [r10-0x170], 0x5
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x16f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x167], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x15f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x157], r1
  ldxh r1, [r6+0x0]
  stxh [r10-0x14f], r1
  ldxb r1, [r6+0x2]
  stxb [r10-0x14d], r1
  stxw [r10-0x148], r5
  stxw [r10-0x14c], r4
  ldxdw r1, [r3+0x0]
  stxdw [r10-0x144], r1
  ldxdw r1, [r3+0x8]
  stxdw [r10-0x13c], r1
  ldxdw r1, [r3+0xd]
  stxdw [r10-0x137], r1
  mov64 r1, r10
  add64 r1, -0x170
  stxdw [r10-0x298], r1
  stdw [r10-0x290], 0x41
  ja jmp_249e8

jmp_245b0:
  jeq r2, 0xf, jmp_253b8
  jne r2, 0x10, jmp_25788
  lddw r1, str_043b
  mov64 r2, 0xd
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_cf00
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_25680
  ldxdw r2, [r10-0x168]
  stxdw [r10-0x290], r2
  stxdw [r10-0x298], r1
  mov64 r1, r10
  add64 r1, -0x6b8
  mov64 r2, r10
  add64 r2, -0x298
  call fn_d378
  ldxw r6, [r10-0x6b4]
  ldxw r7, [r10-0x6b8]
  ja jmp_256e8

jmp_24678:
  mov64 r8, r1
  lddw r1, str_035e
  mov64 r2, 0xc
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_0c90
  ldxw r6, [r10-0x28c]
  ldxw r7, [r10-0x290]
  ldxdw r1, [r10-0x298]
  jeq r1, 0x0, jmp_256e8
  ldxdw r2, [r10-0x270]
  stxdw [r10-0x30], r2
  ldxdw r2, [r10-0x278]
  stxdw [r10-0x38], r2
  ldxdw r2, [r10-0x280]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x288]
  stxdw [r10-0x48], r2
  jne r9, 0x3, jmp_258d8
  ldxh r2, [r8+0x1]
  ldxdw r3, [r10-0x30]
  stxdw [r10-0x148], r3
  ldxdw r3, [r10-0x38]
  stxdw [r10-0x150], r3
  ldxdw r3, [r10-0x40]
  stxdw [r10-0x158], r3
  ldxdw r3, [r10-0x48]
  stxdw [r10-0x160], r3
  stxh [r10-0x138], r2
  add64 r8, 0x3
  stxdw [r10-0x140], r8
  stxw [r10-0x164], r6
  stxw [r10-0x168], r7
  stxdw [r10-0x170], r1
  mov64 r1, r10
  add64 r1, -0x718
  mov64 r2, r10
  add64 r2, -0x170
  call fn_1558
  ldxw r6, [r10-0x714]
  ldxw r7, [r10-0x718]
  ja jmp_256e8

jmp_247f0:
  lddw r1, str_03c0
  mov64 r2, 0x12
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_2180
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_256b0
  mov64 r0, r7
  mov64 r7, 0x2
  jne r9, 0x8, jmp_256d8
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r2+0x28]
  lddw r4, -0x2ef915ab4fa6d9f4
  jne r3, r4, jmp_24900
  ldxdw r3, [r2+0x30]
  lddw r4, 0x626c582b5813378e
  jne r3, r4, jmp_24900
  ldxdw r3, [r2+0x38]
  lddw r4, -0x164c5fdb9d1c7931
  jne r3, r4, jmp_24900
  mov64 r3, 0x0
  ldxdw r4, [r2+0x40]
  lddw r5, -0xe007a018e0ac636
  jeq r4, r5, jmp_24908

jmp_24900:
  mov64 r3, 0x1

jmp_24908:
  lddw r7, 0x900000000
  jne r3, 0x0, jmp_25ad8
  lddw r7, 0xa00000000
  ldxdw r3, [r2+0x50]
  jne r3, 0x9c, jmp_25ad8
  mov64 r7, 0xb
  ldxb r3, [r2+0x0]
  and64 r3, 0xf
  jne r3, 0x0, jmp_25ad8
  ldxdw r3, [r0+0x0]
  stxdw [r2+0xcc], r3
  ldxdw r1, [r1+0x0]
  stb [r10-0x170], 0xb
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x16f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x167], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x15f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x157], r1
  stxdw [r10-0x14f], r3
  mov64 r1, r10
  add64 r1, -0x170
  stxdw [r10-0x298], r1
  stdw [r10-0x290], 0x29

jmp_249e8:
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, 0x1
  call fn_287e0
  mov64 r0, 0x0
  ja jmp_25798

jmp_24a18:
  stxdw [r10-0x720], r1
  lddw r1, str_03e2
  mov64 r2, 0x6
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_48c0
  ldxw r6, [r10-0x28c]
  ldxw r7, [r10-0x290]
  ldxdw r8, [r10-0x298]
  jeq r8, 0x0, jmp_256e8
  stxdw [r10-0x730], r6
  stxdw [r10-0x728], r7
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r2, r10
  add64 r2, -0x288
  mov64 r3, 0x48
  call fn_2a090
  mov64 r7, 0x2
  mov64 r6, 0xc
  jne r9, 0x10, jmp_256e8
  mov64 r7, 0x0
  ldxdw r1, [r10-0x720]
  ldxdw r9, [r1+0x1]
  jeq r9, 0x0, jmp_256e8
  ldxdw r1, [r1+0x9]
  jeq r1, 0x0, jmp_256e8
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0x48
  mov64 r3, 0x48
  call fn_2a090
  stxdw [r10-0x110], r6
  stxdw [r10-0x118], r9
  ldxdw r1, [r10-0x730]
  stxw [r10-0x164], r1
  ldxdw r1, [r10-0x728]
  stxw [r10-0x168], r1
  stxdw [r10-0x170], r8
  mov64 r1, r10
  add64 r1, -0x708
  mov64 r2, r10
  add64 r2, -0x170
  call fn_56b8
  ldxw r6, [r10-0x704]
  ldxw r7, [r10-0x708]
  ja jmp_256e8

jmp_24bc8:
  lddw r1, str_041c
  mov64 r2, 0x12
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_8fe0
  ldxw r6, [r10-0x164]
  ldxw r7, [r10-0x168]
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_256e8
  ldxdw r2, [r10-0x158]
  stxdw [r10-0x280], r2
  ldxdw r2, [r10-0x160]
  stxdw [r10-0x288], r2
  stxw [r10-0x28c], r6
  stxw [r10-0x290], r7
  stxdw [r10-0x298], r1
  mov64 r1, r10
  add64 r1, -0x6c8
  mov64 r2, r10
  add64 r2, -0x298
  call fn_9850
  ldxw r6, [r10-0x6c4]
  ldxw r7, [r10-0x6c8]
  ja jmp_256e8

jmp_24cb0:
  lddw r1, str_03b0
  mov64 r2, 0x10
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_85d0
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_25680
  ldxdw r2, [r10-0x168]
  stxdw [r10-0x290], r2
  stxdw [r10-0x298], r1
  mov64 r1, r10
  add64 r1, -0x6d8
  mov64 r2, r10
  add64 r2, -0x298
  call fn_89b8
  ldxw r6, [r10-0x6d4]
  ldxw r7, [r10-0x6d8]
  ja jmp_256e8

jmp_24d68:
  mov64 r8, r1
  lddw r1, str_03da
  mov64 r2, 0x4
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_13098
  ldxw r2, [r10-0x28c]
  ldxw r3, [r10-0x290]
  ldxdw r1, [r10-0x298]
  jeq r1, 0x0, jmp_256c0
  ldxdw r4, [r10-0x268]
  stxdw [r10-0x28], r4
  ldxdw r4, [r10-0x270]
  stxdw [r10-0x30], r4
  ldxdw r4, [r10-0x278]
  stxdw [r10-0x38], r4
  ldxdw r4, [r10-0x280]
  stxdw [r10-0x40], r4
  ldxdw r4, [r10-0x288]
  stxdw [r10-0x48], r4
  mov64 r7, 0x2
  jne r9, 0x11, jmp_256d8
  ldxdw r4, [r8+0x1]
  ldxb r5, [r8+0x9]
  jeq r5, 0x0, jmp_25c98
  jne r5, 0x1, jmp_256d8
  mov64 r5, 0x1
  ja jmp_25ca0

jmp_24e70:
  stxdw [r10-0x720], r1
  lddw r1, str_03f2
  mov64 r2, 0xc
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_6b58
  ldxw r6, [r10-0x28c]
  ldxw r2, [r10-0x290]
  ldxdw r8, [r10-0x298]
  jeq r8, 0x0, jmp_258c8
  stxdw [r10-0x728], r7
  ldxdw r1, [r10-0x278]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x48], r1
  mov64 r7, 0x2
  jne r9, 0x51, jmp_256d8
  ldxdw r1, [r10-0x720]
  ldxdw r3, [r1+0x4a]
  ldxdw r9, [r1+0x42]
  mov64 r1, r9
  add64 r1, -0x1
  jge r1, r3, jmp_256d8
  mov64 r7, r3
  stxdw [r10-0x730], r2
  mov64 r1, r10
  add64 r1, -0x6e8
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, 0xa
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, 0x1
  ldxdw r2, [r10-0x6e0]
  jne r2, 0x0, jmp_25930
  mov64 r1, 0x0
  mov64 r3, -0x1
  mov64 r0, r7
  jeq r1, 0x0, jmp_25948

jmp_24fe0:
  lddw r7, 0x2000000000
  ldxdw r2, [r10-0x720]
  ldxdw r5, [r10-0x730]
  jge r0, r3, jmp_256d8
  ja jmp_25978

jmp_25010:
  mov64 r9, r7
  stxdw [r10-0x720], r1
  lddw r1, str_0448
  mov64 r2, 0x11
  call sol_log_
  mov64 r7, 0xa
  jlt r6, 0x5, jmp_25ad8
  ldxdw r1, [r10-0x698]
  ldxb r1, [r1+0x1]
  jeq r1, 0x0, jmp_25900
  ldxdw r1, [r10-0x688]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_25ad0
  mov64 r7, 0x2
  jlt r8, 0x3, jmp_25ad8
  lddw r7, 0x2000000000
  ldxb r1, [r9+0x0]
  jgt r1, 0x5, jmp_25ad8
  mov64 r2, 0x1
  lsh64 r2, r1
  and64 r2, 0x34
  jeq r2, 0x0, jmp_25ad8
  mov64 r2, r10
  add64 r2, -0x670
  mov64 r3, r10
  add64 r3, -0x678
  mov64 r4, r10
  add64 r4, -0x680
  mov64 r5, r10
  add64 r5, -0x688
  mov64 r0, r10
  add64 r0, -0x690
  add64 r6, -0x5
  ldxdw r9, [r10-0x720]
  ldxb r7, [r9+0x2]
  stxb [r10-0x127], r1
  stxb [r10-0x128], r7
  add64 r8, -0x3
  stxdw [r10-0x130], r8
  stxdw [r10-0x140], r6
  stxdw [r10-0x148], r2
  stxdw [r10-0x150], r3
  stxdw [r10-0x158], r4
  stxdw [r10-0x160], r5
  mov64 r1, r0
  rsh64 r1, 0x20
  stxw [r10-0x164], r1
  stxw [r10-0x168], r0
  mov64 r1, r10
  add64 r1, -0x698
  mov64 r2, r1
  rsh64 r2, 0x20
  stxw [r10-0x16c], r2
  stxw [r10-0x170], r1
  add64 r9, 0x3
  stxw [r10-0x138], r9
  rsh64 r9, 0x20
  stxw [r10-0x134], r9
  mov64 r1, r10
  add64 r1, -0x6b0
  mov64 r2, r10
  add64 r2, -0x170
  call fn_ddc0
  ldxw r6, [r10-0x6ac]
  ldxw r7, [r10-0x6b0]
  ja jmp_256e8

jmp_25230:
  mov64 r8, r7
  lddw r1, data_0374
  mov64 r2, 0xa
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_2480
  ldxw r6, [r10-0x28c]
  ldxw r7, [r10-0x290]
  ldxdw r1, [r10-0x298]
  jeq r1, 0x0, jmp_256e8
  ldxdw r2, [r10-0x268]
  stxdw [r10-0x28], r2
  ldxdw r2, [r10-0x270]
  stxdw [r10-0x30], r2
  ldxdw r2, [r10-0x278]
  stxdw [r10-0x38], r2
  ldxdw r2, [r10-0x280]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x288]
  stxdw [r10-0x48], r2
  jne r9, 0x2, jmp_258e8
  ldxh r2, [r8+0x0]
  ldxdw r3, [r10-0x28]
  stxdw [r10-0x140], r3
  ldxdw r3, [r10-0x30]
  stxdw [r10-0x148], r3
  ldxdw r3, [r10-0x38]
  stxdw [r10-0x150], r3
  ldxdw r3, [r10-0x40]
  stxdw [r10-0x158], r3
  ldxdw r3, [r10-0x48]
  stxdw [r10-0x160], r3
  stxh [r10-0x138], r2
  stxw [r10-0x164], r6
  stxw [r10-0x168], r7
  stxdw [r10-0x170], r1
  mov64 r1, r10
  add64 r1, -0x6f8
  mov64 r2, r10
  add64 r2, -0x170
  call fn_2c78
  ldxw r6, [r10-0x6f4]
  ldxw r7, [r10-0x6f8]
  ja jmp_256e8

jmp_253b8:
  lddw r1, str_0380
  mov64 r2, 0x10
  call sol_log_
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x698
  mov64 r3, r6
  call fn_3260
  ldxdw r1, [r10-0x170]
  jeq r1, 0x0, jmp_25680
  ldxdw r1, [r10-0x168]
  ldxdw r6, [r1+0x0]
  ldxdw r2, [r6+0x28]
  lddw r3, -0x2ef915ab4fa6d9f4
  jne r2, r3, jmp_254b0
  ldxdw r2, [r6+0x30]
  lddw r3, 0x626c582b5813378e
  jne r2, r3, jmp_254b0
  ldxdw r2, [r6+0x38]
  lddw r3, -0x164c5fdb9d1c7931
  jne r2, r3, jmp_254b0
  mov64 r2, 0x0
  ldxdw r3, [r6+0x40]
  lddw r4, -0xe007a018e0ac636
  jeq r3, r4, jmp_254b8

jmp_254b0:
  mov64 r2, 0x1

jmp_254b8:
  lddw r7, 0x900000000
  jne r2, 0x0, jmp_25ad8
  lddw r7, 0xa00000000
  ldxdw r2, [r6+0x50]
  jne r2, 0x9c, jmp_25ad8
  mov64 r7, 0xb
  ldxb r2, [r6+0x0]
  mov64 r3, r2
  and64 r3, 0xf
  jne r3, 0x0, jmp_25ad8
  or64 r2, 0x8
  stxb [r6+0x0], r2
  ldxdw r2, [r6+0xd4]
  stxdw [r6+0xaa], r2
  ldxdw r2, [r6+0xdc]
  stxdw [r6+0xb2], r2
  ldxdw r2, [r6+0xe4]
  stxdw [r6+0xba], r2
  ldxdw r2, [r6+0xec]
  stxdw [r6+0xc2], r2
  stdw [r6+0xd4], 0x0
  stdw [r6+0xdc], 0x0
  stdw [r6+0xe4], 0x0
  stdw [r6+0xec], 0x0
  ldxdw r1, [r1+0x0]
  stb [r10-0x170], 0xf
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x16f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x167], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x15f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x157], r1
  ldxdw r1, [r6+0xaa]
  stxdw [r10-0x14f], r1
  ldxdw r1, [r6+0xb2]
  stxdw [r10-0x147], r1
  ldxdw r1, [r6+0xba]
  stxdw [r10-0x13f], r1
  ldxdw r1, [r6+0xc2]
  stxdw [r10-0x137], r1
  mov64 r1, r10
  add64 r1, -0x170
  stxdw [r10-0x298], r1
  stdw [r10-0x290], 0x41
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, 0x1
  call fn_287e0
  ldxb r1, [r6+0x0]
  and64 r1, 0xf7
  stxb [r6+0x0], r1
  mov64 r0, 0x0
  ja jmp_25798

jmp_25680:
  ldxw r6, [r10-0x164]
  ldxw r7, [r10-0x168]
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jsle r7, 0xc, jmp_25728
  ja jmp_25b00

jmp_256b0:
  ldxdw r7, [r10-0x168]
  ja jmp_256d8

jmp_256c0:
  lsh64 r2, 0x20
  or64 r2, r3
  mov64 r7, r2

jmp_256d8:
  mov64 r6, r7
  rsh64 r6, 0x20

jmp_256e8:
  mov64 r0, 0x0
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1a, jmp_25798
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jsgt r7, 0xc, jmp_25b00

jmp_25728:
  jsle r7, 0x5, jmp_25760
  jsle r7, 0x8, jmp_257a0
  jsgt r7, 0xa, jmp_257f0
  jne r7, 0x9, jmp_25880
  lddw r0, 0xa00000000
  ja jmp_25798

jmp_25760:
  jsgt r7, 0x2, jmp_257c8
  jeq r7, 0x0, jmp_25828
  lddw r0, 0x200000000
  jeq r7, 0x1, jmp_25798

jmp_25788:
  lddw r0, 0x300000000

jmp_25798:
  exit

jmp_257a0:
  jeq r7, 0x6, jmp_25810
  jne r7, 0x7, jmp_25868
  lddw r0, 0x800000000
  ja jmp_25798

jmp_257c8:
  jeq r7, 0x3, jmp_25850
  jne r7, 0x4, jmp_258b0
  lddw r0, 0x500000000
  ja jmp_25798

jmp_257f0:
  jne r7, 0xb, jmp_25898
  lddw r0, 0xc00000000
  ja jmp_25798

jmp_25810:
  lddw r0, 0x700000000
  ja jmp_25798

jmp_25828:
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  jeq r6, 0x0, jmp_25918
  mov64 r0, r6
  ja jmp_25798

jmp_25850:
  lddw r0, 0x400000000
  ja jmp_25798

jmp_25868:
  lddw r0, 0x900000000
  ja jmp_25798

jmp_25880:
  lddw r0, 0xb00000000
  ja jmp_25798

jmp_25898:
  lddw r0, 0xd00000000
  ja jmp_25798

jmp_258b0:
  lddw r0, 0x600000000
  ja jmp_25798

jmp_258c8:
  mov64 r7, r2
  ja jmp_256e8

jmp_258d8:
  mov64 r7, 0x2
  ja jmp_256e8

jmp_258e8:
  mov64 r7, 0x2
  mov64 r6, 0x0
  ja jmp_256e8

jmp_25900:
  lddw r7, 0x800000000
  ja jmp_25ad8

jmp_25918:
  lddw r0, 0x100000000
  ja jmp_25798

jmp_25930:
  mov64 r3, -0x1
  mov64 r0, r7
  jne r1, 0x0, jmp_24fe0

jmp_25948:
  ldxdw r3, [r10-0x6e8]
  lddw r7, 0x2000000000
  ldxdw r2, [r10-0x720]
  ldxdw r5, [r10-0x730]
  jge r0, r3, jmp_256d8

jmp_25978:
  mov64 r1, r2
  add64 r1, 0x41
  add64 r2, 0x21
  ldxdw r4, [r10-0x728]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x118], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x120], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x128], r3
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x130], r3
  ldxdw r3, [r2+0x0]
  stxdw [r10-0x110], r3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x108], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x100], r3
  ldxdw r2, [r2+0x18]
  stxdw [r10-0xf8], r2
  ldxdw r2, [r10-0x48]
  stxdw [r10-0x160], r2
  ldxdw r2, [r10-0x40]
  stxdw [r10-0x158], r2
  ldxdw r2, [r10-0x38]
  stxdw [r10-0x150], r2
  stxdw [r10-0x138], r0
  mov64 r2, r9
  rsh64 r2, 0x20
  stxw [r10-0x13c], r2
  stxw [r10-0x140], r9
  stxdw [r10-0x148], r1
  stxw [r10-0x164], r6
  stxw [r10-0x168], r5
  stxdw [r10-0x170], r8
  mov64 r1, r10
  add64 r1, -0x6f0
  mov64 r2, r10
  add64 r2, -0x170
  call fn_7038
  ldxw r6, [r10-0x6ec]
  ldxw r7, [r10-0x6f0]
  ja jmp_256e8

jmp_25ad0:
  mov64 r7, 0x0

jmp_25ad8:
  mov64 r6, r7
  rsh64 r6, 0x20
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jsle r7, 0xc, jmp_25728

jmp_25b00:
  jsle r7, 0x12, jmp_25b38
  jsle r7, 0x15, jmp_25b68
  jsgt r7, 0x17, jmp_25bb8
  jne r7, 0x16, jmp_25c38
  lddw r0, 0x1700000000
  ja jmp_25798

jmp_25b38:
  jsgt r7, 0xf, jmp_25b90
  jeq r7, 0xd, jmp_25bf0
  jne r7, 0xe, jmp_25c68
  lddw r0, 0xf00000000
  ja jmp_25798

jmp_25b68:
  jeq r7, 0x13, jmp_25bd8
  jne r7, 0x14, jmp_25c20
  lddw r0, 0x1500000000
  ja jmp_25798

jmp_25b90:
  jeq r7, 0x10, jmp_25c08
  jne r7, 0x11, jmp_25c80
  lddw r0, 0x1200000000
  ja jmp_25798

jmp_25bb8:
  jne r7, 0x18, jmp_25c50
  lddw r0, 0x1900000000
  ja jmp_25798

jmp_25bd8:
  lddw r0, 0x1400000000
  ja jmp_25798

jmp_25bf0:
  lddw r0, 0xe00000000
  ja jmp_25798

jmp_25c08:
  lddw r0, 0x1100000000
  ja jmp_25798

jmp_25c20:
  lddw r0, 0x1600000000
  ja jmp_25798

jmp_25c38:
  lddw r0, 0x1800000000
  ja jmp_25798

jmp_25c50:
  lddw r0, 0x1a00000000
  ja jmp_25798

jmp_25c68:
  lddw r0, 0x1000000000
  ja jmp_25798

jmp_25c80:
  lddw r0, 0x1300000000
  ja jmp_25798

jmp_25c98:
  mov64 r5, 0x0

jmp_25ca0:
  lddw r7, 0xc00000000
  jeq r4, 0x0, jmp_256d8
  ldxdw r0, [r8+0xa]
  jeq r0, 0x0, jmp_256d8
  ldxdw r6, [r10-0x28]
  stxdw [r10-0x140], r6
  ldxdw r6, [r10-0x30]
  stxdw [r10-0x148], r6
  ldxdw r6, [r10-0x38]
  stxdw [r10-0x150], r6
  ldxdw r6, [r10-0x40]
  stxdw [r10-0x158], r6
  ldxdw r6, [r10-0x48]
  stxdw [r10-0x160], r6
  stxb [r10-0x128], r5
  stxdw [r10-0x130], r0
  stxw [r10-0x164], r2
  stxw [r10-0x168], r3
  stxw [r10-0x138], r4
  rsh64 r4, 0x20
  stxw [r10-0x134], r4
  stxw [r10-0x170], r1
  rsh64 r1, 0x20
  stxw [r10-0x16c], r1
  mov64 r1, r10
  add64 r1, -0x6a8
  mov64 r2, r10
  add64 r2, -0x170
  call fn_136a0
  ldxw r6, [r10-0x6a4]
  ldxw r7, [r10-0x6a8]
  ja jmp_256e8

jmp_25da8:
  lddw r1, data_0918
  call fn_298e0

jmp_25dc0:
  lddw r1, data_0990
  call fn_298e0

jmp_25dd8:
  lddw r1, data_0960
  call fn_298e0

jmp_25df0:
  lddw r1, data_0978
  call fn_298e0

jmp_25e08:
  lddw r1, data_0930
  call fn_298e0

jmp_25e20:
  lddw r1, data_0948
  call fn_298e0

jmp_25e38:
  lddw r1, data_0888
  call fn_298e0

jmp_25e50:
  lddw r1, data_08d0
  call fn_298e0

jmp_25e68:
  lddw r1, data_08e8
  call fn_298e0

jmp_25e80:
  lddw r1, data_08a0
  call fn_298e0

jmp_25e98:
  lddw r1, data_08b8
  call fn_298e0

jmp_25eb0:
  lddw r1, data_0858
  call fn_298e0

jmp_25ec8:
  lddw r1, data_0870
  call fn_298e0
  ldxdw r2, [r1+0x8]
  ldxdw r1, [r2+0x0]
  ldxdw r2, [r2+0x8]
  add64 r2, -0x1
  call sol_log_
  lddw r1, data_0479
  mov64 r2, 0xe
  call sol_log_
  exit

fn_25f30:
  call fn_28aa0
  exit

fn_25f40:
  exit

fn_25f48:
  mov64 r9, 0xa
  ldxdw r0, [r2+0x20]
  jlt r0, 0x4, jmp_26208
  stxdw [r10-0x120], r4
  stxdw [r10-0x118], r5
  ldxdw r4, [r2+0x18]
  stxdw [r10-0x110], r4
  ldxdw r4, [r4+0x0]
  ldxdw r5, [r3+0x0]
  ldxdw r6, [r5+0x0]
  mov64 r8, r6
  add64 r8, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r9, [r8+0x0]
  jne r9, r5, jmp_26010
  ldxdw r5, [r4+0x8]
  ldxdw r9, [r8+0x8]
  jne r9, r5, jmp_26010
  ldxdw r5, [r4+0x10]
  ldxdw r9, [r8+0x10]
  jne r9, r5, jmp_26010
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r9, [r8+0x18]
  jeq r9, r4, jmp_26018

jmp_26010:
  mov64 r5, 0x1

jmp_26018:
  mov64 r9, 0x1
  jne r5, 0x0, jmp_26208
  ldxdw r4, [r10-0x110]
  ldxb r5, [r4+0x8]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26050
  mov64 r4, -0x78

jmp_26050:
  ldxb r5, [r6+0x0]
  and64 r4, r5
  and64 r4, 0xff
  jeq r4, 0x0, jmp_26080

jmp_26070:
  mov64 r9, 0xb
  ja jmp_26208

jmp_26080:
  ldxb r5, [r6+0x1]
  mov64 r4, 0x1
  jne r5, 0x0, jmp_26218
  mov64 r4, 0x0
  stxdw [r10-0x128], r4
  ldxb r4, [r6+0x2]
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_26238

jmp_260c0:
  ldxb r4, [r6+0x3]
  jne r4, 0x0, jmp_260d8

jmp_260d0:
  mov64 r9, 0x0

jmp_260d8:
  ldxdw r4, [r6+0x50]
  mov64 r7, r6
  add64 r7, 0x28
  stxdw [r10-0xe8], r7
  mov64 r7, r6
  add64 r7, 0x58
  stxdw [r10-0xf0], r7
  stxdw [r10-0xf8], r4
  add64 r6, 0x48
  stxdw [r10-0x100], r6
  stxdw [r10-0x108], r8
  stxb [r10-0xd6], r9
  stxb [r10-0xd7], r5
  ldxdw r4, [r10-0x128]
  stxb [r10-0xd8], r4
  stdw [r10-0xe0], 0x0
  ldxdw r4, [r10-0x110]
  ldxdw r4, [r4+0x10]
  ldxdw r5, [r3+0x8]
  ldxdw r8, [r5+0x0]
  mov64 r7, r8
  add64 r7, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r7+0x0]
  jne r6, r5, jmp_261f0
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r7+0x8]
  jne r6, r5, jmp_261f0
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r7+0x10]
  jne r6, r5, jmp_261f0
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r6, [r7+0x18]
  jeq r6, r4, jmp_261f8

jmp_261f0:
  mov64 r5, 0x1

jmp_261f8:
  mov64 r9, 0x1
  jeq r5, 0x0, jmp_26258

jmp_26208:
  stxw [r1+0x0], r9
  exit

jmp_26218:
  stxdw [r10-0x128], r4
  ldxb r4, [r6+0x2]
  mov64 r5, 0x1
  jne r4, 0x0, jmp_260c0

jmp_26238:
  mov64 r5, 0x0
  ldxb r4, [r6+0x3]
  jeq r4, 0x0, jmp_260d0
  ja jmp_260d8

jmp_26258:
  ldxdw r4, [r10-0x110]
  ldxb r5, [r4+0x18]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26280
  mov64 r4, -0x78

jmp_26280:
  ldxb r5, [r8+0x0]
  and64 r4, r5
  and64 r4, 0xff
  jne r4, 0x0, jmp_26070
  ldxb r4, [r8+0x1]
  mov64 r5, 0x1
  mov64 r6, 0x1
  jne r4, 0x0, jmp_267d0
  mov64 r6, 0x0
  stxdw [r10-0x128], r6
  ldxb r6, [r8+0x2]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_267f0

jmp_262e8:
  ldxb r6, [r8+0x3]
  jne r6, 0x0, jmp_26300

jmp_262f8:
  mov64 r5, 0x0

jmp_26300:
  ldxdw r6, [r8+0x50]
  mov64 r9, r8
  add64 r8, 0x28
  stxdw [r10-0xb0], r8
  mov64 r8, r9
  add64 r8, 0x58
  stxdw [r10-0xb8], r8
  stxdw [r10-0xc0], r6
  add64 r9, 0x48
  stxdw [r10-0xc8], r9
  stxdw [r10-0xd0], r7
  stxb [r10-0x9e], r5
  stxb [r10-0x9f], r4
  ldxdw r4, [r10-0x128]
  stxb [r10-0xa0], r4
  stdw [r10-0xa8], 0x0
  ldxdw r4, [r10-0x110]
  ldxdw r4, [r4+0x20]
  ldxdw r5, [r3+0x10]
  ldxdw r8, [r5+0x0]
  mov64 r7, r8
  add64 r7, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r7+0x0]
  jne r6, r5, jmp_26418
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r7+0x8]
  jne r6, r5, jmp_26418
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r7+0x10]
  jne r6, r5, jmp_26418
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r6, [r7+0x18]
  jeq r6, r4, jmp_26420

jmp_26418:
  mov64 r5, 0x1

jmp_26420:
  mov64 r9, 0x1
  jne r5, 0x0, jmp_26208
  ldxdw r4, [r10-0x110]
  ldxb r5, [r4+0x28]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26458
  mov64 r4, -0x78

jmp_26458:
  ldxb r5, [r8+0x0]
  and64 r4, r5
  and64 r4, 0xff
  jne r4, 0x0, jmp_26070
  ldxb r4, [r8+0x1]
  mov64 r5, 0x1
  mov64 r6, 0x1
  jne r4, 0x0, jmp_26810
  mov64 r6, 0x0
  stxdw [r10-0x128], r6
  ldxb r6, [r8+0x2]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_26830

jmp_264c0:
  ldxb r6, [r8+0x3]
  jne r6, 0x0, jmp_264d8

jmp_264d0:
  mov64 r5, 0x0

jmp_264d8:
  ldxdw r6, [r8+0x50]
  mov64 r9, r8
  add64 r8, 0x28
  stxdw [r10-0x78], r8
  mov64 r8, r9
  add64 r8, 0x58
  stxdw [r10-0x80], r8
  stxdw [r10-0x88], r6
  add64 r9, 0x48
  stxdw [r10-0x90], r9
  stxdw [r10-0x98], r7
  stxb [r10-0x66], r5
  stxb [r10-0x67], r4
  ldxdw r4, [r10-0x128]
  stxb [r10-0x68], r4
  stdw [r10-0x70], 0x0
  ldxdw r4, [r10-0x110]
  ldxdw r4, [r4+0x30]
  ldxdw r3, [r3+0x18]
  ldxdw r7, [r3+0x0]
  mov64 r3, r7
  add64 r3, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r3+0x0]
  jne r6, r5, jmp_265f0
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r3+0x8]
  jne r6, r5, jmp_265f0
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r3+0x10]
  jne r6, r5, jmp_265f0
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r6, [r3+0x18]
  jeq r6, r4, jmp_265f8

jmp_265f0:
  mov64 r5, 0x1

jmp_265f8:
  mov64 r9, 0x1
  jne r5, 0x0, jmp_26208
  ldxdw r4, [r10-0x110]
  ldxb r5, [r4+0x38]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26630
  mov64 r4, -0x78

jmp_26630:
  ldxb r5, [r7+0x0]
  and64 r4, r5
  and64 r4, 0xff
  mov64 r9, 0xb
  jne r4, 0x0, jmp_26208
  ldxb r4, [r7+0x1]
  mov64 r5, 0x1
  mov64 r9, 0x1
  jne r4, 0x0, jmp_26850
  mov64 r9, 0x0
  ldxb r6, [r7+0x2]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_26868

jmp_26698:
  mov64 r8, r1
  ldxb r1, [r7+0x3]
  jne r1, 0x0, jmp_266b8

jmp_266b0:
  mov64 r5, 0x0

jmp_266b8:
  ldxdw r1, [r7+0x50]
  mov64 r6, r7
  add64 r6, 0x28
  stxdw [r10-0x40], r6
  mov64 r6, r7
  add64 r6, 0x58
  stxdw [r10-0x48], r6
  stxdw [r10-0x50], r1
  add64 r7, 0x48
  stxdw [r10-0x58], r7
  stxdw [r10-0x60], r3
  stxb [r10-0x2e], r5
  stxb [r10-0x2f], r4
  stxb [r10-0x30], r9
  stdw [r10-0x38], 0x0
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x10]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r3
  stxdw [r10-0x18], r0
  ldxdw r2, [r10-0x110]
  stxdw [r10-0x20], r2
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x108
  mov64 r3, 0x4
  ldxdw r4, [r10-0x120]
  ldxdw r5, [r10-0x118]
  call sol_invoke_signed_c
  mov64 r9, 0x1a
  mov64 r1, r8
  ja jmp_26208

jmp_267d0:
  stxdw [r10-0x128], r6
  ldxb r6, [r8+0x2]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_262e8

jmp_267f0:
  mov64 r4, 0x0
  ldxb r6, [r8+0x3]
  jeq r6, 0x0, jmp_262f8
  ja jmp_26300

jmp_26810:
  stxdw [r10-0x128], r6
  ldxb r6, [r8+0x2]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_264c0

jmp_26830:
  mov64 r4, 0x0
  ldxb r6, [r8+0x3]
  jeq r6, 0x0, jmp_264d0
  ja jmp_264d8

jmp_26850:
  ldxb r6, [r7+0x2]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_26698

jmp_26868:
  mov64 r4, 0x0
  mov64 r8, r1
  ldxb r1, [r7+0x3]
  jeq r1, 0x0, jmp_266b0
  ja jmp_266b8

fn_26890:
  mov64 r7, 0xa
  ldxdw r0, [r2+0x20]
  jlt r0, 0x3, jmp_26b60
  stxdw [r10-0xe8], r4
  stxdw [r10-0xe0], r5
  ldxdw r4, [r2+0x18]
  stxdw [r10-0xd8], r4
  ldxdw r4, [r4+0x0]
  ldxdw r5, [r3+0x0]
  ldxdw r6, [r5+0x0]
  mov64 r8, r6
  add64 r8, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r9, [r8+0x0]
  jne r9, r5, jmp_26958
  ldxdw r5, [r4+0x8]
  ldxdw r9, [r8+0x8]
  jne r9, r5, jmp_26958
  ldxdw r5, [r4+0x10]
  ldxdw r9, [r8+0x10]
  jne r9, r5, jmp_26958
  mov64 r9, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r5, [r8+0x18]
  jeq r5, r4, jmp_26960

jmp_26958:
  mov64 r9, 0x1

jmp_26960:
  mov64 r7, 0x1
  jne r9, 0x0, jmp_26b60
  ldxdw r4, [r10-0xd8]
  ldxb r5, [r4+0x8]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26998
  mov64 r4, -0x78

jmp_26998:
  ldxb r5, [r6+0x0]
  and64 r4, r5
  and64 r4, 0xff
  jeq r4, 0x0, jmp_269c8

jmp_269b8:
  mov64 r7, 0xb
  ja jmp_26b60

jmp_269c8:
  ldxb r5, [r6+0x1]
  mov64 r9, 0x1
  mov64 r4, 0x1
  jne r5, 0x0, jmp_26b70
  mov64 r4, 0x0
  stxdw [r10-0xf0], r4
  ldxb r4, [r6+0x2]
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_26b90

jmp_26a10:
  ldxb r4, [r6+0x3]
  jne r4, 0x0, jmp_26a28

jmp_26a20:
  mov64 r9, 0x0

jmp_26a28:
  ldxdw r4, [r6+0x50]
  mov64 r7, r6
  add64 r7, 0x28
  stxdw [r10-0xb0], r7
  mov64 r7, r6
  add64 r7, 0x58
  stxdw [r10-0xb8], r7
  stxdw [r10-0xc0], r4
  add64 r6, 0x48
  stxdw [r10-0xc8], r6
  stxdw [r10-0xd0], r8
  stxb [r10-0x9e], r9
  stxb [r10-0x9f], r5
  ldxdw r4, [r10-0xf0]
  stxb [r10-0xa0], r4
  stdw [r10-0xa8], 0x0
  ldxdw r4, [r10-0xd8]
  ldxdw r4, [r4+0x10]
  ldxdw r5, [r3+0x8]
  ldxdw r5, [r5+0x0]
  mov64 r8, r5
  add64 r8, 0x8
  stxdw [r10-0xf0], r5
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r8+0x0]
  jne r6, r5, jmp_26b48
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r8+0x8]
  jne r6, r5, jmp_26b48
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r8+0x10]
  jne r6, r5, jmp_26b48
  mov64 r9, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r5, [r8+0x18]
  jeq r5, r4, jmp_26b50

jmp_26b48:
  mov64 r9, 0x1

jmp_26b50:
  mov64 r7, 0x1
  jeq r9, 0x0, jmp_26bb0

jmp_26b60:
  stxw [r1+0x0], r7
  exit

jmp_26b70:
  stxdw [r10-0xf0], r4
  ldxb r4, [r6+0x2]
  mov64 r5, 0x1
  jne r4, 0x0, jmp_26a10

jmp_26b90:
  mov64 r5, 0x0
  ldxb r4, [r6+0x3]
  jeq r4, 0x0, jmp_26a20
  ja jmp_26a28

jmp_26bb0:
  ldxdw r4, [r10-0xd8]
  ldxb r5, [r4+0x18]
  mov64 r4, -0x1
  jne r5, 0x0, jmp_26bd8
  mov64 r4, -0x78

jmp_26bd8:
  ldxdw r6, [r10-0xf0]
  ldxb r5, [r6+0x0]
  and64 r4, r5
  and64 r4, 0xff
  jne r4, 0x0, jmp_269b8
  ldxb r4, [r6+0x1]
  mov64 r5, 0x1
  jne r4, 0x0, jmp_26f68
  mov64 r7, 0x0
  stxdw [r10-0xf8], r7
  ldxb r6, [r6+0x2]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_26f88

jmp_26c40:
  mov64 r7, r8
  ldxdw r6, [r10-0xf0]
  ldxb r6, [r6+0x3]
  jne r6, 0x0, jmp_26c68

jmp_26c60:
  mov64 r5, 0x0

jmp_26c68:
  ldxdw r9, [r10-0xf0]
  ldxdw r6, [r9+0x50]
  mov64 r8, r9
  add64 r8, 0x28
  stxdw [r10-0x78], r8
  mov64 r8, r9
  add64 r8, 0x58
  stxdw [r10-0x80], r8
  stxdw [r10-0x88], r6
  add64 r9, 0x48
  stxdw [r10-0x90], r9
  stxdw [r10-0x98], r7
  stxb [r10-0x66], r5
  stxb [r10-0x67], r4
  ldxdw r4, [r10-0xf8]
  stxb [r10-0x68], r4
  stdw [r10-0x70], 0x0
  ldxdw r4, [r10-0xd8]
  ldxdw r4, [r4+0x20]
  ldxdw r3, [r3+0x10]
  ldxdw r9, [r3+0x0]
  mov64 r3, r9
  add64 r3, 0x8
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r3+0x0]
  jne r6, r5, jmp_26d88
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r3+0x8]
  jne r6, r5, jmp_26d88
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r3+0x10]
  jne r6, r5, jmp_26d88
  mov64 r8, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r5, [r3+0x18]
  jeq r5, r4, jmp_26d90

jmp_26d88:
  mov64 r8, 0x1

jmp_26d90:
  mov64 r7, 0x1
  jne r8, 0x0, jmp_26b60
  ldxdw r4, [r10-0xd8]
  ldxb r5, [r4+0x28]
  mov64 r6, -0x1
  jne r5, 0x0, jmp_26dc8
  mov64 r6, -0x78

jmp_26dc8:
  ldxb r5, [r9+0x0]
  and64 r6, r5
  and64 r6, 0xff
  mov64 r7, 0xb
  jne r6, 0x0, jmp_26b60
  ldxb r4, [r9+0x1]
  mov64 r5, 0x1
  mov64 r7, 0x1
  jne r4, 0x0, jmp_26fb8
  mov64 r7, 0x0
  ldxb r6, [r9+0x2]
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_26fd0

jmp_26e30:
  mov64 r8, r1
  ldxb r1, [r9+0x3]
  jne r1, 0x0, jmp_26e50

jmp_26e48:
  mov64 r5, 0x0

jmp_26e50:
  ldxdw r1, [r9+0x50]
  mov64 r6, r9
  add64 r6, 0x28
  stxdw [r10-0x40], r6
  mov64 r6, r9
  add64 r6, 0x58
  stxdw [r10-0x48], r6
  stxdw [r10-0x50], r1
  add64 r9, 0x48
  stxdw [r10-0x58], r9
  stxdw [r10-0x60], r3
  stxb [r10-0x2e], r5
  stxb [r10-0x2f], r4
  stxb [r10-0x30], r7
  stdw [r10-0x38], 0x0
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x10]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r3
  stxdw [r10-0x18], r0
  ldxdw r2, [r10-0xd8]
  stxdw [r10-0x20], r2
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0xd0
  mov64 r3, 0x3
  ldxdw r4, [r10-0xe8]
  ldxdw r5, [r10-0xe0]
  call sol_invoke_signed_c
  mov64 r7, 0x1a
  mov64 r1, r8
  ja jmp_26b60

jmp_26f68:
  stxdw [r10-0xf8], r7
  ldxb r6, [r6+0x2]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_26c40

jmp_26f88:
  mov64 r4, 0x0
  mov64 r7, r8
  ldxdw r6, [r10-0xf0]
  ldxb r6, [r6+0x3]
  jeq r6, 0x0, jmp_26c60
  ja jmp_26c68

jmp_26fb8:
  ldxb r6, [r9+0x2]
  mov64 r4, 0x1
  jne r6, 0x0, jmp_26e30

jmp_26fd0:
  mov64 r4, 0x0
  mov64 r8, r1
  ldxb r1, [r9+0x3]
  jeq r1, 0x0, jmp_26e48
  ja jmp_26e50

fn_26ff8:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r7, [r1+0x0]
  add64 r7, 0x8
  ldxdw r3, [r2+0x0]
  ldxdw r8, [r3+0x0]
  ldxdw r0, [r2+0x8]
  ldxdw r9, [r0+0x0]
  stxdw [r10-0x60], r7
  add64 r9, 0x8
  stxdw [r10-0x70], r9
  add64 r8, 0x8
  stxdw [r10-0x80], r8
  sth [r10-0x58], 0x100
  sth [r10-0x68], 0x1
  sth [r10-0x78], 0x1
  stb [r10-0x4a], 0xf
  ldxdw r7, [r2+0x18]
  stxdw [r10-0x49], r7
  ldxb r2, [r2+0x20]
  stxb [r10-0x41], r2
  mov64 r2, r10
  add64 r2, -0x80
  stxdw [r10-0x28], r2
  mov64 r2, r10
  add64 r2, -0x4a
  stxdw [r10-0x38], r2
  lddw r2, data_00e0
  stxdw [r10-0x40], r2
  stdw [r10-0x20], 0x3
  stdw [r10-0x30], 0xa
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r0
  stxdw [r10-0x18], r3
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, r10
  add64 r3, -0x18
  call fn_26890
  ldxdw r1, [r10-0x88]
  stxdw [r6+0x0], r1
  exit

fn_27170:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r0, [r1+0x0]
  add64 r0, 0x8
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x0]
  ldxdw r7, [r2+0x0]
  ldxdw r8, [r3+0x0]
  stxdw [r10-0x50], r0
  add64 r8, 0x8
  stxdw [r10-0x60], r8
  add64 r7, 0x8
  stxdw [r10-0x70], r7
  sth [r10-0x48], 0x100
  sth [r10-0x58], 0x0
  sth [r10-0x68], 0x1
  mov64 r0, r10
  add64 r0, -0x70
  stxdw [r10-0x28], r0
  lddw r0, str_0508
  stxdw [r10-0x38], r0
  lddw r0, data_00e0
  stxdw [r10-0x40], r0
  stdw [r10-0x20], 0x3
  stdw [r10-0x30], 0x1
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r3
  stxdw [r10-0x18], r2
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, r10
  add64 r3, -0x18
  call fn_26890
  ldxdw r1, [r10-0x78]
  stxdw [r6+0x0], r1
  exit

fn_272c0:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r7, [r1+0x0]
  add64 r7, 0x8
  ldxdw r3, [r2+0x0]
  ldxdw r8, [r3+0x0]
  ldxdw r0, [r2+0x8]
  ldxdw r9, [r0+0x0]
  stxdw [r10-0x60], r7
  add64 r9, 0x8
  stxdw [r10-0x70], r9
  add64 r8, 0x8
  stxdw [r10-0x80], r8
  sth [r10-0x58], 0x100
  sth [r10-0x68], 0x1
  sth [r10-0x78], 0x1
  stb [r10-0x4a], 0xe
  ldxdw r7, [r2+0x18]
  stxdw [r10-0x49], r7
  ldxb r2, [r2+0x20]
  stxb [r10-0x41], r2
  mov64 r2, r10
  add64 r2, -0x80
  stxdw [r10-0x28], r2
  mov64 r2, r10
  add64 r2, -0x4a
  stxdw [r10-0x38], r2
  lddw r2, data_00e0
  stxdw [r10-0x40], r2
  stdw [r10-0x20], 0x3
  stdw [r10-0x30], 0xa
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r0
  stxdw [r10-0x18], r3
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, r10
  add64 r3, -0x18
  call fn_26890
  ldxdw r1, [r10-0x88]
  stxdw [r6+0x0], r1
  exit

fn_27438:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r0, [r1+0x0]
  add64 r0, 0x8
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x0]
  ldxdw r7, [r2+0x0]
  ldxdw r8, [r3+0x0]
  stxdw [r10-0x50], r0
  add64 r8, 0x8
  stxdw [r10-0x60], r8
  add64 r7, 0x8
  stxdw [r10-0x70], r7
  sth [r10-0x48], 0x100
  sth [r10-0x58], 0x0
  sth [r10-0x68], 0x1
  mov64 r0, r10
  add64 r0, -0x70
  stxdw [r10-0x28], r0
  lddw r0, data_0509
  stxdw [r10-0x38], r0
  lddw r0, data_00e0
  stxdw [r10-0x40], r0
  stdw [r10-0x20], 0x3
  stdw [r10-0x30], 0x1
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r3
  stxdw [r10-0x18], r2
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, r10
  add64 r3, -0x18
  call fn_26890
  ldxdw r1, [r10-0x78]
  stxdw [r6+0x0], r1
  exit

fn_27588:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r7, [r1+0x0]
  add64 r7, 0x8
  ldxdw r3, [r2+0x0]
  ldxdw r8, [r3+0x0]
  ldxdw r0, [r2+0x8]
  ldxdw r9, [r0+0x0]
  stxdw [r10-0x60], r7
  add64 r9, 0x8
  stxdw [r10-0x70], r9
  add64 r8, 0x8
  stxdw [r10-0x80], r8
  sth [r10-0x58], 0x100
  sth [r10-0x68], 0x1
  sth [r10-0x78], 0x1
  stb [r10-0x49], 0x3
  ldxdw r2, [r2+0x18]
  stxdw [r10-0x48], r2
  mov64 r2, r10
  add64 r2, -0x80
  stxdw [r10-0x28], r2
  mov64 r2, r10
  add64 r2, -0x49
  stxdw [r10-0x38], r2
  lddw r2, data_00e0
  stxdw [r10-0x40], r2
  stdw [r10-0x20], 0x3
  stdw [r10-0x30], 0x9
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r0
  stxdw [r10-0x18], r3
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, r10
  add64 r3, -0x18
  call fn_26890
  ldxdw r1, [r10-0x88]
  stxdw [r6+0x0], r1
  exit

fn_276f0:
  stxdw [r10-0xb0], r4
  mov64 r6, r3
  stxdw [r10-0xa8], r1
  ldxdw r5, [r2+0x18]
  ldxdw r8, [r5+0x0]
  add64 r8, 0x8
  ldxdw r4, [r2+0x0]
  ldxdw r9, [r4+0x0]
  ldxdw r0, [r2+0x8]
  ldxdw r3, [r0+0x0]
  ldxdw r7, [r2+0x10]
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x68], r8
  add64 r1, 0x8
  stxdw [r10-0x78], r1
  add64 r3, 0x8
  stxdw [r10-0x88], r3
  add64 r9, 0x8
  stxdw [r10-0x98], r9
  sth [r10-0x60], 0x100
  sth [r10-0x70], 0x1
  sth [r10-0x80], 0x0
  sth [r10-0x90], 0x1
  stb [r10-0x52], 0xc
  ldxdw r1, [r2+0x20]
  stxdw [r10-0x51], r1
  ldxb r1, [r2+0x28]
  stxb [r10-0x49], r1
  mov64 r1, r10
  add64 r1, -0x98
  stxdw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0x52
  stxdw [r10-0x40], r1
  lddw r1, data_00e0
  stxdw [r10-0x48], r1
  stdw [r10-0x28], 0x4
  stdw [r10-0x38], 0xa
  stxdw [r10-0x8], r5
  stxdw [r10-0x10], r7
  stxdw [r10-0x18], r0
  stxdw [r10-0x20], r4
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r10
  add64 r2, -0x48
  mov64 r3, r10
  add64 r3, -0x20
  mov64 r4, r6
  ldxdw r5, [r10-0xb0]
  call fn_25f48
  ldxdw r1, [r10-0xa0]
  ldxdw r2, [r10-0xa8]
  stxdw [r2+0x0], r1
  exit

fn_278b0:
  mov64 r9, 0xa
  ldxdw r0, [r2+0x20]
  jlt r0, 0x2, jmp_27d08
  stxdw [r10-0xa8], r4
  stxdw [r10-0xa0], r5
  ldxdw r4, [r2+0x18]
  ldxdw r9, [r4+0x0]
  ldxdw r6, [r3+0x0]
  ldxdw r7, [r6+0x0]
  mov64 r8, r7
  add64 r8, 0x8
  ldxdw r6, [r9+0x0]
  ldxdw r5, [r8+0x0]
  jne r5, r6, jmp_27970
  ldxdw r5, [r9+0x8]
  ldxdw r6, [r8+0x8]
  jne r6, r5, jmp_27970
  ldxdw r5, [r9+0x10]
  ldxdw r6, [r8+0x10]
  jne r6, r5, jmp_27970
  mov64 r6, 0x0
  ldxdw r5, [r9+0x18]
  ldxdw r9, [r8+0x18]
  jeq r9, r5, jmp_27978

jmp_27970:
  mov64 r6, 0x1

jmp_27978:
  mov64 r9, 0x1
  jne r6, 0x0, jmp_27d08
  ldxb r5, [r4+0x8]
  mov64 r6, -0x1
  jne r5, 0x0, jmp_279a8
  mov64 r6, -0x78

jmp_279a8:
  ldxb r5, [r7+0x0]
  and64 r6, r5
  mov64 r9, 0xb
  and64 r6, 0xff
  jne r6, 0x0, jmp_27d08
  ldxb r5, [r7+0x1]
  mov64 r6, 0x1
  stxdw [r10-0xb0], r6
  jeq r5, 0x0, jmp_27d18
  ldxb r5, [r7+0x2]
  mov64 r9, 0x1
  jeq r5, 0x0, jmp_27d38

jmp_27a08:
  stxdw [r10-0xb8], r6
  ldxb r5, [r7+0x3]
  jne r5, 0x0, jmp_27a30

jmp_27a20:
  mov64 r5, 0x0
  stxdw [r10-0xb0], r5

jmp_27a30:
  ldxdw r5, [r7+0x50]
  mov64 r6, r7
  add64 r6, 0x28
  stxdw [r10-0x78], r6
  mov64 r6, r7
  add64 r6, 0x58
  stxdw [r10-0x80], r6
  stxdw [r10-0x88], r5
  add64 r7, 0x48
  stxdw [r10-0x90], r7
  stxdw [r10-0x98], r8
  ldxdw r5, [r10-0xb0]
  stxb [r10-0x66], r5
  stxb [r10-0x67], r9
  ldxdw r5, [r10-0xb8]
  stxb [r10-0x68], r5
  stdw [r10-0x70], 0x0
  ldxdw r8, [r4+0x10]
  ldxdw r3, [r3+0x8]
  ldxdw r7, [r3+0x0]
  mov64 r3, r7
  add64 r3, 0x8
  ldxdw r5, [r8+0x0]
  ldxdw r6, [r3+0x0]
  jne r6, r5, jmp_27b48
  ldxdw r5, [r8+0x8]
  ldxdw r6, [r3+0x8]
  jne r6, r5, jmp_27b48
  ldxdw r5, [r8+0x10]
  ldxdw r6, [r3+0x10]
  jne r6, r5, jmp_27b48
  mov64 r6, 0x0
  ldxdw r5, [r8+0x18]
  ldxdw r8, [r3+0x18]
  jeq r8, r5, jmp_27b50

jmp_27b48:
  mov64 r6, 0x1

jmp_27b50:
  mov64 r9, 0x1
  jne r6, 0x0, jmp_27d08
  ldxb r5, [r4+0x18]
  mov64 r6, -0x1
  jne r5, 0x0, jmp_27b80
  mov64 r6, -0x78

jmp_27b80:
  ldxb r5, [r7+0x0]
  and64 r6, r5
  and64 r6, 0xff
  mov64 r9, 0xb
  jne r6, 0x0, jmp_27d08
  ldxb r5, [r7+0x1]
  mov64 r8, 0x1
  mov64 r6, 0x1
  jeq r5, 0x0, jmp_27d60
  ldxb r5, [r7+0x2]
  mov64 r9, 0x1
  jeq r5, 0x0, jmp_27d80

jmp_27be0:
  stxdw [r10-0xb0], r1
  ldxb r1, [r7+0x3]
  jne r1, 0x0, jmp_27c00

jmp_27bf8:
  mov64 r8, 0x0

jmp_27c00:
  ldxdw r1, [r7+0x50]
  mov64 r5, r7
  add64 r5, 0x28
  stxdw [r10-0x40], r5
  mov64 r5, r7
  add64 r5, 0x58
  stxdw [r10-0x48], r5
  stxdw [r10-0x50], r1
  add64 r7, 0x48
  stxdw [r10-0x58], r7
  stxdw [r10-0x60], r3
  stxb [r10-0x2e], r8
  stxb [r10-0x2f], r9
  stxb [r10-0x30], r6
  stdw [r10-0x38], 0x0
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x10]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r3
  stxdw [r10-0x18], r0
  stxdw [r10-0x20], r4
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r3, 0x2
  ldxdw r4, [r10-0xa8]
  ldxdw r5, [r10-0xa0]
  call sol_invoke_signed_c
  mov64 r9, 0x1a
  ldxdw r1, [r10-0xb0]

jmp_27d08:
  stxw [r1+0x0], r9
  exit

jmp_27d18:
  mov64 r6, 0x0
  ldxb r5, [r7+0x2]
  mov64 r9, 0x1
  jne r5, 0x0, jmp_27a08

jmp_27d38:
  mov64 r9, 0x0
  stxdw [r10-0xb8], r6
  ldxb r5, [r7+0x3]
  jeq r5, 0x0, jmp_27a20
  ja jmp_27a30

jmp_27d60:
  mov64 r6, 0x0
  ldxb r5, [r7+0x2]
  mov64 r9, 0x1
  jne r5, 0x0, jmp_27be0

jmp_27d80:
  mov64 r9, 0x0
  stxdw [r10-0xb0], r1
  ldxb r1, [r7+0x3]
  jeq r1, 0x0, jmp_27bf8
  ja jmp_27c00

fn_27da8:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x0]
  ldxdw r0, [r1+0x0]
  mov64 r3, r0
  add64 r3, 0x8
  stxdw [r10-0x80], r3
  sth [r10-0x78], 0x101
  stb [r10-0x69], 0x0
  sth [r10-0x6b], 0x0
  stb [r10-0x6c], 0x8
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x68], r1
  mov64 r1, 0xb
  ldxb r2, [r0+0x0]
  jne r2, 0x0, jmp_27f88
  ldxb r1, [r0+0x1]
  ldxb r2, [r0+0x2]
  ldxb r7, [r0+0x3]
  ldxdw r8, [r0+0x50]
  mov64 r9, r0
  add64 r9, 0x28
  stxdw [r10-0x40], r9
  mov64 r9, r0
  add64 r9, 0x58
  stxdw [r10-0x48], r9
  stxdw [r10-0x50], r8
  add64 r0, 0x48
  stxdw [r10-0x58], r0
  stxdw [r10-0x60], r3
  mov64 r3, 0x1
  jeq r7, 0x0, jmp_27f98
  stxb [r10-0x2e], r3
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_27fb8

jmp_27ec8:
  stxb [r10-0x2f], r3
  mov64 r2, 0x1
  jne r1, 0x0, jmp_27ee8

jmp_27ee0:
  mov64 r2, 0x0

jmp_27ee8:
  stxb [r10-0x30], r2
  stdw [r10-0x38], 0x0
  mov64 r1, r10
  add64 r1, -0x6c
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x80
  stxdw [r10-0x20], r1
  lddw r1, data_0100
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0xc
  stdw [r10-0x18], 0x1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r3, 0x1
  call sol_invoke_signed_c
  mov64 r1, 0x1a

jmp_27f88:
  stxw [r6+0x0], r1
  exit

jmp_27f98:
  mov64 r3, 0x0
  stxb [r10-0x2e], r3
  mov64 r3, 0x1
  jne r2, 0x0, jmp_27ec8

jmp_27fb8:
  mov64 r3, 0x0
  stxb [r10-0x2f], r3
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_27ee0
  ja jmp_27ee8

fn_27fe0:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r1+0x0]
  mov64 r1, r3
  add64 r1, 0x8
  stxdw [r10-0x98], r1
  sth [r10-0x90], 0x101
  stb [r10-0x81], 0x0
  sth [r10-0x83], 0x0
  stb [r10-0x84], 0x1
  ldxdw r2, [r2+0x8]
  ldxdw r0, [r2+0x18]
  stxdw [r10-0x68], r0
  ldxdw r0, [r2+0x10]
  stxdw [r10-0x70], r0
  ldxdw r0, [r2+0x8]
  stxdw [r10-0x78], r0
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x80], r2
  mov64 r2, 0xb
  ldxb r0, [r3+0x0]
  jne r0, 0x0, jmp_281f8
  ldxb r2, [r3+0x1]
  ldxb r0, [r3+0x2]
  ldxb r7, [r3+0x3]
  ldxdw r8, [r3+0x50]
  mov64 r9, r3
  add64 r9, 0x28
  stxdw [r10-0x40], r9
  mov64 r9, r3
  add64 r9, 0x58
  stxdw [r10-0x48], r9
  stxdw [r10-0x50], r8
  add64 r3, 0x48
  stxdw [r10-0x58], r3
  stxdw [r10-0x60], r1
  mov64 r1, 0x1
  jeq r7, 0x0, jmp_28208
  stxb [r10-0x2e], r1
  mov64 r1, 0x1
  jeq r0, 0x0, jmp_28228

jmp_28138:
  stxb [r10-0x2f], r1
  mov64 r1, 0x1
  jne r2, 0x0, jmp_28158

jmp_28150:
  mov64 r1, 0x0

jmp_28158:
  stxb [r10-0x30], r1
  stdw [r10-0x38], 0x0
  mov64 r1, r10
  add64 r1, -0x84
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x98
  stxdw [r10-0x20], r1
  lddw r1, data_0100
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x24
  stdw [r10-0x18], 0x1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r3, 0x1
  call sol_invoke_signed_c
  mov64 r2, 0x1a

jmp_281f8:
  stxw [r6+0x0], r2
  exit

jmp_28208:
  mov64 r1, 0x0
  stxb [r10-0x2e], r1
  mov64 r1, 0x1
  jne r0, 0x0, jmp_28138

jmp_28228:
  mov64 r1, 0x0
  stxb [r10-0x2f], r1
  mov64 r1, 0x1
  jeq r2, 0x0, jmp_28150
  ja jmp_28158

fn_28250:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x8]
  ldxdw r0, [r1+0x0]
  add64 r0, 0x8
  ldxdw r3, [r2+0x0]
  ldxdw r7, [r3+0x0]
  stxdw [r10-0x80], r0
  add64 r7, 0x8
  stxdw [r10-0x90], r7
  sth [r10-0x78], 0x101
  sth [r10-0x88], 0x101
  stw [r10-0x6c], 0x0
  ldxdw r0, [r2+0x18]
  stxdw [r10-0x68], r0
  ldxdw r0, [r2+0x20]
  stxdw [r10-0x60], r0
  ldxdw r2, [r2+0x10]
  ldxdw r0, [r2+0x18]
  stxdw [r10-0x40], r0
  ldxdw r0, [r2+0x10]
  stxdw [r10-0x48], r0
  ldxdw r0, [r2+0x8]
  stxdw [r10-0x50], r0
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x58], r2
  mov64 r2, r10
  add64 r2, -0x90
  stxdw [r10-0x20], r2
  mov64 r2, r10
  add64 r2, -0x6c
  stxdw [r10-0x30], r2
  lddw r2, data_0100
  stxdw [r10-0x38], r2
  stdw [r10-0x18], 0x2
  stdw [r10-0x28], 0x34
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r3
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, r10
  add64 r3, -0x10
  call fn_278b0
  ldxdw r1, [r10-0x98]
  stxdw [r6+0x0], r1
  exit

fn_283e0:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r6, r1
  ldxdw r1, [r2+0x8]
  ldxdw r0, [r1+0x0]
  add64 r0, 0x8
  ldxdw r3, [r2+0x0]
  ldxdw r7, [r3+0x0]
  stxdw [r10-0x58], r0
  add64 r7, 0x8
  stxdw [r10-0x68], r7
  sth [r10-0x50], 0x1
  sth [r10-0x60], 0x101
  stb [r10-0x41], 0x0
  sth [r10-0x43], 0x0
  stb [r10-0x44], 0x2
  ldxdw r2, [r2+0x10]
  stxdw [r10-0x40], r2
  mov64 r2, r10
  add64 r2, -0x68
  stxdw [r10-0x20], r2
  mov64 r2, r10
  add64 r2, -0x44
  stxdw [r10-0x30], r2
  lddw r2, data_0100
  stxdw [r10-0x38], r2
  stdw [r10-0x18], 0x2
  stdw [r10-0x28], 0xc
  stxdw [r10-0x8], r1
  stxdw [r10-0x10], r3
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, r10
  add64 r3, -0x10
  call fn_278b0
  ldxdw r1, [r10-0x70]
  stxdw [r6+0x0], r1
  exit

fn_28528:
  ldxdw r2, [r2+0x0]
  ldxb r3, [r2+0x0]
  mov64 r4, r3
  and64 r4, 0x8
  jne r4, 0x0, jmp_285a8
  mov64 r4, r3
  and64 r4, 0x7
  jeq r4, 0x7, jmp_285a8
  add64 r3, 0x1
  stxb [r2+0x0], r3
  ldxdw r3, [r2+0x50]
  stxdw [r1+0x8], r3
  stxdw [r1+0x10], r2
  stb [r1+0x18], 0x0
  add64 r2, 0x58
  ja jmp_285b8

jmp_285a8:
  stw [r1+0x8], 0xb
  mov64 r2, 0x0

jmp_285b8:
  stxdw [r1+0x0], r2
  exit

fn_285c8:
  mov64 r9, r3
  ldxdw r6, [r2+0x0]
  ldxb r2, [r6+0x0]
  mov64 r3, r2
  and64 r3, 0xf
  jeq r3, 0x0, jmp_28610
  mov64 r8, 0xb
  mov64 r7, 0x0
  ja jmp_287c8

jmp_28610:
  mov64 r8, 0x1a
  mov64 r0, r2
  or64 r0, 0x8
  stxb [r6+0x0], r0
  ldxdw r5, [r6+0x50]
  mov64 r7, r5
  rsh64 r7, 0x20
  jeq r9, r5, jmp_287c0
  ldxw r8, [r6+0x4]
  lsh64 r8, 0x20
  arsh64 r8, 0x20
  jslt r8, 0x0, jmp_286a8
  lddw r3, 0x80000000
  mov64 r8, r5
  or64 r8, r3
  stxw [r6+0x4], r8
  mov64 r8, r5
  ja jmp_286b0

jmp_286a8:
  and64 r8, 0x7fffffff

jmp_286b0:
  mov64 r3, r9
  sub64 r3, r8
  mov64 r8, 0x0
  stxdw [r10-0x8], r8
  mov64 r8, 0x1
  jle r3, r9, jmp_28708
  jeq r8, 0x0, jmp_28718

jmp_286e8:
  mov64 r8, 0x13
  ldxdw r3, [r10-0x8]
  jle r3, 0x2800, jmp_28738
  ja jmp_287c0

jmp_28708:
  mov64 r8, 0x0
  jne r8, 0x0, jmp_286e8

jmp_28718:
  stxdw [r10-0x8], r3
  mov64 r8, 0x13
  ldxdw r3, [r10-0x8]
  jgt r3, 0x2800, jmp_287c0

jmp_28738:
  stxdw [r6+0x50], r9
  mov64 r2, r0
  jeq r4, 0x0, jmp_287b0
  jle r9, r5, jmp_287b0
  mov64 r2, r6
  add64 r2, 0x58
  add64 r2, r5
  sub64 r9, r5
  mov64 r8, r1
  mov64 r1, r2
  mov64 r2, 0x0
  mov64 r3, r9
  call sol_memset_
  mov64 r1, r8
  ldxb r2, [r6+0x0]

jmp_287b0:
  and64 r2, -0x9
  mov64 r8, 0x1a

jmp_287c0:
  stxb [r6+0x0], r2

jmp_287c8:
  stxw [r1+0x4], r7
  stxw [r1+0x0], r8
  exit

fn_287e0:
  call sol_log_data
  exit

fn_287f0:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x28
  call sol_get_clock_sysvar
  jeq r0, 0x0, jmp_28898
  lddw r2, -0x100000000
  mov64 r1, r0
  add64 r1, r2
  mov64 r2, r1
  rsh64 r2, 0x20
  lsh64 r1, 0x20
  or64 r1, r2
  jge r1, 0x1a, jmp_288f8
  mov64 r2, r1
  lsh64 r2, 0x2
  lddw r3, data_050c
  add64 r3, r2
  ldxw r0, [r3+0x0]
  ja jmp_28900

jmp_28898:
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x28], r1
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x20], r1
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x18], r1
  ldxdw r1, [r10-0x20]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x28]
  stxdw [r6+0x8], r1
  mov64 r1, 0x0
  ja jmp_28918

jmp_288f8:
  mov64 r1, 0x0

jmp_28900:
  stxw [r6+0x8], r0
  stxw [r6+0x4], r1
  mov64 r1, 0x1

jmp_28918:
  stxw [r6+0x0], r1
  exit

fn_28928:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x18
  call sol_get_rent_sysvar
  jeq r0, 0x0, jmp_289d0
  lddw r2, -0x100000000
  mov64 r1, r0
  add64 r1, r2
  mov64 r2, r1
  rsh64 r2, 0x20
  lsh64 r1, 0x20
  or64 r1, r2
  jge r1, 0x1a, jmp_28a10
  mov64 r2, r1
  lsh64 r2, 0x2
  lddw r3, data_050c
  add64 r3, r2
  ldxw r0, [r3+0x0]
  ja jmp_28a18

jmp_289d0:
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x18], r1
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x8], r1
  mov64 r1, 0x0
  ja jmp_28a30

jmp_28a10:
  mov64 r1, 0x0

jmp_28a18:
  stxw [r6+0x8], r0
  stxw [r6+0x4], r1
  mov64 r1, 0x1

jmp_28a30:
  stxw [r6+0x0], r1
  exit

fn_28a40:
  call fn_28a70

fn_28a48:
  call fn_28a60

fn_28a50:
  call sol_log_
  exit

fn_28a60:
  call custom_panic
  call abort

fn_28a70:
  call abort

fn_28a78:
  lddw r1, str_0574
  mov64 r2, 0x2e
  call fn_28a50
  call fn_28a40

fn_28aa0:
  call fn_28a78

fn_28aa8:
  mov64 r2, r1
  lddw r1, data_0ec8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_28b00:
  jne r1, 0x0, jmp_28b18
  mov64 r1, r3
  call fn_28aa8

jmp_28b18:
  call fn_28b20

fn_28b20:
  mov64 r3, r1
  mov64 r1, r2
  mov64 r2, r3
  call fn_25f30

fn_28b40:
  stxdw [r10-0x10], r2
  stxdw [r10-0x18], r1
  sth [r10-0x8], 0x1
  mov64 r1, r10
  add64 r1, -0x18
  call fn_28a48

fn_28b70:
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  lddw r1, data_0f28
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x10], r1
  lddw r1, 0x4fbf
  stxdw [r10-0x8], r1
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x20], r1
  stdw [r10-0x30], 0x0
  stdw [r10-0x48], 0x2
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r3
  call fn_28b40

fn_28c38:
  mov64 r0, r1
  ldxdw r6, [r5-0xff8]
  jeq r2, 0x0, jmp_28c88
  mov64 r2, 0x110000
  ldxw r8, [r0+0x10]
  mov64 r1, r8
  and64 r1, 0x200000
  jne r1, 0x0, jmp_28ca0
  mov64 r9, r6
  ja jmp_28cb8

jmp_28c88:
  mov64 r2, 0x2d
  ldxw r8, [r0+0x10]
  ja jmp_28ca8

jmp_28ca0:
  mov64 r2, 0x2b

jmp_28ca8:
  mov64 r9, r6
  add64 r9, 0x1

jmp_28cb8:
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0x28], r1
  mov64 r1, r8
  and64 r1, 0x800000
  stxdw [r10-0x18], r4
  stxdw [r10-0x20], r2
  jne r1, 0x0, jmp_28da8
  mov64 r1, 0x0
  stxdw [r10-0x10], r1
  mov64 r7, r9
  ldxh r2, [r0+0x14]
  jlt r7, r2, jmp_28e80

jmp_28d18:
  mov64 r9, r6
  ldxdw r8, [r0+0x8]
  ldxdw r7, [r0+0x0]
  mov64 r1, r7
  mov64 r2, r8
  ldxdw r3, [r10-0x20]
  ldxdw r4, [r10-0x10]
  ldxdw r5, [r10-0x18]
  call fn_29230
  mov64 r6, 0x1
  jne r0, 0x0, jmp_29218
  ldxdw r4, [r8+0x18]
  mov64 r1, r7
  ldxdw r2, [r10-0x28]
  mov64 r3, r9
  callx r4
  mov64 r6, r0
  ja jmp_29218

jmp_28da8:
  stxdw [r10-0x10], r3
  jge r4, 0x20, jmp_28e38
  mov64 r7, 0x0
  jeq r4, 0x0, jmp_28e68
  ldxdw r1, [r10-0x10]
  mov64 r2, r4
  ja jmp_28e00

jmp_28de0:
  add64 r7, r3
  add64 r1, 0x1
  add64 r2, -0x1
  jeq r2, 0x0, jmp_28e68

jmp_28e00:
  ldxb r4, [r1+0x0]
  lsh64 r4, 0x38
  arsh64 r4, 0x38
  mov64 r3, 0x1
  jsgt r4, -0x41, jmp_28de0
  mov64 r3, 0x0
  ja jmp_28de0

jmp_28e38:
  mov64 r1, r3
  mov64 r2, r4
  stxdw [r10-0x38], r0
  call fn_29318
  mov64 r7, r0
  ldxdw r0, [r10-0x38]

jmp_28e68:
  add64 r7, r9
  ldxh r2, [r0+0x14]
  jge r7, r2, jmp_28d18

jmp_28e80:
  mov64 r1, r8
  and64 r1, 0x1000000
  stxdw [r10-0x40], r6
  jne r1, 0x0, jmp_28ef0
  sub64 r2, r7
  stxdw [r10-0x8], r8
  mov64 r1, r8
  rsh64 r1, 0x1d
  and64 r1, 0x3
  jsgt r1, 0x1, jmp_28ff8
  mov64 r8, 0x0
  jeq r1, 0x0, jmp_29020
  mov64 r8, r2
  ja jmp_29020

jmp_28ef0:
  stxdw [r10-0x30], r2
  ldxdw r2, [r0+0x10]
  lddw r1, 0x9fe00000
  stxdw [r10-0x48], r2
  and64 r2, r1
  or64 r2, 0x20000030
  stxw [r0+0x10], r2
  ldxdw r1, [r0+0x0]
  stxdw [r10-0x38], r0
  ldxdw r9, [r0+0x8]
  stxdw [r10-0x8], r1
  mov64 r2, r9
  ldxdw r3, [r10-0x20]
  ldxdw r4, [r10-0x10]
  ldxdw r5, [r10-0x18]
  call fn_29230
  mov64 r6, 0x1
  jne r0, 0x0, jmp_29218
  ldxdw r8, [r10-0x30]
  sub64 r8, r7
  mov64 r7, 0x0
  and64 r8, 0xffff

jmp_28fa8:
  mov64 r1, r7
  and64 r1, 0xffff
  jge r1, r8, jmp_291c8
  ldxdw r3, [r9+0x20]
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x30
  callx r3
  add64 r7, 0x1
  jeq r0, 0x0, jmp_28fa8
  ja jmp_29218

jmp_28ff8:
  mov64 r8, r2
  jne r1, 0x2, jmp_29020
  mov64 r8, r2
  and64 r8, 0xfffe
  rsh64 r8, 0x1

jmp_29020:
  stxdw [r10-0x30], r2
  ldxdw r1, [r10-0x8]
  and64 r1, 0x1fffff
  stxdw [r10-0x8], r1
  mov64 r6, 0x0
  ldxdw r7, [r0+0x8]
  ldxdw r9, [r0+0x0]

jmp_29058:
  mov64 r1, r8
  and64 r1, 0xffff
  mov64 r2, r6
  and64 r2, 0xffff
  jge r2, r1, jmp_290c0
  ldxdw r3, [r7+0x20]
  mov64 r1, r9
  ldxdw r2, [r10-0x8]
  callx r3
  add64 r6, 0x1
  jeq r0, 0x0, jmp_29058
  mov64 r6, 0x1
  ja jmp_29218

jmp_290c0:
  mov64 r1, r9
  mov64 r2, r7
  ldxdw r3, [r10-0x20]
  ldxdw r4, [r10-0x10]
  ldxdw r5, [r10-0x18]
  call fn_29230
  mov64 r6, 0x1
  jne r0, 0x0, jmp_29218
  ldxdw r4, [r7+0x18]
  mov64 r1, r9
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x40]
  callx r4
  ldxdw r2, [r10-0x30]
  jne r0, 0x0, jmp_29218
  sub64 r2, r8
  mov64 r8, 0x0
  and64 r2, 0xffff
  stxdw [r10-0x30], r2

jmp_29158:
  mov64 r1, r8
  and64 r1, 0xffff
  mov64 r6, 0x1
  jlt r1, r2, jmp_29180
  mov64 r6, 0x0

jmp_29180:
  jge r1, r2, jmp_29218
  ldxdw r3, [r7+0x20]
  mov64 r1, r9
  ldxdw r2, [r10-0x8]
  callx r3
  ldxdw r2, [r10-0x30]
  add64 r8, 0x1
  jeq r0, 0x0, jmp_29158
  ja jmp_29218

jmp_291c8:
  ldxdw r4, [r9+0x18]
  ldxdw r1, [r10-0x8]
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x40]
  callx r4
  jne r0, 0x0, jmp_29218
  ldxdw r1, [r10-0x38]
  ldxdw r2, [r10-0x48]
  stxdw [r1+0x10], r2
  mov64 r6, 0x0

jmp_29218:
  and64 r6, 0x1
  mov64 r0, r6
  exit

fn_29230:
  mov64 r6, r5
  mov64 r7, r4
  mov64 r8, r2
  mov64 r2, r3
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jeq r2, 0x110000, jmp_292a8
  ldxdw r4, [r8+0x20]
  mov64 r9, r1
  mov64 r2, r3
  callx r4
  mov64 r1, r9
  mov64 r2, r0
  mov64 r0, 0x1
  jne r2, 0x0, jmp_292e0

jmp_292a8:
  jeq r7, 0x0, jmp_292d8
  ldxdw r4, [r8+0x18]
  mov64 r2, r7
  mov64 r3, r6
  callx r4
  ja jmp_292e0

jmp_292d8:
  mov64 r0, 0x0

jmp_292e0:
  exit

fn_292e8:
  call fn_29e38

fn_292f0:
  call fn_29f00

fn_292f8:
  mov64 r4, r1
  mov64 r1, r2
  mov64 r2, r4
  call fn_29fc8

fn_29318:
  mov64 r7, r1
  add64 r7, 0x7
  and64 r7, -0x8
  mov64 r3, r7
  sub64 r3, r1
  jge r2, r3, jmp_293b8

jmp_29348:
  mov64 r0, 0x0
  jne r2, 0x0, jmp_29380
  ja jmp_298d8

jmp_29360:
  add64 r0, r3
  add64 r1, 0x1
  add64 r2, -0x1
  jeq r2, 0x0, jmp_298d8

jmp_29380:
  ldxb r4, [r1+0x0]
  lsh64 r4, 0x38
  arsh64 r4, 0x38
  mov64 r3, 0x1
  jsgt r4, -0x41, jmp_29360
  mov64 r3, 0x0
  ja jmp_29360

jmp_293b8:
  mov64 r5, r2
  sub64 r5, r3
  jlt r5, 0x8, jmp_29348
  stxdw [r10-0x8], r3
  mov64 r2, r5
  and64 r2, 0x7
  mov64 r0, 0x0
  mov64 r3, 0x0
  jne r7, r1, jmp_29710

jmp_29400:
  ldxdw r4, [r10-0x8]
  add64 r1, r4
  jeq r2, 0x0, jmp_294a0
  mov64 r0, r5
  and64 r0, -0x8
  mov64 r4, r1
  add64 r4, r0
  mov64 r0, 0x0
  ja jmp_29468

jmp_29448:
  add64 r0, r6
  add64 r4, 0x1
  add64 r2, -0x1
  jeq r2, 0x0, jmp_294a0

jmp_29468:
  ldxb r7, [r4+0x0]
  lsh64 r7, 0x38
  arsh64 r7, 0x38
  mov64 r6, 0x1
  jsgt r7, -0x41, jmp_29448
  mov64 r6, 0x0
  ja jmp_29448

jmp_294a0:
  rsh64 r5, 0x3
  add64 r0, r3
  lddw r9, 0x101010101010101
  ja jmp_29578

jmp_294c8:
  mov64 r1, r7
  add64 r1, r5
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x10], r7
  mov64 r7, r2
  and64 r7, 0x3
  mov64 r5, r3
  sub64 r5, r2
  mov64 r6, r4
  lddw r8, 0xff00ff00ff00ff
  and64 r6, r8
  rsh64 r4, 0x8
  and64 r4, r8
  add64 r4, r6
  lddw r6, 0x1000100010001
  mul64 r4, r6
  rsh64 r4, 0x30
  add64 r4, r0
  mov64 r0, r4
  jne r7, 0x0, jmp_297b8

jmp_29578:
  mov64 r3, r5
  mov64 r7, r1
  jeq r3, 0x0, jmp_298d8
  mov64 r1, r3
  jlt r3, 0xc0, jmp_295a8
  mov64 r1, 0xc0

jmp_295a8:
  stxdw [r10-0x8], r1
  mov64 r5, r1
  lsh64 r5, 0x3
  mov64 r4, 0x0
  jlt r3, 0x4, jmp_294c8
  mov64 r2, r5
  and64 r2, 0x7e0
  mov64 r1, r7
  add64 r1, r2
  mov64 r2, r7

jmp_295f8:
  ldxdw r6, [r2+0x0]
  mov64 r8, r6
  rsh64 r8, 0x6
  xor64 r6, -0x1
  rsh64 r6, 0x7
  or64 r6, r8
  and64 r6, r9
  add64 r6, r4
  ldxdw r4, [r2+0x8]
  mov64 r8, r4
  rsh64 r8, 0x6
  xor64 r4, -0x1
  rsh64 r4, 0x7
  or64 r4, r8
  and64 r4, r9
  add64 r4, r6
  ldxdw r6, [r2+0x10]
  mov64 r8, r6
  rsh64 r8, 0x6
  xor64 r6, -0x1
  rsh64 r6, 0x7
  or64 r6, r8
  and64 r6, r9
  add64 r6, r4
  ldxdw r4, [r2+0x18]
  mov64 r8, r4
  rsh64 r8, 0x6
  xor64 r4, -0x1
  rsh64 r4, 0x7
  or64 r4, r8
  and64 r4, r9
  add64 r4, r6
  add64 r2, 0x20
  jne r2, r1, jmp_295f8
  ja jmp_294c8

jmp_29710:
  mov64 r6, r1
  sub64 r6, r7
  mov64 r7, r1
  ja jmp_29748

jmp_29730:
  add64 r3, r9
  add64 r7, 0x1
  jeq r8, 0x1, jmp_29400

jmp_29748:
  ldxb r4, [r7+0x0]
  lsh64 r4, 0x38
  arsh64 r4, 0x38
  mov64 r8, 0x1
  mov64 r9, 0x1
  jsle r4, -0x41, jmp_29790
  add64 r6, 0x1
  jeq r6, 0x0, jmp_29730
  ja jmp_297a8

jmp_29790:
  mov64 r9, 0x0
  add64 r6, 0x1
  jeq r6, 0x0, jmp_29730

jmp_297a8:
  mov64 r8, 0x0
  ja jmp_29730

jmp_297b8:
  ldxdw r8, [r10-0x10]
  and64 r2, 0xfc
  lsh64 r2, 0x3
  jlt r3, 0xc0, jmp_297e0
  mov64 r3, 0xc0

jmp_297e0:
  mov64 r6, r8
  add64 r6, r2
  mov64 r2, 0x0
  and64 r3, 0x3
  lsh64 r3, 0x3
  lddw r1, 0x101010101010101

jmp_29818:
  ldxdw r0, [r6+0x0]
  mov64 r5, r0
  rsh64 r5, 0x6
  xor64 r0, -0x1
  rsh64 r0, 0x7
  or64 r0, r5
  and64 r0, r1
  add64 r0, r2
  add64 r6, 0x8
  add64 r3, -0x8
  mov64 r2, r0
  jne r3, 0x0, jmp_29818
  lddw r1, 0xff00ff00ff00ff
  mov64 r2, r0
  and64 r2, r1
  rsh64 r0, 0x8
  and64 r0, r1
  add64 r0, r2
  lddw r1, 0x1000100010001
  mul64 r0, r1
  rsh64 r0, 0x30
  add64 r0, r4

jmp_298d8:
  exit

fn_298e0:
  mov64 r2, r1
  lddw r1, data_0ed8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_29938:
  mov64 r2, r1
  lddw r1, data_0ee8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_29990:
  mov64 r2, r1
  lddw r1, data_0ef8
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_299e8:
  mov64 r2, r1
  lddw r1, data_0f08
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_29a40:
  mov64 r2, r1
  lddw r1, data_0f18
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40

fn_29a98:
  mov64 r2, r1
  lddw r1, data_0f48
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  call fn_28b40
  mov64 r6, r2
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r3, r10
  add64 r3, -0x14
  mov64 r4, 0x14
  call fn_29b88
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x20]
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  mov64 r5, r10
  mov64 r1, r6
  mov64 r2, 0x1
  mov64 r3, 0x1
  mov64 r4, 0x0
  call fn_28c38
  exit

fn_29b88:
  stxdw [r10-0x8], r3
  mov64 r0, r2
  stxdw [r10-0x10], r4
  mov64 r5, r4
  jlt r2, 0x3e8, jmp_29cd8
  ldxdw r3, [r10-0x8]
  add64 r3, -0x2
  ldxdw r5, [r10-0x10]
  mov64 r0, r2

jmp_29bd0:
  mov64 r7, r0
  div64 r0, 0x2710
  mov64 r8, r0
  mul64 r8, 0x2710
  mov64 r9, r7
  sub64 r9, r8
  mov64 r6, r9
  and64 r6, 0xffff
  div64 r6, 0x64
  mov64 r8, r6
  mul64 r8, 0x64
  sub64 r9, r8
  lsh64 r9, 0x1
  and64 r9, 0xfffe
  lsh64 r6, 0x1
  lddw r8, str_0666
  add64 r8, r9
  lddw r9, str_0666
  add64 r9, r6
  mov64 r6, r3
  add64 r6, r5
  ldxb r4, [r9+0x1]
  stxb [r6-0x1], r4
  ldxb r4, [r9+0x0]
  stxb [r6-0x2], r4
  ldxb r4, [r8+0x1]
  stxb [r6+0x1], r4
  ldxb r4, [r8+0x0]
  stxb [r6+0x0], r4
  add64 r5, -0x4
  jgt r7, 0x98967f, jmp_29bd0

jmp_29cd8:
  jle r0, 0x9, jmp_29d98
  mov64 r6, r0
  and64 r6, 0xffff
  div64 r6, 0x64
  mov64 r3, r6
  mul64 r3, 0x64
  sub64 r0, r3
  lsh64 r0, 0x1
  and64 r0, 0xfffe
  lddw r3, str_0666
  add64 r3, r0
  ldxdw r7, [r10-0x8]
  mov64 r4, r7
  add64 r4, r5
  ldxb r0, [r3+0x1]
  stxb [r4-0x1], r0
  add64 r5, -0x2
  mov64 r4, r7
  add64 r4, r5
  ldxb r3, [r3+0x0]
  stxb [r4+0x0], r3
  jne r2, 0x0, jmp_29db0
  ja jmp_29db8

jmp_29d98:
  mov64 r6, r0
  ldxdw r7, [r10-0x8]
  jeq r2, 0x0, jmp_29db8

jmp_29db0:
  jeq r6, 0x0, jmp_29e08

jmp_29db8:
  lsh64 r6, 0x1
  and64 r6, 0x1e
  lddw r2, str_0666
  add64 r2, r6
  add64 r5, -0x1
  mov64 r3, r7
  add64 r3, r5
  ldxb r2, [r2+0x1]
  stxb [r3+0x0], r2

jmp_29e08:
  ldxdw r2, [r10-0x10]
  sub64 r2, r5
  stxdw [r1+0x8], r2
  add64 r7, r5
  stxdw [r1+0x0], r7
  exit

fn_29e38:
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  lddw r1, data_0f58
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x10], r1
  lddw r1, 0x4fbf
  stxdw [r10-0x8], r1
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x20], r1
  stdw [r10-0x30], 0x0
  stdw [r10-0x48], 0x2
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r3
  call fn_28b40

fn_29f00:
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  lddw r1, data_0f78
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x10], r1
  lddw r1, 0x4fbf
  stxdw [r10-0x8], r1
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x20], r1
  stdw [r10-0x30], 0x0
  stdw [r10-0x48], 0x2
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r3
  call fn_28b40

fn_29fc8:
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  lddw r1, data_0f98
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x10], r1
  lddw r1, 0x4fbf
  stxdw [r10-0x8], r1
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x20], r1
  stdw [r10-0x30], 0x0
  stdw [r10-0x48], 0x3
  stdw [r10-0x38], 0x2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r3
  call fn_28b40

fn_2a090:
  mov64 r6, r1
  call sol_memcpy_
  mov64 r0, r6
  exit

fn_2a0b0:
  mov64 r6, r1
  and64 r2, 0xff
  call sol_memset_
  mov64 r0, r6
  exit

fn_2a0d8:
  stxdw [r10-0xc0], r4
  mov64 r9, r2
  stxdw [r10-0xd0], r1
  mov64 r1, r5
  rsh64 r1, 0x1
  stxdw [r10-0xb8], r5
  mov64 r4, r5
  or64 r4, r1
  mov64 r1, r4
  rsh64 r1, 0x2
  or64 r4, r1
  mov64 r1, r4
  rsh64 r1, 0x4
  or64 r4, r1
  mov64 r1, r4
  rsh64 r1, 0x8
  or64 r4, r1
  mov64 r1, r4
  rsh64 r1, 0x10
  or64 r4, r1
  mov64 r1, r4
  rsh64 r1, 0x20
  or64 r4, r1
  lddw r1, 0x5555555555555555
  xor64 r4, -0x1
  mov64 r2, r4
  rsh64 r2, 0x1
  and64 r2, r1
  sub64 r4, r2
  lddw r2, 0x3333333333333333
  mov64 r7, r4
  and64 r7, r2
  rsh64 r4, 0x2
  and64 r4, r2
  add64 r7, r4
  mov64 r4, r7
  rsh64 r4, 0x4
  add64 r7, r4
  lddw r6, 0xf0f0f0f0f0f0f0f
  and64 r7, r6
  lddw r4, 0x101010101010101
  mul64 r7, r4
  jne r3, 0x0, jmp_2a390
  mov64 r0, r9
  rsh64 r0, 0x1
  mov64 r5, r9
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x2
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x4
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x8
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x10
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x20
  or64 r5, r0
  xor64 r5, -0x1
  mov64 r0, r5
  rsh64 r0, 0x1
  and64 r0, r1
  sub64 r5, r0
  mov64 r8, r5
  and64 r8, r2
  rsh64 r5, 0x2
  and64 r5, r2
  add64 r8, r5
  mov64 r5, r8
  rsh64 r5, 0x4
  add64 r8, r5
  and64 r8, r6
  mul64 r8, r4
  rsh64 r8, 0x38
  add64 r8, 0x40
  rsh64 r7, 0x38
  ldxdw r5, [r10-0xb8]
  jeq r5, 0x0, jmp_2a4c0
  ja jmp_2a5e0

jmp_2a390:
  mov64 r5, r3
  mov64 r0, r5
  rsh64 r0, 0x1
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x2
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x4
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x8
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x10
  or64 r5, r0
  mov64 r0, r5
  rsh64 r0, 0x20
  or64 r5, r0
  xor64 r5, -0x1
  mov64 r0, r5
  rsh64 r0, 0x1
  and64 r0, r1
  sub64 r5, r0
  mov64 r8, r5
  and64 r8, r2
  rsh64 r5, 0x2
  and64 r5, r2
  add64 r8, r5
  mov64 r5, r8
  rsh64 r5, 0x4
  add64 r8, r5
  and64 r8, r6
  mul64 r8, r4
  rsh64 r8, 0x38
  rsh64 r7, 0x38
  ldxdw r5, [r10-0xb8]
  jne r5, 0x0, jmp_2a5e0

jmp_2a4c0:
  ldxdw r7, [r10-0xc0]
  mov64 r5, r7
  rsh64 r5, 0x1
  or64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x2
  or64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x4
  or64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x8
  or64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x10
  or64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x20
  or64 r7, r5
  xor64 r7, -0x1
  mov64 r5, r7
  rsh64 r5, 0x1
  and64 r5, r1
  sub64 r7, r5
  mov64 r1, r7
  rsh64 r1, 0x2
  and64 r7, r2
  and64 r1, r2
  add64 r7, r1
  mov64 r1, r7
  rsh64 r1, 0x4
  add64 r7, r1
  and64 r7, r6
  mul64 r7, r4
  rsh64 r7, 0x38
  add64 r7, 0x40

jmp_2a5e0:
  mov64 r0, r3
  jle r7, r8, jmp_2a658
  mov64 r1, r8
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jle r1, 0x3f, jmp_2a770
  mov64 r6, r9
  ldxdw r2, [r10-0xc0]
  div64 r6, r2
  mov64 r1, r6
  mul64 r1, r2
  sub64 r9, r1
  mov64 r4, 0x0
  mov64 r8, r9
  ja jmp_2a888

jmp_2a658:
  mov64 r6, 0x0
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r3, [r10-0xc0]
  jlt r9, r3, jmp_2a718
  mov64 r1, 0x0
  ldxdw r7, [r10-0xd0]
  ldxdw r4, [r10-0xb8]
  jge r0, r4, jmp_2a730

jmp_2a6a0:
  ldxdw r4, [r10-0xb8]
  jeq r0, r4, jmp_2a748

jmp_2a6b0:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_2a758

jmp_2a6c8:
  ldxdw r1, [r10-0xb8]
  sub64 r0, r1
  mov64 r4, 0x0
  mov64 r6, 0x1
  mov64 r1, 0x1
  jlt r9, r3, jmp_2a700
  mov64 r1, 0x0

jmp_2a700:
  sub64 r0, r1
  sub64 r9, r3
  ja jmp_2a760

jmp_2a718:
  ldxdw r7, [r10-0xd0]
  ldxdw r4, [r10-0xb8]
  jlt r0, r4, jmp_2a6a0

jmp_2a730:
  mov64 r2, 0x0
  ldxdw r4, [r10-0xb8]
  jne r0, r4, jmp_2a6b0

jmp_2a748:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_2a6c8

jmp_2a758:
  mov64 r4, 0x0

jmp_2a760:
  mov64 r8, r9
  ja jmp_2a898

jmp_2a770:
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jle r1, 0x5f, jmp_2a8c0
  ldxdw r4, [r10-0xc0]
  mov64 r1, r4
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r2, r0
  div64 r2, r1
  mov64 r3, r2
  mul64 r3, r4
  sub64 r0, r3
  lsh64 r0, 0x20
  mov64 r8, r9
  rsh64 r8, 0x20
  or64 r0, r8
  div64 r0, r1
  mov64 r3, r0
  mul64 r3, r4
  sub64 r8, r3
  mov64 r4, r0
  rsh64 r4, 0x20
  or64 r4, r2
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  lsh64 r8, 0x20
  or64 r8, r9
  lsh64 r0, 0x20
  mov64 r2, r8
  div64 r2, r1
  or64 r0, r2
  mul64 r2, r1
  sub64 r8, r2
  mov64 r6, r0

jmp_2a888:
  mov64 r0, 0x0
  ldxdw r7, [r10-0xd0]

jmp_2a898:
  stxdw [r7+0x10], r8
  stxdw [r7+0x0], r6
  stxdw [r7+0x18], r0
  stxdw [r7+0x8], r4
  exit

jmp_2a8c0:
  stxdw [r10-0xd8], r0
  mov64 r1, r7
  sub64 r1, r8
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jge r1, 0x20, jmp_2ab60
  mov64 r6, 0x40
  sub64 r6, r8
  lsh64 r6, 0x20
  arsh64 r6, 0x20
  mov64 r1, r10
  add64 r1, -0x80
  ldxdw r8, [r10-0xc0]
  mov64 r2, r8
  ldxdw r7, [r10-0xb8]
  mov64 r3, r7
  mov64 r4, r6
  call fn_2c4a0
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r9
  ldxdw r3, [r10-0xd8]
  mov64 r4, r6
  call fn_2c4a0
  ldxdw r1, [r10-0x80]
  ldxdw r6, [r10-0x90]
  div64 r6, r1
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_2c150
  ldxdw r1, [r10-0xb0]
  ldxdw r3, [r10-0x98]
  mov64 r2, r3
  add64 r2, r1
  mov64 r1, 0x1
  jlt r2, r3, jmp_2aa40
  mov64 r1, 0x0

jmp_2aa40:
  ldxdw r3, [r10-0xa8]
  add64 r3, r1
  ldxdw r1, [r10-0xa0]
  ldxdw r7, [r10-0xd0]
  ldxdw r0, [r10-0xd8]
  jne r3, 0x0, jmp_2aab8
  mov64 r4, 0x1
  mov64 r3, 0x1
  jlt r9, r1, jmp_2b1b0
  mov64 r3, 0x0
  jge r0, r2, jmp_2b1b8

jmp_2aa98:
  jeq r0, r2, jmp_2b1c8

jmp_2aaa0:
  mov64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_2b1d8

jmp_2aab8:
  ldxdw r3, [r10-0xb8]
  add64 r3, r0
  stxdw [r10-0xb8], r3
  mov64 r5, r8
  add64 r5, r9
  mov64 r3, 0x1
  mov64 r4, 0x1
  mov64 r9, r5
  jlt r5, r8, jmp_2ab08
  mov64 r4, 0x0

jmp_2ab08:
  ldxdw r0, [r10-0xb8]
  add64 r0, r4
  sub64 r0, r2
  mov64 r8, r9
  jlt r8, r1, jmp_2ab38
  mov64 r3, 0x0

jmp_2ab38:
  sub64 r0, r3
  sub64 r8, r1
  add64 r6, -0x1
  mov64 r4, 0x0
  ja jmp_2a898

jmp_2ab60:
  mov64 r1, 0x60
  sub64 r1, r7
  stxdw [r10-0xf8], r1
  mov64 r4, r1
  lsh64 r4, 0x20
  stxdw [r10-0xf0], r4
  arsh64 r4, 0x20
  mov64 r1, r10
  add64 r1, -0x10
  ldxdw r2, [r10-0xc0]
  ldxdw r3, [r10-0xb8]
  call fn_2c4a0
  mov64 r5, 0x0
  ldxdw r1, [r10-0x10]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  add64 r1, 0x1
  stxdw [r10-0x100], r1
  mov64 r4, 0x0
  stxdw [r10-0xc8], r9
  ldxdw r0, [r10-0xd8]

jmp_2ac08:
  stxdw [r10-0xe8], r5
  stxdw [r10-0xe0], r4
  mov64 r6, 0x40
  sub64 r6, r8
  mov64 r9, r6
  lsh64 r9, 0x20
  mov64 r8, r9
  arsh64 r8, 0x20
  mov64 r1, r10
  add64 r1, -0x20
  ldxdw r2, [r10-0xc8]
  stxdw [r10-0xd8], r0
  mov64 r3, r0
  mov64 r4, r8
  call fn_2c4a0
  ldxdw r2, [r10-0x20]
  rsh64 r9, 0x20
  ldxdw r1, [r10-0xf0]
  rsh64 r1, 0x20
  jlt r9, r1, jmp_2b218
  ldxdw r1, [r10-0x100]
  div64 r2, r1
  ldxdw r1, [r10-0xf8]
  sub64 r6, r1
  lsh64 r6, 0x20
  arsh64 r6, 0x20
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r3, 0x0
  mov64 r8, r2
  mov64 r4, r6
  call fn_2c3f8
  mov64 r1, r10
  add64 r1, -0x40
  ldxdw r2, [r10-0xc0]
  ldxdw r3, [r10-0xb8]
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_2c150
  mov64 r1, r10
  add64 r1, -0x50
  ldxdw r2, [r10-0x40]
  ldxdw r3, [r10-0x38]
  mov64 r4, r6
  call fn_2c3f8
  ldxdw r4, [r10-0x30]
  mov64 r1, r4
  ldxdw r2, [r10-0xe8]
  add64 r1, r2
  mov64 r2, 0x1
  mov64 r3, 0x1
  jlt r1, r4, jmp_2adb0
  mov64 r3, 0x0

jmp_2adb0:
  ldxdw r4, [r10-0x50]
  ldxdw r0, [r10-0xd8]
  ldxdw r6, [r10-0xc8]
  jlt r6, r4, jmp_2add8
  mov64 r2, 0x0

jmp_2add8:
  ldxdw r5, [r10-0x48]
  sub64 r0, r5
  sub64 r0, r2
  ldxdw r2, [r10-0x28]
  sub64 r6, r4
  stxdw [r10-0xc8], r6
  jne r0, 0x0, jmp_2af78
  mov64 r5, r6
  rsh64 r5, 0x1
  mov64 r4, r6
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x2
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x4
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x8
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x10
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x20
  or64 r4, r5
  xor64 r4, -0x1
  mov64 r5, r4
  rsh64 r5, 0x1
  lddw r6, 0x5555555555555555
  and64 r5, r6
  sub64 r4, r5
  mov64 r8, r4
  lddw r5, 0x3333333333333333
  and64 r8, r5
  rsh64 r4, 0x2
  and64 r4, r5
  add64 r8, r4
  mov64 r4, r8
  rsh64 r4, 0x4
  add64 r8, r4
  lddw r4, 0xf0f0f0f0f0f0f0f
  and64 r8, r4
  lddw r4, 0x101010101010101
  mul64 r8, r4
  rsh64 r8, 0x38
  add64 r8, 0x40
  ja jmp_2b0d0

jmp_2af78:
  mov64 r5, r0
  rsh64 r5, 0x1
  mov64 r4, r0
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x2
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x4
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x8
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x10
  or64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x20
  or64 r4, r5
  xor64 r4, -0x1
  mov64 r5, r4
  rsh64 r5, 0x1
  lddw r6, 0x5555555555555555
  and64 r5, r6
  sub64 r4, r5
  mov64 r8, r4
  lddw r5, 0x3333333333333333
  and64 r8, r5
  rsh64 r4, 0x2
  and64 r4, r5
  add64 r8, r4
  mov64 r4, r8
  rsh64 r4, 0x4
  add64 r8, r4
  lddw r4, 0xf0f0f0f0f0f0f0f
  and64 r8, r4
  lddw r4, 0x101010101010101
  mul64 r8, r4
  rsh64 r8, 0x38

jmp_2b0d0:
  ldxdw r4, [r10-0xe0]
  add64 r2, r4
  add64 r2, r3
  mov64 r3, r7
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jle r3, r8, jmp_2b4a0
  mov64 r3, r8
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  mov64 r5, r1
  mov64 r4, r2
  jle r3, 0x3f, jmp_2ac08
  ldxdw r4, [r10-0xc0]
  jeq r4, 0x0, jmp_2b5d0
  ldxdw r8, [r10-0xc8]
  mov64 r3, r8
  div64 r3, r4
  ldxdw r7, [r10-0xd0]

jmp_2b168:
  mov64 r6, r1
  add64 r6, r3
  mov64 r0, 0x0
  mov64 r3, 0x1
  jlt r6, r1, jmp_2b198
  mov64 r3, 0x0

jmp_2b198:
  mod64 r8, r4
  add64 r2, r3
  ja jmp_2b5b8

jmp_2b1b0:
  jlt r0, r2, jmp_2aa98

jmp_2b1b8:
  mov64 r4, 0x0
  jne r0, r2, jmp_2aaa0

jmp_2b1c8:
  and64 r3, 0x1
  jne r3, 0x0, jmp_2aab8

jmp_2b1d8:
  sub64 r0, r2
  mov64 r4, 0x0
  mov64 r2, 0x1
  jlt r9, r1, jmp_2b200
  mov64 r2, 0x0

jmp_2b200:
  sub64 r0, r2
  sub64 r9, r1
  ja jmp_2a760

jmp_2b218:
  mov64 r6, r2
  mov64 r1, r10
  add64 r1, -0x60
  ldxdw r2, [r10-0xc0]
  ldxdw r3, [r10-0xb8]
  mov64 r4, r8
  call fn_2c4a0
  ldxdw r1, [r10-0x60]
  jeq r1, 0x0, jmp_2b5c8
  mov64 r4, r6
  div64 r4, r1

jmp_2b270:
  ldxdw r7, [r10-0xd0]
  ldxdw r8, [r10-0xc8]
  mov64 r1, r10
  add64 r1, -0x70
  ldxdw r6, [r10-0xc0]
  mov64 r2, r6
  ldxdw r3, [r10-0xb8]
  mov64 r9, r4
  mov64 r5, 0x0
  call fn_2c150
  mov64 r4, 0x1
  ldxdw r1, [r10-0x70]
  mov64 r3, 0x1
  jlt r8, r1, jmp_2b398
  mov64 r3, 0x0
  ldxdw r2, [r10-0x68]
  ldxdw r0, [r10-0xd8]
  jge r0, r2, jmp_2b3b0

jmp_2b300:
  jeq r0, r2, jmp_2b3c0

jmp_2b308:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_2b3d0

jmp_2b320:
  ldxdw r5, [r10-0xe8]
  mov64 r6, r5
  add64 r6, r9
  mov64 r4, 0x1
  mov64 r3, 0x1
  jlt r6, r5, jmp_2b358
  mov64 r3, 0x0

jmp_2b358:
  jlt r8, r1, jmp_2b368
  mov64 r4, 0x0

jmp_2b368:
  sub64 r0, r2
  sub64 r0, r4
  sub64 r8, r1
  ldxdw r4, [r10-0xe0]
  add64 r4, r3
  ja jmp_2a898

jmp_2b398:
  ldxdw r2, [r10-0x68]
  ldxdw r0, [r10-0xd8]
  jlt r0, r2, jmp_2b300

jmp_2b3b0:
  mov64 r4, 0x0
  jne r0, r2, jmp_2b308

jmp_2b3c0:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_2b320

jmp_2b3d0:
  ldxdw r3, [r10-0xb8]
  add64 r0, r3
  mov64 r3, r8
  add64 r3, r6
  mov64 r4, 0x1
  mov64 r5, 0x1
  jlt r3, r8, jmp_2b410
  mov64 r5, 0x0

jmp_2b410:
  add64 r0, r5
  ldxdw r6, [r10-0xe8]
  add64 r9, r6
  add64 r9, -0x1
  mov64 r5, 0x1
  mov64 r8, r9
  jlt r9, r6, jmp_2b450
  mov64 r5, 0x0

jmp_2b450:
  sub64 r0, r2
  jlt r3, r1, jmp_2b468
  mov64 r4, 0x0

jmp_2b468:
  sub64 r0, r4
  sub64 r3, r1
  ldxdw r4, [r10-0xe0]
  add64 r4, r5
  mov64 r6, r8
  mov64 r8, r3
  ja jmp_2a898

jmp_2b4a0:
  mov64 r4, 0x1
  mov64 r3, 0x1
  ldxdw r7, [r10-0xd0]
  ldxdw r5, [r10-0xc0]
  ldxdw r8, [r10-0xc8]
  jlt r8, r5, jmp_2b518
  mov64 r3, 0x0
  ldxdw r6, [r10-0xb8]
  jge r0, r6, jmp_2b528

jmp_2b4e8:
  ldxdw r6, [r10-0xb8]
  jeq r0, r6, jmp_2b540

jmp_2b4f8:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_2b5b0
  ja jmp_2b550

jmp_2b518:
  ldxdw r6, [r10-0xb8]
  jlt r0, r6, jmp_2b4e8

jmp_2b528:
  mov64 r4, 0x0
  ldxdw r6, [r10-0xb8]
  jne r0, r6, jmp_2b4f8

jmp_2b540:
  and64 r3, 0x1
  jne r3, 0x0, jmp_2b5b0

jmp_2b550:
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r8, r5, jmp_2b570
  mov64 r4, 0x0

jmp_2b570:
  ldxdw r6, [r10-0xb8]
  sub64 r0, r6
  add64 r1, 0x1
  jeq r1, 0x0, jmp_2b598
  mov64 r3, 0x0

jmp_2b598:
  sub64 r0, r4
  add64 r2, r3
  sub64 r8, r5

jmp_2b5b0:
  mov64 r6, r1

jmp_2b5b8:
  mov64 r4, r2
  ja jmp_2a898

jmp_2b5c8:
  ja jmp_2b270

jmp_2b5d0:
  ldxdw r7, [r10-0xd0]
  ldxdw r8, [r10-0xc8]
  ja jmp_2b168

fn_2b5e8:
  mov64 r3, 0x3
  lddw r0, 0x7fffffffffffffff
  mov64 r4, r1
  and64 r4, r0
  lddw r6, 0x7ff0000000000000
  jgt r4, r6, jmp_2b6b8
  mov64 r5, r2
  and64 r5, r0
  jgt r5, r6, jmp_2b6b8
  or64 r5, r4
  jeq r5, 0x0, jmp_2b680
  mov64 r3, r2
  and64 r3, r1
  jsle r3, -0x1, jmp_2b690
  mov64 r3, 0x0
  jsge r1, r2, jmp_2b6a0
  ja jmp_2b6b8

jmp_2b680:
  mov64 r3, 0x1
  ja jmp_2b6b8

jmp_2b690:
  mov64 r3, 0x0
  jsgt r1, r2, jmp_2b6b8

jmp_2b6a0:
  mov64 r3, 0x1
  jeq r1, r2, jmp_2b6b8
  mov64 r3, 0x2

jmp_2b6b8:
  lsh64 r3, 0x3
  lddw r1, data_0060
  add64 r1, r3
  ldxdw r0, [r1+0x0]
  exit

fn_2b6e8:
  mov64 r0, 0x0
  lddw r2, 0x3ff0000000000000
  jlt r1, r2, jmp_2b798
  lddw r2, 0x43f0000000000000
  jge r1, r2, jmp_2b778
  mov64 r0, r1
  lsh64 r0, 0xb
  lddw r2, -0x8000000000000000
  or64 r0, r2
  rsh64 r1, 0x34
  mov64 r2, 0x3e
  sub64 r2, r1
  and64 r2, 0x3f
  rsh64 r0, r2
  ja jmp_2b798

jmp_2b778:
  lddw r2, 0x7ff0000000000001
  jge r1, r2, jmp_2b798
  mov64 r0, -0x1

jmp_2b798:
  exit

fn_2b7a0:
  call fn_2b7b0
  exit

fn_2b7b0:
  mov64 r3, r2
  mov64 r0, r1
  mov64 r6, r3
  xor64 r6, r0
  lddw r1, -0x8000000000000000
  and64 r6, r1
  lddw r1, 0xfffffffffffff
  and64 r2, r1
  mov64 r4, r0
  and64 r4, r1
  mov64 r7, r3
  rsh64 r7, 0x34
  and64 r7, 0x7ff
  mov64 r8, r0
  rsh64 r8, 0x34
  and64 r8, 0x7ff
  mov64 r1, r8
  add64 r1, -0x7ff
  jlt r1, -0x7fe, jmp_2b9c8
  mov64 r1, r7
  add64 r1, -0x7ff
  jlt r1, -0x7fe, jmp_2b9c8
  stxdw [r10-0x18], r6
  mov64 r6, 0x0

jmp_2b880:
  lsh64 r2, 0xb
  lddw r1, -0x8000000000000000
  or64 r2, r1
  lddw r9, 0x10000000000000
  or64 r4, r9
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_2c150
  add64 r7, r8
  add64 r7, r6
  ldxdw r1, [r10-0x8]
  mov64 r3, r1
  and64 r3, r9
  ldxdw r2, [r10-0x10]
  jne r3, 0x0, jmp_2ba20
  lsh64 r1, 0x1
  mov64 r3, r2
  rsh64 r3, 0x3f
  or64 r1, r3
  lsh64 r2, 0x1
  add64 r7, -0x3ff
  ldxdw r6, [r10-0x18]
  jsgt r7, 0x7fe, jmp_2ba38

jmp_2b958:
  jslt r7, 0x1, jmp_2bab8
  lddw r3, 0xfffffffffffff
  and64 r1, r3
  lsh64 r7, 0x34
  or64 r7, r1
  mov64 r1, r7
  mov64 r0, r1
  or64 r0, r6
  lddw r3, -0x8000000000000000
  jle r2, r3, jmp_2bb68

jmp_2b9b8:
  add64 r0, 0x1
  ja jmp_2bba8

jmp_2b9c8:
  lddw r9, 0x7fffffffffffffff
  mov64 r5, r0
  and64 r5, r9
  lddw r1, 0x7ff0000000000000
  jle r5, r1, jmp_2ba60
  lddw r1, 0x8000000000000
  or64 r0, r1
  ja jmp_2bba8

jmp_2ba20:
  add64 r7, -0x3fe
  ldxdw r6, [r10-0x18]
  jsle r7, 0x7fe, jmp_2b958

jmp_2ba38:
  lddw r1, 0x7ff0000000000000

jmp_2ba48:
  or64 r6, r1

jmp_2ba50:
  mov64 r0, r6
  ja jmp_2bba8

jmp_2ba60:
  mov64 r0, r3
  and64 r0, r9
  jle r0, r1, jmp_2baa0
  lddw r1, 0x8000000000000
  or64 r3, r1
  mov64 r0, r3
  ja jmp_2bba8

jmp_2baa0:
  jne r5, r1, jmp_2bb88
  jne r0, 0x0, jmp_2ba48
  ja jmp_2bb98

jmp_2bab8:
  mov64 r4, 0x1
  mov64 r3, 0x1
  sub64 r3, r7
  jgt r3, 0x3f, jmp_2ba50
  add64 r7, 0x3f
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  mov64 r5, r2
  lsh64 r5, r7
  jne r5, 0x0, jmp_2bb10
  mov64 r4, 0x0

jmp_2bb10:
  rsh64 r2, r3
  mov64 r5, r1
  lsh64 r5, r7
  or64 r2, r5
  or64 r2, r4
  rsh64 r1, r3
  mov64 r0, r1
  or64 r0, r6
  lddw r3, -0x8000000000000000
  jgt r2, r3, jmp_2b9b8

jmp_2bb68:
  jne r2, r3, jmp_2bba8
  and64 r1, 0x1
  add64 r0, r1
  ja jmp_2bba8

jmp_2bb88:
  jne r0, r1, jmp_2bbb0
  jne r5, 0x0, jmp_2ba48

jmp_2bb98:
  lddw r0, 0x7ff8000000000000

jmp_2bba8:
  exit

jmp_2bbb0:
  jeq r5, 0x0, jmp_2ba50
  jeq r0, 0x0, jmp_2ba50
  mov64 r9, 0x0
  lddw r1, 0x10000000000000
  jge r5, r1, jmp_2bd78
  jeq r4, 0x0, jmp_2bd48
  mov64 r1, r4
  rsh64 r1, 0x1
  mov64 r3, r4
  or64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x2
  or64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x4
  or64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x8
  or64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x10
  or64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x20
  or64 r3, r1
  xor64 r3, -0x1
  lddw r1, 0x5555555555555555
  mov64 r5, r3
  rsh64 r5, 0x1
  and64 r5, r1
  sub64 r3, r5
  lddw r1, 0x3333333333333333
  mov64 r5, r3
  and64 r5, r1
  rsh64 r3, 0x2
  and64 r3, r1
  add64 r5, r3
  mov64 r1, r5
  rsh64 r1, 0x4
  add64 r5, r1
  lddw r1, 0xf0f0f0f0f0f0f0f
  and64 r5, r1
  lddw r1, 0x101010101010101
  mul64 r5, r1
  rsh64 r5, 0x38
  ja jmp_2bd50

jmp_2bd48:
  mov64 r5, 0x40

jmp_2bd50:
  mov64 r9, 0xc
  sub64 r9, r5
  add64 r5, 0x35
  and64 r5, 0x3f
  lsh64 r4, r5

jmp_2bd78:
  lddw r1, 0xfffffffffffff
  stxdw [r10-0x18], r6
  jgt r0, r1, jmp_2bf00
  jeq r2, 0x0, jmp_2bf10
  mov64 r3, r2
  rsh64 r3, 0x1
  mov64 r1, r2
  or64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x2
  or64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x4
  or64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x8
  or64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x10
  or64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x20
  or64 r1, r3
  xor64 r1, -0x1
  lddw r3, 0x5555555555555555
  mov64 r5, r1
  rsh64 r5, 0x1
  and64 r5, r3
  sub64 r1, r5
  lddw r5, 0x3333333333333333
  mov64 r3, r1
  and64 r3, r5
  rsh64 r1, 0x2
  and64 r1, r5
  add64 r3, r1
  mov64 r1, r3
  rsh64 r1, 0x4
  add64 r3, r1
  lddw r1, 0xf0f0f0f0f0f0f0f
  and64 r3, r1
  lddw r1, 0x101010101010101
  mul64 r3, r1
  rsh64 r3, 0x38
  ja jmp_2bf18

jmp_2bf00:
  mov64 r6, r9
  ja jmp_2b880

jmp_2bf10:
  mov64 r3, 0x40

jmp_2bf18:
  sub64 r9, r3
  add64 r3, 0x35
  and64 r3, 0x3f
  lsh64 r2, r3
  add64 r9, 0xc
  mov64 r6, r9
  ja jmp_2b880

fn_2bf50:
  jeq r1, 0x0, jmp_2c140
  mov64 r3, r1
  rsh64 r3, 0x1
  mov64 r2, r1
  or64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x2
  or64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x4
  or64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x8
  or64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x10
  or64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x20
  or64 r2, r3
  xor64 r2, -0x1
  lddw r3, 0x5555555555555555
  mov64 r4, r2
  rsh64 r4, 0x1
  and64 r4, r3
  sub64 r2, r4
  lddw r4, 0x3333333333333333
  mov64 r3, r2
  and64 r3, r4
  rsh64 r2, 0x2
  and64 r2, r4
  add64 r3, r2
  mov64 r2, r3
  rsh64 r2, 0x4
  add64 r3, r2
  lddw r2, 0xf0f0f0f0f0f0f0f
  and64 r3, r2
  lddw r2, 0x101010101010101
  mul64 r3, r2
  rsh64 r3, 0x38
  lsh64 r1, r3
  lsh64 r3, 0x34
  mov64 r2, r1
  rsh64 r2, 0xb
  mov64 r0, r2
  sub64 r0, r3
  xor64 r2, -0x1
  lsh64 r1, 0x35
  mov64 r3, r1
  rsh64 r3, 0x3f
  and64 r3, r2
  sub64 r1, r3
  rsh64 r1, 0x3f
  add64 r0, r1
  lddw r1, 0x43d0000000000000
  add64 r0, r1
  ja jmp_2c148

jmp_2c140:
  mov64 r0, 0x0

jmp_2c148:
  exit

fn_2c150:
  stxdw [r10-0x10], r3
  stxdw [r10-0x8], r1
  mov64 r1, r2
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r7, r4
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  mov64 r6, r2
  rsh64 r6, 0x20
  mov64 r3, r7
  mul64 r3, r1
  mul64 r7, r6
  mov64 r0, r4
  rsh64 r0, 0x20
  mov64 r9, r0
  mul64 r9, r1
  mov64 r1, r9
  add64 r1, r7
  mov64 r8, 0x1
  jlt r1, r9, jmp_2c200
  mov64 r8, 0x0

jmp_2c200:
  mov64 r9, r1
  lsh64 r9, 0x20
  mov64 r7, r3
  add64 r7, r9
  mov64 r9, 0x1
  jlt r7, r3, jmp_2c238
  mov64 r9, 0x0

jmp_2c238:
  ldxdw r3, [r10-0x8]
  stxdw [r3+0x0], r7
  rsh64 r1, 0x20
  lsh64 r8, 0x20
  or64 r8, r1
  ldxdw r1, [r10-0x10]
  mul64 r4, r1
  mul64 r5, r2
  add64 r5, r4
  mul64 r0, r6
  add64 r0, r5
  add64 r0, r8
  add64 r0, r9
  stxdw [r3+0x8], r0
  exit

fn_2c2b0:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_2a0d8
  ldxdw r1, [r10-0x20]
  ldxdw r2, [r10-0x18]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

fn_2c2f8:
  mov64 r3, 0x3
  lddw r0, 0x7fffffffffffffff
  mov64 r4, r1
  and64 r4, r0
  lddw r6, 0x7ff0000000000000
  jgt r4, r6, jmp_2c3c8
  mov64 r5, r2
  and64 r5, r0
  jgt r5, r6, jmp_2c3c8
  or64 r5, r4
  jeq r5, 0x0, jmp_2c390
  mov64 r3, r2
  and64 r3, r1
  jsle r3, -0x1, jmp_2c3a0
  mov64 r3, 0x0
  jsge r1, r2, jmp_2c3b0
  ja jmp_2c3c8

jmp_2c390:
  mov64 r3, 0x1
  ja jmp_2c3c8

jmp_2c3a0:
  mov64 r3, 0x0
  jsgt r1, r2, jmp_2c3c8

jmp_2c3b0:
  mov64 r3, 0x1
  jeq r1, r2, jmp_2c3c8
  mov64 r3, 0x2

jmp_2c3c8:
  lsh64 r3, 0x3
  lddw r1, data_0060
  add64 r1, r3
  ldxdw r0, [r1+0x0]
  exit

fn_2c3f8:
  mov64 r5, r4
  and64 r5, 0x40
  jne r5, 0x0, jmp_2c468
  jeq r4, 0x0, jmp_2c488
  mov64 r5, r4
  and64 r5, 0x3f
  lsh64 r3, r5
  neg64 r4
  and64 r4, 0x3f
  mov64 r0, r2
  rsh64 r0, r4
  or64 r3, r0
  lsh64 r2, r5
  ja jmp_2c488

jmp_2c468:
  and64 r4, 0x3f
  mov64 r3, r2
  lsh64 r3, r4
  mov64 r2, 0x0

jmp_2c488:
  stxdw [r1+0x0], r2
  stxdw [r1+0x8], r3
  exit

fn_2c4a0:
  mov64 r5, r4
  and64 r5, 0x40
  jne r5, 0x0, jmp_2c518
  jeq r4, 0x0, jmp_2c538
  mov64 r5, r4
  and64 r5, 0x3f
  rsh64 r2, r5
  neg64 r4
  and64 r4, 0x3f
  mov64 r0, r3
  lsh64 r0, r4
  or64 r0, r2
  rsh64 r3, r5
  mov64 r2, r0
  ja jmp_2c538

jmp_2c518:
  and64 r4, 0x3f
  rsh64 r3, r4
  mov64 r2, r3
  mov64 r3, 0x0

jmp_2c538:
  stxdw [r1+0x0], r2
  stxdw [r1+0x8], r3
  exit

.rodata
  data_0000: .byte 0x00, 0x01, 0x02, 0x07, 0x03, 0x0d, 0x08, 0x13, 0x04, 0x19, 0x0e, 0x1c, 0x09, 0x22, 0x14, 0x28, 0x05, 0x11, 0x1a, 0x26, 0x0f, 0x2e, 0x1d, 0x30, 0x0a, 0x1f, 0x23, 0x36, 0x15, 0x32, 0x29, 0x39, 0x3f, 0x06, 0x0c, 0x12, 0x18, 0x1b, 0x21, 0x27, 0x10, 0x25, 0x2d, 0x2f, 0x1e, 0x35, 0x31, 0x38, 0x3e, 0x0b, 0x17, 0x20, 0x24, 0x2c, 0x34, 0x37, 0x3d, 0x16, 0x2b, 0x33, 0x3c, 0x2a, 0x3b, 0x3a
  data_0040: .byte 0xeb, 0xf9, 0x75, 0x8c, 0x27, 0x8c, 0x5e, 0x8d, 0x4e, 0x28, 0x2c, 0x27, 0xa4, 0x0d, 0xb3, 0x07, 0xe3, 0x05, 0xa7, 0x63, 0xc3, 0xec, 0xc7, 0xa0, 0x3e, 0x68, 0x69, 0x3a, 0xd2, 0x5f, 0xea, 0x1b
  data_0060: .byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
  data_0080: .byte 0xf1, 0x4b, 0xf6, 0x5a, 0xd5, 0x6b, 0xd2, 0xba, 0x71, 0x5e, 0x45, 0x74, 0x2c, 0x23, 0x1f, 0x27, 0xd6, 0x36, 0x21, 0xcf, 0x5b, 0x77, 0x8f, 0x37, 0xc1, 0xa2, 0x48, 0x95, 0x1d, 0x17, 0x56, 0x02
  data_00a0: .byte 0x8c, 0x97, 0x25, 0x8f, 0x4e, 0x24, 0x89, 0xf1, 0xbb, 0x3d, 0x10, 0x29, 0x14, 0x8e, 0x0d, 0x83, 0x0b, 0x5a, 0x13, 0x99, 0xda, 0xff, 0x10, 0x84, 0x04, 0x8e, 0x7b, 0xd8, 0xdb, 0xe9, 0xf8, 0x59
  str_00c0: .ascii "index out of bounds: the len is "
  data_00e0: .byte 0x06, 0xdd, 0xf6, 0xe1, 0xd7, 0x65, 0xa1, 0x93, 0xd9, 0xcb, 0xe1, 0x46, 0xce, 0xeb, 0x79, 0xac, 0x1c, 0xb4, 0x85, 0xed, 0x5f, 0x5b, 0x37, 0x91, 0x3a, 0x8c, 0xf5, 0x85, 0x7e, 0xff, 0x00, 0xa9
  data_0100: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_0120: .byte 0x05, 0xbe, 0xb9, 0xd8, 0x8c, 0xb5, 0xc1, 0xa2, 0x1e, 0x48, 0xe9, 0x94, 0x3b, 0x25, 0x84, 0xd6, 0xe9, 0x30, 0x52, 0x66, 0x2a, 0x83, 0x99, 0x72, 0x3f, 0xcd, 0xac, 0x29, 0x36, 0xe1, 0x3b, 0x93
  data_0140: .byte 0x0c, 0xb7, 0xfa, 0xbb, 0x52, 0xf7, 0xa6, 0x48, 0xbb, 0x5b, 0x31, 0x7d, 0x9a, 0x01, 0x8b, 0x90, 0x57, 0xcb, 0x02, 0x47, 0x74, 0xfa, 0xfe, 0x01, 0xe6, 0xc4, 0xdf, 0x98, 0xcc, 0x38, 0x58, 0x81
  data_0160: .byte 0x0c, 0x26, 0x59, 0xb0, 0x54, 0xea, 0x06, 0xd1, 0x8e, 0x37, 0x13, 0x58, 0x2b, 0x58, 0x6c, 0x62, 0xcf, 0x86, 0xe3, 0x62, 0x24, 0xa0, 0xb3, 0xe9, 0xca, 0x39, 0xf5, 0x71, 0xfe, 0x85, 0xff, 0xf1
  data_0180: .byte 0x73, 0x72, 0x63, 0x2f, 0x65, 0x6e, 0x74, 0x72, 0x79, 0x70, 0x6f, 0x69, 0x6e, 0x74, 0x2f, 0x6d, 0x6f, 0x64, 0x2e, 0x72, 0x73, 0x00
  data_0196: .byte 0x73, 0x72, 0x63, 0x2f, 0x70, 0x75, 0x62, 0x6b, 0x65, 0x79, 0x2e, 0x72, 0x73, 0x00
  data_01a4: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x74, 0x61, 0x74, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_01b9: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x70, 0x72, 0x6f, 0x78, 0x79, 0x2f, 0x6d, 0x69, 0x67, 0x72, 0x61, 0x74, 0x65, 0x5f, 0x61, 0x73, 0x73, 0x65, 0x74, 0x2e, 0x72, 0x73, 0x00
  data_01dc: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x70, 0x72, 0x6f, 0x78, 0x79, 0x2f, 0x70, 0x6f, 0x73, 0x74, 0x5f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x5f, 0x70, 0x72, 0x69, 0x63, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_0203: .byte 0x2f, 0x55, 0x73, 0x65, 0x72, 0x73, 0x2f, 0x72, 0x75, 0x6e, 0x6e, 0x65, 0x72, 0x2f, 0x77, 0x6f, 0x72, 0x6b, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x6f, 0x75, 0x74, 0x2f, 0x72, 0x75, 0x73, 0x74, 0x2f, 0x6c, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x2f, 0x61, 0x6c, 0x6c, 0x6f, 0x63, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x6c, 0x69, 0x63, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_0258: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x70, 0x72, 0x6f, 0x78, 0x79, 0x2f, 0x75, 0x70, 0x64, 0x61, 0x74, 0x65, 0x5f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_027b: .byte 0x73, 0x72, 0x63, 0x2f, 0x73, 0x79, 0x73, 0x76, 0x61, 0x72, 0x73, 0x2f, 0x72, 0x65, 0x6e, 0x74, 0x2e, 0x72, 0x73, 0x00
  data_028f: .byte 0x2f, 0x55, 0x73, 0x65, 0x72, 0x73, 0x2f, 0x72, 0x75, 0x6e, 0x6e, 0x65, 0x72, 0x2f, 0x77, 0x6f, 0x72, 0x6b, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x6f, 0x75, 0x74, 0x2f, 0x72, 0x75, 0x73, 0x74, 0x2f, 0x6c, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x2f, 0x63, 0x6f, 0x72, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6e, 0x75, 0x6d, 0x2f, 0x6d, 0x6f, 0x64, 0x2e, 0x72, 0x73, 0x00
  data_02e5: .byte 0x73, 0x72, 0x63, 0x2f, 0x61, 0x63, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x5f, 0x69, 0x6e, 0x66, 0x6f, 0x2e, 0x72, 0x73, 0x00
  data_02f9: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x68, 0x65, 0x6c, 0x70, 0x65, 0x72, 0x73, 0x2e, 0x72, 0x73, 0x00
  data_0310: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x5f, 0x72, 0x65, 0x70, 0x6f, 0x72, 0x74, 0x2e, 0x72, 0x73, 0x00
  str_032d: .ascii "Unable to find a viable program address bump seed"
  str_035e: .ascii "Create Proxy"
  str_036a: .ascii "proxy"
  str_036f: .ascii "asset"
  data_0374: .byte 0x55, 0x70, 0x64, 0x61, 0x74, 0x65, 0x20, 0x46, 0x65, 0x65, 0x00, 0x00
  str_0380: .ascii "Accept Authority"
  str_0390: .ascii "range end index "
  str_03a0: .ascii "Update Authority"
  str_03b0: .ascii "Deactivate Asset"
  str_03c0: .ascii "Update Deposit Cap"
  str_03d2: .ascii "pyth"
  str_03d6: .ascii "Wrap"
  str_03da: .ascii "Swap"
  str_03de: .ascii "auth"
  str_03e2: .ascii "Unwrap"
  str_03e8: .ascii "Claim Fees"
  str_03f2: .ascii "Create Asset"
  str_03fe: .ascii "Freeze Fee"
  str_0408: .ascii "Freeze Token Account"
  str_041c: .ascii "Thaw Token Account"
  str_042e: .ascii "Update Oracle"
  str_043b: .ascii "Migrate Asset"
  str_0448: .ascii "Post Oracle Price"
  str_0459: .ascii "stream"
  str_045f: .ascii "Withdraw"
  data_0467: .byte 0xff
  str_0468: .ascii "Slippage exceeded"
  data_0479: .byte 0x2a, 0x2a, 0x20, 0x50, 0x41, 0x4e, 0x49, 0x43, 0x4b, 0x45, 0x44, 0x20, 0x2a, 0x2a, 0x00
  data_0488: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_04f0: .byte 0x58, 0x02, 0x00, 0x00, 0x58, 0x02, 0x00, 0x00, 0x58, 0x02, 0x00, 0x00, 0x00, 0xa3, 0x02, 0x00, 0x58, 0x02, 0x00, 0x00, 0x58, 0x02, 0x00, 0x00
  str_0508: .ascii "
"
  data_0509: .byte 0x0b, 0x00, 0x00
  data_050c: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  str_0574: .ascii "Error: memory allocation failed, out of memory"
  str_05a2: .ascii "capacity overflow"
  str_05b3: .ascii "attempt to add with overflow"
  str_05cf: .ascii "attempt to subtract with overflow"
  str_05f0: .ascii "attempt to multiply with overflow"
  str_0611: .ascii "attempt to negate with overflow"
  str_0630: .ascii "attempt to shift left with overflow"
  str_0653: .ascii ")"
  str_0654: .ascii " but the index is "
  str_0666: .ascii "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"
  str_072e: .ascii "attempt to divide by zero"
  str_0747: .ascii " out of range for slice of length "
  str_0769: .ascii "slice index starts at "
  str_077f: .ascii " but ends at "
  str_078c: .ascii "copy_from_slice: source slice length ("
  data_07b2: .byte 0x29, 0x20, 0x64, 0x6f, 0x65, 0x73, 0x20, 0x6e, 0x6f, 0x74, 0x20, 0x6d, 0x61, 0x74, 0x63, 0x68, 0x20, 0x64, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x73, 0x6c, 0x69, 0x63, 0x65, 0x20, 0x6c, 0x65, 0x6e, 0x67, 0x74, 0x68, 0x20, 0x28, 0x00, 0x00, 0x00
  data_07e0: .quad data_028f
  data_07e8: .byte 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x04, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00
  data_07f8: .quad data_028f
  data_0800: .byte 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x96, 0x04, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00
  data_0810: .quad data_02e5
  data_0818: .byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0x02, 0x00, 0x00, 0x2a, 0x00, 0x00, 0x00
  data_0828: .quad data_02e5
  data_0830: .byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0x02, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00
  data_0840: .quad data_0203
  data_0848: .byte 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x01, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0858: .quad data_0180
  data_0860: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe4, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00
  data_0870: .quad data_0180
  data_0878: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe7, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00
  data_0888: .quad data_0180
  data_0890: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd8, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_08a0: .quad data_0180
  data_08a8: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd2, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_08b8: .quad data_0180
  data_08c0: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd3, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_08d0: .quad data_0180
  data_08d8: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd4, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_08e8: .quad data_0180
  data_08f0: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd5, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0900: .quad data_0180
  data_0908: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd6, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0918: .quad data_0180
  data_0920: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbf, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0930: .quad data_0180
  data_0938: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb7, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0948: .quad data_0180
  data_0950: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb8, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0960: .quad data_0180
  data_0968: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb9, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0978: .quad data_0180
  data_0980: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xba, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0990: .quad data_0180
  data_0998: .byte 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbb, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_09a8: .quad str_032d
  data_09b0: .quad 0x0000000000000031
  data_09b8: .quad data_0196
  data_09c0: .byte 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x68, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_09d0: .quad data_027b
  data_09d8: .byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb2, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00
  data_09e8: .quad data_027b
  data_09f0: .byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaf, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0a00: .quad data_0258
  data_0a08: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa6, 0x00, 0x00, 0x00, 0x34, 0x00, 0x00, 0x00
  data_0a18: .quad data_0258
  data_0a20: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa7, 0x00, 0x00, 0x00, 0x34, 0x00, 0x00, 0x00
  data_0a30: .quad data_0258
  data_0a38: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0x00, 0x00, 0x00, 0x38, 0x00, 0x00, 0x00
  data_0a48: .quad data_0258
  data_0a50: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xca, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x00
  data_0a60: .quad data_0258
  data_0a68: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcf, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_0a78: .quad data_0258
  data_0a80: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd8, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00
  data_0a90: .quad data_0258
  data_0a98: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe9, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_0aa8: .quad data_0258
  data_0ab0: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf7, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0ac0: .quad data_0258
  data_0ac8: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00
  data_0ad8: .quad data_0258
  data_0ae0: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4a, 0x01, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
  data_0af0: .quad data_0258
  data_0af8: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xce, 0x01, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00
  data_0b08: .quad data_01b9
  data_0b10: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5c, 0x00, 0x00, 0x00, 0x32, 0x00, 0x00, 0x00
  data_0b20: .quad data_01b9
  data_0b28: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00
  data_0b38: .quad data_01b9
  data_0b40: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0x2f, 0x00, 0x00, 0x00
  data_0b50: .quad data_01b9
  data_0b58: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8c, 0x00, 0x00, 0x00, 0x26, 0x00, 0x00, 0x00
  data_0b68: .quad data_01b9
  data_0b70: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8f, 0x00, 0x00, 0x00, 0x1a, 0x00, 0x00, 0x00
  data_0b80: .quad data_01b9
  data_0b88: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00
  data_0b98: .quad data_01b9
  data_0ba0: .byte 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x95, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0bb0: .quad data_01dc
  data_0bb8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0bc8: .quad data_01dc
  data_0bd0: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x01, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x00
  data_0be0: .quad data_01dc
  data_0be8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x02, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0bf8: .quad data_01dc
  data_0c00: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x02, 0x00, 0x00, 0x2e, 0x00, 0x00, 0x00
  data_0c10: .quad data_01dc
  data_0c18: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x03, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_0c28: .quad data_01dc
  data_0c30: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0x03, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_0c40: .quad data_01dc
  data_0c48: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x26, 0x03, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0c58: .quad data_01dc
  data_0c60: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2a, 0x03, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_0c70: .quad data_01dc
  data_0c78: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2e, 0x03, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00
  data_0c88: .quad data_02f9
  data_0c90: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0x01, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x00
  data_0ca0: .quad data_02f9
  data_0ca8: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6a, 0x02, 0x00, 0x00, 0x27, 0x00, 0x00, 0x00
  data_0cb8: .quad data_02f9
  data_0cc0: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6b, 0x02, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00
  data_0cd0: .quad data_02f9
  data_0cd8: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6c, 0x02, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0ce8: .quad data_02f9
  data_0cf0: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xad, 0x03, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0d00: .quad data_02f9
  data_0d08: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb4, 0x03, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0d18: .quad data_02f9
  data_0d20: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb8, 0x03, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00
  data_0d30: .quad data_02f9
  data_0d38: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb9, 0x03, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00
  data_0d48: .quad data_02f9
  data_0d50: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbb, 0x03, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0d60: .quad data_02f9
  data_0d68: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x03, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0d78: .quad data_02f9
  data_0d80: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc5, 0x03, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
  data_0d90: .quad data_02f9
  data_0d98: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x04, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0da8: .quad data_02f9
  data_0db0: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0dc0: .quad data_02f9
  data_0dc8: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a, 0x04, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00
  data_0dd8: .quad data_02f9
  data_0de0: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0b, 0x04, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00
  data_0df0: .quad data_02f9
  data_0df8: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0d, 0x04, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0e08: .quad data_02f9
  data_0e10: .byte 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x04, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
  data_0e20: .quad data_01a4
  data_0e28: .byte 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x2d, 0x00, 0x00, 0x00
  data_0e38: .quad data_01a4
  data_0e40: .byte 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x62, 0x01, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0e50: .quad data_01a4
  data_0e58: .byte 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0x01, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00
  data_0e68: .quad data_01a4
  data_0e70: .byte 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0b, 0x02, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x00
  data_0e80: .quad data_0310
  data_0e88: .byte 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0e98: .quad data_0310
  data_0ea0: .byte 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3d, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0eb0: .quad data_0310
  data_0eb8: .byte 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45, 0x01, 0x00, 0x00, 0x38, 0x00, 0x00, 0x00
  data_0ec8: .quad str_05a2
  data_0ed0: .quad 0x0000000000000011
  data_0ed8: .quad str_05b3
  data_0ee0: .quad 0x000000000000001c
  data_0ee8: .quad str_05cf
  data_0ef0: .quad 0x0000000000000021
  data_0ef8: .quad str_05f0
  data_0f00: .quad 0x0000000000000021
  data_0f08: .quad str_0611
  data_0f10: .quad 0x000000000000001f
  data_0f18: .quad str_0630
  data_0f20: .quad 0x0000000000000023
  data_0f28: .quad str_00c0
  data_0f30: .quad 0x0000000000000020
  data_0f38: .quad str_0654
  data_0f40: .quad 0x0000000000000012
  data_0f48: .quad str_072e
  data_0f50: .quad 0x0000000000000019
  data_0f58: .quad str_0390
  data_0f60: .quad 0x0000000000000010
  data_0f68: .quad str_0747
  data_0f70: .quad 0x0000000000000022
  data_0f78: .quad str_0769
  data_0f80: .quad 0x0000000000000016
  data_0f88: .quad str_077f
  data_0f90: .quad 0x000000000000000d
  data_0f98: .quad str_078c
  data_0fa0: .quad 0x0000000000000026
  data_0fa8: .quad data_07b2
  data_0fb0: .quad 0x000000000000002b
  data_0fb8: .quad str_0653
  data_0fc0: .quad 0x0000000000000001
