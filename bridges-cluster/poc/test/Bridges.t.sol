// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IHashportRouter {
    function owner() external view returns (address);
    function admin() external view returns (address);
    function membersCount() external view returns (uint256);
    function membersPercentage() external view returns (uint256);
    function membersPrecision() external view returns (uint256);
    function paused() external view returns (bool);
    function nativeTokensCount() external view returns (uint256);
    function hashesUsed(bytes32) external view returns (bool);
    function unlock(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    ) external;
    function mint(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _wrappedToken,
        address _receiver,
        uint256 _amount,
        bytes[] calldata _signatures
    ) external;
}

interface IAMB {
    function validatorContract() external view returns (address);
    function requiredSignatures() external view returns (uint256);
    function messageId() external view returns (bytes32);
    function executeSignatures(bytes memory _data, bytes memory _signatures) external;
}

interface ITokenBridgeMediator {
    function bridgeContract() external view returns (address);
    function mediatorContractOnOtherSide() external view returns (address);
    function handleBridgedTokens(address _recipient, uint256 _value) external;
}

interface IValidatorContract {
    function validatorCount() external view returns (uint256);
    function requiredSignatures() external view returns (uint256);
    function validatorList() external view returns (address[] memory);
}

interface ITelosOFT {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) external payable;
    function outboundAmount() external view returns (uint256);
}

struct LzCallParams {
    address payable refundAddress;
    address zroPaymentAddress;
    bytes adapterParams;
}

contract HashportTest is Test {
    IHashportRouter constant ROUTER =
        IHashportRouter(0x367e59b559283C8506207d75B0c5D8C66c4Cd4B7);
    address constant QNT = 0x4a220E6096B25EADb88358cb44068A3248254675;

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
    }

    function test_liveConfig() public view {
        assertEq(ROUTER.membersCount(), 9);
        assertEq(ROUTER.membersPercentage(), 51);
        assertEq(ROUTER.membersPrecision(), 100);
        // ceil(9 * 51 / 100) = 5 required signatures
        assertEq(ROUTER.paused(), false);
        assertEq(ROUTER.nativeTokensCount(), 24);
        assertEq(ROUTER.hashesUsed(keccak256("zombie-hunt-iv")), false);
    }

    function test_unlockRejectsUnsignedMessage() public {
        bytes[] memory sigs = new bytes[](5);
        for (uint256 i = 0; i < 5; i++) {
            sigs[i] = new bytes(65);
            sigs[i][64] = bytes1(uint8(27));
        }
        (bool ok, ) = address(ROUTER).call(
            abi.encodeWithSignature(
                "unlock(uint256,bytes,address,uint256,address,bytes[])",
                uint256(1),
                hex"01",
                QNT,
                uint256(1),
                address(this),
                sigs
            )
        );
        assertFalse(ok, "unlock must reject non-validator signatures");
    }

    function test_mintRejectsUnsignedMessage() public {
        bytes[] memory sigs = new bytes[](5);
        for (uint256 i = 0; i < 5; i++) {
            sigs[i] = new bytes(65);
            sigs[i][64] = bytes1(uint8(27));
        }
        (bool ok, ) = address(ROUTER).call(
            abi.encodeWithSignature(
                "mint(uint256,bytes,address,address,uint256,bytes[])",
                uint256(1),
                hex"01",
                address(0x1234),
                address(this),
                uint256(1),
                sigs
            )
        );
        assertFalse(ok, "mint must reject non-validator signatures");
    }
}

contract ElastosTest is Test {
    IAMB constant AMB = IAMB(0x4490ee96671855BD0a52Eb5074EC5569496c0162);
    ITokenBridgeMediator constant MEDIATOR =
        ITokenBridgeMediator(0xE235CbC85e26824E4D855d4d0ac80f3A85A520E4);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("ELASTOS_RPC", string("https://api.elastos.io/esc"))
        );
    }

    function test_liveConfig() public view {
        assertEq(AMB.requiredSignatures(), 2);
        assertEq(AMB.messageId(), bytes32(0));
        IValidatorContract vc = IValidatorContract(AMB.validatorContract());
        assertEq(vc.validatorCount(), 2);
        assertEq(vc.requiredSignatures(), 2);
        assertTrue(MEDIATOR.bridgeContract() == address(AMB));
        assertTrue(MEDIATOR.mediatorContractOnOtherSide() != address(0));
        assertGt(address(MEDIATOR).balance, 6_000_000 ether);
    }

    function test_executeSignaturesRejectsGarbage() public {
        (bool ok, ) = address(AMB).call(
            abi.encodeWithSignature("executeSignatures(bytes,bytes)", hex"00", hex"00")
        );
        assertFalse(ok, "executeSignatures must reject invalid signatures");
    }

    function test_mediatorRejectsDirectBridgeCall() public {
        vm.prank(address(AMB));
        (bool ok, ) = address(MEDIATOR).call(
            abi.encodeWithSignature(
                "handleBridgedTokens(address,uint256)",
                address(0xdead),
                uint256(1)
            )
        );
        assertFalse(ok, "mediator must reject when no AMB message is in flight");
    }
}

contract TelosOFTTest is Test {
    ITelosOFT constant OFT =
        ITelosOFT(0x02Ea28694Ae65358Be92bAFeF5Cb8C211f33Db1A);
    address attacker = address(0xA11CE);
    address victim = address(0xB0B);

    function setUp() public {
        vm.createSelectFork(vm.envOr("TELOS_RPC", string("https://rpc.telos.net")));
    }

    function test_fullyBacked() public view {
        assertEq(OFT.totalSupply(), address(OFT).balance);
        assertGt(address(OFT).balance, 51_000_000 ether);
    }

    function test_depositWithdrawRoundTrip() public {
        vm.deal(attacker, 10 ether);
        vm.prank(attacker);
        OFT.deposit{value: 3 ether}();
        assertEq(OFT.balanceOf(attacker), 3 ether);

        vm.prank(attacker);
        OFT.withdraw(1 ether);
        assertEq(OFT.balanceOf(attacker), 2 ether);
        assertEq(attacker.balance, 8 ether);
    }

    function test_withdrawZeroBalanceReverts() public {
        vm.prank(attacker);
        (bool ok, ) = address(OFT).call(
            abi.encodeWithSignature("withdraw(uint256)", uint256(1))
        );
        assertFalse(ok, "withdraw must require an OFT balance");
    }

    function test_sendFromCannotSpendVictimWithoutAllowance() public {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        OFT.deposit{value: 5 ether}();
        assertEq(OFT.balanceOf(victim), 5 ether);
        assertEq(OFT.balanceOf(attacker), 0);

        LzCallParams memory p = LzCallParams({
            refundAddress: payable(attacker),
            zroPaymentAddress: address(0),
            adapterParams: abi.encodePacked(uint16(1), uint256(200000))
        });

        vm.prank(attacker);
        (bool ok, ) = address(OFT).call(
            abi.encodeCall(
                ITelosOFT.sendFrom,
                (
                    victim,
                    uint16(101),
                    bytes32(uint256(uint160(attacker))),
                    uint256(1 ether),
                    p
                )
            )
        );
        assertFalse(ok, "sendFrom must require allowance from a third-party _from");
    }
}
