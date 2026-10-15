#!/usr/bin/env python3
"""Decode marginfi MarginfiAccount (layout of v0.1.12, 2304-byte struct + 8-byte disc).
MarginfiAccount: group(32) authority(32) lending_account(1728) account_flags(8)
  emissions_destination(32) health_cache(304) migrated_from(32) migrated_to(32) last_update(8)
  account_index(2) third_party_index(2) bump(1) active_orders(1) _pad0(2) liquidation_record(32)
  indexer_flags(24) rebalance_execution_seq(8) liquidation_tagged_at(8) _padding0(16)
LendingAccount: balances[16] (104 each), last_tag_used u16, _pad1[6], _padding[7 x u64]
Balance: active u8, bank_pk(32), bank_asset_tag u8, tag u16, premium_rate_snapshot u32,
  asset_shares(16), liability_shares(16), premium_outstanding(16), last_update u64, _padding u64
HealthCache: 6 x I80F48, timestamp i64, flags u32, mrgn_err u32, prices[[u8;8];16], internal_err u32,
  err_index u8, program_version u8, pad0[2], internal_liq_err u32, internal_bankruptcy_err u32,
  reserved0[32], reserved1[16]
"""
import struct

I80F48_SCALE = float(1 << 48)
def i80f48(b): return int.from_bytes(b, 'little', signed=True) / I80F48_SCALE

class R:
    def __init__(self, raw, base=0): self.raw = raw; self.o = base
    def u8(self): v = self.raw[self.o]; self.o += 1; return v
    def u16(self): v = struct.unpack_from('<H', self.raw, self.o)[0]; self.o += 2; return v
    def u32(self): v = struct.unpack_from('<I', self.raw, self.o)[0]; self.o += 4; return v
    def u64(self): v = struct.unpack_from('<Q', self.raw, self.o)[0]; self.o += 8; return v
    def i64(self): v = struct.unpack_from('<q', self.raw, self.o)[0]; self.o += 8; return v
    def i80f48(self): v = i80f48(self.raw[self.o:self.o+16]); self.o += 16; return v
    def pk(self):
        import base58
        v = base58.b58encode(self.raw[self.o:self.o+32]).decode(); self.o += 32; return v
    def skip(self, n): self.o += n

def decode_balance(r):
    b = {}
    b["active"] = r.u8()
    b["bank"] = r.pk()
    b["bank_asset_tag"] = r.u8()
    b["tag"] = r.u16()
    b["premium_rate_snapshot"] = r.u32()
    b["asset_shares"] = r.i80f48()
    b["liability_shares"] = r.i80f48()
    b["premium_outstanding"] = r.i80f48()
    b["last_update"] = r.u64()
    r.skip(8)
    return b

def decode_health_cache(r):
    h = {}
    h["asset_value_init"] = r.i80f48()
    h["liability_value_init"] = r.i80f48()
    h["asset_value_maint"] = r.i80f48()
    h["liability_value_maint"] = r.i80f48()
    h["asset_value_equity"] = r.i80f48()
    h["liability_value_equity"] = r.i80f48()
    h["timestamp"] = r.i64()
    h["flags"] = r.u32()
    h["mrgn_err"] = r.u32()
    h["prices"] = [struct.unpack('<d', bytes(r.raw[r.o+i*8:r.o+i*8+8]))[0] for i in range(16)]
    r.skip(128)
    h["internal_err"] = r.u32()
    h["err_index"] = r.u8()
    h["program_version"] = r.u8()
    r.skip(2)
    h["internal_liq_err"] = r.u32()
    h["internal_bankruptcy_err"] = r.u32()
    r.skip(48)
    return h

def decode_account(raw, with_balances=True):
    assert raw[:8] == bytes([67,178,130,109,126,114,28,42]), "not a MarginfiAccount"
    r = R(raw, 8)
    a = {}
    a["group"] = r.pk()
    a["authority"] = r.pk()
    if with_balances:
        a["balances"] = [decode_balance(r) for _ in range(16)]
    else:
        r.skip(16 * 104)
    r.skip(8)  # last_tag_used + pad
    r.skip(56)  # lending account padding
    a["account_flags"] = r.u64()
    a["emissions_destination_account"] = r.pk()
    a["health_cache"] = decode_health_cache(r)
    a["migrated_from"] = r.pk()
    a["migrated_to"] = r.pk()
    a["last_update"] = r.u64()
    a["account_index"] = r.u16()
    a["third_party_index"] = r.u16()
    a["bump"] = r.u8()
    a["active_orders"] = r.u8()
    r.skip(2)
    a["liquidation_record"] = r.pk()
    a["indexer_flags"] = r.raw[r.o:r.o+24].hex(); r.skip(24)
    a["rebalance_execution_seq"] = r.u64()
    a["liquidation_tagged_at"] = r.i64()
    r.skip(16)
    a["_consumed"] = r.o - 8
    return a

if __name__ == "__main__":
    import json, base64, sys
    d = json.load(open(sys.argv[1]))["result"]["value"]
    raw = base64.b64decode(d["data"][0])
    a = decode_account(raw)
    print(json.dumps(a, indent=1))
