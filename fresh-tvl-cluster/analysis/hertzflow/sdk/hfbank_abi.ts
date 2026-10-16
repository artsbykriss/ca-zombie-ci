export default [
  {
    inputs: [{ internalType: "address", name: "receiver", type: "address" }],
    name: "mint",
    outputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;
