// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPolygonTRVRegistry {
  event ServiceInstanceModified(string _serviceName, string _serviceId, address _serviceAddress);

  /* Views */
  function getServiceInstance(string memory _serviceName, string memory _serviceId) external view returns (address);

  /* Actions */
  function createServiceInstance(string memory _serviceName, string memory _serviceId, address _serviceAddress) external;

  function modifyServiceInstance(string memory _serviceName, string memory _serviceId, address _serviceAddress) external;
}
