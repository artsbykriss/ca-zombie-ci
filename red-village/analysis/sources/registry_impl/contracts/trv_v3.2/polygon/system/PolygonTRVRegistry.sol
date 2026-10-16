// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { BaseUpgradeable } from "../common/BaseUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPolygonTRVRegistry.sol";
import "../common/Constants.sol";

contract PolygonTRVRegistry is
  Initializable, //
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  BaseUpgradeable,
  IPolygonTRVRegistry
{
  using ECDSA for bytes32;

  // variables
  // from base: address public coreRegistry;
  mapping(bytes32 => mapping(bytes32 => address[])) public services;

  function __LLTRVRegistry_init() internal {
    // TODO_season: fill in the correct address
    // systemVerifier = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    _setCoreRegistry(address(this));
    _setServiceInstance(
      Constants.SYSTEM_SERVICE_NAME, //
      Constants.ACCESS_CONTROL_SERVICE_ID,
      Constants.ACCESS_CONTROL_INSTANCE
    );
    _setServiceInstance(
      Constants.SYSTEM_SERVICE_NAME, //
      Constants.SYSTEM_VERIFIER_SERVICE_ID,
      Constants.SYSTEM_VERIFIER_INSTANCE
    );
  }

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
    __Base_init();
    __LLTRVRegistry_init();
  }

  function _authorizeUpgrade(address) internal override onlyRoler("_authorizeUpgrade") {}

  /* Views */
  // verified
  function getServiceInstance(string memory _serviceName, string memory _serviceId) external view returns (address) {
    uint256 size = services[getHashedID(_serviceName)][getHashedID(_serviceId)].length;
    if (size == 0) {
      return address(0);
    }
    return services[getHashedID(_serviceName)][getHashedID(_serviceId)][size - 1];
  }

  /* Admin */
  // verified
  function _setServiceInstance(string memory _serviceName, string memory _serviceId, address _serviceAddress) internal {
    require(_serviceAddress != address(0), "Service address is required");
    bytes32 serviceName = getHashedID(_serviceName);
    bytes32 serviceId = getHashedID(_serviceId);

    services[serviceName][serviceId].push(_serviceAddress);
    emit ServiceInstanceModified(_serviceName, _serviceId, _serviceAddress);
  }

  function createServiceInstance(string memory _serviceName, string memory _serviceId, address _serviceAddress) external onlyRoler("createServiceInstance") {
    require(services[getHashedID(_serviceName)][getHashedID(_serviceId)].length == 0, "Service already exists");
    _setServiceInstance(_serviceName, _serviceId, _serviceAddress);
  }

  // verified
  function modifyServiceInstance(string memory _serviceName, string memory _serviceId, address _serviceAddress) external onlyRoler("modifyServiceInstance") {
    require(services[getHashedID(_serviceName)][getHashedID(_serviceId)].length > 0, "Service not exists");
    _setServiceInstance(_serviceName, _serviceId, _serviceAddress);
  }

  uint256[50] private __gap;
}
