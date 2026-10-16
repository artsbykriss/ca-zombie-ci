// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

// NOTE (Z3-H17 child, HertzFlow): poc/src/ForkHelper.sol does not compile against the vendored
// forge-std (its VM_ADDRESS constant redeclares Base.VM_ADDRESS, solc error 9097) and this child
// may not edit parent-owned files. Identical fork semantics are implemented locally below:
// env override (BSC_RPC) first, else first reachable keyless public RPC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IHFRouter {
    function makeExternalCalls(
        address[] calldata targets,
        bytes[] calldata data,
        address[] calldata refundTokens,
        address[] calldata refundReceivers
    ) external payable;
}

interface IHFBank {
    function admin() external view returns (address);
    function underlyingToken() external view returns (address);
    function wrappedToken() external view returns (address);
    function getReserve() external view returns (uint256, uint256);
    function recordedUnderlyingBalance() external view returns (uint256);
    function minReserveFactor() external view returns (uint256);
    function paused() external view returns (bool);
    function isMintCaller(address) external view returns (bool);
    function isMintReceiver(address) external view returns (bool);
    function isBorrower(address) external view returns (bool);
    function mint(address receiver) external returns (uint256);
    function redeem(uint256 amount, address receiver) external;
}

interface IWrapped {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function canHold(address) external view returns (bool);
    function minters(address) external view returns (bool);
    function registrars(address) external view returns (bool);
    function redemptionBank() external view returns (address);
    function addMinter(address) external;
}

interface IDataStore {
    function getUint(bytes32) external view returns (uint256);
    function getAddress(bytes32) external view returns (address);
    function getBool(bytes32) external view returns (bool);
    function setUint(bytes32, uint256) external;
}

