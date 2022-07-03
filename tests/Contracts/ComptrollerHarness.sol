pragma solidity ^0.5.16;

import "../../contracts/Comptroller.sol";
import "../../contracts/ApeToken.sol";
import "../../contracts/PriceOracle/PriceOracle.sol";

contract ComptrollerKovan is Comptroller {
    function getCompAddress() public view returns (address) {
        return 0x61460874a7196d6a22D1eE4922473664b3E95270;
    }
}

contract ComptrollerRopsten is Comptroller {
    function getCompAddress() public view returns (address) {
        return 0x1Fe16De955718CFAb7A44605458AB023838C2793;
    }
}

contract ComptrollerHarness is Comptroller {
    uint256 public blockNumber;

    constructor() public Comptroller() {}

    function setPauseGuardian(address harnessedPauseGuardian) public {
        pauseGuardian = harnessedPauseGuardian;
    }

    function harnessFastForward(uint256 blocks) public returns (uint256) {
        blockNumber += blocks;
        return blockNumber;
    }

    function setBlockNumber(uint256 number) public {
        blockNumber = number;
    }

    function getBlockNumber() public view returns (uint256) {
        return blockNumber;
    }
}

contract ComptrollerBorked {
    function _become(
        Unitroller unitroller,
        PriceOracle _oracle,
        uint256 _closeFactorMantissa,
        uint256 _maxAssets,
        bool _reinitializing
    ) public {
        _oracle;
        _closeFactorMantissa;
        _maxAssets;
        _reinitializing;

        require(msg.sender == unitroller.admin(), "unitroller admin only");
        unitroller._acceptImplementation();
    }
}

