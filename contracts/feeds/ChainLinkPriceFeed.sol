// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IHeartbeatStore.sol";
import "../libraries/Utils.sol";
import "./base/PriceFeed.sol";

/// @title ChainLink Price Feed
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice PriceFeed implementation for ChainLink price feeds
contract ChainLinkPriceFeed is PriceFeed {

    /// @dev decimals of price returned by ChainLink price feed
    uint8 immutable public oracleDecimals;

    /// @dev address of price feed contract in ChainLink
    address immutable public oracle;

    /// @dev address holding heartbeat for this PriceFeed
    address immutable public heartbeatStore;

    /// @dev Initialize decimals, oracle, oracle decimals, and heartbeatStore
    constructor(uint16 _feedId, uint8 _decimals, address _oracle, uint8 _oracleDecimals, address _heartbeatStore)
        PriceFeed(_feedId, _decimals) {
        require(_oracle != address(0), "ZERO_ADDRESS");
        require(_oracleDecimals >= 6, "INVALID_ORACLE_DECIMALS");

        oracle = _oracle;
        oracleDecimals = _oracleDecimals;
        heartbeatStore = _heartbeatStore;
    }

    /// @inheritdoc PriceFeed
    function _getHeartbeat() internal virtual override view returns (uint256) {
        return IHeartbeatStore(heartbeatStore).getHeartbeat(oracle);
    }

    /// @inheritdoc PriceFeed
    function _getPrice(uint256 maxAge, bool strict) internal virtual override view returns (uint256 price, bool stale) {
        (,int256 feedPrice,,uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();

        if(feedPrice < 0) {
            require(!strict, "NEGATIVE_PRICE");
            feedPrice = 0;
        }

        stale = block.timestamp - updatedAt > maxAge;
        price = Utils.convertDecimals(uint256(feedPrice), oracleDecimals, decimals);
    }
}
