// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "../contracts/TestChainLinkOracle.sol";
import "../../contracts/feeds/ChainLinkPriceFeed.sol";

contract ChainLinkPriceFeedTest is Test {

    TestChainLinkOracle oracle;
    ChainLinkPriceFeed feed;

    function setUp() public {
        oracle = new TestChainLinkOracle();
        feed = new ChainLinkPriceFeed(1, 6, address(oracle), 8);
    }

    function testChainLinkConstructorErrors() public {
        vm.expectRevert("ZERO_ADDRESS");
        feed = new ChainLinkPriceFeed(1, 6, address(0), 5);

        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new ChainLinkPriceFeed(1, 6, address(oracle), 5);
    }

    function testChainLinkGetPrice() public {
        oracle.setAnswer(1e8);

        uint256 price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 1e6);

        feed.getPrice(type(uint256).max, true);
        assertEq(price, 1e6);

        oracle.setAnswer(2e8);

        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 2e6);

        price = feed.getPrice(type(uint256).max, true);
        assertEq(price, 2e6);

        oracle.setAnswer(-int256(1));
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 0);

        vm.expectRevert("NEGATIVE_PRICE");
        price = feed.getPrice(type(uint256).max, true);

        oracle.setAnswer(311289234796);
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 3112892347);

        vm.warp(1000);

        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 3112892347);

        price = feed.getPrice(type(uint256).max, true);
        assertEq(price, 3112892347);

        price = feed.getPrice(1000, true);
        assertEq(price, 3112892347);

        price = feed.getPrice(1000, false);
        assertEq(price, 3112892347);

        vm.expectRevert("STALE_PRICE");
        price = feed.getPrice(1000 - 2, true);

        price = feed.getPrice(1000 - 2, false);
        assertEq(price, 0);

        vm.warp(1002);

        price = feed.getPrice(1002, false);
        assertEq(price, 3112892347);

        price = feed.getPrice(1002, true);
        assertEq(price, 3112892347);
    }
}
