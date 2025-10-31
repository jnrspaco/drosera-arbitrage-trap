// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTrap} from "./BaseTrap.sol";
import {IDEX} from "./interfaces/IDEX.sol";

/// @title ArbitrageTrap - Drosera-Compatible Version
/// @notice Monitors price differences between two DEXs for arbitrage opportunities
/// @dev IMPORTANT: data[0] = newest block, data[1] = previous block (Drosera ordering)
contract ArbitrageTrap is BaseTrap {
    struct ArbitrageData {
        uint256 dex1Price;
        uint256 dex2Price;
        uint256 priceSpread;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // Configuration - UPDATE WITH YOUR DEPLOYED ADDRESSES
    // NOTE: These are hardcoded for PoC. For production, use constructor or registry.
    address constant DEX1 = 0x6b2e277fA5d4352A8E9418b5DDe0D8196F1b52e6;
    address constant DEX2 = 0xc10C2c8D517318609Be483476925AcD44b3a180d;
    address constant TOKEN0 = 0x0000000000000000000000000000000000001111;
    address constant TOKEN1 = 0x0000000000000000000000000000000000002222;
    uint256 constant THRESHOLD_BPS = 200; // 2% threshold in basis points
    uint256 constant MIN_PRICE = 1; // Minimum price to prevent divide-by-zero

    /// @notice Collect current arbitrage data from both DEXs
    /// @dev Uses try-catch to handle potential DEX call failures gracefully
    /// @return Encoded ArbitrageData struct, or empty bytes if collection fails
    function collect() external view override returns (bytes memory) {
        // Safe price fetching with fallback
        uint256 price1 = _safeGetPrice(DEX1, TOKEN0, TOKEN1);
        uint256 price2 = _safeGetPrice(DEX2, TOKEN0, TOKEN1);

        // If either price is invalid, return empty data
        if (price1 < MIN_PRICE || price2 < MIN_PRICE) {
            return bytes("");
        }

        // Calculate absolute price spread in basis points
        uint256 spread = _calculateSpread(price1, price2);

        ArbitrageData memory data = ArbitrageData({
            dex1Price: price1,
            dex2Price: price2,
            priceSpread: spread,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        return abi.encode(data);
    }

    /// @notice Determine if response should be triggered based on historical data
    /// @dev CRITICAL: Drosera provides data[0] = newest, data[1] = previous
    /// @dev Must be PURE function (no state reads) per Drosera ITrap interface
    /// @param data Array of encoded ArbitrageData where [0]=newest, [1]=previous, etc.
    /// @return shouldRespond True if arbitrage opportunity exceeds threshold
    /// @return callData Encoded data to pass to response function
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        // Need at least 2 data points for analysis
        if (data.length < 2) {
            return (false, bytes(""));
        }

        // Guard against empty blobs
        if (data[0].length == 0 || data[1].length == 0) {
            return (false, bytes(""));
        }

        // DROSERA ORDERING: data[0] = newest (latest), data[1] = previous
        ArbitrageData memory latestData = abi.decode(data[0], (ArbitrageData));
        ArbitrageData memory previousData = abi.decode(data[1], (ArbitrageData));

        // Validate data integrity
        if (latestData.dex1Price < MIN_PRICE || 
            latestData.dex2Price < MIN_PRICE ||
            previousData.dex1Price < MIN_PRICE ||
            previousData.dex2Price < MIN_PRICE) {
            return (false, bytes(""));
        }

        // Check if current spread exceeds threshold AND is persistent
        // (exists in at least 2 consecutive blocks)
        if (latestData.priceSpread >= THRESHOLD_BPS && 
            previousData.priceSpread >= THRESHOLD_BPS) {
            
            // Encode response data
            bytes memory callData = abi.encode(
                latestData.dex1Price,
                latestData.dex2Price,
                latestData.priceSpread,
                latestData.blockNumber
            );
            
            return (true, callData);
        }

        return (false, bytes(""));
    }

    /// @notice Safely fetch price from DEX with error handling
    /// @dev Returns 0 if call fails, preventing reverts in collect()
    function _safeGetPrice(address dex, address token0, address token1) 
        private 
        view 
        returns (uint256) 
    {
        try IDEX(dex).getPrice(token0, token1) returns (uint256 price) {
            return price;
        } catch {
            return 0;
        }
    }

    /// @notice Calculate spread between two prices in basis points
    /// @dev Protected against divide-by-zero
    function _calculateSpread(uint256 price1, uint256 price2) 
        private 
        pure 
        returns (uint256) 
    {
        if (price1 == 0 || price2 == 0) {
            return 0;
        }

        if (price1 > price2) {
            return ((price1 - price2) * 10000) / price2;
        } else {
            return ((price2 - price1) * 10000) / price1;
        }
    }
}

