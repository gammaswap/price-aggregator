// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./base/PriceFeed.sol";
import "../libraries/Utils.sol";

/// @title Multi-Source ChainLink Price Feed
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice PriceFeed implementation for Oracle using multiple ChainLink price feeds
contract MultiSourceChainLinkPriceFeed is PriceFeed {

    /// @dev decimals of price returned by ChainLink price feed
    uint8[] public oracleDecimals;

    /// @dev address of price feed contract in ChainLink
    address[] public oracles;

    /// @dev if true use the reciprocal of the price returned by ChainLink
    bool[] public isReverse;

    /// @dev Initialize decimals, oracles, and oracle decimals
    constructor(uint16 _feedId, uint8 _decimals, address[] memory _oracles, uint8[] memory _oracleDecimals, bool[] memory _isReverse) PriceFeed(_feedId, _decimals) {
        require(_oracles.length > 1, "NOT_MULTIPLE_ORACLE_ADDRESS");
        require(_oracles.length == _oracleDecimals.length, "INVALID_ORACLE_LENGTH");
        require(_oracles.length == _isReverse.length, "INVALID_REVERSE_LENGTH");
        for(uint256 i = 0; i < _oracles.length;) {
            require(_oracles[i] != address(0), "ZERO_ORACLE_ADDRESS");
            require(_oracleDecimals[i] >= 6, "INVALID_ORACLE_DECIMALS");
            unchecked {
                ++i;
            }
        }

        oracles = _oracles;
        oracleDecimals = _oracleDecimals;
        isReverse = _isReverse;
    }

    /// @inheritdoc PriceFeed
    function _getPrice(uint256 maxAge, bool strict) internal virtual override view returns (uint256 price, bool stale) {
        for(uint256 i = 0; i < oracles.length;) {
            (uint256 oraclePrice, bool isStale) = _getSingleOraclePrice(i, maxAge, strict);

            if(i == 0) {
                stale = isStale;
                price = oraclePrice;
            } else {
                stale = stale && isStale;
                price = price * oraclePrice / 1e18;
            }

            unchecked {
                ++i;
            }
        }

        price = Utils.convertDecimals(price, 18, decimals);
    }

    /// @dev Get individual oracle price formatted to be 18 decimals
    /// @param id - id of ChainLink in oracles array
    /// @param maxAge - maximum accepted age after which the price is considered stale
    /// @param strict - if true revert when price is negative, zero, or stale
    function _getSingleOraclePrice(uint256 id, uint256 maxAge, bool strict) internal virtual view returns (uint256 price, bool stale) {
        (,int256 feedPrice,,uint256 updatedAt,) = AggregatorV3Interface(oracles[id]).latestRoundData();

        if(feedPrice < 0) {
            require(!strict, "NEGATIVE_PRICE");
            feedPrice = 0;
        }

        stale = block.timestamp - updatedAt > maxAge;
        price = Utils.convertDecimals(uint256(feedPrice), oracleDecimals[id], 18);
        if(price > 0 && isReverse[id]) {
            price = 1e36 / price;
        }
    }
}
