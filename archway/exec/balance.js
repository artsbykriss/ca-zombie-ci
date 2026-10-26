#!/usr/bin/env node
/* Exit-rehearsal balances: Archway burner, Noble address, Ethereum destination.
 * Read-only. Usage: node balance.js */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet } = require("@cosmjs/proto-signing");
const { JsonRpcProvider, Contract } = require("ethers");

const ARCHWAY_LCD = "https://api.mainnet.archway.io";
const NOBLE_LCD = "https://noble-api.polkachu.com";
const USDC_ARCHWAY = "ibc/43897B9739BD63E3A08A88191999C632E052724AB96BD4C74AE31375C991F48D";
const USDC_ETH = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const ETH_DEST = "0x2B2357b4BD1c7600545117B68a3FafFb8C169137";

function env(name) {
  const txt = fs.readFileSync(path.join(__dirname, "..", "..", ".env"), "utf8");
  for (const line of txt.split("\n")) {
    const m = line.match(/^([A-Za-z0-9_]+)=(.*)$/);
    if (m && m[1] === name) return m[2].trim().replace(/^["']|["']$/g, "");
  }
  return "";
}

async function lcd(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${url} -> ${r.status}`);
  return r.json();
}

(async () => {
  const key = JSON.parse(fs.readFileSync(path.join(__dirname, ".archway_key.json"), "utf8"));
  const wA = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "archway" });
  const [aA] = await wA.getAccounts();
  const wN = await DirectSecp256k1HdWallet.fromMnemonic(key.mnemonic, { prefix: "noble" });
  const [aN] = await wN.getAccounts();

  console.log("Archway burner:", aA.address);
  console.log("Noble address :", aN.address);
  console.log("Ethereum dest :", ETH_DEST);
  console.log();

  const bA = await lcd(`${ARCHWAY_LCD}/cosmos/bank/v1beta1/balances/${aA.address}`);
  console.log("Archway balances:");
  if (!bA.balances.length) console.log("  (empty)");
  for (const b of bA.balances) {
    const tag = b.denom === USDC_ARCHWAY ? "  <- Noble-native USDC" : "";
    console.log(`  ${b.amount} ${b.denom}${tag}`);
  }

  const bN = await lcd(`${NOBLE_LCD}/cosmos/bank/v1beta1/balances/${aN.address}`);
  console.log("Noble balances:");
  if (!bN.balances.length) console.log("  (empty)");
  for (const b of bN.balances) console.log(`  ${b.amount} ${b.denom}`);

  try {
    const provider = new JsonRpcProvider(env("RPC_URL"));
    const usdc = new Contract(USDC_ETH, ["function balanceOf(address) view returns (uint256)"], provider);
    const eth = await provider.getBalance(ETH_DEST);
    const u = await usdc.balanceOf(ETH_DEST);
    console.log("Ethereum:");
    console.log(`  ${Number(eth) / 1e18} ETH`);
    console.log(`  ${Number(u) / 1e6} USDC`);
  } catch (e) {
    console.log("Ethereum: RPC error:", e.message);
  }
})();
