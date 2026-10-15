#!/usr/bin/env python3
"""Decode marginfi v2 Bank accounts (layout of deployed v0.1.12-rc2, mrgnlabs/marginfi-v2 @ mrgn-0.1.12-rc2).
Bank struct: #[repr(C)] zero-copy, 3904 bytes (current) or 1856 bytes (v1 legacy prefix).
Account data = 8-byte Anchor discriminator + struct.
"""
import struct

I80F48_SCALE = float(1 << 48)

def i80f48(b):
    v = struct.unpack_from('<i', b)[0] if False else int.from_bytes(b, 'little', signed=True)
    return v / I80F48_SCALE

class R:
    def __init__(self, raw, base=0):
        self.raw = raw; self.o = base
    def u8(self): v = self.raw[self.o]; self.o += 1; return v
    def u16(self): v = struct.unpack_from('<H', self.raw, self.o)[0]; self.o += 2; return v
    def u32(self): v = struct.unpack_from('<I', self.raw, self.o)[0]; self.o += 4; return v
    def i32(self): v = struct.unpack_from('<i', self.raw, self.o)[0]; self.o += 4; return v
    def u64(self): v = struct.unpack_from('<Q', self.raw, self.o)[0]; self.o += 8; return v
    def i64(self): v = struct.unpack_from('<q', self.raw, self.o)[0]; self.o += 8; return v
    def i80f48(self): v = i80f48(self.raw[self.o:self.o+16]); self.o += 16; return v
    def i80f48_raw(self): v = int.from_bytes(self.raw[self.o:self.o+16], 'little', signed=True); self.o += 16; return v
    def pk(self):
        import base58
        v = base58.b58encode(self.raw[self.o:self.o+32]).decode(); self.o += 32; return v
    def skip(self, n): self.o += n

ORACLE_SETUP = {0:'None',1:'PythLegacy',2:'SwitchboardV2',3:'PythPushOracle',4:'SwitchboardPull',
 5:'StakedWithPythPush',6:'KaminoPythPush',7:'KaminoSwitchboardPull',8:'Fixed',9:'DriftPythPull',
 10:'DriftSwitchboardPull',11:'SolendPythPull',12:'SolendSwitchboardPull',13:'FixedKamino',
 14:'FixedDrift',15:'JuplendPythPull',16:'JuplendSwitchboardPull',17:'FixedJuplend',18:'Scope',
 19:'PythMSOL',20:'KaminoMSOL',21:'JuplendMSOL',22:'PythLST',23:'KaminoLST',24:'JuplendLST',
 25:'PTPyth',26:'PTFixed',27:'ScopeKamino',28:'ScopeJuplend'}
OP_STATE = {0:'Paused',1:'Operational',2:'ReduceOnly',3:'KilledByBankruptcy',4:'Uninitialized',5:'ReduceOnlyNoInitHealth'}

def decode_bank_config(r):
    c = {}
    c['asset_weight_init'] = r.i80f48()
    c['asset_weight_maint'] = r.i80f48()
    c['liability_weight_init'] = r.i80f48()
    c['liability_weight_maint'] = r.i80f48()
    c['deposit_limit'] = r.u64()
    irc_start = r.o
    irc = {}
    irc['placeholder0'] = r.i80f48(); irc['placeholder1'] = r.i80f48(); irc['placeholder2'] = r.i80f48()
    irc['insurance_fee_fixed_apr'] = r.i80f48()
    irc['insurance_ir_fee'] = r.i80f48()
    irc['protocol_fixed_fee_apr'] = r.i80f48()
    irc['protocol_ir_fee'] = r.i80f48()
    irc['protocol_origination_fee'] = r.i80f48()
    irc['zero_util_rate'] = r.u32()
    irc['hundred_util_rate'] = r.u32()
    irc['points'] = [(r.u32(), r.u32()) for _ in range(5)]
    irc['curve_type'] = r.u8()
    r.skip(7)   # _pad0
    r.skip(32)  # _padding1
    r.skip(16)  # _padding2
    r.skip(8)   # _padding3
    assert r.o - irc_start == 240, f"InterestRateConfig size {r.o-irc_start}"
    c['interest_rate_config'] = irc
    c['operational_state'] = OP_STATE.get(r.u8(), '?')
    c['oracle_setup'] = ORACLE_SETUP.get(r.u8(), '?')
    c['oracle_keys'] = [r.pk() for _ in range(5)]
    c['cb_window_max_up_bps'] = r.u16()
    c['cb_window_max_down_bps'] = r.u16()
    r.skip(2)
    c['borrow_limit'] = r.u64()
    c['risk_tier'] = {0:'Collateral',1:'Isolated'}.get(r.u8(), '?')
    c['asset_tag'] = r.u8()
    c['config_flags'] = r.u8()
    r.skip(1)
    c['cb_window_seconds'] = r.u32()
    c['total_asset_value_init_limit'] = r.u64()
    c['oracle_max_age'] = r.u16()
    c['scope_entry_index'] = r.u16()
    c['oracle_max_confidence'] = r.u32()
    c['fixed_price'] = r.i80f48()
    c['cb_deviation_bps_tiers'] = [r.u16() for _ in range(3)]
    c['cb_tier_durations_seconds'] = [r.u16() for _ in range(3)]
    c['cb_escalation_window_mult'] = r.u8()
    r.skip(1)
    c['cb_ema_alpha_bps'] = r.u16()
    return c

