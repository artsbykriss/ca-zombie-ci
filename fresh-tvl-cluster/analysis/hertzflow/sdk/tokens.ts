import { getAddress, zeroAddress } from "viem";

import type { Token, TokenAddressTypesMap } from "types/tokens";

import { SOURCE_BSC_MAINNET, SOURCE_BSC_TESTNET } from "./chains";

export const NATIVE_TOKEN_ADDRESS = zeroAddress;

const createSyntheticTokens = (configs: readonly (readonly [symbol: string, address: string])[]): Token[] =>
  configs.map(([marketSymbol, address]) => {
    const symbol = marketSymbol.endsWith("/USD") ? marketSymbol.slice(0, -4) : marketSymbol;
    return {
      name: symbol,
      symbol,
      decimals: 18,
      address: getAddress(address),
      isSynthetic: true,
    };
  });

// Baseline index tokens for the markets currently configured in this SDK.
// Newly listed markets can add token metadata through HertzFlowSdkConfig.tokens.
const MAINNET_SYNTHETIC_TOKENS = createSyntheticTokens([
  ["DOGE/USD", "0x14b61d2e6065752d2039ebfc0081888e33496cc2"],
  ["ETH/USD", "0x683083beef2cd42e05c4a6487a213a78797ab01a"],
  ["BNB/USD", "0x3bc2b65604e18c4a9181c6fd97b1d3ccc8a89b18"],
  ["BTC/USD", "0x26c52b0b6a890e95748253193ead9c676b58258f"],
]);

const TESTNET_SYNTHETIC_TOKENS = createSyntheticTokens([
  ["BTC/USD", "0x2d8f28f05113c2dc0a17ebbba60d8f72318bdb1f"],
  ["ETH/USD", "0x2c08e4b0442381bb2f6e70943c94f991345be236"],
  ["DOGE/USD", "0x511c4671bfbe6180f2ac51843bfa0bcffc59bc4a"],
  ["BNB/USD", "0xbd36ecff5b38569edb70881372b1de79da073920"],
  ["PEPE/USD", "0xbfb51f94a0d823ffdbf0061bbf0c7160864f42e1"],
  ["NVDA/USD", "0xd92f09fb5653d9759310da40d70aa2fadb74d983"],
  ["TSLA/USD", "0x0bd2f9b566eadf4a7576e7e00c3e4f84c6cf06f7"],
  ["XAU/USD", "0x2ac10b74b967298af93216364f3067c509833259"],
  ["WIF/USD", "0xeea6ee78f056c38dec6d3d18e8d668fd1291700f"],
  ["USD/JPY", "0x2e95b266f4b5590831af722beae74f9722dd49ec"],
  ["XAG/USD", "0x5f3828e2b3f1f36ae682d027bdb106ef7eb54fca"],
  ["BONK/USD", "0x9fe34d5651da27099c1709328980352bae0c8eab"],
  ["GOOG/USD", "0xb5e48b6db7cdb2b35483b1301d0a1e7ed534c4e8"],
  ["EUR/USD", "0x92e6448ea7de9fd9ae2aaf1960d110f2359c4321"],
  ["AAPL/USD", "0xea8190b9e28ba0682cb4dc8dfb3b4c3afe4a536b"],
  ["FARTCOIN/USD", "0xab354230f520d38d7484d76749de7b7d8ba4a678"],
  ["SOL/USD", "0x9dc796246f1a9723f269b201efbe5df3f2ab666a"],
  ["HYPE/USD", "0x683939d7cb0b3fd714b014e29663b95de65ff7b8"],
  ["GRASS/USD", "0xc8aaac280edf0ba18d26a2386d50fc934c045b0b"],
  ["XRP/USD", "0x38b0533486c703f3f73797f2148ceec1ac2f2b94"],
  ["AERO/USD", "0xb925add974ff578c86ab1077777d381690469d24"],
  ["ARM/USD", "0xfb681274bddc2f6889b1876bdbcbc84337393e94"],
  ["0G/USD", "0x8efb4bfa9a3a760884f56d4ad57bc6ade4d0b33c"],
  ["POPCAT/USD", "0x5b913688886db19e01fc866c6b9fbced416bd4ed"],
  ["SHIB/USD", "0x922edbe14205350c90b791858525704223483df0"],
  ["ZETA/USD", "0x3d98106f0911930a606ce5294f6a90f40964d989"],
  ["MSTR/USD", "0xc6bcf9ca2397dd769edd64930e6b4dc6ffd0184e"],
  ["HOOD/USD", "0xdbbf6b69416e31189f5f426801ca3c67cd0faadc"],
  ["QQQ/USD", "0x8d33b6e4f8c3e7f4b7596e2a5f9ba089a50190fe"],
  ["AMD/USD", "0x40b8309504ed8793fb9b17cdb34caf1d0691a7d9"],
  ["USD/CAD", "0x63d3cb2ff1a79cdd49397f81143ca72b54a288cb"],
  ["ASTS/USD", "0xa05e279103b2d59c628cdf6c11e30739746e23b6"],
  ["MRVL/USD", "0x663de62a4be589533b30b08a55009ce27c75c003"],
  ["MU/USD", "0x963c6ecf363fb9fa315acd7079e7720b34fd7c9c"],
  ["RKLB/USD", "0x1056352e47551bbcb197da19d5aafbd0c300f14e"],
  ["MOODENG/USD", "0xff2ffc2b201ad36046c1c2b7510dddc71058257b"],
  ["GBP/USD", "0x7dec209d48139717ed7752c87685dc8000684db6"],
  ["MSFT/USD", "0xcb9a88ec3ba3f76c98487e0cf3257e8e741d073b"],
  ["USD/CHF", "0x59a9e6f73ce7adb0bb91ed64935670f1df14fa17"],
  ["ZORA/USD", "0xdf1f95fb50a02d8e045461a282e68d4b1b966d25"],
  ["SPY/USD", "0x2b73e8186352b46a2e0b8410aa7782f54ed7316a"],
  ["AUD/USD", "0xa687e29bcd3655cdba7109c353c9ca57904437b8"],
  ["AVGO/USD", "0x1d103efa216251ec4499e2974d9d3c936fd7eaf8"],
  ["SAFE/USD", "0xff70661b9f0e210d6521aa84547804c5e23ecef3"],
  ["CRCL/USD", "0x418aec10a6d9194a0931b77e85d5db4ee67598f4"],
  ["OKLO/USD", "0xfa79d6b104e1bc1e96caa6e42488e27e89a59c9a"],
  ["PLTR/USD", "0x23a045e3a048936805a803bb1e5297922c1be3c1"],
  ["NBIS/USD", "0x525f6b54d1898073c1054ecf3f3d73c6485d1fbe"],
  ["COIN/USD", "0xb93cad14b71bfcba84c6e1077998906b94cd60ca"],
  ["AMZN/USD", "0x1ed799b47026c20d90e5ad80360c7efd18fc003f"],
  ["IREN/USD", "0xcded8baaf2e2670cb3c3d0e3a5891436a7aa1c59"],
  ["META/USD", "0xc12a50d37590cca1c33907efe9e72c55981a6f71"],
  ["HIMS/USD", "0x954ce2286f69522ec9631583c0eabbf06e7d8b29"],
  ["USDXY/USD", "0x77e587a0dae01a49c35e656d481e177ec6d2d53d"],
  ["RIVN/USD", "0xbe1eec86253b64278363ec4d52f039964297e2bc"],
  ["TSM/USD", "0x6ace0c402d16c756ce6aac37103d4c81013cbd47"],
  ["CRWV/USD", "0x541b92fbe2370982d652f2140f18b99b1887afc0"],
  ["DRIFT/USD", "0x933c831265efbc5b58d445647f758bd8d802d949"],
  ["IP/USD", "0xb09bc8fa8de878936173212b3d7881aa5fbfd048"],
  ["USOILSPOT/USD", "0xc96b746f27a8a327af689784fc854c3917c165ae"],
  ["UKOILSPOT/USD", "0x0686877cc60526b8cfe78b6fc1924c5a2f2c8bbc"],
]);

