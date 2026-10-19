#!/usr/bin/env python3
"""Minimal read-only Pirate Chain P2P probe (no tx broadcast, no wallet)."""
import socket, ssl, struct, hashlib, time, sys, json

MAGIC = bytes.fromhex("f9eee48d")
PROTO = 170015
PEERS = [("137.184.0.170", 45452), ("143.244.145.109", 45452)]
CHECKPOINT_HASH = "00000000731ee33eecfb1a7ceb9de7f4576f95c724fc1ca3babce42c5c3c4171"  # height 3,817,031

def sha256d(b): return hashlib.sha256(hashlib.sha256(b).digest()).digest()
def revhex(h): return bytes.fromhex(h)[::-1]

def varint(n):
    if n < 0xfd: return bytes([n])
    if n <= 0xffff: return b"\xfd" + struct.pack("<H", n)
    if n <= 0xffffffff: return b"\xfe" + struct.pack("<I", n)
    return b"\xff" + struct.pack("<Q", n)

def read_varint(buf, off):
    b = buf[off]
    if b < 0xfd: return b, off+1
    if b == 0xfd: return struct.unpack_from("<H", buf, off+1)[0], off+3
    if b == 0xfe: return struct.unpack_from("<I", buf, off+1)[0], off+5
    return struct.unpack_from("<Q", buf, off+1)[0], off+9

def msg(cmd, payload):
    return MAGIC + cmd.encode().ljust(12, b"\x00") + struct.pack("<I", len(payload)) + sha256d(payload)[:4] + payload

def netaddr(ip="0.0.0.0", port=45452, services=1):
    # 8 services, 16 ip, 2 port BE
    return struct.pack("<Q", services) + b"\x00"*10 + b"\xff\xff" + socket.inet_aton(ip) + struct.pack(">H", port)

def version_payload():
    ua = b"/p2p-probe:0.1/"
    return (struct.pack("<i", PROTO) + struct.pack("<Q", 1) + struct.pack("<q", int(time.time()))
            + netaddr() + netaddr() + struct.pack("<Q", 0x1122334455667788)
            + varint(len(ua)) + ua + struct.pack("<i", 0) + b"\x00")

class Peer:
    def __init__(self, host, port):
        raw = socket.create_connection((host, port), timeout=20)
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        ctx.minimum_version = ssl.TLSVersion.TLSv1_3
        ctx.maximum_version = ssl.TLSVersion.TLSv1_3
        self.s = ctx.wrap_socket(raw)
        self.s.settimeout(30)
        self.buf = b""
    def send(self, cmd, payload=b""):
        self.s.sendall(msg(cmd, payload))
    def recv_msg(self):
        while True:
            if len(self.buf) >= 24:
                if self.buf[:4] != MAGIC:
                    i = self.buf.find(MAGIC)
                    if i < 0:
                        self.buf = self.buf[-3:]
                    else:
                        self.buf = self.buf[i:]
                if len(self.buf) >= 24:
                    clen = struct.unpack_from("<I", self.buf, 16)[0]
                    if len(self.buf) >= 24 + clen:
                        cmd = self.buf[4:16].rstrip(b"\x00").decode(errors="replace")
                        payload = self.buf[24:24+clen]
                        self.buf = self.buf[24+clen:]
                        return cmd, payload
            d = self.s.recv(65536)
            if not d: raise EOFError("peer closed")
            self.buf += d
    def handshake(self, timeout=30):
        self.send("version", version_payload())
        got_version = False
        t0 = time.time()
        while time.time() - t0 < timeout:
            cmd, payload = self.recv_msg()
            if cmd == "version":
                got_version = True
                try:
                    off = 4+8+8+26+26+8
                    ualen, off = read_varint(payload, off)
                    off += ualen
                    height = struct.unpack_from("<i", payload, off)[0]
                    self.peer_height = height
                except Exception:
                    self.peer_height = None
                self.send("verack")
            elif cmd == "verack":
                if got_version: return True
            elif cmd in ("ping",):
                self.send("pong", payload)
        return False

def parse_headers(payload):
    n, off = read_varint(payload, 0)
    out = []
    for _ in range(n):
        start = off
        off += 140
        slen, off = read_varint(payload, off)
        off += slen
        raw = payload[start:off]
        out.append((hashlib.sha256(hashlib.sha256(raw).digest()).digest()[::-1].hex(),
                    raw[:4], raw[4:36][::-1].hex(), struct.unpack_from("<I", raw, 100)[0],
                    struct.unpack_from("<I", raw, 104)[0], raw))
    return out, off

if __name__ == "__main__":
    for host, port in PEERS:
        print("trying", host, port)
        try:
            p = Peer(host, port)
            ok = p.handshake()
            print("handshake", ok, "peer_height", getattr(p, "peer_height", None))
            loc = [revhex(CHECKPOINT_HASH)]
            payload = struct.pack("<i", PROTO) + varint(len(loc)) + b"".join(loc) + b"\x00"*32
            p.send("getheaders", payload)
            t0 = time.time()
            while time.time() - t0 < 60:
                cmd, pl = p.recv_msg()
                print("msg", cmd, "len", len(pl))
                if cmd == "headers":
                    hs, off = parse_headers(pl)
                    print("headers", len(hs), "first", hs[0][0] if hs else None, "last", hs[-1][0] if hs else None,
                          "time", hs[0][3] if hs else None, hs[-1][3] if hs else None)
                    break
                if cmd == "ping": p.send("pong", pl)
            p.s.close()
        except Exception as e:
            print("ERR", type(e).__name__, e)
