// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZapperGFang {
    function swapToGFang(address _from, uint amount, address _to, address recipient) external returns (uint256); 
}
    