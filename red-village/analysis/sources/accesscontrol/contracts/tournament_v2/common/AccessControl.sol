// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Pellar + LightLink 2022

import { Base } from "./Base.sol";

library RoleMemberSet {
  struct Record {
    address[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function add(Record storage _record, address _value) internal {
    if (contains(_record, _value)) return; // exist
    _record.values.push(_value);
    _record.indexes[_value] = _record.values.length;
  }

  function remove(Record storage _record, address _value) internal {
    uint256 valueIndex = _record.indexes[_value];
    if (valueIndex == 0) return; // removed non-exist value
    uint256 toDeleteIndex = valueIndex - 1; // dealing with out of bounds
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      address lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
    }
    _record.values.pop();
    _record.indexes[_value] = 0; // set to 0
  }

  function contains(Record storage _record, address _value) internal view returns (bool) {
    return _record.indexes[_value] != 0;
  }

  function size(Record storage _record) internal view returns (uint256) {
    return _record.values.length;
  }

  function at(Record storage _record, uint256 _index) internal view returns (address) {
    return _record.values[_index];
  }
}

contract AccessControl is Base {
  using RoleMemberSet for RoleMemberSet.Record;

  // variables

  // contract => list addresses
  mapping(address => RoleMemberSet.Record) master;

  // role => list addresses
  mapping(bytes => RoleMemberSet.Record) roleMembers;

  constructor () {
    accessControlProvider = address(this);
  }

  /**
   * @dev Grant roles
   * {grantRoles}.
   *
   * allow an account can access method of a contract (that contract need call function from here to check)
   * _methodInfo ie: setData(uint256,uint256) (no space)
   */
  // verified
  function grantRoles(
    address _account,
    address _contract,
    string[] memory _methodsInfo
  ) external onlyRoler("grantRoles") {
    bytes memory role;
    for (uint256 i = 0; i < _methodsInfo.length; i++) {
      role = abi.encode(_contract, _methodsInfo[i]);
      roleMembers[role].add(_account);
    }
  }

  // verified
  function revokeRoles(
    address _account,
    address _contract,
    string[] memory _methodsInfo
  ) external onlyRoler("revokeRoles") {
    bytes memory role;
    for (uint256 i = 0; i < _methodsInfo.length; i++) {
      role = abi.encode(_contract, _methodsInfo[i]);
      roleMembers[role].remove(_account);
    }
  }

  // verified
  function grantMaster(
    address _account,
    address _contract
  ) external onlyRoler("grantMaster") {
    master[_contract].add(_account);
  }

  // verified
  function revokeMaster(
    address _account,
    address _contract
  ) external onlyRoler("revokeMaster") {
    master[_contract].remove(_account);
  }

  // View
  // verified
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) public view returns (bool) {
    return master[_contract].contains(_account) || roleMembers[abi.encode(_contract, _methodInfo)].contains(_account);
  }

  // verified
  function getMembersByRole(address _contract, string memory _methodInfo) public view returns (address[] memory) {
    uint256 size = roleMembers[abi.encode(_contract, _methodInfo)].size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = roleMembers[abi.encode(_contract, _methodInfo)].at(i);
    }
    return records;
  }

  // verified
  function getMemberOfRoleByIndex(
    address _contract,
    string memory _methodInfo,
    uint256 _index
  ) public view returns (address) {
    return roleMembers[abi.encode(_contract, _methodInfo)].at(_index);
  }

  // verified
  function getMastersByRole(address _contract) public view returns (address[] memory) {
    uint256 size = master[_contract].size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = master[_contract].at(i);
    }
    return records;
  }

  // verified
  function getMasterOfRoleByIndex(
    address _contract,
    uint256 _index
  ) public view returns (address) {
    return master[_contract].at(_index);
  }
}
