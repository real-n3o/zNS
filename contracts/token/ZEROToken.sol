/**
  @title ZEROToken
  @dev Simple token contract for testing
  SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IZEROToken } from "./IZEROToken.sol";

contract ZEROToken is IZEROToken, ERC20Upgradeable {
  function initialize(string memory name, string memory symbol) public initializer {
    __ERC20_init(name, symbol);
  }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}