#!/usr/bin/env node
/* Exit leg 2: Circle CCTP depositForBurn on Noble (uusdc -> Ethereum domain 0).
 * Usage: node cctp_burn_noble.js [amount_usdc]   (default 10) */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet, Registry } = require("@cosmjs/proto-signing");
const { SigningStargateClient, defaultRegistryTypes } = require("@cosmjs/stargate");
const { getAddress } = require("ethers");
const cctpCodec = require("./cctp_codec");

const NOBLE_RPC = "https://noble-rpc.polkachu.com";
const DEST_DOMAIN = 0; // Ethereum
const ETH_DEST = "0x2B2357b4BD1c7600545117B68a3FafFb8C169137";

const cctpType = {
  encode: (v) => ({ finish: () => cctpCodec.encode(v) }),
  decode: (b) => cctpCodec.decode(b),
  fromPartial: (v) => v,
  create: (v) => v,
};

(async () => {
  const amount = process.argv[2] || "10";
  const micro = BigInt(Math.round(parseFloat(amount) * 1e6));
  const key = JSON.parse(fs.readFileSync(path.join(__dirname, ".archway_key.json"), "utf8"));
  const wN = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "noble" });
  const [aN] = await wN.getAccounts();

  const registry = new Registry([...defaultRegistryTypes, ["/circle.cctp.v1.MsgDepositForBurn", cctpType]]);
  const client = await SigningStargateClient.connectWithSigner(NOBLE_RPC, wN, { registry });
  const bal = await client.getBalance(aN.address, "uusdc");
  console.log(`noble : ${aN.address}`);
  console.log(`uusdc : ${bal.amount} (burning ${micro}, gas denom uusdc)`);
  if (BigInt(bal.amount) < micro) throw new Error("insufficient uusdc");

  const ethBytes = Buffer.from(getAddress(ETH_DEST).slice(2), "hex"); // 20 bytes
  const mintRecipient = Buffer.concat([Buffer.alloc(12), ethBytes]); // 32-byte padded

  const msg = {
    typeUrl: "/circle.cctp.v1.MsgDepositForBurn",
    value: {
      from: aN.address,
      amount: micro.toString(),
      destinationDomain: DEST_DOMAIN,
      mintRecipient,
      burnToken: "uusdc",
    },
  };
  // Noble min gas price 0.1 uusdc/gas
  const fee = { amount: [{ denom: "uusdc", amount: "50000" }], gas: "400000" };
  const t0 = Date.now();
  const res = await client.signAndBroadcast(aN.address, [msg], fee);
  console.log(`burn broadcast in ${((Date.now() - t0) / 1000).toFixed(1)}s: ${res.transactionHash} code=${res.code}`);
  if (res.code !== 0) {
    console.log("rawLog:", res.rawLog);
    process.exit(1);
  }
  console.log("leg 2 done; next: cctp_mint_eth.js", res.transactionHash);
})();
