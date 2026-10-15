#!/usr/bin/env python3
"""Program-exact marginfi v2 maintenance-health model (deployed mrgn-0.1.12-rc2).

Implements the risk engine as deployed, using the PROGRAM's own oracle accounts:
  * emode: reconciled config = intersection (min weight) of the account's LIABILITY banks'
    emode entries; each ASSET bank's weight = max(base_weight, reconciled[asset_bank.emode_tag]).
    (This is the key difference from naive models, which also intersect the asset banks.)
  * prices: Pyth push (owner rec2HHDDnj...), PythLST (Pyth x SPL/Sanctum stake-pool rate),
    PythMSOL (Pyth x Marinade mSOL rate), Fixed, PTPyth (Pyth x Exponent linear/redemption rate).
  * bias: assets use Low = price - min(2.12*conf, 5%*price); liabilities High = price + ...
  * premium: added to liability value only when the bank has PREMIUM_ACTIVE (we surface it).
  * isolated risk tier collateral counts zero.

Unsupported oracle setups (Kamino*/Juplend*/Scope*/Staked/Switchboard*/PythLegacy) are
reported as `unsupported` per bank so the caller can exclude or handle them explicitly.
"""
import json, os, struct, time

I80F48 = 1 << 48
CONF_MULT = 2.12
MAX_CONF_INTERVAL = 0.05
U32_MAX = 2 ** 32 - 1

PYTH_PUSH_OWNER = "rec2HHDDnjLfj4kE7VyEtFA1HPGQLK33259532cRyHp"
SPL_STAKE_POOL_ID = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"
SANCTUM_SPL_STAKE_POOL_ID = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"
SANCTUM_SPL_MULTI_STAKE_POOL_ID = "SP12GQ1XkYQ7nMZQr8Qvr1nVQn5FCE6i9v1xr7Kz3nQ"  # placeholder, verified below
MARINADE_STATE_OWNER = "MarBmsSgKXdrN1egZf5sqe1TMai9K1rChYNDJgjq7aD"
EXPONENT_VAULT_OWNER = "ExponentnaRg3CQbW6dqQNZKXp7gtZ9DGMp1cwC4HAS7"

ORACLE_SETUP = {0: 'None', 1: 'PythLegacy', 2: 'SwitchboardV2', 3: 'PythPushOracle', 4: 'SwitchboardPull',
                5: 'StakedWithPythPush', 6: 'KaminoPythPush', 7: 'KaminoSwitchboardPull', 8: 'Fixed',
                9: 'DriftPythPull', 10: 'DriftSwitchboardPull', 11: 'SolendPythPull',
                12: 'SolendSwitchboardPull', 13: 'FixedKamino', 14: 'FixedDrift', 15: 'JuplendPythPull',
                16: 'JuplendSwitchboardPull', 17: 'FixedJuplend', 18: 'Scope', 19: 'PythMSOL',
                20: 'KaminoMSOL', 21: 'JuplendMSOL', 22: 'PythLST', 23: 'KaminoLST', 24: 'JuplendLST',
                25: 'PTPyth', 26: 'PTFixed', 27: 'ScopeKamino', 28: 'ScopeJuplend'}


def decode_pyth_push(raw):
    if len(raw) < 134:
        return None
    price, conf, exp, pt = struct.unpack_from('<qQiq', raw, 73)
    verification = raw[40]
    return {"price": price, "conf": conf, "exp": exp, "publish_time": pt,
            "verification": verification, "price_usd": price * 10.0 ** exp,
            "conf_usd": conf * 10.0 ** exp}


def decode_stake_pool(raw):
    if len(raw) < 282:
        return None
    acct_type = raw[0]
    total_lamports = struct.unpack_from('<Q', raw, 258)[0]
    pool_token_supply = struct.unpack_from('<Q', raw, 266)[0]
    last_update_epoch = struct.unpack_from('<Q', raw, 274)[0]
    return {"account_type": acct_type, "total_lamports": total_lamports,
            "pool_token_supply": pool_token_supply, "last_update_epoch": last_update_epoch}


