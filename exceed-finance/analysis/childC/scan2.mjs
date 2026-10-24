import { rpc } from "./rpc.mjs";
const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const MINT = process.argv[2];
const MAXSIG = parseInt(process.argv[3] || "300", 10);
let all = [], before;
while (all.length < MAXSIG) {
  const opts = { limit: 100 };
  if (before) opts.before = before;
  const r = await rpc("getSignaturesForAddress", [MINT, opts]);
  if (!r.length) break;
  all = all.concat(r); before = r[r.length-1].signature;
  if (r.length < 100) break;
}
all = all.slice(0, MAXSIG);
console.log("sig count fetched:", all.length, "oldest slot:", all[all.length-1].slot, new Date(all[all.length-1].blockTime*1000).toISOString());
const counts = {};
const interesting = [];
async function one(s) {
  let tx;
  try { tx = await rpc("getTransaction", [s.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }]); }
  catch(e){ return null; }
  if (!tx) return null;
  const logs = tx.meta.logMessages || [];
  if (!logs.some(l=>l.includes(PROG))) return null;
  const instrs = logs.filter(l=>l.includes(PROG) && /Instruction: \w+/.test(l)).map(l=>(l.match(/Instruction: (\w+)/)||[])[1]);
  for (const i of instrs) counts[i] = (counts[i]||0)+1;
  return { sig: s.signature, slot: s.slot, blockTime: tx.blockTime, instrs, err: !!s.err };
}
const CONC = 4;
const out = [];
for (let i = 0; i < all.length; i += CONC) {
  const res = await Promise.all(all.slice(i,i+CONC).map(one));
  for (const r of res) if (r) out.push(r);
  await new Promise(r=>setTimeout(r,120));
}
console.log("exceed txs:", out.length);
console.log("instruction counts:", JSON.stringify(counts, null, 2));
for (const r of out) console.log(JSON.stringify(r));
