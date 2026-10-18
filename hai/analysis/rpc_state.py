#!/usr/bin/env python3
"""Latest-block state reads for HAI governor/timelock/safe/token. Public keyless RPC only."""
import json, urllib.request, os, sys, time

RPC = os.environ.get('OP_RPC_PUBLIC', 'https://mainnet.optimism.io')

GOV = '0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777'
TL = '0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899'
SAFE = '0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724'
KITE = '0xf467c7d5a4a9c4687ffc7986ac6ad5a4c81e1404'
ATTACKER = '0xDC6A914c4fA69917f4bc6A93cCe46CC348a6ec0c'
DEFENDER = '0xCAFd432b7EcAfff352D92fcB81c60380d437E99D'
V2 = '0xE02e8AFcE6BFE464edA586E3a54ba9901FF2C81d'
V3 = '0xbad58e133138549936d2576ebc33251be841d3e9'
V4 = '0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb'
DELEGATE_TARGET = '0x1472934131f7af94f3cf2542b6121a44d236cf39'
OP = '0x4200000000000000000000000000000000000042'
WETH = '0x4200000000000000000000000000000000000006'
VELO = '0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db'
HARDENING = 103806721447535921384462690981123294371878165558661022162562047341447243780649

def enc_uint(x): return hex(x)[2:].rjust(64, '0')
def enc_addr(a): return a.lower().replace('0x', '').rjust(64, '0')

def call(to, data, tag='latest'):
    return {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, tag]}

