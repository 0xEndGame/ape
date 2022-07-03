pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../../contracts/Legacy/ApeErc20Immutable.sol";
import "../../contracts/ApeErc20Delegator.sol";
import "../../contracts/ApeErc20Delegate.sol";
import "../../contracts/ApeCollateralCapErc20Delegate.sol";
import "../../contracts/Legacy/ApeCollateralCapErc20Delegator.sol";
import "../../contracts/ApeWrappedNativeDelegate.sol";
import "../../contracts/ApeWrappedNativeDelegator.sol";
import "./ComptrollerScenario.sol";

contract ApeErc20Harness is ApeErc20Immutable {
    uint256 public blockNumber = 100000;
    uint256 harnessExchangeRate;
    bool harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        ApeErc20Immutable(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function doTransferOut(
        address payable to,
        uint256 amount,
        bool isNative
    ) internal {
        require(failTransferToAddresses[to] == false, "transfer failed");
        return super.doTransferOut(to, amount, isNative);
    }

    function exchangeRateStoredInternal() internal view returns (uint256) {
        if (harnessExchangeRateStored) {
            return harnessExchangeRate;
        }
        return super.exchangeRateStoredInternal();
    }

    function getBlockNumber() internal view returns (uint256) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint256) {
        return borrowRateMaxMantissa;
    }

    function harnessSetAccrualBlockNumber(uint256 _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetBlockNumber(uint256 newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint256 blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint256 amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetTotalSupply(uint256 totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessSetTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(
        uint256 totalSupply_,
        uint256 totalBorrows_,
        uint256 totalReserves_
    ) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint256 exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(
        address payer,
        address account,
        uint256 mintAmount
    ) public returns (uint256) {
        (uint256 err, ) = super.mintFresh(payer, account, mintAmount, false);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint256 apeTokenAmount,
        uint256 underlyingAmount
    ) public returns (uint256) {
        return super.redeemFresh(account, apeTokenAmount, underlyingAmount, false);
    }

    function harnessAccountBorrows(address account) public view returns (uint256 principal, uint256 interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(
        address account,
        uint256 principal,
        uint256 interestIndex
    ) public {
        accountBorrows[account] = BorrowSnapshot({principal: principal, interestIndex: interestIndex});
    }

    function harnessSetBorrowIndex(uint256 borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint256 borrowAmount) public returns (uint256) {
        return borrowFresh(account, borrowAmount, false);
    }

    function harnessRepayBorrowFresh(
        address payer,
        address account,
        uint256 repayAmount
    ) public returns (uint256) {
        (uint256 err, ) = repayBorrowFresh(payer, account, repayAmount, false);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        ApeToken apeTokenCollateral
    ) public returns (uint256) {
        (uint256 err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, apeTokenCollateral, false);
        return err;
    }

    function harnessReduceReservesFresh(uint256 amount) public returns (uint256) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint256 newReserveFactorMantissa) public returns (uint256) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint256) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint256 amount) public returns (uint256) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }
}

