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
    bytes public constant contractName = 0xBytes([83, 121, 110, 99, 86, 97, 117, 108, 116]);
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    
    mapping(bytes32 => bytes32) storage_map_w;
    bytes32 store_ad;
    uint256 public minRedeemLimit;
    bytes32 store_r;
    uint256 public getLastRequestId;
    mapping(bytes32 => bytes32) storage_map_s;
    uint256 public maxFluctuationBps;
    mapping(bytes32 => bytes32) storage_map_ac;
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_b;
    uint256 public lastAccountingTimestamp;
    uint256 public totalFeesCollected;
    address public custodian;
    address public getProxyImplementation;
    uint256 public depositFeeBps;
    uint256 public withdrawFeeBps;
    uint256 public latestNav;
    bool public isReceiverEqSender;
    address public getProxyAdmin;
    uint256 public minDepositLimit;
    uint256 public maturityPeriod;
    uint256 public walletDailyInstantWithdrawQuota;
    mapping(bytes32 => bytes32) storage_map_z;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 public getLastProcessedRequestId;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_a;
    uint256 public maxSupply;
    mapping(bytes32 => bytes32) storage_map_aa;
    mapping(bytes32 => bytes32) storage_map_y;
    uint256 public lastReportId;
    uint256 public maxDepositLimit;
    bytes32 store_o;
    
    event ToggleReceiverEqSender(bool);
    error ERC4626ExceededMaxDeposit(address, uint256, uint256);
    event Transfer(address, address, uint256);
    event RoleRevoked(bytes32, address, address);
    event Event_62e78cea();
    event Event_5db9ee0a();
    event RoleGranted(bytes32, address, address);
    event Approval(address, address, uint256);
    event ConfigUpdated(uint256, uint256, uint8);
    event PayerUpdated(address, address);
    event CustodianUpdated(address, address);
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_94280d62());
        require(address(arg0), CustomError_94280d62());
        address var_a = address(msg.sender);
        var_a = address(arg0);
        storage_map_a[var_a] = arg1;
        require(!0x01, CustomError_94280d62());
        return 0x01;
        emit Approval(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x18160ddd
    /// @custom:signature   totalSupply() public view returns (uint256)
    function totalSupply() public view returns (uint256) {
        return store_b;
    }
    
    /// @custom:selector    0x403f3731
    /// @custom:signature   setCustodian(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCustodian(address arg0) public payable {
        require(arg0 == (address(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        custodian = (uint96(custodian)) | (address(arg0));
        emit CustodianUpdated(address(custodian), address(arg0));
    }
    
    /// @custom:selector    0x0a28a477
    /// @custom:signature   previewWithdraw(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdraw(uint256 arg0) public view returns (uint256) {
        if (!(0x0f4240 - withdrawFeeBps) > 0x0f4240) {
            require(!(0x0f4240 - withdrawFeeBps) > 0x0f4240);
            require(!0x01 > 0x03);
            require(0x02);
            require(!0x01 == 0x01);
            require(0 - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))));
            require((0x0f4240 - withdrawFeeBps) > (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))));
            require(0x0f4240 - withdrawFeeBps);
            require(!((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) > ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps))));
            require(0 - latestNav);
            require(!0x01 > 0x03);
            require(0x02);
            require(!0x01 == 0x01);
            require(latestNav > ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))));
            require(latestNav);
            require(!((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav) > ((0x01 == 0x01) + ((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav)));
            return (0x01 == 0x01) + ((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav);
            require(latestNav);
            require(0 - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))));
        }
        return (0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps));
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0xcbefa5b1
    /// @custom:signature   Unresolved_cbefa5b1(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cbefa5b1(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xe3fb10a9
    /// @custom:signature   getUserDailyWithdrawQuota(address arg0) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getUserDailyWithdrawQuota(address arg0) public view {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        require(!0xef10 > (block.timestamp + 0xef10));
        require(0x015180);
        require(((block.timestamp + 0xef10) / 0x015180) == ((((block.timestamp + 0xef10) / 0x015180) * 0x015180) / 0x015180) | !0x015180);
    }
    
    /// @custom:selector    0xe5dd3306
    /// @custom:signature   previewDepositWithFee(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDepositWithFee(uint256 arg0) public view returns (bytes memory) {
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(!(((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)));
        require(!(arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0);
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(latestNav);
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(!((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav)));
        return abi.encodePacked(((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav), (0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139));
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        return abi.encodePacked(arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)), (0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139));
    }
    
    /// @custom:selector    0xd905777e
    /// @custom:signature   maxRedeem(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxRedeem(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = 0;
        require(!uint64(storage_map_a[var_a]));
        require(uint64(storage_map_a[var_a]) > (uint64(block.timestamp)));
        return 0;
        var_a = uint64(storage_map_a[var_a]);
        require(!0 > (storage_map_a[var_a] + 0));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint64(storage_map_a[var_a]));
        return 0;
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   revokeRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function revokeRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = uint248(storage_map_a[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xb6ac642a
    /// @custom:signature   setWithdrawFee(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setWithdrawFee(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(!(arg0 > 0x2710), CustomError_b4fa3fb3());
        withdrawFeeBps = arg0;
        emit ConfigUpdated(0x05, withdrawFeeBps, arg0);
    }
    
    /// @custom:selector    0x43e6cb8e
    /// @custom:signature   fulfillPendingWithdrawals(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function fulfillPendingWithdrawals(uint256 arg0) public payable {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_b, CustomError_3ee5aeb5());
        store_b = 0x02;
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]));
        require(address(isReceiverEqSender));
        address var_h = address(isReceiverEqSender);
        (bool success, bytes memory ret0) = address(store_b).Unresolved_70a08231(var_h); // staticcall
        var_d = var_d + (uint248(ret0.length + 0x1f));
        require(!((var_d + ret0.length) - var_d) < 0x20);
        require(!var_d.length < arg0);
        address var_j = address(isReceiverEqSender);
        (bool success, bytes memory ret0) = address(store_b).Unresolved_70a08231(var_j); // staticcall
        var_j = address(isReceiverEqSender);
        (bool success, bytes memory ret0) = address(store_b).Unresolved_dd62ed3e(var_j); // staticcall
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   grantRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function grantRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = 0x01 | (uint248(storage_map_a[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
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
    /// @custom:signature   setMinDepositLimit(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMinDepositLimit(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(0 - arg0, CustomError_b4fa3fb3());
        minDepositLimit = arg0;
        emit ConfigUpdated(0x02, minDepositLimit, arg0);
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        if (store_o) {
            if (store_o - ((store_o >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_o >> 0x01)) / 0x20) * 0x20));
                if (store_o) {
                    if (store_o - ((store_o >> 0x01) < 0x20)) {
                        if (!store_o >> 0x01) {
                            if (0x1f < (store_o >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace04;
                                if ((0x20 + var_c) + (store_o >> 0x01) > (0x20 + (0x20 + var_c))) {
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
    
    /// @custom:selector    0xef8b30f7
    /// @custom:signature   previewDeposit(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDeposit(uint256 arg0) public view returns (uint256) {
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(!(((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)));
        require(!(arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0);
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(latestNav);
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(!((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav)));
        return ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav);
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        return arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139));
    }
    
    /// @custom:selector    0x402d267d
    /// @custom:signature   maxDeposit(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxDeposit(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(store_b < maxSupply);
        require(!(maxSupply - store_b) > maxSupply);
        require(0 - latestNav);
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_b)) - ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_b)))));
        require(0x09184e72a000 > ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_b)) - ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_b)))));
        require(!(((latestNav * (maxSupply - store_b)) - (((maxSupply - store_b) * latestNav) % 0x09184e72a000) / 0x2000) | ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_b)) - ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_b))) - ((((maxSupply - store_b) * latestNav) % 0x09184e72a000) > (latestNav * (maxSupply - store_b))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * (maxSupply - store_b)) - (((maxSupply - store_b) * latestNav) % 0x09184e72a000) / 0x2000) | ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * (maxSupply - store_b)) - ((((maxSupply - store_b) * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * (maxSupply - store_b))) - ((((maxSupply - store_b) * latestNav) % 0x09184e72a000) > (latestNav * (maxSupply - store_b))) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
        require(0x09184e72a000);
        require(0x09184e72a000);
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
        return 0;
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        if (store_r) {
            if (store_r - ((store_r >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_r >> 0x01)) / 0x20) * 0x20));
                if (store_r) {
                    if (store_r - ((store_r >> 0x01) < 0x20)) {
                        if (!store_r >> 0x01) {
                            if (0x1f < (store_r >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace03;
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
    
    /// @custom:selector    0x07a2d13a
    /// @custom:signature   convertToAssets(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToAssets(uint256 arg0) public view returns (uint256) {
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        return (((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd);
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000);
        return arg0;
    }
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   renounceRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function renounceRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(msg.sender == (address(arg1)), CustomError_6697b232());
        var_b = var_b;
        var_b = address(arg1);
        require(!bytes1(storage_map_s[var_b]));
        var_b = arg0;
        var_b = address(arg1);
        storage_map_s[var_b] = uint248(storage_map_s[var_b]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xdfe60835
    /// @custom:signature   setMaxDepositLimit(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxDepositLimit(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_e2517d3f());
        maxDepositLimit = arg0;
        emit ConfigUpdated(0, maxDepositLimit, arg0);
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x66e6c241
    /// @custom:signature   setMaturityPeriod(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaturityPeriod(uint256 arg0) public payable {
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_b4fa3fb3());
        require(0x015180, CustomError_b4fa3fb3());
        require(!(arg0 % 0x015180), CustomError_b4fa3fb3());
        maturityPeriod = arg0;
        emit ConfigUpdated(0x08, maturityPeriod, arg0);
    }
    
    /// @custom:selector    0xd85d5752
    /// @custom:signature   previewWithdrawWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdrawWithFee(uint256 arg0) public view {
        if (!(0x0f4240 - withdrawFeeBps) > 0x0f4240) {
            require(!(0x0f4240 - withdrawFeeBps) > 0x0f4240);
            require(!0x01 > 0x03);
            require(0x02);
            require(!0x01 == 0x01);
            require(0 - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))));
            require((0x0f4240 - withdrawFeeBps) > (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x0f4240 * arg0) - (((arg0 * 0x0f4240) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x0f4240 * arg0))));
            require(0x0f4240 - withdrawFeeBps);
            require(!((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) > ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps))));
            require(0 - latestNav);
            require(!0x01 > 0x03);
            require(0x02);
            require(!0x01 == 0x01);
            require(latestNav > ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))));
            require(latestNav);
            require(!((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav) > ((0x01 == 0x01) + ((0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) / latestNav)));
            require(latestNav);
            require(0 - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))) - ((((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * ((0x01 == 0x01) + ((0x0f4240 * arg0) / (0x0f4240 - withdrawFeeBps)))))));
        }
    }
    
    /// @custom:selector    0xb70d8fab
    /// @custom:signature   skipWithdrawalRequest(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function skipWithdrawalRequest(uint256 arg0) public view {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(!arg0, CustomError_b4fa3fb3());
        require(!(arg0 > getLastRequestId), CustomError_b4fa3fb3());
        var_d = var_d;
        require(!(bytes1(storage_map_w[var_d] / 0x0100000000000000000000000000000000000000000000000000)), CustomError_b4fa3fb3());
        require(!((arg0 - 0x01) > arg0), CustomError_b4fa3fb3());
        require(arg0, CustomError_b4fa3fb3());
    }
    
    /// @custom:selector    0x6f8b44b0
    /// @custom:signature   setMaxSupply(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxSupply(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_e2517d3f());
        maxSupply = arg0;
        emit ConfigUpdated(0x01, maxSupply, arg0);
    }
    
    /// @custom:selector    0x88b98b72
    /// @custom:signature   Unresolved_88b98b72(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_88b98b72(uint256 arg0) public payable {
        require(arg0 == arg0);
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(arg0 - (bytes1(isReceiverEqSender / 0x010000000000000000000000000000000000000000)), CustomError_b4fa3fb3());
        isReceiverEqSender = (uint248(isReceiverEqSender)) | (0x010000000000000000000000000000000000000000 * arg0);
        emit ToggleReceiverEqSender(arg0);
    }
    
    /// @custom:selector    0x94bf804d
    /// @custom:signature   mint(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function mint(uint256 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_b, CustomError_3ee5aeb5());
        store_b = 0x02;
        require(!(bytes1(store_b)), CustomError_d93c0665());
        require(!(bytes1(isReceiverEqSender / 0x010000000000000000000000000000000000000000)), CustomError_9aa02670());
        require(!(!msg.sender == (address(arg1))), CustomError_9aa02670());
        require(!(store_b > (arg0 + store_b)), CustomError_db0692da());
        require(!((arg0 + store_b) > maxSupply), CustomError_db0692da());
        require(0 - latestNav);
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
        require(0x09184e72a000);
        require(0x09184e72a000);
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
    }
    
    /// @custom:selector    0x17fd40ee
    /// @custom:signature   getLockedShares(address arg0, uint64 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getLockedShares(address arg0, uint64 arg1) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint64(arg1)));
        var_a = 0;
        if (!uint64(storage_map_a[var_a])) {
            require(!uint64(storage_map_a[var_a]));
            var_a = var_a;
            require(uint64(storage_map_a[var_a]) > (uint64(arg1)));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            return storage_map_a[var_a] - 0;
            var_a = uint64(storage_map_a[var_a]);
            require(!(storage_map_a[var_a] - 0) > storage_map_a[var_a]);
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!0 > (storage_map_a[var_a] + 0));
        }
    }
    
    /// @custom:selector    0xb8c4b85a
    /// @custom:signature   Unresolved_b8c4b85a(uint256 arg0, uint256 arg1) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_b8c4b85a(uint256 arg0, uint256 arg1) public view returns (bytes memory) {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!(arg0 > 0xffffffffffffffff), CustomError_c969e0f2());
        require(!(arg0), CustomError_c969e0f2());
        var_d = var_d + 0xc0;
        require(arg0 + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_c969e0f2());
        require(!(0 < (arg0)), CustomError_c969e0f2());
        require(0 < (arg0), CustomError_c969e0f2());
        require(!(0 + (0x20 + (arg0))), CustomError_c969e0f2());
        require(!((0 + (0x20 + (arg0))) > getLastRequestId), CustomError_c969e0f2());
        var_a = var_a;
        require(!(((0 + (0x20 + (arg0))) - 0x01) > (0 + (0x20 + (arg0)))), CustomError_c969e0f2());
        var_a = (0 + (0x20 + (arg0))) - 0x01;
        var_d = 0xc0 + var_d;
        require(!(storage_map_y[var_a] - (storage_map_y[var_a]) > (storage_map_y[var_a])), CustomError_c969e0f2());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!0 + (0x20 + (arg0))), CustomError_c969e0f2());
        return abi.encodePacked(0x20, var_d.length);
    }
    
    /// @custom:selector    0xb3d7f6b9
    /// @custom:signature   previewMint(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMint(uint256 arg0) public view {
        require(0 - latestNav);
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
        require(0x09184e72a000);
        require(0x09184e72a000);
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
    }
    
    /// @custom:selector    0xba087652
    /// @custom:signature   Unresolved_ba087652(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ba087652(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x7d031b65
    /// @custom:signature   getWithdrawalRequests(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getWithdrawalRequests(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        address var_c = var_c + (0x20 + (0x20 * (storage_map_y[var_a])));
        require(!storage_map_y[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_y[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0x01e1d114
    /// @custom:signature   totalAssets() public view returns (uint256)
    function totalAssets() public view returns (uint256) {
        if (0 - store_b) {
            if (0 - latestNav) {
                if (!0 > 0x03) {
                    if (0x02) {
                        if (!0x01 == 0) {
                            if (0x09184e72a000) {
                                if (0 - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)))) {
                                    if (0x09184e72a000 > (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)))) {
                                        if (!(((latestNav * store_b) - ((store_b * latestNav) % 0x09184e72a000) / 0x2000) | (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)) - (((store_b * latestNav) % 0x09184e72a000) > (latestNav * store_b)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((store_b * latestNav) % 0x09184e72a000) > 0) + (((latestNav * store_b) - ((store_b * latestNav) % 0x09184e72a000) / 0x2000) | (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)) - (((store_b * latestNav) % 0x09184e72a000) > (latestNav * store_b)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd))) {
                                            return (((store_b * latestNav) % 0x09184e72a000) > 0) + (((latestNav * store_b) - ((store_b * latestNav) % 0x09184e72a000) / 0x2000) | (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)) - (((store_b * latestNav) % 0x09184e72a000) > (latestNav * store_b)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd);
                                            if (0x09184e72a000) {
                                                if (0 - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)))) {
                                                    if (0x09184e72a000 > (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * store_b) - (((store_b * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * store_b)))) {
                                                        if (0x09184e72a000) {
                                                            return store_b;
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
    
    /// @custom:selector    0x234740b9
    /// @custom:signature   userDailyWithdrawQuota(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function userDailyWithdrawQuota(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return abi.encodePacked(storage_map_s[var_b], uint64(storage_map_ac[var_b]));
    }
    
    /// @custom:selector    0x483cab58
    /// @custom:signature   fulfillSpecificRequest(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function fulfillSpecificRequest(uint256 arg0) public payable {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_b, CustomError_3ee5aeb5());
        store_b = 0x02;
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_b4fa3fb3());
        require(!arg0, CustomError_b4fa3fb3());
        require(!(arg0 > getLastRequestId), CustomError_b4fa3fb3());
        var_a = var_a;
        require(!(bytes1(storage_map_ab[var_a] / 0x0100000000000000000000000000000000000000000000000000)), CustomError_b4fa3fb3());
        require(!((arg0 - 0x01) > arg0), CustomError_b4fa3fb3());
        require(arg0, CustomError_b4fa3fb3());
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   Unresolved_a9059cbb(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_a9059cbb(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_e450d38c());
        require(address(arg0), CustomError_e450d38c());
        require(address(msg.sender), CustomError_e450d38c());
        address var_a = address(msg.sender);
        require(!(storage_map_a[var_a] < arg1), CustomError_e450d38c());
        uint256 var_f = arg1;
        var_a = address(msg.sender);
        storage_map_a[var_a] = storage_map_a[var_a] - arg1;
        if (address(arg0)) {
            var_a = address(arg0);
            storage_map_a[var_a] = var_f + storage_map_a[var_a];
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
                    var_a = uint64(storage_map_a[var_a]);
                    var_a = uint64(storage_map_a[var_a]);
                    require(address(msg.sender) - (address(arg0)), CustomError_6c6ed794());
                    var_a = uint64(storage_map_a[var_a]);
                    require(!arg1, CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_a[var_a] = (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1))) + storage_map_a[var_a];
                    var_a = uint64(storage_map_a[var_a]);
                    storage_map_a[var_a] = storage_map_a[var_a] - (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)));
                    require(uint64(storage_map_a[var_a]), CustomError_6c6ed794());
                    require(0 - storage_map_a[var_a], CustomError_6c6ed794());
                    require(!(storage_map_a[var_a] > (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)) + storage_map_a[var_a])), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(0 - (storage_map_a[var_a] - (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)))), CustomError_6c6ed794());
                    var_a = 0;
                    require(0, CustomError_6c6ed794());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
                    require(!0, CustomError_6c6ed794());
                    var_a = uint64(storage_map_a[var_a]);
                    require(!(0 < (uint64(storage_map_a[var_a]))), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    storage_map_a[var_a] = (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1))) + storage_map_a[var_a];
                    var_a = 0;
                    storage_map_a[var_a] = (uint64(storage_map_a[var_a])) | (uint192(storage_map_a[var_a]));
                    var_a = uint64(storage_map_a[var_a]);
                    storage_map_a[var_a] = (uint64(storage_map_a[var_a])) | (uint192(storage_map_a[var_a]));
                    var_a = address(arg0);
                    require(uint64(storage_map_a[var_a]) < (uint64(storage_map_a[var_a])), CustomError_6c6ed794());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(!(storage_map_a[var_a] > (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)) + storage_map_a[var_a])), CustomError_6c6ed794());
                }
            }
            require(!((0x01 + (uint64(storage_map_a[var_a]))) > 0xffffffffffffffff), CustomError_6c6ed794());
        }
        require(!0, CustomError_6c6ed794());
        var_a = 0;
        require(!(uint64(storage_map_a[var_a])), CustomError_6c6ed794());
        var_a = 0;
        require(0 - (uint64(storage_map_a[var_a])), CustomError_6c6ed794());
        var_a = 0;
        var_a = 0;
        storage_map_a[var_a] = (uint64(storage_map_a[var_a])) | (uint192(storage_map_a[var_a]));
        require(0 == (uint64(storage_map_a[var_a])), CustomError_6c6ed794());
        var_a = address(msg.sender);
        require(!((uint64(storage_map_a[var_a]) - 0) > 0xffffffffffffffff), CustomError_6c6ed794());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_a[var_a] = (uint64(storage_map_a[var_a] - 0) * 0x01) | (uint192(storage_map_a[var_a]));
        return 0x01;
        return 0x01;
        return 0x01;
        var_a = 0;
        require(!arg1, CustomError_6c6ed794());
        require(uint64(storage_map_a[var_a]), CustomError_6c6ed794());
        var_a = uint64(storage_map_a[var_a]);
        var_a = uint64(storage_map_a[var_a]);
        storage_map_a[var_a] = storage_map_a[var_a] - (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)));
        require(0 - (storage_map_a[var_a] - (storage_map_a[var_a] ^ ((arg1 < storage_map_a[var_a]) * (storage_map_a[var_a] ^ arg1)))), CustomError_6c6ed794());
        require(0, CustomError_6c6ed794());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000001, CustomError_6c6ed794());
        if (!0) {
            var_a = 0;
            if (!uint64(storage_map_a[var_a])) {
                var_a = 0;
                require(!0, CustomError_ec442f05());
                var_a = 0;
                var_a = 0;
                storage_map_a[var_a] = (uint64(storage_map_a[var_a])) | (uint192(storage_map_a[var_a]));
                require(!(uint64(storage_map_a[var_a])), CustomError_ec442f05());
                var_a = address(msg.sender);
                require(0 - (uint64(storage_map_a[var_a])), CustomError_ec442f05());
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                storage_map_a[var_a] = (uint64(storage_map_a[var_a] - 0) * 0x01) | (uint192(storage_map_a[var_a]));
                return 0x01;
                return 0x01;
                require(0 == (uint64(storage_map_a[var_a])), CustomError_ec442f05());
            }
            require(!((uint64(storage_map_a[var_a]) - 0) > 0xffffffffffffffff), CustomError_ec442f05());
        }
        return 0x01;
    }
    
    /// @custom:selector    0x944d5b06
    /// @custom:signature   getAllBatches(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getAllBatches(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        require(!(uint64(storage_map_a[var_a])) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint64(storage_map_a[var_a]));
        require(!(uint64(storage_map_a[var_a])) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_e = var_e + (0x20 + (0x20 * (uint64(storage_map_a[var_a]))));
        require(!uint64(storage_map_a[var_a]));
        var_a = 0;
        require(!uint64(storage_map_a[var_a]));
        var_a = uint64(storage_map_a[var_a]);
        var_a = uint64(storage_map_a[var_a]);
        require(0x01);
        return abi.encodePacked(0x40, (var_e + 0x60) - var_e, var_e.length, var_e.length);
    }
    
    /// @custom:selector    0xc6e6f592
    /// @custom:signature   convertToShares(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToShares(uint256 arg0) public view returns (uint256) {
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(latestNav);
        require(0 - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))));
        require(latestNav > (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))));
        require(latestNav);
        require(!((0x09184e72a000 * arg0) / latestNav) > ((((arg0 * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * arg0) / latestNav)));
        return (((arg0 * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * arg0) / latestNav);
        require(0 - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))));
        require(latestNav > (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * arg0) - (((arg0 * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * arg0))));
        require(latestNav);
        return arg0;
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public payable
    function Unresolved_3f4ba83a() public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_8dfc202b());
        require(bytes1(store_ad), CustomError_8dfc202b());
        store_ad = uint248(store_ad);
        emit Event_5db9ee0a(address(msg.sender));
    }
    
    /// @custom:selector    0x32cb7b29
    /// @custom:signature   setMinRedeemLimit(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMinRedeemLimit(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(0 - arg0, CustomError_b4fa3fb3());
        minRedeemLimit = arg0;
        emit ConfigUpdated(0x03, minRedeemLimit, arg0);
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_j[var_a];
    }
    
    /// @custom:selector    0x6e553f65
    /// @custom:signature   deposit(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function deposit(uint256 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_b, CustomError_3ee5aeb5());
        store_b = 0x02;
        require(!(bytes1(store_b)), CustomError_d93c0665());
        require(!(bytes1(isReceiverEqSender / 0x010000000000000000000000000000000000000000)), CustomError_9aa02670());
        require(!(!msg.sender == (address(arg1))), CustomError_9aa02670());
        require(!(arg0 < minDepositLimit), CustomError_443c8a40());
        require(!(arg0 > maxDepositLimit), CustomError_79012fb2());
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(0x0f4240 > (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0))));
        require(!(((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)));
        require(!(arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > arg0);
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(latestNav);
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(!((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav)));
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(0 - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(latestNav > ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (arg0 - ((0x01 == 0x01) + (((depositFeeBps * arg0) - ((arg0 * depositFeeBps) % 0x0f4240) / 0x40) | (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * arg0) - (((arg0 * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * arg0)) - (((arg0 * depositFeeBps) % 0x0f4240) > (depositFeeBps * arg0)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
    }
    
    /// @custom:selector    0x490ae210
    /// @custom:signature   setDepositFee(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setDepositFee(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(!(arg0 > 0x2710), CustomError_b4fa3fb3());
        depositFeeBps = arg0;
        emit ConfigUpdated(0x04, depositFeeBps, arg0);
    }
    
    /// @custom:selector    0x83e7a49d
    /// @custom:signature   setMaxFluctuationBps(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMaxFluctuationBps(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_e2517d3f());
        maxFluctuationBps = arg0;
        emit ConfigUpdated(0x06, maxFluctuationBps, arg0);
    }
    
    /// @custom:selector    0x069a3ecf
    /// @custom:signature   previewRedeemWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeemWithFee(uint256 arg0) public view {
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000);
    }
    
    /// @custom:selector    0xb37f20b8
    /// @custom:signature   previewMintWithFee(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMintWithFee(uint256 arg0) public view {
        require(0 - latestNav);
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((0x01 == 0x01) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
        require(0x09184e72a000);
        require(0x09184e72a000);
        require(!(0x0f4240 - depositFeeBps) > 0x0f4240);
    }
    
    /// @custom:selector    0x4cdad506
    /// @custom:signature   previewRedeem(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeem(uint256 arg0) public view {
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(!(((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((arg0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * arg0) - ((arg0 * latestNav) % 0x09184e72a000) / 0x2000) | (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0)) - (((arg0 * latestNav) % 0x09184e72a000) > (latestNav * arg0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
        require(0x09184e72a000);
        require(0 - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000 > (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * arg0) - (((arg0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * arg0))));
        require(0x09184e72a000);
    }
    
    /// @custom:selector    0x71aaba2a
    /// @custom:signature   updatePersonalDailyWithdrawQuota(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function updatePersonalDailyWithdrawQuota(uint256 arg0) public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_e2517d3f());
        walletDailyInstantWithdrawQuota = arg0;
        emit ConfigUpdated(0x07, walletDailyInstantWithdrawQuota, arg0);
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        return !(!bytes1(store_b));
    }
    
    /// @custom:selector    0x313ce567
    /// @custom:signature   decimals() public view returns (bool)
    function decimals() public view returns (bool) {
        if (!(0 + (store_b / 0x010000000000000000000000000000000000000000)) > 0xff) {
            return bytes1(0 + (store_b / 0x010000000000000000000000000000000000000000));
        }
    }
    
    /// @custom:selector    0x44b5794d
    /// @custom:signature   getAvailableShares(address arg0, uint64 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getAvailableShares(address arg0, uint64 arg1) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint64(arg1)));
        var_a = 0;
        require(!uint64(storage_map_a[var_a]));
        require(uint64(storage_map_a[var_a]) > (uint64(arg1)));
        return 0;
        var_a = uint64(storage_map_a[var_a]);
        require(!0 > (storage_map_a[var_a] + 0));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint64(storage_map_a[var_a]));
        return 0;
    }
    
    /// @custom:selector    0xc63d75b6
    /// @custom:signature   maxMint(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxMint(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(store_b < maxSupply);
        require(!0x01 > 0x03);
        require(0x02);
        require(!0x01 == 0x01);
        require(0 - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit))));
        require(0x0f4240 > (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit))));
        require(!(((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139) > ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)));
        require(!(maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) > maxDepositLimit);
        require(0 - latestNav);
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(latestNav);
        require(0 - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(!((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) > (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav)));
        require(!(maxSupply - store_b) > maxSupply);
        return (maxSupply - store_b) ^ (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav) < (maxSupply - store_b) * ((maxSupply - store_b) ^ (((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % latestNav) > 0) + ((0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) / latestNav))));
        require(latestNav > ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(0 - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(latestNav);
        require(latestNav > ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))) - ((((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) * 0x09184e72a000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (0x09184e72a000 * (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))))));
        require(!(maxSupply - store_b) > maxSupply);
        return (maxSupply - store_b) ^ ((maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139))) < (maxSupply - store_b) * ((maxSupply - store_b) ^ (maxDepositLimit - ((0x01 == 0x01) + (((depositFeeBps * maxDepositLimit) - ((maxDepositLimit * depositFeeBps) % 0x0f4240) / 0x40) | (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (depositFeeBps * maxDepositLimit) - (((maxDepositLimit * depositFeeBps) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (depositFeeBps * maxDepositLimit)) - (((maxDepositLimit * depositFeeBps) % 0x0f4240) > (depositFeeBps * maxDepositLimit)) * 0x0400000000000000000000000000000000000000000000000000000000000000) * 0xde8f6cefed634549b62c77574f722e1ac57e23f24d8fd5cb790fb65668c26139)))));
        return 0;
    }
    
    /// @custom:selector    0x38d52e0f
    /// @custom:signature   asset() public view returns (address)
    function asset() public view returns (address) {
        return address(store_b);
    }
    
    /// @custom:selector    0x4bda1b55
    /// @custom:signature   Unresolved_4bda1b55(uint64 arg0) public pure
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_4bda1b55(uint64 arg0) public pure {
        require(!((var_a + 0xa0) < var_a) | ((var_a + 0xa0) > 0xffffffffffffffff));
        require(arg0 == (uint64(arg0)));
    }
    
    /// @custom:selector    0xd55e6975
    /// @custom:signature   setPayer(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setPayer(address arg0) public payable {
        require(arg0 == (address(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        isReceiverEqSender = (uint96(isReceiverEqSender)) | (address(arg0));
        emit PayerUpdated(address(isReceiverEqSender), address(arg0));
    }
    
    /// @custom:selector    0xce96cb77
    /// @custom:signature   maxWithdraw(address arg0) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxWithdraw(address arg0) public view {
        require(arg0 == (address(arg0)));
        var_a = 0;
        if (!uint64(storage_map_a[var_a])) {
            require(!uint64(storage_map_a[var_a]));
            require(uint64(storage_map_a[var_a]) > (uint64(block.timestamp)));
            require(0 - latestNav);
            require(!0 > 0x03);
            require(0x02);
            require(!0x01 == 0);
            require(0x09184e72a000);
            require(0 - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0))));
            require(0x09184e72a000 > (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0))));
            require(!(((latestNav * 0) - ((0 * latestNav) % 0x09184e72a000) / 0x2000) | (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0)) - (((0 * latestNav) % 0x09184e72a000) > (latestNav * 0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd) > ((((0 * latestNav) % 0x09184e72a000) > 0) + (((latestNav * 0) - ((0 * latestNav) % 0x09184e72a000) / 0x2000) | (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0)) - (((0 * latestNav) % 0x09184e72a000) > (latestNav * 0)) * 0x08000000000000000000000000000000000000000000000000000000000000) * 0x4b2d08ef176cf47267637e79e6bf28ff2377a3389cf4023da47a2cf9f6433fbd)));
            require(!(0x0f4240 - withdrawFeeBps) > 0x0f4240);
            require(0x09184e72a000);
            require(0 - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0))));
            require(0x09184e72a000 > (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (latestNav * 0) - (((0 * latestNav) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (latestNav * 0))));
            require(0x09184e72a000);
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public payable
    function Unresolved_8456cb59() public payable {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_d[var_d]), CustomError_d93c0665());
        require(!(bytes1(store_ad)), CustomError_d93c0665());
        store_ad = 0x01 | (uint248(store_ad));
        emit Event_62e78cea(address(msg.sender));
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
        return abi.encodePacked(storage_map_a[var_a], uint64(storage_map_a[var_a]));
    }
}