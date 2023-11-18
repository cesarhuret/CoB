// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CobWeb} from "../src/CobWeb.sol";
import {ChronicleRouter} from "../src/ChronicleRouter.sol";
import {MockChronicleRouter} from "../src/MockRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deployer is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configs/zkevm.json");
        string memory json = vm.readFile(path);

        address SELF_KISSER = vm.parseJsonAddress(json, ".SELF_KISSER");
        address ENS_REGISTRY = vm.parseJsonAddress(json, ".ENS_REGISTRY");
        address MAILBOX = vm.parseJsonAddress(json, ".MAILBOX");
        uint32 CHAIN_ID = uint32(vm.parseJsonUint(json, ".CHAIN_ID"));

        address[] memory TOKENS = vm.parseJsonAddressArray(json, ".TOKENS");

        string[] memory ENS = vm.parseJsonStringArray(json, ".ENS");

        uint256[] memory CHAINS = vm.parseJsonUintArray(json, ".CHAINS");

        uint32[] memory chains = new uint32[](CHAINS.length);

        for (uint256 i = 0; i < CHAINS.length; i++) {
            chains[i] = uint32(CHAINS[i]);
        }

        address[] memory ORACLES = vm.parseJsonAddressArray(json, ".ORACLES");

        // ChronicleRouter router = new ChronicleRouter(
        //     SELF_KISSER,
        //     ENS_REGISTRY,
        //     CHAIN_ID,
        //     "eth",
        //     "cob",
        //     ENS,
        //     chains,
        //     TOKENS,
        //     ORACLES
        // );

        MockChronicleRouter router = new MockChronicleRouter(
            SELF_KISSER,
            CHAIN_ID,
            ENS,
            chains,
            TOKENS,
            ORACLES
        );

        // router.getToken(ENS[1], uint32(CHAINS[1]));

        // uint256[] memory prices = router.query(ENS);

        // for (uint256 i = 0; i < prices.length; i++) {
        //     console2.logUint(prices[i]);
        // }

        uint256[] memory LOCAL = vm.parseJsonUintArray(json, ".LOCAL");

        uint32[] memory local = new uint32[](LOCAL.length);

        for (uint256 i = 0; i < LOCAL.length; i++) {
            local[i] = uint32(LOCAL[i]);
        }

        CobWeb cob = new CobWeb(MAILBOX, address(router), local);

        console2.logAddress(address(cob));

        payable(address(cob)).transfer(100000000000);

        vm.stopBroadcast();
    }
}
