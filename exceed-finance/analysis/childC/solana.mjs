import crypto from "node:crypto";
const ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
export function b58encode(buf) {
  let n = 0n; for (const b of buf) n = n * 256n + BigInt(b);
  let s = ""; while (n > 0n) { s = ALPH[Number(n % 58n)] + s; n /= 58n; }
  for (const b of buf) { if (b === 0) s = "1" + s; else break; }
  return s;
}
export function b58decode(str) {
  let n = 0n; for (const c of str) { const i = ALPH.indexOf(c); if (i < 0) throw new Error("bad b58"); n = n * 58n + BigInt(i); }
  const bytes = []; while (n > 0n) { bytes.unshift(Number(n % 256n)); n /= 256n; }
  for (const c of str) { if (c === "1") bytes.unshift(0); else break; }
  return Buffer.from(bytes);
}
export function shortvec(n) {
  const out = []; while (true) { let b = n & 0x7f; n >>= 7; if (n === 0) { out.push(b); break; } out.push(b | 0x80); } return Buffer.from(out);
}
export function anchorDisc(name) {
  return crypto.createHash("sha256").update("global:" + name).digest().subarray(0, 8);
}
// accounts: [{pubkey(base58), isSigner, isWritable}]
export function buildMessage(accounts, instructions, blockhashB58, versioned = true) {
  const signers = accounts.filter(a => a.isSigner);
  const writableNonSigner = accounts.filter(a => !a.isSigner && a.isWritable);
  const readonlyNonSigner = accounts.filter(a => !a.isSigner && !a.isWritable);
  const ordered = [...signers, ...writableNonSigner, ...readonlyNonSigner];
  const idx = new Map(ordered.map((a, i) => [a.pubkey, i]));
  const header = Buffer.from([signers.length, signers.filter(a => !a.isWritable).length, readonlyNonSigner.length]);
  let keys = shortvec(ordered.length);
  for (const a of ordered) keys = Buffer.concat([keys, b58decode(a.pubkey)]);
  const bh = b58decode(blockhashB58);
  let body = Buffer.concat([header, keys, bh]);
  body = Buffer.concat([body, shortvec(instructions.length)]);
  for (const ix of instructions) {
    let b = Buffer.from([idx.get(ix.programId)]);
    b = Buffer.concat([b, shortvec(ix.keys.length)]);
    for (const k of ix.keys) b = Buffer.concat([b, Buffer.from([idx.get(k.pubkey)])]);
    b = Buffer.concat([b, shortvec(ix.data.length), ix.data]);
    body = Buffer.concat([body, b]);
  }
  if (versioned) {
    body = Buffer.concat([Buffer.from([0x80]), body, shortvec(0)]); // version 0 + no address table lookups
  }
  return body;
}
export function buildTx(accounts, instructions, blockhashB58, versioned = true) {
  const msg = buildMessage(accounts, instructions, blockhashB58, versioned);
  const nSig = accounts.filter(a => a.isSigner).length;
  let tx = shortvec(nSig);
  for (let i = 0; i < nSig; i++) tx = Buffer.concat([tx, Buffer.alloc(64)]);
  return Buffer.concat([tx, msg]);
}
export const SYSTEM = "11111111111111111111111111111111";
export const TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
export const ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";
