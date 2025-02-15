// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MemeToken is ERC20 {

  constructor(string memory name, string memory symbol ) ERC20(name, symbol) {
    _mint(msg.sender,1_000_000_000_000e18);
  }

}


