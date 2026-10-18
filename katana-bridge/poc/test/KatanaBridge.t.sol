// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IVaultToken is IERC20Min {
    function totalAssets() external view returns (uint256);
    function asset() external view returns (address);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function reinitialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        address lxlyBridge_,
        address nativeConverter_
    ) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function version() external view returns (string memory);
    function totalNetMintedByAdditionalMintersBurners() external view returns (uint256);
    function nativeConverter() external view returns (address);
}

interface IOApp {
    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }

    function endpoint() external view returns (address);
    function peers(uint32 eid) external view returns (bytes32);
    function owner() external view returns (address);
    function globalInitializationCounter() external view returns (uint64);
    function secondaryChainBalance() external view returns (uint256);
    function token() external view returns (address);
    function reinitialize(bytes[] calldata data) external;
    function reinitialize1(address token, bool approvalRequired, address owner, address delegate) external;
    function lzReceive(Origin calldata origin, bytes32 guid, bytes calldata message, address executor, bytes calldata extraData)
        external
        payable;
}

interface INativeConverter {
    function backingOnLayerY() external view returns (uint256);
    function underlyingToken() external view returns (address);
    function customToken() external view returns (address);
}

error OnlyEndpoint(address addr);
error OnlyPeer(uint32 eid, bytes32 sender);
error Unauthorized();
error ReinitializersLocked();
error AlreadyReinitialized();
error InvalidInitialization();
error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

