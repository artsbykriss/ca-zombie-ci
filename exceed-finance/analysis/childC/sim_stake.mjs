import { rpc, rpcNotNull } from "./rpc.mjs";
import { buildTx, anchorDisc } from "./solana.mjs";
import { calculateExchangeRate, baseToLst } from "./rate.mjs";

const PROG = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV";
const PAIR = "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7";
const AC = "fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe";
const USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const LST = "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z";
const PAIRBASE = "67f3oEHTLfkBcShmgtivVT5gzqVYrJ9HMP6oCRhS3n7Y";
const LSTFEE = "Bw4N68gHwCJGewLdaBfQToHtKhVcMBRvNhkRxa5ZPV17";
const PRICEFEED = "7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE";
const TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";
const SYSTEM = "11111111111111111111111111111111";

// staker used (a real USDC holder from an actual historical stake tx)
const STAKER = process.argv[2] || "4pPuiTYZLTqNZJWxi7X3rENbrcC7FMsLT43jpWXRHGQX";
const STAKER_BASE = process.argv[3] || "T3Mu5EkLVfF7w92T2KVgwqJxLDnS5Ukv8Pf3JEqnNsS";
const STAKER_LST = process.argv[4] || "DKkZamLMQrLaPBUdaRyv3jmH4P1KbpiSdxTJp5r5PzhX";
const QTY = BigInt(process.argv[5] || "5000000"); // 5 USDC

function pairFromBuf(buf) {
  let o = 8;
  const pair_bump = buf.readUInt8(o); o += 1;
  const lst_mint_bump = buf.readUInt8(o); o += 1;
  const base_token_mint = buf.subarray(o, o+32); o += 32;
  const base_mint_decimals = buf.readUInt8(o); o += 1;
  const lst_mint = buf.subarray(o, o+32); o += 32;
  const lst_mint_decimals = buf.readUInt8(o); o += 1;
  const symLen = buf.readUInt32LE(o); o += 4;
  const lst_symbol = buf.subarray(o, o+symLen).toString("utf8"); o += symLen;
  const interval_apr_rate = buf.readBigUInt64LE(o); o += 8;
  const seconds_per_interval = buf.readInt32LE(o); o += 4;
  const initial_exchange_rate = buf.readBigUInt64LE(o); o += 8;
  const last_yield_change_exchange_rate = buf.readBigUInt64LE(o); o += 8;
  const last_yield_change_timestamp = buf.readBigInt64LE(o); o += 8;
  const deposit_cap = buf.readBigUInt64LE(o); o += 8;
  const minimum_deposit = buf.readBigUInt64LE(o); o += 8;
  const stake_fee_bps = buf.readUInt16LE(o); o += 2;
  const swap_fee_bps = buf.readUInt16LE(o); o += 2;
  const withdraw_fee_bps = buf.readUInt16LE(o); o += 2;
  return { pair_bump, lst_mint_bump, base_token_mint, base_mint_decimals, lst_mint, lst_mint_decimals,
    lst_symbol, interval_apr_rate, seconds_per_interval, initial_exchange_rate,
    last_yield_change_exchange_rate, last_yield_change_timestamp, deposit_cap, minimum_deposit,
    stake_fee_bps, swap_fee_bps, withdraw_fee_bps };
}

const pairAcc = await rpcNotNull("getAccountInfo", [PAIR, { encoding: "base64" }]);
const pair = pairFromBuf(Buffer.from(pairAcc.value.data[0], "base64"));
const pairSlot = pairAcc.context?.slot;
const pfAcc = await rpcNotNull("getAccountInfo", [PRICEFEED, { encoding: "base64" }]);
const pfb = Buffer.from(pfAcc.value.data[0], "base64");
// publish_time is at offset len-56..? find: it's the field before prev_publish_time. Use known layout attempt:
// PriceUpdateV2: write_authority(32) verification_level(1) feed_id(32) price(8) conf(8) exponent(4) publish_time(8) ...
// total expected 8+32+1+32+8+8+4+8+8+8+8 = 125 ; account is 134 => 9 extra (likely enum 2 bytes + padding?) -> search for plausible ts
let publishTime = null;
for (let off = 0; off + 8 <= pfb.length; off++) {
  const v = Number(pfb.readBigInt64LE(off));
  if (v > 1700000000 && v < 2000000000) { publishTime = v; break; }
}
const now = Math.floor(Date.now()/1000);
console.log("pair slot", pairSlot, "lst_symbol", pair.lst_symbol, "stake_fee_bps", pair.stake_fee_bps, "withdraw_fee_bps", pair.withdraw_fee_bps);
console.log("schedule: intervalRate", pair.interval_apr_rate.toString(), "spi", pair.seconds_per_interval, "lastRate", pair.last_yield_change_exchange_rate.toString(), "lastTs", pair.last_yield_change_timestamp.toString());
console.log("price feed publish_time(first plausible i64)", publishTime, publishTime?new Date(publishTime*1000).toISOString():"", "age_s", publishTime?now-publishTime:"?");

