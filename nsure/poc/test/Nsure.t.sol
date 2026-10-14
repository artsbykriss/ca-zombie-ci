// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/INsure.sol";

/// @title Nsure (Ethereum) — live extractability PoC
/// @notice READ-ONLY research: all tests run on a local fork of Ethereum mainnet.
///         No transaction is ever sent to a real network.
/// @dev    Pinned block 26_193_225 (2026-10-14). Fresh-attacker standard:
///         the attacker has no legacy positions, keys, roles or whitelists.
contract NsureLiveTest is Test {
    uint256 constant BLOCK = 26_193_225;

    address constant CAPITAL_STAKE  = 0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6; // CapitalStake
    address constant UNDERWRITING   = 0x1a66f065303299d78693f122c800Ab3dEbE9c966; // Underwriting
    address constant BUY            = 0x702Aff99b08e8891Fc70811174701Fb7407B4477; // Buy
    address constant SURPLUS        = 0x80E711B29e46d430Ff1553eB2aDA670E2A25593C; // Surplus
    address constant TREASURY       = 0xfd0D28539aeD12477dcba1575eB40fca53969440; // Treasury
    address constant NSURE          = 0x20945cA1df56D237fD40036d47E866C7DcCD2114; // Nsure token
    address constant CONVERTER      = 0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84; // CapitalConverter (nETH)
    address constant PRODUCT        = 0x06e76c5C53775681f0626600d6266901a03141a8; // Product
    address constant CLAIM_PURCHASE = 0x200dB99FE5c0f39688853d4c4D8651648d995b26; // ClaimPurchaseMint
    address constant OWNER_EOA      = 0x7023a32108539A024Ca17aFaB0F5B90f8770bcCd; // owner of all pools (EOA)
    address constant SIGNER_CS      = 0x04aE9200C02d598EDF2801C3E3850431d57CD707; // CapitalStake signer (EOA)
    address constant SIGNER_POOLS   = 0xbB826fB86FaE53be90f0b711C6a506860b7bDbE3; // Underwriting/Treasury/Buy signer (EOA)
    address constant SAFE           = 0x1995dc62B91163E4693f63Eae7AF6559c8aB299C; // 3/5 Gnosis Safe
    address constant WETH           = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant PAIR           = 0xed196f5f01e8c99eF4c6d77B83CCaF629032A8f2; // UniV2 NSURE/WETH
    address constant STAKER         = 0x297946c26171008BA8c0e5642814b5Fe6b842Ab7; // 11 nETH staker
    address constant NETH_HOLDER    = 0x3906e62fb8C9E53710CBaf533AC787b7179C5209; // 2.0 nETH wallet

    address attacker = address(0xA11CE);

    // live values at BLOCK (from live_state.json)
    uint256 constant UW_WETH = 3_310_472_452_994_177_977;
    uint256 constant SU_WETH = 6_048_082_593_315_581_676;
    uint256 constant TR_WETH = 1_512_020_648_328_895_409;
    uint256 constant TOTAL_WETH = UW_WETH + SU_WETH + TR_WETH; // 10.870575694638655562

    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant CLAIM_TYPEHASH  = keccak256("Claim(address account,uint256 currency,uint256 amount,uint256 nonce,uint256 deadline)");

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))),
            BLOCK
        );
        vm.label(CAPITAL_STAKE, "CapitalStake");
        vm.label(UNDERWRITING, "Underwriting");
        vm.label(SURPLUS, "Surplus");
        vm.label(TREASURY, "Treasury");
        vm.label(CONVERTER, "CapitalConverter");
        vm.label(attacker, "attacker");
    }

    // ------------------------------------------------------------------
    // 1. live state
    // ------------------------------------------------------------------
    function test_live_state() public {
        assertEq(IERC20(WETH).balanceOf(UNDERWRITING), UW_WETH, "UW WETH");
        assertEq(IERC20(WETH).balanceOf(SURPLUS), SU_WETH, "SU WETH");
        assertEq(IERC20(WETH).balanceOf(TREASURY), TR_WETH, "TR WETH");
        assertEq(IERC20(WETH).balanceOf(UNDERWRITING) + IERC20(WETH).balanceOf(SURPLUS) + IERC20(WETH).balanceOf(TREASURY), TOTAL_WETH, "total WETH");

        assertEq(IPool(UNDERWRITING).owner(), OWNER_EOA, "UW owner");
        assertEq(IPool(UNDERWRITING).signer(), SIGNER_POOLS, "UW signer");
        assertEq(IPool(UNDERWRITING).operator(), address(0), "UW operator unset");
        assertEq(IPool(TREASURY).owner(), OWNER_EOA, "TR owner");
        assertEq(IPool(TREASURY).signer(), SIGNER_POOLS, "TR signer");
        assertEq(IPool(TREASURY).operator(), address(0), "TR operator unset");
        assertEq(ISurplus(SURPLUS).owner(), OWNER_EOA, "SU owner");
        assertEq(ISurplus(SURPLUS).operator(), address(0), "SU operator unset");
        assertEq(ICapitalStake(CAPITAL_STAKE).signer(), SIGNER_CS, "CS signer");
        assertEq(ICapitalStake(CAPITAL_STAKE).operator(), address(0), "CS operator unset");
        assertFalse(ICapitalStake(CAPITAL_STAKE).paused(), "CS not paused");
        assertTrue(ICapitalStake(CAPITAL_STAKE).canDeposit(), "CS deposits open");

        // Underwriting claims can only pay WETH (currency 0); Treasury [NSURE, WETH]
        (address uwCur0,) = IPool(UNDERWRITING).divCurrencies(0);
        assertEq(uwCur0, WETH, "UW div[0]=WETH");
        (address trCur0,) = IPool(TREASURY).divCurrencies(0);
        (address trCur1,) = IPool(TREASURY).divCurrencies(1);
        assertEq(trCur0, NSURE, "TR div[0]=NSURE");
        assertEq(trCur1, WETH, "TR div[1]=WETH");

        // nETH backing is gone
        assertEq(ICapitalConverter(CONVERTER).smartBalance(), 0, "converter ETH = 0");
        assertEq(CONVERTER.balance, 0, "converter native = 0");

        // NSURE liquidity
        (uint112 r0, uint112 r1,) = IUniV2(PAIR).getReserves();
        emit log_named_uint("pair NSURE reserve", uint256(r0));
        emit log_named_uint("pair WETH reserve", uint256(r1));
    }

    // ------------------------------------------------------------------
    // 2. E-U: every permissionless extraction path is closed
    // ------------------------------------------------------------------
    function test_eu_paths_closed() public {
        vm.deal(attacker, 10 ether);
        uint256 attWeth0 = IERC20(WETH).balanceOf(attacker);
        uint256 attNsure0 = IERC20(NSURE).balanceOf(attacker);
        uint256 attEth0 = attacker.balance;

        uint256 deadline = block.timestamp + 1000;

        // (a) Underwriting.claim with fabricated signature -> revert
        vm.prank(attacker);
        vm.expectRevert();
        IPool(UNDERWRITING).claim(UW_WETH, 0, deadline, 27, bytes32(uint256(1)), bytes32(uint256(1)));

        // (b) Treasury.claim with fabricated signature -> revert
        vm.prank(attacker);
        vm.expectRevert();
        IPool(TREASURY).claim(TR_WETH, 1, deadline, 27, bytes32(uint256(1)), bytes32(uint256(1)));

        // (c) Surplus.payouts -> operator is address(0): impossible for anyone
        vm.prank(attacker);
        vm.expectRevert(bytes("not operator"));
        ISurplus(SURPLUS).payouts(payable(attacker), SU_WETH, WETH);

        // (d) Treasury.payouts -> operator unset
        vm.prank(attacker);
        vm.expectRevert(bytes("not operator"));
        IPool(TREASURY).payouts(payable(attacker), TR_WETH, WETH);

        // (e) Underwriting.withdraw -> no internal balance
        vm.prank(attacker);
        vm.expectRevert(bytes("insufficient"));
        IPool(UNDERWRITING).withdraw(1, deadline, 27, bytes32(uint256(1)), bytes32(uint256(1)));

        // (f) CapitalStake.unstake -> signer signature required
        vm.prank(attacker);
        vm.expectRevert();
        ICapitalStake(CAPITAL_STAKE).unstake(0, 1, 27, bytes32(uint256(1)), bytes32(uint256(1)), deadline);

        // (g) CapitalStake.claim with no stake -> succeeds but pays 0
        vm.prank(attacker);
        ICapitalStake(CAPITAL_STAKE).claim(0);

        // (h) CapitalStake.withdraw with no pending -> succeeds but pays 0
        vm.prank(attacker);
        ICapitalStake(CAPITAL_STAKE).withdraw(0);

        // (i) CapitalConverter.exit without nETH -> revert
        vm.prank(attacker);
        vm.expectRevert(bytes("CapitalConverter: insufficient assets"));
        ICapitalConverter(CONVERTER).exit(1e18);

        // (j) CapitalConverter.convert 1 ETH -> bricked (SafeMath underflow: balance 0)
        vm.prank(attacker);
        vm.expectRevert();
        ICapitalConverter(CONVERTER).convert{value: 1 ether}(1 ether);

        // (k) Buy.buyInsurance with fabricated signature -> revert (premium transfers rolled back)
        vm.prank(attacker);
        vm.expectRevert();
        IBuy(BUY).buyInsurance{value: 0.001 ether}(1, 100e18, 0.001 ether, 30 days, 27, bytes32(uint256(1)), bytes32(uint256(1)), deadline, 0);

        // (l) NSURE mint is minter-gated
        vm.prank(attacker);
        vm.expectRevert();
        INsureToken(NSURE).mint(attacker, 1e18);

        // net gain for a fresh attacker: zero
        assertEq(IERC20(WETH).balanceOf(attacker), attWeth0, "attacker WETH unchanged");
        assertEq(IERC20(NSURE).balanceOf(attacker), attNsure0, "attacker NSURE unchanged");
        assertEq(attacker.balance, attEth0, "attacker ETH unchanged");
    }

    // ------------------------------------------------------------------
    // 3. E-U: even a legacy nETH holder gets 0 ETH back (backing drained)
    // ------------------------------------------------------------------
    function test_eu_neth_exit_pays_zero() public {
        assertEq(IERC20(CONVERTER).balanceOf(NETH_HOLDER), 2.0e18, "holder nETH");
        uint256 before = NETH_HOLDER.balance;
        vm.prank(NETH_HOLDER);
        ICapitalConverter(CONVERTER).exit(2.0e18);
        assertEq(NETH_HOLDER.balance, before, "exit paid 0 ETH");
        assertEq(IERC20(CONVERTER).balanceOf(NETH_HOLDER), 0, "nETH burned");
    }

    // ------------------------------------------------------------------
    // 4. P: owner/signer keys can drain the full 10.8706 WETH
    //    (demonstration with impersonated owner + a test signer key)
    // ------------------------------------------------------------------
    function test_privileged_owner_signer_drain() public {
        uint256 pk = 0xB0B;
        address newSigner = vm.addr(pk);
        uint256 deadline = block.timestamp + 1000;

        // ---- Underwriting: owner rotates signer, signer signs a claim ----
        vm.prank(OWNER_EOA);
        IPool(UNDERWRITING).setSigner(newSigner);
        assertEq(IPool(UNDERWRITING).signer(), newSigner, "signer rotated");

        bytes32 digest = _claimDigest(UNDERWRITING, "Stake", attacker, 0, UW_WETH, IPool(UNDERWRITING).nonces(attacker), deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        vm.prank(attacker);
        IPool(UNDERWRITING).claim(UW_WETH, 0, deadline, v, r, s);
        assertEq(IERC20(WETH).balanceOf(attacker), UW_WETH, "attacker got UW WETH");

        // ---- Treasury: same, currency 1 = WETH ----
        vm.prank(OWNER_EOA);
        IPool(TREASURY).setSigner(newSigner);
        digest = _claimDigest(TREASURY, "Treasury", attacker, 1, TR_WETH, IPool(TREASURY).nonces(attacker), deadline);
        (v, r, s) = vm.sign(pk, digest);
        vm.prank(attacker);
        IPool(TREASURY).claim(TR_WETH, 1, deadline, v, r, s);

        // ---- Surplus: owner sets operator, operator pays out ----
        vm.prank(OWNER_EOA);
        ISurplus(SURPLUS).setOperator(attacker);
        vm.prank(attacker);
        ISurplus(SURPLUS).payouts(payable(attacker), SU_WETH, WETH);

        assertEq(IERC20(WETH).balanceOf(attacker), TOTAL_WETH, "attacker drained all WETH");
        assertEq(IERC20(WETH).balanceOf(UNDERWRITING), 0, "UW empty");
        assertEq(IERC20(WETH).balanceOf(TREASURY), 0, "TR empty");
        assertEq(IERC20(WETH).balanceOf(SURPLUS), 0, "SU empty");
        emit log_named_uint("P-path total drained (wei)", TOTAL_WETH);
    }

    // ------------------------------------------------------------------
    // 5. H-O: a legacy staker can still claim accrued NSURE rewards
    // ------------------------------------------------------------------
    function test_ho_staker_claims_nsure_rewards() public {
        uint256 pending = ICapitalStake(CAPITAL_STAKE).pendingNsure(0, STAKER);
        uint256 before = IERC20(NSURE).balanceOf(STAKER);
        vm.prank(STAKER);
        ICapitalStake(CAPITAL_STAKE).claim(0);
        uint256 gained = IERC20(NSURE).balanceOf(STAKER) - before;
        assertEq(gained, pending, "staker got pending NSURE");
        emit log_named_uint("staker pending NSURE (wei)", pending);
    }

    // ------------------------------------------------------------------
    function _claimDigest(address pool, string memory name, address account, uint256 currency, uint256 amount, uint256 nonce, uint256 deadline) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), block.chainid, pool));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, account, currency, amount, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

interface IUniV2 {
    function getReserves() external view returns (uint112, uint112, uint32);
}
