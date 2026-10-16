import json, sys; sys.path.insert(0,'.')
from rpc import keccak

def canon(inp):
    t = inp['type']
    if t.startswith('tuple'):
        inner = ','.join(canon(c) for c in inp['components'])
        return '(' + inner + ')' + t[len('tuple'):]
    return t

def sig(f):
    return f['name'] + '(' + ','.join(canon(i) for i in f['inputs']) + ')'

def selectors(abi_path):
    abi = json.load(open(abi_path))
    out = {}
    for f in abi:
        if f.get('type') == 'function':
            s = sig(f)
            out[s] = "0x" + keccak(s.encode()).hex()[:8]
    return out

if __name__ == "__main__":
    for tag in ["registry","ramp","rwa","rampeth"]:
        s = selectors(f"sources/{tag}.abi.json")
        print("==", tag)
        for k,v in s.items():
            if any(x in k for x in ["setPoolConfig","pokeFee","clearPoke","setClaimFee","setDistributor","setFFFeeSink","setPaused","pause","setPoolPaused","pausePool","setBallotGate","setPoolAsymmetry","sweep","deposit","withdraw","claimFees","stake","unstake","transfer","syncRanges","register"]):
                print(f"   {v} {k}")
