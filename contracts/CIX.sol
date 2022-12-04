// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CIX is ERC20, AccessControlEnumerable {
    bytes32 public constant BURNER = bytes32(uint256(1));
    bytes32 public constant MINTER = bytes32(uint256(2));

    constructor(
        address admin,
        address minter,
        address burner
    ) ERC20("Centurion Invest Token", "CIX") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BURNER, burner);
        _grantRole(MINTER, minter);
        _mint(_msgSender(), 2400000000 * 10**uint256(decimals()));
    }

    function burn(address account, uint256 amount) external onlyRole(BURNER) {
        require(
            _msgSender() == account,
            "ERC20: burn account different from message sender"
        );
        _burn(account, amount);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER) {
        _mint(to, amount);
    }
}
