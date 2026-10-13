#!/usr/bin/env python3
"""Compare Aurora Rose pool bytecode with known Curve deployments (code hash + stripped metadata)."""
import json, urllib.request, subprocess, sys

def getcode(rpcurl, addr):
    req=urllib.request.Request(rpcurl,data=json.dumps({'jsonrpc':'2.0','id':1,'method':'eth_getCode','params':[addr,'latest']}).encode(),
                               headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req,timeout=60))['result']

def keccak(hexstr):
    return subprocess.run(['cast','keccak',hexstr],capture_output=True,text=True).stdout.strip()

AURORA='https://mainnet.aurora.dev'
ETH='https://ethereum-rpc.publicnode.com'
targets = {
 'aurora-poolA-3coin': (AURORA,'0xc90dB0d8713414d78523436dC347419164544A3f'),
 'aurora-meta-UST': (AURORA,'0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8'),
 'aurora-meta-FRAX': (AURORA,'0xa34315F1ef49392387Dd143f4578083A9Bd33E94'),
 'aurora-meta-MAI': (AURORA,'0x65a761136815B45A9d78d9781d22d47247B49D23'),
 # Curve references on Ethereum
 'curve-3pool': (ETH,'0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7'),
 'curve-renBTC': (ETH,'0x93054188d876f558f4a66B2EF1d97d16eDf0895B'),
 'curve-sBTC': (ETH,'0x7fC77b5c7614e1533320ea6dcc1c2abb61bb7d4e'),
 'curve-gusd-meta': (ETH,'0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956'),
 'curve-husd-meta': (ETH,'0x3eF6A01A0a756cc1A116bC610eA9Ba9550a1eB4E'),
 'curve-usdn-meta': (ETH,'0x0f9cb53Ebe405d49A0d96fd8D90BaFc30A7648d7'),
}
out={}
for name,(rpc,addr) in targets.items():
    try:
        c=getcode(rpc,addr)
        n=(len(c)-2)//2
        full=keccak(c)
        # strip solidity metadata: last 43 bytes (86 hex) typical for 0.5/0.6; try several
        strip={}
        for cut in (86, 82, 78, 74, 70, 66, 62, 58, 54, 50):
            if len(c)-2 > cut:
                strip[cut]=keccak(c[:len(c)-cut])
        out[name]={'addr':addr,'len':n,'full':full,'strip':strip}
        print(f"{name:22s} {addr} len={n} full={full}")
    except Exception as e:
        print(name,'ERR',e)
json.dump(out, open('curve_compare.json','w'), indent=1)
# find matching stripped hashes between aurora and curve refs
print("\n=== matches on stripped hashes ===")
aur=[k for k in out if k.startswith('aurora')]
cur=[k for k in out if k.startswith('curve')]
for a in aur:
    for c in cur:
        for cut in out[a]['strip']:
            if cut in out[c]['strip'] and out[a]['strip'][cut]==out[c]['strip'][cut]:
                print(f"MATCH {a} <-> {c} (strip {cut})")
