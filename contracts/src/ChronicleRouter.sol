// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ENS} from "@ens/contracts/registry/ENS.sol";
import {IAddrResolver} from "@ens/contracts/resolvers/profiles/IAddrResolver.sol";
import {ISelfKisser} from "./ISelfKisser.sol";

contract ChronicleRouter is Ownable {
    mapping(uint32 => mapping(string => address)) public enstoken;

    address public selfKisser;

    address public registry;

    uint32 public immutable chainId;

    string public base;

    string public swarm; // swarm is the cobweb swarm

    constructor(
        address _selfKisser,
        address _registry,
        uint32 _chainId,
        string memory _base,
        string memory _swarm,
        string[] memory pairs,
        uint32[] memory chains,
        address[] memory tokens,
        address[] memory oracles
    ) {
        selfKisser = _selfKisser;
        registry = _registry;
        chainId = _chainId;
        base = _base;
        swarm = _swarm;

        setTokens(pairs, chains, tokens);
        selfKissAll(oracles);
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
        string[] memory pairs,
        uint32[] memory chains,
        address[] memory tokens
    ) public onlyOwner {
        require(
            pairs.length * chains.length == tokens.length,
            "ChronicleRouter: invalid length"
        );
        for (uint256 i = 0; i < chains.length; i++) {
            for (uint256 j = 0; j < pairs.length; j++) {
                enstoken[chains[i]][pairs[j]] = tokens[j + i * pairs.length];
            }
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
        prices = new uint256[](pairs.length);

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

    function selfKissAll(address[] memory oracles) private {
        for (uint256 i = 0; i < oracles.length; i++) {
            ISelfKisser(selfKisser).selfKiss(oracles[i], address(this));
        }
    }
}