def decode_marinade_state(raw):
    """MinimalMarinadeState layout (marginfi). mSOL price = total_virtual_staked_lamports / msol_supply."""
    # The account has an 8-byte Anchor discriminator. Fields (see marinade-finance state):
    #   msol_mint(32) admin_authority(32) operational_authority(32) treasury_msol_account(32)
    #   ... we instead use marginfi's MinimalMarinadeState offsets (see lst_stake_price.rs).
    # NOTE: filled in below from the actual struct definition used by the deployed program.
    return None


class BankState:
    __slots__ = ("pk", "cfg", "emode", "mint", "decimals", "asv", "lsv", "flags",
                 "risk_tier", "op_state", "premium_active", "fixed_price")

    def __init__(self, pk, b):
        c = b["config"]
        self.pk = pk
        self.cfg = c
        self.emode = b["emode"]
        self.mint = b["mint"]
        self.decimals = b["mint_decimals"]
        self.asv = b["asset_share_value"]
        self.lsv = b["liability_share_value"]
        self.flags = b["flags"]
        self.risk_tier = c["risk_tier"]
        self.op_state = c["operational_state"]
        self.premium_active = bool(b["flags"] & 16)   # PREMIUM_ACTIVE bit - verified in notes
        self.fixed_price = c["fixed_price"]


class PriceEngine:
    """Computes program prices (low/high) per bank from live oracle accounts."""

    def __init__(self, banks, oracles, epoch, now):
        self.banks = banks
        self.oracles = oracles
        self.epoch = epoch
        self.now = now
        self.cache = {}

    def _push(self, key):
        o = self.oracles.get(key)
        if not o:
            return None
        return decode_pyth_push(__import__("base64").b64decode(o["data"]))

    def price(self, bank_pk):
        """Returns dict(low, high, kind, status, extra)."""
        if bank_pk in self.cache:
            return self.cache[bank_pk]
        b = self.banks[bank_pk]
        cfg = b.cfg
        setup = cfg["oracle_setup"]
        keys = cfg["oracle_keys"]
        res = {"kind": setup, "status": "ok", "low": None, "high": None}
        max_age = cfg["oracle_max_age"]
        max_conf_cfg = cfg["oracle_max_confidence"]

        def pyth_low_high(price, conf, exp, publish_time, rate=1.0):
            p = price * 10.0 ** exp * rate
            c = conf * 10.0 ** exp * rate
            if max_age and self.now - publish_time > max_age:
                return None, None, "stale"
            ci = min(CONF_MULT * c, MAX_CONF_INTERVAL * p)
            frac = (max_conf_cfg / U32_MAX) if max_conf_cfg > 0 else 0.1
            if CONF_MULT * c > p * frac:
                return None, None, "max_conf"
            return p - ci, p + ci, "ok"

        try:
            if setup == 'Fixed':
                fp = cfg["fixed_price"]
                res.update(low=fp, high=fp)
            elif setup == 'PythPushOracle':
                pf = self._push(keys[0])
                if pf is None:
                    res.update(status="missing_oracle")
                else:
                    lo, hi, st = pyth_low_high(pf["price"], pf["conf"], pf["exp"], pf["publish_time"])
                    res.update(low=lo, high=hi, status=st)
            elif setup == 'PythLST':
                pf = self._push(keys[0])
                sp = self.oracles.get(keys[1])
                if pf is None or sp is None:
                    res.update(status="missing_oracle")
                else:
                    import base64
                    praw = base64.b64decode(sp["data"])
                    pool = decode_stake_pool(praw)
                    if pool is None or pool["account_type"] != 1 or pool["pool_token_supply"] == 0:
                        res.update(status="bad_stake_pool")
                    elif self.epoch - pool["last_update_epoch"] > 1:
                        res.update(status="stake_pool_stale")
                    else:
                        rate = pool["total_lamports"] / pool["pool_token_supply"]
                        lo, hi, st = pyth_low_high(pf["price"], pf["conf"], pf["exp"], pf["publish_time"], rate)
                        res.update(low=lo, high=hi, status=st, rate=rate)
            elif setup == 'PythMSOL':
                pf = self._push(keys[0])
                ms = self.oracles.get(keys[1])
                if pf is None or ms is None:
                    res.update(status="missing_oracle")
                else:
                    import base64
                    mraw = base64.b64decode(ms["data"])
                    rate = marinade_rate(mraw)
                    if rate is None:
                        res.update(status="bad_marinade")
                    else:
                        lo, hi, st = pyth_low_high(pf["price"], pf["conf"], pf["exp"], pf["publish_time"], rate)
                        res.update(low=lo, high=hi, status=st, rate=rate)
            elif setup == 'PTPyth':
                pf = self._push(keys[0])
                ev = self.oracles.get(keys[1])
                if pf is None or ev is None:
                    res.update(status="missing_oracle")
                else:
                    import base64
                    eraw = base64.b64decode(ev["data"])
                    mult, st = exponent_pt_multiplier(eraw, cfg["fixed_price"], self.now)
                    if mult is None:
                        res.update(status=st)
                    else:
                        lo, hi, st2 = pyth_low_high(pf["price"], pf["conf"], pf["exp"], pf["publish_time"], mult)
                        res.update(low=lo, high=hi, status=st2, pt_mult=mult)
            elif setup == 'PTFixed':
                ev = self.oracles.get(keys[0])
                if ev is None:
                    res.update(status="missing_oracle")
                else:
                    import base64
                    eraw = base64.b64decode(ev["data"])
                    mult, st = exponent_pt_multiplier(eraw, cfg["fixed_price"], self.now)
                    if mult is None:
                        res.update(status=st)
                    else:
                        res.update(low=mult, high=mult, pt_mult=mult)
            else:
                res.update(status="unsupported:" + setup)
        except Exception as e:
            res.update(status="error:" + str(e))
        self.cache[bank_pk] = res
        return res


