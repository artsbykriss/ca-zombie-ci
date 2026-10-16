import { erc20Abi } from "viem";

import ClaimHandler from "./ClaimHandler";
import CreditDistributor from "./CreditDistributor";
import CreditFeeClaimVault from "./CreditFeeClaimVault";
import CustomErrors from "./CustomErrors";
import DataStore from "./DataStore";
import ERC20PermitInterface from "./ERC20PermitInterface";
import ERC721 from "./ERC721";
import EventEmitter from "./EventEmitter";
import ExchangeRouter from "./ExchangeRouter";
import HFBank from "./HFBank";
import HFBankFactory from "./HFBankFactory";
import HlvReader from "./HlvReader";
import HlvRouter from "./HlvRouter";
import HlvToken from "./HlvToken";
import Multicall from "./Multicall";
import ReferralStorage from "./ReferralStorage";
import RelayParams from "./RelayParams";
import SmartAccount from "./SmartAccount";
import SyntheticsReader from "./SyntheticsReader";
import SyntheticsRouter from "./SyntheticsRouter";
import Token from "./Token";
import WETH from "./WETH";
import XP from "./XP";

export const abis = {
  ClaimHandler,
  CreditDistributor,
  CreditFeeClaimVault,
  CustomErrors,
  DataStore,
  ERC20: erc20Abi,
  ERC20PermitInterface,
  ERC721: ERC721,
  EventEmitter,
  ExchangeRouter,
  HFBank,
  HFBankFactory,
  HlvReader,
  HlvRouter,
  HlvToken,
  Multicall,
  ReferralStorage,
  RelayParams,
  SmartAccount,
  SyntheticsReader,
  SyntheticsRouter,
  Token,
  WETH,
  XP,
} satisfies Record<string, any>;

export type AbiId = keyof typeof abis;