def decode_bank(raw):
    """raw = full account data (discriminator + struct)."""
    assert raw[:8] == bytes([142,49,166,242,50,66,97,188]), "not a Bank account"
    r = R(raw, 8)
    b = {}
    b['mint'] = r.pk()
    b['mint_decimals'] = r.u8()
    b['group'] = r.pk()
    r.skip(7)
    b['asset_share_value'] = r.i80f48()
    b['liability_share_value'] = r.i80f48()
    b['liquidity_vault'] = r.pk()
    b['liquidity_vault_bump'] = r.u8()
    b['liquidity_vault_authority_bump'] = r.u8()
    b['insurance_vault'] = r.pk()
    b['insurance_vault_bump'] = r.u8()
    b['insurance_vault_authority_bump'] = r.u8()
    r.skip(4)
    b['collected_insurance_fees_outstanding'] = r.i80f48()
    b['fee_vault'] = r.pk()
    b['fee_vault_bump'] = r.u8()
    b['fee_vault_authority_bump'] = r.u8()
    r.skip(6)
    b['collected_group_fees_outstanding'] = r.i80f48()
    b['total_liability_shares'] = r.i80f48()
    b['total_asset_shares'] = r.i80f48()
    b['last_update'] = r.i64()
    cfg_start = r.o
    b['config'] = decode_bank_config(r)
    assert r.o - cfg_start == 544, f"BankConfig size {r.o-cfg_start}"
    b['flags'] = r.u64()
    b['emissions_rate'] = r.u64()
    b['emissions_remaining'] = r.i80f48()
    b['emissions_mint'] = r.pk()
    b['collected_program_fees_outstanding'] = r.i80f48()
    em_start = r.o
    r.skip(424)  # EmodeSettings
    assert r.o - em_start == 424
    b['fees_destination_account'] = r.pk()
    cache_start = r.o
    cache = {}
    cache['base_rate'] = r.u32(); cache['lending_rate'] = r.u32(); cache['borrowing_rate'] = r.u32()
    cache['interest_accumulated_for'] = r.u32()
    cache['accumulated_since_last_update'] = r.i80f48()
    cache['last_oracle_price'] = r.i80f48()
    cache['last_oracle_price_timestamp'] = r.i64()
    cache['last_oracle_price_confidence'] = r.i80f48()
    cache['liq_cache_flags'] = r.u8()
    r.skip(7)
    cache['price_multiplier'] = r.i80f48()
    cache['liquidation_price_rt'] = r.i80f48()
    cache['liquidation_price_rt_confidence'] = r.i80f48()
    cache['liquidation_price_twap'] = r.i80f48()
    cache['liquidation_price_twap_confidence'] = r.i80f48()
    assert r.o - cache_start == 160
    b['cache'] = cache
    b['lending_position_count'] = r.i32()
    b['borrowing_position_count'] = r.i32()
    b['liquidation_liquidator_fee'] = r.u32()
    b['liquidation_insurance_fee'] = r.u32()
    r.skip(8)
    b['integration_acc_1'] = r.pk()
    b['integration_acc_2'] = r.pk()
    b['integration_acc_3'] = r.pk()
    rl_start = r.o
    rl = {}
    rl['hourly_max_outflow'] = r.u64(); rl['hourly_window_duration'] = r.u64(); rl['hourly_window_start'] = r.i64(); rl['hourly_prev_outflow'] = r.i64(); rl['hourly_cur_outflow'] = r.i64()
    rl['daily_max_outflow'] = r.u64(); rl['daily_window_duration'] = r.u64(); rl['daily_window_start'] = r.i64(); rl['daily_prev_outflow'] = r.i64(); rl['daily_cur_outflow'] = r.i64()
    assert r.o - rl_start == 80
    b['rate_limiter'] = rl
    b['collected_premium_outstanding'] = r.i80f48()
    b['bank_seed'] = r.u64()
    b['cb_halt_started_at'] = r.i64()
    b['cb_halt_ended_at'] = r.i64()
    b['cb_tier'] = r.u8()
    b['cb_tier3_consecutive_trips'] = r.u8()
    b['cb_pre_break_state'] = r.u8()
    r.skip(5)
    b['cb_last_observed_slot'] = r.u64()
    b['cb_last_oracle_source_time'] = r.i64()
    b['cb_reference_price'] = r.i80f48()
    b['cb_window_reference_price'] = r.i80f48()
    b['cb_window_started_at'] = r.i64()
    b['cb_frozen_seconds_pending'] = r.u64()
    b['premium_tag'] = r.u16()
    r.skip(6)
    b['premium_activated_at'] = r.i64()
    b['_struct_bytes_consumed'] = r.o - 8
    b['_account_bytes'] = len(raw)
    return b

if __name__ == "__main__":
    import json, base64, sys
    d = json.load(open(sys.argv[1]))
    if 'result' in d and isinstance(d['result'], dict) and 'value' in d['result']:
        accts = [(d['result']['value'].get('data',['','base64']), None)]
    else:
        accts = []
    raw = base64.b64decode(accts[0][0][0])
    print(json.dumps(decode_bank(raw), indent=2))
