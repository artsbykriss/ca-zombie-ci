import { encodeFunctionData, zeroAddress } from "viem";

import { abis } from "abis";
import type { ContractsChainId } from "configs/chains";
import { getContract } from "configs/contracts";
import { NATIVE_TOKEN_ADDRESS } from "configs/tokens";
import { DecreasePositionSwapType } from "types/orders";

import type { ExternalCallsPayload } from "./orderTransactions";

export type InternalUsdParams = {
  bankAddress: string;
  wrappedTokenAddress: string;
  underlyingTokenAddress?: string;
};

export function requireInternalUsd(internalUsd: InternalUsdParams | undefined): InternalUsdParams {
  if (!internalUsd) {
    throw new Error("HFUSD orders require internal USD configuration");
  }

  return internalUsd;
}

export function getInternalUsdOrderAddresses(receiver: string) {
  return {
    receiver,
    cancellationReceiver: receiver,
    callbackContract: zeroAddress,
    callbackGasLimit: 0n,
  };
}

export function validateInternalUsdWrappedToken(
  internalUsd: InternalUsdParams,
  tokenAddress: string,
  label = "Internal USD collateral token"
) {
  if (tokenAddress.toLowerCase() !== internalUsd.wrappedTokenAddress.toLowerCase()) {
    throw new Error(label + " must match the internal USD wrapped token");
  }
}

export function validateInternalUsdDecreaseOrder({
  internalUsd,
  receiveTokenAddress,
  swapPath,
  decreasePositionSwapType,
}: {
  internalUsd: InternalUsdParams;
  receiveTokenAddress: string;
  swapPath: string[];
  decreasePositionSwapType: DecreasePositionSwapType;
}) {
  if (receiveTokenAddress.toLowerCase() !== internalUsd.wrappedTokenAddress.toLowerCase()) {
    throw new Error("HFUSD decrease orders must receive the HFUSD wrapped token");
  }

  if (swapPath.length !== 0) {
    throw new Error("HFUSD decrease orders do not support swap paths");
  }

  if (decreasePositionSwapType !== DecreasePositionSwapType.NoSwap) {
    throw new Error("HFUSD decrease orders require NoSwap");
  }
}

export function buildInternalUsdMintExternalCalls({
  chainId,
  payTokenAddress,
  payTokenAmount,
  internalUsd,
  mintReceiver,
}: {
  chainId: ContractsChainId;
  payTokenAddress: string;
  payTokenAmount: bigint;
  internalUsd: InternalUsdParams;
  mintReceiver?: string;
}): ExternalCallsPayload {
  if (payTokenAddress === NATIVE_TOKEN_ADDRESS) {
    throw new Error("Internal USD wrapping only supports ERC20 payment tokens");
  }

  if (payTokenAmount <= 0n) {
    throw new Error("Internal USD wrapping requires a positive payment amount");
  }

  const underlyingTokenAddress = internalUsd.underlyingTokenAddress ?? payTokenAddress;
  if (underlyingTokenAddress.toLowerCase() !== payTokenAddress.toLowerCase()) {
    throw new Error("Internal USD underlying token must match the payment token");
  }

  const receiver = mintReceiver ?? getContract(chainId, "OrderVault");

  return {
    sendTokens: [],
    sendAmounts: [],
    externalCallTargets: [internalUsd.bankAddress],
    externalCallDataList: [
      encodeFunctionData({
        abi: abis.HFBank,
        functionName: "mint",
        args: [receiver as `0x${string}`],
      }),
    ],
    refundTokens: [],
    refundReceivers: [],
  };
}
