// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title IPrintrDev
 * @notice Interface for the Dev NFT contract that tracks token creators
 * @dev Each PRINTR token gets one Dev NFT minted to its creator
 */
interface IPrintrDev is IERC721, IERC721Metadata {

    /// @notice Custom errors for the PrintrDev contract
    error OnlyPrintrCanMint();
    error PositionAlreadyCreated();

    /**
     * @notice Mint a new Dev NFT for a token
     * @dev Only callable by the Printr contract
     * @param telecoinId The PRINTR token ID (bytes32)
     * @param creator The creator who will receive the NFT
     * @return id The minted NFT token ID
     */
    function mint(
        bytes32 telecoinId,
        address creator
    ) external returns (uint256 id);

    /**
     * @notice Get the NFT token ID for a specific PRINTR token
     * @param token The PRINTR token address
     * @return id The NFT token ID (which is the token address as uint256)
     */
    function tokenToId(
        address token
    ) external view returns (uint256 id);

    /**
     * @notice Get the PRINTR token address for a specific NFT token ID
     * @param id The NFT token ID
     * @return token The PRINTR token address
     */
    function idToToken(
        uint256 id
    ) external view returns (address token);

}
