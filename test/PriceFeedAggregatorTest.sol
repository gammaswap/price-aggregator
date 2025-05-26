// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./contracts/TestPriceFeed.sol";
import "../contracts/PriceAggregator.sol";

contract PriceFeedAggregatorTest is Test {

    TestPriceFeed feed;
    PriceAggregator agg;

    function setUp() public {
        feed = new TestPriceFeed(1, 6);
        feed.setPrice(1e18);

        agg = new PriceAggregator(address(0));
        agg.addPriceFeed(address(feed));
    }

    function testAddPriceFeed() public {
        vm.expectRevert("ZERO_ADDRESS");
        agg.addPriceFeed(address(0));

        TestPriceFeed2 feed0 = new TestPriceFeed2(0, 6);

        vm.expectRevert("ZERO_ID");
        agg.addPriceFeed(address(feed0));

        TestPriceFeed2 feed1 = new TestPriceFeed2(1, 6);

        vm.expectRevert("FEED_ID_UNAVAILABLE");
        agg.addPriceFeed(address(feed1));

        TestPriceFeed2 feed2 = new TestPriceFeed2(2, 6);
        agg.addPriceFeed(address(feed2));

        assertEq(agg.getPriceFeed(2), address(feed2));
    }

    function testUpdatePriceFeed() public {
        vm.expectRevert("ZERO_ID");
        agg.updatePriceFeed(0, address(0));

        vm.expectRevert("ZERO_ADDRESS");
        agg.updatePriceFeed(1, address(0));

        TestPriceFeed2 feed0 = new TestPriceFeed2(0, 6);

        vm.expectRevert("WRONG_FEED");
        agg.updatePriceFeed(1, address(feed0));

        TestPriceFeed2 feed1 = new TestPriceFeed2(1, 6);
        vm.expectRevert("WRONG_FEED");
        agg.updatePriceFeed(2, address(feed1));

        vm.expectRevert("WRONG_FEED");
        agg.updatePriceFeed(2, address(feed));

        agg.updatePriceFeed(1, address(feed));
        assertEq(agg.getPriceFeed(1), address(feed));

        TestPriceFeed2 feed2 = new TestPriceFeed2(2, 6);

        vm.expectRevert("WRONG_FEED");
        agg.updatePriceFeed(1, address(feed2));

        vm.expectRevert("PRICE_FEED_DOES_NOT_EXIST");
        agg.updatePriceFeed(2, address(feed2));

        agg.updatePriceFeed(1, address(feed1));
        assertEq(agg.getPriceFeed(1), address(feed1));
        assertNotEq(address(feed), address(feed1));
    }

    function testRemovePriceFeed() public {
        vm.expectRevert("ZERO_ID");
        agg.removePriceFeed(0);

        vm.expectRevert("PRICE_FEED_DOES_NOT_EXIST");
        agg.removePriceFeed(2);

        assertEq(agg.getPriceFeed(1), address(feed));

        agg.removePriceFeed(1);

        assertEq(agg.getPriceFeed(1), address(0));
    }

    function testAggGetPrice() public {
        vm.expectRevert("ZERO_ID");
        agg.getPrice(0, type(uint256).max, false);

        vm.expectRevert("ZERO_ADDRESS");
        agg.getPrice(2, type(uint256).max, false);

        uint256 price = agg.getPrice(1, type(uint256).max, false);
        assertEq(price, 1e18);

        feed.setPrice(2e18);

        price = agg.getPrice(1, type(uint256).max, false);
        assertEq(price, 2e18);
    }
}

contract TestPriceFeed2 is IPriceFeed {

    uint16 public override feedId;
    uint8 public override decimals;

    constructor(uint16 _feedId, uint8 _decimals) {
        feedId = _feedId;
        decimals = _decimals;
    }

    function getPrice(uint256, bool) external override view returns(uint256) {
        return 0;
    }
}