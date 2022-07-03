pragma solidity ^0.5.16;

import "./ERC20.sol";
import "./FaucetToken.sol";
import "../../contracts/Legacy/ApeEther.sol";
import "../../contracts/ApeToken.sol";
import "../../contracts/ApeErc20.sol";
import "../../contracts/ComptrollerInterface.sol";

/**
 * @title The ApeFinance Evil Test Token
 * @notice A simple test token that fails certain operations
 */
contract EvilToken is FaucetToken {
    bool public fail;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public FaucetToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
        fail = true;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        if (fail) {
            return false;
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        if (fail) {
            return false;
        }
        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount);
        emit Transfer(src, dst, amount);
        return true;
    }
}

interface RecipientInterface {
    /**
     * @dev Hook executed upon a transfer to the recipient
     */
    function tokensReceived() external;
}

contract EvilAccount is RecipientInterface {
    address payable private crEth;
    address private crEvilToken;
    uint256 private borrowAmount;

    constructor(
        address payable _crEth,
        address _crEvilToken,
        uint256 _borrowAmount
    ) public {
        crEth = _crEth;
        crEvilToken = _crEvilToken;
        borrowAmount = _borrowAmount;
    }

    function attackBorrow() external payable {
        // Mint crEth.
        ApeEther(crEth).mint.value(msg.value)();
        ComptrollerInterface comptroller = ApeEther(crEth).comptroller();

        // Enter the market.
        address[] memory markets = new address[](1);
        markets[0] = crEth;
        comptroller.enterMarkets(markets);

        // Borrow EvilTransferToken.
        require(ApeErc20(crEvilToken).borrow(address(this), borrowAmount) == 0, "first borrow failed");
    }

    function tokensReceived() external {
        // Borrow Eth.
        require(ApeEther(crEth).borrow(address(this), borrowAmount) != 0, "reentry borrow succeed");
    }

    function() external payable {}
}

contract EvilAccount2 is RecipientInterface {
    address private crWeth;
    address private crEvilToken;
    address private borrower;
    uint256 private repayAmount;

    constructor(
        address _crWeth,
        address _crEvilToken,
        address _borrower,
        uint256 _repayAmount
    ) public {
        crWeth = _crWeth;
        crEvilToken = _crEvilToken;
        borrower = _borrower;
        repayAmount = _repayAmount;
    }

    function attackLiquidate() external {
        // Make sure the evil account has enough balance to repay.
        address evilToken = ApeErc20(crEvilToken).underlying();
        require(ERC20Base(evilToken).balanceOf(address(this)) > repayAmount, "insufficient balance");

        // Approve for repayment.
        require(ERC20Base(evilToken).approve(crEvilToken, repayAmount) == true, "failed to approve");

        // Liquidate EvilTransferToken.
        require(
            ApeErc20(crEvilToken).liquidateBorrow(borrower, repayAmount, ApeToken(crWeth)) == 0,
            "first liquidate failed"
        );
    }

    function tokensReceived() external {
        // Make sure the evil account has enough balance to repay.
        address weth = ApeErc20(crWeth).underlying();
        require(ERC20Base(weth).balanceOf(address(this)) > repayAmount, "insufficient balance");

        // Approve for repayment.
        require(ERC20Base(weth).approve(crWeth, repayAmount) == true, "failed to approve");

        // Liquidate ETH.
        ApeErc20(crWeth).liquidateBorrow(borrower, repayAmount, ApeToken(crWeth));
    }
}

contract EvilTransferToken is FaucetToken {
    bool private attackSwitchOn;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public FaucetToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function transfer(address dst, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        emit Transfer(msg.sender, dst, amount);

        if (attackSwitchOn) {
            RecipientInterface(dst).tokensReceived();
        }
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount);
        emit Transfer(src, dst, amount);

        if (attackSwitchOn) {
            RecipientInterface(src).tokensReceived();
        }
        return true;
    }

    function turnSwitchOn() external {
        attackSwitchOn = true;
    }

    function turnSwitchOff() external {
        attackSwitchOn = false;
    }
}
