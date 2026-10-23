// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {Ownable} from "@solady/auth/Ownable.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {IPurrLP} from "./interfaces/IPurrLP.sol";
import {PurrLP} from "./PurrLP.sol";

/// @notice Create and register PurrLP pools
contract Factory is Ownable {
    event LogCreated(
        address clone_,
        address indexed baseToken_,
        address indexed quoteToken_,
        address indexed creator_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_
    );

    event LogPoolAdded(address baseToken, address quoteToken, address creator, address pool);
    event LogPoolRemoved(address pool);
    event LogSetImplementation(address indexed implementation);

    error ErrInvalidUserPoolIndex();
    error ErrZeroAddress();

    address public implementation;

    mapping(address creator => mapping(address pool => bool exists)) public poolExists;
    mapping(address base => mapping(address quote => address[] pools)) public pools;
    mapping(address creator => address[] pools) public userPools;

    constructor(address implementation_, address owner_) {
        if (implementation_ == address(0)) {
            revert ErrZeroAddress();
        }

        implementation = implementation_;
        _initializeOwner(owner_);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// VIEWS
    //////////////////////////////////////////////////////////////////////////////////////

    function getPoolCount(address token0, address token1) external view returns (uint256) {
        return pools[token0][token1].length;
    }

    function getUserPoolCount(address creator) external view returns (uint256) {
        return userPools[creator].length;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// PUBLIC
    //////////////////////////////////////////////////////////////////////////////////////

    function create(
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_,
        address oracle_
    ) external returns (address clone) {
        address creator = msg.sender;

        bytes32 salt = _computeSalt(creator, baseToken_, quoteToken_, lpFeeRate_, i_, k_, oracle_);
        clone = LibClone.cloneDeterministic(address(implementation), salt);
        IPurrLP(clone).init(address(baseToken_), address(quoteToken_), lpFeeRate_, i_, k_, oracle_);

        emit LogCreated(clone, baseToken_, quoteToken_, creator, lpFeeRate_, i_, k_);
        _addPool(creator, baseToken_, quoteToken_, clone);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// ADMIN
    //////////////////////////////////////////////////////////////////////////////////////

    function setLpImplementation(address implementation_) external onlyOwner {
        if (implementation_ == address(0)) {
            revert ErrZeroAddress();
        }

        implementation = implementation_;
        emit LogSetImplementation(implementation_);
    }

    /// @notice Register a pool to the list
    /// Note this doesn't check if the pool is valid or if it's already registered.
    function addPool(address creator, address baseToken, address quoteToken, address pool) external onlyOwner {
        _addPool(creator, baseToken, quoteToken, pool);
    }

    function removePool(
        address creator,
        address baseToken,
        address quoteToken,
        uint256 poolIndex,
        uint256 userPoolIndex
    ) external onlyOwner {
        address[] storage _pools = pools[baseToken][quoteToken];
        address pool = _pools[poolIndex];
        address[] storage _userPools = userPools[creator];

        _pools[poolIndex] = _pools[_pools.length - 1];
        _pools.pop();

        if (_userPools[userPoolIndex] != pool) {
            revert ErrInvalidUserPoolIndex();
        }

        _userPools[userPoolIndex] = _userPools[_userPools.length - 1];
        _userPools.pop();
        poolExists[creator][pool] = false;

        emit LogPoolRemoved(pool);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// INTERNALS
    //////////////////////////////////////////////////////////////////////////////////////

    function _addPool(address creator, address baseToken, address quoteToken, address pool) internal {
        pools[baseToken][quoteToken].push(pool);
        userPools[creator].push(pool);
        poolExists[creator][pool] = true;

        emit LogPoolAdded(baseToken, quoteToken, creator, pool);
    }

    function _computeSalt(
        address sender_,
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_,
        address oracle_
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(tx.origin, sender_, implementation, baseToken_, quoteToken_, lpFeeRate_, i_, k_, oracle_));
    }
}
