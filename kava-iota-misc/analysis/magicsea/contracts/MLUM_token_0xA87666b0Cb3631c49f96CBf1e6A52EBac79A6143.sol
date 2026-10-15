// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFTVotesPermit } from "./OFTVotesPermit.sol";

contract MagicLumOFT is OFTVotesPermit {
    constructor(
        address _lzEndpoint,
        address _delegate
    ) OFTVotesPermit("MagicLum", "MLUM", _lzEndpoint, _delegate) {}

}
