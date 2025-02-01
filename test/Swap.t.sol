// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Swap} from "../src/Swap.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// forge test --match-contract SwapTest -vv
contract SwapTest is Test {

  Swap public swap;

  address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;


  function setUp() public {
    // deploy token
    vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI",21699812);
    swap = new Swap();
  }

  function test_swap() public {
    deal(usdc,address(this),1000e6);
    IERC20(usdc).approve(address(swap),1000e6);
    swap.swap(1000e6,100);
    uint256 wbtcBalance = IERC20(wbtc).balanceOf(address(this));
    console.log('WBTC Balance', wbtcBalance);
  }


}
