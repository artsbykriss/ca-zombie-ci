#!/usr/bin/env python3
"""Decode Pyth push-oracle price accounts (owner rec2HHDDnj..., 134 bytes) and
Pyth legacy price accounts (owner FsJ3A3u2..., PriceAccount v2).
Usage: python3 decode_feed.py <account-json-file>"""
import json, base64, struct, time, sys

def decode_push(raw):
    out = {"kind": "pyth_push", "len": len(raw)}
    out["disc"] = raw[:8].hex()
    out["write_authority"] = raw[8:40].hex()
    out["verification"] = raw[40]
    out["feed_id"] = raw[41:73].hex()
    price, conf, exp, pt, prev, ema, emac = struct.unpack_from('<qQiqqqQ', raw, 73)
    out.update(price=price, conf=conf, exponent=exp, publish_time=pt, prev_publish_time=prev,
               ema_price=ema, ema_conf=emac, price_usd=price * 10.0 ** exp,
               ema_usd=ema * 10.0 ** exp, conf_usd=conf * 10.0 ** exp)
    out["posted_slot"] = struct.unpack_from('<Q', raw, 125)[0]
    out["age_s"] = int(time.time()) - pt
    return out

def decode_legacy(raw):
    magic, version, atype, size, ptype, exponent = struct.unpack_from('<IIIIIi', raw, 0)
    num, num_qt = struct.unpack_from('<qq', raw, 24)
    last_slot, valid_slot = struct.unpack_from('<QQ', raw, 40)
    ema_price, ema_conf = struct.unpack_from('<qq', raw, 56)
    timestamp, min_pub = struct.unpack_from('<qq', raw, 72)
    return {"kind": "pyth_legacy", "len": len(raw), "magic": hex(magic), "exponent": exponent,
            "price": num, "price_usd": num * 10.0 ** exponent, "confidence": num_qt,
            "ema_price": ema_price, "ema_usd": ema_price * 10.0 ** exponent,
            "last_slot": last_slot, "valid_slot": valid_slot, "timestamp": timestamp,
            "status": raw[88] if len(raw) > 88 else None, "age_s": int(time.time()) - timestamp}

if __name__ == "__main__":
    raw = base64.b64decode(json.load(open(sys.argv[1]))["result"]["value"]["data"][0])
    print(json.dumps(decode_push(raw), indent=1))
