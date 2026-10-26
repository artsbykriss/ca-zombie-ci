#!/usr/bin/env node
/* Exit leg 1: IBC transfer of Noble-native USDC from the Archway burner to the Noble
 * address via channel-29 (counterparty Noble channel-12).
 * Usage: node ibc_archway_noble.js [amount_usdc]   (default 10) */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet } = require("@cosmjs/proto-signing");
const { SigningStargateClient } = require("@cosmjs/stargate");
const { MsgTransfer } = require("cosmjs-types/ibc/applications/transfer/v1/tx");

const ARCHWAY_RPC = "https://rpc.mainnet.archway.io";
const USDC_ARCHWAY = "ibc/43897B9739BD63E3A08A88191999C632E052724AB96BD4C74AE31375C991F48D";
const CHANNEL = "channel-29";

(async () => {
  const amount = process.argv[2] || "10";
  const micro = BigInt(Math.round(parseFloat(amount) * 1e6));
  const key = JSON.parse(fs.readFileSync(path.join(__dirname, ".archway_key.json"), "utf8"));
  const wA = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "archway" });
  const [aA] = await wA.getAccounts();
  const wN = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "noble" });
  const [aN] = await wN.getAccounts();

  const client = await SigningStargateClient.connectWithSigner(ARCHWAY_RPC, wA);
  const bal = await client.getBalance(aA.address, USDC_ARCHWAY);
  console.log(`burner: ${aA.address}`);
  console.log(`noble : ${aN.address}`);
  console.log(`USDC on Archway: ${bal.amount} (sending ${micro})`);
  if (BigInt(bal.amount) < micro) throw new Error("insufficient USDC");

  const msg = {
    typeUrl: "/ibc.applications.transfer.v1.MsgTransfer",
    value: MsgTransfer.fromPartial({
      sourcePort: "transfer",
      sourceChannel: CHANNEL,
      token: { denom: USDC_ARCHWAY, amount: micro.toString() },
      sender: aA.address,
      receiver: aN.address,
      timeoutHeight: { revisionNumber: 0n, revisionHeight: 0n },
      timeoutTimestamp: BigInt(Date.now() + 15 * 60 * 1000) * 1_000_000n,
    }),
  };
  // Archway min gas price 140000000000 aarch/gas; 200k gas -> 0.028 ARCH
  const fee = { amount: [{ denom: "aarch", amount: "30000000000000000" }], gas: "200000" };
  const t0 = Date.now();
  const res = await client.signAndBroadcast(aA.address, [msg], fee);
  console.log(`broadcast in ${((Date.now() - t0) / 1000).toFixed(1)}s: ${res.transactionHash} code=${res.code}`);
  if (res.code !== 0) {
    console.log("rawLog:", res.rawLog);
    process.exit(1);
  }
  console.log("leg 1 sent; poll Noble for the incoming uusdc.");
})();
