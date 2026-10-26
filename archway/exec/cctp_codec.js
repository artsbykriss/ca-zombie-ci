/* Minimal circle.cctp.v1.MsgDepositForBurn protobuf codec (no external deps).
 * Fields: 1 from(string), 2 amount(string), 3 destination_domain(uint32),
 *         4 mint_recipient(bytes32), 5 burn_token(string). */
"use strict";

function varint(n) {
  const out = [];
  let v = n >>> 0;
  while (v > 0x7f) {
    out.push((v & 0x7f) | 0x80);
    v >>>= 7;
  }
  out.push(v);
  return Buffer.from(out);
}

function tag(field, wire) {
  return varint((field << 3) | wire);
}

function encode(msg) {
  const parts = [];
  const str = (f, s) => {
    const b = Buffer.from(s, "utf8");
    parts.push(tag(f, 2), varint(b.length), b);
  };
  const bytes = (f, b) => parts.push(tag(f, 2), varint(b.length), b);
  const uint32 = (f, n) => parts.push(tag(f, 0), varint(n));
  str(1, msg.from);
  str(2, String(msg.amount));
  uint32(3, msg.destinationDomain >>> 0);
  bytes(4, Buffer.from(msg.mintRecipient));
  str(5, msg.burnToken);
  return Buffer.concat(parts);
}

function readVarint(buf, pos) {
  let shift = 0;
  let v = 0;
  while (true) {
    const b = buf[pos++];
    v |= (b & 0x7f) << shift;
    if ((b & 0x80) === 0) break;
    shift += 7;
  }
  return [v >>> 0, pos];
}

function decode(buf) {
  const b = Buffer.from(buf);
  const out = { from: "", amount: "", destinationDomain: 0, mintRecipient: new Uint8Array(), burnToken: "" };
  let pos = 0;
  while (pos < b.length) {
    let key;
    [key, pos] = readVarint(b, pos);
    const field = key >> 3;
    const wire = key & 7;
    if (wire === 2) {
      let len;
      [len, pos] = readVarint(b, pos);
      const val = b.subarray(pos, pos + len);
      pos += len;
      if (field === 1) out.from = val.toString("utf8");
      else if (field === 2) out.amount = val.toString("utf8");
      else if (field === 4) out.mintRecipient = new Uint8Array(val);
      else if (field === 5) out.burnToken = val.toString("utf8");
    } else if (wire === 0) {
      let v;
      [v, pos] = readVarint(b, pos);
      if (field === 3) out.destinationDomain = v;
    } else {
      throw new Error(`unsupported wire type ${wire} for field ${field}`);
    }
  }
  return out;
}

module.exports = { encode, decode };
