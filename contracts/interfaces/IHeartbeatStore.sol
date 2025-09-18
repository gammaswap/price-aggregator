// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Hearbeat Store Contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface for contract to store heartbeats of different price feeds
/// @dev Hearbeat is stored in seconds
interface IHeartbeatStore {

    /// @dev Get heartbeat by feed source address
    /// @param feed - address of feed source
    /// @return heartbeat - max time elapsed in seconds before source price feed updates
    function getHeartbeat(address feed) external view returns(uint256 heartbeat);

    /// @dev Set the heartbeat of a feed source
    /// @param feed - address of feed source
    /// @param heartbeat - max time elapsed in seconds before source price feed updates
    function setHeartbeat(address feed, uint256 heartbeat) external;
}
