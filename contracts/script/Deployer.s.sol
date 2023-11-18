// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CobWeb} from "../src/CobWeb.sol";
import {ChronicleRouter} from "../src/ChronicleRouter.sol";

contract Deployer is Script {
    string root;

    string path;

    string json;

    function setUp() public {
        root = vm.projectRoot();
        path = string.concat(root, "/configs/sepolia.json");
        json = vm.readFile(path);
    }

    function run() public {
        vm.broadcast();

        address SELF_KISSER = vm.parseJsonAddress(json, "SELF_KISSER");
        address ENS_REGISTRY = vm.parseJsonAddress(json, "ENS_REGISTRY");
        address MAILBOX = vm.parseJsonAddress(json, "MAILBOX");
        uint32 CHAIN_ID = uint32(vm.parseJsonUint(json, "CHAIN_ID"));

        address[] memory TOKENS = vm.parseJsonAddressArray(json, "TOKENS");

        string[] memory ENS = vm.parseJsonStringArray(json, "ENS");

        uint256[] memory CHAINS = vm.parseJsonUintArray(json, "CHAINS");

        uint32[] memory chains = new uint32[](CHAINS.length);

        for (uint256 i = 0; i < CHAINS.length; i++) {
            chains[i] = uint32(CHAINS[i]);
        }

        address[] memory ORACLES = vm.parseJsonAddressArray(json, "ORACLES");

        ChronicleRouter router = new ChronicleRouter(
            SELF_KISSER,
            ENS_REGISTRY,
            CHAIN_ID,
            "eth",
            "cob",
            ENS,
            chains,
            TOKENS,
            ORACLES
        );

        router.getToken(ENS[1], uint32(CHAINS[1]));

        uint256[] memory prices = router.query(ENS);

        for (uint256 i = 0; i < prices.length; i++) {
            console2.logUint(prices[i]);
        }

        uint256[] memory LOCAL = vm.parseJsonUintArray(json, "LOCAL");

        uint32[] memory local = new uint32[](LOCAL.length);

        for (uint256 i = 0; i < LOCAL.length; i++) {
            local[i] = uint32(LOCAL[i]);
        }

        CobWeb cob = new CobWeb(MAILBOX, local);

        console2.logAddress(address(cob));
    }
}
