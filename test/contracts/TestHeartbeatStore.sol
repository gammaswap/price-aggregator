// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../contracts/interfaces/IHeartbeatStore.sol";

contract TestHeartbeatStore is IHeartbeatStore {

    mapping(address => uint256) public override getHeartbeat;

    constructor(){
    }

    function setHeartbeat(address feed, uint256 heartbeat) external virtual override {
        getHeartbeat[feed] = heartbeat;
    }
}
