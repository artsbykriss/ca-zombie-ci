// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { MMNFTMetadata } from "../../Structs.sol";

interface ITradeWinnerNFT is IERC721AUpgradeable {
    /**
     * @dev Mints new nft to a given address
     * @param _tokenMetadata The metadata to be stored for the token
     * @return The id of the minted nft
     */
    function mint(
        address to,
        MMNFTMetadata calldata _tokenMetadata
    ) external returns (uint256);

    /**
     * @dev Mints multiple nfts to a given address
     * @param _tokensMetadata The list of metadata to be stored for the each token
     * @return The list ids of the minted nfts
     */
    function mintBatch(
        address to,
        MMNFTMetadata[] calldata _tokensMetadata
    ) external returns (uint256[] memory);
}
