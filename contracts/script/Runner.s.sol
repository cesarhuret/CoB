// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CobWeb} from "../src/CobWeb.sol";
import {ChronicleRouter} from "../src/ChronicleRouter.sol";
import {MockChronicleRouter} from "../src/MockRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Runner is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        CobWeb cob = CobWeb(
            payable(address(0xE14c8eAAB11FC37fd5b52C4D1f878c4Bf5EAF628))
        );

        string[] memory tokens = new string[](2);
        tokens[0] = "ethusd";
        tokens[1] = "usdcusd";

        cob.bridge(10 ** 18, tokens, 11155111, 1442, 0xffffff, 1 * 10 ** 16);

    }
}
