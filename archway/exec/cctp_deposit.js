#!/usr/bin/env node
/* CCTP deposit step (separate because the swap/approve are already done):
 * depositForBurn(balance, domain 4 (Noble), mintRecipient, USDC) + print the message hash. */
const fs = require("fs");
const path = require("path");
const { JsonRpcProvider, Wallet, Contract, formatUnits, keccak256, Interface } = require("ethers");

const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const TOKEN_MESSENGER = "0xBd3fa81B58Ba92a82136038B25aDec7066af3155";
const DEST_DOMAIN = 4; // Noble
const NOBLE_ADDR = "noble1khgqgnnpw984e70chqjc5yu5r3ed8255avnh9h";

function env(name) {
  const txt = fs.readFileSync(path.join(__dirname, "..", "..", ".env"), "utf8");
  for (const line of txt.split("\n")) {
    const m = line.match(/^([A-Za-z0-9_]+)=(.*)$/);
    if (m && m[1] === name) return m[2].trim().replace(/^["']|["']$/g, "");
  }
  return "";
}

function bech32ToBytes(addr) {
  const CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
  const pos = addr.lastIndexOf("1");
  const dataPart = addr.slice(pos + 1).toLowerCase();
  const values = [];
  for (const c of dataPart) {
    const v = CHARSET.indexOf(c);
    if (v === -1) throw new Error("bad bech32 char " + c);
    values.push(v);
  }
  const data = values.slice(0, -6); // drop checksum
  let bits = 0;
  let acc = 0;
  const bytes = [];
  for (const v of data) {
    acc = (acc << 5) | v;
    bits += 5;
    while (bits >= 8) {
      bits -= 8;
      bytes.push((acc >> bits) & 0xff);
    }
  }
  return Buffer.from(bytes);
}

const TM_ABI = ["function depositForBurn(uint256 amount, uint32 destinationDomain, bytes32 mintRecipient, address burnToken) returns (uint64)"];
const ERC20_ABI = ["function balanceOf(address) view returns (uint256)", "function allowance(address,address) view returns (uint256)"];
const MSG_SENT_TOPIC = new Interface(["event MessageSent(bytes message)"]).getEvent("MessageSent").topicHash;

(async () => {
  const provider = new JsonRpcProvider("https://mainnet.infura.io/v3/" + env("INFURA_API_KEY"));
  const wallet = new Wallet(env("PRIVATE_KEY"), provider);
  const usdc = new Contract(USDC, ERC20_ABI, provider);
  const bal = await usdc.balanceOf(wallet.address);
  const allow = await usdc.allowance(wallet.address, TOKEN_MESSENGER);
  console.log("USDC balance:", formatUnits(bal, 6), "| allowance:", formatUnits(allow, 6));
  if (allow < bal) throw new Error("allowance too low");

  const data = bech32ToBytes(NOBLE_ADDR);
  console.log("noble addr bytes:", data.toString("hex"), `(${data.length} bytes)`);
  if (data.length !== 20) throw new Error("unexpected address length");
  const mintRecipient = "0x" + "00".repeat(12) + data.toString("hex");

  const tm = new Contract(TOKEN_MESSENGER, TM_ABI, wallet);
  const burnTx = await tm.depositForBurn(bal, DEST_DOMAIN, mintRecipient, USDC, { gasLimit: 250000 });
  console.log("burn tx:", burnTx.hash);
  const rc = await burnTx.wait();
  console.log("burn mined:", rc.status === 1 ? "OK" : "FAILED", "block", rc.blockNumber);

  const iface = new Interface(["event MessageSent(bytes message)"]);
  let messageHex = null;
  for (const log of rc.logs) {
    if (log.topics[0] === MSG_SENT_TOPIC) {
      const parsed = iface.decodeEventLog({ topics: log.topics, data: log.data });
      messageHex = parsed.args[0];
    }
  }
  if (!messageHex) throw new Error("no MessageSent event");
  const messageHash = keccak256(messageHex);
  console.log("messageHash:", messageHash);
  console.log("attestation:", `https://iris-api.circle.com/v1/attestations/${messageHash}`);
})();
