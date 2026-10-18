// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20V {
    function balanceOf(address) external view returns (uint256);
    function delegates(address) external view returns (address);
    function allowance(address, address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ISafe {
    function nonce() external view returns (uint256);
}

interface IGovernor {
    function quorumNumerator() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32)
        external payable returns (uint256);
}

/// Executed via eth_call state-override. When placed at the Timelock address,
/// address(this) == Timelock, so Safe.execTransaction sees msg.sender == owner.
contract Harness {
    address constant SAFE = 0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724;
    address constant KITE = 0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404;
    address constant FED2 = 0xfEd2eB6325432F0bF7110DcE2CCC5fF811ac3D4D;
    address constant OP = 0x4200000000000000000000000000000000000042;
    address constant X468C = 0x468c572c41DB8B206B3919AC9a41ad8dE2eAc822;
    address constant STAKING = 0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90;
    address constant GOV = 0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777;

    function runPayload(bytes calldata payload)
        external
        returns (
            bool ok,
            address delegatee,
            uint256 safeKite,
            uint256 fed2Kite,
            uint256 op468c,
            uint256 allowStaking,
            uint256 nonce
        )
    {
        (ok,) = SAFE.call(payload);
        delegatee = IERC20V(KITE).delegates(SAFE);
        safeKite = IERC20V(KITE).balanceOf(SAFE);
        fed2Kite = IERC20V(KITE).balanceOf(FED2);
        op468c = IERC20V(OP).balanceOf(X468C);
        allowStaking = IERC20V(KITE).allowance(SAFE, STAKING);
        nonce = ISafe(SAFE).nonce();
    }

    function runHardening(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calls,
        bytes32 descriptionHash
    )
        external
        returns (bool ok, uint256 qNum, uint256 threshold, uint256 vPeriod, uint256 supply)
    {
        (ok,) = GOV.call(
            abi.encodeWithSelector(
                IGovernor.execute.selector, targets, values, calls, descriptionHash
            )
        );
        qNum = IGovernor(GOV).quorumNumerator();
        threshold = IGovernor(GOV).proposalThreshold();
        vPeriod = IGovernor(GOV).votingPeriod();
        supply = IERC20V(KITE).totalSupply();
    }
}
