import concat from "lodash/concat";
import { Abi, encodeFunctionData, erc20Abi, getAddress, zeroAddress, zeroHash } from "viem";

import { abis } from "abis";
import { getContract } from "configs/contracts";
import { convertTokenAddress, NATIVE_TOKEN_ADDRESS } from "configs/tokens";
import type { HertzFlowSDK } from "index";
import { DecreasePositionSwapType, OrderPositionType, OrderTxnType, OrderType } from "types/orders";
import type { ExternalSwapQuote } from "types/externalSwap";
import { TokenData, TokenPrices, TokensData } from "types/tokens";
import { isMarketOrderType } from "utils/orders";
import { simulateExecuteOrder } from "utils/simulateExecuteOrder";
import { PEACH_BSC_ROUTER } from "modules/externalSwap";
import {
  buildInternalUsdMintExternalCalls,
  getInternalUsdOrderAddresses,
  validateInternalUsdWrappedToken,
  type InternalUsdParams,
} from "utils/internalUsd";
import { convertToContractPrice } from "utils/tokens";
import { applySlippageToMinOut, applySlippageToPrice } from "utils/trade";
import type { ExternalCallsPayload } from "utils/orderTransactions";

import { createCancelEncodedPayload } from "./cancelOrdersTxn";
import { createDecreaseEncodedPayload, DecreaseOrderParams } from "./createDecreaseOrderTxn";
import { createUpdateEncodedPayload } from "./updateOrderTxn";

export type PriceOverrides = {
  [address: string]: TokenPrices | undefined;
};

type IncreaseOrderParams = {
  account: string;
  marketAddress: string;
  initialCollateralAddress: string;
  targetCollateralAddress: string;
  initialCollateralAmount: bigint;
  swapPath: string[];
  sizeDeltaUsd: bigint;
  acceptablePrice: bigint;
  triggerPrice: bigint | undefined;
  isLong: boolean;
  orderType: OrderType.MarketIncrease | OrderType.LimitIncrease;
  orderPositionType: OrderPositionType;
  executionFee: bigint;
  allowedSlippage: number;
  skipSimulation?: boolean;
  referralCode: string | undefined;
  indexToken: TokenData;
  tokensData: TokensData;
  dataList?: string[];
  internalUsd?: InternalUsdParams;
  externalSwapQuote?: ExternalSwapQuote;
};

type SecondaryOrderCommonParams = {
  account: string;
  marketAddress: string;
  swapPath: string[];
  allowedSlippage: number;
  initialCollateralAddress: string;
  receiveTokenAddress: string;
  isLong: boolean;
  indexToken: TokenData;
  txnType: OrderTxnType;
  orderType: OrderType;
  sizeDeltaUsd: bigint;
  initialCollateralDeltaAmount: bigint;
  internalUsd?: InternalUsdParams;
};

export type SecondaryDecreaseOrderParams = DecreaseOrderParams & SecondaryOrderCommonParams;

export type SecondaryCancelOrderParams = SecondaryOrderCommonParams & {
  orderKey: string | null;
};

export type SecondaryUpdateOrderParams = SecondaryOrderCommonParams & {
  orderKey: string;
  sizeDeltaUsd: bigint;
  acceptablePrice: bigint;
  triggerPrice: bigint;
  executionFee: bigint;
  indexToken: TokenData;
  minOutputAmount: bigint;
  autoCancel: boolean;
};

