#!/usr/bin/env python3
"""READ-ONLY: poll stake-account lamports to detect mid-epoch credits."""
import sys, time, json, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc  # noqa

ACCTS = {
    "pool idx0  (Bw9eiuod…)": "Bw9eiuodrcZ9v1uEHZQNdEDETrM92vWux6FFDpN9cYen",
    "pool idx14 (52qokGjZ…)": "52qokGjZdeRYWUwYSPEfT2GsJXqvDWy4oStp2tTkUjst",
    "pool idx43 (E31N3GPm…)": "E31N3GPmF1MLTkqg21e8AFg7ULPtjofyDYDETGtt9DqG",
}
ROUNDS = int(sys.argv[1]) if len(sys.argv) > 1 else 7
SLEEP = int(sys.argv[2]) if len(sys.argv) > 2 else 30


def main():
    prev = {}
    for r in range(ROUNDS):
        res = rpc("getMultipleAccounts", [list(ACCTS.values()), {"encoding": "base64", "commitment": "confirmed"}])
        slot = rpc("getSlot", [{"commitment": "confirmed"}])
        for (name, addr), v in zip(ACCTS.items(), res["value"]):
            lam = v["lamports"]
            d = lam - prev.get(name, lam)
            print(f"r{r} slot={slot} {name} lamports={lam} delta={d}", flush=True)
            prev[name] = lam
        # any global reward activity?
        if r < ROUNDS - 1:
            time.sleep(SLEEP)
    print(json.dumps(prev, indent=1))


main()
