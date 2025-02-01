// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ImplementationV1 {
    // v1
    uint256 public price;
    
    function setPrice(uint256 newPrice) public {
        price = newPrice;
    }

}
