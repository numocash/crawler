// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { CREATE3Factory } from "create3-factory/CREATE3Factory.sol";

import { Arbitrage } from "src/examples/Arbitrage.sol";
import { SwapRouter } from "src/examples/SwapRouter.sol";

contract Deploy is Script {
    address constant create3Factory = 0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1;

    address constant numoenFactory = 0x8396A792510A402681812EcE6aD3FF19261928Ba;
    address constant uniV2Factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address constant uniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function run() external returns (address arbitrage, address swapRouter) {
        CREATE3Factory create3 = CREATE3Factory(create3Factory);

        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        arbitrage = create3.deploy(
            keccak256("NumoenArbitrageExample2"),
            bytes.concat(type(Arbitrage).creationCode, abi.encode(numoenFactory, uniV2Factory, uniV3Factory))
        );
        swapRouter = create3.deploy(
            keccak256("NumoenSwapRouterExample2"),
            bytes.concat(type(SwapRouter).creationCode, abi.encode(numoenFactory, weth))
        );
    }
}
