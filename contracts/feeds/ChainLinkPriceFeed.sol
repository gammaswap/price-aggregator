// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./base/PriceFeed.sol";

/// @title ChainLink Price Feed
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice PriceFeed implementation for ChainLink price feeds
contract ChainLinkPriceFeed is PriceFeed {

    /// @dev decimals of price returned by ChainLink price feed
    uint8 immutable public oracleDecimals;

    /// @dev address of price feed contract in ChainLink
    address immutable public oracle;

    /// @dev Initialize decimals, oracle, and oracle decimals
    constructor(uint16 _feedId, uint8 _decimals, address _oracle, uint8 _oracleDecimals) PriceFeed(_feedId, _decimals) {
        require(_oracleDecimals >= 6, "INVALID_ORACLE_DECIMALS");
        require(_oracle != address(0), "ZERO_ADDRESS");

        oracle = _oracle;
        oracleDecimals = _oracleDecimals;
    }

    /// @inheritdoc PriceFeed
    function _getPrice(uint256 maxAge, bool strict) internal virtual override view returns (uint256 price, bool stale) {
        (,int256 feedPrice,,uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();

        if(feedPrice < 0) {
            require(!strict, "NEGATIVE_PRICE");
            feedPrice = 0;
        }

        stale = block.timestamp - updatedAt > maxAge;
        price = _convertDecimals(uint256(feedPrice), oracleDecimals, decimals);
    }

    /// @dev Convert value number from a fromDecimals number to a toDecimals number
    /// @param value - number to convert
    /// @param fromDecimals - decimals of value to convert from
    /// @param toDecimals - decimals value will be converted to
    /// @return converted - value as a toDecimals number
    function _convertDecimals(uint256 value, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256 converted) {
        if (fromDecimals == toDecimals) {
            return value;
        } else if (fromDecimals > toDecimals) {
            return value / (10 ** (fromDecimals - toDecimals));
        } else {
            return value * (10 ** (toDecimals - fromDecimals));
        }
    }
}
