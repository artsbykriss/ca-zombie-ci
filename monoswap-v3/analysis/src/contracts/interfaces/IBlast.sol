/// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBlast{
    enum YieldMode {
        AUTOMATIC,
        VOID,
        CLAIMABLE
    }
    enum GasMode {
        VOID,
        CLAIMABLE 
    }
    function configure(YieldMode _yield, GasMode gasMode, address governor) external;
}
