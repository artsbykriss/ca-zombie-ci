#!/usr/bin/env python3
"""Exact arbitrage check: PandaSwap pair vs live PancakeSwap pools (the real on-chain exit market).

For each PandaSwap pair (t0,t1):
  * direct Pancake pair (t0,t1) if it exists -> exact 2-pool arb
  * else Pancake pairs (t0,WBNB) and (t1,WBNB) -> exact 3-pool arb
  * else: no on-chain market -> arb = 0
PandaSwap fee 0.3% (997/1000), Pancake V2 fee 0.25% (9975/10000).
"""
WBNB = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
PKF = "0xca143ce32fe78f1f7019d7d551a6402fc5350c73"
ZERO = "0x0000000000000000000000000000000000000000"
SEL_GETPAIR = "0xe6a43905"
SEL_RESERVES = "0x0902f1ac"
SEL_TOKEN0 = "0x0dfe1681"


def out_amt(amount_in, r_in, r_out, fee_num, fee_den):
    if amount_in <= 0 or r_in <= 0 or r_out <= 0:
        return 0.0
    a = amount_in * fee_num
    return r_out * a / (r_in * fee_den + a)


def opt(fn, hi):
    lo = 0.0
    for _ in range(200):
        m1 = lo + (hi - lo) / 3
        m2 = hi - (hi - lo) / 3
        if fn(m1) < fn(m2):
            lo = m1
        else:
            hi = m2
    x = (lo + hi) / 2
    return x, fn(x)


class ArbEngine:
    def __init__(self, call, block_hex, decimals=None):
        self.call = call
        self.block = block_hex
        self.dec = {k.lower(): (v or 18) for k, v in (decimals or {}).items()}
        self.cache = {}

    def _dec(self, token):
        return self.dec.get(token.lower(), 18)

    def _pool(self, pair):
        """Returns (r0h, r1h, token0) in human units, or None."""
        if pair in self.cache:
            return self.cache[pair]
        r = self.call(pair, SEL_RESERVES, self.block)
        t0 = self.call(pair, SEL_TOKEN0, self.block)
        if not r or len(r) < 194 or not t0:
            self.cache[pair] = None
            return None
        t0 = "0x" + t0[-40:]
        r0 = int(r[2:66], 16) / 10 ** self._dec(t0)
        r1 = int(r[66:130], 16) / 10 ** self._dec(t0)  # placeholder; fixed below
        self.cache[pair] = None
        # need token1 decimals too
        t1 = self.call(pair, "0xd21220a7", self.block)
        t1 = "0x" + t1[-40:]
        r0 = int(r[2:66], 16) / 10 ** self._dec(t0)
        r1 = int(r[66:130], 16) / 10 ** self._dec(t1)
        self.cache[pair] = (r0, r1, t0.lower())
        return self.cache[pair]

    def pancake_market(self, t0, t1):
        gp = self.call(PKF, SEL_GETPAIR + t0[2:].rjust(64, "0") + t1[2:].rjust(64, "0"), self.block)
        pair = "0x" + gp[-40:] if gp and len(gp) >= 42 else None
        if pair and pair != ZERO and self._pool(pair):
            return ("direct", pair)
        p0 = self.call(PKF, SEL_GETPAIR + t0[2:].rjust(64, "0") + WBNB[2:].rjust(64, "0"), self.block)
        p1 = self.call(PKF, SEL_GETPAIR + t1[2:].rjust(64, "0") + WBNB[2:].rjust(64, "0"), self.block)
        p0 = "0x" + p0[-40:] if p0 and len(p0) >= 42 else None
        p1 = "0x" + p1[-40:] if p1 and len(p1) >= 42 else None
        if p0 and p1 and p0 != ZERO and p1 != ZERO and self._pool(p0) and self._pool(p1):
            return ("via", p0, p1)
        return None

    def compute(self, t0, t1, r0P, r1P, d0, d1, p0usd, p1usd, max_in_usd=200000.0):
        market = self.pancake_market(t0, t1)
        if not market:
            return {"route": "none", "profit_usd": 0.0}
        r0P_h, r1P_h = r0P / 10 ** d0, r1P / 10 ** d1
        F_P = (997, 1000)
        F_K = (9975, 10000)
        best = {"profit_usd": 0.0, "dir": None, "route": market[0]}

        def sell_on_pancake(token_in, token_out, amount_in):
            if market[0] == "direct":
                r0h, r1h, mt0 = self._pool(market[1])
                if mt0 == token_in.lower():
                    return out_amt(amount_in, r0h, r1h, *F_K)
                else:
                    return out_amt(amount_in, r1h, r0h, *F_K)
            # via WBNB: pick the pool that actually contains token_in first
            if token_in.lower() == t0.lower():
                p_in, p_out = market[1], market[2]
            else:
                p_in, p_out = market[2], market[1]
            a0h, a1h, at0 = self._pool(p_in)
            if at0 == token_in.lower():
                wbnb_out = out_amt(amount_in, a0h, a1h, *F_K)
            else:
                wbnb_out = out_amt(amount_in, a1h, a0h, *F_K)
            b0h, b1h, bt0 = self._pool(p_out)
            if bt0 == WBNB:
                return out_amt(wbnb_out, b0h, b1h, *F_K)
            else:
                return out_amt(wbnb_out, b1h, b0h, *F_K)

        def f1(in_t1):  # buy t0 in PandaSwap with t1, sell t0 on Pancake
            t0_out = out_amt(in_t1, r1P_h, r0P_h, *F_P)
            t1_back = sell_on_pancake(t0, t1, t0_out)
            return (t1_back - in_t1) * p1usd

        def f2(in_t0):  # buy t1 in PandaSwap with t0, sell t1 on Pancake
            t1_out = out_amt(in_t0, r0P_h, r1P_h, *F_P)
            t0_back = sell_on_pancake(t1, t0, t1_out)
            return (t0_back - in_t0) * p0usd

        def f3(in_t1):  # buy t0 on Pancake with t1, sell into PandaSwap
            t0_bought = sell_on_pancake(t1, t0, in_t1)
            t1_back = out_amt(t0_bought, r0P_h, r1P_h, *F_P)
            return (t1_back - in_t1) * p1usd

        def f4(in_t0):  # buy t1 on Pancake with t0, sell into PandaSwap
            t1_bought = sell_on_pancake(t0, t1, in_t0)
            t0_back = out_amt(t1_bought, r1P_h, r0P_h, *F_P)
            return (t0_back - in_t0) * p0usd

        for name, fn, price_in in [("Pbuy0_sell_pk", f1, p1usd), ("Pbuy1_sell_pk", f2, p0usd),
                                   ("pk_buy0_sellP", f3, p1usd), ("pk_buy1_sellP", f4, p0usd)]:
            if not price_in:
                continue
            hi = max_in_usd / price_in
            x, prof = opt(fn, hi)
            if prof > best["profit_usd"]:
                best = {"profit_usd": prof, "dir": name, "size_usd": x * price_in, "route": market[0]}
        return best
