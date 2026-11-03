; Trigger module for GHSA-v2h8-j899-r676.
; A typed `if` with block parameters and an OMITTED `else`, executed in a loop.
; params=2, prefix=31 (forces the block parameters to spill), 1000 iterations.
; On a vulnerable Singlepass build this leaks 8 native-stack bytes per iteration
; (upstream regression uses 400000 iterations to reach the guard page).
(module
  (type $pass (func (param i64 i64) (result i64 i64)))
  (func $probe)
  (func (export "check")
    (param $value i64) (param $condition i32) (param $expected i64)
    (result i32) (local $remaining i32)
    i32.const 1000 local.set $remaining
    loop
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
local.get $value
      local.get $condition
      if (type $pass) end
local.get $expected i64.ne if unreachable end
local.get $expected i64.ne if unreachable end
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
drop
      call $probe
      local.get $remaining i32.const 1 i32.sub
      local.tee $remaining br_if 0
    end
    i32.const 1))
