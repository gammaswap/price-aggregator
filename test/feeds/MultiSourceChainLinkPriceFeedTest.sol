// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import "../contracts/TestChainLinkOracle.sol";
import "../../contracts/feeds/MultiSourceChainLinkPriceFeed.sol";

contract MultiSourceChainLinkPriceFeedTest is Test {

    TestChainLinkOracle oracle1;
    TestChainLinkOracle oracle2;
    TestChainLinkOracle oracle3;
    MultiSourceChainLinkPriceFeed feed;

    function setUp() public {
        oracle1 = new TestChainLinkOracle();
        oracle2 = new TestChainLinkOracle();
        oracle3 = new TestChainLinkOracle();

        uint8[] memory oracleDecimals = new uint8[](3);
        bool[] memory isReverse = new bool[](3);
        address[] memory oracles = new address[](3);
        oracles[0] = address(oracle1);
        oracles[1] = address(oracle2);
        oracles[2] = address(oracle3);
        oracleDecimals[0] = 6;
        oracleDecimals[1] = 6;
        oracleDecimals[2] = 18;
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);
    }

    function testMultiSourceChainLinkConstructorErrors() public {
        address[] memory oracles = new address[](0);
        uint8[] memory oracleDecimals = new uint8[](1);
        bool[] memory isReverse = new bool[](1);

        vm.expectRevert("NOT_MULTIPLE_ORACLE_ADDRESS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracles = new address[](1);
        vm.expectRevert("NOT_MULTIPLE_ORACLE_ADDRESS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracles = new address[](2);
        vm.expectRevert("INVALID_ORACLE_LENGTH");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracleDecimals = new uint8[](2);
        vm.expectRevert("INVALID_REVERSE_LENGTH");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        isReverse = new bool[](2);
        vm.expectRevert("ZERO_ORACLE_ADDRESS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracles[0] = address(1);
        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracleDecimals[0] = 6;
        vm.expectRevert("ZERO_ORACLE_ADDRESS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracles[1] = address(2);
        vm.expectRevert("INVALID_ORACLE_DECIMALS");
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        oracleDecimals[1] = 6;
        feed = new MultiSourceChainLinkPriceFeed(1, 6, oracles, oracleDecimals, isReverse);

        for(uint256 i = 0; i < oracles.length; i++) {
            assertEq(oracles[i],address(uint160(i + 1)));
            assertEq(oracleDecimals[i], 6);
            assertEq(isReverse[i],false);
        }
    }
}