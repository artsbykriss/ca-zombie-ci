import { rpc, rpcNotNull } from "./rpc.mjs";
import { buildTx, b58encode, b58decode, anchorDisc, SYSTEM, TOKEN, ATA } from "./solana.mjs";
import crypto from "node:crypto";

const BLOCKHASH = process.argv[2] || null;

export async function simulate(accounts, instructions, opts = {}) {
  let bh = opts.blockhash || BLOCKHASH;
  if (!bh) {
    const bhs = await rpcNotNull("getLatestBlockhash", [{ commitment: "finalized" }]);
    bh = bhs.value.blockhash;
  }
  const tx = buildTx(accounts, instructions, bh);
  const params = [tx.toString("base64"), {
    encoding: "base64",
    sigVerify: false,
    replaceRecentBlockhash: true,
    commitment: "processed",
  }];
  const res = await rpcNotNull("simulateTransaction", params, 12);
  return res;
}
export function freshPubkey() { return b58encode(crypto.randomBytes(32)); }

if (import.meta.url === `file://${process.argv[1]}`) {
  // standalone: run update_pair_limits tests
  const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
  const PAIR = "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7";
  const AC = "fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe";
  const REAL_AUTH = "WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ";
  const disc = anchorDisc("update_pair_limits");
  // all params None
  const data = Buffer.concat([disc, Buffer.from([0,0,0,0,0])]);
  async function run(auth, label) {
    const accounts = [
      { pubkey: auth, isSigner: true, isWritable: false },
      { pubkey: PAIR, isSigner: false, isWritable: true },
      { pubkey: AC, isSigner: false, isWritable: false },
      { pubkey: PROG, isSigner: false, isWritable: false },
    ];
    const ix = { programId: PROG, keys: [
      { pubkey: PAIR, isSigner: false, isWritable: true },
      { pubkey: auth, isSigner: true, isWritable: false },
      { pubkey: AC, isSigner: false, isWritable: false },
    ], data };
    const res = await simulate(accounts, [ix]);
    console.log("=== " + label + " (authority=" + auth + ") ===");
    console.log("err:", JSON.stringify(res.value.err));
    console.log("unitsConsumed:", res.value.unitsConsumed);
    const logs = (res.value.logs || []);
    for (const l of logs) if (/Instruction|Error|error|failed|Constraint|consumed|authority|0x|Program log/.test(l)) console.log("  ", l);
    if (!logs.length) console.log("   (no logs)");
    return res;
  }
  await run(freshPubkey(), "FRESH SIGNER");
  await run(REAL_AUTH, "REAL pair_authority");
}
