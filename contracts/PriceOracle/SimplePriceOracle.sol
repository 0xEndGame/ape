pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "../ApeErc20.sol";

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint256) prices;
    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );

    function getUnderlyingPrice(ApeToken apeToken) public view returns (uint256) {
        if (compareStrings(apeToken.symbol(), "crETH")) {
            return 1e18;
        } else {
            return prices[address(ApeErc20(address(apeToken)).underlying())];
        }
    }

    function setUnderlyingPrice(ApeToken apeToken, uint256 underlyingPriceMantissa) public {
        address asset = address(ApeErc20(address(apeToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint256 price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
