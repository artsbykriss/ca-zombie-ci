.globl entrypoint

fn_0000:
  mov64 r0, r2
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jsgt r1, 0xc, jmp_0058
  jsle r1, 0x5, jmp_0090
  jsle r1, 0x8, jmp_0100
  jsgt r1, 0xa, jmp_01a0
  jne r1, 0x9, jmp_02b8
  lddw r0, 0xa00000000
  ja jmp_0358

jmp_0058:
  jsle r1, 0x12, jmp_00d0
  jsle r1, 0x15, jmp_0128
  jsgt r1, 0x17, jmp_01c0
  jne r1, 0x16, jmp_02d0
  lddw r0, 0x1700000000
  ja jmp_0358

jmp_0090:
  jsgt r1, 0x2, jmp_0150
  jeq r1, 0x0, jmp_0210
  lddw r0, 0x200000000
  jeq r1, 0x1, jmp_0358
  lddw r0, 0x300000000
  ja jmp_0358

jmp_00d0:
  jsgt r1, 0xf, jmp_0178
  jeq r1, 0xd, jmp_0240
  jne r1, 0xe, jmp_0318
  lddw r0, 0xf00000000
  ja jmp_0358

jmp_0100:
  jeq r1, 0x6, jmp_01e0
  jne r1, 0x7, jmp_0288
  lddw r0, 0x800000000
  ja jmp_0358

jmp_0128:
  jeq r1, 0x13, jmp_01f8
  jne r1, 0x14, jmp_02a0
  lddw r0, 0x1500000000
  ja jmp_0358

jmp_0150:
  jeq r1, 0x3, jmp_0258
  jne r1, 0x4, jmp_0330
  lddw r0, 0x500000000
  ja jmp_0358

jmp_0178:
  jeq r1, 0x10, jmp_0270
  jne r1, 0x11, jmp_0348
  lddw r0, 0x1200000000
  ja jmp_0358

jmp_01a0:
  jne r1, 0xb, jmp_02e8
  lddw r0, 0xc00000000
  ja jmp_0358

jmp_01c0:
  jne r1, 0x18, jmp_0300
  lddw r0, 0x1900000000
  ja jmp_0358

jmp_01e0:
  lddw r0, 0x700000000
  ja jmp_0358

jmp_01f8:
  lddw r0, 0x1400000000
  ja jmp_0358

jmp_0210:
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_0358
  lddw r0, 0x100000000
  ja jmp_0358

jmp_0240:
  lddw r0, 0xe00000000
  ja jmp_0358

jmp_0258:
  lddw r0, 0x400000000
  ja jmp_0358

jmp_0270:
  lddw r0, 0x1100000000
  ja jmp_0358

jmp_0288:
  lddw r0, 0x900000000
  ja jmp_0358

jmp_02a0:
  lddw r0, 0x1600000000
  ja jmp_0358

jmp_02b8:
  lddw r0, 0xb00000000
  ja jmp_0358

jmp_02d0:
  lddw r0, 0x1800000000
  ja jmp_0358

jmp_02e8:
  lddw r0, 0xd00000000
  ja jmp_0358

jmp_0300:
  lddw r0, 0x1a00000000
  ja jmp_0358

jmp_0318:
  lddw r0, 0x1000000000
  ja jmp_0358

jmp_0330:
  lddw r0, 0x600000000
  ja jmp_0358

jmp_0348:
  lddw r0, 0x1300000000

jmp_0358:
  exit

fn_0360:
  mov64 r0, 0x1a
  ldxdw r2, [r1+0x48]
  ldxdw r4, [r1+0x50]
  mov64 r3, r4
  jge r2, r4, jmp_05a8
  mov64 r5, r2
  mul64 r5, 0x38
  ldxdw r4, [r1+0x38]
  add64 r4, r5
  ldxdw r0, [r1+0x20]
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, r5
  lsh64 r0, 0x3
  ldxdw r6, [r1+0x0]
  add64 r6, r0
  lsh64 r5, 0x4
  stxdw [r10-0x8], r1
  ldxdw r0, [r1+0x10]
  add64 r5, r0
  add64 r5, 0x8
  mov64 r1, r3
  ja jmp_04c0

jmp_0418:
  mov64 r3, r7
  add64 r3, 0x8
  stxdw [r4+0x0], r3
  mov64 r3, r7
  add64 r3, 0x48
  stxdw [r4+0x8], r3
  ldxdw r3, [r7+0x50]
  mov64 r0, r7
  add64 r0, 0x28
  stxdw [r4+0x20], r0
  mov64 r0, r7
  add64 r0, 0x58
  stxdw [r4+0x18], r0
  stxdw [r4+0x10], r3
  stdw [r4+0x28], 0x0
  ldxw r3, [r7+0x1]
  stxw [r4+0x30], r3
  add64 r5, 0x10
  add64 r6, 0x8
  add64 r4, 0x38
  jge r2, r1, jmp_0588

jmp_04c0:
  add64 r2, 0x1
  ldxdw r0, [r6+0x0]
  ldxdw r7, [r0+0x0]
  ldxdw r8, [r5-0x8]
  ldxdw r0, [r8+0x0]
  ldxdw r9, [r7+0x8]
  jne r9, r0, jmp_0578
  mov64 r0, 0x1
  ldxdw r9, [r8+0x8]
  ldxdw r3, [r7+0x10]
  jne r3, r9, jmp_0598
  ldxdw r3, [r8+0x10]
  ldxdw r9, [r7+0x18]
  jne r9, r3, jmp_0598
  ldxdw r3, [r8+0x18]
  ldxdw r8, [r7+0x20]
  jne r8, r3, jmp_0598
  ldxb r3, [r5+0x0]
  jne r3, 0x1, jmp_0418
  ldxb r3, [r7+0x0]
  jeq r3, 0xff, jmp_0418
  mov64 r0, 0xb
  ja jmp_0598

jmp_0578:
  mov64 r0, 0x1
  ja jmp_0598

jmp_0588:
  mov64 r0, 0x1a
  mov64 r2, r1

jmp_0598:
  ldxdw r1, [r10-0x8]
  stxdw [r1+0x48], r2

jmp_05a8:
  exit

fn_05b0:
  mov64 r6, r1
  ldxdw r1, [r4+0x18]
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r4+0x8]
  ldxdw r7, [r4+0x0]
  lddw r8, -0x42bcf8a191e690bb
  jne r7, r8, jmp_0700
  lddw r8, 0x61fb6bd0dbe5a208
  jne r0, r8, jmp_0700
  lddw r8, 0x72b19992c23bfdc4
  jne r5, r8, jmp_0700
  lddw r8, -0x5f6978a92e5eeea3
  jne r1, r8, jmp_0700
  ldxdw r1, [r2+0x8]
  jne r3, 0x1, jmp_0810
  jne r1, 0x10, jmp_0e48
  ldxdw r1, [r2+0x0]
  ldxdw r5, [r1+0x8]
  lddw r0, 0x797469726f687475
  xor64 r5, r0
  ldxdw r1, [r1+0x0]
  lddw r0, 0x612d656c6361726f
  xor64 r1, r0
  or64 r1, r5
  jne r1, 0x0, jmp_0e48
  lddw r1, 0xff0000001a
  lddw r2, 0x13307c569701ccf8
  lddw r3, -0x78643d3527711a18
  lddw r4, 0x62b92caaf098f98e
  lddw r5, -0x178277b09baa79de
  ja jmp_0ed8

jmp_0700:
  lddw r8, 0x17fee008f3155dfe
  jne r7, r8, jmp_0e48
  lddw r7, -0x70c6ba182ecb4d4d
  jne r0, r7, jmp_0e48
  lddw r0, 0x2d2cf27ef4b22b67
  jne r5, r0, jmp_0e48
  lddw r5, 0x553de8c6eda0600a
  jne r1, r5, jmp_0e48
  ldxdw r1, [r2+0x8]
  jne r3, 0x1, jmp_0908
  jne r1, 0x6, jmp_0e48
  ldxdw r1, [r2+0x0]
  ldxw r5, [r1+0x0]
  ldxh r1, [r1+0x4]
  lsh64 r1, 0x20
  or64 r5, r1
  lddw r1, 0x6769666e6f63
  jne r5, r1, jmp_0e48
  lddw r1, 0xff0000001a
  lddw r2, 0x76af5324775b33a4
  lddw r3, 0x589c4e18ad4e531d
  lddw r4, -0x7610efa892797393
  lddw r5, 0x6485714b2c3e69fa
  ja jmp_0ed8

jmp_0810:
  jeq r1, 0x7, jmp_0a10
  jne r1, 0x6, jmp_0e48
  ldxdw r1, [r2+0x0]
  ldxw r5, [r1+0x0]
  ldxh r1, [r1+0x4]
  lsh64 r1, 0x20
  or64 r5, r1
  lddw r1, 0x736563697270
  jne r5, r1, jmp_0e48
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e48
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0b98
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0c28
  lddw r1, 0xfd0000001a
  lddw r2, 0x7aa80c7bd9b32db0
  lddw r3, -0x4953a499653cb8ce
  lddw r4, 0x389ad8f340cf22c7
  lddw r5, 0x7f2063ee78df879e
  ja jmp_0ed8

jmp_0908:
  jne r1, 0x6, jmp_0e48
  ldxdw r5, [r2+0x0]
  ldxw r1, [r5+0x0]
  ldxh r5, [r5+0x4]
  lsh64 r5, 0x20
  or64 r1, r5
  lddw r5, 0x74656b72616d
  jeq r1, r5, jmp_0b00
  lddw r5, 0x656c6361726f
  jne r1, r5, jmp_0e48
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e48
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0ce8
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0d78
  lddw r1, 0xff0000001a
  lddw r2, -0x1513dc8b1dd9889f
  lddw r3, 0x2e52c0600404c816
  lddw r4, 0x7cb85f1542112856
  lddw r5, -0x6e8ec092166b9542
  ja jmp_0ed8

jmp_0a10:
  ldxdw r1, [r2+0x0]
  ldxh r5, [r1+0x4]
  lsh64 r5, 0x20
  ldxb r0, [r1+0x6]
  lsh64 r0, 0x30
  or64 r0, r5
  ldxw r1, [r1+0x0]
  or64 r1, r0
  lddw r5, 0x73746867696577
  jne r1, r5, jmp_0e48
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e48
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0be0
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0c88
  lddw r2, 0x33ba3ae03c73a294
  lddw r3, 0x27d69e0c3861ab3b
  lddw r4, 0x310af60e6afc1089
  lddw r5, -0x58ec6f1101b2d5f1
  ja jmp_0ed8

jmp_0b00:
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e48
  lddw r1, 0xff0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0d30
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0dd8
  lddw r2, -0x781abfcb1367ecb
  lddw r3, -0x60be4aefd618aaf2
  lddw r4, 0x6b8a6005673cbb10
  lddw r5, 0x29fecfe88a8ae1fd
  ja jmp_0ed8

jmp_0b98:
  lddw r2, 0x55fd4bf665c8920
  lddw r3, 0xf2eb77c77ed9fe3
  lddw r4, 0x55c60d7b6d308c3c
  lddw r5, -0x27ea5f23a1b4d1e
  ja jmp_0ed8

jmp_0be0:
  lddw r2, -0x66feb4aa46e5a3f1
  lddw r3, 0x1a320c12a61e29f2
  lddw r4, -0x477a7f2e0fe308da
  lddw r5, -0x5d81d940a24a0fba
  ja jmp_0ed8

jmp_0c28:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e48
  lddw r2, 0x4cb2f5a683e80249
  lddw r3, 0x3cba9d160b4ffdde
  lddw r4, 0x38e70ffa45cdb189
  lddw r5, 0x6ba52ee8842aac07
  ja jmp_0ed8

jmp_0c88:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e48
  lddw r2, 0x31e9ad9be0f31580
  lddw r3, 0x1fd2f1ec0e49b0b4
  lddw r4, 0x652f22e28b3fe56e
  lddw r5, -0x49f1123b4e612d43
  ja jmp_0ed8

jmp_0ce8:
  lddw r2, 0x1b2ef052ccaa8eb7
  lddw r3, -0x1868c6b8c1b6c194
  lddw r4, 0x6539fa11752014ab
  lddw r5, -0x73a3ee11e18450f6
  ja jmp_0ed8

jmp_0d30:
  lddw r2, 0x37978f41e74b6e70
  lddw r3, -0x4cf1643775f039de
  lddw r4, 0x7dc78f34cedf4f5
  lddw r5, -0x184085da377b6178
  ja jmp_0ed8

jmp_0d78:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e48
  lddw r2, 0xfb473dd5013e4a7
  lddw r3, 0x796087766583034b
  lddw r4, 0x6f602b31a1ad117d
  lddw r5, -0x6afe0ab31641a1fb
  ja jmp_0ed8

jmp_0dd8:
  ldxdw r1, [r2+0x10]
  ldxh r1, [r1+0x0]
  jne r1, 0x2, jmp_0e48
  lddw r1, 0xfd0000001a
  lddw r2, 0x4d863ab181b188b0
  lddw r3, -0x2b84581d3d4a5850
  lddw r4, 0x18df4081bd26c14
  lddw r5, -0x7819d7709597cce3
  ja jmp_0ed8

jmp_0e48:
  stb [r10-0x1], 0xff
  mov64 r0, r10
  add64 r0, -0x28
  mov64 r5, r10
  add64 r5, -0x1
  mov64 r1, r2
  mov64 r2, r3
  mov64 r3, r4
  mov64 r4, r0
  call sol_try_find_program_address
  jne r0, 0x0, jmp_0f38
  ldxdw r2, [r10-0x10]
  ldxdw r3, [r10-0x18]
  ldxdw r4, [r10-0x20]
  ldxdw r5, [r10-0x28]
  ldxb r1, [r10-0x1]
  lsh64 r1, 0x20
  or64 r1, 0x1a

jmp_0ed8:
  lddw r0, 0x200000000
  ldxdw r7, [r6+0x8]
  jne r7, r5, jmp_0f30
  ldxdw r5, [r6+0x10]
  jne r5, r4, jmp_0f30
  ldxdw r4, [r6+0x18]
  jne r4, r3, jmp_0f30
  ldxdw r3, [r6+0x20]
  jne r3, r2, jmp_0f30
  mov64 r0, r1

jmp_0f30:
  exit

jmp_0f38:
  lddw r1, data_05b8
  call fn_14320

fn_0f50:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_0fd8
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_0fd8
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_0fd8
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_0fd8
  ldxb r6, [r2+0x0]
  jge r6, 0x2, jmp_1000
  stb [r1+0x56d], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_0ff8

jmp_0fd8:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0x56d], 0x2

jmp_0ff8:
  exit

jmp_1000:
  mov64 r8, r1
  add64 r6, -0x1
  stxb [r2+0x0], r6
  ldxdw r3, [r2+0x50]
  stxdw [r10-0x578], r2
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x570
  call fn_e7f0
  ldxw r9, [r10-0x570]
  ldxb r7, [r10-0x3]
  jne r7, 0x2, jmp_1080
  stxw [r8+0x4], r9
  stb [r8+0x56d], 0x2
  stw [r8+0x0], 0x0
  ja jmp_10d0

jmp_1080:
  mov64 r1, r8
  add64 r1, 0x4
  mov64 r2, r10
  add64 r2, -0x56c
  mov64 r3, 0x569
  call fn_15658
  ldxh r1, [r10-0x2]
  stxh [r8+0x56e], r1
  stxb [r8+0x56d], r7
  stxw [r8+0x0], r9

jmp_10d0:
  and64 r6, 0xff
  add64 r6, 0x1
  mov64 r1, r6
  and64 r1, 0xff
  ldxdw r2, [r10-0x578]
  jne r1, r6, jmp_1110
  stxb [r2+0x0], r6
  ja jmp_0ff8

jmp_1110:
  lddw r1, data_05d0
  call fn_14350

fn_1128:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_11c0
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_11c0
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_11c0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_11c0
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_11d8
  lddw r2, 0xb00000001
  stxdw [r1+0x0], r2
  stw [r1+0x8], 0x0
  ja jmp_11d0

jmp_11c0:
  stw [r1+0x8], 0x2
  stdw [r1+0x0], 0x1

jmp_11d0:
  exit

jmp_11d8:
  mov64 r4, 0x2
  add64 r3, -0x1
  stxb [r2+0x0], r3
  ldxdw r5, [r2+0x50]
  jne r5, 0x32, jmp_1298
  mov64 r4, 0x13
  ldxdw r5, [r2+0x58]
  lddw r0, 0x31303043524f5443
  jne r5, r0, jmp_1298
  ldxdw r4, [r2+0x62]
  ldxdw r5, [r2+0x6a]
  ldxdw r0, [r2+0x72]
  ldxdw r6, [r2+0x7a]
  ldxdw r7, [r2+0x82]
  ldxh r8, [r2+0x60]
  stxh [r1+0x30], r8
  stxdw [r1+0x28], r7
  stxdw [r1+0x20], r6
  stxdw [r1+0x18], r0
  stxdw [r1+0x10], r5
  stxdw [r1+0x8], r4
  stw [r1+0x0], 0x0
  ja jmp_12a8

jmp_1298:
  stxw [r1+0x8], r4
  stdw [r1+0x0], 0x1

jmp_12a8:
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r1, r3
  and64 r1, 0xff
  jne r1, r3, jmp_12e0
  stxb [r2+0x0], r3
  ja jmp_11d0

jmp_12e0:
  lddw r1, data_05d0
  call fn_14350

fn_12f8:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_1380
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_1380
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_1380
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_1380
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_13a8
  stb [r1+0x1e], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_13a0

jmp_1380:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0x1e], 0x2

jmp_13a0:
  exit

jmp_13a8:
  mov64 r0, 0x2
  add64 r3, -0x1
  stxb [r2+0x0], r3
  ldxdw r4, [r2+0x50]
  jne r4, 0x27, jmp_1428
  mov64 r0, 0x13
  ldxdw r4, [r2+0x58]
  lddw r5, 0x3130544847575443
  jne r4, r5, jmp_1428
  ldxdw r4, [r2+0x62]
  ldxh r5, [r2+0x60]
  ldxb r6, [r2+0x6a]
  jeq r6, 0x0, jmp_1478
  mov64 r0, 0x1
  jeq r6, 0x1, jmp_1480

jmp_1428:
  stxw [r1+0x4], r0
  stb [r1+0x1e], 0x2
  stw [r1+0x0], 0x0

jmp_1440:
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r1, r3
  and64 r1, 0xff
  jne r1, r3, jmp_14f0
  stxb [r2+0x0], r3
  ja jmp_13a0

jmp_1478:
  mov64 r0, 0x0

jmp_1480:
  ldxdw r6, [r2+0x6b]
  ldxdw r7, [r2+0x73]
  ldxh r8, [r2+0x7d]
  ldxh r9, [r2+0x7b]
  stxh [r1+0x18], r9
  stxh [r1+0x1c], r5
  stxh [r1+0x1a], r8
  stxdw [r1+0x10], r7
  stxdw [r1+0x8], r6
  stxb [r1+0x1e], r0
  stxw [r1+0x0], r4
  rsh64 r4, 0x20
  stxw [r1+0x4], r4
  ja jmp_1440

jmp_14f0:
  lddw r1, data_05d0
  call fn_14350

fn_1508:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_1590
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_1590
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_1590
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_1590
  ldxb r6, [r2+0x0]
  jge r6, 0x2, jmp_15b8
  stb [r1+0xbc], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_15b0

jmp_1590:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0xbc], 0x2

jmp_15b0:
  exit

jmp_15b8:
  mov64 r9, r1
  add64 r6, -0x1
  stxb [r2+0x0], r6
  ldxdw r3, [r2+0x50]
  stxdw [r10-0xc8], r2
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0xc0
  call fn_10820
  ldxw r8, [r10-0xc0]
  ldxb r7, [r10-0x4]
  jne r7, 0x2, jmp_1638
  stxw [r9+0x4], r8
  stb [r9+0xbc], 0x2
  stw [r9+0x0], 0x0
  ja jmp_1698

jmp_1638:
  mov64 r1, r9
  add64 r1, 0x4
  mov64 r2, r10
  add64 r2, -0xbc
  mov64 r3, 0xb8
  call fn_15658
  ldxh r1, [r10-0x3]
  stxh [r9+0xbd], r1
  ldxb r1, [r10-0x1]
  stxb [r9+0xbf], r1
  stxb [r9+0xbc], r7
  stxw [r9+0x0], r8

jmp_1698:
  and64 r6, 0xff
  add64 r6, 0x1
  mov64 r1, r6
  and64 r1, 0xff
  ldxdw r2, [r10-0xc8]
  jne r1, r6, jmp_16d8
  stxb [r2+0x0], r6
  ja jmp_15b0

jmp_16d8:
  lddw r1, data_05d0
  call fn_14350

fn_16f0:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_1778
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_1778
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_1778
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_1778
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_17a0
  stb [r1+0x152], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_1798

jmp_1778:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0x152], 0x2

jmp_1798:
  exit

jmp_17a0:
  mov64 r4, 0x2
  add64 r3, -0x1
  stxb [r2+0x0], r3
  ldxdw r5, [r2+0x50]
  jeq r5, 0x15b, jmp_1848
  jeq r5, 0x15a, jmp_1810
  jne r5, 0x156, jmp_2588
  ldxdw r0, [r2+0x58]
  lddw r6, 0x3330304746435443
  jne r0, r6, jmp_2588
  mov64 r6, 0x1
  mov64 r0, 0x0
  ja jmp_1878

jmp_1810:
  ldxdw r0, [r2+0x58]
  lddw r6, 0x3430304746435443
  jne r0, r6, jmp_2588
  mov64 r6, 0x0
  mov64 r0, 0x1
  ja jmp_1878

jmp_1848:
  mov64 r0, 0x0
  ldxdw r7, [r2+0x58]
  lddw r8, 0x3530304746435443
  mov64 r6, 0x0
  jne r7, r8, jmp_2588

jmp_1878:
  mov64 r8, 0x0
  mov64 r4, 0x1
  ldxw r7, [r2+0x183]
  stxdw [r10-0x1a8], r7
  ldxw r7, [r2+0x163]
  stxdw [r10-0x1b0], r7
  ldxw r7, [r2+0x143]
  stxdw [r10-0x1b8], r7
  ldxw r7, [r2+0x123]
  stxdw [r10-0x1c0], r7
  ldxw r7, [r2+0x103]
  stxdw [r10-0x1c8], r7
  ldxw r7, [r2+0xe3]
  stxdw [r10-0x1d0], r7
  ldxw r7, [r2+0xc3]
  stxdw [r10-0x1d8], r7
  ldxw r7, [r2+0xa3]
  stxdw [r10-0x1e0], r7
  ldxw r7, [r2+0x83]
  stxdw [r10-0x1e8], r7
  ldxw r7, [r2+0x63]
  stxdw [r10-0x1f0], r7
  ldxb r7, [r2+0x1a0]
  mov64 r9, 0x0
  stxdw [r10-0x1a0], r9
  jeq r7, 0x0, jmp_1960
  jne r7, 0x1, jmp_2588
  mov64 r7, 0x1
  stxdw [r10-0x1a0], r7

jmp_1960:
  ldxb r7, [r2+0x1a1]
  jeq r7, 0x0, jmp_1980
  jne r7, 0x1, jmp_2588
  mov64 r8, 0x1

jmp_1980:
  ldxw r9, [r2+0x1aa]
  ldxdw r7, [r2+0x1a2]
  jeq r6, 0x0, jmp_24e8
  jne r5, 0x156, jmp_2588
  mov64 r4, 0x0
  stxdw [r10-0x200], r4
  mov64 r6, 0x32

jmp_19b8:
  stxdw [r10-0x1f8], r6
  mov64 r4, r2
  add64 r4, 0x187
  stxdw [r10-0x220], r4
  mov64 r4, r2
  add64 r4, 0x180
  stxdw [r10-0x228], r4
  mov64 r4, r2
  add64 r4, 0x167
  stxdw [r10-0x230], r4
  mov64 r4, r2
  add64 r4, 0x160
  stxdw [r10-0x238], r4
  mov64 r4, r2
  add64 r4, 0x147
  stxdw [r10-0x240], r4
  mov64 r4, r2
  add64 r4, 0x140
  stxdw [r10-0x248], r4
  mov64 r4, r2
  add64 r4, 0x127
  stxdw [r10-0x250], r4
  mov64 r4, r2
  add64 r4, 0x120
  stxdw [r10-0x258], r4
  mov64 r4, r2
  add64 r4, 0x107
  stxdw [r10-0x260], r4
  mov64 r4, r2
  add64 r4, 0x100
  stxdw [r10-0x268], r4
  mov64 r4, r2
  add64 r4, 0xe7
  stxdw [r10-0x270], r4
  mov64 r4, r2
  add64 r4, 0xe0
  stxdw [r10-0x278], r4
  mov64 r4, r2
  add64 r4, 0xc7
  stxdw [r10-0x280], r4
  mov64 r4, r2
  add64 r4, 0xc0
  stxdw [r10-0x288], r4
  stxdw [r10-0x210], r8
  mov64 r8, r2
  add64 r8, 0xa7
  stxdw [r10-0x208], r7
  mov64 r7, r2
  add64 r7, 0xa0
  mov64 r0, r2
  add64 r0, 0x87
  mov64 r6, r2
  add64 r6, 0x80
  mov64 r4, r2
  add64 r4, 0x67
  mov64 r5, r2
  add64 r5, 0x60
  stxdw [r10-0x218], r9
  ldxb r9, [r5+0x2]
  stxb [r10-0x6], r9
  ldxh r5, [r5+0x0]
  stxh [r10-0x8], r5
  ldxdw r5, [r10-0x1f0]
  stxw [r10-0x5], r5
  ldxb r5, [r4+0x18]
  stxb [r10-0x10], r5
  ldxdw r5, [r4+0x10]
  stxdw [r10-0x18], r5
  ldxdw r5, [r4+0x8]
  stxdw [r10-0x20], r5
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x28], r4
  ldxb r4, [r6+0x2]
  stxb [r10-0x2e], r4
  ldxh r4, [r6+0x0]
  stxh [r10-0x30], r4
  ldxb r4, [r0+0x18]
  stxb [r10-0x38], r4
  ldxdw r4, [r0+0x10]
  stxdw [r10-0x40], r4
  ldxdw r4, [r0+0x8]
  stxdw [r10-0x48], r4
  ldxdw r4, [r0+0x0]
  stxdw [r10-0x50], r4
  ldxb r4, [r7+0x2]
  stxb [r10-0x56], r4
  ldxh r4, [r7+0x0]
  stxh [r10-0x58], r4
  ldxb r4, [r8+0x18]
  stxb [r10-0x60], r4
  ldxdw r4, [r8+0x10]
  stxdw [r10-0x68], r4
  ldxdw r4, [r8+0x8]
  stxdw [r10-0x70], r4
  ldxdw r4, [r8+0x0]
  stxdw [r10-0x78], r4
  ldxdw r5, [r10-0x288]
  ldxb r4, [r5+0x2]
  stxb [r10-0x7e], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0x80], r4
  ldxdw r5, [r10-0x280]
  ldxb r4, [r5+0x18]
  stxb [r10-0x88], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0x90], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x98], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0xa0], r4
  ldxdw r5, [r10-0x278]
  ldxb r4, [r5+0x2]
  stxb [r10-0xa6], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0xa8], r4
  ldxdw r5, [r10-0x270]
  ldxb r4, [r5+0x18]
  stxb [r10-0xb0], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0xb8], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0xc0], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0xc8], r4
  ldxdw r5, [r10-0x268]
  ldxb r4, [r5+0x2]
  stxb [r10-0xce], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0xd0], r4
  ldxdw r5, [r10-0x260]
  ldxb r4, [r5+0x18]
  stxb [r10-0xd8], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0xe0], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0xe8], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0xf0], r4
  ldxdw r5, [r10-0x258]
  ldxb r4, [r5+0x2]
  stxb [r10-0xf6], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0xf8], r4
  ldxdw r5, [r10-0x250]
  ldxb r4, [r5+0x18]
  stxb [r10-0x100], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0x108], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x110], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0x118], r4
  ldxdw r5, [r10-0x248]
  ldxb r4, [r5+0x2]
  stxb [r10-0x11e], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0x120], r4
  ldxdw r5, [r10-0x240]
  ldxb r4, [r5+0x18]
  stxb [r10-0x128], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0x130], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x138], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0x140], r4
  ldxdw r5, [r10-0x238]
  ldxb r4, [r5+0x2]
  stxb [r10-0x146], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0x148], r4
  ldxdw r5, [r10-0x230]
  ldxb r4, [r5+0x18]
  stxb [r10-0x150], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0x158], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x160], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0x168], r4
  ldxdw r5, [r10-0x228]
  ldxb r4, [r5+0x2]
  stxb [r10-0x16e], r4
  ldxh r4, [r5+0x0]
  stxh [r10-0x170], r4
  ldxdw r5, [r10-0x220]
  ldxb r4, [r5+0x18]
  stxb [r10-0x178], r4
  ldxdw r4, [r5+0x10]
  stxdw [r10-0x180], r4
  ldxdw r4, [r5+0x8]
  stxdw [r10-0x188], r4
  ldxdw r4, [r5+0x0]
  stxdw [r10-0x190], r4
  ldxw r4, [r10-0x8]
  ldxb r5, [r10-0x2]
  stxb [r1+0x6], r5
  ldxh r5, [r10-0x4]
  stxh [r1+0x4], r5
  ldxdw r5, [r10-0x28]
  stxdw [r1+0x7], r5
  ldxdw r5, [r10-0x20]
  stxdw [r1+0xf], r5
  ldxdw r5, [r10-0x18]
  stxdw [r1+0x17], r5
  ldxb r5, [r10-0x10]
  stxb [r1+0x1f], r5
  ldxh r5, [r10-0x30]
  stxh [r1+0x20], r5
  ldxb r5, [r10-0x2e]
  stxb [r1+0x22], r5
  ldxdw r5, [r10-0x1e8]
  stxw [r1+0x23], r5
  ldxdw r5, [r10-0x50]
  stxdw [r1+0x27], r5
  ldxdw r5, [r10-0x48]
  stxdw [r1+0x2f], r5
  ldxdw r5, [r10-0x40]
  stxdw [r1+0x37], r5
  ldxb r5, [r10-0x38]
  stxb [r1+0x3f], r5
  ldxh r5, [r10-0x58]
  stxh [r1+0x40], r5
  ldxb r5, [r10-0x56]
  ldxdw r0, [r10-0x1e0]
  stxw [r1+0x43], r0
  stxb [r1+0x42], r5
  ldxb r5, [r10-0x60]
  stxb [r1+0x5f], r5
  ldxdw r5, [r10-0x68]
  stxdw [r1+0x57], r5
  ldxdw r5, [r10-0x70]
  stxdw [r1+0x4f], r5
  ldxdw r5, [r10-0x78]
  stxdw [r1+0x47], r5
  ldxb r5, [r10-0x7e]
  ldxh r0, [r10-0x80]
  ldxdw r6, [r10-0x1d8]
  stxw [r1+0x63], r6
  stxh [r1+0x60], r0
  stxb [r1+0x62], r5
  ldxb r5, [r10-0x88]
  stxb [r1+0x7f], r5
  ldxdw r5, [r10-0x90]
  stxdw [r1+0x77], r5
  ldxdw r5, [r10-0x98]
  stxdw [r1+0x6f], r5
  ldxdw r5, [r10-0xa0]
  stxdw [r1+0x67], r5
  ldxb r5, [r10-0xa6]
  stxb [r1+0x82], r5
  ldxh r5, [r10-0xa8]
  stxh [r1+0x80], r5
  ldxdw r5, [r10-0x1d0]
  stxw [r1+0x83], r5
  ldxb r5, [r10-0xb0]
  stxb [r1+0x9f], r5
  ldxdw r5, [r10-0xb8]
  stxdw [r1+0x97], r5
  ldxdw r5, [r10-0xc0]
  stxdw [r1+0x8f], r5
  ldxdw r5, [r10-0xc8]
  stxdw [r1+0x87], r5
  ldxb r5, [r10-0xce]
  stxb [r1+0xa2], r5
  ldxh r5, [r10-0xd0]
  stxh [r1+0xa0], r5
  ldxdw r5, [r10-0x1c8]
  stxw [r1+0xa3], r5
  ldxb r5, [r10-0xd8]
  stxb [r1+0xbf], r5
  ldxdw r5, [r10-0xe0]
  stxdw [r1+0xb7], r5
  ldxdw r5, [r10-0xe8]
  stxdw [r1+0xaf], r5
  ldxdw r5, [r10-0xf0]
  stxdw [r1+0xa7], r5
  ldxb r5, [r10-0xf6]
  stxb [r1+0xc2], r5
  ldxh r5, [r10-0xf8]
  stxh [r1+0xc0], r5
  ldxdw r5, [r10-0x1c0]
  stxw [r1+0xc3], r5
  ldxb r5, [r10-0x100]
  stxb [r1+0xdf], r5
  ldxdw r5, [r10-0x108]
  stxdw [r1+0xd7], r5
  ldxdw r5, [r10-0x110]
  stxdw [r1+0xcf], r5
  ldxdw r5, [r10-0x118]
  stxdw [r1+0xc7], r5
  ldxb r5, [r10-0x11e]
  stxb [r1+0xe2], r5
  ldxh r5, [r10-0x120]
  stxh [r1+0xe0], r5
  ldxdw r5, [r10-0x1b8]
  stxw [r1+0xe3], r5
  ldxb r5, [r10-0x128]
  stxb [r1+0xff], r5
  ldxdw r5, [r10-0x130]
  stxdw [r1+0xf7], r5
  ldxdw r5, [r10-0x138]
  stxdw [r1+0xef], r5
  ldxdw r5, [r10-0x140]
  stxdw [r1+0xe7], r5
  ldxb r5, [r10-0x146]
  stxb [r1+0x102], r5
  ldxh r5, [r10-0x148]
  stxh [r1+0x100], r5
  ldxdw r5, [r10-0x1b0]
  stxw [r1+0x103], r5
  ldxb r5, [r10-0x150]
  stxb [r1+0x11f], r5
  ldxdw r5, [r10-0x158]
  stxdw [r1+0x117], r5
  ldxdw r5, [r10-0x160]
  stxdw [r1+0x10f], r5
  ldxdw r5, [r10-0x168]
  stxdw [r1+0x107], r5
  ldxb r5, [r10-0x16e]
  stxb [r1+0x122], r5
  ldxh r5, [r10-0x170]
  stxh [r1+0x120], r5
  ldxdw r5, [r10-0x1a8]
  stxw [r1+0x123], r5
  ldxb r5, [r10-0x178]
  stxb [r1+0x13f], r5
  ldxdw r5, [r10-0x180]
  stxdw [r1+0x137], r5
  ldxdw r5, [r10-0x188]
  stxdw [r1+0x12f], r5
  ldxdw r5, [r10-0x190]
  stxdw [r1+0x127], r5
  ldxdw r5, [r10-0x210]
  stxb [r1+0x151], r5
  ldxdw r5, [r10-0x1a0]
  stxb [r1+0x150], r5
  ldxdw r5, [r10-0x1f8]
  stxw [r1+0x14c], r5
  ldxdw r5, [r10-0x218]
  stxw [r1+0x148], r5
  ldxdw r5, [r10-0x208]
  stxdw [r1+0x140], r5
  ldxb r5, [r10-0x191]
  stxb [r1+0x157], r5
  ldxw r5, [r10-0x195]
  stxw [r1+0x153], r5
  ldxdw r5, [r10-0x200]
  stxb [r1+0x152], r5
  stxw [r1+0x0], r4
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r1, r3
  and64 r1, 0xff
  jeq r1, r3, jmp_25c8

jmp_24d0:
  lddw r1, data_05d0
  call fn_14350

jmp_24e8:
  jlt r5, 0x15a, jmp_2588
  mov64 r6, 0x0
  stxdw [r10-0x200], r6
  ldxw r6, [r2+0x1ae]
  stxdw [r10-0x1f8], r6
  jeq r0, 0x0, jmp_2548
  mov64 r0, 0x15a

jmp_2520:
  ldxdw r6, [r10-0x1f8]
  jne r0, r5, jmp_2588
  mov64 r4, 0x2
  jlt r6, 0x3e9, jmp_19b8
  ja jmp_2588

jmp_2548:
  jeq r5, 0x15a, jmp_2588
  mov64 r0, 0x15b
  ldxb r6, [r2+0x1b2]
  jeq r6, 0x0, jmp_2520
  jne r6, 0x1, jmp_2588
  mov64 r6, 0x1
  stxdw [r10-0x200], r6
  ja jmp_2520

jmp_2588:
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r5, r3
  and64 r5, 0xff
  stxw [r1+0x4], r4
  stb [r1+0x152], 0x2
  stw [r1+0x0], 0x0
  jne r5, r3, jmp_24d0

jmp_25c8:
  stxb [r2+0x0], r3
  ja jmp_1798

fn_25d8:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_2660
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_2660
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_2660
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_2660
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_2688
  stb [r1+0xb8], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_2680

jmp_2660:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0xb8], 0x2

jmp_2680:
  exit

jmp_2688:
  add64 r3, -0x1
  stxb [r2+0x0], r3
  mov64 r0, 0x2
  ldxdw r7, [r2+0x50]
  jeq r7, 0xc1, jmp_26e8
  jne r7, 0xb9, jmp_30b0
  mov64 r8, 0x1
  ldxdw r3, [r2+0x58]
  lddw r4, 0x343030544b4d5443
  jeq r3, r4, jmp_2710
  ja jmp_30b0

jmp_26e8:
  mov64 r8, 0x0
  ldxdw r3, [r2+0x58]
  lddw r4, 0x353030544b4d5443
  jne r3, r4, jmp_30b0

jmp_2710:
  mov64 r0, 0x1
  ldxh r6, [r2+0x62]
  ldxh r5, [r2+0x60]
  ldxb r3, [r2+0x64]
  mov64 r4, 0x0
  jeq r3, 0x0, jmp_2750
  jne r3, 0x1, jmp_30b0
  mov64 r4, 0x1

jmp_2750:
  mov64 r3, 0x0
  stxdw [r10-0xa0], r3
  stxdw [r10-0xb8], r6
  stxdw [r10-0xb0], r5
  stxdw [r10-0xa8], r4
  ldxb r3, [r2+0xa7]
  ldxh r4, [r2+0xa5]
  stxdw [r10-0x88], r4
  ldxb r9, [r2+0x87]
  ldxh r4, [r2+0x85]
  stxdw [r10-0x140], r4
  ldxb r4, [r2+0xe7]
  ldxh r6, [r2+0xe5]
  stxdw [r10-0x150], r6
  ldxb r5, [r2+0xc7]
  stxdw [r10-0x180], r5
  ldxh r6, [r2+0xc5]
  stxdw [r10-0x158], r6
  ldxb r5, [r2+0x77]
  stxdw [r10-0x178], r5
  ldxh r6, [r2+0x75]
  stxdw [r10-0x128], r6
  ldxb r5, [r2+0xd7]
  stxdw [r10-0x170], r5
  ldxh r6, [r2+0xd5]
  stxdw [r10-0x138], r6
  ldxb r5, [r2+0xb7]
  stxdw [r10-0x168], r5
  ldxh r6, [r2+0xb5]
  stxdw [r10-0x148], r6
  ldxb r5, [r2+0x97]
  stxdw [r10-0x160], r5
  ldxh r6, [r2+0x95]
  stxdw [r10-0x130], r6
  ldxw r6, [r2+0xc8]
  stxdw [r10-0x60], r6
  ldxw r6, [r2+0xe8]
  stxdw [r10-0x8], r6
  ldxw r6, [r2+0x88]
  stxdw [r10-0x48], r6
  ldxw r6, [r2+0xa8]
  stxdw [r10-0x68], r6
  ldxw r6, [r2+0xb8]
  stxdw [r10-0x78], r6
  ldxw r6, [r2+0xd8]
  stxdw [r10-0x10], r6
  ldxw r6, [r2+0x78]
  stxdw [r10-0x70], r6
  ldxw r6, [r2+0x98]
  stxdw [r10-0x80], r6
  ldxb r6, [r2+0xf4]
  stxdw [r10-0x18], r6
  ldxdw r6, [r2+0xec]
  stxdw [r10-0x98], r6
  ldxb r6, [r2+0xe4]
  stxdw [r10-0x20], r6
  ldxdw r6, [r2+0xdc]
  stxdw [r10-0x90], r6
  ldxb r6, [r2+0xd4]
  stxdw [r10-0x28], r6
  ldxdw r6, [r2+0xcc]
  stxdw [r10-0x120], r6
  ldxb r6, [r2+0xc4]
  stxdw [r10-0x30], r6
  ldxdw r6, [r2+0xbc]
  stxdw [r10-0x118], r6
  ldxb r6, [r2+0xb4]
  stxdw [r10-0x38], r6
  ldxdw r6, [r2+0xac]
  stxdw [r10-0x110], r6
  ldxb r6, [r2+0xa4]
  stxdw [r10-0x40], r6
  ldxdw r6, [r2+0x9c]
  stxdw [r10-0x108], r6
  ldxb r6, [r2+0x94]
  stxdw [r10-0x50], r6
  ldxdw r6, [r2+0x8c]
  stxdw [r10-0x100], r6
  ldxb r6, [r2+0x84]
  stxdw [r10-0x58], r6
  ldxdw r6, [r2+0x7c]
  stxdw [r10-0xf8], r6
  ldxh r6, [r2+0x10f]
  stxdw [r10-0xf0], r6
  ldxh r6, [r2+0x10d]
  stxdw [r10-0xe8], r6
  ldxdw r6, [r2+0x105]
  stxdw [r10-0xe0], r6
  ldxdw r6, [r2+0xfd]
  stxdw [r10-0xd8], r6
  ldxdw r6, [r2+0xf5]
  stxdw [r10-0xd0], r6
  ldxdw r6, [r2+0x6d]
  stxdw [r10-0xc8], r6
  ldxdw r5, [r2+0x65]
  stxdw [r10-0xc0], r5
  jeq r8, 0x0, jmp_2a68
  mov64 r8, 0xb9
  ja jmp_2a88

jmp_2a68:
  jlt r7, 0xc1, jmp_30b0
  mov64 r8, 0xc1
  ldxdw r6, [r2+0x111]
  stxdw [r10-0xa0], r6

jmp_2a88:
  jne r8, r7, jmp_30b0
  lsh64 r3, 0x10
  ldxdw r5, [r10-0x88]
  or64 r5, r3
  stxdw [r10-0x88], r5
  lsh64 r9, 0x10
  ldxdw r8, [r10-0x140]
  or64 r8, r9
  lsh64 r4, 0x10
  ldxdw r3, [r10-0x150]
  or64 r3, r4
  ldxdw r4, [r10-0x180]
  lsh64 r4, 0x10
  ldxdw r6, [r10-0x158]
  or64 r6, r4
  ldxdw r4, [r10-0x178]
  lsh64 r4, 0x10
  ldxdw r0, [r10-0x128]
  or64 r0, r4
  ldxdw r4, [r10-0x170]
  lsh64 r4, 0x10
  ldxdw r7, [r10-0x138]
  or64 r7, r4
  ldxdw r4, [r10-0x168]
  lsh64 r4, 0x10
  ldxdw r9, [r10-0x148]
  or64 r9, r4
  ldxdw r5, [r10-0x160]
  lsh64 r5, 0x10
  ldxdw r4, [r10-0x130]
  or64 r4, r5
  ldxdw r5, [r10-0x60]
  lsh64 r5, 0x18
  or64 r5, r6
  stxdw [r10-0x60], r5
  ldxdw r5, [r10-0x8]
  lsh64 r5, 0x18
  or64 r5, r3
  stxdw [r10-0x8], r5
  ldxdw r3, [r10-0x48]
  lsh64 r3, 0x18
  or64 r3, r8
  stxdw [r10-0x48], r3
  ldxdw r3, [r10-0x68]
  lsh64 r3, 0x18
  ldxdw r5, [r10-0x88]
  or64 r3, r5
  stxdw [r10-0x68], r3
  ldxdw r3, [r10-0x78]
  lsh64 r3, 0x18
  or64 r3, r9
  stxdw [r10-0x78], r3
  ldxdw r3, [r10-0x10]
  lsh64 r3, 0x18
  or64 r3, r7
  stxdw [r10-0x10], r3
  ldxdw r3, [r10-0x70]
  lsh64 r3, 0x18
  or64 r3, r0
  stxdw [r10-0x70], r3
  ldxdw r3, [r10-0x80]
  lsh64 r3, 0x18
  or64 r3, r4
  stxdw [r10-0x80], r3
  ldxdw r4, [r10-0x18]
  lsh64 r4, 0x38
  ldxdw r3, [r10-0x98]
  rsh64 r3, 0x8
  or64 r4, r3
  stxdw [r10-0x18], r4
  ldxdw r4, [r10-0x20]
  lsh64 r4, 0x38
  ldxdw r3, [r10-0x90]
  rsh64 r3, 0x8
  or64 r4, r3
  stxdw [r10-0x20], r4
  ldxdw r5, [r10-0x38]
  ldxdw r4, [r10-0x50]
  ldxdw r0, [r10-0x28]
  lsh64 r0, 0x38
  ldxdw r8, [r10-0x120]
  mov64 r3, r8
  rsh64 r3, 0x8
  or64 r0, r3
  stxdw [r10-0x28], r0
  ldxdw r0, [r10-0x30]
  lsh64 r0, 0x38
  ldxdw r7, [r10-0x118]
  mov64 r3, r7
  rsh64 r3, 0x8
  or64 r0, r3
  stxdw [r10-0x30], r0
  lsh64 r5, 0x38
  ldxdw r9, [r10-0x110]
  mov64 r3, r9
  rsh64 r3, 0x8
  or64 r5, r3
  stxdw [r10-0x38], r5
  ldxdw r5, [r10-0x40]
  lsh64 r5, 0x38
  ldxdw r0, [r10-0x108]
  mov64 r3, r0
  rsh64 r3, 0x8
  or64 r5, r3
  stxdw [r10-0x40], r5
  lsh64 r4, 0x38
  ldxdw r5, [r10-0x100]
  mov64 r3, r5
  rsh64 r3, 0x8
  or64 r4, r3
  stxdw [r10-0x50], r4
  ldxdw r4, [r10-0x58]
  lsh64 r4, 0x38
  ldxdw r6, [r10-0xf8]
  mov64 r3, r6
  rsh64 r3, 0x8
  or64 r4, r3
  stxdw [r10-0x58], r4
  ldxdw r4, [r10-0x98]
  lsh64 r4, 0x38
  ldxdw r3, [r10-0x8]
  or64 r3, r4
  stxdw [r10-0x8], r3
  ldxdw r4, [r10-0x90]
  lsh64 r4, 0x38
  ldxdw r3, [r10-0x10]
  or64 r3, r4
  stxdw [r10-0x10], r3
  lsh64 r8, 0x38
  ldxdw r3, [r10-0x60]
  or64 r3, r8
  lsh64 r7, 0x38
  ldxdw r8, [r10-0x78]
  or64 r8, r7
  lsh64 r9, 0x38
  ldxdw r7, [r10-0x68]
  or64 r7, r9
  lsh64 r0, 0x38
  ldxdw r9, [r10-0x80]
  or64 r9, r0
  lsh64 r5, 0x38
  ldxdw r0, [r10-0x48]
  or64 r0, r5
  lsh64 r6, 0x38
  ldxdw r5, [r10-0x70]
  or64 r5, r6
  ldxdw r4, [r10-0x8]
  stxdw [r1+0x80], r4
  ldxdw r4, [r10-0x10]
  stxdw [r1+0x70], r4
  stxdw [r1+0x60], r3
  stxdw [r1+0x50], r8
  stxdw [r1+0x40], r7
  stxdw [r1+0x30], r9
  stxdw [r1+0x20], r0
  stxdw [r1+0x10], r5
  ldxdw r3, [r10-0xf0]
  stxh [r1+0xb6], r3
  ldxdw r3, [r10-0xe8]
  stxh [r1+0xb4], r3
  ldxdw r3, [r10-0xb8]
  stxh [r1+0xb2], r3
  ldxdw r3, [r10-0xb0]
  stxh [r1+0xb0], r3
  ldxdw r3, [r10-0xa0]
  stxdw [r1+0xa8], r3
  ldxdw r3, [r10-0xe0]
  stxdw [r1+0xa0], r3
  ldxdw r3, [r10-0xd8]
  stxdw [r1+0x98], r3
  ldxdw r3, [r10-0xd0]
  stxdw [r1+0x90], r3
  ldxdw r3, [r10-0xc8]
  stxdw [r1+0x8], r3
  ldxdw r3, [r10-0xa8]
  stxb [r1+0xb8], r3
  ldxdw r3, [r10-0x18]
  stxdw [r1+0x88], r3
  ldxdw r3, [r10-0x20]
  stxdw [r1+0x78], r3
  ldxdw r3, [r10-0x28]
  stxdw [r1+0x68], r3
  ldxdw r3, [r10-0x30]
  stxdw [r1+0x58], r3
  ldxdw r3, [r10-0x38]
  stxdw [r1+0x48], r3
  ldxdw r3, [r10-0x40]
  stxdw [r1+0x38], r3
  ldxdw r3, [r10-0x50]
  stxdw [r1+0x28], r3
  ldxdw r3, [r10-0x58]
  stxdw [r1+0x18], r3
  ldxdw r3, [r10-0xc0]
  stxw [r1+0x0], r3
  rsh64 r3, 0x20
  stxw [r1+0x4], r3
  ja jmp_30c8

jmp_30b0:
  stxw [r1+0x4], r0
  stb [r1+0xb8], 0x2
  stw [r1+0x0], 0x0

jmp_30c8:
  ldxb r1, [r2+0x0]
  add64 r1, 0x1
  mov64 r3, r1
  and64 r3, 0xff
  jne r3, r1, jmp_3100
  stxb [r2+0x0], r1
  ja jmp_2680

jmp_3100:
  lddw r1, data_05d0
  call fn_14350

fn_3118:
  ldxb r3, [r1+0x2]
  jeq r3, 0x0, jmp_3150
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_3168
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_31e0

jmp_3150:
  mov64 r0, 0x0
  mov64 r1, 0x2
  ja jmp_31e0

jmp_3168:
  ldxdw r3, [r1+0x50]
  mov64 r4, r1
  add64 r4, 0x58
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, r4
  call fn_10b98
  mov64 r1, r0
  stb [r6+0x0], 0xff
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_31d8
  mov64 r0, 0x0
  ja jmp_31e0

jmp_31d8:
  mov64 r0, 0x1a

jmp_31e0:
  exit

fn_31e8:
  ldxb r3, [r1+0x2]
  jeq r3, 0x0, jmp_3220
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_3238
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_32b8

jmp_3220:
  mov64 r0, 0x0
  mov64 r1, 0x2
  ja jmp_32b8

jmp_3238:
  stb [r1+0x0], 0x0
  ldxdw r3, [r1+0x50]
  mov64 r4, r1
  add64 r4, 0x58
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, r4
  call fn_f118
  mov64 r1, r0
  stb [r6+0x0], 0xff
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_32b0
  mov64 r0, 0x0
  ja jmp_32b8

jmp_32b0:
  mov64 r0, 0x1a

jmp_32b8:
  exit

fn_32c0:
  ldxdw r5, [r1+0x48]
  mov64 r0, r3
  sub64 r0, r5
  mov64 r4, 0x0
  mov64 r6, 0x1
  jle r0, r3, jmp_3310
  jeq r6, 0x0, jmp_3320

jmp_32f8:
  mov64 r0, 0x1a
  jgt r3, r5, jmp_3338
  ja jmp_3390

jmp_3310:
  mov64 r6, 0x0
  jne r6, 0x0, jmp_32f8

jmp_3320:
  mov64 r4, r0
  mov64 r0, 0x1a
  jle r3, r5, jmp_3390

jmp_3338:
  mov64 r0, 0x0
  ldxdw r3, [r2+0x28]
  jne r3, 0x0, jmp_3390
  ldxdw r3, [r2+0x30]
  jne r3, 0x0, jmp_3390
  ldxdw r3, [r2+0x38]
  jne r3, 0x0, jmp_3390
  ldxdw r3, [r2+0x40]
  jne r3, 0x0, jmp_3390
  ldxdw r3, [r2+0x50]
  jeq r3, 0x0, jmp_3398

jmp_3390:
  exit

jmp_3398:
  ldxb r3, [r2+0x2]
  jeq r3, 0x0, jmp_3390
  ldxdw r3, [r2+0x48]
  jlt r3, r4, jmp_3390
  mov64 r3, r1
  add64 r3, 0x8
  stxdw [r10-0xb8], r3
  mov64 r5, r2
  add64 r5, 0x8
  stxdw [r10-0xc8], r5
  sth [r10-0xb0], 0x1
  sth [r10-0xc0], 0x101
  stxdw [r10-0xa0], r4
  stw [r10-0xa4], 0x2
  ldxb r4, [r2+0x0]
  ldxb r6, [r1+0x0]
  and64 r6, r4
  mov64 r0, 0xb
  jne r6, 0xff, jmp_3390
  mov64 r4, r1
  add64 r4, 0x48
  mov64 r0, r2
  add64 r0, 0x28
  mov64 r6, r2
  add64 r6, 0x48
  stxdw [r10-0x78], r0
  stxdw [r10-0x90], r6
  stxdw [r10-0x98], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x80], r5
  stdw [r10-0x70], 0x0
  stdw [r10-0x88], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x58], r4
  stxdw [r10-0x60], r3
  stxw [r10-0x68], r2
  ldxdw r2, [r1+0x50]
  mov64 r3, r1
  add64 r3, 0x28
  stxdw [r10-0x40], r3
  mov64 r3, r1
  add64 r3, 0x58
  stxdw [r10-0x48], r3
  stxdw [r10-0x50], r2
  stdw [r10-0x38], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0xa4
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x20], r1
  lddw r1, data_0308
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0xc
  stdw [r10-0x18], 0x2
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_3390

fn_35c0:
  mov64 r7, r2
  mov64 r2, r1
  mov64 r0, 0x0
  ldxb r1, [r7+0x1]
  jeq r1, 0x0, jmp_37f8
  mov64 r1, 0x2
  ldxb r6, [r2+0x2]
  jeq r6, 0x0, jmp_3800
  ldxb r6, [r7+0x2]
  jeq r6, 0x0, jmp_3800
  ldxb r6, [r2+0x3]
  jne r6, 0x0, jmp_3800
  mov64 r1, 0x12
  ldxdw r6, [r2+0x50]
  jne r6, 0x0, jmp_3800
  ldxdw r6, [r2+0x28]
  jne r6, 0x0, jmp_3800
  ldxdw r6, [r2+0x30]
  jne r6, 0x0, jmp_3800
  ldxdw r6, [r2+0x38]
  jne r6, 0x0, jmp_3800
  ldxdw r6, [r2+0x40]
  jne r6, 0x0, jmp_3800
  ldxdw r9, [r5-0xff8]
  ldxdw r8, [r5-0x1000]
  stxdw [r10-0x160], r2
  mov64 r1, r2
  mov64 r6, r3
  mov64 r2, r3
  mov64 r3, 0x2
  call fn_05b0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_3800
  stxb [r10-0x151], r1
  stdw [r10-0x108], 0x0
  stdw [r10-0x110], 0x1
  stdw [r10-0x118], 0x0
  stdw [r10-0x120], 0x1
  ldxdw r1, [r6+0x0]
  ldxdw r2, [r6+0x8]
  stxdw [r10-0x148], r2
  stxdw [r10-0x150], r1
  ldxdw r1, [r6+0x10]
  ldxdw r2, [r6+0x18]
  mov64 r3, r10
  add64 r3, -0x151
  stxdw [r10-0x130], r3
  stxdw [r10-0x138], r2
  stxdw [r10-0x140], r1
  stdw [r10-0x128], 0x1
  mov64 r1, r10
  add64 r1, -0x150
  stxdw [r10-0x100], r1
  stdw [r10-0xf8], 0x3
  mov64 r2, r10
  add64 r2, -0x98
  lddw r1, data_02e8
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_3808
  mov64 r0, 0x10
  jne r1, 0x1, jmp_37f0
  mov64 r0, 0x1

jmp_37f0:
  ja jmp_3800

jmp_37f8:
  mov64 r1, 0x3

jmp_3800:
  exit

jmp_3808:
  ldxdw r3, [r10-0x98]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_3eb8
  mov64 r0, 0x0
  mov64 r1, 0x2
  mov64 r2, r7
  ldxdw r4, [r2+0x28]
  jne r4, 0x0, jmp_3800
  ldxdw r1, [r2+0x30]
  jne r1, 0x0, jmp_3900
  ldxdw r1, [r7+0x38]
  jne r1, 0x0, jmp_3900
  ldxdw r1, [r7+0x40]
  jne r1, 0x0, jmp_3900
  ldxdw r1, [r7+0x50]
  jne r1, 0x0, jmp_3900
  mov64 r1, r9
  add64 r1, 0x80
  mul64 r3, r1
  ldxdw r1, [r10-0x160]
  ldxdw r1, [r1+0x48]
  mov64 r2, r3
  sub64 r2, r1
  mov64 r4, 0x1
  jgt r2, r3, jmp_3910
  mov64 r4, 0x0
  mov64 r5, 0x0
  jeq r4, 0x0, jmp_3920

jmp_38f0:
  ldxdw r2, [r7+0x48]
  jge r2, r5, jmp_3938

jmp_3900:
  mov64 r1, 0x2
  ja jmp_3800

jmp_3910:
  mov64 r5, 0x0
  jne r4, 0x0, jmp_38f0

jmp_3920:
  mov64 r5, r2
  ldxdw r2, [r7+0x48]
  jlt r2, r5, jmp_3900

jmp_3938:
  ldxdw r2, [r10-0x160]
  mov64 r6, r2
  add64 r6, 0x28
  add64 r2, 0x48
  stxdw [r10-0x168], r2
  jeq r1, 0x0, jmp_3c58
  ldxdw r1, [r10-0x160]
  mov64 r2, r7
  call fn_32c0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r1, 0x2
  jne r0, 0x1a, jmp_3800
  ldxdw r1, [r10-0x160]
  mov64 r7, r1
  add64 r7, 0x8
  stxdw [r10-0x28], r7
  sth [r10-0x20], 0x101
  stxdw [r10-0xec], r9
  stw [r10-0xf0], 0x8
  ldxb r1, [r1+0x0]
  jne r1, 0xff, jmp_3d20
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x90], r1
  stxdw [r10-0x98], r7
  ldxdw r9, [r10-0x160]
  ldxdw r1, [r9+0x50]
  stxdw [r10-0x78], r6
  stxdw [r10-0x88], r1
  mov64 r1, r9
  add64 r1, 0x58
  stxdw [r10-0x170], r1
  stxdw [r10-0x80], r1
  stdw [r10-0x70], 0x0
  ldxw r1, [r9+0x1]
  stxw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xc8], r1
  lddw r1, data_0308
  stxdw [r10-0xd0], r1
  stdw [r10-0xb0], 0xc
  stdw [r10-0xc0], 0x1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r4, r10
  add64 r4, -0x100
  mov64 r3, 0x1
  mov64 r5, 0x1
  call sol_invoke_signed_c
  stxdw [r10-0xf0], r7
  sth [r10-0xe8], 0x101
  stw [r10-0x28], 0x1
  ldxdw r1, [r8+0x18]
  stxdw [r10-0xc], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0x14], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0x1c], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0x24], r1
  ldxb r1, [r9+0x0]
  jne r1, 0xff, jmp_3d20
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x90], r1
  stxdw [r10-0x98], r7
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x78], r6
  ldxdw r3, [r10-0x170]
  stxdw [r10-0x80], r3
  stxdw [r10-0x88], r2
  stdw [r10-0x70], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0xc8], r1
  lddw r1, data_0308
  stxdw [r10-0xd0], r1
  stdw [r10-0xb0], 0x24
  stdw [r10-0xc0], 0x1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r4, r10
  add64 r4, -0x100
  mov64 r3, 0x1
  ja jmp_3e98

jmp_3c58:
  ldxdw r4, [r10-0x160]
  mov64 r1, r4
  add64 r1, 0x8
  stxdw [r10-0xe0], r1
  mov64 r5, r7
  mov64 r2, r5
  add64 r2, 0x8
  stxdw [r10-0xf0], r2
  sth [r10-0xd8], 0x101
  sth [r10-0xe8], 0x101
  stxdw [r10-0xc4], r9
  stxdw [r10-0xcc], r3
  stw [r10-0xd0], 0x0
  ldxdw r3, [r8+0x18]
  stxdw [r10-0xa4], r3
  ldxdw r3, [r8+0x10]
  stxdw [r10-0xac], r3
  ldxdw r3, [r8+0x8]
  stxdw [r10-0xb4], r3
  ldxdw r3, [r8+0x0]
  stxdw [r10-0xbc], r3
  ldxb r3, [r5+0x0]
  ldxb r4, [r4+0x0]
  and64 r4, r3
  jeq r4, 0xff, jmp_3d30

jmp_3d20:
  mov64 r0, 0xb
  ja jmp_37f0

jmp_3d30:
  mov64 r3, r7
  add64 r3, 0x28
  mov64 r4, r7
  add64 r4, 0x48
  stxdw [r10-0x78], r3
  stxdw [r10-0x90], r4
  stxdw [r10-0x98], r2
  mov64 r2, r7
  add64 r2, 0x58
  stxdw [r10-0x80], r2
  stdw [r10-0x70], 0x0
  stdw [r10-0x88], 0x0
  ldxw r2, [r7+0x1]
  ldxdw r3, [r10-0x168]
  stxdw [r10-0x58], r3
  stxdw [r10-0x60], r1
  stxw [r10-0x68], r2
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x40], r6
  mov64 r3, r1
  add64 r3, 0x58
  stxdw [r10-0x48], r3
  stxdw [r10-0x50], r2
  stdw [r10-0x38], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0xd0
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0x20], r1
  lddw r1, data_0308
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x34
  stdw [r10-0x18], 0x2
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r4, r10
  add64 r4, -0x100
  mov64 r3, 0x2

jmp_3e98:
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_37f0

jmp_3eb8:
  mov64 r0, 0x1
  mov64 r1, 0x0
  ja jmp_3800

fn_3ed0:
  mov64 r7, r3
  mov64 r8, r2
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0xae0
  call fn_0f50
  ldxw r2, [r10-0xadc]
  ldxw r1, [r10-0xae0]
  ldxb r9, [r10-0x573]
  jne r9, 0x2, jmp_3f38
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  ja jmp_4130

jmp_3f38:
  stxdw [r10-0xaf0], r2
  stxdw [r10-0xae8], r1
  mov64 r1, r10
  add64 r1, -0x568
  mov64 r2, r10
  add64 r2, -0xad8
  mov64 r3, 0x560
  call fn_15658
  ldxh r1, [r10-0x576]
  stxh [r10-0x56c], r1
  ldxb r1, [r10-0x574]
  stxb [r10-0x56a], r1
  ldxh r2, [r10-0x578]
  jge r2, 0x3, jmp_40f8
  ldxh r1, [r10-0x572]
  stxdw [r10-0xb00], r1
  mov64 r1, r10
  add64 r1, -0x2
  stxdw [r10-0xad0], r1
  lddw r1, str_0368
  stxdw [r10-0xae0], r1
  stxdw [r10-0xaf8], r2
  stxh [r10-0x2], r2
  stdw [r10-0xac8], 0x2
  stdw [r10-0xad8], 0x6
  mov64 r2, r10
  add64 r2, -0xae0
  mov64 r1, r8
  mov64 r3, 0x2
  mov64 r4, r7
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_4118
  ldxdw r1, [r10-0xaf0]
  stxw [r6+0x4], r1
  ldxdw r1, [r10-0xae8]
  stxw [r6+0x0], r1
  mov64 r1, r6
  add64 r1, 0x8
  mov64 r2, r10
  add64 r2, -0x568
  mov64 r3, 0x560
  call fn_15658
  ldxdw r1, [r10-0xaf8]
  stxh [r6+0x568], r1
  ldxb r1, [r10-0x56a]
  ldxh r2, [r10-0x56c]
  stxb [r6+0x56d], r9
  ldxdw r3, [r10-0xb00]
  stxh [r6+0x56e], r3
  stxh [r6+0x56a], r2
  stxb [r6+0x56c], r1
  ja jmp_4138

jmp_40f8:
  lddw r1, 0x800000000
  stxdw [r6+0x0], r1
  ja jmp_4130

jmp_4118:
  stxw [r6+0x0], r0
  rsh64 r0, 0x20
  stxw [r6+0x4], r0

jmp_4130:
  stb [r6+0x56d], 0x2

jmp_4138:
  exit

fn_4140:
  mov64 r0, r1
  mov64 r1, 0x2
  jne r3, 0x6, jmp_42a8
  ldxdw r6, [r2+0x0]
  ldxb r1, [r6+0x1]
  jeq r1, 0x0, jmp_42b8
  stxdw [r10-0xa88], r5
  stxdw [r10-0xa80], r4
  mov64 r9, r0
  stxdw [r10-0xa70], r0
  stdw [r10-0xa68], 0x20
  mov64 r8, r2
  ldxdw r7, [r2+0x20]
  mov64 r2, r10
  add64 r2, -0xa70
  mov64 r1, r7
  mov64 r3, 0x1
  lddw r4, data_02c8
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_4560
  ldxdw r1, [r7+0x28]
  lddw r2, -0x4f5e77b16e0957fe
  jne r1, r2, jmp_42b8
  ldxdw r1, [r7+0x30]
  lddw r2, 0x2bae63f73e1510e2
  jne r1, r2, jmp_42b8
  ldxdw r1, [r7+0x38]
  lddw r2, -0x2ddb3ee9c2463e00
  jne r1, r2, jmp_42b8
  ldxdw r1, [r7+0x40]
  lddw r2, 0x8004107a53c0
  jne r1, r2, jmp_42b8
  ldxb r1, [r7+0x0]
  jge r1, 0x2, jmp_42d0
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_4570

jmp_42a8:
  mov64 r0, 0x0
  ja jmp_4570

jmp_42b8:
  mov64 r1, 0x3
  mov64 r0, 0x0
  ja jmp_4570

jmp_42d0:
  add64 r1, -0x1
  stxb [r7+0x0], r1
  ldxdw r2, [r7+0x50]
  jlt r2, 0x2d, jmp_4400
  ldxw r2, [r7+0x58]
  jne r2, 0x3, jmp_4400
  ldxb r2, [r7+0x64]
  jne r2, 0x1, jmp_4400
  ldxdw r2, [r6+0x8]
  ldxdw r3, [r7+0x65]
  jne r3, r2, jmp_4400
  ldxdw r2, [r6+0x10]
  ldxdw r3, [r7+0x6d]
  jne r3, r2, jmp_4400
  ldxdw r2, [r6+0x18]
  ldxdw r3, [r7+0x75]
  jne r3, r2, jmp_4400
  ldxdw r2, [r6+0x20]
  ldxdw r3, [r7+0x7d]
  jne r3, r2, jmp_4400
  and64 r1, 0xff
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_4908
  stxb [r7+0x0], r1
  mov64 r0, 0x0
  ldxdw r1, [r8+0x28]
  ldxdw r2, [r1+0x8]
  jne r2, 0x0, jmp_43f0
  ldxdw r2, [r1+0x10]
  jne r2, 0x0, jmp_43f0
  ldxdw r2, [r1+0x18]
  jne r2, 0x0, jmp_43f0
  ldxdw r2, [r1+0x20]
  jeq r2, 0x0, jmp_4448

jmp_43f0:
  mov64 r1, 0x2
  ja jmp_4570

jmp_4400:
  and64 r1, 0xff
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_4908
  stxb [r7+0x0], r1
  mov64 r0, 0x0
  mov64 r1, 0x3
  ja jmp_4570

jmp_4448:
  ldxb r1, [r1+0x3]
  jeq r1, 0x0, jmp_43f0
  ldxdw r1, [r10-0xa80]
  and64 r1, 0xffff
  jgt r1, 0x2, jmp_4578
  ldxdw r1, [r10-0xa88]
  add64 r1, -0xb
  and64 r1, 0xff
  jlt r1, 0xf6, jmp_4578
  ldxdw r7, [r8+0x18]
  ldxb r2, [r7+0x3]
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_4570
  ldxdw r1, [r8+0x10]
  add64 r7, 0x8
  stxdw [r10-0xa90], r1
  lddw r2, data_0690
  mov64 r3, 0x1
  mov64 r4, r7
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_4560
  mov64 r1, r10
  add64 r1, -0xa70
  ldxdw r2, [r10-0xa90]
  mov64 r3, r7
  call fn_16f0
  ldxb r1, [r10-0x91e]
  jne r1, 0x2, jmp_4588
  ldxw r1, [r10-0xa6c]
  ldxw r0, [r10-0xa70]
  ja jmp_4570

jmp_4560:
  mov64 r1, r0
  rsh64 r1, 0x20

jmp_4570:
  exit

jmp_4578:
  mov64 r1, 0x8
  ja jmp_4570

jmp_4588:
  mov64 r1, r10
  add64 r1, -0xa72
  stxdw [r10-0xa60], r1
  lddw r1, str_0368
  stxdw [r10-0xa70], r1
  ldxdw r1, [r10-0xa80]
  stxh [r10-0xa72], r1
  stdw [r10-0xa58], 0x2
  stdw [r10-0xa68], 0x6
  ldxdw r8, [r8+0x8]
  stxdw [r10-0x1000], r9
  stdw [r10-0xff8], 0x53a
  mov64 r3, r10
  add64 r3, -0xa70
  mov64 r5, r10
  mov64 r1, r8
  mov64 r2, r6
  mov64 r4, r9
  call fn_35c0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_4570
  ldxdw r1, [r6+0x20]
  stxdw [r10-0xa58], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0xa60], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0xa68], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0xa70], r1
  ldxdw r1, [r7+0x0]
  stxdw [r10-0xa50], r1
  ldxdw r1, [r7+0x8]
  stxdw [r10-0xa48], r1
  ldxdw r1, [r7+0x10]
  stxdw [r10-0xa40], r1
  ldxdw r1, [r7+0x18]
  stxdw [r10-0xa38], r1
  mov64 r6, r10
  add64 r6, -0x500
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x480
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x400
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x380
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x300
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  ldxdw r1, [r10-0xa88]
  stxb [r10-0x504], r1
  ldxdw r1, [r10-0xa80]
  stxh [r10-0x508], r1
  stb [r10-0x503], 0x0
  sth [r10-0x506], 0x0
  stdw [r10-0xa30], 0x0
  stdw [r10-0xa28], 0x0
  stdw [r10-0xa20], 0x0
  stdw [r10-0xa18], 0x0
  stdw [r10-0xa10], 0x0
  mov64 r1, r10
  add64 r1, -0xa08
  mov64 r2, r6
  mov64 r3, 0x500
  call fn_15658
  mov64 r2, r10
  add64 r2, -0xa70
  mov64 r1, r8
  call fn_31e8
  ja jmp_4570

jmp_4908:
  lddw r1, data_05d0
  call fn_14350

fn_4920:
  mov64 r8, r2
  mov64 r9, r1
  jne r3, 0x3, jmp_4cd8
  stxdw [r10-0xba8], r4
  ldxb r1, [r5+0x79]
  stxdw [r10-0xbc0], r1
  ldxb r1, [r5+0x78]
  stxdw [r10-0xbb0], r1
  ldxdw r1, [r5+0x58]
  stxdw [r10-0xbe0], r1
  ldxdw r1, [r5+0x50]
  stxdw [r10-0xbd8], r1
  ldxdw r1, [r5+0x48]
  stxdw [r10-0xbd0], r1
  ldxdw r1, [r5+0x40]
  stxdw [r10-0xbc8], r1
  ldxdw r1, [r5+0x38]
  stxdw [r10-0xc00], r1
  ldxdw r1, [r5+0x30]
  stxdw [r10-0xbf8], r1
  ldxdw r1, [r5+0x28]
  stxdw [r10-0xbf0], r1
  stxdw [r10-0xbb8], r5
  ldxdw r1, [r5+0x20]
  stxdw [r10-0xbe8], r1
  ldxdw r7, [r8+0x8]
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, r7
  mov64 r3, r9
  call fn_3ed0
  ldxw r1, [r10-0x62c]
  ldxw r0, [r10-0x630]
  ldxb r6, [r10-0xc3]
  jeq r6, 0x2, jmp_4ce8
  stxdw [r10-0xc10], r9
  stxdw [r10-0xc08], r7
  mov64 r3, r10
  add64 r3, -0xb98
  mov64 r2, r10
  add64 r2, -0x628
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x565
  mov64 r9, r0
  call fn_15658
  stxb [r10-0x633], r6
  stxw [r10-0xb9c], r7
  stxw [r10-0xba0], r9
  ldxh r1, [r10-0xc2]
  stxh [r10-0x632], r1
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r8+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_4ce8
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0xba0]
  jne r3, r4, jmp_4ce8
  ldxdw r3, [r10-0xb98]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_4ce8
  ldxdw r3, [r10-0xb90]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_4ce8
  ldxdw r3, [r10-0xb88]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_4ce8
  mov64 r1, 0x1
  ldxdw r2, [r10-0xba8]
  mov64 r9, r2
  and64 r9, 0xff
  jgt r9, 0x5, jmp_4ce8
  ldxdw r6, [r10-0xbb0]
  mov64 r5, r6
  jgt r5, 0x12, jmp_4ce8
  ldxdw r7, [r10-0xbc0]
  mov64 r1, r7
  and64 r1, 0x1
  ldxdw r3, [r10-0xbb8]
  jeq r1, 0x0, jmp_4d80
  mov64 r1, 0x2
  ldxdw r4, [r3+0x0]
  jne r4, 0x0, jmp_4bf0
  ldxdw r4, [r3+0x8]
  jne r4, 0x0, jmp_4bf0
  ldxdw r4, [r3+0x10]
  jne r4, 0x0, jmp_4bf0
  ldxdw r3, [r3+0x18]
  jeq r3, 0x0, jmp_4ce8

jmp_4bf0:
  ldxdw r3, [r10-0xbc8]
  jne r3, 0x0, jmp_4c30
  ldxdw r3, [r10-0xbd0]
  jne r3, 0x0, jmp_4c30
  ldxdw r3, [r10-0xbd8]
  jne r3, 0x0, jmp_4c30
  ldxdw r3, [r10-0xbe0]
  jeq r3, 0x0, jmp_4ce8

jmp_4c30:
  add64 r2, -0x2
  and64 r2, 0xff
  jgt r2, 0x2, jmp_4c88
  ldxdw r2, [r10-0xbe8]
  jne r2, 0x0, jmp_4c88
  ldxdw r2, [r10-0xbf0]
  jne r2, 0x0, jmp_4c88
  ldxdw r2, [r10-0xbf8]
  jne r2, 0x0, jmp_4c88
  ldxdw r2, [r10-0xc00]
  jeq r2, 0x0, jmp_4ce8

jmp_4c88:
  stxdw [r10-0xba8], r5
  ldxh r2, [r10-0x638]
  mov64 r1, r10
  add64 r1, -0x630
  call fn_dc00
  ldxb r1, [r10-0x630]
  jne r1, 0x1, jmp_4cf0
  ldxw r1, [r10-0x62c]
  mov64 r0, 0x0
  ja jmp_4ce8

jmp_4cd8:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_4ce8:
  exit

jmp_4cf0:
  mov64 r1, 0x8
  ldxdw r2, [r10-0x62f]
  mov64 r0, 0x0
  ldxdw r3, [r10-0xbc8]
  jne r2, r3, jmp_4ce8
  ldxdw r2, [r10-0x627]
  ldxdw r3, [r10-0xbb8]
  ldxdw r4, [r10-0xbd0]
  ldxdw r5, [r10-0xba8]
  jne r2, r4, jmp_4ce8
  ldxdw r2, [r10-0x61f]
  ldxdw r4, [r10-0xbd8]
  jne r2, r4, jmp_4ce8
  ldxdw r2, [r10-0x617]
  ldxdw r4, [r10-0xbe0]
  jne r2, r4, jmp_4ce8
  ldxb r2, [r10-0x60f]
  jne r2, r5, jmp_4ce8

jmp_4d80:
  lsh64 r9, 0x7
  mov64 r1, r10
  add64 r1, -0xba0
  add64 r1, r9
  ldxdw r2, [r3+0x18]
  stxdw [r1+0x80], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0x78], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0x70], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x68], r2
  ldxdw r2, [r10-0xbe0]
  stxdw [r1+0xc0], r2
  ldxdw r2, [r10-0xbd8]
  stxdw [r1+0xb8], r2
  ldxdw r2, [r10-0xbd0]
  stxdw [r1+0xb0], r2
  ldxdw r2, [r10-0xbc8]
  stxdw [r1+0xa8], r2
  ldxdw r2, [r10-0xc00]
  stxdw [r1+0xa0], r2
  ldxdw r2, [r10-0xbf8]
  stxdw [r1+0x98], r2
  ldxdw r2, [r10-0xbf0]
  stxdw [r1+0x90], r2
  ldxdw r2, [r10-0xbe8]
  stxdw [r1+0x88], r2
  stxb [r1+0xe1], r7
  stxb [r1+0xe0], r6
  stdw [r1+0xc8], 0x0
  stdw [r1+0xd0], 0x0
  stdw [r1+0xd8], 0x0
  ldxdw r1, [r10-0xb60]
  jeq r1, -0x1, jmp_5238
  add64 r1, 0x1
  stxdw [r10-0xb60], r1
  mov64 r1, 0x2
  ldxdw r7, [r10-0xc08]
  ldxb r2, [r7+0x2]
  jeq r2, 0x0, jmp_4ce8
  ldxdw r2, [r7+0x50]
  jne r2, 0x53a, jmp_4ce8
  ldxb r1, [r7+0x0]
  jeq r1, 0xff, jmp_4f00

jmp_4ee8:
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_4ce8

jmp_4f00:
  ldxdw r8, [r8+0x10]
  ldxh r4, [r10-0x638]
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, r8
  ldxdw r3, [r10-0xc10]
  call fn_5b38
  ldxb r6, [r10-0x574]
  jne r6, 0x3, jmp_4f60
  ldxw r0, [r10-0x630]
  ldxw r1, [r10-0x62c]
  ja jmp_4ce8

jmp_4f60:
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r10
  add64 r2, -0x628
  mov64 r3, 0xb4
  call fn_15658
  ldxh r1, [r10-0x573]
  stxh [r10-0xbc], r1
  ldxb r1, [r10-0x571]
  stxb [r10-0xba], r1
  jne r6, 0x2, jmp_4fe0

jmp_4fb8:
  mov64 r2, r10
  add64 r2, -0xba0
  mov64 r1, r7
  call fn_31e8
  ja jmp_4ce8

jmp_4fe0:
  mov64 r1, r10
  add64 r1, -0x628
  mov64 r2, r10
  add64 r2, -0xb8
  mov64 r3, 0xb4
  call fn_15658
  ldxh r1, [r10-0xbc]
  stxh [r10-0x573], r1
  ldxb r1, [r10-0xba]
  stxb [r10-0x571], r1
  stb [r10-0x574], 0x0
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, 0x0
  mov64 r3, 0x5a
  call fn_15678
  ldxb r1, [r10-0x63f]
  mov64 r0, 0x100
  jne r1, 0x0, jmp_5080
  mov64 r0, 0x0

jmp_5080:
  stdw [r10-0x5c8], 0x0
  stdw [r10-0x5c0], 0x0
  stdw [r10-0x5b8], 0x0
  stdw [r10-0x5b0], 0x0
  stdw [r10-0x5a8], 0x0
  stdw [r10-0x5a0], 0x0
  stdw [r10-0x598], 0x0
  stw [r10-0x590], 0x0
  ldxb r1, [r10-0xabf]
  stxdw [r10-0xba8], r1
  ldxb r3, [r10-0xa3f]
  ldxb r4, [r10-0x9bf]
  ldxb r5, [r10-0x93f]
  ldxb r6, [r10-0x8bf]
  ldxb r7, [r10-0x83f]
  ldxb r9, [r10-0x7bf]
  ldxb r2, [r10-0x73f]
  ldxb r1, [r10-0x6bf]
  stxh [r10-0x57a], r0
  mov64 r0, 0x100
  jne r1, 0x0, jmp_5248
  mov64 r0, 0x0
  stxh [r10-0x57c], r0
  mov64 r1, 0x100
  mov64 r0, 0x0
  jeq r2, 0x0, jmp_5268

jmp_5150:
  stxh [r10-0x57e], r1
  mov64 r1, 0x100
  jne r9, 0x0, jmp_5288

jmp_5168:
  mov64 r1, 0x0
  stxh [r10-0x580], r1
  mov64 r1, 0x100
  jeq r7, 0x0, jmp_52a0

jmp_5188:
  stxh [r10-0x582], r1
  mov64 r1, 0x100
  jne r6, 0x0, jmp_52c0

jmp_51a0:
  mov64 r1, 0x0
  stxh [r10-0x584], r1
  mov64 r1, 0x100
  jeq r5, 0x0, jmp_52d8

jmp_51c0:
  stxh [r10-0x586], r1
  mov64 r1, 0x100
  jne r4, 0x0, jmp_52f8

jmp_51d8:
  mov64 r1, 0x0
  stxh [r10-0x588], r1
  mov64 r1, 0x100
  jeq r3, 0x0, jmp_5310

jmp_51f8:
  stxh [r10-0x58a], r1
  mov64 r1, 0x100
  ldxdw r2, [r10-0xba8]
  jne r2, 0x0, jmp_5338

jmp_5218:
  mov64 r1, 0x0
  stxh [r10-0x58c], r1
  ldxdw r1, [r10-0x5d0]
  jne r1, -0x1, jmp_5350

jmp_5238:
  mov64 r1, 0x4
  ja jmp_4ce8

jmp_5248:
  stxh [r10-0x57c], r0
  mov64 r1, 0x100
  mov64 r0, 0x0
  jne r2, 0x0, jmp_5150

jmp_5268:
  mov64 r1, 0x0
  stxh [r10-0x57e], r1
  mov64 r1, 0x100
  jeq r9, 0x0, jmp_5168

jmp_5288:
  stxh [r10-0x580], r1
  mov64 r1, 0x100
  jne r7, 0x0, jmp_5188

jmp_52a0:
  mov64 r1, 0x0
  stxh [r10-0x582], r1
  mov64 r1, 0x100
  jeq r6, 0x0, jmp_51a0

jmp_52c0:
  stxh [r10-0x584], r1
  mov64 r1, 0x100
  jne r5, 0x0, jmp_51c0

jmp_52d8:
  mov64 r1, 0x0
  stxh [r10-0x586], r1
  mov64 r1, 0x100
  jeq r4, 0x0, jmp_51d8

jmp_52f8:
  stxh [r10-0x588], r1
  mov64 r1, 0x100
  jne r3, 0x0, jmp_51f8

jmp_5310:
  mov64 r1, 0x0
  stxh [r10-0x58a], r1
  mov64 r1, 0x100
  ldxdw r2, [r10-0xba8]
  jeq r2, 0x0, jmp_5218

jmp_5338:
  stxh [r10-0x58c], r1
  ldxdw r1, [r10-0x5d0]
  jeq r1, -0x1, jmp_5238

jmp_5350:
  add64 r1, 0x1
  stxdw [r10-0x5d0], r1
  mov64 r1, 0x2
  ldxb r2, [r8+0x2]
  jeq r2, 0x0, jmp_4ce8
  ldxdw r2, [r8+0x50]
  jne r2, 0xbf, jmp_4ce8
  ldxb r1, [r8+0x0]
  jne r1, 0xff, jmp_4ee8
  mov64 r2, r10
  add64 r2, -0x630
  mov64 r1, r8
  call fn_3118
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_53f0
  ldxdw r7, [r10-0xc08]
  ja jmp_4fb8

jmp_53f0:
  mov64 r0, r2
  ja jmp_4ce8

fn_5400:
  mov64 r7, r2
  mov64 r8, r1
  jne r3, 0x3, jmp_5600
  stxdw [r10-0xba8], r4
  stxdw [r10-0xbb0], r5
  ldxdw r6, [r7+0x8]
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, r6
  mov64 r3, r8
  call fn_3ed0
  ldxw r1, [r10-0x62c]
  ldxw r0, [r10-0x630]
  ldxb r2, [r10-0xc3]
  jeq r2, 0x2, jmp_5610
  stxdw [r10-0xbc0], r2
  stxdw [r10-0xbb8], r6
  mov64 r3, r10
  add64 r3, -0xb98
  mov64 r2, r10
  add64 r2, -0x628
  mov64 r6, r1
  mov64 r1, r3
  mov64 r3, 0x565
  mov64 r9, r0
  call fn_15658
  stxw [r10-0xb9c], r6
  stxw [r10-0xba0], r9
  ldxh r1, [r10-0xc2]
  stxh [r10-0x632], r1
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r7+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_5610
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0xba0]
  jne r3, r4, jmp_5610
  ldxdw r3, [r10-0xb98]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_5610
  ldxdw r3, [r10-0xb90]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_5610
  ldxdw r3, [r10-0xb88]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_5610
  mov64 r1, 0x1
  ldxdw r2, [r10-0xba8]
  add64 r2, -0xb
  and64 r2, 0xff
  jlt r2, 0xf6, jmp_5610
  ldxdw r7, [r7+0x10]
  ldxh r4, [r10-0x638]
  mov64 r1, r10
  add64 r1, -0x630
  mov64 r2, r7
  mov64 r3, r8
  call fn_5b38
  ldxb r8, [r10-0x574]
  jne r8, 0x3, jmp_5618
  ldxw r0, [r10-0x630]
  ldxw r1, [r10-0x62c]
  ja jmp_5610

jmp_5600:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_5610:
  exit

jmp_5618:
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r10
  add64 r2, -0x628
  mov64 r3, 0xb4
  call fn_15658
  ldxh r1, [r10-0x573]
  stxh [r10-0x3], r1
  ldxb r1, [r10-0x571]
  stxb [r10-0x1], r1
  ldxdw r1, [r10-0xba8]
  stxb [r10-0x634], r1
  mov64 r0, 0x0
  ldxdw r1, [r10-0xb60]
  jeq r1, -0x1, jmp_5b18
  add64 r1, 0x1
  stxdw [r10-0xb60], r1
  mov64 r1, 0x2
  ldxdw r5, [r10-0xbb8]
  ldxb r2, [r5+0x2]
  jeq r2, 0x0, jmp_5610
  ldxdw r2, [r5+0x50]
  jne r2, 0x53a, jmp_5610
  mov64 r0, 0xb
  ldxb r1, [r5+0x0]
  jeq r1, 0xff, jmp_56f8
  mov64 r1, 0x0
  ja jmp_5610

jmp_56f8:
  ldxdw r2, [r10-0xbb0]
  jeq r8, 0x2, jmp_59f8
  mov64 r1, r2
  ldxdw r3, [r10-0xbc0]
  xor64 r1, r3
  and64 r1, 0x1
  jeq r1, 0x0, jmp_59f8
  stb [r10-0x4], 0x0
  mov64 r1, r10
  add64 r1, -0xc0
  mov64 r2, 0x0
  mov64 r3, 0x5a
  call fn_15678
  ldxb r2, [r10-0x63f]
  mov64 r1, 0x100
  jne r2, 0x0, jmp_5780
  mov64 r1, 0x0

jmp_5780:
  stdw [r10-0x58], 0x0
  stdw [r10-0x50], 0x0
  stdw [r10-0x48], 0x0
  stdw [r10-0x40], 0x0
  stdw [r10-0x38], 0x0
  stdw [r10-0x30], 0x0
  stdw [r10-0x28], 0x0
  stw [r10-0x20], 0x0
  ldxb r2, [r10-0xabf]
  stxdw [r10-0xba8], r2
  ldxb r2, [r10-0xa3f]
  stxdw [r10-0xbc0], r2
  ldxb r5, [r10-0x9bf]
  ldxb r6, [r10-0x93f]
  ldxb r8, [r10-0x8bf]
  ldxb r9, [r10-0x83f]
  ldxb r3, [r10-0x7bf]
  ldxb r2, [r10-0x73f]
  ldxb r4, [r10-0x6bf]
  stxh [r10-0xa], r1
  mov64 r1, 0x100
  jne r4, 0x0, jmp_5838
  mov64 r1, 0x0

jmp_5838:
  stxh [r10-0xc], r1
  mov64 r4, 0x100
  mov64 r1, 0x2
  mov64 r0, 0x0
  jne r2, 0x0, jmp_5a28
  mov64 r4, 0x0
  stxh [r10-0xe], r4
  mov64 r2, 0x100
  jeq r3, 0x0, jmp_5a40

jmp_5880:
  stxh [r10-0x10], r2
  mov64 r2, 0x100
  jne r9, 0x0, jmp_5a60

jmp_5898:
  mov64 r2, 0x0
  stxh [r10-0x12], r2
  mov64 r2, 0x100
  jeq r8, 0x0, jmp_5a78

jmp_58b8:
  stxh [r10-0x14], r2
  mov64 r2, 0x100
  jne r6, 0x0, jmp_5a98

jmp_58d0:
  mov64 r2, 0x0
  stxh [r10-0x16], r2
  mov64 r2, 0x100
  jeq r5, 0x0, jmp_5ab0

jmp_58f0:
  stxh [r10-0x18], r2
  mov64 r2, 0x100
  ldxdw r3, [r10-0xbc0]
  jne r3, 0x0, jmp_5ad8

jmp_5910:
  mov64 r2, 0x0
  stxh [r10-0x1a], r2
  mov64 r2, 0x100
  ldxdw r3, [r10-0xba8]
  jeq r3, 0x0, jmp_5af8

jmp_5938:
  stxh [r10-0x1c], r2
  ldxdw r2, [r10-0x60]
  jeq r2, -0x1, jmp_5b18

jmp_5950:
  add64 r2, 0x1
  stxdw [r10-0x60], r2
  ldxb r2, [r7+0x2]
  jeq r2, 0x0, jmp_5610
  ldxdw r2, [r7+0x50]
  jne r2, 0xbf, jmp_5610
  mov64 r1, 0x0
  ldxb r2, [r7+0x0]
  mov64 r0, 0xb
  jne r2, 0xff, jmp_5610
  mov64 r2, r10
  add64 r2, -0xc0
  mov64 r1, r7
  call fn_3118
  mov64 r3, r0
  mov64 r4, r0
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  ldxdw r2, [r10-0xbb0]
  ldxdw r5, [r10-0xbb8]
  jne r4, 0x1a, jmp_5b28

jmp_59f8:
  stxb [r10-0x633], r2
  mov64 r2, r10
  add64 r2, -0xba0
  mov64 r1, r5
  call fn_31e8
  ja jmp_5610

jmp_5a28:
  stxh [r10-0xe], r4
  mov64 r2, 0x100
  jne r3, 0x0, jmp_5880

jmp_5a40:
  mov64 r2, 0x0
  stxh [r10-0x10], r2
  mov64 r2, 0x100
  jeq r9, 0x0, jmp_5898

jmp_5a60:
  stxh [r10-0x12], r2
  mov64 r2, 0x100
  jne r8, 0x0, jmp_58b8

jmp_5a78:
  mov64 r2, 0x0
  stxh [r10-0x14], r2
  mov64 r2, 0x100
  jeq r6, 0x0, jmp_58d0

jmp_5a98:
  stxh [r10-0x16], r2
  mov64 r2, 0x100
  jne r5, 0x0, jmp_58f0

jmp_5ab0:
  mov64 r2, 0x0
  stxh [r10-0x18], r2
  mov64 r2, 0x100
  ldxdw r3, [r10-0xbc0]
  jeq r3, 0x0, jmp_5910

jmp_5ad8:
  stxh [r10-0x1a], r2
  mov64 r2, 0x100
  ldxdw r3, [r10-0xba8]
  jne r3, 0x0, jmp_5938

jmp_5af8:
  mov64 r2, 0x0
  stxh [r10-0x1c], r2
  ldxdw r2, [r10-0x60]
  jne r2, -0x1, jmp_5950

jmp_5b18:
  mov64 r1, 0x4
  ja jmp_5610

jmp_5b28:
  mov64 r0, r3
  ja jmp_5610

fn_5b38:
  mov64 r7, r4
  mov64 r8, r3
  mov64 r9, r2
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x17a
  stxdw [r10-0x168], r1
  lddw r1, str_0374
  stxdw [r10-0x178], r1
  stxh [r10-0x17a], r7
  stdw [r10-0x160], 0x2
  stdw [r10-0x170], 0x7
  mov64 r2, r10
  add64 r2, -0x178
  mov64 r1, r9
  mov64 r3, 0x2
  mov64 r4, r8
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_5c70
  ldxdw r1, [r9+0x28]
  jne r1, 0x0, jmp_5c40
  ldxdw r1, [r9+0x30]
  jne r1, 0x0, jmp_5c40
  ldxdw r1, [r9+0x38]
  jne r1, 0x0, jmp_5c40
  ldxdw r1, [r9+0x40]
  jne r1, 0x0, jmp_5c40
  ldxdw r1, [r9+0x50]
  jeq r1, 0x0, jmp_5e28

jmp_5c40:
  ldxdw r1, [r9+0x50]
  jne r1, 0x27, jmp_5c98
  lddw r1, 0x1300000000

jmp_5c60:
  stxdw [r6+0x0], r1
  ja jmp_5c88

jmp_5c70:
  stxw [r6+0x0], r0
  rsh64 r0, 0x20
  stxw [r6+0x4], r0

jmp_5c88:
  stb [r6+0xbc], 0x3

jmp_5c90:
  exit

jmp_5c98:
  mov64 r1, r10
  add64 r1, -0x178
  mov64 r2, r9
  mov64 r3, r8
  call fn_1508
  ldxw r1, [r10-0x174]
  ldxw r8, [r10-0x178]
  ldxb r9, [r10-0xbc]
  jne r9, 0x2, jmp_5cf8
  stxw [r6+0x4], r1
  stxw [r6+0x0], r8
  ja jmp_5c88

jmp_5cf8:
  stxdw [r10-0x188], r1
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xb0
  call fn_15658
  ldxh r1, [r10-0xbb]
  stxh [r10-0xb4], r1
  ldxb r1, [r10-0xb9]
  stxb [r10-0xb2], r1
  ldxh r1, [r10-0xc0]
  mov64 r2, r7
  and64 r2, 0xffff
  jne r1, r2, jmp_5e10
  ldxh r1, [r10-0xbe]
  stxdw [r10-0x190], r1
  mov64 r1, r6
  add64 r1, 0x8
  mov64 r2, r10
  add64 r2, -0xb0
  mov64 r3, 0xb0
  call fn_15658
  ldxb r1, [r10-0xb2]
  ldxh r2, [r10-0xb4]
  stxw [r6+0x0], r8
  ldxdw r3, [r10-0x188]
  stxw [r6+0x4], r3
  stxh [r6+0xb8], r7
  ldxdw r3, [r10-0x190]
  stxh [r6+0xba], r3
  stxb [r6+0xbc], r9
  stxh [r6+0xbd], r2
  stxb [r6+0xbf], r1
  ja jmp_5c90

jmp_5e10:
  lddw r1, 0x800000000
  ja jmp_5c60

jmp_5e28:
  stb [r6+0xbc], 0x2
  ja jmp_5c90

fn_5e38:
  mov64 r6, r2
  mov64 r0, r1
  jne r3, 0x4, jmp_63b8
  stxdw [r10-0xb08], r4
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0xaf8], r1
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0xb00], r1
  ldxdw r9, [r6+0x8]
  mov64 r1, r10
  add64 r1, -0x578
  mov64 r2, r9
  stxdw [r10-0xaf0], r0
  mov64 r3, r0
  call fn_3ed0
  ldxw r1, [r10-0x574]
  ldxw r7, [r10-0x578]
  ldxb r8, [r10-0xb]
  jeq r8, 0x2, jmp_63c8
  stxdw [r10-0xb10], r9
  mov64 r3, r10
  add64 r3, -0xae0
  mov64 r2, r10
  add64 r2, -0x570
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x565
  call fn_15658
  stxb [r10-0x57b], r8
  stxw [r10-0xae4], r9
  stxw [r10-0xae8], r7
  ldxh r1, [r10-0xa]
  stxh [r10-0x57a], r1
  mov64 r1, 0x3
  ldxdw r8, [r6+0x0]
  ldxb r2, [r8+0x1]
  jeq r2, 0x0, jmp_6398
  ldxdw r2, [r8+0x8]
  ldxdw r3, [r10-0xae8]
  jne r2, r3, jmp_6398
  ldxdw r2, [r10-0xae0]
  ldxdw r3, [r8+0x10]
  jne r3, r2, jmp_6398
  ldxdw r2, [r10-0xad8]
  ldxdw r3, [r8+0x18]
  jne r3, r2, jmp_6398
  ldxdw r2, [r10-0xad0]
  ldxdw r3, [r8+0x20]
  jne r3, r2, jmp_6398
  mov64 r1, r10
  add64 r1, -0x2
  stxdw [r10-0x568], r1
  lddw r1, str_0374
  stxdw [r10-0x578], r1
  ldxh r1, [r10-0x580]
  stxdw [r10-0xb18], r1
  stxh [r10-0x2], r1
  stdw [r10-0x560], 0x2
  stdw [r10-0x570], 0x7
  ldxdw r9, [r6+0x10]
  mov64 r2, r10
  add64 r2, -0x578
  mov64 r1, r9
  mov64 r3, 0x2
  ldxdw r4, [r10-0xaf0]
  call fn_05b0
  mov64 r7, r0
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_6228
  mov64 r1, 0x1
  ldxdw r2, [r10-0xaf8]
  add64 r2, -0x4
  and64 r2, 0xff
  jgt r2, 0xe, jmp_6398
  ldxdw r2, [r10-0xb00]
  ldxdw r3, [r10-0xaf0]
  jeq r2, 0x0, jmp_6180
  ldxb r2, [r10-0x57c]
  add64 r2, -0xb
  and64 r2, 0xff
  jlt r2, 0xf6, jmp_6398
  ldxb r4, [r10-0x987]
  ldxb r2, [r10-0xa07]
  add64 r2, r4
  ldxb r4, [r10-0x907]
  add64 r2, r4
  ldxb r4, [r10-0x887]
  add64 r2, r4
  ldxb r4, [r10-0x807]
  add64 r2, r4
  ldxb r4, [r10-0x787]
  add64 r2, r4
  ldxb r4, [r10-0x707]
  add64 r2, r4
  and64 r2, 0xff
  ldxb r4, [r10-0x687]
  add64 r2, r4
  ldxb r4, [r10-0x607]
  add64 r2, r4
  ldxb r4, [r10-0x587]
  add64 r2, r4
  jlt r2, 0x2, jmp_6398

jmp_6180:
  ldxdw r1, [r9+0x28]
  jne r1, 0x0, jmp_61d0
  ldxdw r1, [r9+0x30]
  jne r1, 0x0, jmp_61d0
  ldxdw r1, [r9+0x38]
  jne r1, 0x0, jmp_61d0
  ldxdw r1, [r9+0x40]
  jne r1, 0x0, jmp_61d0
  ldxdw r1, [r9+0x50]
  jeq r1, 0x0, jmp_6330

jmp_61d0:
  ldxdw r1, [r9+0x50]
  jne r1, 0x27, jmp_6240
  mov64 r1, r10
  add64 r1, -0x578
  mov64 r2, r9
  call fn_12f8
  ldxb r1, [r10-0x55a]
  jne r1, 0x2, jmp_6288
  ldxw r1, [r10-0x574]
  ldxw r7, [r10-0x578]
  ja jmp_63c8

jmp_6228:
  mov64 r1, r7
  rsh64 r1, 0x20
  ja jmp_63c8

jmp_6240:
  mov64 r1, r10
  add64 r1, -0x578
  mov64 r2, r9
  call fn_1508
  ldxb r1, [r10-0x4bc]
  jne r1, 0x2, jmp_62b8
  ldxw r7, [r10-0x578]
  ldxw r1, [r10-0x574]
  ja jmp_63c8

jmp_6288:
  mov64 r1, 0x8
  ldxh r2, [r10-0x55c]
  ldxdw r3, [r10-0xb18]
  jne r2, r3, jmp_6398
  ldxdw r2, [r10-0x578]
  ja jmp_62e0

jmp_62b8:
  mov64 r1, 0x8
  ldxh r2, [r10-0x4c0]
  ldxdw r3, [r10-0xb18]
  jne r2, r3, jmp_6398
  ldxdw r2, [r10-0x518]

jmp_62e0:
  add64 r2, 0x1
  mov64 r7, 0x0
  mov64 r1, 0x1
  ldxdw r3, [r10-0xb08]
  jeq r2, 0x0, jmp_6310
  mov64 r1, 0x0

jmp_6310:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_6348
  mov64 r1, 0x4
  ja jmp_63c8

jmp_6330:
  mov64 r2, 0x1
  mov64 r7, 0x1
  ldxdw r3, [r10-0xb08]

jmp_6348:
  mov64 r1, 0x6
  jne r3, r2, jmp_6398
  mov64 r1, 0x2
  ldxdw r2, [r6+0x18]
  ldxdw r3, [r2+0x8]
  jne r3, 0x0, jmp_6398
  ldxdw r3, [r2+0x10]
  jne r3, 0x0, jmp_6398
  ldxdw r3, [r2+0x18]
  jeq r3, 0x0, jmp_63a8

jmp_6398:
  mov64 r7, 0x0
  ja jmp_63c8

jmp_63a8:
  ldxdw r1, [r2+0x20]
  jeq r1, 0x0, jmp_63d8

jmp_63b8:
  mov64 r7, 0x0

jmp_63c0:
  mov64 r1, 0x2

jmp_63c8:
  mov64 r0, r7
  exit

jmp_63d8:
  ldxb r1, [r2+0x3]
  jeq r1, 0x0, jmp_63b8
  ldxdw r1, [r10-0xaa8]
  jeq r1, -0x1, jmp_6468
  add64 r1, 0x1
  stxdw [r10-0xaa8], r1
  ldxdw r1, [r10-0xb10]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_63b8
  ldxdw r1, [r10-0xb10]
  ldxdw r1, [r1+0x50]
  jne r1, 0x53a, jmp_63b8
  ldxdw r1, [r10-0xb10]
  ldxb r1, [r1+0x0]
  jeq r1, 0xff, jmp_6480
  mov64 r1, 0x0
  mov64 r7, 0xb
  ja jmp_63c8

jmp_6468:
  mov64 r1, 0x4
  mov64 r7, 0x0
  ja jmp_63c8

jmp_6480:
  ldxb r1, [r9+0x2]
  jeq r1, 0x0, jmp_63b8
  ldxb r1, [r9+0x3]
  jne r1, 0x0, jmp_63b8
  jeq r7, 0x0, jmp_6570
  mov64 r1, r10
  add64 r1, -0x2
  stxdw [r10-0x568], r1
  lddw r1, str_0374
  stxdw [r10-0x578], r1
  ldxdw r1, [r10-0xb18]
  stxh [r10-0x2], r1
  stdw [r10-0x560], 0x2
  stdw [r10-0x570], 0x7
  ldxdw r4, [r10-0xaf0]
  stxdw [r10-0x1000], r4
  stdw [r10-0xff8], 0xbf
  mov64 r3, r10
  add64 r3, -0x578
  mov64 r5, r10
  mov64 r1, r9
  mov64 r2, r8
  call fn_35c0
  mov64 r7, r0
  mov64 r2, r7
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_63c8
  ja jmp_6580

jmp_6570:
  ldxdw r1, [r9+0x50]
  jne r1, 0xbf, jmp_6938

jmp_6580:
  ldxdw r1, [r10-0xb00]
  stxb [r10-0x4bd], r1
  ldxdw r1, [r10-0xb08]
  stxdw [r10-0x518], r1
  ldxdw r1, [r10-0xb18]
  stxh [r10-0x4c0], r1
  ldxdw r1, [r10-0xaf8]
  stxb [r10-0x4be], r1
  stb [r10-0x4bc], 0x0
  stdw [r10-0x510], 0x0
  stdw [r10-0x508], 0x0
  stdw [r10-0x500], 0x0
  stdw [r10-0x4f8], 0x0
  stdw [r10-0x4f0], 0x0
  stdw [r10-0x4e8], 0x0
  stdw [r10-0x4e0], 0x0
  stw [r10-0x4d8], 0x0
  mov64 r1, r10
  add64 r1, -0x578
  stxdw [r10-0xb00], r1
  mov64 r2, 0x0
  mov64 r3, 0x5a
  call fn_15678
  mov64 r1, 0x100
  stxdw [r10-0xaf8], r1
  ldxb r3, [r10-0x687]
  stxdw [r10-0xaf0], r1
  jne r3, 0x0, jmp_6768
  mov64 r1, 0x0
  stxdw [r10-0xaf0], r1
  ldxb r3, [r10-0x607]
  mov64 r4, 0x100
  jeq r3, 0x0, jmp_6780

jmp_6688:
  ldxb r5, [r10-0xa07]
  mov64 r3, 0x100
  jne r5, 0x0, jmp_67a0

jmp_66a0:
  mov64 r3, 0x0
  ldxb r0, [r10-0x987]
  mov64 r5, 0x100
  jeq r0, 0x0, jmp_67b8

jmp_66c0:
  ldxb r6, [r10-0x907]
  mov64 r0, 0x100
  jne r6, 0x0, jmp_67d8

jmp_66d8:
  mov64 r0, 0x0
  ldxb r6, [r10-0x887]
  mov64 r7, 0x100
  jeq r6, 0x0, jmp_67f0

jmp_66f8:
  ldxb r6, [r10-0x807]
  mov64 r8, 0x100
  jne r6, 0x0, jmp_6810

jmp_6710:
  mov64 r8, 0x0
  ldxb r6, [r10-0x787]
  mov64 r2, 0x100
  jeq r6, 0x0, jmp_6828

jmp_6730:
  ldxb r1, [r10-0x707]
  mov64 r6, 0x100
  jne r1, 0x0, jmp_6848

jmp_6748:
  mov64 r6, 0x0
  ldxb r1, [r10-0x587]
  jeq r1, 0x0, jmp_6858
  ja jmp_6868

jmp_6768:
  ldxb r3, [r10-0x607]
  mov64 r4, 0x100
  jne r3, 0x0, jmp_6688

jmp_6780:
  mov64 r4, 0x0
  ldxb r5, [r10-0xa07]
  mov64 r3, 0x100
  jeq r5, 0x0, jmp_66a0

jmp_67a0:
  ldxb r0, [r10-0x987]
  mov64 r5, 0x100
  jne r0, 0x0, jmp_66c0

jmp_67b8:
  mov64 r5, 0x0
  ldxb r6, [r10-0x907]
  mov64 r0, 0x100
  jeq r6, 0x0, jmp_66d8

jmp_67d8:
  ldxb r6, [r10-0x887]
  mov64 r7, 0x100
  jne r6, 0x0, jmp_66f8

jmp_67f0:
  mov64 r7, 0x0
  ldxb r6, [r10-0x807]
  mov64 r8, 0x100
  jeq r6, 0x0, jmp_6710

jmp_6810:
  ldxb r6, [r10-0x787]
  mov64 r2, 0x100
  jne r6, 0x0, jmp_6730

jmp_6828:
  mov64 r2, 0x0
  ldxb r1, [r10-0x707]
  mov64 r6, 0x100
  jeq r1, 0x0, jmp_6748

jmp_6848:
  ldxb r1, [r10-0x587]
  jne r1, 0x0, jmp_6868

jmp_6858:
  mov64 r1, 0x0
  stxdw [r10-0xaf8], r1

jmp_6868:
  ldxdw r1, [r10-0xaf8]
  stxh [r10-0x4c2], r1
  stxh [r10-0x4c4], r4
  ldxdw r1, [r10-0xaf0]
  stxh [r10-0x4c6], r1
  stxh [r10-0x4c8], r6
  stxh [r10-0x4ca], r2
  stxh [r10-0x4cc], r8
  stxh [r10-0x4ce], r7
  stxh [r10-0x4d0], r0
  stxh [r10-0x4d2], r5
  stxh [r10-0x4d4], r3
  mov64 r1, r9
  ldxdw r2, [r10-0xb00]
  call fn_3118
  mov64 r7, r0
  mov64 r2, r7
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_63c8
  mov64 r2, r10
  add64 r2, -0xae8
  ldxdw r1, [r10-0xb10]
  call fn_31e8
  mov64 r7, r0
  ja jmp_63c8

jmp_6938:
  mov64 r2, r10
  add64 r2, -0x578
  lddw r1, data_02e8
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  jeq r0, 0x0, jmp_6998
  mov64 r7, 0x10
  jne r0, 0x1, jmp_6990
  mov64 r7, 0x1

jmp_6990:
  ja jmp_63c8

jmp_6998:
  ldxdw r3, [r10-0x578]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_6ab0
  mov64 r7, 0x0
  ldxb r1, [r8+0x2]
  jeq r1, 0x0, jmp_63c0
  ldxb r1, [r9+0x2]
  jeq r1, 0x0, jmp_63c0
  mul64 r3, 0x13f
  ldxdw r1, [r9+0x48]
  jge r1, r3, jmp_6a38
  mov64 r1, r9
  mov64 r2, r8
  call fn_32c0
  mov64 r1, 0x2
  mov64 r7, r0
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jne r7, 0x1a, jmp_63c8

jmp_6a38:
  ldxb r2, [r9+0x0]
  mov64 r7, 0xb
  jne r2, 0xff, jmp_63c8
  ldxdw r2, [r9+0x50]
  jeq r2, 0xbf, jmp_6580
  jge r2, 0xbf, jmp_6aa0
  mov64 r3, 0xbf
  sub64 r3, r2
  mov64 r1, r9
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_15678

jmp_6aa0:
  stdw [r9+0x50], 0xbf
  ja jmp_6580

jmp_6ab0:
  mov64 r7, 0x1
  mov64 r1, 0x0
  ja jmp_63c8

fn_6ac8:
  mov64 r7, r2
  mov64 r5, r1
  jlt r3, 0x2, jmp_6be0
  stxdw [r10-0xb10], r3
  stxdw [r10-0xb08], r4
  ldxdw r6, [r7+0x0]
  mov64 r1, r10
  add64 r1, -0x590
  mov64 r2, r6
  mov64 r3, r5
  call fn_3ed0
  ldxw r1, [r10-0x58c]
  ldxw r0, [r10-0x590]
  ldxb r8, [r10-0x23]
  jeq r8, 0x2, jmp_6bf0
  stxdw [r10-0xb18], r6
  mov64 r3, r10
  add64 r3, -0xaf8
  mov64 r2, r10
  add64 r2, -0x588
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x565
  mov64 r6, r0
  call fn_15658
  stxw [r10-0xafc], r9
  stxw [r10-0xb00], r6
  ldxh r1, [r10-0x22]
  stxh [r10-0x592], r1
  stxb [r10-0x593], r8
  and64 r8, 0x1
  jeq r8, 0x0, jmp_6bf8
  mov64 r0, 0x0
  mov64 r1, 0x7
  ja jmp_6bf0

jmp_6be0:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_6bf0:
  exit

jmp_6bf8:
  ldxdw r1, [r10-0xac8]
  stxdw [r10-0x8], r1
  ldxdw r1, [r10-0xad0]
  stxdw [r10-0x10], r1
  ldxdw r1, [r10-0xad8]
  stxdw [r10-0x18], r1
  ldxdw r1, [r10-0xae0]
  stxdw [r10-0x20], r1
  ldxdw r8, [r7+0x8]
  mov64 r4, r10
  add64 r4, -0x20
  mov64 r1, r8
  lddw r2, data_0690
  mov64 r3, 0x1
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_6cf0
  mov64 r3, r10
  add64 r3, -0xae0
  mov64 r1, r10
  add64 r1, -0x590
  mov64 r2, r8
  call fn_16f0
  ldxb r1, [r10-0x43e]
  jne r1, 0x2, jmp_6d08
  ldxw r0, [r10-0x590]
  ldxw r1, [r10-0x58c]
  ja jmp_6bf0

jmp_6cf0:
  mov64 r1, r0
  rsh64 r1, 0x20
  ja jmp_6bf0

jmp_6d08:
  ldxdw r8, [r10-0x450]
  mov64 r2, r10
  add64 r2, -0x590
  lddw r1, data_0328
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_6d78
  mov64 r0, 0x10
  jne r1, 0x1, jmp_6d70
  mov64 r0, 0x1

jmp_6d70:
  ja jmp_6bf0

jmp_6d78:
  ldxdw r3, [r10-0x590]
  ldxdw r1, [r10-0xb08]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0xb10]
  add64 r1, -0x2
  stxdw [r10-0x1000], r1
  add64 r7, 0x10
  mov64 r1, r10
  add64 r1, -0xb00
  mov64 r5, r10
  mov64 r2, r8
  mov64 r4, r7
  call fn_8480
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_6bf0
  and64 r1, 0x1
  jeq r1, 0x0, jmp_6e80
  mov64 r0, 0x0
  mov64 r1, 0x2
  ldxdw r4, [r10-0xb18]
  ldxb r2, [r4+0x2]
  jeq r2, 0x0, jmp_6bf0
  ldxdw r2, [r4+0x50]
  jne r2, 0x53a, jmp_6bf0
  ldxb r2, [r4+0x0]
  jeq r2, 0xff, jmp_6e90
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_6bf0

jmp_6e80:
  mov64 r0, 0x1a
  ja jmp_6bf0

jmp_6e90:
  ldxdw r2, [r10-0xb08]
  and64 r2, 0xff
  jge r2, 0xa, jmp_6f40
  mov64 r1, r2
  lsh64 r1, 0x7
  mov64 r3, r10
  add64 r3, -0xb00
  add64 r3, r1
  mul64 r2, 0x7a
  mov64 r1, r4
  add64 r1, r2
  ldxdw r2, [r3+0xc8]
  stxdw [r1+0x130], r2
  ldxdw r2, [r3+0xd0]
  stxdw [r1+0x138], r2
  ldxdw r2, [r3+0xd8]
  stxdw [r1+0x140], r2
  ldxdw r1, [r10-0xac0]
  stxdw [r4+0xa4], r1
  stb [r4+0x0], 0xff
  mov64 r0, 0x1a
  ja jmp_6bf0

jmp_6f40:
  stb [r4+0x0], 0xff
  ja jmp_6bf0

fn_6f50:
  mov64 r6, r2
  mov64 r7, r1
  jne r3, 0x7, jmp_7200
  ldxdw r2, [r6+0x0]
  mov64 r1, r10
  add64 r1, -0x6e8
  mov64 r3, r7
  call fn_3ed0
  ldxw r1, [r10-0x6e4]
  ldxw r0, [r10-0x6e8]
  ldxb r8, [r10-0x17b]
  jeq r8, 0x2, jmp_7210
  stxdw [r10-0xc60], r7
  mov64 r3, r10
  add64 r3, -0xc50
  mov64 r2, r10
  add64 r2, -0x6e0
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x565
  mov64 r7, r0
  call fn_15658
  stxb [r10-0x6eb], r8
  stxw [r10-0xc54], r9
  stxw [r10-0xc58], r7
  ldxh r1, [r10-0x17a]
  stxh [r10-0x6ea], r1
  ldxdw r1, [r10-0xc20]
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0xc28]
  stxdw [r10-0x168], r1
  ldxdw r1, [r10-0xc30]
  stxdw [r10-0x170], r1
  ldxdw r1, [r10-0xc38]
  stxdw [r10-0x178], r1
  ldxdw r8, [r6+0x18]
  mov64 r4, r10
  add64 r4, -0x178
  mov64 r1, r8
  lddw r2, data_0690
  mov64 r3, 0x1
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_7218
  mov64 r3, r10
  add64 r3, -0xc38
  mov64 r1, r10
  add64 r1, -0x6e8
  mov64 r2, r8
  call fn_16f0
  ldxw r1, [r10-0x6e4]
  ldxw r0, [r10-0x6e8]
  ldxb r8, [r10-0x596]
  jeq r8, 0x2, jmp_7210
  mov64 r3, r10
  add64 r3, -0x150
  mov64 r2, r10
  add64 r2, -0x6e0
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  mov64 r9, r0
  call fn_15658
  ldxw r1, [r10-0x595]
  stxw [r10-0x5], r1
  ldxb r1, [r10-0x591]
  stxb [r10-0x1], r1
  stxb [r10-0x6], r8
  stxw [r10-0x154], r7
  stxw [r10-0x158], r9
  mov64 r2, r10
  add64 r2, -0x6e8
  lddw r1, data_0328
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_7230
  mov64 r0, 0x10
  jne r1, 0x1, jmp_71f8
  mov64 r0, 0x1

jmp_71f8:
  ja jmp_7210

jmp_7200:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_7210:
  exit

jmp_7218:
  mov64 r1, r0
  rsh64 r1, 0x20
  ja jmp_7210

jmp_7230:
  ldxdw r5, [r10-0x6e8]
  mov64 r3, r10
  add64 r3, -0xc58
  mov64 r4, r10
  add64 r4, -0x158
  ldxdw r1, [r10-0xc60]
  mov64 r2, r6
  call fn_7278
  ja jmp_7210

fn_7278:
  mov64 r9, r5
  mov64 r6, r4
  mov64 r8, r1
  mov64 r1, 0x2
  mov64 r0, 0x0
  ldxdw r7, [r2+0x28]
  ldxdw r4, [r3+0x20]
  ldxdw r5, [r7+0x8]
  jne r5, r4, jmp_76c0
  ldxdw r4, [r3+0x28]
  ldxdw r5, [r7+0x10]
  jne r5, r4, jmp_76c0
  ldxdw r4, [r3+0x30]
  ldxdw r5, [r7+0x18]
  jne r5, r4, jmp_76c0
  ldxdw r4, [r3+0x38]
  ldxdw r5, [r7+0x20]
  jne r5, r4, jmp_76c0
  ldxb r4, [r7+0x3]
  jeq r4, 0x0, jmp_76c0
  stxdw [r10-0x3f8], r3
  stxdw [r10-0x3f0], r2
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x3e8], r1
  lddw r2, data_06a0
  mov64 r3, 0x1
  mov64 r4, r8
  call fn_05b0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_76c0
  stxb [r10-0x3d9], r1
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r4, [r10-0x3e8]
  ldxdw r2, [r4+0x8]
  ldxdw r3, [r6+0x60]
  jne r3, r2, jmp_76c0
  ldxdw r2, [r4+0x10]
  ldxdw r3, [r6+0x68]
  jne r3, r2, jmp_76c0
  ldxdw r2, [r4+0x18]
  ldxdw r3, [r6+0x70]
  jne r3, r2, jmp_76c0
  ldxdw r2, [r4+0x20]
  ldxdw r3, [r6+0x78]
  jne r3, r2, jmp_76c0
  ldxdw r2, [r10-0x3f0]
  add64 r2, 0x20
  add64 r7, 0x8
  ldxdw r1, [r10-0x3f8]
  ldxh r3, [r1+0x568]
  mov64 r1, r10
  add64 r1, -0x318
  stxdw [r10-0x168], r1
  lddw r1, str_038b
  stxdw [r10-0x178], r1
  stxdw [r10-0x408], r3
  stxh [r10-0x318], r3
  stdw [r10-0x160], 0x2
  stdw [r10-0x170], 0x6
  stxdw [r10-0x410], r2
  ldxdw r1, [r2+0x0]
  mov64 r2, r10
  add64 r2, -0x178
  stxdw [r10-0x400], r1
  mov64 r3, 0x2
  mov64 r4, r7
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_76b0
  mov64 r1, r10
  add64 r1, -0x178
  ldxdw r2, [r10-0x400]
  mov64 r3, r7
  call fn_1128
  ldxw r1, [r10-0x178]
  jne r1, 0x1, jmp_7538
  ldxw r1, [r10-0x170]
  ldxw r0, [r10-0x174]
  ja jmp_76c0

jmp_7538:
  mov64 r1, 0x8
  ldxh r2, [r10-0x148]
  ldxdw r3, [r10-0x408]
  mov64 r4, r3
  jne r2, r4, jmp_76c8
  stxdw [r10-0x420], r4
  ldxdw r2, [r10-0x3f0]
  add64 r2, 0x30
  ldxdw r1, [r10-0x150]
  stxdw [r10-0x428], r1
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x430], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x438], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x440], r1
  mov64 r1, r10
  add64 r1, -0x318
  stxdw [r10-0x168], r1
  lddw r1, data_0391
  stxdw [r10-0x178], r1
  stxh [r10-0x318], r3
  stdw [r10-0x160], 0x2
  stdw [r10-0x170], 0x6
  stxdw [r10-0x448], r2
  ldxdw r1, [r2+0x0]
  mov64 r2, r10
  add64 r2, -0x178
  stxdw [r10-0x418], r1
  mov64 r3, 0x2
  mov64 r4, r7
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_76b0
  mov64 r1, r10
  add64 r1, -0x178
  ldxdw r2, [r10-0x418]
  mov64 r3, r7
  call fn_25d8
  ldxb r1, [r10-0xc0]
  jne r1, 0x2, jmp_76d8
  ldxw r1, [r10-0x174]
  ldxw r0, [r10-0x178]
  ja jmp_76c0

jmp_76b0:
  mov64 r1, r0
  rsh64 r1, 0x20

jmp_76c0:
  exit

jmp_76c8:
  mov64 r0, 0x0
  ja jmp_76c0

jmp_76d8:
  ldxh r1, [r10-0xc8]
  ldxdw r2, [r10-0x420]
  jne r1, r2, jmp_7888
  mov64 r1, 0x2
  ldxdw r2, [r10-0x3f0]
  ldxdw r3, [r2+0x0]
  ldxb r2, [r3+0x2]
  mov64 r0, 0x0
  jeq r2, 0x0, jmp_76c0
  stxdw [r10-0x458], r3
  ldxdw r2, [r10-0x400]
  ldxb r2, [r2+0x2]
  jeq r2, 0x0, jmp_76c0
  ldxdw r2, [r10-0x418]
  ldxb r2, [r2+0x2]
  jeq r2, 0x0, jmp_76c0
  ldxdw r1, [r10-0xd0]
  stxdw [r10-0x468], r1
  ldxdw r1, [r10-0x3f0]
  ldxdw r2, [r1+0x8]
  mov64 r1, r10
  add64 r1, -0x178
  stxdw [r10-0x460], r2
  mov64 r3, r8
  ldxdw r4, [r10-0x408]
  call fn_5b38
  ldxw r1, [r10-0x174]
  stxdw [r10-0x450], r1
  ldxw r1, [r10-0x178]
  stxdw [r10-0x420], r1
  ldxb r8, [r10-0xbc]
  jeq r8, 0x3, jmp_7c68
  mov64 r1, r10
  add64 r1, -0x3d0
  mov64 r2, r10
  add64 r2, -0x170
  mov64 r3, 0xb4
  call fn_15658
  ldxh r1, [r10-0xbb]
  stxh [r10-0x31b], r1
  ldxb r1, [r10-0xb9]
  stxb [r10-0x319], r1
  ldxdw r1, [r10-0x450]
  stxw [r10-0x3d4], r1
  ldxdw r1, [r10-0x420]
  stxw [r10-0x3d8], r1
  stxb [r10-0x31c], r8
  jne r8, 0x2, jmp_78a0
  mov64 r5, 0x0
  mov64 r1, 0x1
  stxdw [r10-0x470], r1
  ldxdw r6, [r6+0x140]
  mov64 r8, 0x0
  ja jmp_79b0

jmp_7888:
  mov64 r0, 0x0
  mov64 r1, 0x8
  ja jmp_76c0

jmp_78a0:
  ldxb r1, [r10-0x31d]
  jeq r1, 0x0, jmp_78c8
  ldxdw r1, [r10-0x460]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_7c48

jmp_78c8:
  ldxdw r6, [r6+0x140]
  mov64 r1, r10
  add64 r1, -0x3d8
  mov64 r2, r9
  ldxdw r3, [r10-0x3f8]
  mov64 r4, r6
  call fn_10ec0
  mov64 r8, r0
  mov64 r1, r8
  and64 r1, 0x1
  jeq r1, 0x0, jmp_7948
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  rsh64 r8, 0x20
  stxdw [r10-0x450], r8
  ja jmp_7c68

jmp_7948:
  mov64 r5, 0x0
  mov64 r1, 0x1
  stxdw [r10-0x470], r1
  ldxb r1, [r10-0x31c]
  jeq r1, 0x2, jmp_7980
  mov64 r2, 0x0
  stxdw [r10-0x470], r2

jmp_7980:
  mov64 r2, r10
  add64 r2, -0x3d8
  jeq r1, 0x2, jmp_79a0
  mov64 r5, r2

jmp_79a0:
  and64 r8, 0x100
  rsh64 r8, 0x8

jmp_79b0:
  mov64 r1, r10
  add64 r1, -0x178
  ldxdw r2, [r10-0x3f8]
  mov64 r3, r9
  mov64 r4, r6
  call fn_f850
  ldxw r1, [r10-0x178]
  jne r1, 0x1, jmp_7a30
  mov64 r1, 0x1a
  stxdw [r10-0x420], r1
  ldxw r1, [r10-0x174]
  stxdw [r10-0x450], r1
  jeq r1, 0x15, jmp_7c68

jmp_7a18:
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  ja jmp_7c68

jmp_7a30:
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  ldxdw r1, [r10-0x458]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_7c58
  ldxdw r1, [r10-0x458]
  ldxdw r1, [r1+0x50]
  jne r1, 0x53a, jmp_7c58
  mov64 r1, 0xb
  stxdw [r10-0x420], r1
  mov64 r1, 0x0
  stxdw [r10-0x450], r1
  ldxdw r1, [r10-0x458]
  ldxb r1, [r1+0x0]
  jne r1, 0xff, jmp_7c68
  ldxh r1, [r10-0x160]
  stxdw [r10-0x458], r1
  ldxdw r9, [r10-0x168]
  ldxdw r6, [r10-0x170]
  jeq r8, 0x0, jmp_7b28
  ldxdw r1, [r10-0x460]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_7c80
  ldxdw r1, [r10-0x460]
  ldxdw r1, [r1+0x50]
  jne r1, 0xbf, jmp_7c80
  mov64 r1, 0x0
  stxdw [r10-0x450], r1
  ldxdw r1, [r10-0x460]
  ldxb r1, [r1+0x0]
  jne r1, 0xff, jmp_7c68

jmp_7b28:
  mov64 r1, 0x15
  stxdw [r10-0x450], r1
  ldxdw r1, [r10-0x428]
  jlt r9, r1, jmp_7a18
  ldxdw r1, [r10-0x400]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_7c80
  ldxdw r1, [r10-0x400]
  ldxdw r1, [r1+0x50]
  jne r1, 0x32, jmp_7c80
  mov64 r1, 0x0
  stxdw [r10-0x450], r1
  ldxdw r1, [r10-0x400]
  ldxb r1, [r1+0x0]
  jne r1, 0xff, jmp_7c68
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  ldxdw r1, [r10-0x418]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_7c58
  ldxdw r1, [r10-0x418]
  ldxdw r1, [r1+0x50]
  jne r1, 0xc1, jmp_7c58
  ldxdw r1, [r10-0x418]
  ldxb r1, [r1+0x0]
  mov64 r2, 0xb
  stxdw [r10-0x420], r2
  jeq r1, 0xff, jmp_7c98
  mov64 r2, 0x1
  stxdw [r10-0x450], r2
  jne r1, 0xff, jmp_7cc0

jmp_7c20:
  ldxdw r2, [r10-0x450]
  lsh64 r2, 0x2
  stxdw [r10-0x450], r2
  jeq r1, 0xff, jmp_7cf0
  ja jmp_7c68

jmp_7c48:
  mov64 r1, 0x0
  stxdw [r10-0x420], r1

jmp_7c58:
  mov64 r1, 0x2
  stxdw [r10-0x450], r1

jmp_7c68:
  ldxdw r0, [r10-0x420]
  ldxdw r1, [r10-0x450]
  ja jmp_76c0

jmp_7c80:
  mov64 r1, 0x2
  stxdw [r10-0x450], r1
  ja jmp_7a18

jmp_7c98:
  mov64 r2, 0x0
  stxdw [r10-0x420], r2
  mov64 r2, 0x1
  stxdw [r10-0x450], r2
  jeq r1, 0xff, jmp_7c20

jmp_7cc0:
  mov64 r2, 0x0
  stxdw [r10-0x450], r2
  ldxdw r2, [r10-0x450]
  lsh64 r2, 0x2
  stxdw [r10-0x450], r2
  jne r1, 0xff, jmp_7c68

jmp_7cf0:
  ldxdw r1, [r10-0x468]
  jeq r1, -0x1, jmp_7c68
  ldxdw r1, [r10-0x3f8]
  ldxdw r2, [r1+0x48]
  ldxdw r1, [r1+0x40]
  jne r1, r2, jmp_7e88
  ldxdw r1, [r10-0x3f8]
  ldxdw r1, [r1+0x58]
  jne r1, r6, jmp_7e88
  ldxdw r1, [r10-0x3f8]
  ldxdw r1, [r1+0x60]
  jne r1, r9, jmp_7e88
  ldxdw r1, [r10-0x3f8]
  ldxdw r3, [r1+0x50]
  ldxdw r1, [r10-0x428]
  jne r1, r9, jmp_7e98
  ldxdw r1, [r10-0x438]
  jne r1, r6, jmp_7e98
  ldxdw r1, [r10-0x440]
  jne r1, r6, jmp_7e98
  ldxdw r1, [r10-0x3f8]
  ldxh r1, [r1+0x56a]
  ldxdw r2, [r10-0x458]
  jne r1, r2, jmp_7e98
  ldxdw r1, [r10-0x430]
  jne r1, r3, jmp_7e98
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  jne r8, 0x0, jmp_7de8
  mov64 r1, 0x1a
  stxdw [r10-0x420], r1

jmp_7de8:
  xor64 r8, -0x1
  ldxdw r1, [r10-0x470]
  or64 r8, r1
  and64 r8, 0x1
  mov64 r1, 0x2
  stxdw [r10-0x450], r1
  jne r8, 0x0, jmp_7c68
  mov64 r2, r10
  add64 r2, -0x3d8
  ldxdw r1, [r10-0x460]
  call fn_3118
  stxdw [r10-0x450], r1
  stxdw [r10-0x420], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_7c68
  mov64 r1, 0x1a
  stxdw [r10-0x420], r1
  ja jmp_7c68

jmp_7e88:
  ldxdw r1, [r10-0x3f8]
  ldxdw r3, [r1+0x50]

jmp_7e98:
  ldxdw r1, [r10-0x430]
  jgt r3, r1, jmp_7eb0
  ldxdw r3, [r10-0x430]

jmp_7eb0:
  add64 r3, 0x1
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  mov64 r1, 0x1
  stxdw [r10-0x428], r3
  jeq r3, 0x0, jmp_7ee8
  mov64 r1, 0x0

jmp_7ee8:
  mov64 r2, 0x4
  stxdw [r10-0x450], r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_7c68
  ldxdw r1, [r10-0x428]
  stxdw [r10-0x2f8], r1
  stxdw [r10-0x300], r9
  stxdw [r10-0x308], r6
  stxdw [r10-0x310], r6
  ldxdw r1, [r10-0x408]
  stxh [r10-0x316], r1
  stb [r10-0x318], 0x4
  stw [r10-0x229], 0x0
  stdw [r10-0x230], 0x0
  stdw [r10-0x238], 0x0
  stdw [r10-0x240], 0x0
  stdw [r10-0x248], 0x0
  mov64 r1, r10
  add64 r1, -0x318
  mov64 r2, r10
  add64 r2, -0x248
  call fn_dd48
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  stxdw [r10-0x450], r0
  jne r0, 0x0, jmp_7c68
  ldxdw r2, [r10-0x3f0]
  mov64 r0, r2
  add64 r0, 0x28
  mov64 r1, r2
  add64 r1, 0x10
  ldxdw r4, [r10-0x3e8]
  add64 r4, 0x8
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x1e0], r7
  ldxdw r5, [r10-0x418]
  add64 r5, 0x8
  stxdw [r10-0x1f0], r5
  ldxdw r5, [r10-0x400]
  add64 r5, 0x8
  stxdw [r10-0x200], r5
  stxdw [r10-0x220], r4
  add64 r3, 0x8
  stxdw [r10-0x210], r3
  sth [r10-0x1d8], 0x0
  sth [r10-0x1e8], 0x1
  sth [r10-0x1f8], 0x1
  sth [r10-0x208], 0x0
  sth [r10-0x218], 0x100
  mov64 r3, r10
  add64 r3, -0x3d9
  stxdw [r10-0x1c0], r3
  lddw r3, str_037b
  stxdw [r10-0x1d0], r3
  stdw [r10-0x1b8], 0x1
  stdw [r10-0x1c8], 0x10
  stxdw [r10-0x3e8], r0
  stxdw [r10-0x190], r0
  ldxdw r3, [r10-0x448]
  stxdw [r10-0x198], r3
  ldxdw r3, [r10-0x410]
  stxdw [r10-0x1a0], r3
  add64 r2, 0x18
  stxdw [r10-0x1a8], r2
  stxdw [r10-0x1b0], r1
  mov64 r1, r10
  add64 r1, -0x1d0
  stxdw [r10-0x188], r1
  stdw [r10-0x180], 0x2
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x178
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x1d0
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x220
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x188
  stxdw [r10-0x58], r1
  mov64 r1, r10
  add64 r1, -0x1b0
  stxdw [r10-0x60], r1
  stdw [r10-0x8], 0x5
  stdw [r10-0x10], 0x5
  stdw [r10-0x18], 0x0
  stdw [r10-0x30], 0x5
  stdw [r10-0x38], 0x5
  stdw [r10-0x40], 0x0
  mov64 r1, r10
  add64 r1, -0x60
  call fn_0360
  stxdw [r10-0x420], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_8338
  mov64 r1, r10
  add64 r1, -0x248
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x220
  stxdw [r10-0x58], r1
  stxdw [r10-0x60], r7
  stdw [r10-0x40], 0x23
  stdw [r10-0x50], 0x5
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x178
  mov64 r3, 0x5
  stxdw [r10-0x450], r3
  mov64 r4, r10
  add64 r4, -0x188
  mov64 r5, 0x1
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x410]
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r10-0x3e8]
  ldxdw r3, [r1+0x0]
  add64 r3, 0x8
  mov64 r1, r10
  add64 r1, -0x178
  call fn_1128
  ldxw r1, [r10-0x178]
  jne r1, 0x1, jmp_8340
  ldxw r1, [r10-0x170]
  stxdw [r10-0x450], r1
  ldxw r1, [r10-0x174]
  stxdw [r10-0x420], r1
  ja jmp_7c68

jmp_8338:
  ja jmp_7c68

jmp_8340:
  mov64 r1, 0x0
  stxdw [r10-0x420], r1
  ldxdw r1, [r10-0x170]
  jne r1, r6, jmp_7c68
  ldxdw r1, [r10-0x168]
  jne r1, r6, jmp_7c68
  ldxdw r1, [r10-0x150]
  jne r1, r9, jmp_7c68
  ldxdw r1, [r10-0x158]
  ldxdw r2, [r10-0x428]
  jne r1, r2, jmp_7c68
  jeq r8, 0x0, jmp_8418
  mov64 r1, 0x2
  stxdw [r10-0x450], r1
  ldxb r1, [r10-0x31c]
  jeq r1, 0x2, jmp_7c68
  ldxdw r1, [r10-0x3f0]
  ldxdw r1, [r1+0x8]
  mov64 r2, r10
  add64 r2, -0x3d8
  call fn_3118
  stxdw [r10-0x450], r1
  stxdw [r10-0x420], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_7c68

jmp_8418:
  ldxdw r2, [r10-0x3f8]
  ldxdw r1, [r10-0x458]
  stxh [r2+0x56a], r1
  stxdw [r2+0x60], r9
  stxdw [r2+0x58], r6
  ldxdw r1, [r10-0x428]
  stxdw [r2+0x50], r1
  ldxdw r1, [r2+0x40]
  stxdw [r2+0x48], r1
  ldxdw r1, [r10-0x3f0]
  ldxdw r1, [r1+0x0]
  call fn_31e8
  ja jmp_76c0

fn_8480:
  ldxdw r0, [r5-0x1000]
  jeq r0, 0x0, jmp_8a00
  stxdw [r10-0x50], r2
  stxdw [r10-0x48], r0
  ldxdw r2, [r5-0xff8]
  mov64 r8, r2
  and64 r8, 0xff
  jge r8, 0xa, jmp_9378
  mov64 r0, r8
  lsh64 r0, 0x7
  mov64 r7, r1
  add64 r7, r0
  mov64 r9, 0x0
  lddw r0, 0x200000000
  ldxb r6, [r7+0xe1]
  and64 r6, 0x1
  jeq r6, 0x0, jmp_8a30
  stxdw [r10-0x58], r2
  mov64 r5, r7
  add64 r5, 0x68
  ldxdw r2, [r4+0x0]
  ldxdw r6, [r5+0x0]
  ldxdw r9, [r2+0x8]
  jne r9, r6, jmp_8a28
  ldxdw r6, [r5+0x8]
  ldxdw r9, [r2+0x10]
  jne r9, r6, jmp_8a28
  ldxdw r6, [r5+0x10]
  ldxdw r9, [r2+0x18]
  jne r9, r6, jmp_8a28
  stxdw [r10-0x60], r5
  ldxdw r6, [r5+0x18]
  ldxdw r9, [r2+0x20]
  jne r9, r6, jmp_8a28
  jgt r8, 0x5, jmp_8a18
  mov64 r6, r8
  lsh64 r6, 0x3
  lddw r9, data_03c8
  add64 r9, r6
  mov64 r5, r2
  ldxdw r2, [r9+0x0]
  lddw r9, data_0488
  add64 r9, r6
  ldxdw r9, [r9+0x0]
  or64 r9, r2
  lddw r2, data_04b8
  add64 r2, r6
  ldxdw r2, [r2+0x0]
  or64 r9, r2
  ldxdw r2, [r5+0x28]
  jne r2, r9, jmp_8a28
  lddw r2, data_03f8
  add64 r2, r6
  ldxdw r2, [r2+0x0]
  ldxdw r9, [r5+0x30]
  jne r9, r2, jmp_8a28
  lddw r2, data_0428
  add64 r2, r6
  ldxdw r2, [r2+0x0]
  ldxdw r9, [r5+0x38]
  jne r9, r2, jmp_8a28
  lddw r2, data_0458
  add64 r2, r6
  ldxdw r2, [r2+0x0]
  stxdw [r10-0x68], r5
  ldxdw r6, [r5+0x40]
  mov64 r9, 0x0
  jne r6, r2, jmp_8a30
  ldxdw r2, [r10-0x48]
  add64 r2, -0x1
  ldxdw r5, [r10-0x58]
  add64 r5, -0x2
  and64 r5, 0xff
  mov64 r6, 0x0
  stxdw [r10-0x70], r5
  jgt r5, 0x2, jmp_8758
  mov64 r5, r2
  ldxdw r2, [r10-0x70]
  lsh64 r2, 0x3
  lddw r0, data_0398
  add64 r0, r2
  mov64 r2, r5
  ldxdw r6, [r0+0x0]

jmp_8758:
  mov64 r0, 0x2
  jne r2, r6, jmp_9178
  stxdw [r10-0x48], r2
  ldxdw r6, [r7+0xd8]
  ldxdw r5, [r7+0xd0]
  ldxdw r2, [r7+0xc8]
  stxdw [r10-0x98], r2
  ldxdw r2, [r7+0xa0]
  stxdw [r10-0x90], r2
  ldxdw r2, [r7+0x98]
  stxdw [r10-0x88], r2
  ldxdw r2, [r7+0x90]
  stxdw [r10-0x80], r2
  ldxdw r2, [r7+0x88]
  stxdw [r10-0x78], r2
  jne r8, 0x3, jmp_89d0
  stxdw [r10-0xa0], r5
  ldxdw r2, [r10-0x48]
  jle r2, 0x1, jmp_9590
  ldxdw r7, [r4+0x10]
  ldxdw r2, [r7+0x8]
  lddw r5, 0x65d346050182c6bd
  jne r2, r5, jmp_9178
  ldxdw r2, [r7+0x10]
  lddw r5, 0x610f76e70e70e483
  jne r2, r5, jmp_9178
  ldxdw r2, [r7+0x18]
  lddw r5, -0x322b4e000b453a
  jne r2, r5, jmp_9178
  ldxdw r2, [r7+0x20]
  lddw r5, 0x4fe798fce46b21ca
  jne r2, r5, jmp_9178
  stxdw [r10-0xd0], r4
  stxdw [r10-0xa8], r3
  stxdw [r10-0xb8], r1
  mov64 r3, r7
  ldxdw r1, [r7+0x28]
  lddw r2, 0x14b3ded492fcf80b
  jne r1, r2, jmp_9178
  ldxdw r1, [r3+0x30]
  lddw r2, -0x68c84594f411f7a6
  jne r1, r2, jmp_9178
  ldxdw r1, [r3+0x38]
  lddw r2, 0x2920836652dd4691
  jne r1, r2, jmp_9178
  ldxdw r1, [r3+0x40]
  lddw r2, -0x6533faea60a4de51
  jne r1, r2, jmp_9178
  ldxb r9, [r3+0x0]
  jlt r9, 0x2, jmp_89e8
  add64 r9, -0x1
  stxb [r3+0x0], r9
  and64 r9, 0xff
  add64 r9, 0x1
  mov64 r1, r9
  and64 r1, 0xff
  jne r1, r9, jmp_9578
  mov64 r7, r3
  ldxdw r2, [r7+0x50]
  mov64 r1, r7
  add64 r1, 0x58
  call fn_db10
  stxb [r7+0x0], r9
  mov64 r9, 0x0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  ldxdw r1, [r10-0xb8]
  ldxdw r3, [r10-0xa8]
  ldxdw r4, [r10-0xd0]
  ldxdw r5, [r10-0xa0]
  jne r0, 0x0, jmp_9178

jmp_89d0:
  ldxdw r2, [r10-0x68]
  ldxb r0, [r2+0x0]
  jge r0, 0x2, jmp_8a40

jmp_89e8:
  mov64 r9, 0xb
  mov64 r0, 0x0
  ja jmp_9178

jmp_8a00:
  lddw r0, 0x200000000
  ja jmp_8a38

jmp_8a18:
  lddw r0, 0x100000000

jmp_8a28:
  mov64 r9, 0x0

jmp_8a30:
  or64 r0, r9

jmp_8a38:
  exit

jmp_8a40:
  stxdw [r10-0xa0], r5
  stxdw [r10-0xb0], r6
  mov64 r5, r4
  add64 r0, -0x1
  stxb [r2+0x0], r0
  ldxdw r4, [r2+0x50]
  mov64 r0, r2
  add64 r0, 0x58
  ldxdw r2, [r10-0x70]
  jge r2, 0x3, jmp_8b98
  stxdw [r10-0xc8], r0
  stxdw [r10-0xc0], r4
  ldxdw r2, [r10-0x48]
  jeq r2, 0x0, jmp_95b8
  mov64 r0, 0x2
  ldxdw r7, [r5+0x8]
  ldxdw r2, [r7+0x8]
  ldxdw r4, [r10-0x78]
  jne r2, r4, jmp_9138
  ldxdw r2, [r7+0x10]
  ldxdw r4, [r10-0x80]
  jne r2, r4, jmp_9138
  ldxdw r2, [r7+0x18]
  ldxdw r6, [r10-0x88]
  jne r2, r6, jmp_9138
  stxdw [r10-0x70], r7
  ldxdw r2, [r7+0x20]
  ldxdw r7, [r10-0x90]
  jne r2, r7, jmp_9138
  stxdw [r10-0xb8], r1
  stxdw [r10-0xa8], r3
  stxdw [r10-0xd0], r5
  jeq r8, 0x3, jmp_8cb0
  jne r8, 0x2, jmp_8cf8
  lddw r1, -0x17ae6f94d86aa607
  lddw r2, 0x271c31da13a86c8d
  lddw r6, -0x679c97ccd8e185dc
  lddw r5, 0x57f7024af6196809
  ja jmp_8d38

jmp_8b98:
  stxdw [r10-0xb8], r1
  stdw [r10-0x8], 0x0
  stdw [r10-0x10], 0x0
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x0
  stxdw [r10-0xa8], r3
  stxdw [r10-0xfd0], r3
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0xff0], r1
  stdw [r10-0xfd8], 0x0
  stdw [r10-0xfe0], 0x1
  stdw [r10-0xff8], 0x0
  stdw [r10-0x1000], 0x1
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r5, r10
  ldxdw r2, [r10-0x58]
  mov64 r3, r0
  call fn_bae8
  ldxw r1, [r10-0x40]
  jeq r1, 0x0, jmp_8c68
  ldxb r0, [r10-0x3c]
  ja jmp_9138

jmp_8c68:
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ldxdw r3, [r10-0x38]
  ldxdw r5, [r10-0x98]
  jeq r5, 0x0, jmp_91f0

jmp_8c90:
  jgt r3, r5, jmp_8f70
  mov64 r4, r5
  sub64 r4, r3
  ja jmp_8f80

jmp_8cb0:
  lddw r1, -0x6533faea60a4de51
  lddw r2, 0x2920836652dd4691
  lddw r6, -0x68c84594f411f7a6
  lddw r5, 0x14b3ded492fcf80b
  ja jmp_8d38

jmp_8cf8:
  lddw r1, -0x6f077ddd0a585744
  lddw r2, 0x1569326529647267
  lddw r6, -0x3cecd16c12b85db3
  lddw r5, -0x68bdbd0cc49f1df7

jmp_8d38:
  ldxdw r7, [r10-0x70]
  ldxdw r9, [r7+0x28]
  jne r9, r5, jmp_9130
  ldxdw r5, [r7+0x30]
  jne r5, r6, jmp_9130
  ldxdw r5, [r10-0x70]
  ldxdw r5, [r5+0x38]
  jne r5, r2, jmp_9130
  ldxdw r2, [r10-0x70]
  ldxdw r2, [r2+0x40]
  jne r2, r1, jmp_9130
  ldxdw r1, [r10-0x70]
  add64 r1, 0x8
  jne r8, 0x4, jmp_8fa8
  ldxdw r2, [r10-0x48]
  jeq r2, 0x1, jmp_95e0
  ldxdw r2, [r10-0xd0]
  ldxdw r6, [r2+0x10]
  ldxdw r2, [r6+0x8]
  lddw r5, -0x7c7378fe34e6938d
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x10]
  lddw r5, 0x6908b750f16c5b93
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x18]
  lddw r5, -0x2182f51b47f76d7d
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x20]
  lddw r5, 0x212b43e785330d84
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x28]
  lddw r5, -0x68bdbd0cc49f1df7
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x30]
  lddw r5, -0x3cecd16c12b85db3
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x38]
  lddw r5, 0x1569326529647267
  jne r2, r5, jmp_9130
  ldxdw r2, [r6+0x40]
  lddw r5, -0x6f077ddd0a585744
  mov64 r9, 0x0
  jne r2, r5, jmp_9138
  ldxdw r2, [r10-0x70]
  ldxb r2, [r2+0x0]
  jle r2, 0x1, jmp_8fc0
  add64 r2, -0x1
  ldxdw r5, [r10-0x70]
  stxb [r5+0x0], r2
  ldxdw r5, [r5+0x50]
  ldxdw r0, [r1+0x18]
  stxdw [r10-0x8], r0
  ldxdw r0, [r1+0x10]
  stxdw [r10-0x10], r0
  ldxdw r0, [r1+0x8]
  stxdw [r10-0x18], r0
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x20], r1
  ldxb r1, [r6+0x0]
  jgt r1, 0x1, jmp_93a0
  mov64 r9, 0xb
  mov64 r0, 0x0
  ja jmp_94c0

jmp_8f70:
  mov64 r4, r3
  sub64 r4, r5

jmp_8f80:
  rsh64 r5, 0x1
  jle r4, r5, jmp_91f0
  mov64 r9, 0x0
  mov64 r0, 0x5
  ja jmp_9138

jmp_8fa8:
  ldxdw r2, [r10-0x70]
  ldxb r2, [r2+0x0]
  jge r2, 0x2, jmp_8fd8

jmp_8fc0:
  mov64 r9, 0xb
  mov64 r0, 0x0
  ja jmp_9138

jmp_8fd8:
  add64 r2, -0x1
  ldxdw r0, [r10-0x70]
  stxb [r0+0x0], r2
  ldxdw r2, [r0+0x50]
  ldxdw r5, [r1+0x18]
  stxdw [r10-0x8], r5
  ldxdw r5, [r1+0x10]
  stxdw [r10-0x10], r5
  ldxdw r5, [r1+0x8]
  stxdw [r10-0x18], r5
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x20], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0xfd0], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r2
  mov64 r1, r0
  add64 r1, 0x58
  stxdw [r10-0x1000], r1
  stdw [r10-0xfd8], 0x0
  stdw [r10-0xfe0], 0x1
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r5, r10
  ldxdw r2, [r10-0x58]
  ldxdw r3, [r10-0xc8]
  ldxdw r4, [r10-0xc0]
  call fn_bae8
  ldxw r1, [r10-0x40]
  jne r1, 0x1, jmp_9188
  ldxdw r1, [r10-0x70]
  ldxb r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_9578
  ldxb r0, [r10-0x3c]
  ldxdw r2, [r10-0x70]
  stxb [r2+0x0], r1

jmp_9130:
  mov64 r9, 0x0

jmp_9138:
  ldxdw r1, [r10-0x68]
  ldxb r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_9578
  ldxdw r2, [r10-0x68]
  stxb [r2+0x0], r1

jmp_9178:
  lsh64 r0, 0x20
  ja jmp_8a30

jmp_9188:
  ldxdw r1, [r10-0x70]
  ldxb r4, [r1+0x0]
  add64 r4, 0x1
  mov64 r1, r4
  and64 r1, 0xff
  jne r1, r4, jmp_9578
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ldxdw r3, [r10-0x38]

jmp_91d0:
  ldxdw r5, [r10-0x70]
  stxb [r5+0x0], r4
  ldxdw r5, [r10-0x98]
  jne r5, 0x0, jmp_8c90

jmp_91f0:
  mov64 r9, 0x0
  mov64 r0, 0x15
  ldxdw r4, [r10-0xa8]
  jlt r4, r2, jmp_9138
  sub64 r4, r2
  ldxdw r5, [r10-0x50]
  jge r4, r5, jmp_9138
  mov64 r0, 0x6
  ldxdw r4, [r10-0xa0]
  jlt r2, r4, jmp_9138
  ldxdw r4, [r10-0x98]
  jne r4, r3, jmp_9288
  ldxdw r4, [r10-0xa0]
  jne r4, r2, jmp_9288
  ldxdw r4, [r10-0xb0]
  jne r4, r1, jmp_9288
  mov64 r9, 0x1a
  mov64 r0, 0x0
  ja jmp_9138

jmp_9288:
  ldxdw r4, [r10-0x58]
  or64 r4, 0x2
  and64 r4, 0xff
  jne r4, 0x2, jmp_92b8
  ldxdw r4, [r10-0xb0]
  jle r1, r4, jmp_9138

jmp_92b8:
  ldxdw r4, [r10-0xb8]
  ldxdw r4, [r4+0x40]
  jeq r4, -0x1, jmp_9368
  ldxdw r5, [r10-0x60]
  stxdw [r5+0x70], r1
  stxdw [r5+0x68], r2
  stxdw [r5+0x60], r3
  add64 r4, 0x1
  ldxdw r1, [r10-0xb8]
  stxdw [r1+0x40], r4
  ldxdw r1, [r10-0x68]
  ldxb r1, [r1+0x0]
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_9578
  ldxdw r2, [r10-0x68]
  stxb [r2+0x0], r1
  mov64 r9, 0x1a
  lddw r0, 0x100000000
  ja jmp_8a30

jmp_9368:
  mov64 r0, 0x4
  ja jmp_9138

jmp_9378:
  mov64 r1, r8
  mov64 r2, 0xa
  lddw r3, data_06b0
  call fn_14310

jmp_93a0:
  add64 r1, -0x1
  stxb [r6+0x0], r1
  ldxdw r2, [r6+0x50]
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0xfd0], r1
  stxdw [r10-0xfd8], r2
  mov64 r1, r6
  add64 r1, 0x58
  stxdw [r10-0xfe0], r1
  mov64 r1, r10
  add64 r1, -0x20
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x60]
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r5
  ldxdw r1, [r10-0x70]
  add64 r1, 0x58
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x40
  mov64 r5, r10
  mov64 r2, 0x4
  ldxdw r3, [r10-0xc8]
  ldxdw r4, [r10-0xc0]
  call fn_bae8
  ldxw r1, [r10-0x40]
  jne r1, 0x1, jmp_9500
  ldxb r1, [r6+0x0]
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_9578
  ldxb r0, [r10-0x3c]
  stxb [r6+0x0], r1
  ldxdw r1, [r10-0x70]
  ldxb r2, [r1+0x0]

jmp_94c0:
  and64 r2, 0xff
  add64 r2, 0x1
  mov64 r1, r2
  and64 r1, 0xff
  jne r1, r2, jmp_9578
  ldxdw r1, [r10-0x70]
  stxb [r1+0x0], r2
  ja jmp_9138

jmp_9500:
  ldxb r4, [r6+0x0]
  add64 r4, 0x1
  mov64 r1, r4
  and64 r1, 0xff
  jne r1, r4, jmp_9578
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  ldxdw r3, [r10-0x38]
  stxb [r6+0x0], r4
  ldxdw r4, [r10-0x70]
  ldxb r4, [r4+0x0]
  add64 r4, 0x1
  mov64 r5, r4
  and64 r5, 0xff
  jeq r5, r4, jmp_91d0

jmp_9578:
  lddw r1, data_05d0
  call fn_14350

jmp_9590:
  mov64 r1, 0x1
  ldxdw r2, [r10-0x48]
  lddw r3, data_06c8
  call fn_14310

jmp_95b8:
  mov64 r1, 0x0
  mov64 r2, 0x0
  lddw r3, data_06e0
  call fn_14310

jmp_95e0:
  mov64 r1, 0x1
  mov64 r2, 0x1
  lddw r3, data_06f8
  call fn_14310

fn_9608:
  mov64 r8, r4
  mov64 r4, r2
  ldxdw r9, [r5-0xff0]
  mov64 r6, r9
  and64 r6, 0xff
  jge r6, 0x40, jmp_9770
  stxdw [r10-0xc58], r1
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0xc70], r1
  ldxdw r1, [r5-0x1000]
  stxdw [r10-0xc80], r1
  mov64 r1, r10
  add64 r1, -0x6e0
  stxdw [r10-0xc68], r3
  mov64 r2, r3
  mov64 r3, r4
  call fn_3ed0
  mov64 r3, 0x1
  jgt r6, 0x1f, jmp_96a8
  mov64 r3, 0x0

jmp_96a8:
  mov64 r1, r6
  rsh64 r1, 0x1
  mov64 r7, r9
  and64 r7, 0x1
  mov64 r2, r1
  and64 r2, 0x1
  add64 r7, r2
  and64 r1, 0x2
  add64 r7, r1
  mov64 r1, r9
  and64 r1, 0x8
  jne r1, 0x0, jmp_9798
  and64 r9, 0x10
  stxdw [r10-0xc78], r6
  stxdw [r10-0xc60], r8
  jne r9, 0x0, jmp_97c0

jmp_9728:
  ldxw r6, [r10-0x6dc]
  ldxw r8, [r10-0x6e0]
  ldxb r9, [r10-0x173]
  jne r9, 0x2, jmp_97e8

jmp_9748:
  ldxdw r1, [r10-0xc58]
  stxw [r1+0x4], r6
  stxw [r1+0x0], r8
  stb [r1+0x152], 0x2
  ja jmp_9aa8

jmp_9770:
  lddw r2, 0x100000000
  stxdw [r1+0x0], r2
  stb [r1+0x152], 0x2
  ja jmp_9aa8

jmp_9798:
  add64 r7, 0x3
  and64 r9, 0x10
  stxdw [r10-0xc78], r6
  stxdw [r10-0xc60], r8
  jeq r9, 0x0, jmp_9728

jmp_97c0:
  add64 r7, 0x3
  ldxw r6, [r10-0x6dc]
  ldxw r8, [r10-0x6e0]
  ldxb r9, [r10-0x173]
  jeq r9, 0x2, jmp_9748

jmp_97e8:
  stxdw [r10-0xc88], r3
  mov64 r1, r10
  add64 r1, -0xc48
  mov64 r2, r10
  add64 r2, -0x6d8
  mov64 r3, 0x565
  call fn_15658
  stxw [r10-0xc4c], r6
  stxw [r10-0xc50], r8
  ldxh r1, [r10-0x172]
  stxh [r10-0x6e2], r1
  stxb [r10-0x6e3], r9
  and64 r9, 0x1
  jeq r9, 0x0, jmp_9888
  lddw r1, 0x700000000

jmp_9868:
  ldxdw r2, [r10-0xc58]
  stxdw [r2+0x0], r1

jmp_9878:
  stb [r2+0x152], 0x2
  ja jmp_9aa8

jmp_9888:
  ldxdw r1, [r10-0xc18]
  stxdw [r10-0x158], r1
  ldxdw r1, [r10-0xc20]
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0xc28]
  stxdw [r10-0x168], r1
  ldxdw r1, [r10-0xc30]
  stxdw [r10-0x170], r1
  mov64 r4, r10
  add64 r4, -0x170
  ldxdw r6, [r10-0xc60]
  mov64 r1, r6
  lddw r2, data_0690
  mov64 r3, 0x1
  call fn_05b0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_99a0
  mov64 r1, r10
  add64 r1, -0x6e0
  mov64 r3, r10
  add64 r3, -0x170
  mov64 r2, r6
  call fn_16f0
  ldxw r8, [r10-0x6dc]
  ldxw r6, [r10-0x6e0]
  ldxb r9, [r10-0x58e]
  jne r9, 0x2, jmp_99c0
  ldxdw r1, [r10-0xc58]
  stxw [r1+0x4], r8
  stxw [r1+0x0], r6
  stb [r1+0x152], 0x2
  ja jmp_9aa8

jmp_99a0:
  ldxdw r1, [r10-0xc58]
  stxdw [r1+0x0], r0
  stb [r1+0x152], 0x2
  ja jmp_9aa8

jmp_99c0:
  mov64 r1, r10
  add64 r1, -0x138
  mov64 r2, r10
  add64 r2, -0x6d8
  mov64 r3, 0x138
  call fn_15658
  ldxdw r1, [r10-0x598]
  stxdw [r10-0x148], r1
  ldxh r1, [r10-0x590]
  stxh [r10-0x140], r1
  ldxw r1, [r10-0x58d]
  stxw [r10-0x150], r1
  ldxb r1, [r10-0x589]
  stxb [r10-0x14c], r1
  mov64 r1, 0x0
  mov64 r2, 0x2
  ldxdw r3, [r10-0xc68]
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_9a88
  ldxdw r4, [r3+0x50]
  jne r4, 0x53a, jmp_9a88
  ldxb r1, [r3+0x0]
  jeq r1, 0xff, jmp_9ab0
  mov64 r1, 0xb
  mov64 r2, 0x0

jmp_9a88:
  ldxdw r3, [r10-0xc58]
  stxw [r3+0x4], r2
  stxw [r3+0x0], r1
  stb [r3+0x152], 0x2

jmp_9aa8:
  exit

jmp_9ab0:
  ldxdw r1, [r10-0x5a0]
  stxdw [r10-0xc60], r1
  mov64 r2, r10
  add64 r2, -0x6e0
  lddw r1, data_0328
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jeq r0, 0x0, jmp_9b30
  mov64 r1, 0x10
  jne r0, 0x1, jmp_9b18
  mov64 r1, 0x1

jmp_9b18:
  ldxdw r2, [r10-0xc58]
  stxw [r2+0x0], r1
  ja jmp_9878

jmp_9b30:
  stxdw [r10-0xc90], r9
  ldxdw r1, [r10-0xc88]
  add64 r7, r1
  ldxdw r1, [r10-0xc70]
  jne r1, r7, jmp_9de0
  stxdw [r10-0xca8], r8
  stxdw [r10-0xca0], r6
  ldxdw r1, [r10-0x6e0]
  stxdw [r10-0xc88], r1
  mov64 r5, 0x0
  mov64 r9, 0x0
  mov64 r7, 0x0
  ldxdw r1, [r10-0xc68]
  ldxdw r6, [r10-0xc78]

jmp_9ba0:
  mov64 r8, r7
  mov64 r3, r8
  and64 r3, 0xff
  jge r3, 0x6, jmp_9df8
  mov64 r4, r6
  rsh64 r4, r3
  mov64 r7, r8
  add64 r7, 0x1
  and64 r4, 0x1
  jeq r4, 0x0, jmp_9ba0
  mov64 r1, 0x1
  mov64 r3, r8
  add64 r3, -0x2
  and64 r3, 0xff
  mov64 r4, 0x1
  jle r3, 0x2, jmp_9c58
  mov64 r3, r5
  add64 r3, r4
  jge r3, r5, jmp_9c98

jmp_9c38:
  and64 r1, 0x1
  ldxdw r2, [r10-0xc60]
  jeq r1, 0x0, jmp_9cb8
  ja jmp_9f88

jmp_9c58:
  lsh64 r3, 0x3
  lddw r4, data_03b0
  add64 r4, r3
  ldxdw r4, [r4+0x0]
  mov64 r3, r5
  add64 r3, r4
  jlt r3, r5, jmp_9c38

jmp_9c98:
  mov64 r1, 0x0
  and64 r1, 0x1
  ldxdw r2, [r10-0xc60]
  jne r1, 0x0, jmp_9f88

jmp_9cb8:
  ldxdw r1, [r10-0xc70]
  jgt r3, r1, jmp_9f60
  stxdw [r10-0xff8], r8
  mov64 r1, r3
  sub64 r1, r5
  stxdw [r10-0x1000], r1
  lsh64 r5, 0x3
  ldxdw r4, [r10-0xc80]
  add64 r4, r5
  mov64 r1, r10
  add64 r1, -0xc50
  mov64 r5, r10
  stxdw [r10-0xc98], r3
  ldxdw r3, [r10-0xc88]
  call fn_8480
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1a, jmp_9dd0
  mov64 r1, r0
  call fn_0000
  add64 r8, 0xa
  and64 r8, 0xff
  lddw r1, 0x50494b534c43524f
  mov64 r2, 0x1
  mov64 r3, r8
  mov64 r4, 0x0
  mov64 r5, r0
  call sol_log_64_

jmp_9db8:
  ldxdw r5, [r10-0xc98]
  ldxdw r1, [r10-0xc68]
  ja jmp_9ba0

jmp_9dd0:
  or64 r9, r2
  ja jmp_9db8

jmp_9de0:
  lddw r1, 0x200000000
  ja jmp_9868

jmp_9df8:
  and64 r9, 0x1
  jeq r9, 0x0, jmp_9e40
  mov64 r2, r10
  add64 r2, -0xc50
  call fn_31e8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_9f40

jmp_9e40:
  ldxdw r6, [r10-0xc58]
  mov64 r1, r6
  add64 r1, 0x158
  mov64 r2, r10
  add64 r2, -0xc50
  mov64 r3, 0x570
  call fn_15658
  mov64 r1, r6
  add64 r1, 0x8
  mov64 r2, r10
  add64 r2, -0x138
  mov64 r3, 0x138
  call fn_15658
  ldxdw r1, [r10-0x148]
  stxdw [r6+0x148], r1
  ldxh r1, [r10-0x140]
  stxh [r6+0x150], r1
  ldxw r1, [r10-0x150]
  stxw [r6+0x153], r1
  ldxb r1, [r10-0x14c]
  stxb [r6+0x157], r1
  ldxdw r1, [r10-0xc88]
  stxdw [r6+0x6c8], r1
  ldxdw r1, [r10-0xc90]
  stxb [r6+0x152], r1
  ldxdw r1, [r10-0xc60]
  stxdw [r6+0x140], r1
  ldxdw r1, [r10-0xca8]
  stxw [r6+0x4], r1
  ldxdw r1, [r10-0xca0]
  stxw [r6+0x0], r1
  ja jmp_9aa8

jmp_9f40:
  ldxdw r2, [r10-0xc58]
  stxw [r2+0x0], r0
  stxw [r2+0x4], r1
  ja jmp_9878

jmp_9f60:
  mov64 r1, r3
  ldxdw r2, [r10-0xc70]
  lddw r3, data_0728
  call fn_14328

jmp_9f88:
  lddw r1, data_0710
  call fn_14350

fn_9fa0:
  mov64 r6, r1
  jle r3, 0x6, jmp_a190
  ldxdw r0, [r2+0x18]
  ldxdw r8, [r2+0x0]
  stxdw [r10-0xff0], r4
  add64 r3, -0x7
  stxdw [r10-0xff8], r3
  stxdw [r10-0xda8], r2
  mov64 r1, r2
  add64 r1, 0x38
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x6d0
  mov64 r5, r10
  mov64 r2, r6
  mov64 r3, r8
  mov64 r4, r0
  call fn_9608
  ldxw r1, [r10-0x6cc]
  ldxw r0, [r10-0x6d0]
  ldxb r7, [r10-0x57e]
  jeq r7, 0x2, jmp_a1a0
  mov64 r3, r10
  add64 r3, -0xd98
  mov64 r2, r10
  add64 r2, -0x6c8
  stxdw [r10-0xdb0], r1
  mov64 r1, r3
  mov64 r3, 0x14a
  stxdw [r10-0xdb8], r0
  call fn_15658
  mov64 r1, r10
  add64 r1, -0xc45
  mov64 r2, r10
  add64 r2, -0x57d
  mov64 r3, 0x575
  call fn_15658
  ldxdw r8, [r10-0x8]
  mov64 r9, r10
  add64 r9, -0x6d0
  mov64 r2, r10
  add64 r2, -0xc40
  mov64 r1, r9
  mov64 r3, 0x570
  call fn_15658
  stxb [r10-0xc4e], r7
  ldxdw r1, [r10-0xdb0]
  stxw [r10-0xd9c], r1
  ldxdw r1, [r10-0xdb8]
  stxw [r10-0xda0], r1
  ldxw r1, [r10-0xc45]
  stxw [r10-0xc4d], r1
  ldxb r1, [r10-0xc41]
  stxb [r10-0xc49], r1
  mov64 r4, r10
  add64 r4, -0xda0
  mov64 r1, r6
  ldxdw r2, [r10-0xda8]
  mov64 r3, r9
  mov64 r5, r8
  call fn_7278
  ja jmp_a1a0

jmp_a190:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_a1a0:
  exit

entrypoint:
  mov64 r2, r1
  add64 r2, 0x8
  ldxdw r3, [r1+0x0]
  jeq r3, 0x0, jmp_a2c0
  ldxdw r4, [r1+0x58]
  stxw [r1+0xc], r4
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2868
  add64 r1, 0x286f
  mov64 r4, 0x1
  jlt r1, r5, jmp_a210
  mov64 r4, 0x0

jmp_a210:
  stxdw [r10-0x970], r2
  and64 r4, 0x1
  jne r4, 0x0, jmp_ba68
  and64 r1, -0x8
  jeq r3, 0x1, jmp_ac78
  jne r3, 0x2, jmp_a2e0
  ldxb r2, [r1+0x0]
  jne r2, 0xff, jmp_aca8
  ldxdw r4, [r1+0x50]
  mov64 r2, r1
  add64 r2, r4
  mov64 r0, r2
  add64 r0, 0x2860
  add64 r2, 0x2867
  mov64 r5, 0x1
  jlt r2, r0, jmp_a298
  mov64 r5, 0x0

jmp_a298:
  stxw [r1+0x4], r4
  stxdw [r10-0x968], r1
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba80
  and64 r2, -0x8

jmp_a2c0:
  mov64 r1, r2
  ldxdw r8, [r1+0x0]
  jeq r8, 0x0, jmp_ac88
  ja jmp_acf0

jmp_a2e0:
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r4, r3
  jlt r3, 0x6, jmp_a728
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r4, r3

jmp_a318:
  ldxb r5, [r1+0x0]
  jne r5, 0xff, jmp_a5b8
  ldxdw r5, [r1+0x50]
  stxw [r1+0x4], r5
  stxdw [r2+0x8], r1
  ldxdw r5, [r1+0x50]
  add64 r1, r5
  mov64 r0, r1
  add64 r0, 0x2860
  add64 r1, 0x2867
  mov64 r5, 0x1
  jlt r1, r0, jmp_a380
  mov64 r5, 0x0

jmp_a380:
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba50
  and64 r1, -0x8
  ldxb r5, [r1+0x0]
  jne r5, 0xff, jmp_a600

jmp_a3a8:
  ldxdw r5, [r1+0x50]
  stxw [r1+0x4], r5
  stxdw [r2+0x10], r1
  ldxdw r5, [r1+0x50]
  add64 r1, r5
  mov64 r0, r1
  add64 r0, 0x2860
  add64 r1, 0x2867
  mov64 r5, 0x1
  jlt r1, r0, jmp_a400
  mov64 r5, 0x0

jmp_a400:
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba50
  and64 r1, -0x8
  ldxb r5, [r1+0x0]
  jne r5, 0xff, jmp_a648

jmp_a428:
  ldxdw r5, [r1+0x50]
  stxw [r1+0x4], r5
  stxdw [r2+0x18], r1
  ldxdw r5, [r1+0x50]
  add64 r1, r5
  mov64 r0, r1
  add64 r0, 0x2860
  add64 r1, 0x2867
  mov64 r5, 0x1
  jlt r1, r0, jmp_a480
  mov64 r5, 0x0

jmp_a480:
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba50
  and64 r1, -0x8
  ldxb r5, [r1+0x0]
  jne r5, 0xff, jmp_a690

jmp_a4a8:
  ldxdw r5, [r1+0x50]
  stxw [r1+0x4], r5
  stxdw [r2+0x20], r1
  ldxdw r5, [r1+0x50]
  add64 r1, r5
  mov64 r0, r1
  add64 r0, 0x2860
  add64 r1, 0x2867
  mov64 r5, 0x1
  jlt r1, r0, jmp_a500
  mov64 r5, 0x0

jmp_a500:
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba50
  and64 r1, -0x8
  add64 r2, 0x28
  ldxb r5, [r1+0x0]
  jne r5, 0xff, jmp_a6e0

jmp_a530:
  ldxdw r5, [r1+0x50]
  stxw [r1+0x4], r5
  stxdw [r2+0x0], r1
  ldxdw r5, [r1+0x50]
  add64 r1, r5
  mov64 r0, r1
  add64 r0, 0x2860
  add64 r1, 0x2867
  mov64 r5, 0x1
  jlt r1, r0, jmp_a588
  mov64 r5, 0x0

jmp_a588:
  and64 r5, 0x1
  jne r5, 0x0, jmp_ba50
  and64 r1, -0x8
  add64 r4, -0x5
  jgt r4, 0x5, jmp_a318
  ja jmp_a728

jmp_a5b8:
  lsh64 r5, 0x3
  mov64 r0, r10
  add64 r0, -0x970
  add64 r0, r5
  ldxdw r5, [r0+0x0]
  stxdw [r2+0x8], r5
  add64 r1, 0x8
  ldxb r5, [r1+0x0]
  jeq r5, 0xff, jmp_a3a8

jmp_a600:
  lsh64 r5, 0x3
  mov64 r0, r10
  add64 r0, -0x970
  add64 r0, r5
  ldxdw r5, [r0+0x0]
  stxdw [r2+0x10], r5
  add64 r1, 0x8
  ldxb r5, [r1+0x0]
  jeq r5, 0xff, jmp_a428

jmp_a648:
  lsh64 r5, 0x3
  mov64 r0, r10
  add64 r0, -0x970
  add64 r0, r5
  ldxdw r5, [r0+0x0]
  stxdw [r2+0x18], r5
  add64 r1, 0x8
  ldxb r5, [r1+0x0]
  jeq r5, 0xff, jmp_a4a8

jmp_a690:
  lsh64 r5, 0x3
  mov64 r0, r10
  add64 r0, -0x970
  add64 r0, r5
  ldxdw r5, [r0+0x0]
  stxdw [r2+0x20], r5
  add64 r1, 0x8
  add64 r2, 0x28
  ldxb r5, [r1+0x0]
  jeq r5, 0xff, jmp_a530

jmp_a6e0:
  lsh64 r5, 0x3
  mov64 r0, r10
  add64 r0, -0x970
  add64 r0, r5
  ldxdw r5, [r0+0x0]
  stxdw [r2+0x0], r5
  add64 r1, 0x8
  add64 r4, -0x5
  jgt r4, 0x5, jmp_a318

jmp_a728:
  jsle r4, 0x2, jmp_a8d0
  jeq r4, 0x3, jmp_a968
  jne r4, 0x4, jmp_aa78
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b840
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x8], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_a7a8
  mov64 r4, 0x0

jmp_a7a8:
  and64 r4, 0x1
  jne r4, 0x0, jmp_a8b8
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b888

jmp_a7d0:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x10], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_a828
  mov64 r4, 0x0

jmp_a828:
  and64 r4, 0x1
  jne r4, 0x0, jmp_a8b8
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b8d0

jmp_a850:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x18], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r4, jmp_a8a8
  mov64 r2, 0x0

jmp_a8a8:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_ac70

jmp_a8b8:
  lddw r1, data_0630
  call fn_14350

jmp_a8d0:
  jeq r4, 0x1, jmp_ac78
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_ba18
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x8], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r4, jmp_a940
  mov64 r2, 0x0

jmp_a940:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_ac70
  lddw r1, data_0660
  call fn_14350

jmp_a968:
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b7c0
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x8], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_a9d0
  mov64 r4, 0x0

jmp_a9d0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_aa60
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b808

jmp_a9f8:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x10], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r4, jmp_aa50
  mov64 r2, 0x0

jmp_aa50:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_ac70

jmp_aa60:
  lddw r1, data_0648
  call fn_14350

jmp_aa78:
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b908
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x8], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_aae0
  mov64 r4, 0x0

jmp_aae0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_ba98
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b950

jmp_ab08:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x10], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_ab60
  mov64 r4, 0x0

jmp_ab60:
  and64 r4, 0x1
  jne r4, 0x0, jmp_ba98
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b998

jmp_ab88:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x18], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_abe0
  mov64 r4, 0x0

jmp_abe0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_ba98
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_b9e0

jmp_ac08:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x20], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r4, jmp_ac60
  mov64 r2, 0x0

jmp_ac60:
  and64 r2, 0x1
  jne r2, 0x0, jmp_ba98

jmp_ac70:
  and64 r1, -0x8

jmp_ac78:
  ldxdw r8, [r1+0x0]
  jne r8, 0x0, jmp_acf0

jmp_ac88:
  mov64 r6, -0x1
  mov64 r1, 0x0
  mov64 r2, 0x1
  ja jmp_b4f8

jmp_aca8:
  lsh64 r2, 0x3
  mov64 r4, r10
  add64 r4, -0x970
  add64 r4, r2
  ldxdw r2, [r4+0x0]
  stxdw [r10-0x968], r2

jmp_acd8:
  add64 r1, 0x8
  ldxdw r8, [r1+0x0]
  jeq r8, 0x0, jmp_ac88

jmp_acf0:
  mov64 r7, r1
  add64 r7, 0x8
  mov64 r2, 0x0
  mov64 r6, 0x1
  ldxb r0, [r7+0x0]
  jsle r0, 0x2, jmp_ad80
  jsgt r0, 0x5, jmp_adf0
  jeq r0, 0x3, jmp_aeb0
  jne r0, 0x5, jmp_ae78
  jlt r8, 0x9, jmp_b4e0
  jeq r8, 0x9, jmp_b4e0
  ldxdw r2, [r1+0x9]
  stxdw [r10-0x978], r2
  ldxb r2, [r1+0x11]
  jeq r2, 0x0, jmp_b4d0
  jne r2, 0x1, jmp_b4e0
  mov64 r5, 0x1
  ja jmp_b4d8

jmp_ad80:
  jeq r0, 0x0, jmp_ae30
  jeq r0, 0x1, jmp_b100
  jne r0, 0x2, jmp_ae78
  jeq r8, 0x1, jmp_b4e0
  jlt r8, 0x3, jmp_b4e0
  ldxb r0, [r1+0x9]
  ldxb r1, [r1+0xa]
  mov64 r5, 0x0
  jeq r1, 0x0, jmp_add8
  jne r1, 0x1, jmp_b4e0
  mov64 r5, 0x1

jmp_add8:
  mov64 r9, 0x2
  mov64 r6, 0x3
  ja jmp_aea0

jmp_adf0:
  jeq r0, 0x6, jmp_aec8
  jne r0, 0x7, jmp_ae78
  jeq r8, 0x1, jmp_b4e0
  ldxb r0, [r1+0x9]
  jge r0, 0x40, jmp_b4e0
  mov64 r9, 0x5
  mov64 r6, 0x2
  ja jmp_aea0

jmp_ae30:
  jlt r8, 0x4, jmp_b4e0
  mov64 r6, 0x4
  ldxb r0, [r1+0xb]
  ldxh r5, [r1+0x9]
  mov64 r4, r5
  rsh64 r4, 0x8
  mov64 r9, 0x0
  jne r6, r8, jmp_b4e0
  ja jmp_aef8

jmp_ae78:
  add64 r0, -0xa
  mov64 r1, r0
  and64 r1, 0xff
  jge r1, 0x6, jmp_b4e0
  mov64 r9, 0x3

jmp_aea0:
  jne r6, r8, jmp_b4e0
  ja jmp_aef8

jmp_aeb0:
  mov64 r9, 0x4
  jne r6, r8, jmp_b4e0
  ja jmp_aef8

jmp_aec8:
  jlt r8, 0x9, jmp_b4e0
  mov64 r9, 0x6
  mov64 r6, 0x9
  ldxdw r1, [r1+0x9]
  stxdw [r10-0x978], r1
  jne r6, r8, jmp_b4e0

jmp_aef8:
  mov64 r1, r7
  add64 r1, r8
  ldxdw r6, [r10-0x1b]
  stxdw [r10-0x12b], r6
  ldxdw r6, [r10-0x20]
  stxdw [r10-0x130], r6
  ldxdw r6, [r10-0x28]
  stxdw [r10-0x138], r6
  ldxdw r6, [r10-0xc8]
  stxdw [r10-0x158], r6
  ldxdw r6, [r10-0xc0]
  stxdw [r10-0x150], r6
  ldxdw r6, [r10-0xb8]
  stxdw [r10-0x148], r6
  ldxb r6, [r10-0xb0]
  stxb [r10-0x140], r6
  ldxh r6, [r10-0x2c]
  stxh [r10-0x15c], r6
  ldxb r6, [r10-0x2a]
  stxb [r10-0x15a], r6
  ldxb r6, [r10-0x30]
  stxb [r10-0x160], r6
  ldxdw r6, [r10-0x38]
  stxdw [r10-0x168], r6
  ldxdw r6, [r10-0x40]
  stxdw [r10-0x170], r6
  ldxdw r6, [r10-0x48]
  stxdw [r10-0x178], r6
  ldxdw r6, [r10-0x138]
  stxdw [r10-0xe0], r6
  ldxdw r6, [r10-0x130]
  stxdw [r10-0xd8], r6
  ldxdw r6, [r10-0x12b]
  stxdw [r10-0xd3], r6
  ldxb r6, [r10-0x140]
  stxb [r10-0xe8], r6
  ldxdw r6, [r10-0x148]
  stxdw [r10-0xf0], r6
  ldxdw r6, [r10-0x150]
  stxdw [r10-0xf8], r6
  ldxdw r6, [r10-0x158]
  stxdw [r10-0x100], r6
  ldxb r6, [r10-0x15a]
  stxb [r10-0x102], r6
  ldxh r6, [r10-0x15c]
  stxh [r10-0x104], r6
  ldxb r6, [r10-0x160]
  stxb [r10-0x108], r6
  ldxdw r6, [r10-0x168]
  stxdw [r10-0x110], r6
  ldxdw r6, [r10-0x170]
  stxdw [r10-0x118], r6
  ldxdw r6, [r10-0x178]
  stxdw [r10-0x120], r6
  jsgt r9, 0x3, jmp_b1d8
  jsgt r9, 0x1, jmp_b208
  and64 r5, 0xff
  lsh64 r4, 0x8
  or64 r4, r5
  jne r9, 0x0, jmp_b268
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r5, r0
  call fn_4140
  ja jmp_b498

jmp_b100:
  jeq r8, 0x1, jmp_b4e0
  jlt r8, 0x22, jmp_b4e0
  ldxb r0, [r1+0x9]
  ldxh r5, [r1+0xa]
  ldxb r2, [r1+0xc]
  ldxw r4, [r1+0xd]
  stxw [r10-0xb], r4
  stxb [r10-0xc], r2
  ldxw r2, [r1+0x11]
  stxw [r10-0x7], r2
  ldxw r2, [r1+0x14]
  stxw [r10-0x4], r2
  jlt r8, 0x42, jmp_b4e0
  jlt r8, 0x62, jmp_b4e0
  jeq r8, 0x62, jmp_b4e0
  jlt r8, 0x64, jmp_b4e0
  ldxw r2, [r1+0x2d]
  stxdw [r10-0x988], r2
  ldxw r2, [r1+0x4d]
  stxdw [r10-0x980], r2
  ldxb r2, [r1+0x6a]
  stxdw [r10-0x990], r2
  ldxb r2, [r1+0x6b]
  jeq r2, 0x0, jmp_b600
  jne r2, 0x1, jmp_b4e0
  mov64 r2, 0x1
  ja jmp_b608

jmp_b1d8:
  jsgt r9, 0x5, jmp_b240
  jne r9, 0x4, jmp_b408
  mov64 r2, r10
  add64 r2, -0x970
  call fn_6f50
  ja jmp_b498

jmp_b208:
  jne r9, 0x2, jmp_b430
  and64 r5, 0x1
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r4, r0
  call fn_5400
  ja jmp_b498

jmp_b240:
  jne r9, 0x6, jmp_b458
  jeq r3, 0x0, jmp_b570
  mov64 r1, 0x0
  mov64 r2, 0x2
  ja jmp_b4f0

jmp_b268:
  ldxh r5, [r10-0xd0]
  stxh [r10-0xaa], r5
  ldxdw r5, [r10-0xd8]
  stxdw [r10-0xb2], r5
  ldxdw r5, [r10-0xe0]
  stxdw [r10-0xba], r5
  ldxh r5, [r10-0xce]
  stxh [r10-0xa8], r5
  ldxb r5, [r10-0xcc]
  stxb [r10-0xa6], r5
  ldxdw r5, [r10-0x988]
  stxw [r10-0xa5], r5
  ldxdw r5, [r10-0x100]
  stxdw [r10-0xa1], r5
  ldxdw r5, [r10-0xf8]
  stxdw [r10-0x99], r5
  ldxdw r5, [r10-0xf0]
  stxdw [r10-0x91], r5
  ldxb r5, [r10-0xe8]
  stxb [r10-0x89], r5
  ldxdw r5, [r10-0x980]
  stxw [r10-0x85], r5
  stxh [r10-0xc8], r4
  ldxdw r4, [r10-0x998]
  stxw [r10-0xc6], r4
  ldxdw r4, [r10-0x990]
  stxb [r10-0x50], r4
  stxb [r10-0x4f], r2
  ldxdw r2, [r10-0x978]
  stxdw [r10-0xc2], r2
  ldxb r2, [r10-0x102]
  stxb [r10-0x86], r2
  ldxh r2, [r10-0x104]
  stxh [r10-0x88], r2
  ldxdw r2, [r10-0x120]
  stxdw [r10-0x81], r2
  ldxdw r2, [r10-0x118]
  stxdw [r10-0x79], r2
  ldxdw r2, [r10-0x110]
  stxdw [r10-0x71], r2
  ldxb r2, [r10-0x108]
  stxb [r10-0x69], r2
  stdw [r10-0x58], 0x0
  stdw [r10-0x60], 0x0
  stdw [r10-0x68], 0x0
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r5, r10
  add64 r5, -0xc8
  mov64 r4, r0
  call fn_4920
  ja jmp_b498

jmp_b408:
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r4, r0
  call fn_9fa0
  ja jmp_b498

jmp_b430:
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r4, r0
  call fn_6ac8
  ja jmp_b498

jmp_b458:
  stxdw [r10-0xff8], r0
  and64 r5, 0x1
  stxdw [r10-0x1000], r5
  mov64 r2, r10
  add64 r2, -0x970
  mov64 r5, r10
  ldxdw r4, [r10-0x978]
  call fn_5e38

jmp_b498:
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r1
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_b4f0
  ja jmp_b538

jmp_b4d0:
  mov64 r5, 0x0

jmp_b4d8:
  jge r8, 0xb, jmp_b548

jmp_b4e0:
  mov64 r1, 0x0
  mov64 r2, 0x1

jmp_b4f0:
  ldxb r6, [r7+0x0]

jmp_b4f8:
  call fn_0000
  lddw r1, 0x50494b534c43524f
  mov64 r2, 0x1
  mov64 r3, r6
  mov64 r4, 0x0
  mov64 r5, r0
  call sol_log_64_

jmp_b538:
  mov64 r0, 0x0
  exit

jmp_b548:
  mov64 r9, 0x7
  mov64 r2, 0x0
  mov64 r6, 0xb
  ldxb r0, [r1+0x12]
  ja jmp_aea0

jmp_b570:
  mov64 r2, r10
  add64 r2, -0xc8
  lddw r1, data_0328
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jeq r0, 0x0, jmp_b5d0
  mov64 r1, 0x10
  jne r0, 0x1, jmp_b5c8
  mov64 r1, 0x1

jmp_b5c8:
  ja jmp_b4f0

jmp_b5d0:
  mov64 r2, 0x17
  ldxdw r3, [r10-0xc8]
  mov64 r1, 0x0
  ldxdw r4, [r10-0x978]
  jgt r3, r4, jmp_b4f0
  ja jmp_b538

jmp_b600:
  mov64 r2, 0x0

jmp_b608:
  mov64 r6, r1
  add64 r6, 0x18
  mov64 r4, r5
  rsh64 r4, 0x8
  mov64 r9, r1
  add64 r9, 0x31
  stxdw [r10-0x9a8], r9
  mov64 r9, r1
  add64 r9, 0x2a
  stxdw [r10-0x978], r9
  mov64 r9, r1
  add64 r9, 0x51
  stxdw [r10-0x9a0], r9
  add64 r1, 0x4a
  ldxh r9, [r6+0x10]
  stxh [r10-0x18], r9
  ldxdw r9, [r6+0x8]
  stxdw [r10-0x20], r9
  ldxdw r6, [r6+0x0]
  stxdw [r10-0x28], r6
  ldxdw r9, [r10-0x978]
  ldxb r6, [r9+0x2]
  stxb [r10-0x14], r6
  ldxh r6, [r9+0x0]
  stxh [r10-0x16], r6
  ldxdw r6, [r10-0x8]
  stxdw [r10-0x978], r6
  ldxw r6, [r10-0xc]
  stxdw [r10-0x998], r6
  ldxdw r9, [r10-0x9a8]
  ldxb r6, [r9+0x18]
  stxb [r10-0xb0], r6
  ldxdw r6, [r9+0x10]
  stxdw [r10-0xb8], r6
  ldxdw r6, [r9+0x8]
  stxdw [r10-0xc0], r6
  ldxdw r6, [r9+0x0]
  stxdw [r10-0xc8], r6
  ldxh r6, [r1+0x0]
  stxh [r10-0x2c], r6
  ldxb r1, [r1+0x2]
  stxb [r10-0x2a], r1
  ldxdw r6, [r10-0x9a0]
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x48], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x40], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x38], r1
  ldxb r1, [r6+0x18]
  stxb [r10-0x30], r1
  mov64 r9, 0x1
  mov64 r6, 0x64
  jne r6, r8, jmp_b4e0
  ja jmp_aef8

jmp_b7c0:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x8], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_a9f8

jmp_b808:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x10], r4
  ja jmp_acd8

jmp_b840:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x8], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_a7d0

jmp_b888:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x10], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_a850

jmp_b8d0:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x18], r4
  ja jmp_acd8

jmp_b908:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x8], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_ab08

jmp_b950:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x10], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_ab88

jmp_b998:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x18], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_ac08

jmp_b9e0:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x20], r4
  ja jmp_acd8

jmp_ba18:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0x970
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x8], r4
  ja jmp_acd8

jmp_ba50:
  lddw r1, data_0678
  call fn_14350

jmp_ba68:
  lddw r1, data_05e8
  call fn_14350

jmp_ba80:
  lddw r1, data_0600
  call fn_14350

jmp_ba98:
  lddw r1, data_0618
  call fn_14350

fn_bab0:
  ldxw r4, [r1+0x14]
  ldxw r3, [r1+0x10]
  ldxdw r5, [r1+0x0]
  ldxdw r2, [r1+0x8]
  add64 r2, -0x1
  mov64 r1, r5
  call sol_panic_

fn_bae8:
  mov64 r0, r4
  mov64 r7, r2
  ldxdw r8, [r5-0xfe8]
  ldxdw r4, [r5-0xff0]
  ldxdw r6, [r5-0xff8]
  ldxdw r2, [r5-0x1000]
  and64 r7, 0xff
  jsgt r7, 0x2, jmp_bd30
  jeq r7, 0x0, jmp_bf88
  jne r7, 0x1, jmp_c620
  jne r0, 0x4f0, jmp_c978
  ldxdw r2, [r4+0x40]
  ldxdw r5, [r3+0x18]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x48]
  ldxdw r5, [r3+0x20]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x50]
  ldxdw r5, [r3+0x28]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x58]
  ldxdw r5, [r3+0x30]
  jne r5, r2, jmp_c978
  ldxdw r2, [r3+0x38]
  lddw r5, 0x3aaddbbef37afac6
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0x40]
  lddw r5, 0x3174c9ab6af3653d
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0x48]
  lddw r5, -0x1b1f092d3d1b444f
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0x50]
  lddw r5, 0x615d2f450302a67c
  jne r2, r5, jmp_c978
  ldxdw r6, [r3+0x80]
  jeq r6, 0x0, jmp_c9f0

jmp_bc30:
  stxdw [r10-0x40], r3
  stxdw [r10-0x38], r1
  ldxb r2, [r4+0x78]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_d390
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_c9d8
  ldxdw r1, [r10-0x20]
  ldxdw r7, [r10-0x28]
  mov64 r2, 0x0
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_156e0
  mov64 r8, r0
  mov64 r9, r1
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_156e0
  mov64 r2, r1
  add64 r2, r8
  mov64 r4, 0x1
  mov64 r3, 0x1
  jne r9, 0x0, jmp_c998
  mov64 r3, 0x0
  jge r2, r1, jmp_c9a0

jmp_bd10:
  or64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_c9c0
  ja jmp_c9d8

jmp_bd30:
  jeq r7, 0x3, jmp_c228
  jne r7, 0x4, jmp_c820
  jne r0, 0x420, jmp_c978
  ldxdw r0, [r8+0x0]
  ldxdw r7, [r3+0x398]
  jne r7, r0, jmp_c978
  ldxdw r0, [r8+0x8]
  ldxdw r7, [r3+0x3a0]
  jne r7, r0, jmp_c978
  ldxdw r0, [r8+0x10]
  ldxdw r7, [r3+0x3a8]
  jne r7, r0, jmp_c978
  ldxdw r0, [r8+0x18]
  ldxdw r7, [r3+0x3b0]
  jne r7, r0, jmp_c978
  ldxdw r0, [r4+0x40]
  ldxdw r7, [r3+0x3b8]
  jne r7, r0, jmp_c978
  ldxdw r0, [r4+0x48]
  ldxdw r7, [r3+0x3c0]
  jne r7, r0, jmp_c978
  ldxdw r0, [r4+0x50]
  ldxdw r7, [r3+0x3c8]
  jne r7, r0, jmp_c978
  ldxdw r0, [r4+0x58]
  ldxdw r7, [r3+0x3d0]
  jne r7, r0, jmp_c978
  ldxdw r0, [r3+0x3f8]
  lddw r7, 0x2d3f6c1c2047dea8
  jne r0, r7, jmp_c978
  ldxdw r0, [r3+0x400]
  lddw r7, -0x536d559e531862a4
  jne r0, r7, jmp_c978
  ldxdw r0, [r3+0x408]
  lddw r7, -0x30763dafd096a703
  jne r0, r7, jmp_c978
  ldxdw r3, [r3+0x410]
  lddw r0, -0x2b4e3f294a420730
  jne r3, r0, jmp_c978
  stxdw [r10-0x38], r1
  ldxdw r8, [r5-0xfd0]
  ldxdw r7, [r5-0xfd8]
  ldxdw r9, [r5-0xfe0]
  add64 r4, 0x40
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r3, r6
  call fn_d790
  ldxw r1, [r10-0x30]
  jeq r1, 0x1, jmp_bf70
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x40], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x48], r1
  ldxdw r1, [r10-0x8]
  stxdw [r10-0x58], r1
  ldxh r1, [r10-0x10]
  stxdw [r10-0x50], r1
  ldxdw r6, [r10-0x18]
  mov64 r1, r10
  add64 r1, -0x30
  mov64 r2, r9
  mov64 r3, r7
  lddw r4, data_0348
  call fn_d790
  ldxw r1, [r10-0x30]
  jne r1, 0x1, jmp_ca30

jmp_bf70:
  ldxw r2, [r10-0x2c]
  ldxdw r1, [r10-0x38]
  ja jmp_cd90

jmp_bf88:
  jne r0, 0x800, jmp_c978
  ldxdw r2, [r3+0x0]
  lddw r5, 0x544154534c4f4f50
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0x8]
  jne r2, 0x3, jmp_c978
  ldxdw r2, [r4+0x40]
  ldxdw r5, [r3+0xb8]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x48]
  ldxdw r5, [r3+0xc0]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x50]
  ldxdw r5, [r3+0xc8]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x58]
  ldxdw r5, [r3+0xd0]
  jne r5, r2, jmp_c978
  ldxdw r2, [r3+0xd8]
  lddw r5, 0x3aaddbbef37afac6
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0xe0]
  lddw r5, 0x3174c9ab6af3653d
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0xe8]
  lddw r5, -0x1b1f092d3d1b444f
  jne r2, r5, jmp_c978
  ldxdw r2, [r3+0xf0]
  lddw r5, 0x615d2f450302a67c
  jne r2, r5, jmp_c978
  mov64 r5, 0x2
  ldxb r2, [r4+0x78]
  jlt r2, 0x6, jmp_ca20
  add64 r2, -0x6
  and64 r2, 0xff
  mov64 r6, r1
  mov64 r1, r2
  mov64 r7, r3
  call fn_d1b8
  mov64 r3, r7
  mov64 r2, r1
  mov64 r1, r6
  mov64 r5, 0x4
  and64 r0, 0x1
  jeq r0, 0x0, jmp_ca20
  ldxdw r4, [r3+0x1d0]
  mov64 r5, 0x2
  jne r4, r2, jmp_ca20
  ldxb r1, [r3+0x342]
  lsh64 r1, 0x10
  ldxh r2, [r3+0x340]
  or64 r2, r1
  ldxw r4, [r3+0x343]
  lsh64 r4, 0x18
  or64 r4, r2
  ldxdw r2, [r3+0x347]
  mov64 r1, r2
  lsh64 r1, 0x38
  or64 r1, r4
  ldxb r4, [r3+0x34f]
  lsh64 r4, 0x20
  mov64 r7, r2
  rsh64 r7, 0x20
  or64 r7, r4
  mul64 r7, 0xf4240
  rsh64 r2, 0x8
  and64 r2, 0xffffff
  mov64 r8, r3
  mov64 r3, 0xf4240
  mov64 r4, 0x0
  call fn_156e0
  mov64 r0, r7
  mov64 r2, r1
  mov64 r1, r6
  rsh64 r2, 0x18
  add64 r0, r2
  ldxdw r9, [r8+0x58]
  ldxdw r7, [r8+0x48]
  ja jmp_cde8

jmp_c228:
  jne r0, 0x270, jmp_c978
  ldxb r5, [r3+0x0]
  jne r5, 0x1, jmp_c978
  jeq r6, 0x1030, jmp_c250
  jne r6, 0x1029, jmp_c978

jmp_c250:
  ldxb r5, [r2+0x0]
  jne r5, 0x0, jmp_c978
  ldxdw r5, [r4+0x40]
  ldxdw r0, [r3+0x10]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x48]
  ldxdw r0, [r3+0x18]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x50]
  ldxdw r0, [r3+0x20]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x58]
  ldxdw r0, [r3+0x28]
  jne r0, r5, jmp_c978
  ldxb r5, [r3+0x1]
  jeq r5, 0x0, jmp_cd78
  jne r5, 0x1, jmp_cd88
  ldxb r5, [r2+0x1]
  jeq r5, 0x0, jmp_cd78
  jne r5, 0x1, jmp_cd88
  ldxh r7, [r3+0xe]
  lsh64 r7, 0x5
  mov64 r3, r7
  add64 r3, 0xda
  jgt r3, r6, jmp_c978
  mov64 r3, r7
  add64 r3, 0xe2
  jgt r3, r6, jmp_c978
  mov64 r5, r2
  add64 r5, r7
  ldxdw r9, [r5+0xd2]
  lddw r3, -0x41b988a05efe133d
  jeq r9, r3, jmp_c978
  ldxdw r0, [r2+0xf2]
  stxdw [r10-0x40], r0
  jeq r0, r3, jmp_c978
  ldxdw r3, [r5+0xda]
  stxdw [r10-0x48], r3
  jeq r3, 0x0, jmp_c978
  ldxdw r8, [r2+0xfa]
  jeq r8, 0x0, jmp_c978
  stxdw [r10-0x58], r5
  stxdw [r10-0x50], r2
  stxdw [r10-0x38], r1
  ldxb r2, [r4+0x78]
  mov64 r1, r10
  add64 r1, -0x30
  call fn_d390
  ldxdw r1, [r10-0x30]
  jne r1, 0x1, jmp_c9d8
  mov64 r1, r9
  rsh64 r1, 0x11
  lsh64 r9, 0x2f
  or64 r9, r1
  lddw r1, -0x99e20dcc4502f80
  xor64 r9, r1
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r9
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x88], r0
  mov64 r8, r1
  ldxdw r1, [r10-0x20]
  stxdw [r10-0x68], r1
  mov64 r2, 0x0
  mov64 r3, r0
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x70], r0
  stxdw [r10-0x78], r1
  ldxdw r9, [r10-0x28]
  stxdw [r10-0x60], r8
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r9
  mov64 r4, 0x0
  call fn_156e0
  mov64 r8, r0
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x88]
  mov64 r2, 0x0
  mov64 r3, r9
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x88], r0
  mov64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x78]
  jne r4, 0x0, jmp_c538
  mov64 r3, 0x0

jmp_c538:
  mov64 r4, 0x1
  ldxdw r5, [r10-0x80]
  jne r5, 0x0, jmp_c558
  mov64 r4, 0x0

jmp_c558:
  ldxdw r5, [r10-0x70]
  add64 r8, r5
  mov64 r0, 0x1
  ldxdw r5, [r10-0x68]
  jne r5, 0x0, jmp_c588
  mov64 r0, 0x0

jmp_c588:
  mov64 r5, r1
  add64 r5, r8
  mov64 r8, r5
  mov64 r5, 0x1
  ldxdw r9, [r10-0x60]
  jne r9, 0x0, jmp_c5c0
  mov64 r5, 0x0

jmp_c5c0:
  jlt r8, r1, jmp_c5d0
  mov64 r2, 0x0

jmp_c5d0:
  and64 r5, r0
  or64 r5, r4
  or64 r5, r3
  or64 r5, r2
  and64 r5, 0x1
  jne r5, 0x0, jmp_c9d8
  add64 r7, 0xea
  jle r7, r6, jmp_d060
  ldxdw r1, [r10-0x38]
  ja jmp_c978

jmp_c620:
  jne r0, 0x800, jmp_c978
  jne r6, 0x20, jmp_c978
  ldxdw r5, [r3+0x0]
  lddw r0, -0x65cda7cbcad043d0
  jne r5, r0, jmp_c978
  ldxdw r5, [r4+0x40]
  ldxdw r0, [r3+0x50]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x48]
  ldxdw r0, [r3+0x58]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x50]
  ldxdw r0, [r3+0x60]
  jne r0, r5, jmp_c978
  ldxdw r5, [r4+0x58]
  ldxdw r0, [r3+0x68]
  jne r0, r5, jmp_c978
  ldxdw r5, [r3+0x70]
  lddw r0, 0x3aaddbbef37afac6
  jne r5, r0, jmp_c978
  ldxdw r5, [r3+0x78]
  lddw r0, 0x3174c9ab6af3653d
  jne r5, r0, jmp_c978
  ldxdw r5, [r3+0x80]
  lddw r0, -0x1b1f092d3d1b444f
  jne r5, r0, jmp_c978
  ldxdw r5, [r3+0x88]
  lddw r0, 0x615d2f450302a67c
  jne r5, r0, jmp_c978
  ldxdw r5, [r8+0x0]
  ldxdw r0, [r3+0xd0]
  jne r0, r5, jmp_c978
  ldxdw r5, [r8+0x8]
  ldxdw r0, [r3+0xd8]
  jne r0, r5, jmp_c978
  ldxdw r5, [r8+0x10]
  ldxdw r0, [r3+0xe0]
  jne r0, r5, jmp_c978
  ldxdw r5, [r8+0x18]
  ldxdw r0, [r3+0xe8]
  jne r0, r5, jmp_c978
  ldxb r4, [r4+0x78]
  ldxb r5, [r3+0x7bc]
  jne r5, r4, jmp_c978
  ldxb r3, [r3+0x7bd]
  jne r3, 0x6, jmp_c978
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r2+0x0]
  mov64 r5, r4
  add64 r5, -0x1
  jge r5, r3, jmp_c978
  mov64 r0, r3
  and64 r0, r4
  xor64 r3, r4
  rsh64 r3, 0x1
  add64 r0, r3
  ldxdw r9, [r2+0x18]
  ldxw r7, [r2+0x10]
  ja jmp_cde8

jmp_c820:
  jne r0, 0x2a0, jmp_c978
  ldxb r2, [r3+0x69]
  jne r2, 0xa, jmp_c978
  ldxb r2, [r4+0x78]
  ldxb r5, [r3+0x6a]
  jne r5, r2, jmp_c978
  ldxb r2, [r3+0x6b]
  jne r2, 0x6, jmp_c978
  ldxb r2, [r3+0x6c]
  jeq r2, 0x0, jmp_c978
  ldxdw r2, [r4+0x40]
  ldxdw r5, [r3+0xf0]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x48]
  ldxdw r5, [r3+0xf8]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x50]
  ldxdw r5, [r3+0x100]
  jne r5, r2, jmp_c978
  ldxdw r2, [r4+0x58]
  ldxdw r4, [r3+0x108]
  jne r4, r2, jmp_c978
  ldxdw r2, [r3+0x110]
  lddw r4, 0x3aaddbbef37afac6
  jne r2, r4, jmp_c978
  ldxdw r2, [r3+0x118]
  lddw r4, 0x3174c9ab6af3653d
  jne r2, r4, jmp_c978
  ldxdw r2, [r3+0x120]
  lddw r4, -0x1b1f092d3d1b444f
  jne r2, r4, jmp_c978
  ldxdw r2, [r3+0x128]
  lddw r4, 0x615d2f450302a67c
  jne r2, r4, jmp_c978
  ldxdw r9, [r3+0x50]
  ldxdw r7, [r3+0x60]
  ldxdw r0, [r3+0x1a8]
  div64 r0, 0x2710
  ja jmp_cde8

jmp_c978:
  stw [r1+0x4], 0x2

jmp_c980:
  mov64 r2, 0x1

jmp_c988:
  stxw [r1+0x0], r2
  exit

jmp_c998:
  jlt r2, r1, jmp_bd10

jmp_c9a0:
  mov64 r4, 0x0
  or64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_c9d8

jmp_c9c0:
  lddw r1, 0x38d7ea4c68000
  jlt r2, r1, jmp_cda0

jmp_c9d8:
  ldxdw r1, [r10-0x38]

jmp_c9e0:
  stw [r1+0x4], 0x4
  ja jmp_c980

jmp_c9f0:
  ldxdw r2, [r3+0x70]
  jeq r2, 0x0, jmp_bc30
  ldxdw r2, [r3+0x78]
  jeq r2, 0x0, jmp_bc30

jmp_ca10:
  stw [r1+0x4], 0x19
  ja jmp_c980

jmp_ca20:
  stxw [r1+0x4], r5
  ja jmp_c980

jmp_ca30:
  ldxdw r1, [r10-0x38]
  jgt r6, r8, jmp_ce30
  ldxdw r7, [r10-0x18]
  jgt r7, r8, jmp_ce30
  ldxdw r8, [r10-0x48]
  mov64 r2, r8
  ldxdw r4, [r10-0x40]
  or64 r2, r4
  jeq r2, 0x0, jmp_ca10
  ldxdw r5, [r10-0x20]
  ldxdw r4, [r10-0x28]
  mov64 r2, r4
  or64 r2, r5
  jeq r2, 0x0, jmp_ca10
  ldxh r1, [r10-0x10]
  lsh64 r1, 0x30
  arsh64 r1, 0x30
  ldxdw r2, [r10-0x50]
  lsh64 r2, 0x30
  arsh64 r2, 0x30
  sub64 r2, r1
  mov64 r1, r2
  lsh64 r1, 0x30
  arsh64 r1, 0x30
  jne r1, r2, jmp_d188
  stxdw [r10-0x60], r5
  stxdw [r10-0x50], r4
  stxdw [r10-0x68], r6
  add64 r1, 0x6
  mov64 r6, r1
  lsh64 r6, 0x30
  arsh64 r6, 0x30
  jne r6, r1, jmp_d188
  ldxdw r9, [r10-0x8]
  mov64 r1, r6
  arsh64 r1, 0x3f
  mov64 r2, r6
  xor64 r2, r1
  sub64 r2, r1
  mov64 r1, r10
  add64 r1, -0x30
  call fn_d390
  ldxdw r1, [r10-0x30]
  jeq r1, 0x0, jmp_c9d8
  ldxdw r1, [r10-0x20]
  ldxdw r2, [r10-0x28]
  stxdw [r10-0x78], r2
  stxdw [r10-0x70], r1
  mov64 r2, 0x0
  jsle r6, -0x1, jmp_ce40
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x80], r0
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x40]
  mov64 r2, 0x0
  ldxdw r6, [r10-0x78]
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x88], r0
  stxdw [r10-0x98], r1
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_156e0
  mov64 r3, r1
  mov64 r1, 0x1
  stxdw [r10-0x78], r1
  mov64 r5, 0x1
  ldxdw r1, [r10-0x90]
  jne r1, 0x0, jmp_cc88
  mov64 r5, 0x0

jmp_cc88:
  stxdw [r10-0x48], r0
  mov64 r0, 0x1
  ldxdw r1, [r10-0x98]
  jne r1, 0x0, jmp_ccb0
  mov64 r0, 0x0

jmp_ccb0:
  ldxdw r1, [r10-0x80]
  ldxdw r4, [r10-0x88]
  add64 r4, r1
  mov64 r8, 0x1
  ldxdw r1, [r10-0x38]
  ldxdw r2, [r10-0x70]
  jne r2, 0x0, jmp_ccf0
  mov64 r8, 0x0

jmp_ccf0:
  mov64 r2, r3
  add64 r2, r4
  mov64 r6, 0x1
  ldxdw r4, [r10-0x40]
  jne r4, 0x0, jmp_cd20
  mov64 r6, 0x0

jmp_cd20:
  jlt r2, r3, jmp_cd38
  mov64 r3, 0x0
  stxdw [r10-0x78], r3

jmp_cd38:
  and64 r6, r8
  or64 r6, r0
  or64 r6, r5
  ldxdw r3, [r10-0x78]
  or64 r6, r3
  and64 r6, 0x1
  jne r6, 0x0, jmp_c9e0
  ja jmp_d000

jmp_cd78:
  mov64 r2, 0x19
  ja jmp_cd90

jmp_cd88:
  mov64 r2, 0x2

jmp_cd90:
  stxw [r1+0x4], r2
  ja jmp_c980

jmp_cda0:
  mov64 r1, r0
  lddw r3, 0x38d7ea4c68000
  mov64 r4, 0x0
  call fn_15838
  ldxdw r1, [r10-0x40]
  ldxdw r9, [r1+0x70]
  ldxdw r7, [r1+0x78]

jmp_cde0:
  ldxdw r1, [r10-0x38]

jmp_cde8:
  jeq r0, 0x0, jmp_ce20
  jeq r7, 0x0, jmp_ce20
  stxdw [r1+0x18], r9
  stxdw [r1+0x10], r7
  stxdw [r1+0x8], r0
  mov64 r2, 0x0
  ja jmp_c988

jmp_ce20:
  stw [r1+0x4], 0x5
  ja jmp_c980

jmp_ce30:
  stw [r1+0x4], 0x15
  ja jmp_c980

jmp_ce40:
  ldxdw r6, [r10-0x50]
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x80], r0
  stxdw [r10-0x90], r1
  ldxdw r1, [r10-0x60]
  mov64 r2, 0x0
  ldxdw r8, [r10-0x78]
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x88], r0
  stxdw [r10-0x98], r1
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x50], r0
  mov64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x90]
  jne r4, 0x0, jmp_cf08
  mov64 r3, 0x0

jmp_cf08:
  mov64 r5, 0x1
  ldxdw r4, [r10-0x98]
  jne r4, 0x0, jmp_cf28
  mov64 r5, 0x0

jmp_cf28:
  ldxdw r4, [r10-0x80]
  ldxdw r0, [r10-0x88]
  add64 r0, r4
  mov64 r6, 0x1
  ldxdw r4, [r10-0x70]
  jne r4, 0x0, jmp_cf60
  mov64 r6, 0x0

jmp_cf60:
  mov64 r4, r1
  add64 r4, r0
  mov64 r0, 0x1
  ldxdw r8, [r10-0x60]
  jne r8, 0x0, jmp_cf90
  mov64 r0, 0x0

jmp_cf90:
  jlt r4, r1, jmp_cfa0
  mov64 r2, 0x0

jmp_cfa0:
  and64 r0, r6
  or64 r0, r5
  or64 r0, r3
  or64 r0, r2
  and64 r0, 0x1
  ldxdw r1, [r10-0x38]
  jne r0, 0x0, jmp_c9e0
  ldxdw r1, [r10-0x50]
  or64 r1, r4
  jeq r1, 0x0, jmp_d1a0
  stxdw [r10-0x60], r4
  ldxdw r2, [r10-0x40]

jmp_d000:
  ldxdw r1, [r10-0x48]
  ldxdw r3, [r10-0x50]
  ldxdw r4, [r10-0x60]
  call fn_15838
  jne r1, 0x0, jmp_c9d8
  ldxdw r1, [r10-0x58]
  jlt r9, r1, jmp_d040
  ldxdw r9, [r10-0x58]

jmp_d040:
  ldxdw r1, [r10-0x68]
  jlt r7, r1, jmp_cde0
  ldxdw r7, [r10-0x68]
  ja jmp_cde0

jmp_d060:
  ldxdw r3, [r10-0x40]
  mov64 r1, r3
  rsh64 r1, 0x11
  lsh64 r3, 0x2f
  or64 r3, r1
  lddw r1, -0x99e20dcc4502f80
  xor64 r3, r1
  ldxdw r1, [r10-0x48]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_156e0
  mov64 r4, r1
  ldxdw r1, [r10-0x58]
  ldxdw r1, [r1+0xca]
  lddw r3, 0x19976b95796
  xor64 r1, r3
  ldxdw r2, [r10-0x50]
  ldxdw r9, [r2+0xea]
  xor64 r9, r3
  jlt r9, r1, jmp_d118
  mov64 r9, r1

jmp_d118:
  ldxdw r1, [r10-0x88]
  mov64 r2, r8
  mov64 r3, r0
  call fn_15838
  mov64 r2, r1
  ldxdw r1, [r10-0x58]
  ldxdw r1, [r1+0xe2]
  ldxdw r3, [r10-0x50]
  ldxdw r7, [r3+0x102]
  jlt r7, r1, jmp_d170
  mov64 r7, r1

jmp_d170:
  ldxdw r1, [r10-0x38]
  jne r2, 0x0, jmp_c9e0
  ja jmp_cde8

jmp_d188:
  lddw r1, data_0740
  call fn_14350

jmp_d1a0:
  lddw r1, data_0758
  call fn_14350

fn_d1b8:
  mov64 r2, r1
  mov64 r3, r2
  lsh64 r3, 0x20
  mov64 r1, 0x1
  rsh64 r3, 0x20
  jeq r3, 0x0, jmp_d360
  mov64 r4, r2
  and64 r4, 0x1
  jeq r4, 0x0, jmp_d218
  mov64 r0, 0x1
  mov64 r1, 0xa
  jeq r3, 0x1, jmp_d378

jmp_d218:
  mov64 r3, r2
  and64 r3, 0x2
  jeq r3, 0x0, jmp_d258
  mov64 r0, 0x1
  mul64 r1, 0x64
  mov64 r3, r2
  and64 r3, 0xfe
  jeq r3, 0x2, jmp_d378

jmp_d258:
  mov64 r3, r2
  and64 r3, 0x4
  jeq r3, 0x0, jmp_d298
  mov64 r0, 0x1
  mul64 r1, 0x2710
  mov64 r3, r2
  and64 r3, 0xfc
  jeq r3, 0x4, jmp_d378

jmp_d298:
  mov64 r3, r2
  and64 r3, 0x8
  jeq r3, 0x0, jmp_d2d8
  mov64 r0, 0x1
  mul64 r1, 0x5f5e100
  mov64 r3, r2
  and64 r3, 0xf8
  jeq r3, 0x8, jmp_d378

jmp_d2d8:
  mov64 r3, r2
  and64 r3, 0x10
  jeq r3, 0x0, jmp_d370
  mov64 r6, r2
  mov64 r2, 0x0
  lddw r3, 0x2386f26fc10000
  mov64 r4, 0x0
  call fn_156e0
  mov64 r2, 0x1
  jne r1, 0x0, jmp_d338
  mov64 r2, 0x0

jmp_d338:
  and64 r2, 0x1
  jne r2, 0x0, jmp_d380
  and64 r6, 0xf0
  mov64 r1, r0
  jne r6, 0x10, jmp_d370

jmp_d360:
  mov64 r0, 0x1
  ja jmp_d378

jmp_d370:
  mov64 r0, 0x0

jmp_d378:
  exit

jmp_d380:
  mov64 r0, 0x0
  ja jmp_d378

fn_d390:
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_d3f0
  mov64 r2, r7
  mov64 r8, 0x0
  and64 r2, 0x1
  jne r2, 0x0, jmp_d408
  mov64 r9, 0x1
  ja jmp_d418

jmp_d3f0:
  stdw [r6+0x10], 0x0
  stdw [r6+0x8], 0x1
  ja jmp_d770

jmp_d408:
  mov64 r9, 0xa
  jeq r1, 0x1, jmp_d760

jmp_d418:
  mov64 r1, r7
  and64 r1, 0x2
  jeq r1, 0x0, jmp_d480
  mov64 r1, r9
  mov64 r2, r8
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_156e0
  mov64 r9, r0
  mov64 r8, r1
  mov64 r1, r7
  and64 r1, 0xfffe
  jeq r1, 0x2, jmp_d760

jmp_d480:
  mov64 r1, r7
  and64 r1, 0x4
  jeq r1, 0x0, jmp_d4e8
  mov64 r1, r9
  mov64 r2, r8
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_156e0
  mov64 r9, r0
  mov64 r8, r1
  mov64 r1, r7
  and64 r1, 0xfffc
  jeq r1, 0x4, jmp_d760

jmp_d4e8:
  mov64 r1, r7
  and64 r1, 0x8
  jeq r1, 0x0, jmp_d550
  mov64 r1, r9
  mov64 r2, r8
  mov64 r3, 0x5f5e100
  mov64 r4, 0x0
  call fn_156e0
  mov64 r9, r0
  mov64 r8, r1
  mov64 r1, r7
  and64 r1, 0xfff8
  jeq r1, 0x8, jmp_d760

jmp_d550:
  mov64 r1, r7
  and64 r1, 0x10
  jeq r1, 0x0, jmp_d5c0
  mov64 r1, r9
  mov64 r2, r8
  lddw r3, 0x2386f26fc10000
  mov64 r4, 0x0
  call fn_156e0
  mov64 r9, r0
  mov64 r8, r1
  mov64 r1, r7
  and64 r1, 0xfff0
  jeq r1, 0x10, jmp_d760

jmp_d5c0:
  mov64 r1, r7
  and64 r1, 0x20
  jeq r1, 0x0, jmp_d780
  mov64 r1, r9
  mov64 r2, 0x0
  lddw r3, 0x4ee2d6d415b
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x8], r0
  stxdw [r10-0x20], r1
  mov64 r1, r8
  mov64 r2, 0x0
  lddw r3, -0x7a53107f00000000
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x18], r0
  stxdw [r10-0x10], r1
  mov64 r1, r9
  mov64 r2, 0x0
  lddw r3, -0x7a53107f00000000
  mov64 r4, 0x0
  call fn_156e0
  mov64 r9, r0
  mov64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x20]
  jne r4, 0x0, jmp_d6b8
  mov64 r3, 0x0

jmp_d6b8:
  ldxdw r4, [r10-0x8]
  ldxdw r5, [r10-0x18]
  add64 r5, r4
  mov64 r4, 0x1
  jne r8, 0x0, jmp_d6e8
  mov64 r4, 0x0

jmp_d6e8:
  mov64 r8, r1
  add64 r8, r5
  mov64 r5, 0x1
  ldxdw r0, [r10-0x10]
  jne r0, 0x0, jmp_d718
  mov64 r5, 0x0

jmp_d718:
  jlt r8, r1, jmp_d728
  mov64 r2, 0x0

jmp_d728:
  or64 r4, r5
  or64 r4, r3
  or64 r4, r2
  and64 r4, 0x1
  jne r4, 0x0, jmp_d780
  and64 r7, 0xffe0
  jne r7, 0x20, jmp_d780

jmp_d760:
  stxdw [r6+0x8], r9
  stxdw [r6+0x10], r8

jmp_d770:
  stdw [r6+0x0], 0x1

jmp_d778:
  exit

jmp_d780:
  stdw [r6+0x0], 0x0
  ja jmp_d778

fn_d790:
  jne r3, 0x80, jmp_da98
  ldxdw r3, [r4+0x0]
  ldxdw r5, [r2+0x18]
  jne r5, r3, jmp_da98
  ldxdw r3, [r4+0x8]
  ldxdw r5, [r2+0x20]
  jne r5, r3, jmp_da98
  ldxdw r3, [r4+0x10]
  ldxdw r5, [r2+0x28]
  jne r5, r3, jmp_da98
  ldxdw r3, [r4+0x18]
  ldxdw r4, [r2+0x30]
  jne r4, r3, jmp_da98
  ldxdw r3, [r2+0x38]
  lddw r4, -0x7d5b5cecd34422c3
  jne r3, r4, jmp_da98
  ldxdw r3, [r2+0x40]
  lddw r4, -0x29fc1bc418a68f49
  jne r3, r4, jmp_da98
  ldxdw r3, [r2+0x48]
  lddw r4, 0x1c0dac4d2317c26b
  jne r3, r4, jmp_da98
  ldxdw r3, [r2+0x50]
  lddw r4, 0x670a78851e26185b
  jne r3, r4, jmp_da98
  ldxdw r5, [r2+0x70]
  mov64 r4, 0x1
  lddw r0, 0x21b0f9af01c32d04
  mov64 r3, 0x1
  jne r5, r0, jmp_d950
  mov64 r3, 0x0
  ldxdw r0, [r2+0x68]
  lddw r6, -0x5a7fcfb658f55208
  mov64 r5, 0x1
  jeq r0, r6, jmp_d978

jmp_d8d8:
  ldxdw r6, [r2+0x58]
  lddw r7, 0x6f8b6ff594e5e165
  mov64 r0, 0x1
  jne r6, r7, jmp_d9a8

jmp_d900:
  mov64 r0, 0x0
  ldxdw r6, [r2+0x60]
  lddw r7, -0x95251a1d19c1bcf
  jeq r6, r7, jmp_d9c8

jmp_d928:
  or64 r0, r4
  or64 r0, r5
  or64 r0, r3
  jne r0, 0x1, jmp_d9f0
  ja jmp_da98

jmp_d950:
  ldxdw r0, [r2+0x68]
  lddw r6, -0x5a7fcfb658f55208
  mov64 r5, 0x1
  jne r0, r6, jmp_d8d8

jmp_d978:
  mov64 r5, 0x0
  ldxdw r6, [r2+0x58]
  lddw r7, 0x6f8b6ff594e5e165
  mov64 r0, 0x1
  jeq r6, r7, jmp_d900

jmp_d9a8:
  ldxdw r6, [r2+0x60]
  lddw r7, -0x95251a1d19c1bcf
  jne r6, r7, jmp_d928

jmp_d9c8:
  mov64 r4, 0x0
  or64 r0, r4
  or64 r0, r5
  or64 r0, r3
  jeq r0, 0x1, jmp_da98

jmp_d9f0:
  ldxdw r3, [r2+0x10]
  jeq r3, 0x0, jmp_da98
  ldxdw r4, [r2+0x0]
  jeq r4, 0x0, jmp_dac8

jmp_da10:
  mov64 r5, r4
  and64 r5, 0xfffffff
  mov64 r0, r4
  rsh64 r0, 0x1c
  and64 r0, 0xfffffff
  mov64 r6, r5
  add64 r6, -0x1
  jge r6, r0, jmp_dab8
  add64 r0, r5
  ldxdw r2, [r2+0x8]
  stxdw [r1+0x8], r0
  stxdw [r1+0x28], r3
  arsh64 r4, 0x38
  stxh [r1+0x20], r4
  stxdw [r1+0x18], r2
  stdw [r1+0x10], 0x0
  ja jmp_db00

jmp_da98:
  stw [r1+0x4], 0x2

jmp_daa0:
  mov64 r2, 0x1

jmp_daa8:
  stxw [r1+0x0], r2
  exit

jmp_dab8:
  stw [r1+0x4], 0x5
  ja jmp_daa0

jmp_dac8:
  ldxdw r5, [r2+0x8]
  jeq r5, 0x0, jmp_da10
  stxdw [r1+0x28], r3
  stxdw [r1+0x18], r5
  stdw [r1+0x10], 0x0
  stdw [r1+0x8], 0x0
  sth [r1+0x20], 0x0

jmp_db00:
  mov64 r2, 0x0
  ja jmp_daa8

fn_db10:
  mov64 r0, 0x2
  jne r2, 0x270, jmp_dbf8
  ldxb r2, [r1+0x0]
  jne r2, 0x1, jmp_dbf8
  ldxh r2, [r1+0xe]
  jne r2, 0x1, jmp_dbf8
  ldxdw r2, [r1+0x10]
  lddw r3, 0x3aaddbbef37afac6
  jne r2, r3, jmp_dbf8
  ldxdw r2, [r1+0x18]
  lddw r3, 0x3174c9ab6af3653d
  jne r2, r3, jmp_dbf8
  ldxdw r2, [r1+0x20]
  lddw r3, -0x1b1f092d3d1b444f
  jne r2, r3, jmp_dbf8
  ldxdw r2, [r1+0x28]
  lddw r3, 0x615d2f450302a67c
  jne r2, r3, jmp_dbf8
  ldxb r1, [r1+0x1]
  mov64 r2, 0x19
  jeq r1, 0x0, jmp_dbe0
  mov64 r2, 0x2

jmp_dbe0:
  mov64 r0, 0x0
  jeq r1, 0x1, jmp_dbf8
  mov64 r0, r2

jmp_dbf8:
  exit

fn_dc00:
  mov64 r6, r1
  and64 r2, 0xffff
  jeq r2, 0x0, jmp_dc98
  jeq r2, 0x1, jmp_dc68
  jne r2, 0x2, jmp_dd28
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, str_053f
  mov64 r3, 0x2b
  call fn_14418
  mov64 r1, 0x9
  ja jmp_dcd0

jmp_dc68:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, str_0513
  mov64 r3, 0x2c
  ja jmp_dcc0

jmp_dc98:
  mov64 r1, r10
  add64 r1, -0x20
  lddw r2, str_04e8
  mov64 r3, 0x2b

jmp_dcc0:
  call fn_14418
  mov64 r1, 0x8

jmp_dcd0:
  ldxdw r2, [r10-0x8]
  stxdw [r6+0x19], r2
  ldxdw r2, [r10-0x10]
  stxdw [r6+0x11], r2
  ldxdw r2, [r10-0x18]
  stxdw [r6+0x9], r2
  ldxdw r2, [r10-0x20]
  stxdw [r6+0x1], r2
  stxb [r6+0x21], r1
  mov64 r1, 0x0
  ja jmp_dd38

jmp_dd28:
  stw [r6+0x4], 0x8
  mov64 r1, 0x1

jmp_dd38:
  stxb [r6+0x0], r1
  exit

fn_dd48:
  mov64 r0, 0x1
  ldxb r3, [r1+0x0]
  mov64 r4, 0x18
  rsh64 r4, r3
  and64 r4, 0x1
  jeq r4, 0x0, jmp_e4e8
  jsgt r3, 0x17, jmp_ddb8
  jsgt r3, 0xb, jmp_de30
  jsgt r3, 0x5, jmp_de90
  jsgt r3, 0x2, jmp_df30
  jeq r3, 0x0, jmp_e038
  jne r3, 0x1, jmp_e218
  stb [r2+0x0], 0x0
  ja jmp_e410

jmp_ddb8:
  jsgt r3, 0x23, jmp_de60
  jsgt r3, 0x1d, jmp_deb8
  jsgt r3, 0x1a, jmp_df50
  jeq r3, 0x18, jmp_e058
  jne r3, 0x19, jmp_e248
  stb [r2+0x0], 0xa
  ldxdw r3, [r1+0x1]
  stxdw [r2+0x1], r3
  ldxdw r3, [r1+0x9]
  stxdw [r2+0x9], r3
  ldxdw r3, [r1+0x11]
  stxdw [r2+0x11], r3
  ldxdw r1, [r1+0x19]
  stxdw [r2+0x19], r1
  ja jmp_e4e0

jmp_de30:
  jsgt r3, 0x11, jmp_dee0
  jsgt r3, 0xe, jmp_df70
  jeq r3, 0xc, jmp_e068
  jne r3, 0xd, jmp_e258
  stb [r2+0x0], 0x2b
  ja jmp_e0b0

jmp_de60:
  jsgt r3, 0x29, jmp_df08
  jsgt r3, 0x26, jmp_df90
  jeq r3, 0x24, jmp_e078
  jne r3, 0x25, jmp_e268
  stb [r2+0x0], 0x13
  ja jmp_e4e0

jmp_de90:
  jsgt r3, 0x8, jmp_dfb0
  jeq r3, 0x6, jmp_e088
  jne r3, 0x7, jmp_e278
  stb [r2+0x0], 0x2a
  ja jmp_e0b0

jmp_deb8:
  jsgt r3, 0x20, jmp_dfd0
  jeq r3, 0x1e, jmp_e098
  jne r3, 0x1f, jmp_e288
  stb [r2+0x0], 0x10
  ja jmp_e4d0

jmp_dee0:
  jsgt r3, 0x14, jmp_dff0
  jeq r3, 0x12, jmp_e0a8
  jne r3, 0x13, jmp_e298
  stb [r2+0x0], 0x1b
  ja jmp_e0b0

jmp_df08:
  jsgt r3, 0x2c, jmp_e010
  jeq r3, 0x2a, jmp_e0d8
  jne r3, 0x2b, jmp_e2d8
  stb [r2+0x0], 0x1d
  ja jmp_e1d0

jmp_df30:
  jeq r3, 0x3, jmp_e118
  jne r3, 0x4, jmp_e308
  stb [r2+0x0], 0x1f
  ja jmp_e120

jmp_df50:
  jeq r3, 0x1b, jmp_e178
  jne r3, 0x1c, jmp_e328
  stb [r2+0x0], 0xd
  ja jmp_e4e0

jmp_df70:
  jeq r3, 0xf, jmp_e188
  jne r3, 0x10, jmp_e380
  stb [r2+0x0], 0x5
  ja jmp_e4d0

jmp_df90:
  jeq r3, 0x27, jmp_e1b8
  jne r3, 0x28, jmp_e408
  stb [r2+0x0], 0x16
  ja jmp_e4e0

jmp_dfb0:
  jeq r3, 0x9, jmp_e1c8
  jne r3, 0xa, jmp_e450
  stb [r2+0x0], 0x26
  ja jmp_e1d0

jmp_dfd0:
  jeq r3, 0x21, jmp_e1e8
  jne r3, 0x22, jmp_e4a8
  stb [r2+0x0], 0x1c
  ja jmp_e4e0

jmp_dff0:
  jeq r3, 0x15, jmp_e1f8
  jne r3, 0x16, jmp_e4b8
  stb [r2+0x0], 0x2e
  ja jmp_e0b0

jmp_e010:
  jeq r3, 0x2d, jmp_e208
  jne r3, 0x2e, jmp_e4c8
  stb [r2+0x0], 0x28
  mov64 r0, 0x2
  ja jmp_e4e8

jmp_e038:
  stb [r2+0x0], 0x29
  ldxh r1, [r1+0x2]
  stxh [r2+0x1], r1
  ja jmp_e4e0

jmp_e058:
  stb [r2+0x0], 0x9
  ja jmp_e4e0

jmp_e068:
  stb [r2+0x0], 0x4
  ja jmp_e4d0

jmp_e078:
  stb [r2+0x0], 0x12
  ja jmp_e4e0

jmp_e088:
  stb [r2+0x0], 0x21
  ja jmp_e0b0

jmp_e098:
  stb [r2+0x0], 0xf
  ja jmp_e4d0

jmp_e0a8:
  stb [r2+0x0], 0x7

jmp_e0b0:
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x1], r3
  ldxdw r1, [r1+0x10]
  stxdw [r2+0x9], r1
  ja jmp_e4e0

jmp_e0d8:
  stb [r2+0x0], 0x18
  ldxh r3, [r1+0x2]
  stxh [r2+0x1], r3
  ldxh r3, [r1+0x4]
  stxh [r2+0x3], r3
  ldxdw r1, [r1+0x8]
  stxdw [r2+0x5], r1
  ja jmp_e4e0

jmp_e118:
  stb [r2+0x0], 0x2

jmp_e120:
  ldxh r3, [r1+0x2]
  stxh [r2+0x1], r3
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x3], r3
  ldxdw r3, [r1+0x10]
  stxdw [r2+0xb], r3
  ldxdw r3, [r1+0x18]
  stxdw [r2+0x13], r3
  ldxdw r1, [r1+0x20]
  stxdw [r2+0x1b], r1
  ja jmp_e4e0

jmp_e178:
  stb [r2+0x0], 0xc
  ja jmp_e310

jmp_e188:
  stb [r2+0x0], 0x25
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x1], r3
  ldxh r1, [r1+0x2]
  stxh [r2+0x9], r1
  ja jmp_e4e0

jmp_e1b8:
  stb [r2+0x0], 0x15
  ja jmp_e4e0

jmp_e1c8:
  stb [r2+0x0], 0x2c

jmp_e1d0:
  ldxw r1, [r1+0x4]
  stxw [r2+0x1], r1
  ja jmp_e4e0

jmp_e1e8:
  stb [r2+0x0], 0x1a
  ja jmp_e4e0

jmp_e1f8:
  stb [r2+0x0], 0x2f
  ja jmp_e310

jmp_e208:
  stb [r2+0x0], 0x1e
  ja jmp_e4d0

jmp_e218:
  stb [r2+0x0], 0x1
  ldxh r3, [r1+0x2]
  stxh [r2+0x1], r3
  ldxh r1, [r1+0x4]
  stxh [r2+0x3], r1
  ja jmp_e4e0

jmp_e248:
  stb [r2+0x0], 0xb
  ja jmp_e4e0

jmp_e258:
  stb [r2+0x0], 0x24
  ja jmp_e4d0

jmp_e268:
  stb [r2+0x0], 0x14
  ja jmp_e4e0

jmp_e278:
  stb [r2+0x0], 0x23
  ja jmp_e4d0

jmp_e288:
  stb [r2+0x0], 0x11
  ja jmp_e4e0

jmp_e298:
  stb [r2+0x0], 0x2d
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x1], r3
  ldxdw r3, [r1+0x10]
  stxdw [r2+0x9], r3
  ldxdw r1, [r1+0x18]
  stxdw [r2+0x11], r1
  ja jmp_e4e0

jmp_e2d8:
  stb [r2+0x0], 0x31
  ldxh r3, [r1+0x2]
  stxh [r2+0x1], r3
  ldxw r1, [r1+0x4]
  stxw [r2+0x3], r1
  ja jmp_e4e0

jmp_e308:
  stb [r2+0x0], 0x20

jmp_e310:
  ldxb r1, [r1+0x1]
  stxb [r2+0x1], r1
  ja jmp_e4e0

jmp_e328:
  stb [r2+0x0], 0xe
  ldxdw r3, [r1+0x18]
  ldxdw r4, [r1+0x20]
  stxdw [r2+0x9], r4
  stxdw [r2+0x1], r3
  ldxdw r3, [r1+0x28]
  ldxdw r1, [r1+0x30]
  stxdw [r2+0x19], r1
  stxdw [r2+0x11], r3
  mov64 r0, 0x2
  ja jmp_e4e8

jmp_e380:
  stb [r2+0x0], 0x6
  ldxh r3, [r1+0x4]
  stxh [r2+0x1], r3
  ldxdw r3, [r1+0x18]
  stxdw [r2+0x3], r3
  ldxh r3, [r1+0x6]
  stxh [r2+0xb], r3
  ldxb r3, [r1+0x2]
  stxb [r2+0xd], r3
  ldxb r3, [r1+0x3]
  stxb [r2+0xe], r3
  ldxdw r3, [r1+0x20]
  stxdw [r2+0xf], r3
  ldxdw r1, [r1+0x28]
  stxdw [r2+0x17], r1
  mov64 r0, 0x2
  ja jmp_e4e8

jmp_e408:
  stb [r2+0x0], 0x17

jmp_e410:
  ldxdw r3, [r1+0x1]
  stxdw [r2+0x1], r3
  ldxdw r3, [r1+0x9]
  stxdw [r2+0x9], r3
  ldxdw r3, [r1+0x11]
  stxdw [r2+0x11], r3
  ldxdw r1, [r1+0x19]
  ja jmp_e490

jmp_e450:
  stb [r2+0x0], 0x3
  ldxdw r3, [r1+0x11]
  stxdw [r2+0x1], r3
  ldxdw r3, [r1+0x19]
  stxdw [r2+0x9], r3
  ldxdw r3, [r1+0x21]
  stxdw [r2+0x11], r3
  ldxdw r1, [r1+0x29]

jmp_e490:
  stxdw [r2+0x19], r1
  mov64 r0, 0x2
  ja jmp_e4e8

jmp_e4a8:
  stb [r2+0x0], 0x19
  ja jmp_e4e0

jmp_e4b8:
  stb [r2+0x0], 0x8
  ja jmp_e4e0

jmp_e4c8:
  stb [r2+0x0], 0x27

jmp_e4d0:
  ldxdw r1, [r1+0x8]
  stxdw [r2+0x1], r1

jmp_e4e0:
  mov64 r0, 0x0

jmp_e4e8:
  exit

fn_e4f0:
  mov64 r0, 0x2
  ldxdw r3, [r2+0x10]
  jgt r3, -0x21, jmp_e7e8
  ldxdw r5, [r2+0x8]
  mov64 r7, r3
  add64 r7, 0x20
  jgt r7, r5, jmp_e7e8
  ldxdw r4, [r2+0x0]
  mov64 r6, r4
  add64 r6, r3
  ldxdw r8, [r1+0x18]
  stxdw [r6+0x18], r8
  ldxdw r8, [r1+0x10]
  stxdw [r6+0x10], r8
  ldxdw r8, [r1+0x8]
  stxdw [r6+0x8], r8
  ldxdw r8, [r1+0x0]
  stxdw [r6+0x0], r8
  stxdw [r2+0x10], r7
  jgt r3, -0x41, jmp_e7e8
  mov64 r6, r3
  add64 r6, 0x40
  jgt r6, r5, jmp_e7e8
  mov64 r8, r1
  add64 r8, 0x20
  mov64 r9, r4
  add64 r9, r7
  ldxdw r7, [r8+0x18]
  stxdw [r9+0x18], r7
  ldxdw r7, [r8+0x10]
  stxdw [r9+0x10], r7
  ldxdw r7, [r8+0x8]
  stxdw [r9+0x8], r7
  ldxdw r7, [r8+0x0]
  stxdw [r9+0x0], r7
  stxdw [r2+0x10], r6
  jgt r3, -0x61, jmp_e7e8
  mov64 r7, r3
  add64 r7, 0x60
  jgt r7, r5, jmp_e7e8
  mov64 r8, r1
  add64 r8, 0x40
  mov64 r9, r4
  add64 r9, r6
  ldxdw r6, [r8+0x18]
  stxdw [r9+0x18], r6
  ldxdw r6, [r8+0x10]
  stxdw [r9+0x10], r6
  ldxdw r6, [r8+0x8]
  stxdw [r9+0x8], r6
  ldxdw r6, [r8+0x0]
  stxdw [r9+0x0], r6
  stxdw [r2+0x10], r7
  jge r7, r5, jmp_e7e8
  ldxb r6, [r1+0x78]
  mov64 r8, r4
  add64 r8, r7
  stxb [r8+0x0], r6
  mov64 r6, r3
  add64 r6, 0x61
  stxdw [r2+0x10], r6
  jge r6, r5, jmp_e7e8
  ldxb r7, [r1+0x79]
  mov64 r8, r4
  add64 r8, r6
  stxb [r8+0x0], r7
  mov64 r6, r3
  add64 r6, 0x62
  stxdw [r2+0x10], r6
  jgt r3, -0x6b, jmp_e7e8
  mov64 r7, r3
  add64 r7, 0x6a
  jgt r7, r5, jmp_e7e8
  ldxdw r8, [r1+0x60]
  mov64 r9, r4
  add64 r9, r6
  stxdw [r9+0x0], r8
  stxdw [r2+0x10], r7
  jgt r3, -0x73, jmp_e7e8
  mov64 r6, r3
  add64 r6, 0x72
  jgt r6, r5, jmp_e7e8
  ldxdw r8, [r1+0x68]
  mov64 r9, r4
  add64 r9, r7
  stxdw [r9+0x0], r8
  stxdw [r2+0x10], r6
  jgt r3, -0x7b, jmp_e7e8
  add64 r3, 0x7a
  jgt r3, r5, jmp_e7e8
  ldxdw r1, [r1+0x70]
  add64 r4, r6
  stxdw [r4+0x0], r1
  stxdw [r2+0x10], r3
  mov64 r0, 0x0

jmp_e7e8:
  exit

fn_e7f0:
  stxdw [r10-0xb00], r1
  jne r3, 0x53a, jmp_e888
  ldxdw r1, [r2+0x0]
  lddw r3, 0x3130444545465443
  jne r1, r3, jmp_e8a8
  ldxb r3, [r2+0x4a]
  ldxh r4, [r2+0x48]
  ldxw r5, [r2+0x2b]
  ldxw r0, [r2+0xb]
  ldxb r1, [r2+0x4b]
  jeq r1, 0x0, jmp_e8c8
  jne r1, 0x1, jmp_f0c8
  stxdw [r10-0xae8], r0
  stxdw [r10-0xac0], r5
  stxdw [r10-0xab0], r4
  stxdw [r10-0xaa8], r3
  mov64 r1, 0x1
  ja jmp_e8f0

jmp_e888:
  ldxdw r1, [r10-0xb00]
  stb [r1+0x56d], 0x2
  stw [r1+0x0], 0x2
  ja jmp_f110

jmp_e8a8:
  ldxdw r1, [r10-0xb00]
  stb [r1+0x56d], 0x2
  stw [r1+0x0], 0x13
  ja jmp_f110

jmp_e8c8:
  stxdw [r10-0xae8], r0
  stxdw [r10-0xac0], r5
  stxdw [r10-0xab0], r4
  stxdw [r10-0xaa8], r3
  mov64 r1, 0x0

jmp_e8f0:
  stxdw [r10-0xab8], r1
  mov64 r8, r2
  add64 r8, 0x2f
  mov64 r7, r2
  add64 r7, 0x28
  mov64 r9, r2
  add64 r9, 0xf
  mov64 r6, r2
  add64 r6, 0x8
  ldxh r1, [r2+0x74]
  stxdw [r10-0xac8], r1
  ldxdw r1, [r2+0x6c]
  stxdw [r10-0xad0], r1
  ldxdw r1, [r2+0x64]
  stxdw [r10-0xae0], r1
  ldxdw r1, [r2+0x5c]
  stxdw [r10-0xaf0], r1
  ldxdw r1, [r2+0x54]
  stxdw [r10-0xaf8], r1
  ldxdw r1, [r2+0x4c]
  stxdw [r10-0xb08], r1
  mov64 r1, r10
  add64 r1, -0x500
  stxdw [r10-0xad8], r1
  stxdw [r10-0xaa0], r2
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x480
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x400
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x380
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x300
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x280
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x200
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x180
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x100
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  mov64 r1, r10
  add64 r1, -0x80
  mov64 r2, 0x0
  mov64 r3, 0x7a
  call fn_15678
  ldxh r1, [r6+0x0]
  ldxb r2, [r6+0x2]
  ldxdw r3, [r10-0xae8]
  stxw [r10-0xa95], r3
  stxb [r10-0xa96], r2
  stxh [r10-0xa98], r1
  ldxdw r1, [r9+0x8]
  stxdw [r10-0xa89], r1
  ldxdw r1, [r9+0x0]
  stxdw [r10-0xa91], r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0xa81], r1
  ldxb r1, [r9+0x18]
  stxb [r10-0xa79], r1
  ldxh r1, [r7+0x0]
  ldxb r2, [r7+0x2]
  ldxdw r3, [r10-0xac0]
  stxw [r10-0xa75], r3
  stxb [r10-0xa76], r2
  stxh [r10-0xa78], r1
  ldxb r1, [r8+0x18]
  stxb [r10-0xa59], r1
  ldxdw r1, [r8+0x10]
  stxdw [r10-0xa61], r1
  ldxdw r1, [r8+0x8]
  stxdw [r10-0xa69], r1
  ldxdw r1, [r8+0x0]
  stxdw [r10-0xa71], r1
  ldxdw r1, [r10-0xb08]
  stxdw [r10-0xa58], r1
  ldxdw r1, [r10-0xaf8]
  stxdw [r10-0xa50], r1
  ldxdw r1, [r10-0xaf0]
  stxdw [r10-0xa48], r1
  ldxdw r1, [r10-0xae0]
  stxdw [r10-0xa40], r1
  ldxdw r1, [r10-0xad0]
  stxdw [r10-0xa38], r1
  ldxdw r1, [r10-0xac8]
  stxh [r10-0x52e], r1
  ldxdw r1, [r10-0xab0]
  stxh [r10-0x530], r1
  ldxdw r1, [r10-0xaa8]
  stxb [r10-0x52c], r1
  ldxdw r1, [r10-0xab8]
  stxb [r10-0x52b], r1
  mov64 r1, r10
  add64 r1, -0xa30
  ldxdw r2, [r10-0xad8]
  mov64 r3, 0x500
  call fn_15658
  ldxdw r2, [r10-0xaa0]
  mov64 r3, 0x68
  mov64 r1, r10
  add64 r1, -0x504
  stxdw [r10-0xae8], r1
  mov64 r1, r10
  add64 r1, -0x51d
  stxdw [r10-0xaf0], r1
  mov64 r1, r10
  add64 r1, -0x524
  stxdw [r10-0xaf8], r1
  add64 r2, 0xe8
  ja jmp_f068

jmp_ed38:
  stxdw [r10-0xaa8], r5
  add64 r6, r3
  stxdw [r10-0xaa0], r4
  mov64 r4, r2
  add64 r4, -0x2b
  mov64 r9, r2
  add64 r9, -0x32
  stxdw [r10-0xad8], r8
  mov64 r8, r2
  add64 r8, -0x4b
  mov64 r1, r2
  add64 r1, -0x52
  mov64 r5, r2
  add64 r5, -0x6b
  stxdw [r10-0xad0], r7
  mov64 r7, r2
  add64 r7, -0x72
  stxdw [r10-0xac8], r0
  ldxh r0, [r7+0x0]
  stxdw [r10-0xae0], r0
  ldxb r7, [r7+0x2]
  ldxdw r0, [r2-0x10]
  stxdw [r10-0xab0], r0
  ldxdw r0, [r2-0x8]
  stxdw [r10-0xab8], r0
  ldxdw r0, [r2+0x0]
  stxdw [r10-0xac0], r0
  ldxdw r0, [r10-0xad8]
  stxw [r10-0x525], r0
  stxb [r10-0x526], r7
  ldxdw r0, [r10-0xae0]
  stxh [r10-0x528], r0
  ldxdw r7, [r10-0xaf8]
  ldxb r0, [r7+0x2]
  stxb [r10-0x51e], r0
  ldxh r0, [r7+0x0]
  stxh [r10-0x520], r0
  ldxb r0, [r5+0x18]
  ldxw r7, [r10-0x528]
  stxdw [r10-0xad8], r7
  mov64 r7, r3
  ldxdw r3, [r10-0xaf0]
  stxb [r3+0x18], r0
  ldxdw r0, [r5+0x10]
  stxdw [r3+0x10], r0
  ldxdw r0, [r5+0x8]
  stxdw [r3+0x8], r0
  ldxdw r5, [r5+0x0]
  stxdw [r3+0x0], r5
  mov64 r3, r7
  ldxb r5, [r1+0x2]
  ldxdw r0, [r10-0xae8]
  stxb [r0+0x2], r5
  ldxh r1, [r1+0x0]
  stxh [r0+0x0], r1
  ldxdw r1, [r10-0xad8]
  stxw [r6+0x0], r1
  ldxdw r1, [r10-0x520]
  stxdw [r6+0x4], r1
  ldxdw r1, [r10-0x518]
  stxdw [r6+0xc], r1
  ldxdw r1, [r10-0x510]
  stxdw [r6+0x14], r1
  ldxdw r1, [r10-0x509]
  stxdw [r6+0x1b], r1
  ldxdw r1, [r10-0xad0]
  stxw [r6+0x23], r1
  ldxdw r1, [r8+0x0]
  stxdw [r6+0x27], r1
  ldxdw r1, [r8+0x8]
  stxdw [r6+0x2f], r1
  ldxdw r1, [r8+0x10]
  stxdw [r6+0x37], r1
  ldxb r1, [r8+0x18]
  stxb [r6+0x3f], r1
  ldxh r1, [r9+0x0]
  stxh [r6+0x40], r1
  ldxb r1, [r9+0x2]
  stxb [r6+0x42], r1
  ldxdw r1, [r10-0xac8]
  stxw [r6+0x43], r1
  ldxdw r1, [r4+0x0]
  stxdw [r6+0x47], r1
  ldxdw r1, [r4+0x8]
  stxdw [r6+0x4f], r1
  ldxdw r1, [r4+0x10]
  stxdw [r6+0x57], r1
  ldxb r1, [r4+0x18]
  stxb [r6+0x5f], r1
  ldxdw r1, [r10-0xaa0]
  stxb [r6+0x78], r1
  ldxdw r1, [r10-0xaa8]
  stxb [r6+0x79], r1
  ldxdw r1, [r10-0xac0]
  stxdw [r6+0x70], r1
  ldxdw r1, [r10-0xab8]
  stxdw [r6+0x68], r1
  ldxdw r1, [r10-0xab0]
  stxdw [r6+0x60], r1
  add64 r2, 0x7a
  add64 r3, 0x80
  jeq r3, 0x568, jmp_f0e8

jmp_f068:
  mov64 r6, r10
  add64 r6, -0xa98
  ldxb r4, [r2-0x12]
  ldxw r0, [r2-0x2f]
  ldxw r7, [r2-0x4f]
  ldxw r8, [r2-0x6f]
  ldxb r1, [r2-0x11]
  mov64 r5, 0x0
  jeq r1, 0x0, jmp_ed38
  jne r1, 0x1, jmp_f0c8
  mov64 r5, 0x1
  ja jmp_ed38

jmp_f0c8:
  ldxdw r1, [r10-0xb00]
  stb [r1+0x56d], 0x2
  stw [r1+0x0], 0x1
  ja jmp_f110

jmp_f0e8:
  mov64 r2, r10
  add64 r2, -0xa98
  ldxdw r1, [r10-0xb00]
  mov64 r3, 0x570
  call fn_15658

jmp_f110:
  exit

fn_f118:
  mov64 r6, r1
  mov64 r0, 0x2
  jne r3, 0x53a, jmp_f848
  stxdw [r10-0x18], r2
  stdw [r10-0x10], 0x53a
  lddw r1, 0x3130444545465443
  stxdw [r2+0x0], r1
  ldxdw r1, [r6+0x18]
  stxdw [r2+0x20], r1
  ldxdw r1, [r6+0x10]
  stxdw [r2+0x18], r1
  ldxdw r1, [r6+0x8]
  stxdw [r2+0x10], r1
  ldxdw r1, [r6+0x0]
  stxdw [r2+0x8], r1
  ldxdw r1, [r6+0x20]
  stxdw [r2+0x28], r1
  ldxdw r1, [r6+0x28]
  stxdw [r2+0x30], r1
  ldxdw r1, [r6+0x30]
  stxdw [r2+0x38], r1
  ldxdw r1, [r6+0x38]
  stxdw [r2+0x40], r1
  ldxh r1, [r6+0x568]
  stxh [r2+0x48], r1
  ldxb r1, [r6+0x56c]
  stxb [r2+0x4a], r1
  ldxb r1, [r6+0x56d]
  stxb [r2+0x4b], r1
  ldxdw r1, [r6+0x40]
  stxdw [r2+0x4c], r1
  ldxdw r1, [r6+0x48]
  stxdw [r2+0x54], r1
  ldxdw r1, [r6+0x50]
  stxdw [r2+0x5c], r1
  ldxdw r1, [r6+0x58]
  stxdw [r2+0x64], r1
  ldxdw r1, [r6+0x60]
  stxdw [r2+0x6c], r1
  ldxh r1, [r6+0x56a]
  stxh [r2+0x74], r1
  ldxdw r1, [r6+0x80]
  stxdw [r2+0x8e], r1
  ldxdw r1, [r6+0x78]
  stxdw [r2+0x86], r1
  ldxdw r1, [r6+0x70]
  stxdw [r2+0x7e], r1
  ldxdw r1, [r6+0x68]
  stxdw [r2+0x76], r1
  ldxdw r1, [r6+0xa0]
  stxdw [r2+0xae], r1
  ldxdw r1, [r6+0x98]
  stxdw [r2+0xa6], r1
  ldxdw r1, [r6+0x90]
  stxdw [r2+0x9e], r1
  ldxdw r1, [r6+0x88]
  stxdw [r2+0x96], r1
  ldxdw r1, [r6+0xb8]
  stxdw [r2+0xc6], r1
  ldxdw r1, [r6+0xa8]
  stxdw [r2+0xb6], r1
  ldxdw r1, [r6+0xb0]
  stxdw [r2+0xbe], r1
  ldxdw r1, [r6+0xc0]
  stxdw [r2+0xce], r1
  ldxb r1, [r6+0xe0]
  stxb [r2+0xd6], r1
  stdw [r10-0x8], 0xd7
  ldxb r1, [r6+0xe1]
  stxb [r2+0xd7], r1
  ldxdw r1, [r6+0xc8]
  stxdw [r2+0xd8], r1
  ldxdw r1, [r6+0xd0]
  stxdw [r2+0xe0], r1
  ldxdw r1, [r6+0xd8]
  stxdw [r2+0xe8], r1
  ldxdw r1, [r6+0x100]
  stxdw [r2+0x108], r1
  ldxdw r1, [r6+0xf8]
  stxdw [r2+0x100], r1
  ldxdw r1, [r6+0xf0]
  stxdw [r2+0xf8], r1
  ldxdw r1, [r6+0xe8]
  stxdw [r2+0xf0], r1
  ldxdw r1, [r6+0x120]
  stxdw [r2+0x128], r1
  ldxdw r1, [r6+0x118]
  stxdw [r2+0x120], r1
  ldxdw r1, [r6+0x110]
  stxdw [r2+0x118], r1
  ldxdw r1, [r6+0x108]
  stxdw [r2+0x110], r1
  ldxdw r1, [r6+0x138]
  stxdw [r2+0x140], r1
  ldxdw r1, [r6+0x128]
  stxdw [r2+0x130], r1
  ldxdw r1, [r6+0x130]
  stxdw [r2+0x138], r1
  ldxdw r1, [r6+0x140]
  stxdw [r2+0x148], r1
  ldxb r1, [r6+0x160]
  stxb [r2+0x150], r1
  ldxb r1, [r6+0x161]
  stxb [r2+0x151], r1
  ldxdw r1, [r6+0x148]
  stxdw [r2+0x152], r1
  ldxdw r1, [r6+0x150]
  stxdw [r2+0x15a], r1
  ldxdw r1, [r6+0x158]
  stxdw [r2+0x162], r1
  ldxdw r1, [r6+0x180]
  stxdw [r2+0x182], r1
  ldxdw r1, [r6+0x178]
  stxdw [r2+0x17a], r1
  ldxdw r1, [r6+0x170]
  stxdw [r2+0x172], r1
  ldxdw r1, [r6+0x168]
  stxdw [r2+0x16a], r1
  ldxdw r1, [r6+0x1a0]
  stxdw [r2+0x1a2], r1
  ldxdw r1, [r6+0x198]
  stxdw [r2+0x19a], r1
  ldxdw r1, [r6+0x190]
  stxdw [r2+0x192], r1
  ldxdw r1, [r6+0x188]
  stxdw [r2+0x18a], r1
  ldxdw r1, [r6+0x1b8]
  stxdw [r2+0x1ba], r1
  ldxdw r1, [r6+0x1a8]
  stxdw [r2+0x1aa], r1
  ldxdw r1, [r6+0x1b0]
  stxdw [r2+0x1b2], r1
  ldxdw r1, [r6+0x1c0]
  stxdw [r2+0x1c2], r1
  ldxb r1, [r6+0x1e0]
  stxb [r2+0x1ca], r1
  ldxb r1, [r6+0x1e1]
  stxb [r2+0x1cb], r1
  ldxdw r1, [r6+0x1c8]
  stxdw [r2+0x1cc], r1
  stdw [r10-0x8], 0x1d4
  ldxdw r1, [r6+0x1d0]
  stxdw [r2+0x1d4], r1
  ldxdw r1, [r6+0x1d8]
  stxdw [r2+0x1dc], r1
  ldxdw r1, [r6+0x200]
  stxdw [r2+0x1fc], r1
  ldxdw r1, [r6+0x1f8]
  stxdw [r2+0x1f4], r1
  ldxdw r1, [r6+0x1f0]
  stxdw [r2+0x1ec], r1
  ldxdw r1, [r6+0x1e8]
  stxdw [r2+0x1e4], r1
  ldxdw r1, [r6+0x220]
  stxdw [r2+0x21c], r1
  ldxdw r1, [r6+0x218]
  stxdw [r2+0x214], r1
  ldxdw r1, [r6+0x210]
  stxdw [r2+0x20c], r1
  ldxdw r1, [r6+0x208]
  stxdw [r2+0x204], r1
  ldxdw r1, [r6+0x238]
  stxdw [r2+0x234], r1
  ldxdw r1, [r6+0x228]
  stxdw [r2+0x224], r1
  ldxdw r1, [r6+0x230]
  stxdw [r2+0x22c], r1
  ldxdw r1, [r6+0x240]
  stxdw [r2+0x23c], r1
  ldxb r1, [r6+0x260]
  stxb [r2+0x244], r1
  ldxb r1, [r6+0x261]
  stxb [r2+0x245], r1
  ldxdw r1, [r6+0x248]
  stxdw [r2+0x246], r1
  ldxdw r1, [r6+0x250]
  stxdw [r2+0x24e], r1
  ldxdw r1, [r6+0x258]
  stxdw [r2+0x256], r1
  mov64 r1, r6
  add64 r1, 0x268
  stdw [r10-0x8], 0x25e
  mov64 r2, r10
  add64 r2, -0x18
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  mov64 r1, r6
  add64 r1, 0x2e8
  mov64 r2, r10
  add64 r2, -0x18
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  mov64 r1, r6
  add64 r1, 0x368
  mov64 r2, r10
  add64 r2, -0x18
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  mov64 r1, r6
  add64 r1, 0x3e8
  mov64 r2, r10
  add64 r2, -0x18
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  mov64 r1, r6
  add64 r1, 0x468
  mov64 r2, r10
  add64 r2, -0x18
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  add64 r6, 0x4e8
  mov64 r2, r10
  add64 r2, -0x18
  mov64 r1, r6
  call fn_e4f0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_f848
  mov64 r0, 0x0

jmp_f848:
  exit

fn_f850:
  ldxb r0, [r2+0x56d]
  jeq r0, 0x0, jmp_f878
  lddw r2, 0x700000001
  ja jmp_f8b0

jmp_f878:
  ldxb r6, [r2+0x56c]
  mov64 r0, r6
  add64 r0, -0xb
  and64 r0, 0xff
  jge r0, 0xf6, jmp_f8c0
  lddw r2, 0x200000001

jmp_f8b0:
  stxdw [r1+0x0], r2

jmp_f8b8:
  exit

jmp_f8c0:
  stxdw [r10-0xc8], r4
  stxdw [r10-0xe0], r6
  stxdw [r10-0xd8], r1
  mov64 r1, 0x0
  stxdw [r10-0xc0], r1
  jeq r5, 0x0, jmp_f8f8
  ldxb r1, [r5+0xbb]

jmp_f8f8:
  mov64 r6, 0x68
  stxdw [r10-0x118], r5
  mov64 r0, r5
  add64 r0, 0xa4
  mov64 r9, r2
  add64 r9, 0x68
  stw [r10-0x8], 0x0
  stdw [r10-0x10], 0x0
  stw [r10-0x18], 0x0
  stdw [r10-0x20], 0x0
  stw [r10-0x28], 0x0
  stdw [r10-0x30], 0x0
  stw [r10-0x38], 0x0
  stdw [r10-0x40], 0x0
  stw [r10-0x48], 0x0
  stdw [r10-0x50], 0x0
  stw [r10-0x58], 0x0
  stdw [r10-0x60], 0x0
  stw [r10-0x68], 0x0
  stdw [r10-0x70], 0x0
  stw [r10-0x78], 0x0
  stdw [r10-0x80], 0x0
  stw [r10-0x88], 0x0
  stdw [r10-0x90], 0x0
  stw [r10-0x98], 0x0
  stdw [r10-0xa0], 0x0
  and64 r1, 0x1
  stxdw [r10-0x100], r1
  stxdw [r10-0x108], r9
  mov64 r8, r3
  mov64 r1, 0x0
  stxdw [r10-0xe8], r1
  mov64 r5, 0x0
  mov64 r4, 0x0
  stxdw [r10-0xf8], r1
  mov64 r7, 0x0
  stxdw [r10-0x110], r0

jmp_fa20:
  mov64 r1, r6
  stxdw [r10-0xf0], r4
  stxdw [r10-0xd0], r8
  mov64 r8, r7
  lsh64 r8, 0x1
  add64 r0, r8
  add64 r6, 0x80
  ldxdw r4, [r10-0xc8]
  ja jmp_fa98

jmp_fa68:
  add64 r1, 0x80
  mov64 r9, r2
  add64 r9, r1
  add64 r0, 0x2
  add64 r6, 0x80
  jeq r6, 0x5e8, jmp_fe30

jmp_fa98:
  stxdw [r10-0xb0], r7
  add64 r7, 0x1
  mov64 r8, 0x1
  jeq r7, 0x0, jmp_fac0
  mov64 r8, 0x0

jmp_fac0:
  jeq r8, 0x1, jmp_106a8
  ldxdw r8, [r9+0x68]
  stxdw [r10-0xa8], r8
  jlt r3, r8, jmp_fa68
  ldxb r8, [r9+0x79]
  jne r8, 0x1, jmp_fa68
  ldxdw r8, [r9+0x60]
  stxdw [r10-0xb8], r8
  jeq r8, 0x0, jmp_fa68
  mov64 r9, r3
  ldxdw r8, [r10-0xa8]
  sub64 r9, r8
  jle r4, r9, jmp_fa68
  mov64 r1, 0x100
  ldxdw r8, [r10-0x100]
  jeq r8, 0x0, jmp_fb88
  ldxdw r1, [r10-0x118]
  jeq r1, 0x0, jmp_106a0
  ldxdw r1, [r10-0xb0]
  jge r1, 0xa, jmp_10768
  ldxh r1, [r0+0x0]
  mov64 r0, r1
  add64 r0, -0x101
  and64 r0, 0xffff
  jlt r0, 0xff00, jmp_10668

jmp_fb88:
  stxdw [r10-0x120], r5
  stxdw [r10-0x128], r2
  stxdw [r10-0x130], r3
  mov64 r3, r4
  sub64 r3, r9
  lsh64 r1, 0xa
  mov64 r2, 0x0
  mov64 r8, r4
  mov64 r4, 0x0
  call fn_156e0
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_15838
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jgt r0, 0x1, jmp_fc20
  mov64 r0, 0x1

jmp_fc20:
  ldxdw r1, [r10-0xc0]
  ldxdw r8, [r10-0xf8]
  jeq r1, 0xa, jmp_10740
  lsh64 r1, 0x4
  mov64 r2, r10
  add64 r2, -0xa0
  add64 r2, r1
  ldxdw r1, [r10-0xb8]
  stxdw [r2+0x0], r1
  stxw [r2+0x8], r0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  add64 r8, r0
  mov64 r1, r8
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  ldxdw r4, [r10-0xc8]
  ldxdw r3, [r10-0x130]
  ldxdw r2, [r10-0x128]
  jne r1, r8, jmp_10728
  ldxdw r1, [r10-0xb0]
  jge r1, 0x10, jmp_10720
  ldxdw r1, [r10-0xf0]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r9, r0
  jgt r0, r1, jmp_fd10
  mov64 r9, r1

jmp_fd10:
  stxdw [r10-0xf8], r8
  ldxdw r1, [r10-0x120]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jle r0, r1, jmp_fdf0
  ldxdw r8, [r10-0xa8]
  ldxdw r5, [r10-0xd0]
  jge r8, r5, jmp_fe10

jmp_fd50:
  ldxdw r9, [r10-0xc0]
  jgt r0, r1, jmp_fd68

jmp_fd60:
  mov64 r0, r1

jmp_fd68:
  add64 r9, 0x1
  stxdw [r10-0xc0], r9
  mov64 r1, 0x1
  ldxdw r4, [r10-0xb0]
  lsh64 r1, r4
  ldxdw r9, [r10-0xe8]
  or64 r9, r1
  stxdw [r10-0xe8], r9
  mov64 r9, r2
  add64 r9, r6
  mov64 r5, r0
  ldxdw r4, [r10-0x120]
  stxdw [r10-0xf0], r4
  ldxdw r8, [r10-0xa8]
  ldxdw r0, [r10-0x110]
  jne r6, 0x568, jmp_fa20
  ja jmp_fe38

jmp_fdf0:
  stxdw [r10-0x120], r9
  ldxdw r8, [r10-0xa8]
  ldxdw r5, [r10-0xd0]
  jlt r8, r5, jmp_fd50

jmp_fe10:
  stxdw [r10-0xa8], r5
  ldxdw r9, [r10-0xc0]
  jle r0, r1, jmp_fd60
  ja jmp_fd68

jmp_fe30:
  ldxdw r8, [r10-0xd0]

jmp_fe38:
  stxdw [r10-0xa8], r8
  ldxdw r1, [r10-0xc0]
  ldxdw r2, [r10-0xe0]
  jge r1, r2, jmp_fe80
  ldxdw r2, [r10-0xd8]
  stw [r2+0x4], 0x15

jmp_fe68:
  mov64 r1, 0x1
  stxw [r2+0x0], r1
  ja jmp_f8b8

jmp_fe80:
  ldxdw r7, [r10-0xe8]
  mov64 r3, r7
  rsh64 r3, 0x1
  and64 r3, 0x5555
  mov64 r2, r7
  sub64 r2, r3
  mov64 r3, r2
  and64 r3, 0x3333
  rsh64 r2, 0x2
  and64 r2, 0x3333
  add64 r3, r2
  mov64 r2, r3
  rsh64 r2, 0x4
  add64 r3, r2
  mov64 r2, r3
  and64 r2, 0xf
  and64 r3, 0xf00
  rsh64 r3, 0x8
  add64 r2, r3
  jne r2, 0x2, jmp_10090
  mov64 r2, r7
  and64 r2, 0xa
  rsh64 r2, 0x1
  mov64 r4, r7
  and64 r4, 0xb
  mov64 r3, r4
  sub64 r3, r2
  mov64 r2, r3
  and64 r2, 0x3333
  rsh64 r3, 0x2
  and64 r3, 0x3333
  add64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x4
  add64 r2, r3
  mov64 r3, r2
  and64 r3, 0xf
  and64 r2, 0xf00
  rsh64 r2, 0x8
  add64 r3, r2
  jne r3, 0x1, jmp_10090
  mov64 r2, r4
  and64 r2, 0xffff
  jeq r2, 0x0, jmp_105c0
  mov64 r2, r4
  add64 r2, -0x1
  xor64 r4, -0x1
  and64 r4, r2
  mov64 r2, r4
  rsh64 r2, 0x1
  and64 r2, 0x5555
  sub64 r4, r2
  mov64 r2, r4
  and64 r2, 0x3333
  rsh64 r4, 0x2
  and64 r4, 0x3333
  add64 r2, r4
  mov64 r1, r2
  rsh64 r1, 0x4
  add64 r2, r1
  mov64 r1, r2
  and64 r1, 0xf
  and64 r2, 0xf00
  rsh64 r2, 0x8
  add64 r1, r2
  ja jmp_105c8

jmp_10090:
  jge r1, 0xb, jmp_10680
  ldxdw r8, [r10-0xf8]
  jne r1, 0x2, jmp_10100
  ldxw r2, [r10-0x98]
  ldxw r8, [r10-0x88]
  jlt r8, r2, jmp_100c8
  mov64 r8, r2

jmp_100c8:
  stxw [r10-0x88], r8
  stxw [r10-0x98], r8
  lsh64 r8, 0x20
  arsh64 r8, 0x20
  jslt r8, 0x0, jmp_10790
  lsh64 r8, 0x1
  ja jmp_102f8

jmp_10100:
  jlt r1, 0x3, jmp_102f8
  mov64 r0, r5
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r2, r0
  mul64 r2, 0x5
  mov64 r3, r2
  rsh64 r3, 0x20
  jne r3, 0x0, jmp_107a8
  mov64 r3, r8
  lsh64 r3, 0x20
  mov64 r4, r3
  arsh64 r4, 0x20
  jslt r4, 0x0, jmp_107c0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  mov64 r4, r8
  lsh64 r4, 0x1
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jle r2, r4, jmp_102f8
  rsh64 r3, 0x20
  jlt r3, r0, jmp_107f0
  sub64 r8, r5
  mov64 r0, r8
  lsh64 r0, 0x1
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  div64 r0, 0x3
  ldxdw r2, [r10-0xf0]
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jge r0, r2, jmp_10248
  mov64 r3, r8
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r3, r2, jmp_10808
  ldxdw r2, [r10-0xf0]
  sub64 r8, r2
  lsh64 r8, 0x1
  mov64 r0, r8

jmp_10248:
  mov64 r2, r1
  lsh64 r2, 0x4
  mov64 r8, 0x0
  mov64 r3, r10
  add64 r3, -0x98
  lsh64 r0, 0x20
  rsh64 r0, 0x20

jmp_10280:
  ldxw r5, [r3+0x0]
  mov64 r4, r0
  jlt r0, r5, jmp_102a0
  mov64 r4, r5

jmp_102a0:
  stxw [r3+0x0], r4
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  add64 r8, r4
  mov64 r4, r8
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jne r4, r8, jmp_106f0
  add64 r3, 0x10
  add64 r2, -0x10
  jne r2, 0x0, jmp_10280

jmp_102f8:
  jlt r1, 0x2, jmp_10430
  mov64 r9, 0x1
  mov64 r4, 0x2
  mov64 r2, r10
  add64 r2, -0x90
  ja jmp_10348

jmp_10328:
  add64 r2, 0x10
  mov64 r4, r9
  add64 r4, r3
  jge r9, r1, jmp_10430

jmp_10348:
  mov64 r3, r9
  mov64 r9, r4
  mov64 r4, r3
  lsh64 r4, 0x4
  mov64 r0, r10
  add64 r0, -0xa0
  add64 r0, r4
  ldxw r5, [r0+0x8]
  ldxdw r4, [r0+0x0]
  mov64 r0, r2

jmp_10398:
  ldxdw r6, [r0-0x10]
  jle r6, r4, jmp_103e0
  add64 r3, -0x1
  stxdw [r0+0x0], r6
  ldxw r6, [r0-0x8]
  stxw [r0+0x8], r6
  add64 r0, -0x10
  jne r3, 0x0, jmp_10398
  mov64 r3, 0x0

jmp_103e0:
  lsh64 r3, 0x4
  mov64 r0, r10
  add64 r0, -0xa0
  add64 r0, r3
  stxw [r0+0x8], r5
  stxdw [r0+0x0], r4
  mov64 r3, 0x1
  jlt r9, r1, jmp_10328
  mov64 r3, 0x0
  ja jmp_10328

jmp_10430:
  jeq r1, 0x0, jmp_10708
  mov64 r4, 0x0
  mov64 r2, r1
  lsh64 r2, 0x4
  mov64 r9, r10
  add64 r9, -0xa0
  mov64 r3, r9
  add64 r3, r2
  ldxdw r2, [r3-0x10]
  mov64 r3, 0x0

jmp_10480:
  jeq r1, r3, jmp_10630
  ldxw r5, [r9+0x8]
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  add64 r4, r5
  mov64 r5, r4
  lsh64 r5, 0x20
  mov64 r0, r5
  rsh64 r0, 0x20
  jne r0, r4, jmp_106c0
  arsh64 r5, 0x20
  jslt r5, 0x0, jmp_106d8
  add64 r3, 0x1
  add64 r9, 0x10
  mov64 r0, r8
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r6, r5
  lsh64 r6, 0x1
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  mov64 r4, r5
  jlt r6, r0, jmp_10480
  ldxdw r4, [r9-0x10]
  jne r6, r0, jmp_10628
  jge r3, r1, jmp_10628
  ldxdw r1, [r9+0x0]
  jlt r1, r4, jmp_107d8
  sub64 r1, r4
  rsh64 r1, 0x1
  mov64 r2, r4
  add64 r2, r1
  mov64 r1, 0x1
  jlt r2, r4, jmp_10598
  mov64 r1, 0x0

jmp_10598:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_10630
  lddw r1, data_0800
  call fn_14350

jmp_105c0:
  mov64 r1, 0x10

jmp_105c8:
  ldxdw r2, [r10-0x108]
  lsh64 r1, 0x7
  add64 r2, r1
  ldxdw r1, [r2+0x60]
  ldxdw r3, [r10-0xd8]
  stxh [r3+0x18], r7
  ldxdw r2, [r10-0xa8]
  stxdw [r3+0x10], r2
  stxdw [r3+0x8], r1
  mov64 r1, 0x0
  stxw [r3+0x0], r1
  ja jmp_f8b8

jmp_10628:
  mov64 r2, r4

jmp_10630:
  ldxdw r1, [r10-0xa8]
  ldxdw r3, [r10-0xd8]
  stxh [r3+0x18], r7
  stxdw [r3+0x10], r1
  stxdw [r3+0x8], r2
  stw [r3+0x0], 0x0
  ja jmp_f8b8

jmp_10668:
  ldxdw r2, [r10-0xd8]
  stw [r2+0x4], 0x2
  ja jmp_fe68

jmp_10680:
  mov64 r2, 0xa
  lddw r3, data_0788
  call fn_14328

jmp_106a0:
  call fn_14358

jmp_106a8:
  lddw r1, data_0770
  call fn_14350

jmp_106c0:
  lddw r1, data_07b8
  call fn_14350

jmp_106d8:
  lddw r1, data_07d0
  call fn_14350

jmp_106f0:
  lddw r1, data_0908
  call fn_14350

jmp_10708:
  lddw r1, data_07a0
  call fn_14350

jmp_10720:
  call fn_14360

jmp_10728:
  lddw r1, data_0860
  call fn_14350

jmp_10740:
  mov64 r1, 0xa
  mov64 r2, 0xa
  lddw r3, data_0848
  call fn_14310

jmp_10768:
  ldxdw r1, [r10-0xb0]
  mov64 r2, 0xa
  lddw r3, data_0830
  call fn_14310

jmp_10790:
  lddw r1, data_0890
  call fn_14350

jmp_107a8:
  lddw r1, data_08a8
  call fn_14350

jmp_107c0:
  lddw r1, data_08c0
  call fn_14350

jmp_107d8:
  lddw r1, data_07e8
  call fn_14350

jmp_107f0:
  lddw r1, data_08d8
  call fn_14350

jmp_10808:
  lddw r1, data_08f0
  call fn_14350

fn_10820:
  jne r3, 0xbf, jmp_10b68
  mov64 r0, 0x13
  ldxdw r3, [r2+0x0]
  lddw r4, 0x3230544847575443
  jne r3, r4, jmp_10b78
  mov64 r3, 0x0
  mov64 r0, 0x1
  ldxdw r5, [r2+0xa]
  ldxh r7, [r2+0x8]
  ldxb r4, [r2+0x12]
  mov64 r9, 0x0
  jeq r4, 0x0, jmp_10898
  jne r4, 0x1, jmp_10b78
  mov64 r9, 0x1

jmp_10898:
  ldxb r8, [r2+0x13]
  ldxb r4, [r2+0x14]
  jeq r4, 0x0, jmp_108c0
  jne r4, 0x1, jmp_10b78
  mov64 r3, 0x1

jmp_108c0:
  ldxdw r4, [r2+0x6f]
  stxdw [r10-0x8], r4
  ldxdw r4, [r2+0x77]
  stxdw [r10-0x10], r4
  ldxdw r4, [r2+0x7f]
  stxdw [r10-0x18], r4
  ldxdw r4, [r2+0x87]
  stxdw [r10-0x20], r4
  ldxdw r4, [r2+0x8f]
  stxdw [r10-0x28], r4
  ldxdw r4, [r2+0x97]
  stxdw [r10-0x30], r4
  ldxdw r4, [r2+0x9f]
  stxdw [r10-0x38], r4
  ldxdw r4, [r2+0xa7]
  stxdw [r10-0x40], r4
  ldxdw r4, [r2+0xaf]
  stxdw [r10-0x48], r4
  ldxdw r4, [r2+0xb7]
  stxdw [r10-0x50], r4
  ldxdw r4, [r2+0x65]
  stxdw [r10-0x58], r4
  ldxh r4, [r2+0x6d]
  stxdw [r10-0x60], r4
  ldxdw r4, [r2+0x15]
  stxdw [r10-0x68], r4
  ldxdw r4, [r2+0x1d]
  stxdw [r10-0x70], r4
  ldxdw r4, [r2+0x25]
  stxdw [r10-0x78], r4
  ldxdw r4, [r2+0x2d]
  stxdw [r10-0x88], r4
  ldxdw r4, [r2+0x35]
  stxdw [r10-0x90], r4
  ldxdw r0, [r2+0x3d]
  stxdw [r10-0x80], r5
  ldxdw r5, [r2+0x45]
  ldxdw r4, [r2+0x4d]
  ldxdw r6, [r2+0x55]
  ldxdw r2, [r2+0x5d]
  stxb [r1+0xbb], r9
  stxb [r1+0xba], r8
  stxh [r1+0xb8], r7
  stxdw [r1+0xb0], r2
  stxdw [r1+0xa8], r6
  stxdw [r1+0xa0], r4
  stxdw [r1+0x98], r5
  stxdw [r1+0x90], r0
  ldxdw r2, [r10-0x90]
  stxdw [r1+0x88], r2
  ldxdw r2, [r10-0x88]
  stxdw [r1+0x80], r2
  ldxdw r2, [r10-0x78]
  stxdw [r1+0x78], r2
  ldxdw r2, [r10-0x70]
  stxdw [r1+0x70], r2
  ldxdw r2, [r10-0x68]
  stxdw [r1+0x68], r2
  ldxdw r2, [r10-0x80]
  stxdw [r1+0x60], r2
  ldxdw r2, [r10-0x60]
  stxh [r1+0x58], r2
  ldxdw r2, [r10-0x58]
  stxdw [r1+0x50], r2
  ldxdw r2, [r10-0x50]
  stxdw [r1+0x48], r2
  ldxdw r2, [r10-0x48]
  stxdw [r1+0x40], r2
  ldxdw r2, [r10-0x40]
  stxdw [r1+0x38], r2
  ldxdw r2, [r10-0x38]
  stxdw [r1+0x30], r2
  ldxdw r2, [r10-0x30]
  stxdw [r1+0x28], r2
  ldxdw r2, [r10-0x28]
  stxdw [r1+0x20], r2
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x18], r2
  ldxdw r2, [r10-0x18]
  stxdw [r1+0x10], r2
  ldxdw r2, [r10-0x10]
  stxdw [r1+0x8], r2
  ldxdw r2, [r10-0x8]
  stxdw [r1+0x0], r2
  ja jmp_10b88

jmp_10b68:
  stw [r1+0x0], 0x2
  ja jmp_10b80

jmp_10b78:
  stxw [r1+0x0], r0

jmp_10b80:
  mov64 r3, 0x2

jmp_10b88:
  stxb [r1+0xbc], r3
  exit

fn_10b98:
  mov64 r0, 0x2
  jne r3, 0xbf, jmp_10eb8
  lddw r3, 0x3230544847575443
  stxdw [r2+0x0], r3
  ldxh r3, [r1+0xb8]
  stxh [r2+0x8], r3
  ldxdw r3, [r1+0x60]
  stxdw [r2+0xa], r3
  ldxb r3, [r1+0xbb]
  stxb [r2+0x12], r3
  ldxb r3, [r1+0xba]
  stxb [r2+0x13], r3
  ldxb r3, [r1+0xbc]
  stxb [r2+0x14], r3
  ldxw r3, [r1+0x68]
  stxw [r2+0x15], r3
  ldxw r3, [r1+0x6c]
  stxw [r2+0x19], r3
  ldxw r3, [r1+0x70]
  stxw [r2+0x1d], r3
  ldxw r3, [r1+0x74]
  stxw [r2+0x21], r3
  ldxw r3, [r1+0x78]
  stxw [r2+0x25], r3
  ldxw r3, [r1+0x7c]
  stxw [r2+0x29], r3
  ldxw r3, [r1+0x80]
  stxw [r2+0x2d], r3
  ldxw r3, [r1+0x84]
  stxw [r2+0x31], r3
  ldxw r3, [r1+0x88]
  stxw [r2+0x35], r3
  ldxw r3, [r1+0x8c]
  stxw [r2+0x39], r3
  ldxh r3, [r1+0x90]
  stxh [r2+0x3d], r3
  ldxh r3, [r1+0x92]
  stxh [r2+0x3f], r3
  ldxh r3, [r1+0x94]
  stxh [r2+0x41], r3
  ldxh r3, [r1+0x96]
  stxh [r2+0x43], r3
  ldxh r3, [r1+0x98]
  stxh [r2+0x45], r3
  ldxh r3, [r1+0x9a]
  stxh [r2+0x47], r3
  ldxh r3, [r1+0x9c]
  stxh [r2+0x49], r3
  ldxh r3, [r1+0x9e]
  stxh [r2+0x4b], r3
  ldxh r3, [r1+0xa0]
  stxh [r2+0x4d], r3
  ldxh r3, [r1+0xa2]
  stxh [r2+0x4f], r3
  ldxh r3, [r1+0xa4]
  stxh [r2+0x51], r3
  ldxh r3, [r1+0xa6]
  stxh [r2+0x53], r3
  ldxh r3, [r1+0xa8]
  stxh [r2+0x55], r3
  ldxh r3, [r1+0xaa]
  stxh [r2+0x57], r3
  ldxh r3, [r1+0xac]
  stxh [r2+0x59], r3
  ldxh r3, [r1+0xae]
  stxh [r2+0x5b], r3
  ldxh r3, [r1+0xb0]
  stxh [r2+0x5d], r3
  ldxh r3, [r1+0xb2]
  stxh [r2+0x5f], r3
  ldxh r3, [r1+0xb4]
  stxh [r2+0x61], r3
  ldxh r3, [r1+0xb6]
  stxh [r2+0x63], r3
  ldxdw r3, [r1+0x50]
  stxdw [r2+0x65], r3
  ldxh r3, [r1+0x58]
  stxh [r2+0x6d], r3
  ldxdw r3, [r1+0x0]
  stxdw [r2+0x6f], r3
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x77], r3
  ldxdw r3, [r1+0x10]
  stxdw [r2+0x7f], r3
  ldxdw r3, [r1+0x18]
  stxdw [r2+0x87], r3
  ldxdw r3, [r1+0x20]
  stxdw [r2+0x8f], r3
  ldxdw r3, [r1+0x28]
  stxdw [r2+0x97], r3
  ldxdw r3, [r1+0x30]
  stxdw [r2+0x9f], r3
  ldxdw r3, [r1+0x38]
  stxdw [r2+0xa7], r3
  ldxdw r3, [r1+0x40]
  stxdw [r2+0xaf], r3
  ldxdw r1, [r1+0x48]
  stxdw [r2+0xb7], r1
  mov64 r0, 0x0

jmp_10eb8:
  exit

fn_10ec0:
  mov64 r6, 0x0
  ldxb r5, [r1+0xbb]
  mov64 r0, 0x0
  jne r5, 0x1, jmp_11648
  lddw r0, 0x200000000
  mov64 r6, 0x1
  ldxb r5, [r1+0xba]
  add64 r5, -0x4
  and64 r5, 0xff
  jgt r5, 0xe, jmp_11648
  jeq r4, 0x0, jmp_11648
  ldxdw r7, [r1+0x50]
  ldxb r5, [r1+0xbc]
  jne r5, 0x1, jmp_10f50
  lddw r0, 0x600000000
  jlt r2, r7, jmp_11648

jmp_10f50:
  stxdw [r10-0xd0], r2
  mov64 r9, 0x0
  stdw [r10-0xd8], 0x0
  stdw [r10-0xe0], 0x0
  stdw [r10-0xe8], 0x0
  stdw [r10-0xf0], 0x0
  stdw [r10-0xf8], 0x0
  stdw [r10-0x100], 0x0
  stdw [r10-0x108], 0x0
  stdw [r10-0x110], 0x0
  stdw [r10-0x118], 0x0
  stdw [r10-0x120], 0x0
  sth [r10-0xc8], 0x0
  ldxb r0, [r3+0xe1]
  stxdw [r10-0x128], r7
  jeq r0, 0x0, jmp_11050
  ldxdw r0, [r3+0xc8]
  jeq r0, 0x0, jmp_11050
  ldxdw r6, [r3+0xd0]
  jlt r2, r6, jmp_11050
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_110d8
  stxdw [r10-0x120], r0
  mov64 r0, 0x1
  sth [r10-0xc8], 0x1
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11058
  mov64 r9, 0x1
  ldxb r6, [r3+0x161]
  jeq r6, 0x1, jmp_11068
  ja jmp_11108

jmp_11050:
  mov64 r0, 0x0

jmp_11058:
  ldxb r6, [r3+0x161]
  jne r6, 0x1, jmp_11108

jmp_11068:
  ldxdw r8, [r3+0x148]
  jeq r8, 0x0, jmp_11108
  ldxdw r6, [r3+0x150]
  jlt r2, r6, jmp_11108
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11100
  stxdw [r10-0x118], r8
  or64 r0, 0x2
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11108
  or64 r9, 0x2
  ja jmp_11108

jmp_110d8:
  mov64 r0, 0x0
  ldxdw r7, [r10-0x128]
  ldxb r6, [r3+0x161]
  jeq r6, 0x1, jmp_11068
  ja jmp_11108

jmp_11100:
  ldxdw r7, [r10-0x128]

jmp_11108:
  ldxb r6, [r3+0x1e1]
  jne r6, 0x1, jmp_11190
  ldxdw r8, [r3+0x1c8]
  jeq r8, 0x0, jmp_11190
  ldxdw r6, [r3+0x1d0]
  jlt r2, r6, jmp_11190
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11188
  stxdw [r10-0x110], r8
  or64 r0, 0x4
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11190
  or64 r9, 0x4
  ja jmp_11190

jmp_11188:
  ldxdw r7, [r10-0x128]

jmp_11190:
  ldxb r6, [r3+0x261]
  jne r6, 0x1, jmp_11218
  ldxdw r8, [r3+0x248]
  jeq r8, 0x0, jmp_11218
  ldxdw r6, [r3+0x250]
  jlt r2, r6, jmp_11218
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11210
  stxdw [r10-0x108], r8
  or64 r0, 0x8
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11218
  or64 r9, 0x8
  ja jmp_11218

jmp_11210:
  ldxdw r7, [r10-0x128]

jmp_11218:
  ldxb r6, [r3+0x2e1]
  jne r6, 0x1, jmp_112a0
  ldxdw r8, [r3+0x2c8]
  jeq r8, 0x0, jmp_112a0
  ldxdw r6, [r3+0x2d0]
  jlt r2, r6, jmp_112a0
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11298
  stxdw [r10-0x100], r8
  or64 r0, 0x10
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_112a0
  or64 r9, 0x10
  ja jmp_112a0

jmp_11298:
  ldxdw r7, [r10-0x128]

jmp_112a0:
  ldxb r6, [r3+0x361]
  jne r6, 0x1, jmp_11328
  ldxdw r8, [r3+0x348]
  jeq r8, 0x0, jmp_11328
  ldxdw r6, [r3+0x350]
  jlt r2, r6, jmp_11328
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11320
  stxdw [r10-0xf8], r8
  or64 r0, 0x20
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11328
  or64 r9, 0x20
  ja jmp_11328

jmp_11320:
  ldxdw r7, [r10-0x128]

jmp_11328:
  ldxb r6, [r3+0x3e1]
  jne r6, 0x1, jmp_113b0
  ldxdw r8, [r3+0x3c8]
  jeq r8, 0x0, jmp_113b0
  ldxdw r6, [r3+0x3d0]
  jlt r2, r6, jmp_113b0
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_113a8
  stxdw [r10-0xf0], r8
  or64 r0, 0x40
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_113b0
  or64 r9, 0x40
  ja jmp_113b0

jmp_113a8:
  ldxdw r7, [r10-0x128]

jmp_113b0:
  ldxb r6, [r3+0x461]
  jne r6, 0x1, jmp_11438
  ldxdw r8, [r3+0x448]
  jeq r8, 0x0, jmp_11438
  ldxdw r6, [r3+0x450]
  jlt r2, r6, jmp_11438
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11430
  stxdw [r10-0xe8], r8
  or64 r0, 0x80
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11438
  or64 r9, 0x80
  ja jmp_11438

jmp_11430:
  ldxdw r7, [r10-0x128]

jmp_11438:
  ldxb r6, [r3+0x4e1]
  jne r6, 0x1, jmp_114c0
  ldxdw r8, [r3+0x4c8]
  jeq r8, 0x0, jmp_114c0
  ldxdw r6, [r3+0x4d0]
  jlt r2, r6, jmp_114c0
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_114b8
  stxdw [r10-0xe0], r8
  or64 r0, 0x100
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_114c0
  or64 r9, 0x100
  ja jmp_114c0

jmp_114b8:
  ldxdw r7, [r10-0x128]

jmp_114c0:
  ldxb r6, [r3+0x561]
  jne r6, 0x1, jmp_11548
  ldxdw r8, [r3+0x548]
  jeq r8, 0x0, jmp_11548
  ldxdw r6, [r3+0x550]
  jlt r2, r6, jmp_11548
  mov64 r7, r2
  sub64 r7, r6
  jge r7, r4, jmp_11540
  stxdw [r10-0xd8], r8
  or64 r0, 0x200
  stxh [r10-0xc8], r0
  ldxdw r7, [r10-0x128]
  jle r6, r7, jmp_11548
  or64 r9, 0x200
  ja jmp_11548

jmp_11540:
  ldxdw r7, [r10-0x128]

jmp_11548:
  jeq r5, 0x0, jmp_11608
  jne r2, r7, jmp_11600
  ldxh r5, [r1+0x58]
  jne r5, r0, jmp_11600
  mov64 r5, r10
  add64 r5, -0x120
  mov64 r6, r1
  mov64 r8, r2
  mov64 r2, r5
  stxdw [r10-0x130], r9
  mov64 r9, r3
  mov64 r3, 0x50
  mov64 r7, r4
  call fn_156a0
  mov64 r4, r7
  ldxdw r7, [r10-0x128]
  mov64 r2, r8
  mov64 r3, r9
  ldxdw r9, [r10-0x130]
  mov64 r1, r6
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jeq r0, 0x0, jmp_117f8

jmp_11600:
  jge r2, r7, jmp_11658

jmp_11608:
  mov64 r2, r10
  add64 r2, -0x120
  mov64 r6, r1
  mov64 r3, 0x60
  call fn_15658
  stb [r6+0xbc], 0x1
  mov64 r0, 0x100
  mov64 r6, 0x0

jmp_11648:
  or64 r0, r6
  exit

jmp_11658:
  jeq r2, r7, jmp_11608
  mov64 r5, r2
  sub64 r5, r7
  jgt r5, r4, jmp_11608
  mov64 r4, r9
  rsh64 r4, 0x1
  and64 r4, 0x155
  mov64 r5, r9
  sub64 r5, r4
  mov64 r4, r5
  and64 r4, 0x3333
  rsh64 r5, 0x2
  and64 r5, 0x3333
  add64 r4, r5
  mov64 r5, r4
  rsh64 r5, 0x4
  add64 r4, r5
  mov64 r5, r4
  and64 r5, 0xf
  and64 r4, 0xf00
  rsh64 r4, 0x8
  add64 r5, r4
  mov64 r6, 0x0
  mov64 r0, 0x0
  jlt r5, 0x3, jmp_11648
  mov64 r8, r10
  add64 r8, -0xc0
  mov64 r6, r1
  mov64 r1, r8
  mov64 r7, r2
  mov64 r2, r6
  stxdw [r10-0x128], r3
  mov64 r3, 0x60
  call fn_15658
  stxh [r10-0x8], r9
  stxdw [r10-0x10], r7
  mov64 r9, r10
  add64 r9, -0x60
  mov64 r2, r10
  add64 r2, -0x120
  mov64 r1, r9
  mov64 r3, 0x50
  call fn_15658
  mov64 r1, r6
  mov64 r2, r8
  mov64 r3, r9
  call fn_11810
  mov64 r1, r6
  ldxdw r2, [r10-0x128]
  call fn_133d8
  mov64 r1, r6
  ja jmp_11608

jmp_117f8:
  mov64 r6, 0x0
  mov64 r0, 0x0
  ja jmp_11648

fn_11810:
  mov64 r9, r3
  stxdw [r10-0x178], r2
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x170
  mov64 r8, 0x0
  mov64 r2, 0x0
  mov64 r3, 0xa0
  call fn_15678
  mov64 r1, 0x1
  ldxh r2, [r9+0x58]
  mov64 r4, 0x0
  ja jmp_11898

jmp_11878:
  mov64 r1, r3
  add64 r1, r4
  mov64 r4, r3
  jge r3, 0xa, jmp_119e8

jmp_11898:
  mov64 r3, r1
  mov64 r1, r2
  rsh64 r1, r4
  and64 r1, 0x1
  jeq r1, 0x0, jmp_119c8
  mov64 r1, r4
  lsh64 r1, 0x3
  mov64 r5, r9
  add64 r5, r1
  ldxdw r5, [r5+0x0]
  jeq r5, 0x0, jmp_119c8
  jeq r8, 0x0, jmp_11978
  mov64 r1, r8
  lsh64 r1, 0x4
  mov64 r0, r10
  add64 r0, -0x170
  add64 r0, r1
  mov64 r1, r8

jmp_11928:
  jge r8, 0xb, jmp_131e0
  ldxdw r6, [r0-0x10]
  jle r6, r5, jmp_11988
  jeq r1, 0xa, jmp_13208
  add64 r1, -0x1
  stxdw [r0+0x0], r6
  ldxdw r6, [r0-0x8]
  stxdw [r0+0x8], r6
  add64 r0, -0x10
  jne r1, 0x0, jmp_11928

jmp_11978:
  mov64 r1, 0x0
  ja jmp_11990

jmp_11988:
  jeq r1, 0xa, jmp_132d0

jmp_11990:
  lsh64 r1, 0x4
  mov64 r0, r10
  add64 r0, -0x170
  add64 r0, r1
  stxdw [r0+0x8], r4
  stxdw [r0+0x0], r5
  add64 r8, 0x1

jmp_119c8:
  mov64 r4, 0x1
  jlt r3, 0xa, jmp_11878
  mov64 r4, 0x0
  ja jmp_11878

jmp_119e8:
  jge r8, 0x3, jmp_119f8

jmp_119f0:
  exit

jmp_119f8:
  mov64 r1, r8
  rsh64 r1, 0x1
  stw [r10-0xb8], 0x0
  stdw [r10-0xc0], 0x0
  stdw [r10-0xc8], 0x0
  stdw [r10-0xd0], 0x0
  stdw [r10-0xb0], 0x0
  stdw [r10-0xa8], 0x0
  stdw [r10-0xa0], 0x0
  stw [r10-0x98], 0x0
  stdw [r10-0x90], 0x0
  stdw [r10-0x88], 0x0
  stdw [r10-0x80], 0x0
  stw [r10-0x78], 0x0
  stdw [r10-0x70], 0x0
  stdw [r10-0x68], 0x0
  stdw [r10-0x60], 0x0
  stw [r10-0x58], 0x0
  stdw [r10-0x8], 0x3
  stdw [r10-0x10], 0x3
  stdw [r10-0x18], 0x3
  stdw [r10-0x20], 0x3
  stdw [r10-0x28], 0x3
  stdw [r10-0x30], 0x3
  stdw [r10-0x38], 0x3
  stdw [r10-0x40], 0x3
  stdw [r10-0x48], 0x3
  stdw [r10-0x50], 0x3
  mov64 r2, r8
  and64 r2, 0x1
  jne r2, 0x0, jmp_11c90
  jge r8, 0x14, jmp_13370
  mov64 r2, r1
  lsh64 r2, 0x4
  mov64 r3, r10
  add64 r3, -0x170
  add64 r3, r2
  ldxdw r2, [r3+0x0]
  jeq r2, 0x0, jmp_11e98
  mov64 r5, r2
  rsh64 r5, 0x1
  mov64 r4, r2
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
  lddw r5, 0x5555555555555555
  mov64 r0, r4
  rsh64 r0, 0x1
  and64 r0, r5
  sub64 r4, r0
  lddw r0, 0x3333333333333333
  mov64 r5, r4
  and64 r5, r0
  rsh64 r4, 0x2
  and64 r4, r0
  add64 r5, r4
  mov64 r4, r5
  rsh64 r4, 0x4
  add64 r5, r4
  lddw r4, 0xf0f0f0f0f0f0f0f
  and64 r5, r4
  lddw r4, 0x101010101010101
  mul64 r5, r4
  rsh64 r5, 0x38
  ja jmp_11ea0

jmp_11c90:
  jge r8, 0x14, jmp_13390
  mov64 r3, r10
  add64 r3, -0x170
  jge r8, 0x12, jmp_133b0
  mov64 r2, r1
  lsh64 r2, 0x4
  add64 r3, r2
  ldxdw r2, [r3+0x0]
  ldxdw r4, [r3+0x10]
  jlt r4, r2, jmp_13340
  mov64 r0, r4
  sub64 r0, r2
  rsh64 r0, 0x1
  mov64 r5, r2
  add64 r5, r0
  mov64 r0, 0x1
  jlt r5, r2, jmp_11d20
  mov64 r0, 0x0

jmp_11d20:
  and64 r0, 0x1
  jne r0, 0x0, jmp_13358
  jeq r5, 0x0, jmp_12370
  mov64 r6, r5
  rsh64 r6, 0x1
  mov64 r0, r5
  or64 r0, r6
  mov64 r6, r0
  rsh64 r6, 0x2
  or64 r0, r6
  mov64 r6, r0
  rsh64 r6, 0x4
  or64 r0, r6
  mov64 r6, r0
  rsh64 r6, 0x8
  or64 r0, r6
  mov64 r6, r0
  rsh64 r6, 0x10
  or64 r0, r6
  mov64 r6, r0
  rsh64 r6, 0x20
  or64 r0, r6
  xor64 r0, -0x1
  lddw r6, 0x5555555555555555
  mov64 r9, r0
  rsh64 r9, 0x1
  and64 r9, r6
  sub64 r0, r9
  lddw r9, 0x3333333333333333
  mov64 r6, r0
  and64 r6, r9
  rsh64 r0, 0x2
  and64 r0, r9
  add64 r6, r0
  mov64 r0, r6
  rsh64 r0, 0x4
  add64 r6, r0
  lddw r0, 0xf0f0f0f0f0f0f0f
  and64 r6, r0
  lddw r0, 0x101010101010101
  mul64 r6, r0
  rsh64 r6, 0x38
  ja jmp_12378

jmp_11e98:
  mov64 r5, 0x40

jmp_11ea0:
  mov64 r0, 0x28
  sub64 r0, r5
  mov64 r4, 0x0
  mov64 r5, 0x1
  jgt r0, 0x28, jmp_11ef8
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_11f00

jmp_11ed8:
  mov64 r5, r2
  rsh64 r5, r4
  jne r5, 0x0, jmp_11f20
  ja jmp_13178

jmp_11ef8:
  jne r5, 0x0, jmp_11ed8

jmp_11f00:
  mov64 r4, r0
  mov64 r5, r2
  rsh64 r5, r4
  jeq r5, 0x0, jmp_13178

jmp_11f20:
  stxw [r10-0xb8], r4
  stxdw [r10-0xd0], r2
  mov64 r4, r5
  rsh64 r4, 0x1
  lddw r0, 0x2710000000
  add64 r4, r0
  stxdw [r10-0xc8], r5
  div64 r4, r5
  stxdw [r10-0xc0], r4
  ldxdw r3, [r3-0x10]
  jeq r3, 0x0, jmp_120e0
  mov64 r5, r3
  rsh64 r5, 0x1
  mov64 r4, r3
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
  lddw r5, 0x5555555555555555
  mov64 r0, r4
  rsh64 r0, 0x1
  and64 r0, r5
  sub64 r4, r0
  lddw r0, 0x3333333333333333
  mov64 r5, r4
  and64 r5, r0
  rsh64 r4, 0x2
  and64 r4, r0
  add64 r5, r4
  mov64 r4, r5
  rsh64 r4, 0x4
  add64 r5, r4
  lddw r4, 0xf0f0f0f0f0f0f0f
  and64 r5, r4
  lddw r4, 0x101010101010101
  mul64 r5, r4
  rsh64 r5, 0x38
  ja jmp_120e8

jmp_120e0:
  mov64 r5, 0x40

jmp_120e8:
  mov64 r0, 0x28
  sub64 r0, r5
  mov64 r4, 0x0
  mov64 r5, 0x1
  jgt r0, 0x28, jmp_12140
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_12148

jmp_12120:
  mov64 r5, r3
  rsh64 r5, r4
  jne r5, 0x0, jmp_12168
  ja jmp_13178

jmp_12140:
  jne r5, 0x0, jmp_12120

jmp_12148:
  mov64 r4, r0
  mov64 r5, r3
  rsh64 r5, r4
  jeq r5, 0x0, jmp_13178

jmp_12168:
  stxw [r10-0x98], r4
  mov64 r4, r5
  rsh64 r4, 0x1
  lddw r0, 0x2710000000
  add64 r4, r0
  stxdw [r10-0xa8], r5
  div64 r4, r5
  stxdw [r10-0xa0], r4
  stxdw [r10-0xb0], r3
  jlt r2, r3, jmp_13340
  sub64 r2, r3
  rsh64 r2, 0x1
  mov64 r4, r3
  add64 r4, r2
  mov64 r2, 0x1
  jlt r4, r3, jmp_121f8
  mov64 r2, 0x0

jmp_121f8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_13358
  jeq r4, 0x0, jmp_12608
  mov64 r3, r4
  rsh64 r3, 0x1
  mov64 r2, r4
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
  mov64 r5, r2
  rsh64 r5, 0x1
  and64 r5, r3
  sub64 r2, r5
  lddw r5, 0x3333333333333333
  mov64 r3, r2
  and64 r3, r5
  rsh64 r2, 0x2
  and64 r2, r5
  add64 r3, r2
  mov64 r2, r3
  rsh64 r2, 0x4
  add64 r3, r2
  lddw r2, 0xf0f0f0f0f0f0f0f
  and64 r3, r2
  lddw r2, 0x101010101010101
  mul64 r3, r2
  rsh64 r3, 0x38
  ja jmp_12610

jmp_12370:
  mov64 r6, 0x40

jmp_12378:
  mov64 r9, 0x28
  sub64 r9, r6
  mov64 r0, 0x0
  mov64 r6, 0x1
  jgt r9, 0x28, jmp_123d0
  mov64 r6, 0x0
  jeq r6, 0x0, jmp_123d8

jmp_123b0:
  mov64 r6, r5
  rsh64 r6, r0
  jne r6, 0x0, jmp_123f8
  ja jmp_13178

jmp_123d0:
  jne r6, 0x0, jmp_123b0

jmp_123d8:
  mov64 r0, r9
  mov64 r6, r5
  rsh64 r6, r0
  jeq r6, 0x0, jmp_13178

jmp_123f8:
  stxw [r10-0xb8], r0
  stxdw [r10-0xd0], r5
  mov64 r5, r6
  rsh64 r5, 0x1
  lddw r0, 0x2710000000
  add64 r5, r0
  stxdw [r10-0xc8], r6
  div64 r5, r6
  stxdw [r10-0xc0], r5
  ldxdw r3, [r3-0x10]
  jlt r4, r3, jmp_13340
  sub64 r4, r3
  rsh64 r4, 0x1
  mov64 r5, r3
  add64 r5, r4
  mov64 r4, 0x1
  jlt r5, r3, jmp_12490
  mov64 r4, 0x0

jmp_12490:
  and64 r4, 0x1
  jne r4, 0x0, jmp_13358
  jeq r5, 0x0, jmp_12788
  mov64 r0, r5
  rsh64 r0, 0x1
  mov64 r4, r5
  or64 r4, r0
  mov64 r0, r4
  rsh64 r0, 0x2
  or64 r4, r0
  mov64 r0, r4
  rsh64 r0, 0x4
  or64 r4, r0
  mov64 r0, r4
  rsh64 r0, 0x8
  or64 r4, r0
  mov64 r0, r4
  rsh64 r0, 0x10
  or64 r4, r0
  mov64 r0, r4
  rsh64 r0, 0x20
  or64 r4, r0
  xor64 r4, -0x1
  lddw r0, 0x5555555555555555
  mov64 r6, r4
  rsh64 r6, 0x1
  and64 r6, r0
  sub64 r4, r6
  lddw r6, 0x3333333333333333
  mov64 r0, r4
  and64 r0, r6
  rsh64 r4, 0x2
  and64 r4, r6
  add64 r0, r4
  mov64 r4, r0
  rsh64 r4, 0x4
  add64 r0, r4
  lddw r4, 0xf0f0f0f0f0f0f0f
  and64 r0, r4
  lddw r4, 0x101010101010101
  mul64 r0, r4
  rsh64 r0, 0x38
  ja jmp_12790

jmp_12608:
  mov64 r3, 0x40

jmp_12610:
  mov64 r5, 0x28
  sub64 r5, r3
  mov64 r2, 0x0
  mov64 r3, 0x1
  jgt r5, 0x28, jmp_12668
  mov64 r3, 0x0
  jeq r3, 0x0, jmp_12670

jmp_12648:
  mov64 r3, r4
  rsh64 r3, r2
  jne r3, 0x0, jmp_12690
  ja jmp_13178

jmp_12668:
  jne r3, 0x0, jmp_12648

jmp_12670:
  mov64 r2, r5
  mov64 r3, r4
  rsh64 r3, r2
  jeq r3, 0x0, jmp_13178

jmp_12690:
  stxw [r10-0x58], r2
  stxdw [r10-0x70], r4
  mov64 r2, r3
  rsh64 r2, 0x1
  lddw r4, 0x2710000000
  add64 r2, r4
  stxdw [r10-0x68], r3
  div64 r2, r3
  stxdw [r10-0x60], r2
  jge r8, 0xb, jmp_13190
  mov64 r3, 0x0
  mov64 r4, r10
  add64 r4, -0x168
  lsh64 r8, 0x4
  ja jmp_12758

jmp_12710:
  lsh64 r2, 0x3
  mov64 r0, r10
  add64 r0, -0x50
  add64 r0, r2
  stxdw [r0+0x0], r5
  add64 r4, 0x10
  add64 r3, 0x1
  add64 r8, -0x10
  jeq r8, 0x0, jmp_12db0

jmp_12758:
  ldxdw r2, [r4+0x0]
  jge r2, 0xa, jmp_13230
  mov64 r5, 0x1
  jge r3, r1, jmp_12710
  mov64 r5, 0x0
  ja jmp_12710

jmp_12788:
  mov64 r0, 0x40

jmp_12790:
  mov64 r6, 0x28
  sub64 r6, r0
  mov64 r4, 0x0
  mov64 r0, 0x1
  jgt r6, 0x28, jmp_127e8
  mov64 r0, 0x0
  jeq r0, 0x0, jmp_127f0

jmp_127c8:
  mov64 r0, r5
  rsh64 r0, r4
  jne r0, 0x0, jmp_12810
  ja jmp_13178

jmp_127e8:
  jne r0, 0x0, jmp_127c8

jmp_127f0:
  mov64 r4, r6
  mov64 r0, r5
  rsh64 r0, r4
  jeq r0, 0x0, jmp_13178

jmp_12810:
  stxw [r10-0x98], r4
  stxdw [r10-0xb0], r5
  mov64 r4, r0
  rsh64 r4, 0x1
  lddw r5, 0x2710000000
  add64 r4, r5
  stxdw [r10-0xa8], r0
  div64 r4, r0
  stxdw [r10-0xa0], r4
  jlt r2, r3, jmp_13340
  mov64 r5, r2
  sub64 r5, r3
  rsh64 r5, 0x1
  mov64 r4, r3
  add64 r4, r5
  mov64 r5, 0x1
  jlt r4, r3, jmp_128a8
  mov64 r5, 0x0

jmp_128a8:
  and64 r5, 0x1
  jne r5, 0x0, jmp_13358
  jeq r4, 0x0, jmp_12a20
  mov64 r5, r4
  rsh64 r5, 0x1
  mov64 r3, r4
  or64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x2
  or64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x4
  or64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x8
  or64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x10
  or64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x20
  or64 r3, r5
  xor64 r3, -0x1
  lddw r5, 0x5555555555555555
  mov64 r0, r3
  rsh64 r0, 0x1
  and64 r0, r5
  sub64 r3, r0
  lddw r0, 0x3333333333333333
  mov64 r5, r3
  and64 r5, r0
  rsh64 r3, 0x2
  and64 r3, r0
  add64 r5, r3
  mov64 r3, r5
  rsh64 r3, 0x4
  add64 r5, r3
  lddw r3, 0xf0f0f0f0f0f0f0f
  and64 r5, r3
  lddw r3, 0x101010101010101
  mul64 r5, r3
  rsh64 r5, 0x38
  ja jmp_12a28

jmp_12a20:
  mov64 r5, 0x40

jmp_12a28:
  mov64 r0, 0x28
  sub64 r0, r5
  mov64 r3, 0x0
  mov64 r5, 0x1
  jgt r0, 0x28, jmp_12a80
  mov64 r5, 0x0
  jeq r5, 0x0, jmp_12a88

jmp_12a60:
  mov64 r5, r4
  rsh64 r5, r3
  jne r5, 0x0, jmp_12aa8
  ja jmp_13178

jmp_12a80:
  jne r5, 0x0, jmp_12a60

jmp_12a88:
  mov64 r3, r0
  mov64 r5, r4
  rsh64 r5, r3
  jeq r5, 0x0, jmp_13178

jmp_12aa8:
  stxw [r10-0x78], r3
  stxdw [r10-0x90], r4
  mov64 r3, r5
  rsh64 r3, 0x1
  lddw r4, 0x2710000000
  add64 r3, r4
  stxdw [r10-0x88], r5
  div64 r3, r5
  stxdw [r10-0x80], r3
  jeq r2, 0x0, jmp_12c60
  mov64 r4, r2
  rsh64 r4, 0x1
  mov64 r3, r2
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x2
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x4
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x8
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x10
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x20
  or64 r3, r4
  xor64 r3, -0x1
  lddw r4, 0x5555555555555555
  mov64 r5, r3
  rsh64 r5, 0x1
  and64 r5, r4
  sub64 r3, r5
  lddw r5, 0x3333333333333333
  mov64 r4, r3
  and64 r4, r5
  rsh64 r3, 0x2
  and64 r3, r5
  add64 r4, r3
  mov64 r3, r4
  rsh64 r3, 0x4
  add64 r4, r3
  lddw r3, 0xf0f0f0f0f0f0f0f
  and64 r4, r3
  lddw r3, 0x101010101010101
  mul64 r4, r3
  rsh64 r4, 0x38
  ja jmp_12c68

jmp_12c60:
  mov64 r4, 0x40

jmp_12c68:
  mov64 r5, 0x28
  sub64 r5, r4
  mov64 r3, 0x0
  mov64 r4, 0x1
  jgt r5, 0x28, jmp_13150
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_13158

jmp_12ca0:
  mov64 r4, r2
  rsh64 r4, r3
  jeq r4, 0x0, jmp_13178

jmp_12cb8:
  stxw [r10-0x58], r3
  stxdw [r10-0x70], r2
  mov64 r2, r4
  rsh64 r2, 0x1
  lddw r3, 0x2710000000
  add64 r2, r3
  stxdw [r10-0x68], r4
  div64 r2, r4
  stxdw [r10-0x60], r2
  jge r8, 0xb, jmp_131b8
  mov64 r3, 0x0
  mov64 r4, r10
  add64 r4, -0x168
  lsh64 r8, 0x4

jmp_12d30:
  mov64 r5, 0x0
  jlt r3, r1, jmp_12d58
  mov64 r5, 0x1
  jeq r1, r3, jmp_12d58
  mov64 r5, 0x2

jmp_12d58:
  ldxdw r2, [r4+0x0]
  jgt r2, 0x9, jmp_13258
  lsh64 r2, 0x3
  mov64 r0, r10
  add64 r0, -0x50
  add64 r0, r2
  stxdw [r0+0x0], r5
  add64 r3, 0x1
  add64 r4, 0x10
  add64 r8, -0x10
  jne r8, 0x0, jmp_12d30

jmp_12db0:
  mov64 r8, 0x0
  mov64 r9, r7
  add64 r9, 0x90
  add64 r7, 0x68
  ldxdw r1, [r10-0x178]
  ldxh r1, [r1+0x58]
  mov64 r5, r1
  mov64 r6, 0x0
  stxdw [r10-0x180], r5
  ja jmp_12e38

jmp_12e00:
  mov64 r1, 0x20

jmp_12e08:
  stxh [r9+0x0], r1

jmp_12e10:
  add64 r6, 0x8
  add64 r8, 0x1
  add64 r7, 0x4
  add64 r9, 0x2
  jeq r6, 0x50, jmp_119f0

jmp_12e38:
  mov64 r2, r5
  rsh64 r2, r8
  mov64 r1, r10
  add64 r1, -0x50
  and64 r2, 0x1
  jeq r2, 0x0, jmp_12e10
  ldxdw r2, [r10-0x178]
  add64 r2, r6
  ldxdw r2, [r2+0x0]
  jeq r2, 0x0, jmp_12e10
  add64 r1, r6
  ldxdw r1, [r1+0x0]
  jge r1, 0x4, jmp_13298
  lsh64 r1, 0x5
  mov64 r3, r10
  add64 r3, -0xd0
  add64 r3, r1
  ldxw r1, [r3+0x18]
  jgt r1, 0x3f, jmp_132b8
  ldxdw r4, [r3+0x0]
  jgt r2, r4, jmp_12f10
  sub64 r4, r2
  mov64 r2, r4
  rsh64 r2, r1
  ldxdw r1, [r3+0x8]
  jge r1, r2, jmp_12f30
  ja jmp_12f38

jmp_12f10:
  sub64 r2, r4
  rsh64 r2, r1
  ldxdw r1, [r3+0x8]
  jlt r1, r2, jmp_12f38

jmp_12f30:
  mov64 r1, r2

jmp_12f38:
  ldxdw r3, [r3+0x10]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_156e0
  mov64 r2, 0x1
  jne r1, 0x0, jmp_12f70
  mov64 r2, 0x0

jmp_12f70:
  and64 r2, 0x1
  jne r2, 0x0, jmp_13280
  mov64 r2, 0x40000
  jgt r0, 0x40000fff, jmp_12fa0
  rsh64 r0, 0xc
  mov64 r2, r0

jmp_12fa0:
  ldxh r1, [r9+0x0]
  jeq r1, 0x0, jmp_13080
  ldxw r1, [r7+0x0]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  ldxdw r5, [r10-0x180]
  jge r3, r1, jmp_130b8
  mov64 r3, r1
  sub64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  add64 r3, 0x40
  mov64 r2, r3
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, r3, jmp_13328
  lddw r2, 0xffffff80
  and64 r3, r2
  rsh64 r3, 0x7
  jlt r1, r3, jmp_13310
  sub64 r1, r3
  stxw [r7+0x0], r1
  ldxh r1, [r9+0x0]
  add64 r1, 0x1
  jlt r1, 0x20, jmp_12e08
  ja jmp_12e00

jmp_13080:
  mov64 r1, r2
  ldxdw r5, [r10-0x180]
  stxw [r7+0x0], r1
  ldxh r1, [r9+0x0]
  add64 r1, 0x1
  jge r1, 0x20, jmp_12e00
  ja jmp_12e08

jmp_130b8:
  sub64 r2, r1
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  add64 r2, 0x40
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, r2, jmp_132f8
  lddw r3, 0xffffff80
  and64 r2, r3
  rsh64 r2, 0x7
  add64 r2, r1
  mov64 r1, r2
  stxw [r7+0x0], r1
  ldxh r1, [r9+0x0]
  add64 r1, 0x1
  jlt r1, 0x20, jmp_12e08
  ja jmp_12e00

jmp_13150:
  jne r4, 0x0, jmp_12ca0

jmp_13158:
  mov64 r3, r5
  mov64 r4, r2
  rsh64 r4, r3
  jne r4, 0x0, jmp_12cb8

jmp_13178:
  lddw r1, data_0ad0
  call fn_14350

jmp_13190:
  mov64 r1, r8
  mov64 r2, 0xa
  lddw r3, data_0968
  call fn_14328

jmp_131b8:
  mov64 r1, r8
  mov64 r2, 0xa
  lddw r3, data_09c8
  call fn_14328

jmp_131e0:
  add64 r1, -0x1
  mov64 r2, 0xa
  lddw r3, data_0a58
  call fn_14310

jmp_13208:
  mov64 r1, 0xa
  mov64 r2, 0xa
  lddw r3, data_0a88
  call fn_14310

jmp_13230:
  mov64 r1, r2
  mov64 r2, 0xa
  lddw r3, data_0980
  call fn_14310

jmp_13258:
  mov64 r1, r2
  mov64 r2, 0xa
  lddw r3, data_0a40
  call fn_14310

jmp_13280:
  lddw r1, data_0b00
  call fn_14350

jmp_13298:
  mov64 r2, 0x4
  lddw r3, data_09e0
  call fn_14310

jmp_132b8:
  lddw r1, data_0ae8
  call fn_14350

jmp_132d0:
  mov64 r1, 0xa
  mov64 r2, 0xa
  lddw r3, data_0a70
  call fn_14310

jmp_132f8:
  lddw r1, data_0a28
  call fn_14350

jmp_13310:
  lddw r1, data_0a10
  call fn_14350

jmp_13328:
  lddw r1, data_09f8
  call fn_14350

jmp_13340:
  lddw r1, data_0aa0
  call fn_14350

jmp_13358:
  lddw r1, data_0ab8
  call fn_14350

jmp_13370:
  mov64 r2, 0xa
  lddw r3, data_0950
  call fn_14310

jmp_13390:
  mov64 r2, 0xa
  lddw r3, data_0998
  call fn_14310

jmp_133b0:
  mov64 r1, 0xa
  mov64 r2, 0xa
  lddw r3, data_09b0
  call fn_14310

fn_133d8:
  mov64 r4, 0x40000
  ldxh r9, [r1+0x90]
  ldxb r6, [r2+0xe1]
  jne r6, 0x1, jmp_13420
  mov64 r3, r9
  jeq r3, 0x0, jmp_13420
  ldxw r4, [r1+0x68]
  jlt r4, 0x40000, jmp_13420
  mov64 r4, 0x40000

jmp_13420:
  ldxh r5, [r1+0x92]
  ldxb r3, [r2+0x161]
  stxdw [r10-0x40], r5
  jne r3, 0x1, jmp_13468
  jeq r5, 0x0, jmp_13468
  ldxw r5, [r1+0x6c]
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jlt r5, r4, jmp_13470

jmp_13468:
  mov64 r5, r4

jmp_13470:
  ldxh r4, [r1+0x94]
  ldxb r0, [r2+0x1e1]
  stxdw [r10-0x48], r4
  jne r0, 0x1, jmp_134b8
  jeq r4, 0x0, jmp_134b8
  ldxw r8, [r1+0x70]
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jlt r8, r5, jmp_134c0

jmp_134b8:
  mov64 r8, r5

jmp_134c0:
  ldxh r4, [r1+0x96]
  ldxb r5, [r2+0x261]
  stxdw [r10-0x8], r5
  stxdw [r10-0x50], r4
  jne r5, 0x1, jmp_13518
  mov64 r5, r4
  jeq r5, 0x0, jmp_13518
  ldxw r5, [r1+0x74]
  lsh64 r8, 0x20
  rsh64 r8, 0x20
  jlt r5, r8, jmp_13520

jmp_13518:
  mov64 r5, r8

jmp_13520:
  ldxh r4, [r1+0x98]
  ldxb r7, [r2+0x2e1]
  stxdw [r10-0x10], r7
  stxdw [r10-0x58], r4
  jne r7, 0x1, jmp_13578
  mov64 r7, r4
  jeq r7, 0x0, jmp_13578
  ldxw r7, [r1+0x78]
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jlt r7, r5, jmp_13580

jmp_13578:
  mov64 r7, r5

jmp_13580:
  ldxh r8, [r1+0x9a]
  ldxb r4, [r2+0x361]
  stxdw [r10-0x18], r4
  jne r4, 0x1, jmp_135d0
  mov64 r5, r8
  jeq r5, 0x0, jmp_135d0
  ldxw r5, [r1+0x7c]
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jlt r5, r7, jmp_135d8

jmp_135d0:
  mov64 r5, r7

jmp_135d8:
  ldxh r4, [r1+0x9c]
  ldxb r7, [r2+0x3e1]
  stxdw [r10-0x20], r7
  stxdw [r10-0x68], r4
  stxdw [r10-0x60], r8
  jne r7, 0x1, jmp_13638
  mov64 r7, r4
  jeq r7, 0x0, jmp_13638
  ldxw r7, [r1+0x80]
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jlt r7, r5, jmp_13640

jmp_13638:
  mov64 r7, r5

jmp_13640:
  ldxh r8, [r1+0x9e]
  ldxb r4, [r2+0x461]
  stxdw [r10-0x28], r4
  jne r4, 0x1, jmp_13690
  mov64 r5, r8
  jeq r5, 0x0, jmp_13690
  ldxw r5, [r1+0x84]
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jlt r5, r7, jmp_13698

jmp_13690:
  mov64 r5, r7

jmp_13698:
  ldxh r4, [r1+0xa0]
  ldxb r7, [r2+0x4e1]
  stxdw [r10-0x30], r7
  stxdw [r10-0x78], r4
  stxdw [r10-0x70], r8
  jne r7, 0x1, jmp_136f8
  mov64 r7, r4
  jeq r7, 0x0, jmp_136f8
  ldxw r7, [r1+0x88]
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jlt r7, r5, jmp_13700

jmp_136f8:
  mov64 r7, r5

jmp_13700:
  ldxh r8, [r1+0xa2]
  ldxb r2, [r2+0x561]
  stxdw [r10-0x38], r2
  jne r2, 0x1, jmp_13750
  mov64 r2, r8
  jeq r2, 0x0, jmp_13750
  ldxw r2, [r1+0x8c]
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jlt r2, r7, jmp_13758

jmp_13750:
  mov64 r2, r7

jmp_13758:
  mov64 r5, 0x0
  mov64 r7, 0x0
  jeq r6, 0x0, jmp_13860
  mov64 r6, r9
  jeq r6, 0x0, jmp_13978
  ldxw r9, [r1+0x68]
  mov64 r7, r2
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  jlt r9, r7, jmp_142e0
  ldxb r7, [r1+0xba]
  jge r7, 0x20, jmp_142f8
  sub64 r9, r2
  jlt r6, 0x20, jmp_137d0
  mov64 r6, 0x20

jmp_137d0:
  mov64 r4, r8
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  rsh64 r9, r7
  jlt r9, 0x8, jmp_13800
  mov64 r9, 0x8

jmp_13800:
  mov64 r7, 0x100
  mov64 r8, 0x100
  rsh64 r8, r9
  mov64 r9, 0x100
  sub64 r9, r8
  mul64 r9, r6
  lddw r6, 0xffffffe0
  and64 r9, r6
  rsh64 r9, 0x5
  sub64 r7, r9
  mov64 r8, r4

jmp_13860:
  stxh [r1+0xa4], r7
  jeq r3, 0x0, jmp_13990

jmp_13870:
  ldxdw r3, [r10-0x40]
  jeq r3, 0x0, jmp_13ab8
  ldxw r6, [r1+0x6c]
  mov64 r5, r2
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  jlt r6, r5, jmp_142e0
  ldxb r5, [r1+0xba]
  jgt r5, 0x1f, jmp_142f8
  sub64 r6, r2
  jlt r3, 0x20, jmp_138d0
  mov64 r3, 0x20

jmp_138d0:
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  rsh64 r6, r5
  jlt r6, 0x8, jmp_138f8
  mov64 r6, 0x8

jmp_138f8:
  mov64 r5, 0x100
  mov64 r7, 0x100
  rsh64 r7, r6
  mov64 r6, 0x100
  sub64 r6, r7
  mul64 r6, r3
  lddw r3, 0xffffffe0
  and64 r6, r3
  rsh64 r6, 0x5
  sub64 r5, r6
  stxh [r1+0xa6], r5
  mov64 r3, 0x0
  mov64 r6, 0x0
  jne r0, 0x0, jmp_139b0
  ja jmp_13ae0

jmp_13978:
  mov64 r7, 0x100
  stxh [r1+0xa4], r7
  jne r3, 0x0, jmp_13870

jmp_13990:
  stxh [r1+0xa6], r5
  mov64 r3, 0x0
  mov64 r6, 0x0
  jeq r0, 0x0, jmp_13ae0

jmp_139b0:
  ldxdw r4, [r10-0x48]
  mov64 r5, r4
  jeq r5, 0x0, jmp_13be8
  ldxw r0, [r1+0x70]
  mov64 r6, r2
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  jlt r0, r6, jmp_142e0
  ldxb r6, [r1+0xba]
  jgt r6, 0x1f, jmp_142f8
  sub64 r0, r2
  jlt r5, 0x20, jmp_13a18
  mov64 r5, 0x20

jmp_13a18:
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  rsh64 r0, r6
  jlt r0, 0x8, jmp_13a40
  mov64 r0, 0x8

jmp_13a40:
  mov64 r6, 0x100
  mov64 r7, 0x100
  rsh64 r7, r0
  mov64 r0, 0x100
  sub64 r0, r7
  mul64 r0, r5
  lddw r5, 0xffffffe0
  and64 r0, r5
  rsh64 r0, 0x5
  sub64 r6, r0
  stxh [r1+0xa8], r6
  ldxdw r4, [r10-0x8]
  jne r4, 0x0, jmp_13af8
  ja jmp_13c18

jmp_13ab8:
  mov64 r5, 0x100
  stxh [r1+0xa6], r5
  mov64 r3, 0x0
  mov64 r6, 0x0
  jne r0, 0x0, jmp_139b0

jmp_13ae0:
  stxh [r1+0xa8], r6
  ldxdw r4, [r10-0x8]
  jeq r4, 0x0, jmp_13c18

jmp_13af8:
  ldxdw r3, [r10-0x50]
  mov64 r4, r3
  jeq r4, 0x0, jmp_13c10
  ldxw r5, [r1+0x74]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r5, r3, jmp_142e0
  ldxb r3, [r1+0xba]
  jgt r3, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_13b60
  mov64 r4, 0x20

jmp_13b60:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r3
  jlt r5, 0x8, jmp_13b88
  mov64 r5, 0x8

jmp_13b88:
  mov64 r3, 0x100
  mov64 r0, 0x100
  rsh64 r0, r5
  mov64 r5, 0x100
  sub64 r5, r0
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r3, r5
  ja jmp_13c18

jmp_13be8:
  mov64 r6, 0x100
  stxh [r1+0xa8], r6
  ldxdw r4, [r10-0x8]
  jne r4, 0x0, jmp_13af8
  ja jmp_13c18

jmp_13c10:
  mov64 r3, 0x100

jmp_13c18:
  stxh [r1+0xaa], r3
  mov64 r3, 0x0
  mov64 r0, 0x0
  ldxdw r4, [r10-0x10]
  jeq r4, 0x0, jmp_13d20
  ldxdw r4, [r10-0x58]
  jeq r4, 0x0, jmp_13e28
  ldxw r5, [r1+0x78]
  mov64 r0, r2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jlt r5, r0, jmp_142e0
  ldxb r0, [r1+0xba]
  jgt r0, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_13ca0
  mov64 r4, 0x20

jmp_13ca0:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r0
  jlt r5, 0x8, jmp_13cc8
  mov64 r5, 0x8

jmp_13cc8:
  mov64 r0, 0x100
  mov64 r6, 0x100
  rsh64 r6, r5
  mov64 r5, 0x100
  sub64 r5, r6
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r0, r5

jmp_13d20:
  stxh [r1+0xac], r0
  ldxdw r4, [r10-0x18]
  jeq r4, 0x0, jmp_13e58

jmp_13d38:
  ldxdw r3, [r10-0x60]
  mov64 r4, r3
  jeq r4, 0x0, jmp_13e50
  ldxw r5, [r1+0x7c]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r5, r3, jmp_142e0
  ldxb r3, [r1+0xba]
  jgt r3, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_13da0
  mov64 r4, 0x20

jmp_13da0:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r3
  jlt r5, 0x8, jmp_13dc8
  mov64 r5, 0x8

jmp_13dc8:
  mov64 r3, 0x100
  mov64 r0, 0x100
  rsh64 r0, r5
  mov64 r5, 0x100
  sub64 r5, r0
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r3, r5
  ja jmp_13e58

jmp_13e28:
  mov64 r0, 0x100
  stxh [r1+0xac], r0
  ldxdw r4, [r10-0x18]
  jne r4, 0x0, jmp_13d38
  ja jmp_13e58

jmp_13e50:
  mov64 r3, 0x100

jmp_13e58:
  stxh [r1+0xae], r3
  mov64 r3, 0x0
  mov64 r0, 0x0
  ldxdw r4, [r10-0x20]
  jeq r4, 0x0, jmp_13f60
  ldxdw r4, [r10-0x68]
  jeq r4, 0x0, jmp_14068
  ldxw r5, [r1+0x80]
  mov64 r0, r2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jlt r5, r0, jmp_142e0
  ldxb r0, [r1+0xba]
  jgt r0, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_13ee0
  mov64 r4, 0x20

jmp_13ee0:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r0
  jlt r5, 0x8, jmp_13f08
  mov64 r5, 0x8

jmp_13f08:
  mov64 r0, 0x100
  mov64 r6, 0x100
  rsh64 r6, r5
  mov64 r5, 0x100
  sub64 r5, r6
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r0, r5

jmp_13f60:
  stxh [r1+0xb0], r0
  ldxdw r4, [r10-0x28]
  jeq r4, 0x0, jmp_14098

jmp_13f78:
  ldxdw r3, [r10-0x70]
  mov64 r4, r3
  jeq r4, 0x0, jmp_14090
  ldxw r5, [r1+0x84]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r5, r3, jmp_142e0
  ldxb r3, [r1+0xba]
  jgt r3, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_13fe0
  mov64 r4, 0x20

jmp_13fe0:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r3
  jlt r5, 0x8, jmp_14008
  mov64 r5, 0x8

jmp_14008:
  mov64 r3, 0x100
  mov64 r0, 0x100
  rsh64 r0, r5
  mov64 r5, 0x100
  sub64 r5, r0
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r3, r5
  ja jmp_14098

jmp_14068:
  mov64 r0, 0x100
  stxh [r1+0xb0], r0
  ldxdw r4, [r10-0x28]
  jne r4, 0x0, jmp_13f78
  ja jmp_14098

jmp_14090:
  mov64 r3, 0x100

jmp_14098:
  stxh [r1+0xb2], r3
  mov64 r3, 0x0
  mov64 r0, 0x0
  ldxdw r4, [r10-0x30]
  jeq r4, 0x0, jmp_141a0
  ldxdw r4, [r10-0x78]
  jeq r4, 0x0, jmp_142a0
  ldxw r5, [r1+0x88]
  mov64 r0, r2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jlt r5, r0, jmp_142e0
  ldxb r0, [r1+0xba]
  jgt r0, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_14120
  mov64 r4, 0x20

jmp_14120:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r0
  jlt r5, 0x8, jmp_14148
  mov64 r5, 0x8

jmp_14148:
  mov64 r0, 0x100
  mov64 r6, 0x100
  rsh64 r6, r5
  mov64 r5, 0x100
  sub64 r5, r6
  mul64 r5, r4
  lddw r4, 0xffffffe0
  and64 r5, r4
  rsh64 r5, 0x5
  sub64 r0, r5

jmp_141a0:
  stxh [r1+0xb4], r0
  ldxdw r4, [r10-0x38]
  jeq r4, 0x0, jmp_142d0

jmp_141b8:
  mov64 r4, r8
  jeq r4, 0x0, jmp_142c8
  ldxw r5, [r1+0x8c]
  mov64 r3, r2
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jlt r5, r3, jmp_142e0
  ldxb r3, [r1+0xba]
  jgt r3, 0x1f, jmp_142f8
  sub64 r5, r2
  jlt r4, 0x20, jmp_14218
  mov64 r4, 0x20

jmp_14218:
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  rsh64 r5, r3
  jlt r5, 0x8, jmp_14240
  mov64 r5, 0x8

jmp_14240:
  mov64 r3, 0x100
  mov64 r2, 0x100
  rsh64 r2, r5
  mov64 r5, 0x100
  sub64 r5, r2
  mul64 r5, r4
  lddw r2, 0xffffffe0
  and64 r5, r2
  rsh64 r5, 0x5
  sub64 r3, r5
  ja jmp_142d0

jmp_142a0:
  mov64 r0, 0x100
  stxh [r1+0xb4], r0
  ldxdw r4, [r10-0x38]
  jne r4, 0x0, jmp_141b8
  ja jmp_142d0

jmp_142c8:
  mov64 r3, 0x100

jmp_142d0:
  stxh [r1+0xb6], r3
  exit

jmp_142e0:
  lddw r1, data_0920
  call fn_14350

jmp_142f8:
  lddw r1, data_0938
  call fn_14350

fn_14310:
  mov64 r1, r3
  call fn_14320

fn_14320:
  call fn_bab0

fn_14328:
  mov64 r1, r3
  call fn_14320

fn_14338:
  lddw r1, data_0818
  call fn_14320

fn_14350:
  call fn_14320

fn_14358:
  call fn_14338

fn_14360:
  lddw r1, data_0878
  call fn_14320

fn_14378:
  and64 r1, 0xff
  jsle r1, 0x1, jmp_143b0
  jeq r1, 0x2, jmp_143d0
  jne r1, 0x3, jmp_143e8
  lddw r1, data_0b60
  call fn_14320

jmp_143b0:
  jne r1, 0x0, jmp_14400
  lddw r1, data_0b18
  call fn_14320

jmp_143d0:
  lddw r1, data_0b48
  call fn_14320

jmp_143e8:
  lddw r1, data_0b78
  call fn_14320

jmp_14400:
  lddw r1, data_0b30
  call fn_14320

fn_14418:
  mov64 r0, 0x0
  ja jmp_14458

jmp_14428:
  lddw r5, data_056a
  add64 r5, r4
  add64 r0, 0x1
  ldxb r4, [r5+0x0]
  jeq r4, 0xff, jmp_155a8

jmp_14458:
  jeq r3, r0, jmp_14498
  mov64 r4, r2
  add64 r4, r0
  ldxb r4, [r4+0x0]
  add64 r4, -0x31
  jlt r4, 0x4a, jmp_14428
  mov64 r4, 0x4a
  ja jmp_14428

jmp_14498:
  mov64 r7, 0x2d
  sub64 r7, r3
  mov64 r5, r2
  add64 r5, r3
  mov64 r0, 0x0
  add64 r5, -0x2d
  stdw [r10-0xb], 0x0
  stdw [r10-0x10], 0x0
  stdw [r10-0x18], 0x0
  stdw [r10-0x20], 0x0
  stdw [r10-0x28], 0x0
  stdw [r10-0x30], 0x0
  ja jmp_14550

jmp_14500:
  lddw r6, data_056a
  add64 r6, r4
  ldxb r4, [r6+0x0]

jmp_14520:
  mov64 r6, r10
  add64 r6, -0x30
  add64 r6, r0
  stxb [r6+0x0], r4
  add64 r0, 0x1
  jeq r0, 0x2d, jmp_145e0

jmp_14550:
  mov64 r4, 0x0
  jlt r0, r7, jmp_14520
  mov64 r4, r3
  add64 r4, r0
  add64 r4, -0x2d
  jge r4, r3, jmp_155d0
  mov64 r4, r5
  add64 r4, r0
  ldxb r4, [r4+0x0]
  jlt r4, 0x31, jmp_155b8
  add64 r4, -0x31
  and64 r4, 0xff
  jlt r4, 0x4b, jmp_14500
  mov64 r1, r4
  mov64 r2, 0x4b
  lddw r3, data_0bf0
  call fn_14310

jmp_145e0:
  mov64 r4, r1
  stxdw [r10-0x70], r2
  ldxb r1, [r10-0x2f]
  mul64 r1, 0x2fa28
  ldxb r2, [r10-0x30]
  mul64 r2, 0xacad10
  add64 r2, r1
  ldxb r1, [r10-0x2e]
  mul64 r1, 0xd24
  add64 r2, r1
  ldxb r1, [r10-0x2b]
  mul64 r1, 0xacad10
  ldxb r0, [r10-0x2a]
  mul64 r0, 0x2fa28
  add64 r0, r1
  ldxb r1, [r10-0x2d]
  mul64 r1, 0x3a
  add64 r2, r1
  ldxb r1, [r10-0x25]
  mul64 r1, 0x2fa28
  ldxb r5, [r10-0x26]
  mul64 r5, 0xacad10
  add64 r5, r1
  ldxb r1, [r10-0x2c]
  add64 r2, r1
  ldxb r1, [r10-0x29]
  mul64 r1, 0xd24
  add64 r0, r1
  ldxb r1, [r10-0x28]
  mul64 r1, 0x3a
  add64 r0, r1
  ldxb r1, [r10-0x27]
  add64 r0, r1
  lddw r1, 0xb5a6d367
  stxdw [r10-0x60], r0
  mul64 r0, r1
  mov64 r3, r2
  mul64 r3, 0x7ba4a062
  add64 r3, r0
  ldxb r1, [r10-0x24]
  mul64 r1, 0xd24
  add64 r5, r1
  ldxb r1, [r10-0x23]
  mul64 r1, 0x3a
  add64 r5, r1
  ldxb r1, [r10-0x22]
  add64 r5, r1
  lddw r1, 0xb2a25e00
  stxdw [r10-0x58], r5
  mov64 r0, r5
  mul64 r0, r1
  mov64 r1, r3
  add64 r1, r0
  mov64 r0, 0x1
  jlt r1, r3, jmp_147b0
  mov64 r0, 0x0

jmp_147b0:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  ldxb r3, [r10-0x21]
  mul64 r3, 0xacad10
  ldxb r7, [r10-0x20]
  mul64 r7, 0x2fa28
  add64 r7, r3
  ldxb r3, [r10-0x1f]
  mul64 r3, 0xd24
  add64 r7, r3
  ldxb r3, [r10-0x1e]
  mul64 r3, 0x3a
  add64 r7, r3
  ldxb r3, [r10-0x1d]
  add64 r7, r3
  mov64 r3, r7
  mul64 r3, 0x5765d
  mov64 r5, r1
  add64 r5, r3
  mov64 r3, 0x1
  stxdw [r10-0x68], r5
  jlt r5, r1, jmp_14868
  mov64 r3, 0x0

jmp_14868:
  and64 r3, 0x1
  jne r3, 0x0, jmp_155f8
  lddw r1, 0xcbc0907d
  ldxdw r3, [r10-0x60]
  mul64 r3, r1
  lddw r1, 0xc19c48e6
  mov64 r5, r2
  mul64 r5, r1
  mov64 r1, r5
  add64 r1, r3
  mov64 r3, 0x1
  jlt r1, r5, jmp_148e0
  mov64 r3, 0x0

jmp_148e0:
  and64 r3, 0x1
  jne r3, 0x0, jmp_155f8
  ldxdw r5, [r10-0x58]
  mul64 r5, 0x6d5a3847
  mov64 r3, r1
  add64 r3, r5
  mov64 r0, 0x1
  jlt r3, r1, jmp_14928
  mov64 r0, 0x0

jmp_14928:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  mov64 r5, r7
  mul64 r5, 0x5809369c
  mov64 r1, r3
  add64 r1, r5
  mov64 r0, 0x1
  jlt r1, r3, jmp_14970
  mov64 r0, 0x0

jmp_14970:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  ldxb r3, [r10-0x1c]
  ldxb r9, [r10-0x1b]
  mul64 r3, 0xacad10
  mul64 r9, 0x2fa28
  ldxb r5, [r10-0x1a]
  add64 r9, r3
  mul64 r5, 0xd24
  ldxb r3, [r10-0x19]
  add64 r9, r5
  mul64 r3, 0x3a
  add64 r9, r3
  ldxb r3, [r10-0x18]
  add64 r9, r3
  mov64 r3, r9
  mul64 r3, 0x23be67
  mov64 r5, r1
  add64 r5, r3
  mov64 r3, 0x1
  stxdw [r10-0x78], r5
  jlt r5, r1, jmp_14a28
  mov64 r3, 0x0

jmp_14a28:
  and64 r3, 0x1
  jne r3, 0x0, jmp_155f8
  lddw r1, 0xec548c47
  ldxdw r3, [r10-0x58]
  mul64 r3, r1
  ldxdw r1, [r10-0x60]
  mul64 r1, 0x7e6a558
  mov64 r5, r2
  mul64 r5, 0x28f6af73
  add64 r5, r1
  add64 r5, r3
  lddw r1, 0xc6e94dde
  mov64 r3, r7
  mul64 r3, r1
  mov64 r1, r5
  add64 r1, r3
  mov64 r3, 0x1
  jlt r1, r5, jmp_14ad0
  mov64 r3, 0x0

jmp_14ad0:
  and64 r3, 0x1
  jne r3, 0x0, jmp_155f8
  lddw r3, 0xb5f0f288
  mov64 r5, r9
  mul64 r5, r3
  mov64 r3, r1
  add64 r3, r5
  mov64 r0, 0x1
  jlt r3, r1, jmp_14b28
  mov64 r0, 0x0

jmp_14b28:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  ldxb r5, [r10-0x17]
  ldxb r1, [r10-0x16]
  mul64 r5, 0xacad10
  mul64 r1, 0x2fa28
  ldxb r0, [r10-0x15]
  add64 r1, r5
  mul64 r0, 0xd24
  ldxb r5, [r10-0x14]
  add64 r1, r0
  mul64 r5, 0x3a
  add64 r1, r5
  ldxb r5, [r10-0x13]
  add64 r1, r5
  mov64 r5, r1
  mul64 r5, 0xe9e506
  mov64 r6, r3
  add64 r6, r5
  mov64 r0, 0x1
  stxdw [r10-0x80], r6
  jlt r6, r3, jmp_14be0
  mov64 r0, 0x0

jmp_14be0:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  lddw r3, 0xb0612100
  mov64 r0, r2
  mul64 r0, r3
  ldxdw r3, [r10-0x58]
  mul64 r3, 0x1ceaa75e
  add64 r0, r3
  ldxdw r3, [r10-0x60]
  mul64 r3, 0x4778de28
  mov64 r5, r7
  mul64 r5, 0x5869f408
  add64 r3, r5
  add64 r0, r3
  lddw r3, 0x9aaf5053
  mov64 r5, r9
  mul64 r5, r3
  mov64 r3, r0
  add64 r3, r5
  mov64 r6, 0x1
  jlt r3, r0, jmp_14ca0
  mov64 r6, 0x0

jmp_14ca0:
  and64 r6, 0x1
  jne r6, 0x0, jmp_155f8
  mov64 r5, r1
  mul64 r5, 0x734501d8
  mov64 r0, r3
  add64 r0, r5
  mov64 r6, 0x1
  jlt r0, r3, jmp_14ce8
  mov64 r6, 0x0

jmp_14ce8:
  and64 r6, 0x1
  jne r6, 0x0, jmp_155f8
  ldxb r5, [r10-0x12]
  ldxb r3, [r10-0x11]
  mul64 r5, 0xacad10
  mul64 r3, 0x2fa28
  ldxb r6, [r10-0x10]
  add64 r3, r5
  mul64 r6, 0xd24
  ldxb r5, [r10-0xf]
  add64 r3, r6
  mul64 r5, 0x3a
  add64 r3, r5
  ldxb r5, [r10-0xe]
  add64 r3, r5
  mov64 r5, r3
  mul64 r5, 0x5fa8624
  mov64 r6, r0
  add64 r6, r5
  mov64 r8, 0x1
  jlt r6, r0, jmp_14d98
  mov64 r8, 0x0

jmp_14d98:
  and64 r8, 0x1
  jne r8, 0x0, jmp_155f8
  lddw r5, 0xf23a8000
  mul64 r1, r5
  lddw r5, 0xfa000000
  mul64 r7, r5
  ldxdw r5, [r10-0x58]
  lsh64 r5, 0x1e
  add64 r5, r7
  mul64 r9, 0x1100000
  add64 r5, r9
  mov64 r0, r5
  add64 r0, r1
  mov64 r1, 0x1
  jlt r0, r5, jmp_14e28
  mov64 r1, 0x0

jmp_14e28:
  and64 r1, 0x1
  jne r1, 0x0, jmp_155f8
  lddw r1, 0xc7fba400
  mul64 r3, r1
  mov64 r1, r0
  add64 r1, r3
  mov64 r3, 0x1
  jlt r1, r0, jmp_14e78
  mov64 r3, 0x0

jmp_14e78:
  and64 r3, 0x1
  jne r3, 0x0, jmp_155f8
  ldxb r3, [r10-0xd]
  ldxb r0, [r10-0xc]
  mul64 r3, 0xacad10
  mul64 r0, 0x2fa28
  ldxb r5, [r10-0xb]
  add64 r0, r3
  mul64 r5, 0xd24
  ldxb r3, [r10-0xa]
  add64 r0, r5
  mul64 r3, 0x3a
  add64 r0, r3
  ldxb r3, [r10-0x9]
  add64 r0, r3
  mul64 r0, 0x271f35a0
  mov64 r3, r1
  add64 r3, r0
  mov64 r0, 0x1
  jlt r3, r1, jmp_14f20
  mov64 r0, 0x0

jmp_14f20:
  and64 r0, 0x1
  jne r0, 0x0, jmp_155f8
  ldxb r5, [r10-0x8]
  ldxb r1, [r10-0x7]
  mul64 r5, 0xacad10
  mul64 r1, 0x2fa28
  ldxb r0, [r10-0x6]
  add64 r1, r5
  mul64 r0, 0xd24
  ldxb r5, [r10-0x5]
  add64 r1, r0
  mul64 r5, 0x3a
  add64 r1, r5
  ldxb r5, [r10-0x4]
  add64 r1, r5
  mov64 r5, r3
  add64 r5, r1
  mov64 r1, 0x1
  jlt r5, r3, jmp_14fc0
  mov64 r1, 0x0

jmp_14fc0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_155f8
  mov64 r3, r5
  rsh64 r3, 0x20
  mov64 r1, r6
  add64 r1, r3
  mov64 r3, 0x1
  mov64 r7, r1
  jlt r1, r6, jmp_15010
  mov64 r3, 0x0

jmp_15010:
  and64 r3, 0x1
  jne r3, 0x0, jmp_15620
  mov64 r3, r7
  rsh64 r3, 0x20
  ldxdw r1, [r10-0x80]
  mov64 r9, r1
  add64 r9, r3
  mov64 r3, 0x1
  jlt r9, r1, jmp_15060
  mov64 r3, 0x0

jmp_15060:
  and64 r3, 0x1
  jne r3, 0x0, jmp_15620
  mov64 r3, r9
  rsh64 r3, 0x20
  ldxdw r1, [r10-0x78]
  mov64 r0, r1
  add64 r0, r3
  mov64 r3, 0x1
  jlt r0, r1, jmp_150b0
  mov64 r3, 0x0

jmp_150b0:
  and64 r3, 0x1
  jne r3, 0x0, jmp_15620
  mov64 r3, r0
  rsh64 r3, 0x20
  ldxdw r1, [r10-0x68]
  mov64 r6, r1
  add64 r6, r3
  mov64 r3, 0x1
  jlt r6, r1, jmp_15100
  mov64 r3, 0x0

jmp_15100:
  and64 r3, 0x1
  jne r3, 0x0, jmp_15620
  stxdw [r10-0x78], r0
  stxdw [r10-0x68], r5
  stxdw [r10-0x80], r4
  lddw r8, 0xe28ed535
  mov64 r3, r2
  mul64 r3, r8
  ldxdw r1, [r10-0x60]
  mov64 r8, r1
  mul64 r8, 0x469deca6
  lddw r5, 0x9df9dbf7
  add64 r3, r8
  mov64 r8, r2
  mul64 r8, r5
  mul64 r1, 0x20a8
  ldxdw r4, [r10-0x58]
  mul64 r4, 0xd5b2
  add64 r8, r1
  add64 r3, r4
  mul64 r2, 0x4fd
  mov64 r5, r6
  rsh64 r5, 0x20
  add64 r3, r5
  mov64 r5, r3
  rsh64 r5, 0x20
  add64 r8, r5
  mov64 r5, r8
  rsh64 r5, 0x20
  add64 r2, r5
  lddw r5, 0xffffffff
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r6
  jgt r2, r5, jmp_15638
  mov64 r0, r7
  stxdw [r10-0x88], r0
  mov64 r5, r0
  rsh64 r5, 0x18
  mov64 r1, r0
  rsh64 r1, 0x10
  rsh64 r0, 0x8
  mov64 r7, r9
  rsh64 r9, 0x18
  mov64 r2, r7
  rsh64 r2, 0x10
  mov64 r4, r7
  rsh64 r4, 0x8
  ldxdw r6, [r10-0x88]
  stxb [r10-0x35], r6
  stxb [r10-0x36], r0
  stxb [r10-0x37], r1
  stxb [r10-0x38], r5
  stxb [r10-0x39], r7
  stxb [r10-0x3a], r4
  stxb [r10-0x3b], r2
  stxb [r10-0x3c], r9
  ldxdw r2, [r10-0x68]
  mov64 r1, r2
  rsh64 r1, 0x8
  stxb [r10-0x32], r1
  mov64 r1, r2
  rsh64 r1, 0x10
  stxb [r10-0x33], r1
  stxb [r10-0x31], r2
  rsh64 r2, 0x18
  stxb [r10-0x34], r2
  ldxdw r2, [r10-0x78]
  mov64 r1, r2
  rsh64 r1, 0x8
  stxb [r10-0x3e], r1
  mov64 r1, r2
  rsh64 r1, 0x10
  stxb [r10-0x3f], r1
  stxb [r10-0x3d], r2
  rsh64 r2, 0x18
  stxb [r10-0x40], r2
  ldxdw r2, [r10-0x60]
  mov64 r1, r2
  rsh64 r1, 0x8
  stxb [r10-0x42], r1
  mov64 r1, r2
  rsh64 r1, 0x10
  stxb [r10-0x43], r1
  stxb [r10-0x41], r2
  rsh64 r2, 0x18
  stxb [r10-0x44], r2
  mov64 r1, r3
  rsh64 r1, 0x8
  stxb [r10-0x46], r1
  mov64 r1, r3
  rsh64 r1, 0x10
  stxb [r10-0x47], r1
  stxb [r10-0x45], r3
  rsh64 r3, 0x18
  stxb [r10-0x48], r3
  mov64 r1, r8
  rsh64 r1, 0x8
  stxb [r10-0x4a], r1
  mov64 r1, r8
  rsh64 r1, 0x10
  stxb [r10-0x4b], r1
  stxb [r10-0x49], r8
  rsh64 r8, 0x18
  stxb [r10-0x4c], r8
  ldxdw r2, [r10-0x58]
  mov64 r1, r2
  rsh64 r1, 0x8
  stxb [r10-0x4e], r1
  mov64 r5, 0x0
  mov64 r3, r10
  add64 r3, -0x4e
  mov64 r1, r2
  rsh64 r1, 0x10
  stxb [r10-0x4f], r1
  stxb [r10-0x4d], r2
  rsh64 r2, 0x18
  mov64 r7, r2
  stxb [r10-0x50], r2
  ldxdw r6, [r10-0x70]

jmp_154d0:
  mov64 r2, r10
  add64 r2, -0x50
  add64 r2, r5
  mov64 r4, r6
  add64 r4, r5
  ldxb r0, [r4+0x0]
  ldxb r2, [r2+0x0]
  jne r2, 0x0, jmp_15538
  mov64 r2, r0
  jne r2, 0x31, jmp_15610
  add64 r5, 0x1
  jne r5, 0x20, jmp_154d0
  ja jmp_15548

jmp_15538:
  mov64 r2, r0
  jeq r2, 0x31, jmp_15648

jmp_15548:
  ldxdw r2, [r3+0x16]
  ldxdw r4, [r10-0x80]
  stxdw [r4+0x18], r2
  ldxdw r2, [r3+0x10]
  stxdw [r4+0x12], r2
  ldxdw r2, [r3+0x8]
  stxdw [r4+0xa], r2
  ldxdw r2, [r3+0x0]
  stxdw [r4+0x2], r2
  stxb [r4+0x1], r1
  stxb [r4+0x0], r7
  exit

jmp_155a8:
  mov64 r1, 0x0
  call fn_14378

jmp_155b8:
  lddw r1, data_0bd8
  call fn_14350

jmp_155d0:
  mov64 r1, r4
  mov64 r2, r3
  lddw r3, data_0bc0
  call fn_14310

jmp_155f8:
  lddw r1, data_0ba8
  call fn_14350

jmp_15610:
  mov64 r1, 0x2
  call fn_14378

jmp_15620:
  lddw r1, data_0b90
  call fn_14350

jmp_15638:
  mov64 r1, 0x3
  call fn_14378

jmp_15648:
  mov64 r1, 0x4
  call fn_14378

fn_15658:
  mov64 r6, r1
  call sol_memcpy_
  mov64 r0, r6
  exit

fn_15678:
  mov64 r6, r1
  and64 r2, 0xff
  call sol_memset_
  mov64 r0, r6
  exit

fn_156a0:
  stw [r10-0x4], 0x0
  mov64 r4, r10
  add64 r4, -0x4
  call sol_memcmp_
  ldxw r0, [r10-0x4]
  lsh64 r0, 0x20
  arsh64 r0, 0x20
  exit

fn_156e0:
  stxdw [r10-0x10], r2
  mov64 r2, r1
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  mov64 r7, r3
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  stxdw [r10-0x8], r1
  rsh64 r1, 0x20
  mov64 r0, r7
  mul64 r0, r2
  mul64 r7, r1
  mov64 r5, r3
  rsh64 r5, 0x20
  mov64 r6, r5
  mul64 r6, r2
  mov64 r9, r6
  add64 r9, r7
  mov64 r2, 0x1
  mov64 r8, 0x1
  jlt r9, r6, jmp_15790
  mov64 r8, 0x0

jmp_15790:
  mov64 r6, r9
  lsh64 r6, 0x20
  mov64 r7, r0
  add64 r7, r6
  jlt r7, r0, jmp_157c0
  mov64 r2, 0x0

jmp_157c0:
  rsh64 r9, 0x20
  lsh64 r8, 0x20
  or64 r8, r9
  ldxdw r0, [r10-0x10]
  mul64 r3, r0
  ldxdw r0, [r10-0x8]
  mul64 r4, r0
  add64 r4, r3
  mul64 r5, r1
  add64 r5, r4
  add64 r5, r8
  add64 r5, r2
  mov64 r0, r7
  mov64 r1, r5
  exit

fn_15838:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r3, r2
  mov64 r2, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_15888
  ldxdw r1, [r10-0x18]
  ldxdw r0, [r10-0x20]
  exit

fn_15888:
  stxdw [r10-0x8], r5
  stxdw [r10-0x10], r4
  mov64 r9, r2
  mov64 r6, r1
  lddw r4, 0x5555555555555555
  lddw r8, 0x3333333333333333
  lddw r2, 0xf0f0f0f0f0f0f0f
  lddw r1, 0x101010101010101
  stxdw [r10-0x18], r3
  jne r3, 0x0, jmp_15bf8
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
  and64 r0, r4
  sub64 r5, r0
  mov64 r7, r5
  and64 r7, r8
  rsh64 r5, 0x2
  and64 r5, r8
  add64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x4
  add64 r7, r5
  and64 r7, r2
  mul64 r7, r1
  rsh64 r7, 0x38
  add64 r7, 0x40
  ldxdw r5, [r10-0x8]
  jeq r5, 0x0, jmp_15d20

jmp_15a28:
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
  and64 r0, r4
  sub64 r5, r0
  mov64 r4, r5
  rsh64 r4, 0x2
  and64 r5, r8
  and64 r4, r8
  add64 r5, r4
  mov64 r3, r5
  rsh64 r3, 0x4
  add64 r5, r3
  and64 r5, r2
  mul64 r5, r1
  rsh64 r5, 0x38
  jgt r5, r7, jmp_15e48

jmp_15b40:
  mov64 r8, 0x0
  mov64 r3, 0x1
  mov64 r1, 0x1
  ldxdw r4, [r10-0x10]
  jlt r9, r4, jmp_15eb0
  mov64 r1, 0x0
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jge r2, r5, jmp_15ec8

jmp_15b88:
  jeq r2, r5, jmp_15ed8

jmp_15b90:
  mov64 r1, r3
  and64 r1, 0x1
  jne r1, 0x0, jmp_15ee8

jmp_15ba8:
  sub64 r2, r5
  mov64 r3, 0x0
  mov64 r8, 0x1
  mov64 r1, 0x1
  jlt r9, r4, jmp_15bd8

jmp_15bd0:
  mov64 r1, 0x0

jmp_15bd8:
  sub64 r2, r1
  sub64 r9, r4
  mov64 r0, r9
  ja jmp_16028

jmp_15bf8:
  mov64 r0, r3
  rsh64 r0, 0x1
  mov64 r5, r3
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
  and64 r0, r4
  sub64 r5, r0
  mov64 r7, r5
  and64 r7, r8
  rsh64 r5, 0x2
  and64 r5, r8
  add64 r7, r5
  mov64 r5, r7
  rsh64 r5, 0x4
  add64 r7, r5
  and64 r7, r2
  mul64 r7, r1
  rsh64 r7, 0x38
  ldxdw r5, [r10-0x8]
  jne r5, 0x0, jmp_15a28

jmp_15d20:
  ldxdw r5, [r10-0x10]
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
  and64 r0, r4
  sub64 r5, r0
  mov64 r4, r5
  rsh64 r4, 0x2
  and64 r5, r8
  and64 r4, r8
  add64 r5, r4
  mov64 r3, r5
  rsh64 r3, 0x4
  add64 r5, r3
  and64 r5, r2
  mul64 r5, r1
  rsh64 r5, 0x38
  add64 r5, 0x40
  jle r5, r7, jmp_15b40

jmp_15e48:
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jle r1, 0x3f, jmp_15f00
  mov64 r8, r9
  ldxdw r2, [r10-0x10]
  div64 r8, r2
  mov64 r1, r8
  mul64 r1, r2
  sub64 r9, r1
  mov64 r3, 0x0
  mov64 r0, r9
  ja jmp_16020

jmp_15eb0:
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jlt r2, r5, jmp_15b88

jmp_15ec8:
  mov64 r3, 0x0
  jne r2, r5, jmp_15b90

jmp_15ed8:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_15ba8

jmp_15ee8:
  mov64 r3, 0x0
  mov64 r0, r9
  ja jmp_16028

jmp_15f00:
  mov64 r1, r5
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  stxdw [r10-0x48], r1
  jle r1, 0x5f, jmp_16050
  ldxdw r4, [r10-0x10]
  mov64 r1, r4
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  ldxdw r8, [r10-0x18]
  mov64 r2, r8
  div64 r2, r1
  mov64 r3, r2
  mul64 r3, r4
  sub64 r8, r3
  lsh64 r8, 0x20
  mov64 r0, r9
  rsh64 r0, 0x20
  or64 r8, r0
  div64 r8, r1
  mov64 r3, r8
  mul64 r3, r4
  sub64 r0, r3
  mov64 r3, r8
  rsh64 r3, 0x20
  or64 r3, r2
  lsh64 r9, 0x20
  rsh64 r9, 0x20
  lsh64 r0, 0x20
  or64 r0, r9
  lsh64 r8, 0x20
  mov64 r2, r0
  div64 r2, r1
  or64 r8, r2
  mul64 r2, r1
  sub64 r0, r2

jmp_16020:
  mov64 r2, 0x0

jmp_16028:
  stxdw [r6+0x10], r0
  stxdw [r6+0x0], r8
  stxdw [r6+0x18], r2
  stxdw [r6+0x8], r3
  exit

jmp_16050:
  mov64 r1, r5
  sub64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  stxdw [r10-0x50], r6
  jge r1, 0x20, jmp_16298
  mov64 r6, 0x40
  sub64 r6, r7
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  ldxdw r7, [r10-0x10]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r3, r6
  call fn_16d18
  stxdw [r10-0x20], r0
  mov64 r1, r9
  ldxdw r2, [r10-0x18]
  mov64 r3, r6
  call fn_16d18
  mov64 r8, r0
  ldxdw r1, [r10-0x20]
  div64 r8, r1
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_156e0
  stxdw [r10-0x20], r0
  mov64 r6, r1
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_156e0
  mov64 r3, 0x1
  mov64 r4, r6
  add64 r4, r0
  jlt r4, r6, jmp_16190
  mov64 r3, 0x0

jmp_16190:
  add64 r1, r3
  ldxdw r6, [r10-0x50]
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jne r1, 0x0, jmp_16208
  mov64 r3, 0x1
  mov64 r1, 0x1
  ldxdw r0, [r10-0x20]
  jlt r9, r0, jmp_16858
  mov64 r1, 0x0
  jge r2, r4, jmp_16860

jmp_161e8:
  jeq r2, r4, jmp_16870

jmp_161f0:
  mov64 r1, r3
  and64 r1, 0x1
  jeq r1, 0x0, jmp_16880

jmp_16208:
  add64 r5, r2
  mov64 r0, r7
  add64 r0, r9
  mov64 r1, 0x1
  mov64 r3, 0x1
  jlt r0, r7, jmp_16240
  mov64 r3, 0x0

jmp_16240:
  add64 r5, r3
  sub64 r5, r4
  ldxdw r2, [r10-0x20]
  jlt r0, r2, jmp_16268
  mov64 r1, 0x0

jmp_16268:
  sub64 r5, r1
  sub64 r0, r2
  add64 r8, -0x1
  mov64 r2, r5
  mov64 r3, 0x0
  ja jmp_16028

jmp_16298:
  mov64 r1, 0x60
  sub64 r1, r5
  stxdw [r10-0x60], r1
  mov64 r3, r1
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x58], r3
  call fn_16d18
  mov64 r4, 0x0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  add64 r0, 0x1
  stxdw [r10-0x68], r0
  mov64 r1, 0x0
  stxdw [r10-0x28], r1
  mov64 r0, r9
  ldxdw r2, [r10-0x18]

jmp_16330:
  stxdw [r10-0x30], r4
  mov64 r8, 0x40
  sub64 r8, r7
  mov64 r6, r8
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  mov64 r1, r0
  stxdw [r10-0x18], r2
  mov64 r3, r6
  mov64 r9, r0
  call fn_16d18
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x20], r9
  jlt r6, r1, jmp_168b0
  ldxdw r1, [r10-0x68]
  div64 r0, r1
  ldxdw r1, [r10-0x60]
  sub64 r8, r1
  lsh64 r8, 0x20
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x38], r0
  mov64 r3, r0
  mov64 r4, 0x0
  call fn_156e0
  mov64 r2, r1
  rsh64 r8, 0x20
  mov64 r1, r0
  mov64 r3, r8
  call fn_16c70
  mov64 r6, r0
  stxdw [r10-0x40], r1
  mov64 r7, 0x1
  jlt r9, r6, jmp_16448
  mov64 r7, 0x0

jmp_16448:
  ldxdw r1, [r10-0x38]
  mov64 r2, 0x0
  mov64 r3, r8
  call fn_16c70
  mov64 r5, r0
  ldxdw r2, [r10-0x30]
  add64 r5, r2
  mov64 r8, 0x1
  jlt r5, r0, jmp_16498
  mov64 r8, 0x0

jmp_16498:
  ldxdw r2, [r10-0x18]
  ldxdw r3, [r10-0x40]
  sub64 r2, r3
  sub64 r2, r7
  ldxdw r0, [r10-0x20]
  sub64 r0, r6
  jne r2, 0x0, jmp_16638
  mov64 r4, r0
  rsh64 r4, 0x1
  mov64 r3, r0
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x2
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x4
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x8
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x10
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x20
  or64 r3, r4
  xor64 r3, -0x1
  mov64 r4, r3
  rsh64 r4, 0x1
  lddw r6, 0x5555555555555555
  and64 r4, r6
  sub64 r3, r4
  mov64 r7, r3
  lddw r4, 0x3333333333333333
  and64 r7, r4
  rsh64 r3, 0x2
  and64 r3, r4
  add64 r7, r3
  mov64 r3, r7
  rsh64 r3, 0x4
  add64 r7, r3
  lddw r3, 0xf0f0f0f0f0f0f0f
  and64 r7, r3
  lddw r3, 0x101010101010101
  mul64 r7, r3
  rsh64 r7, 0x38
  add64 r7, 0x40
  ja jmp_16790

jmp_16638:
  mov64 r4, r2
  rsh64 r4, 0x1
  mov64 r3, r2
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x2
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x4
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x8
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x10
  or64 r3, r4
  mov64 r4, r3
  rsh64 r4, 0x20
  or64 r3, r4
  xor64 r3, -0x1
  mov64 r4, r3
  rsh64 r4, 0x1
  lddw r6, 0x5555555555555555
  and64 r4, r6
  sub64 r3, r4
  mov64 r7, r3
  lddw r4, 0x3333333333333333
  and64 r7, r4
  rsh64 r3, 0x2
  and64 r3, r4
  add64 r7, r3
  mov64 r3, r7
  rsh64 r3, 0x4
  add64 r7, r3
  lddw r3, 0xf0f0f0f0f0f0f0f
  and64 r7, r3
  lddw r3, 0x101010101010101
  mul64 r7, r3
  rsh64 r7, 0x38

jmp_16790:
  ldxdw r6, [r10-0x50]
  ldxdw r3, [r10-0x28]
  add64 r1, r3
  add64 r1, r8
  ldxdw r3, [r10-0x48]
  jle r3, r7, jmp_16b18
  mov64 r3, r7
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  mov64 r4, r5
  stxdw [r10-0x28], r1
  jle r3, 0x3f, jmp_16330
  ldxdw r4, [r10-0x10]
  jeq r4, 0x0, jmp_16c68
  mov64 r3, r0
  div64 r3, r4

jmp_16810:
  mov64 r8, r5
  add64 r8, r3
  mov64 r2, 0x0
  mov64 r3, 0x1
  jlt r8, r5, jmp_16840
  mov64 r3, 0x0

jmp_16840:
  mod64 r0, r4
  add64 r1, r3
  ja jmp_16bf8

jmp_16858:
  jlt r2, r4, jmp_161e8

jmp_16860:
  mov64 r3, 0x0
  jne r2, r4, jmp_161f0

jmp_16870:
  and64 r1, 0x1
  jne r1, 0x0, jmp_16208

jmp_16880:
  sub64 r2, r4
  mov64 r3, 0x0
  mov64 r1, 0x1
  ldxdw r4, [r10-0x20]
  jge r9, r4, jmp_15bd0
  ja jmp_15bd8

jmp_168b0:
  mov64 r8, r0
  ldxdw r7, [r10-0x10]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r3, r6
  call fn_16d18
  jeq r0, 0x0, jmp_16c60
  div64 r8, r0
  mov64 r3, r8

jmp_168f8:
  ldxdw r6, [r10-0x50]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r9, r3
  mov64 r4, 0x0
  call fn_156e0
  mov64 r3, 0x1
  mov64 r4, 0x1
  ldxdw r2, [r10-0x20]
  jlt r2, r0, jmp_16a18
  mov64 r4, 0x0
  ldxdw r2, [r10-0x18]
  jge r2, r1, jmp_16a28

jmp_16960:
  ldxdw r5, [r10-0x8]
  jeq r2, r1, jmp_16a40

jmp_16970:
  mov64 r4, r3
  and64 r4, 0x1
  jne r4, 0x0, jmp_16a50

jmp_16988:
  ldxdw r5, [r10-0x30]
  mov64 r8, r5
  add64 r8, r9
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r8, r5, jmp_169c0
  mov64 r4, 0x0

jmp_169c0:
  ldxdw r5, [r10-0x20]
  jlt r5, r0, jmp_169d8
  mov64 r3, 0x0

jmp_169d8:
  sub64 r2, r1
  sub64 r2, r3
  ldxdw r1, [r10-0x20]
  sub64 r1, r0
  mov64 r0, r1
  ldxdw r3, [r10-0x28]
  add64 r3, r4
  ja jmp_16028

jmp_16a18:
  ldxdw r2, [r10-0x18]
  jlt r2, r1, jmp_16960

jmp_16a28:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x8]
  jne r2, r1, jmp_16970

jmp_16a40:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_16988

jmp_16a50:
  add64 r2, r5
  ldxdw r8, [r10-0x20]
  mov64 r5, r8
  add64 r5, r7
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r5, r8, jmp_16a90
  mov64 r4, 0x0

jmp_16a90:
  add64 r2, r4
  ldxdw r7, [r10-0x30]
  add64 r9, r7
  add64 r9, -0x1
  mov64 r4, 0x1
  mov64 r8, r9
  jlt r9, r7, jmp_16ad0
  mov64 r4, 0x0

jmp_16ad0:
  sub64 r2, r1
  jlt r5, r0, jmp_16ae8
  mov64 r3, 0x0

jmp_16ae8:
  sub64 r2, r3
  sub64 r5, r0
  ldxdw r3, [r10-0x28]
  add64 r3, r4
  mov64 r0, r5
  ja jmp_16028

jmp_16b18:
  mov64 r4, 0x1
  mov64 r3, 0x1
  mov64 r7, r0
  ldxdw r0, [r10-0x10]
  mov64 r9, r7
  jlt r7, r0, jmp_16c08
  mov64 r3, 0x0
  ldxdw r7, [r10-0x8]
  jge r2, r7, jmp_16c18

jmp_16b60:
  ldxdw r7, [r10-0x8]
  jeq r2, r7, jmp_16c30

jmp_16b70:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_16c40

jmp_16b88:
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r9, r0, jmp_16ba8
  mov64 r4, 0x0

jmp_16ba8:
  ldxdw r7, [r10-0x8]
  sub64 r2, r7
  add64 r5, 0x1
  jeq r5, 0x0, jmp_16bd0
  mov64 r3, 0x0

jmp_16bd0:
  sub64 r2, r4
  add64 r1, r3
  sub64 r9, r0
  mov64 r0, r9
  mov64 r8, r5

jmp_16bf8:
  mov64 r3, r1
  ja jmp_16028

jmp_16c08:
  ldxdw r7, [r10-0x8]
  jlt r2, r7, jmp_16b60

jmp_16c18:
  mov64 r4, 0x0
  ldxdw r7, [r10-0x8]
  jne r2, r7, jmp_16b70

jmp_16c30:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_16b88

jmp_16c40:
  mov64 r8, r5
  mov64 r3, r1
  mov64 r0, r9
  ja jmp_16028

jmp_16c60:
  ja jmp_168f8

jmp_16c68:
  ja jmp_16810

fn_16c70:
  mov64 r0, r1
  mov64 r1, r3
  and64 r1, 0x40
  jne r1, 0x0, jmp_16ce8
  jeq r3, 0x0, jmp_16d08
  mov64 r1, r3
  and64 r1, 0x3f
  lsh64 r2, r1
  neg64 r3
  and64 r3, 0x3f
  mov64 r4, r0
  rsh64 r4, r3
  or64 r2, r4
  lsh64 r0, r1
  ja jmp_16d08

jmp_16ce8:
  and64 r3, 0x3f
  mov64 r2, r0
  lsh64 r2, r3
  mov64 r0, 0x0

jmp_16d08:
  mov64 r1, r2
  exit

fn_16d18:
  mov64 r0, r1
  mov64 r1, r3
  and64 r1, 0x40
  jne r1, 0x0, jmp_16d98
  jeq r3, 0x0, jmp_16db8
  mov64 r1, r3
  and64 r1, 0x3f
  rsh64 r0, r1
  neg64 r3
  and64 r3, 0x3f
  mov64 r4, r2
  lsh64 r4, r3
  or64 r4, r0
  rsh64 r2, r1
  mov64 r0, r4
  ja jmp_16db8

jmp_16d98:
  and64 r3, 0x3f
  rsh64 r2, r3
  mov64 r0, r2
  mov64 r2, 0x0

jmp_16db8:
  mov64 r1, r2
  exit

.rodata
  data_0000: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x73, 0x6f, 0x6c, 0x61, 0x6e, 0x61, 0x2d, 0x61, 0x63, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x2d, 0x76, 0x69, 0x65, 0x77, 0x2d, 0x32, 0x2e, 0x31, 0x2e, 0x30, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6c, 0x69, 0x62, 0x2e, 0x72, 0x73, 0x00
  data_007a: .byte 0x2f, 0x68, 0x6f, 0x6d, 0x65, 0x2f, 0x72, 0x75, 0x6e, 0x6e, 0x65, 0x72, 0x2f, 0x77, 0x6f, 0x72, 0x6b, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x6f, 0x75, 0x74, 0x2f, 0x72, 0x75, 0x73, 0x74, 0x2f, 0x6c, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x2f, 0x63, 0x6f, 0x72, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x74, 0x65, 0x72, 0x2f, 0x61, 0x64, 0x61, 0x70, 0x74, 0x65, 0x72, 0x73, 0x2f, 0x65, 0x6e, 0x75, 0x6d, 0x65, 0x72, 0x61, 0x74, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_00df: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x5f, 0x6c, 0x65, 0x61, 0x72, 0x6e, 0x69, 0x6e, 0x67, 0x2e, 0x72, 0x73, 0x00
  data_0106: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x73, 0x2f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6c, 0x69, 0x62, 0x2e, 0x72, 0x73, 0x00
  data_0121: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x2d, 0x73, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x73, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6c, 0x69, 0x62, 0x2e, 0x72, 0x73, 0x00
  data_0142: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6f, 0x72, 0x61, 0x63, 0x6c, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_0160: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x66, 0x69, 0x76, 0x65, 0x38, 0x5f, 0x63, 0x6f, 0x6e, 0x73, 0x74, 0x2d, 0x31, 0x2e, 0x30, 0x2e, 0x30, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6c, 0x69, 0x62, 0x2e, 0x72, 0x73, 0x00
  data_01d2: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x70, 0x69, 0x6e, 0x6f, 0x63, 0x63, 0x68, 0x69, 0x6f, 0x2d, 0x30, 0x2e, 0x31, 0x31, 0x2e, 0x32, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x65, 0x6e, 0x74, 0x72, 0x79, 0x70, 0x6f, 0x69, 0x6e, 0x74, 0x2f, 0x6d, 0x6f, 0x64, 0x2e, 0x72, 0x73, 0x00
  data_024e: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x73, 0x6f, 0x6c, 0x61, 0x6e, 0x61, 0x2d, 0x61, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0x2d, 0x32, 0x2e, 0x39, 0x2e, 0x30, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x79, 0x73, 0x63, 0x61, 0x6c, 0x6c, 0x73, 0x2e, 0x72, 0x73, 0x00
  data_02c8: .byte 0x02, 0xa8, 0xf6, 0x91, 0x4e, 0x88, 0xa1, 0xb0, 0xe2, 0x10, 0x15, 0x3e, 0xf7, 0x63, 0xae, 0x2b, 0x00, 0xc2, 0xb9, 0x3d, 0x16, 0xc1, 0x24, 0xd2, 0xc0, 0x53, 0x7a, 0x10, 0x04, 0x80, 0x00, 0x00
  data_02e8: .byte 0x06, 0xa7, 0xd5, 0x17, 0x19, 0x2c, 0x5c, 0x51, 0x21, 0x8c, 0xc9, 0x4c, 0x3d, 0x4a, 0xf1, 0x7f, 0x58, 0xda, 0xee, 0x08, 0x9b, 0xa1, 0xfd, 0x44, 0xe3, 0xdb, 0xd9, 0x8a, 0x00, 0x00, 0x00, 0x00
  data_0308: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_0328: .byte 0x06, 0xa7, 0xd5, 0x17, 0x18, 0xc7, 0x74, 0xc9, 0x28, 0x56, 0x63, 0x98, 0x69, 0x1d, 0x5e, 0xb6, 0x8b, 0x5e, 0xb8, 0xa3, 0x9b, 0x4b, 0x6d, 0x5c, 0x73, 0x55, 0x5b, 0x21, 0x00, 0x00, 0x00, 0x00
  data_0348: .byte 0xc6, 0xfa, 0x7a, 0xf3, 0xbe, 0xdb, 0xad, 0x3a, 0x3d, 0x65, 0xf3, 0x6a, 0xab, 0xc9, 0x74, 0x31, 0xb1, 0xbb, 0xe4, 0xc2, 0xd2, 0xf6, 0xe0, 0xe4, 0x7c, 0xa6, 0x02, 0x03, 0x45, 0x2f, 0x5d, 0x61
  str_0368: .ascii "prices"
  str_036e: .ascii "config"
  str_0374: .ascii "weights"
  str_037b: .ascii "oracle-authority"
  str_038b: .ascii "oracle"
  data_0391: .byte 0x6d, 0x61, 0x72, 0x6b, 0x65, 0x74, 0x00
  data_0398: .byte 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_03b0: .byte 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_03c8: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaf, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x67
  data_03f8: .byte 0xc0, 0x9b, 0x73, 0x39, 0x23, 0xec, 0xc3, 0x67, 0xf3, 0xe5, 0x73, 0x89, 0x8b, 0x54, 0x5b, 0x1e, 0x2e, 0x65, 0xa3, 0xb0, 0x5e, 0x55, 0xb3, 0x02, 0x5a, 0x08, 0xee, 0x0b, 0x6b, 0xba, 0x37, 0x97, 0xc8, 0xf9, 0x18, 0xd1, 0x1d, 0x75, 0xbb, 0x9d, 0x9c, 0xc4, 0x7b, 0x10, 0x00, 0x9e, 0x50, 0xfc
  data_0428: .byte 0x0d, 0x28, 0x63, 0xe7, 0xd4, 0x6a, 0x9c, 0x1c, 0xe8, 0xd2, 0x8d, 0x05, 0x8e, 0xd9, 0x4e, 0x88, 0xca, 0x5d, 0xc7, 0x43, 0xf2, 0xc8, 0xdf, 0x56, 0x91, 0x46, 0xdd, 0x52, 0x66, 0x83, 0x20, 0x29, 0xf3, 0xa2, 0x26, 0x0b, 0x8c, 0xfb, 0xa2, 0xe6, 0x18, 0x4a, 0x59, 0xde, 0x61, 0x8e, 0xcc, 0x70
  data_0458: .byte 0xf4, 0x7d, 0xfd, 0xbb, 0xd0, 0xd5, 0xfe, 0x57, 0xe0, 0xbc, 0xb3, 0x32, 0x57, 0x1b, 0xea, 0x0a, 0x73, 0xfd, 0x43, 0xef, 0x74, 0x4c, 0xf0, 0xaf, 0xaf, 0x21, 0x5b, 0x9f, 0x15, 0x05, 0xcc, 0x9a, 0xb3, 0x1e, 0x00, 0x21, 0x98, 0xae, 0x10, 0xe6, 0xbb, 0xad, 0x97, 0x31, 0xec, 0xf4, 0xae, 0xbd
  data_0488: .byte 0x9f, 0x32, 0xda, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0xd3, 0xed, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a, 0x32, 0x93, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0b, 0xf8, 0xfc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8b, 0xbc, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8a, 0xb0, 0x68, 0x00, 0x00, 0x00, 0x00, 0x00
  data_04b8: .byte 0x00, 0x00, 0x00, 0x9c, 0x1f, 0x6c, 0x12, 0x00, 0x00, 0x00, 0x00, 0xc4, 0xe5, 0x73, 0xad, 0x00, 0x00, 0x00, 0x00, 0x7c, 0x46, 0x3d, 0xb0, 0x00, 0x00, 0x00, 0x00, 0x92, 0xd4, 0xde, 0xb3, 0x00, 0x00, 0x00, 0x00, 0x25, 0x8a, 0x81, 0x75, 0x00, 0x00, 0x00, 0x00, 0x84, 0x61, 0x39, 0x7e, 0x00
  str_04e8: .ascii "cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij"
  str_0513: .ascii "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs"
  str_053f: .ascii "So11111111111111111111111111111111111111112"
  data_056a: .byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0xff, 0x11, 0x12, 0x13, 0x14, 0x15, 0xff, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0xff, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0xff, 0x00, 0x00, 0x00
  data_05b8: .quad data_024e
  data_05c0: .byte 0x7a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x17, 0x01, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
  data_05d0: .quad data_0000
  data_05d8: .byte 0x7a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x01, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00
  data_05e8: .quad data_01d2
  data_05f0: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc2, 0x01, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0600: .quad data_01d2
  data_0608: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdd, 0x01, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0618: .quad data_01d2
  data_0620: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe8, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0630: .quad data_01d2
  data_0638: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xeb, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0648: .quad data_01d2
  data_0650: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xee, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0660: .quad data_01d2
  data_0668: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf1, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0678: .quad data_01d2
  data_0680: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe1, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0690: .quad str_036e
  data_0698: .quad 0x0000000000000006
  data_06a0: .quad str_037b
  data_06a8: .quad 0x0000000000000010
  data_06b0: .quad data_0106
  data_06b8: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfd, 0x01, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00
  data_06c8: .quad data_0106
  data_06d0: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a, 0x02, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00
  data_06e0: .quad data_0106
  data_06e8: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x02, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00
  data_06f8: .quad data_0106
  data_0700: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x1a, 0x00, 0x00, 0x00
  data_0710: .quad data_0106
  data_0718: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x02, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0728: .quad data_0106
  data_0730: .byte 0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x02, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00
  data_0740: .quad data_0121
  data_0748: .byte 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb2, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_0758: .quad data_0121
  data_0760: .byte 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbc, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00
  data_0770: .quad data_007a
  data_0778: .byte 0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0788: .quad data_0142
  data_0790: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x01, 0x00, 0x00, 0x2a, 0x00, 0x00, 0x00
  data_07a0: .quad data_0142
  data_07a8: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1d, 0x01, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00
  data_07b8: .quad data_0142
  data_07c0: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x01, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_07d0: .quad data_0142
  data_07d8: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x01, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_07e8: .quad data_0142
  data_07f0: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x23, 0x01, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00
  data_0800: .quad data_0142
  data_0808: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x23, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0818: .quad data_0142
  data_0820: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf7, 0x00, 0x00, 0x00, 0x23, 0x00, 0x00, 0x00
  data_0830: .quad data_0142
  data_0838: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf7, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x00
  data_0848: .quad data_0142
  data_0850: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0860: .quad data_0142
  data_0868: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0878: .quad data_0142
  data_0880: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0890: .quad data_0142
  data_0898: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x01, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_08a8: .quad data_0142
  data_08b0: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x01, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_08c0: .quad data_0142
  data_08c8: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x01, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00
  data_08d8: .quad data_0142
  data_08e0: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x44, 0x01, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00
  data_08f0: .quad data_0142
  data_08f8: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x49, 0x01, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0908: .quad data_0142
  data_0910: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4e, 0x01, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0920: .quad data_00df
  data_0928: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbd, 0x00, 0x00, 0x00, 0x2a, 0x00, 0x00, 0x00
  data_0938: .quad data_00df
  data_0940: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbd, 0x00, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00
  data_0950: .quad data_00df
  data_0958: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdb, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
  data_0968: .quad data_00df
  data_0970: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xde, 0x00, 0x00, 0x00, 0x2f, 0x00, 0x00, 0x00
  data_0980: .quad data_00df
  data_0988: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdf, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0998: .quad data_00df
  data_09a0: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe2, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
  data_09b0: .quad data_00df
  data_09b8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe2, 0x00, 0x00, 0x00, 0x46, 0x00, 0x00, 0x00
  data_09c8: .quad data_00df
  data_09d0: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe6, 0x00, 0x00, 0x00, 0x2f, 0x00, 0x00, 0x00
  data_09e0: .quad data_00df
  data_09e8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf4, 0x00, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_09f8: .quad data_00df
  data_0a00: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfb, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0a10: .quad data_00df
  data_0a18: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfb, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0a28: .quad data_00df
  data_0a30: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf9, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0a40: .quad data_00df
  data_0a48: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe7, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0a58: .quad data_00df
  data_0a60: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcc, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
  data_0a70: .quad data_00df
  data_0a78: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd0, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_0a88: .quad data_00df
  data_0a90: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcd, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0aa0: .quad data_00df
  data_0aa8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00
  data_0ab8: .quad data_00df
  data_0ac0: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00
  data_0ad0: .quad data_00df
  data_0ad8: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0ae8: .quad data_00df
  data_0af0: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0b00: .quad data_00df
  data_0b08: .byte 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x19, 0x01, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00
  data_0b18: .quad data_0160
  data_0b20: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00
  data_0b30: .quad data_0160
  data_0b38: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00
  data_0b48: .quad data_0160
  data_0b50: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x22, 0x00, 0x00, 0x00
  data_0b60: .quad data_0160
  data_0b68: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00
  data_0b78: .quad data_0160
  data_0b80: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x27, 0x00, 0x00, 0x00
  data_0b90: .quad data_0160
  data_0b98: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5a, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0ba8: .quad data_0160
  data_0bb0: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
  data_0bc0: .quad data_0160
  data_0bc8: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00
  data_0bd8: .quad data_0160
  data_0be0: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_0bf0: .quad data_0160
  data_0bf8: .byte 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00
