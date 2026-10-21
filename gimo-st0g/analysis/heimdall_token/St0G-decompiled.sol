// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.9.2
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid solidity code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

contract DecompiledContract {
    uint256 public constant decimals = 18;
    
    mapping(bytes32 => bytes32) storage_map_a;
    uint256 public totalSupply;
    address public minter;
    mapping(bytes32 => bytes32) storage_map_d;
    bytes32 store_e;
    bytes32 store_f;
    
    event MinterChanged(address, address);
    event Approval(address, address, uint256);
    event Transfer(address, address, uint256);
    error CallerNotAllowed();
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), "ERC20: approve to the zero address");
        require(address(arg0), "ERC20: approve to the zero address");
        var_a = address(arg0);
        storage_map_a[var_a] = arg1;
        emit Approval(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x79cc6790
    /// @custom:signature   burnFrom(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function burnFrom(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        var_a = address(msg.sender);
        require(storage_map_a[var_a] == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "ERC20: burn amount exceeds balance");
        require(address(arg0), "ERC20: burn amount exceeds balance");
        var_a = address(arg0);
        require(!(storage_map_a[var_a] < arg1), "ERC20: burn amount exceeds balance");
        var_a = address(arg0);
        storage_map_a[var_a] = storage_map_a[var_a] - arg1;
        totalSupply = totalSupply - arg1;
        emit Transfer(address(arg0), 0, arg1);
        require(!(storage_map_a[var_a] < arg1), "ERC20: insufficient allowance");
        require(address(arg0), "ERC20: approve to the zero address");
        require(address(msg.sender), "ERC20: approve to the zero address");
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   transfer(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function transfer(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), "ERC20: transfer amount exceeds balance");
        require(address(arg0), "ERC20: transfer amount exceeds balance");
        address var_a = address(msg.sender);
        require(!(storage_map_a[var_a] < arg1), "ERC20: transfer amount exceeds balance");
        var_a = address(msg.sender);
        storage_map_a[var_a] = storage_map_a[var_a] - arg1;
        var_a = address(arg0);
        storage_map_a[var_a] = arg1 + storage_map_a[var_a];
        emit Transfer(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x679aefce
    /// @custom:signature   getRate() public payable returns (uint256)
    function getRate() public payable returns (uint256) {
        (bool success, bytes memory ret0) = address(minter).getRate(); // staticcall
        uint256 var_b = var_b + (uint248(ret0.length + 0x1f));
        require(!((var_b + ret0.length) - var_b) < 0x20);
        return var_b.length;
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x40c10f19
    /// @custom:signature   mint(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function mint(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(minter)), CustomError_2af07d20());
        require(0 - arg1, "ERC20: mint to the zero address");
        require(address(arg0), "ERC20: mint to the zero address");
        require(!(totalSupply > (arg1 + totalSupply)), "ERC20: mint to the zero address");
        totalSupply = arg1 + totalSupply;
        address var_b = address(arg0);
        storage_map_d[var_b] = arg1 + storage_map_d[var_b];
        emit Transfer(0, address(arg0), arg1);
    }
    
    /// @custom:selector    0xa457c2d7
    /// @custom:signature   decreaseAllowance(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function decreaseAllowance(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        var_a = address(arg0);
        require(!(storage_map_a[var_a] < arg1), "ERC20: decreased allowance below zero");
        require(address(msg.sender), "ERC20: approve to the zero address");
        require(address(arg0), "ERC20: approve to the zero address");
        var_a = address(arg0);
        storage_map_a[var_a] = storage_map_a[var_a] - arg1;
        emit Approval(address(msg.sender), address(arg0), storage_map_a[var_a] - arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x42966c68
    /// @custom:signature   burn(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function burn(uint256 arg0) public payable {
        require(address(msg.sender), "ERC20: burn amount exceeds balance");
        address var_a = address(msg.sender);
        require(!(storage_map_a[var_a] < arg0), "ERC20: burn amount exceeds balance");
        var_a = address(msg.sender);
        storage_map_a[var_a] = storage_map_a[var_a] - arg0;
        totalSupply = totalSupply - arg0;
        emit Transfer(address(msg.sender), 0, arg0);
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        if (store_e) {
            if (store_e - ((store_e >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_e >> 0x01)) / 0x20) * 0x20));
                if (store_e) {
                    if (store_e - ((store_e >> 0x01) < 0x20)) {
                        if (!store_e >> 0x01) {
                            if (0x1f < (store_e >> 0x01)) {
                                var_a = 0x03;
                                if ((0x20 + var_c) + (store_e >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x4eb03f6e
    /// @custom:signature   updateMinter(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function updateMinter(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(minter)), CustomError_2af07d20());
        require(address(arg0), CustomError_2b53784e());
        emit MinterChanged(address(minter), address(arg0));
        minter = (address(arg0)) | (uint96(minter));
    }
    
    /// @custom:selector    0x39509351
    /// @custom:signature   increaseAllowance(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function increaseAllowance(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        var_a = address(arg0);
        require(!(storage_map_a[var_a] > (arg1 + storage_map_a[var_a])), "ERC20: approve to the zero address");
        require(address(msg.sender), "ERC20: approve to the zero address");
        require(address(arg0), "ERC20: approve to the zero address");
        var_a = address(arg0);
        storage_map_a[var_a] = arg1 + storage_map_a[var_a];
        emit Approval(address(msg.sender), address(arg0), arg1 + storage_map_a[var_a]);
        return 0x01;
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        if (store_f) {
            if (store_f - ((store_f >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_f >> 0x01)) / 0x20) * 0x20));
                if (store_f) {
                    if (store_f - ((store_f >> 0x01) < 0x20)) {
                        if (!store_f >> 0x01) {
                            if (0x1f < (store_f >> 0x01)) {
                                var_a = 0x04;
                                if ((0x20 + var_c) + (store_f >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}