contract KatanaBridgeAuthTest is Test {
    // ---------------- Ethereum mainnet ----------------
    address constant L1_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant L1_LXLY_BRIDGE = 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe;

    address constant VBUSDC = 0x53E82ABbb12638F09d9e624578ccB666217a765e;
    address constant VBUSDC_ADAPTER = 0xb5bADA33542a05395d504a25885e02503A957Bb3;
    address constant VBUSDT = 0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC;
    address constant VBUSDT_ADAPTER = 0x839dC0cFF5e263F56C9810560adF8Ea40E95Ab82;
    address constant VBWBTC = 0x2C24B57e2CCd1f273045Af6A5f632504C432374F;
    address constant VBWBTC_ADAPTER = 0x8d09C41229F07AD098ffB5faD239Dd87D2c131D4;
    address constant VBETH = 0x2DC70fb75b88d2eB4715bc06E1595E6D97c34DFF;
    address constant VBETH_ADAPTER = 0x8F45F7ACD4b9FC0B446902790F304d444dfF949b;

    // ---------------- Katana (chain id 747474) ----------------
    address constant L2_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant MINTER = 0x807275727Dd3E640c5F2b5DE7d1eC72B4Dd293C0; // vbUSDC LZ adapter
    address constant L2_VBUSDC = 0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36;
    address constant L2_VBUSDC_CONVERTER = 0x97a3500083348A147F419b8a65717909762c389f;

    address constant L2_VBUSDT = 0x2DCa96907fde857dd3D816880A0df407eeB2D2F2;
    address constant L2_USDT_MINTER = 0x4690f346337eD8737BeA462ac71Ff16Ef95B985E;
    address constant L2_USDT_CONVERTER = 0x053FA9b934b83E1E0ffc7e98a41aAdc3640bB462;

    address constant L2_VBWBTC = 0x0913DA6Da4b42f538B445599b46Bb4622342Cf52;
    address constant L2_WBTC_MINTER = 0x8169e532Bc781985e155037db1F96c267a520DFC;
    address constant L2_WBTC_CONVERTER = 0xb00aa68b87256E2F22058fB2Ba3246EEc54A44fc;

    address constant L2_WETH = 0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62;
    address constant L2_ETH_MINTER = 0x694d1697F6909361775139357d99fb60b5caB683;

    bytes32 constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

    string ETH_RPC;
    string KAT_RPC;

    function setUp() public {
        ETH_RPC = vm.envOr("FORK_RPC_URL", string("https://eth.drpc.org"));
        KAT_RPC = vm.envOr("KATANA_RPC_URL", string("https://rpc.katana.network"));
    }

    // ================= L2 minter (NonDefaultMintBurnOftAdapter) =================

    function test_l2Minter_lzReceive_onlyEndpoint() public {
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        IOApp.Origin memory o = IOApp.Origin(30101, bytes32(uint256(uint160(VBUSDC_ADAPTER))), 1);
        vm.expectRevert(abi.encodeWithSelector(OnlyEndpoint.selector, address(this)));
        m.lzReceive(o, bytes32(0), "", address(0), "");
    }

    function test_l2Minter_lzReceive_onlyPeer() public {
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        address forgedSender = address(0xdeadbeef);
        IOApp.Origin memory o = IOApp.Origin(30101, bytes32(uint256(uint160(forgedSender))), 1);
        vm.prank(L2_ENDPOINT);
        vm.expectRevert(abi.encodeWithSelector(OnlyPeer.selector, uint32(30101), bytes32(uint256(uint160(forgedSender)))));
        m.lzReceive(o, bytes32(uint256(0x1234)), abi.encodePacked(forgedSender, uint256(1_000_000e6)), address(0), "");
    }

    function test_l2Minter_reinitialize_closed() public {
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        bytes[] memory empty = new bytes[](0);
        vm.expectRevert(AlreadyReinitialized.selector);
        m.reinitialize(empty);
    }

    function test_l2Minter_reinitialize1_locked() public {
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        vm.expectRevert(ReinitializersLocked.selector);
        m.reinitialize1(address(this), false, address(this), address(this));
    }

    function test_l2Minter_peerIsL1Adapter() public {
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        assertEq(m.endpoint(), L2_ENDPOINT, "L2 endpoint not canonical LZ EndpointV2");
        assertEq(m.owner(), 0x619D553686958A873A62B336b2DD97C3b25134EA, "owner not expected Safe");
        assertEq(m.globalInitializationCounter(), 1);
        assertEq(m.token(), L2_VBUSDC);
        assertEq(m.peers(30101), bytes32(uint256(uint160(VBUSDC_ADAPTER))), "peer(30101) != L1 adapter");
    }

    function test_l2Minter_onlyLzPeerCanMint() public {
        // Every other EID must have no peer; a peerless EID cannot pass _getPeerOrRevert.
        vm.createSelectFork(KAT_RPC);
        IOApp m = IOApp(MINTER);
        assertEq(m.peers(30375), bytes32(0), "unexpected peer for Katana EID on Katana minter");
        assertEq(m.peers(30110), bytes32(0), "unexpected peer for Arbitrum EID");
        assertEq(m.peers(30184), bytes32(0), "unexpected peer for Base EID");
    }

    // ================= L2 custom token (GenericCustomToken) =================

    function test_l2Token_mint_unauthorized() public {
        vm.createSelectFork(KAT_RPC);
        vm.expectRevert(Unauthorized.selector);
        IVaultToken(L2_VBUSDC).mint(address(this), 1_000_000e6);
    }

    function test_l2Token_burn_unauthorized() public {
        vm.createSelectFork(KAT_RPC);
        vm.expectRevert(Unauthorized.selector);
        IVaultToken(L2_VBUSDC).burn(address(0xdeadbeef), 1);
    }

    function test_l2Token_reinitialize_closed() public {
        vm.createSelectFork(KAT_RPC);
        vm.expectRevert(InvalidInitialization.selector);
        IVaultToken(L2_VBUSDC).reinitialize(address(this), "x", "x", 6, address(this), address(this));
    }

    function test_l2Token_roles() public {
        vm.createSelectFork(KAT_RPC);
        IVaultToken t = IVaultToken(L2_VBUSDC);
        assertTrue(t.hasRole(MINTER_BURNER_ROLE, MINTER), "minter lacks role");
        assertFalse(t.hasRole(MINTER_BURNER_ROLE, address(this)), "attacker has role");
        assertEq(t.version(), "0.5.1");
        IOApp m = IOApp(MINTER);
        assertEq(t.totalNetMintedByAdditionalMintersBurners(), m.secondaryChainBalance(), "accounting mismatch");
    }

    // ================= L1 adapter (NonDefaultOftAdapter, escrow) =================

    function test_l1Adapter_lzReceive_onlyEndpoint() public {
        vm.createSelectFork(ETH_RPC);
        IOApp a = IOApp(VBUSDC_ADAPTER);
        IOApp.Origin memory o = IOApp.Origin(30375, bytes32(uint256(uint160(MINTER))), 1);
        vm.expectRevert(abi.encodeWithSelector(OnlyEndpoint.selector, address(this)));
        a.lzReceive(o, bytes32(0), "", address(0), "");
    }

    function test_l1Adapter_lzReceive_onlyPeer() public {
        vm.createSelectFork(ETH_RPC);
        IOApp a = IOApp(VBUSDC_ADAPTER);
        address forgedSender = address(0xdeadbeef);
        IOApp.Origin memory o = IOApp.Origin(30375, bytes32(uint256(uint160(forgedSender))), 1);
        vm.prank(L1_ENDPOINT);
        vm.expectRevert(abi.encodeWithSelector(OnlyPeer.selector, uint32(30375), bytes32(uint256(uint160(forgedSender)))));
        a.lzReceive(o, bytes32(uint256(0x1234)), abi.encodePacked(forgedSender, uint256(1e6)), address(0), "");
    }

    function test_l1Adapter_peerIsL2Minter() public {
        vm.createSelectFork(ETH_RPC);
        IOApp a = IOApp(VBUSDC_ADAPTER);
        assertEq(a.endpoint(), L1_ENDPOINT, "L1 endpoint not canonical LZ EndpointV2");
        assertEq(a.owner(), 0x619D553686958A873A62B336b2DD97C3b25134EA, "owner not expected Safe");
        assertEq(a.peers(30375), bytes32(uint256(uint160(MINTER))), "peer(30375) != L2 minter");
        assertEq(a.peers(30101), bytes32(0), "unexpected self-EID peer");
    }

    function test_l1Adapter_holdsBacking() public {
        vm.createSelectFork(ETH_RPC);
        uint256 bal = IERC20Min(VBUSDC).balanceOf(VBUSDC_ADAPTER);
        assertGt(bal, 0, "adapter empty");
        // The L2 side reports the same net supply (checked in test_l2Token_roles).
        assertGe(bal, 60_000_000_000, "adapter balance unexpectedly low");
        assertLe(bal, 100_000_000_000, "adapter balance unexpectedly high");
    }

    // ================= L1 vault: no unprivileged withdrawal =================

    function test_l1Vault_redeemWithoutSharesReverts() public {
        vm.createSelectFork(ETH_RPC);
        vm.expectRevert();
        IVaultToken(VBUSDC).redeem(1_000_000, address(this), address(this));
    }

    // ================= Solvency / WBTC reconciliation =================

    function test_solvency_vbUSDC() public {
        vm.createSelectFork(ETH_RPC);
        uint256 escrow = IERC20Min(VBUSDC).balanceOf(L1_LXLY_BRIDGE);
        uint256 adapter = IERC20Min(VBUSDC).balanceOf(VBUSDC_ADAPTER);
        vm.createSelectFork(KAT_RPC);
        uint256 l2Supply = IERC20Min(L2_VBUSDC).totalSupply();
        uint256 conv = INativeConverter(L2_VBUSDC_CONVERTER).backingOnLayerY();
        assertLe(l2Supply, escrow + adapter + conv, "vbUSDC unbacked");
    }

    function test_solvency_vbUSDT() public {
        vm.createSelectFork(ETH_RPC);
        uint256 escrow = IERC20Min(VBUSDT).balanceOf(L1_LXLY_BRIDGE);
        uint256 adapter = IERC20Min(VBUSDT).balanceOf(VBUSDT_ADAPTER);
        vm.createSelectFork(KAT_RPC);
        uint256 l2Supply = IERC20Min(L2_VBUSDT).totalSupply();
        uint256 conv = INativeConverter(L2_USDT_CONVERTER).backingOnLayerY();
        assertLe(l2Supply, escrow + adapter + conv, "vbUSDT unbacked");
    }

    function test_solvency_vbWBTC() public {
        vm.createSelectFork(ETH_RPC);
        uint256 escrow = IERC20Min(VBWBTC).balanceOf(L1_LXLY_BRIDGE);
        uint256 adapter = IERC20Min(VBWBTC).balanceOf(VBWBTC_ADAPTER);
        uint256 l1TotalAssets = IVaultToken(VBWBTC).totalAssets();
        vm.createSelectFork(KAT_RPC);
        uint256 l2Supply = IERC20Min(L2_VBWBTC).totalSupply();
        uint256 conv = INativeConverter(L2_WBTC_CONVERTER).backingOnLayerY();
        assertLe(l2Supply, escrow + adapter + conv, "vbWBTC unbacked");
        // 154.17 WBTC is the real L1 vault totalAssets; the old 33.68 figure was a single strategy.
        assertGe(l1TotalAssets, 150_000_000_00, "L1 vbWBTC totalAssets unexpectedly low");
        assertLe(l1TotalAssets, 160_000_000_00, "L1 vbWBTC totalAssets unexpectedly high");
        assertGe(escrow, 149_000_000_00, "L1 escrow unexpectedly low");
        assertLe(escrow, 156_000_000_00, "L1 escrow unexpectedly high");
    }

    function test_solvency_vbETH() public {
        vm.createSelectFork(ETH_RPC);
        uint256 escrow = IERC20Min(VBETH).balanceOf(L1_LXLY_BRIDGE);
        uint256 adapter = IERC20Min(VBETH).balanceOf(VBETH_ADAPTER);
        vm.createSelectFork(KAT_RPC);
        uint256 l2Supply = IERC20Min(L2_WETH).totalSupply();
        uint256 nativeEth = address(L2_WETH).balance; // WETH contract holds deposited ETH
        uint256 conv = INativeConverter(0xa6B0DB1293144Ebe9478B6a84F75dd651E45914a).backingOnLayerY();
        assertLe(l2Supply, escrow + adapter + nativeEth + conv, "WETH unbacked");
    }

    function test_allMinersShareSameOwnerAndEndpoint() public {
        vm.createSelectFork(KAT_RPC);
        address[4] memory minters = [MINTER, L2_USDT_MINTER, L2_WBTC_MINTER, L2_ETH_MINTER];
        for (uint256 i; i < minters.length; i++) {
            IOApp m = IOApp(minters[i]);
            assertEq(m.owner(), 0x619D553686958A873A62B336b2DD97C3b25134EA, "minter owner");
            assertEq(m.endpoint(), L2_ENDPOINT, "minter endpoint");
            assertEq(m.globalInitializationCounter(), 1, "minter init counter");
        }
        assertEq(IOApp(L2_ETH_MINTER).peers(30101), bytes32(uint256(uint160(VBETH_ADAPTER))), "vbETH peer");
        assertEq(IOApp(L2_USDT_MINTER).peers(30101), bytes32(uint256(uint160(VBUSDT_ADAPTER))), "vbUSDT peer");
        assertEq(IOApp(L2_WBTC_MINTER).peers(30101), bytes32(uint256(uint160(VBWBTC_ADAPTER))), "vbWBTC peer");
    }
}