/// @title Z3-H17 · HertzFlow (BSC 56) — GMX-v2-fork config layer + wrapped-bank parity
/// @notice Read-only research PoC. Local fork of live BSC state via keyless public RPCs only.
///         No mainnet transactions, no keys. Structural assertions only.
contract HertzFlowH17Test is Test {
    address constant VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));

    // --- deployment B ("value-bearing": DL adapter) ---
    address constant ROUTER_B = 0x61e1116A943b27D21094599C2c5Bd75e980170a5;
    address constant HELPER_B = 0x95d312Da653F8B9c6f04345f3B2463e91c7505b3; // executor used by makeExternalCalls
    address constant DATASTORE_B = 0xc244A37A17CE7aa14E1BDD73f6a047Ed6B56f6B8;
    address constant BANK_HFUSD = 0x00ceA6655a2b5C4eAD8752EBb41dbC896D3eB5df;
    address constant BANK_HFUSD1 = 0xAB96931f9d151bE6Ff313449a926390cA292db62;
    address constant HFUSD = 0x7F7AD43d1Baa6BeA7f53F72D97D90b4FC0f662DF;
    address constant HFUSD1 = 0x026C39Ab4B07f4C8C62b5824F0F9D7BE5087405a;
    address constant U_TOKEN = 0xcE24439F2D9C6a2289F741120FE202248B666666;
    address constant USD1 = 0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d;
    address constant DEPOSIT_VAULT_B = 0x1de72AcBCfD84F437B369fE195417CAaB4ffE115;
    address constant MK_M2 = 0xF59B083e6B700F011475c70A2F81FA49378e28d3; // BTC/USD HFUSD1 market
    address constant ATTACKER = address(0xA77ACC);
    bytes32 constant POOL_AMOUNT_KEY = keccak256(abi.encode("POOL_AMOUNT"));

    function _fork() internal returns (uint256 blk) {
        string[2] memory urls = [
            "https://bsc-rpc.publicnode.com",
            "https://bsc-dataseed.bnbchain.org"
        ];
        string memory override_ = vm.envOr("BSC_RPC", string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return block.number;
        }
        for (uint256 i = 0; i < urls.length; i++) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return block.number;
        }
        revert("no reachable BSC RPC");
    }

    function setUp() public {
        uint256 blk = _fork();
        console2.log("fork block (BSC eth_blockNumber space):", blk);
    }

    // T1 — makeExternalCalls is permissionless: a fresh attacker can invoke the router entrypoint.
    function test_T1_makeExternalCalls_permissionless() public {
        address[] memory t = new address[](0);
        bytes[] memory d = new bytes[](0);
        address[] memory empty = new address[](0);
        vm.prank(ATTACKER, ATTACKER);
        IHFRouter(ROUTER_B).makeExternalCalls(t, d, empty, empty);
        console2.log("T1 PASS: fresh attacker invoked makeExternalCalls (empty) successfully");
    }

    // T2 — external calls execute under the shared executor (HELPER_B), not the router;
    //      config writes are rejected because the executor holds no DataStore role.
    function test_T2_datastore_write_blocked() public {
        bytes32 probeKey = keccak256(abi.encode("H17_PROBE"));
        address[] memory targets = new address[](1);
        targets[0] = DATASTORE_B;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(IDataStore.setUint.selector, probeKey, uint256(1));
        address[] memory empty = new address[](0);

        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = ROUTER_B.call(
            abi.encodeWithSelector(IHFRouter.makeExternalCalls.selector, targets, data, empty, empty)
        );
        // low-level call returns ok=false with revert data; the outer error wraps the inner revert
        assertTrue(!ok, "DataStore write via router must fail");
        console2.log("T2 revert data:");
        console2.logBytes(ret);
        // outer selector must be ExternalCallFailed(bytes) = 0x59afd6c6
        bytes4 outer;
        assembly { outer := mload(add(ret, 32)) }
        assertEq(outer, bytes4(0x59afd6c6), "expected ExternalCallFailed");
        console2.log("T2 PASS: DataStore.setUint via makeExternalCalls reverted (executor lacks CONTROLLER)");
    }

    // T3 — mintCaller primitive is real (helper executes bank.mint) but closed today: no surplus.
    function test_T3_surplus_mint_closed_today() public {
        assertTrue(IHFBank(BANK_HFUSD1).isMintCaller(HELPER_B), "helper must be mintCaller");
        assertTrue(IHFBank(BANK_HFUSD1).isMintReceiver(DEPOSIT_VAULT_B), "deposit vault must be mintReceiver");
        (uint256 reserve,) = IHFBank(BANK_HFUSD1).getReserve();
        uint256 recorded = IHFBank(BANK_HFUSD1).recordedUnderlyingBalance();
        assertEq(reserve, recorded, "no surplus expected: reserve == recorded");

        address[] memory targets = new address[](1);
        targets[0] = BANK_HFUSD1;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(IHFBank.mint.selector, DEPOSIT_VAULT_B);
        address[] memory empty = new address[](0);
        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = ROUTER_B.call(
            abi.encodeWithSelector(IHFRouter.makeExternalCalls.selector, targets, data, empty, empty)
        );
        assertTrue(!ok, "mint with zero surplus must revert");
        bytes4 outer;
        assembly { outer := mload(add(ret, 32)) }
        assertEq(outer, bytes4(0x59afd6c6), "expected ExternalCallFailed(ZeroAmount)");
        console2.log("T3 PASS: bank.mint via permissionless makeExternalCalls reverts with no surplus");
    }

    // T4 — conditional primitive: if surplus exists (any direct donation), the very next
    //      makeExternalCalls mints it, credited to the whitelisted DepositVault (not to the caller).
    function test_T4_donated_surplus_convertible_by_anyone() public {
        uint256 amount = 1_000e18;
        uint256 vaultBefore = IERC20(HFUSD1).balanceOf(DEPOSIT_VAULT_B);

        deal(USD1, ATTACKER, amount);
        vm.prank(ATTACKER, ATTACKER);
        IERC20(USD1).transfer(BANK_HFUSD1, amount); // un-synced donation -> surplus

        (uint256 reserve,) = IHFBank(BANK_HFUSD1).getReserve();
        uint256 recorded = IHFBank(BANK_HFUSD1).recordedUnderlyingBalance();
        assertEq(reserve - recorded, amount, "donation must create exact surplus");

        address[] memory targets = new address[](1);
        targets[0] = BANK_HFUSD1;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(IHFBank.mint.selector, DEPOSIT_VAULT_B);
        address[] memory empty = new address[](0);
        vm.prank(ATTACKER, ATTACKER);
        IHFRouter(ROUTER_B).makeExternalCalls(targets, data, empty, empty);

        uint256 vaultAfter = IERC20(HFUSD1).balanceOf(DEPOSIT_VAULT_B);
        assertEq(vaultAfter - vaultBefore, amount, "minted surplus goes to DepositVault");
        assertEq(IERC20(HFUSD1).balanceOf(ATTACKER), 0, "attacker receives no wrapped tokens directly");
        console2.log("T4 PASS: un-synced surplus is mintable by any caller, but only to the DepositVault");
        console2.log("          (attacker delta: -1000 USD1 / +0 HFUSD1)");
    }

    // T5 — banks are fully backed; supply of wrapped <= reserve of underlying.
    function test_T5_full_backing() public {
        (uint256 resU,) = IHFBank(BANK_HFUSD).getReserve();
        (uint256 res1,) = IHFBank(BANK_HFUSD1).getReserve();
        uint256 supU = IERC20(HFUSD).totalSupply();
        uint256 sup1 = IERC20(HFUSD1).totalSupply();
        assertGe(resU, supU, "HFUSD bank under-backed");
        assertGe(res1, sup1, "HFUSD1 bank under-backed");
        assertFalse(IHFBank(BANK_HFUSD1).paused(), "bank must not be paused");
        assertEq(IHFBank(BANK_HFUSD1).minReserveFactor(), 0, "minReserveFactor is 0 (borrower-only risk)");
        assertFalse(IHFBank(BANK_HFUSD1).isBorrower(HELPER_B), "helper must not be borrower");
        console2.log("T5 PASS: reserves >= supplies; U reserve:", resU);
        console2.log("         USD1 reserve:", res1);
    }

    // T6 — redeem requires the caller's own wrapped tokens (fresh attacker has none).
    function test_T6_redeem_requires_own_tokens() public {
        vm.prank(ATTACKER, ATTACKER);
        (bool ok,) = BANK_HFUSD1.call(abi.encodeWithSelector(IHFBank.redeem.selector, 1e18, ATTACKER));
        assertTrue(!ok, "redeem by tokenless attacker must revert");
        console2.log("T6 PASS: bank.redeem reverts for an attacker owning no wrapped tokens");
    }

    // T7 — wrapped tokens cannot be taken over via makeExternalCalls (registrar/minter ACLs).
    function test_T7_wrapped_token_not_takeoverable() public {
        assertFalse(IWrapped(HFUSD1).registrars(ROUTER_B), "router must not be registrar");
        assertFalse(IWrapped(HFUSD1).minters(HELPER_B), "executor must not be minter");
        assertFalse(IWrapped(HFUSD1).canHold(HELPER_B), "executor must not be holder");

        address[] memory targets = new address[](1);
        targets[0] = HFUSD1;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(IWrapped.addMinter.selector, ATTACKER);
        address[] memory empty = new address[](0);
        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = ROUTER_B.call(
            abi.encodeWithSelector(IHFRouter.makeExternalCalls.selector, targets, data, empty, empty)
        );
        assertTrue(!ok, "addMinter via makeExternalCalls must fail");
        assertFalse(IWrapped(HFUSD1).minters(ATTACKER), "attacker must not become minter");
        console2.log("T7 PASS: addMinter(attacker) reverted; no path to mint wrapped tokens");
        console2.logBytes(ret);
    }

    // T8 — market accounting: contract balance covers the accounted pool amount (no phantom claims).
    function test_T8_market_pool_accounting() public {
        bytes32 key = keccak256(abi.encode(POOL_AMOUNT_KEY, MK_M2, HFUSD1));
        uint256 poolAmount = IDataStore(DATASTORE_B).getUint(key);
        uint256 balance = IERC20(HFUSD1).balanceOf(MK_M2);
        assertGe(balance, poolAmount, "market balance < accounted pool");
        console2.log("T8 PASS: M2 HFUSD1 balance:", balance);
        console2.log("         accounted POOL_AMOUNT:", poolAmount);
        // PRICE_FEED data-store keys are unset on this deployment (prices are keeper/provider fed)
        bytes32 pfKey = keccak256(abi.encode(keccak256(abi.encode("PRICE_FEED")), MK_M2));
        assertEq(IDataStore(DATASTORE_B).getAddress(pfKey), address(0), "no on-chain per-token price feed expected");
    }
}
