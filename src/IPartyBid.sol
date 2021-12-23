// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPartyBid {
    function totalContributed(address) external view returns (uint256);
}
