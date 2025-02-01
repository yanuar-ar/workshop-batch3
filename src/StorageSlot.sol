// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//forge inspect StorageSlot storage-layout --pretty
contract StorageSlot {
  uint256 public price; // 0
  address public owner; // 1 = 20 bytes
  uint96 public decimals; // 2 = 12 bytes
  uint256 public totalSupply; // 3 = 32 bytes
}


