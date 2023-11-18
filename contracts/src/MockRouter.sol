// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISelfKisser} from "./ISelfKisser.sol";

contract MockChronicleRouter is Ownable {
    mapping(uint32 => mapping(string => address)) public enstoken;
    mapping(uint32 => mapping(string => address)) public ensoracle;

    address public selfKisser;
    uint32 public immutable chainId;

    constructor(
        address _selfKisser,
        uint32 _chainId,
        string[] memory pairs,
        uint32[] memory chains,
        address[] memory tokens,
        address[] memory oracles
    ) {
        selfKisser = _selfKisser;
        chainId = _chainId;

        setTokens(pairs, chains, tokens);
        setOracles(pairs, chains, oracles);
        selfKissAll(oracles);
    }

    function setSelfKisser(address _selfKisser) external onlyOwner {
        selfKisser = _selfKisser;
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

    function setOracles(
        string[] memory pairs,
        uint32[] memory chains,
        address[] memory oracles
    ) public onlyOwner {
        require(
            pairs.length * chains.length == oracles.length,
            "ChronicleRouter: invalid length"
        );
        for (uint256 i = 0; i < chains.length; i++) {
            for (uint256 j = 0; j < pairs.length; j++) {
                ensoracle[chains[i]][pairs[j]] = oracles[j + i * pairs.length];
            }
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
            address feed = ensoracle[chainId][pairs[i]];
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
