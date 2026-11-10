
// ===== .venv/lib/pypy3.11/site-packages/snekmate/utils/math.vy =====
# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Standard Mathematical Utility Functions
@custom:contract-name math
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@custom:coauthor bout3fiddy
@notice These functions implement standard mathematical utility
        functions that are missing in the Vyper language. If a
        function is inspired by an existing implementation, it
        is properly referenced in the function docstring. The
        following functions have been added for convenience:
        - `_uint256_average` (`internal` `pure` function),
        - `_int256_average` (`internal` `pure` function),
        - `_ceil_div` (`internal` `pure` function),
        - `_signum` (`internal` `pure` function),
        - `_mul_div` (`internal` `pure` function),
        - `_log2` (`internal` `pure` function),
        - `_log10` (`internal` `pure` function),
        - `_log256` (`internal` `pure` function),
        - `_wad_ln` (`internal` `pure` function),
        - `_wad_exp` (`internal` `pure` function),
        - `_cbrt` (`internal` `pure` function),
        - `_wad_cbrt` (`internal` `pure` function).
"""


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@pure
def _uint256_average(x: uint256, y: uint256) -> uint256:
    """
    @dev Returns the average of two 32-byte unsigned integers.
    @notice Note that the result is rounded towards zero. For
            more details on finding the average of two unsigned
            integers without an overflow, please refer to:
            https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223.
    @param x The first 32-byte unsigned integer of the data set.
    @param y The second 32-byte unsigned integer of the data set.
    @return uint256 The 32-byte average (rounded towards zero) of
            `x` and `y`.
    """
    return unsafe_add(x & y, (x ^ y) >> 1)


@internal
@pure
def _int256_average(x: int256, y: int256) -> int256:
    """
    @dev Returns the average of two 32-byte signed integers.
    @notice Note that the result is rounded towards infinity.
            For more details on finding the average of two signed
            integers without an overflow, please refer to:
            https://patents.google.com/patent/US6007232A/en.
    @param x The first 32-byte signed integer of the data set.
    @param y The second 32-byte signed integer of the data set.
    @return int256 The 32-byte average (rounded towards infinity)
            of `x` and `y`.
    """
    return unsafe_add(unsafe_add(x >> 1, y >> 1), x & y & 1)


@internal
@pure
def _ceil_div(x: uint256, y: uint256) -> uint256:
    """
    @dev Calculates "ceil(x / y)" for any strictly positive `y`.
    @notice The implementation is inspired by OpenZeppelin's
            implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte numerator.
    @param y The 32-byte denominator.
    @return uint256 The 32-byte rounded up result of "x/y".
    """
    assert y != empty(uint256), "math: ceil_div division by zero"
    # Due to a known compiler bug (https://github.com/vyperlang/vyper/issues/3480),
    # we use `0` instead of `empty(uint256)` as return value.
    return 0 if (x == empty(uint256)) else unsafe_add(unsafe_div(x - 1, y), 1)


@internal
@pure
def _signum(x: int256) -> int256:
    """
    @dev Returns the indication of the sign of a 32-byte signed integer.
    @notice The function returns `-1` if `x < 0`, `0` if `x == 0`, and `1`
            if `x > 0`. For more details on finding the sign of a signed
            integer, please refer to:
            https://graphics.stanford.edu/~seander/bithacks.html#CopyIntegerSign.
    @param x The 32-byte signed integer variable.
    @return int256 The 32-byte sign indication (`1`, `0`, or `-1`) of `x`.
    """
    return unsafe_sub(convert((x > empty(int256)), int256), convert((x < empty(int256)), int256))


@internal
@pure
def _mul_div(x: uint256, y: uint256, denominator: uint256, roundup: bool) -> uint256:
    """
    @dev Calculates "(x * y) / denominator" in 512-bit precision,
         following the selected rounding direction.
    @notice The implementation is inspired by Remco Bloemen's
            implementation under the MIT license here:
            https://xn--2-umb.com/21/muldiv.
            Furthermore, the rounding direction design pattern is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte multiplicand.
    @param y The 32-byte multiplier.
    @param denominator The 32-byte divisor.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    # Handle division by zero.
    assert denominator != empty(uint256), "math: mul_div division by zero"

    # 512-bit multiplication "[prod1 prod0] = x * y".
    # Compute the product "mod 2**256" and "mod 2**256 - 1".
    # Then use the Chinese Remainder theorem to reconstruct
    # the 512-bit result. The result is stored in two 256-bit
    # variables, where: "product = prod1 * 2**256 + prod0".
    mm: uint256 = uint256_mulmod(x, y, max_value(uint256))
    # The least significant 256 bits of the product.
    prod0: uint256 = unsafe_mul(x, y)
    # The most significant 256 bits of the product.
    prod1: uint256 = empty(uint256)

    if mm < prod0:
        prod1 = unsafe_sub(unsafe_sub(mm, prod0), 1)
    else:
        prod1 = unsafe_sub(mm, prod0)

    # Handling of non-overflow cases, 256 by 256 division.
    if prod1 == empty(uint256):
        if roundup and uint256_mulmod(x, y, denominator) != empty(uint256):
            # Calculate "ceil((x * y) / denominator)". The following
            # line cannot overflow because we have the previous check
            # "(x * y) % denominator != 0", which accordingly rules out
            # the possibility of "x * y = 2**256 - 1" and `denominator == 1`.
            return unsafe_add(unsafe_div(prod0, denominator), 1)

        return unsafe_div(prod0, denominator)

    # Ensure that the result is less than "2**256". Also,
    # prevents that `denominator == 0`.
    assert denominator > prod1, "math: mul_div overflow"

    #######################
    # 512 by 256 Division #
    #######################

    # Make division exact by subtracting the remainder
    # from "[prod1 prod0]". First, compute remainder using
    # the `uint256_mulmod` operation.
    remainder: uint256 = uint256_mulmod(x, y, denominator)

    # Second, subtract the 256-bit number from the 512-bit
    # number.
    if remainder > prod0:
        prod1 = unsafe_sub(prod1, 1)
    prod0 = unsafe_sub(prod0, remainder)

    # Factor powers of two out of the denominator and calculate
    # the largest power of two divisor of denominator. Always `>= 1`,
    # unless the denominator is zero (which is prevented above),
    # in which case `twos` is zero. For more details, please refer to:
    # https://cs.stackexchange.com/q/138556.
    twos: uint256 = unsafe_sub(empty(uint256), denominator) & denominator
    # Divide denominator by `twos`.
    denominator_div: uint256 = unsafe_div(denominator, twos)
    # Divide "[prod1 prod0]" by `twos`.
    prod0 = unsafe_div(prod0, twos)
    # Flip `twos` such that it is "2**256 / twos". If `twos` is zero,
    # it becomes one.
    twos = unsafe_add(unsafe_div(unsafe_sub(empty(uint256), twos), twos), 1)

    # Shift bits from `prod1` to `prod0`.
    prod0 |= unsafe_mul(prod1, twos)

    # Invert the denominator "mod 2**256". Since the denominator is
    # now an odd number, it has an inverse modulo "2**256", so we have:
    # "denominator * inverse = 1 mod 2**256". Calculate the inverse by
    # starting with a seed that is correct for four bits. That is,
    # "denominator * inverse = 1 mod 2**4".
    inverse: uint256 = unsafe_mul(3, denominator_div) ^ 2

    # Use Newton-Raphson iteration to improve accuracy. Thanks to Hensel's
    # lifting lemma, this also works in modular arithmetic by doubling the
    # correct bits in each step.
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**8".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**16".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**32".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**64".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**128".
    inverse = unsafe_mul(inverse, unsafe_sub(2, unsafe_mul(denominator_div, inverse))) # Inverse "mod 2**256".

    # Since the division is now exact, we can divide by multiplying
    # with the modular inverse of the denominator. This returns the
    # correct result modulo "2**256". Since the preconditions guarantee
    # that the result is less than "2**256", this is the final result.
    # We do not need to calculate the high bits of the result and
    # `prod1` is no longer necessary.
    result: uint256 = unsafe_mul(prod0, inverse)

    if roundup and uint256_mulmod(x, y, denominator) != empty(uint256):
        # Calculate "ceil((x * y) / denominator)". The following
        # line uses intentionally checked arithmetic to prevent
        # a theoretically possible overflow.
        result += 1

    return result


