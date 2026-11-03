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
    address storage_map_ac[keccak256(var_a) + storage_map_j[var_a]];
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_w;
    mapping(bytes32 => bytes32) storage_map_ao;
    mapping(bytes32 => bytes32) storage_map_al;
    string public name;
    mapping(bytes32 => bytes32) storage_map_s;
    mapping(bytes32 => bytes32) storage_map_am;
    mapping(bytes32 => bytes32) storage_map_af;
    mapping(bytes32 => bytes32) storage_map_ak;
    mapping(bytes32 => bytes32) storage_map_ac;
    mapping(bytes32 => bytes32) storage_map_j;
    address public coo;
    mapping(bytes32 => bytes32) storage_map_k;
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_b;
    mapping(bytes32 => bytes32) storage_map_an;
    address storage_map_ad[keccak256(var_a) + ((storage_map_j[var_a] + 0x01) - 0x01)];
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_e;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_ae;
    mapping(bytes32 => bytes32) storage_map_o;
    mapping(bytes32 => bytes32) storage_map_ah;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 public income;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_t;
    address public cfo;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_ai;
    address public mineContract;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_m;
    mapping(bytes32 => bytes32) storage_map_ag;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_l;
    string public symbol;
    mapping(bytes32 => bytes32) storage_map_aj;
    mapping(bytes32 => bytes32) storage_map_c;
    
    event WithDraw(address, uint256);
    event Event_b9186c27();
    event Event_3126e6ae();
    event Event_fc24cc5b();
    event Event_41da9773();
    event Event_14f6e46e();
    event Event_8340b063();
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x1d62b24d
    /// @custom:signature   Unresolved_1d62b24d(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1d62b24d(uint256 arg0, uint256 arg1) public {
        require(!0);
        require(!0);
        uint256 var_a = var_a + (0x20 + (0x20 * (arg0)));
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_d = arg1;
        require(!(storage_map_b[var_d]) == 0x02);
        var_d = address(var_f);
        require(storage_map_c[var_d] == arg1);
        var_d = address(var_f);
        require(!storage_map_c[var_d] == 0);
        var_d = address(var_f);
        require(!storage_map_c[var_d] == 0x02);
        require(!(storage_map_b[var_d]) == 0x03);
        require(address(coo / 0x0100) == (address(msg.sender)));
        var_d = storage_map_d[var_d];
        (bool success, bytes memory ret0) = address(var_f).transfer(storage_map_e[var_d]);
        var_d = address(var_f);
        require(!(storage_map_c[var_d] + (storage_map_e[var_d]) < storage_map_c[var_d]), "SafeMath add failed");
        var_d = address(var_f);
        storage_map_c[var_d] = storage_map_c[var_d] + (storage_map_e[var_d]);
        var_d = address(var_f);
        require(storage_map_c[var_d] < storage_map_c[var_d]);
        var_d = keccak256(var_d);
        require(!(address(storage_map_g[keccak256(var_d) + storage_map_c[var_d]] / 0x01)) == (address(var_f)));
        require(storage_map_c[var_d] < storage_map_c[var_d]);
    }
    
    /// @custom:selector    0x7c9315f3
    /// @custom:signature   updateFee(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function updateFee(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        uint256 var_a = 0;
        storage_map_i[var_a] = arg0;
        var_a = 0x01;
        storage_map_i[var_a] = arg1;
        var_a = 0x02;
        storage_map_i[var_a] = arg2;
        var_a = 0x03;
        storage_map_i[var_a] = arg3;
        var_a = 0x04;
        storage_map_i[var_a] = arg4;
        emit Event_fc24cc5b(arg0, arg1, arg2, arg3, arg4);
    }
    
    /// @custom:selector    0x3ccfd60b
    /// @custom:signature   withdraw() public
    function withdraw() public {
        require(!0);
        require(!0);
        address var_a = address(msg.sender);
        require(!storage_map_j[var_a] > 0);
        var_a = address(msg.sender);
        (bool success, bytes memory ret0) = address(msg.sender).transfer(storage_map_j[var_a]);
        var_a = address(msg.sender);
        storage_map_j[var_a] = 0;
    }
    
    /// @custom:selector    0x56935823
    /// @custom:signature   Unresolved_56935823(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_56935823(uint256 arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return storage_map_k[var_b];
    }
    
    /// @custom:selector    0xbe9a6555
    /// @custom:signature   start() public
    function start() public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        coo = (0 * 0x01) | (uint248(coo));
    }
    
    /// @custom:selector    0x1092880b
    /// @custom:signature   Unresolved_1092880b(uint256 arg0, uint256 arg1, uint256 arg2) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_1092880b(uint256 arg0, uint256 arg1, uint256 arg2) public returns (uint256) {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_a = arg2;
        require(storage_map_j[var_a] == 0);
        var_a = arg1;
        storage_map_l[var_a] = var_j;
        storage_map_i[var_a] = var_k;
        storage_map_m[var_a] = var_l;
        storage_map_n[var_a] = var_m;
        storage_map_o[var_a] = var_n;
        storage_map_p[var_a] = var_o;
        var_a = arg2;
        storage_map_j[var_a] = arg1;
        return arg1;
    }
    
    /// @custom:selector    0xc12d6f41
    /// @custom:signature   Unresolved_c12d6f41(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c12d6f41(uint256 arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return abi.encodePacked(storage_map_r[var_b], storage_map_s[var_b], storage_map_t[var_b], storage_map_u[var_b], storage_map_v[var_b], storage_map_w[var_b]);
    }
    
    /// @custom:selector    0xaaa08767
    /// @custom:signature   Unresolved_aaa08767(uint256 arg0, uint256 arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_aaa08767(uint256 arg0, uint256 arg1) public view {
        require(!0);
        require(!0);
        uint256 var_a = var_a + (0x20 + (0x20 * (arg1)));
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_d = arg0;
        require(!(!(storage_map_b[var_d]) == 0x02), "SafeMath mul failed");
        require(!(storage_map_x[var_d] < 0x02), "SafeMath mul failed");
        var_d = storage_map_d[var_d];
        require(!(storage_map_x[var_d] == 0), "SafeMath mul failed");
        require(!(!storage_map_x[var_d]), "SafeMath mul failed");
        require(!(!(storage_map_x[var_d] * (storage_map_f[var_d]) / (storage_map_x[var_d])) == (storage_map_f[var_d])), "SafeMath mul failed");
        var_d = storage_map_d[var_d];
        require(!(storage_map_x[var_d] == 0), "SafeMath mul failed");
        require(!(!storage_map_x[var_d]), "SafeMath mul failed");
        require(!(!(storage_map_x[var_d] * (storage_map_e[var_d]) / (storage_map_x[var_d])) == (storage_map_e[var_d])), "SafeMath mul failed");
        require(!(storage_map_x[var_d] * (storage_map_f[var_d]) > (storage_map_x[var_d] * (storage_map_e[var_d]))), "SafeMath sub failed");
        require(var_a.length > 0);
        require(var_a.length);
        require(var_a.length);
        require(storage_map_x[var_d] * (storage_map_e[var_d]) - (storage_map_x[var_d] * (storage_map_f[var_d])) == ((var_a.length * (storage_map_x[var_d] * (storage_map_e[var_d]) - (storage_map_x[var_d] * (storage_map_f[var_d])) / var_a.length)) + (storage_map_x[var_d] * (storage_map_e[var_d]) - (storage_map_x[var_d] * (storage_map_f[var_d])) % var_a.length)));
    }
    
    /// @custom:selector    0xf56f4a5d
    /// @custom:signature   stopBet(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function stopBet(uint256 arg0) public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_a = arg0;
        require(storage_map_m[var_a] == 0x01);
        storage_map_m[var_a] = 0x02;
    }
    
    /// @custom:selector    0xb2596a67
    /// @custom:signature   levels(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function levels(uint256 arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return abi.encodePacked(storage_map_r[var_b], storage_map_s[var_b]);
    }
    
    /// @custom:selector    0x3b17eadc
    /// @custom:signature   withdrawAllBalance() public
    function withdrawAllBalance() public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        (bool success, bytes memory ret0) = address(msg.sender).transfer(address(this).balance);
        income = 0;
    }
    
    /// @custom:selector    0xb144adfb
    /// @custom:signature   balance_of(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balance_of(address arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return storage_map_k[var_b];
    }
    
    /// @custom:selector    0xc47f0027
    /// @custom:signature   Unresolved_c47f0027(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c47f0027(uint256 arg0) public {
        require(!0);
        require(!0);
        uint256 var_a = var_a + (0x20 + (((0x1f + (arg0)) / 0x20) * 0x20));
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_d = 0;
        if (0x1f < var_a.length) {
            cooa = 0x01 + (var_a.length + var_a.length);
            if (!var_a.length) {
                if (!((0x20 + var_a) + var_a.length) > (0x20 + var_a)) {
                    if (!(keccak256(var_d) + ((0x1f + (((0x0100 * (!cooa)) - 0x01) & (cooa) / 0x02)) / 0x20)) > keccak256(var_d)) {
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x9986a0c6
    /// @custom:signature   setCoo(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCoo(address arg0) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        coo = (address(arg0) * 0x0100) | (uint96(coo));
        emit Event_41da9773(address(arg0), address(arg0));
    }
    
    /// @custom:selector    0x74ad8f6c
    /// @custom:signature   Unresolved_74ad8f6c(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_74ad8f6c(uint256 arg0) public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_a = arg0;
        require(storage_map_m[var_a] == 0x02);
        require(storage_map_o[var_a] < 0x02);
        require(!(storage_map_p[var_a]) < 0x02);
        storage_map_m[var_a] = 0x01;
        storage_map_m[var_a] = 0;
    }
    
    /// @custom:selector    0x1a0fa8c3
    /// @custom:signature   withdrawIncome() public
    function withdrawIncome() public {
        require(!0);
        require(!0);
        require(address(cfo / 0x01) == (address(msg.sender)));
        (bool success, bytes memory ret0) = address(msg.sender).transfer(income);
        income = 0;
    }
    
    /// @custom:selector    0x11610c25
    /// @custom:signature   bet() public payable
    function bet() public payable {
        address var_a = address(msg.sender);
        require(!storage_map_j[var_a] == 0);
        var_a = storage_map_n[var_a];
        require(storage_map_l[var_a] == msg.value);
        require(storage_map_m[var_a] == 0x01);
        var_a = address(msg.sender);
        require(storage_map_j[var_a] == 0x01);
        var_a = address(msg.sender);
        require(!storage_map_j[var_a] > 0);
        require(storage_map_j[var_a] < storage_map_j[var_a]);
        var_a = keccak256(var_a);
        require(!(address(storage_map_ac[keccak256(var_a) + storage_map_j[var_a]] / 0x01)) == (address(msg.sender)));
        var_a = address(msg.sender);
        storage_map_j[var_a] = storage_map_j[var_a];
        uint256 var_c = var_c + 0x40;
        var_e = 0x01;
        storage_map_j[var_a] = storage_map_j[var_a] + 0x01;
        var_a = keccak256(var_a);
        storage_map_ad[keccak256(var_a) + ((storage_map_j[var_a] + 0x01) - 0x01)] = (address(var_f) * 0x01) | (uint96(storage_map_ad[keccak256(var_a) + ((storage_map_j[var_a] + 0x01) - 0x01)]));
        storage_map_ad[keccak256(var_a) + ((storage_map_j[var_a] + 0x01) - 0x01)] = ((var_g) * 0x010000000000000000000000000000000000000000) | (uint248(storage_map_ad[keccak256(var_a) + ((storage_map_j[var_a] + 0x01) - 0x01)]));
        storage_map_o[var_a] = var_e + (storage_map_o[var_a]);
        var_a = address(msg.sender);
        storage_map_j[var_a] = 0x02;
        address var_i = address(msg.sender);
        require(address(mineContract / 0x01).code.length);
        (bool success, bytes memory ret0) = address(mineContract / 0x01).{ value: 0 ether }Unresolved_b4da4c45(var_i); // call
        require(!ret0.length < 0x20);
        require(var_c.length);
        require(storage_map_j[var_a] < storage_map_j[var_a]);
        var_a = keccak256(var_a);
        storage_map_ac[keccak256(var_a) + storage_map_j[var_a]] = (0x01 * 0x010000000000000000000000000000000000000000) | (uint248(storage_map_ac[keccak256(var_a) + storage_map_j[var_a]]));
        storage_map_o[var_a] = var_e + (storage_map_o[var_a]);
        var_a = address(msg.sender);
        storage_map_j[var_a] = 0x02;
        address var_k = address(msg.sender);
        uint256 var_l = msg.value;
        require(address(mineContract / 0x01).code.length);
        (bool success, bytes memory ret0) = address(mineContract / 0x01).{ value: 0 ether }Unresolved_b4da4c45(var_k, var_l, var_i); // call
        require(!ret0.length < 0x20);
        if (!storage_map_j[var_a] > 0) {
        }
    }
    
    /// @custom:selector    0x565db840
    /// @custom:signature   Unresolved_565db840(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_565db840(uint256 arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        uint256 var_d = arg0;
        if (!storage_map_c[var_d]) {
            var_g = this.code[15239:15239];
            if (!0 < storage_map_c[var_d]) {
                if (0 < storage_map_c[var_d]) {
                    var_d = keccak256(var_d);
                    var_a = var_a + 0x40;
                    if (!var_g) {
                        if (!0 < (0x20 * var_a.length)) {
                            return abi.encodePacked((0x20 + var_a) - var_a, var_a.length);
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xcb17c05e
    /// @custom:signature   withDrawToken(address arg0, address arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function withDrawToken(address arg0, address arg1, uint256 arg2) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        address var_b = address(arg1);
        require(address(arg0).code.length);
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_a9059cbb(var_b); // call
        require(!ret0.length < 0x20);
        require(var_d.length);
        emit Event_b9186c27(address(arg0), address(arg1), arg2);
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        require(!(address(arg0)) == 0);
        emit OwnershipTransferred(address(unresolved_8da5cb5b / 0x01), address(arg0));
        unresolved_8da5cb5b = (address(arg0) * 0x01) | (uint96(unresolved_8da5cb5b));
    }
    
    /// @custom:selector    0x960018bf
    /// @custom:signature   Unresolved_960018bf(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_960018bf(uint256 arg0, uint256 arg1) public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        var_d = address(var_f);
        require(storage_map_c[var_d] == 0);
        if (storage_map_af[var_d] < 0x02) {
            storage_map_b[var_d] = 0x01;
            emit Event_14f6e46e(arg1);
            storage_map_b[var_d] = 0;
        }
    }
    
    /// @custom:selector    0x3dc72af7
    /// @custom:signature   setMineContract(address arg0) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setMineContract(address arg0) public returns (bool) {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        mineContract = (address(arg0) * 0x01) | (uint96(mineContract));
        return 0x01;
    }
    
    /// @custom:selector    0x8930718a
    /// @custom:signature   Unresolved_8930718a(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8930718a(address arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return storage_map_k[var_b];
    }
    
    /// @custom:selector    0xd4f778a0
    /// @custom:signature   Unresolved_d4f778a0(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d4f778a0(address arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return storage_map_k[var_b];
    }
    
    /// @custom:selector    0x07da68f5
    /// @custom:signature   stop() public
    function stop() public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        coo = (0x01 * 0x01) | (uint248(coo));
    }
    
    /// @custom:selector    0x868e83c8
    /// @custom:signature   Unresolved_868e83c8(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_868e83c8(uint256 arg0, address arg1) public view returns (uint256) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        var_b = address(arg1);
        return storage_map_k[var_b];
    }
    
    /// @custom:selector    0x2d46ed56
    /// @custom:signature   setCfo(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCfo(address arg0) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        cfo = (address(arg0) * 0x01) | (uint96(cfo));
        emit Event_8340b063(address(cfo / 0x01), address(arg0));
    }
    
    /// @custom:selector    0x4ec9221d
    /// @custom:signature   Unresolved_4ec9221d(uint256 arg0, uint256 arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4ec9221d(uint256 arg0, uint256 arg1) public view returns (bool) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        if (arg1 < storage_map_k[var_b]) {
            var_b = keccak256(var_b);
            return abi.encodePacked(address(storage_map_ag[keccak256(var_b) + arg1] / 0x01), (bytes1(storage_map_ag[keccak256(var_b) + arg1] / 0x010000000000000000000000000000000000000000)));
        }
    }
    
    /// @custom:selector    0x2e842c0a
    /// @custom:signature   getPaidPlayers(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getPaidPlayers(uint256 arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        uint256 var_h = arg0;
        var_h = var_r;
        if (!storage_map_an[var_h]) {
            var_r = this.code[15239:15239];
            if (!0 < storage_map_an[var_h]) {
                if (0 < storage_map_an[var_h]) {
                    var_h = keccak256(var_h);
                    var_a = var_a + 0x40;
                    if (!var_r) {
                        if (!0 < (0x20 * var_a.length)) {
                            return abi.encodePacked((0x20 + var_a) - var_a, var_a.length);
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xb7789e2c
    /// @custom:signature   Unresolved_b7789e2c(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_b7789e2c(uint256 arg0, uint256 arg1) public {
        require(!0);
        require(!0);
        require(address(coo / 0x0100) == (address(msg.sender)));
        uint256 var_a = arg0;
        storage_map_i[var_a] = arg1;
        var_a = arg1;
        storage_map_j[var_a] = arg0;
        if (storage_map_p[var_a] < 0x02) {
            storage_map_m[var_a] = 0x01;
            storage_map_m[var_a] = 0;
        }
    }
    
    /// @custom:selector    0x6747fc13
    /// @custom:signature   withdrawAdmin(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function withdrawAdmin(address arg0, uint256 arg1) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        (bool success, bytes memory ret0) = address(arg0).transfer(arg1);
        emit WithDraw(address(arg0), arg1);
    }
    
    /// @custom:selector    0xedb0bb3a
    /// @custom:signature   updatePrice(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function updatePrice(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public {
        require(!0);
        require(!0);
        require(address(unresolved_8da5cb5b / 0x01) == (address(msg.sender)));
        uint256 var_a = 0;
        storage_map_l[var_a] = arg0;
        var_a = 0x01;
        storage_map_l[var_a] = arg1;
        var_a = 0x02;
        storage_map_l[var_a] = arg2;
        var_a = 0x03;
        storage_map_l[var_a] = arg3;
        var_a = 0x04;
        storage_map_l[var_a] = arg4;
        emit Event_3126e6ae(arg0, arg1, arg2, arg3, arg4);
    }
    
    /// @custom:selector    0x464d82ee
    /// @custom:signature   Unresolved_464d82ee(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_464d82ee(uint256 arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return storage_map_k[var_b];
    }
}