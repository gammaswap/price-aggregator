// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Price Aggregator
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used by all contracts that implement a PriceAggregator
interface IPriceAggregator {

    /// @dev Emitted when addPriceFeed() is called
    event AddPriceFeed(uint256 indexed feedId, address feed);

    /// @dev Emitted when removePriceFeed() is called
    event RemovePriceFeed(uint256 indexed feedId, address feed);

    /// @dev Emitted when updatePriceFeed() is called
    event UpdatePriceFeed(uint256 indexed feedId, address oldFeed, address newFeed);

    /// @dev Initialize PriceAggregator when used as a proxy contract
    function initialize() external;

    /// @dev Get PriceFeed contract by feedId
    /// @param feedId - ID that identifies price feed to get price from
    /// @return feed - PriceFeed associated with feedId
    function getPriceFeed(uint16 feedId) external view returns(address feed);

    /// @dev Add new PriceFeed contract address
    /// @param feed - address of PriceFeed contract to be added to PriceAggregator
    function addPriceFeed(address feed) external;

    /// @dev Update PriceFeed contract associated with feedId. Replaces old contract with new one
    /// @param feedId - ID that identifies PriceFeed contract in PriceAggregator (newFeed's id must match feedId)
    /// @param newFeed - address of new PriceFeed contract
    function updatePriceFeed(uint16 feedId, address newFeed) external;

    /// @dev Used by other contracts to get price from this price feed
    /// @param feedId - ID that identifies price feed to get price from
    function removePriceFeed(uint16 feedId) external;

    /// @dev Get price from PriceFeed identified by id
    /// @param feedId - ID that identifies price feed to get price from
    /// @param maxAge - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from price feed identified by feedId
    function getPrice(uint16 feedId, uint256 maxAge, bool strict) external view returns (uint256 price);
}
