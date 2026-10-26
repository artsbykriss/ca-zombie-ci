#!/usr/bin/env node
/* Exit legs 3-4: poll the Circle attestation for a Noble burn and mint on Ethereum.
 * Usage: node cctp_mint_eth.js <noble_burn_txhash> */
const fs = require("fs");
const path = require("path");
const { keccak256, JsonRpcProvider, Wallet, Contract } = require("ethers");

const NOBLE_LCD = "https://noble-api.polkachu.com";
const IRIS = "https://iris-api.circle.com/v1/attestations";
const MESSAGE_TRANSMITTER = "0x0a992d191DEeC32aFe36203Ad87D7d289a738F81";

function env(name) {
  const txt = fs.readFileSync(path.join(__dirname, "..", "..", ".env"), "utf8");
  for (const line of txt.split("\n")) {
    const m = line.match(/^([A-Za-z0-9_]+)=(.*)$/);
    if (m && m[1] === name) return m[2].trim().replace(/^["']|["']$/g, "");
  }
  return "";
}

(async () => {
  const txhash = process.argv[2];
  if (!txhash) throw new Error("usage: node cctp_mint_eth.js <noble_burn_txhash>");

  // 1. extract the CCTP message from the Noble burn tx
  const tx = await fetch(`${NOBLE_LCD}/cosmos/tx/v1beta1/txs/${txhash}`).then((r) => r.json());
  let messageB64 = null;
  for (const e of tx.tx_response?.events || []) {
    if (e.type === "circle.cctp.v1.MessageSent") {
      for (const a of e.attributes || []) if (a.key === "message") messageB64 = a.value;
    }
  }
  if (!messageB64) throw new Error("no circle.cctp.v1.MessageSent event in tx");
  const messageHex = "0x" + Buffer.from(messageB64, "base64").toString("hex");
  const messageHash = keccak256(messageHex);
  console.log(`message: ${messageHex.slice(0, 42)}... (${(messageHex.length - 2) / 2} bytes)`);
  console.log(`messageHash: ${messageHash}`);

  // 2. poll the Circle attestation
  const t0 = Date.now();
  let att = null;
  for (let i = 0; i < 160; i++) {
    try {
      const r = await fetch(`${IRIS}/${messageHash}`);
      if (r.ok) {
        const d = await r.json();
        if (d.status === "complete" && d.attestation && d.attestation !== "PENDING") {
          att = d.attestation;
          break;
        }
        if (i % 8 === 0) console.log(`  waiting... status=${d.status} (${((Date.now() - t0) / 1000).toFixed(0)}s)`);
      }
    } catch (e) {
      if (i % 8 === 0) console.log(`  poll error: ${e.message}`);
    }
    await new Promise((r) => setTimeout(r, 15000));
  }
  if (!att) throw new Error("attestation timeout (40 min)");
  console.log(`attestation complete in ${((Date.now() - t0) / 1000).toFixed(0)}s`);

  // 3. receiveMessage on Ethereum
  const provider = new JsonRpcProvider(env("RPC_URL"));
  const wallet = new Wallet(env("PRIVATE_KEY"), provider);
  const ct = new Contract(
    MESSAGE_TRANSMITTER,
    ["function receiveMessage(bytes message, bytes attestation) returns (bool)"],
    wallet
  );
  const t1 = Date.now();
  const txr = await ct.receiveMessage(messageHex, att);
  console.log(`eth tx: ${txr.hash} (broadcast in ${((Date.now() - t1) / 1000).toFixed(1)}s)`);
  const rc = await txr.wait();
  console.log(`mined block ${rc.blockNumber} status=${rc.status}`);
})();
