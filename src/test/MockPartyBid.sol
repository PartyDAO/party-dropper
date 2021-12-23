// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../IPartyBid.sol";

contract MockPartyBid is IPartyBid {
    mapping(address => uint256) contributions;

    function totalContributed(address a) external view returns (uint256) {
        return contributions[a];
    }

    function setContribution(address a, uint256 amount) public {
        contributions[a] = amount;
    }
}
