// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../interfaces/IPriceFeed.sol";

/// @title Base Price Feed Contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Base abstract contract to be inherited by all PriceFeed implementations
abstract contract PriceFeed is IPriceFeed {

    /// @inheritdoc IPriceFeed
    uint16 immutable public override feedId;

    /// @inheritdoc IPriceFeed
    uint8 immutable public override decimals;

    /// @dev Initialize feedId of PriceFeed and decimals of price returned by this PriceFeed
    constructor(uint16 _feedId, uint8 _decimals) {
        require(_feedId > 0, "INVALID_FEED_ID");
        require(_decimals >= 6, "INVALID_DECIMALS");
        feedId = _feedId;
        decimals = _decimals;
    }

    /// @inheritdoc IPriceFeed
    function getPrice(uint256 maxAge, bool strict) external virtual override view returns (uint256 price) {

        bool stale;
        (price, stale) = _getPrice(maxAge, strict);

        if(strict) {
            require(price > 0, "INVALID_PRICE");
            require(!stale, "STALE_PRICE");
        } else if(stale) {
            price = 0;
        }

        return price;
    }

    /// @dev Implemented by concrete PriceFeeds to get the price according to its own specific logic
    /// @param maxAge - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from this price feed
    /// @return stale - true if price was updated more than maxAge seconds ago
    function _getPrice(uint256 maxAge, bool strict) internal virtual view returns (uint256 price, bool stale);
}
