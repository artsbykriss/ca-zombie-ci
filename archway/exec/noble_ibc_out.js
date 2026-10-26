#!/usr/bin/env node
/* IBC out of Noble (after the inbound CCTP mint):
 *   - uusdc -> Archway burner (Noble channel-12 -> Archway channel-29)
 *   - uusdc -> Osmosis burner (Noble channel-1  -> Osmosis channel-750) for the ARCH gas buy
 * Usage: node noble_ibc_out.js [archway_usdc] [osmosis_usdc]   (default 20 / 1) */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet } = require("@cosmjs/proto-signing");
const { SigningStargateClient } = require("@cosmjs/stargate");
const { MsgTransfer } = require("cosmjs-types/ibc/applications/transfer/v1/tx");

const NOBLE_RPC = "https://noble-rpc.polkachu.com";
const ARCHWAY_RECEIVER = "archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw";
const OSMO_RECEIVER = "osmo1khgqgnnpw984e70chqjc5yu5r3ed8255a540tt";

(async () => {
  const toArchway = BigInt(Math.round(parseFloat(process.argv[2] || "20") * 1e6));
  const toOsmo = BigInt(Math.round(parseFloat(process.argv[3] || "1") * 1e6));
  const key = JSON.parse(fs.readFileSync(path.join(__dirname, ".archway_key.json"), "utf8"));
  const w = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "noble" });
  const [a] = await w.getAccounts();
  const client = await SigningStargateClient.connectWithSigner(NOBLE_RPC, w);
  const bal = await client.getBalance(a.address, "uusdc");
  console.log(`noble ${a.address} | uusdc ${bal.amount}`);
  console.log(`sending ${toArchway} -> archway, ${toOsmo} -> osmosis (fee paid in uusdc)`);
  if (BigInt(bal.amount) < toArchway + toOsmo) throw new Error("insufficient uusdc");

  const deadline = BigInt(Date.now() + 15 * 60 * 1000) * 1_000_000n;
  const mk = (channel, receiver, amount) => ({
    typeUrl: "/ibc.applications.transfer.v1.MsgTransfer",
    value: MsgTransfer.fromPartial({
      sourcePort: "transfer",
      sourceChannel: channel,
      token: { denom: "uusdc", amount: amount.toString() },
      sender: a.address,
      receiver,
      timeoutHeight: { revisionNumber: 0n, revisionHeight: 0n },
      timeoutTimestamp: deadline,
    }),
  });
  const fee = { amount: [{ denom: "uusdc", amount: "50000" }], gas: "400000" };

  const r1 = await client.signAndBroadcast(a.address, [mk("channel-12", ARCHWAY_RECEIVER, toArchway)], fee);
  console.log(`-> archway tx ${r1.transactionHash} code=${r1.code}`);
  if (r1.code !== 0) { console.log(r1.rawLog); process.exit(1); }

  const r2 = await client.signAndBroadcast(a.address, [mk("channel-1", OSMO_RECEIVER, toOsmo)], fee);
  console.log(`-> osmosis tx ${r2.transactionHash} code=${r2.code}`);
  if (r2.code !== 0) { console.log(r2.rawLog); process.exit(1); }
  console.log("both IBC transfers broadcast.");
})();
