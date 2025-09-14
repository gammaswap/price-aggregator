// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "./contracts/TestPriceFeed.sol";

contract PriceFeedTest is Test {

    TestPriceFeed feed;

    function setUp() public {
        feed = new TestPriceFeed(1, 6, address(0));
        feed.setPrice(1e18);
    }

    function testConstructorErrors() public {
        vm.expectRevert("INVALID_FEED_ID");
        feed = new TestPriceFeed(0, 6, address(0));

        vm.expectRevert("INVALID_DECIMALS");
        feed = new TestPriceFeed(1, 5, address(0));
    }

    function testGetPrice() public {
        uint256 price = feed.getPrice(0,false);
        assertEq(price, 1e18);

        price = feed.getPrice(0,true);
        assertEq(price, 1e18);

        feed.setStale(true);

        price = feed.getPrice(0,false);
        assertEq(price, 0);

        feed.setStale(false);

        price = feed.getPrice(0,false);
        assertEq(price, 1e18);

        feed.setPrice(0);

        price = feed.getPrice(0,false);
        assertEq(price, 0);
    }

    function testGetPriceStrict() public {
        feed.setStale(true);

        vm.expectRevert("STALE_PRICE");
        feed.getPrice(0,true);

        uint256 price = feed.getPrice(0,false);
        assertEq(price, 0);

        feed.setStale(false);
        feed.setPrice(0);

        vm.expectRevert("INVALID_PRICE");
        feed.getPrice(0,true);

        price = feed.getPrice(0,false);
        assertEq(price, 0);
    }

}

