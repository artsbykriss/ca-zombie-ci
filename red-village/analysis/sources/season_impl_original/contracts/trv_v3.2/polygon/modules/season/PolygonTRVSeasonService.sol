// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { BaseUpgradeable } from "../../common/BaseUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../../common/Constants.sol";
import "../../interfaces/IPolygonVault.state.sol";
import "../../interfaces/IPolygonTRVRegistry.sol";
import { IPolygonTRVKernel } from "../../interfaces/IPolygonTRVKernel.sol";
import "../../interfaces/IZooKeeper.sol";
// EIP712
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

contract PolygonTRVSeasonService is
  Initializable, //
  UUPSUpgradeable,
  EIP712Upgradeable,
  BaseUpgradeable
{
  using ECDSA for bytes32;

  struct TokenItem {
    address token;
    uint256 tokenId;
  }

  struct Runtime {
    uint256 seasonId;
    bytes data;
  }

  struct Ticket {
    address burner;
    address target;
    TokenItem[] items;
    Runtime runtime;
  }

  event ChampionBurnt(Ticket ticket, uint256 timestamp);

  /* Execute */
  function __SeasonService_init() internal {}

  function _authorizeUpgrade(address) internal override onlyRoler("_authorizeUpgrade") {}

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __Base_init();
    __EIP712_init("TRV", "3.2.0");
    __SeasonService_init();
  }

  function verifier() public view returns (address) {
    return IPolygonTRVRegistry(coreRegistry).getServiceInstance(Constants.SYSTEM_SERVICE_NAME, Constants.SYSTEM_VERIFIER_SERVICE_ID);
  }

  function zooKeeper() public view returns (address) {
    return IPolygonTRVRegistry(coreRegistry).getServiceInstance(Constants.SYSTEM_SERVICE_NAME, Constants.ZOO_KEEPER_SERVICE_ID);
  }

  function _processBurnChampions(Ticket memory _req) internal {
    for (uint256 i = 0; i < _req.items.length; i++) {
      IZooKeeper(zooKeeper()).transferERC721In(_req.items[i].token, _req.burner, _req.items[i].tokenId);
      IZooKeeper(zooKeeper()).transferERC721Out(_req.items[i].token, _req.target, _req.items[i].tokenId);
    }

    emit ChampionBurnt(_req, block.timestamp);
  }

  function burnChampions(Ticket memory _req, bytes[] calldata _signatures) external onlyRoler("burnChampions") {
    verifyTicket(_req, _signatures);

    _processBurnChampions(_req);
  }

  function verifyTicket(Ticket memory _req, bytes[] calldata _signatures) public view {
    require(_req.items.length > 0, "Invalid amount");
    bool isCaller = verifyTicketRequest(_req, _signatures);
    require(isCaller, "Invalid buyer signature");
    require(verifier() == keccak256(_signatures[0]).toEthSignedMessageHash().recover(_signatures[1]), "Invalid system signature");
  }

  function verifyTicketRequest(Ticket memory _req, bytes[] calldata _signatures) public view returns (bool) {
    bytes32 messageHash = hash(_req);
    address user = _hashTypedDataV4(messageHash).recover(_signatures[0]);

    return user == _req.burner;
  }

  function hash(Ticket memory _req) internal pure returns (bytes32) {
    // array
    bytes32 structHash = keccak256("Ticket(address burner,address target,TokenItem[] items,Runtime runtime)Runtime(uint256 seasonId,bytes data)TokenItem(address token,uint256 tokenId)");
    bytes32[] memory encodedItems = new bytes32[](_req.items.length);
    for (uint256 i = 0; i < _req.items.length; i++) {
      encodedItems[i] = hash(_req.items[i]);
    }

    return
      keccak256(
        abi.encode(
          structHash,
          _req.burner, //
          _req.target,
          keccak256(abi.encodePacked(encodedItems)),
          hash(_req.runtime)
        )
      );
  }

  // verified
  function hash(TokenItem memory _req) internal pure returns (bytes32) {
    bytes32 structHash = keccak256("TokenItem(address token,uint256 tokenId)");
    return keccak256(abi.encode(structHash, _req.token, _req.tokenId));
  }

  // verified
  function hash(Runtime memory _req) internal pure returns (bytes32) {
    bytes32 structHash = keccak256("Runtime(uint256 seasonId,bytes data)");
    return
      keccak256(
        abi.encode(
          structHash,
          _req.seasonId, //
          keccak256(abi.encodePacked(_req.data))
        )
      );
  }
}
