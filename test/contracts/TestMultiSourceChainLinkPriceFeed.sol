// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import "../../contracts/feeds/MultiSourceChainLinkPriceFeed.sol";

contract TestMultiSourceChainLinkPriceFeed is MultiSourceChainLinkPriceFeed {
    constructor(uint16 _feedId, uint8 _decimals, address[] memory _oracles, uint8[] memory _oracleDecimals,
        bool[] memory _isReverse) MultiSourceChainLinkPriceFeed(_feedId, _decimals, _oracles, _oracleDecimals,
        _isReverse) {
    }

    function setReverse(uint256 id, bool _isReverse) public {
        isReverse[id] = _isReverse;
    }

    function getSingleOraclePrice(uint256 id, uint256 maxAge, bool strict, bool _isReverse, uint8 _oracleDecimals)
        public virtual returns (uint256 price, bool stale) {
        isReverse[id] = _isReverse;
        if(_oracleDecimals > 5) {
            oracleDecimals[id] = _oracleDecimals;
        }
        return _getSingleOraclePrice(id, maxAge, strict);
    }
}
