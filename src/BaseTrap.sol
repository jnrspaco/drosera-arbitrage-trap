// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BaseTrap
 * @notice Abstract contract that all Drosera traps must implement
 * @dev Traps are monitoring contracts that collect data and determine if a response should be triggered
 */
abstract contract BaseTrap {
    /**
     * @notice Collects current state data to be analyzed
     * @return Encoded data to be stored and analyzed
     */
    function collect() external view virtual returns (bytes memory);

    /**
     * @notice Analyzes collected data to determine if a response should be triggered
     * @dev MUST be pure function - no state reads allowed per Drosera ITrap interface
     * @param data Array of encoded data from previous blocks where [0] = newest
     * @return shouldRespond True if an incident is detected and response should be triggered
     * @return callData Encoded data to pass to the response function
     */
    function shouldRespond(bytes[] calldata data) 
        external 
        pure 
        virtual 
        returns (bool shouldRespond, bytes memory callData);
}

