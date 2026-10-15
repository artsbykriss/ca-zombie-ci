#!/usr/bin/env python3
"""Strict borsh decoder for spoo1 StakePool (v2.1.0 / commit 54cdceda) state.

Layout taken verbatim from program/src/state.rs @ 54cdceda5d77b06ea7cea6e18c99560212755ab1.
Fee struct is { denominator: u64, numerator: u64 }  <-- denominator FIRST.
"""
import base64, json, struct, sys, pathlib

HERE = pathlib.Path(__file__).resolve().parent
ANALYSIS = HERE.parent


class R:
    def __init__(self, b):
        self.b = b
        self.o = 0

    def take(self, n):
        v = self.b[self.o:self.o + n]
        assert len(v) == n, f"short read at {self.o} want {n} got {len(v)}"
        self.o += n
        return v

    def u8(self):
        return self.take(1)[0]

    def u32(self):
        return struct.unpack("<I", self.take(4))[0]

    def u64(self):
        return struct.unpack("<Q", self.take(8))[0]

    def i64(self):
        return struct.unpack("<q", self.take(8))[0]

    def vec_u8(self):
        n = self.u32()
        return self.take(n)

    def string(self):
        return self.vec_u8().decode("utf8", "replace")

    def pk(self):
        return b58(self.take(32))

    def opt_pk(self):
        t = self.u8()
        if t == 0:
            return None
        assert t == 1, f"bad Option tag {t}"
        return self.pk()

    def fee(self):
        # NB: denominator first per state.rs
        d = self.u64()
        n = self.u64()
        return {"denominator": d, "numerator": n, "ratio": (n / d if d else 0.0)}

    def future_fee(self):
        t = self.u8()
        if t == 0:
            return {"tag": "None"}
        assert t in (1, 2), f"bad FutureEpoch tag {t}"
        f = self.fee()
        f["tag"] = "One" if t == 1 else "Two"
        return f


_A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = _A[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s


def decode(data: bytes):
    r = R(data)
    st = {}
    st["account_type"] = {0: "Uninitialized", 1: "StakePool", 2: "ValidatorList"}.get(r.u8(), "?")
    st["manager"] = r.pk()
    st["staker"] = r.pk()
    st["stake_deposit_authority"] = r.pk()
    st["stake_withdraw_bump_seed"] = r.u8()
    st["validator_list"] = r.pk()
    st["reserve_stake"] = r.pk()
    st["pool_mint"] = r.pk()
    st["manager_fee_account"] = r.pk()
    st["token_program_id"] = r.pk()
    st["total_lamports"] = r.u64()
    st["pool_token_supply"] = r.u64()
    st["last_update_epoch"] = r.u64()
    st["lockup"] = {"unix_timestamp": r.i64(), "epoch": r.u64(), "custodian": r.pk()}
    st["epoch_fee"] = r.fee()
    st["next_epoch_fee"] = r.future_fee()
    st["preferred_deposit_validator_vote_address"] = r.opt_pk()
    st["preferred_withdraw_validator_vote_address"] = r.opt_pk()
    st["stake_deposit_fee"] = r.fee()
    st["stake_withdrawal_fee"] = r.fee()
    st["next_stake_withdrawal_fee"] = r.future_fee()
    st["stake_referral_fee"] = r.u8()
    st["sol_deposit_authority"] = r.opt_pk()
    st["sol_deposit_fee"] = r.fee()
    st["sol_referral_fee"] = r.u8()
    st["sol_withdraw_authority"] = r.opt_pk()
    st["sol_withdrawal_fee"] = r.fee()
    st["next_sol_withdrawal_fee"] = r.future_fee()
    st["last_epoch_pool_token_supply"] = r.u64()
    st["last_epoch_total_lamports"] = r.u64()
    st["_bytes_consumed"] = r.o
    st["_bytes_total"] = len(data)
    st["_tail_hex"] = data[r.o:].hex()
    return st


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else str(ANALYSIS / "raw_pool.b64")
    raw = pathlib.Path(src).read_text().strip()
    data = base64.b64decode(raw) if not raw.startswith("{") else None
    if data is None:
        data = base64.b64decode(json.loads(raw)["result"]["value"]["data"][0])
    st = decode(data)
    print(json.dumps(st, indent=2))
    lam = st["total_lamports"]
    sup = st["pool_token_supply"]
    print("\n== derived ==")
    print(f"total_lamports   = {lam} ({lam/1e9:.6f} SOL)")
    print(f"pool_token_supply= {sup} ({sup/1e9:.9f} pdSOL)")
    if sup:
        print(f"lamports/token   = {lam/sup:.9f}  (ceil={-(-lam//sup)})")


if __name__ == "__main__":
    main()
