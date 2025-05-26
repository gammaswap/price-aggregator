// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import "../../contracts/feeds/base/PriceFeed.sol";

contract TestPriceFeed is PriceFeed {

    uint256 private price;
    bool private stale;

    constructor(uint16 _feedId, uint8 _decimals) PriceFeed(_feedId, _decimals) {
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function setStale(bool _stale) external {
        stale = _stale;
    }

    function _getPrice(uint256, bool) internal virtual override view returns (uint256, bool) {
        return (price, stale);
    }
}