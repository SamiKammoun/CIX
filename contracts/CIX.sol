// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CIX is ERC20, AccessControlEnumerable {
    bytes32 public constant BURNER_ROLE = bytes32(uint256(1));
    bytes32 public constant MINTER_ROLE = bytes32(uint256(2));

    constructor(
        address admin,
        address minter,
        address burner
    ) ERC20("Centurion Invest Token", "CIX") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BURNER_ROLE, burner);
        _grantRole(MINTER_ROLE, minter);
        _mint(_msgSender(), 2400000000 * 10**uint256(decimals()));
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        require(
            _msgSender() == account,
            "ERC20: burn account different from message sender"
        );
        _burn(account, amount);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
