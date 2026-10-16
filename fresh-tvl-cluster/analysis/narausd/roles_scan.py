import json, urllib.request, sys

def logs(addr, topic0, page=1, offset=1000):
    url=f"https://eth.blockscout.com/api?module=logs&action=getLogs&fromBlock=1&toBlock=latest&address={addr}&topic0={topic0}&page={page}&offset={offset}"
    req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req))["result"]

def topic(sig): 
    import subprocess
    return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()

ROLES={
 "0x0000000000000000000000000000000000000000000000000000000000000000":"DEFAULT_ADMIN",
 "0x"+__import__("subprocess").run(["cast","keccak","MINTER_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"MINTER",
 "0x"+__import__("subprocess").run(["cast","keccak","COLLATERAL_MANAGER_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"COLLATERAL_MANAGER",
 "0x"+__import__("subprocess").run(["cast","keccak","GATEKEEPER_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"GATEKEEPER",
 "0x"+__import__("subprocess").run(["cast","keccak","BLACKLIST_MANAGER_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"BLACKLIST_MANAGER",
 "0x"+__import__("subprocess").run(["cast","keccak","REWARDER_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"REWARDER",
 "0x"+__import__("subprocess").run(["cast","keccak","FULL_RESTRICTED_ROLE"],capture_output=True,text=True).stdout.strip()[2:]:"FULL_RESTRICTED",
}
def nm(r): return ROLES.get(r, r[:10]+"..")

rc=topic("RoleGranted(bytes32,address,address)")
rr=topic("RoleRevoked(bytes32,address,address)")

targets={
 "MCT":       "0x4eD90999f558Fdc28606b7F7f9AFc7044befb803",
 "NaraUSD":   "0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7",
 "NaraUSD+":  "0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6",
}
for name,addr in targets.items():
    for lbl,top in (("GRANT",rc),("REVOKE",rr)):
        res=logs(addr,top)
        print(f"== {name} {lbl} n={len(res)}")
        for r in res:
            t=r["topics"]
            role=t[1]; acct="0x"+t[2][-40:]; by="0x"+t[3][-40:] if len(t)>3 else "?"
            print(f"  blk={int(r['blockNumber'],16)} {nm(role):20s} account={acct} by={by}")
