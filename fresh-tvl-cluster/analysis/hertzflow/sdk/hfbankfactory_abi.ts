export default [
  {
    inputs: [{ internalType: "address", name: "wrappedToken", type: "address" }],
    name: "getBankByWrappedToken",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "underlyingByWrappedToken",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
] as const;