def rpc_batch(calls):
    body = json.dumps(calls).encode()
    for i in range(3):
        try:
            req = urllib.request.Request(RPC, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
            r = json.load(urllib.request.urlopen(req, timeout=40))
            if isinstance(r, list) and len(r) == 1:
                return r[0]
            return r
        except Exception as e:
            if i == 2: raise
            time.sleep(1.5)

def main():
    out = {}
    # latest block
    b = rpc_batch([{"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}])
    bn = int(b['result'], 16)
    blk = rpc_batch([{"jsonrpc": "2.0", "id": 1, "method": "eth_getBlockByNumber", "params": [hex(bn), False]}])['result']
    ts = int(blk['timestamp'], 16)
    out['block'] = bn; out['timestamp'] = ts
    out['iso'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(ts))

    reqs = []
    labels = []
    def add(label, to, data):
        labels.append(label); reqs.append(call(to, data))

    add('votingDelay', GOV, '0x3932abb1')
    add('votingPeriod', GOV, '0x02a251a3')
    add('proposalThreshold', GOV, '0xb58131b0')
    add('quorumNumerator', GOV, '0xa7713a70')
    add('timelock', GOV, '0xd33219b4')
    add('token', GOV, '0xfc0c546a')
    add('quorum_now', GOV, '0xf8ce560a' + enc_uint(ts - 1))
    add('hardening_state', GOV, '0x3e4f49e6' + enc_uint(HARDENING))
    add('hardening_deadline', GOV, '0xc01f9e37' + enc_uint(HARDENING))
    add('hardening_votes', GOV, '0x544ffc9c' + enc_uint(HARDENING))
    add('tl_minDelay', TL, '0xf27a0c92')
    add('kite_symbol', KITE, '0x95d89b41')
    add('kite_totalSupply', KITE, '0x18160ddd')
    add('kite_safe', KITE, '0x70a08231' + enc_addr(SAFE))
    add('kite_attacker', KITE, '0x70a08231' + enc_addr(ATTACKER))
    add('kite_defender', KITE, '0x70a08231' + enc_addr(DEFENDER))
    add('kite_v2', KITE, '0x70a08231' + enc_addr(V2))
    add('kite_v3', KITE, '0x70a08231' + enc_addr(V3))
    add('kite_v4', KITE, '0x70a08231' + enc_addr(V4))
    add('votes_defender', GOV, '0xeb9019d4' + enc_addr(DEFENDER) + enc_uint(ts - 1))
    add('votes_v2', GOV, '0xeb9019d4' + enc_addr(V2) + enc_uint(ts - 1))
    add('votes_v3', GOV, '0xeb9019d4' + enc_addr(V3) + enc_uint(ts - 1))
    add('votes_v4', GOV, '0xeb9019d4' + enc_addr(V4) + enc_uint(ts - 1))
    add('votes_attacker', GOV, '0xeb9019d4' + enc_addr(ATTACKER) + enc_uint(ts - 1))
    add('safe_owners', SAFE, '0xa0e67e2b')
    add('safe_threshold', SAFE, '0xe75235b8')
    add('safe_nonce', SAFE, '0xaffed0e0')
    add('op_safe', OP, '0x70a08231' + enc_addr(SAFE))
    add('weth_safe', WETH, '0x70a08231' + enc_addr(SAFE))
    add('velo_safe', VELO, '0x70a08231' + enc_addr(SAFE))
    add('tl_ts', TL, '0xd45c4435' + '52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6')
    add('tl_done', TL, '0x2ab0f529' + '52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6')
    add('tl_ready', TL, '0x13bc9f20' + '52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6')
    add('tl_pending', TL, '0x584b153e' + '52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6')
    add('tl_delay_role', TL, '0x91d14854' + __import__('subprocess').check_output(['cast','keccak','PROPOSER_ROLE']).decode().strip()[2:] + enc_addr(GOV))
    add('delegates_defender', KITE, '0x587cde1e' + enc_addr(DEFENDER))
    add('delegates_v2', KITE, '0x587cde1e' + enc_addr(V2))
    add('delegates_v3', KITE, '0x587cde1e' + enc_addr(V3))

    res = []
    for i in range(0, len(reqs), 8):
        part = reqs[i:i+8]
        for j, r in enumerate(part):
            r['id'] = i + j + 1
        got = rpc_batch(part)
        if isinstance(got, dict):
            got = [got]
        res.extend(got)
    byid = {r['id']: r for r in res} if isinstance(res, list) else {}
    vals = {}
    for i, lab in enumerate(labels, start=1):
        r = byid.get(i)
        vals[lab] = r.get('result') if r else None
    out['raw'] = vals

    def dec_u(k):
        v = vals.get(k)
        return int(v, 16) if v and v != '0x' else None
    out['decoded'] = {
        'votingDelay': dec_u('votingDelay'),
        'votingPeriod': dec_u('votingPeriod'),
        'proposalThreshold': dec_u('proposalThreshold'),
        'quorumNumerator': dec_u('quorumNumerator'),
        'timelock': '0x' + vals['timelock'][-40:] if vals.get('timelock') else None,
        'token': '0x' + vals['token'][-40:] if vals.get('token') else None,
        'quorum_now': dec_u('quorum_now'),
        'hardening_state': dec_u('hardening_state'),
        'hardening_deadline': dec_u('hardening_deadline'),
        'hardening_votes': vals.get('hardening_votes'),
        'tl_minDelay': dec_u('tl_minDelay'),
        'kite_totalSupply': dec_u('kite_totalSupply'),
        'kite_safe': dec_u('kite_safe'),
        'kite_attacker': dec_u('kite_attacker'),
        'kite_defender': dec_u('kite_defender'),
        'kite_v2': dec_u('kite_v2'),
        'kite_v3': dec_u('kite_v3'),
        'kite_v4': dec_u('kite_v4'),
        'votes_defender': dec_u('votes_defender'),
        'votes_v2': dec_u('votes_v2'),
        'votes_v3': dec_u('votes_v3'),
        'votes_v4': dec_u('votes_v4'),
        'votes_attacker': dec_u('votes_attacker'),
        'safe_threshold': dec_u('safe_threshold'),
        'safe_nonce': dec_u('safe_nonce'),
        'op_safe': dec_u('op_safe'),
        'weth_safe': dec_u('weth_safe'),
        'velo_safe': dec_u('velo_safe'),
        'tl_ts': dec_u('tl_ts'),
        'tl_done': dec_u('tl_done'),
        'tl_ready': dec_u('tl_ready'),
        'tl_pending': dec_u('tl_pending'),
        'tl_proposer_role': dec_u('tl_delay_role'),
    }
    # decode string symbol
    sv = vals.get('kite_symbol')
    if sv and sv != '0x':
        try:
            ln = int(sv[66:130], 16)
            out['decoded']['kite_symbol'] = bytes.fromhex(sv[130:130+ln*2]).decode()
        except Exception: pass
    # owners array
    ov = vals.get('safe_owners')
    if ov and ov != '0x':
        try:
            n = int(ov[66:130], 16)
            owners = ['0x' + ov[130+i*64+24:130+(i+1)*64] for i in range(n)]
            out['decoded']['safe_owners'] = owners
        except Exception: pass
    for k in ['delegates_defender', 'delegates_v2', 'delegates_v3']:
        v = vals.get(k)
        out['decoded'][k] = ('0x' + v[-40:]) if v and v != '0x' else None
    print(json.dumps(out, indent=2))
    json.dump(out, open('latest_state.json', 'w'), indent=2)

if __name__ == '__main__':
    main()
