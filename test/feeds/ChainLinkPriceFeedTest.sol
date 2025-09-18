// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "../contracts/TestChainLinkOracle.sol";
import "../../contracts/feeds/ChainLinkPriceFeed.sol";
import "../contracts/TestHeartbeatStore.sol";

contract ChainLinkPriceFeedTest is Test {

    TestChainLinkOracle oracle;
    ChainLinkPriceFeed feed;
    TestHeartbeatStore heartbeatStore;

    function setUp() public {
        oracle = new TestChainLinkOracle();
        heartbeatStore = new TestHeartbeatStore();
        feed = new ChainLinkPriceFeed(1, 6, address(oracle), 8, address(heartbeatStore));
    }

    function testChainLinkConstructorErrors() public {
        vm.expectRevert("ZERO_ADDRESS");
        feed = new ChainLinkPriceFeed(1, 6, address(0), 5, address(heartbeatStore));

        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new ChainLinkPriceFeed(1, 6, address(oracle), 5, address(heartbeatStore));
    }

    function testChainLinkGetPrice() public {
        oracle.setAnswer(1e8);

        uint256 price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 1e6);

        price = feed.getPrice(type(uint256).max, true);
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

    function testChainLinkGetPriceByTime() public {
        oracle.setAnswer(1e8);

        (uint256 price, bool ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 1e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(type(uint256).max, true);
        assertEq(price, 1e6);
        assertTrue(ok);

        oracle.setAnswer(2e8);

        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 2e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(type(uint256).max, true);
        assertEq(price, 2e6);
        assertTrue(ok);

        oracle.setAnswer(-int256(1));
        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 0);
        assertFalse(ok);

        vm.expectRevert("NEGATIVE_PRICE");
        feed.getPriceByTime(type(uint256).max, true);

        oracle.setAnswer(311289234796);
        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        vm.warp(1000);

        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(type(uint256).max, true);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(1000, true);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(1000, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByTime(1000 - 2, true);

        (price, ok) = feed.getPriceByTime(1000 - 2, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.warp(1002);

        (price, ok) = feed.getPriceByTime(1002, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(1002, true);
        assertEq(price, 3112892347);
        assertTrue(ok);
    }

    function testChainLinkGetPriceByZeroHeartbeats() public {
        oracle.setAnswer(1e8);

        assertEq(heartbeatStore.getHeartbeat(feed.oracle()), 0); // zero heartbeat is a maxAge of 0 seconds

        (uint256 price, bool ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 1e6);
        assertFalse(ok);


        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(type(uint256).max, true);

        oracle.setAnswer(2e8);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 2e6);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);

        oracle.setAnswer(-int256(1));
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 0);
        assertFalse(ok);

        vm.expectRevert("NEGATIVE_PRICE");
        feed.getPriceByHeartbeats(type(uint256).max, true);

        oracle.setAnswer(311289234796);
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.warp(1000);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertFalse(ok); // because maxAge will round to 1

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(type(uint256).max, true);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1000, true);

        (price, ok) = feed.getPriceByHeartbeats(1000, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1000 - 2, true);

        (price, ok) = feed.getPriceByHeartbeats(1000 - 2, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.warp(1002);

        (price, ok) = feed.getPriceByHeartbeats(1002, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1002, true);
    }

    function testChainLinkGetPriceByHeartbeats() public {
        oracle.setAnswer(1e8);

        heartbeatStore.setHeartbeat(feed.oracle(), 1000);

        assertEq(heartbeatStore.getHeartbeat(feed.oracle()), 1000); // heartbeat is a maxAge of 1000 seconds

        (uint256 price, bool ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 1e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 1e6);
        assertTrue(ok);

        oracle.setAnswer(2e8);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 2e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 2e6);
        assertTrue(ok);

        oracle.setAnswer(-int256(1));
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 0);
        assertFalse(ok);

        vm.expectRevert("NEGATIVE_PRICE");
        feed.getPriceByHeartbeats(type(uint256).max, true);

        oracle.setAnswer(311289234796);
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        vm.warp(1000);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1000, true); // 1000 = 100% and 1 heartbeat = 1000 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1000, false); // 1000 = 100% and 1 heartbeat = 1000 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1000 - 2, true);

        (price, ok) = feed.getPriceByHeartbeats(1000 - 2, false);
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.warp(1002);

        (price, ok) = feed.getPriceByHeartbeats(1002, false); // 1002 = 100.2% and 1 heartbeat = 1000 seconds so 1002 = 1002 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1001, false); // 1001 = 100.1% and 1 heartbeat = 1000 seconds so 1001 = 1001 seconds maxAge
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1001, true); // 1001 = 100.1% and 1 heartbeat = 1000 seconds so 1002 = 1001 seconds maxAge

        (price, ok) = feed.getPriceByHeartbeats(1003, false); // 1003 = 100.3% and 1 heartbeat = 1000 seconds so 1003 = 1003 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(2000, false); // 2000 = 200% and 1 heartbeat = 1000 seconds so 2000 = 2000 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);

        vm.warp(2001);

        (price, ok) = feed.getPriceByHeartbeats(2000, false); // 2000 = 200% and 1 heartbeat = 1000 seconds so 2000 = 2000 seconds maxAge
        assertEq(price, 3112892347);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        (price, ok) = feed.getPriceByHeartbeats(2000, true); // 2000 = 200% and 1 heartbeat = 1000 seconds so 2000 = 2000 seconds maxAge

        (price, ok) = feed.getPriceByHeartbeats(2001, false); // 2000 = 200% and 1 heartbeat = 1000 seconds so 2000 = 2000 seconds maxAge
        assertEq(price, 3112892347);
        assertTrue(ok);
    }
}
