#!/usr/bin/env python3
"""Probe the deployed store program's instruction surface ON-CHAIN.

For each candidate instruction name we send a minimal simulateTransaction carrying only its
discriminator. Anchor returns InstructionFallbackNotFound (Custom 101) iff the discriminator is not
recognised; any other result means the instruction exists in the deployed binary.

Read-only: sigVerify=false, replaceRecentBlockhash=true.
"""
import json, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import simulate_battery as sb
from solders.instruction import Instruction, AccountMeta

REPO = "/tmp/opencode/gmx-solana-repo"
HERE = os.path.dirname(os.path.abspath(__file__))

def names(commit):
    src = subprocess.run(["git", "-C", REPO, "show", f"{commit}:programs/store/src/lib.rs"],
                         capture_output=True, text=True).stdout
    return sorted(set(re.findall(r"^\s+pub fn ([a-z0-9_]+)", src, re.M)))

def probe(name, tries=6):
    ix = Instruction(sb.PROGRAM, sb.disc(name), [AccountMeta(sb.STORE, False, False)])
    for _ in range(tries):
        v = sb.simulate_tx([ix], tries=1)
        if "error" not in v:
            err = v.get("err")
            code = None
            if isinstance(err, dict) and "InstructionError" in err:
                ie = err["InstructionError"][1]
                code = ie.get("Custom") if isinstance(ie, dict) else ie
            return {"name": name, "code": code, "recognized": code != 101}
        time.sleep(4)
    return {"name": name, "rpc_failed": True, "recognized": None}

def main():
    audit = names("8af1e70")
    post = ["close_gt_exchange_v2", "set_gt_delegate", "increase_gt_allowance",
            "decrease_gt_allowance", "request_gt_exchange_v2"]
    out = {}
    for group, ns in (("audit_134", audit), ("post_audit_5", post)):
        res = {}
        for i, n in enumerate(ns):
            res[n] = probe(n)
            time.sleep(0.8)
        out[group] = res
        rec = [n for n, v in res.items() if v.get("recognized")]
        fb = [n for n, v in res.items() if v.get("code") == 101]
        fail = [n for n, v in res.items() if v.get("rpc_failed")]
        print(f"{group}: {len(ns)} probed | recognized={len(rec)} fallback101={len(fb)} rpc_failed={len(fail)}", flush=True)
        if fb:
            print("   FALLBACK(101):", fb, flush=True)
        if fail:
            print("   RPC-FAILED:", fail, flush=True)
        with open(os.path.join(HERE, "instruction_surface_probe.json"), "w") as f:
            json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
