// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ArbitrageTrap} from "../src/ArbitrageTrap.sol";
import {ArbitrageResponse} from "../src/ArbitrageResponse.sol";
import {MockDEX} from "../src/mocks/MockDEX.sol";

contract ArbitrageTrapTest is Test {
    ArbitrageTrap public trap;
    ArbitrageResponse public response;
    MockDEX public dex1;
    MockDEX public dex2;
    
    address token0 = address(0x1111);
    address token1 = address(0x2222);
    uint256 threshold = 200; // 2% threshold

    function setUp() public {
        // Deploy mock DEXs at the addresses expected by the trap
        vm.etch(0x6b2e277fA5d4352A8E9418b5DDe0D8196F1b52e6, address(new MockDEX()).code);
        vm.etch(0xc10C2c8D517318609Be483476925AcD44b3a180d, address(new MockDEX()).code);
        
        dex1 = MockDEX(0x6b2e277fA5d4352A8E9418b5DDe0D8196F1b52e6);
        dex2 = MockDEX(0xc10C2c8D517318609Be483476925AcD44b3a180d);
        
        // Deploy response contract
        response = new ArbitrageResponse();
        
        // Deploy trap (no constructor args)
        trap = new ArbitrageTrap();
    }

    function testCollectData() public {
        // Set initial prices
        dex1.setPrice(token0, token1, 1000e18);
        dex2.setPrice(token0, token1, 1000e18);
        
        bytes memory data = trap.collect();
        ArbitrageTrap.ArbitrageData memory decoded = abi.decode(
            data,
            (ArbitrageTrap.ArbitrageData)
        );
        
        assertEq(decoded.dex1Price, 1000e18);
        assertEq(decoded.dex2Price, 1000e18);
        assertEq(decoded.priceSpread, 0);
    }

    function testShouldRespondWithLargeSpread() public {
        // Set prices with large spread (5%)
        dex1.setPrice(token0, token1, 1000e18);
        dex2.setPrice(token0, token1, 1050e18);
        
        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = trap.collect();
        
        vm.roll(block.number + 1);
        dataArray[1] = trap.collect();
        
        (bool shouldRespond, bytes memory callData) = trap.shouldRespond(dataArray);
        
        assertTrue(shouldRespond);
        assertGt(callData.length, 0);
    }

    function testShouldNotRespondWithSmallSpread() public {
        // Set prices with small spread (1%)
        dex1.setPrice(token0, token1, 1000e18);
        dex2.setPrice(token0, token1, 1010e18);
        
        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = trap.collect();
        
        vm.roll(block.number + 1);
        dataArray[1] = trap.collect();
        
        (bool shouldRespond,) = trap.shouldRespond(dataArray);
        
        assertFalse(shouldRespond);
    }

    function testResponseExecution() public {
        uint256 dex1Price = 1000e18;
        uint256 dex2Price = 1050e18;
        uint256 spread = 500; // 5%
        uint256 blockNum = block.number;
        
        response.handleArbitrage(dex1Price, dex2Price, spread, blockNum);
        
        (uint256 lastBlock, uint256 total) = response.getStats();
        assertEq(lastBlock, block.number);
        assertEq(total, 1);
    }
}
