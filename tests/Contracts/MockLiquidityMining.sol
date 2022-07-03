pragma solidity ^0.5.16;

import "../../contracts/LiquidityMiningInterface.sol";

contract MockLiquidityMining is LiquidityMiningInterface {
    address public comptroller;

    constructor(address _comptroller) public {
        comptroller = _comptroller;
    }

    function updateSupplyIndex(address apeToken, address[] calldata accounts) external {
        // Do nothing.
        apeToken;
        accounts;
    }

    function updateBorrowIndex(address apeToken, address[] calldata accounts) external {
        // Do nothing.
        apeToken;
        accounts;
    }
}