@internal
@pure
def _log2(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 2 of `x`, following the selected
         rounding direction.
    @notice Note that it returns `0` if given `0`. The implementation
            is inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(uint256):
        return empty(uint256)

    value: uint256 = x
    result: uint256 = empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log2(max_value(uint256)) < max_value(uint256)`.
    if x >> 128 != empty(uint256):
        x >>= 128
        result = 128
    if x >> 64 != empty(uint256):
        x >>= 64
        result = unsafe_add(result, 64)
    if x >> 32 != empty(uint256):
        x >>= 32
        result = unsafe_add(result, 32)
    if x >> 16 != empty(uint256):
        x >>= 16
        result = unsafe_add(result, 16)
    if x >> 8 != empty(uint256):
        x >>= 8
        result = unsafe_add(result, 8)
    if x >> 4 != empty(uint256):
        x >>= 4
        result = unsafe_add(result, 4)
    if x >> 2 != empty(uint256):
        x >>= 2
        result = unsafe_add(result, 2)
    if x >> 1 != empty(uint256):
        result = unsafe_add(result, 1)

    if roundup and (1 << result) < value:
        result = unsafe_add(result, 1)

    return result


@internal
@pure
def _log10(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 10 of `x`, following the selected
         rounding direction.
    @notice Note that it returns `0` if given `0`. The implementation
            is inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(uint256):
        return empty(uint256)

    value: uint256 = x
    result: uint256 = empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log10(max_value(uint256)) < max_value(uint256)`.
    if x >= 10 ** 64:
        x = unsafe_div(x, 10 ** 64)
        result = 64
    if x >= 10 ** 32:
        x = unsafe_div(x, 10 ** 32)
        result = unsafe_add(result, 32)
    if x >= 10 ** 16:
        x = unsafe_div(x, 10 ** 16)
        result = unsafe_add(result, 16)
    if x >= 10 ** 8:
        x = unsafe_div(x, 10 ** 8)
        result = unsafe_add(result, 8)
    if x >= 10 ** 4:
        x = unsafe_div(x, 10 ** 4)
        result = unsafe_add(result, 4)
    if x >= 10 ** 2:
        x = unsafe_div(x, 10 ** 2)
        result = unsafe_add(result, 2)
    if x >= 10:
        result = unsafe_add(result, 1)

    if roundup and (10 ** result) < value:
        result = unsafe_add(result, 1)

    return result


@internal
@pure
def _log256(x: uint256, roundup: bool) -> uint256:
    """
    @dev Returns the log in base 256 of `x`, following the selected
         rounding direction.
    @notice Note that it returns `0` if given `0`. Also, adding one to the
            rounded down result gives the number of pairs of hex symbols
            needed to represent `x` as a hex string. The implementation is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
    @param x The 32-byte variable.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return uint256 The 32-byte calculation result.
    """
    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(uint256):
        return empty(uint256)

    value: uint256 = x
    result: uint256 = empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log256(max_value(uint256)) < max_value(uint256)`.
    if x >> 128 != empty(uint256):
        x >>= 128
        result = 16
    if x >> 64 != empty(uint256):
        x >>= 64
        result = unsafe_add(result, 8)
    if x >> 32 != empty(uint256):
        x >>= 32
        result = unsafe_add(result, 4)
    if x >> 16 != empty(uint256):
        x >>= 16
        result = unsafe_add(result, 2)
    if x >> 8 != empty(uint256):
        result = unsafe_add(result, 1)

    if roundup and (1 << (result << 3)) < value:
        result = unsafe_add(result, 1)

    return result


@internal
@pure
def _wad_ln(x: int256) -> int256:
    """
    @dev Calculates the natural logarithm of a signed integer with a
         precision of 1e18.
    @notice Note that it returns `0` if given `0`. Furthermore, this function
            consumes about 1,400 to 1,650 gas units depending on the value
            of `x`. The implementation is inspired by Remco Bloemen's
            implementation under the MIT license here:
            https://xn--2-umb.com/22/exp-ln.
    @param x The 32-byte variable.
    @return int256 The 32-byte calculation result.
    """
    assert x >= empty(int256), "math: wad_ln undefined"

    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(int256):
        return empty(int256)

    # We want to convert `x` from "10**18" fixed point to "2**96"
    # fixed point. We do this by multiplying by "2**96 / 10**18".
    # But since "ln(x * C) = ln(x) + ln(C)" holds, we can just do
    # nothing here and add "ln(2**96 / 10**18)" at the end.

    # Reduce the range of `x` to "(1, 2) * 2**96".
    # Also remember that "ln(2**k * x) = k * ln(2) + ln(x)" holds.
    k: int256 = unsafe_sub(convert(self._log2(convert(x, uint256), False), int256), 96)
    # Note that to circumvent Vyper's safecast feature for the potentially
    # negative expression `x <<= uint256(159 - k)`, we first convert the
    # expression `x <<= uint256(159 - k)` to `bytes32` and subsequently
    # to `uint256`. Remember that the EVM default behaviour is to use two's
    # complement representation to handle signed integers.
    x = convert(convert(convert(x << convert(unsafe_sub(159, k), uint256), bytes32), uint256) >> 159, int256)

    # Evaluate using a "(8, 8)"-term rational approximation. Since `p` is monic,
    # we will multiply by a scaling factor later.
    p: int256 = unsafe_add(
        unsafe_mul(unsafe_add(x, 3_273_285_459_638_523_848_632_254_066_296), x) >> 96,
        24_828_157_081_833_163_892_658_089_445_524,
    )
    p = unsafe_add(unsafe_mul(p, x) >> 96, 43_456_485_725_739_037_958_740_375_743_393)
    p = unsafe_sub(unsafe_mul(p, x) >> 96, 11_111_509_109_440_967_052_023_855_526_967)
    p = unsafe_sub(unsafe_mul(p, x) >> 96, 45_023_709_667_254_063_763_336_534_515_857)
    p = unsafe_sub(unsafe_mul(p, x) >> 96, 14_706_773_417_378_608_786_704_636_184_526)
    p = unsafe_sub(unsafe_mul(p, x), 795_164_235_651_350_426_258_249_787_498 << 96)

    # We leave `p` in the "2**192" base so that we do not have to scale it up
    # again for the division. Note that `q` is monic by convention.
    q: int256 = unsafe_add(
        unsafe_mul(unsafe_add(x, 5_573_035_233_440_673_466_300_451_813_936), x) >> 96,
        71_694_874_799_317_883_764_090_561_454_958,
    )
    q = unsafe_add(unsafe_mul(q, x) >> 96, 283_447_036_172_924_575_727_196_451_306_956)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 401_686_690_394_027_663_651_624_208_769_553)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 204_048_457_590_392_012_362_485_061_816_622)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 31_853_899_698_501_571_402_653_359_427_138)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 909_429_971_244_387_300_277_376_558_375)

    # It is known that the polynomial `q` has no zeros in the domain.
    # No scaling is required, as `p` is already "2**96" too large. Also,
    # `r` is in the range "(0, 0.125) * 2**96" after the division.
    r: int256 = unsafe_div(p, q)

    # To finalise the calculation, we have to proceed with the following steps:
    #   - multiply by the scaling factor "s = 5.549...",
    #   - add "ln(2**96 / 10**18)",
    #   - add "k * ln(2)", and
    #   - multiply by "10**18 / 2**96 = 5**18 >> 78".
    # In order to perform the most gas-efficient calculation, we carry out all
    # these steps in one expression.
    return (
        unsafe_add(
            unsafe_add(
                unsafe_mul(r, 1_677_202_110_996_718_588_342_820_967_067_443_963_516_166),
                unsafe_mul(
                    k, 16_597_577_552_685_614_221_487_285_958_193_947_469_193_820_559_219_878_177_908_093_499_208_371
                ),
            ),
            600_920_179_829_731_861_736_702_779_321_621_459_595_472_258_049_074_101_567_377_883_020_018_308,
        )
        >> 174
    )


@internal
@pure
def _wad_exp(x: int256) -> int256:
    """
    @dev Calculates the natural exponential function of a signed integer with
         a precision of 1e18.
    @notice Note that this function consumes about 810 gas units. The implementation
            is inspired by Remco Bloemen's implementation under the MIT license here:
            https://xn--2-umb.com/22/exp-ln.
    @param x The 32-byte variable.
    @return int256 The 32-byte calculation result.
    """
    # If the result is `< 1`, we return zero. This happens when we have the following:
    # "x <= (log(1e-18) * 1e18) ~ -4.15e19".
    if x <= -41_446_531_673_892_822_313:
        return empty(int256)

    # When the result is "> (2**255 - 1) / 1e18" we cannot represent it as a signed integer.
    # This happens when "x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135".
    assert x < 135_305_999_368_893_231_589, "math: wad_exp overflow"

    # `x` is now in the range "(-42, 136) * 1e18". Convert to "(-42, 136) * 2**96" for higher
    # intermediate precision and a binary base. This base conversion is a multiplication with
    # "1e18 / 2**96 = 5**18 / 2**78".
    x = unsafe_div(x << 78, 5 ** 18)

    # Reduce the range of `x` to "(-½ ln 2, ½ ln 2) * 2**96" by factoring out powers of two
    # so that "exp(x) = exp(x') * 2**k", where `k` is a signer integer. Solving this gives
    # "k = round(x / log(2))" and "x' = x - k * log(2)". Thus, `k` is in the range "[-61, 195]".
    k: int256 = unsafe_add(unsafe_div(x << 96, 54_916_777_467_707_473_351_141_471_128), 2 ** 95) >> 96
    x = unsafe_sub(x, unsafe_mul(k, 54_916_777_467_707_473_351_141_471_128))

    # Evaluate using a "(6, 7)"-term rational approximation. Since `p` is monic,
    # we will multiply by a scaling factor later.
    y: int256 = unsafe_add(
        unsafe_mul(unsafe_add(x, 1_346_386_616_545_796_478_920_950_773_328), x) >> 96,
        57_155_421_227_552_351_082_224_309_758_442,
    )
    p: int256 = unsafe_add(
        unsafe_mul(
            unsafe_add(
                unsafe_mul(unsafe_sub(unsafe_add(y, x), 94_201_549_194_550_492_254_356_042_504_812), y) >> 96,
                28_719_021_644_029_726_153_956_944_680_412_240,
            ),
            x,
        ),
        4_385_272_521_454_847_904_659_076_985_693_276 << 96,
    )

    # We leave `p` in the "2**192" base so that we do not have to scale it up
    # again for the division.
    q: int256 = unsafe_add(
        unsafe_mul(unsafe_sub(x, 2_855_989_394_907_223_263_936_484_059_900), x) >> 96,
        50_020_603_652_535_783_019_961_831_881_945,
    )
    q = unsafe_sub(unsafe_mul(q, x) >> 96, 533_845_033_583_426_703_283_633_433_725_380)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 3_604_857_256_930_695_427_073_651_918_091_429)
    q = unsafe_sub(unsafe_mul(q, x) >> 96, 14_423_608_567_350_463_180_887_372_962_807_573)
    q = unsafe_add(unsafe_mul(q, x) >> 96, 26_449_188_498_355_588_339_934_803_723_976_023)

    # The polynomial `q` has no zeros in the range because all its roots are complex.
    # No scaling is required, as `p` is already "2**96" too large. Also,
    # `r` is in the range "(0.09, 0.25) * 2**96" after the division.
    r: int256 = unsafe_div(p, q)

    # To finalise the calculation, we have to multiply `r` by:
    #   - the scale factor "s = ~6.031367120",
    #   - the factor "2**k" from the range reduction, and
    #   - the factor "1e18 / 2**96" for the base conversion.
    # We do this all at once, with an intermediate result in "2**213" base,
    # so that the final right shift always gives a positive value.

    # Note that to circumvent Vyper's safecast feature for the potentially
    # negative parameter value `r`, we first convert `r` to `bytes32` and
    # subsequently to `uint256`. Remember that the EVM default behaviour is
    # to use two's complement representation to handle signed integers.
    return convert(
        unsafe_mul(
            convert(convert(r, bytes32), uint256), 3_822_833_074_963_236_453_042_738_258_902_158_003_155_416_615_667
        )
        >> convert(unsafe_sub(195, k), uint256),
        int256,
    )


@internal
@pure
def _cbrt(x: uint256, roundup: bool) -> uint256:
    """
    @dev Calculates the cube root of an unsigned integer.
    @notice Note that this function consumes about 1,600 to 1,800 gas units
            depending on the value of `x` and `roundup`. The implementation is
            inspired by Curve Finance's implementation under the MIT license here:
            https://github.com/curvefi/tricrypto-ng/blob/main/contracts/main/CurveCryptoMathOptimized3.vy.
    @param x The 32-byte variable from which the cube root is calculated.
    @param roundup The Boolean variable that specifies whether
           to round up or not. The default `False` is round down.
    @return The 32-byte cube root of `x`.
    """
    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(uint256):
        return empty(uint256)

    y: uint256 = unsafe_div(self._wad_cbrt(x), 10 ** 12)

    if roundup and unsafe_mul(unsafe_mul(y, y), y) != x:
        y = unsafe_add(y, 1)

    return y


@internal
@pure
def _wad_cbrt(x: uint256) -> uint256:
    """
    @dev Calculates the cube root of an unsigned integer with a precision
         of 1e18.
    @notice Note that this function consumes about 1,500 to 1,700 gas units
            depending on the value of `x`. The implementation is inspired
            by Curve Finance's implementation under the MIT license here:
            https://github.com/curvefi/tricrypto-ng/blob/main/contracts/main/CurveCryptoMathOptimized3.vy.
    @param x The 32-byte variable from which the cube root is calculated.
    @return The 32-byte cubic root of `x` with a precision of 1e18.
    """
    # For the special case `x == 0`, we already return `0` here in order
    # not to iterate through the remaining code.
    if x == empty(uint256):
        return empty(uint256)

    # Since this cube root is for numbers with base 1e18, we have to scale
    # the input by 1e36 to increase the precision. This leads to an overflow
    # for very large numbers. So we conditionally sacrifice precision.
    value: uint256 = empty(uint256)
    if x >= unsafe_mul(unsafe_div(max_value(uint256), 10 ** 36), 10 ** 18):
        value = x
    elif x >= unsafe_div(max_value(uint256), 10 ** 36):
        value = unsafe_mul(x, 10 ** 18)
    else:
        value = unsafe_mul(x, 10 ** 36)

    # Compute the binary logarithm of `value`.
    log2x: uint256 = self._log2(value, False)

    # If we divide log2x by 3, the remainder is "log2x % 3". So if we simply
    # multiply "2**(log2x/3)" and discard the remainder to calculate our guess,
    # the Newton-Raphson method takes more iterations to converge to a solution
    # because it lacks this precision. A few more calculations now in order to
    # do fewer calculations later:
    #   - "pow = log2(x) // 3" (the operator `//` means integer division),
    #   - "remainder = log2(x) % 3",
    #   - "initial_guess = 2**pow * cbrt(2)**remainder".
    # Now substituting "2 = 1.26 ≈ 1,260 / 1,000", we get:
    #   - "initial_guess = 2**pow * 1,260**remainder // 1,000**remainder".
    remainder: uint256 = log2x % 3
    y: uint256 = unsafe_div(
        unsafe_mul(pow_mod256(2, unsafe_div(log2x, 3)), pow_mod256(1_260, remainder)), pow_mod256(1_000, remainder)
    )

    # Since we have chosen good initial values for the cube roots, 7 Newton-Raphson
    # iterations are just sufficient. 6 iterations would lead to non-convergences,
    # and 8 would be one iteration too many. Without initial values, the iteration
    # number can be up to 20 or more. The iterations are unrolled. This reduces the
    # gas cost, but requires more bytecode.
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)
    y = unsafe_div(unsafe_add(unsafe_mul(2, y), unsafe_div(value, unsafe_mul(y, y))), 3)

    # Since we scaled up, we have to scale down accordingly.
    if x >= unsafe_mul(unsafe_div(max_value(uint256), 10 ** 36), 10 ** 18):
        return unsafe_mul(y, 10 ** 12)
    elif x >= unsafe_div(max_value(uint256), 10 ** 36):
        return unsafe_mul(y, 10 ** 6)

    return y

