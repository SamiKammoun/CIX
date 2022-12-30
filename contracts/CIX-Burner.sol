// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICIX.sol";

contract Burner {
    ICIX public cix;

    constructor(address cixAddress) {
        cix = ICIX(cixAddress);
    }

    function burn(address account, uint256 amount) external {
        cix.burn(account, amount);
    }
}
