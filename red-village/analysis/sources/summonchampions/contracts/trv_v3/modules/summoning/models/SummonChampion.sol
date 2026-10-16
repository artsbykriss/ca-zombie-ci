// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonChampion } from "../types/Types.sol";
import { ISummonChampion } from "../interfaces/ISummonChampion.sol";
import { ERC721Enumerable, ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer } from "../../../royalty/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SummonChampions is Base, ERC721Enumerable, ISummonChampion, DefaultOperatorFilterer {
  // vars
  string public baseURI = "https://redvillage-assets.s3.ap-southeast-2.amazonaws.com/champions/summoned/traits/";
  uint256 public currentId = 28000;
  mapping(uint256 => SummonChampion.TokenInfo) public tokens;

  constructor() ERC721("TheRedVillageChampions", "TRVC") {}

  /* View */
  // verified
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");
    return string(abi.encodePacked(baseURI, tokens[_tokenId].uri_name));
  }

  // verified
  function getCurrentId() public view returns (uint256) {
    return currentId;
  }

  /* Admin */
  // verified
  function mintTo(address _owner, string memory _uriName) public onlyRoler("mintTo") returns (uint256 newChampionId) {
    newChampionId = currentId;
    _mint(_owner, currentId);
    tokens[currentId] = SummonChampion.TokenInfo({ uri_name: _uriName, timestamp: block.timestamp });
    currentId += 1;
  }

  function setTokenUriName(uint256 _tokenId, string memory _uriName) public onlyRoler("setTokenUriName") {
    tokens[_tokenId].uri_name = _uriName;
  }

  function setBaseURI(string memory _uri) public onlyRoler("setBaseURI") {
    baseURI = _uri;
  }

  /* Royalty */
  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}
