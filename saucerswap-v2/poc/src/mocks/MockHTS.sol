// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IHederaTokenService as CoreHTS} from "../core/interfaces/IHederaTokenService.sol";
import {IHederaTokenService as PerHTS} from "../periphery/interfaces/IHederaTokenService.sol";

/// @notice Minimal local mock of the Hedera HTS precompile (0x167) used by SaucerSwap V2.
/// Storage-free: the NFT address is an immutable baked into runtime code so `vm.etch` works.
/// NOTE: the real HTS enforces allowance for `transferToken` when sender != caller
/// (docs.hedera.com HSCS security model v2); this mock moves balances unconditionally so the
/// local end-to-end flow can be exercised. It is NOT a security oracle and must not be used
/// to reason about the real allowance rules.
interface IMockMoveERC20 {
    function move(address from, address to, uint256 amount) external;
}

interface IMockNFTMin {
    function mintTo(address to, bytes calldata meta) external returns (int64 serial);
    function moveNFT(address from, address to, int64 serial) external;
}

contract MockHTS {
    address public immutable nft;

    constructor(address _nft) {
        nft = _nft;
    }

    // Hedera response code 22 = SUCCESS
    fallback(bytes calldata data) external returns (bytes memory) {
        bytes4 sel = bytes4(data[:4]);
        if (sel == CoreHTS.associateToken.selector || sel == CoreHTS.associateTokens.selector) {
            return abi.encode(int32(22));
        }
        if (sel == PerHTS.createNonFungibleToken.selector) {
            return abi.encode(int32(22), nft);
        }
        if (sel == PerHTS.mintToken.selector) {
            (, , bytes[] memory md) = abi.decode(data[4:], (address, int64, bytes[]));
            bytes memory meta = md.length > 0 ? md[0] : bytes("");
            int64 s = IMockNFTMin(nft).mintTo(msg.sender, meta);
            return abi.encode(int32(22), s);
        }
        if (sel == PerHTS.burnToken.selector) {
            return abi.encode(int32(22));
        }
        if (sel == CoreHTS.transferToken.selector) {
            (address token, address from, address to, int64 amount) =
                abi.decode(data[4:], (address, address, address, int64));
            IMockMoveERC20(token).move(from, to, uint256(uint64(amount)));
            return abi.encode(int32(22));
        }
        if (sel == PerHTS.transferNFT.selector) {
            (address token, address from, address to, int64 serial) =
                abi.decode(data[4:], (address, address, address, int64));
            IMockNFTMin(token).moveNFT(from, to, serial);
            return abi.encode(int32(22));
        }
        if (sel == PerHTS.approve.selector) {
            return abi.encode(int32(22));
        }
        revert("MockHTS:unhandled");
    }
}

/// @notice Mock of the Hedera exchange-rate precompile (0x168). Identity conversion is enough
/// for local tests where mintFee/poolCreateFee are 0.
contract MockExchangeRate {
    fallback(bytes calldata data) external returns (bytes memory) {
        bytes4 sel = bytes4(data[:4]);
        if (sel == bytes4(keccak256("tinycentsToTinybars(uint256)")) ||
            sel == bytes4(keccak256("tinybarsToTinycents(uint256)"))) {
            (uint256 x) = abi.decode(data[4:], (uint256));
            return abi.encode(x);
        }
        revert("MockExchangeRate:unhandled");
    }
}
