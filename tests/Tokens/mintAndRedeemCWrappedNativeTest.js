const {
  etherGasCost,
  etherMantissa,
  etherUnsigned,
} = require('../Utils/Ethereum');

const {
  makeCToken,
  fastForward,
  setBalance,
  setEtherBalance,
  getBalances,
  adjustBalances,
} = require('../Utils/Compound');

const exchangeRate = 5;
const mintAmount = etherUnsigned(1e5);
const mintTokens = mintAmount.dividedBy(exchangeRate);
const redeemTokens = etherUnsigned(10e3);
const redeemAmount = redeemTokens.multipliedBy(exchangeRate);

async function preMint(cToken, payer, minter, mintAmount, mintTokens, exchangeRate) {
  await send(cToken.comptroller, 'setMintAllowed', [true]);
  await send(cToken.comptroller, 'setMintVerify', [true]);
  await send(cToken.interestRateModel, 'setFailBorrowRate', [false]);
  await send(cToken.underlying, 'deposit', [], { from: minter, value: mintAmount });
  await send(cToken.underlying, 'deposit', [], { from: payer, value: mintAmount });
  await send(cToken.underlying, 'approve', [cToken._address, mintAmount], { from: minter });
  await send(cToken.underlying, 'approve', [cToken._address, mintAmount], { from: payer });
  await send(cToken, 'harnessSetBalance', [minter, 0]);
  await send(cToken, 'harnessSetBalance', [payer, 0]);
  await send(cToken, 'harnessSetExchangeRate', [etherMantissa(exchangeRate)]);
}

async function mintNative(cToken, minter, mintAmount, opts = {}) {
  let from = minter;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'mintNative', [minter], {from: from, value: mintAmount});
}

async function mint(cToken, minter, mintAmount, opts = {}) {
  let from = minter;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'mint', [minter, mintAmount], { from: from });
}

async function preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate) {
  const root = saddle.account;
  await send(cToken.comptroller, 'setRedeemAllowed', [true]);
  await send(cToken.comptroller, 'setRedeemVerify', [true]);
  await send(cToken.interestRateModel, 'setFailBorrowRate', [false]);
  await send(cToken, 'harnessSetExchangeRate', [etherMantissa(exchangeRate)]);
  await send(cToken.underlying, 'deposit', [], { from: root, value: redeemAmount });
  await send(cToken.underlying, 'harnessSetBalance', [cToken._address, redeemAmount]);
  await send(cToken, 'harnessSetTotalSupply', [redeemTokens]);
  await setBalance(cToken, redeemer, redeemTokens);
}

async function redeemCTokensNative(cToken, redeemer, redeemTokens, redeemAmount, opts = {}) {
  let from = redeemer;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'redeemNative', [redeemer, redeemTokens, 0], {from: from});
}

async function redeemCTokens(cToken, redeemer, redeemTokens, redeemAmount, opts = {}) {
  let from = redeemer;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'redeem', [redeemer, redeemTokens, 0], {from: from});
}

async function redeemUnderlyingNative(cToken, redeemer, redeemTokens, redeemAmount, opts = {}) {
  let from = redeemer;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'redeemNative', [redeemer, 0, redeemAmount], {from: from});
}

async function redeemUnderlying(cToken, redeemer, redeemTokens, redeemAmount, opts = {}) {
  let from = redeemer;
  if (opts.from) {
    from = opts.from;
  }
  return send(cToken, 'redeem', [redeemer, 0, redeemAmount], {from: from});
}

