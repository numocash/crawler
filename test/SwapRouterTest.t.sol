// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.17;

import { Test } from "forge-std/Test.sol";
import { NumoenSwapLibrary } from "src/NumoenSwapLibrary.sol";
import { SwapRouter } from "src/examples/SwapRouter.sol";

import { MockERC20 } from "./utils/MockERC20.sol";

import { LiquidityManager } from "numoen/periphery/LiquidityManager.sol";
import { Factory } from "numoen/core/Factory.sol";
import { Lendgine } from "numoen/core/Lendgine.sol";

contract SwapRouterTest is Test {
    SwapRouter public swapRouter;
    Lendgine public lendgine;

    MockERC20 public token0;
    MockERC20 public token1;

    address public cuh;

    function setUp() external {
        cuh = makeAddr("cuh");

        Factory factory = new Factory();
        token0 = new MockERC20();
        token1 = new MockERC20();

        lendgine = Lendgine(factory.createLendgine(address(token0), address(token1), 18, 18, 5e18));

        swapRouter = new SwapRouter(address(factory), address(0));

        // add initial liquidity to pool
        LiquidityManager liquidityManager = new LiquidityManager(address(factory), address(0));

        deal(address(token0), address(this), 1e18);
        deal(address(token1), address(this), 8e18);

        token0.approve(address(liquidityManager), 1e18);
        token1.approve(address(liquidityManager), 8e18);

        liquidityManager.addLiquidity(
            LiquidityManager.AddLiquidityParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                liquidity: 1e18,
                amount0Min: 1e18,
                amount1Min: 8e18,
                sizeMin: 1e18,
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    function testSwap0To1() external {
        deal(address(token0), cuh, 1.25e18 + 1);

        vm.prank(cuh);
        token0.approve(address(swapRouter), 1.25e18 + 1);

        vm.prank(cuh);
        uint256 amount0In = swapRouter.swap0To1(
            SwapRouter.Swap0To1Params({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount1Out: 1e18,
                amount0InMax: 1.25e18 + 1,
                recipient: cuh,
                deadline: block.timestamp
            })
        );
        assertEq(amount0In, 1.25e18 + 1);

        assertEq(token0.balanceOf(cuh), 0);
        assertEq(token1.balanceOf(cuh), 1e18);

        assertEq(lendgine.reserve0(), 2.25e18 + 1);
        assertEq(lendgine.reserve1(), 7e18);
    }

    function testSwap1To0() external {
        deal(address(token1), cuh, 1e18);

        vm.prank(cuh);
        token1.approve(address(swapRouter), 1e18);

        vm.prank(cuh);
        uint256 amount0Out = swapRouter.swap1To0(
            SwapRouter.Swap1To0Params({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount1In: 1e18,
                amount0OutMin: 0.75e18 - 1,
                recipient: cuh,
                deadline: block.timestamp
            })
        );

        assertEq(amount0Out, 0.75e18 - 1);

        assertEq(token0.balanceOf(cuh), 0.75e18 - 1);
        assertEq(token1.balanceOf(cuh), 0);

        assertEq(lendgine.reserve0(), 0.25e18 + 1);
        assertEq(lendgine.reserve1(), 9e18);
    }
}
