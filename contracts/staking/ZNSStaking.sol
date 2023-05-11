/**
  @title ZNSStaking
  @dev Contract for managing staking related to ZNS domains
  SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.18;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IZNSStaking } from "./IZNSStaking.sol";
import { ZNSDomain } from "../domain/ZNSDomain.sol";
import { ZNSRegistrar } from "../registrar/ZNSRegistrar.sol";

/**
 * @title ZNSStaking
 * @dev Staking contract for Zero Name Service (ZNS) domains.
*/
contract ZNSStaking is IZNSStaking, Initializable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;

  mapping(bytes32 => uint256) public stakes;

  ZNSDomain public znsDomain;
  IERC20Upgradeable public stakingToken;
  address private znsRegistrarAddress;

  /**
    * @dev Emitted when stake is added to a domain.
    * @param domainHash The ID of the domain that had stake added to it.
    * @param amount The amount of stake added to the domain.
    * @param ownerOf The address of the owner of the domain.
  */
  event StakeAdded(bytes32 indexed domainHash, uint256 amount, address ownerOf);

  /**
    * @dev Emitted when stake is withdrawn from a domain.
    * @param domainHash The ID of the domain that had stake withdrawn from it.
    * @param amount The amount of stake withdrawn from the domain.
    * @param recipient The address of the recipient of the withdrawn stake.
  */
  event StakeWithdrawn(bytes32 indexed domainHash, uint256 amount, address indexed recipient);

  modifier onlyRegistrar {
    require(msg.sender == znsRegistrarAddress, "ZNSDomain: Only the ZNSRegistrar can call this function");
    _;
  }

  /**
    @dev Initializes the contract with the addresses of ZNS domains and staking tokens.
  */
  function initialize(ZNSDomain _znsDomain, IERC20Upgradeable _stakingToken, address _znsRegistrar) external initializer {
    __ZNSStaking_init(_znsDomain, _stakingToken);
    znsRegistrarAddress = _znsRegistrar;
  }

  function __ZNSStaking_init(ZNSDomain _znsDomain, IERC20Upgradeable _stakingToken) internal {
    require(_znsDomain != ZNSDomain(address(0)), "Invalid ZNSDomain address");
    require(_stakingToken != IERC20Upgradeable(address(0)), "Invalid ZNSDomain address");

    znsDomain = _znsDomain;
    stakingToken = _stakingToken;
  }

  /**
    @dev Adds a stake to the contract for the given domain tokenId.
    Only the owner of the domain can add a stake.
  */
  function addStake(bytes32 domainHash, uint256 domainCost, address beneficiary) onlyRegistrar nonReentrant external {
    // Transfer funds to the recipient to the staking contract
    SafeERC20Upgradeable.safeTransferFrom(stakingToken, beneficiary, address(this), domainCost);

    // Add stake to the mapping with msg.sender as the owner
    stakes[domainHash] = domainCost;
    uint256 tokenId = uint256(domainHash);

    emit StakeAdded(domainHash, domainCost, znsDomain.ownerOf(tokenId));
  }

  /**
    @dev Withdraws the stake from the contract for the given domain tokenId.
    Only the owner of the domain can withdraw the stake.
    The recipient address must not be 0.
  */
  function withdrawStake(bytes32 domainHash, address beneficiary) onlyRegistrar nonReentrant external {
    uint256 tokenId = uint256(domainHash);

    require(znsDomain.ownerOf(tokenId) == beneficiary, "ZNSStaking: Only the domain owner can withdraw stake");
    require(beneficiary != address(0), "ZNSStaking: Recipient address cannot be zero");

    // Check that the stake exists for tokenID + recipient
    uint256 stakedAmount = stakes[domainHash];

    // Remove stake from mapping
    delete stakes[domainHash];

    // Transfer tokens back to domain owner
    SafeERC20Upgradeable.safeTransfer(stakingToken, beneficiary, stakedAmount);

    emit StakeWithdrawn(domainHash, stakedAmount, beneficiary);
  }

  uint256[49] private __gap;
}