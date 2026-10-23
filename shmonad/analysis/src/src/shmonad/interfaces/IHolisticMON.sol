// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { IERC20Full } from "./IERC20Full.sol";

interface IHolisticMON is IERC20Full {
    function initialize() external;

    function shMonad() external view returns (address);

    function enableActivation() external;

    function isActivationEnabled() external view returns (bool);

    function activate(address account) external;

    function activate(address[] calldata accounts) external;

    function isActivated(address account) external view returns (bool);

    function emitTransfer(address from, address to, uint256 value) external;
}
