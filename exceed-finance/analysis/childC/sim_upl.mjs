import { rpc, rpcNotNull } from "./rpc.mjs";
import { buildTx, anchorDisc, b58encode } from "./solana.mjs";
import crypto from "node:crypto";

const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const PAIR = "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7";
const AC = "fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe";
const FEEPAYER = "87VfCnQ4d7XuZwriJAK7yADmqzrJQBx9FYMqCwdue5kv"; // funded existing account (distinct from authority)
const REAL_AUTH = "WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ";

const data = Buffer.concat([anchorDisc("update_pair_limits"), Buffer.from([0,0,0,0,0])]);

async function sim(ixKeys, accounts, label) {
  const bhs = await rpcNotNull("getLatestBlockhash", [{ commitment: "finalized" }]);
  const tx = buildTx(accounts, [{ programId: PROG, keys: ixKeys, data }], bhs.value.blockhash, true);
  const res = await fetch("https://api.mainnet-beta.solana.com", {
    method: "POST", headers: { "content-type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "simulateTransaction",
      params: [tx.toString("base64"), { encoding: "base64", sigVerify: false, replaceRecentBlockhash: true }] }),
  });
  const j = await res.json();
  console.log("\n=== " + label + " ===");
  if (j.error) { console.log("RPC ERROR", JSON.stringify(j.error)); return; }
  const v = j.value ?? j.result?.value;
  if (!v) { console.log("RAW", JSON.stringify(j).slice(0,500)); return; }
  console.log("err:", JSON.stringify(v.err), "units:", v.unitsConsumed);
  for (const l of (v.logs||[])) console.log("  ", l);
}

// (1) fresh signer as authority, full accounts
{
  const auth = b58encode(crypto.randomBytes(32));
  const accounts = [
    { pubkey: FEEPAYER, isSigner: true, isWritable: true },
    { pubkey: auth, isSigner: true, isWritable: false },
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: AC, isSigner: false, isWritable: false },
    { pubkey: PROG, isSigner: false, isWritable: false },
  ];
  const ixKeys = [
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: auth, isSigner: true, isWritable: false },
    { pubkey: AC, isSigner: false, isWritable: false },
  ];
  await sim(ixKeys, accounts, "FRESH SIGNER as authority (" + auth + ")");
}

// (2) too few accounts (omit access_control) -> reproduce 3010
{
  const auth = b58encode(crypto.randomBytes(32));
  const accounts = [
    { pubkey: FEEPAYER, isSigner: true, isWritable: true },
    { pubkey: auth, isSigner: true, isWritable: false },
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: PROG, isSigner: false, isWritable: false },
  ];
  const ixKeys = [
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: auth, isSigner: true, isWritable: false },
  ];
  await sim(ixKeys, accounts, "MISSING access_control account");
}

// (3) real pair_authority as authority (marked signer)
{
  const accounts = [
    { pubkey: FEEPAYER, isSigner: true, isWritable: true },
    { pubkey: REAL_AUTH, isSigner: true, isWritable: false },
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: AC, isSigner: false, isWritable: false },
    { pubkey: PROG, isSigner: false, isWritable: false },
  ];
  const ixKeys = [
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: REAL_AUTH, isSigner: true, isWritable: false },
    { pubkey: AC, isSigner: false, isWritable: false },
  ];
  await sim(ixKeys, accounts, "REAL pair_authority as authority (signer)");
}

// (4) real pair_authority address but NOT marked signer -> expect AccountNotSigner (3010)
{
  const accounts = [
    { pubkey: FEEPAYER, isSigner: true, isWritable: true },
    { pubkey: REAL_AUTH, isSigner: false, isWritable: false },
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: AC, isSigner: false, isWritable: false },
    { pubkey: PROG, isSigner: false, isWritable: false },
  ];
  const ixKeys = [
    { pubkey: PAIR, isSigner: false, isWritable: true },
    { pubkey: REAL_AUTH, isSigner: false, isWritable: false },
    { pubkey: AC, isSigner: false, isWritable: false },
  ];
  await sim(ixKeys, accounts, "REAL pair_authority address, NOT signer");
}
