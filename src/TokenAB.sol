// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenAB is ERC20, ERC20Burnable, Ownable {
    error TokenAB__MustBeMoreThanZero();
    error TokenAB__BurnAmountExceedBalance();

    constructor(address initialOwner) ERC20("TokenAB", "TokenAB") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert TokenAB__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert TokenAB__BurnAmountExceedBalance();
        }
        super.burn(_amount);
    }
}