// ===== contracts/AMM.vy =====
# @version 0.4.3
"""
@title LEVAMM
@notice Automatic market maker which keeps constant leverage
@author Scientia Spectra AG
@license Copyright (c) 2025
"""
from snekmate.utils import math


interface IERC20:
    def decimals() -> uint256: view
    def approve(_to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(user: address) -> uint256: view

interface PriceOracle:
    def price_w() -> uint256: nonpayable
    def price() -> uint256: view

interface LT:
    def distribute_borrower_fees(): nonpayable


struct AMMState:
    collateral: uint256
    debt: uint256
    x0: uint256

struct Pair:
    collateral: uint256
    debt: uint256

struct OraclizedValue:
    p_o: uint256
    value: uint256


LEVERAGE: public(immutable(uint256))
LEV_RATIO: immutable(uint256)
MIN_SAFE_DEBT: immutable(uint256)
MAX_SAFE_DEBT: immutable(uint256)
LT_CONTRACT: public(immutable(address))
COLLATERAL: public(immutable(IERC20))
STABLECOIN: public(immutable(IERC20))
PRICE_ORACLE_CONTRACT: public(immutable(PriceOracle))

COLLATERAL_PRECISION: immutable(uint256)

MAX_FEE: constant(uint256) = 10**17
fee: public(uint256)

MAX_RATE: constant(uint256) = 10**18 // (365 * 86400)  # Not more than 100% APR

collateral_amount: public(uint256)
debt: uint256
rate: public(uint256)
rate_mul: public(uint256)
rate_time: uint256

minted: public(uint256)
redeemed: public(uint256)

is_killed: public(bool)


event TokenExchange:
    buyer: indexed(address)
    sold_id: uint256
    tokens_sold: uint256
    bought_id: uint256
    tokens_bought: uint256
    fee: uint256
    price_oracle: uint256

event AddLiquidityRaw:
    token_amounts: uint256[2]
    invariant: uint256
    price_oracle: uint256

event RemoveLiquidityRaw:
    collateral_change: uint256
    debt_change: uint256

event SetRate:
    rate: uint256
    rate_mul: uint256
    time: uint256

event CollectFees:
    amount: uint256
    new_supply: uint256

event SetFee:
    fee: uint256

event SetKilled:
    is_killed: bool


@deploy
def __init__(lt_contract: address,
             stablecoin: IERC20, collateral: IERC20, leverage: uint256,
             fee: uint256, price_oracle_contract: PriceOracle):
    LT_CONTRACT = lt_contract
    STABLECOIN = stablecoin
    COLLATERAL = collateral
    LEVERAGE = leverage
    assert fee <= MAX_FEE, "Fee too high"
    self.fee = fee
    PRICE_ORACLE_CONTRACT = price_oracle_contract

    COLLATERAL_PRECISION = 10**(18 - staticcall COLLATERAL.decimals())
    assert staticcall STABLECOIN.decimals() == 18
    assert leverage > 10**18

    denominator: uint256 = 2 * leverage - 10**18
    LEV_RATIO = leverage**2 * 10**18 // denominator**2

    # 1 / (4 * L**2)
    MIN_SAFE_DEBT = 10**54 // (4 * leverage**2)
    # (2 * L - 1)**2 / (4 * L**2) - 1 / (8 * L**2)
    MAX_SAFE_DEBT = denominator**2 * 10**18 // (4 * leverage**2) - 10**54 // (8 * leverage**2)

    self.rate_mul = 10**18
    self.rate_time = block.timestamp

    extcall stablecoin.approve(LT_CONTRACT, max_value(uint256), default_return_value=True)
    extcall collateral.approve(LT_CONTRACT, max_value(uint256), default_return_value=True)


# Math
@internal
@pure
def sqrt(arg: uint256) -> uint256:
    return isqrt(arg)


@internal
@view
def get_x0(p_oracle: uint256, collateral: uint256, debt: uint256, safe_limits: bool) -> uint256:
    # Safe limits:
    # debt >= 0
    # debt <= coll_value * 10**18 // (4 * LEV_RATIO)  ( == 9 / 16 * coll_value)
    # debt in equilibrium = coll_value * (LEVERAGE - 1.0) / LEVERAGE  ( == 1/2 * coll_value)
    # When L=2, critical value of debt corresponds to p_amm = 9/16 * p_o
    # Just in case, we limit between (1/16 .. 8.5/16) which is a somewaht tighter range

    coll_value: uint256 = p_oracle * collateral * COLLATERAL_PRECISION // 10**18

    if safe_limits:
        assert debt >= coll_value * MIN_SAFE_DEBT // 10**18, "Unsafe min"
        assert debt <= coll_value * MAX_SAFE_DEBT // 10**18, "Unsafe max"

    D: uint256 = coll_value**2 - 4 * coll_value * LEV_RATIO // 10**18 * debt
    return (coll_value + self.sqrt(D)) * 10**18 // (2 * LEV_RATIO)
###


@internal
@view
def _rate_mul() -> uint256:
    """
    @notice Rate multiplier which is 1.0 + integral(rate, dt)
    @return Rate multiplier in units where 1.0 == 1e18
    """
    return unsafe_div(self.rate_mul * (10**18 + self.rate * (block.timestamp - self.rate_time)), 10**18)


@external
@view
def get_rate_mul() -> uint256:
    """
    @notice Rate multiplier which is 1.0 + integral(rate, dt)
    @return Rate multiplier in units where 1.0 == 1e18
    """
    return self._rate_mul()


@external
@nonreentrant
def set_rate(rate: uint256) -> uint256:
    """
    @notice Set interest rate. That affects the dependence of AMM base price over time
    @param rate New rate in units of int(fraction * 1e18) per second
    @return rate_mul multiplier (e.g. 1.0 + integral(rate, dt))
    """
    assert msg.sender == LT_CONTRACT, "Access"
    assert rate <= MAX_RATE, "Rate too high"
    rate_mul: uint256 = self._rate_mul()
    self.debt = self.debt * rate_mul // self.rate_mul
    self.rate_mul = rate_mul
    self.rate_time = block.timestamp
    self.rate = rate
    log SetRate(rate=rate, rate_mul=rate_mul, time=block.timestamp)
    return rate_mul


@internal
@view
def _debt() -> uint256:
    return self.debt * self._rate_mul() // self.rate_mul


@internal
def _debt_w() -> uint256:
    rate_mul: uint256 = self._rate_mul()
    debt: uint256 = self.debt * rate_mul // self.rate_mul
    self.rate_mul = rate_mul
    self.rate_time = block.timestamp
    return debt


@external
@view
def get_debt() -> uint256:
    """
    @notice Debt of the AMM
    """
    return self._debt()


@external
@view
def outdated_debt() -> uint256:
    return self.debt


@external
@view
def get_state() -> AMMState:
    """
    @notice State of the AMM
    @return Returns a data strucuture which contains (collateral, debt, x0)
    """
    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    state: AMMState = empty(AMMState)
    state.collateral = self.collateral_amount
    state.debt = self._debt()
    state.x0 = self.get_x0(p_o, state.collateral, state.debt, False)
    return state


@external
@view
def get_dy(i: uint256, j: uint256, in_amount: uint256) -> uint256:
    """
    @notice Function to preview the result of exchange in the AMM
    @param i Index of input coin (0 = stablecoin, 1 = LP token collateral)
    @param j Index of output coin
    @param in_amount Amount of coin i
    @return Amount of coin j to be received
    """
    assert (i == 0 and j == 1) or (i == 1 and j == 0)

    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    collateral: uint256 = self.collateral_amount  # == y_initial
    debt: uint256 = self._debt()
    x_initial: uint256 = self.get_x0(p_o, collateral, debt, False) - debt

    if i == 0:  # Buy collateral
        assert in_amount <= debt, "Amount too large"
        x: uint256 = x_initial + in_amount
        y: uint256 = math._ceil_div(x_initial * collateral, x)
        return (collateral - y) * (10**18 - self.fee) // 10**18

    else:  # Sell collateral
        y: uint256 = collateral + in_amount
        x: uint256 = math._ceil_div(x_initial * collateral, y)
        return (x_initial - x) * (10**18 - self.fee) // 10**18


@external
@view
def get_p() -> uint256:
    """
    @notice Returns state price of the AMM itself
    """
    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    collateral: uint256 = self.collateral_amount
    debt: uint256 = self._debt()
    return (self.get_x0(p_o, collateral, debt, False) - debt) * (10**18 // COLLATERAL_PRECISION) // collateral


@external
@nonreentrant
def exchange(i: uint256, j: uint256, in_amount: uint256, min_out: uint256, _for: address = msg.sender) -> uint256:
    """
    @notice Exchanges two coins, callable by anyone
    @param i Index of input coin (0 = stablecoin, 1 = LP token collateral)
    @param j Output coin index
    @param in_amount Amount of input coin to swap
    @param min_out Minimal amount to get as output
    @param _for Address to send coins to
    @return Amount of coins given in/out
    """
    assert (i == 0 and j == 1) or (i == 1 and j == 0)
    assert not self.is_killed

    collateral: uint256 = self.collateral_amount  # == y_initial
    assert collateral > 0, "Empty AMM"
    debt: uint256 = self._debt_w()
    p_o: uint256 = extcall PRICE_ORACLE_CONTRACT.price_w()
    x0: uint256 = self.get_x0(p_o, collateral, debt, False)
    x_initial: uint256 = x0 - debt

    out_amount: uint256 = 0
    fee: uint256 = self.fee

    coll_vs_debt_before: uint256 = unsafe_div(p_o * collateral * COLLATERAL_PRECISION, debt)
    if debt == 0:
        coll_vs_debt_before = max_value(uint256)

    if i == 0:  # Trader buys collateral from us
        x: uint256 = x_initial + in_amount
        y: uint256 = math._ceil_div(x_initial * collateral, x)
        out_amount = (collateral - y) * (10**18 - fee) // 10**18
        assert out_amount >= min_out, "Slippage"
        debt -= in_amount
        collateral -= out_amount
        self.redeemed += in_amount
        assert extcall STABLECOIN.transferFrom(msg.sender, self, in_amount, default_return_value=True)
        assert extcall COLLATERAL.transfer(_for, out_amount, default_return_value=True)

    else:  # Trader sells collateral to us
        y: uint256 = collateral + in_amount
        x: uint256 = math._ceil_div(x_initial * collateral, y)
        out_amount = (x_initial - x) * (10**18 - fee) // 10**18
        assert out_amount >= min_out, "Slippage"
        debt += out_amount
        self.minted += out_amount
        collateral = y
        assert extcall COLLATERAL.transferFrom(msg.sender, self, in_amount, default_return_value=True)
        assert extcall STABLECOIN.transfer(_for, out_amount, default_return_value=True)

    # Depending on asymmetry decide on the math control
    coll_vs_debt_after: uint256 = unsafe_div(p_o * collateral * COLLATERAL_PRECISION, debt)
    if debt == 0:
        coll_vs_debt_after = max_value(uint256)

    check_state: bool = True # Init here separately
    if coll_vs_debt_after > 2 * 10**18:
        if coll_vs_debt_before > coll_vs_debt_after:
            # We improved -> relax the check
            check_state = False
    else:
        if coll_vs_debt_before < coll_vs_debt_after:
            # We improved -> relax the check
            check_state = False

    # This call also will not allow to get too close to the untradable region
    assert self.get_x0(p_o, collateral, debt, check_state) >= x0, "Bad final state"

    self.collateral_amount = collateral
    self.debt = debt

    log TokenExchange(buyer=msg.sender, sold_id=i, tokens_sold=in_amount,
                      bought_id=j, tokens_bought=out_amount, fee=fee, price_oracle=p_o)

    if LT_CONTRACT != empty(address) and LT_CONTRACT.is_contract:
        self._collect_fees()
        extcall LT(LT_CONTRACT).distribute_borrower_fees()

    return out_amount


@external
def _deposit(d_collateral: uint256, d_debt: uint256) -> OraclizedValue:
    assert msg.sender == LT_CONTRACT, "Access violation"
    assert not self.is_killed

    p_o: uint256 = extcall PRICE_ORACLE_CONTRACT.price_w()
    collateral: uint256 = self.collateral_amount  # == y_initial
    debt: uint256 = self._debt_w()

    debt += d_debt
    collateral += d_collateral
    self.minted += d_debt

    self.debt = debt
    self.collateral_amount = collateral
    # Assume that transfer of collateral happened already (as a result of exchange)

    value_after: uint256 = self.get_x0(p_o, collateral, debt, True) * 10**18 // (2 * LEVERAGE - 10**18)  # Value in fiat

    log AddLiquidityRaw(token_amounts=[d_collateral, d_debt], invariant=value_after, price_oracle=p_o)
    return OraclizedValue(p_o=p_o, value=value_after)


@external
def _withdraw(frac: uint256) -> Pair:
    assert msg.sender == LT_CONTRACT, "Access violation"

    collateral: uint256 = self.collateral_amount  # == y_initial
    debt: uint256 = self._debt_w()

    d_collateral: uint256 = collateral * frac // 10**18
    d_debt: uint256 = math._ceil_div(debt * frac, 10**18)

    self.collateral_amount -= d_collateral
    self.debt = debt - d_debt
    self.redeemed += d_debt

    log RemoveLiquidityRaw(collateral_change=d_collateral, debt_change=d_debt)

    return Pair(collateral=d_collateral, debt=d_debt)


@external
@view
def coins(i: uint256) -> IERC20:
    """
    @notice Coins in the AMM: 0 - stablecoin, 1 - collateral (LP)
    """
    return [STABLECOIN, COLLATERAL][i]


@external
@view
def value_oracle() -> OraclizedValue:
    """
    @notice Non-manipulable oracle which shows value of the whole AMM valued in stablecoin
    """
    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    collateral: uint256 = self.collateral_amount  # == y_initial
    debt: uint256 = self._debt()
    return OraclizedValue(p_o=p_o, value=self.get_x0(p_o, collateral, debt, False) * 10**18 // (2 * LEVERAGE - 10**18))


@external
@view
def value_oracle_for(collateral: uint256, debt: uint256) -> OraclizedValue:
    """
    @notice Total value oracle for any specified amounts of collateral and debt in the AMM
    """
    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    return OraclizedValue(p_o=p_o, value=self.get_x0(p_o, collateral, debt, False) * 10**18 // (2 * LEVERAGE - 10**18))


@external
@view
def value_change(collateral_amount: uint256, borrowed_amount: uint256, is_deposit: bool) -> OraclizedValue:
    """
    @notice Change in the value oracle
    @param collateral_amount Amount of collateral to deposit/withdraw to AMM
    @param borrowed_amount Amount to borrow or repay when depositing/withdrawing
    @param is_deposit Is it a deposit or withdrawal
    @return (p_oracle, value)
    """
    p_o: uint256 = staticcall PRICE_ORACLE_CONTRACT.price()
    collateral: uint256 = self.collateral_amount  # == y_initial
    debt: uint256 = self._debt()

    if is_deposit:
        collateral += collateral_amount
        debt += borrowed_amount
    else:
        collateral -= collateral_amount
        debt -= borrowed_amount

    x0_after: uint256 = self.get_x0(p_o, collateral, debt, is_deposit)

    return OraclizedValue(
        p_o = p_o,
        value = x0_after * 10**18 // (2 * LEVERAGE - 10**18))


@external
@view
def max_debt() -> uint256:
    """
    @notice Maximum amount of debt which the AMM can possibly take
    """
    return staticcall STABLECOIN.balanceOf(self) + self._debt()


@external
@view
def accumulated_interest() -> uint256:
    """
    @notice Calculate the amount of fees obtained from the interest
    """
    minted: uint256 = self.minted
    return unsafe_sub(max(self._debt() + self.redeemed, minted), minted)


@internal
def _collect_fees() -> uint256:
    """
    @notice Collect the fees charged as interest.
    """
    assert not self.is_killed

    debt: uint256 = self._debt_w()
    self.debt = debt
    minted: uint256 = self.minted
    to_be_redeemed: uint256 = debt + self.redeemed
    # Difference between to_be_redeemed and minted amount is exactly due to interest charged
    if to_be_redeemed > minted:
        self.minted = to_be_redeemed
        to_be_redeemed = unsafe_sub(to_be_redeemed, minted)  # Now this is the fees to charge
        stables_in_amm: uint256 = staticcall STABLECOIN.balanceOf(self)
        if stables_in_amm < to_be_redeemed:
            self.minted -= (to_be_redeemed - stables_in_amm)
            to_be_redeemed = stables_in_amm
        assert extcall STABLECOIN.transfer(LT_CONTRACT, to_be_redeemed, default_return_value=True)
        log CollectFees(amount=to_be_redeemed, new_supply=debt)
        return to_be_redeemed
    else:
        log CollectFees(amount=0, new_supply=debt)
        return 0


@external
@nonreentrant
def collect_fees() -> uint256:
    """
    @notice Collect the fees charged as interest.
    """
    return self._collect_fees()


@external
def set_killed(is_killed: bool):
    """
    @notice Kill (True) or unkill (False) the pool
    """
    assert msg.sender == LT_CONTRACT, "Access"
    self.is_killed = is_killed
    log SetKilled(is_killed=is_killed)


@external
@nonreentrant
@view
def check_nonreentrant():
    pass


@external
def set_fee(fee: uint256):
    """
    @notice Set pool's fee for exchanges LP<>stacoin (all the fees go to LPs)
    """
    assert msg.sender == LT_CONTRACT, "Access"
    assert fee <= MAX_FEE
    self.fee = fee
    log SetFee(fee=fee)
