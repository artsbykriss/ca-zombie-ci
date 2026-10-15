// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "./interfaces/IMagicSeaFactory.sol";
import "./MagicSeaPair.sol";

contract MagicSeaFactory is IMagicSeaFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(MagicSeaPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;

    uint256 public constant FEE_DENOMINATOR = 100000;
    uint256 public constant OWNER_FEE_SHARE_MAX = 50000; // 50%
    uint256 public override ownerFeeShare = 50000; // default value = 50%

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _feeToSetter) public {
        require(_feeToSetter != address(0), "MagicSea: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "MagicSea: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "MagicSea: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "MagicSea: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(MagicSeaPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMagicSeaPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev Updates the share of fees attributed to the owner (FeeManager)
     *
     * Must only be called by owner
     */
    function setOwnerFeeShare(uint256 newOwnerFeeShare) external {
        require(msg.sender == feeToSetter, "MagicSea: FORBIDDEN");
        require(newOwnerFeeShare > 0, "MagicSea: ownerFeeShare mustn't exceed minimum");
        require(newOwnerFeeShare <= OWNER_FEE_SHARE_MAX, "MagicSea: ownerFeeShare mustn't exceed maximum");
        // uint prevOwnerFeeShare = ownerFeeShare;
        ownerFeeShare = newOwnerFeeShare;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "MagicSea: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(_feeToSetter != address(0), "MagicSea: FORBIDDEN");
        require(msg.sender == feeToSetter, "MagicSea: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
