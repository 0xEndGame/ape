pragma solidity ^0.5.16;

import "./ERC20.sol";
import "../../contracts/ApeCollateralCapErc20.sol";
import "../../contracts/ERC3156FlashLenderInterface.sol";
import "../../contracts/ApeWrappedNative.sol";
import "../../contracts/SafeMath.sol";

// FlashloanReceiver is a simple flashloan receiver implementation for testing
contract FlashloanReceiver is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    uint256 totalBorrows;
    address borrowToken;

    function doFlashloan(
        address apeToken,
        uint256 borrowAmount,
        uint256 repayAmount
    ) external {
        borrowToken = ApeCollateralCapErc20(apeToken).underlying();
        uint256 balanceBefore = ERC20(borrowToken).balanceOf(address(this));
        bytes memory data = abi.encode(apeToken, borrowAmount, repayAmount);
        totalBorrows = ApeCollateralCapErc20(apeToken).totalBorrows();
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        (address apeToken, uint256 borrowAmount, uint256 repayAmount) = abi.decode(data, (address, uint256, uint256));
        require(amount == borrowAmount, "Params not match");
        uint256 totalBorrowsAfter = ApeCollateralCapErc20(apeToken).totalBorrows();
        require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndMint is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
    uint256 totalBorrows;
    address borrowToken;

    function doFlashloan(address apeToken, uint256 borrowAmount) external {
        borrowToken = ApeCollateralCapErc20(apeToken).underlying();
        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        address apeToken = abi.decode(data, (address));
        ApeCollateralCapErc20(apeToken).mint(address(this), amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndRepayBorrow is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    address borrowToken;

    function doFlashloan(address apeToken, uint256 borrowAmount) external {
        borrowToken = ApeCollateralCapErc20(apeToken).underlying();
        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        address apeToken = abi.decode(data, (address));
        ApeCollateralCapErc20(apeToken).repayBorrow(address(this), amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanTwice is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
    address borrowToken;

    function doFlashloan(address apeToken, uint256 borrowAmount) external {
        borrowToken = ApeCollateralCapErc20(apeToken).underlying();

        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        address apeToken = abi.decode(data, (address));
        ApeCollateralCapErc20(apeToken).flashLoan(this, address(this), amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanReceiverNative is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    uint256 totalBorrows;

    function doFlashloan(
        address payable apeToken,
        uint256 borrowAmount,
        uint256 repayAmount
    ) external {
        ERC20 underlying = ERC20(ApeWrappedNative(apeToken).underlying());
        uint256 balanceBefore = underlying.balanceOf(address(this));
        bytes memory data = abi.encode(apeToken, borrowAmount);
        totalBorrows = ApeWrappedNative(apeToken).totalBorrows();
        underlying.approve(apeToken, repayAmount);
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, address(underlying), borrowAmount, data);
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter == balanceBefore.add(borrowAmount).sub(repayAmount), "Balance inconsistent");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        (address payable apeToken, uint256 borrowAmount) = abi.decode(data, (address, uint256));
        require(token == ApeWrappedNative(apeToken).underlying(), "Params not match");
        require(amount == borrowAmount, "Params not match");
        uint256 totalBorrowsAfter = ApeWrappedNative(apeToken).totalBorrows();
        require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function() external payable {}
}

contract FlashloanAndMintNative is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address payable apeToken, uint256 borrowAmount) external {
        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(
            this,
            ApeWrappedNative(apeToken).underlying(),
            borrowAmount,
            data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        address payable apeToken = abi.decode(data, (address));
        ApeWrappedNative(apeToken).mint(address(this), amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndRepayBorrowNative is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address payable apeToken, uint256 borrowAmount) external {
        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(
            this,
            ApeWrappedNative(apeToken).underlying(),
            borrowAmount,
            data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        address payable apeToken = abi.decode(data, (address));
        ApeWrappedNative(apeToken).repayBorrow(address(this), amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanTwiceNative is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address payable apeToken, uint256 borrowAmount) external {
        address borrowToken = ApeWrappedNative(apeToken).underlying();
        bytes memory data = abi.encode(apeToken);
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        address payable apeToken = abi.decode(data, (address));
        ERC3156FlashLenderInterface(apeToken).flashLoan(this, token, amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}
