def words(hexdata):
    h = hexdata[2:] if hexdata.startswith("0x") else hexdata
    return [h[i:i+64] for i in range(0, len(h), 64)]

def dec(word): return int(word, 16)
def addr(word): return "0x" + word[-40:]
def saddr(word): return "0x" + word[-40:]

def decode_poolinfos(hexdata):
    w = words(hexdata)
    off = dec(w[0]) // 32
    n = dec(w[off])
    out = []
    for i in range(n):
        base = off + 1 + i * 7
        cur0 = addr(w[base+0]); cur1 = addr(w[base+1])
        fee = dec(w[base+2]) & 0xFFFFFF
        tick = dec(w[base+3])
        if tick >= 2**23: tick -= 2**24
        hooks = addr(w[base+4])
        pid = "0x" + w[base+5]
        active = dec(w[base+6]) != 0
        out.append(dict(currency0=cur0, currency1=cur1, fee=fee, tickSpacing=tick, hooks=hooks, id=pid, active=active))
    return out

def decode_string(hexdata):
    w = words(hexdata)
    off = dec(w[0]) // 32
    ln = dec(w[off])
    h = hexdata[2:]
    raw = bytes.fromhex(h[(off+1)*64:(off+1)*64 + ln*2])
    return raw.decode('utf-8', 'replace')

def decode_address_array(hexdata):
    w = words(hexdata)
    n = dec(w[0])
    return [addr(w[1+i]) for i in range(n)]
