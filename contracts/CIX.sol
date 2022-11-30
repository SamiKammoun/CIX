// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract CIX is ERC20, Ownable {
    constructor() ERC20("Centurion Invest Token", "CIX") {
        _mint(owner(), 2400000000 * 10**uint256(decimals()));
    }

    function burn(address account, uint256 amount) external {
        require(
            _msgSender() == account,
            "ERC20: burn account different from message sender"
        );
        _burn(account, amount);
    }
}