export async function createIncreaseOrderTxn({
  sdk,
  createIncreaseOrderParams: p,
  createDecreaseOrderParams,
  cancelOrderParams,
  updateOrderParams,
}: {
  sdk: HertzFlowSDK;
  createIncreaseOrderParams: IncreaseOrderParams;
  createDecreaseOrderParams?: SecondaryDecreaseOrderParams[];
  cancelOrderParams?: SecondaryCancelOrderParams[];
  updateOrderParams?: SecondaryUpdateOrderParams[];
}) {
  if (p.internalUsd) {
    validateInternalUsdWrappedToken(p.internalUsd, p.targetCollateralAddress);
  }

  const isNativePayment = p.initialCollateralAddress === NATIVE_TOKEN_ADDRESS;
  const externalSwapQuote = p.externalSwapQuote;

  const chainId = sdk.chainId;

  const exchangeRouter = getContract(chainId, "ExchangeRouter");
  const orderVaultAddress = getContract(chainId, "OrderVault");
  const wntCollateralAmount = isNativePayment ? p.initialCollateralAmount : 0n;
  const initialCollateralTokenAddress = p.internalUsd
    ? p.internalUsd.wrappedTokenAddress
    : convertTokenAddress(chainId, p.initialCollateralAddress, "wrapped");
  const shouldApplySlippage = isMarketOrderType(p.orderType);
  const acceptablePrice = shouldApplySlippage
    ? applySlippageToPrice(p.allowedSlippage, p.acceptablePrice, true, p.isLong)
    : p.acceptablePrice;

  const wntAmountToIncrease = wntCollateralAmount + p.executionFee;
  const totalWntAmount = concat<undefined | SecondaryDecreaseOrderParams | SecondaryUpdateOrderParams>(
    createDecreaseOrderParams,
    updateOrderParams
  ).reduce((acc, p) => (p ? acc + p.executionFee : acc), wntAmountToIncrease);

  const encodedPayload = await createEncodedPayload({
    routerAbi: abis.ExchangeRouter as Abi,
    chainId,
    orderVaultAddress,
    totalWntAmount: wntAmountToIncrease,
    p,
    acceptablePrice,
    isNativePayment,
    initialCollateralTokenAddress,
    uiFeeReceiver: sdk.config.settings?.uiFeeReceiverAccount,
    externalSwapQuote,
  });

  const simulationEncodedPayload = await createEncodedPayload({
    routerAbi: abis.ExchangeRouter as Abi,
    chainId,
    orderVaultAddress,
    totalWntAmount: wntAmountToIncrease,
    p,
    acceptablePrice,
    isNativePayment,
    initialCollateralTokenAddress,
    uiFeeReceiver: sdk.config.settings?.uiFeeReceiverAccount,
    externalSwapQuote,
  });

  const decreaseEncodedPayload = createDecreaseEncodedPayload({
    sdk,
    orderVaultAddress,
    ps: createDecreaseOrderParams || [],
  });

  const cancelEncodedPayload = createCancelEncodedPayload(cancelOrderParams?.map(({ orderKey }) => orderKey) || []);
  const updateEncodedPayload =
    updateOrderParams?.reduce<string[]>(
      (
        acc,
        { orderKey, sizeDeltaUsd, executionFee, indexToken, acceptablePrice, triggerPrice, minOutputAmount, autoCancel }
      ) => {
        return [
          ...acc,
          ...createUpdateEncodedPayload({
            sdk,
            orderKey,
            sizeDeltaUsd,
            executionFee,
            indexTokenDecimals: indexToken.decimals,
            acceptablePrice,
            triggerPrice,
            minOutputAmount,
            autoCancel,
          }),
        ];
      },
      []
    ) ?? [];

  const primaryPriceOverrides: PriceOverrides = {};

  if (p.triggerPrice != undefined) {
    primaryPriceOverrides[p.indexToken.address] = {
      minPrice: p.triggerPrice,
      maxPrice: p.triggerPrice,
    };
  }

  if (!p.skipSimulation) {
    await simulateExecuteOrder(sdk, {
      tokensData: p.tokensData,
      primaryPriceOverrides,
      createMulticallPayload: simulationEncodedPayload,
      value: totalWntAmount,
    });
  }

  const finalPayload = [...encodedPayload, ...decreaseEncodedPayload, ...cancelEncodedPayload, ...updateEncodedPayload];

  return await sdk.callContract(exchangeRouter, abis.ExchangeRouter as Abi, "multicall", [finalPayload], {
    value: totalWntAmount,
  });
}

