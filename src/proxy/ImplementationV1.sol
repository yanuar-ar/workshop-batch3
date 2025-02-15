// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';

contract ImplementationV1 is Initializable {
    // v1
    uint256 public price;
    address public assetToken;
    address public owner;
    
    constructor() {
        _disableInitializers();
    }

    function initialize(address _assetToken) public initializer {
        assetToken = _assetToken;
        owner = msg.sender;
    }

    function setPrice(uint256 newPrice) public {
        require(msg.sender == owner, "Only owner can set price");
        price = newPrice;
    }

}
