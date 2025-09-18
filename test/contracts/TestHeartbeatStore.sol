// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../contracts/interfaces/IHeartbeatStore.sol";

contract TestHeartbeatStore is IHeartbeatStore {

    mapping(uint16 => mapping(uint256 => uint256)) public override getHeartbeatByIndex;

    constructor(){
    }

    function getHeartbeat(uint16 feedId) external virtual override view returns(uint256) {
        return getHeartbeatByIndex[feedId][0];
    }

    function setHeartbeat(uint16 feedId, uint256 heartbeat) external virtual override {
        getHeartbeatByIndex[feedId][0] = heartbeat;
    }

    function setHeartbeatByIndex(uint16 feedId, uint256 index, uint256 heartbeat) external virtual override {
        getHeartbeatByIndex[feedId][index] = heartbeat;
    }
}
