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
    uint256 public constant unresolved_d55be8c6 = 10000;
    uint256 public constant NAV_PRECISION = 10000000000000;
    uint256 public constant unresolved_54fd4d50 = 2;
    uint256 public constant GUARD = 0;
    uint256 public constant FEE_PRECISION = 1000000;
    uint256 public constant MAX_REQUEST_BATCH = 50;
    bytes public constant contractName = 0xBytes([65, 115, 121, 110, 99, 86, 97, 117, 108, 116]);
    uint256 public constant DEFAULT_BATCH_SIZE = 20;
    uint256 public constant decimals = 6;
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    address public constant share = 0xAddress(0x0000000000000000000000000000000000000000);
    
    mapping(bytes32 => bytes32) storage_map_c;
    address public getProxyImplementation;
    mapping(bytes32 => bytes32) storage_map_ao;
    bytes32 store_r;
    mapping(bytes32 => bytes32) storage_map_al;
    uint256 public nativeFee;
    mapping(bytes32 => bytes32) storage_map_am;
    uint256 public withdrawFeeBps;
    mapping(bytes32 => bytes32) storage_map_af;
    uint256 public totalFeesCollected;
    mapping(bytes32 => bytes32) storage_map_ar;
    address public withdrawQueue;
    bytes32 store_a;
    mapping(bytes32 => bytes32) storage_map_k;
    mapping(bytes32 => bytes32) storage_map_an;
    mapping(bytes32 => bytes32) storage_map_b;
    address public custodian;
    uint256 public depositFeeBps;
    mapping(bytes32 => bytes32) storage_map_x;
    uint256 public nextRedeemRequestId;
    uint256 public latestNav;
    mapping(bytes32 => bytes32) storage_map_e;
    uint256 public minDepositLimit;
    uint256 public maxSupply;
    uint256 public maxDepositLimit;
    uint256 public totalNativeFeeCollected;
    bytes32 store_ac;
    mapping(bytes32 => bytes32) storage_map_z;
    mapping(bytes32 => bytes32) storage_map_ae;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 storage_map_x[storage_map_b[var_a] - 0x01];
    uint256 public maturityPeriod;
    mapping(bytes32 => bytes32) storage_map_ab;
    address public asset;
    address public whitelist;
    address storage_map_al[storage_map_ab[var_d] - 0x01];
    mapping(bytes32 => bytes32) storage_map_as;
    uint256 public maxFluctuationBps;
    mapping(bytes32 => bytes32) storage_map_aq;
    address public swaper;
    mapping(bytes32 => bytes32) storage_map_aa;
    address public getProxyAdmin;
    mapping(bytes32 => bytes32) storage_map_y;
    bytes32 store_t;
    mapping(bytes32 => bytes32) storage_map_ag;
    mapping(bytes32 => bytes32) storage_map_u;
    bytes32 store_ah;
    bytes public accounting;
    
    event Event_46514c48();
    event ToggleReceiverEqSender(bool);
    event Transfer(address, address, uint256);
    event RoleRevoked(bytes32, address, address);
    event Event_62e78cea();
    event Event_5db9ee0a();
    event TransferShares(address, address, uint256, uint64);
    event RoleGranted(bytes32, address, address);
    event Approval(address, address, uint256);
    event ConfigUpdated(uint256, uint256, uint8);
    event Event_bf7b4d2d();
    error InvalidInitialization();
    event CustodianUpdated(address, address);
    
    /// @custom:selector    0x18160ddd
    /// @custom:signature   totalSupply() public view returns (uint256)
    function totalSupply() public view returns (uint256) {
        return store_a;
    }
    
    /// @custom:selector    0xeaed1d07
    /// @custom:signature   claimableRedeemRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claimableRedeemRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        uint256 var_c = var_c + 0xa0;
        require(address(arg1) == (address(storage_map_c[var_a])));
        return 0;
        require(block.timestamp < (uint64(var_c.length)));
        require(block.timestamp < (uint64(var_c.length)));
        return 0;
        return var_j;
        require(!(uint64(var_k) - 0x015180) > 0xffffffffffffffff);
        var_a = uint64(var_k - 0x015180);
        require(!storage_map_b[var_a]);
        return var_j;
        return 0;
    }
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_94280d62());
        require(address(arg0), CustomError_94280d62());
        address var_a = address(msg.sender);
        var_a = address(arg0);
        storage_map_b[var_a] = arg1;
        require(!0x01, CustomError_94280d62());
        return 0x01;
        emit Approval(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x403f3731
    /// @custom:signature   setCustodian(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCustodian(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        custodian = (address(arg0)) | (uint96(custodian));
        emit CustodianUpdated(address(custodian), address(arg0));
    }
    
    /// @custom:selector    0x0a28a477
    /// @custom:signature   previewWithdraw(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdraw(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   revokeRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function revokeRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_b[var_a])), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_b[var_a] = uint248(storage_map_b[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0xe5dd3306
    /// @custom:signature   previewDepositWithFee(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDepositWithFee(uint256 arg0) public view returns (bytes memory) {
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(!((((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))), CustomError_eae7b9f3());
        require(!((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))), CustomError_eae7b9f3());
        return abi.encodePacked(((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav), (0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139));
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0xd905777e
    /// @custom:signature   maxRedeem(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxRedeem(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = 0;
        require(!uint64(storage_map_b[var_a]));
        require(!(uint64(storage_map_b[var_a])) > (uint64(block.timestamp)));
        require(!(uint64(storage_map_b[var_a]) - (uint64(block.timestamp))) > 0xffffffffffffffff);
        require(uint64(storage_map_b[var_a] - (block.timestamp)) < (uint64(swaper / 0x010000000000000000000000000000000000000000)));
        var_a = uint64(storage_map_b[var_a]);
        return storage_map_b[var_a];
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint64(storage_map_b[var_a])) > (uint64(block.timestamp)));
        var_a = uint64(storage_map_b[var_a]);
        return storage_map_b[var_a];
        return 0;
    }
    
    /// @custom:selector    0xb91a1e8f
    /// @custom:signature   setNativeFee(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setNativeFee(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        nativeFee = arg0;
        emit ConfigUpdated(0x07, nativeFee, arg0);
    }
    
    /// @custom:selector    0xa3c491bd
    /// @custom:signature   Unresolved_a3c491bd(uint64 arg0) public view returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_a3c491bd(uint64 arg0) public view returns (uint256) {
        require(arg0 == (uint64(arg0)));
        uint64 var_a = uint64(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_b[var_a]));
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xb6ac642a
    /// @custom:signature   setWithdrawFee(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setWithdrawFee(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(!(arg0 > 0x2710), CustomError_b4fa3fb3());
        withdrawFeeBps = arg0;
        emit ConfigUpdated(0x04, withdrawFeeBps, arg0);
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   grantRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function grantRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_b[var_a] = 0x01 | (uint248(storage_map_b[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x620ee8e400000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x620ee8e400000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x620ee8e400000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!(uint32(arg0)) == 0x01ffc9a700000000000000000000000000000000000000000000000000000000);
    }
    
    /// @custom:selector    0xb460af94
    /// @custom:signature   Unresolved_b460af94(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b460af94(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x613af3b6
    /// @custom:signature   setMinDepositLimit(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMinDepositLimit(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(0 - arg0, CustomError_b4fa3fb3());
        minDepositLimit = arg0;
        emit ConfigUpdated(0x02, minDepositLimit, arg0);
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        if (store_r) {
            if (store_r - ((store_r >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_r >> 0x01)) / 0x20) * 0x20));
                if (store_r) {
                    if (store_r - ((store_r >> 0x01) < 0x20)) {
                        if (!store_r >> 0x01) {
                            if (0x1f < (store_r >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace04;
                                if ((0x20 + var_c) + (store_r >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x402d267d
    /// @custom:signature   maxDeposit(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxDeposit(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(store_a < maxSupply, CustomError_eae7b9f3());
        require(!((maxSupply - store_a) > maxSupply), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_a)) - ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_a)))), CustomError_eae7b9f3());
        require(0x09184e72a000 > ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_a)) - ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_a)))), CustomError_eae7b9f3());
        require(!((((latestNav * (maxSupply - store_a)) - (((maxSupply - store_a) * latestNav) % 0x09184e72a000) / 0x2000) | ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_a)) - ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_a))) - ((((maxSupply - store_a) * latestNav) % 0x09184e72a000) > (latestNav * (maxSupply - store_a))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * (maxSupply - store_a)) - (((maxSupply - store_a) * latestNav) % 0x09184e72a000) / 0x2000) | ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_a)) - ((((maxSupply - store_a) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_a))) - ((((maxSupply - store_a) * latestNav) % 0x09184e72a000) > (latestNav * (maxSupply - store_a))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        require(!((0x0f4240 - depositFeeBps) > 0x0f4240), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        return 0;
    }
    
    /// @custom:selector    0xef8b30f7
    /// @custom:signature   previewDeposit(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDeposit(uint256 arg0) public view returns (uint256) {
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(!((((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))), CustomError_eae7b9f3());
        require(!((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))), CustomError_eae7b9f3());
        return ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav);
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0x0e589d91
    /// @custom:signature   Unresolved_0e589d91(uint64 arg0, uint16 arg1) public pure
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function Unresolved_0e589d91(uint64 arg0, uint16 arg1) public pure {
        require(arg0 == (uint64(arg0)));
        require(arg1 == (uint16(arg1)));
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        if (store_t) {
            if (store_t - ((store_t >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_t >> 0x01)) / 0x20) * 0x20));
                if (store_t) {
                    if (store_t - ((store_t >> 0x01) < 0x20)) {
                        if (!store_t >> 0x01) {
                            if (0x1f < (store_t >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace03;
                                if ((0x20 + var_c) + (store_t >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x07a2d13a
    /// @custom:signature   convertToAssets(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToAssets(uint256 arg0) public view returns (uint256) {
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(!((((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        return (((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd);
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   renounceRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function renounceRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        require(msg.sender == (address(arg1)), CustomError_6697b232());
        var_b = var_b;
        var_b = address(arg1);
        require(!bytes1(storage_map_u[var_b]));
        var_b = arg0;
        var_b = address(arg1);
        storage_map_u[var_b] = uint248(storage_map_u[var_b]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xdfe60835
    /// @custom:signature   setMaxDepositLimit(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxDepositLimit(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        maxDepositLimit = arg0;
        emit ConfigUpdated(0, maxDepositLimit, arg0);
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xd85d5752
    /// @custom:signature   previewWithdrawWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdrawWithFee(uint256 arg0) public view {
        require(!((0x0f4240 - withdrawFeeBps) > 0x0f4240), CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))), CustomError_eae7b9f3());
        require((0x0f4240 - withdrawFeeBps) > (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))), CustomError_eae7b9f3());
        require(0x0f4240 - withdrawFeeBps, CustomError_eae7b9f3());
        require(!((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps) > ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))), CustomError_eae7b9f3());
        require(latestNav > ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav) > ((0x01 == 0x01) + ((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0x6f8b44b0
    /// @custom:signature   setMaxSupply(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxSupply(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        maxSupply = arg0;
        emit ConfigUpdated(0x01, maxSupply, arg0);
    }
    
    /// @custom:selector    0x270eb4a4
    /// @custom:signature   Unresolved_270eb4a4(uint256 arg0, uint256 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_270eb4a4(uint256 arg0, uint256 arg1) public pure {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!arg1 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x88b98b72
    /// @custom:signature   Unresolved_88b98b72(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_88b98b72(uint256 arg0) public {
        require(arg0 == arg0);
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(arg0 - (bytes1(swaper / 0x0100000000000000000000000000000000000000000000000000000000)), CustomError_b4fa3fb3());
        swaper = (uint248(swaper)) | (0x0100000000000000000000000000000000000000000000000000000000 * arg0);
        emit ToggleReceiverEqSender(arg0);
    }
    
    /// @custom:selector    0x94bf804d
    /// @custom:signature   mint(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function mint(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_a, CustomError_3ee5aeb5());
        store_a = 0x02;
        require(!(bytes1(store_a)), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(whitelist / 0x01).whitelistEnabled(); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_9aa02670());
        require(var_c.length == var_c.length, CustomError_9aa02670());
        require(!var_c.length, CustomError_9aa02670());
        require(!var_c.length, CustomError_9aa02670());
        require(!(bytes1(swaper / 0x0100000000000000000000000000000000000000000000000000000000)), CustomError_9aa02670());
        require(!(!msg.sender == (address(arg1))), CustomError_9aa02670());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(!((((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        require(!((0x0f4240 - depositFeeBps) > 0x0f4240), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        var_e = address(msg.sender);
        (bool success, bytes memory ret0) = address(whitelist).Unresolved_3af32abf(var_e); // staticcall
    }
    
    /// @custom:selector    0x17fd40ee
    /// @custom:signature   getLockedShares(address arg0, uint64 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getLockedShares(address arg0, uint64 arg1) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint64(arg1)));
        var_a = 0;
        if (!uint64(storage_map_b[var_a])) {
            require(!uint64(storage_map_b[var_a]));
            var_a = var_a;
            require(uint64(storage_map_b[var_a]) > (uint64(arg1)));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            return storage_map_b[var_a] - 0;
            var_a = uint64(storage_map_b[var_a]);
            require(!(storage_map_b[var_a] - 0) > storage_map_b[var_a]);
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!0 > (storage_map_b[var_a] + 0));
        }
    }
    
    /// @custom:selector    0xb3d7f6b9
    /// @custom:signature   previewMint(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMint(uint256 arg0) public view {
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(!((((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        require(!((0x0f4240 - depositFeeBps) > 0x0f4240), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0xba087652
    /// @custom:signature   Unresolved_ba087652(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ba087652(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x01e1d114
    /// @custom:signature   totalAssets() public view returns (uint256)
    function totalAssets() public view returns (uint256) {
        if (0 - store_a) {
            if (0 - latestNav) {
                if (!0 > 0x03) {
                    if (0x02) {
                        if (!0x01 == 0) {
                            if (0x09184e72a000) {
                                if (0 - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)))) {
                                    if (0x09184e72a000 > (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)))) {
                                        if (!(((latestNav * store_a) - ((store_a * latestNav) % 0x09184e72a000) / 0x2000) | (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)) - (((store_a * latestNav) % 0x09184e72a000) > (latestNav * store_a)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((store_a * latestNav) % 0x09184e72a000) > 0) + (((latestNav * store_a) - ((store_a * latestNav) % 0x09184e72a000) / 0x2000) | (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)) - (((store_a * latestNav) % 0x09184e72a000) > (latestNav * store_a)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) {
                                            return (((store_a * latestNav) % 0x09184e72a000) > 0) + (((latestNav * store_a) - ((store_a * latestNav) % 0x09184e72a000) / 0x2000) | (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)) - (((store_a * latestNav) % 0x09184e72a000) > (latestNav * store_a)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd);
                                            if (0x09184e72a000) {
                                                if (0 - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)))) {
                                                    if (0x09184e72a000 > (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_a) - (((store_a * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_a)))) {
                                                        if (0x09184e72a000) {
                                                            return store_a;
                                                            return 0;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x859ef6e5
    /// @custom:signature   Unresolved_859ef6e5(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_859ef6e5(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!(bytes1(store_a)), CustomError_d93c0665());
        require(!(arg0 > 0x32), CustomError_9c009eca());
        require(!(0 < (arg0)), CustomError_ea8e4eb5());
        require(0 < (arg0), CustomError_ea8e4eb5());
        uint256 var_a = (0 + (arg0 + 0x20));
        require(0 - (storage_map_e[var_a]), CustomError_ea8e4eb5());
        require(msg.sender == (address(storage_map_d[var_a])), CustomError_ea8e4eb5());
        require(!(block.timestamp > 0xffffffffffffffff), CustomError_6dfcc650());
        require(!(uint64(storage_map_b[var_a]) > (uint64(block.timestamp))), CustomError_02d66c04());
        require(!(uint64(storage_map_b[var_a]) - (uint64(block.timestamp)) > 0xffffffffffffffff), CustomError_02d66c04());
        require(!(uint64(storage_map_b[var_a] - (block.timestamp)) < (uint64(swaper / 0x010000000000000000000000000000000000000000))), CustomError_02d66c04());
        var_a = uint64(storage_map_b[var_a]);
        require(!(storage_map_b[var_a] < (storage_map_e[var_a])), CustomError_5372057d());
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_e[var_a]);
        require(0 - (storage_map_b[var_a] - (storage_map_e[var_a])), CustomError_e450d38c());
        require(!(address(storage_map_d[var_a])), CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(0 - storage_map_b[var_a], CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(0 - storage_map_b[var_a], CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(!(storage_map_b[var_a] > (storage_map_e[var_a] + storage_map_b[var_a])), CustomError_e450d38c());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
        require(address(this), CustomError_e450d38c());
        var_a = address(this);
        require(!(storage_map_b[var_a] < (storage_map_e[var_a])), CustomError_e450d38c());
        var_a = address(this);
        storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_e[var_a]);
        if (address(storage_map_d[var_a])) {
            var_a = address(storage_map_d[var_a]);
            storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
            emit Transfer(address(this), address(storage_map_d[var_a]), storage_map_e[var_a]);
            var_a = var_a;
            emit TransferShares(address(this), address(storage_map_d[var_a]), storage_map_e[var_a], uint64(storage_map_b[var_a]));
            var_a = (0 + (arg0 + 0x20));
            if (!storage_map_b[var_a]) {
                if (!(storage_map_b[var_a] - 0x01) > storage_map_b[var_a]) {
                    require(address(storage_map_d[var_a]), CustomError_02d66c04());
                    require(!storage_map_b[var_a], CustomError_02d66c04());
                    require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
                    var_a = 0 + keccak256(var_a);
                    require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
                    var_a = 0 + keccak256(var_a);
                    storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
                    var_a = storage_map_z[var_a];
                    storage_map_b[var_a] = storage_map_b[var_a];
                    require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_02d66c04());
                    var_a = 0;
                    require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
                    require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
                    require(storage_map_b[var_a], CustomError_02d66c04());
                    require(!0, CustomError_02d66c04());
                    var_a = uint64(storage_map_b[var_a]);
                    require(!(0 < (uint64(storage_map_b[var_a]))), CustomError_02d66c04());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
                    var_a = 0;
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    var_a = uint64(storage_map_b[var_a]);
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    require(uint64(storage_map_b[var_a]) < (uint64(storage_map_b[var_a])), CustomError_02d66c04());
                    var_a = address(storage_map_d[var_a]);
                    require(!(storage_map_b[var_a] > (storage_map_e[var_a] + storage_map_b[var_a])), CustomError_02d66c04());
                    var_a = address(storage_map_d[var_a]);
                    require(address(this) == (address(storage_map_d[var_a])), CustomError_02d66c04());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_b[var_a], CustomError_02d66c04());
                }
            }
            require(!((0x01 + (uint64(storage_map_b[var_a]))) > 0xffffffffffffffff), CustomError_02d66c04());
        }
        var_a = 0;
        require(!(uint64(storage_map_b[var_a])), CustomError_02d66c04());
        var_a = 0;
        require(uint64(storage_map_b[var_a]) - (uint64(storage_map_b[var_a])), CustomError_02d66c04());
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = 0;
        var_a = uint64(storage_map_b[var_a]);
        var_a = 0;
        storage_map_b[var_a] = (uint192(storage_map_b[var_a])) | (uint64(storage_map_b[var_a]));
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = uint192(storage_map_b[var_a]);
        var_a = address(this);
        require(!storage_map_b[var_a], CustomError_02d66c04());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
        require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_02d66c04());
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
        var_a = 0 + keccak256(var_a);
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
        var_a = 0 + keccak256(var_a);
        storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
        var_a = storage_map_z[var_a];
        storage_map_b[var_a] = storage_map_b[var_a];
        require(storage_map_b[var_a], CustomError_02d66c04());
        var_a = keccak256(var_a);
        storage_map_z[var_a] = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - 0x01;
        var_a = address(this);
        storage_map_b[var_a] = 0;
        var_a = address(this);
        require(!((uint64(storage_map_b[var_a]) - 0x01) > 0xffffffffffffffff), CustomError_02d66c04());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(uint64(storage_map_b[var_a])) > (uint64(block.timestamp))), CustomError_02d66c04());
    }
    
    /// @custom:selector    0xf5a23d8d
    /// @custom:signature   pendingRedeemRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function pendingRedeemRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        uint256 var_c = var_c + 0xa0;
        require(address(arg1) == (address(storage_map_c[var_a])));
        return 0;
        require(!block.timestamp < (uint64(var_c.length)));
        return var_j;
        return 0;
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   Unresolved_a9059cbb(address arg0, uint256 arg1) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_a9059cbb(address arg0, uint256 arg1) public returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_e450d38c());
        require(address(arg0), CustomError_e450d38c());
        require(address(msg.sender), CustomError_e450d38c());
        address var_a = address(msg.sender);
        require(!(storage_map_b[var_a] < arg1), CustomError_e450d38c());
        uint256 var_f = arg1;
        var_a = address(msg.sender);
        storage_map_b[var_a] = storage_map_b[var_a] - arg1;
        if (address(arg0)) {
            var_a = address(arg0);
            storage_map_b[var_a] = var_f + storage_map_b[var_a];
            emit Transfer(address(msg.sender), address(arg0), arg1);
            if (0 - arg1) {
                if (address(msg.sender)) {
                    require(address(arg0), CustomError_6c6ed794());
                    require(0 - arg1, CustomError_6c6ed794());
                    require(!(!address(msg.sender)), CustomError_6c6ed794());
                    require(!(!address(msg.sender)), CustomError_6c6ed794());
                    var_a = 0;
                    require(!(!address(arg0)), CustomError_6c6ed794());
                    require(!(!address(arg0)), CustomError_6c6ed794());
                    var_a = uint64(storage_map_b[var_a]);
                    var_a = uint64(storage_map_b[var_a]);
                    require(address(msg.sender) - (address(arg0)), CustomError_6c6ed794());
                    var_a = uint64(storage_map_b[var_a]);
                    require(!arg1, CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_b[var_a] = (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1))) + storage_map_b[var_a];
                    var_a = uint64(storage_map_b[var_a]);
                    storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)));
                    require(uint64(storage_map_b[var_a]), CustomError_6c6ed794());
                    require(0 - storage_map_b[var_a], CustomError_6c6ed794());
                    require(!(storage_map_b[var_a] > (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)) + storage_map_b[var_a])), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(0 - (storage_map_b[var_a] - (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)))), CustomError_6c6ed794());
                    var_a = 0;
                    require(0, CustomError_6c6ed794());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
                    require(!0, CustomError_6c6ed794());
                    var_a = uint64(storage_map_b[var_a]);
                    require(!(0 < (uint64(storage_map_b[var_a]))), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_b[var_a] = (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1))) + storage_map_b[var_a];
                    var_a = 0;
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    var_a = uint64(storage_map_b[var_a]);
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    require(uint64(storage_map_b[var_a]) < (uint64(storage_map_b[var_a])), CustomError_6c6ed794());
                    var_a = address(arg0);
                    require(!(storage_map_b[var_a] > (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)) + storage_map_b[var_a])), CustomError_6c6ed794());
                    require(address(this) == (address(arg0)), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_b[var_a], CustomError_6c6ed794());
                }
            }
            require(!((0x01 + (uint64(storage_map_b[var_a]))) > 0xffffffffffffffff), CustomError_6c6ed794());
        }
        require(!0, CustomError_6c6ed794());
        var_a = 0;
        require(!(uint64(storage_map_b[var_a])), CustomError_6c6ed794());
        var_a = 0;
        require(0 - (uint64(storage_map_b[var_a])), CustomError_6c6ed794());
        var_a = 0;
        var_a = 0;
        storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
        require(0 == (uint64(storage_map_b[var_a])), CustomError_6c6ed794());
        var_a = 0;
        var_a = 0;
        storage_map_b[var_a] = 0;
        storage_map_b[var_a] = uint192(storage_map_b[var_a]);
        var_a = address(msg.sender);
        require(!storage_map_b[var_a], CustomError_6c6ed794());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_6c6ed794());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_6c6ed794());
        require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_6c6ed794());
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_6c6ed794());
        var_a = 0 + keccak256(var_a);
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_6c6ed794());
        var_a = 0 + keccak256(var_a);
        storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
        var_a = storage_map_z[var_a];
        storage_map_b[var_a] = storage_map_b[var_a];
        require(storage_map_b[var_a], CustomError_6c6ed794());
        var_a = address(msg.sender);
        require(!((uint64(storage_map_b[var_a]) - 0) > 0xffffffffffffffff), CustomError_6c6ed794());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_b[var_a] = (uint64(storage_map_b[var_a] - 0) * 0x01) | (uint192(storage_map_b[var_a]));
        return 0x01;
        return 0x01;
        return 0x01;
        var_a = 0;
        require(!arg1, CustomError_6c6ed794());
        require(uint64(storage_map_b[var_a]), CustomError_6c6ed794());
        var_a = uint64(storage_map_b[var_a]);
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)));
        require(0 - (storage_map_b[var_a] - (storage_map_b[var_a] ^ ((arg1 < storage_map_b[var_a]) * (storage_map_b[var_a] ^ arg1)))), CustomError_6c6ed794());
        require(0, CustomError_6c6ed794());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
        if (!0) {
            var_a = 0;
            require(!0, CustomError_eae7b9f3());
            var_a = 0;
            require(!(uint64(storage_map_b[var_a])), CustomError_eae7b9f3());
            var_a = 0;
            var_a = 0;
            storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
            require(0 - (uint64(storage_map_b[var_a])), CustomError_eae7b9f3());
            var_a = 0;
            var_a = 0;
            storage_map_b[var_a] = 0;
            storage_map_b[var_a] = uint192(storage_map_b[var_a]);
            var_a = address(msg.sender);
            require(0 == (uint64(storage_map_b[var_a])), CustomError_eae7b9f3());
            require(!storage_map_b[var_a], CustomError_eae7b9f3());
            require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_eae7b9f3());
            require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_eae7b9f3());
            require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_eae7b9f3());
            var_a = 0 + keccak256(var_a);
            require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_eae7b9f3());
            var_a = 0 + keccak256(var_a);
            storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
            var_a = storage_map_z[var_a];
            storage_map_b[var_a] = storage_map_b[var_a];
            require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_eae7b9f3());
            var_a = address(msg.sender);
            require(storage_map_b[var_a], CustomError_eae7b9f3());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            storage_map_b[var_a] = (uint64(storage_map_b[var_a] - 0) * 0x01) | (uint192(storage_map_b[var_a]));
            return 0x01;
            return 0x01;
            require(!((uint64(storage_map_b[var_a]) - 0) > 0xffffffffffffffff), CustomError_eae7b9f3());
        }
        require(0 - (uint64(accounting)), CustomError_eae7b9f3());
        if (!address(arg0)) {
        }
        return 0x01;
    }
    
    /// @custom:selector    0xaedfd4db
    /// @custom:signature   Unresolved_aedfd4db(uint64 arg0) public view returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_aedfd4db(uint64 arg0) public view returns (uint256) {
        require(arg0 == (uint64(arg0)));
        uint64 var_a = uint64(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xc6e6f592
    /// @custom:signature   convertToShares(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToShares(uint256 arg0) public view returns (uint256) {
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(0 - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))), CustomError_eae7b9f3());
        require(latestNav > (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * arg0) / latestNav) > ((((arg0 * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * arg0) / latestNav))), CustomError_eae7b9f3());
        return (((arg0 * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * arg0) / latestNav);
        require(0 - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))), CustomError_eae7b9f3());
        require(latestNav > (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0x944d5b06
    /// @custom:signature   getAllBatches(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getAllBatches(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        require(!(uint64(storage_map_b[var_a])) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint64(storage_map_b[var_a]));
        require(!(uint64(storage_map_b[var_a])) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_e = var_e + (0x20 + (0x20 * (uint64(storage_map_b[var_a]))));
        require(!uint64(storage_map_b[var_a]));
        var_a = 0;
        require(!uint64(storage_map_b[var_a]));
        var_a = uint64(storage_map_b[var_a]);
        var_a = uint64(storage_map_b[var_a]);
        require(0x01);
        return abi.encodePacked(0x40, (var_e + 0x60) - var_e, var_e.length, var_e.length);
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public
    function Unresolved_3f4ba83a() public {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]), CustomError_8dfc202b());
        require(bytes1(store_ac), CustomError_8dfc202b());
        store_ac = uint248(store_ac);
        emit Event_5db9ee0a(address(msg.sender));
    }
    
    /// @custom:selector    0xce2bc2f1
    /// @custom:signature   Unresolved_ce2bc2f1(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ce2bc2f1(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        address var_c = var_c + (0x20 + (0x20 * (storage_map_aa[var_a])));
        require(!storage_map_aa[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_aa[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0x6e553f65
    /// @custom:signature   deposit(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function deposit(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_a, CustomError_3ee5aeb5());
        store_a = 0x02;
        require(!(bytes1(store_a)), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(whitelist / 0x01).whitelistEnabled(); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_9aa02670());
        require(var_c.length == var_c.length, CustomError_9aa02670());
        require(!var_c.length, CustomError_9aa02670());
        require(!var_c.length, CustomError_9aa02670());
        require(!(bytes1(swaper / 0x0100000000000000000000000000000000000000000000000000000000)), CustomError_9aa02670());
        require(!(!msg.sender == (address(arg1))), CustomError_9aa02670());
        require(!(arg0 < minDepositLimit), CustomError_0267cc62());
        require(!(arg0 > maxDepositLimit), CustomError_79012fb2());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))), CustomError_eae7b9f3());
        require(!((((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))), CustomError_eae7b9f3());
        require(!((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))), CustomError_eae7b9f3());
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        var_e = address(msg.sender);
        (bool success, bytes memory ret0) = address(whitelist).Unresolved_3af32abf(var_e); // staticcall
    }
    
    /// @custom:selector    0x490ae210
    /// @custom:signature   setDepositFee(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setDepositFee(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(!(arg0 > 0x2710), CustomError_b4fa3fb3());
        depositFeeBps = arg0;
        emit ConfigUpdated(0x03, depositFeeBps, arg0);
    }
    
    /// @custom:selector    0x83e7a49d
    /// @custom:signature   setMaxFluctuationBps(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxFluctuationBps(uint256 arg0) public {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        maxFluctuationBps = arg0;
        emit ConfigUpdated(0x05, maxFluctuationBps, arg0);
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_k[var_a];
    }
    
    /// @custom:selector    0x069a3ecf
    /// @custom:signature   previewRedeemWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeemWithFee(uint256 arg0) public view {
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(!((((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0xe85ba3e9
    /// @custom:signature   redeemRequests(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function redeemRequests(uint256 arg0) public view returns (bytes memory) {
        uint256 var_b = arg0;
        return abi.encodePacked(uint64(storage_map_u[var_b]), address(storage_map_u[var_b] / 0x010000000000000000), address(storage_map_ae[var_b]), address(storage_map_af[var_b]), storage_map_ag[var_b]);
    }
    
    /// @custom:selector    0xb37f20b8
    /// @custom:signature   previewMintWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMintWithFee(uint256 arg0) public view {
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(!((((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_eae7b9f3());
        require(!((0x0f4240 - depositFeeBps) > 0x0f4240), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))), CustomError_eae7b9f3());
        require(0x09184e72a000, CustomError_eae7b9f3());
    }
    
    /// @custom:selector    0x4cdad506
    /// @custom:signature   previewRedeem(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeem(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0x0bd1a518
    /// @custom:signature   Unresolved_0bd1a518(uint64 arg0) public view returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_0bd1a518(uint64 arg0) public view returns (uint256) {
        require(arg0 == (uint64(arg0)));
        uint64 var_b = arg0;
        return storage_map_u[var_b];
    }
    
    /// @custom:selector    0x0bf9285e
    /// @custom:signature   Unresolved_0bf9285e(uint256 arg0, uint64 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint64", "bytes8", "int64"]
    function Unresolved_0bf9285e(uint256 arg0, uint64 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(uint64(store_ah));
        require(!0x01 == (uint64(store_ah)));
        require(!uint64(store_ah));
        require(!address(this).code.length);
        store_ah = 0x01 | (uint192(store_ah));
        require(bytes1(store_ah / 0x010000000000000000));
        require(!(((0x04 + arg0) + 0x20) - (0x04 + arg0)) < 0x20);
        require(arg0 == (address(arg0)));
        require(address(arg0) == 0);
        require(address(arg0) == 0);
        require(address(arg0) == 0);
        require(address(arg0) == 0);
        require(address(arg0) == 0);
        require(!(((0x04 + arg0) + 0xc0) - ((0x04 + arg0) + 0xa0)) < 0x20);
        require((arg0 + 0xa0) == (uint64(arg0 + 0xa0)));
        require(!uint64(arg0 + 0xa0));
        require(!(((0x04 + arg0) + 0xc0) - ((0x04 + arg0) + 0xa0)) < 0x20);
        require((arg0 + 0xa0) == (uint64(arg0 + 0xa0)));
        require(0x015180, CustomError_b4fa3fb3());
        require(!(!uint64((arg0 + 0xa0) % 0x015180)), CustomError_b4fa3fb3());
        require(!(uint64((arg0 + 0xa0) % 0x015180)), CustomError_b4fa3fb3());
        require(bytes1(store_ah / 0x010000000000000000), CustomError_d7e6bcf8());
        require(bytes1(store_ah / 0x010000000000000000), CustomError_d7e6bcf8());
        require(bytes1(store_ah / 0x010000000000000000), CustomError_d7e6bcf8());
        require(!(uint64(arg0 + 0xa0)), CustomError_b4fa3fb3());
        require(!(!uint64(arg0 + 0xa0)), CustomError_b4fa3fb3());
        require(!(uint64(store_ah)), CustomError_f92ee8a9());
        require(!(uint64(store_ah)), CustomError_f92ee8a9());
        require(!(uint64(store_ah)), CustomError_f92ee8a9());
        store_ah = 0x01 | (uint192(store_ah));
        if (store_ah / 0x010000000000000000) {
        }
        if (!0x01 == (uint64(store_ah))) {
        }
    }
    
    /// @custom:selector    0x4048ee5b
    /// @custom:signature   Unresolved_4048ee5b(uint64 arg0) public
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_4048ee5b(uint64 arg0) public {
        require(arg0 == (uint64(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_b4fa3fb3());
        require(!(uint64(arg0) > maturityPeriod), CustomError_b4fa3fb3());
        swaper = (uint192(swaper)) | (0x010000000000000000000000000000000000000000 * (uint64(arg0)));
        emit ConfigUpdated(0x06, uint64(swaper / 0x010000000000000000000000000000000000000000), uint64(arg0));
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        return !(!bytes1(store_a));
    }
    
    /// @custom:selector    0x44b5794d
    /// @custom:signature   getAvailableShares(address arg0, uint64 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getAvailableShares(address arg0, uint64 arg1) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint64(arg1)));
        var_a = 0;
        require(!uint64(storage_map_b[var_a]));
        require(uint64(storage_map_b[var_a]) > (uint64(arg1)));
        return 0;
        var_a = uint64(storage_map_b[var_a]);
        require(!0 > (storage_map_b[var_a] + 0));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint64(storage_map_b[var_a]));
        return 0;
    }
    
    /// @custom:selector    0xc63d75b6
    /// @custom:signature   maxMint(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxMint(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(store_a < maxSupply, CustomError_eae7b9f3());
        require(!(0x01 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0x01), CustomError_eae7b9f3());
        require(0 - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit))), CustomError_eae7b9f3());
        require(0x0f4240 > (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit))), CustomError_eae7b9f3());
        require(!((((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))), CustomError_eae7b9f3());
        require(!((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > maxDepositLimit), CustomError_eae7b9f3());
        require(0 - latestNav, CustomError_eae7b9f3());
        require(!(0 > 0x03), CustomError_eae7b9f3());
        require(0x02, CustomError_eae7b9f3());
        require(!(0x01 == 0), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(0 - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(!(((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))), CustomError_eae7b9f3());
        require(!((maxSupply - store_a) > maxSupply), CustomError_eae7b9f3());
        return (maxSupply - store_a) ^ (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) < (maxSupply - store_a) * ((maxSupply - store_a) ^ (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))));
        require(latestNav > ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(0 - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        require(latestNav, CustomError_eae7b9f3());
        require(latestNav > ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))), CustomError_eae7b9f3());
        return 0;
    }
    
    /// @custom:selector    0x0efa819c
    /// @custom:signature   Unresolved_0efa819c(uint256 arg0, uint64 arg1) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_0efa819c(uint256 arg0, uint64 arg1) public returns (uint256) {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(arg1 == (uint64(arg1)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]), CustomError_083e2f67());
        require(!(arg0 > 0x32), CustomError_083e2f67());
        require(!(uint64(arg1) - (uint64(swaper / 0x010000000000000000000000000000000000000000)) > 0xffffffffffffffff), CustomError_580c8fa1());
        require(!(block.timestamp < (uint64(arg1 - (swaper / 0x010000000000000000000000000000000000000000)))), CustomError_580c8fa1());
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + ((0x04 + arg0) + 0x20)) + 0x20) - (0 + ((0x04 + arg0) + 0x20))) < 0x20);
        require((0 + (arg0 + 0x20)) == (address(0 + (arg0 + 0x20))));
        require(address(0 + (arg0 + 0x20)) - address(this), CustomError_6dfcc650());
        var_d = uint64(arg1);
        require(0 - storage_map_ab[var_d], CustomError_6dfcc650());
        require(!(uint64(arg1) > (maturityPeriod + (uint64(arg1)))), CustomError_6dfcc650());
        require(!((maturityPeriod + (uint64(arg1))) > 0xffffffffffffffff), CustomError_6dfcc650());
        var_d = 0;
        if (!uint64(storage_map_ab[var_d])) {
            var_d = 0;
            if (uint64(arg1) - (uint64(storage_map_ab[var_d]))) {
                var_d = uint64(arg1);
                storage_map_ab[var_d] = 0;
                var_d = uint64(arg1);
                var_d = 0;
                storage_map_ab[var_d] = (uint192(storage_map_ab[var_d])) | (uint64(storage_map_ab[var_d]));
                var_d = uint64(arg1);
                storage_map_ab[var_d] = uint192(storage_map_ab[var_d]);
                var_d = address(0 + (arg0 + 0x20));
                if (!storage_map_ab[var_d]) {
                    require(!(uint64(storage_map_ab[var_d])), CustomError_b7cc1142());
                    require(uint64(arg1) - (uint64(storage_map_ab[var_d])), CustomError_b7cc1142());
                    require(!storage_map_ab[var_d], CustomError_b7cc1142());
                    require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_b7cc1142());
                    var_d = 0 + keccak256(var_d);
                    require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_b7cc1142());
                    var_d = 0 + keccak256(var_d);
                    storage_map_al[storage_map_ab[var_d] - 0x01] = storage_map_am[var_d];
                    var_d = storage_map_an[var_d];
                    storage_map_ab[var_d] = storage_map_ab[var_d];
                    require((storage_map_ab[var_d] - 0x01) == (storage_map_ab[var_d] - 0x01), CustomError_b7cc1142());
                    var_d = keccak256(var_d);
                    storage_map_an[var_d] = 0;
                    storage_map_ab[var_d] = storage_map_ab[var_d] - 0x01;
                    var_d = address(0 + (arg0 + 0x20));
                    storage_map_ab[var_d] = 0;
                    var_d = address(0 + (arg0 + 0x20));
                    require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_b7cc1142());
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d] - 0x01) * 0x01) | (uint192(storage_map_ab[var_d]));
                    var_d = uint64(maturityPeriod + (arg1));
                    require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_b7cc1142());
                    var_d = uint64(maturityPeriod + (arg1));
                    require(storage_map_ab[var_d], CustomError_b7cc1142());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_ab[var_d] = storage_map_ab[var_d] + storage_map_ab[var_d];
                    emit Event_bf7b4d2d(storage_map_ab[var_d], address(0 + (arg0 + 0x20)), uint64(arg1), uint64(maturityPeriod + (arg1)));
                    var_d = var_d;
                    emit TransferShares(address(0 + (arg0 + 0x20)), 0, storage_map_ab[var_d], uint64(arg1));
                    var_d = var_d;
                    emit TransferShares(0, address(0 + (arg0 + 0x20)), storage_map_ab[var_d], uint64(maturityPeriod + (arg1)));
                    require(!((uint64(storage_map_ab[var_d]) - 0x01) > 0xffffffffffffffff), CustomError_b7cc1142());
                    var_d = 0;
                    require(0 - storage_map_ab[var_d], CustomError_b7cc1142());
                    require(!(storage_map_ab[var_d] > (storage_map_ab[var_d] + storage_map_ab[var_d])), CustomError_b7cc1142());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0001, CustomError_b7cc1142());
                    require(!0, CustomError_b7cc1142());
                    var_d = uint64(maturityPeriod + (arg1));
                    require(!(0 < (uint64(maturityPeriod + (arg1)))), CustomError_b7cc1142());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_ab[var_d] = storage_map_ab[var_d] + storage_map_ab[var_d];
                    var_d = 0;
                    storage_map_ab[var_d] = (uint64(maturityPeriod + (arg1))) | (uint192(storage_map_ab[var_d]));
                    var_d = uint64(maturityPeriod + (arg1));
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d])) | (uint192(storage_map_ab[var_d]));
                    require(uint64(maturityPeriod + (arg1)) < (uint64(storage_map_ab[var_d])), CustomError_b7cc1142());
                    var_d = address(0 + (arg0 + 0x20));
                    require(!(storage_map_ab[var_d] > (storage_map_ab[var_d] + storage_map_ab[var_d])), CustomError_b7cc1142());
                    require(address(this) == (address(0 + (arg0 + 0x20))), CustomError_b7cc1142());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_ab[var_d], CustomError_b7cc1142());
                }
            }
            require(!((0x01 + (uint64(storage_map_ab[var_d]))) > 0xffffffffffffffff), CustomError_b7cc1142());
        }
        emit Event_46514c48(uint64(arg1), 0);
        return 0;
    }
    
    /// @custom:selector    0x4bda1b55
    /// @custom:signature   Unresolved_4bda1b55(uint64 arg0) public view
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_4bda1b55(uint64 arg0) public view {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]));
        require(!uint64(accounting));
        require(!uint64(accounting / 0x010000000000000000));
        require(!0x20 < 0x20);
        require(arg0 == (uint64(arg0)));
        require(!(uint64(arg0) - (uint64(accounting))) > 0xffffffffffffffff);
        require(!0x015180 == (uint64(arg0 - (accounting))));
        require(!0x20 < 0x20);
        if (0x015180 == (uint64(arg0 - (accounting)))) {
        }
    }
    
    /// @custom:selector    0x7d41c86e
    /// @custom:signature   Unresolved_7d41c86e(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7d41c86e(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xb8c461cd
    /// @custom:signature   Unresolved_b8c461cd(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_b8c461cd(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]), CustomError_083e2f67());
        require(!(arg0 > 0x32), CustomError_083e2f67());
        require(!(0 < (arg0)), CustomError_ede74c48());
        require(0 < (arg0), CustomError_ede74c48());
        var_d = (0 + (arg0 + 0x20));
        require(0 - (storage_map_aq[var_d]), CustomError_ede74c48());
        require(!(block.timestamp < (uint64(storage_map_ab[var_d]))), CustomError_ede74c48());
        require(!((uint64(storage_map_ab[var_d]) - 0x015180) > 0xffffffffffffffff), CustomError_5372057d());
        var_d = uint64(storage_map_ab[var_d] - 0x015180);
        require(0 - storage_map_ab[var_d], CustomError_5372057d());
        require(!(0 > 0x03), CustomError_5372057d());
        require(0x02, CustomError_5372057d());
        require(!(0x01 == 0), CustomError_5372057d());
        require(0x09184e72a000, CustomError_5372057d());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d])))), CustomError_5372057d());
        require(0x09184e72a000 > ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d])))), CustomError_5372057d());
        var_d = 0x4e487b71;
        require(!(((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_5372057d());
        require(!(0x01 > 0x03), CustomError_5372057d());
        require(0x02, CustomError_5372057d());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == 0x01), CustomError_5372057d());
        require(0 - (((((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) * withdrawFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) - (((((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) * withdrawFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))))), CustomError_5372057d());
        require(0x0f4240 > (((((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) * withdrawFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) - (((((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) * withdrawFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))))), CustomError_5372057d());
        require(0x0f4240, CustomError_5372057d());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(((withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) / 0x0f4240) > ((0x01 == 0x01) + ((withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) / 0x0f4240))), CustomError_5372057d());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) - ((0x01 == 0x01) + ((withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) / 0x0f4240)) > (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))), CustomError_5372057d());
        var_d = uint64(storage_map_ab[var_d]);
        require(!(storage_map_ab[var_d] < (storage_map_ar[var_d])), CustomError_5372057d());
        var_d = uint64(storage_map_ab[var_d]);
        storage_map_ab[var_d] = storage_map_ab[var_d] - (storage_map_ar[var_d]);
        require(0 - (storage_map_ab[var_d] - (storage_map_ar[var_d])), CustomError_e450d38c());
        require(!0, CustomError_e450d38c());
        var_d = uint64(storage_map_ab[var_d]);
        require(0 - storage_map_ab[var_d], CustomError_e450d38c());
        var_d = uint64(storage_map_ab[var_d]);
        require(0 - storage_map_ab[var_d], CustomError_e450d38c());
        var_d = uint64(storage_map_ab[var_d]);
        require(!(storage_map_ab[var_d] > (storage_map_ar[var_d] + storage_map_ab[var_d])), CustomError_e450d38c());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_ab[var_d] = (storage_map_ar[var_d]) + storage_map_ab[var_d];
        require(address(this), CustomError_e450d38c());
        var_d = address(this);
        require(!(storage_map_ab[var_d] < (storage_map_ar[var_d])), CustomError_e450d38c());
        var_d = address(this);
        storage_map_ab[var_d] = storage_map_ab[var_d] - (storage_map_ar[var_d]);
        require(0);
        var_d = 0;
        storage_map_ab[var_d] = (storage_map_ar[var_d]) + storage_map_ab[var_d];
        emit Transfer(address(this), 0, storage_map_ar[var_d]);
        var_d = var_d;
        emit TransferShares(address(this), 0, storage_map_ar[var_d], uint64(storage_map_ab[var_d]));
        var_h = (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)) - ((0x01 == 0x01) + ((withdrawFeeBps * (((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > 0) + ((storage_map_ab[var_d] * (storage_map_ar[var_d]) - (storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) / 0x2000) | ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ab[var_d] * (storage_map_ar[var_d])) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ab[var_d] * (storage_map_ar[var_d]))) - ((storage_map_ar[var_d] * storage_map_ab[var_d] % 0x09184e72a000) > (storage_map_ab[var_d] * (storage_map_ar[var_d]))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) / 0x0f4240));
        var_i = address(storage_map_ab[var_d] / 0x010000000000000000);
        (bool success, bytes memory ret0) = address(withdrawQueue).Unresolved_340c59c5(var_h, var_i); // call
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        var_d = 0;
        if (!0) {
            if (!0 < (uint64(storage_map_ab[var_d]))) {
                if (!uint64(storage_map_ab[var_d])) {
                    require(!0, CustomError_a2dbc163());
                    var_d = uint64(storage_map_ab[var_d]);
                    require(!(0 < (uint64(storage_map_ab[var_d]))), CustomError_a2dbc163());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_ab[var_d] = (storage_map_ar[var_d]) + storage_map_ab[var_d];
                    var_d = 0;
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d])) | (uint192(storage_map_ab[var_d]));
                    var_d = uint64(storage_map_ab[var_d]);
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d])) | (uint192(storage_map_ab[var_d]));
                    require(uint64(storage_map_ab[var_d]) < (uint64(storage_map_ab[var_d])), CustomError_a2dbc163());
                    var_d = 0;
                    require(!(storage_map_ab[var_d] > (storage_map_ar[var_d] + storage_map_ab[var_d])), CustomError_a2dbc163());
                    require(address(this) == 0, CustomError_a2dbc163());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_ab[var_d], CustomError_a2dbc163());
                }
            }
            require(!((0x01 + (uint64(storage_map_ab[var_d]))) > 0xffffffffffffffff), CustomError_a2dbc163());
        }
        var_d = 0;
        require(!(uint64(storage_map_ab[var_d])), CustomError_a2dbc163());
        var_d = 0;
        require(uint64(storage_map_ab[var_d]) - (uint64(storage_map_ab[var_d])), CustomError_a2dbc163());
        var_d = uint64(storage_map_ab[var_d]);
        storage_map_ab[var_d] = 0;
        var_d = uint64(storage_map_ab[var_d]);
        var_d = 0;
        storage_map_ab[var_d] = (uint192(storage_map_ab[var_d])) | (uint64(storage_map_ab[var_d]));
        var_d = uint64(storage_map_ab[var_d]);
        storage_map_ab[var_d] = uint192(storage_map_ab[var_d]);
        var_d = address(this);
        require(!storage_map_ab[var_d], CustomError_a2dbc163());
        require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_a2dbc163());
        require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_a2dbc163());
        require((storage_map_ab[var_d] - 0x01) == (storage_map_ab[var_d] - 0x01), CustomError_a2dbc163());
        require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_a2dbc163());
        var_d = 0 + keccak256(var_d);
        require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_a2dbc163());
        var_d = 0 + keccak256(var_d);
        storage_map_al[storage_map_ab[var_d] - 0x01] = storage_map_am[var_d];
        var_d = storage_map_an[var_d];
        storage_map_ab[var_d] = storage_map_ab[var_d];
        require(storage_map_ab[var_d], CustomError_a2dbc163());
        var_d = keccak256(var_d);
        storage_map_an[var_d] = 0;
        storage_map_ab[var_d] = storage_map_ab[var_d] - 0x01;
        var_d = address(this);
        storage_map_ab[var_d] = 0;
        var_d = address(this);
        require(!((uint64(storage_map_ab[var_d]) - 0x01) > 0xffffffffffffffff), CustomError_a2dbc163());
        require(0x0f4240, CustomError_a2dbc163());
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x45a8c5d1
    /// @custom:signature   getRedeemRequestCount(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getRedeemRequestCount(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xfdb2863d
    /// @custom:signature   Unresolved_fdb2863d(uint64 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_fdb2863d(uint64 arg0) public view returns (bytes memory) {
        require(arg0 == (uint64(arg0)));
        uint64 var_a = uint64(arg0);
        uint64 var_c = var_c + (0x20 + (0x20 * (storage_map_aa[var_a])));
        require(!storage_map_aa[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_aa[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0xce96cb77
    /// @custom:signature   maxWithdraw(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxWithdraw(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xc3f0d30e
    /// @custom:signature   cancelRedeemRequest(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function cancelRedeemRequest(uint256 arg0) public {
        require(!(bytes1(store_a)), CustomError_d93c0665());
        uint256 var_a = arg0;
        require(0 - (storage_map_e[var_a]), CustomError_ea8e4eb5());
        require(msg.sender == (address(storage_map_d[var_a])), CustomError_ea8e4eb5());
        require(!(block.timestamp > 0xffffffffffffffff), CustomError_6dfcc650());
        require(!(uint64(storage_map_b[var_a]) > (uint64(block.timestamp))), CustomError_02d66c04());
        require(!(uint64(storage_map_b[var_a]) - (uint64(block.timestamp)) > 0xffffffffffffffff), CustomError_02d66c04());
        require(!(uint64(storage_map_b[var_a] - (block.timestamp)) < (uint64(swaper / 0x010000000000000000000000000000000000000000))), CustomError_02d66c04());
        var_a = uint64(storage_map_b[var_a]);
        require(!(storage_map_b[var_a] < (storage_map_e[var_a])), CustomError_5372057d());
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_e[var_a]);
        require(0 - (storage_map_b[var_a] - (storage_map_e[var_a])), CustomError_e450d38c());
        require(!(address(storage_map_d[var_a])), CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(0 - storage_map_b[var_a], CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(0 - storage_map_b[var_a], CustomError_e450d38c());
        var_a = uint64(storage_map_b[var_a]);
        require(!(storage_map_b[var_a] > (storage_map_e[var_a] + storage_map_b[var_a])), CustomError_e450d38c());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
        require(address(this), CustomError_e450d38c());
        var_a = address(this);
        require(!(storage_map_b[var_a] < (storage_map_e[var_a])), CustomError_e450d38c());
        var_a = address(this);
        storage_map_b[var_a] = storage_map_b[var_a] - (storage_map_e[var_a]);
        if (address(storage_map_d[var_a])) {
            var_a = address(storage_map_d[var_a]);
            storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
            emit Transfer(address(this), address(storage_map_d[var_a]), storage_map_e[var_a]);
            var_a = var_a;
            emit TransferShares(address(this), address(storage_map_d[var_a]), storage_map_e[var_a], uint64(storage_map_b[var_a]));
            var_a = arg0;
            if (!storage_map_b[var_a]) {
                if (!(storage_map_b[var_a] - 0x01) > storage_map_b[var_a]) {
                    require(address(storage_map_d[var_a]), CustomError_02d66c04());
                    require(!storage_map_b[var_a], CustomError_02d66c04());
                    require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
                    var_a = 0 + keccak256(var_a);
                    require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
                    var_a = 0 + keccak256(var_a);
                    storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
                    var_a = storage_map_z[var_a];
                    storage_map_b[var_a] = storage_map_b[var_a];
                    require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_02d66c04());
                    var_a = 0;
                    require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
                    require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
                    require(storage_map_b[var_a], CustomError_02d66c04());
                    require(!0, CustomError_02d66c04());
                    var_a = uint64(storage_map_b[var_a]);
                    require(!(0 < (uint64(storage_map_b[var_a]))), CustomError_02d66c04());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_b[var_a] = (storage_map_e[var_a]) + storage_map_b[var_a];
                    var_a = 0;
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    var_a = uint64(storage_map_b[var_a]);
                    storage_map_b[var_a] = (uint64(storage_map_b[var_a])) | (uint192(storage_map_b[var_a]));
                    require(uint64(storage_map_b[var_a]) < (uint64(storage_map_b[var_a])), CustomError_02d66c04());
                    var_a = address(storage_map_d[var_a]);
                    require(!(storage_map_b[var_a] > (storage_map_e[var_a] + storage_map_b[var_a])), CustomError_02d66c04());
                    var_a = address(storage_map_d[var_a]);
                    require(address(this) == (address(storage_map_d[var_a])), CustomError_02d66c04());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_b[var_a], CustomError_02d66c04());
                }
            }
            require(!((0x01 + (uint64(storage_map_b[var_a]))) > 0xffffffffffffffff), CustomError_02d66c04());
        }
        var_a = 0;
        require(!(uint64(storage_map_b[var_a])), CustomError_02d66c04());
        var_a = 0;
        require(uint64(storage_map_b[var_a]) - (uint64(storage_map_b[var_a])), CustomError_02d66c04());
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = 0;
        var_a = uint64(storage_map_b[var_a]);
        var_a = 0;
        storage_map_b[var_a] = (uint192(storage_map_b[var_a])) | (uint64(storage_map_b[var_a]));
        var_a = uint64(storage_map_b[var_a]);
        storage_map_b[var_a] = uint192(storage_map_b[var_a]);
        var_a = address(this);
        require(!storage_map_b[var_a], CustomError_02d66c04());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_02d66c04());
        require((storage_map_b[var_a] - 0x01) == (storage_map_b[var_a] - 0x01), CustomError_02d66c04());
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
        var_a = 0 + keccak256(var_a);
        require((storage_map_b[var_a] - 0x01) < (storage_map_aa[var_a]), CustomError_02d66c04());
        var_a = 0 + keccak256(var_a);
        storage_map_x[storage_map_b[var_a] - 0x01] = storage_map_y[var_a];
        var_a = storage_map_z[var_a];
        storage_map_b[var_a] = storage_map_b[var_a];
        require(storage_map_b[var_a], CustomError_02d66c04());
        var_a = keccak256(var_a);
        storage_map_z[var_a] = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - 0x01;
        var_a = address(this);
        storage_map_b[var_a] = 0;
        var_a = address(this);
        require(!((uint64(storage_map_b[var_a]) - 0x01) > 0xffffffffffffffff), CustomError_02d66c04());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(uint64(storage_map_b[var_a])) > (uint64(block.timestamp))), CustomError_02d66c04());
    }
    
    /// @custom:selector    0xd07843ca
    /// @custom:signature   getBatch(address arg0, uint64 arg1) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getBatch(address arg0, uint64 arg1) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint64(arg1)));
        var_a = uint64(arg1);
        var_a = uint64(arg1);
        return abi.encodePacked(storage_map_b[var_a], uint64(storage_map_b[var_a]));
    }
    
    /// @custom:selector    0xe35605dc
    /// @custom:signature   Unresolved_e35605dc(uint64 arg0, uint256 arg1) public returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_e35605dc(uint64 arg0, uint256 arg1) public returns (uint256) {
        require(arg0 == (uint64(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]), CustomError_083e2f67());
        require(0 - arg1, CustomError_083e2f67());
        require(!(arg1 > 0x32), CustomError_083e2f67());
        require(!(uint64(arg0) - (uint64(swaper / 0x010000000000000000000000000000000000000000)) > 0xffffffffffffffff), CustomError_580c8fa1());
        require(!(block.timestamp < (uint64(arg0 - (swaper / 0x010000000000000000000000000000000000000000)))), CustomError_580c8fa1());
        var_d = uint64(arg0);
        require(!(storage_map_ab[var_d] < 0xffff), CustomError_0());
        require(!(arg1 > 0xffff), CustomError_0());
        require(!(0xffff > 0xffffffffffffffff), CustomError_0());
        require(!0xffff, CustomError_0());
        require(!(0 < 0xffff), CustomError_0());
        require(!(0 < 0xffff), CustomError_0());
        uint256 var_k = 0;
        emit Event_46514c48();
        return ;
        require(address(var_e) - (address(this)), CustomError_0());
        var_d = uint64(arg0);
        require(!storage_map_ab[var_d], CustomError_0());
        require(!(uint64(arg0) > (maturityPeriod + (uint64(arg0)))), CustomError_0());
        require(!((maturityPeriod + (uint64(arg0))) > 0xffffffffffffffff), CustomError_0());
        var_d = 0;
        if (!uint64(storage_map_ab[var_d])) {
            var_d = 0;
            if (uint64(arg0) - (uint64(storage_map_ab[var_d]))) {
                var_d = uint64(arg0);
                storage_map_ab[var_d] = 0;
                var_d = uint64(arg0);
                var_d = 0;
                storage_map_ab[var_d] = (uint192(storage_map_ab[var_d])) | (uint64(storage_map_ab[var_d]));
                var_d = uint64(arg0);
                storage_map_ab[var_d] = uint192(storage_map_ab[var_d]);
                var_d = address(var_e);
                if (!storage_map_ab[var_d]) {
                    require(!(uint64(storage_map_ab[var_d])), CustomError_e2517d3f());
                    require(uint64(arg0) - (uint64(storage_map_ab[var_d])), CustomError_e2517d3f());
                    require(!storage_map_ab[var_d], CustomError_e2517d3f());
                    require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_e2517d3f());
                    var_d = var_k + keccak256(var_d);
                    require(!((storage_map_ab[var_d] - 0x01) > storage_map_ab[var_d]), CustomError_e2517d3f());
                    var_d = var_k + keccak256(var_d);
                    storage_map_al[storage_map_ab[var_d] - 0x01] = storage_map_am[var_d];
                    var_d = storage_map_an[var_d];
                    storage_map_ab[var_d] = storage_map_ab[var_d];
                    require((storage_map_ab[var_d] - 0x01) == (storage_map_ab[var_d] - 0x01), CustomError_e2517d3f());
                    var_d = keccak256(var_d);
                    storage_map_an[var_d] = 0;
                    storage_map_ab[var_d] = storage_map_ab[var_d] - 0x01;
                    var_d = address(var_e);
                    storage_map_ab[var_d] = 0;
                    var_d = address(var_e);
                    require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_e2517d3f());
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d] - 0x01) * 0x01) | (uint192(storage_map_ab[var_d]));
                    var_d = uint64(maturityPeriod + (arg0));
                    require((storage_map_ab[var_d] - 0x01) < (storage_map_ao[var_d]), CustomError_e2517d3f());
                    var_d = uint64(maturityPeriod + (arg0));
                    require(storage_map_ab[var_d], CustomError_e2517d3f());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_ab[var_d] = storage_map_ab[var_d] + storage_map_ab[var_d];
                    emit Event_bf7b4d2d();
                    var_d = var_d;
                    emit TransferShares(address(var_e), 0, );
                    var_d = var_d;
                    emit TransferShares(0, address(var_e), );
                    require(!((uint64(storage_map_ab[var_d]) - 0x01) > 0xffffffffffffffff), CustomError_e2517d3f());
                    var_d = 0;
                    require(0 - storage_map_ab[var_d], CustomError_e2517d3f());
                    require(!(storage_map_ab[var_d] > (storage_map_ab[var_d] + storage_map_ab[var_d])), CustomError_e2517d3f());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0001, CustomError_e2517d3f());
                    require(!0, CustomError_e2517d3f());
                    var_d = uint64(maturityPeriod + (arg0));
                    require(!(0 < (uint64(maturityPeriod + (arg0)))), CustomError_e2517d3f());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_ab[var_d] = storage_map_ab[var_d] + storage_map_ab[var_d];
                    var_d = 0;
                    storage_map_ab[var_d] = (uint64(maturityPeriod + (arg0))) | (uint192(storage_map_ab[var_d]));
                    var_d = uint64(maturityPeriod + (arg0));
                    storage_map_ab[var_d] = (uint64(storage_map_ab[var_d])) | (uint192(storage_map_ab[var_d]));
                    require(uint64(maturityPeriod + (arg0)) < (uint64(storage_map_ab[var_d])), CustomError_e2517d3f());
                    var_d = address(var_e);
                    require(!(storage_map_ab[var_d] > (storage_map_ab[var_d] + storage_map_ab[var_d])), CustomError_e2517d3f());
                    require(address(this) == (address(var_e)), CustomError_e2517d3f());
                    var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(storage_map_ab[var_d], CustomError_e2517d3f());
                }
            }
            require(!((0x01 + (uint64(storage_map_ab[var_d]))) > 0xffffffffffffffff), CustomError_e2517d3f());
        }
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 < (storage_map_ao[var_d]), CustomError_e2517d3f());
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public
    function Unresolved_8456cb59() public {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_ab[var_d]), CustomError_d93c0665());
        require(!(bytes1(store_ac)), CustomError_d93c0665());
        store_ac = 0x01 | (uint248(store_ac));
        emit Event_62e78cea(address(msg.sender));
    }
}