contract BoolComptroller is ComptrollerInterface {
    bool allowMint = true;
    bool allowRedeem = true;
    bool allowBorrow = true;
    bool allowRepayBorrow = true;
    bool allowLiquidateBorrow = true;
    bool allowSeize = true;

    bool verifyMint = true;
    bool verifyRedeem = true;
    bool verifyBorrow = true;
    bool verifyRepayBorrow = true;
    bool verifyLiquidateBorrow = true;
    bool verifySeize = true;

    bool failCalculateSeizeTokens;
    uint256 calculatedSeizeTokens;

    uint256 noError = 0;
    uint256 opaqueError = noError + 11; // an arbitrary, opaque error code

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata _apeTokens) external {
        _apeTokens;
    }

    function exitMarket(address _apeToken) external {
        _apeToken;
    }

    function checkMembership(address _account, ApeToken _apeToken) external view returns (bool) {
        _account;
        _apeToken;
        return true;
    }

    /*** Policy Hooks ***/

    function mintAllowed(
        address _apeToken,
        address _payer,
        address _minter,
        uint256 _mintAmount
    ) public returns (uint256) {
        _apeToken;
        _payer;
        _minter;
        _mintAmount;
        return allowMint ? noError : opaqueError;
    }

    function mintVerify(
        address _apeToken,
        address _payer,
        address _minter,
        uint256 _mintAmount,
        uint256 _mintTokens
    ) external {
        _apeToken;
        _payer;
        _minter;
        _mintAmount;
        _mintTokens;
        require(verifyMint, "mintVerify rejected mint");
    }

    function redeemAllowed(
        address _apeToken,
        address _redeemer,
        uint256 _redeemTokens
    ) public returns (uint256) {
        _apeToken;
        _redeemer;
        _redeemTokens;
        return allowRedeem ? noError : opaqueError;
    }

    function redeemVerify(
        address _apeToken,
        address _redeemer,
        uint256 _redeemAmount,
        uint256 _redeemTokens
    ) external {
        _apeToken;
        _redeemer;
        _redeemAmount;
        _redeemTokens;
        require(verifyRedeem, "redeemVerify rejected redeem");
    }

    function borrowAllowed(
        address _apeToken,
        address _borrower,
        uint256 _borrowAmount
    ) public returns (uint256) {
        _apeToken;
        _borrower;
        _borrowAmount;
        return allowBorrow ? noError : opaqueError;
    }

    function borrowVerify(
        address _apeToken,
        address _borrower,
        uint256 _borrowAmount
    ) external {
        _apeToken;
        _borrower;
        _borrowAmount;
        require(verifyBorrow, "borrowVerify rejected borrow");
    }

    function repayBorrowAllowed(
        address _apeToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) public returns (uint256) {
        _apeToken;
        _payer;
        _borrower;
        _repayAmount;
        return allowRepayBorrow ? noError : opaqueError;
    }

    function repayBorrowVerify(
        address _apeToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount,
        uint256 _borrowerIndex
    ) external {
        _apeToken;
        _payer;
        _borrower;
        _repayAmount;
        _borrowerIndex;
        require(verifyRepayBorrow, "repayBorrowVerify rejected repayBorrow");
    }

    function liquidateBorrowAllowed(
        address _apeTokenBorrowed,
        address _apeTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repayAmount
    ) public returns (uint256) {
        _apeTokenBorrowed;
        _apeTokenCollateral;
        _liquidator;
        _borrower;
        _repayAmount;
        return allowLiquidateBorrow ? noError : opaqueError;
    }

    function liquidateBorrowVerify(
        address _apeTokenBorrowed,
        address _apeTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repayAmount,
        uint256 _seizeTokens
    ) external {
        _apeTokenBorrowed;
        _apeTokenCollateral;
        _liquidator;
        _borrower;
        _repayAmount;
        _seizeTokens;
        require(verifyLiquidateBorrow, "liquidateBorrowVerify rejected liquidateBorrow");
    }

    function seizeAllowed(
        address _apeTokenCollateral,
        address _apeTokenBorrowed,
        address _borrower,
        address _liquidator,
        uint256 _seizeTokens
    ) public returns (uint256) {
        _apeTokenCollateral;
        _apeTokenBorrowed;
        _liquidator;
        _borrower;
        _seizeTokens;
        return allowSeize ? noError : opaqueError;
    }

    function seizeVerify(
        address _apeTokenCollateral,
        address _apeTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external {
        _apeTokenCollateral;
        _apeTokenBorrowed;
        _liquidator;
        _borrower;
        _seizeTokens;
        require(verifySeize, "seizeVerify rejected seize");
    }

    /*** Special Liquidation Calculation ***/

    function liquidateCalculateSeizeTokens(
        address _apeTokenBorrowed,
        address _apeTokenCollateral,
        uint256 _repayAmount
    ) public view returns (uint256, uint256) {
        _apeTokenBorrowed;
        _apeTokenCollateral;
        _repayAmount;
        return (calculatedSeizeTokens, 0);
    }

    /**** Mock Settors ****/

    /*** Policy Hooks ***/

    function setMintAllowed(bool allowMint_) public {
        allowMint = allowMint_;
    }

    function setMintVerify(bool verifyMint_) public {
        verifyMint = verifyMint_;
    }

    function setRedeemAllowed(bool allowRedeem_) public {
        allowRedeem = allowRedeem_;
    }

    function setRedeemVerify(bool verifyRedeem_) public {
        verifyRedeem = verifyRedeem_;
    }

    function setBorrowAllowed(bool allowBorrow_) public {
        allowBorrow = allowBorrow_;
    }

    function setBorrowVerify(bool verifyBorrow_) public {
        verifyBorrow = verifyBorrow_;
    }

    function setRepayBorrowAllowed(bool allowRepayBorrow_) public {
        allowRepayBorrow = allowRepayBorrow_;
    }

    function setRepayBorrowVerify(bool verifyRepayBorrow_) public {
        verifyRepayBorrow = verifyRepayBorrow_;
    }

    function setLiquidateBorrowAllowed(bool allowLiquidateBorrow_) public {
        allowLiquidateBorrow = allowLiquidateBorrow_;
    }

    function setLiquidateBorrowVerify(bool verifyLiquidateBorrow_) public {
        verifyLiquidateBorrow = verifyLiquidateBorrow_;
    }

    function setSeizeAllowed(bool allowSeize_) public {
        allowSeize = allowSeize_;
    }

    function setSeizeVerify(bool verifySeize_) public {
        verifySeize = verifySeize_;
    }

    /*** Liquidity/Liquidation Calculations ***/

    function setCalculatedSeizeTokens(uint256 seizeTokens_) public {
        calculatedSeizeTokens = seizeTokens_;
    }
}

contract EchoTypesComptroller is UnitrollerAdminStorage {
    function stringy(string memory s) public pure returns (string memory) {
        return s;
    }

    function addresses(address a) public pure returns (address) {
        return a;
    }

    function booly(bool b) public pure returns (bool) {
        return b;
    }

    function listOInts(uint256[] memory u) public pure returns (uint256[] memory) {
        return u;
    }

    function reverty() public pure {
        require(false, "gotcha sucka");
    }

    function becomeBrains(address payable unitroller) public {
        Unitroller(unitroller)._acceptImplementation();
    }
}
