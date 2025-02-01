// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

// forge test --match-contract TokenTest
contract TokenTest is Test {

  Token public token;
  

  address public alice = makeAddr("alice");

  function setUp() public {
    // deploy token
    token = new Token();
  }

  function test_mint() public {
    token.mint(address(this), 1000);
    assertEq(token.balanceOf(address(this)), 1000, "balance should be 1000");
  }

  function test_mint_max_supply() public {

    assertEq(token.MAX_TOTAL_SUPPLY(),10_000);

    vm.expectRevert("Max supply exceeded");
    token.mint(address(this), 1000000000);
  }


}
