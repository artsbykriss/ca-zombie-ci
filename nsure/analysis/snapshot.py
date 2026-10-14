#!/usr/bin/env python3
"""Pin a block and snapshot all Nsure live state into live_state.json (evidence)."""
import sys, json, time
sys.path.insert(0, '.')
from rpc import rpc_batch, selector, block_number

BLK = block_number()
print("pinned block:", BLK)

A = {
 'capitalStake':  '0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6',
 'underwriting':  '0x1a66f065303299d78693f122c800Ab3dEbE9c966',
 'buy':           '0x702aff99b08e8891fc70811174701fb7407b4477',
 'surplus':       '0x80e711b29e46d430ff1553eb2ada670e2a25593c',
 'treasury':      '0xfd0D28539aeD12477dcba1575eB40fca53969440',
 'nsureToken':    '0x20945ca1df56d237fd40036d47e866c7dccd2114',
 'capitalConverter': '0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84',
 'product':       '0x06e76c5c53775681f0626600d6266901a03141a8',
 'claimPurchaseMint': '0x200db99fe5c0f39688853d4c4d8651648d995b26',
 'uw2':           '0x454fd408abb7c3b36b4cf098fe86c9ed388fc477',
 'ownerEOA':      '0x7023a32108539a024ca17afab0f5b90f8770bccd',
 'signer04':      '0x04ae9200c02d598edf2801c3e3850431d57cd707',
 'signerBB':      '0xbb826fb86fae53be90f0b711c6a506860b7bdbe3',
 'safe':          '0x1995dc62b91163e4693f63eae7af6559c8ab299c',
}
WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
NSURE = A['nsureToken']
NETH = A['capitalConverter']
PAIR = '0xed196f5f01e8c99ef4c6d77b83ccaf629032a8f2'

def ea(a): return a.lower().replace('0x', '').rjust(64, '0')

state = {'block': BLK, 'addresses': A, 'reads': {}}

calls, labels = [], []
def add(label, to, data):
    calls.append(("eth_call", [{"to": to, "data": data}, hex(BLK)]))
    labels.append(label)

for n, a in A.items():
    add(f'native:{n}', a, None)  # handled below
# native balances need eth_getBalance
calls = [("eth_getBalance", [A[n], hex(BLK)]) for n in A]
res = rpc_batch(calls)
for n, r in zip(A, res):
    state['reads'][f'native:{n}'] = int(r, 16) if isinstance(r, str) else r

calls, labels = [], []
for n, a in A.items():
    add(f'weth:{n}', WETH, selector('balanceOf(address)') + ea(a))
    add(f'nsure:{n}', NSURE, selector('balanceOf(address)') + ea(a))
    add(f'neth:{n}', NETH, selector('balanceOf(address)') + ea(a))
    for f in ['owner()', 'operator()', 'signer()', 'paused()', 'totalSupply()']:
        add(f'{f}:{n}', a, selector(f))
res = rpc_batch(calls)
for l, r in zip(labels, res):
    if isinstance(r, str) and r.startswith('0x') and r != '0x':
        state['reads'][l] = int(r, 16) if len(r) <= 66 else r
    else:
        state['reads'][l] = {'error': str(r)[:80]}

# pair reserves
calls = [
    ("eth_call", [{"to": PAIR, "data": selector('getReserves()')}, hex(BLK)]),
    ("eth_call", [{"to": PAIR, "data": selector('token0()')}, hex(BLK)]),
    ("eth_call", [{"to": PAIR, "data": selector('token1()')}, hex(BLK)]),
    ("eth_call", [{"to": PAIR, "data": selector('totalSupply()')}, hex(BLK)]),
]
res = rpc_batch(calls)
r0 = res[0]
if isinstance(r0, str) and r0 != '0x':
    w = [r0[2+i*64:2+(i+1)*64] for i in range(3)]
    state['pair'] = {'pair': PAIR, 'reserve0': int(w[0], 16), 'reserve1': int(w[1], 16),
                     'ts': int(w[2], 16), 'token0': '0x'+res[1][-40:], 'token1': '0x'+res[2][-40:],
                     'lp_total': int(res[3], 16)}

# roles / pool config details
calls, labels = [], []
add('cs.poolLength', A['capitalStake'], selector('poolLength()'))
add('cs.canDeposit', A['capitalStake'], selector('canDeposit()'))
add('cs.totalAllocPoint', A['capitalStake'], selector('totalAllocPoint()'))
add('cs.nsurePerBlock', A['capitalStake'], selector('nsurePerBlock()'))
add('cs.pendingDuration', A['capitalStake'], selector('pendingDuration()'))
add('cs.poolInfo0', A['capitalStake'], selector('poolInfo(uint256)') + format(0, '064x'))
add('cs.userCap0', A['capitalStake'], selector('userCapacityMax(uint256)') + format(0, '064x'))
add('cs.capMax0', A['capitalStake'], selector('capacityMax(uint256)') + format(0, '064x'))
add('nsure.getMinterLength', NSURE, selector('getMinterLength()'))
add('nsure.totalSupply', NSURE, selector('totalSupply()'))
add('nsure.isMinterCS', NSURE, selector('isMinter(address)') + ea(A['capitalStake']))
add('nsure.isMinterCPM', NSURE, selector('isMinter(address)') + ea(A['claimPurchaseMint']))
add('nsure.isMinterSafe', NSURE, selector('isMinter(address)') + ea(A['safe']))
add('safe.threshold', A['safe'], selector('getThreshold()'))
add('safe.nonce', A['safe'], selector('nonce()'))
add('cpm.signer', A['claimPurchaseMint'], selector('signer()'))
add('uw.divLen', A['underwriting'], selector('getDivCurrencyLength()'))
add('uw.div0', A['underwriting'], selector('divCurrencies(uint256)') + format(0, '064x'))
add('tr.divLen', A['treasury'], selector('getDivCurrencyLength()'))
add('tr.div0', A['treasury'], selector('divCurrencies(uint256)') + format(0, '064x'))
add('tr.div1', A['treasury'], selector('divCurrencies(uint256)') + format(1, '064x'))
add('converter.maxConvert', A['capitalConverter'], selector('maxConvert()'))
res = rpc_batch(calls)
for l, r in zip(labels, res):
    if isinstance(r, str) and r.startswith('0x') and r != '0x':
        if l in ('cs.poolInfo0', 'uw.div0', 'tr.div0', 'tr.div1'):
            w = [r[2+i*64:2+(i+1)*64] for i in range(len(r[2:])//64)]
            state['reads'][l] = w
        else:
            state['reads'][l] = int(r, 16)
    else:
        state['reads'][l] = {'error': str(r)[:80]}

# storage slots (signer/operator evidence)
calls = [("eth_getStorageAt", [A[n], hex(slot), hex(BLK)]) for n in ('underwriting','treasury','surplus','capitalStake') for slot in (0,1,2)]
labels = [f'slot{n}:{slot}' for n in ('underwriting','treasury','surplus','capitalStake') for slot in (0,1,2)]
res = rpc_batch(calls)
for l, r in zip(labels, res):
    state['reads'][l] = r

json.dump(state, open('live_state.json', 'w'), indent=1, default=str)
print("saved live_state.json")
print(json.dumps({k: v for k, v in state['reads'].items() if k.startswith(('weth:','nsure:','native:'))}, indent=1))
print('pair:', json.dumps(state.get('pair'), indent=1))
