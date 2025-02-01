// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC20 {

  error AmountCannotBeZero();
  error SharesCannotBeMoreThanBalance();

  event Deposit(address user,uint256 amount,uint256 shares);
  event Withdraw(address user,uint256 amount,uint256 shares);

  address public assetToken;
  address public owner;

  constructor(address _assetToken) ERC20("Deposito Vault","DEPO") {
    assetToken = _assetToken;
    owner = msg.sender;
  }

  function deposit(uint256 amount) external {
    if (amount == 0) revert AmountCannotBeZero();

    // shares yg akan diperoleh = deposit amount / total asset * total shares
    uint256 shares = 0;
    uint256 totalAssets = IERC20(assetToken).balanceOf(address(this));

    if (totalSupply() == 0 ) {
      shares = amount;
    } else {
      shares = (amount * totalSupply() / totalAssets);
    }

    _mint(msg.sender,shares);
    IERC20(assetToken).transferFrom(msg.sender,address(this),amount);

    emit Deposit(msg.sender,amount,shares);
  }

  function withdraw(uint256 shares) external {
    if (shares > balanceOf(msg.sender) || balanceOf(msg.sender) == 0) revert SharesCannotBeMoreThanBalance();
    // amount withdraw = shares / total shares * total assets
    uint256 totalAssets = IERC20(assetToken).balanceOf(address(this));
    uint256 amount = (shares * totalAssets / totalSupply());

    // withdraw GMX, Aaave

    _burn(msg.sender,shares);
    IERC20(assetToken).transfer(msg.sender,amount);

    emit Withdraw(msg.sender,amount,shares);
  }

  function distributeYield(uint256 amount) external {
    require(msg.sender == owner,"Only owner can distribute yield");
    IERC20(assetToken).transferFrom(msg.sender,address(this),amount);
  }
}


