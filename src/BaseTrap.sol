// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract BaseTrap {
    function collect() external view virtual returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external view virtual returns (bool, bytes memory);
}
