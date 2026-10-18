// Batch eth_call helper. Input: JSON file [{to,data}]. Output: JSON [{ok,result|error}]
const fs = require('fs');
const RPC = process.env.PHAROS_RPC || "https://rpc.pharos.xyz";
const inp = JSON.parse(fs.readFileSync(process.argv[2]));
const out = process.argv[3];
const BS = 40, CONC = 4;
let idx = 0; const res = new Array(inp.length);
async function one(batch, base) {
  const body = batch.map((c,i)=>({jsonrpc:"2.0",id:base+i,method:"eth_call",params:[{to:c.to,data:c.data},"latest"]}));
  for (let a=0;a<5;a++) {
    try {
      const r = await fetch(RPC,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(body)});
      const j = await r.json();
      const arr = Array.isArray(j)?j:[j];
      for (const x of arr) { const i = x.id - base; res[base+i] = x.error ? {ok:false,error:x.error.message} : {ok:true,result:x.result}; }
      return;
    } catch(e) { await new Promise(r=>setTimeout(r,700*(a+1))); }
  }
  for (let i=0;i<batch.length;i++) res[base+i] = {ok:false,error:"fetch_failed"};
}
async function worker(){ while(idx<inp.length){ const base=idx; idx+=BS; await one(inp.slice(base,base+BS),base); if(base%400===0) console.error("progress",base,"/",inp.length);} }
(async()=>{ await Promise.all(Array.from({length:CONC},worker)); fs.writeFileSync(out,JSON.stringify(res)); console.error("done",res.length); })();
