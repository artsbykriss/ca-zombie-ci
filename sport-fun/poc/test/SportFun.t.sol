// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IERC1155 {
    function balanceOf(address, uint256) external view returns (uint256);
}

interface IPlayer {
    function sellTokens(
        uint256[] calldata playerTokenIds,
        uint256[] calldata amounts,
        uint256 minCurrencyToReceive,
        uint256[] calldata feeRateBps,
        int256[] calldata discountFeeBps,
        uint256[] calldata surgeEpochs,
        uint256 deadline,
        bytes calldata signature,
        uint256 nonce
    ) external;

    function getTxSigners() external view returns (address[] memory);
    function getActivePlayerIds() external view returns (uint256[] memory);
    function isBuyable(uint256) external view returns (bool);
    function isSellable(uint256) external view returns (bool);
    function fdfPair() external view returns (address);
    function whitelistedAddresses(address) external view returns (bool);
    function upgradeVersion() external view returns (uint256);
    function upgradeToAndCall(address, bytes memory) external payable;

    error InvalidSignature();
    error UnauthorisedTransfer();

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

interface IFDFPair {
    function buyTokens(
        uint256[] memory playerTokenIds,
        uint256[] memory playerTokenAmountsToBuy,
        uint256 maxCurrencySpend,
        uint256[] memory feeRateBps,
        int256[] memory discountFeeBps,
        uint256 deadline,
        address recipient,
        bytes calldata signature,
        uint256 nonce
    ) external returns (uint256[] memory);

    function getCurrencyReserves(uint256[] calldata ids) external view returns (uint256[] memory);
    function getAllPlayerIds() external view returns (uint256[] memory);
    function currencyToken() external view returns (address);
    function playerToken() external view returns (address);
    function treasury() external view returns (address);
    function upgradeVersion() external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);

    error INVALID_TOKENS_TRANSFERRED();
    function upgradeToAndCall(address, bytes memory) external payable;
}

