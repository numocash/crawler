// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { NumoenSwapLibrary } from "src/NumoenSwapLibrary.sol";

contract NumoenSwapLibraryTest is Test {
    /// @notice Test amount0 in under normal conditions
    function testToken0In() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e18, 1e18, 8e18, 1e18, 1, 1, 5e18);

        assertEq(amount0, 1.25e18);
    }

    /// @notice Test amount0 in with an unusual token0Scale
    function testToken0InScale0() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e18, 1e6, 8e18, 1e18, 1e12, 1, 5e18);

        assertEq(amount0, 1.25e6);
    }

    /// @notice Test amount0 in with an unusual token1Scale
    function testToken0InScale1() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e6, 1e18, 8e6, 1e18, 1, 1e12, 5e18);

        assertEq(amount0, 1.25e18);
    }

    /// @notice Test amount0 out under normal conditions
    function testToken0Out() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e18, 1e18, 8e18, 1e18, 1, 1, 5e18);

        assertEq(amount0, 0.75e18);
    }

    /// @notice Test amount0 with an unusual token0Scale
    function testToken0OutScale0() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e18, 1e6, 8e18, 1e18, 1e12, 1, 5e18);

        assertEq(amount0, 0.75e6);
    }

    /// @notice Test amount0 with an unusual token1Scale
    function testToken0OutScale1() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e6, 1e18, 8e6, 1e18, 1, 1e12, 5e18);

        assertEq(amount0, 0.75e18);
    }

    // /// @notice Test amount0 in edge cases
    // function testToken0InRounding() external {
    //     uint256 amount0 = NumoenSwapLibrary.getToken0In(1e18, 1e18 - 1, 8e18 - 8, 1e18 - 1, 1, 1, 5e18);

    //     assertEq(amount0, 1.25 ether + 2);
    // }

    // /// @notice Test amount0 out edge cases
    // function testToken0OutRounding() external {
    //     uint256 reserve0Before = 1e18 - 1;
    //     uint256 reserve1Before = 8e18 - 8;
    //     uint256 setupAmount1Out = 1e18;
    //     uint256 setupAmount0In = 1.25e18 + 2;

    //     uint256 amount0 = NumoenSwapLibrary.getToken0Out(
    //         setupAmount0In, reserve0Before + setupAmount0In, reserve1Before - setupAmount1Out, 1e18 - 1, 1, 1, 5e18
    //     );

    //     assertEq(amount0, setupAmount0In - 1);
    // }
}