export const TOKENS: { [chainId: number]: Token[] } = {
  [SOURCE_BSC_MAINNET]: [
    {
      name: "BNB",
      symbol: "BNB",
      decimals: 18,
      address: NATIVE_TOKEN_ADDRESS,
      isNative: true,
      isShortable: true,
    },
    {
      name: "Wrapped BNB",
      symbol: "WBNB",
      decimals: 18,
      address: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
      isWrapped: true,
      baseSymbol: "BNB",
    },
    {
      name: "Tether USD",
      symbol: "USDT",
      decimals: 18,
      address: "0x55d398326f99059fF775485246999027B3197955",
      isStable: true,
    },
    {
      name: "USD1",
      symbol: "USD1",
      decimals: 18,
      address: "0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d",
      isStable: true,
    },
    {
      name: "Hertzflow USD",
      symbol: "HFUSD",
      decimals: 18,
      address: "0x3Cc4C9cbDa158909D385e8B4EbDD80867067623E",
      isStable: true,
    },
    {
      name: "Hertzflow USD1",
      symbol: "HFUSD1",
      decimals: 18,
      address: "0x4928e8dBc3743241eACbC57172a2EC45e5284Cb2",
      isStable: true,
    },
    ...MAINNET_SYNTHETIC_TOKENS,
  ],
  [SOURCE_BSC_TESTNET]: [
    {
      name: "BNB",
      symbol: "BNB",
      decimals: 18,
      address: NATIVE_TOKEN_ADDRESS,
      isNative: true,
      isShortable: true,
    },
    {
      name: "Wrapped BNB",
      symbol: "WBNB",
      decimals: 18,
      address: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
      isWrapped: true,
      baseSymbol: "BNB",
    },
    {
      name: "Tether USD",
      symbol: "USDT",
      decimals: 18,
      address: "0x6335881872FEcab922d1d83c6Bae6E27C5a9209c",
      isStable: true,
    },
    {
      name: "Hertzflow USD",
      symbol: "HFUSD",
      decimals: 18,
      address: "0x22527Bb489A0c7d91F63E63226b14f979f5FF090",
      isStable: true,
    },
    ...TESTNET_SYNTHETIC_TOKENS,
  ],
};

