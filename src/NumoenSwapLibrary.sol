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
        uint256 scale1RoundingUp = FullMath.mulDivRoundingUp((reserve1 - amount1) * token1Scale, 1e18, liquidity);

        uint256 b = scale1 * upperBound;
        uint256 c = (scale1RoundingUp * scale1RoundingUp) / 4;
        uint256 d = upperBound * upperBound;

        uint256 a = (c + d) - b;
        uint256 scale0 = FullMath.mulDivRoundingUp(a, 1, 1e18);
        uint256 targetR1 = FullMath.mulDivRoundingUp(FullMath.mulDivRoundingUp(scale0, liquidity, 1e18), 1, token0Scale);

        amount0 = targetR1 - reserve0;
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
        uint256 scale1RoundingUp = FullMath.mulDivRoundingUp((reserve1 + amount1) * token1Scale, 1e18, liquidity);

        uint256 b = scale1 * upperBound;
        uint256 c = (scale1RoundingUp * scale1RoundingUp) / 4;
        uint256 d = upperBound * upperBound;

        uint256 a = (c + d) - b;
        uint256 scale0 = FullMath.mulDivRoundingUp(a, 1, 1e18);
        uint256 targetR1 = FullMath.mulDivRoundingUp(FullMath.mulDivRoundingUp(scale0, liquidity, 1e18), 1, token0Scale);

        amount0 = reserve0 - targetR1;
    }
}
