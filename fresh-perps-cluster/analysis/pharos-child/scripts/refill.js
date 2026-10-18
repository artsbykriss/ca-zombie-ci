const fs=require('fs');
const RPC=process.env.PHAROS_RPC||"https://rpc.pharos.xyz";
const calls=JSON.parse(fs.readFileSync(process.argv[2]));
const res=JSON.parse(fs.readFileSync(process.argv[3]));
const idxs=[]; res.forEach((x,i)=>{ if(!x || (x.ok===false && /cu limit|too fast|rate/i.test(x.error||""))) idxs.push(i); });
console.log("refill",idxs.length);
let k=0;
async function worker(){
 while(k<idxs.length){
  const i=idxs[k++];
  for(let a=0;a<8;a++){
   try{
    const r=await fetch(RPC,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({jsonrpc:"2.0",id:1,method:"eth_call",params:[{to:calls[i].to,data:calls[i].data},"latest"]})});
    const j=await r.json();
    if(j.error){ if(/cu limit|too fast|rate/i.test(j.error.message||"")){ await new Promise(r=>setTimeout(r,1200)); continue;} res[i]={ok:false,error:j.error.message}; break; }
    res[i]={ok:true,result:j.result}; break;
   }catch(e){ await new Promise(r=>setTimeout(r,1000)); }
  }
  if(idxs.indexOf(i)%100===0) console.error("at",idxs.indexOf(i));
 }
}
(async()=>{ await Promise.all(Array.from({length:3},worker)); fs.writeFileSync(process.argv[3],JSON.stringify(res)); console.log("remaining null",res.filter(x=>!x).length); })();
