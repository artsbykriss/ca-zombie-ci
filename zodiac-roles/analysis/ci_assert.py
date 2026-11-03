#!/usr/bin/env python3
"""Assert the Zodiac CI scan results."""
import json
import sys

d = json.load(open("ci-out/scan.json"))
ok = {
    "roles_count_9912": 9900 <= d.get("roles_count", 0) <= 9920,
    "delay_count_136": d.get("delay_count") == 136,
    "top_avatar_4971": "4971dd016127f390a3ef6b956ff944d0e2e1e462" in str(d.get("top_avatar", "")).lower(),
    "top_module_threshold_2": d.get("top_module_threshold") == "0x" + "0" * 63 + "2",
    "top_module_handler_canonical": str(d.get("top_module_handler", "")).lower().endswith(
        "f48f2b2d2a534e402487b3ee7c18c33aec0fe5e4"
    ),
    "second_instance_12beef": "12beef35025841efccb77d6ee40df86400fdb4bb" in str(d.get("second_instance_avatar", "")).lower(),
}
# No-module counterexample must be an empty address[] (offset 0x40, length 0x0)
raw = str(d.get("no_module_counterexample", ""))
try:
    body = raw[2:]
    off = int(body[0:64], 16)
    length = int(body[off * 2:off * 2 + 64], 16)
    ok["no_module_counterexample_empty"] = off == 0x40 and length == 0
except Exception:
    ok["no_module_counterexample_empty"] = False
for k, v in ok.items():
    print(f"{'PASS' if v else 'FAIL'}  {k}")
print(json.dumps({k: d.get(k) for k in ("roles_count", "delay_count", "top_avatar", "second_instance_avatar")}, indent=1))
if not all(ok.values()):
    sys.exit(1)
print("Zodiac scan OK")
