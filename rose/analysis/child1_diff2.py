#!/usr/bin/env python3
"""Child1: post-process child1_diff.json.
1) shift profile (b_off - a_off) across anchors/gaps
2) gaps whose lengths differ (actual insert/deletes)
3) classify equal-length content gaps
"""
import json

rep = json.load(open("child1_diff.json"))
print(f"gaps: {len(rep)}")

print("\n=== length-changing gaps (a_len != b_len) ===")
net = 0
for e in rep:
    if e["a_len"] != e["b_len"]:
        net += e["b_len"] - e["a_len"]
        print(f"gap {e['n']:3d} vase@{e['a_off']}({e['a_len']}) bento@{e['b_off']}({e['b_len']}) "
              f"delta={e['b_len']-e['a_len']:+d}")
        print(f"   VASE : {e['a_hex']}  | {e['a_asc']}")
        print(f"   BENTO: {e['b_hex']}  | {e['b_asc']}")
print(f"net delta over length-changing gaps: {net:+d}")

# shift profile: for each gap, print offset difference
prev = 0
print("\n=== shift profile (b_off - a_off) where it changes ===")
for e in rep:
    diff = e["b_off"] - e["a_off"]
    if diff != prev:
        print(f"  gap {e['n']:3d} vase@{e['a_off']:6d} bento@{e['b_off']:6d}  shift {prev:+d} -> {diff:+d}")
        prev = diff

# classify equal-length gaps
print("\n=== equal-length gaps with content changes (excluding single PUSH-target bytes) ===")
import re
def malformed(seg):
    """does seg look like pure ASCII/data"? just report hex"""
    return None

for e in rep:
    if e["a_len"] == e["b_len"] and e["a_len"] > 0:
        if e["a_len"] <= 4:
            continue  # single-byte/short, print summary later
        print(f"gap {e['n']:3d} vase@{e['a_off']}({e['a_len']}) bento@{e['b_off']}({e['b_len']}) "
              f"delta={e['b_len']-e['a_len']:+d}")
        print(f"   VASE : {e['a_hex']}")
        print(f"   BENTO: {e['b_hex']}")
        print(f"   VASE asc : {e['a_asc']}")
        print(f"   BENTO asc: {e['b_asc']}")

nshort = sum(1 for e in rep if e['a_len'] == e['b_len'] and e['a_len'] <= 4)
print(f"\nshort (<=4B) equal-length gaps: {nshort}")
nerr = sum(1 for e in rep if e['a_len'] == e['b_len'] and e['a_len'] > 4)
print(f"long equal-length gaps: {nerr}")
