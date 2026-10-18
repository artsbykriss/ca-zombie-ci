const fs=require('fs');
const RPC=process.env.PHAROS_RPC||"https://rpc.pharos.xyz";
const calls=JSON.parse(fs.readFileSync(process.argv[2]));
const out=process.argv[3];
const BS=+(process.env.BS||5), DELAY=+(process.env.DELAY||350);
let res=fs.existsSync(out)?JSON.parse(fs.readFileSync(out)):new Array(calls.length);
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 for(let base=0;base<calls.length;base+=BS){
  const batch=calls.slice(base,base+BS);
  const todo=batch.map((c,i)=>({c,i:base+i})).filter(x=>!res[x.i]||res[x.i].ok!==true);
  if(!todo.length){ await sleep(20); continue; }
  const body=todo.map((x,k)=>({jsonrpc:"2.0",id:k,method:"eth_call",params:[{to:x.c.to,data:x.c.data},"latest"]}));
  let ok=false;
  for(let a=0;a<8&&!ok;a++){
   try{
    const r=await fetch(RPC,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(body)});
    const txt=await r.text(); let j; try{j=JSON.parse(txt);}catch(e){ await sleep(1500); continue; }
    const arr=Array.isArray(j)?j:[j];
    let rate=false;
    for(const x of arr){ if(x.error){ if(/cu limit|too fast|rate|429/i.test(x.error.message||"")){rate=true;break;} res[base+x.id]={ok:false,error:x.error.message}; } else res[base+x.id]={ok:true,result:x.result}; }
    if(!rate) ok=true; else await sleep(2000);
   }catch(e){ await sleep(1200); }
  }
  if(base%200===0){ console.error("progress",base,"/",calls.length); fs.writeFileSync(out,JSON.stringify(res)); }
  await sleep(DELAY);
 }
 fs.writeFileSync(out,JSON.stringify(res)); console.error("done",calls.length,"missing",res.filter(x=>!x).length);
})();
