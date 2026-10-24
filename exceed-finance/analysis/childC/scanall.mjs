import { rpc } from "./rpc.mjs";
import fs from "node:fs";
const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const MINT = process.argv[2];
let all = [], before;
while (true) {
  const opts = { limit: 1000 };
  if (before) opts.before = before;
  const r = await rpc("getSignaturesForAddress", [MINT, opts]);
  if (!r.length) break;
  all = all.concat(r); before = r[r.length-1].signature;
  if (r.length < 1000) break;
}
console.log("total sigs:", all.length, "range:", new Date(all[all.length-1].blockTime*1000).toISOString(), "->", new Date(all[0].blockTime*1000).toISOString());
const counts = {};
const interesting = [];
async function one(s) {
  let tx;
  try { tx = await rpc("getTransaction", [s.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }]); }
  catch(e){ return null; }
  if (!tx) return null;
  const logs = tx.meta.logMessages || [];
  if (!logs.some(l=>l.includes(PROG))) return null;
  const instrs = logs.filter(l=>/Instruction: \w+/.test(l)).map(l=>(l.match(/Instruction: (\w+)/)||[])[1]);
  const uniq = [...new Set(instrs)];
  for (const i of uniq) counts[i] = (counts[i]||0)+1;
  return { sig: s.signature, slot: s.slot, blockTime: tx.blockTime, instrs: uniq, err: !!s.err };
}
const CONC = 5;
const out = [];
for (let i = 0; i < all.length; i += CONC) {
  const res = await Promise.all(all.slice(i,i+CONC).map(one));
  for (const r of res) if (r) out.push(r);
  if (i % 100 === 0) console.log("progress", i, "found", out.length);
}
console.log("exceed txs:", out.length);
console.log("instruction counts:", JSON.stringify(counts, null, 2));
fs.writeFileSync("scan-"+MINT.slice(0,6)+".json", JSON.stringify(out, null, 1));
for (const r of out) console.log(JSON.stringify(r));
