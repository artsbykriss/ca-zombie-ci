// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TetherLikeERC20
 * @notice Test token that reproduces the parts of mainnet USDT (TetherToken) the pool has
 *         to survive: 6 decimals, `transfer` / `transferFrom` / `approve` that return
 *         nothing, an `approve` that refuses to go from one non-zero value to another,
 *         an allowance of type(uint256).max that is never spent, and owner-run
 *         address freezing.
 * @dev Not for production. The freezing here is stricter than mainnet USDT, which only
 *      stops a frozen SENDER: this one also refuses to credit a frozen recipient, as
 *      newer Tether deployments do. That makes "the treasury is frozen" and "the
 *      depositor is frozen" testable from both sides.
 */
contract TetherLikeERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isBlackListed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddedBlackList(address indexed user);
    event RemovedBlackList(address indexed user);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Test helper standing in for TetherToken.issue().
    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function addBlackList(address user) external onlyOwner {
        isBlackListed[user] = true;
        emit AddedBlackList(user);
    }

    function removeBlackList(address user) external onlyOwner {
        isBlackListed[user] = false;
        emit RemovedBlackList(user);
    }

    /// @dev No return value, like USDT. A caller that decodes a bool reverts here.
    function transfer(address to, uint256 value) external {
        _transfer(msg.sender, to, value);
    }

    /// @dev No return value, like USDT. An allowance of type(uint256).max is never spent.
    function transferFrom(address from, address to, uint256 value) external {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "allowance");
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;
        _transfer(from, to, value);
    }

    /// @dev No return value, and USDT's rule: to change a non-zero allowance, zero it first.
    function approve(address spender, uint256 value) external {
        require(value == 0 || allowance[msg.sender][spender] == 0, "approve: reset to 0 first");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(!isBlackListed[from], "blacklisted sender");
        require(!isBlackListed[to], "blacklisted recipient");
        require(balanceOf[from] >= value, "balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
