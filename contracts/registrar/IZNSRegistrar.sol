pragma solidity ^0.8.18;

interface IZNSRegistrar {
  function mintDomain(string memory domainName) external;
  function destroyDomain(string memory domainName) external;
  function domainNameToTokenId(string memory domainName) external view returns (uint256);
  function setDomainCost(uint256 newDomainCost) external;
  function isDomainAvailable(string memory domainName) external view returns (bool);
  function getDomainOwner(bytes32 domainHash) external view returns (address);
  function setDomainOwner(bytes32 domainHash, address owner) external;
  function getDomainContract(bytes32 domainHash) external view returns (address);
  function setDomainContract(bytes32 domainHash, address domain) external;
  function getResolverContract(bytes32 domainHash) external view returns (address);
  function setResolverContract(bytes32 domainHash, address resolver) external;
  function hashDomainName(string memory domainName) external pure returns (bytes32);
}
