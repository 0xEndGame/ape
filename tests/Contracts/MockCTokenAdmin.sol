pragma solidity ^0.5.16;

import "../../contracts/ApeTokenAdmin.sol";

contract MockApeTokenAdmin is ApeTokenAdmin {
    uint256 public blockTimestamp;

    constructor(address payable _admin) public ApeTokenAdmin(_admin) {}

    function setBlockTimestamp(uint256 timestamp) public {
        blockTimestamp = timestamp;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return blockTimestamp;
    }
}