async function createEncodedPayload({
  routerAbi,
  chainId,
  orderVaultAddress,
  totalWntAmount,
  p,
  acceptablePrice,
  isNativePayment,
  initialCollateralTokenAddress,
  uiFeeReceiver,
  externalSwapQuote,
}: {
  routerAbi: Abi;
  chainId: number;
  orderVaultAddress: string;
  totalWntAmount: bigint;
  p: IncreaseOrderParams;
  acceptablePrice: bigint;
  isNativePayment: boolean;
  initialCollateralTokenAddress: string;
  uiFeeReceiver: string | undefined;
  externalSwapQuote: ExternalSwapQuote | undefined;
}) {
  const orderParams = createOrderParams({
    p,
    acceptablePrice,
    initialCollateralTokenAddress,
    isNativePayment,
    uiFeeReceiver,
  });
  const shouldMintInternalUsd = Boolean(p.internalUsd && p.initialCollateralAmount > 0n && !externalSwapQuote);
  const externalCalls = externalSwapQuote
    ? buildPeachExternalCalls({
        chainId,
        quote: externalSwapQuote,
        account: p.account,
        initialCollateralAddress: p.initialCollateralAddress,
        initialCollateralAmount: p.initialCollateralAmount,
        internalUsd: p.internalUsd,
      })
    : shouldMintInternalUsd
    ? buildInternalUsdMintExternalCalls({
        chainId: chainId as any,
        payTokenAddress: p.initialCollateralAddress,
        payTokenAmount: p.initialCollateralAmount,
        internalUsd: p.internalUsd!,
        mintReceiver: orderVaultAddress,
      })
    : undefined;
  const mintExternalCalls = externalSwapQuote
    ? {
        externalCallTargets: [p.internalUsd!.bankAddress],
        externalCallDataList: [
          encodeFunctionData({
            abi: abis.HFBank,
            functionName: "mint",
            args: [getAddress(orderVaultAddress) as `0x${string}`],
          }),
        ],
        refundTokens: [],
        refundReceivers: [],
      }
    : undefined;

  const multicall = [
    { method: "sendWnt", params: [orderVaultAddress, externalSwapQuote ? p.executionFee : totalWntAmount] },

    externalSwapQuote && isNativePayment
      ? {
          method: "sendWnt",
          params: [getContract(chainId as any, "ExternalHandler"), p.initialCollateralAmount],
        }
      : externalSwapQuote
      ? {
          method: "sendTokens",
          params: [p.initialCollateralAddress, getContract(chainId as any, "ExternalHandler"), p.initialCollateralAmount],
        }
      : !isNativePayment
      ? {
          method: "sendTokens",
          params: [
            p.initialCollateralAddress,
            shouldMintInternalUsd ? p.internalUsd!.bankAddress : orderVaultAddress,
            p.initialCollateralAmount,
          ],
        }
      : undefined,

    externalCalls
      ? {
          method: "makeExternalCalls",
          params: [
            externalCalls.externalCallTargets,
            externalCalls.externalCallDataList,
            externalCalls.refundTokens,
            externalCalls.refundReceivers,
          ],
        }
      : undefined,

    mintExternalCalls
      ? {
          method: "makeExternalCalls",
          params: [
            mintExternalCalls.externalCallTargets,
            mintExternalCalls.externalCallDataList,
            mintExternalCalls.refundTokens,
            mintExternalCalls.refundReceivers,
          ],
        }
      : undefined,

    {
      method: "createOrder",
      params: [orderParams],
    },
  ];
  return multicall.filter(Boolean).map((call) =>
    encodeFunctionData({
      abi: routerAbi,
      functionName: call!.method,
      args: call!.params,
    })
  );
}

function buildPeachExternalCalls({
  chainId,
  quote,
  account,
  initialCollateralAddress,
  initialCollateralAmount,
  internalUsd,
}: {
  chainId: number;
  quote: ExternalSwapQuote;
  account: string;
  initialCollateralAddress: string;
  initialCollateralAmount: bigint;
  internalUsd: InternalUsdParams | undefined;
}): ExternalCallsPayload {
  if (!internalUsd) throw new Error("Peach HFUSD orders require internal USD configuration");
  if (quote.source !== "peach") throw new Error("Unsupported external swap provider");
  if (quote.routerAddress.toLowerCase() !== PEACH_BSC_ROUTER.toLowerCase()) {
    throw new Error("Peach quote router is not trusted");
  }
  if (quote.transaction.to.toLowerCase() !== quote.routerAddress.toLowerCase()) {
    throw new Error("Peach quote transaction target must match routerAddress");
  }
  if (quote.transaction.data === "0x") {
    throw new Error("Peach quote transaction calldata is empty");
  }
  if (quote.transaction.value !== 0n || quote.isNativeOut) {
    throw new Error("Peach HFUSD order requires ERC20 swap calldata with zero value");
  }
  if (quote.deadline <= BigInt(Math.floor(Date.now() / 1000))) throw new Error("Peach quote has expired");
  if (quote.amountIn !== initialCollateralAmount) throw new Error("Peach quote amountIn must match collateral amount");
  if (quote.tokenOut.toLowerCase() !== (internalUsd.underlyingTokenAddress ?? "").toLowerCase()) {
    throw new Error("Peach quote output must match the internal USD underlying token");
  }

  const expectedTokenIn = initialCollateralAddress === NATIVE_TOKEN_ADDRESS
    ? convertTokenAddress(chainId as any, NATIVE_TOKEN_ADDRESS, "wrapped")
    : initialCollateralAddress;
  if (quote.tokenIn.toLowerCase() !== expectedTokenIn.toLowerCase()) {
    throw new Error("Peach quote input must match the payment token");
  }

  return {
    sendTokens: [],
    sendAmounts: [],
    externalCallTargets: [quote.tokenIn, quote.routerAddress],
    externalCallDataList: [
      encodeFunctionData({ abi: erc20Abi, functionName: "approve", args: [getAddress(quote.routerAddress), quote.amountIn] }),
      quote.transaction.data,
    ],
    refundTokens: [quote.tokenIn, quote.tokenOut],
    refundReceivers: [getAddress(account), getAddress(internalUsd.bankAddress)],
  };
}

