// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ArbitrageResponse
/// @notice Response contract that gets called when arbitrage opportunity is detected
contract ArbitrageResponse {
    event ArbitrageDetected(
        uint256 dex1Price,
        uint256 dex2Price,
        uint256 spread,
        uint256 blockNumber,
        uint256 timestamp
    );

    event ResponseExecuted(
        address indexed executor,
        uint256 timestamp
    );

    uint256 public lastResponseBlock;
    uint256 public totalResponses;

    /// @notice Main response function called by Drosera operators
    /// @param dex1Price Price from DEX 1
    /// @param dex2Price Price from DEX 2
    /// @param spread Price spread in basis points
    /// @param blockNumber Block where arbitrage was detected
    function handleArbitrage(
        uint256 dex1Price,
        uint256 dex2Price,
        uint256 spread,
        uint256 blockNumber
    ) external {
        require(block.number > lastResponseBlock, "Already responded this block");

        lastResponseBlock = block.number;
        totalResponses++;

        emit ArbitrageDetected(
            dex1Price,
            dex2Price,
            spread,
            blockNumber,
            block.timestamp
        );

        emit ResponseExecuted(msg.sender, block.timestamp);

        // Add your custom response logic here:
        // - Pause trading
        // - Execute arbitrage
        // - Send alerts
        // - Update oracle
        // - etc.
    }

    /// @notice Get response statistics
    function getStats() external view returns (uint256, uint256) {
        return (lastResponseBlock, totalResponses);
    }
}
