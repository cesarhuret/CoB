// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ENS} from "@ens/contracts/registry/ENS.sol";
import {IAddrResolver} from "@ens/contracts/resolvers/profiles/IAddrResolver.sol";
import {ISelfKisser} from "./ISelfKisser.sol";

contract ChronicleRouter is Ownable {
    string[] public ens; // ENS addresses, e.g. btc/usd.cob.eth, etc...

    mapping(uint32 => mapping(string => address)) public enstoken;

    address public selfKisser;

    address public registry;

    uint32 public immutable chainId;

    string public base;

    string public swarm; // swarm is the cobweb swarm

    constructor(
        address _selfKisser,
        string[] memory _ens,
        address _registry,
        uint32 _chainId,
        string memory _base,
        string memory _swarm
    ) {
        selfKisser = _selfKisser;
        ens = _ens;
        registry = _registry;
        chainId = _chainId;
        base = _base;
        swarm = _swarm;
    }

    function setBase(string memory _base) external onlyOwner {
        base = _base;
    }

    function setSwarm(string memory _swarm) external onlyOwner {
        swarm = _swarm;
    }

    function setSelfKisser(address _selfKisser) external onlyOwner {
        selfKisser = _selfKisser;
    }

    function setRegistry(address _registry) external onlyOwner {
        registry = _registry;
    }

    function setToken(
        string calldata pair,
        uint32 chain,
        address token
    ) external onlyOwner {
        enstoken[chain][pair] = token;
    }

    function setTokens(
        string[] calldata pairs,
        uint32[] calldata chains,
        address[] calldata tokens
    ) external onlyOwner {
        require(
            pairs.length == chains.length && pairs.length == tokens.length,
            "Length mismatch"
        );

        for (uint256 i = 0; i < pairs.length; i++) {
            enstoken[chains[i]][pairs[i]] = tokens[i];
        }
    }

    function namehash(string calldata pair) public view returns (bytes32 node) {
        if (bytes(pair).length == 0) {
            return bytes32(0);
        }

        string[] memory labels = new string[](3);
        labels[0] = pair; // e.g. : btc
        labels[1] = swarm; // cob
        labels[2] = base; // eth
        for (uint i = 3; i > 0; i--) {
            node = keccak256(
                abi.encodePacked(
                    node,
                    keccak256(abi.encodePacked(labels[i - 1]))
                )
            );
        }
    }

    function getToken(
        string calldata pair,
        uint32 chain
    ) external view returns (address) {
        return enstoken[chain][pair];
    }

    function query(
        string[] calldata pairs
    ) external view returns (uint256[] memory prices) {
        for (uint256 i = 0; i < pairs.length; i++) {
            bytes32 node = namehash(pairs[i]);
            address resolver = ENS(registry).resolver(node);
            address feed = IAddrResolver(resolver).addr(node);
            prices[i] = IChronicle(feed).read();
        }
    }

    function selfKiss(address _ens) external {
        // pass bytes and resolve the ens
        ISelfKisser(selfKisser).selfKiss(_ens, msg.sender);
    }

    function selfKissAll() external {
        for (uint256 i = 0; i < ens.length; i++) {
            ISelfKisser(selfKisser).selfKiss(
                enstoken[chainId][ens[i]],
                msg.sender
            );
        }
    }
}
