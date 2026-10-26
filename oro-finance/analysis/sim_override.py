"""Simulate a Sell with simulation-only account-data overrides (no state is changed on-chain).
Funds the seller's GOLD ATA and the protocol USDC vault inside the simulation so the swap
can complete, letting us read the exact price the program pays out.

Read-only: simulateTransaction only. Nothing is signed or sent.
"""
import sys, json, base64
sys.path.insert(0, '.')
import rpc2
from sim_sell import build, simulate, show, SELL, SELL_DEFAULT, SELL_DATA


def acct_data(pk):
    v = rpc2.call("getAccountInfo", [pk, {"encoding": "base64"}])["value"]
    return bytearray(base64.b64decode(v["data"][0])), v["owner"], v["lamports"]


def tok_set_amount(raw, amount):
    raw = bytearray(raw)
    raw[64:72] = int(amount).to_bytes(8, 'little')
    return raw


def override(pk, raw, owner, lamports, executable=False):
    return {"pubkey": pk, "data": list(bytes(raw)), "owner": owner,
            "lamports": lamports, "executable": executable}


def main():
    vals = dict(SELL_DEFAULT)
    for kv in sys.argv[1:]:
        k, v = kv.split("=", 1)
        vals[k] = v

    ov = []
    # fund seller GOLD ata and protocol USDC vault
    gold_ata, o1, l1 = acct_data(vals["seller_ata_a"])
    ov.append(override(vals["seller_ata_a"], tok_set_amount(gold_ata, 10_000_000), o1, l1))
    usdc_vault, o2, l2 = acct_data(vals["vault_b"])
    ov.append(override(vals["vault_b"], tok_set_amount(usdc_vault, 100_000_000_000), o2, l2))
    gold_vault, o3, l3 = acct_data(vals["vault_a"])
    ov.append(override(vals["vault_a"], tok_set_amount(gold_vault, 0), o3, l3))

    b = build(SELL, vals, SELL_DATA)
    res = simulate(b, ov)
    v = show(res, "sell+override " + json.dumps({k: x for k, x in vals.items()
                                                 if x != SELL_DEFAULT.get(k)}))
    return v


if __name__ == "__main__":
    main()
