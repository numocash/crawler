// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.17;

import { ISwapCallback } from "numoen/core/interfaces/callback/ISwapCallback.sol";
import { ILendgine } from "numoen/core/interfaces/ILendgine.sol";

import { LendgineAddress } from "numoen/periphery/libraries/LendgineAddress.sol";
import { NumoenSwapLibrary } from "../NumoenSwapLibrary.sol";

import { SwapHelper } from "numoen/periphery/SwapHelper.sol";
import { SafeCast } from "numoen/libraries/SafeCast.sol";
import { SafeTransferLib } from "numoen/libraries/SafeTransferLib.sol";
import { Balance } from "numoen/libraries/Balance.sol";

contract Arbitrage is SwapHelper, ISwapCallback {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address private immutable factory;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _factory,
        address _uniswapV2Factory,
        address _uniswapV3Factory
    )
        SwapHelper(_uniswapV2Factory, _uniswapV3Factory)
    {
        factory = _factory;
    }

    /*//////////////////////////////////////////////////////////////
                                CALLBACK
    //////////////////////////////////////////////////////////////*/

    struct SwapCallbackData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        SwapType swapType;
        bytes swapExtraData;
    }

    function swapCallback(uint256 amount0Out, uint256 amount1Out, bytes calldata data) external {
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));

        // Swap the output of the Numoen swap on an external exchange
        swap(
            decoded.swapType,
            SwapParams({
                tokenIn: decoded.tokenIn,
                tokenOut: decoded.tokenOut,
                amount: SafeCast.toInt256(amount0Out > 0 ? amount0Out : amount1Out),
                recipient: address(this)
            }),
            decoded.swapExtraData
        );

        // payback numoen for the swap
        SafeTransferLib.safeTransfer(decoded.tokenOut, msg.sender, decoded.amountIn);
    }

    /*//////////////////////////////////////////////////////////////
                            ARBITRAGE LOGIC
    //////////////////////////////////////////////////////////////*/

    struct ArbitrageParams {
        address token0;
        address token1;
        uint256 token0Exp;
        uint256 token1Exp;
        uint256 upperBound;
        uint256 amount;
        SwapType swapType;
        bytes swapExtraData;
        address recipient;
    }

    /// @notice Arbitrage when price on Numoen is greater than the external market
    /// @dev Uses Numoen flash loans, reverts if not profitable
    function arbitrage0(ArbitrageParams calldata params) external {
        address lendgine = LendgineAddress.computeAddress(
            factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
        );

        uint256 r0 = ILendgine(lendgine).reserve0();
        uint256 r1 = ILendgine(lendgine).reserve1();
        uint256 totalLiquidity = ILendgine(lendgine).totalLiquidity();

        uint256 amount0Out = NumoenSwapLibrary.getToken0Out(
            params.amount,
            r0,
            r1,
            totalLiquidity,
            10 ** (18 - params.token0Exp),
            10 ** (18 - params.token1Exp),
            params.upperBound
        );

        ILendgine(lendgine).swap(
            address(this),
            amount0Out,
            0,
            abi.encode(
                SwapCallbackData({
                    tokenIn: params.token0,
                    tokenOut: params.token1,
                    amountIn: params.amount,
                    swapType: params.swapType,
                    swapExtraData: params.swapExtraData
                })
            )
        );

        SafeTransferLib.safeTransfer(params.token1, params.recipient, Balance.balance(params.token1));
    }

    /// @notice Arbitrage when price on Numoen is lower than the external market
    /// @dev Uses Numoen flash loans, reverts if not profitable
    function arbitrage1(ArbitrageParams calldata params) external {
        address lendgine = LendgineAddress.computeAddress(
            factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
        );

        uint256 r0 = ILendgine(lendgine).reserve0();
        uint256 r1 = ILendgine(lendgine).reserve1();
        uint256 totalLiquidity = ILendgine(lendgine).totalLiquidity();

        uint256 amount0In = NumoenSwapLibrary.getToken0In(
            params.amount,
            r0,
            r1,
            totalLiquidity,
            10 ** (18 - params.token0Exp),
            10 ** (18 - params.token1Exp),
            params.upperBound
        );

        ILendgine(lendgine).swap(
            address(this),
            0,
            params.amount,
            abi.encode(
                SwapCallbackData({
                    tokenIn: params.token1,
                    tokenOut: params.token0,
                    amountIn: amount0In,
                    swapType: params.swapType,
                    swapExtraData: params.swapExtraData
                })
            )
        );

        SafeTransferLib.safeTransfer(params.token0, params.recipient, Balance.balance(params.token0));
    }
}
