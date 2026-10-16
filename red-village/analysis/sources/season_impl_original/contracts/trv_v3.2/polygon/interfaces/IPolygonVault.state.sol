// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPolygonVaultState {
  function depositItems(
    bytes32 hashed
  )
    external
    view
    returns (
      bool initialized, //
      bool confirmed,
      address from,
      address to,
      address currency,
      uint256 amount,
      uint256 pending_amount,
      bytes memory notes
    );

  function getBalance(address _account, address _currency) external view returns (uint256);

  function increaseBalance(address _account, address _currency, uint256 _amount) external;

  function decreaseBalance(address _account, address _currency, uint256 _amount) external;

  function depositPending(bytes32 _hashed, address _from, address _to, address _currency, uint256 _amount, bytes memory _notes) external;

  function depositConfirmed(bytes32 _hashed) external;

  function withdraw(bytes32 _hashed, address _from, address _to, address _currency, uint256 _amount) external;
}

interface ILLVaultEvent {
  event VaultEvent(bytes32 indexed id, bytes data, uint256 blockTimestamp);

  function emitSingleEventById(bytes32 _id, bytes memory _data) external;

  function emitBatchEventsById(bytes32 _id, bytes[] memory _data) external;

  function emitBatchEventsByIds(bytes32[] memory _ids, bytes[] memory _data) external;
}
