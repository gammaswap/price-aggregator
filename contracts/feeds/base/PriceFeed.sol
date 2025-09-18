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

    /// @dev Initialize feedId of the PriceFeed, and decimals of token price is quoted in by this PriceFeed
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

        if(!_isPriceOk(price, stale, strict)) {
            price = 0;
        }

        return price;
    }

    /// @inheritdoc IPriceFeed
    function getPriceByTime(uint256 maxAge, bool strict) external virtual override view returns (uint256 price, bool ok) {
        bool stale;
        (price, stale) = _getPrice(maxAge, strict);
        ok = _isPriceOk(price, stale, strict);
    }

    /// @inheritdoc IPriceFeed
    function getPriceByHeartbeats(uint256 maxHeartbeats, bool strict) external virtual override view returns (uint256 price, bool ok) {
        if(maxHeartbeats > 100e3) maxHeartbeats = 100e3; // capped at 100 heartbeats

        bool stale;
        uint256 maxAge = maxHeartbeats * _getHeartbeat() / 1000;

        (price, stale) = _getPrice(maxAge, strict);
        ok = _isPriceOk(price, stale, strict);
    }

    /// @dev Return false if price is zero or stale. When in strict mode revert
    function _isPriceOk(uint256 price, bool stale, bool strict) internal virtual view returns (bool ok){
        ok = !stale;
        if(strict) {
            require(price > 0, "INVALID_PRICE");
            require(ok, "STALE_PRICE");
        } else if(price == 0) {
            ok = false;
        }
        return ok;
    }

    /// @dev Get heartbeat for PriceFeed
    /// @return heartbeat - maximum time it will take to update feed in seconds
    function _getHeartbeat() internal virtual view returns (uint256);

    /// @dev Implemented by concrete PriceFeeds to get the price according to its own specific logic
    /// @param maxAge - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from this price feed
    /// @return stale - true if price was updated more than maxAge seconds ago
    function _getPrice(uint256 maxAge, bool strict) internal virtual view returns (uint256 price, bool stale);
}
