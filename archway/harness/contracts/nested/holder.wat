;; E6b holder contract (generated).
(module
  (import "env" "query" (func $query (param i32) (result i32)))
  (memory (export "memory") 1)
  (global $heap (mut i32) (i32.const 8192))
  (func (export "allocate") (param $size i32) (result i32)
    (local $data i32) (local $region i32)
    (local.set $data (global.get $heap))
    (global.set $heap
      (i32.and (i32.add (i32.add (local.get $data) (local.get $size)) (i32.const 7)) (i32.const -8)))
    (local.set $region (global.get $heap))
    (global.set $heap (i32.add (global.get $heap) (i32.const 16)))
    (i32.store (local.get $region) (local.get $data))
    (i32.store offset=4 (local.get $region) (local.get $size))
    (i32.store offset=8 (local.get $region) (i32.const 0))
    (local.get $region))
  (func (export "deallocate") (param $ptr i32))
  (func (export "interface_version_8"))
  ;; @16 query-request region -> @64 request JSON; @32 response region -> @512 JSON
  (data (i32.const 16) "\40\00\00\00\00\01\00\00\56\00\00\00")
  (data (i32.const 32) "\00\02\00\00\40\00\00\00\3e\00\00\00")
  (data (i32.const 64) "\7b\22\73\6d\61\72\74\22\3a\7b\22\63\6f\6e\74\72\61\63\74\5f\61\64\64\72\22\3a\22\61\72\63\68\77\61\79\31\74\72\69\67\67\65\72\74\72\69\67\67\65\72\74\72\69\67\67\65\72\74\72\69\67\67\65\72\74\72\67\67\78\71\35\22\2c\22\6d\73\67\22\3a\22\65\33\30\3d\22\7d\7d")
  (data (i32.const 512) "\7b\22\6f\6b\22\3a\7b\22\6d\65\73\73\61\67\65\73\22\3a\5b\5d\2c\22\64\61\74\61\22\3a\6e\75\6c\6c\2c\22\61\74\74\72\69\62\75\74\65\73\22\3a\5b\5d\2c\22\65\76\65\6e\74\73\22\3a\5b\5d\7d\7d")
  (func (export "instantiate") (param i32 i32 i32) (result i32) (i32.const 32))
  (func (export "execute") (param $env i32) (param $info i32) (param $msg i32) (result i32)
    (local $a i64) (local $b i64) (local $c i64) (local $d i64)
    ;; stage distinctive values in locals (live across the query call)
    (local.set $a (i64.or (i64.shl (i64.extend_i32_u (local.get $env)) (i64.const 32)) (i64.const 0x1111)))
    (local.set $b (i64.or (i64.shl (i64.extend_i32_u (local.get $env)) (i64.const 32)) (i64.const 0x2222)))
    (local.set $c (i64.or (i64.shl (i64.extend_i32_u (local.get $env)) (i64.const 32)) (i64.const 0x3333)))
    (local.set $d (i64.or (i64.shl (i64.extend_i32_u (local.get $env)) (i64.const 32)) (i64.const 0x4444)))
    ;; suspend inside the querier while the trigger runs on the stack above
    (call $query (i32.const 16))
    drop
    (i64.add (i64.add (local.get $a) (local.get $b)) (i64.add (local.get $c) (local.get $d)))
    drop
    (i32.const 32))
)
