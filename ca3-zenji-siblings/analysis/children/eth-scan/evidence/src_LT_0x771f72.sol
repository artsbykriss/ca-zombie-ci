
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

// ===== contracts/LT.vy =====
# @version 0.4.3
"""
@title LT
@notice Implementation of leveraged liquidity for Yield Basis
@author Scientia Spectra AG
@license Copyright (c) 2025
"""
from ethereum.ercs import IERC20
from snekmate.utils import math

implements: IERC20


interface IERC20Detailed:
    def decimals() -> uint256: view

interface IERC20Slice:
    def symbol() -> String[29]: view

interface LevAMM:
    def _deposit(d_collateral: uint256, d_debt: uint256) -> OraclizedValue: nonpayable
    def _withdraw(frac: uint256) -> Pair: nonpayable
    def value_change(collateral_amount: uint256, borrowed_amount: uint256, is_deposit: bool) -> OraclizedValue: view
    def fee() -> uint256: view
    def value_oracle() -> OraclizedValue: view
    def get_state() -> AMMState: view
    def get_debt() -> uint256: view
    def collateral_amount() -> uint256: view
    def value_oracle_for(collateral: uint256, debt: uint256) -> OraclizedValue: view
    def set_rate(rate: uint256) -> uint256: nonpayable
    def collect_fees() -> uint256: nonpayable
    def PRICE_ORACLE_CONTRACT() -> PriceOracle: view
    def max_debt() -> uint256: view
    def COLLATERAL() -> address: view
    def STABLECOIN() -> address: view
    def LT_CONTRACT() -> address: view
    def set_killed(is_killed: bool): nonpayable
    def check_nonreentrant(): nonpayable
    def is_killed() -> bool: view
    def set_fee(fee: uint256): nonpayable

