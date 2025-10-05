// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MockDEX
/// @notice Mock DEX contract for testing arbitrage trap
contract MockDEX {
    mapping(bytes32 => uint256) private prices;
    mapping(bytes32 => uint256) private reserve0Map;
    mapping(bytes32 => uint256) private reserve1Map;

    function setPrice(address token0, address token1, uint256 price) external {
        bytes32 key = keccak256(abi.encodePacked(token0, token1));
        prices[key] = price;
    }

    function setReserves(
        address token0,
        address token1,
        uint256 _reserve0,
        uint256 _reserve1
    ) external {
        bytes32 key = keccak256(abi.encodePacked(token0, token1));
        reserve0Map[key] = _reserve0;
        reserve1Map[key] = _reserve1;
    }

    function getPrice(address token0, address token1) external view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(token0, token1));
        uint256 price = prices[key];
        require(price > 0, "Price not set");
        return price;
    }

    function getReserves(address token0, address token1)
        external
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        bytes32 key = keccak256(abi.encodePacked(token0, token1));
        return (reserve0Map[key], reserve1Map[key]);
    }
}
