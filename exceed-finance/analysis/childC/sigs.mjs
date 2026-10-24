import { rpc } from "./rpc.mjs";
const MINT = process.argv[2] || "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z";
let all = [];
let before;
for (let i = 0; i < 6; i++) {
  const opts = { limit: 100 };
  if (before) opts.before = before;
  const r = await rpc("getSignaturesForAddress", [MINT, opts]);
  if (!r.length) break;
  all = all.concat(r);
  before = r[r.length - 1].signature;
  if (r.length < 100) break;
}
console.log("total sigs:", all.length);
for (const s of all.slice(0, 60)) {
  console.log(s.slot, new Date((s.blockTime||0)*1000).toISOString(), s.err ? "ERR" : "ok", s.signature);
}
