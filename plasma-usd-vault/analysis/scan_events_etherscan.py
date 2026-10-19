#!/usr/bin/env python3
"""Count teller events via Etherscan V2 getLogs (read-only). No secrets printed."""
import json, urllib.request, subprocess, time

KEY = subprocess.check_output("grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '\"'", shell=True).decode().strip()
T = "0x4E7d2186eB8B75fBDcA867761636637E05BaeF1E"
EV = {
    "BulkWithdraw": "0xdcc60b41ff1c604459e6aa4a7299817416b19fc586a392f111646e26597c4af9",
    "BulkDeposit": "0x6f9b974223f85a1ae805c33b8b519039e2435481d949db1110de151a94d587af",
    "MessageSent": "0xe0ec62d39b054dc2fd626dbc271483735df6e6fa1ef8389754bf8ab27a75eab2",
    "MessageReceived": "0xb944fddc61d7fedb8b736790454ba972000703b0d21c7481d6dbf95b7c2cc2f1",
}

def get_logs(chain, frm, to, topic):
    out = []
    page = 1
    while True:
        url = (f"https://api.etherscan.io/v2/api?chainid={chain}&module=logs&action=getLogs"
               f"&fromBlock={frm}&toBlock={to}&address={T}&topic0={topic}&page={page}&offset=1000&apikey={KEY}")
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=60) as r:
                    d = json.load(r)
                break
            except Exception:
                time.sleep(1)
        if d.get("status") != "1":
            if "No records" in str(d.get("message")) or d.get("result") == []:
                return out
            raise RuntimeError(str(d)[:200])
        res = d["result"]
        out += res
        if len(res) < 1000:
            return out
        page += 1

CH = {"plasma": (9745, 25_000_000, 35_510_052), "ethereum": (1, 16_000_000, 26_229_819)}
out = {}
for net, (chain, lo, hi) in CH.items():
    out[net] = {}
    for name, topic in EV.items():
        logs = []
        f = lo
        while f <= hi:
            t = min(f + 1_000_000 - 1, hi)
            logs += get_logs(chain, f, t, topic)
            f = t + 1
        out[net][name] = logs
        total = 0
        for l in logs:
            try:
                total += int(l["data"], 16)
            except Exception:
                pass
        print(net, name, len(logs), "sum_raw", total, flush=True)
json.dump(out, open("analysis/teller_events.json", "w"))
print("wrote analysis/teller_events.json")
