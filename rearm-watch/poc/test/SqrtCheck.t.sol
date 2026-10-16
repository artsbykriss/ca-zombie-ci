// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TickMath} from "../src/uniswap/TickMath.sol";

contract SqrtCheckTest is Test {
    function test_logSqrt() public {
        for (int24 t = 276322; t <= 276329; t++) {
            emit log_named_uint("sqrt at tick", uint256(uint160(TickMath.getSqrtPriceAtTick(t))));
            emit log_named_int("tick is", t);
        }
    }
}
