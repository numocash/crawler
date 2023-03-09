// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { FullMath } from "numoen/libraries/FullMath.sol";

/// @notice Helper functions for swapping with Numoen PMMP
/// @author Kyle Scott (kyle@numoen.com)
library NumoenSwapLibrary {
    /// @notice Calculates the amount of token0 that must be swapped in for a given amount of token1
    /// @param amount1 The amount of token1 swapped out
    /// @param reserve0 The amount of reserve0 in the pair
    /// @param reserve1 The amount of reserve1 in the pair
    /// @param liquidity The amount of liquidity in the pair
    /// @param token0Scale Scale required to make token0 18 decimals
    /// @param token1Scale Scale required to make token1 18 decimals
    /// @param upperBound Maximum exchange rate (token0 / token1) * 1e18
    /// @return amount0 The amount of token0 that must be swapped in
    function getToken0In(
        uint256 amount1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 liquidity,
        uint256 token0Scale,
        uint256 token1Scale,
        uint256 upperBound
    )
        internal
        pure
        returns (uint256 amount0)
    {
        uint256 scale1 = FullMath.mulDiv((reserve1 - amount1) * token1Scale, 1e18, liquidity);

        uint256 b = scale1 * upperBound;
        uint256 c = (scale1 * scale1) / 4;
        uint256 d = upperBound * upperBound;

        // add 1 for any rounding that could occur, cheaper than determing the exact amount
        amount0 = 1 + FullMath.mulDivRoundingUp((c + d) - b, liquidity, 1e36 * token0Scale) - reserve0;
    }

    /// @notice Calculates the amount of token0 received for a given amount of token1
    /// @param amount1 The amount of token1 swapped in
    /// @param reserve0 The amount of reserve0 in the pair
    /// @param reserve1 The amount of reserve1 in the pair
    /// @param liquidity The amount of liquidity in the pair
    /// @param token0Scale Scale required to make token0 18 decimals
    /// @param token1Scale Scale required to make token1 18 decimals
    /// @param upperBound Maximum exchange rate (token0 / token1) * 1e18
    /// @return amount0 The amount of token0 swapped out
    function getToken0Out(
        uint256 amount1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 liquidity,
        uint256 token0Scale,
        uint256 token1Scale,
        uint256 upperBound
    )
        internal
        pure
        returns (uint256 amount0)
    {
        uint256 scale1 = FullMath.mulDiv((reserve1 + amount1) * token1Scale, 1e18, liquidity);

        uint256 b = scale1 * upperBound;
        uint256 c = (scale1 * scale1) / 4;
        uint256 d = upperBound * upperBound;

        // subtract 1 for any rounding that could occur, cheaper than determing the exact amount
        amount0 = reserve0 - FullMath.mulDivRoundingUp((c + d) - b, liquidity, 1e36 * token0Scale) - 1;
    }
}
