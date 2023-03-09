// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.17;

import { Multicall } from "numoen/periphery/Multicall.sol";
import { Payment } from "numoen/periphery/Payment.sol";
import { SelfPermit } from "numoen/periphery/SelfPermit.sol";

import { ISwapCallback } from "numoen/core/interfaces/callback/ISwapCallback.sol";
import { ILendgine } from "numoen/core/interfaces/ILendgine.sol";

import { LendgineAddress } from "numoen/periphery/libraries/LendgineAddress.sol";
import { NumoenSwapLibrary } from "../NumoenSwapLibrary.sol";

contract SwapRouter is Multicall, Payment, SelfPermit, ISwapCallback {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LivelinessError();

    error AmountError();

    error ValidationError();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address private immutable factory;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _factory, address _weth) Payment(_weth) {
        factory = _factory;
    }

    /*//////////////////////////////////////////////////////////////
                           LIVELINESS MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier checkDeadline(uint256 deadline) {
        if (deadline < block.timestamp) revert LivelinessError();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CALLBACK
    //////////////////////////////////////////////////////////////*/

    struct SwapCallbackData {
        address token0;
        address token1;
        uint256 token0Exp;
        uint256 token1Exp;
        uint256 upperBound;
        uint256 amount0In;
        uint256 amount1In;
        address payer;
    }

    function swapCallback(uint256, uint256, bytes calldata data) external {
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));

        address lendgine = LendgineAddress.computeAddress(
            factory, decoded.token0, decoded.token1, decoded.token0Exp, decoded.token1Exp, decoded.upperBound
        );
        if (lendgine != msg.sender) revert ValidationError();

        if (decoded.amount0In > 0) pay(decoded.token0, decoded.payer, msg.sender, decoded.amount0In);
        if (decoded.amount1In > 0) pay(decoded.token1, decoded.payer, msg.sender, decoded.amount1In);
    }

    /*//////////////////////////////////////////////////////////////
                                SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    struct Swap0To1Params {
        address token0;
        address token1;
        uint256 token0Exp;
        uint256 token1Exp;
        uint256 upperBound;
        uint256 amount1Out;
        uint256 amount0InMax;
        address recipient;
        uint256 deadline;
    }

    function swap0To1(Swap0To1Params calldata params)
        external
        payable
        checkDeadline(params.deadline)
        returns (uint256 amount0In)
    {
        address lendgine = LendgineAddress.computeAddress(
            factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
        );

        uint256 r0 = ILendgine(lendgine).reserve0();
        uint256 r1 = ILendgine(lendgine).reserve1();
        uint256 totalLiquidity = ILendgine(lendgine).totalLiquidity();

        amount0In = NumoenSwapLibrary.getToken0In(
            params.amount1Out,
            r0,
            r1,
            totalLiquidity,
            10 ** (18 - params.token0Exp),
            10 ** (18 - params.token1Exp),
            params.upperBound
        );

        if (amount0In > params.amount0InMax) revert AmountError();

        ILendgine(lendgine).swap(
            params.recipient,
            0,
            params.amount1Out,
            abi.encode(
                SwapCallbackData({
                    token0: params.token0,
                    token1: params.token1,
                    token0Exp: params.token0Exp,
                    token1Exp: params.token1Exp,
                    upperBound: params.upperBound,
                    amount0In: amount0In,
                    amount1In: 0,
                    payer: msg.sender
                })
            )
        );
    }

    struct Swap1To0Params {
        address token0;
        address token1;
        uint256 token0Exp;
        uint256 token1Exp;
        uint256 upperBound;
        uint256 amount1In;
        uint256 amount0OutMin;
        address recipient;
        uint256 deadline;
    }

    function swap1To0(Swap1To0Params calldata params)
        external
        payable
        checkDeadline(params.deadline)
        returns (uint256 amount0Out)
    {
        address lendgine = LendgineAddress.computeAddress(
            factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
        );

        uint256 r0 = ILendgine(lendgine).reserve0();
        uint256 r1 = ILendgine(lendgine).reserve1();
        uint256 totalLiquidity = ILendgine(lendgine).totalLiquidity();

        amount0Out = NumoenSwapLibrary.getToken0Out(
            params.amount1In,
            r0,
            r1,
            totalLiquidity,
            10 ** (18 - params.token0Exp),
            10 ** (18 - params.token1Exp),
            params.upperBound
        );

        if (amount0Out < params.amount0OutMin) revert AmountError();

        ILendgine(lendgine).swap(
            params.recipient,
            amount0Out,
            0,
            abi.encode(
                SwapCallbackData({
                    token0: params.token0,
                    token1: params.token1,
                    token0Exp: params.token0Exp,
                    token1Exp: params.token1Exp,
                    upperBound: params.upperBound,
                    amount0In: 0,
                    amount1In: params.amount1In,
                    payer: msg.sender
                })
            )
        );
    }
}
