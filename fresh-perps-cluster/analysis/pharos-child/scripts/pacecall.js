// Sequential paced eth_call runner to avoid per-second CU limits.
const fs=require('fs');
const RPC=process.env.PHAROS_RPC||"https://rpc.pharos.xyz";
const calls=JSON.parse(fs.readFileSync(process.argv[2]));
const out=process.argv[3];
let res = fs.existsSync(out)?JSON.parse(fs.readFileSync(out)):new Array(calls.length);
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 let done=0, fail=0;
 for(let i=0;i<calls.length;i++){
  if(res[i] && res[i].ok) continue;
  let ok=false;
  for(let a=0;a<6 && !ok;a++){
   try{
    const r=await fetch(RPC,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({jsonrpc:"2.0",id:1,method:"eth_call",params:[{to:calls[i].to,data:calls[i].data},"latest"]})});
    const j=await r.json();
    if(j.error){ if(/cu limit|too fast|rate|429/i.test(j.error.message||"")){ await sleep(1200); continue;} res[i]={ok:false,error:j.error.message}; ok=true; }
    else { res[i]={ok:true,result:j.result}; ok=true; }
   }catch(e){ await sleep(800); }
  }
  if(!ok){fail++; res[i]=res[i]||{ok:false,error:"failed"};}
  done++;
  if(done%50===0){ console.error("progress",done,"/",calls.length,"fail",fail); fs.writeFileSync(out,JSON.stringify(res)); }
  await sleep(90);
 }
 fs.writeFileSync(out,JSON.stringify(res)); console.error("done",calls.length,"fail",fail);
})();
