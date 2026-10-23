.globl entrypoint

fn_0000:
  mov64 r6, r2
  ldxdw r0, [r6+0x0]
  ldxdw r8, [r6+0x20]
  jeq r8, 0x0, jmp_00e0
  ldxdw r3, [r6+0x28]
  sub64 r3, r8
  jeq r0, 0x0, jmp_0118
  ldxdw r4, [r6+0x8]
  ldxdw r2, [r6+0x18]
  sub64 r2, r4
  add64 r2, r3
  mov64 r4, 0x1
  jlt r2, r3, jmp_0070
  mov64 r4, 0x0

jmp_0070:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_0100

jmp_0080:
  lddw r1, data_5d90
  stxdw [r10-0x30], r1
  stdw [r10-0x10], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x8
  mov64 r1, r10
  add64 r1, -0x30
  lddw r2, data_6068
  call fn_cc598

jmp_00e0:
  jeq r0, 0x0, jmp_0220
  ldxdw r3, [r6+0x8]
  ldxdw r2, [r6+0x18]
  sub64 r2, r3

jmp_0100:
  mov64 r3, 0x0
  jslt r2, 0x0, jmp_0130
  ja jmp_0150

jmp_0118:
  mov64 r2, r3
  mov64 r3, 0x0
  jsge r2, 0x0, jmp_0150

jmp_0130:
  mov64 r1, r3
  lddw r3, data_6068
  call fn_cb038

jmp_0150:
  jeq r2, 0x0, jmp_0220
  stxdw [r10-0x50], r0
  mov64 r9, r2
  mov64 r7, r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  lddw r1, 0x300008000
  jeq r2, 0x0, jmp_01b0
  mov64 r1, r2

jmp_01b0:
  mov64 r5, r1
  mov64 r2, r9
  sub64 r5, r2
  mov64 r4, 0x0
  mov64 r3, 0x1
  mov64 r0, 0x1
  jle r5, r1, jmp_0238
  mov64 r1, r7
  jeq r0, 0x0, jmp_0250

jmp_01f8:
  lddw r5, 0x300000008
  ldxdw r0, [r10-0x50]
  jge r4, r5, jmp_0278
  ja jmp_0130

jmp_0220:
  mov64 r4, 0x1
  mov64 r2, 0x0
  ja jmp_0290

jmp_0238:
  mov64 r0, 0x0
  mov64 r1, r7
  jne r0, 0x0, jmp_01f8

jmp_0250:
  mov64 r4, r5
  lddw r5, 0x300000008
  ldxdw r0, [r10-0x50]
  jlt r4, r5, jmp_0130

jmp_0278:
  lddw r3, 0x300000000
  stxdw [r3+0x0], r4

jmp_0290:
  stxdw [r10-0x40], r4
  stxdw [r10-0x48], r2
  stdw [r10-0x38], 0x0
  ldxdw r7, [r6+0x28]
  ldxdw r9, [r6+0x18]
  ldxdw r6, [r6+0x8]
  jeq r8, 0x0, jmp_0338
  mov64 r5, r7
  sub64 r5, r8
  stxdw [r10-0x50], r0
  jeq r0, 0x0, jmp_0360
  mov64 r0, r9
  sub64 r0, r6
  mov64 r3, r5
  add64 r3, r0
  mov64 r0, 0x1
  jlt r3, r5, jmp_0320
  mov64 r0, 0x0

jmp_0320:
  and64 r0, 0x1
  jeq r0, 0x0, jmp_0368
  ja jmp_0080

jmp_0338:
  jeq r0, 0x0, jmp_0428
  stxdw [r10-0x50], r0
  mov64 r3, r9
  sub64 r3, r6
  ja jmp_0368

jmp_0360:
  mov64 r3, r5

jmp_0368:
  jgt r3, r2, jmp_0468
  mov64 r2, 0x0
  ldxdw r0, [r10-0x50]
  jeq r8, 0x0, jmp_03d8

jmp_0388:
  jeq r8, r7, jmp_03d8
  sub64 r7, r8

jmp_0398:
  mov64 r3, r4
  add64 r3, r2
  ldxb r5, [r8+0x0]
  stxb [r3+0x0], r5
  add64 r8, 0x1
  add64 r2, 0x1
  add64 r7, -0x1
  jne r7, 0x0, jmp_0398

jmp_03d8:
  jeq r0, 0x0, jmp_0430
  jeq r6, r9, jmp_0430

jmp_03e8:
  mov64 r3, r4
  add64 r3, r2
  ldxb r5, [r6+0x0]
  stxb [r3+0x0], r5
  add64 r2, 0x1
  add64 r6, 0x1
  jne r6, r9, jmp_03e8
  ja jmp_0430

jmp_0428:
  mov64 r2, 0x0

jmp_0430:
  stxdw [r10-0x38], r2
  stxdw [r1+0x10], r2
  ldxdw r2, [r10-0x40]
  stxdw [r1+0x8], r2
  ldxdw r2, [r10-0x48]
  stxdw [r1+0x0], r2
  exit

jmp_0468:
  mov64 r2, r10
  add64 r2, -0x48
  stxdw [r10-0x58], r1
  mov64 r1, r2
  mov64 r2, 0x0
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  ldxdw r1, [r10-0x58]
  ldxdw r4, [r10-0x40]
  ldxdw r2, [r10-0x38]
  ldxdw r0, [r10-0x50]
  jne r8, 0x0, jmp_0388
  ja jmp_03d8

fn_04d8:
  mov64 r6, r3
  mov64 r8, r2
  mov64 r7, r1
  jeq r6, r8, jmp_0630
  sub64 r6, r8
  div64 r6, 0x4c
  mov64 r9, r6
  lsh64 r9, 0x5
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0558
  mov64 r3, r1

jmp_0558:
  mov64 r2, r3
  sub64 r2, r9
  mov64 r1, 0x0
  mov64 r4, 0x1
  jle r2, r3, jmp_0660
  jeq r4, 0x0, jmp_0670

jmp_0588:
  lddw r2, 0x300000007
  jle r1, r2, jmp_0690

jmp_05a0:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  mov64 r2, r1
  mov64 r3, r6

jmp_05c8:
  ldxdw r4, [r8+0x18]
  stxdw [r2+0x18], r4
  ldxdw r4, [r8+0x10]
  stxdw [r2+0x10], r4
  ldxdw r4, [r8+0x8]
  stxdw [r2+0x8], r4
  ldxdw r4, [r8+0x0]
  stxdw [r2+0x0], r4
  add64 r2, 0x20
  add64 r8, 0x4c
  add64 r3, -0x1
  jne r3, 0x0, jmp_05c8
  ja jmp_0640

jmp_0630:
  mov64 r6, 0x0
  mov64 r1, 0x1

jmp_0640:
  stxdw [r7+0x8], r1
  stxdw [r7+0x10], r6
  stxdw [r7+0x0], r6
  exit

jmp_0660:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0588

jmp_0670:
  mov64 r1, r2
  lddw r2, 0x300000007
  jgt r1, r2, jmp_05a0

jmp_0690:
  mov64 r1, 0x1
  mov64 r2, r9
  lddw r3, data_6068
  call fn_cb038

fn_06b8:
  mov64 r6, r3
  mov64 r8, r2
  mov64 r7, r1
  jeq r6, r8, jmp_07e8
  sub64 r6, r8
  div64 r6, 0x12c
  mov64 r9, r6
  lsh64 r9, 0x3
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0738
  mov64 r3, r1

jmp_0738:
  mov64 r2, r3
  sub64 r2, r9
  mov64 r1, 0x0
  mov64 r4, 0x1
  jle r2, r3, jmp_0818
  jeq r4, 0x0, jmp_0828

jmp_0768:
  lddw r2, 0x300000007
  jle r1, r2, jmp_0848

jmp_0780:
  and64 r1, -0x8
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  add64 r8, 0x20
  mov64 r2, r1
  mov64 r3, r6

jmp_07b8:
  stxdw [r2+0x0], r8
  add64 r2, 0x8
  add64 r8, 0x12c
  add64 r3, -0x1
  jne r3, 0x0, jmp_07b8
  ja jmp_07f8

jmp_07e8:
  mov64 r6, 0x0
  mov64 r1, 0x8

jmp_07f8:
  stxdw [r7+0x8], r1
  stxdw [r7+0x10], r6
  stxdw [r7+0x0], r6
  exit

jmp_0818:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0768

jmp_0828:
  mov64 r1, r2
  lddw r2, 0x300000007
  jgt r1, r2, jmp_0780

jmp_0848:
  mov64 r1, 0x8
  mov64 r2, r9
  lddw r3, data_6068
  call fn_cb038

fn_0870:
  mov64 r8, r5
  mov64 r7, r3
  mov64 r6, r2
  stxdw [r10-0x60], r1
  mov64 r1, r6
  and64 r1, 0x1
  jeq r1, 0x0, jmp_09a8
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r3, r10
  add64 r3, -0x14
  mov64 r2, r4
  mov64 r4, 0x14
  call fn_d1a20
  mov64 r1, 0x0
  ldxdw r9, [r10-0x40]
  jslt r9, 0x0, jmp_09f8
  ldxdw r2, [r10-0x48]
  jeq r9, 0x0, jmp_0ac8
  stxdw [r10-0x68], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0950
  mov64 r3, r1

jmp_0950:
  mov64 r2, r3
  sub64 r2, r9
  mov64 r5, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_0ae8
  jeq r4, 0x0, jmp_0af8

jmp_0988:
  lddw r2, 0x300000008
  jge r5, r2, jmp_0b18
  ja jmp_09f8

jmp_09a8:
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r3, r10
  add64 r3, -0x14
  mov64 r2, r4
  mov64 r4, 0x14
  call fn_d1a20
  mov64 r1, 0x0
  ldxdw r9, [r10-0x20]
  jsge r9, 0x0, jmp_0a18

jmp_09f8:
  mov64 r2, r9
  lddw r3, data_5ff0
  call fn_cb038

jmp_0a18:
  ldxdw r2, [r10-0x28]
  jeq r9, 0x0, jmp_0ad8
  stxdw [r10-0x68], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0a70
  mov64 r3, r1

jmp_0a70:
  mov64 r2, r3
  sub64 r2, r9
  mov64 r5, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_0c58
  jeq r4, 0x0, jmp_0c68

jmp_0aa8:
  lddw r2, 0x300000008
  jge r5, r2, jmp_0c88
  ja jmp_09f8

jmp_0ac8:
  mov64 r5, 0x1
  ja jmp_0b38

jmp_0ad8:
  mov64 r5, 0x1
  ja jmp_0ca8

jmp_0ae8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0988

jmp_0af8:
  mov64 r5, r2
  lddw r2, 0x300000008
  jlt r5, r2, jmp_09f8

jmp_0b18:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r5
  ldxdw r2, [r10-0x68]

jmp_0b38:
  stxdw [r10-0x68], r5
  mov64 r1, r5
  mov64 r3, r9
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r3, r10
  add64 r3, -0x14
  mov64 r2, r8
  mov64 r4, 0x14
  call fn_d1a20
  mov64 r1, 0x0
  ldxdw r8, [r10-0x50]
  jslt r8, 0x0, jmp_0d18
  ldxdw r2, [r10-0x58]
  jeq r8, 0x0, jmp_0de8
  stxdw [r10-0x70], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0c00
  mov64 r3, r1

jmp_0c00:
  mov64 r2, r3
  sub64 r2, r8
  mov64 r5, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_0e08
  jeq r4, 0x0, jmp_0e18

jmp_0c38:
  lddw r2, 0x300000008
  jge r5, r2, jmp_0e38
  ja jmp_0d18

jmp_0c58:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0aa8

jmp_0c68:
  mov64 r5, r2
  lddw r2, 0x300000008
  jlt r5, r2, jmp_09f8

jmp_0c88:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r5
  ldxdw r2, [r10-0x68]

jmp_0ca8:
  stxdw [r10-0x68], r5
  mov64 r1, r5
  mov64 r3, r9
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r3, r10
  add64 r3, -0x14
  mov64 r2, r8
  mov64 r4, 0x14
  call fn_d1a20
  mov64 r1, 0x0
  ldxdw r8, [r10-0x30]
  jsge r8, 0x0, jmp_0d38

jmp_0d18:
  mov64 r2, r8
  lddw r3, data_5ff0
  call fn_cb038

jmp_0d38:
  ldxdw r2, [r10-0x38]
  jeq r8, 0x0, jmp_0df8
  stxdw [r10-0x70], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_0d90
  mov64 r3, r1

jmp_0d90:
  mov64 r2, r3
  sub64 r2, r8
  mov64 r5, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_0ec8
  jeq r4, 0x0, jmp_0ed8

jmp_0dc8:
  lddw r2, 0x300000008
  jge r5, r2, jmp_0ef8
  ja jmp_0d18

jmp_0de8:
  mov64 r5, 0x1
  ja jmp_0e58

jmp_0df8:
  mov64 r5, 0x1
  ja jmp_0f18

jmp_0e08:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0c38

jmp_0e18:
  mov64 r5, r2
  lddw r2, 0x300000008
  jlt r5, r2, jmp_0d18

jmp_0e38:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r5
  ldxdw r2, [r10-0x70]

jmp_0e58:
  stxdw [r10-0x70], r5
  mov64 r1, r5
  mov64 r3, r8
  call fn_d23d0
  ldxb r1, [r7+0x38]
  stb [r7+0x38], 0x0
  mov64 r1, 0x68
  stxdw [r10-0x78], r1
  mov64 r2, 0x60
  mov64 r3, 0x58
  mov64 r4, 0x50
  mov64 r5, 0x48
  mov64 r0, 0x40
  ja jmp_0f80

jmp_0ec8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_0dc8

jmp_0ed8:
  mov64 r5, r2
  lddw r2, 0x300000008
  jlt r5, r2, jmp_0d18

jmp_0ef8:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r5
  ldxdw r2, [r10-0x70]

jmp_0f18:
  stxdw [r10-0x70], r5
  mov64 r1, r5
  mov64 r3, r8
  call fn_d23d0
  ldxb r1, [r7+0x50]
  stb [r7+0x50], 0x0
  mov64 r1, 0x80
  stxdw [r10-0x78], r1
  mov64 r2, 0x78
  mov64 r3, 0x70
  mov64 r4, 0x68
  mov64 r5, 0x60
  mov64 r0, 0x58

jmp_0f80:
  mov64 r1, r7
  add64 r7, r0
  stxdw [r7+0x0], r9
  mov64 r0, r1
  add64 r0, r5
  ldxdw r5, [r10-0x68]
  stxdw [r0+0x0], r5
  mov64 r5, r1
  add64 r5, r4
  stxdw [r5+0x0], r9
  mov64 r4, r1
  add64 r4, r3
  stxdw [r4+0x0], r8
  mov64 r3, r1
  add64 r3, r2
  ldxdw r2, [r10-0x70]
  stxdw [r3+0x0], r2
  mov64 r2, r1
  ldxdw r3, [r10-0x78]
  add64 r2, r3
  stxdw [r2+0x0], r8
  ldxdw r2, [r10-0x60]
  stxdw [r2+0x8], r1
  stxdw [r2+0x0], r6
  exit

fn_1048:
  mov64 r6, r5
  stxdw [r10-0x10], r4
  mov64 r8, r3
  stxdw [r10-0x8], r2
  mov64 r9, r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_10b0
  mov64 r2, r1

jmp_10b0:
  mov64 r1, r2
  sub64 r1, r6
  mov64 r7, 0x0
  mov64 r3, 0x1
  jle r1, r2, jmp_1188
  jeq r3, 0x0, jmp_1198

jmp_10e0:
  ldxdw r1, [r10-0x8]
  and64 r1, 0x1
  lddw r1, 0x300000007
  jle r7, r1, jmp_11c8

jmp_1108:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r1, r7
  ldxdw r2, [r10-0x10]
  mov64 r3, r6
  call fn_d23d0
  ldxdw r1, [r8+0x0]
  stxdw [r8+0x10], r7
  stxdw [r8+0x18], r6
  stxdw [r8+0x8], r6
  stdw [r8+0x0], 0x1
  stxdw [r9+0x8], r8
  ldxdw r1, [r10-0x8]
  stxdw [r9+0x0], r1
  exit

jmp_1188:
  mov64 r3, 0x0
  jne r3, 0x0, jmp_10e0

jmp_1198:
  mov64 r7, r1
  ldxdw r1, [r10-0x8]
  and64 r1, 0x1
  lddw r1, 0x300000007
  jgt r7, r1, jmp_1108

jmp_11c8:
  mov64 r1, 0x1
  mov64 r2, r6
  lddw r3, data_5ff0
  call fn_cb038

fn_11f0:
  mov64 r6, r1
  ldxdw r1, [r2+0x8]
  jeq r1, 0x0, jmp_1328
  add64 r1, -0x1
  stxdw [r2+0x8], r1
  ldxdw r3, [r2+0x0]
  mov64 r1, r3
  add64 r1, 0x30
  stxdw [r2+0x0], r1
  ldxdw r1, [r3+0x8]
  ldxdw r4, [r1+0x0]
  add64 r4, 0x1
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_1268
  mov64 r5, 0x0

jmp_1268:
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x0], r4
  jeq r5, 0x1, jmp_1380
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r4+0x0]
  add64 r5, 0x1
  mov64 r0, 0x1
  jeq r5, 0x0, jmp_12b0
  mov64 r0, 0x0

jmp_12b0:
  stxdw [r4+0x0], r5
  jeq r0, 0x1, jmp_1380
  ldxb r5, [r3+0x2a]
  ldxdw r0, [r3+0x18]
  ldxdw r7, [r3+0x20]
  ldxb r8, [r3+0x28]
  ldxb r3, [r3+0x29]
  stxb [r6+0x29], r3
  stxb [r6+0x28], r8
  stxdw [r6+0x20], r7
  stxdw [r6+0x18], r0
  stxdw [r6+0x10], r4
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r2
  ja jmp_1370

jmp_1328:
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  mov64 r5, 0x2

jmp_1370:
  stxb [r6+0x2a], r5
  exit

jmp_1380:
  call abort

fn_1388:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r5, r10
  call fn_fa50
  ldxw r1, [r10-0x28]
  jne r1, 0x2, jmp_13e8
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_14b8

jmp_13e8:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0xb8
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_14c0
  jeq r4, 0x0, jmp_14d0

jmp_1438:
  lddw r7, 0x300007f48
  jne r1, 0x0, jmp_14f0

jmp_1450:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1518

jmp_1468:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r1, r7
  mov64 r3, 0xb8
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_14b8:
  exit

jmp_14c0:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1438

jmp_14d0:
  mov64 r2, r3
  lddw r7, 0x300007f48
  jeq r1, 0x0, jmp_1450

jmp_14f0:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1468

jmp_1518:
  mov64 r1, 0x8
  mov64 r2, 0xb8
  call fn_cb058

fn_1530:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r5, r10
  call fn_fa50
  ldxw r1, [r10-0x28]
  jne r1, 0x2, jmp_1590
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1660

jmp_1590:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0xb8
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_1668
  jeq r4, 0x0, jmp_1678

jmp_15e0:
  lddw r7, 0x300007f48
  jne r1, 0x0, jmp_1698

jmp_15f8:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_16c0

jmp_1610:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r1, r7
  mov64 r3, 0xb8
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_1660:
  exit

jmp_1668:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_15e0

jmp_1678:
  mov64 r2, r3
  lddw r7, 0x300007f48
  jeq r1, 0x0, jmp_15f8

jmp_1698:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1610

jmp_16c0:
  mov64 r1, 0x8
  mov64 r2, 0xb8
  call fn_cb058

fn_16d8:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r5, r10
  call fn_f570
  ldxw r1, [r10-0x60]
  jne r1, 0x2, jmp_1738
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1808

jmp_1738:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x60
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_1810
  jeq r4, 0x0, jmp_1820

jmp_1788:
  lddw r7, 0x300007fa0
  jne r1, 0x0, jmp_1840

jmp_17a0:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1868

jmp_17b8:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r1, r7
  mov64 r3, 0x60
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_1808:
  exit

jmp_1810:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1788

jmp_1820:
  mov64 r2, r3
  lddw r7, 0x300007fa0
  jeq r1, 0x0, jmp_17a0

jmp_1840:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_17b8

jmp_1868:
  mov64 r1, 0x8
  mov64 r2, 0x60
  call fn_cb058

fn_1880:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r5, r10
  call fn_f8f0
  ldxb r1, [r10-0x6]
  jne r1, 0x2, jmp_18e0
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x110]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_19b0

jmp_18e0:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x118
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_19b8
  jeq r4, 0x0, jmp_19c8

jmp_1930:
  lddw r7, 0x300007ee8
  jne r1, 0x0, jmp_19e8

jmp_1948:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1a10

jmp_1960:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x118
  mov64 r1, r7
  mov64 r3, 0x118
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_19b0:
  exit

jmp_19b8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1930

jmp_19c8:
  mov64 r2, r3
  lddw r7, 0x300007ee8
  jeq r1, 0x0, jmp_1948

jmp_19e8:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1960

jmp_1a10:
  mov64 r1, 0x8
  mov64 r2, 0x118
  call fn_cb058

fn_1a28:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r5, r10
  call fn_f570
  ldxw r1, [r10-0x60]
  jne r1, 0x2, jmp_1a88
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1b58

jmp_1a88:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x60
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_1b60
  jeq r4, 0x0, jmp_1b70

jmp_1ad8:
  lddw r7, 0x300007fa0
  jne r1, 0x0, jmp_1b90

jmp_1af0:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1bb8

jmp_1b08:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r1, r7
  mov64 r3, 0x60
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_1b58:
  exit

jmp_1b60:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1ad8

jmp_1b70:
  mov64 r2, r3
  lddw r7, 0x300007fa0
  jeq r1, 0x0, jmp_1af0

jmp_1b90:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1b08

jmp_1bb8:
  mov64 r1, 0x8
  mov64 r2, 0x60
  call fn_cb058

fn_1bd0:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r5, r10
  call fn_f8f0
  ldxb r1, [r10-0x6]
  jne r1, 0x2, jmp_1c30
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x110]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1d00

jmp_1c30:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x118
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_1d08
  jeq r4, 0x0, jmp_1d18

jmp_1c80:
  lddw r7, 0x300007ee8
  jne r1, 0x0, jmp_1d38

jmp_1c98:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1d60

jmp_1cb0:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x118
  mov64 r1, r7
  mov64 r3, 0x118
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_1d00:
  exit

jmp_1d08:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1c80

jmp_1d18:
  mov64 r2, r3
  lddw r7, 0x300007ee8
  jeq r1, 0x0, jmp_1c98

jmp_1d38:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1cb0

jmp_1d60:
  mov64 r1, 0x8
  mov64 r2, 0x118
  call fn_cb058

fn_1d78:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r5, r10
  call fn_fa50
  ldxw r1, [r10-0x28]
  jne r1, 0x2, jmp_1dd8
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1ea8

jmp_1dd8:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0xb8
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_1eb0
  jeq r4, 0x0, jmp_1ec0

jmp_1e28:
  lddw r7, 0x300007f48
  jne r1, 0x0, jmp_1ee0

jmp_1e40:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_1f08

jmp_1e58:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r1, r7
  mov64 r3, 0xb8
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_1ea8:
  exit

jmp_1eb0:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1e28

jmp_1ec0:
  mov64 r2, r3
  lddw r7, 0x300007f48
  jeq r1, 0x0, jmp_1e40

jmp_1ee0:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_1e58

jmp_1f08:
  mov64 r1, 0x8
  mov64 r2, 0xb8
  call fn_cb058

fn_1f20:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r5, r10
  call fn_fa50
  ldxw r1, [r10-0x28]
  jne r1, 0x2, jmp_1f80
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_2050

jmp_1f80:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0xb8
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_2058
  jeq r4, 0x0, jmp_2068

jmp_1fd0:
  lddw r7, 0x300007f48
  jne r1, 0x0, jmp_2088

jmp_1fe8:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_20b0

jmp_2000:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r1, r7
  mov64 r3, 0xb8
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_2050:
  exit

jmp_2058:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_1fd0

jmp_2068:
  mov64 r2, r3
  lddw r7, 0x300007f48
  jeq r1, 0x0, jmp_1fe8

jmp_2088:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_2000

jmp_20b0:
  mov64 r1, 0x8
  mov64 r2, 0xb8
  call fn_cb058

fn_20c8:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r5, r10
  call fn_f570
  ldxw r1, [r10-0x60]
  jne r1, 0x2, jmp_2128
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_21f8

jmp_2128:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x60
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_2200
  jeq r4, 0x0, jmp_2210

jmp_2178:
  lddw r7, 0x300007fa0
  jne r1, 0x0, jmp_2230

jmp_2190:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_2258

jmp_21a8:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r1, r7
  mov64 r3, 0x60
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_21f8:
  exit

jmp_2200:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2178

jmp_2210:
  mov64 r2, r3
  lddw r7, 0x300007fa0
  jeq r1, 0x0, jmp_2190

jmp_2230:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_21a8

jmp_2258:
  mov64 r1, 0x8
  mov64 r2, 0x60
  call fn_cb058

fn_2270:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r5, r10
  call fn_f6d0
  ldxw r1, [r10-0x60]
  jne r1, 0x2, jmp_22d0
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_23a0

jmp_22d0:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x60
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_23a8
  jeq r4, 0x0, jmp_23b8

jmp_2320:
  lddw r7, 0x300007fa0
  jne r1, 0x0, jmp_23d8

jmp_2338:
  lddw r1, 0x300000008
  jlt r7, r1, jmp_2400

jmp_2350:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0x60
  mov64 r1, r7
  mov64 r3, 0x60
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_23a0:
  exit

jmp_23a8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2320

jmp_23b8:
  mov64 r2, r3
  lddw r7, 0x300007fa0
  jeq r1, 0x0, jmp_2338

jmp_23d8:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000008
  jge r7, r1, jmp_2350

jmp_2400:
  mov64 r1, 0x8
  mov64 r2, 0x60
  call fn_cb058

fn_2418:
  mov64 r7, 0x2
  jeq r2, 0x0, jmp_24c0
  ldxdw r4, [r3+0x0]
  lddw r5, -0x6c5e9a281e0922fa
  jne r4, r5, jmp_24b0
  ldxdw r4, [r3+0x8]
  lddw r5, -0x53861431b91e3427
  jne r4, r5, jmp_24b0
  ldxdw r4, [r3+0x10]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_24b0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x18]
  lddw r5, -0x56ff00817a0a73c6
  jeq r3, r5, jmp_24b8

jmp_24b0:
  mov64 r4, 0x1

jmp_24b8:
  jeq r4, 0x0, jmp_24c8

jmp_24c0:
  ja jmp_2568

jmp_24c8:
  mov64 r8, r1
  ldxdw r6, [r2+0x0]
  mov64 r1, r6
  call fn_be6d0
  jne r0, 0x0, jmp_2560
  ldxdw r1, [r6+0x10]
  ldxdw r1, [r1+0x10]
  jeq r1, 0x0, jmp_2560
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x18
  call fn_be7f0
  ldxdw r7, [r10-0x28]
  ldxdw r2, [r10-0x20]
  ja jmp_2560

jmp_2560:
  mov64 r1, r8

jmp_2568:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r7
  exit

fn_2580:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_2668
  ldxdw r0, [r2+0x0]
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r4+0x0]
  ldxdw r7, [r5+0x0]
  jne r7, r0, jmp_2610
  ldxdw r0, [r2+0x8]
  ldxdw r7, [r5+0x8]
  jne r7, r0, jmp_2610
  ldxdw r0, [r2+0x10]
  ldxdw r7, [r5+0x10]
  jne r7, r0, jmp_2610
  mov64 r0, 0x0
  ldxdw r2, [r2+0x18]
  ldxdw r5, [r5+0x18]
  jeq r5, r2, jmp_2618

jmp_2610:
  mov64 r0, 0x1

jmp_2618:
  jeq r0, 0x0, jmp_26b0
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r5, r10
  call fn_fa50
  ldxw r1, [r10-0x28]
  jne r1, 0x2, jmp_26e8
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]
  ja jmp_2698

jmp_2668:
  mov64 r1, r10
  add64 r1, -0xc8
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0xc8]
  ldxdw r2, [r10-0xc0]

jmp_2698:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_27b8

jmp_26b0:
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  stdw [r6+0x0], 0x2
  stdw [r6+0x8], 0x0
  ja jmp_27b8

jmp_26e8:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0xb8
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_27c0
  jeq r4, 0x0, jmp_27d0

jmp_2738:
  lddw r7, 0x300007f48
  jne r1, 0x0, jmp_27f0

jmp_2750:
  lddw r1, 0x300000007
  jle r7, r1, jmp_2818

jmp_2768:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r1, r7
  mov64 r3, 0xb8
  call fn_d23d0
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_27b8:
  exit

jmp_27c0:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2738

jmp_27d0:
  mov64 r2, r3
  lddw r7, 0x300007f48
  jeq r1, 0x0, jmp_2750

jmp_27f0:
  and64 r2, -0x8
  mov64 r7, r2
  lddw r1, 0x300000007
  jgt r7, r1, jmp_2768

jmp_2818:
  mov64 r1, 0x8
  mov64 r2, 0xb8
  call fn_cb058

fn_2830:
  mov64 r6, r1
  ldxdw r4, [r3+0x8]
  jeq r4, 0x0, jmp_2910
  ldxdw r0, [r2+0x0]
  ldxdw r1, [r3+0x0]
  ldxdw r5, [r1+0x0]
  ldxdw r7, [r5+0x0]
  jne r7, r0, jmp_28c0
  ldxdw r0, [r2+0x8]
  ldxdw r7, [r5+0x8]
  jne r7, r0, jmp_28c0
  ldxdw r0, [r2+0x10]
  ldxdw r7, [r5+0x10]
  jne r7, r0, jmp_28c0
  mov64 r0, 0x0
  ldxdw r2, [r2+0x18]
  ldxdw r5, [r5+0x18]
  jeq r5, r2, jmp_28c8

jmp_28c0:
  mov64 r0, 0x1

jmp_28c8:
  add64 r4, -0x1
  stxdw [r3+0x8], r4
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  jeq r0, 0x0, jmp_2958
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_2968

jmp_2910:
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_2968

jmp_2958:
  stdw [r6+0x0], 0x2
  stdw [r6+0x8], 0x0

jmp_2968:
  exit

fn_2970:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_2a58
  ldxdw r0, [r2+0x0]
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r4+0x0]
  ldxdw r7, [r5+0x0]
  jne r7, r0, jmp_2a00
  ldxdw r0, [r2+0x8]
  ldxdw r7, [r5+0x8]
  jne r7, r0, jmp_2a00
  ldxdw r0, [r2+0x10]
  ldxdw r7, [r5+0x10]
  jne r7, r0, jmp_2a00
  mov64 r0, 0x0
  ldxdw r2, [r2+0x18]
  ldxdw r5, [r5+0x18]
  jeq r5, r2, jmp_2a08

jmp_2a00:
  mov64 r0, 0x1

jmp_2a08:
  jeq r0, 0x0, jmp_2aa0
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r5, r10
  call fn_10120
  ldxdw r1, [r10-0x8]
  ldxdw r2, [r10-0x10]
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  ja jmp_2ad0

jmp_2a58:
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x20]
  ldxdw r2, [r10-0x18]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_2ad0

jmp_2aa0:
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  stdw [r6+0x0], 0x2
  stdw [r6+0x8], 0x0

jmp_2ad0:
  exit

fn_2ad8:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_2b30
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_2b30
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_2b30
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_2f60

jmp_2b30:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_2b58

jmp_2b40:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_2e30

jmp_2b58:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_2be0
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_2be0
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_2be0
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_2be8

jmp_2be0:
  mov64 r1, 0x1

jmp_2be8:
  jeq r1, 0x0, jmp_2d00
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x190]
  ldxdw r2, [r10-0x198]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x160], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x168], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x170], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x178], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x158], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x150], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x148], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x140], r1
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r4, r10
  add64 r4, -0x178
  call fn_be990
  ldxdw r1, [r10-0x1a8]
  ldxdw r2, [r10-0x1a0]
  ja jmp_2e60

jmp_2d00:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_2dd0
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x180], r1
  stxdw [r10-0x188], r2
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r10
  add64 r2, -0x188
  call fn_53140
  ldxb r9, [r10-0x177]
  jne r9, 0x7, jmp_2e80
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7
  ja jmp_2f40

jmp_2dd0:
  stxdw [r10-0x168], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r10
  add64 r2, -0x178
  call fn_be7f0
  ldxdw r1, [r10-0x1b8]
  ldxdw r2, [r10-0x1b0]
  ja jmp_2e60

jmp_2e30:
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x1c8]
  ldxdw r2, [r10-0x1c0]

jmp_2e60:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7

jmp_2e78:
  exit

jmp_2e80:
  ldxb r1, [r10-0x178]
  stxdw [r10-0x1d0], r1
  ldxh r1, [r10-0x172]
  stxh [r6+0x6], r1
  ldxw r1, [r10-0x176]
  stxw [r6+0x2], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x1d8], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x1e0], r1
  mov64 r1, r6
  add64 r1, 0x18
  mov64 r2, r10
  add64 r2, -0x160
  mov64 r3, 0x160
  call fn_d23d0
  stxdw [r6+0x178], r7
  ldxdw r1, [r10-0x1e0]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r6+0x8], r1
  stxb [r6+0x1], r9
  ldxdw r1, [r10-0x1d0]
  stxb [r6+0x0], r1

jmp_2f40:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_2e78

jmp_2f60:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_2b58
  ja jmp_2b40

fn_2f78:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_2fd0
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_2fd0
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_2fd0
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_33b0

jmp_2fd0:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_2ff8

jmp_2fe0:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_32d0

jmp_2ff8:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_3080
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_3080
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_3080
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_3088

jmp_3080:
  mov64 r1, 0x1

jmp_3088:
  jeq r1, 0x0, jmp_31a0
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x88], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x90], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x98], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0xa0], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x80], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x78], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x70], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r4, r10
  add64 r4, -0xa0
  call fn_be990
  ldxdw r1, [r10-0xd0]
  ldxdw r2, [r10-0xc8]
  ja jmp_3300

jmp_31a0:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_3270
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0xa8], r1
  stxdw [r10-0xb0], r2
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r10
  add64 r2, -0xb0
  call fn_57510
  ldxdw r2, [r10-0x98]
  ldxdw r1, [r10-0xa0]
  ldxb r9, [r10-0x1]
  jne r9, 0x2, jmp_3320
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0xa7], 0x2
  ja jmp_3390

jmp_3270:
  stxdw [r10-0x90], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xa0], r1
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be7f0
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xd8]
  ja jmp_3300

jmp_32d0:
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xf0]
  ldxdw r2, [r10-0xe8]

jmp_3300:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0xa7], 0x2

jmp_3318:
  exit

jmp_3320:
  stxdw [r10-0xf8], r1
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0x100], r2
  mov64 r2, r10
  add64 r2, -0x90
  mov64 r3, 0x8f
  call fn_d23d0
  stxb [r6+0xa7], r9
  ldxdw r1, [r10-0x100]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r7

jmp_3390:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_3318

jmp_33b0:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_2ff8
  ja jmp_2fe0

fn_33c8:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_3420
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_3420
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_3420
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_3800

jmp_3420:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_3448

jmp_3430:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_3720

jmp_3448:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_34d0
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_34d0
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_34d0
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_34d8

jmp_34d0:
  mov64 r1, 0x1

jmp_34d8:
  jeq r1, 0x0, jmp_35f0
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x80]
  ldxdw r2, [r10-0x88]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x58], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x68], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x48], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x40], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x38], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r4, r10
  add64 r4, -0x68
  call fn_be990
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0x90]
  ja jmp_3750

jmp_35f0:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_36c0
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x70], r1
  stxdw [r10-0x78], r2
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r10
  add64 r2, -0x78
  call fn_58e30
  ldxdw r2, [r10-0x58]
  ldxdw r1, [r10-0x60]
  ldxdw r9, [r10-0x68]
  jne r9, 0x2, jmp_3770
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_37e0

jmp_36c0:
  stxdw [r10-0x58], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x68
  call fn_be7f0
  ldxdw r1, [r10-0xa8]
  ldxdw r2, [r10-0xa0]
  ja jmp_3750

jmp_3720:
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]

jmp_3750:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2

jmp_3768:
  exit

jmp_3770:
  stxdw [r10-0xc0], r1
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0xc8], r2
  mov64 r2, r10
  add64 r2, -0x50
  mov64 r3, 0x50
  call fn_d23d0
  stxdw [r6+0x68], r7
  ldxdw r1, [r10-0xc8]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r9

jmp_37e0:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_3768

jmp_3800:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_3448
  ja jmp_3430

fn_3818:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_3870
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_3870
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_3870
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_3c58

jmp_3870:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_3898

jmp_3880:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_3b70

jmp_3898:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_3920
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_3920
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_3920
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_3928

jmp_3920:
  mov64 r1, 0x1

jmp_3928:
  jeq r1, 0x0, jmp_3a40
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x68]
  ldxdw r2, [r10-0x70]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x48], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x58], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x60], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x40], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x38], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x30], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r4, r10
  add64 r4, -0x60
  call fn_be990
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_3ba0

jmp_3a40:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_3b10
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x18], r1
  stxdw [r10-0x20], r2
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x20
  call fn_b1a18
  ldxw r1, [r10-0x60]
  jne r1, 0x1, jmp_3bc0
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0
  ja jmp_3c38

jmp_3b10:
  stxdw [r10-0x50], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x60], r1
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x60
  call fn_be7f0
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]
  ja jmp_3ba0

jmp_3b70:
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xa0]
  ldxdw r2, [r10-0x98]

jmp_3ba0:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0

jmp_3bb8:
  exit

jmp_3bc0:
  ldxdw r1, [r10-0x48]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x8], r1
  ldxw r1, [r10-0x5c]
  ldxdw r2, [r10-0x58]
  ldxdw r3, [r10-0x50]
  stxdw [r6+0x14], r3
  stxdw [r6+0xc], r2
  stxw [r6+0x8], r1
  stxdw [r6+0x0], r7
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x1c], r1
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x24], r1

jmp_3c38:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_3bb8

jmp_3c58:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_3898
  ja jmp_3880

fn_3c70:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_3cc8
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_3cc8
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_3cc8
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_40c8

jmp_3cc8:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_3cf0

jmp_3cd8:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_3fd8

jmp_3cf0:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_3d78
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_3d78
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_3d78
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_3d80

jmp_3d78:
  mov64 r1, 0x1

jmp_3d80:
  jeq r1, 0x0, jmp_3e98
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x58]
  ldxdw r2, [r10-0x60]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x40], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x20], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x18], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x10], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]
  ja jmp_4008

jmp_3e98:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_3f78
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x48], r1
  stxdw [r10-0x50], r2
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, r10
  add64 r2, -0x50
  call fn_58418
  ldxdw r2, [r10-0x30]
  ldxdw r1, [r10-0x38]
  ldxdw r3, [r10-0x40]
  lddw r4, -0x8000000000000000
  jne r3, r4, jmp_4038
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r4
  ja jmp_40a8

jmp_3f78:
  stxdw [r10-0x30], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, r10
  add64 r2, -0x40
  call fn_be7f0
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_4008

jmp_3fd8:
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]

jmp_4008:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1

jmp_4030:
  exit

jmp_4038:
  ldxdw r4, [r10-0x8]
  stxdw [r6+0x38], r4
  ldxdw r4, [r10-0x10]
  stxdw [r6+0x30], r4
  ldxdw r4, [r10-0x18]
  stxdw [r6+0x28], r4
  ldxdw r4, [r10-0x20]
  stxdw [r6+0x20], r4
  ldxdw r4, [r10-0x28]
  stxdw [r6+0x18], r4
  stxdw [r6+0x40], r7
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r3

jmp_40a8:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_4030

jmp_40c8:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_3cf0
  ja jmp_3cd8

fn_40e0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_4138
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_4138
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_4138
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_4570

jmp_4138:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_4160

jmp_4148:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_4438

jmp_4160:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_41e8
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_41e8
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_41e8
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_41f0

jmp_41e8:
  mov64 r1, 0x1

jmp_41f0:
  jeq r1, 0x0, jmp_4308
  mov64 r1, r10
  add64 r1, -0x228
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x220]
  ldxdw r2, [r10-0x228]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x100], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x110], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0xf0], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0xe8], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0xe0], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r4, r10
  add64 r4, -0x110
  call fn_be990
  ldxdw r1, [r10-0x238]
  ldxdw r2, [r10-0x230]
  ja jmp_4468

jmp_4308:
  ldxdw r1, [r7+0x10]
  mov64 r9, r1
  add64 r9, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_43d8
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x210], r1
  stxdw [r10-0x218], r2
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0x218
  call fn_54510
  ldxw r1, [r10-0x110]
  jne r1, 0x1, jmp_4488
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x100]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2
  ja jmp_4550

jmp_43d8:
  stxdw [r10-0x100], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, r10
  add64 r2, -0x110
  call fn_be7f0
  ldxdw r1, [r10-0x248]
  ldxdw r2, [r10-0x240]
  ja jmp_4468

jmp_4438:
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x258]
  ldxdw r2, [r10-0x250]

jmp_4468:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2

jmp_4480:
  exit

jmp_4488:
  ldxw r1, [r10-0x10c]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x268], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x270], r1
  mov64 r8, r10
  add64 r8, -0x208
  mov64 r2, r10
  add64 r2, -0xf8
  mov64 r1, r8
  mov64 r3, 0xf8
  call fn_d23d0
  ldxdw r1, [r10-0x270]
  stxdw [r6+0x14], r1
  ldxdw r1, [r10-0x268]
  stxdw [r6+0xc], r1
  ldxdw r1, [r10-0x260]
  stxw [r6+0x8], r1
  stxdw [r6+0x0], r7
  add64 r6, 0x1c
  mov64 r1, r6
  mov64 r2, r8
  mov64 r3, 0xf8
  call fn_d23d0

jmp_4550:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1
  ja jmp_4480

jmp_4570:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_4160
  ja jmp_4148

fn_4588:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_45e0
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_45e0
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_45e0
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_49a8

jmp_45e0:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_4608

jmp_45f0:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_48e0

jmp_4608:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_4690
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_4690
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_4690
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_4698

jmp_4690:
  mov64 r1, 0x1

jmp_4698:
  jeq r1, 0x0, jmp_47b0
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x68]
  ldxdw r2, [r10-0x70]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x38], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x40], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x48], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x50], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x30], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x28], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x20], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r4, r10
  add64 r4, -0x50
  call fn_be990
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_4910

jmp_47b0:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_4880
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r10
  add64 r2, -0x60
  call fn_56da0
  ldxdw r9, [r10-0x40]
  ldxdw r2, [r10-0x48]
  ldxdw r1, [r10-0x50]
  jne r1, 0x1, jmp_4930
  stxdw [r6+0x10], r9
  stxdw [r6+0x8], r2
  stdw [r6+0x0], 0x0
  ja jmp_4988

jmp_4880:
  stxdw [r10-0x40], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x50
  call fn_be7f0
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]
  ja jmp_4910

jmp_48e0:
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xa0]
  ldxdw r2, [r10-0x98]

jmp_4910:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0

jmp_4928:
  exit

jmp_4930:
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0xa8], r2
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x38
  call fn_d23d0
  stxdw [r6+0x10], r9
  ldxdw r1, [r10-0xa8]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r7

jmp_4988:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_4928

jmp_49a8:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_4608
  ja jmp_45f0

fn_49c0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_4a18
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_4a18
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_4a18
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_4e48

jmp_4a18:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_4a40

jmp_4a28:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_4d18

jmp_4a40:
  ldxdw r1, [r8+0x0]
  lddw r2, -0x6c5e9a281e0922fa
  jne r1, r2, jmp_4ac8
  ldxdw r1, [r8+0x8]
  lddw r2, -0x53861431b91e3427
  jne r1, r2, jmp_4ac8
  ldxdw r1, [r8+0x10]
  lddw r2, -0x6ec8a4a0127a4be4
  jne r1, r2, jmp_4ac8
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x56ff00817a0a73c6
  jeq r2, r3, jmp_4ad0

jmp_4ac8:
  mov64 r1, 0x1

jmp_4ad0:
  jeq r1, 0x0, jmp_4be8
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0xc8]
  ldxdw r2, [r10-0xd0]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0xb0], r1
  lddw r1, -0x6c5e9a281e0922fa
  stxdw [r10-0x90], r1
  lddw r1, -0x53861431b91e3427
  stxdw [r10-0x88], r1
  lddw r1, -0x6ec8a4a0127a4be4
  stxdw [r10-0x80], r1
  lddw r1, -0x56ff00817a0a73c6
  stxdw [r10-0x78], r1
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r4, r10
  add64 r4, -0xb0
  call fn_be990
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xd8]
  ja jmp_4d48

jmp_4be8:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_4cb8
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0xb8], r1
  stxdw [r10-0xc0], r2
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_b9170
  ldxdw r2, [r10-0xa8]
  ldxdw r1, [r10-0xb0]
  ldxw r9, [r10-0x28]
  jne r9, 0x2, jmp_4d68
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stw [r6+0x90], 0x2
  ja jmp_4e28

jmp_4cb8:
  stxdw [r10-0xa0], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xb0], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0xb0
  call fn_be7f0
  ldxdw r1, [r10-0xf0]
  ldxdw r2, [r10-0xe8]
  ja jmp_4d48

jmp_4d18:
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]

jmp_4d48:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stw [r6+0x90], 0x2

jmp_4d60:
  exit

jmp_4d68:
  stxdw [r10-0x108], r1
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0x110], r2
  mov64 r2, r10
  add64 r2, -0xa0
  mov64 r3, 0x78
  call fn_d23d0
  ldxdw r1, [r10-0x24]
  stxdw [r6+0x94], r1
  ldxdw r1, [r10-0x1c]
  stxdw [r6+0x9c], r1
  ldxdw r1, [r10-0x14]
  stxdw [r6+0xa4], r1
  ldxdw r1, [r10-0xc]
  stxdw [r6+0xac], r1
  ldxw r1, [r10-0x4]
  stxw [r6+0xb4], r1
  stxw [r6+0x90], r9
  ldxdw r1, [r10-0x110]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x108]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r7

jmp_4e28:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_4d60

jmp_4e48:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_4a40
  ja jmp_4a28

fn_4e60:
  ldxdw r5, [r4+0x0]
  ldxdw r0, [r3+0x0]
  jne r0, r5, jmp_4ec8
  ldxdw r5, [r4+0x8]
  ldxdw r0, [r3+0x8]
  jne r0, r5, jmp_4ec8
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r3+0x10]
  jne r0, r5, jmp_4ec8
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_4ed0

jmp_4ec8:
  mov64 r5, 0x1

jmp_4ed0:
  mov64 r8, 0x2
  jeq r5, 0x0, jmp_4ee8
  ja jmp_57c0

jmp_4ee8:
  mov64 r7, r1
  mov64 r9, r2
  ldxdw r6, [r2+0x0]
  mov64 r1, r6
  call fn_be6d0
  jeq r0, 0x0, jmp_4f28
  mov64 r1, r7
  ja jmp_57c0

jmp_4f28:
  ldxdw r6, [r6+0x10]
  ldxdw r1, [r6+0x10]
  jeq r1, 0x0, jmp_4fa0
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x30]
  mov64 r1, r7
  ja jmp_57b8

jmp_4fa0:
  stdw [r6+0x10], -0x1
  ldxdw r1, [r6+0x18]
  ldxdw r2, [r6+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_1408
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x10e
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x10f
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x28
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x48
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxw r1, [r9+0x68]
  stxw [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0x70]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0x6f]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxh r1, [r9+0x6c]
  stxh [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x2
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x6e
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x74
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x94
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxw r1, [r9+0xb4]
  stxw [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0xbc]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0xbb]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxh r1, [r9+0xb8]
  stxh [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x2
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0xba
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0xc0
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0xe0
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxw r1, [r9+0x100]
  stxw [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0x108]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0x107]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxh r1, [r9+0x104]
  stxh [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x2
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x106
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x110
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxh r1, [r9+0x10c]
  stxh [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x2
  call fn_be210
  jne r0, 0x0, jmp_5708
  mov64 r2, r9
  add64 r2, 0x111
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5708
  ldxb r1, [r9+0x112]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jeq r0, 0x0, jmp_57d8

jmp_5708:
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_5760
  jeq r1, 0x0, jmp_5760
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_5760
  ldxdw r1, [r0-0x1]
  callx r2

jmp_5760:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r2, [r10-0x38]
  ldxdw r3, [r10-0x40]
  ldxdw r1, [r6+0x10]
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  mov64 r1, r7
  jeq r3, 0x2, jmp_57c0

jmp_57b8:
  mov64 r8, r3

jmp_57c0:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r8
  exit

jmp_57d8:
  ldxdw r1, [r6+0x10]
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  mov64 r1, r7
  ja jmp_57c0

fn_5800:
  mov64 r6, r1
  ldxdw r1, [r4+0x0]
  ldxdw r5, [r3+0x0]
  jne r5, r1, jmp_5870
  ldxdw r1, [r4+0x8]
  ldxdw r5, [r3+0x8]
  jne r5, r1, jmp_5870
  ldxdw r1, [r4+0x10]
  ldxdw r5, [r3+0x10]
  jne r5, r1, jmp_5870
  mov64 r1, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_5878

jmp_5870:
  mov64 r1, 0x1

jmp_5878:
  mov64 r8, 0x2
  jne r1, 0x0, jmp_58b0
  mov64 r9, r2
  ldxdw r7, [r2+0x0]
  mov64 r1, r7
  call fn_be6d0
  jeq r0, 0x0, jmp_58c8

jmp_58b0:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r8
  exit

jmp_58c8:
  ldxdw r7, [r7+0x10]
  ldxdw r1, [r7+0x10]
  jeq r1, 0x0, jmp_5938
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ja jmp_5ce0

jmp_5938:
  stdw [r7+0x10], -0x1
  ldxdw r1, [r7+0x18]
  ldxdw r2, [r7+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_13a0
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r2, r9
  add64 r2, 0xa4
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5c38
  ldxdw r1, [r9+0x88]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r2, r9
  add64 r2, 0x48
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r2, r9
  add64 r2, 0xa5
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5c38
  ldxdw r1, [r9+0x90]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_5c38
  ldxdw r1, [r9+0x98]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r2, r9
  add64 r2, 0xa6
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r2, r9
  add64 r2, 0xa0
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_5c38
  mov64 r1, r9
  add64 r1, 0x68
  mov64 r2, r10
  add64 r2, -0x20
  call fn_cab8
  jne r0, 0x0, jmp_5c38
  mov64 r1, r9
  add64 r1, 0x8
  mov64 r2, r10
  add64 r2, -0x20
  call fn_d0b8
  jne r0, 0x0, jmp_5c38
  ldxb r1, [r9+0xa7]
  stxb [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x1
  call fn_be210
  jeq r0, 0x0, jmp_5cf0

jmp_5c38:
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_5c90
  jeq r1, 0x0, jmp_5c90
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_5c90
  ldxdw r1, [r0-0x1]
  callx r2

jmp_5c90:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r1, [r10-0x38]
  ldxdw r2, [r10-0x40]
  ldxdw r3, [r7+0x10]
  add64 r3, 0x1
  stxdw [r7+0x10], r3
  jeq r2, 0x2, jmp_58b0

jmp_5ce0:
  mov64 r8, r2
  ja jmp_58b0

jmp_5cf0:
  ldxdw r1, [r7+0x10]
  add64 r1, 0x1
  stxdw [r7+0x10], r1
  ja jmp_58b0

fn_5d10:
  ldxdw r5, [r4+0x0]
  ldxdw r0, [r3+0x0]
  jne r0, r5, jmp_5d78
  ldxdw r5, [r4+0x8]
  ldxdw r0, [r3+0x8]
  jne r0, r5, jmp_5d78
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r3+0x10]
  jne r0, r5, jmp_5d78
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_5d80

jmp_5d78:
  mov64 r5, 0x1

jmp_5d80:
  mov64 r7, 0x2
  jeq r5, 0x0, jmp_5d98
  ja jmp_60c8

jmp_5d98:
  mov64 r8, r1
  mov64 r9, r2
  ldxdw r6, [r2+0x40]
  mov64 r1, r6
  call fn_be6d0
  jeq r0, 0x0, jmp_5dd8
  mov64 r1, r8
  ja jmp_60c8

jmp_5dd8:
  ldxdw r6, [r6+0x10]
  ldxdw r1, [r6+0x10]
  jeq r1, 0x0, jmp_5e50
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x30]
  mov64 r1, r8
  ja jmp_60c0

jmp_5e50:
  stdw [r6+0x10], -0x1
  ldxdw r1, [r6+0x18]
  ldxdw r2, [r6+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_13f0
  mov64 r3, 0x8
  call fn_be210
  jeq r0, 0x0, jmp_5ef0
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_6068
  jne r1, 0x0, jmp_6040
  ja jmp_6068

jmp_5ef0:
  mov64 r2, r9
  add64 r2, 0x38
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5ff0
  mov64 r2, r9
  add64 r2, 0x18
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_5ff0
  lddw r0, 0x1400000003
  mov64 r1, r9
  ldxdw r9, [r1+0x10]
  lddw r2, 0xffffffff
  jgt r9, r2, jmp_5ff0
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x48], r1
  stxw [r10-0x4], r9
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  mov64 r1, r9
  jeq r0, 0x0, jmp_60e0

jmp_5ff0:
  mov64 r1, r0
  and64 r1, 0x3
  jsgt r1, 0x1, jmp_6010
  jne r1, 0x0, jmp_6040

jmp_6010:
  jne r0, 0x0, jmp_6068

jmp_6018:
  ldxdw r1, [r6+0x10]
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  mov64 r1, r8
  ja jmp_60c8

jmp_6040:
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_6068
  ldxdw r1, [r0-0x1]
  callx r2

jmp_6068:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r2, [r10-0x38]
  ldxdw r3, [r10-0x40]
  ldxdw r1, [r6+0x10]
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  mov64 r1, r8
  jeq r3, 0x2, jmp_60c8

jmp_60c0:
  mov64 r7, r3

jmp_60c8:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r7
  exit

jmp_60e0:
  ldxdw r9, [r10-0x48]
  jeq r1, 0x0, jmp_6018

jmp_60f0:
  stxdw [r10-0x48], r1
  ldxb r1, [r9+0x0]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_5ff0
  add64 r9, 0x1
  ldxdw r1, [r10-0x48]
  add64 r1, -0x1
  jne r1, 0x0, jmp_60f0
  ja jmp_6018

fn_6168:
  mov64 r6, r1
  ldxdw r1, [r4+0x0]
  ldxdw r5, [r3+0x0]
  jne r5, r1, jmp_61d8
  ldxdw r1, [r4+0x8]
  ldxdw r5, [r3+0x8]
  jne r5, r1, jmp_61d8
  ldxdw r1, [r4+0x10]
  ldxdw r5, [r3+0x10]
  jne r5, r1, jmp_61d8
  mov64 r1, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_61e0

jmp_61d8:
  mov64 r1, 0x1

jmp_61e0:
  mov64 r8, 0x2
  jne r1, 0x0, jmp_6218
  mov64 r9, r2
  ldxdw r7, [r2+0x0]
  mov64 r1, r7
  call fn_be6d0
  jeq r0, 0x0, jmp_6230

jmp_6218:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r8
  exit

jmp_6230:
  ldxdw r7, [r7+0x10]
  ldxdw r1, [r7+0x10]
  jeq r1, 0x0, jmp_62a0
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ja jmp_6430

jmp_62a0:
  stdw [r7+0x10], -0x1
  ldxdw r1, [r7+0x18]
  ldxdw r2, [r7+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_13b0
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_6388
  mov64 r2, r9
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_6388
  ldxw r1, [r9+0x28]
  stxw [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  jeq r0, 0x0, jmp_6440

jmp_6388:
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_63e0
  jeq r1, 0x0, jmp_63e0
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_63e0
  ldxdw r1, [r0-0x1]
  callx r2

jmp_63e0:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r1, [r10-0x38]
  ldxdw r2, [r10-0x40]
  ldxdw r3, [r7+0x10]
  add64 r3, 0x1
  stxdw [r7+0x10], r3
  jeq r2, 0x2, jmp_6218

jmp_6430:
  mov64 r8, r2
  ja jmp_6218

jmp_6440:
  ldxdw r1, [r7+0x10]
  add64 r1, 0x1
  stxdw [r7+0x10], r1
  ja jmp_6218

fn_6460:
  mov64 r6, r1
  ldxdw r1, [r4+0x0]
  ldxdw r5, [r3+0x0]
  jne r5, r1, jmp_64d0
  ldxdw r1, [r4+0x8]
  ldxdw r5, [r3+0x8]
  jne r5, r1, jmp_64d0
  ldxdw r1, [r4+0x10]
  ldxdw r5, [r3+0x10]
  jne r5, r1, jmp_64d0
  mov64 r1, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_64d8

jmp_64d0:
  mov64 r1, 0x1

jmp_64d8:
  mov64 r8, 0x2
  jne r1, 0x0, jmp_6510
  mov64 r9, r2
  ldxdw r7, [r2+0x68]
  mov64 r1, r7
  call fn_be6d0
  jeq r0, 0x0, jmp_6528

jmp_6510:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r8
  exit

jmp_6528:
  ldxdw r7, [r7+0x10]
  ldxdw r1, [r7+0x10]
  jeq r1, 0x0, jmp_6598
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ja jmp_68b8

jmp_6598:
  stdw [r7+0x10], -0x1
  ldxdw r1, [r7+0x18]
  ldxdw r2, [r7+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_13a8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r2, r9
  add64 r2, 0x65
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r2, r9
  add64 r2, 0x66
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r2, r9
  add64 r2, 0x10
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x20
  call fn_be210
  jne r0, 0x0, jmp_6810
  ldxdw r1, [r9+0x30]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_6810
  ldxdw r1, [r9+0x38]
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r1, r9
  ldxdw r2, [r1+0x8]
  ldxdw r1, [r1+0x0]
  mov64 r3, r10
  add64 r3, -0x20
  call fn_ef48
  jne r0, 0x0, jmp_6810
  mov64 r2, r9
  add64 r2, 0x67
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r2, r9
  add64 r2, 0x40
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_6810
  mov64 r1, r9
  add64 r1, 0x44
  mov64 r2, r10
  add64 r2, -0x20
  call fn_eea0
  jeq r0, 0x0, jmp_68c8

jmp_6810:
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_6868
  jeq r1, 0x0, jmp_6868
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_6868
  ldxdw r1, [r0-0x1]
  callx r2

jmp_6868:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r1, [r10-0x38]
  ldxdw r2, [r10-0x40]
  ldxdw r3, [r7+0x10]
  add64 r3, 0x1
  stxdw [r7+0x10], r3
  jeq r2, 0x2, jmp_6510

jmp_68b8:
  mov64 r8, r2
  ja jmp_6510

jmp_68c8:
  ldxdw r1, [r7+0x10]
  add64 r1, 0x1
  stxdw [r7+0x10], r1
  ja jmp_6510

fn_68e8:
  ldxdw r5, [r4+0x0]
  ldxdw r0, [r3+0x0]
  jne r0, r5, jmp_6950
  ldxdw r5, [r4+0x8]
  ldxdw r0, [r3+0x8]
  jne r0, r5, jmp_6950
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r3+0x10]
  jne r0, r5, jmp_6950
  mov64 r5, 0x0
  ldxdw r4, [r4+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r4, jmp_6958

jmp_6950:
  mov64 r5, 0x1

jmp_6958:
  mov64 r8, 0x2
  jeq r5, 0x0, jmp_6970
  ja jmp_6bf0

jmp_6970:
  mov64 r7, r1
  stxdw [r10-0x48], r2
  ldxdw r6, [r2+0x178]
  mov64 r1, r6
  call fn_be6d0
  jeq r0, 0x0, jmp_69b0
  mov64 r1, r7
  ja jmp_6bf0

jmp_69b0:
  ldxdw r9, [r6+0x10]
  ldxdw r1, [r9+0x10]
  jeq r1, 0x0, jmp_6a28
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r10
  add64 r2, -0x20
  call fn_be7f0
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x30]
  mov64 r1, r7
  ja jmp_6be8

jmp_6a28:
  stdw [r9+0x10], -0x1
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r9+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  stdw [r10-0x10], 0x0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_13e0
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r2, [r10-0x48]
  add64 r2, 0x172
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r2, [r10-0x48]
  add64 r2, 0x173
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r2, [r10-0x48]
  add64 r2, 0x174
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jeq r0, 0x0, jmp_6c08

jmp_6b38:
  mov64 r1, r0
  and64 r1, 0x3
  mov64 r2, r1
  add64 r2, -0x2
  jlt r2, 0x2, jmp_6b90
  jeq r1, 0x0, jmp_6b90
  ldxdw r1, [r0+0x7]
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_6b90
  ldxdw r1, [r0-0x1]
  callx r2

jmp_6b90:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0xbbc
  call fn_c1978
  ldxdw r2, [r10-0x38]
  ldxdw r3, [r10-0x40]
  ldxdw r1, [r9+0x10]
  add64 r1, 0x1
  stxdw [r9+0x10], r1
  mov64 r1, r7
  jeq r3, 0x2, jmp_6bf0

jmp_6be8:
  mov64 r8, r3

jmp_6bf0:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r8
  exit

jmp_6c08:
  mov64 r1, 0x0
  ldxdw r6, [r10-0x48]

jmp_6c18:
  stxdw [r10-0x50], r1
  add64 r6, r1
  ldxb r1, [r6+0x0]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x1]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x2]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x3]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x4]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x5]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x6]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x7]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x8]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x9]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0xa]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0xb]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0xc]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0xd]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0xe]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0xf]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x10]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxb r1, [r6+0x11]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r6, [r10-0x48]
  ldxdw r1, [r10-0x50]
  add64 r6, r1
  ldxb r1, [r6+0x12]
  stxb [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  add64 r6, 0x13
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r6
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r1, [r10-0x50]
  add64 r1, 0x14
  ldxdw r6, [r10-0x48]
  jne r1, 0x168, jmp_6c18
  mov64 r2, r6
  add64 r2, 0x168
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r1, [r10-0x48]
  ldxw r1, [r1+0x16c]
  stxw [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x4
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r1, [r10-0x48]
  ldxh r1, [r1+0x170]
  stxh [r10-0x4], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x4
  mov64 r3, 0x2
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r2, [r10-0x48]
  add64 r2, 0x175
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_6b38
  ldxdw r1, [r9+0x10]
  add64 r1, 0x1
  stxdw [r9+0x10], r1
  mov64 r8, 0x2
  mov64 r1, r7
  ja jmp_6bf0

fn_73f0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_7448
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_7448
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_7448
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_7810

jmp_7448:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_7470

jmp_7458:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_7748

jmp_7470:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_74f8
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_74f8
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_74f8
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_7500

jmp_74f8:
  mov64 r1, 0x1

jmp_7500:
  jeq r1, 0x0, jmp_7618
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x68]
  ldxdw r2, [r10-0x70]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x38], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x40], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x48], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x50], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x30], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x28], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x20], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r4, r10
  add64 r4, -0x50
  call fn_be990
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_7778

jmp_7618:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_76e8
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r2
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, r10
  add64 r2, -0x60
  call fn_56988
  ldxdw r9, [r10-0x40]
  ldxdw r2, [r10-0x48]
  ldxdw r1, [r10-0x50]
  jne r1, 0x1, jmp_7798
  stxdw [r6+0x10], r9
  stxdw [r6+0x8], r2
  stdw [r6+0x0], 0x0
  ja jmp_77f0

jmp_76e8:
  stxdw [r10-0x40], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x50
  call fn_be7f0
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]
  ja jmp_7778

jmp_7748:
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xa0]
  ldxdw r2, [r10-0x98]

jmp_7778:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0

jmp_7790:
  exit

jmp_7798:
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0xa8], r2
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x38
  call fn_d23d0
  stxdw [r6+0x10], r9
  ldxdw r1, [r10-0xa8]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r7

jmp_77f0:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_7790

jmp_7810:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_7470
  ja jmp_7458

fn_7828:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_7880
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_7880
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_7880
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_7c60

jmp_7880:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_78a8

jmp_7890:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_7b80

jmp_78a8:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_7930
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_7930
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_7930
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_7938

jmp_7930:
  mov64 r1, 0x1

jmp_7938:
  jeq r1, 0x0, jmp_7a50
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x80]
  ldxdw r2, [r10-0x88]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x58], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x68], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x48], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x40], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x38], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r4, r10
  add64 r4, -0x68
  call fn_be990
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0x90]
  ja jmp_7bb0

jmp_7a50:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_7b20
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x70], r1
  stxdw [r10-0x78], r2
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r10
  add64 r2, -0x78
  call fn_58a08
  ldxdw r2, [r10-0x58]
  ldxdw r1, [r10-0x60]
  ldxdw r9, [r10-0x68]
  jne r9, 0x2, jmp_7bd0
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_7c40

jmp_7b20:
  stxdw [r10-0x58], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x68
  call fn_be7f0
  ldxdw r1, [r10-0xa8]
  ldxdw r2, [r10-0xa0]
  ja jmp_7bb0

jmp_7b80:
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xb0]

jmp_7bb0:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2

jmp_7bc8:
  exit

jmp_7bd0:
  stxdw [r10-0xc0], r1
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0xc8], r2
  mov64 r2, r10
  add64 r2, -0x50
  mov64 r3, 0x50
  call fn_d23d0
  stxdw [r6+0x68], r7
  ldxdw r1, [r10-0xc8]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r9

jmp_7c40:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_7bc8

jmp_7c60:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_78a8
  ja jmp_7890

fn_7c78:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_7cd0
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_7cd0
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_7cd0
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_80b8

jmp_7cd0:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_7cf8

jmp_7ce0:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_7fd0

jmp_7cf8:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_7d80
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_7d80
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_7d80
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_7d88

jmp_7d80:
  mov64 r1, 0x1

jmp_7d88:
  jeq r1, 0x0, jmp_7ea0
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x68]
  ldxdw r2, [r10-0x70]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x48], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x58], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x60], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x40], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x38], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x30], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r4, r10
  add64 r4, -0x60
  call fn_be990
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_8000

jmp_7ea0:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_7f70
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x18], r1
  stxdw [r10-0x20], r2
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x20
  call fn_b1600
  ldxw r1, [r10-0x60]
  jne r1, 0x1, jmp_8020
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x50]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0
  ja jmp_8098

jmp_7f70:
  stxdw [r10-0x50], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x60], r1
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x60
  call fn_be7f0
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]
  ja jmp_8000

jmp_7fd0:
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xa0]
  ldxdw r2, [r10-0x98]

jmp_8000:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0

jmp_8018:
  exit

jmp_8020:
  ldxdw r1, [r10-0x48]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x8], r1
  ldxw r1, [r10-0x5c]
  ldxdw r2, [r10-0x58]
  ldxdw r3, [r10-0x50]
  stxdw [r6+0x14], r3
  stxdw [r6+0xc], r2
  stxw [r6+0x8], r1
  stxdw [r6+0x0], r7
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x1c], r1
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x24], r1

jmp_8098:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_8018

jmp_80b8:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_7cf8
  ja jmp_7ce0

fn_80d0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_8128
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_8128
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_8128
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_8560

jmp_8128:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_8150

jmp_8138:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_8428

jmp_8150:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_81d8
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_81d8
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_81d8
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_81e0

jmp_81d8:
  mov64 r1, 0x1

jmp_81e0:
  jeq r1, 0x0, jmp_82f8
  mov64 r1, r10
  add64 r1, -0x228
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x220]
  ldxdw r2, [r10-0x228]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x100], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x110], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0xf0], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0xe8], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0xe0], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r4, r10
  add64 r4, -0x110
  call fn_be990
  ldxdw r1, [r10-0x238]
  ldxdw r2, [r10-0x230]
  ja jmp_8458

jmp_82f8:
  ldxdw r1, [r7+0x10]
  mov64 r9, r1
  add64 r9, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_83c8
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x210], r1
  stxdw [r10-0x218], r2
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0x218
  call fn_54108
  ldxw r1, [r10-0x110]
  jne r1, 0x1, jmp_8478
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x100]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2
  ja jmp_8540

jmp_83c8:
  stxdw [r10-0x100], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, r10
  add64 r2, -0x110
  call fn_be7f0
  ldxdw r1, [r10-0x248]
  ldxdw r2, [r10-0x240]
  ja jmp_8458

jmp_8428:
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x258]
  ldxdw r2, [r10-0x250]

jmp_8458:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2

jmp_8470:
  exit

jmp_8478:
  ldxw r1, [r10-0x10c]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x268], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x270], r1
  mov64 r8, r10
  add64 r8, -0x208
  mov64 r2, r10
  add64 r2, -0xf8
  mov64 r1, r8
  mov64 r3, 0xf8
  call fn_d23d0
  ldxdw r1, [r10-0x270]
  stxdw [r6+0x14], r1
  ldxdw r1, [r10-0x268]
  stxdw [r6+0xc], r1
  ldxdw r1, [r10-0x260]
  stxw [r6+0x8], r1
  stxdw [r6+0x0], r7
  add64 r6, 0x1c
  mov64 r1, r6
  mov64 r2, r8
  mov64 r3, 0xf8
  call fn_d23d0

jmp_8540:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1
  ja jmp_8470

jmp_8560:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_8150
  ja jmp_8138

fn_8578:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_85d0
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_85d0
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_85d0
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_89e0

jmp_85d0:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_85f8

jmp_85e0:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_88d0

jmp_85f8:
  ldxdw r1, [r8+0x0]
  lddw r2, -0x6c5e9a281e0922fa
  jne r1, r2, jmp_8680
  ldxdw r1, [r8+0x8]
  lddw r2, -0x53861431b91e3427
  jne r1, r2, jmp_8680
  ldxdw r1, [r8+0x10]
  lddw r2, -0x6ec8a4a0127a4be4
  jne r1, r2, jmp_8680
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x56ff00817a0a73c6
  jeq r2, r3, jmp_8688

jmp_8680:
  mov64 r1, 0x1

jmp_8688:
  jeq r1, 0x0, jmp_87a0
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x70]
  ldxdw r2, [r10-0x78]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x40], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x48], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x58], r1
  lddw r1, -0x6c5e9a281e0922fa
  stxdw [r10-0x38], r1
  lddw r1, -0x53861431b91e3427
  stxdw [r10-0x30], r1
  lddw r1, -0x6ec8a4a0127a4be4
  stxdw [r10-0x28], r1
  lddw r1, -0x56ff00817a0a73c6
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, r10
  add64 r4, -0x58
  call fn_be990
  ldxdw r1, [r10-0x88]
  ldxdw r2, [r10-0x80]
  ja jmp_8900

jmp_87a0:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_8870
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x60], r1
  stxdw [r10-0x68], r2
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r2, r10
  add64 r2, -0x68
  call fn_b94f0
  ldxw r9, [r10-0x58]
  jne r9, 0x2, jmp_8920
  ldxdw r1, [r10-0x50]
  ldxdw r2, [r10-0x48]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stw [r6+0x0], 0x2
  ja jmp_89c0

jmp_8870:
  stxdw [r10-0x48], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x58], r1
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r10
  add64 r2, -0x58
  call fn_be7f0
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0x90]
  ja jmp_8900

jmp_88d0:
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xa8]
  ldxdw r2, [r10-0xa0]

jmp_8900:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stw [r6+0x0], 0x2

jmp_8918:
  exit

jmp_8920:
  ldxw r1, [r10-0x54]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc0], r1
  mov64 r1, r6
  add64 r1, 0x18
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r3, 0x40
  call fn_d23d0
  stxdw [r6+0x58], r7
  ldxdw r1, [r10-0xc0]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0xb8]
  stxdw [r6+0x8], r1
  ldxdw r1, [r10-0xb0]
  stxw [r6+0x4], r1
  stxw [r6+0x0], r9

jmp_89c0:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_8918

jmp_89e0:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_85f8
  ja jmp_85e0

fn_89f8:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_8a50
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_8a50
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_8a50
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_8e50

jmp_8a50:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_8a78

jmp_8a60:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_8d60

jmp_8a78:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_8b00
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_8b00
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_8b00
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_8b08

jmp_8b00:
  mov64 r1, 0x1

jmp_8b08:
  jeq r1, 0x0, jmp_8c20
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x58]
  ldxdw r2, [r10-0x60]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x40], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x20], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x18], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x10], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]
  ja jmp_8d90

jmp_8c20:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_8d00
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x48], r1
  stxdw [r10-0x50], r2
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, r10
  add64 r2, -0x50
  call fn_57fe0
  ldxdw r2, [r10-0x30]
  ldxdw r1, [r10-0x38]
  ldxdw r3, [r10-0x40]
  lddw r4, -0x8000000000000000
  jne r3, r4, jmp_8dc0
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r4
  ja jmp_8e30

jmp_8d00:
  stxdw [r10-0x30], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, r10
  add64 r2, -0x40
  call fn_be7f0
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_8d90

jmp_8d60:
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x88]

jmp_8d90:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1

jmp_8db8:
  exit

jmp_8dc0:
  ldxdw r4, [r10-0x8]
  stxdw [r6+0x38], r4
  ldxdw r4, [r10-0x10]
  stxdw [r6+0x30], r4
  ldxdw r4, [r10-0x18]
  stxdw [r6+0x28], r4
  ldxdw r4, [r10-0x20]
  stxdw [r6+0x20], r4
  ldxdw r4, [r10-0x28]
  stxdw [r6+0x18], r4
  stxdw [r6+0x40], r7
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r3

jmp_8e30:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_8db8

jmp_8e50:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_8a78
  ja jmp_8a60

fn_8e68:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_8ec0
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_8ec0
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_8ec0
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_92f0

jmp_8ec0:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_8ee8

jmp_8ed0:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_91c0

jmp_8ee8:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_8f70
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_8f70
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_8f70
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_8f78

jmp_8f70:
  mov64 r1, 0x1

jmp_8f78:
  jeq r1, 0x0, jmp_9090
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0x190]
  ldxdw r2, [r10-0x198]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x160], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x168], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x170], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x178], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x158], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x150], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x148], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x140], r1
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r4, r10
  add64 r4, -0x178
  call fn_be990
  ldxdw r1, [r10-0x1a8]
  ldxdw r2, [r10-0x1a0]
  ja jmp_91f0

jmp_9090:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_9160
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x180], r1
  stxdw [r10-0x188], r2
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r10
  add64 r2, -0x188
  call fn_52d30
  ldxb r9, [r10-0x177]
  jne r9, 0x7, jmp_9210
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7
  ja jmp_92d0

jmp_9160:
  stxdw [r10-0x168], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r10
  add64 r2, -0x178
  call fn_be7f0
  ldxdw r1, [r10-0x1b8]
  ldxdw r2, [r10-0x1b0]
  ja jmp_91f0

jmp_91c0:
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0x1c8]
  ldxdw r2, [r10-0x1c0]

jmp_91f0:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7

jmp_9208:
  exit

jmp_9210:
  ldxb r1, [r10-0x178]
  stxdw [r10-0x1d0], r1
  ldxh r1, [r10-0x172]
  stxh [r6+0x6], r1
  ldxw r1, [r10-0x176]
  stxw [r6+0x2], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x1d8], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x1e0], r1
  mov64 r1, r6
  add64 r1, 0x18
  mov64 r2, r10
  add64 r2, -0x160
  mov64 r3, 0x160
  call fn_d23d0
  stxdw [r6+0x178], r7
  ldxdw r1, [r10-0x1e0]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r6+0x8], r1
  stxb [r6+0x1], r9
  ldxdw r1, [r10-0x1d0]
  stxb [r6+0x0], r1

jmp_92d0:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_9208

jmp_92f0:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_8ee8
  ja jmp_8ed0

fn_9308:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x18]
  ldxdw r1, [r8+0x0]
  jne r1, 0x0, jmp_9360
  ldxdw r1, [r8+0x8]
  jne r1, 0x0, jmp_9360
  ldxdw r1, [r8+0x10]
  jne r1, 0x0, jmp_9360
  ldxdw r1, [r8+0x18]
  jeq r1, 0x0, jmp_9740

jmp_9360:
  mov64 r1, 0x1
  jne r1, 0x0, jmp_9388

jmp_9370:
  mov64 r1, r7
  call fn_c47d0
  jeq r0, 0x0, jmp_9660

jmp_9388:
  ldxdw r1, [r8+0x0]
  lddw r2, 0x5f9ff80ea6de9204
  jne r1, r2, jmp_9410
  ldxdw r1, [r8+0x8]
  lddw r2, 0x306871741f975c4a
  jne r1, r2, jmp_9410
  ldxdw r1, [r8+0x10]
  lddw r2, -0x7ec0aad0512fff5d
  jne r1, r2, jmp_9410
  mov64 r1, 0x0
  ldxdw r2, [r8+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r2, r3, jmp_9418

jmp_9410:
  mov64 r1, 0x1

jmp_9418:
  jeq r1, 0x0, jmp_9530
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, 0xbbf
  call fn_c1978
  ldxdw r3, [r10-0xb8]
  ldxdw r2, [r10-0xc0]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x88], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x90], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x98], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0xa0], r1
  lddw r1, 0x5f9ff80ea6de9204
  stxdw [r10-0x80], r1
  lddw r1, 0x306871741f975c4a
  stxdw [r10-0x78], r1
  lddw r1, -0x7ec0aad0512fff5d
  stxdw [r10-0x70], r1
  lddw r1, -0x4886a17a3ed6b36e
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r4, r10
  add64 r4, -0xa0
  call fn_be990
  ldxdw r1, [r10-0xd0]
  ldxdw r2, [r10-0xc8]
  ja jmp_9690

jmp_9530:
  ldxdw r1, [r7+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_9600
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0xa8], r1
  stxdw [r10-0xb0], r2
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r10
  add64 r2, -0xb0
  call fn_57100
  ldxdw r2, [r10-0x98]
  ldxdw r1, [r10-0xa0]
  ldxb r9, [r10-0x1]
  jne r9, 0x2, jmp_96b0
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0xa7], 0x2
  ja jmp_9720

jmp_9600:
  stxdw [r10-0x90], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xa0], r1
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be7f0
  ldxdw r1, [r10-0xe0]
  ldxdw r2, [r10-0xd8]
  ja jmp_9690

jmp_9660:
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, 0xbc4
  call fn_c1978
  ldxdw r1, [r10-0xf0]
  ldxdw r2, [r10-0xe8]

jmp_9690:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0xa7], 0x2

jmp_96a8:
  exit

jmp_96b0:
  stxdw [r10-0xf8], r1
  mov64 r1, r6
  add64 r1, 0x18
  stxdw [r10-0x100], r2
  mov64 r2, r10
  add64 r2, -0x90
  mov64 r3, 0x8f
  call fn_d23d0
  stxb [r6+0xa7], r9
  ldxdw r1, [r10-0x100]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r7

jmp_9720:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_96a8

jmp_9740:
  mov64 r1, 0x0
  jne r1, 0x0, jmp_9388
  ja jmp_9370

fn_9758:
  mov64 r3, r2
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x10]
  ldxdw r1, [r1+0x8]
  call fn_cead0
  exit

fn_9788:
  mov64 r1, r2
  lddw r2, str_12ed
  mov64 r3, 0x2
  call fn_ce058
  exit

fn_97b8:
  ldxdw r1, [r1+0x0]
  ldxw r3, [r2+0x10]
  mov64 r4, r3
  and64 r4, 0x2000000
  jne r4, 0x0, jmp_9800
  and64 r3, 0x4000000
  jne r3, 0x0, jmp_9810
  call fn_d14b8
  ja jmp_9818

jmp_9800:
  call fn_d0c18
  ja jmp_9818

jmp_9810:
  call fn_d0d48

jmp_9818:
  exit
  ldxdw r1, [r1+0x0]
  call fn_cc360
  exit

fn_9838:
  mov64 r3, r2
  mov64 r6, r1
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r3
  call fn_5a268
  jne r0, 0x0, jmp_9908
  ldxdw r1, [r10-0x28]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x30]
  stxdw [r6+0x8], r1
  ldxdw r1, [r10-0x38]
  stxdw [r6+0x0], r1
  exit

jmp_9908:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8
  ldxw r3, [r2+0x10]
  mov64 r4, r3
  and64 r4, 0x2000000
  jne r4, 0x0, jmp_9998
  and64 r3, 0x4000000
  jne r3, 0x0, jmp_99a8
  call fn_d1338
  ja jmp_99b0

jmp_9998:
  call fn_d09c8
  ja jmp_99b0

jmp_99a8:
  call fn_d0af0

jmp_99b0:
  exit

fn_99b8:
  mov64 r3, r2
  lddw r2, data_5df8
  call fn_cd5c0
  exit

fn_99e0:
  call fn_cd5c0
  exit

fn_99f0:
  mov64 r3, r2
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jeq r2, 0x0, jmp_9c20
  mov64 r2, 0x1
  mov64 r4, r3
  and64 r4, 0x1
  jeq r4, 0x0, jmp_9a60
  mov64 r6, 0x1
  mov64 r2, 0xa
  mov64 r4, r3
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jeq r4, 0x1, jmp_9c40

jmp_9a60:
  mov64 r4, r3
  and64 r4, 0x2
  jeq r4, 0x0, jmp_9ab0
  lddw r4, 0xfffffffe
  mov64 r5, r3
  and64 r5, r4
  mov64 r6, 0x1
  mul64 r2, 0x64
  jeq r5, 0x2, jmp_9c40

jmp_9ab0:
  mov64 r4, r3
  and64 r4, 0x4
  jeq r4, 0x0, jmp_9b00
  lddw r4, 0xfffffffc
  mov64 r5, r3
  and64 r5, r4
  mov64 r6, 0x1
  mul64 r2, 0x2710
  jeq r5, 0x4, jmp_9c40

jmp_9b00:
  mov64 r4, r3
  and64 r4, 0x8
  jeq r4, 0x0, jmp_9b50
  lddw r4, 0xfffffff8
  mov64 r5, r3
  and64 r5, r4
  mov64 r6, 0x1
  mul64 r2, 0x5f5e100
  jeq r5, 0x8, jmp_9c40

jmp_9b50:
  mov64 r4, r3
  and64 r4, 0x10
  jeq r4, 0x0, jmp_9c38
  mov64 r8, r3
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r6, 0x0
  mov64 r3, 0x0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x8]
  jne r2, 0x0, jmp_9bd8
  mov64 r1, 0x0

jmp_9bd8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_9c58
  lddw r1, 0xfffffff0
  and64 r8, r1
  mov64 r1, r7
  jne r8, 0x10, jmp_9c38
  ldxdw r2, [r10-0x10]
  ja jmp_9c28

jmp_9c20:
  mov64 r2, 0x1

jmp_9c28:
  mov64 r6, 0x1
  ja jmp_9c40

jmp_9c38:
  mov64 r6, 0x0

jmp_9c40:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r6
  exit

jmp_9c58:
  mov64 r1, r7
  ja jmp_9c40

fn_9c68:
  exit

fn_9c70:
  ldxdw r1, [r1+0x0]
  mov64 r2, r1
  and64 r2, 0x3
  mov64 r3, r2
  add64 r3, -0x2
  jlt r3, 0x2, jmp_9cd0
  jeq r2, 0x0, jmp_9cd0
  ldxdw r2, [r1+0x7]
  ldxdw r2, [r2+0x0]
  jeq r2, 0x0, jmp_9cd0
  ldxdw r1, [r1-0x1]
  callx r2

jmp_9cd0:
  exit

fn_9cd8:
  jeq r1, 0x0, jmp_9cf8
  ldxdw r1, [r2+0x0]
  ldxb r1, [r2+0x38]
  ja jmp_9d00

jmp_9cf8:
  ldxdw r1, [r2+0x0]

jmp_9d00:
  exit

fn_9d08:
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r2+0x0]
  add64 r3, -0x1
  stxdw [r2+0x0], r3
  jne r3, 0x0, jmp_9d60
  mov64 r2, r1
  add64 r2, 0x8
  mov64 r6, r1
  mov64 r1, r2
  call fn_c25c0
  mov64 r1, r6

jmp_9d60:
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r2+0x0]
  add64 r3, -0x1
  stxdw [r2+0x0], r3
  jne r3, 0x0, jmp_9d98
  add64 r1, 0x10
  call fn_c2610

jmp_9d98:
  exit

fn_9da0:
  exit

fn_9da8:
  mov64 r6, r1
  ldxdw r1, [r6+0xc0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9df0
  mov64 r1, r6
  add64 r1, 0xc0
  call fn_c25c0

jmp_9df0:
  ldxdw r1, [r6+0xc8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9e30
  mov64 r1, r6
  add64 r1, 0xc8
  call fn_c2610

jmp_9e30:
  ldxdw r1, [r6+0xf0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9e70
  mov64 r1, r6
  add64 r1, 0xf0
  call fn_c25c0

jmp_9e70:
  ldxdw r1, [r6+0xf8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9eb0
  mov64 r1, r6
  add64 r1, 0xf8
  call fn_c2610

jmp_9eb0:
  ldxdw r1, [r6+0x120]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9ef0
  mov64 r1, r6
  add64 r1, 0x120
  call fn_c25c0

jmp_9ef0:
  ldxdw r1, [r6+0x128]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9f30
  mov64 r1, r6
  add64 r1, 0x128
  call fn_c2610

jmp_9f30:
  ldxdw r1, [r6+0x150]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9f70
  mov64 r1, r6
  add64 r1, 0x150
  call fn_c25c0

jmp_9f70:
  ldxdw r1, [r6+0x158]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_9fb0
  add64 r6, 0x158
  mov64 r1, r6
  call fn_c2610

jmp_9fb0:
  exit

fn_9fb8:
  mov64 r6, r1
  ldxdw r1, [r6+0xc0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a000
  mov64 r1, r6
  add64 r1, 0xc0
  call fn_c25c0

jmp_a000:
  ldxdw r1, [r6+0xc8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a040
  mov64 r1, r6
  add64 r1, 0xc8
  call fn_c2610

jmp_a040:
  ldxdw r1, [r6+0xf0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a080
  mov64 r1, r6
  add64 r1, 0xf0
  call fn_c25c0

jmp_a080:
  ldxdw r1, [r6+0xf8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a0c0
  mov64 r1, r6
  add64 r1, 0xf8
  call fn_c2610

jmp_a0c0:
  ldxdw r1, [r6+0x120]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a100
  mov64 r1, r6
  add64 r1, 0x120
  call fn_c25c0

jmp_a100:
  ldxdw r1, [r6+0x128]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a140
  add64 r6, 0x128
  mov64 r1, r6
  call fn_c2610

jmp_a140:
  exit

fn_a148:
  mov64 r6, r1
  ldxdw r1, [r6+0xc0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a190
  mov64 r1, r6
  add64 r1, 0xc0
  call fn_c25c0

jmp_a190:
  ldxdw r1, [r6+0xc8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a1d0
  mov64 r1, r6
  add64 r1, 0xc8
  call fn_c2610

jmp_a1d0:
  ldxdw r1, [r6+0xf0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a210
  mov64 r1, r6
  add64 r1, 0xf0
  call fn_c25c0

jmp_a210:
  ldxdw r1, [r6+0xf8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a250
  add64 r6, 0xf8
  mov64 r1, r6
  call fn_c2610

jmp_a250:
  exit

fn_a258:
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r2+0x0]
  add64 r3, -0x1
  stxdw [r2+0x0], r3
  jne r3, 0x0, jmp_a2b0
  mov64 r2, r1
  add64 r2, 0x8
  mov64 r6, r1
  mov64 r1, r2
  call fn_c25c0
  mov64 r1, r6

jmp_a2b0:
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r2+0x0]
  add64 r3, -0x1
  stxdw [r2+0x0], r3
  jne r3, 0x0, jmp_a2e8
  add64 r1, 0x10
  call fn_c2610

jmp_a2e8:
  exit

fn_a2f0:
  mov64 r6, r1
  ldxdw r1, [r6+0x8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a338
  mov64 r1, r6
  add64 r1, 0x8
  call fn_c25c0

jmp_a338:
  ldxdw r1, [r6+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a378
  mov64 r1, r6
  add64 r1, 0x10
  call fn_c2610

jmp_a378:
  ldxdw r1, [r6+0x38]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a3b8
  mov64 r1, r6
  add64 r1, 0x38
  call fn_c25c0

jmp_a3b8:
  ldxdw r1, [r6+0x40]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a3f8
  mov64 r1, r6
  add64 r1, 0x40
  call fn_c2610

jmp_a3f8:
  ldxdw r1, [r6+0x68]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a438
  mov64 r1, r6
  add64 r1, 0x68
  call fn_c25c0

jmp_a438:
  ldxdw r1, [r6+0x70]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a478
  add64 r6, 0x70
  mov64 r1, r6
  call fn_c2610

jmp_a478:
  exit

fn_a480:
  mov64 r6, r1
  ldxdw r1, [r6+0x8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a4c8
  mov64 r1, r6
  add64 r1, 0x8
  call fn_c25c0

jmp_a4c8:
  ldxdw r1, [r6+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a508
  mov64 r1, r6
  add64 r1, 0x10
  call fn_c2610

jmp_a508:
  ldxdw r1, [r6+0x38]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a548
  mov64 r1, r6
  add64 r1, 0x38
  call fn_c25c0

jmp_a548:
  ldxdw r1, [r6+0x40]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a588
  mov64 r1, r6
  add64 r1, 0x40
  call fn_c2610

jmp_a588:
  ldxdw r1, [r6+0x68]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a5c8
  mov64 r1, r6
  add64 r1, 0x68
  call fn_c25c0

jmp_a5c8:
  ldxdw r1, [r6+0x70]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a608
  mov64 r1, r6
  add64 r1, 0x70
  call fn_c2610

jmp_a608:
  ldxdw r1, [r6+0x98]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a648
  mov64 r1, r6
  add64 r1, 0x98
  call fn_c25c0

jmp_a648:
  ldxdw r1, [r6+0xa0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a688
  add64 r6, 0xa0
  mov64 r1, r6
  call fn_c2610

jmp_a688:
  exit

fn_a690:
  mov64 r6, r1
  ldxdw r1, [r6+0x8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a6d8
  mov64 r1, r6
  add64 r1, 0x8
  call fn_c25c0

jmp_a6d8:
  ldxdw r1, [r6+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a718
  mov64 r1, r6
  add64 r1, 0x10
  call fn_c2610

jmp_a718:
  ldxdw r1, [r6+0x38]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a758
  mov64 r1, r6
  add64 r1, 0x38
  call fn_c25c0

jmp_a758:
  ldxdw r1, [r6+0x40]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a798
  mov64 r1, r6
  add64 r1, 0x40
  call fn_c2610

jmp_a798:
  ldxdw r1, [r6+0x68]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a7d8
  mov64 r1, r6
  add64 r1, 0x68
  call fn_c25c0

jmp_a7d8:
  ldxdw r1, [r6+0x70]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a818
  mov64 r1, r6
  add64 r1, 0x70
  call fn_c2610

jmp_a818:
  ldxdw r1, [r6+0x98]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a858
  mov64 r1, r6
  add64 r1, 0x98
  call fn_c25c0

jmp_a858:
  ldxdw r1, [r6+0xa0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a898
  mov64 r1, r6
  add64 r1, 0xa0
  call fn_c2610

jmp_a898:
  ldxdw r1, [r6+0xc8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a8d8
  mov64 r1, r6
  add64 r1, 0xc8
  call fn_c25c0

jmp_a8d8:
  ldxdw r1, [r6+0xd0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a918
  mov64 r1, r6
  add64 r1, 0xd0
  call fn_c2610

jmp_a918:
  ldxdw r1, [r6+0xf8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a958
  mov64 r1, r6
  add64 r1, 0xf8
  call fn_c25c0

jmp_a958:
  ldxdw r1, [r6+0x100]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a998
  mov64 r1, r6
  add64 r1, 0x100
  call fn_c2610

jmp_a998:
  ldxdw r1, [r6+0x128]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_a9d8
  mov64 r1, r6
  add64 r1, 0x128
  call fn_c25c0

jmp_a9d8:
  ldxdw r1, [r6+0x130]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_aa18
  add64 r6, 0x130
  mov64 r1, r6
  call fn_c2610

jmp_aa18:
  exit

fn_aa20:
  mov64 r6, r1
  ldxdw r1, [r6+0x50]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_aa68
  mov64 r1, r6
  add64 r1, 0x50
  call fn_c25c0

jmp_aa68:
  ldxdw r1, [r6+0x58]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_aaa8
  mov64 r1, r6
  add64 r1, 0x58
  call fn_c2610

jmp_aaa8:
  ldxdw r1, [r6+0x80]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_aae8
  mov64 r1, r6
  add64 r1, 0x80
  call fn_c25c0

jmp_aae8:
  ldxdw r1, [r6+0x88]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_ab28
  add64 r6, 0x88
  mov64 r1, r6
  call fn_c2610

jmp_ab28:
  exit

fn_ab30:
  mov64 r6, r1
  ldxdw r1, [r6+0x98]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_ab78
  mov64 r1, r6
  add64 r1, 0x98
  call fn_c25c0

jmp_ab78:
  ldxdw r1, [r6+0xa0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_abb8
  mov64 r1, r6
  add64 r1, 0xa0
  call fn_c2610

jmp_abb8:
  ldxdw r1, [r6+0xc8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_abf8
  mov64 r1, r6
  add64 r1, 0xc8
  call fn_c25c0

jmp_abf8:
  ldxdw r1, [r6+0xd0]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_ac38
  add64 r6, 0xd0
  mov64 r1, r6
  call fn_c2610

jmp_ac38:
  exit

fn_ac40:
  ldxdw r2, [r1+0x0]
  jeq r2, 0x0, jmp_ae08
  ldxdw r3, [r1+0x8]
  ldxdw r1, [r1+0x10]
  jeq r1, 0x0, jmp_add0
  mov64 r4, 0x0
  ja jmp_aca0

jmp_ac78:
  mov64 r3, r5
  mov64 r4, r0
  add64 r1, -0x1
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_adf8

jmp_aca0:
  jeq r4, 0x0, jmp_ace0
  mov64 r5, r3
  mov64 r3, r2
  mov64 r2, r4
  ldxh r4, [r2+0x16a]
  jge r5, r4, jmp_ad20

jmp_acd0:
  mov64 r0, r2
  ja jmp_ad58

jmp_ace0:
  mov64 r5, 0x0
  jeq r3, 0x0, jmp_ad08

jmp_acf0:
  ldxdw r2, [r2+0x170]
  add64 r3, -0x1
  jne r3, 0x0, jmp_acf0

jmp_ad08:
  mov64 r3, 0x0
  ldxh r4, [r2+0x16a]
  jlt r5, r4, jmp_acd0

jmp_ad20:
  ldxdw r0, [r2+0x160]
  jeq r0, 0x0, jmp_ae10
  add64 r3, 0x1
  ldxh r5, [r2+0x168]
  ldxh r4, [r0+0x16a]
  mov64 r2, r0
  jge r5, r4, jmp_ad20

jmp_ad58:
  add64 r5, 0x1
  jeq r3, 0x0, jmp_ac78
  lsh64 r5, 0x3
  add64 r0, r5
  add64 r0, 0x170

jmp_ad80:
  ldxdw r4, [r0+0x0]
  mov64 r0, r4
  add64 r0, 0x170
  add64 r3, -0x1
  jne r3, 0x0, jmp_ad80
  mov64 r3, 0x0
  add64 r1, -0x1
  mov64 r2, 0x0
  jne r1, 0x0, jmp_aca0
  ja jmp_adf8

jmp_add0:
  mov64 r4, r2
  jeq r3, 0x0, jmp_adf8

jmp_ade0:
  ldxdw r4, [r4+0x170]
  add64 r3, -0x1
  jne r3, 0x0, jmp_ade0

jmp_adf8:
  ldxdw r4, [r4+0x160]
  jne r4, 0x0, jmp_adf8

jmp_ae08:
  exit

jmp_ae10:
  lddw r1, data_5ee8
  call fn_cc290

fn_ae28:
  mov64 r0, 0x0
  ldxdw r4, [r1+0x0]
  ldxdw r5, [r1+0x8]
  stxdw [r10-0x8], r5
  jge r4, r5, jmp_b050
  stxdw [r10-0x18], r1
  mov64 r0, r4
  mul64 r0, 0x4c
  stxdw [r10-0x10], r3
  add64 r0, r3
  add64 r0, 0x4c
  mov64 r6, r4
  ja jmp_aeb0

jmp_ae90:
  add64 r0, 0x4c
  mov64 r4, r6
  ldxdw r1, [r10-0x8]
  jge r6, r1, jmp_b058

jmp_aeb0:
  add64 r6, 0x1
  jge r6, r2, jmp_ae90
  jgt r4, 0x2, jmp_b0a8
  mul64 r4, 0x4c
  ldxdw r7, [r10-0x10]
  add64 r7, r4
  mov64 r4, r7
  add64 r4, 0x48
  mov64 r8, r0
  mov64 r9, r6
  ja jmp_af38

jmp_af08:
  ldxb r1, [r8+0x48]
  ldxb r3, [r4+0x0]
  jne r3, r1, jmp_b038

jmp_af20:
  add64 r9, 0x1
  add64 r8, 0x4c
  jge r9, r2, jmp_ae90

jmp_af38:
  jgt r9, 0x2, jmp_b070
  ldxdw r5, [r8+0x0]
  ldxdw r3, [r7+0x0]
  jne r3, r5, jmp_afa8
  ldxdw r3, [r8+0x8]
  ldxdw r5, [r7+0x8]
  jne r5, r3, jmp_afa8
  ldxdw r3, [r8+0x10]
  ldxdw r5, [r7+0x10]
  jne r5, r3, jmp_afa8
  mov64 r5, 0x0
  ldxdw r3, [r8+0x18]
  ldxdw r1, [r7+0x18]
  jeq r1, r3, jmp_afb0

jmp_afa8:
  mov64 r5, 0x1

jmp_afb0:
  jeq r5, 0x0, jmp_af08
  ldxdw r1, [r8+0x20]
  ldxdw r3, [r7+0x20]
  jne r3, r1, jmp_b020
  ldxdw r1, [r8+0x28]
  ldxdw r3, [r7+0x28]
  jne r3, r1, jmp_b020
  ldxdw r1, [r8+0x30]
  ldxdw r3, [r7+0x30]
  jne r3, r1, jmp_b020
  mov64 r5, 0x0
  ldxdw r1, [r8+0x38]
  ldxdw r3, [r7+0x38]
  jeq r3, r1, jmp_b028

jmp_b020:
  mov64 r5, 0x1

jmp_b028:
  jne r5, 0x0, jmp_af20
  ja jmp_af08

jmp_b038:
  mov64 r0, 0x1

jmp_b040:
  ldxdw r1, [r10-0x18]
  stxdw [r1+0x0], r6

jmp_b050:
  exit

jmp_b058:
  mov64 r0, 0x0
  ldxdw r6, [r10-0x8]
  ja jmp_b040

jmp_b070:
  ldxdw r1, [r10-0x18]
  stxdw [r1+0x0], r6
  mov64 r1, 0x3
  mov64 r2, 0x3
  lddw r3, data_67a0
  call fn_cc630

jmp_b0a8:
  ldxdw r1, [r10-0x18]
  stxdw [r1+0x0], r6
  mov64 r1, r4
  mov64 r2, 0x3
  lddw r3, data_6788
  call fn_cc630

fn_b0e0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x0]
  ldxdw r2, [r7+0x8]
  jeq r2, 0x0, jmp_b160
  add64 r2, -0x1
  ldxb r1, [r8+0x0]
  stxdw [r7+0x8], r2
  add64 r8, 0x1
  stxdw [r7+0x0], r8
  stxb [r10-0x59], r1
  jeq r1, 0x1, jmp_b188
  jne r1, 0x0, jmp_b1a0
  stb [r6+0x1], 0x0
  mov64 r1, 0x0
  ja jmp_b270

jmp_b160:
  lddw r1, data_5dc8
  call fn_c9c58
  stxdw [r7+0x0], r8
  ja jmp_b260

jmp_b188:
  stb [r6+0x1], 0x1
  mov64 r1, 0x0
  ja jmp_b270

jmp_b1a0:
  lddw r1, data_5ec0
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x10
  stxdw [r10-0x30], r1
  lddw r1, 0x18aef
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x59
  stxdw [r10-0x10], r1
  stdw [r10-0x20], 0x0
  stdw [r10-0x38], 0x1
  stdw [r10-0x28], 0x1
  mov64 r7, r10
  add64 r7, -0x58
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r1, r7
  call fn_cb0f0
  mov64 r1, 0x14
  mov64 r2, r7
  call fn_bc4f8

jmp_b260:
  stxdw [r6+0x8], r0
  mov64 r1, 0x1

jmp_b270:
  stxb [r6+0x0], r1
  exit

fn_b280:
  mov64 r1, r2
  lddw r2, str_135d
  mov64 r3, 0x5
  call fn_ce550
  exit

fn_b2b0:
  mov64 r7, 0x1
  ldxdw r6, [r1+0x10]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r3, 0x80, jmp_b320
  mov64 r7, 0x2
  jlt r3, 0x800, jmp_b320
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  mov64 r7, 0x3
  jlt r3, 0x10000, jmp_b320
  mov64 r7, 0x4

jmp_b320:
  ldxdw r3, [r1+0x0]
  sub64 r3, r6
  mov64 r4, r6
  jgt r7, r3, jmp_b4e0

jmp_b340:
  ldxdw r3, [r1+0x8]
  add64 r3, r4
  mov64 r4, r2
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jge r4, 0x80, jmp_b380
  stxb [r3+0x0], r2
  ja jmp_b4c0

jmp_b380:
  jge r4, 0x800, jmp_b3c8
  mov64 r4, r2
  and64 r4, 0x3f
  or64 r4, 0x80
  stxb [r3+0x1], r4
  rsh64 r2, 0x6
  or64 r2, 0xc0
  stxb [r3+0x0], r2
  ja jmp_b4c0

jmp_b3c8:
  mov64 r4, r2
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jge r4, 0x10000, jmp_b438
  mov64 r4, r2
  and64 r4, 0x3f
  or64 r4, 0x80
  stxb [r3+0x2], r4
  mov64 r4, r2
  rsh64 r4, 0xc
  or64 r4, 0xe0
  stxb [r3+0x0], r4
  rsh64 r2, 0x6
  ja jmp_b4a8

jmp_b438:
  mov64 r4, r2
  and64 r4, 0x3f
  or64 r4, 0x80
  stxb [r3+0x3], r4
  mov64 r4, r2
  rsh64 r4, 0x12
  or64 r4, 0xf0
  stxb [r3+0x0], r4
  mov64 r4, r2
  rsh64 r4, 0x6
  and64 r4, 0x3f
  or64 r4, 0x80
  stxb [r3+0x2], r4
  rsh64 r2, 0xc

jmp_b4a8:
  and64 r2, 0x3f
  or64 r2, 0x80
  stxb [r3+0x1], r2

jmp_b4c0:
  add64 r7, r6
  stxdw [r1+0x10], r7
  mov64 r0, 0x0
  exit

jmp_b4e0:
  mov64 r8, r1
  mov64 r9, r2
  mov64 r2, r6
  mov64 r3, r7
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r2, r9
  mov64 r1, r8
  ldxdw r4, [r1+0x10]
  ja jmp_b340

fn_b538:
  mov64 r6, r3
  mov64 r7, r1
  ldxdw r8, [r7+0x10]
  ldxdw r1, [r7+0x0]
  sub64 r1, r8
  jgt r6, r1, jmp_b5a8

jmp_b568:
  ldxdw r1, [r7+0x8]
  add64 r1, r8
  mov64 r3, r6
  call fn_d23d0
  add64 r8, r6
  stxdw [r7+0x10], r8
  mov64 r0, 0x0
  exit

jmp_b5a8:
  mov64 r1, r7
  mov64 r9, r2
  mov64 r2, r8
  mov64 r3, r6
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r2, r9
  ldxdw r8, [r7+0x10]
  ja jmp_b568

fn_b5f8:
  mov64 r8, r3
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r1, [r4+0x8]
  jeq r1, 0x0, jmp_b738
  ldxdw r3, [r4+0x10]
  jeq r3, 0x0, jmp_b738
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r5, 0x300008000
  jeq r1, 0x0, jmp_b668
  mov64 r5, r1

jmp_b668:
  mov64 r2, r5
  sub64 r2, r8
  mov64 r1, 0x0
  mov64 r0, 0x1
  jgt r2, r5, jmp_b698
  mov64 r0, 0x0

jmp_b698:
  mov64 r9, 0x0
  jne r0, 0x0, jmp_b6b0
  mov64 r9, r2

jmp_b6b0:
  mov64 r2, r7
  neg64 r2
  and64 r9, r2
  lddw r2, 0x300000008
  jlt r9, r2, jmp_b818
  ldxdw r2, [r4+0x0]
  lddw r1, 0x300000000
  stxdw [r1+0x0], r9
  mov64 r1, r9
  call fn_d23d0
  mov64 r1, r9
  stxdw [r6+0x10], r8
  mov64 r2, 0x1
  jne r1, 0x0, jmp_b830
  ja jmp_b838

jmp_b738:
  jeq r8, 0x0, jmp_b860
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_b780
  mov64 r2, r1

jmp_b780:
  mov64 r3, r2
  sub64 r3, r8
  mov64 r1, 0x0
  mov64 r4, 0x1
  jgt r3, r2, jmp_b7b0
  mov64 r4, 0x0

jmp_b7b0:
  mov64 r2, 0x0
  jne r4, 0x0, jmp_b7c8
  mov64 r2, r3

jmp_b7c8:
  mov64 r3, r7
  neg64 r3
  and64 r2, r3
  lddw r3, 0x300000008
  jlt r2, r3, jmp_b818
  lddw r1, 0x300000000
  stxdw [r1+0x0], r2
  mov64 r1, r2

jmp_b818:
  stxdw [r6+0x10], r8
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_b838

jmp_b830:
  mov64 r2, 0x0

jmp_b838:
  jeq r1, 0x0, jmp_b848
  mov64 r7, r1

jmp_b848:
  stxdw [r6+0x8], r7
  stxdw [r6+0x0], r2
  exit

jmp_b860:
  mov64 r1, r7
  stxdw [r6+0x10], r8
  mov64 r2, 0x1
  jne r1, 0x0, jmp_b830
  ja jmp_b838

fn_b888:
  stxdw [r10-0x48], r2
  mov64 r7, r1
  ldxdw r6, [r7+0x0]
  mov64 r8, r6
  lsh64 r8, 0x1
  jgt r8, 0x4, jmp_b8c0
  mov64 r8, 0x4

jmp_b8c0:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r9, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x18
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_b920
  mov64 r1, 0x0

jmp_b920:
  and64 r1, 0x1
  jne r1, 0x0, jmp_b968
  ldxdw r3, [r10-0x40]
  lddw r1, 0x7ffffffffffffff8
  jle r3, r1, jmp_b980
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_b968:
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_b980:
  mov64 r1, 0x0
  jeq r6, 0x0, jmp_b9b8
  ldxdw r1, [r7+0x8]
  mul64 r6, 0x18
  stxdw [r10-0x8], r6
  stxdw [r10-0x18], r1
  mov64 r1, 0x8

jmp_b9b8:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x8
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_ba20
  ldxdw r1, [r10-0x28]
  stxdw [r7+0x0], r8
  stxdw [r7+0x8], r1
  exit

jmp_ba20:
  ldxdw r2, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

fn_ba48:
  mov64 r6, r2
  ldxdw r5, [r1+0x0]
  mov64 r7, r5
  lsh64 r7, 0x1
  jgt r7, 0x4, jmp_ba78
  mov64 r7, 0x4

jmp_ba78:
  mov64 r4, 0x0
  lddw r2, 0x3ffffffffffffff
  jgt r5, r2, jmp_bac8
  mov64 r3, r7
  lsh64 r3, 0x5
  jsge r3, 0x0, jmp_bae0
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

jmp_bac8:
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

jmp_bae0:
  mov64 r2, 0x0
  jeq r5, 0x0, jmp_bb18
  ldxdw r2, [r1+0x8]
  lsh64 r5, 0x5
  stxdw [r10-0x8], r5
  stxdw [r10-0x18], r2
  mov64 r2, 0x1

jmp_bb18:
  mov64 r8, r1
  stxdw [r10-0x10], r2
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x1
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_bb88
  ldxdw r1, [r10-0x28]
  stxdw [r8+0x0], r7
  stxdw [r8+0x8], r1
  exit

jmp_bb88:
  ldxdw r2, [r10-0x20]
  ldxdw r4, [r10-0x28]
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

fn_bbb0:
  mov64 r6, r2
  ldxdw r2, [r1+0x0]
  mov64 r7, r2
  lsh64 r7, 0x1
  jgt r7, 0x8, jmp_bbe0
  mov64 r7, 0x8

jmp_bbe0:
  jsge r7, 0x0, jmp_bc00
  mov64 r1, 0x0
  mov64 r3, r6
  call fn_cb038

jmp_bc00:
  mov64 r3, 0x0
  jeq r2, 0x0, jmp_bc30
  ldxdw r3, [r1+0x8]
  stxdw [r10-0x8], r2
  stxdw [r10-0x18], r3
  mov64 r3, 0x1

jmp_bc30:
  mov64 r8, r1
  stxdw [r10-0x10], r3
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x1
  mov64 r3, r7
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_bca8
  ldxdw r1, [r10-0x28]
  stxdw [r8+0x0], r7
  stxdw [r8+0x8], r1
  exit

jmp_bca8:
  ldxdw r2, [r10-0x20]
  ldxdw r1, [r10-0x28]
  mov64 r3, r6
  call fn_cb038

fn_bcc8:
  mov64 r6, r2
  ldxdw r5, [r1+0x0]
  mov64 r7, r5
  lsh64 r7, 0x1
  jgt r7, 0x4, jmp_bcf8
  mov64 r7, 0x4

jmp_bcf8:
  mov64 r4, 0x0
  lddw r2, 0x3ffffffffffffff
  jgt r5, r2, jmp_bd58
  mov64 r3, r7
  lsh64 r3, 0x5
  lddw r0, 0x7ffffffffffffff8
  jle r3, r0, jmp_bd70
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

jmp_bd58:
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

jmp_bd70:
  mov64 r2, 0x0
  jeq r5, 0x0, jmp_bda8
  ldxdw r2, [r1+0x8]
  lsh64 r5, 0x5
  stxdw [r10-0x8], r5
  stxdw [r10-0x18], r2
  mov64 r2, 0x8

jmp_bda8:
  mov64 r8, r1
  stxdw [r10-0x10], r2
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x8
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_be18
  ldxdw r1, [r10-0x28]
  stxdw [r8+0x0], r7
  stxdw [r8+0x8], r1
  exit

jmp_be18:
  ldxdw r2, [r10-0x20]
  ldxdw r4, [r10-0x28]
  mov64 r1, r4
  mov64 r3, r6
  call fn_cb038

fn_be40:
  stxdw [r10-0x48], r2
  mov64 r7, r1
  ldxdw r6, [r7+0x0]
  mov64 r8, r6
  lsh64 r8, 0x1
  jgt r8, 0x4, jmp_be78
  mov64 r8, 0x4

jmp_be78:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r9, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0xd0
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_bed8
  mov64 r1, 0x0

jmp_bed8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_bf20
  ldxdw r3, [r10-0x40]
  lddw r1, 0x7ffffffffffffff8
  jle r3, r1, jmp_bf38
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_bf20:
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_bf38:
  mov64 r1, 0x0
  jeq r6, 0x0, jmp_bf70
  ldxdw r1, [r7+0x8]
  mul64 r6, 0xd0
  stxdw [r10-0x8], r6
  stxdw [r10-0x18], r1
  mov64 r1, 0x8

jmp_bf70:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x8
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_bfd8
  ldxdw r1, [r10-0x28]
  stxdw [r7+0x0], r8
  stxdw [r7+0x8], r1
  exit

jmp_bfd8:
  ldxdw r2, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

fn_c000:
  stxdw [r10-0x48], r2
  mov64 r7, r1
  ldxdw r6, [r7+0x0]
  mov64 r8, r6
  lsh64 r8, 0x1
  jgt r8, 0x4, jmp_c038
  mov64 r8, 0x4

jmp_c038:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r9, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x12c
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_c098
  mov64 r1, 0x0

jmp_c098:
  and64 r1, 0x1
  jne r1, 0x0, jmp_c0e0
  ldxdw r3, [r10-0x40]
  lddw r1, 0x7ffffffffffffffc
  jle r3, r1, jmp_c0f8
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c0e0:
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c0f8:
  mov64 r1, 0x0
  jeq r6, 0x0, jmp_c130
  ldxdw r1, [r7+0x8]
  mul64 r6, 0x12c
  stxdw [r10-0x8], r6
  stxdw [r10-0x18], r1
  mov64 r1, 0x4

jmp_c130:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x4
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_c198
  ldxdw r1, [r10-0x28]
  stxdw [r7+0x0], r8
  stxdw [r7+0x8], r1
  exit

jmp_c198:
  ldxdw r2, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

fn_c1c0:
  stxdw [r10-0x48], r2
  mov64 r7, r1
  ldxdw r6, [r7+0x0]
  mov64 r8, r6
  lsh64 r8, 0x1
  jgt r8, 0x4, jmp_c1f8
  mov64 r8, 0x4

jmp_c1f8:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r9, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x4c
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_c258
  mov64 r1, 0x0

jmp_c258:
  and64 r1, 0x1
  jne r1, 0x0, jmp_c2a0
  ldxdw r3, [r10-0x40]
  lddw r1, 0x7ffffffffffffffc
  jle r3, r1, jmp_c2b8
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c2a0:
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c2b8:
  mov64 r1, 0x0
  jeq r6, 0x0, jmp_c2f0
  ldxdw r1, [r7+0x8]
  mul64 r6, 0x4c
  stxdw [r10-0x8], r6
  stxdw [r10-0x18], r1
  mov64 r1, 0x4

jmp_c2f0:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x4
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_c358
  ldxdw r1, [r10-0x28]
  stxdw [r7+0x0], r8
  stxdw [r7+0x8], r1
  exit

jmp_c358:
  ldxdw r2, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

fn_c380:
  stxdw [r10-0x48], r2
  mov64 r7, r1
  ldxdw r6, [r7+0x0]
  mov64 r8, r6
  lsh64 r8, 0x1
  jgt r8, 0x4, jmp_c3b8
  mov64 r8, 0x4

jmp_c3b8:
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r9, 0x0
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x28
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_c418
  mov64 r1, 0x0

jmp_c418:
  and64 r1, 0x1
  jne r1, 0x0, jmp_c460
  ldxdw r3, [r10-0x40]
  lddw r1, 0x7ffffffffffffff8
  jle r3, r1, jmp_c478
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c460:
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

jmp_c478:
  mov64 r1, 0x0
  jeq r6, 0x0, jmp_c4b0
  ldxdw r1, [r7+0x8]
  mul64 r6, 0x28
  stxdw [r10-0x8], r6
  stxdw [r10-0x18], r1
  mov64 r1, 0x8

jmp_c4b0:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, 0x8
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_c518
  ldxdw r1, [r10-0x28]
  stxdw [r7+0x0], r8
  stxdw [r7+0x8], r1
  exit

jmp_c518:
  ldxdw r2, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r9
  ldxdw r3, [r10-0x48]
  call fn_cb038

fn_c540:
  stxdw [r10-0x18], r5
  mov64 r8, r3
  mov64 r5, r2
  mov64 r6, r1
  mov64 r2, r8
  add64 r2, r4
  add64 r2, -0x1
  mov64 r9, r8
  neg64 r9
  and64 r2, r9
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r7, 0x0
  mov64 r3, 0x0
  stxdw [r10-0x20], r5
  mov64 r4, r5
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x8]
  jne r2, 0x0, jmp_c5f0
  mov64 r1, 0x0

jmp_c5f0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_c650
  stxdw [r10-0x28], r6
  lddw r1, -0x8000000000000000
  sub64 r1, r8
  ldxdw r6, [r10-0x10]
  jle r6, r1, jmp_c670

jmp_c630:
  mov64 r1, r7
  mov64 r2, r6
  ldxdw r3, [r10-0x18]
  call fn_cb038

jmp_c650:
  mov64 r1, r7
  mov64 r2, r6
  ldxdw r3, [r10-0x18]
  call fn_cb038

jmp_c670:
  jeq r6, 0x0, jmp_c718
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_c6b8
  mov64 r3, r1

jmp_c6b8:
  mov64 r2, r3
  sub64 r2, r6
  mov64 r1, 0x0
  mov64 r4, 0x1
  jle r2, r3, jmp_c728
  jeq r4, 0x0, jmp_c738

jmp_c6e8:
  and64 r1, r9
  lddw r2, 0x300000008
  mov64 r7, r8
  jge r1, r2, jmp_c768
  ja jmp_c630

jmp_c718:
  mov64 r2, 0x0
  ja jmp_c790

jmp_c728:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_c6e8

jmp_c738:
  mov64 r1, r2
  and64 r1, r9
  lddw r2, 0x300000008
  mov64 r7, r8
  jlt r1, r2, jmp_c630

jmp_c768:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  mov64 r8, r1
  ldxdw r2, [r10-0x20]

jmp_c790:
  ldxdw r1, [r10-0x28]
  stxdw [r1+0x8], r8
  stxdw [r1+0x0], r2
  exit

fn_c7b0:
  mov64 r8, r4
  mov64 r7, r3
  mov64 r3, r2
  add64 r3, r7
  mov64 r6, 0x0
  mov64 r4, 0x1
  jlt r3, r2, jmp_c7f0
  mov64 r4, 0x0

jmp_c7f0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_c940
  mov64 r3, 0x8
  jeq r5, 0x1, jmp_c818
  mov64 r3, 0x4

jmp_c818:
  add64 r7, r2
  ldxdw r9, [r1+0x0]
  mov64 r2, r9
  lsh64 r2, 0x1
  jgt r7, r2, jmp_c848
  mov64 r7, r2

jmp_c848:
  stxdw [r10-0x48], r1
  jgt r7, r3, jmp_c860
  mov64 r7, r3

jmp_c860:
  mov64 r2, r8
  stxdw [r10-0x50], r5
  add64 r2, r5
  add64 r2, -0x1
  mov64 r1, r8
  neg64 r1
  and64 r2, r1
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r3, 0x0
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x38]
  jne r2, 0x0, jmp_c8e8
  mov64 r1, 0x0

jmp_c8e8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_c940
  lddw r1, -0x8000000000000000
  sub64 r1, r8
  ldxdw r3, [r10-0x40]
  jle r3, r1, jmp_c960
  mov64 r1, r6
  lddw r3, data_5f00
  call fn_cb038

jmp_c940:
  mov64 r1, r6
  lddw r3, data_5f00
  call fn_cb038

jmp_c960:
  mov64 r1, 0x0
  jeq r9, 0x0, jmp_c9a8
  ldxdw r1, [r10-0x50]
  mul64 r9, r1
  ldxdw r1, [r10-0x48]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x8], r9
  stxdw [r10-0x18], r1
  mov64 r1, r8

jmp_c9a8:
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r4, r10
  add64 r4, -0x18
  mov64 r2, r8
  call fn_b5f8
  ldxdw r1, [r10-0x30]
  jeq r1, 0x1, jmp_ca18
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x48]
  stxdw [r2+0x0], r7
  stxdw [r2+0x8], r1
  exit

jmp_ca18:
  ldxdw r2, [r10-0x20]
  ldxdw r6, [r10-0x28]
  mov64 r1, r6
  lddw r3, data_5f00
  call fn_cb038

fn_ca48:
  mov64 r4, r2
  ldxb r1, [r1+0x0]
  lsh64 r1, 0x3
  lddw r3, data_2a58
  add64 r3, r1
  lddw r2, data_6f60
  add64 r2, r1
  ldxdw r2, [r2+0x0]
  ldxdw r3, [r3+0x0]
  mov64 r1, r4
  call fn_ce550
  exit

fn_cab8:
  mov64 r6, r2
  mov64 r7, r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r6
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_cbd0
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r6
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_cbd0
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r6
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_cbd0
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r6
  mov64 r3, 0x8
  call fn_be210
  jne r0, 0x0, jmp_cbd0
  mov64 r0, 0x0

jmp_cbd0:
  exit

fn_cbd8:
  ldxdw r7, [r2+0x0]
  stxdw [r10-0x10], r2
  ldxdw r6, [r2+0x8]
  stxdw [r10-0x18], r1
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x8], r1
  mov64 r8, r6
  jlt r6, 0x8, jmp_cc20
  mov64 r8, 0x8

jmp_cc20:
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  lddw r0, data_5de0
  add64 r7, r8
  mov64 r9, r6
  sub64 r9, r8
  jlt r6, 0x8, jmp_ce08
  ldxdw r1, [r10-0x18]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x8], r1
  mov64 r8, r9
  jlt r9, 0x8, jmp_cca8
  mov64 r8, 0x8

jmp_cca8:
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r6, r9
  sub64 r6, r8
  jlt r9, 0x8, jmp_cdf0
  ldxdw r1, [r10-0x18]
  ldxdw r1, [r1+0x10]
  stxdw [r10-0x8], r1
  mov64 r8, r6
  jlt r6, 0x8, jmp_cd20
  mov64 r8, 0x8

jmp_cd20:
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r9, r6
  sub64 r9, r8
  jlt r6, 0x8, jmp_cdf8
  ldxdw r1, [r10-0x18]
  ldxdw r1, [r1+0x18]
  stxdw [r10-0x8], r1
  mov64 r8, r9
  jlt r9, 0x8, jmp_cd98
  mov64 r8, 0x8

jmp_cd98:
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r1, r9
  sub64 r9, r8
  jlt r1, 0x8, jmp_cdf8
  mov64 r0, 0x0
  ja jmp_ce08

jmp_cdf0:
  mov64 r9, r6

jmp_cdf8:
  lddw r0, data_5de0

jmp_ce08:
  ldxdw r1, [r10-0x10]
  stxdw [r1+0x0], r7
  stxdw [r1+0x8], r9
  exit

fn_ce28:
  ldxdw r7, [r2+0x0]
  stxdw [r10-0x18], r2
  ldxdw r9, [r2+0x8]
  ldxdw r3, [r1+0x0]
  stxdw [r10-0x20], r1
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r3
  mov64 r8, r9
  jlt r9, 0x10, jmp_ce80
  mov64 r8, 0x10

jmp_ce80:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  lddw r0, data_5de0
  add64 r7, r8
  mov64 r6, r9
  sub64 r6, r8
  jlt r9, 0x10, jmp_d098
  ldxdw r2, [r10-0x20]
  ldxdw r1, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r8, r6
  jlt r6, 0x10, jmp_cf18
  mov64 r8, 0x10

jmp_cf18:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r9, r6
  sub64 r9, r8
  jlt r6, 0x10, jmp_d080
  ldxdw r2, [r10-0x20]
  ldxdw r1, [r2+0x20]
  ldxdw r2, [r2+0x28]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r8, r9
  jlt r9, 0x10, jmp_cfa0
  mov64 r8, 0x10

jmp_cfa0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r6, r9
  sub64 r6, r8
  jlt r9, 0x10, jmp_d088
  ldxdw r2, [r10-0x20]
  ldxdw r1, [r2+0x30]
  ldxdw r2, [r2+0x38]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r8, r6
  jlt r6, 0x10, jmp_d028
  mov64 r8, 0x10

jmp_d028:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r7
  mov64 r3, r8
  call fn_d23d0
  add64 r7, r8
  mov64 r1, r6
  sub64 r6, r8
  jlt r1, 0x10, jmp_d088
  mov64 r0, 0x0
  ja jmp_d098

jmp_d080:
  mov64 r6, r9

jmp_d088:
  lddw r0, data_5de0

jmp_d098:
  ldxdw r1, [r10-0x18]
  stxdw [r1+0x0], r7
  stxdw [r1+0x8], r6
  exit

fn_d0b8:
  mov64 r6, r2
  mov64 r7, r1
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r7+0x8]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r6
  mov64 r3, 0x10
  call fn_be210
  jne r0, 0x0, jmp_d210
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r7+0x18]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r6
  mov64 r3, 0x10
  call fn_be210
  jne r0, 0x0, jmp_d210
  ldxdw r1, [r7+0x20]
  ldxdw r2, [r7+0x28]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r6
  mov64 r3, 0x10
  call fn_be210
  jne r0, 0x0, jmp_d210
  ldxdw r1, [r7+0x30]
  ldxdw r2, [r7+0x38]
  stxdw [r10-0x8], r2
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r6
  mov64 r3, 0x10
  call fn_be210
  jne r0, 0x0, jmp_d210
  mov64 r0, 0x0

jmp_d210:
  exit

fn_d218:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r7+0x8]
  jge r2, 0x10, jmp_d258
  mov64 r3, r2
  mov64 r8, r1
  ja jmp_d2d0

jmp_d258:
  mov64 r8, r1
  add64 r8, 0x10
  mov64 r3, r2
  add64 r3, -0x10
  jlt r3, 0x10, jmp_d2d0
  mov64 r8, r1
  add64 r8, 0x20
  mov64 r3, r2
  add64 r3, -0x20
  jlt r3, 0x10, jmp_d2d0
  mov64 r8, r1
  add64 r8, 0x30
  mov64 r3, r2
  add64 r3, -0x30
  jge r3, 0x10, jmp_d320

jmp_d2d0:
  add64 r8, r3
  lddw r1, data_5dc8
  call fn_c9c58
  stxdw [r7+0x0], r8
  stdw [r7+0x8], 0x0
  stxdw [r6+0x8], r0
  mov64 r1, 0x1

jmp_d310:
  stxdw [r6+0x0], r1
  exit

jmp_d320:
  ldxdw r3, [r1+0x8]
  stxdw [r10-0x10], r3
  ldxdw r3, [r1+0x0]
  stxdw [r10-0x8], r3
  ldxdw r5, [r1+0x18]
  ldxdw r0, [r1+0x10]
  add64 r2, -0x40
  ldxdw r8, [r1+0x20]
  ldxdw r9, [r1+0x28]
  ldxdw r4, [r1+0x30]
  ldxdw r3, [r1+0x38]
  stxdw [r7+0x8], r2
  add64 r1, 0x40
  stxdw [r7+0x0], r1
  stxdw [r6+0x40], r3
  stxdw [r6+0x38], r4
  stxdw [r6+0x30], r9
  stxdw [r6+0x28], r8
  stxdw [r6+0x20], r5
  stxdw [r6+0x18], r0
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x8]
  stxdw [r6+0x8], r1
  mov64 r1, 0x0
  ja jmp_d310

fn_d3f0:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r7+0x8]
  jge r2, 0x8, jmp_d430
  mov64 r3, r2
  mov64 r8, r1
  ja jmp_d4a8

jmp_d430:
  mov64 r8, r1
  add64 r8, 0x8
  mov64 r3, r2
  add64 r3, -0x8
  jlt r3, 0x8, jmp_d4a8
  mov64 r8, r1
  add64 r8, 0x10
  mov64 r3, r2
  add64 r3, -0x10
  jlt r3, 0x8, jmp_d4a8
  mov64 r8, r1
  add64 r8, 0x18
  mov64 r3, r2
  add64 r3, -0x18
  jge r3, 0x8, jmp_d4f8

jmp_d4a8:
  add64 r8, r3
  lddw r1, data_5dc8
  call fn_c9c58
  stxdw [r7+0x0], r8
  stdw [r7+0x8], 0x0
  stxdw [r6+0x8], r0
  mov64 r1, 0x1

jmp_d4e8:
  stxdw [r6+0x0], r1
  exit

jmp_d4f8:
  ldxdw r3, [r1+0x0]
  ldxdw r4, [r1+0x8]
  ldxdw r5, [r1+0x10]
  add64 r2, -0x20
  ldxdw r0, [r1+0x18]
  stxdw [r7+0x8], r2
  add64 r1, 0x20
  stxdw [r7+0x0], r1
  stxdw [r6+0x20], r0
  stxdw [r6+0x18], r5
  stxdw [r6+0x10], r4
  stxdw [r6+0x8], r3
  mov64 r1, 0x0
  ja jmp_d4e8

fn_d568:
  stxdw [r10-0x8], r1
  mov64 r4, r10
  add64 r4, -0x8
  mov64 r1, r2
  lddw r2, str_1418
  mov64 r3, 0xf
  lddw r5, data_5f18
  call fn_ce800
  exit

fn_d5c0:
  ldxdw r3, [r2+0x8]
  ldxdw r5, [r3+0x0]
  add64 r5, 0x1
  mov64 r0, 0x1
  jeq r5, 0x0, jmp_d5f0
  mov64 r0, 0x0

jmp_d5f0:
  ldxdw r4, [r2+0x0]
  stxdw [r3+0x0], r5
  jeq r0, 0x1, jmp_d6b8
  ldxdw r5, [r2+0x10]
  ldxdw r0, [r5+0x0]
  add64 r0, 0x1
  mov64 r6, 0x1
  jeq r0, 0x0, jmp_d638
  mov64 r6, 0x0

jmp_d638:
  stxdw [r5+0x0], r0
  jeq r6, 0x1, jmp_d6b8
  ldxdw r0, [r2+0x18]
  ldxdw r6, [r2+0x20]
  ldxb r7, [r2+0x28]
  ldxb r8, [r2+0x29]
  ldxb r2, [r2+0x2a]
  stxb [r1+0x2a], r2
  stxb [r1+0x29], r8
  stxb [r1+0x28], r7
  stxdw [r1+0x20], r6
  stxdw [r1+0x18], r0
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r3
  stxdw [r1+0x0], r4
  exit

jmp_d6b8:
  call abort

fn_d6c0:
  ldxdw r3, [r1+0x0]
  lddw r4, -0x8000000000000000
  xor64 r3, r4
  jlt r3, 0x1a, jmp_d6f0
  mov64 r3, 0xe

jmp_d6f0:
  jsgt r3, 0xc, jmp_d740
  jsle r3, 0x5, jmp_d788
  mov64 r1, r2
  jsle r3, 0x8, jmp_d838
  jsgt r3, 0xa, jmp_d908
  jne r3, 0x9, jmp_da90
  lddw r2, str_14e5
  mov64 r3, 0x14
  ja jmp_db00

jmp_d740:
  jsle r3, 0x12, jmp_d7c8
  mov64 r1, r2
  jsle r3, 0x15, jmp_d868
  jsgt r3, 0x17, jmp_d930
  jne r3, 0x16, jmp_dab0
  lddw r2, str_15c8
  mov64 r3, 0x13
  ja jmp_db00

jmp_d788:
  jsgt r3, 0x2, jmp_d898
  jeq r3, 0x0, jmp_d990
  mov64 r1, r2
  jne r3, 0x1, jmp_db10
  lddw r2, str_1447
  mov64 r3, 0xf
  ja jmp_db00

jmp_d7c8:
  jsgt r3, 0xf, jmp_d8d0
  jeq r3, 0xd, jmp_d9f0
  jne r3, 0xe, jmp_db30
  stxdw [r10-0x8], r1
  mov64 r4, r10
  add64 r4, -0x8
  mov64 r1, r2
  lddw r2, str_1520
  mov64 r3, 0xc
  lddw r5, data_5f80
  call fn_ce800
  ja jmp_db08

jmp_d838:
  jeq r3, 0x6, jmp_d958
  jne r3, 0x7, jmp_da50
  lddw r2, str_14b4
  mov64 r3, 0x18
  ja jmp_db00

jmp_d868:
  jeq r3, 0x13, jmp_d970
  jne r3, 0x14, jmp_da70
  lddw r2, str_1581
  mov64 r3, 0x21
  ja jmp_db00

jmp_d898:
  mov64 r1, r2
  jeq r3, 0x3, jmp_da18
  jne r3, 0x4, jmp_db58
  lddw r2, str_147e
  mov64 r3, 0x13
  ja jmp_db00

jmp_d8d0:
  mov64 r1, r2
  jeq r3, 0x10, jmp_da30
  jne r3, 0x11, jmp_db78
  lddw r2, data_1383
  mov64 r3, 0xc
  ja jmp_db00

jmp_d908:
  jne r3, 0xb, jmp_dac8
  lddw r2, str_150d
  mov64 r3, 0x13
  ja jmp_db00

jmp_d930:
  jne r3, 0x18, jmp_dae8
  lddw r2, str_15ed
  mov64 r3, 0x9
  ja jmp_db00

jmp_d958:
  lddw r2, str_14a2
  ja jmp_daf8

jmp_d970:
  lddw r2, str_1573
  mov64 r3, 0xe
  ja jmp_db00

jmp_d990:
  add64 r1, 0x8
  stxdw [r10-0x8], r1
  mov64 r4, r10
  add64 r4, -0x8
  mov64 r1, r2
  lddw r2, str_1441
  mov64 r3, 0x6
  lddw r5, data_5f60
  call fn_ce800
  ja jmp_db08

jmp_d9f0:
  mov64 r1, r2
  lddw r2, str_1377
  mov64 r3, 0xc
  ja jmp_db00

jmp_da18:
  lddw r2, str_146c
  ja jmp_daf8

jmp_da30:
  lddw r2, str_1540
  mov64 r3, 0x11
  ja jmp_db00

jmp_da50:
  lddw r2, str_14cc
  mov64 r3, 0x19
  ja jmp_db00

jmp_da70:
  lddw r2, str_15a2
  mov64 r3, 0x26
  ja jmp_db00

jmp_da90:
  lddw r2, str_14f9
  mov64 r3, 0x14
  ja jmp_db00

jmp_dab0:
  lddw r2, str_15db
  ja jmp_daf8

jmp_dac8:
  lddw r2, str_1362
  mov64 r3, 0x15
  ja jmp_db00

jmp_dae8:
  lddw r2, str_15f6

jmp_daf8:
  mov64 r3, 0x12

jmp_db00:
  call fn_ce550

jmp_db08:
  exit

jmp_db10:
  lddw r2, str_1456
  mov64 r3, 0x16
  ja jmp_db00

jmp_db30:
  mov64 r1, r2
  lddw r2, str_152c
  mov64 r3, 0x14
  ja jmp_db00

jmp_db58:
  lddw r2, str_1491
  mov64 r3, 0x11
  ja jmp_db00

jmp_db78:
  lddw r2, str_1551
  mov64 r3, 0x22
  ja jmp_db00

fn_db98:
  mov64 r8, r2
  mov64 r2, r1
  ldxdw r7, [r8+0x0]
  ldxdw r9, [r8+0x8]
  jge r9, 0x4, jmp_dc20
  add64 r7, r9
  lddw r1, data_5dc8
  mov64 r6, r2
  call fn_c9c58
  stxdw [r8+0x0], r7
  stdw [r8+0x8], 0x0
  stxdw [r6+0x8], r0
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1
  ja jmp_e518

jmp_dc20:
  ldxw r3, [r7+0x0]
  mov64 r1, r7
  add64 r1, 0x4
  stxdw [r8+0x0], r1
  add64 r9, -0x4
  stxdw [r8+0x8], r9
  stxdw [r10-0x110], r3
  jeq r3, 0x0, jmp_e2e8
  stxdw [r10-0x138], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r4, 0x300008000
  jeq r1, 0x0, jmp_dca8
  mov64 r4, r1

jmp_dca8:
  ldxdw r1, [r10-0x110]
  mov64 r3, r1
  jlt r1, 0x35, jmp_dcc8
  mov64 r3, 0x35

jmp_dcc8:
  mov64 r2, r3
  mul64 r2, 0x4c
  mov64 r5, r4
  sub64 r5, r2
  mov64 r1, 0x0
  mov64 r0, 0x1
  jle r5, r4, jmp_e308
  jeq r0, 0x0, jmp_e318

jmp_dd08:
  lddw r4, 0x300000007
  jle r1, r4, jmp_e338

jmp_dd20:
  and64 r1, -0x4
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  stxdw [r10-0xb8], r3
  mov64 r2, 0x0
  stxdw [r10-0xc8], r2
  mov64 r0, 0x48
  mov64 r2, r10
  add64 r2, -0x2c
  stxdw [r10-0x120], r2
  mov64 r2, r10
  add64 r2, -0x3d
  stxdw [r10-0x128], r2
  mov64 r2, r10
  add64 r2, -0x98
  stxdw [r10-0x130], r2
  add64 r7, 0x4d
  stxdw [r10-0xc0], r1
  stxdw [r10-0xb0], r1
  stdw [r10-0xa8], 0x0
  stxdw [r10-0x118], r8
  ja jmp_df40

jmp_ddd8:
  stxdw [r10-0xc0], r1
  mov64 r2, r1
  ldxdw r4, [r10-0xf8]
  add64 r2, r4
  stxdw [r2-0x44], r5
  stxw [r2-0x48], r3
  ldxdw r3, [r10-0x78]
  stxdw [r2-0x3c], r3
  ldxdw r3, [r10-0x70]
  stxdw [r2-0x34], r3
  ldxdw r3, [r10-0x68]
  stxdw [r2-0x2c], r3
  ldxh r3, [r10-0x60]
  stxh [r2-0x24], r3
  ldxdw r1, [r10-0xd0]
  stxdw [r2-0x21], r1
  ldxdw r1, [r10-0xe8]
  stxb [r2-0x22], r1
  ldxdw r3, [r10-0x90]
  stxdw [r2-0x19], r3
  ldxdw r3, [r10-0x88]
  stxdw [r2-0x11], r3
  ldxb r3, [r10-0x80]
  stxb [r2-0x9], r3
  ldxdw r1, [r10-0xd8]
  stxb [r2+0x0], r1
  stxb [r2-0x1], r6
  ldxdw r1, [r10-0x108]
  stxb [r2-0x2], r1
  ldxdw r1, [r10-0x100]
  stxh [r2-0x4], r1
  ldxdw r1, [r10-0xf0]
  stxw [r2-0x8], r1
  add64 r7, 0x49
  add64 r4, 0x4c
  add64 r8, 0x1
  stxdw [r10-0xa8], r8
  stxdw [r10-0xc8], r8
  mov64 r2, r8
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  ldxdw r8, [r10-0x118]
  ldxdw r1, [r10-0x110]
  mov64 r0, r4
  jge r2, r1, jmp_e548

jmp_df40:
  jle r9, 0x1f, jmp_e358
  ldxdw r2, [r7-0x43]
  ldxb r3, [r7-0x3b]
  stxb [r10-0x38], r3
  stxdw [r10-0x40], r2
  mov64 r3, r9
  and64 r3, -0x20
  jeq r3, 0x20, jmp_e358
  ldxdw r3, [r10-0x3f]
  ldxdw r6, [r7-0x23]
  ldxb r4, [r7-0x1b]
  stxb [r10-0x38], r4
  stxdw [r10-0x40], r6
  mov64 r4, r9
  and64 r4, -0x4
  jeq r4, 0x40, jmp_e358
  ldxdw r5, [r10-0x3f]
  ldxw r1, [r7-0x9]
  mov64 r4, r9
  add64 r4, -0x44
  stxdw [r8+0x8], r4
  jeq r4, 0x0, jmp_e398
  stxdw [r10-0xe0], r3
  mov64 r3, r0
  stxdw [r10-0xd0], r5
  ldxb r0, [r7-0x5]
  mov64 r5, r7
  add64 r5, -0x4
  stxdw [r8+0x0], r5
  add64 r4, -0x1
  stxdw [r8+0x8], r4
  stxb [r10-0x59], r0
  stxdw [r10-0xd8], r0
  jge r0, 0x2, jmp_e3c8
  jeq r4, 0x0, jmp_e410
  stxdw [r10-0xe8], r6
  ldxb r6, [r7-0x4]
  mov64 r5, r7
  add64 r5, -0x3
  stxdw [r8+0x0], r5
  add64 r4, -0x1
  stxdw [r8+0x8], r4
  stxb [r10-0x59], r6
  jge r6, 0x6, jmp_e430
  jle r4, 0x1, jmp_e358
  add64 r4, 0x46
  jeq r4, 0x48, jmp_e520
  stxdw [r10-0xf0], r1
  mov64 r1, r8
  mov64 r8, r7
  add64 r8, -0x3a
  stxdw [r10-0xf8], r3
  mov64 r0, r7
  add64 r0, -0x29
  mov64 r5, r7
  add64 r5, -0x1a
  ldxh r3, [r7-0x3]
  stxdw [r10-0x100], r3
  mov64 r9, r4
  add64 r9, -0x49
  ldxb r3, [r7-0x1]
  stxdw [r10-0x108], r3
  stxdw [r1+0x8], r9
  stxdw [r1+0x0], r7
  ldxw r3, [r7-0x49]
  ldxh r4, [r7-0x45]
  stxh [r10-0xa0], r4
  ldxb r4, [r8+0x10]
  ldxdw r1, [r10-0x128]
  stxb [r1+0x10], r4
  ldxdw r4, [r8+0x8]
  stxdw [r1+0x8], r4
  ldxdw r4, [r8+0x0]
  stxdw [r1+0x0], r4
  ldxh r4, [r0+0x4]
  ldxdw r1, [r10-0x120]
  stxh [r1+0x4], r4
  ldxw r4, [r0+0x0]
  stxw [r1+0x0], r4
  ldxb r4, [r5+0x10]
  stxb [r10-0x80], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x88], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0x90], r4
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x9d], r1
  stxb [r10-0x9e], r2
  ldxdw r1, [r10-0x130]
  ldxh r2, [r1+0x0]
  stxh [r10-0x40], r2
  ldxb r2, [r1+0x2]
  stxb [r10-0x3e], r2
  ldxdw r5, [r10-0xa0]
  ldxdw r2, [r10-0x40]
  stxdw [r10-0x78], r2
  ldxdw r2, [r10-0x38]
  stxdw [r10-0x70], r2
  ldxdw r2, [r10-0x30]
  stxdw [r10-0x68], r2
  ldxh r2, [r10-0x28]
  stxh [r10-0x60], r2
  ldxdw r2, [r10-0xb8]
  ldxdw r1, [r10-0xc0]
  ldxdw r8, [r10-0xc8]
  jne r8, r2, jmp_ddd8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_5fb8
  stxdw [r10-0xc0], r3
  stxdw [r10-0xe0], r5
  call fn_c1c0
  ldxdw r5, [r10-0xe0]
  ldxdw r3, [r10-0xc0]
  ldxdw r1, [r10-0xb0]
  ja jmp_ddd8

jmp_e2e8:
  stdw [r2+0x10], 0x0
  stdw [r2+0x8], 0x4
  stdw [r2+0x0], 0x0
  ja jmp_e518

jmp_e308:
  mov64 r0, 0x0
  jne r0, 0x0, jmp_dd08

jmp_e318:
  mov64 r1, r5
  lddw r4, 0x300000007
  jgt r1, r4, jmp_dd20

jmp_e338:
  mov64 r1, 0x4
  lddw r3, data_5fa0
  call fn_cb038

jmp_e358:
  add64 r7, r9
  add64 r7, -0x49
  lddw r1, data_5dc8
  call fn_c9c58

jmp_e380:
  stxdw [r8+0x0], r7
  stdw [r8+0x8], 0x0
  ja jmp_e4f0

jmp_e398:
  lddw r1, data_5dc8
  call fn_c9c58
  add64 r7, -0x5
  stxdw [r8+0x0], r7
  ja jmp_e4f0

jmp_e3c8:
  lddw r1, data_5ec0
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x10
  stxdw [r10-0x30], r1
  lddw r1, 0x18aef
  ja jmp_e470

jmp_e410:
  lddw r1, data_5dc8
  call fn_c9c58
  ja jmp_e4f0

jmp_e430:
  lddw r1, data_5f50
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x10
  stxdw [r10-0x30], r1
  lddw r1, 0x11fc

jmp_e470:
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x59
  stxdw [r10-0x10], r1
  stdw [r10-0x20], 0x0
  stdw [r10-0x38], 0x1
  stdw [r10-0x28], 0x1
  mov64 r7, r10
  add64 r7, -0x58
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r1, r7
  call fn_cb0f0
  mov64 r1, 0x14
  mov64 r2, r7
  call fn_bc4f8

jmp_e4f0:
  lddw r1, -0x8000000000000000
  ldxdw r2, [r10-0x138]
  stxdw [r2+0x0], r1
  stxdw [r2+0x8], r0

jmp_e518:
  exit

jmp_e520:
  lddw r1, data_5dc8
  call fn_c9c58
  add64 r7, -0x1
  ja jmp_e380

jmp_e548:
  ldxdw r1, [r10-0xa8]
  ldxdw r2, [r10-0x138]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0xb0]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0xb8]
  stxdw [r2+0x0], r1
  ja jmp_e518

fn_e588:
  mov64 r6, r1
  ldxdw r9, [r2+0x0]
  ldxdw r8, [r2+0x8]
  jge r8, 0x4, jmp_e608
  add64 r9, r8
  lddw r1, data_5dc8
  mov64 r7, r2
  call fn_c9c58
  stxdw [r7+0x0], r9
  stdw [r7+0x8], 0x0
  stxdw [r6+0x8], r0
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1
  ja jmp_ee58

jmp_e608:
  add64 r8, -0x4
  ldxw r1, [r9+0x0]
  stxdw [r2+0x8], r8
  add64 r9, 0x4
  stxdw [r2+0x0], r9
  jeq r1, 0x0, jmp_eac0
  stxdw [r10-0x28], r9
  stxdw [r10-0x30], r2
  stxdw [r10-0x48], r6
  mov64 r2, r1
  mov64 r6, r1
  jlt r6, 0x100000, jmp_e670
  mov64 r2, 0x100000

jmp_e670:
  stxdw [r10-0x40], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_e6b8
  mov64 r2, r1

jmp_e6b8:
  mov64 r5, r2
  ldxdw r3, [r10-0x40]
  sub64 r5, r3
  mov64 r9, 0x0
  mov64 r4, 0x1
  jle r5, r2, jmp_eae0
  jeq r4, 0x0, jmp_eaf0

jmp_e6f0:
  lddw r2, 0x300000007
  jle r9, r2, jmp_eb10

jmp_e708:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r9
  mov64 r7, 0x0
  mov64 r1, r9
  mov64 r2, 0x0
  call fn_d23f0
  mov64 r0, r9
  ldxdw r5, [r10-0x40]
  stxdw [r10-0x8], r5
  stxdw [r10-0x18], r5
  stxdw [r10-0x10], r0
  ldxdw r3, [r10-0x30]
  ldxdw r4, [r10-0x28]
  stxdw [r10-0x38], r6

jmp_e780:
  jne r7, r5, jmp_e878
  mov64 r9, r5
  lsh64 r9, 0x1
  jlt r9, r6, jmp_e7a8
  mov64 r9, r6

jmp_e7a8:
  jle r9, r5, jmp_e868
  sub64 r9, r5
  ldxdw r1, [r10-0x18]
  sub64 r1, r5
  jgt r9, r1, jmp_e9e0
  mov64 r1, r0
  add64 r1, r5
  jlt r9, 0x2, jmp_e850

jmp_e7e8:
  add64 r9, -0x1
  mov64 r2, 0x0
  mov64 r3, r9
  stxdw [r10-0x28], r4
  stxdw [r10-0x40], r5
  stxdw [r10-0x20], r0
  call fn_d23f0
  ldxdw r1, [r10-0x20]
  ldxdw r5, [r10-0x40]
  ldxdw r4, [r10-0x28]
  ldxdw r3, [r10-0x30]
  add64 r5, r9
  add64 r1, r5

jmp_e850:
  stb [r1+0x0], 0x0
  add64 r5, 0x1
  ja jmp_e870

jmp_e868:
  mov64 r5, r9

jmp_e870:
  stxdw [r10-0x8], r5

jmp_e878:
  jlt r5, r7, jmp_ee60
  mov64 r1, r5
  sub64 r1, r7
  mov64 r9, r8
  jlt r8, r1, jmp_e8a8
  mov64 r9, r1

jmp_e8a8:
  ldxdw r0, [r10-0x10]
  mov64 r1, r0
  add64 r1, r7
  jne r9, 0x1, jmp_e900
  ldxb r2, [r4+0x0]
  stxb [r1+0x0], r2
  add64 r8, -0x1
  stxdw [r3+0x8], r8
  add64 r4, 0x1
  stxdw [r3+0x0], r4
  ja jmp_e990

jmp_e900:
  mov64 r2, r4
  mov64 r3, r9
  stxdw [r10-0x28], r8
  mov64 r8, r4
  mov64 r6, r5
  stxdw [r10-0x20], r0
  call fn_d23d0
  ldxdw r0, [r10-0x20]
  mov64 r5, r6
  mov64 r4, r8
  ldxdw r8, [r10-0x28]
  ldxdw r6, [r10-0x38]
  ldxdw r3, [r10-0x30]
  sub64 r8, r9
  stxdw [r3+0x8], r8
  add64 r4, r9
  stxdw [r3+0x0], r4
  jeq r9, 0x0, jmp_eb38

jmp_e990:
  mov64 r1, r7
  add64 r1, r9
  mov64 r2, 0x1
  jlt r1, r7, jmp_e9b8
  mov64 r2, 0x0

jmp_e9b8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_ee88
  mov64 r7, r1
  jlt r1, r6, jmp_e780
  ja jmp_ea68

jmp_e9e0:
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r2, r5
  mov64 r3, r9
  mov64 r6, r4
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r4, r6
  ldxdw r6, [r10-0x38]
  ldxdw r3, [r10-0x30]
  ldxdw r0, [r10-0x10]
  ldxdw r5, [r10-0x8]
  mov64 r1, r0
  add64 r1, r5
  jge r9, 0x2, jmp_e7e8
  ja jmp_e850

jmp_ea68:
  ldxdw r1, [r10-0x18]
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_eb90
  lddw r2, -0x7fffffffffffffff
  jeq r1, r2, jmp_eb60
  ldxdw r2, [r10-0x48]
  stxdw [r2+0x10], r5
  stxdw [r2+0x8], r0
  ja jmp_ee50

jmp_eac0:
  stdw [r6+0x10], 0x0
  stdw [r6+0x8], 0x1
  stdw [r6+0x0], 0x0
  ja jmp_ee58

jmp_eae0:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_e6f0

jmp_eaf0:
  mov64 r9, r5
  lddw r2, 0x300000007
  jgt r9, r2, jmp_e708

jmp_eb10:
  mov64 r1, 0x1
  mov64 r2, r3
  lddw r3, data_5e78
  call fn_cb038

jmp_eb38:
  mov64 r1, 0x14
  lddw r2, str_1326
  mov64 r3, 0x1a
  call fn_ca088

jmp_eb60:
  lddw r1, -0x8000000000000000
  ldxdw r2, [r10-0x48]
  stxdw [r2+0x0], r1
  stxdw [r2+0x8], r0
  ja jmp_ee58

jmp_eb90:
  stxdw [r10-0x28], r4
  mov64 r1, r6
  jlt r1, 0x1000, jmp_ebb0
  mov64 r6, 0x1000

jmp_ebb0:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_ebf0
  mov64 r3, r1

jmp_ebf0:
  mov64 r2, r3
  sub64 r2, r6
  mov64 r1, 0x0
  mov64 r4, 0x1
  jle r2, r3, jmp_edc8
  jeq r4, 0x0, jmp_edd8

jmp_ec20:
  lddw r2, 0x300000007
  jle r1, r2, jmp_edf8

jmp_ec38:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  stxdw [r10-0x10], r1
  stxdw [r10-0x18], r6
  mov64 r6, 0x0
  add64 r8, -0x1
  stdw [r10-0x8], 0x0
  ldxdw r2, [r10-0x30]
  ldxdw r3, [r10-0x28]
  ja jmp_ece8

jmp_ec90:
  ldxdw r1, [r10-0x10]
  add64 r1, r6
  stxb [r1+0x0], r7
  add64 r8, -0x1
  add64 r6, 0x1
  stxdw [r10-0x8], r6
  mov64 r1, r6
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  ldxdw r4, [r10-0x38]
  jge r1, r4, jmp_ee20

jmp_ece8:
  mov64 r9, r3
  add64 r9, r6
  jeq r8, -0x1, jmp_ed70
  ldxb r7, [r9+0x0]
  stxdw [r2+0x8], r8
  add64 r9, 0x1
  stxdw [r2+0x0], r9
  ldxdw r1, [r10-0x18]
  jne r6, r1, jmp_ec90
  mov64 r1, r10
  add64 r1, -0x18
  lddw r2, data_5fb8
  call fn_cac38
  ldxdw r3, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ja jmp_ec90

jmp_ed70:
  lddw r1, data_5dc8
  mov64 r6, r2
  call fn_c9c58
  stxdw [r6+0x0], r9
  stdw [r6+0x8], 0x0
  ldxdw r2, [r10-0x48]
  stxdw [r2+0x8], r0
  lddw r1, -0x8000000000000000
  ja jmp_ee50

jmp_edc8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_ec20

jmp_edd8:
  mov64 r1, r2
  lddw r2, 0x300000007
  jgt r1, r2, jmp_ec38

jmp_edf8:
  mov64 r1, 0x1
  mov64 r2, r6
  lddw r3, data_5fa0
  call fn_cb038

jmp_ee20:
  ldxdw r1, [r10-0x8]
  ldxdw r2, [r10-0x48]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0x10]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x18]

jmp_ee50:
  stxdw [r2+0x0], r1

jmp_ee58:
  exit

jmp_ee60:
  mov64 r1, r7
  mov64 r2, r5
  lddw r3, data_5ea8
  call fn_cf458

jmp_ee88:
  lddw r1, data_5e90
  call fn_d07b8

fn_eea0:
  mov64 r6, r2
  mov64 r7, r1
  ldxb r1, [r7+0x0]
  jne r1, 0x1, jmp_ef18
  mov64 r1, r6
  lddw r2, data_1608
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_ef40
  add64 r7, 0x1
  mov64 r1, r6
  mov64 r2, r7
  mov64 r3, 0x20
  ja jmp_ef38

jmp_ef18:
  mov64 r1, r6
  lddw r2, data_0bb8
  mov64 r3, 0x1

jmp_ef38:
  call fn_be210

jmp_ef40:
  exit

fn_ef48:
  mov64 r6, r3
  and64 r1, 0x1
  jeq r1, 0x0, jmp_efc8
  mov64 r7, r2
  mov64 r1, r6
  lddw r2, data_1608
  mov64 r3, 0x1
  call fn_be210
  jne r0, 0x0, jmp_eff0
  stxdw [r10-0x8], r7
  mov64 r2, r10
  add64 r2, -0x8
  mov64 r1, r6
  mov64 r3, 0x8
  ja jmp_efe8

jmp_efc8:
  mov64 r1, r6
  lddw r2, data_0bb8
  mov64 r3, 0x1

jmp_efe8:
  call fn_be210

jmp_eff0:
  exit

fn_eff8:
  mov64 r7, r2
  mov64 r6, r1
  ldxdw r8, [r7+0x0]
  ldxdw r1, [r7+0x8]
  jeq r1, 0x0, jmp_f080
  mov64 r3, r1
  add64 r3, -0x1
  ldxb r2, [r8+0x0]
  stxdw [r7+0x8], r3
  mov64 r3, r8
  add64 r3, 0x1
  stxdw [r7+0x0], r3
  stxb [r10-0x59], r2
  jeq r2, 0x1, jmp_f0a8
  jne r2, 0x0, jmp_f0e8
  stb [r6+0x1], 0x0
  ja jmp_f278

jmp_f080:
  lddw r1, data_5dc8
  call fn_c9c58
  stxdw [r7+0x0], r8
  ja jmp_f1a8

jmp_f0a8:
  jge r1, 0x21, jmp_f1c0
  add64 r8, r1
  lddw r1, data_5dc8
  call fn_c9c58
  stxdw [r7+0x0], r8
  stdw [r7+0x8], 0x0
  ja jmp_f1a8

jmp_f0e8:
  lddw r1, data_5fd0
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x10
  stxdw [r10-0x30], r1
  lddw r1, 0x18aef
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x59
  stxdw [r10-0x10], r1
  stdw [r10-0x20], 0x0
  stdw [r10-0x38], 0x2
  stdw [r10-0x28], 0x1
  mov64 r7, r10
  add64 r7, -0x58
  mov64 r2, r10
  add64 r2, -0x40
  mov64 r1, r7
  call fn_cb0f0
  mov64 r1, 0x14
  mov64 r2, r7
  call fn_bc4f8

jmp_f1a8:
  stxdw [r6+0x8], r0
  mov64 r1, 0x1
  ja jmp_f280

jmp_f1c0:
  ldxdw r2, [r8+0x7]
  ldxb r4, [r8+0xf]
  stxb [r10-0x38], r4
  ldxh r4, [r3+0x4]
  stxh [r6+0x6], r4
  ldxw r3, [r3+0x0]
  stxw [r6+0x2], r3
  stxdw [r10-0x40], r2
  add64 r1, -0x21
  ldxdw r3, [r10-0x3f]
  stxdw [r7+0x8], r1
  mov64 r1, r8
  add64 r1, 0x21
  stxdw [r7+0x0], r1
  ldxb r1, [r8+0x20]
  stxb [r6+0x21], r1
  ldxdw r1, [r8+0x18]
  stxdw [r6+0x19], r1
  ldxdw r1, [r8+0x10]
  stxdw [r6+0x11], r1
  stxdw [r6+0x9], r3
  stxb [r6+0x8], r2
  stb [r6+0x1], 0x1

jmp_f278:
  mov64 r1, 0x0

jmp_f280:
  stxb [r6+0x0], r1
  exit

fn_f290:
  mov64 r6, r1
  mov64 r1, 0x0
  jsge r3, 0x0, jmp_f2c8

jmp_f2a8:
  mov64 r2, r3
  lddw r3, data_5ff0
  call fn_cb038

jmp_f2c8:
  jeq r3, 0x0, jmp_f388
  mov64 r8, r2
  mov64 r7, r3
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_f320
  mov64 r2, r1

jmp_f320:
  mov64 r4, r2
  mov64 r3, r7
  sub64 r4, r3
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r5, 0x1
  jle r4, r2, jmp_f398
  mov64 r2, r8
  jeq r5, 0x0, jmp_f3b0

jmp_f368:
  lddw r4, 0x300000008
  jge r7, r4, jmp_f3d0
  ja jmp_f2a8

jmp_f388:
  mov64 r7, 0x1
  ja jmp_f3e8

jmp_f398:
  mov64 r5, 0x0
  mov64 r2, r8
  jne r5, 0x0, jmp_f368

jmp_f3b0:
  mov64 r7, r4
  lddw r4, 0x300000008
  jlt r7, r4, jmp_f2a8

jmp_f3d0:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7

jmp_f3e8:
  mov64 r1, r7
  mov64 r8, r3
  call fn_d23d0
  stxdw [r6+0x8], r7
  stxdw [r6+0x10], r8
  stxdw [r6+0x0], r8
  exit

fn_f420:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f470
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_be1a8
  ja jmp_f4c0

jmp_f470:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_f4c0:
  exit

fn_f4c8:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f518
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_be1a8
  ja jmp_f568

jmp_f518:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_f568:
  exit

fn_f570:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f5c0
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_8578
  ja jmp_f618

jmp_f5c0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stw [r6+0x0], 0x2

jmp_f618:
  exit

fn_f620:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f670
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_7c78
  ja jmp_f6c8

jmp_f670:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x0

jmp_f6c8:
  exit

fn_f6d0:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f720
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_8578
  ja jmp_f778

jmp_f720:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stw [r6+0x0], 0x2

jmp_f778:
  exit

fn_f780:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f7d0
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_89f8
  ja jmp_f838

jmp_f7d0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1

jmp_f838:
  exit

fn_f840:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f890
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_7828
  ja jmp_f8e8

jmp_f890:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2

jmp_f8e8:
  exit

fn_f8f0:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f940
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_80d0
  ja jmp_f998

jmp_f940:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2

jmp_f998:
  exit

fn_f9a0:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_f9f0
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_8e68
  ja jmp_fa48

jmp_f9f0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7

jmp_fa48:
  exit

fn_fa50:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_faa0
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_49c0
  ja jmp_faf8

jmp_faa0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stw [r6+0x90], 0x2

jmp_faf8:
  exit

fn_fb00:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_fb50
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_89f8
  ja jmp_fbb8

jmp_fb50:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  lddw r1, -0x8000000000000000
  stxdw [r6+0x0], r1

jmp_fbb8:
  exit

fn_fbc0:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_fc10
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_9308
  ja jmp_fc68

jmp_fc10:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0xa7], 0x2

jmp_fc68:
  exit

fn_fc70:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_fcc0
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_80d0
  ja jmp_fd18

jmp_fcc0:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  stb [r6+0x112], 0x2

jmp_fd18:
  exit

fn_fd20:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_fd70
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_7828
  ja jmp_fdc8

jmp_fd70:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2

jmp_fdc8:
  exit

fn_fdd0:
  ldxdw r2, [r3+0x8]
  jeq r2, 0x0, jmp_fe20
  add64 r2, -0x1
  stxdw [r3+0x8], r2
  ldxdw r2, [r3+0x0]
  mov64 r4, r2
  add64 r4, 0x30
  stxdw [r3+0x0], r4
  call fn_8e68
  ja jmp_fe78

jmp_fe20:
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x1], 0x7

jmp_fe78:
  exit

fn_fe80:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_10078
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  lddw r3, -0xe76dbb170da6874
  jne r2, r3, jmp_ff58
  ldxdw r2, [r7+0x8]
  lddw r3, -0x7cf271ebd6efc245
  jne r2, r3, jmp_ff58
  ldxdw r2, [r7+0x10]
  lddw r3, -0x7bef002566eca5f5
  jne r2, r3, jmp_ff58
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  lddw r4, 0x59f8e9dbd87b8e04
  jeq r3, r4, jmp_ff60

jmp_ff58:
  mov64 r2, 0x1

jmp_ff60:
  jeq r2, 0x0, jmp_100b0
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  lddw r1, -0xe76dbb170da6874
  stxdw [r10-0x20], r1
  lddw r1, -0x7cf271ebd6efc245
  stxdw [r10-0x18], r1
  lddw r1, -0x7bef002566eca5f5
  stxdw [r10-0x10], r1
  lddw r1, 0x59f8e9dbd87b8e04
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10108

jmp_10078:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10108

jmp_100b0:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_100d8
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10118

jmp_100d8:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10108:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10118:
  exit

fn_10120:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_102d0
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x0
  stdw [r10-0x38], 0x0
  stdw [r10-0x40], 0x0
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  jne r2, 0x0, jmp_101f0
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r10-0x38]
  jne r2, r3, jmp_101f0
  ldxdw r2, [r7+0x10]
  ldxdw r3, [r10-0x30]
  jne r2, r3, jmp_101f0
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  ldxdw r4, [r10-0x28]
  jeq r3, r4, jmp_101f8

jmp_101f0:
  mov64 r2, 0x1

jmp_101f8:
  jeq r2, 0x0, jmp_10308
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  stdw [r10-0x20], 0x0
  stdw [r10-0x18], 0x0
  stdw [r10-0x10], 0x0
  stdw [r10-0x8], 0x0
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10360

jmp_102d0:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10360

jmp_10308:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_10330
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10370

jmp_10330:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10360:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10370:
  exit

fn_10378:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_10570
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  lddw r3, -0xe76dbb170da6874
  jne r2, r3, jmp_10450
  ldxdw r2, [r7+0x8]
  lddw r3, -0x7cf271ebd6efc245
  jne r2, r3, jmp_10450
  ldxdw r2, [r7+0x10]
  lddw r3, -0x7bef002566eca5f5
  jne r2, r3, jmp_10450
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  lddw r4, 0x59f8e9dbd87b8e04
  jeq r3, r4, jmp_10458

jmp_10450:
  mov64 r2, 0x1

jmp_10458:
  jeq r2, 0x0, jmp_105a8
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  lddw r1, -0xe76dbb170da6874
  stxdw [r10-0x20], r1
  lddw r1, -0x7cf271ebd6efc245
  stxdw [r10-0x18], r1
  lddw r1, -0x7bef002566eca5f5
  stxdw [r10-0x10], r1
  lddw r1, 0x59f8e9dbd87b8e04
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10600

jmp_10570:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10600

jmp_105a8:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_105d0
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10610

jmp_105d0:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10600:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10610:
  exit

fn_10618:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_107c8
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x0
  stdw [r10-0x38], 0x0
  stdw [r10-0x40], 0x0
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  jne r2, 0x0, jmp_106e8
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r10-0x38]
  jne r2, r3, jmp_106e8
  ldxdw r2, [r7+0x10]
  ldxdw r3, [r10-0x30]
  jne r2, r3, jmp_106e8
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  ldxdw r4, [r10-0x28]
  jeq r3, r4, jmp_106f0

jmp_106e8:
  mov64 r2, 0x1

jmp_106f0:
  jeq r2, 0x0, jmp_10800
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  stdw [r10-0x20], 0x0
  stdw [r10-0x18], 0x0
  stdw [r10-0x10], 0x0
  stdw [r10-0x8], 0x0
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10858

jmp_107c8:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10858

jmp_10800:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_10828
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10868

jmp_10828:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10858:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10868:
  exit

fn_10870:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_10a68
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_10948
  ldxdw r2, [r7+0x8]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_10948
  ldxdw r2, [r7+0x10]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_10948
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  lddw r4, -0x56ff00817a0a73c6
  jeq r3, r4, jmp_10950

jmp_10948:
  mov64 r2, 0x1

jmp_10950:
  jeq r2, 0x0, jmp_10aa0
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  lddw r1, -0x6c5e9a281e0922fa
  stxdw [r10-0x20], r1
  lddw r1, -0x53861431b91e3427
  stxdw [r10-0x18], r1
  lddw r1, -0x6ec8a4a0127a4be4
  stxdw [r10-0x10], r1
  lddw r1, -0x56ff00817a0a73c6
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10af8

jmp_10a68:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10af8

jmp_10aa0:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_10ac8
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10b08

jmp_10ac8:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10af8:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10b08:
  exit

fn_10b10:
  mov64 r6, r1
  ldxdw r1, [r3+0x8]
  jeq r1, 0x0, jmp_10d08
  add64 r1, -0x1
  stxdw [r3+0x8], r1
  ldxdw r1, [r3+0x0]
  mov64 r2, r1
  add64 r2, 0x30
  stxdw [r3+0x0], r2
  ldxdw r7, [r1+0x0]
  ldxdw r2, [r7+0x0]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_10be8
  ldxdw r2, [r7+0x8]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_10be8
  ldxdw r2, [r7+0x10]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_10be8
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  lddw r4, -0x56ff00817a0a73c6
  jeq r3, r4, jmp_10bf0

jmp_10be8:
  mov64 r2, 0x1

jmp_10bf0:
  jeq r2, 0x0, jmp_10d40
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r2, 0xbc0
  call fn_c1978
  ldxdw r3, [r10-0x48]
  ldxdw r2, [r10-0x50]
  ldxdw r1, [r7+0x18]
  stxdw [r10-0x28], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0x30], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0x40], r1
  lddw r1, -0x6c5e9a281e0922fa
  stxdw [r10-0x20], r1
  lddw r1, -0x53861431b91e3427
  stxdw [r10-0x18], r1
  lddw r1, -0x6ec8a4a0127a4be4
  stxdw [r10-0x10], r1
  lddw r1, -0x56ff00817a0a73c6
  stxdw [r10-0x8], r1
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r4, r10
  add64 r4, -0x40
  call fn_be990
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x58]
  ja jmp_10d98

jmp_10d08:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0xbbd
  call fn_c1978
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x78]
  ja jmp_10d98

jmp_10d40:
  ldxb r2, [r1+0x2a]
  jeq r2, 0x0, jmp_10d68
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_10da8

jmp_10d68:
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r2, 0xbc1
  call fn_c1978
  ldxdw r1, [r10-0x70]
  ldxdw r2, [r10-0x68]

jmp_10d98:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_10da8:
  exit

fn_10db0:
  mov64 r6, r1
  ldxb r1, [r2+0x109]
  jgt r1, 0x1, jmp_110f8
  ldxb r1, [r2+0x108]
  mov64 r3, r1
  add64 r3, -0x1
  and64 r3, 0xff
  jge r3, 0x3, jmp_11290
  jgt r1, 0x2, jmp_115f0
  mov64 r3, r1
  mul64 r3, 0x4c
  mov64 r4, r3
  add64 r4, r2
  add64 r4, 0x20
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x0
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x0
  ldxdw r5, [r4+0x0]
  jne r5, 0x0, jmp_10ea0
  ldxdw r5, [r4+0x8]
  ldxdw r0, [r10-0xe8]
  jne r5, r0, jmp_10ea0
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r10-0xe0]
  jne r5, r0, jmp_10ea0
  mov64 r5, 0x0
  ldxdw r0, [r4+0x18]
  ldxdw r7, [r10-0xd8]
  jeq r0, r7, jmp_10ea8

jmp_10ea0:
  mov64 r5, 0x1

jmp_10ea8:
  jne r5, 0x0, jmp_10f60
  ldxdw r5, [r4+0x20]
  jne r5, 0x0, jmp_10ef0
  ldxdw r5, [r4+0x28]
  jne r5, 0x0, jmp_10ef0
  ldxdw r5, [r4+0x30]
  jne r5, 0x0, jmp_10ef0
  ldxdw r5, [r4+0x38]
  jeq r5, 0x0, jmp_11608

jmp_10ef0:
  mov64 r5, 0x1

jmp_10ef8:
  ldxw r0, [r4+0x40]
  or64 r5, r0
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jne r5, 0x0, jmp_10f60
  ldxb r5, [r4+0x48]
  jne r5, 0x0, jmp_10f60
  ldxb r5, [r4+0x47]
  jne r5, 0x0, jmp_10f60
  ldxh r5, [r4+0x44]
  jne r5, 0x0, jmp_10f60
  ldxb r4, [r4+0x46]
  jeq r4, 0x0, jmp_11438

jmp_10f60:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_11618
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_0978
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17a8
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0xb6
  stdw [r10-0xe0], 0x20
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x118]
  ja jmp_11420

jmp_110f8:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_11618
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_0978
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17a8
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0xab
  stdw [r10-0xe0], 0x20
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  ja jmp_11420

jmp_11290:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_11618
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_0978
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17a8
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0xb1
  stdw [r10-0xe0], 0x20
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]

jmp_11420:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_11430:
  exit

jmp_11438:
  mov64 r4, 0x98

jmp_11440:
  jeq r3, r4, jmp_115f0
  mov64 r5, r2
  add64 r5, r3
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x0
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x0
  ldxdw r0, [r5+0x6c]
  jne r0, 0x0, jmp_114d8
  ldxdw r0, [r5+0x74]
  ldxdw r7, [r10-0xe8]
  jne r0, r7, jmp_114d8
  ldxdw r0, [r5+0x7c]
  ldxdw r7, [r10-0xe0]
  jne r0, r7, jmp_114d8
  mov64 r0, 0x0
  ldxdw r5, [r5+0x84]
  ldxdw r7, [r10-0xd8]
  jeq r5, r7, jmp_114e0

jmp_114d8:
  mov64 r0, 0x1

jmp_114e0:
  jne r0, 0x0, jmp_10f60
  mov64 r5, r2
  add64 r5, r3
  ldxdw r0, [r5+0x8c]
  jne r0, 0x0, jmp_11538
  ldxdw r0, [r5+0x94]
  jne r0, 0x0, jmp_11538
  ldxdw r0, [r5+0x9c]
  jne r0, 0x0, jmp_11538
  ldxdw r0, [r5+0xa4]
  jeq r0, 0x0, jmp_115e0

jmp_11538:
  mov64 r0, 0x1

jmp_11540:
  ldxw r5, [r5+0xac]
  or64 r0, r5
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_10f60
  mov64 r5, r2
  add64 r5, r3
  ldxb r0, [r5+0xb4]
  jne r0, 0x0, jmp_10f60
  ldxb r0, [r5+0xb3]
  jne r0, 0x0, jmp_10f60
  ldxh r5, [r5+0xb0]
  jne r5, 0x0, jmp_10f60
  mov64 r5, r2
  add64 r5, r3
  add64 r2, 0x4c
  add64 r4, -0x4c
  ldxb r5, [r5+0xb2]
  jeq r5, 0x0, jmp_11440
  ja jmp_10f60

jmp_115e0:
  mov64 r0, 0x0
  ja jmp_11540

jmp_115f0:
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_11430

jmp_11608:
  mov64 r5, 0x0
  ja jmp_10ef8

jmp_11618:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_11668:
  ldxb r0, [r2+0x109]
  and64 r0, 0x1
  jne r0, 0x0, jmp_11838
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16f0
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16f0
  call fn_5a268
  jne r0, 0x0, jmp_11870
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_0978
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x17b7
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0xce
  stdw [r10-0xd8], 0x20
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r1, [r10-0xf8]
  ldxdw r2, [r10-0xf0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_11868

jmp_11838:
  ldxdw r0, [r5-0xff8]
  ldxdw r5, [r5-0x1000]
  stxdw [r10-0xff8], r0
  stxdw [r10-0x1000], r5
  mov64 r5, r10
  call fn_118c0

jmp_11868:
  exit

jmp_11870:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_118c0:
  mov64 r6, r5
  mov64 r9, r4
  stxdw [r10-0x1e8], r3
  mov64 r8, r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0xc0
  call fn_10db0
  ldxdw r1, [r10-0xc0]
  jne r1, 0x2, jmp_119a8
  ldxdw r4, [r10-0xb8]
  jeq r4, 0x0, jmp_13510
  ldxdw r2, [r6-0x1000]
  mov64 r1, r4
  add64 r1, -0x1
  jne r2, r1, jmp_119b8
  stxdw [r10-0x228], r2
  mov64 r1, 0x0
  mov64 r2, r4
  lsh64 r2, 0x5
  lddw r3, 0x7ffffffffffffff
  jgt r4, r3, jmp_11990
  lddw r3, 0x7ffffffffffffff8
  jle r2, r3, jmp_11b68

jmp_11990:
  lddw r3, data_6020
  call fn_cb038

jmp_119a8:
  ldxdw r2, [r10-0xb8]
  ja jmp_11b48

jmp_119b8:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_16e4
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  lddw r1, data_16e4
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17ac
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0xe4
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r10-0x158]

jmp_11b48:
  stxdw [r7+0x8], r2
  stxdw [r7+0x0], r1
  sth [r7+0x14], 0x2

jmp_11b60:
  exit

jmp_11b68:
  stxdw [r10-0x220], r4
  stxdw [r10-0x240], r7
  mov64 r7, r2
  ldxdw r1, [r6-0xff8]
  stxdw [r10-0x238], r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_11bd0
  mov64 r3, r1

jmp_11bd0:
  mov64 r1, r3
  mov64 r2, r7
  sub64 r1, r2
  mov64 r0, 0x0
  mov64 r4, 0x1
  jle r1, r3, jmp_12778
  ldxdw r3, [r10-0x220]
  jeq r4, 0x0, jmp_12790

jmp_11c10:
  lddw r1, 0x300000008
  jlt r0, r1, jmp_127b0

jmp_11c28:
  and64 r0, -0x8
  lddw r1, 0x300000000
  stxdw [r1+0x0], r0
  stxdw [r10-0x150], r3
  mov64 r3, 0x0
  add64 r9, -0x30
  mov64 r7, r8
  add64 r7, 0x40
  stxdw [r10-0x148], r0
  stdw [r10-0x140], 0x0
  mov64 r1, 0x0
  stxdw [r10-0x1f0], r1
  stxdw [r10-0x230], r8
  ja jmp_11d68

jmp_11ca0:
  mov64 r1, r0
  ldxdw r3, [r10-0x200]
  add64 r1, r3
  stxb [r1+0x18], r8
  ldxdw r2, [r10-0x1f8]
  stxh [r1+0x16], r2
  stxh [r1+0x14], r9
  ldxdw r2, [r10-0x218]
  stxw [r1+0x10], r2
  stxdw [r1+0x8], r5
  stxdw [r1+0x0], r6
  ldxw r2, [r10-0x137]
  stxw [r1+0x19], r2
  ldxw r2, [r10-0x134]
  stxw [r1+0x1c], r2
  ldxdw r9, [r10-0x210]
  add64 r9, 0x30
  add64 r7, 0x4c
  add64 r3, 0x20
  ldxdw r1, [r10-0x1f0]
  add64 r1, 0x1
  stxdw [r10-0x140], r1
  ldxdw r8, [r10-0x230]
  stxdw [r10-0x1f0], r1
  jeq r4, r1, jmp_12978

jmp_11d68:
  jeq r3, 0x60, jmp_13528
  ldxdw r2, [r10-0x1e8]
  stxdw [r10-0x200], r3
  jeq r3, 0x0, jmp_11db0
  ldxdw r1, [r10-0x1f0]
  add64 r1, -0x1
  mov64 r2, r9
  ldxdw r3, [r10-0x228]
  jge r1, r3, jmp_12b78

jmp_11db0:
  ldxdw r1, [r2+0x0]
  ldxdw r3, [r1+0x18]
  stxdw [r10-0xa8], r3
  ldxdw r3, [r1+0x10]
  stxdw [r10-0xb0], r3
  ldxdw r3, [r1+0x8]
  stxdw [r10-0xb8], r3
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xc0], r1
  ldxdw r3, [r7-0x20]
  jne r1, r3, jmp_11e58
  ldxdw r1, [r7-0x18]
  ldxdw r3, [r10-0xb8]
  jne r3, r1, jmp_11e58
  ldxdw r1, [r7-0x10]
  ldxdw r3, [r10-0xb0]
  jne r3, r1, jmp_11e58
  mov64 r1, 0x0
  ldxdw r3, [r7-0x8]
  ldxdw r4, [r10-0xa8]
  jeq r4, r3, jmp_11e60

jmp_11e58:
  mov64 r1, 0x1

jmp_11e60:
  jne r1, 0x0, jmp_127d0
  ldxb r1, [r7+0x27]
  jsgt r1, 0x2, jmp_11ee8
  jeq r1, 0x0, jmp_120c8
  jne r1, 0x1, jmp_11fc0
  lddw r3, -0x6cc41ec9d65332c1
  stxdw [r10-0x118], r3
  lddw r3, 0x7299832a665230e9
  stxdw [r10-0x120], r3
  lddw r3, -0x297bdac46b16b7e2
  stxdw [r10-0x128], r3
  lddw r3, -0x5d3e4a73274641fb
  ja jmp_12008

jmp_11ee8:
  mov64 r3, r1
  add64 r3, -0x4
  jge r3, 0x2, jmp_11f60
  lddw r3, -0x4886a17a3ed6b36e
  stxdw [r10-0x118], r3
  lddw r3, -0x7ec0aad0512fff5d
  stxdw [r10-0x120], r3
  lddw r3, 0x306871741f975c4a
  stxdw [r10-0x128], r3
  lddw r3, 0x5f9ff80ea6de9204
  ja jmp_12008

jmp_11f60:
  lddw r3, 0x256171d9548a2c1
  stxdw [r10-0x118], r3
  lddw r3, 0x378f775bcf2136d6
  stxdw [r10-0x120], r3
  lddw r3, 0x271f232c74455e71
  stxdw [r10-0x128], r3
  lddw r3, -0x452d942aa509b40f
  ja jmp_12008

jmp_11fc0:
  lddw r4, data_2b2d
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x118], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x120], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x128], r3
  ldxdw r3, [r4+0x0]

jmp_12008:
  stxdw [r10-0x130], r3
  ldxdw r3, [r10-0x118]
  stxdw [r10-0xf8], r3
  ldxdw r3, [r10-0x120]
  stxdw [r10-0x100], r3
  ldxdw r3, [r10-0x128]
  stxdw [r10-0x108], r3
  ldxdw r4, [r10-0x130]
  stxdw [r10-0x110], r4
  ldxdw r3, [r2+0x18]
  ldxdw r5, [r3+0x0]
  jne r5, r4, jmp_120b8
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r10-0x108]
  jne r4, r5, jmp_120b8
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r10-0x100]
  jne r4, r5, jmp_120b8
  mov64 r4, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r5, [r10-0xf8]
  jeq r3, r5, jmp_120c0

jmp_120b8:
  mov64 r4, 0x1

jmp_120c0:
  jne r4, 0x0, jmp_129e0

jmp_120c8:
  ldxw r3, [r7+0x20]
  stxdw [r10-0x208], r0
  jeq r3, 0x0, jmp_12150
  mov64 r4, r1
  lsh64 r4, 0x2
  lddw r5, data_2a70
  add64 r5, r4
  ldxw r5, [r5+0x0]
  jlt r5, r3, jmp_12120
  mov64 r5, r3

jmp_12120:
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r3+0x0]
  lddw r0, -0x5d3e4a73274641fb
  jeq r4, r0, jmp_12180
  ja jmp_121e8

jmp_12150:
  mov64 r5, 0xc8
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r3+0x0]
  lddw r0, -0x5d3e4a73274641fb
  jne r4, r0, jmp_121e8

jmp_12180:
  ldxdw r4, [r3+0x8]
  lddw r0, -0x297bdac46b16b7e2
  jne r4, r0, jmp_121e8
  ldxdw r4, [r3+0x10]
  lddw r0, 0x7299832a665230e9
  jne r4, r0, jmp_121e8
  mov64 r4, 0x0
  ldxdw r0, [r3+0x18]
  lddw r6, -0x6cc41ec9d65332c1
  jeq r0, r6, jmp_121f0

jmp_121e8:
  mov64 r4, 0x1

jmp_121f0:
  stxdw [r10-0x210], r9
  jeq r4, 0x0, jmp_12440
  lddw r4, data_2b2d
  ldxdw r4, [r4+0x0]
  ldxdw r0, [r3+0x0]
  jne r0, r4, jmp_122a8
  lddw r4, data_2b2d
  ldxdw r4, [r4+0x8]
  ldxdw r0, [r3+0x8]
  jne r0, r4, jmp_122a8
  lddw r4, data_2b2d
  ldxdw r4, [r4+0x10]
  ldxdw r0, [r3+0x10]
  jne r0, r4, jmp_122a8
  mov64 r4, 0x0
  lddw r0, data_2b2d
  ldxdw r0, [r0+0x18]
  ldxdw r6, [r3+0x18]
  jeq r6, r0, jmp_122b0

jmp_122a8:
  mov64 r4, 0x1

jmp_122b0:
  jeq r4, 0x0, jmp_124f0
  ldxdw r4, [r3+0x0]
  lddw r0, -0x452d942aa509b40f
  jne r4, r0, jmp_12340
  ldxdw r4, [r3+0x8]
  lddw r0, 0x271f232c74455e71
  jne r4, r0, jmp_12340
  ldxdw r4, [r3+0x10]
  lddw r0, 0x378f775bcf2136d6
  jne r4, r0, jmp_12340
  mov64 r4, 0x0
  ldxdw r0, [r3+0x18]
  lddw r6, 0x256171d9548a2c1
  jeq r0, r6, jmp_12348

jmp_12340:
  mov64 r4, 0x1

jmp_12348:
  jeq r4, 0x0, jmp_12520
  ldxdw r4, [r3+0x0]
  lddw r0, 0x5f9ff80ea6de9204
  jne r4, r0, jmp_123d8
  ldxdw r4, [r3+0x8]
  lddw r0, 0x306871741f975c4a
  jne r4, r0, jmp_123d8
  ldxdw r4, [r3+0x10]
  lddw r0, -0x7ec0aad0512fff5d
  jne r4, r0, jmp_123d8
  mov64 r4, 0x0
  ldxdw r3, [r3+0x18]
  lddw r0, -0x4886a17a3ed6b36e
  jeq r3, r0, jmp_123e0

jmp_123d8:
  mov64 r4, 0x1

jmp_123e0:
  jne r4, 0x0, jmp_13150
  jne r1, 0x5, jmp_125c8
  ldxb r1, [r7+0x26]
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r5, r10
  ldxdw r3, [r10-0x238]
  mov64 r4, r7
  call fn_48250
  ja jmp_12610

jmp_12440:
  ldxdw r1, [r7-0x20]
  ldxdw r3, [r7+0x0]
  jne r3, r1, jmp_124a8
  ldxdw r1, [r7-0x18]
  ldxdw r3, [r7+0x8]
  jne r3, r1, jmp_124a8
  ldxdw r1, [r7-0x10]
  ldxdw r3, [r7+0x10]
  jne r3, r1, jmp_124a8
  mov64 r1, 0x0
  ldxdw r3, [r7-0x8]
  ldxdw r4, [r7+0x18]
  jeq r4, r3, jmp_124b0

jmp_124a8:
  mov64 r1, 0x1

jmp_124b0:
  jne r1, 0x0, jmp_12fb0
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r3, r5
  call fn_41028
  ja jmp_12610

jmp_124f0:
  mov64 r1, r10
  add64 r1, -0xc0
  ldxdw r3, [r10-0x238]
  mov64 r4, r7
  call fn_40180
  ja jmp_12610

jmp_12520:
  ldxdw r1, [r7-0x20]
  ldxdw r3, [r7+0x0]
  jne r3, r1, jmp_12588
  ldxdw r1, [r7-0x18]
  ldxdw r3, [r7+0x8]
  jne r3, r1, jmp_12588
  ldxdw r1, [r7-0x10]
  ldxdw r3, [r7+0x10]
  jne r3, r1, jmp_12588
  mov64 r1, 0x0
  ldxdw r3, [r7-0x8]
  ldxdw r4, [r7+0x18]
  jeq r4, r3, jmp_12590

jmp_12588:
  mov64 r1, 0x1

jmp_12590:
  jne r1, 0x0, jmp_132e8
  mov64 r1, r10
  add64 r1, -0xc0
  ldxdw r3, [r10-0x238]
  mov64 r4, r5
  call fn_417d0
  ja jmp_12610

jmp_125c8:
  ldxb r1, [r7+0x26]
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r5, r10
  ldxdw r3, [r10-0x238]
  mov64 r4, r7
  call fn_47210

jmp_12610:
  ldxdw r5, [r10-0xb8]
  ldxh r9, [r10-0xac]
  jeq r9, 0x2, jmp_12968
  ldxdw r6, [r10-0xc0]
  ldxh r1, [r10-0xaa]
  stxdw [r10-0x1f8], r1
  ldxw r1, [r10-0xb0]
  stxdw [r10-0x218], r1
  mov64 r1, r9
  and64 r1, 0x1
  ldxdw r4, [r10-0x220]
  ldxdw r0, [r10-0x208]
  jeq r1, 0x0, jmp_126e8
  ldxh r1, [r7+0x24]
  mov64 r2, r1
  jge r1, 0x3e8, jmp_126b8
  mov64 r3, 0xc8
  jne r1, 0x0, jmp_126d0

jmp_126a0:
  ldxdw r1, [r10-0x1f8]
  jle r1, r3, jmp_126e8
  ja jmp_12d10

jmp_126b8:
  mov64 r2, 0x3e8
  mov64 r3, 0xc8
  jeq r1, 0x0, jmp_126a0

jmp_126d0:
  mov64 r3, r2
  ldxdw r1, [r10-0x1f8]
  jgt r1, r3, jmp_12d10

jmp_126e8:
  ldxb r8, [r7+0x28]
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x1f0]
  jne r2, r1, jmp_11ca0
  mov64 r1, r10
  add64 r1, -0x150
  lddw r2, data_6050
  stxdw [r10-0x208], r6
  mov64 r6, r7
  mov64 r7, r5
  call fn_bcc8
  mov64 r5, r7
  mov64 r7, r6
  ldxdw r6, [r10-0x208]
  ldxdw r4, [r10-0x220]
  ldxdw r0, [r10-0x148]
  ja jmp_11ca0

jmp_12778:
  mov64 r4, 0x0
  ldxdw r3, [r10-0x220]
  jne r4, 0x0, jmp_11c10

jmp_12790:
  mov64 r0, r1
  lddw r1, 0x300000008
  jge r0, r1, jmp_11c28

jmp_127b0:
  mov64 r1, 0x8
  lddw r3, data_6020
  call fn_cb038

jmp_127d0:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x177f
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x104
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x178]
  ldxdw r1, [r10-0x180]
  ja jmp_132c0

jmp_12968:
  ldxdw r1, [r10-0xc0]
  ja jmp_132c0

jmp_12978:
  ldxdw r2, [r10-0x148]
  mov64 r1, r10
  add64 r1, -0xc0
  ldxdw r3, [r10-0x1f0]
  call fn_3f538
  ldxdw r1, [r10-0xb8]
  ldxh r2, [r10-0xac]
  jne r2, 0x2, jmp_12e78
  ldxdw r2, [r10-0xc0]
  ldxdw r3, [r10-0x240]
  stxdw [r3+0x8], r1
  stxdw [r3+0x0], r2
  ja jmp_12d00

jmp_129e0:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16ec
  call fn_594a8
  stdw [r10-0xc8], 0x0
  stdw [r10-0xd0], 0x1
  stdw [r10-0xd8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16ec
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x90], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17ab
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x108
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x188]
  ldxdw r1, [r10-0x190]
  ja jmp_132c0

jmp_12b78:
  stw [r10-0xd8], 0x3c
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r6, r10
  add64 r6, -0xd8
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  stw [r10-0x28], 0x17ac
  stb [r10-0x70], 0x2
  stdw [r10-0xc0], 0x2
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]

jmp_12ce8:
  ldxdw r3, [r10-0x240]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1

jmp_12d00:
  sth [r3+0x14], 0x2
  ja jmp_11b60

jmp_12d10:
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16e8
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  lddw r1, data_16e8
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17ad
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x140
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x1d8]
  ldxdw r1, [r10-0x1e0]
  ja jmp_132c0

jmp_12e78:
  ldxdw r3, [r10-0xc0]
  ldxh r5, [r10-0xaa]
  ldxw r4, [r10-0xb0]
  mov64 r0, r2
  and64 r0, 0x1
  jeq r0, 0x0, jmp_13488
  ldxh r0, [r8+0x104]
  mov64 r6, r0
  jge r0, 0x3e8, jmp_13458
  mov64 r7, 0xc8
  jne r0, 0x0, jmp_13470

jmp_12ed0:
  mov64 r0, r5
  jle r0, r7, jmp_13488

jmp_12ee0:
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16e8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16e8
  call fn_9838
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0xf8
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  stw [r10-0x28], 0x17ad
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r1, [r10-0x1d0]
  ldxdw r2, [r10-0x1c8]
  ja jmp_12ce8

jmp_12fb0:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  lddw r1, data_1670
  call fn_5a268
  ldxdw r6, [r10-0x240]
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x177f
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x11d
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x1b8]
  ldxdw r1, [r10-0x1c0]
  ja jmp_132c8

jmp_13150:
  stw [r10-0xd8], 0xf
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r6, r10
  add64 r6, -0xd8
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  stw [r10-0x28], 0x177f
  stb [r10-0x70], 0x2
  stdw [r10-0xc0], 0x2
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x198]
  ldxdw r1, [r10-0x1a0]

jmp_132c0:
  ldxdw r6, [r10-0x240]

jmp_132c8:
  stxdw [r6+0x8], r5
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_11b60

jmp_132e8:
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x120], 0x0
  stdw [r10-0x128], 0x1
  stdw [r10-0x130], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x110], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x100], r1
  mov64 r2, r10
  add64 r2, -0x110
  lddw r1, data_1670
  call fn_5a268
  ldxdw r6, [r10-0x240]
  jne r0, 0x0, jmp_134c0
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x88], r1
  lddw r1, str_0978
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x177f
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x122
  stdw [r10-0xb0], 0x20
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r5, [r10-0x1a8]
  ldxdw r1, [r10-0x1b0]
  ja jmp_132c8

jmp_13458:
  mov64 r6, 0x3e8
  mov64 r7, 0xc8
  jeq r0, 0x0, jmp_12ed0

jmp_13470:
  mov64 r7, r6
  mov64 r0, r5
  jgt r0, r7, jmp_12ee0

jmp_13488:
  ldxdw r0, [r10-0x240]
  stxh [r0+0x16], r5
  stxh [r0+0x14], r2
  stxw [r0+0x10], r4
  stxdw [r0+0x8], r1
  stxdw [r0+0x0], r3
  ja jmp_11b60

jmp_134c0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_13510:
  lddw r1, data_6008
  call fn_d0810

jmp_13528:
  mov64 r1, 0x3
  mov64 r2, 0x3
  lddw r3, data_6038
  call fn_cc630

fn_13550:
  mov64 r9, r4
  mov64 r8, r3
  ldxdw r3, [r5-0xff8]
  jeq r3, 0x0, jmp_13730
  stxdw [r10-0x198], r1
  ldxdw r1, [r5-0x1000]
  ldxb r7, [r8+0x67]
  lsh64 r7, 0x1
  jge r1, r7, jmp_138d0
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_141f0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1724
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x45
  stdw [r10-0xe0], 0x23
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r2, [r10-0x178]
  ldxdw r6, [r10-0x180]
  ja jmp_141d0

jmp_13730:
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_141f0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1724
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x43
  stdw [r10-0xe0], 0x23
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r2, [r10-0x188]
  ldxdw r6, [r10-0x190]
  ja jmp_141d8

jmp_138d0:
  stxdw [r10-0x1b0], r1
  stxdw [r10-0x1b8], r3
  stxdw [r10-0x1a0], r2
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r8
  mov64 r3, r9
  mov64 r4, r7
  call fn_49240
  ldxdw r3, [r10-0xe0]
  ldxdw r6, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  lddw r2, -0x8000000000000000
  jne r1, r2, jmp_13958
  mov64 r2, r3
  ja jmp_141d0

jmp_13958:
  jeq r3, 0x0, jmp_13ad8
  mul64 r3, 0x12c
  div64 r3, 0x12c
  stxdw [r10-0x1a8], r3
  lsh64 r3, 0x3
  stxdw [r10-0x1c0], r3
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r5, 0x300008000
  jeq r1, 0x0, jmp_139c8
  mov64 r5, r1

jmp_139c8:
  mov64 r1, r5
  ldxdw r2, [r10-0x1c0]
  sub64 r1, r2
  mov64 r4, 0x0
  mov64 r3, 0x1
  jgt r1, r5, jmp_13a90
  mov64 r3, 0x0
  jeq r3, 0x0, jmp_13a98

jmp_13a08:
  lddw r1, 0x300000007
  jle r4, r1, jmp_13ab8

jmp_13a20:
  and64 r4, -0x8
  lddw r1, 0x300000000
  stxdw [r1+0x0], r4
  add64 r6, 0x20
  mov64 r1, r4
  ldxdw r3, [r10-0x1a8]
  mov64 r2, r3

jmp_13a60:
  stxdw [r1+0x0], r6
  add64 r6, 0x12c
  add64 r1, 0x8
  add64 r2, -0x1
  jne r2, 0x0, jmp_13a60
  ja jmp_13ae8

jmp_13a90:
  jne r3, 0x0, jmp_13a08

jmp_13a98:
  mov64 r4, r1
  lddw r1, 0x300000007
  jgt r4, r1, jmp_13a20

jmp_13ab8:
  mov64 r1, 0x8
  lddw r3, data_6068
  call fn_cb038

jmp_13ad8:
  mov64 r3, 0x0
  mov64 r4, 0x8

jmp_13ae8:
  stxdw [r10-0x1c0], r4
  stxdw [r10-0x128], r4
  stxdw [r10-0x120], r3
  stxdw [r10-0x1a8], r3
  stxdw [r10-0x130], r3
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r3, r10
  add64 r3, -0x130
  mov64 r2, r8
  mov64 r4, r9
  mov64 r5, r7
  call fn_4b620
  ldxdw r6, [r10-0xe0]
  ldxdw r3, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  lddw r2, -0x8000000000000000
  jne r1, r2, jmp_13b98
  mov64 r2, r6
  mov64 r6, r3
  ja jmp_141d0

jmp_13b98:
  mov64 r8, r3
  mov64 r1, r10
  add64 r1, -0xf0
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0xe8
  ldxdw r2, [r10-0xf0]
  jne r2, 0x1, jmp_13c48
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x108], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x110], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x118], r1
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0x118
  call fn_be7f0
  ldxdw r2, [r10-0x168]
  ldxdw r6, [r10-0x170]
  ja jmp_141d0

jmp_13c48:
  ldxdw r5, [r10-0x1b0]
  sub64 r5, r7
  mul64 r7, 0x30
  add64 r9, r7
  ldxdw r2, [r1+0x20]
  stxdw [r10-0xf8], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x100], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x108], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x110], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x118], r1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x118
  mov64 r3, r10
  add64 r3, -0x130
  mov64 r4, r9
  call fn_4a398
  ldxdw r3, [r10-0x10]
  ldxdw r7, [r10-0x18]
  ldxdw r1, [r10-0x20]
  lddw r2, -0x8000000000000000
  jne r1, r2, jmp_13d40
  mov64 r2, r3
  mov64 r6, r7
  ja jmp_141d0

jmp_13d40:
  stxdw [r10-0x1d0], r3
  ldxdw r1, [r10-0x1a0]
  ldxdw r2, [r10-0x1a8]
  stxb [r1+0x9e], r2
  stw [r1+0x98], -0x1
  stdw [r1+0x60], 0x0
  stdw [r1+0x68], 0x0
  stdw [r1+0x70], 0x0
  stdw [r1+0x78], 0x0
  stdw [r1+0x0], 0x0
  stdw [r1+0x8], 0x0
  stdw [r1+0x10], 0x0
  stdw [r1+0x18], 0x0
  stdw [r1+0x20], 0x0
  stdw [r1+0x28], 0x0
  stdw [r1+0x30], 0x0
  stdw [r1+0x38], 0x0
  mov64 r3, r8
  jeq r2, 0x0, jmp_141c8
  mov64 r2, 0x0
  stxdw [r10-0x1b0], r2
  mov64 r2, r10
  add64 r2, -0xd0
  stxdw [r10-0x1e0], r2
  mov64 r2, r10
  add64 r2, -0xb8
  stxdw [r10-0x1e8], r2
  mov64 r8, r1
  add64 r8, 0x8
  add64 r3, 0x60
  add64 r7, 0x10
  mov64 r9, 0x0
  stxdw [r10-0x1d8], r6

jmp_13e48:
  jeq r6, r9, jmp_14240
  ldxdw r2, [r1+0x90]
  stxdw [r10-0x1c8], r3
  ldxdw r4, [r3+0x0]
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r3, 0x0
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x150
  ldxdw r2, [r10-0x140]
  ldxdw r3, [r10-0x138]
  ldxdw r4, [r10-0x1b8]
  mov64 r5, 0x0
  call fn_d45f0
  ldxdw r1, [r10-0x148]
  jeq r1, 0x0, jmp_14088
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_16cc
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16cc
  call fn_5a268
  jne r0, 0x0, jmp_141f0
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x1e8]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0x30]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x38]
  stxdw [r2+0x0], r1
  ldxdw r1, [r10-0x40]
  ldxdw r2, [r10-0x1e0]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0x48]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r2+0x0], r1
  lddw r1, str_1724
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x59
  stdw [r10-0xe0], 0x23
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r2, [r10-0x158]
  ldxdw r6, [r10-0x160]
  jeq r6, 0x2, jmp_14090
  ja jmp_141d0

jmp_14088:
  ldxdw r2, [r10-0x150]

jmp_14090:
  jeq r9, 0x4, jmp_14290
  ldxdw r1, [r10-0x1c0]
  ldxdw r5, [r10-0x1b0]
  add64 r1, r5
  ldxdw r1, [r1+0x0]
  ldxb r1, [r1+0x107]
  ldxdw r4, [r10-0x1a0]
  mov64 r3, r4
  add64 r3, r9
  stxb [r3+0x98], r1
  mov64 r1, r4
  add64 r1, r5
  stxdw [r1+0x60], r2
  ldxdw r1, [r10-0x1d0]
  jeq r1, r9, jmp_14268
  ldxdw r4, [r7-0x8]
  ldxdw r3, [r7-0x10]
  ldxw r5, [r7+0x0]
  mov64 r1, r10
  add64 r1, -0xf0
  call fn_14b90
  ldxdw r2, [r10-0xe0]
  ldxdw r6, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  jne r1, 0x0, jmp_141d0
  stxdw [r8+0x0], r2
  stxdw [r8-0x8], r6
  ldxdw r1, [r10-0x1b0]
  add64 r1, 0x8
  stxdw [r10-0x1b0], r1
  add64 r8, 0x10
  ldxdw r3, [r10-0x1c8]
  add64 r3, 0xd0
  add64 r7, 0x18
  add64 r9, 0x1
  ldxdw r1, [r10-0x1a0]
  ldxdw r2, [r10-0x1a8]
  ldxdw r6, [r10-0x1d8]
  jlt r9, r2, jmp_13e48

jmp_141c8:
  mov64 r6, 0x2

jmp_141d0:
  ldxdw r7, [r10-0x198]

jmp_141d8:
  stxdw [r7+0x8], r2
  stxdw [r7+0x0], r6
  exit

jmp_141f0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_14240:
  mov64 r1, r9
  mov64 r2, r6
  lddw r3, data_6080
  call fn_cc630

jmp_14268:
  mov64 r1, r9
  ldxdw r2, [r10-0x1d0]
  lddw r3, data_60b0
  call fn_cc630

jmp_14290:
  mov64 r1, 0x4
  mov64 r2, 0x4
  lddw r3, data_6098
  call fn_cc630

fn_142b8:
  mov64 r6, r1
  ldxb r1, [r2+0x9e]
  jeq r1, 0x0, jmp_143f0
  mov64 r0, 0x0
  mov64 r7, r3
  and64 r7, 0xff
  ldxb r8, [r2+0x98]
  jne r8, r7, jmp_143e8

jmp_142f8:
  mov64 r1, r0
  lsh64 r1, 0x3
  mov64 r3, r2
  add64 r3, r1
  lsh64 r0, 0x4
  add64 r2, r0
  ldxdw r8, [r2+0x8]
  ldxdw r9, [r2+0x0]
  mov64 r1, r9
  or64 r1, r8
  ldxdw r7, [r3+0x60]
  jeq r1, 0x0, jmp_14918
  stxdw [r10-0x130], r4
  ldxdw r4, [r5+0x8]
  ldxdw r3, [r5+0x0]
  ldxw r5, [r5+0x10]
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r7
  stxdw [r10-0x138], r3
  stxdw [r10-0x140], r4
  stxdw [r10-0x148], r5
  call fn_14b90
  ldxdw r3, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  jne r1, 0x1, jmp_14628
  ldxdw r1, [r10-0xe0]
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r3
  ja jmp_14938

jmp_143e8:
  jne r1, 0x1, jmp_14578

jmp_143f0:
  stw [r10-0xf4], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_14940
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x128]
  ldxdw r2, [r10-0x120]

jmp_14560:
  stxdw [r6+0x8], r2

jmp_14568:
  stxdw [r6+0x0], r1
  ja jmp_14938

jmp_14578:
  mov64 r0, 0x1
  mov64 r7, r3
  and64 r7, 0xff
  ldxb r8, [r2+0x99]
  jeq r8, r7, jmp_142f8
  jeq r1, 0x2, jmp_143f0
  mov64 r0, 0x2
  mov64 r7, r3
  and64 r7, 0xff
  ldxb r8, [r2+0x9a]
  jeq r8, r7, jmp_142f8
  jeq r1, 0x3, jmp_143f0
  mov64 r0, 0x3
  and64 r3, 0xff
  ldxb r7, [r2+0x9b]
  jeq r7, r3, jmp_142f8
  jeq r1, 0x4, jmp_143f0
  mov64 r1, 0x4
  mov64 r2, 0x4
  lddw r3, data_60c8
  call fn_cc630

jmp_14628:
  mov64 r2, 0x1
  mov64 r1, 0x1
  jle r3, r9, jmp_14688
  mov64 r1, 0x0
  ldxdw r3, [r10-0xe0]
  ldxdw r4, [r10-0x130]
  jgt r3, r8, jmp_146a0

jmp_14660:
  jeq r3, r8, jmp_146b0

jmp_14668:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_14918
  ja jmp_146c0

jmp_14688:
  ldxdw r3, [r10-0xe0]
  ldxdw r4, [r10-0x130]
  jle r3, r8, jmp_14660

jmp_146a0:
  mov64 r2, 0x0
  jne r3, r8, jmp_14668

jmp_146b0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_14918

jmp_146c0:
  ldxdw r1, [r10-0x148]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r8
  ldxdw r4, [r10-0x138]
  call fn_4ef20
  ldxw r1, [r10-0xf0]
  jne r1, 0x1, jmp_148b0
  ldxw r8, [r10-0xec]
  stxw [r10-0xf4], r8
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_14940
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  add64 r8, 0x1770
  stxw [r10-0x58], r8
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x110]
  ja jmp_14560

jmp_148b0:
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x0, jmp_14908
  mov64 r1, r10
  add64 r1, -0x108
  call fn_14990
  ldxdw r7, [r10-0x100]
  ldxdw r1, [r10-0x108]
  ldxdw r4, [r10-0x130]
  jeq r1, 0x2, jmp_14918
  stxdw [r6+0x8], r7
  ja jmp_14568

jmp_14908:
  ldxdw r7, [r10-0xe8]
  ldxdw r4, [r10-0x130]

jmp_14918:
  jlt r7, r4, jmp_14928
  mov64 r7, r4

jmp_14928:
  stxdw [r6+0x8], r7
  stdw [r6+0x0], 0x2

jmp_14938:
  exit

jmp_14940:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_14990:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16cc
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16cc
  call fn_5a268
  jne r0, 0x0, jmp_14b40
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_1724
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x1780
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0x78
  stdw [r10-0xd8], 0x23
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r1, [r10-0xf8]
  ldxdw r2, [r10-0xf0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_14b40:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_14b90:
  mov64 r0, r3
  mov64 r6, r1
  mov64 r1, r0
  or64 r1, r4
  jeq r1, 0x0, jmp_14d98
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r4
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r7, 0x0
  mov64 r5, r10
  mov64 r3, 0x0
  mov64 r4, r0
  call fn_4e128
  ldxw r1, [r10-0xf0]
  jeq r1, 0x0, jmp_14f48
  ldxw r8, [r10-0xec]
  stxw [r10-0xf4], r8
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_14f78
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  add64 r8, 0x1770
  stxw [r10-0x58], r8
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x100]
  ja jmp_14f28

jmp_14d98:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_14f78
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1724
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x82
  stdw [r10-0xe0], 0x23
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x110]

jmp_14f28:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  mov64 r7, 0x1
  ja jmp_14f68

jmp_14f48:
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xe0]
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1

jmp_14f68:
  stxdw [r6+0x0], r7
  exit

jmp_14f78:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_14fc8:
  mov64 r6, r1
  mov64 r1, r3
  and64 r1, 0xff
  jeq r1, 0x0, jmp_151b8
  mov64 r4, 0x0
  ldxdw r7, [r2+0x10]
  ldxdw r1, [r2+0x8]

jmp_15000:
  jeq r7, r4, jmp_15330
  mov64 r5, r1
  add64 r5, r4
  add64 r4, 0x1
  mov64 r0, r3
  and64 r0, 0xff
  ldxb r5, [r5+0x0]
  jne r5, r0, jmp_15000
  stw [r10-0xf4], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_153c8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0x108]
  ja jmp_153b0

jmp_151b8:
  stw [r10-0xf4], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_153c8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x118]
  ja jmp_153b0

jmp_15330:
  ldxdw r4, [r2+0x0]
  jne r7, r4, jmp_15388
  mov64 r1, r2
  mov64 r8, r2
  lddw r2, data_60f8
  mov64 r9, r3
  call fn_bbb0
  mov64 r3, r9
  mov64 r2, r8
  ldxdw r1, [r2+0x8]

jmp_15388:
  add64 r1, r7
  stxb [r1+0x0], r3
  add64 r7, 0x1
  stxdw [r2+0x10], r7
  mov64 r2, 0x2

jmp_153b0:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r2
  exit

jmp_153c8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_15418:
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  jeq r1, 0x0, jmp_15508
  ldxdw r4, [r2+0x8]
  mov64 r5, r1

jmp_15440:
  jeq r5, 0x0, jmp_15690
  add64 r5, -0x1
  mov64 r0, r3
  and64 r0, 0xff
  ldxb r7, [r4+0x0]
  add64 r4, 0x1
  jne r7, r0, jmp_15440
  mov64 r0, 0x1
  jne r5, 0x0, jmp_154b0
  ja jmp_15698

jmp_15490:
  add64 r0, 0x1
  add64 r4, 0x1
  add64 r5, -0x1
  jeq r5, 0x0, jmp_15698

jmp_154b0:
  ldxb r7, [r4+0x0]
  mov64 r8, r3
  and64 r8, 0xff
  jeq r7, r8, jmp_15490
  mov64 r8, r4
  sub64 r8, r0
  stxb [r8+0x0], r7
  add64 r4, 0x1
  add64 r5, -0x1
  jne r5, 0x0, jmp_154b0
  ja jmp_15698

jmp_15508:
  mov64 r3, 0x0
  jlt r3, r1, jmp_156b8

jmp_15518:
  stw [r10-0xec], 0x1
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r7, r10
  add64 r7, -0xec
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_156d8
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  stw [r10-0x50], 0x1771
  stb [r10-0x98], 0x2
  stdw [r10-0xe8], 0x2
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r2, [r10-0xf8]
  ldxdw r1, [r10-0x100]
  ja jmp_156c0

jmp_15690:
  mov64 r0, 0x0

jmp_15698:
  mov64 r3, r1
  sub64 r3, r0
  stxdw [r2+0x10], r3
  jge r3, r1, jmp_15518

jmp_156b8:
  mov64 r1, 0x2

jmp_156c0:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_156d8:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_15728:
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  ldxdw r2, [r2+0x8]

jmp_15740:
  jeq r1, 0x0, jmp_15778
  add64 r1, -0x1
  ldxb r3, [r2+0x0]
  add64 r2, 0x1
  jne r3, 0x6, jmp_15740
  mov64 r1, 0x2
  ja jmp_158e8

jmp_15778:
  stw [r10-0xec], 0x0
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r7, r10
  add64 r7, -0xec
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_15900
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  stw [r10-0x50], 0x1770
  stb [r10-0x98], 0x2
  stdw [r10-0xe8], 0x2
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r2, [r10-0xf8]
  ldxdw r1, [r10-0x100]

jmp_158e8:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_15900:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_15950:
  mov64 r4, r2
  mov64 r2, 0x0
  ldxdw r8, [r1+0x10]
  ldxdw r6, [r1+0x8]
  mov64 r7, r6
  add64 r7, r8

jmp_15980:
  jeq r8, r2, jmp_159c0
  mov64 r1, r6
  add64 r1, r2
  add64 r2, 0x1
  ldxb r1, [r1+0x0]
  jne r1, 0x6, jmp_15980

jmp_159b0:
  mov64 r0, 0x1

jmp_159b8:
  exit

jmp_159c0:
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r3
  mov64 r3, r4
  call fn_1bf58
  mov64 r0, 0x0
  jeq r8, 0x0, jmp_159b8
  ldxdw r1, [r10-0x10]
  jeq r1, 0x0, jmp_159b8
  ldxdw r2, [r10-0x8]

jmp_15a10:
  ldxb r3, [r6+0x0]
  mov64 r4, r2
  mov64 r5, r1

jmp_15a28:
  jeq r4, 0x0, jmp_15a58
  add64 r4, -0x1
  ldxb r8, [r5+0x0]
  add64 r5, 0x1
  jne r8, r3, jmp_15a28
  ja jmp_159b0

jmp_15a58:
  add64 r6, 0x1
  jne r6, r7, jmp_15a10
  ja jmp_159b8

fn_15a70:
  mov64 r6, r1
  mov64 r9, 0x2
  jeq r4, 0x0, jmp_160c0
  ldxdw r1, [r5-0xff0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x100], r2
  ldxdw r7, [r2+0x0]
  add64 r7, 0x1
  mov64 r0, 0x1
  jeq r7, 0x0, jmp_15ad0
  mov64 r0, 0x0

jmp_15ad0:
  ldxdw r2, [r5-0xff8]
  ldxdw r8, [r5-0x1000]
  ldxdw r5, [r1+0x0]
  stxdw [r10-0x110], r5
  ldxdw r5, [r10-0x100]
  stxdw [r5+0x0], r7
  jeq r0, 0x1, jmp_160d8
  ldxdw r7, [r1+0x10]
  ldxdw r0, [r7+0x0]
  add64 r0, 0x1
  mov64 r5, 0x1
  jeq r0, 0x0, jmp_15b38
  mov64 r5, 0x0

jmp_15b38:
  stxdw [r7+0x0], r0
  jeq r5, 0x1, jmp_160d8
  stxdw [r10-0x118], r3
  stxdw [r10-0x120], r7
  ldxdw r7, [r8+0x0]
  ldxdw r0, [r7+0x8]
  ldxdw r3, [r0+0x0]
  add64 r3, 0x1
  mov64 r5, 0x1
  jeq r3, 0x0, jmp_15b90
  mov64 r5, 0x0

jmp_15b90:
  ldxb r8, [r1+0x2a]
  stxdw [r10-0x140], r8
  ldxb r8, [r1+0x29]
  stxdw [r10-0x138], r8
  ldxb r8, [r1+0x28]
  stxdw [r10-0x130], r8
  ldxdw r8, [r1+0x20]
  stxdw [r10-0x128], r8
  ldxdw r1, [r1+0x18]
  stxdw [r10-0x148], r1
  ldxdw r1, [r7+0x0]
  stxdw [r0+0x0], r3
  jeq r5, 0x1, jmp_160d8
  stxdw [r10-0x150], r1
  ldxdw r5, [r7+0x10]
  ldxdw r1, [r5+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_15c30
  mov64 r3, 0x0

jmp_15c30:
  stxdw [r5+0x0], r1
  jeq r3, 0x1, jmp_160d8
  ldxdw r1, [r2+0x0]
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x108], r2
  ldxdw r2, [r2+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_15c80
  mov64 r3, 0x0

jmp_15c80:
  ldxb r8, [r7+0x2a]
  stxdw [r10-0x178], r8
  ldxb r8, [r7+0x29]
  stxdw [r10-0x170], r8
  ldxb r8, [r7+0x28]
  stxdw [r10-0x168], r8
  ldxdw r8, [r7+0x20]
  stxdw [r10-0x160], r8
  ldxdw r7, [r7+0x18]
  stxdw [r10-0x158], r7
  ldxdw r8, [r1+0x0]
  ldxdw r7, [r10-0x108]
  stxdw [r7+0x0], r2
  jeq r3, 0x1, jmp_160d8
  ldxdw r7, [r1+0x10]
  ldxdw r2, [r7+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_15d20
  mov64 r3, 0x0

jmp_15d20:
  stxdw [r7+0x0], r2
  jeq r3, 0x1, jmp_160d8
  stxdw [r10-0x188], r5
  stxdw [r10-0x180], r4
  ldxdw r2, [r10-0x118]
  ldxdw r4, [r2+0x0]
  ldxdw r3, [r4+0x8]
  ldxdw r2, [r3+0x0]
  add64 r2, 0x1
  mov64 r5, 0x1
  jeq r2, 0x0, jmp_15d80
  mov64 r5, 0x0

jmp_15d80:
  ldxb r9, [r1+0x2a]
  stxdw [r10-0x1a0], r9
  ldxb r9, [r1+0x29]
  stxdw [r10-0x198], r9
  ldxb r9, [r1+0x28]
  stxdw [r10-0x190], r9
  ldxdw r9, [r1+0x20]
  stxdw [r10-0x118], r9
  ldxdw r1, [r1+0x18]
  ldxdw r9, [r4+0x0]
  stxdw [r3+0x0], r2
  jeq r5, 0x1, jmp_160d8
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r4+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r5, 0x1
  jeq r2, 0x0, jmp_15e18
  mov64 r5, 0x0

jmp_15e18:
  stxdw [r1+0x0], r2
  jeq r5, 0x1, jmp_160d8
  ldxdw r2, [r4+0x18]
  ldxdw r5, [r4+0x20]
  stxdw [r10-0x1b8], r8
  stxdw [r10-0x1b0], r0
  ldxb r0, [r4+0x28]
  mov64 r8, r7
  mov64 r7, r9
  mov64 r9, r6
  ldxb r6, [r4+0x29]
  ldxb r4, [r4+0x2a]
  stxb [r10-0x16], r4
  stxb [r10-0x17], r6
  mov64 r6, r9
  mov64 r9, 0x2
  stxb [r10-0x18], r0
  stxdw [r10-0x20], r5
  stxdw [r10-0x28], r2
  stxdw [r10-0x30], r1
  stxdw [r10-0x38], r3
  stxdw [r10-0x40], r7
  ldxdw r1, [r10-0x1a0]
  stxb [r10-0x46], r1
  ldxdw r1, [r10-0x198]
  stxb [r10-0x47], r1
  ldxdw r1, [r10-0x190]
  stxb [r10-0x48], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x1a8]
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r8
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x178]
  stxb [r10-0x76], r1
  ldxdw r1, [r10-0x170]
  stxb [r10-0x77], r1
  ldxdw r1, [r10-0x168]
  stxb [r10-0x78], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x188]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x150]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x140]
  stxb [r10-0xa6], r1
  ldxdw r1, [r10-0x138]
  stxb [r10-0xa7], r1
  ldxdw r1, [r10-0x130]
  stxb [r10-0xa8], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0xd0], r1
  stdw [r10-0x8], 0x0
  stdw [r10-0x10], 0x8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x8
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  ldxdw r3, [r10-0x180]
  call fn_b7360
  ldxdw r2, [r10-0xf8]
  jeq r2, 0x2, jmp_160c0
  ldxdw r1, [r10-0xf0]
  mov64 r9, r2
  ja jmp_160c0

jmp_160c0:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r9
  exit

jmp_160d8:
  call abort

fn_160e0:
  mov64 r6, r5
  mov64 r7, r4
  stxdw [r10-0x788], r3
  mov64 r9, r2
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, 0x0
  mov64 r3, 0x0
  call fn_b3090
  ldxdw r1, [r10-0x2c0]
  jeq r1, 0x0, jmp_16298
  ldxdw r1, [r6-0xff0]
  stxdw [r10-0x7b0], r1
  ldxdw r1, [r6-0xff8]
  stxdw [r10-0x840], r1
  ldxdw r6, [r6-0x1000]
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x5a8], r1
  ldxdw r1, [r10-0x2a8]
  stxdw [r10-0x5b0], r1
  ldxdw r1, [r10-0x2b0]
  stxdw [r10-0x5b8], r1
  ldxdw r1, [r10-0x2b8]
  stxdw [r10-0x5c0], r1
  ldxb r5, [r9+0x67]
  stxdw [r10-0x7d8], r9
  stxdw [r10-0x798], r5
  jeq r5, 0x0, jmp_16468
  mov64 r9, r7
  mov64 r7, r5
  lsh64 r7, 0x5
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r2, 0x300008000
  jeq r1, 0x0, jmp_16220
  mov64 r2, r1

jmp_16220:
  mov64 r1, r2
  sub64 r1, r7
  mov64 r0, 0x0
  mov64 r3, 0x1
  jgt r1, r2, jmp_16410
  mov64 r3, 0x0
  ldxdw r5, [r10-0x798]
  jeq r3, 0x0, jmp_16420

jmp_16260:
  lddw r1, 0x300000008
  jlt r0, r1, jmp_16440

jmp_16278:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r0
  ja jmp_16478

jmp_16298:
  stw [r10-0x68], 0x10
  mov64 r1, r10
  add64 r1, -0x588
  mov64 r6, r10
  add64 r6, -0x68
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x580]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x578]
  stxdw [r10-0x290], r1
  stw [r10-0x228], 0x1780
  stb [r10-0x270], 0x2
  stdw [r10-0x2c0], 0x2
  mov64 r1, r10
  add64 r1, -0x5e0
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x5e0]
  ldxdw r2, [r10-0x5d8]
  ja jmp_17db8

jmp_16410:
  ldxdw r5, [r10-0x798]
  jne r3, 0x0, jmp_16260

jmp_16420:
  mov64 r0, r1
  lddw r1, 0x300000008
  jge r0, r1, jmp_16278

jmp_16440:
  mov64 r1, 0x1
  mov64 r2, r7
  lddw r3, data_6128
  call fn_cb038

jmp_16468:
  mov64 r0, 0x1
  mov64 r9, r7

jmp_16478:
  mov64 r7, r8
  stxdw [r10-0x598], r0
  stxdw [r10-0x5a0], r5
  stdw [r10-0x590], 0x0
  stxdw [r10-0x790], r9
  mov64 r4, 0x2
  jeq r9, 0x0, jmp_17b70
  mov64 r1, 0x0
  stxdw [r10-0x7d0], r1
  mov64 r1, r10
  add64 r1, -0x2b8
  stxdw [r10-0x8c8], r1
  mov64 r1, r10
  add64 r1, -0x2bf
  stxdw [r10-0x8b8], r1
  mov64 r1, r10
  add64 r1, -0x44
  stxdw [r10-0x8a8], r1
  mov64 r1, r10
  add64 r1, -0x2bc
  stxdw [r10-0x8b0], r1
  mov64 r1, r10
  add64 r1, -0xa4
  stxdw [r10-0x870], r1
  mov64 r1, r10
  add64 r1, -0x4d4
  stxdw [r10-0x850], r1
  mov64 r1, r10
  add64 r1, -0x2b8
  stxdw [r10-0x848], r1
  mov64 r1, r10
  add64 r1, -0x4fc
  stxdw [r10-0x7e8], r1
  mov64 r1, r10
  add64 r1, -0x51b
  stxdw [r10-0x7f0], r1
  mov64 r1, r10
  add64 r1, -0x540
  stxdw [r10-0x7f8], r1
  mov64 r1, r10
  add64 r1, -0x584
  stxdw [r10-0x800], r1
  mov64 r1, r10
  add64 r1, -0x234
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x253
  stxdw [r10-0x810], r1
  mov64 r1, r10
  add64 r1, -0x278
  stxdw [r10-0x818], r1
  mov64 r1, r10
  add64 r1, -0x2bc
  stxdw [r10-0x820], r1
  ldxdw r1, [r10-0x7b0]
  ldxb r1, [r1+0x0]
  ldxdw r2, [r6+0x68]
  stxdw [r10-0x7c8], r2
  lddw r3, -0x6c5e9a281e0922fa
  and64 r1, 0x1
  stxdw [r10-0x8c0], r1
  mov64 r6, 0x0
  mov64 r9, 0x0
  stxdw [r10-0x7a0], r7

jmp_16680:
  mov64 r5, r9
  add64 r5, 0x4
  mov64 r1, 0x1
  jlt r5, r9, jmp_166a8
  mov64 r1, 0x0

jmp_166a8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_19720
  ldxdw r1, [r10-0x790]
  jgt r5, r1, jmp_18110
  stxdw [r10-0x890], r4
  mov64 r8, r9
  add64 r8, 0x1
  jge r8, r1, jmp_19738
  mov64 r7, r9
  add64 r7, 0x2
  jge r7, r1, jmp_19760
  mov64 r2, r9
  add64 r2, 0x3
  stxdw [r10-0x7e0], r2
  jge r2, r1, jmp_19788
  stxdw [r10-0x888], r9
  mul64 r9, 0x30
  ldxdw r2, [r10-0x788]
  add64 r2, r9
  stxdw [r10-0x7b8], r2
  ldxdw r1, [r2+0x18]
  ldxdw r2, [r1+0x0]
  jne r2, r3, jmp_167c8
  ldxdw r2, [r1+0x8]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_167c8
  ldxdw r2, [r1+0x10]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_167c8
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  lddw r3, -0x56ff00817a0a73c6
  jeq r1, r3, jmp_167d0

jmp_167c8:
  mov64 r2, 0x1

jmp_167d0:
  jne r2, 0x0, jmp_182c0
  ldxdw r1, [r10-0x7b8]
  ldxdw r9, [r1+0x10]
  ldxdw r1, [r9+0x10]
  lddw r2, 0x7fffffffffffffff
  jge r1, r2, jmp_18458
  stxdw [r10-0x828], r7
  stxdw [r10-0x880], r5
  stxdw [r10-0x7c0], r6
  stxdw [r10-0x7a8], r0
  mov64 r7, r9
  add64 r7, 0x10
  add64 r1, 0x1
  stxdw [r9+0x10], r1
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r9+0x20]
  stxdw [r10-0x80], r2
  stxdw [r10-0x88], r1
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x88
  call fn_b9170
  ldxw r6, [r10-0x238]
  jeq r6, 0x2, jmp_184f0
  stxdw [r10-0x830], r9
  ldxw r9, [r10-0x2c0]
  ldxdw r1, [r10-0x800]
  ldxdw r2, [r10-0x820]
  mov64 r3, 0x3c
  call fn_d23d0
  ldxdw r3, [r10-0x818]
  ldxdw r1, [r3+0x0]
  ldxdw r5, [r10-0x280]
  ldxdw r2, [r10-0x7f8]
  stxdw [r2+0x0], r1
  ldxdw r1, [r3+0x8]
  stxdw [r2+0x8], r1
  ldxdw r1, [r3+0x10]
  stxdw [r2+0x10], r1
  ldxdw r1, [r3+0x18]
  stxdw [r2+0x18], r1
  ldxw r1, [r3+0x20]
  stxw [r2+0x20], r1
  ldxdw r4, [r10-0x810]
  ldxw r2, [r4+0x17]
  ldxb r1, [r10-0x254]
  ldxdw r3, [r10-0x7f0]
  stxw [r3+0x17], r2
  ldxdw r2, [r4+0x10]
  stxdw [r3+0x10], r2
  ldxdw r2, [r4+0x8]
  stxdw [r3+0x8], r2
  ldxdw r2, [r4+0x0]
  stxdw [r3+0x0], r2
  ldxdw r4, [r10-0x808]
  ldxdw r2, [r4+0x0]
  ldxdw r3, [r10-0x7e8]
  stxdw [r3+0x0], r2
  ldxdw r2, [r4+0x8]
  stxdw [r3+0x8], r2
  ldxdw r2, [r4+0x10]
  stxdw [r3+0x10], r2
  ldxdw r2, [r4+0x18]
  stxdw [r3+0x18], r2
  ldxw r2, [r4+0x20]
  stxw [r3+0x20], r2
  stxw [r10-0x500], r6
  stxw [r10-0x588], r9
  stxdw [r10-0x898], r5
  stxdw [r10-0x548], r5
  stxb [r10-0x51c], r1
  ldxdw r2, [r7+0x0]
  add64 r2, -0x1
  stxdw [r10-0x8d0], r7
  stxdw [r7+0x0], r2
  ldxdw r2, [r10-0x7c8]
  ldxdw r2, [r2+0x0]
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x2a8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x2b0], r3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x2b8], r3
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x2c0], r2
  ldxdw r3, [r10-0x568]
  jne r3, r2, jmp_16ae8
  ldxdw r2, [r10-0x2b8]
  ldxdw r3, [r10-0x560]
  jne r3, r2, jmp_16ae8
  ldxdw r2, [r10-0x2b0]
  ldxdw r3, [r10-0x558]
  jne r3, r2, jmp_16ae8
  mov64 r2, 0x0
  ldxdw r3, [r10-0x2a8]
  ldxdw r4, [r10-0x550]
  jeq r4, r3, jmp_16af0

jmp_16ae8:
  mov64 r2, 0x1

jmp_16af0:
  ldxdw r9, [r10-0x7a0]
  jne r2, 0x0, jmp_18520
  jeq r1, 0x2, jmp_186b8
  mul64 r8, 0x30
  ldxdw r7, [r10-0x788]
  add64 r7, r8
  ldxdw r1, [r7+0x18]
  ldxdw r2, [r1+0x0]
  lddw r3, 0x5f9ff80ea6de9204
  jne r2, r3, jmp_16bb0
  ldxdw r2, [r1+0x8]
  lddw r3, 0x306871741f975c4a
  jne r2, r3, jmp_16bb0
  ldxdw r2, [r1+0x10]
  lddw r3, -0x7ec0aad0512fff5d
  jne r2, r3, jmp_16bb0
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  lddw r3, -0x4886a17a3ed6b36e
  jeq r1, r3, jmp_16bb8

jmp_16bb0:
  mov64 r2, 0x1

jmp_16bb8:
  jne r2, 0x0, jmp_18850
  ldxdw r6, [r7+0x10]
  ldxdw r1, [r6+0x10]
  lddw r2, 0x7fffffffffffffff
  jge r1, r2, jmp_189e8
  mov64 r2, r6
  add64 r2, 0x10
  stxdw [r10-0x838], r2
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  ldxdw r1, [r6+0x18]
  ldxdw r2, [r6+0x20]
  stxdw [r10-0x18], r2
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x20
  call fn_54108
  ldxw r1, [r10-0x2c0]
  jeq r1, 0x1, jmp_18a78
  stxdw [r10-0x8a0], r7
  ldxw r8, [r10-0x2bc]
  mov64 r1, r10
  add64 r1, -0x3c8
  ldxdw r2, [r10-0x848]
  mov64 r3, 0x103
  call fn_d23d0
  ldxb r7, [r10-0x1b2]
  jeq r7, 0x2, jmp_190d0
  ldxb r1, [r10-0x1b1]
  stxdw [r10-0x860], r1
  ldxh r1, [r10-0x1b4]
  stxdw [r10-0x858], r1
  mov64 r9, r8
  ldxb r8, [r10-0x1b5]
  mov64 r1, r10
  add64 r1, -0x1ac
  stxdw [r10-0x868], r1
  mov64 r2, r10
  add64 r2, -0x3c8
  mov64 r3, 0x103
  call fn_d23d0
  stxdw [r10-0x878], r9
  stxw [r10-0x4d8], r9
  ldxdw r1, [r10-0x850]
  ldxdw r2, [r10-0x868]
  mov64 r3, 0x103
  call fn_d23d0
  ldxdw r1, [r10-0x860]
  stxb [r10-0x3cd], r1
  stxb [r10-0x3ce], r7
  ldxdw r1, [r10-0x858]
  stxh [r10-0x3d0], r1
  stxb [r10-0x3d1], r8
  ldxdw r2, [r10-0x838]
  ldxdw r1, [r2+0x0]
  add64 r1, -0x1
  stxdw [r2+0x0], r1
  ldxdw r1, [r10-0x798]
  jge r1, 0x5, jmp_19700
  ldxdw r5, [r10-0x7d8]
  ldxdw r7, [r10-0x7d0]
  jeq r1, 0x0, jmp_17f78
  ldxdw r4, [r10-0x828]
  mul64 r4, 0x30
  ldxdw r2, [r10-0x788]
  mov64 r3, r2
  add64 r3, r4
  stxdw [r10-0x828], r3
  ldxdw r3, [r10-0x7e0]
  mul64 r3, 0x30
  add64 r2, r3
  stxdw [r10-0x7e0], r2
  ldxdw r9, [r10-0x830]
  add64 r9, 0x18
  add64 r6, 0x18
  mov64 r0, 0x40

jmp_16e30:
  mov64 r2, r5
  add64 r2, r0
  ldxb r2, [r2+0x0]
  mov64 r3, r8
  jeq r2, r3, jmp_16e78
  mov64 r4, r0
  add64 r4, -0x3f
  add64 r0, 0x1
  jlt r4, r1, jmp_16e30

jmp_16e78:
  jne r2, r3, jmp_17f78
  stxdw [r10-0x858], r6
  ldxdw r1, [r10-0x878]
  stxw [r10-0xa8], r1
  ldxw r1, [r10-0x194]
  ldxdw r2, [r10-0x870]
  stxw [r2+0x18], r1
  ldxdw r1, [r10-0x19c]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0x1a4]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x1ac]
  stxdw [r2+0x0], r1
  mov64 r1, 0x0
  ldxdw r8, [r10-0x7a0]
  ldxdw r5, [r10-0x7a8]
  ldxdw r6, [r10-0x7c0]

jmp_16f00:
  jeq r7, r1, jmp_16fa0
  mov64 r2, r5
  add64 r2, r1
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r10-0xa8]
  jne r3, r4, jmp_16f80
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0xa0]
  jne r3, r4, jmp_16f80
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r10-0x98]
  jne r3, r4, jmp_16f80
  mov64 r3, 0x0
  ldxdw r2, [r2+0x18]
  ldxdw r4, [r10-0x90]
  jeq r2, r4, jmp_16f88

jmp_16f80:
  mov64 r3, 0x1

jmp_16f88:
  add64 r1, 0x20
  jne r3, 0x0, jmp_16f00
  ja jmp_17c28

jmp_16fa0:
  ldxdw r1, [r10-0x5a0]
  jne r6, r1, jmp_16fe0
  mov64 r1, r10
  add64 r1, -0x5a0
  lddw r2, data_61a0
  call fn_ba48
  ldxdw r5, [r10-0x598]

jmp_16fe0:
  mov64 r1, r6
  lsh64 r1, 0x5
  mov64 r2, r5
  add64 r2, r1
  ldxdw r1, [r10-0x90]
  stxdw [r2+0x18], r1
  ldxdw r1, [r10-0x98]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r2+0x0], r1
  add64 r6, 0x1
  stxdw [r10-0x590], r6
  ldxdw r1, [r10-0x588]
  ldxdw r2, [r10-0x4d8]
  ldxdw r7, [r10-0x8a0]
  jne r2, r1, jmp_170c0
  ldxdw r1, [r10-0x580]
  ldxdw r2, [r10-0x4d0]
  jne r2, r1, jmp_170c0
  ldxdw r1, [r10-0x578]
  ldxdw r2, [r10-0x4c8]
  jne r2, r1, jmp_170c0
  mov64 r1, 0x0
  ldxdw r2, [r10-0x570]
  ldxdw r3, [r10-0x4c0]
  jeq r3, r2, jmp_170c8

jmp_170c0:
  mov64 r1, 0x1

jmp_170c8:
  jne r1, 0x0, jmp_18aa8
  stxdw [r10-0x7a8], r5
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x58], r1
  lddw r1, str_1770
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0x3c0], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x3c8], r1
  stdw [r10-0x50], 0x20
  stdw [r10-0x60], 0x5
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x68
  mov64 r3, 0x2
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x2a8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x2b0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x2b8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x2c0]
  stxdw [r10-0x88], r1
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x2a8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2b0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x2b8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2c0], r1
  ldxdw r2, [r10-0x88]
  jne r1, r2, jmp_17280
  ldxdw r1, [r10-0x80]
  ldxdw r2, [r10-0x2b8]
  jne r2, r1, jmp_17280
  ldxdw r1, [r10-0x78]
  ldxdw r2, [r10-0x2b0]
  jne r2, r1, jmp_17280
  mov64 r1, 0x0
  ldxdw r2, [r10-0x70]
  ldxdw r3, [r10-0x2a8]
  jeq r3, r2, jmp_17288

jmp_17280:
  mov64 r1, 0x1

jmp_17288:
  jne r1, 0x0, jmp_18df8
  ldxdw r1, [r10-0x7c8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x2a8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2b0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x2b8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2c0], r1
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r10
  add64 r2, -0x2c0
  mov64 r3, r10
  add64 r3, -0x4d8
  call fn_bc628
  ldxdw r1, [r10-0x7b8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x2a8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2b0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x2b8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2c0], r1
  ldxdw r2, [r10-0x68]
  jne r1, r2, jmp_173c8
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x2b8]
  jne r2, r1, jmp_173c8
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x2b0]
  jne r2, r1, jmp_173c8
  mov64 r1, 0x0
  ldxdw r2, [r10-0x50]
  ldxdw r3, [r10-0x2a8]
  jeq r3, r2, jmp_173d0

jmp_173c8:
  mov64 r1, 0x1

jmp_173d0:
  jne r1, 0x0, jmp_18ec8
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x4d8
  call fn_10db0
  ldxdw r2, [r10-0x2c0]
  jne r2, 0x2, jmp_18f98
  ldxdw r7, [r10-0x2b8]
  jeq r7, 0x0, jmp_197c8
  add64 r7, -0x1
  ldxdw r3, [r10-0x880]
  mov64 r1, r3
  add64 r1, r7
  mov64 r2, 0x1
  jlt r1, r3, jmp_17458
  mov64 r2, 0x0

jmp_17458:
  and64 r2, 0x1
  jne r2, 0x0, jmp_197b0
  ldxdw r2, [r10-0x790]
  jgt r1, r2, jmp_18fc0
  stxdw [r10-0x830], r9
  ldxdw r2, [r10-0x840]
  stxdw [r10-0xff8], r2
  sub64 r1, r3
  stxdw [r10-0x1000], r1
  mul64 r3, 0x30
  ldxdw r4, [r10-0x788]
  add64 r4, r3
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x4d8
  mov64 r5, r10
  ldxdw r3, [r10-0x828]
  call fn_11668
  ldxh r9, [r10-0x2ac]
  jeq r9, 0x2, jmp_19090
  ldxdw r2, [r10-0x8b0]
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x30], r1
  ldxdw r2, [r2+0x8]
  stxdw [r10-0x28], r2
  ldxw r0, [r10-0x2c0]
  stxw [r10-0x48], r0
  ldxh r4, [r10-0x2aa]
  ldxdw r3, [r10-0x8a8]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  stxh [r10-0x34], r9
  stxdw [r10-0x7b8], r4
  stxh [r10-0x32], r4
  ldxdw r5, [r10-0x7e0]
  ldxdw r1, [r5+0x18]
  ldxdw r2, [r1+0x0]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_17608
  ldxdw r2, [r1+0x8]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_17608
  ldxdw r2, [r1+0x10]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_17608
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  lddw r3, -0x56ff00817a0a73c6
  jeq r1, r3, jmp_17610

jmp_17608:
  mov64 r2, 0x1

jmp_17610:
  ldxdw r4, [r10-0x8e0]
  jne r2, 0x0, jmp_19288
  ldxdw r1, [r5+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x2a8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2b0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x2b8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2c0], r1
  ldxdw r2, [r10-0x4d8]
  jne r1, r2, jmp_176c8
  ldxdw r1, [r10-0x4d0]
  ldxdw r2, [r10-0x2b8]
  jne r2, r1, jmp_176c8
  ldxdw r1, [r10-0x4c8]
  ldxdw r2, [r10-0x2b0]
  jne r2, r1, jmp_176c8
  mov64 r1, 0x0
  ldxdw r2, [r10-0x4c0]
  ldxdw r3, [r10-0x2a8]
  jeq r3, r2, jmp_176d0

jmp_176c8:
  mov64 r1, 0x1

jmp_176d0:
  jne r1, 0x0, jmp_19358
  stxdw [r10-0x7c0], r6
  ldxdw r6, [r5+0x10]
  ldxdw r1, [r6+0x10]
  lddw r2, 0x7fffffffffffffff
  jge r1, r2, jmp_19428
  stxdw [r10-0x7e0], r9
  mov64 r9, r0
  mov64 r2, r6
  add64 r2, 0x10
  stxdw [r10-0x8d8], r2
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  ldxdw r1, [r6+0x18]
  ldxdw r2, [r6+0x20]
  stxdw [r10-0x3c0], r2
  stxdw [r10-0x3c8], r1
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x3c8
  call fn_b94f0
  ldxw r1, [r10-0x2c0]
  jeq r1, 0x2, jmp_19498
  ldxb r4, [r10-0x290]
  ldxdw r1, [r10-0x90]
  ldxdw r2, [r10-0x8b8]
  stxdw [r2+0x18], r1
  ldxdw r1, [r10-0x98]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r2+0x0], r1
  ldxdw r5, [r10-0x798]
  ldxdw r0, [r10-0x7a8]
  ldxdw r1, [r10-0x8c0]
  jeq r1, 0x0, jmp_178a0
  ldxdw r1, [r10-0x7b0]
  ldxdw r1, [r1+0x1]
  ldxdw r2, [r10-0x2bf]
  jne r1, r2, jmp_17890
  ldxdw r1, [r10-0x7b0]
  ldxdw r1, [r1+0x9]
  ldxdw r2, [r10-0x2b7]
  jne r1, r2, jmp_17890
  ldxdw r1, [r10-0x7b0]
  ldxdw r1, [r1+0x11]
  ldxdw r2, [r10-0x2af]
  jne r1, r2, jmp_17890
  mov64 r1, 0x0
  ldxdw r2, [r10-0x7b0]
  ldxdw r2, [r2+0x19]
  ldxdw r3, [r10-0x2a7]
  jeq r2, r3, jmp_17898

jmp_17890:
  mov64 r1, 0x1

jmp_17898:
  jeq r1, 0x0, jmp_17b18

jmp_178a0:
  ldxdw r9, [r10-0x890]
  ldxdw r3, [r10-0x898]
  jeq r3, 0x0, jmp_17a10

jmp_178b8:
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r2, r10
  add64 r2, -0x48
  call fn_3c7b8
  ldxw r1, [r10-0x20]
  jeq r1, 0x1, jmp_194d0
  ldxdw r3, [r10-0x10]
  ldxdw r2, [r10-0x18]
  mov64 r1, r10
  add64 r1, -0x2c0
  call fn_b3090
  ldxdw r1, [r10-0x2c0]
  jeq r1, 0x0, jmp_19508
  ldxdw r8, [r10-0x8c8]
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x3c0], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x3c8], r1
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x5c0
  mov64 r3, r10
  add64 r3, -0x3c8
  call fn_b40a8
  ldxdw r1, [r10-0x2c0]
  jeq r1, 0x0, jmp_19558
  ldxdw r1, [r8+0x18]
  stxdw [r10-0x5a8], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x5b0], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x5b8], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x5c0], r1
  ldxdw r5, [r10-0x798]
  ldxdw r0, [r10-0x7a8]
  ldxdw r8, [r10-0x7a0]

jmp_17a10:
  mov64 r2, r7
  add64 r2, 0x4
  mov64 r1, 0x1
  jlt r2, r7, jmp_17a38
  mov64 r1, 0x0

jmp_17a38:
  and64 r1, 0x1
  jne r1, 0x0, jmp_197f8
  ldxdw r3, [r10-0x888]
  mov64 r1, r3
  add64 r1, r2
  mov64 r2, 0x1
  jlt r1, r3, jmp_17a78
  mov64 r2, 0x0

jmp_17a78:
  mov64 r4, r9
  mov64 r7, r8
  and64 r2, 0x1
  jne r2, 0x0, jmp_197e0
  add64 r6, 0x18
  ldxdw r3, [r10-0x8d8]
  ldxdw r2, [r3+0x0]
  add64 r2, -0x1
  stxdw [r3+0x0], r2
  ldxdw r2, [r10-0x7d0]
  add64 r2, 0x20
  stxdw [r10-0x7d0], r2
  mov64 r9, r1
  stxdw [r10-0x8e0], r6
  lddw r3, -0x6c5e9a281e0922fa
  ldxdw r6, [r10-0x7c0]
  ldxdw r8, [r10-0x790]
  jlt r1, r8, jmp_16680
  ja jmp_17b80

jmp_17b18:
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x5d0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x5c8], r1
  ldxdw r1, [r10-0x7b8]
  stxdw [r10-0x8f0], r1
  stxdw [r10-0x8e8], r9
  ldxdw r9, [r10-0x7e0]
  ldxdw r3, [r10-0x898]
  jne r3, 0x0, jmp_178b8
  ja jmp_17a10

jmp_17b70:
  mov64 r6, 0x0
  mov64 r1, 0x0

jmp_17b80:
  ldxdw r2, [r10-0x790]
  jne r1, r2, jmp_17dd8
  jne r6, r5, jmp_17ea8
  ldxdw r1, [r10-0x5a8]
  stxdw [r7+0x18], r1
  ldxdw r1, [r10-0x5b0]
  stxdw [r7+0x10], r1
  ldxdw r1, [r10-0x5b8]
  stxdw [r7+0x8], r1
  ldxdw r1, [r10-0x5c0]
  stxdw [r7+0x0], r1
  ldxdw r1, [r10-0x5d0]
  stxdw [r7+0x24], r1
  ldxdw r1, [r10-0x5c8]
  stxdw [r7+0x2c], r1
  ldxdw r1, [r10-0x8f0]
  stxh [r7+0x36], r1
  stxh [r7+0x34], r4
  ldxdw r1, [r10-0x8e8]
  stxw [r7+0x20], r1
  ja jmp_17dd0

jmp_17c28:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x1
  stdw [r10-0x68], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x3c0], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x3c8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x3b8], r1
  mov64 r2, r10
  add64 r2, -0x3c8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x83
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x640
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x640]
  ldxdw r2, [r10-0x638]

jmp_17db8:
  stxdw [r8+0x8], r2
  stxdw [r8+0x0], r1
  sth [r8+0x34], 0x3

jmp_17dd0:
  exit

jmp_17dd8:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0xd4
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x770
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x770]
  ldxdw r2, [r10-0x768]
  ja jmp_182a0

jmp_17ea8:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0xdc
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x780
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x780]
  ldxdw r2, [r10-0x778]
  ja jmp_182a0

jmp_17f78:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x1
  stdw [r10-0x68], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x3c0], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x3c8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x3b8], r1
  mov64 r2, r10
  add64 r2, -0x3c8
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1772
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x7c
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x720
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x720]
  ldxdw r2, [r10-0x718]
  ja jmp_184c8

jmp_18110:
  mov64 r1, r10
  add64 r1, -0x588
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x580]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x578]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x56
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x760
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x760]
  ldxdw r2, [r10-0x758]

jmp_182a0:
  stxdw [r7+0x8], r2
  stxdw [r7+0x0], r1
  sth [r7+0x34], 0x3
  ja jmp_17dd0

jmp_182c0:
  mov64 r1, r10
  add64 r1, -0x588
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x580]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x578]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x60
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x5f0
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x5f0]
  ldxdw r2, [r10-0x5e8]
  ja jmp_184c8

jmp_18458:
  ldxdw r1, [r10-0x8d0]
  stxdw [r10-0x4c8], r1
  ldxdw r1, [r10-0x830]
  stxdw [r10-0x4d0], r1
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x4d8], r1
  mov64 r1, r10
  add64 r1, -0x600
  mov64 r2, r10
  add64 r2, -0x4d8
  call fn_be7f0
  ldxdw r1, [r10-0x600]
  ldxdw r2, [r10-0x5f8]

jmp_184c8:
  ldxdw r3, [r10-0x7a0]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  sth [r3+0x34], 0x3
  ja jmp_17dd0

jmp_184f0:
  ldxdw r1, [r10-0x2b8]
  ldxdw r2, [r10-0x2c0]
  jeq r2, 0x0, jmp_18c40
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_18c48

jmp_18520:
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x6a
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x610
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x610]
  ldxdw r2, [r10-0x608]
  ja jmp_18a58

jmp_186b8:
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_1700
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  lddw r1, data_1700
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x17a0
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x6f
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x740
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x740]
  ldxdw r2, [r10-0x738]
  ja jmp_18a58

jmp_18850:
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x74
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x620
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x620]
  ldxdw r2, [r10-0x618]
  ja jmp_18a58

jmp_189e8:
  ldxdw r1, [r10-0x838]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x858]
  stxdw [r10-0x60], r1
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, r10
  add64 r2, -0x68
  call fn_be7f0
  ldxdw r1, [r10-0x630]
  ldxdw r2, [r10-0x628]

jmp_18a58:
  stxdw [r9+0x8], r2
  stxdw [r9+0x0], r1
  sth [r9+0x34], 0x3
  ja jmp_17dd0

jmp_18a78:
  ldxdw r1, [r10-0x2b0]
  ldxdw r2, [r10-0x2b8]
  jeq r2, 0x0, jmp_190c0
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_190c8

jmp_18aa8:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x1
  stdw [r10-0x68], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x3c0], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x3c8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x3b8], r1
  mov64 r2, r10
  add64 r2, -0x3c8
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x290], r1
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x8a
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  mov64 r1, r10
  add64 r1, -0x650
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x650]
  ldxdw r2, [r10-0x648]
  ja jmp_17db8

jmp_18c40:
  ldxdw r1, [r1+0x0]

jmp_18c48:
  stw [r10-0x20], 0x1
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r6, r10
  add64 r6, -0x20
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x3b8], 0x0
  stdw [r10-0x3c0], 0x1
  stdw [r10-0x3c8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x4d0], r1
  mov64 r1, r10
  add64 r1, -0x3c8
  stxdw [r10-0x4d8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x4c8], r1
  mov64 r2, r10
  add64 r2, -0x4d8
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x290], r1
  stw [r10-0x228], 0x1771
  stb [r10-0x270], 0x2
  stdw [r10-0x2c0], 0x2
  mov64 r1, r10
  add64 r1, -0x750
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x750]
  ldxdw r2, [r10-0x748]
  ldxdw r3, [r10-0x7a0]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  sth [r3+0x34], 0x3
  ldxdw r1, [r7+0x0]
  add64 r1, -0x1
  stxdw [r7+0x0], r1
  ja jmp_17dd0

jmp_18df8:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x97
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x660
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x660]
  ldxdw r2, [r10-0x658]
  ja jmp_17db8

jmp_18ec8:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0x9f
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x670
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x670]
  ldxdw r2, [r10-0x668]
  ja jmp_17db8

jmp_18f98:
  ldxdw r1, [r10-0x2b8]
  jeq r2, 0x0, jmp_195b8
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_195c0

jmp_18fc0:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0xa9
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x710
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x710]
  ldxdw r2, [r10-0x708]
  ja jmp_17db8

jmp_19090:
  ldxdw r1, [r10-0x2b8]
  ldxdw r2, [r10-0x2c0]
  jeq r2, 0x0, jmp_195f8
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_19600

jmp_190c0:
  ldxdw r1, [r1+0x0]

jmp_190c8:
  mov64 r8, 0x1

jmp_190d0:
  stxw [r10-0x48], r8
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r6, r10
  add64 r6, -0x48
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x1
  stdw [r10-0x68], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x3c0], r1
  mov64 r1, r10
  add64 r1, -0x68
  stxdw [r10-0x3c8], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x3b8], r1
  mov64 r2, r10
  add64 r2, -0x3c8
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_196b0
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x290], r1
  add64 r8, 0x1770
  stxw [r10-0x228], r8
  stb [r10-0x270], 0x2
  stdw [r10-0x2c0], 0x2
  mov64 r1, r10
  add64 r1, -0x730
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x730]
  ldxdw r2, [r10-0x728]
  stxdw [r9+0x8], r2
  stxdw [r9+0x0], r1
  sth [r9+0x34], 0x3
  ldxdw r2, [r10-0x838]
  ldxdw r1, [r2+0x0]
  add64 r1, -0x1
  stxdw [r2+0x0], r1
  ja jmp_17dd0

jmp_19288:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0xb4
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x690
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x690]
  ldxdw r2, [r10-0x688]
  ja jmp_17db8

jmp_19358:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x288
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1747
  stxdw [r10-0x2b8], r1
  stb [r10-0x270], 0x2
  stw [r10-0x2a8], 0xb9
  stdw [r10-0x2b0], 0x29
  stdw [r10-0x2c0], 0x0
  stw [r10-0x228], 0x1771
  mov64 r1, r10
  add64 r1, -0x6a0
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be760
  ldxdw r1, [r10-0x6a0]
  ldxdw r2, [r10-0x698]
  ja jmp_17db8

jmp_19428:
  ldxdw r1, [r10-0x8d8]
  stxdw [r10-0x2b0], r1
  stxdw [r10-0x2b8], r4
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x2c0], r1
  mov64 r1, r10
  add64 r1, -0x6b0
  mov64 r2, r10
  add64 r2, -0x2c0
  call fn_be7f0
  ldxdw r1, [r10-0x6b0]
  ldxdw r2, [r10-0x6a8]
  ja jmp_17db8

jmp_19498:
  ldxdw r1, [r10-0x2b0]
  ldxdw r2, [r10-0x2b8]
  jeq r2, 0x0, jmp_19638
  ldxdw r2, [r1+0x0]
  ldxdw r6, [r10-0x8d8]
  ldxb r1, [r1+0x38]
  ja jmp_19648

jmp_194d0:
  ldxw r2, [r10-0x1c]
  mov64 r1, r10
  add64 r1, -0x6e0
  call fn_5a078
  ldxdw r1, [r10-0x6e0]
  ldxdw r2, [r10-0x6d8]
  ja jmp_19538

jmp_19508:
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x6c0]
  ldxdw r2, [r10-0x6b8]

jmp_19538:
  stxdw [r8+0x8], r2
  stxdw [r8+0x0], r1
  sth [r8+0x34], 0x3
  ja jmp_195a8

jmp_19558:
  mov64 r1, r10
  add64 r1, -0x6d0
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x6d0]
  ldxdw r2, [r10-0x6c8]
  ldxdw r7, [r10-0x7a0]
  stxdw [r7+0x8], r2
  stxdw [r7+0x0], r1
  sth [r7+0x34], 0x3

jmp_195a8:
  ldxdw r6, [r10-0x8d8]
  ja jmp_19690

jmp_195b8:
  ldxdw r1, [r1+0x0]

jmp_195c0:
  mov64 r1, r10
  add64 r1, -0x680
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r1, [r10-0x680]
  ldxdw r2, [r10-0x678]
  ja jmp_17db8

jmp_195f8:
  ldxdw r1, [r1+0x0]

jmp_19600:
  mov64 r1, r10
  add64 r1, -0x700
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r1, [r10-0x700]
  ldxdw r2, [r10-0x6f8]
  ja jmp_17db8

jmp_19638:
  ldxdw r1, [r1+0x0]
  ldxdw r6, [r10-0x8d8]

jmp_19648:
  mov64 r1, r10
  add64 r1, -0x6f0
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r1, [r10-0x6f0]
  ldxdw r2, [r10-0x6e8]
  stxdw [r8+0x8], r2
  stxdw [r8+0x0], r1
  sth [r8+0x34], 0x3

jmp_19690:
  ldxdw r1, [r6+0x0]
  add64 r1, -0x1
  stxdw [r6+0x0], r1
  ja jmp_17dd0

jmp_196b0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_19700:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_19720:
  lddw r1, data_6140
  call fn_d07b8

jmp_19738:
  mov64 r2, r1
  mov64 r1, r8
  lddw r3, data_6158
  call fn_cc630

jmp_19760:
  mov64 r2, r1
  mov64 r1, r7
  lddw r3, data_6170
  call fn_cc630

jmp_19788:
  ldxdw r1, [r10-0x7e0]
  ldxdw r2, [r10-0x790]
  lddw r3, data_6188
  call fn_cc630

jmp_197b0:
  lddw r1, data_61d0
  call fn_d07b8

jmp_197c8:
  lddw r1, data_61b8
  call fn_d0810

jmp_197e0:
  lddw r1, data_6200
  call fn_d07b8

jmp_197f8:
  lddw r1, data_61e8
  call fn_d07b8

fn_19810:
  mov64 r7, r5
  mov64 r2, r4
  mov64 r9, r3
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xa8
  stxdw [r10-0x270], r2
  call fn_b3190
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0xa0]
  or64 r2, r1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_19880
  mov64 r3, 0x0

jmp_19880:
  ldxb r8, [r9+0x30]
  jgt r8, 0x2, jmp_19a18
  stw [r10-0x130], 0x10
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r7, r10
  add64 r7, -0x130
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0xf0], r1
  lddw r1, 0xe0000020
  stxdw [r10-0xe0], r1
  mov64 r2, r10
  add64 r2, -0xf0
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1aa28
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x1780
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r1, [r10-0x268]
  ldxdw r2, [r10-0x260]

jmp_19a00:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  ja jmp_1a218

jmp_19a18:
  stxdw [r10-0x280], r7
  stxdw [r10-0x278], r6
  ldxdw r6, [r10-0xa8]
  mov64 r7, r8
  add64 r7, -0x3
  mov64 r4, 0x1
  mov64 r2, 0x1
  jeq r7, 0x0, jmp_19bd8
  mov64 r1, r7
  and64 r1, 0x1
  jeq r1, 0x0, jmp_19a80
  mov64 r2, 0xa
  jeq r7, 0x1, jmp_19bd8

jmp_19a80:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_19ab8
  mul64 r2, 0x64
  mov64 r1, r7
  and64 r1, -0x2
  jeq r1, 0x2, jmp_19bd8

jmp_19ab8:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_19af0
  mul64 r2, 0x2710
  mov64 r1, r7
  and64 r1, -0x4
  jeq r1, 0x4, jmp_19bd8

jmp_19af0:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_19b28
  mul64 r2, 0x5f5e100
  mov64 r1, r7
  and64 r1, -0x8
  jeq r1, 0x8, jmp_19bd8

jmp_19b28:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_1a090
  stxdw [r10-0x288], r3
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r3, 0x0
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x150]
  jne r2, 0x0, jmp_19ba0
  mov64 r1, 0x0

jmp_19ba0:
  and64 r1, 0x1
  ldxdw r3, [r10-0x288]
  mov64 r4, 0x1
  jne r1, 0x0, jmp_1a090
  and64 r7, -0x10
  jne r7, 0x10, jmp_1a090
  ldxdw r2, [r10-0x158]

jmp_19bd8:
  xor64 r6, 0x1
  or64 r6, r3
  ldxdw r3, [r9+0x28]
  jgt r3, r2, jmp_19c00
  mov64 r4, 0x0

jmp_19c00:
  mov64 r1, r6
  and64 r1, r4
  and64 r1, 0x1
  ldxdw r7, [r10-0x280]
  jeq r1, 0x0, jmp_19dc0
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_1720
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0xf0], r1
  lddw r1, 0xe0000020
  stxdw [r10-0xe0], r1
  mov64 r2, r10
  add64 r2, -0xf0
  lddw r1, data_1720
  call fn_5a268
  jne r0, 0x0, jmp_1aa28
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x78], r1
  lddw r1, str_1747
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x17b9
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0xfd
  stdw [r10-0x98], 0x29
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r1, [r10-0x258]
  ldxdw r2, [r10-0x250]
  ja jmp_1a200

jmp_19dc0:
  mov64 r1, 0x1
  jeq r3, 0x0, jmp_19dd8
  mov64 r1, 0x0

jmp_19dd8:
  or64 r1, r6
  and64 r1, 0x1
  jeq r1, 0x0, jmp_19e18
  jgt r8, 0x12, jmp_1aa78
  jne r8, 0x12, jmp_1a398
  mov64 r3, 0x0
  mov64 r2, 0x1
  ja jmp_1a540

jmp_19e18:
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r3
  mov64 r3, 0x0
  call fn_b3090
  ldxdw r1, [r10-0xa8]
  ldxdw r6, [r10-0x278]
  jeq r1, 0x0, jmp_1a220
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r3, r10
  add64 r3, -0x130
  mov64 r2, r7
  call fn_b3b98
  ldxdw r1, [r10-0xa8]
  jeq r1, 0x0, jmp_1a3e0
  ldxdw r1, [r10-0x88]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0xc8], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0xc8
  ldxdw r3, [r10-0x270]
  call fn_b3588
  ldxdw r1, [r10-0xf0]
  jeq r1, 0x0, jmp_1a8e0
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x110
  call fn_b3420
  ldxdw r1, [r10-0xa8]
  jeq r1, 0x0, jmp_1a950
  ldxdw r1, [r10-0x88]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0xc8
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_b3190
  ldxdw r1, [r10-0xc8]
  jeq r1, 0x0, jmp_1a9c0
  ldxdw r1, [r10-0xb8]
  jeq r1, 0x0, jmp_1aa08
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x1c8]
  ldxdw r2, [r10-0x1c0]
  ja jmp_19a00

jmp_1a090:
  stw [r10-0x130], 0x10
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r7, r10
  add64 r7, -0x130
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0xf0], r1
  lddw r1, 0xe0000020
  stxdw [r10-0xe0], r1
  mov64 r2, r10
  add64 r2, -0xf0
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1aa28
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x1780
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r10-0x160]

jmp_1a200:
  ldxdw r3, [r10-0x278]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1

jmp_1a218:
  exit

jmp_1a220:
  stw [r10-0x148], 0x10
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r7, r10
  add64 r7, -0x148
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0xf0], r1
  lddw r1, 0xe0000020
  stxdw [r10-0xe0], r1
  mov64 r2, r10
  add64 r2, -0xf0
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1aa28
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x1780
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r1, [r10-0x178]
  ldxdw r2, [r10-0x170]
  ja jmp_19a00

jmp_1a398:
  mov64 r6, 0x12
  sub64 r6, r8
  and64 r6, 0xff
  mov64 r1, r6
  mov64 r3, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_1a418
  mov64 r2, 0x1
  ja jmp_1a428

jmp_1a3e0:
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x188]
  ldxdw r2, [r10-0x180]
  ja jmp_19a00

jmp_1a418:
  mov64 r2, 0xa
  jeq r8, 0x11, jmp_1a540

jmp_1a428:
  mov64 r1, r6
  and64 r1, 0x2
  jeq r1, 0x0, jmp_1a490
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r3, [r10-0x1d0]
  ldxdw r2, [r10-0x1d8]
  mov64 r1, r6
  and64 r1, 0x1e
  jeq r1, 0x2, jmp_1a540

jmp_1a490:
  mov64 r1, r6
  and64 r1, 0x4
  jeq r1, 0x0, jmp_1a4f8
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r3, [r10-0x1e0]
  ldxdw r2, [r10-0x1e8]
  mov64 r1, r6
  and64 r1, 0x1c
  jeq r1, 0x4, jmp_1a540

jmp_1a4f8:
  and64 r6, 0x8
  jeq r6, 0x0, jmp_1aa90
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r3, [r10-0x1f0]
  ldxdw r2, [r10-0x1f8]

jmp_1a540:
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_b3090
  ldxdw r1, [r10-0xa8]
  jeq r1, 0x0, jmp_1a728
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r3, r10
  add64 r3, -0x130
  mov64 r2, r7
  call fn_b3588
  ldxdw r1, [r10-0xa8]
  ldxdw r6, [r10-0x278]
  jeq r1, 0x0, jmp_1a8a8
  ldxdw r1, [r10-0x88]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0xc8], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0xc8
  call fn_b3420
  ldxdw r1, [r10-0xf0]
  jeq r1, 0x0, jmp_1a918
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0x110
  call fn_b3190
  ldxdw r1, [r10-0x148]
  jeq r1, 0x0, jmp_1a988
  ldxdw r1, [r10-0x138]
  jeq r1, 0x0, jmp_1a9f8
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x248]
  ldxdw r2, [r10-0x240]
  ja jmp_19a00

jmp_1a728:
  stw [r10-0x148], 0x10
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r7, r10
  add64 r7, -0x148
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0xf0], r1
  lddw r1, 0xe0000020
  stxdw [r10-0xe0], r1
  mov64 r2, r10
  add64 r2, -0xf0
  mov64 r1, r7
  call fn_5a268
  ldxdw r6, [r10-0x278]
  jne r0, 0x0, jmp_1aa28
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x1780
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r1, [r10-0x208]
  ldxdw r2, [r10-0x200]
  ja jmp_19a00

jmp_1a8a8:
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x218]
  ldxdw r2, [r10-0x210]
  ja jmp_19a00

jmp_1a8e0:
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x198]
  ldxdw r2, [r10-0x190]
  ja jmp_19a00

jmp_1a918:
  mov64 r1, r10
  add64 r1, -0x228
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x228]
  ldxdw r2, [r10-0x220]
  ja jmp_19a00

jmp_1a950:
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x1a8]
  ldxdw r2, [r10-0x1a0]
  ja jmp_19a00

jmp_1a988:
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x238]
  ldxdw r2, [r10-0x230]
  ja jmp_19a00

jmp_1a9c0:
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x1b8]
  ldxdw r2, [r10-0x1b0]
  ja jmp_19a00

jmp_1a9f8:
  ldxdw r1, [r10-0x140]
  ja jmp_1aa10

jmp_1aa08:
  ldxdw r1, [r10-0xc0]

jmp_1aa10:
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_1a218

jmp_1aa28:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_1aa78:
  lddw r1, data_6218
  call fn_d0810

jmp_1aa90:
  lddw r1, data_5e60
  call fn_d0868

fn_1aaa8:
  stxdw [r10-0x158], r1
  ldxb r1, [r2+0x66]
  stxb [r10-0xfa], r1
  ldxb r1, [r2+0x65]
  mov64 r2, r10
  add64 r2, -0xf9
  stxdw [r10-0x110], r2
  mov64 r2, r10
  add64 r2, -0xfa
  stxdw [r10-0x120], r2
  lddw r2, str_1775
  stxdw [r10-0x130], r2
  stxb [r10-0xf9], r1
  stdw [r10-0x108], 0x1
  stdw [r10-0x118], 0x1
  stdw [r10-0x128], 0xe
  ldxdw r1, [r5-0xff0]
  ldxdw r2, [r1+0x0]
  ldxdw r8, [r2+0x8]
  ldxdw r1, [r8+0x0]
  add64 r1, 0x1
  mov64 r0, 0x1
  jeq r1, 0x0, jmp_1ab70
  mov64 r0, 0x0

jmp_1ab70:
  ldxdw r9, [r2+0x0]
  stxdw [r8+0x0], r1
  jeq r0, 0x1, jmp_1b178
  stxdw [r10-0x160], r3
  stxdw [r10-0x150], r4
  ldxdw r7, [r2+0x10]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r4, 0x1
  jeq r1, 0x0, jmp_1abc8
  mov64 r4, 0x0

jmp_1abc8:
  ldxdw r6, [r5-0xff8]
  ldxdw r5, [r5-0x1000]
  stxdw [r7+0x0], r1
  jeq r4, 0x1, jmp_1b178
  ldxdw r4, [r5+0x58]
  ldxdw r1, [r4+0x8]
  stxdw [r10-0x148], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r5, 0x1
  jeq r1, 0x0, jmp_1ac28
  mov64 r5, 0x0

jmp_1ac28:
  ldxb r0, [r2+0x2a]
  stxdw [r10-0x188], r0
  ldxb r0, [r2+0x29]
  stxdw [r10-0x180], r0
  ldxb r0, [r2+0x28]
  stxdw [r10-0x178], r0
  ldxdw r0, [r2+0x20]
  stxdw [r10-0x170], r0
  ldxdw r2, [r2+0x18]
  stxdw [r10-0x168], r2
  ldxdw r2, [r4+0x0]
  stxdw [r10-0x190], r2
  ldxdw r2, [r10-0x148]
  stxdw [r2+0x0], r1
  jeq r5, 0x1, jmp_1b178
  ldxdw r3, [r4+0x10]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_1acd0
  mov64 r2, 0x0

jmp_1acd0:
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_1b178
  stxdw [r10-0x198], r7
  ldxdw r7, [r6+0x0]
  ldxdw r5, [r7+0x8]
  ldxdw r1, [r5+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_1ad20
  mov64 r2, 0x0

jmp_1ad20:
  ldxb r6, [r4+0x2a]
  stxdw [r10-0x1b0], r6
  ldxb r6, [r4+0x29]
  stxdw [r10-0x1a8], r6
  ldxb r6, [r4+0x28]
  stxdw [r10-0x1a0], r6
  ldxdw r6, [r4+0x20]
  ldxdw r4, [r4+0x18]
  ldxdw r0, [r7+0x0]
  stxdw [r10-0x1b8], r0
  stxdw [r5+0x0], r1
  jeq r2, 0x1, jmp_1b178
  stxdw [r10-0x1c0], r6
  ldxdw r6, [r7+0x10]
  ldxdw r1, [r6+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_1adb8
  mov64 r2, 0x0

jmp_1adb8:
  stxdw [r6+0x0], r1
  jeq r2, 0x1, jmp_1b178
  stxdw [r10-0x1d8], r4
  stxdw [r10-0x1c8], r9
  stxdw [r10-0x1d0], r8
  ldxdw r1, [r10-0x150]
  ldxdw r9, [r1+0x68]
  ldxdw r8, [r9+0x8]
  ldxdw r1, [r8+0x0]
  add64 r1, 0x1
  mov64 r4, 0x1
  jeq r1, 0x0, jmp_1ae20
  mov64 r4, 0x0

jmp_1ae20:
  ldxb r2, [r7+0x2a]
  stxdw [r10-0x1e8], r2
  ldxb r2, [r7+0x29]
  stxdw [r10-0x1e0], r2
  ldxb r2, [r7+0x28]
  stxdw [r10-0x150], r2
  ldxdw r0, [r7+0x20]
  ldxdw r2, [r7+0x18]
  ldxdw r7, [r9+0x0]
  stxdw [r8+0x0], r1
  jeq r4, 0x1, jmp_1b178
  stxdw [r10-0x1f0], r5
  ldxdw r1, [r9+0x10]
  ldxdw r4, [r1+0x0]
  add64 r4, 0x1
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_1aeb0
  mov64 r5, 0x0

jmp_1aeb0:
  stxdw [r1+0x0], r4
  jeq r5, 0x1, jmp_1b178
  ldxdw r4, [r9+0x18]
  ldxdw r5, [r9+0x20]
  stxdw [r10-0x1f8], r3
  stxdw [r10-0x200], r6
  mov64 r6, r2
  mov64 r3, r0
  ldxb r0, [r9+0x28]
  mov64 r2, r7
  ldxb r7, [r9+0x29]
  ldxb r9, [r9+0x2a]
  stxb [r10-0x26], r9
  stxb [r10-0x27], r7
  stxb [r10-0x28], r0
  stxdw [r10-0x30], r5
  stxdw [r10-0x38], r4
  stxdw [r10-0x40], r1
  stxdw [r10-0x48], r8
  stxdw [r10-0x50], r2
  ldxdw r1, [r10-0x1e8]
  stxb [r10-0x56], r1
  ldxdw r1, [r10-0x1e0]
  stxb [r10-0x57], r1
  ldxdw r1, [r10-0x150]
  stxb [r10-0x58], r1
  stxdw [r10-0x60], r3
  stxdw [r10-0x68], r6
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x1b0]
  stxb [r10-0x86], r1
  ldxdw r1, [r10-0x1a8]
  stxb [r10-0x87], r1
  ldxdw r1, [r10-0x1a0]
  stxb [r10-0x88], r1
  ldxdw r1, [r10-0x1c0]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0xb0], r1
  mov64 r1, r10
  add64 r1, -0x130
  stxdw [r10-0x10], r1
  stdw [r10-0x8], 0x3
  mov64 r1, r10
  add64 r1, -0x10
  stxdw [r10-0x20], r1
  ldxdw r1, [r10-0x188]
  stxb [r10-0xb6], r1
  ldxdw r1, [r10-0x180]
  stxb [r10-0xb7], r1
  ldxdw r1, [r10-0x178]
  stxb [r10-0xb8], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x1c8]
  stxdw [r10-0xe0], r1
  stdw [r10-0x18], 0x1
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x8
  stdw [r10-0xf8], 0x0
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xf8
  ldxdw r3, [r10-0x160]
  call fn_b7ae8
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ldxdw r3, [r10-0x158]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  exit

jmp_1b178:
  call abort

fn_1b180:
  mov64 r6, r1
  mov64 r1, r3
  and64 r1, 0xff
  jeq r1, 0x0, jmp_1b328
  ldxb r1, [r2+0x13]
  jle r1, 0x11, jmp_1b4a0
  stw [r10-0xf4], 0x27
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1b6d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1797
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x118]
  ja jmp_1b6b8

jmp_1b328:
  stw [r10-0xf4], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1b6d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x128]
  ja jmp_1b6b8

jmp_1b4a0:
  mov64 r4, r2
  add64 r4, 0x1
  mov64 r5, r4
  mov64 r0, r1

jmp_1b4c0:
  jeq r0, 0x0, jmp_1b670
  add64 r0, -0x1
  mov64 r7, r3
  and64 r7, 0xff
  ldxb r8, [r5+0x0]
  add64 r5, 0x1
  jne r8, r7, jmp_1b4c0
  stw [r10-0xf4], 0x29
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1b6d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1799
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0x108]
  ja jmp_1b6b8

jmp_1b670:
  add64 r4, r1
  stxb [r4+0x0], r3
  ldxb r1, [r2+0x13]
  add64 r1, 0x1
  mov64 r3, r1
  and64 r3, 0xff
  jne r3, r1, jmp_1b720
  stxb [r2+0x13], r1
  mov64 r2, 0x2

jmp_1b6b8:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r2
  exit

jmp_1b6d0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_1b720:
  lddw r1, data_6230
  call fn_d07b8

fn_1b738:
  mov64 r6, r1
  ldxb r1, [r2+0x13]
  jeq r1, 0x0, jmp_1b828
  mov64 r4, 0x0
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x1]
  jne r0, r5, jmp_1b9a0

jmp_1b778:
  mov64 r3, r1
  add64 r3, -0x1
  jge r4, r3, jmp_1b7d8

jmp_1b790:
  jge r4, 0x11, jmp_1bed0
  mov64 r1, r2
  add64 r1, r4
  add64 r4, 0x1
  ldxb r5, [r1+0x2]
  stxb [r1+0x1], r5
  jlt r4, r3, jmp_1b790
  ldxb r1, [r2+0x13]
  jeq r1, 0x0, jmp_1bf40

jmp_1b7d8:
  jge r1, 0x13, jmp_1bf00
  mov64 r3, r2
  add64 r3, r1
  stb [r3+0x0], 0x0
  ldxb r1, [r2+0x13]
  jeq r1, 0x0, jmp_1bf28
  add64 r1, -0x1
  stxb [r2+0x13], r1
  mov64 r2, 0x2
  ja jmp_1bb18

jmp_1b828:
  stw [r10-0xf4], 0x27
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1be80
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1797
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x118]
  ja jmp_1bb18

jmp_1b9a0:
  jne r1, 0x1, jmp_1bb30

jmp_1b9a8:
  stw [r10-0xf4], 0x28
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1be80
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1798
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0x108]

jmp_1bb18:
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  exit

jmp_1bb30:
  mov64 r4, 0x1
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x2]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x2, jmp_1b9a8
  mov64 r4, 0x2
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x3]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x3, jmp_1b9a8
  mov64 r4, 0x3
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x4]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x4, jmp_1b9a8
  mov64 r4, 0x4
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x5]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x5, jmp_1b9a8
  mov64 r4, 0x5
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x6]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x6, jmp_1b9a8
  mov64 r4, 0x6
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x7]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x7, jmp_1b9a8
  mov64 r4, 0x7
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x8]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x8, jmp_1b9a8
  mov64 r4, 0x8
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x9]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x9, jmp_1b9a8
  mov64 r4, 0x9
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xa]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xa, jmp_1b9a8
  mov64 r4, 0xa
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xb]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xb, jmp_1b9a8
  mov64 r4, 0xb
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xc]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xc, jmp_1b9a8
  mov64 r4, 0xc
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xd]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xd, jmp_1b9a8
  mov64 r4, 0xd
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xe]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xe, jmp_1b9a8
  mov64 r4, 0xe
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xf]
  jeq r0, r5, jmp_1b778
  jeq r1, 0xf, jmp_1b9a8
  mov64 r4, 0xf
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x10]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x10, jmp_1b9a8
  mov64 r4, 0x10
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x11]
  jeq r0, r5, jmp_1b778
  jeq r1, 0x11, jmp_1b9a8
  mov64 r4, 0x11
  and64 r3, 0xff
  ldxb r5, [r2+0x12]
  jeq r5, r3, jmp_1b778
  jeq r1, 0x12, jmp_1b9a8
  mov64 r1, 0x12
  mov64 r2, 0x12
  lddw r3, data_6248
  call fn_cc630

jmp_1be80:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_1bed0:
  add64 r4, 0x1
  mov64 r1, r4
  mov64 r2, 0x12
  lddw r3, data_62a8
  call fn_cc630

jmp_1bf00:
  add64 r1, -0x1
  mov64 r2, 0x12
  lddw r3, data_6278
  call fn_cc630

jmp_1bf28:
  lddw r1, data_6290
  call fn_d0810

jmp_1bf40:
  lddw r1, data_6260
  call fn_d0810

fn_1bf58:
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r4, [r2+0x0]
  jne r4, r5, jmp_1bf88
  mov64 r4, r2
  ja jmp_1c220

jmp_1bf88:
  mov64 r4, r2
  add64 r4, 0x14
  ldxb r0, [r2+0x14]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x28
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x28]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x3c
  ldxb r0, [r2+0x3c]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x50
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x50]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x64
  ldxb r0, [r2+0x64]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x78
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x78]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x8c
  ldxb r0, [r2+0x8c]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0xa0
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xa0]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0xb4
  ldxb r0, [r2+0xb4]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0xc8
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xc8]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0xdc
  ldxb r0, [r2+0xdc]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0xf0
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0xf0]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x104
  ldxb r0, [r2+0x104]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x118
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r0, [r2+0x118]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x12c
  ldxb r0, [r2+0x12c]
  jeq r0, r5, jmp_1c220
  mov64 r4, r2
  add64 r4, 0x140
  and64 r3, 0xff
  ldxb r5, [r2+0x140]
  jeq r5, r3, jmp_1c220
  ldxb r5, [r2+0x154]
  add64 r2, 0x154
  mov64 r4, r2
  jne r5, r3, jmp_1c278

jmp_1c220:
  ldxb r2, [r4+0x13]
  jge r2, 0x13, jmp_1c250
  add64 r4, 0x1

jmp_1c238:
  stxdw [r1+0x8], r2
  stxdw [r1+0x0], r4
  exit

jmp_1c250:
  mov64 r1, r2
  mov64 r2, 0x12
  lddw r3, data_62c0
  call fn_cf460

jmp_1c278:
  mov64 r4, 0x0
  ja jmp_1c238

fn_1c288:
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r3, [r1+0x0]
  jne r3, r4, jmp_1c2b8
  mov64 r3, r1
  ja jmp_1c558

jmp_1c2b8:
  mov64 r3, r1
  add64 r3, 0x14
  ldxb r5, [r1+0x14]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x28
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0x28]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x3c
  ldxb r5, [r1+0x3c]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x50
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0x50]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x64
  ldxb r5, [r1+0x64]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x78
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0x78]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x8c
  ldxb r5, [r1+0x8c]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0xa0
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0xa0]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0xb4
  ldxb r5, [r1+0xb4]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0xc8
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0xc8]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0xdc
  ldxb r5, [r1+0xdc]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0xf0
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0xf0]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x104
  ldxb r5, [r1+0x104]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x118
  mov64 r4, r2
  and64 r4, 0xff
  ldxb r5, [r1+0x118]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x12c
  ldxb r5, [r1+0x12c]
  jeq r5, r4, jmp_1c558
  mov64 r3, r1
  add64 r3, 0x140
  and64 r2, 0xff
  ldxb r4, [r1+0x140]
  jeq r4, r2, jmp_1c558
  mov64 r0, 0x0
  ldxb r4, [r1+0x154]
  add64 r1, 0x154
  mov64 r3, r1
  jne r4, r2, jmp_1c590

jmp_1c558:
  ldxb r1, [r3+0x13]
  jeq r1, 0x0, jmp_1c588
  mov64 r0, 0x1
  ldxb r2, [r3+0x1]
  jeq r2, 0x1, jmp_1c590
  jne r1, 0x1, jmp_1c598

jmp_1c588:
  mov64 r0, 0x0

jmp_1c590:
  exit

jmp_1c598:
  ldxb r2, [r3+0x2]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x2, jmp_1c588
  ldxb r2, [r3+0x3]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x3, jmp_1c588
  ldxb r2, [r3+0x4]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x4, jmp_1c588
  ldxb r2, [r3+0x5]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x5, jmp_1c588
  ldxb r2, [r3+0x6]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x6, jmp_1c588
  ldxb r2, [r3+0x7]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x7, jmp_1c588
  ldxb r2, [r3+0x8]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x8, jmp_1c588
  ldxb r2, [r3+0x9]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x9, jmp_1c588
  ldxb r2, [r3+0xa]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xa, jmp_1c588
  ldxb r2, [r3+0xb]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xb, jmp_1c588
  ldxb r2, [r3+0xc]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xc, jmp_1c588
  ldxb r2, [r3+0xd]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xd, jmp_1c588
  ldxb r2, [r3+0xe]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xe, jmp_1c588
  ldxb r2, [r3+0xf]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0xf, jmp_1c588
  ldxb r2, [r3+0x10]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x10, jmp_1c588
  ldxb r2, [r3+0x11]
  jeq r2, 0x1, jmp_1c590
  jeq r1, 0x11, jmp_1c588
  ldxb r2, [r3+0x12]
  jeq r2, 0x1, jmp_1c590
  mov64 r0, 0x0
  jeq r1, 0x12, jmp_1c590
  mov64 r1, 0x12
  mov64 r2, 0x12
  lddw r3, data_62d8
  call fn_cc630

fn_1c760:
  mov64 r6, r1
  mov64 r1, r4
  and64 r1, 0xff
  jne r1, 0x1, jmp_1c7a0
  mov64 r1, r3
  and64 r1, 0xff
  jgt r1, 0x3, jmp_1c860
  jeq r1, 0x2, jmp_1c860

jmp_1c7a0:
  mov64 r5, r3
  and64 r5, 0xff
  ldxb r1, [r2+0x0]
  jne r1, r5, jmp_1c7d0
  ldxb r1, [r2+0x13]
  jne r1, 0x0, jmp_1ce98

jmp_1c7d0:
  mov64 r1, r2
  add64 r1, 0x14
  ldxb r0, [r2+0x14]
  jne r0, r5, jmp_1c810
  ldxb r5, [r2+0x27]
  jeq r5, 0x0, jmp_1c810
  mov64 r2, r1
  ja jmp_1ce98

jmp_1c810:
  mov64 r5, r2
  add64 r5, 0x28
  mov64 r7, r3
  and64 r7, 0xff
  ldxb r0, [r2+0x28]
  jne r0, r7, jmp_1c9d8
  ldxb r0, [r2+0x3b]
  jeq r0, 0x0, jmp_1c9d8
  mov64 r2, r5
  ja jmp_1ce98

jmp_1c860:
  stw [r10-0xf4], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1d498
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1771
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x148]
  ja jmp_1cec8

jmp_1c9d8:
  mov64 r0, r2
  add64 r0, 0x3c
  ldxb r8, [r2+0x3c]
  jne r8, r7, jmp_1ca18
  ldxb r7, [r2+0x4f]
  jeq r7, 0x0, jmp_1ca18
  mov64 r2, r0
  ja jmp_1ce98

jmp_1ca18:
  mov64 r7, r2
  add64 r7, 0x50
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0x50]
  jne r8, r9, jmp_1ca68
  ldxb r8, [r2+0x63]
  jeq r8, 0x0, jmp_1ca68
  mov64 r2, r7
  ja jmp_1ce98

jmp_1ca68:
  mov64 r8, r2
  add64 r8, 0x64
  stxdw [r10-0x150], r8
  ldxb r8, [r2+0x64]
  jne r8, r9, jmp_1cab0
  ldxb r8, [r2+0x77]
  jeq r8, 0x0, jmp_1cab0
  ldxdw r2, [r10-0x150]
  ja jmp_1ce98

jmp_1cab0:
  mov64 r8, r2
  add64 r8, 0x78
  stxdw [r10-0x158], r8
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0x78]
  jne r8, r9, jmp_1cb08
  ldxb r8, [r2+0x8b]
  jeq r8, 0x0, jmp_1cb08
  ldxdw r2, [r10-0x158]
  ja jmp_1ce98

jmp_1cb08:
  mov64 r8, r2
  add64 r8, 0x8c
  stxdw [r10-0x160], r8
  ldxb r8, [r2+0x8c]
  jne r8, r9, jmp_1cb50
  ldxb r8, [r2+0x9f]
  jeq r8, 0x0, jmp_1cb50
  ldxdw r2, [r10-0x160]
  ja jmp_1ce98

jmp_1cb50:
  mov64 r8, r2
  add64 r8, 0xa0
  stxdw [r10-0x168], r8
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0xa0]
  jne r8, r9, jmp_1cba8
  ldxb r8, [r2+0xb3]
  jeq r8, 0x0, jmp_1cba8
  ldxdw r2, [r10-0x168]
  ja jmp_1ce98

jmp_1cba8:
  mov64 r8, r2
  add64 r8, 0xb4
  stxdw [r10-0x170], r8
  ldxb r8, [r2+0xb4]
  jne r8, r9, jmp_1cbf0
  ldxb r8, [r2+0xc7]
  jeq r8, 0x0, jmp_1cbf0
  ldxdw r2, [r10-0x170]
  ja jmp_1ce98

jmp_1cbf0:
  mov64 r8, r2
  add64 r8, 0xc8
  stxdw [r10-0x178], r8
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0xc8]
  jne r8, r9, jmp_1cc48
  ldxb r8, [r2+0xdb]
  jeq r8, 0x0, jmp_1cc48
  ldxdw r2, [r10-0x178]
  ja jmp_1ce98

jmp_1cc48:
  mov64 r8, r2
  add64 r8, 0xdc
  stxdw [r10-0x180], r8
  ldxb r8, [r2+0xdc]
  jne r8, r9, jmp_1cc90
  ldxb r8, [r2+0xef]
  jeq r8, 0x0, jmp_1cc90
  ldxdw r2, [r10-0x180]
  ja jmp_1ce98

jmp_1cc90:
  mov64 r8, r2
  add64 r8, 0xf0
  stxdw [r10-0x188], r8
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0xf0]
  jne r8, r9, jmp_1cce8
  ldxb r8, [r2+0x103]
  jeq r8, 0x0, jmp_1cce8
  ldxdw r2, [r10-0x188]
  ja jmp_1ce98

jmp_1cce8:
  mov64 r8, r2
  add64 r8, 0x104
  stxdw [r10-0x190], r8
  ldxb r8, [r2+0x104]
  jne r8, r9, jmp_1cd30
  ldxb r8, [r2+0x117]
  jeq r8, 0x0, jmp_1cd30
  ldxdw r2, [r10-0x190]
  ja jmp_1ce98

jmp_1cd30:
  mov64 r8, r2
  add64 r8, 0x118
  stxdw [r10-0x1a0], r8
  mov64 r9, r3
  and64 r9, 0xff
  ldxb r8, [r2+0x118]
  jne r8, r9, jmp_1cd88
  ldxb r8, [r2+0x12b]
  jeq r8, 0x0, jmp_1cd88
  ldxdw r2, [r10-0x1a0]
  ja jmp_1ce98

jmp_1cd88:
  mov64 r8, r2
  add64 r8, 0x12c
  stxdw [r10-0x1a8], r8
  stxdw [r10-0x198], r2
  ldxb r2, [r2+0x12c]
  jne r2, r9, jmp_1cde0
  ldxdw r2, [r10-0x198]
  ldxb r2, [r2+0x13f]
  jeq r2, 0x0, jmp_1cde0
  ldxdw r2, [r10-0x1a8]
  ja jmp_1ce98

jmp_1cde0:
  ldxdw r2, [r10-0x198]
  mov64 r9, r2
  add64 r9, 0x140
  stxdw [r10-0x1b0], r9
  mov64 r8, r3
  and64 r8, 0xff
  ldxb r2, [r2+0x140]
  jne r2, r8, jmp_1ce48
  ldxdw r2, [r10-0x198]
  ldxb r2, [r2+0x153]
  jeq r2, 0x0, jmp_1ce48
  ldxdw r2, [r10-0x1b0]
  ja jmp_1ce98

jmp_1ce48:
  ldxdw r2, [r10-0x198]
  mov64 r9, r2
  add64 r9, 0x154
  stxdw [r10-0x1b8], r9
  ldxb r2, [r2+0x154]
  jne r2, r8, jmp_1cee0
  ldxdw r2, [r10-0x198]
  ldxb r2, [r2+0x167]
  jeq r2, 0x0, jmp_1cee0
  ldxdw r2, [r10-0x1b8]

jmp_1ce98:
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r3, r4
  call fn_1b180
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0x108]

jmp_1cec8:
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  exit

jmp_1cee0:
  ldxdw r2, [r10-0x198]
  ldxb r9, [r2+0x13]
  jeq r9, 0x0, jmp_1d290
  ldxdw r2, [r10-0x198]
  ldxb r8, [r2+0x27]
  mov64 r2, r1
  jeq r8, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x3b]
  mov64 r2, r5
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x4f]
  mov64 r2, r0
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x63]
  mov64 r2, r7
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x77]
  ldxdw r2, [r10-0x150]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x8b]
  ldxdw r2, [r10-0x158]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x9f]
  ldxdw r2, [r10-0x160]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0xb3]
  ldxdw r2, [r10-0x168]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0xc7]
  ldxdw r2, [r10-0x170]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0xdb]
  ldxdw r2, [r10-0x178]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0xef]
  ldxdw r2, [r10-0x180]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x103]
  ldxdw r2, [r10-0x188]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x117]
  ldxdw r2, [r10-0x190]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x12b]
  ldxdw r2, [r10-0x1a0]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x13f]
  ldxdw r2, [r10-0x1a8]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x153]
  ldxdw r2, [r10-0x1b0]
  jeq r1, 0x0, jmp_1d290
  ldxdw r1, [r10-0x198]
  ldxb r1, [r1+0x167]
  ldxdw r2, [r10-0x1b8]
  jeq r1, 0x0, jmp_1d290
  stw [r10-0xf4], 0x27
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1d498
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1797
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x118]
  ja jmp_1cec8

jmp_1d290:
  stxb [r2+0x0], r3
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r3, r4
  call fn_1b180
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x128]
  jne r2, 0x2, jmp_1cec8
  ldxdw r3, [r10-0x198]
  ldxb r3, [r3+0x168]
  add64 r3, 0x1
  mov64 r4, r3
  and64 r4, 0xff
  jne r4, r3, jmp_1d4e8
  jge r4, 0x13, jmp_1d320
  ldxdw r4, [r10-0x198]
  stxb [r4+0x168], r3
  ja jmp_1cec8

jmp_1d320:
  stw [r10-0xf4], 0x27
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1d498
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1797
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x130]
  ldxdw r2, [r10-0x138]
  ja jmp_1cec8

jmp_1d498:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_1d4e8:
  lddw r1, data_62f0
  call fn_d07b8

fn_1d500:
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0x0]
  jne r2, r1, jmp_1d548
  ldxb r2, [r7+0x13]
  mov64 r8, r7
  jne r2, 0x0, jmp_1d8f0

jmp_1d548:
  ldxb r2, [r7+0x14]
  jne r2, r1, jmp_1d578
  ldxb r1, [r7+0x27]
  mov64 r8, r7
  add64 r8, 0x14
  jne r1, 0x0, jmp_1d8f0

jmp_1d578:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0x28]
  jne r2, r1, jmp_1d5b8
  ldxb r2, [r7+0x3b]
  mov64 r8, r7
  add64 r8, 0x28
  jne r2, 0x0, jmp_1d8f0

jmp_1d5b8:
  ldxb r2, [r7+0x3c]
  jne r2, r1, jmp_1d5e8
  ldxb r1, [r7+0x4f]
  mov64 r8, r7
  add64 r8, 0x3c
  jne r1, 0x0, jmp_1d8f0

jmp_1d5e8:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0x50]
  jne r2, r1, jmp_1d628
  ldxb r2, [r7+0x63]
  mov64 r8, r7
  add64 r8, 0x50
  jne r2, 0x0, jmp_1d8f0

jmp_1d628:
  ldxb r2, [r7+0x64]
  jne r2, r1, jmp_1d658
  ldxb r1, [r7+0x77]
  mov64 r8, r7
  add64 r8, 0x64
  jne r1, 0x0, jmp_1d8f0

jmp_1d658:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0x78]
  jne r2, r1, jmp_1d698
  ldxb r2, [r7+0x8b]
  mov64 r8, r7
  add64 r8, 0x78
  jne r2, 0x0, jmp_1d8f0

jmp_1d698:
  ldxb r2, [r7+0x8c]
  jne r2, r1, jmp_1d6c8
  ldxb r1, [r7+0x9f]
  mov64 r8, r7
  add64 r8, 0x8c
  jne r1, 0x0, jmp_1d8f0

jmp_1d6c8:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0xa0]
  jne r2, r1, jmp_1d708
  ldxb r2, [r7+0xb3]
  mov64 r8, r7
  add64 r8, 0xa0
  jne r2, 0x0, jmp_1d8f0

jmp_1d708:
  ldxb r2, [r7+0xb4]
  jne r2, r1, jmp_1d738
  ldxb r1, [r7+0xc7]
  mov64 r8, r7
  add64 r8, 0xb4
  jne r1, 0x0, jmp_1d8f0

jmp_1d738:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0xc8]
  jne r2, r1, jmp_1d778
  ldxb r2, [r7+0xdb]
  mov64 r8, r7
  add64 r8, 0xc8
  jne r2, 0x0, jmp_1d8f0

jmp_1d778:
  ldxb r2, [r7+0xdc]
  jne r2, r1, jmp_1d7a8
  ldxb r1, [r7+0xef]
  mov64 r8, r7
  add64 r8, 0xdc
  jne r1, 0x0, jmp_1d8f0

jmp_1d7a8:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0xf0]
  jne r2, r1, jmp_1d7e8
  ldxb r2, [r7+0x103]
  mov64 r8, r7
  add64 r8, 0xf0
  jne r2, 0x0, jmp_1d8f0

jmp_1d7e8:
  ldxb r2, [r7+0x104]
  jne r2, r1, jmp_1d818
  ldxb r1, [r7+0x117]
  mov64 r8, r7
  add64 r8, 0x104
  jne r1, 0x0, jmp_1d8f0

jmp_1d818:
  mov64 r1, r3
  and64 r1, 0xff
  ldxb r2, [r7+0x118]
  jne r2, r1, jmp_1d858
  ldxb r2, [r7+0x12b]
  mov64 r8, r7
  add64 r8, 0x118
  jne r2, 0x0, jmp_1d8f0

jmp_1d858:
  ldxb r2, [r7+0x12c]
  jne r2, r1, jmp_1d888
  ldxb r1, [r7+0x13f]
  mov64 r8, r7
  add64 r8, 0x12c
  jne r1, 0x0, jmp_1d8f0

jmp_1d888:
  and64 r3, 0xff
  ldxb r1, [r7+0x140]
  jne r1, r3, jmp_1d8c0
  ldxb r1, [r7+0x153]
  mov64 r8, r7
  add64 r8, 0x140
  jne r1, 0x0, jmp_1d8f0

jmp_1d8c0:
  ldxb r1, [r7+0x154]
  jne r1, r3, jmp_1d9b0
  ldxb r1, [r7+0x167]
  mov64 r8, r7
  add64 r8, 0x154
  jeq r1, 0x0, jmp_1d9b0

jmp_1d8f0:
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r8
  mov64 r3, r4
  call fn_1b738
  ldxdw r1, [r10-0xf8]
  ldxdw r2, [r10-0x100]
  jne r2, 0x2, jmp_1d998
  mov64 r2, 0x2
  ldxb r3, [r8+0x13]
  jne r3, 0x0, jmp_1d998
  ldxb r0, [r7+0x168]
  mov64 r3, r0
  add64 r3, -0x1
  mov64 r4, 0x0
  mov64 r5, 0x1
  jgt r3, r0, jmp_1d980
  mov64 r5, 0x0

jmp_1d980:
  jne r5, 0x0, jmp_1d990
  mov64 r4, r3

jmp_1d990:
  stxb [r7+0x168], r4

jmp_1d998:
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  exit

jmp_1d9b0:
  stw [r10-0xec], 0x26
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r7, r10
  add64 r7, -0xec
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1db28
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  stw [r10-0x50], 0x1796
  stb [r10-0x98], 0x2
  stdw [r10-0xe8], 0x2
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x110]
  ja jmp_1d998

jmp_1db28:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_1db78:
  mov64 r6, r1
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r3, 0x168
  call fn_d23f0
  stw [r10-0x4], 0x0
  stb [r10-0x8], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r7
  mov64 r3, 0xa
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x180]
  jne r1, 0x2, jmp_1e0f8
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xe
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x190]
  jne r1, 0x2, jmp_1e108
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x9
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1a0]
  jne r1, 0x2, jmp_1e118
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xc
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1b0]
  jne r1, 0x2, jmp_1e128
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x0
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1c0]
  jne r1, 0x2, jmp_1e138
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x1
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1d0]
  jne r1, 0x2, jmp_1e148
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x4
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1e0]
  jne r1, 0x2, jmp_1e158
  mov64 r1, r10
  add64 r1, -0x1f0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x5
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x1f0]
  jne r1, 0x2, jmp_1e168
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xd
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x200]
  jne r1, 0x2, jmp_1e178
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xf
  mov64 r4, 0x5
  call fn_1c760
  ldxdw r1, [r10-0x210]
  jne r1, 0x2, jmp_1e188
  mov64 r1, r10
  add64 r1, -0x220
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x2
  mov64 r4, 0x4
  call fn_1c760
  ldxdw r1, [r10-0x220]
  jne r1, 0x2, jmp_1e198
  mov64 r1, r10
  add64 r1, -0x230
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x3
  mov64 r4, 0x4
  call fn_1c760
  ldxdw r1, [r10-0x230]
  jne r1, 0x2, jmp_1e1a8
  mov64 r1, r10
  add64 r1, -0x240
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x0
  mov64 r4, 0x2
  call fn_1c760
  ldxdw r1, [r10-0x240]
  jne r1, 0x2, jmp_1e1b8
  mov64 r1, r10
  add64 r1, -0x250
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x1
  mov64 r4, 0x2
  call fn_1c760
  ldxdw r1, [r10-0x250]
  jne r1, 0x2, jmp_1e1c8
  mov64 r1, r10
  add64 r1, -0x260
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x4
  mov64 r4, 0x3
  call fn_1c760
  ldxdw r1, [r10-0x260]
  jne r1, 0x2, jmp_1e1d8
  mov64 r1, r10
  add64 r1, -0x270
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x5
  mov64 r4, 0x3
  call fn_1c760
  ldxdw r1, [r10-0x270]
  jne r1, 0x2, jmp_1e1e8
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x6
  mov64 r4, 0x3
  call fn_1c760
  ldxdw r1, [r10-0x280]
  jne r1, 0x2, jmp_1e1f8
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0x7
  mov64 r4, 0x3
  call fn_1c760
  ldxdw r1, [r10-0x290]
  jne r1, 0x2, jmp_1e208
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r1, r6
  mov64 r3, 0x170
  call fn_d23d0
  ja jmp_1e228

jmp_1e0f8:
  ldxdw r2, [r10-0x178]
  ja jmp_1e210

jmp_1e108:
  ldxdw r2, [r10-0x188]
  ja jmp_1e210

jmp_1e118:
  ldxdw r2, [r10-0x198]
  ja jmp_1e210

jmp_1e128:
  ldxdw r2, [r10-0x1a8]
  ja jmp_1e210

jmp_1e138:
  ldxdw r2, [r10-0x1b8]
  ja jmp_1e210

jmp_1e148:
  ldxdw r2, [r10-0x1c8]
  ja jmp_1e210

jmp_1e158:
  ldxdw r2, [r10-0x1d8]
  ja jmp_1e210

jmp_1e168:
  ldxdw r2, [r10-0x1e8]
  ja jmp_1e210

jmp_1e178:
  ldxdw r2, [r10-0x1f8]
  ja jmp_1e210

jmp_1e188:
  ldxdw r2, [r10-0x208]
  ja jmp_1e210

jmp_1e198:
  ldxdw r2, [r10-0x218]
  ja jmp_1e210

jmp_1e1a8:
  ldxdw r2, [r10-0x228]
  ja jmp_1e210

jmp_1e1b8:
  ldxdw r2, [r10-0x238]
  ja jmp_1e210

jmp_1e1c8:
  ldxdw r2, [r10-0x248]
  ja jmp_1e210

jmp_1e1d8:
  ldxdw r2, [r10-0x258]
  ja jmp_1e210

jmp_1e1e8:
  ldxdw r2, [r10-0x268]
  ja jmp_1e210

jmp_1e1f8:
  ldxdw r2, [r10-0x278]
  ja jmp_1e210

jmp_1e208:
  ldxdw r2, [r10-0x288]

jmp_1e210:
  stxdw [r6+0x8], r1
  stxdw [r6+0x10], r2
  stb [r6+0x1], 0x7

jmp_1e228:
  exit

fn_1e230:
  ldxb r2, [r2+0x0]
  jsgt r2, 0x5, jmp_1e268
  jeq r2, 0x4, jmp_1e420
  jne r2, 0x5, jmp_1e290
  stdw [r1+0x0], 0x2
  stb [r1+0x8], 0x1
  ja jmp_1e448

jmp_1e268:
  jeq r2, 0x6, jmp_1e438
  jne r2, 0x7, jmp_1e290
  stdw [r1+0x0], 0x2
  stb [r1+0x8], 0x3
  ja jmp_1e448

jmp_1e290:
  mov64 r7, r1
  stw [r10-0xec], 0x26
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r6, r10
  add64 r6, -0xec
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_1e450
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  stw [r10-0x50], 0x1796
  stb [r10-0x98], 0x2
  stdw [r10-0xe8], 0x2
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  stxdw [r7+0x8], r2
  stxdw [r7+0x0], r1
  ja jmp_1e448

jmp_1e420:
  stdw [r1+0x0], 0x2
  stb [r1+0x8], 0x0
  ja jmp_1e448

jmp_1e438:
  stdw [r1+0x0], 0x2
  stb [r1+0x8], 0x2

jmp_1e448:
  exit

jmp_1e450:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_1e4a0:
  mov64 r6, r1
  ldxb r1, [r3+0x0]
  ldxw r2, [r2+0x0]
  rsh64 r2, r1
  and64 r2, 0x1
  jeq r2, 0x0, jmp_1e668
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16dc
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16dc
  call fn_5a268
  jne r0, 0x0, jmp_1e688
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_1783
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x1795
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0x20
  stdw [r10-0xd8], 0x25
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r2, [r10-0xf0]
  ldxdw r1, [r10-0xf8]
  ja jmp_1e670

jmp_1e668:
  mov64 r1, 0x2

jmp_1e670:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_1e688:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_1e6d8:
  mov64 r6, r1
  jeq r3, 0x0, jmp_1ea38
  ldxdw r9, [r2+0x8]
  ldxb r1, [r9+0x44]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1ebd0
  stxdw [r10-0x498], r6
  ldxw r5, [r9+0x48]
  ldxb r1, [r9+0x47]
  stxb [r10-0x342], r1
  ldxh r1, [r9+0x45]
  stxh [r10-0x344], r1
  ldxdw r1, [r9+0x4c]
  stxdw [r10-0x360], r1
  ldxdw r1, [r9+0x54]
  stxdw [r10-0x358], r1
  ldxdw r1, [r9+0x5c]
  stxdw [r10-0x350], r1
  ldxb r1, [r9+0x64]
  stxb [r10-0x348], r1
  ldxb r1, [r9+0x47]
  stxb [r10-0x37e], r1
  ldxh r1, [r9+0x45]
  stxw [r10-0x37d], r5
  stxh [r10-0x380], r1
  ldxdw r1, [r9+0x4c]
  stxdw [r10-0x379], r1
  ldxdw r1, [r9+0x54]
  stxdw [r10-0x371], r1
  ldxdw r1, [r9+0x5c]
  stxdw [r10-0x369], r1
  ldxb r1, [r9+0x64]
  stxb [r10-0x361], r1
  ldxdw r7, [r9+0x140]
  ldxdw r1, [r7+0x0]
  ldxdw r0, [r1+0x18]
  stxdw [r10-0x250], r0
  ldxdw r0, [r1+0x10]
  stxdw [r10-0x258], r0
  ldxdw r0, [r1+0x8]
  stxdw [r10-0x260], r0
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x268], r1
  ldxdw r0, [r10-0x380]
  jne r1, r0, jmp_1e890
  ldxdw r1, [r10-0x378]
  ldxdw r0, [r10-0x260]
  jne r0, r1, jmp_1e890
  ldxdw r1, [r10-0x370]
  ldxdw r0, [r10-0x258]
  jne r0, r1, jmp_1e890
  mov64 r1, 0x0
  ldxdw r0, [r10-0x368]
  ldxdw r6, [r10-0x250]
  jeq r6, r0, jmp_1e898

jmp_1e890:
  mov64 r1, 0x1

jmp_1e898:
  jeq r1, 0x0, jmp_1ed48
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_165c
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x180], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x170], r1
  mov64 r2, r10
  add64 r2, -0x180
  lddw r1, data_165c
  call fn_5a268
  jne r0, 0x0, jmp_1f680
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x238], r1
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stw [r10-0x1d0], 0x17a4
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x3f
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x398]
  ldxdw r8, [r10-0x3a0]
  ja jmp_1f350

jmp_1ea38:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x180], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x170], r1
  mov64 r2, r10
  add64 r2, -0x180
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_1f680
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x238], r1
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stw [r10-0x1d0], 0x1771
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x2f
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  mov64 r1, r10
  add64 r1, -0x490
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x488]
  ldxdw r8, [r10-0x490]
  ja jmp_1f358

jmp_1ebd0:
  stw [r10-0x2a0], 0x33
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r7, r10
  add64 r7, -0x2a0
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x180], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x170], r1
  mov64 r2, r10
  add64 r2, -0x180
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_1f680
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x238], r1
  stw [r10-0x1d0], 0x17a3
  stb [r10-0x218], 0x2
  stdw [r10-0x268], 0x2
  mov64 r1, r10
  add64 r1, -0x390
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x388]
  ldxdw r8, [r10-0x390]
  ja jmp_1f358

jmp_1ed48:
  stxdw [r10-0x4a8], r5
  ldxb r1, [r9+0x67]
  jge r1, 0x5, jmp_1fc60
  jeq r1, 0x0, jmp_1f1c0
  stxdw [r10-0x4a0], r7
  ldxdw r0, [r9+0x128]
  ldxb r0, [r0+0x10f]
  mov64 r7, 0x40

jmp_1ed88:
  mov64 r6, r9
  add64 r6, r7
  ldxb r8, [r6+0x0]
  mov64 r6, r0
  jeq r8, r6, jmp_1edd0
  mov64 r5, r7
  add64 r5, -0x3f
  add64 r7, 0x1
  jlt r5, r1, jmp_1ed88

jmp_1edd0:
  ldxdw r5, [r10-0x4a0]
  jne r8, r6, jmp_1f1c0
  stxdw [r10-0x4c0], r4
  stxdw [r10-0x4b0], r2
  stxdw [r10-0x4b8], r3
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r2, r5
  call fn_4dad0
  ldxdw r7, [r10-0x260]
  ldxdw r8, [r10-0x268]
  ldxb r6, [r10-0x218]
  jeq r6, 0x2, jmp_1f350
  mov64 r1, r10
  add64 r1, -0x330
  mov64 r2, r10
  add64 r2, -0x258
  mov64 r3, 0x40
  call fn_d23d0
  ldxw r1, [r10-0x217]
  stxw [r10-0x2ef], r1
  ldxw r1, [r10-0x214]
  stxw [r10-0x2ec], r1
  stxb [r10-0x2f0], r6
  stxdw [r10-0x338], r7
  stxdw [r10-0x340], r8
  ldxdw r1, [r9+0x130]
  ldxdw r1, [r1+0x58]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x250], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x258], r3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x260], r3
  ldxdw r3, [r2+0x0]
  stxdw [r10-0x268], r3
  ldxdw r4, [r10-0x320]
  ldxdw r6, [r10-0x498]
  jne r4, r3, jmp_1ef60
  ldxdw r3, [r10-0x260]
  ldxdw r4, [r10-0x318]
  jne r4, r3, jmp_1ef60
  ldxdw r3, [r10-0x258]
  ldxdw r4, [r10-0x310]
  jne r4, r3, jmp_1ef60
  mov64 r3, 0x0
  ldxdw r4, [r10-0x250]
  ldxdw r5, [r10-0x308]
  jeq r5, r4, jmp_1ef68

jmp_1ef60:
  mov64 r3, 0x1

jmp_1ef68:
  jne r3, 0x0, jmp_1f028
  ldxdw r3, [r9+0x128]
  ldxdw r4, [r2+0x18]
  stxdw [r10-0x250], r4
  ldxdw r4, [r2+0x10]
  stxdw [r10-0x258], r4
  ldxdw r4, [r2+0x8]
  stxdw [r10-0x260], r4
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x268], r2
  ldxdw r4, [r3+0x8]
  jne r4, r2, jmp_1f018
  ldxdw r2, [r3+0x10]
  ldxdw r4, [r10-0x260]
  jne r2, r4, jmp_1f018
  ldxdw r2, [r3+0x18]
  ldxdw r4, [r10-0x258]
  jne r2, r4, jmp_1f018
  mov64 r2, 0x0
  ldxdw r3, [r3+0x20]
  ldxdw r4, [r10-0x250]
  jeq r3, r4, jmp_1f020

jmp_1f018:
  mov64 r2, 0x1

jmp_1f020:
  jeq r2, 0x0, jmp_1f370

jmp_1f028:
  mov64 r1, r10
  add64 r1, -0x2a0
  lddw r2, data_1684
  call fn_594a8
  stdw [r10-0xe0], 0x0
  stdw [r10-0xe8], 0x1
  stdw [r10-0xf0], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0x180], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x170], r1
  mov64 r2, r10
  add64 r2, -0x180
  lddw r1, data_1684
  call fn_5a268
  jne r0, 0x0, jmp_1f680
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0x298]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x238], r1
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stw [r10-0x1d0], 0x17a7
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x4b
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  mov64 r1, r10
  add64 r1, -0x3b0
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x3a8]
  ldxdw r8, [r10-0x3b0]
  ja jmp_1f358

jmp_1f1c0:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x178], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x180], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x170], r1
  mov64 r2, r10
  add64 r2, -0x180
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_1f680
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x238], r1
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stw [r10-0x1d0], 0x1772
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x45
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  mov64 r1, r10
  add64 r1, -0x480
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x478]
  ldxdw r8, [r10-0x480]

jmp_1f350:
  ldxdw r6, [r10-0x498]

jmp_1f358:
  stxdw [r6+0x8], r7
  stxdw [r6+0x0], r8
  exit

jmp_1f370:
  ldxdw r2, [r9+0x140]
  ldxdw r2, [r2+0x0]
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x168], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x170], r3
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x178], r3
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x180], r2
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x250], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x258], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x260], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x268], r1
  mov64 r1, r10
  add64 r1, -0x2e8
  mov64 r2, r10
  add64 r2, -0x180
  mov64 r3, r10
  add64 r3, -0x268
  call fn_bc628
  ldxdw r1, [r9+0x148]
  ldxdw r1, [r1+0x0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x250], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x258], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x260], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x268], r1
  ldxdw r2, [r10-0x2e8]
  jne r1, r2, jmp_1f4f8
  ldxdw r1, [r10-0x2e0]
  ldxdw r2, [r10-0x260]
  jne r2, r1, jmp_1f4f8
  ldxdw r1, [r10-0x2d8]
  ldxdw r2, [r10-0x258]
  jne r2, r1, jmp_1f4f8
  mov64 r1, 0x0
  ldxdw r2, [r10-0x2d0]
  ldxdw r3, [r10-0x250]
  jeq r3, r2, jmp_1f500

jmp_1f4f8:
  mov64 r1, 0x1

jmp_1f500:
  jeq r1, 0x0, jmp_1f5d8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_165c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x230
  lddw r2, data_165c
  call fn_9838
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x54
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  stw [r10-0x1d0], 0x17a4
  mov64 r1, r10
  add64 r1, -0x3c0
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x3b8]
  ldxdw r8, [r10-0x3c0]
  ja jmp_1f358

jmp_1f5d8:
  mov64 r1, r10
  add64 r1, -0x268
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0x260
  ldxdw r2, [r10-0x268]
  jeq r2, 0x0, jmp_1f6d0
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x170], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x178], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x180], r1
  mov64 r1, r10
  add64 r1, -0x470
  mov64 r2, r10
  add64 r2, -0x180
  call fn_be7f0
  ldxdw r7, [r10-0x468]
  ldxdw r8, [r10-0x470]
  ja jmp_1f358

jmp_1f680:
  mov64 r3, r10
  add64 r3, -0x2c8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_1f6d0:
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2c8], r1
  stxdw [r10-0x2c0], r5
  stxdw [r10-0x2b8], r4
  stxdw [r10-0x2b0], r3
  stxdw [r10-0x160], r2
  stxdw [r10-0x2a8], r2
  ldxdw r3, [r9+0x150]
  ldxdw r2, [r9+0x128]
  ldxdw r1, [r10-0x4b0]
  ldxdw r4, [r1+0x10]
  ldxdw r1, [r1+0x18]
  mov64 r5, r10
  add64 r5, -0x2c8
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r5, r10
  call fn_11668
  ldxdw r4, [r10-0x268]
  ldxdw r5, [r10-0x260]
  ldxh r1, [r10-0x254]
  jne r1, 0x2, jmp_1f7d0
  mov64 r7, r5
  mov64 r8, r4
  ja jmp_1f358

jmp_1f7d0:
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_1f8e8
  ldxdw r7, [r10-0x2f8]
  ldxdw r1, [r10-0x300]
  mov64 r3, r1
  add64 r3, r7
  mov64 r2, 0x1
  jlt r3, r1, jmp_1f820
  mov64 r2, 0x0

jmp_1f820:
  ldxw r3, [r10-0x258]
  and64 r2, 0x1
  stxdw [r10-0x4a0], r3
  jne r2, 0x0, jmp_206a0
  add64 r7, r1

jmp_1f848:
  ldxdw r1, [r9+0x148]
  ldxdw r2, [r1+0x48]
  stxdw [r10-0xff8], r3
  stxdw [r10-0x4c8], r5
  stxdw [r10-0x1000], r5
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r5, r10
  mov64 r3, 0x0
  mov64 r8, r4
  call fn_4e128
  ldxw r1, [r10-0x268]
  jne r1, 0x1, jmp_1f9b8
  ldxw r2, [r10-0x264]
  mov64 r1, r10
  add64 r1, -0x450
  call fn_5a078
  ldxdw r7, [r10-0x448]
  ldxdw r8, [r10-0x450]
  ja jmp_1f358

jmp_1f8e8:
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x230
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x5e
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  stw [r10-0x1d0], 0x1791
  mov64 r1, r10
  add64 r1, -0x460
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x458]
  ldxdw r8, [r10-0x460]
  ja jmp_1f358

jmp_1f9b8:
  ldxdw r1, [r10-0x258]
  ldxdw r0, [r10-0x260]
  mov64 r3, 0x1
  mov64 r2, 0x1
  jlt r7, r0, jmp_1f9e8
  mov64 r2, 0x0

jmp_1f9e8:
  mov64 r4, r1
  add64 r4, r2
  mov64 r2, 0x1
  jgt r7, r0, jmp_1fa10
  mov64 r2, 0x0

jmp_1fa10:
  neg64 r4
  mov64 r5, r7
  sub64 r5, r0
  mov64 r0, 0x1
  jgt r5, r7, jmp_1fb30
  mov64 r0, 0x0
  jeq r4, 0x0, jmp_1fb38

jmp_1fa48:
  jeq r4, 0x0, jmp_1fb48

jmp_1fa50:
  mov64 r0, r3
  mov64 r3, 0x0
  jeq r0, 0x0, jmp_1fb58

jmp_1fa68:
  mov64 r6, 0x0
  jne r0, 0x0, jmp_1fb70

jmp_1fa78:
  mov64 r6, r5
  jne r1, 0x0, jmp_1fb78

jmp_1fa88:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_1fb90

jmp_1fa98:
  ldxdw r1, [r10-0x4a0]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x4c8]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r5, r10
  mov64 r2, r6
  mov64 r4, r8
  call fn_4ef20
  ldxw r1, [r10-0x268]
  jne r1, 0x1, jmp_1fc80
  ldxw r2, [r10-0x264]
  mov64 r1, r10
  add64 r1, -0x440
  call fn_5a078
  ldxdw r7, [r10-0x438]
  ldxdw r8, [r10-0x440]
  ja jmp_1f350

jmp_1fb30:
  jne r4, 0x0, jmp_1fa48

jmp_1fb38:
  mov64 r3, 0x0
  jne r4, 0x0, jmp_1fa50

jmp_1fb48:
  mov64 r3, 0x0
  jne r0, 0x0, jmp_1fa68

jmp_1fb58:
  mov64 r3, r4
  mov64 r6, 0x0
  jeq r0, 0x0, jmp_1fa78

jmp_1fb70:
  jeq r1, 0x0, jmp_1fa88

jmp_1fb78:
  mov64 r2, 0x0
  and64 r2, 0x1
  jne r2, 0x0, jmp_1fa98

jmp_1fb90:
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_16a4
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x230
  lddw r2, data_16a4
  call fn_9838
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x6a
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  stw [r10-0x1d0], 0x17a5
  mov64 r1, r10
  add64 r1, -0x3e0
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x3d8]
  ldxdw r8, [r10-0x3e0]
  ja jmp_1f350

jmp_1fc60:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_1fc80:
  ldxdw r1, [r10-0x258]
  jeq r1, 0x0, jmp_1fcc8
  mov64 r1, r10
  add64 r1, -0x430
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x428]
  ldxdw r8, [r10-0x430]
  ja jmp_1f350

jmp_1fcc8:
  ldxdw r2, [r10-0x260]
  ldxdw r1, [r10-0x4b8]
  jle r1, r2, jmp_1fdb0
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_16f8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x230
  lddw r2, data_16f8
  call fn_9838
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x78
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  stw [r10-0x1d0], 0x17a6
  mov64 r1, r10
  add64 r1, -0x420
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x418]
  ldxdw r8, [r10-0x420]
  ja jmp_1f350

jmp_1fdb0:
  ldxdw r1, [r9+0x138]
  ldxdw r2, [r1+0x48]
  ldxdw r1, [r10-0x4b8]
  jge r2, r1, jmp_1fea0
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_1650
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x230
  lddw r2, data_1650
  call fn_9838
  lddw r1, str_17a8
  stxdw [r10-0x260], r1
  stb [r10-0x218], 0x2
  stw [r10-0x250], 0x7d
  stdw [r10-0x258], 0x2c
  stdw [r10-0x268], 0x0
  stw [r10-0x1d0], 0x1775
  mov64 r1, r10
  add64 r1, -0x410
  mov64 r2, r10
  add64 r2, -0x268
  call fn_be760
  ldxdw r7, [r10-0x408]
  ldxdw r8, [r10-0x410]
  ja jmp_1f350

jmp_1fea0:
  ldxdw r1, [r10-0x4c0]
  stxb [r10-0x26a], r1
  ldxb r1, [r9+0x65]
  mov64 r2, r10
  add64 r2, -0x269
  stxdw [r10-0x280], r2
  mov64 r2, r10
  add64 r2, -0x26a
  stxdw [r10-0x290], r2
  lddw r2, str_1775
  stxdw [r10-0x2a0], r2
  stxb [r10-0x269], r1
  stdw [r10-0x278], 0x1
  stdw [r10-0x288], 0x1
  stdw [r10-0x298], 0xe
  ldxdw r2, [r9+0x158]
  mov64 r1, r10
  add64 r1, -0x250
  call fn_d5c0
  ldxdw r2, [r9+0x68]
  mov64 r8, r10
  add64 r8, -0xf0
  mov64 r1, r8
  call fn_d5c0
  ldxdw r1, [r9+0x138]
  ldxdw r2, [r1+0x0]
  mov64 r7, r10
  add64 r7, -0x180
  mov64 r1, r7
  call fn_d5c0
  ldxdw r1, [r9+0x148]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x150
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r8
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x2a0
  stxdw [r10-0xf0], r1
  stdw [r10-0xe8], 0x3
  mov64 r1, r10
  add64 r1, -0x220
  mov64 r2, r7
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0x190], r1
  stdw [r10-0x188], 0x1
  stdw [r10-0x258], 0x0
  stdw [r10-0x260], 0x8
  stdw [r10-0x268], 0x0
  mov64 r1, r10
  add64 r1, -0x3f0
  mov64 r2, r10
  add64 r2, -0x268
  ldxdw r3, [r10-0x4b8]
  call fn_b7360
  ldxdw r8, [r10-0x3f0]
  jne r8, 0x2, jmp_203e8
  mov64 r2, r9
  add64 r2, 0xb8
  mov64 r1, r10
  add64 r1, -0xc0
  call fn_d5c0
  ldxdw r1, [r10-0x4b0]
  ldxb r1, [r1+0x20]
  stxdw [r10-0x4a0], r1
  ldxdw r1, [r9+0x118]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x250], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x258], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x260], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x268], r1
  ldxdw r1, [r9+0x68]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x230], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x238], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x240], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r9+0x130]
  ldxdw r1, [r1+0x58]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x1f0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x1f8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x200], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x208], r1
  ldxdw r1, [r10-0x4a8]
  stxw [r10-0x225], r1
  ldxb r1, [r10-0x342]
  stxb [r10-0x226], r1
  ldxh r1, [r10-0x344]
  stxh [r10-0x228], r1
  ldxb r1, [r10-0x348]
  stxb [r10-0x209], r1
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x211], r1
  ldxdw r1, [r10-0x358]
  stxdw [r10-0x219], r1
  ldxdw r1, [r10-0x360]
  stxdw [r10-0x221], r1
  ldxdw r1, [r10-0x4b8]
  stxdw [r10-0x1e0], r1
  stxdw [r10-0x1e8], r6
  mov64 r1, r10
  add64 r1, -0x90
  mov64 r2, r10
  add64 r2, -0x268
  call fn_a0b70
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x38], r2
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r1
  ldxdw r2, [r10-0x80]
  add64 r1, r2
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r10
  add64 r2, -0x60
  call fn_0000
  ldxdw r7, [r10-0x70]
  ldxdw r8, [r10-0x68]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jgt r1, r2, jmp_203f8
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_20400

jmp_20398:
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_20420

jmp_203b0:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_20438

jmp_203d0:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_203e8:
  ldxdw r7, [r10-0x3e8]
  ja jmp_1f350

jmp_203f8:
  jne r4, 0x0, jmp_20398

jmp_20400:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_203b0

jmp_20420:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_203d0

jmp_20438:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0xc0]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x178], r1
  stdw [r10-0x170], 0x1
  stdw [r10-0x180], 0x1
  mov64 r9, r10
  add64 r9, -0x268
  mov64 r5, r10
  add64 r5, -0x180
  mov64 r1, r9
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, r8
  call fn_c96c0
  mov64 r7, r10
  add64 r7, -0x180
  mov64 r2, r10
  add64 r2, -0xc0
  mov64 r1, r7
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0xe0], r1
  lddw r1, str_17d4
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x4a0]
  stxb [r10-0x1], r1
  stdw [r10-0x10], 0x2
  stdw [r10-0xd8], 0x1
  stdw [r10-0xe8], 0x11
  mov64 r1, r10
  add64 r1, -0x18
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r7
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x30]
  jne r2, r1, jmp_20638
  mov64 r8, 0x2
  ja jmp_20670

jmp_20638:
  mov64 r1, r10
  add64 r1, -0x400
  mov64 r2, r10
  add64 r2, -0x30
  call fn_be7f0
  ldxdw r7, [r10-0x3f8]
  ldxdw r8, [r10-0x400]

jmp_20670:
  mov64 r1, r10
  add64 r1, -0x180
  call fn_a258
  jne r8, 0x2, jmp_1f350
  mov64 r8, 0x2
  ja jmp_1f350

jmp_206a0:
  mov64 r1, r10
  add64 r1, -0x3d0
  mov64 r2, 0x10
  mov64 r7, r4
  mov64 r8, r5
  call fn_5a078
  ldxdw r3, [r10-0x4a0]
  mov64 r5, r8
  mov64 r4, r7
  ldxdw r7, [r10-0x3c8]
  ldxdw r8, [r10-0x3d0]
  jne r8, 0x2, jmp_1f358
  ja jmp_1f848

fn_20708:
  mov64 r9, r3
  stxdw [r10-0x450], r1
  ldxdw r7, [r9+0x18]
  jeq r7, 0x0, jmp_20738
  ldxdw r8, [r9+0x20]
  jle r7, r8, jmp_208e8

jmp_20738:
  mov64 r1, r10
  add64 r1, -0x398
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x280], r1
  mov64 r1, r10
  add64 r1, -0x138
  stxdw [r10-0x288], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x278], r1
  mov64 r2, r10
  add64 r2, -0x288
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_21858
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x340], r1
  lddw r1, str_17e5
  stxdw [r10-0x368], r1
  stw [r10-0x2d8], 0x17a8
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x23
  stdw [r10-0x360], 0x30
  stdw [r10-0x370], 0x0
  mov64 r1, r10
  add64 r1, -0x448
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x440]
  ldxdw r6, [r10-0x448]

jmp_208c8:
  ldxdw r1, [r10-0x450]

jmp_208d0:
  stxdw [r1+0x8], r8
  stxdw [r1+0x0], r6
  exit

jmp_208e8:
  stxdw [r10-0x458], r2
  ldxdw r6, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x3a8
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, 0xa
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x3a0]
  jne r2, 0x0, jmp_20c30
  mov64 r1, 0x0
  mov64 r2, -0x1
  jeq r1, 0x0, jmp_20c40

jmp_20960:
  jge r8, r2, jmp_20c50

jmp_20968:
  ldxb r1, [r6+0x78]
  jge r1, 0x13, jmp_20de8
  ldxw r1, [r6+0x48]
  and64 r1, 0x1
  stxdw [r10-0x468], r8
  jeq r1, 0x0, jmp_20b88
  ldxdw r1, [r6+0x64]
  stxdw [r10-0x380], r1
  ldxdw r1, [r6+0x5c]
  stxdw [r10-0x388], r1
  ldxdw r1, [r6+0x54]
  stxdw [r10-0x390], r1
  ldxdw r1, [r6+0x4c]
  stxdw [r10-0x398], r1
  stxdw [r10-0x460], r6
  ldxdw r1, [r6+0x110]
  ldxb r6, [r1+0x173]
  jeq r6, 0x0, jmp_20b78
  mov64 r2, 0x0
  mov64 r1, 0x1

jmp_20a08:
  mov64 r8, r1
  mov64 r1, r10
  add64 r1, -0xf8
  stxdw [r10-0x278], r1
  lddw r1, str_1775
  stxdw [r10-0x288], r1
  stxb [r10-0xf8], r2
  stdw [r10-0x270], 0x1
  stdw [r10-0x280], 0xe
  mov64 r1, r10
  add64 r1, -0x370
  mov64 r2, r10
  add64 r2, -0x288
  mov64 r3, 0x2
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x358]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x360]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0x368]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x370]
  stxdw [r10-0x138], r1
  ldxdw r2, [r10-0x398]
  jne r2, r1, jmp_20b38
  ldxdw r1, [r10-0x130]
  ldxdw r2, [r10-0x390]
  jne r2, r1, jmp_20b38
  ldxdw r1, [r10-0x128]
  ldxdw r2, [r10-0x388]
  jne r2, r1, jmp_20b38
  mov64 r1, 0x0
  ldxdw r2, [r10-0x120]
  ldxdw r3, [r10-0x380]
  jeq r3, r2, jmp_20b40

jmp_20b38:
  mov64 r1, 0x1

jmp_20b40:
  jeq r1, 0x0, jmp_21338
  mov64 r1, r8
  add64 r1, 0x1
  mov64 r3, r8
  and64 r3, 0xff
  mov64 r2, r8
  jlt r3, r6, jmp_20a08

jmp_20b78:
  ldxdw r6, [r10-0x460]
  ldxdw r8, [r10-0x468]

jmp_20b88:
  mov64 r1, r10
  add64 r1, -0x370
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0x368
  ldxdw r2, [r10-0x370]
  jeq r2, 0x0, jmp_20f80
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x278], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x280], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x288], r1
  mov64 r1, r10
  add64 r1, -0x438
  mov64 r2, r10
  add64 r2, -0x288
  call fn_be7f0
  ldxdw r8, [r10-0x430]
  ldxdw r6, [r10-0x438]
  ja jmp_208c8

jmp_20c30:
  mov64 r2, -0x1
  jne r1, 0x0, jmp_20960

jmp_20c40:
  ldxdw r2, [r10-0x3a8]
  jlt r8, r2, jmp_20968

jmp_20c50:
  mov64 r1, r10
  add64 r1, -0x398
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x280], r1
  mov64 r1, r10
  add64 r1, -0x138
  stxdw [r10-0x288], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x278], r1
  mov64 r2, r10
  add64 r2, -0x288
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_21858
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x340], r1
  lddw r1, str_17e5
  stxdw [r10-0x368], r1
  stw [r10-0x2d8], 0x17a8
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x2e
  stdw [r10-0x360], 0x30
  stdw [r10-0x370], 0x0
  mov64 r1, r10
  add64 r1, -0x3b8
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x3b0]
  ldxdw r6, [r10-0x3b8]
  ja jmp_208c8

jmp_20de8:
  mov64 r1, r10
  add64 r1, -0x398
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x280], r1
  mov64 r1, r10
  add64 r1, -0x138
  stxdw [r10-0x288], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x278], r1
  mov64 r2, r10
  add64 r2, -0x288
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_21858
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x340], r1
  lddw r1, str_17e5
  stxdw [r10-0x368], r1
  stw [r10-0x2d8], 0x1771
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x33
  stdw [r10-0x360], 0x30
  stdw [r10-0x370], 0x0
  mov64 r1, r10
  add64 r1, -0x3c8
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x3c0]
  ldxdw r6, [r10-0x3c8]
  ja jmp_208c8

jmp_20f80:
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x398], r1
  stxdw [r10-0x390], r5
  stxdw [r10-0x388], r4
  stxdw [r10-0x380], r3
  stxdw [r10-0x268], r2
  stxdw [r10-0x378], r2
  ldxh r4, [r9+0x28]
  ldxdw r3, [r9+0x10]
  ldxdw r2, [r9+0x8]
  ldxdw r1, [r6+0xa0]
  ldxdw r1, [r1+0x0]
  ldxdw r5, [r1+0x18]
  stxdw [r10-0x270], r5
  ldxdw r5, [r1+0x10]
  stxdw [r10-0x278], r5
  ldxdw r5, [r1+0x8]
  stxdw [r10-0x280], r5
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x288], r1
  mov64 r1, r10
  add64 r1, -0x370
  mov64 r5, r10
  add64 r5, -0x288
  stxdw [r10-0x470], r4
  call fn_4fdc8
  ldxdw r8, [r10-0x368]
  mov64 r2, r6
  ldxdw r6, [r10-0x370]
  ldxb r3, [r10-0x328]
  jeq r3, 0x2, jmp_208c8
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x480], r1
  stxdw [r10-0x460], r2
  mov64 r2, r10
  add64 r2, -0x360
  stxdw [r10-0x478], r3
  mov64 r3, 0x38
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd3
  stxdw [r10-0x488], r1
  mov64 r2, r10
  add64 r2, -0x327
  mov64 r3, 0x9b
  call fn_d23d0
  ldxb r1, [r10-0x28c]
  stxdw [r10-0x490], r1
  stxdw [r10-0x368], r8
  stxdw [r10-0x370], r6
  mov64 r1, r10
  add64 r1, -0x360
  ldxdw r2, [r10-0x480]
  mov64 r3, 0x38
  call fn_d23d0
  ldxdw r1, [r10-0x478]
  stxb [r10-0x328], r1
  mov64 r1, r10
  add64 r1, -0x327
  ldxdw r2, [r10-0x488]
  mov64 r3, 0x9b
  call fn_d23d0
  ldxdw r1, [r10-0x460]
  ldxdw r1, [r1+0x120]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x270], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x278], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x280], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x288], r1
  ldxdw r2, [r10-0x370]
  jne r1, r2, jmp_21250
  ldxdw r1, [r10-0x368]
  ldxdw r2, [r10-0x280]
  jne r2, r1, jmp_21250
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r10-0x278]
  jne r2, r1, jmp_21250
  mov64 r1, 0x0
  ldxdw r2, [r10-0x358]
  ldxdw r3, [r10-0x270]
  jeq r3, r2, jmp_21258

jmp_21250:
  mov64 r1, 0x1

jmp_21258:
  ldxdw r3, [r10-0x458]
  jeq r1, 0x0, jmp_21408
  mov64 r1, r10
  add64 r1, -0x268
  lddw r2, data_1670
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x250
  lddw r2, data_1670
  call fn_9838
  lddw r1, str_17e5
  stxdw [r10-0x280], r1
  stb [r10-0x238], 0x2
  stw [r10-0x270], 0x45
  stdw [r10-0x278], 0x30
  stdw [r10-0x288], 0x0
  stw [r10-0x1f0], 0x177f
  mov64 r1, r10
  add64 r1, -0x3e8
  mov64 r2, r10
  add64 r2, -0x288
  call fn_be760
  ldxdw r8, [r10-0x3e0]
  ldxdw r6, [r10-0x3e8]
  ja jmp_208c8

jmp_21338:
  mov64 r1, r10
  add64 r1, -0x350
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x338
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_17e5
  stxdw [r10-0x368], r1
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x3e
  stdw [r10-0x360], 0x30
  stdw [r10-0x370], 0x0
  stw [r10-0x2d8], 0x1771
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x3d0]
  ldxdw r6, [r10-0x3d8]
  ja jmp_208c8

jmp_21408:
  ldxdw r4, [r10-0x460]
  ldxdw r1, [r4+0xa0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r4+0x110]
  mov64 r0, r4
  ldxb r2, [r2+0x174]
  stxdw [r10-0x480], r2
  ldxb r2, [r9+0x2a]
  stxdw [r10-0x488], r2
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r1+0x8]
  ldxdw r5, [r1+0x10]
  ldxdw r1, [r1+0x18]
  ldxb r9, [r3+0x22]
  stxdw [r10-0x498], r9
  ldxdw r9, [r0+0x118]
  stxdw [r9+0x20], r1
  stxdw [r9+0x18], r5
  stxdw [r9+0x10], r4
  stxdw [r9+0x8], r2
  stxdw [r9+0x30], r8
  stxdw [r9+0x28], r6
  mov64 r1, r9
  add64 r1, 0x38
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r6, r3
  mov64 r3, 0x38
  call fn_d23d0
  ldxdw r1, [r10-0x478]
  stxb [r9+0x70], r1
  mov64 r1, r9
  add64 r1, 0x71
  mov64 r2, r10
  add64 r2, -0xd3
  mov64 r3, 0x9b
  call fn_d23d0
  ldxdw r1, [r10-0x488]
  stxb [r9+0x112], r1
  ldxdw r8, [r10-0x490]
  stxb [r9+0x110], r8
  ldxdw r1, [r10-0x480]
  stxb [r9+0x10f], r1
  ldxdw r1, [r10-0x498]
  stxb [r9+0x10e], r1
  ldxdw r1, [r10-0x470]
  stxh [r9+0x10c], r1
  stb [r9+0x111], 0x0
  ldxdw r9, [r10-0x460]
  ldxdw r3, [r9+0x120]
  ldxdw r2, [r9+0x118]
  ldxdw r4, [r6+0x10]
  ldxdw r1, [r6+0x18]
  mov64 r5, r10
  add64 r5, -0x398
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x288
  mov64 r5, r10
  call fn_518e0
  ldxh r1, [r10-0x274]
  jeq r1, 0x2, jmp_21900
  ldxdw r6, [r10-0x288]
  ldxdw r8, [r10-0x280]
  jeq r1, 0x3, jmp_208c8
  ldxw r4, [r10-0x278]
  lsh64 r4, 0x20
  arsh64 r4, 0x20
  add64 r4, 0x6
  mov64 r1, r4
  lsh64 r1, 0x20
  arsh64 r1, 0x20
  jeq r1, r4, jmp_21698
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x420]
  ldxdw r6, [r10-0x428]
  ja jmp_208c8

jmp_21698:
  mov64 r1, r10
  add64 r1, -0x288
  mov64 r2, r6
  mov64 r3, r8
  call fn_3d580
  ldxdw r8, [r10-0x278]
  ldxdw r6, [r10-0x280]
  ldxdw r1, [r10-0x288]
  jne r1, 0x0, jmp_208c8
  mov64 r1, 0x1
  jlt r6, r7, jmp_21718
  mov64 r1, 0x0
  jne r8, 0x0, jmp_21720

jmp_21700:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_21738
  ja jmp_21788

jmp_21718:
  jeq r8, 0x0, jmp_21700

jmp_21720:
  mov64 r1, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_21788

jmp_21738:
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r3, [r10-0x468]
  jle r6, r3, jmp_218a8
  mov64 r1, 0x0
  jne r8, 0x0, jmp_218b0

jmp_21768:
  jeq r8, 0x0, jmp_218c0

jmp_21770:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_218d0

jmp_21788:
  mov64 r1, r10
  add64 r1, -0x268
  lddw r2, data_1668
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x250
  lddw r2, data_1668
  call fn_9838
  lddw r1, str_17e5
  stxdw [r10-0x280], r1
  stb [r10-0x238], 0x2
  stw [r10-0x270], 0x64
  stdw [r10-0x278], 0x30
  stdw [r10-0x288], 0x0
  stw [r10-0x1f0], 0x17b6
  mov64 r1, r10
  add64 r1, -0x418
  mov64 r2, r10
  add64 r2, -0x288
  call fn_be760
  ldxdw r8, [r10-0x410]
  ldxdw r6, [r10-0x418]
  ja jmp_208c8

jmp_21858:
  mov64 r3, r10
  add64 r3, -0xf8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_218a8:
  jeq r8, 0x0, jmp_21768

jmp_218b0:
  mov64 r2, 0x0
  jne r8, 0x0, jmp_21770

jmp_218c0:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_21788

jmp_218d0:
  ldxdw r9, [r10-0x460]
  ldxdw r1, [r9+0x118]
  ldxb r2, [r1+0x111]
  or64 r2, 0x1
  stxb [r1+0x111], r2
  ldxdw r8, [r10-0x490]

jmp_21900:
  ldxdw r1, [r9+0x110]
  ldxb r2, [r1+0x174]
  mov64 r6, r9
  jeq r2, 0xff, jmp_21f38
  add64 r2, 0x1
  stxb [r1+0x174], r2
  mov64 r2, r6
  add64 r2, 0xa8
  mov64 r1, r10
  add64 r1, -0x1e8
  call fn_d5c0
  ldxdw r1, [r10-0x458]
  ldxb r9, [r1+0x23]
  ldxdw r1, [r6+0x108]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x188], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x190], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x198], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x1a0], r1
  ldxdw r1, [r6+0xa0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xe0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xe8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xf0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r6+0x120]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x120], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x128], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x130], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x138], r1
  jge r8, 0x4, jmp_21fe0
  mov64 r1, r8
  mul64 r1, 0x4c
  mov64 r2, r10
  add64 r2, -0x370
  mov64 r3, r2
  add64 r3, r1
  mov64 r6, r10
  add64 r6, -0x288
  mov64 r1, r6
  call fn_04d8
  ldxdw r1, [r10-0x188]
  stxdw [r10-0x258], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0x268], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x270], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x250], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x470]
  stxh [r10-0x210], r1
  stxb [r10-0x20e], r8
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r6
  call fn_a0468
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x158], r2
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x170], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0x178], r1
  stxdw [r10-0x180], r1
  ldxdw r2, [r10-0x1a8]
  add64 r1, r2
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0x180
  call fn_0000
  ldxdw r6, [r10-0x198]
  ldxdw r7, [r10-0x190]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jgt r1, r2, jmp_21d00
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_21d08

jmp_21cb0:
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_21d28

jmp_21cc8:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_21d40

jmp_21ce8:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_21d00:
  jne r4, 0x0, jmp_21cb0

jmp_21d08:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_21cc8

jmp_21d28:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_21ce8

jmp_21d40:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0x1e8]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x130], r1
  stdw [r10-0x128], 0x1
  stdw [r10-0x138], 0x1
  mov64 r8, r10
  add64 r8, -0x288
  mov64 r5, r10
  add64 r5, -0x138
  mov64 r1, r8
  lddw r2, data_272e
  mov64 r3, r6
  mov64 r4, r7
  call fn_c96c0
  mov64 r6, r10
  add64 r6, -0x138
  mov64 r2, r10
  add64 r2, -0x1e8
  mov64 r1, r6
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xf8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0xd4
  stxdw [r10-0xe8], r1
  lddw r1, str_17d4
  stxdw [r10-0xf8], r1
  stxb [r10-0xd4], r9
  stdw [r10-0x100], 0x2
  stdw [r10-0xe0], 0x1
  stdw [r10-0xf0], 0x11
  mov64 r1, r10
  add64 r1, -0x108
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r5, r10
  mov64 r2, r8
  mov64 r3, r6
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x150]
  jne r2, r1, jmp_21f70
  mov64 r6, 0x2
  ja jmp_21fa8

jmp_21f38:
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x400]
  ldxdw r6, [r10-0x408]
  ja jmp_208c8

jmp_21f70:
  mov64 r1, r10
  add64 r1, -0x3f8
  mov64 r2, r10
  add64 r2, -0x150
  call fn_be7f0
  ldxdw r8, [r10-0x3f0]
  ldxdw r6, [r10-0x3f8]

jmp_21fa8:
  mov64 r1, r10
  add64 r1, -0x138
  call fn_a258
  ldxdw r1, [r10-0x450]
  jne r6, 0x2, jmp_208d0
  mov64 r6, 0x2
  ja jmp_208d0

jmp_21fe0:
  mov64 r1, r8
  mov64 r2, 0x3
  lddw r3, data_6308
  call fn_cf460

fn_22008:
  mov64 r9, r3
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r9
  and64 r1, 0xffff
  jge r1, 0x2711, jmp_221a8
  stxdw [r10-0x360], r6
  ldxdw r8, [r7+0x8]
  ldxdw r1, [r8+0x228]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x198], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x1a0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x1a8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x1b0], r1
  ldxb r6, [r7+0x20]
  stdw [r10-0x10], 0x1
  stdw [r10-0x8], 0x0
  stdw [r10-0x18], 0x0
  mov64 r1, r10
  add64 r1, -0x18
  lddw r2, data_60e0
  call fn_bbb0
  ldxdw r1, [r10-0x10]
  stb [r1+0x0], 0x6
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x1c8], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x1c0], r1
  stdw [r10-0x8], 0x1
  stdw [r10-0x1b8], 0x1
  mov64 r2, r10
  add64 r2, -0x1c8
  mov64 r1, r8
  mov64 r3, 0x38
  call fn_d23d0
  stxb [r8+0x38], r6
  ldxb r1, [r7+0x21]
  stxdw [r10-0x368], r1
  mov64 r1, r10
  add64 r1, -0x1c8
  call fn_1db78
  ldxb r6, [r10-0x1c7]
  jne r6, 0x7, jmp_22350
  ldxdw r7, [r10-0x1b8]
  ldxdw r8, [r10-0x1c0]
  ldxdw r6, [r10-0x360]
  ja jmp_22338

jmp_221a8:
  mov64 r1, r10
  add64 r1, -0x338
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x30], 0x0
  stdw [r10-0x38], 0x1
  stdw [r10-0x40], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x318], r1
  mov64 r1, r10
  add64 r1, -0x40
  stxdw [r10-0x320], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x310], r1
  mov64 r2, r10
  add64 r2, -0x320
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_22ec0
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x180], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0x188], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x190], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x1a0], r1
  ldxdw r1, [r10-0x328]
  stxdw [r10-0x198], r1
  lddw r1, str_1815
  stxdw [r10-0x1c0], r1
  stw [r10-0x130], 0x1771
  stb [r10-0x178], 0x2
  stw [r10-0x1b0], 0x14
  stdw [r10-0x1b8], 0x35
  stdw [r10-0x1c8], 0x0
  mov64 r1, r10
  add64 r1, -0x348
  mov64 r2, r10
  add64 r2, -0x1c8
  call fn_be760
  ldxdw r7, [r10-0x340]
  ldxdw r8, [r10-0x348]

jmp_22338:
  stxdw [r6+0x0], r8
  stxdw [r6+0x8], r7
  exit

jmp_22350:
  ldxw r1, [r10-0x1c6]
  stxw [r10-0x40], r1
  ldxh r1, [r10-0x1c2]
  stxh [r10-0x3c], r1
  ldxdw r1, [r10-0x1c0]
  stxdw [r10-0x370], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x378], r1
  ldxb r1, [r10-0x1c8]
  stxdw [r10-0x388], r1
  mov64 r1, r10
  add64 r1, -0x320
  stxdw [r10-0x380], r1
  mov64 r2, r10
  add64 r2, -0x1b0
  mov64 r3, 0x158
  call fn_d23d0
  stxb [r8+0xa9], r6
  ldxdw r1, [r10-0x388]
  stxb [r8+0xa8], r1
  ldxw r1, [r10-0x40]
  stxw [r8+0xaa], r1
  ldxh r1, [r10-0x3c]
  stxh [r8+0xae], r1
  ldxdw r1, [r10-0x378]
  stxdw [r8+0xb8], r1
  ldxdw r1, [r10-0x370]
  stxdw [r8+0xb0], r1
  mov64 r1, r8
  add64 r1, 0xc0
  ldxdw r2, [r10-0x380]
  mov64 r3, 0x158
  call fn_d23d0
  ldxdw r1, [r10-0x368]
  stxb [r8+0x21a], r1
  stxh [r8+0x218], r9
  stb [r8+0x21d], 0x1
  sth [r8+0x21b], 0x0
  ldxdw r3, [r8+0x50]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_224b0
  mov64 r2, 0x0

jmp_224b0:
  ldxdw r6, [r8+0x48]
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_22f10
  stxdw [r10-0x368], r3
  ldxdw r9, [r8+0x58]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_22500
  mov64 r2, 0x0

jmp_22500:
  stxdw [r9+0x0], r1
  jeq r2, 0x1, jmp_22f10
  ldxb r1, [r7+0x22]
  stxdw [r10-0x378], r1
  ldxb r1, [r8+0x72]
  stxdw [r10-0x3a0], r1
  ldxb r1, [r8+0x71]
  stxdw [r10-0x398], r1
  ldxb r1, [r8+0x70]
  stxdw [r10-0x390], r1
  ldxdw r1, [r8+0x68]
  stxdw [r10-0x388], r1
  ldxdw r1, [r8+0x60]
  stxdw [r10-0x380], r1
  ldxdw r1, [r8+0x228]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x1b0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x1b8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x1c0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x1c8], r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r2, 0x0
  mov64 r4, 0x1
  mov64 r3, r1
  add64 r3, -0x100
  jle r3, r1, jmp_226f0
  jeq r4, 0x0, jmp_22700

jmp_22610:
  lddw r8, 0x300007f00
  jne r1, 0x0, jmp_22720

jmp_22628:
  stxdw [r10-0x370], r6
  lddw r1, 0x300000007
  jle r8, r1, jmp_22748

jmp_22648:
  lddw r7, 0x300000000
  stxdw [r7+0x0], r8
  lddw r1, 0x138496194a10e11b
  stxdw [r8+0x0], r1
  ldxdw r1, [r10-0x1c8]
  stxdw [r8+0x8], r1
  ldxdw r1, [r10-0x1c0]
  stxdw [r8+0x10], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r8+0x18], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r8+0x20], r1
  mov64 r1, 0x0
  mov64 r6, 0x30
  jsge r6, 0x0, jmp_22770

jmp_226d0:
  mov64 r2, 0x30
  lddw r3, data_6068
  call fn_cb038

jmp_226f0:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_22610

jmp_22700:
  mov64 r2, r3
  lddw r8, 0x300007f00
  jeq r1, 0x0, jmp_22628

jmp_22720:
  mov64 r8, r2
  stxdw [r10-0x370], r6
  lddw r1, 0x300000007
  jgt r8, r1, jmp_22648

jmp_22748:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6df8
  call fn_cb038

jmp_22770:
  call fn_b1c08
  ldxdw r1, [r7+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_227a0
  mov64 r3, r1

jmp_227a0:
  mov64 r2, r3
  sub64 r2, r6
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_227f8
  jeq r4, 0x0, jmp_22808

jmp_227d8:
  lddw r2, 0x300000007
  jgt r7, r2, jmp_22828
  ja jmp_226d0

jmp_227f8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_227d8

jmp_22808:
  mov64 r7, r2
  lddw r2, 0x300000007
  jle r7, r2, jmp_226d0

jmp_22828:
  lddw r6, 0x300000000
  stxdw [r6+0x0], r7
  lddw r1, 0x1d9acb512ea545e4
  stxdw [r7+0x0], r1
  ldxb r1, [r8+0x0]
  stxb [r7+0x8], r1
  ldxb r1, [r8+0x1]
  stxb [r7+0x9], r1
  ldxb r1, [r8+0x2]
  stxb [r7+0xa], r1
  ldxb r1, [r8+0x3]
  stxb [r7+0xb], r1
  ldxb r1, [r8+0x4]
  stxb [r7+0xc], r1
  ldxb r1, [r8+0x5]
  stxb [r7+0xd], r1
  ldxb r1, [r8+0x6]
  stxb [r7+0xe], r1
  ldxb r1, [r8+0x7]
  stxb [r7+0xf], r1
  ldxb r1, [r8+0x8]
  stxb [r7+0x10], r1
  ldxb r1, [r8+0x9]
  stxb [r7+0x11], r1
  ldxb r1, [r8+0xa]
  stxb [r7+0x12], r1
  ldxb r1, [r8+0xb]
  stxb [r7+0x13], r1
  ldxb r1, [r8+0xc]
  stxb [r7+0x14], r1
  ldxb r1, [r8+0xd]
  stxb [r7+0x15], r1
  ldxb r1, [r8+0xe]
  stxb [r7+0x16], r1
  ldxb r1, [r8+0xf]
  stxb [r7+0x17], r1
  ldxb r1, [r8+0x10]
  stxb [r7+0x18], r1
  ldxb r1, [r8+0x11]
  stxb [r7+0x19], r1
  ldxb r1, [r8+0x12]
  stxb [r7+0x1a], r1
  ldxb r1, [r8+0x13]
  stxb [r7+0x1b], r1
  ldxb r1, [r8+0x14]
  stxb [r7+0x1c], r1
  ldxb r1, [r8+0x15]
  stxb [r7+0x1d], r1
  ldxb r1, [r8+0x16]
  stxb [r7+0x1e], r1
  ldxb r1, [r8+0x17]
  stxb [r7+0x1f], r1
  ldxb r1, [r8+0x18]
  stxb [r7+0x20], r1
  ldxb r1, [r8+0x19]
  stxb [r7+0x21], r1
  ldxb r1, [r8+0x1a]
  stxb [r7+0x22], r1
  ldxb r1, [r8+0x1b]
  stxb [r7+0x23], r1
  ldxb r1, [r8+0x1c]
  stxb [r7+0x24], r1
  ldxb r1, [r8+0x1d]
  stxb [r7+0x25], r1
  ldxb r1, [r8+0x1e]
  stxb [r7+0x26], r1
  ldxb r1, [r8+0x1f]
  stxb [r7+0x27], r1
  ldxb r1, [r8+0x20]
  stxb [r7+0x28], r1
  ldxb r1, [r8+0x21]
  stxb [r7+0x29], r1
  ldxb r1, [r8+0x22]
  stxb [r7+0x2a], r1
  ldxb r1, [r8+0x23]
  stxb [r7+0x2b], r1
  ldxb r1, [r8+0x24]
  stxb [r7+0x2c], r1
  ldxb r1, [r8+0x25]
  stxb [r7+0x2d], r1
  ldxb r1, [r8+0x26]
  stxb [r7+0x2e], r1
  ldxb r1, [r8+0x27]
  stxb [r7+0x2f], r1
  call fn_b1c08
  ldxdw r2, [r6+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jle r1, r2, jmp_22d90
  ldxdw r6, [r10-0x360]
  jeq r4, 0x0, jmp_22da8

jmp_22b20:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_22dc8

jmp_22b38:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_22de8

jmp_22b50:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r8, [r10-0x370]
  ldxdw r2, [r8+0x0]
  ldxdw r3, [r8+0x8]
  ldxdw r4, [r8+0x10]
  ldxdw r5, [r8+0x18]
  stxdw [r1+0x18], r5
  stxdw [r1+0x10], r4
  stxdw [r1+0x8], r3
  stxdw [r1+0x0], r2
  sth [r1+0x20], 0x1
  stxdw [r10-0x318], r1
  stdw [r10-0x310], 0x1
  stdw [r10-0x320], 0x1
  mov64 r1, r10
  add64 r1, -0x1c8
  stxdw [r10-0x3a8], r1
  mov64 r5, r10
  add64 r5, -0x320
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, 0x30
  call fn_c96c0
  ldxdw r1, [r10-0x3a0]
  stxb [r10-0x2f6], r1
  ldxdw r1, [r10-0x398]
  stxb [r10-0x2f7], r1
  ldxdw r1, [r10-0x390]
  stxb [r10-0x2f8], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x300], r1
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x308], r1
  stxdw [r10-0x310], r9
  ldxdw r9, [r10-0x368]
  stxdw [r10-0x318], r9
  stxdw [r10-0x320], r8
  mov64 r1, r10
  add64 r1, -0x40
  stxdw [r10-0x338], r1
  mov64 r1, r10
  add64 r1, -0x19
  stxdw [r10-0x30], r1
  lddw r1, str_17d4
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x378]
  stxb [r10-0x19], r1
  stdw [r10-0x330], 0x2
  stdw [r10-0x28], 0x1
  stdw [r10-0x38], 0x11
  mov64 r1, r10
  add64 r1, -0x338
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r3, r10
  add64 r3, -0x320
  mov64 r5, r10
  ldxdw r2, [r10-0x3a8]
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x58]
  jne r2, r1, jmp_22e00
  mov64 r8, 0x2
  ja jmp_22e40

jmp_22d90:
  mov64 r4, 0x0
  ldxdw r6, [r10-0x360]
  jne r4, 0x0, jmp_22b20

jmp_22da8:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_22b38

jmp_22dc8:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_22b50

jmp_22de8:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_22e00:
  mov64 r1, r10
  add64 r1, -0x358
  mov64 r2, r10
  add64 r2, -0x58
  call fn_be7f0
  ldxdw r9, [r10-0x318]
  ldxdw r7, [r10-0x350]
  ldxdw r8, [r10-0x358]

jmp_22e40:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1
  jne r1, 0x0, jmp_22e78
  mov64 r1, r10
  add64 r1, -0x318
  call fn_c25c0

jmp_22e78:
  ldxdw r1, [r10-0x310]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_22338
  mov64 r1, r10
  add64 r1, -0x310
  call fn_c2610
  ja jmp_22338

jmp_22ec0:
  mov64 r3, r10
  add64 r3, -0x1c8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_22f10:
  call abort

fn_22f18:
  mov64 r5, r4
  mov64 r7, r3
  mov64 r6, r1
  ldxdw r8, [r2+0x8]
  stxb [r10-0xf1], r5
  ldxdw r4, [r8+0xb0]
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r5
  mov64 r3, r8
  call fn_4d818
  ldxdw r1, [r10-0x108]
  jne r1, 0x2, jmp_23198
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0xf1
  call fn_1e230
  ldxdw r1, [r10-0xf0]
  jne r1, 0x2, jmp_231a8
  ldxb r9, [r10-0xe8]
  mov64 r3, 0x1
  lsh64 r3, r9
  ldxdw r1, [r8+0xb0]
  ldxw r2, [r1+0x16c]
  mov64 r4, r2
  and64 r4, r3
  jeq r7, 0x0, jmp_231b8
  jeq r4, 0x0, jmp_231d8
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1688
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1688
  call fn_5a268
  jne r0, 0x0, jmp_23508
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_184a
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x179d
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x23
  stdw [r10-0xe0], 0x3b
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r2, [r10-0x120]
  ldxdw r1, [r10-0x128]
  ja jmp_234f0

jmp_23198:
  ldxdw r2, [r10-0x100]
  ja jmp_234f0

jmp_231a8:
  ldxdw r2, [r10-0xe8]
  ja jmp_234f0

jmp_231b8:
  jeq r4, 0x0, jmp_23360
  xor64 r3, -0x1
  and64 r2, r3
  ja jmp_231e0

jmp_231d8:
  or64 r2, r3

jmp_231e0:
  stxw [r1+0x16c], r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, -0x100
  mov64 r2, 0x0
  mov64 r4, 0x1
  jle r3, r1, jmp_232e8
  jeq r4, 0x0, jmp_232f8

jmp_23238:
  lddw r3, 0x300007f00
  jne r1, 0x0, jmp_23318

jmp_23250:
  lddw r1, 0x300000007
  jle r3, r1, jmp_23338

jmp_23268:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r3
  stxb [r3+0x9], r7
  stxb [r3+0x8], r9
  lddw r1, -0x47f9147d987acd1c
  stxdw [r3+0x0], r1
  stxdw [r10-0xf0], r3
  stdw [r10-0xe8], 0xa
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, 0x1
  call fn_c2660
  mov64 r1, 0x2
  ja jmp_234f0

jmp_232e8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_23238

jmp_232f8:
  mov64 r2, r3
  lddw r3, 0x300007f00
  jeq r1, 0x0, jmp_23250

jmp_23318:
  mov64 r3, r2
  lddw r1, 0x300000007
  jgt r3, r1, jmp_23268

jmp_23338:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6e40
  call fn_cb038

jmp_23360:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_16d4
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16d4
  call fn_5a268
  jne r0, 0x0, jmp_23508
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_184a
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x179e
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x28
  stdw [r10-0xe0], 0x3b
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r2, [r10-0x110]
  ldxdw r1, [r10-0x118]

jmp_234f0:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_23508:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_23558:
  mov64 r6, r1
  ldxdw r1, [r3+0x20]
  mov64 r4, r1
  add64 r4, -0x1
  jge r4, 0x4, jmp_236f8
  ldxdw r4, [r3+0x28]
  jge r4, 0x1e13381, jmp_23890
  stxdw [r10-0x358], r4
  stxdw [r10-0x338], r6
  mov64 r4, r3
  add64 r4, 0x30
  stxdw [r10-0x350], r4
  stxdw [r10-0x340], r2
  ldxdw r2, [r2+0x8]
  ldxdw r8, [r3+0x18]
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x368], r4
  ldxdw r3, [r3+0x0]
  stxdw [r10-0x360], r3
  mov64 r0, r8
  add64 r0, r1
  mov64 r3, 0x0
  stxdw [r10-0x348], r2
  ldxdw r4, [r2+0x120]
  ldxb r4, [r4+0x174]
  mov64 r2, r4
  mov64 r9, r8

jmp_23630:
  ldxb r6, [r9+0x0]
  jge r6, r2, jmp_23bd8
  mov64 r4, r3
  add64 r4, 0x1
  add64 r9, 0x1
  mov64 r5, 0x0

jmp_23660:
  jeq r3, r5, jmp_236a0
  jeq r1, r5, jmp_24830
  mov64 r7, r8
  add64 r7, r5
  add64 r5, 0x1
  ldxb r7, [r7+0x0]
  jne r7, r6, jmp_23660
  ja jmp_23a28

jmp_236a0:
  mov64 r3, r4
  jne r9, r0, jmp_23630
  mov64 r5, 0xff
  ldxb r2, [r8+0x0]
  stxdw [r10-0x370], r2
  jne r1, 0x1, jmp_23cb0
  mov64 r7, 0xff
  mov64 r8, 0xff
  ldxdw r6, [r10-0x338]
  ldxdw r9, [r10-0x348]
  ja jmp_23d18

jmp_236f8:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_24740
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1885
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1771
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x23
  stdw [r10-0x248], 0x34
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x2a0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r7, [r10-0x298]
  ldxdw r8, [r10-0x2a0]
  ja jmp_23bc0

jmp_23890:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_24740
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1885
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1771
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x28
  stdw [r10-0x248], 0x34
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x2b0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r7, [r10-0x2a8]
  ldxdw r8, [r10-0x2b0]
  ja jmp_23bc0

jmp_23a28:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16d8
  call fn_5a268
  ldxdw r6, [r10-0x338]
  jne r0, 0x0, jmp_24740
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1885
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1771
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x33
  stdw [r10-0x248], 0x34
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x2d0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r7, [r10-0x2c8]
  ldxdw r8, [r10-0x2d0]

jmp_23bc0:
  stxdw [r6+0x8], r7
  stxdw [r6+0x0], r8
  exit

jmp_23bd8:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_16c0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_16c0
  call fn_9838
  lddw r1, str_1885
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x2e
  stdw [r10-0x248], 0x34
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1772
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r7, [r10-0x2b8]
  ldxdw r8, [r10-0x2c0]
  ldxdw r6, [r10-0x338]
  ja jmp_23bc0

jmp_23cb0:
  ldxb r3, [r8+0x1]
  ldxdw r9, [r10-0x348]
  jne r1, 0x2, jmp_23cd8
  mov64 r7, 0xff
  ja jmp_23ce8

jmp_23cd8:
  ldxb r7, [r8+0x2]
  jne r1, 0x3, jmp_23cf8

jmp_23ce8:
  ldxdw r6, [r10-0x338]
  ja jmp_23d10

jmp_23cf8:
  ldxdw r6, [r10-0x338]
  jne r1, 0x4, jmp_24850
  ldxb r5, [r8+0x3]

jmp_23d10:
  mov64 r8, r3

jmp_23d18:
  ldxdw r3, [r9+0x120]
  ldxb r2, [r3+0x173]
  stxdw [r10-0x348], r2
  ldxdw r2, [r10-0x340]
  ldxb r0, [r2+0x20]
  ldxdw r2, [r9+0x128]
  stxdw [r10-0x338], r2
  ldxdw r3, [r2+0x58]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r3+0x18]
  stxdw [r10-0x240], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x248], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x250], r4
  ldxdw r3, [r3+0x0]
  stxdw [r10-0x258], r3
  ldxdw r2, [r10-0x368]
  stxdw [r9+0x8], r2
  ldxdw r2, [r10-0x360]
  stxdw [r9+0x0], r2
  lsh64 r5, 0x18
  and64 r7, 0xff
  lsh64 r7, 0x10
  or64 r5, r7
  and64 r8, 0xff
  lsh64 r8, 0x8
  or64 r5, r8
  ldxdw r3, [r10-0x258]
  stxdw [r9+0x10], r3
  ldxdw r3, [r10-0x250]
  stxdw [r9+0x18], r3
  ldxdw r3, [r10-0x248]
  stxdw [r9+0x20], r3
  ldxdw r3, [r10-0x240]
  stxdw [r9+0x28], r3
  ldxdw r2, [r10-0x370]
  or64 r5, r2
  stxw [r9+0x40], r5
  ldxdw r2, [r10-0x358]
  stxdw [r9+0x38], r2
  stdw [r9+0x30], 0x0
  ldxdw r2, [r10-0x350]
  ldxdw r3, [r2+0x0]
  stxdw [r9+0x44], r3
  ldxdw r3, [r2+0x8]
  stxdw [r9+0x4c], r3
  ldxdw r3, [r2+0x10]
  stxdw [r9+0x54], r3
  ldxdw r3, [r2+0x18]
  stxdw [r9+0x5c], r3
  ldxb r3, [r2+0x20]
  stxb [r9+0x64], r3
  stxb [r9+0x67], r1
  ldxdw r1, [r10-0x348]
  stxb [r9+0x66], r1
  stxb [r9+0x65], r0
  stxb [r10-0x25a], r1
  mov64 r1, r10
  add64 r1, -0x259
  stxdw [r10-0x270], r1
  mov64 r1, r10
  add64 r1, -0x25a
  stxdw [r10-0x280], r1
  lddw r1, str_1775
  stxdw [r10-0x290], r1
  stxb [r10-0x259], r0
  stdw [r10-0x268], 0x1
  stdw [r10-0x278], 0x1
  stdw [r10-0x288], 0xe
  ldxdw r1, [r10-0x338]
  ldxb r3, [r1+0x30]
  jle r3, 0x2, jmp_243e8
  add64 r3, -0x3
  mov64 r1, r10
  add64 r1, -0x2f0
  mov64 r2, r3
  call fn_99f0
  ldxdw r1, [r10-0x2f0]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_244b8
  ldxdw r7, [r10-0x2e8]
  ldxdw r2, [r9+0x140]
  mov64 r1, r10
  add64 r1, -0x240
  call fn_d5c0
  ldxdw r1, [r9+0x128]
  ldxdw r2, [r1+0x58]
  mov64 r8, r10
  add64 r8, -0x170
  mov64 r1, r8
  call fn_d5c0
  ldxdw r1, [r9+0x130]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x140
  call fn_d5c0
  ldxdw r2, [r9+0x68]
  mov64 r1, r10
  add64 r1, -0x110
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x28], r1
  stdw [r10-0x20], 0x3
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r8
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x180], r1
  stdw [r10-0x178], 0x1
  stdw [r10-0x248], 0x0
  stdw [r10-0x250], 0x8
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x310
  mov64 r2, r10
  add64 r2, -0x258
  mov64 r3, r7
  call fn_b7ae8
  ldxdw r8, [r10-0x310]
  jne r8, 0x2, jmp_244f0
  ldxdw r1, [r9+0x120]
  ldxb r2, [r1+0x173]
  jeq r2, 0xff, jmp_24790
  add64 r2, 0x1
  stxb [r1+0x173], r2
  mov64 r2, r9
  add64 r2, 0xb8
  mov64 r1, r10
  add64 r1, -0xe0
  call fn_d5c0
  ldxdw r1, [r10-0x340]
  ldxb r1, [r1+0x21]
  stxdw [r10-0x338], r1
  ldxdw r1, [r9+0x118]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x240], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x248], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x250], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x258], r1
  ldxdw r1, [r9+0x68]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x220], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x228], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x230], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x238], r1
  ldxdw r1, [r9+0x128]
  ldxdw r1, [r1+0x58]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x200], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x208], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x210], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x218], r1
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_a0958
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xb0]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x78], r1
  stxdw [r10-0x80], r1
  ldxdw r2, [r10-0xa0]
  add64 r1, r2
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r10
  add64 r2, -0x80
  call fn_0000
  ldxdw r7, [r10-0x90]
  ldxdw r8, [r10-0x88]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jgt r1, r2, jmp_24500
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_24508

jmp_24398:
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_24528

jmp_243b0:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_24540

jmp_243d0:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_243e8:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_1710
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1710
  call fn_9838
  lddw r1, str_1885
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x50
  stdw [r10-0x248], 0x34
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x178a
  mov64 r1, r10
  add64 r1, -0x2e0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r7, [r10-0x2d8]
  ldxdw r8, [r10-0x2e0]
  ja jmp_23bc0

jmp_244b8:
  mov64 r1, r10
  add64 r1, -0x300
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x2f8]
  ldxdw r8, [r10-0x300]
  ja jmp_23bc0

jmp_244f0:
  ldxdw r7, [r10-0x308]
  ja jmp_23bc0

jmp_24500:
  jne r4, 0x0, jmp_24398

jmp_24508:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_243b0

jmp_24528:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_243d0

jmp_24540:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0xe0]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x168], r1
  stdw [r10-0x160], 0x1
  stdw [r10-0x170], 0x1
  mov64 r9, r10
  add64 r9, -0x258
  mov64 r5, r10
  add64 r5, -0x170
  mov64 r1, r9
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, r8
  call fn_c96c0
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r2, r10
  add64 r2, -0xe0
  mov64 r1, r7
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x38], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0x18], r1
  lddw r1, str_17d4
  stxdw [r10-0x28], r1
  ldxdw r1, [r10-0x338]
  stxb [r10-0x1], r1
  stdw [r10-0x30], 0x2
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x11
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r7
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x50]
  jne r2, r1, jmp_247c8
  mov64 r8, 0x2
  ja jmp_24800

jmp_24740:
  mov64 r3, r10
  add64 r3, -0x98
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_24790:
  mov64 r1, r10
  add64 r1, -0x330
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x328]
  ldxdw r8, [r10-0x330]
  ja jmp_23bc0

jmp_247c8:
  mov64 r1, r10
  add64 r1, -0x320
  mov64 r2, r10
  add64 r2, -0x50
  call fn_be7f0
  ldxdw r7, [r10-0x318]
  ldxdw r8, [r10-0x320]

jmp_24800:
  mov64 r1, r10
  add64 r1, -0x170
  call fn_a258
  jne r8, 0x2, jmp_23bc0
  mov64 r8, 0x2
  ja jmp_23bc0

jmp_24830:
  mov64 r2, r1
  lddw r3, data_6338
  call fn_cc630

jmp_24850:
  mov64 r1, 0x4
  mov64 r2, 0x4
  lddw r3, data_6320
  call fn_cc630

fn_24878:
  mov64 r6, r1
  ldxdw r2, [r2+0x8]
  ldxb r1, [r2+0x67]
  jge r1, 0x5, jmp_24ac0
  jeq r1, 0x0, jmp_24918
  ldxdw r3, [r2+0xc8]
  ldxb r3, [r3+0x10f]
  mov64 r4, 0x40

jmp_248b8:
  mov64 r5, r2
  add64 r5, r4
  ldxb r5, [r5+0x0]
  mov64 r0, r3
  jeq r5, r0, jmp_24900
  mov64 r7, r4
  add64 r7, -0x3f
  add64 r4, 0x1
  jlt r7, r1, jmp_248b8

jmp_24900:
  jne r5, r0, jmp_24918
  mov64 r1, 0x2
  ja jmp_24aa8

jmp_24918:
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_24ae0
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_18b9
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x1772
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0xc
  stdw [r10-0xd8], 0x3e
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r2, [r10-0xf0]
  ldxdw r1, [r10-0xf8]

jmp_24aa8:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_24ac0:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_24ae0:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_24b30:
  mov64 r7, r3
  mov64 r8, r1
  mov64 r1, r7
  and64 r1, 0xff00
  jeq r1, 0x0, jmp_24c38
  ldxdw r6, [r2+0x8]
  ldxdw r4, [r6+0xb0]
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, 0xf
  mov64 r3, r6
  call fn_4d818
  ldxdw r1, [r10-0xf8]
  jne r1, 0x2, jmp_24dd0
  stxdw [r10-0x130], r8
  mov64 r8, r7
  and64 r8, 0xffffff
  mov64 r9, r8
  rsh64 r9, 0x10
  rsh64 r8, 0x8
  ldxdw r2, [r6+0xb0]
  mov64 r1, r7
  and64 r1, 0x1
  jeq r1, 0x0, jmp_24de0
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r3, r9
  mov64 r4, r8
  call fn_1d500
  ldxdw r1, [r10-0x118]
  jeq r1, 0x2, jmp_24e18
  ldxdw r2, [r10-0x110]
  ja jmp_24f30

jmp_24c38:
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_24fc8
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_18f7
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x1771
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0x1c
  stdw [r10-0xd8], 0x34
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r2, [r10-0x120]
  ldxdw r1, [r10-0x128]
  ja jmp_24f38

jmp_24dd0:
  ldxdw r2, [r10-0xf0]
  ja jmp_24f38

jmp_24de0:
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r3, r9
  mov64 r4, r8
  call fn_1c760
  ldxdw r1, [r10-0x108]
  jne r1, 0x2, jmp_24f28

jmp_24e18:
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r2, r1
  add64 r2, -0x100
  mov64 r3, 0x0
  mov64 r4, 0x1
  jle r2, r1, jmp_24f50
  jeq r4, 0x0, jmp_24f60

jmp_24e68:
  lddw r2, 0x300007f00
  jne r1, 0x0, jmp_24f80

jmp_24e80:
  lddw r1, 0x300000007
  jle r2, r1, jmp_24fa0

jmp_24e98:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r2
  and64 r7, 0x1
  stxb [r2+0xa], r7
  stxb [r2+0x9], r8
  stxb [r2+0x8], r9
  lddw r1, 0xe2e78a9e8dc720d
  stxdw [r2+0x0], r1
  stxdw [r10-0xe8], r2
  stdw [r10-0xe0], 0xb
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r2, 0x1
  call fn_c2660
  mov64 r1, 0x2
  ja jmp_24f30

jmp_24f28:
  ldxdw r2, [r10-0x100]

jmp_24f30:
  ldxdw r8, [r10-0x130]

jmp_24f38:
  stxdw [r8+0x8], r2
  stxdw [r8+0x0], r1
  exit

jmp_24f50:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_24e68

jmp_24f60:
  mov64 r3, r2
  lddw r2, 0x300007f00
  jeq r1, 0x0, jmp_24e80

jmp_24f80:
  mov64 r2, r3
  lddw r1, 0x300000007
  jgt r2, r1, jmp_24e98

jmp_24fa0:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6e10
  call fn_cb038

jmp_24fc8:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_25018:
  mov64 r9, r1
  ldxdw r8, [r2+0x8]
  ldxdw r1, [r3+0x1a]
  stxdw [r10-0x130], r1
  ldxdw r1, [r3+0x12]
  stxdw [r10-0x138], r1
  ldxdw r1, [r3+0xa]
  stxdw [r10-0x140], r1
  ldxdw r1, [r3+0x2]
  stxdw [r10-0x148], r1
  ldxb r7, [r3+0x1]
  jeq r7, 0x0, jmp_25288
  ldxdw r1, [r8+0x60]
  ldxdw r4, [r10-0x148]
  jne r1, r4, jmp_250e0
  ldxdw r1, [r8+0x68]
  ldxdw r4, [r10-0x140]
  jne r1, r4, jmp_250e0
  ldxdw r1, [r8+0x70]
  ldxdw r4, [r10-0x138]
  jne r1, r4, jmp_250e0
  mov64 r1, 0x0
  ldxdw r4, [r8+0x78]
  ldxdw r5, [r10-0x130]
  jeq r4, r5, jmp_250e8

jmp_250e0:
  mov64 r1, 0x1

jmp_250e8:
  jeq r1, 0x0, jmp_25420
  mov64 r1, r10
  add64 r1, -0x128
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x1
  stdw [r10-0x28], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x58], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x48], r1
  mov64 r2, r10
  add64 r2, -0x58
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_26278
  ldxdw r1, [r10-0x18]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0xe0], r1
  lddw r1, str_192b
  stxdw [r10-0x108], r1
  stw [r10-0x78], 0x1771
  stb [r10-0xc0], 0x2
  stw [r10-0xf8], 0x1f
  stdw [r10-0x100], 0x39
  stdw [r10-0x110], 0x0
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r2, r10
  add64 r2, -0x110
  call fn_be760
  ldxdw r7, [r10-0x150]
  ldxdw r6, [r10-0x158]
  ja jmp_255a0

jmp_25288:
  mov64 r1, r10
  add64 r1, -0x128
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x1
  stdw [r10-0x28], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x58], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x48], r1
  mov64 r2, r10
  add64 r2, -0x58
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_26278
  ldxdw r1, [r10-0x18]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0xe0], r1
  lddw r1, str_192b
  stxdw [r10-0x108], r1
  stw [r10-0x78], 0x1771
  stb [r10-0xc0], 0x2
  stw [r10-0xf8], 0x1d
  stdw [r10-0x100], 0x39
  stdw [r10-0x110], 0x0
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r2, r10
  add64 r2, -0x110
  call fn_be760
  ldxdw r7, [r10-0x1f0]
  ldxdw r6, [r10-0x1f8]
  ja jmp_255a0

jmp_25420:
  stxdw [r10-0x208], r2
  stxdw [r10-0x210], r3
  ldxb r1, [r3+0x0]
  stxdw [r10-0x200], r1
  ldxdw r4, [r8+0xf8]
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, 0xe
  mov64 r3, r8
  call fn_4d818
  ldxdw r6, [r10-0x168]
  jne r6, 0x2, jmp_25598
  stxdw [r10-0x218], r9
  mov64 r9, r8
  add64 r9, 0x48
  jne r7, 0x6, jmp_255b8
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r8
  call fn_15728
  ldxdw r6, [r10-0x198]
  jne r6, 0x2, jmp_25620
  ldxdw r1, [r10-0x200]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_25688
  ldxdw r1, [r8+0xf8]
  ldxb r1, [r1+0x175]
  jlt r1, 0x2, jmp_259c8
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r9
  mov64 r3, 0x6
  call fn_15418
  ldxdw r6, [r10-0x1d8]
  jne r6, 0x2, jmp_25b40
  ldxdw r1, [r8+0xf8]
  ldxb r5, [r1+0x175]
  mov64 r2, r5
  add64 r2, -0x1
  mov64 r3, 0x0
  mov64 r4, 0x1
  jgt r2, r5, jmp_25578
  mov64 r4, 0x0

jmp_25578:
  jne r4, 0x0, jmp_25588
  mov64 r3, r2

jmp_25588:
  stxb [r1+0x175], r3
  ja jmp_256f0

jmp_25598:
  ldxdw r7, [r10-0x160]

jmp_255a0:
  stxdw [r9+0x0], r6
  stxdw [r9+0x8], r7
  exit

jmp_255b8:
  ldxdw r1, [r10-0x200]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_25638
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r9
  mov64 r3, r7
  call fn_15418
  ldxdw r6, [r10-0x188]
  ldxdw r9, [r10-0x218]
  jeq r6, 0x2, jmp_256f0
  ldxdw r7, [r10-0x180]
  ja jmp_255a0

jmp_25620:
  ldxdw r7, [r10-0x190]
  ldxdw r9, [r10-0x218]
  ja jmp_255a0

jmp_25638:
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r9
  mov64 r3, r7
  call fn_14fc8
  ldxdw r6, [r10-0x178]
  ldxdw r9, [r10-0x218]
  jeq r6, 0x2, jmp_256f0
  ldxdw r7, [r10-0x170]
  ja jmp_255a0

jmp_25688:
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r9
  mov64 r3, 0x6
  call fn_14fc8
  ldxdw r6, [r10-0x1a8]
  jne r6, 0x2, jmp_25aa0
  ldxdw r1, [r8+0xf8]
  ldxb r2, [r1+0x175]
  ldxdw r9, [r10-0x218]
  jeq r2, 0xff, jmp_25b58
  add64 r2, 0x1
  stxb [r1+0x175], r2

jmp_256f0:
  ldxdw r4, [r8+0x98]
  ldxdw r1, [r4+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_25720
  mov64 r2, 0x0

jmp_25720:
  ldxdw r6, [r8+0x90]
  stxdw [r4+0x0], r1
  ldxdw r1, [r10-0x208]
  jeq r2, 0x1, jmp_262c8
  ldxdw r9, [r8+0xa0]
  ldxdw r2, [r9+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_25770
  mov64 r3, 0x0

jmp_25770:
  stxdw [r10-0x220], r4
  stxdw [r9+0x0], r2
  jeq r3, 0x1, jmp_262c8
  ldxb r1, [r1+0x20]
  stxdw [r10-0x228], r1
  ldxb r1, [r8+0xba]
  stxdw [r10-0x250], r1
  ldxb r1, [r8+0xb9]
  stxdw [r10-0x248], r1
  ldxb r1, [r8+0xb8]
  stxdw [r10-0x240], r1
  ldxdw r1, [r8+0xb0]
  stxdw [r10-0x238], r1
  ldxdw r1, [r8+0xa8]
  stxdw [r10-0x230], r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r4, r2
  add64 r4, -0x100
  mov64 r3, 0x0
  mov64 r5, 0x1
  jle r4, r2, jmp_25940
  ldxdw r1, [r10-0x210]
  jeq r5, 0x0, jmp_25958

jmp_25840:
  lddw r8, 0x300007f00
  jne r2, 0x0, jmp_25978

jmp_25858:
  stxdw [r10-0x208], r6
  lddw r2, 0x300000007
  jle r8, r2, jmp_259a0

jmp_25878:
  add64 r1, 0x2
  lddw r6, 0x300000000
  stxdw [r6+0x0], r8
  lddw r2, 0x22c8555a2f8bc9aa
  stxdw [r8+0x0], r2
  ldxdw r2, [r1+0x0]
  stxdw [r8+0x8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r8+0x10], r2
  ldxdw r2, [r1+0x10]
  stxdw [r8+0x18], r2
  ldxdw r1, [r1+0x18]
  stxdw [r8+0x20], r1
  ldxdw r1, [r10-0x200]
  stxb [r8+0x29], r1
  stxb [r8+0x28], r7
  mov64 r1, 0x0
  mov64 r7, 0x32
  jsge r7, 0x0, jmp_25ab8

jmp_25920:
  mov64 r2, 0x32
  lddw r3, data_6068
  call fn_cb038

jmp_25940:
  mov64 r5, 0x0
  ldxdw r1, [r10-0x210]
  jne r5, 0x0, jmp_25840

jmp_25958:
  mov64 r3, r4
  lddw r8, 0x300007f00
  jeq r2, 0x0, jmp_25858

jmp_25978:
  mov64 r8, r3
  stxdw [r10-0x208], r6
  lddw r2, 0x300000007
  jgt r8, r2, jmp_25878

jmp_259a0:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6e70
  call fn_cb038

jmp_259c8:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1674
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_1674
  call fn_9838
  lddw r1, str_192b
  stxdw [r10-0x108], r1
  stb [r10-0xc0], 0x2
  stw [r10-0xf8], 0x36
  stdw [r10-0x100], 0x39
  stdw [r10-0x110], 0x0
  stw [r10-0x78], 0x178e
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, r10
  add64 r2, -0x110
  call fn_be760
  ldxdw r7, [r10-0x1c0]
  ldxdw r6, [r10-0x1c8]
  ldxdw r9, [r10-0x218]
  ja jmp_255a0

jmp_25aa0:
  ldxdw r7, [r10-0x1a0]
  ldxdw r9, [r10-0x218]
  ja jmp_255a0

jmp_25ab8:
  call fn_b1c08
  ldxdw r1, [r6+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_25ae8
  mov64 r3, r1

jmp_25ae8:
  mov64 r2, r3
  sub64 r2, r7
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_25b90
  jeq r4, 0x0, jmp_25ba0

jmp_25b20:
  lddw r2, 0x300000007
  jgt r7, r2, jmp_25bc0
  ja jmp_25920

jmp_25b40:
  ldxdw r7, [r10-0x1d0]
  ldxdw r9, [r10-0x218]
  ja jmp_255a0

jmp_25b58:
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x1b0]
  ldxdw r6, [r10-0x1b8]
  ja jmp_255a0

jmp_25b90:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_25b20

jmp_25ba0:
  mov64 r7, r2
  lddw r2, 0x300000007
  jle r7, r2, jmp_25920

jmp_25bc0:
  stxdw [r6+0x0], r7
  lddw r1, 0x1d9acb512ea545e4
  stxdw [r7+0x0], r1
  ldxb r1, [r8+0x0]
  stxb [r7+0x8], r1
  ldxb r1, [r8+0x1]
  stxb [r7+0x9], r1
  ldxb r1, [r8+0x2]
  stxb [r7+0xa], r1
  ldxb r1, [r8+0x3]
  stxb [r7+0xb], r1
  ldxb r1, [r8+0x4]
  stxb [r7+0xc], r1
  ldxb r1, [r8+0x5]
  stxb [r7+0xd], r1
  ldxb r1, [r8+0x6]
  stxb [r7+0xe], r1
  ldxb r1, [r8+0x7]
  stxb [r7+0xf], r1
  ldxb r1, [r8+0x8]
  stxb [r7+0x10], r1
  ldxb r1, [r8+0x9]
  stxb [r7+0x11], r1
  ldxb r1, [r8+0xa]
  stxb [r7+0x12], r1
  ldxb r1, [r8+0xb]
  stxb [r7+0x13], r1
  ldxb r1, [r8+0xc]
  stxb [r7+0x14], r1
  ldxb r1, [r8+0xd]
  stxb [r7+0x15], r1
  ldxb r1, [r8+0xe]
  stxb [r7+0x16], r1
  ldxb r1, [r8+0xf]
  stxb [r7+0x17], r1
  ldxb r1, [r8+0x10]
  stxb [r7+0x18], r1
  ldxb r1, [r8+0x11]
  stxb [r7+0x19], r1
  ldxb r1, [r8+0x12]
  stxb [r7+0x1a], r1
  ldxb r1, [r8+0x13]
  stxb [r7+0x1b], r1
  ldxb r1, [r8+0x14]
  stxb [r7+0x1c], r1
  ldxb r1, [r8+0x15]
  stxb [r7+0x1d], r1
  ldxb r1, [r8+0x16]
  stxb [r7+0x1e], r1
  ldxb r1, [r8+0x17]
  stxb [r7+0x1f], r1
  ldxb r1, [r8+0x18]
  stxb [r7+0x20], r1
  ldxb r1, [r8+0x19]
  stxb [r7+0x21], r1
  ldxb r1, [r8+0x1a]
  stxb [r7+0x22], r1
  ldxb r1, [r8+0x1b]
  stxb [r7+0x23], r1
  ldxb r1, [r8+0x1c]
  stxb [r7+0x24], r1
  ldxb r1, [r8+0x1d]
  stxb [r7+0x25], r1
  ldxb r1, [r8+0x1e]
  stxb [r7+0x26], r1
  ldxb r1, [r8+0x1f]
  stxb [r7+0x27], r1
  ldxb r1, [r8+0x20]
  stxb [r7+0x28], r1
  ldxb r1, [r8+0x21]
  stxb [r7+0x29], r1
  ldxb r1, [r8+0x22]
  stxb [r7+0x2a], r1
  ldxb r1, [r8+0x23]
  stxb [r7+0x2b], r1
  ldxb r1, [r8+0x24]
  stxb [r7+0x2c], r1
  ldxb r1, [r8+0x25]
  stxb [r7+0x2d], r1
  ldxb r1, [r8+0x26]
  stxb [r7+0x2e], r1
  ldxb r1, [r8+0x27]
  stxb [r7+0x2f], r1
  ldxb r1, [r8+0x28]
  stxb [r7+0x30], r1
  ldxb r1, [r8+0x29]
  stxb [r7+0x31], r1
  call fn_b1c08
  ldxdw r2, [r6+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jle r1, r2, jmp_26140
  ldxdw r6, [r10-0x208]
  jeq r4, 0x0, jmp_26158

jmp_25ec8:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_26178

jmp_25ee0:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_26198

jmp_25ef8:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r6+0x0]
  ldxdw r3, [r6+0x8]
  ldxdw r4, [r6+0x10]
  ldxdw r5, [r6+0x18]
  stxdw [r1+0x18], r5
  stxdw [r1+0x10], r4
  stxdw [r1+0x8], r3
  stxdw [r1+0x0], r2
  sth [r1+0x20], 0x1
  stxdw [r10-0x50], r1
  stdw [r10-0x48], 0x1
  stdw [r10-0x58], 0x1
  mov64 r8, r10
  add64 r8, -0x110
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r1, r8
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, 0x32
  call fn_c96c0
  ldxdw r1, [r10-0x250]
  stxb [r10-0x2e], r1
  ldxdw r1, [r10-0x248]
  stxb [r10-0x2f], r1
  ldxdw r1, [r10-0x240]
  stxb [r10-0x30], r1
  ldxdw r1, [r10-0x238]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x230]
  stxdw [r10-0x40], r1
  stxdw [r10-0x48], r9
  ldxdw r1, [r10-0x220]
  stxdw [r10-0x50], r1
  stxdw [r10-0x58], r6
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x128], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0x18], r1
  lddw r1, str_17d4
  stxdw [r10-0x28], r1
  ldxdw r1, [r10-0x228]
  stxb [r10-0x1], r1
  stdw [r10-0x120], 0x2
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x11
  mov64 r1, r10
  add64 r1, -0x128
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r3, r10
  add64 r3, -0x58
  mov64 r5, r10
  mov64 r2, r8
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x70]
  jne r2, r1, jmp_261b0
  mov64 r6, 0x2
  ldxdw r9, [r10-0x218]
  ldxdw r2, [r10-0x220]
  ja jmp_261f8

jmp_26140:
  mov64 r4, 0x0
  ldxdw r6, [r10-0x208]
  jne r4, 0x0, jmp_25ec8

jmp_26158:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_25ee0

jmp_26178:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_25ef8

jmp_26198:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_261b0:
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r2, r10
  add64 r2, -0x70
  call fn_be7f0
  ldxdw r2, [r10-0x50]
  ldxdw r7, [r10-0x1e0]
  ldxdw r6, [r10-0x1e8]
  ldxdw r9, [r10-0x218]

jmp_261f8:
  ldxdw r1, [r2+0x0]
  add64 r1, -0x1
  stxdw [r2+0x0], r1
  jne r1, 0x0, jmp_26230
  mov64 r1, r10
  add64 r1, -0x50
  call fn_c25c0

jmp_26230:
  ldxdw r1, [r10-0x48]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_255a0
  mov64 r1, r10
  add64 r1, -0x48
  call fn_c2610
  ja jmp_255a0

jmp_26278:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_262c8:
  call abort

fn_262d0:
  mov64 r7, r1
  ldxdw r9, [r3+0x18]
  stxdw [r10-0x440], r7
  jeq r9, 0x0, jmp_26300
  ldxdw r6, [r3+0x20]
  jle r9, r6, jmp_264b0

jmp_26300:
  mov64 r1, r10
  add64 r1, -0x3b8
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x238], r1
  mov64 r1, r10
  add64 r1, -0x138
  stxdw [r10-0x240], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x230], r1
  mov64 r2, r10
  add64 r2, -0x240
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_276b0
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x3b0]
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x340], r1
  lddw r1, str_1964
  stxdw [r10-0x368], r1
  stw [r10-0x2d8], 0x17a8
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x20
  stdw [r10-0x360], 0x34
  stdw [r10-0x370], 0x0
  mov64 r1, r10
  add64 r1, -0x438
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x430]
  ldxdw r7, [r10-0x438]

jmp_26490:
  ldxdw r1, [r10-0x440]
  stxdw [r1+0x8], r8
  stxdw [r1+0x0], r7
  exit

jmp_264b0:
  mov64 r7, r3
  stxdw [r10-0x448], r2
  ldxdw r8, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x3c8
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, 0xa
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r2, [r10-0x3c0]
  jeq r2, 0x0, jmp_265d8
  mov64 r2, -0x1
  jeq r1, 0x0, jmp_265f0

jmp_26528:
  jge r6, r2, jmp_26600

jmp_26530:
  mov64 r1, r10
  add64 r1, -0x370
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0x368
  ldxdw r2, [r10-0x370]
  jne r2, 0x1, jmp_26798
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x230], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x238], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x240], r1
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r2, r10
  add64 r2, -0x240
  call fn_be7f0
  ldxdw r8, [r10-0x420]
  ldxdw r7, [r10-0x428]
  ja jmp_26490

jmp_265d8:
  mov64 r1, 0x0
  mov64 r2, -0x1
  jne r1, 0x0, jmp_26528

jmp_265f0:
  ldxdw r2, [r10-0x3c8]
  jlt r6, r2, jmp_26530

jmp_26600:
  mov64 r1, r10
  add64 r1, -0x3b8
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x238], r1
  mov64 r1, r10
  add64 r1, -0x138
  stxdw [r10-0x240], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x230], r1
  mov64 r2, r10
  add64 r2, -0x240
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_276b0
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x3b0]
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x340], r1
  lddw r1, str_1964
  stxdw [r10-0x368], r1
  stw [r10-0x2d8], 0x17a8
  stb [r10-0x320], 0x2
  stw [r10-0x358], 0x29
  stdw [r10-0x360], 0x34
  stdw [r10-0x370], 0x0
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, r10
  add64 r2, -0x370
  call fn_be760
  ldxdw r8, [r10-0x3d0]
  ldxdw r7, [r10-0x3d8]
  ja jmp_26490

jmp_26798:
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x3b8], r1
  stxdw [r10-0x3b0], r5
  stxdw [r10-0x3a8], r4
  stxdw [r10-0x3a0], r3
  stxdw [r10-0x220], r2
  stxdw [r10-0x398], r2
  ldxdw r5, [r8+0xb8]
  ldxdw r1, [r5+0x40]
  stxdw [r10-0x378], r1
  ldxdw r1, [r5+0x38]
  stxdw [r10-0x380], r1
  ldxdw r1, [r5+0x30]
  stxdw [r10-0x388], r1
  ldxdw r1, [r5+0x28]
  stxdw [r10-0x390], r1
  ldxh r4, [r7+0x28]
  ldxdw r3, [r7+0x10]
  ldxdw r2, [r7+0x8]
  add64 r5, 0x8
  mov64 r1, r10
  add64 r1, -0x370
  stxdw [r10-0x450], r4
  call fn_4fdc8
  mov64 r2, r8
  ldxdw r8, [r10-0x368]
  ldxdw r7, [r10-0x370]
  ldxb r3, [r10-0x328]
  jeq r3, 0x2, jmp_26490
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x468], r1
  stxdw [r10-0x458], r2
  mov64 r2, r10
  add64 r2, -0x360
  stxdw [r10-0x460], r3
  mov64 r3, 0x38
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd3
  stxdw [r10-0x470], r1
  mov64 r2, r10
  add64 r2, -0x327
  mov64 r3, 0x9b
  call fn_d23d0
  ldxb r1, [r10-0x28c]
  stxdw [r10-0x478], r1
  stxdw [r10-0x368], r8
  stxdw [r10-0x370], r7
  mov64 r1, r10
  add64 r1, -0x360
  ldxdw r2, [r10-0x468]
  mov64 r3, 0x38
  call fn_d23d0
  ldxdw r1, [r10-0x460]
  stxb [r10-0x328], r1
  mov64 r1, r10
  add64 r1, -0x327
  ldxdw r2, [r10-0x470]
  mov64 r3, 0x9b
  call fn_d23d0
  ldxdw r1, [r10-0x458]
  ldxdw r1, [r1+0xc0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x0]
  stxdw [r10-0x240], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x228], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x230], r2
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x370]
  ldxdw r2, [r10-0x240]
  jne r2, r1, jmp_26a60
  ldxdw r1, [r10-0x368]
  ldxdw r2, [r10-0x238]
  jne r2, r1, jmp_26a60
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r10-0x230]
  jne r2, r1, jmp_26a60
  mov64 r1, 0x0
  ldxdw r2, [r10-0x358]
  ldxdw r3, [r10-0x228]
  jeq r3, r2, jmp_26a68

jmp_26a60:
  mov64 r1, 0x1

jmp_26a68:
  jeq r1, 0x0, jmp_26c08
  mov64 r1, r10
  add64 r1, -0x1a0
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x1
  stdw [r10-0xf8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0xf8
  stxdw [r10-0x138], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x128], r1
  mov64 r2, r10
  add64 r2, -0x138
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_276b0
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x1f8], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x200], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x208], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0x210], r1
  lddw r1, str_1964
  stxdw [r10-0x238], r1
  stw [r10-0x1a8], 0x177f
  stb [r10-0x1f0], 0x2
  stw [r10-0x228], 0x32
  stdw [r10-0x230], 0x34
  stdw [r10-0x240], 0x0
  mov64 r1, r10
  add64 r1, -0x3e8
  mov64 r2, r10
  add64 r2, -0x240
  call fn_be760
  ldxdw r8, [r10-0x3e0]
  ldxdw r7, [r10-0x3e8]
  ja jmp_26490

jmp_26c08:
  ldxdw r1, [r10-0x458]
  ldxdw r2, [r1+0xb8]
  stxdw [r2+0x30], r8
  mov64 r8, r1
  stxdw [r2+0x28], r7
  mov64 r1, r2
  mov64 r7, r2
  add64 r1, 0x38
  mov64 r2, r10
  add64 r2, -0x38
  mov64 r3, 0x38
  call fn_d23d0
  ldxdw r1, [r10-0x460]
  stxb [r7+0x70], r1
  add64 r7, 0x71
  mov64 r2, r10
  add64 r2, -0xd3
  mov64 r1, r7
  mov64 r3, 0x9b
  call fn_d23d0
  ldxdw r1, [r8+0xb8]
  ldxdw r7, [r10-0x478]
  stxb [r1+0x110], r7
  ldxdw r1, [r8+0xb8]
  ldxdw r2, [r10-0x450]
  stxh [r1+0x10c], r2
  ldxdw r1, [r8+0xb8]
  ldxb r2, [r1+0x111]
  and64 r2, 0xfe
  stxb [r1+0x111], r2
  ldxdw r3, [r8+0xc0]
  ldxdw r2, [r8+0xb8]
  ldxdw r1, [r10-0x448]
  ldxdw r4, [r1+0x10]
  ldxdw r1, [r1+0x18]
  mov64 r5, r10
  add64 r5, -0x3b8
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x240
  mov64 r5, r10
  call fn_518e0
  ldxh r1, [r10-0x22c]
  jeq r1, 0x2, jmp_26f10
  ldxdw r7, [r10-0x240]
  ldxdw r8, [r10-0x238]
  jeq r1, 0x3, jmp_26490
  ldxw r4, [r10-0x230]
  lsh64 r4, 0x20
  arsh64 r4, 0x20
  add64 r4, 0x6
  mov64 r1, r4
  lsh64 r1, 0x20
  arsh64 r1, 0x20
  jeq r1, r4, jmp_26e08
  mov64 r1, r10
  add64 r1, -0x418
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x410]
  ldxdw r7, [r10-0x418]
  ja jmp_26490

jmp_26e08:
  mov64 r1, r10
  add64 r1, -0x240
  mov64 r2, r7
  mov64 r3, r8
  call fn_3d580
  ldxdw r8, [r10-0x230]
  ldxdw r7, [r10-0x238]
  ldxdw r1, [r10-0x240]
  jne r1, 0x0, jmp_26490
  mov64 r1, 0x1
  jge r7, r9, jmp_26e80
  jne r8, 0x0, jmp_26e90

jmp_26e68:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_26ea8
  ja jmp_275e0

jmp_26e80:
  mov64 r1, 0x0
  jeq r8, 0x0, jmp_26e68

jmp_26e90:
  mov64 r1, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_275e0

jmp_26ea8:
  mov64 r2, 0x1
  mov64 r1, 0x1
  jgt r7, r6, jmp_275a8
  jne r8, 0x0, jmp_275b8

jmp_26ec8:
  jne r8, 0x0, jmp_275c8

jmp_26ed0:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_275e0

jmp_26ee0:
  ldxdw r8, [r10-0x458]
  ldxdw r1, [r8+0xb8]
  ldxb r2, [r1+0x111]
  or64 r2, 0x1
  stxb [r1+0x111], r2
  ldxdw r7, [r10-0x478]

jmp_26f10:
  mov64 r2, r8
  add64 r2, 0x48
  mov64 r1, r10
  add64 r1, -0x288
  call fn_d5c0
  ldxdw r1, [r10-0x448]
  ldxb r6, [r1+0x20]
  ldxdw r1, [r8+0xa8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x188], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x190], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x198], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x1a0], r1
  ldxdw r2, [r8+0xb8]
  ldxdw r1, [r2+0x20]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r2+0x18]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r2+0x40]
  stxdw [r10-0x120], r1
  ldxdw r1, [r2+0x38]
  stxdw [r10-0x128], r1
  ldxdw r1, [r2+0x30]
  stxdw [r10-0x130], r1
  ldxdw r1, [r2+0x28]
  stxdw [r10-0x138], r1
  jge r7, 0x4, jmp_27700
  add64 r2, 0x28
  mov64 r1, r7
  mul64 r1, 0x4c
  mov64 r3, r2
  add64 r3, r1
  mov64 r8, r7
  mov64 r7, r10
  add64 r7, -0x240
  mov64 r1, r7
  call fn_04d8
  ldxdw r1, [r10-0x188]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x208], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x200], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x1f8], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x1f0], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0x1e8], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x1e0], r1
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x1d8], r1
  ldxdw r1, [r10-0x378]
  stxdw [r10-0x1d0], r1
  stxb [r10-0x1a6], r8
  ldxdw r1, [r10-0x450]
  stxh [r10-0x1a8], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x1b8], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x1c0], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x1c8], r1
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, r7
  call fn_a0fe0
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x158], r2
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0x258]
  stxdw [r10-0x170], r1
  ldxdw r1, [r10-0x250]
  stxdw [r10-0x178], r1
  stxdw [r10-0x180], r1
  ldxdw r2, [r10-0x248]
  add64 r1, r2
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0x180
  call fn_0000
  ldxdw r7, [r10-0x198]
  ldxdw r8, [r10-0x190]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jle r1, r2, jmp_274d8
  jeq r4, 0x0, jmp_274e8

jmp_272b0:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_27508

jmp_272c8:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_27528

jmp_272e0:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0x288]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x130], r1
  stdw [r10-0x128], 0x1
  stdw [r10-0x138], 0x1
  mov64 r9, r10
  add64 r9, -0x240
  mov64 r5, r10
  add64 r5, -0x138
  mov64 r1, r9
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, r8
  call fn_c96c0
  mov64 r7, r10
  add64 r7, -0x138
  mov64 r2, r10
  add64 r2, -0x288
  mov64 r1, r7
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xf8
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0xd4
  stxdw [r10-0xe8], r1
  lddw r1, str_17d4
  stxdw [r10-0xf8], r1
  stxb [r10-0xd4], r6
  stdw [r10-0x100], 0x2
  stdw [r10-0xe0], 0x1
  stdw [r10-0xf0], 0x11
  mov64 r1, r10
  add64 r1, -0x108
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r7
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x150]
  jne r2, r1, jmp_27540
  mov64 r7, 0x2
  ja jmp_27578

jmp_274d8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_272b0

jmp_274e8:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_272c8

jmp_27508:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_272e0

jmp_27528:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_27540:
  mov64 r1, r10
  add64 r1, -0x3f8
  mov64 r2, r10
  add64 r2, -0x150
  call fn_be7f0
  ldxdw r8, [r10-0x3f0]
  ldxdw r7, [r10-0x3f8]

jmp_27578:
  mov64 r1, r10
  add64 r1, -0x138
  call fn_a258
  jne r7, 0x2, jmp_26490
  mov64 r7, 0x2
  ja jmp_26490

jmp_275a8:
  mov64 r1, 0x0
  jeq r8, 0x0, jmp_26ec8

jmp_275b8:
  mov64 r2, 0x0
  jeq r8, 0x0, jmp_26ed0

jmp_275c8:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_26ee0

jmp_275e0:
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1668
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x208
  lddw r2, data_1668
  call fn_9838
  lddw r1, str_1964
  stxdw [r10-0x238], r1
  stb [r10-0x1f0], 0x2
  stw [r10-0x228], 0x4f
  stdw [r10-0x230], 0x34
  stdw [r10-0x240], 0x0
  stw [r10-0x1a8], 0x17b6
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x240
  call fn_be760
  ldxdw r8, [r10-0x400]
  ldxdw r7, [r10-0x408]
  ja jmp_26490

jmp_276b0:
  mov64 r3, r10
  add64 r3, -0x108
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_27700:
  mov64 r1, r7
  mov64 r2, 0x3
  lddw r3, data_6350
  call fn_cf460

fn_27728:
  mov64 r6, r1
  ldxdw r8, [r2+0x8]
  ldxdw r3, [r8+0x8]
  ldxdw r2, [r3+0x8]
  ldxdw r1, [r2+0x0]
  add64 r1, 0x1
  mov64 r5, 0x1
  jeq r1, 0x0, jmp_27770
  mov64 r5, 0x0

jmp_27770:
  ldxdw r4, [r3+0x0]
  stxdw [r2+0x0], r1
  jeq r5, 0x1, jmp_28fe0
  ldxdw r1, [r3+0x10]
  ldxdw r5, [r1+0x0]
  add64 r5, 0x1
  mov64 r0, 0x1
  jeq r5, 0x0, jmp_277b8
  mov64 r0, 0x0

jmp_277b8:
  stxdw [r1+0x0], r5
  jeq r0, 0x1, jmp_28fe0
  ldxdw r5, [r3+0x18]
  ldxdw r0, [r3+0x20]
  ldxb r7, [r3+0x28]
  ldxb r9, [r3+0x29]
  ldxb r3, [r3+0x2a]
  stxb [r10-0x33e], r3
  stxb [r10-0x33f], r9
  stxb [r10-0x340], r7
  stxdw [r10-0x348], r0
  stxdw [r10-0x358], r1
  stxdw [r10-0x360], r2
  stxdw [r10-0x368], r4
  stxdw [r10-0x350], r5
  ldxdw r2, [r5+0x0]
  lddw r3, 0x5f9ff80ea6de9204
  jne r2, r3, jmp_278b8
  ldxdw r2, [r5+0x8]
  lddw r3, 0x306871741f975c4a
  jne r2, r3, jmp_278b8
  ldxdw r2, [r5+0x10]
  lddw r3, -0x7ec0aad0512fff5d
  jne r2, r3, jmp_278b8
  mov64 r2, 0x0
  ldxdw r3, [r5+0x18]
  lddw r4, -0x4886a17a3ed6b36e
  jeq r3, r4, jmp_278c0

jmp_278b8:
  mov64 r2, 0x1

jmp_278c0:
  jeq r2, 0x0, jmp_27a60
  mov64 r1, r10
  add64 r1, -0x200
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x1d0], 0x0
  stdw [r10-0x1d8], 0x1
  stdw [r10-0x1e0], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x268], r1
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x270], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x260], r1
  mov64 r2, r10
  add64 r2, -0x270
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_28800
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x1e0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0x100], r1
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stw [r10-0x98], 0x1771
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x28
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  mov64 r1, r10
  add64 r1, -0x378
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x370]
  ldxdw r8, [r10-0x378]
  ja jmp_27e80

jmp_27a60:
  mov64 r9, r1
  add64 r9, 0x10
  ldxdw r2, [r1+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r2, r3, jmp_27c78
  mov64 r3, r2
  add64 r3, 0x1
  stxdw [r1+0x10], r3
  ldxdw r3, [r1+0x20]
  jle r3, 0x7, jmp_27cd8
  ldxdw r1, [r1+0x18]
  ldxdw r1, [r1+0x0]
  lddw r3, 0x8a0e08bfcf1b4ea
  jeq r1, r3, jmp_27f18
  mov64 r1, r10
  add64 r1, -0x200
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x1d0], 0x0
  stdw [r10-0x1d8], 0x1
  stdw [r10-0x1e0], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x268], r1
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x270], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x260], r1
  mov64 r2, r10
  add64 r2, -0x270
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_28800
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x1e0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0x100], r1
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stw [r10-0x98], 0x1771
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x2c
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  mov64 r1, r10
  add64 r1, -0x3a8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x3a0]
  ldxdw r8, [r10-0x3a8]
  ja jmp_27e68

jmp_27c78:
  stxdw [r10-0x120], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0x388
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be7f0
  ldxdw r7, [r10-0x380]
  ldxdw r8, [r10-0x388]
  ja jmp_27e80

jmp_27cd8:
  mov64 r1, r10
  add64 r1, -0x200
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x1d0], 0x0
  stdw [r10-0x1d8], 0x1
  stdw [r10-0x1e0], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x268], r1
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x270], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x260], r1
  mov64 r2, r10
  add64 r2, -0x270
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_28800
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x1e0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0x100], r1
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stw [r10-0x98], 0x1771
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x2b
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  mov64 r1, r10
  add64 r1, -0x398
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x390]
  ldxdw r8, [r10-0x398]

jmp_27e68:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1

jmp_27e78:
  stxdw [r9+0x0], r1

jmp_27e80:
  ldxdw r1, [r10-0x360]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_27ec0
  mov64 r1, r10
  add64 r1, -0x360
  call fn_c25c0

jmp_27ec0:
  ldxdw r1, [r10-0x358]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_27f00
  mov64 r1, r10
  add64 r1, -0x358
  call fn_c2610

jmp_27f00:
  stxdw [r6+0x8], r7
  stxdw [r6+0x0], r8
  exit

jmp_27f18:
  stxdw [r9+0x0], r2
  ldxdw r2, [r10-0x358]
  mov64 r9, r2
  add64 r9, 0x10
  ldxdw r1, [r2+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r1, r3, jmp_28098
  mov64 r3, r1
  add64 r3, 0x1
  stxdw [r2+0x10], r3
  ldxdw r3, [r2+0x20]
  jle r3, 0x4b, jmp_280f8
  ldxdw r2, [r2+0x18]
  ldxb r5, [r2+0x9]
  ldxb r0, [r2+0x8]
  ldxdw r4, [r2+0x22]
  stxdw [r10-0x300], r4
  ldxdw r4, [r2+0x1a]
  stxdw [r10-0x308], r4
  ldxdw r4, [r2+0x12]
  stxdw [r10-0x310], r4
  ldxdw r4, [r2+0xa]
  stxdw [r10-0x318], r4
  ldxdw r4, [r2+0x22]
  stxdw [r10-0x320], r4
  ldxdw r4, [r2+0x1a]
  stxdw [r10-0x328], r4
  ldxdw r4, [r2+0x12]
  stxdw [r10-0x330], r4
  ldxdw r4, [r2+0xa]
  stxdw [r10-0x338], r4
  ldxdw r4, [r2+0x2b]
  stxdw [r10-0x2f8], r4
  ldxdw r4, [r2+0x33]
  stxdw [r10-0x2f0], r4
  ldxdw r4, [r2+0x3b]
  stxdw [r10-0x2e8], r4
  ldxdw r4, [r2+0x43]
  stxdw [r10-0x2e0], r4
  ldxb r7, [r2+0x2a]
  jeq r7, 0x0, jmp_281c8
  jne r7, 0x1, jmp_28270
  stxdw [r10-0x488], r5
  mov64 r3, 0x4b
  mov64 r4, r2
  add64 r4, 0x2b
  ja jmp_281f8

jmp_28098:
  stxdw [r10-0x120], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0x3b8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be7f0
  ldxdw r7, [r10-0x3b0]
  ldxdw r8, [r10-0x3b8]
  ja jmp_27e80

jmp_280f8:
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xf8
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x36
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  stw [r10-0x98], 0x1771
  mov64 r1, r10
  add64 r1, -0x3c8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x3c0]
  ldxdw r8, [r10-0x3c8]
  ja jmp_27e68

jmp_281c8:
  jle r3, 0x6b, jmp_28560
  stxdw [r10-0x488], r5
  mov64 r3, 0x6b
  mov64 r7, 0x2
  mov64 r4, r2
  add64 r4, 0x4b

jmp_281f8:
  ldxdw r5, [r4+0x18]
  stxdw [r10-0x8], r5
  ldxdw r5, [r4+0x10]
  stxdw [r10-0x10], r5
  ldxdw r5, [r4+0x8]
  stxdw [r10-0x18], r5
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x20], r4
  add64 r2, r3
  ldxb r2, [r2+0x0]
  jeq r2, 0x0, jmp_282a8
  jne r2, 0x1, jmp_28630
  stxdw [r10-0x480], r0
  mov64 r2, 0x1
  ja jmp_282b8

jmp_28270:
  mov64 r1, r10
  add64 r1, -0x478
  mov64 r2, 0x38
  call fn_5a078
  ldxdw r7, [r10-0x470]
  ldxdw r8, [r10-0x478]
  ja jmp_27e68

jmp_282a8:
  stxdw [r10-0x480], r0
  mov64 r2, 0x0

jmp_282b8:
  stxdw [r10-0x490], r2
  stxdw [r9+0x0], r1
  mov64 r1, r10
  add64 r1, -0x270
  stxdw [r10-0x1d0], r1
  lddw r1, str_1770
  stxdw [r10-0x1e0], r1
  ldxdw r1, [r10-0x300]
  stxdw [r10-0x258], r1
  ldxdw r1, [r10-0x308]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0x310]
  stxdw [r10-0x268], r1
  ldxdw r1, [r10-0x318]
  stxdw [r10-0x270], r1
  stdw [r10-0x1c8], 0x20
  stdw [r10-0x1d8], 0x5
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0x1e0
  mov64 r3, 0x2
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x2c0], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x2c8], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x2d0], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x2d8], r1
  ldxb r1, [r10-0x110]
  ldxdw r2, [r10-0x368]
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x128], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x120], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x118], r3
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x130], r2
  ldxdw r3, [r10-0x2d8]
  jne r2, r3, jmp_28478
  ldxdw r2, [r10-0x2d0]
  ldxdw r3, [r10-0x128]
  jne r3, r2, jmp_28478
  ldxdw r2, [r10-0x2c8]
  ldxdw r3, [r10-0x120]
  jne r3, r2, jmp_28478
  mov64 r2, 0x0
  ldxdw r3, [r10-0x2c0]
  ldxdw r4, [r10-0x118]
  jeq r4, r3, jmp_28480

jmp_28478:
  mov64 r2, 0x1

jmp_28480:
  ldxdw r3, [r10-0x480]
  jeq r2, 0x0, jmp_28668
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xf8
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x67
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  stw [r10-0x98], 0x1771
  mov64 r1, r10
  add64 r1, -0x3e8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x3e0]
  ldxdw r8, [r10-0x3e8]
  ja jmp_27e80

jmp_28560:
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xf8
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x43
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  stw [r10-0x98], 0x1771
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x3d0]
  ldxdw r8, [r10-0x3d8]
  ja jmp_27e68

jmp_28630:
  mov64 r1, r10
  add64 r1, -0x468
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r7, [r10-0x460]
  ldxdw r8, [r10-0x468]
  ja jmp_27e68

jmp_28668:
  mov64 r2, r3
  jne r2, r1, jmp_28730
  mov64 r1, r10
  add64 r1, -0x368
  call fn_c4848
  jge r0, 0x6d, jmp_28850
  mov64 r1, r10
  add64 r1, -0x130
  call fn_c2af0
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x290], r1
  ldxdw r1, [r10-0x130]
  jne r1, 0x1, jmp_28920
  mov64 r1, r10
  add64 r1, -0x458
  mov64 r2, r10
  add64 r2, -0x2a0
  call fn_be7f0
  ldxdw r7, [r10-0x450]
  ldxdw r8, [r10-0x458]
  ja jmp_27e80

jmp_28730:
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xf8
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x68
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  stw [r10-0x98], 0x1771
  mov64 r1, r10
  add64 r1, -0x3f8
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x3f0]
  ldxdw r8, [r10-0x3f8]
  ja jmp_27e80

jmp_28800:
  mov64 r3, r10
  add64 r3, -0x220
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_28850:
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xf8
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1998
  stxdw [r10-0x128], r1
  stb [r10-0xe0], 0x2
  stw [r10-0x118], 0x70
  stdw [r10-0x120], 0x34
  stdw [r10-0x130], 0x0
  stw [r10-0x98], 0x1771
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be760
  ldxdw r7, [r10-0x400]
  ldxdw r8, [r10-0x408]
  ja jmp_27e80

jmp_28920:
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x2a8], r1
  ldxdw r1, [r10-0x298]
  stxdw [r10-0x2b0], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x2b8], r1
  mov64 r1, r10
  add64 r1, -0x2b8
  mov64 r2, 0x10a
  call fn_c2bb8
  mov64 r9, r0
  mov64 r1, r10
  add64 r1, -0x368
  call fn_c47d0
  jle r9, r0, jmp_28cc0
  ldxdw r1, [r8+0x0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x208], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x210], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x218], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x220], r1
  sub64 r9, r0
  ldxdw r1, [r10-0x368]
  ldxdw r2, [r1+0x0]
  stxdw [r10-0x200], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x1f8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x1f0], r2
  ldxdw r1, [r1+0x18]
  stxdw [r10-0x1e8], r1
  mov64 r1, r10
  add64 r1, -0x270
  mov64 r2, r10
  add64 r2, -0x220
  mov64 r3, r10
  add64 r3, -0x200
  mov64 r4, r9
  call fn_c9430
  ldxdw r2, [r8+0x0]
  mov64 r1, r10
  add64 r1, -0x1e0
  call fn_d5c0
  ldxdw r3, [r10-0x360]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_28ac8
  mov64 r2, 0x0

jmp_28ac8:
  ldxdw r4, [r10-0x368]
  stxdw [r10-0x4a0], r4
  stxdw [r10-0x498], r3
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_28fe0
  ldxdw r9, [r10-0x358]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_28b20
  mov64 r2, 0x0

jmp_28b20:
  stxdw [r9+0x0], r1
  jeq r2, 0x1, jmp_28fe0
  ldxdw r2, [r8+0x10]
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x4a8], r1
  ldxdw r1, [r10-0x348]
  stxdw [r10-0x4b0], r1
  ldxb r1, [r10-0x340]
  stxdw [r10-0x4b8], r1
  ldxb r1, [r10-0x33f]
  stxdw [r10-0x4c0], r1
  ldxb r1, [r10-0x33e]
  stxdw [r10-0x4c8], r1
  mov64 r1, r10
  add64 r1, -0xd0
  call fn_d5c0
  mov64 r8, r10
  add64 r8, -0x130
  mov64 r2, r10
  add64 r2, -0x1e0
  mov64 r1, r8
  mov64 r3, 0x30
  call fn_d23d0
  ldxdw r1, [r10-0x4c8]
  stxb [r10-0xd6], r1
  ldxdw r1, [r10-0x4c0]
  stxb [r10-0xd7], r1
  ldxdw r1, [r10-0x4b8]
  stxb [r10-0xd8], r1
  ldxdw r1, [r10-0x4b0]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x4a8]
  stxdw [r10-0xe8], r1
  stxdw [r10-0xf0], r9
  ldxdw r1, [r10-0x498]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x4a0]
  stxdw [r10-0x100], r1
  mov64 r1, r10
  add64 r1, -0x288
  mov64 r2, r10
  add64 r2, -0x270
  mov64 r3, r8
  mov64 r4, 0x3
  call fn_c2670
  ldxdw r1, [r10-0x288]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_29050
  mov64 r1, r10
  add64 r1, -0x130
  call fn_a2f0

jmp_28cc0:
  mov64 r1, r10
  add64 r1, -0x270
  mov64 r2, r10
  add64 r2, -0x368
  mov64 r3, 0x10a
  call fn_c4b20
  ldxdw r1, [r10-0x270]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_28fe8
  stdw [r10-0x170], 0x0
  stdw [r10-0x168], 0x0
  stdw [r10-0x160], 0x0
  stdw [r10-0x158], 0x0
  stdw [r10-0x150], 0x0
  stdw [r10-0x148], 0x0
  stdw [r10-0x140], 0x0
  stdw [r10-0x138], 0x0
  ldxdw r1, [r10-0x2e0]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x2e8]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x2f0]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0x2f8]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x8]
  stxdw [r10-0xf8], r1
  mov64 r8, r10
  add64 r8, -0x1b0
  mov64 r2, r10
  add64 r2, -0x130
  mov64 r1, r8
  mov64 r3, 0x40
  call fn_d23d0
  ldxdw r1, [r10-0x488]
  stxb [r10-0x29], r1
  ldxdw r1, [r10-0x480]
  stxb [r10-0x2a], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0x328]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x320]
  stxdw [r10-0x118], r1
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r8
  mov64 r3, 0x40
  call fn_d23d0
  stxb [r10-0xc9], r7
  stb [r10-0xc8], 0x0
  stb [r10-0xca], 0x0
  sth [r10-0xcc], 0x0
  stw [r10-0xd0], 0x0
  mov64 r1, r10
  add64 r1, -0xc4
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r2, r7
  mov64 r3, 0x40
  call fn_d23d0
  stdw [r10-0x84], 0x0
  stb [r10-0x7c], 0x0
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r7
  mov64 r3, 0x40
  call fn_d23d0
  ldxdw r1, [r10-0x490]
  stxb [r10-0x26], r1
  ldxdw r1, [r10-0x358]
  mov64 r9, r1
  add64 r9, 0x10
  stdw [r10-0x38], 0x0
  stb [r10-0x30], 0x0
  sth [r10-0x28], 0x101
  sth [r10-0x2c], 0x0
  ldxdw r2, [r1+0x10]
  jeq r2, 0x0, jmp_290d0
  stxdw [r10-0x260], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x270], r1
  mov64 r1, r10
  add64 r1, -0x438
  mov64 r2, r10
  add64 r2, -0x270
  call fn_be7f0
  ldxdw r7, [r10-0x430]
  ldxdw r8, [r10-0x438]
  ja jmp_27e80

jmp_28fe0:
  call abort

jmp_28fe8:
  ldxdw r2, [r10-0x260]
  stxdw [r10-0x120], r2
  ldxdw r2, [r10-0x268]
  stxdw [r10-0x128], r2
  stxdw [r10-0x130], r1
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be7f0
  ldxdw r7, [r10-0x420]
  ldxdw r8, [r10-0x428]
  ja jmp_27e80

jmp_29050:
  ldxdw r2, [r10-0x278]
  stxdw [r10-0x1d0], r2
  ldxdw r2, [r10-0x280]
  stxdw [r10-0x1d8], r2
  stxdw [r10-0x1e0], r1
  mov64 r1, r10
  add64 r1, -0x418
  mov64 r2, r10
  add64 r2, -0x1e0
  call fn_be7f0
  ldxdw r7, [r10-0x410]
  ldxdw r8, [r10-0x418]
  mov64 r1, r10
  add64 r1, -0x130
  call fn_a2f0
  ja jmp_27e80

jmp_290d0:
  stdw [r1+0x10], -0x1
  ldxdw r2, [r1+0x20]
  jlt r2, 0x8, jmp_291f8
  ldxdw r2, [r1+0x18]
  lddw r3, 0x8a0e08bfcf1b4ea
  stxdw [r2+0x0], r3
  ldxdw r2, [r1+0x20]
  jlt r2, 0x8, jmp_29218
  ldxdw r1, [r1+0x18]
  add64 r2, -0x8
  stxdw [r10-0x268], r2
  add64 r1, 0x8
  stxdw [r10-0x270], r1
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0x270
  call fn_55a50
  jeq r0, 0x0, jmp_291b8
  mov64 r1, r10
  add64 r1, -0x448
  mov64 r2, r0
  call fn_be898
  ldxdw r7, [r10-0x440]
  ldxdw r8, [r10-0x448]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  ja jmp_27e78

jmp_291b8:
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  stxdw [r9+0x0], r1
  mov64 r1, r10
  add64 r1, -0x368
  call fn_9d08
  mov64 r8, 0x2
  ja jmp_27f00

jmp_291f8:
  mov64 r1, 0x8
  lddw r3, data_6368
  call fn_cf460

jmp_29218:
  mov64 r1, 0x8
  lddw r3, data_6380
  call fn_cf458

fn_29238:
  mov64 r6, r1
  ldxdw r4, [r2+0x8]
  ldxb r1, [r4+0x67]
  jge r1, 0x5, jmp_2a398
  jeq r1, 0x0, jmp_29490
  mov64 r5, r4
  add64 r5, 0x40
  ldxdw r3, [r4+0x128]
  ldxb r3, [r3+0x10f]
  mov64 r0, 0x40

jmp_29288:
  mov64 r7, r4
  add64 r7, r0
  ldxb r7, [r7+0x0]
  mov64 r8, r3
  jeq r7, r8, jmp_292d0
  mov64 r9, r0
  add64 r9, -0x3f
  add64 r0, 0x1
  jlt r9, r1, jmp_29288

jmp_292d0:
  jne r7, r8, jmp_29490
  ldxdw r0, [r4+0x138]
  ldxb r0, [r0+0x74]
  jne r0, 0x2, jmp_29638
  jne r1, 0x1, jmp_297d0
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_16e0
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x118], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x108], r1
  mov64 r2, r10
  add64 r2, -0x118
  lddw r1, data_16e0
  call fn_5a268
  jne r0, 0x0, jmp_2a3b8
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_19f7
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17a2
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x2c
  stdw [r10-0xb0], 0x39
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r7, [r10-0x168]
  ldxdw r8, [r10-0x170]
  ja jmp_29620

jmp_29490:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x118], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x108], r1
  mov64 r2, r10
  add64 r2, -0x118
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_2a3b8
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_19f7
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x1772
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x20
  stdw [r10-0xb0], 0x39
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r7, [r10-0x178]
  ldxdw r8, [r10-0x180]

jmp_29620:
  stxdw [r6+0x0], r8
  stxdw [r6+0x8], r7
  exit

jmp_29638:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_16c4
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x118], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x108], r1
  mov64 r2, r10
  add64 r2, -0x118
  lddw r1, data_16c4
  call fn_5a268
  jne r0, 0x0, jmp_2a3b8
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_19f7
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17a1
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x27
  stdw [r10-0xb0], 0x39
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r7, [r10-0x138]
  ldxdw r8, [r10-0x140]
  ja jmp_29620

jmp_297d0:
  mov64 r0, 0x0

jmp_297d8:
  jeq r1, r0, jmp_29c70
  mov64 r7, r5
  add64 r7, r0
  add64 r0, 0x1
  ldxb r7, [r7+0x0]
  mov64 r8, r3
  jne r7, r8, jmp_297d8
  add64 r1, -0x1
  mov64 r3, r0
  add64 r3, -0x1
  jge r3, r1, jmp_29880

jmp_29830:
  mov64 r3, r0
  add64 r0, -0x1
  jge r0, 0x3, jmp_2a410
  mov64 r0, r4
  add64 r0, r3
  ldxb r7, [r0+0x40]
  stxb [r0+0x3f], r7
  mov64 r0, r3
  add64 r0, 0x1
  jlt r3, r1, jmp_29830

jmp_29880:
  add64 r5, r1
  stb [r5+0x0], 0xff
  ldxb r1, [r4+0x67]
  jeq r1, 0x0, jmp_2a438
  add64 r1, -0x1
  stxb [r4+0x67], r1
  ldxdw r8, [r4+0xc0]
  ldxdw r1, [r8+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_298e0
  mov64 r3, 0x0

jmp_298e0:
  ldxdw r9, [r4+0xb8]
  stxdw [r8+0x0], r1
  jeq r3, 0x1, jmp_2a408
  ldxdw r5, [r4+0xc8]
  ldxdw r1, [r5+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_29928
  mov64 r3, 0x0

jmp_29928:
  stxdw [r10-0x188], r5
  stxdw [r5+0x0], r1
  jeq r3, 0x1, jmp_2a408
  ldxb r1, [r2+0x20]
  stxdw [r10-0x1a0], r1
  ldxb r1, [r4+0xe2]
  stxdw [r10-0x1c8], r1
  ldxb r1, [r4+0xe1]
  stxdw [r10-0x1c0], r1
  ldxb r1, [r4+0xe0]
  stxdw [r10-0x1b8], r1
  ldxdw r1, [r4+0xd8]
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r4+0xd0]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r4+0x118]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xa8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xb0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xb8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r4+0x68]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x88], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x90], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x98], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r4+0x128]
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x78], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x70], r2
  ldxdw r2, [r1+0x20]
  stxdw [r10-0x68], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x80], r2
  ldxb r7, [r1+0x10f]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r2, 0x0
  mov64 r4, 0x1
  mov64 r3, r1
  add64 r3, -0x100
  jle r3, r1, jmp_29de8
  stxdw [r10-0x198], r9
  stxdw [r10-0x190], r8
  jeq r4, 0x0, jmp_29e08

jmp_29af0:
  lddw r9, 0x300007f00
  jne r1, 0x0, jmp_29e28

jmp_29b08:
  lddw r1, 0x300000007
  jle r9, r1, jmp_29e48

jmp_29b20:
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, r10
  add64 r2, -0xa0
  lddw r8, 0x300000000
  stxdw [r8+0x0], r9
  lddw r3, -0x61f10df97f3df318
  stxdw [r9+0x0], r3
  ldxdw r3, [r10-0xa8]
  stxdw [r9+0x20], r3
  ldxdw r3, [r10-0xb0]
  stxdw [r9+0x18], r3
  ldxdw r3, [r10-0xb8]
  stxdw [r9+0x10], r3
  ldxdw r3, [r10-0xc0]
  stxdw [r9+0x8], r3
  ldxdw r3, [r2+0x0]
  stxdw [r9+0x28], r3
  ldxdw r3, [r2+0x8]
  stxdw [r9+0x30], r3
  ldxdw r3, [r2+0x10]
  stxdw [r9+0x38], r3
  ldxdw r2, [r2+0x18]
  stxdw [r9+0x40], r2
  ldxdw r2, [r1+0x8]
  stxdw [r9+0x50], r2
  ldxdw r2, [r1+0x10]
  stxdw [r9+0x58], r2
  ldxdw r2, [r1+0x18]
  stxdw [r9+0x60], r2
  ldxdw r1, [r1+0x0]
  stxb [r9+0x68], r7
  stxdw [r9+0x48], r1
  mov64 r1, 0x0
  mov64 r7, 0x71
  jsge r7, 0x0, jmp_29e70

jmp_29c50:
  mov64 r2, 0x71
  lddw r3, data_6068
  call fn_cb038

jmp_29c70:
  stw [r10-0xc4], 0x2
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r7, r10
  add64 r7, -0xc4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x110], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x118], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x108], r1
  mov64 r2, r10
  add64 r2, -0x118
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_2a3b8
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  stw [r10-0x28], 0x1772
  stb [r10-0x70], 0x2
  stdw [r10-0xc0], 0x2
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r7, [r10-0x158]
  ldxdw r8, [r10-0x160]
  ja jmp_29620

jmp_29de8:
  mov64 r4, 0x0
  stxdw [r10-0x198], r9
  stxdw [r10-0x190], r8
  jne r4, 0x0, jmp_29af0

jmp_29e08:
  mov64 r2, r3
  lddw r9, 0x300007f00
  jeq r1, 0x0, jmp_29b08

jmp_29e28:
  mov64 r9, r2
  lddw r1, 0x300000007
  jgt r9, r1, jmp_29b20

jmp_29e48:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6dc8
  call fn_cb038

jmp_29e70:
  call fn_b1c08
  ldxdw r1, [r8+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_29ea0
  mov64 r3, r1

jmp_29ea0:
  mov64 r2, r3
  sub64 r2, r7
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_29ef8
  jeq r4, 0x0, jmp_29f08

jmp_29ed8:
  lddw r2, 0x300000007
  jgt r7, r2, jmp_29f28
  ja jmp_29c50

jmp_29ef8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_29ed8

jmp_29f08:
  mov64 r7, r2
  lddw r2, 0x300000007
  jle r7, r2, jmp_29c50

jmp_29f28:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r7
  lddw r1, 0x1d9acb512ea545e4
  stxdw [r7+0x0], r1
  mov64 r1, 0x0

jmp_29f60:
  mov64 r2, r7
  add64 r2, r1
  mov64 r3, r9
  add64 r3, r1
  ldxb r3, [r3+0x0]
  stxb [r2+0x8], r3
  add64 r1, 0x1
  jne r1, 0x69, jmp_29f60
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r1, r2
  add64 r1, -0x22
  mov64 r3, 0x0
  mov64 r4, 0x1
  jle r1, r2, jmp_2a268
  ldxdw r9, [r10-0x190]
  jeq r4, 0x0, jmp_2a280

jmp_29ff8:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_2a2a0

jmp_2a010:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_2a2c0

jmp_2a028:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r8, [r10-0x198]
  ldxdw r2, [r8+0x0]
  ldxdw r3, [r8+0x8]
  ldxdw r4, [r8+0x10]
  ldxdw r5, [r8+0x18]
  stxdw [r1+0x18], r5
  stxdw [r1+0x10], r4
  stxdw [r1+0x8], r3
  stxdw [r1+0x0], r2
  sth [r1+0x20], 0x1
  stxdw [r10-0x110], r1
  stdw [r10-0x108], 0x1
  stdw [r10-0x118], 0x1
  mov64 r1, r10
  add64 r1, -0xc0
  stxdw [r10-0x1d0], r1
  mov64 r5, r10
  add64 r5, -0x118
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, 0x71
  call fn_c96c0
  ldxdw r1, [r10-0x1c8]
  stxb [r10-0xee], r1
  ldxdw r1, [r10-0x1c0]
  stxb [r10-0xef], r1
  ldxdw r1, [r10-0x1b8]
  stxb [r10-0xf0], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x1a8]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x188]
  stxdw [r10-0x108], r1
  stxdw [r10-0x110], r9
  stxdw [r10-0x118], r8
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0xc4
  stxdw [r10-0xd8], r1
  lddw r1, str_17d4
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x1a0]
  stxb [r10-0xc4], r1
  stdw [r10-0x18], 0x2
  stdw [r10-0xd0], 0x1
  stdw [r10-0xe0], 0x11
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r3, r10
  add64 r3, -0x118
  mov64 r5, r10
  ldxdw r2, [r10-0x1d0]
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x130]
  jne r2, r1, jmp_2a2d8
  mov64 r8, 0x2
  ja jmp_2a318

jmp_2a268:
  mov64 r4, 0x0
  ldxdw r9, [r10-0x190]
  jne r4, 0x0, jmp_29ff8

jmp_2a280:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_2a010

jmp_2a2a0:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_2a028

jmp_2a2c0:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_2a2d8:
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0x130
  call fn_be7f0
  ldxdw r9, [r10-0x110]
  ldxdw r7, [r10-0x148]
  ldxdw r8, [r10-0x150]

jmp_2a318:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1
  jne r1, 0x0, jmp_2a350
  mov64 r1, r10
  add64 r1, -0x110
  call fn_c25c0

jmp_2a350:
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_29620
  mov64 r1, r10
  add64 r1, -0x108
  call fn_c2610
  ja jmp_29620

jmp_2a398:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_2a3b8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_2a408:
  call abort

jmp_2a410:
  mov64 r1, r3
  mov64 r2, 0x4
  lddw r3, data_63b0
  call fn_cc630

jmp_2a438:
  lddw r1, data_6398
  call fn_d0810

fn_2a450:
  mov64 r9, r2
  mov64 r6, r1
  ldxdw r7, [r9+0x8]
  ldxdw r1, [r7+0x70]
  mov64 r5, 0x0
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_2a4a0
  mov64 r5, r7
  add64 r5, 0x70

jmp_2a4a0:
  ldxdw r1, [r3+0x8]
  stxdw [r10-0x230], r1
  ldxdw r8, [r3+0x0]
  ldxdw r4, [r7+0x150]
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, 0x0
  mov64 r3, r5
  call fn_4d818
  ldxdw r1, [r10-0x178]
  jne r1, 0x2, jmp_2a668
  jeq r8, 0x0, jmp_2a810
  ldxb r1, [r7+0x67]
  jge r1, 0x5, jmp_2afb0
  jeq r1, 0x0, jmp_2a678
  ldxdw r2, [r7+0x170]
  stxdw [r10-0x248], r2
  mov64 r2, r7
  add64 r2, 0x188
  stxdw [r10-0x238], r2
  mov64 r2, r7
  add64 r2, 0x148
  stxdw [r10-0x240], r2
  ldxdw r2, [r7+0x168]
  ldxb r2, [r2+0x10f]
  mov64 r3, 0x40

jmp_2a570:
  mov64 r4, r7
  add64 r4, r3
  ldxb r4, [r4+0x0]
  mov64 r5, r2
  jeq r4, r5, jmp_2a5b8
  mov64 r0, r3
  add64 r0, -0x3f
  add64 r3, 0x1
  jlt r0, r1, jmp_2a570

jmp_2a5b8:
  jne r4, r5, jmp_2a678
  mov64 r1, r10
  add64 r1, -0xe0
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0xd8
  ldxdw r2, [r10-0xe0]
  jne r2, 0x1, jmp_2a9b8
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x130], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x138], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x140], r1
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r2, r10
  add64 r2, -0x140
  call fn_be7f0
  ldxdw r9, [r10-0x200]
  ldxdw r1, [r10-0x208]
  ja jmp_2a9a0

jmp_2a668:
  ldxdw r9, [r10-0x170]
  ja jmp_2a9a0

jmp_2a678:
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x158], 0x0
  stdw [r10-0x160], 0x1
  stdw [r10-0x168], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0x168
  stxdw [r10-0x140], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x130], r1
  mov64 r2, r10
  add64 r2, -0x140
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_2af60
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xb0], r1
  lddw r1, str_1a30
  stxdw [r10-0xd8], r1
  stw [r10-0x48], 0x1772
  stb [r10-0x90], 0x2
  stw [r10-0xc8], 0x2b
  stdw [r10-0xd0], 0x2d
  stdw [r10-0xe0], 0x0
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, r10
  add64 r2, -0xe0
  call fn_be760
  ldxdw r9, [r10-0x210]
  ldxdw r1, [r10-0x218]
  ja jmp_2a9a0

jmp_2a810:
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x158], 0x0
  stdw [r10-0x160], 0x1
  stdw [r10-0x168], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0x168
  stxdw [r10-0x140], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x130], r1
  mov64 r2, r10
  add64 r2, -0x140
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_2af60
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xb0], r1
  lddw r1, str_1a30
  stxdw [r10-0xd8], r1
  stw [r10-0x48], 0x1771
  stb [r10-0x90], 0x2
  stw [r10-0xc8], 0x28
  stdw [r10-0xd0], 0x2d
  stdw [r10-0xe0], 0x0
  mov64 r1, r10
  add64 r1, -0x228
  mov64 r2, r10
  add64 r2, -0xe0
  call fn_be760
  ldxdw r9, [r10-0x220]
  ldxdw r1, [r10-0x228]

jmp_2a9a0:
  stxdw [r6+0x8], r9
  stxdw [r6+0x0], r1
  exit

jmp_2a9b8:
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x168], r1
  stxdw [r10-0x160], r5
  stxdw [r10-0x158], r4
  stxdw [r10-0x150], r3
  stxdw [r10-0x120], r2
  stxdw [r10-0x148], r2
  ldxdw r4, [r9+0x18]
  ldxdw r3, [r9+0x10]
  ldxdw r1, [r7+0x168]
  ldxdw r2, [r1+0x20]
  stxdw [r10-0x127], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x12f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x137], r2
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x13f], r1
  stb [r10-0x140], 0x1
  mov64 r1, r10
  add64 r1, -0x140
  stxdw [r10-0xff0], r1
  mov64 r1, r10
  add64 r1, -0x168
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r7
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r5, r10
  mov64 r2, r7
  call fn_160e0
  ldxdw r9, [r10-0xd8]
  ldxdw r1, [r10-0xe0]
  ldxh r2, [r10-0xac]
  jeq r2, 0x3, jmp_2a9a0
  ldxdw r3, [r10-0xc8]
  stxdw [r10-0x18], r3
  ldxdw r3, [r10-0xd0]
  stxdw [r10-0x20], r3
  ldxdw r3, [r10-0xbc]
  stxdw [r10-0x10], r3
  ldxdw r3, [r10-0xb4]
  stxdw [r10-0x8], r3
  stxdw [r10-0x28], r9
  stxdw [r10-0x30], r1
  jne r2, 0x2, jmp_2ab80
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r2, 0x2
  call fn_5a078
  ldxdw r9, [r10-0x1f0]
  ldxdw r1, [r10-0x1f8]
  ja jmp_2a9a0

jmp_2ab80:
  ldxh r1, [r10-0xaa]
  ldxw r3, [r10-0xc0]
  ldxdw r4, [r10-0x8]
  stxdw [r10-0x10c], r4
  ldxdw r4, [r10-0x10]
  stxdw [r10-0x114], r4
  stxh [r10-0x102], r1
  stxh [r10-0x104], r2
  stxw [r10-0x118], r3
  ldxdw r1, [r7+0x178]
  ldxdw r2, [r7+0x180]
  ldxdw r3, [r10-0x238]
  stxdw [r10-0xff0], r3
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r5, r10
  ldxdw r3, [r10-0x240]
  mov64 r4, r8
  call fn_15a70
  ldxdw r1, [r10-0x188]
  jne r1, 0x2, jmp_2acc0
  ldxdw r1, [r10-0x248]
  ldxb r4, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r10
  add64 r2, -0x118
  mov64 r3, r8
  call fn_3c7b8
  ldxw r1, [r10-0xe0]
  jne r1, 0x1, jmp_2acd0
  ldxw r2, [r10-0xdc]
  mov64 r1, r10
  add64 r1, -0x1e8
  call fn_5a078
  ldxdw r9, [r10-0x1e0]
  ldxdw r1, [r10-0x1e8]
  ja jmp_2a9a0

jmp_2acc0:
  ldxdw r9, [r10-0x180]
  ja jmp_2a9a0

jmp_2acd0:
  ldxdw r9, [r10-0xd0]
  ldxdw r2, [r10-0xd8]
  mov64 r1, r10
  add64 r1, -0xe0
  stxdw [r10-0x240], r2
  mov64 r3, r9
  call fn_b3090
  ldxdw r1, [r10-0xe0]
  jeq r1, 0x0, jmp_2ae98
  stxdw [r10-0x248], r9
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x100], r1
  ldxdw r3, [r7+0x158]
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r4, r10
  add64 r4, -0x30
  mov64 r5, r10
  add64 r5, -0x100
  call fn_19810
  ldxdw r9, [r10-0xd8]
  ldxdw r1, [r10-0xe0]
  jne r1, 0x2, jmp_2a9a0
  ldxdw r1, [r10-0x230]
  jle r1, r9, jmp_2aed0
  mov64 r1, r10
  add64 r1, -0xc0
  lddw r2, data_1704
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa8
  lddw r2, data_1704
  call fn_9838
  lddw r1, str_1a30
  stxdw [r10-0xd8], r1
  stb [r10-0x90], 0x2
  stw [r10-0xc8], 0x51
  stdw [r10-0xd0], 0x2d
  stdw [r10-0xe0], 0x0
  stw [r10-0x48], 0x1793
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r10
  add64 r2, -0xe0
  call fn_be760
  ldxdw r9, [r10-0x1d0]
  ldxdw r1, [r10-0x1d8]
  ja jmp_2a9a0

jmp_2ae98:
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r9, [r10-0x190]
  ldxdw r1, [r10-0x198]
  ja jmp_2a9a0

jmp_2aed0:
  ldxdw r1, [r7+0x158]
  ldxdw r2, [r7+0x0]
  jne r2, 0x1, jmp_2b0b8
  ldxdw r2, [r1+0x28]
  mov64 r4, r2
  add64 r4, r9
  mov64 r3, 0x1
  jlt r4, r2, jmp_2af18
  mov64 r3, 0x0

jmp_2af18:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_2afd0
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r9, [r10-0x1c0]
  ldxdw r1, [r10-0x1c8]
  ja jmp_2a9a0

jmp_2af60:
  mov64 r3, r10
  add64 r3, -0x40
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_2afb0:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_2afd0:
  add64 r2, r9
  ldxdw r3, [r7+0x8]
  jle r2, r3, jmp_2b0b8
  mov64 r1, r10
  add64 r1, -0xc0
  lddw r2, data_1654
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa8
  lddw r2, data_1654
  call fn_9838
  lddw r1, str_1a30
  stxdw [r10-0xd8], r1
  stb [r10-0x90], 0x2
  stw [r10-0xc8], 0x57
  stdw [r10-0xd0], 0x2d
  stdw [r10-0xe0], 0x0
  stw [r10-0x48], 0x1774
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r10
  add64 r2, -0xe0
  call fn_be760
  ldxdw r9, [r10-0x1b0]
  ldxdw r1, [r10-0x1b8]
  ja jmp_2a9a0

jmp_2b0b8:
  ldxdw r2, [r7+0x160]
  ldxdw r3, [r10-0x238]
  stxdw [r10-0xff0], r3
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r5, r10
  mov64 r2, r7
  mov64 r3, r9
  mov64 r4, r7
  call fn_1aaa8
  ldxdw r1, [r10-0x1a8]
  jne r1, 0x2, jmp_2b288
  ldxdw r1, [r7+0x148]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xc8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xd0], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xd8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xe0], r1
  ldxb r1, [r7+0x66]
  ldxdw r2, [r7+0x170]
  ldxdw r2, [r2+0x58]
  ldxdw r2, [r2+0x0]
  ldxdw r3, [r2+0x8]
  stxdw [r10-0xb8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0xb0], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0xa8], r3
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x88], r9
  stxdw [r10-0x90], r8
  ldxdw r3, [r10-0x240]
  stxdw [r10-0xa0], r3
  ldxdw r3, [r10-0x248]
  stxdw [r10-0x98], r3
  stxb [r10-0x80], r1
  stxdw [r10-0xc0], r2
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xe0
  call fn_9fe28
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x40], r1
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r2, 0x1
  call fn_c2660
  mov64 r1, 0x2
  ja jmp_2a9a0

jmp_2b288:
  ldxdw r9, [r10-0x1a0]
  ja jmp_2a9a0

fn_2b298:
  ldxdw r4, [r3+0x0]
  stxdw [r10-0x1f8], r1
  jeq r4, 0x0, jmp_2b4e0
  stxdw [r10-0x208], r4
  stxdw [r10-0x200], r2
  ldxdw r9, [r2+0x8]
  ldxdw r1, [r9+0x0]
  mov64 r5, 0x0
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_2b2f8
  mov64 r5, r9

jmp_2b2f8:
  ldxb r7, [r3+0x9]
  ldxb r8, [r3+0x8]
  ldxdw r4, [r9+0xb0]
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, 0x1
  mov64 r3, r5
  call fn_4d818
  ldxdw r6, [r10-0x180]
  jne r6, 0x2, jmp_2b678
  ldxdw r1, [r10-0x200]
  ldxb r1, [r1+0x20]
  ldxdw r2, [r9+0xd0]
  stxb [r2+0xa4], r1
  ldxdw r1, [r9+0xb8]
  ldxdw r1, [r1+0x30]
  ldxdw r2, [r9+0xd0]
  stxdw [r2+0x88], r1
  ldxdw r1, [r9+0xd0]
  stxdw [r10-0x220], r8
  stxb [r1+0xa5], r8
  ldxdw r1, [r9+0xa8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r1+0x8]
  ldxdw r4, [r1+0x10]
  ldxdw r1, [r1+0x18]
  ldxdw r5, [r9+0xd0]
  stxdw [r5+0x60], r1
  stxdw [r5+0x58], r4
  stxdw [r5+0x50], r3
  stxdw [r5+0x48], r2
  ldxdw r1, [r9+0xd0]
  ldxdw r2, [r10-0x208]
  stxdw [r1+0x98], r2
  ldxdw r1, [r9+0xd0]
  stxb [r1+0xa7], r7
  ldxdw r6, [r9+0xd0]
  ldxdw r1, [r9+0xb8]
  ldxdw r7, [r1+0x38]
  mov64 r1, r10
  add64 r1, -0x158
  call fn_c2a08
  ldxdw r1, [r10-0x158]
  jne r1, 0x1, jmp_2b688
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ldxdw r3, [r10-0x140]
  stxdw [r10-0x148], r3
  stxdw [r10-0x150], r2
  stxdw [r10-0x158], r1
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0x158
  call fn_be7f0
  ldxdw r7, [r10-0x198]
  ldxdw r6, [r10-0x1a0]
  ldxdw r8, [r10-0x200]
  jeq r6, 0x2, jmp_2b6e0
  ja jmp_2c060

jmp_2b4e0:
  mov64 r1, r10
  add64 r1, -0x170
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x1
  stdw [r10-0x28], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x58], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x48], r1
  mov64 r2, r10
  add64 r2, -0x58
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_2c8d8
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0x128], r1
  lddw r1, str_1a5d
  stxdw [r10-0x150], r1
  stw [r10-0xc0], 0x1771
  stb [r10-0x108], 0x2
  stw [r10-0x140], 0x29
  stdw [r10-0x148], 0x36
  stdw [r10-0x158], 0x0
  mov64 r1, r10
  add64 r1, -0x1f0
  mov64 r2, r10
  add64 r2, -0x158
  call fn_be760
  ldxdw r7, [r10-0x1e8]
  ldxdw r6, [r10-0x1f0]
  ja jmp_2c060

jmp_2b678:
  ldxdw r7, [r10-0x178]
  ja jmp_2c060

jmp_2b688:
  ldxdw r1, [r10-0x130]
  mov64 r3, r1
  add64 r3, r7
  mov64 r2, 0x1
  jlt r3, r1, jmp_2b6b8
  mov64 r2, 0x0

jmp_2b6b8:
  and64 r2, 0x1
  ldxdw r8, [r10-0x200]
  jne r2, 0x0, jmp_2c928
  add64 r1, r7
  stxdw [r6+0x90], r1

jmp_2b6e0:
  ldxdw r4, [r8+0x10]
  ldxdw r1, [r8+0x18]
  ldxdw r3, [r9+0xb8]
  ldxdw r2, [r9+0xd0]
  ldxdw r5, [r9+0xc0]
  ldxdw r5, [r5+0x28]
  stxdw [r10-0xff8], r5
  stxdw [r10-0x1000], r1
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r5, r10
  call fn_13550
  ldxdw r6, [r10-0x1b0]
  jne r6, 0x2, jmp_2c010
  ldxdw r5, [r9+0xe0]
  ldxdw r0, [r5+0x8]
  ldxdw r1, [r0+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2b790
  mov64 r2, 0x0

jmp_2b790:
  ldxdw r3, [r5+0x0]
  stxdw [r0+0x0], r1
  jeq r2, 0x1, jmp_2c8d0
  ldxdw r7, [r5+0x10]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2b7d8
  mov64 r2, 0x0

jmp_2b7d8:
  stxdw [r7+0x0], r1
  jeq r2, 0x1, jmp_2c8d0
  stxdw [r10-0x228], r3
  ldxdw r1, [r9+0xc8]
  ldxdw r2, [r1+0x0]
  ldxdw r6, [r2+0x8]
  ldxdw r1, [r6+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_2b830
  mov64 r3, 0x0

jmp_2b830:
  ldxb r4, [r5+0x2a]
  stxdw [r10-0x248], r4
  ldxb r4, [r5+0x29]
  stxdw [r10-0x240], r4
  ldxb r4, [r5+0x28]
  stxdw [r10-0x238], r4
  ldxdw r4, [r5+0x20]
  stxdw [r10-0x230], r4
  ldxdw r4, [r5+0x18]
  ldxdw r5, [r2+0x0]
  stxdw [r6+0x0], r1
  jeq r3, 0x1, jmp_2c8d0
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x210], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_2b8c8
  mov64 r3, 0x0

jmp_2b8c8:
  stxdw [r10-0x258], r5
  stxdw [r10-0x250], r6
  ldxdw r6, [r10-0x210]
  stxdw [r6+0x0], r1
  jeq r3, 0x1, jmp_2c8d0
  mov64 r5, r0
  ldxdw r1, [r9+0xd8]
  ldxdw r6, [r1+0x0]
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x218], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_2b940
  mov64 r3, 0x0

jmp_2b940:
  ldxb r0, [r2+0x2a]
  stxdw [r10-0x280], r0
  ldxb r0, [r2+0x29]
  stxdw [r10-0x278], r0
  ldxb r0, [r2+0x28]
  stxdw [r10-0x270], r0
  ldxdw r0, [r2+0x20]
  stxdw [r10-0x268], r0
  ldxdw r2, [r2+0x18]
  stxdw [r10-0x260], r2
  ldxdw r2, [r6+0x0]
  stxdw [r10-0x288], r2
  ldxdw r2, [r10-0x218]
  stxdw [r2+0x0], r1
  jeq r3, 0x1, jmp_2c8d0
  ldxdw r2, [r6+0x10]
  ldxdw r1, [r2+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  mov64 r0, r5
  jeq r1, 0x0, jmp_2b9f0
  mov64 r3, 0x0

jmp_2b9f0:
  stxdw [r10-0x298], r4
  stxdw [r10-0x290], r7
  stxdw [r2+0x0], r1
  jeq r3, 0x1, jmp_2c8d0
  ldxdw r7, [r9+0xa8]
  ldxdw r1, [r7+0x8]
  ldxdw r4, [r1+0x0]
  add64 r4, 0x1
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_2ba48
  mov64 r5, 0x0

jmp_2ba48:
  ldxb r3, [r6+0x2a]
  stxdw [r10-0x2b8], r3
  ldxb r3, [r6+0x29]
  stxdw [r10-0x2b0], r3
  ldxb r3, [r6+0x28]
  stxdw [r10-0x2a8], r3
  ldxdw r3, [r6+0x20]
  stxdw [r10-0x2a0], r3
  ldxdw r3, [r6+0x18]
  ldxdw r6, [r7+0x0]
  stxdw [r10-0x2c0], r6
  stxdw [r1+0x0], r4
  jeq r5, 0x1, jmp_2c8d0
  ldxdw r4, [r7+0x10]
  ldxdw r5, [r4+0x0]
  add64 r5, 0x1
  mov64 r6, 0x1
  jeq r5, 0x0, jmp_2bae0
  mov64 r6, 0x0

jmp_2bae0:
  mov64 r8, r3
  stxdw [r10-0x2c8], r0
  stxdw [r4+0x0], r5
  jeq r6, 0x1, jmp_2c8d0
  ldxdw r5, [r7+0x18]
  ldxdw r6, [r7+0x20]
  ldxb r0, [r7+0x28]
  ldxb r3, [r7+0x29]
  ldxb r7, [r7+0x2a]
  stxb [r10-0x86], r7
  stxb [r10-0x87], r3
  stxb [r10-0x88], r0
  stxdw [r10-0x90], r6
  stxdw [r10-0x98], r5
  stxdw [r10-0xa0], r4
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x2c0]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x2b8]
  stxb [r10-0xb6], r1
  ldxdw r1, [r10-0x2b0]
  stxb [r10-0xb7], r1
  ldxdw r1, [r10-0x2a8]
  stxb [r10-0xb8], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0xc0], r1
  stxdw [r10-0xc8], r8
  stxdw [r10-0xd0], r2
  ldxdw r1, [r10-0x218]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x280]
  stxb [r10-0xe6], r1
  ldxdw r1, [r10-0x278]
  stxb [r10-0xe7], r1
  ldxdw r1, [r10-0x270]
  stxb [r10-0xe8], r1
  ldxdw r1, [r10-0x268]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x260]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x210]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x250]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x258]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x248]
  stxb [r10-0x116], r1
  ldxdw r1, [r10-0x240]
  stxb [r10-0x117], r1
  ldxdw r1, [r10-0x238]
  stxb [r10-0x118], r1
  ldxdw r1, [r10-0x230]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x298]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x2c8]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x228]
  stxdw [r10-0x140], r1
  stdw [r10-0x78], 0x0
  stdw [r10-0x80], 0x8
  stdw [r10-0x148], 0x0
  stdw [r10-0x150], 0x8
  stdw [r10-0x158], 0x0
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r10
  add64 r2, -0x158
  ldxdw r7, [r10-0x208]
  mov64 r3, r7
  call fn_b7360
  ldxdw r6, [r10-0x1c0]
  jne r6, 0x2, jmp_2c020
  ldxdw r1, [r9+0xb8]
  ldxdw r2, [r1+0x30]
  jeq r2, -0x1, jmp_2c030
  add64 r2, 0x1
  stxdw [r1+0x30], r2
  ldxdw r3, [r9+0x50]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2bda8
  mov64 r2, 0x0

jmp_2bda8:
  ldxdw r6, [r9+0x48]
  stxdw [r3+0x0], r1
  ldxdw r5, [r10-0x200]
  jeq r2, 0x1, jmp_2c8d0
  ldxdw r4, [r9+0x58]
  ldxdw r1, [r4+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2bdf8
  mov64 r2, 0x0

jmp_2bdf8:
  stxdw [r10-0x210], r3
  stxdw [r10-0x218], r4
  stxdw [r4+0x0], r1
  jeq r2, 0x1, jmp_2c8d0
  ldxb r1, [r5+0x21]
  stxdw [r10-0x200], r1
  ldxb r1, [r9+0x72]
  stxdw [r10-0x248], r1
  ldxb r1, [r9+0x71]
  stxdw [r10-0x240], r1
  ldxb r1, [r9+0x70]
  stxdw [r10-0x238], r1
  ldxdw r1, [r9+0x68]
  stxdw [r10-0x230], r1
  ldxdw r1, [r9+0x60]
  stxdw [r10-0x228], r1
  ldxdw r1, [r9+0xa8]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x140], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x148], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x150], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x158], r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  mov64 r2, 0x0
  mov64 r4, 0x1
  mov64 r3, r1
  add64 r3, -0x100
  jle r3, r1, jmp_2c080
  jeq r4, 0x0, jmp_2c090

jmp_2bf18:
  lddw r8, 0x300007f00
  jne r1, 0x0, jmp_2c0b0

jmp_2bf30:
  mov64 r9, r6
  lddw r1, 0x300000007
  ldxdw r2, [r10-0x220]
  jle r8, r1, jmp_2c0e0

jmp_2bf58:
  lddw r6, 0x300000000
  stxdw [r6+0x0], r8
  lddw r1, -0x6473cfb6f075ecf8
  stxdw [r8+0x0], r1
  ldxdw r1, [r10-0x158]
  stxdw [r8+0x8], r1
  ldxdw r1, [r10-0x150]
  stxdw [r8+0x10], r1
  ldxdw r1, [r10-0x148]
  stxdw [r8+0x18], r1
  ldxdw r1, [r10-0x140]
  stxdw [r8+0x20], r1
  stxdw [r8+0x29], r7
  stxb [r8+0x28], r2
  mov64 r1, 0x0
  mov64 r7, 0x39
  jsge r7, 0x0, jmp_2c108

jmp_2bff0:
  mov64 r2, 0x39
  lddw r3, data_6068
  call fn_cb038

jmp_2c010:
  ldxdw r7, [r10-0x1a8]
  ja jmp_2c060

jmp_2c020:
  ldxdw r7, [r10-0x1b8]
  ja jmp_2c060

jmp_2c030:
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x1d8]
  ldxdw r6, [r10-0x1e0]

jmp_2c060:
  ldxdw r1, [r10-0x1f8]
  stxdw [r1+0x0], r6
  stxdw [r1+0x8], r7
  exit

jmp_2c080:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2bf18

jmp_2c090:
  mov64 r2, r3
  lddw r8, 0x300007f00
  jeq r1, 0x0, jmp_2bf30

jmp_2c0b0:
  mov64 r8, r2
  mov64 r9, r6
  lddw r1, 0x300000007
  ldxdw r2, [r10-0x220]
  jgt r8, r1, jmp_2bf58

jmp_2c0e0:
  mov64 r1, 0x1
  mov64 r2, 0x100
  lddw r3, data_6d98
  call fn_cb038

jmp_2c108:
  call fn_b1c08
  ldxdw r1, [r6+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_2c138
  mov64 r3, r1

jmp_2c138:
  mov64 r2, r3
  sub64 r2, r7
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r4, 0x1
  jle r2, r3, jmp_2c190
  jeq r4, 0x0, jmp_2c1a0

jmp_2c170:
  lddw r2, 0x300000007
  jgt r7, r2, jmp_2c1c0
  ja jmp_2bff0

jmp_2c190:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2c170

jmp_2c1a0:
  mov64 r7, r2
  lddw r2, 0x300000007
  jle r7, r2, jmp_2bff0

jmp_2c1c0:
  stxdw [r6+0x0], r7
  lddw r1, 0x1d9acb512ea545e4
  stxdw [r7+0x0], r1
  ldxb r1, [r8+0x0]
  stxb [r7+0x8], r1
  ldxb r1, [r8+0x1]
  stxb [r7+0x9], r1
  ldxb r1, [r8+0x2]
  stxb [r7+0xa], r1
  ldxb r1, [r8+0x3]
  stxb [r7+0xb], r1
  ldxb r1, [r8+0x4]
  stxb [r7+0xc], r1
  ldxb r1, [r8+0x5]
  stxb [r7+0xd], r1
  ldxb r1, [r8+0x6]
  stxb [r7+0xe], r1
  ldxb r1, [r8+0x7]
  stxb [r7+0xf], r1
  ldxb r1, [r8+0x8]
  stxb [r7+0x10], r1
  ldxb r1, [r8+0x9]
  stxb [r7+0x11], r1
  ldxb r1, [r8+0xa]
  stxb [r7+0x12], r1
  ldxb r1, [r8+0xb]
  stxb [r7+0x13], r1
  ldxb r1, [r8+0xc]
  stxb [r7+0x14], r1
  ldxb r1, [r8+0xd]
  stxb [r7+0x15], r1
  ldxb r1, [r8+0xe]
  stxb [r7+0x16], r1
  ldxb r1, [r8+0xf]
  stxb [r7+0x17], r1
  ldxb r1, [r8+0x10]
  stxb [r7+0x18], r1
  ldxb r1, [r8+0x11]
  stxb [r7+0x19], r1
  ldxb r1, [r8+0x12]
  stxb [r7+0x1a], r1
  ldxb r1, [r8+0x13]
  stxb [r7+0x1b], r1
  ldxb r1, [r8+0x14]
  stxb [r7+0x1c], r1
  ldxb r1, [r8+0x15]
  stxb [r7+0x1d], r1
  ldxb r1, [r8+0x16]
  stxb [r7+0x1e], r1
  ldxb r1, [r8+0x17]
  stxb [r7+0x1f], r1
  ldxb r1, [r8+0x18]
  stxb [r7+0x20], r1
  ldxb r1, [r8+0x19]
  stxb [r7+0x21], r1
  ldxb r1, [r8+0x1a]
  stxb [r7+0x22], r1
  ldxb r1, [r8+0x1b]
  stxb [r7+0x23], r1
  ldxb r1, [r8+0x1c]
  stxb [r7+0x24], r1
  ldxb r1, [r8+0x1d]
  stxb [r7+0x25], r1
  ldxb r1, [r8+0x1e]
  stxb [r7+0x26], r1
  ldxb r1, [r8+0x1f]
  stxb [r7+0x27], r1
  ldxb r1, [r8+0x20]
  stxb [r7+0x28], r1
  ldxb r1, [r8+0x21]
  stxb [r7+0x29], r1
  ldxb r1, [r8+0x22]
  stxb [r7+0x2a], r1
  ldxb r1, [r8+0x23]
  stxb [r7+0x2b], r1
  ldxb r1, [r8+0x24]
  stxb [r7+0x2c], r1
  ldxb r1, [r8+0x25]
  stxb [r7+0x2d], r1
  ldxb r1, [r8+0x26]
  stxb [r7+0x2e], r1
  ldxb r1, [r8+0x27]
  stxb [r7+0x2f], r1
  ldxb r1, [r8+0x28]
  stxb [r7+0x30], r1
  ldxb r1, [r8+0x29]
  stxb [r7+0x31], r1
  ldxb r1, [r8+0x2a]
  stxb [r7+0x32], r1
  ldxb r1, [r8+0x2b]
  stxb [r7+0x33], r1
  ldxb r1, [r8+0x2c]
  stxb [r7+0x34], r1
  ldxb r1, [r8+0x2d]
  stxb [r7+0x35], r1
  ldxb r1, [r8+0x2e]
  stxb [r7+0x36], r1
  ldxb r1, [r8+0x2f]
  stxb [r7+0x37], r1
  ldxb r1, [r8+0x30]
  stxb [r7+0x38], r1
  call fn_b1c08
  ldxdw r2, [r6+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jle r1, r2, jmp_2c7a8
  jeq r4, 0x0, jmp_2c7b8

jmp_2c530:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_2c7d8

jmp_2c548:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_2c7f8

jmp_2c560:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r9+0x0]
  ldxdw r3, [r9+0x8]
  ldxdw r4, [r9+0x10]
  ldxdw r5, [r9+0x18]
  stxdw [r1+0x18], r5
  stxdw [r1+0x10], r4
  stxdw [r1+0x8], r3
  stxdw [r1+0x0], r2
  sth [r1+0x20], 0x1
  stxdw [r10-0x50], r1
  stdw [r10-0x48], 0x1
  stdw [r10-0x58], 0x1
  mov64 r8, r10
  add64 r8, -0x158
  mov64 r5, r10
  add64 r5, -0x58
  mov64 r1, r8
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, 0x39
  call fn_c96c0
  ldxdw r1, [r10-0x248]
  stxb [r10-0x2e], r1
  ldxdw r1, [r10-0x240]
  stxb [r10-0x2f], r1
  ldxdw r1, [r10-0x238]
  stxb [r10-0x30], r1
  ldxdw r1, [r10-0x230]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x228]
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x218]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0x210]
  stxdw [r10-0x50], r1
  stxdw [r10-0x58], r9
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x170], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0x18], r1
  lddw r1, str_17d4
  stxdw [r10-0x28], r1
  ldxdw r1, [r10-0x200]
  stxb [r10-0x1], r1
  stdw [r10-0x168], 0x2
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x11
  mov64 r1, r10
  add64 r1, -0x170
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x70
  mov64 r3, r10
  add64 r3, -0x58
  mov64 r5, r10
  mov64 r2, r8
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x70]
  jne r2, r1, jmp_2c810
  mov64 r6, 0x2
  ldxdw r2, [r10-0x210]
  ja jmp_2c850

jmp_2c7a8:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_2c530

jmp_2c7b8:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_2c548

jmp_2c7d8:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_2c560

jmp_2c7f8:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_2c810:
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0x70
  call fn_be7f0
  ldxdw r2, [r10-0x50]
  ldxdw r7, [r10-0x1c8]
  ldxdw r6, [r10-0x1d0]

jmp_2c850:
  ldxdw r1, [r2+0x0]
  add64 r1, -0x1
  stxdw [r2+0x0], r1
  jne r1, 0x0, jmp_2c888
  mov64 r1, r10
  add64 r1, -0x50
  call fn_c25c0

jmp_2c888:
  ldxdw r1, [r10-0x48]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_2c060
  mov64 r1, r10
  add64 r1, -0x48
  call fn_c2610
  ja jmp_2c060

jmp_2c8d0:
  call abort

jmp_2c8d8:
  mov64 r3, r10
  add64 r3, -0x158
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_2c928:
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r7, [r10-0x188]
  ldxdw r6, [r10-0x190]
  jeq r6, 0x2, jmp_2b6e0
  ja jmp_2c060

fn_2c968:
  mov64 r6, r3
  mov64 r9, r2
  stxdw [r10-0x580], r1
  ldxdw r7, [r9+0x8]
  ldxdw r1, [r7+0x70]
  mov64 r3, 0x0
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_2c9c0
  mov64 r3, r7
  add64 r3, 0x70

jmp_2c9c0:
  ldxdw r4, [r7+0x1c8]
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, 0x1
  call fn_4d818
  ldxdw r8, [r10-0x3d8]
  jne r8, 0x2, jmp_2cac0
  ldxdw r1, [r7+0x1d0]
  ldxdw r1, [r1+0x28]
  stxdw [r10-0x588], r1
  ldxdw r8, [r7+0x1b0]
  mov64 r1, r10
  add64 r1, -0x280
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0x278
  ldxdw r2, [r10-0x280]
  jne r2, 0x1, jmp_2cae8
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x188], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x190], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x198], r1
  mov64 r1, r10
  add64 r1, -0x578
  mov64 r2, r10
  add64 r2, -0x198
  call fn_be7f0
  ldxdw r9, [r10-0x570]
  ldxdw r8, [r10-0x578]
  ja jmp_2cac8

jmp_2cac0:
  ldxdw r9, [r10-0x3d0]

jmp_2cac8:
  ldxdw r1, [r10-0x580]
  stxdw [r1+0x0], r8
  stxdw [r1+0x8], r9
  exit

jmp_2cae8:
  stxdw [r10-0x590], r9
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r1+0x10]
  ldxdw r4, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x3c8], r1
  stxdw [r10-0x190], r4
  stxdw [r10-0x3c0], r4
  stxdw [r10-0x188], r3
  stxdw [r10-0x3b8], r3
  stxdw [r10-0x180], r2
  stxdw [r10-0x3b0], r2
  ldxdw r0, [r10-0x258]
  stxdw [r10-0x3a8], r0
  ldxdw r9, [r7+0x1a8]
  jge r0, r9, jmp_2cd00
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_1678
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_1678
  call fn_5a268
  jne r0, 0x0, jmp_2dde0
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x258], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x250], r1
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stw [r10-0x1e8], 0x1792
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x34
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  mov64 r1, r10
  add64 r1, -0x568
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x560]
  ldxdw r8, [r10-0x568]
  ja jmp_2cac8

jmp_2cd00:
  stxdw [r10-0x598], r8
  ldxdw r1, [r7+0x38]
  mov64 r3, r9
  add64 r3, r1
  mov64 r2, 0x1
  jlt r3, r9, jmp_2cd38
  mov64 r2, 0x0

jmp_2cd38:
  and64 r2, 0x1
  jne r2, 0x0, jmp_2de30
  add64 r9, r1

jmp_2cd50:
  ldxdw r2, [r10-0x598]
  jeq r2, 0x0, jmp_2ce58
  ldxdw r1, [r10-0x588]
  jeq r1, 0x0, jmp_2ce58
  ldxdw r1, [r7+0x1d8]
  ldxdw r1, [r1+0x48]
  jge r1, r2, jmp_2cff0
  mov64 r1, r10
  add64 r1, -0x260
  lddw r2, data_1650
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_1650
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x43
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  stw [r10-0x1e8], 0x1775
  mov64 r1, r10
  add64 r1, -0x558
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x550]
  ldxdw r8, [r10-0x558]
  ja jmp_2cac8

jmp_2ce58:
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x330], 0x0
  stdw [r10-0x338], 0x1
  stdw [r10-0x340], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_2dde0
  ldxdw r1, [r10-0x330]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x240], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x248], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x258], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x250], r1
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stw [r10-0x1e8], 0x1771
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x3e
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  mov64 r1, r10
  add64 r1, -0x3f8
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x3f0]
  ldxdw r8, [r10-0x3f8]
  ja jmp_2cac8

jmp_2cff0:
  ldxdw r1, [r7+0x1c0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x268], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x270], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x278], r2
  mov64 r5, r7
  add64 r5, 0x160
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x280], r1
  ldxdw r2, [r7+0x160]
  jne r1, r2, jmp_2d0b0
  ldxdw r1, [r5+0x8]
  ldxdw r2, [r10-0x278]
  jne r2, r1, jmp_2d0b0
  ldxdw r1, [r5+0x10]
  ldxdw r2, [r10-0x270]
  jne r2, r1, jmp_2d0b0
  mov64 r1, 0x0
  ldxdw r2, [r5+0x18]
  ldxdw r3, [r10-0x268]
  jeq r3, r2, jmp_2d0b8

jmp_2d0b0:
  mov64 r1, 0x1

jmp_2d0b8:
  jeq r1, 0x0, jmp_2d268
  ldxb r1, [r7+0x1bf]
  jeq r1, 0x0, jmp_2d650
  ldxdw r1, [r7+0x1f8]
  jeq r1, 0x0, jmp_2d820
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x268], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x270], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x278], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x280], r1
  ldxdw r2, [r5+0x0]
  jne r1, r2, jmp_2d188
  ldxdw r1, [r5+0x8]
  ldxdw r2, [r10-0x278]
  jne r2, r1, jmp_2d188
  ldxdw r1, [r5+0x10]
  ldxdw r2, [r10-0x270]
  jne r2, r1, jmp_2d188
  mov64 r1, 0x0
  ldxdw r2, [r5+0x18]
  ldxdw r3, [r10-0x268]
  jeq r3, r2, jmp_2d190

jmp_2d188:
  mov64 r1, 0x1

jmp_2d190:
  jeq r1, 0x0, jmp_2da78
  mov64 r1, r10
  add64 r1, -0x260
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x5b
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  stw [r10-0x1e8], 0x1771
  mov64 r1, r10
  add64 r1, -0x418
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x410]
  ldxdw r8, [r10-0x418]
  ja jmp_2cac8

jmp_2d268:
  stxdw [r10-0x5a0], r0
  stxdw [r10-0x5a8], r5
  mov64 r8, r7
  add64 r8, 0x1c0
  ldxdw r1, [r7+0x1e0]

jmp_2d290:
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x340
  call fn_d5c0
  ldxdw r2, [r8+0x0]
  mov64 r8, r10
  add64 r8, -0x198
  mov64 r1, r8
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r10
  add64 r2, -0x340
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x370
  mov64 r2, r8
  mov64 r3, 0x30
  call fn_d23d0
  ldxb r1, [r7+0x66]
  stxb [r10-0x2f9], r1
  stxdw [r10-0x2f8], r6
  ldxb r2, [r7+0x1bc]
  mov64 r3, r10
  add64 r3, -0x2e9
  stxdw [r10-0x310], r3
  mov64 r3, r10
  add64 r3, -0x2f8
  stxdw [r10-0x320], r3
  mov64 r3, r10
  add64 r3, -0x2f9
  stxdw [r10-0x330], r3
  lddw r3, str_13b8
  stxdw [r10-0x340], r3
  stxb [r10-0x2e9], r2
  stdw [r10-0x308], 0x1
  stdw [r10-0x318], 0x8
  stdw [r10-0x328], 0x1
  stdw [r10-0x338], 0x8
  ldxdw r2, [r10-0x5a0]
  jle r2, r9, jmp_2d720
  ldxdw r2, [r7+0x1e8]
  mov64 r1, r10
  add64 r1, -0x268
  call fn_d5c0
  ldxdw r1, [r7+0x1d8]
  ldxdw r2, [r1+0x0]
  mov64 r6, r10
  add64 r6, -0x198
  mov64 r1, r6
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r10
  add64 r2, -0x3a0
  mov64 r3, 0x30
  call fn_d23d0
  ldxdw r2, [r7+0x118]
  mov64 r1, r10
  add64 r1, -0x138
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0xd8], r1
  stdw [r10-0xd0], 0x4
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, r6
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x1a8], r1
  stdw [r10-0x1a0], 0x1
  stdw [r10-0x270], 0x0
  stdw [r10-0x278], 0x8
  stdw [r10-0x280], 0x0
  ldxdw r1, [r7+0x1d8]
  ldxdw r3, [r1+0x48]
  mov64 r1, r10
  add64 r1, -0x538
  mov64 r2, r10
  add64 r2, -0x280
  call fn_b7360
  ldxdw r8, [r10-0x538]
  jne r8, 0x2, jmp_2d858
  ldxdw r1, [r7+0x1d8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r8, r1
  call fn_d5c0
  ldxdw r2, [r7+0x118]
  mov64 r6, r10
  add64 r6, -0x280
  mov64 r1, r6
  call fn_d5c0
  ldxdw r2, [r7+0x1e8]
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0xff8], r1
  mov64 r1, r10
  add64 r1, -0x370
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x548
  mov64 r5, r10
  mov64 r7, r8
  mov64 r3, r7
  mov64 r4, r6
  call fn_2f4b0
  ldxdw r9, [r10-0x540]
  ldxdw r8, [r10-0x548]
  mov64 r1, r6
  call fn_9d08
  mov64 r1, r7
  call fn_9d08
  ja jmp_2d860

jmp_2d650:
  mov64 r1, r10
  add64 r1, -0x260
  lddw r2, data_167c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_167c
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x50
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  stw [r10-0x1e8], 0x17bb
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x400]
  ldxdw r8, [r10-0x408]
  ja jmp_2cac8

jmp_2d720:
  ldxdw r2, [r10-0x590]
  ldxdw r3, [r2+0x18]
  ldxb r6, [r7+0x67]
  mov64 r9, r6
  mul64 r9, 0x3
  jge r3, r9, jmp_2d880
  mov64 r1, r10
  add64 r1, -0x260
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x88
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  stw [r10-0x1e8], 0x1771
  mov64 r1, r10
  add64 r1, -0x528
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x520]
  ldxdw r8, [r10-0x528]
  ja jmp_2da40

jmp_2d820:
  mov64 r1, r10
  add64 r1, -0x448
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r9, [r10-0x440]
  ldxdw r8, [r10-0x448]
  ja jmp_2cac8

jmp_2d858:
  ldxdw r9, [r10-0x530]

jmp_2d860:
  mov64 r1, r10
  add64 r1, -0x370
  call fn_9d08
  ja jmp_2cac8

jmp_2d880:
  stxdw [r10-0x5a0], r3
  ldxdw r8, [r2+0x10]
  stxb [r10-0x2b2], r1
  ldxb r1, [r7+0x65]
  mov64 r2, r10
  add64 r2, -0x2b1
  stxdw [r10-0x2c8], r2
  mov64 r2, r10
  add64 r2, -0x2b2
  stxdw [r10-0x2d8], r2
  lddw r2, str_1775
  stxdw [r10-0x2e8], r2
  stxb [r10-0x2b1], r1
  stdw [r10-0x2c0], 0x1
  stdw [r10-0x2d0], 0x1
  stdw [r10-0x2e0], 0xe
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r7
  mov64 r3, r8
  mov64 r4, r9
  call fn_49240
  ldxdw r3, [r10-0x270]
  ldxdw r2, [r10-0x278]
  ldxdw r1, [r10-0x280]
  lddw r4, -0x8000000000000000
  jeq r1, r4, jmp_2da30
  stxdw [r10-0x5b0], r6
  stxdw [r10-0x5b8], r3
  mov64 r1, r3
  mul64 r1, 0x12c
  mov64 r3, r2
  add64 r3, r1
  mov64 r6, r10
  add64 r6, -0x2b0
  mov64 r1, r6
  stxdw [r10-0x5c0], r2
  call fn_06b8
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r7
  mov64 r3, r6
  mov64 r4, r8
  mov64 r5, r9
  call fn_4b620
  ldxdw r3, [r10-0x270]
  ldxdw r2, [r10-0x278]
  ldxdw r1, [r10-0x280]
  mov64 r6, r8
  lddw r4, -0x8000000000000000
  jne r1, r4, jmp_2dc08

jmp_2da30:
  mov64 r9, r3

jmp_2da38:
  mov64 r8, r2

jmp_2da40:
  mov64 r1, r10
  add64 r1, -0x370
  call fn_9d08
  mov64 r1, r10
  add64 r1, -0x3a0
  call fn_9d08
  ja jmp_2cac8

jmp_2da78:
  ldxdw r1, [r7+0x200]
  jeq r1, 0x0, jmp_2dbd0
  ldxdw r2, [r5+0x0]
  ldxdw r3, [r1+0x28]
  jne r3, r2, jmp_2daf0
  ldxdw r2, [r5+0x8]
  ldxdw r3, [r1+0x30]
  jne r3, r2, jmp_2daf0
  ldxdw r2, [r5+0x10]
  ldxdw r3, [r1+0x38]
  jne r3, r2, jmp_2daf0
  mov64 r2, 0x0
  ldxdw r3, [r5+0x18]
  ldxdw r4, [r1+0x40]
  jeq r4, r3, jmp_2daf8

jmp_2daf0:
  mov64 r2, 0x1

jmp_2daf8:
  jeq r2, 0x0, jmp_2dcc8
  mov64 r1, r10
  add64 r1, -0x260
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x248
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0x278], r1
  stb [r10-0x230], 0x2
  stw [r10-0x268], 0x61
  stdw [r10-0x270], 0x2e
  stdw [r10-0x280], 0x0
  stw [r10-0x1e8], 0x1771
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r2, r10
  add64 r2, -0x280
  call fn_be760
  ldxdw r9, [r10-0x420]
  ldxdw r8, [r10-0x428]
  ja jmp_2cac8

jmp_2dbd0:
  mov64 r1, r10
  add64 r1, -0x438
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r9, [r10-0x430]
  ldxdw r8, [r10-0x438]
  ja jmp_2cac8

jmp_2dc08:
  mov64 r1, r10
  add64 r1, -0x458
  stxdw [r10-0x5d0], r2
  stxdw [r10-0x5c8], r3
  call fn_4d878
  ldxdw r8, [r10-0x458]
  jne r8, 0x2, jmp_2dcf0
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r3, r10
  add64 r3, -0x2b0
  ldxdw r2, [r10-0x5a8]
  mov64 r4, r6
  mov64 r5, r9
  call fn_4c090
  ldxdw r8, [r10-0x270]
  ldxdw r2, [r10-0x278]
  ldxdw r1, [r10-0x280]
  mov64 r4, r6
  lddw r6, -0x8000000000000000
  jne r1, r6, jmp_2dd00
  mov64 r9, r8
  ja jmp_2da38

jmp_2dcc8:
  stxdw [r10-0x5a0], r0
  stxdw [r10-0x5a8], r5
  mov64 r8, r7
  add64 r8, 0x1f8
  ja jmp_2d290

jmp_2dcf0:
  ldxdw r9, [r10-0x450]
  ja jmp_2da40

jmp_2dd00:
  stxdw [r10-0x5e8], r2
  ldxdw r5, [r10-0x5a0]
  sub64 r5, r9
  mul64 r9, 0x30
  stxdw [r10-0x5a0], r4
  add64 r4, r9
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r10
  add64 r2, -0x3c8
  mov64 r3, r10
  add64 r3, -0x2b0
  call fn_4a398
  ldxdw r9, [r10-0x270]
  ldxdw r2, [r10-0x278]
  ldxdw r1, [r10-0x280]
  jeq r1, r6, jmp_2da38
  stxdw [r10-0x5e0], r2
  stxdw [r10-0x5d8], r9
  stxdw [r10-0x5f0], r8
  ldxdw r6, [r10-0x2a0]
  ldxdw r9, [r10-0x2a8]
  ldxdw r2, [r7+0x208]
  jeq r2, 0x0, jmp_2de80
  mov64 r1, r10
  add64 r1, -0x280
  call fn_d5c0
  ja jmp_2de88

jmp_2dde0:
  mov64 r3, r10
  add64 r3, -0x108
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_2de30:
  mov64 r1, r10
  add64 r1, -0x3e8
  mov64 r2, 0x10
  mov64 r8, r0
  call fn_5a078
  mov64 r0, r8
  ldxdw r9, [r10-0x3e0]
  ldxdw r8, [r10-0x3e8]
  jne r8, 0x2, jmp_2cac8
  ja jmp_2cd50

jmp_2de80:
  stb [r10-0x256], 0x2

jmp_2de88:
  ldxdw r1, [r7+0x210]
  stxdw [r10-0xfd8], r1
  mov64 r1, r10
  add64 r1, -0x280
  stxdw [r10-0xfe0], r1
  ldxdw r1, [r10-0x5d8]
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x5e0]
  stxdw [r10-0xff0], r1
  ldxdw r1, [r10-0x5c8]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x5d0]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x468
  mov64 r5, r10
  mov64 r2, r7
  mov64 r3, r9
  mov64 r4, r6
  call fn_2ff60
  ldxdw r8, [r10-0x468]
  jne r8, 0x2, jmp_2eeb0
  mov64 r1, r10
  add64 r1, -0x478
  ldxdw r6, [r10-0x5b8]
  mov64 r2, r6
  mov64 r3, 0x8
  mov64 r4, 0x28
  lddw r5, data_63c8
  call fn_c540
  ldxdw r1, [r10-0x478]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x470]
  stxdw [r10-0x620], r1
  stxdw [r10-0x290], r1
  stdw [r10-0x288], 0x0
  jeq r6, 0x0, jmp_2e6c0
  mov64 r1, r7
  add64 r1, 0x120
  stxdw [r10-0x610], r1
  mov64 r1, 0x1
  mov64 r2, 0x0
  stxdw [r10-0x628], r2
  mov64 r2, r10
  add64 r2, -0x268
  stxdw [r10-0x630], r2
  mov64 r2, r10
  add64 r2, -0x238
  stxdw [r10-0x638], r2
  mov64 r2, r10
  add64 r2, -0x138
  stxdw [r10-0x640], r2
  mov64 r2, r10
  add64 r2, -0x168
  stxdw [r10-0x648], r2
  ldxdw r2, [r10-0x5b0]
  mul64 r2, 0x90
  stxdw [r10-0x5b0], r2
  ldxdw r2, [r10-0x5a0]
  add64 r2, -0x30
  stxdw [r10-0x5a0], r2
  mov64 r6, 0x0

jmp_2e080:
  stxdw [r10-0x5f8], r1
  ldxdw r1, [r10-0x5c8]
  jge r6, r1, jmp_2f238
  ldxdw r1, [r10-0x5f0]
  jge r6, r1, jmp_2f260
  mov64 r2, r6
  mul64 r2, 0xd0
  ldxdw r1, [r10-0x5d0]
  stxdw [r10-0x608], r2
  add64 r1, r2
  stxdw [r10-0x600], r1
  ldxdw r2, [r1+0x60]
  mov64 r1, r10
  add64 r1, -0x488
  mov64 r3, 0x0
  ldxdw r4, [r10-0x598]
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x498
  ldxdw r2, [r10-0x488]
  ldxdw r3, [r10-0x480]
  ldxdw r4, [r10-0x588]
  mov64 r5, 0x0
  call fn_d45f0
  ldxdw r1, [r10-0x490]
  jeq r1, 0x0, jmp_2e190
  mov64 r1, r10
  add64 r1, -0x4a8
  call fn_2f2b0
  ldxdw r9, [r10-0x4a0]
  ldxdw r8, [r10-0x4a8]
  jeq r8, 0x2, jmp_2e198
  ja jmp_2da40

jmp_2e190:
  ldxdw r9, [r10-0x498]

jmp_2e198:
  ldxdw r1, [r10-0x5d8]
  jge r6, r1, jmp_2f288
  mov64 r1, r6
  mul64 r1, 0x12c
  ldxdw r2, [r10-0x5c0]
  add64 r2, r1
  add64 r2, 0x20
  mul64 r6, 0x18
  ldxdw r5, [r10-0x5e0]
  add64 r5, r6
  stxdw [r10-0x618], r2
  ldxb r3, [r2+0x107]
  mov64 r1, r10
  add64 r1, -0x280
  ldxdw r2, [r10-0x610]
  mov64 r4, r9
  call fn_142b8
  ldxdw r9, [r10-0x278]
  ldxdw r8, [r10-0x280]
  jne r8, 0x2, jmp_2da40
  ldxdw r1, [r10-0x5e8]
  ldxdw r2, [r10-0x608]
  add64 r1, r2
  ldxdw r2, [r10-0x5b0]
  ldxdw r6, [r10-0x5a0]
  ldxdw r0, [r10-0x600]
  jeq r9, 0x0, jmp_2e668

jmp_2e270:
  jeq r2, 0x0, jmp_2eec0
  ldxdw r3, [r6+0x30]
  ldxdw r4, [r3+0x18]
  stxdw [r10-0x268], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x270], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x278], r4
  ldxdw r3, [r3+0x0]
  stxdw [r10-0x280], r3
  ldxdw r4, [r0+0x0]
  jne r3, r4, jmp_2e320
  ldxdw r3, [r0+0x8]
  ldxdw r4, [r10-0x278]
  jne r4, r3, jmp_2e320
  ldxdw r3, [r0+0x10]
  ldxdw r4, [r10-0x270]
  jne r4, r3, jmp_2e320
  mov64 r3, 0x0
  ldxdw r4, [r0+0x18]
  ldxdw r5, [r10-0x268]
  jeq r5, r4, jmp_2e328

jmp_2e320:
  mov64 r3, 0x1

jmp_2e328:
  add64 r2, -0x30
  add64 r6, 0x30
  jne r3, 0x0, jmp_2e270
  ldxdw r2, [r10-0x5b0]
  ldxdw r8, [r10-0x5a0]

jmp_2e350:
  jeq r2, 0x0, jmp_2eef8
  ldxdw r3, [r8+0x30]
  ldxdw r4, [r3+0x18]
  stxdw [r10-0x268], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x270], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x278], r4
  ldxdw r3, [r3+0x0]
  stxdw [r10-0x280], r3
  ldxdw r4, [r1+0x0]
  jne r3, r4, jmp_2e400
  ldxdw r3, [r1+0x8]
  ldxdw r4, [r10-0x278]
  jne r4, r3, jmp_2e400
  ldxdw r3, [r1+0x10]
  ldxdw r4, [r10-0x270]
  jne r4, r3, jmp_2e400
  mov64 r3, 0x0
  ldxdw r4, [r1+0x18]
  ldxdw r5, [r10-0x268]
  jeq r5, r4, jmp_2e408

jmp_2e400:
  mov64 r3, 0x1

jmp_2e408:
  add64 r2, -0x30
  add64 r8, 0x30
  jne r3, 0x0, jmp_2e350
  ldxdw r2, [r7+0x1e8]
  ldxdw r1, [r10-0x630]
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x198
  stxdw [r10-0x600], r1
  mov64 r2, r6
  call fn_d5c0
  ldxdw r1, [r10-0x648]
  mov64 r2, r8
  call fn_d5c0
  ldxdw r2, [r7+0x68]
  ldxdw r1, [r10-0x640]
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x2e8
  stxdw [r10-0xd8], r1
  stdw [r10-0xd0], 0x3
  ldxdw r1, [r10-0x638]
  ldxdw r2, [r10-0x600]
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x1a8], r1
  stdw [r10-0x1a0], 0x1
  stdw [r10-0x270], 0x0
  stdw [r10-0x278], 0x8
  stdw [r10-0x280], 0x0
  mov64 r1, r10
  add64 r1, -0x4b8
  mov64 r2, r10
  add64 r2, -0x280
  mov64 r3, r9
  call fn_b7360
  ldxdw r8, [r10-0x4b8]
  jne r8, 0x2, jmp_2f220
  ldxdw r2, [r10-0x618]
  ldxdw r1, [r2+0x18]
  stxdw [r10-0x268], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x270], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x298]
  ldxdw r2, [r10-0x628]
  jne r2, r1, jmp_2e5e0
  mov64 r1, r10
  add64 r1, -0x298
  lddw r2, data_6428
  call fn_c380
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x620], r1

jmp_2e5e0:
  ldxdw r3, [r10-0x628]
  mov64 r1, r3
  mul64 r1, 0x28
  ldxdw r2, [r10-0x620]
  add64 r2, r1
  ldxdw r1, [r10-0x268]
  stxdw [r2+0x18], r1
  ldxdw r1, [r10-0x270]
  stxdw [r2+0x10], r1
  ldxdw r1, [r10-0x278]
  stxdw [r2+0x8], r1
  ldxdw r1, [r10-0x280]
  stxdw [r2+0x0], r1
  stxdw [r2+0x20], r9
  add64 r3, 0x1
  stxdw [r10-0x628], r3
  stxdw [r10-0x288], r3

jmp_2e668:
  mov64 r2, 0x1
  ldxdw r1, [r10-0x5b8]
  ldxdw r3, [r10-0x5f8]
  jlt r3, r1, jmp_2e690
  mov64 r2, 0x0

jmp_2e690:
  ldxdw r3, [r10-0x5f8]
  mov64 r1, r3
  add64 r1, r2
  mov64 r6, r3
  ldxdw r2, [r10-0x5b8]
  jlt r3, r2, jmp_2e080

jmp_2e6c0:
  ldxdw r1, [r7+0x1d8]
  ldxdw r6, [r1+0x48]
  ldxdw r1, [r10-0x598]
  jle r6, r1, jmp_2e9a8
  ldxdw r2, [r7+0x1e8]
  mov64 r1, r10
  add64 r1, -0xd8
  call fn_d5c0
  ldxdw r1, [r7+0x1d8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x198
  call fn_d5c0
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x588], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2e760
  mov64 r2, 0x0

jmp_2e760:
  ldxdw r3, [r10-0x3a0]
  stxdw [r10-0x5a0], r3
  ldxdw r3, [r10-0x588]
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_2f230
  ldxdw r9, [r10-0x390]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_2e7b8
  mov64 r2, 0x0

jmp_2e7b8:
  stxdw [r9+0x0], r1
  jeq r2, 0x1, jmp_2f230
  ldxdw r1, [r10-0x598]
  sub64 r6, r1
  ldxdw r2, [r7+0x118]
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x5b0], r1
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x5b8], r1
  ldxb r1, [r10-0x378]
  stxdw [r10-0x5c0], r1
  ldxb r1, [r10-0x377]
  stxdw [r10-0x5c8], r1
  ldxb r8, [r10-0x376]
  mov64 r1, r10
  add64 r1, -0x1d8
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r3, 0x30
  call fn_d23d0
  stxb [r10-0x1de], r8
  ldxdw r1, [r10-0x5c8]
  stxb [r10-0x1df], r1
  ldxdw r1, [r10-0x5c0]
  stxb [r10-0x1e0], r1
  ldxdw r1, [r10-0x5b8]
  stxdw [r10-0x1e8], r1
  ldxdw r1, [r10-0x5b0]
  stxdw [r10-0x1f0], r1
  stxdw [r10-0x1f8], r9
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x200], r1
  ldxdw r1, [r10-0x5a0]
  stxdw [r10-0x208], r1
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0x198], r1
  stdw [r10-0x270], 0x0
  stdw [r10-0x278], 0x8
  stdw [r10-0x280], 0x0
  stdw [r10-0x190], 0x4
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r2, r10
  add64 r2, -0xd8
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x198
  stxdw [r10-0x1a8], r1
  stdw [r10-0x1a0], 0x1
  mov64 r1, r10
  add64 r1, -0x4e8
  mov64 r2, r10
  add64 r2, -0x280
  mov64 r3, r6
  call fn_b7360
  ldxdw r8, [r10-0x4e8]
  jne r8, 0x2, jmp_2ef40

jmp_2e9a8:
  ldxdw r2, [r7+0x1e8]
  mov64 r1, r10
  add64 r1, -0x268
  call fn_d5c0
  ldxdw r2, [r7+0x118]
  mov64 r8, r10
  add64 r8, -0x108
  mov64 r1, r8
  call fn_d5c0
  ldxdw r1, [r7+0x1d8]
  ldxdw r2, [r1+0x0]
  mov64 r6, r10
  add64 r6, -0xd8
  mov64 r1, r6
  call fn_d5c0
  ldxdw r1, [r7+0x1d0]
  ldxdw r2, [r1+0x58]
  mov64 r9, r10
  add64 r9, -0x198
  mov64 r1, r9
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r6
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r8
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0xd8], r1
  stdw [r10-0xd0], 0x4
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, r9
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x1a8], r1
  stdw [r10-0x1a0], 0x1
  stdw [r10-0x270], 0x0
  stdw [r10-0x278], 0x8
  stdw [r10-0x280], 0x0
  mov64 r1, r10
  add64 r1, -0x4f8
  mov64 r2, r10
  add64 r2, -0x280
  ldxdw r3, [r10-0x598]
  call fn_b8270
  ldxdw r8, [r10-0x4f8]
  jne r8, 0x2, jmp_2ef30
  ldxdw r1, [r7+0x1d8]
  ldxdw r2, [r1+0x0]
  mov64 r8, r10
  add64 r8, -0x198
  mov64 r1, r8
  stxdw [r10-0x588], r8
  call fn_d5c0
  ldxdw r2, [r7+0x118]
  mov64 r6, r10
  add64 r6, -0x280
  mov64 r1, r6
  call fn_d5c0
  ldxdw r2, [r7+0x1e8]
  mov64 r1, r10
  add64 r1, -0x340
  stxdw [r10-0xff8], r1
  mov64 r1, r10
  add64 r1, -0x370
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x508
  mov64 r5, r10
  mov64 r3, r8
  mov64 r4, r6
  call fn_2f4b0
  ldxdw r9, [r10-0x500]
  ldxdw r8, [r10-0x508]
  mov64 r1, r6
  call fn_9d08
  ldxdw r1, [r10-0x588]
  call fn_9d08
  jne r8, 0x2, jmp_2da40
  mov64 r2, r7
  add64 r2, 0xb8
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_d5c0
  ldxdw r1, [r10-0x590]
  ldxb r9, [r1+0x20]
  ldxdw r2, [r10-0x5a8]
  ldxdw r1, [r2+0x18]
  stxdw [r10-0x250], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x258], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x260], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x268], r1
  ldxb r1, [r7+0x66]
  ldxdw r2, [r10-0x298]
  stxdw [r10-0x280], r2
  ldxdw r2, [r10-0x290]
  stxdw [r10-0x278], r2
  ldxdw r2, [r10-0x288]
  stxdw [r10-0x270], r2
  ldxdw r2, [r10-0x598]
  stxdw [r10-0x248], r2
  stxb [r10-0x240], r1
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r10
  add64 r2, -0x280
  call fn_a0050
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x38], r2
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x50], r1
  ldxdw r1, [r10-0x70]
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r1
  ldxdw r2, [r10-0x68]
  add64 r1, r2
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0x60
  call fn_0000
  ldxdw r6, [r10-0x100]
  ldxdw r7, [r10-0xf8]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jgt r1, r2, jmp_2ef50
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_2ef58

jmp_2ee60:
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_2ef78

jmp_2ee78:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_2ef90

jmp_2ee98:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_2eeb0:
  ldxdw r9, [r10-0x460]
  ja jmp_2da40

jmp_2eec0:
  mov64 r1, r10
  add64 r1, -0x4d8
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r9, [r10-0x4d0]
  ldxdw r8, [r10-0x4d8]
  ja jmp_2da40

jmp_2eef8:
  mov64 r1, r10
  add64 r1, -0x4c8
  mov64 r2, 0x1
  call fn_5a078
  ldxdw r9, [r10-0x4c0]
  ldxdw r8, [r10-0x4c8]
  ja jmp_2da40

jmp_2ef30:
  ldxdw r9, [r10-0x4f0]
  ja jmp_2da40

jmp_2ef40:
  ldxdw r9, [r10-0x4e0]
  ja jmp_2da40

jmp_2ef50:
  jne r4, 0x0, jmp_2ee60

jmp_2ef58:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_2ee78

jmp_2ef78:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_2ee98

jmp_2ef90:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0xa8]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x190], r1
  stdw [r10-0x188], 0x1
  stdw [r10-0x198], 0x1
  mov64 r8, r10
  add64 r8, -0x280
  mov64 r5, r10
  add64 r5, -0x198
  mov64 r1, r8
  lddw r2, data_272e
  mov64 r3, r6
  mov64 r4, r7
  call fn_c96c0
  mov64 r6, r10
  add64 r6, -0x198
  mov64 r2, r10
  add64 r2, -0xa8
  mov64 r1, r6
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0xc8], r1
  lddw r1, str_17d4
  stxdw [r10-0xd8], r1
  stxb [r10-0x1], r9
  stdw [r10-0x10], 0x2
  stdw [r10-0xc0], 0x1
  stdw [r10-0xd0], 0x11
  mov64 r1, r10
  add64 r1, -0x18
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r5, r10
  mov64 r2, r8
  mov64 r3, r6
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x30]
  jne r2, r1, jmp_2f188
  mov64 r8, 0x2
  ja jmp_2f1c0

jmp_2f188:
  mov64 r1, r10
  add64 r1, -0x518
  mov64 r2, r10
  add64 r2, -0x30
  call fn_be7f0
  ldxdw r9, [r10-0x510]
  ldxdw r8, [r10-0x518]

jmp_2f1c0:
  mov64 r1, r10
  add64 r1, -0x198
  call fn_a258
  jne r8, 0x2, jmp_2da40
  mov64 r1, r10
  add64 r1, -0x370
  call fn_9d08
  mov64 r1, r10
  add64 r1, -0x3a0
  call fn_9d08
  mov64 r8, 0x2
  ja jmp_2cac8

jmp_2f220:
  ldxdw r9, [r10-0x4b0]
  ja jmp_2da40

jmp_2f230:
  call abort

jmp_2f238:
  mov64 r1, r6
  ldxdw r2, [r10-0x5c8]
  lddw r3, data_63e0
  call fn_cc630

jmp_2f260:
  mov64 r1, r6
  ldxdw r2, [r10-0x5f0]
  lddw r3, data_63f8
  call fn_cc630

jmp_2f288:
  mov64 r1, r6
  ldxdw r2, [r10-0x5d8]
  lddw r3, data_6410
  call fn_cc630

fn_2f2b0:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x48
  lddw r2, data_16cc
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  lddw r1, data_16cc
  call fn_5a268
  jne r0, 0x0, jmp_2f460
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  lddw r1, str_1a93
  stxdw [r10-0xe0], r1
  stw [r10-0x50], 0x1780
  stb [r10-0x98], 0x2
  stw [r10-0xd0], 0xb9
  stdw [r10-0xd8], 0x2e
  stdw [r10-0xe8], 0x0
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be760
  ldxdw r1, [r10-0xf8]
  ldxdw r2, [r10-0xf0]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  exit

jmp_2f460:
  mov64 r3, r10
  add64 r3, -0xe8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_2f4b0:
  mov64 r9, r4
  ldxdw r4, [r2+0x8]
  stxdw [r10-0x190], r4
  ldxdw r0, [r4+0x0]
  add64 r0, 0x1
  mov64 r4, 0x1
  jeq r0, 0x0, jmp_2f4f0
  mov64 r4, 0x0

jmp_2f4f0:
  ldxdw r7, [r2+0x0]
  stxdw [r10-0x1b0], r7
  ldxdw r6, [r10-0x190]
  stxdw [r6+0x0], r0
  jeq r4, 0x1, jmp_2ff08
  ldxdw r4, [r2+0x10]
  stxdw [r10-0x198], r4
  ldxdw r0, [r4+0x0]
  add64 r0, 0x1
  mov64 r4, 0x1
  jeq r0, 0x0, jmp_2f550
  mov64 r4, 0x0

jmp_2f550:
  ldxdw r7, [r5-0xff8]
  stxdw [r10-0x1b8], r7
  ldxdw r8, [r5-0x1000]
  ldxdw r5, [r10-0x198]
  stxdw [r5+0x0], r0
  jeq r4, 0x1, jmp_2ff08
  ldxdw r0, [r3+0x8]
  ldxdw r5, [r0+0x0]
  add64 r5, 0x1
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_2f5b0
  mov64 r4, 0x0

jmp_2f5b0:
  ldxdw r7, [r3+0x0]
  stxdw [r10-0x1e0], r7
  ldxb r7, [r2+0x2a]
  stxdw [r10-0x1d8], r7
  ldxb r7, [r2+0x29]
  stxdw [r10-0x1d0], r7
  ldxb r7, [r2+0x28]
  stxdw [r10-0x1c8], r7
  ldxdw r7, [r2+0x20]
  stxdw [r10-0x1c0], r7
  ldxdw r2, [r2+0x18]
  stxdw [r0+0x0], r5
  jeq r4, 0x1, jmp_2ff08
  stxdw [r10-0x1e8], r2
  ldxdw r7, [r3+0x10]
  ldxdw r4, [r7+0x0]
  add64 r4, 0x1
  mov64 r2, 0x1
  jeq r4, 0x0, jmp_2f650
  mov64 r2, 0x0

jmp_2f650:
  stxdw [r7+0x0], r4
  jeq r2, 0x1, jmp_2ff08
  stxdw [r10-0x1f0], r0
  ldxdw r0, [r8+0x8]
  ldxdw r4, [r0+0x0]
  add64 r4, 0x1
  mov64 r2, 0x1
  jeq r4, 0x0, jmp_2f698
  mov64 r2, 0x0

jmp_2f698:
  ldxdw r5, [r8+0x0]
  stxdw [r10-0x210], r5
  ldxb r5, [r3+0x2a]
  stxdw [r10-0x208], r5
  ldxb r5, [r3+0x29]
  stxdw [r10-0x200], r5
  ldxb r5, [r3+0x28]
  stxdw [r10-0x1f8], r5
  ldxdw r5, [r3+0x20]
  ldxdw r3, [r3+0x18]
  stxdw [r0+0x0], r4
  jeq r2, 0x1, jmp_2ff08
  ldxdw r2, [r8+0x10]
  stxdw [r10-0x1a0], r2
  ldxdw r4, [r2+0x0]
  add64 r4, 0x1
  mov64 r2, 0x1
  jeq r4, 0x0, jmp_2f730
  mov64 r2, 0x0

jmp_2f730:
  ldxdw r6, [r10-0x1a0]
  stxdw [r6+0x0], r4
  jeq r2, 0x1, jmp_2ff08
  stxdw [r10-0x218], r5
  ldxdw r5, [r9+0x8]
  ldxdw r2, [r5+0x0]
  add64 r2, 0x1
  mov64 r4, 0x1
  jeq r2, 0x0, jmp_2f780
  mov64 r4, 0x0

jmp_2f780:
  ldxdw r6, [r9+0x0]
  stxdw [r10-0x240], r6
  ldxb r6, [r8+0x2a]
  stxdw [r10-0x238], r6
  ldxb r6, [r8+0x29]
  stxdw [r10-0x230], r6
  ldxb r6, [r8+0x28]
  stxdw [r10-0x228], r6
  ldxdw r6, [r8+0x20]
  stxdw [r10-0x220], r6
  ldxdw r6, [r8+0x18]
  stxdw [r5+0x0], r2
  jeq r4, 0x1, jmp_2ff08
  stxdw [r10-0x1a8], r5
  ldxdw r2, [r9+0x10]
  ldxdw r5, [r2+0x0]
  add64 r5, 0x1
  mov64 r4, 0x1
  jeq r5, 0x0, jmp_2f820
  mov64 r4, 0x0

jmp_2f820:
  stxdw [r2+0x0], r5
  jeq r4, 0x1, jmp_2ff08
  stxdw [r10-0x260], r8
  stxdw [r10-0x250], r1
  ldxdw r1, [r9+0x18]
  ldxdw r4, [r9+0x20]
  ldxb r5, [r9+0x28]
  stxdw [r10-0x248], r7
  ldxb r7, [r9+0x29]
  mov64 r8, r6
  stxdw [r10-0x258], r9
  ldxb r6, [r9+0x2a]
  stxb [r10-0x66], r6
  stxb [r10-0x67], r7
  stxb [r10-0x68], r5
  stxdw [r10-0x70], r4
  stxdw [r10-0x78], r1
  stxdw [r10-0x80], r2
  ldxdw r1, [r10-0x1a8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x240]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x238]
  stxb [r10-0x96], r1
  ldxdw r1, [r10-0x230]
  stxb [r10-0x97], r1
  ldxdw r1, [r10-0x228]
  stxb [r10-0x98], r1
  ldxdw r1, [r10-0x220]
  stxdw [r10-0xa0], r1
  stxdw [r10-0xa8], r8
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0xb0], r1
  mov64 r6, r0
  stxdw [r10-0xb8], r0
  ldxdw r1, [r10-0x210]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x208]
  stxb [r10-0xc6], r1
  ldxdw r1, [r10-0x200]
  stxb [r10-0xc7], r1
  ldxdw r1, [r10-0x1f8]
  stxb [r10-0xc8], r1
  ldxdw r1, [r10-0x218]
  stxdw [r10-0xd0], r1
  stxdw [r10-0xd8], r3
  ldxdw r1, [r10-0x248]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x1e0]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x18], r1
  stdw [r10-0x10], 0x4
  mov64 r1, r10
  add64 r1, -0x18
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x1d8]
  stxb [r10-0xf6], r1
  ldxdw r1, [r10-0x1d0]
  stxb [r10-0xf7], r1
  ldxdw r1, [r10-0x1c8]
  stxb [r10-0xf8], r1
  ldxdw r1, [r10-0x1c0]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x1e8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0x120], r1
  stdw [r10-0x58], 0x1
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x8
  stdw [r10-0x138], 0x0
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0x138
  call fn_b89f8
  ldxdw r1, [r10-0x148]
  jne r1, 0x2, jmp_2fca8
  ldxdw r9, [r10-0x258]
  mov64 r1, r9
  call fn_c47d0
  mov64 r7, r0
  ldxdw r1, [r10-0x260]
  call fn_c47d0
  mov64 r1, r0
  add64 r1, r7
  mov64 r2, 0x1
  jlt r1, r0, jmp_2fb20
  mov64 r2, 0x0

jmp_2fb20:
  ldxdw r3, [r10-0x1a8]
  jne r2, 0x1, jmp_2fcb8
  stw [r10-0x4c], 0x10
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r7, r10
  add64 r7, -0x4c
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x1
  stdw [r10-0x30], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x30
  stxdw [r10-0x18], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x8], r1
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_2ff10
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xf0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0x108], r1
  stw [r10-0xa0], 0x1780
  stb [r10-0xe8], 0x2
  stdw [r10-0x138], 0x2
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r10
  add64 r2, -0x138
  call fn_be760
  ldxdw r2, [r10-0x180]
  ldxdw r1, [r10-0x188]
  ja jmp_2fee8

jmp_2fca8:
  ldxdw r2, [r10-0x140]
  ja jmp_2fee8

jmp_2fcb8:
  ldxdw r2, [r6+0x10]
  jeq r2, 0x0, jmp_2fd30
  add64 r6, 0x10
  stxdw [r10-0x128], r6
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r2, r10
  add64 r2, -0x138
  call fn_be7f0
  ldxdw r2, [r10-0x150]
  ldxdw r1, [r10-0x158]
  ja jmp_2fee8

jmp_2fd30:
  stdw [r6+0x10], -0x1
  ldxdw r2, [r6+0x18]
  stxdw [r2+0x0], r1
  ldxdw r1, [r6+0x10]
  add64 r1, 0x1
  stxdw [r6+0x10], r1
  ldxdw r1, [r3+0x10]
  jeq r1, 0x0, jmp_2fdd8
  add64 r3, 0x10
  stxdw [r10-0x128], r3
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r10
  add64 r2, -0x138
  call fn_be7f0
  ldxdw r2, [r10-0x160]
  ldxdw r1, [r10-0x168]
  ja jmp_2fee8

jmp_2fdd8:
  stdw [r3+0x10], -0x1
  ldxdw r1, [r3+0x18]
  stdw [r1+0x0], 0x0
  ldxdw r1, [r3+0x10]
  add64 r1, 0x1
  stxdw [r3+0x10], r1
  mov64 r1, r9
  lddw r2, data_0918
  call fn_c4cb8
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, 0x0
  call fn_c4980
  ldxdw r1, [r10-0x18]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_2fe88
  mov64 r1, 0x2
  ja jmp_2fee8

jmp_2fe88:
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x128], r2
  ldxdw r2, [r10-0x10]
  stxdw [r10-0x130], r2
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r10
  add64 r2, -0x138
  call fn_be7f0
  ldxdw r2, [r10-0x170]
  ldxdw r1, [r10-0x178]

jmp_2fee8:
  ldxdw r3, [r10-0x250]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  exit

jmp_2ff08:
  call abort

jmp_2ff10:
  mov64 r3, r10
  add64 r3, -0x138
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_2ff60:
  mov64 r7, r4
  mov64 r9, r3
  mov64 r3, r1
  ldxdw r8, [r5-0xfe0]
  ldxb r1, [r2+0x44]
  jne r1, 0x1, jmp_30190
  stxdw [r10-0x218], r3
  ldxdw r3, [r5-0xfd8]
  ldxdw r0, [r5-0xfe8]
  ldxdw r1, [r5-0xff0]
  stxdw [r10-0x220], r1
  ldxdw r6, [r5-0xff8]
  ldxdw r4, [r5-0x1000]
  ldxdw r1, [r2+0x5d]
  stxdw [r10-0x178], r1
  ldxdw r1, [r2+0x55]
  stxdw [r10-0x180], r1
  ldxdw r1, [r2+0x4d]
  stxdw [r10-0x188], r1
  ldxdw r1, [r2+0x45]
  stxdw [r10-0x190], r1
  ldxb r1, [r8+0x2a]
  jne r1, 0x2, jmp_30250
  stw [r10-0xc4], 0x34
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r7, r10
  add64 r7, -0xc4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x140], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x130], r1
  mov64 r2, r10
  add64 r2, -0x140
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_30e68
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  stw [r10-0x28], 0x17a4
  stb [r10-0x70], 0x2
  stdw [r10-0xc0], 0x2
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r8, [r10-0x208]
  ldxdw r6, [r10-0x210]
  ja jmp_30650

jmp_30190:
  mov64 r6, 0x2
  ldxb r1, [r8+0x2a]
  jeq r1, 0x2, jmp_30248
  ldxdw r1, [r8+0x8]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_301f8
  mov64 r1, r8
  add64 r1, 0x8
  mov64 r7, r3
  call fn_c25c0
  mov64 r3, r7

jmp_301f8:
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_30248
  add64 r8, 0x10
  mov64 r1, r8
  mov64 r7, r3
  call fn_c2610
  mov64 r3, r7

jmp_30248:
  ja jmp_30658

jmp_30250:
  stxdw [r10-0x228], r3
  ldxw r2, [r8+0x0]
  ldxdw r3, [r8+0x22]
  stxdw [r10-0x14e], r3
  ldxdw r3, [r8+0x1c]
  stxdw [r10-0x154], r3
  ldxdw r3, [r8+0x14]
  stxdw [r10-0x15c], r3
  ldxdw r3, [r8+0xc]
  stxdw [r10-0x164], r3
  ldxdw r3, [r8+0x4]
  stxdw [r10-0x16c], r3
  ldxb r3, [r8+0x2f]
  stxb [r10-0x141], r3
  ldxw r3, [r8+0x2b]
  stxw [r10-0x145], r3
  stxw [r10-0x170], r2
  stxb [r10-0x146], r1
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xb8], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xb0], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xa8], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xc0], r1
  ldxdw r2, [r10-0x190]
  jne r1, r2, jmp_30388
  ldxdw r1, [r10-0x188]
  ldxdw r2, [r10-0xb8]
  jne r2, r1, jmp_30388
  ldxdw r1, [r10-0x180]
  ldxdw r2, [r10-0xb0]
  jne r2, r1, jmp_30388
  mov64 r1, 0x0
  ldxdw r2, [r10-0x178]
  ldxdw r3, [r10-0xa8]
  jeq r3, r2, jmp_30390

jmp_30388:
  mov64 r1, 0x1

jmp_30390:
  jeq r1, 0x0, jmp_30530
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, data_165c
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x138], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x140], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x130], r1
  mov64 r2, r10
  add64 r2, -0x140
  lddw r1, data_165c
  call fn_5a268
  jne r0, 0x0, jmp_30e68
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  lddw r1, str_1a93
  stxdw [r10-0xb8], r1
  stw [r10-0x28], 0x17a4
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x148
  stdw [r10-0xb0], 0x2e
  stdw [r10-0xc0], 0x0
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r8, [r10-0x198]
  ldxdw r6, [r10-0x1a0]
  ja jmp_305c0

jmp_30530:
  stxdw [r10-0x238], r0
  stxdw [r10-0x230], r4
  mov64 r1, r10
  add64 r1, -0x170
  call fn_c4918
  jeq r0, 0x0, jmp_30570
  mov64 r6, 0x2

jmp_30568:
  ja jmp_305c0

jmp_30570:
  stxdw [r10-0x240], r6
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, r10
  add64 r2, -0x170
  call fn_4dad0
  ldxdw r8, [r10-0xb8]
  ldxdw r6, [r10-0xc0]
  ldxb r1, [r10-0x70]
  jne r1, 0x2, jmp_30670

jmp_305c0:
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  ldxdw r3, [r10-0x218]
  jne r2, 0x0, jmp_30610
  mov64 r1, r10
  add64 r1, -0x168
  call fn_c25c0
  ldxdw r3, [r10-0x218]

jmp_30610:
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_30658
  mov64 r1, r10
  add64 r1, -0x160
  call fn_c2610

jmp_30650:
  ldxdw r3, [r10-0x218]

jmp_30658:
  stxdw [r3+0x8], r8
  stxdw [r3+0x0], r6
  exit

jmp_30670:
  stxdw [r10-0x248], r1
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xb0
  mov64 r3, 0x40
  call fn_d23d0
  ldxw r1, [r10-0x6f]
  stxw [r10-0xef], r1
  ldxw r1, [r10-0x6c]
  stxw [r10-0xec], r1
  ldxdw r1, [r10-0x248]
  stxb [r10-0xf0], r1
  stxdw [r10-0x138], r8
  stxdw [r10-0x140], r6
  mov64 r6, 0x2
  jeq r7, 0x0, jmp_30568
  mov64 r3, r10
  add64 r3, -0x120
  mov64 r8, 0x0
  lsh64 r7, 0x3
  ldxdw r0, [r10-0x220]
  add64 r0, 0x10
  ldxdw r5, [r10-0x230]
  add64 r5, 0x60

jmp_30738:
  ldxdw r1, [r9+0x0]
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r10-0x120]
  jne r2, r4, jmp_307a8
  ldxdw r2, [r1+0x8]
  ldxdw r4, [r10-0x118]
  jne r2, r4, jmp_307a8
  ldxdw r2, [r1+0x10]
  ldxdw r4, [r10-0x110]
  jne r2, r4, jmp_307a8
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  ldxdw r4, [r10-0x108]
  jeq r1, r4, jmp_307b0

jmp_307a8:
  mov64 r2, 0x1

jmp_307b0:
  jeq r2, 0x0, jmp_307f0
  add64 r0, 0x18
  add64 r5, 0xd0
  add64 r8, 0x1
  add64 r9, 0x8
  add64 r7, -0x8
  jne r7, 0x0, jmp_30738
  ja jmp_30568

jmp_307f0:
  ldxdw r1, [r10-0x228]
  jeq r1, 0x0, jmp_309d8
  mov64 r6, r0
  stxdw [r10-0x230], r5
  ldxdw r1, [r1+0x0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xd0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xd8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xe0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, r10
  add64 r2, -0x190
  call fn_bc628
  ldxdw r1, [r10-0xc0]
  ldxdw r2, [r10-0xe8]
  jne r2, r1, jmp_308f0
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0xe0]
  jne r2, r1, jmp_308f0
  ldxdw r1, [r10-0xb0]
  ldxdw r2, [r10-0xd8]
  jne r2, r1, jmp_308f0
  mov64 r1, 0x0
  ldxdw r2, [r10-0xa8]
  ldxdw r3, [r10-0xd0]
  jeq r3, r2, jmp_308f8

jmp_308f0:
  mov64 r1, 0x1

jmp_308f8:
  ldxdw r2, [r10-0x238]
  jeq r1, 0x0, jmp_30a10
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_165c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_165c
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0xb8], r1
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x15b
  stdw [r10-0xb0], 0x2e
  stdw [r10-0xc0], 0x0
  stw [r10-0x28], 0x17a4
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r8, [r10-0x1a8]
  ldxdw r6, [r10-0x1b0]
  ja jmp_305c0

jmp_309d8:
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r2, 0x34
  call fn_5a078
  ldxdw r8, [r10-0x1f8]
  ldxdw r6, [r10-0x200]
  ja jmp_305c0

jmp_30a10:
  jge r8, r2, jmp_30ef8
  ldxdw r1, [r10-0x228]
  ldxdw r2, [r1+0x48]
  ldxdw r7, [r6-0x10]
  ldxdw r9, [r6-0x8]
  ldxw r6, [r6+0x0]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r9
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r5, r10
  mov64 r3, 0x0
  mov64 r4, r7
  call fn_4e128
  ldxw r1, [r10-0xc0]
  jeq r1, 0x0, jmp_30ac8
  ldxw r2, [r10-0xbc]
  mov64 r1, r10
  add64 r1, -0x1f0
  call fn_5a078
  ldxdw r8, [r10-0x1e8]
  ldxdw r6, [r10-0x1f0]
  ja jmp_305c0

jmp_30ac8:
  stxdw [r10-0x238], r9
  stxdw [r10-0x228], r7
  stxdw [r10-0x220], r8
  ldxdw r8, [r10-0xf8]
  ldxdw r1, [r10-0x100]
  mov64 r3, r1
  add64 r3, r8
  mov64 r2, 0x1
  jlt r3, r1, jmp_30b18
  mov64 r2, 0x0

jmp_30b18:
  stxdw [r10-0x248], r6
  ldxdw r9, [r10-0xb0]
  ldxdw r7, [r10-0xb8]
  and64 r2, 0x1
  jne r2, 0x0, jmp_30eb8
  add64 r8, r1

jmp_30b48:
  mov64 r3, 0x0
  mov64 r1, 0x1
  mov64 r2, 0x1
  jlt r8, r7, jmp_30b70
  mov64 r2, 0x0

jmp_30b70:
  add64 r9, r2
  neg64 r9
  mov64 r4, r8
  sub64 r4, r7
  mov64 r5, 0x1
  ldxdw r6, [r10-0x240]
  jle r4, r8, jmp_30c70
  jeq r9, 0x0, jmp_30c80

jmp_30bb0:
  ldxdw r7, [r10-0x220]
  jne r9, 0x0, jmp_30c98

jmp_30bc0:
  mov64 r2, 0x0
  jeq r5, 0x0, jmp_30cb0

jmp_30bd0:
  jne r5, 0x0, jmp_30be0

jmp_30bd8:
  mov64 r3, r9

jmp_30be0:
  ldxdw r1, [r10-0x248]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x238]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r5, r10
  ldxdw r4, [r10-0x228]
  call fn_4ef20
  ldxw r1, [r10-0xc0]
  jne r1, 0x1, jmp_30cc8
  ldxw r2, [r10-0xbc]
  mov64 r1, r10
  add64 r1, -0x1e0
  call fn_5a078
  ldxdw r8, [r10-0x1d8]
  ldxdw r6, [r10-0x1e0]
  ja jmp_305c0

jmp_30c70:
  mov64 r5, 0x0
  jne r9, 0x0, jmp_30bb0

jmp_30c80:
  mov64 r1, 0x0
  ldxdw r7, [r10-0x220]
  jeq r9, 0x0, jmp_30bc0

jmp_30c98:
  mov64 r5, r1
  mov64 r2, 0x0
  jne r5, 0x0, jmp_30bd0

jmp_30cb0:
  mov64 r2, r4
  jeq r5, 0x0, jmp_30bd8
  ja jmp_30be0

jmp_30cc8:
  jge r7, r6, jmp_30f18
  ldxdw r1, [r10-0xb0]
  ldxdw r2, [r10-0xb8]
  ldxdw r3, [r10-0x230]
  ldxdw r3, [r3+0x0]
  mov64 r4, 0x1
  jge r2, r3, jmp_30df8
  jne r1, 0x0, jmp_30e08

jmp_30d08:
  jeq r4, 0x0, jmp_30e18

jmp_30d10:
  jeq r4, 0x0, jmp_30e28

jmp_30d18:
  or64 r2, r1
  jeq r2, 0x0, jmp_30e40

jmp_30d28:
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_1658
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1658
  call fn_9838
  lddw r1, str_1a93
  stxdw [r10-0xb8], r1
  stb [r10-0x70], 0x2
  stw [r10-0xa8], 0x166
  stdw [r10-0xb0], 0x2e
  stdw [r10-0xc0], 0x0
  stw [r10-0x28], 0x17ba
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0xc0
  call fn_be760
  ldxdw r8, [r10-0x1c8]
  ldxdw r6, [r10-0x1d0]
  ja jmp_305c0

jmp_30df8:
  mov64 r4, 0x0
  jeq r1, 0x0, jmp_30d08

jmp_30e08:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_30d10

jmp_30e18:
  mov64 r1, 0x0
  jne r4, 0x0, jmp_30d18

jmp_30e28:
  mov64 r2, r3
  or64 r2, r1
  jne r2, 0x0, jmp_30d28

jmp_30e40:
  mov64 r1, r10
  add64 r1, -0x170
  call fn_9d08
  mov64 r6, 0x2
  ja jmp_30650

jmp_30e68:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_30eb8:
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x1b8]
  ldxdw r6, [r10-0x1c0]
  jne r6, 0x2, jmp_305c0
  ja jmp_30b48

jmp_30ef8:
  mov64 r1, r8
  lddw r3, data_6440
  call fn_cc630

jmp_30f18:
  mov64 r1, r7
  mov64 r2, r6
  lddw r3, data_6458
  call fn_cc630

fn_30f40:
  ldxdw r4, [r2+0x8]
  stxdw [r10-0x350], r4
  ldxdw r5, [r4+0x80]
  ldxdw r4, [r5+0x8]
  ldxdw r6, [r4+0x0]
  add64 r6, 0x1
  mov64 r0, 0x1
  jeq r6, 0x0, jmp_30f88
  mov64 r0, 0x0

jmp_30f88:
  ldxdw r7, [r5+0x0]
  stxdw [r4+0x0], r6
  jeq r0, 0x1, jmp_32800
  ldxdw r6, [r5+0x10]
  ldxdw r0, [r6+0x0]
  add64 r0, 0x1
  mov64 r8, 0x1
  jeq r0, 0x0, jmp_30fd0
  mov64 r8, 0x0

jmp_30fd0:
  stxdw [r6+0x0], r0
  jeq r8, 0x1, jmp_32800
  stxdw [r10-0x348], r1
  ldxdw r0, [r5+0x18]
  ldxdw r8, [r5+0x20]
  ldxb r9, [r5+0x28]
  mov64 r1, r7
  ldxb r7, [r5+0x29]
  ldxb r5, [r5+0x2a]
  stxb [r10-0x216], r5
  stxb [r10-0x217], r7
  mov64 r7, r1
  stxb [r10-0x218], r9
  stxdw [r10-0x220], r8
  stxdw [r10-0x230], r6
  stxdw [r10-0x238], r4
  stxdw [r10-0x240], r7
  stxdw [r10-0x228], r0
  ldxdw r4, [r0+0x0]
  lddw r5, 0x5f9ff80ea6de9204
  jne r4, r5, jmp_310e8
  ldxdw r4, [r0+0x8]
  lddw r5, 0x306871741f975c4a
  jne r4, r5, jmp_310e8
  ldxdw r4, [r0+0x10]
  lddw r5, -0x7ec0aad0512fff5d
  jne r4, r5, jmp_310e8
  mov64 r4, 0x0
  ldxdw r5, [r0+0x18]
  lddw r0, -0x4886a17a3ed6b36e
  jeq r5, r0, jmp_310f0

jmp_310e8:
  mov64 r4, 0x1

jmp_310f0:
  jeq r4, 0x0, jmp_31290
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x138], 0x0
  stdw [r10-0x140], 0x1
  stdw [r10-0x148], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x208], r1
  mov64 r1, r10
  add64 r1, -0x148
  stxdw [r10-0x210], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x200], r1
  mov64 r2, r10
  add64 r2, -0x210
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_32128
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stw [r10-0x8], 0x1771
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x26
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  mov64 r1, r10
  add64 r1, -0x250
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x248]
  ldxdw r6, [r10-0x250]
  ja jmp_316b8

jmp_31290:
  mov64 r8, r6
  add64 r8, 0x10
  ldxdw r4, [r6+0x10]
  lddw r5, 0x7fffffffffffffff
  jge r4, r5, jmp_314b0
  ldxdw r1, [r10-0x350]
  ldxb r9, [r1+0x66]
  add64 r4, 0x1
  stxdw [r6+0x10], r4
  ldxdw r4, [r6+0x20]
  jne r4, 0x42, jmp_31510
  ldxdw r1, [r6+0x18]
  ldxdw r4, [r1+0x0]
  lddw r5, -0x2f67bf153fa159ce
  jeq r4, r5, jmp_31758
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x138], 0x0
  stdw [r10-0x140], 0x1
  stdw [r10-0x148], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x208], r1
  mov64 r1, r10
  add64 r1, -0x148
  stxdw [r10-0x210], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x200], r1
  mov64 r2, r10
  add64 r2, -0x210
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_32128
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stw [r10-0x8], 0x1771
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x2a
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x278]
  ldxdw r6, [r10-0x280]
  ja jmp_316a0

jmp_314b0:
  stxdw [r10-0x90], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xa0], r1
  mov64 r1, r10
  add64 r1, -0x260
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be7f0
  ldxdw r9, [r10-0x258]
  ldxdw r6, [r10-0x260]
  ja jmp_316b8

jmp_31510:
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x138], 0x0
  stdw [r10-0x140], 0x1
  stdw [r10-0x148], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x208], r1
  mov64 r1, r10
  add64 r1, -0x148
  stxdw [r10-0x210], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x200], r1
  mov64 r2, r10
  add64 r2, -0x210
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_32128
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stw [r10-0x8], 0x1771
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x29
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  mov64 r1, r10
  add64 r1, -0x270
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x268]
  ldxdw r6, [r10-0x270]

jmp_316a0:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1

jmp_316b8:
  ldxdw r1, [r10-0x238]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_316f8
  mov64 r1, r10
  add64 r1, -0x238
  call fn_c25c0

jmp_316f8:
  ldxdw r1, [r10-0x230]
  ldxdw r2, [r1+0x0]
  add64 r2, -0x1
  stxdw [r1+0x0], r2
  jne r2, 0x0, jmp_31738
  mov64 r1, r10
  add64 r1, -0x230
  call fn_c2610

jmp_31738:
  ldxdw r1, [r10-0x348]
  stxdw [r1+0x8], r9
  stxdw [r1+0x0], r6
  exit

jmp_31758:
  ldxdw r6, [r1+0x19]
  ldxdw r0, [r1+0x11]
  ldxdw r4, [r1+0x9]
  ldxb r5, [r1+0x8]
  stxdw [r10-0x358], r5
  ldxdw r5, [r1+0x29]
  stxdw [r10-0xf0], r5
  ldxdw r5, [r1+0x21]
  stxdw [r10-0xf8], r5
  jne r4, r3, jmp_31a70
  mov64 r4, r9
  ldxb r5, [r1+0x31]
  jne r5, r4, jmp_31c08
  stxdw [r10-0x370], r6
  stxdw [r10-0x368], r0
  stxdw [r10-0x380], r2
  ldxdw r2, [r1+0x3a]
  stxdw [r10-0x378], r2
  ldxdw r6, [r1+0x32]
  stxb [r10-0xb8], r9
  mov64 r1, r10
  add64 r1, -0xd8
  stxdw [r10-0x80], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x90], r1
  lddw r1, str_13b8
  stxdw [r10-0xa0], r1
  stxdw [r10-0x360], r3
  stxdw [r10-0xd8], r3
  stdw [r10-0x78], 0x8
  stdw [r10-0x88], 0x1
  stdw [r10-0x98], 0x8
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r10
  add64 r2, -0xa0
  mov64 r3, 0x3
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x208]
  stxdw [r10-0x140], r1
  ldxdw r1, [r10-0x210]
  stxdw [r10-0x148], r1
  ldxb r1, [r10-0x1f0]
  ldxdw r2, [r7+0x18]
  stxdw [r10-0x88], r2
  ldxdw r2, [r7+0x10]
  stxdw [r10-0x90], r2
  ldxdw r2, [r7+0x8]
  stxdw [r10-0x98], r2
  ldxdw r2, [r7+0x0]
  stxdw [r10-0xa0], r2
  ldxdw r3, [r10-0x148]
  jne r2, r3, jmp_31990
  ldxdw r2, [r10-0x140]
  ldxdw r3, [r10-0x98]
  jne r3, r2, jmp_31990
  ldxdw r2, [r10-0x138]
  ldxdw r3, [r10-0x90]
  jne r3, r2, jmp_31990
  mov64 r2, 0x0
  ldxdw r3, [r10-0x130]
  ldxdw r4, [r10-0x88]
  jeq r4, r3, jmp_31998

jmp_31990:
  mov64 r2, 0x1

jmp_31998:
  jeq r2, 0x0, jmp_31cd8
  mov64 r1, r10
  add64 r1, -0x80
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x46
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  stw [r10-0x8], 0x1771
  mov64 r1, r10
  add64 r1, -0x2b0
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x2a8]
  ldxdw r6, [r10-0x2b0]
  ja jmp_316a0

jmp_31a70:
  mov64 r1, r10
  add64 r1, -0xd8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x138], 0x0
  stdw [r10-0x140], 0x1
  stdw [r10-0x148], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x208], r1
  mov64 r1, r10
  add64 r1, -0x148
  stxdw [r10-0x210], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x200], r1
  mov64 r2, r10
  add64 r2, -0x210
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_32128
  ldxdw r1, [r10-0x138]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stw [r10-0x8], 0x1771
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x38
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x288]
  ldxdw r6, [r10-0x290]
  ja jmp_316a0

jmp_31c08:
  mov64 r1, r10
  add64 r1, -0x80
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x39
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  stw [r10-0x8], 0x1771
  mov64 r1, r10
  add64 r1, -0x2a0
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x298]
  ldxdw r6, [r10-0x2a0]
  ja jmp_316a0

jmp_31cd8:
  ldxdw r3, [r10-0x358]
  mov64 r2, r3
  jne r2, r1, jmp_31f30
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x50], r1
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, 0x0
  mov64 r7, r3
  mov64 r3, 0x98
  call fn_d23f0
  stxb [r10-0x4], r7
  ldxdw r1, [r10-0x360]
  stxdw [r10-0x20], r1
  stxb [r10-0x3], r9
  ldxdw r1, [r10-0x370]
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x368]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x378]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x1a8]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x30], r1
  ldxdw r1, [r10-0x198]
  stxdw [r10-0x28], r1
  stxdw [r10-0x18], r6
  stb [r10-0x2], 0x0
  stw [r10-0x8], 0x0
  stdw [r10-0xa0], 0x0
  stdw [r10-0x98], 0x0
  stdw [r10-0x90], 0x0
  stdw [r10-0x88], 0x0
  stdw [r10-0x80], 0x0
  stdw [r10-0x78], 0x0
  stdw [r10-0x70], 0x0
  stdw [r10-0x68], 0x0
  stb [r10-0x1], 0x0
  ldxdw r1, [r10-0x350]
  ldxdw r9, [r1+0x38]
  mov64 r1, 0x1
  mov64 r2, r6
  add64 r2, r9
  jlt r2, r6, jmp_31e80
  mov64 r1, 0x0

jmp_31e80:
  and64 r1, 0x1
  jne r1, 0x0, jmp_32a30
  add64 r9, r6

jmp_31e98:
  mov64 r1, r10
  add64 r1, -0x210
  call fn_c2a08
  ldxdw r1, [r10-0x210]
  jne r1, 0x1, jmp_32000
  ldxdw r1, [r10-0x208]
  ldxdw r2, [r10-0x200]
  ldxdw r3, [r10-0x1f8]
  stxdw [r10-0x200], r3
  stxdw [r10-0x208], r2
  stxdw [r10-0x210], r1
  mov64 r1, r10
  add64 r1, -0x340
  mov64 r2, r10
  add64 r2, -0x210
  call fn_be7f0
  ldxdw r9, [r10-0x338]
  ldxdw r6, [r10-0x340]
  ja jmp_316b8

jmp_31f30:
  mov64 r1, r10
  add64 r1, -0x80
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x68
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1ac1
  stxdw [r10-0x98], r1
  stb [r10-0x50], 0x2
  stw [r10-0x88], 0x47
  stdw [r10-0x90], 0x36
  stdw [r10-0xa0], 0x0
  stw [r10-0x8], 0x1771
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, r10
  add64 r2, -0xa0
  call fn_be760
  ldxdw r9, [r10-0x2b8]
  ldxdw r6, [r10-0x2c0]
  ja jmp_316a0

jmp_32000:
  ldxdw r1, [r10-0x1e8]
  jgt r1, r9, jmp_32090
  ldxdw r1, [r10-0x380]
  ldxdw r4, [r1+0x10]
  ldxdw r1, [r1+0x18]
  ldxdw r3, [r10-0x350]
  ldxdw r2, [r3+0x78]
  ldxdw r2, [r2+0x28]
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x2e0
  mov64 r2, r10
  add64 r2, -0xa0
  mov64 r5, r10
  call fn_13550
  ldxdw r6, [r10-0x2e0]
  jne r6, 0x2, jmp_32808

jmp_32090:
  mov64 r1, r10
  add64 r1, -0x210
  call fn_c2af0
  ldxdw r1, [r10-0x208]
  stxdw [r10-0x178], r1
  ldxdw r1, [r10-0x200]
  stxdw [r10-0x170], r1
  ldxdw r1, [r10-0x1f8]
  stxdw [r10-0x168], r1
  ldxdw r1, [r10-0x210]
  jne r1, 0x1, jmp_32178
  mov64 r1, r10
  add64 r1, -0x330
  mov64 r2, r10
  add64 r2, -0x178
  call fn_be7f0
  ldxdw r9, [r10-0x328]
  ldxdw r6, [r10-0x330]
  ja jmp_316b8

jmp_32128:
  mov64 r3, r10
  add64 r3, -0xb8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_32178:
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x140], r1
  ldxdw r1, [r10-0x178]
  stxdw [r10-0x148], r1
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, 0xa8
  call fn_c2bb8
  mov64 r8, r0
  mov64 r1, r10
  add64 r1, -0x240
  call fn_c47d0
  jle r8, r0, jmp_32728
  ldxdw r6, [r10-0x350]
  ldxdw r1, [r6+0x70]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xe0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xe8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xf0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xf8], r1
  sub64 r8, r0
  ldxdw r1, [r10-0x240]
  ldxdw r2, [r1+0x0]
  stxdw [r10-0xd8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xd0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xc8], r2
  ldxdw r1, [r1+0x18]
  stxdw [r10-0xc0], r1
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0xf8
  mov64 r3, r10
  add64 r3, -0xd8
  mov64 r4, r8
  call fn_c9430
  ldxdw r2, [r6+0x70]
  ldxdw r6, [r2+0x8]
  ldxdw r1, [r6+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_32310
  mov64 r3, 0x0

jmp_32310:
  ldxdw r8, [r2+0x0]
  stxdw [r6+0x0], r1
  jeq r3, 0x1, jmp_32800
  ldxdw r4, [r2+0x10]
  ldxdw r1, [r4+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_32358
  mov64 r3, 0x0

jmp_32358:
  stxdw [r4+0x0], r1
  jeq r3, 0x1, jmp_32800
  ldxdw r9, [r10-0x238]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_32398
  mov64 r3, 0x0

jmp_32398:
  ldxb r5, [r2+0x2a]
  stxdw [r10-0x368], r5
  ldxb r5, [r2+0x29]
  stxdw [r10-0x360], r5
  ldxb r5, [r2+0x28]
  stxdw [r10-0x358], r5
  ldxdw r7, [r2+0x20]
  ldxdw r0, [r2+0x18]
  ldxdw r2, [r10-0x240]
  stxdw [r10-0x370], r2
  stxdw [r9+0x0], r1
  jeq r3, 0x1, jmp_32800
  ldxdw r5, [r10-0x230]
  ldxdw r1, [r5+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_32428
  mov64 r2, 0x0

jmp_32428:
  stxdw [r10-0x380], r7
  stxdw [r10-0x378], r0
  stxdw [r5+0x0], r1
  jeq r2, 0x1, jmp_32800
  ldxdw r1, [r10-0x350]
  ldxdw r0, [r1+0x88]
  ldxdw r7, [r0+0x8]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_32488
  mov64 r2, 0x0

jmp_32488:
  ldxdw r3, [r0+0x0]
  stxdw [r10-0x3a8], r3
  ldxb r3, [r10-0x216]
  stxdw [r10-0x3a0], r3
  ldxb r3, [r10-0x217]
  stxdw [r10-0x398], r3
  ldxb r3, [r10-0x218]
  stxdw [r10-0x390], r3
  ldxdw r3, [r10-0x220]
  stxdw [r10-0x388], r3
  ldxdw r3, [r10-0x228]
  stxdw [r10-0x350], r3
  stxdw [r7+0x0], r1
  jeq r2, 0x1, jmp_32800
  stxdw [r10-0x3b8], r9
  stxdw [r10-0x3b0], r4
  ldxdw r1, [r0+0x10]
  ldxdw r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_32538
  mov64 r3, 0x0

jmp_32538:
  mov64 r4, r8
  mov64 r9, r6
  stxdw [r1+0x0], r2
  jeq r3, 0x1, jmp_32800
  ldxdw r2, [r0+0x18]
  ldxdw r3, [r0+0x20]
  ldxb r6, [r0+0x28]
  ldxb r8, [r0+0x29]
  ldxb r0, [r0+0x2a]
  stxb [r10-0x186], r0
  stxb [r10-0x187], r8
  stxb [r10-0x188], r6
  stxdw [r10-0x190], r3
  stxdw [r10-0x198], r2
  stxdw [r10-0x1a0], r1
  stxdw [r10-0x1a8], r7
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r10-0x3a0]
  stxb [r10-0x1b6], r1
  ldxdw r1, [r10-0x398]
  stxb [r10-0x1b7], r1
  ldxdw r1, [r10-0x390]
  stxb [r10-0x1b8], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x1c0], r1
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x1c8], r1
  stxdw [r10-0x1d0], r5
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x1d8], r1
  ldxdw r1, [r10-0x370]
  stxdw [r10-0x1e0], r1
  ldxdw r1, [r10-0x368]
  stxb [r10-0x1e6], r1
  ldxdw r1, [r10-0x360]
  stxb [r10-0x1e7], r1
  ldxdw r1, [r10-0x358]
  stxb [r10-0x1e8], r1
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x1f0], r1
  ldxdw r1, [r10-0x378]
  stxdw [r10-0x1f8], r1
  ldxdw r1, [r10-0x3b0]
  stxdw [r10-0x200], r1
  stxdw [r10-0x208], r9
  stxdw [r10-0x210], r4
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0x148
  mov64 r3, r10
  add64 r3, -0x210
  mov64 r4, 0x3
  call fn_c2670
  ldxdw r1, [r10-0x160]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_32880
  mov64 r1, r10
  add64 r1, -0x210
  call fn_a2f0

jmp_32728:
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0x240
  mov64 r3, 0xa8
  call fn_c4b20
  ldxdw r1, [r10-0x148]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_32818
  ldxdw r1, [r10-0x230]
  mov64 r7, r1
  add64 r7, 0x10
  ldxdw r2, [r1+0x10]
  jeq r2, 0x0, jmp_32900
  stxdw [r10-0x200], r7
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0x210], r1
  mov64 r1, r10
  add64 r1, -0x310
  mov64 r2, r10
  add64 r2, -0x210
  call fn_be7f0
  ldxdw r9, [r10-0x308]
  ldxdw r6, [r10-0x310]
  ja jmp_316b8

jmp_32800:
  call abort

jmp_32808:
  ldxdw r9, [r10-0x2d8]
  ja jmp_316b8

jmp_32818:
  ldxdw r2, [r10-0x138]
  stxdw [r10-0x200], r2
  ldxdw r2, [r10-0x140]
  stxdw [r10-0x208], r2
  stxdw [r10-0x210], r1
  mov64 r1, r10
  add64 r1, -0x300
  mov64 r2, r10
  add64 r2, -0x210
  call fn_be7f0
  ldxdw r9, [r10-0x2f8]
  ldxdw r6, [r10-0x300]
  ja jmp_316b8

jmp_32880:
  ldxdw r2, [r10-0x150]
  stxdw [r10-0xa8], r2
  ldxdw r2, [r10-0x158]
  stxdw [r10-0xb0], r2
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x2f0
  mov64 r2, r10
  add64 r2, -0xb8
  call fn_be7f0
  ldxdw r9, [r10-0x2e8]
  ldxdw r6, [r10-0x2f0]
  mov64 r1, r10
  add64 r1, -0x210
  call fn_a2f0
  ja jmp_316b8

jmp_32900:
  stdw [r1+0x10], -0x1
  ldxdw r2, [r1+0x20]
  jlt r2, 0x8, jmp_32a70
  ldxdw r2, [r1+0x18]
  lddw r3, -0x2f67bf153fa159ce
  stxdw [r2+0x0], r3
  ldxdw r2, [r1+0x20]
  jlt r2, 0x8, jmp_32a90
  ldxdw r1, [r1+0x18]
  add64 r2, -0x8
  stxdw [r10-0x208], r2
  add64 r1, 0x8
  stxdw [r10-0x210], r1
  mov64 r1, r10
  add64 r1, -0xa0
  mov64 r2, r10
  add64 r2, -0x210
  call fn_57a68
  jeq r0, 0x0, jmp_329f0
  mov64 r1, r10
  add64 r1, -0x320
  mov64 r2, r0
  call fn_be898
  ldxdw r9, [r10-0x318]
  ldxdw r6, [r10-0x320]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  stxdw [r7+0x0], r1
  ja jmp_316b8

jmp_329f0:
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  stxdw [r7+0x0], r1
  mov64 r1, r10
  add64 r1, -0x240
  call fn_9d08
  mov64 r6, 0x2
  ja jmp_31738

jmp_32a30:
  mov64 r1, r10
  add64 r1, -0x2d0
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r9, [r10-0x2c8]
  ldxdw r6, [r10-0x2d0]
  jne r6, 0x2, jmp_316b8
  ja jmp_31e98

jmp_32a70:
  mov64 r1, 0x8
  lddw r3, data_6470
  call fn_cf460

jmp_32a90:
  mov64 r1, 0x8
  lddw r3, data_6488
  call fn_cf458

fn_32ab0:
  mov64 r8, r2
  mov64 r9, r1
  ldxdw r7, [r3+0x10]
  jeq r7, 0x0, jmp_32b90
  ldxdw r6, [r3+0x8]
  ldxdw r1, [r3+0x0]
  stxdw [r10-0x4a0], r1
  mov64 r1, r10
  add64 r1, -0x258
  call fn_c2a08
  mov64 r1, r10
  add64 r1, -0x250
  ldxdw r2, [r10-0x258]
  jne r2, 0x1, jmp_32d28
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x160], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x168], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x170], r1
  mov64 r1, r10
  add64 r1, -0x488
  mov64 r2, r10
  add64 r2, -0x170
  call fn_be7f0
  ldxdw r8, [r10-0x480]
  ldxdw r6, [r10-0x488]
  ja jmp_33770

jmp_32b90:
  mov64 r1, r10
  add64 r1, -0x2e8
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_33cb0
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x2e8]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x2e0]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x2d8]
  stxdw [r10-0x228], r1
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1771
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x17
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x498
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x490]
  ldxdw r6, [r10-0x498]
  ja jmp_33770

jmp_32d28:
  stxdw [r10-0x4a8], r9
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x2e8], r1
  stxdw [r10-0x2e0], r5
  stxdw [r10-0x2d8], r4
  stxdw [r10-0x158], r3
  stxdw [r10-0x2d0], r3
  stxdw [r10-0x150], r2
  stxdw [r10-0x2c8], r2
  ldxdw r9, [r8+0x8]
  ldxdw r1, [r9+0x188]
  ldxdw r1, [r1+0x58]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x158], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x160], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x168], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x170], r1
  ldxdw r1, [r9+0x198]
  ldxdw r1, [r1+0x58]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x240], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x248], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x250], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x258], r1
  ldxdw r2, [r10-0x170]
  jne r2, r1, jmp_32ea8
  ldxdw r1, [r10-0x250]
  ldxdw r2, [r10-0x168]
  jne r2, r1, jmp_32ea8
  ldxdw r1, [r10-0x248]
  ldxdw r2, [r10-0x160]
  jne r2, r1, jmp_32ea8
  mov64 r1, 0x0
  ldxdw r2, [r10-0x240]
  ldxdw r3, [r10-0x158]
  jeq r3, r2, jmp_32eb0

jmp_32ea8:
  mov64 r1, 0x1

jmp_32eb0:
  jeq r1, 0x0, jmp_332a8
  stxdw [r10-0x4b0], r6
  ldxb r1, [r9+0x67]
  jge r1, 0x5, jmp_33d00
  jeq r1, 0x0, jmp_33110
  ldxdw r2, [r9+0x190]
  ldxb r3, [r2+0x10f]
  mov64 r4, 0x40

jmp_32ef0:
  mov64 r5, r9
  add64 r5, r4
  ldxb r5, [r5+0x0]
  mov64 r0, r3
  jeq r5, r0, jmp_32f38
  mov64 r6, r4
  add64 r6, -0x3f
  add64 r4, 0x1
  jlt r6, r1, jmp_32ef0

jmp_32f38:
  jne r5, r0, jmp_33110
  stxdw [r10-0x4b8], r8
  mov64 r4, 0x40
  ldxdw r3, [r9+0x1a0]
  ldxb r5, [r3+0x10f]

jmp_32f60:
  mov64 r0, r9
  add64 r0, r4
  ldxb r0, [r0+0x0]
  mov64 r6, r5
  jeq r0, r6, jmp_32fa8
  mov64 r8, r4
  add64 r8, -0x3f
  add64 r4, 0x1
  jlt r8, r1, jmp_32f60

jmp_32fa8:
  jne r0, r6, jmp_33440
  ldxdw r4, [r9+0x180]
  ldxw r1, [r4+0x16c]
  and64 r1, 0x8
  jne r1, 0x0, jmp_335d8
  ldxb r1, [r2+0x112]
  jne r1, 0x0, jmp_32ff0
  ldxb r1, [r3+0x112]
  jne r1, 0x1, jmp_33788

jmp_32ff0:
  ldxdw r1, [r9+0x70]
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_33040
  mov64 r1, r9
  add64 r1, 0x70
  mov64 r2, 0x3
  mov64 r3, r4
  call fn_15950
  jne r0, 0x0, jmp_337f0

jmp_33040:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_1648
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1648
  call fn_9838
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x40
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1786
  mov64 r1, r10
  add64 r1, -0x458
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x450]
  ldxdw r6, [r10-0x458]
  ja jmp_33768

jmp_33110:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_33cb0
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1772
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x29
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x468
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x460]
  ldxdw r6, [r10-0x468]
  ja jmp_33768

jmp_332a8:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16d8
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16d8
  call fn_5a268
  jne r0, 0x0, jmp_33cb0
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1771
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x21
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x478
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x470]
  ldxdw r6, [r10-0x478]
  ja jmp_33768

jmp_33440:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_16c0
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_16c0
  call fn_5a268
  jne r0, 0x0, jmp_33cb0
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x1772
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x2d
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x2f8
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x2f0]
  ldxdw r6, [r10-0x2f8]
  ja jmp_33768

jmp_335d8:
  mov64 r1, r10
  add64 r1, -0x28
  lddw r2, data_164c
  call fn_594a8
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x168], r1
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x170], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x160], r1
  mov64 r2, r10
  add64 r2, -0x170
  lddw r1, data_164c
  call fn_5a268
  jne r0, 0x0, jmp_33cb0
  ldxdw r1, [r10-0x280]
  stxdw [r10-0x210], r1
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x220], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x238], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x230], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x228], r1
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stw [r10-0x1c0], 0x177e
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x35
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x308
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x300]
  ldxdw r6, [r10-0x308]

jmp_33768:
  ldxdw r9, [r10-0x4a8]

jmp_33770:
  stxdw [r9+0x8], r8
  stxdw [r9+0x0], r6
  exit

jmp_33788:
  ldxdw r1, [r9+0x70]
  mov64 r3, 0x0
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_337c0
  mov64 r3, r9
  add64 r3, 0x70

jmp_337c0:
  mov64 r1, r10
  add64 r1, -0x318
  mov64 r2, 0x3
  call fn_4d818
  ldxdw r6, [r10-0x318]
  jne r6, 0x2, jmp_33bd0

jmp_337f0:
  ldxdw r2, [r9+0x190]
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x258
  call fn_10db0
  ldxdw r8, [r10-0x250]
  ldxdw r6, [r10-0x258]
  jne r6, 0x2, jmp_33768
  stxdw [r10-0x4c0], r8
  jeq r8, 0x0, jmp_34d58
  ldxdw r2, [r9+0x1a0]
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x258
  call fn_10db0
  ldxdw r8, [r10-0x250]
  ldxdw r6, [r10-0x258]
  jne r6, 0x2, jmp_33768
  jeq r8, 0x0, jmp_34d70
  ldxdw r0, [r10-0x4c0]
  add64 r0, -0x1
  add64 r8, r0
  add64 r8, -0x1
  mov64 r1, 0x1
  jlt r8, r0, jmp_338c0
  mov64 r1, 0x0

jmp_338c0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_34d88
  ldxdw r1, [r10-0x4b8]
  ldxdw r1, [r1+0x18]
  jne r1, r8, jmp_33be0
  stxdw [r10-0x4c8], r1
  jlt r1, r0, jmp_34bf8
  mov64 r3, r9
  add64 r3, 0xb8
  ldxdw r1, [r10-0x4b8]
  ldxdw r4, [r1+0x10]
  ldxdw r2, [r9+0x190]
  mov64 r1, r10
  add64 r1, -0x2e8
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r0
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r5, r10
  stxdw [r10-0x4c0], r0
  stxdw [r10-0x4d0], r4
  call fn_11668
  ldxdw r8, [r10-0x250]
  ldxdw r6, [r10-0x258]
  ldxh r1, [r10-0x244]
  jeq r1, 0x2, jmp_33768
  mov64 r3, r9
  add64 r3, 0xe8
  ldxh r2, [r10-0x242]
  stxh [r10-0x2aa], r2
  stxh [r10-0x2ac], r1
  ldxw r1, [r10-0x248]
  stxw [r10-0x2b0], r1
  stxdw [r10-0x2b8], r8
  stxdw [r10-0x2c0], r6
  ldxdw r2, [r9+0x1a0]
  mov64 r1, r10
  add64 r1, -0x2e8
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x4c8]
  ldxdw r5, [r10-0x4c0]
  sub64 r1, r5
  stxdw [r10-0x1000], r1
  mul64 r5, 0x30
  ldxdw r4, [r10-0x4d0]
  add64 r4, r5
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r5, r10
  call fn_11668
  ldxdw r8, [r10-0x250]
  ldxdw r6, [r10-0x258]
  ldxh r1, [r10-0x244]
  jeq r1, 0x2, jmp_33768
  ldxh r2, [r10-0x242]
  stxh [r10-0x292], r2
  stxh [r10-0x294], r1
  ldxw r1, [r10-0x248]
  stxw [r10-0x298], r1
  stxdw [r10-0x2a0], r8
  stxdw [r10-0x2a8], r6
  ldxdw r1, [r9+0x1b0]
  ldxdw r8, [r1+0x48]
  ldxdw r1, [r9+0x180]
  stxdw [r10-0x4c0], r1
  ldxdw r6, [r9+0x198]
  ldxdw r1, [r9+0x188]
  ldxb r4, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, r10
  add64 r2, -0x2c0
  mov64 r3, r7
  call fn_3c7b8
  ldxw r1, [r10-0x258]
  jne r1, 0x0, jmp_33b98
  ldxdw r1, [r10-0x248]
  stxdw [r10-0x4c8], r1
  ldxdw r1, [r10-0x250]
  stxdw [r10-0x4d0], r1
  ldxb r4, [r6+0x30]
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, r10
  add64 r2, -0x2a8
  mov64 r3, 0x1
  call fn_3c7b8
  ldxw r1, [r10-0x258]
  jeq r1, 0x0, jmp_33d20

jmp_33b98:
  ldxw r2, [r10-0x254]

jmp_33ba0:
  mov64 r1, r10
  add64 r1, -0x448
  call fn_5a078
  ldxdw r8, [r10-0x440]
  ldxdw r6, [r10-0x448]
  ja jmp_33768

jmp_33bd0:
  ldxdw r8, [r10-0x310]
  ja jmp_33768

jmp_33be0:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_16d8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_16d8
  call fn_9838
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x57
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1771
  mov64 r1, r10
  add64 r1, -0x328
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x320]
  ldxdw r6, [r10-0x328]
  ja jmp_33768

jmp_33cb0:
  mov64 r3, r10
  add64 r3, -0x98
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_33d00:
  mov64 r2, 0x4
  lddw r3, data_6110
  call fn_cf460

jmp_33d20:
  ldxdw r5, [r10-0x248]
  ldxdw r4, [r10-0x250]
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_34d48
  mov64 r1, r10
  add64 r1, -0x338
  ldxdw r2, [r10-0x4d0]
  ldxdw r3, [r10-0x4c8]
  call fn_d45f0
  mov64 r1, r10
  add64 r1, -0x358
  ldxdw r2, [r10-0x330]
  stxdw [r10-0x4c8], r2
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x348
  ldxdw r2, [r10-0x338]
  mov64 r6, r2
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  mov64 r2, 0x1
  ldxdw r3, [r10-0x350]
  mov64 r1, 0x1
  jne r3, 0x0, jmp_33e18
  mov64 r1, 0x0

jmp_33e18:
  ldxdw r4, [r10-0x358]
  ldxdw r5, [r10-0x340]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_33e48
  mov64 r2, 0x0

jmp_33e48:
  or64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_33e98

jmp_33e60:
  mov64 r1, r10
  add64 r1, -0x438
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x430]
  ldxdw r6, [r10-0x438]
  ja jmp_33768

jmp_33e98:
  mov64 r2, r6
  mov64 r4, r2
  add64 r4, r8
  mov64 r1, 0x1
  jlt r4, r2, jmp_33ec8
  mov64 r1, 0x0

jmp_33ec8:
  ldxdw r5, [r10-0x4c8]
  add64 r5, r1
  mov64 r1, r4
  or64 r1, r5
  jeq r1, 0x0, jmp_33e60
  ldxdw r2, [r10-0x348]
  mov64 r1, r10
  add64 r1, -0x368
  call fn_d45f0
  mov64 r2, 0x1
  ldxdw r1, [r10-0x368]
  jge r1, 0x2711, jmp_33f80
  ldxdw r3, [r10-0x360]
  jne r3, 0x0, jmp_33f98

jmp_33f38:
  and64 r2, 0x1
  jne r2, 0x0, jmp_33fb0

jmp_33f48:
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x420]
  ldxdw r6, [r10-0x428]
  ja jmp_33768

jmp_33f80:
  mov64 r2, 0x0
  ldxdw r3, [r10-0x360]
  jeq r3, 0x0, jmp_33f38

jmp_33f98:
  mov64 r2, 0x0
  and64 r2, 0x1
  jeq r2, 0x0, jmp_33f48

jmp_33fb0:
  ldxdw r2, [r10-0x4c0]
  ldxh r8, [r2+0x170]
  jlt r8, 0x2711, jmp_34000
  mov64 r1, r10
  add64 r1, -0x418
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r8, [r10-0x410]
  ldxdw r6, [r10-0x418]
  ja jmp_33768

jmp_34000:
  mov64 r2, 0x1
  stxdw [r10-0x4c0], r2
  jgt r1, 0x2710, jmp_34020
  mov64 r2, 0x0

jmp_34020:
  add64 r3, r2
  neg64 r3
  mov64 r2, 0x2710
  sub64 r2, r1
  mov64 r1, r10
  add64 r1, -0x378
  mov64 r4, r6
  ldxdw r5, [r10-0x4c8]
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x388
  ldxdw r2, [r10-0x378]
  ldxdw r3, [r10-0x370]
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d45f0
  mov64 r4, 0x2710
  sub64 r4, r8
  and64 r4, 0xffff
  mov64 r1, r10
  add64 r1, -0x398
  ldxdw r2, [r10-0x388]
  ldxdw r3, [r10-0x380]
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x3a8
  ldxdw r8, [r10-0x398]
  ldxdw r6, [r10-0x390]
  mov64 r2, r8
  mov64 r3, r6
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d45f0
  mov64 r1, 0x1
  jle r8, 0x270f, jmp_34230
  jeq r6, 0x0, jmp_34240

jmp_34148:
  jne r6, 0x0, jmp_34258

jmp_34150:
  and64 r1, 0x1
  jne r1, 0x0, jmp_34270

jmp_34160:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_1650
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1650
  call fn_9838
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x90
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1775
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x400]
  ldxdw r6, [r10-0x408]
  ja jmp_33768

jmp_34230:
  mov64 r1, 0x0
  jne r6, 0x0, jmp_34148

jmp_34240:
  mov64 r2, 0x0
  stxdw [r10-0x4c0], r2
  jeq r6, 0x0, jmp_34150

jmp_34258:
  ldxdw r1, [r10-0x4c0]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_34160

jmp_34270:
  ldxdw r1, [r10-0x3a0]
  ldxdw r8, [r10-0x3a8]
  ldxdw r2, [r9+0x1b0]
  ldxdw r4, [r2+0x48]
  mov64 r3, 0x1
  mov64 r2, 0x1
  jgt r8, r4, jmp_34398
  jne r1, 0x0, jmp_343a8

jmp_342b0:
  jne r1, 0x0, jmp_343b8

jmp_342b8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_343d0

jmp_342c8:
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_1650
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1650
  call fn_9838
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x92
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1775
  mov64 r1, r10
  add64 r1, -0x3f8
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x3f0]
  ldxdw r6, [r10-0x3f8]
  ja jmp_33768

jmp_34398:
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_342b0

jmp_343a8:
  mov64 r3, 0x0
  jeq r1, 0x0, jmp_342b8

jmp_343b8:
  mov64 r2, r3
  and64 r2, 0x1
  jeq r2, 0x0, jmp_342c8

jmp_343d0:
  ldxdw r1, [r10-0x4a0]
  jeq r1, 0x0, jmp_344c0
  ldxdw r1, [r10-0x4b0]
  jle r1, r8, jmp_344c0
  mov64 r1, r10
  add64 r1, -0x238
  lddw r2, data_1704
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x220
  lddw r2, data_1704
  call fn_9838
  lddw r1, str_1af7
  stxdw [r10-0x250], r1
  stb [r10-0x208], 0x2
  stw [r10-0x240], 0x9c
  stdw [r10-0x248], 0x2a
  stdw [r10-0x258], 0x0
  stw [r10-0x1c0], 0x1793
  mov64 r1, r10
  add64 r1, -0x3e8
  mov64 r2, r10
  add64 r2, -0x258
  call fn_be760
  ldxdw r8, [r10-0x3e0]
  ldxdw r6, [r10-0x3e8]
  ja jmp_33768

jmp_344c0:
  ldxb r1, [r9+0x66]
  stxb [r10-0x25a], r1
  ldxb r1, [r9+0x65]
  mov64 r2, r10
  add64 r2, -0x259
  stxdw [r10-0x270], r2
  mov64 r2, r10
  add64 r2, -0x25a
  stxdw [r10-0x280], r2
  lddw r2, str_1775
  stxdw [r10-0x290], r2
  stxb [r10-0x259], r1
  stdw [r10-0x268], 0x1
  stdw [r10-0x278], 0x1
  stdw [r10-0x288], 0xe
  ldxdw r2, [r9+0x1c8]
  mov64 r1, r10
  add64 r1, -0x240
  call fn_d5c0
  ldxdw r1, [r9+0x1b8]
  ldxdw r2, [r1+0x0]
  mov64 r6, r10
  add64 r6, -0x170
  mov64 r1, r6
  call fn_d5c0
  ldxdw r1, [r9+0x1a8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x140
  call fn_d5c0
  ldxdw r2, [r9+0x178]
  mov64 r1, r10
  add64 r1, -0x110
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r6
  mov64 r3, 0x90
  call fn_d23d0
  stdw [r10-0x178], 0x0
  stdw [r10-0x180], 0x8
  stdw [r10-0x248], 0x0
  stdw [r10-0x250], 0x8
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x3b8
  mov64 r2, r10
  add64 r2, -0x258
  mov64 r3, r7
  call fn_b7360
  ldxdw r6, [r10-0x3b8]
  jne r6, 0x2, jmp_34c58
  ldxdw r2, [r9+0x1c8]
  mov64 r1, r10
  add64 r1, -0x240
  call fn_d5c0
  ldxdw r1, [r9+0x1b0]
  ldxdw r2, [r1+0x0]
  mov64 r6, r10
  add64 r6, -0x170
  mov64 r1, r6
  call fn_d5c0
  ldxdw r1, [r9+0x1c0]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x140
  call fn_d5c0
  ldxdw r2, [r9+0x68]
  mov64 r1, r10
  add64 r1, -0x110
  call fn_d5c0
  mov64 r1, r10
  add64 r1, -0x290
  stxdw [r10-0x28], r1
  stdw [r10-0x20], 0x3
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r6
  mov64 r3, 0x90
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x180], r1
  stdw [r10-0x178], 0x1
  stdw [r10-0x248], 0x0
  stdw [r10-0x250], 0x8
  stdw [r10-0x258], 0x0
  mov64 r1, r10
  add64 r1, -0x3c8
  mov64 r2, r10
  add64 r2, -0x258
  mov64 r3, r8
  call fn_b7360
  ldxdw r6, [r10-0x3c8]
  jne r6, 0x2, jmp_34c68
  mov64 r2, r9
  add64 r2, 0x118
  mov64 r1, r10
  add64 r1, -0xe0
  call fn_d5c0
  ldxdw r1, [r10-0x4b8]
  ldxb r6, [r1+0x26]
  ldxdw r1, [r9+0x178]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x240], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x248], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x250], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x258], r1
  ldxdw r1, [r9+0x68]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x228], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x230], r2
  ldxdw r2, [r1+0x0]
  stxdw [r10-0x238], r2
  ldxdw r1, [r1+0x18]
  stxdw [r10-0x218], r7
  stxdw [r10-0x210], r8
  stxdw [r10-0x220], r1
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0x258
  call fn_a0de8
  lddw r1, data_13d8
  lddw r2, data_13d8
  add64 r2, 0x8
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xb0]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x78], r1
  stxdw [r10-0x80], r1
  ldxdw r2, [r10-0xa0]
  add64 r1, r2
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r2, r10
  add64 r2, -0x80
  call fn_0000
  ldxdw r7, [r10-0x90]
  ldxdw r8, [r10-0x88]
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0x22
  jle r1, r2, jmp_34c78
  jeq r4, 0x0, jmp_34c88

jmp_349d0:
  lddw r1, 0x300007fde
  jne r2, 0x0, jmp_34ca8

jmp_349e8:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_34cc8

jmp_34a00:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r10-0xe0]
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x1
  stxdw [r10-0x168], r1
  stdw [r10-0x160], 0x1
  stdw [r10-0x170], 0x1
  mov64 r9, r10
  add64 r9, -0x258
  mov64 r5, r10
  add64 r5, -0x170
  mov64 r1, r9
  lddw r2, data_272e
  mov64 r3, r7
  mov64 r4, r8
  call fn_c96c0
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r2, r10
  add64 r2, -0xe0
  mov64 r1, r7
  mov64 r3, 0x30
  call fn_d23d0
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x38], r1
  mov64 r1, r10
  add64 r1, -0x1
  stxdw [r10-0x18], r1
  lddw r1, str_17d4
  stxdw [r10-0x28], r1
  stxb [r10-0x1], r6
  stdw [r10-0x30], 0x2
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x11
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x1
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r7
  mov64 r4, 0x1
  call fn_c2698
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x50]
  jne r2, r1, jmp_34ce0
  mov64 r6, 0x2
  ja jmp_34d18

jmp_34bf8:
  lddw r1, data_5db8
  stxdw [r10-0x258], r1
  stdw [r10-0x238], 0x0
  stdw [r10-0x250], 0x1
  stdw [r10-0x240], 0x0
  stdw [r10-0x248], 0x8
  mov64 r1, r10
  add64 r1, -0x258
  lddw r2, data_64e8
  call fn_cc598

jmp_34c58:
  ldxdw r8, [r10-0x3b0]
  ja jmp_33768

jmp_34c68:
  ldxdw r8, [r10-0x3c0]
  ja jmp_33768

jmp_34c78:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_349d0

jmp_34c88:
  mov64 r3, r1
  lddw r1, 0x300007fde
  jeq r2, 0x0, jmp_349e8

jmp_34ca8:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_34a00

jmp_34cc8:
  mov64 r1, 0x1
  mov64 r2, 0x22
  call fn_cb058

jmp_34ce0:
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, r10
  add64 r2, -0x50
  call fn_be7f0
  ldxdw r8, [r10-0x3d0]
  ldxdw r6, [r10-0x3d8]

jmp_34d18:
  mov64 r1, r10
  add64 r1, -0x170
  call fn_a258
  jne r6, 0x2, jmp_33768
  mov64 r6, 0x2
  ja jmp_33768

jmp_34d48:
  mov64 r2, 0x10
  ja jmp_33ba0

jmp_34d58:
  lddw r1, data_64a0
  call fn_d0810

jmp_34d70:
  lddw r1, data_64b8
  call fn_d0810

jmp_34d88:
  lddw r1, data_64d0
  call fn_d07b8

fn_34da0:
  mov64 r6, r1
  and64 r3, 0xff
  jeq r3, 0x2, jmp_35648
  jeq r3, 0x4, jmp_35208
  jne r3, 0x5, jmp_357f8
  ldxb r1, [r2+0x20]
  jeq r1, 0x0, jmp_35ae8
  ldxdw r3, [r2+0x8]
  ldxdw r1, [r3+0x28]
  jeq r1, 0x0, jmp_36060
  stxdw [r10-0x390], r4
  mov64 r9, r2
  ldxb r2, [r2+0x21]
  stxdw [r10-0x3b0], r2
  ldxdw r2, [r5+0x10]
  stxdw [r10-0x3a0], r2
  ldxdw r2, [r5+0x8]
  stxdw [r10-0x3a8], r2
  ldxdw r1, [r1+0x0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xd0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xd8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xe0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xe8], r1
  stxdw [r10-0x398], r3
  ldxdw r2, [r3+0x8]
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_10db0
  ldxdw r7, [r10-0xa0]
  ldxdw r8, [r10-0xa8]
  jne r8, 0x2, jmp_38370
  jge r7, 0x4, jmp_37ec0
  ldxdw r3, [r10-0x390]
  mov64 r2, r9
  jeq r7, 0x0, jmp_36558
  mul64 r7, 0x4c
  ldxdw r1, [r10-0x398]
  ldxdw r1, [r1+0x8]
  mov64 r4, 0x0
  ja jmp_34f20

jmp_34f10:
  add64 r4, 0x4c
  jeq r7, r4, jmp_36558

jmp_34f20:
  mov64 r5, r1
  add64 r5, r4
  ldxb r0, [r5+0x6f]
  jne r0, 0x5, jmp_34f10
  ldxdw r0, [r5+0x28]
  ldxdw r8, [r10-0xe8]
  jne r0, r8, jmp_34fa8
  ldxdw r0, [r5+0x30]
  ldxdw r8, [r10-0xe0]
  jne r0, r8, jmp_34fa8
  ldxdw r0, [r5+0x38]
  ldxdw r8, [r10-0xd8]
  jne r0, r8, jmp_34fa8
  mov64 r0, 0x0
  ldxdw r5, [r5+0x40]
  ldxdw r8, [r10-0xd0]
  jeq r5, r8, jmp_34fb0

jmp_34fa8:
  mov64 r0, 0x1

jmp_34fb0:
  jne r0, 0x0, jmp_34f10
  add64 r1, r4
  ldxdw r4, [r1+0x60]
  stxdw [r10-0xb0], r4
  ldxdw r4, [r1+0x58]
  stxdw [r10-0xb8], r4
  ldxdw r4, [r1+0x50]
  stxdw [r10-0xc0], r4
  ldxdw r4, [r1+0x48]
  stxdw [r10-0xc8], r4
  ldxdw r5, [r3+0x0]
  jne r4, r5, jmp_35060
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r10-0xc0]
  jne r5, r4, jmp_35060
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r10-0xb8]
  jne r5, r4, jmp_35060
  mov64 r4, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r5, [r10-0xb0]
  jeq r5, r3, jmp_35068

jmp_35060:
  mov64 r4, 0x1

jmp_35068:
  jeq r4, 0x0, jmp_36b18
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x1
  stdw [r10-0x100], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x100
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x177f
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x109
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x258
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x250]
  ldxdw r8, [r10-0x258]
  ja jmp_38370

jmp_35208:
  ldxb r1, [r2+0x20]
  jeq r1, 0x0, jmp_35970
  ldxdw r3, [r2+0x8]
  ldxdw r1, [r3+0x28]
  jeq r1, 0x0, jmp_35ee8
  stxdw [r10-0x390], r4
  mov64 r9, r2
  ldxb r2, [r2+0x21]
  stxdw [r10-0x3b0], r2
  ldxdw r2, [r5+0x10]
  stxdw [r10-0x3a0], r2
  ldxdw r2, [r5+0x8]
  stxdw [r10-0x3a8], r2
  ldxdw r1, [r1+0x0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0xd0], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0xd8], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xe0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xe8], r1
  stxdw [r10-0x398], r3
  ldxdw r2, [r3+0x8]
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_10db0
  ldxdw r7, [r10-0xa0]
  ldxdw r8, [r10-0xa8]
  jne r8, 0x2, jmp_38370
  jge r7, 0x4, jmp_37e98
  ldxdw r3, [r10-0x390]
  mov64 r2, r9
  jeq r7, 0x0, jmp_363e0
  mul64 r7, 0x4c
  ldxdw r1, [r10-0x398]
  ldxdw r1, [r1+0x8]
  mov64 r4, 0x0
  ja jmp_35360

jmp_35350:
  add64 r4, 0x4c
  jeq r7, r4, jmp_363e0

jmp_35360:
  mov64 r5, r1
  add64 r5, r4
  ldxb r0, [r5+0x6f]
  jne r0, 0x4, jmp_35350
  ldxdw r0, [r5+0x28]
  ldxdw r8, [r10-0xe8]
  jne r0, r8, jmp_353e8
  ldxdw r0, [r5+0x30]
  ldxdw r8, [r10-0xe0]
  jne r0, r8, jmp_353e8
  ldxdw r0, [r5+0x38]
  ldxdw r8, [r10-0xd8]
  jne r0, r8, jmp_353e8
  mov64 r0, 0x0
  ldxdw r5, [r5+0x40]
  ldxdw r8, [r10-0xd0]
  jeq r5, r8, jmp_353f0

jmp_353e8:
  mov64 r0, 0x1

jmp_353f0:
  jne r0, 0x0, jmp_35350
  add64 r1, r4
  ldxdw r4, [r1+0x60]
  stxdw [r10-0xb0], r4
  ldxdw r4, [r1+0x58]
  stxdw [r10-0xb8], r4
  ldxdw r4, [r1+0x50]
  stxdw [r10-0xc0], r4
  ldxdw r4, [r1+0x48]
  stxdw [r10-0xc8], r4
  ldxdw r5, [r3+0x0]
  jne r4, r5, jmp_354a0
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r10-0xc0]
  jne r5, r4, jmp_354a0
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r10-0xb8]
  jne r5, r4, jmp_354a0
  mov64 r4, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r5, [r10-0xb0]
  jeq r5, r3, jmp_354a8

jmp_354a0:
  mov64 r4, 0x1

jmp_354a8:
  jeq r4, 0x0, jmp_36880
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x1
  stdw [r10-0x100], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x100
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x177f
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x8b
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x2f8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x2f0]
  ldxdw r8, [r10-0x2f8]
  ja jmp_38370

jmp_35648:
  ldxdw r9, [r2+0x8]
  ldxdw r1, [r9+0x28]
  jeq r1, 0x0, jmp_35c60
  mov64 r1, r10
  add64 r1, -0xe8
  lddw r2, data_16ec
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_16ec
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x19f
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1a0]
  ldxdw r8, [r10-0x1a8]
  ja jmp_38370

jmp_357f8:
  stw [r10-0x100], 0x38
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r7, r10
  add64 r7, -0x100
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17a8
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x388
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x380]
  ldxdw r8, [r10-0x388]
  ja jmp_38370

jmp_35970:
  stw [r10-0x100], 0x3b
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r7, r10
  add64 r7, -0x100
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x2e8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x2e0]
  ldxdw r8, [r10-0x2e8]
  ja jmp_38370

jmp_35ae8:
  stw [r10-0x100], 0x3b
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r7, r10
  add64 r7, -0x100
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x240]
  ldxdw r8, [r10-0x248]
  ja jmp_38370

jmp_35c60:
  ldxdw r0, [r5+0x10]
  ldxdw r7, [r5+0x8]
  ldxdw r1, [r9+0x20]
  ldxdw r1, [r1+0x0]
  ldxdw r3, [r1+0x18]
  stxdw [r10-0x90], r3
  ldxdw r3, [r1+0x10]
  stxdw [r10-0x98], r3
  ldxdw r3, [r1+0x8]
  stxdw [r10-0xa0], r3
  ldxdw r3, [r1+0x0]
  stxdw [r10-0xa8], r3
  lddw r1, data_2b2d
  ldxdw r5, [r1+0x0]
  jne r3, r5, jmp_35d40
  ldxdw r1, [r1+0x8]
  ldxdw r3, [r10-0xa0]
  jne r3, r1, jmp_35d40
  lddw r3, data_2b2d
  ldxdw r1, [r3+0x10]
  ldxdw r5, [r10-0x98]
  jne r5, r1, jmp_35d40
  mov64 r1, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r5, [r10-0x90]
  jeq r5, r3, jmp_35d48

jmp_35d40:
  mov64 r1, 0x1

jmp_35d48:
  jeq r1, 0x0, jmp_361d8
  mov64 r1, r10
  add64 r1, -0xe8
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x177f
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x1a7
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1b0]
  ldxdw r8, [r10-0x1b8]
  ja jmp_38370

jmp_35ee8:
  stw [r10-0x118], 0x3b
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r7, r10
  add64 r7, -0x118
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x378
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x370]
  ldxdw r8, [r10-0x378]
  ja jmp_38370

jmp_36060:
  stw [r10-0x118], 0x3b
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r7, r10
  add64 r7, -0x118
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x2d8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x2d0]
  ldxdw r8, [r10-0x2d8]
  ja jmp_38370

jmp_361d8:
  ldxdw r1, [r2+0x18]
  jne r1, 0x5, jmp_366d0
  stxdw [r10-0x3a8], r7
  stxdw [r10-0x3a0], r0
  stxdw [r10-0x390], r4
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x398], r1
  ldxdw r2, [r9+0x8]
  add64 r2, 0x8
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_10db0
  ldxdw r7, [r10-0xa0]
  ldxdw r8, [r10-0xa8]
  jne r8, 0x2, jmp_38370
  jge r7, 0x4, jmp_38388
  ldxdw r1, [r10-0x390]
  ldxdw r8, [r10-0x398]
  jeq r7, 0x0, jmp_36848
  mov64 r2, r8
  add64 r2, 0xc0
  stxdw [r10-0x3b0], r2
  mov64 r2, r8
  add64 r2, 0x90
  stxdw [r10-0x3b8], r2
  mov64 r2, r8
  add64 r2, 0x60
  stxdw [r10-0x3c0], r2
  mov64 r2, r8
  add64 r2, 0x30
  stxdw [r10-0x3c8], r2
  mul64 r7, 0x4c
  ldxdw r2, [r9+0x8]
  mov64 r3, 0x0
  ja jmp_36310

jmp_362f0:
  mov64 r5, 0x1

jmp_362f8:
  jeq r5, 0x0, jmp_36da8

jmp_36300:
  add64 r3, 0x4c
  jeq r7, r3, jmp_36848

jmp_36310:
  mov64 r4, r2
  add64 r4, r3
  ldxb r5, [r4+0x6f]
  jne r5, 0x2, jmp_36300
  ldxdw r5, [r8+0x0]
  ldxdw r0, [r5+0x18]
  stxdw [r10-0x90], r0
  ldxdw r0, [r5+0x10]
  stxdw [r10-0x98], r0
  ldxdw r0, [r5+0x8]
  stxdw [r10-0xa0], r0
  ldxdw r5, [r5+0x0]
  stxdw [r10-0xa8], r5
  ldxdw r0, [r4+0x28]
  jne r0, r5, jmp_362f0
  ldxdw r5, [r4+0x30]
  ldxdw r0, [r10-0xa0]
  jne r5, r0, jmp_362f0
  ldxdw r5, [r4+0x38]
  ldxdw r0, [r10-0x98]
  jne r5, r0, jmp_362f0
  mov64 r5, 0x0
  ldxdw r4, [r4+0x40]
  ldxdw r0, [r10-0x90]
  jne r4, r0, jmp_362f0
  ja jmp_362f8

jmp_363e0:
  stw [r10-0x118], 0x3c
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r7, r10
  add64 r7, -0x118
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ac
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x368
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x360]
  ldxdw r8, [r10-0x368]
  ja jmp_38370

jmp_36558:
  stw [r10-0x118], 0x3c
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r7, r10
  add64 r7, -0x118
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ac
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x2c8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x2c0]
  ldxdw r8, [r10-0x2c8]
  ja jmp_38370

jmp_366d0:
  stw [r10-0x100], 0x3b
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r7, r10
  add64 r7, -0x100
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x1
  stdw [r10-0xc8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x78], r1
  stw [r10-0x10], 0x17ab
  stb [r10-0x58], 0x2
  stdw [r10-0xa8], 0x2
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1c0]
  ldxdw r8, [r10-0x1c8]
  ja jmp_38370

jmp_36848:
  mov64 r1, r10
  add64 r1, -0x238
  mov64 r2, 0x3c
  call fn_5a078
  ldxdw r7, [r10-0x230]
  ldxdw r8, [r10-0x238]
  ja jmp_38370

jmp_36880:
  ldxh r7, [r1+0x6c]
  ldxw r5, [r1+0x68]
  ldxb r9, [r1+0x6e]
  ldxdw r1, [r10-0x398]
  ldxdw r1, [r1+0x20]
  ldxdw r1, [r1+0x0]
  ldxdw r3, [r1+0x18]
  stxdw [r10-0x90], r3
  ldxdw r3, [r1+0x10]
  stxdw [r10-0x98], r3
  ldxdw r3, [r1+0x8]
  stxdw [r10-0xa0], r3
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xa8], r1
  lddw r3, -0x72a173d8738a0615
  jne r1, r3, jmp_36970
  lddw r1, 0x7b30da4272c284e
  ldxdw r3, [r10-0xa0]
  jne r3, r1, jmp_36970
  lddw r1, -0x5f38133c9c58fa1d
  ldxdw r3, [r10-0x98]
  jne r3, r1, jmp_36970
  mov64 r1, 0x0
  lddw r3, 0x1bea5fd23a69683e
  ldxdw r4, [r10-0x90]
  jeq r4, r3, jmp_36978

jmp_36970:
  mov64 r1, 0x1

jmp_36978:
  jeq r1, 0x0, jmp_36f30
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_170c
  call fn_594a8
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x1
  stdw [r10-0x100], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x100
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_170c
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x17ae
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x8f
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x308
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x300]
  ldxdw r8, [r10-0x308]
  ja jmp_38370

jmp_36b18:
  ldxw r7, [r1+0x68]
  ldxb r9, [r1+0x6e]
  ldxdw r1, [r10-0x398]
  ldxdw r1, [r1+0x20]
  ldxdw r1, [r1+0x0]
  ldxdw r3, [r1+0x18]
  stxdw [r10-0x90], r3
  ldxdw r3, [r1+0x10]
  stxdw [r10-0x98], r3
  ldxdw r3, [r1+0x8]
  stxdw [r10-0xa0], r3
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xa8], r1
  lddw r3, -0x72a173d8738a0615
  jne r1, r3, jmp_36c00
  lddw r1, 0x7b30da4272c284e
  ldxdw r3, [r10-0xa0]
  jne r3, r1, jmp_36c00
  lddw r1, -0x5f38133c9c58fa1d
  ldxdw r3, [r10-0x98]
  jne r3, r1, jmp_36c00
  mov64 r1, 0x0
  lddw r3, 0x1bea5fd23a69683e
  ldxdw r4, [r10-0x90]
  jeq r4, r3, jmp_36c08

jmp_36c00:
  mov64 r1, 0x1

jmp_36c08:
  jeq r1, 0x0, jmp_37060
  mov64 r1, r10
  add64 r1, -0x118
  lddw r2, data_170c
  call fn_594a8
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x1
  stdw [r10-0x100], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x190], r1
  mov64 r1, r10
  add64 r1, -0x100
  stxdw [r10-0x198], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x188], r1
  mov64 r2, r10
  add64 r2, -0x198
  lddw r1, data_170c
  call fn_5a268
  jne r0, 0x0, jmp_373f8
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0x70], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x78], r1
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stw [r10-0x10], 0x17ae
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x10e
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  mov64 r1, r10
  add64 r1, -0x268
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x260]
  ldxdw r8, [r10-0x268]
  ja jmp_38370

jmp_36da8:
  add64 r2, r3
  ldxdw r3, [r2+0x60]
  stxdw [r10-0xd0], r3
  ldxdw r3, [r2+0x58]
  stxdw [r10-0xd8], r3
  ldxdw r3, [r2+0x50]
  stxdw [r10-0xe0], r3
  ldxdw r3, [r2+0x48]
  stxdw [r10-0xe8], r3
  ldxdw r4, [r1+0x0]
  jne r3, r4, jmp_36e50
  ldxdw r3, [r1+0x8]
  ldxdw r4, [r10-0xe0]
  jne r4, r3, jmp_36e50
  ldxdw r3, [r1+0x10]
  ldxdw r4, [r10-0xd8]
  jne r4, r3, jmp_36e50
  mov64 r3, 0x0
  ldxdw r4, [r1+0x18]
  ldxdw r5, [r10-0xd0]
  jeq r5, r4, jmp_36e58

jmp_36e50:
  mov64 r3, 0x1

jmp_36e58:
  jeq r3, 0x0, jmp_37180
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1670
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_1670
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x1c0
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x177f
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1d0]
  ldxdw r8, [r10-0x1d8]
  ja jmp_38370

jmp_36f30:
  stxdw [r10-0x3b8], r5
  mov64 r1, r10
  add64 r1, -0x318
  ldxdw r3, [r10-0x3a8]
  ldxdw r4, [r10-0x3a0]
  call fn_383b0
  ldxdw r8, [r10-0x318]
  jne r8, 0x2, jmp_373d8
  stxdw [r10-0x3a0], r7
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_39510
  ldxdw r7, [r10-0x98]
  ldxdw r8, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_38370
  stxdw [r10-0x3a8], r9
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_c2a08
  ldxdw r9, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  jne r1, 0x1, jmp_37688
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0x90]
  stxdw [r10-0x98], r2
  stxdw [r10-0xa0], r1
  stxdw [r10-0xa8], r9
  mov64 r1, r10
  add64 r1, -0x358
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be7f0
  ldxdw r7, [r10-0x350]
  ldxdw r8, [r10-0x358]
  ja jmp_38370

jmp_37060:
  mov64 r1, r10
  add64 r1, -0x278
  ldxdw r3, [r10-0x3a8]
  ldxdw r4, [r10-0x3a0]
  call fn_383b0
  ldxdw r8, [r10-0x278]
  jne r8, 0x2, jmp_373e8
  stxdw [r10-0x3a0], r7
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_39510
  ldxdw r7, [r10-0x98]
  ldxdw r8, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  lddw r2, -0x8000000000000000
  jeq r1, r2, jmp_38370
  mov64 r1, r10
  add64 r1, -0xa8
  call fn_c2a08
  ldxdw r3, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  jne r1, 0x1, jmp_37818
  ldxdw r1, [r10-0x98]
  ldxdw r2, [r10-0x90]
  stxdw [r10-0x98], r2
  stxdw [r10-0xa0], r1
  stxdw [r10-0xa8], r3
  mov64 r1, r10
  add64 r1, -0x2b8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be7f0
  ldxdw r7, [r10-0x2b0]
  ldxdw r8, [r10-0x2b8]
  ja jmp_38370

jmp_37180:
  ldxw r7, [r2+0x68]
  ldxh r2, [r2+0x6c]
  stxdw [r10-0x3d0], r2
  stxdw [r10-0x188], r1
  lddw r1, str_1b5a
  stxdw [r10-0x198], r1
  stdw [r10-0x180], 0x20
  stdw [r10-0x190], 0xa
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r3, 0x2
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x90]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0xc8], r1
  ldxb r4, [r10-0x88]
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x90], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x98], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xa0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xa8], r1
  ldxdw r2, [r10-0xc8]
  jne r1, r2, jmp_372f8
  ldxdw r1, [r10-0xc0]
  ldxdw r2, [r10-0xa0]
  jne r2, r1, jmp_372f8
  ldxdw r1, [r10-0xb8]
  ldxdw r2, [r10-0x98]
  jne r2, r1, jmp_372f8
  mov64 r1, 0x0
  ldxdw r2, [r10-0xb0]
  ldxdw r3, [r10-0x90]
  jeq r3, r2, jmp_37300

jmp_372f8:
  mov64 r1, 0x1

jmp_37300:
  jeq r1, 0x0, jmp_37448
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1670
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_1670
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x1c7
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x177f
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1e0]
  ldxdw r8, [r10-0x1e8]
  ja jmp_38370

jmp_373d8:
  ldxdw r7, [r10-0x310]
  ja jmp_38370

jmp_373e8:
  ldxdw r7, [r10-0x270]
  ja jmp_38370

jmp_373f8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_37448:
  stxdw [r10-0x3d8], r4
  lddw r1, str_1b64
  stxdw [r10-0x100], r1
  stdw [r10-0xf8], 0x9
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x100
  mov64 r3, 0x1
  lddw r4, data_272e
  call fn_c9968
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x180], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0x188], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0x190], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x198], r1
  ldxb r4, [r10-0x88]
  ldxdw r1, [r10-0x3b0]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x90], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x98], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0xa0], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0xa8], r1
  ldxdw r2, [r10-0x198]
  jne r1, r2, jmp_375a8
  ldxdw r1, [r10-0x190]
  ldxdw r2, [r10-0xa0]
  jne r2, r1, jmp_375a8
  ldxdw r1, [r10-0x188]
  ldxdw r2, [r10-0x98]
  jne r2, r1, jmp_375a8
  mov64 r1, 0x0
  ldxdw r2, [r10-0x180]
  ldxdw r3, [r10-0x90]
  jeq r3, r2, jmp_375b0

jmp_375a8:
  mov64 r1, 0x1

jmp_375b0:
  jeq r1, 0x0, jmp_37ab0
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_169c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_169c
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x1ce
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b4
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x1f0]
  ldxdw r8, [r10-0x1f8]
  ja jmp_38370

jmp_37688:
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x3c0], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r8
  mov64 r3, r7
  call fn_42490
  ldxdw r7, [r10-0x98]
  ldxdw r8, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  jeq r1, 0x1, jmp_38370
  stxdw [r10-0x3c8], r9
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r10
  add64 r2, -0x90
  mov64 r3, 0x64
  call fn_d23d0
  ldxdw r1, [r10-0x3b8]
  mov64 r2, r1
  mov64 r3, r2
  jlt r2, 0x5dc, jmp_37740
  mov64 r3, 0x5dc

jmp_37740:
  mov64 r1, 0xc8
  jeq r2, 0x0, jmp_37758
  mov64 r1, r3

jmp_37758:
  stxdw [r10-0x190], r7
  stxdw [r10-0x198], r8
  ldxdw r2, [r10-0x28]
  stxdw [r10-0x120], r2
  ldxw r7, [r10-0x2c]
  stxw [r10-0x124], r7
  ldxdw r2, [r10-0x3a0]
  stxdw [r10-0xff0], r2
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r5, r10
  ldxdw r3, [r10-0x390]
  ldxdw r4, [r10-0x3c0]
  call fn_43df0
  ldxh r1, [r10-0x94]
  jne r1, 0x2, jmp_37d18
  ldxdw r8, [r10-0xa8]
  ldxdw r7, [r10-0xa0]
  ja jmp_38370

jmp_37818:
  stxdw [r10-0x3b8], r3
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x3a8], r1
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r8
  mov64 r3, r7
  call fn_45160
  ldxdw r7, [r10-0x98]
  ldxdw r8, [r10-0xa0]
  ldxdw r1, [r10-0xa8]
  jeq r1, 0x1, jmp_38370
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r10
  add64 r2, -0x90
  mov64 r3, 0x44
  call fn_d23d0
  ldxdw r1, [r10-0x3a0]
  mov64 r2, r1
  mov64 r3, r2
  jlt r2, 0x5dc, jmp_378d0
  mov64 r3, 0x5dc

jmp_378d0:
  mov64 r1, 0xc8
  jeq r2, 0x0, jmp_378e8
  mov64 r1, r3

jmp_378e8:
  stxdw [r10-0x190], r7
  stxdw [r10-0x198], r8
  ldxdw r2, [r10-0x48]
  stxdw [r10-0x140], r2
  ldxw r2, [r10-0x4c]
  stxdw [r10-0x3a0], r2
  stxw [r10-0x144], r2
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r9
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r2, r10
  add64 r2, -0x198
  mov64 r5, r10
  ldxdw r3, [r10-0x390]
  ldxdw r4, [r10-0x3a8]
  call fn_46630
  ldxdw r8, [r10-0xa8]
  ldxdw r7, [r10-0xa0]
  ldxh r1, [r10-0x94]
  jeq r1, 0x2, jmp_38370
  ldxdw r1, [r10-0x398]
  ldxdw r2, [r1+0x28]
  jeq r2, 0x0, jmp_37f30
  ldxw r1, [r10-0x98]
  ldxw r3, [r2+0x44]
  jeq r3, 0x0, jmp_379d8
  ldxw r4, [r2+0x40]
  mov64 r5, r1
  jne r4, r5, jmp_382a8

jmp_379d8:
  ldxdw r4, [r10-0x3a0]
  jle r4, r3, jmp_38108
  ldxdw r3, [r10-0x390]
  ldxdw r4, [r3+0x18]
  stxdw [r2+0x20], r4
  ldxdw r4, [r3+0x10]
  stxdw [r2+0x18], r4
  ldxdw r4, [r3+0x8]
  stxdw [r2+0x10], r4
  ldxdw r3, [r3+0x0]
  stxdw [r2+0x8], r3
  ldxdw r3, [r10-0x398]
  ldxdw r2, [r3+0x28]
  stxdw [r2+0x30], r7
  stxdw [r2+0x28], r8
  ldxdw r2, [r3+0x28]
  stxw [r2+0x40], r1
  ldxdw r1, [r3+0x28]
  sth [r1+0x48], 0x0
  ldxdw r1, [r3+0x28]
  ldxdw r2, [r10-0x3a0]
  stxw [r1+0x44], r2
  ldxdw r1, [r3+0x28]
  ldxdw r2, [r10-0x3b8]
  stxdw [r1+0x38], r2
  ldxdw r1, [r3+0x28]
  ja jmp_37e78

jmp_37ab0:
  stxdw [r10-0x3e0], r4
  stxdw [r10-0x3f0], r7
  mov64 r1, r8
  call fn_c4918
  mov64 r2, r8
  stxdw [r10-0x3e8], r0
  jne r0, 0x0, jmp_37b50
  ldxdw r3, [r2+0x18]
  mov64 r7, r2
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r4, r10
  add64 r4, -0x198
  ldxdw r5, [r10-0x390]
  call fn_3bd88
  mov64 r2, r7
  ldxdw r7, [r10-0xa0]
  ldxdw r8, [r10-0xa8]
  jne r8, 0x2, jmp_38370

jmp_37b50:
  ldxdw r1, [r10-0x3e0]
  stxdw [r10-0xfc8], r1
  ldxdw r1, [r10-0x3d8]
  stxdw [r10-0xfd0], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0xfd8], r1
  ldxdw r1, [r10-0x3b0]
  stxdw [r10-0xfe0], r1
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0xff0], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r2
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r5, r10
  mov64 r2, r9
  ldxdw r3, [r10-0x3a8]
  ldxdw r4, [r10-0x3a0]
  call fn_39a08
  ldxdw r8, [r10-0x208]
  jne r8, 0x2, jmp_37d08
  ldxdw r1, [r10-0x398]
  ldxdw r3, [r1+0x18]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r4, r10
  add64 r4, -0x198
  ldxdw r5, [r10-0x390]
  call fn_3bd88
  ldxdw r2, [r10-0xa0]
  ldxdw r8, [r10-0xa8]
  jne r8, 0x2, jmp_37ee8
  mov64 r1, 0x1
  jsge r7, r2, jmp_37c88
  mov64 r1, 0x0

jmp_37c88:
  ldxdw r2, [r10-0x3e8]
  xor64 r2, -0x1
  and64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_37f68
  ldxdw r1, [r10-0x398]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x228
  ldxdw r3, [r10-0x3d0]
  ldxdw r4, [r10-0x3f0]
  call fn_3b148
  ldxdw r8, [r10-0x228]
  jeq r8, 0x2, jmp_37e88
  ldxdw r7, [r10-0x220]
  ja jmp_38370

jmp_37d08:
  ldxdw r7, [r10-0x200]
  ja jmp_38370

jmp_37d18:
  ldxdw r2, [r10-0x398]
  ldxdw r3, [r2+0x28]
  jeq r3, 0x0, jmp_37ef8
  ldxdw r5, [r10-0xa8]
  ldxh r2, [r10-0x92]
  stxdw [r10-0x3a0], r2
  ldxw r4, [r10-0x98]
  ldxdw r0, [r10-0xa0]
  ldxw r8, [r3+0x44]
  jeq r8, 0x0, jmp_37d80
  ldxw r9, [r3+0x40]
  mov64 r2, r4
  jne r9, r2, jmp_381d8

jmp_37d80:
  mov64 r2, r7
  jle r2, r8, jmp_38038
  ldxdw r2, [r10-0x390]
  ldxdw r8, [r2+0x18]
  stxdw [r3+0x20], r8
  ldxdw r8, [r2+0x10]
  stxdw [r3+0x18], r8
  ldxdw r8, [r2+0x8]
  stxdw [r3+0x10], r8
  ldxdw r2, [r2+0x0]
  stxdw [r3+0x8], r2
  ldxdw r3, [r10-0x398]
  ldxdw r2, [r3+0x28]
  stxdw [r2+0x30], r0
  stxdw [r2+0x28], r5
  ldxdw r2, [r3+0x28]
  stxw [r2+0x40], r4
  and64 r1, 0x1
  jne r1, 0x0, jmp_37e28
  mov64 r1, -0x1
  stxdw [r10-0x3a0], r1

jmp_37e28:
  ldxdw r2, [r10-0x398]
  ldxdw r1, [r2+0x28]
  ldxdw r3, [r10-0x3a0]
  stxh [r1+0x48], r3
  ldxdw r1, [r2+0x28]
  stxw [r1+0x44], r7
  ldxdw r1, [r2+0x28]
  ldxdw r3, [r10-0x3c8]
  stxdw [r1+0x38], r3
  ldxdw r1, [r2+0x28]

jmp_37e78:
  ldxdw r2, [r10-0x3b0]
  stxb [r1+0x4a], r2

jmp_37e88:
  mov64 r8, 0x2
  ja jmp_38370

jmp_37e98:
  mov64 r1, r7
  mov64 r2, 0x3
  lddw r3, data_6500
  call fn_cf460

jmp_37ec0:
  mov64 r1, r7
  mov64 r2, 0x3
  lddw r3, data_6518
  call fn_cf460

jmp_37ee8:
  mov64 r7, r2
  ja jmp_38370

jmp_37ef8:
  mov64 r1, r10
  add64 r1, -0x348
  mov64 r2, 0x3b
  call fn_5a078
  ldxdw r7, [r10-0x340]
  ldxdw r8, [r10-0x348]
  ja jmp_38370

jmp_37f30:
  mov64 r1, r10
  add64 r1, -0x2a8
  mov64 r2, 0x3b
  call fn_5a078
  ldxdw r7, [r10-0x2a0]
  ldxdw r8, [r10-0x2a8]
  ja jmp_38370

jmp_37f68:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1660
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_1660
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x1f4
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b1
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x210]
  ldxdw r8, [r10-0x218]
  ja jmp_38370

jmp_38038:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1660
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_1660
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0xcc
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b1
  mov64 r1, r10
  add64 r1, -0x338
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x330]
  ldxdw r8, [r10-0x338]
  ja jmp_38370

jmp_38108:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_1660
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_1660
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x139
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b1
  mov64 r1, r10
  add64 r1, -0x298
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x290]
  ldxdw r8, [r10-0x298]
  ja jmp_38370

jmp_381d8:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16b4
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_16b4
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0xbf
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b2
  mov64 r1, r10
  add64 r1, -0x328
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x320]
  ldxdw r8, [r10-0x328]
  ja jmp_38370

jmp_382a8:
  mov64 r1, r10
  add64 r1, -0x88
  lddw r2, data_16b4
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0x70
  lddw r2, data_16b4
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xa0], r1
  stb [r10-0x58], 0x2
  stw [r10-0x90], 0x131
  stdw [r10-0x98], 0x39
  stdw [r10-0xa8], 0x0
  stw [r10-0x10], 0x17b2
  mov64 r1, r10
  add64 r1, -0x288
  mov64 r2, r10
  add64 r2, -0xa8
  call fn_be760
  ldxdw r7, [r10-0x280]
  ldxdw r8, [r10-0x288]

jmp_38370:
  stxdw [r6+0x0], r8
  stxdw [r6+0x8], r7
  exit

jmp_38388:
  mov64 r1, r7
  mov64 r2, 0x3
  lddw r3, data_6548
  call fn_cf460

fn_383b0:
  mov64 r5, r2
  mov64 r6, r1
  jgt r4, -0xd, jmp_39268
  mov64 r1, 0x1
  jlt r4, 0x4c5, jmp_383e0
  mov64 r1, 0x0

jmp_383e0:
  mov64 r2, r4
  add64 r2, 0xc
  and64 r1, 0x1
  jeq r1, 0x0, jmp_39280

jmp_38400:
  ldxdw r1, [r5+0x18]
  jne r1, 0x3, jmp_38438
  mov64 r1, 0x0
  jsge r2, 0x0, jmp_385b0

jmp_38420:
  lddw r3, data_6530
  call fn_cb038

jmp_38438:
  stw [r10-0x170], 0x3b
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x150], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x158], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x148], r1
  mov64 r2, r10
  add64 r2, -0x158
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_39408
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x98], r1
  stw [r10-0x30], 0x17ab
  stb [r10-0x78], 0x2
  stdw [r10-0xc8], 0x2
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r10
  add64 r2, -0xc8
  call fn_be760
  ldxdw r7, [r10-0x188]
  ldxdw r8, [r10-0x190]
  ja jmp_393f0

jmp_385b0:
  ldxdw r8, [r5+0x10]
  stxdw [r10-0x1b0], r5
  stxdw [r10-0x1a8], r4
  mov64 r9, r3
  jeq r2, 0x0, jmp_391e8
  mov64 r7, r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_38620
  mov64 r3, r1

jmp_38620:
  mov64 r0, r3
  mov64 r2, r7
  sub64 r0, r2
  mov64 r5, 0x0
  mov64 r1, 0x1
  mov64 r7, 0x1
  jle r0, r3, jmp_38690
  ldxdw r3, [r10-0x1a8]
  mov64 r4, r9
  jeq r7, 0x0, jmp_386b0

jmp_38670:
  lddw r0, 0x300000007
  jgt r5, r0, jmp_386d0
  ja jmp_38420

jmp_38690:
  mov64 r7, 0x0
  ldxdw r3, [r10-0x1a8]
  mov64 r4, r9
  jne r7, 0x0, jmp_38670

jmp_386b0:
  mov64 r5, r0
  lddw r0, 0x300000007
  jle r5, r0, jmp_38420

jmp_386d0:
  lddw r1, 0x300000000
  stxdw [r1+0x0], r5
  stxdw [r10-0x168], r5
  stxdw [r10-0x170], r2
  stdw [r10-0x160], 0x0
  jle r2, 0x7, jmp_39200
  mov64 r7, 0x0

jmp_38710:
  mov64 r1, r5
  add64 r1, r7
  lddw r0, -0x69a73987cf725e7b
  stxdw [r1+0x0], r0
  add64 r7, 0x8
  stxdw [r10-0x160], r7
  sub64 r2, r7
  jle r2, 0x3, jmp_39460

jmp_38758:
  add64 r5, r7
  stxw [r5+0x0], r3
  add64 r7, 0x4
  stxdw [r10-0x160], r7
  ldxdw r1, [r10-0x170]
  sub64 r1, r7
  jgt r3, r1, jmp_394c0

jmp_38790:
  ldxdw r1, [r10-0x168]
  add64 r1, r7
  mov64 r2, r4
  mov64 r9, r3
  call fn_d23d0
  add64 r7, r9
  stxdw [r10-0x160], r7
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r4, 0x0
  mov64 r5, 0x1
  mov64 r1, r2
  add64 r1, -0x88
  jle r1, r2, jmp_390f0
  ldxdw r3, [r10-0x1b0]
  jeq r5, 0x0, jmp_39108

jmp_38820:
  lddw r1, 0x300007f78
  jne r2, 0x0, jmp_39128

jmp_38838:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_39148

jmp_38850:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r8+0x0]
  ldxdw r4, [r8+0x30]
  ldxdw r5, [r4+0x18]
  stxdw [r10-0xf0], r5
  ldxdw r5, [r4+0x10]
  stxdw [r10-0xf8], r5
  ldxdw r5, [r4+0x8]
  stxdw [r10-0x100], r5
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x108], r4
  ldxdw r4, [r3+0x8]
  ldxdw r3, [r4+0x0]
  ldxdw r3, [r3+0x0]
  ldxdw r5, [r3+0x18]
  stxdw [r10-0xd0], r5
  ldxdw r5, [r3+0x10]
  stxdw [r10-0xd8], r5
  ldxdw r5, [r3+0x8]
  stxdw [r10-0xe0], r5
  ldxdw r3, [r3+0x0]
  stxdw [r10-0xe8], r3
  ldxdw r3, [r8+0x60]
  ldxdw r5, [r3+0x18]
  stxdw [r10-0xb0], r5
  ldxdw r5, [r3+0x10]
  stxdw [r10-0xb8], r5
  ldxdw r5, [r3+0x8]
  stxdw [r10-0xc0], r5
  ldxdw r3, [r3+0x0]
  stxdw [r10-0xc8], r3
  ldxdw r3, [r2+0x0]
  ldxdw r5, [r2+0x8]
  ldxdw r0, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r0
  stxdw [r1+0x8], r5
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x0
  ldxdw r2, [r10-0x108]
  stxdw [r1+0x22], r2
  ldxdw r2, [r10-0x100]
  stxdw [r1+0x2a], r2
  ldxdw r2, [r10-0xf8]
  stxdw [r1+0x32], r2
  ldxdw r2, [r10-0xf0]
  stxdw [r1+0x3a], r2
  sth [r1+0x42], 0x0
  ldxdw r2, [r10-0xe8]
  stxdw [r1+0x44], r2
  ldxdw r2, [r10-0xe0]
  stxdw [r1+0x4c], r2
  ldxdw r2, [r10-0xd8]
  stxdw [r1+0x54], r2
  ldxdw r2, [r10-0xd0]
  stxdw [r1+0x5c], r2
  sth [r1+0x64], 0x1
  ldxdw r2, [r10-0xb0]
  stxdw [r1+0x7e], r2
  ldxdw r2, [r10-0xb8]
  stxdw [r1+0x76], r2
  ldxdw r2, [r10-0xc0]
  stxdw [r1+0x6e], r2
  ldxdw r2, [r10-0xc8]
  stxdw [r1+0x66], r2
  sth [r1+0x86], 0x0
  lddw r2, -0x72a173d8738a0615
  stxdw [r10-0x128], r2
  lddw r2, 0x7b30da4272c284e
  stxdw [r10-0x120], r2
  lddw r2, -0x5f38133c9c58fa1d
  stxdw [r10-0x118], r2
  lddw r2, 0x1bea5fd23a69683e
  stxdw [r10-0x110], r2
  stxdw [r10-0x150], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x140], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0x130], r1
  stdw [r10-0x148], 0x4
  stdw [r10-0x158], 0x4
  ldxdw r0, [r8+0x8]
  ldxdw r1, [r0+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38b50
  mov64 r2, 0x0

jmp_38b50:
  ldxdw r5, [r8+0x0]
  stxdw [r0+0x0], r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_39458
  ldxdw r3, [r8+0x10]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38ba0
  mov64 r2, 0x0

jmp_38ba0:
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_39458
  ldxdw r7, [r8+0x38]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38be0
  mov64 r2, 0x0

jmp_38be0:
  ldxdw r9, [r8+0x30]
  stxdw [r10-0x1d0], r9
  ldxb r9, [r8+0x2a]
  stxdw [r10-0x1c8], r9
  ldxb r9, [r8+0x29]
  stxdw [r10-0x1c0], r9
  ldxb r9, [r8+0x28]
  stxdw [r10-0x1b8], r9
  ldxdw r9, [r8+0x20]
  stxdw [r10-0x1b0], r9
  ldxdw r9, [r8+0x18]
  stxdw [r7+0x0], r1
  jeq r2, 0x1, jmp_39458
  ldxdw r1, [r8+0x40]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38c80
  mov64 r2, 0x0

jmp_38c80:
  stxdw [r10-0x1d8], r9
  ldxdw r9, [r10-0x1a8]
  stxdw [r9+0x0], r1
  jeq r2, 0x1, jmp_39458
  ldxdw r9, [r4+0x0]
  ldxdw r4, [r9+0x8]
  ldxdw r1, [r4+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38cd8
  mov64 r2, 0x0

jmp_38cd8:
  stxdw [r10-0x1e0], r7
  ldxb r7, [r8+0x5a]
  stxdw [r10-0x208], r7
  ldxb r7, [r8+0x59]
  stxdw [r10-0x200], r7
  ldxb r7, [r8+0x58]
  stxdw [r10-0x1f8], r7
  ldxdw r7, [r8+0x50]
  stxdw [r10-0x1f0], r7
  ldxdw r7, [r8+0x48]
  stxdw [r10-0x1e8], r7
  ldxdw r7, [r9+0x0]
  stxdw [r10-0x210], r7
  stxdw [r4+0x0], r1
  jeq r2, 0x1, jmp_39458
  ldxdw r7, [r9+0x10]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_38d80
  mov64 r2, 0x0

jmp_38d80:
  stxdw [r10-0x218], r3
  stxdw [r7+0x0], r1
  jeq r2, 0x1, jmp_39458
  stxdw [r10-0x228], r4
  ldxdw r1, [r8+0x68]
  ldxdw r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_38dd0
  mov64 r3, 0x0

jmp_38dd0:
  stxdw [r10-0x220], r5
  ldxdw r4, [r8+0x60]
  stxdw [r10-0x250], r4
  ldxb r4, [r9+0x2a]
  stxdw [r10-0x248], r4
  ldxb r4, [r9+0x29]
  stxdw [r10-0x240], r4
  ldxb r4, [r9+0x28]
  stxdw [r10-0x238], r4
  ldxdw r4, [r9+0x20]
  stxdw [r10-0x230], r4
  ldxdw r4, [r9+0x18]
  stxdw [r1+0x0], r2
  jeq r3, 0x1, jmp_39458
  ldxdw r2, [r8+0x70]
  ldxdw r3, [r2+0x0]
  add64 r3, 0x1
  mov64 r5, 0x1
  jeq r3, 0x0, jmp_38e70
  mov64 r5, 0x0

jmp_38e70:
  stxdw [r10-0x258], r0
  stxdw [r2+0x0], r3
  jeq r5, 0x1, jmp_39458
  ldxdw r3, [r8+0x78]
  ldxdw r5, [r8+0x80]
  ldxb r0, [r8+0x88]
  ldxb r9, [r8+0x89]
  ldxb r8, [r8+0x8a]
  stxb [r10-0xe], r8
  stxb [r10-0xf], r9
  stxb [r10-0x10], r0
  stxdw [r10-0x18], r5
  stxdw [r10-0x20], r3
  stxdw [r10-0x28], r2
  stxdw [r10-0x30], r1
  ldxdw r1, [r10-0x250]
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x248]
  stxb [r10-0x3e], r1
  ldxdw r1, [r10-0x240]
  stxb [r10-0x3f], r1
  ldxdw r1, [r10-0x238]
  stxb [r10-0x40], r1
  ldxdw r1, [r10-0x230]
  stxdw [r10-0x48], r1
  stxdw [r10-0x50], r4
  stxdw [r10-0x58], r7
  ldxdw r1, [r10-0x228]
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x210]
  stxdw [r10-0x68], r1
  ldxdw r1, [r10-0x208]
  stxb [r10-0x6e], r1
  ldxdw r1, [r10-0x200]
  stxb [r10-0x6f], r1
  ldxdw r1, [r10-0x1f8]
  stxb [r10-0x70], r1
  ldxdw r1, [r10-0x1f0]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x1e8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x1a8]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0x1e0]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x1c8]
  stxb [r10-0x9e], r1
  ldxdw r1, [r10-0x1c0]
  stxb [r10-0x9f], r1
  ldxdw r1, [r10-0x1b8]
  stxb [r10-0xa0], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x218]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x258]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x220]
  stxdw [r10-0xc8], r1
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0x158
  mov64 r3, r10
  add64 r3, -0xc8
  mov64 r4, 0x4
  call fn_c2670
  lddw r1, -0x7fffffffffffffe6
  ldxdw r2, [r10-0x108]
  jne r2, r1, jmp_39160
  mov64 r1, r10
  add64 r1, -0xc8
  call fn_a480
  mov64 r8, 0x2
  ja jmp_393f0

jmp_390f0:
  mov64 r5, 0x0
  ldxdw r3, [r10-0x1b0]
  jne r5, 0x0, jmp_38820

jmp_39108:
  mov64 r4, r1
  lddw r1, 0x300007f78
  jeq r2, 0x0, jmp_38838

jmp_39128:
  mov64 r1, r4
  lddw r2, 0x300000008
  jge r1, r2, jmp_38850

jmp_39148:
  mov64 r1, 0x1
  mov64 r2, 0x88
  call fn_cb058

jmp_39160:
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xe8], r1
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0xe8
  call fn_be7f0
  ldxdw r7, [r10-0x198]
  ldxdw r8, [r10-0x1a0]
  mov64 r1, r10
  add64 r1, -0xc8
  call fn_a480
  ja jmp_393f0

jmp_391e8:
  stdw [r10-0x160], 0x0
  stdw [r10-0x168], 0x1
  stdw [r10-0x170], 0x0

jmp_39200:
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, 0x0
  mov64 r3, 0x8
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r4, r9
  ldxdw r3, [r10-0x1a8]
  ldxdw r2, [r10-0x170]
  ldxdw r5, [r10-0x168]
  ldxdw r7, [r10-0x160]
  ja jmp_38710

jmp_39268:
  mov64 r1, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_38400

jmp_39280:
  stw [r10-0x170], 0x1
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r7, r10
  add64 r7, -0x170
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x1
  stdw [r10-0xe8], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x150], r1
  mov64 r1, r10
  add64 r1, -0xe8
  stxdw [r10-0x158], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x148], r1
  mov64 r2, r10
  add64 r2, -0x158
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_39408
  ldxdw r1, [r10-0xd8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x88], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x98], r1
  stw [r10-0x30], 0x1771
  stb [r10-0x78], 0x2
  stdw [r10-0xc8], 0x2
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xc8
  call fn_be760
  ldxdw r7, [r10-0x178]
  ldxdw r8, [r10-0x180]

jmp_393f0:
  stxdw [r6+0x8], r7
  stxdw [r6+0x0], r8
  exit

jmp_39408:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_39458:
  call abort

jmp_39460:
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r7
  mov64 r3, 0x4
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r4, r9
  ldxdw r3, [r10-0x1a8]
  ldxdw r5, [r10-0x168]
  ldxdw r7, [r10-0x160]
  ja jmp_38758

jmp_394c0:
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r7
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  mov64 r4, r9
  ldxdw r3, [r10-0x1a8]
  ldxdw r7, [r10-0x160]
  ja jmp_38790

fn_39510:
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xd8
  call fn_c29f8
  ldxdw r1, [r10-0xb8]
  lddw r2, -0x8000000000000000
  jne r1, r2, jmp_396c8
  stw [r10-0x110], 0x3e
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r7, r10
  add64 r7, -0x110
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x10], 0x0
  stdw [r10-0x18], 0x1
  stdw [r10-0x20], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x128], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x130], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x120], r1
  mov64 r2, r10
  add64 r2, -0x130
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_399b8
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  stw [r10-0x40], 0x17ae
  stb [r10-0x88], 0x2
  stdw [r10-0xd8], 0x2
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ja jmp_39970

jmp_396c8:
  ldxdw r4, [r10-0xd4]
  stxdw [r10-0xf8], r4
  ldxdw r5, [r10-0xcc]
  stxdw [r10-0xf0], r5
  ldxdw r0, [r10-0xc4]
  stxdw [r10-0xe8], r0
  ldxw r7, [r10-0xbc]
  stxw [r10-0xe0], r7
  ldxdw r2, [r10-0xb0]
  ldxdw r3, [r10-0xa8]
  ldxw r8, [r10-0xd8]
  stxdw [r10-0x12c], r4
  stxw [r10-0x130], r8
  stxdw [r10-0x124], r5
  stxdw [r10-0x11c], r0
  stxw [r10-0x114], r7
  lddw r4, -0x72a173d8738a0615
  ldxdw r5, [r10-0x130]
  jne r5, r4, jmp_397d0
  lddw r4, 0x7b30da4272c284e
  ldxdw r5, [r10-0x128]
  jne r5, r4, jmp_397d0
  lddw r4, -0x5f38133c9c58fa1d
  ldxdw r5, [r10-0x120]
  jne r5, r4, jmp_397d0
  mov64 r4, 0x0
  lddw r5, 0x1bea5fd23a69683e
  ldxdw r0, [r10-0x118]
  jeq r0, r5, jmp_397d8

jmp_397d0:
  mov64 r4, 0x1

jmp_397d8:
  jeq r4, 0x0, jmp_399a0
  mov64 r1, r10
  add64 r1, -0x110
  lddw r2, data_170c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_170c
  call fn_5a268
  jne r0, 0x0, jmp_399b8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x100]
  stxdw [r10-0xa8], r1
  lddw r1, str_1b21
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17ae
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x189
  stdw [r10-0xc8], 0x39
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]

jmp_39970:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  lddw r1, -0x8000000000000000

jmp_39990:
  stxdw [r6+0x0], r1
  exit

jmp_399a0:
  stxdw [r6+0x10], r3
  stxdw [r6+0x8], r2
  ja jmp_39990

jmp_399b8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_39a08:
  mov64 r0, r2
  mov64 r8, r1
  jgt r4, -0x9, jmp_3af00
  mov64 r1, 0x1
  jlt r4, 0x4c9, jmp_39a38
  mov64 r1, 0x0

jmp_39a38:
  mov64 r2, r4
  add64 r2, 0x8
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3af18

jmp_39a58:
  stxdw [r10-0x2b8], r8
  mov64 r7, 0x0
  jsge r2, 0x0, jmp_39a90

jmp_39a70:
  mov64 r1, r7
  lddw r3, data_6560
  call fn_cb038

jmp_39a90:
  ldxdw r1, [r5-0xfc8]
  ldxdw r6, [r5-0xfd0]
  ldxdw r7, [r5-0xfd8]
  ldxdw r8, [r5-0xfe0]
  stxdw [r10-0x2e0], r8
  ldxdw r8, [r5-0xfe8]
  stxdw [r10-0x2f0], r8
  ldxdw r8, [r5-0xff0]
  ldxdw r9, [r5-0xff8]
  ldxdw r5, [r5-0x1000]
  stxdw [r10-0x2e8], r5
  stxdw [r10-0x2c0], r0
  stxdw [r10-0x2c8], r4
  stxdw [r10-0x2d0], r3
  stxdw [r10-0x2f8], r1
  stxdw [r10-0x300], r6
  stxdw [r10-0x308], r7
  jeq r2, 0x0, jmp_3ae78
  mov64 r6, r2
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r1, [r1+0x0]
  lddw r3, 0x300008000
  jeq r1, 0x0, jmp_39b68
  mov64 r3, r1

jmp_39b68:
  mov64 r5, r3
  mov64 r2, r6
  sub64 r5, r2
  mov64 r1, 0x0
  mov64 r7, 0x1
  mov64 r0, 0x1
  jle r5, r3, jmp_39bd8
  ldxdw r3, [r10-0x2c8]
  ldxdw r4, [r10-0x2d0]
  jeq r0, 0x0, jmp_39bf8

jmp_39bb8:
  lddw r5, 0x300000007
  jgt r1, r5, jmp_39c18
  ja jmp_39a70

jmp_39bd8:
  mov64 r0, 0x0
  ldxdw r3, [r10-0x2c8]
  ldxdw r4, [r10-0x2d0]
  jne r0, 0x0, jmp_39bb8

jmp_39bf8:
  mov64 r1, r5
  lddw r5, 0x300000007
  jle r1, r5, jmp_39a70

jmp_39c18:
  lddw r5, 0x300000000
  stxdw [r5+0x0], r1
  stxdw [r10-0x288], r1
  stxdw [r10-0x290], r2
  stdw [r10-0x280], 0x0
  jle r2, 0x7, jmp_3ae90
  mov64 r7, 0x0

jmp_39c58:
  mov64 r5, r1
  add64 r5, r7
  lddw r0, 0x2c764f0bafcf5f85
  stxdw [r5+0x0], r0
  add64 r7, 0x8
  stxdw [r10-0x280], r7
  sub64 r2, r7
  jgt r3, r2, jmp_3b0f0

jmp_39ca0:
  add64 r1, r7
  mov64 r2, r4
  mov64 r6, r3
  call fn_d23d0
  add64 r7, r6
  stxdw [r10-0x280], r7
  lddw r1, data_2b2d
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x210], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x218], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x220], r2
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x228], r1
  call fn_b1c08
  lddw r1, 0x300000000
  ldxdw r2, [r1+0x0]
  mov64 r3, 0x0
  mov64 r4, 0x1
  mov64 r1, r2
  add64 r1, -0xee
  jgt r1, r2, jmp_39d70
  mov64 r4, 0x0

jmp_39d70:
  ldxdw r5, [r10-0x2c0]
  ldxdw r7, [r10-0x2e0]
  ldxdw r0, [r10-0x2e8]
  ldxdw r6, [r10-0x2f0]
  jeq r4, 0x0, jmp_3ad98
  lddw r1, 0x300007f12
  jne r2, 0x0, jmp_3adb8

jmp_39db0:
  lddw r2, 0x300000008
  jlt r1, r2, jmp_3add8

jmp_39dc8:
  lddw r2, 0x300000000
  stxdw [r2+0x0], r1
  ldxdw r2, [r5+0x0]
  ldxdw r2, [r2+0x0]
  ldxdw r4, [r9+0x0]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x1f0], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x1f8], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x200], r3
  stxdw [r10-0x310], r4
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x208], r3
  stxdw [r10-0x2d8], r8
  ldxdw r4, [r8+0x0]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x1d0], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x1d8], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x1e0], r3
  stxdw [r10-0x318], r4
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x1e8], r3
  ldxdw r4, [r6+0x0]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x60], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x68], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x70], r3
  stxdw [r10-0x320], r4
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x78], r3
  ldxdw r4, [r0+0x0]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x8], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x10], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x18], r3
  stxdw [r10-0x328], r4
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x20], r3
  ldxdw r3, [r5+0x18]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r3+0x18]
  stxdw [r10-0x40], r4
  ldxdw r4, [r3+0x10]
  stxdw [r10-0x48], r4
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x50], r4
  ldxdw r3, [r3+0x0]
  stxdw [r10-0x58], r3
  ldxdw r4, [r7+0x0]
  ldxdw r3, [r4+0x18]
  stxdw [r10-0x1b0], r3
  ldxdw r3, [r4+0x10]
  stxdw [r10-0x1b8], r3
  ldxdw r3, [r4+0x8]
  stxdw [r10-0x1c0], r3
  stxdw [r10-0x330], r4
  ldxdw r3, [r4+0x0]
  stxdw [r10-0x1c8], r3
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  mov64 r8, r5
  ldxdw r5, [r2+0x10]
  ldxdw r2, [r2+0x18]
  stxdw [r1+0x18], r2
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stxdw [r1+0x0], r3
  sth [r1+0x20], 0x101
  ldxdw r2, [r10-0x208]
  stxdw [r1+0x22], r2
  ldxdw r2, [r10-0x200]
  stxdw [r1+0x2a], r2
  ldxdw r2, [r10-0x1f8]
  stxdw [r1+0x32], r2
  ldxdw r2, [r10-0x1f0]
  stxdw [r1+0x3a], r2
  sth [r1+0x42], 0x0
  ldxdw r2, [r10-0x1e8]
  stxdw [r1+0x44], r2
  ldxdw r2, [r10-0x1e0]
  stxdw [r1+0x4c], r2
  ldxdw r2, [r10-0x1d8]
  stxdw [r1+0x54], r2
  ldxdw r2, [r10-0x1d0]
  stxdw [r1+0x5c], r2
  sth [r1+0x64], 0x0
  ldxdw r2, [r10-0x60]
  stxdw [r1+0x7e], r2
  ldxdw r2, [r10-0x68]
  stxdw [r1+0x76], r2
  ldxdw r2, [r10-0x70]
  stxdw [r1+0x6e], r2
  ldxdw r2, [r10-0x78]
  stxdw [r1+0x66], r2
  sth [r1+0x86], 0x100
  ldxdw r2, [r10-0x8]
  stxdw [r1+0xa0], r2
  ldxdw r2, [r10-0x10]
  stxdw [r1+0x98], r2
  ldxdw r2, [r10-0x18]
  stxdw [r1+0x90], r2
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x88], r2
  sth [r1+0xa8], 0x101
  ldxdw r2, [r10-0x40]
  stxdw [r1+0xc2], r2
  ldxdw r2, [r10-0x48]
  stxdw [r1+0xba], r2
  ldxdw r2, [r10-0x50]
  stxdw [r1+0xb2], r2
  ldxdw r2, [r10-0x58]
  stxdw [r1+0xaa], r2
  sth [r1+0xca], 0x0
  ldxdw r2, [r10-0x1b0]
  stxdw [r1+0xe4], r2
  ldxdw r2, [r10-0x1b8]
  stxdw [r1+0xdc], r2
  ldxdw r2, [r10-0x1c0]
  stxdw [r1+0xd4], r2
  ldxdw r2, [r10-0x1c8]
  stxdw [r1+0xcc], r2
  sth [r1+0xec], 0x1
  ldxdw r2, [r10-0x290]
  stxdw [r10-0x260], r2
  ldxdw r2, [r10-0x288]
  stxdw [r10-0x258], r2
  ldxdw r2, [r10-0x280]
  stxdw [r10-0x250], r2
  ldxdw r2, [r10-0x228]
  stxdw [r10-0x248], r2
  ldxdw r2, [r10-0x220]
  stxdw [r10-0x240], r2
  ldxdw r2, [r10-0x218]
  stxdw [r10-0x238], r2
  ldxdw r2, [r10-0x210]
  stxdw [r10-0x230], r2
  stxdw [r10-0x270], r1
  stdw [r10-0x268], 0x7
  stdw [r10-0x278], 0x7
  ldxdw r1, [r8+0x0]
  ldxdw r5, [r1+0x8]
  ldxdw r2, [r5+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_3a298
  mov64 r3, 0x0

jmp_3a298:
  ldxdw r4, [r1+0x0]
  stxdw [r10-0x338], r4
  stxdw [r5+0x0], r2
  and64 r3, 0x1
  jne r3, 0x0, jmp_3aef8
  stxdw [r10-0x340], r5
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x2c8], r2
  ldxdw r2, [r2+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x2d8]
  jeq r2, 0x0, jmp_3a308
  mov64 r3, 0x0

jmp_3a308:
  ldxdw r5, [r10-0x2c8]
  stxdw [r5+0x0], r2
  jeq r3, 0x1, jmp_3aef8
  ldxdw r5, [r9+0x8]
  ldxdw r2, [r5+0x0]
  add64 r2, 0x1
  mov64 r3, 0x1
  jeq r2, 0x0, jmp_3a350
  mov64 r3, 0x0

jmp_3a350:
  ldxb r8, [r1+0x2a]
  stxdw [r10-0x368], r8
  ldxb r8, [r1+0x29]
  stxdw [r10-0x360], r8
  ldxb r8, [r1+0x28]
  stxdw [r10-0x358], r8
  ldxdw r8, [r1+0x20]
  stxdw [r10-0x350], r8
  ldxdw r1, [r1+0x18]
  stxdw [r10-0x348], r1
  stxdw [r5+0x0], r2
  jeq r3, 0x1, jmp_3aef8
  ldxdw r3, [r9+0x10]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a3e0
  mov64 r2, 0x0

jmp_3a3e0:
  stxdw [r10-0x370], r3
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  mov64 r8, r7
  ldxdw r3, [r4+0x8]
  ldxdw r1, [r3+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a430
  mov64 r2, 0x0

jmp_3a430:
  ldxb r7, [r9+0x2a]
  stxdw [r10-0x390], r7
  ldxb r7, [r9+0x29]
  stxdw [r10-0x388], r7
  ldxb r7, [r9+0x28]
  stxdw [r10-0x380], r7
  ldxdw r7, [r9+0x20]
  stxdw [r10-0x378], r7
  ldxdw r9, [r9+0x18]
  stxdw [r3+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  ldxdw r7, [r4+0x10]
  ldxdw r1, [r7+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a4b8
  mov64 r2, 0x0

jmp_3a4b8:
  stxdw [r10-0x398], r7
  stxdw [r7+0x0], r1
  mov64 r7, r8
  jeq r2, 0x1, jmp_3aef8
  stxdw [r10-0x2d0], r3
  stxdw [r10-0x3a0], r9
  ldxdw r8, [r6+0x8]
  ldxdw r1, [r8+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a518
  mov64 r2, 0x0

jmp_3a518:
  ldxb r9, [r4+0x2a]
  stxdw [r10-0x3c0], r9
  ldxb r9, [r4+0x29]
  stxdw [r10-0x3b8], r9
  ldxb r9, [r4+0x28]
  stxdw [r10-0x3b0], r9
  ldxdw r9, [r4+0x20]
  stxdw [r10-0x3a8], r9
  ldxdw r3, [r4+0x18]
  stxdw [r8+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  ldxdw r9, [r6+0x10]
  ldxdw r1, [r9+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a5a0
  mov64 r2, 0x0

jmp_3a5a0:
  mov64 r4, r5
  stxdw [r9+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  mov64 r5, r0
  ldxdw r1, [r0+0x8]
  stxdw [r10-0x2d8], r1
  ldxdw r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a5f8
  mov64 r2, 0x0

jmp_3a5f8:
  ldxb r0, [r6+0x2a]
  stxdw [r10-0x3e0], r0
  ldxb r0, [r6+0x29]
  stxdw [r10-0x3d8], r0
  ldxb r0, [r6+0x28]
  stxdw [r10-0x3d0], r0
  ldxdw r0, [r6+0x20]
  stxdw [r10-0x3c8], r0
  ldxdw r6, [r6+0x18]
  stxdw [r10-0x2f0], r6
  ldxdw r6, [r10-0x2d8]
  stxdw [r6+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  mov64 r0, r5
  ldxdw r6, [r0+0x10]
  ldxdw r1, [r6+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_3a698
  mov64 r2, 0x0

jmp_3a698:
  stxdw [r10-0x3f0], r3
  stxdw [r10-0x3e8], r4
  stxdw [r6+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  ldxdw r1, [r10-0x2c0]
  ldxdw r5, [r1+0x18]
  ldxdw r4, [r5+0x8]
  ldxdw r1, [r4+0x0]
  add64 r1, 0x1
  mov64 r2, 0x1
  ldxdw r3, [r10-0x2d0]
  jeq r1, 0x0, jmp_3a700
  mov64 r2, 0x0

jmp_3a700:
  ldxb r3, [r0+0x2a]
  stxdw [r10-0x408], r3
  ldxb r3, [r0+0x29]
  stxdw [r10-0x400], r3
  ldxb r3, [r0+0x28]
  stxdw [r10-0x3f8], r3
  ldxdw r3, [r0+0x20]
  stxdw [r10-0x2c0], r3
  ldxdw r0, [r0+0x18]
  ldxdw r3, [r5+0x0]
  stxdw [r10-0x2e8], r3
  stxdw [r4+0x0], r1
  jeq r2, 0x1, jmp_3aef8
  ldxdw r2, [r5+0x10]
  ldxdw r1, [r2+0x0]
  add64 r1, 0x1
  mov64 r3, 0x1
  jeq r1, 0x0, jmp_3a798
  mov64 r3, 0x0

jmp_3a798:
  stxdw [r10-0x418], r0
  stxdw [r10-0x410], r9
  stxdw [r2+0x0], r1
  jeq r3, 0x1, jmp_3aef8
  stxdw [r10-0x428], r4
  stxdw [r10-0x420], r8
  ldxdw r9, [r7+0x8]
  ldxdw r3, [r9+0x0]
  add64 r3, 0x1
  mov64 r0, 0x1
  jeq r3, 0x0, jmp_3a7f8
  mov64 r0, 0x0

jmp_3a7f8:
  ldxb r1, [r5+0x2a]
  stxdw [r10-0x438], r1
  ldxb r1, [r5+0x29]
  stxdw [r10-0x430], r1
  ldxb r8, [r5+0x28]
  ldxdw r1, [r5+0x20]
  ldxdw r4, [r5+0x18]
  stxdw [r9+0x0], r3
  jeq r0, 0x1, jmp_3aef8
  stxdw [r10-0x448], r8
  stxdw [r10-0x440], r1
  ldxdw r3, [r7+0x10]
  ldxdw r0, [r3+0x0]
  add64 r0, 0x1
  mov64 r1, 0x1
  jeq r0, 0x0, jmp_3a880
  mov64 r1, 0x0

jmp_3a880:
  mov64 r8, r6
  stxdw [r3+0x0], r0
  jeq r1, 0x1, jmp_3aef8
  ldxdw r1, [r7+0x18]
  ldxdw r0, [r7+0x20]
  ldxb r5, [r7+0x28]
  ldxb r6, [r7+0x29]
  ldxb r7, [r7+0x2a]
  stxb [r10-0x7e], r7
  stxb [r10-0x7f], r6
  stxb [r10-0x80], r5
  stxdw [r10-0x88], r0
  stxdw [r10-0x90], r1
  stxdw [r10-0x98], r3
  stxdw [r10-0xa0], r9
  ldxdw r1, [r10-0x330]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x438]
  stxb [r10-0xae], r1
  ldxdw r1, [r10-0x430]
  stxb [r10-0xaf], r1
  ldxdw r1, [r10-0x448]
  stxb [r10-0xb0], r1
  ldxdw r1, [r10-0x440]
  stxdw [r10-0xb8], r1
  stxdw [r10-0xc0], r4
  stxdw [r10-0xc8], r2
  ldxdw r1, [r10-0x428]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x2e8]
  stxdw [r10-0xd8], r1
  ldxdw r1, [r10-0x408]
  stxb [r10-0xde], r1
  ldxdw r1, [r10-0x400]
  stxb [r10-0xdf], r1
  ldxdw r1, [r10-0x3f8]
  stxb [r10-0xe0], r1
  ldxdw r1, [r10-0x2c0]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x418]
  stxdw [r10-0xf0], r1
  stxdw [r10-0xf8], r8
  ldxdw r1, [r10-0x2d8]
  stxdw [r10-0x100], r1
  ldxdw r1, [r10-0x328]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x3e0]
  stxb [r10-0x10e], r1
  ldxdw r1, [r10-0x3d8]
  stxb [r10-0x10f], r1
  ldxdw r1, [r10-0x3d0]
  stxb [r10-0x110], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x2f0]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x410]
  stxdw [r10-0x128], r1
  ldxdw r1, [r10-0x420]
  stxdw [r10-0x130], r1
  ldxdw r1, [r10-0x320]
  stxdw [r10-0x138], r1
  ldxdw r1, [r10-0x3c0]
  stxb [r10-0x13e], r1
  ldxdw r1, [r10-0x3b8]
  stxb [r10-0x13f], r1
  ldxdw r1, [r10-0x3b0]
  stxb [r10-0x140], r1
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x148], r1
  ldxdw r1, [r10-0x3f0]
  stxdw [r10-0x150], r1
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x158], r1
  ldxdw r1, [r10-0x2d0]
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0x318]
  stxdw [r10-0x168], r1
  ldxdw r1, [r10-0x390]
  stxb [r10-0x16e], r1
  ldxdw r1, [r10-0x388]
  stxb [r10-0x16f], r1
  ldxdw r1, [r10-0x380]
  stxb [r10-0x170], r1
  ldxdw r1, [r10-0x378]
  stxdw [r10-0x178], r1
  ldxdw r1, [r10-0x3a0]
  stxdw [r10-0x180], r1
  ldxdw r1, [r10-0x370]
  stxdw [r10-0x188], r1
  ldxdw r1, [r10-0x3e8]
  stxdw [r10-0x190], r1
  ldxdw r1, [r10-0x310]
  stxdw [r10-0x198], r1
  ldxdw r1, [r10-0x368]
  stxb [r10-0x19e], r1
  ldxdw r1, [r10-0x360]
  stxb [r10-0x19f], r1
  ldxdw r1, [r10-0x358]
  stxb [r10-0x1a0], r1
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r10-0x348]
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r10-0x2c8]
  stxdw [r10-0x1b8], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x1c0], r1
  ldxdw r1, [r10-0x338]
  stxdw [r10-0x1c8], r1
  mov64 r1, r10
  add64 r1, -0x21
  stxdw [r10-0x38], r1
  ldxdw r1, [r10-0x308]
  stxdw [r10-0x48], r1
  lddw r1, str_1b5a
  stxdw [r10-0x58], r1
  ldxdw r1, [r10-0x300]
  stxb [r10-0x21], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x78], r1
  stdw [r10-0x30], 0x1
  stdw [r10-0x40], 0x20
  stdw [r10-0x50], 0xa
  mov64 r1, r10
  add64 r1, -0x228
  stxdw [r10-0x10], r1
  lddw r1, str_1b64
  stxdw [r10-0x20], r1
  ldxdw r1, [r10-0x2f8]
  stxb [r10-0x228], r1
  stdw [r10-0x60], 0x2
  stdw [r10-0x70], 0x3
  stdw [r10-0x8], 0x1
  stdw [r10-0x18], 0x9
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x1000], r1
  stdw [r10-0xff8], 0x2
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r2, r10
  add64 r2, -0x278
  mov64 r3, r10
  add64 r3, -0x1c8
  mov64 r5, r10
  mov64 r4, 0x7
  call fn_c2698
  ldxdw r1, [r10-0x208]
  lddw r2, -0x7fffffffffffffe6
  jne r1, r2, jmp_3adf0
  mov64 r1, r10
  add64 r1, -0x1c8
  call fn_a690
  mov64 r7, 0x2
  ja jmp_3ae68

jmp_3ad98:
  mov64 r3, r1
  lddw r1, 0x300007f12
  jeq r2, 0x0, jmp_39db0

jmp_3adb8:
  mov64 r1, r3
  lddw r2, 0x300000008
  jge r1, r2, jmp_39dc8

jmp_3add8:
  mov64 r1, 0x1
  mov64 r2, 0xee
  call fn_cb058

jmp_3adf0:
  ldxdw r2, [r10-0x1f8]
  stxdw [r10-0x1d8], r2
  ldxdw r2, [r10-0x200]
  stxdw [r10-0x1e0], r2
  stxdw [r10-0x1e8], r1
  mov64 r1, r10
  add64 r1, -0x2b0
  mov64 r2, r10
  add64 r2, -0x1e8
  call fn_be7f0
  ldxdw r6, [r10-0x2a8]
  ldxdw r7, [r10-0x2b0]
  mov64 r1, r10
  add64 r1, -0x1c8
  call fn_a690

jmp_3ae68:
  ldxdw r8, [r10-0x2b8]
  ja jmp_3b088

jmp_3ae78:
  stdw [r10-0x280], 0x0
  stdw [r10-0x288], 0x1
  stdw [r10-0x290], 0x0

jmp_3ae90:
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, 0x0
  mov64 r3, 0x8
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  ldxdw r4, [r10-0x2d0]
  ldxdw r3, [r10-0x2c8]
  ldxdw r2, [r10-0x290]
  ldxdw r1, [r10-0x288]
  ldxdw r7, [r10-0x280]
  ja jmp_39c58

jmp_3aef8:
  call abort

jmp_3af00:
  mov64 r1, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_39a58

jmp_3af18:
  stw [r10-0x78], 0x1
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r7, r10
  add64 r7, -0x78
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x48], 0x0
  stdw [r10-0x50], 0x1
  stdw [r10-0x58], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x270], r1
  mov64 r1, r10
  add64 r1, -0x58
  stxdw [r10-0x278], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x268], r1
  mov64 r2, r10
  add64 r2, -0x278
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_3b0a0
  ldxdw r1, [r10-0x48]
  stxdw [r10-0x180], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0x188], r1
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x190], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0x1a0], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x198], r1
  stw [r10-0x130], 0x1771
  stb [r10-0x178], 0x2
  stdw [r10-0x1c8], 0x2
  mov64 r1, r10
  add64 r1, -0x2a0
  mov64 r2, r10
  add64 r2, -0x1c8
  call fn_be760
  ldxdw r6, [r10-0x298]
  ldxdw r7, [r10-0x2a0]

jmp_3b088:
  stxdw [r8+0x8], r6
  stxdw [r8+0x0], r7
  exit

jmp_3b0a0:
  mov64 r3, r10
  add64 r3, -0x1c8
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_3b0f0:
  mov64 r1, r10
  add64 r1, -0x290
  mov64 r2, r7
  mov64 r4, 0x1
  mov64 r5, 0x1
  call fn_c7b0
  ldxdw r4, [r10-0x2d0]
  ldxdw r3, [r10-0x2c8]
  ldxdw r1, [r10-0x288]
  ldxdw r7, [r10-0x280]
  ja jmp_39ca0

fn_3b148:
  mov64 r8, r4
  mov64 r6, r1
  mov64 r9, r2
  add64 r9, 0x10
  ldxdw r1, [r2+0x10]
  lddw r4, 0x7fffffffffffffff
  jge r1, r4, jmp_3b228
  stxdw [r10-0x1b0], r3
  add64 r1, 0x1
  stxdw [r2+0x10], r1
  ldxdw r1, [r2+0x18]
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x100], r2
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x108
  call fn_b2678
  ldxb r1, [r10-0x70]
  jne r1, 0x2, jmp_3b288
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xf0]
  jeq r2, 0x0, jmp_3b2d8
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_3b2e0

jmp_3b228:
  stxdw [r10-0xe0], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x118]
  ja jmp_3bca0

jmp_3b288:
  ldxdw r1, [r10-0xb0]
  jsle r1, 0x0, jmp_3b458
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  stxdw [r10-0x1b8], r1
  jeq r8, 0x0, jmp_3b5f0
  mul64 r8, 0x190
  add64 r8, 0x3e7
  div64 r8, 0x3e8
  ja jmp_3b5f8

jmp_3b2d8:
  ldxdw r1, [r1+0x0]

jmp_3b2e0:
  stw [r10-0xf4], 0x39
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_3bd38
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x17a9
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1a0]
  ldxdw r2, [r10-0x1a8]
  ja jmp_3bc88

jmp_3b458:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_3bd38
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x259
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x128]
  ja jmp_3bc88

jmp_3b5f0:
  mov64 r8, 0x50

jmp_3b5f8:
  ldxdw r7, [r10-0x98]
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x1c0], r1
  mov64 r1, r10
  add64 r1, -0xf0
  call fn_c2a08
  ldxdw r1, [r10-0xf0]
  jne r1, 0x1, jmp_3b6a8
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xe0]
  ldxdw r3, [r10-0xd8]
  stxdw [r10-0xe0], r3
  stxdw [r10-0xe8], r2
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x190]
  ldxdw r2, [r10-0x198]
  ja jmp_3bc88

jmp_3b6a8:
  mov64 r3, 0x1
  mov64 r2, 0x1
  jsle r7, 0x0, jmp_3b868
  ldxdw r4, [r10-0xc8]
  mov64 r1, r4
  sub64 r1, r7
  jsge r1, r4, jmp_3b890

jmp_3b6e0:
  xor64 r2, r3
  and64 r2, 0x1
  jne r2, 0x0, jmp_3b8b0

jmp_3b6f8:
  jslt r1, 0x0, jmp_3b8c8
  jsgt r1, r8, jmp_3b8c8
  mov64 r1, r10
  add64 r1, -0x138
  ldxdw r7, [r10-0x1c0]
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, 0x32
  mov64 r5, 0x0
  call fn_d4490
  mov64 r2, 0x1
  ldxdw r3, [r10-0x138]
  mov64 r1, 0x1
  ldxdw r4, [r10-0x1b8]
  jgt r3, r4, jmp_3ba60
  ldxdw r3, [r10-0x130]
  jne r3, 0x0, jmp_3ba78

jmp_3b780:
  jne r3, 0x0, jmp_3ba88

jmp_3b788:
  and64 r1, 0x1
  jne r1, 0x0, jmp_3baa0

jmp_3b798:
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_16e8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16e8
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x26d
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x17ad
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x178]
  ja jmp_3bc88

jmp_3b868:
  mov64 r2, 0x0
  ldxdw r4, [r10-0xc8]
  mov64 r1, r4
  sub64 r1, r7
  jslt r1, r4, jmp_3b6e0

jmp_3b890:
  mov64 r3, 0x0
  xor64 r2, r3
  and64 r2, 0x1
  jeq r2, 0x0, jmp_3b6f8

jmp_3b8b0:
  lddw r1, data_6578
  call fn_d0810

jmp_3b8c8:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_168c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_168c
  call fn_5a268
  jne r0, 0x0, jmp_3bd38
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x179f
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x263
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x180]
  ldxdw r2, [r10-0x188]
  ja jmp_3bc88

jmp_3ba60:
  mov64 r1, 0x0
  ldxdw r3, [r10-0x130]
  jeq r3, 0x0, jmp_3b780

jmp_3ba78:
  mov64 r2, 0x0
  jeq r3, 0x0, jmp_3b788

jmp_3ba88:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3b798

jmp_3baa0:
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r4, [r10-0x1b8]
  ldxdw r1, [r10-0x148]
  mov64 r2, r4
  add64 r2, r1
  mov64 r1, 0x1
  mov64 r5, 0x1
  jlt r2, r4, jmp_3bb18
  mov64 r5, 0x0

jmp_3bb18:
  ldxdw r3, [r10-0x140]
  add64 r3, r5
  jeq r2, 0x0, jmp_3bb38
  mov64 r1, 0x0

jmp_3bb38:
  sub64 r3, r1
  add64 r2, -0x1
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r5, 0x0
  call fn_d45f0
  ldxdw r2, [r10-0x1b0]
  and64 r2, 0xffff
  mov64 r3, r2
  jge r2, 0x3e8, jmp_3bcb8
  mov64 r1, 0xc8
  jne r2, 0x0, jmp_3bcd0

jmp_3bb98:
  ldxdw r2, [r10-0x158]
  jge r2, 0xffff, jmp_3bce8

jmp_3bba8:
  ldxdw r3, [r10-0x150]
  jne r3, 0x0, jmp_3bd00

jmp_3bbb8:
  jge r1, r2, jmp_3bd10

jmp_3bbc0:
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_16e8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16e8
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x27c
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x17ad
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r10-0x168]

jmp_3bc88:
  ldxdw r3, [r9+0x0]
  add64 r3, -0x1
  stxdw [r9+0x0], r3

jmp_3bca0:
  stxdw [r6+0x8], r1
  stxdw [r6+0x0], r2
  exit

jmp_3bcb8:
  mov64 r3, 0x3e8
  mov64 r1, 0xc8
  jeq r2, 0x0, jmp_3bb98

jmp_3bcd0:
  mov64 r1, r3
  ldxdw r2, [r10-0x158]
  jlt r2, 0xffff, jmp_3bba8

jmp_3bce8:
  mov64 r2, 0xffff
  ldxdw r3, [r10-0x150]
  jeq r3, 0x0, jmp_3bbb8

jmp_3bd00:
  mov64 r2, 0xffff
  jlt r1, r2, jmp_3bbc0

jmp_3bd10:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1
  mov64 r2, 0x2
  ja jmp_3bca0

jmp_3bd38:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_3bd88:
  mov64 r6, r1
  lddw r1, data_2b2d
  ldxdw r0, [r1+0x0]
  ldxdw r7, [r3+0x0]
  jne r7, r0, jmp_3be18
  ldxdw r1, [r1+0x8]
  ldxdw r0, [r3+0x8]
  jne r0, r1, jmp_3be18
  lddw r0, data_2b2d
  ldxdw r1, [r0+0x10]
  ldxdw r7, [r3+0x10]
  jne r7, r1, jmp_3be18
  mov64 r1, 0x0
  ldxdw r0, [r0+0x18]
  ldxdw r3, [r3+0x18]
  jeq r3, r0, jmp_3be20

jmp_3be18:
  mov64 r1, 0x1

jmp_3be20:
  jeq r1, 0x0, jmp_3bfc0
  mov64 r1, r10
  add64 r1, -0x38
  lddw r2, data_1690
  call fn_594a8
  stdw [r10-0x10], 0x0
  stdw [r10-0x18], 0x1
  stdw [r10-0x20], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x188], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x190], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x180], r1
  mov64 r2, r10
  add64 r2, -0x190
  lddw r1, data_1690
  call fn_5a268
  jne r0, 0x0, jmp_3c768
  ldxdw r1, [r10-0x10]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17b3
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x294
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1a0]
  ldxdw r2, [r10-0x198]
  ja jmp_3c0f0

jmp_3bfc0:
  mov64 r8, r2
  add64 r8, 0x10
  ldxdw r1, [r2+0x10]
  lddw r3, 0x7fffffffffffffff
  jge r1, r3, jmp_3c098
  mov64 r7, r4
  stxdw [r10-0x1f8], r5
  add64 r1, 0x1
  stxdw [r2+0x10], r1
  ldxdw r1, [r2+0x18]
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x100], r2
  stxdw [r10-0x108], r1
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x108
  call fn_b2678
  ldxb r9, [r10-0x70]
  jne r9, 0x2, jmp_3c108
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xf0]
  jeq r2, 0x0, jmp_3c370
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_3c378

jmp_3c098:
  stxdw [r10-0xe0], r8
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x1b0]
  ldxdw r2, [r10-0x1a8]

jmp_3c0f0:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_3c100:
  exit

jmp_3c108:
  stxdw [r10-0x200], r8
  ldxw r8, [r10-0xf0]
  mov64 r1, r10
  add64 r1, -0x18c
  mov64 r2, r10
  add64 r2, -0xec
  mov64 r3, 0x54
  call fn_d23d0
  stxw [r10-0x190], r8
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r10-0x190]
  jne r2, r1, jmp_3c1b8
  ldxdw r1, [r7+0x8]
  ldxdw r2, [r10-0x188]
  jne r2, r1, jmp_3c1b8
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r10-0x180]
  jne r2, r1, jmp_3c1b8
  mov64 r2, 0x0
  ldxdw r1, [r7+0x18]
  ldxdw r3, [r10-0x178]
  jeq r3, r1, jmp_3c1c0

jmp_3c1b8:
  mov64 r2, 0x1

jmp_3c1c0:
  ldxdw r1, [r10-0x1f8]
  jeq r2, 0x0, jmp_3c518
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_169c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_169c
  call fn_5a268
  ldxdw r8, [r10-0x200]
  jne r0, 0x0, jmp_3c768
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17b4
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x2a0
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1c0]
  ldxdw r2, [r10-0x1b8]
  ja jmp_3c4e8

jmp_3c370:
  ldxdw r1, [r1+0x0]

jmp_3c378:
  stw [r10-0xf4], 0x39
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_3c768
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x17a9
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x1f0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1f0]
  ldxdw r2, [r10-0x1e8]

jmp_3c4e8:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1

jmp_3c4f8:
  ldxdw r1, [r8+0x0]
  add64 r1, -0x1
  stxdw [r8+0x0], r1
  ja jmp_3c100

jmp_3c518:
  and64 r9, 0x1
  ldxdw r8, [r10-0x200]
  jeq r9, 0x0, jmp_3c678
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r10-0x170]
  jne r3, r2, jmp_3c598
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x168]
  jne r3, r2, jmp_3c598
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0x160]
  jne r3, r2, jmp_3c598
  mov64 r2, 0x0
  ldxdw r1, [r1+0x18]
  ldxdw r3, [r10-0x158]
  jeq r3, r1, jmp_3c5a0

jmp_3c598:
  mov64 r2, 0x1

jmp_3c5a0:
  jeq r2, 0x0, jmp_3c748
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_1670
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_1670
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x2aa
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x177f
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1e0]
  ldxdw r2, [r10-0x1d8]
  ja jmp_3c4e8

jmp_3c678:
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_16b8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16b8
  call fn_9838
  lddw r1, str_1b21
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x2a5
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x17b5
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1d0]
  ldxdw r2, [r10-0x1c8]
  ja jmp_3c4e8

jmp_3c748:
  ldxdw r1, [r10-0x98]
  stxdw [r6+0x8], r1
  stdw [r6+0x0], 0x2
  ja jmp_3c4f8

jmp_3c768:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_3c7b8:
  mov64 r6, r2
  ldxdw r5, [r6+0x8]
  ldxdw r8, [r6+0x0]
  mov64 r2, r8
  or64 r2, r5
  jeq r2, 0x0, jmp_3c818
  mov64 r2, r4
  and64 r2, 0xff
  jle r2, 0x12, jmp_3c838
  lddw r2, 0x1000000001
  ja jmp_3c828

jmp_3c818:
  lddw r2, 0x2100000001

jmp_3c828:
  stxdw [r1+0x0], r2
  ja jmp_3d560

jmp_3c838:
  stxdw [r10-0x160], r5
  stxdw [r10-0x158], r1
  stxdw [r10-0x150], r3
  mov64 r9, 0x1
  mov64 r3, 0x0
  jeq r2, 0x12, jmp_3ca88
  mov64 r7, 0x12
  sub64 r7, r4
  and64 r7, 0xff
  mov64 r1, r7
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3c8b8
  mov64 r9, 0xa
  mov64 r1, r4
  and64 r1, 0xff
  jeq r1, 0x11, jmp_3ca88

jmp_3c8b8:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_3c938
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r9
  mov64 r9, r4
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_d4490
  mov64 r4, r9
  ldxdw r3, [r10-0x20]
  ldxdw r9, [r10-0x28]
  mov64 r1, r7
  and64 r1, 0x1e
  jeq r1, 0x2, jmp_3ca88

jmp_3c938:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_3c9b8
  mov64 r1, r10
  add64 r1, -0x38
  mov64 r2, r9
  mov64 r9, r4
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  mov64 r4, r9
  ldxdw r3, [r10-0x30]
  ldxdw r9, [r10-0x38]
  mov64 r1, r7
  and64 r1, 0x1c
  jeq r1, 0x4, jmp_3ca88

jmp_3c9b8:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_3ca30
  mov64 r1, r10
  add64 r1, -0x48
  mov64 r2, r9
  mov64 r9, r4
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_d4490
  mov64 r4, r9
  ldxdw r3, [r10-0x40]
  ldxdw r9, [r10-0x48]
  and64 r7, 0x18
  jeq r7, 0x8, jmp_3ca88

jmp_3ca30:
  and64 r4, 0xff
  jgt r4, 0x2, jmp_3d568
  mov64 r1, r10
  add64 r1, -0x58
  mov64 r2, r9
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r3, [r10-0x50]
  ldxdw r9, [r10-0x58]

jmp_3ca88:
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r3
  mov64 r3, 0x0
  ldxdw r7, [r10-0x150]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r2, [r10-0x70]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_3cb20
  mov64 r1, 0x0

jmp_3cb20:
  ldxdw r2, [r10-0x60]
  ldxdw r3, [r10-0x78]
  mov64 r9, r2
  add64 r9, r3
  mov64 r3, 0x1
  jlt r9, r2, jmp_3cb58
  mov64 r3, 0x0

jmp_3cb58:
  or64 r1, r3
  jne r1, 0x1, jmp_3cb90

jmp_3cb68:
  lddw r1, 0x1000000001
  ldxdw r2, [r10-0x158]
  stxdw [r2+0x0], r1
  ja jmp_3d560

jmp_3cb90:
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x150], r1
  ldxw r6, [r6+0x10]
  lsh64 r6, 0x20
  arsh64 r6, 0x20
  mov64 r7, 0x1
  mov64 r2, 0x1
  mov64 r3, 0x0
  jeq r6, 0x0, jmp_3d058
  mov64 r1, r6
  lsh64 r1, 0x20
  arsh64 r1, 0x3f
  mov64 r7, r6
  xor64 r7, r1
  sub64 r7, r1
  mov64 r1, r7
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3cc48
  mov64 r2, 0xa
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1, jmp_3d048

jmp_3cc48:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_3ccc0
  mov64 r1, r10
  add64 r1, -0x88
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffffe
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x80]
  ldxdw r2, [r10-0x88]
  jeq r4, 0x2, jmp_3d048

jmp_3ccc0:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_3cd38
  mov64 r1, r10
  add64 r1, -0x98
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffffc
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0x90]
  ldxdw r2, [r10-0x98]
  jeq r4, 0x4, jmp_3d048

jmp_3cd38:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_3cdb0
  mov64 r1, r10
  add64 r1, -0xa8
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffff8
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0xa0]
  ldxdw r2, [r10-0xa8]
  jeq r4, 0x8, jmp_3d048

jmp_3cdb0:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_3ce30
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffff0
  mov64 r4, r7
  and64 r4, r1
  ldxdw r3, [r10-0xb0]
  ldxdw r2, [r10-0xb8]
  jeq r4, 0x10, jmp_3d048

jmp_3ce30:
  mov64 r0, r3
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_3cb68
  mov64 r1, r10
  add64 r1, -0xe8
  mov64 r3, 0x0
  stxdw [r10-0x170], r2
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  stxdw [r10-0x168], r0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0xd8
  ldxdw r2, [r10-0x168]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0xc8
  ldxdw r2, [r10-0x170]
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  stxdw [r10-0x170], r1
  ldxdw r3, [r10-0xe0]
  jne r3, 0x0, jmp_3cf40
  mov64 r1, 0x0

jmp_3cf40:
  stxdw [r10-0x178], r1
  ldxdw r4, [r10-0xe8]
  ldxdw r5, [r10-0xd8]
  mov64 r3, 0x1
  ldxdw r1, [r10-0x168]
  jne r1, 0x0, jmp_3cf78
  mov64 r3, 0x0

jmp_3cf78:
  add64 r5, r4
  ldxdw r0, [r10-0xd0]
  mov64 r4, 0x1
  jne r0, 0x0, jmp_3cfa0
  mov64 r4, 0x0

jmp_3cfa0:
  ldxdw r2, [r10-0xc0]
  mov64 r0, r2
  add64 r0, r5
  mov64 r1, r0
  jlt r0, r2, jmp_3cfd8
  mov64 r2, 0x0
  stxdw [r10-0x170], r2

jmp_3cfd8:
  lddw r5, 0xffffffe0
  and64 r7, r5
  mov64 r5, r1
  jne r7, 0x20, jmp_3cb68
  or64 r3, r4
  ldxdw r1, [r10-0x178]
  or64 r3, r1
  ldxdw r1, [r10-0x170]
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_3cb68
  ldxdw r2, [r10-0xc8]
  mov64 r3, r5

jmp_3d048:
  jsle r6, -0x1, jmp_3d430
  mov64 r7, 0x1

jmp_3d058:
  stxdw [r10-0x170], r2
  stxdw [r10-0x168], r3
  mov64 r1, r10
  add64 r1, -0x108
  ldxdw r2, [r10-0x160]
  mov64 r3, 0x0
  ldxdw r6, [r10-0x150]
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0xf8
  mov64 r2, r6
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r2, [r10-0x100]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_3d138
  mov64 r1, 0x0

jmp_3d138:
  ldxdw r3, [r10-0x110]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_3d158
  mov64 r2, 0x0

jmp_3d158:
  ldxdw r3, [r10-0x108]
  ldxdw r5, [r10-0x118]
  mov64 r4, 0x1
  ldxdw r0, [r10-0x160]
  jeq r0, 0x0, jmp_3d218
  add64 r5, r3
  mov64 r3, 0x1
  jeq r9, 0x0, jmp_3d238

jmp_3d198:
  ldxdw r0, [r10-0xf0]
  mov64 r6, r0
  add64 r6, r5
  jlt r6, r0, jmp_3d1c0

jmp_3d1b8:
  mov64 r7, 0x0

jmp_3d1c0:
  and64 r3, r4
  or64 r3, r2
  or64 r3, r1
  or64 r3, r7
  and64 r3, 0x1
  ldxdw r8, [r10-0x158]
  jeq r3, 0x0, jmp_3d268

jmp_3d1f8:
  stw [r8+0x4], 0x10
  mov64 r1, 0x1
  stxw [r8+0x0], r1
  ja jmp_3d560

jmp_3d218:
  mov64 r4, 0x0
  add64 r5, r3
  mov64 r3, 0x1
  jne r9, 0x0, jmp_3d198

jmp_3d238:
  mov64 r3, 0x0
  ldxdw r0, [r10-0xf0]
  mov64 r6, r0
  add64 r6, r5
  jge r6, r0, jmp_3d1b8
  ja jmp_3d1c0

jmp_3d268:
  ldxdw r7, [r10-0xf8]
  mov64 r1, r10
  add64 r1, -0x138
  ldxdw r2, [r10-0x168]
  mov64 r3, 0x0
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r6
  mov64 r3, 0x0
  ldxdw r9, [r10-0x170]
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r9
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r3, [r10-0x130]
  mov64 r2, 0x1
  jne r3, 0x0, jmp_3d348
  mov64 r2, 0x0

jmp_3d348:
  ldxdw r4, [r10-0x140]
  mov64 r3, 0x1
  jne r4, 0x0, jmp_3d368
  mov64 r3, 0x0

jmp_3d368:
  ldxdw r4, [r10-0x138]
  ldxdw r7, [r10-0x148]
  mov64 r0, 0x1
  ldxdw r5, [r10-0x168]
  jeq r5, 0x0, jmp_3d4d8
  add64 r7, r4
  mov64 r4, 0x1
  jeq r6, 0x0, jmp_3d4f8

jmp_3d3a8:
  ldxdw r6, [r10-0x120]
  mov64 r5, r6
  add64 r5, r7
  jlt r5, r6, jmp_3d3d0

jmp_3d3c8:
  mov64 r1, 0x0

jmp_3d3d0:
  and64 r4, r0
  or64 r4, r3
  or64 r4, r2
  or64 r4, r1
  and64 r4, 0x1
  jne r4, 0x0, jmp_3d1f8
  ldxdw r1, [r10-0x128]
  stxdw [r8+0x8], r1
  stxdw [r8+0x10], r5
  mov64 r1, 0x0
  stxw [r8+0x0], r1
  ja jmp_3d560

jmp_3d430:
  stxdw [r10-0xff0], r3
  stxdw [r10-0xff8], r2
  ldxdw r1, [r10-0x160]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r5, r10
  ldxdw r2, [r10-0x150]
  mov64 r3, r9
  mov64 r4, r8
  call fn_3e5b0
  ldxdw r1, [r10-0x18]
  jeq r1, 0x0, jmp_3d528
  ldxdw r2, [r10-0x8]
  ldxdw r1, [r10-0x10]
  call fn_9cd8
  ldxdw r2, [r10-0x158]
  stw [r2+0x4], 0x10
  mov64 r1, 0x1
  stxw [r2+0x0], r1
  ja jmp_3d560

jmp_3d4d8:
  mov64 r0, 0x0
  add64 r7, r4
  mov64 r4, 0x1
  jne r6, 0x0, jmp_3d3a8

jmp_3d4f8:
  mov64 r4, 0x0
  ldxdw r6, [r10-0x120]
  mov64 r5, r6
  add64 r5, r7
  jge r5, r6, jmp_3d3c8
  ja jmp_3d3d0

jmp_3d528:
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  ldxdw r3, [r10-0x158]
  stxdw [r3+0x10], r2
  stxdw [r3+0x8], r1
  mov64 r1, 0x0
  stxw [r3+0x0], r1

jmp_3d560:
  exit

jmp_3d568:
  lddw r1, data_5e60
  call fn_d0868

fn_3d580:
  mov64 r9, r4
  stxdw [r10-0x258], r3
  stxdw [r10-0x260], r2
  mov64 r6, r1
  mov64 r1, r9
  lsh64 r1, 0x20
  mov64 r2, r1
  arsh64 r2, 0x20
  stxdw [r10-0x250], r6
  jsle r2, -0x1, jmp_3d988
  rsh64 r1, 0x20
  mov64 r8, 0x1
  mov64 r7, 0x0
  jeq r1, 0x0, jmp_3e120
  mov64 r1, r9
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3d630
  mov64 r8, 0xa
  mov64 r1, r9
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1, jmp_3e120

jmp_3d630:
  mov64 r1, r9
  and64 r1, 0x2
  jeq r1, 0x0, jmp_3d6a8
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r7, [r10-0x190]
  ldxdw r8, [r10-0x198]
  mov64 r1, r9
  and64 r1, 0x7ffffffe
  jeq r1, 0x2, jmp_3e120

jmp_3d6a8:
  mov64 r1, r9
  and64 r1, 0x4
  jeq r1, 0x0, jmp_3d720
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r7, [r10-0x1a0]
  ldxdw r8, [r10-0x1a8]
  mov64 r1, r9
  and64 r1, 0x7ffffffc
  jeq r1, 0x4, jmp_3e120

jmp_3d720:
  mov64 r1, r9
  and64 r1, 0x8
  jeq r1, 0x0, jmp_3d798
  mov64 r1, r10
  add64 r1, -0x1b8
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r7, [r10-0x1b0]
  ldxdw r8, [r10-0x1b8]
  mov64 r1, r9
  and64 r1, 0x7ffffff8
  jeq r1, 0x8, jmp_3e120

jmp_3d798:
  mov64 r1, r9
  and64 r1, 0x10
  jeq r1, 0x0, jmp_3d818
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, r8
  mov64 r3, r7
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r7, [r10-0x1c0]
  ldxdw r8, [r10-0x1c8]
  mov64 r1, r9
  and64 r1, 0x7ffffff0
  jeq r1, 0x10, jmp_3e120

jmp_3d818:
  mov64 r1, r9
  and64 r1, 0x20
  jeq r1, 0x0, jmp_3e388
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r3, [r10-0x1f0]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_3e060
  ldxdw r4, [r10-0x1f8]
  ldxdw r5, [r10-0x1e8]
  mov64 r3, 0x1
  jeq r7, 0x0, jmp_3e088

jmp_3d930:
  add64 r5, r4
  ldxdw r0, [r10-0x1e0]
  mov64 r4, 0x1
  jeq r0, 0x0, jmp_3e0b0

jmp_3d950:
  ldxdw r0, [r10-0x1d0]
  mov64 r7, r0
  add64 r7, r5
  jge r7, r0, jmp_3e0d8

jmp_3d970:
  and64 r9, 0x7fffffe0
  jeq r9, 0x20, jmp_3e0f0
  ja jmp_3e388

jmp_3d988:
  mov64 r6, r9
  neg64 r6
  mov64 r1, r6
  mov64 r7, 0x0
  and64 r1, 0x1
  jne r1, 0x0, jmp_3d9c8
  mov64 r8, 0x1
  ja jmp_3d9f8

jmp_3d9c8:
  mov64 r8, 0xa
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  lddw r1, 0xffffffff
  jeq r9, r1, jmp_3de70

jmp_3d9f8:
  mov64 r1, r6
  and64 r1, 0x2
  jeq r1, 0x0, jmp_3da80
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x64
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffffe
  mov64 r2, r6
  and64 r2, r1
  ldxdw r7, [r10-0x100]
  ldxdw r8, [r10-0x108]
  jeq r2, 0x2, jmp_3de70

jmp_3da80:
  mov64 r1, r6
  and64 r1, 0x4
  jeq r1, 0x0, jmp_3db08
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffffc
  mov64 r2, r6
  and64 r2, r1
  ldxdw r7, [r10-0x110]
  ldxdw r8, [r10-0x118]
  jeq r2, 0x4, jmp_3de70

jmp_3db08:
  mov64 r1, r6
  and64 r1, 0x8
  jeq r1, 0x0, jmp_3db90
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, 0x5f5e100
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffff8
  mov64 r2, r6
  and64 r2, r1
  ldxdw r7, [r10-0x120]
  ldxdw r8, [r10-0x128]
  jeq r2, 0x8, jmp_3de70

jmp_3db90:
  mov64 r1, r6
  and64 r1, 0x10
  jeq r1, 0x0, jmp_3dc20
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r8
  mov64 r3, r7
  lddw r4, 0x2386f26fc10000
  mov64 r5, 0x0
  call fn_d4490
  lddw r1, 0xfffffff0
  mov64 r2, r6
  and64 r2, r1
  ldxdw r7, [r10-0x130]
  ldxdw r8, [r10-0x138]
  jeq r2, 0x10, jmp_3de70

jmp_3dc20:
  mov64 r1, r6
  and64 r1, 0x20
  jeq r1, 0x0, jmp_3dee0
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, 0x4ee2d6d415b
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x158
  mov64 r2, r7
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r8
  mov64 r3, 0x0
  lddw r4, -0x7a53107f00000000
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, 0x1
  ldxdw r3, [r10-0x160]
  mov64 r2, 0x1
  jeq r3, 0x0, jmp_3dda0
  ldxdw r4, [r10-0x168]
  ldxdw r5, [r10-0x158]
  mov64 r3, 0x1
  jeq r7, 0x0, jmp_3ddc8

jmp_3dd38:
  add64 r5, r4
  ldxdw r0, [r10-0x150]
  mov64 r4, 0x1
  jeq r0, 0x0, jmp_3ddf0

jmp_3dd58:
  ldxdw r0, [r10-0x140]
  mov64 r7, r0
  add64 r7, r5
  jge r7, r0, jmp_3de18

jmp_3dd78:
  lddw r5, 0xffffffe0
  and64 r6, r5
  jeq r6, 0x20, jmp_3de40
  ja jmp_3dee0

jmp_3dda0:
  mov64 r2, 0x0
  ldxdw r4, [r10-0x168]
  ldxdw r5, [r10-0x158]
  mov64 r3, 0x1
  jne r7, 0x0, jmp_3dd38

jmp_3ddc8:
  mov64 r3, 0x0
  add64 r5, r4
  ldxdw r0, [r10-0x150]
  mov64 r4, 0x1
  jne r0, 0x0, jmp_3dd58

jmp_3ddf0:
  mov64 r4, 0x0
  ldxdw r0, [r10-0x140]
  mov64 r7, r0
  add64 r7, r5
  jlt r7, r0, jmp_3dd78

jmp_3de18:
  mov64 r1, 0x0
  lddw r5, 0xffffffe0
  and64 r6, r5
  jne r6, 0x20, jmp_3dee0

jmp_3de40:
  or64 r3, r4
  or64 r3, r2
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_3dee0
  ldxdw r8, [r10-0x148]

jmp_3de70:
  mov64 r1, r10
  add64 r1, -0x178
  ldxdw r2, [r10-0x260]
  ldxdw r3, [r10-0x258]
  mov64 r4, r8
  mov64 r5, r7
  call fn_d45f0
  ldxdw r1, [r10-0x170]
  ldxdw r6, [r10-0x250]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x178]
  stxdw [r6+0x8], r1
  mov64 r1, 0x0
  ja jmp_3e510

jmp_3dee0:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_3e560
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x188]
  ldxdw r2, [r10-0x180]
  ldxdw r6, [r10-0x250]
  ja jmp_3e4f8

jmp_3e060:
  mov64 r2, 0x0
  ldxdw r4, [r10-0x1f8]
  ldxdw r5, [r10-0x1e8]
  mov64 r3, 0x1
  jne r7, 0x0, jmp_3d930

jmp_3e088:
  mov64 r3, 0x0
  add64 r5, r4
  ldxdw r0, [r10-0x1e0]
  mov64 r4, 0x1
  jne r0, 0x0, jmp_3d950

jmp_3e0b0:
  mov64 r4, 0x0
  ldxdw r0, [r10-0x1d0]
  mov64 r7, r0
  add64 r7, r5
  jlt r7, r0, jmp_3d970

jmp_3e0d8:
  mov64 r1, 0x0
  and64 r9, 0x7fffffe0
  jne r9, 0x20, jmp_3e388

jmp_3e0f0:
  or64 r3, r4
  or64 r3, r2
  or64 r3, r1
  and64 r3, 0x1
  jne r3, 0x0, jmp_3e388
  ldxdw r8, [r10-0x1d8]

jmp_3e120:
  mov64 r1, r10
  add64 r1, -0x228
  mov64 r6, r7
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r7, [r10-0x260]
  mov64 r4, r7
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x238
  ldxdw r9, [r10-0x258]
  mov64 r2, r9
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, r7
  mov64 r3, 0x0
  mov64 r4, r8
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r2, [r10-0x220]
  mov64 r1, 0x1
  jeq r2, 0x0, jmp_3e2e0
  ldxdw r3, [r10-0x230]
  mov64 r2, 0x1
  mov64 r8, 0x1
  jeq r3, 0x0, jmp_3e308

jmp_3e218:
  ldxdw r3, [r10-0x228]
  ldxdw r0, [r10-0x238]
  mov64 r5, 0x1
  jeq r6, 0x0, jmp_3e330

jmp_3e238:
  ldxdw r7, [r10-0x250]
  add64 r0, r3
  mov64 r3, 0x1
  jeq r9, 0x0, jmp_3e358

jmp_3e258:
  ldxdw r6, [r10-0x210]
  mov64 r4, r6
  add64 r4, r0
  jlt r4, r6, jmp_3e280

jmp_3e278:
  mov64 r8, 0x0

jmp_3e280:
  and64 r3, r5
  or64 r3, r2
  or64 r3, r1
  or64 r3, r8
  and64 r3, 0x1
  jne r3, 0x0, jmp_3e520
  ldxdw r1, [r10-0x218]
  mov64 r6, r7
  stxdw [r6+0x8], r1
  stxdw [r6+0x10], r4
  mov64 r1, 0x0
  ja jmp_3e510

jmp_3e2e0:
  mov64 r1, 0x0
  ldxdw r3, [r10-0x230]
  mov64 r2, 0x1
  mov64 r8, 0x1
  jne r3, 0x0, jmp_3e218

jmp_3e308:
  mov64 r2, 0x0
  ldxdw r3, [r10-0x228]
  ldxdw r0, [r10-0x238]
  mov64 r5, 0x1
  jne r6, 0x0, jmp_3e238

jmp_3e330:
  mov64 r5, 0x0
  ldxdw r7, [r10-0x250]
  add64 r0, r3
  mov64 r3, 0x1
  jne r9, 0x0, jmp_3e258

jmp_3e358:
  mov64 r3, 0x0
  ldxdw r6, [r10-0x210]
  mov64 r4, r6
  add64 r4, r0
  jge r4, r6, jmp_3e278
  ja jmp_3e280

jmp_3e388:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_3e560
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x208
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x208]
  ldxdw r2, [r10-0x200]

jmp_3e4f8:
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  mov64 r1, 0x1

jmp_3e510:
  stxdw [r6+0x0], r1
  exit

jmp_3e520:
  mov64 r1, r10
  add64 r1, -0x248
  mov64 r2, 0x10
  call fn_5a078
  ldxdw r1, [r10-0x248]
  ldxdw r2, [r10-0x240]
  mov64 r6, r7
  ja jmp_3e4f8

jmp_3e560:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_3e5b0:
  mov64 r7, r4
  mov64 r4, r3
  mov64 r6, r2
  stxdw [r10-0x258], r1
  ldxdw r9, [r5-0xff0]
  ldxdw r2, [r5-0xff8]
  mov64 r1, r2
  or64 r1, r9
  jeq r1, 0x0, jmp_3e778
  ldxdw r8, [r5-0x1000]
  mov64 r1, r10
  add64 r1, -0x128
  stxdw [r10-0x238], r2
  mov64 r2, r7
  mov64 r3, 0x0
  stxdw [r10-0x220], r4
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r7
  mov64 r3, 0x0
  ldxdw r6, [r10-0x220]
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_d4490
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, r6
  mov64 r5, 0x0
  call fn_d4490
  lddw r2, 0x218a392cd3d5dbf
  lddw r1, data_0040
  ldxdw r6, [r10-0x238]
  jne r6, 0x0, jmp_3e8f0
  mov64 r3, r9
  neg64 r3
  mov64 r4, r9
  and64 r4, r3
  mul64 r4, r2
  rsh64 r4, 0x3a
  add64 r1, r4
  ldxb r8, [r1+0x0]
  add64 r8, 0x40
  ja jmp_3e930

jmp_3e778:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r6, r10
  add64 r6, -0xf4
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_3f4d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x218
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x218]
  ldxdw r2, [r10-0x210]
  ja jmp_3f4a0

jmp_3e8f0:
  mov64 r3, r6
  neg64 r3
  mov64 r4, r6
  and64 r4, r3
  mul64 r4, r2
  rsh64 r4, 0x3a
  add64 r1, r4
  ldxb r8, [r1+0x0]

jmp_3e930:
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r6
  mov64 r3, r9
  mov64 r4, r8
  call fn_d47e0
  ldxdw r3, [r10-0x120]
  ldxdw r1, [r10-0x108]
  mov64 r5, r3
  add64 r5, r1
  ldxdw r1, [r10-0x138]
  mov64 r2, r5
  add64 r2, r1
  mov64 r1, 0x1
  mov64 r4, 0x1
  stxdw [r10-0x240], r2
  jlt r2, r5, jmp_3e9c0
  mov64 r4, 0x0

jmp_3e9c0:
  mov64 r2, 0x1
  jlt r5, r3, jmp_3e9d8
  mov64 r2, 0x0

jmp_3e9d8:
  ldxdw r3, [r10-0x118]
  ldxdw r0, [r10-0x100]
  mov64 r5, r0
  add64 r5, r3
  mov64 r3, 0x1
  jlt r5, r0, jmp_3ea10
  mov64 r3, 0x0

jmp_3ea10:
  add64 r2, r4
  ldxdw r4, [r10-0x130]
  mov64 r0, r5
  add64 r0, r4
  mov64 r4, 0x1
  jlt r0, r5, jmp_3ea48
  mov64 r4, 0x0

jmp_3ea48:
  mov64 r5, r0
  add64 r5, r2
  jlt r5, r0, jmp_3ea68
  mov64 r1, 0x0

jmp_3ea68:
  ldxdw r0, [r10-0x110]
  add64 r0, r3
  add64 r0, r4
  add64 r0, r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x248], r1
  ldxdw r7, [r10-0x140]
  jeq r7, 0x0, jmp_3edd0
  mov64 r2, 0x1
  mov64 r1, 0x1
  jlt r5, r6, jmp_3efe0
  jlt r0, r9, jmp_3eff0

jmp_3eac8:
  jne r0, r9, jmp_3f000

jmp_3ead0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_3f018

jmp_3eae0:
  mov64 r1, 0x0
  stxdw [r10-0x220], r1
  mov64 r8, 0x7f
  stxdw [r10-0x228], r1
  mov64 r7, r0
  stxdw [r10-0x250], r9
  ja jmp_3eba8

jmp_3eb18:
  sub64 r7, r0
  sub64 r7, r4
  ldxdw r4, [r10-0x228]
  or64 r3, r4
  ldxdw r4, [r10-0x220]
  or64 r2, r4
  sub64 r1, r5
  add64 r8, -0x1
  mov64 r4, r8
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  stxdw [r10-0x220], r2
  stxdw [r10-0x228], r3
  mov64 r5, r1
  mov64 r0, r7
  lddw r1, 0xffffffff
  jeq r4, r1, jmp_3f190

jmp_3eba8:
  stxdw [r10-0x230], r0
  mov64 r9, r8
  lsh64 r9, 0x20
  arsh64 r9, 0x20
  mov64 r1, r10
  add64 r1, -0x208
  ldxdw r2, [r10-0x248]
  ldxdw r3, [r10-0x240]
  mov64 r4, r9
  mov64 r6, r5
  call fn_d47e0
  mov64 r1, r10
  add64 r1, -0x1f8
  mov64 r2, 0x1
  mov64 r3, 0x0
  mov64 r4, r9
  ldxdw r9, [r10-0x250]
  call fn_d4738
  mov64 r1, r6
  rsh64 r1, 0x3f
  lsh64 r7, 0x1
  or64 r7, r1
  mov64 r2, 0x1
  jge r7, r9, jmp_3ec70
  mov64 r2, 0x0

jmp_3ec70:
  ldxdw r1, [r10-0x208]
  and64 r1, 0x1
  lsh64 r6, 0x1
  or64 r1, r6
  mov64 r3, 0x1
  ldxdw r6, [r10-0x238]
  jlt r1, r6, jmp_3ed08
  ldxdw r5, [r10-0x230]
  jne r7, r9, jmp_3ed20

jmp_3ecb8:
  mov64 r4, 0x1
  jsge r5, 0x0, jmp_3ed38

jmp_3ecc8:
  or64 r4, r3
  jne r4, 0x0, jmp_3ed50

jmp_3ecd8:
  mov64 r2, 0x0
  jeq r4, 0x0, jmp_3ed60

jmp_3ece8:
  ldxdw r3, [r10-0x1f0]
  mov64 r0, r9
  jeq r4, 0x0, jmp_3ed78
  ja jmp_3ed80

jmp_3ed08:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x230]
  jeq r7, r9, jmp_3ecb8

jmp_3ed20:
  mov64 r3, r2
  mov64 r4, 0x1
  jslt r5, 0x0, jmp_3ecc8

jmp_3ed38:
  mov64 r4, 0x0
  or64 r4, r3
  jeq r4, 0x0, jmp_3ecd8

jmp_3ed50:
  ldxdw r2, [r10-0x1f8]
  jne r4, 0x0, jmp_3ece8

jmp_3ed60:
  mov64 r3, 0x0
  mov64 r0, r9
  jne r4, 0x0, jmp_3ed80

jmp_3ed78:
  mov64 r0, 0x0

jmp_3ed80:
  mov64 r5, r6
  jeq r4, 0x0, jmp_3eda8
  mov64 r4, 0x1
  jlt r1, r5, jmp_3eb18
  ja jmp_3edc0

jmp_3eda8:
  mov64 r5, 0x0
  mov64 r4, 0x1
  jlt r1, r5, jmp_3eb18

jmp_3edc0:
  mov64 r4, 0x0
  ja jmp_3eb18

jmp_3edd0:
  ldxdw r1, [r10-0x148]
  stxdw [r10-0x220], r1
  mov64 r9, r8
  lsh64 r9, 0x20
  mov64 r1, r9
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_3ef20
  arsh64 r9, 0x20
  mov64 r1, r10
  add64 r1, -0x158
  ldxdw r2, [r10-0x248]
  ldxdw r3, [r10-0x240]
  mov64 r4, r9
  mov64 r6, r5
  stxdw [r10-0x228], r7
  mov64 r7, r0
  call fn_d47e0
  neg64 r8
  and64 r8, 0x7f
  mov64 r1, r10
  add64 r1, -0x168
  mov64 r2, r6
  mov64 r3, r7
  mov64 r4, r8
  call fn_d4738
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r6
  mov64 r3, r7
  ldxdw r7, [r10-0x228]
  mov64 r4, r9
  call fn_d47e0
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r10-0x150]
  or64 r2, r1
  stxdw [r10-0x240], r2
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r10-0x158]
  or64 r2, r1
  stxdw [r10-0x248], r2
  ldxdw r0, [r10-0x170]
  ldxdw r5, [r10-0x178]

jmp_3ef20:
  ldxdw r8, [r10-0x220]
  mov64 r1, r8
  or64 r1, r7
  jeq r1, 0x0, jmp_3f520
  mov64 r3, r0
  mod64 r3, r8
  mov64 r1, r10
  add64 r1, -0x188
  mov64 r6, r5
  mov64 r2, r5
  mov64 r4, r8
  mov64 r9, r7
  mov64 r5, r7
  mov64 r7, r0
  call fn_d45f0
  mov64 r2, 0x1
  mov64 r1, 0x1
  jgt r8, r7, jmp_3f1b0
  mov64 r7, r9
  jne r7, 0x0, jmp_3f1c8

jmp_3efc0:
  jne r7, 0x0, jmp_3f1d8

jmp_3efc8:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3f1f0
  ja jmp_3f330

jmp_3efe0:
  mov64 r1, 0x0
  jge r0, r9, jmp_3eac8

jmp_3eff0:
  mov64 r2, 0x0
  jeq r0, r9, jmp_3ead0

jmp_3f000:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_3eae0

jmp_3f018:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r6, r10
  add64 r6, -0xf4
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_3f4d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x1e8
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1e8]
  ldxdw r2, [r10-0x1e0]
  ja jmp_3f4a0

jmp_3f190:
  ldxdw r7, [r10-0x258]
  stxdw [r7+0x8], r2
  stxdw [r7+0x10], r3
  ja jmp_3f320

jmp_3f1b0:
  mov64 r1, 0x0
  mov64 r7, r9
  jeq r7, 0x0, jmp_3efc0

jmp_3f1c8:
  mov64 r2, 0x0
  jeq r7, 0x0, jmp_3efc8

jmp_3f1d8:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_3f330

jmp_3f1f0:
  ldxdw r2, [r10-0x188]
  jne r2, 0x0, jmp_3f330
  mov64 r1, r10
  add64 r1, -0x1a8
  mov64 r4, r8
  mov64 r5, r7
  call fn_d4490
  ldxdw r1, [r10-0x1a8]
  mov64 r3, r6
  sub64 r3, r1
  mov64 r1, r10
  add64 r1, -0x1b8
  ldxdw r9, [r10-0x240]
  mov64 r2, r9
  mov64 r4, r8
  mov64 r5, r7
  call fn_d45f0
  mov64 r1, r10
  add64 r1, -0x1c8
  ldxdw r6, [r10-0x1b8]
  ldxdw r3, [r10-0x1b0]
  mov64 r2, r6
  mov64 r4, r8
  mov64 r5, r7
  call fn_d4490
  ldxdw r1, [r10-0x1c8]
  sub64 r9, r1
  mov64 r1, r10
  add64 r1, -0x1d8
  ldxdw r2, [r10-0x248]
  mov64 r3, r9
  mov64 r4, r8
  mov64 r5, r7
  call fn_d45f0
  ldxdw r7, [r10-0x258]
  stxdw [r7+0x10], r6
  ldxdw r1, [r10-0x1d8]
  stxdw [r7+0x8], r1

jmp_3f320:
  mov64 r1, 0x0
  ja jmp_3f4c0

jmp_3f330:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r6, r10
  add64 r6, -0xf4
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_3f4d0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x198
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x198]
  ldxdw r2, [r10-0x190]

jmp_3f4a0:
  ldxdw r7, [r10-0x258]
  stxdw [r7+0x10], r2
  stxdw [r7+0x8], r1
  mov64 r1, 0x1

jmp_3f4c0:
  stxdw [r7+0x0], r1
  exit

jmp_3f4d0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_3f520:
  lddw r1, data_6590
  call fn_d0970

fn_3f538:
  mov64 r9, r2
  mov64 r6, r1
  jeq r3, 0x1, jmp_3f708
  jne r3, 0x0, jmp_3f718
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_40130
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b6d
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17a8
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0xf
  stdw [r10-0xe0], 0x2a
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x118
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x110]

jmp_3f6e8:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_40128

jmp_3f708:
  ldxb r1, [r9+0x18]
  jeq r1, 0x0, jmp_3f9b0

jmp_3f718:
  stxdw [r10-0x168], r6
  mov64 r8, 0x0
  lsh64 r3, 0x5
  mov64 r1, 0x0
  stxdw [r10-0x150], r1
  lddw r7, 0xde0b6b3a7640000
  mov64 r6, 0x0
  stxdw [r10-0x158], r3
  ja jmp_3f790

jmp_3f768:
  stxdw [r10-0x160], r4
  mov64 r1, 0x1
  stxdw [r10-0x150], r1

jmp_3f780:
  add64 r8, 0x20
  jeq r3, r8, jmp_3fd80

jmp_3f790:
  mov64 r1, r9
  add64 r1, r8
  ldxw r4, [r1+0x10]
  lsh64 r4, 0x20
  arsh64 r4, 0x20
  add64 r4, 0x12
  mov64 r5, r4
  lsh64 r5, 0x20
  arsh64 r5, 0x20
  jne r5, r4, jmp_3fa20
  ldxdw r3, [r1+0x8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0xf0
  call fn_3d580
  ldxdw r1, [r10-0xe0]
  ldxdw r4, [r10-0xe8]
  ldxdw r2, [r10-0xf0]
  jeq r2, 0x1, jmp_3fb98
  mov64 r2, r4
  or64 r2, r1
  jeq r2, 0x0, jmp_3fbc0
  mov64 r2, r9
  add64 r2, r8
  ldxb r2, [r2+0x18]
  jeq r2, 0x0, jmp_3f8b8
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r4
  stdw [r10-0x1000], 0x0
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r5, r10
  mov64 r2, r7
  mov64 r3, r6
  lddw r4, 0xde0b6b3a7640000
  ja jmp_3f908

jmp_3f8b8:
  lddw r2, 0xde0b6b3a7640000
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  stdw [r10-0xff0], 0x0
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r5, r10
  mov64 r2, r7
  mov64 r3, r6

jmp_3f908:
  call fn_3e5b0
  ldxdw r6, [r10-0xe0]
  ldxdw r7, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  jne r1, 0x0, jmp_3fd58
  mov64 r1, r9
  add64 r1, r8
  ldxh r4, [r1+0x14]
  ldxdw r3, [r10-0x158]
  jeq r4, 0x0, jmp_3f780
  ldxh r1, [r1+0x16]
  ldxdw r4, [r10-0x160]
  and64 r4, 0xffff
  add64 r4, r1
  jlt r4, 0xffff, jmp_3f988
  mov64 r4, 0xffff

jmp_3f988:
  ldxdw r5, [r10-0x150]
  and64 r5, 0x1
  jne r5, 0x0, jmp_3f768
  mov64 r4, r1
  ja jmp_3f768

jmp_3f9b0:
  ldxdw r0, [r9+0x8]
  ldxdw r1, [r9+0x0]
  mov64 r3, r1
  or64 r3, r0
  jeq r3, 0x0, jmp_3fde0
  ldxw r3, [r9+0x10]
  ldxh r4, [r9+0x14]
  ldxh r5, [r9+0x16]
  stxdw [r6+0x8], r0
  stxdw [r6+0x0], r1
  stxh [r6+0x16], r5
  stxh [r6+0x14], r4
  stxw [r6+0x10], r3
  ja jmp_40128

jmp_3fa20:
  stw [r10-0xf4], 0x10
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r6, r10
  add64 r6, -0xf4
  mov64 r2, r6
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r6
  call fn_5a268
  jne r0, 0x0, jmp_40130
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x1780
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x148
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x148]
  ldxdw r2, [r10-0x140]
  ja jmp_40108

jmp_3fb98:
  ldxdw r2, [r10-0x168]
  stxdw [r2+0x8], r1
  stxdw [r2+0x0], r4
  sth [r2+0x14], 0x2
  ja jmp_40128

jmp_3fbc0:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_40130
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b6d
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x28
  stdw [r10-0xe0], 0x2a
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x138]
  ldxdw r2, [r10-0x130]
  ja jmp_40108

jmp_3fd58:
  ldxdw r1, [r10-0x168]
  stxdw [r1+0x8], r6
  stxdw [r1+0x0], r7
  sth [r1+0x14], 0x2
  ja jmp_40128

jmp_3fd80:
  mov64 r1, r7
  or64 r1, r6
  jeq r1, 0x0, jmp_3ff78
  ldxdw r1, [r10-0x168]
  stxdw [r1+0x0], r7
  ldxdw r2, [r10-0x160]
  stxh [r1+0x16], r2
  ldxdw r2, [r10-0x150]
  stxh [r1+0x14], r2
  stxdw [r1+0x8], r6
  stw [r1+0x10], -0x12
  ja jmp_40128

jmp_3fde0:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_40130
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b6d
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x13
  stdw [r10-0xe0], 0x2a
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x100]
  ja jmp_3f6e8

jmp_3ff78:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_40130
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b6d
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x35
  stdw [r10-0xe0], 0x2a
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x128
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x128]
  ldxdw r2, [r10-0x120]

jmp_40108:
  ldxdw r3, [r10-0x168]
  stxdw [r3+0x8], r2
  stxdw [r3+0x0], r1
  sth [r3+0x14], 0x2

jmp_40128:
  exit

jmp_40130:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_40180:
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  mov64 r9, r1
  add64 r9, 0x10
  ldxdw r2, [r1+0x10]
  lddw r0, 0x7fffffffffffffff
  jge r2, r0, jmp_40270
  mov64 r7, r4
  stxdw [r10-0x238], r3
  stxdw [r10-0x240], r5
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x18]
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x188], r1
  stxdw [r10-0x190], r2
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x190
  call fn_b2678
  ldxb r8, [r10-0x70]
  jne r8, 0x2, jmp_402e8
  ldxdw r1, [r10-0xe8]
  ldxdw r2, [r10-0xf0]
  jeq r2, 0x0, jmp_407d8
  ldxdw r2, [r1+0x0]
  ldxb r1, [r1+0x38]
  ja jmp_407e0

jmp_40270:
  stxdw [r10-0xe0], r9
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0x1a0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x1a0]
  ldxdw r2, [r10-0x198]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_40980

jmp_402e8:
  stxdw [r10-0x248], r6
  ldxw r6, [r10-0xf0]
  mov64 r1, r10
  add64 r1, -0x17c
  mov64 r2, r10
  add64 r2, -0xec
  mov64 r3, 0x3c
  call fn_d23d0
  ldxdw r1, [r10-0x90]
  stxdw [r10-0x120], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0x118], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0x110], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x108], r1
  ldxw r1, [r10-0x6e]
  stxw [r10-0xfe], r1
  ldxh r1, [r10-0x6a]
  stxh [r10-0xfa], r1
  ldxdw r0, [r10-0xb0]
  ldxdw r4, [r10-0xa8]
  ldxw r5, [r10-0xa0]
  ldxdw r1, [r10-0x98]
  ldxw r2, [r10-0x9c]
  ldxb r3, [r10-0x6f]
  stxb [r10-0xff], r3
  stxw [r10-0x12c], r2
  stxw [r10-0x180], r6
  stxdw [r10-0x128], r1
  stxw [r10-0x130], r5
  stxdw [r10-0x138], r4
  stxdw [r10-0x140], r0
  stxb [r10-0x100], r8
  and64 r8, 0x1
  jeq r8, 0x0, jmp_40638
  stxdw [r10-0x250], r4
  ldxdw r2, [r7+0x0]
  ldxdw r3, [r10-0x160]
  jne r3, r2, jmp_40478
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r10-0x158]
  jne r3, r2, jmp_40478
  ldxdw r2, [r7+0x10]
  ldxdw r3, [r10-0x150]
  jne r3, r2, jmp_40478
  mov64 r2, 0x0
  ldxdw r3, [r7+0x18]
  ldxdw r4, [r10-0x148]
  jeq r4, r3, jmp_40480

jmp_40478:
  mov64 r2, 0x1

jmp_40480:
  ldxdw r8, [r10-0x240]
  ldxdw r3, [r10-0x238]
  ldxdw r6, [r10-0x248]
  jeq r2, 0x0, jmp_40988
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_40fd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b97
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x177f
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x19
  stdw [r10-0xe0], 0x36
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x1c0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1b8]
  ldxdw r2, [r10-0x1c0]
  ja jmp_40950

jmp_40638:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  ldxdw r6, [r10-0x248]
  jne r0, 0x0, jmp_40fd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b97
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x14
  stdw [r10-0xe0], 0x36
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x1b0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1a8]
  ldxdw r2, [r10-0x1b0]
  ja jmp_40950

jmp_407d8:
  ldxdw r1, [r1+0x0]

jmp_407e0:
  stw [r10-0xf4], 0xf
  mov64 r1, r10
  add64 r1, -0x50
  mov64 r7, r10
  add64 r7, -0xf4
  mov64 r2, r7
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  mov64 r1, r7
  call fn_5a268
  jne r0, 0x0, jmp_40fd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  stw [r10-0x58], 0x177f
  stb [r10-0xa0], 0x2
  stdw [r10-0xf0], 0x2
  mov64 r1, r10
  add64 r1, -0x230
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x228]
  ldxdw r2, [r10-0x230]

jmp_40950:
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  sth [r6+0x14], 0x2

jmp_40968:
  ldxdw r1, [r9+0x0]
  add64 r1, -0x1
  stxdw [r9+0x0], r1

jmp_40980:
  exit

jmp_40988:
  stxdw [r10-0x258], r5
  ldxdw r5, [r3+0x20]
  mov64 r4, 0x1
  mov64 r3, 0x1
  jsle r1, 0x0, jmp_40bd8
  mov64 r7, r5
  sub64 r7, r1
  jsge r7, r5, jmp_40bf8

jmp_409c8:
  xor64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_40c18

jmp_409e0:
  mov64 r1, 0x78
  mov64 r3, r8
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  ldxdw r2, [r10-0x250]
  jgt r3, 0x12c, jmp_40a38
  lsh64 r8, 0x1
  add64 r8, 0x4
  and64 r8, 0xfffe
  div64 r8, 0x5
  mov64 r1, r8

jmp_40a38:
  jle r7, r1, jmp_40c30
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_40fd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1b97
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x28
  stdw [r10-0xe0], 0x36
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x220
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x218]
  ldxdw r2, [r10-0x220]
  ja jmp_40950

jmp_40bd8:
  mov64 r3, 0x0
  mov64 r7, r5
  sub64 r7, r1
  jslt r7, r5, jmp_409c8

jmp_40bf8:
  mov64 r4, 0x0
  xor64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_409e0

jmp_40c18:
  lddw r1, data_65a8
  call fn_d0810

jmp_40c30:
  jsle r0, 0x0, jmp_40d98
  mov64 r1, r10
  add64 r1, -0x1e0
  mov64 r3, 0x0
  mov64 r4, 0x32
  mov64 r5, 0x0
  mov64 r7, r0
  call fn_d4490
  mov64 r4, r7
  mov64 r5, 0x1
  ldxdw r3, [r10-0x1e0]
  mov64 r1, 0x1
  jgt r3, r4, jmp_40e68
  ldxdw r3, [r10-0x1d8]
  jne r3, 0x0, jmp_40e80

jmp_40ca8:
  ldxdw r2, [r10-0x250]
  jne r3, 0x0, jmp_40e98

jmp_40cb8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_40eb0

jmp_40cc8:
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1b97
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x2f
  stdw [r10-0xe0], 0x36
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x1791
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x208]
  ldxdw r2, [r10-0x210]
  ja jmp_40950

jmp_40d98:
  mov64 r1, r10
  add64 r1, -0xd0
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1b97
  stxdw [r10-0xe8], r1
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x2d
  stdw [r10-0xe0], 0x36
  stdw [r10-0xf0], 0x0
  stw [r10-0x58], 0x1791
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x1c8]
  ldxdw r2, [r10-0x1d0]
  ja jmp_40950

jmp_40e68:
  mov64 r1, 0x0
  ldxdw r3, [r10-0x1d8]
  jeq r3, 0x0, jmp_40ca8

jmp_40e80:
  mov64 r5, 0x0
  ldxdw r2, [r10-0x250]
  jeq r3, 0x0, jmp_40cb8

jmp_40e98:
  mov64 r1, r5
  and64 r1, 0x1
  jeq r1, 0x0, jmp_40cc8

jmp_40eb0:
  mov64 r1, r10
  add64 r1, -0x1f0
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  mov64 r4, r7
  ldxdw r1, [r10-0x1f0]
  mov64 r2, r4
  add64 r2, r1
  mov64 r1, 0x1
  mov64 r5, 0x1
  jlt r2, r4, jmp_40f20
  mov64 r5, 0x0

jmp_40f20:
  ldxdw r3, [r10-0x1e8]
  add64 r3, r5
  jeq r2, 0x0, jmp_40f40
  mov64 r1, 0x0

jmp_40f40:
  sub64 r3, r1
  add64 r2, -0x1
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r5, 0x0
  call fn_d45f0
  ldxdw r1, [r10-0x200]
  jlt r1, 0xffff, jmp_40f88
  mov64 r1, 0xffff

jmp_40f88:
  ldxdw r2, [r10-0x1f8]
  ldxdw r3, [r10-0x258]
  jeq r2, 0x0, jmp_40fa8
  mov64 r1, 0xffff

jmp_40fa8:
  stxdw [r6+0x0], r7
  stxw [r6+0x10], r3
  stxh [r6+0x16], r1
  stdw [r6+0x8], 0x0
  sth [r6+0x14], 0x1
  ja jmp_40968

jmp_40fd8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_41028:
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  mov64 r7, r1
  add64 r7, 0x10
  ldxdw r2, [r1+0x10]
  lddw r4, 0x7fffffffffffffff
  jge r2, r4, jmp_41158
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x20]
  jne r2, 0x11, jmp_411d0
  mov64 r8, r3
  ldxdw r1, [r1+0x18]
  ldxb r2, [r1+0x10]
  stxdw [r10-0x150], r2
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x148], r2
  ldxdw r9, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0xf0
  call fn_c2a08
  ldxdw r2, [r10-0xe8]
  ldxdw r1, [r10-0xf0]
  jne r1, 0x1, jmp_41398
  ldxdw r1, [r10-0xe0]
  ldxdw r3, [r10-0xd8]
  stxdw [r10-0xe0], r3
  stxdw [r10-0xe8], r1
  stxdw [r10-0xf0], r2
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ja jmp_41360

jmp_41158:
  stxdw [r10-0xe0], r7
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xf0], r1
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be7f0
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_41390

jmp_411d0:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_41780
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1bcd
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x177f
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x13
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]

jmp_41360:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2

jmp_41378:
  ldxdw r1, [r7+0x0]
  add64 r1, -0x1
  stxdw [r7+0x0], r1

jmp_41390:
  exit

jmp_41398:
  mov64 r3, r2
  sub64 r3, r9
  mov64 r1, 0x0
  mov64 r4, 0x1
  jle r3, r2, jmp_41570
  jeq r4, 0x0, jmp_41580

jmp_413c8:
  jge r8, 0xc8, jmp_41590

jmp_413d0:
  jle r1, r8, jmp_415a0

jmp_413d8:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_168c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_168c
  call fn_5a268
  jne r0, 0x0, jmp_41780
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1bcd
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x179f
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x21
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x130]
  ldxdw r2, [r10-0x128]
  ja jmp_41360

jmp_41570:
  mov64 r4, 0x0
  jne r4, 0x0, jmp_413c8

jmp_41580:
  mov64 r1, r3
  jlt r8, 0xc8, jmp_413d0

jmp_41590:
  mov64 r8, 0xc8
  jgt r1, r8, jmp_413d8

jmp_415a0:
  ldxdw r1, [r10-0x148]
  jeq r1, 0x0, jmp_415e8
  stxdw [r6+0x0], r1
  ldxdw r1, [r10-0x150]
  neg64 r1
  stxw [r6+0x10], r1
  stdw [r6+0x8], 0x0
  sth [r6+0x14], 0x0
  ja jmp_41378

jmp_415e8:
  mov64 r1, r10
  add64 r1, -0x50
  lddw r2, data_171c
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_171c
  call fn_5a268
  jne r0, 0x0, jmp_41780
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x50]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x48]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0xc0], r1
  lddw r1, str_1bcd
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x1791
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x28
  stdw [r10-0xe0], 0x39
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x118]
  ja jmp_41360

jmp_41780:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_417d0:
  mov64 r6, r1
  ldxdw r2, [r2+0x10]
  mov64 r7, r2
  add64 r7, 0x10
  ldxdw r1, [r2+0x10]
  lddw r5, 0x7fffffffffffffff
  jge r1, r5, jmp_419b8
  mov64 r5, r1
  add64 r5, 0x1
  stxdw [r2+0x10], r5
  ldxdw r5, [r2+0x20]
  jle r5, 0xf7, jmp_41a30
  ldxdw r2, [r2+0x18]
  ldxdw r5, [r2+0x0]
  lddw r0, 0x754981804245b360
  jne r5, r0, jmp_41bc8
  ldxb r5, [r2+0x8]
  jne r5, 0x2, jmp_41d60
  ldxw r5, [r2+0x94]
  jne r5, 0x1, jmp_41ef8
  ldxw r5, [r2+0x8f]
  jeq r5, 0x0, jmp_41fc8
  ldxdw r9, [r3+0x0]
  ldxdw r5, [r2+0xc8]
  mov64 r0, r9
  sub64 r0, r5
  mov64 r5, 0x0
  mov64 r8, 0x1
  jle r0, r9, jmp_42098
  jeq r8, 0x0, jmp_420a8

jmp_418d0:
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jle r5, r4, jmp_420c8

jmp_418e8:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_168c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_168c
  call fn_9838
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x55
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x179f
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x168]
  ldxdw r2, [r10-0x170]
  ja jmp_42408

jmp_419b8:
  stxdw [r10-0xc8], r7
  lddw r1, -0x7ffffffffffffff5
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be7f0
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2
  ja jmp_42438

jmp_41a30:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_42440
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x177f
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x2f
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x108]
  ldxdw r2, [r10-0x110]
  ja jmp_42408

jmp_41bc8:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a8
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a8
  call fn_5a268
  jne r0, 0x0, jmp_42440
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17a9
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x36
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x118]
  ldxdw r2, [r10-0x120]
  ja jmp_42408

jmp_41d60:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_42440
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3f
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x128]
  ldxdw r2, [r10-0x130]
  ja jmp_42408

jmp_41ef8:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x46
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x138]
  ldxdw r2, [r10-0x140]
  ja jmp_42408

jmp_41fc8:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x4d
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x178]
  ldxdw r2, [r10-0x180]
  ja jmp_42408

jmp_42098:
  mov64 r8, 0x0
  jne r8, 0x0, jmp_418d0

jmp_420a8:
  mov64 r5, r0
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jgt r5, r4, jmp_418e8

jmp_420c8:
  ldxdw r8, [r3+0x20]
  ldxw r9, [r2+0xd0]
  mov64 r5, 0x1
  mov64 r3, 0x1
  jsle r9, 0x0, jmp_42218
  mov64 r0, r8
  sub64 r0, r9
  jsge r0, r8, jmp_42238

jmp_42108:
  xor64 r3, r5
  lddw r5, -0x8000000000000000
  jeq r3, 0x0, jmp_42260

jmp_42128:
  mul64 r4, 0x190
  add64 r4, 0x3e7
  div64 r4, 0x3e8
  jsle r5, r4, jmp_42288

jmp_42148:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_168c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_168c
  call fn_9838
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x61
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x179f
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x158]
  ldxdw r2, [r10-0x160]
  ja jmp_42408

jmp_42218:
  mov64 r3, 0x0
  mov64 r0, r8
  sub64 r0, r9
  jslt r0, r8, jmp_42108

jmp_42238:
  mov64 r5, 0x0
  xor64 r3, r5
  lddw r5, -0x8000000000000000
  jne r3, 0x0, jmp_42128

jmp_42260:
  mov64 r5, r0
  mul64 r4, 0x190
  add64 r4, 0x3e7
  div64 r4, 0x3e8
  jsgt r5, r4, jmp_42148

jmp_42288:
  ldxdw r3, [r2+0xe0]
  ldxdw r4, [r2+0xd8]
  mov64 r0, 0x1
  mov64 r5, 0x1
  jeq r4, 0x0, jmp_42308
  jsle r3, 0x0, jmp_42318

jmp_422b8:
  jne r3, 0x0, jmp_42328

jmp_422c0:
  and64 r5, 0x1
  jeq r5, 0x0, jmp_42340

jmp_422d0:
  ldxb r2, [r2+0x8a]
  stxdw [r6+0x0], r4
  stxdw [r6+0x8], r3
  neg64 r2
  stxw [r6+0x10], r2
  sth [r6+0x14], 0x0
  ja jmp_42430

jmp_42308:
  mov64 r5, 0x0
  jsgt r3, 0x0, jmp_422b8

jmp_42318:
  mov64 r0, 0x0
  jeq r3, 0x0, jmp_422c0

jmp_42328:
  mov64 r5, r0
  and64 r5, 0x1
  jne r5, 0x0, jmp_422d0

jmp_42340:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c06
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x69
  stdw [r10-0xc8], 0x3b
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x148]
  ldxdw r2, [r10-0x150]

jmp_42408:
  stxdw [r6+0x0], r2
  stxdw [r6+0x8], r1
  sth [r6+0x14], 0x2
  ldxdw r1, [r7+0x0]
  add64 r1, -0x1

jmp_42430:
  stxdw [r7+0x0], r1

jmp_42438:
  exit

jmp_42440:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_42490:
  mov64 r6, r1
  jne r3, 0x120, jmp_42a00
  ldxb r1, [r2+0x0]
  jne r1, 0x0, jmp_42b98
  ldxb r1, [r2+0x1]
  jne r1, 0x3, jmp_42b98
  ldxb r1, [r2+0x20]
  mov64 r7, r2
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x21]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x22]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x23]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x24]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x25]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x26]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x27]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x28]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x29]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2a]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2b]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2c]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2d]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2e]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x2f]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x30]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x31]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x32]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x33]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x34]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x35]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x36]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x37]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x38]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x39]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x3a]
  jne r1, 0x0, jmp_42688
  ldxb r1, [r2+0x3b]
  jeq r1, 0x0, jmp_42d60

jmp_42688:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_43108
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r8, [r10-0x118]
  ldxdw r1, [r10-0x120]
  jne r1, 0x2, jmp_42d50
  mov64 r1, r7
  ldxb r2, [r1+0x40]
  jne r2, 0x0, jmp_42d88

jmp_42838:
  ldxb r2, [r1+0x41]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x42]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x43]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x44]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x45]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x46]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x47]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x48]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x49]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4a]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4b]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4c]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4d]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4e]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x4f]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x50]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x51]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x52]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x53]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x54]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x55]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x56]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x57]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x58]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x59]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x5a]
  jne r2, 0x0, jmp_42d88
  ldxb r2, [r1+0x5b]
  jne r2, 0x0, jmp_42d88
  ldxw r9, [r1+0x5c]
  be32 r9
  ja jmp_42f20

jmp_42a00:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_43108
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x7d
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  ja jmp_42d28

jmp_42b98:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_43108
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x82
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]

jmp_42d28:
  stxdw [r6+0x10], r2

jmp_42d30:
  stxdw [r6+0x8], r1

jmp_42d38:
  mov64 r1, 0x1

jmp_42d40:
  stxdw [r6+0x0], r1
  exit

jmp_42d50:
  stxdw [r6+0x10], r8
  ja jmp_42d30

jmp_42d60:
  ldxw r8, [r2+0x3c]
  be32 r8
  mov64 r1, r7
  ldxb r2, [r1+0x40]
  jeq r2, 0x0, jmp_42838

jmp_42d88:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_43108
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r9, [r10-0x128]
  ldxdw r1, [r10-0x130]
  jne r1, 0x2, jmp_430f8

jmp_42f20:
  mov64 r1, r7
  ldxb r2, [r1+0x60]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x61]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x62]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x63]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x64]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x65]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x66]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x67]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x68]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x69]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6a]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6b]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6c]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6d]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6e]
  jne r2, 0x0, jmp_43028
  ldxb r2, [r1+0x6f]
  jeq r2, 0x0, jmp_43158

jmp_43028:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x4a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ja jmp_42d28

jmp_430f8:
  stxdw [r6+0x10], r9
  ja jmp_42d30

jmp_43108:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_43158:
  ldxb r1, [r1+0x80]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x81]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x82]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x83]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x84]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x85]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x86]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x87]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x88]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x89]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8a]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8b]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8c]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8d]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8e]
  jne r1, 0x0, jmp_43258
  ldxb r1, [r7+0x8f]
  jeq r1, 0x0, jmp_43328

jmp_43258:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x4a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ja jmp_42d28

jmp_43328:
  mov64 r1, r7
  ldxdw r2, [r1+0x70]
  stxdw [r10-0x1a0], r2
  ldxdw r2, [r1+0x78]
  stxdw [r10-0x1a8], r2
  ldxdw r2, [r1+0x90]
  stxdw [r10-0x1b0], r2
  ldxdw r2, [r1+0x98]
  stxdw [r10-0x1b8], r2
  ldxb r1, [r1+0xa0]
  jeq r1, 0x0, jmp_43478

jmp_43380:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x198], r1
  ldxdw r2, [r10-0x160]
  jeq r2, 0x2, jmp_43640
  ldxdw r1, [r10-0x198]
  stxdw [r6+0x10], r1
  stxdw [r6+0x8], r2
  ja jmp_42d38

jmp_43478:
  ldxb r1, [r7+0xa1]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa2]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa3]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa4]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa5]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa6]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa7]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa8]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xa9]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xaa]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xab]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xac]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xad]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xae]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xaf]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb0]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb1]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb2]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb3]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb4]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb5]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb6]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb7]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb8]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xb9]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xba]
  jne r1, 0x0, jmp_43380
  ldxb r1, [r7+0xbb]
  jne r1, 0x0, jmp_43380
  ldxw r1, [r7+0xbc]
  be32 r1
  stxdw [r10-0x198], r1

jmp_43640:
  ldxb r2, [r7+0xc0]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc1]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc2]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc3]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc4]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc5]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc6]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc7]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc8]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xc9]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xca]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xcb]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xcc]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xcd]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xce]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xcf]
  jne r2, 0x0, jmp_43b80
  ldxb r2, [r7+0xd0]
  lsh64 r2, 0x38
  arsh64 r2, 0x38
  jsle r2, -0x1, jmp_43b80
  ldxb r2, [r7+0xe0]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe1]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe2]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe3]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe4]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe5]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe6]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe7]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe8]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xe9]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xea]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xeb]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xec]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xed]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xee]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xef]
  jne r2, 0x0, jmp_43c50
  ldxb r2, [r7+0xf0]
  lsh64 r2, 0x38
  arsh64 r2, 0x38
  jsle r2, -0x1, jmp_43c50
  ldxb r2, [r7+0x100]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x101]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x102]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x103]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x104]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x105]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x106]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x107]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x108]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x109]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10a]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10b]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10c]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10d]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10e]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x10f]
  jne r2, 0x0, jmp_43d20
  ldxb r2, [r7+0x110]
  lsh64 r2, 0x38
  arsh64 r2, 0x38
  jsle r2, -0x1, jmp_43d20
  ldxdw r1, [r10-0x1a0]
  be64 r1
  stxdw [r10-0x1a0], r1
  ldxdw r1, [r10-0x1a8]
  be64 r1
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r10-0x1b0]
  be64 r1
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r10-0x1b8]
  be64 r1
  stxdw [r10-0x1b8], r1
  ldxdw r3, [r7+0xd0]
  be64 r3
  ldxdw r5, [r7+0xd8]
  be64 r5
  ldxdw r0, [r7+0xf0]
  be64 r0
  ldxdw r1, [r7+0xf8]
  be64 r1
  ldxdw r4, [r7+0x110]
  stxdw [r10-0x1c0], r4
  ldxdw r4, [r7+0x118]
  ldxdw r2, [r7+0x0]
  stxdw [r10-0x1c8], r2
  ldxdw r2, [r7+0x8]
  stxdw [r10-0x1d8], r2
  ldxdw r2, [r7+0x10]
  stxdw [r10-0x1d0], r2
  ldxdw r2, [r7+0x18]
  ldxdw r7, [r10-0x198]
  stxw [r6+0x80], r7
  stxw [r6+0x7c], r9
  stxw [r6+0x78], r8
  stxdw [r6+0x58], r1
  stxdw [r6+0x60], r0
  stxdw [r6+0x48], r5
  stxdw [r6+0x50], r3
  ldxdw r1, [r10-0x1b8]
  stxdw [r6+0x38], r1
  ldxdw r1, [r10-0x1b0]
  stxdw [r6+0x40], r1
  ldxdw r1, [r10-0x1a8]
  stxdw [r6+0x28], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r6+0x30], r1
  stxdw [r6+0x20], r2
  ldxdw r1, [r10-0x1d0]
  stxdw [r6+0x18], r1
  ldxdw r1, [r10-0x1d8]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x1c8]
  stxdw [r6+0x8], r1
  be64 r4
  stxdw [r6+0x68], r4
  ldxdw r1, [r10-0x1c0]
  be64 r1
  stxdw [r6+0x70], r1
  mov64 r1, 0x0
  ja jmp_42d40

jmp_43b80:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x5a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]
  ja jmp_42d28

jmp_43c50:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x5a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x180]
  ldxdw r2, [r10-0x178]
  ja jmp_42d28

jmp_43d20:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x5a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x190
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x190]
  ldxdw r2, [r10-0x188]
  ja jmp_42d28

fn_43df0:
  mov64 r6, r1
  ldxdw r1, [r5-0xff0]
  ldxdw r0, [r5-0xff8]
  ldxdw r7, [r5-0x1000]
  mov64 r5, r7
  and64 r5, 0xff
  jeq r5, 0x8, jmp_43e30
  jne r5, 0x12, jmp_44040

jmp_43e30:
  ldxdw r5, [r3+0x0]
  ldxdw r8, [r2+0x0]
  jne r8, r5, jmp_43e98
  ldxdw r5, [r3+0x8]
  ldxdw r8, [r2+0x8]
  jne r8, r5, jmp_43e98
  ldxdw r5, [r3+0x10]
  ldxdw r8, [r2+0x10]
  jne r8, r5, jmp_43e98
  mov64 r5, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r8, [r2+0x18]
  jeq r8, r3, jmp_43ea0

jmp_43e98:
  mov64 r5, 0x1

jmp_43ea0:
  jeq r5, 0x0, jmp_441d8
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_44cb8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x177f
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xad
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  ja jmp_44c58

jmp_44040:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_44cb8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17a8
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xa6
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x180]
  ldxdw r2, [r10-0x178]
  ja jmp_44c58

jmp_441d8:
  ldxw r3, [r2+0x70]
  jsge r4, r3, jmp_44380
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16ac
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16ac
  call fn_5a268
  jne r0, 0x0, jmp_44cb8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17af
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xb1
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]
  ja jmp_44c58

jmp_44380:
  ldxw r5, [r2+0x78]
  jle r4, r5, jmp_44528
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1714
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1714
  call fn_5a268
  jne r0, 0x0, jmp_44cb8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17b0
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xbb
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r10-0x158]
  ja jmp_44c58

jmp_44528:
  ldxw r5, [r2+0x74]
  jlt r5, r3, jmp_44648
  jlt r4, r5, jmp_44648
  sub64 r4, r5
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mul64 r0, 0x190
  add64 r0, 0x3e7
  div64 r0, 0x3e8
  jle r4, r0, jmp_447e0
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_168c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_168c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xd4
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x179f
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ja jmp_44c58

jmp_44648:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_44cb8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xc5
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]
  ja jmp_44c58

jmp_447e0:
  ldxdw r8, [r2+0x48]
  mov64 r3, 0x1
  mov64 r4, 0x1
  jsge r8, 0x0, jmp_44830
  ldxdw r9, [r2+0x40]
  jne r9, 0x0, jmp_44848

jmp_44810:
  jne r8, 0x0, jmp_44858

jmp_44818:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_44870
  ja jmp_448c8

jmp_44830:
  mov64 r4, 0x0
  ldxdw r9, [r2+0x40]
  jeq r9, 0x0, jmp_44810

jmp_44848:
  mov64 r3, 0x0
  jeq r8, 0x0, jmp_44818

jmp_44858:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_448c8

jmp_44870:
  ldxdw r3, [r2+0x58]
  jsle r3, -0x1, jmp_448c8
  ldxdw r0, [r2+0x50]
  mov64 r5, 0x1
  mov64 r4, 0x1
  jle r0, r9, jmp_44998
  jle r3, r8, jmp_449a8

jmp_448a8:
  jne r3, r8, jmp_449b8

jmp_448b0:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_449d0
  ja jmp_44b90

jmp_448c8:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xd9
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x118]
  ja jmp_44c58

jmp_44998:
  mov64 r4, 0x0
  jgt r3, r8, jmp_448a8

jmp_449a8:
  mov64 r5, 0x0
  jeq r3, r8, jmp_448b0

jmp_449b8:
  mov64 r4, r5
  and64 r4, 0x1
  jne r4, 0x0, jmp_44b90

jmp_449d0:
  ldxdw r4, [r2+0x68]
  ldxdw r0, [r2+0x60]
  mov64 r5, 0x1
  mov64 r3, 0x1
  jgt r9, r0, jmp_44b58
  jsgt r8, r4, jmp_44b68

jmp_44a00:
  jne r8, r4, jmp_44b78

jmp_44a08:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_44b90

jmp_44a18:
  and64 r1, 0xffff
  mov64 r3, r1
  jlt r1, 0x3e8, jmp_44a38
  mov64 r3, 0x3e8

jmp_44a38:
  mov64 r4, 0xc8
  jeq r1, 0x0, jmp_44a50
  mov64 r4, r3

jmp_44a50:
  stxdw [r10-0x188], r4
  mov64 r1, r2
  call fn_44d08
  mov64 r1, r0
  and64 r1, 0xffff
  ldxdw r2, [r10-0x188]
  jle r1, r2, jmp_44c78
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16e8
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16e8
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xe6
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17ad
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ja jmp_44c58

jmp_44b58:
  mov64 r3, 0x0
  jsle r8, r4, jmp_44a00

jmp_44b68:
  mov64 r5, 0x0
  jeq r8, r4, jmp_44a08

jmp_44b78:
  mov64 r3, r5
  and64 r3, 0x1
  jne r3, 0x0, jmp_44a18

jmp_44b90:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0xdd
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x130]
  ldxdw r2, [r10-0x128]

jmp_44c58:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  sth [r6+0x14], 0x2

jmp_44c70:
  exit

jmp_44c78:
  stxdw [r6+0x0], r9
  stxh [r6+0x16], r0
  stxdw [r6+0x8], r8
  and64 r7, 0xff
  neg64 r7
  stxw [r6+0x10], r7
  sth [r6+0x14], 0x1
  ja jmp_44c70

jmp_44cb8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_44d08:
  ldxdw r3, [r1+0x50]
  ldxdw r0, [r1+0x40]
  mov64 r4, 0x1
  jlt r0, r3, jmp_44d30
  mov64 r4, 0x0

jmp_44d30:
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
  jslt r4, 0x0, jmp_45118
  ldxdw r4, [r1+0x68]
  ldxdw r6, [r1+0x60]
  mov64 r5, 0x1
  jlt r6, r0, jmp_44db0
  mov64 r5, 0x0

jmp_44db0:
  mov64 r1, r4
  sub64 r1, r7
  sub64 r1, r5
  mov64 r5, r4
  xor64 r5, r7
  xor64 r4, r1
  and64 r5, r4
  stxdw [r10-0x48], r7
  jslt r5, 0x0, jmp_45130
  mov64 r8, r0
  sub64 r8, r3
  stxdw [r10-0x50], r0
  sub64 r6, r0
  mov64 r7, 0x1
  mov64 r9, 0x1
  jle r8, r6, jmp_45088
  mov64 r3, 0x1
  jle r2, r1, jmp_450a0

jmp_44e40:
  jne r2, r1, jmp_450b0

jmp_44e48:
  jne r9, 0x0, jmp_44e58

jmp_44e50:
  mov64 r2, r1

jmp_44e58:
  mov64 r1, r10
  add64 r1, -0x20
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  jne r9, 0x0, jmp_44e98
  mov64 r8, r6

jmp_44e98:
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r8
  mov64 r3, 0x0
  mov64 r4, 0x2710
  mov64 r5, 0x0
  call fn_d4490
  ldxdw r2, [r10-0x18]
  mov64 r1, 0x1
  jne r2, 0x0, jmp_44ef0
  mov64 r1, 0x0

jmp_44ef0:
  ldxdw r2, [r10-0x20]
  ldxdw r3, [r10-0x8]
  mov64 r8, r3
  add64 r8, r2
  ldxdw r9, [r10-0x48]
  jlt r8, r3, jmp_44f28
  mov64 r7, 0x0

jmp_44f28:
  or64 r1, r7
  and64 r1, 0x1
  jne r1, 0x0, jmp_45078
  ldxdw r7, [r10-0x50]
  mov64 r1, r7
  or64 r1, r9
  jeq r1, 0x0, jmp_45148
  ldxdw r6, [r10-0x10]
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r6
  mov64 r3, r8
  mov64 r4, r7
  mov64 r5, r9
  call fn_d45f0
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r4, r7
  ldxdw r7, [r10-0x30]
  mov64 r5, r9
  ldxdw r9, [r10-0x28]
  mov64 r2, r7
  mov64 r3, r9
  call fn_d4490
  ldxdw r1, [r10-0x38]
  sub64 r8, r1
  mov64 r1, 0x1
  ldxdw r2, [r10-0x40]
  mov64 r3, 0x1
  jlt r6, r2, jmp_45020
  mov64 r3, 0x0

jmp_45020:
  sub64 r8, r3
  sub64 r6, r2
  or64 r6, r8
  mov64 r2, 0x1
  jeq r6, 0x0, jmp_450c8
  mov64 r0, r7
  add64 r0, r2
  jge r0, r7, jmp_450e8

jmp_45060:
  add64 r9, r1
  jge r0, 0xffff, jmp_45100

jmp_45070:
  jeq r9, 0x0, jmp_45080

jmp_45078:
  mov64 r0, 0xffff

jmp_45080:
  exit

jmp_45088:
  mov64 r9, 0x0
  mov64 r3, 0x1
  jgt r2, r1, jmp_44e40

jmp_450a0:
  mov64 r3, 0x0
  jeq r2, r1, jmp_44e48

jmp_450b0:
  mov64 r9, r3
  jeq r9, 0x0, jmp_44e50
  ja jmp_44e58

jmp_450c8:
  mov64 r2, 0x0
  mov64 r0, r7
  add64 r0, r2
  jlt r0, r7, jmp_45060

jmp_450e8:
  mov64 r1, 0x0
  add64 r9, r1
  jlt r0, 0xffff, jmp_45070

jmp_45100:
  mov64 r0, 0xffff
  jne r9, 0x0, jmp_45078
  ja jmp_45080

jmp_45118:
  lddw r1, data_65c0
  call fn_d0810

jmp_45130:
  lddw r1, data_65d8
  call fn_d0810

jmp_45148:
  lddw r1, data_65f0
  call fn_d0970

fn_45160:
  mov64 r6, r1
  jne r3, 0xe0, jmp_456d0
  ldxb r1, [r2+0x0]
  jne r1, 0x0, jmp_45868
  ldxb r1, [r2+0x1]
  jne r1, 0x7, jmp_45868
  ldxb r1, [r2+0x20]
  mov64 r7, r2
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x21]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x22]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x23]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x24]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x25]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x26]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x27]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x28]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x29]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2a]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2b]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2c]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2d]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2e]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x2f]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x30]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x31]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x32]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x33]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x34]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x35]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x36]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x37]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x38]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x39]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x3a]
  jne r1, 0x0, jmp_45358
  ldxb r1, [r2+0x3b]
  jeq r1, 0x0, jmp_45a30

jmp_45358:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_45dd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r8, [r10-0x118]
  ldxdw r1, [r10-0x120]
  jne r1, 0x2, jmp_45a20
  mov64 r1, r7
  ldxb r2, [r1+0x40]
  jne r2, 0x0, jmp_45a58

jmp_45508:
  ldxb r2, [r1+0x41]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x42]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x43]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x44]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x45]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x46]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x47]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x48]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x49]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4a]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4b]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4c]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4d]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4e]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x4f]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x50]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x51]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x52]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x53]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x54]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x55]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x56]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x57]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x58]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x59]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x5a]
  jne r2, 0x0, jmp_45a58
  ldxb r2, [r1+0x5b]
  jne r2, 0x0, jmp_45a58
  ldxw r9, [r1+0x5c]
  be32 r9
  ja jmp_45bf0

jmp_456d0:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_45dd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x12a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]
  ja jmp_459f8

jmp_45868:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_45dd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x12f
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]

jmp_459f8:
  stxdw [r6+0x10], r2

jmp_45a00:
  stxdw [r6+0x8], r1

jmp_45a08:
  mov64 r1, 0x1

jmp_45a10:
  stxdw [r6+0x0], r1
  exit

jmp_45a20:
  stxdw [r6+0x10], r8
  ja jmp_45a00

jmp_45a30:
  ldxw r8, [r2+0x3c]
  be32 r8
  mov64 r1, r7
  ldxb r2, [r1+0x40]
  jeq r2, 0x0, jmp_45508

jmp_45a58:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_45dd8
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r9, [r10-0x128]
  ldxdw r1, [r10-0x130]
  jne r1, 0x2, jmp_45dc8

jmp_45bf0:
  mov64 r1, r7
  ldxb r2, [r1+0x60]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x61]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x62]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x63]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x64]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x65]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x66]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x67]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x68]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x69]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6a]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6b]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6c]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6d]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6e]
  jne r2, 0x0, jmp_45cf8
  ldxb r2, [r1+0x6f]
  jeq r2, 0x0, jmp_45e28

jmp_45cf8:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x4a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ja jmp_459f8

jmp_45dc8:
  stxdw [r6+0x10], r9
  ja jmp_45a00

jmp_45dd8:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

jmp_45e28:
  ldxb r1, [r1+0x80]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x81]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x82]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x83]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x84]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x85]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x86]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x87]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x88]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x89]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8a]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8b]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8c]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8d]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8e]
  jne r1, 0x0, jmp_45f28
  ldxb r1, [r7+0x8f]
  jeq r1, 0x0, jmp_45ff8

jmp_45f28:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x4a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ja jmp_459f8

jmp_45ff8:
  mov64 r1, r7
  ldxdw r2, [r1+0x70]
  stxdw [r10-0x178], r2
  ldxdw r2, [r1+0x78]
  stxdw [r10-0x180], r2
  ldxdw r2, [r1+0x90]
  stxdw [r10-0x188], r2
  ldxdw r2, [r1+0x98]
  stxdw [r10-0x190], r2
  ldxb r1, [r1+0xa0]
  jeq r1, 0x0, jmp_46138

jmp_46050:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_16a0
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_16a0
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x3b
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x17aa
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x158]
  ldxdw r2, [r10-0x160]
  jeq r2, 0x2, jmp_462f8
  stxdw [r6+0x10], r1
  stxdw [r6+0x8], r2
  ja jmp_45a08

jmp_46138:
  ldxb r1, [r7+0xa1]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa2]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa3]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa4]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa5]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa6]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa7]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa8]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xa9]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xaa]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xab]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xac]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xad]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xae]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xaf]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb0]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb1]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb2]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb3]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb4]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb5]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb6]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb7]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb8]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xb9]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xba]
  jne r1, 0x0, jmp_46050
  ldxb r1, [r7+0xbb]
  jne r1, 0x0, jmp_46050
  ldxw r1, [r7+0xbc]
  be32 r1

jmp_462f8:
  ldxb r2, [r7+0xc0]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc1]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc2]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc3]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc4]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc5]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc6]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc7]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc8]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xc9]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xca]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xcb]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xcc]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xcd]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xce]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xcf]
  jne r2, 0x0, jmp_46560
  ldxb r2, [r7+0xd0]
  lsh64 r2, 0x38
  arsh64 r2, 0x38
  jsle r2, -0x1, jmp_46560
  ldxdw r2, [r10-0x178]
  be64 r2
  stxdw [r10-0x178], r2
  ldxdw r4, [r10-0x180]
  be64 r4
  ldxdw r3, [r10-0x188]
  be64 r3
  ldxdw r2, [r10-0x190]
  be64 r2
  ldxdw r5, [r7+0xd0]
  stxdw [r10-0x180], r5
  ldxdw r5, [r7+0xd8]
  ldxdw r0, [r7+0x0]
  stxdw [r10-0x188], r0
  ldxdw r0, [r7+0x8]
  stxdw [r10-0x198], r0
  ldxdw r0, [r7+0x10]
  stxdw [r10-0x190], r0
  ldxdw r7, [r7+0x18]
  stxw [r6+0x60], r1
  stxw [r6+0x5c], r9
  stxw [r6+0x58], r8
  stxdw [r6+0x38], r2
  stxdw [r6+0x40], r3
  stxdw [r6+0x28], r4
  ldxdw r1, [r10-0x178]
  stxdw [r6+0x30], r1
  stxdw [r6+0x20], r7
  ldxdw r1, [r10-0x190]
  stxdw [r6+0x18], r1
  ldxdw r1, [r10-0x198]
  stxdw [r6+0x10], r1
  ldxdw r1, [r10-0x188]
  stxdw [r6+0x8], r1
  be64 r5
  stxdw [r6+0x48], r5
  ldxdw r1, [r10-0x180]
  be64 r1
  stxdw [r6+0x50], r1
  mov64 r1, 0x0
  ja jmp_45a10

jmp_46560:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x5a
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x170]
  ldxdw r2, [r10-0x168]
  ja jmp_459f8

fn_46630:
  mov64 r6, r1
  ldxdw r1, [r5-0x1000]
  mov64 r0, r1
  add64 r0, -0x1
  and64 r0, 0xff
  jge r0, 0x12, jmp_46870
  ldxdw r0, [r3+0x0]
  ldxdw r7, [r2+0x0]
  jne r7, r0, jmp_466c8
  ldxdw r0, [r3+0x8]
  ldxdw r7, [r2+0x8]
  jne r7, r0, jmp_466c8
  ldxdw r0, [r3+0x10]
  ldxdw r7, [r2+0x10]
  jne r7, r0, jmp_466c8
  mov64 r0, 0x0
  ldxdw r3, [r3+0x18]
  ldxdw r7, [r2+0x18]
  jeq r7, r3, jmp_466d0

jmp_466c8:
  mov64 r0, 0x1

jmp_466d0:
  jeq r0, 0x0, jmp_46a28
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1670
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1670
  call fn_5a268
  jne r0, 0x0, jmp_471c0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x177f
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x15d
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x110
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x110]
  ldxdw r2, [r10-0x108]
  ja jmp_46a00

jmp_46870:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1718
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1718
  call fn_5a268
  jne r0, 0x0, jmp_471c0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17a8
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x155
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x100]
  ldxdw r2, [r10-0xf8]

jmp_46a00:
  stxdw [r6+0x8], r2
  stxdw [r6+0x0], r1
  mov64 r1, 0x2

jmp_46a18:
  stxh [r6+0x14], r1
  exit

jmp_46a28:
  ldxw r3, [r2+0x50]
  jsge r4, r3, jmp_46bd0
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16ac
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16ac
  call fn_5a268
  jne r0, 0x0, jmp_471c0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17af
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x161
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x160
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r10-0x158]
  ja jmp_46a00

jmp_46bd0:
  ldxw r0, [r2+0x58]
  jle r4, r0, jmp_46d78
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_1714
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_1714
  call fn_5a268
  jne r0, 0x0, jmp_471c0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17b0
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x169
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x150
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x150]
  ldxdw r2, [r10-0x148]
  ja jmp_46a00

jmp_46d78:
  ldxw r0, [r2+0x54]
  jlt r0, r3, jmp_46ea0
  jlt r4, r0, jmp_46ea0
  ldxdw r3, [r5-0xff8]
  sub64 r4, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  mul64 r3, 0x190
  add64 r3, 0x3e7
  div64 r3, 0x3e8
  jle r4, r3, jmp_47038
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_168c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_168c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x17e
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x179f
  mov64 r1, r10
  add64 r1, -0x140
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x140]
  ldxdw r2, [r10-0x138]
  ja jmp_46a00

jmp_46ea0:
  mov64 r1, r10
  add64 r1, -0xf0
  lddw r2, data_16a0
  call fn_594a8
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x1
  stdw [r10-0x38], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x38
  stxdw [r10-0x20], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x10], r1
  mov64 r2, r10
  add64 r2, -0x20
  lddw r1, data_16a0
  call fn_5a268
  jne r0, 0x0, jmp_471c0
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0xa8], r1
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stw [r10-0x40], 0x17aa
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x173
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x120]
  ldxdw r2, [r10-0x118]
  ja jmp_46a00

jmp_47038:
  ldxdw r3, [r2+0x40]
  ldxdw r2, [r2+0x48]
  mov64 r4, 0x1
  mov64 r5, 0x1
  jsle r2, 0x0, jmp_470b8
  jeq r3, 0x0, jmp_470c8

jmp_47068:
  jne r2, 0x0, jmp_470d8

jmp_47070:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_470f0

jmp_47080:
  stxdw [r6+0x0], r3
  stxdw [r6+0x8], r2
  and64 r1, 0xff
  neg64 r1
  stxw [r6+0x10], r1
  mov64 r1, 0x0
  ja jmp_46a18

jmp_470b8:
  mov64 r5, 0x0
  jne r3, 0x0, jmp_47068

jmp_470c8:
  mov64 r4, 0x0
  jeq r2, 0x0, jmp_47070

jmp_470d8:
  mov64 r4, r5
  and64 r4, 0x1
  jne r4, 0x0, jmp_47080

jmp_470f0:
  mov64 r1, r10
  add64 r1, -0xb8
  lddw r2, data_171c
  call fn_594a8
  mov64 r1, r10
  add64 r1, -0xa0
  lddw r2, data_171c
  call fn_9838
  lddw r1, str_1c41
  stxdw [r10-0xd0], r1
  stb [r10-0x88], 0x2
  stw [r10-0xc0], 0x185
  stdw [r10-0xc8], 0x30
  stdw [r10-0xd8], 0x0
  stw [r10-0x40], 0x1791
  mov64 r1, r10
  add64 r1, -0x130
  mov64 r2, r10
  add64 r2, -0xd8
  call fn_be760
  ldxdw r1, [r10-0x130]
  ldxdw r2, [r10-0x128]
  ja jmp_46a00

jmp_471c0:
  mov64 r3, r10
  add64 r3, -0x1
  lddw r1, str_12ef
  mov64 r2, 0x37
  lddw r4, data_5e28
  lddw r5, data_5e48
  call fn_cc6f8

fn_47210:
  mov64 r6, r1
  ldxdw r1, [r2+0x10]
  mov64 r8, r1
  add64 r8, 0x10
  ldxdw r2, [r1+0x10]
  lddw r0, 0x7fffffffffffffff
  jge r2, r0, jmp_47440
  ldxdw r7, [r5-0xff8]
  ldxdw r9, [r5-0x1000]
  add64 r2, 0x1
  stxdw [r1+0x10], r2
  ldxdw r2, [r1+0x20]
  jne r2, 0x4b, jmp_474b8
  ldxdw r1, [r1+0x18]
  ldxdw r2, [r1+0x0]
  lddw r5, 0x5d7bf9fb56bbbd19
  jeq r2, r5, jmp_47680
  mov64 r1, r10
  add64 r1, -0x38
  lddw r2, data_16a8
  call fn_594a8
  stdw [r10-0x10], 0x0
  stdw [r10-0x18], 0x1
  stdw [r10-0x20], 0x0
  lddw r1, data_5df8
  stxdw [r10-0x148], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0x150], r1
  lddw r1, 0xe0000020
  stxdw [r10-0x140], r1
  mov64 r2, r10
  add64 r2, -0x150
  lddw r1, data_16a8
  call fn_5a268
  jne r0, 0x0, jmp_48200
  ldxdw r1, [r10-0x10]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0xb8], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xd0], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0xc0], r1
  lddw r1, str_1c71
  stxdw [r10-0xe8], r1
  stw [r10-0x58], 0x17a9
  stb [r10-0xa0], 0x2
  stw [r10-0xd8], 0x1c
  stdw [r10-0xe0], 0x38
  stdw [r10-0xf0], 0x0
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, r10
  add64 r2, -0xf0
  call fn_be760
  ldxdw r1, [r10-0x180]
  ldxdw r2, [r10-0x178]
  ja jmp_47648
