// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @notice Minimal ERC-721-shaped mock used as the SaucerSwap V2 LP position NFT (HTS stand-in).
contract MockNFT {
    string public name = "SaucerSwap v2 Liquidity Position";
    string public symbol = "SSV2-LP";
    uint256 public nextSerial = 1;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => uint256) public balanceOf;

    function mintTo(address to, bytes calldata) external returns (int64 serial) {
        serial = int64(uint64(nextSerial));
        ownerOf[uint256(uint64(serial))] = to;
        balanceOf[to] += 1;
        nextSerial += 1;
    }

    function moveNFT(address from, address to, int64 serial) external {
        uint256 s = uint256(uint64(serial));
        require(ownerOf[s] == from, "MockNFT: not owner");
        ownerOf[s] = to;
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
    }

    function approve(address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "MockNFT: auth");
        getApproved[tokenId] = to;
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == from, "MockNFT: not owner");
        require(
            msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
            "MockNFT: auth"
        );
        ownerOf[tokenId] = to;
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
    }
}
