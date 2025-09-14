// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "./contracts/TestPriceFeed.sol";
import "./contracts/TestHeartbeatStore.sol";

contract PriceFeedTest is Test {

    TestPriceFeed feed;
    TestHeartbeatStore heartbeatStore;

    function setUp() public {
        heartbeatStore = new TestHeartbeatStore();
        feed = new TestPriceFeed(1, 6, address(heartbeatStore));
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

    function testGetPriceByTime() public {
        (uint256 price, bool ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(0,true);
        assertEq(price, 1e18);
        assertTrue(ok);

        feed.setStale(true);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertFalse(ok);

        feed.setStale(false);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertTrue(ok);

        feed.setPrice(0);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 0);
        assertFalse(ok);
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


    function testGetPriceByTimeStrict() public {
        feed.setStale(true);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByTime(0,true);

        (uint256 price, bool ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertFalse(ok);

        feed.setStale(false);
        feed.setPrice(0);

        vm.expectRevert("INVALID_PRICE");
        feed.getPriceByTime(0,true);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 0);
        assertFalse(ok);
    }

    // TODO: Finish this section
    function testGetPriceByHeartbeats() public {
        assertEq(feed.heartbeatStore(), address(heartbeatStore));
        (uint256 price, bool ok) = feed.getPriceByHeartbeats(0,false);
        assertEq(price, 1e18);
        assertTrue(ok);

        /*(price, ok) = feed.getPriceByTime(0,true);
        assertEq(price, 1e18);
        assertTrue(ok);

        feed.setStale(true);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertFalse(ok);

        feed.setStale(false);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 1e18);
        assertTrue(ok);

        feed.setPrice(0);

        (price, ok) = feed.getPriceByTime(0,false);
        assertEq(price, 0);
        assertFalse(ok);/**/
    }
}

