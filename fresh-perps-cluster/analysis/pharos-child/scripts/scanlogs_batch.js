// Batched eth_getLogs scanner: 1000-block windows, 20 windows per HTTP batch.
const fs=require("fs");
const RPC=process.env.PHAROS_RPC||"https://rpc.pharos.xyz";
const addr=process.argv[2], topic0=process.argv[3], from=+process.argv[4], to=+process.argv[5], out=process.argv[6];
const ranges=[]; for(let s=from;s<=to;s+=1000) ranges.push([s,Math.min(s+999,to)]);
const BS=20, CONC=3; let idx=0; const results=[]; let errs=0;
async function worker(){
 while(idx<ranges.length){
  const base=idx; idx+=BS; const batch=ranges.slice(base,base+BS);
  const body=batch.map(([a,b],i)=>({jsonrpc:"2.0",id:i,method:"eth_getLogs",params:[{address:addr,fromBlock:"0x"+a.toString(16),toBlock:"0x"+b.toString(16),topics:[topic0]}]}));
  let ok=false;
  for(let att=0;att<6 && !ok;att++){
   try{
    const r=await fetch(RPC,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json(); const arr=Array.isArray(j)?j:[j];
    let bad=false;
    for(const x of arr){ if(x.error){bad=true;break;} if(Array.isArray(x.result)) results.push(...x.result); }
    if(bad){ if(/range|limit|fast|cu /i.test(JSON.stringify(arr.find(x=>x.error)?.error||""))){ await new Promise(r=>setTimeout(r,500)); continue; } }
    ok=true;
   }catch(e){ await new Promise(r=>setTimeout(r,800)); }
  }
  if(!ok){errs++; console.error("FAILED batch at",base);}
  if(base%200===0) console.error("progress",base,"/",ranges.length,"logs",results.length);
 }
}
(async()=>{await Promise.all(Array.from({length:CONC},worker)); results.sort((a,b)=>parseInt(a.blockNumber,16)-parseInt(b.blockNumber,16)); fs.writeFileSync(out,JSON.stringify({count:results.length,logs:results})); console.error("done",results.length,"errs",errs);})();
