import { rpc } from "./rpc.mjs";
const PAIRS = process.argv.slice(2);
if (!PAIRS.length) PAIRS.push("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7");
for (const PAIR of PAIRS) {
  const acc = await rpc("getAccountInfo", [PAIR, { encoding: "base64" }]);
  const buf = Buffer.from(acc.value.data[0], "base64");
  let o = 8;
  const pair_bump = buf.readUInt8(o); o += 1;
  const lst_mint_bump = buf.readUInt8(o); o += 1;
  const base_token_mint = buf.subarray(o, o+32).toString("hex"); o += 32;
  const base_mint_decimals = buf.readUInt8(o); o += 1;
  const lst_mint = buf.subarray(o, o+32).toString("hex"); o += 32;
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
  console.log(JSON.stringify({
    PAIR, owner: acc.value.owner, slot: acc.context?.slot, dataLen: buf.length,
    pair_bump, lst_mint_bump, base_token_mint, base_mint_decimals, lst_mint, lst_mint_decimals, lst_symbol,
    interval_apr_rate: interval_apr_rate.toString(), seconds_per_interval,
    initial_exchange_rate: initial_exchange_rate.toString(),
    last_yield_change_exchange_rate: last_yield_change_exchange_rate.toString(),
    last_yield_change_timestamp: last_yield_change_timestamp.toString(),
    deposit_cap: deposit_cap.toString(), minimum_deposit: minimum_deposit.toString(),
    stake_fee_bps, swap_fee_bps, withdraw_fee_bps, trailing: buf.length - o,
  }));
}
