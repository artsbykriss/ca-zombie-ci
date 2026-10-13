#!/usr/bin/env python3
"""Child1: step 1 exploration - metadata tails, ASCII strings, common prefix/suffix."""
import json, re, sys

d = json.load(open("child1_bytecodes.json"))
vase = bytes.fromhex(d["vase"]["code"][2:])
bento = bytes.fromhex(d["bentobox"]["code"][2:])


def strip_metadata(code):
    meta_len = int.from_bytes(code[-2:], "big")
    meta = code[-(meta_len + 2):]
    body = code[: -(meta_len + 2)]
    return body, meta, meta_len


for name, code in (("vase", vase), ("bento", bento)):
    body, meta, ml = strip_metadata(code)
    print(f"=== {name}: total={len(code)} metadata_len_field={ml} meta_hex_head={meta[:12].hex()} body_len={len(body)}")
    # validate CBOR marker
    print(f"    meta tail hex: {meta[:40].hex()} ... {meta[-14:].hex()}")
    print(f"    contains ipfs marker: {b'ipfs' in meta}, bzzr1: {b'bzzr1' in meta}")

vb, vm, _ = strip_metadata(vase)
bb, bm, _ = strip_metadata(bento)

# ASCII strings >= 6 chars in body
def strings(code, minlen=5):
    out = []
    for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, code):
        out.append((m.start(), m.group().decode()))
    return out

vs = strings(vb)
bs = strings(bb)
print(f"\n=== vase body strings ({len(vs)}):")
for off, s in vs:
    print(f"  {off:6d} {s!r}")
print(f"\n=== bento body strings ({len(bs)}):")
for off, s in bs:
    print(f"  {off:6d} {s!r}")

# common prefix / suffix of bodies
def common_prefix(a, b):
    n = min(len(a), len(b))
    i = 0
    while i < n and a[i] == b[i]:
        i += 1
    return i

def common_suffix(a, b):
    n = min(len(a), len(b))
    i = 0
    while i < n and a[len(a) - 1 - i] == b[len(b) - 1 - i]:
        i += 1
    return i

cp = common_prefix(vb, bb)
cs = common_suffix(vb, bb)
print(f"\ncommon prefix len={cp}, common suffix len={cs}")
print(f"vase middle region: [{cp}, {len(vb)-cs}) len={len(vb)-cp-cs}")
print(f"bento middle region: [{cp}, {len(bb)-cs}) len={len(bb)-cp-cs}")
print(f"vase middle hex: {vb[cp:len(vb)-cs].hex()}")
print(f"bento middle hex: {bb[cp:len(bb)-cs].hex()}")
