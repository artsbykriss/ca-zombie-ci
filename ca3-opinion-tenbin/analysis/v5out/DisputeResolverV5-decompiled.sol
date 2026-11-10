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
    bytes public constant VERSION = 0xBytes([53, 46, 48, 46, 48]);
    uint256 public constant unresolved_c2117309 = 74274921817751248094718065371742003061103356065104057648113035213316718461728;
    uint256 public constant MIN_WINDOW_DURATION = 3600;
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    uint256 public constant unresolved_52d1902d = 3963877391197344453575983046348115674221700746820753546331534351508065746944;
    uint256 public constant MAX_ACTIVE_RETURN = 200;
    uint256 public constant REWARD_MANAGER_ROLE = 6929006194705809631891541069947565074251412566298752009331330615582471944525;
    uint256 public constant MAX_WINDOW_DURATION = 864000;
    uint256 public constant OPERATOR_ROLE = 68480234572564484000009739288816226232004483193032960564416004514937613957417;
    
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_w;
    mapping(bytes32 => bytes32) storage_map_ay;
    mapping(bytes32 => bytes32) storage_map_ao;
    mapping(bytes32 => bytes32) storage_map_am;
    uint256 public minReVoteWindow;
    mapping(bytes32 => bytes32) storage_map_ak;
    uint256 public maxReVoteWindow;
    mapping(bytes32 => bytes32) storage_map_af;
    bytes32 treasuryt;
    mapping(bytes32 => bytes32) storage_map_ac;
    mapping(bytes32 => bytes32) storage_map_ar;
    mapping(bytes32 => bytes32) storage_map_bh;
    address storage_map_ca[storage_map_b[var_a] - 0x01];
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_ce;
    bytes32 store_l;
    mapping(bytes32 => bytes32) storage_map_bq;
    mapping(bytes32 => bytes32) storage_map_bs;
    mapping(bytes32 => bytes32) storage_map_bm;
    address treasuryu;
    mapping(bytes32 => bytes32) storage_map_ca;
    mapping(bytes32 => bytes32) storage_map_o;
    mapping(bytes32 => bytes32) storage_map_ah;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_d;
    bool public unresolved_5c975abb;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_t;
    mapping(bytes32 => bytes32) storage_map_aq;
    mapping(bytes32 => bytes32) storage_map_cc;
    mapping(bytes32 => bytes32) storage_map_ai;
    mapping(bytes32 => bytes32) storage_map_aa;
    uint256 storage_map_br[storage_map_f[var_e] - 0x01];
    mapping(bytes32 => bytes32) storage_map_y;
    address storage_map_cc[store_e + keccak256(var_a)];
    mapping(bytes32 => bytes32) storage_map_cd;
    mapping(bytes32 => bytes32) storage_map_bi;
    mapping(bytes32 => bytes32) storage_map_ag;
    mapping(bytes32 => bytes32) storage_map_be;
    mapping(bytes32 => bytes32) storage_map_bl;
    mapping(bytes32 => bytes32) storage_map_bv;
    mapping(bytes32 => bytes32) storage_map_bd;
    mapping(bytes32 => bytes32) storage_map_aj;
    mapping(bytes32 => bytes32) storage_map_bc;
    mapping(bytes32 => bytes32) storage_map_cb;
    mapping(bytes32 => bytes32) storage_map_bz;
    mapping(bytes32 => bytes32) storage_map_bu;
    mapping(bytes32 => bytes32) storage_map_bo;
    mapping(bytes32 => bytes32) storage_map_bf;
    mapping(bytes32 => bytes32) storage_map_by;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_al;
    mapping(bytes32 => bytes32) storage_map_s;
    mapping(bytes32 => bytes32) storage_map_av;
    mapping(bytes32 => bytes32) storage_map_aw;
    mapping(bytes32 => bytes32) storage_map_ap;
    mapping(bytes32 => bytes32) storage_map_az;
    mapping(bytes32 => bytes32) storage_map_j;
    mapping(bytes32 => bytes32) storage_map_bb;
    uint256 storage_map_bt[store_e + keccak256(var_e)];
    address public treasury;
    address public oracleProxy;
    mapping(bytes32 => bytes32) storage_map_b;
    bytes32 store_e;
    mapping(bytes32 => bytes32) storage_map_an;
    mapping(bytes32 => bytes32) storage_map_bt;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_br;
    mapping(bytes32 => bytes32) storage_map_ae;
    mapping(bytes32 => bytes32) storage_map_z;
    mapping(bytes32 => bytes32) storage_map_bk;
    mapping(bytes32 => bytes32) storage_map_ba;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_bj;
    mapping(bytes32 => bytes32) storage_map_bg;
    mapping(bytes32 => bytes32) storage_map_bn;
    mapping(bytes32 => bytes32) storage_map_bp;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_bw;
    mapping(bytes32 => bytes32) storage_map_bx;
    address treasurys;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_ax;
    
    event Event_31237182();
    event RewardWithdrawn(bytes32, uint256);
    event OracleProxyUpdated(address, address);
    event StakeClaimed(bytes32, address, uint256);
    event ReVoteWindowBoundsUpdated(uint256, uint256);
    event DisputeFiled(bytes32, address, uint256, uint8, uint256);
    event RoleGranted(bytes32, address, address);
    event Event_1771e1fa();
    event Event_5db9ee0a();
    event RewardDeposited(bytes32, address, uint256);
    event DisputeResolved(bytes32, bool, uint256[2]);
    event Event_3e273fdb();
    error CategoryNotFound(bytes32);
    event RoleRevoked(bytes32, address, address);
    event Event_62e78cea();
    event Event_3bc38cfb();
    event Event_bc7cd75a();
    event TreasuryUpdated(address, address);
    event QuestionDeadlineConfigured(bytes32, uint256, uint256);
    event ResolutionFinalized(bytes32, uint256[2]);
    event DisputeTimedOut(bytes32);
    event Event_2167d217();
    
    /// @custom:selector    0x14423650
    /// @custom:signature   setOracleProxy(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setOracleProxy(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_d92e233d());
        require(address(arg0), CustomError_d92e233d());
        oracleProxy = (address(arg0)) | (uint96(oracleProxy));
        emit OracleProxyUpdated(address(oracleProxy), address(arg0));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_e = var_e + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_e.length);
        require(0x29);
    }
    
    /// @custom:selector    0xff435224
    /// @custom:signature   Unresolved_ff435224(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ff435224(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_056d5007());
        require(address(arg1), CustomError_056d5007());
        var_a = arg0;
        require(address(storage_map_b[var_a]), CustomError_056d5007());
        storage_map_d[var_a] = (address(arg1)) | (uint96(storage_map_d[var_a]));
        emit Event_1771e1fa(arg0, address(storage_map_d[var_a]), address(arg1));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_f = var_f + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_f.length);
        require(0x29);
    }
    
    /// @custom:selector    0xd08c0edc
    /// @custom:signature   getActiveQuestionIds() public view returns (bytes memory)
    function getActiveQuestionIds() public view returns (bytes memory) {
        require(!(0xc8 < store_e), CustomError_9ba345dd());
        uint256 var_d = var_d + (0x20 + (0x20 * store_e));
        if (!store_e) {
            var_e = 0x0162;
            if ((0x20 + var_d) + (0x20 * store_e) > (0x20 + (0x20 + var_d))) {
                return abi.encodePacked(0x20, var_d.length);
            }
        }
    }
    
    /// @custom:selector    0xd7ff1dc7
    /// @custom:signature   getQuestionDeadlineConfig(bytes32 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getQuestionDeadlineConfig(bytes32 arg0) public view returns (bool) {
        uint256 var_a = arg0;
        require(!bytes1(storage_map_g[var_a]));
        return abi.encodePacked(storage_map_b[var_a], storage_map_h[var_a], 0x01);
        require(!bytes1(storage_map_g[var_a]));
        require(!bytes1(storage_map_g[var_a]));
        return abi.encodePacked(storage_map_b[var_a], storage_map_d[var_a], 0);
        var_a = storage_map_b[var_a];
        return abi.encodePacked(storage_map_b[var_a], storage_map_i[var_a], 0);
    }
    
    /// @custom:selector    0xc0c53b8b
    /// @custom:signature   Unresolved_c0c53b8b(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c0c53b8b(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xfdf426a2
    /// @custom:signature   Unresolved_fdf426a2(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_fdf426a2(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_056d5007());
        require(address(arg1), CustomError_056d5007());
        var_a = arg0;
        require(address(storage_map_b[var_a]), CustomError_056d5007());
        storage_map_b[var_a] = (address(arg1)) | (uint96(storage_map_b[var_a]));
        emit Event_3bc38cfb(arg0, address(storage_map_b[var_a]), address(arg1));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_f = var_f + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_f.length);
        require(0x29);
    }
    
    /// @custom:selector    0x1a1d4b79
    /// @custom:signature   Unresolved_1a1d4b79(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_1a1d4b79(uint256 arg0) public view returns (uint256) {
        uint256 var_b = arg0;
        return storage_map_j[var_b];
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public
    function Unresolved_3f4ba83a() public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "Pausable: not paused");
        require(bytes1(unresolved_5c975abb), "Pausable: not paused");
        unresolved_5c975abb = uint248(unresolved_5c975abb);
        emit Event_5db9ee0a(address(msg.sender));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        if (address(msg.sender) < 0x10) {
            if (0x29 < var_h.length) {
                if (0x29) {
                }
            }
        }
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = address(arg1);
        return !(!bytes1(storage_map_b[var_a]));
    }
    
    /// @custom:selector    0xcb87e909
    /// @custom:signature   Unresolved_cb87e909(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_cb87e909(uint256 arg0, uint256 arg1) public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        var_a = arg0;
        require(!storage_map_b[var_a], CustomError_818ec7b5());
        var_a = arg1;
        require(address(storage_map_b[var_a]), CustomError_056d5007());
        var_a = arg0;
        storage_map_b[var_a] = arg1;
        emit Event_2167d217(arg0, arg1);
        store_l = 0x01;
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_h.length);
        require(0x29);
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   revokeRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function revokeRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "Strings: hex length insufficient");
        var_a = address(arg1);
        require(!(bytes1(storage_map_b[var_a])), "Strings: hex length insufficient");
        var_a = address(arg1);
        storage_map_b[var_a] = uint248(storage_map_b[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_e = var_e + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_e.length);
        require(0x29);
    }
    
    /// @custom:selector    0xe93a7323
    /// @custom:signature   setReVoteWindowBounds(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function setReVoteWindowBounds(uint256 arg0, uint256 arg1) public {
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_1e3fe615());
        require(!(arg0 < 0x0e10), CustomError_1e3fe615());
        require(!(arg1 > 0x0d2f00), CustomError_1e3fe615());
        require(!(arg0 > arg1), CustomError_1e3fe615());
        minReVoteWindow = arg0;
        maxReVoteWindow = arg1;
        emit ReVoteWindowBoundsUpdated(arg0, arg1);
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_i = var_i + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_i.length);
        require(0x29);
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   grantRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function grantRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "Strings: hex length insufficient");
        var_a = address(arg1);
        require(bytes1(storage_map_b[var_a]), "Strings: hex length insufficient");
        var_a = address(arg1);
        storage_map_b[var_a] = 0x01 | (uint248(storage_map_b[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_e = var_e + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_e.length);
        require(0x29);
    }
    
    /// @custom:selector    0x379ba0ca
    /// @custom:signature   Unresolved_379ba0ca(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_379ba0ca(uint256 arg0) public view returns (bytes memory) {
        uint256 var_f = arg0;
        var_a = var_a + 0x80;
        return abi.encodePacked(address(var_a.length), address(var_s), var_t, var_u);
    }
    
    /// @custom:selector    0x1d96d782
    /// @custom:signature   withdrawRewardPool(bytes32 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function withdrawRewardPool(bytes32 arg0) public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        var_a = arg0;
        require(0 - (storage_map_s[var_a]), CustomError_6e764988());
        require(!(address(storage_map_t[var_a])), CustomError_6e764988());
        require(!(bytes1(storage_map_u[var_a] / 0x0100)), CustomError_6e764988());
        require(bytes1(storage_map_u[var_a]), "Address: insufficient balance for call");
        require(!(bytes1(storage_map_v[var_a]) > 0x05), "Address: insufficient balance for call");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(bytes1(storage_map_v[var_a])) == 0x05), "Address: insufficient balance for call");
        require(!(!(bytes1(storage_map_v[var_a])) == 0x05), "Address: insufficient balance for call");
        require(0 - (storage_map_w[var_a]), "Address: insufficient balance for call");
        storage_map_w[var_a] = 0;
        uint256 var_c = ((0x64 + var_h) - var_h) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        var_h = 0x40 + var_h;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        var_n = 0x20;
        (bool success, bytes memory ret0) = address(storage_map_x[var_a]).{ value: storage_map_w[var_a] ether }Unresolved_08c379a0(var_n); // call
        require(ret0.length == 0);
        require(!var_r);
        require(0 - var_r, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_r, "SafeERC20: ERC20 operation did not succeed");
        require(!(((0x80 + var_r) - 0x80) < 0x20), "SafeERC20: ERC20 operation did not succeed");
        require(var_c == var_c, "SafeERC20: ERC20 operation did not succeed");
        require(var_c, "SafeERC20: ERC20 operation did not succeed");
        emit RewardWithdrawn(arg0, storage_map_w[var_a]);
        store_l = 0x01;
        require(address(storage_map_x[var_a]).code.length, "Address: call to non-contract");
        var_h = var_h + (uint248(ret0.length + 0x3f));
        require(!var_h.length);
        require(0 - var_h.length, "Address: call to non-contract");
        require(address(storage_map_x[var_a]).code.length, "Address: call to non-contract");
        require(0 == var_h.length, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_h.length, "SafeERC20: ERC20 operation did not succeed");
        emit RewardWithdrawn(arg0, storage_map_w[var_a]);
        store_l = 0x01;
        if (!(storage_map_y[var_a]) > 0x05) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(bytes1(storage_map_y[var_a]) > 0x05), CustomError_6e764988());
        }
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_h.length);
        require(0x29);
    }
    
    /// @custom:selector    0xc9b36728
    /// @custom:signature   configureQuestionDeadline(bytes32 arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function configureQuestionDeadline(bytes32 arg0, uint256 arg1, uint256 arg2) public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        require(arg1 < 0x0e10, CustomError_1e3fe615());
        require(!(arg1 > 0x0d2f00), CustomError_1e3fe615());
        require(arg2 < minReVoteWindow, CustomError_1e3fe615());
        require(!(arg2 < minReVoteWindow), CustomError_1e3fe615());
        var_a = arg0;
        require(!(storage_map_z[var_a]), CustomError_a5eea3ed());
        uint256 var_g = var_g + 0x60;
        var_a = arg0;
        storage_map_b[var_a] = var_g.length;
        storage_map_d[var_a] = var_j;
        storage_map_g[var_a] = (var_k) | (uint248(storage_map_g[var_a]));
        emit QuestionDeadlineConfigured(arg0, arg1, arg2);
        store_l = 0x01;
        require(!(arg1 < 0x0e10), CustomError_1e3fe615());
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_g = var_g + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_g.length);
        require(0x29);
    }
    
    /// @custom:selector    0x3c1dd612
    /// @custom:signature   Unresolved_3c1dd612(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_3c1dd612(uint256 arg0, uint256 arg1) public {
        require(arg1 < 0x02);
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        uint256 var_e = arg0;
        require(0 - (storage_map_aa[var_e]), CustomError_582ea80a());
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_582ea80a());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_e]) == 0, CustomError_582ea80a());
        require(bytes1(storage_map_ab[var_e]) < 0x06, CustomError_582ea80a());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(block.timestamp < (storage_map_ac[var_e]), "Address: insufficient balance for call");
        require(0 - (storage_map_ad[var_e]), "Address: insufficient balance for call");
        storage_map_ab[var_e] = 0x01 | (uint248(storage_map_ab[var_e]));
        require(!(arg1 > 0x01), "Address: insufficient balance for call");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_ab[var_e] = (arg1 * 0x0100) | (0x01 | (uint240(storage_map_ab[var_e])));
        storage_map_ae[var_e] = msg.sender | (uint96(storage_map_ae[var_e]));
        storage_map_af[var_e] = storage_map_ag[var_e];
        var_e = arg0;
        require(!(bytes1(storage_map_ah[var_e])), "Address: insufficient balance for call");
        require(!(block.timestamp > (storage_map_ai[var_e] + block.timestamp)), "Address: insufficient balance for call");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_aj[var_e] = (storage_map_ai[var_e]) + block.timestamp;
        require(arg1 < 0x02, "Address: insufficient balance for call");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        emit DisputeFiled(arg0, msg.sender, storage_map_ag[var_e], arg1, (storage_map_ai[var_e]) + block.timestamp);
        var_a = ((0x84 + var_k) - var_k) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        var_k = 0x40 + var_k;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        var_p = 0x20;
        uint256 var_s = 0;
        (bool success, bytes memory ret0) = address(storage_map_ak[var_e]).{ value: var_s ether }Unresolved_08c379a0(var_p); // call
        require(ret0.length == 0);
        require(!var_t);
        require(0 - var_t, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_t, "SafeERC20: ERC20 operation did not succeed");
        require(!(((0x80 + var_t) - 0x80) < 0x20), "SafeERC20: ERC20 operation did not succeed");
        require(var_a == var_a, "SafeERC20: ERC20 operation did not succeed");
        require(var_a, "SafeERC20: ERC20 operation did not succeed");
        store_l = 0x01;
        require(address(storage_map_ak[var_e]).code.length, "Address: call to non-contract");
        var_k = var_k + (uint248(ret0.length + 0x3f));
        require(!var_k.length);
        require(0 - var_k.length, "Address: call to non-contract");
        require(address(storage_map_ak[var_e]).code.length, "Address: call to non-contract");
        require(0 == var_k.length, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_k.length, "SafeERC20: ERC20 operation did not succeed");
        store_l = 0x01;
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        uint256 var_a = arg0;
        return storage_map_h[var_a];
    }
    
    /// @custom:selector    0xe920f0b2
    /// @custom:signature   categories(bytes32 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function categories(bytes32 arg0) public view returns (bytes memory) {
        uint256 var_b = arg0;
        return abi.encodePacked(address(storage_map_j[var_b]), address(storage_map_am[var_b]), storage_map_an[var_b], storage_map_ao[var_b]);
    }
    
    /// @custom:selector    0x7d197102
    /// @custom:signature   isFinalizable(bytes32 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function isFinalizable(bytes32 arg0) public view returns (bool) {
        uint256 var_a = arg0;
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) == 0x05);
        require(!(bytes1(storage_map_y[var_a])) == 0x05);
        return 0;
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) - 0);
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) - 0x01);
        return 0;
        return 0x01;
        return !(!block.timestamp > (storage_map_ap[var_a]));
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
    }
    
    /// @custom:selector    0x152edab4
    /// @custom:signature   getActiveQuestionIdsPaginated(uint256 arg0, uint256 arg1) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function getActiveQuestionIdsPaginated(uint256 arg0, uint256 arg1) public view returns (bytes memory) {
        if (arg0 < store_e) {
            if (!(store_e - arg0) > store_e) {
                require(arg0 < store_e);
                require(!(store_e - arg0) > store_e);
                require(arg1 > (store_e - arg0));
                uint256 var_d = var_d + (0x20 + (0x20 * (store_e - arg0)));
                require(!(store_e - arg0) > 0xffffffffffffffff);
                require(!store_e - arg0);
                require(!0 < (store_e - arg0));
                require(!arg0 > (0 + arg0));
                var_a = 0x0162;
                require((0 + arg0) < store_e);
                return abi.encodePacked(0x20, var_d.length);
                require(0x01);
            }
        }
    }
    
    /// @custom:selector    0xa04a8bdc
    /// @custom:signature   Unresolved_a04a8bdc(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a04a8bdc(uint256 arg0, address arg1) public view {
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_f913ac12());
        require(arg0, CustomError_f913ac12());
        var_a = arg0;
        require(!(address(storage_map_b[var_a])), CustomError_f913ac12());
        require(!0x20 < 0x20);
        require(arg1 == (address(arg1)));
        require(address(arg1) - 0);
        require(!0x20 < 0x20);
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_f = var_f + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_f.length);
        require(0x29);
    }
    
    /// @custom:selector    0xb341ab82
    /// @custom:signature   depositRewardPool(bytes32 arg0, address arg1, uint256 arg2) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function depositRewardPool(bytes32 arg0, address arg1, uint256 arg2) public {
        require(arg1 == (address(arg1)));
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        require(0 - arg2, CustomError_582ea80a());
        require(address(arg1), CustomError_582ea80a());
        var_a = arg0;
        require(0 - (storage_map_s[var_a]), CustomError_582ea80a());
        require(!(bytes1(storage_map_y[var_a]) > 0x05), CustomError_582ea80a());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) == 0, CustomError_582ea80a());
        require(bytes1(storage_map_y[var_a]) < 0x06, CustomError_582ea80a());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_w[var_a]), CustomError_fb8962fb());
        var_a = arg0;
        require(!(bytes1(storage_map_g[var_a])), "Address: insufficient balance for call");
        require(!(block.timestamp > (storage_map_b[var_a] + block.timestamp)), "Address: insufficient balance for call");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_ar[var_a] = storage_map_b[var_a] + block.timestamp;
        storage_map_x[var_a] = (address(arg1)) | (uint96(storage_map_x[var_a]));
        storage_map_w[var_a] = arg2;
        emit RewardDeposited(arg0, address(arg1), arg2);
        var_c = ((0x84 + var_i) - var_i) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        var_i = 0x40 + var_i;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        var_o = 0x20;
        uint256 var_r = 0;
        (bool success, bytes memory ret0) = address(arg1).{ value: var_r ether }Unresolved_08c379a0(var_o); // call
        require(ret0.length == 0);
        require(!var_s);
        require(0 - var_s, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_s, "SafeERC20: ERC20 operation did not succeed");
        require(!(((0x80 + var_s) - 0x80) < 0x20), "SafeERC20: ERC20 operation did not succeed");
        require(var_c == var_c, "SafeERC20: ERC20 operation did not succeed");
        require(var_c, "SafeERC20: ERC20 operation did not succeed");
        store_l = 0x01;
        require(address(arg1).code.length, "Address: call to non-contract");
        var_i = var_i + (uint248(ret0.length + 0x3f));
        require(!var_i.length);
        require(0 - var_i.length, "Address: call to non-contract");
        require(address(arg1).code.length, "Address: call to non-contract");
        require(0 == var_i.length, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_i.length, "SafeERC20: ERC20 operation did not succeed");
        store_l = 0x01;
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_i = var_i + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_i.length);
        require(0x29);
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1 > 0xffffffffffffffff), "Function must be called through delegatecall");
        require(!(((var_c + (uint248(0x3f + (arg1 + 0x1f)))) < var_c) | ((var_c + (uint248(0x3f + (arg1 + 0x1f)))) > 0xffffffffffffffff)), "Function must be called through delegatecall");
        require(address(this) - 0xe0f9f92a20402611f95b68352a7783f430060c5c, "Function must be called through delegatecall");
        require(address(treasurys) == 0xe0f9f92a20402611f95b68352a7783f430060c5c, "ERC1967: new implementation is not a contract");
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ERC1967: new implementation is not a contract");
        require(!(bytes1(treasuryt)), "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_g = 0x20;
        treasurys = (address(arg0)) | (uint96(treasurys));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        require(0x01 == var_a, "ERC1967: new implementation is not a contract");
        require(address(0x0dbf).code.length, "ERC1967: new implementation is not a contract");
        treasurys = 0x0dbf | (uint96(treasurys));
        emit Event_bc7cd75a(0x0dbf);
        require(var_l > 0);
        require(!var_l > 0);
        var_c = 0x60 + var_c;
        require(!0 < var_l);
        (bool success, bytes memory ret0) = address(0x0dbf).Unresolved_(var_o); // delegatecall
        require(ret0.length == 0);
        require(!var_p);
        require(0 - var_p, "Address: call to non-contract");
        require(address(0x0dbf).code.length, "Address: call to non-contract");
        var_c = var_c + (uint248(ret0.length + 0x3f));
        require(!var_c.length);
        require(0 - var_c.length, "Address: call to non-contract");
        require(address(0x0dbf).code.length, "Address: call to non-contract");
        require(!var_c, "ERC1967Upgrade: unsupported proxiableUUID");
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), "ERC1967Upgrade: new implementation is not UUPS");
        require(0x01, "ERC1967Upgrade: new implementation is not UUPS");
        var_a = var_a;
        require(var_c.length == var_a, "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        treasurys = (address(arg0)) | (uint96(treasurys));
        emit Event_bc7cd75a(address(arg0));
        require(var_c.length > 0, "ERC1967Upgrade: unsupported proxiableUUID");
        require(!(var_c.length > 0), "ERC1967Upgrade: unsupported proxiableUUID");
        require(!0x01, "ERC1967Upgrade: unsupported proxiableUUID");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_c = var_c + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10, "Function must be called through active proxy");
        require(0x29 < var_c.length, "Function must be called through active proxy");
        require(0x29, "Function must be called through active proxy");
    }
    
    /// @custom:selector    0x3659cfe6
    /// @custom:signature   upgradeTo(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function upgradeTo(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(this) - 0xe0f9f92a20402611f95b68352a7783f430060c5c, "Function must be called through delegatecall");
        require(address(treasuryu) == 0xe0f9f92a20402611f95b68352a7783f430060c5c, "ERC1967: new implementation is not a contract");
        var_f = address(msg.sender);
        require(bytes1(storage_map_o[var_f]), "ERC1967: new implementation is not a contract");
        require(!(bytes1(treasuryt)), "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_c = 0x20;
        treasuryu = (address(arg0)) | (uint96(treasuryu));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_c); // staticcall
        var_f = var_f;
        require(0 == var_f, "ERC1967: new implementation is not a contract");
        require(address(0x1383).code.length, "ERC1967: new implementation is not a contract");
        treasuryu = 0x1383 | (uint96(treasuryu));
        emit Event_bc7cd75a(0x1383);
        require(var_k > 0);
        require(!var_k > 0);
        var_h = 0x60 + var_h;
        require(!0 < var_k);
        (bool success, bytes memory ret0) = address(0x1383).Unresolved_(var_n); // delegatecall
        require(ret0.length == 0);
        require(!var_o);
        require(0 - var_o, "Address: call to non-contract");
        require(address(0x1383).code.length, "Address: call to non-contract");
        var_h = var_h + (uint248(ret0.length + 0x3f));
        require(!var_h.length);
        require(0 - var_h.length, "Address: call to non-contract");
        require(address(0x1383).code.length, "Address: call to non-contract");
        require(!var_h, "ERC1967Upgrade: unsupported proxiableUUID");
        var_h = var_h + (uint248(ret0.length + 0x1f));
        require(!(((var_h + ret0.length) - var_h) < 0x20), "ERC1967Upgrade: new implementation is not UUPS");
        require(0x01, "ERC1967Upgrade: new implementation is not UUPS");
        var_f = var_f;
        require(var_h.length == var_f, "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        treasuryu = (address(arg0)) | (uint96(treasuryu));
        emit Event_bc7cd75a(address(arg0));
        require(var_h.length > 0, "ERC1967Upgrade: unsupported proxiableUUID");
        require(!(var_h.length > 0), "ERC1967Upgrade: unsupported proxiableUUID");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10, "Function must be called through active proxy");
        require(0x29 < var_h.length, "Function must be called through active proxy");
        require(0x29, "Function must be called through active proxy");
    }
    
    /// @custom:selector    0xd557dba1
    /// @custom:signature   Unresolved_d557dba1(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_d557dba1(uint256 arg0, uint256 arg1) public {
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_1e3fe615());
        require(arg1 < 0x0e10, CustomError_1e3fe615());
        require(!(arg1 > 0x0d2f00), CustomError_1e3fe615());
        var_a = arg0;
        require(address(storage_map_b[var_a]), CustomError_056d5007());
        storage_map_g[var_a] = arg1;
        emit Event_3e273fdb(arg0, storage_map_g[var_a], arg1);
        require(!(arg1 < 0x0e10), CustomError_1e3fe615());
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_i = var_i + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_i.length);
        require(0x29);
    }
    
    /// @custom:selector    0x199543b7
    /// @custom:signature   Unresolved_199543b7(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_199543b7(uint256 arg0, uint256 arg1) public {
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_1e3fe615());
        require(arg1 < minReVoteWindow, CustomError_1e3fe615());
        require(!(arg1 < minReVoteWindow), CustomError_1e3fe615());
        var_a = arg0;
        require(address(storage_map_b[var_a]), CustomError_056d5007());
        storage_map_av[var_a] = arg1;
        emit Event_31237182(arg0, storage_map_av[var_a], arg1);
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_i = var_i + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_i.length);
        require(0x29);
    }
    
    /// @custom:selector    0x01f78976
    /// @custom:signature   isDisputable(bytes32 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function isDisputable(bytes32 arg0) public view returns (bool) {
        uint256 var_a = arg0;
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_y[var_a])) == 0);
        require(!(bytes1(storage_map_y[var_a])) == 0);
        return !(!(bytes1(storage_map_y[var_a])) == 0);
        return !(!(storage_map_aw[var_a]) > 0);
        require(!block.timestamp < (storage_map_ap[var_a]));
        return !(!(storage_map_aw[var_a]) > 0);
        return !(!block.timestamp < (storage_map_ap[var_a]));
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
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   renounceRole(bytes32 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function renounceRole(bytes32 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        require(msg.sender == (address(arg1)), "AccessControl: can only renounce roles for self");
        var_f = address(arg1);
        require(!bytes1(storage_map_o[var_f]));
        var_f = address(arg1);
        storage_map_o[var_f] = uint248(storage_map_o[var_f]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0xb05dc775
    /// @custom:signature   isDisputeTimedOut(bytes32 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function isDisputeTimedOut(bytes32 arg0) public view returns (bool) {
        uint256 var_a = arg0;
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_y[var_a])) == 0x01);
        return !(!block.timestamp > (storage_map_ax[var_a]));
        return !(!(bytes1(storage_map_y[var_a])) == 0x01);
    }
    
    /// @custom:selector    0x03e8d652
    /// @custom:signature   getResolution(bytes32 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getResolution(bytes32 arg0) public view returns (bool) {
        var_a = 0x40 + var_a;
        var_a = 0x40 + var_a;
        uint256 var_q = arg0;
        var_a = 0x40 + var_a;
        if ((0x40 + var_a) > (0x20 + var_a)) {
            var_a = 0x40 + var_a;
            if ((0x40 + var_a) > (0x20 + var_a)) {
                require((0x40 + var_a) > (0x20 + var_a));
                require((0x40 + var_a) > (0x20 + var_a));
                var_q = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(bytes1(storage_map_bb[var_q])) > 0x05);
                var_q = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(bytes1(storage_map_bb[var_q])) > 0x05);
                var_q = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(bytes1(storage_map_bc[var_q] / 0x0100)) > 0x01);
                require(!(bytes1(storage_map_bc[var_q] / 0x0100)) > 0x01);
                require(!0 < 0x02);
                require(!0 < 0x02);
                var_q = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                return abi.encodePacked(var_a.length, var_bg, var_bh, var_bi, var_bj, var_bk, address(var_bl), address(var_bm), var_bn, var_bo, !(!var_bp), (var_bq));
                require(var_al < 0x06);
            }
            require(var_an < 0x02);
        }
    }
    
    /// @custom:selector    0xf0f44260
    /// @custom:signature   setTreasury(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setTreasury(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_d92e233d());
        require(address(arg0), CustomError_d92e233d());
        treasury = (address(arg0)) | (uint96(treasury));
        emit TreasuryUpdated(address(treasury), address(arg0));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_e = var_e + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_e.length);
        require(0x29);
    }
    
    /// @custom:selector    0xb388b7e7
    /// @custom:signature   Unresolved_b388b7e7(uint256 arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_b388b7e7(uint256 arg0, uint256 arg1, uint256 arg2) public {
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        require(arg1 == 0x02, CustomError_fff7d58e());
        require(0 < (arg1), CustomError_fff7d58e());
        require(!(0 == (0 + (arg1 + 0x20))), CustomError_fff7d58e());
        require(!(0 == (0 + (arg1 + 0x20))), CustomError_fff7d58e());
        uint256 var_e = arg0;
        require(storage_map_f[var_e], CustomError_fff7d58e());
        var_e = arg0;
        require(0 - (storage_map_aa[var_e]), CustomError_fff7d58e());
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_fff7d58e());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_e]) - 0x01, CustomError_fff7d58e());
        require(msg.sender == (address(storage_map_ai[var_e])), CustomError_fff7d58e());
        var_e = arg0;
        require(block.timestamp < (storage_map_aj[var_e]), CustomError_0be484b5());
        require(arg1, CustomError_0be484b5());
        require(!((0 + (arg1 + 0x20)) == (storage_map_ai[var_e])), CustomError_0be484b5());
        require(!(!(0 + (arg1 + 0x20)) == (storage_map_ai[var_e])), CustomError_0be484b5());
        storage_map_ab[var_e] = 0x03 | (uint248(storage_map_ab[var_e]));
        storage_map_bn[var_e] = (uint248(storage_map_bn[var_e])) | 0x0100;
        require(arg1, CustomError_0be484b5());
        require(0 < 0x02, CustomError_0be484b5());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_bo[0x03 + keccak256(var_e)] = (0 + (arg1 + 0x20));
        require(0x01 < (arg1), CustomError_0be484b5());
        require(0x01 < 0x02, CustomError_0be484b5());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_bp[0x03 + keccak256(var_e)] = (0x20 + (arg1 + 0x20));
        require(!(0 < 0x02), CustomError_0be484b5());
        emit DisputeResolved(arg0, (!(0 + (arg1 + 0x20)) == (storage_map_ai[var_e])));
        var_e = arg0;
        require(0 - (storage_map_aa[var_e]), CustomError_0be484b5());
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_0be484b5());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_e]) - 0x04, CustomError_0be484b5());
        require(!(bytes1(storage_map_bq[var_e]) > 0x05), CustomError_582ea80a());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_bq[var_e]) - 0x05, CustomError_582ea80a());
        require(bytes1(storage_map_ab[var_e]) < 0x06, CustomError_582ea80a());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_870b9b0d());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_e]) - 0, CustomError_870b9b0d());
        require(!(block.timestamp < (storage_map_ac[var_e])), CustomError_870b9b0d());
        storage_map_bq[var_e] = 0x05 | (uint248(storage_map_bq[var_e]));
        var_e = arg0;
        require(!storage_map_f[var_e]);
        require(!(storage_map_f[var_e] - 0x01) > storage_map_f[var_e]);
        require(!(store_e - 0x01) > store_e);
        require((storage_map_f[var_e] - 0x01) == (store_e - 0x01));
        require((store_e - 0x01) < store_e);
        var_e = 0x0162;
        require((storage_map_f[var_e] - 0x01) < store_e);
        var_e = 0x0162;
        storage_map_br[storage_map_f[var_e] - 0x01] = storage_map_bs[var_e];
        var_e = storage_map_bs[var_e];
        storage_map_f[var_e] = storage_map_f[var_e];
        require(store_e);
        var_e = 0x0162;
        storage_map_bt[store_e + keccak256(var_e)] = 0;
        store_e = store_e + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        var_e = arg0;
        storage_map_f[var_e] = 0;
        uint256 var_h = var_h + 0x60;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_m = arg0;
        require(address(oracleProxy).code.length);
        (bool success, bytes memory ret0) = address(oracleProxy).{ value: storage_map_bt[store_e + keccak256(var_e)] ether }Unresolved_b388b7e7(var_m); // call
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        if (!(storage_map_ab[var_e]) > 0x05) {
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_20b2e2ae());
        }
        require(0x01 < (arg1), CustomError_d5d201a0());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_fff7d58e());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_e]) - 0x04, CustomError_fff7d58e());
        require(msg.sender == (address(storage_map_ai[var_e])), CustomError_fff7d58e());
        require(0 < (arg1), CustomError_9564d15d());
        require(0 < 0x02, CustomError_9564d15d());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_bo[0x03 + keccak256(var_e)] = (0 + (arg1 + 0x20));
        require(0x01 < (arg1), CustomError_9564d15d());
        require(0x01 < 0x02, CustomError_9564d15d());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_bp[0x03 + keccak256(var_e)] = (0x20 + (arg1 + 0x20));
        storage_map_bq[var_e] = 0x05 | (uint248(storage_map_bq[var_e]));
        require(0 < (arg1), CustomError_9564d15d());
        require(0x01 < (arg1), CustomError_9564d15d());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(msg.sender == (address(storage_map_f[var_e])), CustomError_9564d15d());
        require(!(!msg.sender == (address(storage_map_ai[var_e]))), CustomError_9564d15d());
        var_e = arg0;
        storage_map_f[var_e] = arg0;
        if (arg1) {
            require(arg1, CustomError_6aa92783());
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            storage_map_bw[0x01 + keccak256(var_e)] = (0 + (arg1 + 0x20));
            require(0 < 0x02, CustomError_6aa92783());
            require(0x01 < (arg1), CustomError_6aa92783());
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            storage_map_bx[0x01 + keccak256(var_e)] = (0x20 + (arg1 + 0x20));
            require(0x01 < 0x02, CustomError_6aa92783());
            require(arg1, CustomError_6aa92783());
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            storage_map_bo[0x03 + keccak256(var_e)] = (0 + (arg1 + 0x20));
            require(0 < 0x02, CustomError_6aa92783());
            require(0x01 < (arg1), CustomError_6aa92783());
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            storage_map_bp[0x03 + keccak256(var_e)] = (0x20 + (arg1 + 0x20));
            storage_map_ab[var_e] = uint248(storage_map_ab[var_e]);
            storage_map_aa[var_e] = block.timestamp;
            storage_map_al[var_e] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            require(0x01 < 0x02, CustomError_6aa92783());
        }
        require(0x01 < (arg1), CustomError_663493a0());
    }
    
    /// @custom:selector    0xbd66528a
    /// @custom:signature   claim(bytes32 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function claim(bytes32 arg0) public {
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        uint256 var_e = arg0;
        require(0 - (storage_map_aa[var_e]), CustomError_c8426484());
        require(address(storage_map_ae[var_e]), CustomError_c8426484());
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_c8426484());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(bytes1(storage_map_ab[var_e])) == 0x02), CustomError_c8426484());
        require(!(!(bytes1(storage_map_ab[var_e])) == 0x02), CustomError_c8426484());
        require(!(!(bytes1(storage_map_ab[var_e])) == 0x02), CustomError_c8426484());
        require(!(!(bytes1(storage_map_ab[var_e])) == 0x02), CustomError_c8426484());
        require(!(bytes1(storage_map_bn[var_e])), CustomError_c8426484());
        storage_map_bn[var_e] = 0x01 | (uint248(storage_map_bn[var_e]));
        require(!(bytes1((0x01 | (uint248(storage_map_bn[var_e]))) / 0x0100)), CustomError_3524bb27());
        require(msg.sender == (address(storage_map_ae[var_e])), CustomError_3524bb27());
        require(!(storage_map_by[var_e] > (storage_map_ad[var_e] + (storage_map_by[var_e]))), "Address: insufficient balance for call");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_ag[var_e] = 0;
        storage_map_af[var_e] = 0;
        uint256 var_a = ((0x64 + var_h) - var_h) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        var_h = 0x40 + var_h;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        var_n = 0x20;
        (bool success, bytes memory ret0) = address(storage_map_ak[var_e]).{ value: storage_map_ag[var_e] ether }Unresolved_08c379a0(var_n); // call
        require(ret0.length == 0);
        require(!var_r);
        require(0 - var_r, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_r, "SafeERC20: ERC20 operation did not succeed");
        require(!(((0x80 + var_r) - 0x80) < 0x20), "SafeERC20: ERC20 operation did not succeed");
        require(var_a == var_a, "SafeERC20: ERC20 operation did not succeed");
        require(var_a, "SafeERC20: ERC20 operation did not succeed");
        emit StakeClaimed(arg0, address(storage_map_ae[var_e]), (storage_map_ad[var_e]) + (storage_map_by[var_e]));
        store_l = 0x01;
        require(address(storage_map_ak[var_e]).code.length, "Address: call to non-contract");
        var_h = var_h + (uint248(ret0.length + 0x3f));
        require(!var_h.length);
        require(0 - var_h.length, "Address: call to non-contract");
        require(address(storage_map_ak[var_e]).code.length, "Address: call to non-contract");
        require(0 == var_h.length, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_h.length, "SafeERC20: ERC20 operation did not succeed");
        emit StakeClaimed(arg0, address(storage_map_ae[var_e]), (storage_map_ad[var_e]) + (storage_map_by[var_e]));
        store_l = 0x01;
        storage_map_af[var_e] = 0;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        require(bytes1(storage_map_ab[var_e]) < 0x06, CustomError_582ea80a());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_bq[var_e]) > 0x05), CustomError_20b2e2ae());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_20b2e2ae());
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_ab[var_e]) > 0x05), CustomError_20b2e2ae());
    }
    
    /// @custom:selector    0x400c3d96
    /// @custom:signature   Unresolved_400c3d96(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_400c3d96(uint256 arg0) public view returns (uint256) {
        uint256 var_a = arg0;
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x0c103479
    /// @custom:signature   timeoutDispute(bytes32 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function timeoutDispute(bytes32 arg0) public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        var_a = arg0;
        require(0 - (storage_map_s[var_a]), CustomError_f6f8f9df());
        require(!(bytes1(storage_map_y[var_a]) > 0x05), CustomError_f6f8f9df());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) == 0x01, CustomError_f6f8f9df());
        require(!(block.timestamp < (storage_map_ax[var_a])), CustomError_f6f8f9df());
        storage_map_y[var_a] = 0x04 | (uint248(storage_map_y[var_a]));
        storage_map_u[var_a] = (uint248(storage_map_u[var_a])) | 0x0100;
        var_a = arg0;
        require(!storage_map_b[var_a], CustomError_582ea80a());
        require(!((storage_map_b[var_a] - 0x01) > storage_map_b[var_a]), CustomError_582ea80a());
        require(!((store_e - 0x01) > store_e), CustomError_582ea80a());
        require((storage_map_b[var_a] - 0x01) == (store_e - 0x01), CustomError_582ea80a());
        require((store_e - 0x01) < store_e, CustomError_582ea80a());
        var_a = 0x0162;
        require((storage_map_b[var_a] - 0x01) < store_e, CustomError_582ea80a());
        var_a = 0x0162;
        storage_map_ca[storage_map_b[var_a] - 0x01] = storage_map_cb[var_a];
        var_a = storage_map_cb[var_a];
        storage_map_b[var_a] = storage_map_b[var_a];
        require(store_e, CustomError_582ea80a());
        var_a = 0x0162;
        storage_map_cc[store_e + keccak256(var_a)] = 0;
        store_e = store_e + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        var_a = arg0;
        storage_map_b[var_a] = 0;
        emit DisputeTimedOut(arg0);
        store_l = 0x01;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        emit DisputeTimedOut(arg0);
        store_l = 0x01;
        require(bytes1(storage_map_y[var_a]) < 0x06, CustomError_582ea80a());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_h.length);
        require(0x29);
    }
    
    /// @custom:selector    0x92584d80
    /// @custom:signature   finalize(bytes32 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function finalize(bytes32 arg0) public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "ReentrancyGuard: reentrant call");
        require(store_l - 0x02, "ReentrancyGuard: reentrant call");
        store_l = 0x02;
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        var_a = arg0;
        require(0 - (storage_map_s[var_a]), CustomError_0be484b5());
        require(!(bytes1(storage_map_y[var_a]) > 0x05), CustomError_0be484b5());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) - 0x04, CustomError_0be484b5());
        require(!(bytes1(storage_map_v[var_a]) > 0x05), CustomError_582ea80a());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_v[var_a]) - 0x05, CustomError_582ea80a());
        require(bytes1(storage_map_y[var_a]) < 0x06, CustomError_582ea80a());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) - 0);
        require(!(bytes1(storage_map_y[var_a])) > 0x05);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_a]) - 0x01);
        storage_map_v[var_a] = 0x05 | (uint248(storage_map_v[var_a]));
        var_a = arg0;
        require(!storage_map_b[var_a]);
        require(!(storage_map_b[var_a] - 0x01) > storage_map_b[var_a]);
        require(!(store_e - 0x01) > store_e);
        require((storage_map_b[var_a] - 0x01) == (store_e - 0x01));
        require((store_e - 0x01) < store_e);
        var_a = 0x0162;
        require((storage_map_b[var_a] - 0x01) < store_e);
        var_a = 0x0162;
        storage_map_ca[storage_map_b[var_a] - 0x01] = storage_map_cb[var_a];
        var_a = storage_map_cb[var_a];
        storage_map_b[var_a] = storage_map_b[var_a];
        require(store_e);
        var_a = 0x0162;
        storage_map_cc[store_e + keccak256(var_a)] = 0;
        store_e = store_e + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        var_a = arg0;
        storage_map_b[var_a] = 0;
        uint256 var_h = var_h + 0x60;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_m = arg0;
        require(address(oracleProxy).code.length);
        (bool success, bytes memory ret0) = address(oracleProxy).{ value: storage_map_b[var_a] ether }Unresolved_b388b7e7(var_m); // call
        require(!(0 < 0x02), CustomError_870b9b0d());
        emit ResolutionFinalized(arg0, 0xb388b7e700000000000000000000000000000000000000000000000000000000);
        store_l = 0x01;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp < (storage_map_ap[var_a])), CustomError_870b9b0d());
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        require(bytes1(address(msg.sender)) < 0x10);
        require(0x29 < var_h.length);
        require(0x29);
    }
    
    /// @custom:selector    0x1b72bfbd
    /// @custom:signature   getRequiredStake(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRequiredStake(bytes32 arg0) public view returns (uint256) {
        uint256 var_a = arg0;
        return storage_map_aw[var_a];
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public
    function Unresolved_8456cb59() public {
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), "Pausable: paused");
        require(!(bytes1(unresolved_5c975abb)), "Pausable: paused");
        unresolved_5c975abb = 0x01 | (uint248(unresolved_5c975abb));
        emit Event_62e78cea(address(msg.sender));
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x02 > 0x2a), "Strings: hex length insufficient");
        require(!(0x2a > 0xffffffffffffffff), "Strings: hex length insufficient");
        uint256 var_h = var_h + 0x60;
        require(!0x2a, "Strings: hex length insufficient");
        require((0x14 == 0x14) | !0x02, "Strings: hex length insufficient");
        require(!(0x01 > 0x29), "Strings: hex length insufficient");
        require(!(0x29 > 0x01), "Strings: hex length insufficient");
        require(!(address(msg.sender)), "Strings: hex length insufficient");
        if (address(msg.sender) < 0x10) {
            if (0x29 < var_h.length) {
                if (0x29) {
                }
            }
        }
    }
}