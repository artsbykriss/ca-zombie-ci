#!/usr/bin/env python3
"""ZH4 Wave-B0 CI check: validate the residual disposition table and re-read live funds.

Read-only. Public RPCs only. No secrets are read or written.
Writes ci-out/validation.json and ci-out/live_checks.json.
"""
import json, os, re, sys, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'analysis'))
from rows import ROWS  # noqa: E402

OUT = os.path.join(ROOT, 'ci-out')
os.makedirs(OUT, exist_ok=True)

# ---------- counts ----------
from collections import Counter
cnt = Counter(); n_total = 0
for lane, target, funds, status, ref, note, *rest in ROWS:
    n = rest[0] if rest else 1
    n_total += n; cnt[status] += n
closed = cnt['CLOSED-README'] + cnt['CLOSED-LANE'] + cnt['EXCLUDED'] + cnt['COVERED']
summary = json.load(open(os.path.join(ROOT, 'summary.json')))
expected = summary['counts']
checks = {
    'named_candidates_enumerated': n_total == expected['named_candidates_enumerated'],
    'table_rows_and_groups': len(ROWS) == expected['table_rows_and_groups'],
    'findings': cnt['FINDING'] == expected['findings_tier1_tier2'],
    'low': cnt['LOW'] == expected['low_tier3'],
    'closed': closed == expected['closed_total'],
    'parked': cnt['PARKED'] == expected['parked'],
    'open': cnt['OPEN'] == expected['open'],
    'open_list_len': len(summary['open_list']) == cnt['OPEN'],
}
missing_lane_files = [f'analysis/{l}.md' for l in ['r1','r2','r3','r4','r5','r6','r7','d2a','d2b','d2c','d2d']
                      if not os.path.exists(os.path.join(ROOT, f'analysis/{l}.md'))]

