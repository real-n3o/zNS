/**
  @title ZNSRegistrar
  @dev Contract for registering and updating ZNS domains
  @notice This contract allows users to register Zero Name Service (ZNS) domains
  @notice A ZNS domain is an ERC721 NFT token with a URI
  @notice Each domain costs a specified amount of Zero Tokens
  SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.18;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import { IZNSRegistrar } from "./IZNSRegistrar.sol";
import { ZNSDomain } from "../domain/ZNSDomain.sol";
import { ZNSStaking } from "../staking/ZNSStaking.sol";
import { ZEROToken } from "../token/ZEROToken.sol";

contract ZNSRegistrar is IZNSRegistrar, Initializable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

  uint256 public domainCost;
  ZNSDomain private znsDomain;
  ZEROToken private zeroToken;
  ZNSStaking private znsStaking;

  /**
   * @dev Stores information about a registered domain.
   * @param tokenId The token ID of the NFT representing the domain.
  */
  struct Domain {
    address owner;
    address domain;
    address resolver;
  }

  mapping(bytes32 => Domain) private _domains;

  modifier onlyOwner(bytes32 domainHash) {
    uint256 tokenId = uint256(domainHash);
    require(znsDomain.ownerOf(tokenId) == msg.sender, "ZNSRegistrar: Only the owner can call this function");
    _;
  }

  /**
    @dev Event emitted when a domain is minted
    @param domainHash The hash of the minted domain
    @param domainName The name of the minted domain
    @param owner The address of the domain owner
  */
  event DomainMinted(bytes32 indexed domainHash, string domainName, address indexed owner);

  /**
    * @dev Emitted when the token URI of a domain is updated.
    * @param tokenId The ID of the domain that had its token URI updated.
    * @param oldTokenURI The old token URI of the domain.
    * @param newTokenURI The new token URI of the domain.
  */
  event TokenURIUpdated(uint256 indexed tokenId, string oldTokenURI, string newTokenURI);

  /**
    * @dev Emitted when the cost of a domain is set.
    * @param newDomainCost The new cost of a domain.
    */
  event DomainCostSet(uint256 newDomainCost);

  /**
    * @dev Emitted when a domain is destroyed.
    * @param domainHash The hash of the destroyed domain.
    * @param domainName The name of the destroyed domain.
  */
  event DomainDestroyed(bytes32 indexed domainHash, string domainName);

  /**
    @dev Initializes the ZNSRegistrar contract
    @param _znsDomain The address of the ZNSDomain contract
    @param _zeroToken The address of the ZEROToken contract
    @param _znsStaking The address of the ZNSStaking contract
    @param _domainCost The cost of registering a domain in Zero Tokens
  */
  function initialize(ZNSDomain _znsDomain, ZEROToken _zeroToken, ZNSStaking _znsStaking, uint256 _domainCost) external initializer {
    __ReentrancyGuard_init();
    __ZNSRegistrar_init(_znsDomain, _zeroToken, _znsStaking, _domainCost);
  }

  function __ZNSRegistrar_init(ZNSDomain _znsDomain, ZEROToken _zeroToken, ZNSStaking _znsStaking, uint256 _domainCost) internal {
    // Check that the addresses are not the zero address
    require(_znsDomain != ZNSDomain(address(0)), "Invalid ZNSDomain address");
    require(_zeroToken != ZEROToken(address(0)), "Invalid ZeroToken address");
    require(_znsStaking != ZNSStaking(address(0)), "Invalid ZNSStaking address");
    
    znsDomain = _znsDomain;
    zeroToken = _zeroToken;
    znsStaking = _znsStaking;
    domainCost = _domainCost;
  }

  /**
    @dev Mints a new domain
    @param domainName The name of the domain to be minted
  */
  function mintDomain(string memory domainName) public nonReentrant {
    // Check if the domain name already exists
    require(isDomainAvailable(domainName) == true, "ZNSRegistrar: Domain name already exists with tokenId");
    bytes32 domainHash = hashDomainName(domainName);
    uint256 tokenId = uint256(domainHash);

    // Mint the domain
    znsDomain.mintDomain(msg.sender, tokenId);
    _domains[domainHash] = Domain(msg.sender, address(0), address(0));

    // Set default owner to msg.sender
    _domains[domainHash].owner == msg.sender;

    // Add stake
    znsStaking.addStake(domainHash, domainCost, msg.sender);

    emit DomainMinted(domainHash, domainName, msg.sender);
  }

  /**
    * @dev Destroys a domain.
    * @param domainName The ID of the domain to be destroyed.
  */
  function destroyDomain(string memory domainName) public nonReentrant {
    bytes32 domainHash = hashDomainName(domainName);

    // Check if the sender is the owner of the domain
    uint256 tokenId = uint256(domainHash);
    require(znsDomain.ownerOf(tokenId) == msg.sender, "Only the domain owner can withdraw staked tokens");

    // Delete, burn and withdraw the stake
    delete _domains[domainHash];
    znsStaking.withdrawStake(domainHash, msg.sender);
    znsDomain.burn(tokenId, msg.sender);
    // NOTE: May need to move this into ZNSStaking contract but need to determine AC

    emit DomainDestroyed(domainHash, domainName);
  }

  /**
    * @dev Gets the token ID associated with the given domain name.
    * @param domainName The name of the domain to get the token ID for.
    * @return The token ID of the domain.
  */
  function domainNameToTokenId(string memory domainName) public pure returns (uint256) {
    bytes32 domainHash = hashDomainName(domainName);
    uint256 tokenId = uint256(domainHash);
    return tokenId;
  }

  // To Do: Possibly offload to a separate pricing contract for upgradeability/modularity

  /**
    * @dev Sets the cost of a domain.
    * @param _newDomainCost The new cost for a domain.
  */
  // Note: Need AC
  function setDomainCost(uint256 _newDomainCost) external {
    domainCost = _newDomainCost;
    emit DomainCostSet(_newDomainCost);
  }

  /**
    * @dev Checks if a domain name is available for registration.
    * @param domainName The domain name to check availability for.
    * @return A boolean indicating whether the domain name is available (true) or not (false).
  */
  function isDomainAvailable(string memory domainName) public view returns (bool) {
    bytes32 domainHash = hashDomainName(domainName);
    return _domains[domainHash].owner == address(0);
  }

  /**
    * @dev Gets the owner address of a domain.
    * @param domainHash The hash of the domain.
    * @return The owner address of the domain.
  */
  function getDomainOwner(bytes32 domainHash) public view returns (address) {
      return _domains[domainHash].owner;
  }

  /**
    * @dev Sets the owner address of a domain.
    * @param domainHash The hash of the domain.
    * @param owner The new owner address to set for the domain.
  */
  function setDomainOwner(bytes32 domainHash, address owner) onlyOwner(domainHash) external {
      _domains[domainHash].owner = owner;
  }

  /**
    * @dev Gets the domain contract address of a domain.
    * @param domainHash The hash of the domain.
    * @return The domain contract address of the domain.
  */
  function getDomainContract(bytes32 domainHash) public view returns (address) {
      return _domains[domainHash].domain;
  }

  /**
    * @dev Sets the domain contract address of a domain.
    * @param domainHash The hash of the domain.
    * @param domain The new domain contract address to set for the domain.
  */
  function setDomainContract(bytes32 domainHash, address domain) onlyOwner(domainHash) external {
      _domains[domainHash].domain = domain;
  }

  /**
    * @dev Gets the resolver contract address of a domain.
    * @param domainHash The hash of the domain.
    * @return The resolver contract address of the domain.
  */
  function getResolverContract(bytes32 domainHash) public view returns (address) {
      return _domains[domainHash].resolver;
  }

  /**
    * @dev Sets the resolver contract address of a domain.
    * @param domainHash The hash of the domain.
    * @param resolver The new resolver contract address to set for the domain.
  */
  function setResolverContract(bytes32 domainHash, address resolver) onlyOwner(domainHash) external {
      _domains[domainHash].resolver = resolver;
  }

  /**
    * @dev Computes the hash value of a given domain name.
    * @param domainName The domain name to be hashed.
    * @return The hash value of the domain name.
  */
  function hashDomainName(string memory domainName) public pure returns (bytes32) {
    return keccak256(bytes(domainName));
  }

  uint256[49] private __gap;
}

