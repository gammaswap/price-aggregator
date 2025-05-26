// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract TestChainLinkOracle is AggregatorV3Interface {

    int256 private answer;
    uint256 private updatedAt;

    constructor() {
    }

    function setAnswer(int256 _answer) external {
        answer = _answer;
    }

    function setUpdatedAt(uint256 _updatedAt) external {
        updatedAt = _updatedAt;
    }

    function decimals() external view returns (uint8) {
        return 8;
    }

    function description() external view returns (string memory) {
        return "";
    }

    function version() external view returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt,
        uint256 updatedAt, uint80 answeredInRound) {
    }

    function latestRoundData() external view returns (uint80 roundId, int256 _answer, uint256 startedAt, uint256 _updatedAt, uint80 answeredInRound) {
        _answer = answer;
        _updatedAt = updatedAt;
    }
}
