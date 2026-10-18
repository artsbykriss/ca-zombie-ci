// Read-only log scanner for Pharos via public dRPC (10k block windows).
const RPC = process.env.PHAROS_RPC || "https://pharos.drpc.org";
const addr = process.argv[2];
const topic0 = process.argv[3];
const from = parseInt(process.argv[4]);
const to = parseInt(process.argv[5]);
const out = process.argv[6];
const STEP = 9999;
const CONC = 12;
const fs = require('fs');
const chunks = [];
for (let s = from; s <= to; s += STEP) chunks.push([s, Math.min(s + STEP - 1, to)]);
let idx = 0, results = [], errors = 0;
async function worker() {
  while (idx < chunks.length) {
    const i = idx++;
    const [a, b] = chunks[i];
    for (let attempt = 0; attempt < 4; attempt++) {
      try {
        const r = await fetch(RPC, {method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({jsonrpc:"2.0",id:i,method:"eth_getLogs",params:[{address:addr,fromBlock:"0x"+a.toString(16),toBlock:"0x"+b.toString(16),topics:[topic0]}]})});
        const j = await r.json();
        if (j.error) { if (/rate|limit|too many/i.test(j.error.message||"")) { await new Promise(r=>setTimeout(r,1500)); continue; } throw new Error(JSON.stringify(j.error)); }
        results.push(...j.result);
        break;
      } catch(e) { if (attempt===3) { errors++; console.error("ERR",a,b,e.message); } else await new Promise(r=>setTimeout(r,800)); }
    }
    if (i % 200 === 0) console.error("progress", i, "/", chunks.length, "logs", results.length);
  }
}
(async()=>{ await Promise.all(Array.from({length:CONC},worker)); results.sort((x,y)=>parseInt(x.blockNumber,16)-parseInt(y.blockNumber,16)); fs.writeFileSync(out, JSON.stringify({count:results.length,logs:results},null,0)); console.error("done", results.length, "errors", errors); })();
