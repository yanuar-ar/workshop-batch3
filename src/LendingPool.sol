// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IOracle {
  function getPrice() external view returns (uint256);
}
contract LendingPool  {
  // erros
  error ZeroAmount();
  error InsufficientShares();
  error InsufficientLiquidity();
  error InsufficientCollateral();
  error LTVExceedMaxAmount();
  error InvalidOracle();
  error FlashloanFailed();
  // events
  event Supply(address user,uint256 amount, uint256 shares);
  event Withdraw(address user,uint256 amount, uint256 shares);
  event SupplyCollateral(address user,uint256 amount);
  event Borrow(address user,uint256 amount, uint256 shares);
  event Repay(address user,uint256 amount, uint256 shares);
  event Flashloan(address user,address token, uint256 amount);

  // supply
  uint256 public totalSupplyShares;
  uint256 public totalSupplyAssets;
  
  mapping(address => uint256) public userSupplyShares;

  // borrow

  uint256 public totalBorrowShares;
  uint256 public totalBorrowAssets;

  mapping(address => uint256) public userBorrowShares;
  mapping(address => uint256) public userCollaterals;

  uint256 public lastAccrued = block.timestamp;

  uint256 public borrowRate = 1e17; // 18 decimals setara 10%

  address public collateralToken;
  address public debtToken;

  uint256 ltv; // 18 decimals

  address public oracle;

  constructor(address _collateralToken, address _debtToken, address _oracle, uint256 _ltv) {
    collateralToken = _collateralToken;
    debtToken = _debtToken;

    if (_oracle == address(0)) revert InvalidOracle();
    oracle = _oracle;

    if (_ltv > 1e18) revert LTVExceedMaxAmount();
    ltv = _ltv;
  }

  function supply(uint256 amount) external {
    if (amount == 0) revert ZeroAmount();

    _accrueInterest();

    uint256 shares = 0;
    if (totalSupplyShares == 0 ) {
      shares = amount;
    } else {
      shares = (amount * totalSupplyShares / totalSupplyAssets);
    }

    userSupplyShares[msg.sender] += shares;
    totalSupplyShares += shares;
    totalSupplyAssets += amount;

    IERC20(debtToken).transferFrom(msg.sender,address(this),amount);

    emit Supply(msg.sender, amount, shares);
  }

  function withdraw(uint256 shares) external {
    if (shares == 0) revert ZeroAmount();
    if (shares > userSupplyShares[msg.sender]) revert InsufficientShares();

    _accrueInterest();

    uint256 amount = (shares * totalSupplyAssets / totalSupplyShares);

    userSupplyShares[msg.sender] -= shares;
    totalSupplyShares -= shares;
    totalSupplyAssets -= amount;

    if (totalSupplyAssets < totalBorrowAssets) revert InsufficientLiquidity();

    IERC20(debtToken).transfer(msg.sender, amount);

    emit Withdraw(msg.sender, amount, shares);
  }

  function borrow(uint256 amount) external {
    _accrueInterest();

    uint256 shares = 0;
    if (totalBorrowShares == 0 ) {
      shares = amount;
    } else {
      shares = (amount * totalBorrowShares / totalBorrowAssets);
    }

    userBorrowShares[msg.sender] += shares;
    totalBorrowShares += shares;
    totalBorrowAssets += amount;

    _isHealthy(msg.sender);
    if(totalBorrowAssets > totalSupplyAssets) revert InsufficientLiquidity();

    IERC20(debtToken).transfer(msg.sender, amount);

    emit Borrow(msg.sender, amount, shares);
  }

  function repay(uint256 shares) external {
    if (shares == 0) revert ZeroAmount();

    _accrueInterest();

    uint256 borrowAmount = (shares * totalBorrowAssets / totalBorrowShares);

    userBorrowShares[msg.sender] -= shares;
    totalBorrowShares -= shares;
    totalBorrowAssets -= borrowAmount;

    IERC20(debtToken).transferFrom(msg.sender,address(this),borrowAmount);

    emit Repay(msg.sender, borrowAmount, shares);
  }

  function supplyCollateral(uint256 amount) external {
    if (amount == 0) revert ZeroAmount();

    _accrueInterest();

    userCollaterals[msg.sender] += amount;

    IERC20(collateralToken).transferFrom(msg.sender,address(this),amount);

    emit SupplyCollateral(msg.sender, amount);
  }

  function withdrawCollateral(uint256 amount) public {
    if (amount == 0) revert ZeroAmount();
    if (amount > userCollaterals[msg.sender]) revert InsufficientCollateral();

    _accrueInterest();

    userCollaterals[msg.sender] -= amount;

    _isHealthy(msg.sender);

    IERC20(collateralToken).transfer(msg.sender, amount);
  }

  function _isHealthy(address user) internal view {
    uint256 collateralPrice = IOracle(oracle).getPrice();
    uint256 collateralDecimals = 10**IERC20Metadata(collateralToken).decimals(); // 1e18

    uint256 borrowed = userBorrowShares[user] * totalBorrowAssets / totalBorrowShares;

    uint256 collateralValue = userCollaterals[user] * collateralPrice / collateralDecimals;
    uint256 maxBorrow = collateralValue * ltv / 1e18;

    if (borrowed > maxBorrow) revert InsufficientCollateral();
  }

  function accureInterest() external {
    _accrueInterest();
  }

  function _accrueInterest() internal {

    uint256 interestPerYear = totalBorrowAssets * borrowRate/ 1e18;
    // 1000 * 1e17 / 1e18 = 100/year

    uint256 elapsedTime = block.timestamp - lastAccrued;
    // 1 hari 

    uint256 interest = (interestPerYear * elapsedTime) / 365 days;
    // interest = $100 * 1 hari / 365 hari  = $0.27

    totalSupplyAssets += interest;
    totalBorrowAssets += interest;
    lastAccrued = block.timestamp;
  }


  function flashloan(address token, uint256 amount,bytes calldata data) external {
    if (amount == 0) revert ZeroAmount();

    IERC20(token).transfer(msg.sender,amount);

    (bool success, ) = address(msg.sender).call(data);
    if (!success) revert FlashloanFailed();

    IERC20(token).transferFrom(msg.sender, address(this), amount);

    emit Flashloan(msg.sender, token, amount);

  }

}


