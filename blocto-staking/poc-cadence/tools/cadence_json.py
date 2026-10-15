#!/usr/bin/env python3
"""Flatten Flow CLI JSON-Cadence output and pull a value out of it.

Usage:
  <flow CLI output> | python3 cadence_json.py <path>
  *          -> whole flattened structure
  foo.bar    -> dict/struct field
  foo[0]     -> list index
"""
import json
import sys


def flatten(v):
    if v is None:
        return None
    if isinstance(v, list):
        return [flatten(x) for x in v]
    if isinstance(v, dict):
        if "type" in v and "value" in v:
            t = v["type"]
            raw = v["value"]
            if t in ("UInt", "UInt8", "UInt16", "UInt32", "UInt64", "UInt128", "UInt256",
                     "Int", "Int8", "Int16", "Int32", "Int64", "Int128", "Int256",
                     "Word8", "Word16", "Word32", "Word64"):
                return int(raw)
            if t in ("UFix64", "Fix64"):
                return float(raw)
            if t == "Bool":
                return raw if isinstance(raw, bool) else str(raw).lower() == "true"
            if t == "String":
                return raw
            if t in ("Optional",):
                return None if raw is None else flatten(raw)
            if t == "Array" or t == "VariableSizedArray":
                return [flatten(x) for x in raw]
            if t == "Dictionary":
                out = {}
                if isinstance(raw, dict):
                    entries = raw.get("entries", [])
                elif isinstance(raw, list):
                    entries = raw
                else:
                    entries = []
                for e in entries:
                    k = flatten(e["key"])
                    out[str(k) if not isinstance(k, str) else k] = flatten(e["value"])
                return out
            if t == "Struct" or t == "Resource":
                return {f["name"]: flatten(f["value"]) for f in raw.get("fields", [])}
            if t == "Enum":
                return flatten(raw)
            if t == "Address":
                return raw
            if t == "Type":
                return raw.get("staticType", raw) if isinstance(raw, dict) else raw
            if t == "Void":
                return None
            # fall back: raw
            return flatten(raw) if isinstance(raw, (dict, list)) else raw
        if "value" in v and len(v) == 1:
            return flatten(v["value"])
        return {k: flatten(x) for k, x in v.items()}
    return v


def walk(obj, path):
    if path in ("", "*"):
        return obj
    cur = obj
    token = ""
    i = 0
    parts = []
    while i < len(path):
        c = path[i]
        if c == ".":
            parts.append(token)
            token = ""
        elif c == "[":
            if token:
                parts.append(token)
                token = ""
            j = path.index("]", i)
            parts.append(int(path[i + 1:j]))
            i = j
        else:
            token += c
        i += 1
    if token:
        parts.append(token)
    for p in parts:
        if isinstance(p, int):
            cur = cur[p]
        elif isinstance(cur, dict):
            cur = cur[p]
        else:
            raise KeyError(f"cannot walk {p!r} into {type(cur).__name__}")
    return cur


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception as e:  # noqa: BLE001
        print(f"__PARSE_ERROR__ {e}", file=sys.stderr)
        sys.exit(2)
    flat = flatten(data)
    path = sys.argv[1] if len(sys.argv) > 1 else "*"
    try:
        val = walk(flat, path)
    except Exception as e:  # noqa: BLE001
        print(f"__PATH_ERROR__ {path}: {e}", file=sys.stderr)
        sys.exit(3)
    if isinstance(val, (dict, list)):
        print(json.dumps(val, sort_keys=True))
    elif isinstance(val, bool):
        print("true" if val else "false")
    else:
        print(val)


if __name__ == "__main__":
    main()
