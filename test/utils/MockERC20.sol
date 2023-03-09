// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ERC20 } from "numoen/core/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20() { }
}
