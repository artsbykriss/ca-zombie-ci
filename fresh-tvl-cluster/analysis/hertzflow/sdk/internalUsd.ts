import { type Address, type PublicClient, zeroAddress } from "viem";

import { abis } from "abis";
import type { InternalUsdParams } from "utils/internalUsd";

import { type ContractsChainId, SOURCE_BSC_MAINNET, SOURCE_BSC_TESTNET } from "./chains";
import { getContract } from "./contracts";

export type InternalUsdChainConfig = {
  underlyingTokenAddress: Address;
  wrappedTokenAddress: Address;
  bankAddress: Address;
};

export const INTERNAL_USD_CONFIGS: Partial<Record<ContractsChainId, readonly InternalUsdChainConfig[]>> = {
  [SOURCE_BSC_MAINNET]: [
    {
      underlyingTokenAddress: "0x55d398326f99059fF775485246999027B3197955",
      wrappedTokenAddress: "0x3Cc4C9cbDa158909D385e8B4EbDD80867067623E",
      bankAddress: "0x1b40AE150e956EA1B01e6d6A9dfeE498961D6fFd",
    },
    {
      underlyingTokenAddress: "0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d",
      wrappedTokenAddress: "0x4928e8dBc3743241eACbC57172a2EC45e5284Cb2",
      bankAddress: "0xB5D271f5Ce7553bFFeCD6d840a37C315f7d17080",
    },
  ],
  [SOURCE_BSC_TESTNET]: [
    {
      underlyingTokenAddress: "0x6335881872FEcab922d1d83c6Bae6E27C5a9209c",
      wrappedTokenAddress: "0x22527Bb489A0c7d91F63E63226b14f979f5FF090",
      bankAddress: "0xeF1efFAB1A632E5D75F4E93F2375989f6fFCce79",
    },
  ],
};

const runtimeInternalUsdConfigs = new Map<number, Map<string, InternalUsdChainConfig>>();
const nonInternalUsdTokens = new Map<number, Set<string>>();

function normalizeAddress(address: string): string {
  return address.toLowerCase();
}

function getStaticInternalUsdConfigs(chainId: number | undefined): readonly InternalUsdChainConfig[] {
  if (!chainId) return [];
  return INTERNAL_USD_CONFIGS[chainId as ContractsChainId] ?? [];
}

export function getInternalUsdConfigs(chainId: number | undefined): readonly InternalUsdChainConfig[] {
  if (!chainId) return [];
  const staticConfigs = getStaticInternalUsdConfigs(chainId);
  const configsByWrapper = new Map(
    staticConfigs.map((config) => [normalizeAddress(config.wrappedTokenAddress), config])
  );

  for (const [wrapperAddress, config] of runtimeInternalUsdConfigs.get(chainId) ?? []) {
    if (!configsByWrapper.has(wrapperAddress)) {
      configsByWrapper.set(wrapperAddress, config);
    }
  }

  return Array.from(configsByWrapper.values());
}

export function getInternalUsdConfig(
  chainId: number | undefined,
  wrappedTokenAddress?: string
): InternalUsdChainConfig | undefined {
  const configs = getInternalUsdConfigs(chainId);
  if (configs.length === 0) return undefined;
  if (!wrappedTokenAddress) return configs[0];

  return configs.find((config) => config.wrappedTokenAddress.toLowerCase() === wrappedTokenAddress.toLowerCase());
}

export function clearRuntimeInternalUsdConfigs(chainId?: number): void {
  if (chainId === undefined) {
    runtimeInternalUsdConfigs.clear();
    nonInternalUsdTokens.clear();
    return;
  }

  runtimeInternalUsdConfigs.delete(chainId);
  nonInternalUsdTokens.delete(chainId);
}

export async function hydrateInternalUsdConfigs({
  chainId,
  wrappedTokenAddresses,
  publicClient,
}: {
  chainId: ContractsChainId;
  wrappedTokenAddresses: readonly Address[];
  publicClient: Pick<PublicClient, "multicall">;
}): Promise<readonly InternalUsdChainConfig[]> {
  const factoryAddress = getContract(chainId, "HFBankFactory");
  const runtimeConfigs = runtimeInternalUsdConfigs.get(chainId) ?? new Map<string, InternalUsdChainConfig>();
  const knownNonInternalTokens = nonInternalUsdTokens.get(chainId) ?? new Set<string>();
  runtimeInternalUsdConfigs.set(chainId, runtimeConfigs);
  nonInternalUsdTokens.set(chainId, knownNonInternalTokens);

  const unresolvedWrappers = Array.from(
    new Map(wrappedTokenAddresses.map((address) => [normalizeAddress(address), address])).values()
  ).filter((address) => {
    const normalizedAddress = normalizeAddress(address);
    return !getInternalUsdConfig(chainId, address) && !knownNonInternalTokens.has(normalizedAddress);
  });

  if (unresolvedWrappers.length === 0) {
    return getInternalUsdConfigs(chainId);
  }

  const results = await publicClient.multicall({
    allowFailure: false,
    contracts: unresolvedWrappers.flatMap((wrappedTokenAddress) => [
      {
        address: factoryAddress,
        abi: abis.HFBankFactory,
        functionName: "getBankByWrappedToken",
        args: [wrappedTokenAddress],
      },
      {
        address: factoryAddress,
        abi: abis.HFBankFactory,
        functionName: "underlyingByWrappedToken",
        args: [wrappedTokenAddress],
      },
    ]),
  });

  unresolvedWrappers.forEach((wrappedTokenAddress, index) => {
    const bankAddress = results[index * 2] as Address;
    const underlyingTokenAddress = results[index * 2 + 1] as Address;
    const normalizedAddress = normalizeAddress(wrappedTokenAddress);

    if (bankAddress === zeroAddress || underlyingTokenAddress === zeroAddress) {
      knownNonInternalTokens.add(normalizedAddress);
      return;
    }

    runtimeConfigs.set(normalizedAddress, {
      bankAddress,
      wrappedTokenAddress,
      underlyingTokenAddress,
    });
  });

  return getInternalUsdConfigs(chainId);
}

