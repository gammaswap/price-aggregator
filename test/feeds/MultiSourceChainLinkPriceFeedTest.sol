// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "../contracts/TestChainLinkOracle.sol";
import "../contracts/TestMultiSourceChainLinkPriceFeed.sol";
import "../../contracts/feeds/MultiSourceChainLinkPriceFeed.sol";
import "../../contracts/interfaces/IHeartbeatStore.sol";
import { PriceAggregator } from "../../contracts/PriceAggregator.sol";

contract MultiSourceChainLinkPriceFeedTest is Test {

    TestChainLinkOracle oracle1;
    TestChainLinkOracle oracle2;
    TestChainLinkOracle oracle3;

    address[] public mOracles;
    uint8[] public mOracleDecimals;
    bool[] public mIsReverse;

    TestMultiSourceChainLinkPriceFeed feed;

    IHeartbeatStore heartbeatStore;

    function setUp() public {
        oracle1 = new TestChainLinkOracle();
        oracle2 = new TestChainLinkOracle();
        oracle3 = new TestChainLinkOracle();

        mOracleDecimals = new uint8[](3);
        mIsReverse = new bool[](3);
        mOracles = new address[](3);

        mOracles[0] = address(oracle1);
        mOracles[1] = address(oracle2);
        mOracles[2] = address(oracle3);

        mOracleDecimals[0] = 8;
        mOracleDecimals[1] = 6;
        mOracleDecimals[2] = 18;

        heartbeatStore = IHeartbeatStore(address(new PriceAggregator(address(0))));

        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, mOracles, mOracleDecimals,
            mIsReverse, address(heartbeatStore));
    }

    function testBTCUSD_ETHUSD_PriceFeed() public {
        address[] memory oracles = new address[](2);
        uint8[] memory oracleDecimals = new uint8[](2);
        bool[] memory isReverse = new bool[](2);

        oracle1 = new TestChainLinkOracle(); // cbBtc/usd
        oracle2 = new TestChainLinkOracle(); // eth/usd
        oracles[0] = address(oracle1);
        oracles[1] = address(oracle2);
        oracleDecimals[0] = 8;
        oracleDecimals[1] = 8;

        int256 btcUsdPx = 11147686164321;
        int256 ethUsdPx = 464046457000;
        oracle1.setAnswer(btcUsdPx);
        oracle2.setAnswer(ethUsdPx);

        // (cbBTC/USD) x (USD/ETH) = (cbBTC/USD) / (ETH/USD) = cbBTC/ETH => reverse ETH/USD

        isReverse[0] = false;
        isReverse[1] = true;

        feed = new TestMultiSourceChainLinkPriceFeed(1, 18, oracles, oracleDecimals,
            isReverse, address(heartbeatStore));

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 0, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 0), 1000); // heartbeat is a maxAge of 1000 seconds

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 1, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 1), 1000); // heartbeat is a maxAge of 1000 seconds

        uint256 price = feed.getPrice(type(uint256).max, false);
        assertApproxEqRel(price,uint256(btcUsdPx)*1e18/uint256(ethUsdPx),1e12);

        bool ok;
        (price, ok)= feed.getPriceByTime(type(uint256).max, false);
        assertApproxEqRel(price,uint256(btcUsdPx)*1e18/uint256(ethUsdPx),1e12);

        (price, ok)= feed.getPriceByHeartbeats(type(uint256).max, false);
        assertApproxEqRel(price,uint256(btcUsdPx)*1e18/uint256(ethUsdPx),1e12);

        oracle1.setAnswer(ethUsdPx);
        oracle2.setAnswer(btcUsdPx);

        // (ETH/USD) x (USD/cbBTC) = (ETH/USD) / (cbBTC/USD) = ETH/cbBTC => reverse cbBTC/USD

        isReverse[0] = false;
        isReverse[1] = true;

        price = feed.getPrice(type(uint256).max, false);
        assertApproxEqRel(price,uint256(ethUsdPx)*1e18/uint256(btcUsdPx),1e12);

        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertApproxEqRel(price,uint256(ethUsdPx)*1e18/uint256(btcUsdPx),1e12);

        (price, ok)= feed.getPriceByHeartbeats(type(uint256).max, false);
        assertApproxEqRel(price,uint256(ethUsdPx)*1e18/uint256(btcUsdPx),1e12);
    }

    function testMultiSourceChainLinkConstructorErrors() public {
        address[] memory oracles = new address[](0);
        uint8[] memory oracleDecimals = new uint8[](1);
        bool[] memory isReverse = new bool[](1);

        vm.expectRevert("NOT_MULTIPLE_ORACLE_ADDRESS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracles = new address[](1);
        vm.expectRevert("NOT_MULTIPLE_ORACLE_ADDRESS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracles = new address[](2);
        vm.expectRevert("INVALID_ORACLE_LENGTH");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracleDecimals = new uint8[](2);
        vm.expectRevert("INVALID_REVERSE_LENGTH");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        isReverse = new bool[](2);
        vm.expectRevert("ZERO_ORACLE_ADDRESS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracles[0] = address(1);
        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracleDecimals[0] = 6;
        vm.expectRevert("ZERO_ORACLE_ADDRESS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracles[1] = address(2);
        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        oracleDecimals[1] = 6;
        feed = new TestMultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse, address(heartbeatStore));

        for(uint256 i = 0; i < oracles.length; i++) {
            assertEq(oracles[i],address(uint160(i + 1)));
            assertEq(oracleDecimals[i], 6);
            assertEq(isReverse[i],false);
        }
    }

    function testMultiSourceChainLinkGetSingleOraclePrice() public {
        oracle1.setAnswer(1e8);

        vm.warp(10);

        (uint256 price, bool stale) = feed.getSingleOraclePrice(0, type(uint256).max, false, false, 0);
        assertEq(price, 1e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 0);
        assertEq(price, 1e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, 11, true, false, 0);
        assertEq(price, 1e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, 10, true, false, 0);
        assertEq(price, 1e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, 9, true, false, 0);
        assertEq(price, 1e18);
        assertEq(stale,true);

        oracle1.setAnswer(2e8);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, false, false, 0);
        assertEq(price, 2e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 0);
        assertEq(price, 2e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, true, 0);
        assertEq(price, 5e17);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, true, 6);
        assertEq(price, 5e15);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 6);
        assertEq(price, 2e20);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 8);
        assertEq(price, 2e18);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, true, 8);
        assertEq(price, 5e17);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 18);
        assertEq(price, 2e8);
        assertEq(stale,false);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, true, 18);
        assertEq(price, 5e27);
        assertEq(stale,false);

        oracle1.setAnswer(-int256(1));
        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, false, true, 18);
        assertEq(price, 0);

        vm.expectRevert("NEGATIVE_PRICE");
        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, true, 18);

        oracle1.setAnswer(311289234796);
        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 8);
        assertEq(price, 311289234796e10);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 18);
        assertEq(price, 311289234796);

        vm.warp(1000);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, false, false, 20);
        assertEq(price, 3112892347);

        (price, stale) = feed.getSingleOraclePrice(0, type(uint256).max, true, false, 20);
        assertEq(price, 3112892347);

        oracle2.setAnswer(411289234796);
        (price, stale) = feed.getSingleOraclePrice(1, 1000, true, false, 20);
        assertEq(price, 4112892347);

        (price, stale) = feed.getSingleOraclePrice(1, 1000, false, false, 20);
        assertEq(price, 4112892347);

        (price, stale) = feed.getSingleOraclePrice(1, 1000 - 2, true, false, 20);
        assertEq(stale, true);

        (price, stale) = feed.getSingleOraclePrice(1, 1000 - 2, false, false, 18);
        assertEq(price, 411289234796);
        assertEq(stale, true);

        vm.warp(1002);

        (price, stale) = feed.getSingleOraclePrice(1, 1002, false, false, 18);
        assertEq(price, 411289234796);
        assertEq(stale, false);

        (price, stale) = feed.getSingleOraclePrice(1, 1002, true, false, 18);
        assertEq(price, 411289234796);
        assertEq(stale, false);

        (price, stale) = feed.getSingleOraclePrice(1, 1002, true, true, 18);
        assertEq(price, 1e36/uint256(411289234796));
        assertEq(stale, false);
    }

    function testMultiSourceChainLinkGetPrice() public {
        oracle1.setAnswer(1e8);
        oracle2.setAnswer(1e6);
        oracle3.setAnswer(1e18);

        uint256 price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 1e6);

        price = feed.getPrice(type(uint256).max, true);
        assertEq(price, 1e6);

        oracle2.setAnswer(2e8);

        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 200e6);

        price = feed.getPrice(type(uint256).max, true);
        assertEq(price, 200e6);

        oracle3.setAnswer(-int256(1));
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 0);

        vm.expectRevert("NEGATIVE_PRICE");
        price = feed.getPrice(type(uint256).max, true);

        oracle3.setAnswer(311289234796);
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e18));

        oracle1.setAnswer(311289234796);
        oracle3.setAnswer(1e18);
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e8));

        vm.warp(1000);

        oracle2.setAnswer(1e6);
        price = feed.getPrice(type(uint256).max, false);
        assertEq(price, 3112892347);

        price = feed.getPrice(type(uint256).max, true);
        assertEq(price, 3112892347);

        price = feed.getPrice(1000, true);
        assertEq(price, 3112892347);

        price = feed.getPrice(1000, false);
        assertEq(price, 3112892347);

        oracle2.setAnswer(2e6);
        feed.setReverse(1,true);
        price = feed.getPrice(1000, true);
        assertEq(price, uint256(3112892347) / 2);

        price = feed.getPrice(1000, false);
        assertEq(price, uint256(3112892347) / 2);

        vm.expectRevert("STALE_PRICE");
        price = feed.getPrice(1000 - 2, true);

        price = feed.getPrice(1000 - 2, false);
        assertEq(price, 0);

        vm.warp(1002);

        oracle3.setAnswer(2e18);
        feed.setReverse(2,true);
        price = feed.getPrice(1002, false);
        assertEq(price, uint256(3112892347)/4);

        price = feed.getPrice(1002, true);
        assertEq(price, uint256(3112892347)/4);
    }

    function testMultiSourceChainLinkGetPriceByTime() public {
        oracle1.setAnswer(1e8);
        oracle2.setAnswer(1e6);
        oracle3.setAnswer(1e18);

        (uint256 price, bool ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 1e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(type(uint256).max, true);
        assertEq(price, 1e6);
        assertTrue(ok);

        oracle2.setAnswer(2e8);

        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 200e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(type(uint256).max, true);
        assertEq(price, 200e6);
        assertTrue(ok);

        oracle3.setAnswer(-int256(1));
        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 0);
        assertFalse(ok);

        vm.expectRevert("NEGATIVE_PRICE");
        feed.getPriceByTime(type(uint256).max, true);

        oracle3.setAnswer(311289234796);
        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e18));
        assertTrue(ok);

        oracle1.setAnswer(311289234796);
        oracle3.setAnswer(1e18);
        (price, ok) = feed.getPriceByTime(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e8));
        assertTrue(ok);

        vm.warp(1000);

        oracle2.setAnswer(1e6);
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

        oracle2.setAnswer(2e6);
        feed.setReverse(1,true);
        (price, ok) = feed.getPriceByTime(1000, true);
        assertEq(price, uint256(3112892347) / 2);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(1000, false);
        assertEq(price, uint256(3112892347) / 2);
        assertTrue(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByTime(1000 - 2, true);

        (price, ok) = feed.getPriceByTime(1000 - 2, false);
        assertEq(price, uint256(3112892347) / 2);
        assertFalse(ok);

        vm.warp(1002);

        oracle3.setAnswer(2e18);
        feed.setReverse(2,true);
        (price, ok) = feed.getPriceByTime(1002, false);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByTime(1002, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);
    }

    function testMultiSourceChainLinkGetPriceByHeartbeats() public {

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 0, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 0), 1000); // heartbeat is a maxAge of 1000 seconds

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 1, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 1), 1000); // heartbeat is a maxAge of 1000 seconds

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 2, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 2), 1000); // heartbeat is a maxAge of 1000 seconds

        oracle1.setAnswer(1e8);
        oracle2.setAnswer(1e6);
        oracle3.setAnswer(1e18);

        (uint256 price, bool ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 1e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 1e6);
        assertTrue(ok);

        oracle2.setAnswer(2e8);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 200e6);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 200e6);
        assertTrue(ok);

        oracle3.setAnswer(-int256(1));
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 0);
        assertFalse(ok);

        vm.expectRevert("NEGATIVE_PRICE");
        feed.getPriceByHeartbeats(type(uint256).max, true);

        oracle3.setAnswer(311289234796);
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e18));
        assertTrue(ok);

        oracle1.setAnswer(311289234796);
        oracle3.setAnswer(1e18);
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 200e6 * 311289234796 / uint256(1e8));
        assertTrue(ok);

        vm.warp(1000);

        oracle2.setAnswer(1e6);
        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(type(uint256).max, true);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1000, true);
        assertEq(price, 3112892347);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1000, false);
        assertEq(price, 3112892347);
        assertTrue(ok);

        oracle2.setAnswer(2e6);
        feed.setReverse(1,true);
        (price, ok) = feed.getPriceByHeartbeats(1000, true);
        assertEq(price, uint256(3112892347) / 2);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1000, false);
        assertEq(price, uint256(3112892347) / 2);
        assertTrue(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1000 - 2, true);

        (price, ok) = feed.getPriceByHeartbeats(1000 - 2, false);
        assertEq(price, uint256(3112892347) / 2);
        assertFalse(ok);

        vm.warp(1002);

        oracle3.setAnswer(2e18);
        feed.setReverse(2,true);
        (price, ok) = feed.getPriceByHeartbeats(1002, false);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1002, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 0, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 0), 1000); // heartbeat is a maxAge of 1000 seconds

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 1, 1002);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 1), 1002); // heartbeat is a maxAge of 1000 seconds

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 2, 1000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 2), 1000); // heartbeat is a maxAge of 1000 seconds

        (price, ok) = feed.getPriceByHeartbeats(1002, false); // 100.2% or 1.002 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        vm.warp(1004);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1002, true);

        (price, ok) = feed.getPriceByHeartbeats(1002, false); // 100.2% or 1.002 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertFalse(ok);

        (price, ok) = feed.getPriceByHeartbeats(1004, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        heartbeatStore.setHeartbeatByIndex(feed.feedId(), 1, 2000);
        assertEq(heartbeatStore.getHeartbeatByIndex(feed.feedId(), 1), 2000); // heartbeat is a maxAge of 1000 seconds

        (price, ok) = feed.getPriceByHeartbeats(1004, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        vm.warp(2000);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1004, true);

        (price, ok) = feed.getPriceByHeartbeats(1004, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertFalse(ok);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(2000-1, true);

        (price, ok) = feed.getPriceByHeartbeats(2000-1, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertFalse(ok);

        (price, ok) = feed.getPriceByHeartbeats(2000, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(2000, true); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        oracle1.setUpdatedAt(block.timestamp);
        oracle3.setUpdatedAt(block.timestamp);

        (price, ok) = feed.getPriceByHeartbeats(2000-1, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(2000-1, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1004, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1004, false); // 100.4% or 1.004 heartbeats
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        vm.warp(2008);

        (price, ok) = feed.getPriceByHeartbeats(1004, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1004, false);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        vm.warp(2009);

        vm.expectRevert("STALE_PRICE");
        feed.getPriceByHeartbeats(1004, true);

        (price, ok) = feed.getPriceByHeartbeats(1004, false);
        assertEq(price, uint256(3112892347)/4);
        assertFalse(ok);

        oracle2.setUpdatedAt(block.timestamp);

        (price, ok) = feed.getPriceByHeartbeats(1004, true);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);

        (price, ok) = feed.getPriceByHeartbeats(1004, false);
        assertEq(price, uint256(3112892347)/4);
        assertTrue(ok);
    }
}