interface CurveCryptoPool:
    def add_liquidity(amounts: uint256[2], min_mint_amount: uint256, receiver: address, donation: bool) -> uint256: nonpayable
    def remove_liquidity(amount: uint256, min_amounts: uint256[2]) -> uint256[2]: nonpayable
    def lp_price() -> uint256: view
    def price_scale() -> uint256: view
    def decimals() -> uint256: view
    def mid_fee() -> uint256: view
    def totalSupply() -> uint256: view
    def coins(i: uint256) -> address: view
    def calc_token_amount(amounts: uint256[2], deposit: bool) -> uint256: view
    def balances(i: uint256) -> uint256: view
    def approve(_to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def remove_liquidity_fixed_out(token_amount: uint256, i: uint256, amount_i: uint256, min_amount_j: uint256) -> uint256: nonpayable
    def calc_withdraw_fixed_out(token_amount: uint256, i: uint256, amount_i: uint256) -> uint256: view

interface PriceOracle:
    def price_w() -> uint256: nonpayable
    def price() -> uint256: view
    def AGG() -> address: view

interface Factory:
    def admin() -> address: view
    def emergency_admin() -> address: view
    def fee_receiver() -> address: view
    def gauge_controller() -> address: view
    def min_admin_fee() -> uint256: view


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

struct LiquidityValues:
    admin: int256  # Can be negative
    total: uint256
    ideal_staked: uint256
    staked: uint256

struct LiquidityValuesOut:
    admin: int256  # Can be negative
    total: uint256
    ideal_staked: uint256
    staked: uint256
    staked_tokens: uint256
    supply_tokens: uint256
    token_reduction: int256


event SetStaker:
    staker: indexed(address)


event WithdrawAdminFees:
    receiver: address
    amount: uint256

event AllocateStablecoins:
    allocator: indexed(address)
    stablecoin_allocation: uint256
    stablecoin_allocated: uint256

event DistributeBorrowerFees:
    sender: indexed(address)
    amount: uint256
    min_amount: uint256
    discount: uint256


# ERC4626 events

event Deposit:
    sender: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256

event Withdraw:
    sender: indexed(address)
    receiver: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256


event SetAdmin:
    admin: address


CRYPTOPOOL: public(immutable(CurveCryptoPool))  # Liquidity like LP(TBTC/crvUSD)
STABLECOIN: public(immutable(IERC20))  # For example, crvUSD
ASSET_TOKEN: public(immutable(IERC20))  # For example, TBTC

CRYPTOPOOL_N_COINS: constant(uint256) = 2
FEE_CLAIM_DISCOUNT: constant(uint256) = 10**16
MIN_SHARE_REMAINDER: constant(uint256) = 10**6  # We leave at least this much of shares if > 0
SQRT_MIN_UNSTAKED_FRACTION: constant(int256) = 10**14  # == 1e-4, avoiding infinite APR and 0/0 errors
MIN_STAKED_FOR_FEES: constant(int256) = 10**16

admin: public(address)
amm: public(LevAMM)
agg: public(PriceOracle)

staker: public(address)

liquidity: public(LiquidityValues)

allowance: public(HashMap[address, HashMap[address, uint256]])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
decimals: public(constant(uint8)) = 18

stablecoin_allocation: public(uint256)
stablecoin_allocated: public(uint256)


@deploy
def __init__(asset_token: IERC20, stablecoin: IERC20, cryptopool: CurveCryptoPool,
             admin: address):
    """
    @notice Initializer (can be performed by an EOA deployer or a factory)
    @param asset_token Token which gets deposited. Can be collateral or can be not
    @param stablecoin Stablecoin which gets "granted" to this contract to use for loans. Has to be 18 decimals
    @param cryptopool Cryptopool LP collateral token
    @param admin Admin which can set callbacks, stablecoin allocator and fee. Sensitive!
    """
    # Example:
    # asset_token = WBTC
    # stablecoin = crvUSD
    # cryptopool = WBTC LP

    STABLECOIN = stablecoin
    CRYPTOPOOL = cryptopool
    ASSET_TOKEN = asset_token
    self.admin = admin
    assert extcall asset_token.approve(cryptopool.address, max_value(uint256), default_return_value=True)
    assert extcall stablecoin.approve(cryptopool.address, max_value(uint256), default_return_value=True)
    assert staticcall cryptopool.coins(0) == stablecoin.address
    assert staticcall cryptopool.coins(1) == asset_token.address

    # Twocrypto has no N_COINS public, so we check that coins(2) reverts
    success: bool = False
    res: Bytes[32] = empty(Bytes[32])
    success, res = raw_call(
        cryptopool.address,
        abi_encode(CRYPTOPOOL_N_COINS, method_id=method_id("coins(uint256)")),
        max_outsize=32,
        is_static_call=True,
        revert_on_failure=False)
    assert not success, "N>2"


@internal
@view
def _check_admin():
    admin: address = self.admin
    if admin.is_contract:
        assert msg.sender == admin or msg.sender == staticcall Factory(admin).admin(), "Access"
    else:
        assert msg.sender == admin, "Access"


@internal
@view
def _price_oracle() -> uint256:
    return staticcall CRYPTOPOOL.price_scale() * staticcall self.agg.price() // 10**18


@internal
def _price_oracle_w() -> uint256:
    return staticcall CRYPTOPOOL.price_scale() * extcall self.agg.price_w() // 10**18


@internal
def _checkpoint_gauge():
    """
    @notice Checkpoint a gauge if any to prevent flash loan attacks on reward distribution, reverts are ignored
    """
    gauge: address = self.staker
    if gauge != empty(address):
        admin: address = self.admin
        if admin.is_contract:
            gc: address = staticcall Factory(admin).gauge_controller()
            if gc != empty(address):
                success: bool = raw_call(
                    gc,
                    abi_encode(gauge, method_id=method_id("checkpoint(address)")),
                    is_static_call=False,
                    revert_on_failure=False)
                if not success:
                    # Try again but with fixed gas. This will just make TX fail if one tries to manipulate
                    # the gas attached to the call while NOT inflating the gas estimate if the call does not revert
                    assert msg.gas >= 200_000, "GAS"
                    success = raw_call(
                        gc,
                        abi_encode(gauge, method_id=method_id("checkpoint(address)")),
                        gas=200_000,
                        is_static_call=False,
                        revert_on_failure=False)


@internal
@view
def _min_admin_fee() -> uint256:
    admin: address = self.admin
    if admin.is_contract:
        return staticcall Factory(admin).min_admin_fee()
    else:
        return 0


@external
@view
def min_admin_fee() -> uint256:
    return self._min_admin_fee()


@internal
@pure
def mul_div_signed(x: int256, y: int256, denominator: int256) -> int256:
    if denominator == 0:
        return 0

    value: int256 = convert(
        math._mul_div(
            convert(abs(x), uint256),
            convert(abs(y), uint256),
            convert(abs(denominator), uint256),
            False),
        int256)

    if ((x < 0) != (y < 0)) != (denominator < 0):
        value = -value

    return value


@internal
@view
def _calculate_values(p_o: uint256, _amm_value: uint256 = 0) -> LiquidityValuesOut:
    prev: LiquidityValues = self.liquidity
    staker: address = self.staker
    staked: int256 = 0
    if staker != empty(address):
        staked = convert(self.balanceOf[self.staker], int256)
    supply: int256 = convert(self.totalSupply, int256)
    # staked is guaranteed to be <= supply

    f_a: int256 = convert(
        10**18 - (10**18 - self._min_admin_fee()) * isqrt(convert(10**36 - staked * 10**36 // supply, uint256)) // 10**18,
        int256)

    amm_value: uint256 = _amm_value
    if amm_value == 0:
        amm_value = (staticcall self.amm.value_oracle()).value

    cur_value: int256 = convert(amm_value * 10**18 // p_o, int256)
    prev_value: int256 = convert(prev.total, int256)
    value_change: int256 = cur_value - (prev_value + prev.admin)

    v_st: int256 = convert(prev.staked, int256)
    v_st_ideal: int256 = convert(prev.ideal_staked, int256)
    # ideal_staked is set when some tokens are transferred to staker address

    # _36 postifix is to emphasize that the value is 1e36-based, not 1e18, for type tracking purposes

    # Admin fees are earned only when all losses are paid off
    dv_use_36: int256 = 0
    v_st_loss: int256 = max(v_st_ideal - v_st, 0)
    if staked >= MIN_STAKED_FOR_FEES:
        if value_change > 0:
            # Admin fee is only charged once the loss if fully paid off
            v_loss: int256 = min(value_change, v_st_loss * supply // staked)
            dv_use_36 = v_loss * 10**18 + (value_change - v_loss) * (10**18 - f_a)
        else:
            # Admin doesn't pay for value loss
            dv_use_36 = value_change * 10**18
    else:
        # If staked part is small - positive admin fees are charged on profits and negative on losses
        dv_use_36 = value_change * (10**18 - f_a)

    prev.admin += (value_change - dv_use_36 // 10**18)

    # dv_s is guaranteed to be <= dv_use
    # if staked < supply (not exactly 100.0% staked) - dv_s is strictly < dv_use
    dv_s_36: int256 = self.mul_div_signed(dv_use_36, staked, supply)
    if dv_use_36 > 0:
        dv_s_36 = min(dv_s_36, v_st_loss * 10**18)

    # new_staked_value is guaranteed to be <= new_total_value
    new_total_value_36: int256 = max(prev_value * 10**18 + dv_use_36, 0)
    new_staked_value_36: int256 = max(v_st * 10**18 + dv_s_36, 0)

    # Solution of:
    # staked - token_reduction       new_staked_value
    # -------------------------  =  -------------------
    # supply - token_reduction         new_total_value
    #
    # the result:
    #                      new_total_value * staked - new_staked_value * supply
    # token_reduction  =  ------------------------------------------------------
    #                               new_total_value - new_staked_value
    #
    # When eps = (supply - staked) / supply << 1, it comes down to:
    # token_reduction = value_change / total_value * (1.0 - min_admin_fee) / sqrt(eps) * supply
    # So when eps < 1e-8 - we'll limit token_reduction

    # If denominator is 0 -> token_reduction = 0 (not a revert)

    token_reduction: int256 = new_total_value_36 - new_staked_value_36  # Denominator
    token_reduction = self.mul_div_signed(new_total_value_36, staked, token_reduction) - self.mul_div_signed(new_staked_value_36, supply, token_reduction)

    max_token_reduction: int256 = abs(value_change * supply // (prev_value + value_change + 1) * (10**18 - f_a) // SQRT_MIN_UNSTAKED_FRACTION)

    # let's leave at least 1 LP token for staked and for total
    if staked > 0:
        token_reduction = min(token_reduction, staked - 1)
    if supply > 0:
        token_reduction = min(token_reduction, supply - 1)
    # But most likely it's this condition to apply
    if token_reduction >= 0:
        token_reduction = min(token_reduction, max_token_reduction)
    else:
        token_reduction = max(token_reduction, -max_token_reduction)
    # And don't allow negatives if denominator was too small
    if new_total_value_36 - new_staked_value_36 < 10**4 * 10**18:
        token_reduction = max(token_reduction, 0)

    # Supply changes each time:
    # value split reduces the amount of staked tokens (but not others),
    # and this also reduces the supply of LP tokens

    return LiquidityValuesOut(
        admin=prev.admin,
        total=convert(new_total_value_36 // 10**18, uint256),
        ideal_staked=prev.ideal_staked,
        staked=convert(new_staked_value_36 // 10**18, uint256),
        staked_tokens=convert(staked - token_reduction, uint256),
        supply_tokens=convert(supply - token_reduction, uint256),
        token_reduction=token_reduction
    )


@internal
def _log_token_reduction(staker: address, token_reduction: int256):
    if token_reduction < 0:
        log IERC20.Transfer(sender=empty(address), receiver=staker, value=convert(-token_reduction, uint256))
    if token_reduction > 0:
        log IERC20.Transfer(sender=staker, receiver=empty(address), value=convert(token_reduction, uint256))


@external
@view
@nonreentrant
def preview_deposit(assets: uint256, debt: uint256, raise_overflow: bool = True) -> uint256:
    """
    @notice Returns the amount of shares which can be obtained upon depositing assets, including slippage.
            Reverts if amounts are too high
    @param assets Amount of crypto to deposit
    @param debt Amount of stables to borrow for MMing (approx same value as crypto)
    @param raise_overflow Raise if deposit overflows (optional and true by default)
    """
    lp_tokens: uint256 = staticcall CRYPTOPOOL.calc_token_amount([debt, assets], True)
    supply: uint256 = self.totalSupply
    p_o: uint256 = self._price_oracle()
    amm: LevAMM = self.amm
    amm_max_debt: uint256 = staticcall amm.max_debt() // 2

    if supply > 0:
        liquidity: LiquidityValuesOut = self._calculate_values(p_o)
        if liquidity.total > 0:
            v: OraclizedValue = staticcall amm.value_change(lp_tokens, debt, True)
            if raise_overflow:
                if amm_max_debt < v.value:
                    raise "Debt too high"
            # Liquidity contains admin fees, so we need to subtract
            # If admin fees are negative - we get LESS LP tokens
            # value_before = v.value_before - liquidity.admin = total
            value_after: uint256 = convert(convert(v.value * 10**18 // p_o, int256) - liquidity.admin, uint256)
            return liquidity.supply_tokens * value_after // liquidity.total - liquidity.supply_tokens

    v: OraclizedValue = staticcall amm.value_oracle_for(lp_tokens, debt)
    if raise_overflow:
        if amm_max_debt < v.value:
            raise "Debt too high"
    return v.value * 10**18 // p_o


@external
@view
@nonreentrant
def preview_withdraw(tokens: uint256) -> uint256:
    """
    @notice Returns the amount of assets which can be obtained upon withdrawing from tokens
    """
    v: LiquidityValuesOut = self._calculate_values(self._price_oracle())
    state: AMMState = staticcall self.amm.get_state()
    # Total does NOT include uncollected admin fees
    # however we account only for positive admin balance. This "socializes" losses if they happen
    admin_balance: uint256 = convert(max(v.admin, 0), uint256)
    frac: uint256 = 10**18 * v.total // (v.total + admin_balance) * tokens // v.supply_tokens
    withdrawn_lp: uint256 = state.collateral * frac // 10**18
    withdrawn_debt: uint256 = state.debt * frac // 10**18
    return staticcall CRYPTOPOOL.calc_withdraw_fixed_out(withdrawn_lp, 0, withdrawn_debt)


@external
@nonreentrant
def deposit(assets: uint256, debt: uint256, min_shares: uint256, receiver: address = msg.sender) -> uint256:
    """
    @notice Method to deposit assets (e.g. like BTC) to receive shares (e.g. like yield-bearing BTC)
    @param assets Amount of assets to deposit
    @param debt Amount of debt for AMM to take (approximately BTC * btc_price)
    @param min_shares Minimal amount of shares to receive (important to calculate to exclude sandwich attacks)
    @param receiver Receiver of the shares who is optional. If not specified - receiver is the sender
    """
    staker: address = self.staker
    assert receiver != staker, "Deposit to staker"

    amm: LevAMM = self.amm
    assert extcall STABLECOIN.transferFrom(amm.address, self, debt, default_return_value=True)
    assert extcall ASSET_TOKEN.transferFrom(msg.sender, self, assets, default_return_value=True)

    # add_liquidity can make profit, but change in price_scale (IF) can cause loss
    lp_tokens: uint256 = extcall CRYPTOPOOL.add_liquidity([debt, assets], 0, amm.address, False)
    p_o: uint256 = self._price_oracle_w()

    supply: uint256 = self.totalSupply
    shares: uint256 = 0

    # Running calculate_values before _deposit but after add_liquidity means that:
    # fees from add_liquidity are given to all the previous LPs in YB
    # as well as loss from adjustment of price_scale is shared by them
    # but not by the new depositor
    liquidity_values: LiquidityValuesOut = empty(LiquidityValuesOut)
    if supply > 0:
        liquidity_values = self._calculate_values(p_o)

    v: OraclizedValue = extcall amm._deposit(lp_tokens, debt)
    value_after: uint256 = v.value * 10**18 // p_o

    # Value is measured in USD
    # Do not allow value to become larger than HALF of the available stablecoins after the deposit
    # If value becomes too large - we don't allow to deposit more to have a buffer when the price rises
    assert staticcall amm.max_debt() // 2 >= v.value, "Debt too high"

    if supply > 0 and liquidity_values.total > 0:
        supply = liquidity_values.supply_tokens
        self.liquidity.admin = liquidity_values.admin
        value_before: uint256 = liquidity_values.total
        value_after = convert(convert(value_after, int256) - liquidity_values.admin, uint256)
        self.liquidity.total = value_after
        self.liquidity.staked = liquidity_values.staked
        self.totalSupply = liquidity_values.supply_tokens  # will be increased by mint
        if staker != empty(address):
            self.balanceOf[staker] = liquidity_values.staked_tokens
            self._log_token_reduction(staker, liquidity_values.token_reduction)
        # ideal_staked is only changed when we transfer coins to staker
        shares = supply * value_after // value_before - supply

    else:
        # Initial value/shares ratio is EXACTLY 1.0 in collateral units
        # Value is measured in USD
        shares = value_after
        # self.liquidity.admin is 0 at start but can be rolled over if everything was withdrawn
        self.liquidity.ideal_staked = 0         # Likely already 0 since supply was 0
        self.liquidity.staked = 0               # Same: nothing staked when supply is 0
        self.liquidity.total = shares + supply  # 1 share = 1 crypto at first deposit
        self.liquidity.admin = 0                # if we had admin fees - give them to the first depositor; simpler to handle
        if self.balanceOf[staker] > 0:
            log IERC20.Transfer(sender=staker, receiver=empty(address), value=self.balanceOf[staker])
        self.balanceOf[staker] = 0

    assert shares + supply >= MIN_SHARE_REMAINDER, "Remainder too small"
    assert shares >= min_shares, "Slippage"

    self._mint(receiver, shares)
    self._checkpoint_gauge()
    log Deposit(sender=msg.sender, owner=receiver, assets=assets, shares=shares)
    self._distribute_borrower_fees(FEE_CLAIM_DISCOUNT)
    return shares


@external
@nonreentrant
def withdraw(shares: uint256, min_assets: uint256, receiver: address = msg.sender) -> uint256:
    """
    @notice Method to withdraw assets (e.g. like BTC) by spending shares (e.g. like yield-bearing BTC)
    @param shares Shares to withdraw
    @param min_assets Minimal amount of assets to receive (important to calculate to exclude sandwich attacks)
    @param receiver Receiver of the assets who is optional. If not specified - receiver is the sender
    """
    assert shares > 0, "Withdrawing nothing"

    staker: address = self.staker
    assert staker not in [msg.sender, receiver], "Withdraw to/from staker"

    assert not (staticcall self.amm.is_killed()), "We're dead. Use emergency_withdraw"

    amm: LevAMM = self.amm
    liquidity_values: LiquidityValuesOut = self._calculate_values(self._price_oracle_w())
    supply: uint256 = liquidity_values.supply_tokens
    self.liquidity.admin = liquidity_values.admin
    # self.liquidity.total = liquidity_values.total  no need to update since we will record this value later
    self.liquidity.staked = liquidity_values.staked
    self.totalSupply = supply

    assert supply >= MIN_SHARE_REMAINDER + shares or supply == shares, "Remainder too small"

    if staker != empty(address):
        self.balanceOf[staker] = liquidity_values.staked_tokens
        self._log_token_reduction(staker, liquidity_values.token_reduction)

    admin_balance: uint256 = convert(max(liquidity_values.admin, 0), uint256)

    withdrawn: Pair = extcall amm._withdraw(10**18 * liquidity_values.total // (liquidity_values.total + admin_balance) * shares // supply)
    assert extcall CRYPTOPOOL.transferFrom(amm.address, self, withdrawn.collateral, default_return_value=True)
    crypto_received: uint256 = extcall CRYPTOPOOL.remove_liquidity_fixed_out(withdrawn.collateral, 0, withdrawn.debt, 0)

    self._burn(msg.sender, shares)  # Changes self.totalSupply
    self.liquidity.total = liquidity_values.total * (supply - shares) // supply
    if liquidity_values.admin < 0:
        # If admin fees are negative - we are skipping them, so reduce proportionally
        self.liquidity.admin = liquidity_values.admin * convert(supply - shares, int256) // convert(supply, int256)
    assert crypto_received >= min_assets, "Slippage"
    assert extcall STABLECOIN.transfer(amm.address, withdrawn.debt, default_return_value=True)
    assert extcall ASSET_TOKEN.transfer(receiver, crypto_received, default_return_value=True)

    self._checkpoint_gauge()
    log Withdraw(sender=msg.sender, receiver=receiver, owner=msg.sender, assets=crypto_received, shares=shares)
    self._distribute_borrower_fees(FEE_CLAIM_DISCOUNT)
    return crypto_received


@external
@view
@nonreentrant
def preview_emergency_withdraw(shares: uint256) -> (uint256, int256):
    """
    @notice Method to simulate repay of the debt from the wallet and withdraw what is in the AMM. Does not use heavy math but
            does not necessarily work as single asset withdrawal
    @param shares Shares to withdraw
    @return (unsigned collateral, signed stables). If stables < 0 - we need to bring them
    """
    supply: uint256 = 0
    lv: LiquidityValuesOut = empty(LiquidityValuesOut)
    amm: LevAMM = self.amm

    if staticcall amm.is_killed():
        supply = self.totalSupply
    else:
        lv = self._calculate_values(self._price_oracle())
        supply = lv.supply_tokens

    frac: uint256 = 10**18 * shares // supply
    if lv.admin > 0 and lv.total != 0:
        frac = frac * lv.total // (convert(lv.admin, uint256) + lv.total)

    lp_collateral: uint256 = (staticcall amm.collateral_amount()) * frac // 10**18
    debt: int256 = convert(math._ceil_div((staticcall amm.get_debt()) * frac, 10**18), int256)

    cryptopool_supply: uint256 = staticcall CRYPTOPOOL.totalSupply()
    withdraw_amounts: uint256[2] = [staticcall CRYPTOPOOL.balances(0), staticcall CRYPTOPOOL.balances(1)]
    withdraw_amounts = [
        lp_collateral * withdraw_amounts[0] // cryptopool_supply,
        lp_collateral * withdraw_amounts[1] // cryptopool_supply
    ]

    return (withdraw_amounts[1], convert(withdraw_amounts[0], int256) - debt)


@external
@nonreentrant
def emergency_withdraw(shares: uint256, receiver: address = msg.sender, owner: address = msg.sender) -> (uint256, int256):
    """
    @notice Method to repay the debt from the wallet and withdraw what is in the AMM. Does not use heavy math but
            does not necessarily work as single asset withdrawal. Minimal output is not specified: convexity of
            bonding curves ensures that attackers can only lose value, not gain
    @param shares Shares to withdraw
    @param receiver Receiver of the assets who is optional. If not specified - receiver is the sender
    @return (unsigned asset, signed stables). If stables < 0 - we need to bring them
    """
    staker: address = self.staker
    assert staker not in [owner, receiver], "Withdraw to/from staker"

    supply: uint256 = 0
    lv: LiquidityValuesOut = empty(LiquidityValuesOut)
    amm: LevAMM = self.amm
    killed: bool = staticcall amm.is_killed()

    # Read value_oracle without fail at revert
    response: Bytes[64] = empty(Bytes[64])
    success: bool = False
    success, response = raw_call(
        amm.address,
        method_id("value_oracle()"),
        max_outsize=64,
        revert_on_failure=False,
        is_static_call=True
    )
    amm_value: uint256 = 0
    if success:
        amm_value = abi_decode(response, OraclizedValue).value

    if killed or not success:
        # If killed:
        admin: address = self.admin
        if admin.is_contract:
            if msg.sender == staticcall Factory(admin).emergency_admin():
                # Only emergency admin is allowed to withdraw for others, but then only transfer to themselves
                assert receiver == owner, "receiver"
            else:
                # If sender is a different smart contract - it must be the owner
                assert owner == msg.sender, "owner"
        else:
            if msg.sender == admin:
                # If admin is EOA - it can withdraw for receivers when killed, but only send to themselves
                assert receiver == owner, "receiver"
            else:
                # If EOA caller is not admin - it must be the owner
                assert owner == msg.sender, "owner"

        supply = self.totalSupply

    else:
        # If not killed - only owner is allowed to work with their LP
        assert owner == msg.sender, "Not killed"

        lv = self._calculate_values(self._price_oracle_w(), amm_value)
        supply = lv.supply_tokens
        self.liquidity.admin = lv.admin
        self.liquidity.total = lv.total
        self.liquidity.staked = lv.staked
        self.totalSupply = supply
        if staker != empty(address):
            self.balanceOf[staker] = lv.staked_tokens
            self._log_token_reduction(staker, lv.token_reduction)

    assert supply >= MIN_SHARE_REMAINDER + shares or supply == shares, "Remainder too small"

    frac: uint256 = 10**18 * shares // supply
    frac_clean: int256 = convert(frac, int256)
    if lv.admin > 0 and lv.total != 0:
        frac = frac * lv.total // (convert(lv.admin, uint256) + lv.total)

    withdrawn_levamm: Pair = extcall amm._withdraw(frac)
    assert extcall CRYPTOPOOL.transferFrom(amm.address, self, withdrawn_levamm.collateral, default_return_value=True)
    withdrawn_cswap: uint256[2] = extcall CRYPTOPOOL.remove_liquidity(withdrawn_levamm.collateral, [0, 0])
    stables_to_return: int256 = convert(withdrawn_cswap[0], int256) - convert(withdrawn_levamm.debt, int256)

    self._burn(owner, shares)

    self.liquidity.total = self.liquidity.total * (supply - shares) // supply
    if self.liquidity.admin < 0 or killed or not success:
        self.liquidity.admin = self.liquidity.admin * (10**18 - frac_clean) // 10**18

    if stables_to_return > 0:
        assert extcall STABLECOIN.transfer(receiver, convert(stables_to_return, uint256), default_return_value=True)
    elif stables_to_return < 0:
        assert extcall STABLECOIN.transferFrom(msg.sender, self, convert(-stables_to_return, uint256), default_return_value=True)
    assert extcall STABLECOIN.transfer(amm.address, withdrawn_levamm.debt, default_return_value=True)
    assert extcall ASSET_TOKEN.transfer(receiver, withdrawn_cswap[1], default_return_value=True)

    if not killed:
        self._checkpoint_gauge()

    return (withdrawn_cswap[1], stables_to_return)


@external
def checkpoint_staker_rebase():
    staker: address = self.staker
    killed: bool = staticcall self.amm.is_killed()

    if msg.sender == staker and not killed:
        lv: LiquidityValuesOut = self._calculate_values(self._price_oracle_w())
        self.liquidity.admin = lv.admin
        self.liquidity.total = lv.total
        self.liquidity.staked = lv.staked
        self.totalSupply = lv.supply_tokens
        self.balanceOf[staker] = lv.staked_tokens
        self._log_token_reduction(staker, lv.token_reduction)


@external
@view
def updated_balances() -> (uint256, uint256):
    if self.totalSupply > 0:
        lv: LiquidityValuesOut = self._calculate_values(self._price_oracle())
        return (lv.supply_tokens, lv.staked_tokens)
    else:
        return (0, 0)


@external
@view
def pricePerShare() -> uint256:
    """
    Non-manipulatable "fair price per share" oracle
    """
    if self.totalSupply == 0:
        return 10**18
    else:
        v: LiquidityValuesOut = self._calculate_values(self._price_oracle())
        return v.total * 10**18 // v.supply_tokens


@external
@nonreentrant
def set_amm(amm: LevAMM):
    """
    Set AMM: only allowed once (at init time)
    """
    self._check_admin()
    assert self.amm == empty(LevAMM), "Already set"
    assert staticcall amm.STABLECOIN() == STABLECOIN.address
    assert staticcall amm.COLLATERAL() == CRYPTOPOOL.address
    assert staticcall amm.LT_CONTRACT() == self
    self.amm = amm
    self.agg = PriceOracle(staticcall (staticcall amm.PRICE_ORACLE_CONTRACT()).AGG())


@external
@nonreentrant
def set_admin(new_admin: address):
    """
    Set admin to factory or EOA
    """
    self._check_admin()

    # Sanity check for the new admin
    if new_admin.is_contract:
        check_address: address = staticcall Factory(new_admin).admin()
        check_address = staticcall Factory(new_admin).emergency_admin()
        check_address = staticcall Factory(new_admin).fee_receiver()
        check_address = staticcall Factory(new_admin).gauge_controller()
        check_uint: uint256 = staticcall Factory(new_admin).min_admin_fee()

    self.admin = new_admin
    log SetAdmin(admin=new_admin)


@external
@nonreentrant
def set_rate(rate: uint256):
    """
    @notice Set borrow rate == donation rate for the AMM in units of 1e18-based fraction per second
    """
    self._check_admin()
    extcall self.amm.set_rate(rate)


@external
@nonreentrant
def set_amm_fee(fee: uint256):
    """
    @notice Set 1e18-based AMM fee
    """
    self._check_admin()
    extcall self.amm.set_fee(fee)


@external
@nonreentrant
def allocate_stablecoins(limit: uint256 = max_value(uint256)):
    """
    @notice This method has to be used once this contract has received allocation of stablecoins
    @param limit Limit to allocate for this pool from this allocator. Max uint256 = do not change
    """
    allocator: address = self.admin
    allocation: uint256 = limit
    allocated: uint256 = self.stablecoin_allocated
    if limit == max_value(uint256):
        allocation = self.stablecoin_allocation
    else:
        self._check_admin()
        self.stablecoin_allocation = limit

    extcall self.amm.check_nonreentrant()

    if allocation > allocated:
        to_transfer: uint256 = min(allocation - allocated, staticcall STABLECOIN.balanceOf(allocator))
        assert extcall STABLECOIN.transferFrom(allocator, self.amm.address, to_transfer, default_return_value=True)
        allocated += to_transfer
        self.stablecoin_allocated = allocated

    elif allocation < allocated:
        lp_price: uint256 = extcall (staticcall self.amm.PRICE_ORACLE_CONTRACT()).price_w()
        # Normal operation leaves 50% surplus - coefficient 1
        # "At the edge" is 1/2
        # Safe lower limit for deflating the market - 3/4
        safe_lower_limit: uint256 = lp_price * (staticcall self.amm.collateral_amount()) * 3 // 4 // 10**18
        to_transfer: uint256 = min(
            min(allocated - allocation, allocated - safe_lower_limit),
            staticcall STABLECOIN.balanceOf(self.amm.address))
        allocated -= to_transfer
        assert extcall STABLECOIN.transferFrom(self.amm.address, allocator, to_transfer, default_return_value=True)
        self.stablecoin_allocated = allocated

    log AllocateStablecoins(allocator=allocator, stablecoin_allocation=allocation, stablecoin_allocated=allocated)


@internal
def _distribute_borrower_fees(discount: uint256):
    amm: LevAMM = self.amm
    if discount > FEE_CLAIM_DISCOUNT:
        self._check_admin()
    if msg.sender != amm.address:
        extcall amm.collect_fees()
    amount: uint256 = staticcall STABLECOIN.balanceOf(self)
    if amount > 0:
        # We price to the stablecoin we use, not the aggregated USD here, and this is correct
        # It is possible to have a temporary denial of service here which, though, does not affect emergency
        # withdrawal. It only can happen if price moves too fast. It does not prevent cryptopool from
        # being traded and returning back to normal operation
        min_amount: uint256 = (10**18 - discount) * amount // staticcall CRYPTOPOOL.lp_price()
        extcall CRYPTOPOOL.add_liquidity([amount, 0], min_amount, empty(address), True)
        log DistributeBorrowerFees(sender=msg.sender, amount=amount, min_amount=min_amount, discount=discount)


@external
@nonreentrant
def distribute_borrower_fees(discount: uint256 = FEE_CLAIM_DISCOUNT):
    """
    @notice Distribute borrower fees to the AMM
    @param discount Optional discount (1% by default): only settable by admin
    """
    self._distribute_borrower_fees(discount)


@external
@nonreentrant
def withdraw_admin_fees():
    """
    @notice Withdraw admin fees and distribute to the DAO
    """
    admin: address = self.admin
    assert admin.is_contract, "Need factory"
    assert not staticcall self.amm.is_killed(), "Killed"
    extcall self.amm.check_nonreentrant()

    fee_receiver: address = staticcall Factory(admin).fee_receiver()
    assert fee_receiver != empty(address), "No fee_receiver"

    staker: address = self.staker
    assert fee_receiver != staker, "Staker=fee_receiver"

    v: LiquidityValuesOut = self._calculate_values(self._price_oracle_w())
    assert v.admin >= 0, "Loss made admin fee negative"
    self.totalSupply = v.supply_tokens
    # Mint YB tokens to fee receiver and burn the untokenized admin buffer at the same time
    # fee_receiver is just a normal user
    new_total: uint256 = v.total + convert(v.admin, uint256)
    to_mint: uint256 = v.supply_tokens * new_total // v.total - v.supply_tokens
    self._mint(fee_receiver, to_mint)
    self.liquidity.total = new_total
    self.liquidity.admin = 0
    self.liquidity.staked = v.staked
    if staker != empty(address):
        self.balanceOf[staker] = v.staked_tokens
        self._log_token_reduction(staker, v.token_reduction)

    log WithdrawAdminFees(receiver=fee_receiver, amount=to_mint)


@external
@nonreentrant
def set_staker(staker: address):
    """
    @notice Set staker contract - allowed only once
    """
    assert self.staker == empty(address), "Staker already set"
    assert staker != empty(address)
    self._check_admin()

    staker_balance: uint256 = self.balanceOf[staker]
    if staker_balance > 0:
        # Take that all as admin fee, staker should not have this
        fee_receiver: address = staticcall Factory(self.admin).fee_receiver()
        assert staker != fee_receiver, "Staker=fee_receiver"
        self._transfer(staker, fee_receiver, staker_balance)

    self.staker = staker
    log SetStaker(staker=staker)


@external
def set_killed(is_killed: bool):
    """
    @notice Kill or unkill the pool
    """
    admin: address = self.admin
    if admin.is_contract:
        assert msg.sender in [admin, staticcall Factory(admin).admin(), staticcall Factory(admin).emergency_admin()], "Access"
    else:
        assert msg.sender == admin, "Access"
    extcall self.amm.set_killed(is_killed)


# ERC20 methods

@external
@view
def symbol() -> String[32]:
    return concat('yb-', staticcall IERC20Slice(ASSET_TOKEN.address).symbol())


@external
@view
def name() -> String[58]:
    return concat('Yield Basis liquidity for ', staticcall IERC20Slice(ASSET_TOKEN.address).symbol())


@internal
def _approve(_owner: address, _spender: address, _value: uint256):
    self.allowance[_owner][_spender] = _value

    log IERC20.Approval(owner=_owner, spender=_spender, value=_value)


@internal
def _burn(_from: address, _value: uint256):
    self.balanceOf[_from] -= _value
    self.totalSupply -= _value

    log IERC20.Transfer(sender=_from, receiver=empty(address), value=_value)


@internal
def _mint(_to: address, _value: uint256):
    self.balanceOf[_to] += _value
    self.totalSupply += _value

    log IERC20.Transfer(sender=empty(address), receiver=_to, value=_value)


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    assert _to not in [self, empty(address)]

    staker: address = self.staker
    staker_used: bool = (staker != empty(address) and staker in [_from, _to])
    if staker_used:
        assert _from != _to
        liquidity: LiquidityValuesOut = empty(LiquidityValuesOut)

        if msg.sender == staker or staticcall self.amm.is_killed():
            # If sender is staker - it's mint/redeem/deposit/withdraw
            # where we did checkpoint_staker_rebase() in the same tx
            liquidity.ideal_staked = self.liquidity.ideal_staked
            liquidity.staked = self.liquidity.staked
            liquidity.total = self.liquidity.total
            liquidity.supply_tokens = self.totalSupply
            liquidity.staked_tokens = self.balanceOf[staker]
        else:
            liquidity = self._calculate_values(self._price_oracle_w())
            self.liquidity.admin = liquidity.admin
            self.liquidity.total = liquidity.total
            self.totalSupply = liquidity.supply_tokens
            self.balanceOf[staker] = liquidity.staked_tokens
            self._log_token_reduction(staker, liquidity.token_reduction)

        if _from == staker:
            # Reduce the staked part
            # change by 0 if no supply_tokens or stake_tokens found
            liquidity.staked -= unsafe_div(liquidity.total * _value, liquidity.supply_tokens)
            liquidity.ideal_staked = unsafe_div(liquidity.ideal_staked * (liquidity.staked_tokens - _value), liquidity.staked_tokens)
        elif _to == staker:
            # Increase the staked part
            d_staked_value: uint256 = liquidity.total * _value // liquidity.supply_tokens
            liquidity.staked += d_staked_value
            if liquidity.staked_tokens > 10**10:
                liquidity.ideal_staked = liquidity.ideal_staked * (liquidity.staked_tokens + _value) // liquidity.staked_tokens
            else:
                # To exclude division by zero and numerical noise errors
                liquidity.ideal_staked += d_staked_value

        self.liquidity.staked = liquidity.staked
        self.liquidity.ideal_staked = liquidity.ideal_staked

    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    if staker_used and msg.sender != staker:
        self._checkpoint_gauge()

    log IERC20.Transfer(sender=_from, receiver=_to, value=_value)


@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens from one account to another.
    @dev The caller needs to have an allowance from account `_from` greater than or
        equal to the value being transferred. An allowance equal to the uint256 type's
        maximum, is considered infinite and does not decrease.
    @param _from The account which tokens will be spent from.
    @param _to The account which tokens will be sent to.
    @param _value The amount of tokens to be transferred.
    """
    allowance: uint256 = self.allowance[_from][msg.sender]
    if allowance != max_value(uint256):
        self._approve(_from, msg.sender, allowance - _value)

    self._transfer(_from, _to, _value)
    return True


@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens to `_to`.
    @param _to The account to transfer tokens to.
    @param _value The amount of tokens to transfer.
    """
    self._transfer(msg.sender, _to, _value)
    return True


@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @notice Allow `_spender` to transfer up to `_value` amount of tokens from the caller's account.
    @dev Non-zero to non-zero approvals are allowed, but should be used cautiously. The methods
        increaseAllowance + decreaseAllowance are available to prevent any front-running that
        may occur.
    @param _spender The account permitted to spend up to `_value` amount of caller's funds.
    @param _value The amount of tokens `_spender` is allowed to spend.
    """
    self._approve(msg.sender, _spender, _value)
    return True


@external
@view
def is_killed() -> bool:
    return staticcall self.amm.is_killed()
