pragma solidity ^0.5.16;

import "../../../contracts/ApeEther.sol";

contract ApeEtherCertora is ApeEther {
    constructor(
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        ApeEther(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_, admin_)
    {}
}
