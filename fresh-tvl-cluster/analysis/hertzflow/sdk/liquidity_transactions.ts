import { type Abi, type Address, encodeFunctionData, zeroAddress } from "viem";

import { abis } from "abis/index";
import { getContract } from "configs/contracts";
import { minHlvTokensForFirstDepositKey, minMarketTokensForFirstDepositKey } from "configs/dataStore";
import type { HlvDepositAllocation, HlvWithdrawalAllocation } from "types/liquidity";
import type { InternalUsdParams } from "utils/internalUsd";
import { parseRequiredExecutionFeeFromError } from "utils/simulateExecuteLiquidity";

import type { HertzFlowSDK } from "../..";
import type { CreateDepositParams, CreateWithdrawalParams } from "./types";

export const FIRST_DEPOSIT_RECEIVER = "0x0000000000000000000000000000000000000001" as Address;

export interface CreateDepositTxnParams {
  sdk: HertzFlowSDK;
  params: CreateDepositParams;
  longTokenAmount: bigint;
  shortTokenAmount: bigint;
  internalUsd?: InternalUsdParams;
}

export interface CreateWithdrawalTxnParams {
  sdk: HertzFlowSDK;
  params: CreateWithdrawalParams;
  marketTokenAmount: bigint;
}

export interface CreateHlvDepositTxnParams {
  sdk: HertzFlowSDK;
  hlvAddress: Address;
  marketAddress: Address;
  longTokenAmount: bigint;
  shortTokenAmount: bigint;
  minHlvTokens: bigint;
  executionFee: bigint;
  /** Gas price used when calculating executionFee and sending the transaction. */
  gasPrice?: bigint;
  initialLongToken: Address;
  initialShortToken: Address;
  internalUsd?: InternalUsdParams;
  isFirstDeposit?: boolean;
  marketAllocations?: HlvDepositAllocation[];
}

export interface CreateHlvWithdrawalTxnParams {
  sdk: HertzFlowSDK;
  hlvAddress: Address;
  hlvTokenAddress: Address;
  marketAddress: Address;
  hlvTokenAmount: bigint;
  minLongTokenAmount: bigint;
  minShortTokenAmount: bigint;
  executionFee: bigint;
  /** Gas price used when calculating executionFee and sending the transaction. */
  gasPrice?: bigint;
  marketAllocations?: HlvWithdrawalAllocation[];
}

function encodeRouterCall(abi: Abi, functionName: string, args: unknown[]): `0x${string}` {
  return encodeFunctionData({ abi, functionName, args } as never);
}

function encodeBankMint(bankAddress: Address, receiver: Address): `0x${string}` {
  return encodeFunctionData({
    abi: abis.HFBank,
    functionName: "mint",
    args: [receiver],
  });
}

function encodeTokenTransfers(
  abi: Abi,
  receiver: Address,
  transfers: { token: Address; amount: bigint }[]
): `0x${string}`[] {
  const amounts = new Map<string, { token: Address; amount: bigint }>();

  for (const transfer of transfers) {
    if (transfer.amount <= 0n) continue;
    const key = transfer.token.toLowerCase();
    const current = amounts.get(key);
    amounts.set(key, {
      token: transfer.token,
      amount: (current?.amount ?? 0n) + transfer.amount,
    });
  }

  return Array.from(amounts.values()).map(({ token, amount }) =>
    encodeRouterCall(abi, "sendTokens", [token, receiver, amount])
  );
}

function requireUnderlyingToken(internalUsd: InternalUsdParams): Address {
  if (!internalUsd.underlyingTokenAddress) {
    throw new Error("HFUSD underlying token is not configured");
  }

  return internalUsd.underlyingTokenAddress as Address;
}

function getDepositInternalUsdPayAmount({
  params,
  longTokenAmount,
  shortTokenAmount,
  internalUsd,
}: {
  params: CreateDepositParams;
  longTokenAmount: bigint;
  shortTokenAmount: bigint;
  internalUsd: InternalUsdParams;
}) {
  let payAmount = 0n;

  if (params.addresses.initialLongToken.toLowerCase() === internalUsd.wrappedTokenAddress.toLowerCase()) {
    payAmount += longTokenAmount;
  }

  if (params.addresses.initialShortToken.toLowerCase() === internalUsd.wrappedTokenAddress.toLowerCase()) {
    payAmount += shortTokenAmount;
  }

  return payAmount;
}

