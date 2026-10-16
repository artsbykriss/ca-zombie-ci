import fetch from "cross-fetch";

import type { HertzFlowSDK } from "../index";
import { buildUrl } from "utils/buildUrl";

export type PriceRes = {
  symbol: string;
  price: string;
  bsc_token_addr: string;
  timestamp: number;
};

export class Oracle {
  constructor(public sdk: HertzFlowSDK) {}

  async getLatestPrices(): Promise<PriceRes[]> {
    const oracleUrl = this.sdk.config.oracleUrl;
    if (!oracleUrl) {
      throw new Error("oracleUrl is required to fetch latest prices");
    }

    const response = await fetch(
      buildUrl(oracleUrl, "/v1/latestPrice", { get_all: true })
    ).then((res) => res.json());

    if (!response?.data || !Array.isArray(response.data.prices)) {
      throw new Error("Invalid latest price response");
    }
    return response.data.prices;
  }
}
