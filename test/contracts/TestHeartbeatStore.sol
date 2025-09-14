// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../contracts/interfaces/IHeartbeatStore.sol";

contract TestHeartbeatStore is IHeartbeatStore {

    mapping(uint16 => uint256) public override getHeartbeat;

    constructor(){
    }

    function setHeartbeat(uint16 feedId, uint256 heartbeat) external virtual override {
        getHeartbeat[feedId] = heartbeat;
    }
}
