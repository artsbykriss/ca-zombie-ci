#!/usr/bin/env python3
"""Wei-exact verification of Faiyah reward math against live settlements + views.

Pool #41 (XEF, apr=200 = 2%/yr, interestDelay=0):
  accrued(t) = floor(amount * apr * (t - stime) / (1e4 * 31_536_000))
  claimable(t) = max(0, accrued(t) - claimed)   [claimableReward returns this]
  - every recent Unstaked settlement: cumulative claimed field (w3) must equal accrued(settled_time)
  - every live view: claimableReward.remaining must equal accrued(now) - w3
All reads pinned to one block. Read-only; Tamsa API for decoded logs (public, keyless)."""
import json, subprocess
import requests
import rpc

POOL = '0xca3aab5282586efd5c38edb5083fed87da11ccd9'
DEN = 10_000 * 31_536_000


def sig(s):
    return subprocess.run(['cast', 'sig', s], capture_output=True, text=True).stdout.strip()


def words(raw):
    raw = raw[2:] if raw.startswith('0x') else raw
    return [int(raw[i:i + 64], 16) for i in range(0, len(raw), 64)]


def accrued(amount, apr, elapsed):
    if elapsed <= 0:
        return 0
    return amount * apr * elapsed // DEN


def main():
    bn = rpc.block_number()
    blk = hex(bn)
    now = int(rpc.rpc('eth_getBlockByNumber', [blk, False])['timestamp'], 16)
    apr = rpc.dec_uint(rpc.call(POOL, sig('apr()'), blk))
    intd = rpc.dec_uint(rpc.call(POOL, sig('interestDelay()'), blk))
    intt = rpc.dec_uint(rpc.call(POOL, sig('interestTime()'), blk))
    out = {'pool': POOL, 'block': bn, 'timestamp': now, 'apr': apr,
           'interestDelay': intd, 'interestTime': intt, 'settlements': [], 'views': []}

    rows = requests.get(f'https://api.tamsa.io/api/v1/address/{POOL}/event-logs',
                        params={'limit': 80}, timeout=30,
                        headers={'User-Agent': 'Mozilla/5.0 research'}).json()['rows']
    unst = [r for r in rows if r.get('method', '').startswith('Unstaked')][:35]
    print(f'{len(rows)} recent events, {len(unst)} Unstaked; block={bn} ts={now}')
    for r in unst:
        sid = int(r['topics'][2], 16)
        w = words(rpc.call(POOL, sig('stakes(uint256)') + rpc.enc_uint(sid), blk))
        if len(w) < 5:
            continue
        amount, stime, claimed, settled = w[1], w[2], w[3], w[4]
        ev_amount = int(r['data'][2:66], 16)
        ev_reward = int(r['data'][66:130], 16)
        exp = accrued(amount, apr, settled - stime - intd)
        ok = (amount == ev_amount and claimed == exp)
        out['settlements'].append({'stakeId': sid, 'block': r['blockNumber'],
                                   'amount': str(amount), 'eventReward': str(ev_reward),
                                   'cumulativeClaimed': str(claimed),
                                   'expectedCumulative': str(exp),
                                   'diff': str(claimed - exp), 'exact': ok})
        print(f"  stake {sid} blk {r['blockNumber']} evReward={ev_reward} cumClaimed={claimed} exp={exp} diff={claimed-exp} {'OK' if ok else 'MISMATCH'}")

    nxt = rpc.dec_uint(rpc.call(POOL, sig('nextStakeId()'), blk))
    checked = 0
    step = max(1, nxt // 60)
    for sid in range(0, nxt, step):
        w = words(rpc.call(POOL, sig('stakes(uint256)') + rpc.enc_uint(sid), blk))
        if len(w) < 5 or w[4] != 0:
            continue
        cw = words(rpc.call(POOL, sig('claimableReward(uint256)') + rpc.enc_uint(sid), blk))
        total = accrued(w[1], apr, now - w[2] - intd)
        exp = max(0, total - w[3])
        ok = cw[1] == exp
        out['views'].append({'stakeId': sid, 'claimableNowFlag': cw[0], 'remaining': str(cw[1]),
                             'claimed': str(w[3]), 'expectedRemaining': str(exp),
                             'diff': str(cw[1] - exp), 'exact': ok})
        checked += 1
        print(f"  view stake {sid} remaining={cw[1]} claimed={w[3]} exp={exp} diff={cw[1]-exp} {'OK' if ok else 'MISMATCH'}")
        if checked >= 25:
            break

    out['settlements_exact'] = sum(1 for x in out['settlements'] if x['exact'])
    out['settlements_total'] = len(out['settlements'])
    out['views_exact'] = sum(1 for x in out['views'] if x['exact'])
    out['views_total'] = len(out['views'])
    out['all_exact'] = out['settlements_exact'] == out['settlements_total'] and out['views_exact'] == out['views_total']
    json.dump(out, open('verify_math.json', 'w'), indent=1)
    print(f"RESULT settlements {out['settlements_exact']}/{out['settlements_total']} exact; "
          f"views {out['views_exact']}/{out['views_total']} exact")


if __name__ == '__main__':
    main()
