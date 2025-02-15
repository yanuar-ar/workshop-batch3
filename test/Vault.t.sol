// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {TokenRupiah} from "../src/TokenRupiah.sol";

contract VaultTest is Test {

  Vault public vault;
  TokenRupiah public tokenRupiah;

  address public alice = makeAddr("alice");
  address public bob = makeAddr("bob");
  address public carol = makeAddr("carol");
  address public david = makeAddr("david");

  function setUp() public {
    // deploy token
    tokenRupiah = new TokenRupiah();

    tokenRupiah.mint(address(this), 1000);
    address vaultAddress = computeCreateAddress(address(this), vm.getNonce(address(this)));
    tokenRupiah.approve(vaultAddress, 1000);
    vault = new Vault(address(tokenRupiah));

    tokenRupiah.mint(alice, 1_000_000e6);
    tokenRupiah.mint(bob, 1_000_000e6);
    tokenRupiah.mint(carol, 2_000_000e6);
    tokenRupiah.mint(david, 5_000_000e6);

    // wallet owner
    tokenRupiah.mint(address(this), 1_000_000_000e6);
  }

  function test_deposit_amount_should_not_zero() public {
    vm.expectRevert(Vault.AmountCannotBeZero.selector);
    vault.deposit(0);
  }

  function test_withdraw_shares_cannot_more_than_balance() public {
    vm.startPrank(alice);
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.deposit(1_000_000e6);
    vm.stopPrank();

    vm.startPrank(bob);
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.deposit(1_000_000e6);
    vm.stopPrank();

    vm.startPrank(alice);
    vm.expectRevert(Vault.SharesCannotBeMoreThanBalance.selector);
    vault.withdraw(1_500_000e6);

    console.log("alice balance", tokenRupiah.balanceOf(alice));
  }

  function test_scenario_1() public {
    // hari pertama
    vm.startPrank(alice);
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.deposit(1_000_000e6);
    vm.stopPrank();

    vm.startPrank(bob);
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.deposit(1_000_000e6);
    vm.stopPrank();

    // distribusi yield
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.distributeYield(1_000_000e6);

    // alice withdraw
    uint256 aliceBalanceBefore = tokenRupiah.balanceOf(alice);
    console.log("alice balance before", aliceBalanceBefore);
    vm.startPrank(alice);
    uint256 aliceShares = vault.balanceOf(alice);
    vault.withdraw(aliceShares);
    vm.stopPrank();
    uint256 aliceBalanceAfter = tokenRupiah.balanceOf(alice);
    console.log("alice balance after", aliceBalanceAfter);

    // carol deposit
    vm.startPrank(carol);
    tokenRupiah.approve(address(vault), 2_000_000e6);
    vault.deposit(2_000_000e6);
    vm.stopPrank();

    // distribusi yield
    tokenRupiah.approve(address(vault), 1_000_000e6);
    vault.distributeYield(1_000_000e6);

    // carol withdraw
    vm.startPrank(carol);
    uint256 carolShares = vault.balanceOf(carol);
    vault.withdraw(carolShares);
    vm.stopPrank();

  }


  function test_inflation_attack() public {
    // alice adalah hacker
    vm.startPrank(alice);
    tokenRupiah.approve(address(vault), 1);
    vault.deposit(1);
    tokenRupiah.transfer(address(vault), 1000e6);
    vm.stopPrank();

    // bob deposit 100 USDC
    vm.startPrank(bob);
    tokenRupiah.approve(address(vault), 100e6);
    vault.deposit(100e6);
    console.log("bob shares", vault.balanceOf(bob));
    vm.stopPrank();

    // alice withdraw
    vm.startPrank(alice);
    uint256 aliceBalanceBefore = tokenRupiah.balanceOf(alice);
    uint256 aliceShares = vault.balanceOf(alice);
    vault.withdraw(aliceShares);
    uint256 aliceBalanceAfter = tokenRupiah.balanceOf(alice);
    console.log("alice balance after", aliceBalanceAfter-aliceBalanceBefore);
    vm.stopPrank();

  }



}