describe('CWrappedNative', () => {
  let root, minter, redeemer, benefactor, helper, accounts;
  let cToken;

  beforeEach(async () => {
    [root, minter, redeemer, benefactor, helper, ...accounts] = saddle.accounts;
    cToken = await makeCToken({kind: 'cwrapped', comptrollerOpts: {kind: 'bool'}, exchangeRate});
    await fastForward(cToken, 1);
  });

  [mintNative, mint].forEach((mint) => {
    describe(mint.name, () => {
      beforeEach(async () => {
        await preMint(cToken, benefactor, minter, mintAmount, mintTokens, exchangeRate);
      });

      it("reverts if interest accrual fails", async () => {
        await send(cToken.interestRateModel, 'setFailBorrowRate', [true]);
        await expect(mint(cToken, minter, mintAmount)).rejects.toRevert("revert INTEREST_RATE_MODEL_ERROR");
      });
    });
  });

  describe('mint', () => {
    beforeEach(async () => {
      await preMint(cToken, benefactor, minter, mintAmount, mintTokens, exchangeRate);
    });

    it('mint', async () => {
      const beforeBalances = await getBalances([cToken], [minter]);
      const receipt = await mint(cToken, minter, mintAmount, {from: minter});
      const afterBalances = await getBalances([cToken], [minter]);
      expect(receipt).toSucceed();
      expect(mintTokens).not.toEqualNumber(0);
      expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
        [cToken, 'tokens', mintTokens],
        [cToken, 'cash', mintAmount],
        [cToken, minter, 'cash', -mintAmount],
        [cToken, minter, 'eth', -(await etherGasCost(receipt))],
        [cToken, minter, 'tokens', mintTokens]
      ]));
    });

    it('mint by other', async () => {
      const beforeBalances = await getBalances([cToken], [minter]);
      const receipt = await mint(cToken, minter, mintAmount, {from: benefactor});
      const afterBalances = await getBalances([cToken], [minter]);
      expect(receipt).toSucceed();
      expect(mintTokens).not.toEqualNumber(0);
      expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
        [cToken, 'tokens', mintTokens],
        [cToken, 'cash', mintAmount],
        [cToken, minter, 'tokens', mintTokens]
      ]));
    });

    it('mintNative', async () => {
      const beforeBalances = await getBalances([cToken], [minter]);
      const receipt = await mintNative(cToken, minter, mintAmount, {from: minter});
      const afterBalances = await getBalances([cToken], [minter]);
      expect(receipt).toSucceed();
      expect(mintTokens).not.toEqualNumber(0);
      expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
        [cToken, 'tokens', mintTokens],
        [cToken, 'cash', mintAmount],
        [cToken, minter, 'eth', -mintAmount.plus(await etherGasCost(receipt))],
        [cToken, minter, 'tokens', mintTokens]
      ]));
    });

    it('mintNative by other', async () => {
      const beforeBalances = await getBalances([cToken], [minter]);
      const receipt = await mintNative(cToken, minter, mintAmount, {from: benefactor});
      const afterBalances = await getBalances([cToken], [minter]);
      expect(receipt).toSucceed();
      expect(mintTokens).not.toEqualNumber(0);
      expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
        [cToken, 'tokens', mintTokens],
        [cToken, 'cash', mintAmount],
        [cToken, minter, 'tokens', mintTokens]
      ]));
    });
  });

  [redeemCTokensNative, redeemUnderlyingNative].forEach((redeem) => {
    describe(redeem.name, () => {
      beforeEach(async () => {
        await preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate);
      });

      it("emits a redeem failure if interest accrual fails", async () => {
        await send(cToken.interestRateModel, 'setFailBorrowRate', [true]);
        await expect(redeem(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert INTEREST_RATE_MODEL_ERROR");
      });

      it("returns error from redeemFresh without emitting any extra logs", async () => {
        await expect(redeem(cToken, redeemer, redeemTokens.multipliedBy(5), redeemAmount.multipliedBy(5))).rejects.toRevert("revert subtraction underflow");
      });

      it("returns success from redeemFresh and redeems the correct amount", async () => {
        await fastForward(cToken);
        const beforeBalances = await getBalances([cToken], [redeemer]);
        const receipt = await redeem(cToken, redeemer, redeemTokens, redeemAmount);
        expect(receipt).toTokenSucceed();
        const afterBalances = await getBalances([cToken], [redeemer]);
        expect(redeemTokens).not.toEqualNumber(0);
        expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
          [cToken, 'tokens', -redeemTokens],
          [cToken, 'cash', -redeemAmount],
          [cToken, redeemer, 'eth', redeemAmount.minus(await etherGasCost(receipt))],
          [cToken, redeemer, 'tokens', -redeemTokens]
        ]));
      });

      it("redeems successfully by helper", async () => {
        await send(cToken, '_setHelper', [helper]);
        await fastForward(cToken);
        const beforeBalances = await getBalances([cToken], [redeemer]);
        const receipt = await redeem(cToken, redeemer, redeemTokens, redeemAmount, {from: helper});
        expect(receipt).toTokenSucceed();
        const afterBalances = await getBalances([cToken], [redeemer]);
        expect(redeemTokens).not.toEqualNumber(0);
        expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
          [cToken, 'tokens', -redeemTokens],
          [cToken, 'cash', -redeemAmount],
          [cToken, redeemer, 'eth', redeemAmount],
          [cToken, redeemer, 'tokens', -redeemTokens]
        ]));
      });
    });
  });

  [redeemCTokens, redeemUnderlying].forEach((redeem) => {
    describe(redeem.name, () => {
      beforeEach(async () => {
        await preRedeem(cToken, redeemer, redeemTokens, redeemAmount, exchangeRate);
      });

      it("emits a redeem failure if interest accrual fails", async () => {
        await send(cToken.interestRateModel, 'setFailBorrowRate', [true]);
        await expect(redeem(cToken, redeemer, redeemTokens, redeemAmount)).rejects.toRevert("revert INTEREST_RATE_MODEL_ERROR");
      });

      it("returns error from redeemFresh without emitting any extra logs", async () => {
        await expect(redeem(cToken, redeemer, redeemTokens.multipliedBy(5), redeemAmount.multipliedBy(5))).rejects.toRevert("revert subtraction underflow");
      });

      it("returns success from redeemFresh and redeems the correct amount", async () => {
        await fastForward(cToken);
        const beforeBalances = await getBalances([cToken], [redeemer]);
        const receipt = await redeem(cToken, redeemer, redeemTokens, redeemAmount);
        expect(receipt).toTokenSucceed();
        const afterBalances = await getBalances([cToken], [redeemer]);
        expect(redeemTokens).not.toEqualNumber(0);
        expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
          [cToken, 'tokens', -redeemTokens],
          [cToken, 'cash', -redeemAmount],
          [cToken, redeemer, 'cash', redeemAmount],
          [cToken, redeemer, 'eth', -(await etherGasCost(receipt))],
          [cToken, redeemer, 'tokens', -redeemTokens]
        ]));
      });

      it("redeems successfully by helper", async () => {
        await send(cToken, '_setHelper', [helper]);
        await fastForward(cToken);
        const beforeBalances = await getBalances([cToken], [redeemer]);
        const receipt = await redeem(cToken, redeemer, redeemTokens, redeemAmount, {from : helper});
        expect(receipt).toTokenSucceed();
        const afterBalances = await getBalances([cToken], [redeemer]);
        expect(redeemTokens).not.toEqualNumber(0);
        expect(afterBalances).toEqual(await adjustBalances(beforeBalances, [
          [cToken, 'tokens', -redeemTokens],
          [cToken, 'cash', -redeemAmount],
          [cToken, redeemer, 'cash', redeemAmount],
          [cToken, redeemer, 'tokens', -redeemTokens]
        ]));
      });
    });
  });
});
