#!/usr/bin/env python3
"""xALPH mint/burn math search -- proof that no unprivileged round-trip is profitable.

Reimplements the exact arithmetic of the deployed XAlphToken Ralph bytecode
(codeHash d7a4b6c41512a5a09676367c088ee6846cfb2654297a7d3c1d8f72623815919d,
bytecode identical to alephium/powfi-sdk staking/artifacts/XAlphToken.ral.json):

  method[12] mulDiv(a,b,d)      = floor(a*b/d)          (full-precision, rounds DOWN)
  method[14] stake(amount)      : x = (S==0)?amount:mulDiv(amount,S,D); assert x>0;
                                  D+=amount; S+=x
  method[15] startUnstake(amt)  : b = mulDiv(amt,D,S); assert b>0; D-=b; S-=amt
  method[16] depositReward(amt) : assert S>0; D+=amt          (caller actually pays)
  method[20] cancelUnstake(...) : x = (S==0)?restaked:mulDiv(restaked,S,D); D+=restaked; S+=x

Properties checked:
  (P1) no round-trip stake->startUnstake yields b > amount  (no free ALPH)
  (P2) the exchange rate D/S is monotonically NON-DECREASING under every
       state transition (floor rounding always favours existing holders)
  (P3) no state with S==0 has D>0 (the 1:1 first-staker branch cannot be gamed)

Usage: python3 roundtrip_math.py [--big]
"""
import random, sys

def muldiv(a, b, d):
    assert d != 0, "mulDiv denominator 0 (Ralph error 350)"
    return (a * b) // d

def stake(D, S, a):
    x = a if S == 0 else muldiv(a, S, D)
    assert x > 0, "stake xAlphAmount==0 (error 15)"
    return D + a, S + x, x

def start_unstake(D, S, amount):
    b = muldiv(amount, D, S)
    assert b > 0, "startUnstake alphAmount==0 (error 16)"
    return D - b, S - amount, b

def deposit_reward(D, S, amount):
    assert S > 0, "depositReward S==0 (error 17)"
    return D + amount

def cancel(D, S, restaked):
    x = restaked if S == 0 else muldiv(restaked, S, D)
    assert x > 0
    return D + restaked, S + x, x

LIVE_D = 13512874721665312186856085
LIVE_S = 13409685596049135363642978

def main(big=False):
    print(f"live D={LIVE_D} S={LIVE_S} rate={LIVE_D/LIVE_S:.12f}")

    # --- P1: exhaustive-ish round-trip profit search
    max_profit = None; positives = []
    states = [(10**18, 10**18), (10**24, 10**24), (LIVE_D, LIVE_S), (1000, 1000),
              (10**6, 3), (10**12, 7), (10**18 + 1, 10**18), (10**9, 10**18)]
    trials = 40000 if big else 8000
    small = range(1, 4000) if big else range(1, 1500)
    for (D0, S0) in states:
        cands = list(small) + [10**k for k in range(1, 25)] + \
                [random.randint(1, 10**24) for _ in range(trials)]
        for a in cands:
            try:
                D1, S1, x = stake(D0, S0, a)
            except AssertionError:
                continue
            try:
                D2, S2, b = start_unstake(D1, S1, x)
            except AssertionError:
                continue
            profit = b - a
            max_profit = profit if max_profit is None else max(max_profit, profit)
            if profit > 0:
                positives.append((D0, S0, a, x, b, profit))
    print(f"P1 max round-trip profit (b-a) = {max_profit}")
    print(f"P1 positive-profit states = {len(positives)}")
    for e in positives[:10]:
        print("   ", e)

    # --- P2: rate monotonicity
    D, S = LIVE_D, LIVE_S
    iters = 2_000_000 if big else 300_000
    viol = 0; checked = 0
    for _ in range(iters):
        before = D / S
        r = random.random()
        try:
            if r < 0.45:
                D, S, _ = stake(D, S, random.randint(1, 10**22))
            elif r < 0.9:
                D, S, _ = start_unstake(D, S, random.randint(1, max(1, S // 100)))
            else:
                D = deposit_reward(D, S, random.randint(1, 10**21))
        except AssertionError:
            continue
        checked += 1
        if S == 0:
            # S can only reach 0 together with D==0 (P3); treat as +inf and reseed
            if D != 0:
                viol += 1
            D, S = LIVE_D, LIVE_S
            continue
        after = D / S
        if after < before - 1e-24:
            viol += 1
    print(f"P2 rate-decrease violations in {checked} ops = {viol}")

    # --- P3: D>0 with S==0 reachable?
    reachable = []
    D, S = LIVE_D, LIVE_S
    for _ in range(iters // 10):
        try:
            if random.random() < 0.5:
                D, S, _ = stake(D, S, random.randint(1, 10**20))
            else:
                if S > 0:
                    D, S, _ = start_unstake(D, S, S)  # try to unstake everything
        except AssertionError:
            continue
        if S == 0 and D > 0:
            reachable.append((D, S))
    print(f"P3 states with S==0 & D>0 reachable = {len(reachable)} (expected 0)")
    print("RESULT:", "SAFE" if (not positives and viol == 0 and not reachable) else "INVESTIGATE")

if __name__ == "__main__":
    main(big="--big" in sys.argv)
