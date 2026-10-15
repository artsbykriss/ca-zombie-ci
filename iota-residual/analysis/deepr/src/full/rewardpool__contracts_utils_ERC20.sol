// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {

    constructor() ERC20("MyToken", "MTK") public {
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