# ---------- secret scan ----------
secret_patterns = [
    r'apikey\s*=\s*[A-Za-z0-9]{16,}',
    r'api_key\s*=\s*[A-Za-z0-9]{16,}',
    r'ALCHEMY_API_KEY\s*=\s*\S+',
    r'PRIVATE_KEY\s*=\s*0x[0-9a-fA-F]{64}',
    r'https?://[^\s"\'<>]*(alchemy|infura|quiknode|ankr|drpc)[^\s"\'<>]*[?&](api[_-]?key|key)=[A-Za-z0-9]{10,}',
]
secret_hits = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in ('.git', 'ci-artifacts', '__pycache__')]
    for fn in filenames:
        if not fn.endswith(('.md', '.json', '.py', '.sh', '.txt')):
            continue
        if fn in ('ci-log.txt',):
            continue
        p = os.path.join(dirpath, fn)
        try:
            txt = open(p, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        for pat in secret_patterns:
            if re.search(pat, txt):
                secret_hits.append(os.path.relpath(p, ROOT))
                break

# ---------- live reads (public endpoints only) ----------
RPC = {
    'ethereum': 'https://ethereum-rpc.publicnode.com',
    'katana': 'https://rpc.katana.network',
    'era': 'https://mainnet.era.zksync.io',
    'ronin': 'https://api.roninchain.com/rpc',
    'mantle': 'https://rpc.mantle.xyz',
}
HEADERS = {'User-Agent': 'Mozilla/5.0'}

def post(url, payload, timeout=25):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={**HEADERS, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(chain, method, params):
    j = post(RPC[chain], {'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params})
    if 'error' in j:
        raise RuntimeError(j['error'])
    return j.get('result')

def eth_call(chain, to, data):
    return rpc(chain, 'eth_call', [{'to': to, 'data': data}, 'latest'])

def u256(x):
    return int(x, 16) if x and x != '0x' else None

def word_addr(x):
    return '0x' + x[-40:]

live = {'blocks': {}, 'values': {}, 'errors': []}
try:
    for ch in RPC:
        live['blocks'][ch] = int(rpc(ch, 'eth_blockNumber', []), 16)
except Exception as e:
    live['errors'].append(f'blockNumber: {e}')

def add(name, fn):
    try:
        live['values'][name] = fn()
    except Exception as e:
        live['errors'].append(f'{name}: {e}')

# Katana L1 vault reporting + USDC yield vault
VBUSDC = '0x53E82ABbb12638F09d9e624578ccB666217a765e'
YV = '0xbeefb9f61cc44895d8aec381373555a64191a9c4'
MINTER = '0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0'
add('katana_l1_vbUSDC_totalAssets_raw', lambda: u256(eth_call('ethereum', VBUSDC, '0x01e1d114')))
add('katana_l1_vbUSDC_stakedAssets_raw', lambda: u256(eth_call('ethereum', VBUSDC, '0xb51536c9')))
add('katana_l1_vbUSDC_yieldVault', lambda: word_addr(eth_call('ethereum', VBUSDC, '0xa7f8a5e2')))
add('katana_l1_yieldVault_totalAssets_raw', lambda: u256(eth_call('ethereum', YV, '0x01e1d114')))
add('katana_l2_minter_peer_30101', lambda: word_addr(eth_call('katana', MINTER, '0xbb0b6a53' + hex(30101)[2:].rjust(64, '0'))))

# zkSync unnamed settlement vault
ZK = '0x621425a1Ef6abE91058E9712575dcc4258F8d091'
USDC_ERA = '0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4'
USDT_ERA = '0x493257fD37EDB34451f62EDf8D2a0C418852bA4C'
add('zksync_vault_eth_wei', lambda: int(rpc('era', 'eth_getBalance', [ZK, 'latest']), 16))
add('zksync_vault_usdc_raw', lambda: u256(eth_call('era', USDC_ERA, '0x70a08231' + '0' * 24 + ZK[2:].lower())))
add('zksync_vault_usdt_raw', lambda: u256(eth_call('era', USDT_ERA, '0x70a08231' + '0' * 24 + ZK[2:].lower())))

# Ronin deprecated staking manager
RON = '0x8Bd81a19420bAd681B7bfc20E703EBd8e253782D'
AXS = '0x97a9107c1793bc407d6f527b77e7fff4d812bece'
add('ronin_manager_ron_wei', lambda: int(rpc('ronin', 'eth_getBalance', [RON, 'latest']), 16))
add('ronin_manager_axs_raw', lambda: u256(eth_call('ronin', AXS, '0x70a08231' + '0' * 24 + RON[2:].lower())))

# Tron JustLend Energy Rental native balance
def tron_balance():
    req = urllib.request.Request('https://api.trongrid.io/v1/accounts/TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd',
                                 headers=HEADERS)
    with urllib.request.urlopen(req, timeout=25) as r:
        j = json.loads(r.read().decode())
    return j['data'][0].get('balance', 0)
add('tron_energy_rental_balance_sun', tron_balance)

validation = {
    'ok': all(checks.values()) and not missing_lane_files and not secret_hits,
    'checks': checks,
    'counts': {
        'named_candidates_enumerated': n_total,
        'table_rows_and_groups': len(ROWS),
        'findings_tier1_tier2': cnt['FINDING'],
        'low_tier3': cnt['LOW'],
        'closed_total': closed,
        'parked': cnt['PARKED'],
        'open': cnt['OPEN'],
    },
    'missing_lane_files': missing_lane_files,
    'secret_hits': secret_hits,
    'note': 'counts are compared against summary.json; live reads are point-in-time public-RPC reads (no keys).',
}
json.dump(validation, open(os.path.join(OUT, 'validation.json'), 'w'), indent=2)
json.dump(live, open(os.path.join(OUT, 'live_checks.json'), 'w'), indent=2)

print(json.dumps(validation, indent=2))
print(json.dumps(live, indent=2)[:4000])
sys.exit(0 if validation['ok'] else 1)
