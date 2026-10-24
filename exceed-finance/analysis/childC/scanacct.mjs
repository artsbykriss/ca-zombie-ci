import { rpc } from "./rpc.mjs";
import fs from "node:fs";
const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const ACCT = process.argv[2];
const TAG = process.argv[3] || ACCT.slice(0,6);
let all = [], before;
while (true) {
  const opts = { limit: 1000 };
  if (before) opts.before = before;
  const r = await rpc("getSignaturesForAddress", [ACCT, opts]);
  if (!r.length) break;
  all = all.concat(r); before = r[r.length-1].signature;
  if (r.length < 1000) break;
}
console.log("total sigs:", all.length);
let nulls = 0, oks = 0;
async function one(s) {
  let tx;
  try { tx = await rpc("getTransaction", [s.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }], 10); }
  catch(e){ nulls++; return null; }
  if (!tx) { nulls++; return null; }
  oks++;
  const logs = tx.meta.logMessages || [];
  const instrs = logs.filter(l=>/Instruction: \w+/.test(l)).map(l=>(l.match(/Instruction: (\w+)/)||[])[1]);
  const uniq = [...new Set(instrs)];
  const isExceed = logs.some(l=>l.includes(PROG));
  return { sig: s.signature, slot: s.slot, blockTime: tx.blockTime, isExceed, instrs: uniq, err: !!s.err };
}
const CONC = 4;
const out = [];
for (let i = 0; i < all.length; i += CONC) {
  const res = await Promise.all(all.slice(i,i+CONC).map(one));
  for (const r of res) if (r) out.push(r);
  await new Promise(r=>setTimeout(r,100));
  if (i % 200 === 0) console.log("progress", i, "ok", oks, "null", nulls);
}
console.log("done. ok:", oks, "null:", nulls);
fs.writeFileSync("scan-"+TAG+".json", JSON.stringify(out, null, 1));
const counts={};
for (const r of out) for (const i of r.instrs) counts[i]=(counts[i]||0)+1;
console.log("instruction counts:", JSON.stringify(counts,null,1));
console.log("--- non-err Exceed txs ---");
for (const r of out) if (r.isExceed && !r.err) console.log(JSON.stringify(r));