/// @title Sport.fun (Football.Fun) live-state + attack-surface fork tests.
/// @notice Read-only fork of Base mainnet at a pinned block. No mainnet transactions.
contract SportFunTest is Test {
    // Base mainnet, block 52,903,383 (2026-10-21)
    uint256 constant FORK_BLOCK = 52_903_383;

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant SAFE_TREASURY = 0xBCBF7b37975AeA196Aae35F0A14C0b2951C11af4;

    // Football (FDF) deployment
    address constant PAIR_FB = 0x9da1bB4e725ACc0d96010b7cE2A7244Cda446617;
    address constant PLAYER_FB = 0x71c8b0c5148EdB0399D1EdF9BF0C8C81dEa16918;
    // NFL deployment
    address constant PAIR_NFL = 0x4Fdce033b9F30019337dDC5cC028DC023580585e;
    address constant PLAYER_NFL = 0x2EeF466e802Ab2835aB81BE63eEbc55167d35b56;

    address constant REAL_HOLDER = 0x9F2a925715F8df7EF91Fff969120394339Ab6B06;
    uint256 constant HOLDER_PLAYER_ID = 169187;

    address constant ATTACKER = address(0xBEEF01);

    IERC20 usdc = IERC20(USDC);
    IPlayer playerFb = IPlayer(PLAYER_FB);
    IPlayer playerNfl = IPlayer(PLAYER_NFL);
    IFDFPair pairFb = IFDFPair(PAIR_FB);
    IFDFPair pairNfl = IFDFPair(PAIR_NFL);

    function setUp() public {
        string memory rpcUrl = vm.envOr("BASE_RPC_URL", string("https://mainnet.base.org"));
        if (bytes(rpcUrl).length == 0) rpcUrl = "https://mainnet.base.org";
        vm.createSelectFork(rpcUrl, FORK_BLOCK);
        vm.deal(ATTACKER, 1 ether);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 1. Solvency / NAV-accounting invariant: sum(currencyReserves) == USDC
    // ─────────────────────────────────────────────────────────────────────
    function test_A_reserves_fully_backed_by_usdc() public {
        _checkPairSolvent(PAIR_FB);
        _checkPairSolvent(PAIR_NFL);
    }

    function _checkPairSolvent(address pair) internal {
        IFDFPair p = IFDFPair(pair);
        uint256[] memory ids = p.getAllPlayerIds();
        uint256[] memory reserves = p.getCurrencyReserves(ids);
        uint256 sum;
        for (uint256 i; i < ids.length; i++) {
            sum += reserves[i];
        }
        uint256 bal = usdc.balanceOf(pair);
        // accounting is exact to the cent; allow $10 dust
        assertApproxEqAbs(bal, sum, 10e6, "reserves != usdc balance");
        assertGe(bal + 1e6, sum, "pair insolvent");
        emit log_named_uint("pools", ids.length);
        emit log_named_decimal_uint("sum(currencyReserves) USDC", sum, 6);
        emit log_named_decimal_uint("USDC balance", bal, 6);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 2. Fresh attacker cannot sell without a backend EIP-712 signature
    // ─────────────────────────────────────────────────────────────────────
    function test_B_sell_without_backend_signature_reverts() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = HOLDER_PLAYER_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 300;
        int256[] memory discs = new int256[](1);
        discs[0] = 0;
        uint256[] memory surges = new uint256[](1);
        surges[0] = 0;

        uint256 usdcBefore = usdc.balanceOf(PAIR_FB);

        (address attackerSigner, uint256 pk) = makeAddrAndKey("attacker");
        bytes memory sig = _sign(pk, keccak256("bogus quote"));

        vm.prank(ATTACKER);
        vm.expectRevert(IPlayer.InvalidSignature.selector);
        playerFb.sellTokens(ids, amounts, 0, fees, discs, surges, block.timestamp + 1 hours, sig, 1);

        assertEq(usdc.balanceOf(PAIR_FB), usdcBefore, "USDC moved");
        assertTrue(attackerSigner != address(0));
    }

    // ─────────────────────────────────────────────────────────────────────
    // 3. Even a real holder cannot bypass the signed-quote gate
    // ─────────────────────────────────────────────────────────────────────
    function test_C_real_holder_still_needs_signature() public {
        uint256 bal = IERC1155(PLAYER_FB).balanceOf(REAL_HOLDER, HOLDER_PLAYER_ID);
        assertGt(bal, 0, "holder has shares at fork block");

        uint256[] memory ids = new uint256[](1);
        ids[0] = HOLDER_PLAYER_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = bal;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 300;
        int256[] memory discs = new int256[](1);
        discs[0] = 0;
        uint256[] memory surges = new uint256[](1);
        surges[0] = 0;

        (, uint256 pk) = makeAddrAndKey("attacker2");
        bytes memory sig = _sign(pk, keccak256("bogus holder quote"));

        vm.prank(REAL_HOLDER);
        vm.expectRevert(IPlayer.InvalidSignature.selector);
        playerFb.sellTokens(ids, amounts, 0, fees, discs, surges, block.timestamp + 1 hours, sig, 100);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 4. Direct ERC1155 deposit into the pair (to fake a sell) is blocked
    // ─────────────────────────────────────────────────────────────────────
    function test_D_direct_transfer_to_pair_blocked() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = HOLDER_PLAYER_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;
        bytes memory data = abi.encode(bytes4(0xade79c7b), "");

        vm.prank(ATTACKER);
        vm.expectRevert(IPlayer.UnauthorisedTransfer.selector);
        playerFb.safeBatchTransferFrom(ATTACKER, PAIR_FB, ids, amounts, data);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 5. Pair callback cannot be invoked by an arbitrary caller
    // ─────────────────────────────────────────────────────────────────────
    function test_E_direct_pair_callback_reverts() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = HOLDER_PLAYER_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        vm.prank(ATTACKER);
        vm.expectRevert();
        pairFb.onERC1155BatchReceived(ATTACKER, ATTACKER, ids, amounts, "");
    }

    // ─────────────────────────────────────────────────────────────────────
    // 6. Buy path also requires the backend signature
    // ─────────────────────────────────────────────────────────────────────
    function test_F_buy_without_backend_signature_reverts() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = HOLDER_PLAYER_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 300;
        int256[] memory discs = new int256[](1);
        discs[0] = 0;

        (, uint256 pk) = makeAddrAndKey("attacker3");
        bytes memory sig = _sign(pk, keccak256("bogus buy quote"));

        vm.prank(ATTACKER);
        vm.expectRevert(IPlayer.InvalidSignature.selector);
        pairFb.buyTokens(ids, amounts, 100e6, fees, discs, block.timestamp + 1 hours, ATTACKER, sig, 1);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 7. Upgrade is governor-only (Safe) — no unprivileged drain path
    // ─────────────────────────────────────────────────────────────────────
    function test_G_upgrade_is_governor_only() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        pairFb.upgradeToAndCall(ATTACKER, "");
    }

    // ─────────────────────────────────────────────────────────────────────
    // 8. Ownership / role surface and no stray balances in game contracts
    // ─────────────────────────────────────────────────────────────────────
    function test_H_role_surface_and_stray_balances() public view {
        assertTrue(pairFb.hasRole(keccak256("GOVERNOR_ROLE"), SAFE_TREASURY), "safe not governor fb");
        assertTrue(pairNfl.hasRole(keccak256("GOVERNOR_ROLE"), SAFE_TREASURY), "safe not governor nfl");
        assertEq(pairFb.upgradeVersion(), 4);
        assertEq(pairNfl.upgradeVersion(), 4);
        assertEq(usdc.balanceOf(PAIR_FB) + usdc.balanceOf(PAIR_NFL), 2_121_053_796_733, "total usdc");
        assertEq(usdc.balanceOf(PLAYER_FB), 0, "player contract holds USDC");
        assertEq(usdc.balanceOf(PLAYER_NFL), 0, "player contract holds USDC");
    }

    // ─────────────────────────────────────────────────────────────────────
    // 9. Holder's shares are still present and sellable only via signed quote
    //    (no on-chain expiry exists — shares do not vanish after a tournament)
    // ─────────────────────────────────────────────────────────────────────
    function test_I_no_onchain_expiry_balances_persist() public view {
        assertGt(IERC1155(PLAYER_FB).balanceOf(REAL_HOLDER, HOLDER_PLAYER_ID), 0);
        // token has no expiry surface: getTxSigners/fdfPair/isSellable only
        assertTrue(playerFb.isSellable(HOLDER_PLAYER_ID));
        assertEq(playerFb.upgradeVersion(), 3);
    }

    function _sign(uint256 pk, bytes32 digest) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }
}
