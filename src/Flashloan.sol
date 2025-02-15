// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// AAVE
interface IAavePool {
  function supply(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
  function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode, address onBehalfOf) external;
}

// UNISWAP
interface ISwapRouter {
      struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// BALANCER
interface IFlashloan {
  function flashLoan(address recipient,address[] memory tokens,uint256[] memory amounts,bytes calldata userData) external;
}

contract Flashloan {
  // uniswap
  address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

  // aave
  address public lendingPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

  // balancer
  address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  
 function loopingSupply() public {
    // yg kita punya
    uint256 amount = 1e18; // 18 decimals

    // transfer 1 WETH ke contract
    IERC20(weth).transferFrom(msg.sender, address(this), amount);

    // menyiapkan parameter flashloan
    // meminjam WETH sebanyak 1 WETH
    address[] memory tokens = new address[](1);
    tokens[0] = weth;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1e18;

    IFlashloan(balancerVault).flashLoan(address(this),tokens,amounts,"");
  }

    function receiveFlashLoan(
      IERC20[] memory tokens,
      uint256[] memory amounts,
      uint256[] memory feeAmounts,
      bytes memory userData
  ) external  {
    require(msg.sender == balancerVault,'Not Balancer Vault');

    // flashloan pinjam 1 WETH
    // supply WETH ke AAVE = 2 WETH
    // borrow USDC = 3400e6 USDC
    // swap USC ke WETH = 3400e6 USDC swap ke WETH untuk mendapatkan 1 WETH
    // membayar flashloan 1 WETH

    IERC20(weth).approve(lendingPool, 2e18);
    IAavePool(lendingPool).supply(weth, 2e18, address(this), 0);

    IAavePool(lendingPool).borrow(usdc, 3400e6, 2, 0, address(this));

    IERC20(usdc).approve(router, 3400e6);
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
          tokenIn: usdc,
          tokenOut: weth,
          fee: 500,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: 3400e6,
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
      });

     uint256 amountOut = ISwapRouter(router).exactInputSingle(params);

     // repay flashloan
     IERC20(weth).transfer(balancerVault, 1e18);

     // sisanya jadikan supply
     uint256 dust = IERC20(weth).balanceOf(address(this));
     IERC20(weth).approve(lendingPool, dust);
     IAavePool(lendingPool).supply(weth, dust, address(this), 0);

  }

}
