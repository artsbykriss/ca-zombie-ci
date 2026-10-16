// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Constants.sol";

// Pellar + LightLink 2023

abstract contract BaseUpgradeable is OwnableUpgradeable {
  // variable
  address public coreRegistry;

  // verified
  modifier onlyRoler(string memory _methodInfo) {
    bool isOwner = _msgSender() == owner();
    bool isRoler = false;
    if (!isOwner) {
      address accessControlProvider = IExternal(coreRegistry).getServiceInstance(
        Constants.SYSTEM_SERVICE_NAME, //
        Constants.ACCESS_CONTROL_SERVICE_ID
      );
      isRoler = IExternal(accessControlProvider).hasRole(_msgSender(), address(this), _methodInfo);
    }
    require(isOwner || isRoler, "Caller does not have permission");
    _;
  }

  function __Base_init() internal {
    __Ownable_init();
    _setCoreRegistry(Constants.CORE_REGISTRY_INSTANCE);
  }

  function _setCoreRegistry(address _contract) internal {
    coreRegistry = _contract;
  }

  // verified
  function setCoreRegistry(address _contract) external onlyRoler("setCoreRegistry") {
    _setCoreRegistry(_contract);
  }

  function getHashedID(string memory _id) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_id));
  }

  /* Internal */
  // reviewed
  // verified
  function splitSignature(bytes memory _sig) internal pure returns (uint8, bytes32, bytes32) {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }

  uint256[50] private __gap;
}

interface IExternal {
  function getServiceInstance(string memory _serviceName, string memory _serviceId) external view returns (address);

  function hasRole(address _account, address _contract, string memory _methodInfo) external view returns (bool);
}
