// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IHeartbeatStore {

    /// @dev Get heartbeat by feedId
    /// @param feedId - ID that identifies price feed to get price from
    /// @return heartbeat - max time elapsed in seconds before price feed updates
    function getHeartbeat(uint16 feedId) external view returns(uint256 heartbeat);

    /// @dev Set the heartbeat for a price feed identified by its feedId
    /// @param feedId - ID that identifies price feed to get price from
    /// @param heartbeat - max time elapsed in seconds before price feed updates
    function setHeartbeat(uint16 feedId, uint256 heartbeat) external;
}
