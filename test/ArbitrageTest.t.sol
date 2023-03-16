// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.17;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "./utils/MockERC20.sol";

import { Arbitrage } from "src/examples/Arbitrage.sol";
import { LiquidityManager } from "numoen/periphery/LiquidityManager.sol";
import { Factory } from "numoen/core/Factory.sol";
import { Lendgine } from "numoen/core/Lendgine.sol";
import { SwapHelper } from "numoen/periphery/SwapHelper.sol";

import { IUniswapV2Factory } from "numoen/periphery/UniswapV2/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "numoen/periphery/UniswapV2/interfaces/IUniswapV2Pair.sol";
import { IUniswapV3Factory } from "numoen/periphery/UniswapV3/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "numoen/periphery/UniswapV3/interfaces/IUniswapV3Pool.sol";

contract ArbitrageTest is Test {
    Arbitrage public arbitrage;
    Factory public factory;
    Lendgine public lendgine;
    LiquidityManager public liquidityManager;

    MockERC20 public token0 = MockERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // UNI
    MockERC20 public token1 = MockERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // WETH

    address public cuh;

    IUniswapV2Factory public uniswapV2Factory = IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IUniswapV2Pair public uniswapV2Pair = IUniswapV2Pair(0x6D2fAf643Fe564e0204f35e38d1a1b08D9620d14);
    IUniswapV3Factory public uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniswapV3Pool public uniswapV3Pool = IUniswapV3Pool(0x07A4f63f643fE39261140DF5E613b9469eccEC86); // uni / weth 5

    function setUp() external {
        // use goerli from a block where we know the prices on Uniswap
        vm.createSelectFork("goerli");
        vm.rollFork(8_345_575);

        cuh = makeAddr("cuh");

        factory = new Factory();

        token0 = MockERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // WETH
        token1 = MockERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // UNI

        arbitrage = new Arbitrage(
          address(factory),
          address(uniswapV2Factory),
          address(uniswapV3Factory)
        );

        liquidityManager = new LiquidityManager(address(factory), address(0));
    }

    function setupNumoen() internal {
        lendgine = Lendgine(factory.createLendgine(address(token0), address(token1), 18, 18, 5e18));

        deal(address(token0), address(this), 100e18);
        deal(address(token1), address(this), 800e18);

        token0.approve(address(liquidityManager), 100e18);
        token1.approve(address(liquidityManager), 800e18);

        // provide liqudity at a higher price than UniswapV2
        liquidityManager.addLiquidity(
            LiquidityManager.AddLiquidityParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                liquidity: 100e18,
                amount0Min: 100e18,
                amount1Min: 800e18,
                sizeMin: 100e18,
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    function setupNumoenInverse() internal {
        lendgine = Lendgine(factory.createLendgine(address(token1), address(token0), 18, 18, 5e18));

        deal(address(token0), address(this), 800e18);
        deal(address(token1), address(this), 100e18);

        token0.approve(address(liquidityManager), 800e18);
        token1.approve(address(liquidityManager), 100e18);

        // provide liqudity at a higher price than UniswapV2
        liquidityManager.addLiquidity(
            LiquidityManager.AddLiquidityParams({
                token0: address(token1),
                token1: address(token0),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                liquidity: 100e18,
                amount0Min: 100e18,
                amount1Min: 800e18,
                sizeMin: 100e18,
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    function testArbitrage0V2() external {
        setupNumoen();

        uint256 uniswapReserve0 = token0.balanceOf(address(uniswapV2Pair));
        uint256 uniswapReserve1 = token1.balanceOf(address(uniswapV2Pair));

        arbitrage.arbitrage0(
            Arbitrage.ArbitrageParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e16,
                swapType: SwapHelper.SwapType.UniswapV2,
                swapExtraData: bytes(""),
                recipient: cuh
            })
        );

        assert(token1.balanceOf(cuh) > 0);

        assert(token0.balanceOf(address(uniswapV2Pair)) > uniswapReserve0);
        assert(token1.balanceOf(address(uniswapV2Pair)) < uniswapReserve1);

        assert(token0.balanceOf(address(lendgine)) < 100e18);
        assert(token1.balanceOf(address(lendgine)) > 800e18);
    }

    function testArbitrage1V2() external {
        setupNumoenInverse();

        uint256 uniswapReserve0 = token0.balanceOf(address(uniswapV2Pair));
        uint256 uniswapReserve1 = token1.balanceOf(address(uniswapV2Pair));

        arbitrage.arbitrage1(
            Arbitrage.ArbitrageParams({
                token0: address(token1),
                token1: address(token0),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e16,
                swapType: SwapHelper.SwapType.UniswapV2,
                swapExtraData: bytes(""),
                recipient: cuh
            })
        );

        assert(token1.balanceOf(cuh) > 0);

        assert(token0.balanceOf(address(uniswapV2Pair)) > uniswapReserve0);
        assert(token1.balanceOf(address(uniswapV2Pair)) < uniswapReserve1);

        assert(token0.balanceOf(address(lendgine)) < 800e18);
        assert(token1.balanceOf(address(lendgine)) > 100e18);
    }

    function testArbitrage0V3() external {
        setupNumoen();

        uint256 uniswapReserve0 = token0.balanceOf(address(uniswapV3Pool));
        uint256 uniswapReserve1 = token1.balanceOf(address(uniswapV3Pool));

        arbitrage.arbitrage0(
            Arbitrage.ArbitrageParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e16,
                swapType: SwapHelper.SwapType.UniswapV3,
                swapExtraData: abi.encode(uint24(500)),
                recipient: cuh
            })
        );

        assert(token1.balanceOf(cuh) > 0);

        assertGt(token0.balanceOf(address(uniswapV3Pool)), uniswapReserve0);
        assertLt(token1.balanceOf(address(uniswapV3Pool)), uniswapReserve1);

        assertLt(token0.balanceOf(address(lendgine)), 100e18);
        assertGt(token1.balanceOf(address(lendgine)), 800e18);
    }

    function testArbitrage1V3() external {
        setupNumoenInverse();

        uint256 uniswapReserve0 = token0.balanceOf(address(uniswapV3Pool));
        uint256 uniswapReserve1 = token1.balanceOf(address(uniswapV3Pool));

        arbitrage.arbitrage1(
            Arbitrage.ArbitrageParams({
                token0: address(token1),
                token1: address(token0),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e16,
                swapType: SwapHelper.SwapType.UniswapV3,
                swapExtraData: abi.encode(uint24(500)),
                recipient: cuh
            })
        );

        assert(token1.balanceOf(cuh) > 0);

        assert(token0.balanceOf(address(uniswapV3Pool)) > uniswapReserve0);
        assert(token1.balanceOf(address(uniswapV3Pool)) < uniswapReserve1);

        assert(token0.balanceOf(address(lendgine)) < 800e18);
        assert(token1.balanceOf(address(lendgine)) > 100e18);
    }

    function testArbitrage0NotProfitable() external {
        token0 = new MockERC20();
        token1 = new MockERC20();

        setupNumoen();

        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(token0), address(token1)));

        deal(address(token0), address(uniswapV2Pair), 100 ether);
        deal(address(token1), address(uniswapV2Pair), 100 ether);

        uniswapV2Pair.mint(address(this));

        vm.expectRevert(Arbitrage.NotProfitable.selector);
        arbitrage.arbitrage0(
            Arbitrage.ArbitrageParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e18,
                swapType: SwapHelper.SwapType.UniswapV2,
                swapExtraData: bytes(""),
                recipient: cuh
            })
        );
    }

    function testArbitrage1NotProfitable() external {
        token0 = new MockERC20();
        token1 = new MockERC20();

        setupNumoen();

        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(token0), address(token1)));

        deal(address(token0), address(uniswapV2Pair), 100 ether);
        deal(address(token1), address(uniswapV2Pair), 100 ether);

        uniswapV2Pair.mint(address(this));

        vm.expectRevert(Arbitrage.NotProfitable.selector);
        arbitrage.arbitrage1(
            Arbitrage.ArbitrageParams({
                token0: address(token0),
                token1: address(token1),
                token0Exp: 18,
                token1Exp: 18,
                upperBound: 5e18,
                amount: 1e18,
                swapType: SwapHelper.SwapType.UniswapV2,
                swapExtraData: bytes(""),
                recipient: cuh
            })
        );
    }
}