export async function getOrResolveInternalUsdConfig({
  chainId,
  wrappedTokenAddress,
  publicClient,
}: {
  chainId: ContractsChainId;
  wrappedTokenAddress: Address;
  publicClient: Pick<PublicClient, "multicall">;
}): Promise<InternalUsdChainConfig | undefined> {
  const configured = getInternalUsdConfig(chainId, wrappedTokenAddress);
  if (configured) return configured;

  await hydrateInternalUsdConfigs({
    chainId,
    wrappedTokenAddresses: [wrappedTokenAddress],
    publicClient,
  });
  return getInternalUsdConfig(chainId, wrappedTokenAddress);
}

export async function resolveInternalUsdConfig({
  chainId,
  wrappedTokenAddress,
  publicClient,
}: {
  chainId: ContractsChainId;
  wrappedTokenAddress: Address;
  publicClient: Pick<PublicClient, "multicall">;
}): Promise<InternalUsdChainConfig> {
  const factoryAddress = getContract(chainId, "HFBankFactory");
  const [bankAddress, underlyingTokenAddress] = await publicClient.multicall({
    allowFailure: false,
    contracts: [
      {
        address: factoryAddress,
        abi: abis.HFBankFactory,
        functionName: "getBankByWrappedToken",
        args: [wrappedTokenAddress],
      },
      {
        address: factoryAddress,
        abi: abis.HFBankFactory,
        functionName: "underlyingByWrappedToken",
        args: [wrappedTokenAddress],
      },
    ],
  });

  if (bankAddress === zeroAddress || underlyingTokenAddress === zeroAddress) {
    throw new Error(`No HFBank registered for wrapped token ${wrappedTokenAddress}`);
  }

  return {
    bankAddress,
    wrappedTokenAddress,
    underlyingTokenAddress,
  };
}

export async function validateInternalUsdConfig({
  chainId,
  config,
  publicClient,
}: {
  chainId: ContractsChainId;
  config: InternalUsdChainConfig;
  publicClient: Pick<PublicClient, "multicall">;
}): Promise<void> {
  const resolved = await resolveInternalUsdConfig({
    chainId,
    wrappedTokenAddress: config.wrappedTokenAddress,
    publicClient,
  });

  if (
    resolved.bankAddress.toLowerCase() !== config.bankAddress.toLowerCase() ||
    resolved.underlyingTokenAddress.toLowerCase() !== config.underlyingTokenAddress.toLowerCase()
  ) {
    throw new Error(`Internal USD config does not match HFBankFactory for ${config.wrappedTokenAddress}`);
  }
}

function buildInternalUsdParams(config: InternalUsdChainConfig): InternalUsdParams {
  return {
    bankAddress: config.bankAddress,
    wrappedTokenAddress: config.wrappedTokenAddress,
    underlyingTokenAddress: config.underlyingTokenAddress,
  };
}

export function getInternalUsdParamsForInst(chainId: number | undefined, inst: unknown): InternalUsdParams | undefined {
  if (!inst || typeof inst !== "object") return undefined;

  const market = inst as {
    longTokenAddress?: string;
    shortTokenAddress?: string;
  };

  return getInternalUsdParamsForMarketTokens({
    chainId,
    longTokenAddress: market.longTokenAddress,
    shortTokenAddress: market.shortTokenAddress,
  });
}

export function getTradePayTokenAddress({
  chainId,
  inst,
  collateralTokenAddress,
}: {
  chainId: number | undefined;
  inst: unknown;
  collateralTokenAddress: string | undefined;
}) {
  const internalUsd = getInternalUsdParamsForInst(chainId, inst);
  if (!internalUsd || !collateralTokenAddress) return collateralTokenAddress;

  return collateralTokenAddress.toLowerCase() === internalUsd.wrappedTokenAddress.toLowerCase()
    ? internalUsd.underlyingTokenAddress
    : collateralTokenAddress;
}

export function getInternalUsdCollateralPriceTokenAddress({
  chainId,
  collateralTokenAddress,
}: {
  chainId: number | undefined;
  collateralTokenAddress: string | undefined;
}) {
  if (!chainId || !collateralTokenAddress) return collateralTokenAddress;
  const config = getInternalUsdConfig(chainId, collateralTokenAddress);
  if (!config) return collateralTokenAddress;

  return collateralTokenAddress.toLowerCase() === config.wrappedTokenAddress.toLowerCase()
    ? config.underlyingTokenAddress
    : collateralTokenAddress;
}

export function getInternalUsdParamsForMarketTokens({
  chainId,
  longTokenAddress,
  shortTokenAddress,
}: {
  chainId: number | undefined;
  longTokenAddress: string | undefined;
  shortTokenAddress: string | undefined;
}): InternalUsdParams | undefined {
  if (!longTokenAddress || !shortTokenAddress) return undefined;
  if (longTokenAddress.toLowerCase() !== shortTokenAddress.toLowerCase()) return undefined;
  const config = getInternalUsdConfig(chainId, longTokenAddress);
  if (!config) return undefined;

  return buildInternalUsdParams(config);
}