contract ApeErc20Scenario is ApeErc20Immutable {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        ApeErc20Immutable(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint256) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

contract CEvil is ApeErc20Scenario {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        ApeErc20Scenario(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function evilSeize(
        ApeToken treasure,
        address liquidator,
        address borrower,
        uint256 seizeTokens,
        uint256 feeTokens
    ) public returns (uint256) {
        return treasure.seize(liquidator, borrower, seizeTokens, feeTokens);
    }
}

contract ApeErc20DelegatorScenario is ApeErc20Delegator {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
        ApeErc20Delegator(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        )
    {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }
}

contract ApeCollateralCapErc20DelegatorScenario is ApeCollateralCapErc20Delegator {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
        ApeCollateralCapErc20Delegator(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        )
    {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }
}

contract ApeWrappedNativeDelegatorScenario is ApeWrappedNativeDelegator {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
        ApeWrappedNativeDelegator(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        )
    {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function() external payable {}
}

contract ApeErc20DelegateHarness is ApeErc20Delegate {
    event Log(string x, address y);
    event Log(string x, uint256 y);

    uint256 public blockNumber = 100000;
    uint256 harnessExchangeRate;
    bool harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    function exchangeRateStoredInternal() internal view returns (uint256) {
        if (harnessExchangeRateStored) {
            return harnessExchangeRate;
        }
        return super.exchangeRateStoredInternal();
    }

    function doTransferOut(
        address payable to,
        uint256 amount,
        bool isNative
    ) internal {
        require(failTransferToAddresses[to] == false, "transfer failed");
        return super.doTransferOut(to, amount, isNative);
    }

    function getBlockNumber() internal view returns (uint256) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint256) {
        return borrowRateMaxMantissa;
    }

    function harnessSetBlockNumber(uint256 newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint256 blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint256 amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetAccrualBlockNumber(uint256 _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetTotalSupply(uint256 totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessIncrementTotalBorrows(uint256 addtlBorrow_) public {
        totalBorrows = totalBorrows + addtlBorrow_;
    }

    function harnessSetTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(
        uint256 totalSupply_,
        uint256 totalBorrows_,
        uint256 totalReserves_
    ) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint256 exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(
        address payer,
        address account,
        uint256 mintAmount
    ) public returns (uint256) {
        (uint256 err, ) = super.mintFresh(payer, account, mintAmount, false);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint256 apeTokenAmount,
        uint256 underlyingAmount
    ) public returns (uint256) {
        return super.redeemFresh(account, apeTokenAmount, underlyingAmount, false);
    }

    function harnessAccountBorrows(address account) public view returns (uint256 principal, uint256 interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(
        address account,
        uint256 principal,
        uint256 interestIndex
    ) public {
        accountBorrows[account] = BorrowSnapshot({principal: principal, interestIndex: interestIndex});
    }

    function harnessSetBorrowIndex(uint256 borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint256 borrowAmount) public returns (uint256) {
        return borrowFresh(account, borrowAmount, false);
    }

    function harnessRepayBorrowFresh(
        address payer,
        address account,
        uint256 repayAmount
    ) public returns (uint256) {
        (uint256 err, ) = repayBorrowFresh(payer, account, repayAmount, false);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        ApeToken apeTokenCollateral
    ) public returns (uint256) {
        (uint256 err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, apeTokenCollateral, false);
        return err;
    }

    function harnessReduceReservesFresh(uint256 amount) public returns (uint256) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint256 newReserveFactorMantissa) public returns (uint256) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint256) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint256 amount) public returns (uint256) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }
}

contract ApeErc20DelegateScenario is ApeErc20Delegate {
    constructor() public {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint256) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

contract ApeErc20DelegateScenarioExtra is ApeErc20DelegateScenario {
    function iHaveSpoken() public pure returns (string memory) {
        return "i have spoken";
    }

    function itIsTheWay() public {
        admin = address(1); // make a change to test effect
    }

    function babyYoda() public pure {
        revert("protect the baby");
    }
}

contract ApeCollateralCapErc20DelegateHarness is ApeCollateralCapErc20Delegate {
    event Log(string x, address y);
    event Log(string x, uint256 y);

    uint256 public blockNumber = 100000;
    uint256 harnessExchangeRate;
    bool harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    function exchangeRateStoredInternal() internal view returns (uint256) {
        if (harnessExchangeRateStored) {
            return harnessExchangeRate;
        }
        return super.exchangeRateStoredInternal();
    }

    function doTransferOut(
        address payable to,
        uint256 amount,
        bool isNative
    ) internal {
        require(failTransferToAddresses[to] == false, "transfer failed");
        return super.doTransferOut(to, amount, isNative);
    }

    function getBlockNumber() internal view returns (uint256) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint256) {
        return borrowRateMaxMantissa;
    }

    function harnessSetBlockNumber(uint256 newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint256 blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint256 amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetCollateralBalance(address account, uint256 amount) external {
        accountCollateralTokens[account] = amount;
    }

    function harnessSetAccrualBlockNumber(uint256 _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetTotalSupply(uint256 totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalCollateralTokens(uint256 totalCollateralTokens_) public {
        totalCollateralTokens = totalCollateralTokens_;
    }

    function harnessSetTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessIncrementTotalBorrows(uint256 addtlBorrow_) public {
        totalBorrows = totalBorrows + addtlBorrow_;
    }

    function harnessSetTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(
        uint256 totalSupply_,
        uint256 totalBorrows_,
        uint256 totalReserves_
    ) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint256 exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(
        address payer,
        address account,
        uint256 mintAmount
    ) public returns (uint256) {
        (uint256 err, ) = super.mintFresh(payer, account, mintAmount, false);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint256 apeTokenAmount,
        uint256 underlyingAmount
    ) public returns (uint256) {
        return super.redeemFresh(account, apeTokenAmount, underlyingAmount, false);
    }

    function harnessAccountBorrows(address account) public view returns (uint256 principal, uint256 interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(
        address account,
        uint256 principal,
        uint256 interestIndex
    ) public {
        accountBorrows[account] = BorrowSnapshot({principal: principal, interestIndex: interestIndex});
    }

    function harnessSetBorrowIndex(uint256 borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint256 borrowAmount) public returns (uint256) {
        return borrowFresh(account, borrowAmount, false);
    }

    function harnessRepayBorrowFresh(
        address payer,
        address account,
        uint256 repayAmount
    ) public returns (uint256) {
        (uint256 err, ) = repayBorrowFresh(payer, account, repayAmount, false);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        ApeToken apeTokenCollateral
    ) public returns (uint256) {
        (uint256 err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, apeTokenCollateral, false);
        return err;
    }

    function harnessReduceReservesFresh(uint256 amount) public returns (uint256) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint256 newReserveFactorMantissa) public returns (uint256) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint256) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint256 amount) public returns (uint256) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }

    function harnessSetInternalCash(uint256 amount) public returns (uint256) {
        internalCash = amount;
    }
}

contract ApeCollateralCapErc20DelegateScenario is ApeCollateralCapErc20Delegate {
    constructor() public {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint256) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

contract ApeWrappedNativeDelegateHarness is ApeWrappedNativeDelegate {
    event Log(string x, address y);
    event Log(string x, uint256 y);

    uint256 public blockNumber = 100000;
    uint256 harnessExchangeRate;
    bool harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    function exchangeRateStoredInternal() internal view returns (uint256) {
        if (harnessExchangeRateStored) {
            return harnessExchangeRate;
        }
        return super.exchangeRateStoredInternal();
    }

    function doTransferOut(
        address payable to,
        uint256 amount,
        bool isNative
    ) internal {
        require(failTransferToAddresses[to] == false, "transfer failed");
        return super.doTransferOut(to, amount, isNative);
    }

    function getBlockNumber() internal view returns (uint256) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint256) {
        return borrowRateMaxMantissa;
    }

    function harnessSetBlockNumber(uint256 newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint256 blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint256 amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetAccrualBlockNumber(uint256 _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetTotalSupply(uint256 totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessIncrementTotalBorrows(uint256 addtlBorrow_) public {
        totalBorrows = totalBorrows + addtlBorrow_;
    }

    function harnessSetTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(
        uint256 totalSupply_,
        uint256 totalBorrows_,
        uint256 totalReserves_
    ) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint256 exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(
        address payer,
        address account,
        uint256 mintAmount
    ) public returns (uint256) {
        // isNative is not important for mint fresh testing.
        (uint256 err, ) = mintFresh(payer, account, mintAmount, true);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint256 apeTokenAmount,
        uint256 underlyingAmount
    ) public returns (uint256) {
        // isNative is not important for redeem fresh testing.
        return redeemFresh(account, apeTokenAmount, underlyingAmount, true);
    }

    function harnessAccountBorrows(address account) public view returns (uint256 principal, uint256 interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(
        address account,
        uint256 principal,
        uint256 interestIndex
    ) public {
        accountBorrows[account] = BorrowSnapshot({principal: principal, interestIndex: interestIndex});
    }

    function harnessSetBorrowIndex(uint256 borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint256 borrowAmount) public returns (uint256) {
        // isNative is not important for borrow fresh testing.
        return borrowFresh(account, borrowAmount, true);
    }

    function harnessRepayBorrowFresh(
        address payer,
        address account,
        uint256 repayAmount
    ) public payable returns (uint256) {
        // isNative is not important for repay borrow fresh testing.
        (uint256 err, ) = repayBorrowFresh(payer, account, repayAmount, true);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        ApeToken apeTokenCollateral
    ) public returns (uint256) {
        // isNative is not important for liquidate borrow fresh testing.
        (uint256 err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, apeTokenCollateral, true);
        return err;
    }

    function harnessReduceReservesFresh(uint256 amount) public returns (uint256) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint256 newReserveFactorMantissa) public returns (uint256) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint256) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint256 amount) public returns (uint256) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }

    function harnessDoTransferIn(address from, uint256 amount) public payable returns (uint256) {
        return doTransferIn(from, amount, true);
    }

    function harnessDoTransferOut(address payable to, uint256 amount) public payable {
        return doTransferOut(to, amount, true);
    }

    function() external payable {}
}

contract ApeWrappedNativeDelegateScenario is ApeWrappedNativeDelegate {
    constructor() public {}

    function setTotalBorrows(uint256 totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint256 totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint256) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }

    function() external payable {}
}
