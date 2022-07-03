const {
  etherUnsigned,
  etherMantissa,
  etherGasCost,
  UInt256Max
} = require('../Utils/Ethereum');

const {
  makeCToken,
  balanceOf,
  collateralTokenBalance,
  totalSupply,
  totalCollateralTokens,
  fastForward,
  setBalance,
  getBalances,
  adjustBalances,
  preApprove,
  quickMint,
  preSupply,
  quickRedeem,
  quickRedeemUnderlying
} = require('../Utils/Compound');

const exchangeRate = 50e3;
const mintAmount = etherUnsigned(10e4);
const mintTokens = mintAmount.div(exchangeRate);
const redeemTokens = etherUnsigned(10e3);
const redeemAmount = redeemTokens.multipliedBy(exchangeRate);

async function preMint(cToken, payer, minter, mintAmount, mintTokens, exchangeRate) {
  await preApprove(cToken, payer, mintAmount);
  await preApprove(cToken, minter, mintAmount);
  await send(cToken.comptroller, 'setMintAllowed', [true]);
  await send(cToken.comptroller, 'setMintVerify', [true]);
  await send(cToken.interestRateModel, 'setFailBorrowRate', [false]);
  await send(cToken.underlying, 'harnessSetFailTransferFromAddress', [payer, false]);
  await send(cToken.underlying, 'harnessSetFailTransferFromAddress', [minter, false]);
  await send(cToken, 'harnessSetBalance', [payer, 0]);
  await send(cToken, 'harnessSetBalance', [minter, 0]);
  await send(cToken, 'harnessSetExchangeRate', [etherMantissa(exchangeRate)]);
}

async function mintFresh(cToken, payer, minter, mintAmount) {
  return send(cToken, 'harnessMintFresh', [payer, minter, mintAmount], {from: payer});
}

async function preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate) {
  await preSupply(cToken, redeemer, redeemTokens, {totalCollateralTokens: true});
  await send(cToken.comptroller, 'setRedeemAllowed', [true]);
  await send(cToken.comptroller, 'setRedeemVerify', [true]);
  await send(cToken.interestRateModel, 'setFailBorrowRate', [false]);
  await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount]);
  await send(cToken, 'harnessSetInternalCash', [redeemAmount]);
  await send(cToken.underlying, 'harnessSetBalance', [redeemer, 0]);
  await send(cToken.underlying, 'harnessSetFailTransferToAddress', [redeemer, false]);
  await send(cToken, 'harnessSetExchangeRate', [etherMantissa(exchangeRate)]);
}

async function redeemFreshTokens(cToken, redeemer, redeemTokens, redeemAmount) {
  return send(cToken, 'harnessRedeemFresh', [redeemer, redeemTokens, 0]);
}

async function redeemFreshAmount(cToken, redeemer, redeemTokens, redeemAmount) {
  return send(cToken, 'harnessRedeemFresh', [redeemer, 0, redeemAmount]);
}

