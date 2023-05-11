/**
  @title ZNSDomain
  @dev Contract for issuing ZNS domains
  SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import { IZNSDomain } from "./IZNSDomain.sol";
import { ZNSRegistrar } from "../registrar/ZNSRegistrar.sol";

/**
 * @title ZNSDomain
 * @dev ERC721 contract for Zero Name Service (ZNS) domains.
*/
contract ZNSDomain is IZNSDomain, Initializable, ERC721Upgradeable {
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _domainIds;

  address private znsRegistrarAddress;

  modifier onlyRegistrar {
    require(msg.sender == znsRegistrarAddress, "ZNSDomain: Only the ZNSRegistrar can call this function");
    _;
  }

  /**
   * @dev Initializes the contract.
  */
  function initialize(address _znsRegistrar) public initializer {
    __ERC721_init("Zero Name Service (ZNS)", "ZNS");
    znsRegistrarAddress = _znsRegistrar;
  }

  /**
   * @dev Mint a new domain.
   * @param to The address to mint the domain to.
  * @param to The tokenID of the new domain.
  */
  function mintDomain(address to, uint256 tokenId) external onlyRegistrar {
    _safeMint(to, tokenId);
    _domainIds.increment();
  }

  /**
   * @dev Gets the URI of the domain metadata.
   * @param tokenId The ID of the domain to get the URI for.
   * @return The URI of the domain metadata.
  */
  function getTokenURI(uint256 tokenId) external view returns (string memory) {
    return super.tokenURI(tokenId);
  }

  /**
   * @dev Gets the total number of domains minted.
   * @return The total number of domains minted.
  */
  function totalSupply() external view returns (uint256) {
    return _domainIds.current();
  }

  /**
   * @dev Burns a domain.
   * @param tokenId The ID of the domain to burn.
  */
  function burn(uint256 tokenId, address owner) external onlyRegistrar {
    require(_isApprovedOrOwner(owner, tokenId), "ZNSDomain: caller is not owner nor approved");
    _burn(tokenId);
  }

  /**
    @dev Internal function to burn a domain.
    @param tokenId uint256 ID of the token to be burned.
  */
  function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
    super._burn(tokenId);
    _domainIds.decrement();
  }

  uint256[49] private __gap;
}