const rateNow = calculateExchangeRate(pair.last_yield_change_timestamp, now, pair.interval_apr_rate, pair.last_yield_change_exchange_rate, pair.seconds_per_interval);
const expectedLst = baseToLst(QTY, rateNow, pair.base_mint_decimals, pair.lst_mint_decimals);
console.log("computed rate(now) =", rateNow.toString());
console.log("expected lst for", QTY.toString(), "base =", expectedLst.toString());

// Build stake ix
const disc = anchorDisc("stake");
const data = Buffer.concat([disc, (()=>{const b=Buffer.alloc(9); b.writeBigUInt64LE(QTY,0); b[8]=0; return b;})()]);
const ixKeys = [
  { pubkey: AC, isSigner: false, isWritable: false },
  { pubkey: PAIR, isSigner: false, isWritable: true },
  { pubkey: USDC, isSigner: false, isWritable: true },
  { pubkey: STAKER_BASE, isSigner: false, isWritable: true },
  { pubkey: PAIRBASE, isSigner: false, isWritable: true },
  { pubkey: LSTFEE, isSigner: false, isWritable: true },
  { pubkey: LST, isSigner: false, isWritable: true },
  { pubkey: STAKER_LST, isSigner: false, isWritable: true },
  { pubkey: PRICEFEED, isSigner: false, isWritable: false },
  { pubkey: STAKER, isSigner: true, isWritable: true },
  { pubkey: TOKEN, isSigner: false, isWritable: false },
  { pubkey: ATA, isSigner: false, isWritable: false },
  { pubkey: SYSTEM, isSigner: false, isWritable: false },
];
const accounts = [
  { pubkey: STAKER, isSigner: true, isWritable: true },
  { pubkey: PAIR, isSigner: false, isWritable: true },
  { pubkey: USDC, isSigner: false, isWritable: true },
  { pubkey: STAKER_BASE, isSigner: false, isWritable: true },
  { pubkey: PAIRBASE, isSigner: false, isWritable: true },
  { pubkey: LSTFEE, isSigner: false, isWritable: true },
  { pubkey: LST, isSigner: false, isWritable: true },
  { pubkey: STAKER_LST, isSigner: false, isWritable: true },
  { pubkey: AC, isSigner: false, isWritable: false },
  { pubkey: PRICEFEED, isSigner: false, isWritable: false },
  { pubkey: TOKEN, isSigner: false, isWritable: false },
  { pubkey: ATA, isSigner: false, isWritable: false },
  { pubkey: SYSTEM, isSigner: false, isWritable: false },
  { pubkey: PROG, isSigner: false, isWritable: false },
];
const ix = { programId: PROG, keys: ixKeys, data };
// pre-state
async function preAmt(addr) {
  const a = await rpcNotNull("getAccountInfo", [addr, { encoding: "jsonParsed" }]);
  const info = a.value.data.parsed?.info;
  return { mint: info?.mint, amount: info?.tokenAmount?.amount, supply: info?.supply, owner: info?.owner };
}
const preLstMint = await preAmt(LST);
const preStakerLst = await preAmt(STAKER_LST);
const preStakerBase = await preAmt(STAKER_BASE);
const prePairBase = await preAmt(PAIRBASE);
console.log("PRE lst_mint.supply =", preLstMint.supply, "| staker_lst =", preStakerLst.amount, "| staker_base(usdc) =", preStakerBase.amount, "| pair_base =", prePairBase.amount);
const bhs = await rpcNotNull("getLatestBlockhash", [{ commitment: "finalized" }]);
const tx = buildTx(accounts, [ix], bhs.value.blockhash, true);
const res = await fetch("https://api.mainnet-beta.solana.com", {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "simulateTransaction",
    params: [tx.toString("base64"), { encoding: "base64", sigVerify: false, replaceRecentBlockhash: true,
      accounts: { encoding: "jsonParsed", addresses: [LST, STAKER_LST, STAKER_BASE, PAIRBASE, LSTFEE] } }] }),
});
const j = await res.json();
if (j.error) { console.log("RPC ERROR", JSON.stringify(j.error)); process.exit(0); }
const v = j.value ?? j.result?.value;
console.log("SIM err:", JSON.stringify(v.err), "units:", v.unitsConsumed);
for (const l of (v.logs||[])) console.log("  LOG", l);
console.log("--- post accounts ---");
(v.accounts||[]).forEach((a,i)=>{
  const name=["LST_mint","staker_lst","staker_base","pair_base","lst_fee"][i];
  if(!a){console.log(name,"NULL");return;}
  console.log(name, a.owner, JSON.stringify(a.data.parsed?.info?.tokenAmount||a.data.parsed?.info||"?"));
});
