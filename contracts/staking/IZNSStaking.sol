// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZNSStaking {
    function addStake(bytes32 domainHash, uint256 domainCost, address beneficiary) external;
    function withdrawStake(bytes32 domainHash, address beneficiary) external;
}