// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CobThread} from "../src/CoBThread.sol";
import {ChronicleRouter} from "../src/ChronicleRouter.sol";
import {MockChronicleRouter} from "../src/MockRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deployer is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configs/arbi.json");
        string memory json = vm.readFile(path);

        address MAILBOX = vm.parseJsonAddress(json, ".MAILBOX");
        uint32 CHAIN_ID = uint32(vm.parseJsonUint(json, ".CHAIN_ID"));

        address[] memory TOKENS = vm.parseJsonAddressArray(json, ".TOKENS");

        string[] memory ENS = vm.parseJsonStringArray(json, ".ENS");

        uint256[] memory CHAINS = vm.parseJsonUintArray(json, ".CHAINS");

        uint32[] memory chains = new uint32[](CHAINS.length);
        address[] memory OTHER = vm.parseJsonAddressArray(json, ".OTHER");

        uint256[] memory LOCAL = vm.parseJsonUintArray(json, ".LOCAL");

        uint32[] memory local = new uint32[](LOCAL.length);

        for (uint256 i = 0; i < LOCAL.length; i++) {
            local[i] = uint32(LOCAL[i]);
        }

        CobThread cob = new CobThread(MAILBOX, local, TOKENS, OTHER);

        console2.logAddress(address(cob));

        vm.stopBroadcast();
    }
}
