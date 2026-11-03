#!/usr/bin/env python3
"""Normalize TronGrid ABI ({'entrys':[...]}) to standard ABI JSON + selector map."""
import json, os, subprocess, sys

OUT = os.path.dirname(os.path.abspath(__file__))
NAMES = ["CherryPool", "PokerGame", "FireFull"]


def norm_type(t):
    return t


def canon(entry):
    typ = entry.get("type", "Function")
    t = {"Function": "function", "Event": "event", "Constructor": "constructor",
         "Fallback": "fallback", "Receive": "receive"}.get(typ, typ.lower())
    e = {"type": t, "name": entry.get("name", "")}
    if "inputs" in entry:
        e["inputs"] = [{"name": i.get("name", ""), "type": norm_type(i["type"]),
                        "indexed": bool(i.get("indexed"))} for i in entry["inputs"]]
        if t == "event":
            for i in e["inputs"]:
                i.pop("indexed", None) if not i.pop("indexed", False) else None
    if "outputs" in entry:
        e["outputs"] = [{"name": o.get("name", ""), "type": norm_type(o["type"])}
                        for o in entry["outputs"]]
    if entry.get("payable"):
        e["stateMutability"] = "payable"
    elif entry.get("constant"):
        e["stateMutability"] = "view"
    else:
        e["stateMutability"] = "nonpayable"
    return e


def sig(e):
    return f"{e['name']}({','.join(i['type'] for i in e.get('inputs', []))})"


def selector(s):
    return subprocess.check_output(["cast", "sig", s], text=True).strip()


def main():
    for name in NAMES:
        raw = json.load(open(f"{OUT}/{name}_abi.json"))
        entries = raw.get("entrys", raw if isinstance(raw, list) else [])
        flat, sels = [], {}
        for ent in entries:
            e = canon(ent)
            flat.append(e)
            if e["type"] == "function":
                s = sig(e)
                sels[s] = {"selector": selector(s), "stateMutability": e["stateMutability"],
                           "inputs": [i["type"] for i in e.get("inputs", [])],
                           "outputs": [o["type"] for o in e.get("outputs", [])]}
        json.dump(flat, open(f"{OUT}/{name}_abi_flat.json", "w"), indent=1)
        json.dump(sels, open(f"{OUT}/{name}_selectors.json", "w"), indent=1, sort_keys=True)
        print(f"== {name}: {len(flat)} entries, {len(sels)} functions")
        for s, v in sorted(sels.items(), key=lambda x: x[1]["selector"]):
            print(f"  {v['selector']}  {s}  [{v['stateMutability']}]")


if __name__ == "__main__":
    main()
