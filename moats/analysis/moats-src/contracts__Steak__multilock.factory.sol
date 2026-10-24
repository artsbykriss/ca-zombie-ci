// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./multilock.moat.sol";

contract MultiLockMoatFactory is Ownable {
    address[] public deployedContracts;

    address public adminWallet;
    address public feeReceiver;
    address public usdcToken;
    uint256 public deploymentFee;

    event ContractDeployed(
        address indexed deployer,
        address indexed contractAddress,
        address stakingToken
    );

    event AdminWalletUpdated(address indexed newAdminWallet);
    event FeeReceiverUpdated(address indexed newFeeReceiver);
    event DeploymentFeeUpdated(uint256 newFee);
    event UsdcTokenUpdated(address indexed newUsdcToken);

    constructor(
        address _adminWallet,
        address _feeReceiver,
        address _usdcToken,
        uint256 _deploymentFee
    ) Ownable() {
        require(_adminWallet != address(0), "Invalid admin wallet");
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_usdcToken != address(0), "Invalid USDC token");
        
        adminWallet = _adminWallet;
        feeReceiver = _feeReceiver;
        usdcToken = _usdcToken;
        deploymentFee = _deploymentFee;
    }

    function deployContract(address _stakingToken) external returns (address) {
        if (deploymentFee > 0) {
            require(usdcToken != address(0), "USDC token not set");
            require(feeReceiver != address(0), "Fee receiver not set");
            require(_stakingToken != address(0), "Invalid staking token");
            require(
                IERC20(usdcToken).allowance(msg.sender, address(this)) >=
                    deploymentFee,
                "Insufficient USDC allowance"
            );
            IERC20(usdcToken).transferFrom(
                msg.sender,
                feeReceiver,
                deploymentFee
            );
        }

        MultiLockMoat newContract = new MultiLockMoat(
            _stakingToken,
            feeReceiver,
            adminWallet
        );

        newContract.transferOwnership(msg.sender);

        // Store contract address
        deployedContracts.push(address(newContract));

        emit ContractDeployed(msg.sender, address(newContract), _stakingToken);

        return address(newContract);
    }

    function getDeployedContractsCount() external view returns (uint256) {
        return deployedContracts.length;
    }

    function getAllDeployedContracts()
        external
        view
        returns (address[] memory)
    {
        return deployedContracts;
    }

    function getDeployedContractsPaginated(
        uint256 _offset,
        uint256 _limit
    ) external view returns (address[] memory) {
        require(_offset < deployedContracts.length, "Invalid offset");

        uint256 end = _offset + _limit;
        if (end > deployedContracts.length) {
            end = deployedContracts.length;
        }

        address[] memory contracts = new address[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            contracts[i - _offset] = deployedContracts[i];
        }

        return contracts;
    }

    function isContractDeployed(
        address _contract
    ) external view returns (bool) {
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            if (deployedContracts[i] == _contract) {
                return true;
            }
        }
        return false;
    }

    function getContractAtIndex(
        uint256 _index
    ) external view returns (address) {
        require(_index < deployedContracts.length, "Index out of bounds");
        return deployedContracts[_index];
    }

    // Admin functions to update configuration
    function setAdminWallet(address _adminWallet) external onlyOwner {
        require(_adminWallet != address(0), "Invalid admin wallet");
        adminWallet = _adminWallet;
        emit AdminWalletUpdated(_adminWallet);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    function setDeploymentFee(uint256 _fee) external onlyOwner {
        deploymentFee = _fee; 
        emit DeploymentFeeUpdated(_fee);
    }

    function setUsdcToken(address _usdcToken) external onlyOwner {
        require(_usdcToken != address(0), "Invalid USDC token");
        usdcToken = _usdcToken;
        emit UsdcTokenUpdated(_usdcToken);
    }
}