export async function createDepositTxn({
  sdk,
  params,
  longTokenAmount,
  shortTokenAmount,
  internalUsd,
}: CreateDepositTxnParams): Promise<`0x${string}`> {
  if (!sdk.account) {
    throw new Error("SDK account is not defined");
  }

  const internalUsdPayAmount = internalUsd
    ? getDepositInternalUsdPayAmount({
        params,
        longTokenAmount,
        shortTokenAmount,
        internalUsd,
      })
    : 0n;
  if (internalUsd && internalUsdPayAmount <= 0n) {
    throw new Error("HFUSD LP deposit requires a positive underlying-token amount");
  }

  let minMarketTokens = params.minMarketTokens;
  if (params.addresses.receiver.toLowerCase() === FIRST_DEPOSIT_RECEIVER) {
    const configuredMinMarketTokens = await sdk.publicClient.readContract({
      address: getContract(sdk.chainId, "DataStore"),
      abi: abis.DataStore,
      functionName: "getUint",
      args: [minMarketTokensForFirstDepositKey(params.addresses.market)],
    });
    if (configuredMinMarketTokens > minMarketTokens) {
      minMarketTokens = configuredMinMarketTokens;
    }
  }

  const exchangeRouter = getContract(sdk.chainId, "ExchangeRouter");
  const depositVault = getContract(sdk.chainId, "DepositVault");

  const submitWithExecutionFee = (executionFee: bigint) => {
    const depositParams: CreateDepositParams = {
      ...params,
      addresses: {
        ...params.addresses,
        callbackContract: internalUsd ? zeroAddress : params.addresses.callbackContract,
      },
      minMarketTokens,
      executionFee,
      callbackGasLimit: internalUsd ? 0n : params.callbackGasLimit,
    };
    const fundingCalls = internalUsd
      ? (() => {
          const underlyingToken = requireUnderlyingToken(internalUsd);
          const bankAddress = internalUsd.bankAddress as Address;
          return [
            encodeRouterCall(abis.ExchangeRouter as Abi, "sendTokens", [
              underlyingToken,
              bankAddress,
              internalUsdPayAmount,
            ]),
            encodeRouterCall(abis.ExchangeRouter as Abi, "makeExternalCalls", [
              [bankAddress],
              [encodeBankMint(bankAddress, depositVault)],
              [],
              [],
            ]),
          ];
        })()
      : encodeTokenTransfers(abis.ExchangeRouter as Abi, depositVault, [
          { token: params.addresses.initialLongToken, amount: longTokenAmount },
          { token: params.addresses.initialShortToken, amount: shortTokenAmount },
        ]);
    const calls = [
      ...fundingCalls,
      encodeRouterCall(abis.ExchangeRouter as Abi, "sendWnt", [depositVault, executionFee]),
      encodeRouterCall(abis.ExchangeRouter as Abi, "createDeposit", [depositParams]),
    ];

    return sdk.callContract(exchangeRouter, abis.ExchangeRouter as Abi, "multicall", [calls], {
      value: executionFee,
    });
  };

  try {
    return await submitWithExecutionFee(params.executionFee);
  } catch (error) {
    const requiredExecutionFee = parseRequiredExecutionFeeFromError(error);
    if (requiredExecutionFee !== undefined && requiredExecutionFee > params.executionFee) {
      return submitWithExecutionFee(requiredExecutionFee);
    }
    throw error;
  }
}

export async function createWithdrawalTxn({
  sdk,
  params,
  marketTokenAmount,
}: CreateWithdrawalTxnParams): Promise<`0x${string}`> {
  const exchangeRouter = getContract(sdk.chainId, "ExchangeRouter");
  const withdrawalVault = getContract(sdk.chainId, "WithdrawalVault");

  const submitWithExecutionFee = (executionFee: bigint) => {
    const withdrawalParams: CreateWithdrawalParams = {
      ...params,
      executionFee,
    };
    const calls = [
      encodeRouterCall(abis.ExchangeRouter as Abi, "sendTokens", [
        params.addresses.market,
        withdrawalVault,
        marketTokenAmount,
      ]),
      encodeRouterCall(abis.ExchangeRouter as Abi, "sendWnt", [withdrawalVault, executionFee]),
      encodeRouterCall(abis.ExchangeRouter as Abi, "createWithdrawal", [withdrawalParams]),
    ];

    return sdk.callContract(exchangeRouter, abis.ExchangeRouter as Abi, "multicall", [calls], {
      value: executionFee,
    });
  };

  try {
    return await submitWithExecutionFee(params.executionFee);
  } catch (error) {
    const requiredExecutionFee = parseRequiredExecutionFeeFromError(error);
    if (requiredExecutionFee !== undefined && requiredExecutionFee > params.executionFee) {
      return submitWithExecutionFee(requiredExecutionFee);
    }

    throw error;
  }
}

