// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import '@gammaswap/v1-periphery/contracts/base/Transfers.sol';

import "./interfaces/IPriceAggregator.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IHeartbeatStore.sol";

/// @title Price Aggregator contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used to get prices from multiple sources (e.g. oracles, AMMs, etc.) defined as PriceFeed contracts
/// @dev PriceFeeds can implement Oracles, AMMs, or any combination or logic to determine a price
contract PriceAggregator is IPriceAggregator, IHeartbeatStore, Initializable, UUPSUpgradeable, Transfers, Ownable2Step {

    /// @inheritdoc IPriceAggregator
    mapping(uint16 => address) public override getPriceFeed;

    /// @inheritdoc IHeartbeatStore
    mapping(uint16 => uint256) public override getHeartbeat;

    uint256[50] private __gap;

    /// @dev Initialize `WETH` address to Wrapped Ethereum contract
    constructor(address _WETH) Transfers(_WETH) {
    }

    /// @inheritdoc IPriceAggregator
    function initialize() public virtual override initializer {
        require(owner() == address(0), "PRICE_AGGREGATOR_INITIALIZED");
        _transferOwnership(msg.sender);
    }

    /// @inheritdoc IPriceAggregator
    function addPriceFeed(address feed) external virtual override onlyOwner {
        require(feed != address(0), "ZERO_ADDRESS");
        uint16 feedId = IPriceFeed(feed).feedId();
        require(feedId > 0, "ZERO_ID");
        require(getPriceFeed[feedId] == address(0), "FEED_ID_UNAVAILABLE");

        getPriceFeed[feedId] = feed;

        emit AddPriceFeed(feedId, feed);
    }

    /// @inheritdoc IPriceAggregator
    function updatePriceFeed(uint16 feedId, address newFeed) external virtual override onlyOwner {
        require(feedId > 0, "ZERO_ID");
        require(newFeed != address(0), "ZERO_ADDRESS");
        require(feedId == IPriceFeed(newFeed).feedId(), "WRONG_FEED");

        address oldFeed = getPriceFeed[feedId];

        require(oldFeed != address(0), "PRICE_FEED_DOES_NOT_EXIST");

        getPriceFeed[feedId] = newFeed;

        emit UpdatePriceFeed(feedId, oldFeed, newFeed);
    }

    /// @inheritdoc IPriceAggregator
    function removePriceFeed(uint16 feedId) external virtual override onlyOwner {
        require(feedId > 0, "ZERO_ID");

        address feed = getPriceFeed[feedId];

        require(feed != address(0), "PRICE_FEED_DOES_NOT_EXIST");

        delete getPriceFeed[feedId];

        emit RemovePriceFeed(feedId, feed);
    }

    /// @inheritdoc IHeartbeatStore
    function setHeartbeat(uint16 feedId, uint256 heartbeat) external virtual override onlyOwner {
        require(feedId > 0, "ZERO_ID");
        getHeartbeat[feedId] = heartbeat;
    }

    /// @inheritdoc IPriceAggregator
    function getPrice(uint16 feedId, uint256 maxAge, bool strict) external virtual override view returns (uint256) {
        address feed = _getPriceFeed(feedId);
        return IPriceFeed(feed).getPrice(maxAge, strict);
    }

    /// @inheritdoc IPriceAggregator
    function getPriceByTime(uint16 feedId, uint256 maxSeconds, bool strict) external virtual override view returns (uint256, bool) {
        address feed = _getPriceFeed(feedId);
        return IPriceFeed(feed).getPriceByTime(maxSeconds, strict);
    }

    /// @inheritdoc IPriceAggregator
    function getPriceByHeartbeats(uint16 feedId, uint256 maxHeartbeats, bool strict) external virtual override view returns (uint256, bool) {
        address feed = _getPriceFeed(feedId);
        return IPriceFeed(feed).getPriceByHeartbeats(maxHeartbeats, strict);
    }

    function _getPriceFeed(uint16 feedId) internal view returns(address) {
        require(feedId > 0, "ZERO_ID");

        address feed = getPriceFeed[feedId];

        require(feed != address(0), "ZERO_ADDRESS");

        return feed;
    }

    function getGammaPoolAddress(address, uint16) internal virtual override view returns(address) {
        return address(0);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}