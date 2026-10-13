/// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/IBlast.sol";
import "../interfaces/IBlastPoints.sol";

abstract contract BlastConfigure {
    address public blast;
    address public blastPoints;


    constructor(
        address _blast,
        address _blastPoints,
        address _operator
    )  {
        blast = _blast;
        blastPoints = _blastPoints;
        
        IBlast(_blast).configure(IBlast.YieldMode.CLAIMABLE, IBlast.GasMode.CLAIMABLE, _operator);
        IBlastPoints(blastPoints).configurePointsOperator(_operator);
    }

}