export async function createHlvDepositTxn({
  sdk,
  hlvAddress,
  marketAddress,
  longTokenAmount,
  shortTokenAmount,
  minHlvTokens,
  executionFee,
  gasPrice,
  initialLongToken,
  initialShortToken,
  internalUsd,
  isFirstDeposit = false,
  marketAllocations,
}: CreateHlvDepositTxnParams): Promise<`0x${string}`> {
  if (!sdk.account) {
    throw new Error("SDK account is not defined");
  }

  const rawDepositParts =
    marketAllocations && marketAllocations.length > 0
      ? marketAllocations
      : [
          {
            marketAddress,
            longTokenAmount,
            shortTokenAmount,
            minHlvTokens,
          },
        ];
  const allocatedLongTokenAmount = rawDepositParts.reduce((sum, part) => sum + part.longTokenAmount, 0n);
  const allocatedShortTokenAmount = rawDepositParts.reduce((sum, part) => sum + part.shortTokenAmount, 0n);
  if (allocatedLongTokenAmount !== longTokenAmount || allocatedShortTokenAmount !== shortTokenAmount) {
    throw new Error("HLV deposit allocations must exactly match the funded token amounts");
  }

  const lastPartIndex = rawDepositParts.length - 1;
  let remainingLongTokenAmount = longTokenAmount;
  let remainingShortTokenAmount = shortTokenAmount;
  let remainingMinHlvTokens = minHlvTokens;
  const depositParts = rawDepositParts.map((part, index) => {
    const partLongTokenAmount = index === lastPartIndex ? remainingLongTokenAmount : part.longTokenAmount;
    const partShortTokenAmount = index === lastPartIndex ? remainingShortTokenAmount : part.shortTokenAmount;
    const partMinHlvTokens = index === lastPartIndex ? remainingMinHlvTokens : part.minHlvTokens;

    remainingLongTokenAmount =
      remainingLongTokenAmount > partLongTokenAmount ? remainingLongTokenAmount - partLongTokenAmount : 0n;
    remainingShortTokenAmount =
      remainingShortTokenAmount > partShortTokenAmount ? remainingShortTokenAmount - partShortTokenAmount : 0n;
    remainingMinHlvTokens = remainingMinHlvTokens > partMinHlvTokens ? remainingMinHlvTokens - partMinHlvTokens : 0n;

    return {
      marketAddress: part.marketAddress,
      longTokenAmount: partLongTokenAmount,
      shortTokenAmount: partShortTokenAmount,
      amount: partLongTokenAmount + partShortTokenAmount,
      minHlvTokens: partMinHlvTokens,
    };
  });

  if (isFirstDeposit && depositParts.length !== 1) {
    throw new Error("The first HFUSD HLV deposit requires a single market");
  }

  const hlvRouter = getContract(sdk.chainId, "HlvRouter");
  const hlvVault = getContract(sdk.chainId, "HlvVault");

  const submitWithExecutionFee = async (executionFeePerDeposit: bigint) => {
    let receiver = sdk.account as Address;
    if (isFirstDeposit) {
      receiver = FIRST_DEPOSIT_RECEIVER;
      const part = depositParts[0]!;
      const configuredMinHlvTokens = await sdk.publicClient.readContract({
        address: getContract(sdk.chainId, "DataStore"),
        abi: abis.DataStore,
        functionName: "getUint",
        args: [minHlvTokensForFirstDepositKey(hlvAddress)],
      });
      if (configuredMinHlvTokens > part.minHlvTokens) {
        part.minHlvTokens = configuredMinHlvTokens;
      }
    }

    const calls = depositParts.flatMap((part) => {
      const depositParams = {
        addresses: {
          hlv: hlvAddress,
          market: part.marketAddress,
          receiver,
          callbackContract: zeroAddress,
          uiFeeReceiver: zeroAddress,
          initialLongToken,
          initialShortToken,
          longTokenSwapPath: [],
          shortTokenSwapPath: [],
        },
        minHlvTokens: part.minHlvTokens,
        executionFee: executionFeePerDeposit,
        callbackGasLimit: 0n,
        shouldUnwrapNativeToken: false,
        isMarketTokenDeposit: false,
        dataList: [],
      };

      const fundingCalls = internalUsd
        ? (() => {
            const underlyingToken = requireUnderlyingToken(internalUsd);
            const bankAddress = internalUsd.bankAddress as Address;
            return [
              encodeRouterCall(abis.HlvRouter as Abi, "sendTokens", [underlyingToken, bankAddress, part.amount]),
              encodeRouterCall(abis.HlvRouter as Abi, "makeExternalCalls", [
                [bankAddress],
                [encodeBankMint(bankAddress, hlvVault)],
                [],
                [],
              ]),
            ];
          })()
        : encodeTokenTransfers(abis.HlvRouter as Abi, hlvVault, [
            { token: initialLongToken, amount: part.longTokenAmount },
            { token: initialShortToken, amount: part.shortTokenAmount },
          ]);

      return [
        ...fundingCalls,
        encodeRouterCall(abis.HlvRouter as Abi, "sendWnt", [hlvVault, executionFeePerDeposit]),
        encodeRouterCall(abis.HlvRouter as Abi, "createHlvDeposit", [depositParams]),
      ];
    });

    return sdk.callContract(hlvRouter, abis.HlvRouter as Abi, "multicall", [calls], {
      value: executionFeePerDeposit * BigInt(depositParts.length),
      ...(gasPrice !== undefined ? { gasPrice } : {}),
    });
  };

  try {
    return await submitWithExecutionFee(executionFee);
  } catch (error) {
    const requiredExecutionFee = parseRequiredExecutionFeeFromError(error);
    if (requiredExecutionFee !== undefined && requiredExecutionFee > executionFee) {
      return submitWithExecutionFee(requiredExecutionFee);
    }
    throw error;
  }
}

