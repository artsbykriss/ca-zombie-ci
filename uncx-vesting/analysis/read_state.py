#!/usr/bin/env python3
"""Read UNCX VestingManager state (incl. private mappings) via storage slots.

Layout (verified on-chain):
  slot 9  svgGenerator
  slot 10 nextVestingId
  slot 11 _totalTokenShares mapping
  slot 12 _depositedShares mapping
  slot 13 vestingSchedules mapping
  slot 14 _transferable mapping
  slot 15 _shareRatio mapping
  slot 16 feePercentage
  slot 17 flatFee
  slot 18 feeCollector
  slot 19 feeExemptCreators mapping
  slot 20 feeExemptTokens mapping
"""
import json, subprocess, sys
from eth_utils import keccak

RPC = sys.argv[1] if len(sys.argv) > 1 else None  # never stored in repo

def slot_map(key_hex, base_slot):
    k = key_hex if key_hex.startswith('0x') else '0x' + key_hex
    key = k[2:].rjust(64, '0')
    s = hex(base_slot)[2:].rjust(64, '0')
    return '0x' + keccak(bytes.fromhex(key + s)).hex()

def cast_storage(addr, slot, block=None):
    cmd = ['cast', 'storage', addr, str(slot), '--rpc-url', RPC]
    if block: cmd += ['--block', str(block)]
    out = subprocess.run(cmd, capture_output=True, text=True)
    return out.stdout.strip()

def cast_call(addr, sig, args=None, block=None):
    cmd = ['cast', 'call', addr, sig, '--rpc-url', RPC]
    if args: cmd += [str(a) for a in args]
    if block: cmd += ['--block', str(block)]
    out = subprocess.run(cmd, capture_output=True, text=True)
    return out.stdout.strip() or out.stderr.strip()

def to_int(hexstr):
    if not hexstr: return 0
    s = hexstr.split()[0]
    if s in ('0x', ''): return 0
    try:
        return int(s, 16) if s.startswith('0x') else int(s)
    except ValueError:
        return int(float(s))

if __name__ == '__main__':
    VM = '0xa98f06312b7614523d0f5e725e15fd20fb1b99f5'
    block = int(sys.argv[2]) if len(sys.argv) > 2 else None
    tokens = {
        'EDGEN': '0xaa9806c938836627ed1a41ae871c7e1889ae02ca',
        'ZC': '0x4e67db19044549ff420860834c91b45bad298722',
        'pepecoin': '0xa9e8acf069c58aec8825542845fd754e41a9489a',
        'LO0P': '0x00000000000050806673b532d7486ac114c1de3f',
        'PAAL': '0x14fee680690900ba0cccfc76ad70fd1b95d10e16',
        'AXGT': '0x6112C3509A8a787df576028450FebB3786A2274d',
        'AXGT2': '0xDd66781D0E9a08D4FBb5eC7BAc80B691BE27F21D',
    }
    print(f"=== block {block or 'latest'} ===")
    print("nextVestingId:", to_int(cast_storage(VM, 10, block)))
    print("feePercentage:", to_int(cast_storage(VM, 16, block)))
    print("flatFee:", to_int(cast_storage(VM, 17, block)))
    for name, tok in tokens.items():
        S = to_int(cast_storage(VM, slot_map(tok, 11), block))
        R = to_int(cast_storage(VM, slot_map(tok, 15), block))
        B = to_int(cast_call(tok, "balanceOf(address)(uint256)", [VM], block))
        print(f"{name:10s} totalShares={S} shareRatio={R} balance={B}")
