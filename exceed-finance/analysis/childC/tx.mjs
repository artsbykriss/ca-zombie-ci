import { rpc } from "./rpc.mjs";
const sig = process.argv[2];
const tx = await rpc("getTransaction", [sig, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }]);
if (!tx) { console.log("null tx"); process.exit(0); }
console.log("slot:", tx.slot, "blockTime:", tx.blockTime, new Date(tx.blockTime*1000).toISOString());
console.log("err:", JSON.stringify(tx.meta.err));
const logs = (tx.meta.logMessages||[]).filter(l=>l.includes("Instruction:")||l.includes("Program data:"));
for (const l of logs) console.log("LOG", l);
console.log("--- account keys (index: pubkey signer/writable) ---");
tx.transaction.message.accountKeys.forEach((k,i)=>{
  console.log(i, typeof k === 'string' ? k : k.pubkey, k.signer?"SIGNER":"", k.writable?"W":"");
});
console.log("--- preTokenBalances ---");
console.log(JSON.stringify(tx.meta.preTokenBalances,null,0));
console.log("--- postTokenBalances ---");
console.log(JSON.stringify(tx.meta.postTokenBalances,null,0));
