//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;



contract GovernanceManager {



    /** Master Of Protocol */

    address private _owner;



    // Is A Game Contract

    mapping ( address => bool ) private _isGame;



    // Is a contract that can play games on behalf of others

    mapping ( address => bool ) private _canPlayForOthers;



    // Is an admin that can call certain functions

    mapping ( address => bool ) private _isAdmin;



    // User Info Tracker

    address public userInfoTracker;



    // House Contract For PvH Games

    address public house;



    // Referral Contract

    address public referralManager;



    // Fee Manager

    address public feeReceiver;



    // Claim Manager Contract

    address public claimManager;



    // RNG Contract

    address public RNG;



    // Global Pause

    bool public paused;



    // Globally Tracked Game IDs -- mostly for front end viewing

    uint256[] public allGameIds;



    // onlyOwner modifier

    modifier onlyOwner() {

        require(msg.sender == _owner, 'Only Owner');

        _;

    }



    constructor(

        address owner_

    ) {

        // set ownership

        _owner = owner_;

    }



    function registerGameId(uint256 gameId) external onlyOwner {

        allGameIds.push(gameId);

    }



    function removeGameId(uint256 gameId) external onlyOwner {

        uint256 length = allGameIds.length;

        uint index = length;

        for (uint256 i = 0; i < length; i++) {

            if (allGameIds[i] == gameId) {

                index = i;

                break;

            }

        }

        require(index < length, 'Game ID Not Found');

        allGameIds[index] = allGameIds[length - 1];

        allGameIds.pop();

    }



    function setFeeReceiver(address newReceiver) external onlyOwner {

        feeReceiver = newReceiver;

    }



    function setClaimManager(address newClaimManager) external onlyOwner {

        require(newClaimManager != address(0), 'Zero Address');

        claimManager = newClaimManager;

    }



    function setCanPlayForOthers(address addr, bool canPlay) external onlyOwner {

        _canPlayForOthers[addr] = canPlay;

    }



    function setRNG(address newRNG) external onlyOwner {

        RNG = newRNG;

    }



    function setPaused(bool _paused) external onlyOwner {

        paused = _paused;

    }



    function setHouse(address house_) external onlyOwner {

        require(

            house_ != address(0),

            'Zero House'

        );

        house = house_;

    }



    function changeOwner(address newOwner) external onlyOwner {

        _owner = newOwner;

    }



    function setIsGame(address game, bool isGame_) external onlyOwner {

        _isGame[game] = isGame_;

    }



    function setIsAdmin(address admin, bool isAdmin_) external onlyOwner {

        _isAdmin[admin] = isAdmin_;

    }



    function setReferralManager(address newManager) external onlyOwner {

        referralManager = newManager;

    }



    function setUserInfoTracker(address newTracker) external onlyOwner {

        userInfoTracker = newTracker;

    }



    function getOwner() external view returns (address) {

        return _owner;

    }



    function owner() external view returns (address) {

        return _owner;

    }



    function isGame(address game) external view returns (bool) {

        return _isGame[game];

    }



    function isAdmin(address admin) external view returns (bool) {

        return _isAdmin[admin] || _owner == admin;

    }



    function canPlayForOthers(address addr) external view returns (bool) {

        return _canPlayForOthers[addr] || addr == claimManager;

    }



}