describe('CToken', function () {
  let root, minter, redeemer, benefactor, accounts;
  let cToken;
  beforeEach(async () => {
    [root, minter, redeemer, benefactor, ...accounts] = saddle.accounts;
    cToken = await makeCToken({kind: 'ccollateralcap', comptrollerOpts: {kind: 'bool'}, exchangeRate});
  });

  describe('mintFresh', () => {
    [true, false].forEach((benefactorIsPayer) => {
      let payer;
      const label = benefactorIsPayer ? "benefactor paying" : "minter paying";
      describe(label, () => {
        beforeEach(async () => {
          payer = benefactorIsPayer ? benefactor : minter;
          await preMint(cToken, payer, minter, mintAmount, mintTokens, exchangeRate);
        });

        it("fails if comptroller tells it to", async () => {
          await send(cToken.comptroller, 'setMintAllowed', [false]);
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert rejected');
        });

        it("proceeds if comptroller tells it to", async () => {
          await expect(await mintFresh(cToken, payer, minter, mintAmount)).toSucceed();
        });

        it("fails if not fresh", async () => {
          await fastForward(cToken);
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert market is stale');
        });

        it("continues if fresh", async () => {
          await expect(await send(cToken, 'accrueInterest')).toSucceed();
          expect(await mintFresh(cToken, payer, minter, mintAmount)).toSucceed();
        });

        it("fails if insufficient approval", async () => {
          expect(
            await send(cToken.underlying, 'approve', [cToken._address, 1], {from: minter})
          ).toSucceed();
          expect(
            await send(cToken.underlying, 'approve', [cToken._address, 1], {from: payer})
          ).toSucceed();
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert Insufficient allowance');
        });

        it("fails if insufficient balance", async() => {
          await setBalance(cToken.underlying, minter, 1);
          await setBalance(cToken.underlying, payer, 1);
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert Insufficient balance');
        });

        it("proceeds if sufficient approval and balance", async () =>{
          expect(await mintFresh(cToken, payer, minter, mintAmount)).toSucceed();
        });

        it("fails if exchange calculation fails", async () => {
          expect(await send(cToken, 'harnessSetExchangeRate', [0])).toSucceed();
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert divide by zero');
        });

        it("fails if transferring in fails", async () => {
          await send(cToken.underlying, 'harnessSetFailTransferFromAddress', [minter, true]);
          await send(cToken.underlying, 'harnessSetFailTransferFromAddress', [payer, true]);
          await expect(mintFresh(cToken, payer, minter, mintAmount)).rejects.toRevert('revert transfer failed');
        });

        it("transfers the underlying cash, tokens, and emits Mint event", async () => {
          const beforeBalances = await getBalances([cToken], [minter]);
          const result = await mintFresh(cToken, payer, minter, mintAmount);
          const afterBalances = await getBalances([cToken], [minter]);
          expect(result).toSucceed();
          expect(result).toHaveLog('Mint', {
            payer,
            minter,
            mintAmount: mintAmount.toString(),
            mintTokens: mintTokens.toString()
          });
          if (benefactorIsPayer) {
            expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
              [cToken, minter, 'tokens', mintTokens],
              [cToken, 'cash', mintAmount],
              [cToken, 'tokens', mintTokens]
            ]));
          } else {
            expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
              [cToken, minter, 'cash', -mintAmount],
              [cToken, minter, 'tokens', mintTokens],
              [cToken, 'cash', mintAmount],
              [cToken, minter, 'eth', -(await etherGasCost(result))],
              [cToken, 'tokens', mintTokens]
            ]));
          }
        });

        it("succeeds and not reach collateracl cap", async () => {
          expect(await send(cToken, '_setCollateralCap', [mintTokens])).toSucceed();
          expect(await mintFresh(cToken, payer, minter, mintAmount)).toSucceed();

          const balance = await balanceOf(cToken, minter);
          const collateralTokens = await collateralTokenBalance(cToken, minter);
          const total = await totalSupply(cToken);
          const totalCollateral = await totalCollateralTokens(cToken);
          expect(balance).toEqual(collateralTokens);
          expect(total).toEqual(totalCollateral);
        });

        it("succeeds but reach collateracl cap", async () => {
          expect(await send(cToken, '_setCollateralCap', [mintTokens.minus(1)])).toSucceed();
          expect(await mintFresh(cToken, payer, minter, mintAmount)).toSucceed();

          const balance = await balanceOf(cToken, minter);
          const collateralTokens = await collateralTokenBalance(cToken, minter);
          const total = await totalSupply(cToken);
          const totalCollateral = await totalCollateralTokens(cToken);
          expect(balance.minus(1)).toEqual(collateralTokens);
          expect(total.minus(1)).toEqual(totalCollateral);
        });
      });
    });
  });

  describe('mint', () => {
    let payer;

    beforeEach(async () => {
      payer = benefactor;
      await preMint(cToken, payer, minter, mintAmount, mintTokens, exchangeRate);
    });

    it("emits a mint failure if interest accrual fails", async () => {
      await send(cToken.interestRateModel, 'setFailBorrowRate', [true]);
      await expect(quickMint(cToken, minter, mintAmount)).rejects.toRevert("revert INTEREST_RATE_MODEL_ERROR");
    });

    it("returns error from mintFresh without emitting any extra logs", async () => {
      await send(cToken.underlying, 'harnessSetBalance', [minter, 1]);
      await expect(mintFresh(cToken, minter, minter, mintAmount)).rejects.toRevert('revert Insufficient balance');
    });

    it("returns success from mintFresh and mints the correct number of tokens", async () => {
      expect(await quickMint(cToken, minter, mintAmount)).toSucceed();
      expect(mintTokens).not.toEqualNumber(0);
      expect(await balanceOf(cToken, minter)).toEqualNumber(mintTokens);
    });

    it("emits an AccrueInterest event", async () => {
      expect(await quickMint(cToken, minter, mintAmount)).toHaveLog('AccrueInterest', {
        borrowIndex: "1000000000000000000",
        cashPrior: "0",
        interestAccumulated: "0",
        totalBorrows: "0",
      });
    });
  });

  [redeemFreshTokens, redeemFreshAmount].forEach((redeemFresh) => {
    describe(redeemFresh.name, () => {
      beforeEach(async () => {
        await preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate);
      });

      it("fails if comptroller tells it to", async () =>{
        await send(cToken.comptroller, 'setRedeemAllowed', [false]);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert rejected");
      });

      it("fails if not fresh", async () => {
        await fastForward(cToken);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert('revert market is stale');
      });

      it("continues if fresh", async () => {
        await expect(await send(cToken, 'accrueInterest')).toSucceed();
        expect(await redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).toSucceed();
      });

      it("fails if insufficient protocol cash to transfer out", async() => {
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, 1]);
        await send(cToken, 'harnessSetInternalCash', [1]);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert('revert insufficient cash');
      });

      it("fails if exchange calculation fails", async () => {
        if (redeemFresh == redeemFreshTokens) {
          expect(await send(cToken, 'harnessSetExchangeRate', [UInt256Max()])).toSucceed();
          await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert multiplication overflow");
        } else {
          expect(await send(cToken, 'harnessSetExchangeRate', [0])).toSucceed();
          await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert divide by zero");
        }
      });

      it("fails if transferring out fails", async () => {
        await send(cToken.underlying, 'harnessSetFailTransferToAddress', [redeemer, true]);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert transfer failed");
      });

      it("fails if total supply < redemption amount", async () => {
        await send(cToken, 'harnessExchangeRateDetails', [0, 0, 0]);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert subtraction underflow");
      });

      it("reverts if new account balance underflows", async () => {
        await send(cToken, 'harnessSetBalance', [redeemer, 0]);
        await expect(redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert subtraction underflow");
      });

      it("transfers the underlying cash, tokens, and emits Redeem event", async () => {
        const beforeBalances = await getBalances([cToken], [redeemer]);
        const result = await redeemFresh(cToken, redeemer, redeemTokens, redeemAmount);
        const afterBalances = await getBalances([cToken], [redeemer]);
        expect(result).toSucceed();
        expect(result).toHaveLog('Redeem', {
          redeemer,
          redeemAmount: redeemAmount.toString(),
          redeemTokens: redeemTokens.toString()
        });
        expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
          [cToken, redeemer, 'cash', redeemAmount],
          [cToken, redeemer, 'tokens', -redeemTokens],
          [cToken, 'cash', -redeemAmount],
          [cToken, 'tokens', -redeemTokens]
        ]));
      });

      it("succeeds and not consume collateral", async () => {
        await send(cToken, 'harnessSetBalance', [redeemer, redeemTokens.multipliedBy(3)]);
        await send(cToken, 'harnessSetCollateralBalance', [redeemer, redeemTokens]);
        await send(cToken, 'harnessSetTotalSupply', [redeemTokens.multipliedBy(3)]);
        await send(cToken, 'harnessSetTotalCollateralTokens', [redeemTokens]);

        expect(await redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).toSucceed();

        // balance:          30000 -> 20000
        // collateralTokens: 10000 -> 10000
        // total:            30000 -> 20000
        // totalCollateral:  10000 -> 10000
        const balance = await balanceOf(cToken, redeemer);
        const collateralTokens = await collateralTokenBalance(cToken, redeemer);
        const total = await totalSupply(cToken);
        const totalCollateral = await totalCollateralTokens(cToken);
        expect(balance).toEqual(collateralTokens.multipliedBy(2));
        expect(total).toEqual(totalCollateral.multipliedBy(2));
      });

      it("succeeds but consume partial collateral", async () => {
        await send(cToken, 'harnessSetBalance', [redeemer, redeemTokens.plus(1)]);
        await send(cToken, 'harnessSetCollateralBalance', [redeemer, redeemTokens]);
        await send(cToken, 'harnessSetTotalSupply', [redeemTokens.plus(1)]);
        await send(cToken, 'harnessSetTotalCollateralTokens', [redeemTokens]);

        expect(await redeemFresh(cToken, redeemer, redeemTokens, redeemAmount)).toSucceed();

        // balance:          10001 -> 1
        // collateralTokens: 10000 -> 1
        // total:            10001 -> 1
        // totalCollateral:  10000 -> 1
        const balance = await balanceOf(cToken, redeemer);
        const collateralTokens = await collateralTokenBalance(cToken, redeemer);
        const total = await totalSupply(cToken);
        const totalCollateral = await totalCollateralTokens(cToken);
        expect(balance).toEqual(collateralTokens);
        expect(total).toEqual(totalCollateral);
      });
    });
  });

  describe('redeem', () => {
    beforeEach(async () => {
      await preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate);
    });

    it("emits a redeem failure if interest accrual fails", async () => {
      await send(cToken.interestRateModel, 'setFailBorrowRate', [true]);
      await expect(quickRedeem(cToken, redeemer, redeemTokens)).rejects.toRevert("revert INTEREST_RATE_MODEL_ERROR");
    });

    it("returns error from redeemFresh without emitting any extra logs", async () => {
      await setBalance(cToken.underlying, cToken._address, 0);
      await send(cToken, 'harnessSetInternalCash', [0]);
      await expect(quickRedeem(cToken, redeemer, redeemTokens)).rejects.toRevert("revert insufficient cash");
    });

    it("returns success from redeemFresh and redeems the right amount", async () => {
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      expect(await quickRedeem(cToken, redeemer, redeemTokens, {exchangeRate})).toSucceed();
      expect(redeemAmount).not.toEqualNumber(0);
      expect(await balanceOf(cToken.underlying, redeemer)).toEqualNumber(redeemAmount);
    });

    it("returns success from redeemFresh and redeems the right amount of underlying", async () => {
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      expect(
        await quickRedeemUnderlying(cToken, redeemer, redeemAmount, {exchangeRate})
      ).toSucceed();
      expect(redeemAmount).not.toEqualNumber(0);
      expect(await balanceOf(cToken.underlying, redeemer)).toEqualNumber(redeemAmount);
    });

    it("emits an AccrueInterest event", async () => {
      expect(await quickMint(cToken, minter, mintAmount)).toHaveLog('AccrueInterest', {
        borrowIndex: "1000000000000000000",
        cashPrior: "500000000",
        interestAccumulated: "0",
        totalBorrows: "0",
      });
    });

    it("fails if redeem trigger by other", async () => {
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      await expect(quickRedeem(cToken, redeemer, redeemTokens, {exchangeRate, from: root})).rejects.toRevert('revert invalid redeemer');
    });

    it("fails if redeem underlying trigger by other", async () => {
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      await expect(quickRedeemUnderlying(cToken, redeemer, redeemAmount, {exchangeRate, from: root})).rejects.toRevert('revert invalid redeemer');
    });

    it("redeems successfully by helper", async () => {
      await send(cToken, '_setHelper', [root]);
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      expect(await quickRedeem(cToken, redeemer, redeemTokens, {exchangeRate, from: root})).toSucceed();
      expect(redeemAmount).not.toEqualNumber(0);
      expect(await balanceOf(cToken.underlying, redeemer)).toEqualNumber(redeemAmount);
    });

    it("redeems underlying successfully by helper", async () => {
      await send(cToken, '_setHelper', [root]);
      expect(
        await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount])
      ).toSucceed();
      expect(await quickRedeemUnderlying(cToken, redeemer, redeemAmount, {exchangeRate, from: root})).toSucceed();
      expect(redeemAmount).not.toEqualNumber(0);
      expect(await balanceOf(cToken.underlying, redeemer)).toEqualNumber(redeemAmount);
    });
  });
});
