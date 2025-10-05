// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDEX {
    function getPrice(address token0, address token1) external view returns (uint256);
    function getReserves(address token0, address token1) external view returns (uint256 reserve0, uint256 reserve1);
}
