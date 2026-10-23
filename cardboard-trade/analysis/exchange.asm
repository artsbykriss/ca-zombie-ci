.globl entrypoint

fn_0000:
  ldxdw r3, [r2+0x50]
  jne r3, 0x52, jmp_00b8
  ldxdw r3, [r2+0x28]
  lddw r4, -0x6c5e9a281e0922fa
  jne r3, r4, jmp_00d0
  ldxdw r3, [r2+0x30]
  lddw r4, -0x53861431b91e3427
  jne r3, r4, jmp_00d0
  ldxdw r3, [r2+0x38]
  lddw r4, -0x6ec8a4a0127a4be4
  jne r3, r4, jmp_00d0
  ldxdw r3, [r2+0x40]
  lddw r4, -0x56ff00817a0a73c6
  jne r3, r4, jmp_00d0
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_00e8
  stdw [r1+0x0], 0x0
  stdw [r1+0x8], 0xb
  ja jmp_00e0

jmp_00b8:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x3
  ja jmp_00e0

jmp_00d0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x16

jmp_00e0:
  exit

jmp_00e8:
  add64 r3, -0x1
  stxb [r2+0x0], r3
  stxdw [r1+0x8], r2
  add64 r2, 0x58
  stxdw [r1+0x0], r2
  ja jmp_00e0

fn_0118:
  ldxdw r3, [r2+0x50]
  jne r3, 0xa5, jmp_01d0
  ldxdw r3, [r2+0x28]
  lddw r4, -0x6c5e9a281e0922fa
  jne r3, r4, jmp_01d0
  ldxdw r3, [r2+0x30]
  lddw r4, -0x53861431b91e3427
  jne r3, r4, jmp_01d0
  ldxdw r3, [r2+0x38]
  lddw r4, -0x6ec8a4a0127a4be4
  jne r3, r4, jmp_01d0
  ldxdw r3, [r2+0x40]
  lddw r4, -0x56ff00817a0a73c6
  jne r3, r4, jmp_01d0
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_01e8
  stdw [r1+0x0], 0x0
  stdw [r1+0x8], 0xb
  ja jmp_01e0

jmp_01d0:
  stdw [r1+0x0], 0x0
  stw [r1+0x8], 0x3

jmp_01e0:
  exit

jmp_01e8:
  add64 r3, -0x1
  stxb [r2+0x0], r3
  stxdw [r1+0x8], r2
  add64 r2, 0x58
  stxdw [r1+0x0], r2
  ja jmp_01e0

fn_0218:
  mov64 r0, 0x1a
  ldxdw r2, [r1+0x48]
  ldxdw r4, [r1+0x50]
  mov64 r3, r4
  jge r2, r4, jmp_0460
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
  ja jmp_0378

jmp_02d0:
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
  jge r2, r1, jmp_0440

jmp_0378:
  add64 r2, 0x1
  ldxdw r0, [r6+0x0]
  ldxdw r7, [r0+0x0]
  ldxdw r8, [r5-0x8]
  ldxdw r0, [r8+0x0]
  ldxdw r9, [r7+0x8]
  jne r9, r0, jmp_0430
  mov64 r0, 0x1
  ldxdw r9, [r8+0x8]
  ldxdw r3, [r7+0x10]
  jne r3, r9, jmp_0450
  ldxdw r3, [r8+0x10]
  ldxdw r9, [r7+0x18]
  jne r9, r3, jmp_0450
  ldxdw r3, [r8+0x18]
  ldxdw r8, [r7+0x20]
  jne r8, r3, jmp_0450
  ldxb r3, [r5+0x0]
  jne r3, 0x1, jmp_02d0
  ldxb r3, [r7+0x0]
  jeq r3, 0xff, jmp_02d0
  mov64 r0, 0xb
  ja jmp_0450

jmp_0430:
  mov64 r0, 0x1
  ja jmp_0450

jmp_0440:
  mov64 r0, 0x1a
  mov64 r2, r1

jmp_0450:
  ldxdw r1, [r10-0x8]
  stxdw [r1+0x48], r2

jmp_0460:
  exit

fn_0468:
  mov64 r2, r1
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r2+0x8]
  jeq r3, r4, jmp_0500
  mov64 r1, 0x0

jmp_0490:
  mov64 r5, r3
  add64 r5, r1
  ldxb r0, [r5+0x0]
  jeq r0, 0x0, jmp_0510
  add64 r1, 0x1
  mov64 r5, 0x1
  jeq r1, 0x0, jmp_04d0
  mov64 r5, 0x0

jmp_04d0:
  and64 r5, 0x1
  jne r5, 0x0, jmp_0530
  mov64 r5, r3
  add64 r5, r1
  jne r5, r4, jmp_0490
  stxdw [r2+0x0], r5

jmp_0500:
  mov64 r0, 0x0
  ja jmp_0528

jmp_0510:
  add64 r5, 0x1
  stxdw [r2+0x0], r5
  mov64 r0, 0x1

jmp_0528:
  exit

jmp_0530:
  lddw r1, data_0690
  call fn_2bcf8

fn_0548:
  mov64 r0, 0x0
  ldxb r3, [r1+0x1]
  jeq r3, 0x0, jmp_05c8
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r1+0x8]
  jne r4, r3, jmp_05c8
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r1+0x10]
  jne r4, r3, jmp_05c8
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r1+0x18]
  jne r4, r3, jmp_05c8
  ldxdw r2, [r2+0x18]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_05c8
  mov64 r0, 0x1a

jmp_05c8:
  exit

fn_05d0:
  mov64 r6, r1
  ldxdw r1, [r4+0x18]
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r4+0x8]
  ldxdw r7, [r4+0x0]
  lddw r8, -0x42bcf8a191e690bb
  jne r7, r8, jmp_0768
  lddw r8, 0x61fb6bd0dbe5a208
  jne r0, r8, jmp_0768
  lddw r8, 0x72b19992c23bfdc4
  jne r5, r8, jmp_0768
  lddw r8, -0x5f6978a92e5eeea3
  jne r1, r8, jmp_0768
  jeq r3, 0x1, jmp_0880
  jne r3, 0x2, jmp_0e88
  ldxdw r1, [r2+0x8]
  jeq r1, 0x7, jmp_0a50
  jne r1, 0x6, jmp_0e88
  ldxdw r1, [r2+0x0]
  ldxw r5, [r1+0x0]
  ldxh r1, [r1+0x4]
  lsh64 r1, 0x20
  or64 r5, r1
  lddw r1, 0x736563697270
  jne r5, r1, jmp_0e88
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e88
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0bd8
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0c68
  lddw r1, 0xfd0000001a
  lddw r2, 0x7aa80c7bd9b32db0
  lddw r3, -0x4953a499653cb8ce
  lddw r4, 0x389ad8f340cf22c7
  lddw r5, 0x7f2063ee78df879e
  ja jmp_0f18

jmp_0768:
  lddw r8, 0x17fee008f3155dfe
  jne r7, r8, jmp_0e88
  lddw r7, -0x70c6ba182ecb4d4d
  jne r0, r7, jmp_0e88
  lddw r0, 0x2d2cf27ef4b22b67
  jne r5, r0, jmp_0e88
  lddw r5, 0x553de8c6eda0600a
  jne r1, r5, jmp_0e88
  jeq r3, 0x2, jmp_0940
  jne r3, 0x1, jmp_0e88
  ldxdw r1, [r2+0x8]
  jne r1, 0x6, jmp_0e88
  ldxdw r1, [r2+0x0]
  ldxw r5, [r1+0x0]
  ldxh r1, [r1+0x4]
  lsh64 r1, 0x20
  or64 r5, r1
  lddw r1, 0x6769666e6f63
  jne r5, r1, jmp_0e88
  lddw r1, 0xff0000001a
  lddw r2, 0x76af5324775b33a4
  lddw r3, 0x589c4e18ad4e531d
  lddw r4, -0x7610efa892797393
  lddw r5, 0x6485714b2c3e69fa
  ja jmp_0f18

jmp_0880:
  ldxdw r1, [r2+0x8]
  jne r1, 0x10, jmp_0e88
  ldxdw r1, [r2+0x0]
  ldxdw r5, [r1+0x8]
  lddw r0, 0x797469726f687475
  xor64 r5, r0
  ldxdw r1, [r1+0x0]
  lddw r0, 0x612d656c6361726f
  xor64 r1, r0
  or64 r1, r5
  jne r1, 0x0, jmp_0e88
  lddw r1, 0xff0000001a
  lddw r2, 0x13307c569701ccf8
  lddw r3, -0x78643d3527711a18
  lddw r4, 0x62b92caaf098f98e
  lddw r5, -0x178277b09baa79de
  ja jmp_0f18

jmp_0940:
  ldxdw r1, [r2+0x8]
  jne r1, 0x6, jmp_0e88
  ldxdw r5, [r2+0x0]
  ldxw r1, [r5+0x0]
  ldxh r5, [r5+0x4]
  lsh64 r5, 0x20
  or64 r1, r5
  lddw r5, 0x74656b72616d
  jeq r1, r5, jmp_0b40
  lddw r5, 0x656c6361726f
  jne r1, r5, jmp_0e88
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e88
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0d28
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0db8
  lddw r1, 0xff0000001a
  lddw r2, -0x1513dc8b1dd9889f
  lddw r3, 0x2e52c0600404c816
  lddw r4, 0x7cb85f1542112856
  lddw r5, -0x6e8ec092166b9542
  ja jmp_0f18

jmp_0a50:
  ldxdw r1, [r2+0x0]
  ldxh r5, [r1+0x4]
  lsh64 r5, 0x20
  ldxb r0, [r1+0x6]
  lsh64 r0, 0x30
  or64 r0, r5
  ldxw r1, [r1+0x0]
  or64 r1, r0
  lddw r5, 0x73746867696577
  jne r1, r5, jmp_0e88
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e88
  lddw r1, 0xfe0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0c20
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0cc8
  lddw r2, 0x33ba3ae03c73a294
  lddw r3, 0x27d69e0c3861ab3b
  lddw r4, 0x310af60e6afc1089
  lddw r5, -0x58ec6f1101b2d5f1
  ja jmp_0f18

jmp_0b40:
  ldxdw r1, [r2+0x18]
  jne r1, 0x2, jmp_0e88
  lddw r1, 0xff0000001a
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jeq r5, 0x0, jmp_0d70
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x1, jmp_0e18
  lddw r2, -0x781abfcb1367ecb
  lddw r3, -0x60be4aefd618aaf2
  lddw r4, 0x6b8a6005673cbb10
  lddw r5, 0x29fecfe88a8ae1fd
  ja jmp_0f18

jmp_0bd8:
  lddw r2, 0x55fd4bf665c8920
  lddw r3, 0xf2eb77c77ed9fe3
  lddw r4, 0x55c60d7b6d308c3c
  lddw r5, -0x27ea5f23a1b4d1e
  ja jmp_0f18

jmp_0c20:
  lddw r2, -0x66feb4aa46e5a3f1
  lddw r3, 0x1a320c12a61e29f2
  lddw r4, -0x477a7f2e0fe308da
  lddw r5, -0x5d81d940a24a0fba
  ja jmp_0f18

jmp_0c68:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e88
  lddw r2, 0x4cb2f5a683e80249
  lddw r3, 0x3cba9d160b4ffdde
  lddw r4, 0x38e70ffa45cdb189
  lddw r5, 0x6ba52ee8842aac07
  ja jmp_0f18

jmp_0cc8:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e88
  lddw r2, 0x31e9ad9be0f31580
  lddw r3, 0x1fd2f1ec0e49b0b4
  lddw r4, 0x652f22e28b3fe56e
  lddw r5, -0x49f1123b4e612d43
  ja jmp_0f18

jmp_0d28:
  lddw r2, 0x1b2ef052ccaa8eb7
  lddw r3, -0x1868c6b8c1b6c194
  lddw r4, 0x6539fa11752014ab
  lddw r5, -0x73a3ee11e18450f6
  ja jmp_0f18

jmp_0d70:
  lddw r2, 0x37978f41e74b6e70
  lddw r3, -0x4cf1643775f039de
  lddw r4, 0x7dc78f34cedf4f5
  lddw r5, -0x184085da377b6178
  ja jmp_0f18

jmp_0db8:
  ldxdw r5, [r2+0x10]
  ldxh r5, [r5+0x0]
  jne r5, 0x2, jmp_0e88
  lddw r2, 0xfb473dd5013e4a7
  lddw r3, 0x796087766583034b
  lddw r4, 0x6f602b31a1ad117d
  lddw r5, -0x6afe0ab31641a1fb
  ja jmp_0f18

jmp_0e18:
  ldxdw r1, [r2+0x10]
  ldxh r1, [r1+0x0]
  jne r1, 0x2, jmp_0e88
  lddw r1, 0xfd0000001a
  lddw r2, 0x4d863ab181b188b0
  lddw r3, -0x2b84581d3d4a5850
  lddw r4, 0x18df4081bd26c14
  lddw r5, -0x7819d7709597cce3
  ja jmp_0f18

jmp_0e88:
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
  jne r0, 0x0, jmp_0f78
  ldxdw r2, [r10-0x10]
  ldxdw r3, [r10-0x18]
  ldxdw r4, [r10-0x20]
  ldxdw r5, [r10-0x28]
  ldxb r1, [r10-0x1]
  lsh64 r1, 0x20
  or64 r1, 0x1a

jmp_0f18:
  lddw r0, 0x200000000
  ldxdw r7, [r6+0x8]
  jne r7, r5, jmp_0f70
  ldxdw r5, [r6+0x10]
  jne r5, r4, jmp_0f70
  ldxdw r4, [r6+0x18]
  jne r4, r3, jmp_0f70
  ldxdw r3, [r6+0x20]
  jne r3, r2, jmp_0f70
  mov64 r0, r1

jmp_0f70:
  exit

jmp_0f78:
  lddw r1, data_0660
  call fn_2bc88

fn_0f90:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_1018
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_1018
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_1018
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_1018
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_1040
  stb [r1+0xbe], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_1038

jmp_1018:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0xbe], 0x2

jmp_1038:
  exit

jmp_1040:
  mov64 r4, 0x2
  add64 r3, -0x1
  stxb [r2+0x0], r3
  ldxdw r0, [r2+0x50]
  jeq r0, 0xc7, jmp_10a0
  jne r0, 0xaf, jmp_1450
  mov64 r6, 0x1
  ldxdw r5, [r2+0x58]
  lddw r7, 0x343030534f505443
  jeq r5, r7, jmp_10c8
  ja jmp_1450

jmp_10a0:
  mov64 r6, 0x0
  ldxdw r5, [r2+0x58]
  lddw r7, 0x353030534f505443
  jne r5, r7, jmp_1450

jmp_10c8:
  ldxb r5, [r2+0x9e]
  ldxh r4, [r2+0x9c]
  stxdw [r10-0xa0], r4
  ldxw r4, [r2+0x9f]
  stxdw [r10-0x78], r4
  ldxb r4, [r2+0xab]
  stxdw [r10-0x90], r4
  ldxdw r4, [r2+0xa3]
  stxdw [r10-0x98], r4
  mov64 r4, 0x0
  stxdw [r10-0x30], r4
  mov64 r4, 0x1
  ldxdw r7, [r2+0xbf]
  stxdw [r10-0x40], r7
  ldxdw r7, [r2+0xb7]
  stxdw [r10-0x38], r7
  ldxh r7, [r2+0xb5]
  stxdw [r10-0x68], r7
  ldxb r7, [r2+0xb4]
  stxdw [r10-0x70], r7
  ldxdw r7, [r2+0xac]
  stxdw [r10-0x50], r7
  ldxdw r7, [r2+0x94]
  stxdw [r10-0x48], r7
  ldxh r7, [r2+0x92]
  stxdw [r10-0x80], r7
  ldxdw r7, [r2+0x8a]
  stxdw [r10-0x58], r7
  ldxh r7, [r2+0x88]
  stxdw [r10-0x88], r7
  ldxdw r7, [r2+0x80]
  stxdw [r10-0x60], r7
  ldxw r8, [r2+0x63]
  ldxb r7, [r2+0xc7]
  mov64 r9, 0x0
  jeq r7, 0x0, jmp_11f8
  jne r7, 0x1, jmp_1450
  mov64 r9, 0x1

jmp_11f8:
  ldxb r7, [r2+0xc8]
  jeq r7, 0x0, jmp_1220
  jne r7, 0x1, jmp_1450
  mov64 r7, 0x1
  stxdw [r10-0x30], r7

jmp_1220:
  stxdw [r10-0xb8], r8
  mov64 r8, r5
  mov64 r7, 0x0
  stxdw [r10-0xb0], r7
  ldxb r7, [r2+0xc9]
  mov64 r5, 0x0
  stxdw [r10-0xa8], r5
  jeq r7, 0x0, jmp_1278
  jne r7, 0x1, jmp_1450
  mov64 r7, 0x1
  stxdw [r10-0xa8], r7

jmp_1278:
  ldxdw r7, [r2+0xd2]
  stxdw [r10-0xc8], r7
  ldxdw r7, [r2+0xca]
  stxdw [r10-0xc0], r7
  ldxb r7, [r2+0xda]
  mov64 r5, r8
  mov64 r8, r9
  jeq r7, 0x0, jmp_12d0
  jne r7, 0x1, jmp_1450
  mov64 r7, 0x1
  stxdw [r10-0xb0], r7

jmp_12d0:
  ldxw r7, [r2+0x103]
  stxdw [r10-0xe8], r7
  ldxdw r7, [r2+0xfb]
  stxdw [r10-0xe0], r7
  ldxdw r7, [r2+0xf3]
  stxdw [r10-0xd8], r7
  ldxdw r7, [r2+0xeb]
  stxdw [r10-0xd0], r7
  ldxdw r9, [r2+0xe3]
  ldxdw r7, [r2+0xdb]
  stxdw [r10-0xf0], r7
  jeq r6, 0x0, jmp_1360
  mov64 r6, 0xaf
  mov64 r7, 0x0
  stxdw [r10-0xf8], r7
  stxdw [r10-0x108], r7
  stxdw [r10-0x100], r7
  ja jmp_13a0

jmp_1360:
  jlt r0, 0xc7, jmp_1450
  mov64 r6, 0xc7
  ldxdw r7, [r2+0x117]
  stxdw [r10-0x100], r7
  ldxdw r7, [r2+0x10f]
  stxdw [r10-0xf8], r7
  ldxdw r7, [r2+0x107]
  stxdw [r10-0x108], r7

jmp_13a0:
  jne r6, r0, jmp_1450
  mov64 r4, r2
  add64 r4, 0x67
  mov64 r0, r2
  add64 r0, 0x60
  ldxb r6, [r0+0x2]
  stxb [r10-0x6], r6
  ldxh r0, [r0+0x0]
  stxh [r10-0x8], r0
  ldxdw r0, [r10-0xb8]
  stxw [r10-0x5], r0
  ldxdw r0, [r4+0x0]
  stxdw [r10-0x28], r0
  ldxdw r0, [r4+0x8]
  stxdw [r10-0x20], r0
  ldxdw r0, [r4+0x10]
  stxdw [r10-0x18], r0
  ldxb r4, [r4+0x18]
  stxb [r10-0x10], r4
  ldxw r4, [r10-0x8]
  mov64 r0, 0x1
  jne r0, 0x0, jmp_14a0

jmp_1450:
  stxw [r1+0x4], r4
  stb [r1+0xbe], 0x2
  stw [r1+0x0], 0x0

jmp_1468:
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r1, r3
  and64 r1, 0xff
  jne r1, r3, jmp_1730
  stxb [r2+0x0], r3
  ja jmp_1038

jmp_14a0:
  lsh64 r5, 0x10
  ldxdw r0, [r10-0xa0]
  or64 r0, r5
  stxdw [r10-0xa0], r9
  ldxdw r9, [r10-0x78]
  lsh64 r9, 0x18
  or64 r9, r0
  ldxdw r0, [r10-0x90]
  lsh64 r0, 0x38
  ldxdw r6, [r10-0x98]
  mov64 r5, r6
  rsh64 r5, 0x8
  or64 r0, r5
  lsh64 r6, 0x38
  or64 r9, r6
  ldxb r5, [r10-0x2]
  stxb [r1+0x6], r5
  ldxh r5, [r10-0x4]
  stxh [r1+0x4], r5
  ldxb r5, [r10-0x10]
  stxdw [r10-0x78], r5
  ldxdw r5, [r10-0x18]
  ldxdw r6, [r10-0x20]
  ldxdw r7, [r10-0x28]
  stxdw [r1+0x28], r0
  stxdw [r1+0x20], r9
  stxdw [r1+0x7], r7
  stxdw [r1+0xf], r6
  stxdw [r1+0x17], r5
  ldxdw r5, [r10-0x78]
  stxb [r1+0x1f], r5
  ldxdw r5, [r10-0xa8]
  stxb [r1+0xbd], r5
  ldxdw r5, [r10-0x30]
  stxb [r1+0xbc], r5
  stxb [r1+0xbb], r8
  ldxdw r5, [r10-0x70]
  stxb [r1+0xba], r5
  ldxdw r5, [r10-0x68]
  stxh [r1+0xb8], r5
  ldxdw r5, [r10-0x80]
  stxh [r1+0xb6], r5
  ldxdw r5, [r10-0x88]
  stxh [r1+0xb4], r5
  ldxdw r5, [r10-0xe8]
  stxw [r1+0xb0], r5
  ldxdw r5, [r10-0x100]
  stxdw [r1+0xa8], r5
  ldxdw r5, [r10-0xf8]
  stxdw [r1+0xa0], r5
  ldxdw r5, [r10-0x108]
  stxdw [r1+0x98], r5
  ldxdw r5, [r10-0xe0]
  stxdw [r1+0x90], r5
  ldxdw r5, [r10-0xd8]
  stxdw [r1+0x88], r5
  ldxdw r5, [r10-0xd0]
  stxdw [r1+0x80], r5
  ldxdw r5, [r10-0xa0]
  stxdw [r1+0x78], r5
  ldxdw r5, [r10-0xf0]
  stxdw [r1+0x70], r5
  ldxdw r5, [r10-0xc8]
  stxdw [r1+0x68], r5
  ldxdw r5, [r10-0xc0]
  stxdw [r1+0x60], r5
  ldxdw r5, [r10-0x40]
  stxdw [r1+0x58], r5
  ldxdw r5, [r10-0x38]
  stxdw [r1+0x50], r5
  ldxdw r5, [r10-0x50]
  stxdw [r1+0x48], r5
  ldxdw r5, [r10-0x48]
  stxdw [r1+0x40], r5
  ldxdw r5, [r10-0x58]
  stxdw [r1+0x38], r5
  ldxdw r5, [r10-0x60]
  stxdw [r1+0x30], r5
  ldxdw r5, [r10-0xb0]
  stxb [r1+0xbe], r5
  stxw [r1+0x0], r4
  ja jmp_1468

jmp_1730:
  lddw r1, data_0678
  call fn_2bcf8

fn_1748:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_17e0
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_17e0
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_17e0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_17e0
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_17f8
  lddw r2, 0xb00000001
  stxdw [r1+0x0], r2
  stw [r1+0x8], 0x0
  ja jmp_17f0

jmp_17e0:
  stw [r1+0x8], 0x2
  stdw [r1+0x0], 0x1

jmp_17f0:
  exit

jmp_17f8:
  mov64 r4, 0x2
  add64 r3, -0x1
  stxb [r2+0x0], r3
  ldxdw r5, [r2+0x50]
  jne r5, 0x32, jmp_18b8
  mov64 r4, 0x13
  ldxdw r5, [r2+0x58]
  lddw r0, 0x31303043524f5443
  jne r5, r0, jmp_18b8
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
  ja jmp_18c8

jmp_18b8:
  stxw [r1+0x8], r4
  stdw [r1+0x0], 0x1

jmp_18c8:
  and64 r3, 0xff
  add64 r3, 0x1
  mov64 r1, r3
  and64 r1, 0xff
  jne r1, r3, jmp_1900
  stxb [r2+0x0], r3
  ja jmp_17f0

jmp_1900:
  lddw r1, data_0678
  call fn_2bcf8

fn_1918:
  ldxdw r4, [r3+0x0]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_19a0
  ldxdw r4, [r3+0x8]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_19a0
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x38]
  jne r5, r4, jmp_19a0
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x40]
  jne r4, r3, jmp_19a0
  ldxb r3, [r2+0x0]
  jge r3, 0x2, jmp_19c8
  stb [r1+0xb8], 0x2
  stdw [r1+0x0], 0xb
  ja jmp_19c0

jmp_19a0:
  lddw r2, 0x200000000
  stxdw [r1+0x0], r2
  stb [r1+0xb8], 0x2

jmp_19c0:
  exit

jmp_19c8:
  add64 r3, -0x1
  stxb [r2+0x0], r3
  mov64 r0, 0x2
  ldxdw r7, [r2+0x50]
  jeq r7, 0xc1, jmp_1a28
  jne r7, 0xb9, jmp_23f0
  mov64 r8, 0x1
  ldxdw r3, [r2+0x58]
  lddw r4, 0x343030544b4d5443
  jeq r3, r4, jmp_1a50
  ja jmp_23f0

jmp_1a28:
  mov64 r8, 0x0
  ldxdw r3, [r2+0x58]
  lddw r4, 0x353030544b4d5443
  jne r3, r4, jmp_23f0

jmp_1a50:
  mov64 r0, 0x1
  ldxh r6, [r2+0x62]
  ldxh r5, [r2+0x60]
  ldxb r3, [r2+0x64]
  mov64 r4, 0x0
  jeq r3, 0x0, jmp_1a90
  jne r3, 0x1, jmp_23f0
  mov64 r4, 0x1

jmp_1a90:
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
  jeq r8, 0x0, jmp_1da8
  mov64 r8, 0xb9
  ja jmp_1dc8

jmp_1da8:
  jlt r7, 0xc1, jmp_23f0
  mov64 r8, 0xc1
  ldxdw r6, [r2+0x111]
  stxdw [r10-0xa0], r6

jmp_1dc8:
  jne r8, r7, jmp_23f0
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
  ja jmp_2408

jmp_23f0:
  stxw [r1+0x4], r0
  stb [r1+0xb8], 0x2
  stw [r1+0x0], 0x0

jmp_2408:
  ldxb r1, [r2+0x0]
  add64 r1, 0x1
  mov64 r3, r1
  and64 r3, 0xff
  jne r3, r1, jmp_2440
  stxb [r2+0x0], r1
  ja jmp_19c0

jmp_2440:
  lddw r1, data_0678
  call fn_2bcf8

fn_2458:
  ldxb r3, [r1+0x2]
  jeq r3, 0x0, jmp_2490
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_24a8
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_2520

jmp_2490:
  mov64 r0, 0x0
  mov64 r1, 0x2
  ja jmp_2520

jmp_24a8:
  ldxdw r3, [r1+0x50]
  mov64 r4, r1
  add64 r4, 0x58
  mov64 r6, r1
  mov64 r1, r2
  mov64 r2, r4
  call fn_2b890
  mov64 r1, r0
  stb [r6+0x0], 0xff
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x0, jmp_2518
  mov64 r0, 0x0
  ja jmp_2520

jmp_2518:
  mov64 r0, 0x1a

jmp_2520:
  exit

fn_2528:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2570
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_2580
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_2600

jmp_2570:
  mov64 r0, 0x0
  ja jmp_2600

jmp_2580:
  mov64 r0, 0x0
  ldxdw r4, [r3+0x50]
  jne r4, 0x28, jmp_25f8
  lddw r4, 0x3130304645525443
  stxdw [r3+0x58], r4
  ldxdw r4, [r2+0x0]
  stxdw [r3+0x60], r4
  ldxdw r4, [r2+0x8]
  stxdw [r3+0x68], r4
  ldxdw r4, [r2+0x10]
  stxdw [r3+0x70], r4
  ldxdw r2, [r2+0x18]
  stxdw [r3+0x78], r2
  mov64 r0, 0x1a

jmp_25f8:
  stb [r3+0x0], 0xff

jmp_2600:
  exit

fn_2608:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2650
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_2660
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_2710

jmp_2650:
  mov64 r0, 0x0
  ja jmp_2710

jmp_2660:
  mov64 r0, 0x0
  ldxdw r4, [r3+0x50]
  jne r4, 0x40, jmp_2708
  lddw r4, 0x3130304555515443
  stxdw [r3+0x58], r4
  ldxdw r4, [r2+0x20]
  stxdw [r3+0x60], r4
  ldxdw r4, [r2+0x0]
  stxdw [r3+0x68], r4
  ldxdw r4, [r2+0x8]
  stxdw [r3+0x70], r4
  ldxdw r4, [r2+0x10]
  stxdw [r3+0x78], r4
  ldxdw r4, [r2+0x18]
  stxdw [r3+0x80], r4
  ldxdw r4, [r2+0x28]
  stxdw [r3+0x88], r4
  ldxdw r2, [r2+0x30]
  stxdw [r3+0x90], r2
  mov64 r0, 0x1a

jmp_2708:
  stb [r3+0x0], 0xff

jmp_2710:
  exit

fn_2718:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2760
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_2770
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_2810

jmp_2760:
  mov64 r0, 0x0
  ja jmp_2810

jmp_2770:
  mov64 r0, 0x0
  ldxdw r4, [r3+0x50]
  jne r4, 0x32, jmp_2808
  lddw r4, 0x31303043524f5443
  stxdw [r3+0x58], r4
  ldxh r4, [r2+0x28]
  stxh [r3+0x60], r4
  ldxdw r4, [r2+0x0]
  stxdw [r3+0x62], r4
  ldxdw r4, [r2+0x8]
  stxdw [r3+0x6a], r4
  ldxdw r4, [r2+0x10]
  stxdw [r3+0x72], r4
  ldxdw r4, [r2+0x18]
  stxdw [r3+0x7a], r4
  ldxdw r2, [r2+0x20]
  stxdw [r3+0x82], r2
  mov64 r0, 0x1a

jmp_2808:
  stb [r3+0x0], 0xff

jmp_2810:
  exit

fn_2818:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2860
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_2870
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_2b00

jmp_2860:
  mov64 r0, 0x0
  ja jmp_2b00

jmp_2870:
  ldxdw r4, [r3+0x50]
  jne r4, 0xaf, jmp_28d0
  mov64 r0, 0x0
  ldxdw r5, [r2+0x98]
  jne r5, 0x0, jmp_2af8
  ldxdw r5, [r2+0xa0]
  jne r5, 0x0, jmp_2af8
  lddw r5, 0x343030534f505443
  ldxdw r6, [r2+0xa8]
  jeq r6, 0x0, jmp_28f0
  ja jmp_2af8

jmp_28d0:
  mov64 r0, 0x0
  lddw r5, 0x353030534f505443
  jne r4, 0xc7, jmp_2af8

jmp_28f0:
  stxdw [r3+0x58], r5
  ldxdw r5, [r2+0x0]
  stxdw [r3+0x60], r5
  ldxdw r5, [r2+0x8]
  stxdw [r3+0x68], r5
  ldxdw r5, [r2+0x10]
  stxdw [r3+0x70], r5
  ldxdw r5, [r2+0x18]
  stxdw [r3+0x78], r5
  ldxdw r5, [r2+0x30]
  stxdw [r3+0x80], r5
  ldxh r5, [r2+0xb4]
  stxh [r3+0x88], r5
  ldxdw r5, [r2+0x38]
  stxdw [r3+0x8a], r5
  ldxh r5, [r2+0xb6]
  stxh [r3+0x92], r5
  ldxdw r5, [r2+0x40]
  stxdw [r3+0x94], r5
  ldxdw r5, [r2+0x20]
  ldxdw r0, [r2+0x28]
  stxdw [r3+0xa4], r0
  stxdw [r3+0x9c], r5
  ldxdw r5, [r2+0x48]
  stxdw [r3+0xac], r5
  ldxb r5, [r2+0xba]
  stxb [r3+0xb4], r5
  ldxh r5, [r2+0xb8]
  stxh [r3+0xb5], r5
  ldxdw r5, [r2+0x50]
  stxdw [r3+0xb7], r5
  ldxdw r5, [r2+0x58]
  stxdw [r3+0xbf], r5
  ldxb r5, [r2+0xbb]
  stxb [r3+0xc7], r5
  ldxb r5, [r2+0xbc]
  stxb [r3+0xc8], r5
  ldxb r5, [r2+0xbd]
  stxb [r3+0xc9], r5
  ldxdw r5, [r2+0x60]
  stxdw [r3+0xca], r5
  ldxdw r5, [r2+0x68]
  stxdw [r3+0xd2], r5
  ldxb r5, [r2+0xbe]
  stxb [r3+0xda], r5
  ldxdw r5, [r2+0x70]
  stxdw [r3+0xdb], r5
  ldxdw r5, [r2+0x78]
  stxdw [r3+0xe3], r5
  ldxdw r5, [r2+0x80]
  stxdw [r3+0xeb], r5
  ldxdw r5, [r2+0x88]
  stxdw [r3+0xf3], r5
  ldxdw r5, [r2+0x90]
  stxdw [r3+0xfb], r5
  ldxw r5, [r2+0xb0]
  stxw [r3+0x103], r5
  mov64 r0, 0x1a
  jeq r4, 0xaf, jmp_2af8
  ldxdw r4, [r2+0x98]
  stxdw [r3+0x107], r4
  ldxdw r4, [r2+0xa0]
  stxdw [r3+0x10f], r4
  ldxdw r2, [r2+0xa8]
  stxdw [r3+0x117], r2

jmp_2af8:
  stb [r3+0x0], 0xff

jmp_2b00:
  exit

fn_2b08:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_2b50
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_2b60
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_32d8

jmp_2b50:
  mov64 r0, 0x0
  ja jmp_32d8

jmp_2b60:
  ldxdw r4, [r3+0x50]
  mov64 r5, 0x1
  mov64 r0, 0x1
  jne r4, 0x15a, jmp_2bd0
  jne r4, 0x156, jmp_2be0

jmp_2b88:
  jeq r5, r0, jmp_2bf0

jmp_2b90:
  mov64 r0, 0x0
  mov64 r7, 0x1
  mov64 r6, 0x1
  jne r4, 0x156, jmp_2f18
  ldxw r5, [r2+0x14c]
  jeq r5, 0x32, jmp_2f30

jmp_2bc0:
  jle r5, 0x3e8, jmp_2f40
  ja jmp_32d0

jmp_2bd0:
  mov64 r0, 0x0
  jeq r4, 0x156, jmp_2b88

jmp_2be0:
  mov64 r5, 0x0
  jne r5, r0, jmp_2b90

jmp_2bf0:
  mov64 r0, 0x0
  jne r4, 0x15b, jmp_32d0
  ldxw r4, [r2+0x14c]
  mov64 r5, r4
  jgt r5, 0x3e8, jmp_32d0
  lddw r5, 0x3530304746435443
  stxdw [r3+0x58], r5
  ldxdw r5, [r2+0x18]
  stxdw [r3+0x78], r5
  ldxdw r5, [r2+0x10]
  stxdw [r3+0x70], r5
  ldxdw r5, [r2+0x8]
  stxdw [r3+0x68], r5
  ldxdw r5, [r2+0x0]
  stxdw [r3+0x60], r5
  ldxdw r5, [r2+0x38]
  stxdw [r3+0x98], r5
  ldxdw r5, [r2+0x30]
  stxdw [r3+0x90], r5
  ldxdw r5, [r2+0x28]
  stxdw [r3+0x88], r5
  ldxdw r5, [r2+0x20]
  stxdw [r3+0x80], r5
  ldxdw r5, [r2+0x40]
  stxdw [r3+0xa0], r5
  ldxdw r5, [r2+0x48]
  stxdw [r3+0xa8], r5
  ldxdw r5, [r2+0x50]
  stxdw [r3+0xb0], r5
  ldxdw r5, [r2+0x58]
  stxdw [r3+0xb8], r5
  ldxdw r5, [r2+0x60]
  stxdw [r3+0xc0], r5
  ldxdw r5, [r2+0x68]
  stxdw [r3+0xc8], r5
  ldxdw r5, [r2+0x70]
  stxdw [r3+0xd0], r5
  ldxdw r5, [r2+0x78]
  stxdw [r3+0xd8], r5
  ldxdw r5, [r2+0x80]
  stxdw [r3+0xe0], r5
  ldxdw r5, [r2+0x88]
  stxdw [r3+0xe8], r5
  ldxdw r5, [r2+0x90]
  stxdw [r3+0xf0], r5
  ldxdw r5, [r2+0x98]
  stxdw [r3+0xf8], r5
  ldxdw r5, [r2+0xa0]
  stxdw [r3+0x100], r5
  ldxdw r5, [r2+0xa8]
  stxdw [r3+0x108], r5
  ldxdw r5, [r2+0xb0]
  stxdw [r3+0x110], r5
  ldxdw r5, [r2+0xb8]
  stxdw [r3+0x118], r5
  ldxdw r5, [r2+0xc0]
  stxdw [r3+0x120], r5
  ldxdw r5, [r2+0xc8]
  stxdw [r3+0x128], r5
  ldxdw r5, [r2+0xd8]
  stxdw [r3+0x138], r5
  ldxdw r5, [r2+0xd0]
  stxdw [r3+0x130], r5
  ldxdw r5, [r2+0xe0]
  stxdw [r3+0x140], r5
  ldxdw r5, [r2+0xe8]
  stxdw [r3+0x148], r5
  ldxdw r5, [r2+0xf0]
  stxdw [r3+0x150], r5
  ldxdw r5, [r2+0xf8]
  stxdw [r3+0x158], r5
  ldxdw r5, [r2+0x100]
  stxdw [r3+0x160], r5
  ldxdw r5, [r2+0x108]
  stxdw [r3+0x168], r5
  ldxdw r5, [r2+0x110]
  stxdw [r3+0x170], r5
  ldxdw r5, [r2+0x118]
  stxdw [r3+0x178], r5
  ldxdw r5, [r2+0x120]
  stxdw [r3+0x180], r5
  ldxdw r5, [r2+0x128]
  stxdw [r3+0x188], r5
  ldxdw r5, [r2+0x130]
  stxdw [r3+0x190], r5
  ldxdw r5, [r2+0x138]
  stxdw [r3+0x198], r5
  ldxb r5, [r2+0x150]
  stxb [r3+0x1a0], r5
  ldxb r5, [r2+0x151]
  stxb [r3+0x1a1], r5
  ldxdw r5, [r2+0x140]
  stxdw [r3+0x1a2], r5
  ldxw r5, [r2+0x148]
  stxw [r3+0x1ae], r4
  stxw [r3+0x1aa], r5
  ldxb r2, [r2+0x152]
  stxb [r3+0x1b2], r2
  mov64 r0, 0x1a
  ja jmp_32d0

jmp_2f18:
  mov64 r6, 0x0
  ldxw r5, [r2+0x14c]
  jne r5, 0x32, jmp_2bc0

jmp_2f30:
  mov64 r7, 0x0
  jgt r5, 0x3e8, jmp_32d0

jmp_2f40:
  and64 r6, r7
  and64 r6, 0x1
  jne r6, 0x0, jmp_32d0
  jlt r4, 0x8, jmp_32d0
  ldxb r6, [r2+0x152]
  and64 r6, 0x1
  jne r6, 0x0, jmp_32d0
  lddw r6, 0x3430304746435443
  jne r4, 0x15a, jmp_2fc0
  lddw r7, 0x3330304746435443
  jne r4, 0x156, jmp_2fe8

jmp_2fa8:
  stxdw [r3+0x58], r7
  jge r4, 0x28, jmp_3000
  ja jmp_32d0

jmp_2fc0:
  lddw r6, 0x3530304746435443
  lddw r7, 0x3330304746435443
  jeq r4, 0x156, jmp_2fa8

jmp_2fe8:
  mov64 r7, r6
  stxdw [r3+0x58], r7
  jlt r4, 0x28, jmp_32d0

jmp_3000:
  ldxdw r6, [r2+0x18]
  stxdw [r3+0x78], r6
  ldxdw r6, [r2+0x10]
  stxdw [r3+0x70], r6
  ldxdw r6, [r2+0x8]
  stxdw [r3+0x68], r6
  ldxdw r6, [r2+0x0]
  stxdw [r3+0x60], r6
  jlt r4, 0x48, jmp_32d0
  ldxdw r6, [r2+0x38]
  stxdw [r3+0x98], r6
  ldxdw r6, [r2+0x30]
  stxdw [r3+0x90], r6
  ldxdw r6, [r2+0x28]
  stxdw [r3+0x88], r6
  ldxdw r6, [r2+0x20]
  stxdw [r3+0x80], r6
  jlt r4, 0x68, jmp_32d0
  ldxdw r6, [r2+0x58]
  stxdw [r3+0xb8], r6
  ldxdw r6, [r2+0x50]
  stxdw [r3+0xb0], r6
  ldxdw r6, [r2+0x48]
  stxdw [r3+0xa8], r6
  ldxdw r6, [r2+0x40]
  stxdw [r3+0xa0], r6
  jlt r4, 0x88, jmp_32d0
  ldxdw r6, [r2+0x78]
  stxdw [r3+0xd8], r6
  ldxdw r6, [r2+0x70]
  stxdw [r3+0xd0], r6
  ldxdw r6, [r2+0x68]
  stxdw [r3+0xc8], r6
  ldxdw r6, [r2+0x60]
  stxdw [r3+0xc0], r6
  jlt r4, 0xa8, jmp_32d0
  ldxdw r6, [r2+0x98]
  stxdw [r3+0xf8], r6
  ldxdw r6, [r2+0x90]
  stxdw [r3+0xf0], r6
  ldxdw r6, [r2+0x88]
  stxdw [r3+0xe8], r6
  ldxdw r6, [r2+0x80]
  stxdw [r3+0xe0], r6
  jlt r4, 0xc8, jmp_32d0
  ldxdw r6, [r2+0xb8]
  stxdw [r3+0x118], r6
  ldxdw r6, [r2+0xb0]
  stxdw [r3+0x110], r6
  ldxdw r6, [r2+0xa8]
  stxdw [r3+0x108], r6
  ldxdw r6, [r2+0xa0]
  stxdw [r3+0x100], r6
  jlt r4, 0xe8, jmp_32d0
  ldxdw r6, [r2+0xd8]
  stxdw [r3+0x138], r6
  ldxdw r6, [r2+0xd0]
  stxdw [r3+0x130], r6
  ldxdw r6, [r2+0xc8]
  stxdw [r3+0x128], r6
  ldxdw r6, [r2+0xc0]
  stxdw [r3+0x120], r6
  jlt r4, 0x108, jmp_32d0
  ldxdw r6, [r2+0xf8]
  stxdw [r3+0x158], r6
  ldxdw r6, [r2+0xf0]
  stxdw [r3+0x150], r6
  ldxdw r6, [r2+0xe8]
  stxdw [r3+0x148], r6
  ldxdw r6, [r2+0xe0]
  stxdw [r3+0x140], r6
  jlt r4, 0x128, jmp_32d0
  ldxdw r6, [r2+0x118]
  stxdw [r3+0x178], r6
  ldxdw r6, [r2+0x110]
  stxdw [r3+0x170], r6
  ldxdw r6, [r2+0x108]
  stxdw [r3+0x168], r6
  ldxdw r6, [r2+0x100]
  stxdw [r3+0x160], r6
  jlt r4, 0x148, jmp_32d0
  ldxdw r6, [r2+0x138]
  stxdw [r3+0x198], r6
  ldxdw r6, [r2+0x130]
  stxdw [r3+0x190], r6
  ldxdw r6, [r2+0x128]
  stxdw [r3+0x188], r6
  ldxdw r6, [r2+0x120]
  stxdw [r3+0x180], r6
  jne r4, 0x148, jmp_32e0

jmp_32d0:
  stb [r3+0x0], 0xff

jmp_32d8:
  exit

jmp_32e0:
  ldxb r6, [r2+0x150]
  stxb [r3+0x1a0], r6
  jlt r4, 0x14a, jmp_32d0
  ldxb r6, [r2+0x151]
  stxb [r3+0x1a1], r6
  jlt r4, 0x152, jmp_32d0
  ldxdw r6, [r2+0x140]
  stxdw [r3+0x1a2], r6
  jlt r4, 0x156, jmp_32d0
  ldxw r2, [r2+0x148]
  stxw [r3+0x1aa], r2
  jne r4, 0x156, jmp_3350
  mov64 r0, 0x1a
  ja jmp_32d0

jmp_3350:
  jlt r4, 0x15a, jmp_32d0
  stxw [r3+0x1ae], r5
  mov64 r0, 0x1a
  ja jmp_32d0

fn_3370:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_33b8
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_33c8
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_35b8

jmp_33b8:
  mov64 r0, 0x0
  ja jmp_35b8

jmp_33c8:
  mov64 r0, 0x0
  ldxdw r4, [r3+0x50]
  jne r4, 0xc1, jmp_35b0
  lddw r4, 0x353030544b4d5443
  stxdw [r3+0x58], r4
  ldxh r4, [r2+0xb0]
  stxh [r3+0x60], r4
  ldxh r4, [r2+0xb2]
  stxh [r3+0x62], r4
  ldxb r4, [r2+0xb8]
  stxb [r3+0x64], r4
  ldxdw r4, [r2+0x0]
  stxdw [r3+0x65], r4
  ldxdw r4, [r2+0x8]
  stxdw [r3+0x6d], r4
  ldxdw r4, [r2+0x10]
  ldxdw r5, [r2+0x18]
  stxdw [r3+0x7d], r5
  stxdw [r3+0x75], r4
  ldxdw r4, [r2+0x20]
  ldxdw r5, [r2+0x28]
  stxdw [r3+0x8d], r5
  stxdw [r3+0x85], r4
  ldxdw r4, [r2+0x30]
  ldxdw r5, [r2+0x38]
  stxdw [r3+0x9d], r5
  stxdw [r3+0x95], r4
  ldxdw r4, [r2+0x40]
  ldxdw r5, [r2+0x48]
  stxdw [r3+0xad], r5
  stxdw [r3+0xa5], r4
  ldxdw r4, [r2+0x50]
  ldxdw r5, [r2+0x58]
  stxdw [r3+0xbd], r5
  stxdw [r3+0xb5], r4
  ldxdw r4, [r2+0x60]
  ldxdw r5, [r2+0x68]
  stxdw [r3+0xcd], r5
  stxdw [r3+0xc5], r4
  ldxdw r4, [r2+0x70]
  ldxdw r5, [r2+0x78]
  stxdw [r3+0xdd], r5
  stxdw [r3+0xd5], r4
  ldxdw r4, [r2+0x80]
  ldxdw r5, [r2+0x88]
  stxdw [r3+0xed], r5
  stxdw [r3+0xe5], r4
  ldxdw r4, [r2+0x90]
  stxdw [r3+0xf5], r4
  ldxdw r4, [r2+0x98]
  stxdw [r3+0xfd], r4
  ldxdw r4, [r2+0xa0]
  stxdw [r3+0x105], r4
  ldxh r4, [r2+0xb4]
  stxh [r3+0x10d], r4
  ldxh r4, [r2+0xb6]
  stxh [r3+0x10f], r4
  ldxdw r2, [r2+0xa8]
  stxdw [r3+0x111], r2
  mov64 r0, 0x1a

jmp_35b0:
  stb [r3+0x0], 0xff

jmp_35b8:
  exit

fn_35c0:
  mov64 r3, r1
  mov64 r1, 0x2
  ldxb r4, [r3+0x2]
  jeq r4, 0x0, jmp_3608
  ldxb r4, [r3+0x0]
  jeq r4, 0xff, jmp_3618
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_3818

jmp_3608:
  mov64 r0, 0x0
  ja jmp_3818

jmp_3618:
  ldxdw r4, [r3+0x50]
  jne r4, 0xac, jmp_3668
  mov64 r0, 0x0
  ldxh r5, [r2+0xa8]
  jne r5, 0x0, jmp_3810
  lddw r5, 0x3330304c4f505443
  ldxw r6, [r2+0xa4]
  jeq r6, 0x0, jmp_3688
  ja jmp_3810

jmp_3668:
  mov64 r0, 0x0
  lddw r5, 0x3430304c4f505443
  jne r4, 0xb2, jmp_3810

jmp_3688:
  stxdw [r3+0x58], r5
  ldxdw r5, [r2+0x20]
  stxdw [r3+0x60], r5
  ldxdw r5, [r2+0x28]
  stxdw [r3+0x68], r5
  ldxdw r5, [r2+0x30]
  stxdw [r3+0x70], r5
  ldxdw r5, [r2+0x38]
  stxdw [r3+0x78], r5
  ldxdw r5, [r2+0x40]
  stxdw [r3+0x80], r5
  ldxdw r5, [r2+0x48]
  stxdw [r3+0x88], r5
  ldxdw r5, [r2+0x50]
  stxdw [r3+0x90], r5
  ldxdw r5, [r2+0x58]
  stxdw [r3+0x98], r5
  ldxdw r5, [r2+0x60]
  stxdw [r3+0xa0], r5
  ldxdw r5, [r2+0x68]
  stxdw [r3+0xa8], r5
  ldxdw r5, [r2+0x70]
  stxdw [r3+0xb0], r5
  ldxdw r5, [r2+0x0]
  ldxdw r0, [r2+0x8]
  stxdw [r3+0xc0], r0
  stxdw [r3+0xb8], r5
  ldxdw r5, [r2+0x78]
  stxdw [r3+0xc8], r5
  ldxdw r5, [r2+0x80]
  stxdw [r3+0xd0], r5
  ldxdw r5, [r2+0x88]
  stxdw [r3+0xd8], r5
  ldxdw r5, [r2+0x10]
  ldxdw r0, [r2+0x18]
  stxdw [r3+0xe8], r0
  stxdw [r3+0xe0], r5
  ldxdw r5, [r2+0x90]
  stxdw [r3+0xf0], r5
  ldxw r5, [r2+0xa0]
  stxw [r3+0xf8], r5
  ldxdw r5, [r2+0x98]
  stxdw [r3+0xfc], r5
  mov64 r0, 0x1a
  jeq r4, 0xac, jmp_3810
  ldxh r4, [r2+0xa8]
  stxh [r3+0x104], r4
  ldxw r2, [r2+0xa4]
  stxw [r3+0x106], r2

jmp_3810:
  stb [r3+0x0], 0xff

jmp_3818:
  exit

fn_3820:
  mov64 r8, r3
  mov64 r6, r2
  mov64 r7, r1
  mov64 r1, r6
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r8
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_3910
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r6+0x28]
  jne r2, r1, jmp_3930
  ldxdw r1, [r8+0x8]
  ldxdw r2, [r6+0x30]
  jne r2, r1, jmp_3930
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r6+0x38]
  jne r2, r1, jmp_3930
  ldxdw r1, [r8+0x18]
  ldxdw r2, [r6+0x40]
  jne r2, r1, jmp_3930
  ldxb r8, [r6+0x0]
  jgt r8, 0x1, jmp_3958
  stb [r7+0x152], 0x2
  stdw [r7+0x0], 0xb
  ja jmp_3950

jmp_3910:
  stxw [r7+0x0], r0
  rsh64 r0, 0x20
  stxw [r7+0x4], r0
  ja jmp_3948

jmp_3930:
  lddw r1, 0x200000000
  stxdw [r7+0x0], r1

jmp_3948:
  stb [r7+0x152], 0x2

jmp_3950:
  exit

jmp_3958:
  add64 r8, -0x1
  stxb [r6+0x0], r8
  ldxdw r3, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x158
  call fn_28bc8
  ldxw r1, [r10-0x158]
  ldxb r9, [r10-0x6]
  jne r9, 0x2, jmp_39d0
  stxw [r7+0x4], r1
  stb [r7+0x152], 0x2
  stw [r7+0x0], 0x0
  ja jmp_3a40

jmp_39d0:
  stxdw [r10-0x160], r1
  mov64 r1, r7
  add64 r1, 0x4
  mov64 r2, r10
  add64 r2, -0x154
  mov64 r3, 0x14e
  call fn_2c060
  ldxw r1, [r10-0x5]
  stxw [r7+0x153], r1
  ldxb r1, [r10-0x1]
  stxb [r7+0x157], r1
  stxb [r7+0x152], r9
  ldxdw r1, [r10-0x160]
  stxw [r7+0x0], r1

jmp_3a40:
  and64 r8, 0xff
  add64 r8, 0x1
  mov64 r1, r8
  and64 r1, 0xff
  jne r1, r8, jmp_3a78
  stxb [r6+0x0], r8
  ja jmp_3950

jmp_3a78:
  lddw r1, data_0678
  call fn_2bcf8

fn_3a90:
  mov64 r4, r3
  mov64 r3, 0x0
  mov64 r5, 0x2
  ldxdw r0, [r4+0x0]
  ldxdw r6, [r2+0x28]
  jne r6, r0, jmp_5970
  ldxdw r0, [r4+0x8]
  ldxdw r6, [r2+0x30]
  jne r6, r0, jmp_5970
  ldxdw r0, [r4+0x10]
  ldxdw r6, [r2+0x38]
  jne r6, r0, jmp_5970
  ldxdw r0, [r4+0x18]
  ldxdw r6, [r2+0x40]
  jne r6, r0, jmp_5970
  ldxb r5, [r2+0x0]
  jgt r5, 0x1, jmp_3b30
  mov64 r3, 0xb
  mov64 r5, 0x0
  ja jmp_5970

jmp_3b30:
  add64 r5, -0x1
  stxb [r2+0x0], r5
  mov64 r5, 0x2
  ldxdw r0, [r2+0x50]
  jne r0, 0x1d2, jmp_5940
  mov64 r5, 0x13
  ldxdw r0, [r2+0x58]
  lddw r6, 0x3430305253555443
  jne r0, r6, jmp_5940
  ldxb r5, [r2+0xda]
  stxdw [r10-0x508], r5
  ldxh r5, [r2+0xd8]
  stxdw [r10-0x408], r5
  ldxw r5, [r2+0xdb]
  stxdw [r10-0x340], r5
  ldxb r5, [r2+0xe7]
  stxdw [r10-0x368], r5
  ldxdw r5, [r2+0xdf]
  stxdw [r10-0x400], r5
  mov64 r6, 0x0
  mov64 r5, 0x1
  ldxdw r8, [r2+0xf0]
  ldxdw r9, [r2+0xe8]
  ldxdw r0, [r2+0xd0]
  stxdw [r10-0x4c0], r0
  ldxdw r0, [r2+0xc8]
  stxdw [r10-0x4c8], r0
  ldxdw r0, [r2+0xc0]
  stxdw [r10-0x4d0], r0
  ldxdw r0, [r2+0xb8]
  stxdw [r10-0x4d8], r0
  ldxw r0, [r2+0x9b]
  stxdw [r10-0x500], r0
  ldxdw r0, [r2+0x90]
  stxdw [r10-0x4e0], r0
  ldxdw r0, [r2+0x88]
  stxdw [r10-0x4e8], r0
  ldxdw r0, [r2+0x80]
  stxdw [r10-0x4f0], r0
  ldxw r0, [r2+0x63]
  stxdw [r10-0x4f8], r0
  ldxb r0, [r2+0xf8]
  mov64 r7, 0x0
  jeq r0, 0x0, jmp_3ca8
  jne r0, 0x1, jmp_5940
  mov64 r7, 0x1

jmp_3ca8:
  ldxb r0, [r2+0xf9]
  jeq r0, 0x0, jmp_3cc8
  jne r0, 0x1, jmp_5940
  mov64 r6, 0x1

jmp_3cc8:
  stxdw [r10-0x510], r9
  stxdw [r10-0x598], r8
  stxdw [r10-0x590], r7
  stxdw [r10-0x588], r6
  mov64 r5, r2
  add64 r5, 0x9f
  mov64 r8, r2
  add64 r8, 0x98
  mov64 r6, r2
  add64 r6, 0x60
  ldxdw r3, [r2+0x1c2]
  stxdw [r10-0x518], r3
  ldxdw r3, [r2+0x14a]
  stxdw [r10-0x520], r3
  ldxdw r3, [r2+0x142]
  stxdw [r10-0x528], r3
  ldxdw r3, [r2+0x13a]
  stxdw [r10-0x530], r3
  ldxdw r3, [r2+0x132]
  stxdw [r10-0x538], r3
  ldxdw r3, [r2+0x12a]
  stxdw [r10-0x540], r3
  ldxdw r3, [r2+0x122]
  stxdw [r10-0x548], r3
  ldxdw r3, [r2+0x11a]
  stxdw [r10-0x550], r3
  ldxdw r3, [r2+0x112]
  stxdw [r10-0x558], r3
  ldxdw r3, [r2+0xfa]
  stxdw [r10-0x560], r3
  ldxdw r3, [r2+0x109]
  stxdw [r10-0x418], r3
  ldxb r3, [r2+0x111]
  stxdw [r10-0x388], r3
  ldxdw r3, [r2+0x159]
  stxdw [r10-0x420], r3
  ldxb r3, [r2+0x161]
  stxdw [r10-0x390], r3
  ldxdw r3, [r2+0x169]
  stxdw [r10-0x428], r3
  ldxb r3, [r2+0x171]
  stxdw [r10-0x398], r3
  ldxdw r3, [r2+0x179]
  stxdw [r10-0x430], r3
  ldxb r3, [r2+0x181]
  stxdw [r10-0x3a0], r3
  ldxdw r3, [r2+0x189]
  stxdw [r10-0x438], r3
  ldxb r3, [r2+0x191]
  stxdw [r10-0x3a8], r3
  ldxdw r3, [r2+0x199]
  stxdw [r10-0x440], r3
  ldxb r3, [r2+0x1a1]
  stxdw [r10-0x3b8], r3
  ldxdw r3, [r2+0x1a9]
  stxdw [r10-0x448], r3
  ldxb r3, [r2+0x1b1]
  stxdw [r10-0x3c8], r3
  ldxdw r3, [r2+0x1b9]
  stxdw [r10-0x410], r3
  ldxb r3, [r2+0x1c1]
  stxdw [r10-0x3d8], r3
  ldxw r3, [r2+0x175]
  stxdw [r10-0x348], r3
  ldxw r3, [r2+0x155]
  stxdw [r10-0x3b0], r3
  ldxw r3, [r2+0x1b5]
  stxdw [r10-0x358], r3
  ldxw r3, [r2+0x185]
  stxdw [r10-0x350], r3
  ldxw r3, [r2+0x165]
  stxdw [r10-0x3c0], r3
  ldxw r3, [r2+0x105]
  stxdw [r10-0x3f8], r3
  ldxw r3, [r2+0x1a5]
  stxdw [r10-0x360], r3
  ldxw r3, [r2+0x195]
  stxdw [r10-0x3e8], r3
  ldxh r3, [r2+0x182]
  stxdw [r10-0x478], r3
  ldxb r3, [r2+0x184]
  stxdw [r10-0x5c8], r3
  ldxh r3, [r2+0x1b2]
  stxdw [r10-0x470], r3
  ldxb r3, [r2+0x1b4]
  stxdw [r10-0x5d0], r3
  ldxh r3, [r2+0x152]
  stxdw [r10-0x468], r3
  ldxb r3, [r2+0x154]
  stxdw [r10-0x5d8], r3
  ldxh r3, [r2+0x172]
  stxdw [r10-0x498], r3
  ldxb r3, [r2+0x174]
  stxdw [r10-0x5e0], r3
  ldxh r3, [r2+0x192]
  stxdw [r10-0x5c0], r3
  ldxb r3, [r2+0x194]
  stxdw [r10-0x4a8], r3
  ldxh r3, [r2+0x1a2]
  stxdw [r10-0x490], r3
  ldxb r9, [r2+0x1a4]
  ldxh r3, [r2+0x102]
  stxdw [r10-0x488], r3
  ldxb r3, [r2+0x104]
  stxdw [r10-0x5e8], r3
  ldxh r3, [r2+0x162]
  stxdw [r10-0x480], r3
  ldxb r3, [r2+0x164]
  stxdw [r10-0x5f0], r3
  ldxb r7, [r2+0x1cc]
  stxb [r10-0x2e], r7
  ldxh r7, [r2+0x1ca]
  stxh [r10-0x30], r7
  ldxw r3, [r2+0x1cd]
  stxdw [r10-0x570], r3
  ldxb r7, [r2+0x1e9]
  stxb [r10-0x38], r7
  ldxdw r7, [r2+0x1e1]
  stxdw [r10-0x40], r7
  ldxdw r7, [r2+0x1d9]
  stxdw [r10-0x48], r7
  ldxdw r7, [r2+0x1d1]
  stxdw [r10-0x50], r7
  ldxh r7, [r2+0x1ea]
  stxh [r10-0x58], r7
  ldxb r7, [r2+0x1ec]
  stxb [r10-0x56], r7
  ldxw r3, [r2+0x1ed]
  stxdw [r10-0x568], r3
  ldxb r7, [r2+0x1f9]
  stxb [r10-0x60], r7
  ldxdw r7, [r2+0x1f1]
  stxdw [r10-0x68], r7
  ldxw r3, [r2+0x21d]
  stxdw [r10-0x370], r3
  ldxdw r3, [r2+0x201]
  stxdw [r10-0x5a0], r3
  ldxb r3, [r2+0x209]
  stxdw [r10-0x3d0], r3
  ldxdw r3, [r2+0x211]
  stxdw [r10-0x5a8], r3
  ldxb r3, [r2+0x219]
  stxdw [r10-0x3e0], r3
  ldxdw r3, [r2+0x221]
  stxdw [r10-0x5b0], r3
  ldxb r3, [r2+0x229]
  stxdw [r10-0x3f0], r3
  ldxh r3, [r2+0x21a]
  stxdw [r10-0x450], r3
  ldxb r3, [r2+0x21c]
  stxdw [r10-0x4a0], r3
  ldxw r3, [r2+0x20d]
  stxdw [r10-0x380], r3
  ldxw r3, [r2+0x1fd]
  stxdw [r10-0x378], r3
  ldxh r3, [r2+0x1fa]
  stxdw [r10-0x460], r3
  ldxb r3, [r2+0x1fc]
  stxdw [r10-0x4b8], r3
  ldxh r3, [r2+0x20a]
  stxdw [r10-0x458], r3
  ldxb r3, [r2+0x20c]
  stxdw [r10-0x4b0], r3
  ldxb r3, [r6+0x2]
  stxb [r10-0x6], r3
  ldxh r3, [r6+0x0]
  stxh [r10-0x8], r3
  ldxb r3, [r2+0x67]
  stxb [r10-0x1], r3
  ldxdw r3, [r2+0x78]
  stxdw [r10-0x328], r3
  ldxdw r3, [r2+0x70]
  stxdw [r10-0x330], r3
  ldxdw r3, [r2+0x68]
  stxdw [r10-0x338], r3
  ldxh r3, [r8+0x0]
  stxh [r10-0x320], r3
  ldxb r3, [r8+0x2]
  stxb [r10-0x31e], r3
  ldxdw r3, [r5+0x0]
  ldxdw r6, [r5+0x8]
  ldxdw r8, [r5+0x10]
  ldxb r5, [r5+0x18]
  ldxdw r0, [r10-0x4f8]
  stxw [r10-0x5], r0
  stxb [r10-0x10], r5
  stxdw [r10-0x18], r8
  stxdw [r10-0x20], r6
  stxdw [r10-0x28], r3
  ldxw r8, [r10-0x4]
  ldxw r6, [r10-0x8]
  ldxdw r3, [r10-0x338]
  stxdw [r10-0x88], r3
  ldxdw r3, [r10-0x330]
  stxdw [r10-0x80], r3
  ldxdw r3, [r10-0x328]
  stxdw [r10-0x78], r3
  ldxw r3, [r10-0x321]
  stxw [r10-0x71], r3
  ldxb r3, [r10-0x10]
  stxb [r10-0x110], r3
  ldxdw r3, [r10-0x18]
  stxdw [r10-0x118], r3
  ldxdw r3, [r10-0x20]
  stxdw [r10-0x120], r3
  ldxdw r3, [r10-0x28]
  stxdw [r10-0x128], r3
  ldxb r3, [r10-0x2e]
  stxb [r10-0x12e], r3
  ldxh r3, [r10-0x30]
  stxh [r10-0x130], r3
  ldxb r3, [r10-0x38]
  stxb [r10-0x138], r3
  ldxdw r3, [r10-0x40]
  stxdw [r10-0x140], r3
  ldxdw r3, [r10-0x48]
  stxdw [r10-0x148], r3
  ldxdw r3, [r10-0x50]
  stxdw [r10-0x150], r3
  ldxb r3, [r10-0x56]
  stxb [r10-0x156], r3
  ldxh r3, [r10-0x58]
  stxh [r10-0x158], r3
  ldxb r3, [r10-0x60]
  stxb [r10-0x160], r3
  ldxdw r3, [r10-0x68]
  stxdw [r10-0x168], r3
  ldxb r3, [r2+0x0]
  add64 r3, 0x1
  mov64 r5, r3
  and64 r5, 0xff
  stxdw [r10-0x578], r8
  stxdw [r10-0x4f8], r6
  stxdw [r10-0x580], r1
  stxdw [r10-0x5b8], r3
  jne r5, r3, jmp_59b8
  ldxdw r1, [r10-0x508]
  lsh64 r1, 0x10
  ldxdw r0, [r10-0x5f0]
  lsh64 r0, 0x10
  ldxdw r5, [r10-0x5e8]
  lsh64 r5, 0x10
  lsh64 r9, 0x10
  stxdw [r10-0x508], r9
  ldxdw r3, [r10-0x4a8]
  lsh64 r3, 0x10
  stxdw [r10-0x4a8], r3
  ldxdw r9, [r10-0x5e0]
  lsh64 r9, 0x10
  ldxdw r8, [r10-0x5d8]
  lsh64 r8, 0x10
  ldxdw r6, [r10-0x5d0]
  lsh64 r6, 0x10
  ldxdw r3, [r10-0x5c8]
  lsh64 r3, 0x10
  ldxdw r7, [r10-0x4b0]
  lsh64 r7, 0x10
  stxdw [r10-0x4b0], r7
  ldxdw r7, [r10-0x4b8]
  lsh64 r7, 0x10
  stxdw [r10-0x4b8], r7
  ldxdw r7, [r10-0x4a0]
  lsh64 r7, 0x10
  stxdw [r10-0x4a0], r7
  ldxdw r7, [r10-0x408]
  or64 r7, r1
  stxdw [r10-0x408], r7
  ldxdw r1, [r10-0x340]
  lsh64 r1, 0x18
  stxdw [r10-0x340], r1
  ldxdw r1, [r10-0x480]
  or64 r1, r0
  stxdw [r10-0x480], r1
  ldxdw r1, [r10-0x488]
  or64 r1, r5
  stxdw [r10-0x488], r1
  ldxdw r1, [r10-0x490]
  ldxdw r5, [r10-0x508]
  or64 r1, r5
  stxdw [r10-0x490], r1
  ldxdw r5, [r10-0x5c0]
  ldxdw r1, [r10-0x4a8]
  or64 r5, r1
  ldxdw r1, [r10-0x498]
  or64 r1, r9
  stxdw [r10-0x498], r1
  ldxdw r0, [r10-0x468]
  or64 r0, r8
  stxdw [r10-0x468], r0
  ldxdw r1, [r10-0x470]
  or64 r1, r6
  stxdw [r10-0x470], r1
  ldxdw r1, [r10-0x478]
  or64 r1, r3
  stxdw [r10-0x478], r1
  ldxdw r9, [r10-0x3e8]
  lsh64 r9, 0x18
  ldxdw r1, [r10-0x360]
  lsh64 r1, 0x18
  stxdw [r10-0x360], r1
  ldxdw r0, [r10-0x3f8]
  lsh64 r0, 0x18
  mov64 r8, r0
  ldxdw r6, [r10-0x3c0]
  lsh64 r6, 0x18
  ldxdw r1, [r10-0x350]
  lsh64 r1, 0x18
  stxdw [r10-0x350], r1
  ldxdw r1, [r10-0x358]
  lsh64 r1, 0x18
  stxdw [r10-0x358], r1
  ldxdw r7, [r10-0x3b0]
  lsh64 r7, 0x18
  ldxdw r0, [r10-0x348]
  lsh64 r0, 0x18
  stxdw [r10-0x348], r0
  ldxdw r1, [r10-0x458]
  ldxdw r3, [r10-0x4b0]
  or64 r1, r3
  stxdw [r10-0x458], r1
  ldxdw r1, [r10-0x460]
  ldxdw r3, [r10-0x4b8]
  or64 r1, r3
  stxdw [r10-0x460], r1
  ldxdw r1, [r10-0x378]
  lsh64 r1, 0x18
  stxdw [r10-0x378], r1
  ldxdw r1, [r10-0x380]
  lsh64 r1, 0x18
  stxdw [r10-0x380], r1
  ldxdw r1, [r10-0x450]
  ldxdw r3, [r10-0x4a0]
  or64 r1, r3
  stxdw [r10-0x450], r1
  ldxdw r0, [r10-0x370]
  lsh64 r0, 0x18
  stxdw [r10-0x370], r0
  ldxdw r1, [r10-0x340]
  ldxdw r3, [r10-0x408]
  or64 r1, r3
  stxdw [r10-0x340], r1
  ldxdw r1, [r10-0x368]
  lsh64 r1, 0x38
  stxdw [r10-0x368], r1
  ldxdw r3, [r10-0x400]
  mov64 r1, r3
  rsh64 r1, 0x8
  stxdw [r10-0x408], r1
  lsh64 r3, 0x38
  stxdw [r10-0x400], r3
  or64 r9, r5
  stxdw [r10-0x3e8], r9
  ldxdw r5, [r10-0x360]
  ldxdw r1, [r10-0x490]
  or64 r5, r1
  stxdw [r10-0x360], r5
  ldxdw r1, [r10-0x488]
  or64 r8, r1
  stxdw [r10-0x3f8], r8
  ldxdw r1, [r10-0x480]
  or64 r6, r1
  stxdw [r10-0x3c0], r6
  ldxdw r3, [r10-0x350]
  ldxdw r1, [r10-0x478]
  or64 r3, r1
  stxdw [r10-0x350], r3
  ldxdw r1, [r10-0x470]
  ldxdw r3, [r10-0x358]
  or64 r3, r1
  stxdw [r10-0x358], r3
  ldxdw r1, [r10-0x468]
  or64 r7, r1
  stxdw [r10-0x3b0], r7
  ldxdw r1, [r10-0x348]
  ldxdw r3, [r10-0x498]
  or64 r1, r3
  stxdw [r10-0x348], r1
  ldxdw r1, [r10-0x3d8]
  lsh64 r1, 0x38
  stxdw [r10-0x3d8], r1
  ldxdw r3, [r10-0x410]
  rsh64 r3, 0x8
  stxdw [r10-0x468], r3
  ldxdw r1, [r10-0x3c8]
  lsh64 r1, 0x38
  stxdw [r10-0x3c8], r1
  ldxdw r6, [r10-0x448]
  mov64 r3, r6
  rsh64 r3, 0x8
  stxdw [r10-0x470], r3
  ldxdw r1, [r10-0x3b8]
  lsh64 r1, 0x38
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r10-0x440]
  mov64 r3, r1
  mov64 r7, r1
  rsh64 r3, 0x8
  stxdw [r10-0x478], r3
  ldxdw r1, [r10-0x3a8]
  lsh64 r1, 0x38
  stxdw [r10-0x3a8], r1
  ldxdw r1, [r10-0x438]
  mov64 r3, r1
  mov64 r8, r1
  rsh64 r3, 0x8
  stxdw [r10-0x480], r3
  ldxdw r1, [r10-0x3a0]
  lsh64 r1, 0x38
  stxdw [r10-0x3a0], r1
  ldxdw r1, [r10-0x430]
  mov64 r3, r1
  mov64 r9, r1
  rsh64 r3, 0x8
  stxdw [r10-0x488], r3
  ldxdw r1, [r10-0x398]
  lsh64 r1, 0x38
  stxdw [r10-0x398], r1
  ldxdw r0, [r10-0x428]
  mov64 r3, r0
  rsh64 r3, 0x8
  stxdw [r10-0x490], r3
  ldxdw r1, [r10-0x390]
  lsh64 r1, 0x38
  stxdw [r10-0x390], r1
  ldxdw r5, [r10-0x420]
  mov64 r1, r5
  rsh64 r1, 0x8
  stxdw [r10-0x498], r1
  ldxdw r1, [r10-0x388]
  lsh64 r1, 0x38
  stxdw [r10-0x388], r1
  ldxdw r3, [r10-0x418]
  mov64 r1, r3
  rsh64 r1, 0x8
  stxdw [r10-0x4a0], r1
  ldxdw r1, [r10-0x410]
  lsh64 r1, 0x38
  stxdw [r10-0x410], r1
  lsh64 r6, 0x38
  stxdw [r10-0x448], r6
  lsh64 r7, 0x38
  stxdw [r10-0x440], r7
  lsh64 r8, 0x38
  stxdw [r10-0x438], r8
  lsh64 r9, 0x38
  stxdw [r10-0x430], r9
  lsh64 r0, 0x38
  stxdw [r10-0x428], r0
  lsh64 r5, 0x38
  stxdw [r10-0x420], r5
  lsh64 r3, 0x38
  stxdw [r10-0x418], r3
  ldxdw r1, [r10-0x460]
  ldxdw r3, [r10-0x378]
  or64 r3, r1
  stxdw [r10-0x378], r3
  ldxdw r1, [r10-0x458]
  ldxdw r3, [r10-0x380]
  or64 r3, r1
  stxdw [r10-0x380], r3
  ldxdw r1, [r10-0x3f0]
  lsh64 r1, 0x38
  stxdw [r10-0x3f0], r1
  ldxdw r6, [r10-0x5b0]
  mov64 r1, r6
  rsh64 r1, 0x8
  stxdw [r10-0x458], r1
  ldxdw r1, [r10-0x3e0]
  lsh64 r1, 0x38
  stxdw [r10-0x3e0], r1
  ldxdw r5, [r10-0x5a8]
  mov64 r7, r5
  rsh64 r7, 0x8
  ldxdw r1, [r10-0x3d0]
  lsh64 r1, 0x38
  stxdw [r10-0x3d0], r1
  ldxdw r1, [r10-0x5a0]
  mov64 r3, r1
  rsh64 r3, 0x8
  ldxdw r8, [r10-0x370]
  ldxdw r9, [r10-0x450]
  or64 r8, r9
  stxdw [r10-0x370], r8
  lsh64 r6, 0x38
  lsh64 r5, 0x38
  lsh64 r1, 0x38
  ldxdw r8, [r10-0x408]
  ldxdw r0, [r10-0x368]
  or64 r0, r8
  stxdw [r10-0x368], r0
  ldxdw r0, [r10-0x340]
  ldxdw r8, [r10-0x400]
  or64 r0, r8
  stxdw [r10-0x340], r0
  ldxdw r9, [r10-0x3d8]
  ldxdw r0, [r10-0x468]
  or64 r9, r0
  stxdw [r10-0x3d8], r9
  ldxdw r9, [r10-0x3c8]
  ldxdw r0, [r10-0x470]
  or64 r9, r0
  stxdw [r10-0x3c8], r9
  ldxdw r9, [r10-0x3b8]
  ldxdw r0, [r10-0x478]
  or64 r9, r0
  stxdw [r10-0x3b8], r9
  ldxdw r9, [r10-0x3a8]
  ldxdw r0, [r10-0x480]
  or64 r9, r0
  stxdw [r10-0x3a8], r9
  ldxdw r9, [r10-0x3a0]
  ldxdw r0, [r10-0x488]
  or64 r9, r0
  stxdw [r10-0x3a0], r9
  ldxdw r9, [r10-0x398]
  ldxdw r0, [r10-0x490]
  or64 r9, r0
  stxdw [r10-0x398], r9
  ldxdw r9, [r10-0x390]
  ldxdw r0, [r10-0x498]
  or64 r9, r0
  stxdw [r10-0x390], r9
  ldxdw r9, [r10-0x388]
  ldxdw r0, [r10-0x4a0]
  or64 r9, r0
  stxdw [r10-0x388], r9
  ldxdw r0, [r10-0x358]
  ldxdw r8, [r10-0x410]
  or64 r0, r8
  stxdw [r10-0x358], r0
  ldxdw r9, [r10-0x360]
  ldxdw r0, [r10-0x448]
  or64 r9, r0
  stxdw [r10-0x360], r9
  ldxdw r9, [r10-0x3e8]
  ldxdw r0, [r10-0x440]
  or64 r9, r0
  stxdw [r10-0x3e8], r9
  ldxdw r0, [r10-0x438]
  ldxdw r8, [r10-0x350]
  or64 r8, r0
  stxdw [r10-0x350], r8
  ldxdw r9, [r10-0x348]
  ldxdw r0, [r10-0x430]
  or64 r9, r0
  stxdw [r10-0x348], r9
  ldxdw r9, [r10-0x3c0]
  ldxdw r0, [r10-0x428]
  or64 r9, r0
  stxdw [r10-0x3c0], r9
  ldxdw r9, [r10-0x3b0]
  ldxdw r0, [r10-0x420]
  or64 r9, r0
  stxdw [r10-0x3b0], r9
  ldxdw r9, [r10-0x3f8]
  ldxdw r0, [r10-0x418]
  or64 r9, r0
  ldxdw r0, [r10-0x3f0]
  ldxdw r8, [r10-0x458]
  or64 r0, r8
  stxdw [r10-0x3f0], r0
  ldxdw r0, [r10-0x3e0]
  or64 r0, r7
  stxdw [r10-0x3e0], r0
  ldxdw r0, [r10-0x3d0]
  or64 r0, r3
  stxdw [r10-0x3d0], r0
  ldxdw r3, [r10-0x370]
  or64 r3, r6
  ldxdw r0, [r10-0x380]
  or64 r0, r5
  ldxdw r5, [r10-0x378]
  or64 r5, r1
  ldxdw r1, [r10-0x5b8]
  stxb [r2+0x0], r1
  ldxw r1, [r10-0x71]
  stxw [r10-0x91], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x98], r1
  ldxdw r1, [r10-0x80]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x88]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0xc8], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0xc0], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0xb8], r1
  ldxb r1, [r10-0x110]
  stxb [r10-0xb0], r1
  ldxh r1, [r10-0x130]
  stxh [r10-0xd0], r1
  ldxb r1, [r10-0x12e]
  stxb [r10-0xce], r1
  ldxb r1, [r10-0x138]
  stxb [r10-0xd8], r1
  ldxdw r1, [r10-0x140]
  stxdw [r10-0xe0], r1
  ldxdw r1, [r10-0x148]
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x150]
  stxdw [r10-0xf0], r1
  ldxh r1, [r10-0x158]
  stxh [r10-0xf8], r1
  ldxb r1, [r10-0x156]
  stxb [r10-0xf6], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x108], r1
  ldxb r1, [r10-0x160]
  stxb [r10-0x100], r1
  ldxdw r1, [r10-0x578]
  stxw [r10-0x334], r1
  ldxdw r1, [r10-0x4f8]
  stxw [r10-0x338], r1
  ldxw r1, [r10-0x91]
  stxw [r10-0x319], r1
  ldxdw r1, [r10-0x98]
  stxdw [r10-0x320], r1
  ldxdw r1, [r10-0xa0]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0xa8]
  stxdw [r10-0x330], r1
  ldxdw r6, [r10-0x500]
  stxw [r10-0x315], r6
  ldxb r1, [r10-0xb0]
  stxb [r10-0x2f9], r1
  ldxdw r1, [r10-0xb8]
  stxdw [r10-0x301], r1
  ldxdw r1, [r10-0xc0]
  stxdw [r10-0x309], r1
  ldxdw r1, [r10-0xc8]
  stxdw [r10-0x311], r1
  ldxb r1, [r10-0xce]
  stxb [r10-0x2f6], r1
  ldxh r1, [r10-0xd0]
  stxh [r10-0x2f8], r1
  ldxdw r1, [r10-0x570]
  stxw [r10-0x2f5], r1
  ldxb r1, [r10-0xd8]
  stxb [r10-0x2d9], r1
  ldxdw r1, [r10-0xe0]
  stxdw [r10-0x2e1], r1
  ldxdw r1, [r10-0xe8]
  stxdw [r10-0x2e9], r1
  ldxdw r1, [r10-0xf0]
  stxdw [r10-0x2f1], r1
  ldxdw r1, [r10-0x3d8]
  stxdw [r10-0x250], r1
  ldxdw r1, [r10-0x358]
  stxdw [r10-0x258], r1
  ldxdw r1, [r10-0x3c8]
  stxdw [r10-0x260], r1
  ldxdw r1, [r10-0x360]
  stxdw [r10-0x268], r1
  ldxdw r1, [r10-0x3b8]
  stxdw [r10-0x270], r1
  ldxdw r1, [r10-0x3e8]
  stxdw [r10-0x278], r1
  ldxdw r1, [r10-0x3a8]
  stxdw [r10-0x280], r1
  ldxdw r1, [r10-0x350]
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x3a0]
  stxdw [r10-0x290], r1
  ldxdw r1, [r10-0x348]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x398]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x3c0]
  stxdw [r10-0x2a8], r1
  ldxdw r1, [r10-0x390]
  stxdw [r10-0x2b0], r1
  ldxdw r1, [r10-0x3b0]
  stxdw [r10-0x2b8], r1
  ldxdw r1, [r10-0x388]
  stxdw [r10-0x2c0], r1
  mov64 r1, r9
  stxdw [r10-0x3f8], r1
  stxdw [r10-0x2c8], r1
  ldxdw r1, [r10-0x368]
  stxdw [r10-0x2d0], r1
  ldxdw r1, [r10-0x340]
  stxdw [r10-0x2d8], r1
  ldxdw r1, [r10-0x568]
  stxw [r10-0x245], r1
  ldxdw r1, [r10-0x4f0]
  stxdw [r10-0x208], r1
  ldxdw r1, [r10-0x4e8]
  stxdw [r10-0x200], r1
  ldxdw r1, [r10-0x4e0]
  stxdw [r10-0x1f8], r1
  ldxdw r1, [r10-0x4d8]
  stxdw [r10-0x1f0], r1
  ldxdw r1, [r10-0x4d0]
  stxdw [r10-0x1e8], r1
  ldxdw r1, [r10-0x4c8]
  stxdw [r10-0x1e0], r1
  ldxdw r1, [r10-0x4c0]
  stxdw [r10-0x1d8], r1
  ldxdw r1, [r10-0x510]
  stxdw [r10-0x1d0], r1
  ldxdw r9, [r10-0x598]
  stxdw [r10-0x1c8], r9
  ldxdw r1, [r10-0x560]
  stxdw [r10-0x1c0], r1
  ldxdw r1, [r10-0x558]
  stxdw [r10-0x1b8], r1
  ldxdw r1, [r10-0x550]
  stxdw [r10-0x1b0], r1
  ldxdw r1, [r10-0x548]
  stxdw [r10-0x1a8], r1
  ldxdw r1, [r10-0x540]
  stxdw [r10-0x1a0], r1
  ldxdw r1, [r10-0x538]
  stxdw [r10-0x198], r1
  ldxdw r1, [r10-0x530]
  stxdw [r10-0x190], r1
  ldxdw r1, [r10-0x528]
  stxdw [r10-0x188], r1
  ldxdw r1, [r10-0x520]
  stxdw [r10-0x180], r1
  ldxdw r1, [r10-0x518]
  stxdw [r10-0x178], r1
  ldxdw r1, [r10-0x3f0]
  stxdw [r10-0x210], r1
  mov64 r1, r3
  stxdw [r10-0x370], r1
  stxdw [r10-0x218], r1
  ldxdw r1, [r10-0x3e0]
  stxdw [r10-0x220], r1
  mov64 r1, r0
  stxdw [r10-0x380], r1
  stxdw [r10-0x228], r1
  ldxdw r1, [r10-0x3d0]
  stxdw [r10-0x230], r1
  mov64 r1, r5
  stxdw [r10-0x378], r1
  stxdw [r10-0x238], r1
  ldxdw r7, [r10-0x588]
  stxb [r10-0x16f], r7
  ldxdw r8, [r10-0x590]
  stxb [r10-0x170], r8
  ldxb r1, [r10-0xf6]
  stxb [r10-0x246], r1
  ldxh r1, [r10-0xf8]
  stxh [r10-0x248], r1
  ldxdw r1, [r10-0x108]
  stxdw [r10-0x241], r1
  ldxb r1, [r10-0x100]
  stxb [r10-0x239], r1
  ldxh r1, [r10-0x10a]
  stxh [r10-0x16a], r1
  ldxw r1, [r10-0x10e]
  stxw [r10-0x16e], r1
  mov64 r1, r10
  add64 r1, -0x338
  stxdw [r10-0x78], r1
  lddw r1, str_0367
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x20
  stdw [r10-0x80], 0x6
  mov64 r3, r10
  add64 r3, -0x88
  mov64 r1, r2
  mov64 r2, r3
  mov64 r3, 0x2
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_5990
  ldxdw r1, [r10-0x580]
  ldxdw r2, [r10-0x578]
  stxw [r1+0x4], r2
  ldxdw r2, [r10-0x4f8]
  stxw [r1+0x0], r2
  ldxdw r2, [r10-0xa8]
  stxdw [r1+0x8], r2
  ldxdw r2, [r10-0xa0]
  stxdw [r1+0x10], r2
  ldxdw r2, [r10-0x98]
  stxdw [r1+0x18], r2
  ldxw r2, [r10-0x91]
  stxw [r1+0x1f], r2
  stxw [r1+0x23], r6
  ldxdw r2, [r10-0xc8]
  stxdw [r1+0x27], r2
  ldxdw r2, [r10-0xc0]
  stxdw [r1+0x2f], r2
  ldxdw r2, [r10-0xb8]
  stxdw [r1+0x37], r2
  ldxb r2, [r10-0xb0]
  stxb [r1+0x3f], r2
  ldxb r2, [r10-0xce]
  stxb [r1+0x42], r2
  ldxh r2, [r10-0xd0]
  stxh [r1+0x40], r2
  ldxdw r2, [r10-0x570]
  stxw [r1+0x43], r2
  ldxdw r2, [r10-0xf0]
  stxdw [r1+0x47], r2
  ldxdw r2, [r10-0xe8]
  stxdw [r1+0x4f], r2
  ldxdw r2, [r10-0xe0]
  stxdw [r1+0x57], r2
  ldxb r2, [r10-0xd8]
  stxb [r1+0x5f], r2
  ldxdw r2, [r10-0x3d8]
  stxdw [r1+0xe8], r2
  ldxdw r2, [r10-0x358]
  stxdw [r1+0xe0], r2
  ldxdw r2, [r10-0x3c8]
  stxdw [r1+0xd8], r2
  ldxdw r2, [r10-0x360]
  stxdw [r1+0xd0], r2
  ldxdw r2, [r10-0x3b8]
  stxdw [r1+0xc8], r2
  ldxdw r2, [r10-0x3e8]
  stxdw [r1+0xc0], r2
  ldxdw r2, [r10-0x3a8]
  stxdw [r1+0xb8], r2
  ldxdw r2, [r10-0x350]
  stxdw [r1+0xb0], r2
  ldxdw r2, [r10-0x3a0]
  stxdw [r1+0xa8], r2
  ldxdw r2, [r10-0x348]
  stxdw [r1+0xa0], r2
  ldxdw r2, [r10-0x398]
  stxdw [r1+0x98], r2
  ldxdw r2, [r10-0x3c0]
  stxdw [r1+0x90], r2
  ldxdw r2, [r10-0x390]
  stxdw [r1+0x88], r2
  ldxdw r2, [r10-0x3b0]
  stxdw [r1+0x80], r2
  ldxdw r2, [r10-0x388]
  stxdw [r1+0x78], r2
  ldxdw r2, [r10-0x3f8]
  stxdw [r1+0x70], r2
  ldxdw r2, [r10-0x368]
  stxdw [r1+0x68], r2
  ldxdw r2, [r10-0x340]
  stxdw [r1+0x60], r2
  ldxh r2, [r10-0xf8]
  stxh [r1+0xf0], r2
  ldxb r2, [r10-0xf6]
  stxb [r1+0xf2], r2
  ldxdw r2, [r10-0x568]
  stxw [r1+0xf3], r2
  ldxdw r2, [r10-0x108]
  stxdw [r1+0xf7], r2
  ldxb r2, [r10-0x100]
  stxb [r1+0xff], r2
  ldxdw r2, [r10-0x4f0]
  stxdw [r1+0x130], r2
  ldxdw r2, [r10-0x4e8]
  stxdw [r1+0x138], r2
  ldxdw r2, [r10-0x4e0]
  stxdw [r1+0x140], r2
  ldxdw r2, [r10-0x4d8]
  stxdw [r1+0x148], r2
  ldxdw r2, [r10-0x4d0]
  stxdw [r1+0x150], r2
  ldxdw r2, [r10-0x4c8]
  stxdw [r1+0x158], r2
  ldxdw r2, [r10-0x4c0]
  stxdw [r1+0x160], r2
  ldxdw r2, [r10-0x510]
  stxdw [r1+0x168], r2
  stxdw [r1+0x170], r9
  ldxdw r2, [r10-0x560]
  stxdw [r1+0x178], r2
  ldxdw r2, [r10-0x558]
  stxdw [r1+0x180], r2
  ldxdw r2, [r10-0x550]
  stxdw [r1+0x188], r2
  ldxdw r2, [r10-0x548]
  stxdw [r1+0x190], r2
  ldxdw r2, [r10-0x540]
  stxdw [r1+0x198], r2
  ldxdw r2, [r10-0x538]
  stxdw [r1+0x1a0], r2
  ldxdw r2, [r10-0x530]
  stxdw [r1+0x1a8], r2
  ldxdw r2, [r10-0x528]
  stxdw [r1+0x1b0], r2
  ldxdw r2, [r10-0x520]
  stxdw [r1+0x1b8], r2
  ldxdw r2, [r10-0x518]
  stxdw [r1+0x1c0], r2
  ldxdw r2, [r10-0x3f0]
  stxdw [r1+0x128], r2
  ldxdw r2, [r10-0x370]
  stxdw [r1+0x120], r2
  ldxdw r2, [r10-0x3e0]
  stxdw [r1+0x118], r2
  ldxdw r2, [r10-0x380]
  stxdw [r1+0x110], r2
  ldxdw r2, [r10-0x3d0]
  stxdw [r1+0x108], r2
  ldxdw r2, [r10-0x378]
  stxdw [r1+0x100], r2
  stxb [r1+0x1c9], r7
  stxb [r1+0x1c8], r8
  ldxh r2, [r10-0x10a]
  stxh [r1+0x1ce], r2
  ldxw r2, [r10-0x10e]
  stxw [r1+0x1ca], r2
  ja jmp_5988

jmp_5940:
  ldxb r4, [r2+0x0]
  add64 r4, 0x1
  mov64 r0, r4
  and64 r0, 0xff
  jne r0, r4, jmp_59b8
  stxb [r2+0x0], r4

jmp_5970:
  stxw [r1+0x4], r5
  stxw [r1+0x0], r3

jmp_5980:
  stb [r1+0x1c9], 0x2

jmp_5988:
  exit

jmp_5990:
  ldxdw r1, [r10-0x580]
  stxw [r1+0x0], r0
  rsh64 r0, 0x20
  stxw [r1+0x4], r0
  ja jmp_5980

jmp_59b8:
  lddw r1, data_0678
  call fn_2bcf8

fn_59d0:
  mov64 r3, r1
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_5a60
  ldxdw r5, [r3+0x20]
  ldxdw r6, [r3+0x18]
  ldxdw r4, [r3+0x10]
  ldxdw r3, [r3+0x8]
  ldxdw r7, [r2+0x0]
  jne r3, r7, jmp_5a68
  ldxdw r7, [r2+0x8]
  jne r4, r7, jmp_5a68
  ldxdw r7, [r2+0x10]
  jne r6, r7, jmp_5a68
  ldxdw r7, [r2+0x18]
  jne r5, r7, jmp_5a68
  mov64 r0, 0x1a

jmp_5a60:
  exit

jmp_5a68:
  ldxdw r7, [r2+0x20]
  jne r3, r7, jmp_5a60
  ldxdw r7, [r2+0x28]
  jne r4, r7, jmp_5a60
  ldxdw r7, [r2+0x30]
  jne r6, r7, jmp_5a60
  ldxdw r7, [r2+0x38]
  jne r5, r7, jmp_5a60
  or64 r4, r3
  or64 r4, r6
  or64 r4, r5
  jeq r4, 0x0, jmp_5a60
  mov64 r6, r2
  mov64 r2, r10
  add64 r2, -0x28
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_5b38
  mov64 r0, 0x10
  jne r1, 0x1, jmp_5a60
  mov64 r0, 0x1
  ja jmp_5a60

jmp_5b38:
  ldxdw r1, [r10-0x8]
  ldxdw r2, [r6+0x148]
  mov64 r0, 0x1a
  jslt r1, r2, jmp_5b60
  mov64 r0, 0x0

jmp_5b60:
  mov64 r1, 0x11
  ja jmp_5a60

fn_5b70:
  mov64 r0, 0x0
  ldxdw r3, [r2+0x0]
  ldxdw r4, [r1+0x8]
  jne r4, r3, jmp_5bf0
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r1+0x10]
  jne r4, r3, jmp_5bf0
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r1+0x18]
  jne r4, r3, jmp_5bf0
  ldxdw r2, [r2+0x18]
  ldxdw r3, [r1+0x20]
  jne r3, r2, jmp_5bf0
  ldxb r1, [r1+0x3]
  jeq r1, 0x0, jmp_5bf0
  mov64 r0, 0x1a

jmp_5bf0:
  exit

fn_5bf8:
  mov64 r6, r1
  mov64 r0, 0x0
  ldxb r1, [r2+0x1]
  jeq r1, 0x0, jmp_5ec0
  mov64 r1, 0x2
  ldxb r7, [r6+0x2]
  jeq r7, 0x0, jmp_5ec8
  ldxb r7, [r2+0x2]
  jeq r7, 0x0, jmp_5ec8
  mov64 r1, 0x12
  ldxdw r7, [r6+0x50]
  jne r7, 0x0, jmp_5ec8
  ldxdw r7, [r6+0x28]
  jne r7, 0x0, jmp_5ec8
  ldxdw r7, [r6+0x30]
  jne r7, 0x0, jmp_5ec8
  ldxdw r7, [r6+0x38]
  jne r7, 0x0, jmp_5ec8
  ldxdw r7, [r6+0x40]
  jne r7, 0x0, jmp_5ec8
  mov64 r8, r2
  ldxdw r9, [r5-0xff0]
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0x168], r1
  ldxdw r5, [r5-0x1000]
  stxdw [r10-0x160], r6
  mov64 r1, r6
  mov64 r7, r3
  mov64 r2, r3
  mov64 r6, r4
  mov64 r3, r4
  mov64 r4, r5
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_5ec8
  stxb [r10-0x151], r1
  stdw [r10-0x108], 0x0
  stdw [r10-0x110], 0x1
  stdw [r10-0x118], 0x0
  stdw [r10-0x120], 0x1
  stdw [r10-0x128], 0x0
  stdw [r10-0x130], 0x1
  stdw [r10-0x138], 0x0
  stdw [r10-0x140], 0x1
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r7+0x8]
  stxdw [r10-0x148], r2
  stxdw [r10-0x150], r1
  jeq r6, 0x1, jmp_5de8
  ldxdw r1, [r7+0x10]
  ldxdw r2, [r7+0x18]
  stxdw [r10-0x138], r2
  stxdw [r10-0x140], r1
  jeq r6, 0x2, jmp_5de8
  ldxdw r1, [r7+0x20]
  ldxdw r2, [r7+0x28]
  stxdw [r10-0x128], r2
  stxdw [r10-0x130], r1

jmp_5de8:
  mov64 r1, r6
  lsh64 r1, 0x4
  mov64 r2, r10
  add64 r2, -0x150
  mov64 r3, r2
  add64 r3, r1
  mov64 r1, r10
  add64 r1, -0x151
  stxdw [r3+0x0], r1
  stdw [r3+0x8], 0x1
  add64 r6, 0x1
  stxdw [r10-0xf8], r6
  stxdw [r10-0x100], r2
  mov64 r2, r10
  add64 r2, -0x98
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_5ed0
  mov64 r0, 0x10
  jne r1, 0x1, jmp_64a8

jmp_5ea8:
  mov64 r0, 0x1
  mov64 r1, 0x0
  ja jmp_5ec8

jmp_5ec0:
  mov64 r1, 0x3

jmp_5ec8:
  exit

jmp_5ed0:
  ldxdw r2, [r10-0x98]
  lddw r1, 0x1999851ec8b
  jgt r2, r1, jmp_5ea8
  ldxdw r3, [r10-0x160]
  mov64 r7, r3
  add64 r7, 0x28
  mov64 r1, r9
  add64 r1, 0x80
  mul64 r2, r1
  mov64 r0, r3
  add64 r0, 0x48
  ldxdw r1, [r3+0x48]
  jeq r1, 0x0, jmp_63e0
  mov64 r6, r3
  add64 r6, 0x8
  jle r2, r1, jmp_6140
  sub64 r2, r1
  stxdw [r10-0x18], r6
  mov64 r1, r8
  add64 r1, 0x8
  stxdw [r10-0x28], r1
  sth [r10-0x10], 0x1
  sth [r10-0x20], 0x101
  stxdw [r10-0xec], r2
  stw [r10-0xf0], 0x2
  ldxb r2, [r8+0x0]
  ldxb r4, [r3+0x0]
  and64 r4, r2
  jne r4, 0xff, jmp_64a0
  stxdw [r10-0x98], r1
  mov64 r1, r8
  add64 r1, 0x48
  stxdw [r10-0x90], r1
  ldxdw r1, [r8+0x50]
  mov64 r2, r8
  add64 r2, 0x28
  stxdw [r10-0x78], r2
  mov64 r2, r8
  add64 r2, 0x58
  stxdw [r10-0x80], r2
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x0
  ldxw r1, [r8+0x1]
  stxdw [r10-0x58], r0
  stxdw [r10-0x60], r6
  stxw [r10-0x68], r1
  ldxdw r1, [r3+0x50]
  stxdw [r10-0x40], r7
  mov64 r2, r3
  add64 r2, 0x58
  stxdw [r10-0x48], r2
  stxdw [r10-0x50], r1
  stdw [r10-0x38], 0x0
  ldxw r1, [r3+0x1]
  stxw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xc8], r1
  lddw r1, data_0301
  stxdw [r10-0xd0], r1
  stdw [r10-0xb0], 0xc
  stdw [r10-0xc0], 0x2
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  mov64 r8, r0
  call sol_invoke_signed_c
  mov64 r0, r8
  ldxdw r3, [r10-0x160]

jmp_6140:
  stxdw [r10-0x28], r6
  sth [r10-0x20], 0x101
  stxdw [r10-0xec], r9
  stw [r10-0xf0], 0x8
  ldxb r1, [r3+0x0]
  jne r1, 0xff, jmp_64a0
  stxdw [r10-0x170], r0
  stxdw [r10-0x90], r0
  stxdw [r10-0x98], r6
  ldxdw r1, [r3+0x50]
  mov64 r9, r7
  stxdw [r10-0x78], r7
  stxdw [r10-0x88], r1
  mov64 r8, r3
  add64 r8, 0x58
  stxdw [r10-0x80], r8
  stdw [r10-0x70], 0x0
  ldxw r1, [r3+0x1]
  stxw [r10-0x68], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xc8], r1
  lddw r1, data_0301
  stxdw [r10-0xd0], r1
  stdw [r10-0xb0], 0xc
  stdw [r10-0xc0], 0x1
  mov64 r1, r10
  add64 r1, -0xd0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r4, r10
  add64 r4, -0x100
  mov64 r7, r3
  mov64 r3, 0x1
  mov64 r5, 0x1
  call sol_invoke_signed_c
  stxdw [r10-0xf0], r6
  sth [r10-0xe8], 0x101
  stw [r10-0x28], 0x1
  ldxdw r2, [r10-0x168]
  ldxdw r1, [r2+0x18]
  stxdw [r10-0xc], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x14], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x1c], r1
  ldxdw r1, [r2+0x0]
  stxdw [r10-0x24], r1
  ldxb r1, [r7+0x0]
  jne r1, 0xff, jmp_64a0
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x90], r1
  stxdw [r10-0x98], r6
  ldxdw r1, [r10-0x160]
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x78], r9
  stxdw [r10-0x80], r8
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
  lddw r1, data_0301
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
  ja jmp_6618

jmp_63e0:
  mov64 r1, r3
  add64 r1, 0x8
  stxdw [r10-0xe0], r1
  mov64 r4, r8
  add64 r4, 0x8
  stxdw [r10-0xf0], r4
  sth [r10-0xd8], 0x101
  sth [r10-0xe8], 0x101
  stxdw [r10-0xc4], r9
  stxdw [r10-0xcc], r2
  stw [r10-0xd0], 0x0
  ldxdw r5, [r10-0x168]
  ldxdw r2, [r5+0x18]
  stxdw [r10-0xa4], r2
  ldxdw r2, [r5+0x10]
  stxdw [r10-0xac], r2
  ldxdw r2, [r5+0x8]
  stxdw [r10-0xb4], r2
  ldxdw r2, [r5+0x0]
  stxdw [r10-0xbc], r2
  ldxb r2, [r8+0x0]
  ldxb r5, [r3+0x0]
  and64 r5, r2
  jeq r5, 0xff, jmp_64b8

jmp_64a0:
  mov64 r0, 0xb

jmp_64a8:
  mov64 r1, 0x0
  ja jmp_5ec8

jmp_64b8:
  stxdw [r10-0x98], r4
  mov64 r2, r8
  add64 r2, 0x48
  stxdw [r10-0x90], r2
  ldxdw r2, [r8+0x50]
  mov64 r4, r8
  add64 r4, 0x28
  stxdw [r10-0x78], r4
  mov64 r4, r8
  add64 r4, 0x58
  stxdw [r10-0x80], r4
  stxdw [r10-0x88], r2
  stdw [r10-0x70], 0x0
  ldxw r2, [r8+0x1]
  stxdw [r10-0x58], r0
  stxdw [r10-0x60], r1
  stxw [r10-0x68], r2
  ldxdw r1, [r3+0x50]
  stxdw [r10-0x40], r7
  mov64 r2, r3
  add64 r2, 0x58
  stxdw [r10-0x48], r2
  stxdw [r10-0x50], r1
  stdw [r10-0x38], 0x0
  ldxw r1, [r3+0x1]
  stxw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0xd0
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xf0
  stxdw [r10-0x20], r1
  lddw r1, data_0301
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

jmp_6618:
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_5ec8

fn_6638:
  mov64 r7, r1
  mov64 r6, 0x3
  ldxb r1, [r2+0x1]
  jeq r1, 0x0, jmp_68a0
  mov64 r8, r2
  stxdw [r10-0x10], r3
  stdw [r10-0x8], 0x20
  mov64 r2, r10
  add64 r2, -0x10
  mov64 r1, r7
  mov64 r3, 0x1
  lddw r4, data_0281
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_6770
  ldxdw r1, [r7+0x28]
  lddw r2, -0x4f5e77b16e0957fe
  jne r1, r2, jmp_68a0
  ldxdw r1, [r7+0x30]
  lddw r2, 0x2bae63f73e1510e2
  jne r1, r2, jmp_68a0
  ldxdw r1, [r7+0x38]
  lddw r2, -0x2ddb3ee9c2463e00
  jne r1, r2, jmp_68a0
  ldxdw r1, [r7+0x40]
  lddw r2, 0x8004107a53c0
  jne r1, r2, jmp_68a0
  ldxb r1, [r7+0x0]
  jge r1, 0x2, jmp_6788
  mov64 r0, 0xb
  mov64 r6, 0x0
  ja jmp_68a8

jmp_6770:
  mov64 r6, r0
  rsh64 r6, 0x20
  ja jmp_68a8

jmp_6788:
  add64 r1, -0x1
  stxb [r7+0x0], r1
  ldxdw r2, [r7+0x50]
  jlt r2, 0x2d, jmp_6870
  ldxw r2, [r7+0x58]
  jne r2, 0x3, jmp_6870
  ldxb r2, [r7+0x64]
  jne r2, 0x1, jmp_6870
  ldxdw r2, [r8+0x8]
  ldxdw r3, [r7+0x65]
  jne r3, r2, jmp_6830
  ldxdw r2, [r8+0x10]
  ldxdw r3, [r7+0x6d]
  jne r3, r2, jmp_6830
  ldxdw r2, [r8+0x18]
  ldxdw r3, [r7+0x75]
  jne r3, r2, jmp_6830
  ldxdw r2, [r8+0x20]
  mov64 r0, 0x1a
  ldxdw r3, [r7+0x7d]
  jeq r3, r2, jmp_6838

jmp_6830:
  mov64 r0, 0x0

jmp_6838:
  and64 r1, 0xff
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_68b8
  stxb [r7+0x0], r1
  ja jmp_68a8

jmp_6870:
  and64 r1, 0xff
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_68b8
  stxb [r7+0x0], r1

jmp_68a0:
  mov64 r0, 0x0

jmp_68a8:
  mov64 r1, r6
  exit

jmp_68b8:
  lddw r1, data_0678
  call fn_2bcf8

fn_68d0:
  mov64 r8, r3
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r7
  lddw r2, data_0760
  mov64 r3, 0x1
  mov64 r4, r8
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_69d0
  mov64 r9, 0x0
  mov64 r0, 0x2
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r7+0x28]
  jne r2, r1, jmp_6b80
  ldxdw r1, [r8+0x8]
  ldxdw r2, [r7+0x30]
  jne r2, r1, jmp_6b80
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r7+0x38]
  jne r2, r1, jmp_6b80
  ldxdw r1, [r8+0x18]
  ldxdw r2, [r7+0x40]
  jne r2, r1, jmp_6b80
  ldxb r8, [r7+0x0]
  jgt r8, 0x1, jmp_69e0
  mov64 r9, 0xb
  mov64 r0, 0x0
  ja jmp_6b80

jmp_69d0:
  stxdw [r6+0x4], r0
  ja jmp_6b90

jmp_69e0:
  add64 r8, -0x1
  stxb [r7+0x0], r8
  ldxdw r3, [r7+0x50]
  mov64 r2, r7
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0xb8
  call fn_2b208
  ldxw r1, [r10-0xb8]
  jne r1, 0x1, jmp_6a70
  and64 r8, 0xff
  add64 r8, 0x1
  mov64 r1, r8
  and64 r1, 0xff
  jne r1, r8, jmp_6be8
  ldxw r0, [r10-0xb4]
  stxb [r7+0x0], r8
  ja jmp_6b80

jmp_6a70:
  ldxw r9, [r10-0xb0]
  mov64 r1, r10
  add64 r1, -0x210
  mov64 r2, r10
  add64 r2, -0xac
  mov64 r3, 0xac
  call fn_2c060
  and64 r8, 0xff
  add64 r8, 0x1
  mov64 r1, r8
  and64 r1, 0xff
  jne r1, r8, jmp_6be8
  stxb [r7+0x0], r8
  mov64 r7, r10
  add64 r7, -0x164
  mov64 r2, r10
  add64 r2, -0x210
  mov64 r1, r7
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x2c0], r9
  mov64 r1, r10
  add64 r1, -0x2bc
  mov64 r2, r7
  mov64 r3, 0xac
  call fn_2c060
  mov64 r1, r10
  add64 r1, -0x2c0
  call fn_2a1d0
  mov64 r1, r9
  mov64 r9, 0x0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jeq r0, 0x0, jmp_6ba0

jmp_6b80:
  stxw [r6+0x8], r0
  stxw [r6+0x4], r9

jmp_6b90:
  stw [r6+0x0], 0x1

jmp_6b98:
  exit

jmp_6ba0:
  stxw [r6+0x8], r1
  mov64 r1, r6
  add64 r1, 0xc
  mov64 r2, r10
  add64 r2, -0x164
  mov64 r3, 0xac
  call fn_2c060
  stw [r6+0x0], 0x0
  ja jmp_6b98

jmp_6be8:
  lddw r1, data_0678
  call fn_2bcf8

fn_6c00:
  stxdw [r10-0xe8], r2
  mov64 r2, r1
  mov64 r0, 0x0
  mov64 r1, 0x2
  ldxdw r6, [r5-0xff0]
  ldxdw r8, [r5-0x1000]
  ldxdw r9, [r6+0xc0]
  ldxdw r7, [r8+0x8]
  jne r7, r9, jmp_6f78
  ldxdw r7, [r6+0xc8]
  ldxdw r9, [r8+0x10]
  jne r9, r7, jmp_6f78
  ldxdw r7, [r6+0xd0]
  ldxdw r9, [r8+0x18]
  jne r9, r7, jmp_6f78
  ldxdw r6, [r6+0xd8]
  ldxdw r7, [r8+0x20]
  jne r7, r6, jmp_6f78
  mov64 r9, r4
  ldxdw r6, [r5-0xff8]
  stxdw [r10-0xb0], r3
  lddw r1, str_0371
  stxdw [r10-0xc0], r1
  stdw [r10-0xa8], 0x20
  stdw [r10-0xb8], 0x7
  lddw r1, data_02c1
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r2
  stdw [r10-0xff0], 0xa5
  mov64 r3, r10
  add64 r3, -0xc0
  mov64 r5, r10
  mov64 r1, r6
  ldxdw r2, [r10-0xe8]
  mov64 r4, 0x2
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_6f78
  mov64 r1, r8
  add64 r1, 0x8
  stxdw [r10-0xd0], r1
  mov64 r2, r6
  add64 r2, 0x8
  stxdw [r10-0xe0], r2
  sth [r10-0xc8], 0x0
  sth [r10-0xd8], 0x1
  ldxb r3, [r6+0x0]
  jne r3, 0xff, jmp_6f80
  stxdw [r10-0xc0], r2
  mov64 r2, r6
  add64 r2, 0x48
  stxdw [r10-0xb8], r2
  ldxdw r2, [r6+0x50]
  mov64 r3, r6
  add64 r3, 0x28
  stxdw [r10-0xa0], r3
  mov64 r3, r6
  add64 r3, 0x58
  stxdw [r10-0xa8], r3
  stxdw [r10-0xb0], r2
  stdw [r10-0x98], 0x0
  ldxw r2, [r6+0x1]
  mov64 r3, r8
  add64 r3, 0x48
  stxdw [r10-0x80], r3
  stxdw [r10-0x88], r1
  stxw [r10-0x90], r2
  ldxdw r1, [r8+0x50]
  mov64 r2, r8
  add64 r2, 0x28
  stxdw [r10-0x68], r2
  mov64 r2, r8
  add64 r2, 0x58
  stxdw [r10-0x70], r2
  stxdw [r10-0x78], r1
  stdw [r10-0x60], 0x0
  ldxw r1, [r8+0x1]
  stxw [r10-0x58], r1
  stb [r10-0x49], 0x12
  ldxdw r1, [r9+0x8]
  stxdw [r10-0x48], r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0x40], r1
  ldxdw r1, [r9+0x18]
  stxdw [r10-0x38], r1
  ldxdw r1, [r9+0x20]
  stxdw [r10-0x30], r1
  mov64 r1, r10
  add64 r1, -0x49
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xe0
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x21
  stdw [r10-0x18], 0x2
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0xc0
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  mov64 r0, 0x1a

jmp_6f78:
  exit

jmp_6f80:
  mov64 r0, 0xb
  mov64 r1, 0x2
  ja jmp_6f78

fn_6f98:
  mov64 r6, r3
  mov64 r7, r2
  mov64 r9, r1
  jlt r6, 0x8, jmp_7d18
  stxdw [r10-0x740], r4
  ldxdw r8, [r7+0x8]
  mov64 r1, r10
  add64 r1, -0x380
  mov64 r2, r8
  mov64 r3, r9
  call fn_3820
  ldxb r1, [r10-0x22e]
  jne r1, 0x2, jmp_7018
  ldxw r0, [r10-0x380]
  ldxw r1, [r10-0x37c]
  ja jmp_7d28

jmp_7018:
  ldxdw r1, [r10-0x288]
  stxdw [r10-0x760], r1
  ldxdw r1, [r10-0x290]
  stxdw [r10-0x758], r1
  ldxdw r1, [r10-0x298]
  stxdw [r10-0x750], r1
  ldxdw r1, [r10-0x2a0]
  stxdw [r10-0x748], r1
  ldxdw r1, [r10-0x2a8]
  stxdw [r10-0x780], r1
  ldxdw r1, [r10-0x2b0]
  stxdw [r10-0x778], r1
  ldxdw r1, [r10-0x2b8]
  stxdw [r10-0x770], r1
  ldxdw r1, [r10-0x2c0]
  stxdw [r10-0x768], r1
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x380
  mov64 r3, r9
  call fn_68d0
  ldxw r1, [r10-0x380]
  jne r1, 0x1, jmp_70e8
  ldxw r1, [r10-0x378]
  ldxw r0, [r10-0x37c]
  ja jmp_7d28

jmp_70e8:
  stxdw [r10-0x788], r8
  ldxw r8, [r10-0x378]
  mov64 r1, r10
  add64 r1, -0x734
  mov64 r2, r10
  add64 r2, -0x374
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x738], r8
  ldxdw r2, [r7+0x18]
  mov64 r1, r10
  add64 r1, -0x380
  mov64 r3, r9
  call fn_3a90
  ldxw r1, [r10-0x37c]
  ldxw r0, [r10-0x380]
  ldxb r8, [r10-0x1b7]
  jeq r8, 0x2, jmp_7d28
  stxdw [r10-0x798], r9
  stxdw [r10-0x790], r7
  mov64 r3, r10
  add64 r3, -0x680
  mov64 r2, r10
  add64 r2, -0x378
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x1b6]
  stxw [r10-0x4be], r1
  ldxh r1, [r10-0x1b2]
  stxh [r10-0x4ba], r1
  stxw [r10-0x684], r9
  stxw [r10-0x688], r7
  mov64 r0, 0x0
  mov64 r1, 0x18
  stxb [r10-0x4bf], r8
  and64 r8, 0x1
  jne r8, 0x0, jmp_7d28
  ldxdw r1, [r10-0x740]
  ldxdw r8, [r1+0x0]
  jeq r6, 0x9, jmp_72f0
  ldxdw r7, [r10-0x790]
  ldxdw r4, [r10-0x798]
  jne r6, 0x8, jmp_7d20
  mov64 r6, 0x0
  jeq r8, 0x3, jmp_7318
  mov64 r1, 0x3
  ldxdw r2, [r7+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_7d28
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x688]
  jne r3, r4, jmp_7d28
  ldxdw r3, [r10-0x680]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_7d28
  ldxdw r3, [r10-0x678]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_7d28
  ldxdw r3, [r10-0x670]
  ldxdw r2, [r2+0x20]
  jeq r2, r3, jmp_7408
  ja jmp_7d28

jmp_72f0:
  ldxdw r7, [r10-0x790]
  ldxdw r4, [r10-0x798]
  jne r8, 0x3, jmp_7d20
  mov64 r6, r7
  add64 r6, 0x40

jmp_7318:
  ldxdw r1, [r7+0x0]
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x688]
  jne r2, r3, jmp_7d20
  ldxdw r2, [r10-0x680]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_7d20
  ldxdw r2, [r10-0x678]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_7d20
  ldxdw r2, [r10-0x670]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_7d20
  mov64 r1, r10
  add64 r1, -0x688
  stxdw [r10-0x370], r1
  lddw r1, str_0371
  stxdw [r10-0x380], r1
  stdw [r10-0x368], 0x20
  stdw [r10-0x378], 0x7
  ldxdw r1, [r7+0x20]
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r3, 0x2
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_78c8

jmp_7408:
  ldxdw r1, [r7+0x38]
  lddw r2, data_02c1
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_7d20
  ldxdw r3, [r7+0x28]
  ldxdw r1, [r3+0x8]
  ldxdw r2, [r10-0x748]
  jne r1, r2, jmp_78e0
  ldxdw r1, [r3+0x10]
  ldxdw r2, [r10-0x750]
  jne r1, r2, jmp_78e0
  ldxdw r1, [r3+0x18]
  ldxdw r2, [r10-0x758]
  jne r1, r2, jmp_78e0
  ldxdw r1, [r3+0x20]
  ldxdw r2, [r10-0x760]
  jne r1, r2, jmp_78e0
  ldxdw r9, [r7+0x30]
  ldxdw r1, [r9+0x8]
  ldxdw r2, [r10-0x768]
  jne r1, r2, jmp_78e0
  ldxdw r1, [r9+0x10]
  ldxdw r2, [r10-0x770]
  jne r1, r2, jmp_78e0
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r10-0x778]
  jne r1, r2, jmp_78e0
  ldxdw r2, [r9+0x20]
  mov64 r1, 0x2
  mov64 r0, 0x0
  ldxdw r4, [r10-0x780]
  jne r2, r4, jmp_7d28
  stxdw [r10-0x750], r3
  ldxdw r2, [r7+0x20]
  mov64 r1, r10
  add64 r1, -0x380
  stxdw [r10-0x748], r2
  call fn_0118
  ldxdw r4, [r10-0x380]
  jeq r4, 0x0, jmp_7d30
  mov64 r0, 0x0
  mov64 r1, 0x1
  jeq r8, 0x3, jmp_7580
  mov64 r1, 0x0

jmp_7580:
  lsh64 r1, 0x3
  mov64 r2, r7
  add64 r2, r1
  mov64 r1, 0x2
  ldxdw r5, [r10-0x378]
  ldxdw r2, [r2+0x0]
  ldxdw r3, [r2+0x8]
  mov64 r7, r4
  ldxdw r4, [r7+0x20]
  jne r4, r3, jmp_79c8
  ldxdw r3, [r2+0x10]
  ldxdw r4, [r7+0x28]
  jne r4, r3, jmp_79c8
  stxdw [r10-0x758], r8
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r7+0x30]
  jne r4, r3, jmp_79c8
  stxdw [r10-0x760], r5
  ldxdw r1, [r2+0x20]
  mov64 r8, r7
  ldxdw r2, [r7+0x38]
  jne r2, r1, jmp_79b8
  mov64 r1, r9
  add64 r1, 0x8
  stxdw [r10-0x768], r1
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r8+0x0]
  jne r2, r1, jmp_79b8
  ldxdw r1, [r9+0x10]
  ldxdw r2, [r8+0x8]
  jne r2, r1, jmp_79b8
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r8+0x10]
  jne r2, r1, jmp_79b8
  ldxdw r1, [r9+0x20]
  ldxdw r2, [r8+0x18]
  jne r2, r1, jmp_79b8
  jeq r6, 0x0, jmp_78f8
  ldxdw r1, [r10-0x768]
  stxdw [r10-0x360], r1
  lddw r1, data_02c1
  stxdw [r10-0x370], r1
  ldxdw r7, [r10-0x748]
  add64 r7, 0x8
  stxdw [r10-0x380], r7
  stdw [r10-0x358], 0x20
  stdw [r10-0x368], 0x20
  stdw [r10-0x378], 0x20
  ldxdw r1, [r6+0x0]
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r3, 0x3
  lddw r4, data_02a1
  call fn_05d0
  mov64 r1, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_7968
  ldxdw r2, [r6+0x0]
  mov64 r1, r10
  add64 r1, -0x380
  call fn_0118
  ldxdw r2, [r10-0x380]
  jeq r2, 0x0, jmp_7a30
  ldxdw r1, [r10-0x378]
  ldxdw r3, [r7+0x0]
  ldxdw r4, [r2+0x20]
  jne r4, r3, jmp_7980
  ldxdw r3, [r10-0x748]
  ldxdw r3, [r3+0x10]
  ldxdw r4, [r2+0x28]
  jne r4, r3, jmp_7980
  ldxdw r3, [r10-0x748]
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x30]
  jne r4, r3, jmp_7980
  ldxdw r3, [r10-0x748]
  ldxdw r3, [r3+0x20]
  ldxdw r4, [r2+0x38]
  jne r4, r3, jmp_7980
  ldxdw r3, [r10-0x768]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r2+0x0]
  jne r4, r3, jmp_7980
  ldxdw r3, [r9+0x10]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_7980
  ldxdw r3, [r9+0x18]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_7980
  ldxdw r3, [r9+0x20]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_7980
  ldxb r3, [r1+0x0]
  add64 r3, 0x1
  mov64 r4, r3
  and64 r4, 0xff
  jne r4, r3, jmp_82b8
  ldxdw r2, [r2+0x40]
  stxdw [r10-0x770], r2
  stxb [r1+0x0], r3
  ja jmp_7908

jmp_78c8:
  mov64 r1, r0
  rsh64 r1, 0x20
  ja jmp_7d28

jmp_78e0:
  mov64 r1, 0x2
  mov64 r0, 0x0
  ja jmp_7d28

jmp_78f8:
  mov64 r1, 0x0
  stxdw [r10-0x770], r1

jmp_7908:
  ldxdw r1, [r10-0x758]
  jsgt r1, 0x1, jmp_7a00
  ldxdw r1, [r10-0x758]
  jne r1, 0x0, jmp_7a48
  ldxdw r1, [r10-0x740]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x740], r1
  ldxdw r5, [r10-0x760]
  jgt r1, 0x98967f, jmp_7b78
  mov64 r0, 0x0
  mov64 r1, 0x14
  ja jmp_79c8

jmp_7968:
  mov64 r0, r1
  rsh64 r1, 0x20
  ja jmp_79c0

jmp_7980:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_82b8
  stxb [r1+0x0], r2
  mov64 r0, 0x0

jmp_79b8:
  mov64 r1, 0x2

jmp_79c0:
  ldxdw r5, [r10-0x760]

jmp_79c8:
  ldxb r2, [r5+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_82b8
  stxb [r5+0x0], r2
  ja jmp_7d28

jmp_7a00:
  ldxdw r1, [r10-0x758]
  jne r1, 0x2, jmp_7b00
  ldxdw r1, [r10-0x740]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x740], r1
  ja jmp_7b60

jmp_7a30:
  ldxw r1, [r10-0x374]
  ldxw r0, [r10-0x378]
  ja jmp_79c0

jmp_7a48:
  ldxdw r1, [r10-0x740]
  ldxdw r3, [r1+0x8]
  jeq r3, 0x0, jmp_7da8
  ldxdw r1, [r10-0x740]
  ldxdw r2, [r1+0x10]
  mov64 r1, 0x10
  mov64 r0, 0x0
  ldxdw r5, [r10-0x760]
  jgt r2, r3, jmp_79c8
  ldxdw r4, [r10-0x558]
  mov64 r1, r3
  sub64 r1, r4
  mov64 r4, 0x1
  jgt r1, r3, jmp_7d60
  mov64 r4, 0x0
  mov64 r3, 0x0
  stxdw [r10-0x740], r3
  jeq r4, 0x0, jmp_7d78

jmp_7ad8:
  mov64 r1, 0xb
  ldxdw r3, [r10-0x740]
  ldxdw r5, [r10-0x760]
  jgt r3, r2, jmp_79c8
  ja jmp_7b78

jmp_7b00:
  ldxdw r1, [r8+0x40]
  mov64 r3, r1
  ldxdw r2, [r10-0x770]
  add64 r3, r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_7b38
  mov64 r2, 0x0

jmp_7b38:
  and64 r2, 0x1
  jne r2, 0x0, jmp_8730
  ldxdw r2, [r10-0x770]
  add64 r2, r1
  stxdw [r10-0x740], r2

jmp_7b60:
  ldxdw r1, [r10-0x740]
  ldxdw r5, [r10-0x760]
  jeq r1, 0x0, jmp_7d48

jmp_7b78:
  ldxb r1, [r5+0x0]
  add64 r1, 0x1
  mov64 r2, r1
  and64 r2, 0xff
  jne r2, r1, jmp_82b8
  ldxdw r2, [r10-0x760]
  stxb [r2+0x0], r1
  mov64 r1, r10
  add64 r1, -0x380
  ldxdw r2, [r10-0x750]
  call fn_0118
  ldxdw r2, [r10-0x380]
  jeq r2, 0x0, jmp_7d30
  ldxdw r1, [r10-0x378]
  ldxdw r3, [r10-0x788]
  ldxdw r3, [r3+0x8]
  ldxdw r4, [r2+0x20]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r10-0x788]
  ldxdw r3, [r3+0x10]
  ldxdw r4, [r2+0x28]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r10-0x788]
  ldxdw r3, [r3+0x18]
  ldxdw r4, [r2+0x30]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r10-0x788]
  ldxdw r3, [r3+0x20]
  ldxdw r4, [r2+0x38]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r10-0x768]
  ldxdw r3, [r3+0x0]
  ldxdw r4, [r2+0x0]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r9+0x10]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r9+0x18]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_7ce8
  ldxdw r3, [r9+0x20]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_7ce8
  ldxdw r2, [r2+0x40]
  ldxdw r3, [r10-0x718]
  jge r2, r3, jmp_7dc0

jmp_7ce8:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_82b8
  stxb [r1+0x0], r2

jmp_7d18:
  mov64 r0, 0x0

jmp_7d20:
  mov64 r1, 0x2

jmp_7d28:
  exit

jmp_7d30:
  ldxw r1, [r10-0x374]
  ldxw r0, [r10-0x378]
  ja jmp_7d28

jmp_7d48:
  mov64 r0, 0x0
  mov64 r1, 0x10
  ja jmp_79c8

jmp_7d60:
  mov64 r3, 0x0
  stxdw [r10-0x740], r3
  jne r4, 0x0, jmp_7ad8

jmp_7d78:
  stxdw [r10-0x740], r1
  mov64 r1, 0xb
  ldxdw r3, [r10-0x740]
  ldxdw r5, [r10-0x760]
  jgt r3, r2, jmp_79c8
  ja jmp_7b78

jmp_7da8:
  mov64 r1, 0x10

jmp_7db0:
  mov64 r0, 0x0
  ja jmp_79c0

jmp_7dc0:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_82b8
  stxb [r1+0x0], r2
  ldxdw r1, [r10-0x740]
  jeq r1, 0x0, jmp_82d0
  jeq r6, 0x0, jmp_8250
  ldxdw r1, [r10-0x770]
  jeq r1, 0x0, jmp_8250
  mov64 r1, r10
  add64 r1, -0x688
  stxdw [r10-0x370], r1
  lddw r7, str_0371
  stxdw [r10-0x380], r7
  stdw [r10-0x368], 0x20
  stdw [r10-0x378], 0x7
  mov64 r2, r10
  add64 r2, -0x380
  ldxdw r1, [r10-0x748]
  mov64 r3, 0x2
  ldxdw r4, [r10-0x798]
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_9130
  stxb [r10-0x481], r1
  mov64 r1, r10
  add64 r1, -0x481
  stxdw [r10-0x498], r1
  mov64 r1, r10
  add64 r1, -0x688
  stxdw [r10-0x4a8], r1
  stxdw [r10-0x4b8], r7
  stdw [r10-0x490], 0x1
  stdw [r10-0x4a0], 0x20
  stdw [r10-0x4b0], 0x7
  mov64 r1, r10
  add64 r1, -0x4b8
  stxdw [r10-0x480], r1
  stdw [r10-0x478], 0x3
  ldxdw r1, [r6+0x0]
  ldxdw r2, [r10-0x768]
  stxdw [r10-0x460], r2
  add64 r1, 0x8
  stxdw [r10-0x470], r1
  ldxdw r2, [r10-0x748]
  mov64 r1, r2
  add64 r1, 0x8
  stxdw [r10-0x440], r1
  stxdw [r10-0x450], r1
  sth [r10-0x438], 0x100
  sth [r10-0x448], 0x1
  sth [r10-0x458], 0x0
  sth [r10-0x468], 0x1
  ldxb r3, [r2+0x0]
  ldxdw r2, [r6+0x0]
  ldxb r4, [r2+0x0]
  and64 r3, r4
  jne r3, 0xff, jmp_9158
  mov64 r3, r2
  add64 r3, 0x48
  stxdw [r10-0x378], r3
  mov64 r3, r2
  add64 r3, 0x8
  stxdw [r10-0x380], r3
  ldxdw r3, [r2+0x50]
  mov64 r4, r2
  add64 r4, 0x28
  stxdw [r10-0x360], r4
  mov64 r4, r2
  add64 r4, 0x58
  stxdw [r10-0x368], r4
  stxdw [r10-0x370], r3
  stdw [r10-0x358], 0x0
  ldxw r2, [r2+0x1]
  mov64 r3, r9
  add64 r3, 0x48
  stxdw [r10-0x340], r3
  ldxdw r3, [r10-0x768]
  stxdw [r10-0x348], r3
  stxw [r10-0x350], r2
  ldxdw r2, [r9+0x50]
  mov64 r3, r9
  add64 r3, 0x28
  stxdw [r10-0x328], r3
  mov64 r3, r9
  add64 r3, 0x58
  stxdw [r10-0x330], r3
  stxdw [r10-0x338], r2
  stdw [r10-0x320], 0x0
  ldxw r2, [r9+0x1]
  stxw [r10-0x318], r2
  ldxdw r0, [r10-0x748]
  mov64 r2, r0
  add64 r2, 0x48
  stxdw [r10-0x308], r2
  stxdw [r10-0x310], r1
  mov64 r3, r0
  add64 r3, 0x28
  ldxdw r4, [r0+0x50]
  stxdw [r10-0x2f0], r3
  mov64 r5, r0
  add64 r5, 0x58
  stxdw [r10-0x2f8], r5
  stxdw [r10-0x300], r4
  stdw [r10-0x2e8], 0x0
  ldxw r0, [r0+0x1]
  stxdw [r10-0x2b8], r3
  stxdw [r10-0x2c0], r5
  stxdw [r10-0x2c8], r4
  stxdw [r10-0x2d0], r2
  stxdw [r10-0x2d8], r1
  stxw [r10-0x2a8], r0
  stxw [r10-0x2e0], r0
  stdw [r10-0x2b0], 0x0
  ldxdw r1, [r10-0x770]
  stxdw [r10-0x31], r1
  stb [r10-0x29], 0x6
  stb [r10-0x32], 0xc
  mov64 r1, r10
  add64 r1, -0x32
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x470
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0xa
  stdw [r10-0x18], 0x4
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r4, r10
  add64 r4, -0x480
  mov64 r3, 0x4
  mov64 r5, 0x1
  call sol_invoke_signed_c

jmp_8250:
  ldxdw r1, [r10-0x758]
  jne r1, 0x2, jmp_82e0
  ldxdw r1, [r10-0x558]
  ldxdw r2, [r10-0x740]
  jlt r1, r2, jmp_82a0
  ldxdw r2, [r10-0x740]
  sub64 r1, r2
  stxdw [r10-0x558], r1
  ldxdw r1, [r10-0x710]
  jge r1, r2, jmp_8c98

jmp_82a0:
  mov64 r1, 0xb
  mov64 r0, 0x0
  ja jmp_7d28

jmp_82b8:
  lddw r1, data_0678
  call fn_2bcf8

jmp_82d0:
  mov64 r0, 0x1a
  ja jmp_7d28

jmp_82e0:
  ldxdw r1, [r10-0x758]
  jne r1, 0x3, jmp_8740
  ldxdw r1, [r10-0x790]
  ldxdw r9, [r1+0x8]
  mov64 r1, r9
  lddw r2, data_0750
  mov64 r3, 0x1
  ldxdw r4, [r10-0x798]
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_9130
  stxb [r10-0x481], r1
  mov64 r1, r10
  add64 r1, -0x481
  stxdw [r10-0x18], r1
  lddw r1, str_0361
  stxdw [r10-0x28], r1
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x6
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x480], r1
  stdw [r10-0x478], 0x2
  mov64 r8, r9
  add64 r8, 0x8
  ldxdw r1, [r10-0x790]
  ldxdw r5, [r1+0x20]
  mov64 r6, r5
  add64 r6, 0x8
  stxdw [r10-0x470], r6
  sth [r10-0x468], 0x1
  ldxdw r3, [r1+0x30]
  mov64 r0, r3
  add64 r0, 0x8
  stxdw [r10-0x460], r0
  sth [r10-0x458], 0x0
  ldxdw r2, [r1+0x28]
  stxdw [r10-0x440], r8
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x450], r4
  sth [r10-0x438], 0x100
  sth [r10-0x448], 0x1
  ldxb r7, [r5+0x0]
  ldxb r1, [r2+0x0]
  and64 r1, r7
  jne r1, 0xff, jmp_9158
  stxdw [r10-0x380], r6
  mov64 r1, r5
  add64 r1, 0x48
  stxdw [r10-0x378], r1
  ldxdw r1, [r5+0x50]
  mov64 r6, r5
  add64 r6, 0x28
  stxdw [r10-0x360], r6
  mov64 r6, r5
  add64 r6, 0x58
  stxdw [r10-0x368], r6
  stxdw [r10-0x370], r1
  stdw [r10-0x358], 0x0
  ldxw r1, [r5+0x1]
  mov64 r5, r3
  add64 r5, 0x48
  stxdw [r10-0x340], r5
  stxdw [r10-0x348], r0
  stxw [r10-0x350], r1
  ldxdw r1, [r3+0x50]
  mov64 r5, r3
  add64 r5, 0x28
  stxdw [r10-0x328], r5
  mov64 r5, r3
  add64 r5, 0x58
  stxdw [r10-0x330], r5
  stxdw [r10-0x338], r1
  stdw [r10-0x320], 0x0
  ldxw r1, [r3+0x1]
  mov64 r3, r2
  add64 r3, 0x48
  stxdw [r10-0x308], r3
  stxdw [r10-0x310], r4
  stxw [r10-0x318], r1
  mov64 r1, r2
  add64 r1, 0x28
  ldxdw r3, [r2+0x50]
  stxdw [r10-0x2f0], r1
  mov64 r1, r2
  add64 r1, 0x58
  stxdw [r10-0x2f8], r1
  stxdw [r10-0x300], r3
  stdw [r10-0x2e8], 0x0
  ldxw r1, [r2+0x1]
  mov64 r2, r9
  add64 r2, 0x48
  stxdw [r10-0x2d0], r2
  stxdw [r10-0x2d8], r8
  stxw [r10-0x2e0], r1
  mov64 r1, r9
  add64 r1, 0x28
  ldxdw r2, [r9+0x50]
  stxdw [r10-0x2b8], r1
  mov64 r1, r9
  add64 r1, 0x58
  stxdw [r10-0x2c0], r1
  stxdw [r10-0x2c8], r2
  stdw [r10-0x2b0], 0x0
  ldxw r1, [r9+0x1]
  stxw [r10-0x2a8], r1
  ldxdw r1, [r10-0x740]
  stxdw [r10-0x31], r1
  stb [r10-0x29], 0x6
  stb [r10-0x32], 0xc
  mov64 r1, r10
  add64 r1, -0x32
  stxdw [r10-0x4a0], r1
  mov64 r1, r10
  add64 r1, -0x470
  stxdw [r10-0x4b0], r1
  lddw r1, data_02c1
  stxdw [r10-0x4b8], r1
  stdw [r10-0x498], 0xa
  stdw [r10-0x4a8], 0x4
  mov64 r1, r10
  add64 r1, -0x4b8
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r4, r10
  add64 r4, -0x480
  mov64 r3, 0x4
  mov64 r5, 0x1
  ja jmp_8a98

jmp_8730:
  mov64 r1, 0x4
  ja jmp_7db0

jmp_8740:
  ldxdw r1, [r10-0x790]
  ldxdw r0, [r1+0x20]
  mov64 r7, r0
  add64 r7, 0x8
  stxdw [r10-0x470], r7
  sth [r10-0x468], 0x1
  ldxdw r4, [r1+0x30]
  mov64 r6, r4
  add64 r6, 0x8
  stxdw [r10-0x460], r6
  sth [r10-0x458], 0x0
  ldxdw r2, [r1+0x28]
  mov64 r5, r2
  add64 r5, 0x8
  stxdw [r10-0x450], r5
  sth [r10-0x448], 0x1
  ldxdw r1, [r1+0x0]
  mov64 r8, r1
  add64 r8, 0x8
  stxdw [r10-0x440], r8
  sth [r10-0x438], 0x100
  ldxb r9, [r0+0x0]
  ldxb r3, [r2+0x0]
  and64 r3, r9
  jne r3, 0xff, jmp_9158
  stxdw [r10-0x380], r7
  mov64 r3, r0
  add64 r3, 0x48
  stxdw [r10-0x378], r3
  ldxdw r3, [r0+0x50]
  mov64 r7, r0
  add64 r7, 0x28
  stxdw [r10-0x360], r7
  mov64 r7, r0
  add64 r7, 0x58
  stxdw [r10-0x368], r7
  stxdw [r10-0x370], r3
  stdw [r10-0x358], 0x0
  ldxw r3, [r0+0x1]
  mov64 r0, r4
  add64 r0, 0x48
  stxdw [r10-0x340], r0
  stxdw [r10-0x348], r6
  stxw [r10-0x350], r3
  ldxdw r3, [r4+0x50]
  mov64 r0, r4
  add64 r0, 0x28
  stxdw [r10-0x328], r0
  mov64 r0, r4
  add64 r0, 0x58
  stxdw [r10-0x330], r0
  stxdw [r10-0x338], r3
  stdw [r10-0x320], 0x0
  ldxw r3, [r4+0x1]
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x308], r4
  stxdw [r10-0x310], r5
  stxw [r10-0x318], r3
  mov64 r3, r2
  add64 r3, 0x28
  ldxdw r4, [r2+0x50]
  stxdw [r10-0x2f0], r3
  mov64 r3, r2
  add64 r3, 0x58
  stxdw [r10-0x2f8], r3
  stxdw [r10-0x300], r4
  stdw [r10-0x2e8], 0x0
  ldxw r2, [r2+0x1]
  mov64 r3, r1
  add64 r3, 0x48
  stxdw [r10-0x2d0], r3
  stxdw [r10-0x2d8], r8
  stxw [r10-0x2e0], r2
  mov64 r2, r1
  add64 r2, 0x28
  ldxdw r3, [r1+0x50]
  stxdw [r10-0x2b8], r2
  mov64 r2, r1
  add64 r2, 0x58
  stxdw [r10-0x2c0], r2
  stxdw [r10-0x2c8], r3
  stdw [r10-0x2b0], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x2a8], r1
  ldxdw r1, [r10-0x740]
  stxdw [r10-0x27], r1
  stb [r10-0x1f], 0x6
  stb [r10-0x28], 0xc
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x4a0], r1
  mov64 r1, r10
  add64 r1, -0x470
  stxdw [r10-0x4b0], r1
  lddw r1, data_02c1
  stxdw [r10-0x4b8], r1
  stdw [r10-0x498], 0xa
  stdw [r10-0x4a8], 0x4
  mov64 r1, r10
  add64 r1, -0x4b8
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r3, 0x4
  mov64 r4, 0x8
  mov64 r5, 0x0

jmp_8a98:
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x558]
  mov64 r3, r1
  ldxdw r2, [r10-0x740]
  add64 r3, r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_8ad8
  mov64 r2, 0x0

jmp_8ad8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_9140
  ldxdw r4, [r10-0x740]
  mov64 r2, r4
  add64 r2, r1
  stxdw [r10-0x558], r2
  ldxdw r1, [r10-0x710]
  mov64 r3, r1
  add64 r3, r4
  mov64 r2, 0x1
  jlt r3, r1, jmp_8b38
  mov64 r2, 0x0

jmp_8b38:
  and64 r2, 0x1
  stb [r10-0x4c0], 0x1
  jne r2, 0x0, jmp_9140
  ldxdw r3, [r10-0x740]
  mov64 r2, r3
  add64 r2, r1
  stxdw [r10-0x710], r2
  ldxdw r2, [r10-0x718]
  mov64 r1, r2
  add64 r1, r3
  mov64 r3, 0x1
  jlt r1, r2, jmp_8ba0
  mov64 r3, 0x0

jmp_8ba0:
  and64 r3, 0x1
  mov64 r1, 0x4
  mov64 r0, 0x0
  jne r3, 0x0, jmp_7d28
  ldxdw r1, [r10-0x740]
  add64 r1, r2
  stxdw [r10-0x718], r1

jmp_8bd8:
  mov64 r1, r10
  add64 r1, -0x738
  call fn_2a1d0
  mov64 r1, r0
  mov64 r0, 0x0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  ldxdw r2, [r10-0x790]
  jne r1, 0x0, jmp_7d28
  ldxdw r1, [r2+0x18]
  mov64 r2, r10
  add64 r2, -0x688
  call fn_2458
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_9130
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x10]
  mov64 r2, r10
  add64 r2, -0x738
  call fn_35c0
  ja jmp_7d28

jmp_8c98:
  ldxdw r4, [r10-0x740]
  sub64 r1, r4
  stxdw [r10-0x710], r1
  ldxdw r2, [r10-0x718]
  mov64 r1, 0xb
  mov64 r0, 0x0
  ldxdw r3, [r10-0x790]
  jlt r2, r4, jmp_7d28
  ldxdw r1, [r10-0x740]
  sub64 r2, r1
  stxdw [r10-0x718], r2
  ldxdw r9, [r3+0x8]
  mov64 r1, r9
  lddw r2, data_0750
  mov64 r3, 0x1
  ldxdw r4, [r10-0x798]
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_9130
  stxb [r10-0x481], r1
  mov64 r1, r10
  add64 r1, -0x481
  stxdw [r10-0x18], r1
  lddw r1, str_0361
  stxdw [r10-0x28], r1
  stdw [r10-0x10], 0x1
  stdw [r10-0x20], 0x6
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0x480], r1
  stdw [r10-0x478], 0x2
  mov64 r8, r9
  add64 r8, 0x8
  ldxdw r1, [r10-0x790]
  ldxdw r5, [r1+0x28]
  mov64 r6, r5
  add64 r6, 0x8
  stxdw [r10-0x470], r6
  sth [r10-0x468], 0x1
  ldxdw r3, [r1+0x30]
  mov64 r0, r3
  add64 r0, 0x8
  stxdw [r10-0x460], r0
  sth [r10-0x458], 0x0
  ldxdw r2, [r1+0x20]
  stxdw [r10-0x440], r8
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x450], r4
  sth [r10-0x438], 0x100
  sth [r10-0x448], 0x1
  ldxb r7, [r5+0x0]
  ldxb r1, [r2+0x0]
  and64 r1, r7
  jne r1, 0xff, jmp_9158
  stxdw [r10-0x380], r6
  mov64 r1, r5
  add64 r1, 0x48
  stxdw [r10-0x378], r1
  ldxdw r1, [r5+0x50]
  mov64 r6, r5
  add64 r6, 0x28
  stxdw [r10-0x360], r6
  mov64 r6, r5
  add64 r6, 0x58
  stxdw [r10-0x368], r6
  stxdw [r10-0x370], r1
  stdw [r10-0x358], 0x0
  ldxw r1, [r5+0x1]
  mov64 r5, r3
  add64 r5, 0x48
  stxdw [r10-0x340], r5
  stxdw [r10-0x348], r0
  stxw [r10-0x350], r1
  ldxdw r1, [r3+0x50]
  mov64 r5, r3
  add64 r5, 0x28
  stxdw [r10-0x328], r5
  mov64 r5, r3
  add64 r5, 0x58
  stxdw [r10-0x330], r5
  stxdw [r10-0x338], r1
  stdw [r10-0x320], 0x0
  ldxw r1, [r3+0x1]
  mov64 r3, r2
  add64 r3, 0x48
  stxdw [r10-0x308], r3
  stxdw [r10-0x310], r4
  stxw [r10-0x318], r1
  mov64 r1, r2
  add64 r1, 0x28
  ldxdw r3, [r2+0x50]
  stxdw [r10-0x2f0], r1
  mov64 r1, r2
  add64 r1, 0x58
  stxdw [r10-0x2f8], r1
  stxdw [r10-0x300], r3
  stdw [r10-0x2e8], 0x0
  ldxw r1, [r2+0x1]
  mov64 r2, r9
  add64 r2, 0x48
  stxdw [r10-0x2d0], r2
  stxdw [r10-0x2d8], r8
  stxw [r10-0x2e0], r1
  mov64 r1, r9
  add64 r1, 0x28
  ldxdw r2, [r9+0x50]
  stxdw [r10-0x2b8], r1
  mov64 r1, r9
  add64 r1, 0x58
  stxdw [r10-0x2c0], r1
  stxdw [r10-0x2c8], r2
  stdw [r10-0x2b0], 0x0
  ldxw r1, [r9+0x1]
  stxw [r10-0x2a8], r1
  ldxdw r1, [r10-0x740]
  stxdw [r10-0x31], r1
  stb [r10-0x29], 0x6
  stb [r10-0x32], 0xc
  mov64 r1, r10
  add64 r1, -0x32
  stxdw [r10-0x4a0], r1
  mov64 r1, r10
  add64 r1, -0x470
  stxdw [r10-0x4b0], r1
  lddw r1, data_02c1
  stxdw [r10-0x4b8], r1
  stdw [r10-0x498], 0xa
  stdw [r10-0x4a8], 0x4
  mov64 r1, r10
  add64 r1, -0x4b8
  mov64 r2, r10
  add64 r2, -0x380
  mov64 r4, r10
  add64 r4, -0x480
  mov64 r3, 0x4
  mov64 r5, 0x1
  call sol_invoke_signed_c
  ja jmp_8bd8

jmp_9130:
  mov64 r0, r2
  ja jmp_7d28

jmp_9140:
  mov64 r1, 0x4
  mov64 r0, 0x0
  ja jmp_7d28

jmp_9158:
  mov64 r0, 0xb
  mov64 r1, 0x4
  ja jmp_7d28

fn_9170:
  mov64 r0, r2
  mov64 r6, r1
  ldxdw r2, [r5-0x1000]
  ldxdw r7, [r5-0xff8]
  and64 r7, 0xff
  jgt r7, 0x2e, jmp_94b0
  mov64 r1, 0x1
  lsh64 r1, r7
  lddw r5, 0x4402080001c0
  mov64 r8, r1
  and64 r8, r5
  jeq r8, 0x0, jmp_9340
  jlt r2, 0x8, jmp_9688
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r4
  mov64 r3, r0
  call fn_0f90
  ldxw r2, [r10-0xdc]
  ldxw r1, [r10-0xe0]
  ldxb r3, [r10-0x22]
  jne r3, 0x2, jmp_9248
  stxw [r6+0x8], r2
  stxw [r6+0x4], r1
  stb [r6+0x0], 0x8
  ja jmp_9680

jmp_9248:
  ldxdw r3, [r10-0xc8]
  stxdw [r10-0x8], r3
  ldxdw r3, [r10-0xd0]
  stxdw [r10-0x10], r3
  ldxdw r3, [r10-0xd8]
  stxdw [r10-0x18], r3
  stxw [r10-0x1c], r2
  stxw [r10-0x20], r1
  ldxdw r5, [r10-0xb0]
  jne r7, 0x6, jmp_93b0
  ldxb r7, [r10-0x24]
  ldxb r9, [r10-0x25]
  ldxh r2, [r10-0x2a]
  stxdw [r10-0x100], r2
  ldxdw r2, [r10-0xa0]
  stxdw [r10-0xf0], r2
  ldxdw r2, [r10-0xa8]
  stxdw [r10-0xf8], r2
  ldxh r2, [r10-0x2]
  lsh64 r2, 0x20
  ldxw r3, [r10-0x6]
  or64 r3, r2
  mov64 r2, 0x2
  stxdw [r10-0xe8], r2
  ldxdw r0, [r10-0xe]
  ldxdw r8, [r10-0x16]
  ldxdw r2, [r10-0x1e]
  and64 r7, 0x1
  and64 r9, 0x1
  mov64 r4, r5
  ja jmp_9418

jmp_9340:
  lddw r4, 0x80000004
  and64 r1, r4
  jeq r1, 0x0, jmp_94b0
  jlt r2, 0x3, jmp_96a8
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r3
  mov64 r3, r0
  call fn_1748
  ldxw r1, [r10-0xe0]
  jeq r1, 0x0, jmp_9510
  ldxdw r1, [r10-0xdc]
  ja jmp_94f8

jmp_93b0:
  ldxdw r3, [r10-0x60]
  ldxdw r0, [r10-0x70]
  ldxdw r8, [r10-0x80]
  mov64 r1, 0x3
  stxdw [r10-0xe8], r1
  ldxdw r1, [r10-0x8]
  stxdw [r10-0x108], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0xf8], r1
  ldxdw r1, [r10-0x18]
  stxdw [r10-0xf0], r1
  ldxdw r4, [r10-0x20]
  mov64 r2, r5

jmp_9418:
  ldxdw r5, [r10-0x108]
  stxdw [r6+0x40], r5
  ldxdw r5, [r10-0xf8]
  stxdw [r6+0x38], r5
  ldxdw r5, [r10-0xf0]
  stxdw [r6+0x30], r5
  stxdw [r6+0x28], r4
  stxdw [r6+0x20], r3
  stxdw [r6+0x18], r0
  stxdw [r6+0x10], r8
  stxdw [r6+0x8], r2
  stxh [r6+0x6], r1
  ldxdw r1, [r10-0x100]
  stxh [r6+0x4], r1
  stxb [r6+0x2], r7
  stxb [r6+0x1], r9
  ldxdw r1, [r10-0xe8]
  stxb [r6+0x0], r1
  ja jmp_9680

jmp_94b0:
  jle r2, 0x2, jmp_96c8
  mov64 r1, r10
  add64 r1, -0xe0
  mov64 r2, r3
  mov64 r3, r0
  call fn_1918
  ldxb r1, [r10-0x28]
  jne r1, 0x2, jmp_9550
  ldxdw r1, [r10-0xe0]

jmp_94f8:
  stxdw [r6+0x4], r1
  stb [r6+0x0], 0x8
  ja jmp_9680

jmp_9510:
  ldxdw r1, [r10-0xd8]
  ldxdw r2, [r10-0xd0]
  ldxdw r3, [r10-0xb8]
  stxdw [r6+0x18], r3
  stxdw [r6+0x10], r2
  stxdw [r6+0x8], r1
  stb [r6+0x0], 0x1
  ja jmp_9680

jmp_9550:
  ldxdw r3, [r10-0x98]
  ldxdw r5, [r10-0xa0]
  ldxdw r0, [r10-0xa8]
  ldxdw r1, [r10-0xb0]
  mov64 r2, 0x0
  ldxh r4, [r10-0x2e]
  jsle r7, 0x17, jmp_95b8
  jsgt r7, 0x24, jmp_95d8
  ldxdw r1, [r10-0x50]
  jeq r7, 0x18, jmp_9610
  jne r7, 0x1e, jmp_95e8
  mov64 r2, 0x7
  ja jmp_9628

jmp_95b8:
  jeq r7, 0x1, jmp_9648
  jeq r7, 0xd, jmp_9630
  jeq r7, 0xe, jmp_9600
  ja jmp_95e8

jmp_95d8:
  jeq r7, 0x25, jmp_9600
  jeq r7, 0x29, jmp_9648

jmp_95e8:
  lddw r1, 0x100000000
  ja jmp_94f8

jmp_9600:
  mov64 r2, 0x5
  ja jmp_9648

jmp_9610:
  ldxh r8, [r10-0x2a]
  ldxh r4, [r10-0x2c]
  mov64 r2, 0x6

jmp_9628:
  ja jmp_9648

jmp_9630:
  ldxdw r0, [r10-0xd8]
  ldxdw r1, [r10-0xe0]
  mov64 r2, 0x4

jmp_9648:
  stxdw [r6+0x18], r5
  stxdw [r6+0x10], r0
  stxdw [r6+0x8], r1
  stxh [r6+0x4], r8
  stxh [r6+0x2], r4
  stxb [r6+0x0], r2
  stxdw [r6+0x20], r3

jmp_9680:
  exit

jmp_9688:
  mov64 r1, 0x7
  lddw r3, data_07d0
  call fn_2bc78

jmp_96a8:
  mov64 r1, 0x2
  lddw r3, data_07b8
  call fn_2bc78

jmp_96c8:
  mov64 r1, 0x2
  lddw r3, data_07e8
  call fn_2bc78

fn_96e8:
  mov64 r9, r4
  mov64 r7, r3
  mov64 r8, r2
  mov64 r6, r1
  mov64 r1, r8
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_9cc0
  stxb [r10-0x1a1], r1
  mov64 r1, r10
  add64 r1, -0x1a1
  stxdw [r10-0x190], r1
  lddw r1, str_0361
  stxdw [r10-0x1a0], r1
  stdw [r10-0x188], 0x1
  stdw [r10-0x198], 0x6
  stdw [r10-0xd4], 0x0
  stdw [r10-0xdc], 0x0
  stdw [r10-0xe4], 0x0
  stdw [r10-0xec], 0x0
  stdw [r10-0xf4], 0x0
  stdw [r10-0xfc], 0x0
  stdw [r10-0x104], 0x0
  stdw [r10-0x10c], 0x0
  mov64 r1, 0x13
  ldxb r2, [r9+0xb2]
  jne r2, 0x1, jmp_9cb8
  mov64 r1, 0x1
  ldxdw r4, [r9+0x48]
  jeq r4, 0x0, jmp_9cb8
  ldxb r3, [r9+0x0]
  lddw r2, data_0620
  mov64 r5, r3
  lsh64 r5, 0x3
  add64 r2, r5
  ldxdw r2, [r2+0x0]
  ldxb r5, [r9+0xb3]
  stxdw [r10-0x1b0], r2
  jsgt r3, 0x3, jmp_9898
  jsgt r3, 0x1, jmp_98b8
  jne r3, 0x0, jmp_98e8
  jeq r5, 0x1, jmp_9960
  jeq r5, 0x29, jmp_9960
  ja jmp_9cb8

jmp_9898:
  jsgt r3, 0x5, jmp_98d0
  jne r3, 0x4, jmp_9900
  jeq r5, 0xd, jmp_9960
  ja jmp_9cb8

jmp_98b8:
  jne r3, 0x2, jmp_9918
  jeq r5, 0x6, jmp_9960
  ja jmp_9cb8

jmp_98d0:
  jne r3, 0x6, jmp_9958
  jeq r5, 0x18, jmp_9960
  ja jmp_9cb8

jmp_98e8:
  jeq r5, 0x2, jmp_9960
  jeq r5, 0x1f, jmp_9960
  ja jmp_9cb8

jmp_9900:
  jeq r5, 0x25, jmp_9960
  jeq r5, 0xe, jmp_9960
  ja jmp_9cb8

jmp_9918:
  jgt r5, 0x2e, jmp_9cb8
  mov64 r0, 0x1
  lsh64 r0, r5
  lddw r2, 0x440208000180
  and64 r0, r2
  jne r0, 0x0, jmp_9960
  ja jmp_9cb8

jmp_9958:
  jne r5, 0x1e, jmp_9cb8

jmp_9960:
  stxb [r10-0x177], r5
  lddw r1, 0x544e56455443
  stxdw [r10-0x180], r1
  stb [r10-0x178], 0x1
  ldxh r1, [r9+0xb0]
  stxdw [r10-0x174], r4
  stxh [r10-0x176], r1
  ldxdw r1, [r9+0x50]
  ldxdw r2, [r9+0x58]
  stxdw [r10-0x164], r2
  stxdw [r10-0x16c], r1
  ldxdw r1, [r9+0x60]
  ldxdw r2, [r9+0x68]
  stxdw [r10-0x154], r2
  stxdw [r10-0x15c], r1
  ldxdw r1, [r9+0x70]
  ldxdw r2, [r9+0x78]
  stxdw [r10-0x144], r2
  stxdw [r10-0x14c], r1
  ldxdw r1, [r9+0x80]
  ldxdw r2, [r9+0x88]
  stxdw [r10-0x134], r2
  stxdw [r10-0x13c], r1
  ldxdw r1, [r9+0x90]
  ldxdw r2, [r9+0x98]
  stxdw [r10-0x124], r2
  stxdw [r10-0x12c], r1
  ldxdw r1, [r9+0xa0]
  ldxdw r2, [r9+0xa8]
  stxdw [r10-0x114], r2
  stxdw [r10-0x11c], r1
  jsgt r3, 0x3, jmp_9a90
  jsgt r3, 0x1, jmp_9ac8
  jne r3, 0x0, jmp_9be8
  ldxh r1, [r9+0x2]
  stxh [r10-0x10c], r1
  ja jmp_9d60

jmp_9a90:
  jsgt r3, 0x5, jmp_9ba0
  jne r3, 0x4, jmp_9c40
  ldxdw r1, [r9+0x8]
  stxdw [r10-0x10c], r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0x104], r1
  ja jmp_9d60

jmp_9ac8:
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r1, 0x2
  and64 r2, 0xd3
  jne r3, 0x2, jmp_9cb0
  jne r2, 0x0, jmp_9cb8
  ldxdw r1, [r9+0x1e]
  stxdw [r10-0xf4], r1
  ldxdw r1, [r9+0x16]
  stxdw [r10-0xfc], r1
  ldxdw r1, [r9+0xe]
  stxdw [r10-0x104], r1
  ldxdw r1, [r9+0x6]
  stxdw [r10-0x10c], r1
  ldxdw r1, [r9+0x28]
  stxdw [r10-0xec], r1
  ldxdw r1, [r9+0x30]
  stxdw [r10-0xe4], r1
  ldxdw r1, [r9+0x38]
  stxdw [r10-0xdc], r1
  ldxh r1, [r9+0x4]
  stxh [r10-0xd4], r1
  ldxb r1, [r9+0x1]
  stxb [r10-0xd2], r1
  ldxb r1, [r9+0x2]
  stxb [r10-0xd1], r1
  ja jmp_9d60

jmp_9ba0:
  ldxdw r4, [r10-0x1b0]
  jne r3, 0x6, jmp_9cc8
  ldxh r1, [r9+0x2]
  stxh [r10-0x10c], r1
  ldxh r1, [r9+0x4]
  stxh [r10-0x10a], r1
  ldxdw r1, [r9+0x8]
  stxdw [r10-0x108], r1
  ja jmp_9d68

jmp_9be8:
  ldxdw r1, [r9+0x8]
  stxdw [r10-0x10c], r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0x104], r1
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r1, 0x2
  and64 r2, 0xd0
  jne r2, 0x0, jmp_9cb8
  ldxdw r1, [r9+0x18]
  ja jmp_9ca0

jmp_9c40:
  ldxdw r1, [r9+0x8]
  ldxdw r2, [r9+0x10]
  stxdw [r10-0x104], r2
  stxdw [r10-0x10c], r1
  mov64 r2, 0x1
  lsh64 r2, r3
  mov64 r1, 0x2
  and64 r2, 0xd3
  jne r2, 0x0, jmp_9cb8
  ldxdw r1, [r9+0x18]
  ldxdw r2, [r9+0x20]
  stxdw [r10-0xf4], r2

jmp_9ca0:
  stxdw [r10-0xfc], r1
  ja jmp_9d60

jmp_9cb0:
  jeq r2, 0x0, jmp_9ce0

jmp_9cb8:
  mov64 r0, 0x0

jmp_9cc0:
  exit

jmp_9cc8:
  ldxdw r1, [r9+0x8]
  stxdw [r10-0x10c], r1
  ja jmp_9d68

jmp_9ce0:
  ldxdw r1, [r9+0x40]
  stxdw [r10-0xf4], r1
  ldxdw r1, [r9+0x38]
  stxdw [r10-0xfc], r1
  ldxdw r1, [r9+0x30]
  stxdw [r10-0x104], r1
  ldxdw r1, [r9+0x28]
  stxdw [r10-0x10c], r1
  ldxdw r1, [r9+0x8]
  stxdw [r10-0xec], r1
  ldxdw r1, [r9+0x10]
  stxdw [r10-0xe4], r1
  ldxdw r1, [r9+0x18]
  stxdw [r10-0xdc], r1
  ldxdw r1, [r9+0x20]
  stxdw [r10-0xd4], r1

jmp_9d60:
  ldxdw r4, [r10-0x1b0]

jmp_9d68:
  mov64 r1, r7
  add64 r1, 0x8
  stxdw [r10-0xb8], r1
  mov64 r2, r8
  add64 r2, 0x8
  stxdw [r10-0xc8], r2
  sth [r10-0xb0], 0x0
  sth [r10-0xc0], 0x100
  mov64 r3, r10
  add64 r3, -0x1a0
  stxdw [r10-0xa8], r3
  stdw [r10-0xa0], 0x2
  mov64 r3, r8
  add64 r3, 0x48
  stxdw [r10-0x90], r3
  stxdw [r10-0x98], r2
  ldxdw r2, [r8+0x50]
  mov64 r3, r8
  add64 r3, 0x28
  stxdw [r10-0x78], r3
  mov64 r3, r8
  add64 r3, 0x58
  stxdw [r10-0x80], r3
  stxdw [r10-0x88], r2
  stdw [r10-0x70], 0x0
  ldxw r2, [r8+0x1]
  mov64 r3, r7
  add64 r3, 0x48
  stxdw [r10-0x58], r3
  stxdw [r10-0x60], r1
  stxw [r10-0x68], r2
  mov64 r1, r7
  add64 r1, 0x28
  ldxdw r2, [r7+0x50]
  stxdw [r10-0x40], r1
  mov64 r1, r7
  add64 r1, 0x58
  stxdw [r10-0x48], r1
  stxdw [r10-0x50], r2
  stdw [r10-0x38], 0x0
  ldxw r1, [r7+0x1]
  stxw [r10-0x30], r1
  stxdw [r10-0x8], r4
  mov64 r1, r10
  add64 r1, -0x180
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xc8
  stxdw [r10-0x20], r1
  stxdw [r10-0x28], r6
  stdw [r10-0x18], 0x2
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r4, r10
  add64 r4, -0xa8
  mov64 r3, 0x2
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_9cc0

fn_9f58:
  mov64 r6, r1
  ldxb r1, [r4+0x0]
  jsgt r1, 0x17, jmp_ab10
  jsgt r1, 0xb, jmp_abd8
  jsgt r1, 0x5, jmp_afe0
  jsgt r1, 0x2, jmp_b280
  jeq r1, 0x0, jmp_c188
  jne r1, 0x1, jmp_dbf0
  jne r3, 0xb, jmp_f1c0
  ldxdw r1, [r4+0x99]
  stxdw [r10-0x910], r1
  ldxdw r1, [r4+0x91]
  stxdw [r10-0x908], r1
  ldxdw r1, [r4+0x89]
  stxdw [r10-0x900], r1
  ldxdw r1, [r4+0x81]
  stxdw [r10-0x8f8], r1
  ldxdw r1, [r4+0x79]
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r4+0x71]
  stxdw [r10-0x8e8], r1
  ldxdw r1, [r4+0x69]
  stxdw [r10-0x8e0], r1
  ldxdw r1, [r4+0x61]
  stxdw [r10-0x8d8], r1
  ldxdw r1, [r4+0x59]
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r4+0x51]
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r4+0x49]
  stxdw [r10-0x8c0], r1
  ldxdw r1, [r4+0x41]
  stxdw [r10-0x8b8], r1
  ldxdw r1, [r4+0x39]
  stxdw [r10-0x8b0], r1
  ldxdw r1, [r4+0x31]
  stxdw [r10-0x8a8], r1
  ldxdw r1, [r4+0x29]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r4+0x21]
  stxdw [r10-0x898], r1
  ldxdw r1, [r4+0x19]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x11]
  stxdw [r10-0x888], r1
  ldxdw r9, [r4+0x9]
  ldxdw r8, [r4+0x1]
  ldxdw r1, [r2+0x38]
  mov64 r7, r2
  ldxdw r2, [r2+0x0]
  mov64 r3, r6
  call fn_6638
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r1, [r7+0x28]
  lddw r2, data_0301
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_127e0
  ldxdw r1, [r7+0x30]
  lddw r2, data_02c1
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_127e0
  ldxdw r2, [r7+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  call fn_0000
  ldxdw r2, [r10-0x408]
  jeq r2, 0x0, jmp_112a0
  ldxdw r1, [r10-0x400]
  ldxb r3, [r2+0x2d]
  jne r3, 0x1, jmp_11248
  ldxb r2, [r2+0x2c]
  jne r2, 0x6, jmp_11248
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2
  jne r8, 0x0, jmp_a240
  jne r9, 0x0, jmp_a240
  ldxdw r1, [r10-0x888]
  jne r1, 0x0, jmp_a240
  ldxdw r1, [r10-0x890]
  jeq r1, 0x0, jmp_f1c0

jmp_a240:
  ldxdw r1, [r10-0x898]
  jne r1, 0x0, jmp_a280
  ldxdw r1, [r10-0x8a0]
  jne r1, 0x0, jmp_a280
  ldxdw r1, [r10-0x8a8]
  jne r1, 0x0, jmp_a280
  ldxdw r1, [r10-0x8b0]
  jeq r1, 0x0, jmp_f1c0

jmp_a280:
  ldxdw r1, [r10-0x8b8]
  jne r1, 0x0, jmp_a2c0
  ldxdw r1, [r10-0x8c0]
  jne r1, 0x0, jmp_a2c0
  ldxdw r1, [r10-0x8c8]
  jne r1, 0x0, jmp_a2c0
  ldxdw r1, [r10-0x8d0]
  jeq r1, 0x0, jmp_f1c0

jmp_a2c0:
  ldxdw r1, [r10-0x8d8]
  jne r1, 0x0, jmp_a300
  ldxdw r1, [r10-0x8e0]
  jne r1, 0x0, jmp_a300
  ldxdw r1, [r10-0x8e8]
  jne r1, 0x0, jmp_a300
  ldxdw r1, [r10-0x8f0]
  jeq r1, 0x0, jmp_f1c0

jmp_a300:
  ldxdw r1, [r10-0x8f8]
  jne r1, 0x0, jmp_a340
  ldxdw r1, [r10-0x900]
  jne r1, 0x0, jmp_a340
  ldxdw r1, [r10-0x908]
  jne r1, 0x0, jmp_a340
  ldxdw r1, [r10-0x910]
  jeq r1, 0x0, jmp_f1c0

jmp_a340:
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0x15b
  mov64 r5, r10
  lddw r3, data_0750
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_136a0
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x10]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0xb2
  mov64 r5, r10
  lddw r3, data_0760
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_136a0
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x20]
  lddw r3, data_02c1
  stxdw [r10-0xff8], r3
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0xa5
  mov64 r5, r10
  lddw r3, data_0818
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_136a0
  mov64 r2, r7
  ldxdw r1, [r2+0x8]
  ldxdw r3, [r2+0x20]
  mov64 r5, r3
  add64 r5, 0x8
  stxdw [r10-0x4f8], r5
  sth [r10-0x4f0], 0x1
  ldxdw r2, [r2+0x18]
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x4e8], r4
  sth [r10-0x4e0], 0x0
  ldxb r0, [r3+0x0]
  jne r0, 0xff, jmp_156b8
  stxdw [r10-0x408], r5
  mov64 r5, r3
  add64 r5, 0x48
  stxdw [r10-0x400], r5
  ldxdw r5, [r3+0x50]
  mov64 r0, r3
  add64 r0, 0x28
  stxdw [r10-0x3e8], r0
  mov64 r0, r3
  add64 r0, 0x58
  stxdw [r10-0x3f0], r0
  stxdw [r10-0x3f8], r5
  stdw [r10-0x3e0], 0x0
  ldxw r3, [r3+0x1]
  mov64 r5, r2
  add64 r5, 0x48
  stxdw [r10-0x3c8], r5
  stxdw [r10-0x3d0], r4
  stxw [r10-0x3d8], r3
  ldxdw r3, [r2+0x50]
  mov64 r4, r2
  add64 r4, 0x28
  stxdw [r10-0x3b0], r4
  mov64 r4, r2
  add64 r4, 0x58
  stxdw [r10-0x3b8], r4
  stxdw [r10-0x3c0], r3
  stdw [r10-0x3a8], 0x0
  ldxw r2, [r2+0x1]
  stxw [r10-0x3a0], r2
  stb [r10-0x820], 0x12
  ldxdw r2, [r1+0x8]
  stxdw [r10-0x81f], r2
  ldxdw r2, [r1+0x10]
  stxdw [r10-0x817], r2
  ldxdw r2, [r1+0x18]
  stxdw [r10-0x80f], r2
  ldxdw r1, [r1+0x20]
  stxdw [r10-0x807], r1
  mov64 r1, r10
  add64 r1, -0x820
  stxdw [r10-0x6b0], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x6c0], r1
  lddw r1, data_02c1
  stxdw [r10-0x6c8], r1
  stdw [r10-0x6a8], 0x21
  stdw [r10-0x6b8], 0x2
  mov64 r1, r10
  add64 r1, -0x6c8
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  mov64 r1, r7
  ldxdw r4, [r1+0x40]
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r1+0x8]
  ldxdw r5, [r1+0x48]
  ldxdw r1, [r1+0x50]
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r5
  mov64 r5, r10
  mov64 r1, r6
  call fn_1ad48
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxdw r3, [r2+0x20]
  stxdw [r10-0x3f0], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x3f8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x400], r3
  ldxdw r2, [r2+0x8]
  stxdw [r10-0x408], r2
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x348], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x340], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x338], r3
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x330], r2
  ldxdw r2, [r1+0x20]
  ldxdw r3, [r2+0x8]
  stxdw [r10-0x328], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x320], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x318], r3
  ldxdw r2, [r2+0x20]
  stxdw [r10-0x310], r2
  ldxdw r2, [r1+0x40]
  ldxdw r3, [r2+0x20]
  stxdw [r10-0x2f0], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x2f8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x300], r3
  ldxdw r2, [r2+0x8]
  stxdw [r10-0x308], r2
  ldxdw r2, [r1+0x48]
  ldxdw r3, [r2+0x20]
  stxdw [r10-0x2d0], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x2d8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x2e0], r3
  ldxdw r2, [r2+0x8]
  ldxdw r3, [r10-0x910]
  stxdw [r10-0x350], r3
  ldxdw r3, [r10-0x908]
  stxdw [r10-0x358], r3
  ldxdw r3, [r10-0x900]
  stxdw [r10-0x360], r3
  ldxdw r3, [r10-0x8f8]
  stxdw [r10-0x368], r3
  ldxdw r3, [r10-0x8f0]
  stxdw [r10-0x370], r3
  ldxdw r3, [r10-0x8e8]
  stxdw [r10-0x378], r3
  ldxdw r3, [r10-0x8e0]
  stxdw [r10-0x380], r3
  ldxdw r3, [r10-0x8d8]
  stxdw [r10-0x388], r3
  ldxdw r3, [r10-0x8d0]
  stxdw [r10-0x390], r3
  ldxdw r3, [r10-0x8c8]
  stxdw [r10-0x398], r3
  ldxdw r3, [r10-0x8c0]
  stxdw [r10-0x3a0], r3
  ldxdw r3, [r10-0x8b8]
  stxdw [r10-0x3a8], r3
  ldxdw r3, [r10-0x8b0]
  stxdw [r10-0x3b0], r3
  ldxdw r3, [r10-0x8a8]
  stxdw [r10-0x3b8], r3
  ldxdw r3, [r10-0x8a0]
  stxdw [r10-0x3c0], r3
  ldxdw r3, [r10-0x898]
  stxdw [r10-0x3c8], r3
  ldxdw r3, [r10-0x890]
  stxdw [r10-0x3d0], r3
  ldxdw r3, [r10-0x888]
  stxdw [r10-0x3d8], r3
  stxdw [r10-0x3e0], r9
  stxdw [r10-0x3e8], r8
  stxdw [r10-0x2e8], r2
  sth [r10-0x2b8], 0x0
  lddw r2, 0x3200000014
  stxdw [r10-0x2c0], r2
  stb [r10-0x2b6], 0x0
  stdw [r10-0x2c8], 0x64
  ldxdw r1, [r1+0x8]
  mov64 r2, r10
  add64 r2, -0x408
  call fn_2b08
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  mov64 r6, r10
  add64 r6, -0x408
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r3, 0x98
  call fn_2c080
  lddw r1, 0x48c27395000
  stxdw [r10-0x370], r1
  sth [r10-0x360], 0x0
  stdw [r10-0x368], 0x2710
  ldxdw r1, [r7+0x10]
  mov64 r2, r6
  call fn_35c0
  ja jmp_127e8

jmp_ab10:
  jsgt r1, 0x23, jmp_ac28
  jsgt r1, 0x1d, jmp_b030
  jsgt r1, 0x1a, jmp_b618
  jeq r1, 0x18, jmp_c5c0
  jne r1, 0x19, jmp_dd70
  jne r3, 0x4, jmp_127d8
  ldxdw r1, [r4+0x19]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x11]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r4+0x9]
  stxdw [r10-0x898], r1
  ldxdw r7, [r4+0x1]
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r8, [r10-0x408]
  ldxb r9, [r10-0x23f]
  jne r9, 0x2, jmp_f758
  mov64 r0, r8
  ja jmp_127e8

jmp_abd8:
  jsgt r1, 0x11, jmp_b070
  jsgt r1, 0xe, jmp_b928
  jeq r1, 0xc, jmp_ce98
  jne r1, 0xd, jmp_ddd8
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stxdw [r10-0x3f8], r4
  stxdw [r10-0x400], r1
  stdw [r10-0x408], 0x1
  ja jmp_f0d8

jmp_ac28:
  jsgt r1, 0x29, jmp_b0c0
  jsgt r1, 0x26, jmp_b958
  jeq r1, 0x24, jmp_ceb8
  jne r1, 0x25, jmp_e1e0
  mov64 r0, 0x0
  jne r3, 0x4, jmp_127e0
  mov64 r7, r2
  ldxdw r2, [r2+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_ee28
  mov64 r1, 0x3
  mov64 r2, r7
  ldxdw r3, [r2+0x0]
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_10cb8
  ldxdw r4, [r10-0x3c8]
  ldxdw r5, [r3+0x8]
  mov64 r0, 0x0
  jne r5, r4, jmp_127e8
  ldxdw r4, [r10-0x3c0]
  ldxdw r5, [r3+0x10]
  jne r5, r4, jmp_127e8
  ldxdw r4, [r10-0x3b8]
  ldxdw r5, [r3+0x18]
  jne r5, r4, jmp_127e8
  ldxdw r4, [r10-0x3b0]
  ldxdw r3, [r3+0x20]
  jne r3, r4, jmp_127e8
  ldxdw r2, [r2+0x8]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_127e8
  ldxdw r3, [r10-0x388]
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x380]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x378]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x370]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  ldxdw r2, [r7+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_cf00
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x6c8], r6
  mov64 r1, r10
  add64 r1, -0x6c8
  call fn_1db60
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r6, [r10-0x640]
  jeq r6, 0x0, jmp_12798
  ldxdw r1, [r10-0x638]
  mov64 r2, 0x0
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x6f
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r1, r0
  mov64 r2, 0x0
  lddw r3, 0xde0b6b3a7640000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r8, 0x1
  jlt r0, r6, jmp_af00
  mov64 r8, 0x0

jmp_af00:
  jeq r2, 0x0, jmp_af10
  mov64 r8, 0x0

jmp_af10:
  mov64 r1, r0
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_2c2a8
  and64 r8, 0x1
  jne r8, 0x0, jmp_12798
  ldxdw r3, [r10-0x6b8]
  mov64 r2, r3
  add64 r2, r0
  mov64 r0, 0x1
  mov64 r5, 0x1
  jlt r2, r3, jmp_af78
  mov64 r5, 0x0

jmp_af78:
  ldxdw r6, [r10-0x6b0]
  mov64 r4, r6
  add64 r4, r1
  mov64 r1, r4
  add64 r1, r5
  jlt r1, r6, jmp_12730
  mov64 r0, 0x0
  jne r1, r6, jmp_12738

jmp_afb8:
  mov64 r1, 0x4
  and64 r5, 0x1
  mov64 r0, 0x0
  jeq r5, 0x0, jmp_12760
  ja jmp_127e8

jmp_afe0:
  jsgt r1, 0x8, jmp_bbf0
  jeq r1, 0x6, jmp_cf18
  jne r1, 0x7, jmp_e200
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stdw [r10-0x6c8], 0x0
  stxdw [r10-0x3f8], r4
  stxdw [r10-0x400], r1
  stdw [r10-0x408], 0x5
  ja jmp_f110

jmp_b030:
  jsgt r1, 0x20, jmp_bd90
  jeq r1, 0x1e, jmp_cf50
  jne r1, 0x1f, jmp_e270
  ldxdw r4, [r4+0x8]
  mov64 r1, r6
  mov64 r5, 0x1
  call fn_1c508
  ja jmp_127e8

jmp_b070:
  jsgt r1, 0x14, jmp_be48
  jeq r1, 0x12, jmp_cf78
  jne r1, 0x13, jmp_e290
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stxdw [r10-0x6b8], r4
  stxdw [r10-0x6c0], r1
  stdw [r10-0x6c8], 0x1
  stdw [r10-0x408], 0x2
  ja jmp_f110

jmp_b0c0:
  jsgt r1, 0x2c, jmp_be90
  mov64 r0, 0x0
  jeq r1, 0x2a, jmp_cfb0
  jne r1, 0x2b, jmp_e9b8
  jne r3, 0x3, jmp_127e0
  ldxw r8, [r4+0x4]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r2, [r10-0x404]
  ldxw r3, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_d028
  mov64 r1, r7
  ldxdw r1, [r1+0x0]
  ldxb r4, [r1+0x1]
  jeq r4, 0x0, jmp_10cb0
  lsh64 r2, 0x20
  or64 r2, r3
  ldxdw r3, [r1+0x8]
  mov64 r0, 0x0
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x400]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x3f8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x3f0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_11bc0
  mov64 r1, 0x8
  mov64 r2, r8
  add64 r2, -0x1
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jgt r2, 0xf423f, jmp_127e8
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_10538
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x628], r8
  ja jmp_113a0

jmp_b280:
  mov64 r0, 0x0
  jeq r1, 0x3, jmp_d040
  jne r1, 0x4, jmp_ebe0
  jne r3, 0x3, jmp_127e0
  ldxdw r1, [r4+0x20]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x18]
  stxdw [r10-0x898], r1
  ldxdw r1, [r4+0x10]
  stxdw [r10-0x888], r1
  ldxdw r9, [r4+0x8]
  ldxh r7, [r4+0x2]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_d0c8
  mov64 r1, 0x3
  mov64 r2, r8
  ldxdw r2, [r2+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_10cb8
  ldxdw r3, [r10-0x3a8]
  ldxdw r4, [r2+0x8]
  mov64 r0, 0x0
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x3a0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x398]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x390]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  ldxdw r1, [r10-0x2c8]
  stxdw [r10-0x8a0], r1
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x3f8], r1
  lddw r1, str_0393
  stxdw [r10-0x408], r1
  stxh [r10-0x6c8], r7
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  ldxdw r1, [r8+0x10]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_10920
  ldxdw r2, [r8+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_1748
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_f5b0
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0x2c
  call fn_2c060
  mov64 r0, 0x0
  mov64 r1, r7
  ldxh r2, [r10-0x6a0]
  jne r2, r1, jmp_115b0
  mov64 r1, r9
  add64 r1, -0x1
  ldxdw r2, [r10-0x888]
  jge r1, r2, jmp_12270
  mov64 r1, 0x6
  ldxdw r2, [r10-0x6b0]
  ldxdw r3, [r10-0x890]
  jle r3, r2, jmp_127e8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r1, [r10-0x408]
  ldxdw r2, [r10-0x898]
  jlt r1, r2, jmp_12ff0
  ldxdw r2, [r10-0x898]
  sub64 r1, r2
  ldxdw r2, [r10-0x8a0]
  jge r1, r2, jmp_12ff0
  ldxdw r2, [r10-0x6a8]
  mov64 r0, 0x0
  mov64 r1, 0x15
  ldxdw r3, [r10-0x898]
  jlt r3, r2, jmp_127e8
  ldxdw r1, [r10-0x3e8]
  ldxdw r2, [r10-0x898]
  stxdw [r10-0x6a8], r2
  ldxdw r2, [r10-0x890]
  stxdw [r10-0x6b0], r2
  ldxdw r2, [r10-0x888]
  stxdw [r10-0x6c0], r2
  stxdw [r10-0x6c8], r9
  stxdw [r10-0x6b8], r1
  ldxdw r1, [r8+0x10]
  ja jmp_12eb0

jmp_b618:
  jeq r1, 0x1b, jmp_d0e8
  mov64 r0, 0x0
  jne r1, 0x1c, jmp_ec58
  jne r3, 0x4, jmp_127e0
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r9, [r10-0x404]
  ldxw r2, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_d340
  mov64 r1, 0x3
  mov64 r3, r8
  ldxdw r0, [r3+0x0]
  ldxb r3, [r0+0x1]
  jeq r3, 0x0, jmp_10cb8
  ldxdw r3, [r10-0x2c8]
  stxdw [r10-0x8a0], r3
  ldxdw r3, [r10-0x3d0]
  stxdw [r10-0x898], r3
  ldxdw r3, [r10-0x3d8]
  stxdw [r10-0x890], r3
  ldxdw r3, [r10-0x3e0]
  stxdw [r10-0x888], r3
  ldxdw r7, [r10-0x3e8]
  lsh64 r9, 0x20
  or64 r9, r2
  ldxdw r5, [r0+0x20]
  ldxdw r2, [r0+0x18]
  ldxdw r3, [r0+0x10]
  ldxdw r4, [r0+0x8]
  mov64 r0, 0x0
  jne r4, r9, jmp_b768
  ldxdw r9, [r10-0x400]
  jne r3, r9, jmp_b768
  ldxdw r9, [r10-0x3f8]
  jne r2, r9, jmp_b768
  ldxdw r9, [r10-0x3f0]
  jeq r5, r9, jmp_b7a0

jmp_b768:
  jne r4, r7, jmp_127e8
  ldxdw r4, [r10-0x888]
  jne r3, r4, jmp_127e8
  ldxdw r3, [r10-0x890]
  jne r2, r3, jmp_127e8
  ldxdw r2, [r10-0x898]
  jne r5, r2, jmp_127e8

jmp_b7a0:
  ldxdw r2, [r8+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r1, [r10-0x404]
  ldxw r7, [r10-0x408]
  ldxb r9, [r10-0x350]
  jeq r9, 0x2, jmp_fc58
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  stxdw [r10-0x8d0], r1
  mov64 r1, r3
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxb [r10-0x610], r9
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x6c4], r1
  stxw [r10-0x6c8], r7
  ldxdw r2, [r8+0x18]
  ldxh r3, [r10-0x618]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r4, r6
  call fn_17bf8
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_10e20
  ldxdw r1, [r10-0x3f0]
  stxdw [r10-0x810], r1
  ldxdw r1, [r10-0x3e8]
  stxdw [r10-0x808], r1
  ldxdw r1, [r10-0x3e0]
  stxdw [r10-0x800], r1
  ldxdw r1, [r10-0x3d8]
  stxdw [r10-0x7f8], r1
  ldxdw r7, [r10-0x400]
  stxdw [r10-0x820], r7
  ldxdw r6, [r10-0x3f8]
  stxdw [r10-0x818], r6
  and64 r9, 0x1
  jeq r9, 0x0, jmp_11e00
  mov64 r1, 0x7
  ja jmp_10cb8

jmp_b928:
  jeq r1, 0xf, jmp_d2d0
  jne r1, 0x10, jmp_ed18
  ldxdw r1, [r4+0x8]
  stxdw [r10-0x400], r1
  stdw [r10-0x408], 0x2
  ja jmp_f0d8

jmp_b958:
  jeq r1, 0x27, jmp_d358
  jne r1, 0x28, jmp_ee40
  mov64 r0, 0x0
  mov64 r1, 0x2
  jne r3, 0x4, jmp_127e8
  mov64 r7, r2
  ldxdw r2, [r2+0x0]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_ee28
  mov64 r2, r7
  ldxdw r3, [r2+0x18]
  ldxdw r1, [r3+0x8]
  lddw r4, -0x6c5e9a281e0922fa
  jne r1, r4, jmp_127d8
  ldxdw r4, [r3+0x10]
  lddw r5, -0x53861431b91e3427
  mov64 r0, 0x0
  mov64 r1, 0x2
  jne r4, r5, jmp_127e8
  ldxdw r4, [r3+0x18]
  lddw r5, -0x6ec8a4a0127a4be4
  jne r4, r5, jmp_127e8
  ldxdw r4, [r3+0x20]
  lddw r5, -0x56ff00817a0a73c6
  jne r4, r5, jmp_127e8
  ldxb r3, [r3+0x3]
  jeq r3, 0x0, jmp_127e8
  ldxb r1, [r10-0x2b7]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_11bc0
  ldxdw r3, [r10-0x308]
  ldxdw r1, [r2+0x8]
  ldxdw r2, [r1+0x8]
  jne r2, r3, jmp_11bc0
  ldxdw r2, [r10-0x300]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x2f8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x2f0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_11bc0
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  call fn_0118
  ldxdw r2, [r10-0x408]
  jeq r2, 0x0, jmp_112a0
  ldxdw r1, [r10-0x400]
  ldxdw r4, [r2+0x0]
  ldxdw r3, [r7+0x8]
  ldxdw r5, [r3+0x8]
  jne r4, r5, jmp_127a8
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x8]
  jne r5, r4, jmp_127a8
  ldxdw r4, [r3+0x18]
  ldxdw r5, [r2+0x10]
  jne r5, r4, jmp_127a8
  ldxdw r3, [r3+0x20]
  ldxdw r2, [r2+0x18]
  jne r2, r3, jmp_127a8
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2
  ldxdw r4, [r7+0x10]
  ldxdw r3, [r7+0x8]
  ldxdw r2, [r7+0x0]
  mov64 r1, r6
  call fn_1b770
  ja jmp_127e8

jmp_bbf0:
  jeq r1, 0x9, jmp_d4b8
  jne r1, 0xa, jmp_eff0
  jne r3, 0x2, jmp_127d8
  ldxw r7, [r4+0x4]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r9, [r10-0x2b6]
  jeq r9, 0x2, jmp_e260
  stxdw [r10-0x888], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r9
  stxw [r10-0x6c4], r7
  stxw [r10-0x6c8], r6
  mov64 r0, 0x0
  ldxdw r1, [r8+0x0]
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_10c00
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x6c8]
  jne r2, r3, jmp_10c00
  ldxdw r2, [r10-0x6c0]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_10c00
  ldxdw r2, [r10-0x6b8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_10c00
  ldxdw r2, [r10-0x6b0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_10c00
  mov64 r1, 0x10
  ldxdw r3, [r10-0x888]
  mov64 r2, r3
  jgt r2, 0xf4240, jmp_127e8
  stxw [r10-0x580], r3
  ja jmp_fac8

jmp_bd90:
  jeq r1, 0x21, jmp_d740
  jne r1, 0x22, jmp_f0d0
  mov64 r0, 0x0
  jne r3, 0x4, jmp_127e0
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_be30
  ldxdw r8, [r10-0x398]
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17e50
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_107e0

jmp_be30:
  ldxw r1, [r10-0x400]
  ldxw r0, [r10-0x404]
  ja jmp_127e8

jmp_be48:
  jeq r1, 0x15, jmp_d928
  jne r1, 0x16, jmp_f100
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stdw [r10-0x6c8], 0x0
  stxdw [r10-0x3f8], r4
  stxdw [r10-0x400], r1
  stdw [r10-0x408], 0x0
  ja jmp_f110

jmp_be90:
  jeq r1, 0x2d, jmp_daa8
  jne r1, 0x2e, jmp_f148
  mov64 r7, r2
  add64 r4, 0x1
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r4
  mov64 r8, r3
  mov64 r3, 0xc8
  call fn_2c060
  jne r8, 0x8, jmp_c170
  ldxdw r2, [r7+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r2, [r10-0x2b6]
  jeq r2, 0x2, jmp_127e8
  mov64 r2, r7
  ldxdw r8, [r2+0x0]
  ldxb r3, [r8+0x1]
  jeq r3, 0x0, jmp_11158
  lsh64 r1, 0x20
  or64 r1, r0
  ldxdw r3, [r8+0x8]
  jne r3, r1, jmp_11158
  ldxdw r1, [r10-0x400]
  ldxdw r3, [r8+0x10]
  jne r3, r1, jmp_11158
  ldxdw r1, [r10-0x3f8]
  ldxdw r3, [r8+0x18]
  jne r3, r1, jmp_11158
  ldxdw r1, [r10-0x3f0]
  ldxdw r3, [r8+0x20]
  jne r3, r1, jmp_11158
  mov64 r4, r2
  add64 r4, 0x10
  ldxdw r1, [r10-0x308]
  ldxdw r9, [r4+0x0]
  ldxdw r3, [r9+0x8]
  jne r3, r1, jmp_c170
  ldxdw r1, [r10-0x300]
  ldxdw r3, [r9+0x10]
  jne r3, r1, jmp_c170
  ldxdw r1, [r10-0x2f8]
  ldxdw r3, [r9+0x18]
  jne r3, r1, jmp_c170
  ldxdw r1, [r10-0x2f0]
  ldxdw r3, [r9+0x20]
  jne r3, r1, jmp_c170
  mov64 r3, r2
  add64 r3, 0x20
  ldxdw r5, [r3+0x0]
  ldxdw r1, [r5+0x8]
  lddw r2, 0x457cd1e3b165700b
  jne r1, r2, jmp_c170
  ldxdw r1, [r5+0x10]
  lddw r2, -0x323cfb9480ad62c8
  jne r1, r2, jmp_c170
  ldxdw r1, [r5+0x18]
  lddw r2, -0x4a025fe58c9347a8
  jne r1, r2, jmp_c170
  stxdw [r10-0x890], r3
  stxdw [r10-0x888], r4
  ldxdw r1, [r5+0x20]
  lddw r2, 0x4629f803bcd1b649
  jne r1, r2, jmp_c170
  stxdw [r10-0x898], r5
  ldxb r1, [r5+0x3]
  jeq r1, 0x0, jmp_c170
  mov64 r1, r7
  add64 r1, 0x28
  stxdw [r10-0x8a8], r1
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r1+0x8]
  jne r1, 0x0, jmp_c170
  ldxdw r1, [r10-0x8a0]
  ldxdw r1, [r1+0x10]
  jne r1, 0x0, jmp_c170
  ldxdw r1, [r10-0x8a0]
  ldxdw r1, [r1+0x18]
  jne r1, 0x0, jmp_c170
  ldxdw r1, [r10-0x8a0]
  ldxdw r1, [r1+0x20]
  jeq r1, 0x0, jmp_14018

jmp_c170:
  mov64 r1, 0x2
  mov64 r0, 0x0
  ja jmp_127e8

jmp_c188:
  mov64 r0, 0x0
  mov64 r1, 0x2
  jne r3, 0x5, jmp_127e8
  ldxdw r5, [r6+0x0]
  ldxdw r3, [r2+0x20]
  ldxdw r7, [r3+0x8]
  jne r7, r5, jmp_127e8
  ldxdw r5, [r6+0x8]
  ldxdw r7, [r3+0x10]
  jne r7, r5, jmp_127e8
  ldxdw r5, [r6+0x10]
  ldxdw r7, [r3+0x18]
  jne r7, r5, jmp_127e8
  ldxdw r5, [r6+0x18]
  ldxdw r7, [r3+0x20]
  jne r7, r5, jmp_127e8
  ldxb r3, [r3+0x3]
  jeq r3, 0x0, jmp_127e8
  ldxh r9, [r4+0x2]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r2, [r10-0x404]
  ldxw r3, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_d028
  mov64 r1, r8
  ldxdw r1, [r1+0x0]
  ldxb r4, [r1+0x1]
  jeq r4, 0x0, jmp_10cb0
  lsh64 r2, 0x20
  or64 r2, r3
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_10cb0
  ldxdw r2, [r10-0x400]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_10cb0
  ldxdw r2, [r10-0x3f8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_10cb0
  ldxdw r2, [r10-0x3f0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_10cb0
  ldxdw r1, [r8+0x18]
  ldxdw r2, [r1+0x8]
  jne r2, 0x0, jmp_127d8
  ldxdw r2, [r1+0x10]
  jne r2, 0x0, jmp_127d8
  ldxdw r2, [r1+0x18]
  jne r2, 0x0, jmp_127d8
  ldxdw r2, [r1+0x20]
  jne r2, 0x0, jmp_127d8
  ldxb r2, [r1+0x3]
  mov64 r0, 0x0
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x3f8], r1
  lddw r1, str_0378
  stxdw [r10-0x408], r1
  stxh [r10-0x6c8], r9
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  ldxdw r1, [r8+0x10]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_144e0
  ldxdw r2, [r8+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_1918
  ldxw r1, [r10-0x404]
  stxdw [r10-0x8d0], r1
  ldxw r1, [r10-0x408]
  stxdw [r10-0x8f0], r1
  ldxb r7, [r10-0x350]
  jeq r7, 0x2, jmp_13720
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxb [r10-0x610], r7
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x6c4], r1
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x6c8], r1
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  mov64 r1, r9
  ldxh r2, [r10-0x618]
  jne r2, r1, jmp_145c0
  ldxdw r1, [r8+0x10]
  ldxdw r2, [r1+0x50]
  jne r2, 0xb9, jmp_146c8
  mov64 r2, 0x2
  stxdw [r10-0x8d0], r2
  ldxdw r2, [r8+0x0]
  ldxb r2, [r2+0x2]
  jeq r2, 0x0, jmp_13720
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_13720
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r1, 0x0
  stxdw [r10-0x8d0], r1
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  jeq r0, 0x0, jmp_14d20

jmp_c598:
  mov64 r1, 0x10
  stxdw [r10-0x8f0], r1
  jne r0, 0x1, jmp_14f90
  mov64 r1, 0x1
  ja jmp_14f88

jmp_c5c0:
  mov64 r0, 0x0
  mov64 r1, 0x2
  jeq r3, 0x0, jmp_127e8
  jgt r3, 0x3f, jmp_127e8
  stxdw [r10-0x888], r2
  add64 r3, -0x1
  mov64 r7, r3
  mov64 r2, r3
  and64 r2, 0x1
  jne r2, 0x0, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_cf00
  ldxw r8, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x81c
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x820], r8
  jeq r7, 0x0, jmp_10e40
  lsh64 r7, 0x3
  ldxdw r3, [r10-0x7e8]
  ldxdw r2, [r10-0x7e0]
  add64 r2, r3
  mov64 r1, 0x1
  mov64 r4, 0x1
  jlt r2, r3, jmp_c6d8
  mov64 r4, 0x0

jmp_c6d8:
  ldxdw r3, [r10-0x888]
  mov64 r9, r3
  add64 r9, r7
  ldxdw r5, [r10-0x7d8]
  add64 r5, r2
  stxdw [r10-0x8e0], r5
  jlt r5, r2, jmp_c718
  mov64 r1, 0x0

jmp_c718:
  add64 r3, 0x8
  add64 r9, 0x8
  or64 r4, r1
  stxdw [r10-0x918], r4
  ldxdw r1, [r10-0x7d0]
  stxdw [r10-0x8d8], r1
  ldxdw r1, [r10-0x7c8]
  stxdw [r10-0x8b0], r1
  ldxdw r5, [r10-0x7f8]
  ldxdw r1, [r10-0x800]
  stxdw [r10-0x928], r1
  ldxdw r2, [r10-0x7b0]
  ldxdw r7, [r10-0x7b8]
  mov64 r1, r10
  add64 r1, -0x4fe
  stxdw [r10-0x8f8], r1
  mov64 r1, r10
  add64 r1, -0x6c0
  stxdw [r10-0x900], r1
  mov64 r1, r10
  add64 r1, -0x23e
  stxdw [r10-0x908], r1
  mov64 r1, r10
  add64 r1, -0x400
  stxdw [r10-0x910], r1
  ldxdw r1, [r10-0x7f0]
  stxdw [r10-0x920], r1
  mov64 r4, r1
  ldxdw r1, [r10-0x8e0]
  add64 r4, r1
  stxdw [r10-0x930], r4
  stxdw [r10-0x938], r9
  stxdw [r10-0x940], r2

jmp_c820:
  jeq r2, r7, jmp_12280
  stxdw [r10-0x8a0], r5
  stxdw [r10-0x898], r3
  ldxdw r2, [r3+0x0]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17e50
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_cf00
  ldxdw r1, [r10-0x3e0]
  jne r7, r1, jmp_122b8
  stxdw [r10-0x8a8], r7
  ldxdw r1, [r10-0x3d0]
  stxdw [r10-0x890], r1
  ldxdw r1, [r10-0x3d8]
  stxdw [r10-0x8e8], r1
  ldxdw r1, [r10-0x3e8]
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r10-0x3f0]
  stxdw [r10-0x8c0], r1
  ldxdw r1, [r10-0x3f8]
  stxdw [r10-0x8b8], r1
  ldxw r9, [r10-0x3fc]
  ldxw r7, [r10-0x400]
  ldxdw r1, [r10-0x898]
  ldxdw r2, [r1+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r8, [r10-0x23f]
  jeq r8, 0x2, jmp_127e8
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x900]
  ldxdw r2, [r10-0x910]
  mov64 r3, 0x1c1
  stxdw [r10-0x8f0], r0
  call fn_2c060
  ldxdw r3, [r10-0x908]
  ldxh r1, [r3+0x4]
  ldxdw r2, [r10-0x8f8]
  stxh [r2+0x4], r1
  ldxw r1, [r3+0x0]
  stxw [r2+0x0], r1
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x6c4], r1
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x6c8], r1
  stxb [r10-0x4ff], r8
  lsh64 r9, 0x20
  or64 r9, r7
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r10-0x6c8]
  jne r9, r2, jmp_127e8
  ldxdw r2, [r10-0x6c0]
  ldxdw r5, [r10-0x898]
  ldxdw r3, [r10-0x8b8]
  jne r3, r2, jmp_127e8
  ldxdw r2, [r10-0x6b8]
  ldxdw r3, [r10-0x8c0]
  jne r3, r2, jmp_127e8
  ldxdw r2, [r10-0x6b0]
  ldxdw r3, [r10-0x8c8]
  jne r3, r2, jmp_127e8
  ldxdw r4, [r10-0x8a0]
  mov64 r2, r4
  ldxdw r3, [r10-0x920]
  add64 r2, r3
  mov64 r1, 0x1
  jlt r2, r4, jmp_ca78
  mov64 r1, 0x0

jmp_ca78:
  ldxdw r2, [r10-0x918]
  or64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_12fe0
  mov64 r2, r3
  add64 r2, r4
  mov64 r3, r2
  ldxdw r1, [r10-0x8e0]
  add64 r3, r1
  mov64 r1, 0x1
  jlt r3, r2, jmp_cad8
  mov64 r1, 0x0

jmp_cad8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_12fe0
  mov64 r2, r4
  ldxdw r1, [r10-0x930]
  add64 r2, r1
  mov64 r1, 0xb
  ldxdw r7, [r10-0x928]
  jlt r7, r2, jmp_127e8
  sub64 r7, r2
  mov64 r8, r7
  ldxdw r2, [r10-0x890]
  jlt r7, r2, jmp_cb40
  ldxdw r8, [r10-0x890]

jmp_cb40:
  ldxdw r2, [r10-0x590]
  jlt r2, r8, jmp_127e8
  sub64 r2, r8
  stxdw [r10-0x590], r2
  ldxdw r2, [r10-0x598]
  mov64 r4, r2
  add64 r4, r8
  mov64 r3, 0x1
  jlt r4, r2, jmp_cb90
  mov64 r3, 0x0

jmp_cb90:
  and64 r3, 0x1
  jne r3, 0x0, jmp_12fe0
  mov64 r3, r8
  add64 r3, r2
  stxdw [r10-0x598], r3
  ldxdw r2, [r10-0x8b0]
  jlt r2, r8, jmp_127e8
  ldxdw r3, [r10-0x8a0]
  mov64 r2, r3
  add64 r2, r8
  mov64 r1, 0x1
  jlt r2, r3, jmp_cbf8
  mov64 r1, 0x0

jmp_cbf8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_12fe0
  ldxdw r3, [r10-0x8d8]
  mov64 r1, r3
  sub64 r1, r8
  mov64 r2, 0x1
  jgt r1, r3, jmp_cc78
  mov64 r2, 0x0
  mov64 r3, 0x0
  stxdw [r10-0x8d8], r3
  jeq r2, 0x0, jmp_cc90

jmp_cc50:
  mov64 r1, 0x2
  ldxdw r2, [r5+0x0]
  ldxb r3, [r2+0x2]
  jne r3, 0x0, jmp_ccb8
  ja jmp_127e8

jmp_cc78:
  mov64 r3, 0x0
  stxdw [r10-0x8d8], r3
  jne r2, 0x0, jmp_cc50

jmp_cc90:
  stxdw [r10-0x8d8], r1
  mov64 r1, 0x2
  ldxdw r2, [r5+0x0]
  ldxb r3, [r2+0x2]
  jeq r3, 0x0, jmp_127e8

jmp_ccb8:
  mov64 r0, 0xb
  ldxb r3, [r2+0x0]
  jne r3, 0xff, jmp_11f70
  stb [r2+0x0], 0x0
  ldxdw r3, [r2+0x50]
  jne r3, 0x40, jmp_122d0
  ldxdw r3, [r10-0x890]
  sub64 r3, r8
  stxdw [r2+0x90], r3
  ldxdw r3, [r10-0x8e8]
  stxdw [r2+0x88], r3
  ldxdw r3, [r10-0x8c8]
  stxdw [r2+0x80], r3
  ldxdw r3, [r10-0x8c0]
  stxdw [r2+0x78], r3
  ldxdw r3, [r10-0x8b8]
  stxdw [r2+0x70], r3
  stxdw [r2+0x68], r9
  ldxdw r3, [r10-0x8a8]
  stxdw [r2+0x60], r3
  lddw r3, 0x3130304555515443
  stxdw [r2+0x58], r3
  stb [r2+0x0], 0xff
  ldxdw r9, [r5+0x8]
  ldxb r2, [r9+0x2]
  jeq r2, 0x0, jmp_122d8
  ldxb r1, [r9+0x0]
  jne r1, 0xff, jmp_11f70
  ldxdw r3, [r9+0x50]
  mov64 r2, r9
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x6c8
  call fn_2b890
  mov64 r1, r0
  stb [r9+0x0], 0xff
  mov64 r0, 0x0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x0, jmp_127e8
  ldxdw r1, [r10-0x8b0]
  sub64 r1, r8
  stxdw [r10-0x8b0], r1
  ldxdw r1, [r10-0x8a0]
  add64 r8, r1
  ldxdw r3, [r10-0x898]
  ldxdw r1, [r10-0x890]
  jgt r1, r7, jmp_12368
  mov64 r1, 0x4
  ldxdw r2, [r10-0x8a8]
  jeq r2, -0x1, jmp_127e8
  ldxdw r7, [r10-0x8a8]
  add64 r7, 0x1
  add64 r3, 0x10
  mov64 r5, r8
  ldxdw r9, [r10-0x938]
  ldxdw r2, [r10-0x940]
  jne r3, r9, jmp_c820
  ja jmp_12290

jmp_ce98:
  ldxdw r1, [r4+0x8]
  stxdw [r10-0x400], r1
  stdw [r10-0x408], 0x0
  ja jmp_f0d8

jmp_ceb8:
  jne r3, 0x1, jmp_127d8
  mov64 r7, r2
  ldxdw r2, [r2+0x0]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_f1d0

jmp_cf00:
  ldxw r1, [r10-0x400]
  ldxw r0, [r10-0x404]
  ja jmp_127e8

jmp_cf18:
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stxdw [r10-0x6b8], r4
  stxdw [r10-0x6c0], r1
  stdw [r10-0x6c8], 0x1
  stdw [r10-0x408], 0x4
  ja jmp_f110

jmp_cf50:
  ldxdw r4, [r4+0x8]
  mov64 r1, r6
  mov64 r5, 0x0
  call fn_1c508
  ja jmp_127e8

jmp_cf78:
  ldxdw r1, [r4+0x8]
  ldxdw r4, [r4+0x10]
  stxdw [r10-0x6b8], r4
  stxdw [r10-0x6c0], r1
  stdw [r10-0x6c8], 0x1
  stdw [r10-0x408], 0x1
  ja jmp_f110

jmp_cfb0:
  jne r3, 0x3, jmp_127e0
  ldxdw r1, [r4+0x8]
  stxdw [r10-0x888], r1
  ldxh r7, [r4+0x4]
  ldxh r9, [r4+0x2]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r2, [r10-0x404]
  ldxw r3, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_f288

jmp_d028:
  mov64 r1, r2
  mov64 r0, r3
  ja jmp_127e8

jmp_d040:
  jne r3, 0x3, jmp_127e0
  ldxdw r1, [r4+0x20]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x18]
  stxdw [r10-0x898], r1
  ldxdw r1, [r4+0x10]
  stxdw [r10-0x888], r1
  ldxdw r8, [r4+0x8]
  ldxh r9, [r4+0x2]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_f450

jmp_d0c8:
  ldxw r2, [r10-0x408]
  ldxw r1, [r10-0x404]
  mov64 r0, r2
  ja jmp_127e8

jmp_d0e8:
  jne r3, 0x2, jmp_127d8
  ldxb r7, [r4+0x1]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r9, [r10-0x2b6]
  jeq r9, 0x2, jmp_ddc8
  stxdw [r10-0x888], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r9
  stxw [r10-0x6c4], r7
  stxw [r10-0x6c8], r6
  mov64 r0, 0x0
  mov64 r1, 0x3
  mov64 r2, r8
  ldxdw r6, [r2+0x0]
  ldxb r3, [r6+0x1]
  jeq r3, 0x0, jmp_127e8
  ldxdw r3, [r6+0x20]
  ldxdw r4, [r6+0x18]
  ldxdw r5, [r6+0x10]
  ldxdw r6, [r6+0x8]
  ldxdw r7, [r10-0x6c8]
  jne r6, r7, jmp_d258
  ldxdw r7, [r10-0x6c0]
  jne r5, r7, jmp_d258
  ldxdw r7, [r10-0x6b8]
  jne r4, r7, jmp_d258
  ldxdw r7, [r10-0x6b0]
  jeq r3, r7, jmp_d2b0

jmp_d258:
  ldxdw r7, [r10-0x888]
  and64 r7, 0x1
  jeq r7, 0x0, jmp_127e8
  ldxdw r7, [r10-0x6a8]
  jne r6, r7, jmp_127e8
  ldxdw r6, [r10-0x6a0]
  jne r5, r6, jmp_127e8
  ldxdw r5, [r10-0x698]
  jne r4, r5, jmp_127e8
  ldxdw r4, [r10-0x690]
  jne r3, r4, jmp_127e8

jmp_d2b0:
  ldxdw r1, [r10-0x888]
  stxb [r10-0x578], r1
  ldxdw r1, [r2+0x8]
  ja jmp_fad0

jmp_d2d0:
  mov64 r0, 0x0
  jne r3, 0x4, jmp_127e0
  ldxh r8, [r4+0x2]
  ldxdw r7, [r4+0x8]
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r9, [r10-0x404]
  ldxw r2, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_f5d0

jmp_d340:
  mov64 r1, r9
  mov64 r0, r2
  ja jmp_127e8

jmp_d358:
  jne r3, 0x2, jmp_127d8
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r8, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r9, [r10-0x2b6]
  jeq r9, 0x2, jmp_efd8
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r9
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r6
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r7+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_127e8
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r3, r4, jmp_127e8
  ldxdw r3, [r10-0x6c0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x6b8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x6b0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  stb [r10-0x577], 0x1
  ldxdw r1, [r7+0x8]
  ja jmp_fad0

jmp_d4b8:
  jne r3, 0x3, jmp_127d8
  ldxw r7, [r4+0x4]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r6, [r10-0x2b6]
  jeq r6, 0x2, jmp_127e8
  stxdw [r10-0x888], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r6
  stxw [r10-0x6c4], r9
  stxw [r10-0x6c8], r7
  mov64 r0, 0x0
  mov64 r3, r8
  ldxdw r2, [r3+0x0]
  ldxb r1, [r2+0x1]
  jeq r1, 0x0, jmp_11bc0
  ldxdw r1, [r2+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r1, r4, jmp_11bc0
  ldxdw r1, [r10-0x6c0]
  ldxdw r4, [r2+0x10]
  jne r4, r1, jmp_11bc0
  ldxdw r1, [r10-0x6b8]
  ldxdw r4, [r2+0x18]
  jne r4, r1, jmp_11bc0
  ldxdw r1, [r10-0x6b0]
  ldxdw r4, [r2+0x20]
  jne r4, r1, jmp_11bc0
  mov64 r1, 0x2
  ldxdw r3, [r3+0x10]
  ldxdw r4, [r3+0x8]
  jne r4, 0x0, jmp_127e8
  ldxdw r4, [r3+0x10]
  jne r4, 0x0, jmp_127e8
  ldxdw r4, [r3+0x18]
  jne r4, 0x0, jmp_127e8
  ldxdw r4, [r3+0x20]
  jne r4, 0x0, jmp_127e8
  ldxb r1, [r3+0x3]
  jeq r1, 0x0, jmp_127e0
  ldxdw r1, [r10-0x888]
  jgt r1, 0x3e8, jmp_113d0
  ldxdw r6, [r8+0x8]
  ldxb r1, [r6+0x2]
  jeq r1, 0x0, jmp_127e0
  ldxdw r1, [r6+0x50]
  jne r1, 0x156, jmp_13fb8
  ldxb r2, [r2+0x2]
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_127e8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  jeq r0, 0x0, jmp_13cf8
  mov64 r2, 0x10
  jne r0, 0x1, jmp_d730
  mov64 r2, 0x1

jmp_d730:
  mov64 r0, r2
  ja jmp_127e8

jmp_d740:
  jne r3, 0x7, jmp_127d8
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r7, [r10-0x2b6]
  jeq r7, 0x2, jmp_127e8
  mov64 r3, r10
  add64 r3, -0x818
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x149
  mov64 r8, r0
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x6cd], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x6c9], r1
  stxb [r10-0x6ce], r7
  stxw [r10-0x81c], r9
  stxw [r10-0x820], r8
  ldxb r8, [r10-0x2b7]
  stxb [r10-0x6cf], r8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r7, [r10-0x23f]
  jeq r7, 0x2, jmp_127e8
  stxdw [r10-0x890], r8
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r8, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  mov64 r9, r0
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r9
  mov64 r0, 0x0
  stxb [r10-0x4ff], r7
  and64 r7, 0x1
  jeq r7, 0x0, jmp_10938
  mov64 r1, 0x18
  ja jmp_127e8

jmp_d928:
  jne r3, 0x3, jmp_127d8
  ldxb r7, [r4+0x1]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r6, [r10-0x2b6]
  jeq r6, 0x2, jmp_127e8
  stxdw [r10-0x888], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r6
  stxw [r10-0x6c4], r9
  stxw [r10-0x6c8], r7
  mov64 r0, 0x0
  mov64 r2, r8
  ldxdw r9, [r2+0x0]
  ldxb r1, [r9+0x1]
  jeq r1, 0x0, jmp_10c00
  ldxdw r1, [r9+0x20]
  ldxdw r3, [r9+0x18]
  ldxdw r4, [r9+0x10]
  ldxdw r5, [r9+0x8]
  ldxdw r7, [r10-0x6c8]
  jne r5, r7, jmp_108a0
  ldxdw r7, [r10-0x6c0]
  jne r4, r7, jmp_108a0
  ldxdw r7, [r10-0x6b8]
  jne r3, r7, jmp_108a0
  ldxdw r7, [r10-0x6b0]
  jne r1, r7, jmp_108a0
  ldxdw r5, [r10-0x888]
  ja jmp_10900

jmp_daa8:
  jne r3, 0x3, jmp_f1c0
  ldxdw r8, [r4+0x8]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r3, [r10-0x404]
  ldxw r4, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_f1a8
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxb r5, [r2+0x1]
  jeq r5, 0x0, jmp_10cb0
  lsh64 r3, 0x20
  or64 r3, r4
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x400]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_10cb0
  jeq r8, 0x0, jmp_11230
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r9, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r6, [r10-0x350]
  jne r6, 0x2, jmp_112b8
  mov64 r1, r9
  ja jmp_127e8

jmp_dbf0:
  mov64 r1, 0x2
  jne r3, 0x5, jmp_10cb8
  ldxh r7, [r4+0x4]
  ldxh r9, [r4+0x2]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r3, [r10-0x404]
  ldxw r4, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_f1a8
  mov64 r1, r8
  ldxdw r2, [r1+0x0]
  ldxb r5, [r2+0x1]
  jeq r5, 0x0, jmp_10cb0
  lsh64 r3, 0x20
  or64 r3, r4
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x400]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_10cb0
  ldxdw r1, [r1+0x20]
  lddw r2, data_0301
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r1, 0x2
  jne r0, 0x1a, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r7
  call fn_2a418
  ldxw r1, [r10-0x408]
  ldxb r7, [r10-0x350]
  jne r7, 0x2, jmp_115c0
  mov64 r0, 0x0
  ja jmp_127e8

jmp_dd70:
  jne r3, 0x2, jmp_127d8
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r8, [r10-0x23f]
  jne r8, 0x2, jmp_f880

jmp_ddc8:
  mov64 r0, r6
  ja jmp_127e8

jmp_ddd8:
  jne r3, 0x7, jmp_f1c0
  ldxdw r8, [r4+0x8]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r2, [r10-0x2b6]
  jeq r2, 0x2, jmp_127e8
  mov64 r2, r7
  ldxdw r3, [r2+0x0]
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_10cb0
  lsh64 r1, 0x20
  or64 r1, r0
  ldxdw r4, [r3+0x8]
  jne r4, r1, jmp_10cb0
  ldxdw r1, [r10-0x400]
  ldxdw r4, [r3+0x10]
  jne r4, r1, jmp_10cb0
  ldxdw r1, [r10-0x3f8]
  ldxdw r4, [r3+0x18]
  jne r4, r1, jmp_10cb0
  ldxdw r1, [r10-0x3f0]
  ldxdw r3, [r3+0x20]
  jne r3, r1, jmp_10cb0
  jeq r8, 0x0, jmp_11078
  ldxdw r1, [r2+0x30]
  ldxdw r2, [r1+0x8]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_f1c0
  ldxdw r2, [r1+0x10]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_f1c0
  ldxdw r2, [r1+0x18]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_f1c0
  ldxdw r2, [r1+0x20]
  lddw r3, -0x56ff00817a0a73c6
  jne r2, r3, jmp_f1c0
  ldxb r1, [r1+0x3]
  jeq r1, 0x0, jmp_f1c0
  ldxdw r1, [r10-0x328]
  ldxdw r2, [r7+0x20]
  ldxdw r3, [r2+0x8]
  jne r3, r1, jmp_f1c0
  ldxdw r3, [r10-0x320]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_f1c0
  ldxdw r4, [r10-0x318]
  ldxdw r5, [r2+0x18]
  jne r5, r4, jmp_f1c0
  ldxdw r5, [r10-0x310]
  ldxdw r2, [r2+0x20]
  jne r2, r5, jmp_f1c0
  ldxdw r0, [r10-0x348]
  ldxdw r2, [r7+0x28]
  ldxdw r9, [r2+0x8]
  jne r9, r0, jmp_f1c0
  ldxdw r0, [r10-0x340]
  ldxdw r9, [r2+0x10]
  jne r9, r0, jmp_f1c0
  ldxdw r0, [r10-0x338]
  ldxdw r9, [r2+0x18]
  jne r9, r0, jmp_f1c0
  ldxdw r0, [r10-0x330]
  ldxdw r2, [r2+0x20]
  jne r2, r0, jmp_f1c0
  ldxdw r2, [r7+0x18]
  ldxdw r0, [r2+0x8]
  jne r0, r1, jmp_e078
  ldxdw r1, [r2+0x10]
  jne r1, r3, jmp_e078
  ldxdw r1, [r2+0x18]
  jne r1, r4, jmp_e078
  ldxdw r1, [r2+0x20]
  jeq r1, r5, jmp_f1c0

jmp_e078:
  mov64 r1, r10
  add64 r1, -0x408
  call fn_0118
  ldxdw r3, [r10-0x408]
  jeq r3, 0x0, jmp_112a0
  mov64 r2, 0x2
  ldxdw r1, [r10-0x400]
  ldxdw r5, [r3+0x20]
  ldxdw r4, [r7+0x0]
  ldxdw r0, [r4+0x8]
  jne r5, r0, jmp_e198
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r3+0x28]
  jne r0, r5, jmp_e198
  ldxdw r5, [r4+0x18]
  ldxdw r0, [r3+0x30]
  jne r0, r5, jmp_e198
  ldxdw r4, [r4+0x20]
  ldxdw r5, [r3+0x38]
  jne r5, r4, jmp_e198
  ldxdw r5, [r3+0x0]
  ldxdw r4, [r7+0x28]
  ldxdw r0, [r4+0x8]
  jne r5, r0, jmp_e198
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r3+0x8]
  jne r0, r5, jmp_e198
  ldxdw r5, [r4+0x18]
  ldxdw r0, [r3+0x10]
  jne r0, r5, jmp_e198
  ldxdw r4, [r4+0x20]
  ldxdw r5, [r3+0x18]
  jne r5, r4, jmp_e198
  mov64 r2, 0xb
  ldxdw r3, [r3+0x40]
  jge r3, r8, jmp_14f98

jmp_e198:
  ldxb r3, [r1+0x0]
  add64 r3, 0x1
  mov64 r4, r3
  and64 r4, 0xff
  jne r4, r3, jmp_16660
  stxb [r1+0x0], r3
  mov64 r0, 0x0
  mov64 r1, r2
  ja jmp_127e8

jmp_e1e0:
  mov64 r1, r6
  mov64 r4, 0x1
  call fn_1f100
  ja jmp_127e8

jmp_e200:
  jne r3, 0x2, jmp_127d8
  ldxdw r7, [r4+0x8]
  mov64 r8, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r9, [r10-0x2b6]
  jne r9, 0x2, jmp_f9b8

jmp_e260:
  mov64 r0, r6
  ja jmp_127e8

jmp_e270:
  mov64 r1, r6
  mov64 r4, 0x0
  call fn_1f100
  ja jmp_127e8

jmp_e290:
  jne r3, 0x7, jmp_127d8
  ldxdw r7, [r4+0x18]
  ldxdw r8, [r4+0x10]
  ldxdw r9, [r4+0x8]
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_ee28
  stxdw [r10-0x898], r1
  stxdw [r10-0x890], r9
  ldxdw r1, [r10-0x2c8]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r9, [r10-0x23f]
  jeq r9, 0x2, jmp_127e8
  stxdw [r10-0x8a8], r8
  stxdw [r10-0x8b0], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  mov64 r8, r0
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxb [r10-0x4ff], r9
  stxw [r10-0x6c4], r7
  stxw [r10-0x6c8], r8
  ldxdw r3, [r10-0x888]
  ldxdw r5, [r3+0x0]
  ldxb r1, [r5+0x1]
  jeq r1, 0x0, jmp_11158
  ldxdw r1, [r5+0x20]
  ldxdw r4, [r5+0x18]
  ldxdw r2, [r5+0x10]
  ldxdw r5, [r5+0x8]
  ldxdw r0, [r10-0x6c8]
  jne r5, r0, jmp_11090
  ldxdw r0, [r10-0x6c0]
  jne r2, r0, jmp_11090
  ldxdw r0, [r10-0x6b8]
  jne r4, r0, jmp_11090
  ldxdw r0, [r10-0x6b0]
  jne r1, r0, jmp_11090

jmp_e470:
  mov64 r1, 0x18
  and64 r9, 0x1
  mov64 r0, 0x0
  jne r9, 0x0, jmp_127e8
  ldxdw r2, [r3+0x28]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_0f90
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r9, [r10-0x34a]
  jeq r9, 0x2, jmp_127e8
  mov64 r3, r10
  add64 r3, -0x4f0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0xb6
  mov64 r8, r0
  call fn_2c060
  stxb [r10-0x43a], r9
  stxw [r10-0x4f4], r7
  stxw [r10-0x4f8], r8
  ldxb r1, [r10-0x349]
  stxb [r10-0x439], r1
  mov64 r1, r10
  add64 r1, -0x820
  stxdw [r10-0x3e8], r1
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x3f8], r1
  lddw r1, str_0386
  stxdw [r10-0x408], r1
  ldxdw r1, [r10-0x4c8]
  stxdw [r10-0x820], r1
  stdw [r10-0x3e0], 0x8
  stdw [r10-0x3f0], 0x20
  stdw [r10-0x400], 0x8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x28]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x3
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_122e8
  mov64 r0, 0x0
  ldxdw r1, [r10-0x6c8]
  ldxdw r2, [r10-0x4f8]
  jne r2, r1, jmp_10c00
  ldxdw r1, [r10-0x6c0]
  ldxdw r2, [r10-0x4f0]
  jne r2, r1, jmp_10c00
  ldxdw r1, [r10-0x6b8]
  ldxdw r2, [r10-0x4e8]
  jne r2, r1, jmp_10c00
  ldxdw r2, [r10-0x6b0]
  ldxdw r3, [r10-0x4e0]
  mov64 r1, 0x3
  jne r3, r2, jmp_127e8
  ldxdw r1, [r10-0x8a8]
  ldxdw r2, [r10-0x890]
  or64 r1, r2
  mov64 r5, 0x0
  jeq r1, 0x0, jmp_148a0
  ldxdw r1, [r10-0x898]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_13738
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_1918
  ldxw r8, [r10-0x404]
  ldxw r1, [r10-0x408]
  stxdw [r10-0x8f0], r1
  ldxb r9, [r10-0x350]
  jeq r9, 0x2, jmp_14000
  mov64 r1, r10
  add64 r1, -0x818
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xa8
  call fn_2c060
  ldxw r1, [r10-0x356]
  stxw [r10-0x76e], r1
  ldxh r1, [r10-0x352]
  stxh [r10-0x76a], r1
  ldxw r1, [r10-0x34f]
  stxw [r10-0x767], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x764], r1
  stxb [r10-0x768], r9
  stxw [r10-0x81c], r8
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x820], r1
  ldxh r7, [r10-0x358]
  stxh [r10-0x770], r7
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x3f8], r1
  lddw r1, str_0378
  stxdw [r10-0x408], r1
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  ldxh r1, [r10-0x444]
  stxdw [r10-0x898], r1
  stxh [r10-0x60], r1
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x18]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13ff0
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  mov64 r8, 0x8
  ldxdw r1, [r10-0x898]
  mov64 r2, r7
  jne r2, r1, jmp_14000
  and64 r9, 0x1
  jne r9, 0x0, jmp_14000
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x3f8], r1
  lddw r1, str_0393
  stxdw [r10-0x408], r1
  stxh [r10-0x60], r7
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x20]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13ff0
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x20]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_1748
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_145d8
  ldxw r8, [r10-0x400]
  ldxw r1, [r10-0x404]
  stxdw [r10-0x8f0], r1
  ja jmp_14000

jmp_e9b8:
  mov64 r1, 0x2
  jne r3, 0x4, jmp_127e8
  ldxw r9, [r4+0x4]
  ldxh r8, [r4+0x2]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r3, [r10-0x404]
  ldxw r4, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jeq r1, 0x2, jmp_f1a8
  mov64 r2, r7
  ldxdw r1, [r2+0x0]
  ldxb r5, [r1+0x1]
  jeq r5, 0x0, jmp_10cb0
  lsh64 r3, 0x20
  or64 r3, r4
  ldxdw r4, [r1+0x8]
  mov64 r0, 0x0
  jne r4, r3, jmp_11bc0
  ldxdw r3, [r10-0x400]
  ldxdw r4, [r1+0x10]
  jne r4, r3, jmp_11bc0
  ldxdw r3, [r10-0x3f8]
  ldxdw r4, [r1+0x18]
  jne r4, r3, jmp_11bc0
  ldxdw r3, [r10-0x3f0]
  ldxdw r1, [r1+0x20]
  jne r1, r3, jmp_11bc0
  mov64 r4, r8
  mov64 r1, 0x2
  jne r4, 0x0, jmp_eae0
  mov64 r3, r9
  jeq r3, 0x0, jmp_eb28

jmp_eae0:
  mov64 r3, r8
  add64 r3, -0x1
  and64 r3, 0xffff
  jgt r3, 0x270f, jmp_113d0
  mov64 r3, r9
  add64 r3, -0x2710
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jgt r3, 0x7530, jmp_113d0

jmp_eb28:
  ldxdw r2, [r2+0x18]
  ldxdw r3, [r2+0x8]
  jne r3, 0x0, jmp_127e8
  ldxdw r3, [r2+0x10]
  jne r3, 0x0, jmp_127e8
  ldxdw r3, [r2+0x18]
  jne r3, 0x0, jmp_127e8
  stxdw [r10-0x888], r4
  ldxdw r3, [r2+0x20]
  jne r3, 0x0, jmp_127e8
  ldxb r2, [r2+0x3]
  jeq r2, 0x0, jmp_127e8
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_13590
  ldxw r6, [r10-0x400]
  ldxw r1, [r10-0x404]
  stxdw [r10-0x8f0], r1
  ja jmp_145a8

jmp_ebe0:
  jne r3, 0x3, jmp_127e0
  ldxb r7, [r4+0x1]
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r8, [r10-0x404]
  ldxw r2, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_faf0
  mov64 r1, r8
  mov64 r0, r2
  ja jmp_127e8

jmp_ec58:
  jne r3, 0x3, jmp_127e0
  ldxdw r1, [r4+0x30]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r4+0x28]
  stxdw [r10-0x898], r1
  ldxdw r9, [r4+0x20]
  ldxdw r1, [r4+0x18]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x10]
  stxdw [r10-0x888], r1
  ldxdw r8, [r4+0x8]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r2, [r10-0x404]
  ldxw r4, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_fc68
  mov64 r1, r2
  mov64 r0, r4
  ja jmp_127e8

jmp_ed18:
  mov64 r0, 0x0
  jlt r3, 0xa, jmp_127e0
  stxdw [r10-0x890], r3
  ldxw r1, [r4+0x10]
  stxdw [r10-0x8b8], r1
  ldxw r8, [r4+0xc]
  ldxb r1, [r4+0x1]
  stxdw [r10-0x8a0], r1
  ldxh r1, [r4+0xa]
  stxdw [r10-0x8b0], r1
  ldxh r1, [r4+0x8]
  stxdw [r10-0x8a8], r1
  ldxdw r1, [r4+0x30]
  stxdw [r10-0x8e0], r1
  ldxdw r1, [r4+0x28]
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r4+0x20]
  stxdw [r10-0x8e8], r1
  ldxb r9, [r4+0x3]
  ldxb r1, [r4+0x2]
  stxdw [r10-0x8d8], r1
  ldxh r1, [r4+0x6]
  stxdw [r10-0x8c0], r1
  ldxdw r7, [r4+0x18]
  ldxh r1, [r4+0x4]
  stxdw [r10-0x898], r1
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_fde0

jmp_ee28:
  ldxw r0, [r10-0x408]
  ldxw r1, [r10-0x404]
  ja jmp_127e8

jmp_ee40:
  jne r3, 0x2, jmp_127d8
  ldxdw r1, [r4+0x99]
  stxdw [r10-0x920], r1
  ldxdw r1, [r4+0x91]
  stxdw [r10-0x918], r1
  ldxdw r1, [r4+0x89]
  stxdw [r10-0x910], r1
  ldxdw r1, [r4+0x81]
  stxdw [r10-0x908], r1
  ldxdw r1, [r4+0x79]
  stxdw [r10-0x900], r1
  ldxdw r1, [r4+0x71]
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r4+0x69]
  stxdw [r10-0x8e8], r1
  ldxdw r1, [r4+0x61]
  stxdw [r10-0x8f8], r1
  ldxdw r1, [r4+0x59]
  stxdw [r10-0x8e0], r1
  ldxdw r1, [r4+0x51]
  stxdw [r10-0x8d8], r1
  ldxdw r1, [r4+0x49]
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r4+0x41]
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r4+0x39]
  stxdw [r10-0x8c0], r1
  ldxdw r1, [r4+0x31]
  stxdw [r10-0x8b8], r1
  ldxdw r1, [r4+0x29]
  stxdw [r10-0x8b0], r1
  ldxdw r1, [r4+0x21]
  stxdw [r10-0x8a8], r1
  ldxdw r1, [r4+0x19]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r4+0x11]
  stxdw [r10-0x898], r1
  ldxdw r1, [r4+0x9]
  stxdw [r10-0x890], r1
  ldxdw r1, [r4+0x1]
  stxdw [r10-0x888], r1
  mov64 r9, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r8, [r10-0x404]
  ldxw r6, [r10-0x408]
  ldxb r7, [r10-0x2b6]
  jne r7, 0x2, jmp_10118

jmp_efd8:
  mov64 r1, r8
  mov64 r0, r6
  ja jmp_127e8

jmp_eff0:
  ldxdw r7, [r4+0x29]
  ldxdw r0, [r4+0x21]
  ldxdw r5, [r4+0x19]
  ldxdw r8, [r4+0x11]
  ldxdw r1, [r4+0x9]
  stxdw [r10-0x878], r1
  ldxdw r1, [r4+0x1]
  stxdw [r10-0x880], r1
  jle r3, 0x8, jmp_f1c0
  ldxdw r1, [r2+0x0]
  ldxb r1, [r1+0x1]
  jeq r1, 0x0, jmp_10558
  stxdw [r10-0x8a8], r7
  stxdw [r10-0x8a0], r0
  stxdw [r10-0x898], r5
  stxdw [r10-0x890], r3
  stxdw [r10-0x888], r2
  ldxdw r2, [r2+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x404]
  ldxw r7, [r10-0x408]
  ldxb r9, [r10-0x2b6]
  jne r9, 0x2, jmp_10570
  mov64 r0, r7
  ja jmp_127e8

jmp_f0d0:
  stdw [r10-0x408], 0x3

jmp_f0d8:
  mov64 r4, r10
  add64 r4, -0x408
  mov64 r1, r6
  call fn_6f98
  ja jmp_127e8

jmp_f100:
  stdw [r10-0x6c8], 0x0
  stdw [r10-0x408], 0x3

jmp_f110:
  mov64 r4, r10
  add64 r4, -0x6c8
  mov64 r5, r10
  add64 r5, -0x408
  mov64 r1, r6
  call fn_182a0
  ja jmp_127e8

jmp_f148:
  jne r3, 0x3, jmp_f1c0
  ldxdw r8, [r4+0x8]
  mov64 r7, r2
  ldxdw r2, [r2+0x8]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxw r3, [r10-0x404]
  ldxw r4, [r10-0x408]
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_10470

jmp_f1a8:
  mov64 r1, r3
  mov64 r0, r4
  ja jmp_127e8

jmp_f1c0:
  mov64 r1, 0x2
  ja jmp_10cb8

jmp_f1d0:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x6c8], r6
  mov64 r1, r10
  add64 r1, -0x6c8
  call fn_1db60
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r6, [r7+0x0]
  ldxb r1, [r6+0x2]
  jeq r1, 0x0, jmp_107c8
  ldxb r1, [r6+0x0]
  jeq r1, 0xff, jmp_111c8
  mov64 r0, 0xb
  mov64 r1, 0x0
  ja jmp_127e8

jmp_f288:
  mov64 r1, r8
  ldxdw r1, [r1+0x0]
  ldxb r4, [r1+0x1]
  jeq r4, 0x0, jmp_10cb0
  lsh64 r2, 0x20
  or64 r2, r3
  ldxdw r3, [r1+0x8]
  mov64 r0, 0x0
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x400]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x3f8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_11bc0
  ldxdw r2, [r10-0x3f0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_11bc0
  mov64 r1, 0x8
  mov64 r2, r9
  jgt r2, 0x2710, jmp_127e8
  mov64 r2, r7
  jgt r2, 0x2710, jmp_127e8
  ldxdw r2, [r10-0x888]
  jeq r2, 0x0, jmp_127e8
  ldxdw r2, [r8+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r6, [r10-0x350]
  jeq r6, 0x2, jmp_127e8
  stxdw [r10-0x898], r1
  mov64 r1, r10
  add64 r1, -0x6c0
  stxdw [r10-0x890], r0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxb [r10-0x610], r6
  ldxdw r1, [r10-0x898]
  stxw [r10-0x6c4], r1
  ldxdw r1, [r10-0x890]
  stxw [r10-0x6c8], r1
  stxh [r10-0x612], r7
  stxh [r10-0x614], r9
  ldxdw r1, [r10-0x888]
  stxdw [r10-0x638], r1

jmp_f440:
  ldxdw r1, [r8+0x10]
  ja jmp_11340

jmp_f450:
  mov64 r1, 0x3
  mov64 r2, r7
  ldxdw r2, [r2+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_10cb8
  ldxdw r3, [r10-0x3a8]
  ldxdw r4, [r2+0x8]
  mov64 r0, 0x0
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x3a0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x398]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x390]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x3f8], r1
  lddw r1, str_0393
  stxdw [r10-0x408], r1
  stxh [r10-0x6c8], r9
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  ldxdw r1, [r7+0x10]
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_10920
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_1748
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_113e0

jmp_f5b0:
  ldxw r1, [r10-0x400]
  ldxw r2, [r10-0x404]
  mov64 r0, r2
  ja jmp_127e8

jmp_f5d0:
  mov64 r1, 0x3
  ldxdw r3, [r10-0x888]
  ldxdw r0, [r3+0x0]
  ldxb r3, [r0+0x1]
  jeq r3, 0x0, jmp_10cb8
  stxdw [r10-0x8b8], r8
  stxdw [r10-0x8b0], r7
  ldxb r3, [r10-0x2b8]
  stxdw [r10-0x898], r3
  ldxdw r3, [r10-0x2c8]
  stxdw [r10-0x8a8], r3
  ldxdw r3, [r10-0x3b0]
  stxdw [r10-0x8a0], r3
  ldxdw r3, [r10-0x3b8]
  stxdw [r10-0x890], r3
  ldxdw r4, [r10-0x3c0]
  ldxdw r7, [r10-0x3c8]
  lsh64 r9, 0x20
  or64 r9, r2
  ldxdw r5, [r0+0x20]
  ldxdw r2, [r0+0x18]
  ldxdw r8, [r0+0x10]
  ldxdw r3, [r0+0x8]
  mov64 r0, 0x0
  jne r3, r9, jmp_f6c8
  ldxdw r9, [r10-0x400]
  jne r8, r9, jmp_f6c8
  ldxdw r9, [r10-0x3f8]
  jne r2, r9, jmp_f6c8
  ldxdw r9, [r10-0x3f0]
  jeq r5, r9, jmp_f6f8

jmp_f6c8:
  jne r3, r7, jmp_127e8
  jne r8, r4, jmp_127e8
  ldxdw r3, [r10-0x890]
  jne r2, r3, jmp_127e8
  ldxdw r2, [r10-0x8a0]
  jne r5, r2, jmp_127e8

jmp_f6f8:
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r1, [r10-0x404]
  ldxw r7, [r10-0x408]
  ldxb r9, [r10-0x350]
  jne r9, 0x2, jmp_10d28
  mov64 r0, r7
  ja jmp_127e8

jmp_f758:
  stxdw [r10-0x8a8], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxb [r10-0x4ff], r9
  stxw [r10-0x6c4], r7
  stxw [r10-0x6c8], r8
  mov64 r0, 0x0
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_119b0
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r3, r4, jmp_119b0
  ldxdw r3, [r10-0x6c0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_119b0
  ldxdw r3, [r10-0x6b8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_119b0
  ldxdw r3, [r10-0x6b0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_119b0
  and64 r9, 0x1
  jeq r9, 0x0, jmp_11170
  mov64 r1, 0x18
  ja jmp_127e8

jmp_f880:
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r9, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxb [r10-0x4ff], r8
  stxw [r10-0x6c4], r9
  stxw [r10-0x6c8], r6
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r7+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_127e8
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r3, r4, jmp_127e8
  ldxdw r3, [r10-0x6c0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x6b8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x6b0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  stdw [r10-0x690], 0x0
  stdw [r10-0x698], 0x0
  stdw [r10-0x6a0], 0x0
  stdw [r10-0x6a8], 0x0
  stdw [r10-0x580], 0x0
  ldxdw r1, [r7+0x8]
  ja jmp_121a0

jmp_f9b8:
  stxdw [r10-0x888], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r7, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r9
  stxw [r10-0x6c4], r7
  stxw [r10-0x6c8], r6
  ldxdw r1, [r8+0x0]
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_10cb0
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x6c8]
  jne r2, r3, jmp_10cb0
  ldxdw r2, [r10-0x6c0]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_10cb0
  ldxdw r2, [r10-0x6b8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_10cb0
  ldxdw r2, [r10-0x6b0]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_10cb0
  ldxdw r1, [r10-0x888]
  jeq r1, 0x0, jmp_11290
  stxdw [r10-0x588], r1

jmp_fac8:
  ldxdw r1, [r8+0x8]

jmp_fad0:
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_2b08
  ja jmp_127e8

jmp_faf0:
  mov64 r1, 0x3
  ldxdw r3, [r10-0x888]
  ldxdw r3, [r3+0x0]
  ldxb r4, [r3+0x1]
  jeq r4, 0x0, jmp_10cb8
  stxdw [r10-0x890], r7
  ldxdw r4, [r10-0x3d0]
  stxdw [r10-0x8a0], r4
  ldxdw r4, [r10-0x3d8]
  stxdw [r10-0x898], r4
  ldxdw r4, [r10-0x3e0]
  ldxdw r9, [r10-0x3e8]
  lsh64 r8, 0x20
  or64 r8, r2
  ldxdw r5, [r3+0x20]
  ldxdw r7, [r3+0x18]
  ldxdw r2, [r3+0x10]
  ldxdw r3, [r3+0x8]
  mov64 r0, 0x0
  jne r3, r8, jmp_fbc0
  ldxdw r8, [r10-0x400]
  jne r2, r8, jmp_fbc0
  ldxdw r8, [r10-0x3f8]
  jne r7, r8, jmp_fbc0
  ldxdw r8, [r10-0x3f0]
  jeq r5, r8, jmp_fc08

jmp_fbc0:
  ldxdw r8, [r10-0x890]
  and64 r8, 0x1
  jeq r8, 0x0, jmp_127e8
  jne r3, r9, jmp_127e8
  jne r2, r4, jmp_127e8
  ldxdw r2, [r10-0x898]
  jne r7, r2, jmp_127e8
  ldxdw r2, [r10-0x8a0]
  jne r5, r2, jmp_127e8

jmp_fc08:
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r7, [r10-0x408]
  ldxb r6, [r10-0x23f]
  jne r6, 0x2, jmp_10ec8

jmp_fc58:
  mov64 r0, r7
  ja jmp_127e8

jmp_fc68:
  mov64 r1, 0x3
  mov64 r3, r7
  ldxdw r0, [r3+0x0]
  ldxb r3, [r0+0x1]
  jeq r3, 0x0, jmp_10cb8
  stxdw [r10-0x8c0], r8
  ldxdw r3, [r10-0x3b0]
  stxdw [r10-0x8c8], r3
  ldxdw r3, [r10-0x3b8]
  stxdw [r10-0x8b8], r3
  ldxdw r3, [r10-0x3c0]
  stxdw [r10-0x8b0], r3
  ldxdw r3, [r10-0x3c8]
  stxdw [r10-0x8a8], r3
  lsh64 r2, 0x20
  or64 r2, r4
  ldxdw r5, [r0+0x20]
  ldxdw r4, [r0+0x18]
  ldxdw r3, [r0+0x10]
  ldxdw r8, [r0+0x8]
  mov64 r0, 0x0
  jne r8, r2, jmp_fd48
  ldxdw r2, [r10-0x400]
  jne r3, r2, jmp_fd48
  ldxdw r2, [r10-0x3f8]
  jne r4, r2, jmp_fd48
  ldxdw r2, [r10-0x3f0]
  jeq r5, r2, jmp_fd88

jmp_fd48:
  ldxdw r2, [r10-0x8a8]
  jne r8, r2, jmp_127e8
  ldxdw r2, [r10-0x8b0]
  jne r3, r2, jmp_127e8
  ldxdw r2, [r10-0x8b8]
  jne r4, r2, jmp_127e8
  ldxdw r2, [r10-0x8c8]
  jne r5, r2, jmp_127e8

jmp_fd88:
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r1, [r10-0x404]
  ldxw r8, [r10-0x408]
  ldxb r6, [r10-0x350]
  jne r6, 0x2, jmp_10fa0
  mov64 r0, r8
  ja jmp_127e8

jmp_fde0:
  mov64 r1, 0x3
  ldxdw r2, [r10-0x888]
  ldxdw r2, [r2+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_10cb8
  ldxdw r3, [r10-0x388]
  ldxdw r4, [r2+0x8]
  mov64 r0, 0x0
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x380]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_127e8
  ldxdw r3, [r10-0x378]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_127e8
  stxdw [r10-0x908], r9
  stxdw [r10-0x8f8], r8
  stxdw [r10-0x900], r7
  ldxdw r3, [r10-0x370]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_127e8
  ldxb r1, [r10-0x2b8]
  stxdw [r10-0x918], r1
  ldxw r7, [r10-0x2bc]
  ldxw r1, [r10-0x2c0]
  stxdw [r10-0x910], r1
  ldxdw r8, [r10-0x2c8]
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x20]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r0, [r10-0x408]
  ldxb r9, [r10-0x23f]
  jeq r9, 0x2, jmp_127e8
  stxdw [r10-0x938], r8
  stxdw [r10-0x930], r7
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r8, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxb [r10-0x4ff], r9
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r7
  mov64 r0, 0x0
  mov64 r1, 0x3
  ldxdw r2, [r10-0x888]
  ldxdw r5, [r2+0x8]
  ldxb r2, [r5+0x1]
  jeq r2, 0x0, jmp_127e8
  ldxdw r2, [r10-0x6b0]
  stxdw [r10-0x920], r2
  ldxdw r8, [r10-0x6b8]
  ldxdw r2, [r10-0x6c0]
  stxdw [r10-0x928], r2
  ldxdw r3, [r5+0x20]
  ldxdw r4, [r5+0x18]
  ldxdw r2, [r5+0x10]
  ldxdw r5, [r5+0x8]
  ldxdw r7, [r10-0x6c8]
  stxdw [r10-0x940], r7
  jne r5, r7, jmp_11e68
  ldxdw r7, [r10-0x928]
  jne r2, r7, jmp_11e68
  jne r4, r8, jmp_11e68
  ldxdw r7, [r10-0x920]
  jne r3, r7, jmp_11e68
  mov64 r1, 0x18
  mov64 r2, r9
  and64 r2, 0x1
  jne r2, 0x0, jmp_127e8

jmp_10070:
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jne r1, 0x0, jmp_10f80
  stxdw [r10-0x948], r8
  ldxdw r8, [r10-0x920]
  ldxdw r7, [r10-0x3e8]
  and64 r9, 0x1
  jeq r9, 0x0, jmp_127f0
  ldxdw r1, [r10-0x650]
  ldxdw r4, [r10-0x658]
  ldxdw r9, [r10-0x548]
  stxdw [r10-0x658], r4
  stxdw [r10-0x650], r1
  jsle r7, r9, jmp_12930
  ja jmp_12938

jmp_10118:
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r7
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r6
  mov64 r0, 0x0
  mov64 r2, r9
  ldxdw r1, [r2+0x0]
  ldxb r3, [r1+0x1]
  jeq r3, 0x0, jmp_119b0
  ldxdw r3, [r1+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r3, r4, jmp_119b0
  ldxdw r3, [r10-0x6c0]
  ldxdw r4, [r1+0x10]
  jne r4, r3, jmp_119b0
  ldxdw r3, [r10-0x6b8]
  ldxdw r4, [r1+0x18]
  jne r4, r3, jmp_119b0
  ldxdw r3, [r10-0x6b0]
  ldxdw r1, [r1+0x20]
  jne r1, r3, jmp_119b0
  mov64 r1, 0x2
  ldxdw r3, [r10-0x888]
  jne r3, 0x0, jmp_10250
  ldxdw r4, [r10-0x890]
  jne r4, 0x0, jmp_10250
  ldxdw r4, [r10-0x898]
  jne r4, 0x0, jmp_10250
  ldxdw r4, [r10-0x8a0]
  jeq r4, 0x0, jmp_127e8

jmp_10250:
  ldxdw r4, [r10-0x8a8]
  ldxdw r5, [r10-0x8b0]
  jne r4, 0x0, jmp_10290
  jne r5, 0x0, jmp_10290
  ldxdw r6, [r10-0x8b8]
  jne r6, 0x0, jmp_10290
  ldxdw r6, [r10-0x8c0]
  jeq r6, 0x0, jmp_127e8

jmp_10290:
  ldxdw r6, [r10-0x8c8]
  ldxdw r7, [r10-0x8d0]
  jne r6, 0x0, jmp_102d0
  jne r7, 0x0, jmp_102d0
  ldxdw r8, [r10-0x8d8]
  jne r8, 0x0, jmp_102d0
  ldxdw r8, [r10-0x8e0]
  jeq r8, 0x0, jmp_127e8

jmp_102d0:
  ldxdw r8, [r10-0x8f8]
  jne r8, 0x0, jmp_10310
  ldxdw r9, [r10-0x8e8]
  jne r9, 0x0, jmp_10310
  ldxdw r9, [r10-0x8f0]
  jne r9, 0x0, jmp_10310
  ldxdw r9, [r10-0x900]
  jeq r9, 0x0, jmp_127e8

jmp_10310:
  ldxdw r9, [r10-0x908]
  jne r9, 0x0, jmp_10350
  ldxdw r9, [r10-0x910]
  jne r9, 0x0, jmp_10350
  ldxdw r9, [r10-0x918]
  jne r9, 0x0, jmp_10350
  ldxdw r9, [r10-0x920]
  jeq r9, 0x0, jmp_127e8

jmp_10350:
  ldxdw r1, [r10-0x920]
  stxdw [r10-0x610], r1
  ldxdw r1, [r10-0x918]
  stxdw [r10-0x618], r1
  ldxdw r1, [r10-0x910]
  stxdw [r10-0x620], r1
  ldxdw r1, [r10-0x908]
  stxdw [r10-0x628], r1
  ldxdw r1, [r10-0x900]
  stxdw [r10-0x630], r1
  ldxdw r1, [r10-0x8f0]
  stxdw [r10-0x638], r1
  ldxdw r1, [r10-0x8e8]
  stxdw [r10-0x640], r1
  stxdw [r10-0x648], r8
  ldxdw r1, [r10-0x8e0]
  stxdw [r10-0x650], r1
  ldxdw r1, [r10-0x8d8]
  stxdw [r10-0x658], r1
  stxdw [r10-0x660], r7
  stxdw [r10-0x668], r6
  ldxdw r1, [r10-0x8c0]
  stxdw [r10-0x670], r1
  ldxdw r1, [r10-0x8b8]
  stxdw [r10-0x678], r1
  stxdw [r10-0x680], r5
  stxdw [r10-0x688], r4
  ldxdw r1, [r10-0x8a0]
  stxdw [r10-0x690], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x698], r1
  ldxdw r1, [r10-0x890]
  stxdw [r10-0x6a0], r1
  stxdw [r10-0x6a8], r3
  ldxdw r1, [r2+0x8]
  ja jmp_fad0

jmp_10470:
  mov64 r1, r7
  ldxdw r2, [r1+0x0]
  ldxb r5, [r2+0x1]
  jeq r5, 0x0, jmp_10558
  lsh64 r3, 0x20
  or64 r3, r4
  ldxdw r4, [r2+0x8]
  jne r4, r3, jmp_10558
  ldxdw r3, [r10-0x400]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_10cb0
  ldxdw r3, [r10-0x3f0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_10cb0
  jeq r8, 0x0, jmp_11078
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_11360

jmp_10538:
  ldxw r1, [r10-0x400]
  ldxw r2, [r10-0x404]
  mov64 r0, r2
  ja jmp_127e8

jmp_10558:
  mov64 r1, 0x3
  mov64 r0, 0x0
  ja jmp_127e8

jmp_10570:
  stxdw [r10-0x8b0], r8
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r8, r1
  mov64 r1, r3
  mov64 r3, 0x14a
  call fn_2c060
  ldxw r1, [r10-0x2b5]
  stxw [r10-0x575], r1
  ldxb r1, [r10-0x2b1]
  stxb [r10-0x571], r1
  stxb [r10-0x576], r9
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r7
  mov64 r0, 0x0
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x8]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_10c00
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x648]
  jne r3, r4, jmp_10c00
  ldxdw r3, [r10-0x640]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_10c00
  ldxdw r3, [r10-0x638]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_10c00
  ldxdw r3, [r10-0x630]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_10c00
  ldxdw r1, [r1+0x20]
  lddw r2, data_0301
  call fn_5b70
  mov64 r1, 0x2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x28]
  lddw r2, data_02c1
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_14c68
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r2+0x20]
  stxdw [r10-0x858], r1
  ldxdw r1, [r2+0x18]
  stxdw [r10-0x860], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x868], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x870], r1
  ldxdw r1, [r10-0x878]
  ldxdw r3, [r10-0x880]
  or64 r3, r1
  jeq r3, 0x0, jmp_107c8
  ldxdw r1, [r10-0x870]
  ldxdw r4, [r10-0x8b0]
  ldxdw r5, [r10-0x898]
  ldxdw r0, [r10-0x8a0]
  ldxdw r7, [r10-0x8a8]
  jne r4, r1, jmp_123e8
  ldxdw r1, [r10-0x868]
  jne r5, r1, jmp_123e8
  ldxdw r1, [r10-0x860]
  jne r0, r1, jmp_123e8
  ldxdw r1, [r10-0x858]
  jne r7, r1, jmp_123e8

jmp_107c8:
  mov64 r0, 0x0
  mov64 r1, 0x2
  ja jmp_127e8

jmp_107e0:
  stxdw [r10-0x8a8], r8
  ldxdw r1, [r10-0x3d0]
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r10-0x3e0]
  stxdw [r10-0x8b0], r1
  ldxdw r1, [r10-0x3e8]
  stxdw [r10-0x898], r1
  ldxdw r1, [r10-0x3f0]
  stxdw [r10-0x890], r1
  ldxdw r1, [r10-0x3f8]
  stxdw [r10-0x888], r1
  ldxw r9, [r10-0x3fc]
  ldxw r8, [r10-0x400]
  ldxdw r2, [r7+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r3, [r10-0x408]
  ldxb r2, [r10-0x23f]
  jne r2, 0x2, jmp_10c10
  mov64 r0, r3
  ja jmp_127e8

jmp_108a0:
  ldxdw r7, [r10-0x888]
  and64 r7, 0x1
  jne r7, 0x0, jmp_10c00
  ldxdw r7, [r10-0x6a8]
  jne r5, r7, jmp_10c00
  ldxdw r5, [r10-0x6a0]
  jne r4, r5, jmp_10c00
  ldxdw r4, [r10-0x698]
  ldxdw r5, [r10-0x888]
  jne r3, r4, jmp_10c00
  ldxdw r3, [r10-0x690]
  jne r1, r3, jmp_10c00

jmp_10900:
  mov64 r1, r5
  jne r6, r1, jmp_10cc8
  mov64 r0, 0x1a
  ja jmp_127e8

jmp_10920:
  mov64 r1, r0
  rsh64 r1, 0x20
  ja jmp_127e8

jmp_10938:
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_10c00
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x6c8]
  jne r3, r4, jmp_10c00
  ldxdw r3, [r10-0x6c0]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_10c00
  ldxdw r3, [r10-0x6b8]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_10c00
  ldxdw r3, [r10-0x6b0]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_10c00
  ldxdw r1, [r1+0x30]
  ldxdw r2, [r1+0x8]
  lddw r3, -0x6c5e9a281e0922fa
  jne r2, r3, jmp_14c68
  ldxdw r2, [r1+0x10]
  lddw r3, -0x53861431b91e3427
  jne r2, r3, jmp_14c68
  ldxdw r2, [r1+0x18]
  lddw r3, -0x6ec8a4a0127a4be4
  jne r2, r3, jmp_14c68
  ldxdw r2, [r1+0x20]
  lddw r3, -0x56ff00817a0a73c6
  jne r2, r3, jmp_14c68
  ldxb r1, [r1+0x3]
  jeq r1, 0x0, jmp_14c68
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x20]
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x720]
  jne r2, r3, jmp_136b0
  ldxdw r2, [r10-0x718]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_136b0
  ldxdw r2, [r10-0x710]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_136b0
  ldxdw r2, [r10-0x708]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_136b0
  ldxdw r2, [r10-0x570]
  mov64 r1, 0x10
  stxdw [r10-0x898], r2
  jeq r2, 0x0, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x18]
  lddw r2, data_0848
  mov64 r3, 0x1
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_14250
  mov64 r7, r10
  add64 r7, -0x720
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r2+0x20]
  stxdw [r10-0x3f0], r3
  ldxdw r3, [r2+0x18]
  stxdw [r10-0x3f8], r3
  ldxdw r3, [r2+0x10]
  stxdw [r10-0x400], r3
  ldxdw r2, [r2+0x8]
  stxdw [r10-0x408], r2
  ldxdw r2, [r1+0x18]
  mov64 r1, r10
  add64 r1, -0x4f8
  mov64 r4, r10
  add64 r4, -0x408
  mov64 r3, r7
  call fn_1b550
  ldxw r1, [r10-0x4f8]
  jeq r1, 0x0, jmp_13748
  ldxw r1, [r10-0x4f0]
  ldxw r0, [r10-0x4f4]
  ja jmp_127e8

jmp_10c00:
  mov64 r1, 0x3
  ja jmp_127e8

jmp_10c10:
  lsh64 r1, 0x20
  or64 r1, r3
  lsh64 r9, 0x20
  or64 r9, r8
  jne r1, r9, jmp_10cb0
  ldxdw r4, [r10-0x400]
  mov64 r3, r7
  mov64 r0, 0x0
  ldxdw r8, [r10-0x888]
  jne r4, r8, jmp_11bc0
  ldxdw r4, [r10-0x3f8]
  ldxdw r6, [r10-0x890]
  jne r4, r6, jmp_11bc0
  ldxdw r4, [r10-0x3f0]
  ldxdw r5, [r10-0x898]
  jne r4, r5, jmp_11bc0
  and64 r2, 0x1
  jeq r2, 0x0, jmp_11a80
  mov64 r1, 0x18
  ja jmp_127e8

jmp_10cb0:
  mov64 r1, 0x3

jmp_10cb8:
  mov64 r0, 0x0
  ja jmp_127e8

jmp_10cc8:
  mov64 r1, 0x2
  ldxdw r6, [r2+0x8]
  ldxb r3, [r6+0x2]
  jeq r3, 0x0, jmp_127e8
  ldxdw r1, [r6+0x50]
  jne r1, 0x15b, jmp_119c0

jmp_10cf8:
  stxb [r10-0x576], r5
  mov64 r2, r10
  add64 r2, -0x6c8
  mov64 r1, r6
  call fn_2b08
  ja jmp_127e8

jmp_10d28:
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r8, r1
  mov64 r1, r3
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r7
  stxb [r10-0x610], r9
  mov64 r0, 0x0
  mov64 r1, 0x7
  ldxdw r2, [r10-0x898]
  and64 r2, 0x1
  jne r2, 0x0, jmp_127e8
  and64 r9, 0x1
  jne r9, 0x0, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x18]
  ldxh r3, [r10-0x618]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r4, r6
  call fn_17bf8
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_11bd0

jmp_10e20:
  ldxw r1, [r10-0x400]
  ldxw r2, [r10-0x404]
  mov64 r0, r2
  ja jmp_127e8

jmp_10e40:
  ldxdw r1, [r10-0x7c8]
  jne r1, 0x0, jmp_10e58

jmp_10e50:
  stdw [r10-0x7d0], 0x0

jmp_10e58:
  mov64 r1, r10
  add64 r1, -0x820
  call fn_2a1d0
  mov64 r1, r0
  mov64 r0, 0x0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x0, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x820
  call fn_35c0
  ja jmp_127e8

jmp_10ec8:
  mov64 r3, r10
  add64 r3, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r8, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  call fn_2c060
  ldxw r1, [r10-0x23e]
  stxw [r10-0x4fe], r1
  ldxh r1, [r10-0x23a]
  stxh [r10-0x4fa], r1
  stxw [r10-0x6c4], r8
  stxw [r10-0x6c8], r7
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_11560

jmp_10f80:
  mov64 r0, 0x10
  jne r1, 0x1, jmp_10f98
  mov64 r0, 0x1

jmp_10f98:
  ja jmp_127e8

jmp_10fa0:
  stxdw [r10-0x8a8], r1
  mov64 r1, r10
  add64 r1, -0x6c0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  ldxdw r1, [r10-0x8a0]
  stxdw [r10-0x680], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x688], r1
  stxdw [r10-0x690], r9
  ldxdw r1, [r10-0x890]
  stxdw [r10-0x698], r1
  stxb [r10-0x610], r6
  ldxdw r1, [r10-0x8a8]
  stxw [r10-0x6c4], r1
  stxw [r10-0x6c8], r8
  ldxdw r1, [r10-0x888]
  stxdw [r10-0x628], r1
  ldxdw r1, [r10-0x8c0]
  stxdw [r10-0x630], r1
  ja jmp_11338

jmp_11078:
  mov64 r1, 0x10
  mov64 r0, 0x0
  ja jmp_127e8

jmp_11090:
  ldxdw r3, [r10-0x6a8]
  jne r5, r3, jmp_11158
  ldxdw r3, [r10-0x6a0]
  jne r2, r3, jmp_11158
  ldxdw r3, [r10-0x698]
  jne r4, r3, jmp_11158
  ldxdw r3, [r10-0x690]
  jne r1, r3, jmp_11158
  or64 r2, r5
  or64 r2, r4
  or64 r2, r1
  jeq r2, 0x0, jmp_11158
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_123b0
  mov64 r0, 0x10
  jne r1, 0x1, jmp_126c0
  mov64 r0, 0x1
  ja jmp_126c0

jmp_11158:
  mov64 r1, 0x3
  mov64 r0, 0x0
  ja jmp_127e8

jmp_11170:
  ldxdw r2, [r1+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x2b6]
  jne r1, 0x2, jmp_11850
  ldxw r2, [r10-0x408]
  ldxw r1, [r10-0x404]
  mov64 r0, r2
  ja jmp_127e8

jmp_111c8:
  ldxdw r3, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x58
  mov64 r1, r10
  add64 r1, -0x6c8
  call fn_2b6a0
  mov64 r1, r0
  stb [r6+0x0], 0xff
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x0, jmp_122d8
  mov64 r0, 0x1a
  ja jmp_127e8

jmp_11230:
  mov64 r1, 0x8
  mov64 r0, 0x0
  ja jmp_127e8

jmp_11248:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2
  mov64 r1, 0x2
  mov64 r0, 0x0
  ja jmp_127e8

jmp_11290:
  mov64 r1, 0x10
  ja jmp_10cb8

jmp_112a0:
  ldxw r1, [r10-0x3fc]
  ldxw r0, [r10-0x400]
  ja jmp_127e8

jmp_112b8:
  mov64 r1, r10
  add64 r1, -0x6c0
  stxdw [r10-0x888], r0
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxb [r10-0x610], r6
  stxw [r10-0x6c4], r9
  ldxdw r1, [r10-0x888]
  stxw [r10-0x6c8], r1
  stxdw [r10-0x638], r8

jmp_11338:
  ldxdw r1, [r7+0x10]

jmp_11340:
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_3370
  ja jmp_127e8

jmp_11360:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxdw [r10-0x630], r8

jmp_113a0:
  stxw [r10-0x6c8], r6

jmp_113a8:
  ldxdw r1, [r7+0x10]

jmp_113b0:
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_35c0
  ja jmp_127e8

jmp_113d0:
  mov64 r1, 0x10
  ja jmp_127e8

jmp_113e0:
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0x2c
  call fn_2c060
  mov64 r0, 0x0
  mov64 r1, r9
  ldxh r2, [r10-0x6a0]
  jne r2, r1, jmp_115b0
  mov64 r1, r8
  add64 r1, -0x1
  ldxdw r2, [r10-0x888]
  jge r1, r2, jmp_12270
  mov64 r1, 0x6
  ldxdw r2, [r10-0x6b0]
  ldxdw r3, [r10-0x890]
  jle r3, r2, jmp_127e8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r3, [r10-0x3e8]
  mov64 r4, r3
  add64 r4, 0x1
  mov64 r1, 0x1
  mov64 r5, 0x1
  jslt r4, r3, jmp_12d78
  mov64 r5, 0x0
  lddw r2, 0x7fffffffffffffff
  jeq r5, 0x0, jmp_12d90

jmp_11500:
  mov64 r4, r3
  add64 r4, -0x1
  jslt r4, r3, jmp_12db0

jmp_11518:
  mov64 r1, 0x0
  xor64 r1, 0x1
  lddw r3, -0x8000000000000000
  jeq r1, 0x0, jmp_12dd0

jmp_11540:
  ldxdw r1, [r10-0x6b8]
  ldxdw r4, [r10-0x898]
  jsge r4, r1, jmp_12df0
  ja jmp_12ff0

jmp_11560:
  ldxdw r9, [r10-0x3e8]
  and64 r6, 0x1
  jeq r6, 0x0, jmp_11f80
  ldxdw r2, [r10-0x548]
  ldxdw r1, [r10-0x888]
  ldxdw r7, [r10-0x890]
  jsgt r9, r2, jmp_115a0
  mov64 r9, r2

jmp_115a0:
  stxdw [r10-0x548], r9
  ja jmp_12190

jmp_115b0:
  mov64 r1, 0x8
  ja jmp_127e8

jmp_115c0:
  mov64 r3, r10
  add64 r3, -0x6c4
  mov64 r2, r10
  add64 r2, -0x404
  stxdw [r10-0x8d0], r1
  mov64 r1, r3
  mov64 r3, 0xb4
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x60f], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x60c], r1
  stxb [r10-0x610], r7
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x6c8], r1
  stxh [r10-0x618], r9
  stxh [r10-0x820], r9
  mov64 r1, r10
  add64 r1, -0x820
  stxdw [r10-0x3f8], r1
  lddw r1, str_0378
  stxdw [r10-0x408], r1
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  mov64 r1, r8
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x10]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0xc1
  mov64 r3, r10
  add64 r3, -0x408
  mov64 r5, r10
  mov64 r4, 0x2
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x820
  stxdw [r10-0x3f8], r1
  lddw r1, str_0393
  stxdw [r10-0x408], r1
  stdw [r10-0x3f0], 0x2
  stdw [r10-0x400], 0x6
  mov64 r1, r8
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x18]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0x32
  mov64 r3, r10
  add64 r3, -0x408
  mov64 r5, r10
  mov64 r4, 0x2
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r1, [r8+0x10]
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_3370
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  stxh [r10-0x3e0], r9
  stdw [r10-0x408], 0x0
  stdw [r10-0x400], 0x0
  stdw [r10-0x3f8], 0x0
  stdw [r10-0x3f0], 0x0
  stdw [r10-0x3e8], 0x0
  ldxdw r1, [r8+0x18]
  mov64 r2, r10
  add64 r2, -0x408
  call fn_2718
  ja jmp_127e8

jmp_11850:
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x8]
  ldxb r2, [r1+0x1]
  mov64 r0, 0x0
  jeq r2, 0x0, jmp_119b0
  ldxdw r2, [r10-0x388]
  ldxdw r3, [r1+0x8]
  jne r3, r2, jmp_119b0
  ldxdw r2, [r10-0x380]
  ldxdw r3, [r1+0x10]
  ldxdw r4, [r10-0x8a8]
  jne r3, r2, jmp_119b0
  ldxdw r2, [r10-0x378]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_119b0
  ldxdw r2, [r10-0x370]
  ldxdw r1, [r1+0x20]
  jne r1, r2, jmp_119b0
  ldxdw r2, [r10-0x898]
  ldxdw r3, [r10-0x8a0]
  jne r4, 0x0, jmp_11920
  jne r2, 0x0, jmp_11920
  jne r3, 0x0, jmp_11920
  mov64 r1, 0x2
  ldxdw r5, [r10-0x890]
  jeq r5, 0x0, jmp_127e8

jmp_11920:
  ldxdw r1, [r10-0x890]
  stxdw [r10-0x690], r1
  stxdw [r10-0x698], r3
  stxdw [r10-0x6a0], r2
  stxdw [r10-0x6a8], r4
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jeq r0, 0x0, jmp_12d08

jmp_11988:
  mov64 r2, 0x10
  jne r0, 0x1, jmp_119a0
  mov64 r2, 0x1

jmp_119a0:
  mov64 r0, r2
  ja jmp_127e8

jmp_119b0:
  mov64 r1, 0x3
  ja jmp_127e8

jmp_119c0:
  ldxdw r1, [r2+0x10]
  lddw r2, data_0301
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_14c68
  ldxb r2, [r9+0x2]
  mov64 r0, 0x0
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_127e8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_12458
  mov64 r0, 0x10
  jne r1, 0x1, jmp_126c0
  mov64 r0, 0x1
  ja jmp_127e8

jmp_11a80:
  ldxdw r2, [r3+0x0]
  ldxb r4, [r2+0x1]
  jeq r4, 0x0, jmp_11bc0
  ldxdw r4, [r2+0x8]
  jne r4, r1, jmp_11bc0
  ldxdw r1, [r2+0x10]
  jne r1, r8, jmp_11bc0
  ldxdw r1, [r2+0x18]
  jne r1, r6, jmp_11bc0
  ldxdw r1, [r2+0x20]
  ldxdw r4, [r10-0x898]
  jne r1, r4, jmp_11bc0
  ldxb r1, [r2+0x2]
  jeq r1, 0x0, jmp_127e0
  ldxdw r3, [r3+0x10]
  ldxb r1, [r3+0x2]
  jeq r1, 0x0, jmp_127e0
  ldxdw r1, [r10-0x8a0]
  jne r1, 0x0, jmp_13570
  mov64 r1, 0xf
  ldxdw r4, [r10-0x8a8]
  ldxdw r5, [r10-0x8b0]
  jge r5, r4, jmp_127e8
  ldxdw r3, [r3+0x48]
  ldxdw r4, [r2+0x48]
  mov64 r1, r4
  add64 r1, r3
  mov64 r5, 0x1
  jlt r1, r4, jmp_11b70
  mov64 r5, 0x0

jmp_11b70:
  mov64 r1, 0x4
  and64 r5, 0x1
  jne r5, 0x0, jmp_127e8
  add64 r3, r4
  stxdw [r2+0x48], r3
  ldxdw r1, [r7+0x10]
  ldxb r2, [r1+0x0]
  jeq r2, 0xff, jmp_136c0

jmp_11bb0:
  mov64 r0, 0xb
  ja jmp_127e8

jmp_11bc0:
  mov64 r1, 0x3
  ja jmp_127e8

jmp_11bd0:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x81c
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0x2c
  call fn_2c060
  stxw [r10-0x820], r6
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jne r1, 0x0, jmp_11e48
  ldxdw r4, [r10-0x408]
  mov64 r1, r10
  add64 r1, -0x4f8
  mov64 r2, r10
  add64 r2, -0x6c8
  mov64 r3, r10
  add64 r3, -0x820
  ldxdw r5, [r10-0x8a8]
  call fn_2a568
  ldxw r1, [r10-0x4f8]
  jne r1, 0x0, jmp_12358
  ldxdw r7, [r10-0x4f0]
  ldxdw r3, [r10-0x6b0]
  ldxdw r2, [r10-0x6b8]
  ldxdw r6, [r10-0x698]
  ldxdw r8, [r10-0x690]
  ldxdw r1, [r10-0x8b8]
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x8b0]
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r7
  stxdw [r10-0x1000], r8
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r5, r10
  mov64 r4, r6
  call fn_27248
  ldxw r1, [r10-0x408]
  jne r1, 0x0, jmp_11df0
  ldxdw r1, [r10-0x3f8]
  stxdw [r10-0x898], r1
  ldxdw r1, [r10-0x400]
  stxdw [r10-0x890], r1
  ldxdw r3, [r10-0x6a0]
  ldxdw r2, [r10-0x6a8]
  ldxdw r4, [r10-0x688]
  ldxdw r5, [r10-0x680]
  ldxdw r1, [r10-0x8b8]
  stxdw [r10-0xfe8], r1
  ldxdw r1, [r10-0x8b0]
  stxdw [r10-0xff0], r1
  stxdw [r10-0xff8], r7
  mov64 r7, r5
  stxdw [r10-0x1000], r5
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r5, r10
  mov64 r9, r4
  call fn_27248
  ldxw r1, [r10-0x408]
  jeq r1, 0x0, jmp_12ee8

jmp_11df0:
  ldxw r1, [r10-0x404]
  ja jmp_10cb8

jmp_11e00:
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jeq r1, 0x0, jmp_12300

jmp_11e48:
  mov64 r0, 0x10
  jne r1, 0x1, jmp_11e60
  mov64 r0, 0x1

jmp_11e60:
  ja jmp_127e8

jmp_11e68:
  stxdw [r10-0x948], r8
  ldxdw r7, [r10-0x6a8]
  jne r5, r7, jmp_127e8
  ldxdw r7, [r10-0x6a0]
  jne r2, r7, jmp_127e8
  ldxdw r7, [r10-0x698]
  jne r4, r7, jmp_127e8
  ldxdw r7, [r10-0x690]
  jne r3, r7, jmp_127e8
  or64 r2, r5
  or64 r2, r4
  or64 r2, r3
  jeq r2, 0x0, jmp_127e8
  ldxdw r1, [r10-0x920]
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  mov64 r1, r0
  jne r1, 0x0, jmp_10f80
  ldxdw r1, [r10-0x3e8]
  ldxdw r2, [r10-0x580]
  jsge r1, r2, jmp_12ed0
  mov64 r1, 0x18
  mov64 r2, r9
  and64 r2, 0x1
  mov64 r0, 0x0
  ldxdw r8, [r10-0x948]
  jeq r2, 0x0, jmp_10070
  ja jmp_127e8

jmp_11f70:
  mov64 r1, 0x0
  ja jmp_127e8

jmp_11f80:
  mov64 r1, 0x1
  stxdw [r10-0x898], r1
  ldxdw r8, [r10-0x548]
  mov64 r2, 0x1
  ldxdw r7, [r10-0x890]
  jsgt r8, 0x0, jmp_121c0
  mov64 r2, 0x0
  mov64 r1, r9
  sub64 r1, r8
  mov64 r3, 0x1
  jsge r1, r9, jmp_121e0

jmp_11fd8:
  xor64 r2, r3
  jne r2, 0x0, jmp_121f8

jmp_11fe8:
  jsgt r9, r8, jmp_11ff8

jmp_11ff0:
  mov64 r1, 0x0

jmp_11ff8:
  ldxdw r3, [r10-0x550]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  ldxdw r4, [r10-0x658]
  mov64 r2, r4
  add64 r2, r0
  mov64 r3, 0x1
  jlt r2, r4, jmp_12048
  mov64 r3, 0x0

jmp_12048:
  ldxdw r5, [r10-0x650]
  mov64 r4, r5
  add64 r4, r1
  add64 r4, r3
  ldxdw r1, [r10-0x888]
  jlt r4, r5, jmp_12228
  mov64 r0, 0x0
  stxdw [r10-0x898], r0
  jne r4, r5, jmp_12230

jmp_12090:
  mov64 r0, -0x1
  mov64 r5, -0x1
  jne r3, 0x0, jmp_12250

jmp_120a8:
  mov64 r5, r4
  jeq r3, 0x0, jmp_12258

jmp_120b8:
  jsgt r9, r8, jmp_120c8

jmp_120c0:
  mov64 r9, r8

jmp_120c8:
  stxdw [r10-0x548], r9
  stxdw [r10-0x658], r0
  stxdw [r10-0x650], r5
  mov64 r2, r7
  and64 r2, 0x1
  jeq r2, 0x0, jmp_12190
  jne r6, 0x0, jmp_12190
  ldxdw r1, [r10-0x508]
  add64 r1, 0x1
  mov64 r2, 0x1
  jeq r1, 0x0, jmp_12128
  mov64 r2, 0x0

jmp_12128:
  mov64 r3, -0x1
  jne r2, 0x0, jmp_12140
  mov64 r3, r1

jmp_12140:
  stxdw [r10-0x508], r3
  stdw [r10-0x650], 0x0
  stdw [r10-0x658], 0x0
  stdw [r10-0x6a8], 0x0
  stdw [r10-0x6a0], 0x0
  stdw [r10-0x698], 0x0
  stdw [r10-0x690], 0x0
  stdw [r10-0x580], 0x0
  ldxdw r1, [r10-0x888]
  ldxdw r7, [r10-0x890]

jmp_12190:
  stxb [r10-0x4ff], r7

jmp_12198:
  ldxdw r1, [r1+0x10]

jmp_121a0:
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_2458
  ja jmp_127e8

jmp_121c0:
  mov64 r1, r9
  sub64 r1, r8
  mov64 r3, 0x1
  jslt r1, r9, jmp_11fd8

jmp_121e0:
  mov64 r3, 0x0
  xor64 r2, r3
  jeq r2, 0x0, jmp_11fe8

jmp_121f8:
  arsh64 r1, 0x3f
  lddw r2, -0x8000000000000000
  xor64 r1, r2
  jsle r9, r8, jmp_11ff0
  ja jmp_11ff8

jmp_12228:
  jeq r4, r5, jmp_12090

jmp_12230:
  ldxdw r3, [r10-0x898]
  mov64 r0, -0x1
  mov64 r5, -0x1
  jeq r3, 0x0, jmp_120a8

jmp_12250:
  jne r3, 0x0, jmp_120b8

jmp_12258:
  mov64 r0, r2
  jsle r9, r8, jmp_120c0
  ja jmp_120c8

jmp_12270:
  mov64 r1, 0x5
  ja jmp_127e8

jmp_12280:
  mov64 r8, r5
  mov64 r7, r2

jmp_12290:
  ldxdw r1, [r10-0x8b0]
  stxdw [r10-0x7c8], r1
  stxdw [r10-0x7f8], r8
  stxdw [r10-0x7b8], r7
  ja jmp_12390

jmp_122b8:
  mov64 r0, 0x0
  mov64 r1, 0xf
  ja jmp_127e8

jmp_122d0:
  stb [r2+0x0], 0xff

jmp_122d8:
  mov64 r0, 0x0
  ja jmp_127e8

jmp_122e8:
  mov64 r1, r0
  rsh64 r1, 0x20
  ja jmp_127e8

jmp_12300:
  ldxdw r4, [r10-0x408]
  mov64 r1, r10
  add64 r1, -0x4f8
  mov64 r2, r10
  add64 r2, -0x6c8
  mov64 r3, r10
  add64 r3, -0x820
  ldxdw r5, [r10-0x8a0]
  call fn_2a568
  ldxw r1, [r10-0x4f8]
  jeq r1, 0x0, jmp_12438

jmp_12358:
  ldxw r1, [r10-0x4f4]
  ja jmp_10cb8

jmp_12368:
  ldxdw r1, [r10-0x8b0]
  stxdw [r10-0x7c8], r1
  stxdw [r10-0x7f8], r8
  ldxdw r2, [r10-0x8a8]
  stxdw [r10-0x7b8], r2

jmp_12390:
  ldxdw r2, [r10-0x8d8]
  stxdw [r10-0x7d0], r2
  jne r1, 0x0, jmp_10e58
  ja jmp_10e50

jmp_123b0:
  mov64 r1, 0x11
  ldxdw r2, [r10-0x3e8]
  ldxdw r4, [r10-0x580]
  ldxdw r3, [r10-0x888]
  mov64 r0, 0x0
  jslt r2, r4, jmp_e470
  ja jmp_127e8

jmp_123e8:
  ldxdw r3, [r10-0x890]
  add64 r3, -0x9
  jne r4, 0x0, jmp_126c8
  jne r5, 0x0, jmp_126c8
  jne r0, 0x0, jmp_126c8
  jne r7, 0x0, jmp_126c8
  mov64 r0, 0x0
  mov64 r1, 0x2
  jne r3, 0x0, jmp_127e8
  ja jmp_13100

jmp_12438:
  stxdw [r10-0x6c0], r6
  stxdw [r10-0x6c8], r7
  stb [r10-0x610], 0x1
  ja jmp_f440

jmp_12458:
  ldxdw r3, [r10-0x408]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_14c78
  ldxdw r6, [r8+0x8]
  mul64 r3, 0x1db
  ldxdw r1, [r6+0x48]
  jle r3, r1, jmp_126a8
  sub64 r3, r1
  ldxdw r2, [r8+0x0]
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x4e8], r1
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x4f8], r4
  sth [r10-0x4e0], 0x1
  sth [r10-0x4f0], 0x101
  stxdw [r10-0x5c], r3
  stw [r10-0x60], 0x2
  ldxb r3, [r6+0x0]
  ldxb r5, [r2+0x0]
  and64 r3, r5
  jne r3, 0xff, jmp_126b8
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x408], r4
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x400], r4
  ldxdw r4, [r2+0x50]
  mov64 r5, r2
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r4
  stdw [r10-0x3e0], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x3c8], r3
  stxdw [r10-0x3d0], r1
  stxw [r10-0x3d8], r2
  ldxdw r1, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x28
  stxdw [r10-0x3b0], r2
  mov64 r2, r6
  add64 r2, 0x58
  stxdw [r10-0x3b8], r2
  stxdw [r10-0x3c0], r1
  stdw [r10-0x3a8], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x3a0], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x818], r1
  lddw r1, data_0301
  stxdw [r10-0x820], r1
  stdw [r10-0x800], 0xc
  stdw [r10-0x810], 0x2
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r6, [r8+0x8]

jmp_126a8:
  ldxb r1, [r6+0x0]
  jeq r1, 0xff, jmp_13008

jmp_126b8:
  mov64 r0, 0xb

jmp_126c0:
  ja jmp_127e8

jmp_126c8:
  jne r3, 0x1, jmp_107c8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x48]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x404]
  ldxw r2, [r10-0x408]
  ldxb r3, [r10-0x23f]
  jne r3, 0x2, jmp_13078

jmp_12720:
  mov64 r0, r2
  ja jmp_127e8

jmp_12730:
  jeq r1, r6, jmp_afb8

jmp_12738:
  mov64 r5, r0
  mov64 r1, 0x4
  and64 r5, 0x1
  mov64 r0, 0x0
  jne r5, 0x0, jmp_127e8

jmp_12760:
  mov64 r1, 0x1
  jlt r2, r3, jmp_12778
  mov64 r1, 0x0

jmp_12778:
  stxdw [r10-0x6b8], r2
  add64 r4, r1
  stxdw [r10-0x6b0], r4
  stdw [r10-0x638], 0x0

jmp_12798:
  ldxdw r1, [r7+0x18]
  ja jmp_113b0

jmp_127a8:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2

jmp_127d8:
  mov64 r0, 0x0

jmp_127e0:
  mov64 r1, 0x2

jmp_127e8:
  exit

jmp_127f0:
  mov64 r1, 0x1
  stxdw [r10-0x8d0], r1
  ldxdw r9, [r10-0x548]
  mov64 r2, 0x1
  jsgt r9, 0x0, jmp_129a8
  mov64 r2, 0x0
  mov64 r1, r7
  sub64 r1, r9
  mov64 r3, 0x1
  jsge r1, r7, jmp_129c8

jmp_12840:
  xor64 r2, r3
  jne r2, 0x0, jmp_129e0

jmp_12850:
  jsgt r7, r9, jmp_12860

jmp_12858:
  mov64 r1, 0x0

jmp_12860:
  ldxdw r3, [r10-0x550]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  ldxdw r4, [r10-0x658]
  mov64 r2, r4
  add64 r2, r0
  mov64 r3, 0x1
  jlt r2, r4, jmp_128b0
  mov64 r3, 0x0

jmp_128b0:
  ldxdw r4, [r10-0x650]
  mov64 r5, r4
  add64 r5, r1
  add64 r5, r3
  jlt r5, r4, jmp_12a10
  mov64 r1, 0x0
  stxdw [r10-0x8d0], r1
  jne r5, r4, jmp_12a18

jmp_128f0:
  mov64 r4, -0x1
  mov64 r1, -0x1
  jne r3, 0x0, jmp_12a38

jmp_12908:
  mov64 r1, r5
  jeq r3, 0x0, jmp_12a40

jmp_12918:
  stxdw [r10-0x658], r4
  stxdw [r10-0x650], r1
  jsgt r7, r9, jmp_12938

jmp_12930:
  mov64 r7, r9

jmp_12938:
  stxdw [r10-0x548], r7
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x18]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_12a68

jmp_12980:
  ldxw r1, [r10-0x400]
  stxdw [r10-0x8d0], r1
  ldxw r1, [r10-0x404]

jmp_12998:
  stxdw [r10-0x8f0], r1
  ja jmp_13720

jmp_129a8:
  mov64 r1, r7
  sub64 r1, r9
  mov64 r3, 0x1
  jslt r1, r7, jmp_12840

jmp_129c8:
  mov64 r3, 0x0
  xor64 r2, r3
  jeq r2, 0x0, jmp_12850

jmp_129e0:
  arsh64 r1, 0x3f
  lddw r2, -0x8000000000000000
  xor64 r1, r2
  jsle r7, r9, jmp_12858
  ja jmp_12860

jmp_12a10:
  jeq r5, r4, jmp_128f0

jmp_12a18:
  ldxdw r3, [r10-0x8d0]
  mov64 r4, -0x1
  mov64 r1, -0x1
  jeq r3, 0x0, jmp_12908

jmp_12a38:
  jne r3, 0x0, jmp_12918

jmp_12a40:
  mov64 r4, r2
  stxdw [r10-0x658], r4
  stxdw [r10-0x650], r1
  jsle r7, r9, jmp_12930
  ja jmp_12938

jmp_12a68:
  ldxw r7, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x4f4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x4f8], r7
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x28]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17990
  ldxw r1, [r10-0x404]
  stxdw [r10-0x8d0], r1
  ldxw r1, [r10-0x408]
  stxdw [r10-0x8f0], r1
  ldxb r9, [r10-0x350]
  jeq r9, 0x2, jmp_13720
  mov64 r1, r10
  add64 r1, -0x818
  mov64 r2, r10
  add64 r2, -0x400
  mov64 r3, 0xb0
  call fn_2c060
  ldxw r1, [r10-0x34f]
  stxw [r10-0x767], r1
  ldxw r1, [r10-0x34c]
  stxw [r10-0x764], r1
  stxb [r10-0x768], r9
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x81c], r1
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x820], r1
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r10-0x898]
  ldxh r2, [r10-0x770]
  jne r2, r1, jmp_13580
  ldxdw r1, [r10-0x8a0]
  jne r1, 0x1, jmp_13710
  ldxdw r1, [r10-0x8a8]
  ldxh r2, [r10-0x76c]
  jne r2, r1, jmp_13580
  ldxh r1, [r10-0x76a]
  ldxdw r2, [r10-0x8b0]
  mov64 r7, r2
  jne r1, r2, jmp_13580
  ldxdw r1, [r10-0x8f8]
  mov64 r2, r1
  ldxdw r1, [r10-0x910]
  jne r1, r2, jmp_13580
  jgt r1, 0xf4240, jmp_13580
  ldxdw r1, [r10-0x8b8]
  jgt r1, 0x3e8, jmp_13580
  ldxdw r2, [r10-0x930]
  jgt r2, r1, jmp_13580
  ldxdw r1, [r10-0x918]
  and64 r1, 0x1
  jne r1, 0x0, jmp_144f8
  and64 r9, 0x1
  jne r9, 0x0, jmp_144f8
  mov64 r1, 0x9
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x8c0]
  add64 r1, -0x1
  and64 r1, 0xffff
  jgt r1, 0x3e7, jmp_13720
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r10-0x900]
  mov64 r2, 0x0
  ldxdw r3, [r10-0x8c0]
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x8a0], r0
  mov64 r2, 0x1
  jne r1, 0x0, jmp_12ce8
  mov64 r2, 0x0

jmp_12ce8:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_146e0

jmp_12cf8:
  mov64 r1, 0x4
  ja jmp_13718

jmp_12d08:
  ldxdw r1, [r10-0x3e8]
  mov64 r2, r1
  add64 r2, 0x278d00
  mov64 r3, 0x1
  jslt r2, r1, jmp_12d38
  mov64 r3, 0x0

jmp_12d38:
  mov64 r1, 0x4
  and64 r3, 0x1
  mov64 r0, 0x0
  jne r3, 0x0, jmp_127e8
  stxdw [r10-0x580], r2
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x18]
  ja jmp_121a0

jmp_12d78:
  lddw r2, 0x7fffffffffffffff
  jne r5, 0x0, jmp_11500

jmp_12d90:
  mov64 r2, r4
  mov64 r4, r3
  add64 r4, -0x1
  jsge r4, r3, jmp_11518

jmp_12db0:
  xor64 r1, 0x1
  lddw r3, -0x8000000000000000
  jne r1, 0x0, jmp_11540

jmp_12dd0:
  mov64 r3, r4
  ldxdw r1, [r10-0x6b8]
  ldxdw r4, [r10-0x898]
  jslt r4, r1, jmp_12ff0

jmp_12df0:
  ldxdw r1, [r10-0x898]
  jslt r1, r3, jmp_12ff0
  mov64 r0, 0x0
  mov64 r1, 0x15
  ldxdw r3, [r10-0x898]
  jsgt r3, r2, jmp_127e8
  ldxdw r1, [r10-0x890]
  stxdw [r10-0x6b0], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x6b8], r1
  ldxdw r1, [r10-0x888]
  stxdw [r10-0x6c0], r1
  stxdw [r10-0x6c8], r8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r1, [r10-0x408]
  stxdw [r10-0x6a8], r1
  ldxdw r1, [r7+0x10]

jmp_12eb0:
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_2718
  ja jmp_127e8

jmp_12ed0:
  mov64 r1, 0x11
  mov64 r0, 0x0
  ja jmp_127e8

jmp_12ee8:
  ldxdw r1, [r10-0x3f8]
  ldxdw r2, [r10-0x400]
  ldxdw r3, [r10-0x890]
  xor64 r3, r6
  ldxdw r4, [r10-0x898]
  xor64 r4, r8
  or64 r3, r4
  jne r3, 0x0, jmp_12f58
  mov64 r3, r2
  xor64 r3, r9
  mov64 r4, r1
  xor64 r4, r7
  or64 r3, r4
  jeq r3, 0x0, jmp_12fd0

jmp_12f58:
  stxdw [r10-0x688], r2
  ldxdw r2, [r10-0x890]
  stxdw [r10-0x698], r2
  stxdw [r10-0x680], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x690], r1
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x10]
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_3370
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8

jmp_12fd0:
  mov64 r0, 0x1a
  ja jmp_127e8

jmp_12fe0:
  mov64 r1, 0x4
  ja jmp_127e8

jmp_12ff0:
  mov64 r0, 0x0
  mov64 r1, 0x15
  ja jmp_127e8

jmp_13008:
  ldxdw r2, [r6+0x50]
  jeq r2, 0x15b, jmp_13068
  jge r2, 0x15b, jmp_13058
  mov64 r3, 0x15b
  sub64 r3, r2
  mov64 r1, r6
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_2c080

jmp_13058:
  stdw [r6+0x50], 0x15b
  ldxdw r6, [r8+0x8]

jmp_13068:
  ldxdw r5, [r10-0x888]
  ja jmp_10cf8

jmp_13078:
  lsh64 r1, 0x20
  or64 r1, r2
  ldxdw r2, [r10-0x8b0]
  jne r1, r2, jmp_107c8
  ldxdw r1, [r10-0x400]
  ldxdw r2, [r10-0x898]
  jne r1, r2, jmp_107c8
  ldxdw r1, [r10-0x3f8]
  ldxdw r2, [r10-0x8a0]
  jne r1, r2, jmp_107c8
  ldxdw r2, [r10-0x3f0]
  mov64 r0, 0x0
  mov64 r1, 0x2
  ldxdw r3, [r10-0x8a8]
  jne r2, r3, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]

jmp_13100:
  mov64 r1, r10
  add64 r1, -0x880
  stxdw [r10-0x3f8], r1
  lddw r1, str_0399
  stxdw [r10-0x408], r1
  stdw [r10-0x3f0], 0x10
  stdw [r10-0x400], 0xd
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x40]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0x28
  mov64 r3, r10
  add64 r3, -0x408
  mov64 r5, r10
  mov64 r4, 0x2
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x40]
  mov64 r2, r10
  add64 r2, -0x870
  call fn_2528
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x870
  stxdw [r10-0x3f8], r1
  lddw r1, str_0367
  stxdw [r10-0x408], r1
  stdw [r10-0x3f0], 0x20
  stdw [r10-0x400], 0x6
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r1+0x18]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0x1d2
  mov64 r3, r10
  add64 r3, -0x408
  mov64 r5, r10
  mov64 r4, 0x2
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  ldxdw r4, [r1+0x10]
  ldxdw r3, [r1+0x30]
  ldxdw r1, [r1+0x38]
  mov64 r5, r10
  add64 r5, -0x6c8
  stxdw [r10-0xff0], r5
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r3
  mov64 r3, r10
  add64 r3, -0x870
  mov64 r5, r10
  mov64 r1, r6
  call fn_6c00
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_127e8
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, 0x0
  mov64 r3, 0x60
  call fn_2c080
  ldxdw r1, [r10-0x870]
  stxdw [r10-0x408], r1
  ldxdw r1, [r10-0x868]
  stxdw [r10-0x400], r1
  ldxdw r1, [r10-0x860]
  stxdw [r10-0x3f8], r1
  ldxdw r1, [r10-0x858]
  stxdw [r10-0x3f0], r1
  ldxdw r1, [r10-0x800]
  stxdw [r10-0x3e8], r1
  ldxdw r1, [r10-0x7f8]
  stxdw [r10-0x3e0], r1
  ldxdw r1, [r10-0x7f0]
  stxdw [r10-0x3d8], r1
  ldxdw r1, [r10-0x7e8]
  stxdw [r10-0x3d0], r1
  stdw [r10-0x2d8], 0x0
  stdw [r10-0x2d0], 0x0
  stdw [r10-0x2c8], 0x0
  mov64 r1, r10
  add64 r1, -0x3a8
  mov64 r2, 0x0
  mov64 r3, 0x90
  call fn_2c080
  mov64 r1, r10
  add64 r1, -0x2c0
  mov64 r2, 0x0
  mov64 r3, 0x82
  call fn_2c080
  ldxdw r1, [r10-0x8a8]
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r10-0x8a0]
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x3c0], r1
  ldxdw r1, [r10-0x8b0]
  stxdw [r10-0x3c8], r1
  ldxdw r1, [r10-0x880]
  stxdw [r10-0x318], r1
  ldxdw r1, [r10-0x878]
  stxdw [r10-0x310], r1
  stdw [r10-0x308], 0x0
  stdw [r10-0x300], 0x0
  stdw [r10-0x2f8], 0x0
  stdw [r10-0x2f0], 0x0
  stdw [r10-0x2e8], 0x0
  stdw [r10-0x2e0], 0x0
  mov64 r2, r10
  add64 r2, -0x820
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r1, [r10-0x800]
  stxdw [r10-0x280], r1
  stxdw [r10-0x288], r1
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x18]
  mov64 r2, r10
  add64 r2, -0x408
  call fn_2458
  ja jmp_127e8

jmp_13570:
  mov64 r1, 0xf
  ja jmp_127e8

jmp_13580:
  mov64 r1, 0x8
  ja jmp_13718

jmp_13590:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x6c4
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x6c8], r6
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r7+0x10]
  ldxb r2, [r1+0x2]
  jeq r2, 0x0, jmp_13700
  ldxdw r2, [r10-0x888]
  jeq r2, 0x0, jmp_14560
  ldxdw r1, [r1+0x50]
  jne r1, 0xac, jmp_14560
  ldxdw r1, [r7+0x0]
  ldxb r1, [r1+0x2]
  jeq r1, 0x0, jmp_13700
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r6, 0x0
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  jeq r0, 0x0, jmp_14268
  mov64 r1, 0x10
  stxdw [r10-0x8f0], r1
  jne r0, 0x1, jmp_144d8
  mov64 r1, 0x1
  ja jmp_144d0

jmp_136a0:
  mov64 r0, r2
  ja jmp_127e8

jmp_136b0:
  mov64 r1, 0x10
  ja jmp_127e8

jmp_136c0:
  stdw [r1+0x50], 0x0
  stdw [r1+0x48], 0x0
  stdw [r1+0x40], 0x0
  stdw [r1+0x38], 0x0
  stdw [r1+0x30], 0x0
  stdw [r1+0x28], 0x0
  mov64 r0, 0x1a
  ja jmp_127e8

jmp_13700:
  mov64 r6, 0x2
  ja jmp_145a8

jmp_13710:
  mov64 r1, 0x13

jmp_13718:
  stxdw [r10-0x8d0], r1

jmp_13720:
  ldxdw r0, [r10-0x8f0]
  ldxdw r1, [r10-0x8d0]
  ja jmp_127e8

jmp_13738:
  mov64 r1, 0x7
  ja jmp_127e8

jmp_13748:
  ldxdw r1, [r10-0x4f0]
  ldxdw r2, [r10-0x898]
  jge r1, r2, jmp_13778
  mov64 r0, 0x0
  mov64 r1, 0xb
  ja jmp_127e8

jmp_13778:
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x28]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r4, r10
  add64 r4, -0x6c8
  mov64 r3, r7
  call fn_1b550
  ldxw r1, [r10-0x408]
  jne r1, 0x0, jmp_cf00
  ldxdw r1, [r10-0x888]
  ldxdw r4, [r1+0x28]
  ldxdw r3, [r1+0x20]
  ldxdw r2, [r1+0x8]
  mov64 r1, r6
  call fn_1b770
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_12720
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x8]
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_12720
  stxb [r10-0xb9], r1
  mov64 r1, r10
  add64 r1, -0xb9
  stxdw [r10-0xa8], r1
  lddw r1, str_0361
  stxdw [r10-0xb8], r1
  stdw [r10-0xa0], 0x1
  stdw [r10-0xb0], 0x6
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x850], r1
  stdw [r10-0x848], 0x2
  ldxdw r1, [r10-0x888]
  ldxdw r0, [r1+0x18]
  mov64 r3, r0
  add64 r3, 0x8
  stxdw [r10-0x4f8], r3
  sth [r10-0x4f0], 0x1
  ldxdw r4, [r1+0x20]
  mov64 r7, r4
  add64 r7, 0x8
  stxdw [r10-0x4e8], r7
  sth [r10-0x4e0], 0x0
  ldxdw r2, [r1+0x28]
  mov64 r5, r2
  add64 r5, 0x8
  stxdw [r10-0x4d8], r5
  sth [r10-0x4d0], 0x1
  ldxdw r1, [r1+0x8]
  mov64 r8, r1
  add64 r8, 0x8
  stxdw [r10-0x8a0], r8
  stxdw [r10-0x4c8], r8
  sth [r10-0x4c0], 0x100
  ldxb r8, [r0+0x0]
  ldxb r9, [r2+0x0]
  and64 r9, r8
  jne r9, 0xff, jmp_15dd8
  stxdw [r10-0x408], r3
  mov64 r3, r0
  add64 r3, 0x48
  stxdw [r10-0x400], r3
  ldxdw r3, [r0+0x50]
  mov64 r8, r0
  add64 r8, 0x28
  stxdw [r10-0x3e8], r8
  mov64 r8, r0
  add64 r8, 0x58
  stxdw [r10-0x3f0], r8
  stxdw [r10-0x3f8], r3
  stdw [r10-0x3e0], 0x0
  ldxw r3, [r0+0x1]
  mov64 r0, r4
  add64 r0, 0x48
  stxdw [r10-0x3c8], r0
  stxdw [r10-0x3d0], r7
  stxw [r10-0x3d8], r3
  ldxdw r3, [r4+0x50]
  mov64 r0, r4
  add64 r0, 0x28
  stxdw [r10-0x3b0], r0
  mov64 r0, r4
  add64 r0, 0x58
  stxdw [r10-0x3b8], r0
  stxdw [r10-0x3c0], r3
  stdw [r10-0x3a8], 0x0
  ldxw r3, [r4+0x1]
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x390], r4
  stxdw [r10-0x398], r5
  stxw [r10-0x3a0], r3
  mov64 r3, r2
  add64 r3, 0x28
  ldxdw r4, [r2+0x50]
  stxdw [r10-0x378], r3
  mov64 r3, r2
  add64 r3, 0x58
  stxdw [r10-0x380], r3
  stxdw [r10-0x388], r4
  stdw [r10-0x370], 0x0
  ldxw r2, [r2+0x1]
  mov64 r3, r1
  add64 r3, 0x48
  stxdw [r10-0x358], r3
  ldxdw r3, [r10-0x8a0]
  stxdw [r10-0x360], r3
  stxw [r10-0x368], r2
  mov64 r2, r1
  add64 r2, 0x28
  ldxdw r3, [r1+0x50]
  stxdw [r10-0x340], r2
  mov64 r2, r1
  add64 r2, 0x58
  stxdw [r10-0x348], r2
  stxdw [r10-0x350], r3
  stdw [r10-0x338], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x330], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x6f], r1
  stb [r10-0x67], 0x6
  stb [r10-0x70], 0xc
  mov64 r1, r10
  add64 r1, -0x70
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x58], r1
  lddw r1, data_02c1
  stxdw [r10-0x60], r1
  stdw [r10-0x40], 0xa
  stdw [r10-0x50], 0x4
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r4, r10
  add64 r4, -0x850
  mov64 r3, 0x4
  mov64 r5, 0x1
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x890]
  and64 r1, 0x1
  jne r1, 0x0, jmp_13ce0
  ldxdw r1, [r10-0x888]
  ldxdw r4, [r1+0x28]
  ldxdw r3, [r1+0x20]
  ldxdw r2, [r1+0x8]
  mov64 r1, r6
  call fn_1bc30
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_12720

jmp_13ce0:
  stdw [r10-0x570], 0x0
  ldxdw r1, [r10-0x888]
  ja jmp_12198

jmp_13cf8:
  ldxdw r3, [r10-0x408]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_156c8
  ldxdw r6, [r8+0x8]
  mul64 r3, 0x1da
  ldxdw r1, [r6+0x48]
  jle r3, r1, jmp_13f48
  sub64 r3, r1
  ldxdw r2, [r8+0x0]
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x4e8], r1
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x4f8], r4
  sth [r10-0x4e0], 0x1
  sth [r10-0x4f0], 0x101
  stxdw [r10-0x5c], r3
  stw [r10-0x60], 0x2
  ldxb r3, [r6+0x0]
  ldxb r5, [r2+0x0]
  and64 r3, r5
  jne r3, 0xff, jmp_11bb0
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x408], r4
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x400], r4
  ldxdw r4, [r2+0x50]
  mov64 r5, r2
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r4
  stdw [r10-0x3e0], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x3c8], r3
  stxdw [r10-0x3d0], r1
  stxw [r10-0x3d8], r2
  ldxdw r1, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x28
  stxdw [r10-0x3b0], r2
  mov64 r2, r6
  add64 r2, 0x58
  stxdw [r10-0x3b8], r2
  stxdw [r10-0x3c0], r1
  stdw [r10-0x3a8], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x3a0], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x818], r1
  lddw r1, data_0301
  stxdw [r10-0x820], r1
  stdw [r10-0x800], 0xc
  stdw [r10-0x810], 0x2
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r6, [r8+0x8]

jmp_13f48:
  ldxb r1, [r6+0x0]
  jne r1, 0xff, jmp_11bb0
  ldxdw r2, [r6+0x50]
  jeq r2, 0x15a, jmp_13fb8
  jge r2, 0x15a, jmp_13fa8
  mov64 r3, 0x15a
  sub64 r3, r2
  mov64 r1, r6
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_2c080

jmp_13fa8:
  stdw [r6+0x50], 0x15a
  ldxdw r6, [r8+0x8]

jmp_13fb8:
  ldxdw r1, [r10-0x888]
  stxw [r10-0x57c], r1
  mov64 r2, r10
  add64 r2, -0x6c8
  mov64 r1, r6
  call fn_2b08
  ja jmp_127e8

jmp_13ff0:
  ldxdw r8, [r10-0x8f0]
  rsh64 r8, 0x20

jmp_14000:
  ldxdw r0, [r10-0x8f0]
  mov64 r1, r8
  ja jmp_127e8

jmp_14018:
  ldxdw r1, [r10-0x8a0]
  ldxb r1, [r1+0x3]
  jeq r1, 0x0, jmp_c170
  mov64 r1, r7
  add64 r1, 0x38
  stxdw [r10-0x8b8], r1
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x8b0], r1
  lddw r2, data_02c1
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_14c68
  mov64 r1, r7
  add64 r1, 0x30
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x8c0], r1
  ldxdw r1, [r1+0x8]
  lddw r2, 0x66d17b1817d5a706
  jne r1, r2, jmp_c170
  ldxdw r1, [r10-0x8c0]
  ldxdw r1, [r1+0x10]
  lddw r2, -0x3f3d02aafb2b25cb
  jne r1, r2, jmp_c170
  ldxdw r1, [r10-0x8c0]
  ldxdw r1, [r1+0x18]
  lddw r2, -0x5a8aa9de7039db3f
  jne r1, r2, jmp_c170
  ldxdw r1, [r10-0x8c0]
  ldxdw r1, [r1+0x20]
  lddw r2, 0x85fcbbadb
  jne r1, r2, jmp_c170
  mov64 r2, r7
  add64 r2, 0x18
  add64 r9, 0x8
  stxdw [r10-0x3e8], r9
  lddw r1, str_037e
  stxdw [r10-0x408], r1
  lddw r1, data_0321
  stxdw [r10-0x3f8], r1
  stdw [r10-0x3e0], 0x20
  stdw [r10-0x3f0], 0x20
  stdw [r10-0x400], 0x8
  stxdw [r10-0x8e0], r2
  ldxdw r1, [r2+0x0]
  mov64 r2, r10
  add64 r2, -0x408
  stxdw [r10-0x8d8], r1
  mov64 r3, 0x3
  lddw r4, data_0321
  call fn_05d0
  mov64 r1, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_14250
  ldxdw r1, [r10-0x8d8]
  ldxdw r1, [r1+0x50]
  jeq r1, 0x0, jmp_151d0
  mov64 r1, 0x12
  mov64 r0, 0x0
  ja jmp_127e8

jmp_14250:
  mov64 r0, r1
  rsh64 r1, 0x20
  ja jmp_127e8

jmp_14268:
  ldxdw r3, [r10-0x408]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_15be0
  ldxdw r6, [r7+0x10]
  mul64 r3, 0x132
  ldxdw r1, [r6+0x48]
  jle r3, r1, jmp_144b8
  sub64 r3, r1
  ldxdw r2, [r7+0x0]
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x4e8], r1
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x4f8], r4
  sth [r10-0x4e0], 0x1
  sth [r10-0x4f0], 0x101
  stxdw [r10-0x5c], r3
  stw [r10-0x60], 0x2
  ldxb r3, [r6+0x0]
  ldxb r5, [r2+0x0]
  and64 r3, r5
  jne r3, 0xff, jmp_144c8
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x408], r4
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x400], r4
  ldxdw r4, [r2+0x50]
  mov64 r5, r2
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r4
  stdw [r10-0x3e0], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x3c8], r3
  stxdw [r10-0x3d0], r1
  stxw [r10-0x3d8], r2
  ldxdw r1, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x28
  stxdw [r10-0x3b0], r2
  mov64 r2, r6
  add64 r2, 0x58
  stxdw [r10-0x3b8], r2
  stxdw [r10-0x3c0], r1
  stdw [r10-0x3a8], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x3a0], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x818], r1
  lddw r1, data_0301
  stxdw [r10-0x820], r1
  stdw [r10-0x800], 0xc
  stdw [r10-0x810], 0x2
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r6, [r7+0x10]

jmp_144b8:
  ldxb r1, [r6+0x0]
  jeq r1, 0xff, jmp_14508

jmp_144c8:
  mov64 r1, 0xb

jmp_144d0:
  stxdw [r10-0x8f0], r1

jmp_144d8:
  ja jmp_145a8

jmp_144e0:
  mov64 r0, r1
  rsh64 r1, 0x20
  ja jmp_127e8

jmp_144f8:
  mov64 r1, 0x7
  ja jmp_13718

jmp_14508:
  ldxdw r2, [r6+0x50]
  jeq r2, 0xb2, jmp_14560
  jge r2, 0xb2, jmp_14558
  mov64 r3, 0xb2
  sub64 r3, r2
  mov64 r1, r6
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_2c080

jmp_14558:
  stdw [r6+0x50], 0xb2

jmp_14560:
  stxw [r10-0x624], r9
  stxh [r10-0x620], r8
  mov64 r1, r10
  add64 r1, -0x6c8
  call fn_2a1d0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r6, r0
  jeq r0, 0x0, jmp_113a8

jmp_145a8:
  ldxdw r0, [r10-0x8f0]
  mov64 r1, r6
  ja jmp_127e8

jmp_145c0:
  mov64 r1, 0x8
  stxdw [r10-0x8d0], r1
  ja jmp_13720

jmp_145d8:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x5c
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0x2c
  call fn_2c060
  stxw [r10-0x60], r6
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r4, [r10-0x408]
  mov64 r1, r10
  add64 r1, -0xb8
  mov64 r2, r10
  add64 r2, -0x820
  mov64 r3, r10
  add64 r3, -0x60
  ldxdw r5, [r10-0x8a0]
  call fn_2a568
  ldxw r1, [r10-0xb8]
  jeq r1, 0x0, jmp_14898
  ldxw r1, [r10-0xb4]
  mov64 r0, 0x0
  ja jmp_127e8

jmp_146c8:
  mov64 r1, 0x12
  stxdw [r10-0x8d0], r1
  ja jmp_13720

jmp_146e0:
  ldxdw r1, [r10-0x900]
  jeq r1, 0x0, jmp_16188
  ldxdw r1, [r10-0x788]
  ldxdw r2, [r10-0x900]
  jlt r2, r1, jmp_16188
  ldxdw r1, [r10-0x780]
  ldxdw r2, [r10-0x8a0]
  jlt r2, r1, jmp_16188
  mov64 r1, 0xa
  stxdw [r10-0x8d0], r1
  lddw r1, 0x9184e72a000
  ldxdw r2, [r10-0x8a0]
  jgt r2, r1, jmp_13720
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0x408
  ldxdw r3, [r10-0x898]
  mov64 r4, r6
  call fn_17bf8
  ldxw r1, [r10-0x408]
  jeq r1, 0x1, jmp_12980
  ldxw r9, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x84c
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0x2c
  call fn_2c060
  stxw [r10-0x850], r9
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_c598
  ldxdw r9, [r10-0x408]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x820
  mov64 r3, r10
  add64 r3, -0x850
  mov64 r4, r9
  ldxdw r5, [r10-0x938]
  call fn_2a568
  ldxw r1, [r10-0x408]
  jeq r1, 0x0, jmp_155a0

jmp_14888:
  ldxw r1, [r10-0x404]
  ja jmp_13718

jmp_14898:
  ldxdw r5, [r10-0xb0]

jmp_148a0:
  mov64 r1, r10
  add64 r1, -0x4f8
  ldxdw r2, [r10-0x890]
  ldxdw r3, [r10-0x8a8]
  ldxdw r4, [r10-0x8b0]
  call fn_2a838
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jeq r0, 0x0, jmp_14900
  mov64 r1, r0
  mov64 r0, 0x0
  ja jmp_127e8

jmp_14900:
  ldxdw r1, [r10-0x888]
  ldxdw r6, [r1+0x28]
  ldxb r1, [r6+0x2]
  jeq r1, 0x0, jmp_107c8
  ldxdw r1, [r6+0x50]
  jne r1, 0xaf, jmp_14cf8
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x30]
  lddw r2, data_0301
  call fn_5b70
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_14c68
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x0]
  ldxb r2, [r1+0x2]
  mov64 r0, 0x0
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_127e8
  mov64 r2, r10
  add64 r2, -0x408
  lddw r1, data_02e1
  mov64 r3, 0x0
  mov64 r4, 0x8
  call sol_get_sysvar
  jne r0, 0x0, jmp_11988
  ldxdw r3, [r10-0x408]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_14c78
  ldxdw r1, [r10-0x888]
  ldxdw r6, [r1+0x28]
  mul64 r3, 0x147
  ldxdw r1, [r6+0x48]
  jle r3, r1, jmp_14c48
  sub64 r3, r1
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x0]
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x50], r1
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x60], r4
  sth [r10-0x48], 0x1
  sth [r10-0x58], 0x101
  stxdw [r10-0xb4], r3
  stw [r10-0xb8], 0x2
  ldxb r3, [r6+0x0]
  ldxb r5, [r2+0x0]
  and64 r3, r5
  jne r3, 0xff, jmp_14c58
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x408], r4
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x400], r4
  ldxdw r4, [r2+0x50]
  mov64 r5, r2
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r4
  stdw [r10-0x3e0], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x3c8], r3
  stxdw [r10-0x3d0], r1
  stxw [r10-0x3d8], r2
  ldxdw r1, [r6+0x50]
  mov64 r2, r6
  add64 r2, 0x28
  stxdw [r10-0x3b0], r2
  mov64 r2, r6
  add64 r2, 0x58
  stxdw [r10-0x3b8], r2
  stxdw [r10-0x3c0], r1
  stdw [r10-0x3a8], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x3a0], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x818], r1
  lddw r1, data_0301
  stxdw [r10-0x820], r1
  stdw [r10-0x800], 0xc
  stdw [r10-0x810], 0x2
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x888]
  ldxdw r6, [r1+0x28]

jmp_14c48:
  ldxb r1, [r6+0x0]
  jeq r1, 0xff, jmp_14c90

jmp_14c58:
  mov64 r0, 0xb
  ja jmp_127e8

jmp_14c68:
  mov64 r1, 0x2
  ja jmp_127e8

jmp_14c78:
  mov64 r0, 0x1
  mov64 r1, 0x0
  ja jmp_127e8

jmp_14c90:
  ldxdw r2, [r6+0x50]
  jeq r2, 0xc7, jmp_14cf8
  jge r2, 0xc7, jmp_14ce0
  mov64 r3, 0xc7
  sub64 r3, r2
  mov64 r1, r6
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_2c080

jmp_14ce0:
  stdw [r6+0x50], 0xc7
  ldxdw r1, [r10-0x888]
  ldxdw r6, [r1+0x28]

jmp_14cf8:
  mov64 r2, r10
  add64 r2, -0x4f8
  mov64 r1, r6
  call fn_2818
  ja jmp_127e8

jmp_14d20:
  ldxdw r3, [r10-0x408]
  lddw r1, 0x1999851ec8b
  jgt r3, r1, jmp_16678
  ldxdw r7, [r8+0x10]
  mul64 r3, 0x141
  ldxdw r1, [r7+0x48]
  jle r3, r1, jmp_14f70
  sub64 r3, r1
  ldxdw r2, [r8+0x0]
  mov64 r1, r7
  add64 r1, 0x8
  stxdw [r10-0x4e8], r1
  mov64 r4, r2
  add64 r4, 0x8
  stxdw [r10-0x4f8], r4
  sth [r10-0x4e0], 0x1
  sth [r10-0x4f0], 0x101
  stxdw [r10-0x5c], r3
  stw [r10-0x60], 0x2
  ldxb r3, [r7+0x0]
  ldxb r5, [r2+0x0]
  and64 r3, r5
  jne r3, 0xff, jmp_14f80
  mov64 r3, r7
  add64 r3, 0x48
  stxdw [r10-0x408], r4
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x400], r4
  ldxdw r4, [r2+0x50]
  mov64 r5, r2
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r2
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r4
  stdw [r10-0x3e0], 0x0
  ldxw r2, [r2+0x1]
  stxdw [r10-0x3c8], r3
  stxdw [r10-0x3d0], r1
  stxw [r10-0x3d8], r2
  ldxdw r1, [r7+0x50]
  mov64 r2, r7
  add64 r2, 0x28
  stxdw [r10-0x3b0], r2
  mov64 r2, r7
  add64 r2, 0x58
  stxdw [r10-0x3b8], r2
  stxdw [r10-0x3c0], r1
  stdw [r10-0x3a8], 0x0
  ldxw r1, [r7+0x1]
  stxw [r10-0x3a0], r1
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x808], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x818], r1
  lddw r1, data_0301
  stxdw [r10-0x820], r1
  stdw [r10-0x800], 0xc
  stdw [r10-0x810], 0x2
  mov64 r1, r10
  add64 r1, -0x820
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r7, [r8+0x10]

jmp_14f70:
  ldxb r1, [r7+0x0]
  jeq r1, 0xff, jmp_15348

jmp_14f80:
  mov64 r1, 0xb

jmp_14f88:
  stxdw [r10-0x8f0], r1

jmp_14f90:
  ja jmp_13720

jmp_14f98:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x408]
  jne r1, 0x1, jmp_15020
  ldxw r1, [r10-0x400]
  ldxw r6, [r10-0x404]
  mov64 r0, r6
  ja jmp_127e8

jmp_15020:
  ldxw r6, [r10-0x400]
  mov64 r1, r10
  add64 r1, -0x81c
  mov64 r2, r10
  add64 r2, -0x3fc
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x820], r6
  ldxdw r2, [r7+0x20]
  mov64 r1, r10
  add64 r1, -0x408
  call fn_0118
  ldxdw r2, [r10-0x408]
  jeq r2, 0x0, jmp_15528
  ldxdw r1, [r10-0x400]
  ldxdw r4, [r2+0x20]
  ldxdw r3, [r7+0x8]
  ldxdw r5, [r3+0x8]
  jne r4, r5, jmp_15180
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x28]
  jne r5, r4, jmp_15180
  ldxdw r4, [r3+0x18]
  ldxdw r5, [r2+0x30]
  jne r5, r4, jmp_15180
  ldxdw r3, [r3+0x20]
  ldxdw r4, [r2+0x38]
  jne r4, r3, jmp_15180
  ldxdw r4, [r2+0x0]
  ldxdw r3, [r7+0x28]
  ldxdw r5, [r3+0x8]
  jne r4, r5, jmp_15180
  ldxdw r4, [r3+0x10]
  ldxdw r5, [r2+0x8]
  jne r5, r4, jmp_15180
  ldxdw r4, [r3+0x18]
  ldxdw r5, [r2+0x10]
  jne r5, r4, jmp_15180
  ldxdw r3, [r3+0x20]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_15180
  ldxdw r3, [r2+0x40]
  ldxdw r2, [r10-0x800]
  jge r3, r2, jmp_16198

jmp_15180:
  ldxb r2, [r1+0x0]
  add64 r2, 0x1
  mov64 r3, r2
  and64 r3, 0xff
  jne r3, r2, jmp_16660
  stxb [r1+0x0], r2
  mov64 r6, 0x0
  mov64 r1, 0x2

jmp_151c0:
  mov64 r0, r6
  ja jmp_127e8

jmp_151d0:
  mov64 r1, r10
  add64 r1, -0x758
  stxdw [r10-0x400], r1
  mov64 r1, r10
  add64 r1, -0x820
  stxdw [r10-0x408], r1
  mov64 r1, r10
  add64 r1, -0x408
  call fn_0468
  stxdw [r10-0x8d0], r1
  and64 r0, 0x1
  jne r0, 0x0, jmp_15240
  mov64 r1, 0xc8
  stxdw [r10-0x8d0], r1

jmp_15240:
  ldxdw r1, [r10-0x8d0]
  jlt r1, 0x9, jmp_15588
  ldxdw r1, [r10-0x820]
  lddw r2, 0x2f2f3a7370747468
  jne r1, r2, jmp_15588
  ldxdw r1, [r10-0x8d0]
  jge r1, 0xc9, jmp_16930
  mov64 r1, r7
  add64 r1, 0x8
  stxdw [r10-0x8e8], r1
  add64 r8, 0x8
  ldxdw r1, [r10-0x898]
  add64 r1, 0x8
  stxdw [r10-0x898], r1
  ldxdw r1, [r10-0x8a0]
  add64 r1, 0x8
  stxdw [r10-0x8a0], r1
  ldxdw r1, [r10-0x8c0]
  add64 r1, 0x8
  stxdw [r10-0x8c0], r1
  mov64 r1, 0x0
  ldxdw r3, [r10-0x8d0]

jmp_152f8:
  mov64 r2, r10
  add64 r2, -0x820
  jeq r3, r1, jmp_15548
  add64 r2, r1
  add64 r1, 0x1
  ldxb r2, [r2+0x0]
  add64 r2, -0x21
  and64 r2, 0xff
  jlt r2, 0x5e, jmp_152f8
  ja jmp_15588

jmp_15348:
  ldxdw r2, [r7+0x50]
  jeq r2, 0xc1, jmp_153a8
  jge r2, 0xc1, jmp_15398
  mov64 r3, 0xc1
  sub64 r3, r2
  mov64 r1, r7
  add64 r1, r2
  add64 r1, 0x58
  mov64 r2, 0x0
  call fn_2c080

jmp_15398:
  stdw [r7+0x50], 0xc1
  ldxdw r7, [r8+0x10]

jmp_153a8:
  stdw [r10-0x620], 0x1
  mov64 r2, r10
  add64 r2, -0x6c8
  mov64 r1, r7
  call fn_3370
  stxdw [r10-0x8d0], r1
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13720
  ldxdw r1, [r10-0x640]
  stxdw [r10-0x360], r1
  ldxdw r1, [r10-0x648]
  stxdw [r10-0x368], r1
  ldxdw r1, [r10-0x650]
  stxdw [r10-0x370], r1
  ldxdw r1, [r10-0x658]
  stxdw [r10-0x378], r1
  ldxdw r1, [r10-0x660]
  stxdw [r10-0x380], r1
  ldxdw r1, [r10-0x668]
  stxdw [r10-0x388], r1
  ldxdw r1, [r10-0x670]
  stxdw [r10-0x390], r1
  ldxdw r1, [r10-0x678]
  stxdw [r10-0x398], r1
  ldxdw r1, [r10-0x6a0]
  stxdw [r10-0x3a0], r1
  ldxdw r1, [r10-0x6a8]
  stxdw [r10-0x3a8], r1
  ldxdw r1, [r10-0x6b0]
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r10-0x6b8]
  stxdw [r10-0x3b8], r1
  stxh [r10-0x358], r9
  ldxh r1, [r10-0x616]
  stxh [r10-0x406], r1
  sth [r10-0x356], 0x2901
  stdw [r10-0x3c0], 0x1
  stb [r10-0x408], 0x0
  ldxdw r3, [r8+0x10]
  ldxdw r2, [r8+0x8]
  mov64 r4, r10
  add64 r4, -0x408
  mov64 r1, r6
  call fn_96e8
  ja jmp_127e8

jmp_15528:
  ldxw r1, [r10-0x3fc]
  ldxw r6, [r10-0x400]
  mov64 r0, r6
  ja jmp_127e8

jmp_15548:
  ldxdw r1, [r10-0x8d0]

jmp_15550:
  jeq r1, 0xc8, jmp_156e0
  mov64 r2, r10
  add64 r2, -0x820
  add64 r2, r1
  add64 r1, 0x1
  ldxb r2, [r2+0x0]
  jeq r2, 0x0, jmp_15550

jmp_15588:
  mov64 r1, 0x1
  mov64 r0, 0x0
  ja jmp_127e8

jmp_155a0:
  mov64 r1, r9
  add64 r1, 0x96
  mov64 r2, 0x0
  stxdw [r10-0x8f0], r2
  mov64 r3, 0x1
  jlt r1, r9, jmp_15600
  mov64 r3, 0x0
  mov64 r2, -0x1
  jeq r3, 0x0, jmp_15610

jmp_155e8:
  ldxdw r1, [r10-0x8c8]
  jge r1, r9, jmp_15628
  ja jmp_15bd0

jmp_15600:
  mov64 r2, -0x1
  jne r3, 0x0, jmp_155e8

jmp_15610:
  mov64 r2, r1
  ldxdw r1, [r10-0x8c8]
  jlt r1, r9, jmp_15bd0

jmp_15628:
  ldxdw r1, [r10-0x8c8]
  jgt r1, r2, jmp_15bd0
  mov64 r1, 0x16
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x8e8]
  jeq r1, 0x0, jmp_13720
  ldxdw r1, [r10-0x400]
  stxdw [r10-0x8b0], r1
  ldxdw r1, [r10-0x8d8]
  and64 r1, 0x1
  stxdw [r10-0x8b8], r1
  jeq r1, 0x0, jmp_15bf8
  ldxdw r1, [r10-0x8e8]
  ldxdw r2, [r10-0x8b0]
  jgt r2, r1, jmp_13720
  ldxdw r1, [r10-0x8b0]
  jne r1, 0x0, jmp_15c10
  ja jmp_12cf8

jmp_156b8:
  mov64 r0, 0xb
  ja jmp_127e0

jmp_156c8:
  mov64 r0, 0x1
  mov64 r1, 0x0
  ja jmp_127e8

jmp_156e0:
  mov64 r1, r10
  add64 r1, -0x6a8
  stxdw [r10-0x8f0], r1
  mov64 r2, 0x0
  mov64 r3, 0xd5
  call fn_2c080
  lddw r1, 0x72616f6264726143
  stxdw [r10-0x6c2], r1
  lddw r1, 0x52414f4244524143
  stxdw [r10-0x6b5], r1
  ldxdw r1, [r10-0x8d0]
  stxw [r10-0x6ac], r1
  mov64 r3, r1
  stxdw [r10-0x8d0], r3
  stw [r10-0x6c6], 0x9
  sth [r10-0x6c8], 0x2a
  stb [r10-0x6ba], 0x64
  stw [r10-0x6b9], 0x9
  stb [r10-0x6ad], 0x44
  mov64 r2, r10
  add64 r2, -0x820
  ldxdw r1, [r10-0x8f0]
  call fn_2c060
  mov64 r1, r10
  add64 r1, -0x6c8
  ldxdw r2, [r10-0x8d0]
  add64 r1, r2
  stdw [r1+0x22], 0x2010000
  sth [r1+0x20], 0x0
  stw [r1+0x29], 0x60100
  ldxdw r2, [r10-0x8b0]
  add64 r2, 0x8
  ldxdw r1, [r10-0x8e8]
  ldxdw r1, [r1+0x0]
  stxdw [r10-0x478], r2
  ldxdw r2, [r10-0x8c0]
  stxdw [r10-0x488], r2
  ldxdw r2, [r10-0x8a0]
  stxdw [r10-0x498], r2
  stxdw [r10-0x4a8], r8
  stxdw [r10-0x4b8], r8
  stxdw [r10-0x4d8], r9
  ldxdw r2, [r10-0x898]
  stxdw [r10-0x4e8], r2
  ldxdw r2, [r10-0x8d8]
  add64 r2, 0x8
  stxdw [r10-0x4f8], r2
  mov64 r2, r1
  add64 r2, 0x8
  stxdw [r10-0x4c8], r2
  sth [r10-0x470], 0x0
  sth [r10-0x480], 0x0
  sth [r10-0x490], 0x0
  sth [r10-0x4a0], 0x100
  sth [r10-0x4b0], 0x101
  sth [r10-0x4c0], 0x100
  sth [r10-0x4d0], 0x1
  sth [r10-0x4e0], 0x0
  sth [r10-0x4f0], 0x1
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r6
  call fn_05d0
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r1, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_15dc0
  stxb [r10-0xb9], r2
  mov64 r1, r10
  add64 r1, -0xb9
  stxdw [r10-0x840], r1
  lddw r1, str_0361
  stxdw [r10-0x850], r1
  stdw [r10-0x838], 0x1
  stdw [r10-0x848], 0x6
  ldxdw r1, [r10-0x8b8]
  stxdw [r10-0x78], r1
  ldxdw r1, [r10-0x8c8]
  stxdw [r10-0x80], r1
  ldxdw r1, [r10-0x8a8]
  stxdw [r10-0x88], r1
  stxdw [r10-0x90], r7
  stxdw [r10-0x98], r7
  ldxdw r1, [r10-0x8e8]
  stxdw [r10-0xa0], r1
  ldxdw r1, [r10-0x888]
  stxdw [r10-0xa8], r1
  ldxdw r1, [r10-0x890]
  stxdw [r10-0xb0], r1
  ldxdw r1, [r10-0x8e0]
  stxdw [r10-0xb8], r1
  mov64 r1, r10
  add64 r1, -0x850
  stxdw [r10-0x70], r1
  stdw [r10-0x68], 0x2
  mov64 r1, r10
  add64 r1, -0x210
  stxdw [r10-0x20], r1
  mov64 r1, r10
  add64 r1, -0x408
  stxdw [r10-0x28], r1
  mov64 r1, r10
  add64 r1, -0x468
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x50], r1
  mov64 r1, r10
  add64 r1, -0x70
  stxdw [r10-0x58], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x60], r1
  stdw [r10-0x8], 0x9
  stdw [r10-0x10], 0x9
  stdw [r10-0x18], 0x0
  stdw [r10-0x30], 0x9
  stdw [r10-0x38], 0x9
  stdw [r10-0x40], 0x0
  mov64 r1, r10
  add64 r1, -0x60
  call fn_0218
  mov64 r1, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_15dc0
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x48], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  stxdw [r10-0x58], r1
  lddw r1, data_0321
  stxdw [r10-0x60], r1
  ldxdw r1, [r10-0x8d0]
  add64 r1, 0x2d
  stxdw [r10-0x40], r1
  stdw [r10-0x50], 0x9
  mov64 r1, r10
  add64 r1, -0x60
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r4, r10
  add64 r4, -0x70
  mov64 r3, 0x9
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_127e8

jmp_15bd0:
  mov64 r1, 0x17
  ja jmp_13718

jmp_15be0:
  mov64 r1, 0x1
  stxdw [r10-0x8f0], r1
  ja jmp_145a8

jmp_15bf8:
  ldxdw r1, [r10-0x8e8]
  ldxdw r2, [r10-0x8b0]
  jlt r2, r1, jmp_13720

jmp_15c10:
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r10-0x8a0]
  mov64 r2, 0x0
  lddw r3, 0xe8d4a51000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r9, 0x1
  ldxdw r1, [r10-0x8b0]
  jlt r0, r1, jmp_15c78
  mov64 r9, 0x0

jmp_15c78:
  jeq r2, 0x0, jmp_15c88
  mov64 r9, 0x0

jmp_15c88:
  mov64 r1, r0
  ldxdw r3, [r10-0x8b0]
  mov64 r4, 0x0
  call fn_2c2a8
  stxdw [r10-0x8e8], r0
  stxdw [r10-0x8c8], r1
  mov64 r1, 0x10
  stxdw [r10-0x8d0], r1
  and64 r9, 0x1
  jne r9, 0x0, jmp_13720
  mov64 r2, 0x10
  ldxdw r1, [r10-0x8b8]
  jne r1, 0x0, jmp_15cf8
  mov64 r2, 0x20

jmp_15cf8:
  mov64 r1, r10
  add64 r1, -0x820
  add64 r1, r2
  mov64 r9, r1
  ldxdw r4, [r1+0x0]
  mov64 r2, r4
  ldxdw r1, [r10-0x8e8]
  add64 r2, r1
  mov64 r0, 0x1
  mov64 r5, 0x1
  stxdw [r10-0x8d0], r2
  jlt r2, r4, jmp_15d60
  mov64 r5, 0x0

jmp_15d60:
  ldxdw r2, [r9+0x8]
  mov64 r1, r2
  ldxdw r3, [r10-0x8c8]
  add64 r1, r3
  mov64 r3, r1
  add64 r3, r5
  jlt r3, r2, jmp_15df0
  mov64 r0, 0x0
  jne r3, r2, jmp_15df8

jmp_15da8:
  and64 r5, 0x1
  jne r5, 0x0, jmp_15e10
  ja jmp_15e30

jmp_15dc0:
  mov64 r0, r1
  mov64 r1, r2
  ja jmp_127e8

jmp_15dd8:
  mov64 r2, 0xb
  mov64 r1, 0x4
  ja jmp_12720

jmp_15df0:
  jeq r3, r2, jmp_15da8

jmp_15df8:
  mov64 r5, r0
  and64 r5, 0x1
  jeq r5, 0x0, jmp_15e30

jmp_15e10:
  mov64 r1, 0x4
  stxdw [r10-0x8d0], r1
  mov64 r1, 0x0
  ja jmp_12998

jmp_15e30:
  ldxdw r2, [r10-0x8b8]
  jne r2, 0x0, jmp_15e50
  ldxdw r5, [r10-0x7d8]
  ja jmp_15e58

jmp_15e50:
  ldxdw r5, [r10-0x7e8]

jmp_15e58:
  ldxdw r2, [r10-0x8b8]
  jne r2, 0x0, jmp_15e78
  ldxdw r2, [r10-0x7e0]
  ja jmp_15e80

jmp_15e78:
  ldxdw r2, [r10-0x7f0]

jmp_15e80:
  mov64 r0, 0x0
  stxdw [r10-0x8f0], r0
  mov64 r3, 0x1
  stxdw [r10-0x910], r3
  ldxdw r0, [r10-0x8d0]
  jlt r0, r4, jmp_15f00
  mov64 r3, 0x0
  add64 r1, r3
  mov64 r4, 0x1
  ldxdw r3, [r10-0x8d0]
  jle r3, r2, jmp_15f20

jmp_15ed8:
  jgt r1, r5, jmp_15f30

jmp_15ee0:
  mov64 r2, 0x0
  stxdw [r10-0x910], r2
  jne r1, r5, jmp_15f38
  ja jmp_15f40

jmp_15f00:
  add64 r1, r3
  mov64 r4, 0x1
  ldxdw r3, [r10-0x8d0]
  jgt r3, r2, jmp_15ed8

jmp_15f20:
  mov64 r4, 0x0
  jle r1, r5, jmp_15ee0

jmp_15f30:
  jeq r1, r5, jmp_15f40

jmp_15f38:
  ldxdw r4, [r10-0x910]

jmp_15f40:
  ldxdw r2, [r10-0x8d0]
  stxdw [r9+0x0], r2
  stxdw [r9+0x8], r1
  mov64 r1, 0xc
  stxdw [r10-0x8d0], r1
  and64 r4, 0x1
  jne r4, 0x0, jmp_13720
  mov64 r1, 0x50
  ldxdw r2, [r10-0x8b8]
  jne r2, 0x0, jmp_15f98
  mov64 r1, 0x60

jmp_15f98:
  mov64 r2, 0x70
  ldxdw r3, [r10-0x8b8]
  jne r3, 0x0, jmp_15fb8
  mov64 r2, 0x80

jmp_15fb8:
  mov64 r3, r10
  add64 r3, -0x820
  mov64 r5, r3
  add64 r5, r2
  add64 r3, r1
  ldxdw r4, [r3+0x8]
  stxdw [r10-0x910], r3
  ldxdw r3, [r3+0x0]
  ldxdw r1, [r5+0x0]
  stxdw [r10-0x918], r5
  ldxdw r2, [r5+0x8]
  ldxdw r5, [r10-0x790]
  stxdw [r10-0xfe8], r5
  ldxdw r5, [r10-0x8a0]
  stxdw [r10-0xff0], r5
  stxdw [r10-0xff8], r2
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r2, r10
  add64 r2, -0x4f8
  mov64 r5, r10
  call fn_29540
  ldxw r1, [r10-0x408]
  jne r1, 0x0, jmp_14888
  ldxdw r1, [r10-0x400]
  stxdw [r10-0x938], r1
  jeq r1, 0x0, jmp_16188
  ldxdw r1, [r10-0x8e0]
  ldxdw r2, [r10-0x938]
  jlt r2, r1, jmp_16188
  ldxdw r1, [r10-0x8c0]
  jne r1, 0x1, jmp_160f8
  ldxh r1, [r10-0x450]
  jne r1, 0x0, jmp_160f8
  ldxw r1, [r10-0x454]
  jne r1, 0x0, jmp_160f8
  ldxdw r1, [r10-0x8a0]
  ldxdw r2, [r10-0x938]
  jne r2, r1, jmp_13720

jmp_160f8:
  ldxdw r4, [r10-0x910]
  ldxdw r2, [r4+0x0]
  mov64 r3, r2
  ldxdw r1, [r10-0x8a0]
  add64 r3, r1
  ldxdw r1, [r4+0x8]
  mov64 r5, 0x1
  mov64 r4, 0x1
  jlt r3, r2, jmp_16690
  mov64 r4, 0x0
  mov64 r0, r1
  add64 r0, r4
  jge r0, r1, jmp_166a8

jmp_16160:
  jge r3, r2, jmp_166b8

jmp_16168:
  mov64 r4, r5
  and64 r4, 0x1
  jne r4, 0x0, jmp_15e10
  ja jmp_166c8

jmp_16188:
  mov64 r1, 0x10
  ja jmp_13718

jmp_16198:
  ldxb r3, [r1+0x0]
  add64 r3, 0x1
  mov64 r4, r3
  and64 r4, 0xff
  jne r4, r3, jmp_16660
  stxb [r1+0x0], r3
  mov64 r3, r2
  add64 r3, r8
  mov64 r6, 0x0
  mov64 r1, 0x1
  jlt r3, r2, jmp_161f8
  mov64 r1, 0x0

jmp_161f8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_16ff0
  mov64 r1, r8
  add64 r1, r2
  stxdw [r10-0x800], r1
  ldxdw r1, [r10-0x7c8]
  jeq r1, 0x0, jmp_16288
  ldxdw r1, [r10-0x7d0]
  mov64 r3, r1
  add64 r3, r8
  mov64 r2, 0x1
  jlt r3, r1, jmp_16260
  mov64 r2, 0x0

jmp_16260:
  and64 r2, 0x1
  jne r2, 0x0, jmp_16ff0
  mov64 r2, r8
  add64 r2, r1
  stxdw [r10-0x7d0], r2

jmp_16288:
  mov64 r1, r10
  add64 r1, -0x820
  call fn_2a1d0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r1, r0
  jne r0, 0x0, jmp_151c0
  mov64 r1, r7
  ldxdw r0, [r1+0x18]
  mov64 r9, r0
  add64 r9, 0x8
  stxdw [r10-0x6c8], r9
  sth [r10-0x6c0], 0x1
  ldxdw r4, [r1+0x28]
  mov64 r6, r4
  add64 r6, 0x8
  stxdw [r10-0x6b8], r6
  sth [r10-0x6b0], 0x0
  ldxdw r2, [r1+0x20]
  mov64 r3, r2
  add64 r3, 0x8
  stxdw [r10-0x890], r3
  stxdw [r10-0x6a8], r3
  sth [r10-0x6a0], 0x1
  ldxdw r1, [r1+0x0]
  mov64 r3, r1
  add64 r3, 0x8
  stxdw [r10-0x888], r3
  stxdw [r10-0x698], r3
  sth [r10-0x690], 0x100
  ldxb r3, [r0+0x0]
  ldxb r5, [r2+0x0]
  and64 r5, r3
  jne r5, 0xff, jmp_176e8
  stxdw [r10-0x408], r9
  mov64 r3, r0
  add64 r3, 0x48
  stxdw [r10-0x400], r3
  ldxdw r3, [r0+0x50]
  mov64 r5, r0
  add64 r5, 0x28
  stxdw [r10-0x3e8], r5
  mov64 r5, r0
  add64 r5, 0x58
  stxdw [r10-0x3f0], r5
  stxdw [r10-0x3f8], r3
  stdw [r10-0x3e0], 0x0
  ldxw r3, [r0+0x1]
  mov64 r5, r4
  add64 r5, 0x48
  stxdw [r10-0x3c8], r5
  stxdw [r10-0x3d0], r6
  stxw [r10-0x3d8], r3
  ldxdw r3, [r4+0x50]
  mov64 r5, r4
  add64 r5, 0x28
  stxdw [r10-0x3b0], r5
  mov64 r5, r4
  add64 r5, 0x58
  stxdw [r10-0x3b8], r5
  stxdw [r10-0x3c0], r3
  stdw [r10-0x3a8], 0x0
  ldxw r3, [r4+0x1]
  mov64 r4, r2
  add64 r4, 0x48
  stxdw [r10-0x390], r4
  ldxdw r4, [r10-0x890]
  stxdw [r10-0x398], r4
  stxw [r10-0x3a0], r3
  mov64 r3, r2
  add64 r3, 0x28
  ldxdw r4, [r2+0x50]
  stxdw [r10-0x378], r3
  mov64 r3, r2
  add64 r3, 0x58
  stxdw [r10-0x380], r3
  stxdw [r10-0x388], r4
  stdw [r10-0x370], 0x0
  ldxw r2, [r2+0x1]
  mov64 r3, r1
  add64 r3, 0x48
  stxdw [r10-0x358], r3
  ldxdw r3, [r10-0x888]
  stxdw [r10-0x360], r3
  stxw [r10-0x368], r2
  mov64 r2, r1
  add64 r2, 0x28
  ldxdw r3, [r1+0x50]
  stxdw [r10-0x340], r2
  mov64 r2, r1
  add64 r2, 0x58
  stxdw [r10-0x348], r2
  stxdw [r10-0x350], r3
  stdw [r10-0x338], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x330], r1
  stxdw [r10-0x5f], r8
  stb [r10-0x57], 0x6
  stb [r10-0x60], 0xc
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x4e0], r1
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x4f0], r1
  lddw r1, data_02c1
  stxdw [r10-0x4f8], r1
  stdw [r10-0x4d8], 0xa
  stdw [r10-0x4e8], 0x4
  mov64 r1, r10
  add64 r1, -0x4f8
  mov64 r2, r10
  add64 r2, -0x408
  mov64 r3, 0x4
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r1, [r7+0x10]
  mov64 r2, r10
  add64 r2, -0x820
  call fn_35c0
  ja jmp_127e8

jmp_16660:
  lddw r1, data_0678
  call fn_2bcf8

jmp_16678:
  mov64 r1, 0x1
  stxdw [r10-0x8f0], r1
  ja jmp_13720

jmp_16690:
  mov64 r0, r1
  add64 r0, r4
  jlt r0, r1, jmp_16160

jmp_166a8:
  mov64 r5, 0x0
  jlt r3, r2, jmp_16168

jmp_166b8:
  and64 r4, 0x1
  jne r4, 0x0, jmp_15e10

jmp_166c8:
  ldxdw r4, [r10-0x910]
  stxdw [r4+0x0], r3
  mov64 r4, 0x1
  mov64 r5, 0x1
  jlt r3, r2, jmp_166f8
  mov64 r5, 0x0

jmp_166f8:
  add64 r1, r5
  ldxdw r2, [r10-0x910]
  stxdw [r2+0x8], r1
  ldxdw r5, [r10-0x918]
  ldxdw r3, [r5+0x0]
  mov64 r2, r3
  ldxdw r1, [r10-0x938]
  add64 r2, r1
  ldxdw r1, [r5+0x8]
  mov64 r5, 0x1
  jlt r2, r3, jmp_16798
  mov64 r5, 0x0
  mov64 r0, r1
  add64 r0, r5
  jge r0, r1, jmp_167b0

jmp_16770:
  jge r2, r3, jmp_167c0

jmp_16778:
  mov64 r5, r4
  and64 r5, 0x1
  jne r5, 0x0, jmp_15e10
  ja jmp_167d0

jmp_16798:
  mov64 r0, r1
  add64 r0, r5
  jlt r0, r1, jmp_16770

jmp_167b0:
  mov64 r4, 0x0
  jlt r2, r3, jmp_16778

jmp_167c0:
  and64 r5, 0x1
  jne r5, 0x0, jmp_15e10

jmp_167d0:
  mov64 r4, 0x1
  jlt r2, r3, jmp_167e8
  mov64 r4, 0x0

jmp_167e8:
  ldxdw r3, [r10-0x890]
  add64 r3, -0xa
  ldxdw r5, [r10-0x918]
  stxdw [r5+0x0], r2
  add64 r1, r4
  stxdw [r5+0x8], r1
  ldxdw r1, [r10-0x908]
  and64 r1, 0x1
  stxdw [r10-0x8e0], r1
  jeq r1, 0x0, jmp_16958
  jge r3, 0x11, jmp_16980
  mov64 r1, 0xb
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x590]
  ldxdw r2, [r10-0x900]
  jlt r1, r2, jmp_16920
  ldxdw r2, [r10-0x900]
  sub64 r1, r2
  stxdw [r10-0x590], r1
  ldxdw r1, [r10-0x4a0]
  stxdw [r10-0x910], r1
  jlt r1, r2, jmp_16920
  ldxdw r1, [r10-0x910]
  ldxdw r2, [r10-0x900]
  sub64 r1, r2
  stxdw [r10-0x4a0], r1
  ldxdw r1, [r10-0x498]
  mov64 r3, r1
  add64 r3, r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_168e8
  mov64 r2, 0x0

jmp_168e8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_15e10
  ldxdw r2, [r10-0x900]
  add64 r2, r1
  stxdw [r10-0x498], r2
  ldxdw r1, [r10-0x890]
  jne r1, 0xa, jmp_16da0

jmp_16920:
  mov64 r1, 0x0
  ja jmp_12998

jmp_16930:
  ldxdw r1, [r10-0x8d0]
  mov64 r2, 0xc8
  lddw r3, data_0800
  call fn_2bcb0

jmp_16958:
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  jeq r3, 0x0, jmp_169a0
  mov64 r1, 0x2
  ja jmp_13718

jmp_16980:
  mov64 r1, 0x2
  stxdw [r10-0x8d0], r1
  mov64 r1, 0x0
  ja jmp_12998

jmp_169a0:
  mov64 r1, 0xb
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x598]
  ldxdw r2, [r10-0x900]
  jlt r1, r2, jmp_13720
  ldxdw r2, [r10-0x900]
  sub64 r1, r2
  stxdw [r10-0x598], r1
  ldxdw r1, [r10-0x4d0]
  jlt r1, r2, jmp_13720
  ldxdw r2, [r10-0x900]
  sub64 r1, r2
  stxdw [r10-0x4d0], r1
  ldxdw r1, [r10-0x4c8]
  mov64 r3, r1
  add64 r3, r2
  mov64 r2, 0x0
  stxdw [r10-0x8f0], r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_16a48
  mov64 r2, 0x0

jmp_16a48:
  and64 r2, 0x1
  mov64 r3, 0x4
  stxdw [r10-0x8d0], r3
  jne r2, 0x0, jmp_13720
  ldxdw r2, [r10-0x900]
  add64 r2, r1
  stxdw [r10-0x4c8], r2

jmp_16a80:
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x40]
  lddw r2, data_0301
  call fn_5b70
  mov64 r1, 0x2
  stxdw [r10-0x8d0], r1
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  stxdw [r10-0x8f0], r0
  jne r0, 0x1a, jmp_13720
  mov64 r1, r10
  add64 r1, -0x60
  stxdw [r10-0x3e8], r1
  mov64 r1, r10
  add64 r1, -0x6c8
  stxdw [r10-0x3f8], r1
  lddw r1, str_0386
  stxdw [r10-0x408], r1
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x60], r1
  stdw [r10-0x3e0], 0x8
  stdw [r10-0x3f0], 0x20
  stdw [r10-0x400], 0x8
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x8]
  ldxdw r1, [r1+0x38]
  stxdw [r10-0xff8], r6
  stxdw [r10-0x1000], r6
  stdw [r10-0xff0], 0xc7
  mov64 r3, r10
  add64 r3, -0x408
  mov64 r5, r10
  mov64 r4, 0x3
  call fn_5bf8
  stxdw [r10-0x8d0], r1
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13720
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  mov64 r1, 0x9
  stxdw [r10-0x8d0], r1
  ldxdw r1, [r10-0x8b0]
  jeq r1, 0x0, jmp_13720
  ldxdw r1, [r10-0x8c0]
  jeq r1, 0x0, jmp_13720
  jgt r7, 0x2710, jmp_13720
  ldxdw r1, [r10-0x588]
  stxdw [r10-0x890], r1
  mov64 r6, 0x0
  mov64 r1, r7
  mov64 r2, 0x0
  ldxdw r7, [r10-0x8b0]
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r2, [r10-0x8c0]
  div64 r7, r2
  mov64 r2, 0x1
  mov64 r3, 0x1
  jlt r7, r0, jmp_16cb8
  mov64 r3, 0x0

jmp_16cb8:
  add64 r1, r3
  neg64 r1
  mov64 r3, r7
  sub64 r3, r0
  mov64 r4, 0x1
  jgt r3, r7, jmp_17008
  mov64 r4, 0x0
  jeq r1, 0x0, jmp_17010

jmp_16cf8:
  jeq r1, 0x0, jmp_17020

jmp_16d00:
  mov64 r4, r2
  mov64 r2, 0x0
  jeq r4, 0x0, jmp_17030

jmp_16d18:
  jne r4, 0x0, jmp_17040

jmp_16d20:
  mov64 r6, r3
  ldxdw r1, [r10-0x8b8]
  jne r1, 0x0, jmp_17050

jmp_16d38:
  mov64 r1, r6
  ldxdw r3, [r10-0x8b0]
  add64 r1, r3
  mov64 r3, 0x0
  stxdw [r10-0x8f0], r3
  mov64 r3, 0x1
  jlt r1, r6, jmp_16d78
  mov64 r3, 0x0

jmp_16d78:
  add64 r2, r3
  mov64 r3, 0x4
  stxdw [r10-0x8d0], r3
  jne r2, 0x0, jmp_13720
  ja jmp_17110

jmp_16da0:
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r1+0x50]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17e50
  ldxw r1, [r10-0x408]
  jne r1, 0x0, jmp_12980
  mov64 r9, r10
  add64 r9, -0x5c
  mov64 r2, r10
  add64 r2, -0x3fc
  ldxw r1, [r10-0x400]
  stxdw [r10-0x8f0], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x918], r1
  stxdw [r10-0x960], r2
  mov64 r3, 0x34
  call fn_2c060
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x60], r1
  stxdw [r10-0x958], r9
  mov64 r1, r9
  ldxdw r2, [r10-0x918]
  mov64 r3, 0x34
  call fn_2c060
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x940]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x928]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x50]
  ldxdw r2, [r10-0x948]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x48]
  jne r1, r8, jmp_17970
  ldxdw r1, [r10-0x488]
  ldxdw r2, [r10-0x40]
  stxdw [r10-0x970], r1
  stxdw [r10-0x968], r2
  jge r2, r1, jmp_17970
  ldxdw r1, [r10-0x30]
  mov64 r9, r1
  ldxdw r2, [r10-0x900]
  jlt r1, r2, jmp_16f20
  ldxdw r9, [r10-0x900]

jmp_16f20:
  sub64 r1, r9
  stxdw [r10-0x30], r1
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x50]
  mov64 r2, r10
  add64 r2, -0x60
  call fn_2608
  stxdw [r10-0x8f0], r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_13718
  ldxdw r1, [r10-0x900]
  sub64 r1, r9
  stxdw [r10-0x950], r1
  ldxdw r1, [r10-0x890]
  jne r1, 0xb, jmp_17708

jmp_16fa8:
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r10-0x950]
  jne r1, 0x0, jmp_13720
  ldxdw r1, [r10-0x900]
  ldxdw r2, [r10-0x910]
  jne r2, r1, jmp_16a80
  stdw [r10-0x4a8], 0x0
  ja jmp_16a80

jmp_16ff0:
  mov64 r1, 0x4
  mov64 r0, r6
  ja jmp_127e8

jmp_17008:
  jne r1, 0x0, jmp_16cf8

jmp_17010:
  mov64 r2, 0x0
  jne r1, 0x0, jmp_16d00

jmp_17020:
  mov64 r2, 0x0
  jne r4, 0x0, jmp_16d18

jmp_17030:
  mov64 r2, r1
  jeq r4, 0x0, jmp_16d20

jmp_17040:
  ldxdw r1, [r10-0x8b8]
  jeq r1, 0x0, jmp_16d38

jmp_17050:
  mov64 r1, 0x0
  mov64 r3, 0x1
  mov64 r4, 0x1
  ldxdw r5, [r10-0x8b0]
  jlt r5, r6, jmp_17080
  mov64 r4, 0x0

jmp_17080:
  add64 r2, r4
  neg64 r2
  ldxdw r0, [r10-0x8b0]
  mov64 r4, r0
  sub64 r4, r6
  mov64 r5, 0x1
  jgt r4, r0, jmp_170e8
  mov64 r5, 0x0
  jeq r2, 0x0, jmp_170f0

jmp_170c8:
  jeq r2, 0x0, jmp_17100

jmp_170d0:
  mov64 r5, r3
  jne r5, 0x0, jmp_17110
  ja jmp_17108

jmp_170e8:
  jne r2, 0x0, jmp_170c8

jmp_170f0:
  mov64 r3, 0x0
  jne r2, 0x0, jmp_170d0

jmp_17100:
  jne r5, 0x0, jmp_17110

jmp_17108:
  mov64 r1, r4

jmp_17110:
  ldxdw r2, [r10-0x8e8]
  stxdw [r10-0x3e8], r2
  ldxdw r2, [r10-0x6b0]
  stxdw [r10-0x3f0], r2
  ldxdw r2, [r10-0x6b8]
  stxdw [r10-0x3f8], r2
  ldxdw r2, [r10-0x6c0]
  stxdw [r10-0x400], r2
  ldxdw r2, [r10-0x6c8]
  stxdw [r10-0x408], r2
  ldxdw r2, [r10-0x898]
  stxh [r10-0x354], r2
  ldxdw r2, [r10-0x890]
  stxdw [r10-0x3d8], r2
  ldxdw r2, [r10-0x8c0]
  stxh [r10-0x352], r2
  ldxdw r2, [r10-0x8b0]
  stxdw [r10-0x3c8], r2
  ldxdw r2, [r10-0x938]
  stxdw [r10-0x3c0], r2
  ldxdw r2, [r10-0x8a8]
  stxh [r10-0x350], r2
  ldxdw r2, [r10-0x8d8]
  stxb [r10-0x34d], r2
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r10-0x8c8]
  stxdw [r10-0x3e0], r1
  ldxdw r9, [r10-0x8a0]
  mov64 r1, r9
  ldxdw r2, [r10-0x930]
  mul64 r1, r2
  div64 r1, 0xf4240
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r10-0x900]
  stxdw [r10-0x3d0], r1
  ldxdw r1, [r10-0x908]
  stxb [r10-0x34c], r1
  stb [r10-0x34e], 0x1
  sth [r10-0x34b], 0x1
  ldxdw r5, [r10-0x648]
  mov64 r2, r5
  add64 r2, r9
  mov64 r7, 0x1
  mov64 r3, 0x1
  jlt r2, r5, jmp_17280
  mov64 r3, 0x0

jmp_17280:
  ldxdw r6, [r10-0x640]
  mov64 r4, r6
  add64 r4, r3
  mov64 r0, 0x1
  jlt r4, r6, jmp_172b0
  mov64 r0, 0x0

jmp_172b0:
  jge r2, r5, jmp_172c0
  mov64 r3, r0

jmp_172c0:
  ldxdw r5, [r10-0x638]
  mov64 r8, r5
  ldxdw r1, [r10-0x900]
  add64 r8, r1
  mov64 r6, 0x1
  jlt r8, r5, jmp_172f8
  mov64 r6, 0x0

jmp_172f8:
  ldxdw r1, [r10-0x630]
  mov64 r9, r1
  add64 r9, r6
  mov64 r0, 0x1
  jlt r9, r1, jmp_173b8
  mov64 r0, 0x0
  jlt r8, r5, jmp_173c0

jmp_17330:
  mov64 r0, -0x1
  mov64 r5, -0x1
  jne r6, 0x0, jmp_173e0

jmp_17348:
  mov64 r5, r9
  mov64 r9, -0x1
  jeq r6, 0x0, jmp_173f0

jmp_17360:
  mov64 r8, -0x1
  jne r3, 0x0, jmp_17408

jmp_17370:
  mov64 r8, r4
  mov64 r4, -0x1
  jeq r3, 0x0, jmp_17418

jmp_17388:
  ldxdw r2, [r10-0x538]
  add64 r2, 0x1
  jeq r2, 0x0, jmp_17438

jmp_173a0:
  mov64 r7, 0x0
  jeq r7, 0x0, jmp_17440
  ja jmp_17448

jmp_173b8:
  jge r8, r5, jmp_17330

jmp_173c0:
  mov64 r6, r0
  mov64 r0, -0x1
  mov64 r5, -0x1
  jeq r6, 0x0, jmp_17348

jmp_173e0:
  mov64 r9, -0x1
  jne r6, 0x0, jmp_17360

jmp_173f0:
  mov64 r9, r8
  mov64 r8, -0x1
  jeq r3, 0x0, jmp_17370

jmp_17408:
  mov64 r4, -0x1
  jne r3, 0x0, jmp_17388

jmp_17418:
  mov64 r4, r2
  ldxdw r2, [r10-0x538]
  add64 r2, 0x1
  jne r2, 0x0, jmp_173a0

jmp_17438:
  jne r7, 0x0, jmp_17448

jmp_17440:
  mov64 r0, r2

jmp_17448:
  ldxdw r1, [r10-0x8f8]
  stxw [r10-0x358], r1
  stxdw [r10-0x538], r0
  stxdw [r10-0x648], r4
  stxdw [r10-0x640], r8
  stxdw [r10-0x638], r9
  stxdw [r10-0x630], r5
  stdw [r10-0x378], 0x0
  stdw [r10-0x380], 0x0
  stdw [r10-0x388], 0x0
  stdw [r10-0x390], 0x0
  stdw [r10-0x398], 0x0
  stdw [r10-0x3a0], 0x0
  stdw [r10-0x3a8], 0x0
  stdw [r10-0x370], 0x0
  stdw [r10-0x368], 0x0
  stdw [r10-0x360], 0x0
  ldxdw r1, [r10-0x8e0]
  jne r1, 0x0, jmp_17540
  ldxdw r3, [r10-0x550]
  mov64 r1, r3
  ldxdw r2, [r10-0x900]
  add64 r1, r2
  mov64 r2, 0x0
  stxdw [r10-0x8f0], r2
  mov64 r2, 0x1
  jlt r1, r3, jmp_17528
  mov64 r2, 0x0

jmp_17528:
  and64 r2, 0x1
  jne r2, 0x0, jmp_12cf8
  stxdw [r10-0x550], r1

jmp_17540:
  mov64 r1, 0x0
  stxdw [r10-0x8f0], r1
  ldxdw r1, [r10-0x890]
  jeq r1, -0x1, jmp_12cf8
  ldxdw r1, [r10-0x890]
  add64 r1, 0x1
  stxdw [r10-0x588], r1
  mov64 r1, r10
  add64 r1, -0x4f8
  call fn_2a1d0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  stxdw [r10-0x8d0], r0
  jne r0, 0x0, jmp_13720
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x38]
  mov64 r2, r10
  add64 r2, -0x408
  call fn_2818
  stxdw [r10-0x8d0], r1
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13720
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x20]
  mov64 r2, r10
  add64 r2, -0x6c8
  call fn_2458
  stxdw [r10-0x8d0], r1
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13720
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x28]
  mov64 r2, r10
  add64 r2, -0x820
  call fn_3370
  stxdw [r10-0x8d0], r1
  stxdw [r10-0x8f0], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_13720
  ldxdw r1, [r10-0x888]
  ldxdw r1, [r1+0x18]
  mov64 r2, r10
  add64 r2, -0x4f8
  call fn_35c0
  ja jmp_127e8

jmp_176e8:
  mov64 r6, 0xb
  mov64 r1, 0x4
  mov64 r0, r6
  ja jmp_127e8

jmp_17708:
  ldxdw r1, [r10-0x890]
  lsh64 r1, 0x3
  ldxdw r2, [r10-0x888]
  add64 r2, 0x58
  stxdw [r10-0x918], r2
  add64 r1, -0x58
  stxdw [r10-0x890], r1

jmp_17740:
  ldxdw r1, [r10-0x918]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x408
  mov64 r3, r6
  call fn_17e50
  ldxw r1, [r10-0x408]
  jne r1, 0x0, jmp_12980
  ldxw r1, [r10-0x400]
  stxdw [r10-0x8f0], r1
  mov64 r9, r10
  add64 r9, -0xb8
  mov64 r1, r9
  ldxdw r2, [r10-0x960]
  mov64 r3, 0x34
  call fn_2c060
  ldxdw r1, [r10-0x8f0]
  stxw [r10-0x60], r1
  ldxdw r1, [r10-0x958]
  mov64 r2, r9
  mov64 r3, 0x34
  call fn_2c060
  ldxdw r1, [r10-0x60]
  ldxdw r2, [r10-0x940]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x58]
  ldxdw r2, [r10-0x928]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x50]
  ldxdw r2, [r10-0x948]
  jne r1, r2, jmp_17970
  ldxdw r1, [r10-0x48]
  jne r1, r8, jmp_17970
  ldxdw r9, [r10-0x40]
  ldxdw r1, [r10-0x968]
  jle r9, r1, jmp_17970
  ldxdw r1, [r10-0x970]
  jge r9, r1, jmp_17970
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x968], r1
  ldxdw r2, [r10-0x950]
  jlt r1, r2, jmp_178a0
  ldxdw r2, [r10-0x950]
  stxdw [r10-0x968], r2

jmp_178a0:
  ldxdw r2, [r10-0x968]
  sub64 r1, r2
  stxdw [r10-0x30], r1
  ldxdw r1, [r10-0x918]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x60
  call fn_2608
  stxdw [r10-0x8f0], r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_13718
  ldxdw r1, [r10-0x918]
  add64 r1, 0x8
  stxdw [r10-0x918], r1
  ldxdw r1, [r10-0x950]
  ldxdw r2, [r10-0x968]
  sub64 r1, r2
  stxdw [r10-0x950], r1
  ldxdw r1, [r10-0x890]
  add64 r1, -0x8
  stxdw [r10-0x968], r9
  stxdw [r10-0x890], r1
  jne r1, 0x0, jmp_17740
  ja jmp_16fa8

jmp_17970:
  mov64 r1, 0xf
  stxdw [r10-0x8d0], r1
  mov64 r1, 0x0
  ja jmp_12998

fn_17990:
  mov64 r7, r3
  mov64 r8, r2
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x180
  call fn_1918
  ldxw r2, [r10-0x17c]
  ldxw r1, [r10-0x180]
  ldxb r9, [r10-0xc8]
  jne r9, 0x2, jmp_179f8
  stxw [r6+0x4], r2
  stxw [r6+0x0], r1
  ja jmp_17be8

jmp_179f8:
  stxdw [r10-0x190], r2
  stxdw [r10-0x188], r1
  mov64 r1, r10
  add64 r1, -0xb0
  mov64 r2, r10
  add64 r2, -0x178
  mov64 r3, 0xa8
  call fn_2c060
  ldxw r1, [r10-0xce]
  stxw [r10-0xb8], r1
  ldxh r1, [r10-0xca]
  stxh [r10-0xb4], r1
  ldxw r1, [r10-0xc7]
  stxw [r10-0xc0], r1
  ldxw r1, [r10-0xc4]
  stxw [r10-0xbd], r1
  ldxh r2, [r10-0xd0]
  mov64 r1, r10
  add64 r1, -0x2
  stxdw [r10-0x170], r1
  lddw r1, str_0378
  stxdw [r10-0x180], r1
  stxdw [r10-0x198], r2
  stxh [r10-0x2], r2
  stdw [r10-0x168], 0x2
  stdw [r10-0x178], 0x6
  mov64 r2, r10
  add64 r2, -0x180
  mov64 r1, r8
  mov64 r3, 0x2
  mov64 r4, r7
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_17bd0
  ldxdw r1, [r10-0x190]
  stxw [r6+0x4], r1
  ldxdw r1, [r10-0x188]
  stxw [r6+0x0], r1
  mov64 r1, r6
  add64 r1, 0x8
  mov64 r2, r10
  add64 r2, -0xb0
  mov64 r3, 0xa8
  call fn_2c060
  ldxdw r1, [r10-0x198]
  stxh [r6+0xb0], r1
  ldxh r1, [r10-0xb4]
  ldxw r2, [r10-0xb8]
  stxb [r6+0xb8], r9
  stxw [r6+0xb2], r2
  stxh [r6+0xb6], r1
  ldxw r1, [r10-0xc0]
  stxw [r6+0xb9], r1
  ldxw r1, [r10-0xbd]
  stxw [r6+0xbc], r1
  ja jmp_17bf0

jmp_17bd0:
  stxw [r6+0x0], r0
  rsh64 r0, 0x20
  stxw [r6+0x4], r0

jmp_17be8:
  stb [r6+0xb8], 0x2

jmp_17bf0:
  exit

fn_17bf8:
  mov64 r8, r4
  mov64 r7, r3
  mov64 r9, r2
  mov64 r6, r1
  mov64 r1, r10
  add64 r1, -0x6a
  stxdw [r10-0x58], r1
  lddw r1, str_0393
  stxdw [r10-0x68], r1
  stxh [r10-0x6a], r7
  stdw [r10-0x50], 0x2
  stdw [r10-0x60], 0x6
  mov64 r2, r10
  add64 r2, -0x68
  mov64 r1, r9
  mov64 r3, 0x2
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_17cf8
  mov64 r1, r10
  add64 r1, -0x68
  mov64 r2, r9
  mov64 r3, r8
  call fn_1748
  ldxw r1, [r10-0x68]
  jne r1, 0x1, jmp_17d10
  ldxdw r1, [r10-0x64]
  stxdw [r6+0x4], r1
  ja jmp_17d00

jmp_17cf8:
  stxdw [r6+0x4], r0

jmp_17d00:
  stw [r6+0x0], 0x1

jmp_17d08:
  exit

jmp_17d10:
  ldxdw r1, [r10-0x5c]
  stxdw [r10-0x28], r1
  ldxdw r1, [r10-0x54]
  stxdw [r10-0x20], r1
  ldxdw r1, [r10-0x4c]
  stxdw [r10-0x18], r1
  ldxdw r1, [r10-0x44]
  stxdw [r10-0x10], r1
  ldxw r1, [r10-0x3c]
  stxw [r10-0x8], r1
  ldxw r1, [r10-0x36]
  stxw [r10-0x30], r1
  ldxh r1, [r10-0x32]
  stxh [r10-0x2c], r1
  ldxh r1, [r10-0x38]
  mov64 r2, r7
  and64 r2, 0xffff
  jne r1, r2, jmp_17e38
  ldxw r1, [r10-0x60]
  stxw [r6+0x8], r1
  ldxdw r1, [r10-0x28]
  stxdw [r6+0xc], r1
  ldxdw r1, [r10-0x20]
  stxdw [r6+0x14], r1
  ldxdw r1, [r10-0x18]
  stxdw [r6+0x1c], r1
  ldxdw r1, [r10-0x10]
  stxdw [r6+0x24], r1
  ldxw r1, [r10-0x8]
  stxw [r6+0x2c], r1
  stxh [r6+0x30], r7
  ldxw r1, [r10-0x30]
  stxw [r6+0x32], r1
  ldxh r1, [r10-0x2c]
  stxh [r6+0x36], r1
  stw [r6+0x0], 0x0
  ja jmp_17d08

jmp_17e38:
  stw [r6+0x8], 0x8
  stdw [r6+0x0], 0x1
  ja jmp_17d08

fn_17e50:
  mov64 r4, r3
  mov64 r3, 0x0
  mov64 r0, 0x2
  ldxdw r5, [r4+0x0]
  ldxdw r6, [r2+0x28]
  jne r6, r5, jmp_18250
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r2+0x30]
  jne r6, r5, jmp_18250
  ldxdw r5, [r4+0x10]
  ldxdw r6, [r2+0x38]
  jne r6, r5, jmp_18250
  ldxdw r5, [r4+0x18]
  ldxdw r6, [r2+0x40]
  jne r6, r5, jmp_18250
  ldxb r5, [r2+0x0]
  jgt r5, 0x1, jmp_17ef0
  mov64 r3, 0xb
  mov64 r0, 0x0
  ja jmp_18250

jmp_17ef0:
  add64 r5, -0x1
  stxb [r2+0x0], r5
  ldxdw r6, [r2+0x50]
  jne r6, 0x40, jmp_18220
  mov64 r0, 0x13
  ldxdw r6, [r2+0x58]
  lddw r7, 0x3130304555515443
  jne r6, r7, jmp_18220
  ldxdw r7, [r2+0x60]
  ldxb r3, [r2+0x6a]
  stxb [r10-0x6], r3
  ldxh r3, [r2+0x68]
  stxh [r10-0x8], r3
  ldxw r3, [r2+0x6b]
  ldxdw r0, [r2+0x77]
  stxdw [r10-0x88], r0
  ldxdw r0, [r2+0x7f]
  stxdw [r10-0x80], r0
  ldxb r0, [r2+0x87]
  stxb [r10-0x78], r0
  ldxdw r0, [r2+0x6f]
  stxdw [r10-0x90], r0
  ldxdw r8, [r2+0x88]
  ldxdw r0, [r2+0x90]
  stxw [r10-0x5], r3
  ldxh r3, [r10-0x4]
  stxh [r10-0x38], r3
  ldxb r3, [r10-0x2]
  stxb [r10-0x36], r3
  ldxw r9, [r10-0x8]
  ldxdw r3, [r10-0x90]
  stxdw [r10-0x35], r3
  ldxdw r3, [r10-0x88]
  stxdw [r10-0x2d], r3
  ldxdw r3, [r10-0x80]
  stxdw [r10-0x25], r3
  ldxb r3, [r10-0x78]
  stxb [r10-0x1d], r3
  and64 r5, 0xff
  add64 r5, 0x1
  mov64 r3, r5
  and64 r3, 0xff
  mov64 r6, r1
  jne r3, r5, jmp_18288
  stxb [r2+0x0], r5
  stxw [r10-0x90], r9
  stxdw [r10-0x98], r7
  stxdw [r10-0x70], r7
  stxdw [r10-0x60], r0
  ldxdw r1, [r10-0x38]
  stxdw [r10-0x58], r1
  stxdw [r10-0x8c], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x50], r1
  stxdw [r10-0x84], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x48], r1
  stxdw [r10-0x7c], r1
  ldxw r1, [r10-0x20]
  stxw [r10-0x40], r1
  stxw [r10-0x74], r1
  stxdw [r10-0x68], r8
  mov64 r1, r10
  add64 r1, -0x8
  stxdw [r10-0x18], r1
  mov64 r1, r10
  add64 r1, -0x90
  stxdw [r10-0x28], r1
  lddw r1, data_03a6
  stxdw [r10-0x38], r1
  stxdw [r10-0x8], r8
  stdw [r10-0x10], 0x8
  stdw [r10-0x20], 0x20
  stdw [r10-0x30], 0x5
  mov64 r3, r10
  add64 r3, -0x38
  mov64 r1, r2
  mov64 r2, r3
  mov64 r3, 0x3
  mov64 r7, r0
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_18270
  stxw [r6+0x8], r9
  ldxdw r1, [r10-0x58]
  stxdw [r6+0xc], r1
  ldxdw r1, [r10-0x50]
  stxdw [r6+0x14], r1
  ldxdw r1, [r10-0x48]
  stxdw [r6+0x1c], r1
  ldxw r1, [r10-0x40]
  stxw [r6+0x24], r1
  stxdw [r6+0x38], r7
  stxdw [r6+0x30], r8
  ldxdw r1, [r10-0x98]
  stxdw [r6+0x28], r1
  stw [r6+0x0], 0x0
  ja jmp_18268

jmp_18220:
  and64 r5, 0xff
  add64 r5, 0x1
  mov64 r4, r5
  and64 r4, 0xff
  jne r4, r5, jmp_18288
  stxb [r2+0x0], r5

jmp_18250:
  stxw [r1+0x8], r0
  stxw [r1+0x4], r3
  stw [r1+0x0], 0x1

jmp_18268:
  exit

jmp_18270:
  stxdw [r6+0x4], r0
  stw [r6+0x0], 0x1
  ja jmp_18268

jmp_18288:
  lddw r1, data_0678
  call fn_2bcf8

fn_182a0:
  mov64 r9, r2
  mov64 r6, r1
  jne r3, 0xd, jmp_18400
  stxdw [r10-0x790], r4
  stxdw [r10-0x788], r5
  ldxdw r8, [r9+0x10]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r8
  mov64 r3, r6
  call fn_3820
  ldxw r4, [r10-0x39c]
  ldxw r0, [r10-0x3a0]
  ldxb r7, [r10-0x24e]
  jeq r7, 0x2, jmp_18410
  stxdw [r10-0x7a0], r8
  mov64 r1, r10
  add64 r1, -0x770
  mov64 r2, r10
  add64 r2, -0x398
  mov64 r3, 0x14a
  stxdw [r10-0x780], r9
  mov64 r9, r0
  mov64 r8, r4
  call fn_2c060
  ldxw r1, [r10-0x24d]
  stxw [r10-0x625], r1
  ldxb r1, [r10-0x249]
  stxb [r10-0x621], r1
  stxb [r10-0x626], r7
  stxw [r10-0x774], r8
  stxw [r10-0x778], r9
  ldxdw r9, [r10-0x780]
  ldxdw r8, [r9+0x18]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r8
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x3a0]
  jne r1, 0x1, jmp_18420

jmp_183e8:
  ldxw r4, [r10-0x398]
  ldxw r0, [r10-0x39c]
  ja jmp_18410

jmp_18400:
  mov64 r0, 0x0
  mov64 r4, 0x2

jmp_18410:
  mov64 r1, r4
  exit

jmp_18420:
  stxdw [r10-0x798], r6
  ldxw r6, [r10-0x398]
  mov64 r1, r10
  add64 r1, -0x61c
  mov64 r2, r10
  add64 r2, -0x394
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x620], r6
  mov64 r6, r9
  ldxdw r9, [r6+0x20]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r9
  ldxdw r3, [r10-0x798]
  call fn_3a90
  ldxw r4, [r10-0x39c]
  ldxw r0, [r10-0x3a0]
  ldxb r1, [r10-0x1d7]
  jeq r1, 0x2, jmp_18410
  stxdw [r10-0x7c0], r9
  mov64 r9, r1
  mov64 r1, r10
  add64 r1, -0x568
  mov64 r2, r10
  add64 r2, -0x398
  mov64 r3, 0x1c1
  stxdw [r10-0x7a8], r0
  stxdw [r10-0x7b0], r4
  call fn_2c060
  ldxw r1, [r10-0x1d6]
  stxw [r10-0x3a6], r1
  ldxh r1, [r10-0x1d2]
  stxh [r10-0x3a2], r1
  stxdw [r10-0x7b8], r9
  stxb [r10-0x3a7], r9
  ldxdw r1, [r10-0x7b0]
  stxw [r10-0x56c], r1
  ldxdw r1, [r10-0x7a8]
  stxw [r10-0x570], r1
  ldxdw r6, [r6+0x38]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r6
  ldxdw r3, [r10-0x798]
  call fn_0f90
  ldxw r4, [r10-0x39c]
  ldxw r0, [r10-0x3a0]
  ldxb r9, [r10-0x2e2]
  jeq r9, 0x2, jmp_18410
  stxdw [r10-0x7c8], r8
  mov64 r1, r10
  add64 r1, -0x1c8
  mov64 r2, r10
  add64 r2, -0x398
  mov64 r3, 0xb6
  mov64 r8, r0
  stxdw [r10-0x7b0], r6
  mov64 r6, r4
  call fn_2c060
  stxb [r10-0x112], r9
  stxw [r10-0x1cc], r6
  stxw [r10-0x1d0], r8
  ldxb r1, [r10-0x2e1]
  stxb [r10-0x111], r1
  mov64 r1, r10
  add64 r1, -0x110
  stxdw [r10-0x380], r1
  mov64 r1, r10
  add64 r1, -0x1d0
  stxdw [r10-0x390], r1
  lddw r1, str_0386
  stxdw [r10-0x3a0], r1
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x110], r1
  stdw [r10-0x378], 0x8
  stdw [r10-0x388], 0x20
  stdw [r10-0x398], 0x8
  mov64 r2, r10
  add64 r2, -0x3a0
  ldxdw r8, [r10-0x7b0]
  mov64 r1, r8
  mov64 r3, 0x3
  ldxdw r4, [r10-0x798]
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_18870
  mov64 r0, 0x0
  ldxdw r6, [r10-0x1d0]
  ldxdw r1, [r10-0x570]
  jne r6, r1, jmp_18df8
  ldxdw r2, [r10-0x1c8]
  ldxdw r1, [r10-0x568]
  mov64 r4, 0x3
  jne r2, r1, jmp_18410
  ldxdw r5, [r10-0x1c0]
  ldxdw r1, [r10-0x560]
  jne r5, r1, jmp_18410
  ldxdw r3, [r10-0x1b8]
  ldxdw r1, [r10-0x558]
  jne r3, r1, jmp_18410
  ldxdw r1, [r10-0x788]
  ldxdw r9, [r1+0x0]
  jne r9, 0x5, jmp_18888
  ldxdw r1, [r10-0x780]
  ldxdw r3, [r1+0x8]
  ldxb r1, [r3+0x1]
  jeq r1, 0x0, jmp_18410
  ldxdw r1, [r3+0x8]
  ldxdw r2, [r10-0x778]
  jne r1, r2, jmp_18410
  ldxdw r4, [r10-0x770]
  ldxdw r2, [r3+0x10]
  jne r2, r4, jmp_18df8
  ldxdw r5, [r10-0x768]
  ldxdw r4, [r3+0x18]
  jne r4, r5, jmp_18df8
  ldxdw r5, [r10-0x760]
  ldxdw r3, [r3+0x20]
  jne r3, r5, jmp_18df8
  ldxdw r5, [r10-0x780]
  ldxdw r5, [r5+0x0]
  ldxb r7, [r5+0x1]
  jeq r7, 0x0, jmp_18df8
  ldxdw r0, [r5+0x8]
  jne r0, r1, jmp_18df0
  ldxdw r1, [r5+0x10]
  jne r1, r2, jmp_18df0
  ldxdw r1, [r5+0x18]
  jne r1, r4, jmp_18df0
  ldxdw r1, [r5+0x20]
  mov64 r0, 0x0
  mov64 r4, 0x3
  jeq r1, r3, jmp_18c78
  ja jmp_18410

jmp_18870:
  mov64 r4, r0
  rsh64 r4, 0x20
  ja jmp_18410

jmp_18888:
  stxdw [r10-0x7d0], r5
  stxdw [r10-0x7d8], r3
  stxdw [r10-0x7a8], r2
  lddw r2, data_03b0
  call fn_1f970
  jeq r0, 0x0, jmp_189c8
  ldxdw r1, [r10-0x780]
  ldxdw r2, [r1+0x8]
  ldxb r1, [r2+0x1]
  jeq r1, 0x0, jmp_18df0
  ldxdw r1, [r2+0x20]
  ldxdw r3, [r2+0x18]
  ldxdw r4, [r2+0x10]
  ldxdw r5, [r2+0x8]
  ldxdw r0, [r10-0x778]
  jne r5, r0, jmp_18940
  ldxdw r0, [r10-0x770]
  jne r4, r0, jmp_18940
  ldxdw r0, [r10-0x768]
  jne r3, r0, jmp_18940
  ldxdw r0, [r10-0x760]
  jeq r1, r0, jmp_18980

jmp_18940:
  ldxdw r0, [r10-0x758]
  jne r5, r0, jmp_18df0
  ldxdw r5, [r10-0x750]
  jne r4, r5, jmp_18df0
  ldxdw r4, [r10-0x748]
  jne r3, r4, jmp_18df0
  ldxdw r3, [r10-0x740]
  jne r1, r3, jmp_18df0

jmp_18980:
  add64 r2, 0x8
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x0]
  call fn_0548
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r4, 0x3
  jne r0, 0x1a, jmp_18410
  ja jmp_18c78

jmp_189c8:
  mov64 r0, 0x0
  mov64 r4, 0x3
  jeq r9, 0x0, jmp_18b40
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x0]
  jeq r1, 0x0, jmp_18c78
  ldxdw r1, [r10-0x7b8]
  and64 r1, 0x1
  jne r1, 0x0, jmp_18b78
  ldxdw r1, [r10-0x788]
  lddw r2, data_03c8
  call fn_1f970
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x0]
  jeq r0, 0x0, jmp_18ba8
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_18df0
  ldxdw r2, [r1+0x8]
  jne r2, r6, jmp_18df0
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0x7a8]
  jne r2, r3, jmp_18df0
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x7d0]
  jne r2, r3, jmp_18df0
  ldxdw r1, [r1+0x20]
  ldxdw r2, [r10-0x7d8]
  jne r1, r2, jmp_18df0
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x8]
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_18df0
  ldxdw r2, [r1+0x8]
  jne r2, r6, jmp_18df0
  ldxdw r2, [r1+0x10]
  ldxdw r3, [r10-0x7a8]
  jne r2, r3, jmp_18df0
  ldxdw r2, [r1+0x18]
  ldxdw r3, [r10-0x7d0]
  jne r2, r3, jmp_18df0
  ldxdw r1, [r1+0x20]
  mov64 r0, 0x0
  mov64 r4, 0x3
  ldxdw r2, [r10-0x7d8]
  jeq r1, r2, jmp_18c78
  ja jmp_18410

jmp_18b40:
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x0]
  ldxb r1, [r1+0x1]
  jeq r1, 0x0, jmp_18410
  ldxdw r1, [r10-0x7b8]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_18b88

jmp_18b78:
  mov64 r4, 0x18
  ja jmp_18410

jmp_18b88:
  mov64 r4, 0x7
  and64 r7, 0x1
  jeq r7, 0x0, jmp_18410
  ja jmp_18c78

jmp_18ba8:
  ldxb r2, [r1+0x1]
  jeq r2, 0x0, jmp_18df0
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r10-0x6f8]
  jne r2, r3, jmp_18df0
  ldxdw r2, [r10-0x6f0]
  ldxdw r3, [r1+0x10]
  jne r3, r2, jmp_18df0
  ldxdw r2, [r10-0x6e8]
  ldxdw r3, [r1+0x18]
  jne r3, r2, jmp_18df0
  ldxdw r2, [r10-0x6e0]
  ldxdw r1, [r1+0x20]
  mov64 r0, 0x0
  mov64 r4, 0x3
  jne r1, r2, jmp_18410
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x8]
  mov64 r2, r10
  add64 r2, -0x570
  call fn_59d0
  mov64 r4, r1
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_18410

jmp_18c78:
  ldxdw r1, [r10-0x780]
  ldxdw r6, [r1+0x28]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r6
  ldxdw r3, [r10-0x798]
  call fn_17990
  ldxw r4, [r10-0x39c]
  ldxw r0, [r10-0x3a0]
  ldxb r7, [r10-0x2e8]
  jeq r7, 0x2, jmp_18410
  stxdw [r10-0x7d8], r6
  stxdw [r10-0x7d0], r9
  mov64 r1, r10
  add64 r1, -0x108
  mov64 r2, r10
  add64 r2, -0x398
  mov64 r3, 0xb0
  mov64 r8, r0
  mov64 r6, r4
  call fn_2c060
  ldxw r1, [r10-0x2e7]
  stxw [r10-0x57], r1
  ldxw r1, [r10-0x2e4]
  stxw [r10-0x54], r1
  mov64 r9, r7
  stxb [r10-0x58], r7
  stxw [r10-0x10c], r6
  stxw [r10-0x110], r8
  mov64 r0, 0x0
  mov64 r4, 0x8
  ldxh r8, [r10-0x60]
  ldxh r1, [r10-0x11c]
  jne r8, r1, jmp_18410
  mov64 r2, r10
  add64 r2, -0x3a0
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jeq r0, 0x0, jmp_18e08
  mov64 r1, 0x10
  jne r0, 0x1, jmp_18de0
  mov64 r1, 0x1

jmp_18de0:
  mov64 r0, r1
  ja jmp_18410

jmp_18df0:
  mov64 r0, 0x0

jmp_18df8:
  mov64 r4, 0x3
  ja jmp_18410

jmp_18e08:
  ldxdw r7, [r10-0x3a0]
  ldxdw r1, [r10-0x7d0]
  jne r1, 0x5, jmp_18e78
  mov64 r1, r7
  add64 r1, 0x96
  mov64 r3, 0x1
  jlt r1, r7, jmp_18f68
  mov64 r3, 0x0
  mov64 r2, -0x1
  jeq r3, 0x0, jmp_18f78

jmp_18e58:
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x10]
  jge r1, r7, jmp_18f98
  ja jmp_19440

jmp_18e78:
  ldxdw r1, [r10-0x780]
  ldxdw r2, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r3, r8
  ldxdw r4, [r10-0x798]
  call fn_17bf8
  ldxw r1, [r10-0x3a0]
  jne r1, 0x0, jmp_183e8
  ldxw r6, [r10-0x398]
  mov64 r1, r10
  add64 r1, -0x4c
  mov64 r2, r10
  add64 r2, -0x394
  mov64 r3, 0x2c
  call fn_2c060
  stxw [r10-0x50], r6
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r10
  add64 r2, -0x110
  mov64 r3, r10
  add64 r3, -0x50
  mov64 r4, r7
  call fn_2a6d8
  ldxw r1, [r10-0x10]
  jeq r1, 0x0, jmp_18fd8
  mov64 r0, 0x0
  ldxw r4, [r10-0xc]
  ja jmp_18410

jmp_18f68:
  mov64 r2, -0x1
  jne r3, 0x0, jmp_18e58

jmp_18f78:
  mov64 r2, r1
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x10]
  jlt r1, r7, jmp_19440

jmp_18f98:
  jgt r1, r2, jmp_19440
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x8]
  stxdw [r10-0x7e0], r1
  jne r1, 0x0, jmp_18fe8
  mov64 r4, 0x16
  mov64 r0, 0x0
  ja jmp_18410

jmp_18fd8:
  ldxdw r1, [r10-0x8]
  stxdw [r10-0x7e0], r1

jmp_18fe8:
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x0]
  jeq r1, 0x0, jmp_19118
  mov64 r1, r7
  add64 r1, 0x96
  mov64 r3, 0x1
  jlt r1, r7, jmp_19058
  mov64 r3, 0x0
  mov64 r2, -0x1
  jeq r3, 0x0, jmp_19068

jmp_19038:
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x10]
  jge r1, r7, jmp_19088
  ja jmp_19440

jmp_19058:
  mov64 r2, -0x1
  jne r3, 0x0, jmp_19038

jmp_19068:
  mov64 r2, r1
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x10]
  jlt r1, r7, jmp_19440

jmp_19088:
  jgt r1, r2, jmp_19440
  ldxdw r1, [r10-0x790]
  ldxdw r1, [r1+0x8]
  jeq r1, 0x0, jmp_190e8
  ldxb r2, [r10-0x115]
  mov64 r0, 0x0
  and64 r2, 0x1
  jeq r2, 0x0, jmp_19100
  ldxdw r2, [r10-0x7e0]
  mov64 r4, 0x16
  jlt r2, r1, jmp_18410
  ja jmp_19118

jmp_190e8:
  mov64 r0, 0x0
  mov64 r4, 0x16
  ja jmp_18410

jmp_19100:
  ldxdw r2, [r10-0x7e0]
  mov64 r4, 0x16
  jgt r2, r1, jmp_18410

jmp_19118:
  ldxdw r1, [r10-0x7d0]
  jeq r1, 0x0, jmp_191c0

jmp_19128:
  ldxdw r1, [r10-0x788]
  lddw r2, data_03e0
  call fn_1f970
  mov64 r6, 0x1
  jeq r0, 0x0, jmp_19238

jmp_19158:
  ldxdw r1, [r10-0x5c8]
  stxdw [r10-0x788], r1
  mov64 r1, r10
  add64 r1, -0x10
  mov64 r2, r10
  add64 r2, -0x620
  call fn_2a040
  ldxw r1, [r10-0x10]
  jne r1, 0x1, jmp_192b0
  ldxw r6, [r10-0xc]

jmp_191a8:
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  ja jmp_195e0

jmp_191c0:
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x8]
  ldxdw r2, [r10-0x128]
  jne r2, r1, jmp_19368
  mov64 r1, r7
  add64 r1, 0x96
  mov64 r3, 0x1
  jlt r1, r7, jmp_19380
  mov64 r3, 0x0
  mov64 r2, -0x1
  jeq r3, 0x0, jmp_19390

jmp_19218:
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x10]
  jge r1, r7, jmp_193b0
  ja jmp_19440

jmp_19238:
  ldxb r1, [r10-0x116]
  jne r1, 0x1, jmp_19458
  ldxdw r1, [r10-0x180]
  mov64 r0, 0x0
  mov64 r4, 0x13
  jeq r1, 0x0, jmp_18410
  mov64 r2, 0x1
  ldxdw r3, [r10-0x7e0]
  jge r3, r1, jmp_195f8
  mov64 r2, 0x0
  ldxdw r3, [r10-0x7e0]
  jgt r3, r1, jmp_19608

jmp_19298:
  ldxb r1, [r10-0x115]
  jne r1, 0x0, jmp_19158
  ja jmp_19620

jmp_192b0:
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x1
  ldxdw r3, [r10-0x788]
  jne r3, 0x0, jmp_192d8
  mov64 r2, 0x0

jmp_192d8:
  stxdw [r10-0x1000], r1
  stxdw [r10-0xff8], r2
  mov64 r4, r6
  and64 r4, 0x1
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r10
  add64 r2, -0x1d0
  mov64 r5, r10
  ldxdw r3, [r10-0x7e0]
  stxdw [r10-0x790], r4
  call fn_26048
  ldxw r1, [r10-0x3a0]
  jne r1, 0x1, jmp_19470
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  ldxw r6, [r10-0x39c]
  ja jmp_195e0

jmp_19368:
  mov64 r0, 0x0
  mov64 r4, 0x1d
  ja jmp_18410

jmp_19380:
  mov64 r2, -0x1
  jne r3, 0x0, jmp_19218

jmp_19390:
  mov64 r2, r1
  ldxdw r1, [r10-0x788]
  ldxdw r1, [r1+0x10]
  jlt r1, r7, jmp_19440

jmp_193b0:
  jgt r1, r2, jmp_19440
  and64 r9, 0x1
  mov64 r4, 0x8
  mov64 r0, 0x0
  jne r9, 0x0, jmp_18410
  ldxdw r1, [r10-0x780]
  ldxdw r2, [r1+0x30]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r3, r8
  ldxdw r4, [r10-0x798]
  call fn_17bf8
  ldxw r1, [r10-0x3a0]
  jne r1, 0x1, jmp_199c8
  ldxw r5, [r10-0x398]
  ldxw r0, [r10-0x39c]

jmp_19430:
  mov64 r4, r5
  ja jmp_18410

jmp_19440:
  mov64 r0, 0x0
  mov64 r4, 0x17
  ja jmp_18410

jmp_19458:
  mov64 r0, 0x0
  mov64 r4, 0x13
  ja jmp_18410

jmp_19470:
  ldxdw r2, [r10-0x398]
  ldxdw r4, [r10-0x620]
  mov64 r1, r4
  stxdw [r10-0x7e8], r2
  add64 r1, r2
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r3, 0x1
  stxdw [r10-0x818], r4
  jlt r1, r4, jmp_194c8
  mov64 r3, 0x0

jmp_194c8:
  ldxdw r0, [r10-0x390]
  ldxdw r5, [r10-0x618]
  mov64 r2, r5
  add64 r2, r0
  add64 r2, r3
  mov64 r4, r5
  xor64 r4, r0
  xor64 r4, -0x1
  stxdw [r10-0x820], r5
  mov64 r3, r5
  xor64 r3, r2
  and64 r4, r3
  stxdw [r10-0x810], r0
  stxdw [r10-0x48], r0
  ldxdw r3, [r10-0x7e8]
  stxdw [r10-0x50], r3
  ldxdw r3, [r10-0x360]
  stxdw [r10-0x808], r3
  stxdw [r10-0x18], r3
  ldxdw r3, [r10-0x368]
  stxdw [r10-0x828], r3
  stxdw [r10-0x20], r3
  ldxdw r3, [r10-0x370]
  stxdw [r10-0x7f8], r3
  stxdw [r10-0x28], r3
  ldxdw r3, [r10-0x378]
  stxdw [r10-0x30], r3
  ldxdw r5, [r10-0x380]
  stxdw [r10-0x800], r5
  stxdw [r10-0x38], r5
  ldxdw r5, [r10-0x388]
  stxdw [r10-0x7f0], r5
  stxdw [r10-0x40], r5
  jsge r4, 0x0, jmp_19630

jmp_195d8:
  mov64 r6, 0x4

jmp_195e0:
  ldxdw r0, [r10-0x7a8]
  mov64 r4, r6
  ja jmp_18410

jmp_195f8:
  ldxdw r3, [r10-0x7e0]
  jle r3, r1, jmp_19298

jmp_19608:
  mov64 r6, 0x0
  ldxb r1, [r10-0x115]
  jne r1, 0x0, jmp_19158

jmp_19620:
  mov64 r6, r2
  ja jmp_19158

jmp_19630:
  stxdw [r10-0x620], r1
  stxdw [r10-0x618], r2
  ldxdw r1, [r10-0x198]
  ldxb r2, [r10-0x114]
  jeq r2, 0x0, jmp_19688
  mov64 r6, 0xb
  ldxdw r2, [r10-0x5c0]
  jlt r2, r1, jmp_195e0
  sub64 r2, r1
  stxdw [r10-0x5c0], r2
  ja jmp_196b0

jmp_19688:
  mov64 r6, 0xb
  ldxdw r2, [r10-0x5f0]
  jlt r2, r1, jmp_195e0
  sub64 r2, r1
  stxdw [r10-0x5f0], r2

jmp_196b0:
  ldxdw r8, [r10-0x440]
  mov64 r4, r8
  ldxdw r1, [r10-0x7f0]
  add64 r4, r1
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r4, r8, jmp_196f8
  mov64 r2, 0x0

jmp_196f8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  ldxdw r0, [r10-0x5f8]
  mov64 r4, r0
  ldxdw r1, [r10-0x7f0]
  add64 r4, r1
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r4, r0, jmp_19750
  mov64 r2, 0x0

jmp_19750:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  ldxdw r5, [r10-0x7f8]
  rsh64 r5, 0x1
  ldxdw r2, [r10-0x5e8]
  mov64 r6, r2
  add64 r6, r5
  mov64 r4, 0x0
  stxdw [r10-0x7a8], r4
  mov64 r4, 0x1
  jlt r6, r2, jmp_197b0
  mov64 r4, 0x0

jmp_197b0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_195d8
  ldxdw r4, [r10-0x7f8]
  sub64 r4, r5
  ldxdw r1, [r10-0x5e0]
  mov64 r6, r1
  add64 r6, r4
  mov64 r7, 0x0
  stxdw [r10-0x7a8], r7
  mov64 r7, 0x1
  jlt r6, r1, jmp_19810
  mov64 r7, 0x0

jmp_19810:
  add64 r5, r2
  stxdw [r10-0x5e8], r5
  and64 r7, 0x1
  jne r7, 0x0, jmp_195d8
  ldxdw r2, [r10-0x7f0]
  add64 r2, r0
  add64 r4, r1
  stxdw [r10-0x5e0], r4
  ldxdw r1, [r10-0x788]
  jeq r1, 0x0, jmp_19e98
  ldxdw r4, [r10-0x5d0]
  mov64 r0, r4
  add64 r0, r3
  mov64 r5, 0x0
  stxdw [r10-0x7a8], r5
  mov64 r5, 0x1
  jlt r0, r4, jmp_198a0
  mov64 r5, 0x0

jmp_198a0:
  and64 r5, 0x1
  jne r5, 0x0, jmp_195d8
  add64 r3, r4
  stxdw [r10-0x5d0], r3
  mov64 r7, 0x0

jmp_198c8:
  ldxdw r3, [r10-0x7f0]
  add64 r3, r8
  mov64 r4, r3
  add64 r4, r7
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  mov64 r1, 0x1
  jlt r4, r3, jmp_19910
  mov64 r1, 0x0

jmp_19910:
  and64 r1, 0x1
  jne r1, 0x0, jmp_195d8
  mov64 r4, r2
  add64 r4, r7
  mov64 r1, 0x1
  jlt r4, r2, jmp_19948
  mov64 r1, 0x0

jmp_19948:
  mov64 r4, r7
  add64 r4, r3
  stxdw [r10-0x440], r4
  and64 r1, 0x1
  jne r1, 0x0, jmp_199b8
  mov64 r1, r7
  add64 r1, r2
  stxdw [r10-0x5f8], r1
  ldxdw r1, [r10-0x800]
  jne r1, r7, jmp_19b28
  ldxdw r1, [r10-0x808]
  jeq r1, 0x0, jmp_1a370

jmp_199a8:
  ldxdw r1, [r10-0x810]
  jsle r1, 0x0, jmp_1a0a0

jmp_199b8:
  mov64 r6, 0x4
  ja jmp_191a8

jmp_199c8:
  ldxw r6, [r10-0x398]
  mov64 r1, r10
  add64 r1, -0x4c
  mov64 r2, r10
  add64 r2, -0x394
  mov64 r3, 0x2c
  call fn_2c060
  stxw [r10-0x50], r6
  ldxdw r5, [r10-0x638]
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r2, r10
  add64 r2, -0x110
  mov64 r3, r10
  add64 r3, -0x50
  mov64 r4, r7
  call fn_2a568
  mov64 r0, 0x0
  ldxw r1, [r10-0x3a0]
  jeq r1, 0x0, jmp_19a80
  ldxw r5, [r10-0x39c]
  mov64 r4, r5
  ja jmp_18410

jmp_19a80:
  mov64 r5, 0x1c
  ldxdw r1, [r10-0x7e0]
  jeq r1, 0x0, jmp_19430
  ldxb r1, [r10-0x113]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_19430
  ldxdw r1, [r10-0x138]
  jeq r1, 0x0, jmp_1a060
  mov64 r2, 0x1
  mov64 r3, 0x1
  ldxdw r4, [r10-0x7e0]
  jge r4, r1, jmp_1a028
  mov64 r3, 0x0
  ldxdw r4, [r10-0x7e0]
  jgt r4, r1, jmp_1a038

jmp_19af8:
  ldxb r1, [r10-0x115]
  jne r1, 0x0, jmp_1a050

jmp_19b08:
  mov64 r2, r3
  and64 r2, 0x1
  jne r2, 0x0, jmp_1a768
  ja jmp_1a060

jmp_19b28:
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x48]
  lddw r2, data_0301
  call fn_5b70
  mov64 r6, 0x2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  stxdw [r10-0x7a8], r0
  jne r0, 0x1a, jmp_195e0
  mov64 r1, 0x0
  mov64 r2, 0x0
  ldxdw r3, [r10-0x790]
  jne r3, 0x0, jmp_19ba0
  mov64 r2, 0x8

jmp_19ba0:
  ldxdw r3, [r10-0x7d0]
  jeq r3, 0x0, jmp_19bb8
  mov64 r1, r2

jmp_19bb8:
  mov64 r2, r10
  add64 r2, -0x10
  stxdw [r10-0x380], r2
  mov64 r2, r10
  add64 r2, -0x1d0
  stxdw [r10-0x390], r2
  lddw r2, data_03a6
  stxdw [r10-0x3a0], r2
  ldxdw r2, [r10-0x1a0]
  stxdw [r10-0x10], r2
  ldxdw r3, [r10-0x780]
  mov64 r2, r3
  add64 r2, r1
  stdw [r10-0x378], 0x8
  stdw [r10-0x388], 0x20
  stdw [r10-0x398], 0x5
  ldxdw r2, [r2+0x0]
  ldxdw r9, [r3+0x40]
  ldxdw r1, [r10-0x798]
  stxdw [r10-0xff8], r1
  stxdw [r10-0x1000], r1
  stdw [r10-0xff0], 0x40
  mov64 r3, r10
  add64 r3, -0x3a0
  mov64 r5, r10
  mov64 r1, r9
  mov64 r4, 0x3
  call fn_5bf8
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0
  ldxdw r8, [r10-0x800]
  sub64 r8, r7
  ldxdw r1, [r10-0x570]
  stxdw [r10-0x3a0], r1
  ldxdw r1, [r10-0x568]
  stxdw [r10-0x398], r1
  ldxdw r1, [r10-0x560]
  stxdw [r10-0x390], r1
  ldxdw r1, [r10-0x558]
  stxdw [r10-0x388], r1
  stxdw [r10-0x370], r8
  ldxdw r1, [r10-0x1a0]
  stxdw [r10-0x378], r1
  ldxdw r7, [r10-0x5b0]
  stxdw [r10-0x380], r7
  mov64 r2, r10
  add64 r2, -0x3a0
  mov64 r1, r9
  call fn_2608
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0
  jeq r7, -0x1, jmp_1ad30
  ldxdw r3, [r10-0x788]
  mov64 r2, r3
  add64 r2, r8
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  mov64 r1, 0x1
  jlt r2, r3, jmp_19de0
  mov64 r1, 0x0

jmp_19de0:
  add64 r7, 0x1
  stxdw [r10-0x5b0], r7
  and64 r1, 0x1
  jne r1, 0x0, jmp_195d8
  mov64 r1, r8
  ldxdw r2, [r10-0x788]
  add64 r1, r2
  stxdw [r10-0x5c8], r1
  ldxdw r1, [r10-0x438]
  mov64 r3, r1
  add64 r3, r8
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_19e60
  mov64 r2, 0x0

jmp_19e60:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  add64 r8, r1
  stxdw [r10-0x438], r8
  ldxdw r1, [r10-0x808]
  jne r1, 0x0, jmp_199a8
  ja jmp_1a370

jmp_19e98:
  ldxdw r3, [r10-0x5f0]
  mov64 r6, r2
  add64 r6, r3
  mov64 r0, 0x0
  stxdw [r10-0x7a8], r0
  mov64 r0, 0x1
  jlt r6, r2, jmp_19ed8
  mov64 r0, 0x0

jmp_19ed8:
  and64 r0, 0x1
  jne r0, 0x0, jmp_195d8
  mov64 r6, r5
  add64 r6, r4
  mov64 r0, 0x0
  stxdw [r10-0x7a8], r0
  mov64 r0, 0x1
  jlt r6, r5, jmp_19f20
  mov64 r0, 0x0

jmp_19f20:
  and64 r0, 0x1
  jne r0, 0x0, jmp_195d8
  add64 r4, r5
  ldxdw r5, [r10-0x5d8]
  mov64 r6, r4
  add64 r6, r5
  mov64 r0, 0x0
  stxdw [r10-0x7a8], r0
  mov64 r0, 0x1
  jlt r6, r4, jmp_19f78
  mov64 r0, 0x0

jmp_19f78:
  and64 r0, 0x1
  jne r0, 0x0, jmp_195d8
  add64 r3, r2
  add64 r5, r4
  mov64 r0, r3
  add64 r0, r5
  mov64 r4, 0x0
  stxdw [r10-0x7a8], r4
  mov64 r4, 0x1
  jlt r0, r3, jmp_19fd0
  mov64 r4, 0x0

jmp_19fd0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_195d8
  add64 r5, r3
  mov64 r6, 0xb
  ldxdw r7, [r10-0x600]
  jlt r7, r5, jmp_195e0
  sub64 r7, r5
  ldxdw r1, [r10-0x800]
  jlt r7, r1, jmp_198c8
  ldxdw r7, [r10-0x800]
  ja jmp_198c8

jmp_1a028:
  ldxdw r4, [r10-0x7e0]
  jle r4, r1, jmp_19af8

jmp_1a038:
  mov64 r2, 0x0
  ldxb r1, [r10-0x115]
  jeq r1, 0x0, jmp_19b08

jmp_1a050:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1a768

jmp_1a060:
  ldxdw r2, [r10-0x130]
  jeq r2, 0x0, jmp_19430
  ldxb r1, [r10-0x115]
  jne r1, 0x1, jmp_1a750
  mov64 r1, 0x1
  ldxdw r3, [r10-0x7e0]
  jlt r3, r2, jmp_19430
  ja jmp_1a768

jmp_1a0a0:
  ldxdw r4, [r10-0x5a8]
  ldxdw r1, [r10-0x808]
  stxdw [r10-0xff8], r1
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  ldxdw r2, [r10-0x810]
  jslt r2, 0x0, jmp_1a0e0
  ldxdw r1, [r10-0x7e8]

jmp_1a0e0:
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x3a0
  mov64 r5, r10
  ldxdw r2, [r10-0x818]
  ldxdw r3, [r10-0x820]
  call fn_277e8
  ldxw r1, [r10-0x3a0]
  jeq r1, 0x0, jmp_1a138
  ldxw r6, [r10-0x39c]
  ja jmp_195e0

jmp_1a138:
  ldxdw r1, [r10-0x390]
  ldxdw r7, [r10-0x398]
  stxdw [r10-0x5a8], r1
  ldxdw r1, [r10-0x5a0]
  mov64 r3, r1
  add64 r3, r7
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_1a190
  mov64 r2, 0x0

jmp_1a190:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  mov64 r2, r7
  add64 r2, r1
  stxdw [r10-0x5a0], r2
  ldxdw r1, [r10-0x420]
  mov64 r3, r1
  add64 r3, r7
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_1a1f8
  mov64 r2, 0x0

jmp_1a1f8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  mov64 r2, r7
  add64 r2, r1
  stxdw [r10-0x420], r2
  ldxdw r1, [r10-0x418]
  mov64 r3, r1
  add64 r3, r7
  mov64 r2, 0x0
  stxdw [r10-0x7a8], r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_1a260
  mov64 r2, 0x0

jmp_1a260:
  and64 r2, 0x1
  jne r2, 0x0, jmp_195d8
  mov64 r2, r7
  add64 r2, r1
  stxdw [r10-0x418], r2
  stxdw [r10-0x140], r7
  jeq r7, 0x0, jmp_1a370
  ldxdw r1, [r10-0x780]
  ldxdw r1, [r1+0x60]
  lddw r2, data_02c1
  call fn_5b70
  mov64 r6, 0x2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  stxdw [r10-0x7a8], r0
  jne r0, 0x1a, jmp_195e0
  ldxdw r1, [r10-0x780]
  ldxdw r4, [r1+0x50]
  ldxdw r1, [r1+0x58]
  stxdw [r10-0xff8], r7
  stxdw [r10-0x1000], r1
  mov64 r2, r10
  add64 r2, -0x778
  mov64 r5, r10
  ldxdw r1, [r10-0x798]
  ldxdw r3, [r10-0x7a0]
  call fn_1bfb8
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0

jmp_1a370:
  mov64 r3, 0x10
  ldxb r1, [r10-0x115]
  jne r1, 0x0, jmp_1a390
  mov64 r3, 0x20

jmp_1a390:
  mov64 r2, r10
  add64 r2, -0x110
  add64 r2, r3
  ldxdw r3, [r2+0x8]
  mov64 r4, 0x0
  stxdw [r10-0x7a8], r4
  mov64 r6, 0x1
  ldxdw r0, [r10-0x1a8]
  mov64 r7, 0x1
  jlt r3, r0, jmp_1a428
  mov64 r7, 0x0
  ldxdw r4, [r2+0x0]
  ldxdw r5, [r10-0x1b0]
  jge r4, r5, jmp_1a440

jmp_1a400:
  jeq r3, r0, jmp_1a450

jmp_1a408:
  mov64 r6, r7
  and64 r6, 0x1
  jne r6, 0x0, jmp_195d8
  ja jmp_1a460

jmp_1a428:
  ldxdw r4, [r2+0x0]
  ldxdw r5, [r10-0x1b0]
  jlt r4, r5, jmp_1a400

jmp_1a440:
  mov64 r6, 0x0
  jne r3, r0, jmp_1a408

jmp_1a450:
  and64 r6, 0x1
  jne r6, 0x0, jmp_195d8

jmp_1a460:
  sub64 r3, r0
  mov64 r0, 0x0
  stxdw [r10-0x7a8], r0
  mov64 r7, 0x1
  mov64 r0, 0x1
  jlt r4, r5, jmp_1a498
  mov64 r0, 0x0

jmp_1a498:
  sub64 r3, r0
  sub64 r4, r5
  stxdw [r2+0x0], r4
  stxdw [r2+0x8], r3
  mov64 r6, 0x50
  jne r1, 0x0, jmp_1a4d0
  mov64 r6, 0x60

jmp_1a4d0:
  mov64 r9, 0x70
  jne r1, 0x0, jmp_1a4e8
  mov64 r9, 0x80

jmp_1a4e8:
  mov64 r8, r10
  add64 r8, -0x110
  ldxdw r1, [r10-0x198]
  ldxh r3, [r10-0x11a]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  jne r1, 0x0, jmp_1a530
  mov64 r7, 0x0

jmp_1a530:
  and64 r7, 0x1
  jne r7, 0x0, jmp_195d8
  mov64 r1, r8
  add64 r1, r6
  ldxdw r2, [r1+0x8]
  ldxdw r3, [r1+0x0]
  mov64 r4, 0x0
  stxdw [r10-0x7a8], r4
  mov64 r4, 0x1
  jlt r3, r0, jmp_1a5a8
  mov64 r4, 0x0
  jne r2, 0x0, jmp_1a5b0

jmp_1a590:
  and64 r4, 0x1
  jne r4, 0x0, jmp_195d8
  ja jmp_1a5c8

jmp_1a5a8:
  jeq r2, 0x0, jmp_1a590

jmp_1a5b0:
  mov64 r4, 0x0
  and64 r4, 0x1
  jne r4, 0x0, jmp_195d8

jmp_1a5c8:
  add64 r8, r9
  mov64 r4, r3
  sub64 r4, r0
  stxdw [r1+0x0], r4
  mov64 r4, 0x0
  stxdw [r10-0x7a8], r4
  mov64 r4, 0x1
  mov64 r5, 0x1
  jlt r3, r0, jmp_1a618
  mov64 r5, 0x0

jmp_1a618:
  sub64 r2, r5
  stxdw [r1+0x8], r2
  ldxdw r1, [r8+0x0]
  ldxdw r2, [r10-0x188]
  jlt r1, r2, jmp_1a678
  mov64 r4, 0x0
  ldxdw r3, [r8+0x8]
  jne r3, 0x0, jmp_1a688

jmp_1a658:
  and64 r4, 0x1
  mov64 r6, 0x4
  jne r4, 0x0, jmp_195e0
  ja jmp_1a6a8

jmp_1a678:
  ldxdw r3, [r8+0x8]
  jeq r3, 0x0, jmp_1a658

jmp_1a688:
  mov64 r4, 0x0
  and64 r4, 0x1
  mov64 r6, 0x4
  jne r4, 0x0, jmp_195e0

jmp_1a6a8:
  mov64 r4, 0x1
  jlt r1, r2, jmp_1a6c0
  mov64 r4, 0x0

jmp_1a6c0:
  sub64 r1, r2
  stxdw [r8+0x0], r1
  sub64 r3, r4
  stxdw [r8+0x8], r3
  mov64 r2, r10
  add64 r2, -0x3a0
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jeq r0, 0x0, jmp_1a828

jmp_1a720:
  mov64 r1, 0x10
  stxdw [r10-0x7a8], r1
  jne r0, 0x1, jmp_1a748
  mov64 r1, 0x1
  stxdw [r10-0x7a8], r1

jmp_1a748:
  ja jmp_195e0

jmp_1a750:
  mov64 r1, 0x0
  ldxdw r3, [r10-0x7e0]
  jgt r3, r2, jmp_19430

jmp_1a768:
  mov64 r5, 0x13
  ldxb r2, [r10-0x116]
  jne r2, 0x1, jmp_19430
  ldxdw r3, [r10-0x180]
  jeq r3, 0x0, jmp_19430
  mov64 r2, 0x1
  mov64 r4, 0x1
  ldxdw r5, [r10-0x7e0]
  jlt r5, r3, jmp_1a7f0
  mov64 r4, 0x0
  ldxdw r5, [r10-0x7e0]
  jle r5, r3, jmp_1a800

jmp_1a7c8:
  jne r1, 0x0, jmp_1a810

jmp_1a7d0:
  mov64 r2, r4
  mov64 r5, 0x1e
  jeq r2, 0x1, jmp_19128
  ja jmp_19430

jmp_1a7f0:
  ldxdw r5, [r10-0x7e0]
  jgt r5, r3, jmp_1a7c8

jmp_1a800:
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_1a7d0

jmp_1a810:
  mov64 r5, 0x1e
  jeq r2, 0x1, jmp_19128
  ja jmp_19430

jmp_1a828:
  ldxdw r6, [r10-0x380]
  ldxdw r1, [r10-0x7b8]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1a870
  ldxdw r1, [r10-0x4f8]
  ldxdw r3, [r10-0x500]
  ldxdw r7, [r10-0x3f0]
  jsle r6, r7, jmp_1a990
  ja jmp_1a998

jmp_1a870:
  mov64 r8, 0x1
  ldxdw r7, [r10-0x3f0]
  mov64 r2, 0x1
  jsgt r7, 0x0, jmp_1ac80
  mov64 r2, 0x0
  mov64 r1, r6
  sub64 r1, r7
  mov64 r3, 0x1
  jsge r1, r6, jmp_1aca0

jmp_1a8b8:
  xor64 r2, r3
  jne r2, 0x0, jmp_1acb8

jmp_1a8c8:
  jsgt r6, r7, jmp_1a8d8

jmp_1a8d0:
  mov64 r1, 0x0

jmp_1a8d8:
  ldxdw r3, [r10-0x3f8]
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  ldxdw r3, [r10-0x500]
  mov64 r2, r3
  add64 r2, r0
  mov64 r4, 0x1
  jlt r2, r3, jmp_1a928
  mov64 r4, 0x0

jmp_1a928:
  ldxdw r3, [r10-0x4f8]
  mov64 r5, r3
  add64 r5, r1
  add64 r5, r4
  jlt r5, r3, jmp_1ace8
  mov64 r8, 0x0
  jne r5, r3, jmp_1acf0

jmp_1a960:
  mov64 r3, -0x1
  mov64 r1, -0x1
  jne r4, 0x0, jmp_1ad10

jmp_1a978:
  mov64 r1, r5
  jeq r4, 0x0, jmp_1ad18

jmp_1a988:
  jsgt r6, r7, jmp_1a998

jmp_1a990:
  mov64 r6, r7

jmp_1a998:
  stxdw [r10-0x500], r3
  stxdw [r10-0x4f8], r1
  stxdw [r10-0x3f0], r6
  ldxdw r9, [r10-0x7d0]
  and64 r9, 0x6
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  mov64 r1, 0x1
  jeq r9, 0x4, jmp_1a9e8
  mov64 r1, 0x0

jmp_1a9e8:
  ldxdw r2, [r10-0x198]
  ldxb r3, [r10-0x114]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x790]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x570
  mov64 r4, r10
  add64 r4, -0x50
  mov64 r5, r10
  call fn_2a9a8
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r6, r0
  jne r0, 0x0, jmp_195e0
  ldxdw r1, [r10-0x7e0]
  stxdw [r10-0x170], r1
  stb [r10-0x113], 0x0
  mov64 r2, r10
  add64 r2, -0x3a0
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  lddw r1, data_0341
  mov64 r3, 0x0
  mov64 r4, 0x28
  call sol_get_sysvar
  jne r0, 0x0, jmp_1a720
  ldxdw r1, [r10-0x380]
  stxdw [r10-0x168], r1
  ldxdw r1, [r10-0x828]
  stxdw [r10-0x148], r1
  ldxdw r1, [r10-0x7f8]
  stxdw [r10-0x150], r1
  ldxdw r1, [r10-0x7f0]
  stxdw [r10-0x158], r1
  ldxdw r1, [r10-0x800]
  stxdw [r10-0x160], r1
  ldxdw r1, [r10-0x790]
  stxb [r10-0x112], r1
  mov64 r1, r10
  add64 r1, -0x620
  call fn_2a1d0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  mov64 r6, r0
  jne r0, 0x0, jmp_195e0
  mov64 r2, r10
  add64 r2, -0x1d0
  ldxdw r1, [r10-0x7b0]
  call fn_2818
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0
  mov64 r2, r10
  add64 r2, -0x570
  ldxdw r1, [r10-0x7c0]
  call fn_2458
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0
  mov64 r2, r10
  add64 r2, -0x110
  ldxdw r1, [r10-0x7d8]
  call fn_3370
  mov64 r6, r1
  stxdw [r10-0x7a8], r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_195e0
  mov64 r2, r10
  add64 r2, -0x620
  ldxdw r1, [r10-0x7c8]
  call fn_35c0
  mov64 r4, r1
  ja jmp_18410

jmp_1ac80:
  mov64 r1, r6
  sub64 r1, r7
  mov64 r3, 0x1
  jslt r1, r6, jmp_1a8b8

jmp_1aca0:
  mov64 r3, 0x0
  xor64 r2, r3
  jeq r2, 0x0, jmp_1a8c8

jmp_1acb8:
  arsh64 r1, 0x3f
  lddw r2, -0x8000000000000000
  xor64 r1, r2
  jsle r6, r7, jmp_1a8d0
  ja jmp_1a8d8

jmp_1ace8:
  jeq r5, r3, jmp_1a960

jmp_1acf0:
  mov64 r4, r8
  mov64 r3, -0x1
  mov64 r1, -0x1
  jeq r4, 0x0, jmp_1a978

jmp_1ad10:
  jne r4, 0x0, jmp_1a988

jmp_1ad18:
  mov64 r3, r2
  jsle r6, r7, jmp_1a990
  ja jmp_1a998

jmp_1ad30:
  mov64 r1, 0x0
  stxdw [r10-0x7a8], r1
  ja jmp_195d8

fn_1ad48:
  mov64 r9, r5
  mov64 r7, r4
  mov64 r6, r3
  mov64 r8, r2
  lddw r2, data_02c1
  stxdw [r10-0xff8], r2
  stxdw [r10-0xf8], r1
  stxdw [r10-0x1000], r1
  stdw [r10-0xff0], 0x52
  mov64 r5, r10
  mov64 r1, r7
  mov64 r2, r8
  lddw r3, data_0828
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1b518
  ldxdw r3, [r9-0xff8]
  ldxdw r9, [r9-0x1000]
  mov64 r2, r7
  add64 r2, 0x8
  stxdw [r10-0xb8], r2
  sth [r10-0xb0], 0x1
  ldxb r1, [r7+0x0]
  jne r1, 0xff, jmp_1b520
  stxdw [r10-0x120], r3
  add64 r6, 0x8
  stxdw [r10-0x100], r2
  stxdw [r10-0xf0], r2
  mov64 r1, r7
  add64 r1, 0x48
  stxdw [r10-0x108], r1
  stxdw [r10-0xe8], r1
  ldxdw r1, [r7+0x50]
  stxdw [r10-0xe0], r1
  mov64 r1, r7
  add64 r1, 0x28
  stxdw [r10-0x110], r1
  stxdw [r10-0xd0], r1
  mov64 r1, r7
  add64 r1, 0x58
  stxdw [r10-0x118], r1
  stxdw [r10-0xd8], r1
  stdw [r10-0xc8], 0x0
  ldxw r1, [r7+0x1]
  stxw [r10-0xc0], r1
  sth [r10-0x98], 0x614
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x96], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x8e], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x86], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0x7e], r1
  stb [r10-0x76], 0x1
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x75], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x6d], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x65], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0x5d], r1
  mov64 r1, r10
  add64 r1, -0x98
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x43
  stdw [r10-0x18], 0x1
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0xf0
  mov64 r3, 0x1
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  lddw r1, data_02c1
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x1000], r1
  stdw [r10-0xff0], 0xa5
  mov64 r5, r10
  mov64 r1, r9
  mov64 r2, r8
  lddw r3, data_0838
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1b518
  ldxdw r3, [r10-0x100]
  stxdw [r10-0xa8], r3
  mov64 r1, r9
  add64 r1, 0x8
  stxdw [r10-0xb8], r1
  sth [r10-0xa0], 0x0
  sth [r10-0xb0], 0x1
  ldxb r2, [r9+0x0]
  jne r2, 0xff, jmp_1b538
  stxdw [r10-0x98], r1
  mov64 r1, r9
  add64 r1, 0x48
  stxdw [r10-0x90], r1
  ldxdw r1, [r9+0x50]
  mov64 r2, r9
  add64 r2, 0x28
  stxdw [r10-0x78], r2
  mov64 r2, r9
  add64 r2, 0x58
  stxdw [r10-0x80], r2
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x0
  ldxw r1, [r9+0x1]
  ldxdw r2, [r10-0x108]
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r3
  stxw [r10-0x68], r1
  ldxdw r1, [r7+0x50]
  ldxdw r2, [r10-0x110]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x118]
  stxdw [r10-0x48], r2
  stxdw [r10-0x50], r1
  stdw [r10-0x38], 0x0
  ldxw r1, [r7+0x1]
  stxw [r10-0x30], r1
  stb [r10-0x28], 0x12
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x27], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x1f], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x17], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0xf], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0xe8], r1
  mov64 r9, r8
  lddw r8, data_02c1
  stxdw [r10-0xf0], r8
  stdw [r10-0xd0], 0x21
  stdw [r10-0xe0], 0x2
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  stxdw [r10-0xff8], r8
  ldxdw r1, [r10-0xf8]
  stxdw [r10-0x1000], r1
  stdw [r10-0xff0], 0xa5
  mov64 r5, r10
  ldxdw r8, [r10-0x120]
  mov64 r1, r8
  mov64 r2, r9
  lddw r3, data_0848
  mov64 r4, 0x1
  call fn_5bf8
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1b518
  ldxdw r3, [r10-0x100]
  stxdw [r10-0xa8], r3
  mov64 r1, r8
  add64 r1, 0x8
  stxdw [r10-0xb8], r1
  sth [r10-0xa0], 0x0
  sth [r10-0xb0], 0x1
  ldxb r2, [r8+0x0]
  jne r2, 0xff, jmp_1b538
  stxdw [r10-0x98], r1
  mov64 r1, r8
  add64 r1, 0x48
  stxdw [r10-0x90], r1
  ldxdw r1, [r8+0x50]
  mov64 r2, r8
  add64 r2, 0x28
  stxdw [r10-0x78], r2
  mov64 r2, r8
  add64 r2, 0x58
  stxdw [r10-0x80], r2
  stxdw [r10-0x88], r1
  stdw [r10-0x70], 0x0
  ldxw r1, [r8+0x1]
  ldxdw r2, [r10-0x108]
  stxdw [r10-0x58], r2
  stxdw [r10-0x60], r3
  stxw [r10-0x68], r1
  ldxdw r1, [r7+0x50]
  ldxdw r2, [r10-0x110]
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x118]
  stxdw [r10-0x48], r2
  stxdw [r10-0x50], r1
  stdw [r10-0x38], 0x0
  ldxw r1, [r7+0x1]
  stxw [r10-0x30], r1
  stb [r10-0x28], 0x12
  ldxdw r1, [r6+0x0]
  stxdw [r10-0x27], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x1f], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x17], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0xf], r1
  mov64 r1, r10
  add64 r1, -0x28
  stxdw [r10-0xd8], r1
  mov64 r1, r10
  add64 r1, -0xb8
  stxdw [r10-0xe8], r1
  lddw r1, data_02c1
  stxdw [r10-0xf0], r1
  stdw [r10-0xd0], 0x21
  stdw [r10-0xe0], 0x2
  mov64 r1, r10
  add64 r1, -0xf0
  mov64 r2, r10
  add64 r2, -0x98
  mov64 r3, 0x2
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  mov64 r0, 0x1a

jmp_1b518:
  exit

jmp_1b520:
  mov64 r0, 0xb
  mov64 r1, 0x1
  ja jmp_1b518

jmp_1b538:
  mov64 r0, 0xb
  mov64 r1, 0x2
  ja jmp_1b518

fn_1b550:
  mov64 r0, 0x3
  ldxdw r5, [r2+0x50]
  jne r5, 0xa5, jmp_1b600
  ldxdw r5, [r2+0x28]
  lddw r6, -0x6c5e9a281e0922fa
  jne r5, r6, jmp_1b600
  ldxdw r5, [r2+0x30]
  lddw r6, -0x53861431b91e3427
  jne r5, r6, jmp_1b600
  ldxdw r5, [r2+0x38]
  lddw r6, -0x6ec8a4a0127a4be4
  jne r5, r6, jmp_1b600
  ldxdw r5, [r2+0x40]
  lddw r6, -0x56ff00817a0a73c6
  jne r5, r6, jmp_1b600
  mov64 r0, 0xb
  ldxb r5, [r2+0x0]
  jgt r5, 0x1, jmp_1b620

jmp_1b600:
  stxw [r1+0x4], r0
  stw [r1+0x8], 0x0
  stw [r1+0x0], 0x1

jmp_1b618:
  exit

jmp_1b620:
  ldxdw r0, [r2+0x70]
  ldxdw r6, [r2+0x68]
  ldxdw r7, [r2+0x60]
  add64 r5, -0x1
  stxb [r2+0x0], r5
  ldxdw r8, [r2+0x58]
  ldxdw r9, [r3+0x0]
  jne r8, r9, jmp_1b710
  ldxdw r8, [r3+0x8]
  jne r7, r8, jmp_1b710
  ldxdw r7, [r3+0x10]
  jne r6, r7, jmp_1b710
  ldxdw r3, [r3+0x18]
  jne r0, r3, jmp_1b710
  ldxdw r3, [r4+0x0]
  ldxdw r0, [r2+0x78]
  jne r0, r3, jmp_1b710
  ldxdw r3, [r4+0x8]
  ldxdw r0, [r2+0x80]
  jne r0, r3, jmp_1b710
  ldxdw r3, [r4+0x10]
  ldxdw r0, [r2+0x88]
  jne r0, r3, jmp_1b710
  ldxdw r3, [r4+0x18]
  ldxdw r4, [r2+0x90]
  jne r4, r3, jmp_1b710
  ldxdw r3, [r2+0x98]
  stxdw [r1+0x8], r3
  stw [r1+0x0], 0x0
  ja jmp_1b720

jmp_1b710:
  stw [r1+0x8], 0x2
  stdw [r1+0x0], 0x1

jmp_1b720:
  and64 r5, 0xff
  add64 r5, 0x1
  mov64 r1, r5
  and64 r1, 0xff
  jne r1, r5, jmp_1b758
  stxb [r2+0x0], r5
  ja jmp_1b618

jmp_1b758:
  lddw r1, data_0678
  call fn_2bcf8

fn_1b770:
  mov64 r5, r1
  mov64 r0, 0x3
  mov64 r1, 0x0
  ldxdw r6, [r4+0x50]
  jne r6, 0xa5, jmp_1bbf8
  ldxdw r6, [r4+0x28]
  lddw r7, -0x6c5e9a281e0922fa
  jne r6, r7, jmp_1bbf8
  ldxdw r6, [r4+0x30]
  lddw r7, -0x53861431b91e3427
  jne r6, r7, jmp_1bbf8
  ldxdw r6, [r4+0x38]
  lddw r7, -0x6ec8a4a0127a4be4
  jne r6, r7, jmp_1bbf8
  ldxdw r6, [r4+0x40]
  lddw r7, -0x56ff00817a0a73c6
  jne r6, r7, jmp_1bbf8
  mov64 r0, 0xb
  ldxb r6, [r4+0x0]
  jlt r6, 0x2, jmp_1bbf8
  add64 r6, -0x1
  stxb [r4+0x0], r6
  and64 r6, 0xff
  add64 r6, 0x1
  mov64 r1, r6
  and64 r1, 0xff
  jne r1, r6, jmp_1bc18
  stxb [r4+0x0], r6
  ldxb r1, [r4+0xc4]
  jne r1, 0x2, jmp_1bbf0
  mov64 r6, r4
  mov64 r7, r3
  mov64 r8, r2
  mov64 r1, r2
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r5
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1bbf8
  stxb [r10-0x451], r1
  mov64 r1, r10
  add64 r1, -0x451
  stxdw [r10-0x440], r1
  lddw r1, str_0361
  stxdw [r10-0x450], r1
  stdw [r10-0x438], 0x1
  stdw [r10-0x448], 0x6
  mov64 r1, r10
  add64 r1, -0x450
  stxdw [r10-0x430], r1
  stdw [r10-0x428], 0x2
  mov64 r1, r8
  mov64 r2, r1
  add64 r2, 0x8
  stxdw [r10-0x400], r2
  mov64 r3, r7
  mov64 r4, r3
  add64 r4, 0x8
  stxdw [r10-0x410], r4
  mov64 r5, r6
  add64 r5, 0x8
  stxdw [r10-0x420], r5
  sth [r10-0x3f8], 0x100
  sth [r10-0x408], 0x0
  sth [r10-0x418], 0x1
  ldxb r0, [r6+0x0]
  jne r0, 0xff, jmp_1bc00
  mov64 r0, r6
  add64 r0, 0x28
  mov64 r7, r6
  add64 r7, 0x58
  stxdw [r10-0x340], r5
  mov64 r5, r6
  add64 r5, 0x48
  stxdw [r10-0x338], r5
  ldxdw r5, [r6+0x50]
  stxdw [r10-0x320], r0
  stxdw [r10-0x328], r7
  stxdw [r10-0x330], r5
  stdw [r10-0x318], 0x0
  ldxw r5, [r6+0x1]
  mov64 r0, r3
  add64 r0, 0x48
  stxdw [r10-0x300], r0
  stxdw [r10-0x308], r4
  stxw [r10-0x310], r5
  ldxdw r4, [r3+0x50]
  mov64 r5, r3
  add64 r5, 0x28
  stxdw [r10-0x2e8], r5
  mov64 r5, r3
  add64 r5, 0x58
  stxdw [r10-0x2f0], r5
  stxdw [r10-0x2f8], r4
  stdw [r10-0x2e0], 0x0
  ldxw r3, [r3+0x1]
  mov64 r4, r1
  add64 r4, 0x48
  stxdw [r10-0x2c8], r4
  stxdw [r10-0x2d0], r2
  stxw [r10-0x2d8], r3
  mov64 r2, r1
  add64 r2, 0x28
  ldxdw r3, [r1+0x50]
  stxdw [r10-0x2b0], r2
  mov64 r2, r1
  add64 r2, 0x58
  stxdw [r10-0x2b8], r2
  stxdw [r10-0x2c0], r3
  stdw [r10-0x2a8], 0x0
  ldxw r1, [r1+0x1]
  stxw [r10-0x2a0], r1
  stb [r10-0x29], 0xb
  mov64 r1, r10
  add64 r1, -0x29
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x420
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x1
  stdw [r10-0x18], 0x3
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x340
  mov64 r4, r10
  add64 r4, -0x430
  mov64 r3, 0x3
  mov64 r5, 0x1
  call sol_invoke_signed_c

jmp_1bbf0:
  mov64 r0, 0x1a

jmp_1bbf8:
  exit

jmp_1bc00:
  mov64 r0, 0xb
  mov64 r1, 0x3
  ja jmp_1bbf8

jmp_1bc18:
  lddw r1, data_0678
  call fn_2bcf8

fn_1bc30:
  mov64 r8, r4
  mov64 r7, r3
  mov64 r6, r2
  mov64 r4, r1
  mov64 r1, r6
  lddw r2, data_0750
  mov64 r3, 0x1
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1bf98
  stxb [r10-0x451], r1
  mov64 r1, r10
  add64 r1, -0x451
  stxdw [r10-0x440], r1
  lddw r1, str_0361
  stxdw [r10-0x450], r1
  stdw [r10-0x438], 0x1
  stdw [r10-0x448], 0x6
  mov64 r1, r10
  add64 r1, -0x450
  stxdw [r10-0x430], r1
  stdw [r10-0x428], 0x2
  mov64 r1, r6
  add64 r1, 0x8
  stxdw [r10-0x400], r1
  mov64 r2, r7
  add64 r2, 0x8
  stxdw [r10-0x410], r2
  mov64 r3, r8
  add64 r3, 0x8
  stxdw [r10-0x420], r3
  sth [r10-0x3f8], 0x100
  sth [r10-0x408], 0x0
  sth [r10-0x418], 0x1
  ldxb r4, [r8+0x0]
  jne r4, 0xff, jmp_1bfa0
  stxdw [r10-0x340], r3
  mov64 r3, r8
  add64 r3, 0x48
  stxdw [r10-0x338], r3
  ldxdw r3, [r8+0x50]
  mov64 r4, r8
  add64 r4, 0x28
  stxdw [r10-0x320], r4
  mov64 r4, r8
  add64 r4, 0x58
  stxdw [r10-0x328], r4
  stxdw [r10-0x330], r3
  stdw [r10-0x318], 0x0
  ldxw r3, [r8+0x1]
  mov64 r4, r7
  add64 r4, 0x48
  stxdw [r10-0x300], r4
  stxdw [r10-0x308], r2
  stxw [r10-0x310], r3
  ldxdw r2, [r7+0x50]
  mov64 r3, r7
  add64 r3, 0x28
  stxdw [r10-0x2e8], r3
  mov64 r3, r7
  add64 r3, 0x58
  stxdw [r10-0x2f0], r3
  stxdw [r10-0x2f8], r2
  stdw [r10-0x2e0], 0x0
  ldxw r2, [r7+0x1]
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x2c8], r3
  stxdw [r10-0x2d0], r1
  stxw [r10-0x2d8], r2
  mov64 r1, r6
  add64 r1, 0x28
  ldxdw r2, [r6+0x50]
  stxdw [r10-0x2b0], r1
  mov64 r1, r6
  add64 r1, 0x58
  stxdw [r10-0x2b8], r1
  stxdw [r10-0x2c0], r2
  stdw [r10-0x2a8], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x2a0], r1
  stb [r10-0x29], 0xa
  mov64 r1, r10
  add64 r1, -0x29
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x420
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x1
  stdw [r10-0x18], 0x3
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x340
  mov64 r4, r10
  add64 r4, -0x430
  mov64 r3, 0x3
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a

jmp_1bf98:
  exit

jmp_1bfa0:
  mov64 r0, 0xb
  mov64 r1, 0x3
  ja jmp_1bf98

fn_1bfb8:
  mov64 r6, r3
  mov64 r9, r2
  mov64 r8, r1
  mov64 r0, 0x0
  mov64 r1, 0x2
  ldxdw r2, [r9+0x100]
  ldxdw r3, [r4+0x8]
  jne r3, r2, jmp_1c168
  ldxdw r2, [r9+0x108]
  ldxdw r3, [r4+0x10]
  jne r3, r2, jmp_1c168
  ldxdw r2, [r9+0x110]
  ldxdw r3, [r4+0x18]
  jne r3, r2, jmp_1c168
  ldxdw r2, [r9+0x118]
  ldxdw r3, [r4+0x20]
  jne r3, r2, jmp_1c168
  stxdw [r10-0x468], r4
  ldxdw r1, [r5-0xff8]
  stxdw [r10-0x470], r1
  ldxdw r7, [r5-0x1000]
  mov64 r1, r7
  lddw r2, data_0848
  mov64 r3, 0x1
  mov64 r4, r8
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_1c158
  add64 r9, 0x100
  ldxdw r1, [r6+0x20]
  stxdw [r10-0x330], r1
  ldxdw r1, [r6+0x18]
  stxdw [r10-0x338], r1
  ldxdw r1, [r6+0x10]
  stxdw [r10-0x340], r1
  ldxdw r1, [r6+0x8]
  stxdw [r10-0x348], r1
  mov64 r1, r10
  add64 r1, -0x428
  mov64 r4, r10
  add64 r4, -0x348
  mov64 r2, r7
  mov64 r3, r9
  call fn_1b550
  ldxw r1, [r10-0x428]
  jne r1, 0x1, jmp_1c170
  ldxw r1, [r10-0x420]
  ldxw r0, [r10-0x424]
  ja jmp_1c168

jmp_1c158:
  mov64 r1, r0
  rsh64 r1, 0x20

jmp_1c168:
  exit

jmp_1c170:
  mov64 r1, r6
  lddw r2, data_0750
  mov64 r3, 0x1
  mov64 r4, r8
  call fn_05d0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1c168
  ldxdw r3, [r10-0x468]
  mov64 r4, r3
  add64 r4, 0x8
  mov64 r2, r6
  add64 r2, 0x8
  stxb [r10-0x459], r1
  mov64 r1, r10
  add64 r1, -0x459
  stxdw [r10-0x448], r1
  lddw r1, str_0361
  stxdw [r10-0x458], r1
  stdw [r10-0x440], 0x1
  stdw [r10-0x450], 0x6
  mov64 r1, r10
  add64 r1, -0x458
  stxdw [r10-0x438], r1
  stdw [r10-0x430], 0x2
  stxdw [r10-0x408], r2
  stxdw [r10-0x428], r4
  mov64 r1, r7
  add64 r1, 0x8
  stxdw [r10-0x418], r1
  sth [r10-0x400], 0x100
  sth [r10-0x410], 0x1
  sth [r10-0x420], 0x1
  ldxb r5, [r3+0x0]
  ldxb r0, [r7+0x0]
  and64 r0, r5
  jne r0, 0xff, jmp_1c4f0
  stxdw [r10-0x348], r4
  mov64 r4, r3
  add64 r4, 0x48
  stxdw [r10-0x340], r4
  ldxdw r4, [r3+0x50]
  mov64 r5, r3
  add64 r5, 0x28
  stxdw [r10-0x328], r5
  mov64 r5, r3
  add64 r5, 0x58
  stxdw [r10-0x330], r5
  stxdw [r10-0x338], r4
  stdw [r10-0x320], 0x0
  ldxw r3, [r3+0x1]
  mov64 r4, r7
  add64 r4, 0x48
  stxdw [r10-0x308], r4
  stxdw [r10-0x310], r1
  stxw [r10-0x318], r3
  ldxdw r1, [r7+0x50]
  mov64 r3, r7
  add64 r3, 0x28
  stxdw [r10-0x2f0], r3
  mov64 r3, r7
  add64 r3, 0x58
  stxdw [r10-0x2f8], r3
  stxdw [r10-0x300], r1
  stdw [r10-0x2e8], 0x0
  ldxw r1, [r7+0x1]
  mov64 r3, r6
  add64 r3, 0x48
  stxdw [r10-0x2d0], r3
  stxdw [r10-0x2d8], r2
  stxw [r10-0x2e0], r1
  mov64 r1, r6
  add64 r1, 0x28
  ldxdw r2, [r6+0x50]
  stxdw [r10-0x2b8], r1
  mov64 r1, r6
  add64 r1, 0x58
  stxdw [r10-0x2c0], r1
  stxdw [r10-0x2c8], r2
  stdw [r10-0x2b0], 0x0
  ldxw r1, [r6+0x1]
  stxw [r10-0x2a8], r1
  ldxdw r1, [r10-0x470]
  stxdw [r10-0x30], r1
  stb [r10-0x31], 0x7
  mov64 r1, r10
  add64 r1, -0x31
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x428
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0x9
  stdw [r10-0x18], 0x3
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x348
  mov64 r4, r10
  add64 r4, -0x438
  mov64 r3, 0x3
  mov64 r5, 0x1
  call sol_invoke_signed_c
  mov64 r0, 0x1a
  ja jmp_1c168

jmp_1c4f0:
  mov64 r0, 0xb
  mov64 r1, 0x3
  ja jmp_1c168

fn_1c508:
  mov64 r9, r5
  mov64 r7, r2
  mov64 r6, r1
  jne r3, 0x9, jmp_1cb28
  stxdw [r10-0x898], r4
  ldxdw r2, [r7+0x10]
  mov64 r1, r10
  add64 r1, -0x370
  stxdw [r10-0x8a0], r2
  mov64 r3, r6
  call fn_3820
  ldxw r1, [r10-0x36c]
  ldxw r0, [r10-0x370]
  ldxb r8, [r10-0x21e]
  jeq r8, 0x2, jmp_1cb38
  mov64 r3, r10
  add64 r3, -0x878
  mov64 r2, r10
  add64 r2, -0x368
  stxdw [r10-0x888], r6
  mov64 r6, r1
  mov64 r1, r3
  mov64 r3, 0x149
  stxdw [r10-0x890], r7
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x21d]
  stxw [r10-0x72d], r1
  ldxb r1, [r10-0x219]
  stxb [r10-0x729], r1
  stxb [r10-0x72e], r8
  stxw [r10-0x87c], r6
  stxw [r10-0x880], r7
  ldxdw r7, [r10-0x890]
  ldxb r6, [r10-0x21f]
  stxb [r10-0x72f], r6
  ldxdw r2, [r7+0x18]
  mov64 r1, r10
  add64 r1, -0x370
  ldxdw r3, [r10-0x888]
  call fn_68d0
  ldxw r1, [r10-0x370]
  jne r1, 0x1, jmp_1c678

jmp_1c660:
  ldxw r1, [r10-0x368]
  ldxw r0, [r10-0x36c]
  ja jmp_1cb38

jmp_1c678:
  stxdw [r10-0x8a8], r6
  ldxw r6, [r10-0x368]
  mov64 r1, r10
  add64 r1, -0x724
  mov64 r2, r10
  add64 r2, -0x364
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x728], r6
  ldxdw r2, [r7+0x20]
  mov64 r1, r10
  add64 r1, -0x370
  ldxdw r3, [r10-0x888]
  call fn_3a90
  ldxw r1, [r10-0x36c]
  ldxw r0, [r10-0x370]
  ldxb r8, [r10-0x1a7]
  jeq r8, 0x2, jmp_1cb38
  mov64 r3, r10
  add64 r3, -0x670
  mov64 r2, r10
  add64 r2, -0x368
  mov64 r6, r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  mov64 r7, r0
  call fn_2c060
  ldxw r1, [r10-0x1a6]
  stxw [r10-0x4ae], r1
  ldxh r1, [r10-0x1a2]
  stxh [r10-0x4aa], r1
  stxw [r10-0x674], r6
  stxw [r10-0x678], r7
  mov64 r1, 0x18
  stxb [r10-0x4af], r8
  and64 r8, 0x1
  jne r8, 0x0, jmp_1cb00
  mov64 r1, 0x3
  ldxdw r6, [r10-0x890]
  ldxdw r8, [r6+0x0]
  ldxb r2, [r8+0x1]
  jeq r2, 0x0, jmp_1cb00
  ldxdw r2, [r8+0x8]
  ldxdw r3, [r10-0x678]
  jne r2, r3, jmp_1cb00
  ldxdw r2, [r10-0x670]
  ldxdw r3, [r8+0x10]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x668]
  ldxdw r3, [r8+0x18]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x660]
  ldxdw r3, [r8+0x20]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r6+0x8]
  ldxb r3, [r2+0x1]
  jeq r3, 0x0, jmp_1cb00
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r10-0x800]
  jne r3, r4, jmp_1cb00
  ldxdw r3, [r10-0x7f8]
  ldxdw r4, [r2+0x10]
  jne r4, r3, jmp_1cb00
  ldxdw r3, [r10-0x7f0]
  ldxdw r4, [r2+0x18]
  jne r4, r3, jmp_1cb00
  ldxdw r3, [r10-0x7e8]
  ldxdw r2, [r2+0x20]
  jne r2, r3, jmp_1cb00
  ldxdw r1, [r6+0x40]
  lddw r2, data_02c1
  call fn_5b70
  mov64 r1, 0x2
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x1a, jmp_1cb38
  mov64 r1, 0x10
  ldxdw r2, [r10-0x898]
  jeq r2, 0x0, jmp_1cb00
  ldxdw r7, [r6+0x38]
  ldxdw r2, [r7+0x8]
  ldxdw r3, [r10-0x780]
  jne r2, r3, jmp_1cb00
  ldxdw r2, [r10-0x778]
  ldxdw r3, [r7+0x10]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x770]
  ldxdw r3, [r7+0x18]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x768]
  ldxdw r3, [r7+0x20]
  jne r3, r2, jmp_1cb00
  ldxdw r4, [r6+0x30]
  ldxdw r2, [r4+0x8]
  ldxdw r3, [r10-0x760]
  jne r2, r3, jmp_1cb00
  ldxdw r2, [r10-0x758]
  ldxdw r3, [r4+0x10]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x750]
  ldxdw r3, [r4+0x18]
  jne r3, r2, jmp_1cb00
  ldxdw r2, [r10-0x748]
  ldxdw r3, [r4+0x20]
  jne r3, r2, jmp_1cb00
  stxdw [r10-0x8b0], r4
  jne r9, 0x0, jmp_1c9f8
  mov64 r1, 0x1a
  mov64 r0, 0x0
  ldxdw r2, [r10-0x898]
  jlt r2, 0x3b9aca00, jmp_1cb38

jmp_1c9f8:
  mov64 r3, r10
  add64 r3, -0x780
  ldxdw r2, [r6+0x28]
  mov64 r1, r10
  add64 r1, -0x370
  mov64 r4, r10
  add64 r4, -0x678
  stxdw [r10-0x8b8], r2
  mov64 r6, r3
  call fn_1b550
  ldxw r1, [r10-0x370]
  jne r1, 0x0, jmp_1c660
  ldxdw r2, [r10-0x8a0]
  ldxdw r1, [r2+0x20]
  stxdw [r10-0x358], r1
  ldxdw r1, [r2+0x18]
  stxdw [r10-0x360], r1
  ldxdw r1, [r2+0x10]
  stxdw [r10-0x368], r1
  ldxdw r1, [r2+0x8]
  stxdw [r10-0x370], r1
  mov64 r1, r10
  add64 r1, -0x460
  mov64 r4, r10
  add64 r4, -0x370
  ldxdw r2, [r10-0x8b0]
  mov64 r3, r6
  call fn_1b550
  ldxw r1, [r10-0x460]
  jeq r1, 0x0, jmp_1cb10
  ldxw r1, [r10-0x458]
  ldxw r0, [r10-0x45c]
  ja jmp_1cb38

jmp_1cb00:
  mov64 r0, 0x0
  ja jmp_1cb38

jmp_1cb10:
  ldxdw r1, [r10-0x458]
  ldxdw r2, [r10-0x6a0]
  jge r1, r2, jmp_1cb40

jmp_1cb28:
  mov64 r0, 0x0
  mov64 r1, 0x2

jmp_1cb38:
  exit

jmp_1cb40:
  mov64 r1, r10
  add64 r1, -0x728
  call fn_1e200
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1d250
  ldxdw r2, [r10-0x710]
  ldxdw r1, [r10-0x718]
  mov64 r3, r10
  add64 r3, -0x678
  call fn_1d778
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1d250
  ldxdw r1, [r10-0x888]
  ldxdw r2, [r10-0x8a0]
  mov64 r3, r7
  ldxdw r4, [r10-0x8b8]
  call fn_1b770
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1d250
  mov64 r1, r7
  add64 r1, 0x8
  stxdw [r10-0x8c0], r1
  ldxdw r1, [r10-0x8b0]
  add64 r1, 0x8
  stxdw [r10-0x8c8], r1
  ldxdw r1, [r10-0x518]
  jeq r9, 0x0, jmp_1cc88
  ldxdw r2, [r10-0x898]
  jge r1, r2, jmp_1d2a0
  mov64 r1, 0xb
  mov64 r0, 0x0
  ja jmp_1cb38

jmp_1cc88:
  mov64 r3, r1
  ldxdw r2, [r10-0x898]
  add64 r3, r2
  mov64 r2, 0x1
  jlt r3, r1, jmp_1ccb8
  mov64 r2, 0x0

jmp_1ccb8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1d288
  ldxdw r3, [r10-0x898]
  mov64 r2, r3
  add64 r2, r1
  stxdw [r10-0x518], r2
  ldxdw r2, [r10-0x6a0]
  mov64 r4, r2
  add64 r4, r3
  mov64 r1, 0x1
  jlt r4, r2, jmp_1cd18
  mov64 r1, 0x0

jmp_1cd18:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d288
  mov64 r1, r8
  add64 r1, 0x8
  ldxdw r3, [r10-0x898]
  add64 r3, r2
  stxdw [r10-0x6a0], r3
  stxdw [r10-0x430], r1
  ldxdw r2, [r10-0x8c8]
  stxdw [r10-0x440], r2
  ldxdw r2, [r10-0x8c0]
  stxdw [r10-0x450], r2
  ldxdw r3, [r10-0x8b8]
  mov64 r2, r3
  add64 r2, 0x8
  stxdw [r10-0x460], r2
  sth [r10-0x428], 0x100
  sth [r10-0x438], 0x1
  sth [r10-0x448], 0x0
  sth [r10-0x458], 0x1
  ldxb r3, [r3+0x0]
  ldxdw r4, [r10-0x8b0]
  ldxb r4, [r4+0x0]
  and64 r4, r3
  jne r4, 0xff, jmp_1d760
  stxdw [r10-0x370], r2
  ldxdw r4, [r10-0x8b8]
  mov64 r2, r4
  add64 r2, 0x48
  stxdw [r10-0x368], r2
  ldxdw r2, [r4+0x50]
  mov64 r3, r4
  add64 r3, 0x28
  stxdw [r10-0x350], r3
  mov64 r3, r4
  add64 r3, 0x58
  stxdw [r10-0x358], r3
  stxdw [r10-0x360], r2
  stdw [r10-0x348], 0x0
  ldxw r2, [r4+0x1]
  mov64 r3, r7
  add64 r3, 0x48
  stxdw [r10-0x330], r3
  ldxdw r3, [r10-0x8c0]
  stxdw [r10-0x338], r3
  stxw [r10-0x340], r2
  ldxdw r2, [r7+0x50]
  mov64 r3, r7
  add64 r3, 0x28
  stxdw [r10-0x318], r3
  mov64 r3, r7
  add64 r3, 0x58
  stxdw [r10-0x320], r3
  stxdw [r10-0x328], r2
  stdw [r10-0x310], 0x0
  ldxw r2, [r7+0x1]
  ldxdw r4, [r10-0x8b0]
  mov64 r3, r4
  add64 r3, 0x48
  stxdw [r10-0x2f8], r3
  ldxdw r3, [r10-0x8c8]
  stxdw [r10-0x300], r3
  stxw [r10-0x308], r2
  mov64 r2, r4
  add64 r2, 0x28
  ldxdw r3, [r4+0x50]
  stxdw [r10-0x2e0], r2
  mov64 r2, r4
  add64 r2, 0x58
  stxdw [r10-0x2e8], r2
  stxdw [r10-0x2f0], r3
  stdw [r10-0x2d8], 0x0
  ldxw r2, [r4+0x1]
  mov64 r3, r8
  add64 r3, 0x48
  stxdw [r10-0x2c0], r3
  stxdw [r10-0x2c8], r1
  stxw [r10-0x2d0], r2
  mov64 r1, r8
  add64 r1, 0x28
  ldxdw r2, [r8+0x50]
  stxdw [r10-0x2a8], r1
  mov64 r1, r8
  add64 r1, 0x58
  stxdw [r10-0x2b0], r1
  stxdw [r10-0x2b8], r2
  stdw [r10-0x2a0], 0x0
  ldxw r1, [r8+0x1]
  stxw [r10-0x298], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x49f], r1
  stb [r10-0x497], 0x6
  stb [r10-0x4a0], 0xc
  mov64 r1, r10
  add64 r1, -0x4a0
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x460
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0xa
  stdw [r10-0x18], 0x4
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x370
  mov64 r3, 0x4
  mov64 r4, 0x8
  mov64 r5, 0x0
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x8a8]
  and64 r1, 0x1
  jne r1, 0x0, jmp_1d108

jmp_1d0b0:
  ldxdw r1, [r10-0x890]
  ldxdw r4, [r1+0x28]
  ldxdw r3, [r1+0x38]
  ldxdw r2, [r1+0x10]
  ldxdw r1, [r10-0x888]
  call fn_1bc30
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1d250

jmp_1d108:
  ldxdw r1, [r10-0x710]
  ldxdw r7, [r10-0x518]
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  mov64 r8, r0
  mov64 r9, r1
  ldxdw r3, [r10-0x718]
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  add64 r2, r8
  mov64 r4, 0x1
  mov64 r3, 0x1
  jne r9, 0x0, jmp_1d260
  mov64 r3, 0x0
  jge r2, r1, jmp_1d268

jmp_1d1a8:
  or64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_1d288

jmp_1d1c0:
  stxdw [r10-0x618], r0
  stxdw [r10-0x610], r2
  ldxdw r1, [r10-0x890]
  ldxdw r1, [r1+0x20]
  mov64 r2, r10
  add64 r2, -0x678
  call fn_2458
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1d250
  ldxdw r1, [r10-0x890]
  ldxdw r1, [r1+0x18]
  mov64 r2, r10
  add64 r2, -0x728
  call fn_35c0
  ja jmp_1cb38

jmp_1d250:
  mov64 r0, r2
  ja jmp_1cb38

jmp_1d260:
  jlt r2, r1, jmp_1d1a8

jmp_1d268:
  mov64 r4, 0x0
  or64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_1d1c0

jmp_1d288:
  mov64 r1, 0x4
  mov64 r0, 0x0
  ja jmp_1cb38

jmp_1d2a0:
  ldxdw r3, [r10-0x898]
  sub64 r1, r3
  stxdw [r10-0x518], r1
  ldxdw r2, [r10-0x6a0]
  mov64 r1, 0xb
  mov64 r0, 0x0
  jlt r2, r3, jmp_1cb38
  ldxdw r1, [r10-0x898]
  sub64 r2, r1
  stxdw [r10-0x6a0], r2
  ldxdw r1, [r10-0x8a0]
  lddw r2, data_0750
  mov64 r3, 0x1
  ldxdw r4, [r10-0x888]
  call fn_05d0
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r3, r0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_1d748
  ldxdw r1, [r10-0x8a0]
  add64 r1, 0x8
  stxb [r10-0x4a1], r2
  mov64 r2, r10
  add64 r2, -0x4a1
  stxdw [r10-0x490], r2
  lddw r2, str_0361
  stxdw [r10-0x4a0], r2
  stdw [r10-0x488], 0x1
  stdw [r10-0x498], 0x6
  mov64 r2, r10
  add64 r2, -0x4a0
  stxdw [r10-0x480], r2
  stdw [r10-0x478], 0x2
  stxdw [r10-0x430], r1
  ldxdw r2, [r10-0x8c0]
  stxdw [r10-0x450], r2
  ldxdw r2, [r10-0x8c8]
  stxdw [r10-0x460], r2
  ldxdw r4, [r10-0x8b8]
  mov64 r2, r4
  add64 r2, 0x8
  stxdw [r10-0x440], r2
  sth [r10-0x428], 0x100
  sth [r10-0x438], 0x1
  sth [r10-0x448], 0x0
  sth [r10-0x458], 0x1
  ldxdw r3, [r10-0x8b0]
  ldxb r3, [r3+0x0]
  ldxb r4, [r4+0x0]
  and64 r4, r3
  jne r4, 0xff, jmp_1d760
  ldxdw r3, [r10-0x8c8]
  stxdw [r10-0x370], r3
  ldxdw r5, [r10-0x8b0]
  mov64 r3, r5
  add64 r3, 0x48
  stxdw [r10-0x368], r3
  ldxdw r3, [r5+0x50]
  mov64 r4, r5
  add64 r4, 0x28
  stxdw [r10-0x350], r4
  mov64 r4, r5
  add64 r4, 0x58
  stxdw [r10-0x358], r4
  stxdw [r10-0x360], r3
  stdw [r10-0x348], 0x0
  ldxw r3, [r5+0x1]
  mov64 r4, r7
  add64 r4, 0x48
  stxdw [r10-0x330], r4
  ldxdw r4, [r10-0x8c0]
  stxdw [r10-0x338], r4
  stxw [r10-0x340], r3
  ldxdw r3, [r7+0x50]
  mov64 r4, r7
  add64 r4, 0x28
  stxdw [r10-0x318], r4
  mov64 r4, r7
  add64 r4, 0x58
  stxdw [r10-0x320], r4
  stxdw [r10-0x328], r3
  stdw [r10-0x310], 0x0
  ldxw r3, [r7+0x1]
  ldxdw r5, [r10-0x8b8]
  mov64 r4, r5
  add64 r4, 0x48
  stxdw [r10-0x2f8], r4
  stxdw [r10-0x300], r2
  stxw [r10-0x308], r3
  mov64 r2, r5
  add64 r2, 0x28
  ldxdw r3, [r5+0x50]
  stxdw [r10-0x2e0], r2
  mov64 r2, r5
  add64 r2, 0x58
  stxdw [r10-0x2e8], r2
  stxdw [r10-0x2f0], r3
  stdw [r10-0x2d8], 0x0
  ldxw r2, [r5+0x1]
  ldxdw r4, [r10-0x8a0]
  mov64 r3, r4
  add64 r3, 0x48
  stxdw [r10-0x2c0], r3
  stxdw [r10-0x2c8], r1
  stxw [r10-0x2d0], r2
  mov64 r1, r4
  add64 r1, 0x28
  ldxdw r2, [r4+0x50]
  stxdw [r10-0x2a8], r1
  mov64 r1, r4
  add64 r1, 0x58
  stxdw [r10-0x2b0], r1
  stxdw [r10-0x2b8], r2
  stdw [r10-0x2a0], 0x0
  ldxw r1, [r4+0x1]
  stxw [r10-0x298], r1
  ldxdw r1, [r10-0x898]
  stxdw [r10-0x469], r1
  stb [r10-0x461], 0x6
  stb [r10-0x46a], 0xc
  mov64 r1, r10
  add64 r1, -0x46a
  stxdw [r10-0x10], r1
  mov64 r1, r10
  add64 r1, -0x460
  stxdw [r10-0x20], r1
  lddw r1, data_02c1
  stxdw [r10-0x28], r1
  stdw [r10-0x8], 0xa
  stdw [r10-0x18], 0x4
  mov64 r1, r10
  add64 r1, -0x28
  mov64 r2, r10
  add64 r2, -0x370
  mov64 r4, r10
  add64 r4, -0x480
  mov64 r3, 0x4
  mov64 r5, 0x1
  call sol_invoke_signed_c
  ldxdw r1, [r10-0x8a8]
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1d0b0
  ja jmp_1d108

jmp_1d748:
  mov64 r1, r2
  mov64 r0, r3
  ja jmp_1cb38

jmp_1d760:
  mov64 r0, 0xb
  mov64 r1, 0x4
  ja jmp_1cb38

fn_1d778:
  mov64 r8, r1
  stxdw [r10-0x10], r3
  ldxdw r9, [r3+0x160]
  mov64 r1, 0x0
  stxdw [r10-0x8], r1
  mov64 r1, r2
  mov64 r2, 0x0
  mov64 r3, r9
  mov64 r4, 0x0
  call fn_2c150
  mov64 r7, r0
  mov64 r6, r1
  mov64 r1, r9
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r9, r1
  add64 r9, r7
  mov64 r3, 0x1
  mov64 r2, 0x1
  jeq r6, 0x0, jmp_1d858
  jge r9, r1, jmp_1d868

jmp_1d830:
  or64 r2, r3
  and64 r2, 0x1
  ldxdw r7, [r10-0x10]
  jeq r2, 0x0, jmp_1d890
  ja jmp_1db48

jmp_1d858:
  mov64 r2, 0x0
  jlt r9, r1, jmp_1d830

jmp_1d868:
  mov64 r3, 0x0
  or64 r2, r3
  and64 r2, 0x1
  ldxdw r7, [r10-0x10]
  jne r2, 0x0, jmp_1db48

jmp_1d890:
  ldxdw r3, [r7+0x60]
  ldxdw r1, [r7+0x68]
  mov64 r2, 0x0
  stxdw [r10-0x8], r2
  mov64 r4, 0x1
  mov64 r2, 0x1
  jge r9, r1, jmp_1d8f8
  jge r0, r3, jmp_1d908

jmp_1d8d0:
  mov64 r5, r4
  jne r9, r1, jmp_1d920

jmp_1d8e0:
  and64 r5, 0x1
  jeq r5, 0x0, jmp_1d938
  ja jmp_1db48

jmp_1d8f8:
  mov64 r2, 0x0
  jlt r0, r3, jmp_1d8d0

jmp_1d908:
  mov64 r4, 0x0
  mov64 r5, r4
  jeq r9, r1, jmp_1d8e0

jmp_1d920:
  mov64 r5, r2
  and64 r5, 0x1
  jne r5, 0x0, jmp_1db48

jmp_1d938:
  mov64 r2, r9
  sub64 r2, r1
  sub64 r2, r4
  mov64 r1, r0
  sub64 r1, r3
  ldxdw r3, [r7+0x170]
  mov64 r8, r1
  add64 r8, r3
  mov64 r3, 0x0
  stxdw [r10-0x8], r3
  mov64 r4, 0x1
  mov64 r3, 0x1
  jge r8, r1, jmp_1d9d8
  mov64 r5, r2
  add64 r5, r3
  jge r5, r2, jmp_1d9f8

jmp_1d9b8:
  jlt r8, r1, jmp_1da08

jmp_1d9c0:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_1da20
  ja jmp_1db48

jmp_1d9d8:
  mov64 r3, 0x0
  mov64 r5, r2
  add64 r5, r3
  jlt r5, r2, jmp_1d9b8

jmp_1d9f8:
  mov64 r4, 0x0
  jge r8, r1, jmp_1d9c0

jmp_1da08:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_1db48

jmp_1da20:
  mov64 r3, 0x0
  stxdw [r10-0x8], r3
  mov64 r3, 0x1
  jlt r8, r1, jmp_1da48
  mov64 r3, 0x0

jmp_1da48:
  add64 r2, r3
  lddw r1, 0xde0b6b3a763ffff
  jgt r2, r1, jmp_1db48
  mov64 r6, r0
  mov64 r1, 0x0
  stxdw [r10-0x8], r1
  mov64 r1, r8
  lddw r3, 0xde0b6b3a7640000
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r3, [r7+0x168]
  mov64 r1, r3
  add64 r1, r0
  mov64 r2, 0x1
  jlt r1, r3, jmp_1dad8
  mov64 r2, 0x0

jmp_1dad8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1db48
  stxdw [r7+0x60], r6
  stxdw [r7+0x68], r9
  stxdw [r7+0x168], r1
  mov64 r1, r0
  lddw r3, -0xde0b6b3a7640000
  mov64 r4, 0x0
  call fn_2c150
  add64 r0, r8
  stxdw [r7+0x170], r0
  mov64 r1, 0x1a
  stxdw [r10-0x8], r1

jmp_1db48:
  ldxdw r0, [r10-0x8]
  mov64 r1, 0x4
  exit

fn_1db60:
  ldxdw r2, [r1+0x58]
  jeq r2, 0x0, jmp_1dea8
  mov64 r2, 0x0
  ldxdw r3, [r1+0x38]

jmp_1db80:
  mov64 r5, r3
  add64 r5, r2
  mov64 r0, 0x0
  mov64 r4, 0x1
  jlt r5, r3, jmp_1dbb0
  mov64 r4, 0x0

jmp_1dbb0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_1dcd8
  mov64 r6, r2
  add64 r6, r3
  stdw [r1+0x38], 0x0
  ldxdw r3, [r1+0x48]
  mov64 r5, r3
  add64 r5, r6
  mov64 r4, 0x1
  jlt r5, r3, jmp_1dc08
  mov64 r4, 0x0

jmp_1dc08:
  and64 r4, 0x1
  jne r4, 0x0, jmp_1dcd8
  mov64 r5, r6
  add64 r5, r3
  stxdw [r1+0x48], r5
  ldxdw r4, [r1+0x90]
  mov64 r8, r4
  add64 r8, r6
  mov64 r7, 0x1
  jlt r8, r4, jmp_1dc60
  mov64 r7, 0x0

jmp_1dc60:
  and64 r7, 0x1
  jne r7, 0x0, jmp_1dcd8
  add64 r6, r4
  stxdw [r1+0x90], r6
  ldxdw r7, [r1+0x8]
  ldxdw r6, [r1+0x0]
  mov64 r9, 0x1
  jlt r6, r2, jmp_1dca8
  mov64 r9, 0x0

jmp_1dca8:
  mov64 r8, r7
  sub64 r8, r9
  mov64 r9, r7
  xor64 r9, r8
  and64 r7, r9
  jsge r7, 0x0, jmp_1dce8

jmp_1dcd8:
  mov64 r2, 0x4
  ja jmp_1dff8

jmp_1dce8:
  sub64 r6, r2
  stxdw [r1+0x0], r6
  stxdw [r1+0x8], r8
  ldxw r6, [r1+0xa4]
  ldxh r7, [r1+0xa8]
  jne r7, 0x0, jmp_1dd28
  mov64 r2, r6
  jeq r2, 0x0, jmp_1dd68

jmp_1dd28:
  mov64 r2, 0x2
  add64 r7, -0x1
  and64 r7, 0xffff
  jgt r7, 0x270f, jmp_1dff8
  add64 r6, -0x2710
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  jge r6, 0x7531, jmp_1dff8

jmp_1dd68:
  mov64 r2, 0x2
  ldxw r6, [r1+0xa0]
  jeq r6, 0x0, jmp_1dff8
  jgt r6, 0xf4240, jmp_1dff8
  ldxdw r6, [r1+0x98]
  jeq r6, 0x0, jmp_1dff8
  ldxdw r6, [r1+0x30]
  ldxdw r7, [r1+0x28]
  mov64 r9, r7
  add64 r9, r6
  mov64 r8, 0x1
  stxdw [r10-0x8], r7
  jlt r9, r7, jmp_1ddd8
  mov64 r8, 0x0

jmp_1ddd8:
  and64 r8, 0x1
  jne r8, 0x0, jmp_1dcd8
  ldxdw r7, [r1+0x40]
  mov64 r8, r7
  add64 r8, r5
  mov64 r9, 0x1
  jlt r8, r7, jmp_1de18
  mov64 r9, 0x0

jmp_1de18:
  and64 r9, 0x1
  jne r9, 0x0, jmp_1dcd8
  ldxdw r0, [r10-0x8]
  add64 r6, r0
  add64 r5, r7
  mov64 r8, r6
  add64 r8, r5
  mov64 r0, 0x0
  mov64 r7, 0x1
  jlt r8, r6, jmp_1de70
  mov64 r7, 0x0

jmp_1de70:
  and64 r7, 0x1
  jne r7, 0x0, jmp_1dcd8
  add64 r5, r6
  ldxdw r6, [r1+0x20]
  jge r6, r5, jmp_1e1b8
  mov64 r2, 0xb
  ja jmp_1dff8

jmp_1dea8:
  ldxdw r5, [r1+0x30]
  ldxdw r6, [r1+0x28]
  mov64 r2, r6
  add64 r2, r5
  mov64 r0, 0x0
  mov64 r3, 0x1
  jlt r2, r6, jmp_1dee8
  mov64 r3, 0x0

jmp_1dee8:
  mov64 r2, 0x4
  and64 r3, 0x1
  jne r3, 0x0, jmp_1dff8
  ldxdw r7, [r1+0x40]
  ldxdw r3, [r1+0x38]
  mov64 r8, r3
  add64 r8, r7
  mov64 r4, 0x1
  jlt r8, r3, jmp_1df38
  mov64 r4, 0x0

jmp_1df38:
  and64 r4, 0x1
  jne r4, 0x0, jmp_1dff8
  add64 r7, r3
  ldxdw r4, [r1+0x48]
  mov64 r9, r7
  add64 r9, r4
  mov64 r8, 0x1
  jlt r9, r7, jmp_1df80
  mov64 r8, 0x0

jmp_1df80:
  and64 r8, 0x1
  jne r8, 0x0, jmp_1dff8
  add64 r5, r6
  add64 r4, r7
  mov64 r7, r5
  add64 r7, r4
  mov64 r6, 0x1
  jlt r7, r5, jmp_1dfc8
  mov64 r6, 0x0

jmp_1dfc8:
  and64 r6, 0x1
  jne r6, 0x0, jmp_1dff8
  add64 r4, r5
  mov64 r2, 0xb
  ldxdw r6, [r1+0x20]
  jge r6, r4, jmp_1e008

jmp_1dff8:
  mov64 r1, r2
  exit

jmp_1e008:
  ldxdw r0, [r1+0x8]
  ldxdw r7, [r1+0x0]
  ldxdw r8, [r1+0x98]
  mov64 r2, 0x1
  stxdw [r10-0x8], r2
  mov64 r5, 0x1
  jlt r7, r8, jmp_1e048
  mov64 r5, 0x0

jmp_1e048:
  mov64 r2, r0
  sub64 r2, r5
  mov64 r9, r0
  xor64 r9, r2
  mov64 r5, r0
  and64 r5, r9
  lddw r9, -0x8000000000000000
  jslt r5, 0x0, jmp_1e120
  mov64 r9, r2
  mov64 r2, 0x0
  jsge r5, 0x0, jmp_1e130

jmp_1e0a8:
  sub64 r6, r4
  mov64 r4, 0x1
  jlt r2, r6, jmp_1e158

jmp_1e0c0:
  mov64 r4, 0x0
  jne r9, 0x0, jmp_1e160

jmp_1e0d0:
  jne r4, 0x0, jmp_1e170

jmp_1e0d8:
  mov64 r2, r6
  mov64 r4, 0x1
  jle r7, r8, jmp_1e180

jmp_1e0f0:
  jsgt r0, 0x0, jmp_1e190

jmp_1e0f8:
  mov64 r5, 0x0
  stxdw [r10-0x8], r5
  jne r0, 0x0, jmp_1e198

jmp_1e110:
  jne r4, 0x0, jmp_1db80
  ja jmp_1e1a8

jmp_1e120:
  mov64 r2, 0x0
  jslt r5, 0x0, jmp_1e0a8

jmp_1e130:
  mov64 r2, r7
  sub64 r2, r8
  sub64 r6, r4
  mov64 r4, 0x1
  jge r2, r6, jmp_1e0c0

jmp_1e158:
  jeq r9, 0x0, jmp_1e0d0

jmp_1e160:
  mov64 r4, 0x0
  jeq r4, 0x0, jmp_1e0d8

jmp_1e170:
  mov64 r4, 0x1
  jgt r7, r8, jmp_1e0f0

jmp_1e180:
  mov64 r4, 0x0
  jsle r0, 0x0, jmp_1e0f8

jmp_1e190:
  jeq r0, 0x0, jmp_1e110

jmp_1e198:
  ldxdw r4, [r10-0x8]
  jne r4, 0x0, jmp_1db80

jmp_1e1a8:
  mov64 r2, 0x0
  ja jmp_1db80

jmp_1e1b8:
  ldxdw r7, [r1+0x50]
  sub64 r6, r5
  jgt r7, r6, jmp_1dff8
  ldxdw r5, [r1+0x70]
  ldxdw r1, [r1+0x68]
  jgt r1, r5, jmp_1dff8
  jgt r4, r3, jmp_1dff8
  mov64 r0, 0x1a
  ja jmp_1dff8

fn_1e200:
  mov64 r6, r1
  call fn_1db60
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1e438
  mov64 r0, 0x1a
  ldxdw r7, [r6+0x88]
  jeq r7, 0x0, jmp_1e3c0
  ldxdw r1, [r6+0x90]
  mov64 r2, 0x0
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x6f
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r1, r0
  mov64 r2, 0x0
  lddw r3, 0xde0b6b3a7640000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r8, 0x1
  jlt r0, r7, jmp_1e2e8
  mov64 r8, 0x0

jmp_1e2e8:
  jeq r2, 0x0, jmp_1e2f8
  mov64 r8, 0x0

jmp_1e2f8:
  mov64 r1, r0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c2a8
  and64 r8, 0x1
  jne r8, 0x0, jmp_1e430
  ldxdw r3, [r6+0x10]
  mov64 r2, r3
  add64 r2, r0
  mov64 r0, 0x0
  mov64 r7, 0x1
  mov64 r5, 0x1
  jlt r2, r3, jmp_1e368
  mov64 r5, 0x0

jmp_1e368:
  ldxdw r8, [r6+0x18]
  mov64 r4, r8
  add64 r4, r1
  mov64 r1, r4
  add64 r1, r5
  jge r1, r8, jmp_1e3c8
  jne r1, r8, jmp_1e3d8

jmp_1e3a0:
  mov64 r1, 0x4
  and64 r5, 0x1
  jeq r5, 0x0, jmp_1e3f8
  ja jmp_1e438

jmp_1e3c0:
  ja jmp_1e438

jmp_1e3c8:
  mov64 r7, 0x0
  jeq r1, r8, jmp_1e3a0

jmp_1e3d8:
  mov64 r5, r7
  mov64 r1, 0x4
  and64 r5, 0x1
  jne r5, 0x0, jmp_1e438

jmp_1e3f8:
  mov64 r1, 0x1
  jlt r2, r3, jmp_1e410
  mov64 r1, 0x0

jmp_1e410:
  stxdw [r6+0x10], r2
  add64 r4, r1
  stxdw [r6+0x18], r4
  stdw [r6+0x90], 0x0

jmp_1e430:
  mov64 r0, 0x1a

jmp_1e438:
  exit

fn_1e440:
  stxdw [r10-0x5a8], r3
  stxdw [r10-0x5b8], r2
  stxdw [r10-0x588], r1
  ldxdw r1, [r5-0xff8]
  ldxdw r5, [r5-0x1000]
  ldxdw r8, [r5+0x100]
  mov64 r0, r8
  add64 r0, r1
  mov64 r2, 0x1
  mov64 r1, 0x1
  jlt r0, r8, jmp_1e500
  mov64 r1, 0x0
  ldxdw r7, [r5+0x108]
  mov64 r3, r7
  add64 r3, r1
  jge r3, r7, jmp_1e520

jmp_1e4c0:
  stxdw [r10-0x598], r5
  stxdw [r10-0x578], r0
  jge r0, r8, jmp_1e540

jmp_1e4d8:
  mov64 r1, r2
  stxdw [r10-0x5a0], r4
  and64 r1, 0x1
  jeq r1, 0x0, jmp_1e558
  ja jmp_1e7e8

jmp_1e500:
  ldxdw r7, [r5+0x108]
  mov64 r3, r7
  add64 r3, r1
  jlt r3, r7, jmp_1e4c0

jmp_1e520:
  mov64 r2, 0x0
  stxdw [r10-0x598], r5
  stxdw [r10-0x578], r0
  jlt r0, r8, jmp_1e4d8

jmp_1e540:
  stxdw [r10-0x5a0], r4
  and64 r1, 0x1
  jne r1, 0x0, jmp_1e7e8

jmp_1e558:
  mov64 r1, r8
  mov64 r2, r7
  mov64 r3, 0xa
  mov64 r4, 0x0
  call fn_2c2a8
  stxdw [r10-0x580], r0
  mov64 r6, r1
  mov64 r9, 0x1
  mov64 r3, 0x1
  ldxdw r1, [r10-0x578]
  jlt r1, r8, jmp_1e5b8
  mov64 r3, 0x0

jmp_1e5b8:
  mov64 r2, r7
  add64 r2, r3
  stxdw [r10-0x590], r2
  mov64 r3, 0xa
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r2, 0x1
  jlt r1, r6, jmp_1e648
  mov64 r2, 0x0
  ldxdw r3, [r10-0x580]
  jge r0, r3, jmp_1e658

jmp_1e610:
  jeq r1, r6, jmp_1e668

jmp_1e618:
  mov64 r9, r2
  and64 r9, 0x1
  jeq r9, 0x0, jmp_1e678

jmp_1e630:
  lddw r1, data_09a8
  call fn_2bcf8

jmp_1e648:
  ldxdw r3, [r10-0x580]
  jlt r0, r3, jmp_1e610

jmp_1e658:
  mov64 r9, 0x0
  jne r1, r6, jmp_1e618

jmp_1e668:
  and64 r9, 0x1
  jne r9, 0x0, jmp_1e630

jmp_1e678:
  mov64 r2, 0x1
  jlt r0, r3, jmp_1e690
  mov64 r2, 0x0

jmp_1e690:
  sub64 r1, r6
  sub64 r1, r2
  stxdw [r10-0x5c0], r1
  jne r1, 0x0, jmp_1e7e8
  stxdw [r10-0x5b0], r0
  ldxdw r1, [r10-0x578]
  ldxdw r2, [r10-0x590]
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r9, r0
  mov64 r6, r1
  mov64 r1, r8
  mov64 r2, r7
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r2, 0x1
  mov64 r3, 0x1
  jlt r6, r1, jmp_1e780
  mov64 r3, 0x0
  jge r9, r0, jmp_1e788

jmp_1e740:
  ldxdw r4, [r10-0x5b0]
  jeq r6, r1, jmp_1e7a0

jmp_1e750:
  mov64 r2, r3
  and64 r2, 0x1
  jeq r2, 0x0, jmp_1e7b0

jmp_1e768:
  lddw r1, data_09c0
  call fn_2bcf8

jmp_1e780:
  jlt r9, r0, jmp_1e740

jmp_1e788:
  mov64 r2, 0x0
  ldxdw r4, [r10-0x5b0]
  jne r6, r1, jmp_1e750

jmp_1e7a0:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1e768

jmp_1e7b0:
  mov64 r2, 0x1
  ldxdw r3, [r10-0x580]
  jlt r9, r0, jmp_1e7d0
  mov64 r2, 0x0

jmp_1e7d0:
  sub64 r6, r1
  sub64 r6, r2
  jeq r6, 0x0, jmp_1e808

jmp_1e7e8:
  ldxdw r1, [r10-0x588]
  stw [r1+0x8], 0x4

jmp_1e7f8:
  stdw [r1+0x0], 0x1

jmp_1e800:
  exit

jmp_1e808:
  sub64 r4, r3
  sub64 r9, r0
  mov64 r2, r4
  add64 r2, r9
  mov64 r1, 0x1
  jlt r2, r4, jmp_1e840
  mov64 r1, 0x0

jmp_1e840:
  ldxdw r5, [r10-0x598]
  ldxdw r2, [r10-0x578]
  stxdw [r5+0x100], r2
  ldxdw r2, [r10-0x590]
  stxdw [r5+0x108], r2
  ldxdw r2, [r10-0x5a0]
  jeq r1, 0x1, jmp_1e7e8
  mov64 r3, r9
  add64 r3, r4
  ldxdw r0, [r5+0x58]
  ldxdw r7, [r5+0x50]
  ldxdw r1, [r5+0x48]
  ldxdw r8, [r5+0x40]
  jne r8, 0x0, jmp_1e8f8
  jne r1, 0x0, jmp_1e8f8
  jne r7, 0x0, jmp_1e8f8
  jne r0, 0x0, jmp_1e8f8
  jne r2, 0x0, jmp_1eae8
  ldxdw r1, [r10-0x588]
  stxdw [r1+0x10], r3
  stdw [r1+0x8], 0x0

jmp_1e8e8:
  stw [r1+0x0], 0x0
  ja jmp_1e800

jmp_1e8f8:
  stxdw [r10-0x578], r1
  mov64 r1, 0x2
  jeq r2, 0x0, jmp_1e920
  ldxdw r1, [r10-0x5a8]
  add64 r1, 0x8

jmp_1e920:
  jeq r2, 0x0, jmp_1eae8
  stxdw [r10-0x580], r7
  stxdw [r10-0x590], r0
  stxdw [r10-0x5c8], r1
  stxdw [r10-0x5b0], r4
  stxdw [r10-0x5d8], r9
  stxdw [r10-0x5e0], r6
  stxdw [r10-0x5d0], r3
  ldxdw r1, [r10-0x5a8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x1d0
  ldxdw r3, [r10-0x5b8]
  call fn_3a90
  ldxw r7, [r10-0x1cc]
  ldxw r6, [r10-0x1d0]
  ldxb r9, [r10-0x7]
  jne r9, 0x2, jmp_1e9d8
  ldxdw r1, [r10-0x588]
  stxw [r1+0x8], r7
  stxw [r1+0x4], r6
  stw [r1+0x0], 0x1
  ja jmp_1e800

jmp_1e9d8:
  mov64 r1, r10
  add64 r1, -0x568
  mov64 r2, r10
  add64 r2, -0x1c8
  mov64 r3, 0x1c1
  call fn_2c060
  ldxw r1, [r10-0x6]
  stxw [r10-0x3a6], r1
  ldxh r1, [r10-0x2]
  stxh [r10-0x3a2], r1
  stxw [r10-0x56c], r7
  stxw [r10-0x570], r6
  stxb [r10-0x3a7], r9
  ldxdw r1, [r10-0x570]
  ldxdw r2, [r10-0x590]
  ldxdw r3, [r10-0x580]
  jne r1, r8, jmp_1eae8
  ldxdw r1, [r10-0x568]
  ldxdw r4, [r10-0x578]
  jne r1, r4, jmp_1eae8
  ldxdw r1, [r10-0x560]
  jne r1, r3, jmp_1eae8
  ldxdw r1, [r10-0x558]
  jne r1, r2, jmp_1eae8
  ldxdw r1, [r10-0x598]
  ldxdw r9, [r1+0x18]
  ldxdw r5, [r1+0x10]
  ldxdw r0, [r1+0x8]
  ldxdw r6, [r1+0x0]
  jne r8, r6, jmp_1eb00
  ldxdw r1, [r10-0x578]
  jne r1, r0, jmp_1eb00
  jne r3, r5, jmp_1eb00
  jne r2, r9, jmp_1eb00

jmp_1eae8:
  ldxdw r1, [r10-0x588]
  stw [r1+0x8], 0x2
  ja jmp_1e7f8

jmp_1eb00:
  ldxdw r3, [r10-0x440]
  mov64 r2, r3
  ldxdw r4, [r10-0x5b0]
  add64 r2, r4
  mov64 r1, 0x1
  jlt r2, r3, jmp_1eb38
  mov64 r1, 0x0

jmp_1eb38:
  jeq r1, 0x1, jmp_1e7e8
  stxdw [r10-0x598], r6
  stxdw [r10-0x5e8], r0
  stxdw [r10-0x5f0], r5
  ldxdw r3, [r10-0x460]
  mov64 r1, r3
  add64 r1, r4
  mov64 r0, 0x1
  mov64 r5, 0x1
  jlt r1, r3, jmp_1eb90
  mov64 r5, 0x0

jmp_1eb90:
  ldxdw r6, [r10-0x458]
  mov64 r4, r6
  ldxdw r7, [r10-0x5c0]
  add64 r4, r7
  mov64 r7, r4
  add64 r7, r5
  jlt r7, r6, jmp_1ebf0
  mov64 r0, 0x0
  jne r7, r6, jmp_1ebf8

jmp_1ebd8:
  stxdw [r10-0x440], r2
  jeq r5, 0x1, jmp_1e7e8
  ja jmp_1ec10

jmp_1ebf0:
  jeq r7, r6, jmp_1ebd8

jmp_1ebf8:
  mov64 r5, r0
  stxdw [r10-0x440], r2
  jeq r5, 0x1, jmp_1e7e8

jmp_1ec10:
  mov64 r2, 0x1
  jlt r1, r3, jmp_1ec28
  mov64 r2, 0x0

jmp_1ec28:
  ldxdw r3, [r10-0x5a0]
  add64 r3, -0x1
  add64 r4, r2
  stxdw [r10-0x460], r1
  stxdw [r10-0x458], r4
  ldxdw r1, [r10-0x518]
  ldxdw r2, [r10-0x520]
  ldxdw r5, [r10-0x528]
  ldxdw r0, [r10-0x530]
  ldxdw r4, [r10-0x580]
  jne r0, 0x0, jmp_1ed20
  jne r5, 0x0, jmp_1ed20
  jne r2, 0x0, jmp_1ed20
  jne r1, 0x0, jmp_1ed20
  jne r3, 0x0, jmp_1eae8

jmp_1eca0:
  ldxdw r1, [r10-0x5a8]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x570
  call fn_2458
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1f0b0
  ldxdw r1, [r10-0x588]
  ldxdw r3, [r10-0x5b0]
  stxdw [r1+0x8], r3
  ldxdw r2, [r10-0x5d0]
  sub64 r2, r3
  stxdw [r1+0x10], r2
  ja jmp_1e8e8

jmp_1ed20:
  jne r3, 0x1, jmp_1eae8
  stxdw [r10-0x5a0], r0
  stxdw [r10-0x5f8], r5
  stxdw [r10-0x5c0], r2
  stxdw [r10-0x5b0], r1
  ldxdw r1, [r10-0x5c8]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x1d0
  ldxdw r3, [r10-0x5b8]
  call fn_3a90
  ldxw r7, [r10-0x1cc]
  ldxw r0, [r10-0x1d0]
  ldxb r6, [r10-0x7]
  jne r6, 0x2, jmp_1edc0

jmp_1ed98:
  ldxdw r1, [r10-0x588]
  stxw [r1+0x8], r7
  stxw [r1+0x4], r0
  stw [r1+0x0], 0x1
  ja jmp_1e800

jmp_1edc0:
  mov64 r1, r10
  add64 r1, -0x398
  mov64 r2, r10
  add64 r2, -0x1c8
  mov64 r3, 0x1c1
  stxdw [r10-0x5b8], r0
  call fn_2c060
  ldxw r1, [r10-0x6]
  stxw [r10-0x1d6], r1
  ldxh r1, [r10-0x2]
  stxh [r10-0x1d2], r1
  stxw [r10-0x39c], r7
  ldxdw r1, [r10-0x5b8]
  stxw [r10-0x3a0], r1
  stxb [r10-0x1d7], r6
  mov64 r7, 0x2
  mov64 r0, 0x0
  ldxdw r1, [r10-0x3a0]
  ldxdw r5, [r10-0x5a0]
  jne r1, r5, jmp_1ed98
  ldxdw r1, [r10-0x398]
  ldxdw r2, [r10-0x5b0]
  ldxdw r3, [r10-0x5c0]
  ldxdw r4, [r10-0x5f8]
  jne r1, r4, jmp_1ed98
  ldxdw r1, [r10-0x390]
  jne r1, r3, jmp_1ed98
  ldxdw r1, [r10-0x388]
  jne r1, r2, jmp_1ed98
  ldxdw r1, [r10-0x598]
  jne r5, r1, jmp_1eee0
  ldxdw r1, [r10-0x5e8]
  jne r4, r1, jmp_1eee0
  ldxdw r1, [r10-0x5f0]
  jne r3, r1, jmp_1eee0
  jeq r2, r9, jmp_1ed98

jmp_1eee0:
  jne r5, r8, jmp_1ef18
  ldxdw r1, [r10-0x578]
  jne r4, r1, jmp_1ef18
  ldxdw r1, [r10-0x580]
  jne r3, r1, jmp_1ef18
  ldxdw r1, [r10-0x590]
  jeq r2, r1, jmp_1ed98

jmp_1ef18:
  ldxdw r3, [r10-0x270]
  mov64 r1, r3
  ldxdw r2, [r10-0x5d8]
  add64 r1, r2
  mov64 r2, 0x1
  jlt r1, r3, jmp_1ef50
  mov64 r2, 0x0

jmp_1ef50:
  and64 r2, 0x1
  jne r2, 0x0, jmp_1f0f0
  ldxdw r3, [r10-0x280]
  mov64 r2, r3
  ldxdw r4, [r10-0x5d8]
  add64 r2, r4
  mov64 r0, 0x1
  mov64 r5, 0x1
  jlt r2, r3, jmp_1efa0
  mov64 r5, 0x0

jmp_1efa0:
  ldxdw r6, [r10-0x278]
  mov64 r4, r6
  ldxdw r7, [r10-0x5e0]
  add64 r4, r7
  mov64 r7, r4
  add64 r7, r5
  jlt r7, r6, jmp_1efe0
  mov64 r0, 0x0

jmp_1efe0:
  jeq r7, r6, jmp_1eff0
  mov64 r5, r0

jmp_1eff0:
  stxdw [r10-0x270], r1
  and64 r5, 0x1
  mov64 r0, 0x0
  mov64 r7, 0x4
  jne r5, 0x0, jmp_1ed98
  mov64 r1, 0x1
  jlt r2, r3, jmp_1f030
  mov64 r1, 0x0

jmp_1f030:
  stxdw [r10-0x280], r2
  add64 r4, r1
  stxdw [r10-0x278], r4
  ldxdw r1, [r10-0x5c8]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x3a0
  call fn_2458
  mov64 r2, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_1f0d8
  ldxdw r1, [r10-0x5d0]
  stxdw [r10-0x5b0], r1
  ja jmp_1eca0

jmp_1f0b0:
  ldxdw r2, [r10-0x588]
  stxw [r2+0x4], r0
  stxw [r2+0x8], r1
  stw [r2+0x0], 0x1
  ja jmp_1e800

jmp_1f0d8:
  mov64 r0, r2
  mov64 r7, r1
  ja jmp_1ed98

jmp_1f0f0:
  mov64 r7, 0x4
  ja jmp_1ed98

fn_1f100:
  mov64 r6, r1
  mov64 r9, 0x4
  jne r4, 0x0, jmp_1f120
  mov64 r9, 0x5

jmp_1f120:
  mov64 r0, 0x0
  mov64 r1, 0x2
  jlt r3, r9, jmp_1f2e8
  jeq r4, 0x0, jmp_1f190
  jne r3, 0x4, jmp_1f2e8
  stxdw [r10-0x458], r4
  stxdw [r10-0x460], r3
  ldxdw r7, [r2+0x8]
  mov64 r1, r2
  add64 r1, 0x18
  stxdw [r10-0x470], r1
  mov64 r8, r2
  add64 r2, 0x10
  ja jmp_1f298

jmp_1f190:
  stxdw [r10-0x458], r4
  stxdw [r10-0x460], r3
  mov64 r8, r2
  ldxdw r7, [r2+0x10]
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r7
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x7e]
  jeq r1, 0x2, jmp_1f2d8
  mov64 r1, 0x3
  mov64 r2, r8
  ldxdw r3, [r2+0x8]
  ldxb r4, [r3+0x1]
  mov64 r0, 0x0
  jeq r4, 0x0, jmp_1f2e8
  ldxdw r4, [r10-0x150]
  ldxdw r5, [r3+0x8]
  jne r5, r4, jmp_1f2e8
  ldxdw r4, [r10-0x148]
  ldxdw r5, [r3+0x10]
  jne r5, r4, jmp_1f2e8
  ldxdw r4, [r10-0x140]
  ldxdw r5, [r3+0x18]
  jne r5, r4, jmp_1f2e8
  ldxdw r4, [r10-0x138]
  ldxdw r3, [r3+0x20]
  jne r3, r4, jmp_1f2e8
  mov64 r1, r2
  add64 r1, 0x20
  stxdw [r10-0x470], r1
  add64 r2, 0x18

jmp_1f298:
  stxdw [r10-0x468], r2
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r2, r7
  mov64 r3, r6
  call fn_3820
  ldxb r1, [r10-0x7e]
  jne r1, 0x2, jmp_1f2f0

jmp_1f2d8:
  ldxw r0, [r10-0x1d0]
  ldxw r1, [r10-0x1cc]

jmp_1f2e8:
  exit

jmp_1f2f0:
  ldxdw r7, [r10-0x118]
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x488], r1
  ldxdw r1, [r10-0x128]
  stxdw [r10-0x480], r1
  ldxdw r1, [r10-0x130]
  stxdw [r10-0x478], r1
  ldxdw r1, [r10-0x468]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r3, r6
  call fn_68d0
  ldxw r1, [r10-0x1d0]
  jne r1, 0x1, jmp_1f380

jmp_1f368:
  ldxw r1, [r10-0x1c8]
  ldxw r0, [r10-0x1cc]
  ja jmp_1f2e8

jmp_1f380:
  stxdw [r10-0x490], r7
  ldxw r7, [r10-0x1c8]
  mov64 r1, r10
  add64 r1, -0x44c
  mov64 r2, r10
  add64 r2, -0x1c4
  mov64 r3, 0xac
  call fn_2c060
  stxw [r10-0x450], r7
  ldxdw r1, [r10-0x470]
  ldxdw r2, [r1+0x0]
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r3, r6
  call fn_3a90
  ldxw r1, [r10-0x1cc]
  ldxw r0, [r10-0x1d0]
  ldxb r7, [r10-0x7]
  jeq r7, 0x2, jmp_1f2e8
  mov64 r3, r10
  add64 r3, -0x398
  mov64 r2, r10
  add64 r2, -0x1c8
  stxdw [r10-0x498], r1
  mov64 r1, r3
  mov64 r3, 0x1c1
  stxdw [r10-0x4a0], r0
  call fn_2c060
  ldxw r1, [r10-0x6]
  stxw [r10-0x1d6], r1
  ldxh r1, [r10-0x2]
  stxh [r10-0x1d2], r1
  ldxdw r1, [r10-0x498]
  stxw [r10-0x39c], r1
  ldxdw r1, [r10-0x4a0]
  stxw [r10-0x3a0], r1
  mov64 r0, 0x0
  mov64 r1, 0x18
  stxb [r10-0x1d7], r7
  and64 r7, 0x1
  jne r7, 0x0, jmp_1f2e8
  mov64 r1, 0x3
  ldxdw r3, [r8+0x0]
  ldxb r2, [r3+0x1]
  jeq r2, 0x0, jmp_1f2e8
  ldxdw r2, [r3+0x8]
  ldxdw r4, [r10-0x3a0]
  jne r2, r4, jmp_1f2e8
  ldxdw r5, [r10-0x398]
  ldxdw r4, [r3+0x10]
  jne r4, r5, jmp_1f2e8
  ldxdw r7, [r10-0x390]
  ldxdw r5, [r3+0x18]
  jne r5, r7, jmp_1f2e8
  ldxdw r7, [r10-0x388]
  ldxdw r3, [r3+0x20]
  jne r3, r7, jmp_1f2e8
  ldxdw r7, [r10-0x458]
  jeq r7, 0x0, jmp_1f710
  ldxdw r6, [r10-0x478]
  jne r2, r6, jmp_1f2e8
  ldxdw r2, [r10-0x490]
  ldxdw r6, [r10-0x480]
  jne r4, r6, jmp_1f2e8
  ldxdw r4, [r10-0x488]
  jne r5, r4, jmp_1f2e8
  jne r3, r2, jmp_1f2e8
  ldxdw r7, [r10-0x410]
  stdw [r10-0x410], 0x0

jmp_1f5a8:
  ldxdw r2, [r10-0x270]
  mov64 r1, r2
  add64 r1, r7
  mov64 r3, 0x1
  jlt r1, r2, jmp_1f5d8
  mov64 r3, 0x0

jmp_1f5d8:
  mov64 r1, 0x4
  and64 r3, 0x1
  jne r3, 0x0, jmp_1f2e8
  mov64 r3, r7
  add64 r3, r2
  stxdw [r10-0x270], r3
  ldxdw r2, [r10-0x428]
  mov64 r4, r2
  add64 r4, r7
  mov64 r3, 0x1
  jlt r4, r2, jmp_1f638
  mov64 r3, 0x0

jmp_1f638:
  and64 r3, 0x1
  jne r3, 0x0, jmp_1f2e8
  add64 r7, r2
  stxdw [r10-0x428], r7
  mov64 r1, r10
  add64 r1, -0x450
  call fn_2a1d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r0, 0x0
  jne r1, 0x0, jmp_1f2e8
  ldxdw r1, [r10-0x470]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x3a0
  call fn_2458
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1f2e8
  ldxdw r1, [r10-0x468]
  ldxdw r1, [r1+0x0]
  mov64 r2, r10
  add64 r2, -0x450
  call fn_35c0
  ja jmp_1f2e8

jmp_1f710:
  ldxdw r2, [r10-0x438]
  ldxdw r1, [r10-0x440]
  mov64 r3, r10
  add64 r3, -0x3a0
  call fn_1d778
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_1f2e8
  ldxdw r4, [r10-0x460]
  sub64 r4, r9
  lsh64 r9, 0x3
  add64 r8, r9
  ldxdw r7, [r10-0x238]
  mov64 r1, r10
  add64 r1, -0x3a0
  stxdw [r10-0x1000], r1
  stxdw [r10-0xff8], r7
  mov64 r1, r10
  add64 r1, -0x1d0
  mov64 r5, r10
  mov64 r2, r6
  mov64 r3, r8
  call fn_1e440
  ldxw r1, [r10-0x1d0]
  jne r1, 0x0, jmp_1f368
  ldxdw r3, [r10-0x1c0]
  ldxdw r2, [r10-0x1c8]
  mov64 r4, r2
  add64 r4, r3
  mov64 r0, 0x0
  mov64 r1, 0x1
  jlt r4, r2, jmp_1f820
  mov64 r1, 0x0

jmp_1f820:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1f960
  mov64 r4, r3
  add64 r4, r2
  mov64 r5, r7
  add64 r5, r4
  mov64 r1, 0x1
  jlt r5, r7, jmp_1f868
  mov64 r1, 0x0

jmp_1f868:
  and64 r1, 0x1
  jne r1, 0x0, jmp_1f960
  ldxdw r5, [r10-0x408]
  add64 r4, r7
  mov64 r1, 0xb
  jlt r5, r4, jmp_1f2e8
  sub64 r5, r4
  stxdw [r10-0x408], r5
  ldxdw r1, [r10-0x410]
  mov64 r5, r1
  add64 r5, r3
  mov64 r4, 0x1
  jlt r5, r1, jmp_1f8d8
  mov64 r4, 0x0

jmp_1f8d8:
  and64 r4, 0x1
  jne r4, 0x0, jmp_1f960
  add64 r3, r1
  stxdw [r10-0x410], r3
  ldxdw r3, [r10-0x428]
  mov64 r1, r3
  add64 r1, r2
  mov64 r4, 0x1
  jlt r1, r3, jmp_1f928
  mov64 r4, 0x0

jmp_1f928:
  and64 r4, 0x1
  mov64 r1, 0x4
  jne r4, 0x0, jmp_1f2e8
  add64 r2, r3
  stxdw [r10-0x428], r2
  stdw [r10-0x238], 0x0
  ja jmp_1f5a8

jmp_1f960:
  mov64 r1, 0x4
  ja jmp_1f2e8

fn_1f970:
  mov64 r0, 0x0
  ldxdw r3, [r1+0x0]
  ldxdw r4, [r2+0x0]
  jne r3, r4, jmp_1fa10
  jeq r3, 0x5, jmp_1f9d0
  mov64 r0, 0x1
  jne r3, 0x0, jmp_1fa10
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r1+0x8]
  mov64 r0, 0x0
  jeq r4, r3, jmp_1f9e8
  ja jmp_1fa10

jmp_1f9d0:
  ldxdw r3, [r2+0x8]
  ldxdw r4, [r1+0x8]
  jne r4, r3, jmp_1fa10

jmp_1f9e8:
  ldxdw r2, [r2+0x10]
  ldxdw r1, [r1+0x10]
  mov64 r0, 0x1
  jeq r1, r2, jmp_1fa10
  mov64 r0, 0x0

jmp_1fa10:
  and64 r0, 0x1
  exit

entrypoint:
  mov64 r2, r1
  add64 r2, 0x8
  ldxdw r0, [r1+0x0]
  jeq r0, 0x0, jmp_1fb38
  ldxdw r3, [r1+0x58]
  stxw [r1+0xc], r3
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2868
  add64 r1, 0x286f
  mov64 r3, 0x1
  jlt r1, r4, jmp_1fa88
  mov64 r3, 0x0

jmp_1fa88:
  stxdw [r10-0xc70], r2
  and64 r3, 0x1
  jne r3, 0x0, jmp_23dc0
  and64 r1, -0x8
  jeq r0, 0x1, jmp_204e0
  jne r0, 0x2, jmp_1fb48
  ldxb r2, [r1+0x0]
  jne r2, 0xff, jmp_23088
  ldxdw r3, [r1+0x50]
  mov64 r2, r1
  add64 r2, r3
  mov64 r5, r2
  add64 r5, 0x2860
  add64 r2, 0x2867
  mov64 r4, 0x1
  jlt r2, r5, jmp_1fb10
  mov64 r4, 0x0

jmp_1fb10:
  stxw [r1+0x4], r3
  stxdw [r10-0xc68], r1
  and64 r4, 0x1
  jne r4, 0x0, jmp_24760
  and64 r2, -0x8

jmp_1fb38:
  mov64 r1, r2
  ja jmp_204e0

jmp_1fb48:
  mov64 r2, r10
  add64 r2, -0xc70
  mov64 r3, r0
  jlt r0, 0x6, jmp_1ff90
  mov64 r2, r10
  add64 r2, -0xc70
  mov64 r3, r0

jmp_1fb80:
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_1fe20
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x8], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_1fbe8
  mov64 r4, 0x0

jmp_1fbe8:
  and64 r4, 0x1
  jne r4, 0x0, jmp_235c0
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_1fe68

jmp_1fc10:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x10], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_1fc68
  mov64 r4, 0x0

jmp_1fc68:
  and64 r4, 0x1
  jne r4, 0x0, jmp_235c0
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_1feb0

jmp_1fc90:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x18], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_1fce8
  mov64 r4, 0x0

jmp_1fce8:
  and64 r4, 0x1
  jne r4, 0x0, jmp_235c0
  and64 r1, -0x8
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_1fef8

jmp_1fd10:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x20], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_1fd68
  mov64 r4, 0x0

jmp_1fd68:
  and64 r4, 0x1
  jne r4, 0x0, jmp_235c0
  and64 r1, -0x8
  add64 r2, 0x28
  ldxb r4, [r1+0x0]
  jne r4, 0xff, jmp_1ff48

jmp_1fd98:
  ldxdw r4, [r1+0x50]
  stxw [r1+0x4], r4
  stxdw [r2+0x0], r1
  ldxdw r4, [r1+0x50]
  add64 r1, r4
  mov64 r5, r1
  add64 r5, 0x2860
  add64 r1, 0x2867
  mov64 r4, 0x1
  jlt r1, r5, jmp_1fdf0
  mov64 r4, 0x0

jmp_1fdf0:
  and64 r4, 0x1
  jne r4, 0x0, jmp_235c0
  and64 r1, -0x8
  add64 r3, -0x5
  jgt r3, 0x5, jmp_1fb80
  ja jmp_1ff90

jmp_1fe20:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x8], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_1fc10

jmp_1fe68:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x10], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_1fc90

jmp_1feb0:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x18], r4
  add64 r1, 0x8
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_1fd10

jmp_1fef8:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x20], r4
  add64 r1, 0x8
  add64 r2, 0x28
  ldxb r4, [r1+0x0]
  jeq r4, 0xff, jmp_1fd98

jmp_1ff48:
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  stxdw [r2+0x0], r4
  add64 r1, 0x8
  add64 r3, -0x5
  jgt r3, 0x5, jmp_1fb80

jmp_1ff90:
  jsle r3, 0x2, jmp_20138
  jeq r3, 0x3, jmp_201d0
  jne r3, 0x4, jmp_202e0
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_233b0
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x8], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_20010
  mov64 r3, 0x0

jmp_20010:
  and64 r3, 0x1
  jne r3, 0x0, jmp_20120
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_233f8

jmp_20038:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x10], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_20090
  mov64 r3, 0x0

jmp_20090:
  and64 r3, 0x1
  jne r3, 0x0, jmp_20120
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23440

jmp_200b8:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x18], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r3, r1
  add64 r3, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r3, jmp_20110
  mov64 r2, 0x0

jmp_20110:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_204d8

jmp_20120:
  lddw r1, data_06f0
  call fn_2bcf8

jmp_20138:
  jeq r3, 0x1, jmp_204e0
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23588
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x8], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r3, r1
  add64 r3, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r3, jmp_201a8
  mov64 r2, 0x0

jmp_201a8:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_204d8
  lddw r1, data_0720
  call fn_2bcf8

jmp_201d0:
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23330
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x8], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_20238
  mov64 r3, 0x0

jmp_20238:
  and64 r3, 0x1
  jne r3, 0x0, jmp_202c8
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23378

jmp_20260:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x10], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r3, r1
  add64 r3, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r3, jmp_202b8
  mov64 r2, 0x0

jmp_202b8:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_204d8

jmp_202c8:
  lddw r1, data_0708
  call fn_2bcf8

jmp_202e0:
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23478
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x8], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_20348
  mov64 r3, 0x0

jmp_20348:
  and64 r3, 0x1
  jne r3, 0x0, jmp_24778
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_234c0

jmp_20370:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x10], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_203c8
  mov64 r3, 0x0

jmp_203c8:
  and64 r3, 0x1
  jne r3, 0x0, jmp_24778
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23508

jmp_203f0:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x18], r1
  ldxdw r3, [r1+0x50]
  add64 r1, r3
  mov64 r4, r1
  add64 r4, 0x2860
  add64 r1, 0x2867
  mov64 r3, 0x1
  jlt r1, r4, jmp_20448
  mov64 r3, 0x0

jmp_20448:
  and64 r3, 0x1
  jne r3, 0x0, jmp_24778
  and64 r1, -0x8
  ldxb r3, [r1+0x0]
  jne r3, 0xff, jmp_23550

jmp_20470:
  ldxdw r3, [r1+0x50]
  stxw [r1+0x4], r3
  stxdw [r2+0x20], r1
  ldxdw r2, [r1+0x50]
  add64 r1, r2
  mov64 r3, r1
  add64 r3, 0x2860
  add64 r1, 0x2867
  mov64 r2, 0x1
  jlt r1, r3, jmp_204c8
  mov64 r2, 0x0

jmp_204c8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_24778

jmp_204d8:
  and64 r1, -0x8

jmp_204e0:
  mov64 r9, r1
  add64 r9, 0x8
  ldxdw r8, [r1+0x0]
  mov64 r3, r9
  add64 r3, r8
  jlt r8, 0x8, jmp_205a8
  ldxdw r4, [r9+0x0]
  lddw r2, 0x544e56455443
  jne r4, r2, jmp_205d0
  mov64 r2, 0x2
  jne r0, 0x2, jmp_20a80
  ldxdw r2, [r10-0xc70]
  ldxb r4, [r2+0x1]
  jeq r4, 0x0, jmp_20890
  mov64 r7, r1
  mov64 r1, r10
  add64 r1, -0x338
  mov64 r6, r3
  call fn_3820
  ldxb r1, [r10-0x1e6]
  jne r1, 0x2, jmp_20a38

jmp_20590:
  ldxw r2, [r10-0x334]
  ldxw r1, [r10-0x338]
  ja jmp_22a28

jmp_205a8:
  jne r8, 0x0, jmp_205c8
  mov64 r1, 0x0
  mov64 r2, 0x1
  ja jmp_22a28

jmp_205c8:
  ldxb r4, [r9+0x0]

jmp_205d0:
  mov64 r2, 0x1
  and64 r4, 0xff
  stxdw [r10-0xc78], r0
  jsgt r4, 0x17, jmp_20638
  jsgt r4, 0xb, jmp_20678
  jsgt r4, 0x5, jmp_208a8
  jsgt r4, 0x2, jmp_20a90
  jeq r4, 0x0, jmp_215e8
  jeq r4, 0x1, jmp_211e0
  jne r4, 0x2, jmp_22978
  jlt r8, 0x23, jmp_22978
  mov64 r6, 0x3
  ja jmp_212a0

jmp_20638:
  jsgt r4, 0x24, jmp_20850
  jsgt r4, 0x1d, jmp_208d8
  jsgt r4, 0x1a, jmp_20ac0
  jeq r4, 0x18, jmp_218d8
  jeq r4, 0x19, jmp_21230
  jne r4, 0x1a, jmp_22978
  mov64 r6, 0x21
  ja jmp_21f58

jmp_20678:
  jsgt r4, 0x11, jmp_20948
  jsgt r4, 0xe, jmp_20b00
  jeq r4, 0xc, jmp_21960
  jeq r4, 0xd, jmp_21240
  jne r4, 0xe, jmp_22978
  jlt r8, 0x31, jmp_22978
  ldxb r2, [r1+0x1b]
  lsh64 r2, 0x10
  ldxh r0, [r1+0x19]
  or64 r0, r2
  ldxb r2, [r1+0xb]
  lsh64 r2, 0x10
  mov64 r5, r3
  ldxh r4, [r1+0x9]
  or64 r4, r2
  ldxw r6, [r1+0xc]
  lsh64 r6, 0x18
  or64 r6, r4
  ldxw r7, [r1+0x1c]
  lsh64 r7, 0x18
  or64 r7, r0
  ldxb r2, [r1+0x28]
  lsh64 r2, 0x38
  ldxdw r3, [r1+0x20]
  mov64 r4, r3
  rsh64 r4, 0x8
  or64 r4, r2
  stxdw [r10-0xce0], r4
  ldxb r2, [r1+0x18]
  lsh64 r2, 0x38
  ldxdw r4, [r1+0x10]
  mov64 r0, r4
  rsh64 r0, 0x8
  or64 r0, r2
  stxdw [r10-0xcd0], r0
  lsh64 r3, 0x38
  or64 r7, r3
  stxdw [r10-0xce8], r7
  lsh64 r4, 0x38
  or64 r6, r4
  stxdw [r10-0xcc8], r6
  mov64 r3, r5
  mov64 r6, 0x1d
  mov64 r5, 0x0
  mov64 r2, 0x31
  ldxdw r4, [r1+0x31]
  stxdw [r10-0xcb0], r4
  rsh64 r4, 0x20
  stxdw [r10-0xcb8], r4
  ldxdw r1, [r1+0x29]
  mov64 r4, r1
  rsh64 r4, 0x20
  stxdw [r10-0xca0], r4
  mov64 r4, 0x0
  stxdw [r10-0xc88], r4
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_20850:
  jsgt r4, 0x2a, jmp_20978
  jsgt r4, 0x27, jmp_20b28
  jeq r4, 0x25, jmp_219e8
  jeq r4, 0x26, jmp_21250
  jne r4, 0x27, jmp_22978
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x2f
  ja jmp_21c30

jmp_20890:
  mov64 r2, 0x3
  mov64 r1, 0x0
  ja jmp_22a28

jmp_208a8:
  jsgt r4, 0x8, jmp_20b58
  jeq r4, 0x6, jmp_21a48
  jeq r4, 0x7, jmp_21278
  jne r4, 0x8, jmp_22978
  mov64 r6, 0x17
  ja jmp_21f58

jmp_208d8:
  jsgt r4, 0x20, jmp_20b80
  jeq r4, 0x1e, jmp_21ab8
  jeq r4, 0x1f, jmp_21290
  jne r4, 0x20, jmp_22978
  jeq r8, 0x1, jmp_22978
  mov64 r5, 0x0
  ldxb r1, [r1+0x9]
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_20930
  jne r1, 0x1, jmp_22978
  mov64 r2, 0x1

jmp_20930:
  stxdw [r10-0xcd8], r2
  mov64 r6, 0x5
  ja jmp_219a8

jmp_20948:
  jsgt r4, 0x14, jmp_20bb0
  jeq r4, 0x12, jmp_21ad0
  jeq r4, 0x13, jmp_21358
  jne r4, 0x14, jmp_22978
  mov64 r6, 0x26
  ja jmp_21f58

jmp_20978:
  jsgt r4, 0x2d, jmp_20e58
  jeq r4, 0x2b, jmp_21ae0
  jeq r4, 0x2c, jmp_21368
  jne r4, 0x2d, jmp_22978
  jlt r8, 0x19, jmp_22978
  mov64 r6, 0x14
  mov64 r5, 0x0
  mov64 r2, 0x19
  ldxdw r4, [r1+0x19]
  stxdw [r10-0xcc8], r4
  ldxdw r4, [r1+0x11]
  stxdw [r10-0xcb0], r4
  rsh64 r4, 0x20
  stxdw [r10-0xcb8], r4
  ldxdw r1, [r1+0x9]
  mov64 r4, r1
  rsh64 r4, 0x20
  stxdw [r10-0xca0], r4
  mov64 r4, 0x0
  stxdw [r10-0xc88], r4
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_20a38:
  mov64 r2, 0x13
  ldxdw r1, [r9+0x0]
  lddw r3, 0x544e56455443
  jne r1, r3, jmp_20a80
  mov64 r1, 0x0
  jne r8, 0x8, jmp_20ee0

jmp_20a70:
  mov64 r2, 0x1
  ja jmp_22a28

jmp_20a80:
  mov64 r1, 0x0
  ja jmp_22a28

jmp_20a90:
  jeq r4, 0x3, jmp_21af8
  jeq r4, 0x4, jmp_213c0
  jne r4, 0x5, jmp_22978
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x10
  ja jmp_21c30

jmp_20ac0:
  jeq r4, 0x1b, jmp_21c08
  mov64 r5, 0x0
  stxdw [r10-0xc80], r5
  jeq r4, 0x1c, jmp_213d8
  jne r4, 0x1d, jmp_22978
  jlt r8, 0x5, jmp_22978
  mov64 r6, 0x2b
  ja jmp_21388

jmp_20b00:
  jeq r4, 0xf, jmp_21c20
  jeq r4, 0x10, jmp_21410
  jne r4, 0x11, jmp_22978
  mov64 r6, 0x20
  ja jmp_21f58

jmp_20b28:
  jeq r4, 0x28, jmp_21c90
  jeq r4, 0x29, jmp_21428
  jne r4, 0x2a, jmp_22978
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0x7
  ja jmp_22900

jmp_20b58:
  jeq r4, 0x9, jmp_21f28
  jeq r4, 0xa, jmp_21498
  jne r4, 0xb, jmp_22978
  mov64 r6, 0x1a
  ja jmp_21f58

jmp_20b80:
  jeq r4, 0x21, jmp_21f38
  jeq r4, 0x23, jmp_21570
  jne r4, 0x24, jmp_22978
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0xe
  ja jmp_21c30

jmp_20bb0:
  jeq r4, 0x15, jmp_21f50
  jeq r4, 0x16, jmp_21588
  jne r4, 0x17, jmp_22978
  jlt r8, 0x21, jmp_22978
  jlt r8, 0x41, jmp_22978
  jlt r8, 0x61, jmp_22978
  jlt r8, 0xa1, jmp_22978
  ldxb r2, [r1+0x28]
  ldxdw r4, [r1+0x20]
  stxdw [r10-0xcc8], r4
  ldxdw r4, [r1+0x18]
  stxdw [r10-0xcb0], r4
  ldxdw r4, [r1+0x10]
  stxdw [r10-0xc80], r4
  ldxw r4, [r1+0xc]
  stxdw [r10-0xc88], r4
  ldxb r4, [r1+0x9]
  stxdw [r10-0xcd8], r4
  ldxh r0, [r1+0xa]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ldxh r4, [r1+0x29]
  lsh64 r4, 0x8
  ldxb r6, [r1+0x2b]
  lsh64 r6, 0x18
  or64 r6, r4
  ldxdw r4, [r1+0x38]
  stxdw [r10-0xce0], r4
  ldxdw r4, [r1+0x30]
  stxdw [r10-0xce8], r4
  mov64 r4, r1
  add64 r4, 0x40
  ldxw r7, [r1+0x2c]
  ldxw r5, [r1+0x6c]
  stxdw [r10-0xcf8], r5
  ldxw r5, [r1+0x4c]
  stxdw [r10-0xd00], r5
  ldxb r5, [r1+0x8b]
  stxb [r10-0x16], r5
  ldxh r5, [r1+0x89]
  stxh [r10-0x18], r5
  ldxw r5, [r1+0x8c]
  stxdw [r10-0xcf0], r5
  ldxb r5, [r1+0xa8]
  stxb [r10-0x20], r5
  ldxdw r5, [r1+0xa0]
  stxdw [r10-0x28], r5
  ldxdw r5, [r1+0x98]
  stxdw [r10-0x30], r5
  ldxdw r5, [r1+0x90]
  stxdw [r10-0x38], r5
  ldxb r5, [r4+0x8]
  stxb [r10-0x8], r5
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x10], r4
  or64 r6, r2
  ldxh r2, [r1+0x49]
  stxh [r10-0x7], r2
  ldxb r2, [r1+0x4b]
  stxb [r10-0x5], r2
  lsh64 r7, 0x20
  or64 r6, r7
  stxdw [r10-0xcd0], r6
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x120], r2
  ldxdw r2, [r1+0x58]
  stxdw [r10-0x118], r2
  ldxdw r2, [r1+0x60]
  stxdw [r10-0x110], r2
  ldxb r2, [r1+0x68]
  stxb [r10-0x108], r2
  ldxh r2, [r1+0x69]
  stxh [r10-0x14], r2
  ldxb r2, [r1+0x6b]
  stxb [r10-0x12], r2
  ldxdw r2, [r1+0x70]
  stxdw [r10-0x78], r2
  ldxdw r2, [r1+0x78]
  stxdw [r10-0x70], r2
  ldxdw r2, [r1+0x80]
  stxdw [r10-0x68], r2
  ldxb r1, [r1+0x88]
  stxb [r10-0x60], r1
  mov64 r6, 0x29
  ja jmp_21870

jmp_20e58:
  jeq r4, 0x2e, jmp_228f0
  jeq r4, 0x2f, jmp_21598
  mov64 r2, 0x0
  stxdw [r10-0xc80], r2
  jne r4, 0x31, jmp_22978
  jlt r8, 0x7, jmp_22978
  mov64 r6, 0x2c
  mov64 r2, 0x7
  ldxw r5, [r1+0xb]
  lddw r4, 0xffff0000
  stxdw [r10-0xc88], r5
  and64 r5, r4
  ldxh r0, [r1+0x9]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ja jmp_213b8

jmp_20ee0:
  mov64 r3, r7
  ldxb r3, [r3+0x10]
  jne r3, 0x1, jmp_22a28
  jlt r8, 0xa, jmp_20a70
  jlt r8, 0xc, jmp_20a70
  jlt r8, 0x14, jmp_20a70
  jlt r8, 0x24, jmp_20a70
  jlt r8, 0x34, jmp_20a70
  jlt r8, 0x44, jmp_20a70
  jlt r8, 0x54, jmp_20a70
  jlt r8, 0x64, jmp_20a70
  jlt r8, 0x74, jmp_20a70
  mov64 r1, r7
  ldxb r4, [r1+0x11]
  ldxh r2, [r1+0x12]
  stxdw [r10-0xce0], r2
  ldxdw r2, [r1+0x14]
  stxdw [r10-0xce8], r2
  ldxb r2, [r1+0x2b]
  stxdw [r10-0xca0], r2
  ldxdw r0, [r1+0x23]
  ldxb r2, [r1+0x1e]
  stxdw [r10-0xd68], r2
  ldxh r2, [r1+0x1c]
  stxdw [r10-0xd60], r2
  ldxw r2, [r1+0x1f]
  stxdw [r10-0xc80], r2
  ldxb r2, [r1+0x3b]
  stxdw [r10-0xc98], r2
  ldxdw r5, [r1+0x33]
  ldxb r2, [r1+0x2e]
  stxdw [r10-0xd58], r2
  ldxh r2, [r1+0x2c]
  stxdw [r10-0xd50], r2
  ldxw r2, [r1+0x2f]
  stxdw [r10-0xca8], r2
  ldxb r2, [r1+0x4b]
  stxdw [r10-0xc90], r2
  ldxdw r2, [r1+0x43]
  stxdw [r10-0xd38], r2
  ldxb r2, [r1+0x3e]
  stxdw [r10-0xd48], r2
  ldxh r2, [r1+0x3c]
  stxdw [r10-0xd40], r2
  ldxw r2, [r1+0x3f]
  stxdw [r10-0xcb0], r2
  ldxb r2, [r1+0x5b]
  stxdw [r10-0xc88], r2
  ldxdw r2, [r1+0x53]
  stxdw [r10-0xd20], r2
  ldxb r2, [r1+0x4e]
  stxdw [r10-0xd30], r2
  ldxh r2, [r1+0x4c]
  stxdw [r10-0xd28], r2
  ldxw r2, [r1+0x4f]
  stxdw [r10-0xcb8], r2
  ldxb r2, [r1+0x6b]
  stxdw [r10-0xcc0], r2
  ldxdw r2, [r1+0x63]
  stxdw [r10-0xd08], r2
  ldxb r2, [r1+0x5e]
  stxdw [r10-0xd18], r2
  ldxh r2, [r1+0x5c]
  stxdw [r10-0xd10], r2
  ldxw r2, [r1+0x5f]
  stxdw [r10-0xcc8], r2
  ldxb r2, [r1+0x7b]
  stxdw [r10-0xcd0], r2
  ldxdw r2, [r1+0x73]
  stxdw [r10-0xcf0], r2
  ldxb r2, [r1+0x6e]
  stxdw [r10-0xd00], r2
  ldxh r2, [r1+0x6c]
  stxdw [r10-0xcf8], r2
  ldxw r1, [r1+0x6f]
  stxdw [r10-0xcd8], r1
  stxdw [r10-0xc78], r4
  jsgt r4, 0x1a, jmp_23928
  ldxdw r1, [r10-0xc78]
  jsle r1, 0x6, jmp_239f0
  ldxdw r1, [r10-0xc78]
  jsgt r1, 0xd, jmp_23b40
  ldxdw r1, [r10-0xc78]
  add64 r1, -0x7
  jlt r1, 0x2, jmp_23c28
  ldxdw r1, [r10-0xc78]
  jne r1, 0xd, jmp_23da8
  jlt r8, 0x84, jmp_23da8
  mov64 r1, 0x4
  stxdw [r10-0xd70], r1
  mov64 r9, 0x84
  ldxdw r1, [r7+0x84]
  stxdw [r10-0xd80], r1
  ldxdw r1, [r7+0x7c]
  stxdw [r10-0xd78], r1
  ja jmp_23d80

jmp_211e0:
  jlt r8, 0x5, jmp_22978
  mov64 r6, 0x2
  mov64 r5, 0x0
  mov64 r2, 0x5
  ldxh r4, [r1+0xb]
  stxdw [r10-0xc88], r4
  ldxh r0, [r1+0x9]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ja jmp_21f70

jmp_21230:
  mov64 r6, 0x23
  ja jmp_21f58

jmp_21240:
  mov64 r6, 0x1c
  ja jmp_21f58

jmp_21250:
  mov64 r2, 0x0
  stxdw [r10-0xc80], r2
  jlt r8, 0x5, jmp_22978
  mov64 r6, 0xa
  ja jmp_21388

jmp_21278:
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0x12
  ja jmp_22900

jmp_21290:
  jlt r8, 0x23, jmp_22978
  mov64 r6, 0x4

jmp_212a0:
  mov64 r5, 0x0
  mov64 r2, 0x23
  ldxdw r4, [r1+0x23]
  stxdw [r10-0xcd0], r4
  ldxdw r4, [r1+0x1b]
  stxdw [r10-0xcc8], r4
  ldxdw r4, [r1+0x13]
  stxdw [r10-0xcb0], r4
  rsh64 r4, 0x20
  stxdw [r10-0xcb8], r4
  ldxdw r4, [r1+0xb]
  mov64 r0, r4
  rsh64 r0, 0x20
  stxdw [r10-0xca0], r0
  ldxh r0, [r1+0x9]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  mov64 r1, 0x0
  stxdw [r10-0xc88], r1
  stxdw [r10-0xc80], r4
  stxdw [r10-0xc90], r4
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21358:
  mov64 r6, 0x25
  ja jmp_21f58

jmp_21368:
  mov64 r2, 0x0
  stxdw [r10-0xc80], r2
  jlt r8, 0x5, jmp_22978
  mov64 r6, 0x9

jmp_21388:
  mov64 r2, 0x5
  ldxw r5, [r1+0x9]
  lddw r1, 0xffff0000
  stxdw [r10-0xc88], r5
  and64 r5, r1

jmp_213b8:
  ja jmp_213f0

jmp_213c0:
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0xc
  ja jmp_21c30

jmp_213d8:
  mov64 r6, 0x22
  mov64 r1, 0x0
  stxdw [r10-0xc88], r1

jmp_213f0:
  mov64 r1, 0x0
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21410:
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x1f
  ja jmp_21c30

jmp_21428:
  jlt r8, 0x3, jmp_22978
  mov64 r5, 0x0
  mov64 r2, 0x3
  ldxh r0, [r1+0x9]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  mov64 r1, 0x0
  stxdw [r10-0xc88], r1
  mov64 r1, 0x0
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  mov64 r6, 0x0
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21498:
  jlt r8, 0x21, jmp_22978
  mov64 r6, 0x19
  mov64 r2, 0x21
  ldxb r4, [r1+0x28]
  stxdw [r10-0xcd0], r4
  ldxdw r4, [r1+0x20]
  stxdw [r10-0xcc8], r4
  ldxb r4, [r1+0x9]
  stxdw [r10-0xcd8], r4
  ldxdw r4, [r1+0x18]
  stxdw [r10-0xcb0], r4
  rsh64 r4, 0x20
  stxdw [r10-0xcb8], r4
  ldxdw r4, [r1+0x10]
  mov64 r5, r4
  rsh64 r5, 0x20
  stxdw [r10-0xca0], r5
  ldxw r5, [r1+0xc]
  stxdw [r10-0xc88], r5
  and64 r5, -0x10000
  ldxh r0, [r1+0xa]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  stxdw [r10-0xc80], r4
  stxdw [r10-0xc90], r4
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21570:
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x8
  ja jmp_21c30

jmp_21588:
  mov64 r6, 0x28
  ja jmp_21f58

jmp_21598:
  jeq r8, 0x1, jmp_22978
  mov64 r5, 0x0
  ldxb r1, [r1+0x9]
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_215d0
  jne r1, 0x1, jmp_22978
  mov64 r2, 0x1

jmp_215d0:
  stxdw [r10-0xcd8], r2
  mov64 r6, 0x15
  ja jmp_219a8

jmp_215e8:
  jlt r8, 0x21, jmp_22978
  jlt r8, 0x41, jmp_22978
  jlt r8, 0x61, jmp_22978
  jlt r8, 0xa1, jmp_22978
  ldxb r2, [r1+0x28]
  ldxdw r4, [r1+0x20]
  stxdw [r10-0xcc8], r4
  ldxdw r4, [r1+0x18]
  stxdw [r10-0xcb0], r4
  ldxdw r4, [r1+0x10]
  stxdw [r10-0xc80], r4
  ldxw r4, [r1+0xc]
  stxdw [r10-0xc88], r4
  ldxb r4, [r1+0x9]
  stxdw [r10-0xcd8], r4
  ldxh r0, [r1+0xa]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ldxh r4, [r1+0x29]
  lsh64 r4, 0x8
  ldxb r6, [r1+0x2b]
  lsh64 r6, 0x18
  or64 r6, r4
  ldxdw r4, [r1+0x38]
  stxdw [r10-0xce0], r4
  ldxdw r4, [r1+0x30]
  stxdw [r10-0xce8], r4
  mov64 r4, r1
  add64 r4, 0x40
  ldxw r7, [r1+0x2c]
  ldxw r5, [r1+0x6c]
  stxdw [r10-0xcf8], r5
  ldxw r5, [r1+0x4c]
  stxdw [r10-0xd00], r5
  ldxb r5, [r1+0x8b]
  stxb [r10-0x16], r5
  ldxh r5, [r1+0x89]
  stxh [r10-0x18], r5
  ldxw r5, [r1+0x8c]
  stxdw [r10-0xcf0], r5
  ldxb r5, [r1+0xa8]
  stxb [r10-0x20], r5
  ldxdw r5, [r1+0xa0]
  stxdw [r10-0x28], r5
  ldxdw r5, [r1+0x98]
  stxdw [r10-0x30], r5
  ldxdw r5, [r1+0x90]
  stxdw [r10-0x38], r5
  ldxb r5, [r4+0x8]
  stxb [r10-0x8], r5
  ldxdw r4, [r4+0x0]
  stxdw [r10-0x10], r4
  or64 r6, r2
  ldxh r2, [r1+0x49]
  stxh [r10-0x7], r2
  ldxb r2, [r1+0x4b]
  stxb [r10-0x5], r2
  lsh64 r7, 0x20
  or64 r6, r7
  stxdw [r10-0xcd0], r6
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x120], r2
  ldxdw r2, [r1+0x58]
  stxdw [r10-0x118], r2
  ldxdw r2, [r1+0x60]
  stxdw [r10-0x110], r2
  ldxb r2, [r1+0x68]
  stxb [r10-0x108], r2
  ldxh r2, [r1+0x69]
  stxh [r10-0x14], r2
  ldxb r2, [r1+0x6b]
  stxb [r10-0x12], r2
  ldxdw r2, [r1+0x70]
  stxdw [r10-0x78], r2
  ldxdw r2, [r1+0x78]
  stxdw [r10-0x70], r2
  ldxdw r2, [r1+0x80]
  stxdw [r10-0x68], r2
  ldxb r1, [r1+0x88]
  stxb [r10-0x60], r1
  mov64 r6, 0x1

jmp_21870:
  mov64 r2, 0xa1
  ldxdw r1, [r10-0xcb0]
  rsh64 r1, 0x20
  stxdw [r10-0xcb8], r1
  ldxdw r4, [r10-0xc80]
  mov64 r1, r4
  rsh64 r1, 0x20
  stxdw [r10-0xca0], r1
  ldxdw r5, [r10-0xc88]
  and64 r5, -0x10000
  stxdw [r10-0xc90], r4
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_218d8:
  jlt r8, 0xd, jmp_22978
  mov64 r6, 0x2a
  mov64 r5, 0x0
  mov64 r2, 0xd
  ldxh r4, [r1+0xb]
  stxdw [r10-0xc88], r4
  ldxdw r4, [r1+0xd]
  mov64 r0, r4
  rsh64 r0, 0x20
  stxdw [r10-0xca0], r0
  ldxh r0, [r1+0x9]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  stxdw [r10-0xc80], r4
  stxdw [r10-0xc90], r4
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21960:
  jeq r8, 0x1, jmp_22978
  mov64 r5, 0x0
  ldxb r1, [r1+0x9]
  mov64 r2, 0x0
  jeq r1, 0x0, jmp_21998
  jne r1, 0x1, jmp_22978
  mov64 r2, 0x1

jmp_21998:
  stxdw [r10-0xcd8], r2
  mov64 r6, 0x1b

jmp_219a8:
  mov64 r2, 0x2
  mov64 r1, 0x0
  stxdw [r10-0xc88], r1
  mov64 r1, 0x0
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_219e8:
  jlt r8, 0xb, jmp_22978
  mov64 r6, 0xf
  mov64 r5, 0x0
  mov64 r2, 0xb
  ldxh r0, [r1+0x11]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ldxdw r1, [r1+0x9]
  mov64 r4, r1
  rsh64 r4, 0x20
  stxdw [r10-0xca0], r4
  ja jmp_21c60

jmp_21a48:
  jlt r8, 0x3, jmp_22978
  jlt r8, 0xb, jmp_22978
  jlt r8, 0xd, jmp_22978
  jeq r8, 0xd, jmp_22978
  ldxh r2, [r1+0x9]
  stxdw [r10-0xc88], r2
  ldxdw r2, [r1+0xb]
  stxdw [r10-0xcc8], r2
  ldxh r4, [r1+0x13]
  ldxb r2, [r1+0x15]
  jeq r2, 0x0, jmp_23048
  jne r2, 0x1, jmp_22978
  mov64 r2, 0x1
  ja jmp_23050

jmp_21ab8:
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x2d
  ja jmp_21c30

jmp_21ad0:
  mov64 r6, 0x24
  ja jmp_21f58

jmp_21ae0:
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0xd
  ja jmp_22900

jmp_21af8:
  jlt r8, 0x31, jmp_22978
  ldxh r2, [r1+0x9]
  lsh64 r2, 0x8
  ldxb r4, [r1+0xb]
  lsh64 r4, 0x18
  or64 r4, r2
  ldxb r2, [r1+0x38]
  or64 r4, r2
  stxdw [r10-0xcb0], r4
  mov64 r6, 0xb
  mov64 r2, 0x31
  ldxb r4, [r1+0x29]
  stxdw [r10-0xcd8], r4
  ldxw r4, [r1+0xc]
  stxdw [r10-0xcb8], r4
  ldxdw r4, [r1+0x20]
  stxdw [r10-0xce8], r4
  ldxdw r4, [r1+0x10]
  stxdw [r10-0xcc8], r4
  ldxdw r4, [r1+0x18]
  stxdw [r10-0xcd0], r4
  ldxb r4, [r1+0x28]
  stxdw [r10-0xce0], r4
  ldxdw r4, [r1+0x30]
  mov64 r5, r4
  rsh64 r5, 0x20
  stxdw [r10-0xca0], r5
  ldxw r5, [r1+0x2c]
  stxdw [r10-0xc88], r5
  and64 r5, -0x10000
  ldxh r0, [r1+0x2a]
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8
  ja jmp_21f08

jmp_21c08:
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0x13
  ja jmp_22900

jmp_21c20:
  jlt r8, 0x9, jmp_22978
  mov64 r6, 0x1e

jmp_21c30:
  mov64 r5, 0x0
  mov64 r2, 0x9
  ldxdw r1, [r1+0x9]
  mov64 r4, r1
  rsh64 r4, 0x20
  stxdw [r10-0xca0], r4

jmp_21c60:
  mov64 r4, 0x0
  stxdw [r10-0xc88], r4
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21c90:
  jlt r8, 0xc9, jmp_22978
  ldxdw r2, [r1+0x38]
  stxdw [r10-0xce0], r2
  ldxdw r2, [r1+0x30]
  stxdw [r10-0xce8], r2
  ldxdw r2, [r1+0x28]
  stxdw [r10-0xcd0], r2
  ldxdw r2, [r1+0x20]
  stxdw [r10-0xcc8], r2
  ldxb r2, [r1+0x9]
  stxdw [r10-0xcd8], r2
  ldxh r0, [r1+0xa]
  ldxw r5, [r1+0xc]
  ldxdw r4, [r1+0x10]
  ldxdw r7, [r1+0x18]
  ldxdw r2, [r1+0x40]
  stxdw [r10-0x10], r2
  ldxw r2, [r1+0x48]
  stxw [r10-0x8], r2
  ldxw r2, [r1+0x4c]
  stxdw [r10-0xd00], r2
  ldxb r2, [r1+0x68]
  stxb [r10-0x108], r2
  ldxdw r2, [r1+0x60]
  stxdw [r10-0x110], r2
  ldxdw r2, [r1+0x58]
  stxdw [r10-0x118], r2
  ldxdw r2, [r1+0x50]
  stxdw [r10-0x120], r2
  ldxb r2, [r1+0x6b]
  stxb [r10-0x12], r2
  ldxh r2, [r1+0x69]
  stxh [r10-0x14], r2
  ldxw r2, [r1+0x6c]
  stxdw [r10-0xcf8], r2
  ldxb r2, [r1+0x88]
  stxb [r10-0x60], r2
  ldxdw r2, [r1+0x80]
  stxdw [r10-0x68], r2
  ldxdw r2, [r1+0x78]
  stxdw [r10-0x70], r2
  ldxdw r2, [r1+0x70]
  stxdw [r10-0x78], r2
  ldxh r2, [r1+0x89]
  stxh [r10-0x18], r2
  ldxb r2, [r1+0x8b]
  stxb [r10-0x16], r2
  ldxw r2, [r1+0x8c]
  stxdw [r10-0xcf0], r2
  ldxdw r2, [r1+0x90]
  stxdw [r10-0x38], r2
  ldxdw r2, [r1+0x98]
  stxdw [r10-0x30], r2
  ldxdw r2, [r1+0xa0]
  stxdw [r10-0x28], r2
  ldxb r2, [r1+0xa8]
  stxb [r10-0x20], r2
  ldxdw r2, [r1+0xa9]
  stxdw [r10-0x338], r2
  ldxdw r2, [r1+0xb1]
  stxdw [r10-0x330], r2
  ldxdw r2, [r1+0xb9]
  stxdw [r10-0x328], r2
  ldxdw r2, [r1+0xc1]
  stxdw [r10-0x320], r2
  ldxdw r1, [r1+0xc9]
  stxdw [r10-0x318], r1
  mov64 r6, 0x2e
  mov64 r2, 0xc9
  stxdw [r10-0xcb0], r7
  rsh64 r7, 0x20
  stxdw [r10-0xcb8], r7
  mov64 r1, r4
  rsh64 r1, 0x20
  stxdw [r10-0xca0], r1
  stxdw [r10-0xc88], r5
  and64 r5, -0x10000
  stxdw [r10-0xcc0], r0
  rsh64 r0, 0x8

jmp_21f08:
  stxdw [r10-0xc80], r4
  stxdw [r10-0xc90], r4
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_21f28:
  mov64 r6, 0x18
  ja jmp_21f58

jmp_21f38:
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0x6
  ja jmp_22900

jmp_21f50:
  mov64 r6, 0x27

jmp_21f58:
  mov64 r5, 0x0
  mov64 r1, 0x0
  stxdw [r10-0xc88], r1

jmp_21f70:
  mov64 r1, 0x0
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jne r2, r8, jmp_22978

jmp_21f90:
  stxdw [r10-0xca8], r3
  ldxw r1, [r10-0x8]
  stxw [r10-0x410], r1
  ldxdw r1, [r10-0x10]
  stxdw [r10-0x418], r1
  ldxdw r1, [r10-0x120]
  stxdw [r10-0x438], r1
  ldxdw r1, [r10-0x118]
  stxdw [r10-0x430], r1
  ldxdw r1, [r10-0x110]
  stxdw [r10-0x428], r1
  ldxb r1, [r10-0x108]
  stxb [r10-0x420], r1
  ldxh r1, [r10-0x14]
  stxh [r10-0x43c], r1
  ldxb r1, [r10-0x12]
  stxb [r10-0x43a], r1
  ldxb r1, [r10-0x60]
  stxb [r10-0x440], r1
  ldxdw r1, [r10-0x68]
  stxdw [r10-0x448], r1
  ldxdw r1, [r10-0x70]
  stxdw [r10-0x450], r1
  ldxdw r1, [r10-0x78]
  stxdw [r10-0x458], r1
  ldxb r1, [r10-0x16]
  stxb [r10-0x45a], r1
  ldxh r1, [r10-0x18]
  stxh [r10-0x45c], r1
  ldxdw r1, [r10-0x38]
  stxdw [r10-0x478], r1
  ldxdw r1, [r10-0x30]
  stxdw [r10-0x470], r1
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x468], r1
  ldxb r1, [r10-0x20]
  stxb [r10-0x460], r1
  mov64 r8, r10
  add64 r8, -0x1e0
  mov64 r2, r10
  add64 r2, -0x338
  mov64 r1, r8
  mov64 r3, 0x2f
  stxdw [r10-0xc98], r9
  mov64 r9, r6
  mov64 r6, r0
  mov64 r7, r5
  call fn_2c060
  ldxdw r2, [r10-0xcb8]
  lsh64 r2, 0x20
  ldxdw r1, [r10-0xcb0]
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  or64 r2, r1
  ldxdw r1, [r10-0xcc0]
  and64 r1, 0xff
  lsh64 r6, 0x8
  or64 r6, r1
  ldxdw r1, [r10-0xce0]
  stxdw [r10-0x3d8], r1
  ldxdw r1, [r10-0xce8]
  stxdw [r10-0x3e0], r1
  ldxdw r1, [r10-0xcd0]
  stxdw [r10-0x3e8], r1
  ldxdw r1, [r10-0xcc8]
  stxdw [r10-0x3f0], r1
  stxdw [r10-0x3f8], r2
  ldxdw r1, [r10-0xca0]
  stxw [r10-0x3fc], r1
  ldxdw r1, [r10-0xcd8]
  stxb [r10-0x407], r1
  ldxdw r1, [r10-0xd00]
  stxw [r10-0x3c4], r1
  ldxdw r1, [r10-0x418]
  stxdw [r10-0x3d0], r1
  ldxw r1, [r10-0x410]
  stxw [r10-0x3c8], r1
  stxdw [r10-0xca0], r6
  stxh [r10-0x406], r6
  mov64 r6, r9
  ldxb r1, [r10-0x420]
  stxb [r10-0x3a8], r1
  ldxdw r1, [r10-0x428]
  stxdw [r10-0x3b0], r1
  ldxdw r1, [r10-0x430]
  stxdw [r10-0x3b8], r1
  ldxdw r1, [r10-0x438]
  stxdw [r10-0x3c0], r1
  ldxb r1, [r10-0x43a]
  stxb [r10-0x3a5], r1
  ldxh r1, [r10-0x43c]
  stxh [r10-0x3a7], r1
  ldxdw r1, [r10-0xcf8]
  stxw [r10-0x3a4], r1
  ldxb r1, [r10-0x440]
  stxb [r10-0x388], r1
  ldxdw r1, [r10-0x448]
  stxdw [r10-0x390], r1
  ldxdw r1, [r10-0x450]
  stxdw [r10-0x398], r1
  ldxdw r1, [r10-0x458]
  stxdw [r10-0x3a0], r1
  ldxb r1, [r10-0x45a]
  stxb [r10-0x385], r1
  ldxh r1, [r10-0x45c]
  stxh [r10-0x387], r1
  ldxdw r1, [r10-0xcf0]
  stxw [r10-0x384], r1
  ldxb r1, [r10-0x460]
  stxb [r10-0x368], r1
  ldxdw r1, [r10-0x468]
  stxdw [r10-0x370], r1
  ldxdw r1, [r10-0x470]
  stxdw [r10-0x378], r1
  ldxdw r1, [r10-0x478]
  stxdw [r10-0x380], r1
  mov64 r1, r10
  add64 r1, -0x367
  mov64 r2, r8
  mov64 r3, 0x2f
  call fn_2c060
  ldxdw r3, [r10-0xc88]
  and64 r3, 0xffff
  or64 r3, r7
  lddw r1, 0xffff0000
  ldxdw r2, [r10-0xc80]
  and64 r2, r1
  ldxdw r1, [r10-0xc90]
  and64 r1, 0xffff
  or64 r2, r1
  stxw [r10-0x400], r2
  stxw [r10-0x404], r3
  stxb [r10-0x408], r6
  ldxdw r1, [r10-0xc98]
  ldxb r9, [r1+0x0]
  ldxdw r7, [r10-0xc78]
  jgt r6, 0x2d, jmp_22bc0
  mov64 r4, 0x0
  mov64 r1, 0x1
  lsh64 r1, r6
  mov64 r2, r1
  and64 r2, 0xce00c0
  jne r2, 0x0, jmp_22460
  lddw r2, 0x240030008004
  and64 r1, r2
  jeq r1, 0x0, jmp_22490
  mov64 r3, 0x1
  mov64 r8, 0x2
  mov64 r1, 0x0
  mov64 r2, 0x2
  jne r7, 0x0, jmp_224d8
  ja jmp_22990

jmp_22460:
  mov64 r3, 0x1
  mov64 r8, 0x5
  mov64 r1, 0x0
  mov64 r2, 0x2
  jne r7, 0x0, jmp_224d8
  ja jmp_22990

jmp_22490:
  mov64 r4, 0x1
  mov64 r1, 0x1
  lsh64 r1, r6
  and64 r1, 0x18
  jeq r1, 0x0, jmp_22bc0
  mov64 r3, 0x0
  mov64 r1, 0x0
  mov64 r2, 0x2
  jeq r7, 0x0, jmp_22990

jmp_224d8:
  stxdw [r10-0xc88], r4
  mov64 r4, r7
  add64 r4, -0x1
  stxdw [r10-0xc80], r4
  lsh64 r4, 0x3
  mov64 r5, r10
  add64 r5, -0xc70
  add64 r5, r4
  ldxdw r4, [r5+0x0]
  ldxdw r5, [r4+0x8]
  ldxdw r6, [r10-0xca8]
  ldxdw r0, [r6+0x0]
  jne r5, r0, jmp_22990
  ldxdw r5, [r6+0x8]
  ldxdw r0, [r4+0x10]
  jne r0, r5, jmp_22990
  ldxdw r5, [r6+0x10]
  ldxdw r0, [r4+0x18]
  jne r0, r5, jmp_22990
  ldxdw r5, [r6+0x18]
  ldxdw r0, [r4+0x20]
  jne r0, r5, jmp_22990
  ldxb r4, [r4+0x3]
  jeq r4, 0x0, jmp_22990
  jeq r3, 0x0, jmp_22dc8
  mov64 r2, r10
  add64 r2, -0xc70
  mov64 r4, r10
  add64 r4, -0x408
  ldxdw r1, [r10-0xca8]
  ldxdw r6, [r10-0xc80]
  mov64 r3, r6
  call fn_9f58
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_22bf8
  mov64 r7, r10
  add64 r7, -0xc70
  mov64 r1, 0x0
  mov64 r2, 0x2
  jge r8, r6, jmp_22990
  lsh64 r8, 0x3
  add64 r7, r8
  ldxdw r2, [r7+0x0]
  mov64 r1, r10
  add64 r1, -0x338
  ldxdw r6, [r10-0xca8]
  mov64 r3, r6
  call fn_1918
  ldxw r2, [r10-0x334]
  ldxw r1, [r10-0x338]
  ldxb r8, [r10-0x280]
  jeq r8, 0x2, jmp_22990
  stxdw [r10-0xc90], r2
  stxdw [r10-0xc98], r1
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0x330
  mov64 r3, 0xa8
  call fn_2c060
  ldxw r1, [r10-0x286]
  stxw [r10-0x438], r1
  ldxh r1, [r10-0x282]
  stxh [r10-0x434], r1
  ldxw r1, [r10-0x27f]
  stxw [r10-0x38], r1
  ldxw r1, [r10-0x27c]
  stxw [r10-0x35], r1
  mov64 r2, r7
  ldxh r7, [r10-0x288]
  mov64 r1, r10
  add64 r1, -0x78
  stxdw [r10-0x328], r1
  lddw r1, str_0378
  stxdw [r10-0x338], r1
  stxh [r10-0x78], r7
  stdw [r10-0x320], 0x2
  stdw [r10-0x330], 0x6
  stxdw [r10-0xc78], r2
  ldxdw r1, [r2+0x0]
  mov64 r2, r10
  add64 r2, -0x338
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_22f20
  ldxdw r1, [r10-0xc90]
  stxw [r10-0x1dc], r1
  ldxdw r1, [r10-0xc98]
  stxw [r10-0x1e0], r1
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r10
  add64 r2, -0x120
  mov64 r3, 0xa8
  call fn_2c060
  stxdw [r10-0xca0], r7
  stxh [r10-0x130], r7
  stxb [r10-0x128], r8
  ldxw r1, [r10-0x438]
  stxw [r10-0x12e], r1
  ldxh r1, [r10-0x434]
  stxh [r10-0x12a], r1
  ldxw r1, [r10-0x38]
  stxw [r10-0x127], r1
  ldxw r1, [r10-0x35]
  stxw [r10-0x124], r1
  ldxdw r6, [r10-0x138]
  jeq r6, -0x1, jmp_231e0

jmp_22870:
  add64 r6, 0x1
  stxdw [r10-0x138], r6
  ldxdw r1, [r10-0xc78]
  ldxdw r1, [r1+0x0]
  ldxdw r2, [r10-0xc88]
  jeq r2, 0x0, jmp_231f8
  ldxb r2, [r1+0x0]
  jne r2, 0xff, jmp_23030
  stb [r1+0x0], 0x0
  ldxdw r2, [r1+0x50]
  jlt r2, 0xb9, jmp_247a8
  add64 r2, -0xb9
  jne r2, 0x8, jmp_247b8
  stxdw [r1+0x111], r6
  stb [r1+0x0], 0xff
  ja jmp_23240

jmp_228f0:
  jlt r8, 0x11, jmp_22978
  mov64 r6, 0x16

jmp_22900:
  mov64 r5, 0x0
  mov64 r2, 0x11
  ldxdw r4, [r1+0x11]
  stxdw [r10-0xcb0], r4
  rsh64 r4, 0x20
  stxdw [r10-0xcb8], r4
  ldxdw r1, [r1+0x9]
  mov64 r4, r1
  rsh64 r4, 0x20
  stxdw [r10-0xca0], r4
  mov64 r4, 0x0
  stxdw [r10-0xc88], r4
  stxdw [r10-0xc80], r1
  stxdw [r10-0xc90], r1
  jeq r2, r8, jmp_21f90

jmp_22978:
  mov64 r2, 0x1
  mov64 r1, 0x0
  ldxb r9, [r9+0x0]

jmp_22990:
  mov64 r3, r9
  jeq r3, 0x1f, jmp_229a8
  jne r3, 0x2, jmp_22a00

jmp_229a8:
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jeq r1, 0x1a, jmp_22db8
  jsgt r1, 0xc, jmp_22a38
  jsle r1, 0x5, jmp_22a70
  jsle r1, 0x8, jmp_22ae0
  jsgt r1, 0xa, jmp_22b80
  jne r1, 0x9, jmp_22ce8
  lddw r2, 0xa00000000
  ja jmp_22d88

jmp_22a00:
  mov64 r0, 0x0
  mov64 r3, r1
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jeq r3, 0x1a, jmp_22dc0

jmp_22a28:
  call fn_2bd00
  ja jmp_22dc0

jmp_22a38:
  jsle r1, 0x12, jmp_22ab0
  jsle r1, 0x15, jmp_22b08
  jsgt r1, 0x17, jmp_22ba0
  jne r1, 0x16, jmp_22d00
  lddw r2, 0x1700000000
  ja jmp_22d88

jmp_22a70:
  jsgt r1, 0x2, jmp_22b30
  jeq r1, 0x0, jmp_22c40
  lddw r2, 0x200000000
  jeq r1, 0x1, jmp_22d88
  lddw r2, 0x300000000
  ja jmp_22d88

jmp_22ab0:
  jsgt r1, 0xf, jmp_22b58
  jeq r1, 0xd, jmp_22c70
  jne r1, 0xe, jmp_22d48
  lddw r2, 0xf00000000
  ja jmp_22d88

jmp_22ae0:
  jeq r1, 0x6, jmp_22c10
  jne r1, 0x7, jmp_22cb8
  lddw r2, 0x800000000
  ja jmp_22d88

jmp_22b08:
  jeq r1, 0x13, jmp_22c28
  jne r1, 0x14, jmp_22cd0
  lddw r2, 0x1500000000
  ja jmp_22d88

jmp_22b30:
  jeq r1, 0x3, jmp_22c88
  jne r1, 0x4, jmp_22d60
  lddw r2, 0x500000000
  ja jmp_22d88

jmp_22b58:
  jeq r1, 0x10, jmp_22ca0
  jne r1, 0x11, jmp_22d78
  lddw r2, 0x1200000000
  ja jmp_22d88

jmp_22b80:
  jne r1, 0xb, jmp_22d18
  lddw r2, 0xc00000000
  ja jmp_22d88

jmp_22ba0:
  jne r1, 0x18, jmp_22d30
  lddw r2, 0x1900000000
  ja jmp_22d88

jmp_22bc0:
  mov64 r2, r10
  add64 r2, -0xc70
  mov64 r4, r10
  add64 r4, -0x408
  ldxdw r1, [r10-0xca8]
  mov64 r3, r7
  call fn_9f58

jmp_22bf8:
  mov64 r2, r1
  mov64 r1, r0
  ja jmp_22990

jmp_22c10:
  lddw r2, 0x700000000
  ja jmp_22d88

jmp_22c28:
  lddw r2, 0x1400000000
  ja jmp_22d88

jmp_22c40:
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x0, jmp_22d88
  lddw r2, 0x100000000
  ja jmp_22d88

jmp_22c70:
  lddw r2, 0xe00000000
  ja jmp_22d88

jmp_22c88:
  lddw r2, 0x400000000
  ja jmp_22d88

jmp_22ca0:
  lddw r2, 0x1100000000
  ja jmp_22d88

jmp_22cb8:
  lddw r2, 0x900000000
  ja jmp_22d88

jmp_22cd0:
  lddw r2, 0x1600000000
  ja jmp_22d88

jmp_22ce8:
  lddw r2, 0xb00000000
  ja jmp_22d88

jmp_22d00:
  lddw r2, 0x1800000000
  ja jmp_22d88

jmp_22d18:
  lddw r2, 0xd00000000
  ja jmp_22d88

jmp_22d30:
  lddw r2, 0x1a00000000
  ja jmp_22d88

jmp_22d48:
  lddw r2, 0x1000000000
  ja jmp_22d88

jmp_22d60:
  lddw r2, 0x600000000
  ja jmp_22d88

jmp_22d78:
  lddw r2, 0x1300000000

jmp_22d88:
  lddw r1, 0x50494b534c43524f
  mov64 r5, r2
  mov64 r2, 0x1
  mov64 r4, 0x0
  call sol_log_64_

jmp_22db8:
  mov64 r0, 0x0

jmp_22dc0:
  exit

jmp_22dc8:
  ldxdw r1, [r10-0xc80]
  jeq r1, 0x0, jmp_22f10
  add64 r7, -0x2
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x328], r1
  lddw r1, str_0378
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0xca0]
  stxh [r10-0x1e0], r1
  mov64 r1, r7
  lsh64 r1, 0x3
  mov64 r8, r10
  add64 r8, -0xc70
  add64 r8, r1
  stdw [r10-0x320], 0x2
  stdw [r10-0x330], 0x6
  ldxdw r1, [r8+0x0]
  mov64 r2, r10
  add64 r2, -0x338
  mov64 r3, 0x2
  ldxdw r6, [r10-0xca8]
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_22f20
  stxdw [r10-0xc78], r8
  ldxdw r2, [r8+0x0]
  mov64 r1, r10
  add64 r1, -0x338
  mov64 r3, r6
  call fn_1918
  ldxw r2, [r10-0x334]
  ldxw r6, [r10-0x338]
  ldxb r8, [r10-0x280]
  jne r8, 0x2, jmp_22f40
  mov64 r1, r6
  ja jmp_22990

jmp_22f10:
  mov64 r1, 0x0
  ja jmp_22990

jmp_22f20:
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r1, r0
  ja jmp_22990

jmp_22f40:
  stxdw [r10-0xc90], r2
  mov64 r1, r10
  add64 r1, -0x120
  mov64 r2, r10
  add64 r2, -0x330
  mov64 r3, 0xa0
  call fn_2c060
  ldxw r1, [r10-0x286]
  stxw [r10-0x438], r1
  ldxh r1, [r10-0x282]
  stxh [r10-0x434], r1
  ldxw r1, [r10-0x27f]
  stxw [r10-0x38], r1
  ldxw r1, [r10-0x27c]
  stxw [r10-0x35], r1
  ldxh r1, [r10-0x288]
  ldxdw r2, [r10-0xca0]
  and64 r2, 0xffff
  jne r1, r2, jmp_230c8
  stxdw [r10-0xc98], r6
  ldxdw r1, [r10-0xc78]
  ldxdw r1, [r1+0x0]
  ldxb r2, [r1+0x2]
  jeq r2, 0x0, jmp_230e0
  ldxdw r2, [r1+0x50]
  jne r2, 0xc1, jmp_230e0
  ldxdw r6, [r10-0x290]
  jeq r6, -0x1, jmp_23800
  ldxb r1, [r1+0x0]
  jeq r1, 0xff, jmp_23818

jmp_23030:
  mov64 r1, 0xb
  mov64 r2, 0x0
  ja jmp_22990

jmp_23048:
  mov64 r2, 0x0

jmp_23050:
  stxdw [r10-0xcc0], r2
  jlt r8, 0xf, jmp_22978
  ldxb r2, [r1+0x16]
  jeq r2, 0x0, jmp_230f8
  jne r2, 0x1, jmp_22978
  mov64 r0, 0x1
  ja jmp_23100

jmp_23088:
  lsh64 r2, 0x3
  mov64 r3, r10
  add64 r3, -0xc70
  add64 r3, r2
  ldxdw r2, [r3+0x0]
  stxdw [r10-0xc68], r2

jmp_230b8:
  add64 r1, 0x8
  ja jmp_204e0

jmp_230c8:
  mov64 r2, 0x8
  mov64 r1, 0x0
  ja jmp_22990

jmp_230e0:
  mov64 r2, 0x2
  mov64 r1, 0x0
  ja jmp_22990

jmp_230f8:
  mov64 r0, 0x0

jmp_23100:
  jlt r8, 0x17, jmp_22978
  jlt r8, 0x1f, jmp_22978
  jlt r8, 0x27, jmp_22978
  jlt r8, 0x29, jmp_22978
  jlt r8, 0x2b, jmp_22978
  jeq r8, 0x2b, jmp_22978
  jlt r8, 0x30, jmp_22978
  mov64 r7, r9
  ldxdw r2, [r1+0x17]
  stxdw [r10-0xcd0], r2
  ldxdw r2, [r1+0x1f]
  stxdw [r10-0xce8], r2
  ldxdw r2, [r1+0x27]
  stxdw [r10-0xce0], r2
  ldxh r2, [r1+0x2f]
  stxdw [r10-0xc90], r2
  ldxh r2, [r1+0x31]
  stxdw [r10-0xc80], r2
  ldxb r2, [r1+0x33]
  stxdw [r10-0xcd8], r2
  mov64 r2, r1
  ldxw r1, [r1+0x34]
  stxdw [r10-0xca0], r1
  jne r8, 0x30, jmp_246c8
  mov64 r1, 0x32
  stxdw [r10-0xcb0], r1
  mov64 r2, 0x30
  ja jmp_246f8

jmp_231e0:
  mov64 r1, 0x0
  mov64 r2, 0x4
  ja jmp_22990

jmp_231f8:
  mov64 r2, r10
  add64 r2, -0x1e0
  call fn_3370
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r0
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  jne r3, 0x1a, jmp_22990

jmp_23240:
  mov64 r1, r10
  add64 r1, -0xc68
  stxdw [r10-0xc88], r1
  mov64 r7, 0x1
  jgt r9, 0x2e, jmp_232b8
  mov64 r1, 0x1
  lsh64 r1, r9
  lddw r2, 0x4402080001c0
  and64 r1, r2
  jeq r1, 0x0, jmp_232b8
  mov64 r1, r10
  add64 r1, -0xc60
  stxdw [r10-0xc88], r1
  mov64 r7, 0x2

jmp_232b8:
  ldxdw r3, [r10-0xc60]
  ldxdw r4, [r10-0xc38]
  stxdw [r10-0xff8], r9
  ldxdw r1, [r10-0xc80]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x338
  mov64 r5, r10
  ldxdw r2, [r10-0xca8]
  call fn_9170
  ldxb r8, [r10-0x338]
  jne r8, 0x8, jmp_235d8
  ldxw r2, [r10-0x330]
  ldxw r1, [r10-0x334]
  ja jmp_22990

jmp_23330:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x8], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_20260

jmp_23378:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x10], r3
  ja jmp_230b8

jmp_233b0:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x8], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_20038

jmp_233f8:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x10], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_200b8

jmp_23440:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x18], r3
  ja jmp_230b8

jmp_23478:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x8], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_20370

jmp_234c0:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x10], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_203f0

jmp_23508:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x18], r3
  add64 r1, 0x8
  ldxb r3, [r1+0x0]
  jeq r3, 0xff, jmp_20470

jmp_23550:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x20], r3
  ja jmp_230b8

jmp_23588:
  lsh64 r3, 0x3
  mov64 r4, r10
  add64 r4, -0xc70
  add64 r4, r3
  ldxdw r3, [r4+0x0]
  stxdw [r2+0x8], r3
  ja jmp_230b8

jmp_235c0:
  lddw r1, data_0738
  call fn_2bcf8

jmp_235d8:
  ldxb r1, [r10-0x335]
  stxb [r10-0x456], r1
  ldxh r1, [r10-0x337]
  stxh [r10-0x458], r1
  ldxw r1, [r10-0x334]
  stxdw [r10-0xc90], r1
  ldxw r1, [r10-0x330]
  stxdw [r10-0xc98], r1
  mov64 r1, r10
  add64 r1, -0x78
  mov64 r2, r10
  add64 r2, -0x32c
  mov64 r3, 0x3c
  call fn_2c060
  ldxdw r1, [r10-0xc80]
  jge r7, r1, jmp_248f8
  ldxdw r1, [r10-0x158]
  stxdw [r10-0x290], r1
  ldxdw r1, [r10-0x160]
  stxdw [r10-0x298], r1
  ldxdw r1, [r10-0x168]
  stxdw [r10-0x2a0], r1
  ldxdw r1, [r10-0x170]
  stxdw [r10-0x2a8], r1
  ldxdw r1, [r10-0x178]
  stxdw [r10-0x2b0], r1
  ldxdw r1, [r10-0x180]
  stxdw [r10-0x2b8], r1
  ldxdw r1, [r10-0x188]
  stxdw [r10-0x2c0], r1
  ldxdw r1, [r10-0x190]
  stxdw [r10-0x2c8], r1
  ldxdw r1, [r10-0x1b8]
  stxdw [r10-0x2d0], r1
  ldxdw r1, [r10-0x1c0]
  stxdw [r10-0x2d8], r1
  ldxdw r1, [r10-0x1c8]
  stxdw [r10-0x2e0], r1
  ldxdw r1, [r10-0x1d0]
  stxdw [r10-0x2e8], r1
  stxb [r10-0x285], r9
  ldxdw r1, [r10-0xca0]
  stxh [r10-0x288], r1
  stxdw [r10-0x2f0], r6
  stxb [r10-0x338], r8
  stb [r10-0x286], 0x1
  ldxdw r1, [r10-0xc98]
  stxw [r10-0x330], r1
  ldxdw r1, [r10-0xc90]
  stxw [r10-0x334], r1
  ldxh r1, [r10-0x458]
  stxh [r10-0x337], r1
  ldxb r1, [r10-0x456]
  stxb [r10-0x335], r1
  mov64 r1, r10
  add64 r1, -0x32c
  mov64 r2, r10
  add64 r2, -0x78
  mov64 r3, 0x3c
  call fn_2c060
  ldxdw r1, [r10-0xc88]
  ldxdw r2, [r1+0x0]
  ldxdw r1, [r10-0xc78]
  ldxdw r3, [r1+0x0]
  mov64 r4, r10
  add64 r4, -0x338
  ldxdw r1, [r10-0xca8]
  call fn_96e8
  ja jmp_22bf8

jmp_23800:
  mov64 r2, 0x4
  mov64 r1, 0x0
  ja jmp_22990

jmp_23818:
  mov64 r2, r10
  add64 r2, -0xc70
  mov64 r4, r10
  add64 r4, -0x408
  ldxdw r1, [r10-0xca8]
  mov64 r3, r7
  call fn_9f58
  mov64 r3, r0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x1a, jmp_239a0
  mov64 r1, r10
  add64 r1, -0x1d8
  mov64 r2, r10
  add64 r2, -0x120
  mov64 r3, 0xa0
  call fn_2c060
  stxb [r10-0x128], r8
  ldxdw r1, [r10-0xca0]
  stxh [r10-0x130], r1
  ldxdw r1, [r10-0xc90]
  stxw [r10-0x1dc], r1
  ldxdw r1, [r10-0xc98]
  stxw [r10-0x1e0], r1
  ldxw r1, [r10-0x438]
  stxw [r10-0x12e], r1
  ldxh r1, [r10-0x434]
  stxh [r10-0x12a], r1
  ldxw r1, [r10-0x38]
  stxw [r10-0x127], r1
  ldxw r1, [r10-0x35]
  stxw [r10-0x124], r1
  ja jmp_22870

jmp_23928:
  ldxdw r1, [r10-0xc78]
  jsgt r1, 0x24, jmp_239b8
  ldxdw r1, [r10-0xc78]
  jsgt r1, 0x1e, jmp_23be0
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x1b, jmp_23c28
  ldxdw r1, [r10-0xc78]
  jne r1, 0x1e, jmp_23da8
  jlt r8, 0x7c, jmp_23da8
  mov64 r1, 0x7
  stxdw [r10-0xd70], r1
  mov64 r9, 0x7c
  ldxdw r1, [r7+0x7c]
  stxdw [r10-0xd78], r1
  ja jmp_23d80

jmp_239a0:
  mov64 r2, r1
  mov64 r1, r3
  ja jmp_22990

jmp_239b8:
  ldxdw r1, [r10-0xc78]
  jsgt r1, 0x29, jmp_23c08
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x25, jmp_23da0
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x29, jmp_23d40
  ja jmp_23da8

jmp_239f0:
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x1, jmp_23d40
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x2, jmp_23ce8
  ldxdw r1, [r10-0xc78]
  jne r1, 0x6, jmp_23da8
  jlt r8, 0x94, jmp_23da8
  jlt r8, 0x9c, jmp_23da8
  jlt r8, 0xa4, jmp_23da8
  jlt r8, 0xac, jmp_23da8
  jlt r8, 0xae, jmp_23da8
  jeq r8, 0xae, jmp_23da8
  mov64 r1, r7
  ldxb r9, [r1+0x8d]
  ldxh r2, [r1+0x8b]
  ldxh r3, [r1+0x9a]
  stxdw [r10-0xd78], r3
  ldxw r4, [r1+0x96]
  stxdw [r10-0xd90], r4
  ldxdw r3, [r1+0x83]
  stxdw [r10-0xd70], r3
  ldxdw r4, [r1+0x8e]
  stxdw [r10-0xd88], r4
  ldxw r3, [r1+0x7f]
  stxdw [r10-0xd80], r3
  ldxb r3, [r1+0x7e]
  stxdw [r10-0xdb0], r3
  ldxh r4, [r1+0x7c]
  stxdw [r10-0xdd0], r4
  ldxdw r3, [r1+0x9c]
  stxdw [r10-0xda0], r3
  ldxdw r3, [r1+0xa4]
  stxdw [r10-0xda8], r3
  ldxdw r3, [r1+0xac]
  stxdw [r10-0xd98], r3
  ldxh r3, [r1+0xb4]
  stxdw [r10-0xdc8], r3
  ldxb r1, [r1+0xb6]
  jeq r1, 0x0, jmp_247c8
  jne r1, 0x1, jmp_23da8
  mov64 r1, 0x1
  ja jmp_247d0

jmp_23b40:
  ldxdw r1, [r10-0xc78]
  jeq r1, 0xe, jmp_23da0
  ldxdw r1, [r10-0xc78]
  jne r1, 0x18, jmp_23da8
  jlt r8, 0x80, jmp_23da8
  mov64 r1, 0x6
  stxdw [r10-0xd70], r1
  mov64 r9, 0x80
  ldxdw r1, [r7+0x80]
  stxdw [r10-0xd78], r1
  ldxh r1, [r7+0x7e]
  stxdw [r10-0xdc8], r1
  ldxh r1, [r7+0x7c]
  stxdw [r10-0xdb8], r1
  rsh64 r1, 0x8
  stxdw [r10-0xdc0], r1
  mov64 r2, 0x1
  mov64 r1, 0x0
  jne r9, r8, jmp_22a28
  ja jmp_23f18

jmp_23be0:
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x1f, jmp_23ce8
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x21, jmp_23c28
  ja jmp_23da8

jmp_23c08:
  ldxdw r1, [r10-0xc78]
  jeq r1, 0x2a, jmp_23c28
  ldxdw r1, [r10-0xc78]
  jne r1, 0x2e, jmp_23da8

jmp_23c28:
  jlt r8, 0xb4, jmp_23da8
  mov64 r1, 0x3
  stxdw [r10-0xd70], r1
  mov64 r9, 0xb4
  ldxdw r1, [r7+0x7c]
  stxdw [r10-0xda0], r1
  ldxdw r1, [r7+0xb4]
  stxdw [r10-0xd90], r1
  ldxdw r1, [r7+0xac]
  stxdw [r10-0xd88], r1
  ldxdw r1, [r7+0xa4]
  stxdw [r10-0xd80], r1
  ldxdw r1, [r7+0x9c]
  stxdw [r10-0xd78], r1
  ldxdw r1, [r7+0x84]
  stxdw [r10-0xda8], r1
  ldxdw r1, [r7+0x8c]
  stxdw [r10-0xd98], r1
  ldxdw r1, [r7+0x94]
  stxdw [r10-0xdb0], r1
  mov64 r2, 0x1
  mov64 r1, 0x0
  jne r9, r8, jmp_22a28
  ja jmp_23f18

jmp_23ce8:
  jlt r8, 0x8c, jmp_23da8
  mov64 r1, 0x1
  stxdw [r10-0xd70], r1
  mov64 r9, 0x8c
  ldxdw r1, [r7+0x8c]
  stxdw [r10-0xd88], r1
  ldxdw r1, [r7+0x84]
  stxdw [r10-0xd80], r1
  ldxdw r1, [r7+0x7c]
  stxdw [r10-0xd78], r1
  ja jmp_23d80

jmp_23d40:
  jlt r8, 0x76, jmp_23da8
  mov64 r1, 0x0
  stxdw [r10-0xd70], r1
  mov64 r9, 0x76
  ldxh r1, [r7+0x7c]
  stxdw [r10-0xdb8], r1
  rsh64 r1, 0x8
  stxdw [r10-0xdc0], r1

jmp_23d80:
  mov64 r2, 0x1
  mov64 r1, 0x0
  jne r9, r8, jmp_22a28
  ja jmp_23f18

jmp_23da0:
  jge r8, 0x94, jmp_23dd8

jmp_23da8:
  mov64 r2, 0x1
  mov64 r1, 0x0
  ja jmp_22a28

jmp_23dc0:
  lddw r1, data_06a8
  call fn_2bcf8

jmp_23dd8:
  ldxb r1, [r7+0x7e]
  lsh64 r1, 0x10
  ldxh r2, [r7+0x7c]
  or64 r2, r1
  ldxb r4, [r7+0x9b]
  lsh64 r4, 0x38
  ldxdw r1, [r7+0x93]
  mov64 r9, r1
  rsh64 r9, 0x8
  or64 r9, r4
  stxdw [r10-0xd90], r9
  ldxb r4, [r7+0x8b]
  lsh64 r4, 0x38
  ldxdw r9, [r7+0x83]
  mov64 r3, r9
  rsh64 r3, 0x8
  or64 r3, r4
  stxdw [r10-0xd80], r3
  lsh64 r9, 0x38
  or64 r9, r2
  ldxb r2, [r7+0x8e]
  lsh64 r2, 0x10
  ldxh r4, [r7+0x8c]
  or64 r4, r2
  ldxw r2, [r7+0x8f]
  lsh64 r2, 0x18
  or64 r2, r4
  lsh64 r1, 0x38
  or64 r2, r1
  stxdw [r10-0xd88], r2
  ldxw r1, [r7+0x7f]
  lsh64 r1, 0x18
  or64 r9, r1
  stxdw [r10-0xd78], r9
  mov64 r1, 0x5
  stxdw [r10-0xd70], r1
  mov64 r9, 0x94
  mov64 r2, 0x1
  mov64 r1, 0x0
  jne r9, r8, jmp_22a28

jmp_23f18:
  ldxdw r2, [r10-0xca0]
  lsh64 r2, 0x38
  mov64 r1, r0
  rsh64 r1, 0x8
  or64 r2, r1
  stxdw [r10-0xca0], r2
  ldxdw r2, [r10-0xd68]
  lsh64 r2, 0x10
  ldxdw r1, [r10-0xd60]
  or64 r1, r2
  ldxdw r2, [r10-0xc80]
  lsh64 r2, 0x18
  or64 r2, r1
  lsh64 r0, 0x38
  or64 r2, r0
  stxdw [r10-0xc80], r2
  ldxdw r2, [r10-0xc98]
  lsh64 r2, 0x38
  mov64 r1, r5
  rsh64 r1, 0x8
  or64 r2, r1
  stxdw [r10-0xc98], r2
  ldxdw r2, [r10-0xd58]
  lsh64 r2, 0x10
  ldxdw r1, [r10-0xd50]
  or64 r1, r2
  ldxdw r9, [r10-0xca8]
  lsh64 r9, 0x18
  or64 r9, r1
  lsh64 r5, 0x38
  or64 r9, r5
  ldxdw r3, [r10-0xc90]
  lsh64 r3, 0x38
  ldxdw r2, [r10-0xd38]
  mov64 r1, r2
  rsh64 r1, 0x8
  or64 r3, r1
  stxdw [r10-0xc90], r3
  ldxdw r3, [r10-0xd48]
  lsh64 r3, 0x10
  ldxdw r1, [r10-0xd40]
  or64 r1, r3
  ldxdw r5, [r10-0xcb0]
  lsh64 r5, 0x18
  or64 r5, r1
  lsh64 r2, 0x38
  or64 r5, r2
  ldxdw r3, [r10-0xc88]
  lsh64 r3, 0x38
  ldxdw r2, [r10-0xd20]
  mov64 r1, r2
  rsh64 r1, 0x8
  or64 r3, r1
  stxdw [r10-0xc88], r3
  ldxdw r3, [r10-0xd30]
  lsh64 r3, 0x10
  ldxdw r1, [r10-0xd28]
  or64 r1, r3
  ldxdw r7, [r10-0xcb8]
  lsh64 r7, 0x18
  or64 r7, r1
  lsh64 r2, 0x38
  or64 r7, r2
  ldxdw r8, [r10-0xcc0]
  lsh64 r8, 0x38
  ldxdw r2, [r10-0xd08]
  mov64 r1, r2
  rsh64 r1, 0x8
  or64 r8, r1
  ldxdw r3, [r10-0xd18]
  lsh64 r3, 0x10
  ldxdw r1, [r10-0xd10]
  or64 r1, r3
  ldxdw r0, [r10-0xcc8]
  lsh64 r0, 0x18
  or64 r0, r1
  lsh64 r2, 0x38
  or64 r0, r2
  ldxdw r4, [r10-0xcd0]
  lsh64 r4, 0x38
  ldxdw r3, [r10-0xcf0]
  mov64 r1, r3
  rsh64 r1, 0x8
  or64 r4, r1
  ldxdw r1, [r10-0xd00]
  lsh64 r1, 0x10
  ldxdw r2, [r10-0xcf8]
  or64 r2, r1
  ldxdw r1, [r10-0xcd8]
  lsh64 r1, 0x18
  or64 r1, r2
  lsh64 r3, 0x38
  or64 r1, r3
  stxdw [r10-0xcd8], r1
  stxdw [r10-0x298], r1
  stxdw [r10-0xcc8], r0
  stxdw [r10-0x2a8], r0
  stxdw [r10-0xcb8], r7
  stxdw [r10-0x2b8], r7
  stxdw [r10-0xcb0], r5
  stxdw [r10-0x2c8], r5
  stxdw [r10-0xca8], r9
  stxdw [r10-0x2d8], r9
  ldxdw r1, [r10-0xc80]
  stxdw [r10-0x2e8], r1
  ldxdw r1, [r10-0xd90]
  stxdw [r10-0x318], r1
  ldxdw r1, [r10-0xd88]
  stxdw [r10-0x320], r1
  ldxdw r1, [r10-0xd80]
  stxdw [r10-0x328], r1
  ldxdw r1, [r10-0xd78]
  stxdw [r10-0x330], r1
  ldxdw r1, [r10-0xc78]
  stxb [r10-0x285], r1
  ldxdw r1, [r10-0xce0]
  stxh [r10-0x288], r1
  ldxdw r1, [r10-0xce8]
  stxdw [r10-0x2f0], r1
  ldxdw r1, [r10-0xdb0]
  stxdw [r10-0x2f8], r1
  ldxdw r1, [r10-0xd98]
  stxdw [r10-0x300], r1
  ldxdw r1, [r10-0xda8]
  stxdw [r10-0x308], r1
  ldxdw r1, [r10-0xda0]
  stxdw [r10-0x310], r1
  ldxdw r1, [r10-0xdd0]
  stxh [r10-0x332], r1
  ldxdw r1, [r10-0xdc8]
  stxh [r10-0x334], r1
  ldxdw r1, [r10-0xdd8]
  stxb [r10-0x337], r1
  ldxdw r1, [r10-0xd70]
  stxb [r10-0x338], r1
  stxdw [r10-0xcd0], r4
  stxdw [r10-0x290], r4
  stxdw [r10-0xcc0], r8
  stxdw [r10-0x2a0], r8
  ldxdw r1, [r10-0xc88]
  stxdw [r10-0x2b0], r1
  ldxdw r1, [r10-0xc90]
  mov64 r8, r1
  stxdw [r10-0x2c0], r1
  ldxdw r1, [r10-0xc98]
  mov64 r9, r1
  stxdw [r10-0x2d0], r1
  ldxdw r1, [r10-0xca0]
  mov64 r7, r1
  stxdw [r10-0x2e0], r1
  ldxdw r1, [r10-0xdb8]
  and64 r1, 0xff
  ldxdw r2, [r10-0xdc0]
  lsh64 r2, 0x8
  or64 r2, r1
  stxh [r10-0x336], r2
  stb [r10-0x286], 0x1
  mov64 r1, r10
  add64 r1, -0x338
  call fn_24958
  mov64 r1, 0x0
  mov64 r2, r0
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jne r2, 0x0, jmp_22a28
  mov64 r1, r10
  add64 r1, -0x1e0
  stxdw [r10-0x328], r1
  lddw r1, str_0378
  stxdw [r10-0x338], r1
  ldxdw r1, [r10-0xce0]
  stxh [r10-0x1e0], r1
  stdw [r10-0x320], 0x2
  stdw [r10-0x330], 0x6
  ldxdw r1, [r10-0xc68]
  mov64 r2, r10
  add64 r2, -0x338
  mov64 r3, 0x2
  mov64 r4, r6
  call fn_05d0
  mov64 r1, r0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jne r1, 0x1a, jmp_24740
  ldxdw r2, [r10-0xc68]
  mov64 r1, r10
  add64 r1, -0x338
  mov64 r3, r6
  call fn_1918
  ldxb r1, [r10-0x280]
  jeq r1, 0x2, jmp_20590
  ldxh r1, [r10-0x288]
  ldxdw r2, [r10-0xce0]
  jne r1, r2, jmp_24790
  ldxdw r1, [r10-0x290]
  ldxdw r2, [r10-0xce8]
  jne r1, r2, jmp_24790
  ldxdw r1, [r10-0x320]
  ldxdw r2, [r10-0x328]
  ldxdw r3, [r10-0xc80]
  xor64 r3, r2
  xor64 r7, r1
  or64 r3, r7
  jne r3, 0x0, jmp_24790
  ldxdw r1, [r10-0x310]
  ldxdw r2, [r10-0x318]
  ldxdw r7, [r10-0xca8]
  xor64 r7, r2
  xor64 r9, r1
  or64 r7, r9
  jne r7, 0x0, jmp_24790
  ldxdw r1, [r10-0x2e0]
  ldxdw r2, [r10-0x2e8]
  ldxdw r3, [r10-0xcb0]
  xor64 r3, r2
  xor64 r8, r1
  or64 r3, r8
  jne r3, 0x0, jmp_24790
  ldxdw r1, [r10-0x2d0]
  ldxdw r2, [r10-0x2d8]
  ldxdw r3, [r10-0xcb8]
  xor64 r3, r2
  ldxdw r7, [r10-0xc88]
  xor64 r7, r1
  or64 r3, r7
  jne r3, 0x0, jmp_24790
  ldxdw r1, [r10-0x2c0]
  ldxdw r2, [r10-0x2c8]
  ldxdw r8, [r10-0xcc8]
  xor64 r8, r2
  ldxdw r9, [r10-0xcc0]
  xor64 r9, r1
  or64 r8, r9
  jne r8, 0x0, jmp_24790
  ldxdw r1, [r10-0x2b0]
  ldxdw r2, [r10-0x2b8]
  ldxdw r8, [r10-0xcd8]
  xor64 r8, r2
  ldxdw r7, [r10-0xcd0]
  xor64 r7, r1
  or64 r8, r7
  mov64 r1, 0x0
  mov64 r2, 0x2
  jeq r8, 0x0, jmp_22db8
  ja jmp_22a28

jmp_246c8:
  mov64 r1, r2
  mov64 r9, r7
  jlt r8, 0x34, jmp_22978
  mov64 r2, 0x34
  ldxw r1, [r1+0x38]
  stxdw [r10-0xcb0], r1

jmp_246f8:
  mov64 r5, r4
  lsh64 r5, 0x10
  ldxdw r1, [r10-0xc80]
  lsh64 r1, 0x10
  stxdw [r10-0xc80], r1
  mov64 r6, 0x11
  mov64 r9, r7
  jne r2, r8, jmp_22978
  ja jmp_21f90

jmp_24740:
  mov64 r2, r0
  rsh64 r2, 0x20
  mov64 r1, r0
  ja jmp_22a28

jmp_24760:
  lddw r1, data_06c0
  call fn_2bcf8

jmp_24778:
  lddw r1, data_06d8
  call fn_2bcf8

jmp_24790:
  mov64 r1, 0x0
  mov64 r2, 0x2
  ja jmp_22a28

jmp_247a8:
  mov64 r1, r2
  call fn_2bc90

jmp_247b8:
  mov64 r1, r2
  call fn_2bcd8

jmp_247c8:
  mov64 r1, 0x0

jmp_247d0:
  stxdw [r10-0xdd8], r1
  jlt r8, 0xb0, jmp_23da8
  ldxb r1, [r7+0xb7]
  jeq r1, 0x0, jmp_24808
  jne r1, 0x1, jmp_23da8
  mov64 r1, 0x1
  ja jmp_24810

jmp_24808:
  mov64 r1, 0x0

jmp_24810:
  stxdw [r10-0xdb8], r1
  lsh64 r9, 0x10
  or64 r2, r9
  ldxdw r3, [r10-0xd78]
  lsh64 r3, 0x20
  ldxdw r1, [r10-0xd90]
  or64 r1, r3
  stxdw [r10-0xd90], r1
  ldxdw r1, [r10-0xdb0]
  ldxdw r3, [r10-0xd80]
  mov64 r4, r3
  lsh64 r4, 0x8
  or64 r4, r1
  lsh64 r2, 0x28
  ldxdw r3, [r10-0xd70]
  mov64 r1, r3
  rsh64 r1, 0x18
  or64 r1, r2
  stxdw [r10-0xd80], r1
  lsh64 r3, 0x28
  or64 r4, r3
  stxdw [r10-0xd78], r4
  mov64 r1, 0x2
  stxdw [r10-0xd70], r1
  mov64 r9, 0xb0
  mov64 r2, 0x1
  mov64 r1, 0x0
  jne r9, r8, jmp_22a28
  ja jmp_23f18

jmp_248f8:
  mov64 r1, r7
  ldxdw r2, [r10-0xc80]
  lddw r3, data_07a0
  call fn_2bc78

fn_24920:
  ldxw r4, [r1+0x14]
  ldxw r3, [r1+0x10]
  ldxdw r5, [r1+0x0]
  ldxdw r2, [r1+0x8]
  add64 r2, -0x1
  mov64 r1, r5
  call sol_panic_

fn_24958:
  mov64 r0, 0x13
  ldxb r2, [r1+0xb2]
  jne r2, 0x1, jmp_24ac8
  mov64 r0, 0x1
  ldxdw r2, [r1+0x48]
  jeq r2, 0x0, jmp_24ac8
  ldxb r2, [r1+0xb3]
  ldxb r1, [r1+0x0]
  jsgt r1, 0x3, jmp_249e8
  jsgt r1, 0x1, jmp_24a08
  jne r1, 0x0, jmp_24a38
  mov64 r1, 0x1
  jne r2, 0x29, jmp_249c8
  mov64 r1, 0x0

jmp_249c8:
  jne r2, 0x1, jmp_249d8

jmp_249d0:
  mov64 r0, 0x0

jmp_249d8:
  and64 r0, r1
  ja jmp_24ac8

jmp_249e8:
  jsgt r1, 0x5, jmp_24a20
  jne r1, 0x4, jmp_24a60
  jeq r2, 0xd, jmp_24ac0
  ja jmp_24ac8

jmp_24a08:
  jne r1, 0x2, jmp_24a88
  jeq r2, 0x6, jmp_24ac0
  ja jmp_24ac8

jmp_24a20:
  jne r1, 0x6, jmp_24ad0
  jeq r2, 0x18, jmp_24ac0
  ja jmp_24ac8

jmp_24a38:
  mov64 r1, 0x1
  jne r2, 0x1f, jmp_24a50
  mov64 r1, 0x0

jmp_24a50:
  jeq r2, 0x2, jmp_249d0
  ja jmp_249d8

jmp_24a60:
  mov64 r1, 0x1
  jne r2, 0x25, jmp_24a78
  mov64 r1, 0x0

jmp_24a78:
  jeq r2, 0xe, jmp_249d0
  ja jmp_249d8

jmp_24a88:
  jgt r2, 0x2e, jmp_24ac8
  mov64 r1, 0x1
  lsh64 r1, r2
  lddw r2, 0x440208000180
  and64 r1, r2
  jeq r1, 0x0, jmp_24ac8

jmp_24ac0:
  mov64 r0, 0x0

jmp_24ac8:
  exit

jmp_24ad0:
  jeq r2, 0x1e, jmp_24ac0
  ja jmp_24ac8

fn_24ae0:
  jne r2, 0x0, jmp_24b40
  lddw r2, 0x100000000
  jge r1, r2, jmp_24cb0
  jge r1, 0x10000, jmp_25720
  jge r1, 0x100, jmp_25c80
  lsh64 r1, 0x1
  lddw r2, data_041b
  add64 r2, r1
  ldxb r0, [r2+0x0]
  ja jmp_26038

jmp_24b40:
  lddw r0, 0x5555555555555555
  lddw r5, 0x3333333333333333
  lddw r4, 0xf0f0f0f0f0f0f0f
  lddw r3, 0x101010101010101
  jne r2, 0x0, jmp_24f50
  mov64 r6, r1
  rsh64 r6, 0x1
  mov64 r7, r1
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x2
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x4
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x8
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x10
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x20
  or64 r7, r6
  xor64 r7, -0x1
  mov64 r6, r7
  rsh64 r6, 0x1
  and64 r6, r0
  sub64 r7, r6
  mov64 r6, r7
  and64 r6, r5
  rsh64 r7, 0x2
  and64 r7, r5
  add64 r6, r7
  mov64 r5, r6
  rsh64 r5, 0x4
  add64 r6, r5
  and64 r6, r4
  mul64 r6, r3
  rsh64 r6, 0x38
  add64 r6, 0x40
  ja jmp_25068

jmp_24cb0:
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
  lddw r3, 0x3333333333333333
  mov64 r6, r2
  and64 r6, r3
  rsh64 r2, 0x2
  and64 r2, r3
  add64 r6, r2
  mov64 r2, r6
  rsh64 r2, 0x4
  add64 r6, r2
  lddw r2, 0xf0f0f0f0f0f0f0f
  and64 r6, r2
  lddw r2, 0x101010101010101
  mul64 r6, r2
  mov64 r2, r6
  rsh64 r2, 0x38
  and64 r2, 0x3e
  lsh64 r1, r2
  mov64 r2, r1
  rsh64 r2, 0x37
  and64 r2, 0x1fe
  lddw r3, data_041b
  add64 r3, r2
  mov64 r2, r1
  rsh64 r2, 0x34
  and64 r2, 0xf
  ldxb r4, [r3+0x1]
  lsh64 r4, 0x4
  or64 r4, r2
  ldxb r2, [r3+0x0]
  mov64 r5, r4
  and64 r5, 0xffff
  mov64 r3, r2
  lsh64 r3, 0x1
  div64 r5, r3
  mov64 r0, r5
  mul64 r0, r3
  sub64 r4, r0
  mov64 r3, r1
  rsh64 r3, 0x30
  and64 r3, 0xf
  lsh64 r4, 0x4
  or64 r4, r3
  lsh64 r2, 0x4
  and64 r2, 0xf0
  mov64 r3, r5
  add64 r3, r2
  mul64 r5, r5
  mov64 r2, r4
  sub64 r2, r5
  and64 r4, 0xffff
  and64 r5, 0xffff
  jlt r4, r5, jmp_259e0
  mov64 r0, 0x0
  ja jmp_259f8

jmp_24f50:
  mov64 r6, r2
  rsh64 r6, 0x1
  mov64 r7, r2
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x2
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x4
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x8
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x10
  or64 r7, r6
  mov64 r6, r7
  rsh64 r6, 0x20
  or64 r7, r6
  xor64 r7, -0x1
  mov64 r6, r7
  rsh64 r6, 0x1
  and64 r6, r0
  sub64 r7, r6
  mov64 r6, r7
  and64 r6, r5
  rsh64 r7, 0x2
  and64 r7, r5
  add64 r6, r7
  mov64 r5, r6
  rsh64 r5, 0x4
  add64 r6, r5
  and64 r6, r4
  mul64 r6, r3
  rsh64 r6, 0x38

jmp_25068:
  mov64 r3, r6
  and64 r3, 0x7e
  call fn_2c0a8
  mov64 r2, r1
  rsh64 r2, 0x37
  and64 r2, 0x1fe
  lddw r3, data_041b
  add64 r3, r2
  mov64 r4, r1
  rsh64 r4, 0x34
  and64 r4, 0xf
  ldxb r2, [r3+0x1]
  lsh64 r2, 0x4
  or64 r2, r4
  ldxb r7, [r3+0x0]
  mov64 r4, r2
  and64 r4, 0xffff
  mov64 r3, r7
  lsh64 r3, 0x1
  div64 r4, r3
  mov64 r5, r4
  mul64 r5, r3
  sub64 r2, r5
  mov64 r3, r1
  rsh64 r3, 0x30
  and64 r3, 0xf
  lsh64 r2, 0x4
  or64 r2, r3
  lsh64 r7, 0x4
  and64 r7, 0xf0
  mov64 r3, r4
  add64 r3, r7
  mul64 r4, r4
  mov64 r7, r2
  sub64 r7, r4
  and64 r2, 0xffff
  and64 r4, 0xffff
  jlt r2, r4, jmp_251b0
  mov64 r5, 0x0
  ja jmp_251c8

jmp_251b0:
  mov64 r5, r3
  lsh64 r5, 0x1
  add64 r5, -0x1

jmp_251c8:
  add64 r7, r5
  mov64 r5, r1
  rsh64 r5, 0x28
  and64 r5, 0xff
  and64 r7, 0xffff
  lsh64 r7, 0x8
  or64 r7, r5
  mov64 r5, 0x1
  jlt r2, r4, jmp_25218
  mov64 r5, 0x0

jmp_25218:
  sub64 r3, r5
  mov64 r2, r3
  and64 r2, 0xffff
  lsh64 r2, 0x1
  mov64 r4, r7
  div64 r4, r2
  mov64 r5, r4
  mul64 r5, r2
  sub64 r7, r5
  mov64 r2, r1
  rsh64 r2, 0x20
  and64 r2, 0xff
  lsh64 r7, 0x8
  or64 r7, r2
  lsh64 r3, 0x8
  and64 r3, 0xff00
  mov64 r2, r4
  add64 r2, r3
  mul64 r4, r4
  mov64 r3, r7
  sub64 r3, r4
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jlt r7, r4, jmp_252f8
  mov64 r5, 0x0
  ja jmp_25310

jmp_252f8:
  mov64 r5, r2
  lsh64 r5, 0x1
  add64 r5, -0x1

jmp_25310:
  add64 r3, r5
  mov64 r5, r1
  rsh64 r5, 0x10
  and64 r5, 0xffff
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  lsh64 r3, 0x10
  or64 r3, r5
  mov64 r5, 0x1
  jlt r7, r4, jmp_25368
  mov64 r5, 0x0

jmp_25368:
  sub64 r2, r5
  mov64 r7, r2
  lsh64 r7, 0x20
  rsh64 r7, 0x20
  lsh64 r7, 0x1
  mov64 r4, r3
  div64 r4, r7
  mov64 r5, r4
  mul64 r5, r7
  sub64 r3, r5
  lsh64 r3, 0x10
  stxdw [r10-0x8], r1
  and64 r1, 0xffff
  or64 r3, r1
  lsh64 r2, 0x10
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  mov64 r7, r4
  add64 r7, r2
  mul64 r4, r4
  jlt r3, r4, jmp_25420
  mov64 r1, 0x0
  ja jmp_25438

jmp_25420:
  mov64 r1, r7
  lsh64 r1, 0x1
  add64 r1, -0x1

jmp_25438:
  mov64 r2, r3
  sub64 r2, r4
  add64 r2, r1
  stxdw [r10-0x10], r0
  mov64 r1, r0
  rsh64 r1, 0x20
  mov64 r5, r2
  lsh64 r5, 0x20
  or64 r1, r5
  mov64 r5, 0x1
  jlt r3, r4, jmp_25498
  mov64 r5, 0x0

jmp_25498:
  sub64 r7, r5
  rsh64 r2, 0x20
  mov64 r3, r7
  lsh64 r3, 0x1
  mov64 r4, r7
  rsh64 r4, 0x3f
  call fn_2c2a8
  mov64 r9, r1
  lsh64 r7, 0x20
  mov64 r8, r0
  add64 r8, r7
  mov64 r1, 0x1
  jlt r8, r0, jmp_25508
  mov64 r1, 0x0

jmp_25508:
  add64 r9, r1
  mov64 r1, r9
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r7, r0
  stxdw [r10-0x18], r1
  add64 r7, r7
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  add64 r2, r7
  mov64 r4, 0x1
  ldxdw r5, [r10-0x8]
  jgt r2, r5, jmp_25680
  mov64 r4, 0x0
  mov64 r3, 0x1
  ldxdw r7, [r10-0x10]
  jle r0, r7, jmp_25698

jmp_255c0:
  jeq r2, r5, jmp_256a8

jmp_255c8:
  mov64 r3, r4
  mov64 r5, 0x1
  ldxdw r4, [r10-0x18]
  jeq r4, 0x0, jmp_256c0

jmp_255e8:
  mov64 r4, 0x1
  jne r9, 0x0, jmp_256d8

jmp_255f8:
  mov64 r4, 0x0
  or64 r4, r5
  mov64 r5, 0x1
  jge r2, r1, jmp_256f0

jmp_25618:
  or64 r4, r5
  or64 r4, r3
  mov64 r1, 0x1
  jlt r8, r4, jmp_25640

jmp_25638:
  mov64 r1, 0x0

jmp_25640:
  sub64 r8, r4
  sub64 r9, r1
  rsh64 r6, 0x1
  mov64 r1, r8
  mov64 r2, r9
  mov64 r3, r6
  call fn_2d6e0
  ja jmp_26040

jmp_25680:
  mov64 r3, 0x1
  ldxdw r7, [r10-0x10]
  jgt r0, r7, jmp_255c0

jmp_25698:
  mov64 r3, 0x0
  jne r2, r5, jmp_255c8

jmp_256a8:
  mov64 r5, 0x1
  ldxdw r4, [r10-0x18]
  jne r4, 0x0, jmp_255e8

jmp_256c0:
  mov64 r5, 0x0
  mov64 r4, 0x1
  jeq r9, 0x0, jmp_255f8

jmp_256d8:
  or64 r4, r5
  mov64 r5, 0x1
  jlt r2, r1, jmp_25618

jmp_256f0:
  mov64 r5, 0x0
  or64 r4, r5
  or64 r4, r3
  mov64 r1, 0x1
  jge r8, r4, jmp_25638
  ja jmp_25640

jmp_25720:
  lddw r2, 0xfffffffe
  mov64 r4, r1
  and64 r4, r2
  rsh64 r4, 0x1
  mov64 r3, r1
  or64 r3, r4
  lddw r2, 0xfffffffc
  mov64 r4, r3
  and64 r4, r2
  rsh64 r4, 0x2
  or64 r3, r4
  lddw r2, 0xfffffff0
  mov64 r4, r3
  and64 r4, r2
  rsh64 r4, 0x4
  or64 r3, r4
  lddw r2, 0xffffff00
  mov64 r4, r3
  and64 r4, r2
  rsh64 r4, 0x8
  or64 r3, r4
  lddw r2, 0xffff0000
  mov64 r4, r3
  and64 r4, r2
  rsh64 r4, 0x10
  or64 r3, r4
  xor64 r3, -0x1
  mov64 r2, r3
  rsh64 r2, 0x1
  and64 r2, 0x55555555
  sub64 r3, r2
  mov64 r2, r3
  and64 r2, 0x33333333
  rsh64 r3, 0x2
  and64 r3, 0x33333333
  add64 r2, r3
  mov64 r3, r2
  rsh64 r3, 0x4
  add64 r2, r3
  and64 r2, 0xf0f0f0f
  mul64 r2, 0x1010101
  mov64 r3, r2
  rsh64 r3, 0x18
  and64 r3, 0x1e
  lsh64 r1, r3
  mov64 r3, r1
  rsh64 r3, 0x17
  and64 r3, 0x1fe
  lddw r4, data_041b
  add64 r4, r3
  mov64 r5, r1
  rsh64 r5, 0x14
  and64 r5, 0xf
  ldxb r3, [r4+0x1]
  lsh64 r3, 0x4
  or64 r3, r5
  ldxb r0, [r4+0x0]
  mov64 r4, r3
  and64 r4, 0xffff
  mov64 r5, r0
  lsh64 r5, 0x1
  div64 r4, r5
  mov64 r6, r4
  mul64 r6, r5
  sub64 r3, r6
  mov64 r5, r1
  rsh64 r5, 0x10
  and64 r5, 0xf
  lsh64 r3, 0x4
  or64 r3, r5
  lsh64 r0, 0x4
  and64 r0, 0xf0
  mov64 r5, r4
  add64 r5, r0
  mul64 r4, r4
  mov64 r0, r3
  sub64 r0, r4
  and64 r3, 0xffff
  and64 r4, 0xffff
  jlt r3, r4, jmp_25ed8
  mov64 r6, 0x0
  ja jmp_25ef0

jmp_259e0:
  mov64 r0, r3
  lsh64 r0, 0x1
  add64 r0, -0x1

jmp_259f8:
  add64 r2, r0
  mov64 r0, r1
  rsh64 r0, 0x28
  and64 r0, 0xff
  and64 r2, 0xffff
  lsh64 r2, 0x8
  or64 r2, r0
  mov64 r7, 0x1
  mov64 r0, 0x1
  jlt r4, r5, jmp_25a50
  mov64 r0, 0x0

jmp_25a50:
  sub64 r3, r0
  mov64 r4, r2
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  mov64 r5, r3
  and64 r5, 0xffff
  lsh64 r5, 0x1
  div64 r4, r5
  mov64 r0, r4
  mul64 r0, r5
  sub64 r2, r0
  mov64 r5, r1
  rsh64 r5, 0x20
  and64 r5, 0xff
  lsh64 r2, 0x8
  or64 r2, r5
  lsh64 r3, 0x8
  and64 r3, 0xff00
  mov64 r5, r4
  add64 r5, r3
  mul64 r4, r4
  mov64 r3, r2
  sub64 r3, r4
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  lsh64 r4, 0x20
  rsh64 r4, 0x20
  jlt r2, r4, jmp_25b40
  mov64 r0, 0x0
  ja jmp_25b58

jmp_25b40:
  mov64 r0, r5
  lsh64 r0, 0x1
  add64 r0, -0x1

jmp_25b58:
  add64 r3, r0
  mov64 r8, r1
  rsh64 r1, 0x10
  and64 r1, 0xffff
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  lsh64 r3, 0x10
  or64 r3, r1
  mov64 r1, 0x1
  jlt r2, r4, jmp_25bb0
  mov64 r1, 0x0

jmp_25bb0:
  sub64 r5, r1
  mov64 r1, r5
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  lsh64 r1, 0x1
  div64 r3, r1
  lsh64 r5, 0x10
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  add64 r3, r5
  mov64 r1, r3
  mov64 r2, 0x0
  mov64 r9, r3
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, 0x1
  jgt r0, r8, jmp_25c40
  mov64 r2, 0x0

jmp_25c40:
  jne r1, 0x0, jmp_25c50
  mov64 r7, 0x0

jmp_25c50:
  or64 r7, r2
  mov64 r0, r9
  sub64 r0, r7
  rsh64 r6, 0x39
  rsh64 r0, r6
  ja jmp_26038

jmp_25c80:
  mov64 r2, r1
  and64 r2, 0xfffe
  rsh64 r2, 0x1
  mov64 r3, r1
  or64 r3, r2
  mov64 r2, r3
  and64 r2, 0xfffc
  rsh64 r2, 0x2
  or64 r3, r2
  mov64 r2, r3
  and64 r2, 0xfff0
  rsh64 r2, 0x4
  or64 r3, r2
  mov64 r2, r3
  and64 r2, 0xff00
  rsh64 r2, 0x8
  or64 r3, r2
  xor64 r3, -0x1
  mov64 r2, r3
  rsh64 r2, 0x1
  and64 r2, 0x5555
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
  and64 r3, 0xf00
  rsh64 r3, 0x8
  mov64 r4, r2
  add64 r4, r3
  and64 r4, 0xe
  lsh64 r1, r4
  mov64 r4, r1
  rsh64 r4, 0x7
  and64 r4, 0x1fe
  lddw r5, data_041b
  add64 r5, r4
  mov64 r4, r1
  rsh64 r4, 0x4
  and64 r4, 0xf
  ldxb r0, [r5+0x1]
  lsh64 r0, 0x4
  or64 r0, r4
  ldxb r4, [r5+0x0]
  mov64 r5, r4
  lsh64 r5, 0x1
  div64 r0, r5
  lsh64 r4, 0x4
  and64 r4, 0xf0
  add64 r0, r4
  and64 r1, 0xffff
  mov64 r4, 0x1
  mov64 r6, r0
  mul64 r6, r6
  mov64 r7, r6
  and64 r7, 0xffff
  mov64 r5, 0x1
  jgt r7, r1, jmp_25e88
  mov64 r5, 0x0

jmp_25e88:
  rsh64 r6, 0x10
  jne r6, 0x0, jmp_25ea0
  mov64 r4, 0x0

jmp_25ea0:
  and64 r2, 0xf
  add64 r2, r3
  or64 r4, r5
  sub64 r0, r4
  rsh64 r2, 0x1
  and64 r0, 0xffff
  ja jmp_26030

jmp_25ed8:
  mov64 r6, r5
  lsh64 r6, 0x1
  add64 r6, -0x1

jmp_25ef0:
  add64 r0, r6
  mov64 r6, r1
  rsh64 r6, 0x8
  and64 r6, 0xff
  and64 r0, 0xffff
  lsh64 r0, 0x8
  or64 r0, r6
  mov64 r6, 0x1
  mov64 r7, 0x1
  jlt r3, r4, jmp_25f48
  mov64 r7, 0x0

jmp_25f48:
  sub64 r5, r7
  mov64 r3, r5
  and64 r3, 0xffff
  lsh64 r3, 0x1
  div64 r0, r3
  lsh64 r5, 0x8
  and64 r5, 0xff00
  add64 r0, r5
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r4, r0
  mul64 r4, r4
  mov64 r5, r4
  lsh64 r5, 0x20
  rsh64 r5, 0x20
  mov64 r3, 0x1
  jgt r5, r1, jmp_25fd8
  mov64 r3, 0x0

jmp_25fd8:
  rsh64 r4, 0x20
  jne r4, 0x0, jmp_25ff0
  mov64 r6, 0x0

jmp_25ff0:
  lddw r1, 0xfe000000
  and64 r2, r1
  or64 r6, r3
  sub64 r0, r6
  rsh64 r2, 0x19
  lsh64 r0, 0x20
  rsh64 r0, 0x20

jmp_26030:
  rsh64 r0, r2

jmp_26038:
  mov64 r1, 0x0

jmp_26040:
  exit

fn_26048:
  mov64 r9, r3
  ldxb r3, [r2+0xbd]
  jeq r3, 0x0, jmp_26130
  ldxb r3, [r2+0xba]
  jne r3, 0x1, jmp_26140
  ldxh r3, [r2+0xb8]
  mov64 r8, r3
  jgt r8, 0x2710, jmp_26140
  ldxw r3, [r2+0xb0]
  mov64 r0, r3
  jgt r0, 0xf4240, jmp_26140
  ldxdw r6, [r5-0xff8]
  ldxdw r3, [r5-0x1000]
  jeq r4, 0x0, jmp_26150
  ldxdw r0, [r2+0x50]
  jeq r0, 0x0, jmp_269a0
  stxdw [r10-0x30], r3
  mov64 r3, 0x1
  mov64 r5, 0x1
  jge r9, r0, jmp_265a8
  mov64 r5, 0x0
  jgt r9, r0, jmp_265b0

jmp_260f8:
  ldxb r0, [r2+0xbb]
  jne r0, 0x0, jmp_265c8

jmp_26108:
  mov64 r3, r5
  and64 r3, 0x1
  jne r3, 0x0, jmp_265d8

jmp_26120:
  stw [r1+0x4], 0xe
  ja jmp_27140

jmp_26130:
  stw [r1+0x4], 0xd
  ja jmp_27140

jmp_26140:
  stw [r1+0x4], 0x8
  ja jmp_27140

jmp_26150:
  mov64 r5, 0x5
  jeq r9, 0x0, jmp_266c8
  stxdw [r10-0x78], r0
  stxdw [r10-0x30], r3
  ldxdw r3, [r2+0x40]
  stxdw [r10-0x8], r3
  jeq r3, 0x0, jmp_266c8
  stxdw [r10-0x48], r4
  stxdw [r10-0x20], r1
  ldxdw r1, [r2+0x38]
  stxdw [r10-0x28], r2
  ldxh r7, [r2+0xb6]
  stxdw [r10-0x10], r1
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, 0x1
  jne r1, 0x0, jmp_261f0
  mov64 r2, 0x0

jmp_261f0:
  mov64 r5, 0x4
  and64 r2, 0x1
  jne r2, 0x0, jmp_271a0
  stxdw [r10-0x80], r7
  mov64 r1, 0x1
  ldxdw r2, [r10-0x28]
  ldxdw r3, [r10-0x8]
  jlt r9, r3, jmp_26238
  mov64 r1, 0x0

jmp_26238:
  mov64 r7, r9
  ldxdw r3, [r10-0x8]
  sub64 r7, r3
  mov64 r4, 0x1
  jne r7, 0x0, jmp_26268
  mov64 r4, 0x0

jmp_26268:
  stxdw [r10-0x18], r6
  mov64 r3, r1
  neg64 r3
  ldxb r2, [r2+0xbb]
  stxdw [r10-0x40], r2
  jne r2, 0x0, jmp_262a8
  sub64 r1, r4
  mov64 r3, r1

jmp_262a8:
  mov64 r4, r3
  arsh64 r4, 0x3f
  stxdw [r10-0x38], r0
  mov64 r1, r0
  mov64 r2, 0x0
  stxdw [r10-0x50], r3
  stxdw [r10-0x58], r4
  call fn_2c150
  mov64 r6, r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x68], r0
  jne r1, 0x0, jmp_26310
  neg64 r7

jmp_26310:
  ldxdw r1, [r10-0x38]
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x70], r0
  stxdw [r10-0x38], r1
  mov64 r1, 0x0
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r0
  ldxdw r3, [r10-0x38]
  add64 r2, r3
  ldxdw r5, [r10-0x68]
  mov64 r4, r5
  add64 r4, r2
  mov64 r3, 0x1
  stxdw [r10-0x60], r4
  jlt r4, r5, jmp_263c0
  mov64 r3, 0x0

jmp_263c0:
  stxdw [r10-0x38], r8
  add64 r6, r3
  mov64 r4, 0x1
  ldxdw r3, [r10-0x50]
  jlt r2, r0, jmp_263f0
  mov64 r4, 0x0

jmp_263f0:
  add64 r1, r4
  mov64 r8, r1
  add64 r8, r6
  arsh64 r6, 0x3f
  mov64 r7, r1
  arsh64 r7, 0x3f
  add64 r7, r6
  mov64 r2, 0x1
  jlt r8, r1, jmp_26440
  mov64 r2, 0x0

jmp_26440:
  add64 r7, r2
  mov64 r1, 0x0
  mov64 r2, 0x0
  ldxdw r4, [r10-0x58]
  call fn_2c150
  add64 r1, r7
  mov64 r4, r0
  add64 r4, r8
  ldxdw r6, [r10-0x18]
  mov64 r3, 0x1
  jlt r4, r0, jmp_264a0
  mov64 r3, 0x0

jmp_264a0:
  add64 r1, r3
  ldxdw r2, [r10-0x60]
  mov64 r3, r2
  arsh64 r3, 0x3f
  xor64 r1, r3
  xor64 r4, r3
  or64 r4, r1
  ldxdw r1, [r10-0x20]
  mov64 r5, 0x4
  jne r4, 0x0, jmp_266c8
  ldxdw r1, [r10-0x70]
  ldxdw r3, [r10-0x8]
  mov64 r4, 0x0
  call fn_2d790
  mov64 r7, r1
  mov64 r3, 0x1
  mov64 r5, 0x1
  jsgt r7, 0x0, jmp_26800
  mov64 r5, 0x0
  jeq r0, 0x0, jmp_26808

jmp_26540:
  ldxdw r1, [r10-0x20]
  ldxdw r2, [r10-0x28]
  ldxdw r4, [r10-0x48]
  jeq r7, 0x0, jmp_26830

jmp_26560:
  mov64 r3, r5
  and64 r3, 0x1
  jne r3, 0x0, jmp_26840

jmp_26578:
  mov64 r3, 0x0
  stxdw [r10-0x18], r6
  mov64 r8, 0x1
  mov64 r5, 0x1
  jeq r0, 0x0, jmp_26640
  ja jmp_26648

jmp_265a8:
  jle r9, r0, jmp_260f8

jmp_265b0:
  mov64 r3, 0x0
  ldxb r0, [r2+0xbb]
  jeq r0, 0x0, jmp_26108

jmp_265c8:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_26120

jmp_265d8:
  ldxdw r0, [r2+0x38]
  mov64 r3, 0x0
  mov64 r7, 0x1
  jne r0, 0x0, jmp_26600
  mov64 r7, 0x0

jmp_26600:
  stxdw [r10-0x38], r8
  stxdw [r10-0x10], r0
  neg64 r0
  neg64 r7
  stxdw [r10-0x18], r6
  mov64 r8, 0x1
  mov64 r5, 0x1
  jne r0, 0x0, jmp_26648

jmp_26640:
  mov64 r5, 0x0

jmp_26648:
  mov64 r6, r7
  add64 r6, r5
  neg64 r6
  neg64 r0
  mov64 r5, 0x1
  ldxdw r9, [r10-0x10]
  jlt r0, r9, jmp_266d8
  mov64 r5, 0x0
  jge r6, r3, jmp_266e0

jmp_26690:
  jeq r6, r3, jmp_266f0

jmp_26698:
  mov64 r5, r8
  mov64 r9, r4
  mov64 r8, r2
  mov64 r6, r1
  jeq r5, 0x0, jmp_26710
  ja jmp_26718

jmp_266c8:
  stxw [r1+0x4], r5
  ja jmp_27140

jmp_266d8:
  jlt r6, r3, jmp_26690

jmp_266e0:
  mov64 r8, 0x0
  jne r6, r3, jmp_26698

jmp_266f0:
  mov64 r9, r4
  mov64 r8, r2
  mov64 r6, r1
  jne r5, 0x0, jmp_26718

jmp_26710:
  ldxdw r0, [r10-0x10]

jmp_26718:
  arsh64 r7, 0x3f
  and64 r7, r0
  mov64 r1, r7
  mov64 r2, 0x0
  ldxdw r3, [r10-0x38]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r5, [r10-0x10]
  jlt r5, r7, jmp_271b8
  sub64 r5, r7
  mov64 r3, r8
  ldxb r2, [r3+0xbc]
  ldxdw r1, [r10-0x18]
  jeq r1, 0x0, jmp_269b0
  mov64 r8, 0x1
  mov64 r0, 0x0
  and64 r2, 0x1
  mov64 r1, r6
  jeq r2, 0x0, jmp_26eb8
  mov64 r2, 0x0
  stxdw [r10-0x10], r2
  mov64 r4, r5
  stxdw [r10-0x8], r2
  ja jmp_26ee8

jmp_26800:
  jne r0, 0x0, jmp_26540

jmp_26808:
  mov64 r3, 0x0
  ldxdw r1, [r10-0x20]
  ldxdw r2, [r10-0x28]
  ldxdw r4, [r10-0x48]
  jne r7, 0x0, jmp_26560

jmp_26830:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_26578

jmp_26840:
  ldxdw r2, [r10-0x80]
  jeq r2, 0x0, jmp_27130
  ldxdw r1, [r10-0x40]
  jeq r1, 0x0, jmp_27158
  mov64 r2, r9
  ldxdw r1, [r10-0x8]
  sub64 r2, r1
  mov64 r1, 0x0
  mov64 r3, 0x1
  jgt r2, r9, jmp_26898

jmp_26890:
  mov64 r3, 0x0

jmp_26898:
  jne r3, 0x0, jmp_268a8
  mov64 r1, r2

jmp_268a8:
  mov64 r2, 0x0
  mov64 r3, 0xf4240
  mov64 r4, 0x0
  call fn_2c150
  mov64 r7, r0
  mov64 r6, r1
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x0
  ldxdw r3, [r10-0x78]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r3, 0x1
  jlt r7, r0, jmp_26918
  mov64 r3, 0x0

jmp_26918:
  mov64 r2, r6
  sub64 r2, r1
  sub64 r2, r3
  mov64 r8, r7
  sub64 r8, r0
  mov64 r3, 0x1
  ldxdw r1, [r10-0x28]
  jgt r2, r6, jmp_26a10
  mov64 r3, 0x0
  mov64 r9, 0x1
  jle r8, r7, jmp_26a20

jmp_26970:
  jeq r2, r6, jmp_26a30

jmp_26978:
  mov64 r9, r3
  ldxdw r6, [r1+0x48]
  mov64 r1, 0x0
  jeq r9, 0x0, jmp_26a48
  ja jmp_26a50

jmp_269a0:
  stw [r1+0x4], 0x13
  ja jmp_27140

jmp_269b0:
  mov64 r1, r6
  and64 r2, 0x1
  jeq r9, 0x0, jmp_26e10
  jeq r2, 0x0, jmp_26eb0
  mov64 r0, 0x0
  mov64 r6, r7
  mov64 r2, 0x0
  stxdw [r10-0x10], r2
  mov64 r4, r5
  mov64 r5, 0x1
  stxdw [r10-0x8], r2
  ja jmp_26f20

jmp_26a10:
  mov64 r9, 0x1
  jgt r8, r7, jmp_26970

jmp_26a20:
  mov64 r9, 0x0
  jne r2, r6, jmp_26978

jmp_26a30:
  ldxdw r6, [r1+0x48]
  mov64 r1, 0x0
  jne r9, 0x0, jmp_26a50

jmp_26a48:
  mov64 r1, r2

jmp_26a50:
  mov64 r2, 0x0
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x48], r0
  stxdw [r10-0x40], r1
  mov64 r3, 0x0
  jne r9, 0x0, jmp_26a98
  mov64 r3, r8

jmp_26a98:
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  mov64 r6, r0
  mov64 r7, r1
  ldxdw r2, [r10-0x48]
  add64 r7, r2
  mov64 r2, 0x1
  ldxdw r3, [r10-0x40]
  jne r3, 0x0, jmp_26dc8
  mov64 r2, 0x0
  mov64 r3, 0x1
  jge r7, r1, jmp_26dd8

jmp_26b08:
  or64 r2, r3
  mov64 r8, 0x4
  and64 r2, 0x1
  jne r2, 0x0, jmp_26e00

jmp_26b28:
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x0
  mov64 r3, 0xf4240
  mov64 r4, 0x0
  call fn_2c150
  mov64 r4, r1
  mov64 r1, r6
  mov64 r2, r7
  mov64 r3, r0
  call fn_2c2a8
  mov64 r6, r0
  mov64 r2, r1
  ldxdw r1, [r10-0x20]
  jne r2, 0x0, jmp_27138
  mov64 r1, r6
  ldxdw r3, [r10-0x38]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  jlt r6, r0, jmp_27218
  sub64 r6, r0
  ldxdw r3, [r10-0x28]
  ldxb r5, [r3+0xbc]
  mov64 r8, r6
  ldxdw r1, [r10-0x20]
  ldxdw r4, [r10-0x10]
  jeq r5, 0x0, jmp_26c70
  mov64 r7, r5
  mov64 r5, r4
  add64 r5, r6
  mov64 r2, 0x1
  mov64 r8, r5
  jlt r5, r4, jmp_26c58
  mov64 r2, 0x0

jmp_26c58:
  and64 r2, 0x1
  jne r2, 0x0, jmp_27190
  mov64 r5, r7

jmp_26c70:
  mov64 r9, 0x0
  ldxdw r2, [r10-0x18]
  jne r2, 0x0, jmp_26cf0
  mov64 r7, r5
  mov64 r4, r8
  mov64 r2, r4
  add64 r2, r0
  mov64 r5, 0x1
  jlt r2, r4, jmp_26cc0
  mov64 r5, 0x0

jmp_26cc0:
  and64 r5, 0x1
  jne r5, 0x0, jmp_27190
  ldxdw r4, [r10-0x30]
  jlt r4, r2, jmp_26ce8
  mov64 r9, r0

jmp_26ce8:
  mov64 r5, r7

jmp_26cf0:
  mov64 r7, r6
  add64 r7, r9
  mov64 r2, 0x1
  mov64 r4, r8
  mov64 r0, r9
  jlt r7, r6, jmp_26d28
  mov64 r2, 0x0

jmp_26d28:
  and64 r2, 0x1
  jne r2, 0x0, jmp_27230
  mov64 r6, 0x0
  mov64 r2, 0x0
  stxdw [r10-0x8], r2
  jne r5, 0x0, jmp_26d68
  ldxdw r2, [r10-0x10]
  stxdw [r10-0x8], r2

jmp_26d68:
  mov64 r9, 0x1
  jne r7, 0x0, jmp_26d80
  mov64 r9, 0x0

jmp_26d80:
  neg64 r7
  neg64 r9
  mov64 r2, 0x0
  stxdw [r10-0x10], r2
  stxdw [r10-0x20], r6
  ldxdw r3, [r3+0x58]
  mov64 r2, r4
  jge r4, r3, jmp_26f50
  ja jmp_26f58

jmp_26dc8:
  mov64 r3, 0x1
  jlt r7, r1, jmp_26b08

jmp_26dd8:
  mov64 r3, 0x0
  or64 r2, r3
  mov64 r8, 0x4
  and64 r2, 0x1
  jeq r2, 0x0, jmp_26b28

jmp_26e00:
  ldxdw r1, [r10-0x20]
  ja jmp_27138

jmp_26e10:
  jeq r2, 0x0, jmp_26eb0
  mov64 r2, r5
  add64 r2, r0
  mov64 r4, 0x1
  jlt r2, r5, jmp_26e40
  mov64 r4, 0x0

jmp_26e40:
  mov64 r6, r5
  jeq r4, 0x1, jmp_27190
  mov64 r4, 0x0
  stxdw [r10-0x8], r4
  mov64 r8, 0x0
  ldxdw r4, [r10-0x30]
  jlt r4, r2, jmp_26e80
  mov64 r8, r0

jmp_26e80:
  mov64 r5, 0x1
  mov64 r4, r6
  mov64 r2, 0x0
  stxdw [r10-0x10], r2
  mov64 r0, r8
  ja jmp_26f00

jmp_26eb0:
  jlt r7, r0, jmp_27200

jmp_26eb8:
  mov64 r2, r7
  sub64 r2, r0
  stxdw [r10-0x10], r2
  mov64 r8, 0x0
  mov64 r4, 0x0
  stxdw [r10-0x8], r5

jmp_26ee8:
  mov64 r6, r7
  mov64 r5, r8
  jne r9, 0x0, jmp_26f18

jmp_26f00:
  jlt r7, r0, jmp_271e8
  mov64 r6, r7
  sub64 r6, r0

jmp_26f18:
  jlt r7, r0, jmp_271d0

jmp_26f20:
  sub64 r7, r0
  mov64 r9, 0x0
  stxdw [r10-0x20], r6
  ldxdw r3, [r3+0x58]
  mov64 r2, r4
  jlt r4, r3, jmp_26f58

jmp_26f50:
  mov64 r2, r3

jmp_26f58:
  stxdw [r10-0x18], r0
  sub64 r3, r2
  ldxdw r0, [r10-0x8]
  mov64 r6, r0
  jlt r0, r3, jmp_26ff8
  mov64 r6, r3
  mov64 r3, r2
  add64 r3, r6
  mov64 r0, 0x1
  jge r3, r2, jmp_27018

jmp_26fa8:
  and64 r0, 0x1
  jne r0, 0x0, jmp_27030

jmp_26fb8:
  mov64 r8, r7
  add64 r8, r3
  mov64 r0, 0x1
  jlt r8, r7, jmp_26fe0
  mov64 r0, 0x0

jmp_26fe0:
  jeq r5, 0x0, jmp_27048
  ldxdw r7, [r10-0x10]
  ja jmp_270b0

jmp_26ff8:
  mov64 r3, r2
  add64 r3, r6
  mov64 r0, 0x1
  jlt r3, r2, jmp_26fa8

jmp_27018:
  mov64 r0, 0x0
  and64 r0, 0x1
  jeq r0, 0x0, jmp_26fb8

jmp_27030:
  lddw r1, data_08e8
  call fn_2bcf8

jmp_27048:
  stxdw [r10-0x28], r4
  ldxdw r5, [r10-0x10]
  mov64 r4, r5
  add64 r4, r6
  mov64 r7, 0x1
  jlt r4, r5, jmp_27080
  mov64 r7, 0x0

jmp_27080:
  and64 r7, 0x1
  ldxdw r4, [r10-0x28]
  jne r7, 0x0, jmp_27190
  mov64 r7, r6
  ldxdw r5, [r10-0x10]
  add64 r7, r5

jmp_270b0:
  sub64 r4, r2
  ldxdw r5, [r10-0x8]
  sub64 r5, r6
  add64 r9, r0
  stxdw [r1+0x8], r8
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x40], r2
  stxdw [r1+0x38], r3
  ldxdw r2, [r10-0x18]
  stxdw [r1+0x30], r2
  stxdw [r1+0x28], r7
  stxdw [r1+0x20], r4
  stxdw [r1+0x18], r5
  stxdw [r1+0x10], r9
  mov64 r2, 0x0
  ja jmp_27148

jmp_27130:
  mov64 r8, 0x5

jmp_27138:
  stxw [r1+0x4], r8

jmp_27140:
  mov64 r2, 0x1

jmp_27148:
  stxw [r1+0x0], r2
  exit

jmp_27158:
  ldxdw r4, [r10-0x8]
  mov64 r2, r4
  sub64 r2, r9
  mov64 r1, 0x0
  mov64 r3, 0x1
  jle r2, r4, jmp_26890
  ja jmp_26898

jmp_27190:
  stw [r1+0x4], 0x4
  ja jmp_27140

jmp_271a0:
  ldxdw r1, [r10-0x20]
  stxw [r1+0x4], r5
  ja jmp_27140

jmp_271b8:
  lddw r1, data_0888
  call fn_2bcf8

jmp_271d0:
  lddw r1, data_08d0
  call fn_2bcf8

jmp_271e8:
  lddw r1, data_08b8
  call fn_2bcf8

jmp_27200:
  lddw r1, data_08a0
  call fn_2bcf8

jmp_27218:
  lddw r1, data_0858
  call fn_2bcf8

jmp_27230:
  lddw r1, data_0870
  call fn_2bcf8

fn_27248:
  mov64 r6, r1
  ldxdw r7, [r5-0xff8]
  jeq r7, 0x0, jmp_27348
  ldxdw r1, [r5-0xff0]
  jeq r1, 0x0, jmp_27348
  ldxdw r8, [r5-0xfe8]
  mov64 r0, r8
  and64 r0, 0xffff
  jge r0, 0x2710, jmp_27348
  stxdw [r10-0x8], r4
  stxdw [r10-0x10], r2
  stxdw [r10-0x20], r3
  ldxdw r2, [r5-0x1000]
  stxdw [r10-0x18], r2
  mov64 r2, 0x0
  lddw r3, 0xe8d4a51000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r9, 0x1
  jge r0, r7, jmp_27300
  mov64 r9, 0x0

jmp_27300:
  jeq r2, 0x0, jmp_27310
  mov64 r9, 0x1

jmp_27310:
  mov64 r1, r0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r5, r1
  and64 r9, 0x1
  jne r9, 0x0, jmp_27368

jmp_27348:
  stw [r6+0x4], 0x10

jmp_27350:
  mov64 r1, 0x1

jmp_27358:
  stxw [r6+0x0], r1
  exit

jmp_27368:
  ldxdw r2, [r10-0x8]
  mov64 r1, r2
  ldxdw r7, [r10-0x18]
  or64 r1, r7
  jeq r1, 0x0, jmp_273f8
  mov64 r3, r2
  mov64 r2, 0x1
  mov64 r1, 0x1
  ldxdw r4, [r10-0x10]
  stxdw [r10-0x30], r3
  jlt r3, r4, jmp_27418
  ldxdw r9, [r10-0x20]
  jlt r7, r9, jmp_27430

jmp_273d0:
  stxdw [r10-0x28], r0
  jne r7, r9, jmp_27448

jmp_273e0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_27460
  ja jmp_276c8

jmp_273f8:
  stdw [r6+0x10], 0x0
  stdw [r6+0x8], 0x0
  mov64 r1, 0x0
  ja jmp_27358

jmp_27418:
  mov64 r1, 0x0
  ldxdw r9, [r10-0x20]
  jge r7, r9, jmp_273d0

jmp_27430:
  mov64 r2, 0x0
  stxdw [r10-0x28], r0
  jeq r7, r9, jmp_273e0

jmp_27448:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_276c8

jmp_27460:
  sub64 r7, r9
  mov64 r1, 0x1
  stxdw [r10-0x40], r1
  ldxdw r2, [r10-0x30]
  jlt r2, r4, jmp_27490
  mov64 r1, 0x0

jmp_27490:
  sub64 r7, r1
  mov64 r3, 0x2710
  sub64 r3, r8
  and64 r3, 0xffff
  ldxdw r1, [r10-0x28]
  stxdw [r10-0x38], r5
  mov64 r2, r5
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r2, [r10-0x10]
  ldxdw r3, [r10-0x8]
  sub64 r3, r2
  stxdw [r10-0x8], r3
  mov64 r3, 0x1
  jle r1, r7, jmp_27648
  ldxdw r2, [r10-0x8]
  jle r0, r2, jmp_27660

jmp_27540:
  ldxdw r2, [r10-0x38]
  jeq r1, r7, jmp_27558

jmp_27550:
  stxdw [r10-0x40], r3

jmp_27558:
  add64 r8, 0x2710
  and64 r8, 0xffff
  ldxdw r1, [r10-0x28]
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r5, [r10-0x38]
  ldxdw r2, [r10-0x40]
  and64 r2, 0x1
  ldxdw r4, [r10-0x10]
  jne r2, 0x0, jmp_276c8
  mov64 r3, 0x1
  mov64 r2, 0x1
  ldxdw r8, [r10-0x8]
  jle r8, r0, jmp_27688
  jle r7, r1, jmp_27698

jmp_27600:
  jne r7, r1, jmp_276a8

jmp_27608:
  and64 r2, 0x1
  ldxdw r1, [r10-0x18]
  jne r2, 0x0, jmp_276c8

jmp_27620:
  ldxdw r2, [r10-0x30]
  stxdw [r6+0x8], r2
  stxdw [r6+0x10], r1
  mov64 r1, 0x0
  ja jmp_27358

jmp_27648:
  mov64 r3, 0x0
  ldxdw r2, [r10-0x8]
  jgt r0, r2, jmp_27540

jmp_27660:
  mov64 r2, 0x0
  stxdw [r10-0x40], r2
  ldxdw r2, [r10-0x38]
  jne r1, r7, jmp_27550
  ja jmp_27558

jmp_27688:
  mov64 r2, 0x0
  jgt r7, r1, jmp_27600

jmp_27698:
  mov64 r3, 0x0
  jeq r7, r1, jmp_27608

jmp_276a8:
  mov64 r2, r3
  and64 r2, 0x1
  ldxdw r1, [r10-0x18]
  jeq r2, 0x0, jmp_27620

jmp_276c8:
  mov64 r3, r4
  ldxdw r0, [r10-0x28]
  add64 r3, r0
  mov64 r2, 0x1
  mov64 r1, 0x1
  jge r3, r4, jmp_27740
  mov64 r3, r9
  add64 r3, r5
  add64 r3, r1
  jge r3, r9, jmp_27768

jmp_27718:
  jne r3, r9, jmp_27778

jmp_27720:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_27790

jmp_27730:
  stw [r6+0x4], 0x4
  ja jmp_27350

jmp_27740:
  mov64 r1, 0x0
  mov64 r3, r9
  add64 r3, r5
  add64 r3, r1
  jlt r3, r9, jmp_27718

jmp_27768:
  mov64 r2, 0x0
  jeq r3, r9, jmp_27720

jmp_27778:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_27730

jmp_27790:
  mov64 r2, r0
  add64 r2, r4
  mov64 r1, 0x0
  mov64 r3, 0x1
  jlt r2, r0, jmp_277c0
  mov64 r3, 0x0

jmp_277c0:
  stxdw [r6+0x8], r2
  add64 r5, r9
  add64 r5, r3
  stxdw [r6+0x10], r5
  ja jmp_27358

fn_277e8:
  stxdw [r10-0x8], r4
  mov64 r9, 0x1
  lddw r4, 0xe8d4a51000
  mov64 r0, 0x1
  jgt r2, r4, jmp_27820
  mov64 r0, 0x0

jmp_27820:
  mov64 r7, r3
  add64 r7, r0
  neg64 r7
  mov64 r6, r3
  and64 r6, r7
  lddw r0, 0x7fffffffffffffff
  jsge r6, 0x0, jmp_27950
  mov64 r8, -0x1
  jsge r6, 0x0, jmp_27968

jmp_27870:
  ldxdw r7, [r5-0x1000]
  mov64 r6, 0x1
  jge r8, r7, jmp_27998

jmp_27888:
  jne r0, 0x0, jmp_279a8

jmp_27890:
  jeq r6, 0x0, jmp_279b8

jmp_27898:
  mov64 r0, 0x1
  jge r2, r4, jmp_279d0

jmp_278a8:
  jsge r3, 0x0, jmp_279e0

jmp_278b0:
  jne r3, 0x0, jmp_279f0

jmp_278b8:
  jeq r0, 0x0, jmp_27a00

jmp_278c0:
  jlt r7, r8, jmp_27a10

jmp_278c8:
  ldxdw r6, [r5-0xff8]
  stxdw [r10-0x10], r1
  jeq r7, 0x0, jmp_27a28
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r6
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r9, r0
  jeq r1, 0x0, jmp_27a88

jmp_27940:
  ldxdw r5, [r10-0x10]
  ja jmp_28030

jmp_27950:
  mov64 r0, r7
  mov64 r8, -0x1
  jslt r6, 0x0, jmp_27870

jmp_27968:
  lddw r8, 0xe8d4a51000
  sub64 r8, r2
  ldxdw r7, [r5-0x1000]
  mov64 r6, 0x1
  jlt r8, r7, jmp_27888

jmp_27998:
  mov64 r6, 0x0
  jeq r0, 0x0, jmp_27890

jmp_279a8:
  mov64 r6, 0x0
  jne r6, 0x0, jmp_27898

jmp_279b8:
  mov64 r8, r7
  mov64 r0, 0x1
  jlt r2, r4, jmp_278a8

jmp_279d0:
  mov64 r0, 0x0
  jslt r3, 0x0, jmp_278b0

jmp_279e0:
  mov64 r9, 0x0
  jeq r3, 0x0, jmp_278b8

jmp_279f0:
  mov64 r0, r9
  jne r0, 0x0, jmp_278c0

jmp_27a00:
  mov64 r8, 0x0
  jge r7, r8, jmp_278c8

jmp_27a10:
  lddw r1, data_0900
  call fn_2bcf8

jmp_27a28:
  mov64 r4, 0x1
  lddw r5, 0xe8d4a51000
  mov64 r0, 0x1
  jge r2, r5, jmp_27cc8
  jsge r3, 0x0, jmp_27cd8

jmp_27a58:
  jne r3, 0x0, jmp_27ce8

jmp_27a60:
  mov64 r9, r6
  jne r0, 0x0, jmp_27a78

jmp_27a70:
  mov64 r9, 0x0

jmp_27a78:
  ldxdw r3, [r10-0x8]
  ja jmp_27a98

jmp_27a88:
  ldxdw r3, [r10-0x8]
  jlt r6, r9, jmp_280c8

jmp_27a98:
  mov64 r1, r7
  sub64 r1, r8
  mov64 r2, r3
  stxdw [r10-0x18], r1
  add64 r2, r1
  mov64 r1, 0x1
  jlt r2, r3, jmp_27ad8
  mov64 r1, 0x0

jmp_27ad8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_27940
  mov64 r1, r9
  mov64 r2, 0x0
  mov64 r3, 0x64
  mov64 r4, 0x0
  call fn_2c150
  ldxdw r4, [r10-0x8]
  stxdw [r10-0x20], r0
  mov64 r3, r6
  mov64 r6, r1
  ldxdw r1, [r10-0x18]
  add64 r1, r4
  stxdw [r10-0x28], r1
  mov64 r0, 0x0
  mov64 r1, 0x0
  mov64 r2, r3
  jeq r3, r9, jmp_27f48
  stxdw [r10-0x30], r6
  lddw r1, 0x6d23ad5f8000
  mov64 r6, r4
  add64 r6, r1
  mov64 r5, 0x1
  jlt r6, r4, jmp_27ba8
  mov64 r5, 0x0

jmp_27ba8:
  mov64 r3, r2
  sub64 r3, r9
  jne r7, r8, jmp_27d08
  lddw r1, 0x4d7b26fb00000000
  lddw r2, 0x97761759c3
  mov64 r8, r3
  mov64 r3, r6
  mov64 r4, r5
  mov64 r7, r5
  call fn_2c2a8
  mov64 r2, r1
  mov64 r1, r0
  lddw r3, 0x6d23ad5f8000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r6
  mov64 r4, r7
  call fn_2c2a8
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  lddw r3, 0x38d7ea4c68000
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r6, [r10-0x30]
  ja jmp_27f48

jmp_27cc8:
  mov64 r0, 0x0
  jslt r3, 0x0, jmp_27a58

jmp_27cd8:
  mov64 r4, 0x0
  jeq r3, 0x0, jmp_27a60

jmp_27ce8:
  mov64 r0, r4
  mov64 r9, r6
  jeq r0, 0x0, jmp_27a70
  ja jmp_27a78

jmp_27d08:
  stxdw [r10-0x38], r3
  mov64 r1, r4
  mov64 r2, 0x0
  lddw r3, 0x2aa1efb94e0000
  mov64 r4, 0x0
  mov64 r7, r5
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, r6
  mov64 r4, r7
  call fn_2c2a8
  mov64 r7, r0
  mov64 r6, r1
  ldxdw r8, [r10-0x28]
  mov64 r1, r8
  mov64 r2, 0x0
  lddw r3, 0x2aa1efb94e0000
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  lddw r1, 0x6d23ad5f8000
  mov64 r3, r8
  add64 r3, r1
  mov64 r9, 0x1
  mov64 r4, 0x1
  jlt r3, r8, jmp_27e00
  mov64 r4, 0x0

jmp_27e00:
  mov64 r1, r0
  call fn_2c2a8
  mov64 r8, r0
  mov64 r2, 0x1
  jge r1, r6, jmp_28078
  jge r8, r7, jmp_28088

jmp_27e30:
  jne r1, r6, jmp_28098

jmp_27e38:
  and64 r9, 0x1
  jne r9, 0x0, jmp_280b0

jmp_27e48:
  sub64 r1, r6
  mov64 r9, 0x1
  mov64 r2, 0x1
  jlt r8, r7, jmp_27e70
  mov64 r2, 0x0

jmp_27e70:
  sub64 r1, r2
  mov64 r2, 0x0
  ldxdw r3, [r10-0x38]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r6, r0
  sub64 r8, r7
  mov64 r7, 0x1
  jne r1, 0x0, jmp_27ec0
  mov64 r7, 0x0

jmp_27ec0:
  ldxdw r1, [r10-0x38]
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  add64 r2, r6
  jlt r2, r1, jmp_27f08
  mov64 r9, 0x0

jmp_27f08:
  or64 r7, r9
  and64 r7, 0x1
  ldxdw r6, [r10-0x30]
  jne r7, 0x0, jmp_27940
  mov64 r1, r0
  ldxdw r3, [r10-0x18]
  mov64 r4, 0x0
  call fn_2c2a8

jmp_27f48:
  ldxdw r7, [r10-0x20]
  mov64 r4, r7
  add64 r4, r0
  mov64 r3, 0x1
  mov64 r2, 0x1
  jlt r4, r7, jmp_27f80
  mov64 r2, 0x0

jmp_27f80:
  mov64 r4, r6
  add64 r4, r1
  add64 r4, r2
  ldxdw r5, [r10-0x10]
  jge r4, r6, jmp_27fc8
  jne r4, r6, jmp_27fd8

jmp_27fb0:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_27ff0
  ja jmp_28030

jmp_27fc8:
  mov64 r3, 0x0
  jeq r4, r6, jmp_27fb0

jmp_27fd8:
  mov64 r2, r3
  and64 r2, 0x1
  jne r2, 0x0, jmp_28030

jmp_27ff0:
  mov64 r2, r0
  add64 r2, r7
  mov64 r3, 0x1
  jlt r2, r0, jmp_28018
  mov64 r3, 0x0

jmp_28018:
  add64 r1, r6
  add64 r1, r3
  jeq r1, 0x0, jmp_28050

jmp_28030:
  stw [r5+0x4], 0x4
  mov64 r1, 0x1

jmp_28040:
  stxw [r5+0x0], r1
  exit

jmp_28050:
  ldxdw r1, [r10-0x28]
  stxdw [r5+0x10], r1
  stxdw [r5+0x8], r2
  mov64 r1, 0x0
  ja jmp_28040

jmp_28078:
  mov64 r2, 0x0
  jlt r8, r7, jmp_27e30

jmp_28088:
  mov64 r9, 0x0
  jeq r1, r6, jmp_27e38

jmp_28098:
  mov64 r9, r2
  and64 r9, 0x1
  jeq r9, 0x0, jmp_27e48

jmp_280b0:
  lddw r1, data_0930
  call fn_2bcf8

jmp_280c8:
  lddw r1, data_0918
  call fn_2bcf8

fn_280e0:
  mov64 r6, r3
  mov64 r7, r2
  mov64 r8, r1
  ldxdw r9, [r5-0x1000]
  mov64 r1, r9
  add64 r1, -0x1
  and64 r1, 0xffff
  jgt r1, 0x270f, jmp_281a0
  ldxdw r1, [r5-0xff8]
  mov64 r2, r1
  add64 r2, -0x2710
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jge r2, 0x7531, jmp_281a0
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  mov64 r2, 0x0
  mov64 r3, r4
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  jlt r2, 0x2710, jmp_281c0
  stw [r8+0x4], 0x4
  ja jmp_281a8

jmp_281a0:
  stw [r8+0x4], 0x10

jmp_281a8:
  mov64 r6, 0x1

jmp_281b0:
  stxw [r8+0x0], r6
  exit

jmp_281c0:
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r4, r1
  mov64 r1, r7
  or64 r1, r6
  jeq r1, 0x0, jmp_283e8
  mov64 r2, 0x1
  mov64 r1, 0x1
  jgt r7, r0, jmp_28408
  jgt r6, r4, jmp_28418

jmp_28220:
  jne r6, r4, jmp_28428

jmp_28228:
  stxdw [r10-0x18], r9
  stxdw [r10-0x10], r8
  and64 r1, 0x1
  jne r1, 0x0, jmp_28450

jmp_28248:
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r8, r0
  mov64 r3, r8
  mov64 r9, r4
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x20], r0
  stxdw [r10-0x28], r1
  stxdw [r10-0x8], r9
  mov64 r1, r9
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  mov64 r9, r0
  stxdw [r10-0x30], r1
  stxdw [r10-0x38], r8
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r7
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x40], r0
  mov64 r0, 0x1
  mov64 r4, 0x1
  ldxdw r2, [r10-0x28]
  jeq r2, 0x0, jmp_28478
  mov64 r5, 0x1
  ldxdw r2, [r10-0x30]
  jeq r2, 0x0, jmp_28498

jmp_28340:
  ldxdw r2, [r10-0x20]
  add64 r9, r2
  mov64 r8, 0x1
  jne r6, 0x0, jmp_28368

jmp_28360:
  mov64 r8, 0x0

jmp_28368:
  mov64 r2, r1
  add64 r2, r9
  mov64 r9, 0x1
  ldxdw r3, [r10-0x8]
  jne r3, 0x0, jmp_28398
  mov64 r9, 0x0

jmp_28398:
  jlt r2, r1, jmp_283a8
  mov64 r0, 0x0

jmp_283a8:
  and64 r9, r8
  or64 r9, r5
  or64 r9, r4
  or64 r9, r0
  jne r9, 0x1, jmp_284c8
  ldxdw r8, [r10-0x10]
  stw [r8+0x4], 0x4
  ja jmp_281a8

jmp_283e8:
  stdw [r8+0x10], 0x0
  stdw [r8+0x8], 0x0
  mov64 r6, 0x0
  ja jmp_281b0

jmp_28408:
  mov64 r1, 0x0
  jle r6, r4, jmp_28220

jmp_28418:
  mov64 r2, 0x0
  jeq r6, r4, jmp_28228

jmp_28428:
  mov64 r1, r2
  stxdw [r10-0x18], r9
  stxdw [r10-0x10], r8
  and64 r1, 0x1
  jeq r1, 0x0, jmp_28248

jmp_28450:
  mov64 r8, r7
  mov64 r9, r6
  stxdw [r10-0x28], r7
  stxdw [r10-0x30], r6
  ja jmp_28508

jmp_28478:
  mov64 r4, 0x0
  mov64 r5, 0x1
  ldxdw r2, [r10-0x30]
  jne r2, 0x0, jmp_28340

jmp_28498:
  mov64 r5, 0x0
  ldxdw r2, [r10-0x20]
  add64 r9, r2
  mov64 r8, 0x1
  jeq r6, 0x0, jmp_28360
  ja jmp_28368

jmp_284c8:
  ldxdw r1, [r10-0x40]
  call fn_24ae0
  stxdw [r10-0x28], r0
  stxdw [r10-0x30], r1
  ldxdw r8, [r10-0x38]
  ldxdw r9, [r10-0x8]
  mov64 r0, r7
  mov64 r4, r6

jmp_28508:
  lsh64 r9, 0x3f
  mov64 r1, r8
  rsh64 r1, 0x1
  or64 r9, r1
  lsh64 r8, 0x3f
  mov64 r1, r8
  mov64 r2, r9
  mov64 r7, r0
  mov64 r3, r7
  mov64 r6, r4
  call fn_2c2a8
  mov64 r2, r1
  stxdw [r10-0x20], r0
  mov64 r1, r0
  stxdw [r10-0x8], r2
  mov64 r3, r7
  mov64 r4, r6
  call fn_2c150
  sub64 r9, r1
  mov64 r1, 0x1
  jlt r8, r0, jmp_285b8
  mov64 r1, 0x0

jmp_285b8:
  sub64 r9, r1
  sub64 r8, r0
  or64 r8, r9
  mov64 r1, 0x1
  jne r8, 0x0, jmp_285e8
  mov64 r1, 0x0

jmp_285e8:
  ldxdw r2, [r10-0x20]
  mov64 r8, r2
  add64 r8, r1
  mov64 r1, 0x1
  ldxdw r7, [r10-0x8]
  jlt r8, r2, jmp_28620
  mov64 r1, 0x0

jmp_28620:
  add64 r7, r1
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r9, r0
  mov64 r6, 0x1
  jne r1, 0x0, jmp_28670
  mov64 r6, 0x0

jmp_28670:
  add64 r9, r9
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  add64 r2, r9
  mov64 r3, 0x1
  jeq r7, 0x0, jmp_28ac8
  mov64 r4, 0x1
  jge r2, r1, jmp_28ae0

jmp_286d0:
  or64 r3, r6
  or64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_28b08

jmp_286f0:
  lddw r1, 0x4000000000000000
  mov64 r9, r2
  add64 r9, r1
  jlt r9, r2, jmp_28b90
  mov64 r1, r0
  mov64 r2, r9
  mov64 r6, r0
  call fn_24ae0
  mov64 r7, r0
  mov64 r8, r1
  mov64 r1, r7
  mov64 r2, r8
  mov64 r3, r7
  mov64 r4, r8
  call fn_2c150
  xor64 r1, r9
  xor64 r0, r6
  or64 r0, r1
  mov64 r1, 0x1
  jne r0, 0x0, jmp_287a0
  mov64 r1, 0x0

jmp_287a0:
  mov64 r6, r7
  add64 r6, r1
  mov64 r1, 0x1
  jlt r6, r7, jmp_287c8
  mov64 r1, 0x0

jmp_287c8:
  add64 r8, r1
  lsh64 r8, 0x3f
  mov64 r1, r6
  rsh64 r1, 0x1
  or64 r8, r1
  lsh64 r6, 0x3f
  mov64 r1, r6
  mov64 r2, r8
  call fn_24ae0
  mov64 r7, r0
  mov64 r2, r1
  mov64 r1, r7
  mov64 r3, r7
  mov64 r9, r2
  mov64 r4, r2
  call fn_2c150
  xor64 r1, r8
  xor64 r0, r6
  or64 r0, r1
  mov64 r1, 0x1
  jne r0, 0x0, jmp_28878
  mov64 r1, 0x0

jmp_28878:
  mov64 r2, r7
  add64 r2, r1
  stxdw [r10-0x8], r2
  mov64 r1, 0x1
  jlt r2, r7, jmp_288a8
  mov64 r1, 0x0

jmp_288a8:
  add64 r9, r1
  ldxdw r3, [r10-0x18]
  and64 r3, 0xffff
  ldxdw r1, [r10-0x28]
  ldxdw r2, [r10-0x30]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r7, r0
  mov64 r8, r1
  ldxdw r3, [r10-0x8]
  mov64 r1, r3
  or64 r1, r9
  jeq r1, 0x0, jmp_28ba8
  mov64 r1, r7
  mov64 r2, r8
  mov64 r4, r9
  call fn_2c2a8
  mov64 r4, r9
  mov64 r6, r0
  mov64 r9, r1
  jgt r9, 0x1, jmp_28bb0
  mov64 r1, r6
  mov64 r2, r9
  ldxdw r3, [r10-0x8]
  stxdw [r10-0x18], r4
  call fn_2c150
  sub64 r8, r1
  mov64 r1, 0x1
  stxdw [r10-0x20], r1
  jlt r7, r0, jmp_289a0
  mov64 r1, 0x0

jmp_289a0:
  sub64 r8, r1
  sub64 r7, r0
  lsh64 r8, 0x3f
  mov64 r1, r7
  rsh64 r1, 0x1
  or64 r8, r1
  lsh64 r7, 0x3f
  mov64 r1, r7
  mov64 r2, r8
  ldxdw r3, [r10-0x8]
  ldxdw r4, [r10-0x18]
  call fn_2c2a8
  mov64 r3, r1
  lsh64 r9, 0x3f
  mov64 r1, r6
  rsh64 r1, 0x1
  or64 r9, r1
  lsh64 r6, 0x3f
  mov64 r1, r6
  add64 r1, r0
  mov64 r4, 0x1
  jge r1, r6, jmp_28b20
  mov64 r2, r9
  add64 r2, r3
  add64 r2, r4
  jge r2, r9, jmp_28b48

jmp_28a70:
  jne r2, r9, jmp_28b60

jmp_28a78:
  and64 r4, 0x1
  jne r4, 0x0, jmp_28b78

jmp_28a88:
  mov64 r6, 0x0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  ldxdw r8, [r10-0x10]
  stxdw [r8+0x10], r1
  stxdw [r8+0x8], r0
  ja jmp_281b0

jmp_28ac8:
  mov64 r3, 0x0
  mov64 r4, 0x1
  jlt r2, r1, jmp_286d0

jmp_28ae0:
  mov64 r4, 0x0
  or64 r3, r6
  or64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_286f0

jmp_28b08:
  lddw r1, data_0948
  call fn_2bcf8

jmp_28b20:
  mov64 r4, 0x0
  mov64 r2, r9
  add64 r2, r3
  add64 r2, r4
  jlt r2, r9, jmp_28a70

jmp_28b48:
  mov64 r3, 0x0
  stxdw [r10-0x20], r3
  jeq r2, r9, jmp_28a78

jmp_28b60:
  ldxdw r4, [r10-0x20]
  and64 r4, 0x1
  jeq r4, 0x0, jmp_28a88

jmp_28b78:
  lddw r1, data_0990
  call fn_2bcf8

jmp_28b90:
  lddw r1, data_0960
  call fn_2bcf8

jmp_28ba8:
  call fn_2bcc0

jmp_28bb0:
  lddw r1, data_0978
  call fn_2bcf8

fn_28bc8:
  jeq r3, 0x15b, jmp_28c50
  jeq r3, 0x15a, jmp_28c18
  jne r3, 0x156, jmp_29510
  ldxdw r4, [r2+0x0]
  lddw r5, 0x3330304746435443
  jne r4, r5, jmp_29510
  mov64 r5, 0x1
  mov64 r4, 0x0
  ja jmp_28c80

jmp_28c18:
  ldxdw r4, [r2+0x0]
  lddw r5, 0x3430304746435443
  jne r4, r5, jmp_29510
  mov64 r5, 0x0
  mov64 r4, 0x1
  ja jmp_28c80

jmp_28c50:
  mov64 r4, 0x0
  ldxdw r0, [r2+0x0]
  lddw r6, 0x3530304746435443
  mov64 r5, 0x0
  jne r0, r6, jmp_29510

jmp_28c80:
  mov64 r6, 0x0
  ldxw r8, [r2+0x12b]
  ldxw r0, [r2+0x10b]
  stxdw [r10-0x8], r0
  ldxw r0, [r2+0xeb]
  stxdw [r10-0x10], r0
  ldxw r0, [r2+0xcb]
  stxdw [r10-0x18], r0
  ldxw r0, [r2+0xab]
  stxdw [r10-0x20], r0
  ldxw r0, [r2+0x8b]
  stxdw [r10-0x28], r0
  ldxw r0, [r2+0x6b]
  stxdw [r10-0x30], r0
  ldxw r0, [r2+0x4b]
  stxdw [r10-0x38], r0
  ldxw r0, [r2+0x2b]
  stxdw [r10-0x40], r0
  ldxw r0, [r2+0xb]
  stxdw [r10-0x48], r0
  ldxb r0, [r2+0x148]
  mov64 r9, 0x0
  jeq r0, 0x0, jmp_28d48
  jne r0, 0x1, jmp_29520
  mov64 r9, 0x1

jmp_28d48:
  ldxb r0, [r2+0x149]
  jeq r0, 0x0, jmp_28d68
  jne r0, 0x1, jmp_29520
  mov64 r6, 0x1

jmp_28d68:
  ldxw r0, [r2+0x152]
  stxdw [r10-0x50], r0
  ldxdw r0, [r2+0x14a]
  jeq r5, 0x0, jmp_29488
  jne r3, 0x156, jmp_29520
  mov64 r7, 0x0
  mov64 r5, 0x32

jmp_28da0:
  stxdw [r10-0x58], r5
  mov64 r3, r2
  add64 r3, 0x12f
  stxdw [r10-0x60], r3
  mov64 r3, r2
  add64 r3, 0x128
  stxdw [r10-0x68], r3
  mov64 r3, r2
  add64 r3, 0x10f
  stxdw [r10-0x80], r3
  mov64 r3, r2
  add64 r3, 0x108
  stxdw [r10-0x90], r3
  mov64 r3, r2
  add64 r3, 0xef
  stxdw [r10-0x98], r3
  mov64 r3, r2
  add64 r3, 0xe8
  stxdw [r10-0xa8], r3
  mov64 r3, r2
  add64 r3, 0xcf
  stxdw [r10-0xb0], r3
  mov64 r3, r2
  add64 r3, 0xc8
  stxdw [r10-0xb8], r3
  mov64 r3, r2
  add64 r3, 0xaf
  stxdw [r10-0xc0], r3
  mov64 r3, r2
  add64 r3, 0xa8
  stxdw [r10-0xc8], r3
  mov64 r3, r2
  add64 r3, 0x8f
  stxdw [r10-0xd0], r3
  mov64 r3, r2
  add64 r3, 0x88
  stxdw [r10-0xd8], r3
  mov64 r5, r2
  add64 r5, 0x6f
  mov64 r3, r2
  add64 r3, 0x68
  stxdw [r10-0xe0], r3
  stxdw [r10-0x78], r9
  mov64 r9, r2
  add64 r9, 0x4f
  stxdw [r10-0x70], r0
  mov64 r0, r2
  add64 r0, 0x48
  stxdw [r10-0x88], r6
  mov64 r6, r2
  add64 r6, 0x2f
  mov64 r4, r2
  add64 r4, 0x28
  mov64 r3, r2
  add64 r3, 0xf
  add64 r2, 0x8
  stxdw [r10-0xa0], r8
  ldxb r8, [r2+0x2]
  stxb [r1+0x2], r8
  ldxh r2, [r2+0x0]
  stxh [r1+0x0], r2
  ldxdw r2, [r10-0x48]
  stxw [r1+0x3], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x7], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0xf], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0x17], r2
  ldxb r2, [r3+0x18]
  stxb [r1+0x1f], r2
  ldxh r2, [r4+0x0]
  stxh [r1+0x20], r2
  ldxb r2, [r4+0x2]
  stxb [r1+0x22], r2
  ldxdw r2, [r10-0x40]
  stxw [r1+0x23], r2
  ldxdw r2, [r6+0x0]
  stxdw [r1+0x27], r2
  ldxdw r2, [r6+0x8]
  stxdw [r1+0x2f], r2
  ldxdw r2, [r6+0x10]
  stxdw [r1+0x37], r2
  ldxb r2, [r6+0x18]
  stxb [r1+0x3f], r2
  ldxh r2, [r0+0x0]
  stxh [r1+0x40], r2
  ldxb r2, [r0+0x2]
  stxb [r1+0x42], r2
  ldxdw r2, [r10-0x38]
  stxw [r1+0x43], r2
  ldxb r2, [r9+0x18]
  stxb [r1+0x5f], r2
  ldxdw r2, [r9+0x10]
  stxdw [r1+0x57], r2
  ldxdw r2, [r9+0x8]
  stxdw [r1+0x4f], r2
  ldxdw r2, [r9+0x0]
  stxdw [r1+0x47], r2
  ldxdw r3, [r10-0xe0]
  ldxh r2, [r3+0x0]
  stxh [r1+0x60], r2
  ldxb r2, [r3+0x2]
  stxb [r1+0x62], r2
  ldxdw r2, [r10-0x30]
  stxw [r1+0x63], r2
  ldxb r2, [r5+0x18]
  stxb [r1+0x7f], r2
  ldxdw r2, [r5+0x10]
  stxdw [r1+0x77], r2
  ldxdw r2, [r5+0x8]
  stxdw [r1+0x6f], r2
  ldxdw r2, [r5+0x0]
  stxdw [r1+0x67], r2
  ldxdw r3, [r10-0xd8]
  ldxb r2, [r3+0x2]
  stxb [r1+0x82], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0x80], r2
  ldxdw r2, [r10-0x28]
  stxw [r1+0x83], r2
  ldxdw r3, [r10-0xd0]
  ldxb r2, [r3+0x18]
  stxb [r1+0x9f], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0x97], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0x8f], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x87], r2
  ldxdw r3, [r10-0xc8]
  ldxb r2, [r3+0x2]
  stxb [r1+0xa2], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0xa0], r2
  ldxdw r2, [r10-0x20]
  stxw [r1+0xa3], r2
  ldxdw r3, [r10-0xc0]
  ldxb r2, [r3+0x18]
  stxb [r1+0xbf], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0xb7], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0xaf], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0xa7], r2
  ldxdw r3, [r10-0xb8]
  ldxb r2, [r3+0x2]
  stxb [r1+0xc2], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0xc0], r2
  ldxdw r2, [r10-0x18]
  stxw [r1+0xc3], r2
  ldxdw r3, [r10-0xb0]
  ldxb r2, [r3+0x18]
  stxb [r1+0xdf], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0xd7], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0xcf], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0xc7], r2
  ldxdw r3, [r10-0xa8]
  ldxb r2, [r3+0x2]
  stxb [r1+0xe2], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0xe0], r2
  ldxdw r2, [r10-0x10]
  stxw [r1+0xe3], r2
  ldxdw r3, [r10-0x98]
  ldxb r2, [r3+0x18]
  stxb [r1+0xff], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0xf7], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0xef], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0xe7], r2
  ldxdw r3, [r10-0x90]
  ldxb r2, [r3+0x2]
  stxb [r1+0x102], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0x100], r2
  ldxdw r2, [r10-0x8]
  stxw [r1+0x103], r2
  ldxdw r3, [r10-0x80]
  ldxb r2, [r3+0x18]
  stxb [r1+0x11f], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0x117], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0x10f], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x107], r2
  ldxdw r3, [r10-0x68]
  ldxb r2, [r3+0x2]
  stxb [r1+0x122], r2
  ldxh r2, [r3+0x0]
  stxh [r1+0x120], r2
  ldxdw r2, [r10-0xa0]
  stxw [r1+0x123], r2
  ldxdw r3, [r10-0x60]
  ldxb r2, [r3+0x18]
  stxb [r1+0x13f], r2
  ldxdw r2, [r3+0x10]
  stxdw [r1+0x137], r2
  ldxdw r2, [r3+0x8]
  stxdw [r1+0x12f], r2
  ldxdw r2, [r3+0x0]
  stxdw [r1+0x127], r2
  ldxdw r2, [r10-0x88]
  stxb [r1+0x151], r2
  ldxdw r2, [r10-0x78]
  stxb [r1+0x150], r2
  ldxdw r2, [r10-0x58]
  stxw [r1+0x14c], r2
  ldxdw r2, [r10-0x50]
  stxw [r1+0x148], r2
  ldxdw r2, [r10-0x70]
  stxdw [r1+0x140], r2
  ja jmp_29530

jmp_29488:
  jlt r3, 0x15a, jmp_29520
  mov64 r7, 0x0
  ldxw r5, [r2+0x156]
  jeq r4, 0x0, jmp_294c0
  mov64 r4, 0x15a
  jeq r4, r3, jmp_29508
  ja jmp_29520

jmp_294c0:
  stxdw [r10-0x58], r5
  jeq r3, 0x15a, jmp_29520
  mov64 r4, 0x15b
  ldxb r5, [r2+0x15a]
  jeq r5, 0x0, jmp_294f8
  jne r5, 0x1, jmp_29520
  mov64 r7, 0x1

jmp_294f8:
  ldxdw r5, [r10-0x58]
  jne r4, r3, jmp_29520

jmp_29508:
  jle r5, 0x3e8, jmp_28da0

jmp_29510:
  stw [r1+0x0], 0x2
  ja jmp_29528

jmp_29520:
  stw [r1+0x0], 0x1

jmp_29528:
  mov64 r7, 0x2

jmp_29530:
  stxb [r1+0x152], r7
  exit

fn_29540:
  mov64 r8, r4
  mov64 r7, r3
  mov64 r9, r2
  mov64 r6, r1
  mov64 r4, 0x8
  ldxdw r3, [r5-0xfe8]
  jeq r3, 0x0, jmp_295e8
  ldxw r1, [r9+0xa0]
  jeq r1, 0x0, jmp_295e8
  ldxdw r2, [r5-0xff8]
  stxdw [r10-0x28], r2
  ldxdw r2, [r5-0x1000]
  stxdw [r10-0x20], r2
  ldxdw r2, [r5-0xff0]
  stxdw [r10-0x30], r2
  mov64 r2, 0x0
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r4, 0x4
  jlt r2, 0x2710, jmp_29608

jmp_295e8:
  stxw [r6+0x4], r4

jmp_295f0:
  mov64 r7, 0x1

jmp_295f8:
  stxw [r6+0x0], r7
  exit

jmp_29608:
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  jgt r0, 0x1, jmp_29638
  mov64 r0, 0x1

jmp_29638:
  ldxw r2, [r9+0xa4]
  ldxh r3, [r9+0xa8]
  ldxdw r4, [r10-0x20]
  ldxdw r5, [r10-0x28]
  jne r3, 0x0, jmp_296c0
  mov64 r1, r2
  jne r1, 0x0, jmp_296c0
  mov64 r2, 0x1
  mov64 r1, 0x1
  jgt r4, r7, jmp_297c0
  mov64 r1, 0x0
  jle r5, r8, jmp_297c8

jmp_29698:
  jeq r5, r8, jmp_297d8

jmp_296a0:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_29958
  ja jmp_297e8

jmp_296c0:
  stxdw [r10-0x38], r2
  mov64 r2, 0x1
  mov64 r1, 0x1
  jgt r4, r7, jmp_29718
  mov64 r1, 0x0
  jle r5, r8, jmp_29720

jmp_296f0:
  jeq r5, r8, jmp_29730

jmp_296f8:
  mov64 r1, r2
  and64 r1, 0x1
  jne r1, 0x0, jmp_297e8
  ja jmp_29740

jmp_29718:
  jgt r5, r8, jmp_296f0

jmp_29720:
  mov64 r2, 0x0
  jne r5, r8, jmp_296f8

jmp_29730:
  and64 r1, 0x1
  jne r1, 0x0, jmp_297e8

jmp_29740:
  stxdw [r10-0x40], r3
  mov64 r9, r7
  ldxdw r1, [r10-0x30]
  add64 r9, r1
  mov64 r2, 0x1
  mov64 r1, 0x1
  jlt r9, r7, jmp_297f8
  mov64 r1, 0x0
  mov64 r3, r8
  add64 r3, r1
  jge r3, r8, jmp_29810

jmp_29798:
  jge r9, r7, jmp_29820

jmp_297a0:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_29830
  ja jmp_29d38

jmp_297c0:
  jgt r5, r8, jmp_29698

jmp_297c8:
  mov64 r2, 0x0
  jne r5, r8, jmp_296a0

jmp_297d8:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_29958

jmp_297e8:
  stw [r6+0x4], 0x8
  ja jmp_295f0

jmp_297f8:
  mov64 r3, r8
  add64 r3, r1
  jlt r3, r8, jmp_29798

jmp_29810:
  mov64 r2, 0x0
  jlt r9, r7, jmp_297a0

jmp_29820:
  and64 r1, 0x1
  jne r1, 0x0, jmp_29d38

jmp_29830:
  ldxdw r1, [r10-0x38]
  stxdw [r10-0xff8], r1
  ldxdw r1, [r10-0x40]
  stxdw [r10-0x1000], r1
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r5, r10
  mov64 r2, r7
  mov64 r3, r8
  stxdw [r10-0x48], r0
  mov64 r4, r0
  call fn_280e0
  ldxw r1, [r10-0x18]
  jne r1, 0x0, jmp_29940
  mov64 r1, 0x1
  jlt r9, r7, jmp_298b8
  mov64 r1, 0x0

jmp_298b8:
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x50], r2
  ldxdw r7, [r10-0x10]
  ldxdw r2, [r10-0x38]
  stxdw [r10-0xff8], r2
  ldxdw r2, [r10-0x40]
  stxdw [r10-0x1000], r2
  add64 r8, r1
  mov64 r1, r10
  add64 r1, -0x18
  mov64 r5, r10
  mov64 r2, r9
  mov64 r3, r8
  ldxdw r4, [r10-0x48]
  call fn_280e0
  ldxw r1, [r10-0x18]
  jne r1, 0x1, jmp_29d48

jmp_29940:
  ldxw r1, [r10-0x14]
  stxw [r6+0x4], r1
  ja jmp_295f0

jmp_29958:
  mov64 r9, r7
  ldxdw r1, [r10-0x30]
  add64 r9, r1
  mov64 r2, 0x1
  mov64 r1, 0x1
  jlt r9, r7, jmp_299d0
  mov64 r1, 0x0
  mov64 r3, r8
  add64 r3, r1
  jge r3, r8, jmp_299e8

jmp_299a8:
  jge r9, r7, jmp_299f8

jmp_299b0:
  mov64 r1, r2
  and64 r1, 0x1
  jeq r1, 0x0, jmp_29a08
  ja jmp_29d38

jmp_299d0:
  mov64 r3, r8
  add64 r3, r1
  jlt r3, r8, jmp_299a8

jmp_299e8:
  mov64 r2, 0x0
  jlt r9, r7, jmp_299b0

jmp_299f8:
  and64 r1, 0x1
  jne r1, 0x0, jmp_29d38

jmp_29a08:
  mov64 r1, 0x1
  mov64 r2, 0x1
  jlt r9, r7, jmp_29a70
  mov64 r2, 0x0
  add64 r8, r2
  mov64 r2, 0x1
  jgt r9, r0, jmp_29a88

jmp_29a40:
  jeq r8, 0x0, jmp_29a98

jmp_29a48:
  mov64 r1, 0x0
  jne r8, 0x0, jmp_29aa0

jmp_29a58:
  and64 r2, 0x1
  jeq r2, 0x0, jmp_29ab8
  ja jmp_29ba8

jmp_29a70:
  add64 r8, r2
  mov64 r2, 0x1
  jle r9, r0, jmp_29a40

jmp_29a88:
  mov64 r2, 0x0
  jne r8, 0x0, jmp_29a48

jmp_29a98:
  jeq r8, 0x0, jmp_29a58

jmp_29aa0:
  mov64 r2, r1
  and64 r2, 0x1
  jne r2, 0x0, jmp_29ba8

jmp_29ab8:
  mov64 r1, r8
  mov64 r2, 0x0
  mov64 r3, r0
  mov64 r4, 0x0
  mov64 r7, r0
  call fn_2c150
  mov64 r8, r0
  stxdw [r10-0x38], r1
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r3, r9
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  add64 r2, r8
  mov64 r4, 0x1
  mov64 r3, 0x1
  ldxdw r5, [r10-0x38]
  jne r5, 0x0, jmp_29d10
  mov64 r3, 0x0
  jge r2, r1, jmp_29d18

jmp_29b60:
  or64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_29d38

jmp_29b78:
  mov64 r1, r0
  call fn_24ae0
  mov64 r9, r0
  mov64 r8, r1
  ldxdw r4, [r10-0x20]
  ldxdw r5, [r10-0x28]

jmp_29ba8:
  mov64 r2, r8
  sub64 r2, r5
  mov64 r7, 0x0
  mov64 r1, 0x1
  mov64 r3, 0x1
  jlt r9, r4, jmp_29be0
  mov64 r3, 0x0

jmp_29be0:
  sub64 r2, r3
  mov64 r3, r9
  sub64 r3, r4
  mov64 r4, 0x1
  jgt r3, r9, jmp_29c88
  mov64 r4, 0x0
  mov64 r5, 0x1
  jle r2, r8, jmp_29c98

jmp_29c20:
  jeq r2, r8, jmp_29ca8

jmp_29c28:
  mov64 r4, r5
  mov64 r5, 0x0
  jeq r4, 0x0, jmp_29cb8

jmp_29c40:
  mov64 r2, 0x0
  jne r4, 0x0, jmp_29cd0

jmp_29c50:
  mov64 r2, r3
  ldxdw r3, [r10-0x30]
  jge r2, r3, jmp_29ce0

jmp_29c68:
  jeq r5, 0x0, jmp_29cf0

jmp_29c70:
  mov64 r1, 0x0
  jeq r1, 0x0, jmp_29cf8
  ja jmp_29d00

jmp_29c88:
  mov64 r5, 0x1
  jgt r2, r8, jmp_29c20

jmp_29c98:
  mov64 r5, 0x0
  jne r2, r8, jmp_29c28

jmp_29ca8:
  mov64 r5, 0x0
  jne r4, 0x0, jmp_29c40

jmp_29cb8:
  mov64 r5, r2
  mov64 r2, 0x0
  jeq r4, 0x0, jmp_29c50

jmp_29cd0:
  ldxdw r3, [r10-0x30]
  jlt r2, r3, jmp_29c68

jmp_29ce0:
  mov64 r1, 0x0
  jne r5, 0x0, jmp_29c70

jmp_29cf0:
  jne r1, 0x0, jmp_29d00

jmp_29cf8:
  ldxdw r2, [r10-0x30]

jmp_29d00:
  stxdw [r6+0x8], r2
  ja jmp_295f8

jmp_29d10:
  jlt r2, r1, jmp_29b60

jmp_29d18:
  mov64 r4, 0x0
  or64 r3, r4
  and64 r3, 0x1
  jeq r3, 0x0, jmp_29b78

jmp_29d38:
  stw [r6+0x4], 0x4
  ja jmp_295f0

jmp_29d48:
  mov64 r0, r7
  mov64 r7, 0x0
  mov64 r1, 0x1
  stxdw [r10-0x38], r1
  ldxdw r3, [r10-0x20]
  jlt r0, r3, jmp_29ea8
  mov64 r1, 0x0
  mov64 r2, 0x1
  ldxdw r4, [r10-0x28]
  ldxdw r5, [r10-0x50]
  jge r5, r4, jmp_29ec8

jmp_29da0:
  jeq r5, r4, jmp_29ed8

jmp_29da8:
  mov64 r1, r2
  jeq r1, 0x0, jmp_29ee0

jmp_29db8:
  jne r1, 0x0, jmp_29dc8

jmp_29dc0:
  mov64 r5, r4

jmp_29dc8:
  ldxdw r2, [r10-0x8]
  mov64 r1, r2
  sub64 r1, r5
  ldxdw r5, [r10-0x10]
  mov64 r3, 0x1
  jlt r5, r0, jmp_29e00
  mov64 r3, 0x0

jmp_29e00:
  sub64 r1, r3
  mov64 r3, r5
  sub64 r3, r0
  mov64 r4, 0x1
  jgt r3, r5, jmp_29ef8
  mov64 r4, 0x0
  mov64 r5, 0x1
  jle r1, r2, jmp_29f08

jmp_29e40:
  jeq r1, r2, jmp_29f18

jmp_29e48:
  mov64 r4, r5
  mov64 r9, 0x0
  jeq r4, 0x0, jmp_29f28

jmp_29e60:
  mov64 r8, 0x0
  jne r4, 0x0, jmp_29f40

jmp_29e70:
  mov64 r8, r1
  mov64 r1, r9
  jeq r8, 0x0, jmp_29f50

jmp_29e88:
  jgt r9, 0x1, jmp_29f60

jmp_29e90:
  mov64 r9, 0x1
  jne r8, 0x0, jmp_29f68
  ja jmp_29f70

jmp_29ea8:
  mov64 r2, 0x1
  ldxdw r4, [r10-0x28]
  ldxdw r5, [r10-0x50]
  jlt r5, r4, jmp_29da0

jmp_29ec8:
  mov64 r2, 0x0
  jne r5, r4, jmp_29da8

jmp_29ed8:
  jne r1, 0x0, jmp_29db8

jmp_29ee0:
  mov64 r0, r3
  jeq r1, 0x0, jmp_29dc0
  ja jmp_29dc8

jmp_29ef8:
  mov64 r5, 0x1
  jgt r1, r2, jmp_29e40

jmp_29f08:
  mov64 r5, 0x0
  jne r1, r2, jmp_29e48

jmp_29f18:
  mov64 r9, 0x0
  jne r4, 0x0, jmp_29e60

jmp_29f28:
  mov64 r9, r3
  mov64 r8, 0x0
  jeq r4, 0x0, jmp_29e70

jmp_29f40:
  mov64 r1, r9
  jne r8, 0x0, jmp_29e88

jmp_29f50:
  mov64 r1, 0x1
  jle r9, 0x1, jmp_29e90

jmp_29f60:
  jeq r8, 0x0, jmp_29f70

jmp_29f68:
  mov64 r9, r1

jmp_29f70:
  ldxdw r1, [r10-0x40]
  mov64 r2, 0x0
  ldxdw r3, [r10-0x30]
  mov64 r4, 0x0
  call fn_2c150
  mov64 r2, r1
  mov64 r1, r0
  mov64 r3, 0x2710
  mov64 r4, 0x0
  call fn_2c2a8
  mov64 r2, 0x1
  jlt r0, r9, jmp_2a000
  mov64 r2, 0x0
  jge r1, r8, jmp_2a008

jmp_29fe0:
  jeq r1, r8, jmp_2a020

jmp_29fe8:
  ldxdw r2, [r10-0x38]
  jeq r2, 0x0, jmp_2a028
  ja jmp_2a030

jmp_2a000:
  jlt r1, r8, jmp_29fe0

jmp_2a008:
  mov64 r3, 0x0
  stxdw [r10-0x38], r3
  jne r1, r8, jmp_29fe8

jmp_2a020:
  jne r2, 0x0, jmp_2a030

jmp_2a028:
  mov64 r0, r9

jmp_2a030:
  stxdw [r6+0x8], r0
  ja jmp_295f8

fn_2a040:
  ldxdw r3, [r2+0x58]
  jeq r3, 0x0, jmp_2a060
  stdw [r1+0x8], 0x0
  ja jmp_2a1a0

jmp_2a060:
  ldxdw r3, [r2+0x30]
  ldxdw r4, [r2+0x28]
  mov64 r0, r4
  add64 r0, r3
  mov64 r5, 0x1
  jlt r0, r4, jmp_2a098
  mov64 r5, 0x0

jmp_2a098:
  jeq r5, 0x1, jmp_2a1b8
  ldxdw r0, [r2+0x40]
  ldxdw r5, [r2+0x38]
  mov64 r7, r5
  add64 r7, r0
  mov64 r6, 0x1
  jlt r7, r5, jmp_2a0d8
  mov64 r6, 0x0

jmp_2a0d8:
  jeq r6, 0x1, jmp_2a1b8
  add64 r0, r5
  ldxdw r5, [r2+0x48]
  mov64 r7, r0
  add64 r7, r5
  mov64 r6, 0x1
  jlt r7, r0, jmp_2a118
  mov64 r6, 0x0

jmp_2a118:
  jeq r6, 0x1, jmp_2a1b8
  add64 r3, r4
  add64 r5, r0
  mov64 r0, r3
  add64 r0, r5
  mov64 r4, 0x1
  jlt r0, r3, jmp_2a158
  mov64 r4, 0x0

jmp_2a158:
  jeq r4, 0x1, jmp_2a1b8
  add64 r5, r3
  ldxdw r2, [r2+0x20]
  jge r2, r5, jmp_2a190
  stw [r1+0x4], 0xb
  mov64 r2, 0x1
  ja jmp_2a1a8

jmp_2a190:
  sub64 r2, r5
  stxdw [r1+0x8], r2

jmp_2a1a0:
  mov64 r2, 0x0

jmp_2a1a8:
  stxw [r1+0x0], r2
  exit

jmp_2a1b8:
  stw [r1+0x4], 0x4
  mov64 r2, 0x1
  ja jmp_2a1a8

fn_2a1d0:
  ldxw r2, [r1+0xa4]
  ldxh r3, [r1+0xa8]
  jne r3, 0x0, jmp_2a1f8
  mov64 r4, r2
  jeq r4, 0x0, jmp_2a238

jmp_2a1f8:
  mov64 r0, 0x2
  add64 r3, -0x1
  and64 r3, 0xffff
  jgt r3, 0x270f, jmp_2a3d0
  add64 r2, -0x2710
  lsh64 r2, 0x20
  rsh64 r2, 0x20
  jge r2, 0x7531, jmp_2a3d0

jmp_2a238:
  ldxw r2, [r1+0xa0]
  jeq r2, 0x0, jmp_2a3c8
  jgt r2, 0xf4240, jmp_2a3c8
  ldxdw r2, [r1+0x98]
  jeq r2, 0x0, jmp_2a3c8
  ldxdw r2, [r1+0x30]
  ldxdw r4, [r1+0x28]
  mov64 r5, r4
  add64 r5, r2
  mov64 r3, 0x1
  jlt r5, r4, jmp_2a298
  mov64 r3, 0x0

jmp_2a298:
  mov64 r0, 0x4
  and64 r3, 0x1
  jne r3, 0x0, jmp_2a3d0
  ldxdw r5, [r1+0x40]
  ldxdw r3, [r1+0x38]
  mov64 r7, r3
  add64 r7, r5
  mov64 r6, 0x1
  jlt r7, r3, jmp_2a2e8
  mov64 r6, 0x0

jmp_2a2e8:
  and64 r6, 0x1
  jne r6, 0x0, jmp_2a3d0
  add64 r5, r3
  ldxdw r3, [r1+0x48]
  mov64 r7, r5
  add64 r7, r3
  mov64 r6, 0x1
  jlt r7, r5, jmp_2a330
  mov64 r6, 0x0

jmp_2a330:
  and64 r6, 0x1
  jne r6, 0x0, jmp_2a3d0
  add64 r2, r4
  mov64 r4, r3
  add64 r4, r5
  mov64 r6, r2
  add64 r6, r4
  mov64 r5, 0x1
  jlt r6, r2, jmp_2a380
  mov64 r5, 0x0

jmp_2a380:
  and64 r5, 0x1
  jne r5, 0x0, jmp_2a3d0
  add64 r4, r2
  mov64 r0, 0xb
  ldxdw r2, [r1+0x20]
  jlt r2, r4, jmp_2a3d0
  ldxdw r5, [r1+0x50]
  sub64 r2, r4
  jle r5, r2, jmp_2a3d8

jmp_2a3c8:
  mov64 r0, 0x2

jmp_2a3d0:
  exit

jmp_2a3d8:
  ldxdw r2, [r1+0x70]
  ldxdw r4, [r1+0x68]
  jgt r4, r2, jmp_2a3c8
  ldxdw r1, [r1+0x90]
  mov64 r0, 0x2
  jgt r1, r3, jmp_2a3d0
  mov64 r0, 0x0
  ja jmp_2a3d0

fn_2a418:
  mov64 r7, r2
  mov64 r6, r1
  mov64 r1, r7
  and64 r1, 0xffff
  jle r1, 0x2, jmp_2a458
  stb [r6+0xb8], 0x2
  stw [r6+0x0], 0x8
  ja jmp_2a548

jmp_2a458:
  lsh64 r1, 0x3
  mov64 r2, r10
  add64 r2, -0x18
  add64 r2, r1
  stdw [r10-0x8], 0x186a0
  stdw [r10-0x10], 0x36ee8
  stdw [r10-0x18], 0x927c0
  ldxdw r1, [r2+0x0]
  mov64 r2, 0x0
  mov64 r3, 0xf4240
  mov64 r4, 0x0
  call fn_2c150
  mov64 r8, r0
  mov64 r2, 0x1
  jne r1, 0x0, jmp_2a4d8
  mov64 r2, 0x0

jmp_2a4d8:
  and64 r2, 0x1
  jne r2, 0x0, jmp_2a550
  mov64 r1, r6
  mov64 r2, 0x0
  mov64 r3, 0x90
  call fn_2c080
  stxh [r6+0xb2], r7
  stxh [r6+0xb0], r7
  stxdw [r6+0x90], r8
  stb [r6+0xb8], 0x0
  stw [r6+0xb4], 0x500c8
  stdw [r6+0xa8], 0x0
  stdw [r6+0xa0], 0x989680
  stdw [r6+0x98], 0xf4240

jmp_2a548:
  exit

jmp_2a550:
  lddw r1, data_09d8
  call fn_2bcf8

fn_2a568:
  ldxb r0, [r2+0xb8]
  jeq r0, 0x0, jmp_2a5e8
  ldxh r4, [r2+0xb0]
  ldxh r3, [r3+0x28]
  jne r3, r4, jmp_2a6a8
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x0]
  mov64 r4, r2
  add64 r4, -0x1
  jge r4, r3, jmp_2a6b8
  mov64 r4, r3
  and64 r4, r2
  xor64 r3, r2
  rsh64 r3, 0x1
  add64 r4, r3
  ja jmp_2a680

jmp_2a5e8:
  ldxdw r0, [r3+0x18]
  jeq r0, 0x0, jmp_2a698
  ldxdw r0, [r3+0x20]
  jlt r4, r0, jmp_2a698
  sub64 r4, r0
  jge r4, r5, jmp_2a698
  ldxh r2, [r2+0xb0]
  ldxh r4, [r3+0x28]
  jne r4, r2, jmp_2a6a8
  ldxdw r2, [r3+0x8]
  ldxdw r3, [r3+0x0]
  mov64 r4, r3
  add64 r4, -0x1
  jge r4, r2, jmp_2a6b8
  mov64 r4, r2
  and64 r4, r3
  xor64 r2, r3
  rsh64 r2, 0x1
  add64 r4, r2

jmp_2a680:
  stxdw [r1+0x8], r4
  mov64 r2, 0x0
  ja jmp_2a6c8

jmp_2a698:
  stw [r1+0x4], 0x15
  ja jmp_2a6c0

jmp_2a6a8:
  stw [r1+0x4], 0x8
  ja jmp_2a6c0

jmp_2a6b8:
  stw [r1+0x4], 0x5

jmp_2a6c0:
  mov64 r2, 0x1

jmp_2a6c8:
  stxw [r1+0x0], r2
  exit

fn_2a6d8:
  ldxb r5, [r2+0xb8]
  jeq r5, 0x0, jmp_2a758
  ldxh r4, [r2+0xb0]
  ldxh r3, [r3+0x28]
  jne r3, r4, jmp_2a7f8
  ldxdw r3, [r2+0x8]
  ldxdw r2, [r2+0x0]
  mov64 r4, r2
  add64 r4, -0x1
  jge r4, r3, jmp_2a818
  mov64 r4, r3
  and64 r4, r2
  xor64 r3, r2
  rsh64 r3, 0x1
  add64 r4, r3
  ja jmp_2a7e0

jmp_2a758:
  ldxdw r5, [r3+0x18]
  jeq r5, 0x0, jmp_2a808
  ldxdw r5, [r3+0x20]
  jgt r5, r4, jmp_2a808
  ldxh r2, [r2+0xb0]
  ldxh r4, [r3+0x28]
  jne r4, r2, jmp_2a7f8
  ldxdw r2, [r3+0x8]
  ldxdw r3, [r3+0x0]
  mov64 r4, r3
  add64 r4, -0x1
  jge r4, r2, jmp_2a818
  mov64 r4, r2
  and64 r4, r3
  xor64 r2, r3
  rsh64 r2, 0x1
  add64 r4, r2

jmp_2a7e0:
  stxdw [r1+0x8], r4
  mov64 r2, 0x0
  ja jmp_2a828

jmp_2a7f8:
  stw [r1+0x4], 0x8
  ja jmp_2a820

jmp_2a808:
  stw [r1+0x4], 0x15
  ja jmp_2a820

jmp_2a818:
  stw [r1+0x4], 0x5

jmp_2a820:
  mov64 r2, 0x1

jmp_2a828:
  stxw [r1+0x0], r2
  exit

fn_2a838:
  mov64 r0, 0xd
  ldxb r6, [r1+0xbd]
  jne r6, 0x1, jmp_2a990
  mov64 r0, 0x1d
  ldxdw r6, [r1+0xa8]
  jne r4, r6, jmp_2a990
  jeq r2, 0x0, jmp_2a8c0
  mov64 r0, 0x1b
  jeq r5, 0x0, jmp_2a990
  ldxdw r6, [r1+0x50]
  ldxb r7, [r1+0xbb]
  jeq r7, 0x0, jmp_2a8b0
  jge r2, r5, jmp_2a990
  jgt r2, r6, jmp_2a8c0
  ja jmp_2a990

jmp_2a8b0:
  jle r2, r5, jmp_2a990
  jge r2, r6, jmp_2a990

jmp_2a8c0:
  jeq r3, 0x0, jmp_2a960
  mov64 r0, 0x1b
  jeq r5, 0x0, jmp_2a990
  mov64 r6, 0x1
  mov64 r7, 0x1
  jlt r3, r5, jmp_2a920
  jgt r3, r5, jmp_2a930

jmp_2a8f8:
  ldxb r5, [r1+0xbb]
  jeq r5, 0x0, jmp_2a948

jmp_2a908:
  and64 r6, 0x1
  jeq r6, 0x0, jmp_2a960
  ja jmp_2a990

jmp_2a920:
  mov64 r7, 0x0
  jle r3, r5, jmp_2a8f8

jmp_2a930:
  mov64 r6, 0x0
  ldxb r5, [r1+0xbb]
  jne r5, 0x0, jmp_2a908

jmp_2a948:
  mov64 r6, r7
  and64 r6, 0x1
  jne r6, 0x0, jmp_2a990

jmp_2a960:
  jeq r4, -0x1, jmp_2a998
  stxdw [r1+0xa0], r3
  stxdw [r1+0x98], r2
  add64 r4, 0x1
  stxdw [r1+0xa8], r4
  mov64 r0, 0x0

jmp_2a990:
  exit

jmp_2a998:
  mov64 r0, 0x4
  ja jmp_2a990

fn_2a9a8:
  stxdw [r10-0x10], r3
  ldxdw r3, [r5-0xff8]
  ldxdw r6, [r1+0x1b8]
  mov64 r0, r6
  add64 r0, r3
  mov64 r3, 0x1
  mov64 r8, 0x1
  jlt r0, r6, jmp_2a9f0
  mov64 r8, 0x0

jmp_2a9f0:
  mov64 r7, -0x1
  mov64 r6, -0x1
  jne r8, 0x0, jmp_2aa10
  mov64 r6, r0

jmp_2aa10:
  ldxdw r5, [r5-0x1000]
  ldxdw r9, [r1+0x1b0]
  mov64 r0, r9
  add64 r0, r5
  mov64 r8, 0x1
  jge r0, r9, jmp_2acb8
  mov64 r5, -0x1
  jeq r8, 0x0, jmp_2acd0

jmp_2aa50:
  ldxdw r0, [r1+0x198]
  add64 r0, 0x1
  mov64 r8, 0x1
  jne r0, 0x0, jmp_2acf8

jmp_2aa70:
  jne r8, 0x0, jmp_2aa80

jmp_2aa78:
  mov64 r7, r0

jmp_2aa80:
  stxdw [r1+0x198], r7
  stxdw [r1+0x1b0], r5
  stxdw [r1+0x1b8], r6
  ldxdw r5, [r4+0x10]
  ldxdw r0, [r4+0x18]
  mov64 r6, r0
  add64 r6, r5
  mov64 r5, 0x1
  jlt r6, r0, jmp_2aad0
  mov64 r5, 0x0

jmp_2aad0:
  mov64 r0, 0x1
  jlt r6, r2, jmp_2aae8
  mov64 r0, 0x0

jmp_2aae8:
  sub64 r5, r0
  sub64 r6, r2
  ldxdw r8, [r1+0xc0]
  mov64 r0, r8
  add64 r0, r6
  mov64 r7, 0x1
  jlt r0, r8, jmp_2ab28
  mov64 r7, 0x0

jmp_2ab28:
  ldxdw r9, [r1+0xc8]
  mov64 r8, r9
  add64 r8, r5
  add64 r8, r7
  mov64 r7, r9
  xor64 r7, r8
  xor64 r9, r5
  xor64 r9, -0x1
  and64 r9, r7
  mov64 r7, r8
  arsh64 r7, 0x3f
  stxdw [r10-0x8], r2
  jslt r9, 0x0, jmp_2ad10
  jsge r9, 0x0, jmp_2ad38

jmp_2ab98:
  stxdw [r1+0xc0], r7
  stxdw [r1+0xc8], r8
  mov64 r0, 0x1
  jsle r5, 0x0, jmp_2ad60

jmp_2abb8:
  jeq r6, 0x0, jmp_2ad70

jmp_2abc0:
  jne r5, 0x0, jmp_2ad80

jmp_2abc8:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_2ad98

jmp_2abd8:
  ldxdw r2, [r1+0xa0]
  mov64 r7, r2
  add64 r7, r6
  mov64 r0, 0x1
  mov64 r6, 0x1
  jlt r7, r2, jmp_2ac10
  mov64 r6, 0x0

jmp_2ac10:
  ldxdw r2, [r1+0xa8]
  mov64 r9, r2
  add64 r9, r5
  add64 r9, r6
  mov64 r5, 0x1
  jge r9, r2, jmp_2b0e8
  jne r9, r2, jmp_2b0f8

jmp_2ac48:
  mov64 r8, -0x1
  mov64 r5, -0x1
  jeq r6, 0x0, jmp_2b118

jmp_2ac60:
  mov64 r9, -0x1
  jeq r6, 0x0, jmp_2b130

jmp_2ac70:
  ldxdw r2, [r1+0x1a0]
  add64 r2, 0x1
  jne r2, 0x0, jmp_2b150

jmp_2ac88:
  jne r0, 0x0, jmp_2ac98

jmp_2ac90:
  mov64 r8, r2

jmp_2ac98:
  stxdw [r1+0x1a0], r8
  stxdw [r1+0xa0], r9
  stxdw [r1+0xa8], r5
  ja jmp_2ae90

jmp_2acb8:
  mov64 r8, 0x0
  mov64 r5, -0x1
  jne r8, 0x0, jmp_2aa50

jmp_2acd0:
  mov64 r5, r0
  ldxdw r0, [r1+0x198]
  add64 r0, 0x1
  mov64 r8, 0x1
  jeq r0, 0x0, jmp_2aa70

jmp_2acf8:
  mov64 r8, 0x0
  jeq r8, 0x0, jmp_2aa78
  ja jmp_2aa80

jmp_2ad10:
  lddw r2, -0x8000000000000000
  mov64 r8, r7
  xor64 r8, r2
  jslt r9, 0x0, jmp_2ab98

jmp_2ad38:
  mov64 r7, r0
  stxdw [r1+0xc0], r7
  stxdw [r1+0xc8], r8
  mov64 r0, 0x1
  jsgt r5, 0x0, jmp_2abb8

jmp_2ad60:
  mov64 r0, 0x0
  jne r6, 0x0, jmp_2abc0

jmp_2ad70:
  mov64 r3, 0x0
  jeq r5, 0x0, jmp_2abc8

jmp_2ad80:
  mov64 r3, r0
  and64 r3, 0x1
  jne r3, 0x0, jmp_2abd8

jmp_2ad98:
  jsge r5, 0x0, jmp_2ae90
  mov64 r0, 0x1
  mov64 r2, 0x1
  jne r6, 0x0, jmp_2adc0
  mov64 r2, 0x0

jmp_2adc0:
  add64 r5, r2
  ldxdw r8, [r1+0xb8]
  mov64 r7, r8
  sub64 r7, r5
  ldxdw r2, [r1+0xb0]
  mov64 r5, r2
  sub64 r5, r6
  mov64 r9, 0x1
  jge r5, r2, jmp_2b168
  add64 r7, r9
  mov64 r2, 0x1
  jge r7, r8, jmp_2b188

jmp_2ae20:
  jne r7, r8, jmp_2b198

jmp_2ae28:
  mov64 r8, -0x1
  mov64 r6, -0x1
  jeq r9, 0x0, jmp_2b1b8

jmp_2ae40:
  mov64 r7, -0x1
  jeq r9, 0x0, jmp_2b1d0

jmp_2ae50:
  ldxdw r2, [r1+0x1a8]
  add64 r2, 0x1
  jne r2, 0x0, jmp_2b1f0

jmp_2ae68:
  jne r0, 0x0, jmp_2ae78

jmp_2ae70:
  mov64 r8, r2

jmp_2ae78:
  stxdw [r1+0x1a8], r8
  stxdw [r1+0xb0], r7
  stxdw [r1+0xb8], r6

jmp_2ae90:
  ldxdw r2, [r4+0x28]
  ldxdw r6, [r1+0xd0]
  mov64 r7, r6
  add64 r7, r2
  mov64 r0, 0x0
  mov64 r5, 0x1
  mov64 r8, 0x1
  jlt r7, r6, jmp_2aed8
  mov64 r8, 0x0

jmp_2aed8:
  ldxdw r3, [r1+0xd8]
  mov64 r9, r3
  add64 r9, r8
  mov64 r2, 0x1
  jge r9, r3, jmp_2b028
  jlt r7, r6, jmp_2b038

jmp_2af08:
  mov64 r6, -0x1
  mov64 r2, -0x1
  ldxdw r3, [r10-0x8]
  jeq r8, 0x0, jmp_2b060

jmp_2af28:
  stxdw [r1+0xd0], r2
  mov64 r2, -0x1
  jne r8, 0x0, jmp_2af48

jmp_2af40:
  mov64 r2, r9

jmp_2af48:
  stxdw [r1+0xd8], r2
  ldxdw r2, [r4+0x30]
  ldxdw r8, [r1+0xe0]
  mov64 r4, r8
  add64 r4, r2
  ldxdw r9, [r1+0xe8]
  mov64 r7, 0x1
  jge r4, r8, jmp_2b088
  mov64 r2, r9
  add64 r2, r7
  jge r2, r9, jmp_2b0a8

jmp_2afa0:
  jlt r4, r8, jmp_2b0b8

jmp_2afa8:
  mov64 r5, -0x1
  jeq r7, 0x0, jmp_2b0d0

jmp_2afb8:
  jne r7, 0x0, jmp_2afc8

jmp_2afc0:
  mov64 r6, r4

jmp_2afc8:
  stxdw [r1+0xe0], r6
  stxdw [r1+0xe8], r5
  ldxdw r2, [r10-0x10]
  and64 r2, 0x1
  jne r2, 0x0, jmp_2b020
  mov64 r0, 0x2
  ldxdw r2, [r1+0x178]
  jlt r2, r3, jmp_2b020
  sub64 r2, r3
  stxdw [r1+0x178], r2
  mov64 r0, 0x0

jmp_2b020:
  exit

jmp_2b028:
  mov64 r2, 0x0
  jge r7, r6, jmp_2af08

jmp_2b038:
  mov64 r8, r2
  mov64 r6, -0x1
  mov64 r2, -0x1
  ldxdw r3, [r10-0x8]
  jne r8, 0x0, jmp_2af28

jmp_2b060:
  mov64 r2, r7
  stxdw [r1+0xd0], r2
  mov64 r2, -0x1
  jeq r8, 0x0, jmp_2af40
  ja jmp_2af48

jmp_2b088:
  mov64 r7, 0x0
  mov64 r2, r9
  add64 r2, r7
  jlt r2, r9, jmp_2afa0

jmp_2b0a8:
  mov64 r5, 0x0
  jge r4, r8, jmp_2afa8

jmp_2b0b8:
  mov64 r7, r5
  mov64 r5, -0x1
  jne r7, 0x0, jmp_2afb8

jmp_2b0d0:
  mov64 r5, r2
  jeq r7, 0x0, jmp_2afc0
  ja jmp_2afc8

jmp_2b0e8:
  mov64 r5, 0x0
  jeq r9, r2, jmp_2ac48

jmp_2b0f8:
  mov64 r6, r5
  mov64 r8, -0x1
  mov64 r5, -0x1
  jne r6, 0x0, jmp_2ac60

jmp_2b118:
  mov64 r5, r9
  mov64 r9, -0x1
  jne r6, 0x0, jmp_2ac70

jmp_2b130:
  mov64 r9, r7
  ldxdw r2, [r1+0x1a0]
  add64 r2, 0x1
  jeq r2, 0x0, jmp_2ac88

jmp_2b150:
  mov64 r0, 0x0
  jeq r0, 0x0, jmp_2ac90
  ja jmp_2ac98

jmp_2b168:
  mov64 r9, 0x0
  add64 r7, r9
  mov64 r2, 0x1
  jlt r7, r8, jmp_2ae20

jmp_2b188:
  mov64 r2, 0x0
  jeq r7, r8, jmp_2ae28

jmp_2b198:
  mov64 r9, r2
  mov64 r8, -0x1
  mov64 r6, -0x1
  jne r9, 0x0, jmp_2ae40

jmp_2b1b8:
  mov64 r6, r7
  mov64 r7, -0x1
  jne r9, 0x0, jmp_2ae50

jmp_2b1d0:
  mov64 r7, r5
  ldxdw r2, [r1+0x1a8]
  add64 r2, 0x1
  jeq r2, 0x0, jmp_2ae68

jmp_2b1f0:
  mov64 r0, 0x0
  jeq r0, 0x0, jmp_2ae70
  ja jmp_2ae78

fn_2b208:
  jgt r3, 0x7, jmp_2b228

jmp_2b210:
  stw [r1+0x4], 0x1
  mov64 r2, 0x1
  ja jmp_2b690

jmp_2b228:
  ldxdw r4, [r2+0x0]
  jne r3, 0xac, jmp_2b258
  lddw r5, 0x3330304c4f505443
  jeq r4, r5, jmp_2b278
  ja jmp_2b430

jmp_2b258:
  jne r3, 0xb2, jmp_2b430
  lddw r5, 0x3430304c4f505443
  jne r4, r5, jmp_2b430

jmp_2b278:
  ldxb r6, [r2+0x8a]
  ldxh r4, [r2+0x88]
  stxdw [r10-0xa0], r4
  ldxb r5, [r2+0x62]
  ldxh r4, [r2+0x60]
  stxdw [r10-0xa8], r4
  ldxw r0, [r2+0x63]
  ldxw r7, [r2+0x8b]
  ldxb r8, [r2+0x97]
  ldxdw r9, [r2+0x8f]
  ldxb r4, [r2+0x6f]
  stxdw [r10-0x8], r4
  ldxdw r4, [r2+0x67]
  stxdw [r10-0x98], r4
  ldxdw r4, [r2+0xa4]
  stxdw [r10-0x18], r4
  ldxw r4, [r2+0xa0]
  stxdw [r10-0x90], r4
  ldxdw r4, [r2+0x98]
  stxdw [r10-0x88], r4
  ldxdw r4, [r2+0x80]
  stxdw [r10-0x80], r4
  ldxdw r4, [r2+0x78]
  stxdw [r10-0x78], r4
  ldxdw r4, [r2+0x70]
  stxdw [r10-0x70], r4
  ldxdw r4, [r2+0x58]
  stxdw [r10-0x68], r4
  ldxdw r4, [r2+0x50]
  stxdw [r10-0x60], r4
  ldxdw r4, [r2+0x48]
  stxdw [r10-0x58], r4
  ldxdw r4, [r2+0x40]
  stxdw [r10-0x50], r4
  ldxdw r4, [r2+0x38]
  stxdw [r10-0x48], r4
  ldxdw r4, [r2+0x30]
  stxdw [r10-0x40], r4
  ldxdw r4, [r2+0x28]
  stxdw [r10-0x38], r4
  ldxdw r4, [r2+0x20]
  stxdw [r10-0x30], r4
  ldxdw r4, [r2+0x18]
  stxdw [r10-0x28], r4
  ldxdw r4, [r2+0x10]
  stxdw [r10-0x20], r4
  ldxdw r4, [r2+0x8]
  stxdw [r10-0x10], r4
  jne r3, 0xac, jmp_2b448
  stxdw [r10-0xb0], r8
  mov64 r8, 0xac
  mov64 r2, 0x0
  mov64 r4, 0x0
  jne r8, r3, jmp_2b210
  ja jmp_2b478

jmp_2b430:
  stw [r1+0x4], 0x2
  mov64 r2, 0x1
  ja jmp_2b690

jmp_2b448:
  jlt r3, 0xb2, jmp_2b210
  stxdw [r10-0xb0], r8
  mov64 r8, 0xb2
  ldxw r4, [r2+0xae]
  ldxh r2, [r2+0xac]
  jne r8, r3, jmp_2b210

jmp_2b478:
  lsh64 r6, 0x10
  ldxdw r3, [r10-0xa0]
  or64 r3, r6
  lsh64 r5, 0x10
  mov64 r8, r4
  ldxdw r4, [r10-0xa8]
  or64 r4, r5
  lsh64 r0, 0x18
  or64 r0, r4
  lsh64 r7, 0x18
  or64 r7, r3
  ldxdw r4, [r10-0xb0]
  lsh64 r4, 0x38
  mov64 r3, r9
  rsh64 r3, 0x8
  or64 r4, r3
  ldxdw r5, [r10-0x8]
  lsh64 r5, 0x38
  ldxdw r6, [r10-0x98]
  mov64 r3, r6
  rsh64 r3, 0x8
  or64 r5, r3
  lsh64 r9, 0x38
  or64 r7, r9
  lsh64 r6, 0x38
  or64 r0, r6
  stxdw [r1+0x18], r7
  stxdw [r1+0x8], r0
  stxh [r1+0xb0], r2
  stxw [r1+0xac], r8
  ldxdw r2, [r10-0x90]
  stxw [r1+0xa8], r2
  ldxdw r2, [r10-0x18]
  stxdw [r1+0xa0], r2
  ldxdw r2, [r10-0x88]
  stxdw [r1+0x98], r2
  ldxdw r2, [r10-0x80]
  stxdw [r1+0x90], r2
  ldxdw r2, [r10-0x78]
  stxdw [r1+0x88], r2
  ldxdw r2, [r10-0x70]
  stxdw [r1+0x80], r2
  ldxdw r2, [r10-0x68]
  stxdw [r1+0x78], r2
  ldxdw r2, [r10-0x60]
  stxdw [r1+0x70], r2
  ldxdw r2, [r10-0x58]
  stxdw [r1+0x68], r2
  ldxdw r2, [r10-0x50]
  stxdw [r1+0x60], r2
  ldxdw r2, [r10-0x48]
  stxdw [r1+0x58], r2
  ldxdw r2, [r10-0x40]
  stxdw [r1+0x50], r2
  ldxdw r2, [r10-0x38]
  stxdw [r1+0x48], r2
  ldxdw r2, [r10-0x30]
  stxdw [r1+0x40], r2
  ldxdw r2, [r10-0x28]
  stxdw [r1+0x38], r2
  ldxdw r2, [r10-0x20]
  stxdw [r1+0x30], r2
  ldxdw r2, [r10-0x10]
  stxdw [r1+0x28], r2
  stxdw [r1+0x20], r4
  stxdw [r1+0x10], r5
  mov64 r2, 0x0

jmp_2b690:
  stxw [r1+0x0], r2
  exit

fn_2b6a0:
  mov64 r0, 0x2
  jne r3, 0xac, jmp_2b6e8
  ldxh r4, [r1+0xa8]
  jne r4, 0x0, jmp_2b888
  lddw r4, 0x3330304c4f505443
  ldxw r5, [r1+0xa4]
  jeq r5, 0x0, jmp_2b700
  ja jmp_2b888

jmp_2b6e8:
  lddw r4, 0x3430304c4f505443
  jne r3, 0xb2, jmp_2b888

jmp_2b700:
  stxdw [r2+0x0], r4
  ldxdw r4, [r1+0x20]
  stxdw [r2+0x8], r4
  ldxdw r4, [r1+0x28]
  stxdw [r2+0x10], r4
  ldxdw r4, [r1+0x30]
  stxdw [r2+0x18], r4
  ldxdw r4, [r1+0x38]
  stxdw [r2+0x20], r4
  ldxdw r4, [r1+0x40]
  stxdw [r2+0x28], r4
  ldxdw r4, [r1+0x48]
  stxdw [r2+0x30], r4
  ldxdw r4, [r1+0x50]
  stxdw [r2+0x38], r4
  ldxdw r4, [r1+0x58]
  stxdw [r2+0x40], r4
  ldxdw r4, [r1+0x60]
  stxdw [r2+0x48], r4
  ldxdw r4, [r1+0x68]
  stxdw [r2+0x50], r4
  ldxdw r4, [r1+0x70]
  stxdw [r2+0x58], r4
  ldxdw r4, [r1+0x0]
  ldxdw r5, [r1+0x8]
  stxdw [r2+0x68], r5
  stxdw [r2+0x60], r4
  ldxdw r4, [r1+0x78]
  stxdw [r2+0x70], r4
  ldxdw r4, [r1+0x80]
  stxdw [r2+0x78], r4
  ldxdw r4, [r1+0x88]
  stxdw [r2+0x80], r4
  ldxdw r4, [r1+0x10]
  ldxdw r5, [r1+0x18]
  stxdw [r2+0x90], r5
  stxdw [r2+0x88], r4
  ldxdw r4, [r1+0x90]
  stxdw [r2+0x98], r4
  ldxw r4, [r1+0xa0]
  stxw [r2+0xa0], r4
  ldxdw r4, [r1+0x98]
  stxdw [r2+0xa4], r4
  mov64 r0, 0x0
  jeq r3, 0xac, jmp_2b888
  ldxh r3, [r1+0xa8]
  stxh [r2+0xac], r3
  ldxw r1, [r1+0xa4]
  stxw [r2+0xae], r1

jmp_2b888:
  exit

fn_2b890:
  mov64 r0, 0x2
  jne r3, 0x1d2, jmp_2bc70
  lddw r3, 0x3430305253555443
  stxdw [r2+0x0], r3
  ldxdw r3, [r1+0x0]
  stxdw [r2+0x8], r3
  ldxdw r3, [r1+0x8]
  stxdw [r2+0x10], r3
  ldxdw r3, [r1+0x10]
  stxdw [r2+0x18], r3
  ldxdw r3, [r1+0x18]
  stxdw [r2+0x20], r3
  ldxdw r3, [r1+0x130]
  stxdw [r2+0x28], r3
  ldxdw r3, [r1+0x138]
  stxdw [r2+0x30], r3
  ldxdw r3, [r1+0x140]
  stxdw [r2+0x38], r3
  ldxdw r3, [r1+0x20]
  stxdw [r2+0x40], r3
  ldxdw r3, [r1+0x28]
  stxdw [r2+0x48], r3
  ldxdw r3, [r1+0x30]
  stxdw [r2+0x50], r3
  ldxdw r3, [r1+0x38]
  stxdw [r2+0x58], r3
  ldxdw r3, [r1+0x148]
  stxdw [r2+0x60], r3
  ldxdw r3, [r1+0x150]
  stxdw [r2+0x68], r3
  ldxdw r3, [r1+0x158]
  stxdw [r2+0x70], r3
  ldxdw r3, [r1+0x160]
  stxdw [r2+0x78], r3
  ldxdw r3, [r1+0x60]
  ldxdw r4, [r1+0x68]
  stxdw [r2+0x88], r4
  stxdw [r2+0x80], r3
  ldxdw r3, [r1+0x168]
  stxdw [r2+0x90], r3
  ldxdw r3, [r1+0x170]
  stxdw [r2+0x98], r3
  ldxb r3, [r1+0x1c8]
  stxb [r2+0xa0], r3
  ldxb r3, [r1+0x1c9]
  stxb [r2+0xa1], r3
  ldxdw r3, [r1+0x178]
  stxdw [r2+0xa2], r3
  ldxdw r3, [r1+0x70]
  ldxdw r4, [r1+0x78]
  stxdw [r2+0xb2], r4
  stxdw [r2+0xaa], r3
  ldxdw r3, [r1+0x180]
  stxdw [r2+0xba], r3
  ldxdw r3, [r1+0x188]
  stxdw [r2+0xc2], r3
  ldxdw r3, [r1+0x190]
  stxdw [r2+0xca], r3
  ldxdw r3, [r1+0x198]
  stxdw [r2+0xd2], r3
  ldxdw r3, [r1+0x1a0]
  stxdw [r2+0xda], r3
  ldxdw r3, [r1+0x1a8]
  stxdw [r2+0xe2], r3
  ldxdw r3, [r1+0x1b0]
  stxdw [r2+0xea], r3
  ldxdw r3, [r1+0x1b8]
  stxdw [r2+0xf2], r3
  ldxdw r3, [r1+0x80]
  ldxdw r4, [r1+0x88]
  stxdw [r2+0x102], r4
  stxdw [r2+0xfa], r3
  ldxdw r3, [r1+0x90]
  ldxdw r4, [r1+0x98]
  stxdw [r2+0x112], r4
  stxdw [r2+0x10a], r3
  ldxdw r3, [r1+0xa0]
  ldxdw r4, [r1+0xa8]
  stxdw [r2+0x122], r4
  stxdw [r2+0x11a], r3
  ldxdw r3, [r1+0xb0]
  ldxdw r4, [r1+0xb8]
  stxdw [r2+0x132], r4
  stxdw [r2+0x12a], r3
  ldxdw r3, [r1+0xc0]
  ldxdw r4, [r1+0xc8]
  stxdw [r2+0x142], r4
  stxdw [r2+0x13a], r3
  ldxdw r3, [r1+0xd0]
  ldxdw r4, [r1+0xd8]
  stxdw [r2+0x152], r4
  stxdw [r2+0x14a], r3
  ldxdw r3, [r1+0xe0]
  ldxdw r4, [r1+0xe8]
  stxdw [r2+0x162], r4
  stxdw [r2+0x15a], r3
  ldxdw r3, [r1+0x1c0]
  stxdw [r2+0x16a], r3
  ldxdw r3, [r1+0x58]
  stxdw [r2+0x18a], r3
  ldxdw r3, [r1+0x50]
  stxdw [r2+0x182], r3
  ldxdw r3, [r1+0x48]
  stxdw [r2+0x17a], r3
  ldxdw r3, [r1+0x40]
  stxdw [r2+0x172], r3
  ldxdw r3, [r1+0xf0]
  stxdw [r2+0x192], r3
  ldxdw r3, [r1+0xf8]
  stxdw [r2+0x19a], r3
  ldxdw r3, [r1+0x100]
  ldxdw r4, [r1+0x108]
  stxdw [r2+0x1aa], r4
  stxdw [r2+0x1a2], r3
  ldxdw r3, [r1+0x110]
  ldxdw r4, [r1+0x118]
  stxdw [r2+0x1ba], r4
  stxdw [r2+0x1b2], r3
  ldxdw r3, [r1+0x120]
  ldxdw r1, [r1+0x128]
  stxdw [r2+0x1ca], r1
  stxdw [r2+0x1c2], r3
  mov64 r0, 0x0

jmp_2bc70:
  exit

fn_2bc78:
  mov64 r1, r3
  call fn_2bc88

fn_2bc88:
  call fn_24920

fn_2bc90:
  call fn_2bc98

fn_2bc98:
  lddw r1, data_0788
  call fn_2bc88

fn_2bcb0:
  mov64 r1, r3
  call fn_2bc88

fn_2bcc0:
  lddw r1, data_0978
  call fn_2bc88

fn_2bcd8:
  call fn_2bce0

fn_2bce0:
  lddw r1, data_0770
  call fn_2bc88

fn_2bcf8:
  call fn_2bc88

fn_2bd00:
  mov64 r0, r2
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jsgt r1, 0xc, jmp_2bd58
  jsle r1, 0x5, jmp_2bd90
  jsle r1, 0x8, jmp_2be00
  jsgt r1, 0xa, jmp_2bea0
  jne r1, 0x9, jmp_2bfb8
  lddw r0, 0xa00000000
  ja jmp_2c058

jmp_2bd58:
  jsle r1, 0x12, jmp_2bdd0
  jsle r1, 0x15, jmp_2be28
  jsgt r1, 0x17, jmp_2bec0
  jne r1, 0x16, jmp_2bfd0
  lddw r0, 0x1700000000
  ja jmp_2c058

jmp_2bd90:
  jsgt r1, 0x2, jmp_2be50
  jeq r1, 0x0, jmp_2bf10
  lddw r0, 0x200000000
  jeq r1, 0x1, jmp_2c058
  lddw r0, 0x300000000
  ja jmp_2c058

jmp_2bdd0:
  jsgt r1, 0xf, jmp_2be78
  jeq r1, 0xd, jmp_2bf40
  jne r1, 0xe, jmp_2c018
  lddw r0, 0xf00000000
  ja jmp_2c058

jmp_2be00:
  jeq r1, 0x6, jmp_2bee0
  jne r1, 0x7, jmp_2bf88
  lddw r0, 0x800000000
  ja jmp_2c058

jmp_2be28:
  jeq r1, 0x13, jmp_2bef8
  jne r1, 0x14, jmp_2bfa0
  lddw r0, 0x1500000000
  ja jmp_2c058

jmp_2be50:
  jeq r1, 0x3, jmp_2bf58
  jne r1, 0x4, jmp_2c030
  lddw r0, 0x500000000
  ja jmp_2c058

jmp_2be78:
  jeq r1, 0x10, jmp_2bf70
  jne r1, 0x11, jmp_2c048
  lddw r0, 0x1200000000
  ja jmp_2c058

jmp_2bea0:
  jne r1, 0xb, jmp_2bfe8
  lddw r0, 0xc00000000
  ja jmp_2c058

jmp_2bec0:
  jne r1, 0x18, jmp_2c000
  lddw r0, 0x1900000000
  ja jmp_2c058

jmp_2bee0:
  lddw r0, 0x700000000
  ja jmp_2c058

jmp_2bef8:
  lddw r0, 0x1400000000
  ja jmp_2c058

jmp_2bf10:
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  jne r0, 0x0, jmp_2c058
  lddw r0, 0x100000000
  ja jmp_2c058

jmp_2bf40:
  lddw r0, 0xe00000000
  ja jmp_2c058

jmp_2bf58:
  lddw r0, 0x400000000
  ja jmp_2c058

jmp_2bf70:
  lddw r0, 0x1100000000
  ja jmp_2c058

jmp_2bf88:
  lddw r0, 0x900000000
  ja jmp_2c058

jmp_2bfa0:
  lddw r0, 0x1600000000
  ja jmp_2c058

jmp_2bfb8:
  lddw r0, 0xb00000000
  ja jmp_2c058

jmp_2bfd0:
  lddw r0, 0x1800000000
  ja jmp_2c058

jmp_2bfe8:
  lddw r0, 0xd00000000
  ja jmp_2c058

jmp_2c000:
  lddw r0, 0x1a00000000
  ja jmp_2c058

jmp_2c018:
  lddw r0, 0x1000000000
  ja jmp_2c058

jmp_2c030:
  lddw r0, 0x600000000
  ja jmp_2c058

jmp_2c048:
  lddw r0, 0x1300000000

jmp_2c058:
  exit

fn_2c060:
  mov64 r6, r1
  call sol_memcpy_
  mov64 r0, r6
  exit

fn_2c080:
  mov64 r6, r1
  and64 r2, 0xff
  call sol_memset_
  mov64 r0, r6
  exit

fn_2c0a8:
  mov64 r0, r1
  mov64 r1, r3
  and64 r1, 0x40
  jne r1, 0x0, jmp_2c120
  jeq r3, 0x0, jmp_2c140
  mov64 r1, r3
  and64 r1, 0x3f
  lsh64 r2, r1
  neg64 r3
  and64 r3, 0x3f
  mov64 r4, r0
  rsh64 r4, r3
  or64 r2, r4
  lsh64 r0, r1
  ja jmp_2c140

jmp_2c120:
  and64 r3, 0x3f
  mov64 r2, r0
  lsh64 r2, r3
  mov64 r0, 0x0

jmp_2c140:
  mov64 r1, r2
  exit

fn_2c150:
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
  jlt r9, r6, jmp_2c200
  mov64 r8, 0x0

jmp_2c200:
  mov64 r6, r9
  lsh64 r6, 0x20
  mov64 r7, r0
  add64 r7, r6
  jlt r7, r0, jmp_2c230
  mov64 r2, 0x0

jmp_2c230:
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

fn_2c2a8:
  mov64 r5, r4
  mov64 r4, r3
  mov64 r3, r2
  mov64 r2, r1
  mov64 r1, r10
  add64 r1, -0x20
  call fn_2c2f8
  ldxdw r1, [r10-0x18]
  ldxdw r0, [r10-0x20]
  exit

fn_2c2f8:
  stxdw [r10-0x8], r5
  stxdw [r10-0x10], r4
  mov64 r9, r2
  mov64 r6, r1
  lddw r4, 0x5555555555555555
  lddw r8, 0x3333333333333333
  lddw r2, 0xf0f0f0f0f0f0f0f
  lddw r1, 0x101010101010101
  stxdw [r10-0x18], r3
  jne r3, 0x0, jmp_2c668
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
  jeq r5, 0x0, jmp_2c790

jmp_2c498:
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
  jgt r5, r7, jmp_2c8b8

jmp_2c5b0:
  mov64 r8, 0x0
  mov64 r3, 0x1
  mov64 r1, 0x1
  ldxdw r4, [r10-0x10]
  jlt r9, r4, jmp_2c920
  mov64 r1, 0x0
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jge r2, r5, jmp_2c938

jmp_2c5f8:
  jeq r2, r5, jmp_2c948

jmp_2c600:
  mov64 r1, r3
  and64 r1, 0x1
  jne r1, 0x0, jmp_2c958

jmp_2c618:
  sub64 r2, r5
  mov64 r3, 0x0
  mov64 r8, 0x1
  mov64 r1, 0x1
  jlt r9, r4, jmp_2c648

jmp_2c640:
  mov64 r1, 0x0

jmp_2c648:
  sub64 r2, r1
  sub64 r9, r4
  mov64 r0, r9
  ja jmp_2ca98

jmp_2c668:
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
  jne r5, 0x0, jmp_2c498

jmp_2c790:
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
  jle r5, r7, jmp_2c5b0

jmp_2c8b8:
  mov64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  jle r1, 0x3f, jmp_2c970
  mov64 r8, r9
  ldxdw r2, [r10-0x10]
  div64 r8, r2
  mov64 r1, r8
  mul64 r1, r2
  sub64 r9, r1
  mov64 r3, 0x0
  mov64 r0, r9
  ja jmp_2ca90

jmp_2c920:
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jlt r2, r5, jmp_2c5f8

jmp_2c938:
  mov64 r3, 0x0
  jne r2, r5, jmp_2c600

jmp_2c948:
  and64 r1, 0x1
  jeq r1, 0x0, jmp_2c618

jmp_2c958:
  mov64 r3, 0x0
  mov64 r0, r9
  ja jmp_2ca98

jmp_2c970:
  mov64 r1, r5
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  stxdw [r10-0x48], r1
  jle r1, 0x5f, jmp_2cac0
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

jmp_2ca90:
  mov64 r2, 0x0

jmp_2ca98:
  stxdw [r6+0x10], r0
  stxdw [r6+0x0], r8
  stxdw [r6+0x18], r2
  stxdw [r6+0x8], r3
  exit

jmp_2cac0:
  mov64 r1, r5
  sub64 r1, r7
  lsh64 r1, 0x20
  rsh64 r1, 0x20
  stxdw [r10-0x50], r6
  jge r1, 0x20, jmp_2cd08
  mov64 r6, 0x40
  sub64 r6, r7
  lsh64 r6, 0x20
  rsh64 r6, 0x20
  ldxdw r7, [r10-0x10]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r3, r6
  call fn_2d6e0
  stxdw [r10-0x20], r0
  mov64 r1, r9
  ldxdw r2, [r10-0x18]
  mov64 r3, r6
  call fn_2d6e0
  mov64 r8, r0
  ldxdw r1, [r10-0x20]
  div64 r8, r1
  mov64 r1, r7
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  stxdw [r10-0x20], r0
  mov64 r6, r1
  ldxdw r1, [r10-0x8]
  mov64 r2, 0x0
  mov64 r3, r8
  mov64 r4, 0x0
  call fn_2c150
  mov64 r3, 0x1
  mov64 r4, r6
  add64 r4, r0
  jlt r4, r6, jmp_2cc00
  mov64 r3, 0x0

jmp_2cc00:
  add64 r1, r3
  ldxdw r6, [r10-0x50]
  ldxdw r2, [r10-0x18]
  ldxdw r5, [r10-0x8]
  jne r1, 0x0, jmp_2cc78
  mov64 r3, 0x1
  mov64 r1, 0x1
  ldxdw r0, [r10-0x20]
  jlt r9, r0, jmp_2d2c8
  mov64 r1, 0x0
  jge r2, r4, jmp_2d2d0

jmp_2cc58:
  jeq r2, r4, jmp_2d2e0

jmp_2cc60:
  mov64 r1, r3
  and64 r1, 0x1
  jeq r1, 0x0, jmp_2d2f0

jmp_2cc78:
  add64 r5, r2
  mov64 r0, r7
  add64 r0, r9
  mov64 r1, 0x1
  mov64 r3, 0x1
  jlt r0, r7, jmp_2ccb0
  mov64 r3, 0x0

jmp_2ccb0:
  add64 r5, r3
  sub64 r5, r4
  ldxdw r2, [r10-0x20]
  jlt r0, r2, jmp_2ccd8
  mov64 r1, 0x0

jmp_2ccd8:
  sub64 r5, r1
  sub64 r0, r2
  add64 r8, -0x1
  mov64 r2, r5
  mov64 r3, 0x0
  ja jmp_2ca98

jmp_2cd08:
  mov64 r1, 0x60
  sub64 r1, r5
  stxdw [r10-0x60], r1
  mov64 r3, r1
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  ldxdw r1, [r10-0x10]
  ldxdw r2, [r10-0x8]
  stxdw [r10-0x58], r3
  call fn_2d6e0
  mov64 r4, 0x0
  lsh64 r0, 0x20
  rsh64 r0, 0x20
  add64 r0, 0x1
  stxdw [r10-0x68], r0
  mov64 r1, 0x0
  stxdw [r10-0x28], r1
  mov64 r0, r9
  ldxdw r2, [r10-0x18]

jmp_2cda0:
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
  call fn_2d6e0
  ldxdw r1, [r10-0x58]
  stxdw [r10-0x20], r9
  jlt r6, r1, jmp_2d320
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
  call fn_2c150
  mov64 r2, r1
  rsh64 r8, 0x20
  mov64 r1, r0
  mov64 r3, r8
  call fn_2c0a8
  mov64 r6, r0
  stxdw [r10-0x40], r1
  mov64 r7, 0x1
  jlt r9, r6, jmp_2ceb8
  mov64 r7, 0x0

jmp_2ceb8:
  ldxdw r1, [r10-0x38]
  mov64 r2, 0x0
  mov64 r3, r8
  call fn_2c0a8
  mov64 r5, r0
  ldxdw r2, [r10-0x30]
  add64 r5, r2
  mov64 r8, 0x1
  jlt r5, r0, jmp_2cf08
  mov64 r8, 0x0

jmp_2cf08:
  ldxdw r2, [r10-0x18]
  ldxdw r3, [r10-0x40]
  sub64 r2, r3
  sub64 r2, r7
  ldxdw r0, [r10-0x20]
  sub64 r0, r6
  jne r2, 0x0, jmp_2d0a8
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
  ja jmp_2d200

jmp_2d0a8:
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

jmp_2d200:
  ldxdw r6, [r10-0x50]
  ldxdw r3, [r10-0x28]
  add64 r1, r3
  add64 r1, r8
  ldxdw r3, [r10-0x48]
  jle r3, r7, jmp_2d588
  mov64 r3, r7
  lsh64 r3, 0x20
  rsh64 r3, 0x20
  mov64 r4, r5
  stxdw [r10-0x28], r1
  jle r3, 0x3f, jmp_2cda0
  ldxdw r4, [r10-0x10]
  jeq r4, 0x0, jmp_2d6d8
  mov64 r3, r0
  div64 r3, r4

jmp_2d280:
  mov64 r8, r5
  add64 r8, r3
  mov64 r2, 0x0
  mov64 r3, 0x1
  jlt r8, r5, jmp_2d2b0
  mov64 r3, 0x0

jmp_2d2b0:
  mod64 r0, r4
  add64 r1, r3
  ja jmp_2d668

jmp_2d2c8:
  jlt r2, r4, jmp_2cc58

jmp_2d2d0:
  mov64 r3, 0x0
  jne r2, r4, jmp_2cc60

jmp_2d2e0:
  and64 r1, 0x1
  jne r1, 0x0, jmp_2cc78

jmp_2d2f0:
  sub64 r2, r4
  mov64 r3, 0x0
  mov64 r1, 0x1
  ldxdw r4, [r10-0x20]
  jge r9, r4, jmp_2c640
  ja jmp_2c648

jmp_2d320:
  mov64 r8, r0
  ldxdw r7, [r10-0x10]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r3, r6
  call fn_2d6e0
  jeq r0, 0x0, jmp_2d6d0
  div64 r8, r0
  mov64 r3, r8

jmp_2d368:
  ldxdw r6, [r10-0x50]
  mov64 r1, r7
  ldxdw r2, [r10-0x8]
  mov64 r9, r3
  mov64 r4, 0x0
  call fn_2c150
  mov64 r3, 0x1
  mov64 r4, 0x1
  ldxdw r2, [r10-0x20]
  jlt r2, r0, jmp_2d488
  mov64 r4, 0x0
  ldxdw r2, [r10-0x18]
  jge r2, r1, jmp_2d498

jmp_2d3d0:
  ldxdw r5, [r10-0x8]
  jeq r2, r1, jmp_2d4b0

jmp_2d3e0:
  mov64 r4, r3
  and64 r4, 0x1
  jne r4, 0x0, jmp_2d4c0

jmp_2d3f8:
  ldxdw r5, [r10-0x30]
  mov64 r8, r5
  add64 r8, r9
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r8, r5, jmp_2d430
  mov64 r4, 0x0

jmp_2d430:
  ldxdw r5, [r10-0x20]
  jlt r5, r0, jmp_2d448
  mov64 r3, 0x0

jmp_2d448:
  sub64 r2, r1
  sub64 r2, r3
  ldxdw r1, [r10-0x20]
  sub64 r1, r0
  mov64 r0, r1
  ldxdw r3, [r10-0x28]
  add64 r3, r4
  ja jmp_2ca98

jmp_2d488:
  ldxdw r2, [r10-0x18]
  jlt r2, r1, jmp_2d3d0

jmp_2d498:
  mov64 r3, 0x0
  ldxdw r5, [r10-0x8]
  jne r2, r1, jmp_2d3e0

jmp_2d4b0:
  and64 r4, 0x1
  jeq r4, 0x0, jmp_2d3f8

jmp_2d4c0:
  add64 r2, r5
  ldxdw r8, [r10-0x20]
  mov64 r5, r8
  add64 r5, r7
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r5, r8, jmp_2d500
  mov64 r4, 0x0

jmp_2d500:
  add64 r2, r4
  ldxdw r7, [r10-0x30]
  add64 r9, r7
  add64 r9, -0x1
  mov64 r4, 0x1
  mov64 r8, r9
  jlt r9, r7, jmp_2d540
  mov64 r4, 0x0

jmp_2d540:
  sub64 r2, r1
  jlt r5, r0, jmp_2d558
  mov64 r3, 0x0

jmp_2d558:
  sub64 r2, r3
  sub64 r5, r0
  ldxdw r3, [r10-0x28]
  add64 r3, r4
  mov64 r0, r5
  ja jmp_2ca98

jmp_2d588:
  mov64 r4, 0x1
  mov64 r3, 0x1
  mov64 r7, r0
  ldxdw r0, [r10-0x10]
  mov64 r9, r7
  jlt r7, r0, jmp_2d678
  mov64 r3, 0x0
  ldxdw r7, [r10-0x8]
  jge r2, r7, jmp_2d688

jmp_2d5d0:
  ldxdw r7, [r10-0x8]
  jeq r2, r7, jmp_2d6a0

jmp_2d5e0:
  mov64 r3, r4
  and64 r3, 0x1
  jne r3, 0x0, jmp_2d6b0

jmp_2d5f8:
  mov64 r3, 0x1
  mov64 r4, 0x1
  jlt r9, r0, jmp_2d618
  mov64 r4, 0x0

jmp_2d618:
  ldxdw r7, [r10-0x8]
  sub64 r2, r7
  add64 r5, 0x1
  jeq r5, 0x0, jmp_2d640
  mov64 r3, 0x0

jmp_2d640:
  sub64 r2, r4
  add64 r1, r3
  sub64 r9, r0
  mov64 r0, r9
  mov64 r8, r5

jmp_2d668:
  mov64 r3, r1
  ja jmp_2ca98

jmp_2d678:
  ldxdw r7, [r10-0x8]
  jlt r2, r7, jmp_2d5d0

jmp_2d688:
  mov64 r4, 0x0
  ldxdw r7, [r10-0x8]
  jne r2, r7, jmp_2d5e0

jmp_2d6a0:
  and64 r3, 0x1
  jeq r3, 0x0, jmp_2d5f8

jmp_2d6b0:
  mov64 r8, r5
  mov64 r3, r1
  mov64 r0, r9
  ja jmp_2ca98

jmp_2d6d0:
  ja jmp_2d368

jmp_2d6d8:
  ja jmp_2d280

fn_2d6e0:
  mov64 r0, r1
  mov64 r1, r3
  and64 r1, 0x40
  jne r1, 0x0, jmp_2d760
  jeq r3, 0x0, jmp_2d780
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
  ja jmp_2d780

jmp_2d760:
  and64 r3, 0x3f
  rsh64 r2, r3
  mov64 r0, r2
  mov64 r2, 0x0

jmp_2d780:
  mov64 r1, r2
  exit

fn_2d790:
  mov64 r7, r4
  mov64 r5, r3
  mov64 r6, r2
  mov64 r2, r1
  neg64 r2
  jslt r6, 0x0, jmp_2d7c8
  mov64 r2, r1

jmp_2d7c8:
  mov64 r8, 0x1
  mov64 r4, 0x1
  jne r1, 0x0, jmp_2d7e8
  mov64 r4, 0x0

jmp_2d7e8:
  mov64 r3, r6
  add64 r3, r4
  mov64 r4, r5
  neg64 r4
  jsge r7, 0x0, jmp_2d8a0
  neg64 r3
  jsge r6, 0x0, jmp_2d8b8

jmp_2d820:
  mov64 r1, 0x1
  jeq r5, 0x0, jmp_2d8d0

jmp_2d830:
  mov64 r5, r7
  jsge r7, 0x0, jmp_2d850

jmp_2d840:
  add64 r5, r1
  neg64 r5

jmp_2d850:
  mov64 r1, r10
  add64 r1, -0x20
  call fn_2c2f8
  mov64 r2, 0x1
  jsge r7, 0x0, jmp_2d8f0
  jsge r6, 0x0, jmp_2d900

jmp_2d880:
  ldxdw r1, [r10-0x18]
  ldxdw r0, [r10-0x20]
  jne r8, r2, jmp_2d920
  ja jmp_2d950

jmp_2d8a0:
  mov64 r4, r5
  neg64 r3
  jslt r6, 0x0, jmp_2d820

jmp_2d8b8:
  mov64 r3, r6
  mov64 r1, 0x1
  jne r5, 0x0, jmp_2d830

jmp_2d8d0:
  mov64 r1, 0x0
  mov64 r5, r7
  jslt r7, 0x0, jmp_2d840
  ja jmp_2d850

jmp_2d8f0:
  mov64 r2, 0x0
  jslt r6, 0x0, jmp_2d880

jmp_2d900:
  mov64 r8, 0x0
  ldxdw r1, [r10-0x18]
  ldxdw r0, [r10-0x20]
  jeq r8, r2, jmp_2d950

jmp_2d920:
  mov64 r2, 0x1
  jne r0, 0x0, jmp_2d938
  mov64 r2, 0x0

jmp_2d938:
  add64 r1, r2
  neg64 r0
  neg64 r1

jmp_2d950:
  exit

.rodata
  data_0000: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x73, 0x6f, 0x6c, 0x61, 0x6e, 0x61, 0x2d, 0x61, 0x63, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x2d, 0x76, 0x69, 0x65, 0x77, 0x2d, 0x32, 0x2e, 0x31, 0x2e, 0x30, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6c, 0x69, 0x62, 0x2e, 0x72, 0x73, 0x00
  data_007a: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x70, 0x61, 0x79, 0x6f, 0x75, 0x74, 0x2e, 0x72, 0x73, 0x00
  data_0098: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x72, 0x65, 0x66, 0x65, 0x72, 0x72, 0x61, 0x6c, 0x2e, 0x72, 0x73, 0x00
  data_00b8: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x74, 0x61, 0x74, 0x65, 0x2e, 0x72, 0x73, 0x00
  data_00d5: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x73, 0x2f, 0x65, 0x78, 0x63, 0x68, 0x61, 0x6e, 0x67, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6d, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0x2e, 0x72, 0x73, 0x00
  data_00f7: .byte 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x63, 0x6f, 0x6c, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x6d, 0x61, 0x74, 0x68, 0x2e, 0x72, 0x73, 0x00
  data_0113: .byte 0x2f, 0x68, 0x6f, 0x6d, 0x65, 0x2f, 0x72, 0x75, 0x6e, 0x6e, 0x65, 0x72, 0x2f, 0x77, 0x6f, 0x72, 0x6b, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x70, 0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x2d, 0x74, 0x6f, 0x6f, 0x6c, 0x73, 0x2f, 0x6f, 0x75, 0x74, 0x2f, 0x72, 0x75, 0x73, 0x74, 0x2f, 0x6c, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x2f, 0x63, 0x6f, 0x72, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x6c, 0x69, 0x63, 0x65, 0x2f, 0x69, 0x74, 0x65, 0x72, 0x2e, 0x72, 0x73, 0x00
  data_016b: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x70, 0x69, 0x6e, 0x6f, 0x63, 0x63, 0x68, 0x69, 0x6f, 0x2d, 0x30, 0x2e, 0x31, 0x31, 0x2e, 0x32, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x65, 0x6e, 0x74, 0x72, 0x79, 0x70, 0x6f, 0x69, 0x6e, 0x74, 0x2f, 0x6d, 0x6f, 0x64, 0x2e, 0x72, 0x73, 0x00
  data_01e7: .byte 0x2f, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x73, 0x2f, 0x6a, 0x6f, 0x65, 0x62, 0x75, 0x69, 0x6c, 0x64, 0x2f, 0x63, 0x61, 0x72, 0x64, 0x62, 0x6f, 0x61, 0x72, 0x64, 0x74, 0x72, 0x61, 0x64, 0x65, 0x2f, 0x2e, 0x63, 0x61, 0x72, 0x67, 0x6f, 0x2f, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x72, 0x79, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x2e, 0x63, 0x72, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x69, 0x6f, 0x2d, 0x31, 0x39, 0x34, 0x39, 0x63, 0x66, 0x38, 0x63, 0x36, 0x62, 0x35, 0x62, 0x35, 0x35, 0x37, 0x66, 0x2f, 0x73, 0x6f, 0x6c, 0x61, 0x6e, 0x61, 0x2d, 0x61, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0x2d, 0x32, 0x2e, 0x39, 0x2e, 0x30, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x73, 0x79, 0x73, 0x63, 0x61, 0x6c, 0x6c, 0x73, 0x2e, 0x72, 0x73, 0x00
  data_0261: .byte 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x73, 0x2f, 0x65, 0x78, 0x63, 0x68, 0x61, 0x6e, 0x67, 0x65, 0x2f, 0x73, 0x72, 0x63, 0x2f, 0x65, 0x76, 0x65, 0x6e, 0x74, 0x73, 0x2e, 0x72, 0x73, 0x00
  data_0281: .byte 0x02, 0xa8, 0xf6, 0x91, 0x4e, 0x88, 0xa1, 0xb0, 0xe2, 0x10, 0x15, 0x3e, 0xf7, 0x63, 0xae, 0x2b, 0x00, 0xc2, 0xb9, 0x3d, 0x16, 0xc1, 0x24, 0xd2, 0xc0, 0x53, 0x7a, 0x10, 0x04, 0x80, 0x00, 0x00
  data_02a1: .byte 0x8c, 0x97, 0x25, 0x8f, 0x4e, 0x24, 0x89, 0xf1, 0xbb, 0x3d, 0x10, 0x29, 0x14, 0x8e, 0x0d, 0x83, 0x0b, 0x5a, 0x13, 0x99, 0xda, 0xff, 0x10, 0x84, 0x04, 0x8e, 0x7b, 0xd8, 0xdb, 0xe9, 0xf8, 0x59
  data_02c1: .byte 0x06, 0xdd, 0xf6, 0xe1, 0xd7, 0x65, 0xa1, 0x93, 0xd9, 0xcb, 0xe1, 0x46, 0xce, 0xeb, 0x79, 0xac, 0x1c, 0xb4, 0x85, 0xed, 0x5f, 0x5b, 0x37, 0x91, 0x3a, 0x8c, 0xf5, 0x85, 0x7e, 0xff, 0x00, 0xa9
  data_02e1: .byte 0x06, 0xa7, 0xd5, 0x17, 0x19, 0x2c, 0x5c, 0x51, 0x21, 0x8c, 0xc9, 0x4c, 0x3d, 0x4a, 0xf1, 0x7f, 0x58, 0xda, 0xee, 0x08, 0x9b, 0xa1, 0xfd, 0x44, 0xe3, 0xdb, 0xd9, 0x8a, 0x00, 0x00, 0x00, 0x00
  data_0301: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_0321: .byte 0x0b, 0x70, 0x65, 0xb1, 0xe3, 0xd1, 0x7c, 0x45, 0x38, 0x9d, 0x52, 0x7f, 0x6b, 0x04, 0xc3, 0xcd, 0x58, 0xb8, 0x6c, 0x73, 0x1a, 0xa0, 0xfd, 0xb5, 0x49, 0xb6, 0xd1, 0xbc, 0x03, 0xf8, 0x29, 0x46
  data_0341: .byte 0x06, 0xa7, 0xd5, 0x17, 0x18, 0xc7, 0x74, 0xc9, 0x28, 0x56, 0x63, 0x98, 0x69, 0x1d, 0x5e, 0xb6, 0x8b, 0x5e, 0xb8, 0xa3, 0x9b, 0x4b, 0x6d, 0x5c, 0x73, 0x55, 0x5b, 0x21, 0x00, 0x00, 0x00, 0x00
  str_0361: .ascii "config"
  str_0367: .ascii "trader"
  str_036d: .ascii "pool"
  str_0371: .ascii "deposit"
  str_0378: .ascii "market"
  str_037e: .ascii "metadata"
  str_0386: .ascii "position"
  str_038e: .ascii "vault"
  str_0393: .ascii "oracle"
  str_0399: .ascii "referral-code"
  data_03a6: .byte 0x63, 0x6c, 0x61, 0x69, 0x6d, 0x00, 0x00, 0x00, 0x00, 0x00
  data_03b0: .byte 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_03c8: .byte 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_03e0: .byte 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  str_03f8: .ascii "reward-mint"
  str_0403: .ascii "stake-vault"
  str_040e: .ascii "reward-escrow"
  data_041b: .byte 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x00, 0x02, 0x01, 0x02, 0x02, 0x02, 0x03, 0x02, 0x04, 0x03, 0x00, 0x03, 0x01, 0x03, 0x02, 0x03, 0x03, 0x03, 0x04, 0x03, 0x05, 0x03, 0x06, 0x04, 0x00, 0x04, 0x01, 0x04, 0x02, 0x04, 0x03, 0x04, 0x04, 0x04, 0x05, 0x04, 0x06, 0x04, 0x07, 0x04, 0x08, 0x05, 0x00, 0x05, 0x01, 0x05, 0x02, 0x05, 0x03, 0x05, 0x04, 0x05, 0x05, 0x05, 0x06, 0x05, 0x07, 0x05, 0x08, 0x05, 0x09, 0x05, 0x0a, 0x06, 0x00, 0x06, 0x01, 0x06, 0x02, 0x06, 0x03, 0x06, 0x04, 0x06, 0x05, 0x06, 0x06, 0x06, 0x07, 0x06, 0x08, 0x06, 0x09, 0x06, 0x0a, 0x06, 0x0b, 0x06, 0x0c, 0x07, 0x00, 0x07, 0x01, 0x07, 0x02, 0x07, 0x03, 0x07, 0x04, 0x07, 0x05, 0x07, 0x06, 0x07, 0x07, 0x07, 0x08, 0x07, 0x09, 0x07, 0x0a, 0x07, 0x0b, 0x07, 0x0c, 0x07, 0x0d, 0x07, 0x0e, 0x08, 0x00, 0x08, 0x01, 0x08, 0x02, 0x08, 0x03, 0x08, 0x04, 0x08, 0x05, 0x08, 0x06, 0x08, 0x07, 0x08, 0x08, 0x08, 0x09, 0x08, 0x0a, 0x08, 0x0b, 0x08, 0x0c, 0x08, 0x0d, 0x08, 0x0e, 0x08, 0x0f, 0x08, 0x10, 0x09, 0x00, 0x09, 0x01, 0x09, 0x02, 0x09, 0x03, 0x09, 0x04, 0x09, 0x05, 0x09, 0x06, 0x09, 0x07, 0x09, 0x08, 0x09, 0x09, 0x09, 0x0a, 0x09, 0x0b, 0x09, 0x0c, 0x09, 0x0d, 0x09, 0x0e, 0x09, 0x0f, 0x09, 0x10, 0x09, 0x11, 0x09, 0x12, 0x0a, 0x00, 0x0a, 0x01, 0x0a, 0x02, 0x0a, 0x03, 0x0a, 0x04, 0x0a, 0x05, 0x0a, 0x06, 0x0a, 0x07, 0x0a, 0x08, 0x0a, 0x09, 0x0a, 0x0a, 0x0a, 0x0b, 0x0a, 0x0c, 0x0a, 0x0d, 0x0a, 0x0e, 0x0a, 0x0f, 0x0a, 0x10, 0x0a, 0x11, 0x0a, 0x12, 0x0a, 0x13, 0x0a, 0x14, 0x0b, 0x00, 0x0b, 0x01, 0x0b, 0x02, 0x0b, 0x03, 0x0b, 0x04, 0x0b, 0x05, 0x0b, 0x06, 0x0b, 0x07, 0x0b, 0x08, 0x0b, 0x09, 0x0b, 0x0a, 0x0b, 0x0b, 0x0b, 0x0c, 0x0b, 0x0d, 0x0b, 0x0e, 0x0b, 0x0f, 0x0b, 0x10, 0x0b, 0x11, 0x0b, 0x12, 0x0b, 0x13, 0x0b, 0x14, 0x0b, 0x15, 0x0b, 0x16, 0x0c, 0x00, 0x0c, 0x01, 0x0c, 0x02, 0x0c, 0x03, 0x0c, 0x04, 0x0c, 0x05, 0x0c, 0x06, 0x0c, 0x07, 0x0c, 0x08, 0x0c, 0x09, 0x0c, 0x0a, 0x0c, 0x0b, 0x0c, 0x0c, 0x0c, 0x0d, 0x0c, 0x0e, 0x0c, 0x0f, 0x0c, 0x10, 0x0c, 0x11, 0x0c, 0x12, 0x0c, 0x13, 0x0c, 0x14, 0x0c, 0x15, 0x0c, 0x16, 0x0c, 0x17, 0x0c, 0x18, 0x0d, 0x00, 0x0d, 0x01, 0x0d, 0x02, 0x0d, 0x03, 0x0d, 0x04, 0x0d, 0x05, 0x0d, 0x06, 0x0d, 0x07, 0x0d, 0x08, 0x0d, 0x09, 0x0d, 0x0a, 0x0d, 0x0b, 0x0d, 0x0c, 0x0d, 0x0d, 0x0d, 0x0e, 0x0d, 0x0f, 0x0d, 0x10, 0x0d, 0x11, 0x0d, 0x12, 0x0d, 0x13, 0x0d, 0x14, 0x0d, 0x15, 0x0d, 0x16, 0x0d, 0x17, 0x0d, 0x18, 0x0d, 0x19, 0x0d, 0x1a, 0x0e, 0x00, 0x0e, 0x01, 0x0e, 0x02, 0x0e, 0x03, 0x0e, 0x04, 0x0e, 0x05, 0x0e, 0x06, 0x0e, 0x07, 0x0e, 0x08, 0x0e, 0x09, 0x0e, 0x0a, 0x0e, 0x0b, 0x0e, 0x0c, 0x0e, 0x0d, 0x0e, 0x0e, 0x0e, 0x0f, 0x0e, 0x10, 0x0e, 0x11, 0x0e, 0x12, 0x0e, 0x13, 0x0e, 0x14, 0x0e, 0x15, 0x0e, 0x16, 0x0e, 0x17, 0x0e, 0x18, 0x0e, 0x19, 0x0e, 0x1a, 0x0e, 0x1b, 0x0e, 0x1c, 0x0f, 0x00, 0x0f, 0x01, 0x0f, 0x02, 0x0f, 0x03, 0x0f, 0x04, 0x0f, 0x05, 0x0f, 0x06, 0x0f, 0x07, 0x0f, 0x08, 0x0f, 0x09, 0x0f, 0x0a, 0x0f, 0x0b, 0x0f, 0x0c, 0x0f, 0x0d, 0x0f, 0x0e, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x11, 0x0f, 0x12, 0x0f, 0x13, 0x0f, 0x14, 0x0f, 0x15, 0x0f, 0x16, 0x0f, 0x17, 0x0f, 0x18, 0x0f, 0x19, 0x0f, 0x1a, 0x0f, 0x1b, 0x0f, 0x1c, 0x0f, 0x1d, 0x0f, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00
  data_0620: .byte 0x76, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x94, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  data_0660: .quad data_01e7
  data_0668: .byte 0x7a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x17, 0x01, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
  data_0678: .quad data_0000
  data_0680: .byte 0x7a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x01, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00
  data_0690: .quad data_0113
  data_0698: .byte 0x58, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8e, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00
  data_06a8: .quad data_016b
  data_06b0: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc2, 0x01, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_06c0: .quad data_016b
  data_06c8: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdd, 0x01, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
  data_06d8: .quad data_016b
  data_06e0: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe8, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_06f0: .quad data_016b
  data_06f8: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xeb, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0708: .quad data_016b
  data_0710: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xee, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0720: .quad data_016b
  data_0728: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf1, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0738: .quad data_016b
  data_0740: .byte 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe1, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0750: .quad str_0361
  data_0758: .quad 0x0000000000000006
  data_0760: .quad str_036d
  data_0768: .quad 0x0000000000000004
  data_0770: .quad data_0261
  data_0778: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45, 0x00, 0x00, 0x00, 0x35, 0x00, 0x00, 0x00
  data_0788: .quad data_0261
  data_0790: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00
  data_07a0: .quad data_0261
  data_07a8: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x53, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00
  data_07b8: .quad data_0261
  data_07c0: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x62, 0x00, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00
  data_07d0: .quad data_0261
  data_07d8: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6a, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00
  data_07e8: .quad data_0261
  data_07f0: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x00
  data_0800: .quad data_00d5
  data_0808: .byte 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x27, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00
  data_0818: .quad str_038e
  data_0820: .quad 0x0000000000000005
  data_0828: .quad str_03f8
  data_0830: .quad 0x000000000000000b
  data_0838: .quad str_0403
  data_0840: .quad 0x000000000000000b
  data_0848: .quad str_040e
  data_0850: .quad 0x000000000000000d
  data_0858: .quad data_00f7
  data_0860: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc7, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00
  data_0870: .quad data_00f7
  data_0878: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xda, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00
  data_0888: .quad data_00f7
  data_0890: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb3, 0x00, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_08a0: .quad data_00f7
  data_08a8: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbe, 0x00, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00
  data_08b8: .quad data_00f7
  data_08c0: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x00, 0x00, 0x00, 0x38, 0x00, 0x00, 0x00
  data_08d0: .quad data_00f7
  data_08d8: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc2, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00
  data_08e8: .quad data_00f7
  data_08f0: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe5, 0x00, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
  data_0900: .quad data_00f7
  data_0908: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x01, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00
  data_0918: .quad data_00f7
  data_0920: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x01, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00
  data_0930: .quad data_00f7
  data_0938: .byte 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3a, 0x01, 0x00, 0x00, 0x29, 0x00, 0x00, 0x00
  data_0948: .quad data_007a
  data_0950: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
  data_0960: .quad data_007a
  data_0968: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00
  data_0978: .quad data_007a
  data_0980: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00
  data_0990: .quad data_007a
  data_0998: .byte 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00
  data_09a8: .quad data_0098
  data_09b0: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_09c0: .quad data_0098
  data_09c8: .byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
  data_09d8: .quad data_00b8
  data_09e0: .byte 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4e, 0x01, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00
