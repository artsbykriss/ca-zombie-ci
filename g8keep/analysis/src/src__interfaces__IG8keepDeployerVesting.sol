// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IG8keepDeployerVesting {
    function deploymentVest(address _deployer, uint256 _tokensToDeployer, uint256 _vestTime)
        external
        returns (uint256 vestingId);
}
