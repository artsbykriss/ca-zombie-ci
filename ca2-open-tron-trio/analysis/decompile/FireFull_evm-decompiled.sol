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
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_w;
    mapping(bytes32 => bytes32) storage_map_ao;
    mapping(bytes32 => bytes32) storage_map_am;
    bytes32 store_ba;
    bytes32 store_aw;
    mapping(bytes32 => bytes32) storage_map_af;
    bytes32 store_at;
    mapping(bytes32 => bytes32) storage_map_ac;
    bytes32 store_bc;
    uint256 public unresolved_d825a91c;
    mapping(bytes32 => bytes32) storage_map_bh;
    mapping(bytes32 => bytes32) storage_map_i;
    uint256 public jackpotIndex;
    address store_bd;
    uint256 public minJoinAmount;
    mapping(bytes32 => bytes32) storage_map_bs;
    mapping(bytes32 => bytes32) storage_map_bq;
    mapping(bytes32 => bytes32) storage_map_bm;
    bytes32 store_au;
    bytes32 store_ax;
    mapping(bytes32 => bytes32) storage_map_o;
    mapping(bytes32 => bytes32) storage_map_ah;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_t;
    mapping(bytes32 => bytes32) storage_map_ai;
    mapping(bytes32 => bytes32) storage_map_aa;
    bytes32 store_bb;
    bytes32 store_y;
    uint256 public superPlayerProfit;
    mapping(bytes32 => bytes32) storage_map_bi;
    mapping(bytes32 => bytes32) storage_map_m;
    mapping(bytes32 => bytes32) storage_map_ag;
    uint256 public playerCounter;
    mapping(bytes32 => bytes32) storage_map_bl;
    mapping(bytes32 => bytes32) storage_map_l;
    mapping(bytes32 => bytes32) storage_map_aj;
    address public creater;
    bytes32 store_av;
    uint256 public unresolved_6534e73e;
    mapping(bytes32 => bytes32) storage_map_bo;
    mapping(bytes32 => bytes32) storage_map_bf;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_al;
    mapping(bytes32 => bytes32) storage_map_s;
    bytes32 store_az;
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_a;
    mapping(bytes32 => bytes32) storage_map_k;
    uint256 public periods;
    mapping(bytes32 => bytes32) storage_map_b;
    bool public contractIndexInfo;
    mapping(bytes32 => bytes32) storage_map_an;
    mapping(bytes32 => bytes32) storage_map_br;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_ae;
    address public unresolved_d6c8eee2;
    mapping(bytes32 => bytes32) storage_map_z;
    bytes32 store_ay;
    mapping(bytes32 => bytes32) storage_map_bk;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_bj;
    mapping(bytes32 => bytes32) storage_map_bg;
    mapping(bytes32 => bytes32) storage_map_bn;
    mapping(bytes32 => bytes32) storage_map_bp;
    mapping(bytes32 => bytes32) storage_map_r;
    bytes public jackpotInfo;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_u;
    
    event WithdrawEvent(address, uint256, uint256);
    event InvitEvent(address, address, uint256);
    event SuperPlayerEvent(address, uint256, uint256, uint256);
    
    /// @custom:selector    0xc061cba0
    /// @custom:signature   Unresolved_c061cba0(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c061cba0(uint256 arg0) public view returns (uint256) {
        require(!0);
        require(!0);
        require(arg0 < store_a);
        var_a = 0x07;
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x5fb02f4d
    /// @custom:signature   startContract() public
    function startContract() public {
        require(!0);
        require(!0);
        require(msg.sender == (address(unresolved_d6c8eee2)), "startContract error");
        if (contractIndexInfo) {
            contractIndexInfo = 0x01 | (uint248(contractIndexInfo));
        }
    }
    
    /// @custom:selector    0x3a6f3c75
    /// @custom:signature   periodsLimit() public view returns (uint256)
    function periodsLimit() public view returns (uint256) {
        require(!0);
        require(!0);
        if (!0x01 == periods) {
            return 0x0ba43b7400;
            if (!0x02 == periods) {
                return 0x174876e800;
                return 0x2e90edd000;
            }
        }
    }
    
    /// @custom:selector    0x40255c7f
    /// @custom:signature   restore(address arg0, address arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function restore(address arg0, address arg1, uint256 arg2) public {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])), "Player already exists");
        var_a = address(arg1);
        require(bytes1(storage_map_f[var_a]), "Player already exists");
        var_a = address(arg0);
        require(!(bytes1(storage_map_f[var_a])), "Player already exists");
        var_c = 0x0a;
        var_a = address(arg1);
        if (0x01 < (storage_map_g[var_a])) {
            var_a = var_c + keccak256(var_a);
            storage_map_h[var_a] = 0x01 + (storage_map_h[var_a]);
            if (!0 < 0x09) {
                var_g = 0x01c0 + var_g;
                var_g = var_g + 0x0180;
                require(0x01 < (storage_map_g[var_a]), "recommender not exist");
                var_a = address(arg0);
                storage_map_f[var_a] = (0x0100 * (var_y)) | (uint248(var_g.length | (storage_map_f[var_a])));
                storage_map_h[var_a] = var_z;
                storage_map_i[var_a] = var_aa;
                storage_map_j[var_a] = var_ab;
                storage_map_k[var_a] = var_ac;
                storage_map_l[var_a] = var_ad;
                storage_map_m[var_a] = var_ae;
                storage_map_n[var_a] = var_af;
                storage_map_o[var_a] = var_ag;
                storage_map_p[var_a] = var_ah;
                var_a = keccak256(var_a) + 0x09;
                require(!(0 < 0x09), "recommender not exist");
                require(!0x0b, "recommender not exist");
                storage_map_q[var_a] = var_ai;
                var_a = keccak256(var_a) + 0x0a;
                require(!(var_ah), "recommender not exist");
                require(!(keccak256(var_a) + (storage_map_p[var_a]) > keccak256(var_a)), "recommender not exist");
                storage_map_r[var_a] = var_aj;
                storage_map_s[var_a] = (var_ak) | (uint248(storage_map_s[var_a]));
                emit InvitEvent(address(arg1), address(arg0), arg2);
                require(!(var_ai), "recommender not exist");
            }
            require(!(keccak256(var_a) + (storage_map_q[var_a]) > keccak256(var_a)), "recommender not exist");
        }
        var_a = address(arg1);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = 0x09 + keccak256(var_a);
        require(address(storage_map_u[var_a]) == 0, "recommender not exist");
        var_a = address(arg1);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = 0x09 + keccak256(var_a);
        var_a = address(arg1);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = address(storage_map_v[var_a]);
        require(0x02 < (storage_map_g[var_a]), "recommender not exist");
    }
    
    /// @custom:selector    0x0ac47c45
    /// @custom:signature   Unresolved_0ac47c45(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_0ac47c45(uint256 arg0) public view returns (address) {
        require(!0);
        require(!0);
        require(arg0 < store_y);
        var_a = 0x0b;
        return address(storage_map_b[var_a]);
    }
    
    /// @custom:selector    0xe2eb41ff
    /// @custom:signature   players(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function players(address arg0) public view returns (bool) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return abi.encodePacked(!(!bytes1(storage_map_z[var_b])), !(!bytes1(storage_map_z[var_b] / 0x0100)), storage_map_aa[var_b], storage_map_ab[var_b], storage_map_ac[var_b], storage_map_ad[var_b], storage_map_ae[var_b], storage_map_af[var_b], storage_map_ag[var_b], storage_map_ah[var_b], storage_map_ai[var_b], (bytes1(storage_map_aj[var_b])));
    }
    
    /// @custom:selector    0xa843af9a
    /// @custom:signature   Unresolved_a843af9a(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_a843af9a(uint256 arg0) public view returns (address) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return address(storage_map_z[var_b]);
    }
    
    /// @custom:selector    0x3ccfd60b
    /// @custom:signature   withdraw() public
    function withdraw() public {
        require(!0);
        require(!0);
        require(!address(msg.sender).code.length);
        address var_a = msg.sender;
        storage_map_al[var_a] = 0;
        (bool success, bytes memory ret0) = address(msg.sender).transfer(storage_map_al[var_a]);
        emit WithdrawEvent(msg.sender, storage_map_al[var_a], block.timestamp);
    }
    
    /// @custom:selector    0xad55a3fb
    /// @custom:signature   superPlayerWithdraw() public
    function superPlayerWithdraw() public {
        require(!0);
        require(!0);
        require(!address(msg.sender).code.length, "sub error");
        address var_a = msg.sender;
        require(bytes1(storage_map_am[var_a]), "sub error");
        var_a = msg.sender;
        require(!(0x28 > (storage_map_an[var_a])), "sub error");
        var_a = msg.sender;
        require(!(storage_map_w[var_a] > superPlayerProfit), "sub error");
        require((superPlayerProfit - (storage_map_w[var_a])) > 0, "add error");
        var_a = msg.sender;
        storage_map_w[var_a] = superPlayerProfit;
        require(superPlayerProfit - (storage_map_w[var_a]), "add error");
        require(superPlayerProfit - (storage_map_w[var_a]), "add error");
        require((0x05 * (superPlayerProfit - (storage_map_w[var_a]))) / (superPlayerProfit - (storage_map_w[var_a])) == 0x05, "add error");
        require(0x2710, "add error");
        var_a = msg.sender;
        require(!(((0x05 * (superPlayerProfit - (storage_map_w[var_a]))) / 0x2710) + (storage_map_ao[var_a]) < (storage_map_ao[var_a])), "add error");
        var_a = msg.sender;
        storage_map_ao[var_a] = ((0x05 * (superPlayerProfit - (storage_map_w[var_a]))) / 0x2710) + (storage_map_ao[var_a]);
        (bool success, bytes memory ret0) = address(msg.sender).transfer((0x05 * (superPlayerProfit - (storage_map_w[var_a]))) / 0x2710);
        emit SuperPlayerEvent(msg.sender, superPlayerProfit - (storage_map_w[var_a]), (0x05 * (superPlayerProfit - (storage_map_w[var_a]))) / 0x2710, block.timestamp);
    }
    
    /// @custom:selector    0xf5a55ff6
    /// @custom:signature   addOwnership(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addOwnership(address arg0) public {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])), "Permission denied");
        var_a = address(arg0);
        storage_map_f[var_a] = 0x01 | (uint248(storage_map_f[var_a]));
    }
    
    /// @custom:selector    0x333a808c
    /// @custom:signature   sedimentaryAssetWithdraw() public
    function sedimentaryAssetWithdraw() public {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])));
        unresolved_d825a91c = 0;
        (bool success, bytes memory ret0) = address(msg.sender).transfer(unresolved_d825a91c);
    }
    
    /// @custom:selector    0x627fa511
    /// @custom:signature   jackpot(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function jackpot(uint256 arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        uint256 var_b = arg0;
        return abi.encodePacked(storage_map_z[var_b], storage_map_aa[var_b], storage_map_ab[var_b]);
    }
    
    /// @custom:selector    0x52f50cfc
    /// @custom:signature   preShip(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function preShip(address arg0) public {
        require(!0);
        require(!0);
        address var_a = address(arg0);
        require(bytes1(storage_map_f[var_a]), "Player already exists");
        var_a = msg.sender;
        require(!(bytes1(storage_map_f[var_a])), "Player already exists");
        var_c = 0x0a;
        var_a = address(arg0);
        if (0x01 < (storage_map_g[var_a])) {
            var_a = var_c + keccak256(var_a);
            storage_map_h[var_a] = 0x01 + (storage_map_h[var_a]);
            if (!0 < 0x09) {
                var_g = 0x01c0 + var_g;
                var_g = var_g + 0x0180;
                require(0x01 < (storage_map_g[var_a]), "recommender not exist");
                var_a = msg.sender;
                storage_map_f[var_a] = (0x0100 * (var_y)) | (uint248(var_g.length | (storage_map_f[var_a])));
                storage_map_h[var_a] = var_z;
                storage_map_i[var_a] = var_aa;
                storage_map_j[var_a] = var_ab;
                storage_map_k[var_a] = var_ac;
                storage_map_l[var_a] = var_ad;
                storage_map_m[var_a] = var_ae;
                storage_map_n[var_a] = var_af;
                storage_map_o[var_a] = var_ag;
                storage_map_p[var_a] = var_ah;
                var_a = keccak256(var_a) + 0x09;
                require(!(0 < 0x09), "recommender not exist");
                require(!0x0b, "recommender not exist");
                storage_map_q[var_a] = var_ai;
                var_a = keccak256(var_a) + 0x0a;
                require(!(var_ah), "recommender not exist");
                require(!(keccak256(var_a) + (storage_map_p[var_a]) > keccak256(var_a)), "recommender not exist");
                storage_map_r[var_a] = var_aj;
                storage_map_s[var_a] = (var_ak) | (uint248(storage_map_s[var_a]));
                emit InvitEvent(address(arg0), msg.sender, block.timestamp);
                require(!(var_ai), "recommender not exist");
            }
            require(!(keccak256(var_a) + (storage_map_q[var_a]) > keccak256(var_a)), "recommender not exist");
        }
        var_a = address(arg0);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = 0x09 + keccak256(var_a);
        require(address(storage_map_u[var_a]) == 0, "recommender not exist");
        var_a = address(arg0);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = 0x09 + keccak256(var_a);
        var_a = address(arg0);
        require(0 < (storage_map_t[var_a]), "recommender not exist");
        var_a = address(storage_map_v[var_a]);
        require(0x02 < (storage_map_g[var_a]), "recommender not exist");
    }
    
    /// @custom:selector    0xa49a0a52
    /// @custom:signature   joinScale() public view returns (uint256)
    function joinScale() public view returns (uint256) {
        require(!0);
        require(!0);
        if (!0x01 == periods) {
            return 0x1a;
            if (!0x02 == periods) {
                return 0x1e;
                return 0x24;
            }
        }
    }
    
    /// @custom:selector    0xcb8c3376
    /// @custom:signature   Unresolved_cb8c3376(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_cb8c3376(uint256 arg0) public view returns (address) {
        require(!0);
        require(!0);
        require(arg0 < store_bc);
        var_a = 0x0c;
        return address(storage_map_b[var_a]);
    }
    
    /// @custom:selector    0x9834c39b
    /// @custom:signature   Unresolved_9834c39b(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9834c39b(address arg0) public view returns (bool) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return abi.encodePacked(!(!bytes1(storage_map_z[var_b])), storage_map_aa[var_b], storage_map_ab[var_b], storage_map_ac[var_b]);
    }
    
    /// @custom:selector    0x9c231159
    /// @custom:signature   setFirePowerContract(address arg0) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setFirePowerContract(address arg0) public returns (bool) {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])), "Permission denied");
        unresolved_d6c8eee2 = (address(arg0)) | (uint96(unresolved_d6c8eee2));
        store_bd = (uint96(store_bd)) | (address(arg0 | (uint96(unresolved_d6c8eee2))));
        return 0x01;
    }
    
    /// @custom:selector    0xf1d3fd58
    /// @custom:signature   delOwnership(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function delOwnership(address arg0) public {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])), "Permission denied");
        var_a = address(arg0);
        storage_map_f[var_a] = uint248(storage_map_f[var_a]);
    }
    
    /// @custom:selector    0x5e5b8937
    /// @custom:signature   setMinJoinAmount(uint256 arg0) public returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMinJoinAmount(uint256 arg0) public returns (bool) {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(0x01 == (bytes1(storage_map_f[var_a])), "Permission denied");
        minJoinAmount = arg0;
        return 0x01;
    }
    
    /// @custom:selector    0x41ee09cb
    /// @custom:signature   activateSuperPlayer() public returns (bool)
    function activateSuperPlayer() public returns (bool) {
        require(!0);
        require(!0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_am[var_a])), "SuperPlayer Activated");
        address var_d = msg.sender;
        require(address(store_bd).code.length);
        (bool success, bytes memory ret0) = address(store_bd).Unresolved_39c72595(var_d); // staticcall
        require(!ret0.length < 0x60);
        require(!var_g.length);
        return 0;
        uint256 var_g = var_g + 0x80;
        var_c = 0x01;
        var_a = msg.sender;
        storage_map_f[var_a] = (uint248(storage_map_f[var_a])) | var_g.length;
        storage_map_ao[var_a] = var_k;
        storage_map_i[var_a] = var_l;
        storage_map_j[var_a] = var_m;
        storage_map_am[var_a] = var_c | (uint248(storage_map_am[var_a]));
        return 0x01;
    }
    
    /// @custom:selector    0xb688a363
    /// @custom:signature   join() public payable
    function join() public payable {
        require(bytes1(contractIndexInfo), "Contract Not Start");
        require(!(0x01 == periods), "Period Maxmum limit exceeded");
        require(!(msg.value > 0x0ba43b7400), "Period Maxmum limit exceeded");
        require(!(msg.value < minJoinAmount), "Period Minimum limit exceeded");
        address var_e = msg.sender;
        require(bytes1(storage_map_bf[var_e]));
        require(!0x01 == periods);
        require(msg.value);
        require(msg.value);
        require(((0x1a * msg.value) / msg.value) == 0x1a);
        require(0x0a);
        require(address(store_bd / 0x01).code.length);
        (bool success, bytes memory ret0) = address(store_bd / 0x01).saleScale(); // staticcall
        require(!ret0.length < 0x20);
        require(msg.value);
        require(msg.value);
        require(((0x64 * msg.value) / msg.value) == 0x64);
        require(var_g.length);
        address var_b = msg.sender;
        require(address(store_bd).code.length);
        (bool success, bytes memory ret0) = address(store_bd).Unresolved_70a08231(var_b); // staticcall
        require(!(ret0.length < 0x20), "ticket not enough");
        require(!(var_g.length < ((0x64 * msg.value) / var_g.length)), "ticket not enough");
        require(msg.value, "add error");
        require(msg.value, "add error");
        require(((0x23 * msg.value) / msg.value) == 0x23, "add error");
        require(0x64, "add error");
        require(unresolved_6534e73e < 0x05, "add error");
        require(0x05, "add error");
        require(!((((0x23 * msg.value) / 0x64) + unresolved_d825a91c) < unresolved_d825a91c), "add error");
        var_b = 0x20;
        require(0x05, "add error");
        require(!(0 < 0x05), "add error");
        require(!0, "add error");
        require(!((0 + unresolved_d825a91c) < unresolved_d825a91c), "add error");
        require(0 < store_y, "add error");
        require(!0x01, "add error");
        require(!0x01, "add error");
        require(!((0 + (((0x23 * msg.value) / 0x64) / 0x05)) < (((0x23 * msg.value) / 0x64) / 0x05)), "add error");
        var_e = address(storage_map_bg[var_e]);
        var_g = var_b + (var_g + (0x20 * (storage_map_bp[var_e])));
        require(!(storage_map_bp[var_e]), "add error");
        var_e = keccak256(var_e) + 0x09;
        require((var_g + 0x20) + (0x20 * (storage_map_bp[var_e])) > (0x20 + (var_g + 0x20)), "add error");
        var_g = var_g + (0x20 + (0x20 * (storage_map_bq[var_e])));
        require(!(storage_map_bq[var_e]), "add error");
        var_e = keccak256(var_e) + 0x0a;
        require((0x20 + var_g) + (0x20 * (storage_map_bq[var_e])) > (0x20 + (0x20 + var_g)), "add error");
        require(!((0 + (((0x23 * msg.value) / 0x64) / 0x05)) + (var_ao) < (var_ao)), "add error");
        if ((0 + (((0x23 * msg.value) / 0x64) / 0x05)) + (var_ao) < (var_as)) {
        }
        if (!(unresolved_6534e73e + 0x01) > playerCounter) {
            var_e = address(storage_map_bf[var_e]);
            if (!storage_map_bf[var_e] / 0x0100) {
                if (0 < store_y) {
                    var_e = 0x0b;
                    storage_map_bg[var_e] = (address(storage_map_bf[var_e])) | (uint96(storage_map_bg[var_e]));
                    unresolved_6534e73e = unresolved_6534e73e + 0x01;
                    require(!((unresolved_6534e73e + 0x01) > playerCounter), "mul error");
                    var_e = 0x0b;
                    require(!(bytes1(storage_map_bf[var_e] / 0x0100)), "mul error");
                    require(0 < store_y, "mul error");
                    require(0 < store_y, "mul error");
                    require(!(address(storage_map_bg[var_e]) == 0), "mul error");
                    require(0 < store_y, "mul error");
                    var_g = 0x01c0 + var_g;
                    require(0 < store_y, "mul error");
                    require(unresolved_6534e73e, "mul error");
                    require(unresolved_6534e73e, "mul error");
                    require(!(0 < unresolved_6534e73e), "mul error");
                }
            }
            require(0 < store_y, "mul error");
        }
        if (!0x02 == periods) {
        }
        if (!0x02 == periods) {
        }
    }
    
    /// @custom:selector    0xe94d9db0
    /// @custom:signature   setNextPeriods() public
    function setNextPeriods() public {
        require(!0);
        require(!0);
        require(msg.sender == (address(unresolved_d6c8eee2)), "No authority");
        periods = 0x01 + periods;
    }
    
    /// @custom:selector    0x4b2abd1d
    /// @custom:signature   contractPlayerInfo(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function contractPlayerInfo(address arg0) public view returns (bytes memory) {
        require(!0);
        require(!0);
        address var_a = address(arg0);
        address var_c = 0x20 + (var_c + (0x20 * (storage_map_p[var_a])));
        require(!storage_map_p[var_a]);
        var_a = keccak256(var_a) + 0x09;
        require((var_c + 0x20) + (0x20 * (storage_map_p[var_a])) > (0x20 + (var_c + 0x20)));
        var_c = var_c + (0x20 + (0x20 * (storage_map_g[var_a])));
        require(!storage_map_g[var_a]);
        var_a = 0x0a + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_g[var_a])) > (0x20 + (0x20 + var_c)));
        require(!0 < (0x20 * var_c.length));
        require(!0 < (0x20 * var_c.length));
        return abi.encodePacked((0x20 + (0x20 + var_c)) - var_c, ((0x20 * var_c.length) + (0x20 + (0x20 + (0x20 + var_c)))) - var_c, var_c.length, var_c.length);
    }
    
    /// @custom:selector    0x022914a7
    /// @custom:signature   owners(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function owners(address arg0) public view returns (bool) {
        require(!0);
        require(!0);
        address var_b = address(arg0);
        return !(!bytes1(storage_map_z[var_b]));
    }
}