// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPolygonTRVKernel {
  event EventFired(string serviceName, string serviceId, bytes32 indexed action, string dataStructure, bytes encodedData, uint256 timestamp);

  function emitEvent(string memory _serviceName, string memory _serviceId, bytes32 _action, string calldata _structure, bytes calldata _encodedData) external;

  function getNonce(string memory _serviceName, string memory _serviceId, address _user) external view returns (uint256);

  function setNonce(string memory _serviceName, string memory _serviceId, address _user, uint256 _newNonce) external;

  function getBytes(string memory _serviceName, string memory _serviceId, bytes calldata _key) external view returns (bytes memory);

  function setBytes(string memory _serviceName, string memory _serviceId, bytes calldata _key, bytes calldata _value) external;

  function delBytes(string memory _serviceName, string memory _serviceId, bytes calldata _key) external;

  // uint256
  function getUint256(string memory _serviceName, string memory _serviceId, bytes calldata _key) external view returns (uint256);

  function setUint256(string memory _serviceName, string memory _serviceId, bytes calldata _key, uint256 _value) external;

  function delUint256(string memory _serviceName, string memory _serviceId, bytes calldata _key) external;

  // address
  function getAddress(string memory _serviceName, string memory _serviceId, bytes calldata _key) external view returns (address);

  function setAddress(string memory _serviceName, string memory _serviceId, bytes calldata _key, address _value) external;

  function delAddress(string memory _serviceName, string memory _serviceId, bytes calldata _key) external;

  // bool
  function getBool(string memory _serviceName, string memory _serviceId, bytes calldata _key) external view returns (bool);

  function setBool(string memory _serviceName, string memory _serviceId, bytes calldata _key, bool _value) external;

  function delBool(string memory _serviceName, string memory _serviceId, bytes calldata _key) external;

  // bytes32
  function getBytes32(string memory _serviceName, string memory _serviceId, bytes calldata _key) external view returns (bytes32);

  function setBytes32(string memory _serviceName, string memory _serviceId, bytes calldata _key, bytes32 _value) external;

  function delBytes32(string memory _serviceName, string memory _serviceId, bytes calldata _key) external;
}
