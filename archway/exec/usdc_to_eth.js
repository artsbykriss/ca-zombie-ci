#!/usr/bin/env node
/* Final leg: swap the USDC that lands on Ethereum back to ETH (Uniswap V3 + unwrap).
 * Usage: node usdc_to_eth.js [usdc_amount]   (default: full balance) */
const fs = require("fs");
const path = require("path");
const { JsonRpcProvider, Wallet, Contract, formatUnits, formatEther, parseUnits } = require("ethers");

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const FEE_TIER = 500;

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
  "function unwrapWETH9(uint256 amountMinimum, address recipient) payable",
  "function multicall(bytes[] data) payable returns (bytes[])",
];
const ERC20_ABI = ["function balanceOf(address) view returns (uint256)", "function approve(address,uint256) returns (bool)"];

(async () => {
  const provider = new JsonRpcProvider("https://mainnet.infura.io/v3/" + env("INFURA_API_KEY"));
  const wallet = new Wallet(env("PRIVATE_KEY"), provider);
  const usdc = new Contract(USDC, ERC20_ABI, provider);
  const bal = await usdc.balanceOf(wallet.address);
  const amountIn = process.argv[2] ? parseUnits(process.argv[2], 6) : bal;
  console.log("wallet:", wallet.address, "| USDC:", formatUnits(bal, 6), "| swapping:", formatUnits(amountIn, 6));
  if (amountIn === 0n) throw new Error("nothing to swap");

  const router = new Contract(SWAP_ROUTER, ROUTER_ABI, wallet);
  const appTx = await usdc.connect(wallet).approve(SWAP_ROUTER, amountIn, { gasLimit: 100000 });
  await appTx.wait();
  console.log("approved");

  // ~$2695/ETH; accept 3% slippage
  const minEth = parseUnits((Number(formatUnits(amountIn, 6)) / 2695 * 0.97).toFixed(18), 18);
  const params = {
    tokenIn: USDC,
    tokenOut: WETH,
    fee: FEE_TIER,
    recipient: wallet.address,
    deadline: Math.floor(Date.now() / 1000) + 600,
    amountIn,
    amountOutMinimum: minEth,
    sqrtPriceLimitX96: 0,
  };
  const tx = await router.exactInputSingle(params, { gasLimit: 250000 });
  console.log("swap tx:", tx.hash);
  const rc = await tx.wait();
  console.log("swap mined:", rc.status === 1 ? "OK" : "FAILED");

  // unwrap WETH -> ETH
  const weth = new Contract(WETH, ["function balanceOf(address) view returns (uint256)", "function withdraw(uint256)"], wallet);
  const wbal = await weth.balanceOf(wallet.address);
  console.log("WETH to unwrap:", formatEther(wbal));
  if (wbal > 0n) {
    const wtx = await weth.withdraw(wbal, { gasLimit: 100000 });
    console.log("unwrap tx:", wtx.hash);
    await wtx.wait();
  }
  console.log("ETH now:", formatEther(await provider.getBalance(wallet.address)));
})();
