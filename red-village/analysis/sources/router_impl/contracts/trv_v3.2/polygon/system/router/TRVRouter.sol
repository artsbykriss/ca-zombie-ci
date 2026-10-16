// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { BaseUpgradeable } from "../../common/BaseUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IPolygonTRVRegistry.sol";

contract PolygonTRVRouter is
  Initializable, //
  UUPSUpgradeable,
  BaseUpgradeable
{
  // variables
  // from base: address public coreRegistry;
  event Forwarded(string _serviceName, string _serviceId, bytes funcEncodeWithSignature);

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __Base_init();
  }

  function _authorizeUpgrade(address) internal override onlyRoler("_authorizeUpgrade") {}

  /* Execute */
  // if need _signatures // [0]: user signature, [1]: system signature
  function forwardRequest(string memory _serviceName, string memory _serviceId, bytes calldata _funcEncodeWithSignature) external {
    address service = IPolygonTRVRegistry(coreRegistry).getServiceInstance(_serviceName, _serviceId);
    require(service != address(0), "Service not implemented");

    (bool success, ) = service.call(_funcEncodeWithSignature);

    require(success, "Forward failed");

    emit Forwarded(_serviceName, _serviceId, _funcEncodeWithSignature);
  }

  function forwardStaticcallRequest(string memory _serviceName, string memory _serviceId, bytes calldata bytesCaller) public view returns (bool, bytes memory) {
    address service = IPolygonTRVRegistry(coreRegistry).getServiceInstance(_serviceName, _serviceId);
    (bool success, bytes memory message) = service.staticcall(bytesCaller);

    return (success, message);
  }

  function forwardMultiStaticcallRequest(string[] memory _serviceNames, string[] memory _serviceIds, bytes[] calldata bytesCallers) public view returns (bool[] memory, bytes[] memory) {
    require(_serviceIds.length == bytesCallers.length, "Invalid length");

    bool[] memory success = new bool[](_serviceIds.length);
    bytes[] memory message = new bytes[](_serviceIds.length);

    for (uint256 i = 0; i < _serviceIds.length; i++) {
      (success[i], message[i]) = forwardStaticcallRequest(_serviceNames[i], _serviceIds[i], bytesCallers[i]);
    }

    return (success, message);
  }
}
