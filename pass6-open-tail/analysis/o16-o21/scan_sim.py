#!/usr/bin/env python3
"""O16-O21: for each located program, fetch recent signatures, find a real tx that
invokes the program, and run the attacker-substitution simulation (control vs attacker).

Read-only: only getSignaturesForAddress / getTransaction / simulateTransaction
(sigVerify:false, replaceRecentBlockhash:true). Nothing is signed or broadcast.
No secrets: keyless public Solana RPC.
"""
import json, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "o13-o15"))
import sim_attacker as SA
from sol_rpc import get_signatures, get_transaction

PROGRAMS = {
    "O16_satrush_main":    "satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco",
    "O16_satrush_staking": "SaTsTaKpGdTfUEPSSwyYgLKkfnZu8uL3D1DbLXshdb7",
    "O18_truedex":         "ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL",
    "O19_pascal":          "3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j",
    "O20_n1bridge":        "n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM",
    "O21_byzanlink_vault": "HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se",
    "O21_byzanlink_payfi": "B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U",
}


def find_examples(pid, want=3):
    """Return (n_sigs, [signatures]) for the newest txs that touch pid."""
    r = get_signatures(pid, limit=1000)
    res = r.get("result") or []
    sigs = [s["signature"] for s in res if not s.get("err")]
    return len(res), sigs[:want]


def main():
    only = sys.argv[1:] or list(PROGRAMS)
    out = {}
    for name in only:
        pid = PROGRAMS[name]
        try:
            n, sigs = find_examples(pid, want=3)
        except Exception as e:
            print(f"[{name}] sig fetch ERR {e}")
            out[name] = {"program": pid, "error": str(e)}
            continue
        rec = {"program": pid, "n_sigs": n, "examples": []}
        print(f"[{name}] {pid} n_sigs={n}")
        for sig in sigs:
            try:
                r = SA.run(sig, only_program=pid)
            except Exception as e:
                rec["examples"].append({"sig": sig, "error": str(e)})
                print(f"   sim ERR {e}")
                continue
            entry = {
                "sig": sig, "disc": r.get("disc"), "dlen": r.get("dlen"),
                "naccts": r.get("n_accts"), "orig_signers": r.get("orig_signers"),
                "attacker_pubkey": r.get("attacker_pubkey"),
                "control": SA.summarize(r.get("control")),
                "attacker": SA.summarize(r.get("attacker")),
            }
            rec["examples"].append(entry)
            print(f"   disc={entry['disc']} dlen={entry['dlen']} naccts={entry['naccts']} "
                  f"signers={entry['orig_signers']}")
            print(f"     control : {entry['control'][:240]}")
            print(f"     attacker: {entry['attacker'][:240]}")
        out[name] = rec
    json.dump(out, open(os.path.join(os.path.dirname(__file__), "sim_surface_O16_O21.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
