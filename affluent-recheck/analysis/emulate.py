"""Build TON messages and call tonapi read-only trace emulation. No broadcast."""
import base64, json, os, time
from pytoniq_core import MessageAny, InternalMsgInfo, Address, CurrencyCollection, Builder, Cell
from ton import post, TONAPI, get

OUT = os.path.join(os.path.dirname(__file__), "emul")
os.makedirs(OUT, exist_ok=True)

def addr(a):
    return Address(a)

def internal(src, dest, body, value=500_000_000, bounce=True):
    info = InternalMsgInfo(
        ihr_disabled=True, bounce=bounce, bounced=False,
        src=addr(src), dest=addr(dest),
        value=CurrencyCollection(grams=value),
        ihr_fee=0, fwd_fee=0, created_lt=0, created_at=0,
    )
    return MessageAny(info=info, init=None, body=body)

def boc64(msg):
    return base64.b64encode(msg.serialize().to_boc()).decode()

def emulate(msg, ignore_sig=True, tag="run"):
    payload = {"boc": boc64(msg), "ignore_signature_check": ignore_sig}
    r = post(f"{TONAPI}/traces/emulate", payload, retries=2)
    fn = os.path.join(OUT, f"{tag}.json")
    json.dump(r, open(fn, "w"), indent=1)
    return r

def burn_body(amount, response_dest):
    b = Builder()
    b.store_uint(0x595F07BC, 32)
    b.store_uint(0, 64)
    b.store_coins(amount)
    b.store_address(addr(response_dest))
    b.store_bit(0)          # custom_payload: nothing
    return b.end_cell()

def notify_body(amount, sender, forward_payload=None):
    """TEP-74 transfer_notification: op, query_id, amount, sender, forward_payload(Either)."""
    b = Builder()
    b.store_uint(0x7362D09C, 32)
    b.store_uint(0, 64)
    b.store_coins(amount)
    b.store_address(addr(sender))
    if forward_payload is None:
        b.store_bit(0)
    else:
        b.store_bit(0)
        b.store_ref(forward_payload)
    return b.end_cell()

def summarize(trace, max_nodes=80):
    """Flatten tonapi trace into readable rows."""
    rows = []
    def walk(node, depth=0):
        tx = node.get("transaction", {})
        im = tx.get("in_msg", {}) or {}
        op = im.get("op_code")
        src = (im.get("source") or {}).get("address")
        dst = (im.get("destination") or {}).get("address")
        dec = im.get("decoded_op_name") or im.get("operation") or ""
        val = im.get("value")
        rows.append({"d": depth, "hash": tx.get("hash", "")[:12], "src": src, "dst": dst,
                     "op": op, "name": dec, "value": val, "aborted": tx.get("aborted"),
                     "compute_exit": ((tx.get("description", {}) or {}).get("compute_ph", {}) or {}).get("exit_code"),
                     "action_result": (((tx.get("description", {}) or {}).get("action_ph", {}) or {}).get("result_code")),
                     "success": tx.get("success"),
                     "decoded_body": im.get("decoded_body")})
        for c in node.get("children", []) or []:
            walk(c, depth + 1)
    walk(trace.get("trace", trace))
    return rows

def show(trace):
    for r in summarize(trace):
        print("  " * r["d"] + f'{r["hash"]} {r["src"]}->{r["dst"]} op={r["op"]} {r["name"]} val={r["value"]} exit={r["compute_exit"]} act={r["action_result"]} ab={r["aborted"]}')

if __name__ == "__main__":
    import sys
    HOLDER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
    JW = "0:43d29f033007c7ba0e2a8a0bd6c3b0d4a33668d179bc8f3aafca7eea67f0b429"
    amt = int(sys.argv[1]) if len(sys.argv) > 1 else 1_000_000
    m = internal(HOLDER, JW, burn_body(amt, HOLDER))
    t = emulate(m, tag=f"burn_{amt}")
    show(t)
