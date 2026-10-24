import { rpc } from "./rpc.mjs";
const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const MINT = process.argv[2] || "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z";
const MAXSIG = parseInt(process.argv[3] || "80", 10);
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
const results = [];
async function one(s) {
  if (s.err) return null;
  let tx;
  try { tx = await rpc("getTransaction", [s.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }]); }
  catch(e){ return null; }
  if (!tx) return null;
  const logs = tx.meta.logMessages || [];
  const exceedLogs = logs.filter(l => l.includes(PROG));
  const instr = logs.filter(l => /Instruction: \w+/.test(l)).map(l=>(l.match(/Instruction: (\w+)/)||[])[1]);
  const involveExceed = logs.some(l=>l.includes(PROG));
  return { sig: s.signature, slot: s.slot, blockTime: tx.blockTime, involveExceed, instr,
    hasStake: instr.includes("Stake"), hasReqW: instr.includes("RequestWithdraw"), hasExecW: instr.includes("ExecuteWithdraw"),
    exceedLogs: exceedLogs.slice(0,4) };
}
const CONC = 4;
for (let i = 0; i < all.length; i += CONC) {
  const batch = all.slice(i, i+CONC);
  const res = await Promise.all(batch.map(one));
  for (const r of res) if (r && r.involveExceed) results.push(r);
  await new Promise(r=>setTimeout(r,150));
}
console.log("scanned:", all.length, "exceed-involving:", results.length);
for (const r of results) console.log(JSON.stringify(r));