function createOrderParams({
  p,
  acceptablePrice,
  initialCollateralTokenAddress,
  isNativePayment,
  uiFeeReceiver,
}: {
  p: IncreaseOrderParams;
  acceptablePrice: bigint;
  initialCollateralTokenAddress: string;
  isNativePayment: boolean;
  uiFeeReceiver: string | undefined;
}) {
  const orderAddresses = p.internalUsd
    ? getInternalUsdOrderAddresses(p.account)
    : {
        receiver: p.account,
        cancellationReceiver: zeroAddress,
        callbackContract: zeroAddress,
        callbackGasLimit: 0n,
      };

  return {
    addresses: {
      cancellationReceiver: orderAddresses.cancellationReceiver,
      receiver: orderAddresses.receiver,
      initialCollateralToken: initialCollateralTokenAddress,
      callbackContract: orderAddresses.callbackContract,
      market: p.marketAddress,
      swapPath: p.swapPath,
      uiFeeReceiver: uiFeeReceiver || zeroAddress,
    },
    numbers: {
      sizeDeltaUsd: p.sizeDeltaUsd,
      initialCollateralDeltaAmount: 0n,
      triggerPrice: convertToContractPrice(p.triggerPrice ?? 0n, p.indexToken.decimals),
      acceptablePrice: convertToContractPrice(acceptablePrice, p.indexToken.decimals),
      executionFee: p.executionFee,
      callbackGasLimit: orderAddresses.callbackGasLimit,
      minOutputAmount: 0n,
      validFromTime: 0n,
    },
    orderType: p.orderType,
    decreasePositionSwapType: DecreasePositionSwapType.NoSwap,
    isLong: p.isLong,
    shouldUnwrapNativeToken: isNativePayment,
    autoCancel: false,
    referralCode: p.referralCode || zeroHash,
    orderPositionType: p.orderPositionType,
    dataList: p.dataList ?? [],
  };
}

export function getPendingOrderFromParams(
  chainId: number,
  txnType: OrderTxnType,
  p: DecreaseOrderParams | SecondaryUpdateOrderParams | SecondaryCancelOrderParams
) {
  const shouldApplySlippage = isMarketOrderType(p.orderType);
  let minOutputAmount = 0n;
  if ("minOutputUsd" in p) {
    // eslint-disable-next-line
    shouldApplySlippage ? applySlippageToMinOut(p.allowedSlippage, p.minOutputUsd) : p.minOutputUsd;
  }
  if ("minOutputAmount" in p) {
    minOutputAmount = p.minOutputAmount;
  }
  const initialCollateralTokenAddress = p.internalUsd
    ? p.internalUsd.wrappedTokenAddress
    : convertTokenAddress(chainId, p.initialCollateralAddress, "wrapped");

  const orderKey = "orderKey" in p && p.orderKey ? p.orderKey : undefined;

  return {
    txnType,
    account: p.account,
    marketAddress: p.marketAddress,
    initialCollateralTokenAddress,
    initialCollateralDeltaAmount: p.initialCollateralDeltaAmount,
    swapPath: p.swapPath,
    sizeDeltaUsd: p.sizeDeltaUsd,
    minOutputAmount: minOutputAmount,
    isLong: p.isLong,
    orderType: p.orderType,
    shouldUnwrapNativeToken: false,
    orderKey,
  };
}
