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
    uint256 public constant unresolved_cc040dc7 = 83730621340915918108512726170279046227750370710898224011930158093829523315222;
    bytes public constant UPGRADE_INTERFACE_VERSION = 0xBytes([53, 46, 48, 46, 48]);
    uint256 public constant version = 3;
    uint256 public constant NAV_SIGNER_ROLE = 21614543442897740902293335356929983108061623038163596613304291425883151812949;
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    uint256 public constant unresolved_52d1902d = e07c8dba;
    uint256 public constant unresolved_9dd6fe88 = 113658709966171638440256896822041815707291962875754310688051668244137771446340;
    
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_w;
    address store_u;
    mapping(bytes32 => bytes32) storage_map_q;
    bytes32 store_m;
    mapping(bytes32 => bytes32) storage_map_s;
    uint256 storage_map_f[storage_map_a[var_a] - 0x01];
    mapping(bytes32 => bytes32) storage_map_ac;
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_b;
    uint256 store_c;
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_e;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_o;
    address public bridgeVault;
    mapping(bytes32 => bytes32) storage_map_v;
    address public beacon;
    uint256 public pTokenCount;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_t;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_aa;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_y;
    mapping(bytes32 => bytes32) storage_map_p;
    uint256 storage_map_v[storage_map_n[var_b] - 0x01];
    mapping(bytes32 => bytes32) storage_map_l;
    
    event BeaconUpdated(address, address);
    event MetadataBaseURIUpdated(string, string);
    event RoleRevoked(bytes32, address, address);
    event Event_54c39467();
    event RoleAdminChanged(bytes32, bytes32, bytes32);
    event Initialized(uint64);
    event Upgraded(address);
    event RoleGranted(bytes32, address, address);
    error CustomError_00000000();
    event Event_719de5e7();
    event Event_7a974a0e();
    event BridgeVaultUpdated(address, address);
    
    /// @custom:selector    0xfe618ab1
    /// @custom:signature   Unresolved_fe618ab1(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_fe618ab1(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(arg1 == arg1);
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]));
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + ((0x04 + arg0) + 0x20)) + 0x20) - (0 + ((0x04 + arg0) + 0x20))) < 0x20);
        require((0 + (arg0 + 0x20)) == (address(0 + (arg0 + 0x20))));
        var_a = address(0 + (arg0 + 0x20));
        storage_map_a[var_a] = arg1 | (uint248(storage_map_a[var_a]));
        require(0 < (arg0), CustomError_e2517d3f());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x8380f472
    /// @custom:signature   Unresolved_8380f472(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_8380f472(uint256 arg0) public view {
        if (store_b) {
            require(bytes1(store_b));
            require(bytes1(store_b) - ((store_b >> 0x01) < 0x20));
            require(bytes1(store_b));
            require(bytes1(store_b) - ((store_b >> 0x01) < 0x20));
            require(!store_b >> 0x01);
            var_a = 0xa16a46d94261c7517cc8ff89f61c0ce93598e3c849801011dee649a6a557d102;
            require(0x1f < (store_b >> 0x01));
        }
    }
    
    /// @custom:selector    0x9f3d1a2a
    /// @custom:signature   metadataBaseURI() public view returns (bytes memory)
    function metadataBaseURI() public view returns (bytes memory) {
        if (store_c) {
            if (store_c - ((store_c >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_c >> 0x01)) / 0x20) * 0x20));
                if (store_c) {
                    if (store_c - ((store_c >> 0x01) < 0x20)) {
                        if (!store_c >> 0x01) {
                            if (0x1f < (store_c >> 0x01)) {
                                var_a = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641007;
                                if ((0x20 + var_c) + (store_c >> 0x01) > (0x20 + (0x20 + var_c))) {
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
    
    /// @custom:selector    0xca15c873
    /// @custom:signature   getRoleMemberCount(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleMemberCount(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x7f41826b
    /// @custom:signature   managerOf(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function managerOf(address arg0) public view returns (address) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0xebcb0b7a
    /// @custom:signature   setBridgeVault(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setBridgeVault(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_d92e233d());
        require(address(arg0), CustomError_d92e233d());
        bridgeVault = (address(arg0)) | (uint96(bridgeVault));
        emit BridgeVaultUpdated(address(bridgeVault), address(arg0));
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
    
    /// @custom:selector    0x5df8122f
    /// @custom:signature   Unresolved_5df8122f(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5df8122f(address arg0) public pure {
        require(arg0 == (address(arg0)));
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
        require(bytes1(storage_map_a[var_a]), CustomError_d311c495());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_a[var_a])), CustomError_d311c495());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = uint248(storage_map_a[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
        require(!0x01, CustomError_d311c495());
        require(!0x01, CustomError_d311c495());
        require(!0x01, CustomError_d311c495());
        var_a = var_a;
        require(!(uint64(bridgeVault / 0x010000000000000000000000000000000000000000)), CustomError_d311c495());
        require(!(uint64(bridgeVault / 0x010000000000000000000000000000000000000000) > storage_map_a[var_a]), CustomError_d311c495());
        require(!(!uint64(bridgeVault / 0x010000000000000000000000000000000000000000)), CustomError_d311c495());
        var_a = var_a;
        if (!arg0 == var_a) {
            var_a = arg0;
            var_a = address(arg1);
            if (!storage_map_a[var_a]) {
                require(!(arg0 == var_a), CustomError_e2517d3f());
                require(!storage_map_a[var_a], CustomError_e2517d3f());
                require(!((storage_map_a[var_a] - 0x01) > storage_map_a[var_a]), CustomError_e2517d3f());
                require(!((storage_map_a[var_a] - 0x01) > storage_map_a[var_a]), CustomError_e2517d3f());
                var_a = 0 + keccak256(var_a);
                require((storage_map_a[var_a] - 0x01) == (storage_map_a[var_a] - 0x01), CustomError_e2517d3f());
                var_a = 0 + keccak256(var_a);
                storage_map_f[storage_map_a[var_a] - 0x01] = storage_map_g[var_a];
                var_a = storage_map_h[var_a];
                storage_map_a[var_a] = storage_map_a[var_a];
                require((storage_map_a[var_a] - 0x01) < (storage_map_i[var_a]), CustomError_e2517d3f());
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((storage_map_a[var_a] - 0x01) < (storage_map_i[var_a]), CustomError_e2517d3f());
                require(storage_map_a[var_a], CustomError_e2517d3f());
            }
        }
    }
    
    /// @custom:selector    0xa3246ad3
    /// @custom:signature   getRoleMembers(bytes32 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleMembers(bytes32 arg0) public view returns (bytes memory) {
        var_a = var_a;
        uint256 var_c = var_c + (0x20 + (0x20 * (storage_map_i[var_a])));
        require(!storage_map_i[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_i[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0xc2eabaf3
    /// @custom:signature   Unresolved_c2eabaf3(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_c2eabaf3(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_67e64154());
        var_a = address(arg0);
        require(bytes1(storage_map_a[var_a]), CustomError_67e64154());
        var_a = address(arg0);
        storage_map_j[var_a] = (uint248(storage_map_j[var_a])) | arg1;
        emit Event_7a974a0e(address(arg0), !(!bytes1(storage_map_j[var_a])), arg1);
    }
    
    /// @custom:selector    0xd42afb56
    /// @custom:signature   setBeacon(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setBeacon(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_d92e233d());
        require(address(arg0), CustomError_d92e233d());
        beacon = (address(arg0)) | (uint96(beacon));
        emit BeaconUpdated(address(beacon), address(arg0));
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_e[var_a];
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
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        require(!0, CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        require(storage_map_a[var_a], CustomError_e2517d3f());
        storage_map_a[var_a] = 0x01 + storage_map_a[var_a];
        var_a = keccak256(var_a);
        storage_map_l[var_a] = address(arg1);
        var_a = address(arg1);
        storage_map_a[var_a] = storage_map_a[var_a];
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = 0x01 | (uint248(storage_map_a[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
        require(!0x01, CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        require(storage_map_a[var_a], CustomError_e2517d3f());
        storage_map_a[var_a] = 0x01 + storage_map_a[var_a];
        var_a = keccak256(var_a);
        storage_map_l[var_a] = address(arg1);
        var_a = address(arg1);
        storage_map_a[var_a] = storage_map_a[var_a];
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x5a05180f00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x5a05180f00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!(uint32(arg0)) == 0x01ffc9a700000000000000000000000000000000000000000000000000000000);
    }
    
    /// @custom:selector    0x84b0196e
    /// @custom:signature   eip712Domain() public view
    function eip712Domain() public view {
        if (store_b) {
            if (store_b - ((store_b >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_b >> 0x01)) / 0x20) * 0x20));
                if (store_b) {
                    if (store_b - ((store_b >> 0x01) < 0x20)) {
                        if (!store_b >> 0x01) {
                            if (0x1f < (store_b >> 0x01)) {
                                var_a = 0xa16a46d94261c7517cc8ff89f61c0ce93598e3c849801011dee649a6a557d102;
                                if ((0x20 + var_c) + (store_b >> 0x01) > (0x20 + (0x20 + var_c))) {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x6c2eb350
    /// @custom:signature   reinitialize() public
    function reinitialize() public {
        require(bytes1(store_m / 0x010000000000000000), CustomError_f92ee8a9());
        require(!(bytes1(store_m / 0x010000000000000000)), CustomError_f92ee8a9());
        store_m = 0x010000000000000000 | (0x02 | (uint184(store_m)));
        var_b = var_b;
        var_b = address(msg.sender);
        if (storage_map_n[var_b]) {
            var_b = var_b;
            var_b = var_b;
            storage_map_o[var_b] = 0;
            emit RoleAdminChanged(var_b, storage_map_o[var_b], 0);
            var_b = var_b;
            var_b = var_b;
            storage_map_o[var_b] = var_b;
            emit RoleAdminChanged(var_b, storage_map_o[var_b], var_b);
            var_b = var_b;
            if (!0 < storage_map_n[var_b]) {
                var_b = var_b;
                require(bytes1(storage_map_n[var_b]), CustomError_e2517d3f());
                var_b = var_b;
                var_b = address(storage_map_p[var_b]);
                require(!(0 < storage_map_n[var_b]), CustomError_e2517d3f());
                require(0 < (storage_map_q[var_b]), CustomError_e2517d3f());
                var_b = var_b;
                var_b = address(storage_map_p[var_b]);
                require(bytes1(storage_map_n[var_b]), CustomError_e2517d3f());
            }
            var_b = var_b;
            var_b = address(storage_map_p[var_b]);
            storage_map_n[var_b] = 0x01 | (uint248(storage_map_n[var_b]));
            emit RoleGranted(var_b, address(storage_map_p[var_b]), address(msg.sender));
            require(!0, CustomError_e2517d3f());
            var_b = var_b;
            var_b = address(storage_map_p[var_b]);
            require(!0x01, CustomError_e2517d3f());
        }
        store_m = uint248(store_m);
        emit Initialized(0x02);
    }
    
    /// @custom:selector    0x0e68ec95
    /// @custom:signature   config(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function config(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_e = address(arg0);
        var_a = var_a + 0x60;
        return abi.encodePacked(address(var_a.length), var_o, (var_p));
    }
    
    /// @custom:selector    0x1f5f81f5
    /// @custom:signature   Unresolved_1f5f81f5(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1f5f81f5(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_e[var_a];
    }
    
    /// @custom:selector    0xd85777d0
    /// @custom:signature   Unresolved_d85777d0(uint256 arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_d85777d0(uint256 arg0, uint256 arg1, uint256 arg2) public pure {
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(!arg2 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1 > 0xffffffffffffffff), CustomError_e07c8dba());
        require(!(((var_c + (uint248(0x3f + (arg1 + 0x1f)))) < var_c) | ((var_c + (uint248(0x3f + (arg1 + 0x1f)))) > 0xffffffffffffffff)), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248(0x3f + (arg1 + 0x1f)));
        require(0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f == address(this), CustomError_e07c8dba());
        require(!(0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f == address(this)), CustomError_e07c8dba());
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_4c9c8ce3());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_h); // staticcall
        var_a = var_a;
        require(var_c == var_a, CustomError_4c9c8ce3());
        require(0 - address(0x0f52).code.length, CustomError_4c9c8ce3());
        var_h = 0x0f52;
        store_u = var_h | (uint96(store_u));
        emit Upgraded(0x0f52);
        require(!var_i, CustomError_d6bda275());
        (bool success, bytes memory ret0) = address(0x0f52).Unresolved_(var_j); // delegatecall
        require(!ret0.length, CustomError_d6bda275());
        var_c = var_c + (0x20 + ret0.length);
        if (ret0.length > 0) {
        }
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_4c9c8ce3());
        require(0x01, CustomError_4c9c8ce3());
        var_a = var_a;
        require(var_c.length == var_a, CustomError_4c9c8ce3());
        require(0 - (address(arg0).code.length), CustomError_4c9c8ce3());
        store_u = (address(arg0)) | (uint96(store_u));
        emit Upgraded(address(arg0));
        require(!var_c.length, CustomError_d6bda275());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_m); // delegatecall
        require(!ret0.length, CustomError_d6bda275());
        var_c = var_c + (0x20 + ret0.length);
        if (ret0.length > 0) {
        }
        require(!(!(address(store_u)) == 0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0xd3c5ee0e
    /// @custom:signature   Unresolved_d3c5ee0e(address arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_d3c5ee0e(address arg0, uint256 arg1, uint256 arg2) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(arg2 == arg2);
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]));
        var_a = address(arg0);
        require(bytes1(storage_map_a[var_a]));
        require(!0 < (arg1));
        require(0 < (arg1));
        require(!(((0 + ((0x04 + arg1) + 0x20)) + 0x20) - (0 + ((0x04 + arg1) + 0x20))) < 0x20);
        require((0 + (arg1 + 0x20)) == (address(0 + (arg1 + 0x20))));
        var_a = address(0 + (arg1 + 0x20));
        storage_map_a[var_a] = arg2 | (uint248(storage_map_a[var_a]));
        require(0 < (arg1), CustomError_67e64154());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x4d9f30fc
    /// @custom:signature   Unresolved_4d9f30fc(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_4d9f30fc(uint256 arg0) public view returns (uint256) {
        var_a = this.code[13963:15256];
        var_c = var_c + 0x20;
        var_c = (((0x20 + var_c) + 0x40) + (uint248(var_c.length + 0x1f))) + 0x20;
        var_c = ((0x20 + (((0x20 + var_c) + 0x40) + (uint248(var_c.length + 0x1f)) + 0x20)) + var_c.length) + var_c.length;
        return ;
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
        require(!(bytes1(storage_map_n[var_b])), CustomError_d311c495());
        var_b = arg0;
        var_b = address(arg1);
        storage_map_n[var_b] = uint248(storage_map_n[var_b]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
        require(!0x01, CustomError_d311c495());
        require(!0x01, CustomError_d311c495());
        require(!0x01, CustomError_d311c495());
        var_b = var_b;
        require(!(uint64(bridgeVault / 0x010000000000000000000000000000000000000000)), CustomError_d311c495());
        require(!(uint64(bridgeVault / 0x010000000000000000000000000000000000000000) > storage_map_n[var_b]), CustomError_d311c495());
        require(!(!uint64(bridgeVault / 0x010000000000000000000000000000000000000000)), CustomError_d311c495());
        var_b = var_b;
        if (!arg0 == var_b) {
            var_b = arg0;
            var_b = address(arg1);
            if (!storage_map_n[var_b]) {
                require(!arg0 == var_b);
                require(!storage_map_n[var_b]);
                require(!(storage_map_n[var_b] - 0x01) > storage_map_n[var_b]);
                require(!(storage_map_n[var_b] - 0x01) > storage_map_n[var_b]);
                var_b = 0 + keccak256(var_b);
                require((storage_map_n[var_b] - 0x01) == (storage_map_n[var_b] - 0x01));
                var_b = 0 + keccak256(var_b);
                storage_map_v[storage_map_n[var_b] - 0x01] = storage_map_w[var_b];
                var_b = storage_map_x[var_b];
                storage_map_n[var_b] = storage_map_n[var_b];
                require((storage_map_n[var_b] - 0x01) < (storage_map_q[var_b]));
                var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((storage_map_n[var_b] - 0x01) < (storage_map_q[var_b]));
                require(storage_map_n[var_b]);
            }
        }
    }
    
    /// @custom:selector    0xed6d7b26
    /// @custom:signature   Unresolved_ed6d7b26(uint256 arg0, uint256 arg1, uint256 arg2, bool arg3, uint256 arg4, address arg5, uint256 arg6) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    function Unresolved_ed6d7b26(uint256 arg0, uint256 arg1, uint256 arg2, bool arg3, uint256 arg4, address arg5, uint256 arg6) public {
        require(!arg1 > 0xffffffffffffffff);
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]));
        require(!(((0x04 + arg1) + 0x20) - (0x04 + arg1)) < 0x20);
        require(arg1 == (address(arg1)));
        require(address(arg1) == 0);
        require(!(address(arg1)) == 0);
        var_c = this.code[13963:15256];
        var_e = var_e + 0x20;
        var_e = (((0x20 + var_e) + 0x40) + (uint248(var_e.length + 0x1f))) + 0x20;
        var_e = ((0x20 + (((0x20 + var_e) + 0x40) + (uint248(var_e.length + 0x1f)) + 0x20)) + var_e.length) + var_e.length;
        require(!address(keccak256(var_r)).code.length);
        var_e = var_e + 0x60;
        require(!(((0x04 + arg1) + 0xc0) - ((0x04 + arg1) + 0xa0)) < 0x20);
        require((arg1 + 0xa0) == (address(arg1 + 0xa0)));
        var_u = 0x01;
        var_a = address(keccak256(var_r));
        storage_map_a[var_a] = (uint96(storage_map_a[var_a])) | (address(var_e.length));
        storage_map_e[var_a] = var_c;
        storage_map_y[var_a] = (uint248(storage_map_y[var_a])) | (var_v);
        storage_map_a[var_a] = var_u | (uint248(storage_map_a[var_a]));
        pTokenCount = pTokenCount + 0x01;
        var_a = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641002;
        storage_map_aa[var_a] = (uint96(storage_map_aa[var_a])) | (address(keccak256(var_r)));
        var_e = var_e + 0x20;
        assembly { addr := create(0, var_e, (((0x050d + var_e) + 0x40) + (uint248(var_e.length + 0x1f)) + 0x20) - var_e, arg0) }
        require(245);
        require(address(245) == (address(keccak256(var_r))));
        require(!(((0x04 + arg1) + 0x20) - (0x04 + arg1)) < 0x20);
        require(arg1 == (address(arg1)));
        require(!(arg1 + (arg1 + 0x20)) > 0xffffffffffffffff);
        require(!(arg1 + (arg1 + 0x40)) > 0xffffffffffffffff);
        require(!(((0x04 + arg1) + 0x80) - ((0x04 + arg1) + 0x60)) < 0x20);
        require((arg1 + 0x60) == (bytes1(arg1 + 0x60)));
        require(address(245).code.length);
        (bool success, bytes memory ret0) = address(245).transfer(0);
    }
    
    /// @custom:selector    0x8da87eb1
    /// @custom:signature   Unresolved_8da87eb1(uint64 arg0) public
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_8da87eb1(uint64 arg0) public {
        require(arg0 == (uint64(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_d311c495());
        var_a = var_a;
        require(!(uint64(arg0)), CustomError_d311c495());
        require(!(uint64(arg0) > storage_map_a[var_a]), CustomError_d311c495());
        bridgeVault = (uint192(bridgeVault)) | (0x010000000000000000000000000000000000000000 * (uint64(arg0)));
        emit Event_54c39467(uint64(bridgeVault / 0x010000000000000000000000000000000000000000), uint64(arg0));
        require(!(!uint64(arg0)), CustomError_d311c495());
        bridgeVault = (uint192(bridgeVault)) | (0x010000000000000000000000000000000000000000 * (uint64(arg0)));
        emit Event_54c39467(uint64(bridgeVault / 0x010000000000000000000000000000000000000000), uint64(arg0));
    }
    
    /// @custom:selector    0x57d41c64
    /// @custom:signature   Unresolved_57d41c64(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_57d41c64(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0xfb94bd8a
    /// @custom:signature   Unresolved_fb94bd8a(uint256 arg0, uint0 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint0", "bytes0", "int0"]
    function Unresolved_fb94bd8a(uint256 arg0, uint0 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        require(bytes1(store_c), CustomError_e2517d3f());
        require(bytes1(store_c) - ((store_c >> 0x01) < 0x20), CustomError_e2517d3f());
        uint256 var_d = var_d + (0x20 + (((0x1f + (store_c >> 0x01)) / 0x20) * 0x20));
        require(bytes1(store_c), CustomError_e2517d3f());
        require(bytes1(store_c) - ((store_c >> 0x01) < 0x20), CustomError_e2517d3f());
        require(!(store_c >> 0x01), CustomError_e2517d3f());
        require(0x1f < (store_c >> 0x01), CustomError_e2517d3f());
        var_a = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641007;
        require((0x20 + var_d) + (store_c >> 0x01) > (0x20 + (0x20 + var_d)), CustomError_e2517d3f());
        require(!(arg0 > 0xffffffffffffffff), CustomError_e2517d3f());
        require(bytes1(store_c), CustomError_e2517d3f());
        require(bytes1(store_c) - ((store_c >> 0x01) < 0x20), CustomError_e2517d3f());
        require(!((store_c >> 0x01) > 0x1f), CustomError_e2517d3f());
        require(!((store_c >> 0x01) > (arg0)), CustomError_e2517d3f());
        require(!(arg0 < 0x20), CustomError_e2517d3f());
        require(!(0 < ((((store_c >> 0x01) + 0x1f) >> 0x05) - ((arg0 + 0x1f) >> 0x05))), CustomError_e2517d3f());
        require((arg0 > 0x1f) == 0x01, CustomError_e2517d3f());
        var_a = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641007;
        require(!(0 < (uint248(arg0))), CustomError_e2517d3f());
        require(!(uint248(arg0) < (arg0)), CustomError_e2517d3f());
        storage_map_a[var_a] = ((0x20 + (arg0)) + 0) & (~(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (bytes1(arg0 << 0x03))));
        store_c = (arg0 << 0x01) + 0x01;
        emit MetadataBaseURIUpdated(0x40, ((var_d + 0x40) + (uint248(var_d.length + 0x1f)) + 0x20) - var_d, var_d.length, (arg0));
        store_c = (arg0 << 0x01) + 0x01;
        emit MetadataBaseURIUpdated(0x40, ((var_d + 0x40) + (uint248(var_d.length + 0x1f)) + 0x20) - var_d, var_d.length, (arg0));
        require(!(arg0), CustomError_e2517d3f());
        store_c = (arg0 << 0x01) | (~(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (arg0 << 0x03)) & (0 + (0x20 + (arg0))));
        emit MetadataBaseURIUpdated(0x40, ((var_d + 0x40) + (uint248(var_d.length + 0x1f)) + 0x20) - var_d, var_d.length, (arg0));
        store_c = (arg0 << 0x01) | (~(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (arg0 << 0x03)) & (0));
        emit MetadataBaseURIUpdated(0x40, ((var_d + 0x40) + (uint248(var_d.length + 0x1f)) + 0x20) - var_d, var_d.length, (arg0));
    }
    
    /// @custom:selector    0xb806d460
    /// @custom:signature   Unresolved_b806d460(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_b806d460(uint256 arg0) public view returns (address) {
        require(arg0 < pTokenCount);
        var_a = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641002;
        return address(storage_map_ab[var_a]);
    }
    
    /// @custom:selector    0x9010d07c
    /// @custom:signature   getRoleMember(bytes32 arg0, uint256 arg1) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function getRoleMember(bytes32 arg0, uint256 arg1) public view returns (address) {
        var_a = var_a;
        require(arg1 < (storage_map_i[var_a]));
        var_a = 0 + keccak256(var_a);
        return address(storage_map_ac[var_a]);
    }
    
    /// @custom:selector    0x22555cda
    /// @custom:signature   Unresolved_22555cda(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_22555cda(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0x4e666f20
    /// @custom:signature   Unresolved_4e666f20(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4e666f20(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_67e64154());
        var_a = address(arg0);
        require(bytes1(storage_map_a[var_a]), CustomError_67e64154());
        var_a = address(arg0);
        storage_map_ad[var_a] = arg1;
        emit Event_719de5e7(address(arg0), storage_map_ad[var_a], arg1);
    }
    
    /// @custom:selector    0x1c0d9bca
    /// @custom:signature   Unresolved_1c0d9bca(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1c0d9bca(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x48477f38
    /// @custom:signature   Unresolved_48477f38(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_48477f38(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
}