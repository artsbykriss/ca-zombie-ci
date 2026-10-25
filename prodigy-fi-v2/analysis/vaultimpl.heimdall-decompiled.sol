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
    uint256 public constant version = 8;
    bytes public constant unresolved_715018a6 = ;
    
    address public linkedToken;
    bool public lpWithdrawn;
    uint256 public unresolved_52569d5b;
    bytes32 store_m;
    uint256 public minDepositAmount;
    uint256 public depositDeadline;
    uint256 public withdrawalUnlockTime;
    uint256 public priceFeed;
    address public unresolved_309dfe1b;
    address public vaultCreator;
    bytes32 priceFeede;
    uint256 public unresolved_3457ba6c;
    uint256 public unresolved_4250f28f;
    uint256 public quantity;
    uint256 public unresolved_449fd873;
    bool public unresolved_87110ffc;
    uint256 public unresolved_5539d97b;
    address public weth;
    uint256 public unresolved_ea9315f4;
    uint256 public unresolved_641786ad;
    bytes32 priceFeedc;
    bool public unresolved_7802f7f3;
    uint256 public unresolved_fccc9c42;
    address public feeReceiver;
    uint256 public depositTotal;
    bytes32 store_j;
    uint256 public unresolved_50f20b01;
    uint256 public tradingFeeRate;
    address public aggregator;
    uint256 public expiry;
    mapping(bytes32 => bytes32) storage_map_l;
    uint256 public unresolved_f54642f8;
    
    error CustomError_00000000();
    event Initialize();
    event Initialized(uint64);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x65de4b2a
    /// @custom:signature   Unresolved_65de4b2a(uint64 arg0) public view
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_65de4b2a(uint64 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (uint64(arg0)));
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), "Vault: not creator");
        uint256 var_a = var_a + 0x40;
        require(!(msg.sender == (address(vaultCreator))), "Vault: not creator");
    }
    
    /// @custom:selector    0x75e396ca
    /// @custom:signature   Unresolved_75e396ca(uint256 arg0, uint64 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_75e396ca(uint256 arg0, uint64 arg1) public pure {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require((msg.data.length - 0x24) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        require(arg1 - (uint64(arg1)));
    }
    
    /// @custom:selector    0x173458bc
    /// @custom:signature   Unresolved_173458bc(address arg0, uint256 arg1, uint64 arg2, uint64 arg3, uint256 arg4, uint80 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint64", "bytes8", "int64"]
    /// @param              arg3 ["uint64", "bytes8", "int64"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint80", "bytes10", "int80"]
    function Unresolved_173458bc(address arg0, uint256 arg1, uint64 arg2, uint64 arg3, uint256 arg4, uint80 arg5) public payable {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbc + msg.data.length) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        uint256 var_a = var_a + 0x80;
        require(arg2 - (uint64(arg2)));
        require(arg3 - (uint64(arg3)));
        require(arg4 - arg4);
        require(arg5 - (uint80(arg5)));
        require(store_j == 0x02, CustomError_3ee5aeb5());
        store_j = 0x02;
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a), "Vault: vault has not been initialized");
        var_a = var_a + 0x60;
        require(!(bytes1(unresolved_7802f7f3)), "Vault: vault has not been initialized");
        require((address(this).balance - msg.value) > address(this).balance, "Vault: vault has not been initialized");
    }
    
    /// @custom:selector    0x7ee762c6
    /// @custom:signature   Unresolved_7ee762c6(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7ee762c6(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return storage_map_l[var_a];
    }
    
    /// @custom:selector    0xb392c530
    /// @custom:signature   Unresolved_b392c530(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_b392c530(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_118cdaa7());
        require(msg.sender - (address(store_m)), CustomError_118cdaa7());
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), "Vault: deposit period has ended");
        uint256 var_c = var_c + 0x60;
        require(!(bytes1(unresolved_7802f7f3)), "Vault: deposit period has ended");
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c), "Vault: deposit period has ended");
        var_c = var_c + 0x40;
        require(!(!block.timestamp > depositDeadline), "Vault: deposit period has ended");
    }
    
    /// @custom:selector    0x08031eba
    /// @custom:signature   Unresolved_08031eba() public view
    function Unresolved_08031eba() public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Vault: not creator");
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), "Vault: not creator");
        uint256 var_a = var_a + 0x40;
        require(!(msg.sender == (address(vaultCreator))), "Vault: not creator");
    }
    
    /// @custom:selector    0x8a2767e7
    /// @custom:signature   Unresolved_8a2767e7(uint256 arg0, uint64 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_8a2767e7(uint256 arg0, uint64 arg1) public pure {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require((msg.data.length - 0x24) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        require(arg1 - (uint64(arg1)));
    }
    
    /// @custom:selector    0x27e235e3
    /// @custom:signature   balances(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balances(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return storage_map_l[var_a];
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public pure returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public pure returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        return ;
    }
    
    /// @custom:selector    0x9cff182a
    /// @custom:signature   Unresolved_9cff182a(uint256 arg0, uint64 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_9cff182a(uint256 arg0, uint64 arg1) public pure {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require((msg.data.length - 0x24) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        require(arg1 - (uint64(arg1)));
    }
    
    /// @custom:selector    0x77231421
    /// @custom:signature   Unresolved_77231421(address arg0, address arg1, address arg2, address arg3, address arg4, uint256 arg5, uint256 arg6, uint256 arg7, uint256 arg8, uint256 arg9, uint256 arg10, uint256 arg11, uint256 arg12, uint64 arg13, address arg14, uint256 arg15, address arg16, uint256 arg17, address arg18) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    /// @param              arg13 ["uint64", "bytes8", "int64"]
    /// @param              arg14 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg15 ["uint256", "bytes32", "int256"]
    /// @param              arg16 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg17 ["uint256", "bytes32", "int256"]
    /// @param              arg18 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_77231421(address arg0, address arg1, address arg2, address arg3, address arg4, uint256 arg5, uint256 arg6, uint256 arg7, uint256 arg8, uint256 arg9, uint256 arg10, uint256 arg11, uint256 arg12, uint64 arg13, address arg14, uint256 arg15, address arg16, uint256 arg17, address arg18) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x0260);
        require(((var_a + 0x0260) > 0xffffffffffffffff) | ((var_a + 0x0260) < var_a));
        uint256 var_a = var_a + 0x0260;
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (address(arg4)));
        require(arg10 - arg10);
        require(arg13 - (uint64(arg13)));
        require(arg14 - (address(arg14)));
        require(arg16 - (address(arg16)));
        require(arg18 - (address(arg18)));
        require(!uint64(priceFeedc));
        require(uint64(priceFeedc) == 0x01);
        require(uint64(priceFeedc));
        require(address(this).code.length);
        priceFeedc = (uint192(priceFeedc)) | 0x01;
        require(!bytes1(priceFeedc >> 0x40));
        unresolved_7802f7f3 = 0x01 | (uint248(unresolved_7802f7f3));
        require(!bytes1(priceFeedc >> 0x40));
        require(!bytes1(priceFeedc >> 0x40));
        require(!address(var_a.length));
        priceFeedc = (address(var_a.length)) | (uint96(priceFeedc));
        emit OwnershipTransferred(address(priceFeedc), address(var_a.length));
        vaultCreator = (uint96(vaultCreator)) | msg.sender;
        priceFeedd = (uint96(priceFeedd)) | (address(var_w));
        priceFeede = (uint96(priceFeede)) | (address(var_x));
        aggregator = (uint96(aggregator)) | (address(var_y));
        priceFeed = var_z;
        priceFeedb = var_aa;
        unresolved_f54642f8 = var_ab;
        unresolved_52569d5b = var_ac;
        unresolved_641786ad = var_ad;
        priceFeedf = (uint248(priceFeedf)) | (bytes1(var_ae));
        quantity = var_af;
        depositDeadline = var_ag;
        tradingFeeRate = var_ah;
        feeReceiver = (uint96(feeReceiver)) | (address(var_ai));
        unresolved_fccc9c42 = var_aj;
        lpWithdrawn = (uint88(lpWithdrawn) | (bytes1(address(var_ak)))) | (address(var_ak << 0x08));
        unresolved_309dfe1b = (uint32(unresolved_309dfe1b) | (uint64(var_al))) | (address(var_am << 0x40));
        (bool success, bytes memory ret0) = address(msg.sender).weth(); // staticcall
        weth = (uint96(weth)) | 0;
        uint256 var_ao = address(var_x);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_722ec76f(var_ao); // staticcall
        priceFeeda = 0;
        unresolved_5539d97b = 0x3c;
        require(var_aa > (var_aa + 0x1c20), CustomError_a8ce4432());
        withdrawalUnlockTime = (var_aa) + 0x1c20;
        require(!(0 & (lpWithdrawn) | (bytes1(address(var_ak)))), CustomError_a8ce4432());
        emit Initialize();
        require(!(bytes1(priceFeedc >> 0x40)), CustomError_a8ce4432());
        return ;
        priceFeedc = uint248(priceFeedc);
        var_an = 0x01;
        emit Initialized(0x01);
        return ;
        require(!(var_af * (var_ad) / (var_af) == (var_ad) | (!var_af)), CustomError_a8ce4432());
        require(!(bytes1(priceFeedf)), CustomError_a8ce4432());
        require(0x0de0b6b3a7640000 > (0x0de0b6b3a7640000 + (var_ad)), CustomError_a8ce4432());
        require(0x0de0b6b3a7640000 > (0x0de0b6b3a7640000 + (var_ad)), CustomError_a8ce4432());
        require(!(var_af * (0x0de0b6b3a7640000 + (var_ad)) / (var_af) == (0x0de0b6b3a7640000 + (var_ad)) | (!var_af)), CustomError_a8ce4432());
        require(((var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) == (((var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8)), CustomError_a8ce4432());
        require(!(0xc097ce7bc90715b34b9f1000000000 > (((var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) - (((var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (var_af * (0x0de0b6b3a7640000 + (var_ad)) * unresolved_f54642f8)))), CustomError_a8ce4432());
        require(unresolved_fccc9c42 < 0, CustomError_a8ce4432());
        if (!priceFeedf) {
        }
        require(unresolved_fccc9c42 < 0, CustomError_a8ce4432());
        if (!priceFeedf) {
        }
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (address(var_a.length)));
        weth = (uint96(weth)) | (address(var_a.length));
        uint256 var_ar = address(var_x);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_722ec76f(var_ar); // staticcall
        if (0x20 > ret0.length) {
        }
        priceFeedc = (uint248(priceFeedc)) | 0x010000000000000000;
        unresolved_7802f7f3 = var_an | (uint248(unresolved_7802f7f3));
        require(!(bytes1(priceFeedc >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(priceFeedc >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(priceFeedc)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0x781229fc
    /// @custom:signature   Unresolved_781229fc(address arg0, uint256 arg1, uint256 arg2) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function Unresolved_781229fc(address arg0, uint256 arg1, uint256 arg2) public view {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg3 > 0xffffffffffffffff);
        require(arg3 > 0xffffffffffffffff);
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a), "Vault: deposit period has ended");
        uint256 var_a = var_a + 0x60;
        require(!(bytes1(unresolved_7802f7f3)), "Vault: deposit period has ended");
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), "Vault: deposit period has ended");
        var_a = var_a + 0x40;
        require(!(!block.timestamp > depositDeadline), "Vault: deposit period has ended");
    }
    
    /// @custom:selector    0xeaa46ccf
    /// @custom:signature   Unresolved_eaa46ccf() public payable
    function Unresolved_eaa46ccf() public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(store_j == 0x02, CustomError_3ee5aeb5());
        store_j = 0x02;
        require(((var_b + 0x60) > 0xffffffffffffffff) | ((var_b + 0x60) < var_b), CustomError_118cdaa7());
        uint256 var_b = var_b + 0x60;
        require(!(bytes1(unresolved_7802f7f3)), CustomError_118cdaa7());
        require(msg.sender - (address(store_m)), CustomError_118cdaa7());
    }
    
    /// @custom:selector    0x8da5cb5b
    /// @custom:signature   Unresolved_8da5cb5b() public view returns (address)
    function Unresolved_8da5cb5b() public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return address(store_m);
    }
    
    /// @custom:selector    0x8caad7b5
    /// @custom:signature   Unresolved_8caad7b5() public view
    function Unresolved_8caad7b5() public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Vault: not creator");
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), "Vault: not creator");
        uint256 var_a = var_a + 0x40;
        require(!(msg.sender == (address(vaultCreator))), "Vault: not creator");
    }
}