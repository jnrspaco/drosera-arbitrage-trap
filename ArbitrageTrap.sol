// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTrap} from "./BaseTrap.sol";
import {IDEX} from "./interfaces/IDEX.sol";

/// @title ArbitrageTrap - Stateless Version
/// @notice Monitors price differences between two DEXs for arbitrage opportunities
contract ArbitrageTrap is BaseTrap {
    struct ArbitrageData {
        uint256 dex1Price;
        uint256 dex2Price;
        uint256 priceSpread;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // Hardcoded configuration - UPDATE WITH YOUR HOODI ADDRESSES
    address constant DEX1 = 0x6b2e277fA5d4352A8E9418b5DDe0D8196F1b52e6;
    address constant DEX2 = 0xc10C2c8D517318609Be483476925AcD44b3a180d;
    address constant TOKEN0 = 0x0000000000000000000000000000000000001111;
    address constant TOKEN1 = 0x0000000000000000000000000000000000002222;
    uint256 constant THRESHOLD_BPS = 200; // 2%

    function collect() external view override returns (bytes memory) {
        uint256 price1 = IDEX(DEX1).getPrice(TOKEN0, TOKEN1);
        uint256 price2 = IDEX(DEX2).getPrice(TOKEN0, TOKEN1);

        uint256 spread;
        if (price1 > price2) {
            spread = ((price1 - price2) * 10000) / price2;
        } else {
            spread = ((price2 - price1) * 10000) / price1;
        }

        ArbitrageData memory data = ArbitrageData({
            dex1Price: price1,
            dex2Price: price2,
            priceSpread: spread,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        return abi.encode(data);
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        if (data.length < 2) {
            return (false, bytes(""));
        }

        ArbitrageData memory latestData = abi.decode(data[data.length - 1], (ArbitrageData));

        if (latestData.priceSpread >= THRESHOLD_BPS) {
            ArbitrageData memory previousData = abi.decode(data[data.length - 2], (ArbitrageData));
            
            if (previousData.priceSpread >= THRESHOLD_BPS) {
                bytes memory callData = abi.encode(
                    latestData.dex1Price,
                    latestData.dex2Price,
                    latestData.priceSpread,
                    latestData.blockNumber
                );
                
                return (true, callData);
            }
        }

        return (false, bytes(""));
    }
}
