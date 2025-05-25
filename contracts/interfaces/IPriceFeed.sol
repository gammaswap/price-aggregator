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

    /// @dev Used by other contracts to get price from this price feed
    /// @param maxAge - maximum age in seconds to determine if price is stale
    /// @param strict - if set to true revert when the price is stale or the price is non positive
    /// @return price - price from this price feed
    function getPrice(uint256 maxAge, bool strict) external view returns (uint256);
}