export const TOKENS_MAP: { [chainId: number]: { [address: string]: Token } } = {};
export const V2_TOKENS: { [chainId: number]: Token[] } = {};
export const SYNTHETIC_TOKENS: { [chainId: number]: Token[] } = {};
export const TOKENS_BY_SYMBOL_MAP: { [chainId: number]: { [symbol: string]: Token } } = {};
export const WRAPPED_TOKENS_MAP: { [chainId: number]: Token } = {};
export const NATIVE_TOKENS_MAP: { [chainId: number]: Token } = {};

const CHAIN_IDS = [SOURCE_BSC_MAINNET, SOURCE_BSC_TESTNET];

for (let j = 0; j < CHAIN_IDS.length; j++) {
  const chainId = CHAIN_IDS[j];

  TOKENS_MAP[chainId] = {};
  TOKENS_BY_SYMBOL_MAP[chainId] = {};
  SYNTHETIC_TOKENS[chainId] = [];
  V2_TOKENS[chainId] = [];

  let tokens = TOKENS[chainId];
  let wrappedTokenAddress: string | undefined;

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    TOKENS_MAP[chainId][token.address] = token;
    TOKENS_BY_SYMBOL_MAP[chainId][token.symbol] ??= token;

    if (token.isWrapped) {
      WRAPPED_TOKENS_MAP[chainId] = token;
      wrappedTokenAddress = token.address;
    }

    if (token.isNative) {
      NATIVE_TOKENS_MAP[chainId] = token;
    }

    V2_TOKENS[chainId].push(token);

    if (token.isSynthetic) {
      SYNTHETIC_TOKENS[chainId].push(token);
    }
  }

  NATIVE_TOKENS_MAP[chainId].wrappedAddress = wrappedTokenAddress;
}

export function getWrappedToken(chainId: number) {
  return WRAPPED_TOKENS_MAP[chainId];
}

export function getNativeToken(chainId: number) {
  return NATIVE_TOKENS_MAP[chainId];
}

export function getTokens(chainId: number) {
  return TOKENS[chainId];
}

export function getV2Tokens(chainId: number) {
  return V2_TOKENS[chainId];
}

export function getTokensMap(chainId: number) {
  return TOKENS_MAP[chainId];
}

export function getToken(chainId: number, address: string) {
  if (!TOKENS_MAP[chainId]) {
    throw new Error(`Incorrect chainId ${chainId}`);
  }
  if (!TOKENS_MAP[chainId][address]) {
    throw new Error(`Incorrect address "${address}" for chainId ${chainId}`);
  }

  return TOKENS_MAP[chainId][address];
}

export function getTokenBySymbol(
  chainId: number,
  symbol: string,
  {
    isSynthetic,
    version,
    symbolType = "symbol",
  }: { isSynthetic?: boolean; version?: "v2"; symbolType?: "symbol" | "baseSymbol" } = {}
) {
  let tokens = Object.values(TOKENS_MAP[chainId]);

  if (version) {
    tokens = getV2Tokens(chainId);
  }

  let token: Token | undefined;

  if (isSynthetic !== undefined) {
    token = tokens.find((token) => {
      return token[symbolType]?.toLowerCase() === symbol.toLowerCase() && Boolean(token.isSynthetic) === isSynthetic;
    });
  } else {
    if (symbolType === "symbol" && TOKENS_BY_SYMBOL_MAP[chainId][symbol]) {
      token = TOKENS_BY_SYMBOL_MAP[chainId][symbol];
    } else {
      token = tokens.find((token) => token[symbolType]?.toLowerCase() === symbol.toLowerCase());
    }
  }

  if (!token) {
    throw new Error(`Incorrect symbol "${symbol}" for chainId ${chainId}`);
  }

  return token;
}

export function convertTokenAddress<T extends keyof TokenAddressTypesMap, R extends TokenAddressTypesMap[T]>(
  chainId: number,
  address: string,
  convertTo?: T
): R {
  const wrappedToken = getWrappedToken(chainId);

  if (convertTo === "wrapped" && address === NATIVE_TOKEN_ADDRESS) {
    return wrappedToken.address as R;
  }

  if (convertTo === "native" && address === wrappedToken.address) {
    return NATIVE_TOKEN_ADDRESS as R;
  }

  return address as R;
}

export function getTokenVisualMultiplier(token: Token): string {
  return token.visualPrefix || token.visualMultiplier?.toString() || "";
}