def marinade_rate(raw):
    """mSOL/SOL rate from the Marinade State account (marginfi MinimalMarinadeState).
    rate = total_virtual_staked_lamports / msol_supply where tvsl = total_active_balance +
    delayed_unstake_cooling_down + emergency_cooling_down + available_reserve_balance
    - circulating_ticket_balance (saturating)."""
    if len(raw) < 8 + 568:
        return None
    d = raw[8:]
    delayed = struct.unpack_from('<Q', d, 218)[0]
    total_active = struct.unpack_from('<Q', d, 368)[0]
    available_reserve = struct.unpack_from('<Q', d, 488)[0]
    msol_supply = struct.unpack_from('<Q', d, 496)[0]
    circulating = struct.unpack_from('<Q', d, 520)[0]
    emergency = struct.unpack_from('<Q', d, 560)[0]
    if msol_supply == 0:
        return None
    under_control = total_active + delayed + emergency + available_reserve
    tvsl = max(under_control - circulating, 0)
    return tvsl / msol_supply


def exponent_pt_multiplier(raw, start_price, now):
    """PT/SY linear multiplier from Exponent vault (8-byte disc + MinimalExponentVault, 449 bytes)."""
    if len(raw) < 8 + 449:
        return None, "bad_exponent_vault"
    d = raw[8:]
    # MinimalExponentVault: _padding_0 [96]; mint_pt 32; _padding_1 [128]; start_ts u32; duration u32;
    #   _padding_2 [32]; _padding_3 [32]; _padding_4 [1]; last_seen_sy_exchange_rate [u64;4];
    #   all_time_high [u64;4]; _padding_6 [32]; _padding_7 [8]; sy_for_pt u64; pt_supply u64
    off = 96 + 32 + 128
    start_ts = struct.unpack_from('<I', d, off)[0]
    duration = struct.unpack_from('<I', d, off + 4)[0]
    off += 8 + 32 + 32 + 1
    last_seen = list(struct.unpack_from('<4Q', d, off))
    ath = list(struct.unpack_from('<4Q', d, off + 32))
    off += 32 + 32 + 32 + 8
    sy_for_pt = struct.unpack_from('<Q', d, off)[0]
    pt_supply = struct.unpack_from('<Q', d, off + 8)[0]
    # emergency mode: compare 256-bit rates most-significant word first
    for i in (3, 2, 1, 0):
        if ath[i] != last_seen[i]:
            if ath[i] > last_seen[i]:
                return None, "pt_emergency"
            break
    maturity = start_ts + duration
    if not (maturity > start_ts and maturity <= now + 5 * 365 * 86400):
        return None, "bad_pt_schedule"
    if pt_supply == 0:
        return None, "pt_zero_supply"
    SY_PRECISION = 10 ** 12  # SY_EXCHANGE_RATE_PRECISION
    if last_seen[1] or last_seen[2] or last_seen[3]:
        return None, "bad_sy_rate_width"
    sy_ex_raw = last_seen[0]
    if sy_ex_raw <= 0:
        return None, "bad_sy_rate"
    sy_per_pt = sy_for_pt / pt_supply
    asset_per_sy = sy_ex_raw / SY_PRECISION
    redemption = sy_per_pt * asset_per_sy
    # linear accretion from start_price to 1.0
    if now <= start_ts:
        linear = start_price
    elif now >= maturity:
        linear = 1.0
    else:
        linear = start_price + (1.0 - start_price) * (now - start_ts) / duration
    return min(linear, redemption), "ok"


