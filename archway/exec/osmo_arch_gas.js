#!/usr/bin/env node
/* On Osmosis: swap Noble-USDC -> ARCH via pool 1375, then IBC the ARCH to the Archway burner.
 * Gas is paid in USDC (Noble-USDC is a whitelisted Osmosis fee token).
 * Usage: node osmo_arch_gas.js [usdc_amount]   (default 0.2) */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet, Registry } = require("@cosmjs/proto-signing");
const { SigningStargateClient, defaultRegistryTypes } = require("@cosmjs/stargate");
const { MsgTransfer } = require("cosmjs-types/ibc/applications/transfer/v1/tx");

const OSMO_RPC = "https://rpc.osmosis.zone";
const USDC = "ibc/498A0751C798A0D9A389AA3691123DADA57DAA4FE165D5C75894505B876BA6E4";
const ARCH = "ibc/23AB778D694C1ECFC59B91D8C399C115CC53B0BD1C61020D8E19519F002BDD85";
const POOL_ID = 1375;
const ARCHWAY_RECEIVER = "archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw";
const ARCHWAY_CHANNEL = "channel-1429";

// ---- minimal protobuf writer for MsgSwapExactAmountIn ----
function varint(n) {
  const out = [];
  let v = typeof n === "bigint" ? n : BigInt(n);
  while (v > 0x7fn) { out.push(Number(v & 0x7fn) | 0x80); v >>= 7n; }
  out.push(Number(v));
  return Buffer.from(out);
}
const tag = (f, w) => varint(BigInt((f << 3) | w));
const str = (f, s) => { const b = Buffer.from(s, "utf8"); return Buffer.concat([tag(f, 2), varint(b.length), b]); };
const sub = (f, b) => Buffer.concat([tag(f, 2), varint(b.length), b]);
const u64 = (f, n) => Buffer.concat([tag(f, 0), varint(n)]);

function encodeSwap(v) {
  const route = Buffer.concat([u64(1, v.routes[0].poolId), str(2, v.routes[0].tokenOutDenom)]);
  const coin = Buffer.concat([str(1, v.tokenIn.denom), str(2, v.tokenIn.amount)]);
  return Buffer.concat([str(1, v.sender), sub(2, route), sub(3, coin), str(4, v.tokenOutMinAmount)]);
}
const swapType = {
  encode: (v) => ({ finish: () => encodeSwap(v) }),
  decode: () => {
    throw new Error("decode not needed");
  },
  fromPartial: (v) => v,
  create: (v) => v,
};

(async () => {
  const usdcIn = BigInt(Math.round(parseFloat(process.argv[2] || "0.2") * 1e6));
  const key = JSON.parse(fs.readFileSync(path.join(__dirname, ".archway_key.json"), "utf8"));
  const w = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "osmo" });
  const [a] = await w.getAccounts();
  const registry = new Registry([...defaultRegistryTypes, ["/osmosis.gamm.v1beta1.MsgSwapExactAmountIn", swapType]]);
  const client = await SigningStargateClient.connectWithSigner(OSMO_RPC, w, { registry });
  const bal = await client.getBalance(a.address, USDC);
  console.log(`osmo ${a.address} | USDC ${bal.amount}`);
  if (BigInt(bal.amount) < usdcIn) throw new Error("insufficient USDC on Osmosis");

  const minArch = usdcIn * 2400n * 10n ** 12n; // conservative: 2400 ARCH per USDC (6-dec USDC -> 18-dec uarch)
  const swapMsg = {
    typeUrl: "/osmosis.gamm.v1beta1.MsgSwapExactAmountIn",
    value: {
      sender: a.address,
      routes: [{ poolId: POOL_ID, tokenOutDenom: ARCH }],
      tokenIn: { denom: USDC, amount: usdcIn.toString() },
      tokenOutMinAmount: minArch.toString(),
    },
  };
  const fee = { amount: [{ denom: USDC, amount: "60000" }], gas: "500000" };
  const r1 = await client.signAndBroadcast(a.address, [swapMsg], fee);
  console.log(`swap tx ${r1.transactionHash} code=${r1.code}`);
  if (r1.code !== 0) { console.log(r1.rawLog); process.exit(1); }
  const archBal = await client.getBalance(a.address, ARCH);
  console.log(`ARCH after swap: ${archBal.amount}`);

  const ibcMsg = {
    typeUrl: "/ibc.applications.transfer.v1.MsgTransfer",
    value: MsgTransfer.fromPartial({
      sourcePort: "transfer",
      sourceChannel: ARCHWAY_CHANNEL,
      token: { denom: ARCH, amount: archBal.amount },
      sender: a.address,
      receiver: ARCHWAY_RECEIVER,
      timeoutHeight: { revisionNumber: 0n, revisionHeight: 0n },
      timeoutTimestamp: BigInt(Date.now() + 15 * 60 * 1000) * 1_000_000n,
    }),
  };
  const r2 = await client.signAndBroadcast(a.address, [ibcMsg], fee);
  console.log(`ibc ARCH->archway tx ${r2.transactionHash} code=${r2.code}`);
  if (r2.code !== 0) { console.log(r2.rawLog); process.exit(1); }
  console.log("done: ARCH is on its way to the Archway burner.");
})();
