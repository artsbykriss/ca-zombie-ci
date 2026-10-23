#!/usr/bin/env node
/* Inbound funding for the exit rehearsal:
 *  1. swap ETH -> USDC on Uniswap V3 (0.05% pool)
 *  2. approve USDC to the CCTP TokenMessenger
 *  3. depositForBurn to Noble (domain 4) with the burner's Noble address as mintRecipient
 * Prints the burn tx hash + message hash for attestation polling.
 * Usage: node fund_inbound.js [eth_amount]   (default 0.008) */
const fs = require("fs");
const path = require("path");
const { JsonRpcProvider, Wallet, Contract, parseEther, formatUnits, getBytes, keccak256, Interface } = require("ethers");
const { fromBech32 } = require("@cosmjs/encoding");

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const TOKEN_MESSENGER = "0xBd3fa81B58Ba92a82136038B25aDec7066af3155";
const FEE_TIER = 500;
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

const ROUTER_ABI = [
  "function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 deadline, uint256 amountIn, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96) params) payable returns (uint256 amountOut)",
];
const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address, uint256) returns (bool)",
  "function allowance(address, address) view returns (uint256)",
];
const TM_ABI = ["function depositForBurn(uint256 amount, uint32 destinationDomain, bytes32 mintRecipient, address burnToken) returns (uint64)"];
const MSG_SENT_TOPIC = new Interface(["event MessageSent(bytes message)"]).getEvent("MessageSent").topicHash;

(async () => {
  const ethAmount = process.argv[2] || "0.008";
  const provider = new JsonRpcProvider("https://mainnet.infura.io/v3/" + env("INFURA_API_KEY"));
  const wallet = new Wallet(env("PRIVATE_KEY"), provider);
  console.log("wallet:", wallet.address);

  // 1. swap ETH -> USDC
  const router = new Contract(SWAP_ROUTER, ROUTER_ABI, wallet);
  const usdc = new Contract(USDC, ERC20_ABI, provider);
  const inWei = parseEther(ethAmount);
  // ~$2695/ETH; min out = 97% of expected (pool fee 0.05%)
  const expected = (Number(ethAmount) * 2695 * 0.9995);
  const minOut = BigInt(Math.floor(expected * 0.97 * 1e6));
  console.log(`swap ${ethAmount} ETH -> ~${expected.toFixed(2)} USDC (min ${Number(minOut) / 1e6})`);
  const deadline = Math.floor(Date.now() / 1000) + 600;
  const swapTx = await router.exactInputSingle(
    { tokenIn: WETH, tokenOut: USDC, fee: FEE_TIER, recipient: wallet.address, deadline, amountIn: inWei, amountOutMinimum: minOut, sqrtPriceLimitX96: 0 },
    { value: inWei, gasLimit: 250000 }
  );
  console.log("swap tx:", swapTx.hash);
  const swapRc = await swapTx.wait();
  console.log("swap mined:", swapRc.status === 1 ? "OK" : "FAILED");
  const bal = await usdc.balanceOf(wallet.address);
  console.log("USDC balance:", formatUnits(bal, 6));

  // 2. approve
  const tm = new Contract(TOKEN_MESSENGER, TM_ABI, wallet);
  const appTx = await usdc.connect(wallet).approve(TOKEN_MESSENGER, bal, { gasLimit: 100000 });
  console.log("approve tx:", appTx.hash);
  await appTx.wait();

  // 3. depositForBurn to Noble
  const data = fromBech32(NOBLE_ADDR).data; // 20 bytes
  const mintRecipient = "0x" + "00".repeat(12) + Buffer.from(data).toString("hex");
  console.log("mintRecipient:", mintRecipient);
  const burnTx = await tm.depositForBurn(bal, DEST_DOMAIN, mintRecipient, USDC, { gasLimit: 250000 });
  console.log("burn tx:", burnTx.hash);
  const burnRc = await burnTx.wait();
  console.log("burn mined:", burnRc.status === 1 ? "OK" : "FAILED");

  // extract the CCTP message from the MessageSent event
  let messageHex = null;
  for (const log of burnRc.logs) {
    if (log.topics[0] === MSG_SENT_TOPIC) {
      const [msg] = new Interface(["event MessageSent(bytes message)"]).decodeEventLog({ topics: log.topics, data: log.data }).args;
      messageHex = msg;
    }
  }
  if (!messageHex) throw new Error("no MessageSent event");
  const messageHash = keccak256(messageHex);
  console.log("message:", messageHex.slice(0, 42) + "...");
  console.log("messageHash:", messageHash);
  console.log("attestation URL:", `https://iris-api.circle.com/v1/attestations/${messageHash}`);
})();