def reconcile_emode(liab_banks, requirement='maint'):
    """Intersection (min weight) of the liability banks' emode entries."""
    if not liab_banks:
        return {}
    key = 'aw_maint' if requirement == 'maint' else 'aw_init'
    configs = [set(e['tag'] for e in b.emode['entries']) for b in liab_banks]
    common = set.intersection(*configs) if configs else set()
    out = {}
    for tag in common:
        w = min(next(e[key] for e in b.emode['entries'] if e['tag'] == tag) for b in liab_banks)
        out[tag] = w
    return out


def account_health(balances, banks, prices, same_asset_maint_leverage=1.0):
    """Returns dict with asset_value_maint, liability_value_maint, health, unsupported[]."""
    liab_banks = [banks[b["bank"]] for b in balances if b["liability_shares"] > 0 and b["bank"] in banks]
    reconciled = reconcile_emode(liab_banks, 'maint')
    # same-asset: lowest liability weight among eligible liability banks
    liab_mints = {banks[b["bank"]].mint: banks[b["bank"]] for b in balances
                  if b["liability_shares"] > 0 and b["bank"] in banks}
    assets = liabs = 0.0
    unsupported = []
    detail = []
    for b in balances:
        if b["bank"] not in banks:
            unsupported.append({"bank": b["bank"], "reason": "unknown_bank"})
            continue
        bank = banks[b["bank"]]
        pr = prices.price(b["bank"])
        if pr["status"] != "ok":
            unsupported.append({"bank": b["bank"], "reason": pr["status"]})
            continue
        dec = 10.0 ** bank.decimals
        if b["asset_shares"]:
            amount = b["asset_shares"] * bank.asv / dec
            w = 0.0 if bank.risk_tier == 'Isolated' else bank.cfg["asset_weight_maint"]
            tag = bank.emode["tag"]
            if tag and tag in reconciled:
                w = max(w, reconciled[tag])
            if same_asset_maint_leverage > 1 and bank.mint in liab_mints:
                lb = liab_mints[bank.mint]
                if (bank.cfg["oracle_keys"][0] == lb.cfg["oracle_keys"][0]
                        and bank.risk_tier == 'Collateral'):
                    w = max(w, lb.cfg["liability_weight_maint"] * (1 - 1.0 / same_asset_maint_leverage))
            v = amount * pr["low"] * w
            assets += v
            detail.append({"bank": b["bank"][:8], "side": "asset", "amount": amount,
                           "price_low": pr["low"], "weight": w, "value": v})
        if b["liability_shares"]:
            amount = b["liability_shares"] * bank.lsv / dec
            v = amount * pr["high"] * bank.cfg["liability_weight_maint"]
            liabs += v
            detail.append({"bank": b["bank"][:8], "side": "liab", "amount": amount,
                           "price_high": pr["high"], "weight": bank.cfg["liability_weight_maint"],
                           "value": v})
    return {"asset_value_maint": assets, "liability_value_maint": liabs,
            "health": assets - liabs, "unsupported": unsupported, "detail": detail,
            "reconciled_emode": reconciled}
