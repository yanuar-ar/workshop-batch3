// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


  interface IChainlink {
    function latestRoundData() external view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  }

contract WETHUSDCOracle {

  address quoteFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD
  address baseFeed = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC/USD

  function getPrice() public view returns (uint256) {
      (, int256 quotePrice,,,) = IChainlink(quoteFeed).latestRoundData();
      (, int256 basePrice,,,) = IChainlink(baseFeed).latestRoundData();
      return uint256(quotePrice) * 1e6 / uint256(basePrice);
  }
  

}