export async function createHlvWithdrawalTxn({
  sdk,
  hlvAddress,
  hlvTokenAddress,
  marketAddress,
  hlvTokenAmount,
  minLongTokenAmount,
  minShortTokenAmount,
  executionFee,
  gasPrice,
  marketAllocations,
}: CreateHlvWithdrawalTxnParams): Promise<`0x${string}`> {
  if (!sdk.account) {
    throw new Error("SDK account is not defined");
  }

  const withdrawalParts =
    marketAllocations && marketAllocations.length > 0
      ? marketAllocations
      : [
          {
            marketAddress,
            hlvTokenAmount,
            minLongTokenAmount,
            minShortTokenAmount,
          },
        ];
  const allocatedHlvTokenAmount = withdrawalParts.reduce((sum, part) => sum + part.hlvTokenAmount, 0n);
  if (allocatedHlvTokenAmount !== hlvTokenAmount) {
    throw new Error("HLV withdrawal allocations must exactly match the funded HLV token amount");
  }

  const hlvRouter = getContract(sdk.chainId, "HlvRouter");
  const hlvVault = getContract(sdk.chainId, "HlvVault");

  const submitWithExecutionFee = (executionFeePerWithdrawal: bigint) => {
    const calls = withdrawalParts.flatMap((part) => {
      const withdrawalParams = {
        addresses: {
          receiver: sdk.account,
          callbackContract: zeroAddress,
          uiFeeReceiver: zeroAddress,
          market: part.marketAddress,
          hlv: hlvAddress,
          longTokenSwapPath: [],
          shortTokenSwapPath: [],
        },
        minLongTokenAmount: part.minLongTokenAmount,
        minShortTokenAmount: part.minShortTokenAmount,
        shouldUnwrapNativeToken: false,
        executionFee: executionFeePerWithdrawal,
        callbackGasLimit: 0n,
        dataList: [],
      };

      return [
        encodeRouterCall(abis.HlvRouter as Abi, "sendTokens", [hlvTokenAddress, hlvVault, part.hlvTokenAmount]),
        encodeRouterCall(abis.HlvRouter as Abi, "sendWnt", [hlvVault, executionFeePerWithdrawal]),
        encodeRouterCall(abis.HlvRouter as Abi, "createHlvWithdrawal", [withdrawalParams]),
      ];
    });

    return sdk.callContract(hlvRouter, abis.HlvRouter as Abi, "multicall", [calls], {
      value: executionFeePerWithdrawal * BigInt(withdrawalParts.length),
      ...(gasPrice !== undefined ? { gasPrice } : {}),
    });
  };

  try {
    return await submitWithExecutionFee(executionFee);
  } catch (error) {
    const requiredExecutionFee = parseRequiredExecutionFeeFromError(error);
    if (requiredExecutionFee !== undefined && requiredExecutionFee > executionFee) {
      return submitWithExecutionFee(requiredExecutionFee);
    }
    throw error;
  }
}
