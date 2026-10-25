// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FeeOnTransferERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public feeRecipient;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _initialOwner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        feeRecipient = msg.sender;
        totalSupply = 1_000_000_000 * 10**_decimals;
        balanceOf[_initialOwner] = totalSupply;
        emit Transfer(address(0), _initialOwner, totalSupply);
    }

    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");
        uint256 fee = amount * 5 / 100;
        uint256 amountAfterFee = amount - fee;
        balanceOf[from] -= amount;
        balanceOf[to] += amountAfterFee;
        balanceOf[feeRecipient] += fee;
        emit Transfer(from, to, amountAfterFee);
        emit Transfer(from, feeRecipient, fee);
    }
}
