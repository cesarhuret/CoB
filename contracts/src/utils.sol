// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library Utils {
    // Function to return the minimum of two uint numbers
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    // Add more utility functions here if needed
}
