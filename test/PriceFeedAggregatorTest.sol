// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./contracts/TestPriceFeed.sol";
import "../contracts/PriceAggregator.sol";
import "../contracts/libraries/Utils.sol";

contract PriceFeedAggregatorTest is Test {

    TestPriceFeed feed;
    PriceAggregator agg;

    function setUp() public {
        feed = new TestPriceFeed(1, 6);
        feed.setPrice(1e18);

        agg = new PriceAggregator(address(0));
        agg.addPriceFeed(address(feed));
    }

    function testDecimalConversions() public {
        (uint128 value, uint8 fromDecimals, uint8 toDecimals) = (0, 13, 0);
        fromDecimals = uint8(bound(fromDecimals, 6, 18));
        toDecimals = uint8(bound(toDecimals, 6, 18));
        value = uint128(bound(value, 1e6, 1e20));

        uint256 answer = Utils.convertDecimals(value, fromDecimals, toDecimals);

        if(fromDecimals == toDecimals) {
            assertEq(value, answer);
        } else if(fromDecimals > toDecimals) {
            uint256 diff = fromDecimals - toDecimals;
            uint256 threshold = 10**diff;
            if(value < threshold) {
                assertEq(answer,0);
            } else {
                assertGt(answer,0);
            }
        } else if(fromDecimals < toDecimals) {
            assertGt(answer,0);
        }
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

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        agg.addPriceFeed(address(feed2));

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

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        agg.updatePriceFeed(1, address(feed1));

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

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        agg.removePriceFeed(1);

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