// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IZNSDomain {
    function mintDomain(address to, uint256 tokenId) external;
    function getTokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function burn(uint256 tokenId, address owner) external;
}
