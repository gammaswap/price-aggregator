// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Interface for Price Feed Contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface to wrap on any PriceFeed implementation (e.g. Oracles, AMMs, etc.)
/// @dev feedId must be unique for every PriceFeed that implements this interface
interface IPriceFeed {

    /// @dev ID that identifies this PriceFeed. Must be unique for each PriceFeed
    function feedId() external view returns(uint16);

    /// @dev decimals of price number returned by price feed
    function decimals() external view returns(uint8);

    /// @dev Get address of contract storing the price feed's heartbeat
    function heartbeatStore() external view returns(address);

    /// @dev Used by other contracts to get price from this price feed
    /// @param maxAge - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from this price feed
    function getPrice(uint256 maxAge, bool strict) external view returns (uint256);

    /// @dev Get price if not stale for more than `maxSeconds` ago
    /// @param maxSeconds - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from price feed identified by feedId
    /// @return ok - false if has an issue (e.g. stale)
    function getPriceByTime(uint256 maxSeconds, bool strict) external view returns (uint256 price, bool ok);

    /// @dev Get price if not stale for more than `maxHeartbeats` in tenths of 1% (e.g. 1 = 0.1%, 1000 = 100%, 1500 = 1.5 heartbeats)
    /// @param maxHeartbeats - maximum age in heartbeats to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from price feed identified by feedId
    /// @return ok - false if has an issue (e.g. stale)
    function getPriceByHeartbeats(uint256 maxHeartbeats, bool strict) external view returns (uint256 price, bool ok);
}