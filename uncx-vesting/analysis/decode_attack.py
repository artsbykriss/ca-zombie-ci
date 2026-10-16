import json
from eth_abi import decode as abi_decode
from eth_utils import keccak

receipt = json.load(open('analysis/attack_receipt_eth.json'))['result']
vm = '0xa98f06312b7614523d0f5e725e15fd20fb1b99f5'.lower()

# canonical signatures (tuple expanded)
evs = {
 keccak(text="VestingCreated(uint256,address,address,(uint256,uint256,uint8)[],bool,bool,bool)").hex():
   ("VestingCreated", [("uint256",True),("address",True),("address",False),("(uint256,uint256,uint8)[]",False),("bool",False),("bool",False),("bool",False)]),
 keccak(text="VestingToppedUp(uint256,address,uint256,(uint256,uint256,uint8)[])").hex():
   ("VestingToppedUp", [("uint256",True),("address",True),("uint256",False),("(uint256,uint256,uint8)[]",False)]),
 keccak(text="TokensReleased(uint256,address,uint256)").hex():
   ("TokensReleased", [("uint256",True),("address",True),("uint256",False)]),
 keccak(text="VestingCancelled(uint256)").hex():
   ("VestingCancelled", [("uint256",True)]),
 keccak(text="FeesCollected(address,uint256,uint256)").hex():
   ("FeesCollected", [("address",False),("uint256",False),("uint256",False)]),
 keccak(text="AirdropVestingCreated(uint256[],address[])").hex():
   ("AirdropVestingCreated", [("uint256[]",False),("address[]",False)]),
}

TOKENS = {
 '0xaa9806c938836627ed1a41ae871c7e1889ae02ca':'?',
}
lines=[]
for lg in receipt['logs']:
    if lg['address'].lower()!=vm: continue
    t0=lg['topics'][0][2:]
    if t0 not in evs: 
        lines.append(f"log{int(lg['logIndex'],16)} RAW {t0}"); continue
    name,spec=evs[t0]
    indexed=[i for i,(t,ix) in enumerate(spec) if ix]
    nonidx=[t for (t,ix) in spec if not ix]
    vals=list(abi_decode(nonidx, bytes.fromhex(lg['data'][2:]))) if nonidx else []
    out={}
    vi=0
    for idx,(t,ix) in enumerate(spec):
        if ix: out[f"arg{idx}"]=lg['topics'][1+indexed.index(idx)]
        else:
            v=vals[vi]; vi+=1
            out[f"arg{idx}"]=v
    lines.append(f"log{int(lg['logIndex'],16)} {name}: {out}")
open('analysis/attack_sequence.txt','w').write("\n".join(str(l) for l in lines))
print("\n".join(str(l) for l in lines))
