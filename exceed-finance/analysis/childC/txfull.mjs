import { rpc } from "./rpc.mjs";
const sig = process.argv[2];
const tx = await rpc("getTransaction", [sig, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }]);
console.log("slot:", tx.slot, "blockTime:", tx.blockTime, new Date(tx.blockTime*1000).toISOString(), "err:", JSON.stringify(tx.meta.err));
for (const l of tx.meta.logMessages||[]) console.log("LOG", l);
